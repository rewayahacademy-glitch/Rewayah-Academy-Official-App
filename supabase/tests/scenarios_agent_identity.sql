-- SEC-01: the JWT identifies the opaque agent token; only the validated
-- per-request hook may map auth.uid() to its currently observed profile.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('ea000000-0000-0000-0000-000000000001', 'sec01-agent@example.test'),
  ('ea000000-0000-0000-0000-000000000002', 'sec01-observed@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('eaffffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('ea000000-0000-0000-0000-000000000001', 'SEC01-AGENT-000001', 'admin',
   'eaffffff-0000-0000-0000-000000000001', 'Agent', 'SEC01', 'active', 'male'),
  ('ea000000-0000-0000-0000-000000000002', 'SEC01-OBS-000001', 'student',
   'eaffffff-0000-0000-0000-000000000001', 'Observed', 'SEC01', 'active', 'female');

INSERT INTO public.jetons_agent
  (id, libelle, prefixe, empreinte, profil_observe, parcours, expire_le, cree_par)
VALUES
  ('ea000000-0000-0000-0000-000000000010', 'SEC-01 fixture', 'rag_ea000000',
   'sec01-test-fingerprint', 'ea000000-0000-0000-0000-000000000002',
   'student', pg_catalog.now() + interval '1 hour',
   'ea000000-0000-0000-0000-000000000001');

DO $sec01$
DECLARE
  v_agent uuid := 'ea000000-0000-0000-0000-000000000010';
  v_observed uuid := 'ea000000-0000-0000-0000-000000000002';
BEGIN
  PERFORM pg_catalog.set_config('test.uid', v_agent::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_agent::text, true);
  PERFORM pg_catalog.set_config('test.jwt', pg_catalog.jsonb_build_object(
    'sub', v_agent::text,
    'role', 'agent_ro',
    'app_metadata', pg_catalog.jsonb_build_object(
      'role', 'student',
      'household_id', 'eaffffff-0000-0000-0000-000000000001',
      'agent_token_id', v_agent::text
    )
  )::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', '', true);

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

  UPDATE public.jetons_agent SET revoque_le = pg_catalog.now() WHERE id = v_agent;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_agent::text, true);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: revoked token must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_agent::text THEN
      RAISE EXCEPTION 'SEC-01: revoked token changed the effective subject';
    END IF;
  END;

  UPDATE public.jetons_agent
     SET revoque_le = NULL, expire_le = pg_catalog.now() - interval '1 second'
   WHERE id = v_agent;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_agent::text, true);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: expired token must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_agent::text THEN
      RAISE EXCEPTION 'SEC-01: expired token changed the effective subject';
    END IF;
  END;

  UPDATE public.jetons_agent
     SET expire_le = pg_catalog.now() + interval '1 hour'
   WHERE id = v_agent;
  UPDATE public.profiles SET role = 'admin' WHERE id = v_observed;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_agent::text, true);
  BEGIN
    PERFORM public.agent_pre_request();
    RAISE EXCEPTION 'SEC-01: changed observed role must be rejected';
  EXCEPTION WHEN insufficient_privilege THEN
    IF current_setting('request.jwt.claim.sub', true) IS DISTINCT FROM v_agent::text THEN
      RAISE EXCEPTION 'SEC-01: role-mismatched token changed the effective subject';
    END IF;
  END;
END
$sec01$;

ROLLBACK;
