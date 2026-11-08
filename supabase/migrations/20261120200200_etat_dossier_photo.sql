-- PERF-ATTENTE, dette 1 (garde-cap, 07/11/2026) : etat_dossier() rend l'etat de
-- la photo, pour la ligne « Votre photo » de la page unique « Votre
-- candidature » (agent E ; E branchera la ligne apres).
--
-- Deux cles ajoutees a la reponse de public.etat_dossier(), cote serveur
-- seulement :
--   photo_posee               vrai si l'enseignant (ou le candidat) a une photo
--                             (teacher_profiles.photo_storage_key non nul, la
--                             meme condition que le refus « photo_requise » de
--                             l'envoi des reponses) ; null pour tout autre role ;
--   accord_publication_signe  vrai si un accord de publication est en cours
--                             (accords_publication, retire_le nul) A LA VERSION
--                             PUBLIEE (app_config enseignants.publication_version,
--                             la meme condition que le refus « accord_publication_requis »
--                             de l'envoi) ; null pour tout autre role.
-- Les cles existantes ne changent pas ; un client qui ne les lit pas n'est pas
-- touche.
--
-- Remplacement par ANCRE, sur la definition en place relue en production le
-- 07/11/2026 (md5 de pg_get_functiondef 9b54e25652bf4c72fb86074d055f0ed8, le
-- meme que celui d'une base rejouee depuis le depot) ; le preflight s'arrete sur
-- tout autre etat, et l'ancre doit se trouver une seule fois. Rejouable : une
-- fonction qui porte deja les deux cles n'est pas retouchee.
--
-- Aucun mot d'effacement. Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.etat_dossier()'::regprocedure);
BEGIN
  IF pg_catalog.md5(v_def) <> '9b54e25652bf4c72fb86074d055f0ed8'
     AND (pg_catalog.strpos(v_def, '''photo_posee''') = 0
          OR pg_catalog.strpos(v_def, '''accord_publication_signe''') = 0) THEN
    RAISE EXCEPTION 'ETAT-DOSSIER-PHOTO : etat_dossier a change (md5 %), migration a revoir',
      pg_catalog.md5(v_def);
  END IF;
  IF pg_catalog.to_regclass('public.accords_publication') IS NULL
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                     WHERE a.attrelid = 'public.teacher_profiles'::regclass
                       AND a.attname = 'photo_storage_key' AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'ETAT-DOSSIER-PHOTO : CAND-PHOTO (20261110330000) n''est pas installe, arret';
  END IF;
END;
$preflight$;

DO $remplacement$
DECLARE
  v_oid oid := 'public.etat_dossier()'::regprocedure::oid;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_avant constant text := E'    ''candidature'', v_candidature\n  );';
  v_apres constant text := E'    ''candidature'', v_candidature,\n'
    || E'    -- PERF-ATTENTE dette 1 (07/11/2026) : la photo et l''accord de publication, pour la\n'
    || E'    -- ligne « Votre photo » ; null pour tout autre role que l''enseignant.\n'
    || E'    ''photo_posee'', case when v_profile.role = ''teacher'' then exists (\n'
    || E'      select 1 from public.teacher_profiles tp\n'
    || E'      where tp.profile_id = v_profile.id and tp.photo_storage_key is not null) end,\n'
    || E'    ''accord_publication_signe'', case when v_profile.role = ''teacher'' then exists (\n'
    || E'      select 1 from public.accords_publication ap\n'
    || E'      where ap.profile_id = v_profile.id and ap.retire_le is null\n'
    || E'        and ap.version = (select c.value #>> ''{}'' from public.app_config c\n'
    || E'                           where c.key = ''enseignants.publication_version'')) end\n'
    || E'  );';
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, '''photo_posee''') > 0 THEN
    RAISE NOTICE 'ETAT-DOSSIER-PHOTO : etat_dossier porte deja la photo, rien a faire';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
         / pg_catalog.length(v_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'ETAT-DOSSIER-PHOTO : ancre trouvee % fois au lieu de 1, migration a revoir', v_n;
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
END;
$remplacement$;

-- Droits restates (CREATE OR REPLACE les garde ; on les relit), empreinte F86 a jour.
DO $droits$
DECLARE
  v_oid regprocedure := 'public.etat_dossier()'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-07. CAND-L2A1 ; PERF-ATTENTE dette 1. Lecture du seul dossier de l appelant ; corps de 20261021210400 garde (code_conduite_signe) ; CAND-L2A1 : cle candidature (etape, etat, issue, pause par modele, questionnaire, cadre, conditions, paiement, a completer, complement demande, envoi possible), jamais un motif interne ; PERF-ATTENTE : photo_posee et accord_publication_signe (enseignant seulement, null sinon). Must-pass: supabase/tests/scenarios_cand_l2a1_moteur_salle_examen.sql ; supabase/tests/scenarios_etat_dossier_photo.sql.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.etat_dossier()'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
BEGIN
  IF pg_catalog.strpos(v_def, '''photo_posee''') = 0
     OR pg_catalog.strpos(v_def, '''accord_publication_signe''') = 0
     OR pg_catalog.strpos(v_def, '''candidature'', v_candidature') = 0
     OR pg_catalog.strpos(v_def, '''code_conduite_signe'', v_conduite') = 0 THEN
    RAISE EXCEPTION 'ETAT-DOSSIER-PHOTO : etat_dossier incomplete apres remplacement';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'ETAT-DOSSIER-PHOTO : droits ou search_path invalides sur etat_dossier';
  END IF;
END;
$postflight$;
