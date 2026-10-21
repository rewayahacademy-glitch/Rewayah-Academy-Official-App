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
| `CPT-12F` | Fil « Profil de paiement » d'un bénéficiaire (ouvert par « Relancer ») | Comptable | E | 3 | `/comptable/paiements/beneficiaires/<id>/fil` | Fil seul (en-tête de contexte, bulles, champ prérempli du message modèle §27.3) | Fil seul, sans liste de conversations (R-FIN-21 : aucune messagerie Finance) | **construit (CPT-COM, 10/10)** : `FilProfilPaiementPage` sur `FilContextuel` du socle Communications, `PortMessagesMetier.filPourObjet(TypeObjetLie.profilPaiement, id)` (contrat C-12, CPT-BR-11) ; captures `docs/current/captures/CPT-COM/` |
| `CPT-13` | Recevoir mes paiements | Comptable, Enseignant | D | 1 | `/compte/paiements-recus` | Page, méthodes en liste | Page bornée | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.10 |
| `CPT-14` | Rapports (entrées et sorties sur 6 mois, flux sur 30 jours, « Exporter le rapport ») | Comptable | E | 1 | `/comptable/tresorerie/rapports` | Graphiques empilés, légende écrite, tableau des valeurs sous « Voir les valeurs » | Idem, colonne bornée | **construit (COMPTA-GRAPH-1, 11/10)**, ports `PortSeriesTresorerie` (CPT-BR-18) et `PortExportRapports` (CPT-BR-19), démo `series_demo.dart` ; décision du directeur du 11/10 : les graphiques des maquettes sont voulus, DR-09 est levée |
| `ADM-18` | Finance > Réserve et délégation | Admin | E | 1 | `/admin/finance/reserve-delegation` | Deux panneaux empilés | Deux panneaux, formulaire borné | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.9 |
| `ADM-19` | Finance > À valider (demandes du Comptable) | Admin | E | 1 | `/admin/finance/a-valider` | File puis décision en feuille | File, décision en feuille | **construit (CPT-VAL-1, 05/10, Q-8 = a)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.9 et `docs/current/CPT-VAL-1.md` |

**Codes nouveaux introduits le 5 octobre 2026** : `CPT-02` à `CPT-13`,
`ADM-18`, `ADM-19`. `CPT-01` garde son code et sa route ; seul son contenu
change. Aucun code existant n'est renommé. La Vue globale et les Politiques
commerciales de la Finance (vague 17_finance) restent hors de ce registre,
comme avant.

## COMPTA-GRAPH-1 (11/10/2026) : graphiques, variations, exports

Décision du directeur du 11/10 : les graphiques des maquettes FIN-CPT-W01 à W06 et M01 à M03 sont voulus ; **DR-09 (« aucun graphique ») est levée**.

- **Dessin** : `CustomPainter` (aucune dépendance), couleurs des jetons existants seulement (`CouleursGraphiques`), `lib/core/widgets/comptable/graphiques/graphiques_comptable.dart`.
- **Montants masqués** : masqués, les graphiques ne se dessinent pas (la forme dirait le montant) ; les variations en % et les mini-courbes disparaissent avec eux (Q-9). Le tableau des valeurs, alternative accessible, garde ses montants masqués un à un.
- **Où** : anneau de répartition des coffres et évolution sur 6 mois dans Trésorerie ; entrées/sorties sur 6 mois et flux sur 30 jours dans l'onglet Rapports ; carte « Entrées et sorties » (total rendu par la source, variation, mini-courbe) dans Aujourd'hui (bureau et texte agrandi) ; barre de progression de la Réserve déjà présente (`JaugeSensible`).
- **Données** : `PortSeriesTresorerie` (rendues par la source, aucun calcul côté client). Production : `CapaciteIndisponible('CPT-BR-18')`, « en préparation » sur Rapports, rien dans Trésorerie et Aujourd'hui.
- **Exports** : « Exporter le rapport » (Rapports) et « Exporter la sélection » (barre de sélection de Paiements) par `PortExportRapports` (CPT-BR-19) ; sans capacité, une phrase à la place de l'action.
- **Écarts COMPTA-RECON-1 §3.2** : bouton « Voir le fil » (W07) ; section « Toujours sensible » (§21.4) du panneau de délégation ; états §49 « erreur partielle » (bande de Trésorerie) et « permission insuffisante » (`PermissionInsuffisante`) ; journal en erreur distinct de l'historique vide (`decision_validation.dart`) ; tests R-FIN-23 à 29. **Non fait, décision à prendre** : le champ « exceptions » du panneau de délégation (contrat à définir, COMPTA-RECON-1 §3.1).
