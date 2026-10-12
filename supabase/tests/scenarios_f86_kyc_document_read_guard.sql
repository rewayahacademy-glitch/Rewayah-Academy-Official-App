-- F86 : lecture KYC refuse les contexts hors admin valide avant tout document.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8690000-0000-0000-0000-000000000001', 'f86-kyc-guardian@example.test'),
  ('f8690000-0000-0000-0000-000000000002', 'f86-kyc-disabled-admin@example.test'),
  ('f8690000-0000-0000-0000-000000000003', 'f86-kyc-no-profile-admin@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f869ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8690000-0000-0000-0000-000000000001', 'F86KYCGUARDIAN001', 'guardian',
   'f869ffff-0000-0000-0000-000000000001', 'F86', 'Guardian', 'active'),
  ('f8690000-0000-0000-0000-000000000002', 'F86KYCDISABLED002', 'admin',
   'f869ffff-0000-0000-0000-000000000001', 'F86', 'DisabledAdmin', 'disabled');

SET LOCAL ROLE authenticated;
DO $f86_kyc_guard$
DECLARE
  v_case record;
BEGIN
  FOR v_case IN
    SELECT * FROM (VALUES
      ('f8690000-0000-0000-0000-000000000003', '{"app_metadata":{"role":"admin"}}'),
      ('f8690000-0000-0000-0000-000000000002', '{"app_metadata":{"role":"admin"}}'),
      ('f8690000-0000-0000-0000-000000000001', '{"app_metadata":{"role":"guardian"}}'),
      ('f8690000-0000-0000-0000-000000000001', '{"app_metadata":{}}')
    ) AS cases(uid, claims)
  LOOP
    PERFORM set_config('request.jwt.claim.sub', v_case.uid, true);
    PERFORM set_config('request.jwt.claims', v_case.claims, true);
    PERFORM set_config('test.uid', v_case.uid, true);
    PERFORM set_config('test.jwt', v_case.claims, true);
    BEGIN
      PERFORM public.autoriser_lecture_piece_identite(NULL::uuid);
      RAISE EXCEPTION 'F86: autoriser_lecture_piece_identite a accepte un contexte interdit';
    EXCEPTION WHEN insufficient_privilege THEN
      IF SQLERRM <> 'lecture des pieces d''identite reservee a l''administration' THEN RAISE; END IF;
    END;
  END LOOP;
END
$f86_kyc_guard$;
RESET ROLE;
ROLLBACK;
