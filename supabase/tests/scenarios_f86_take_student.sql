-- F86 : un compte valide sans claim role ne peut pas prendre un eleve.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8640000-0000-0000-0000-000000000001', 'f86-teacher-without-role@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f864ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8640000-0000-0000-0000-000000000001', 'F86GUARDIAN0001', 'guardian',
   'f864ffff-0000-0000-0000-000000000001', 'F86', 'Guardian', 'active');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8640000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8640000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{}}', true);

DO $f86_null_role_denied$
BEGIN
  BEGIN
    PERFORM public.prendre_eleve(NULL::uuid, NULL::integer, NULL::integer);
    RAISE EXCEPTION 'F86: un compte actif sans role JWT a pu prendre un eleve';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un enseignant au compte valide prend un eleve' THEN RAISE; END IF;
  END;
END
$f86_null_role_denied$;

RESET ROLE;
ROLLBACK;
