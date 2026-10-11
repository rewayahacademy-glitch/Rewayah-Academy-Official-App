BEGIN;

INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
  ('c2900000-0000-0000-0000-000000000001', 'c29-admin@test.invalid', now()),
  ('c2900000-0000-0000-0000-000000000002', 'c29-teacher@test.invalid', now());
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status)
VALUES
  ('c2900000-0000-0000-0000-000000000001', 'C29-ADMIN-0001', 'admin', 'Admin', 'C29', 'active'),
  ('c2900000-0000-0000-0000-000000000002', 'C29-TEACH-0001', 'teacher', 'Teacher', 'C29', 'provisional_active');

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
    RAISE EXCEPTION 'C29: aucun identifiant de capacité créé';
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
    RAISE EXCEPTION 'C29: la capacité active avec MFA est refusée';
  END IF;
  PERFORM pg_catalog.set_config('request.jwt.claims', '{"aal":"aal1","app_metadata":{"role":"teacher"}}', true);
  IF public.ma_capacite_controle_active() THEN
    RAISE EXCEPTION 'C29: une session aal1 conserve la capacité';
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
    RAISE EXCEPTION 'C29: un profil enseignant a utilisé un role admin stale du JWT';
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
    RAISE EXCEPTION 'C29: une session aal1 a retiré une capacité';
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
    v_id, 'retrait de scénario', 'c29a0000-0000-0000-0000-000000000004'
  ) THEN
    RAISE EXCEPTION 'C29: retrait initial non appliqué';
  END IF;
  IF public.retirer_capacite_controle(
    v_id, 'retrait de scénario', 'c29a0000-0000-0000-0000-000000000004'
  ) THEN
    RAISE EXCEPTION 'C29: retrait rejoué signalé comme nouvelle mutation';
  END IF;
END;
$test$;

SELECT set_config('request.jwt.claim.sub', 'c2900000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"teacher"}}', true);
DO $test$
BEGIN
  IF public.ma_capacite_controle_active() THEN
    RAISE EXCEPTION 'C29: la révocation ne prend pas effet immédiatement';
  END IF;
END;
$test$;

RESET ROLE;
DO $postflight$
BEGIN
  IF has_table_privilege('authenticated', 'private.controle_capacites', 'SELECT')
     OR has_table_privilege('anon', 'private.controle_capacites', 'SELECT')
     OR has_function_privilege('anon', 'public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.ma_capacite_controle_active()', 'EXECUTE') THEN
    RAISE EXCEPTION 'C29: exposition directe ou ACL indegue';
  END IF;
  IF (SELECT count(*) FROM public.audit_logs
       WHERE action IN ('controle_capacite_accordee', 'controle_capacite_retiree')) < 2 THEN
    RAISE EXCEPTION 'C29: attribution/retrait non journalisé';
  END IF;
END;
$postflight$;

ROLLBACK;
