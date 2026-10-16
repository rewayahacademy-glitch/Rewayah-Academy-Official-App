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
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8640000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8640000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"f8640000-0000-0000-0000-000000000001","app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
DO $f86_guardian_role_denied$
BEGIN
  BEGIN
    PERFORM public.prendre_eleve(NULL::uuid, NULL::integer, NULL::integer);
    RAISE EXCEPTION 'F86: un tuteur actif a pu prendre un eleve';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un enseignant au compte valide prend un eleve' THEN RAISE; END IF;
  END;
END
$f86_guardian_role_denied$;

RESET ROLE;
UPDATE public.profiles SET account_status = 'disabled'
 WHERE id = 'f8640000-0000-0000-0000-000000000001';
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8640000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8640000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"f8640000-0000-0000-0000-000000000001","app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
DO $f86_disabled_teacher_denied$
BEGIN
  BEGIN
    PERFORM public.prendre_eleve(NULL::uuid, NULL::integer, NULL::integer);
    RAISE EXCEPTION 'F86: un compte enseignant desactive a pu prendre un eleve';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un enseignant au compte valide prend un eleve' THEN RAISE; END IF;
  END;
END
$f86_disabled_teacher_denied$;

RESET ROLE;
DO $f86_anon_acl$
BEGIN
  IF pg_catalog.has_function_privilege(
       'anon', 'public.prendre_eleve(uuid,integer,integer)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'F86: anon conserve EXECUTE sur prendre_eleve';
  END IF;
END
$f86_anon_acl$;
SET LOCAL ROLE anon;
DO $f86_anon_denied$
BEGIN
  BEGIN
    PERFORM public.prendre_eleve(NULL::uuid, NULL::integer, NULL::integer);
    RAISE EXCEPTION 'F86: anon a pu prendre un eleve';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$f86_anon_denied$;

RESET ROLE;
ROLLBACK;
