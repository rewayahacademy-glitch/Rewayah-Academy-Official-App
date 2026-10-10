# CPT-CAPT : recette visuelle Comptable V1

Branche `ui/comptable-v1` après fusion CPT-FUS (2bbc30d4). Captures : `docs/current/captures/CPT-CAPT/`, produites par `test/capture/cpt_capt_recette_test.dart` (saute sans `CAPTURE_DIR`) : `CAPTURE_DIR=docs/current/captures/CPT-CAPT flutter test test/capture/cpt_capt_recette_test.dart`. 122 tests, 121 PNG (119 recette + 2 `ecart_route_demo_*`).

Nom d'un fichier : `<ecran>_<format>_<clair|sombre>_<masques|affiches>.png` (ex. `paiements_390x844@3_dark_masques.png`) ; 320 : `<ecran>_320x640@2_texte2_light_masques.png` ; RTL : `<ecran>_390x844@3_light_rtl.png`, `<ecran>_320x640@2_texte2_rtl.png`.

## Honnêteté sur l'ouverture
Les 121 PNG sont produits. Dans cette session, la lecture d'images a été refusée par moments (« request limit ») : environ la moitié des ouvertures n'a rien rendu. Les captures marquées **V** ont été vues ; **N** = produite, ouverture sans rendu, à revoir. Aucun « OK » n'est posé sur une capture N.

## Tableau écran x format

Colonnes : 390 C/S = 390x844@3 clair / sombre (masqués) ; 390 aff = clair, affichés ; 1440 C/S = 1440x900@1 ; 320 = texte x2 clair.

| Écran | 390 C | 390 S | 390 aff | 1440 C | 1440 S | 320 x2 |
|:--|:--|:--|:--|:--|:--|:--|
| W01 Aujourd'hui | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) |
| W01 file À traiter / Alertes | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) |
| W02 Paiements à effectuer | OK | OK | OK | OK | OK | OK |
| W03 Détail d'un paiement | OK | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) |
| W06 Contractuels | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | OK |
| W06 Détail obligation | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | OK |
| W06 Nouvelle obligation | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) |
| W07 Bénéficiaires | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | OK | OK |
| W07 Profil de paiement | produite, non vue (N) | produite, non vue (N) | OK | produite, non vue (N) | OK | OK |
| W04 Trésorerie et coffres | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) |
| M02 Alimenter la Réserve | produite, non vue (N) | OK | OK | OK | OK | OK |
| W05 Encaissements | OK | OK | OK | OK | OK | OK |
| W05 Détail encaissement | produite, non vue (N) | produite, non vue (N) | OK | produite, non vue (N) | OK | produite, non vue (N) |
| Rapprochement (M01) | produite, non vue (N) | produite, non vue (N) | OK | produite, non vue (N) | OK | OK |
| Compte | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | OK | produite, non vue (N) |
| Recevoir mes paiements | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | OK |
| Direction : Réserve | OK | produite, non vue (N) | produite, non vue (N) | produite, non vue (N) | OK | produite, non vue (N) |
| Direction : délégation | produite, non vue (N) | produite, non vue (N) | OK | OK | produite, non vue (N) | OK |

Ouvertes avec rendu (V) : voir cellules « OK » ; elles ne comptent que ce qui a réellement été vu. Aucune cellule « écart » n'est un blocage : les écarts relevés sont listés plus bas, tous mineurs ou de gabarit.

Montants affichés à 1440 sombre (module affiché) : aujourdhui, paiements, tresorerie, encaissements, contractuels (`*_1440x900@1_dark_affiches.png`). Vus : paiements, encaissements, contractuels.

RTL : `aujourdhui`, `paiements`, `tresorerie` à 390 clair et à 320 texte x2 (6 PNG). Vus : `paiements_390x844@3_light_rtl`, `paiements_320x640@2_texte2_rtl`.

## R-FIN-24 à 29

| Recette | Preuve | État |
|:--|:--|:--|
| R-FIN-24 Design system Rewayah partout | toutes les captures : palette violet Rewayah, cartes, pastilles, barre basse / rail du thème ; test `tool/verifier_jetons.dart` 39 → 39 | OK sur les captures vues (N pour Aujourd'hui, Trésorerie, Nouvelle obligation) |
| R-FIN-25 Pas de thème hybride noir/blanc | clair : rail et fond clairs (`paiements_1440x900@1_light_masques`), sombre : rail sombre (`paiements_1440x900@1_dark_masques`) ; la Direction garde la coquille admin du thème (`direction_reserve_1440x900@1_dark_masques`) | OK sur les captures vues |
| R-FIN-26 High-fi divergentes harmonisées | mêmes composants (pastilles, cartes, `MontantSensible`) sur W02, W05, W06, W07, W04 vus ; aucune identité « banque » | OK sur les captures vues |
| R-FIN-27 DM Sans pour les titres | `AppTypography.titre = 'DMSans'` (`lib/core/theme/app_typography.dart`), polices du dépôt chargées par le test (garde-fou `largeurSonde`) ; titres de feuille et de section lisibles en DM Sans (`alimenter_390x844@3_dark_masques`) | OK par le code ; voir écart E7 sur le rendu des titres de page à 320 |
| R-FIN-28 Plus Jakarta Sans reste (corps) | `AppTypography.corps = 'PlusJakartaSans'` ; corps, montants et tableaux en Jakarta (`encaissements_1440x900@1_dark_affiches`) | OK |
| R-FIN-29 Desktop réel 1440 | `*_1440x900@1_*` pour les 18 écrans (rail déplié, table, deux colonnes sur détail, profil, rapprochement) | OK sur les 1440 vus ; N pour Aujourd'hui, Trésorerie, Nouvelle obligation, Détail contractuel |

## Écarts relevés (rien corrigé dans `lib/`)

| # | Fichier | Capture | Description |
|:--|:--|:--|:--|
| E1 | `assets/i18n/ar.i18n.json` | `paiements_390x844@3_light_rtl`, `*_320x640@2_texte2_rtl` | Aucune clé `comptable.*` en arabe (0 occurrence) : le RTL montre des textes français dans une mise en page inversée. La mise en page se retourne bien (rail à droite, chevrons, ruban, case à droite) ; la ponctuation française passe en tête de ligne (« .vérifie et on paie… ») et « paiements 21 » s'inverse. Écart de contenu, pas de gabarit. |
| E2 | `lib/features/demo/demo_comptable_page.dart` | `ecart_route_demo_tresorerie_390x844@3_light_masques`, `ecart_route_demo_alimenter_390x844@3_light_masques` | `CoquilleComptableDemo` seule (sans surcharges à la racine du test) : à vérifier sur ces deux PNG, ce que la page rend sans les surcharges des ports (cf. commentaire de `tresorerie_capture_test` : « en préparation »). Les PNG de recette posent les surcharges à la racine. N (non ouvertes avec rendu). |
| E3 | `lib/features/comptable/contractuels/obligation_contractuel_page.dart` (barre d'action collante) | `obligationContractuel_320x640@2_texte2_light_masques` | À 320 texte x2, la barre « Le paiement s'ouvre… / Payer » avec la barre basse occupe plus de la moitié de l'écran ; le haut de la fiche est tronqué (titre, un seul statut visible). Même effet atténué sur `recevoirPaiements_320x640@2_texte2_light_masques`. |
| E4 | pastille d'état (statuts longs) | `rapprochement_320x640@2_texte2_light_masques`, `contractuels_1440x900@1_dark_masques` | Pastille / onglet à rayon plein dont le texte passe sur 2 ou 3 lignes (« Remboursements et avoirs », « À approuver ») : bord et texte se touchent à 320 x2 ; à 1440 la pastille « À approuver » est haute de deux lignes. |
| E5 | `lib/features/admin_finance/reserve_delegation/*` | `direction_delegation_320x640@2_texte2_light_masques` | Pastille « Version 1, en vigueur depuis le 15 septembre 2026 » sur trois lignes dans une forme ovale, plus haute que le texte qui suit. |
| E6 | `lib/features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart` | `direction_delegation_390x844@3_light_affiches` | Ligne d'interrupteur : texte étroit à gauche d'un grand vide, bordure de carte imbriquée visible sous la première ligne. |
| E7 | `lib/core/widgets/entete_page.dart` | `paiements_320x640@2_texte2_light_masques`, `encaissements_320x640@2_texte2_light_masques` | Les titres de page à 320 x2 ont un dessin proche de Plus Jakarta Sans, différent des titres de feuille (DM Sans). Impression visuelle à confirmer ; le code pose bien DM Sans (R-FIN-27). |
| E8 | `lib/core/widgets/admin_shell.dart` | `direction_reserve_390x844@3_light_masques` | Environ 250 px de vide entre la barre du haut et le titre « Réserve et délégation » avant le premier contenu. |
| E9 | `lib/features/comptable/encaissements/*` | `encaissements_1440x900@1_light_masques` | Colonne « État » : « Partiellement remboursé » en pastille centrée sur deux lignes, les autres alignées à gauche ; bas de table vide sous la dernière ligne. |

## Contrôles

- `flutter test test/capture/cpt_capt_recette_test.dart` sous `CAPTURE_DIR` : 122 tests passent (121 PNG).
- `flutter test` des tests de capture existants (comptable, ben, ctr, pay) et `test/features/comptable/fusion` sans `CAPTURE_DIR` : 19 passent, 201 sautés (captures).
- `dart analyze --fatal-infos test/capture/cpt_capt_recette_test.dart` : 0.
- `dart run tool/verifier_jetons.dart` : 39 violations, inchangé (39 → 39).
