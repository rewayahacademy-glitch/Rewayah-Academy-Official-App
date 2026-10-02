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
| Bascule de la salle : trois signaux (disque plein ou contour, icône, mot d'état), actions lourdes confirmées | ETATS-BTN-1 (K-54, K-56) | `CommandeSalle` | `bascule-sans-etat` | `commande_salle_test.dart` |
| Navigation précédent / suivant : flèche, position, flèche, la flèche disparaît aux bornes, miroir RTL | NAV-FLECHES-1 (K-54, K-56) | `BarrePrecedentSuivant` | `nav-a-libelle` | `barre_precedent_suivant_test.dart` |
| Aucun élément ne recouvre un contenu | déduite | | | `verifierSansChevauchement` |
| Hiérarchie de titres stricte | déduite | `EnteteDePage`, `SectionHeader` | revue d'écran | |
| État jamais par la couleur seule | déduite | `StatusPill` | revue d'écran | |
| Alerte urgente en tête | déduite | | revue d'écran | |
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

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## ETATS-BTN-1 et NAV-FLECHES-1 : avant et après (branche `corrections/l1-salle`)

| Mesure | Avant | Après |
|---|---|---|
| Composants qui dessinent le disque d'une commande de salle (dock `BoutonAppel`, `_Commande` de `salle_page`) | 2, deux dessins différents | 1 (`CommandeSalle`, `BoutonAppel` et `_Commande` le délèguent) |
| Signaux d'état d'une bascule micro ou caméra du dock | 1 (l'icône) ; mot fixe « Micro », « Caméra », « Parler » | 3 (disque plein ou contour 2 points, icône barrée ou non, mot « Micro ouvert » / « Micro coupé », « Caméra allumée » / « Caméra éteinte ») |
| Signaux d'état d'une bascule de `salle_page` (micro, caméra, son reçu, agrandir) | 2 (remplissage, icône), sans mot d'état | 3 |
| Sites de bascule qui déclarent leur état (`bascule:`) | 0 | 6 (dock : 2 ; `salle_page` : 4) |
| Navigations précédent / suivant faites de deux boutons à libellé ou de chevrons grisés | 3 (lecteur de Coran, présentation de l'enseignant, pagination de la salle) | 0 : les 3 passent par `BarrePrecedentSuivant` |
| Flèche grisée au début ou à la fin | 3 sites | 0 : la flèche disparaît, sa place reste réservée |
| `bouton-grise` (`onPress: null` rendu grisé) | 73 | 69 |
| `verifier_jetons` | 36 | 36 |
| `cartes-collees`, `bouton-recompose`, `libelle-ambigu`, `mot-interne`, `erreur-sans-action` | 0 hors socle | 0 hors socle |

Limites : aucune action « couper le micro de toute la classe » n'existe dans l'application ; « Quitter » (dock, rail, en-tête guidé, `salle_page`) passe déjà par `ConfirmDestructive` (`confirmerQuitterSeance`) et le contrôle `bascule-sans-etat` ne vérifie que la présence de `bascule:`. Dans une rangée compacte et au-delà de 130 % d'échelle de texte, le mot d'état passe en infobulle et dans la voix du lecteur d'écran : à 200 % sur 390 px, deux lignes de mot par commande ne tiennent plus dans la hauteur du téléphone (test `salle_secours_test`, aucun débordement exigé). Les captures avant/après ne sont pas produites : les mesures de géométrie des tests (320 et 1440 px, texte ×1 et ×2) tiennent lieu de preuve.
