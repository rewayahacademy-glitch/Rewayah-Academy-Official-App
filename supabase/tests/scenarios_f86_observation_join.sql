-- F86 : un role NULL ne doit pas laisser entrer un compte authentifie actif en observation.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8630000-0000-0000-0000-000000000001', 'f86-observer-without-role@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f863ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8630000-0000-0000-0000-000000000001', 'F86OBSUSER0001', 'guardian',
   'f863ffff-0000-0000-0000-000000000001', 'F86', 'Observer', 'active');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8630000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8630000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{}}', true);

DO $f86_null_role_denied$
BEGIN
  BEGIN
    PERFORM public.rejoindre_observation(NULL::uuid);
    RAISE EXCEPTION 'F86: un compte actif sans role JWT a rejoint une observation';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'observation reservee au controle qualite' THEN RAISE; END IF;
  END;
END
$f86_null_role_denied$;

RESET ROLE;
ROLLBACK;
