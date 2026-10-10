-- SEC-01: the JWT identifies the opaque agent token; only the validated
-- per-request hook may map auth.uid() to its currently observed profile.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('ea000000-0000-0000-0000-000000000001', 'sec01-agent@example.test'),
  ('ea000000-0000-0000-0000-000000000002', 'sec01-observed-valid@example.test'),
  ('ea000000-0000-0000-0000-000000000003', 'sec01-observed-revoked@example.test'),
  ('ea000000-0000-0000-0000-000000000004', 'sec01-observed-expired@example.test'),
  ('ea000000-0000-0000-0000-000000000005', 'sec01-observed-role@example.test'),
  ('ea000000-0000-0000-0000-000000000006', 'sec01-observed-disabled@example.test'),
  ('ea000000-0000-0000-0000-000000000007', 'sec01-observed-access-expired@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('eaffffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('ea000000-0000-0000-0000-000000000001', 'AGENT-ID-000001', 'admin',
   'eaffffff-0000-0000-0000-000000000001', 'Agent', 'SEC01', 'active', 'male'),
  ('ea000000-0000-0000-0000-000000000002', 'OBS-ID-000001', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'Valid', 'active', 'female'),
  ('ea000000-0000-0000-0000-000000000003', 'OBS-ID-000002', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'Revoked', 'active', 'female'),
  ('ea000000-0000-0000-0000-000000000004', 'OBS-ID-000003', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'Expired', 'active', 'female'),
  ('ea000000-0000-0000-0000-000000000005', 'OBS-ID-000004', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'Role', 'active', 'female'),
  ('ea000000-0000-0000-0000-000000000006', 'OBS-ID-000005', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'Disabled', 'disabled', 'female'),
  ('ea000000-0000-0000-0000-000000000007', 'OBS-ID-000006', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'AccessExpired', 'active', 'female');

UPDATE public.profiles
   SET access_until = pg_catalog.now() - interval '1 hour'
 WHERE id = 'ea000000-0000-0000-0000-000000000007';

INSERT INTO public.jetons_agent
  (id, libelle, prefixe, empreinte, profil_observe, parcours, expire_le, cree_le, cree_par, revoque_le)
VALUES
  ('ea000000-0000-0000-0000-000000000010', 'SEC-01 valid', 'rag_ea000010',
   'sec01-test-fingerprint-valid', 'ea000000-0000-0000-0000-000000000002',
   'student', pg_catalog.now() + interval '1 hour', pg_catalog.now(), 'ea000000-0000-0000-0000-000000000001', NULL),
  ('ea000000-0000-0000-0000-000000000011', 'SEC-01 revoked', 'rag_ea000011',
   'sec01-test-fingerprint-revoked', 'ea000000-0000-0000-0000-000000000003',
   'student', pg_catalog.now() + interval '1 hour', pg_catalog.now(), 'ea000000-0000-0000-0000-000000000001', NULL),
  ('ea000000-0000-0000-0000-000000000012', 'SEC-01 expired', 'rag_ea000012',
   'sec01-test-fingerprint-expired', 'ea000000-0000-0000-0000-000000000004',
   'student', pg_catalog.now() - interval '1 hour', pg_catalog.now() - interval '2 hours', 'ea000000-0000-0000-0000-000000000001', NULL),
  ('ea000000-0000-0000-0000-000000000013', 'SEC-01 role mismatch', 'rag_ea000013',
   'sec01-test-fingerprint-role', 'ea000000-0000-0000-0000-000000000005',
   'student', pg_catalog.now() + interval '1 hour', pg_catalog.now(), 'ea000000-0000-0000-0000-000000000001', NULL),
  ('ea000000-0000-0000-0000-000000000014', 'SEC-01 disabled profile', 'rag_ea000014',
   'sec01-test-fingerprint-disabled', 'ea000000-0000-0000-0000-000000000006',
   'student', pg_catalog.now() + interval '1 hour', pg_catalog.now(), 'ea000000-0000-0000-0000-000000000001', NULL),
  ('ea000000-0000-0000-0000-000000000015', 'SEC-01 account access expired', 'rag_ea000015',
   'sec01-test-fingerprint-access-expired', 'ea000000-0000-0000-0000-000000000007',
   'student', pg_catalog.now() + interval '1 hour', pg_catalog.now(), 'ea000000-0000-0000-0000-000000000001', NULL);

CREATE FUNCTION pg_temp.sec01_set_agent(p_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $test_helper$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.jsonb_build_object(
    'sub', p_id::text,
    'role', 'agent_ro',
    'app_metadata', pg_catalog.jsonb_build_object(
      'role', 'student',
      'household_id', 'eaffffff-0000-0000-0000-000000000001',
      'agent_token_id', p_id::text
    )
  )::text, true);
END;
$test_helper$;

DO $sec01$
DECLARE
  v_agent uuid := 'ea000000-0000-0000-0000-000000000010';
  v_observed uuid := 'ea000000-0000-0000-0000-000000000002';
  v_revoked uuid := 'ea000000-0000-0000-0000-000000000011';
  v_expired uuid := 'ea000000-0000-0000-0000-000000000012';
  v_role_mismatch uuid := 'ea000000-0000-0000-0000-000000000013';
  v_disabled uuid := 'ea000000-0000-0000-0000-000000000014';
  v_access_expired uuid := 'ea000000-0000-0000-0000-000000000015';
BEGIN
  PERFORM pg_temp.sec01_set_agent(v_agent);
  IF auth.uid() IS DISTINCT FROM v_agent THEN
    RAISE EXCEPTION 'SEC-01: initial auth.uid must be the opaque agent token';
  END IF;

  PERFORM public.agent_pre_request();

  IF auth.uid() IS DISTINCT FROM v_observed THEN
    RAISE EXCEPTION 'SEC-01: effective auth.uid must be the validated observed profile';
  END IF;
  IF auth.jwt() ->> 'sub' IS DISTINCT FROM v_agent::text
     OR auth.jwt() -> 'app_metadata' ->> 'agent_token_id' IS DISTINCT FROM v_agent::text THEN
    RAISE EXCEPTION 'SEC-01: signed JWT identity claims were changed';
  END IF;

  -- Revocation is allowed after issuance; other token scope stays immutable.
  UPDATE public.jetons_agent
     SET revoque_le = pg_catalog.now()
   WHERE id = v_revoked;
  PERFORM pg_temp.sec01_set_agent(v_revoked);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: revoked token must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_revoked::text THEN
      RAISE EXCEPTION 'SEC-01: revoked token changed the effective subject';
    END IF;
  END;

  -- Expiration is fixed at issuance and cannot be rewritten afterward.
  PERFORM pg_temp.sec01_set_agent(v_expired);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: expired token must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_expired::text THEN
      RAISE EXCEPTION 'SEC-01: expired token changed the effective subject';
    END IF;
  END;

  -- A current administrator can change a profile; an already issued agent
  -- token must then fail closed against its immutable student scope.
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    'ea000000-0000-0000-0000-000000000001',
    true
  );
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.jsonb_build_object(
    'sub', 'ea000000-0000-0000-0000-000000000001',
    'role', 'authenticated',
    'app_metadata', pg_catalog.jsonb_build_object(
      'role', 'admin',
      'household_id', 'eaffffff-0000-0000-0000-000000000001'
    )
  )::text, true);
  UPDATE public.profiles
     SET role = 'admin'
   WHERE id = 'ea000000-0000-0000-0000-000000000005';

  -- Active status alone is insufficient: disabled or time-expired observed
  -- profiles must not retain delegated access.
  PERFORM pg_temp.sec01_set_agent(v_disabled);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: disabled observed profile must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_disabled::text THEN
      RAISE EXCEPTION 'SEC-01: disabled profile changed the effective subject';
    END IF;
  END;

  PERFORM pg_temp.sec01_set_agent(v_access_expired);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: access-expired observed profile must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_access_expired::text THEN
      RAISE EXCEPTION 'SEC-01: access-expired profile changed the effective subject';
    END IF;
  END;

  PERFORM pg_temp.sec01_set_agent(v_role_mismatch);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: changed observed role must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_role_mismatch::text THEN
      RAISE EXCEPTION 'SEC-01: role-mismatched token changed the effective subject';
    END IF;
  END;
END
$sec01$;

ROLLBACK;
