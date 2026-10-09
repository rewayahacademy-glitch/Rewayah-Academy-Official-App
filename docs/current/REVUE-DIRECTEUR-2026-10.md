# Revue du directeur des 01 et 02/10/2026 : table des règles et des preuves

Remplace la table §4 BIS de `docs/design/README.md`, absent de la branche `integration/essai-fusion` (déplacé dans `docs/archive/2026-09-pre-remise-a-plat/design/README.md` à la remise à plat). Les règles écrites sont dans `lib/CLAUDE.md`, section « Interdits d'interface (revue directeur 01-02/10) ». Source : consignes K-54 à K-59 du tableau « Suivi Rewayah ».

Principe : corriger la cause (composant partagé de `lib/core`), recenser tous les écrans au même défaut ou à un défaut équivalent, écrire la règle et son contrôle, noter le chiffre avant et après.

| Règle | Consigne | Composant partagé | Contrôle automatique | Test de garde |
|---|---|---|---|---|
| Choix du thème : un rectangle, trois bascules (soleil, système, lune) | THEME-SW-1 | `SelecteurTheme` (sur `ControleSegmente`) | `selecteur-theme-recompose` | `test/widgets/selecteur_theme_test.dart` |
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale`, `LienFleche`, `FilterPill`, `BoutonOutil`, `BoutonIcone`, `BoutonCommande`, `MenuActions` | `bouton-recompose` (4 formes) | `verifierBoutonCentre`, `verifierContenuCentre`, `verifierLibelleCentreLigneALigne` |
| Jamais de cartes collées (cartes séparées, ou une carte à lignes fines) | K-55 | `AppCard`, `Ecart`, `GroupeReglages` | `cartes-collees` | `verifierEcartCartes` |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche`, `RaccourciTactile` | `plein-multiple`, `bouton-grise` (alias `bouton-desactive`) | `verifierUnSeulBoutonPlein` |
| Contenu de bouton centré, sans débordement | K-54 | `ActionPrincipale` | `bouton-recompose` | `verifierBoutonCentre` |
| Jamais de cartes collées (cartes séparées de 16 au moins, ou une carte à lignes fines) | K-55 | `PileCartes`, `CarteGroupee`, `CarteLignes`, `GroupeReglages`, `AppCard`, `Ecart` | `cartes-collees` (`tool/revue_cartes.dart`, `test/tool/revue_cartes_test.dart`) | `verifierEcartCartes`, `verifierAucuneCarteCollee` (`test/core/cartes_collees_test.dart`) |
| Un seul bouton plein par écran, secondaires en lien flèche | K-56 | `ActionPrincipale`, `LienFleche` | `bouton-grise` (alias `bouton-desactive`) | revue d'écran |
| Formulaires déduit > choisi > saisi | K-57 | `ChoiceCardGroup` | revue de fiche (FORM-AUTO-1) | |
| Tout choix : contexte, quand, conséquence, carte entière cliquable | K-58 | `ChoiceCardGroup` | revue de fiche | |
| Message d'erreur : cause et action | K-59 | `EtatSysteme`, `BlocAsynchrone` | `erreur-sans-action`, `affirmation-reseau` | |
| Bascule de la salle : trois signaux (disque plein ou contour, icône, mot d'état), actions lourdes confirmées | ETATS-BTN-1 (K-54, K-56) | `CommandeSalle` | `bascule-sans-etat` | `commande_salle_test.dart` |
| Navigation précédent / suivant : flèche, position, flèche, la flèche disparaît aux bornes, miroir RTL | NAV-FLECHES-1 (K-54, K-56) | `BarrePrecedentSuivant` | `nav-a-libelle` | `barre_precedent_suivant_test.dart` |
| Jamais de rangée de sections qui défile (segmenté jusqu'à 4 sur téléphone, menu au-delà, en ligne si ça tient) | ONGLETS-1 | `SelecteurSection` (`ControleSegmente`, `MenuFiltre`) | `onglets-defilants` | `selecteur_section_test.dart` |
| Bouton principal d'une séance selon son moment, jamais grisé | CTA-FIN-1 | `ctaSeance`, `EmplacementEntree`, `LienFleche` | `bouton-grise` | `test/core/enseignant/cta_seance_test.dart`, `test/features/journee_test.dart` |
| Aucun élément ne recouvre un contenu | déduite | | | `verifierSansChevauchement` |
| Hiérarchie de titres stricte : titre d'écran > titre de section > nom / titre de carte > corps, marque sous le titre | déduite (HIER-1) | `AppTypography`, `EntetePage`, `PageShell`, `SectionHeader`, `MarquePage` | `test/theme/hierarchie_titres_test.dart` | `verifierHierarchie` |
| État jamais par la couleur seule | déduite | `StatusPill` | revue d'écran | |
| « En direct » et « Annulée » reconnaissables d'un coup d'œil, partout | ON-AIR-1, ANNUL-VIS-1 | `PastilleEtatSeance`, `TexteHeureSeance`, `LigneRaisonSeance`, `surfaceCarteSeance` | `etat-seance-pastille` | `test/core/widgets/pastille_etat_seance_test.dart` |
| Alerte urgente en tête (tri gravité puis date, section en tête du Centre de commande, bandeau figé tout en haut de l'écran jusqu'au traitement, sans recouvrir la page, point sur la cloche) | déduite ; ALERTE-1 (01/10, décision du 05/10) ; ALERTE-1b (réserves, décidé par délégation le 05/10) | `trierAlertes`, `SectionAlertes`, `BandeauAlerteUrgente` (forme courte sur vue basse), `AdminShell.bandeau` (`_ZoneBandeau`), `ClocheNotifications` | revue d'écran ; captures `docs/current/captures/ALERTE-1b/` | `test/core/alertes/alertes_test.dart`, `test/features/alertes/alertes_ecrans_test.dart`, `test/features/alertes/alerte1b_test.dart` |
| Présentation publique avant la connexion : 5 pages, une idée par page, défilement automatique (6 s, pause au toucher, au survol, au focus, aucun sous mouvement réduit ou lecteur d'écran), glissement, croix pour tout passer, vue une fois par appareil | PUB-1 (décision déléguée du 05/10, fiche `UX_REVIEW_PUB-1.md`) | `BienvenuePage`, `presentationProvider`, `BarrePrecedentSuivant`, `BoutonIcone`, `MarquePage` (sans coupure) | revue d'écran | `test/features/bienvenue/presentation_test.dart` |
| Navigation du Mode Accessibilité : moins de destinations, libellé visible, cibles de 72, actif à trois signaux, mêmes routes | MA-NAV-1 | `NavShell` | `nav-recomposee` | `nav_shell_accessibilite_test.dart` |
| Libellé sans ambiguïté (qui, quoi) | déduite | | `libelle-ambigu` | |
| Aucun mot interne chez le client | déduite | | `mot-interne` | |
| Avatar : petit cercle (jetons `AppAvatar`), centré avec son nom sur le même axe, jamais de carré derrière, une ligne de rôle au plus (AVATAR-1) | 01-02/10 | `AvatarNom`, `AvatarSansImage`, `AvatarTile` | `avatar-recompose`, `avatar-taille` | `verifierMemeAxe`, `verifierAlignes`, `verifierContenu` |
| La mention « visite de contrôle possible » n'est pas rendue au contrôleur (CTRL-SALLE-1) | 02/10 | `_Bandeaux` (salle) | | `test/features/controleur/salle_controleur_test.dart` |

## Chiffres au 02/10/2026 (branche `corrections/revue-directeur-2026-10`, base `integration/essai-fusion` 55a5235)

Avant correction, par contrôle (`dart run tool/verifier_revue.dart --regle=<nom> --detail`) :

| Contrôle | Occurrences avant | Après |
|---|---|---|
| `cartes-collees` | 5 | |
| `bouton-recompose` | 2 (19 avec les quatre formes que le contrôle voit désormais) | 0 |
| `cartes-collees` | 5 (ancienne règle) ; 46 (règle étendue, même base) | 0 |
| `bouton-recompose` | 2 | |
| `libelle-ambigu` | 5 | |
| `mot-interne` | 4 | |
| `erreur-sans-action` | 27 | |
| `bouton-grise` | 73 (53 dans le socle hérité de `main`) | |
| `affirmation-reseau` | 10 (6 dans le socle hérité de `main`) | |
| `libelle-sans-source` | 1377 (1023 dans le socle hérité de `main`) | |
| `verifier_jetons` | 36 | 35 |
| `selecteur-theme-recompose` (THEME-SW-1) | 2 écrans recomposaient le thème (Apparence : 3 cartes `ChoiceCardGroup` ; Réglages : 3 lignes `Radio`) | 0 (les deux utilisent `SelecteurTheme`) |
| `verifier_jetons` | 36 | |
| `avatar-recompose` (AVATAR-1, nouveau) | 21 | 0 |
| `avatar-taille` (AVATAR-1, nouveau) | 16 | 0 |

AVATAR-1 : 31 couples avatar + nom recensés dans `lib/` hors `_dev` (26 passés par `AvatarNom` ou `AvatarSansImage`, 5 lignes de rubrique `GroupeReglages` dont l'avatar de tête passe aux jetons) ; 0 restant. Le contrôle `avatar-recompose` ne détecte que les couples posés dans une `Row`, une `Column` ou un `Wrap` (21 avant) ; les autres (cercle d'initiales recomposé dans `chrome_seance.dart`, avatar dans un `Stack` de `selecteur_profils.dart` et `panneau_eleves.dart`) ont été recensés à la main. Tailles d'avatar : 10 valeurs distinctes avant (32, 40, 44, 48, 56, 64, 72, 80, 96, et 144 en mode enfant pour la taille par défaut) ; 3 après (`AppAvatar` : 32, 48, 64). Preuve de géométrie : `test/core/widgets/avatar_nom_test.dart` (31 tests : axe commun en vertical, nom centré sur le cercle en ligne, cercle contenu dans un cadre de 96x128 et 176x126, 320 et 1440 px, texte x1 et x2, clair et sombre) et `avatar_ligne_rubrique_test.dart` (8 tests).

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
| Navigations précédent / suivant faites de deux boutons à libellé ou de chevrons grisés | 3 (lecteur de Coran, présentation de l'enseignant, pagination de la salle) | 0 : les 3 passent par `BarrePrecedentSuivant`. Exception depuis INTEG-RC-1 (03/10/2026) : le lecteur de Coran du Mode Accessibilité (`LecteurCoranAccessibilite`, MA-CMD-1) a ses propres flèches en icônes seules ; elles suivent la même règle (la flèche disparaît aux bornes, sa place reste réservée), test `coran_ma7_test.dart` « NAV-FLECHES-1 » |
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

**Contradiction ouverte, à arbitrer par le directeur (relevée à INTEG-RC-1, 03/10/2026).** La décision déléguée du 02/10/2026 (`DECISIONS_DELEGUEES_2026-10-02.md`) dit « le mot d'état reste » au-delà de 130 % (WCAG 1.4.1). Le code ne l'applique pas encore : `CommandeSalle` masque le mot d'une bascule dans une rangée compacte au-delà de 130 %, et avec MA-CMD-1 (demande du directeur, « des flèches et sans texte, compacte en bas ») toutes les commandes du dock sont compactes en Mode Accessibilité. `salle_ma5_test.dart` (×2) vérifie aujourd'hui ce comportement provisoire, pas la décision. Essai mesuré en gardant le mot visible dans la rangée compacte : en Mode Accessibilité à 390 px et ×2, en-tête 152 + commandes 140 = 292, au-delà de la limite de 30 % de MA-CMD-1 (253) ; salle de l'enseignant à 390 px et ×2 (`salle_secours_test`, `salle_secours_bandeau_test`), débordement de 34 à 51 px ; panneau Élèves à 320 px et ×2, 22 px. L'essai n'est donc pas livré. Il faut choisir : (a) le mot reste et le dock passe sur deux rangées ou le support cède de la hauteur (MA-CMD-1 à relâcher) ; (b) MA-CMD-1 prime en Mode Accessibilité et la décision du 02/10 est reprise par une décision datée.
Limites connues des contrôles (heuristiques de texte) : `cartes-collees` lit le code (`tool/revue_cartes.dart`, qui reconnaît aussi `ElementEchelonne`, les `itemBuilder` à plusieurs `return`, les `child` ternaires, les séparateurs conditionnels, les éléments `if` facultatifs et les boîtes peintes par `.decoration(` nommées `Carte...`, et ne baisse plus à 8 le minimum d'une liste `separated`) : cartes voisines, boucles `for` et `.map`, variables et méthodes qui rendent une carte, widgets dérivés, listes nommées posées dans `children:`, `ListView.builder` et `.separated`, boîtes peintes à la main ; il ne voit pas une carte construite par un appel dynamique ni un `GridView` de widgets variables (les cadres vidéo de la salle, à 8, en font partie : flux média plein cadre, sans marge ni action, donc pas des cartes ; le panneau d'élèves de la salle, lui, passe à 16) ; `bouton-recompose` ne voit que les boutons Material, `InkWell`, `GestureDetector` et un `Pressable` qui peint lui-même fond arrondi et `Text`. Ce que ces contrôles ne voient pas se mesure par les tests de géométrie et par les captures à 320 px et 1440 px.

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

**Relecture CARTES-ECART-1 (exhaustivité).** Le détecteur laissait passer des piles à moins de 16 : `ElementEchelonne` n'était pas une enveloppe reconnue, les listes `separated` abaissaient le minimum à 8, un `build` à variables avant le `return` n'était pas dérivé, un `child` ternaire, un `itemBuilder` à plusieurs `return`, un séparateur conditionnel, une carte suivie d'un `if` et une boîte peinte par `.decoration(` n'étaient pas vus. Détecteur corrigé, un test par angle mort (`test/tool/revue_cartes_test.dart`), dépôt relevé de nouveau : 5 cas avant correction, 0 après.

| Écran | Avant | Après | Garde de géométrie |
|---|---|---|---|
| Bibliothèque de ressources (`surface_bibliotheque.dart`) | 12 | 16 | `bibliotheque_page_test.dart`, 320 et 1440 px |
| Attribution, enseignants proposés (`attribution_page.dart`) | 8 | 16 | `attribution_admin_test.dart`, 700 et 1400 px |
| Catalogue de classes (`catalogue_classes_page.dart`) | 12 | 16 | `catalogue_classes_test.dart`, 320 et 1440 px |
| Profils de connexion élève (`eleve_connexion_page.dart`) | 12 en colonnes et en rangées | 16 | `eleve_connexion_test.dart`, 320 et 1440 px |
| Panneau d'élèves de la salle (`panneau_eleves.dart`) | 4 ou 8 | 16 | `panneau_eleves_test.dart`, trois gabarits |
| Galerie vidéo de la salle | 8 | 8 (non carte : flux média plein cadre, sans marge ni titre ni action) | |

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
## Pastille d'état de séance (ON-AIR-1, ANNUL-VIS-1)

Demande du directeur (01 et 02/10/2026) : une séance en cours et une séance annulée se reconnaissent au premier coup d'œil, partout où une séance apparaît avec un statut, tous rôles. Partie interface seulement : l'état « en direct » reste calculé côté serveur, les notifications temps réel (« Votre classe est ouverte : rejoignez-la ») et leur délai mesuré sont hors de cette étape.

Cause : chaque écran posait à la main une `StatusPill` (disque et mot) ou un point de couleur, sans battement pour « En direct », et la carte annulée du tuteur prenait tout le fond `washAlert`. Correction : un composant partagé unique, `lib/core/widgets/pastille_etat_seance.dart`.

| Élément | Règle | Source des valeurs |
|---|---|---|
| `PastilleEtatSeance(enDirect)` | pilule douce `washSuccess`, point de statut qui bat doucement, puis reste fixe | `AppMouvement.pulsationDirect` (1500 ms), `pulsationCourbe` (`easeInOut`), `battementsDirect` (3) |
| Réduire les animations | point fixe d'emblée, aucun halo, le mot « En direct » reste | `AppMouvement.mouvementReduit` |
| `PastilleEtatSeance(annulee)` | pilule `washAlert` (le ton d'alerte des jetons, aucun rouge inventé), icône d'annulation (`AppIcons.interdit`), mot « Annulée » | `palette.washAlert`, `pointsStatut` |
| `TexteHeureSeance` | heure barrée et atténuée (`inkMuted`), annoncée « Annulée : {valeur} » au lecteur d'écran (formule neutre : heure, plage ou date), une seule annonce par carte (`annoncer`) | `palette.inkMuted` |
| `surfaceCarteSeance` | carte annulée sur `surfaceSunken`, jamais une opacité (le texte garde son contraste) | `palette.surfaceSunken` |
| `LigneRaisonSeance` | une ligne : pourquoi et, quand la donnée existe, la suite (« Aucun remplaçant trouvé · séance non facturée ») ; rien n'est inventé ; sans motif connu, « Motif non communiqué » | clés `etat.raisonEtSuite`, `etat.motifNonCommunique` |

Nouveaux jetons de mouvement (aucun jeton existant ne convenait : `pulsation` vaut 1,2 s et est réservée à l'imminence ELV-02) : `AppMouvement.pulsationDirect`, `AppMouvement.battementsDirect`, `AppMouvement.pulsationCourbe`, `AppMouvement.ampleurHaloDirect` (1,2, multiple du diamètre) et `AppMouvement.opaciteHaloDirect` (0,45). Les deux derniers étaient des littéraux dans le widget : ils sont dans les jetons de mouvement, documentés ici (`docs/current` n'a pas de fichier `design-tokens.md` ; celui de `docs/archive/` est un historique qu'on ne modifie pas).

Choix à connaître : le battement s'arrête après trois cycles (4,5 s), sous les 5 s au-delà desquelles WCAG 2.2.2 exige une commande d'arrêt, comme le `PointRappel` de K-45. Pour un battement sans fin, il suffit de remplacer `battementsDirect` ; le test `dit le mot et bat doucement, puis reste fixe` est alors à adapter.

Emplacements recensés (une séance apparaît avec un statut) et convertis au composant :

| # | Emplacement | Rôle | « En direct » | « Annulée » |
|---|---|---|---|---|
| 1 | `ChildCard` (accueil du tuteur) | tuteur | converti | converti, carte atténuée |
| 2 | Accueil élève (`accueil_eleve_page`) | élève | converti | converti |
| 3 | Ma journée, carte « Séance en direct » (`journee_page`) | enseignant | converti | |
| 4 | Ma journée, cours annulé du jour (`_CarteCoursAnnule`, avant les autres alertes) | enseignant | | converti : pastille, horaire barré, surface enfoncée, ligne « Motif non communiqué » |
| 5 | Ma journée, carte de séance avec absence « Séance annulée » (`PastilleAbsence`) | enseignant | | converti : horaire barré, surface enfoncée, « Aucun remplaçant trouvé · séance non facturée » |
| 6 | Carte de séance de la Classe (`carte_seance_classe`) | tuteur | converti | converti, heures barrées, carte atténuée |
| 7 | Planning de la classe (`planning_classe_page`) | tuteur | converti | converti, heures barrées |
| 8 | Dernière séance (`ligne_derniere_seance`) | tuteur | converti | converti, date barrée |
| 9 | Carte de séance de l'Espace Classe (`carte_session`, `EmplacementEntreeVue`) | élève, tuteur, enseignant, adulte | converti | converti, heures barrées, carte atténuée |
| 10 | Mes groupes (`carte_groupe`) | élève, enseignant, adulte | converti | |
| 11 | Barre « Cours en cours » (`barre_cours_en_cours`) | enseignant, élève | converti | |
| 12 | Salle d'observation (`panneau_observation_tuteur`) | tuteur | converti | |
| 13 | Entête de la salle du contrôleur (`salle_page`, 2 appels) | contrôleur | converti | |
| 14 | Mission du contrôleur (`controle_page`) | contrôleur | converti | |
| 15 | Sélecteur de profils (`selecteur_profils`, point) | tuteur | converti (point qui bat) | converti : `PointAnnulation` (icône d'annulation à la place du point) et mot |
| 16 | Suivi de l'élève (`suivi_eleve_page`) | élève | | converti |
| 17 | Historique, liste (`composants_historique`) | tuteur | | converti, horaire barré |
| 18 | Historique, détail d'une séance (`detail_seance_page`) | tuteur | | converti : pastille, horaire barré (`LigneCleValeur(annulee)`), carte enfoncée |

Non convertis, et pourquoi : la pastille de connexion de la salle (`chrome_seance`, « En ligne » est l'état du lien, pas celui de la séance) ; les statuts d'évaluation de la direction (`evaluations_page`, l'évaluation annulée n'est pas une séance) ; les écrans de démonstration (`features/demo`) rendent les vrais composants.

Contrôle automatique : `etat-seance-pastille` (`tool/verifier_revue.dart`) échoue sur toute `StatusPill` qui porte le mot « En direct » ou « Annulée » hors de `pastille_etat_seance.dart`.

Chiffres :

| Mesure | Avant | Après |
|---|---|---|
| `StatusPill` posées à la main avec le mot « En direct » ou « Annulée » (contrôle `etat-seance-pastille`) | 6 | 0 |
| Emplacements recensés, tous états | 18 | 18 convertis |
| Pastilles « En direct » qui battent | 0 | 14 appels (13 emplacements) |
| Emplacements « Annulée » au composant (icône d'annulation, heure barrée là où une heure s'affiche, carte atténuée là où il y a une carte) | 0 | 11 emplacements |
| `verifier_jetons` | 36 | 36 |
| `cartes-collees`, `bouton-recompose`, `libelle-ambigu`, `mot-interne`, `erreur-sans-action` | 0 nouvelle | 0 nouvelle |

### Correction après relecture (ON-AIR-1, ANNUL-VIS-1)

| Point relevé | Correction |
|---|---|
| Annonce « Prévue à … » posée sur des dates et des métas | clé `etat.annuleeValeur` (« Annulée : {valeur} »), paramètre `annoncer` : une seule annonce par carte (planning, carte de séance de l'Espace Classe) ; test sur une date |
| « En direct » détecté en comparant des mots traduits (`salle_page`) | `_etatDuLien` rend un type (`EtatPastilleSeance?`) ; le composant se choisit sur ce type |
| Annulée : emplacements à la pastille seule | journée enseignant (carte de séance et cours annulé du jour), détail d'historique, sélecteur de profils, `ChildCard` (pourquoi et suite) : convertis |
| `LigneRaisonSeance` presque inutilisée | branchée dans `ChildCard`, la carte de séance de l'Espace Classe, la journée enseignant ; la suite est passée là où la donnée existe |
| Halo en littéraux dans le widget | `AppMouvement.ampleurHaloDirect`, `AppMouvement.opaciteHaloDirect` |
| Tests | rendus testés : journée enseignant, carte famille, carte de séance de l'Espace Classe, sélecteur de profils, `LigneCleValeur` |

**Dépendances de donnée (BR-1), consignées plutôt que contournées** :

- Le serveur ne rend ni le motif d'une annulation ni sa suite (remplaçant cherché, facturation) pour une séance annulée par l'administration. Les écrans disent « Motif non communiqué » ; ils n'inventent rien. Seul le cas « absence de l'enseignant sans remplaçant » a sa phrase complète, parce que l'état `aucunRemplacant` puis `seanceAnnulee` existe déjà côté absence. Quand le contrat exposera motif et suite, ils se branchent sur `LigneRaisonSeance(raison, suite)` sans autre changement.
- `ChildCard` : `EnfantSeanceAnnulee(motif, propose)` n'est construit aujourd'hui que par la galerie ; l'accueil du tuteur passe par `carte_seance_classe`, dont la ligne d'état est la raison.

**Exceptions justifiées, à valider par le directeur** : la carte « Prochaine séance » de la journée enseignant ne montre jamais une séance annulée (`prochainCours` l'écarte) : le cas est porté par la carte du cours annulé du jour. L'horaire du détail de séance du suivi du foyer est barré mais la carte n'a pas de ligne « pourquoi » (la phrase « La séance a été annulée. » reste, sans motif en donnée).

**ON-AIR-1 reste partiellement faite.** Livré : la pastille « En direct » partout, avec son battement borné. Non livré : la notification « Votre classe est ouverte : rejoignez-la » (une par séance, délai mesuré), le bandeau si l'application est ouverte, le lien profond vers la salle, et la mise à jour en temps réel. Tout cela dépend de BR-1 (serveur, notifications, canal temps réel) ; l'étape ne doit pas passer en « fait » avant.
| `nav-recomposee` (MA-NAV-1, barres hors des coquilles du core) | 0 | 0 |

### MA-NAV-1 : barre de navigation du Mode Accessibilité

| Mesure | Avant | Après |
|---|---|---|
| Destinations de l'élève dans la barre (Mode Accessibilité) | 4 | 4 (Accueil, Ma classe, Coran, Mon espace) : le retrait du Coran (3 destinations) est annulé par la décision déléguée du 02/10/2026 (`DECISIONS_DELEGUEES_2026-10-02.md`), appliquée à INTEG-RC-1 |
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
- Coran dans la barre de l'élève en Mode Accessibilité : la demande MA-NAV-1 de le retirer est annulée par la décision déléguée du 02/10/2026 (« le Coran reste », 4 destinations : Accueil, Ma classe, Coran, Mon espace ; une destination essentielle dans une académie de Coran). Appliqué à INTEG-RC-1 (03/10/2026). **Accord écrit du directeur à obtenir** : c'est l'annulation d'une demande qu'il avait faite lui-même ; il peut la reprendre par une décision datée. Le plafond 1,3 est un choix de conception.
## CTA-FIN-1 : le bouton principal d'une séance selon son moment (02/10/2026)

Demande du directeur (commentaire du 01/10) : le bouton d'une séance n'est jamais désactivé, il change de sens.

| Moment | Bouton | Avant la correction |
|---|---|---|
| Avant l'ouverture de la salle | « Préparer la séance » | idem |
| Salle ouverte, jusqu'à la fin et au-delà tant que la salle est ouverte | « Rejoindre la salle » (+ pastille « En direct » dès l'heure de début) | « Préparer l'entrée » |
| Temps écoulé, cahier non déposé | « Remplir le cahier de transmission » + rappel « Obligatoire » | carte absente (« Aucune séance à venir »), cahier seulement dans « À terminer » |
| Cahier déposé | « Voir le cahier » en lien discret | carte absente |
| Séance annulée ou absence déclarée | « Voir la Classe » | idem |

Cause corrigée dans le composant partagé : `lib/core/enseignant/cta_seance.dart` (fonctions pures `ctaSeance` et `seanceDeLaCarte`, fenêtre d'accès et grâce lues de la base, jamais redéclarées), `EmplacementEntree` (libellé enseignant unique pour la Journée et la fiche de la Classe), `EmplacementEntreeVue` (un bouton de bureau ne déborde plus de sa carte en texte agrandi).

Chiffres (avant, après) : états du bouton de la carte « Prochaine séance » de l'enseignant, 4 libellés dont 1 hors des moments demandés, puis 5 états tous nommés ; libellés différents pour la même action « entrer en salle » côté enseignant, 2 (« Préparer l'entrée » en Classe, rien en Journée pendant le cours) puis 1 (« Rejoindre la salle ») ; débordements mesurés à 320 px en texte ×2 sur la carte de séance, 1 (en-tête nom et pastille) puis 0 ; débordements mesurés à 1440 px en texte ×2 (bouton « Remplir le cahier de transmission »), 1 puis 0 ; tests de transitions, 0 puis 20 (unitaires) et 25 (widget).

Recensé, non repris ici (autre lot) : le bouton « Rejoindre » de l'élève hors ligne reste présent et inerte (`accueil_eleve_page.dart`, décision documentée dans le code), compté par `bouton-grise`.

## PAGESHELL-200-1d : réserves de PAGESHELL-200-1c (05/10/2026)

Branche `corrections/c2-pageshell-d`, issue de `corrections/revue-directeur-2026-10` (6e2c91c4). Statut : **testé localement** seulement ; ni staging, ni déploiement.

**Décision (décidé par délégation le 05/10, règle DIR-REP-1, consigne la plus récente du directeur).** Sur téléphone à 200 % de texte, la page défile pour le reste. L'ancienne règle « barre entière au premier affichage à 200 % » (PAGESHELL-200-1) est remplacée ; écrit aussi dans `03_DESIGN_SYSTEM_ET_UX.md` (« Coquille de page et texte agrandi »). À 100 %, la barre reste entière au premier affichage quand la salle tient (test « barre entière au premier affichage », 390x844 et 414x896).

| Réserve | Ce qui est fait | Preuve |
| :--- | :--- | :--- |
| 1. Vignettes cachées dans le défileur imbriqué | Plus de repère : tout le contenu de la zone (en-tête, support, vignettes) est le minimum utile ; `DefileurCorps` perd le paramètre `repere`. Au bout de la page : support, vignettes, barre. | `salle_observation_test`, groupe « PAGESHELL-200-1d : les vignettes défilent avec la page » (7 vues x LTR/RTL, 320 à 414 px, 100 et 200 %, standard et Interface guidée) : 14 échecs sur la base 6e2c91c4. `page_shell_hauteur_corps_test` : zone de 650 sans rien de caché. |
| 2. `_hauteurMinSupport` non gardé | Pas redondant : avec « Agrandir », le support est seul dans la zone, sans défileur qui garantit sa hauteur. Gardé. | `salle_support_agrandi_test` (support réel, 320x568 et 360x640 à 200 %) : 3 échecs si le `minimumEtire` du téléphone revient à `AppTouchTarget.standard` ; groupe « support agrandi à sa hauteur lisible » : 2 échecs si celui de la carte large y revient. |
| 3. Captures 1440 et 390x844 à 100 %, 320x568 à 100 % | `docs/current/captures/PAGESHELL-200-1d/` (16 PNG, haut et bout, clair, sombre, RTL, Interface guidée ; plus 390x844 et 320x568 à 200 % au bout), script archivé. | PNG ouverts : 1440 inchangé, barre au premier affichage ; 390x844 à 100 % tient sans défiler ; au bout, vignettes entières au-dessus de la barre. |
| 4. Ligne du décompte qui débordait (6 px à 320x568 100 %, 1,3 px à 390x844 130 % guidée) | Déjà corrigé par PAGESHELL-200-1c (4a879cbd, `Wrap`). Groupe étendu au RTL et à 320x568 à 200 %, sans mot coupé. | Groupe « bandeau du décompte sans débordement » : 5 échecs avec le `compteur_visite.dart` de 397ef11d (6 ; 1,3 ; 31 ; 71 px). |
| 5. `_vueForcee` jamais réévaluée à vue égale | Un corps forcé qui tient de nouveau sous la tête fixe fait reprendre la tête fixe à la fin de l'image, après revérification des sources et une fois les animations en cours finies (boîte de dialogue qui se referme). | `page_shell_hauteur_corps_test` : « un corps qui rapetisse… » et « sous une boîte de dialogue… » échouent sur la base. Sans l'attente des animations, `fin_visite_test` 844x390 casse l'arbre sémantique (2 échecs) ; sans la revérification, 1024x900 à 300 % oscille (`pumpAndSettle` expiré). |

Contrôles : `dart analyze --fatal-infos` 0 ; `verifier_revue` 1550 (base 1550) ; `verifier_jetons` 39 (base 39). Aucun libellé touché. Champ serveur : aucun besoin.
## SUPERPOS-1 : superpositions et zone de saisie (05/10/2026, branche `corrections/c2-superpos`)

**Décisions prises par délégation le 05/10** (règle DIR-REP-1, aucune question au directeur) :

- Écran non identifié par le commentaire : **audit de tous les écrans** de la branche commune où un bandeau, une pastille ou un élément flottant peut recouvrir un contenu à lire, et de tous les champs multilignes. Décidé par délégation le 05/10.
- Un bandeau prend sa place dans le flux et pousse, ou se ferme ; jamais peint par-dessus. Le repère « Démonstration » devient une bande en tête, dans le flux ; **clavier ouvert, elle se ferme** (la place va au contenu), et revient clavier fermé. Décidé par délégation le 05/10.
- Une seule zone de saisie multiligne dans le produit : `ZoneSaisie` (`lib/core/widgets/zone_saisie.dart`). Rayon, fond, filet et marges du thème ; étiquette au-dessus du champ (jamais flottante sur le filet) ; aide et erreur jamais coupées ; hauteur qui grandit avec le texte, bornée aux deux cinquièmes de la vue visible ; bouton d'envoi **intégré au champ et centré** en hauteur ; jamais grisé (absent tant que le champ est vide, sa place gardée, la raison écrite sous le champ). Décidé par délégation le 05/10.
- Cartes côte à côte : quand un mot d'un libellé ne tient pas dans une carte (320 en texte double), les cartes s'empilent, pleine largeur, même anatomie. Décidé par délégation le 05/10.
- **En-tête compact selon l'échelle HIER-1** (`EnteteCompact`, `lib/core/widgets/entete_page.dart`) : au-delà de 130 % de texte ou sous 600 de haut, le titre d'écran grandit avec le texte mais seulement jusqu'à un palier (2) au-dessus d'un titre de section (`titleLarge`) lui aussi agrandi, jamais sous la taille du thème ; le sous-titre descend d'un rang du corps (`bodyMedium`, toujours agrandi) et prend toute la largeur sous la rangée du titre ; quand le mot le plus long du titre ne tient pas à côté du disque retour et des actions, ceux-ci passent sur une rangée au-dessus ; un nom composé du titre (« Al-Badr ») ne se coupe plus après son trait d'union (en mode compact seulement : ailleurs la coupure au trait d'union de la typographie française, « es- / tu », est gardée et le texte rendu reste le texte donné). Le clavier ne compte pas (la structure ne bascule pas à son ouverture, même règle que `PageShell`). Décidé par délégation le 05/10.
- Fil de discussion : le contexte compact ne redit plus la Classe et la date déjà écrites au titre (« Contexte joint à vos messages : séance de 17:00 ») ; quand la page entière défile (texte double, vue basse), l'arrivée montre la saisie et le dernier message, l'en-tête passant au-dessus (comme toute messagerie) ; la liste garde au moins la hauteur d'une bulle de deux lignes à l'échelle du texte (220 à 320 ×2, au lieu d'un minimum fixe de 96). Décidé par délégation le 05/10.
- Lecteur du Coran du Mode Accessibilité (`CommandesMasquables`, arbitrage face à MA-CMD-1 du 02/10) : au toucher, MA-CMD-1 reste tel quel (les commandes passent par-dessus le bas du Mushaf quelques secondes, puis se ferment : « ou se ferme ») ; avec lecteur d'écran ou au clavier, elles ne se ferment jamais, donc elles passent **sous** le Mushaf, dans le flux (`placeReservee`). Le rendu du Coran n'est pas touché : seul son cadre raccourcit. Décidé par délégation le 05/10 (choix le plus prudent : la demande du 05/10 est la plus récente, MA-CMD-1 est gardé là où il ne recouvre rien en permanence).
- Un seul point d'attention : un écran n'a qu'une zone pleine (l'action principale) ; les bandeaux (« Démonstration », hors ligne, alerte urgente) sont au registre doux et dans le flux. Décidé par délégation le 05/10 (règle existante du bandeau hors ligne, étendue au repère).

**Méthode.** Test de non-chevauchement par rectangles (`verifierSansChevauchement`) à 320 ×2 en LTR et RTL, 390 et 1440, clavier ouvert (inset de 300) là où il y a une saisie ; mots entiers vérifiés par les boîtes de sélection de chaque mot ; garde de source : aucun `TextField` multiligne hors de `ZoneSaisie` (`test/core/widgets/zone_saisie_unique_test.dart`, 18 fichiers en défaut sur la base, 0 après).

### Écrans et composants audités, verdict

| Écran ou composant | Élément | Constat (avant) | Verdict après |
|---|---|---|---|
| Toutes les pages de l'aperçu (`RepereDemonstration`) | ruban « Démonstration » | ruban d'angle peint par-dessus : couvrait le bouton du compte (coque admin) à 320 ×2 et le début du titre en arabe | **corrigé** : bande en tête, dans le flux ; fermée clavier ouvert (sinon 14 px de débordement sous la feuille de refus à 320 × 640, clavier de 300) |
| Échanges du contrôleur (`FilDiscussion`) | champ et bouton « Envoyer » | 134 px de débordement à 320 ×2 clavier ouvert ; bouton à côté du champ, grisé à vide ; étiquette flottante coupée | **corrigé** : `ZoneSaisie` avec envoi intégré et centré, `ColonneCorps` ; en-tête de contexte compact (une phrase) à texte agrandi ou vue basse |
| Refus de dossier (admin, 02D) | motif | étiquette flottante en ellipse à 390 et 200 % | **corrigé** : `ZoneSaisie` |
| Cahier de séance (enseignant) | position de reprise, objectif, devoir | reprise : texte qui défilait de côté sur une ligne, aide coupée « d'un rempla… » à 320 ×2 | **corrigé** : `ZoneSaisie` (touche « terminé », le texte passe à la ligne), aide entière |
| Complément et observation du contrôleur | texte du document | étiquette flottante | **corrigé** : `ZoneSaisie` |
| Signalement de besoin (fiche élève), signalement du Teaching Core, correction de présence, panneau d'après cours | champs multilignes | étiquettes flottantes, aides bornées à 2 lignes | **corrigé** : `ZoneSaisie` |
| Administration : programmes, attribution, demandes, classes, progression, évaluations, qualité, diagnostics ; réglages de l'enfant | motifs et notes | champs de 2 lignes fixes, étiquette flottante | **corrigé** : `ZoneSaisie` |
| Inscription, étape Genre (`ChoiceCardGroup` côte à côte) | radio en haut de carte | radio dans un `Stack`, par-dessus le disque de l'icône à 320 ; « hom / me » coupé à 320 ×2 | **corrigé** : radio sur sa ligne ; cartes empilées quand un mot ne tient pas |
| En-tête de page (`EntetePage`), toutes les pages à en-tête riche | titre, sous-titre, disque retour | à 320 ×2, titre de 56 (« Dossiers à valider ») et sous-titre de 32 à côté du disque : l'en-tête prenait plus de la moitié de l'écran ; un titre long réduit à 43,5 (sous un titre de section agrandi, 44) et coupé « Al- / Badr » | **corrigé** : en-tête compact HIER-1 ; « Dossiers à valider » : titre 46, en-tête de 242 (38 % de 640) |
| Fil des échanges à l'arrivée (320 ×2) | titre, contexte, liste, saisie | titre sur 4 lignes, contexte qui redisait Classe et date, une tranche de bulle, saisie sous la pliure | **corrigé** : contexte sans redite, saisie entière et dernier message lisible (200 au moins) à l'arrivée |
| Lecteur du Coran, Mode Accessibilité (`CommandesMasquables`, `coran_accessibilite.dart`) | rangée de commandes en bas | posée par-dessus le bas du Mushaf ; toujours visible avec lecteur d'écran ou clavier, donc recouvrement permanent (390 ×2 : 80 px du Mushaf sous les commandes) | **corrigé** : dans le flux, sous le Mushaf, quand elle est toujours visible ; au toucher, MA-CMD-1 garde (par-dessus puis fermée) |
| Feuille de demande des réglages de l'enfant (Interface guidée, 320 ×2) | colonne de la feuille | débordement de 256 (standard) à 710 px (guidée) : bouton d'envoi hors d'atteinte | **corrigé** : la feuille défile |
| Aide du champ vide de `ZoneSaisie` | aide | « administratio / n… » à 320 ×2 (aide du fil du contrôleur) | **corrigé** : aide rendue sans coupure de mot |
| Champs d'une ligne : invitation du conjoint, identité d'un profil élève, saisie du code | aides et erreurs bornées à 2 ou 3 lignes | à 320 ×2 : aide du courriel (« … rejoindre Rewayah. ») et aide de l'âge à l'ellipse ; « e- / mail » coupé dans l'erreur du courriel ; saisie du code : déjà entière | **corrigé** : bornes portées à `ZoneSaisie.lignesAideMax` (8), « e‑mail » insécable |
| Bandeau hors ligne, bandeau d'observation, bandeau d'alerte urgente | bandeaux | déjà dans le flux (`PageShell`, `RewayahApp`) | conforme, non modifié |
| Un seul point d'attention (repère, bandeaux, fil, zone de saisie) | zones pleines | repère « Démonstration » en `washAccent` (doux), bandeaux hors ligne et alerte au registre doux, alerte absente sous l'Accueil (D7) ; dans le fil, le seul élément d'accent est l'icône d'envoi, rendue seulement quand il y a un texte | conforme (lu dans le code et sur les captures, pas de test dédié) |
| Cloche (point de notifications), sélecteur de profils (point d'état), tuiles vidéo d'observation (nom, micro), résultat de visite (badge) | pastilles | posées sur une icône, un avatar ou une image, jamais sur un texte | conforme |
| Pastille « En direct », point de rappel | halo animé | halo translucide et bref, coupé en mouvement réduit | conforme (décoratif) |
| Vignette de ressource (catalogue) | icône de type sur le monogramme | couverture décorative (exclue de la sémantique) | conforme |
| Lecteur de QR (`scanner_page`) | barres sur le viseur | le viseur n'est pas un contenu à lire | conforme |
| Anneau de focus (`Pressable`), grille bento | `PositionedDirectional` | hors de la cible, ou disposition sans recouvrement | conforme |

Exception justifiée : le bandeau « Démonstration » disparaît clavier ouvert ; une capture prise clavier ouvert dans l'aperçu ne porte donc pas le repère.

### Chiffres (base `6e2c91c4` → branche)

| Mesure | Avant | Après |
|---|---|---|
| Fichiers avec un champ multiligne hors de `ZoneSaisie` (hors voies exclues) | 18 | 0 |
| Débordement du fil à 320 ×2, clavier ouvert | 134 px | 0 |
| Recouvrements mesurés (repère sur le bouton du compte ; radio sur l'icône à 320) | 2 | 0 |
| Mots coupés mesurés (« hom / me », « rempla… ») | 2 | 0 |
| En-tête « Dossiers à valider » à 320 ×2 (reprise) | titre 56, en-tête ≈ 340 (lu sur la capture) | titre 46, en-tête 242 (mesuré par test) |
| Commandes du Coran sur le Mushaf, lecteur d'écran, 390 ×2 (reprise) | 80 px | 0 |
| Feuille de demande des réglages de l'enfant, 320 ×2 (reprise) | 256 px (standard), 710 px (guidée) de débordement | 0 |
| Textes tronqués ou mots coupés mesurés (reprise : aide du courriel, aide de l'âge, « e- / mail », « administratio / n… », « Al- / Badr ») | 5 | 0 |
| `verifier_revue` | 1550 | 1550 ; reprise : 1548 avant, 1546 après |
| `verifier_jetons` | 39 | 37 (les deux littéraux du ruban supprimé) |

Tests ajoutés, tous en contre-épreuve réelle sur l'ancien code : `test/core/widgets/zone_saisie_test.dart`, `zone_saisie_unique_test.dart`, `choix_cote_a_cote_superpos_test.dart`, `test/features/demo/repere_demonstration_test.dart` (bande dans le flux, clavier ouvert), `test/features/controleur/echanges_controleur_test.dart` (contexte compact), `test/features/cahier/cahier_en7c_test.dart` (reprise à 320 ×2). Reprise du relecteur, chacun en contre-épreuve réelle sur la tête d'avant la reprise (`2b42d97d`) : `test/core/widgets/entete_compact_test.dart`, `test/features/controleur/echanges_compact_superpos_test.dart`, `test/core/accessibilite/coran_commandes_flux_superpos_test.dart` (3 cas sur 4 échouent avant ; le 4e garde MA-CMD-1 au toucher), `test/features/foyer/aides_champs_320_superpos_test.dart`, `test/features/reglages_enfant_test.dart` (feuille de demande, standard et guidée), `test/core/widgets/zone_saisie_test.dart` (aide du champ vide).

Captures : `docs/current/captures/SUPERPOS-1/` (`avant` = base, `apres`), repère, fil (clavier fermé et ouvert), cahier, cartes Genre ; 320 ×2 clair, 320 ×2 sombre RTL, 390, 1440 ; script archivé `superpos1_capture_test.dart.txt`. Le clavier n'est pas peint par le moteur de test : sa zone apparaît vide. Reprise : `superpos1r_avant_*` (tête `2b42d97d`) et `superpos1r_apres_*` : en-tête « Dossiers à valider » 320 ×2 clair et sombre RTL ; fil à l'arrivée 320 ×2 clair, sombre RTL, 390, 1440 et **Interface guidée** 320 ×2 ; demande des réglages de l'enfant en Interface guidée 320 ×2 et 390 ; lecteur du Coran avec lecteur d'écran 390 ×2 et 320 ×2 ; invitation du conjoint 320 ×2 (erreurs) ; script archivé `superpos1_reprise_capture_test.dart.txt`. Les captures RTL posent le français en sens arabe : la ponctuation y passe en tête de ligne, c'est un effet du forçage, pas de l'écran. Limite assumée : à l'arrivée dans le fil à 320 ×2, le titre est passé au-dessus (on le voit en remontant) ; c'est le prix de la saisie visible.

### Hors lot, relevé pour les autres voies (non touché)

- **Messages, voie COM** (`origin/ui/com-msg`, `lib/features/com_messages`, `FilContextuel` sur `FilDiscussion`) : la branche garde l'ancienne rangée de saisie de `FilDiscussion` (champ à étiquette flottante + bouton « Envoyer » en toutes lettres à côté, aligné en haut, inerte à vide). C'est vraisemblablement l'écran que visait le directeur. Défaut : bouton hors du champ et non centré, bouton inerte (grisé) à vide, débordement à 320 ×2 clavier ouvert. Correction disponible dans le core de cette branche (`ZoneSaisie`, `FilDiscussion`) ; la fusion demandera de reporter l'enregistrement vocal ajouté par COM dans la nouvelle rangée.
- **Finance** (`origin/ui/finance-v1`, lu sans rien toucher) : aucun élément flottant ni champ multiligne dans `admin_finance`, `compte/paiements_page.dart`, `ligne_finance`, `badge_periode_financee` ; les champs numériques des politiques commerciales (`politiques_commerciales.dart:1386`) portent leur libellé au-dessus, en texte : conforme.
- **Comptable** (`origin/ui/comptable-v1`) : `contractuels/nouvelle_obligation_page.dart:462-482`, champ « objet » : `labelText` d'une seule ligne posé sur le filet (`FloatingLabelBehavior.always`), donc étiquette flottante par-dessus la bordure et en ellipse à 320 ×2 ; champ « justificatif » (`:483-490`) : étiquette composée qui descend dans le champ vide et remonte sur le filet au focus. Correction proposée : étiquette au-dessus du champ, comme `ZoneSaisie`. La barre de sélection des paiements (`paiements/barre_selection.dart`) est dans la zone d'action de `PageShell`, dans le flux, et masque « Payer la sélection » au lieu de la griser : conforme. Aucun `Stack` ni `Positioned` dans `lib/features/comptable`.
- **Salle, voie TB** (relevé dans cette branche, non touché) : `salle/salle_page.dart:1475-1495`, la vignette de soi (`PositionedDirectional`, bas-fin, 16 de marge) est posée dans un `Stack` sur la galerie des tuiles distantes : elle recouvre le coin bas-fin de la dernière tuile, là où vivent le nom et l'état du micro de ce participant ; `tc_classe_live/scene_classe.dart:148-175`, étiquette nom et « micro coupé » posée sur l'image vidéo (usage admis pour une image), mais le nom y est en `TextOverflow.ellipsis` : un nom plus large que la tuile est tronqué (non mesuré ici) ; `salle_seance/salle_seance.dart:161`, `CommandesMasquables` sans `placeReservee` : avec lecteur d'écran ou clavier, le dock recouvre en permanence le bas du support et de la vidéo (même défaut que le Coran, correction disponible : passer `placeReservee: true`) ; `salle_seance/panneau_eleves.dart:290-298`, pastille d'état sur la photo de l'élève : sur une image, pas sur un texte, conforme.
- **Coquille, barre du bas en Interface guidée** (relevé sur la capture `superpos1r_apres_fil_320x2_guidee.png`, non touché, hors du périmètre superpositions) : à 320 ×2 en Interface guidée, les libellés de la barre du bas du contrôleur se coupent dans le mot (« Contrôl / e », « Historiq / ue », « Échang / es »). À relayer à la voie COUPE-MOTS (`nav_shell.dart`).
- **Champs d'une ligne à étiquette flottante** (thème, `InputDecorationTheme` : non touché, thème interdit à ce lot) : l'étiquette d'un champ rempli remonte sur le filet (« Adresse e-mail » de l'invitation, capture `superpos1r_apres_invitation_320x2.png`). Pour les champs multilignes, `ZoneSaisie` la pose au-dessus ; pour les champs d'une ligne, la règle reste à décider dans la voie du thème.
- `PageShell` et rangée de filtres (FILTRES-1) : non touchés. Le titre simple de `PageShell` (sans retour, sans action, `headlineLarge`) n'est pas passé par `EntetePage` : il reste à 36 ×2 à 320 ×2 ; à relayer au porteur de `page_shell.dart` (appeler `EnteteCompact.echelleTitre`).

Statut : **présent dans le code, testé localement**. Ni testé sur staging, ni déployé.
## CORAN-320-1 : la page Coran à 320 px et texte ×2 (08/10/2026)
Constat (`docs/current/captures/PT-B`, route réelle) : à texte ×2, en-tête de sourate, mentions et pagination prenaient la page ; à 320 × 568 la zone des versets avait 0 px (débordement de 69 px), à 390 × 844 elle avait 37 % de l'écran. Décision du 05/10 (déléguée, choix a) : seuls l'en-tête, les mentions et la pagination autour du texte changent ; le texte des versets et son rendu ne sont pas touchés.
Fait, seulement au-delà du seuil du texte agrandi (`AppContour.seuilTexteAgrandi`, 130 %), dans `lib/features/tc_mushaf/mushaf_page.dart` :
- en-tête sur une ligne : nom de la sourate et bouton « Mode de lecture » (icône nommée, état déplié annoncé) qui déplie le choix du rendu et la mention « Pour grossir le texte… » ; la page et le juz ne sont plus redits en tête (position au centre de la pagination, juz au pied de chaque page du mushaf) ;
- pagination sur une ligne : flèches et position (`BarrePrecedentSuivant`, inchangée), « Aller à une page » en icône nommée à côté ;
- attribution Tanzil entière, deux lignes au plus, jamais sous la taille de base (`AttributionCoranCompacte`, reprise du lecteur accessible) ;
- tailles de ces trois zones plafonnées à 130 %, la hiérarchie HIER-1 conservée (même plafond pour tous leurs styles), marges serrées ; les versets gardent l'échelle de l'usager.
Chiffres (avant, après), zone des versets / hauteur de l'écran, barre de navigation comprise : 320 × 568 ×2, 0 % puis 53 % ; 390 × 844 ×2, 37 % puis 67 %. À texte normal et à 1440, rien ne change (captures 1440 identiques au pixel près).
Preuves : `test/features/tc_mushaf/mushaf_texte_agrandi_test.dart` (géométrie ≥ 50 % à 320 × 568 et 390 × 844 ×2, LTR et RTL, aucun mot coupé ; contre-épreuve : les paramètres reçus par le rendu des versets, largeur du cadre, échelle de texte, sens, versets, taille, interligne, police, rosace, sont identiques à ceux relevés sur le code d'avant 6e2c91c4, à 320 ×2, 390 ×2 et 1440) ; captures `docs/current/captures/CORAN-320-1/` (`avant_` = 6e2c91c4, `apres_` ; 320 × 568 ×2 clair, sombre, RTL, options dépliées ; 390 × 844 ×2 clair, sombre RTL ; 1440 clair et sombre ; script `coran_320_1_capture_test.dart.txt`). Statut : présent dans le code, testé localement ; ni staging ni déploiement.
Décidé par délégation le 05/10 (DIR-REP-1), à faire valider par le directeur : le plafond de 130 % pour l'en-tête, les mentions et la pagination ; la mention « Pour grossir le texte… » repliée derrière le bouton « Mode de lecture » à texte agrandi ; le choix du rendu replié lui aussi (le garder visible rendait la majorité inatteignable à 320 × 568) ; aucun libellé nouveau (« Mode de lecture » et « Aller à une page » existaient déjà).
Recensé, non repris ici (hors du périmètre de l'étape) : en sens RTL, la position « 1 / 604 » s'affiche « 604 / 1 » (composant partagé `BarrePrecedentSuivant`, aussi en salle) ; les bandes de reprise (« Reprendre ») restent à leur taille quand elles s'affichent.
