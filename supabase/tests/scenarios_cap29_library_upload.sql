-- CAP29 R2 upload: intentions are tied to an owned draft and fixed-size object.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c29u1000-0000-0000-0000-000000000001', 'cap29-upload-admin@test.invalid'),
  ('c29u1000-0000-0000-0000-000000000002', 'cap29-upload-teacher@test.invalid');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('c29u1000-0000-0000-0000-000000000001', 'C29-UPLOAD-ADMIN', 'admin', 'Upload', 'Admin', 'active', 'female'),
  ('c29u1000-0000-0000-0000-000000000002', 'C29-UPLOAD-TEACH', 'teacher', 'Upload', 'Teacher', 'active', 'male');
INSERT INTO public.library_resource
  (id, title, short_title, resource_type, language, category, access_policy, offline_policy)
VALUES
  ('c29u1000-0000-0000-0000-000000000003', 'Upload draft', 'Upload', 'pdf', 'fr', 'cours', 'admin', 'jamais');
INSERT INTO public.resource_version (id, resource_id, numero_version)
VALUES ('c29u1000-0000-0000-0000-000000000004',
        'c29u1000-0000-0000-0000-000000000003', 1);

SELECT set_config('request.jwt.claim.sub', 'c29u1000-0000-0000-0000-000000000001', true);
SELECT set_config('test.uid', 'c29u1000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_intention jsonb;
BEGIN
  IF has_function_privilege('anon', 'public.demander_upload_bibliotheque(uuid,text,text,text,bigint,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.confirmer_upload_bibliotheque(uuid,text,bigint,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.lire_upload_bibliotheque(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.annuler_upload_bibliotheque(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CAP29 upload: anon conserve EXECUTE';
  END IF;
  v_intention := public.demander_upload_bibliotheque(
    'c29u1000-0000-0000-0000-000000000003', 'support', 'manuel.pdf',
    'application/pdf', 1234,
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  );
  IF v_intention->>'cle_temporaire' <> ('private/libraryupload/' || (v_intention->>'id'))
     OR v_intention->>'cle_finale' !~ '^supports/[0-9a-f-]{36}/1/manuel\.pdf$' THEN
    RAISE EXCEPTION 'CAP29 upload: chemin de depot inattendu: %', v_intention;
  END IF;
  IF public.annuler_upload_bibliotheque((v_intention->>'id')::uuid) IS NOT TRUE THEN
    RAISE EXCEPTION 'CAP29 upload: annulation attendue';
  END IF;
  BEGIN
    PERFORM public.demander_upload_bibliotheque(
      'c29u1000-0000-0000-0000-000000000003', 'support', 'archive.zip',
      'application/zip', 1234,
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    );
    RAISE EXCEPTION 'CAP29 upload: type non pris en charge accepté';
  EXCEPTION WHEN invalid_parameter_value THEN
    NULL;
  END;
END
$test$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub', 'c29u1000-0000-0000-0000-000000000002', true);
SELECT set_config('test.uid', 'c29u1000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
SET LOCAL ROLE authenticated;
DO $refus$
BEGIN
  BEGIN
    PERFORM public.demander_upload_bibliotheque(
      'c29u1000-0000-0000-0000-000000000003', 'support', 'manuel.pdf',
      'application/pdf', 1234,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    );
    RAISE EXCEPTION 'CAP29 upload: enseignant a créé une intention admin';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$refus$;
RESET ROLE;
ROLLBACK;
