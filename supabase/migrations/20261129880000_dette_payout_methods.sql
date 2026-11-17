-- DETTE-PAYOUT-METHODS (arbitrage du pilote, 17/11/2026, sur l'inventaire #600) : la direction et la
-- comptabilite ne lisent plus `public.payout_methods` par l'API. La colonne `details` porte les
-- coordonnees de versement (IBAN, numero de mobile money) : un comptable valide, sans second facteur,
-- les lisait par `GET /rest/v1/payout_methods`.
--
-- Pourquoi maintenant, et pourquoi la decision du 08/11 est perimee :
--  * GARDE-VERSEMENTS (20261121600000, 08/11) avait retire l'ECRITURE et laisse « la lecture permise ».
--    Cette reserve visait un usage de l'application. Il n'existe pas : aucun ecran, aucun adaptateur
--    Flutter, aucune fonction Edge, aucune vue ne lit la table (inventaire #600, 17/11) ; les deux ports
--    de versement et de beneficiaires sont indisponibles et non branches dans `lib/main.dart`.
--  * La table est VIDE en production : 0 ligne (compteur, pilote, 17/11), 0 insertion depuis sa creation.
--    Fermer la lecture ne coute donc rien aujourd'hui ; ce serait plus cher une fois des coordonnees saisies.
--  * La paie reelle ne passe pas par cette table (`versements_paie`, `versement_coordonnees_direction`,
--    fonctions SECURITY DEFINER sans droit direct).
--
-- Ce que fait ce fichier, et rien d'autre : UN `ALTER POLICY` sur `payout_methods_admin_accountant_all`
-- (commande ALL, roles `agent_ro` et `authenticated`) : USING (false) et WITH CHECK (false). Consequences :
--  * direction et comptabilite : plus aucune ligne lue ni ecrite par l'API (l'ecriture etait deja fermee
--    par les droits) ;
--  * `agent_ro` perd la lecture des LIGNES de cette table (le privilege SELECT reste, la RLS masque) :
--    accepte par le pilote, les agents n'ont pas a lire des coordonnees bancaires ;
--  * la lecture famille de SES propres coordonnees (`payout_methods_family_read`) ne change pas ;
--  * les fonctions SECURITY DEFINER qui la touchent (`mes_donnees_export`, `private.cpt_anonymiser` appelee
--    par `traiter_demande_suppression`) s'executent avec les droits du proprietaire et ne dependent pas
--    de la politique.
-- `payouts` n'est PAS touchee (option B de l'inventaire). Les futurs adaptateurs lisent par RPC SECURITY
-- DEFINER, avec second facteur pour tout ce qui montre `details`.
--
-- Additif : aucun mot d'effacement, aucun BEGIN ni COMMIT de premier niveau. Preflight : la politique est
-- celle de la production (empreintes du texte lu au catalogue le 17/11) ; refus si elle est deja fermee.

DO $preflight$
DECLARE
  v_all pg_catalog.pg_policies%ROWTYPE;
  v_fam pg_catalog.pg_policies%ROWTYPE;
BEGIN
  IF pg_catalog.to_regclass('public.payout_methods') IS NULL THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS : payout_methods absente ; rien n''est modifie';
  END IF;
  SELECT * INTO v_all FROM pg_catalog.pg_policies
   WHERE schemaname = 'public' AND tablename = 'payout_methods' AND policyname = 'payout_methods_admin_accountant_all';
  SELECT * INTO v_fam FROM pg_catalog.pg_policies
   WHERE schemaname = 'public' AND tablename = 'payout_methods' AND policyname = 'payout_methods_family_read';
  IF v_all.policyname IS NULL OR v_fam.policyname IS NULL THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS : une des deux politiques attendues est absente ; rien n''est modifie';
  END IF;
  IF v_all.qual = 'false' AND v_all.with_check = 'false' THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS : deja installe ; rien n''est modifie';
  END IF;
  IF v_all.cmd <> 'ALL'
     OR pg_catalog.md5(v_all.qual) <> '382764159ec8faf135c4dd9b8d45b992'
     OR pg_catalog.md5(v_all.with_check) <> '382764159ec8faf135c4dd9b8d45b992' THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS : payout_methods_admin_accountant_all n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF v_fam.cmd <> 'SELECT' OR pg_catalog.md5(v_fam.qual) <> '4a2b83a745607da03a2249f3b3264fb0' THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS : payout_methods_family_read n''est pas celle attendue ; rien n''est modifie';
  END IF;
END
$preflight$;

ALTER POLICY payout_methods_admin_accountant_all ON public.payout_methods
  USING (false)
  WITH CHECK (false);

COMMENT ON TABLE public.payout_methods IS
  'Moyens de versement. GARDE-VERSEMENTS (20261121600000, 08/11/2026) : aucun client n''y ecrit directement. DETTE-PAYOUT-METHODS (20261129880000, 17/11/2026) : la direction et la comptabilite ne la lisent plus par l''API (0 ligne, 0 lecteur au 17/11) ; la famille lit les siens ; tout futur lecteur passe par une RPC SECURITY DEFINER.';

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'payout_methods'
                    AND policyname = 'payout_methods_admin_accountant_all'
                    AND cmd = 'ALL' AND qual = 'false' AND with_check = 'false') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS postflight : la politique de direction et comptabilite n''est pas fermee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'payout_methods'
                    AND policyname = 'payout_methods_family_read'
                    AND pg_catalog.md5(qual) = '4a2b83a745607da03a2249f3b3264fb0') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS postflight : la lecture famille a change';
  END IF;
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.payout_methods', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.payout_methods', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.payout_methods', 'UPDATE') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS postflight : les droits d''authenticated ont change';
  END IF;
  IF NOT pg_catalog.has_table_privilege('agent_ro', 'public.payout_methods', 'SELECT') THEN
    RAISE EXCEPTION 'DETTE-PAYOUT-METHODS postflight : agent_ro a perdu son privilege SELECT';
  END IF;
END
$postflight$;
