BEGIN;

INSERT INTO auth.users (id, email)
VALUES ('c1a10000-0000-0000-0000-000000000001', 'kyc-controller@example.test'),
       ('c1a10000-0000-0000-0000-000000000002', 'kyc-disabled-admin@example.test');
INSERT INTO public.profiles
  (id, immutable_id, role, gender, first_name, last_name, account_status)
VALUES
  ('c1a10000-0000-0000-0000-000000000001', 'KYC-CTRL-000001', 'controller',
   'female', 'Controleur', 'Test', 'active'),
  ('c1a10000-0000-0000-0000-000000000002', 'KYC-ADMIN-000002', 'admin',
   'female', 'Admin', 'Desactive', 'disabled');

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
  EXCEPTION WHEN insufficient_privilege THEN
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

-- Le stub SQL ne valide pas la claim exp du JWT. Cette échéance se vérifie au
-- gateway Auth/PostgREST avec un vrai jeton expiré, pas par request.jwt.claims.
DO $other_contexts_denied$
DECLARE v_case record;
BEGIN
  FOR v_case IN
    SELECT * FROM (VALUES
      ('c1a10000-0000-0000-0000-000000000002'::uuid, '{"app_metadata":{"role":"admin"}}'::text,
       'admin désactivé'),
      ('c1a10000-0000-0000-0000-000000000099'::uuid, '{"app_metadata":{"role":"admin"}}'::text,
       'JWT admin sans profil'),
      ('c1a10000-0000-0000-0000-000000000001'::uuid, '{"app_metadata":{"role":"guardian"}}'::text,
       'rôle non autorisé')
    ) AS cases(uid, claims, label)
  LOOP
    PERFORM set_config('request.jwt.claim.sub', v_case.uid::text, true);
    PERFORM set_config('test.uid', v_case.uid::text, true);
    PERFORM set_config('request.jwt.claims', v_case.claims, true);
    PERFORM set_config('test.jwt', v_case.claims, true);

    BEGIN
      PERFORM 1 FROM public.read_kyc_documents();
      RAISE EXCEPTION 'KYC-LECTURE-1: read_kyc_documents accepte %', v_case.label;
    EXCEPTION WHEN insufficient_privilege THEN
      IF SQLERRM <> 'acces KYC refuse' THEN RAISE; END IF;
    END;

    BEGIN
      PERFORM public.autoriser_lecture_piece_identite(
        'c1a10000-0000-0000-0000-000000000099'
      );
      RAISE EXCEPTION 'KYC-LECTURE-1: autoriser_lecture_piece_identite accepte %', v_case.label;
    EXCEPTION WHEN insufficient_privilege THEN
      IF SQLERRM <> 'lecture des pieces d''identite reservee a l''administration' THEN RAISE; END IF;
    END;
  END LOOP;
END
$other_contexts_denied$;

RESET ROLE;
SET LOCAL ROLE anon;
DO $anon_denied$
BEGIN
  BEGIN
    PERFORM 1 FROM public.read_kyc_documents();
    RAISE EXCEPTION 'KYC-LECTURE-1: anon a exécuté read_kyc_documents';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.autoriser_lecture_piece_identite(
      'c1a10000-0000-0000-0000-000000000099'
    );
    RAISE EXCEPTION 'KYC-LECTURE-1: anon a exécuté autoriser_lecture_piece_identite';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$anon_denied$;

ROLLBACK;
