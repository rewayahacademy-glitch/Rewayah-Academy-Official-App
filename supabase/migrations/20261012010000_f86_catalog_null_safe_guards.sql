BEGIN;
SET LOCAL search_path = '';

DO $f86_patch$
DECLARE
  v_definition text;
  v_before text;
  v_after text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(
    'public.annonces_observation(uuid)'::pg_catalog.regprocedure
  );
  v_before := 'v_seance.teacher_id <> auth.uid()';
  v_after := 'v_seance.teacher_id IS DISTINCT FROM auth.uid()';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected annonces_observation definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;

  v_definition := pg_catalog.pg_get_functiondef(
    'public.transmettre_student_concern(uuid,text)'::pg_catalog.regprocedure
  );
  v_before := 'v_expected_target is null or p_cible <> v_expected_target';
  v_after := 'v_expected_target is null or p_cible IS DISTINCT FROM v_expected_target';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected transmettre_student_concern definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;

  v_definition := pg_catalog.pg_get_functiondef(
    'public.creer_offre_horaire(text,text,text,smallint[],smallint,smallint)'::pg_catalog.regprocedure
  );
  v_before := 'if array_length(p_jours, 1) <> v_attendu then';
  v_after := 'if array_length(p_jours, 1) IS DISTINCT FROM v_attendu then';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected creer_offre_horaire definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;
END
$f86_patch$;

COMMENT ON FUNCTION public.annonces_observation(uuid) IS
  'F86 candidate allowlist: signature=public.annonces_observation(uuid); md5_functiondef=741a3984a5c2f280c06241c724e52b83; guard_type=NULL_SAFE_OWNERSHIP; owner=postgres; search_path=""; reviewer=Claude; source=catalogue-canon-fixes@74be57a2.';
COMMENT ON FUNCTION public.transmettre_student_concern(uuid,text) IS
  'F86 candidate allowlist: signature=public.transmettre_student_concern(uuid,text); md5_functiondef=25e186c690932a686da4bb644aae1023; guard_type=NULL_SAFE_TARGET_INTEGRITY; owner=postgres; search_path=""; reviewer=Claude; source=catalogue-canon-fixes@74be57a2.';
COMMENT ON FUNCTION public.creer_offre_horaire(text,text,text,smallint[],smallint,smallint) IS
  'F86 candidate allowlist: signature=public.creer_offre_horaire(text,text,text,smallint[],smallint,smallint); md5_functiondef=4d8a856e87355b5fcba607603aa4ab97; guard_type=NULL_CONFIG_DEFENSIVE; owner=postgres; search_path=""; reviewer=Claude; source=catalogue-canon-fixes@74be57a2.';

DO $f86_postflight$
DECLARE
  v_definition text;
  v_signature text;
  v_oid pg_catalog.regprocedure;
  v_owner text;
  v_config text[];
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(
    'public.annonces_observation(uuid)'::pg_catalog.regprocedure
  );
  IF pg_catalog.strpos(v_definition, 'IS DISTINCT FROM auth.uid()') = 0
     OR pg_catalog.has_function_privilege('anon', 'public.annonces_observation(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.annonces_observation(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'F86 postflight: annonces_observation invalid';
  END IF;

  v_definition := pg_catalog.pg_get_functiondef(
    'public.transmettre_student_concern(uuid,text)'::pg_catalog.regprocedure
  );
  IF pg_catalog.strpos(v_definition, 'p_cible IS DISTINCT FROM v_expected_target') = 0 THEN
    RAISE EXCEPTION 'F86 postflight: transmettre_student_concern invalid';
  END IF;

  v_definition := pg_catalog.pg_get_functiondef(
    'public.creer_offre_horaire(text,text,text,smallint[],smallint,smallint)'::pg_catalog.regprocedure
  );
  IF pg_catalog.strpos(v_definition, 'IS DISTINCT FROM v_attendu') = 0 THEN
    RAISE EXCEPTION 'F86 postflight: creer_offre_horaire invalid';
  END IF;

  FOREACH v_signature IN ARRAY ARRAY[
    'public.annonces_observation(uuid)',
    'public.transmettre_student_concern(uuid,text)',
    'public.creer_offre_horaire(text,text,text,smallint[],smallint,smallint)'
  ] LOOP
    v_oid := pg_catalog.to_regprocedure(v_signature);
    SELECT pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
      INTO v_owner, v_config
      FROM pg_catalog.pg_proc p WHERE p.oid = v_oid::oid;
    IF v_owner IS DISTINCT FROM 'postgres'
       OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'F86 postflight: owner/search_path/ACL invalid for %', v_signature;
    END IF;
  END LOOP;
END
$f86_postflight$;

COMMIT;
