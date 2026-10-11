BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('6f000000-0000-4000-8000-000000000017', 'x2-17-accountant@example.invalid');
INSERT INTO public.households (id, timezone) VALUES
  ('6f000000-0000-4000-8000-000000000117', 'Europe/Paris');
INSERT INTO public.profiles (
  id, immutable_id, role, household_id, first_name, last_name, account_status
) VALUES (
  '6f000000-0000-4000-8000-000000000017', 'X2-17-ACC', 'accountant',
  '6f000000-0000-4000-8000-000000000117', 'Test', 'Comptable', 'active'
);

INSERT INTO public.tresorerie_mouvements (
  coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref,
  survenu_le, transfert_id, source_type, regle, source_id, motif, cree_par
) VALUES
  ('fonds_clients_engages', 'entree', 10000, 'USD', 10000, 'USD',
    (now() AT TIME ZONE 'Europe/Paris')::date::timestamp AT TIME ZONE 'Europe/Paris',
    NULL, 'encaissement', 'fixture', 'x2-17-in', NULL, '6f000000-0000-4000-8000-000000000017'),
  ('fonds_clients_engages', 'sortie', 2000, 'USD', 2000, 'USD',
    (now() AT TIME ZONE 'Europe/Paris')::date::timestamp AT TIME ZONE 'Europe/Paris',
    '6f000000-0000-4000-8000-000000000217', 'transfert_interne', 'fixture', 'x2-17-transfer-out', 'fixture',
    '6f000000-0000-4000-8000-000000000017'),
  ('tresorerie_libre', 'entree', 2000, 'USD', 2000, 'USD',
    (now() AT TIME ZONE 'Europe/Paris')::date::timestamp AT TIME ZONE 'Europe/Paris',
    '6f000000-0000-4000-8000-000000000217', 'transfert_interne', 'fixture', 'x2-17-transfer-in', 'fixture',
    '6f000000-0000-4000-8000-000000000017');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', '6f000000-0000-4000-8000-000000000017', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"accountant"}}', true);

DO $scenario$
DECLARE
  v_series jsonb := public.series_tresorerie();
  v_count integer;
  v_amount bigint;
BEGIN
  IF jsonb_array_length(v_series -> 'repartition') <> 7
     OR jsonb_array_length(v_series -> 'mensuel') <> 6
     OR jsonb_array_length(v_series -> 'flux30Jours') <> 30
     OR jsonb_array_length(v_series -> 'evolution') <> 6 THEN
    RAISE EXCEPTION 'X2-17: dimensions de series invalides';
  END IF;

  SELECT count(*) INTO v_count
    FROM jsonb_array_elements(v_series -> 'repartition') AS r
   WHERE r ->> 'coffre' = 'fonds_clients_engages';
  IF v_count <> 1 THEN RAISE EXCEPTION 'X2-17: coffre absent ou duplique'; END IF;

  SELECT (r -> 'montant' ->> 'mineur')::bigint INTO v_amount
    FROM jsonb_array_elements(v_series -> 'repartition') AS r
   WHERE r ->> 'coffre' = 'fonds_clients_engages';
  IF v_amount <> 8000 THEN
    RAISE EXCEPTION 'X2-17: le transfert doit compter dans le solde, obtenu %', v_amount;
  END IF;

  IF (v_series ->> 'variationEntreesPourMille') IS NOT NULL
     OR (v_series ->> 'variationSortiesPourMille') IS NOT NULL THEN
    RAISE EXCEPTION 'X2-17: une periode precedente vide doit rendre NULL';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(v_series -> 'flux30Jours') AS d
     WHERE (d -> 'encaissements' ->> 'mineur')::bigint = 10000
  ) THEN
    RAISE EXCEPTION 'X2-17: les transferts doivent etre exclus des flux';
  END IF;

  IF has_function_privilege('anon', 'public.series_tresorerie()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.series_tresorerie()', 'EXECUTE') THEN
    RAISE EXCEPTION 'X2-17: ACL inattendue pour anon/service_role';
  END IF;
END;
$scenario$;

SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
DO $negative$
BEGIN
  PERFORM public.series_tresorerie();
  RAISE EXCEPTION 'X2-17: teacher unexpectedly allowed';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$negative$;

RESET ROLE;
ROLLBACK;
