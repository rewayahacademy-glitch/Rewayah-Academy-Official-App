-- DELEG-FIN-1: server-only payout delegation, renewal and isolation.
BEGIN;

INSERT INTO auth.users (id,email) VALUES
  ('df100000-0000-0000-0000-000000000001','df1-admin@test.invalid'),
  ('df100000-0000-0000-0000-000000000002','df1-accountant@test.invalid'),
  ('df100000-0000-0000-0000-000000000003','df1-beneficiary@test.invalid');
INSERT INTO public.households(id,timezone) VALUES
  ('df10ffff-0000-0000-0000-000000000001','Europe/Paris');
INSERT INTO public.profiles
  (id,immutable_id,role,household_id,first_name,last_name,account_status,gender)
VALUES
  ('df100000-0000-0000-0000-000000000001','DF1-ADMIN','admin',NULL,'Admin','Finance','active','female'),
  ('df100000-0000-0000-0000-000000000002','DF1-ACCOUNTANT','accountant',NULL,'Accountant','Finance','active','male'),
  ('df100000-0000-0000-0000-000000000003','DF1-BENEFICIARY','guardian','df10ffff-0000-0000-0000-000000000001','Beneficiary','Finance','active','female');
INSERT INTO public.wallets(id,household_id,currency) VALUES
  ('df100000-0000-0000-0000-000000000101','df10ffff-0000-0000-0000-000000000001','EUR');
INSERT INTO public.payout_methods(id,profile_id,kind,details) VALUES
  ('df100000-0000-0000-0000-000000000102','df100000-0000-0000-0000-000000000003','test','{}');

-- 1. Default policy has zero usable ceiling; no payout is admitted.
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000002","aal":"aal2","app_metadata":{"role":"accountant"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_denied boolean:=false;
BEGIN
  BEGIN
    INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
    VALUES('df100000-0000-0000-0000-000000000101','df100000-0000-0000-0000-000000000102',100);
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: default zero cap allowed a payout'; END IF;
END;
$test$;
RESET ROLE;

-- 2. Admin with aal2 saves one version idempotently; caps share a valid currency.
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal2","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v1 jsonb; v2 jsonb; v_policy jsonb:=jsonb_build_object(
  'paiements_standards_autorises',true,
  'plafond_par_transaction',jsonb_build_object('mineur',10000,'devise','EUR'),
  'plafond_par_lot',jsonb_build_object('mineur',8000,'devise','EUR'),
  'plafond_par_periode',jsonb_build_object('mineur',9000,'devise','EUR'),
  'remboursement_standard_autorise',false,'alimentation_reserve_autorisee',false,
  'retrait_reserve_interdit',true,'premier_paiement_seconde_validation',true,
  'coordonnees_recentes_seconde_validation',true,'jours_coordonnees_recentes',30,
  'exceptions','[]'::jsonb);
BEGIN
  v1:=public.enregistrer_delegation_finance(v_policy,'df100000-0000-0000-0000-000000000201');
  v2:=public.enregistrer_delegation_finance(v_policy,'df100000-0000-0000-0000-000000000201');
  IF v1->>'version' IS DISTINCT FROM v2->>'version' THEN
    RAISE EXCEPTION 'DELEG-FIN-1: policy save is not idempotent';
  END IF;
END;
$test$;

-- 3. Invalid amount shape, currency and sign are rejected by the table guard.
RESET ROLE;
DO $test$
DECLARE v_rejected boolean; v_policy jsonb;
BEGIN
  FOREACH v_policy IN ARRAY ARRAY[
    '{"mineur":-1,"devise":"EUR"}'::jsonb,
    '{"mineur":10,"devise":"eur"}'::jsonb,
    '{"mineur":"10","devise":"EUR"}'::jsonb,
    '{"mineur":10,"devise":"USD"}'::jsonb,
    '{"mineur":10,"devise":"EUR","extra":1}'::jsonb
  ] LOOP
    v_rejected:=false;
    BEGIN
      UPDATE public.finance_delegation SET politique=jsonb_set(
        politique,'{plafond_par_lot}',v_policy,true) WHERE cle_globale='global';
  EXCEPTION WHEN check_violation THEN v_rejected:=true;
    END;
    IF NOT v_rejected THEN RAISE EXCEPTION 'DELEG-FIN-1: invalid batch cap was accepted: %',v_policy; END IF;
  END LOOP;
END;
$test$;

-- 4. A valid request is server-stamped with a minimum 24-hour hold.
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000002","aal":"aal2","app_metadata":{"role":"accountant"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_id uuid;
BEGIN
  INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
  VALUES('df100000-0000-0000-0000-000000000101','df100000-0000-0000-0000-000000000102',5000)
  RETURNING id INTO v_id;
  IF (SELECT executable_apres < pg_catalog.clock_timestamp()+interval '23 hours 59 minutes'
      FROM public.payouts WHERE id=v_id) THEN
    RAISE EXCEPTION 'DELEG-FIN-1: client or server shortened the 24-hour hold';
  END IF;
  PERFORM set_config('test.deleg_fin_payout_id',v_id::text,true);
END;
$test$;

-- 5. Period aggregate prevents splitting a payout around the ceiling.
DO $test$
DECLARE v_denied boolean:=false;
BEGIN
  BEGIN
    INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
    VALUES('df100000-0000-0000-0000-000000000101','df100000-0000-0000-0000-000000000102',5000);
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: cumulative period cap was exceeded'; END IF;
END;
$test$;
RESET ROLE;

-- 6. Early payment is refused; explicit admin cancellation is idempotent/terminal.
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal2","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_id uuid:=current_setting('test.deleg_fin_payout_id')::uuid; v_denied boolean:=false;
BEGIN
  BEGIN UPDATE public.payouts SET status='paid' WHERE id=v_id;
  EXCEPTION WHEN object_not_in_prerequisite_state THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: early payout was marked paid'; END IF;
END;
$test$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000002","aal":"aal2","app_metadata":{"role":"accountant"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_id uuid:=current_setting('test.deleg_fin_payout_id')::uuid; v_denied boolean:=false;
BEGIN
  BEGIN PERFORM public.annuler_sortie_delegation_finance(v_id,'df100000-0000-0000-0000-000000000301');
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: accountant cancelled a payout'; END IF;
END;
$test$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal1","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_id uuid:=current_setting('test.deleg_fin_payout_id')::uuid; v_denied boolean:=false;
BEGIN
  BEGIN PERFORM public.annuler_sortie_delegation_finance(v_id,'df100000-0000-0000-0000-000000000302');
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: aal1 admin cancelled a payout'; END IF;
END;
$test$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal2","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_id uuid:=current_setting('test.deleg_fin_payout_id')::uuid; v_denied boolean:=false;
BEGIN
  PERFORM public.annuler_sortie_delegation_finance(v_id,'df100000-0000-0000-0000-000000000301');
  PERFORM public.annuler_sortie_delegation_finance(v_id,'df100000-0000-0000-0000-000000000301');
  IF (SELECT status FROM public.payouts WHERE id=v_id)<>'cancelled' THEN
    RAISE EXCEPTION 'DELEG-FIN-1: cancellation did not reach terminal state';
  END IF;
  BEGIN UPDATE public.payouts SET status='failed' WHERE id=v_id;
  EXCEPTION WHEN object_not_in_prerequisite_state THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: cancelled payout was mutable'; END IF;
END;
$test$;

-- 7. Suspension cancels pending requests and renewal must preserve suspension.
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal2","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000002","aal":"aal2","app_metadata":{"role":"accountant"}}',true);
SET LOCAL ROLE authenticated;
INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
VALUES('df100000-0000-0000-0000-000000000101','df100000-0000-0000-0000-000000000102',1000);
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal2","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_before timestamptz; v_result jsonb;
BEGIN
  v_result:=public.suspendre_toutes_delegations_finance('df100000-0000-0000-0000-000000000305');
  IF v_result->>'etat'<>'suspendue' OR EXISTS(SELECT 1 FROM public.payouts WHERE status='requested') THEN
    RAISE EXCEPTION 'DELEG-FIN-1: suspension left a requested payout executable';
  END IF;
  SELECT expire_le INTO v_before FROM public.finance_delegation WHERE cle_globale='global';
  v_result:=public.renouveler_delegation_finance('df100000-0000-0000-0000-000000000302');
  IF v_result->>'etat'<>'suspendue' OR NOT coalesce((v_result->>'expire_le')::timestamptz>v_before,false) THEN
    RAISE EXCEPTION 'DELEG-FIN-1: renewal lifted suspension or failed to extend expiry';
  END IF;
END;
$test$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000002","aal":"aal2","app_metadata":{"role":"accountant"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_denied boolean:=false;
BEGIN
  BEGIN INSERT INTO public.payouts(wallet_id,payout_method_id,amount_minor)
    VALUES('df100000-0000-0000-0000-000000000101','df100000-0000-0000-0000-000000000102',1000);
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: suspended delegation admitted a new request'; END IF;
END;
$test$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000001","aal":"aal2","app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_result jsonb;
BEGIN
  v_result:=public.reactiver_delegation_finance('df100000-0000-0000-0000-000000000306','motif valide');
  IF v_result->>'etat'<>'active' THEN RAISE EXCEPTION 'DELEG-FIN-1: explicit reactivation did not lift suspension'; END IF;
END;
$test$;

-- 8. Reactivation requires a 3..500 character reason and cannot revive expiry.
RESET ROLE;
UPDATE public.finance_delegation SET expire_le=pg_catalog.clock_timestamp()-interval '1 second'
  WHERE cle_globale='global';
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_denied boolean; v_reason text;
BEGIN
  FOREACH v_reason IN ARRAY ARRAY['  ','x',repeat('x',501)] LOOP
    v_denied:=false;
    BEGIN PERFORM public.reactiver_delegation_finance('df100000-0000-0000-0000-000000000303',v_reason);
    EXCEPTION WHEN invalid_parameter_value THEN v_denied:=true; END;
    IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: invalid reactivation reason accepted'; END IF;
  END LOOP;
  v_denied:=false;
  BEGIN PERFORM public.reactiver_delegation_finance('df100000-0000-0000-0000-000000000304','motif valable');
  EXCEPTION WHEN object_not_in_prerequisite_state THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: expired delegation was reactivated'; END IF;
END;
$test$;
RESET ROLE;

-- 9. Accountant has no delegation reads/writes; journal and direct DML stay closed.
RESET ROLE;
DO $test$
DECLARE v_denied boolean:=false;
BEGIN
  BEGIN UPDATE public.finance_delegation_journal SET payload='{}'
    WHERE id=(SELECT max(id) FROM public.finance_delegation_journal);
  EXCEPTION WHEN object_not_in_prerequisite_state THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: journal is mutable'; END IF;
END;
$test$;
SELECT set_config('request.jwt.claim.sub','df100000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claims','{"sub":"df100000-0000-0000-0000-000000000002","aal":"aal2","app_metadata":{"role":"accountant"}}',true);
SET LOCAL ROLE authenticated;
DO $test$
DECLARE v_count integer; v_denied boolean:=false;
BEGIN
  SELECT count(*) INTO v_count FROM public.finance_delegation;
  IF v_count<>0 THEN RAISE EXCEPTION 'DELEG-FIN-1: accountant read delegation rows'; END IF;
  BEGIN UPDATE public.finance_delegation SET version=version+1;
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true; END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DELEG-FIN-1: direct delegation update allowed'; END IF;
  IF has_function_privilege('authenticated','public.renouveler_delegation_finance(uuid)','EXECUTE') THEN
    NULL; -- the RPC is executable, its runtime MFA/admin guard is authoritative.
  ELSE
    RAISE EXCEPTION 'DELEG-FIN-1: expected authenticated RPC grant is missing';
  END IF;
END;
$test$;

ROLLBACK;
