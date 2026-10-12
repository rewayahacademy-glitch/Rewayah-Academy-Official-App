-- RECH-BACK-1: fresh authorization claims and disabled-account denial.
-- Synthetic identities only; run once after all migrations on a fresh database.

INSERT INTO auth.users (id, email) VALUES
  ('ab100000-0000-0000-0000-000000000001', 'rech-back-1-a@example.test'),
  ('ab100000-0000-0000-0000-000000000002', 'rech-back-1-admin@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('ab1fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('ab1fffff-0000-0000-0000-000000000002', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('ab100000-0000-0000-0000-000000000001', 'GUAR-RB1-00001', 'guardian',
   'ab1fffff-0000-0000-0000-000000000001', 'Awa', 'Test', 'active'),
  ('ab100000-0000-0000-0000-000000000002', 'ADMN-RB1-00001', 'admin',
   NULL, 'Admin', 'Test', 'active');

DO $scenario$
DECLARE
  v_token jsonb;
  v_claims jsonb;
  v_legacy_claims jsonb;
  v_admin_claims jsonb;
  v_version bigint;
BEGIN
  v_token := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'ab100000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'ab100000-0000-0000-0000-000000000001')
  ));
  v_claims := v_token -> 'claims';
  v_version := (v_claims -> 'app_metadata' ->> 'authorization_version')::bigint;

  IF v_version <> 1 OR v_claims -> 'app_metadata' ->> 'role' <> 'guardian' THEN
    RAISE EXCEPTION 'RB1-HOOK: expected guardian authorization version 1';
  END IF;

  v_legacy_claims := v_claims #- '{app_metadata,authorization_version}';
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ab100000-0000-0000-0000-000000000001',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims::text, true);
  SET LOCAL ROLE authenticated;
  IF v_claims -> 'app_metadata' ->> 'household_id'
       IS DISTINCT FROM 'ab1fffff-0000-0000-0000-000000000001'
     OR NOT public.rech_session_autorisee()
     OR NOT public.app_account_valid() THEN
    RAISE EXCEPTION 'RB1-CURRENT: active synthetic guardian claims should be accepted';
  END IF;
  RESET ROLE;

  PERFORM pg_catalog.set_config('request.jwt.claims', v_legacy_claims::text, true);
  SET LOCAL ROLE authenticated;
  IF public.rech_session_autorisee() THEN
    RAISE EXCEPTION 'RB1-LEGACY: a token without an authorization version remained valid';
  END IF;
  RESET ROLE;
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims::text, true);

  -- Moving the profile and changing its role immediately invalidates the old JWT.
  v_admin_claims := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'ab100000-0000-0000-0000-000000000002',
    'claims', jsonb_build_object('sub', 'ab100000-0000-0000-0000-000000000002')
  )) -> 'claims';
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ab100000-0000-0000-0000-000000000002',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', v_admin_claims::text, true);
  IF v_admin_claims -> 'app_metadata' ->> 'role' <> 'admin'
     OR NOT public.rech_session_autorisee()
     OR NOT public.app_account_valid() THEN
    RAISE EXCEPTION 'RB1-FIXTURE: admin synthetic identity was not issued current claims';
  END IF;
  UPDATE public.profiles
     SET role = 'student', household_id = 'ab1fffff-0000-0000-0000-000000000002'
   WHERE id = 'ab100000-0000-0000-0000-000000000001';
  UPDATE public.profiles SET authorization_version = 1
   WHERE id = 'ab100000-0000-0000-0000-000000000001';

  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ab100000-0000-0000-0000-000000000001',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims::text, true);
  SET LOCAL ROLE authenticated;
  IF public.rech_session_autorisee() THEN
    RAISE EXCEPTION 'RB1-STALE: old role or household claim survived an authorization change';
  END IF;
  RESET ROLE;

  v_claims := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'ab100000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'ab100000-0000-0000-0000-000000000001')
  )) -> 'claims';

  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ab100000-0000-0000-0000-000000000001',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims::text, true);
  SET LOCAL ROLE authenticated;
  IF v_claims -> 'app_metadata' ->> 'authorization_version' <> '2'
     OR v_claims -> 'app_metadata' ->> 'role' <> 'student'
     OR v_claims -> 'app_metadata' ->> 'household_id'
       IS DISTINCT FROM 'ab1fffff-0000-0000-0000-000000000002'
     OR NOT public.rech_session_autorisee() THEN
    RAISE EXCEPTION 'RB1-REFRESHED: fresh role and household claims should be accepted';
  END IF;
  RESET ROLE;

  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ab100000-0000-0000-0000-000000000002',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', v_admin_claims::text, true);
  UPDATE public.profiles
     SET account_status = 'disabled'
   WHERE id = 'ab100000-0000-0000-0000-000000000001';
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ab100000-0000-0000-0000-000000000001',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims::text, true);
  SET LOCAL ROLE authenticated;
  IF public.rech_session_autorisee() OR public.app_account_valid() THEN
    RAISE EXCEPTION 'RB1-DISABLED: disabled account retained authorization';
  END IF;
  RESET ROLE;

  v_claims := public.custom_access_token_hook(jsonb_build_object(
    'user_id', 'ab100000-0000-0000-0000-000000000001',
    'claims', jsonb_build_object('sub', 'ab100000-0000-0000-0000-000000000001')
  )) -> 'claims';
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims::text, true);
  SET LOCAL ROLE authenticated;
  IF v_claims -> 'app_metadata' ->> 'authorization_version' <> '3'
     OR public.rech_session_autorisee()
     OR public.app_account_valid() THEN
    RAISE EXCEPTION 'RB1-DISABLED-REFRESH: refreshed token restored disabled-account authorization';
  END IF;
  RESET ROLE;
END;
$scenario$;

DO $catalog$
DECLARE
  v_proc regprocedure;
BEGIN
  FOREACH v_proc IN ARRAY ARRAY[
    'public.rech_session_autorisee()'::regprocedure,
    'public.custom_access_token_hook(jsonb)'::regprocedure,
    'private.bump_profile_authorization_version()'::regprocedure
  ] LOOP
    IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
              FROM pg_catalog.pg_proc AS p WHERE p.oid = v_proc) THEN
      RAISE EXCEPTION 'RB1-DEFINER: % must remain SECURITY DEFINER with empty search_path', v_proc;
    END IF;
  END LOOP;
  IF NOT has_function_privilege('authenticated', 'public.rech_session_autorisee()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.rech_session_autorisee()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.rech_session_autorisee()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.bump_profile_authorization_version()', 'EXECUTE')
     OR has_function_privilege('anon', 'private.bump_profile_authorization_version()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.custom_access_token_hook(jsonb)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.custom_access_token_hook(jsonb)', 'EXECUTE') THEN
    RAISE EXCEPTION 'RB1-GRANTS: helper/hook EXECUTE grants are not least-privilege';
  END IF;
  IF NOT has_function_privilege(
       'supabase_auth_admin', 'public.custom_access_token_hook(jsonb)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'RB1-HOOK-GRANT: Supabase Auth hook grant was lost';
  END IF;
END;
$catalog$;
