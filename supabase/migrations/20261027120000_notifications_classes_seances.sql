-- Notifications des classes et des seances (fiche « Fraicheur et
-- notifications » du 27/10/2026, lignes 10 a 15).
--
-- Constat du 27/10 : la table public.notifications existe (0063), mais le
-- serveur n'y ecrit que pour certains chemins (demande, classe validee depuis
-- un regroupement, enseignant affecte par c11bis, fusion, remplacement entre
-- enseignants). Une classe creee par l'ecran des groupes, un eleve ajoute ou
-- retire, un creneau change, une seance annulee ou deplacee, une classe fermee
-- ne previennent personne. En production au 27/10 : 11 classes, 0 notification.
--
-- Ce que cette migration pose :
--   1. les deux contraintes CHECK de notifications s'etendent aux douze
--      evenements de la ligne 11 et aux ecrans ou ils menent ; toutes les
--      lignes existantes restent valides (anciennes valeurs conservees) ;
--   2. une fonction unique, private.notifier_classe, ecrit une notification
--      par personne concernee par une classe : chaque eleve membre, les
--      tuteurs de son foyer, l'enseignante de la classe (et l'ancienne, pour
--      un changement) ; jamais deux pour le meme fait dans la meme
--      transaction, que la premiere vienne d'elle-meme ou d'un chemin plus
--      ancien (0066, 0078, 0085, c11bis, fusion, b09) ;
--   3. des declencheurs sur public.groupes, groupe_membres, groupe_creneaux,
--      sessions et remplacements_seance, **differes a la validation de la
--      transaction** (constraint triggers DEFERRABLE INITIALLY DEFERRED) : ils
--      lisent l'etat final. Une classe creee avec ses eleves et ses creneaux
--      dans une seule transaction donne une seule notification « classe
--      creee » par personne, et une personne deja prevenue du meme fait par un
--      chemin plus ancien (classe_validee, enseignant_affecte, classe_changee)
--      n'en recoit pas une seconde ;
--   4. public.notifications rejoint la publication supabase_realtime, sur le
--      modele exact de 20261027100000 : le point de la cloche apparait et
--      disparait sur l'autre appareil sans geste (lignes 12 et 14).
--
-- Le courriel : le declencheur courriel_notification du 23/10 enfile chaque
-- ligne inseree (cle d'idempotence « notification:<id> », modele = evenement) ;
-- les neuf modeles de courriel de ces evenements sont ajoutes dans ce meme lot,
-- dans supabase/functions/_shared/courriel (fr, en, ar, es, pt). Rien n'est
-- duplique ici (ligne 15).
--
-- Mots de ce fichier a connaitre avant le collage : DROP CONSTRAINT, deux
-- fois. Une contrainte CHECK ne se modifie pas : elle se remplace, comme dans
-- c29 (20261011210000) et FAC-F (20261018170000). Aucune table, aucune ligne,
-- aucune fonction, aucun declencheur n'est efface : les declencheurs se creent
-- sous garde « s'il n'existe pas deja » (un declencheur de contrainte ne se
-- remplace pas par CREATE OR REPLACE).
--
-- Rejeu : idempotente (CREATE OR REPLACE, gardes sur les declencheurs et la
-- publication). Sur un Postgres nu sans publication supabase_realtime (CI), la
-- publication est ignoree ; la RLS, elle, est exigee partout.

BEGIN;

-- ------------------------------------------------------------------
-- 1. Les evenements et les destinations
-- ------------------------------------------------------------------
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
  -- Avant le 27/10 : toutes conservees.
  'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation',
  'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
  -- Fiche du 27/10, ligne 11.
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
  'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
  'classe_supprimee'));

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_destination_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK (
  destination IN (
    -- Avant le 27/10 : toutes conservees.
    '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
    '/admin/securite-audit/tirages', '/tuteur/foyer/recharge',
    -- Fiche du 27/10 : l'accueil de l'eleve, l'accueil du tuteur, les
    -- classes de l'enseignante, sa journee.
    '/eleve', '/tuteur', '/enseignant/classes', '/enseignant/journee')
  -- La classe d'un eleve du foyer, et son planning (routes du tuteur).
  OR destination ~ '^/tuteur/classes/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/planning)?$');

-- ------------------------------------------------------------------
-- 2. La fonction unique
-- ------------------------------------------------------------------
-- Ecrit une notification par personne concernee par la classe p_groupe_id :
--   * chaque eleve membre (ou les seuls eleves de p_eleves), portee « soi » ;
--   * les tuteurs du foyer de chacun, portee « foyer » ;
--   * l'enseignante de la classe et celles de p_enseignants, portee
--     « classe », sauf si p_sans_enseignant (absence declaree par elle-meme).
-- params : groupe_id, session_id (si p_session), portee, debut_local (si
-- p_instant, rendu dans le fuseau du foyer ou de l'enseignante). L'ecran ne
-- montre que portee et debut_local.
-- Idempotence : une personne deja prevenue du meme fait dans la meme
-- transaction (meme evenement, ou un evenement equivalent d'un chemin plus
-- ancien, pour la meme classe ou la meme seance) ne recoit rien. Rend le
-- nombre de lignes ecrites.
CREATE OR REPLACE FUNCTION private.notifier_classe(
  p_groupe_id uuid,
  p_evenement text,
  p_session uuid DEFAULT NULL,
  p_instant timestamptz DEFAULT NULL,
  p_eleves uuid[] DEFAULT NULL,
  p_enseignants uuid[] DEFAULT NULL,
  p_sans_enseignant boolean DEFAULT false
)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
  v_equivalents text[];
  v_n integer;
BEGIN
  IF p_groupe_id IS NULL OR p_evenement IS NULL THEN
    RETURN 0;
  END IF;
  SELECT * INTO v_groupe FROM public.groupes g WHERE g.id = p_groupe_id;

  -- Les evenements d'un chemin plus ancien qui disent deja le meme fait.
  v_equivalents := CASE p_evenement
    WHEN 'classe_creee'       THEN ARRAY['classe_validee', 'classe_changee']
    WHEN 'eleve_inscrit'      THEN ARRAY['classe_creee', 'classe_validee', 'classe_changee']
    WHEN 'eleve_retire'       THEN ARRAY['classe_changee', 'classe_supprimee']
    WHEN 'creneau_change'     THEN ARRAY['classe_creee', 'classe_validee']
    WHEN 'seance_annulee'     THEN ARRAY['classe_supprimee', 'classe_changee']
    WHEN 'enseignante_absente' THEN ARRAY['remplacement_propose']
    WHEN 'classe_supprimee'   THEN ARRAY['classe_changee']
    ELSE ARRAY[]::text[]
  END;

  WITH eleves AS (
    SELECT gm.student_id
      FROM public.groupe_membres gm
     WHERE gm.groupe_id = p_groupe_id
       AND p_eleves IS NULL
       AND (gm.left_at IS NULL
            -- Une classe fermee : ses membres sortent dans la meme
            -- transaction (cloturer_groupe) ; ils sont prevenus.
            OR (p_evenement = 'classe_supprimee' AND gm.left_at >= pg_catalog.now()))
    UNION
    SELECT e FROM pg_catalog.unnest(coalesce(p_eleves, ARRAY[]::uuid[])) AS e
  ),
  personnes AS (
    -- L'eleve lui-meme.
    SELECT p.id AS destinataire, p.household_id AS foyer, 'soi'::text AS portee,
           h.timezone AS fuseau, 1 AS rang
      FROM eleves e
      JOIN public.profiles p ON p.id = e.student_id AND p.deleted_at IS NULL
      LEFT JOIN public.households h ON h.id = p.household_id
    UNION ALL
    -- Les tuteurs de son foyer.
    SELECT t.id, p.household_id, 'foyer', h.timezone, 2
      FROM eleves e
      JOIN public.profiles p ON p.id = e.student_id AND p.deleted_at IS NULL
      JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
      JOIN public.profiles t ON t.deleted_at IS NULL
                            AND t.role = 'guardian'
                            AND (t.id = h.primary_guardian_id OR t.household_id = h.id)
     WHERE t.id <> e.student_id
    UNION ALL
    -- L'enseignante de la classe, et celles donnees (l'ancienne).
    SELECT x.id, NULL::uuid, 'classe', coalesce(tp.timezone_iana, v_groupe.timezone_iana), 3
      FROM (SELECT v_groupe.teacher_id AS id
            UNION
            SELECT e FROM pg_catalog.unnest(coalesce(p_enseignants, ARRAY[]::uuid[])) AS e) x
      JOIN public.profiles p ON p.id = x.id AND p.deleted_at IS NULL
      LEFT JOIN public.teacher_profiles tp ON tp.profile_id = x.id
     WHERE NOT p_sans_enseignant
  ),
  destinataires AS (
    -- Une personne, une ligne : l'eleve avant le tuteur avant l'enseignante.
    SELECT DISTINCT ON (destinataire) destinataire, foyer, portee, fuseau
      FROM personnes
     ORDER BY destinataire, rang
  )
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT d.destinataire, d.foyer, p_evenement,
         pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
           'groupe_id', p_groupe_id,
           'session_id', p_session,
           'portee', d.portee,
           'debut_local', CASE WHEN p_instant IS NULL THEN NULL
                               ELSE pg_catalog.to_char(
                                 p_instant AT TIME ZONE coalesce(d.fuseau, v_groupe.timezone_iana, 'UTC'),
                                 'YYYY-MM-DD"T"HH24:MI:SS') END)),
         CASE d.portee
           WHEN 'soi' THEN '/eleve'
           WHEN 'foyer' THEN
             CASE
               WHEN p_evenement IN ('eleve_retire', 'classe_supprimee') THEN '/tuteur'
               WHEN p_session IS NOT NULL THEN '/tuteur/classes/' || p_groupe_id::text || '/planning'
               ELSE '/tuteur/classes/' || p_groupe_id::text
             END
           ELSE
             CASE WHEN p_session IS NOT NULL THEN '/enseignant/journee'
                  ELSE '/enseignant/classes' END
         END
    FROM destinataires d
   WHERE NOT EXISTS (
     SELECT 1 FROM public.notifications n
      WHERE n.destinataire = d.destinataire
        AND n.cree_le = pg_catalog.now()
        AND (n.evenement = p_evenement OR n.evenement = ANY (v_equivalents))
        AND (n.params ->> 'groupe_id' IS NULL OR n.params ->> 'groupe_id' = p_groupe_id::text)
        AND (p_session IS NULL
             OR n.params ->> 'session_id' IS NULL
             OR n.params ->> 'session_id' = p_session::text)
   );
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- ------------------------------------------------------------------
-- 3. Les declencheurs (differes a la validation)
-- ------------------------------------------------------------------

-- Vrai quand la classe existe encore, ouverte, et n'est pas nee dans cette
-- transaction (sa creation dit deja tout : membres, creneaux).
CREATE OR REPLACE FUNCTION private.classe_ouverte_et_ancienne(p_groupe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.groupes g
     WHERE g.id = p_groupe_id
       AND g.ended_at IS NULL
       AND g.created_at < pg_catalog.now()
  );
$function$;

-- public.groupes : creation, enseignant affecte ou change, creneau d'ancre
-- change, fermeture (ended_at).
CREATE OR REPLACE FUNCTION private.notifier_classe_groupes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- L'etat final : une classe fermee (ou effacee) dans la meme transaction
    -- ne se dit pas.
    IF EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = NEW.id AND g.ended_at IS NULL) THEN
      PERFORM private.notifier_classe(NEW.id, 'classe_creee');
    END IF;
    RETURN NULL;
  END IF;

  -- UPDATE
  IF OLD.ended_at IS NULL AND NEW.ended_at IS NOT NULL THEN
    PERFORM private.notifier_classe(
      NEW.id, 'classe_supprimee',
      p_enseignants := ARRAY[OLD.teacher_id]);
    RETURN NULL;
  END IF;
  IF NEW.ended_at IS NOT NULL
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = NEW.id AND g.ended_at IS NULL) THEN
    RETURN NULL;
  END IF;

  IF OLD.teacher_id IS DISTINCT FROM NEW.teacher_id THEN
    IF OLD.teacher_id IS NULL THEN
      PERFORM private.notifier_classe(NEW.id, 'enseignant_affecte');
    ELSE
      PERFORM private.notifier_classe(
        NEW.id, 'enseignant_change',
        p_enseignants := ARRAY[OLD.teacher_id]);
    END IF;
  END IF;

  IF (OLD.weekday, OLD.hour_local, OLD.timezone_iana)
     IS DISTINCT FROM (NEW.weekday, NEW.hour_local, NEW.timezone_iana) THEN
    PERFORM private.notifier_classe(NEW.id, 'creneau_change');
  END IF;
  RETURN NULL;
END;
$function$;

-- public.groupes, effacement physique : les membres sont lus AVANT la cascade,
-- donc ce declencheur-la n'est pas differe.
CREATE OR REPLACE FUNCTION private.notifier_classe_groupes_effacee()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF OLD.ended_at IS NULL THEN
    PERFORM private.notifier_classe(
      OLD.id, 'classe_supprimee',
      p_enseignants := ARRAY[OLD.teacher_id]);
  END IF;
  RETURN OLD;
END;
$function$;

-- public.groupe_membres : eleve inscrit, eleve retire.
CREATE OR REPLACE FUNCTION private.notifier_classe_membres()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF EXISTS (SELECT 1 FROM public.groupe_membres gm WHERE gm.id = NEW.id AND gm.left_at IS NULL)
       AND private.classe_ouverte_et_ancienne(NEW.groupe_id) THEN
      PERFORM private.notifier_classe(
        NEW.groupe_id, 'eleve_inscrit', p_eleves := ARRAY[NEW.student_id]);
    END IF;
    RETURN NULL;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    -- La fermeture de la classe (qui sort ses membres) le dit deja.
    IF OLD.left_at IS NULL AND NEW.left_at IS NOT NULL
       AND EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = NEW.groupe_id AND g.ended_at IS NULL) THEN
      PERFORM private.notifier_classe(
        NEW.groupe_id, 'eleve_retire', p_eleves := ARRAY[NEW.student_id]);
    END IF;
    RETURN NULL;
  END IF;
  -- DELETE : une classe effacee (cascade) l'a deja dit, et n'existe plus.
  IF OLD.left_at IS NULL
     AND EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = OLD.groupe_id AND g.ended_at IS NULL) THEN
    PERFORM private.notifier_classe(
      OLD.groupe_id, 'eleve_retire', p_eleves := ARRAY[OLD.student_id]);
  END IF;
  RETURN NULL;
END;
$function$;

-- public.groupe_creneaux : creneau ajoute, change ou retire. Plusieurs
-- changements dans une transaction (remplacement de la liste) ne donnent
-- qu'une notification par personne.
CREATE OR REPLACE FUNCTION private.notifier_classe_creneaux()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid := CASE WHEN TG_OP = 'DELETE' THEN OLD.groupe_id ELSE NEW.groupe_id END;
BEGIN
  IF private.classe_ouverte_et_ancienne(v_groupe) THEN
    PERFORM private.notifier_classe(v_groupe, 'creneau_change');
  END IF;
  RETURN NULL;
END;
$function$;

-- public.sessions : seance annulee (statut, suppression douce ou effacement),
-- seance deplacee (started_at). Les creations de la cloche sont ignorees ;
-- une seance passee ne dit rien ; une classe fermee l'a deja dit.
CREATE OR REPLACE FUNCTION private.notifier_classe_seances()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_annules text[] := ARRAY['canceled', 'canceled_late'];
BEGIN
  IF TG_OP = 'INSERT' THEN
    RETURN NULL;
  END IF;
  IF OLD.groupe_id IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = OLD.groupe_id AND g.ended_at IS NULL) THEN
    RETURN NULL;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.deleted_at IS NULL
       AND NOT (OLD.status::text = ANY (v_annules))
       AND OLD.started_at > pg_catalog.now() THEN
      PERFORM private.notifier_classe(
        OLD.groupe_id, 'seance_annulee',
        p_session := OLD.id, p_instant := OLD.started_at,
        p_enseignants := ARRAY[OLD.teacher_id]);
    END IF;
    RETURN NULL;
  END IF;

  -- UPDATE
  IF (NOT (OLD.status::text = ANY (v_annules)) AND NEW.status::text = ANY (v_annules))
     OR (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL) THEN
    IF OLD.deleted_at IS NULL AND OLD.started_at > pg_catalog.now() THEN
      PERFORM private.notifier_classe(
        OLD.groupe_id, 'seance_annulee',
        p_session := NEW.id, p_instant := OLD.started_at,
        p_enseignants := ARRAY[NEW.teacher_id]);
    END IF;
    RETURN NULL;
  END IF;
  IF OLD.started_at IS DISTINCT FROM NEW.started_at
     AND NEW.deleted_at IS NULL
     AND NOT (NEW.status::text = ANY (v_annules))
     AND greatest(OLD.started_at, NEW.started_at) > pg_catalog.now() THEN
    PERFORM private.notifier_classe(
      coalesce(NEW.groupe_id, OLD.groupe_id), 'seance_deplacee',
      p_session := NEW.id, p_instant := NEW.started_at,
      p_enseignants := ARRAY[NEW.teacher_id]);
  END IF;
  RETURN NULL;
END;
$function$;

-- public.remplacements_seance : l'enseignante declare son absence, un
-- remplacement est pris. b09 previent deja les autres enseignants
-- (remplacement_propose, remplacement_pris) ; ici, les familles de la classe.
CREATE OR REPLACE FUNCTION private.notifier_classe_remplacements()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid;
  v_debut timestamptz;
BEGIN
  SELECT s.groupe_id, s.started_at INTO v_groupe, v_debut
    FROM public.sessions s
   WHERE s.id = NEW.session_id AND s.deleted_at IS NULL;
  IF v_groupe IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = v_groupe AND g.ended_at IS NULL) THEN
    RETURN NULL;
  END IF;
  PERFORM private.notifier_classe(
    v_groupe,
    CASE WHEN NEW.evenement = 'absence_declaree' THEN 'enseignante_absente'
         ELSE 'remplacement_pris' END,
    p_session := NEW.session_id, p_instant := v_debut,
    p_sans_enseignant := true);
  RETURN NULL;
END;
$function$;

-- Droits : aucune de ces fonctions n'est appelable par un client.
DO $droits$
DECLARE
  v_signature text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'private.notifier_classe(uuid,text,uuid,timestamptz,uuid[],uuid[],boolean)',
    'private.classe_ouverte_et_ancienne(uuid)',
    'private.notifier_classe_groupes()',
    'private.notifier_classe_groupes_effacee()',
    'private.notifier_classe_membres()',
    'private.notifier_classe_creneaux()',
    'private.notifier_classe_seances()',
    'private.notifier_classe_remplacements()'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_signature);
    EXECUTE pg_catalog.format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro',
      v_signature);
  END LOOP;
END
$droits$;

-- Les declencheurs : crees s'ils n'existent pas, jamais retires. Au rejeu,
-- rien ne change.
DO $declencheurs$
DECLARE
  v_nom text;
  v_sql text;
BEGIN
  FOR v_nom, v_sql IN
    SELECT * FROM (VALUES
      ('notifications_classe_groupes', $t$
        CREATE CONSTRAINT TRIGGER notifications_classe_groupes
          AFTER INSERT OR UPDATE OF teacher_id, ended_at, weekday, hour_local, timezone_iana
          ON public.groupes
          DEFERRABLE INITIALLY DEFERRED
          FOR EACH ROW EXECUTE FUNCTION private.notifier_classe_groupes()$t$),
      ('notifications_classe_groupes_effacee', $t$
        CREATE TRIGGER notifications_classe_groupes_effacee
          BEFORE DELETE ON public.groupes
          FOR EACH ROW EXECUTE FUNCTION private.notifier_classe_groupes_effacee()$t$),
      ('notifications_classe_membres', $t$
        CREATE CONSTRAINT TRIGGER notifications_classe_membres
          AFTER INSERT OR UPDATE OF left_at OR DELETE
          ON public.groupe_membres
          DEFERRABLE INITIALLY DEFERRED
          FOR EACH ROW EXECUTE FUNCTION private.notifier_classe_membres()$t$),
      ('notifications_classe_creneaux', $t$
        CREATE CONSTRAINT TRIGGER notifications_classe_creneaux
          AFTER INSERT OR UPDATE OR DELETE
          ON public.groupe_creneaux
          DEFERRABLE INITIALLY DEFERRED
          FOR EACH ROW EXECUTE FUNCTION private.notifier_classe_creneaux()$t$),
      ('notifications_classe_seances', $t$
        CREATE CONSTRAINT TRIGGER notifications_classe_seances
          AFTER UPDATE OF status, started_at, deleted_at OR DELETE
          ON public.sessions
          DEFERRABLE INITIALLY DEFERRED
          FOR EACH ROW EXECUTE FUNCTION private.notifier_classe_seances()$t$),
      ('notifications_classe_remplacements', $t$
        CREATE CONSTRAINT TRIGGER notifications_classe_remplacements
          AFTER INSERT
          ON public.remplacements_seance
          DEFERRABLE INITIALLY DEFERRED
          FOR EACH ROW EXECUTE FUNCTION private.notifier_classe_remplacements()$t$)
    ) AS d(nom, sql)
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_trigger t
       WHERE t.tgname = v_nom AND NOT t.tgisinternal
    ) THEN
      EXECUTE v_sql;
    END IF;
  END LOOP;
END
$declencheurs$;

-- ------------------------------------------------------------------
-- 4. Realtime : public.notifications, comme les quatre tables du lot 1
-- ------------------------------------------------------------------
DO $realtime$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication p
     WHERE p.pubname = 'supabase_realtime'
  ) THEN
    RETURN;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication_tables p
     WHERE p.pubname = 'supabase_realtime'
       AND p.schemaname = 'public'
       AND p.tablename = 'notifications'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications';
  END IF;
END;
$realtime$;

-- ------------------------------------------------------------------
-- 5. Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_signature text;
  v_oid pg_catalog.regprocedure;
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_trigger text;
  v_evenement text;
  v_check text;
  v_publication boolean;
BEGIN
  -- Les contraintes portent les douze evenements et les anciens.
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_check
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  FOREACH v_evenement IN ARRAY ARRAY[
    'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
    'remplacement_propose', 'remplacement_pris', 'demande_presentation',
    'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
    'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
    'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
    'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
    'classe_supprimee'
  ] LOOP
    IF coalesce(v_check, '') NOT LIKE '%''' || v_evenement || '''%' THEN
      RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : evenement % absent de la contrainte', v_evenement;
    END IF;
  END LOOP;
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_check
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_destination_check';
  IF coalesce(v_check, '') NOT LIKE '%''/eleve''%'
     OR v_check NOT LIKE '%''/tuteur/demandes''%'
     OR v_check NOT LIKE '%/tuteur/classes/%' THEN
    RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : contrainte de destination inattendue';
  END IF;

  -- Les fonctions : DEFINER, search_path vide, aucun client.
  FOREACH v_signature IN ARRAY ARRAY[
    'private.notifier_classe(uuid,text,uuid,timestamptz,uuid[],uuid[],boolean)',
    'private.classe_ouverte_et_ancienne(uuid)',
    'private.notifier_classe_groupes()',
    'private.notifier_classe_groupes_effacee()',
    'private.notifier_classe_membres()',
    'private.notifier_classe_creneaux()',
    'private.notifier_classe_seances()',
    'private.notifier_classe_remplacements()'
  ] LOOP
    v_oid := pg_catalog.to_regprocedure(v_signature);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : % absente', v_signature;
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_oid::oid;
    IF NOT v_p.prosecdef
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
       OR pg_catalog.has_function_privilege('public', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : DEFINER, search_path ou droits invalides pour %', v_signature;
    END IF;
  END LOOP;

  -- Les declencheurs sont la, et differes quand ils doivent l'etre.
  FOREACH v_trigger IN ARRAY ARRAY[
    'notifications_classe_groupes', 'notifications_classe_membres',
    'notifications_classe_creneaux', 'notifications_classe_seances',
    'notifications_classe_remplacements'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_trigger t
       WHERE t.tgname = v_trigger AND NOT t.tgisinternal
         AND t.tgdeferrable AND t.tginitdeferred
    ) THEN
      RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : declencheur % absent ou non differe', v_trigger;
    END IF;
  END LOOP;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
     WHERE t.tgname = 'notifications_classe_groupes_effacee' AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : declencheur d''effacement absent';
  END IF;
  -- Le courriel part toujours pour chaque ligne (23/10), une fois.
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
     WHERE t.tgrelid = 'public.notifications'::regclass
       AND t.tgname = 'courriel_notification' AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'NOTIFICATIONS-CLASSES postflight : le declencheur courriel_notification a disparu';
  END IF;

  -- RLS exigee, publication exigee si elle existe.
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relname = 'notifications' AND c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'notifications sans RLS : publication refusee';
  END IF;
  v_publication := EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication p WHERE p.pubname = 'supabase_realtime'
  );
  IF v_publication AND NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication_tables p
     WHERE p.pubname = 'supabase_realtime'
       AND p.schemaname = 'public'
       AND p.tablename = 'notifications'
  ) THEN
    RAISE EXCEPTION 'notifications absente de supabase_realtime';
  END IF;
END;
$postflight$;

COMMIT;
