-- B-04 : controle negatif/positif des reprises et de l'idempotence.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('b0400000-0000-0000-0000-000000000001', 'b04-admin@example.test'),
  ('b0400000-0000-0000-0000-000000000002', 'b04-holder-a@example.test'),
  ('b0400000-0000-0000-0000-000000000003', 'b04-requester-a@example.test'),
  ('b0400000-0000-0000-0000-000000000004', 'b04-holder-b@example.test'),
  ('b0400000-0000-0000-0000-000000000005', 'b04-requester-b@example.test'),
  ('b0400000-0000-0000-0000-000000000006', 'b04-holder-c@example.test'),
  ('b0400000-0000-0000-0000-000000000007', 'b04-requester-c@example.test');

INSERT INTO public.households (id) VALUES
  ('b04fffff-0000-0000-0000-000000000001'),
  ('b04fffff-0000-0000-0000-000000000002'),
  ('b04fffff-0000-0000-0000-000000000003'),
  ('b04fffff-0000-0000-0000-000000000004');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('b0400000-0000-0000-0000-000000000001', 'B04ADMIN000001', 'admin',
   'b04fffff-0000-0000-0000-000000000003', 'B04', 'Admin', 'active', 'male'),
  ('b0400000-0000-0000-0000-000000000002', 'B04HOLDER00001', 'guardian',
   'b04fffff-0000-0000-0000-000000000001', 'Holder', 'One', 'active', 'female'),
  ('b0400000-0000-0000-0000-000000000003', 'B04REQUEST0001', 'guardian',
   'b04fffff-0000-0000-0000-000000000001', 'Requester', 'One', 'active', 'female'),
  ('b0400000-0000-0000-0000-000000000004', 'B04HOLDER00002', 'guardian',
   'b04fffff-0000-0000-0000-000000000002', 'Holder', 'Two', 'active', 'female'),
  ('b0400000-0000-0000-0000-000000000005', 'B04REQUEST0002', 'guardian',
   'b04fffff-0000-0000-0000-000000000002', 'Requester', 'Two', 'active', 'female'),
  ('b0400000-0000-0000-0000-000000000006', 'B04HOLDER00003', 'guardian',
   'b04fffff-0000-0000-0000-000000000004', 'Holder', 'Three', 'active', 'female'),
  ('b0400000-0000-0000-0000-000000000007', 'B04REQUEST0003', 'guardian',
   'b04fffff-0000-0000-0000-000000000004', 'Requester', 'Three', 'active', 'female');
UPDATE public.households SET primary_guardian_id = 'b0400000-0000-0000-0000-000000000002'
WHERE id = 'b04fffff-0000-0000-0000-000000000001';
UPDATE public.households SET primary_guardian_id = 'b0400000-0000-0000-0000-000000000004'
WHERE id = 'b04fffff-0000-0000-0000-000000000002';
UPDATE public.households SET primary_guardian_id = 'b0400000-0000-0000-0000-000000000006'
WHERE id = 'b04fffff-0000-0000-0000-000000000004';

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000003', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000001"}}', true);
DO $request$
DECLARE v_result jsonb; v_retry jsonb; v_denied boolean := false;
BEGIN
  v_result := public.deposer_reprise_foyer('b0400000-0000-0000-0000-000000000011');
  v_retry := public.deposer_reprise_foyer('b0400000-0000-0000-0000-000000000011');
  IF v_result->>'statut' <> 'enregistree' OR v_retry->>'statut' <> 'enregistree'
    OR (public.etat_reprise_foyer()->>'statut') <> 'attente_administration' THEN
    RAISE EXCEPTION 'B-04: depot ou etat du demandeur incorrect: %', v_result;
  END IF;
  BEGIN
    PERFORM * FROM public.lister_reprises_admin();
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-04: un guardian a pu lister les reprises administratives';
  END IF;
  IF has_table_privilege('authenticated', 'public.reprises_foyer', 'SELECT')
    OR has_table_privilege('authenticated', 'public.reprises_foyer', 'INSERT') THEN
    RAISE EXCEPTION 'B-04: acces direct client conserve sur la table';
  END IF;
END
$request$;

SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000004', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000002"}}', true);
DO $other_household$
DECLARE v_denied boolean := false;
BEGIN
  IF public.etat_reprise_foyer()->>'type' <> 'aucune' THEN
    RAISE EXCEPTION 'B-04: titulaire d un autre foyer voit une demande';
  END IF;
  BEGIN
    PERFORM public.refuser_reprise_foyer('b0400000-0000-0000-0000-000000000012');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-04: titulaire d un autre foyer a pu refuser la demande';
  END IF;
END
$other_household$;

SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000001"}}', true);
DO $holder_refusal$
DECLARE
  v_before jsonb;
  v_result jsonb;
  v_after jsonb;
BEGIN
  v_before := public.etat_reprise_foyer();
  IF v_before->>'type' <> 'titulaire' THEN
    RAISE EXCEPTION 'B-04: l etat initial du titulaire est absent';
  END IF;

  v_result := public.refuser_reprise_foyer(
    'b0400000-0000-0000-0000-000000000012'
  );
  IF v_result->>'statut' <> 'enregistree' THEN
    RAISE EXCEPTION 'B-04: le refus du titulaire ne s est pas enregistre';
  END IF;

  v_after := public.etat_reprise_foyer();
  IF v_after->>'statut' <> 'refusee_par_vous' THEN
    RAISE EXCEPTION 'B-04: refus du titulaire non reflechi';
  END IF;
END
$holder_refusal$;

SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000002"}}', true);
SELECT public.deposer_reprise_foyer('b0400000-0000-0000-0000-000000000021');
RESET ROLE;
SELECT set_config('test.reprise_id', (
  SELECT id::text FROM public.reprises_foyer
   WHERE household_id = 'b04fffff-0000-0000-0000-000000000002'
     AND statut = 'a_examiner'
), true);
UPDATE public.reprises_foyer
   SET examen_possible_le = pg_catalog.now() + interval '1 hour'
 WHERE id = current_setting('test.reprise_id')::uuid;
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000002"}}', true);
DO $non_admin_decision$
DECLARE v_denied boolean := false;
BEGIN
  BEGIN
    PERFORM public.decider_reprise_foyer(
      current_setting('test.reprise_id')::uuid,
      false,
      'b0400000-0000-0000-0000-000000000023'
    );
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-04: un guardian a pu decider une reprise';
  END IF;
END
$non_admin_decision$;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b04fffff-0000-0000-0000-000000000003"}}', true);
DO $early_admin_decision$
DECLARE v_row record; v_result jsonb;
BEGIN
  SELECT * INTO v_row FROM public.lister_reprises_admin()
   WHERE id = current_setting('test.reprise_id')::uuid;
  IF v_row.statut <> 'a_examiner' OR v_row.decidable THEN
    RAISE EXCEPTION 'B-04: une reprise avant echeance est decidable';
  END IF;
  v_result := public.decider_reprise_foyer(
    v_row.id, false, 'b0400000-0000-0000-0000-000000000023'
  );
  IF v_result->>'statut' <> 'deja_traitee'
     OR v_result->>'foyer_personnel_cree' <> 'false' THEN
    RAISE EXCEPTION 'B-04: decision admin acceptee avant examen_possible_le: %', v_result;
  END IF;
  SELECT * INTO v_row FROM public.lister_reprises_admin()
   WHERE id = current_setting('test.reprise_id')::uuid;
  IF v_row.statut <> 'a_examiner' OR v_row.decidable THEN
    RAISE EXCEPTION 'B-04: la tentative prematuree a modifie la reprise';
  END IF;
END
$early_admin_decision$;
RESET ROLE;
UPDATE public.reprises_foyer
   SET examen_possible_le = pg_catalog.now() - interval '1 second'
 WHERE id = current_setting('test.reprise_id')::uuid;
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b04fffff-0000-0000-0000-000000000003"}}', true);
DO $admin_refusal$
DECLARE v_row record; v_result jsonb;
BEGIN
  SELECT * INTO v_row FROM public.lister_reprises_admin()
  WHERE foyer_nom = 'Holder One';
  IF v_row.statut <> 'refusee_par_titulaire' OR v_row.decidable THEN
    RAISE EXCEPTION 'B-04: refus titulaire doit rester visible mais non decidable';
  END IF;
  v_result := public.decider_reprise_foyer(
    v_row.id, false, 'b0400000-0000-0000-0000-000000000013');
  IF v_result->>'statut' <> 'deja_traitee' THEN
    RAISE EXCEPTION 'B-04: une demande refusee par le titulaire ne peut plus etre decidee';
  END IF;
  SELECT * INTO v_row FROM public.lister_reprises_admin()
  WHERE foyer_nom = 'Holder Two';
  v_result := public.decider_reprise_foyer(
    v_row.id, false, 'b0400000-0000-0000-0000-000000000023');
  IF v_result->>'statut' <> 'decidee' OR v_result->>'foyer_personnel_cree' <> 'false' THEN
    RAISE EXCEPTION 'B-04: refus administratif incorrect: %', v_result;
  END IF;
END
$admin_refusal$;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000002"}}', true);
DO $redeposit_wait$
DECLARE v_denied boolean := false;
BEGIN
  BEGIN
    PERFORM public.deposer_reprise_foyer('b0400000-0000-0000-0000-000000000024');
  EXCEPTION WHEN insufficient_privilege THEN v_denied := true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'B-04: refus admin sans delai de redepot'; END IF;
END
$redeposit_wait$;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000007', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000004"}}', true);
SELECT public.deposer_reprise_foyer('b0400000-0000-0000-0000-000000000031');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b04fffff-0000-0000-0000-000000000003"}}', true);
DO $admin_approval$
DECLARE v_row record; v_first jsonb; v_retry jsonb;
BEGIN
  SELECT * INTO v_row FROM public.lister_reprises_admin()
  WHERE foyer_nom = 'Holder Three';
  IF v_row.demandeur_prenom <> 'Requester' THEN
    RAISE EXCEPTION 'B-04: seconde reprise absente de la file';
  END IF;
  v_first := public.decider_reprise_foyer(
    v_row.id, true, 'b0400000-0000-0000-0000-000000000022');
  v_retry := public.decider_reprise_foyer(
    v_row.id, true, 'b0400000-0000-0000-0000-000000000022');
  IF v_first->>'foyer_personnel_cree' <> 'true'
    OR v_retry->>'statut' <> 'deja_traitee'
    OR v_retry->>'foyer_personnel_cree' <> 'true'
    OR (SELECT count(*) FROM public.households
        WHERE primary_guardian_id = 'b0400000-0000-0000-0000-000000000007') <> 1 THEN
    RAISE EXCEPTION 'B-04: approbation ou idempotence incorrecte: %, %', v_first, v_retry;
  END IF;
END
$admin_approval$;

ROLLBACK;
