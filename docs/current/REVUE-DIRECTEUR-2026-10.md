# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale` | `bouton-recompose` | `verifierBoutonCentre` |
| Jamais de cartes collées (cartes séparées de 16 au moins, ou une carte à lignes fines) | K-55 | `PileCartes`, `CarteGroupee`, `CarteLignes`, `GroupeReglages`, `AppCard`, `Ecart` | `cartes-collees` (`tool/revue_cartes.dart`, `test/tool/revue_cartes_test.dart`) | `verifierEcartCartes`, `verifierAucuneCarteCollee` (`test/core/cartes_collees_test.dart`) |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche` | `bouton-grise` (alias `bouton-desactive`) | revue d'écran |
| Formulaires déduit > choisi > saisi | K-57 | `ChoiceCardGroup` | revue de fiche (FORM-AUTO-1) | |
| Tout choix : contexte, quand, conséquence, carte entière cliquable | K-58 | `ChoiceCardGroup` | revue de fiche | |
| Message d'erreur : cause et action | K-59 | `EtatSysteme`, `BlocAsynchrone` | `erreur-sans-action`, `affirmation-reseau` | |
| Aucun élément ne recouvre un contenu | déduite | | | `verifierSansChevauchement` |
| Hiérarchie de titres stricte : titre d'écran > titre de section > nom / titre de carte > corps, marque sous le titre | déduite (HIER-1) | `AppTypography`, `EntetePage`, `PageShell`, `SectionHeader`, `MarquePage` | `test/theme/hierarchie_titres_test.dart` | `verifierHierarchie` |
| État jamais par la couleur seule | déduite | `StatusPill` | revue d'écran | |
| Alerte urgente en tête | déduite | | revue d'écran | |
| Libellé sans ambiguïté (qui, quoi) | déduite | | `libelle-ambigu` | |
| Aucun mot interne chez le client | déduite | | `mot-interne` | |

## Chiffres au 02/10/2026 (branche `corrections/revue-directeur-2026-10`, base `integration/essai-fusion` 55a5235)

Avant correction, par contrôle (`dart run tool/verifier_revue.dart --regle=<nom> --detail`) :

| Contrôle | Occurrences avant | Après |
|---|---|---|
| `cartes-collees` | 5 (ancienne règle) ; 46 (règle étendue, même base) | 0 |
| `bouton-recompose` | 2 | |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | |

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` lit le code (`tool/revue_cartes.dart`) : cartes voisines, boucles `for` et `.map`, variables et méthodes qui rendent une carte, widgets dérivés, listes nommées posées dans `children:`, `ListView.builder` et `.separated`, boîtes peintes à la main ; il ne voit pas une carte construite par un appel dynamique ni un `GridView` de widgets variables (les tuiles vidéo de la salle, à 8, en font partie : ce sont des tuiles de présence) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## Lot l1-cartes : CARTES-ECART-1 (K-55) et HIER-1

Branche `corrections/l1-cartes`, base `corrections/revue-directeur-2026-10` ad0e2c6. Cause commune : le contrôle d'origine ne voyait que 5 appels `StatTile` (tous dans une liste posée dans un `Wrap` à 12) ; les cartes collées du directeur étaient ailleurs, dans des piles de `SettingRow` sans écart et des listes à 4, 8 ou 12.

**CARTES-ECART-1 (K-55).** Écart minimal fixé à 16 (`Ecart.vLg`, celui des écrans du tuteur), 8 pour des pastilles de choix, jamais 0, 4, 8 ou 12 entre deux cartes de contenu.

| Mesure | Avant | Après |
|---|---|---|
| Cas vus par le détecteur étendu (`cartes-collees`) | 46 | 0 |
| dont cartes collées (écart 0) | 31 | 0 |
| dont cartes à écart insuffisant (4, 8, 12) | 15 | 0 |
| Fichiers concernés | 16 (15 écrans, 1 composant du core : `ChoiceCardGroup`) | 0 ; `SettingRow` gagne le rendu à plat |
| Tests de géométrie sur écrans réels (320 et 1440 px, texte ×1 et ×2, clair et sombre) | 5 échecs sur 5 (tableau de bord, réglages, compte, profil, `ChoiceCardGroup`) | 0 échec |
| Socle `cartes-collees` | 5 lignes | 0 |

Composants créés : `PileCartes` (cartes indépendantes, 16 au moins, assertion), `CarteGroupee` (une carte, sections à filet `FiletCarte`), `CarteLignes` (une carte de lignes `SettingRow` et `ConfigLigne...`, rendues à plat via `LigneDansCarte`). `GroupeReglages` reste le composant des rubriques à icône. Écrans convertis : réglages et portail du compte, profil personnel, profil enfant, hub Compte tuteur (`espaces_compte`), réglages de l'enfant, réglages d'observation, trois pages de configuration de la direction, tableau de bord de la direction, attribution, demandes, offres de parcours, avant et après cours, navigation du Coran. `ChoiceCardGroup` passe de 12 à 16.

**HIER-1.** Un niveau de texte par rôle, chaque niveau strictement plus grand que le suivant (`lib/core/theme/app_typography.dart`).

| Défaut | Avant | Après |
|---|---|---|
| Accueil public, 320 px : marque / titre | 36 / 32 (la marque dépassait le titre) | 22 / 32 |
| Accueil public, 1440 px : marque / titre | 36 / 36 (même taille) | 22 / 36 |
| Connexion, récupération, attente, dépôt de pièce, démarrage (`MarquePage`, 6 emplacements) | marque 36 | marque 22 |
| `SectionHeader` (49 emplacements hors galerie) / titre d'`EntetePage` sur téléphone | 28 / 28 | 22 / 28 |
| Échelle enfant : `headlineSmall` / `titleLarge` | 32 / 32 | 32 / 28 |
| Échelle enfant : `headlineMedium` / `headlineSmall` | 32 / 32 | 34 / 32 |
| Échelle enfant : `titleMedium` / corps | 18 / 20 (titre sous le corps) | 22 / 20 |
| Titres de section et de ressource posés en `headlineSmall` sous un titre d'écran de même rang | 2 (Journée « À terminer », détail de ressource) | 0 |
| `test/theme/hierarchie_titres_test.dart` sur la base | 8 échecs sur 14 | 0 échec |

Règle écrite : `lib/CLAUDE.md`, « Hiérarchie de titres stricte » ; garde : `verifierHierarchie` (`test/support/garde_interface.dart`).

Captures avant et après, 320 px et 1440 px : `docs/current/captures/l1-cartes/avant` et `apres` (réglages du compte, tableau de bord de la direction, accueil public).
