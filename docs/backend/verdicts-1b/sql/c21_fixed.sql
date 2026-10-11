BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c2100000-0000-0000-0000-000000000001', 'c21-admin-m@example.test'),
  ('c2100000-0000-0000-0000-000000000002', 'c21-admin-f@example.test'),
  ('c2100000-0000-0000-0000-000000000003', 'c21-target-m@example.test'),
  ('c2100000-0000-0000-0000-000000000004', 'c21-target-f@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('c2100000-0000-0000-0000-000000000101', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender,
   account_status)
VALUES
  ('c2100000-0000-0000-0000-000000000001', 'C21-ADMIN-M', 'admin',
   'c2100000-0000-0000-0000-000000000101', 'Admin', 'M', 'male', 'active'),
  ('c2100000-0000-0000-0000-000000000002', 'C21-ADMIN-F', 'admin',
   'c2100000-0000-0000-0000-000000000101', 'Admin', 'F', 'female', 'active'),
  ('c2100000-0000-0000-0000-000000000003', 'C21-TARGET-M', 'teacher',
   'c2100000-0000-0000-0000-000000000101', 'Target', 'M', 'male', 'provisional_active'),
  ('c2100000-0000-0000-0000-000000000004', 'C21-TARGET-F', 'teacher',
   'c2100000-0000-0000-0000-000000000101', 'Target', 'F', 'female', 'provisional_active');

INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key)
VALUES
  ('c2100000-0000-0000-0000-000000000201',
   'c2100000-0000-0000-0000-000000000003', 'passport', 'male', 'c21/m'),
  ('c2100000-0000-0000-0000-000000000202',
   'c2100000-0000-0000-0000-000000000004', 'passport', 'female', 'c21/f');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'c2100000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $c21$
BEGIN
  IF public.verdict_acces_dossier_kyc(
       'c2100000-0000-0000-0000-000000000003'
     ) <> '{"type":"memeGenre"}'::jsonb THEN
    RAISE EXCEPTION 'C-21: same-gender dossier verdict was not allowed';
  END IF;
  IF public.verdict_acces_dossier_kyc(
       'c2100000-0000-0000-0000-000000000004'
     ) <> '{"type":"refus","raison":"genreDifferent"}'::jsonb THEN
    RAISE EXCEPTION 'C-21: cross-gender dossier was not denied';
  END IF;
  IF public.verdict_acces_dossier_kyc(
       'c2100000-0000-0000-0000-000000000099'
     ) <> '{"type":"refus","raison":"profilNonAutorise"}'::jsonb THEN
    RAISE EXCEPTION 'C-21: missing dossier leaked information';
  END IF;
  IF has_function_privilege(
       'service_role', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C-21: service_role can execute the client verdict RPC';
  END IF;
END
$c21$;

ROLLBACK;
