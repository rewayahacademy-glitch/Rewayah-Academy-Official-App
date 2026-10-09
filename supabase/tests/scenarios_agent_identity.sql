-- Regression test SEC-01: the signed JWT subject identifies the delegated agent
-- token; PostgREST's effective subject is resolved from the live token row only
-- after agent_pre_request validates it.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a9000000-0000-0000-0000-000000000001', 'agent-id@example.test'),
  ('a9000000-0000-0000-0000-000000000002', 'observed-id@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('a9ffffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('a9000000-0000-0000-0000-000000000001', 'AGENT-ID-000001', 'admin',
   'a9ffffff-0000-0000-0000-000000000001', 'Agent', 'Fixture', 'active', 'male'),
  ('a9000000-0000-0000-0000-000000000002', 'OBS-ID-000001', 'student',
   'a9ffffff-0000-0000-0000-000000000001', 'Observed', 'Fixture', 'active', 'female');

INSERT INTO public.jetons_agent
  (id, libelle, prefixe, empreinte, profil_observe, parcours, expire_le, cree_par)
VALUES
  ('a9000000-0000-0000-0000-000000000010', 'SEC-01 fixture', 'rag_a9000000',
   'sec01-test-fingerprint', 'a9000000-0000-0000-0000-000000000002',
   'student', now() + interval '1 hour', 'a9000000-0000-0000-0000-000000000001');

DO $sec01$
DECLARE
  v_agent uuid := 'a9000000-0000-0000-0000-000000000010';
  v_observed uuid := 'a9000000-0000-0000-0000-000000000002';
BEGIN
  PERFORM set_config('test.uid', v_agent::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_agent::text, true);
  PERFORM set_config('test.jwt', jsonb_build_object(
    'sub', v_agent::text,
    'app_metadata', jsonb_build_object(
      'role', 'student',
      'household_id', 'a9ffffff-0000-0000-0000-000000000001',
      'agent_token_id', v_agent::text
    )
  )::text, true);

  IF auth.uid() IS DISTINCT FROM v_agent THEN
    RAISE EXCEPTION 'SEC-01: signed subject must identify the agent token before scope resolution';
  END IF;

  PERFORM public.agent_pre_request();

  IF auth.uid() IS DISTINCT FROM v_observed THEN
    RAISE EXCEPTION 'SEC-01: effective subject must resolve to the validated observed profile';
  END IF;
  IF auth.jwt() ->> 'sub' IS DISTINCT FROM v_agent::text
     OR auth.jwt() -> 'app_metadata' ->> 'agent_token_id' IS DISTINCT FROM v_agent::text THEN
    RAISE EXCEPTION 'SEC-01: original agent identity claims must remain intact';
  END IF;
END
$sec01$;

DELETE FROM public.jetons_agent WHERE id = 'a9000000-0000-0000-0000-000000000010';
DELETE FROM public.profiles WHERE id IN
  ('a9000000-0000-0000-0000-000000000001', 'a9000000-0000-0000-0000-000000000002');
DELETE FROM auth.users WHERE id IN
  ('a9000000-0000-0000-0000-000000000001', 'a9000000-0000-0000-0000-000000000002');
DELETE FROM public.households WHERE id = 'a9ffffff-0000-0000-0000-000000000001';

COMMIT;
