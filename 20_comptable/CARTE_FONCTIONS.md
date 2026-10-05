# Comptable V1 : carte des fonctions (routes réelles)

Posée par CPT-FUS le 05/10/2026, sur `ui/comptable-v1` après fusion des six voies (CPT-PAY, CPT-TRES, CPT-ENC, CPT-BEN, CPT-CTR, CPT-DIR) et de FI-VAGUE-CORR. Frontend seulement : chaque port renvoie `CapaciteIndisponible('CPT-BR-nn')` en production, donc la page livrée affiche son propre état « en préparation » (K-09) ; la démonstration (`/demo/comptable?ecran=…`, hors production) branche les données de `lib/features/demo/comptable/*_demo.dart`.

Coquille : `NavShell` du rôle Comptable, quatre destinations (Aujourd'hui 0, Paiements 1, Trésorerie 2, Compte 3) ; onglets de second niveau par `SousNavigationDomaine`.

## Destination 0 : Aujourd'hui

| Fonction | Route réelle | Page | Écran démo | Port (CPT-BR) |
| :--- | :--- | :--- | :--- | :--- |
| W01 Aujourd'hui (zones : à traiter, paiements à effectuer, échéances, encaissements récents, alertes, prestataires, activité, accès rapides) | `/comptable` | `AujourdhuiComptablePage` | `aujourdhui` | `port_aujourdhui_comptable` (03, lit 04, 10, 12) |
| File complète « À traiter » et « Alertes » | `/comptable?vue=attention` | `AujourdhuiComptablePage(vue: attention)` | `attention` | idem |

Liens d'Aujourd'hui (tous vers des routes réelles, testés dans `routes_comptable_test.dart`) :
- accès rapides (bureau) : Paiements → `/comptable/paiements` ; Contractuels → `/comptable/paiements/contractuels` ; Encaissements → `/comptable/tresorerie/encaissements` ; Trésorerie → `/comptable/tresorerie` ; Alimenter la Réserve → `/comptable/tresorerie?action=alimenter` ;
- « Voir tout » des échéances → `/comptable/paiements` ; des encaissements récents → `/comptable/tresorerie/encaissements` ; carte Trésorerie → `/comptable/tresorerie` ;
- chaque élément de la file → l'écran canonique déjà filtré (`/comptable/paiements?filtre=prets&type=enseignant`, `?filtre=infos`, `?filtre=validation`, `/comptable/paiements/obligation/<id>`, `/comptable/paiements/contractuels/obligation/<id>`, `/comptable/paiements/beneficiaires/<id>`, `/comptable/tresorerie/encaissements/<id>`, `/comptable/tresorerie/rapprochement`) ;
- un encaissement récent → `/comptable/tresorerie/encaissements/<id>`.

## Destination 1 : Paiements (onglets Paiements · Contractuels · Bénéficiaires)

| Fonction | Route réelle | Page | Écran démo | Port (CPT-BR) |
| :--- | :--- | :--- | :--- | :--- |
| W02 Paiements à effectuer, filtres (`filtre`, `type`, `classe`), sélection en lot | `/comptable/paiements` | `PaiementsAEffectuerPage` | `paiements` | `port_obligations_payables` (01) |
| Payer : préflight puis confirmation de payout (montant exact `MontantArgent`) | depuis W02 / W03 (feuille) | `confirmation_payout.dart` | `paiements` | `port_payout` (02), `port_capacite_payout` (10) |
| W03 Détail d'un paiement, « Signaler un écart » | `/comptable/paiements/obligation/<id>` | `DetailPaiementPage` | `detailPaiement` | 01, 02 |
| W06 Contractuels | `/comptable/paiements/contractuels` | `ContractuelsPage` | `contractuels` | `port_obligations_contractuels` (08) |
| W06 Détail d'une obligation de contractuel | `/comptable/paiements/contractuels/obligation/<id>` | `ObligationContractuelPage` | `obligationContractuel` | 08 |
| W06 Nouvelle obligation (tâche focalisée, barre basse masquée) | `/comptable/paiements/contractuels/nouvelle` | `NouvelleObligationPage` | `nouvelleObligation` | 08 |
| W07 Bénéficiaires | `/comptable/paiements/beneficiaires` | `BeneficiairesPage` | `beneficiaires` | `port_beneficiaires_paiement` (06) |
| W07 Profil de paiement : relancer, demander une mise à jour, suspendre / reprendre | `/comptable/paiements/beneficiaires/<id>` | `ProfilPaiementPage` | `profilPaiement` | 06, `port_relance_paiement` (11) |

## Destination 2 : Trésorerie (onglets Trésorerie · Encaissements · Rapprochement)

| Fonction | Route réelle | Page | Écran démo | Port (CPT-BR) |
| :--- | :--- | :--- | :--- | :--- |
| W04 Trésorerie et coffres : trésorerie libre, sept coffres, Réserve stratégique (lecture), prévision, historique, politique de la Réserve (lecture) | `/comptable/tresorerie` | `TresoreriePage` | `tresorerie` | `port_tresorerie` (04), `port_politique_reserve` (12, lecture) |
| Alimenter la Réserve / mouvement entre coffres | `/comptable/tresorerie?action=alimenter` | `TresoreriePage` + `transfert_interne.dart` | `alimenter` | 05 |
| W05 Encaissements | `/comptable/tresorerie/encaissements` | `EncaissementsPage` | `encaissements` | `port_encaissements` (07) |
| W05 Détail d'un encaissement | `/comptable/tresorerie/encaissements/<id>` | `DetailEncaissementPage` | `detailEncaissement` | 07 |
| Rapprochement, remboursements et avoirs | `/comptable/tresorerie/rapprochement` | `RapprochementPage` | `rapprochement` | `port_rapprochement` (14), 15 |

## Destination 3 : Compte

| Fonction | Route réelle | Page | Écran démo | Port (CPT-BR) |
| :--- | :--- | :--- | :--- | :--- |
| Compte du Comptable | `/compte` | `ComptePage` | `compte` | (socle) |
| Recevoir mes paiements (bénéficiaire lui-même, aussi pour l'enseignant dans sa coquille) | `/compte/paiements-recus` | `RecevoirPaiementsPage` | `recevoirPaiements` | `port_mes_moyens_paiement` (16) |

## Delta Direction (coquille admin)

| Fonction | Route réelle | Page | Écran démo | Port (CPT-BR) |
| :--- | :--- | :--- | :--- | :--- |
| Réserve et délégation : politique de la Réserve stratégique (écriture versionnée) et délégation financière | `/admin/finance/reserve-delegation` (troisième onglet de Finance) | `FinancePage` > `ReserveDelegationPage` | `reserveDelegation`, `/demo/finance?ecran=reserveDelegation` | 12, 13, `port_validations_finance` (09, attend CPT-Q1) |

Un Comptable n'ouvre pas ce delta (renvoyé à `/comptable`) ; un admin n'ouvre pas `/comptable` (renvoyé à `/admin`).

## Démonstration

Une seule Réserve dans toute la démonstration : politique cible fixe 9 000 USD, alimentation fixe 1 000 USD par mois, actuel 7 400 USD (= coffre Réserve stratégique de la Trésorerie), manque 1 600 USD, 82,2 % atteint, sous l'objectif ; Aujourd'hui lit les mêmes indicateurs (`PolitiqueReserveDemo.sousObjectif`) et la même synthèse de trésorerie (détenue 48 650, protégée 37 900, transit 1 250, libre 9 500 USD). Aucune règle métier ajoutée.

Journal par opération (CPT-BR-17) : `journal(id)` dans chaque port, rendu par `LigneActivite`.
