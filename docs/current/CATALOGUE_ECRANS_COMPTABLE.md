# Catalogue des écrans du Comptable

Registre des écrans de l'espace Comptable et des deux onglets Finance de la
direction qui l'accompagnent, au format du registre général (colonnes : Code,
Écran, Rôle, niveau de charge, profondeur, route, mobile, bureau, état).


Inscrite le 5 octobre 2026 (étape CPT-DIR-2, décision Q-11 = b du directeur,
prise par délégation le 05/10), déplacée ici le 8 octobre 2026 (décidé par
délégation le 08/10) : le catalogue général d'origine est archivé
(`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`, qui
renvoie ici), et `docs/archive/` ne se charge pas comme instruction. La fiche de chaque écran est la revue UX
existante, `20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` sur la branche
`pilotage/tuteur-v1` (citée « UX_REVIEW §n » dans la dernière colonne) : on n'en
écrit pas une seconde ici. Routes et ports : `CARTE_FONCTIONS` de CPT-FUS.
**État** : présent dans le code et testé localement, frontend seulement ; en
production chaque port renvoie `CapaciteIndisponible('CPT-BR-nn')` et la page
affiche son état « en préparation » ; la démonstration
`/demo/comptable?ecran=…` (hors production) porte les données. Montants
masqués par défaut, pourcentages dérivés d'un montant masqués avec eux (Q-9) ;
textes traduits en arabe (Q-10).

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `CPT-01` | Aujourd'hui (et file « À traiter et alertes ») | Comptable | E | 0 | `/comptable`, `/comptable?vue=attention` | Zones empilées, file complète par lien | Grille de zones, accès rapides | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.1 |
| `CPT-02` | Paiements à effectuer, confirmation de payout | Comptable | E | 1 | `/comptable/paiements` | Cartes, barre de sélection basse | Tableau dense, sélection en lot | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.2 |
| `CPT-03` | Détail d'un paiement, « Signaler un écart » | Comptable | E | 2 | `/comptable/paiements/obligation/<id>` | Page, sections empilées | Détail et lignes du calcul côte à côte | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.3 |
| `CPT-04` | Trésorerie et coffres, alimenter la Réserve | Comptable | E | 0 | `/comptable/tresorerie`, `?action=alimenter` | Synthèse puis coffres en cartes | Coffres à gauche, Réserve à droite | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.4 |
| `CPT-05` | Encaissements | Comptable | E | 1 | `/comptable/tresorerie/encaissements` | Cartes filtrées | Tableau dense | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.5 |
| `CPT-06` | Détail d'un encaissement | Comptable | E | 2 | `/comptable/tresorerie/encaissements/<id>` | Page | Panneau à droite de la liste | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.5 |
| `CPT-07` | Rapprochement, remboursements | Comptable | E | 1 | `/comptable/tresorerie/rapprochement` | Liste puis détail | Liste à gauche, détail à droite | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.5 |
| `CPT-08` | Contractuels et obligations | Comptable | E | 1 | `/comptable/paiements/contractuels` | Onglets et cartes | Onglets et tableau dense | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.6 |
| `CPT-09` | Obligation d'un contractuel | Comptable | E | 2 | `/comptable/paiements/contractuels/obligation/<id>` | Page, barre d'action collante | Détail et historique côte à côte | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.6 |
| `CPT-10` | Nouvelle obligation | Comptable | E | 2 | `/comptable/paiements/contractuels/nouvelle` | Tâche focalisée, barre basse masquée | Formulaire borné | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.6 |
| `CPT-11` | Bénéficiaires | Comptable | E | 1 | `/comptable/paiements/beneficiaires` | Cartes filtrées | Tableau dense | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.7 |
| `CPT-12` | Profil de paiement d'un bénéficiaire | Comptable | E | 2 | `/comptable/paiements/beneficiaires/<id>` | Page, actions en bas | Profil et journal côte à côte | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.7 |
| `CPT-13` | Recevoir mes paiements | Comptable, Enseignant | D | 1 | `/compte/paiements-recus` | Page, méthodes en liste | Page bornée | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.10 |
| `ADM-18` | Finance > Réserve et délégation | Admin | E | 1 | `/admin/finance/reserve-delegation` | Deux panneaux empilés | Deux panneaux, formulaire borné | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.9 |
| `ADM-19` | Finance > À valider (demandes du Comptable) | Admin | E | 1 | `/admin/finance/a-valider` | File puis décision en feuille | File, décision en feuille | **construit (CPT-VAL-1, 05/10, Q-8 = a)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.9 et `docs/current/CPT-VAL-1.md` |

**Codes nouveaux introduits le 5 octobre 2026** : `CPT-02` à `CPT-13`,
`ADM-18`, `ADM-19`. `CPT-01` garde son code et sa route ; seul son contenu
change. Aucun code existant n'est renommé. La Vue globale et les Politiques
commerciales de la Finance (vague 17_finance) restent hors de ce registre,
comme avant.
