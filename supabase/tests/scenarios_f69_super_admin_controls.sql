-- F69: direction-only management of the super-admin KYC exception.
BEGIN;

DO $privileges$
DECLARE
  v_routine text;
BEGIN
  FOREACH v_routine IN ARRAY ARRAY[
    'app_private.attribuer_super_admin_kyc(uuid,text)',
    'app_private.retirer_super_admin_kyc(uuid,text)',
    'app_private.basculer_exception_kyc(boolean,text)'
  ] LOOP
    IF has_function_privilege('anon', v_routine, 'EXECUTE')
       OR has_function_privilege('authenticated', v_routine, 'EXECUTE')
       OR has_function_privilege('service_role', v_routine, 'EXECUTE') THEN
      RAISE EXCEPTION 'F69 routine accessible hors postgres: %', v_routine;
    END IF;
    IF NOT has_function_privilege('postgres', v_routine, 'EXECUTE') THEN
      RAISE EXCEPTION 'F69 postgres ne peut pas appeler: %', v_routine;
    END IF;
  END LOOP;
END
$privileges$;

INSERT INTO auth.users(id, email, email_confirmed_at)
VALUES ('f6900000-0000-4000-8000-000000000001', 'f69-test@example.invalid', pg_catalog.now())
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.households(id, status)
VALUES ('f6900000-0000-4000-8000-000000000002', 'active')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES (
  'f6900000-0000-4000-8000-000000000001', 'F69_TEST_ADMIN', 'admin',
  'f6900000-0000-4000-8000-000000000002', 'F69', 'Admin', 'active'
)
ON CONFLICT (id) DO UPDATE SET role = 'admin', account_status = 'active', deleted_at = NULL;

SELECT pg_catalog.set_config('request.jwt.claim.sub', 'f6900000-0000-4000-8000-000000000001', true);
SELECT pg_catalog.set_config(
  'request.jwt.claims',
  '{"app_metadata":{"role":"admin"}}',
  true
);

UPDATE public.profiles SET account_status = 'disabled'
WHERE id = 'f6900000-0000-4000-8000-000000000001';
DO $inactive_admin$
BEGIN
  BEGIN
    CALL app_private.attribuer_super_admin_kyc(
      'f6900000-0000-4000-8000-000000000001', 'must be denied'
    );
    RAISE EXCEPTION 'un admin suspendu a reçu la capacité super-admin';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'le profil cible doit etre un admin actif' THEN
      RAISE;
    END IF;
  END;
END
$inactive_admin$;
UPDATE public.profiles SET account_status = 'active'
WHERE id = 'f6900000-0000-4000-8000-000000000001';

CALL app_private.attribuer_super_admin_kyc(
  'f6900000-0000-4000-8000-000000000001', 'scénario F69 attribution'
);
DO $grant_audit$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM private.super_admin_kyc s
    WHERE s.profile_id = 'f6900000-0000-4000-8000-000000000001'
      AND s.granted_by = 'postgres'
      AND s.motif = 'scénario F69 attribution'
  ) THEN
    RAISE EXCEPTION 'F69 attribution non persistée avec auteur/motif';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.audit_logs a
    WHERE a.action = 'super_admin_kyc_attribue'
      AND a.row_id = 'f6900000-0000-4000-8000-000000000001'
      AND a.payload ->> 'motif' = 'scénario F69 attribution'
  ) THEN
    RAISE EXCEPTION 'F69 audit attribution absent';
  END IF;
END
$grant_audit$;

CALL app_private.retirer_super_admin_kyc(
  'f6900000-0000-4000-8000-000000000001', 'scénario F69 retrait'
);
CALL app_private.basculer_exception_kyc(true, 'scénario F69 activation');
DO $change_audit$
BEGIN
  IF EXISTS (
    SELECT 1 FROM private.super_admin_kyc s
    WHERE s.profile_id = 'f6900000-0000-4000-8000-000000000001'
  ) THEN
    RAISE EXCEPTION 'F69 retrait non appliqué';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.app_config c
    WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb
  ) THEN
    RAISE EXCEPTION 'F69 bascule de l''exception non appliquée';
  END IF;
  IF (SELECT count(*) FROM public.audit_logs a
      WHERE a.action = 'super_admin_kyc_retire'
        AND a.row_id = 'f6900000-0000-4000-8000-000000000001') <> 1
     OR (SELECT count(*) FROM public.audit_logs a
         WHERE a.action = 'kyc_exception_super_admin_bascule'
           AND a.payload ->> 'motif' = 'scénario F69 activation') <> 1 THEN
    RAISE EXCEPTION 'F69 audit retrait/bascule absent';
  END IF;
END
$change_audit$;

GRANT SELECT, UPDATE ON public.app_config TO authenticated;
SELECT pg_catalog.set_config(
  'request.jwt.claims',
  '{"app_metadata":{"role":"admin"}}',
  true
);
SET LOCAL ROLE authenticated;
DO $ordinary_admin$
BEGIN
  BEGIN
    UPDATE public.app_config
       SET value = 'false'::jsonb
     WHERE key = 'kyc_exception_super_admin';
    RAISE EXCEPTION 'un administrateur ordinaire a modifié la clé KYC protégée';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'seul postgres peut modifier kyc_exception_super_admin' THEN
      RAISE;
    END IF;
  END;

  UPDATE public.app_config SET value = '3'::jsonb
   WHERE key = 'max_devices_per_student';
END
$ordinary_admin$;
RESET ROLE;

ROLLBACK;
