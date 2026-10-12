BEGIN;
SET LOCAL search_path = '';

DO $f86_patch$
DECLARE
  v_definition text;
  v_before text;
  v_after text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(
    'public.autoriser_ecoute_archive(uuid)'::pg_catalog.regprocedure
  );
  v_before := 'if not coalesce(public.app_account_valid(), false) then';
  v_after := 'if not coalesce(public.app_account_valid() and public.app_role() in (''admin'', ''controller'', ''teacher'', ''guardian'', ''student''), false) then';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected autoriser_ecoute_archive definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;
END
$f86_patch$;

ALTER FUNCTION public.autoriser_ecoute_archive(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.autoriser_ecoute_archive(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.autoriser_ecoute_archive(uuid)
  TO authenticated;

COMMENT ON FUNCTION public.autoriser_ecoute_archive(uuid) IS
  'F86 candidate allowlist: signature=public.autoriser_ecoute_archive(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: valid admin/controller, session teacher, guardian, or student accounts proceed to the existing exact relationship check; archive status and listening audit remain enforced.';

DO $f86_postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.autoriser_ecoute_archive(uuid)'::pg_catalog.regprocedure;
  v_definition text;
  v_owner text;
  v_config text[];
BEGIN
  SELECT pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
    INTO v_owner, v_config FROM pg_catalog.pg_proc p WHERE p.oid = v_oid::oid;
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  IF v_owner IS DISTINCT FROM 'postgres'
     OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
     OR pg_catalog.strpos(v_definition, 'if not coalesce(public.app_account_valid() and public.app_role() in (''admin'', ''controller'', ''teacher'', ''guardian'', ''student''), false) then') = 0
     OR pg_catalog.strpos(v_definition, 'session_belongs_to_teacher(v_archive.session_id, auth.uid())') = 0
     OR pg_catalog.strpos(v_definition, 'session_in_household(v_archive.session_id, public.app_household_id())') = 0
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR coalesce(pg_catalog.strpos(
       pg_catalog.obj_description(v_oid::oid, 'pg_proc'),
       'md5_functiondef=A_CALCULER;'
     ), 0) = 0 THEN
    RAISE EXCEPTION 'F86 postflight: archive-listen guard/ACL/owner/search_path/allowlist invalid';
  END IF;
END
$f86_postflight$;

COMMIT;
