# Front-end — Flutter

Tout texte visible suit la compétence `mots-rewayah`, et tout ce qui touche le programme
suit `programme-rewayah` (`.claude/skills/`). Aucun mot inventé.

Logo et ornement : uniquement par `BrandLogo` et `OrnementMarque` (`lib/core/widgets/`), selon
`assets/brand/logo/README.md` et `docs/current/BRAND-ORN-1.md`. Identité de marque, signatures,
images : `docs/current/marque/` (compétence `marque-rewayah`) ; un écran n'en tire aucune couleur ni
police nouvelle.

Charte active : `docs/current/03_DESIGN_SYSTEM_ET_UX.md` (Material Design 3, adaptation
iOS, palette douce, un titre, une tâche, un CTA par écran). Avant d'ouvrir un écran,
lire la ligne du MVP qui le concerne dans `docs/current/06_SPEC_FONCTIONNELLE_MVP.md`.
Pour retrouver un écran ou un composant déjà construit, le catalogue historique est
dans `docs/archive/2026-09-pre-remise-a-plat/design/` (référence, pas une règle).

Les composants partagés (`Pressable`, `BentoTile`, `AvatarTile`, `AvatarNom`, `AudioLabel`,
`PermanentNotice`, `PinPad`, `EmptyState`, `OfflineBanner`, `ChoiceCardGroup`,
`ActionPrincipale`, `LienFleche`, `FilterPill`, `BoutonOutil`, `BoutonIcone`, `CommandeSalle`,
`RaccourciTactile`, `PileCartes`, `CarteGroupee`, `CarteLignes`, `PastilleEtatSeance`,
`BarreSelection`) sont les
seuls points d'entrée de leur fonction : on les améliore, on n'en recrée pas un qui ferait la
même chose.

## 🧊 Règles gelées du directeur, DESIGN-GOV-2026-09-26 (obligatoires avant tout nouveau lot visuel)

Texte intégral et seul faisant foi : `docs/current/DESIGN-GOV-2026-09-26.md` (copie de `projet/ressources:memoire/DESIGN-GOV-2026-09-26.md`). **Règle gelée jusqu'à nouvelle décision datée du directeur** : ne pas la modifier, ne pas la réinterpréter.

- Autorité (§1) : dernière demande explicite du directeur, puis décisions canoniques, puis contrats serveur vérifiés, puis la spec du lot, puis le système de design gelé. Une maquette n'élargit jamais une permission ; aucune donnée absente du contrat n'est inventée.
- Validation UX 2026 (§4) : avant d'implémenter une disposition `PROPOSITION`, la confronter aux référentiels officiels (Flutter adaptive, Material 3, Apple HIG, WCAG 2.2 AA, Nielsen, Fitts / Hick / Gestalt, Baymard ; GOV.UK exclu) et livrer `UX_REVIEW_<lot>.md` (règle, source, date, conclusion, modification). Jamais « conforme » sans règle ni conséquence.
- Limite de la validation UX (§4.3) : les standards UX/UI améliorent la disposition, la densité, la lisibilité, le focus clavier, le positionnement des actions, la confirmation d'une décision, les messages d'erreur et l'adaptation mobile, tablette et ordinateur ; ils ne modifient jamais les permissions, les règles KYC, les états serveur, les critères de validation métier, la rétention des pièces, la visibilité des données sensibles, le nombre ou la nature des vérifications métier, ni l'effet juridique d'une décision. Si un standard contredit une règle métier prouvée, **la règle métier prévaut**.
- Contrats A à E (§4 bis) : échelle d'espacement `4, 8, 12, 16, 20, 24, 32, 40, 48, 64` (aucune autre valeur), **objet vers le CTA qui agit dessus : 16**, CTA au bord *trailing* (`start/end`, jamais `left/right`), pas de bouton pleine largeur sur bureau sans justification, `ActionPrincipale` / `AppCard` / `GroupeReglages` / `Skeleton` / `AppBottomSheet` jamais forkés, bureau 1440 réel, durées de mouvement gelées, `Skeleton` + `BlocAsynchrone` obligatoires pour tout chargement substantiel.
- Progression (§4 bis.8) : s'applique aux nouveaux lots seulement. **Aucune étape `fait` ou `vérifié` n'est rouverte uniquement parce qu'elle ne respecte pas encore ces règles**, sauf demande explicite du directeur sur un écran, un composant ou un lot précis, nommée dans Suivi Rewayah (§4 bis.8, exception ; elle n'autorise pas à reprendre les autres étapes) ; l'harmonisation des écrans déjà faits se fera en une passe (HU-1) après les visuels de tous les rôles.
## Règles vérifiées par `dart run tool/verifier_jetons.dart` (local et CI)

- **Aucun `onTap` nu** : tout passe par `Pressable`.
- **Aucune couleur littérale** hors de `lib/core/theme/app_palette.dart`. Le thème expose
  des paires `AppColorPair`, des encres `AppInkColor` ou l'ombre `AppShadowColor`, jamais
  une couleur seule. `Color(0x...)` dans un widget métier est un défaut.
- **Aucun `IconData` construit** hors de `lib/core/icons/app_icons.dart`, aucun `Icons.`
  Material : une seule iconographie, Phosphor.
- **Aucune valeur d'espacement** hors de l'échelle 4, 8, 12, 16, 20, 24, 32, 40, 48, 64
  (`AppSpacing`, `Ecart`). **Aucun rayon littéral** (`AppRadius`, rayon d'un enfant plus
  petit que celui du parent). **Aucune `BoxShadow`** hors de `app_elevation.dart`.
  **Aucun `letterSpacing`** hors d'`app_typography.dart`. **Aucune `Duration` ni `Curves`**
  hors d'`app_mouvement.dart` (les durées métier en minutes restent libres).
- **Aucun nom de jeton d'avant la refonte** : `surfaceBase`, `borderDefault`,
  `textOnLightAccent`, `textOnLightAlert`, `NotoSans`, `VarelaRound`.
- **`PermanentNotice` n'accepte aucun paramètre**, pas même `key`.
- **Tout choix proposé à l'utilisateur passe par `ChoiceCardGroup`**, avec sa carte « Autre ».
- **Un seul routeur**, `lib/core/router/app_router.dart`, aucune branche par plateforme.
  L'Interface guidée et l'interface standard partagent la même arborescence : ce qu'un
  écran **affiche** change, jamais la structure.
- **Zéro emoji, zéro M-dash** dans le code et les libellés.
- **Aucune chaîne visible en dur** : slang, clés en points (`eleve.accueil.rejoindre`).
  Un libellé qui doit aussi être parlé passe par `CleAudio`.
- Le mode d'interface est porté par le thème (`AppMetriques.of(context)`), jamais passé en
  paramètre d'écran en écran.
- Tags de conformité, vocabulaire fermé : `[M3-COLOR]`, `[A11Y]`, `[RESPONSIVE]`,
  `[QURAN-STAGE]`. Un tag documente une décision, pas un fait déjà visible.

## Interdits d'interface (revue directeur 01-02/10)

Textes complets : consignes K-54 à K-59 du tableau ; table des preuves : `docs/current/REVUE-DIRECTEUR-2026-10.md`. Ces règles s'ajoutent aux autres et valent pour tous les rôles. Chaque correction se fait dans le **composant partagé**, jamais écran par écran.

- **K-54 Boutons centrés.** Le contenu d'un bouton (libellé, icône) est centré horizontalement et verticalement, ligne à ligne s'il passe à la ligne. Un bouton ne déborde jamais de l'écran ni de sa carte. **Jamais de bouton recomposé dans un écran** : un `Pressable` qui peint lui-même un fond autour d'un `Text` ou d'une `Icon`, un `Pressable` dont l'enfant est un `Text` nu, un `InkWell` / `GestureDetector` qui réagit au toucher, un bouton ou une puce Material (`ChoiceChip`, `PopupMenuButton`...) sont refusés. Le composant du core qui convient, sinon on l'ajoute au core (centrage fait une fois, dans le composant) :
  - un verbe et son objet : `ActionPrincipale` (`pleineLargeur: false` donne la largeur du contenu, jamais celle du parent ; `doux` : pilule d'alerte douce de la sortie d'une salle) ;
  - un mot qui mène ailleurs : `LienFleche` (cible de 48, `libelleSemantique`, `encre` pour la salle) ;
  - une icône et son mot (outil, tuile) : `BoutonOutil` (`nue` ou `tuile`) ; une icône seule : `BoutonIcone` ; un disque et son mot (micro, caméra, quitter) : `CommandeSalle` ;
  - un filtre ou un onglet : `FilterPill`, posé dans **une seule** `RangeeFiltres` qui défile (FILTRES-1, jamais un `Wrap` de puces : contrôlé par `dart run tool/verifier_revue.dart --regle=wrap-filtres` ; un choix de formulaire en `Wrap` se déclare par `// Choix de formulaire, pas un filtre : <raison>` sur la ligne qui précède) ; une ligne ou une carte qui se touche : `AppCard(onPress:)`, `SettingRow` ; un menu : `MenuActions`, `MenuFiltre` ;
  - toucher une photo en doublon d'un lien : `RaccourciTactile` (exclu du focus et de la sémantique, le lien reste le contrôle).
  Contrôles : `bouton-recompose` (`tool/verifier_revue.dart`, quatre formes, socle à 0) ; `test/core/garde_interface_test.dart` (`verifierContenuCentre`, `verifierLibelleCentreLigneALigne`, 320 et 1440 px, texte ×1 et ×2, clair et sombre, parent qui étire ou non) ; tout nouveau composant de bouton entre dans cette garde.
- **K-55 Jamais de cartes collées.** Deux cas seulement : cartes détachées séparées par `Ecart` (contenus indépendants), ou **une seule** grande carte à lignes fines (contenus liés). Contrôle : `cartes-collees`, `verifierEcartCartes`.
- **K-56 Un seul bouton plein par écran**, à la place prévue par la Bible V2 (bas de formulaire ou de feuille, jamais au milieu du contenu). Les actions secondaires sont des boutons discrets ou des liens avec flèche (`LienFleche`) : **une action secondaire n'est jamais un gros bouton plein** (« Choisir une photo », « Choisir un fichier », « Scanner un code » sont des lignes de lien ; toucher la photo ouvre aussi le choix, `RaccourciTactile`). Un bouton posé dans une carte (« Tester la caméra ») prend toute la largeur de sa carte, en bas, contenu centré. Un bouton qui ne peut pas aboutir n'est pas grisé (`bouton-grise` / `bouton-desactive`). Contrôles : `plein-multiple` (plus d'un `ActionPrincipale` plein dans un fichier : l'existant, des branches exclusives revues une à une, est figé dans le socle avec son nombre) et, sur le rendu, `verifierUnSeulBoutonPlein` (`test/support/garde_interface.dart`) à poser dans le test de tout écran nouveau ou modifié. Limite : le contrôle de source lit le texte, il ne voit pas deux boutons pleins de feuilles différentes ouvertes ensemble ; seul le test de rendu les voit.
- **K-54 Boutons centrés.** Le contenu d'un bouton (libellé, icône) est centré horizontalement et verticalement, ligne à ligne s'il passe à la ligne. Un bouton ne déborde jamais de l'écran ni de sa carte. Jamais de bouton recomposé dans un écran : `ActionPrincipale` (centrage fait une fois). Contrôle : `bouton-recompose`, test `test/core/garde_interface_test.dart` (320 px, texte ×2).
- **K-55 Jamais de cartes collées.** Deux cas seulement : cartes détachées séparées par `Ecart` (contenus indépendants), ou **une seule** grande carte à lignes fines (contenus liés). Tout le reste est interdit.
  - **Écart minimal : 16 (`Ecart.vLg`)**, celui des écrans du tuteur, entre deux cartes ; 8 entre deux pastilles de choix (`AppCard` à `marge` réduite) ; jamais 0, 4, 8 ou 12 entre deux cartes de contenu.
  - **Contenus indépendants** : `PileCartes` (impose 16 au moins, refuse moins par assertion). Jamais un `Column` de cartes sans `spacing:` ni `Ecart`.
  - **Contenus liés** : `CarteGroupee` (sections à filet `FiletCarte` dans UNE `AppCard`), `GroupeReglages` (rubriques `LigneRubrique`) ou `CarteLignes` (lignes `SettingRow`, `ConfigLigne...` : la ligne se rend à plat dans le groupe). Une pile de `SettingRow` hors `CarteLignes` est un défaut.
  - Seule exception à 16 : la galerie vidéo de la salle (8). Ses cadres sont des flux média plein cadre (la vidéo ou l'avatar remplit le cadre, sans marge intérieure, sans titre, sans action), pas des cartes de contenu. Le panneau d'élèves de la salle (`_CarteEleve` : fond, filet, rayon, nom, fiche, actions) EST une pile de cartes : 16.
  - Contrôles : `cartes-collees` (détecteur `tool/revue_cartes.dart` : deux cartes voisines, boucle `for` ou `.map`, variable ou méthode qui rend une carte, widget dérivé, `ListView.builder` / `.separated`, boîte peinte à la main, espace inférieur à 16 ; test `test/tool/revue_cartes_test.dart` qui vérifie aussi que le dépôt n'en contient aucun) ; géométrie : `verifierEcartCartes` (composant) et `verifierAucuneCarteCollee` (écran réel, 320 et 1440 px, texte ×1 et ×2, clair et sombre : `test/core/cartes_collees_test.dart`).
- **K-56 Un seul bouton plein par écran**, à la place prévue par la Bible V2 (bas de formulaire ou de feuille, jamais au milieu du contenu). Les actions secondaires sont des boutons discrets ou des liens avec flèche (`LienFleche`). Un bouton qui ne peut pas aboutir n'est pas grisé (`bouton-grise` / `bouton-desactive`).
- **K-57 Formulaires semi-automatiques : déduit > choisi > saisi.** Préremplir (profil, foyer, classe, créneaux, dernière valeur, date du jour), sinon proposer (liste, puces, sélecteur, meilleure option justifiée), sinon seulement saisir (nom, note libre). Chaque fiche de formulaire classe ses champs déduit / choisi / saisi et justifie chaque « saisi ».
- **K-58 Tout choix s'explique.** Chaque option dit quand la choisir et sa conséquence ; une conséquence irréversible se dit avant le choix ; l'écran commence par une phrase de contexte ; quand l'option est une carte, **toute la carte** est cliquable et l'état choisi se voit sur toute la carte.
- **K-59 Tout message d'échec ou de données incomplètes** dit ce qui manque, la cause probable en mots simples, et quoi faire maintenant (D5 : « non confirmé », jamais « non envoyé »). Contrôle : `erreur-sans-action`.

Deux règles de la salle, de la revue du 01 et 02/10 (ETATS-BTN-1, NAV-FLECHES-1), composants partagés `CommandeSalle` et `BarrePrecedentSuivant` (`lib/core/widgets`) :

- **Une bascule (micro, caméra, son reçu, agrandir) montre son état par trois signaux cumulés**, jamais par la couleur seule : disque plein de contraste (`surfaceInverse`) quand elle est active, contour seul de 2 points (`borderStrong`) quand elle est inactive ; icône différente (micro / micro barré, caméra / caméra barrée) ; mot d'état court sous l'icône (« Micro ouvert » / « Micro coupé », « Caméra allumée » / « Caméra éteinte »). Cible 48 px, au moins un palier (8) entre deux disques, case de bascule de deux cibles de large pour que le mot ne déplace pas ses voisines. Seul un texte agrandi à plus de 130 % dans une rangée compacte fait passer le mot en infobulle et dans la voix du lecteur d'écran. Les actions lourdes (quitter, terminer la séance) passent par `ConfirmDestructive` (`confirmerQuitterSeance`), jamais par un appui direct. Contrôle : `bascule-sans-etat`, test `test/core/widgets/commande_salle_test.dart`.
- **Salle (/salle, tableau) : ETATS-BTN-1, ETATS-MA-1 et MA-CMD-1 remplacées par le standard des commandes d'appel**, `docs/current/SALLE-PLAN-2026-10-24.md` §Standard, décision du directeur du 24/10/2026 : pilule unique, icônes seules, aucun mot d'état sous un bouton à aucune échelle de texte ; l'état se lit par l'icône barrée, la couleur et le libellé Semantics/infobulle. Au-delà de 130 % de texte, les boutons gardent leur taille et la pilule passe sur deux rangées. **Couleurs (décision du directeur du 25/10/2026, lot salle 3 §1.2)** : actif (micro ouvert, caméra allumée) = rempli sombre neutre ; coupé ou éteint = violet de marque du logo (`#8652E6`, `surfacePrimary` clair, le même dans les deux thèmes), icône barrée, **jamais rouge** ; le rouge reste à « Quitter » seul ; le tableau suit la même règle (ouvert sombre neutre, fermé violet, décision du pilote du 25/10/2026) ; choix fait dans `BoutonIcone` (`TonAppel`) et `BoutonAppel`, jamais écran par écran. Les autres écrans gardent ces trois règles.
- **Salle sur ordinateur, composition du 26/10/2026** (`docs/current/maquettes/salle/PLAN-SALLE-COMPOSITION-2026-10-26.md`, validé par le directeur à 08:40, « la dernière refonte de la salle ») : à 840 points et plus, l'enseignant a trois panneaux (`SalleOrdinateur`) ; **rien ne s'ouvre au milieu** (ni feuille ni boîte pour Élèves, Bibliothèque ou Commandes : panneau de gauche, panneau de droite) ; le **focus** (bouton du centre, touche F) retire le haut et les deux panneaux, la barre du bas reste, un second appui ramène tout. **Écart daté au standard du 24/10 (Q1, oui)** : sur ordinateur seulement, la barre des commandes est **une barre sombre sur toute la largeur** (`surfaceInverse`), deux groupes de **tuiles icône + nom** séparés d'un filet (`TuileCommandeSalle`, par `BoutonAppel(nom:)`), cibles de 48, jamais recomposées ; le téléphone garde la pilule à icônes seules. Tuile : au repos, encre claire ; panneau ouvert ou outil retenu, aplat lilas ; bascule coupée ou éteinte (micro, caméra, tableau), violet de marque et icône barrée (lot 3) ; Quitter, seul rouge. K-56 : la page du Coran en erreur garde « Réessayer » comme seul bouton plein, « Présenter » passe en contour. L'élève n'a ni panneau ni liste d'élèves (Q2, non).
- **Salle au téléphone, composition du 26/10/2026 (PR B)** (`PLAN-SALLE-COMPOSITION-2026-10-26.md` §4) : sous 600 points, l'enseignant a **au repos** la page (ou le tableau) seule et un petit « Commandes » en bas ; **au toucher**, la capsule de sa vidéo en haut (`CapsuleVideoTelephone`, « Voir la vidéo en grand ») et la pilule micro · caméra · quitter en bas, tout masqué à 3 s (`CommandesMasquables`). « Commandes » (le « Plus » de la pilule) déplie le **tiroir** `TiroirCommandesTelephone` : trois onglets par `SelecteurSection` (ONGLETS-1) — Support (la Bibliothèque, sans sa croix), Outils (Pointeur, Écrire, Tableau, et `BarreOutilsSalle` quand on écrit), Séance (micro, caméra, Élèves, Quitter) — et « Réduire » le referme. Les élèves montent en feuille (`FeuilleElevesTelephone`, le même `PanneauEleves` que sur ordinateur). **Le tiroir et la feuille ne recouvrent jamais la pilule** : ils sont dans la même colonne et se tassent. **Écart daté à la maquette** : pas de puce « Commandes » au-dessus de la pilule (elle poussait « Réessayer » hors de l'écran à 320 en texte ×2) ; le tableau quitte la pilule et vit dans l'onglet Outils. Rien ne change pour l'élève, le tuteur ni le contrôleur.
- **Navigation précédent / suivant façon lecteur de musique** : flèche de début, position courante au centre, flèche de fin ; deux disques ronds de même taille, icône centrée, cible 48 px ; **au début et à la fin la flèche disparaît** (elle n'est pas grisée, sa place reste réservée pour que la position reste centrée) ; libellés lus en entier (« Page précédente », « Présenter la page suivante ») ; miroir en arabe (le glyphe de `AppIcons.suivant` est retourné selon `Directionality`, dans le composant seulement). Jamais deux boutons à libellé. Contrôle : `nav-a-libelle`, test `test/core/widgets/barre_precedent_suivant_test.dart`.
- **ONGLETS-1 Jamais de rangée de sections qui défile.** Changer de section passe par `SelecteurSection` (`lib/core/widgets/selecteur_section.dart`), seul composant autorisé : jusqu'à 4 sections sur téléphone = contrôle segmenté, tout visible ; 5 et plus = menu déroulant qui affiche la section courante et liste tout au toucher ; tablette et ordinateur = en ligne tant que ça tient (7 sections au plus) ; plus de 7 = la page est à signaler, jamais découpée en silence. La bascule est automatique (nombre, largeur, texte agrandi). Interdits : `TabBar`, `isScrollable: true`, rangée horizontale qui défile avec pastilles ou puces. Contrôle : `onglets-defilants`, test `test/core/widgets/selecteur_section_test.dart`.

Règles équivalentes, déduites des remarques du directeur :

- **THEME-SW-1 Le choix du thème est `SelecteurTheme`** (`lib/core/widgets/selecteur_theme.dart`) : un seul petit rectangle, trois bascules côte à côte, soleil (clair) à gauche, système au milieu, lune (sombre) à droite (l'ordre se miroite en arabe), avec au-dessus une phrase de contexte et dessous la ligne courte des trois options, toutes visibles (K-58). Jamais de cartes, de lignes radio ou de boutons recomposés pour le thème. Contrôle : `selecteur-theme-recompose`, test `test/widgets/selecteur_theme_test.dart`.
- **Le Mode Accessibilité adapte aussi la navigation (MA-NAV-1).** Même arborescence et mêmes routes (routeur unique), seule la présentation de `NavShell` change : moins de destinations (celles qui ne sont pas `essentielle: false`, atteintes sinon par un bloc de l'écran), icônes de 32 et libellés plus grands, libellé **toujours** visible sous l'icône (le rail replié aussi), cibles de 72 et espacées, encre forte au repos, contour franc. Destination active à trois signaux : fond plein, icône pleine, libellé en gras, jamais la couleur seule. Valeurs lues dans `AppMetriques` (`estEnfant`, `cibleTactile`, `arrondi`). Les branches du routeur se lisent sur `destinationsPour(mode: standard)`, l'index actif de la barre se recalcule par `indexDansBarre`. Jamais de barre recomposée hors du core. Contrôle : `nav-recomposee`, test `test/widgets/nav_shell_accessibilite_test.dart` (320 px, 800 px, 1440 px, texte ×2, clair et sombre, RTL).
- **Le bouton principal d'une séance change de sens, il ne se grise jamais (CTA-FIN-1).** Avant l'ouverture de la salle : « Préparer la séance ». Salle ouverte, et tant qu'elle l'est (un cours qui déborde garde son bouton) : « Rejoindre la salle », avec la pastille « En direct » dès l'heure de début. Temps écoulé et cahier non déposé : « Remplir le cahier de transmission », avec le rappel qu'il est obligatoire. Cahier déposé : « Voir le cahier », en lien discret (`LienFleche`). Séance annulée : « Voir la Classe ». La logique est pure et testée (`ctaSeance`, `seanceDeLaCarte` dans `lib/core/enseignant/cta_seance.dart`) ; l'écran ne décide rien. Contrôle : `test/core/enseignant/cta_seance_test.dart`, et le groupe « CTA-FIN-1 » de `test/features/journee_test.dart` (320 px et 1440 px, texte ×1 et ×2, clair et sombre).
- **Aucun élément ne recouvre un contenu à lire** (bouton flottant, bandeau, pastille). Test : `verifierSansChevauchement`, à 320 px et en texte ×2.
- **Hiérarchie de titres stricte** (HIER-1) : un niveau de texte par rôle, chaque niveau **strictement plus grand** que le suivant, dans les deux échelles (`AppTypography.standard` et `.enfant`) : titre d'écran (`headline*` : `PageShell`, `EntetePage`, `AppBottomSheet`) > titre de section (`titleLarge` : `SectionHeader`) > nom et titre de carte (`titleMedium`, `titleSmall`) > corps. Le mot-marque (`MarquePage`) est au rang `titleLarge` : toujours plus petit que le titre de l'écran qu'il surmonte. Jamais un `display*` pour un titre (réservé aux valeurs chiffrées). Un nom et un titre ne valent jamais la même taille ; `titleSmall` peut valoir le corps seulement s'il est plus gras. Contrôles : `test/theme/hierarchie_titres_test.dart` (échelles, composants, écrans-clés à 320 et 1440 px, `verifierHierarchie`).
- **Un état ne se signale jamais par la couleur seule** (en direct, annulée, actif / inactif) : texte ou icône en plus de la couleur.
- **« En direct » et « Annulée » ne se posent qu'avec `PastilleEtatSeance`** (ON-AIR-1, ANNUL-VIS-1), jamais avec une `StatusPill` ou un point posé à la main, tous rôles. « En direct » : point qui bat doucement (`AppMouvement.pulsationDirect`, 1,5 s, 3 battements puis point fixe, WCAG 2.2.2 ; fixe d'emblée si « réduire les animations »). « Annulée » : pastille `washAlert` et icône d'annulation, heure barrée (`TexteHeureSeance`), carte atténuée par `surfaceCarteSeance` (jamais une opacité), pourquoi et suite sur une ligne (`LigneRaisonSeance`). Contrôle : `etat-seance-pastille`, test `test/core/widgets/pastille_etat_seance_test.dart` (contraste mesuré, 320 px, texte ×2).
- **Une alerte urgente va toujours en tête** de l'écran, avant tout autre bloc.
- **Aucun libellé ambigu** : il dit « qui » et « quoi » (« Cahier de séance de Yasmine », pas « Cahier » ; « Déclarer l'absence de… », pas « Déclarer une absence »). Contrôle : `libelle-ambigu`.
- **Un client ne voit jamais un mot technique ou interne** : « admin » (on dit la direction), « foyer » chez la direction. Contrôle : `mot-interne`.
- **« Classe », jamais « groupe »** dans un texte visible.
- Tout nouveau libellé est déclaré dans `tool/libelles_sources.json` avec le commentaire du directeur comme source.
- **Avatar (AVATAR-1).** L'avatar est un **petit cercle** dont la taille vient des jetons (`AppAvatar.petit` 32, `moyen` 48 par défaut, `grand` 64). Tout couple avatar + nom passe par `AvatarNom` (`lib/core/widgets/avatar_nom.dart`), jamais recomposé dans un écran : en disposition **verticale**, l'avatar est centré dans son bloc et le nom centré dessous, sur le même axe ; en disposition **en ligne**, le nom (et au plus une ligne de rôle) est centré verticalement sur le cercle. Texte réduit au strict nécessaire : un nom, une ligne de rôle. **Jamais de carré ni de fond carré derrière l'avatar** : le cercle reste seul ; le futur bandeau de couleur du foyer (FOY-COUL-1) se pose sur la carte, pas sur l'avatar. Dans un cadre vidéo sans image (salle, classe live, vignette), `AvatarSansImage` contient le cercle dans son cadre. Contrôles : `avatar-recompose`, `avatar-taille` ; tests `test/core/widgets/avatar_nom_test.dart` (`verifierMemeAxe`, `verifierAlignes`, `verifierContenu`).
- **La mention « Visite de contrôle possible. » s'adresse aux participants** (décision du directeur du 11/10/2026, option b : elle ne dit plus « Cours enregistré », son point est neutre, la permanence reste, ADR-011) (enseignant, élèves) : elle n'est pas rendue au contrôleur lui-même, qui garde son propre rappel.

Les contrôles tournent dans `dart run tool/verifier_revue.dart` et dans la CI ; leur socle (`tool/revue_socle.txt`) fige l'existant et ne peut que diminuer.

## Pièges déjà payés

- Une paire dit sur quoi elle s'écrit : `surfaceAlert.applyTo(...)` écrit en blanc ; un
  message d'erreur sur la page passe par l'encre `inkAlert`. `inkFaint` est interdit sur
  `surfaceSunken` (contraste 4,48).
- Ne jamais filtrer un `AsyncValue` par son type : Riverpod 3 relance un provider en
  échec, l'état repasse par `AsyncLoading` en gardant `hasError`. Lire `hasValue`,
  `hasError`, `isLoading`.
- Une absence n'est pas un échec : lecture vide ouvre l'inscription, lecture en erreur
  ferme sur le portail d'attente (`LectureProfil`).
- Un bouton qui ne peut pas aboutir n'est pas rendu, il n'est pas grisé ; une phrase
  explique la limite.
- Le code personnel de l'élève ne quitte jamais l'appareil
  (`test/appairage/code_local_test.dart` le vérifie).
- Ce qui décide d'un droit se pose en base, pas à l'écran. Le routeur est une commodité ;
  la barrière est la RLS.
- Une police variable a une valeur par défaut par axe : Bricolage Grotesque sort à
  `wght` 800 si un style ne déclare que `fontSize`.
- Le mouvement réduit ne supprime pas l'information : une pulsation devient une bordure
  `borderStrong` fixe (`AppMouvement.duree`, `AppMouvement.translation`).
- Une seule zone pleine par écran : l'action principale. Alertes et badges prennent le
  registre doux (`washX` fond, `inkX` encre).
- Un écran sans navigation qui l'expose n'existe pas : brancher l'entrée, pas seulement
  la route.

## Génération de code

Dans cet ordre, sinon slang échoue :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

Le code généré est versionné : `dart analyze` doit passer sans étape préalable, et la CI
refuse tout diff après régénération.
