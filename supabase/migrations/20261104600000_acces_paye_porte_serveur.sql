-- Lot (B), fichier 2 sur 2 (02/11/2026) : sans paiement, ni seances ni
-- ressources ; l'espace reste ouvert pour le profil, l'historique et payer.
--
-- Regle du directeur (01/11/2026) : « quelqu'un qui ne paye pas n'a pas acces
-- aux sessions, ni aux ressources, seulement a son espace pour voir son
-- profil, son historique et eventuellement pouvoir payer ». Ordre du pilote du
-- 02/11 : une seule porte serveur, `private.acces_paye(profil)`, dont seul le
-- corps lit l'etat des paiements (un autre modele, des abonnements par
-- exemple, ne changerait que ce corps). Aucun calcul de paiement n'est modifie.
--
-- Aucun mot de suppression dans ce fichier : les politiques sont completees
-- par ALTER POLICY, les fonctions par CREATE OR REPLACE ou par remplacement
-- d'un passage ancre de leur texte (meme methode que 20261018170000_fac_f).
--
-- Ce qui ferme (eleve suspendu, ou tuteur dont aucun enfant concerne n'a un
-- acces paye) :
--   seance      : jeton video de l'observateur-tuteur (l'eleve l'etait deja),
--                 entrer_observation, seance_a_rejoindre ;
--   ressources  : autoriser_lecture_version, politiques library_resource_lecture
--                 et library_resource_groupe_lecture ; support de seance
--                 (support_actif_json, politique ssc_participant_read) ;
--   enregistrements : autoriser_ecoute_archive, politique
--                 session_recordings_teacher_family ;
--   travail a preparer : politique learning_assignment_membres
--                 (assignations_a_venir est SECURITY INVOKER) ;
--   messages    : fils avec l'enseignant (private.com_paires) et annonces de
--                 la Classe (private.com_lit_classe).
-- Ce qui reste ouvert : profil, historique (dont la lecture des anciens
-- messages, en lecture seule), payer, fil avec la direction, texte du Coran.
-- Reglages par defaut du pilote (02/11), a confirmer par le directeur : Coran
-- ouvert, enregistrements fermes, fil de la direction ouvert.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La porte et ses aides.
-- ---------------------------------------------------------------------------
-- La porte : un profil d'eleve a-t-il un acces paye ? Le seul corps qui lit
-- l'etat des paiements.
CREATE OR REPLACE FUNCTION private.acces_paye(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT NOT private.fac_eleve_suspendu(p_profil);
$function$;

-- Les eleves d'une seance : les membres actifs de sa Classe et les
-- participants inscrits comme eleves.
CREATE OR REPLACE FUNCTION private.acces_eleves_seance(p_session uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT m.student_id
    FROM public.sessions s
    JOIN public.groupe_membres m ON m.groupe_id = s.groupe_id AND m.left_at IS NULL
   WHERE s.id = p_session
  UNION
  SELECT sp.profile_id
    FROM public.session_participants sp
   WHERE sp.session_id = p_session AND sp.role = 'student' AND sp.deleted_at IS NULL;
$function$;

-- Pour un profil donne (eleve ou tuteur) : au moins un eleve de la seance, lui
-- ou de son foyer, a-t-il un acces paye ? Le foyer est lu dans les profils, pas
-- dans le jeton : utilisable sous service_role.
CREATE OR REPLACE FUNCTION private.acces_paye_seance_pour(p_session uuid, p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM private.acces_eleves_seance(p_session) e(id)
      JOIN public.profiles c ON c.id = e.id AND c.deleted_at IS NULL
      JOIN public.profiles moi ON moi.id = p_profil
     WHERE (c.id = moi.id
            OR (moi.role = 'guardian' AND moi.household_id IS NOT NULL
                AND c.household_id = moi.household_id))
       AND private.acces_paye(c.id));
$function$;

-- Meme question pour une Classe.
CREATE OR REPLACE FUNCTION private.acces_paye_groupe_pour(p_groupe uuid, p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM public.groupe_membres m
      JOIN public.profiles c ON c.id = m.student_id AND c.deleted_at IS NULL
      JOIN public.profiles moi ON moi.id = p_profil
     WHERE m.groupe_id = p_groupe AND m.left_at IS NULL
       AND (c.id = moi.id
            OR (moi.role = 'guardian' AND moi.household_id IS NOT NULL
                AND c.household_id = moi.household_id))
       AND private.acces_paye(c.id));
$function$;

-- Pour l'appelant (politiques et fonctions sous son jeton). Vrai pour tout
-- role autre qu'eleve ou tuteur : la direction, l'enseignant et le controle ne
-- sont pas concernes. Exigences POSITIVES (F86) : un role inconnu passe par le
-- ELSE et n'est pas ferme ici, les autres portes le ferment.
CREATE OR REPLACE FUNCTION private.acces_paye_seance(p_session uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE WHEN public.app_role() IN ('student', 'guardian')
              THEN private.acces_paye_seance_pour(p_session, auth.uid())
              ELSE true END;
$function$;

CREATE OR REPLACE FUNCTION private.acces_paye_groupe(p_groupe uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE WHEN public.app_role() IN ('student', 'guardian')
              THEN private.acces_paye_groupe_pour(p_groupe, auth.uid())
              ELSE true END;
$function$;

-- L'appelant, hors de toute seance ou Classe (ressources ouvertes a tous les
-- inscrits) : lui-meme, ou un eleve de son foyer, a-t-il un acces paye ?
CREATE OR REPLACE FUNCTION private.acces_paye_appelant()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE WHEN public.app_role() IN ('student', 'guardian')
              THEN EXISTS (
                SELECT 1
                  FROM public.student_profiles sp
                  JOIN public.profiles c ON c.id = sp.profile_id AND c.deleted_at IS NULL
                  JOIN public.profiles moi ON moi.id = auth.uid()
                 WHERE sp.deleted_at IS NULL
                   AND (c.id = moi.id
                        OR (moi.role = 'guardian' AND moi.household_id IS NOT NULL
                            AND c.household_id = moi.household_id))
                   AND private.acces_paye(c.id))
              ELSE true END;
$function$;

-- Droits : la porte et les aides « _pour » ne servent qu'aux fonctions
-- DEFINER ; les aides « appelant » servent aussi aux politiques (elles ne
-- disent rien d'autre que l'etat du foyer de l'appelant).
DO $droits$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.acces_paye(uuid)', 'private.acces_eleves_seance(uuid)',
    'private.acces_paye_seance_pour(uuid,uuid)', 'private.acces_paye_groupe_pour(uuid,uuid)',
    'private.acces_paye_seance(uuid)', 'private.acces_paye_groupe(uuid)',
    'private.acces_paye_appelant()'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', v_f);
  END LOOP;
END;
$droits$;
GRANT EXECUTE ON FUNCTION private.acces_paye_seance(uuid), private.acces_paye_groupe(uuid),
  private.acces_paye_appelant() TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. Les fonctions existantes : un passage ajoute a un endroit ancre.
-- ---------------------------------------------------------------------------
-- Remplace [p_ancre] par [p_ancre || p_ajout] dans la definition actuelle de
-- [p_fonction], une seule fois, puis la recree. Echoue si l'ancre manque ou
-- revient plusieurs fois (texte de la fonction change depuis ce fichier).
CREATE FUNCTION pg_temp.ajouter_apres(p_fonction regprocedure, p_ancre text, p_ajout text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'Lot B : ancre trouvee % fois dans %', v_n, p_fonction;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_ancre || p_ajout);
END;
$$;

-- 2.1 Jeton video : l'observateur-tuteur. L'eleve suspendu est deja refuse
-- (FAC-F-01) ; le tuteur qui observe ne l'etait pas.
SELECT pg_temp.ajouter_apres(
  'public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure,
  $a$  -- Le quota PRECEDE le jeton pour un observateur-tuteur : un jeton d'abord
  -- et un quota ensuite a deja laisse entrer (G §1.5, confirme par Q).
$a$,
  $b$  -- Lot (B), 02/11/2026 : un tuteur n'observe pas une seance si aucun eleve
  -- de son foyer dans cette seance n'a un acces paye.
  if v_role = 'guardian_observer'
     and not private.acces_paye_seance_pour(p_session_id, p_profile_id) then
    raise exception 'acces suspendu pour paiement' using errcode = 'insufficient_privilege';
  end if;
$b$);

-- 2.2 Entrer en observation : meme regle, refus motive.
SELECT pg_temp.ajouter_apres(
  'public.entrer_observation(uuid,text)'::regprocedure,
  $a$    if v_enfant is null then
      return jsonb_build_object('autorise', false, 'motif_refus', 'lien_tuteur_absent');
    end if;
$a$,
  $b$    -- Lot (B), 02/11/2026 : sans acces paye, pas d'observation.
    if not private.acces_paye_seance_pour(p_session_id, auth.uid()) then
      return jsonb_build_object('autorise', false, 'motif_refus', 'acces_suspendu');
    end if;
$b$);

-- 2.3 Le concierge de la Classe (ouvrir la seance du jour en la rejoignant).
SELECT pg_temp.ajouter_apres(
  'public.seance_a_rejoindre(uuid)'::regprocedure,
  $a$    RAISE EXCEPTION 'SeanceNonAutorisee' USING ERRCODE = '42501';
  END IF;
$a$,
  $b$  -- Lot (B), 02/11/2026 : sans acces paye, l'eleve ni son tuteur n'ouvrent
  -- la seance.
  IF NOT private.acces_paye_groupe(p_groupe_id) THEN
    RAISE EXCEPTION 'AccesSuspenduPaiement' USING ERRCODE = '42501';
  END IF;
$b$);

-- 2.4 Ecouter un enregistrement de seance.
SELECT pg_temp.ajouter_apres(
  'public.autoriser_ecoute_archive(uuid)'::regprocedure,
  $a$    raise exception 'ecoute refusee : aucune relation avec cette seance'
      using errcode = '42501';
  end if;
$a$,
  $b$
  -- Lot (B), 02/11/2026 : sans acces paye, pas d'ecoute (reglage par defaut du
  -- pilote : les enregistrements sont une ressource).
  if not private.acces_paye_seance(v_archive.session_id) then
    raise exception 'ecoute refusee : acces suspendu' using errcode = '42501';
  end if;
$b$);

-- 2.5 Lire une ressource de la bibliotheque.
SELECT pg_temp.ajouter_apres(
  'public.autoriser_lecture_version(uuid)'::regprocedure,
  $a$  v_role := public.app_role();
$a$,
  $b$
  -- Lot (B), 02/11/2026 : sans acces paye, pas de ressource.
  if not private.acces_paye_appelant() then
    raise exception 'lecture refusee' using errcode = '42501';
  end if;
$b$);

-- 2.6 Le support affiche en seance.
SELECT pg_temp.ajouter_apres(
  'app_private.support_actif_json(uuid)'::regprocedure,
  $a$  WHERE c.session_id = p_seance_id$a$,
  $b$
    AND private.acces_paye_seance(p_seance_id)$b$);

-- Les empreintes F86 des fonctions modifiees suivent leur nouveau texte.
DO $empreintes$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure,
    'public.entrer_observation(uuid,text)'::regprocedure,
    'public.seance_a_rejoindre(uuid)'::regprocedure,
    'public.autoriser_ecoute_archive(uuid)'::regprocedure,
    'public.autoriser_lecture_version(uuid)'::regprocedure,
    'app_private.support_actif_json(uuid)'::regprocedure] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$empreintes$;

-- ---------------------------------------------------------------------------
-- 3. Messages : les fils avec l'enseignant et les annonces de la Classe.
-- ---------------------------------------------------------------------------
-- Corps de 20261016090000_com_back_1_messages_metier.sql ; seule la derniere
-- condition change : une paire avec l'enseignant n'est permise que si un eleve
-- concerne a un acces paye. Les paires avec l'Administration (« equipe »)
-- restent. Un fil devenu non permis reste lisible en lecture seule par la
-- famille (regle C5 de com_fil_json, inchangee) : c'est son historique.
CREATE OR REPLACE FUNCTION private.com_paires(p_type text, p_objet_id uuid)
RETURNS TABLE (a_nature text, a_id uuid, b_nature text, b_id uuid)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  WITH membres AS (
    -- Eleves actifs d'une Classe active, avec leur enseignant valide.
    SELECT g.id AS groupe_id, g.teacher_id, s.id AS eleve_id, s.household_id,
           private.com_est_mineur(s.id) AS mineur
    FROM public.groupes g
    JOIN public.groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
    JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
    WHERE g.ended_at IS NULL
  ), cibles AS (
    -- Classe : chaque foyer d'un eleve mineur, chaque eleve adulte, avec
    -- l'enseignant ; foyer et Administration ; enseignant et Administration.
    SELECT 'foyer' AS a_nature, mb.household_id AS a_id, 'profil' AS b_nature, mb.teacher_id AS b_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND NOT mb.mineur
    UNION
    SELECT 'profil', g.teacher_id, 'equipe', NULL
      FROM public.groupes g WHERE p_type = 'classe' AND g.id = p_objet_id AND g.ended_at IS NULL
    -- Eleve : mineur, son foyer avec son enseignant et avec l'Administration ;
    -- adulte, lui-meme avec son enseignant.
    UNION
    SELECT 'foyer', mb.household_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND NOT mb.mineur
    -- Dossier (identifiant = profil du titulaire du dossier) : enseignant
    -- ou foyer du tuteur, avec l'Administration.
    UNION
    SELECT CASE p.role WHEN 'teacher' THEN 'profil' ELSE 'foyer' END,
           CASE p.role WHEN 'teacher' THEN p.id ELSE p.household_id END,
           'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'dossier' AND p.id = p_objet_id AND p.deleted_at IS NULL
        AND p.role IN ('teacher', 'guardian')
    -- Remplacement : titulaire et remplacant, chacun avec l'Administration.
    UNION
    SELECT 'profil', x.enseignant_id, 'equipe', NULL
      FROM public.remplacements_seance r
      CROSS JOIN LATERAL (VALUES (r.enseignant_titulaire_id), (r.enseignant_remplacant_id))
        AS x(enseignant_id)
      WHERE p_type = 'remplacement' AND r.id = p_objet_id AND x.enseignant_id IS NOT NULL
    -- Profil de paiement (CPT-BR-11) : le beneficiaire enseignant et l'equipe.
    UNION
    SELECT 'profil', p.id, 'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'profilPaiement' AND p.id = p_objet_id AND p.role = 'teacher'
  )
  SELECT c.a_nature, c.a_id, c.b_nature, c.b_id
  FROM cibles c
  WHERE c.a_id IS NOT NULL
    AND CASE c.a_nature
          WHEN 'foyer' THEN private.com_foyer_valide(c.a_id)
          ELSE private.com_profil_valide(c.a_id, NULL) AND NOT private.com_est_mineur(c.a_id)
        END
    AND (c.b_nature = 'equipe'
         OR (private.com_profil_valide(c.b_id, 'teacher') AND c.b_id <> c.a_id))
    -- Lot (B), 02/11/2026 : avec l'enseignant, seulement si un eleve concerne
    -- (l'adulte lui-meme, ou un eleve du foyer dans cette Classe ou cet eleve)
    -- a un acces paye.
    AND (c.b_nature = 'equipe'
         OR (c.a_nature = 'profil' AND private.acces_paye(c.a_id))
         OR (c.a_nature = 'foyer' AND EXISTS (
               SELECT 1 FROM membres mb
                WHERE mb.household_id = c.a_id
                  AND ((p_type = 'classe' AND mb.groupe_id = p_objet_id)
                       OR (p_type = 'eleve' AND mb.eleve_id = p_objet_id))
                  AND private.acces_paye(mb.eleve_id))));
$function$;

-- Corps de 20261016090100_com_back_1_annonces_classe.sql ; l'eleve (ou le
-- foyer) ne lit les annonces de la Classe que si l'eleve membre a un acces paye.
CREATE OR REPLACE FUNCTION private.com_lit_classe(p_groupe_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(public.app_account_valid(), false)
    AND private.com_profil_valide(auth.uid(), public.app_role()::text)
    AND EXISTS (
      SELECT 1 FROM public.groupes g
      WHERE g.id = p_groupe_id AND g.ended_at IS NULL
        AND (
          (public.app_role() = 'admin')
          OR (public.app_role() = 'teacher' AND g.teacher_id = auth.uid())
          OR EXISTS (
            SELECT 1 FROM public.groupe_membres m
            JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
            JOIN public.profiles moi ON moi.id = auth.uid()
            WHERE m.groupe_id = g.id AND m.left_at IS NULL
              AND (s.id = moi.id
                   OR (moi.role = 'guardian' AND moi.household_id IS NOT NULL
                       AND s.household_id = moi.household_id))
              -- Lot (B), 02/11/2026.
              AND private.acces_paye(s.id))));
$function$;

-- ---------------------------------------------------------------------------
-- 4. Les politiques de lecture : une condition ajoutee a la fin.
-- ---------------------------------------------------------------------------
-- La condition existante est relue dans le catalogue et gardee telle quelle ;
-- la porte s'y ajoute par AND. Toutes sont des politiques FOR SELECT.
--   library_resource_lecture          (public.library_resource)
--   library_resource_groupe_lecture   (public.library_resource_groupe)
--   ssc_participant_read              (public.session_shared_content)
--   session_recordings_teacher_family (public.session_recordings)
--   learning_assignment_membres       (public.learning_assignment)
DO $politiques$
DECLARE
  r record;
  v_qual text;
BEGIN
  FOR r IN SELECT * FROM (VALUES
      ('library_resource_lecture', 'library_resource', 'private.acces_paye_appelant()'),
      ('library_resource_groupe_lecture', 'library_resource_groupe', 'private.acces_paye_groupe(groupe_id)'),
      ('ssc_participant_read', 'session_shared_content', 'private.acces_paye_seance(session_id)'),
      ('session_recordings_teacher_family', 'session_recordings', 'private.acces_paye_seance(session_id)'),
      ('learning_assignment_membres', 'learning_assignment', 'private.acces_paye_groupe(group_id)')
    ) AS x(politique, table_nom, porte) LOOP
    SELECT p.qual INTO v_qual FROM pg_catalog.pg_policies p
     WHERE p.schemaname = 'public' AND p.tablename = r.table_nom AND p.policyname = r.politique
       AND p.cmd = 'SELECT';
    IF v_qual IS NULL THEN
      RAISE EXCEPTION 'Lot B : politique % absente sur %', r.politique, r.table_nom;
    END IF;
    IF pg_catalog.strpos(v_qual, 'acces_paye') = 0 THEN
      EXECUTE pg_catalog.format('ALTER POLICY %I ON public.%I USING ((%s) AND %s)',
        r.politique, r.table_nom, v_qual, r.porte);
    END IF;
  END LOOP;
END;
$politiques$;

-- ---------------------------------------------------------------------------
-- 5. Une bourse de 100 % leve la suspension tout de suite.
-- ---------------------------------------------------------------------------
-- La bourse ne finance pas les factures deja emises (20261018120000_fac_e) ;
-- sans ce declencheur, l'eleve restait suspendu. Motif « bourse » admis par
-- le fichier 1 (20261104500000).
CREATE OR REPLACE FUNCTION private.acces_lever_par_bourse()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  s public.acces_suspensions_paiement;
  v_n integer;
  v_mois date := private.fac_mois_courant();
BEGIN
  IF NEW.retiree_le IS NOT NULL OR NEW.pour_mille < 1000
     OR NEW.mois_debut > v_mois OR NEW.mois_fin < v_mois THEN
    RETURN NEW;
  END IF;
  SELECT * INTO s FROM public.acces_suspensions_paiement
   WHERE profile_id = NEW.profile_id AND retabli_le IS NULL FOR UPDATE;
  IF s.id IS NULL THEN
    RETURN NEW;
  END IF;
  UPDATE public.acces_suspensions_paiement
     SET retabli_le = pg_catalog.clock_timestamp(), retabli_motif = 'bourse'
   WHERE id = s.id;
  v_n := private.fac_notifier_paiement(NEW.profile_id, 'acces_retabli_paiement', '{}'::jsonb);
  INSERT INTO public.relances_paiement (facture_id, profile_id, action, jour, destinataires)
  VALUES (s.facture_id, NEW.profile_id, 'retablissement', private.fac_aujourdhui(), v_n);
  PERFORM public.log_sensitive_access('acces_retabli_paiement', 'acces_suspensions_paiement', s.id::text,
    pg_catalog.jsonb_build_object('profile_id', NEW.profile_id, 'facture_id', s.facture_id,
      'motif', 'bourse', 'destinataires', v_n));
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.acces_lever_par_bourse() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.acces_lever_par_bourse() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER bourses_eleves_leve_suspension
  AFTER INSERT ON public.bourses_eleves
  FOR EACH ROW EXECUTE FUNCTION private.acces_lever_par_bourse();

-- ---------------------------------------------------------------------------
-- 6. Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  r record;
BEGIN
  -- La porte : un seul corps lit les suspensions.
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.acces_paye(uuid)'::regprocedure),
                       'fac_eleve_suspendu') = 0 THEN
    RAISE EXCEPTION 'Lot B : acces_paye ne lit pas les suspensions';
  END IF;
  -- Les fonctions modifiees appellent la porte ; le jeton garde FAC-F-01.
  FOR r IN SELECT * FROM (VALUES
      ('public.autoriser_jeton_video(uuid,uuid,text,text)', 'acces_paye_seance_pour'),
      ('public.autoriser_jeton_video(uuid,uuid,text,text)', 'fac_eleve_suspendu'),
      ('public.entrer_observation(uuid,text)', 'acces_paye_seance_pour'),
      ('public.seance_a_rejoindre(uuid)', 'acces_paye_groupe'),
      ('public.autoriser_ecoute_archive(uuid)', 'acces_paye_seance'),
      ('public.autoriser_lecture_version(uuid)', 'acces_paye_appelant'),
      ('app_private.support_actif_json(uuid)', 'acces_paye_seance'),
      ('private.com_paires(text,uuid)', 'acces_paye'),
      ('private.com_lit_classe(uuid)', 'acces_paye')) AS x(f, mot) LOOP
    IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(r.f::regprocedure), r.mot) = 0 THEN
      RAISE EXCEPTION 'Lot B : % sans %', r.f, r.mot;
    END IF;
  END LOOP;
  -- Les cinq politiques portent la porte.
  IF (SELECT count(*) FROM pg_catalog.pg_policies p
       WHERE p.schemaname = 'public'
         AND p.policyname IN ('library_resource_lecture', 'library_resource_groupe_lecture',
                              'ssc_participant_read', 'session_recordings_teacher_family',
                              'learning_assignment_membres')
         AND pg_catalog.strpos(p.qual, 'acces_paye') > 0) <> 5 THEN
    RAISE EXCEPTION 'Lot B : une politique de lecture sans la porte';
  END IF;
  -- Droits : la porte n'est pas appelable par un client ; les aides de
  -- l'appelant le sont, et seulement par authenticated.
  IF pg_catalog.has_function_privilege('authenticated', 'private.acces_paye(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.acces_paye_seance_pour(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.acces_paye_seance(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'private.acces_paye_seance(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Lot B : droits de la porte incorrects';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgname = 'bourses_eleves_leve_suspension'
                    AND t.tgrelid = 'public.bourses_eleves'::regclass) THEN
    RAISE EXCEPTION 'Lot B : declencheur de la bourse absent';
  END IF;
END;
$postflight$;

COMMIT;
