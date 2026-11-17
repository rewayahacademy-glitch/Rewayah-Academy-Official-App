-- DETTE-COMPTABLE-2 (sécurité, suite de 20261129810000) : la comptabilité pouvait, par l'API, ÉCRIRE dans
-- `wallets` (insérer, changer household_id et devise, supprimer) et INSÉRER dans `wallet_entries` (le
-- grand livre : un crédit forgé). La direction pouvait écrire dans `wallets` de la même façon.
-- Aucun DROP / DELETE / TRUNCATE ; ALTER POLICY et GRANT/REVOKE.
--
-- Inventaire (lib/, supabase/functions, base) :
--  * aucun écran ni fonction Edge n'écrit ces tables par l'API (aucun .from sur elles) ;
--  * toutes les écritures légitimes passent par des fonctions SECURITY DEFINER (fac_crediter_paiement,
--    fac_portefeuille, fac_rendre_commande, fac_financer_profil, recharge_evenement_stripe,
--    remboursement_evenement_stripe, reprendre_alimentation_tresorerie...), qui n'ont pas besoin de
--    politique d'écriture ; private.cpt_anonymiser est la seule fonction INVOKER qui écrit, hors
--    chemin comptable ;
--  * la lecture de `wallet_entries`, `wallets`, `payouts` par la direction et la comptabilité reste
--    nécessaire (rech_d4_rechercher_reference_finance est INVOKER) : inchangée.
--
-- Deux choses sont laissées en l'état, parce qu'une décision datée les veut ainsi (voir la PR) :
--  * `payouts` et `payout_methods` : écriture déjà fermée (droits SELECT seul, GARDE-VERSEMENTS du 08/11,
--    20261121600000) et lecture par la direction et la comptabilité voulue par ce même lot ;
--  * l'insertion dans `wallet_entries` PAR LA DIRECTION : le lot L1-06 de l'audit du 16/10 la garde
--    (« correction par écriture inverse », scenarios_af_l1_06_ledger_immuable.sql). Seule la comptabilité
--    la perd.

-- wallets : lecture finance conservée, plus aucune écriture par l'API (direction comprise).
ALTER POLICY wallets_admin_accountant_all ON public.wallets
  WITH CHECK (false);
REVOKE ALL ON TABLE public.wallets FROM authenticated;
GRANT SELECT ON TABLE public.wallets TO authenticated;

-- wallet_entries : l'insertion directe reste à la direction seule ; la comptabilité la perd.
ALTER POLICY wallet_entries_admin_accountant_insert ON public.wallet_entries
  WITH CHECK (COALESCE(( SELECT app_role() ) = 'admin'::app_role AND ( SELECT app_account_valid() ), false));
