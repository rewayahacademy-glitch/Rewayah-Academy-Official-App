BEGIN;

-- 0081 déplace la signature des accès KYC dans l'Edge Function et retire la
-- lecture directe Storage. Réaffirmer ce retrait ferme aussi les bases dont la
-- policy historique 0004 autorisait encore le rôle controller.
DO $policy$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS kyc_lecture_admin ON storage.objects';
  END IF;
END
$policy$;

DO $postflight$
BEGIN
  IF pg_catalog.to_regclass('storage.objects') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_policies
        WHERE schemaname = 'storage'
          AND tablename = 'objects'
          AND policyname = 'kyc_lecture_admin'
     ) THEN
    RAISE EXCEPTION 'KYC-LECTURE-1: la policy Storage historique est toujours présente';
  END IF;
END
$postflight$;

COMMIT;
