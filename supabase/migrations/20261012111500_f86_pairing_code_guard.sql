BEGIN;
SET LOCAL search_path = '';

DO $f86_patch$
DECLARE
  v_definition text;
  v_before text;
  v_after text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(
    'public.creer_code_appairage(uuid)'::pg_catalog.regprocedure
  );
  v_before := 'if NOT coalesce(public.app_role() = ''guardian'' AND public.app_account_valid(), false) or not public.app_account_valid() then' || E'\n'
    || '    raise exception ''seul un tuteur au compte valide appaire un appareil'';' || E'\n'
    || '  end if;';
  v_after := 'if not coalesce(public.app_account_valid() and public.app_role() = ''guardian'', false) then' || E'\n'
    || '    raise exception ''seul un tuteur au compte valide appaire un appareil'';' || E'\n'
    || '  end if;';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected creer_code_appairage definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;
END
$f86_patch$;

ALTER FUNCTION public.creer_code_appairage(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_code_appairage(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_code_appairage(uuid)
  TO authenticated;

COMMENT ON FUNCTION public.creer_code_appairage(uuid) IS
  'F86 candidate allowlist: signature=public.creer_code_appairage(uuid); md5_functiondef=c9511be43d7cf5a0e3547fc9c3e49925; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: valid guardians may issue device pairing codes only for students in their household; non-guardians and invalid accounts are denied.';

DO $f86_postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.creer_code_appairage(uuid)'::pg_catalog.regprocedure;
  v_definition text;
  v_owner text;
  v_config text[];
BEGIN
  SELECT pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
    INTO v_owner, v_config
    FROM pg_catalog.pg_proc p WHERE p.oid = v_oid::oid;
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  IF pg_catalog.md5(v_definition) IS DISTINCT FROM 'c9511be43d7cf5a0e3547fc9c3e49925' THEN
    RAISE EXCEPTION 'F86 postflight: unexpected creer_code_appairage hash';
  END IF;
  IF v_owner IS DISTINCT FROM 'postgres'
     OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
     OR pg_catalog.strpos(v_definition, 'if not coalesce(public.app_account_valid() and public.app_role() = ''guardian'', false) then') = 0
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR coalesce(pg_catalog.strpos(
       pg_catalog.obj_description(v_oid::oid, 'pg_proc'),
       'md5_functiondef=c9511be43d7cf5a0e3547fc9c3e49925;'
     ), 0) = 0 THEN
    RAISE EXCEPTION 'F86 postflight: pairing-code guard/ACL/owner/search_path/allowlist invalid';
  END IF;
END
$f86_postflight$;

COMMIT;
