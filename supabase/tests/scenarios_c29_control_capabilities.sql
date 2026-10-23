BEGIN;

INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  ('c2900000-0000-0000-0000-000000000001', 'c29-admin@test.invalid', now()),
  ('c2900000-0000-0000-0000-000000000002', 'c29-teacher@test.invalid', now());
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status)
VALUES
  ('c2900000-0000-0000-0000-000000000001', 'C29-ADMIN-0001', 'admin', 'Admin', 'C29', 'active'),
  ('c2900000-0000-0000-0000-000000000002', 'C29-TEACH-0001', 'teacher', 'Teacher', 'C29', 'provisional_active');
INSERT INTO public.teacher_profiles(profile_id,kyc_status)
VALUES ('c2900000-0000-0000-0000-000000000002','approved');
DO $fixture_teacher_contracts$
DECLARE v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 PERFORM set_config('request.jwt.claim.sub','c2900000-0000-0000-0000-000000000002',true);
 PERFORM set_config('test.uid','c2900000-0000-0000-0000-000000000002',true);
 PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
 PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
 PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
 INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES ('c2900000-0000-0000-0000-000000000002','recording_and_control_notice',v_notice_version) ON CONFLICT DO NOTHING;
 INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
 VALUES ('c2900000-0000-0000-0000-000000000002','teacher_conduct_code',public.code_conduite_version_requise())
 ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
 UPDATE public.profiles SET account_status='active' WHERE id='c2900000-0000-0000-0000-000000000002';
 PERFORM set_config('request.jwt.claim.sub','',true); PERFORM set_config('request.jwt.claims','',true);
 PERFORM set_config('test.uid','',true); PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contracts$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'c2900000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);

DO $test$
DECLARE
  v_first uuid;
  v_rejected boolean := false;
BEGIN
  v_first := public.accorder_capacite_controle(
    'c2900000-0000-0000-0000-000000000002',
    pg_catalog.clock_timestamp() - interval '1 minute',
    pg_catalog.clock_timestamp() + interval '1 day',
    true, '{}'::uuid[], '{}'::uuid[],
    'c29a0000-0000-0000-0000-000000000001'
  );
  IF v_first IS NULL THEN
    RAISE EXCEPTION 'C29: aucun identifiant de capacitأ© crأ©أ©';
  END IF;
  BEGIN
    PERFORM public.accorder_capacite_controle(
      'c2900000-0000-0000-0000-000000000002',
      pg_catalog.clock_timestamp() - interval '2 minute',
      pg_catalog.clock_timestamp() + interval '1 day',
      true, '{}'::uuid[], '{}'::uuid[],
      'c29a0000-0000-0000-0000-000000000001'
    );
  EXCEPTION WHEN raise_exception THEN
    v_rejected := true;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'C29: une cle rejouee avec payload modifie a ete acceptee';
  END IF;
END;
$test$;

DO $test$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp() - interval '1 minute';
  v_fin timestamptz := pg_catalog.clock_timestamp() + interval '1 day';
  v_first uuid;
  v_repeat uuid;
BEGIN
  v_first := public.accorder_capacite_controle(
    'c2900000-0000-0000-0000-000000000002', v_debut, v_fin,
    true, '{}'::uuid[], '{}'::uuid[],
    'c29a0000-0000-0000-0000-000000000002'
  );
  v_repeat := public.accorder_capacite_controle(
    'c2900000-0000-0000-0000-000000000002', v_debut, v_fin,
    true, '{}'::uuid[], '{}'::uuid[],
    'c29a0000-0000-0000-0000-000000000002'
  );
  IF v_first IS DISTINCT FROM v_repeat THEN
    RAISE EXCEPTION 'C29: accord non idempotent';
  END IF;
  PERFORM pg_catalog.set_config('test.capacite_id', v_first::text, true);
END;
$test$;

SELECT set_config('request.jwt.claim.sub', 'c2900000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"teacher"}}', true);
DO $test$
BEGIN
  IF NOT public.ma_capacite_controle_active() THEN
    RAISE EXCEPTION 'C29: la capacitأ© active avec MFA est refusأ©e';
  END IF;
  PERFORM pg_catalog.set_config('request.jwt.claims', '{"aal":"aal1","app_metadata":{"role":"teacher"}}', true);
  IF public.ma_capacite_controle_active() THEN
    RAISE EXCEPTION 'C29: une session aal1 conserve la capacitأ©';
  END IF;
END;
$test$;

SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
DO $test$
BEGIN
  BEGIN
    PERFORM public.accorder_capacite_controle(
      'c2900000-0000-0000-0000-000000000002',
      pg_catalog.clock_timestamp(), pg_catalog.clock_timestamp() + interval '1 day',
      true, '{}'::uuid[], '{}'::uuid[],
      'c29a0000-0000-0000-0000-000000000005'
    );
    RAISE EXCEPTION 'C29: un profil enseignant a utilisأ© un role admin stale du JWT';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$test$;

SELECT set_config('request.jwt.claim.sub', 'c2900000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal1","app_metadata":{"role":"admin"}}', true);
DO $test$
BEGIN
  BEGIN
    PERFORM public.retirer_capacite_controle(
      current_setting('test.capacite_id')::uuid, 'test aal1',
      'c29a0000-0000-0000-0000-000000000003'
    );
    RAISE EXCEPTION 'C29: une session aal1 a retirأ© une capacitأ©';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$test$;

SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
DO $test$
DECLARE v_id uuid := current_setting('test.capacite_id')::uuid;
BEGIN
  IF NOT public.retirer_capacite_controle(
    v_id, 'retrait de scأ©nario', 'c29a0000-0000-0000-0000-000000000004'
  ) THEN
    RAISE EXCEPTION 'C29: retrait initial non appliquأ©';
  END IF;
  IF public.retirer_capacite_controle(
    v_id, 'retrait de scأ©nario', 'c29a0000-0000-0000-0000-000000000004'
  ) THEN
    RAISE EXCEPTION 'C29: retrait rejouأ© signalأ© comme nouvelle mutation';
  END IF;
END;
$test$;

SELECT set_config('request.jwt.claim.sub', 'c2900000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"teacher"}}', true);
DO $test$
BEGIN
  IF public.ma_capacite_controle_active() THEN
    RAISE EXCEPTION 'C29: la rأ©vocation ne prend pas effet immأ©diatement';
  END IF;
END;
$test$;

DO $test$
BEGIN
  BEGIN
    PERFORM public.retirer_capacite_controle(
      current_setting('test.capacite_id')::uuid,
      'rôle enseignant interdit',
      'c29a0000-0000-0000-0000-000000000006'
    );
    RAISE EXCEPTION 'C29: un enseignant a retiré une capacité';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$test$;

RESET ROLE;
UPDATE public.profiles SET account_status = 'disabled'
 WHERE id = 'c2900000-0000-0000-0000-000000000001';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'c2900000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
DO $disabled_admin$
BEGIN
  BEGIN
    PERFORM public.accorder_capacite_controle(
      'c2900000-0000-0000-0000-000000000002',
      pg_catalog.clock_timestamp(), pg_catalog.clock_timestamp() + interval '1 day',
      true, '{}'::uuid[], '{}'::uuid[],
      'c29a0000-0000-0000-0000-000000000007'
    );
    RAISE EXCEPTION 'C29: une direction désactivée a accordé une capacité';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  BEGIN
    PERFORM public.retirer_capacite_controle(
      current_setting('test.capacite_id')::uuid,
      'direction désactivée',
      'c29a0000-0000-0000-0000-000000000008'
    );
    RAISE EXCEPTION 'C29: une direction désactivée a retiré une capacité';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  IF public.ma_capacite_controle_active() THEN
    RAISE EXCEPTION 'C29: une direction désactivée conserve une capacité active';
  END IF;
END;
$disabled_admin$;
RESET ROLE;

SET LOCAL ROLE anon;
DO $anonymous$
BEGIN
  BEGIN
    PERFORM public.accorder_capacite_controle(
      'c2900000-0000-0000-0000-000000000002',
      pg_catalog.clock_timestamp(), pg_catalog.clock_timestamp() + interval '1 day',
      true, '{}'::uuid[], '{}'::uuid[],
      'c29a0000-0000-0000-0000-000000000009'
    );
    RAISE EXCEPTION 'C29: anon a accordé une capacité';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.retirer_capacite_controle(
      current_setting('test.capacite_id')::uuid,
      'appel anon',
      'c29a0000-0000-0000-0000-000000000010'
    );
    RAISE EXCEPTION 'C29: anon a retiré une capacité';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.ma_capacite_controle_active();
    RAISE EXCEPTION 'C29: anon a consulté une capacité';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$anonymous$;
RESET ROLE;

DO $postflight$
BEGIN
  IF has_table_privilege('authenticated', 'private.controle_capacites', 'SELECT')
     OR has_table_privilege('anon', 'private.controle_capacites', 'SELECT')
     OR has_function_privilege('anon', 'public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.retirer_capacite_controle(uuid,text,uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.ma_capacite_controle_active()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.retirer_capacite_controle(uuid,text,uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.ma_capacite_controle_active()', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.ma_capacite_controle_active()', 'EXECUTE') THEN
    RAISE EXCEPTION 'C29: exposition directe ou ACL indegue';
  END IF;
  IF (SELECT count(*) FROM public.audit_logs
       WHERE action IN ('controle_capacite_accordee', 'controle_capacite_retiree')) < 2 THEN
    RAISE EXCEPTION 'C29: attribution/retrait non journalisأ©';
  END IF;
END;
$postflight$;

ROLLBACK;
