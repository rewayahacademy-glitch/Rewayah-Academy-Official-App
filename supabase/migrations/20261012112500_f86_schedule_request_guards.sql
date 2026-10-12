BEGIN;
SET LOCAL search_path = '';

DO $f86_patch$
DECLARE
  v_signature text;
  v_definition text;
  v_before text;
  v_after text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)',
    'public.choisir_offre_horaire(uuid,uuid,text)'
  ] LOOP
    v_definition := pg_catalog.pg_get_functiondef(v_signature::pg_catalog.regprocedure);
    v_before := 'IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN' || E'\n'
      || '    RAISE EXCEPTION ''ce profil n''est pas le votre ni celui de votre foyer'';' || E'\n'
      || '  END IF;';
    v_after := 'IF NOT coalesce(public.app_account_valid() AND public.app_role() IN (''guardian'', ''student''), false) THEN' || E'\n'
      || '    RAISE EXCEPTION ''ce profil n''est pas le votre ni celui de votre foyer'';' || E'\n'
      || '  END IF;' || E'\n'
      || '  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN' || E'\n'
      || '    RAISE EXCEPTION ''ce profil n''est pas le votre ni celui de votre foyer'';' || E'\n'
      || '  END IF;';
    IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
      IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
        RAISE EXCEPTION 'F86 preflight: unexpected schedule request definition for %', v_signature;
      END IF;
      EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
    END IF;
  END LOOP;
END
$f86_patch$;

ALTER FUNCTION public.demander_creneau_personnalise(uuid,text,smallint[],smallint) OWNER TO postgres;
ALTER FUNCTION public.choisir_offre_horaire(uuid,uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.demander_creneau_personnalise(uuid,text,smallint[],smallint)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_creneau_personnalise(uuid,text,smallint[],smallint)
  TO authenticated;
REVOKE ALL ON FUNCTION public.choisir_offre_horaire(uuid,uuid,text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.choisir_offre_horaire(uuid,uuid,text)
  TO authenticated;

COMMENT ON FUNCTION public.demander_creneau_personnalise(uuid,text,smallint[],smallint) IS
  'F86 candidate allowlist: signature=public.demander_creneau_personnalise(uuid,text,smallint[],smallint); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: valid guardians may request for their household students and autonomous students for themselves; helper still enforces the exact profile scope.';
COMMENT ON FUNCTION public.choisir_offre_horaire(uuid,uuid,text) IS
  'F86 candidate allowlist: signature=public.choisir_offre_horaire(uuid,uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: valid guardians may choose for household students and autonomous students for themselves; helper still enforces the exact profile scope.';

DO $f86_postflight$
DECLARE
  v_signature text;
  v_definition text;
  v_oid pg_catalog.regprocedure;
  v_owner text;
  v_config text[];
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)',
    'public.choisir_offre_horaire(uuid,uuid,text)'
  ] LOOP
    v_oid := v_signature::pg_catalog.regprocedure;
    v_definition := pg_catalog.pg_get_functiondef(v_oid);
    SELECT pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
      INTO v_owner, v_config FROM pg_catalog.pg_proc p WHERE p.oid = v_oid::oid;
    IF v_owner IS DISTINCT FROM 'postgres'
       OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
       OR pg_catalog.strpos(v_definition, 'app_account_valid() AND public.app_role() IN (''guardian'', ''student'')') = 0
       OR pg_catalog.strpos(v_definition, 'peut_decrire_apprenant(p_membre_id)') = 0
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR coalesce(pg_catalog.strpos(
         pg_catalog.obj_description(v_oid::oid, 'pg_proc'),
         'md5_functiondef=A_CALCULER;'
       ), 0) = 0 THEN
      RAISE EXCEPTION 'F86 postflight: schedule guard/ACL/owner/search_path/allowlist invalid for %', v_signature;
    END IF;
  END LOOP;
END
$f86_postflight$;

COMMIT;
