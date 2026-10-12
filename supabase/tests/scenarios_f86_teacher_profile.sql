-- F86 : une RPC d'ecriture enseignant exige role JWT teacher et compte valide.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8650000-0000-0000-0000-000000000001', 'f86-teacher-no-role@example.test'),
  ('f8650000-0000-0000-0000-000000000002', 'f86-teacher-disabled@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f865ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8650000-0000-0000-0000-000000000001', 'F86TEACHERNO001', 'teacher',
   'f865ffff-0000-0000-0000-000000000001', 'F86', 'NoRole', 'active'),
  ('f8650000-0000-0000-0000-000000000002', 'F86TEACHERDIS002', 'teacher',
   'f865ffff-0000-0000-0000-000000000001', 'F86', 'Disabled', 'disabled');

INSERT INTO public.teacher_profiles (profile_id) VALUES
  ('f8650000-0000-0000-0000-000000000001'),
  ('f8650000-0000-0000-0000-000000000002');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8650000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8650000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{}}', true);

DO $f86_missing_teacher_role$
BEGIN
  BEGIN
    PERFORM public.maj_profil_enseignant();
    RAISE EXCEPTION 'F86: un enseignant actif sans claim role a modifie son profil';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'profil enseignant indisponible' THEN RAISE; END IF;
  END;
END
$f86_missing_teacher_role$;

SELECT set_config('test.uid', 'f8650000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claim.sub', 'f8650000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);

DO $f86_disabled_teacher$
BEGIN
  BEGIN
    PERFORM public.maj_profil_enseignant();
    RAISE EXCEPTION 'F86: un enseignant desactive a modifie son profil';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'profil enseignant indisponible' THEN RAISE; END IF;
  END;
END
$f86_disabled_teacher$;

RESET ROLE;
ROLLBACK;
