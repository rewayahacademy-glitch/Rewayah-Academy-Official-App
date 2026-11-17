# DETTE : la correction du grand livre (`wallet_entries`) par écriture inverse

État : **REPORTÉE, pas abandonnée** (pilote, 17/11/2026). Migration `20261129850000` réservée, non écrite.
Auteur de l'analyse : BE-GESTES, 17/11/2026. Aucune ligne de personne n'a été lue : le schéma et le texte des fonctions seulement (R14).
Tant que ce document n'a pas sa décision, la direction garde l'insertion directe au grand livre (décision datée L1-06, audit du 16/10, `scenarios_af_l1_06_ledger_immuable.sql`).

## Pourquoi cette dette existe

Depuis #594 (migration `20261129830000`, installée le 17/11), la comptabilité ne peut plus insérer au grand livre ni écrire `wallets`. Il reste **une seule porte directe : l'insertion par la direction** (`wallet_entries_admin_accountant_insert`, désormais admin seul). Elle n'est employée par aucun écran ni aucune fonction : elle ne sert que de « correction par écriture inverse ». Le but du lot : remplacer cette porte par une fonction `SECURITY DEFINER` (motif, `aal2`, journal), puis la fermer (`WITH CHECK (false)`).

## Les cinq faits qui rendent « l'écriture inverse exacte » ambiguë

1. **L'identifiant n'est pas un `uuid`.** `wallet_entries.id` est un `bigint` généré (identity). Une fonction `direction_corriger_ecriture(p_entree uuid, …)` ne peut pas désigner une entrée ; il faut `p_entree bigint` (la clé d'idempotence, elle, peut rester `uuid`).
2. **Les montants sont toujours positifs ; le sens vient du type.** `private.bf1_montant_signe` : `credit` = `+abs`, `adjustment` = montant **signé**, tous les autres (`debit`, `refund`, `payout`) = `−abs`. Un `credit` ne compte dans le solde que s'il est confirmé (`private.bf1_compte`). Donc « le montant opposé » n'existe pas : l'inverse d'un `credit` est un `refund`, celui d'un `debit` un `adjustment` positif (c'est ce que fait déjà `private.fac_rouvrir_si_negatif`), celui d'un `refund` un `credit`, celui d'un `adjustment` un `adjustment` de signe contraire. Un `payout` n'a pas d'inverse défini.
3. **Le lien vers l'entrée corrigée n'existe que pour `refund`.** Le CHECK `wallet_entries_refund_link_check` exige `refund_of_entry_id` pour un `refund` et l'interdit pour tout autre type. Corriger un `debit` ou un `adjustment` avec un lien demanderait une nouvelle colonne (`corrige_entree_id`, plus un index unique partiel pour « déjà corrigée », et le refus d'une correction de correction), donc une migration de schéma, plus une table d'idempotence par clé.
4. **Un `refund` confirmé déclenche de la trésorerie.** Le déclencheur `x217_alimenter_wallet_entry` écrit alors une **sortie** (coffre `fonds_clients_engages`), exige que l'original soit un `credit` confirmé, de même portefeuille et même devise, et plafonne le montant à ce qui reste remboursable. Non confirmé, le `refund` corrige le solde du foyer **sans** mouvement de trésorerie, mais réduit quand même « le reste remboursable » que `private.fac_rendre_commande` calcule par `refund_of_entry_id`.
5. **D'autres documents pointent des entrées.** `paiements_saisis.entry_id`, `factures_mensuelles.debit_entry_id`, `remboursements_paiement.entry_id`, `commandes_recharge_allocations.entry_id`. Inverser un débit de facture laisserait la facture « financée » ; le chemin existant pour cela est `private.fac_rouvrir_si_negatif`.

## Ma proposition v1 (BE-GESTES)

- Corriger **un `credit` confirmé** par un `refund` de même montant, portefeuille, devise et bénéficiaire, **non confirmé** (donc sans sortie de trésorerie), lié par `refund_of_entry_id` (aucune colonne nouvelle).
- Corriger **un `debit` non lié à une facture financée** par un `adjustment` positif, avec la colonne `corrige_entree_id`.
- Tout le reste est refusé avec une cause nommée.
- Garde : admin valide en `aal2`, motif de 10 à 300 signes, idempotence par clé (table, une ligne par clé), `log_sensitive_access`, un refus ne laisse aucune écriture.
- Dans la même migration : `wallet_entries_admin_accountant_insert` passe à `WITH CHECK (false)`.

## L'option préférée a priori du pilote (17/11)

Un **`adjustment` signé, sans mouvement de trésorerie**, pour un `credit` confirmé et pour un `debit` non lié, **sans toucher `refund` ni la colonne de lien**. Conséquences à vérifier avant d'écrire : (a) `adjustment` n'accepte pas de lien (fait 3) : « déjà corrigée » et « correction de correction » ne se garantiraient alors que par `reference_id` ou par la table d'idempotence, pas par la base ; (b) un `adjustment` n'a pas de bénéficiaire forcé par le déclencheur `private.bf1_valider_beneficiaire` comme un `refund` : il faut le copier explicitement de l'entrée corrigée ; (c) le « reste remboursable » n'est pas réduit : un crédit corrigé pourrait encore être remboursé en vrai, ce que la fonction doit refuser elle-même.

## Les trois questions, dans leur ordre de blocage

- **(a)** `p_entree` en `bigint` : d'accord ? (Sans objection attendue.)
- **(b)** Une correction **sort-elle de la trésorerie** ou ne corrige-t-elle que le solde du foyer ? **Règle d'argent**, qui relève du lot HARMONISER-ARGENT (`docs/current/A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) ; elle attend sa décision unique. Je ne la fixe pas.
- **(c)** Portée v1 limitée à `credit` et `debit` : d'accord ?

## Ce qui est prêt le jour où (b) est tranchée

Le lot s'écrit en une migration (`20261129850000`) et un scénario rouge→vert : fonction `direction_corriger_ecriture`, table d'idempotence, (colonne de lien si l'option retenue en demande une), `WITH CHECK (false)` sur l'insertion directe, adaptation de `scenarios_af_l1_06_ledger_immuable.sql` (la correction passe par la porte). Aucun écran dans ce lot. Rien de tout cela n'est écrit.

## Ce qui n'est pas prouvé

Aucune de ces affirmations n'a été vérifiée en production par une lecture de lignes (interdite) ; elles viennent du schéma et du texte des fonctions de la base rejouée localement, identique à la production pour ces objets (relu par `pg_policies` et `role_table_grants` le 17/11).
