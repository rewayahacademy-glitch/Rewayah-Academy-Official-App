BEGIN;

INSERT INTO auth.users (id, email)
VALUES ('c1a10000-0000-0000-0000-000000000001', 'kyc-controller@example.test');
INSERT INTO public.profiles
  (id, immutable_id, role, gender, first_name, last_name, account_status)
VALUES
  ('c1a10000-0000-0000-0000-000000000001', 'KYC-CTRL-000001', 'controller',
   'female', 'Controleur', 'Test', 'active');

DO $storage_policy$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'kyc_lecture_admin'
     ) THEN
    RAISE EXCEPTION 'KYC-LECTURE-1: la policy de lecture Storage KYC subsiste';
  END IF;
END
$storage_policy$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'c1a10000-0000-0000-0000-000000000001', true);
SELECT set_config('test.uid', 'c1a10000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"controller"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);

DO $controller_denied$
BEGIN
  BEGIN
    PERFORM 1 FROM public.read_kyc_documents();
    RAISE EXCEPTION 'KYC-LECTURE-1: le contrôleur a lu la file KYC';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'acces KYC refuse' THEN RAISE; END IF;
  END;

  BEGIN
    PERFORM public.autoriser_lecture_piece_identite(
      'c1a10000-0000-0000-0000-000000000099'
    );
    RAISE EXCEPTION 'KYC-LECTURE-1: le contrôleur a ouvert une pièce KYC';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'lecture des pieces d''identite reservee a la Direction' THEN RAISE; END IF;
  END;
END
$controller_denied$;

ROLLBACK;
