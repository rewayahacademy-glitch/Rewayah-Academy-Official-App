BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c2100000-0000-0000-0000-000000000001', 'c21-admin-m@example.test'),
  ('c2100000-0000-0000-0000-000000000002', 'c21-admin-f@example.test'),
  ('c2100000-0000-0000-0000-000000000003', 'c21-target-m@example.test'),
  ('c2100000-0000-0000-0000-000000000004', 'c21-target-f@example.test'),
  ('c2100000-0000-0000-0000-000000000005', 'c21-controller@example.test');

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
   'c2100000-0000-0000-0000-000000000101', 'Target', 'F', 'female', 'provisional_active'),
  ('c2100000-0000-0000-0000-000000000005', 'C21-CONTROLLER', 'controller',
   NULL, 'Controller', 'Test', 'active', 'male');

-- Fixture contractuelle requise par 0089 : le scénario signe la version NDA courante.
DO $fixture_teacher_nda$
DECLARE
  v_teacher record;
  v_teacher_version text;
  v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version
    FROM public.contract_texts
   WHERE contract_kind = 'teacher_nda'
     AND locale = 'fr'
     AND is_current;

  SELECT version INTO v_notice_version
    FROM public.contract_required_versions
   WHERE contract_kind = 'recording_and_control_notice';

  FOR v_teacher IN
    SELECT id FROM public.profiles
     WHERE id IN (
       'c2100000-0000-0000-0000-000000000003',
       'c2100000-0000-0000-0000-000000000004'
     )
  LOOP
    PERFORM set_config('request.jwt.claim.sub', v_teacher.id::text, true);
    PERFORM set_config('test.uid', v_teacher.id::text, true);
    PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
    PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    PERFORM public.signer_contrat(v_teacher_version, 'Fixture enseignant');
    INSERT INTO public.contract_acceptances(profile_id, contract_kind, version)
    VALUES (v_teacher.id, 'recording_and_control_notice', v_notice_version)
    ON CONFLICT (profile_id, contract_kind, version) DO NOTHING;
    UPDATE public.profiles SET account_status = 'active' WHERE id = v_teacher.id;
  END LOOP;

  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('test.uid', '', true);
  PERFORM set_config('test.jwt', '', true);
END
$fixture_teacher_nda$;

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

-- A controller has no access to this admin-only verdict RPC.
SELECT set_config('request.jwt.claim.sub', 'c2100000-0000-0000-0000-000000000005', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"controller"}}', true);
SELECT set_config('test.uid', 'c2100000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);
DO $controller_denied$
BEGIN
  BEGIN
    PERFORM public.verdict_acces_dossier_kyc(
      'c2100000-0000-0000-0000-000000000003'
    );
    RAISE EXCEPTION 'C-21: controller obtained a KYC access verdict';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$controller_denied$;

-- A valid admin role does not survive account disablement.
RESET ROLE;
UPDATE public.profiles SET account_status = 'disabled'
WHERE id = 'c2100000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub', 'c2100000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'c2100000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $disabled_admin_denied$
BEGIN
  BEGIN
    PERFORM public.verdict_acces_dossier_kyc(
      'c2100000-0000-0000-0000-000000000003'
    );
    RAISE EXCEPTION 'F86: disabled admin obtained a KYC access verdict';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$disabled_admin_denied$;

-- Verify both effective ACL and a direct invocation under anon.
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.uid', '', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE anon;
DO $anonymous_denied$
BEGIN
  IF pg_catalog.has_function_privilege(
       'anon', 'public.verdict_acces_dossier_kyc(uuid)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C-21: anon retains EXECUTE on the verdict RPC';
  END IF;
  BEGIN
    PERFORM public.verdict_acces_dossier_kyc(
      'c2100000-0000-0000-0000-000000000003'
    );
    RAISE EXCEPTION 'C-21: anon obtained a KYC access verdict';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$anonymous_denied$;

ROLLBACK;
