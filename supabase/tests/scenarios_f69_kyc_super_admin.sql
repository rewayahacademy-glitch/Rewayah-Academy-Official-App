BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('f6900000-0000-0000-0000-000000000001', 'f69-admin-m@example.test'),
 ('f6900000-0000-0000-0000-000000000002', 'f69-admin-f@example.test'),
 ('f6900000-0000-0000-0000-000000000003', 'f69-admin-null@example.test'),
 ('f6900000-0000-0000-0000-000000000004', 'f69-controller@example.test'),
 ('f6900000-0000-0000-0000-000000000005', 'f69-person-m@example.test'),
 ('f6900000-0000-0000-0000-000000000006', 'f69-person-f@example.test'),
 ('f6900000-0000-0000-0000-000000000007', 'f69-guardian@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f6900000-0000-0000-0000-000000000101', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender,
   account_status)
VALUES
 ('f6900000-0000-0000-0000-000000000001', 'F69-ADMIN-M', 'admin', 'f6900000-0000-0000-0000-000000000101', 'Admin', 'M', 'male', 'active'),
 ('f6900000-0000-0000-0000-000000000002', 'F69-ADMIN-F', 'admin', 'f6900000-0000-0000-0000-000000000101', 'Admin', 'F', 'female', 'active'),
 ('f6900000-0000-0000-0000-000000000003', 'F69-ADMIN-NULL', 'admin', 'f6900000-0000-0000-0000-000000000101', 'Admin', 'N', NULL, 'active'),
 ('f6900000-0000-0000-0000-000000000004', 'F69-CONTROLLER', 'controller', 'f6900000-0000-0000-0000-000000000101', 'Control', 'Refuse', 'male', 'active'),
 ('f6900000-0000-0000-0000-000000000005', 'F69-PERSON-M', 'teacher', 'f6900000-0000-0000-0000-000000000101', 'Personne', 'M', 'male', 'active'),
 ('f6900000-0000-0000-0000-000000000006', 'F69-PERSON-F', 'teacher', 'f6900000-0000-0000-0000-000000000101', 'Personne', 'F', 'female', 'active'),
 ('f6900000-0000-0000-0000-000000000007', 'F69-GUARDIAN', 'guardian', 'f6900000-0000-0000-0000-000000000101', 'Parent', 'Refuse', 'female', 'active');

INSERT INTO private.super_admin_kyc(profile_id, granted_by)
VALUES ('f6900000-0000-0000-0000-000000000002', 'f6900000-0000-0000-0000-000000000001');

INSERT INTO public.kyc_documents (id, profile_id, doc_type, gender, object_key)
VALUES
 ('f6900000-0000-0000-0000-000000000201', 'f6900000-0000-0000-0000-000000000005', 'passport', 'male', 'f69/personne-m.webp'),
 ('f6900000-0000-0000-0000-000000000202', 'f6900000-0000-0000-0000-000000000006', 'passport', 'female', 'f69/personne-f.webp');

DO $scenario$
DECLARE
  v_count integer;
  v_audit_before bigint;
  v_audit_after bigint;
BEGIN
  IF to_regclass('storage.objects') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'kyc_client_read_block'
      AND qual LIKE '%bucket_id%' AND qual LIKE '%false%'
  ) THEN RAISE EXCEPTION 'F69: policy Storage KYC absente ou non bornee'; END IF;

  SET LOCAL ROLE authenticated;

  PERFORM set_config('test.uid', 'f6900000-0000-0000-0000-000000000001', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  SELECT count(*) INTO v_count FROM public.read_kyc_documents()
  WHERE id IN (
    'f6900000-0000-0000-0000-000000000201',
    'f6900000-0000-0000-0000-000000000202'
  );
  IF v_count <> 1 OR EXISTS (
    SELECT 1 FROM public.read_kyc_documents()
    WHERE id IN (
      'f6900000-0000-0000-0000-000000000201',
      'f6900000-0000-0000-0000-000000000202'
    ) AND gender <> 'male'
  ) THEN RAISE EXCEPTION 'F69 : admin homme voit autre chose que son genre'; END IF;
  IF (SELECT count(*) FROM public.kyc_documents) <> 0 THEN
    RAISE EXCEPTION 'F69 : lecture directe KYC disponible malgré la policy de refus';
  END IF;
  BEGIN
    PERFORM public.autoriser_lecture_piece_identite('f6900000-0000-0000-0000-000000000202');
    RAISE EXCEPTION 'F69 : admin homme a ouvert une pièce de l''autre genre';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('test.uid', 'f6900000-0000-0000-0000-000000000005', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
  BEGIN
    PERFORM 1 FROM public.read_kyc_documents();
    RAISE EXCEPTION 'F69: enseignant a lu des dossiers KYC';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.autoriser_lecture_piece_identite('f6900000-0000-0000-0000-000000000201');
    RAISE EXCEPTION 'F69: enseignant a ouvert une piece KYC';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('test.uid', 'f6900000-0000-0000-0000-000000000007', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
  BEGIN
    PERFORM 1 FROM public.read_kyc_documents();
    RAISE EXCEPTION 'F69: tuteur a lu des dossiers KYC';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.autoriser_lecture_piece_identite('f6900000-0000-0000-0000-000000000201');
    RAISE EXCEPTION 'F69: tuteur a ouvert une piece KYC';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('test.uid', 'f6900000-0000-0000-0000-000000000003', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  BEGIN
    PERFORM 1 FROM public.read_kyc_documents();
    RAISE EXCEPTION 'F69 : admin sans genre a lu des dossiers';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('test.uid', 'f6900000-0000-0000-0000-000000000004', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);
  BEGIN
    PERFORM 1 FROM public.read_kyc_documents();
    RAISE EXCEPTION 'F69 : controller a lu des dossiers';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.ma_exception_kyc_active();
    RAISE EXCEPTION 'F69: controller read the admin exception state';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.autoriser_lecture_piece_identite('f6900000-0000-0000-0000-000000000201');
    RAISE EXCEPTION 'F69 : controller a ouvert une pièce';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('test.uid', 'f6900000-0000-0000-0000-000000000002', true);
  PERFORM set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  IF NOT public.ma_exception_kyc_active() THEN
    RAISE EXCEPTION 'F69: l''administration ne voit pas l''exception active';
  END IF;
  UPDATE public.app_config SET value = 'false'::jsonb
  WHERE key = 'kyc_exception_super_admin';
  IF public.ma_exception_kyc_active() THEN
    RAISE EXCEPTION 'F69: statut exception actif apres desactivation';
  END IF;
  SELECT count(*) INTO v_count FROM public.read_kyc_documents()
  WHERE id IN (
    'f6900000-0000-0000-0000-000000000201',
    'f6900000-0000-0000-0000-000000000202'
  );
  IF v_count <> 1 THEN RAISE EXCEPTION 'F69 : exception désactivée ne respecte pas le genre'; END IF;
  BEGIN
    PERFORM public.autoriser_lecture_piece_identite('f6900000-0000-0000-0000-000000000201');
    RAISE EXCEPTION 'F69 : exception coupée a permis l''autre genre';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  UPDATE public.app_config SET value = 'true'::jsonb
  WHERE key = 'kyc_exception_super_admin';
  IF NOT public.ma_exception_kyc_active() THEN
    RAISE EXCEPTION 'F69: statut exception inactif apres activation';
  END IF;
  SELECT count(*) INTO v_audit_before FROM public.audit_logs
  WHERE actor = auth.uid() AND action = 'kyc_read';
  SELECT count(*) INTO v_count FROM public.read_kyc_documents()
  WHERE id IN (
    'f6900000-0000-0000-0000-000000000201',
    'f6900000-0000-0000-0000-000000000202'
  );
  SELECT count(*) INTO v_audit_after FROM public.audit_logs
  WHERE actor = auth.uid() AND action = 'kyc_read';
  IF v_audit_after - v_audit_before <> 1 OR NOT EXISTS (
    SELECT 1 FROM public.audit_logs
    WHERE actor = auth.uid() AND action = 'kyc_read'
      AND payload ->> 'document_count' = '2'
  ) THEN
    RAISE EXCEPTION 'F69: un seul audit de liste doit couvrir tous les documents';
  END IF;
  IF v_count <> 2 THEN RAISE EXCEPTION 'F69 : super-admin actif ne voit pas les deux genres'; END IF;
  PERFORM public.autoriser_lecture_piece_identite('f6900000-0000-0000-0000-000000000201');
  IF NOT EXISTS (
    SELECT 1 FROM public.audit_logs
    WHERE action = 'kyc_document_open'
      AND row_id = 'f6900000-0000-0000-0000-000000000201'
      AND payload ->> 'motif' = 'exception_super_admin_kyc'
  ) THEN RAISE EXCEPTION 'F69 : ouverture exceptionnelle non auditée'; END IF;

  BEGIN
    INSERT INTO private.super_admin_kyc(profile_id)
    VALUES ('f6900000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'F69 : marqueur super-admin modifiable par un admin client';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$scenario$;

ROLLBACK;
