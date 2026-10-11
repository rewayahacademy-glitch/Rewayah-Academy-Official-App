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
INSERT INTO auth.users (id, email) VALUES
  ('6f000000-0000-4000-8000-000000000018', 'x2-17-admin@example.invalid'),
  ('6f000000-0000-4000-8000-000000000019', 'x2-17-teacher@example.invalid');
INSERT INTO public.households (id, timezone) VALUES
  ('6f000000-0000-4000-8000-000000000118', 'Europe/Paris'),
  ('6f000000-0000-4000-8000-000000000119', 'Europe/Paris');
INSERT INTO public.profiles (
  id, immutable_id, role, household_id, first_name, last_name, account_status
) VALUES
  ('6f000000-0000-4000-8000-000000000018', 'X2-17-ADMIN', 'admin',
    '6f000000-0000-4000-8000-000000000118', 'Test', 'Direction', 'active'),
  ('6f000000-0000-4000-8000-000000000019', 'X2-17-TEACH', 'teacher',
    '6f000000-0000-4000-8000-000000000119', 'Test', 'Enseignant', 'active');

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
     OR has_function_privilege('service_role', 'public.series_tresorerie()', 'EXECUTE')
     OR has_table_privilege('service_role', 'public.tresorerie_mouvements', 'SELECT')
     OR has_table_privilege('service_role', 'public.tresorerie_mouvements', 'INSERT') THEN
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

SELECT set_config('test.uid', '6f000000-0000-4000-8000-000000000018', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"},"aal":"aal1"}', true);
DO $negative_aal$
BEGIN
  INSERT INTO public.regles_remuneration_enseignant (
    taux_minor_par_heure, devise, date_effet, motif
  ) VALUES (0, 'USD', current_date, 'X2-17: aal1 doit etre refuse');
  RAISE EXCEPTION 'X2-17: admin aal1 unexpectedly inserted a remuneration rule';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$negative_aal$;

SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"},"aal":"aal2"}', true);
DO $negative_scope$
BEGIN
  INSERT INTO public.regles_remuneration_enseignant (
    enseignant_id, taux_minor_par_heure, devise, date_effet, motif
  ) VALUES (
    '6f000000-0000-4000-8000-000000000018', 0, 'USD', current_date,
    'X2-17: un profil admin ne peut pas etre enseignant'
  );
  RAISE EXCEPTION 'X2-17: non-teacher remuneration scope unexpectedly accepted';
EXCEPTION WHEN check_violation THEN NULL;
END;
$negative_scope$;

INSERT INTO public.regles_remuneration_enseignant (
  enseignant_id, taux_minor_par_heure, devise, date_effet, motif
) VALUES (
  '6f000000-0000-4000-8000-000000000019', 0, 'USD', current_date,
  'X2-17: regle de fixture sans taux impose'
);
DO $append_only$
BEGIN
  UPDATE public.regles_remuneration_enseignant
     SET motif = 'modifie' WHERE enseignant_id = '6f000000-0000-4000-8000-000000000019';
  RAISE EXCEPTION 'X2-17: remuneration rule unexpectedly updated';
EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
END;
$append_only$;
DO $append_only_delete$
BEGIN
  DELETE FROM public.regles_remuneration_enseignant
   WHERE enseignant_id = '6f000000-0000-4000-8000-000000000019';
  RAISE EXCEPTION 'X2-17: remuneration rule unexpectedly deleted';
EXCEPTION WHEN object_not_in_prerequisite_state THEN NULL;
END;
$append_only_delete$;

RESET ROLE;
DO $audit$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.audit_logs
     WHERE action = 'regle_remuneration_creee'
       AND table_name = 'regles_remuneration_enseignant'
  ) THEN
    RAISE EXCEPTION 'X2-17: insertion de regle non auditee';
  END IF;
END;
$audit$;
ROLLBACK;
