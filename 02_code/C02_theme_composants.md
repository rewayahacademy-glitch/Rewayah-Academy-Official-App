# C02 - Thème, jetons et composants partagés (cartographie lecture seule)

- Date : 24/09/2026. Agent : C02 (cartographie). Phase : LECTURE SEULE.
- Dépôt : `D:\RA _APP\RA -OFFICIAL-APP`, branche `c0/configuration-baseline-2026-09-23`, HEAD `3cf3544`. `git status` identique avant et après (seul `?? .claude/`, préexistant).
- Aucune modification, création ou commit dans le dépôt. Fichiers temporaires (scripts d'analyse de polices, copies des polices) uniquement dans le scratchpad de session.
- Convention : **FAIT** = ce que le code exécute ; **PRÉTEND** = ce que disent un commentaire ou une doc. Toute citation est `fichier:ligne` relative à la racine du dépôt, sauf mention contraire.

---

## 0. Synthèse (à lire en premier)

1. **La typographie actuelle n'a qu'une famille française effective.** Tout le `TextTheme` est construit par `_corps` en `InstrumentSans` (`lib/core/theme/app_typography.dart:150-166`, `:171-189`). `BricolageGrotesque` n'est plus utilisée par aucun style depuis le merge `cb3a220` (15/09/2026) ; elle ne sert plus qu'à la galerie de dev (`lib/features/_dev/galerie/galerie_page.dart:644`). Les commentaires qui disent le contraire sont faux (`app_typography.dart:25-26`, `pubspec.yaml:120-124` « AppTypography les pilote tous les deux »).
2. **Aucune trace de Jakarta ni de DM Sans** dans le dépôt ni dans l'historique de toutes les branches (`git log --all -S Jakarta|DMSans|"DM Sans" -- pubspec.yaml lib assets tool test` : vide). Le mandat (« Jakarta est déjà déclarée dans les jetons ») est contredit par le code. Les fichiers cibles existent seulement dans `D:\RA _APP\pilotage-tuteur-v1\polices\` (SHA-256 identiques aux fichiers Google Fonts téléchargés pour contrôle).
3. **Mesures réelles des polices cibles** (table `fvar`/`GSUB` lue sur les binaires) : DM Sans `opsz` 9-40 **défaut 9**, `wght` 100-1000 défaut 400 ; Plus Jakarta Sans `wght` 200-800 défaut 400. **DM Sans n'a pas de fonction `tnum`** (ni `pnum`) : ses chiffres sont proportionnels et `AppTypography.tabulaire()` n'aurait aucun effet sur elle. Plus Jakarta Sans a `tnum`. Conséquence : les rôles `display*` (chiffres, comptes à rebours, `StatTile`) et tout code ou compteur doivent rester en Jakarta.
4. **`headlineMedium` sert aujourd'hui à des codes et des chiffres**, pas seulement à des titres : code d'appairage (`lib/features/appareils/appairage_page.dart:208`), saisie du code élève (`lib/features/eleve_connexion/eleve_connexion_page.dart:316`), touches du `PinPad` (`lib/core/widgets/pin_pad.dart:195`), initiales d'`AvatarTile` (`lib/core/widgets/avatar_tile.dart:124`). Basculer `headline*` en DM Sans sans créer un style « code/chiffre » en Jakarta dégraderait ces écrans.
5. **Le vérificateur de jetons ne contrôle aucune famille de police** : aucune règle `fontFamily` dans `tool/verifier_jetons.dart`. Seul le vocabulaire périmé `VarelaRound`/`NotoSans` est interdit (`tool/verifier_jetons.dart:92-99`). État mesuré : `dart tool/verifier_jetons.dart` -> « 342 fichiers, aucune violation » (exécuté sous verrou, code 0).
6. **Un seul test fige la famille** : `test/theme/typographie_test.dart:7` (`headlineSmall.fontFamily == AppFontFamily.corps`). Il cassera dès que `headlineSmall` passe en DM Sans. Aucun test ne charge de vraie police (`FontLoader` absent, pas de `flutter_test_config.dart`, aucun golden image) : les largeurs réelles de Jakarta/DM Sans ne sont vérifiées par **aucun** test. Base mesurée : `flutter test test/theme` -> 9 tests PASS.
7. **Défauts du mode sombre et des préférences** : le voile d'`AppBottomSheet` prend `surfaceInverse` qui est **clair** en sombre (`lib/core/widgets/app_bottom_sheet.dart:100-102` + `lib/core/theme/app_palette.dart:148-151`) ; la préférence de thème de la page Réglages **n'est branchée à rien** (`lib/app.dart:32,50`, `lib/main.dart:68` ne passent jamais `preferencesLocalesProvider`), de même `animationsReduites`, `effetsReduits`, `lectureGrande`, `economieDonnees` (aucun consommateur hors `compte_page.dart`).
8. **Contrastes** : `inkFaint` clair est sous 4,5:1 partout (3,85 sur canvas, 4,11 sur raised, **3,55 sur sunken**) alors qu'il sert de texte d'invite des champs posés sur `surfaceSunken` (`lib/core/theme/app_theme.dart:146,152`). La valeur « 4,48 » citée par `lib/CLAUDE.md:45-46` et deux commentaires est périmée.
9. **Famille d'états système du mandat §8 : presque entièrement absente.** Existent : `Skeleton`, `OfflineBanner` (binaire, sans « reconnexion »), `EmptyState` (3 registres), `LocalFeedback`, `AttentePage` (dossier). Manquent comme composants partagés : bloc d'erreur (échec serveur), page d'erreur globale, chargement prolongé, reconnexion, 404 (le `GoRouter` n'a pas d'`errorBuilder`, `lib/core/router/app_router.dart:95-106`), accès refusé, session expirée, permission refusée, ressource expirée. Aucune politique de timeout centralisée n'existe dans `lib/core`.
10. **`BandeauObservation` n'est pas l'observation tuteur** : c'est le bandeau des sessions d'observation par un agent IA en lecture seule (ADR-025, `lib/core/widgets/bandeau_observation.dart:10-35`), posé par `lib/app.dart:56-67`. Ne pas le réutiliser pour la notice « Votre parent observe ».

---

## 1. Sources lues

- Règles : `D:\RA _APP\pilotage-tuteur-v1\BRIEF.md`, `CLAUDE.md`, `lib/CLAUDE.md`, mandat `D:\RA _APP\docs de lancement\REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (partie principale et « Prompt étape observation tuteur », qui impose DM Sans/Jakarta et prime sur la première partie pour la typographie).
- Intégralement : `lib/core/theme/*` (10 fichiers), `tool/verifier_jetons.dart`, `lib/core/icons/app_icons.dart`, les 38 widgets de `lib/core/widgets/` (API publique ; `admin_shell.dart` lu par ses signatures), `pubspec.yaml`, `lib/app.dart`, `lib/core/preferences/preferences_locales.dart`, `lib/core/reseau/service_reseau.dart`, `lib/core/router/ecran_a_construire.dart`, tests `test/theme/*`, extraits de `test/widgets/composants_test.dart`.
- Maquettes réellement ouvertes (9 sur 19) : `acceuil tuteur desktop light.png`, `acceuil tuteur desktop dark.png`, `mobile/accueil  tuteur mobile light mode.png`, `mobile/mon compte tuteur mobile light mode.png`, `réglages tutor mobile dark mode.png`, `tuteur observation desktop light.png`, `mobile/tuteur observation mobile light.png`, `tutor observation map.png`, `onboarding Mble d.png`, plus la tuile `pilotage-tuteur-v1/01_visuel/tuiles_V2/L_zoom_typo.png`. **Non ouvertes** : les autres images du dossier (dont les captures historiques). Je n'ai pas identifié la planche « États particuliers et notices de présence » parmi les images ouvertes.

---

## 2. Construction du thème

`AppTheme.pour(InterfaceMode mode, Brightness brightness)` (`lib/core/theme/app_theme.dart:12`) :

- palette : `AppPalette.sombre()` ou `AppPalette.claire()` (`:13-15`) ;
- métriques : `AppMetriques.pour(mode)` (`:16`) ;
- texte : `AppTypography.enfant` ou `.standard`, puis `.apply(bodyColor, displayColor = surfaceCanvas.onBackground)` (`:17-22`) ;
- `ColorScheme` dérivé de la palette par `_schemaDepuisPalette` (`:172-212`) ;
- `ThemeData(useMaterial3: true, extensions: [palette, metriques], textTheme: texte, splashFactory: NoSplash, ...)` (`:66-169`).

Branchement : `lib/app.dart:48-50` fournit `theme` (clair) et `darkTheme` (sombre) calculés sur `session.interfaceMode`, `themeMode` venant du constructeur (`ThemeMode.system` par défaut, `lib/app.dart:32`).

Correspondance `ColorScheme` (FAIT, `app_theme.dart:175-211`) :

| Rôle M3 | Jeton |
|---|---|
| primary / onPrimary | `surfacePrimary` |
| primaryContainer / onPrimaryContainer | `washAccent` |
| secondary | `inkMuted` (couleur brute via `asBorderSide().color`) |
| secondaryContainer | `surfaceSunken` |
| tertiary | `inkAccent` ; tertiaryContainer = `washAccent` |
| error / onError | `surfaceAlert` ; errorContainer = `washAlert` |
| surface / onSurface | `surfaceRaised` |
| surfaceContainerLowest, Low | `surfaceCanvas` |
| surfaceContainer, surfaceDim | `surfaceSunken` |
| surfaceContainerHigh, Highest, surfaceBright | `surfaceOverlay` |
| inverseSurface | `surfaceInverse` ; inversePrimary = `surfacePrimary` de l'autre palette (`:206-208`) |
| outline / outlineVariant | `borderStrong` / `borderHairline` |
| scrim | `palette.voile` |

Thèmes de composants Material posés : boutons Filled/Outlined/Text (`:93-121`, mais ces boutons sont interdits dans `lib/` par le vérificateur, `tool/verifier_jetons.dart:124-126`), `cardTheme`, `dialogTheme`, `bottomSheetTheme`, `inputDecorationTheme` (`:143-168`), `appBarTheme.titleTextStyle = texte.titleLarge` (`:91`), `iconTheme = inkStrong` taille 24 (`:84`).

Remarque : le code lit souvent la couleur brute d'une encre par `asBorderSide().color` (`app_theme.dart:59,78,110,118,181,185,195,209-210`, `lib/core/widgets/admin_shell.dart:198,208`, `nav_shell.dart:578,585,594`), ce qui contourne l'intention « aucune couleur brute exposée » de `AppInkColor` (`lib/core/theme/app_color_pair.dart:56-64`). Pas bloquant, à connaître.

---

## 3. Palette

### 3.1 Types

- `AppColorPair(background, onBackground)` avec `applyTo(TextStyle)`, `decoration(...)`, `lerp` (`lib/core/theme/app_color_pair.dart:13-54`).
- `AppInkColor` : encre de premier plan seulement ; expose `applyTo`, `asBorderSide`, `asIconTheme`, `debugValue` réservé aux tests (`:66-101`).
- `AppShadowColor` : ne construit qu'une `BoxShadow` (`:115-153`).
- `AppPalette extends ThemeExtension<AppPalette>` (`lib/core/theme/app_palette.dart:9`), lue par `AppPalette.of(context)` (`:256-257`). `surfaceOverlay` retombe sur `surfaceRaised` s'il n'est pas fourni (`:37-38`).

### 3.2 Valeurs (FAIT)

| Jeton | Clair (fond / texte) | Sombre (fond / texte) | Lignes |
|---|---|---|---|
| surfaceCanvas | F8F7FA / 211E28 | 111014 / F5F2FA | `:45-48`, `:120-123` |
| surfaceRaised | FFFFFF / 211E28 | 1A181F / F5F2FA | `:41-44`, `:116-119` |
| surfaceSunken | F0EDF4 / 211E28 | 24212B / F5F2FA | `:49-52`, `:124-127` |
| surfaceOverlay | FFFFFF / 211E28 | 2C2834 / F5F2FA | `:53-56`, `:128-131` |
| surfacePrimary | 8652E6 / FFFFFF | C9AEFF / 25113F | `:57-60`, `:132-135` |
| surfaceSuccess | 70EE9C / 1C1D21 | identique | `:61-64`, `:136-139` |
| surfaceWarning | FFB703 / 1C1D21 | identique | `:65-68`, `:140-143` |
| surfaceAlert | B01B3C / FFFFFF | FFB1BD / 570D22 | `:69-72`, `:144-147` |
| surfaceInverse | 211E28 / F5F2FA | F5F2FA / 211E28 | `:73-76`, `:148-151` |
| washAccent | EEE6FA / 4E2983 | 332643 / E8D8FF | `:77-80`, `:152-155` |
| washSuccess | E4F4EB / 175D3A | 173B2B / 9DDEB5 | `:81-84`, `:156-159` |
| washWarning | FFF2CE / 755200 | 44361A / F4D480 | `:85-88`, `:160-163` |
| washAlert | FCE8ED / 921734 | 4A2030 / FFD9E0 | `:89-92`, `:164-167` |
| washFamily | F0EDF4 / 211E28 (= sunken) | 24212B / F5F2FA (= sunken) | `:93-96`, `:168-171` |
| surfaceQuran | F3EAD9 / 1C1D21 | 2E2417 / F5F1E9 | `:97-100`, `:172-175` |

Encres (clair / sombre) : `borderHairline` E3DEE9 / 3A3443 ; `borderResting` 84798F / 95899F ; `borderStrong` 84798F / 95899F ; `inkFaint` 84798F / 95899F ; `inkMuted` 655E70 / BAB3C5 ; `inkStrong` 211E28 / F5F2FA ; `inkAccent` 5B36B0 / C9AEFF ; `inkSuccess` 175D3A / 9DDEB5 ; `inkWarning` 755200 / F4D480 ; `inkAlert` 921734 / FFD9E0 (`:101-110`, `:176-185`). `ombre` 211E28 dans les deux (`:111`, `:186`).

Dérivés : `contourCarte` = blanc ou 211E28 à 8 % selon `estSombre` (`:245-249`) ; `voile` = noir à 32 % (clair) / 56 % (sombre) (`:250-251`) ; `calqueInteraction` = `inkAccent` à 4 % (survol) / 10 % (pression) (`:253-254`) ; `encreSecondaireSur(surface)` rend **toujours `inkMuted`** quel que soit l'argument (`:255`).

Teintes d'identité : 32 paires claires et 32 sombres (`:377-447`), accès par `teinteGroupe(index)` / `teinteCouverture(index)` (`:236-242`). Utiles pour le groupe d'avatars « FD AM YA SN » de la maquette Mon compte.

Famille sémantique des états : `enum TonEtat {neutre, accent, succes, avertissement, alerte}` et `extension PaireDeTonEtat.paireDe(ton)` (neutre -> `surfaceSunken`, sinon `washX`) dans `lib/core/widgets/status_pill.dart:13-48` (et non dans le fichier de palette, volontairement).

### 3.3 Constats sur la palette

- **Trois jetons de même valeur** : `borderResting` = `borderStrong` = `inkFaint` (84798F clair, 95899F sombre). Toute distinction « filet au repos / filet porteur de sens » entre `borderResting` et `borderStrong` est donc invisible, par exemple `ChoiceCardGroup` (`lib/core/widgets/choice_card_group.dart:210-212`) et les touches du `PinPad` (`pin_pad.dart:188-190`). La distinction réelle ne tient qu'entre `borderHairline` et `borderStrong`.
- **`washFamily` = `surfaceSunken`** dans les deux modes : la « teinte du domaine foyer » annoncée par `avatar_tile.dart:24-26` n'existe pas visuellement.
- **Contrastes mesurés** (formule WCAG, script scratchpad) :

| Encre | Clair canvas / raised / sunken | Sombre canvas / raised / sunken |
|---|---|---|
| inkFaint | **3,85 / 4,11 / 3,55** | 5,74 / 5,32 / 4,79 |
| inkMuted | 5,81 / 6,20 / 5,35 | 9,33 / 8,66 / 7,79 |
| inkAccent | 7,57 / 8,08 / 6,97 | 9,91 / 9,19 / 8,27 |
| inkAlert | 8,22 / 8,77 / 7,57 | 14,67 / 13,61 / 12,24 |
| borderStrong sur canvas | 3,85 | 5,74 |
| borderHairline sur raised | 1,32 | 1,47 |

  `inkFaint` clair est sous 4,5:1 partout ; il est utilisé en texte d'invite des champs (`app_theme.dart:152`, sur fond `surfaceSunken` `:146`), dans le Mushaf (`lib/features/tc_mushaf/*`), la galerie et `admin_shell.dart:198`. Les commentaires `timeline_row.dart:31-32`, `signal_row.dart:82-84` et `lib/CLAUDE.md:45-46` (« 4,48 ») décrivent une palette antérieure.
- Pastilles de `StatusPill` en clair : succès 70EE9C sur blanc = 1,46:1, avertissement FFB703 = 1,75:1 (sous 3:1 pour un élément graphique porteur de sens). Compensé par le mot obligatoire (`status_pill.dart:50-55`), donc acceptable, mais la pastille seule n'est pas lisible.
- Tests de palette : `test/theme/contraste_test.dart` (paires claires >= 4,5 et 5 valeurs figées `:40-44`), `test/theme/contraste_sombre_test.dart` (idem sombre, 3 valeurs figées `:38-40`). **Aucun test ne mesure les encres** sur les surfaces : le défaut `inkFaint` passe inaperçu.

### 3.4 Écart palette / maquettes (observation, à confirmer par l'agent visuel)

Dans les maquettes ouvertes, l'action principale « Voir la classe », « Observer la séance », « Continuer » est un **aplat lilas pâle avec texte foncé et flèche**, en clair comme en sombre, et en forme pilule sur l'onboarding. Le code peint l'action principale en `surfacePrimary` 8652E6 avec texte blanc (`lib/core/widgets/action_principale.dart:194-204`) et n'a pas de suffixe icône. C'est une décision de jeton, à trancher par le coordinateur avec l'agent visuel, pas une conclusion de ce rapport.

---

## 4. Mode sombre

- **Comment il est dérivé (FAIT)** : palette sombre écrite à la main (`app_palette.dart:115-188`), même structure que la claire. Pas d'inversion automatique. Différences de comportement codées : pas d'ombre de dialogue en sombre (`lib/core/theme/app_elevation.dart:61-62`, testé `test/theme/elevation_test.dart:17-19`) ; la carte `dominante` perd son ombre en sombre (`lib/core/widgets/app_card.dart:140-142`) ; `voile` plus opaque (`app_palette.dart:250-251`).
- **Défaut 1, voile de feuille** : `AppBottomSheet.ouvrir` remplace le voile du thème par `surfaceInverse.background` à 32 % (`lib/core/widgets/app_bottom_sheet.dart:100-102`). En sombre `surfaceInverse` vaut F5F2FA (`app_palette.dart:148-151`) : le fond sous toute feuille (dont `ConfirmDestructive`) est éclairci au lieu d'être assombri. Constat de code ; rendu non capturé.
- **Défaut 2, préférence de thème inopérante** : la page Réglages écrit `preferencesLocalesProvider.theme` (`lib/features/compte/compte_page.dart:189-247`) et se dit « prennent effet immédiatement » (`:189`), mais `RewayahApp` n'en lit rien (`lib/app.dart:32,50`) et `lib/main.dart:68` construit `const RewayahApp()`. Même situation pour `animationsReduites`, `effetsReduits`, `lectureGrande`, `economieDonnees` : seul consommateur `compte_page.dart`. `AppMouvement.mouvementReduit` ne lit que `MediaQuery.disableAnimationsOf` (`lib/core/theme/app_mouvement.dart:121-122`). La maquette Accueil desktop montre une bascule soleil/lune dans l'en-tête : elle exigera ce branchement (fichier `lib/app.dart`, propriété coordinateur).
- **Maquettes** : les variantes sombres fournies (Accueil desktop/tablette, Réglages, Historique mobile) sont cohérentes avec la palette sombre actuelle à l'oeil (fonds 111014/1A181F, accent C9AEFF), non mesuré au pixel.

---

## 5. AppMetriques et Interface guidée

- `AppMetriques extends ThemeExtension` avec `mode` et `cibleTactile` (`lib/core/theme/app_metriques.dart:13-30`) ; `pour(mode)` : 72 en `enfant`, 48 en `standard` (`:18-23`, valeurs `lib/core/theme/app_spacing.dart:96-102`).
- Dérivés : `estEnfant` (`:33`), `rayon` 24/16 (`:38`), `arrondi` (`:41-42`), `arrondiInterieur` (`:49`), `marge` 24/16 (`:52`), `of(context)` (`:55-56`).
- Échelle typographique enfant : `AppTypography.enfant` (+20 % sur 6 rôles, `lib/core/theme/app_typography.dart:79-86`).
- **Nom technique vs nom produit** : l'enum reste `InterfaceMode.enfant('child')` / `standard` (`lib/core/domain/enums.dart:85-107`), commentaire « Environ 6 a 8 ans » (`:86`). Le libellé produit « Interface guidée » existe en i18n (`strings_fr.g.dart:6378`) et côté Teaching Core (`lib/core/tc_classe/teacher_student_projection.dart:198-201`). Le mode est lu une fois dans `lib/app.dart:48-49` depuis `session.interfaceMode` (défaut `standard`, `lib/core/session/session_state.dart:72`). Un tuteur est donc toujours en métriques standard ; un aperçu de l'Interface guidée d'un élève dans la fiche élève demanderait un `Theme(data: AppTheme.pour(InterfaceMode.enfant, ...))` local, pas une nouvelle échelle.
- `destinationsPour` retire toute navigation à l'élève en mode enfant (`lib/core/widgets/nav_shell.dart:54-56`).

---

## 6. Autres jetons (et écarts doc/code)

| Jeton | FAIT | PRÉTEND (écart) |
|---|---|---|
| `AppSpacing` 4/8/12/16/20/24/32/40/48/64 (`app_spacing.dart:13-57`) ; `Ecart` (`:106-154`) | conforme | - |
| `AppPage` gouttières **16 / 24 / 32** (`app_spacing.dart:65-71`), largeurs 1200/640/760/800/1440/400, `hauteurBouton` 52, `hauteurChoix` 112, `hauteurReglage` 64 (`:74-82`) | - | `page_shell.dart:16-17` dit « 20 / 32 / 48 » ; le test `test/widgets/composants_test.dart:500` porte ce nom mais compare aux constantes (16/24/32) |
| `AppRadius` 8/12/16/24/999, `enfantDe` (`app_radius.dart:13-77`) | conforme | - |
| `AppElevation` niveaux 0-3, `dialogue`, `avecFilet` (`app_elevation.dart:32-88`) | `avecFilet` retombe sur `niveau0` si `ombres` est omis (`:85`) | le commentaire `:71-73` dit que le niveau par défaut est calculé ici |
| `AppMouvement` 100/120/180/220/180/120/400 ms, `pulsation` 1200, `delaiSquelette = apparition` 180 ms (`app_mouvement.dart:19-63`) | - | `skeleton.dart:16` « rien avant 200 ms » (180 en réalité) ; `app_bottom_sheet.dart:17` et `:88-90` « 280 / 200 ms » (180 / 120 en réalité, `:92-97`) ; `local_feedback.dart:20-21` « 200 / 160 ms » (180 / 120, `:107-108`) |
| `AppGabarit` seuils 600 / 840 / 1200, `largeurRail` 80, `largeurBarreLaterale` 256 (`app_gabarit.dart:60-121`) | - | - |
| Cible tactile standard 48 | - | `bento_tile.dart:33` dit 44 |

Littéraux hors échelle non détectés par le vérificateur (arguments par défaut de constructeurs) : `Skeleton.carteEleve` 112.0 et `Skeleton.tuileBento` 120.0 (`lib/core/widgets/skeleton.dart:54,60`).

---

## 7. Typographie actuelle

### 7.1 Familles et axes (FAIT, binaires relus le 24/09)

| Famille technique (`AppFontFamily`) | Fichier (`pubspec.yaml`) | Axes mesurés (min / défaut / max) | Usage réel |
|---|---|---|---|
| `corps` = `InstrumentSans` (`app_typography.dart:23`) | `assets/fonts/InstrumentSans-Variable.ttf` 193 312 o (`pubspec.yaml:116-118`) | wght 400/400/700 ; wdth 75/100/100 | **tous** les rôles du `TextTheme` |
| `titre` = `BricolageGrotesque` (`:26`) | `assets/fonts/BricolageGrotesque-Variable.ttf` 407 844 o (`:126-128`) | opsz 12/96/96 ; wght 200/800/800 ; wdth 75/100/100 | aucun style ; galerie seulement |
| `arabeInterface` = `NotoSansArabic` (`:20`) | 844 676 o (`:104-106`) | wght 100/400/900 ; wdth 62,5/100/100 | repli `repli` de tous les styles (`:30`, `:174`) |
| `arabeDocument` = `UthmanTahaNaskh` (`:17`) | `.otf` statique (`:98-100`) | - | `AppTypography.document()` (`:142-148`) |
| `Phosphor`, `PhosphorFill` | icônes (`:134-139`) | - | `AppIcons` uniquement |

`AppFontAxis` (`app_typography.dart:46-58`) ne déclare que `opszMin/Max` de Bricolage (12/96, désormais inutilisés) et `wghtCorpsMin/Max` 400/700.

### 7.2 Échelle standard (`_construire`, `app_typography.dart:150-166`)

Tous via `_corps(taille, interligne, poids)` : `fontFamily` corps, repli NotoSansArabic, `fontSize`, `height`, `fontWeight`, `letterSpacing: crenage(taille)`, `fontVariations: [wght = poids borné 400..700]` (`:171-189`).

| Rôle | Taille / interligne px | Graisse (wght) | Tabulaire | Usages dans `lib/` (hors `.g.dart`) |
|---|---|---|---|---|
| displayLarge | 36 / 44 | 600 | oui (`:151`) | 0 |
| displayMedium | 36 / 44 | 600 | oui | 1 (compte à rebours, `lib/features/accueil_eleve/accueil_eleve_page.dart:337`) |
| displaySmall | 36 / 44 | 600 | oui | 4 (`StatTile`, `MarquePage`, monogramme `tc_catalogue/vignette_ressource.dart:89`, galerie) |
| headlineLarge | 36 / 44 | 600 | non | 1 (titre de `PageShell`, `page_shell.dart:82`) |
| headlineMedium | 32 / 40 | 600 | non | 7 (codes, PIN, initiales, titres de connexion : voir §0 point 4) |
| headlineSmall | 28 / 36 | 600 | non | 21 (question `PageParcours`, `SectionHeader`, titre `AppBottomSheet`, attente...) |
| titleLarge | 22 / 28 | 600 | non | 15 (+ `appBarTheme`, message `EmptyState`, heures `ScheduleOption`) |
| titleMedium | 18 / 26 | 600 | non | 73 (libellés de lignes et cartes) |
| titleSmall | 16 / 24 | 600 | non | 30 |
| bodyLarge | 16 / 24 | 400 | non | 14 (+ `hintStyle`) |
| bodyMedium | 14 / 20 | 400 | non | 102 |
| bodySmall | 12 / 16 | 400 | non | 195 |
| labelLarge | 16 / 20 | 600 | non | 18 (+ boutons, `app_theme.dart:39`) |
| labelMedium | 12 / 16 | 500 | non | 20 (+ navigation, `nav_shell.dart:574`) |
| labelSmall | 12 / 16 | 500 | non | 20 |

Échelle enfant (`:79-86`) : headlineSmall 32/40 w600, titleLarge 32/40 w600, bodyLarge 20/28 w400, bodyMedium 20/28 w400, labelLarge 20/28 w600, bodySmall 16/24 w400 ; le reste hérite du standard. `facteurEnfant = 1.2` (`:73`) n'est plus utilisé dans le calcul.

Outils : `crenage(taille)` -0,02 em >= 32, -0,015 >= 24, -0,01 >= 18, 0 >= 15, +0,01 sinon (`:97-113`) ; `capitales(base)` +0,06 em <= 12 px (`:120-126`) ; `tabulaire(base)` ajoute `FontFeature.tabularFigures()` (`:134-136`) ; `document()` UthmanTahaNaskh 28 px interligne 2 (`:142-148`).

### 7.3 Historique utile

Au lot T (`09134cb`), `display*` et `headline*` étaient en Bricolage via `_titre(taille, interligne, poids)` qui posait `wght` **et** `opsz = taille.clamp(12, 96)`. Le merge `cb3a220` (« merge: integrate finalized Vague 5 », 15/09/2026) a remplacé toute l'échelle par `_corps` (diff relu : `git diff cb3a220^1 cb3a220 -- lib/core/theme/app_typography.dart`). La fonction `_titre` disparue est le bon gabarit pour DM Sans (même besoin : piloter `opsz`).

### 7.4 `fontFamily` dispersés (rg `fontFamily` lib)

| Emplacement | Nature | Statut |
|---|---|---|
| `lib/core/theme/app_typography.dart:144,173-174` | jetons | légitime |
| `lib/core/icons/app_icons.dart:48-491` | `IconData(..., fontFamily: _repos/_actif)` | légitime (icônes) |
| `lib/features/_dev/galerie/galerie_page.dart:637,644,670` | `copyWith(fontFamily: AppFontFamily.corps/titre/arabeInterface)` + chaînes `'InstrumentSans : ...'` `:634`, `'BricolageGrotesque : ...'` `:641` | outil de dev, à mettre à jour avec la bascule |

Aucun autre `fontFamily`, `fontSize`, `fontWeight` ou `fontStyle` posé hors thème, sauf `AvatarTile` qui recalcule `fontSize: taille * 0.36` (`lib/core/widgets/avatar_tile.dart:128`). Aucun `google_fonts`, aucun `fontSizeFactor`. La centralisation exigée par le mandat est donc déjà atteinte côté écrans : la bascule se fait dans `app_typography.dart`, `pubspec.yaml`, `assets/fonts/`, la galerie et les 4 usages non-titres de `headlineMedium`.

---

## 8. Mesures des polices cibles (binaires de `pilotage-tuteur-v1/polices/`)

SHA-256 : `DMSans-Variable.ttf` 8CD08D97...1C0D (240 164 o), `PlusJakartaSans-Variable.ttf` 89B3FB38...BC8 (176 288 o), identiques au dépôt `google/fonts`. Licences OFL 1.1 présentes à côté.

| Mesure | DM Sans | Plus Jakarta Sans | Instrument Sans (actuel) |
|---|---|---|---|
| Axes | opsz **9 / 9 / 40**, wght 100 / 400 / 1000 | wght 200 / 400 / 800 | wght 400 / 400 / 700, wdth 75-100 |
| Instances nommées | 9 | 7 | 4 |
| `tnum` (chiffres tabulaires) | **absent** | présent | présent |
| Chasse des chiffres 0..9 (unités/1000) | 656, 342, 589, 598, 614, 606, 624, 538, 604, 624 (proportionnels) | 732, 371, ... (proportionnels par défaut, `tnum` disponible) | 666, 391, ... |
| Accents français (àâäçéèêëîïôöùûüÿœæ + capitales, « », ’) | tous présents | tous présents | tous présents |
| U+00A0 espace insécable / U+202F espace fine insécable | oui / **non** | oui / **non** | oui / non |
| Métriques typo (asc / desc, UPM 1000) | 992 / -310 (hauteur naturelle 1,302) | 1038 / -222 (1,260) | 970 / -250 (1,220) |
| x-height / cap-height | 526 / 700 | 536 / 745 | 510 / 720 |
| yMax É / Å ; yMin ç / g | 925 / 967 ; -260 / -232 | 999 / 1044 ; -230 / -220 | 950 / 986 ; -215 / -215 |
| Largeur de « Prochaine séance : jeudi 25 septembre à 17 h 30, avec Sayyida Maryam » | 33 137 (+3,3 %) | 32 953 (+2,7 %) | 32 074 |

Contour et largeur mesurés sur l'instance par défaut (wght 400, et opsz 9 pour DM Sans) : à revalider à l'oeil aux graisses et tailles réelles. Aucune espace fine insécable n'est utilisée aujourd'hui dans `assets/i18n/fr.i18n.json` (0 occurrence de U+202F et U+00A0) : si l'équipe l'introduit, le glyphe viendra du repli NotoSansArabic.

---

## 9. Plan de bascule typographique (proposition pour le coordinateur, seul propriétaire)

### 9.1 Décisions à prendre (je ne tranche pas)

1. **Noms techniques** : je propose `PlusJakartaSans` (corps) et `DMSans` (titres), alignés sur les noms de fichiers. Remplacer, ne pas ajouter : `AppFontFamily.corps` et `AppFontFamily.titre` gardent leurs noms de constantes, seules les valeurs changent, ce qui limite le diff aux fichiers de thème.
2. **Quels rôles sont des « titres »** (mandat : « titres de page, de section et autres styles de titres ») : voir 9.2. Le point dur est `titleMedium` (73 usages), qui sert à la fois de libellé de ligne (`SettingRow`, `ChoiceCardGroup`, carte `DataCollection`) et, dans les maquettes, de titre de bloc (« Prochaine séance », « Dernière séance »).
3. **Graisses** : les titres des maquettes paraissent plus lourds que w600 (plutôt 600-700 à l'oeil sur `L_zoom_typo.png`). À mesurer par l'agent visuel avant de fixer.

### 9.2 Correspondance proposée

| Rôle | Aujourd'hui | Proposition | Justification |
|---|---|---|---|
| displayLarge/Medium/Small | Instrument 36/44 w600 tnum | **Jakarta** 36/44, tnum conservé | chiffres (compte à rebours, `StatTile`, heure « 13:45 » des maquettes) ; DM Sans n'a pas de `tnum` |
| headlineLarge | Instrument 36/44 w600 | **DM Sans**, opsz = 36 | titre de page (`PageShell`) |
| headlineMedium | Instrument 32/40 w600 | **DM Sans**, opsz = 32, **après** migration de ses 4 usages non-titres vers un style « code » Jakarta | codes d'appairage et élève, PIN, initiales |
| headlineSmall | Instrument 28/36 w600 | **DM Sans**, opsz = 28 | question de parcours, `SectionHeader`, titre de feuille |
| titleLarge | Instrument 22/28 w600 | **DM Sans**, opsz = 22 | titre d'`AppBar`, message d'`EmptyState` ; attention `ScheduleOption.hours` (`schedule_option.dart:75`) qui porte des heures |
| titleMedium / titleSmall | Instrument 18/26, 16/24 w600 | **Jakarta** | libellés de lignes et de cartes ; un titre de bloc doit alors employer `headlineSmall`/`titleLarge` (règle d'écran à écrire) |
| body*, label* | Instrument | **Jakarta** | corps, boutons, champs, navigation, pastilles |
| Enfant : headlineSmall, titleLarge 32/40 | `_corps` | **`_titre`** (DM Sans) | cohérence avec l'échelle standard |
| Enfant : body*, labelLarge, bodySmall | `_corps` | Jakarta | idem |
| `document()` | UthmanTahaNaskh | inchangé | Coran |
| Nouveau `AppTypography.code` (et/ou `chiffre`) | - | Jakarta, tnum, graisse 600, taille 32 | remplace `headlineMedium` dans `appairage_page.dart:208`, `eleve_connexion_page.dart:316`, `pin_pad.dart:195` ; le minuteur « Visite 1/2 · 01:42 » en a aussi besoin |

Esquisse du constructeur de titre (à écrire dans `app_typography.dart` par le coordinateur ; texte de rapport, pas un patch appliqué) :

```dart
static TextStyle _titre(double taille, double interligne, FontWeight poids) =>
    TextStyle(
      fontFamily: AppFontFamily.titre,            // 'DMSans'
      fontFamilyFallback: AppFontFamily.repli,
      fontSize: taille,
      height: interligne,
      fontWeight: poids,
      letterSpacing: crenage(taille),
      fontVariations: <FontVariation>[
        FontVariation('wght', poids.value.toDouble().clamp(100, 1000)),
        FontVariation('opsz', taille.clamp(9, 40)),  // défaut 9 = dessin petit corps
      ],
    );
```

et `AppFontAxis` : `opszTitreMin 9`, `opszTitreMax 40`, `wghtTitreMin 100`, `wghtTitreMax 1000`, `wghtCorpsMin 200`, `wghtCorpsMax 800` (remplacent 12/96 et 400/700).

### 9.3 Pièges identifiés

1. **`opsz` par défaut à 9** : un titre DM Sans qui ne pose pas `opsz` sort avec le dessin prévu pour 9 px (plus large, plus lâche) à 22-36 px. L'axe doit être posé explicitement dans chaque style titre ; je n'ai pas vérifié que Flutter l'applique automatiquement d'après `fontSize` (hypothèse à ne pas faire). Avec un `TextScaler` système, `opsz` reste calé sur `fontSize` et non sur la taille rendue : limite acceptée à documenter.
2. **`tnum` absent de DM Sans** : `AppTypography.tabulaire()` posé sur un style DM Sans ne fait rien, et le test `test/widgets/composants_test.dart:387-397` (« le chiffre est tabulaire ») resterait vert puisqu'il vérifie la présence de la fonction dans le style, pas son effet. D'où `display*` en Jakarta.
3. **Défauts d'axe** : Jakarta et DM Sans ont `wght` par défaut 400, donc pas de piège « extra-gras » comme Bricolage (800). Un `copyWith(fontWeight: ...)` sans mise à jour de `fontVariations` garderait l'ancien `wght` (aucune occurrence aujourd'hui dans `lib/`, cf. §7.4) : règle à garder.
4. **Interlignes** (répartition proportionnelle par défaut de Flutter, parts ascendante/descendante de la boîte de ligne en em) :

| Style (px) | DM Sans asc / desc | Jakarta asc / desc | Contrainte glyphes |
|---|---|---|---|
| 36/44 | 0,931 / 0,291 | 1,007 / 0,215 | DM : É 0,925 tient, Å 0,967 déborde ; Jakarta : É 0,999 tient, ç -0,230 déborde de 0,015 em |
| 32/40 et 16/20 | 0,952 / 0,298 | 1,030 / 0,220 | Jakarta labelLarge (boutons) : ç déborde de 0,01 em (0,16 px) |
| 28/36 | 0,980 / 0,306 | 1,059 / 0,227 | OK |
| 22/28 | 0,970 / 0,303 | 1,048 / 0,224 | OK |
| >= 1,33 (corps, libellés) | - | >= 1,098 / >= 0,235 | OK |

   Conclusion : les interlignes actuels restent utilisables, avec un risque de contact entre lignes pour les titres de 36 px sur plusieurs lignes portant « Å » (rare en français). Contrôle visuel requis sur titres longs à deux lignes et texte agrandi 200 %.
5. **Largeur** : Jakarta +2,7 % et x-height +5 % par rapport à Instrument ; DM Sans +3,3 % à opsz 9 (moins à opsz élevé). Zones serrées à contrôler : libellés de `NavigationBar` (`nav_shell.dart:375-393`), `StatusPill`, `PageParcours` (déjà corrigé une fois pour 200 %, `page_parcours.dart:84-87`), `LignePresence` dans une colonne de 208 px (`ligne_presence.dart:127-135`), boutons pleine largeur. **Aucun test existant ne détecte ces débordements** : les tests widget rendent avec la police de test Flutter, pas avec les polices du produit.
6. **Crénage** : le barème `crenage()` (-0,02 em à 36 px) a été calé pour Instrument/Bricolage. DM Sans à opsz 36-40 est déjà resserré par son dessin optique : le cumul peut sur-serrer. À juger à l'oeil sur captures, pas à deviner.
7. **Repli arabe** : les variations `wght` d'un style s'appliquent-elles aux glyphes de repli NotoSansArabic ? `pubspec.yaml:103` l'affirme, rien dans le code ne le garantit ; statut INCONNU, à vérifier sur la ligne mixte de la galerie (`galerie_page.dart:659-662`).
8. **Web** : les polices sont embarquées en assets (pas de réseau), conforme à `pubspec.yaml:93-95`. L'italique DM Sans (fichier séparé) n'est pas nécessaire : aucun `fontStyle` dans `lib/`.
9. **Poids du paquet** : retirer Instrument (193 312 o) et Bricolage (407 844 o), ajouter Jakarta (176 288 o) et DM Sans (240 164 o) : environ -185 Ko.

### 9.4 Fichiers touchés par la bascule (tous « coordinateur seul »)

1. `assets/fonts/` : ajouter `PlusJakartaSans-Variable.ttf`, `DMSans-Variable.ttf`, `LICENSE-PlusJakartaSans.txt`, `LICENSE-DMSans.txt` ; retirer `InstrumentSans-Variable.ttf`, `BricolageGrotesque-Variable.ttf` et leurs licences (le mandat interdit une famille équivalente en double).
2. `pubspec.yaml:108-128` : deux déclarations `family: PlusJakartaSans` / `family: DMSans` avec commentaires d'axes corrigés (« opsz 9-40 défaut 9 », « wght 200-800 défaut 400 »).
3. `lib/core/theme/app_typography.dart` : `AppFontFamily` (valeurs + docs), `AppFontAxis`, réintroduction de `_titre`, `_construire`, `enfant`, nouveau style `code`/`chiffre`.
4. Les 3 usages non-titres de `headlineMedium` (+ décider pour `avatar_tile.dart:124`) : fichiers appartenant à d'autres lots (appareils, connexion élève, `PinPad` partagé) ; demande à formuler par le coordinateur.
5. `lib/features/_dev/galerie/galerie_page.dart:621-684` : spécimens et chaînes.
6. `tool/verifier_jetons.dart` : voir §10.
7. `test/theme/typographie_test.dart` : voir §11.
8. `lib/CLAUDE.md:58-59` (piège « Bricolage sort à wght 800 ») : remplacer par « DM Sans sort en opsz 9 si l'axe n'est pas posé ; DM Sans n'a pas de chiffres tabulaires ».

### 9.5 Preuve attendue avant de dire « jetons stabilisés »

`dart analyze --fatal-infos`, `flutter test test/theme test/widgets`, `dart run tool/verifier_jetons.dart`, puis **captures réelles** (build web ou Windows) de la galerie et de 3 écrans (titre de page, parcours, code d'appairage) en clair/sombre, 390 px et 1440 px, texte à 100 % et 200 %, avec comparaison aux maquettes. Sans capture, statut « UI réalisée », pas « vérifiée ».

---

## 10. `tool/verifier_jetons.dart` : état et mises à jour

Règles existantes (FAIT) : couleur nue hors `app_palette.dart` et `core/marque/logo_google.dart` (`:59-62,284-287`) ; `BoxShadow` hors élévation (`:73-76,293-296`) ; `letterSpacing` hors `app_typography.dart` (`:297-300`) ; `Duration(milliseconds:)` et `Curves.` hors `app_mouvement.dart` (`:301-307`) ; `BorderRadius.circular(n)` hors `app_radius.dart` (`:311-314`) ; vocabulaire périmé (`:92-99,317-328`) ; `IconData(`/`Icons.`/`phosphor_flutter` hors `app_icons.dart` (`:104-106,331-336`) ; `onTap:` hors `Pressable` et exemption `sous_navigation_domaine.dart` (`:107,115,339-343`) ; boutons Material (`:124-126,347-349`) ; `showDialog` hors `confirm_destructive.dart` (`:243-249,356-361`) ; `PressionForcee` hors galerie (`:133,364-370`) ; emoji et M-dash (code et i18n, `:204-207,373-378,490-513`) ; directionnalité (`fromLTRB`, `Alignment.*Left/Right`, `left:/right:` dans `EdgeInsets.only`/`Positioned`, `:143-160,384-395,589-640`) ; `Scaffold` nu dans `lib/features/` (`:173,401-406`) ; `Container(decoration:)` dans `lib/features/` (`:237,648-685`) ; tags de conformité fermés (`:193-203,411-414`) ; `PermanentNotice` sans paramètre (`:231-233,440-461`) ; routeur unique (`:134,269-276,479-488`) ; pas de fichier de routes par mode (`:465-477`) ; échelle d'espacement (`:29-41,534-580`).

**Aucune règle sur les polices.** Propositions :

1. **Nouvelle règle `police-hors-typographie`** : interdire `\bfontFamily\s*:` hors `core/theme/app_typography.dart` et `core/icons/app_icons.dart`. La galerie (`galerie_page.dart:637,644,670`) serait en violation : soit exemption nominative `features/_dev/` comme pour `PressionForcee`, soit réécriture de la galerie avec les styles du thème (préférable). L'expression `\bfontFamily\s*:` ne capture pas `fontFamilyFallback:`.
2. **Mettre à jour `vocabulairePerime`** (`:92-99`) : les messages de remplacement pointent vers `BricolageGrotesque`/`InstrumentSans` ; les faire pointer vers `DMSans`/`PlusJakartaSans`, et ajouter `BricolageGrotesque` et `InstrumentSans` comme vocabulaire périmé. Attention : `\bNotoSans\b` n'attrape pas `NotoSansArabic` (pas de frontière de mot), comportement à conserver. Les chaînes `'InstrumentSans : ...'` de la galerie (`:634,641`) déclencheraient la règle : à réécrire.
3. **Optionnel, liste fermée des familles** : un contrôle que les `family:` de `pubspec.yaml` sont exactement {UthmanTahaNaskh, NotoSansArabic, PlusJakartaSans, DMSans, Phosphor, PhosphorFill} et que les constantes `AppFontFamily` y figurent. Le vérificateur ne lit aujourd'hui que `lib/**/*.dart` et `assets/i18n` (`:255-260,491`) ; ce contrôle serait mieux placé dans `test/theme/typographie_test.dart` (lecture de `pubspec.yaml`).
4. **Optionnel** : interdire `.copyWith(fontWeight:` hors thème (piège 9.3-3), aujourd'hui zéro occurrence.

---

## 11. Tests existants qui figent la typographie ou les jetons

- `rg "Bricolage|InstrumentSans" test lib tool` : **aucun test** ne cite ces noms ; seuls `lib/core/theme/app_typography.dart`, la galerie, `tool/verifier_jetons.dart:97-98`, `lib/CLAUDE.md:58` et `pubspec.yaml` les citent.
- `test/theme/typographie_test.dart:7` : `headlineSmall.fontFamily == AppFontFamily.corps` -> **cassera** si `headlineSmall` passe en DM Sans. Les tailles figées `:8-11,15-16` (titleLarge 22, bodyLarge 16, bodyMedium 14, labelMedium 12, enfant titleLarge 32, bodyLarge 20) restent vraies si l'échelle ne change pas. `:17-18` fige `document()`.
- `test/widgets/composants_test.dart:387-397` : vérifie la présence de `tabularFigures` sur `StatTile` (voir piège 9.3-2).
- `test/theme/mouvement_test.dart:6-10`, `elevation_test.dart:6-19`, `contraste_test.dart:40-44`, `contraste_sombre_test.dart:38-40` : figent des valeurs de jetons non typographiques.
- Base mesurée le 24/09 : `flutter test test/theme` -> **9/9 PASS** (sous verrou `flutter-verrou.ps1`).
- Tests à ajouter lors de la bascule (proposition) : pour chaque rôle, famille attendue selon 9.2 ; présence de `wght` dans les bornes de l'axe ; présence et borne de `opsz` pour tout style DM Sans ; `display*` en Jakarta avec `tnum` ; `AppFontFamily` cohérent avec `pubspec.yaml`. Rappel : ces tests prouvent la configuration, pas le rendu.

---

## 12. Icônes (`lib/core/icons/app_icons.dart`)

`AppIcon(repos, actif)` avec `resoudre(selectionne:)` (`:9-20`) ; Phosphor Regular/Fill en assets (`:41-42`) ; seul fichier autorisé à construire un `IconData` (`:24-29`).

Utiles au tuteur, déjà présents : `accueil` (`:47`), `foyer` (`:67`), `suivi` (`:59`), `profil` (`:99`), `notifications` (`:163`), `reglages` (`:79`), `qr` (`:287`), `appareil` (`:293`), `camera`/`cameraCoupee` (`:196-205`), `sortie` (`:208`), `horsLigne` (`:251`), `rienAAfficher` (`:263`), `avatarSansPhoto` (`:269`), `succes` (`:275`), `avertissement` (`:281`), `ajouter` (`:311`), `chevron` miroité RTL (`:330`), `menuDeroulant` (`:343`), `effacer` (`:305`), `libelleAudio` (`:245`), `tabletteOuOrdinateur` (`:363`), `fichierPdf`, `lecon`, `bibliotheque` (`:369-396`), `observationFermee` (`:489`), `recherche` (`:157`).

Sur `observation/lot-2026-09-21` (non fusionnée) : `observationEnCours` 0xe220, oeil ouvert (+18 lignes, `git diff main...observation/lot-2026-09-21 -- lib/core/icons/app_icons.dart`).

Absents sous un nom sémantique (glyphes à relever dans la police, jamais devinés, comme le fait l'entrée ci-dessus) : son reçu / coupé côté écoute, agrandir / plein écran, fermer (croix), retour (flèche gauche, hors `AppBar`), flèche « suivant » d'un CTA, calendrier / planning (seul `planningGlobal` admin existe), horloge, cadenas / sécurité, bouclier, aide, carte de paiement / reçu, document légal, filtre, photo (appareil photo), crayon (modifier), soleil / lune (bascule de thème), déconnexion distincte de `sortie`, information, casque (écouter), check de consentement. Toutes apparaissent dans les maquettes ouvertes.

Note : la destination secondaire « Compte » du tuteur porte l'icône `sortie` (`lib/core/widgets/nav_shell.dart:163-167`), c'est-à-dire l'icône de sortie de séance.

---

## 13. Composants partagés existants (API publique et usage tuteur)

Les composants listés dans `lib/CLAUDE.md:9-12` sont les points d'entrée uniques de leur fonction : on les améliore, on ne les duplique pas.

| Composant | API publique | Utile au tuteur pour | Écart avec mandat / maquettes |
|---|---|---|---|
| `PageShell` (`page_shell.dart:31-40`) | `child`, `titre?`, `entete?`, `actions?` (zone collée basse), `defilante=true` | toutes les pages | pas d'emplacement d'actions d'en-tête (cloche, bascule de thème, retour rond) ; titre en `headlineLarge` ; porte `OfflineBanner` |
| `PageParcours` (`page_parcours.dart:26-41`) | `numero`, `total`, `question`, `enfant`, `libelleAction`, `onAction?`, `explication?`, `onRetour?`, `enCours`, `minutesRestantes?`, `souscription?` | onboarding, ajout élève | maquette : barre continue (code : segments), bouton retour rond, CTA pilule avec flèche, titre avec mot accentué |
| `PageImmersive` (`page_immersive.dart:49-58`) | `child`, `registre {salle, lecture}`, `entete?`, `bandeau?`, `commandes?` | salle d'observation | registre `salle` = `surfaceInverse` (sombre en clair) ; la maquette d'observation desktop claire est sur fond clair |
| `NavShell` + `destinationsPour` / `secondairesPour` (`nav_shell.dart:49-185,202-285`) | `destinations` (<= 4, assert), `indexActif?`, `onAller`, `child`, `secondaires`, `onAllerSecondaire?` | navigation | tuteur actuel : Accueil (icône foyer), Disponibilités, Réglages, Suivi + Compte secondaire (`:79-100,162-168`) ; cible Accueil · Foyer · Historique · Compte. Maquettes : marque + bouton replier la barre latérale, Compte épinglé en bas, rail tablette sans libellés. Routeur et shell = coordinateur |
| `ActionPrincipale` (`action_principale.dart:47-85`) | `libelle`, `onPress?`, `niveau {principale, secondaire, tertiaire, destructive}`, `enCours`, `pleineLargeur`, `prefixe?` | tous les CTA | pas de suffixe (flèche), pas de forme pilule, principale saturée vs lilas pâle des maquettes, destructif sans fond au repos (« Quitter » a un fond `washAlert`) |
| `AppCard` (`app_card.dart:27-77`) | `child`, `surface?`, `onPress?`, `libelleSemantique?`, `selectionnee`, `contourFort`, `marge?`, `dominante`, `entete?`, `actions?` | blocs Accueil, Compte | conforme à l'esprit ; ombre seulement si `dominante` en clair |
| `SettingRow` (`setting_row.dart:11-33`) | `title`, `icon`, `description?`, `value?`, `controle?`, `onPress?`, `enabled` | Compte, Réglages, fiche élève | chaque ligne est sa propre surface arrondie ; pas de conteneur de groupe à séparateurs ; icône `inkMuted` (maquette : accent) ; pas de variante destructive |
| `SectionHeader` (`section_header.dart:19-40`) | `titre`, `compteur?`, `libelleAction?`, `onAction?` | titres de section | action tertiaire sans flèche (« Voir tout -> ») |
| `StatusPill` + `TonEtat` (`status_pill.dart:13-71`) | `libelle`, `ton` | statuts (Salle ouverte, Présente, Terminée, Interrompue, Limite atteinte) | pastille ronde seulement ; maquettes : variante avec coche et variante sans pastille |
| `EmptyState` + `RegistreVide` (`empty_state.dart:15-74`) | `message`, `invitation?`, `icone?`, `libelleAction?`, `onAction?`, `registre {actionnable, subi, bonneNouvelle}` | vides (aucun cours, aucun résultat) | pas de lien secondaire ; toujours centré plein écran |
| `OfflineBanner` (`offline_banner.dart:32-84`) | aucun paramètre ; lit `horsLigneProvider` (`lib/core/reseau/service_reseau.dart:52-54`) | hors ligne | binaire (interfaces réseau présentes ou non), pas d'état « reconnexion » ni « lent », texte « Pas de réseau... » vs mandat « Vous êtes hors ligne » ; `t.reseau.retabli` existe mais n'est pas affiché |
| `Skeleton` (`skeleton.dart:27-89`) | `hauteur`, `largeur?`, `differe` ; `.texte`, `.liste`, `.carteEleve`, `.tuileBento`, `.ligneTimeline` | chargement initial | pas d'état « chargement prolongé » |
| `ConfirmDestructive` (`confirm_destructive.dart:27-95`) | `question`, `consequence`, `libelleConfirmer`, `onConfirmer`, `onAnnuler`, `irreversible` ; `static demander(...)` -> `Future<bool>` | retrait d'appareil, de profil | toujours en feuille basse, même sur desktop (mandat : pas de bottom sheet mobile étiré sur desktop) ; `showDialog` n'est autorisé que dans ce fichier |
| `AppBottomSheet` (`app_bottom_sheet.dart:21-116`) | `titre`, `child`, `actions?` ; `static ouvrir<T>(context, titre:, constructeur:, actions:)` | feuilles | voile clair en sombre (§4) ; pas de variante dialogue desktop |
| `LocalFeedback` (`local_feedback.dart:27-55`) | `message?`, `libelleAnnuler?`, `onAnnuler?`, `persistant` | retours d'action | - |
| `AvatarTile` (`avatar_tile.dart:28-44`) | `prenom`, `urlSignee?`, `diametre?` | sélecteur de profils, fiche | pas d'anneau de sélection, pas de pastille d'état, pas d'état « photo en cours d'envoi » |
| `ChildCard` + `EtatEnfant` scellé (`child_card.dart:20-139`) | `prenom`, `etat`, `urlAvatar?`, `onOuvrir?`, `onPoserHoraire?`, `onAssister?`, `horsLigne`, `onReessayer?` | à revoir | états `EnfantSansPlanning` (« Proposer des heures ») et `EnfantEnRecherche` (« En recherche d'un enseignant ») relèvent du matching individuel abandonné (`CLAUDE.md` racine, « Le matching individuel... est remplacé ») |
| `ChoiceCardGroup` (`choice_card_group.dart:53-81`) | `options: [OptionChoix{valeur, libelle, icone?}]`, `onChange`, `selectionMultiple`, `valeurInitiale?`, `autoriserSaisieLibre=true` | onboarding (usage, questions) | **pas de description par option** (le mandat impose une description pour « Moi uniquement » / « Moi et ma famille ») ; disposition verticale seulement (maquette : cartes en deux colonnes avec radio en haut) ; carte « Autre » par défaut |
| `FilterPill` (`filter_pill.dart:25-47`) | `libelle`, `onPress?`, `retenue`, `compteur?` | filtres fermés | - |
| `MenuFiltre<T>` (`menu_filtre.dart:54-74`) | `libelle`, `valeur?`, `entrees: [EntreeFiltre{valeur?, libelle, compteur?}]`, `onChoix` | filtres Classe / Période / Statut de l'Historique | pas d'icône de tête (maquette : icônes) |
| `MenuActions` (`menu_actions.dart:36-44`) | `actions: [EntreeAction{libelle, onChoix, destructif}]`, `tooltip?` | actions rares d'une ligne | - |
| `DataCollection<T>` (`data_collection.dart:96-123`) | `colonnes: [ColonneDonnees{titre, texte, role, flex, tabulaire, rendu?, rendreMemeSiTexteVide}]`, `lignes`, `piedDePage?`, `cle?`, `onSelectionner?` | historique admin des observations | tableau seulement >= 1200 ; pas de tri (maquette : « Date v ») |
| `SignalRow` (`signal_row.dart:21-47`) | `phrase`, `icone`, `onPress`, `anciennete?`, `ton` | blocage utile (« Aucun appareil prêt ») | maquette : bouton d'action à droite, pas un chevron |
| `StatTile` (`stat_tile.dart:22-46`) | `valeur`, `libelle`, `onPress?`, `ton` | peu (mandat : éviter les compteurs décoratifs) | - |
| `ScheduleOption` (`schedule_option.dart:13-31`) | `day`, `hours`, `onSelected?`, `timeZone?`, `recurrence?`, `selected`, `enabled` | catalogue de classes | une option = un créneau ; une classe V2 a plusieurs séances hebdomadaires |
| `LignePresence` (`ligne_presence.dart:28-49`) | `nom`, `vue: VuePresence`, `role?`, `afficherConsolide` | présence en vérification, jamais « Absence » inventée | - |
| `PinPad` (`pin_pad.dart:24-41`) | `onCodeComplet(String)`, `longueur=4`, `enErreur` | appareil partagé, PIN | chiffres en `headlineMedium` (voir §9) |
| `AudioLabel` (`audio_label.dart:23-45`) | `cle: CleAudio`, `afficherTexte`, `surface?` | Interface guidée | - |
| `SousNavigationDomaine` (`sous_navigation_domaine.dart:21-33`) | `onglets: [(libelle, chemin)]`, `indexActif` | éventuellement « Séances / Observations » si ce sont deux routes | onglets `TabBar`, pas un contrôle segmenté comme la maquette |
| `BandeauObservation` (`bandeau_observation.dart:35-40`) | `observation: Observation` | **rien** : agent IA (ADR-025) | ne pas réutiliser pour la notice tuteur |
| `PermanentNotice` (`permanent_notice.dart:25-32`) | aucun paramètre (vérifié par l'outil) | salle élève/enseignant | hors périmètre tuteur |
| `MarquePage` (`marque_page.dart:13-15`) | aucun | en-tête « Rewayah » de la barre latérale | texte seul, pas de logo |
| `AdminShell` (`admin_shell.dart:43-78`) | `domaines`, `domaineActif?`, `onAller`, `onCompte`, `child` | vue admin des observations | - |
| Autres (`BentoTile`, `TimelineRow`, `RosaceVerset`, `SelecteurNiveauProgramme`) | - | non pertinents pour le tuteur | - |

Hors `core/widgets` mais existants et à ne pas dupliquer : `lib/features/tc_observation_ui/` (`PanneauObservationTuteur` `panneau_observation_tuteur.dart:34`, `IndicateurObservation` et `IndicateurObservationEnfant` `indicateur_observation.dart:48,131`, `EntreeObservationPage` `entree_observation_page.dart:51`, `ChoixEntreeObservation`, `ModuleReglagesObservation`) ; `AttentePage` avec `_Contenu`, `_Incomplet`, `_Refuse`, `_Indisponible`, `_Deconnexion` (`lib/features/dossier/attente_page.dart:31-297`) pour « dossier en attente / suspendu ». Propriété : lots Cours et Admission, pas C02.

---

## 14. Composants manquants

### 14.1 Famille d'états système (mandat §8) : inventaire

| État du mandat | Existant | Manque |
|---|---|---|
| Chargement initial | `Skeleton` (délai 180 ms) | rien, sauf squelettes aux formes des nouveaux écrans |
| Chargement prolongé | aucun | composant qui bascule après un seuil vers « La connexion prend plus de temps que prévu » + Réessayer / Revenir ; **aucune politique de timeout centralisée** dans `lib/core` (rg `timeout` : une seule mention en commentaire, `lib/core/video/video_session_provider.dart:127`) : à créer comme jeton documenté (ex. `AppDelais` à côté d'`AppMouvement`), pas en littéral d'écran |
| Hors ligne | `OfflineBanner` binaire ; `ChildCard.horsLigne` | libellé du mandat, mention du contenu en cache, action de reprise |
| Reconnexion | aucun (`t.reseau.retabli` inutilisé) | état discret borné |
| Échec serveur | écrans ad hoc (`_Indisponible` dans `attente_page.dart:264`, `admin_dossiers/dossiers_page.dart:432`, `_EtatErreur` en galerie `compte_galerie.dart:263`) | **bloc d'erreur** qui conserve le reste de la page (titre humain, phrase, Réessayer, lien secondaire) |
| 404 | aucun ; pas d'`errorBuilder` (`lib/core/router/app_router.dart:95-106`), donc page d'erreur par défaut de `go_router` | page globale « Cette page est introuvable » (routeur = coordinateur) |
| Accès refusé | aucun composant | page globale sans fuite de données |
| Session expirée | aucun composant | page ou feuille de reconnexion avec retour à la destination |
| Dossier en attente / suspendu | `AttentePage` (feature) | rien de nouveau ; réutiliser |
| Aucun résultat / aucun cours | `EmptyState` (3 registres) | variante « réinitialiser les filtres » (action secondaire), variante en bloc (non plein écran) |
| Permission refusée (caméra) | aucun | état contextualisé avec alternative (saisie du code) ; propriété lot Appareils |
| Ressource supprimée / expirée | aucun | page ou bloc avec retour contextualisé |

Proposition d'architecture (à valider par le coordinateur, qui possède les composants partagés) : **un seul composant de base, deux portées**, par exemple `EtatSysteme` avec `portee {bloc, page}`, `nature {chargementProlonge, horsLigne, reconnexion, echecServeur, introuvable, accesRefuse, sessionExpiree, permissionRefusee, ressourceExpiree}`, `titre?` et `phrase?` (défauts i18n par nature), `libelleAction?/onAction?`, `libelleSecondaire?/onSecondaire?`. Construit sur `EmptyState` (même grammaire : icône, titre, phrase, une action) et `ActionPrincipale`, rendu dans `PageShell` en portée page. Le squelette, `OfflineBanner` et `EmptyState` restent les points d'entrée de leur fonction (ne pas les remplacer). Clés i18n `commun.etats.*` à créer.

Remarque : `EcranAConstruire` (`lib/core/router/ecran_a_construire.dart:24-25`) monte un `Scaffold` + `AppBar` nus ; le vérificateur ne le voit pas car il ne contrôle les `Scaffold` que sous `lib/features/` (`tool/verifier_jetons.dart:401-406`).

### 14.2 Autres composants absents, demandés par les maquettes ouvertes

1. **Sélecteur de profils élèves** : rangée d'avatars ronds, anneau de sélection, pastille d'état, prénom et ligne d'état, entrée « Ajouter » (Accueil et Historique). Construire sur `AvatarTile` (lui ajouter anneau et pastille plutôt que dupliquer).
2. **Contrôle segmenté** « Séances / Observations » (Historique) ; M3 `SegmentedButton` est un bouton Material non listé par la règle `bouton-material` (`tool/verifier_jetons.dart:124-126` ne vise que `Elevated|Text|Outlined|Filled|Icon Button`) mais porte la palette Material : à envelopper ou écrire sur `Pressable`.
3. **Groupe de réglages** : carte avec en-tête (icône ronde, titre, résumé, pastille) et lignes `SettingRow` séparées par des filets (Mon compte).
4. **Bascule de thème** soleil / lune et branchement réel de `PreferenceTheme` (§4).
5. **En-tête de page à actions** : retour rond, titre et sous-titre, actions de fin (cloche avec point de notification, réglages). `PageShell` n'a pas ces emplacements.
6. **Lien avec flèche** (« Voir tout -> », « Retour à la classe -> ») et suffixe icône d'`ActionPrincipale`.
7. **Barre de commandes d'observation** : Son reçu (bascule), Agrandir, Quitter ; minuteur « Visite 1/2 · 01:42 » en chiffres tabulaires (Jakarta). Propriété lot Cours ; `PageImmersive` sert de coquille.
8. **Ligne clé / valeur** (détail d'observation : Tuteur, Durée totale ; visites avec heures et motif de fin).
9. **Case de consentement** non précochée avec texte long (onboarding, « J'accepte ces modalités ») : aucun composant de case partagé ; `Checkbox` Material à habiller.
10. **Liste de caractéristiques** (icône ronde, titre, description) de l'explication de première utilisation.
11. **Pastille d'état avec coche** (« Compte vérifié », « Accès actif ») : variante de `StatusPill`.
12. **Groupe d'avatars empilés** (« 4 membres liés ») sur les teintes d'identité existantes.
13. **Variante dialogue de `ConfirmDestructive` / `AppBottomSheet` pour desktop** (mandat §7 et §7 observation : pas de feuille mobile étirée).

---

## 15. Contradictions et points à arbitrer

| # | Contradiction | Sources | Proposition |
|---|---|---|---|
| 1 | « Jakarta est déjà déclarée dans les jetons » : faux | mandat partie observation §1 vs `app_typography.dart:15-31`, `pubspec.yaml:96-139`, historique de toutes les branches | ajouter `PlusJakartaSans` en remplacement d'`InstrumentSans`, consigner |
| 2 | « BricolageGrotesque pour les titres » : faux depuis `cb3a220` | `app_typography.dart:25-26`, `pubspec.yaml:120-124` vs `:150-166` | le passage à DM Sans réintroduit en fait une famille de titres |
| 3 | DM Sans pour tous les titres vs chiffres tabulaires | mandat vs absence de `tnum` mesurée | `display*` et codes en Jakarta ; titres en DM Sans |
| 4 | `titleMedium` libellé ou titre ? | usages `lib/` vs maquettes | arbitrage coordinateur (9.1-2) |
| 5 | Action principale saturée vs lilas pâle | `action_principale.dart:194-204` vs maquettes | arbitrage visuel |
| 6 | « Cours en cours » interdit, mais la partie principale du mandat demande « Cours toujours en cours » pour une séance prolongée | mandat §5 Accueil vs partie observation §2 ; i18n `assets/i18n/fr.i18n.json:1379,1700,1702,1923,2023` | hors C02 (i18n), à signaler au lot Cours |
| 7 | Durées et gouttières documentées différentes des jetons | §6 | corriger les commentaires lors d'un passage sur ces fichiers |
| 8 | `inkFaint` « 4,48 » | `lib/CLAUDE.md:45-46` vs 3,55 mesuré | corriger la règle ou la couleur ; ajouter un test d'encres |

---

## 16. Statut des preuves de ce rapport

| Affirmation | Statut |
|---|---|
| Structure et valeurs de thème, palette, échelle | lu dans le code (présent dans le code) |
| Axes, fonctions OpenType, métriques, couverture des polices | mesuré sur les binaires (script Python dans le scratchpad) |
| Contrastes | calculés (formule WCAG), non mesurés à l'écran |
| Baseline `verifier_jetons` | exécuté localement : 0 violation |
| Baseline `flutter test test/theme` | exécuté localement : 9/9 PASS |
| Rendu visuel des défauts (voile sombre, débordements, crénage DM Sans) | **non vérifié** : aucune capture produite en phase lecture seule |
| Application des variations au repli arabe, `opsz` automatique | INCONNU |
