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
INSERT INTO auth.users (id,email) VALUES
  ('6f000000-0000-4000-8000-000000000020','x2-17-teacher-no-rule@example.invalid'),
  ('6f000000-0000-4000-8000-000000000021','x2-17-teacher-policy@example.invalid');
INSERT INTO public.households(id,timezone) VALUES
  ('6f000000-0000-4000-8000-000000000120','Europe/Paris'),
  ('6f000000-0000-4000-8000-000000000121','Europe/Paris'),
  ('6f000000-0000-4000-8000-000000000122','Europe/Paris');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status) VALUES
  ('6f000000-0000-4000-8000-000000000020','X2-17-TEACH-NORULE','teacher',
    '6f000000-0000-4000-8000-000000000120','Test','Sans règle','active'),
  ('6f000000-0000-4000-8000-000000000021','X2-17-TEACH-POLICY','teacher',
    '6f000000-0000-4000-8000-000000000121','Test','Avec règle','active');
INSERT INTO public.wallets(id,household_id,currency) VALUES
  ('6f000000-0000-4000-8000-000000000317','6f000000-0000-4000-8000-000000000118','USD');
INSERT INTO public.wallets(id,household_id,currency) VALUES
  ('6f000000-0000-4000-8000-000000000318','6f000000-0000-4000-8000-000000000122','EUR');

DO $payment_events$
DECLARE v_credit bigint; v_refund bigint; v_movement_count integer; v_denied boolean:=false;
BEGIN
  INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type,confirme_par_prestataire_le)
  VALUES('6f000000-0000-4000-8000-000000000317',10000,'USD','credit',clock_timestamp()) RETURNING id INTO v_credit;
  INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type,refund_of_entry_id)
  VALUES('6f000000-0000-4000-8000-000000000317',1000,'USD','refund',v_credit) RETURNING id INTO v_refund;
  UPDATE public.wallet_entries SET confirme_par_prestataire_le=clock_timestamp() WHERE id=v_refund;
  UPDATE public.wallet_entries SET confirme_par_prestataire_le=confirme_par_prestataire_le WHERE id=v_credit;
  SELECT count(*) INTO v_movement_count FROM public.tresorerie_mouvements
   WHERE source_type='encaissement' AND source_id=v_credit::text;
  IF v_movement_count<>1 THEN RAISE EXCEPTION 'X2-17: confirmation paiement non idempotente'; END IF;
  SELECT count(*) INTO v_movement_count FROM public.tresorerie_mouvements
   WHERE source_type='remboursement' AND source_id=v_refund::text AND sens='sortie';
  IF v_movement_count<>1 THEN RAISE EXCEPTION 'X2-17: remboursement confirmé non enregistré en sortie'; END IF;
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid','6f000000-0000-4000-8000-000000000018',true);
  PERFORM set_config('test.jwt','{"app_metadata":{"role":"admin"},"aal":"aal2"}',true);
  BEGIN
    UPDATE public.wallet_entries SET confirme_par_prestataire_le=clock_timestamp()+interval '1 second'
     WHERE id=v_credit;
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'X2-17: admin a fabriqué une confirmation prestataire'; END IF;
  RESET ROLE;
END;
$payment_events$;

INSERT INTO public.payout_methods(id,profile_id,kind,details)
VALUES('6f000000-0000-4000-8000-000000000317','6f000000-0000-4000-8000-000000000019','bank_transfer','{}');
INSERT INTO public.payouts(id,wallet_id,payout_method_id,amount_minor,status)
VALUES('6f000000-0000-4000-8000-000000000217','6f000000-0000-4000-8000-000000000317',
  '6f000000-0000-4000-8000-000000000317',500,'requested');
UPDATE public.payouts SET status='failed' WHERE id='6f000000-0000-4000-8000-000000000217';
DO $payout_events$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.tresorerie_mouvements
   WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000217';
  IF v_count<>4 THEN RAISE EXCEPTION 'X2-17: demande et retour de payout non journalisés'; END IF;
END;
$payout_events$;

INSERT INTO public.payouts(id,wallet_id,payout_method_id,amount_minor,status)
VALUES
 ('6f000000-0000-4000-8000-000000000218','6f000000-0000-4000-8000-000000000318',
  '6f000000-0000-4000-8000-000000000317',500,'requested'),
 ('6f000000-0000-4000-8000-000000000219','6f000000-0000-4000-8000-000000000317',
  '6f000000-0000-4000-8000-000000000317',0,'requested'),
 ('6f000000-0000-4000-8000-000000000220','6f000000-0000-4000-8000-000000000317',
  '6f000000-0000-4000-8000-000000000317',0,'requested');
DO $payout_pending$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
      WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000218'
        AND raison='taux_change_absent' AND traite_le IS NULL)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
      WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000219'
        AND raison='montant_invalide' AND traite_le IS NULL)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
      WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000220'
        AND raison='montant_invalide' AND traite_le IS NULL) THEN
    RAISE EXCEPTION 'X2-17: motifs payout FX/montant non mis en reprise';
  END IF;
END;
$payout_pending$;

INSERT INTO public.sessions(id,teacher_id,started_at,ended_at,status,session_type)
VALUES
 ('6f000000-0000-4000-8000-000000000117','6f000000-0000-4000-8000-000000000021',now()-interval '6 hours',now()-interval '5 hours','planned','standard'),
 ('6f000000-0000-4000-8000-000000000118','6f000000-0000-4000-8000-000000000020',now()-interval '2 hours',now()+interval '1 hour','planned','standard'),
 ('6f000000-0000-4000-8000-000000000119','6f000000-0000-4000-8000-000000000021',now()+interval '3 hours',now()+interval '4 hours','planned','standard'),
 ('6f000000-0000-4000-8000-000000000120','6f000000-0000-4000-8000-000000000020',now()+interval '5 hours',now()+interval '6 hours','planned','standard'),
 ('6f000000-0000-4000-8000-000000000121','6f000000-0000-4000-8000-000000000021',now()+interval '7 hours',now()+interval '8 hours','planned','standard');
INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type,reference_id)
VALUES
 ('6f000000-0000-4000-8000-000000000317',10000,'USD','debit','6f000000-0000-4000-8000-000000000117'),
 ('6f000000-0000-4000-8000-000000000317',10000,'USD','debit','6f000000-0000-4000-8000-000000000118'),
 ('6f000000-0000-4000-8000-000000000317',10000,'USD','debit','6f000000-0000-4000-8000-000000000119'),
 ('6f000000-0000-4000-8000-000000000318',10000,'EUR','debit','6f000000-0000-4000-8000-000000000120'),
 ('6f000000-0000-4000-8000-000000000317',1,'USD','debit','6f000000-0000-4000-8000-000000000121');

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
  IF v_amount <> 17000 THEN
    RAISE EXCEPTION 'X2-17: solde initial et mouvements confirmes doivent compter, obtenu %', v_amount;
  END IF;

  IF (v_series ->> 'variationEntreesPourMille') IS NOT NULL
     OR (v_series ->> 'variationSortiesPourMille') IS NOT NULL THEN
    RAISE EXCEPTION 'X2-17: une periode precedente vide doit rendre NULL';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(v_series -> 'flux30Jours') AS d
     WHERE (d -> 'encaissements' ->> 'mineur')::bigint = 20000
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
EXCEPTION WHEN object_not_in_prerequisite_state OR insufficient_privilege THEN NULL;
END;
$append_only$;
DO $append_only_delete$
BEGIN
  DELETE FROM public.regles_remuneration_enseignant
   WHERE enseignant_id = '6f000000-0000-4000-8000-000000000019';
  RAISE EXCEPTION 'X2-17: remuneration rule unexpectedly deleted';
EXCEPTION WHEN object_not_in_prerequisite_state OR insufficient_privilege THEN NULL;
END;
$append_only_delete$;

RESET ROLE;
UPDATE public.sessions SET status='preflight' WHERE id='6f000000-0000-4000-8000-000000000118';
UPDATE public.sessions SET status='in_progress' WHERE id='6f000000-0000-4000-8000-000000000118';
UPDATE public.sessions SET status='ended' WHERE id='6f000000-0000-4000-8000-000000000118';

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid','6f000000-0000-4000-8000-000000000018',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"},"aal":"aal2"}',true);
INSERT INTO public.regles_remuneration_enseignant(
  enseignant_id,taux_minor_par_heure,devise,date_effet,motif,cree_par
) VALUES (NULL,18000,'USD',current_date,'X2-17 règle globale de test','6f000000-0000-4000-8000-000000000018');
INSERT INTO public.regles_remuneration_enseignant(
  enseignant_id,taux_minor_par_heure,devise,date_effet,motif,cree_par
) VALUES ('6f000000-0000-4000-8000-000000000020',18000,'EUR',current_date,
  'X2-17 EUR FX missing fixture','6f000000-0000-4000-8000-000000000018');
RESET ROLE;

UPDATE public.sessions SET status='preflight' WHERE id='6f000000-0000-4000-8000-000000000117';
UPDATE public.sessions SET status='in_progress' WHERE id='6f000000-0000-4000-8000-000000000117';
SELECT pg_sleep(1);
UPDATE public.sessions SET status='ended' WHERE id='6f000000-0000-4000-8000-000000000117';
UPDATE public.sessions SET status='preflight' WHERE id='6f000000-0000-4000-8000-000000000119';
UPDATE public.sessions SET status='in_progress' WHERE id='6f000000-0000-4000-8000-000000000119';
UPDATE public.sessions SET status='tech_failure' WHERE id='6f000000-0000-4000-8000-000000000119';
UPDATE public.sessions SET status='preflight' WHERE id='6f000000-0000-4000-8000-000000000120';
UPDATE public.sessions SET status='in_progress' WHERE id='6f000000-0000-4000-8000-000000000120';
SELECT pg_sleep(1);
UPDATE public.sessions SET status='ended' WHERE id='6f000000-0000-4000-8000-000000000120';
UPDATE public.sessions SET status='preflight' WHERE id='6f000000-0000-4000-8000-000000000121';
UPDATE public.sessions SET status='in_progress' WHERE id='6f000000-0000-4000-8000-000000000121';
SELECT pg_sleep(1);
UPDATE public.sessions SET status='ended' WHERE id='6f000000-0000-4000-8000-000000000121';

DO $session_finance$
DECLARE v_due bigint;
BEGIN
  SELECT count(*) INTO v_due FROM public.tresorerie_mouvements
   WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000117'
     AND regle='remuneration_due';
  IF v_due<>0 THEN RAISE EXCEPTION 'X2-17: une seance sans politique ne doit pas produire de mouvements'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
    WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000118'
      AND raison='regle_remuneration_absente') THEN
    RAISE EXCEPTION 'X2-17: absence de regle non mise en reprise';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
    WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000119'
      AND raison='duree_indeterminee') THEN
    RAISE EXCEPTION 'X2-17: duree interrompue non mise en reprise';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
    WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000117'
      AND raison='politique_allocation_absente') THEN
    RAISE EXCEPTION 'X2-17: absence de politique non signalée';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tresorerie_mouvements WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000117') THEN
    RAISE EXCEPTION 'X2-17: mouvements generes sans politique allocation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
      WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000120'
        AND raison='taux_change_absent' AND traite_le IS NULL) THEN
    RAISE EXCEPTION 'X2-17: taux FX absent de prestation non mis en reprise';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
      WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000121'
        AND raison='montant_invalide' AND traite_le IS NULL) THEN
    RAISE EXCEPTION 'X2-17: montant prestation invalide non mis en reprise';
  END IF;
END;
$session_finance$;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid','6f000000-0000-4000-8000-000000000018',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"},"aal":"aal2"}',true);
INSERT INTO public.politique_allocation_coffres(
  date_effet,taux_taxes_permille,taux_charges_permille,taux_reserve_permille,cree_par
) VALUES(current_date,100,100,100,'6f000000-0000-4000-8000-000000000018');
RESET ROLE;
INSERT INTO public.fx_rates(from_currency,to_currency,rate,effective_at)
VALUES ('EUR','USD',1.1,now()-interval '1 hour');
INSERT INTO public.wallet_entries(wallet_id,amount_minor,currency,reference_type,reference_id)
VALUES ('6f000000-0000-4000-8000-000000000317',10000,'USD','debit','6f000000-0000-4000-8000-000000000121');
UPDATE public.payouts SET amount_minor=500 WHERE id='6f000000-0000-4000-8000-000000000219';
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid','6f000000-0000-4000-8000-000000000018',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"},"aal":"aal2"}',true);
DO $resume$
DECLARE v_processed integer; v_pending bigint; v_abandon bigint;
BEGIN
  SELECT id INTO v_pending FROM public.tresorerie_a_reprendre
   WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000119'
     AND raison='duree_indeterminee';
  PERFORM public.decider_tresorerie_montant(v_pending,500,'USD');
  SELECT id INTO v_abandon FROM public.tresorerie_a_reprendre
   WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000220'
     AND raison='montant_invalide';
  PERFORM public.abandonner_reprise_tresorerie(v_abandon,'Montant refuse apres examen');
  v_processed:=public.reprendre_alimentation_tresorerie();
  IF v_processed<1 THEN RAISE EXCEPTION 'X2-17: reprise admin non appliquée'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements
      WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000119'
        AND coffre='paie_a_decaisser' AND sens='entree' AND montant_minor=500)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements
      WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000119'
        AND coffre='charges_essentielles' AND montant_minor=950)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements
      WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000119'
        AND coffre='reserve_strategique' AND montant_minor=950) THEN
    RAISE EXCEPTION 'X2-17: politique des coffres non appliquée à la reprise';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000218' AND traite_le IS NOT NULL)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000218')
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000219' AND traite_le IS NOT NULL)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000219')
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000120' AND traite_le IS NOT NULL)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000120')
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000121' AND traite_le IS NOT NULL)
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements WHERE source_type='prestation' AND source_id='6f000000-0000-4000-8000-000000000121')
     OR NOT EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre WHERE source_type='payout' AND source_id='6f000000-0000-4000-8000-000000000220' AND traite_le IS NOT NULL AND abandon_motif='Montant refuse apres examen')
     OR NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action='tresorerie_reprise_abandonnee' AND row_id=v_abandon::text) THEN
    RAISE EXCEPTION 'X2-17: reprise FX/montant ou abandon non audite';
  END IF;
END;
$resume$;
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
