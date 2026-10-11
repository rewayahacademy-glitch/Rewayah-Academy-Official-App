BEGIN;

INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  ('d15ab1ed-0000-0000-0000-000000000001', 'disabled-guardian@test.invalid', now()),
  ('d15ab1ed-0000-0000-0000-000000000002', 'active-guardian@test.invalid', now()),
  ('d15ab1ed-0000-0000-0000-000000000003', 'disabled-child@test.invalid', now()),
  ('d15ab1ed-0000-0000-0000-000000000004', 'active-child@test.invalid', now()),
  ('d15ab1ed-0000-0000-0000-000000000005', 'active-admin@test.invalid', now());

INSERT INTO public.households (id, timezone, status) VALUES
  ('d15ab1ed-0000-0000-0000-000000000101', 'Europe/Paris', 'active'),
  ('d15ab1ed-0000-0000-0000-000000000102', 'Europe/Paris', 'active'),
  ('d15ab1ed-0000-0000-0000-000000000103', 'Europe/Paris', 'active');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('d15ab1ed-0000-0000-0000-000000000001', 'DISABLED-GUARDIAN', 'guardian',
   'd15ab1ed-0000-0000-0000-000000000101', 'Parent', 'Disabled', 'disabled', 'female'),
  ('d15ab1ed-0000-0000-0000-000000000002', 'ACTIVE-GUARDIAN', 'guardian',
   'd15ab1ed-0000-0000-0000-000000000102', 'Parent', 'Active', 'active', 'female'),
  ('d15ab1ed-0000-0000-0000-000000000003', 'DISABLED-CHILD', 'student',
   'd15ab1ed-0000-0000-0000-000000000101', 'Child', 'Disabled', 'active', 'male'),
  ('d15ab1ed-0000-0000-0000-000000000004', 'ACTIVE-CHILD', 'student',
   'd15ab1ed-0000-0000-0000-000000000102', 'Child', 'Active', 'active', 'male'),
  ('d15ab1ed-0000-0000-0000-000000000005', 'ACTIVE-ADMIN', 'admin',
   'd15ab1ed-0000-0000-0000-000000000103', 'Admin', 'Active', 'active', 'male');

UPDATE public.households
SET primary_guardian_id = CASE id
  WHEN 'd15ab1ed-0000-0000-0000-000000000101' THEN 'd15ab1ed-0000-0000-0000-000000000001'::uuid
  WHEN 'd15ab1ed-0000-0000-0000-000000000102' THEN 'd15ab1ed-0000-0000-0000-000000000002'::uuid
  WHEN 'd15ab1ed-0000-0000-0000-000000000103' THEN 'd15ab1ed-0000-0000-0000-000000000005'::uuid
END
WHERE id IN (
  'd15ab1ed-0000-0000-0000-000000000101',
  'd15ab1ed-0000-0000-0000-000000000102',
  'd15ab1ed-0000-0000-0000-000000000103'
);

INSERT INTO public.student_profiles (profile_id) VALUES
  ('d15ab1ed-0000-0000-0000-000000000003'),
  ('d15ab1ed-0000-0000-0000-000000000004');
INSERT INTO public.devices (profile_id, device_fingerprint, platform) VALUES
  ('d15ab1ed-0000-0000-0000-000000000001', 'disabled-fixture-device', 'web');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'd15ab1ed-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"aal":"aal1","app_metadata":{"role":"guardian","household_id":"d15ab1ed-0000-0000-0000-000000000101"}}',
  true);

DO $disabled_account$
DECLARE
  v_table text;
  v_rows bigint;
  v_kyc_denied boolean := false;
BEGIN
  IF public.app_account_valid() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'disabled-account fixture unexpectedly valid';
  END IF;

  FOREACH v_table IN ARRAY ARRAY[
    'contract_texts', 'devices', 'groupe_creneaux', 'groupe_membres',
    'groupes', 'households', 'intentions_horaire', 'library_resource_groupe',
    'matching_requests', 'prayer_settings', 'profiles', 'rule_overrides',
    'student_profiles', 'student_reading_position',
    'teacher_student_assignments', 'weekly_availability'
  ] LOOP
    EXECUTE pg_catalog.format('SELECT count(*) FROM public.%I', v_table)
      INTO v_rows;
    IF v_rows <> 0 THEN
      RAISE EXCEPTION 'disabled account read % row(s) from public.%', v_rows, v_table;
    END IF;
  END LOOP;

  BEGIN
    INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
    VALUES ('d15ab1ed-0000-0000-0000-000000000003', 'passport',
            'private/kyc/disabled-account-fixture');
  EXCEPTION WHEN insufficient_privilege THEN
    v_kyc_denied := true;
  END;
  IF NOT v_kyc_denied THEN
    RAISE EXCEPTION 'disabled guardian inserted a KYC document';
  END IF;
END;
$disabled_account$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'd15ab1ed-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims',
  '{"aal":"aal1","app_metadata":{"role":"guardian","household_id":"d15ab1ed-0000-0000-0000-000000000102"}}',
  true);

DO $active_account$
DECLARE
  v_rows bigint;
  v_document uuid;
BEGIN
  IF public.app_account_valid() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active-account fixture unexpectedly invalid';
  END IF;
  SELECT count(*) INTO v_rows FROM public.profiles
  WHERE id = 'd15ab1ed-0000-0000-0000-000000000002';
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'valid guardian lost self-profile access';
  END IF;
  INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES ('d15ab1ed-0000-0000-0000-000000000004', 'passport',
          'private/kyc/active-account-fixture')
  RETURNING id INTO v_document;
  IF v_document IS NULL THEN
    RAISE EXCEPTION 'valid guardian could not insert the same KYC request';
  END IF;
END;
$active_account$;
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'd15ab1ed-0000-0000-0000-000000000005', true);
SELECT set_config('request.jwt.claims',
  '{"aal":"aal2","app_metadata":{"role":"admin","household_id":"d15ab1ed-0000-0000-0000-000000000103"}}',
  true);
DO $active_admin$
DECLARE v_rows bigint;
BEGIN
  IF public.app_account_valid() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active-admin fixture unexpectedly invalid';
  END IF;
  SELECT count(*) INTO v_rows FROM public.profiles
  WHERE id = 'd15ab1ed-0000-0000-0000-000000000005';
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'valid admin lost profile access';
  END IF;
END;
$active_admin$;
RESET ROLE;

ROLLBACK;
