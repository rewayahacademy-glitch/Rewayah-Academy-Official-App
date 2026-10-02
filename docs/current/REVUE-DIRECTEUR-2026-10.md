# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale` | `bouton-recompose` | `verifierBoutonCentre` |
| Jamais de cartes collées (cartes séparées, ou une carte à lignes fines) | K-55 | `AppCard`, `Ecart`, `GroupeReglages` | `cartes-collees` | `verifierEcartCartes` |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche` | `bouton-grise` (alias `bouton-desactive`) | revue d'écran |
| Formulaires déduit > choisi > saisi | K-57 | `ChoiceCardGroup` | revue de fiche (FORM-AUTO-1) | |
| Tout choix : contexte, quand, conséquence, carte entière cliquable | K-58 | `ChoiceCardGroup` | revue de fiche | |
| Message d'erreur : cause et action | K-59 | `EtatSysteme`, `BlocAsynchrone` | `erreur-sans-action`, `affirmation-reseau` | |
| Aucun élément ne recouvre un contenu | déduite | | | `verifierSansChevauchement` |
| Hiérarchie de titres stricte | déduite | `EnteteDePage`, `SectionHeader` | revue d'écran | |
| État jamais par la couleur seule | déduite | `StatusPill` | revue d'écran | |
| Alerte urgente en tête | déduite | | revue d'écran | |
| Navigation du Mode Accessibilité : moins de destinations, libellé visible, cibles de 72, actif à trois signaux, mêmes routes | MA-NAV-1 | `NavShell` | `nav-recomposee` | `nav_shell_accessibilite_test.dart` |
| Libellé sans ambiguïté (qui, quoi) | déduite | | `libelle-ambigu` | |
| Aucun mot interne chez le client | déduite | | `mot-interne` | |

## Chiffres au 02/10/2026 (branche `corrections/revue-directeur-2026-10`, base `integration/essai-fusion` 55a5235)

Avant correction, par contrôle (`dart run tool/verifier_revue.dart --regle=<nom> --detail`) :

| Contrôle | Occurrences avant | Après |
|---|---|---|
| `cartes-collees` | 5 | |
| `bouton-recompose` | 2 | |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | |
| `nav-recomposee` (MA-NAV-1, barres hors des coquilles du core) | 0 | 0 |

### MA-NAV-1 : barre de navigation du Mode Accessibilité

| Mesure | Avant | Après |
|---|---|---|
| Destinations de l'élève dans la barre (Mode Accessibilité) | 4 | 3 (Accueil, Ma classe, Mon espace ; le Coran reste atteint par le bloc permanent de l'Accueil) |
| Présentations de la barre basse | 1 (standard dans les deux modes) | 2 (standard, guide) |
| Hauteur d'un onglet (guide) | environ 64 | 72 au moins |
| Icône (guide) | 24 | 32 |
| Libellé du rail replié (guide) | infobulle ou 12 pt borné | toujours visible, 14 pt, trois lignes |
| Signaux de l'onglet actif | 3 (encre d'accent, icône pleine, soulignement de 3) | 3 dont un fond plein (fond, icône pleine, gras) |
| Barres de navigation recomposées hors du core | 0 | 0 (contrôle `nav-recomposee`) |

Barres vérifiées : barre basse, rail, barre latérale de `NavShell` (tous rôles) ; `AdminShell` (rôle adulte, hors Mode Accessibilité, déjà lié à `AppMetriques.cibleTactile`).

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## MA-NAV-1, corrections de relecture

- Contrôle `nav-recomposee` : le motif lit maintenant les blancs (`\s*`) ; test `test/tool/verifier_revue_nav_test.dart`.
- Contour du guide : constante nommée `NavShell.epaisseurContourGuide`.
- Texte agrandi : plafond du guide relevé de 1,0 à 1,3 (`echelleTexteMaxGuide`), libellés sans ellipse ; test arabe à 320, ×2, RTL.
- Preuve visuelle : `docs/current/captures/MA-NAV-1/` (`avant` = ad0e2c6, `apres` ; élève, clair/sombre, 320, 320 ×2, tablette, bureau ; harnais `test/capture/ma_nav1_capture_test.dart`).
- À trancher par le directeur : le Coran n'est plus dans la barre de l'élève en Mode Accessibilité (accès par le bloc Coran de l'Accueil) ; confirmer qu'aucun autre écran n'exige un accès direct. Le plafond 1,3 est un choix de conception.
