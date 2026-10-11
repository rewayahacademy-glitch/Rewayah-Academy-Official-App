BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('6f000000-0000-4000-8000-000000000018', 'x2-18-accountant@example.invalid');
INSERT INTO public.households (id, timezone) VALUES
  ('6f000000-0000-4000-8000-000000000118', 'Europe/Paris');
INSERT INTO public.profiles (
  id, immutable_id, role, household_id, first_name, last_name, account_status
) VALUES (
  '6f000000-0000-4000-8000-000000000018', 'X2-18-ACC', 'accountant',
  '6f000000-0000-4000-8000-000000000118', 'Test', 'Comptable', 'active'
);
INSERT INTO public.wallets (id, household_id, currency) VALUES
  ('6f000000-0000-4000-8000-000000000218',
   '6f000000-0000-4000-8000-000000000118', 'USD');
INSERT INTO public.payout_methods (id, profile_id, kind, details) VALUES
  ('6f000000-0000-4000-8000-000000000318',
   '6f000000-0000-4000-8000-000000000018', 'mobile_money',
   '{"private":"SENSITIVE_PAYOUT_METHOD_DETAILS"}'::jsonb);
INSERT INTO public.payouts (id, wallet_id, payout_method_id, amount_minor, status) VALUES
  ('6f000000-0000-4000-8000-000000000418',
   '6f000000-0000-4000-8000-000000000218',
   '6f000000-0000-4000-8000-000000000318', 1234, 'requested');
INSERT INTO public.tresorerie_mouvements (
  coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref,
  survenu_le, source_type, regle, source_id, note
) VALUES (
  'fonds_clients_engages', 'entree', 500, 'USD', 500, 'USD', now(),
  'encaissement', 'x2-18-fixture', 'x2-18-report', '=SUM(1;1)'
);

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', '6f000000-0000-4000-8000-000000000018', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"accountant"}}', true);

DO $direct_write$
BEGIN
  INSERT INTO public.exports_comptables (
    reference, perimetre, periode_debut, periode_fin, nb_lignes, csv, cree_par, cle_idempotence
  ) VALUES (
    'FORGE-1', 'rapport', current_date, current_date, 999,
    'faux;chiffres', auth.uid(), 'x2-18-forge'
  );
  RAISE EXCEPTION 'X2-18: comptable unexpectedly forged export journal row';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$direct_write$;

DO $scenario$
DECLARE
  v_report jsonb;
  v_repeat jsonb;
  v_selection jsonb;
  v_selection_repeat jsonb;
  v_report_csv text;
  v_selection_csv text;
  v_ref text;
  v_count integer;
  v_ids uuid[];
BEGIN
  v_report := public.exporter_rapport_comptable('x2-18-report-key');
  v_repeat := public.exporter_rapport_comptable('x2-18-report-key');
  IF v_report ->> 'reference' IS DISTINCT FROM v_repeat ->> 'reference'
     OR (v_report ->> 'lignes')::integer <> 1 THEN
    RAISE EXCEPTION 'X2-18: rapport ou idempotence invalide';
  END IF;
  v_ref := v_report ->> 'reference';
  IF v_ref !~ '^EXP-[0-9]{8}-[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'X2-18: référence invalide: %', v_ref;
  END IF;
  SELECT csv INTO v_report_csv FROM public.exports_comptables WHERE reference = v_ref;
  IF left(v_report_csv, 1) <> chr(65279)
     OR position('date;coffre;sens;montant;montant_mineur;devise;' IN v_report_csv) <> 2
     OR position('''=SUM(1;1)' IN v_report_csv) = 0 THEN
    RAISE EXCEPTION 'X2-18: BOM, en-tête ou protection de formule absente';
  END IF;
  SELECT count(*) INTO v_count FROM public.exports_comptables
   WHERE cree_par = auth.uid() AND cle_idempotence = 'x2-18-report-key';
  IF v_count <> 1 THEN RAISE EXCEPTION 'X2-18: idempotence a dupliqué le journal'; END IF;

  v_selection := public.exporter_selection_comptable(
    ARRAY['6f000000-0000-4000-8000-000000000418'::uuid], 'x2-18-selection-key'
  );
  v_selection_repeat := public.exporter_selection_comptable(
    ARRAY['6f000000-0000-4000-8000-000000000418'::uuid], 'x2-18-selection-key'
  );
  IF (v_selection ->> 'lignes')::integer <> 1 THEN
    RAISE EXCEPTION 'X2-18: export de sélection invalide';
  END IF;
  IF v_selection ->> 'reference' IS DISTINCT FROM v_selection_repeat ->> 'reference' THEN
    RAISE EXCEPTION 'X2-18: idempotence de sélection invalide';
  END IF;
  SELECT csv INTO v_selection_csv FROM public.exports_comptables
   WHERE reference = v_selection ->> 'reference';
  IF position('paiement_id;cree_le;statut;montant;montant_mineur;devise;' IN v_selection_csv) <> 2
     OR position('mobile_money' IN v_selection_csv) = 0
     OR position('"12.34";"1234";"USD"' IN v_selection_csv) = 0
     OR position('SENSITIVE_PAYOUT_METHOD_DETAILS' IN v_selection_csv) <> 0 THEN
    RAISE EXCEPTION 'X2-18: colonnes de sélection invalides ou details divulgués';
  END IF;

  BEGIN
    PERFORM public.exporter_selection_comptable(ARRAY[]::uuid[], 'x2-18-empty');
    RAISE EXCEPTION 'X2-18: sélection vide acceptée';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;
  SELECT array_agg(gen_random_uuid()) INTO v_ids FROM generate_series(1, 501);
  BEGIN
    PERFORM public.exporter_selection_comptable(v_ids, 'x2-18-too-many-ids');
    RAISE EXCEPTION 'X2-18: sélection de plus de 500 ids acceptée';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;
  BEGIN
    PERFORM public.exporter_selection_comptable(
      ARRAY['6f000000-0000-4000-8000-000000000999'::uuid], 'x2-18-foreign'
    );
    RAISE EXCEPTION 'X2-18: paiement inconnu accepté';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;

  IF has_function_privilege('anon', 'public.exporter_rapport_comptable(text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.exporter_selection_comptable(uuid[],text)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.exporter_rapport_comptable(text)', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.exporter_selection_comptable(uuid[],text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'codex2_private.creer_export_comptable(text,uuid[],text)', 'EXECUTE')
     OR has_function_privilege('anon', 'codex2_private.creer_export_comptable(text,uuid[],text)', 'EXECUTE')
     OR has_function_privilege('service_role', 'codex2_private.creer_export_comptable(text,uuid[],text)', 'EXECUTE')
     OR has_table_privilege('service_role', 'public.exports_comptables', 'SELECT')
     OR has_table_privilege('service_role', 'public.exports_comptables', 'INSERT') THEN
    RAISE EXCEPTION 'X2-18: ACL anon/service_role inattendue';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'codex2_private'
      AND p.proname = 'creer_export_comptable'
      AND p.prosecdef
      AND p.proconfig @> ARRAY['search_path=""']
  ) THEN
    RAISE EXCEPTION 'X2-18: helper privé absent ou non conforme F86';
  END IF;
END;
$scenario$;

SELECT md5(pg_catalog.pg_get_functiondef(
  'codex2_private.creer_export_comptable(text,uuid[],text)'::regprocedure
)) AS x2_18_helper_definer_md5;

RESET ROLE;
INSERT INTO public.tresorerie_mouvements (
  coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref,
  survenu_le, source_type, regle, source_id
)
SELECT 'fonds_clients_engages', 'entree', 1, 'USD', 1, 'USD', now(),
       'encaissement', 'x2-18-cap', 'x2-18-cap-' || n::text
  FROM generate_series(1, 5001) AS gs(n);

SET LOCAL ROLE authenticated;
SELECT set_config('test.jwt', '{"app_metadata":{"role":"accountant"}}', true);
DO $cap$
DECLARE
  v_count integer;
BEGIN
  BEGIN
    PERFORM public.exporter_rapport_comptable('x2-18-cap-key');
    RAISE EXCEPTION 'X2-18: plafond de 5000 lignes non appliqué';
  EXCEPTION WHEN SQLSTATE '54000' THEN NULL;
  END;
  SELECT count(*) INTO v_count FROM public.exports_comptables
   WHERE cree_par = auth.uid() AND cle_idempotence = 'x2-18-cap-key';
  IF v_count <> 0 THEN RAISE EXCEPTION 'X2-18: export trop volumineux journalisé'; END IF;
END;
$cap$;

ROLLBACK;
