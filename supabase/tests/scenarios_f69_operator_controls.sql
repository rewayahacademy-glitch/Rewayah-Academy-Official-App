-- F69 K-65 : seule une session PostgreSQL peut administrer l'exception KYC.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f6900000-0000-0000-0000-000000000001', 'f69-admin@example.test');
INSERT INTO public.households (id)
VALUES ('f69fffff-0000-0000-0000-000000000001');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('f6900000-0000-0000-0000-000000000001', 'F69ADMIN000001', 'admin',
   'f69fffff-0000-0000-0000-000000000001', 'Fixture', 'KYC Admin', 'active', 'female');
UPDATE public.households
SET primary_guardian_id = 'f6900000-0000-0000-0000-000000000001'
WHERE id = 'f69fffff-0000-0000-0000-000000000001';
SELECT set_config('test.uid', 'f6900000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"f69fffff-0000-0000-0000-000000000001"}}', true);

DO $acl$
BEGIN
  IF has_function_privilege('anon', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR has_function_privilege('authenticated', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR has_function_privilege('service_role', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR has_schema_privilege('authenticated', 'private', 'USAGE')
    OR has_table_privilege('authenticated', 'private.super_admin_kyc', 'SELECT') THEN
    RAISE EXCEPTION 'F69: les clients ne sont pas exclus des controles internes';
  END IF;
END
$acl$;

SET LOCAL ROLE authenticated;
DO $client_denied$
DECLARE v_denied boolean := false;
BEGIN
  BEGIN
    CALL app_private.attribuer_super_admin_kyc(
      'f6900000-0000-0000-0000-000000000001', 'client attempt');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'F69: authenticated a appele la procedure postgres'; END IF;

  v_denied := false;
  BEGIN
    UPDATE public.app_config SET value = 'false'::jsonb
    WHERE key = 'kyc_exception_super_admin';
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'F69: admin a modifie la cle reservee'; END IF;

  UPDATE public.app_config SET value = '9'::jsonb
  WHERE key = 'child_ui_mode_max_age';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'F69: la protection bloque aussi une autre cle de configuration';
  END IF;

  v_denied := false;
  BEGIN
    INSERT INTO public.app_config(key, value)
    VALUES ('kyc_exception_super_admin', 'false'::jsonb);
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'F69: admin a insere la cle reservee'; END IF;
END
$client_denied$;
RESET ROLE;

CALL app_private.attribuer_super_admin_kyc(
  'f6900000-0000-0000-0000-000000000001', 'relecture direction');
DO $assigned$
BEGIN
  IF NOT public.ma_exception_kyc_active()
    OR NOT EXISTS (
      SELECT 1 FROM private.super_admin_kyc s
      WHERE s.profile_id = 'f6900000-0000-0000-0000-000000000001'
        AND s.granted_by = 'postgres' AND s.motif = 'relecture direction'
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.audit_logs a
      WHERE a.action = 'super_admin_kyc_attribue'
        AND a.row_id = 'f6900000-0000-0000-0000-000000000001'
        AND a.payload->>'motif' = 'relecture direction'
        AND a.payload->>'granted_by' = 'postgres'
    ) THEN
    RAISE EXCEPTION 'F69: attribution ou audit absent';
  END IF;
END
$assigned$;

CALL app_private.basculer_exception_kyc(false, 'suspension de maintenance');
DO $disabled$
BEGIN
  IF public.ma_exception_kyc_active()
    OR NOT EXISTS (
      SELECT 1 FROM public.audit_logs a
      WHERE a.action = 'super_admin_kyc_exception_basculee'
        AND a.payload->>'motif' = 'suspension de maintenance'
        AND a.payload->>'nouveau' = 'false'
    ) THEN RAISE EXCEPTION 'F69: bascule de l''exception non auditee'; END IF;
END
$disabled$;
CALL app_private.basculer_exception_kyc(true, 'fin de maintenance');
CALL app_private.retirer_super_admin_kyc(
  'f6900000-0000-0000-0000-000000000001', 'fin de mission');
DO $removed$
BEGIN
  IF public.ma_exception_kyc_active()
    OR EXISTS (SELECT 1 FROM private.super_admin_kyc s
      WHERE s.profile_id = 'f6900000-0000-0000-0000-000000000001')
    OR NOT EXISTS (SELECT 1 FROM public.audit_logs a
      WHERE a.action = 'super_admin_kyc_retire'
        AND a.row_id = 'f6900000-0000-0000-0000-000000000001'
        AND a.payload->>'motif' = 'fin de mission') THEN
    RAISE EXCEPTION 'F69: retrait ou audit absent';
  END IF;
END
$removed$;

ROLLBACK;
