# Demande backend : finance visible hors administration (17/10/2026)

De : Claude (écrans, lot F1, branche `lots/F1-finance-visible`). Pour : ChatGPT (Codex).
Origine : le directeur ne voit la finance que chez l'administration. Les écrans des autres rôles
existent et sont désormais atteignables depuis chaque accueil ; ils affichent « pas encore
publié » parce que leurs ports rendent `CapaciteIndisponible`. Rien n'est inventé côté écran.

Statut de ce lot : `présent dans le code`, `testé localement` (écrans seulement). Aucun
adaptateur, aucune migration, aucune RPC écrits ici (zone backend, `COHABITATION.md`, section 2).

## 1. Les quatre ports à brancher

| Port (fichier) | Implémentation actuelle | Code manquant | Écran qui le lit | Lecteur autorisé |
| :--- | :--- | :--- | :--- | :--- |
| `PortRevenusEnseignant` (`lib/core/capacites/port_revenus_enseignant.dart`) | `RevenusEnseignantIndisponibles` | FI-BR-11 | `/enseignant/revenus` (Profil et, depuis F1, Aujourd'hui) | l'enseignant connecté, sur lui seul |
| `PortMesFinances` (`lib/core/capacites/port_mes_finances.dart`) | `MesFinancesIndisponible` | FI-BR-17 | `/eleve/finances` (nouvelle route, accueil adulte) | le compte « élève autonome » (C-24), sur son seul profil |
| `PortPaiementsFoyer` (`lib/core/capacites/port_paiements_foyer.dart`) | `PaiementsFoyerIndisponible` | DB-CPT-03, FI-BR-03, FI-BR-05 | Foyer, `/tuteur/foyer/:id/finances` (accueil famille, depuis F1), `/tuteur/compte/paiements` | le titulaire du foyer ; jamais l'enfant ni le second adulte |
| `PortRechargeFoyer` (`lib/core/capacites/port_recharge_foyer.dart`) | `RechargeFoyerIndisponible` | FI-BR-06 | `/tuteur/foyer/recharge` (et la recharge du seul profil de l'adulte) | le titulaire ; l'adulte autonome pour son seul profil |

## 2. Contrats (lus dans les fichiers de port, à respecter tels quels)

Règles communes : montants en `Montant` (unités mineures + ISO 4217), arrêtés par le serveur ;
Flutter n'additionne, ne divise ni n'arrondit rien. Listes dans l'ordre rendu. Une capacité
absente reste `CapaciteIndisponible`, jamais une liste vide.

- **PortRevenusEnseignant** : `moisEnCours()`, `duMois(DateTime mois)`, `moisDisponibles()`,
  `releve()`. `RevenusEnseignant` = `debut`, `fin`, `classes` (`RevenusClasse` : `classeId`,
  `classe`, `type` enfants / débutants / adultes, `minutesAssurees`, `capacite`,
  `siegesEligibles`, `tauxHoraireEffectif`, `montantEstime`, `enRemplacement`), `total`
  (`TotalRevenus` : minutes, capacité, sièges, `tauxHoraireMoyen`, tous calculés serveur),
  `totalEstime`, `baseHoraire`, `plafondHoraire`, `allocationInternet` (nul si non éligible).
  `LigneReleve` = `mois`, `minutesAssurees`, `montant` ; aucun statut « payé ».
- **PortMesFinances** : `finances()` rend `FinancesProfil?` (nul : pas encore inscrit) ;
  `mouvements()` rend `List<MouvementProfil>`, le plus récent d'abord. Aucun identifiant passé
  par l'écran : le périmètre est la session.
- **PortPaiementsFoyer** : `historique()`, `detail(id)`, `soldes()` (`SoldesFoyer`, soldes déjà
  rédigés), `finances()` (`FinancesFoyer` : `SyntheseFoyer` + un `FinancesProfil` par profil),
  `mouvements(profilId)`, `derniersMouvements({limite = 3})`.
- **PortRechargeFoyer** : `beneficiaires()`, `verifier(choix)`, `verifierMontants(choix)`,
  `payer({recapitulatifId, cle})` (idempotent par `cle`), `suivre(commandeId)` (un des huit
  états, jamais déduit par l'écran).
- `FinancesProfil` (`lib/core/finance/finances_profil.dart`) : `profilId`, `prenom`, `etat`
  (`EtatFinancier`), `solde`, `periode` (début, fin), `prochainDebit` (date, montant),
  `mensualite`, `lignesMensualite`, `essaisUtilises`, `manque`, `finConservation`, plus les
  champs d'identité (accent, avatar, classe, âge, adulte).

## 3. RPC de lecture nécessaires (proposition, à décider côté backend)

1. **Revenus de l'enseignant connecté** : une RPC `security definer` bornée à `auth.uid()`
   (rôle `teacher`), par mois, qui joint les minutes assurées par séance, la règle de
   `regles_remuneration_enseignant` en vigueur à la date de la séance (`date_effet`) et les
   écritures `tresorerie_mouvements` (`source_type = 'prestation'`, coffre `paie_a_decaisser`).
   Constat : `tresorerie_mouvements` ne porte ni enseignant ni séance en colonne (seulement
   `source_id` texte), et sa lecture est réservée à la finance ; la RPC doit donc établir ce
   lien sans ouvrir la table. Elle rend aussi `moisDisponibles` et le relevé des mois arrêtés.
   L'alimentation des prestations reste bloquée (X2-17-BLOQUE) : tant qu'elle l'est, la RPC
   peut rendre `moisDisponibles = []` et le relevé vide, l'écran sait le dire.
2. **Finances par profil** : `wallets` est **par foyer** (`household_id unique`), et
   `wallet_entries` n'a pas de profil. Il faut soit une ventilation par profil élève (colonne
   ou table d'affectation), soit une règle serveur qui la calcule. Deux RPC : une pour le
   titulaire (tous les profils du foyer, `FinancesFoyer`), une pour l'adulte autonome (son
   seul profil, `FinancesProfil`), sans jamais rendre les autres membres à ce dernier.
3. **Paiements du foyer** : historique et détail des paiements confirmés (FI-BR-06 :
   confirmation prestataire, jamais un retour navigateur), avec l'indicateur de justificatif.

## 4. Arbitrage manquant (à remonter au directeur)

Aucune notion d'**échéance** ni de **« reste à payer »** n'existe côté serveur : pas de table de
facture, pas de période due, pas de mensualité arrêtée. Or `FinancesProfil` attend `periode`,
`prochainDebit`, `mensualite`, `lignesMensualite` et `manque`. Ces valeurs dépendent des lots A
(politiques et produits versionnés : prix, remises, validité) et B (facturation et fournisseurs)
de `docs/current/07_MEMOIRE_PEDAGOGIE_FINANCE.md`, non commencés. Sans décision datée sur la
politique de prix et la règle de facturation, le backend ne peut rendre qu'un solde et des
mouvements ; les autres champs doivent alors rester nuls, et l'écran les tait. Question à
poser : faut-il brancher d'abord solde et mouvements seuls, ou attendre les lots A et B ?

## 5. Ce que Claude relira

Les adaptateurs `*_supabase.dart` des quatre ports, les RPC et leurs scénarios
`supabase/tests/scenarios_*.sql` (RLS : un enfant, un second adulte et un autre enseignant ne
lisent rien), puis l'affichage réel sur staging.
