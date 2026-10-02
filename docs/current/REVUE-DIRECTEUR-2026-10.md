# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale`, `LienFleche`, `FilterPill`, `BoutonOutil`, `BoutonIcone`, `BoutonCommande`, `MenuActions` | `bouton-recompose` (4 formes) | `verifierBoutonCentre`, `verifierContenuCentre`, `verifierLibelleCentreLigneALigne` |
| Jamais de cartes collées (cartes séparées, ou une carte à lignes fines) | K-55 | `AppCard`, `Ecart`, `GroupeReglages` | `cartes-collees` | `verifierEcartCartes` |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche`, `RaccourciTactile` | `plein-multiple`, `bouton-grise` (alias `bouton-desactive`) | `verifierUnSeulBoutonPlein` |
| Formulaires déduit > choisi > saisi | K-57 | `ChoiceCardGroup` | revue de fiche (FORM-AUTO-1) | |
| Tout choix : contexte, quand, conséquence, carte entière cliquable | K-58 | `ChoiceCardGroup` | revue de fiche | |
| Message d'erreur : cause et action | K-59 | `EtatSysteme`, `BlocAsynchrone` | `erreur-sans-action`, `affirmation-reseau` | |
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
| `bouton-recompose` | 2 (19 avec les quatre formes que le contrôle voit désormais) | 0 |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | |

Limites connues des contrôles (heuristiques de texte) : `cartes-collees` ne voit que des appels voisins dans une liste `children` sans `spacing:` (pas les `ListView.builder` sans séparateur) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

## Lot l1-boutons (BTN-CENTRE-1, BTN-TESTER-1, PHOTO-LIEN-1), 02/10/2026

Branche `corrections/l1-boutons`. Cause corrigée dans le core, jamais écran par écran.

### K-54 : contenu des boutons centré

Audit mesuré (test de géométrie, 320 et 1440 px, texte ×1 et ×2, clair et sombre, parent qui étire ou non) :

| Composant | Défaut mesuré avant | Correction |
|---|---|---|
| `FilterPill` | libellé collé en haut de la pilule de 48 (écart vertical de 6 px) ; libellé collé au début quand le parent étire la pilule | `Center(widthFactor: 1, heightFactor: 1)`, `Wrap` centré, `TextAlign.center` |
| `MenuFiltre` | libellé et chevron au début quand le parent étire le bouton (jusqu'à 640 px de décalage à 1440) | même centrage |
| `StatusPill` | contenu au début quand la pastille est étirée | `mainAxisAlignment: center`, texte centré |
| `ActionPrincipale` | `pleineLargeur: false` ignoré dans un parent `Align` ou `Column` : le bouton « compact » prenait 1408 px sur bureau (le `Container` à `alignment` s'étirait) ; libellé lu deux fois par le lecteur d'écran | `SizedBox` + `Center(widthFactor: 1)` : largeur du contenu ; texte exclu de la sémantique (le `Pressable` porte le nom) ; option `doux` (pilule d'alerte douce de la sortie de salle) |
| `LienFleche` | contenu au début sous la cible de 48 | `mainAxisAlignment: center`, `libelleSemantique`, `encre` |
| `MenuActions` | — | option `points` (déclencheur « … » du panneau de la salle) |

Composants ajoutés au core (aucun n'existait pour ces boutons) : `BoutonOutil` (icône et mot, `nue` ou `tuile`, déplacé de `features/tc_dock`), `BoutonIcone` (disque ou carré), `BoutonCommande` (disque et mot : micro, caméra, quitter), `RaccourciTactile`. Entrées de galerie et du catalogue ajoutées.

Boutons recomposés dans les écrans, remplacés par un composant du core : **16** (19 repérés par le contrôle élargi, dont 3 lignes de navigation ou de bandeau qui ne sont pas des boutons et sortent du contrôle une fois la règle précisée) :

| Écran | Avant | Après |
|---|---|---|
| `tc_dock` (`BoutonOutil`) | `Pressable` à fond peint | `core/widgets/bouton_outil.dart` |
| `salle_seance/outils_enseignement` | tuile peinte | `BoutonOutil` tuile |
| `salle_seance/panneau_eleves` | tuile peinte | `BoutonOutil` tuile |
| `salle_seance/dock_seance` (`BoutonAppel`) | disque peint | `BoutonCommande` |
| `salle/salle_page` (commandes) | disque peint | `BoutonCommande` |
| `salle/salle_page` (lien Présence) | `Pressable` à `Text` nu | `LienFleche` (encre du registre de la salle) |
| `salle_seance/salle_seance` (`BoutonPanneau`) | tuile peinte | `AppCard(onPress:)` |
| `salle_seance/selecteur_ressources` | `ChoiceChip` ; lignes peintes | `FilterPill` ; `AppCard(onPress:)` |
| `salle_seance/panneau_seance` | `PopupMenuButton` | `MenuActions(points: true)` |
| `tc_observation_ui/barre_commandes` (Quitter) | pilule peinte | `ActionPrincipale(destructive, doux)` |
| `tc_classe_live/roster_classe` (compteur) | `Pressable` à `Text` nu | `LienFleche` |
| `admin_dossiers/visionneuse_piece` | disque peint | `BoutonIcone` |
| `compte/carte_rubriques` | carré peint | `BoutonIcone` |
| `compte/compte_tuteur_page` (Se déconnecter) | bande peinte | `ActionPrincipale(destructive)` |
| `demo/demo_salle_page` | pilule peinte | `ActionPrincipale(secondaire, fleche)` |

Le contrôle `bouton-recompose` voit désormais quatre formes (bouton ou puce Material, `InkWell` ou `GestureDetector` qui réagit au toucher, `Pressable` à surface peinte autour d'un `Text` ou d'une `Icon`, `Pressable` à `Text` nu) ; un détecteur de glissement (`couche_annotation`, un dessin) n'est plus pris pour un bouton. Socle : 2 lignes avant, **0** après. Limite : une décoration passée par une variable à un `Pressable` échappe au contrôle de texte ; le test de géométrie la voit.

### BTN-TESTER-1

« Tester la caméra » (`preparation_enseignant.dart`) : `ActionPrincipale` secondaire pleine largeur, dernier enfant de la colonne de la carte (plus d'`Align` ni d'`IntrinsicWidth`). Test `test/features/classe_enseignant/btn_tester_camera_test.dart` : marges début, fin et bas égales, bouton sur toute la carte, libellé centré, 320 et 1440 px, ×1 et ×2, clair et sombre. Aucun bouton de test du micro ni du haut-parleur n'existe sur cette page ni sur la préparation de l'élève (vérifié) : rien d'autre à traiter.

### PHOTO-LIEN-1 et K-56

« Choisir une photo » devient une ligne `LienFleche` (texte et flèche, centrée verticalement, cible de 48) ; toucher la photo ouvre aussi le choix (`RaccourciTactile`, exclu du focus et de la sémantique : le lien reste le seul contrôle). Écrans : fiche élève (`foyer/photo_eleve.dart` : choisir, changer, choisir une autre ; « Envoyer cette photo » devient l'unique bouton plein de l'aperçu), photo professionnelle de l'enseignant (`photo_publique.dart` : choisir, remplacer, choisir une autre), profil enseignant (`profil_enseignant_page.dart`). Mêmes lignes de lien pour « Choisir un fichier » (`depot_piece_page.dart`) et « Scanner le QR code » (`saisie_code_page.dart`). Test : `test/features/profil_enseignant/photo_lien_test.dart`.

Inventaire (`ActionPrincipale` lus dans `lib/features`, commentaires exclus) :

| | Avant | Après |
|---|---|---|
| Fichiers avec au moins un `ActionPrincipale` | 84 | 87 |
| Boutons pleins (`principale`, explicite ou par défaut) | 85 | 85 |
| Fichiers avec plus d'un bouton plein (`plein-multiple`) | 15 | 14 |
| Actions secondaires en bouton secondaire pleine largeur | 36 (23 fichiers) | 33 (21 fichiers) |
| Boutons de photo ou de fichier en bouton plein ou secondaire pleine largeur | 7 | 0 (lignes de lien) |

Les 14 fichiers restants (dont `feuille_micro_bloque`, dont le niveau dépend d'une condition) ont été relus un à un : leurs boutons pleins sont dans des branches exclusives (`if / else`, `switch`, états successifs d'un parcours) ou dans des feuilles distinctes de la page qui les ouvre ; aucun n'est visible avec un autre. Ils sont figés dans le socle de `plein-multiple` avec leur nombre.

Contrôles ajoutés : `plein-multiple` (`tool/verifier_revue.dart`) et `verifierUnSeulBoutonPlein` (`test/support/garde_interface.dart`). Limite : le contrôle de source lit le texte, il ne sépare pas des branches exclusives de boutons simultanés ; seul le test de rendu voit ce que l'écran montre ensemble, d'où la garde à poser dans le test de chaque écran nouveau ou modifié.
