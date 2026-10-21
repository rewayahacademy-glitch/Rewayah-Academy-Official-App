-- FI-DEV-1 (21/10/2026, lot gnf de CAND-Q15) : une seule table des decimales
-- des devises, la table ISO 4217 complete
-- (docs/current/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md, section 6).
--
-- Constat : deux tables divergeaient.
-- * Client, `decimalesDe` (lib/core/finance/format_montant.dart) : 0 pour XOF,
--   XAF, GNF, JPY, KRW ; 2 pour toutes les autres (KMF et les devises a trois
--   decimales etaient donc fausses).
-- * Serveur, `public.x217_montant_ref` (20261012120101_x2_17_treasury_triggers.sql,
--   lignes 142-144) : 0 pour JPY, XOF, XAF, KMF ; 3 pour KWD, BHD, TND, OMR ;
--   2 pour les autres, GNF et KRW compris.
-- Effet : la reference USD d'un montant GNF ou KRW etait 100 fois trop petite.
-- Au taux de demonstration (1 USD = 8 600 GNF), 1 823 200 GNF valaient 2,12 $
-- au lieu de 212,00 $, et 4 000 GNF arrondissaient a 0 (file montant_invalide).
--
-- Correction :
-- * `private.devise_decimales(text)` porte la table ISO 4217 complete et fait
--   foi : 0 pour BIF CLP DJF GNF ISK JPY KMF KRW PYG RWF UGX UYI VND VUV XAF
--   XOF XPF ; 3 pour BHD IQD JOD KWD LYD OMR TND ; 4 pour CLF UYW ; 2 sinon.
--   Aucun droit client : seuls les DEFINER de proprietaire postgres l'atteignent.
-- * `public.x217_montant_ref` est redefinie (CREATE OR REPLACE) : signature,
--   proprietaire postgres, SECURITY DEFINER, STABLE, search_path vide et droits
--   (aucun role client) inchanges ; seule la table recopiee disparait au profit
--   de `private.devise_decimales`. Ses appelants (x2_17 et
--   20261018130000_fac_e_02, private.pai_due_seance) ne changent pas.
-- * Le client garde un miroir exact, `decimalesHorsDefaut`
--   (lib/core/finance/format_montant.dart), parce que le formatage est
--   synchrone et doit marcher hors ligne. Le test
--   test/core/finance/decimales_devises_test.dart lit la derniere migration
--   qui definit `private.devise_decimales` et compare les deux tables : il
--   casse si l'une bouge sans l'autre. Garder ici une liste `IN (...)` par
--   nombre de decimales et un `ELSE 2` : c'est la forme que le test lit.
--
-- Hors perimetre, volontairement non touche : `private.fac_prix_prepaiement`
-- (20261018120000_fac_e_01_tarifs_v2.sql, arrondi au dollar qui suppose deux
-- decimales). Aucune donnee reprise : les mouvements deja ecrits ne bougent pas
-- (tresorerie_mouvements est en ajout seul), et aucune migration n'ecrit de
-- taux GNF ni de montant GNF au moment d'ecrire ce lot.
-- Aucune signature publique ajoutee ou retiree : la liste blanche des
-- fonctions volatiles et les empreintes F86 ne changent pas
-- (`x217_montant_ref` n'a jamais porte de commentaire F86 et n'est pas une RPC).
BEGIN;

CREATE FUNCTION private.devise_decimales(p_devise text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN p_devise IN ('BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW',
                      'PYG', 'RWF', 'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XOF',
                      'XPF') THEN 0
    WHEN p_devise IN ('BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND') THEN 3
    WHEN p_devise IN ('CLF', 'UYW') THEN 4
    ELSE 2
  END;
$function$;

ALTER FUNCTION private.devise_decimales(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.devise_decimales(text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.devise_decimales(text) IS
  'FI-DEV-1 : nombre de decimales d''une devise (ISO 4217), source unique. Miroir client : decimalesHorsDefaut (lib/core/finance/format_montant.dart), compare par test/core/finance/decimales_devises_test.dart. Aucun droit client. date=2026-10-21.';

CREATE OR REPLACE FUNCTION public.x217_montant_ref(p_minor bigint, p_devise text, p_a timestamptz)
RETURNS bigint
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_taux numeric;
BEGIN
  IF p_devise = 'USD' THEN RETURN p_minor; END IF;
  SELECT f.rate INTO v_taux FROM public.fx_rates f
   WHERE f.from_currency = p_devise AND f.to_currency = 'USD' AND f.effective_at <= p_a
   ORDER BY f.effective_at DESC, f.id DESC LIMIT 1;
  IF v_taux IS NULL THEN RETURN NULL; END IF;
  -- Unites mineures de la devise vers unites mineures de l'USD : les deux
  -- nombres de decimales viennent de la meme table.
  RETURN pg_catalog.round(p_minor::numeric * v_taux * pg_catalog.power(10::numeric,
    private.devise_decimales('USD') - private.devise_decimales(p_devise)))::bigint;
END;
$function$;

ALTER FUNCTION public.x217_montant_ref(bigint, text, timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.x217_montant_ref(bigint, text, timestamptz)
  FROM PUBLIC, anon, authenticated, agent_ro, service_role;

DO $postflight$
DECLARE
  v_dec regprocedure := 'private.devise_decimales(text)'::regprocedure;
  v_ref regprocedure := 'public.x217_montant_ref(bigint,text,timestamptz)'::regprocedure;
  v_oid regprocedure;
  v_attendu record;
BEGIN
  -- Proprietes : la table est INVOKER et IMMUTABLE, la conversion reste
  -- DEFINER et STABLE ; proprietaire postgres et search_path vide pour les deux.
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = v_dec AND NOT p.prosecdef AND p.provolatile = 'i'
          AND p.proowner = 'postgres'::regrole
          AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'FI-DEV-1 : proprietes de private.devise_decimales invalides';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = v_ref AND p.prosecdef AND p.provolatile = 's'
          AND p.proowner = 'postgres'::regrole
          AND p.proconfig @> ARRAY['search_path=""']
          AND p.prosrc LIKE '%private.devise_decimales(p_devise)%') THEN
    RAISE EXCEPTION 'FI-DEV-1 : proprietes de public.x217_montant_ref invalides';
  END IF;
  -- Droits : aucun role client n'execute l'une ou l'autre.
  FOREACH v_oid IN ARRAY ARRAY[v_dec, v_ref] LOOP
    IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FI-DEV-1 : droits invalides pour %', v_oid;
    END IF;
  END LOOP;
  -- Valeurs : chaque classe de la table, et le defaut.
  FOR v_attendu IN
    SELECT d.code, d.decimales FROM (VALUES
      ('GNF', 0), ('KRW', 0), ('KMF', 0), ('XOF', 0), ('UYI', 0), ('XPF', 0),
      ('KWD', 3), ('BHD', 3), ('JOD', 3), ('TND', 3),
      ('CLF', 4), ('UYW', 4),
      ('USD', 2), ('EUR', 2), ('XTS', 2)) AS d(code, decimales)
  LOOP
    IF private.devise_decimales(v_attendu.code) IS DISTINCT FROM v_attendu.decimales THEN
      RAISE EXCEPTION 'FI-DEV-1 : % devrait avoir % decimale(s), la table en donne %',
        v_attendu.code, v_attendu.decimales, private.devise_decimales(v_attendu.code);
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
