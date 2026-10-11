# X2-17 — BLOQUÉ

## Périmètre vérifié

La base ccr `4ae20c71` contient `wallets`, `wallet_entries`, `payouts` et
`fx_rates` (migration `0001_fondations.sql`). Elle ne contient pas de
référentiel de coffres/réserve ni de journal comptable permettant de qualifier
les écritures comme encaissements ou décaissements.

## Contrat manquant

`PortSeriesTresorerie` demande la répartition par `Coffre`, les entrées/sorties
mensuelles, le flux quotidien, la trésorerie détenue et les variations en
pour mille. `wallet_entries.reference_type` distingue `credit`, `debit`,
`adjustment` et `payout`, mais aucune décision versionnée ne définit le signe
et la catégorie d'un ajustement, la conversion multi-devises, la composition
des coffres, ni le périmètre comptable des paiements. Ces règles ne peuvent
pas être déduites des seules colonnes ni inventées dans une RPC.

## Suite nécessaire

Le propriétaire financier doit fournir le contrat de données (source de
vérité, catégories/coffres, règles des ajustements et devises, et fenêtres de
clôture). Après cette décision, une RPC `SECURITY INVOKER` pourra agréger sur
le serveur pour la direction et un scénario pourra comparer chaque agrégat à
des écritures contrôlées. Aucun calcul financier n'a été ajouté dans Flutter
ou SQL pour ce lot.
