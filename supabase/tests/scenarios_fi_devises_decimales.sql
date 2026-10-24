-- FI-DEV-1 (21/10/2026, lot gnf de CAND-Q15) : la reference USD de la
-- tresorerie lit les decimales de la devise dans la table ISO 4217 complete
-- (`private.devise_decimales`, migration 20261021210300).
--
-- Avant le correctif, `public.x217_montant_ref` donnait 2 decimales au GNF et
-- au KRW (0 selon ISO 4217), 2 aux devises a 3 et 4 decimales hors de sa
-- liste (IQD, JOD, LYD, CLF, UYW) : le premier controle echoue alors
-- (150 au lieu de 15 000).
--
-- Sur une base neuve, sous postgres, entre BEGIN et ROLLBACK :
--   psql -f supabase/tests/stub_auth.sql ; toutes les migrations dans l'ordre ;
--   psql -f supabase/tests/scenarios_fi_devises_decimales.sql
-- ou `tool/rejouer_scenarios.sh fi_devises`.
BEGIN;

-- Taux de change vers l'USD. Le GNF a deux taux dates : 0,0001 au 1er janvier
-- (calcul rond), puis le taux de la demonstration (1 USD = 8 600 GNF,
-- lib/features/demo/paiements_demo.dart) a partir du 1er juin.
INSERT INTO public.fx_rates(from_currency, to_currency, rate, effective_at) VALUES
  ('GNF', 'USD', 0.0001, '2026-01-01 00:00:00+00'),
  ('GNF', 'USD', 1::numeric / 8600, '2026-06-01 00:00:00+00'),
  ('KRW', 'USD', 0.00075, '2026-01-01 00:00:00+00'),
  ('KMF', 'USD', 0.0022, '2026-01-01 00:00:00+00'),
  ('KWD', 'USD', 3.25, '2026-01-01 00:00:00+00'),
  ('JOD', 'USD', 1.41, '2026-01-01 00:00:00+00'),
  ('CLF', 'USD', 40, '2026-01-01 00:00:00+00'),
  ('EUR', 'USD', 1.1, '2026-01-01 00:00:00+00');

-- A. La conversion seule.
DO $fi_dev_conversion$
DECLARE
  v_mars timestamptz := '2026-03-01 00:00:00+00';
  v_obtenu bigint;
BEGIN
  v_obtenu := public.x217_montant_ref(1500000, 'GNF', v_mars);
  IF v_obtenu IS DISTINCT FROM 15000 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A1 : 1 500 000 GNF a 0,0001 doivent valoir 15000 (150,00 $), obtenu %', v_obtenu;
  END IF;
  v_obtenu := public.x217_montant_ref(5000, 'GNF', v_mars);
  IF v_obtenu IS DISTINCT FROM 50 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A2 : 5 000 GNF doivent valoir 50 (0,50 $), obtenu %', v_obtenu;
  END IF;
  -- Le taux de la demonstration : 1 823 200 GNF valent 212,00 $, pas 2,12 $.
  v_obtenu := public.x217_montant_ref(1823200, 'GNF', now());
  IF v_obtenu IS DISTINCT FROM 21200 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A3 : 1 823 200 GNF a 1/8600 doivent valoir 21200 (212,00 $), obtenu %', v_obtenu;
  END IF;
  -- 4 000 GNF ne s'arrondissent plus a 0 : 46,51 cents, soit 47.
  v_obtenu := public.x217_montant_ref(4000, 'GNF', now());
  IF v_obtenu IS DISTINCT FROM 47 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A4 : 4 000 GNF a 1/8600 doivent valoir 47, obtenu %', v_obtenu;
  END IF;
  v_obtenu := public.x217_montant_ref(100000, 'KRW', v_mars);
  IF v_obtenu IS DISTINCT FROM 7500 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A5 : 100 000 KRW doivent valoir 7500 (75,00 $), obtenu %', v_obtenu;
  END IF;
  v_obtenu := public.x217_montant_ref(1000, 'KMF', v_mars);
  IF v_obtenu IS DISTINCT FROM 220 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A6 : 1 000 KMF doivent valoir 220 (2,20 $), obtenu %', v_obtenu;
  END IF;
  -- 1000 unites mineures de KWD = 1,000 KWD.
  v_obtenu := public.x217_montant_ref(1000, 'KWD', v_mars);
  IF v_obtenu IS DISTINCT FROM 325 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A7 : 1,000 KWD doit valoir 325 (3,25 $), obtenu %', v_obtenu;
  END IF;
  v_obtenu := public.x217_montant_ref(1000, 'JOD', v_mars);
  IF v_obtenu IS DISTINCT FROM 141 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A8 : 1,000 JOD doit valoir 141 (1,41 $), obtenu %', v_obtenu;
  END IF;
  -- 12345 unites mineures de CLF = 1,2345 CLF.
  v_obtenu := public.x217_montant_ref(12345, 'CLF', v_mars);
  IF v_obtenu IS DISTINCT FROM 4938 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A9 : 1,2345 CLF doit valoir 4938 (49,38 $), obtenu %', v_obtenu;
  END IF;
  v_obtenu := public.x217_montant_ref(10000, 'EUR', v_mars);
  IF v_obtenu IS DISTINCT FROM 11000 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A10 : 100,00 EUR doivent valoir 11000, obtenu %', v_obtenu;
  END IF;
  v_obtenu := public.x217_montant_ref(5000, 'USD', v_mars);
  IF v_obtenu IS DISTINCT FROM 5000 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A11 : l''USD passe tel quel, obtenu %', v_obtenu;
  END IF;
  IF public.x217_montant_ref(1000, 'XOF', v_mars) IS NOT NULL THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A12 : sans taux XOF, la reference doit etre NULL';
  END IF;
  -- Avant la date d'effet du premier taux, pas de reference.
  IF public.x217_montant_ref(1500000, 'GNF', '2025-12-31 00:00:00+00') IS NOT NULL THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE A13 : avant le premier taux GNF, la reference doit etre NULL';
  END IF;
  RAISE NOTICE 'FI-DEV-1 OK A : GNF, KRW, KMF, KWD, JOD, CLF, EUR, USD convertis selon ISO 4217';
END;
$fi_dev_conversion$;

-- B. La table : chaque classe ISO 4217 et le defaut.
DO $fi_dev_table$
DECLARE
  v_ligne record;
BEGIN
  FOR v_ligne IN
    SELECT d.code, d.decimales FROM (VALUES
      ('BIF', 0), ('CLP', 0), ('DJF', 0), ('GNF', 0), ('ISK', 0), ('JPY', 0),
      ('KMF', 0), ('KRW', 0), ('PYG', 0), ('RWF', 0), ('UGX', 0), ('UYI', 0),
      ('VND', 0), ('VUV', 0), ('XAF', 0), ('XOF', 0), ('XPF', 0),
      ('BHD', 3), ('IQD', 3), ('JOD', 3), ('KWD', 3), ('LYD', 3), ('OMR', 3),
      ('TND', 3),
      ('CLF', 4), ('UYW', 4),
      ('USD', 2), ('EUR', 2), ('GBP', 2), ('CAD', 2), ('XTS', 2)
    ) AS d(code, decimales)
  LOOP
    IF private.devise_decimales(v_ligne.code) IS DISTINCT FROM v_ligne.decimales THEN
      RAISE EXCEPTION 'FI-DEV-1 ROUGE B1 : % devrait avoir % decimale(s), obtenu %',
        v_ligne.code, v_ligne.decimales, private.devise_decimales(v_ligne.code);
    END IF;
  END LOOP;
  RAISE NOTICE 'FI-DEV-1 OK B : 26 devises hors defaut et 5 devises a 2 decimales';
END;
$fi_dev_table$;

-- C. Le chemin reel : un encaissement GNF confirme par le prestataire alimente
-- la tresorerie (trigger x217_alimenter_wallet_entry) avec la bonne reference.
INSERT INTO public.households (id, timezone)
VALUES ('fd000000-0000-4000-8000-000000000101', 'Africa/Conakry');
INSERT INTO public.wallets (id, household_id, currency)
VALUES ('fd000000-0000-4000-8000-000000000201', 'fd000000-0000-4000-8000-000000000101', 'GNF');

DO $fi_dev_tresorerie$
DECLARE
  v_gros bigint;
  v_petit bigint;
  v_ref bigint;
BEGIN
  INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type, confirme_par_prestataire_le)
  VALUES ('fd000000-0000-4000-8000-000000000201', 1823200, 'GNF', 'credit', now())
  RETURNING id INTO v_gros;
  INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type, confirme_par_prestataire_le)
  VALUES ('fd000000-0000-4000-8000-000000000201', 4000, 'GNF', 'credit', now())
  RETURNING id INTO v_petit;

  SELECT m.montant_ref_minor INTO v_ref FROM public.tresorerie_mouvements m
   WHERE m.source_type = 'encaissement' AND m.source_id = v_gros::text;
  IF v_ref IS DISTINCT FROM 21200 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE C1 : encaissement de 1 823 200 GNF ecrit avec la reference %, attendu 21200', v_ref;
  END IF;
  SELECT m.montant_ref_minor INTO v_ref FROM public.tresorerie_mouvements m
   WHERE m.source_type = 'encaissement' AND m.source_id = v_petit::text;
  IF v_ref IS DISTINCT FROM 47 THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE C2 : encaissement de 4 000 GNF ecrit avec la reference %, attendu 47', v_ref;
  END IF;
  IF EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre r
              WHERE r.source_type = 'encaissement'
                AND r.source_id IN (v_gros::text, v_petit::text)) THEN
    RAISE EXCEPTION 'FI-DEV-1 ROUGE C3 : un encaissement GNF est parti en file de reprise';
  END IF;
  RAISE NOTICE 'FI-DEV-1 OK C : encaissements GNF ecrits en tresorerie a 212,00 $ et 0,47 $';
END;
$fi_dev_tresorerie$;

-- D. Droits : ni la table ni la conversion ne s'ouvrent a un role client.
-- D1 est la preuve : il lit, sous postgres, l'ACL des deux fonctions apres
-- toutes les migrations (le meme controle que le postflight de
-- 20261021210300, mais rejoue a chaque passage : un GRANT EXECUTE pose par
-- une migration ulterieure le fait rougir).
DO $fi_dev_acl$
DECLARE
  v_fonction regprocedure;
  v_role text;
BEGIN
  FOREACH v_fonction IN ARRAY ARRAY[
      'private.devise_decimales(text)'::regprocedure,
      'public.x217_montant_ref(bigint,text,timestamptz)'::regprocedure] LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_fonction, 'EXECUTE') THEN
        RAISE EXCEPTION 'FI-DEV-1 ROUGE D1 : % a EXECUTE sur %', v_role, v_fonction;
      END IF;
    END LOOP;
  END LOOP;
  RAISE NOTICE 'FI-DEV-1 OK D1 : aucun role client n''a EXECUTE sur les deux fonctions';
END;
$fi_dev_acl$;

-- D2 et D3, defense en profondeur seulement. Sous authenticated, l'appel de
-- private.devise_decimales echoue deja sur le schema (aucun USAGE sur private,
-- migrations 0088 et 20261011112958) quel que soit l'ACL de la fonction : D2
-- ne prouve donc pas cet ACL, c'est D1 qui le prouve. D3 vise une fonction de
-- public : son 42501 vient bien de l'ACL de la fonction.
SET LOCAL ROLE authenticated;
DO $fi_dev_sondes$
BEGIN
  BEGIN
    PERFORM private.devise_decimales('GNF');
    RAISE EXCEPTION 'FI-DEV-1 ROUGE D2 : authenticated lit private.devise_decimales';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.x217_montant_ref(1000, 'GNF', now());
    RAISE EXCEPTION 'FI-DEV-1 ROUGE D3 : authenticated execute public.x217_montant_ref';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'FI-DEV-1 OK D2-D3 : appels refuses sous authenticated (42501)';
END;
$fi_dev_sondes$;
RESET ROLE;

ROLLBACK;
