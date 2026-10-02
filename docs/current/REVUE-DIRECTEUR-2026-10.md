# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Choix du thème : un rectangle, trois bascules (soleil, système, lune) | THEME-SW-1 | `SelecteurTheme` (sur `ControleSegmente`) | `selecteur-theme-recompose` | `test/widgets/selecteur_theme_test.dart` |
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale`, `LienFleche`, `FilterPill`, `BoutonOutil`, `BoutonIcone`, `BoutonCommande`, `MenuActions` | `bouton-recompose` (4 formes) | `verifierBoutonCentre`, `verifierContenuCentre`, `verifierLibelleCentreLigneALigne` |
| Jamais de cartes collées (cartes séparées, ou une carte à lignes fines) | K-55 | `AppCard`, `Ecart`, `GroupeReglages` | `cartes-collees` | `verifierEcartCartes` |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche`, `RaccourciTactile` | `plein-multiple`, `bouton-grise` (alias `bouton-desactive`) | `verifierUnSeulBoutonPlein` |
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
| `bouton-recompose` | 2 (19 avec les quatre formes que le contrôle voit désormais) | 0 |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | 35 |
| `selecteur-theme-recompose` (THEME-SW-1) | 2 écrans recomposaient le thème (Apparence : 3 cartes `ChoiceCardGroup` ; Réglages : 3 lignes `Radio`) | 0 (les deux utilisent `SelecteurTheme`) |

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

### Preuves visuelles

`docs/current/captures/l1-boutons/` : `avant_*` (base `ad0e2c6`) et `apres_*` (cette branche), mêmes écrans, 320 et 1440 px, produits par `test/capture/l1_boutons_capture_test.dart` (`CAPTURE_DIR`, `CAPTURE_PREFIXE`) : préparation de l'enseignant (« Tester la caméra »), photo professionnelle (« Choisir une photo »), boutons du core (pilule étirée, bouton compact, lien, bouton secondaire). Les écrans de la salle (dock, outils, tuiles) ne sont pas capturés : leur preuve est la mesure de géométrie de `test/core/garde_interface_test.dart` (335 cas).
## ETATS-BTN-1 et NAV-FLECHES-1 : avant et après (branche `corrections/l1-salle`)

| Mesure | Avant | Après |
|---|---|---|
| Composants qui dessinent le disque d'une commande de salle (dock `BoutonAppel`, `_Commande` de `salle_page`) | 2, deux dessins différents | 1 (`CommandeSalle`, `BoutonAppel` et `_Commande` le délèguent) |
| Signaux d'état d'une bascule micro ou caméra du dock | 1 (l'icône) ; mot fixe « Micro », « Caméra », « Parler » | 3 (disque plein ou contour 2 points, icône barrée ou non, mot « Micro ouvert » / « Micro coupé », « Caméra allumée » / « Caméra éteinte ») |
| Signaux d'état d'une bascule de `salle_page` (micro, caméra, son reçu, agrandir) | 2 (remplissage, icône), sans mot d'état | 3 |
| Sites de bascule qui déclarent leur état (`bascule:`) | 0 | 8 (dock : 3 ; barre du support : 1 ; `salle_page` : 4) |
| Navigations précédent / suivant faites de deux boutons à libellé ou de chevrons grisés | 3 (lecteur de Coran, présentation de l'enseignant, pagination de la salle) | 0 : les 3 passent par `BarrePrecedentSuivant` |
| Flèche grisée au début ou à la fin | 3 sites | 0 : la flèche disparaît, sa place reste réservée |
| `bouton-grise` (`onPress: null` rendu grisé) | 73 | 69 |
| `verifier_jetons` | 36 | 36 |
| `cartes-collees`, `bouton-recompose`, `libelle-ambigu`, `mot-interne`, `erreur-sans-action` | 0 hors socle | 0 hors socle |

Limites : aucune action « couper le micro de toute la classe » n'existe dans l'application ; « Quitter » (dock, rail, en-tête guidé, `salle_page`) passe déjà par `ConfirmDestructive` (`confirmerQuitterSeance`) et le contrôle `bascule-sans-etat` ne vérifie que la présence de `bascule:`. Dans une rangée compacte et au-delà de 130 % d'échelle de texte, le mot d'état passe en infobulle et dans la voix du lecteur d'écran : à 200 % sur 390 px, deux lignes de mot par commande ne tiennent plus dans la hauteur du téléphone (test `salle_secours_test`, aucun débordement exigé). Les captures avant/après ne sont pas produites : les mesures de géométrie des tests (320 et 1440 px, texte ×1 et ×2) tiennent lieu de preuve.

## ETATS-BTN-1 et NAV-FLECHES-1 : corrections de la relecture (02/10/2026)

| Écart relevé | Correction |
|---|---|
| Agrandir / Réduire traité en bascule dans `salle_page` mais pas dans le dock de la séance ni dans la barre du support | `dock_seance.dart` passe `bascule: agrandi` ; `barre_support.dart` (`ZoomLocal`) remplace son bouton recomposé par `CommandeSalle(bascule: agrandi)`. Les deux sites, comme `salle_page`, ont le même rendu à trois signaux (disque plein ou contour, icône réduire / agrandir, mot « Réduire » / « Agrandir »). Test : `test/features/salle_seance/etats_agrandir_test.dart` (deux sites, deux états, clair et sombre). |
| Contrôle `bascule-sans-etat` trop faible (micro et caméra seulement) | Étendu à `_Commande`, aux icônes agrandir, réduire, son, et à **toute commande dont l'icône change avec l'état** (`x ? AppIcons.a : AppIcons.b`) : c'est le caractère à deux états qui compte. Sans la correction du dock, la règle signale bien 1 violation (vérifié en retirant la ligne). |
| Outil inactif du Teaching Dock sans contour | `BoutonOutil` inactif a le même contour fort de 2 points que la bascule de salle ; plein contrasté seulement quand l'outil est armé. Test : `test/teaching_core/d/bouton_outil_etat_test.dart`. |
| Valeurs littérales 2 et 1,3 dans `commande_salle.dart` | Jeton `AppContour.fort` (2 points, source : anneau de focus `Pressable.epaisseurFocus`, WCAG 2.4.11) et `AppContour.seuilTexteAgrandi` (1,3, source : `nav_shell` et Teaching Dock, doc 04 §28 et §33 n. 13), dans `lib/core/theme/app_contour.dart`. Référencés par `CommandeSalle` et `BoutonOutil`. |
| Désactivation : la bascule perdait son état visuel | Une bascule inerte garde sa forme : plein neutre quand elle est active, contour seul quand elle est inactive ; seule l'encre s'atténue (`inkMuted`). Le mot d'état reste. Test : `commande_salle_test.dart`, groupe « bascule inerte ». |
| Navigation du panneau enseignant : flèches disparues pendant une reconnexion | `BarrePrecedentSuivant` reçoit `actives` : **borne atteinte** = rappel nul = la flèche disparaît ; **commande momentanément inactive** = la flèche reste, inerte et atténuée. Le panneau passe `actives` au lieu d'annuler les rappels. Tests : `barre_precedent_suivant_test.dart` (cas `actives == false`, et borne maintenue) et `salle_enseignant_test.dart` (reconnexion). |
| Exhaustivité de la navigation (règle `nav-a-libelle` trop étroite) | La règle voit maintenant toute clé de libellé nommée précédent ou suivant hors des arguments de `BarrePrecedentSuivant`, et tout `AppIcons.suivant` hors du composant. Sites vérifiés à la main et admis (liste dans `tool/verifier_revue.dart`) : `t.foyer.ajout.suivant` (étape de formulaire), `t.dossiers.file.suivants`, `suivantAnnonce`, `suivantsErreur` (pagination de liste « Charger les dossiers suivants »), `t.enseignant.cahier.devoirPrecedent` (devoir de la séance d'avant). Sites migrés : `mushaf_page`, `panneau_enseignant`, `barre_support`. Les chevrons de ligne (`AppIcons.chevron`) et « Retour » ne sont pas des navigations de pages. |
| Action lourde « couper le micro de toute la classe » : preuve manquante | Commande : `git grep -niE "muteAll\|mute_all\|couperTous\|micro.*(tous\|toute la classe)\|(tous\|toute la classe).*micro\|setMicrophoneEnabled.*all\|muteParticipant\|mutePublished" -- lib test` (hors fichiers générés). Résultat : aucune occurrence dans `lib` ; une seule dans `test`, un commentaire sans rapport (`politique_observation_test.dart` : « micro, camera, publication data et admission : tous fermes »). L'action n'existe pas, donc aucune confirmation à poser ; si elle est créée, elle passera par `ConfirmDestructive`. |

### Décision à valider par le directeur : mot d'état au-delà de 130 % de texte

Dans une rangée compacte et au-delà de 130 % d'échelle de texte, le mot d'état d'une bascule passe en infobulle et dans la voix du lecteur d'écran. Il ne reste alors que deux signaux visibles (disque plein ou contour, icône), plus le mot parlé : « jamais la couleur seule » reste vrai, mais les trois signaux cumulés visibles ne tiennent pas. Cause mesurée : à 200 % sur 390 px, deux lignes de mot par commande ne tiennent plus dans la hauteur du téléphone (`salle_secours_test`, aucun débordement exigé). Choix provisoire consigné, sans blocage : dégradation acceptée sur ce seul palier, mot toujours lu à voix haute et en infobulle. Alternative à arbitrer : une rangée de commandes sur deux lignes à ce palier, au prix d'un dock plus haut. Aucune modification de l'exigence n'a été faite ; décision à dater par le directeur.
