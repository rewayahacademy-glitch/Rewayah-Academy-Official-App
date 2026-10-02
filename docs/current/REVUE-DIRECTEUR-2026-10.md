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
| Jamais de rangée de sections qui défile (segmenté jusqu'à 4 sur téléphone, menu au-delà, en ligne si ça tient) | ONGLETS-1 | `SelecteurSection` (`ControleSegmente`, `MenuFiltre`) | `onglets-defilants` | `selecteur_section_test.dart` |
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
| `onglets-defilants` (nouveau, ONGLETS-1) | 4 détections de composant, soit 14 écrans (13 pages) servis par la barre défilante `SousNavigationDomaine`, 2 rangées de pastilles qui défilent (`surface_bibliotheque.dart`, `mushaf_page.dart`), 1 groupe de puces de section (`selecteur_ressources.dart`, non défilant, converti aussi) | 0 |
| `verifier_jetons` | 36 | 36 (aucune nouvelle) |

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## ONGLETS-1 : sections, onglets et pilules qui défilent (01/10/2026)

Constat du directeur : une rangée d'onglets qui défile ressemble à des diapositives, on ne devine pas qu'elle cache des sections et il faut défiler de gauche à droite pour les atteindre.

Règle (composant unique `SelecteurSection`, `lib/core/widgets/selecteur_section.dart`, bascule automatique selon le nombre de sections, la largeur disponible et l'échelle de texte) :

| Cas | Rendu |
|---|---|
| 2 à 4 sections sur téléphone (moins de 600 px) et chaque mot tient dans sa part de largeur | contrôle segmenté pleine largeur (`ControleSegmente`), un libellé trop long passe à la ligne |
| 5 sections et plus sur téléphone, ou un mot qui ne tient pas dans sa part (texte ×2, 320 px) | menu déroulant (`MenuFiltre` en mode `selecteurDeSection`) : section courante visible, liste complète au toucher avec coche sur la courante |
| Tablette et ordinateur, 7 sections au plus | contrôle segmenté en ligne, largeur naturelle, aligné au début (droite en arabe), si tout tient en une ligne |
| Plus de 7 sections | menu ; la page est à signaler (la découper), pas à découper dans le composant. Pages concernées au 02/10/2026 : aucune (maximum 5, Pédagogie) |

Sources UX (consultées le 02/10/2026) :

- Material Design 3, « Tabs » et « Segmented buttons » (m3.material.io) : des onglets fixes pour un petit nombre de destinations de même niveau, tous visibles ; des onglets défilants seulement quand il y a beaucoup de catégories, et jamais en remplacement d'un choix exclusif de peu d'options ; le bouton segmenté sert aux choix exclusifs de 2 à 5 options.
- Apple Human Interface Guidelines, « Tab bars » et « Segmented controls » (developer.apple.com/design/human-interface-guidelines) : une barre d'onglets pour 5 destinations au plus sur téléphone ; un contrôle segmenté pour un petit nombre de vues d'un même contenu ; au-delà, un menu (pull-down) qui nomme la sélection.
- Nielsen Norman Group, « Hidden navigation » et reconnaissance plutôt que rappel (nngroup.com) : ce qui est caché hors de la vue n'est pas découvert ; garder visible ce qui permet de se repérer.
- WCAG 2.2 AA, critère 1.4.10 (Reflow) : aucun défilement à deux dimensions à 320 px ; critère 2.5.8 (taille de cible) : cible de 24 px au moins, 48 ici.

Consigne du directeur appliquée : jusqu'à 4 sections sur téléphone, tout visible sans défilement ; au-delà, menu déroulant qui affiche la section courante et la liste au toucher ; sur grand écran, en ligne si ça tient.

Écrans convertis (avant / après) :

| Écran ou composant | Avant | Après |
|---|---|---|
| `SousNavigationDomaine` : Pédagogie (5 pages), Configuration (3 pages, 4 avec la politique KYC), Personnes (2), Sécurité et audit (2) : 14 emplacements | `TabBar` défilant | `SelecteurSection` (menu à 5 sur téléphone, segmenté à 2 ou 3 si les mots tiennent, en ligne sur grand écran) |
| Mode de lecture du Coran (`mushaf_page.dart`) | 3 pastilles dans une rangée qui défile | `SelecteurSection` (3 sections) |
| Supports de la salle enseignant (`selecteur_ressources.dart`) | 3 puces de section qui passent à la ligne, sans état annoncé comme groupe exclusif | `SelecteurSection` (3 sections) |
| Filtres de type de la bibliothèque (`surface_bibliotheque.dart`) | 5 pastilles de filtre multiples dans une rangée qui défile, filtres cachés | pastilles qui passent à la ligne (`Wrap`), aucun filtre caché (ce sont des filtres cumulables, pas des sections) |

Hors règle, signalés : `SelecteurProfils` (avatars des profils élèves en rangée qui défile, choix d'une personne et non d'une section) ; `TeachingDock` (barre d'outils de la salle, défilante quand la place manque, pas des sections).

Effet sur le banc d'accessibilité AD-11 : les quatre cas de la politique KYC (320 px, 390 px à 200 %, 1280 px à 400 %, Tab à 320 px), marqués « restes bloqués » parce que le libellé long de l'onglet était coupé, passent maintenant ; `_restes` est vide et l'exemption « hors barre d'onglets » du contrôle de reflux est retirée.
