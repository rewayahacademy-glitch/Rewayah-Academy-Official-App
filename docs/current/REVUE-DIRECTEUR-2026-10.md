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
| Libellé sans ambiguïté (qui, quoi) | déduite | | `libelle-ambigu` | |
| Aucun mot interne chez le client | déduite | | `mot-interne` | |
| Avatar : petit cercle (jetons `AppAvatar`), centré avec son nom sur le même axe, jamais de carré derrière, une ligne de rôle au plus (AVATAR-1) | 01-02/10 | `AvatarNom`, `AvatarSansImage`, `AvatarTile` | `avatar-recompose`, `avatar-taille` | `verifierMemeAxe`, `verifierAlignes`, `verifierContenu` |
| La mention « visite de contrôle possible » n'est pas rendue au contrôleur (CTRL-SALLE-1) | 02/10 | `_Bandeaux` (salle) | | `test/features/controleur/salle_controleur_test.dart` |

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
| `avatar-recompose` (AVATAR-1, nouveau) | 21 | 0 |
| `avatar-taille` (AVATAR-1, nouveau) | 16 | 0 |

AVATAR-1 : 31 couples avatar + nom recensés dans `lib/` hors `_dev` (26 passés par `AvatarNom` ou `AvatarSansImage`, 5 lignes de rubrique `GroupeReglages` dont l'avatar de tête passe aux jetons) ; 0 restant. Le contrôle `avatar-recompose` ne détecte que les couples posés dans une `Row`, une `Column` ou un `Wrap` (21 avant) ; les autres (cercle d'initiales recomposé dans `chrome_seance.dart`, avatar dans un `Stack` de `selecteur_profils.dart` et `panneau_eleves.dart`) ont été recensés à la main. Tailles d'avatar : 10 valeurs distinctes avant (32, 40, 44, 48, 56, 64, 72, 80, 96, et 144 en mode enfant pour la taille par défaut) ; 3 après (`AppAvatar` : 32, 48, 64). Preuve de géométrie : `test/core/widgets/avatar_nom_test.dart` (31 tests : axe commun en vertical, nom centré sur le cercle en ligne, cercle contenu dans un cadre de 96x128 et 176x126, 320 et 1440 px, texte x1 et x2, clair et sombre) et `avatar_ligne_rubrique_test.dart` (8 tests).

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.
