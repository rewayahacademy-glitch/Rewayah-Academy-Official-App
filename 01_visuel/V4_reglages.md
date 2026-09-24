# V4 - Réglages tuteur, mobile sombre : relevé visuel

Agent : relevé visuel V4_reglages. Date : 24/09/2026. Phase lecture seule : aucun fichier du dépôt modifié.

## 0. Source et méthode

| Élément | Valeur |
|---|---|
| Fichier | `D:\RA _APP\docs de lancement\tutuor image\réglages tutor mobile dark mode.png` |
| Taille | 1672 x 941 px, PNG |
| Nature | Planche de flux de 2 écrans mobiles high-fi côte à côte, reliés par une flèche ; légendes « 01 Réglages » et « 02 Apparence » hors écran |
| Statut | **nouveau high-fi** (planche de flux, pas une planche de direction) |
| Ouverture réelle | Image entière ouverte avec Read, puis 9 tuiles agrandies x2 / x3 ouvertes une à une : `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V4_p1_haut.png`, `V4_p1_milieu.png`, `V4_p1_bas.png`, `V4_p2_haut.png`, `V4_p2_theme.png`, `V4_p2_confort.png`, `V4_legendes_g.png`, `V4_legendes_d.png`, `V4_fleche.png` |
| Mesures | `System.Drawing.Bitmap.GetPixel` (échantillons ponctuels, moyennes de zones, détection de bords par saut de luminance, boîtes englobantes du texte) |

**Échelle.** Écran 1 : x 343 -> 753 ; écran 2 : x 918 -> 1328, soit 411 px de large pour 390 dp. **1 dp = 1,054 px** (dp = px / 1,054). L'image est légèrement floutée (rendu généré puis réduit) : les tailles de texte sont données à ±1 dp, les rayons à ±2 dp.

**Réponse à l'indication du coordinateur.** La planche contient **deux écrans**, tous deux des **préférences d'application du titulaire, appliquées à l'appareil** : 01 un hub « Réglages » (4 rubriques), 02 la sous-page « Apparence ». Ce n'est **ni** une page de réglages d'un élève, **ni** l'Interface guidée (qui relève de la fiche élève `.../interface`, mandat §4 et §5 « Fiche d'un élève »).

## 1. Manifeste

| # | Zone sur la planche (px) | Écran | Route logique (mandat §4) | Route existante | État | Thème | Format | Statut |
|---|---|---|---|---|---|---|---|---|
| 01 | cadre x 325-775, y 20-920 ; écran x 343-753 | Réglages (hub des préférences) | `/tuteur/compte/preferences` | `/compte/reglages` (`lib/core/router/routes.dart:297`, `app_router.dart:169-173`, page `ReglagesComptePage` dans `lib/features/compte/compte_page.dart:190`) | nominal | sombre | mobile | nouveau high-fi |
| 02 | cadre x 900-1350, y 20-920 ; écran x 918-1328 | Apparence | sous-page de `.../preferences` (à dériver, p. ex. `/tuteur/compte/preferences/apparence`) | aucune route dédiée : section « Apparence » + « Accessibilité » de la même page `ReglagesComptePage` | nominal : Système sélectionné, 2 bascules désactivées, taille du texte « suit le système » | sombre | mobile | nouveau high-fi |
| - | x 60-230, y 425-505 et x 1430-1610 | Légendes « 01 Réglages » / « 02 Apparence » | - | - | - | - | - | annotation de planche, pas de l'UI |
| - | x 810-862, y 445-482 | Flèche violette entre les écrans | - | - | - | - | - | annotation de flux (tap « Apparence » -> écran 02) |

Attention : `Routes.tuteurReglages = '/tuteur/reglages'` (`routes.dart:100-101`) désigne les **réglages par enfant** (`ReglagesEnfantPage`). Ce n'est pas l'écran de cette planche malgré le titre identique « Réglages ».

## 2. Tokens mesurés

### 2.1 Couleurs (HEX mesurés, coordonnées sur l'image 1672x941)

| Rôle | HEX mesuré | Coordonnées / méthode | Existant `AppPalette.sombre()` (`lib/core/theme/app_palette.dart`) |
|---|---|---|---|
| Fond de planche (hors écran) | `#1A1A27` / `#191825` | (60,60) / (1600,880) | - |
| Fond de page (canvas) | `#1A1925` (moy.), `#1B1B26`, `#1D1D28`, `#191924` | moyenne x930-1320,y175-188 ; (550,180) ; (550,700) ; (400,820) : très léger dégradé | `surfaceCanvas #111014` (plus sombre, plus chaud) |
| Surface carte (écran 01) | `#23232F` / `#22212D` / `#22222E` | (620,215) / (680,292) / (620,635) | `surfaceRaised #1A181F` |
| Surface groupe (écran 02) | `#23232F` (groupe 1), `#21212D` (groupe 2) | moyennes x1180-1300,y205-212 ; x1200-1300,y600-608 | idem |
| Bordure carte / groupe, 1 px | `#2C2D3B` à `#31313F` | (364,204) ; (600,199)=`#313140` ; (550,301)=`#2E2E3B` | `borderHairline #3A3443` |
| Séparateur de lignes, 1 px | `#2E2E3B`, `#30313F` | (1100,730) ; (1200,801) | `borderHairline #3A3443` |
| Option non sélectionnée : fond | `#252432` (Clair), `#292A37` (Sombre) | moyennes x1230-1250,y385-460 / y488-560 | `surfaceSunken #24212B` |
| Option non sélectionnée : bordure 1 px | `#333446` / `#363448` | (942,420) / (1100,373) | - |
| Option sélectionnée : fond (équivalent « CTA doux ») | `#2F2B42` | moyenne x1230-1250,y280-355 | `washAccent #332643` |
| Option sélectionnée : bordure 2 px (accent) | `#C7A5FF`, `#D7BAF0` | (942,330) ; (1100,271) | `inkAccent #C9AEFF` |
| Bouton retour (disque) | `#2B293A` / `#282739` | moyenne x942-948,y125-140 ; (370,133) | `surfaceOverlay #2C2834` |
| Texte principal (titres de page) | `#FCFCFD` / `#F7F7F8` | cœur des glyphes « Réglages » x428-560,y110-147 ; « Apparence » x1000-1160,y105-142 | `inkStrong #F5F2FA` |
| Texte principal (titres de ligne) | `#F6F5F7` (01), `#DEDDE4` (options 02), `#D3D3D7` (lignes Confort visuel) | x452-550,y226-250 ; x1088-1160,y298-320 ; x1005-1160,y676-694 | `inkStrong` |
| Texte secondaire | `#9A9DBE`, `#9395BB`, `#8A8BAB`, `#8588A4` (légende la plus petite) ; `#ABABD5` pour le sous-titre de page 01 (percentile haut) | x452-668,y256-277 ; x1000-1205,y145-168 ; x940-1215,y240-258 ; x1005-1220,y699-717 ; x428-690,y150-172 | `inkMuted #BAB3C5` (plus clair, plus chaud) |
| Accent (icônes, flèche retour) | `#BB92F8` à `#CAA3F9` ; retour `#CBADF9` / `#C8A7EF` | icônes 01 x380-430 (4 icônes) ; icônes 02 x942-986 ; retour x370-402,y118-150 | `inkAccent #C9AEFF` |
| Chevrons | `#BEB9EE` (01), `#A9A5D8` (02) : lavande désaturée | x700-720,y238-264 ; x1286-1302,y824-848 | - |
| Radio sélectionnée : anneau / point | `#D0A8FF` / `#BC98FC` | (1277,304) / (1277,317) ; espace intérieur `#1C1B28` (1277,307) | `inkAccent` |
| Radio non sélectionnée : anneau | `#9491B9` / `#9698C5` | (1277,406) / (1264,420) | `borderResting #95899F` |
| Interrupteur désactivé : piste | `#48475D` | (1290,694) ; (1300,700)=`#49485D` | - |
| Interrupteur : pouce | `#FEFDFE` | (1266,694) | - |
| Miniature thème Clair | fond `#FBF8FF` / `#EBE6FE`, pastille accent `#C3A4FD`, point `#E0CBFE` | (1000,395) / (1040,420) ; (990,442) ; (1053,402) | indice pour dériver le thème clair |
| Miniature thème Sombre | fond `#131324`, pastille `#BB98FB`, gris `#323147` | (1040,495) ; (990,543) ; (1030,522) | - |
| Barre d'accueil iOS | `#FFFFFF` | x475-618, y886-891 | chrome système, ne pas reproduire |
| **Absents de cette planche** | CTA plein, pastilles de statut vert/orange/rouge/gris, bandeau d'alerte, onglet actif de navigation | - | à relever sur les autres planches |

**Écart de palette à trancher par le coordinateur (propriétaire des tokens) :** le sombre de la maquette est un **ardoise bleu-violet** (canvas `#1A1925`, surface `#22222E`, texte secondaire `#9A9DBE`) nettement plus clair et plus froid que `AppPalette.sombre()` (canvas `#111014`, surface `#1A181F`, `inkMuted #BAB3C5`). L'accent est quasi identique (`#C4A0FB` mesuré contre `#C9AEFF`). À confronter aux autres planches sombres (accueil desktop sombre) avant de changer un token.

**Contrastes WCAG calculés :** texte principal `#F6F5F7`/`#22222E` 14,5:1 ; secondaire `#9A9DBE`/`#22222E` 5,9:1 ; secondaire `#9395BB`/`#1A1925` 6,0:1 ; légende `#8588A4`/`#21212D` 4,6:1 (limite AA) ; accent `#C4A0FB`/`#22222E` 7,3:1 ; anneau radio off `#9491B9`/`#252432` 5,1:1 ; **piste d'interrupteur off `#48475D`/`#21212D` 1,77:1 (< 3:1 exigé pour un composant, WCAG 1.4.11)** ; bordure de carte `#2E2E3B`/`#1A1925` 1,3:1 (décorative, acceptable car le texte identifie la ligne).

### 2.2 Géométrie (px mesurés -> dp)

| Mesure | px | dp |
|---|---|---|
| Marge latérale écran 01 (écran 343 -> carte 359 ; carte 737 -> écran 753) | 16 | **15-16** |
| Marge latérale écran 02 (écran 918 -> groupe 927 ; groupe 1320 -> écran 1328) | 8-9 | **8** (incohérent avec 01, voir pièges) |
| Bouton retour : disque (x 359-411, y 109-160) | 52 | **48-49** (cible tactile OK) |
| Flèche retour | 22 x 21 | 20 |
| Écart bouton retour -> titre (411 -> 433) | 22 | 21 |
| En-tête : bas du sous-titre -> première carte (169 -> 199 ; 165 -> 194) | 29-30 | **28** |
| Carte de rubrique (écran 01) : largeur x hauteur (359-737, 199-302) | 379 x 103 | **360 x 98** |
| Écart entre cartes (302 -> 313, 416 -> 428, 531 -> 542) | 11 | **10-11** |
| Rayon carte / groupe (décalage diagonal 5 px) | 13-17 | **~16** (±2) |
| Icône de rubrique 01 (contour) | 42 x 42 | **40** |
| Retrait icône depuis le bord de carte (359 -> 384) | 25 | 24 |
| Début du texte depuis le bord de carte (359 -> 456) | 97 | 92 (icône 40 + écart 28) |
| Chevron | 10 x 17 | 9 x 16 ; retrait droit 21 dp |
| Groupe « Thème de l'application » (927-1320, 194-576) | 394 x 382 | 374 x 362 |
| Retrait interne du groupe : titre de section (927 -> 946) / options (927 -> 941) | 19 / 14 | **18 / 13** (non alignés) |
| Carte d'option (941-1311, 270-365) | 371 x 95 | **352 x 90** |
| Écart entre options (365 -> 373) | 8 | **8** |
| Rayon d'option (décalage diagonal 4 px) | ~13 | **~12** |
| Bordure option sélectionnée / non sélectionnée | 2 / 1 | 2 / 1 |
| Cadre de miniature (952-1077) ; miniature (964-1068 x 389-455) | 126 ; 105 x 67 | 119 ; 100 x 64 |
| Radio : diamètre extérieur ; point intérieur | 30 ; ~20 | **28 ; ~19** |
| Écart entre groupes (576 -> 590) | 14 | 13 |
| Ligne « Confort visuel » : pas vertical (730 -> 801) | 71 | **67** |
| Icône de ligne Confort visuel | 37 | 35 |
| Interrupteur : piste (1250-1306 x 679-710) ; pouce | 56 x 32 ; 26 | **53 x 30 ; 25** |
| Séparateur : de x 945 à 1305 (retrait = padding du groupe) | 1 px | 1 dp, retrait 18 dp des deux côtés |

### 2.3 Typographie observée (tailles ±1 dp)

| Niveau | Exemple | Hauteur de capitale mesurée | Taille estimée | Graisse apparente | Règle écrite à appliquer |
|---|---|---|---|---|---|
| Titre de page | « Réglages », « Apparence » | 21-22 px | **~28 dp** | Bold 700 | **DM Sans** (titre français) |
| Sous-titre de page | « Personnalisez votre expérience. » | 12 px (x-height 9 px) | **~16 dp** | Regular 400, couleur secondaire | Plus Jakarta Sans |
| Titre de section (groupe) | « Thème de l'application », « Confort visuel » | 15 px | **~20 dp** | SemiBold/Bold 600-700 | **DM Sans** |
| Description de section | « Personnalisez l'apparence de Rewayah. » | 11 px | ~14 dp | Regular | Plus Jakarta Sans |
| Titre de rubrique (01) | « Notifications » | 14 px | **~18 dp** | SemiBold 600 | Plus Jakarta Sans (libellé de ligne) |
| Sous-ligne de rubrique (01) | « Rappels et informations » | 11 px | **~15 dp** | Regular | Plus Jakarta Sans |
| Titre d'option (02) | « Système » | 15-16 px | ~17 dp | SemiBold | Plus Jakarta Sans |
| Sous-ligne d'option | « Suit votre appareil » | - (6,4 px/car.) | ~14-15 dp | Regular | Plus Jakarta Sans |
| Titre de ligne Confort visuel | « Réduire les animations » | 10 px | **~14 dp** | SemiBold | Plus Jakarta Sans |
| Légende | « Limite les animations de l'interface. » | 9 px | **~12 dp** ; la légende « Diminue les effets visuels (ombres, flous, etc.). » est visiblement comprimée (~11 dp) pour tenir sur une ligne | Regular | Plus Jakarta Sans |

Famille apparente : grotesque géométrique à grand œil, « a » à deux étages, « g » à un étage, « R » à jambe droite. Compatible avec DM Sans comme avec Plus Jakarta Sans ; impossible de trancher à cette résolution. **La règle écrite prime** : DM Sans pour les titres (page, section), Plus Jakarta Sans pour tout le reste (libellés de ligne, sous-lignes, légendes, contrôles). Rappel du BRIEF : aucune de ces deux familles n'existe aujourd'hui dans le dépôt (polices actuelles `InstrumentSans` / `BricolageGrotesque`), contrairement à ce qu'affirme le mandat.

Hiérarchie incohérente dans la maquette : les libellés de lignes du groupe « Confort visuel » (~14/12 dp) sont nettement plus petits que ceux des options de thème (~17/15 dp) et des rubriques de l'écran 01 (~18/15 dp), alors qu'ils sont au même niveau logique. À normaliser sur un seul style de ligne.

## 3. Fiches écran

### Fiche 01 - Réglages (hub)

- **Fichier / zone** : `réglages tutor mobile dark mode.png`, cadre x 325-775, y 20-920 ; écran x 343-753.
- **Écran** : hub des préférences de l'application du titulaire. **Route** : `/tuteur/compte/preferences` (mandat §4, ligne « Compte | Préférences »), à mapper sur l'existante `/compte/reglages` (alias plutôt que route concurrente). **État** : nominal. **Thème** : sombre. **Format** : mobile. **Statut** : nouveau high-fi.
- **Composition, de haut en bas** :
  1. Barre d'état iOS (« 9:41 », Dynamic Island, réseau, Wi-Fi, batterie) : chrome d'appareil, à ne pas reproduire.
  2. En-tête en ligne : disque retour 48 dp à gauche (fond `#2B293A`, flèche accent 20 dp) ; à sa droite, bloc titre aligné à gauche : titre « Réglages » (~28 dp Bold, blanc) puis sous-titre (~16 dp Regular, lavande-gris). Le titre est centré verticalement sur le bouton retour, le sous-titre déborde sous lui. Pas de barre d'application Material classique.
  3. 28 dp d'espace.
  4. **Quatre cartes séparées** empilées, pleine largeur moins 16 dp de marge, 98 dp de haut, 10-11 dp d'écart, rayon ~16 dp, fond `#22222E`, bordure 1 px `#2E2E3B`. Chaque carte : icône contour accent 40 dp (retrait 24 dp) ; bloc texte à 2 lignes (titre ~18 dp SemiBold blanc, sous-ligne ~15 dp Regular lavande-gris) ; chevron droit lavande 16 dp (retrait 21 dp). Ordre : Apparence, Langue et région, Notifications, Sécurité.
  5. Grand vide jusqu'à la barre d'accueil iOS (~250 dp).
- **Navigation** : aucune barre basse ni rail : écran secondaire poussé, retour en haut à gauche. Cohérent avec `_CoquilleSecondaire` existante. Aucune destination de navigation principale visible, donc aucune indication sur 3 ou 4 onglets.
- **CTA** : aucun CTA plein ; chaque carte est une ligne de navigation entière (chevron). Surfaces tactiles 98 dp (OK >= 48 dp).
- **Iconographie** : contour ~2,5 dp, non rempli, accent lavande. Correspondances Phosphor (déjà dans le dépôt) : palette, globe, cloche, bouclier coché (`palette`, `globe`, `bell`, `shieldCheck`).
- **États visibles** : nominal seulement. Aucun état de chargement, d'erreur ou d'indisponibilité.
- **Textes lisibles, exacts** :
  - « 9:41 »
  - « Réglages »
  - « Personnalisez votre expérience. »
  - « Apparence » / « Thème, texte et confort visuel »
  - « Langue et région » / « Français · Asia/Riyadh »
  - « Notifications » / « Rappels et informations »
  - « Sécurité » / « Connexion et appareils »
- **Erreurs et incohérences à ne pas reproduire** :
  - « Français · Asia/Riyadh » : valeurs illustratives. Dans le code, le fuseau est affiché « non disponible » et l'arabe aussi (`compte_page.dart:284-297`) ; un seul fichier i18n `fr` existe. Ne pas coder `Asia/Riyadh` en dur ; résumé calculé depuis la langue active et le fuseau réel quand il existera ; identifiant IANA brut = jargon, préférer un libellé humain (ville + décalage calculé par date, jamais UTC fixe, mandat §5 Classe).
  - « Sécurité / Connexion et appareils » : doublon de la rubrique Compte « Connexion et sécurité » (`.../securite`) et ambiguïté avec les appareils du foyer (`/tuteur/foyer/appareils`). Cette ligne doit ouvrir **la même route** `.../securite` (pas une 2e page) et le sous-titre doit désigner les sessions/appareils connectés au compte titulaire, pas les appareils élèves du foyer.
  - Quatre grandes cartes séparées pour quatre lignes : tension avec le mandat §5 Mon compte (« Chaque rubrique est une ligne ou un groupe sobre... Pas un catalogue de grandes cartes ») et §9 (« Moins de cartes... listes, séparateurs »). L'écran 02 de la même planche utilise, lui, un groupe unique avec séparateurs. Recommandation : un seul groupe à séparateurs (même composant que « Confort visuel »), ou arbitrage explicite du coordinateur.
  - Fonctions existantes absentes du hub : section « Cours et données » (économie de données, lecture grande du Coran, `compte_page.dart:320-337`) et « Accessibilité » (répartie dans Apparence). Le mandat impose de préserver l'existant : prévoir une rubrique supplémentaire (p. ex. « Cours et données ») plutôt que de supprimer ces réglages.
  - Titre « Réglages » contre libellé du mandat « Préférences » (`.../preferences`) ; et collision de nom avec `/tuteur/reglages` (réglages par enfant). Choisir un libellé et le consigner ; ne pas mélanger avec les réglages élève.

### Fiche 02 - Apparence

- **Fichier / zone** : même fichier, cadre x 900-1350, y 20-920 ; écran x 918-1328.
- **Écran** : sous-page Apparence des préférences. **Route** : sous-route à dériver de `.../preferences` (le mandat §4 ne la liste pas ; aujourd'hui section de `ReglagesComptePage`). **État** : nominal : « Système » sélectionné, « Réduire les animations » et « Réduire les effets » désactivés, taille du texte « Suit la taille du système ». Contenu probablement défilant (le groupe 2 finit à 14 px au-dessus de la barre d'accueil). **Thème** : sombre. **Format** : mobile. **Statut** : nouveau high-fi.
- **Composition, de haut en bas** :
  1. Barre d'état iOS (chrome).
  2. En-tête identique à 01 : disque retour 48 dp, titre « Apparence » (~28 dp Bold), sous-titre « Appliqué sur cet appareil. » (~16 dp, secondaire).
  3. 28 dp.
  4. **Groupe 1 « Thème de l'application »** (surface `#23232F`, bordure 1 px, rayon ~16 dp, marge écran 8 dp) : titre de section ~20 dp, description ~14 dp, puis 3 cartes d'option empilées (352 x 90 dp, rayon ~12 dp, écart 8 dp). Chaque option : cadre de miniature 119 dp à gauche contenant un aperçu d'interface stylisé (Système = superposition clair + sombre ; Clair = fond `#FBF8FF` pastilles lavande ; Sombre = fond `#131324` pastilles violettes), titre ~17 dp SemiBold + sous-ligne ~15 dp, radio 28 dp à droite. Sélection = bordure 2 dp accent `#C7A5FF` + fond teinté `#2F2B42` + radio pleine ; non sélectionnée = bordure 1 dp `#333446`, fond `#252432`, anneau `#9491B9`.
  5. 13 dp.
  6. **Groupe 2 « Confort visuel »** : titre ~20 dp, description ~14 dp, puis 3 lignes (pas 67 dp) séparées par des filets 1 dp retirés de 18 dp : icône accent 35 dp, titre ~14 dp SemiBold + légende ~12 dp, contrôle à droite. Lignes : « Réduire les animations » (interrupteur off), « Réduire les effets » (interrupteur off), « Taille du texte » (chevron -> sous-écran non fourni).
- **Navigation** : aucune barre basse ; retour en haut à gauche.
- **CTA** : aucun ; contrôles = radios (choix exclusif) et interrupteurs style iOS (pouce blanc à gauche, piste grise `#48475D` sans contour, 53 x 30 dp). L'implémentation existante utilise `RadioGroup` + `Switch.adaptive` (`compte_page.dart:215-266`), bonne base.
- **Iconographie** : cercle pointillé (animations), étincelles (effets), glyphe « Aa » (taille du texte), accent lavande ; Phosphor : `circleDashed`, `sparkle`, `textAa`. Miniatures de thème = illustrations construites (pas des captures).
- **États visibles** : un seul (Système actif, toggles off). Non montrés : Clair/Sombre sélectionnés, toggles on, rendu en thème clair, désactivation si l'OS impose déjà la réduction des animations.
- **Textes lisibles, exacts** :
  - « 9:41 »
  - « Apparence »
  - « Appliqué sur cet appareil. »
  - « Thème de l’application » (apostrophe typographique) / « Personnalisez l'apparence de Rewayah. » (apostrophe droite)
  - « Système » / « Suit votre appareil »
  - « Clair » / « Clair et lumineux »
  - « Sombre » / « Sombre et confortable »
  - « Confort visuel » / « Ajustez certains effets visuels de l'application. »
  - « Réduire les animations » / « Limite les animations de l'interface. »
  - « Réduire les effets » / « Diminue les effets visuels (ombres, flous, etc.). »
  - « Aa » (icône) / « Taille du texte » / « Suit la taille du système »
  - Planche : « 01 », « Réglages », « 02 », « Apparence », flèche « → ».
- **Erreurs et incohérences à ne pas reproduire** :
  - « Appliqué sur cet appareil. » alors que `PreferencesLocales` est **en mémoire seulement** (`lib/core/preferences/preferences_locales.dart:18-22`, `build()` renvoie les valeurs par défaut à chaque lancement) : le choix est perdu au redémarrage. La chaîne i18n existante surpromet davantage (« Ces préférences restent sur cet appareil et s'appliquent tout de suite. », `assets/i18n/fr.i18n.json:1124`). Persistance locale à décider par le coordinateur (aucune dépendance `shared_preferences` dans `pubspec.yaml` ; seul `flutter_secure_storage` est présent) ou formulation honnête.
  - « Taille du texte » avec chevron : aucun sous-écran fourni. Ne pas livrer une impasse (mandat §11.1). Le réglage doit respecter le facteur d'agrandissement système (`TextScaler`) ; ne pas le confondre avec `lectureGrande` existant (taille de lecture du Coran). Soit sous-écran dérivé, soit ligne informative sans chevron.
  - « Réduire les animations » doit se cumuler avec la préférence système (`MediaQuery.disableAnimations`), jamais la contredire ; l'interrupteur local ne peut que réduire davantage.
  - Marge écran 8 dp pour les groupes contre 16 dp à l'écran 01 et 16 dp pour le bouton retour du même écran : normaliser sur un seul token de gouttière.
  - Groupe 1 : la carte « Sombre » touche presque le bas du groupe (padding bas ~0-2 dp contre 13 dp sur les côtés) et le titre de section (18 dp) n'est pas aligné sur les options (13 dp) : imprécision de maquette, appliquer un padding de groupe unique.
  - Apostrophes mélangées (’ et ') dans le même écran : unifier selon la convention i18n du dépôt.
  - Légende « Diminue les effets visuels (ombres, flous, etc.). » rétrécie pour tenir : en implémentation, laisser passer à la ligne (texte agrandi sans coupure, mandat §9), ne pas réduire la police.
  - Piste d'interrupteur off à 1,77:1 : relever le contraste (piste ou contour) pour atteindre 3:1.
  - Seule la variante sombre est fournie : dériver le clair sans inversion naïve (mandat §9) ; les miniatures « Clair » donnent un indice (fond `#FBF8FF`, pastilles `#C3A4FD`), et `AppPalette.claire()` existe déjà.

## 4. Pièges principaux (synthèse)

1. **Valeurs illustratives** : « Français · Asia/Riyadh » ne doit pas devenir une constante ; fuseau et arabe sont « non disponible » dans le code actuel ; identifiant IANA brut à humaniser.
2. **Doublons et collisions de routes** : « Sécurité / Connexion et appareils » doit pointer sur `.../securite` existant, pas créer une 2e page ; « Réglages » (compte) n'est pas `/tuteur/reglages` (réglages par enfant) ni l'Interface guidée ; libellé « Réglages » contre « Préférences » du mandat à trancher.
3. **Promesses non tenues par le code** : « Appliqué sur cet appareil. » avec un stockage en mémoire ; « Taille du texte » sans destination ; notifications locales seulement (`notificationsCours`, `notificationsFoyer`) sans service de rappel vérifié.
4. **Fonctions existantes à préserver** : « Cours et données » (économie de données, lecture grande) absent de la maquette.
5. **Normalisation visuelle** : marges 16 dp contre 8 dp, 4 cartes séparées contre groupe à séparateurs, hiérarchie de taille des lignes incohérente, contraste de l'interrupteur off, palette sombre plus claire et plus froide que les tokens actuels.

## 5. Valeurs de tokens clés proposées (à valider par le coordinateur)

| Token | Valeur relevée |
|---|---|
| Canvas sombre | `#1A1925` |
| Surface carte/groupe sombre | `#22222E` (bordure 1 dp `#2E2E3B`) |
| Texte secondaire sombre | `#9A9DBE` |
| Accent sombre | `#C4A0FB` (bordure sélection `#C7A5FF`, fond sélection `#2F2B42`) |
| Gouttière mobile | 16 dp |
| Rayon carte/groupe ; rayon option | 16 dp ; 12 dp |
| Bouton retour | disque 48 dp |
| Hauteur de ligne | 98 dp (rubrique 01, généreuse) ; 67 dp (ligne à interrupteur) ; option de thème 90 dp |
| Titre de page / section / ligne / sous-ligne / légende | ~28 / ~20 / ~17-18 / ~15 / ~12 dp |
