-- FN-028 (lot « Fin de seance », etape 3), decisions du directeur du 01/11/2026
-- (docs/current/DECISION-NOTIFICATIONS-COURRIEL-2026-11-01.md) et arbitrage du
-- pilote du meme jour : l'avis de fin de seance, dans l'application seulement,
-- et le drapeau « courriel » par evenement et par portee.
--
-- Ce fichier contient UN mot de suppression : « DROP CONSTRAINT IF EXISTS
-- notifications_evenement_check » (section 1), recreee aussitot avec les 28
-- evenements de production (liste de 20261103400000, verifiee par le pilote le
-- 01/11 a 10:45) plus « seance_terminee ». Aucune donnee n'est supprimee. Un
-- seul BEGIN; et un seul COMMIT;, seuls sur leur ligne (page de collage).
--
-- 1. Contrainte des evenements : 29 valeurs, controlees en fin de fichier.
-- 2. private.notification_courriel (evenement, portee, courriel) : la table du
--    §3 de la decision. Une ligne « * » vaut toutes les portees. Un evenement
--    absent (dont les six « non classes ») garde le courriel : comportement
--    d'avant ce fichier. Aucune valeur dans Flutter.
-- 3. public.courriel_depuis_notification() remplacee EN ENTIER (CREATE OR
--    REPLACE). Corps de base : 20261103400000_paiement_recu_courriel.sql,
--    section 2, recopie ci-dessous ; la seule difference est le test du
--    drapeau avant `courriel_enfiler`.
--
--      BEGIN
--        PERFORM public.courriel_enfiler(
--          CASE
--            WHEN NEW.evenement IN ('paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
--                                   'paiement_recu')
--              THEN 'facturation'
--            WHEN NEW.evenement IN ('demande_recue', 'classe_validee', 'demande_close', 'demande_presentation')
--              THEN 'inscription'
--            ELSE 'classes' END,
--          NEW.evenement,
--          public.courriel_adresse_profil(NEW.destinataire),
--          NEW.destinataire,
--          NEW.params || pg_catalog.jsonb_build_object('destination', NEW.destination),
--          'notification:' || NEW.id::text);
--        RETURN NULL;
--      END;
--
-- 4. L'avis « seance_terminee » :
--    * l'enseignant effectif (`private.c29_enseignant_effectif_session`,
--      sinon le titulaire), portee « classe », a la cloture (statut passe a
--      `ended` : cloture automatique ou « Quitter et ouvrir le cahier ») ;
--      params : presents (`private.pai_eleves_presents`, source unique de la
--      paie), inscrits, cahier_depose ;
--    * l'eleve (portee « soi ») et, s'il est mineur (`private.com_est_mineur`,
--      fonction existante), les tuteurs de son foyer (portee « foyer », meme
--      jointure que `private.notifier_classe`, qui ne sait ni filtrer les
--      mineurs ni porter ces parametres), quand la seance est close ET le
--      cahier depose, au second des deux evenements ;
--    * le Travail a preparer ne parait que si la regle de partage effective de
--      l'eleve l'ouvre (`private.partage_regle_effective`, existante) :
--      `travail_etat` = « partage » (ligne de travail), « aucun » (cahier
--      partage sans travail pour cet eleve), « non_partage » (rien n'est dit
--      du travail) ;
--    * un seul avis par seance et par destinataire (index unique partiel),
--      meme si le cahier est corrige ou redepose.
--    Courriel : jamais (lignes « seance_terminee » de la section 2).

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Les evenements admis : la liste de production, plus seance_terminee.
-- ---------------------------------------------------------------------------
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
  'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation',
  'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
  'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
  'classe_supprimee',
  'remplacement_avertissement', 'remplacement_pre_alerte', 'remplacement_inutile',
  'titulaire_en_retard', 'remplacant_arrive',
  'paiement_recu',
  -- FN-028 (01/11/2026).
  'seance_terminee'));

-- ---------------------------------------------------------------------------
-- 2. Courriel ou application seulement (decision du 01/11/2026, §3).
-- ---------------------------------------------------------------------------
CREATE TABLE private.notification_courriel (
  evenement text NOT NULL,
  portee text NOT NULL CHECK (portee IN ('*', 'soi', 'foyer', 'classe', 'direction')),
  courriel boolean NOT NULL,
  PRIMARY KEY (evenement, portee)
);
ALTER TABLE private.notification_courriel ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.notification_courriel FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE private.notification_courriel IS
  'DECISION-NOTIFICATIONS-COURRIEL (01/11/2026) : un courriel part en plus de la notification seulement si la ligne le dit ; portee « * » = toutes ; evenement absent = courriel (etat d''avant). Lue par public.courriel_depuis_notification.';

INSERT INTO private.notification_courriel (evenement, portee, courriel) VALUES
  -- Courriel et application (urgent ou trace).
  ('seance_annulee', '*', true),
  ('seance_deplacee', '*', true),
  ('enseignante_absente', '*', true),
  ('remplacement_propose', '*', true),
  ('remplacement_pris', '*', true),
  ('creneau_change', '*', true),
  ('classe_creee', 'soi', true),
  ('classe_creee', 'foyer', true),
  ('classe_validee', 'soi', true),
  ('classe_validee', 'foyer', true),
  ('eleve_inscrit', 'soi', true),
  ('eleve_inscrit', 'foyer', true),
  ('acces_suspendu_paiement', '*', true),
  ('acces_retabli_paiement', '*', true),
  ('paiement_relance', '*', true),
  ('demande_recue', '*', true),
  ('demande_close', '*', true),
  -- Application seulement.
  ('seance_terminee', '*', false),
  ('eleve_inscrit', 'classe', false),
  ('eleve_retire', 'classe', false),
  ('enseignant_affecte', 'classe', false),
  ('enseignant_change', 'classe', false),
  ('classe_changee', '*', false),
  ('titulaire_en_retard', '*', false),
  ('remplacant_arrive', '*', false);

-- Vrai si la notification [p_evenement] de portee [p_portee] part aussi par
-- courriel : la ligne exacte, sinon la ligne « * », sinon oui (etat d'avant).
CREATE FUNCTION private.notification_avec_courriel(p_evenement text, p_portee text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT c.courriel FROM private.notification_courriel c
      WHERE c.evenement = p_evenement AND c.portee = p_portee),
    (SELECT c.courriel FROM private.notification_courriel c
      WHERE c.evenement = p_evenement AND c.portee = '*'),
    true);
$function$;

-- ---------------------------------------------------------------------------
-- 3. Le declencheur des courriels lit le drapeau (corps de base en en-tete).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.courriel_depuis_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- DECISION-NOTIFICATIONS-COURRIEL (01/11/2026) : application seulement.
  IF NOT private.notification_avec_courriel(NEW.evenement, NEW.params ->> 'portee') THEN
    RETURN NULL;
  END IF;
  PERFORM public.courriel_enfiler(
    CASE
      WHEN NEW.evenement IN ('paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
                             'paiement_recu')
        THEN 'facturation'
      WHEN NEW.evenement IN ('demande_recue', 'classe_validee', 'demande_close', 'demande_presentation')
        THEN 'inscription'
      ELSE 'classes' END,
    NEW.evenement,
    public.courriel_adresse_profil(NEW.destinataire),
    NEW.destinataire,
    NEW.params || pg_catalog.jsonb_build_object('destination', NEW.destination),
    'notification:' || NEW.id::text);
  RETURN NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. L'avis de fin de seance.
-- ---------------------------------------------------------------------------

-- Un seul avis par seance et par destinataire, quoi qu'il arrive au cahier.
CREATE UNIQUE INDEX notifications_seance_terminee_unique
  ON public.notifications (destinataire, (params ->> 'session_id'))
  WHERE evenement = 'seance_terminee';

-- L'avis de l'enseignant, a la cloture. Rend le nombre de lignes ecrites.
CREATE FUNCTION private.avis_seance_terminee_enseignant(p_session uuid)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions%ROWTYPE;
  v_g public.groupes%ROWTYPE;
  v_ens uuid;
  v_fuseau text;
  v_n integer;
BEGIN
  SELECT * INTO v_s FROM public.sessions s
   WHERE s.id = p_session AND s.deleted_at IS NULL AND s.status = 'ended';
  IF NOT FOUND OR v_s.groupe_id IS NULL THEN
    RETURN 0;
  END IF;
  SELECT * INTO v_g FROM public.groupes g WHERE g.id = v_s.groupe_id;
  v_ens := coalesce(private.c29_enseignant_effectif_session(p_session), v_s.teacher_id);
  IF v_ens IS NULL THEN
    RETURN 0;
  END IF;
  SELECT coalesce(tp.timezone_iana, v_g.timezone_iana, 'UTC') INTO v_fuseau
    FROM (SELECT 1) un
    LEFT JOIN public.teacher_profiles tp ON tp.profile_id = v_ens;

  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT v_ens, NULL, 'seance_terminee',
         pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
           'groupe_id', v_s.groupe_id,
           'session_id', p_session,
           'portee', 'classe',
           'classe', v_g.libelle,
           'debut_local', pg_catalog.to_char(v_s.started_at AT TIME ZONE v_fuseau,
                                             'YYYY-MM-DD"T"HH24:MI:SS'),
           'presents', private.pai_eleves_presents(p_session),
           'inscrits', (SELECT count(DISTINCT sp.profile_id)::integer
                          FROM public.session_participants sp
                         WHERE sp.session_id = p_session AND sp.role = 'student'
                           AND sp.deleted_at IS NULL),
           'cahier_depose', EXISTS (SELECT 1 FROM public.lesson_reports lr
                                     WHERE lr.session_id = p_session AND lr.deleted_at IS NULL))),
         '/enseignant/journee'
    FROM public.profiles p
   WHERE p.id = v_ens AND p.deleted_at IS NULL
  ON CONFLICT (destinataire, (params ->> 'session_id')) WHERE evenement = 'seance_terminee'
  DO NOTHING;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- L'avis de l'eleve et de ses tuteurs (s'il est mineur) : seulement quand la
-- seance est close ET le cahier depose. Le premier cahier depose fait foi.
CREATE FUNCTION private.avis_seance_terminee_famille(p_session uuid)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions%ROWTYPE;
  v_g public.groupes%ROWTYPE;
  v_contenu jsonb;
  v_n integer;
BEGIN
  SELECT * INTO v_s FROM public.sessions s
   WHERE s.id = p_session AND s.deleted_at IS NULL AND s.status = 'ended';
  IF NOT FOUND OR v_s.groupe_id IS NULL THEN
    RETURN 0;
  END IF;
  SELECT lr.content INTO v_contenu FROM public.lesson_reports lr
   WHERE lr.session_id = p_session AND lr.deleted_at IS NULL
   ORDER BY lr.created_at, lr.id
   LIMIT 1;
  IF NOT FOUND THEN
    RETURN 0;
  END IF;
  SELECT * INTO v_g FROM public.groupes g WHERE g.id = v_s.groupe_id;

  WITH eleves AS (
    SELECT DISTINCT sp.profile_id AS eleve
      FROM public.session_participants sp
     WHERE sp.session_id = p_session AND sp.role = 'student' AND sp.deleted_at IS NULL
  ),
  travail AS (
    SELECT e.eleve,
           coalesce((SELECT r.actif FROM private.partage_regle_effective(v_s.groupe_id, e.eleve) r), false)
             AS partage,
           nullif(pg_catalog.btrim(pg_catalog.regexp_replace(
             coalesce((SELECT x ->> 'travail_maison'
                         FROM pg_catalog.jsonb_array_elements(
                                CASE WHEN pg_catalog.jsonb_typeof(v_contenu -> 'eleves') = 'array'
                                     THEN v_contenu -> 'eleves' ELSE '[]'::jsonb END) x
                        WHERE x ->> 'student_id' = e.eleve::text
                        LIMIT 1), ''),
             '\s*\r?\n\s*', ' · ', 'g')), '') AS texte
      FROM eleves e
  ),
  personnes AS (
    -- L'eleve lui-meme.
    SELECT p.id AS destinataire, p.household_id AS foyer, 'soi'::text AS portee,
           h.timezone AS fuseau, t.eleve, t.partage, t.texte, 1 AS rang
      FROM travail t
      JOIN public.profiles p ON p.id = t.eleve AND p.deleted_at IS NULL
      LEFT JOIN public.households h ON h.id = p.household_id
    UNION ALL
    -- Les tuteurs de son foyer, s'il est mineur (meme jointure que
    -- private.notifier_classe).
    SELECT tu.id, p.household_id, 'foyer', h.timezone, t.eleve, t.partage, t.texte, 2
      FROM travail t
      JOIN public.profiles p ON p.id = t.eleve AND p.deleted_at IS NULL
      JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
      JOIN public.profiles tu ON tu.deleted_at IS NULL
                             AND tu.role = 'guardian'
                             AND (tu.id = h.primary_guardian_id OR tu.household_id = h.id)
     WHERE tu.id <> t.eleve
       AND private.com_est_mineur(t.eleve)
  ),
  destinataires AS (
    SELECT DISTINCT ON (destinataire) *
      FROM personnes
     ORDER BY destinataire, rang, eleve
  )
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT d.destinataire, d.foyer, 'seance_terminee',
         pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
           'groupe_id', v_s.groupe_id,
           'session_id', p_session,
           'portee', d.portee,
           'classe', v_g.libelle,
           'debut_local', pg_catalog.to_char(
             v_s.started_at AT TIME ZONE coalesce(d.fuseau, v_g.timezone_iana, 'UTC'),
             'YYYY-MM-DD"T"HH24:MI:SS'),
           'travail_etat', CASE WHEN NOT d.partage THEN 'non_partage'
                                WHEN d.texte IS NULL THEN 'aucun'
                                ELSE 'partage' END,
           'travail', CASE WHEN d.partage THEN d.texte END)),
         CASE d.portee
           WHEN 'soi' THEN '/eleve'
           ELSE '/tuteur/classes/' || v_s.groupe_id::text || '/planning'
         END
    FROM destinataires d
  ON CONFLICT (destinataire, (params ->> 'session_id')) WHERE evenement = 'seance_terminee'
  DO NOTHING;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- La cloture : l'enseignant, et la famille si le cahier est deja depose.
CREATE FUNCTION private.avis_seance_terminee_cloture()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM private.avis_seance_terminee_enseignant(NEW.id);
  PERFORM private.avis_seance_terminee_famille(NEW.id);
  RETURN NULL;
END;
$function$;

CREATE TRIGGER seance_terminee_avis_cloture
  AFTER UPDATE OF status ON public.sessions
  FOR EACH ROW
  WHEN (NEW.status = 'ended' AND OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.avis_seance_terminee_cloture();

-- Le depot du cahier : la famille, si la seance est deja close.
CREATE FUNCTION private.avis_seance_terminee_cahier()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM private.avis_seance_terminee_famille(NEW.session_id);
  RETURN NULL;
END;
$function$;

CREATE TRIGGER seance_terminee_avis_cahier
  AFTER INSERT ON public.lesson_reports
  FOR EACH ROW
  WHEN (NEW.deleted_at IS NULL)
  EXECUTE FUNCTION private.avis_seance_terminee_cahier();

-- ---------------------------------------------------------------------------
-- 5. Droits : rien de ce fichier n'est appelable par un compte.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.notification_avec_courriel(text,text)'::pg_catalog.regprocedure,
    'private.avis_seance_terminee_enseignant(uuid)'::pg_catalog.regprocedure,
    'private.avis_seance_terminee_famille(uuid)'::pg_catalog.regprocedure,
    'private.avis_seance_terminee_cloture()'::pg_catalog.regprocedure,
    'private.avis_seance_terminee_cahier()'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE ALL ON private.notification_courriel FROM agent_ro;
  END IF;
END;
$droits$;

-- ---------------------------------------------------------------------------
-- 6. Controles : la contrainte porte exactement les 29 evenements ; rien
--    n'est ouvert au client.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_attendu text[] := ARRAY[
    'acces_retabli_paiement', 'acces_suspendu_paiement', 'classe_changee', 'classe_creee',
    'classe_supprimee', 'classe_validee', 'controle_mission_attribuee',
    'controle_mission_non_controlee', 'creneau_change', 'demande_close', 'demande_presentation',
    'demande_recue', 'eleve_inscrit', 'eleve_retire', 'enseignant_affecte', 'enseignant_change',
    'enseignante_absente', 'paiement_recu', 'paiement_relance', 'remplacant_arrive',
    'remplacement_avertissement', 'remplacement_inutile', 'remplacement_pre_alerte',
    'remplacement_pris', 'remplacement_propose', 'seance_annulee', 'seance_deplacee',
    'seance_terminee', 'titulaire_en_retard'];
  v_trouve text[];
BEGIN
  SELECT pg_catalog.array_agg(m[1] ORDER BY m[1]) INTO v_trouve
    FROM pg_catalog.pg_constraint c,
         LATERAL pg_catalog.regexp_matches(pg_catalog.pg_get_constraintdef(c.oid), '''([a-z_]+)''', 'g') m
   WHERE c.conname = 'notifications_evenement_check'
     AND c.conrelid = 'public.notifications'::pg_catalog.regclass;
  IF pg_catalog.cardinality(v_attendu) <> 29 OR v_trouve IS DISTINCT FROM v_attendu THEN
    RAISE EXCEPTION 'FN-028 : notifications_evenement_check ne porte pas les 29 evenements attendus : %', v_trouve;
  END IF;
  IF has_function_privilege('authenticated', 'private.avis_seance_terminee_famille(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'private.avis_seance_terminee_enseignant(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.notification_avec_courriel(text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-028 : une fonction de l''avis est ouverte au client';
  END IF;
  IF NOT private.notification_avec_courriel('seance_annulee', 'soi')
     OR private.notification_avec_courriel('seance_terminee', 'foyer')
     OR NOT private.notification_avec_courriel('classe_supprimee', 'soi') THEN
    RAISE EXCEPTION 'FN-028 : le drapeau courriel ne suit pas la decision du 01/11';
  END IF;
END;
$postflight$;

COMMIT;
