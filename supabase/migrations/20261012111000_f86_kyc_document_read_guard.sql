BEGIN;
SET LOCAL search_path = '';

DO $f86_patch$
DECLARE
  v_definition text;
  v_before text;
  v_after text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(
    'public.autoriser_lecture_piece_identite(uuid)'::pg_catalog.regprocedure
  );
  v_before := 'IF NOT coalesce(public.app_role() = ''admin'', false)' || E'\n'
    || '     OR NOT coalesce(public.app_account_valid(), false) THEN' || E'\n'
    || '    RAISE EXCEPTION ''lecture des pieces d''''identite reservee a l''''administration''' || E'\n'
    || '      USING errcode = ''42501'';' || E'\n'
    || '  END IF;';
  v_after := 'IF NOT coalesce(public.app_account_valid() AND public.app_role() = ''admin'', false) THEN' || E'\n'
    || '    RAISE EXCEPTION ''lecture des pieces d''''identite reservee a l''''administration''' || E'\n'
    || '      USING errcode = ''42501'';' || E'\n'
    || '  END IF;';
  IF pg_catalog.strpos(v_definition, v_after) = 0 THEN
    IF pg_catalog.strpos(v_definition, v_before) = 0 THEN
      RAISE EXCEPTION 'F86 preflight: unexpected autoriser_lecture_piece_identite definition';
    END IF;
    EXECUTE pg_catalog.replace(v_definition, v_before, v_after);
  END IF;
END
$f86_patch$;

REVOKE ALL ON FUNCTION public.autoriser_lecture_piece_identite(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.autoriser_lecture_piece_identite(uuid)
  TO authenticated;

COMMENT ON FUNCTION public.autoriser_lecture_piece_identite(uuid) IS
  'F86 candidate allowlist: signature=public.autoriser_lecture_piece_identite(uuid); md5_functiondef=f9a8e46dc4227c5dc707303d56774fd6; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: only a valid active admin may authorize an identity-document read; non-admin, inactive admin, and missing-profile JWT are denied; the read remains scoped and audited.';

DO $f86_postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.autoriser_lecture_piece_identite(uuid)'::pg_catalog.regprocedure;
  v_definition text;
  v_owner text;
  v_config text[];
BEGIN
  SELECT pg_catalog.pg_get_userbyid(p.proowner), p.proconfig
    INTO v_owner, v_config
    FROM pg_catalog.pg_proc p WHERE p.oid = v_oid::oid;
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  IF pg_catalog.md5(v_definition) IS DISTINCT FROM 'f9a8e46dc4227c5dc707303d56774fd6' THEN
    RAISE EXCEPTION 'F86 postflight: unexpected autoriser_lecture_piece_identite hash';
  END IF;
  IF v_owner IS DISTINCT FROM 'postgres'
     OR NOT coalesce(v_config @> ARRAY['search_path=""'], false)
     OR pg_catalog.strpos(v_definition, 'IF NOT coalesce(public.app_account_valid() AND public.app_role() = ''admin'', false) THEN') = 0
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR coalesce(pg_catalog.strpos(
       pg_catalog.obj_description(v_oid::oid, 'pg_proc'),
       'md5_functiondef=f9a8e46dc4227c5dc707303d56774fd6;'
     ), 0) = 0 THEN
    RAISE EXCEPTION 'F86 postflight: KYC read guard/ACL/owner/search_path/allowlist invalid';
  END IF;
END
$f86_postflight$;

COMMIT;
