-- B-04 : controle negatif/positif des reprises et de l'idempotence.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('b0400000-0000-0000-0000-000000000001', 'b04-admin@example.test'),
  ('b0400000-0000-0000-0000-000000000002', 'b04-holder-a@example.test'),
  ('b0400000-0000-0000-0000-000000000003', 'b04-requester-a@example.test'),
  ('b0400000-0000-0000-0000-000000000004', 'b04-holder-b@example.test'),
  ('b0400000-0000-0000-0000-000000000005', 'b04-requester-b@example.test');

INSERT INTO public.households (id) VALUES
  ('b04fffff-0000-0000-0000-000000000001'),
  ('b04fffff-0000-0000-0000-000000000002'),
  ('b04fffff-0000-0000-0000-000000000003');
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
   'b04fffff-0000-0000-0000-000000000002', 'Requester', 'Two', 'active', 'female');
UPDATE public.households SET primary_guardian_id = 'b0400000-0000-0000-0000-000000000002'
WHERE id = 'b04fffff-0000-0000-0000-000000000001';
UPDATE public.households SET primary_guardian_id = 'b0400000-0000-0000-0000-000000000004'
WHERE id = 'b04fffff-0000-0000-0000-000000000002';

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

SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000002', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000001"}}', true);
DO $holder_refusal$
BEGIN
  IF public.etat_reprise_foyer()->>'type' <> 'titulaire'
    OR public.refuser_reprise_foyer('b0400000-0000-0000-0000-000000000012')->>'statut' <> 'enregistree'
    OR public.etat_reprise_foyer()->>'statut' <> 'refusee_par_vous' THEN
    RAISE EXCEPTION 'B-04: refus du titulaire non reflechi';
  END IF;
END
$holder_refusal$;

SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b04fffff-0000-0000-0000-000000000003"}}', true);
DO $admin_refusal$
DECLARE v_row record; v_result jsonb;
BEGIN
  SELECT * INTO v_row FROM public.lister_reprises_admin();
  IF v_row.statut <> 'refusee_par_titulaire' OR NOT v_row.decidable THEN
    RAISE EXCEPTION 'B-04: reprise refusee non visible ou non decidable';
  END IF;
  v_result := public.decider_reprise_foyer(
    v_row.id, false, 'b0400000-0000-0000-0000-000000000013');
  IF v_result->>'statut' <> 'decidee' OR v_result->>'foyer_personnel_cree' <> 'false' THEN
    RAISE EXCEPTION 'B-04: refus administratif incorrect: %', v_result;
  END IF;
END
$admin_refusal$;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b04fffff-0000-0000-0000-000000000002"}}', true);
SELECT public.deposer_reprise_foyer('b0400000-0000-0000-0000-000000000021');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'b0400000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b04fffff-0000-0000-0000-000000000003"}}', true);
DO $admin_approval$
DECLARE v_row record; v_first jsonb; v_retry jsonb;
BEGIN
  SELECT * INTO v_row FROM public.lister_reprises_admin();
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
        WHERE primary_guardian_id = 'b0400000-0000-0000-0000-000000000005') <> 1 THEN
    RAISE EXCEPTION 'B-04: approbation ou idempotence incorrecte: %, %', v_first, v_retry;
  END IF;
END
$admin_approval$;

ROLLBACK;
