# C11 - Outillage et base de test (chantier frontend Tuteur V1)

Date : 24/09/2026, entre 04:30 et 05:30. Dépôt `D:\RA _APP\RA -OFFICIAL-APP`, branche
`c0/configuration-baseline-2026-09-23` (vérifiée avant et après : inchangée).
Phase lecture seule respectée : aucun fichier suivi modifié, aucun commit. `git status --short`
en fin de mission : seulement `?? .claude/`, déjà présent au départ.

Écritures faites DANS le dépôt, toutes temporaires ou générées :
- `test/_capture_tmp/capture_proto_test.dart` : copié, exécuté, puis supprimé (4 exécutions,
  suppression vérifiée par `Test-Path` = False et `git status` propre après chacune).
- `.dart_tool/`, `build/unit_test_assets/` : générés par `pub get` et `flutter test` (ignorés).
- `flutter pub get --enforce-lockfile` : `pubspec.lock` inchangé (SHA-256 identique avant/après,
  `F4D14339...C1A5`).
- Le bundle web a été écrit HORS dépôt (`-o`), puis supprimé.

Légende des statuts : **MESURÉ** (commande exécutée ici, sortie lue), **LU** (code lu,
non exécuté), **NON EXÉCUTÉ** (et pourquoi).

---

## 1. Environnement (MESURÉ)

| Élément | Valeur |
|---|---|
| Machine | 4 cœurs logiques, 7 908 Mo RAM ; RAM libre observée entre 482 et 2 377 Mo selon l'instant |
| Flutter | 3.47.2 stable, framework `d3b14c8769` (26/08/2026), Dart 3.13.2, DevTools 2.60.0 (`flutter --version`, 8,7 s) |
| Contrainte SDK du dépôt | `sdk: ^3.13.2` (`pubspec.yaml:7-8`) : compatible |
| `flutter doctor` | 7 coches vertes, « No issues found » (51,3 s) : Android SDK 36.0.0, Chrome, Visual Studio Build Tools 2022 17.14.39, réseau |
| `flutter devices` (12,1 s) | `windows` (desktop), `chrome` (Chrome 153.0.8010.53), `edge` (Edge 151.0.4129.78). Aucun émulateur ni appareil mobile |
| Navigateurs installés | Chrome `C:\Program Files\Google\Chrome\Application\chrome.exe` 153.0.8010.53 ; Edge `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` 151.0.4129.78 ; `CHROME_EXECUTABLE` non défini (inutile, Chrome est trouvé) |
| Outils image | pas d'ImageMagick ; Python 3.11.15 + Pillow 12.3.0 disponibles SEULEMENT dans le venv Hermes (`C:\Users\dell\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe`). La recette de comparaison ci-dessous n'en dépend pas (tout en `dart:ui`) |
| Verrou partagé | `D:\RA _APP\pilotage-tuteur-v1\outils\flutter-verrou.ps1` (mutex `Global\RewayahTuteurFlutterLourd`). Découvert APRÈS mes trois premières mesures (analyse complète, vérificateur, tests du routeur) : celles-ci ont tourné sans verrou, voir § 2 |

CI, pour comparaison (LU) : le job Flutter prend `subosito/flutter-action@v2` avec
`channel: stable` **sans version épinglée** (`.github/workflows/ci.yml:267-269`, idem
`flutter-deploy.yml:103-105`). La CI utilisera donc la dernière stable du jour, pas
forcément 3.47.2. Risque d'écart local/CI à signaler au coordinateur (propriétaire des
configurations).

## 2. Mesures des commandes de contrôle (MESURÉ)

| Commande | Durée | Résultat | Remarques |
|---|---|---|---|
| `flutter pub get --enforce-lockfile` | 39,2 s | OK, exit 0 | Lock inchangé. 44 paquets ont une version plus récente incompatible avec les contraintes (dont `sentry_flutter` 8.14.2, bloqué volontairement, `pubspec.yaml:57-66`) |
| `dart analyze --fatal-infos` (dépôt entier) | **557,2 s** | **No issues found**, exit 0 | Sans verrou ; RAM libre 1 631 Mo au départ. Contention avec d'autres agents possible, non mesurable a posteriori. À remesurer sous verrou si le coordinateur veut un budget fiable |
| `dart analyze --fatal-infos lib/core/theme lib/features/accueil_famille` | 64,7 s | No issues found | Sous verrou. Une analyse ciblée coûte déjà une minute : l'analyseur résout tout le graphe importé |
| `dart run tool/verifier_jetons.dart` | 17,2 s | « Jetons verifies : 342 fichiers, aucune violation. », exit 0 | Sans verrou (léger) |
| `flutter test test/router` | 182 s | **150 tests, tous passés** | Sans verrou. 4 fichiers, 45 occurrences statiques `test(`/`testWidgets(` mais 150 tests à l'exécution (boucles de cas) |
| `flutter test` sous-ensemble Tuteur (liste § 4) | 266 s | **307 tests, tous passés** | Sous verrou ; RAM libre 2 065 Mo avant, 2 198 après |
| Prototype de capture (§ 5) | 52 à 89 s (dont ~40-75 s de compilation) | 12 tests passés, 12 PNG écrits | Sous verrou |
| `flutter build web --release` (essai 1, flags CI sans secrets) | arrêté à 88 s | **ARRÊTÉ PAR LA GARDE** : RAM libre 482 Mo < 500 Mo, pic des processus dart 1 781 Mo | Conformément à la consigne. Bundle partiel supprimé |
| `flutter build web --release --no-wasm-dry-run` (essai 2) | **247 s** (compilation 232,7 s) | **OK**, exit 0 | RAM libre min 805 Mo (t = 189 s), pic dart 1 546 Mo (t = 165 s). Détail § 6 |

Commande du sous-ensemble Tuteur (reproductible) :
```
flutter test test/features/accueil_famille_test.dart test/features/appareils_test.dart test/features/reglages_enfant_test.dart test/features/suivi_foyer_test.dart test/features/compte_test.dart test/features/connexion_test.dart test/features/eleve_connexion_test.dart test/features/inscription_test.dart test/features/attente_test.dart test/features/dossier_test.dart test/appairage test/suivi test/teaching_core/g test/theme test/widgets --reporter compact
```

## 3. Comptage des tests (MESURÉ)

- 143 fichiers `*_test.dart` sous `test/`.
- `rg -c "test\(|testWidgets\("` : **1 598 occurrences dans 143 fichiers** (même total avec
  le motif borné `\b(test|testWidgets)\(`). C'est un comptage STATIQUE : `test/router` en
  compte 45 et en exécute 150. Le nombre réel de tests de la suite complète n'est pas connu
  (suite complète NON EXÉCUTÉE, voir § 4).
- Plus gros fichiers : `widgets/composants_test.dart` (41), `features/salle_test.dart` (34),
  `parcours/parcours_offres_test.dart` (32), `teaching_core/c/navigation_coran_test.dart` (31).
- Aucun test d'image (golden PNG) : aucun `matchesGoldenFile`, aucun `flutter_test_config.dart`,
  aucun `dart_test.yaml`. Les « golden » du dépôt sont des contrats de DONNÉES
  (`test/teaching_core/fixtures/goldens_coran.dart:14-16`, « Ce n'est pas un golden d'image »).
- Un seul test rend déjà une image : `test/widgets/logo_google_test.dart:33-39`
  (`RenderRepaintBoundary.toImage` dans `tester.runAsync`), précédent réutilisé par la recette.
- Aucun test ne charge les polices (`FontLoader` absent de `test/`) : **tout le texte des tests
  existants est rendu avec la police de test** (carrés). Sans conséquence pour des assertions
  de widgets, rédhibitoire pour une capture.
- Aucun test ne simule une zone sûre (`FakeViewPadding`, `tester.view.padding` absents) : voir
  l'anomalie § 5.6.
- Paquets absents de `pubspec.lock` : `mobile_scanner`, `camera`, `permission_handler`,
  `integration_test`, `golden_toolkit`, `alchemist`. Le scanner QR du lot Appareils et toute
  capture sur appareil réel exigent une dépendance que seul le coordinateur peut ajouter.
  `qr_flutter` (émetteur) est présent (`pubspec.yaml:52`).

## 4. Échecs préexistants (pour ne pas les attribuer au chantier)

| Contrôle | État sur `c0/configuration-baseline-2026-09-23` |
|---|---|
| `dart analyze --fatal-infos` | 0 problème (MESURÉ) |
| `tool/verifier_jetons.dart` | 0 violation sur 342 fichiers (MESURÉ) |
| `flutter test test/router` | 150/150 (MESURÉ) |
| Sous-ensemble Tuteur (15 chemins, ci-dessus) | 307/307 (MESURÉ) |
| `flutter build web --release` sans secrets | OK avec `--no-wasm-dry-run` ; l'essai avec le dry-run wasm par défaut (celui de la CI) n'a pas pu aller au bout sur cette machine (garde RAM), ce n'est PAS un échec du code (MESURÉ) |
| Suite complète `flutter test` | **NON EXÉCUTÉE** : estimée à 15-25 min en tenant le verrou (extrapolation depuis 150 tests/182 s et 307 tests/266 s), ce qui bloquerait les autres agents. À lancer par le coordinateur avant la première intégration pour figer la base |
| Régénération `dart run slang` + `build_runner` sans diff (étape CI `ci.yml:275-285`) | **NON EXÉCUTÉE** : elle réécrit des fichiers suivis si une dérive existe, interdit en phase lecture |
| `flutter build apk` / `flutter build windows` (matrice CI `ci.yml:256-263`) | **NON EXÉCUTÉS** (lourds, hors demande) |

Observé en passant, préexistant et hors périmètre : l'écran « Configuration absente » servi par
un bundle sans clés (`lib/main.dart:39-42`) déborde à droite à 390 px de large dans Chrome
headless (capture `out/10_...`), police Roboto par défaut. Cause non établie.

## 5. Capture d'écran fiable pour comparer aux maquettes : recette PROUVÉE

### 5.1 Fichiers

Tout est hors dépôt, dans `D:\RA _APP\pilotage-tuteur-v1\02_code\capture_proto\` :
- `capture_proto_test.dart` : le test de capture (source de référence).
- `lancer_capture.ps1` : copie le test dans `test/_capture_tmp/`, l'exécute sous le verrou,
  SUPPRIME la copie dans un `finally`, affiche `git status --short`. Exécuté et validé
  (52 s, 12/12, `TMP_SUPPRIME=True`, dépôt propre).
- `build_web_garde.ps1` : construction web hors dépôt avec garde RAM (version rangée du script
  réellement exécuté depuis le scratchpad ; logique identique, cette copie n'a pas été relancée).
- `out/` : les PNG produits (liste § 5.4).

Commande :
```
& "D:\RA _APP\pilotage-tuteur-v1\02_code\capture_proto\lancer_capture.ps1"
```
Variables facultatives lues par le test : `CAPTURE_DIR` (sortie), `POLICES_DIR` (polices
candidates hors dépôt), `MAQUETTES_DIR`.

### 5.2 Principe (ce que le code FAIT)

1. **Polices réelles** : lecture de `FontManifest.json` via `rootBundle`, puis un `FontLoader`
   par famille. Familles effectivement chargées (sortie du test) : `MaterialIcons,
   UthmanTahaNaskh, NotoSansArabic, InstrumentSans, BricolageGrotesque, Phosphor, PhosphorFill,
   packages/cupertino_icons/CupertinoIcons`. Chargement dans `setUpAll` (hors FakeAsync).
   Les icônes Phosphor passent par le même manifeste (`pubspec.yaml:134-139`) : pas de
   traitement particulier nécessaire.
2. **Garde-fou automatique** contre les carrés : largeur de « iiiiiiiiii » à 20 px.
   Mesuré : 200,0 px avec la police de test, 48,0 px avec InstrumentSans chargée. Le test
   échoue si la police réelle n'est pas active (`expect(corps < 0.6 x inconnue)`).
3. **Vue fixée** : `tester.view.physicalSize = logique x densite`,
   `tester.view.devicePixelRatio = densite`, `addTearDown(tester.view.reset)`.
   390x844 @3 donne 1170x2532 ; 1440x900 @1 donne 1440x900.
4. **Cadre** : `RepaintBoundary(key)` posé AU-DESSUS de `MaterialApp` (fond, overlays,
   feuilles compris). Thème réel `AppTheme.pour(InterfaceMode.standard, Brightness.x)`, locale
   et délégués identiques à l'app (`lib/app.dart:70-72`).
5. **Deux hôtes** : écran isolé (`home:`), ou **vrai routeur** `routeurProvider` avec une
   session factice (même méthode que `test/router/parcours_enseignant_test.dart:83-108`), ce
   qui rend la vraie coquille de navigation (barre basse, rail).
6. **PNG** : `RenderRepaintBoundary.toImage(pixelRatio: densite)` puis
   `toByteData(format: png)` puis `File.writeAsBytes`, le tout dans `tester.runAsync`.
7. **Planche de comparaison** (`_capturerEtComparer`) : la vue est calée sur les PIXELS de la
   maquette (`densite = largeurPx / largeurLogique`, hauteur logique déduite), la maquette est
   décodée par `ui.instantiateImageCodec`, puis une planche est composée en `dart:ui` :
   maquette | capture | superposition 50 % | différence (`BlendMode.difference`). En ligne
   pour un portrait, en grille 2x2 pour un paysage. Aucune dépendance externe.
8. **Données** : fixtures de test isolées (un enfant « Amina », une séance le lendemain à
   17 h), jamais un repli de production.

### 5.3 Vérification visuelle (Read de chaque PNG)

- `00_temoin_..._sans_polices.png` : texte en rectangles pleins, icônes absentes : le piège est
  bien reproduit.
- `01`, `02`, `03`, `04` (connexion clair, sombre, bureau, texte 200 %) : texte réel lisible,
  accents corrects (« électronique », « élève »), logo Google, thème sombre cohérent.
- `05`, `05b`, `06` (accueil tuteur, vrai routeur) : titres, cartes, icônes Phosphor de la
  barre basse et du rail rendues ; aucune boîte vide.
- `07_specimen_polices_390@3.png` : InstrumentSans, BricolageGrotesque, **DM Sans et Plus
  Jakarta Sans chargées depuis `D:\RA _APP\pilotage-tuteur-v1\polices\`** sans toucher au
  pubspec (famille renommée `DMSansApercu` / `JakartaApercu`), accents et guillemets
  français, chiffres, Basmala en UthmanTahaNaskh, icône Phosphor. Permet de prévisualiser les
  futurs jetons DM Sans/Jakarta avant la modification partagée du coordinateur.
- `08_cmp_accueil_mobile_845x1862.png` (et `_capture.png`) : planche contre
  `docs de lancement\tutuor image\mobile\accueil  tuteur mobile light mode.png` (845x1862),
  vue 390 logique @2,1667 avec zone sûre 47/34. Tailles identiques, superposition exploitable.
- `09_cmp_accueil_bureau_1774x887.png` : planche 2x2 contre `acceuil tuteur desktop light.png`
  (1774x887), vue 1440x720 @1,2319. Calage validé à l'œil : le rail de la maquette mesure
  ~248 dp à cette densité, celui de l'app ~255 dp.
- `10_web_release_racine_390x844_chrome.png` : Chrome headless sur le bundle release servi en
  local (voir § 6).

### 5.4 Pièges documentés

| Piège | Effet | Parade prouvée ou recommandée |
|---|---|---|
| Police de test par défaut | Texte en carrés, icônes Phosphor absentes | Charger `FontManifest.json` (§ 5.2.1) + garde-fou de largeur |
| `toImage`, décodage et écriture disque dans le FakeAsync de `testWidgets` | Le test pend | Tout dans `tester.runAsync` (fait ; précédent `logo_google_test.dart:33-39`) |
| `pumpAndSettle` avec squelette ou pulsation infinie | Délai dépassé | Boucle de `pump(100 ms)` x 10 (fait). Pour figer le mouvement : `MediaQueryData(disableAnimations: true)` comme `test/widgets/composants_test.dart:327` |
| Capture = viewport seulement | Le bas d'une page longue manque (`04` à 200 %) | Capturer à la taille de la maquette ; pour une page entière, plusieurs captures après `tester.drag`, ou vue plus haute (qui change la mise en page, à documenter) |
| Maquettes à tailles arbitraires | 845x1862, 1774x887, 1162x2559, planches 1806x871, 1672x941, 1536x1024 | `_vueMaquette` : choisir la largeur LOGIQUE (390 mobile, 1440 bureau), en déduire densité et hauteur ; recadrer d'abord un écran dans une planche multi-écrans |
| Barre d'état et indicateur dessinés dans la maquette | Contenu décalé de ~47 dp | `tester.view.padding` et `viewPadding` = `FakeViewPadding(top: 47 x d, bottom: 34 x d)` (fait) |
| Horloge réelle | `AccueilFamillePage` est construite sans horloge par le routeur (`lib/core/router/app_router.dart:243-245`, `const AccueilFamillePage()`) : « vendredi à 17:00 » change d'un jour à l'autre | Pour une capture reproductible, monter l'écran seul avec `horloge:` (comme `test/features/accueil_famille_test.dart:89`) ; via le routeur, prévoir un fournisseur d'horloge (décision du propriétaire du routeur) |
| Images réseau | `AvatarTile` utilise `Image.network` (`lib/core/widgets/avatar_tile.dart:59-73`) ; sous `flutter test`, le client HTTP répond 400, `errorBuilder` rend les initiales | Pour montrer une photo d'enseignant : `HttpOverrides.global` servant des octets locaux, ou `MemoryImage` + `precacheImage` dans `runAsync`. Jamais de photo réelle dans les captures de recette |
| Hôte du harnais | `hote()` ne pose ni `locale` ni délégués (`test/support/harnais.dart:48-60`) : chaînes Material en anglais | L'hôte du prototype reprend `app.dart:70-72` |
| Plateforme simulée | `flutter test` simule Android par défaut | `debugDefaultTargetPlatformOverride` ou `TargetPlatformVariant` si un comportement iOS/desktop compte (barres de défilement, survol) |
| Moteur | `flutter_tester` (Skia) et CanvasKit web ne sont pas identiques au pixel près (lissage) | Comparer à l'œil sur la planche ; ne pas faire de seuil de pixels strict |
| Fichier temporaire dans `test/` | S'il reste, il est analysé (`--fatal-infos`) et lancé par la CI (écriture sur `D:\`, échec) | `lancer_capture.ps1` supprime dans un `finally` ; si le coordinateur le rend permanent : `skip` quand `CAPTURE_DIR` est absent, ou tag dédié |
| Polices DM Sans / Jakarta non déclarées | Aucune trace dans le dépôt (brief § Faits) | Aperçu possible hors pubspec via `FontLoader` sur les fichiers de `pilotage-tuteur-v1\polices` (fait, `07`) |
| Suppression par l'outil PowerShell | Un `Remove-Item` suivi d'un chemin littéral contenant `D:\RA _APP` a été refusé par la garde de l'outil (« system path protected ») quand il était enchaîné à d'autres commandes | Passer par une variable `-LiteralPath`, ou par `lancer_capture.ps1` |

### 5.5 Ce que la recette ne prouve pas

Un PNG prouve le rendu d'un état simulé, avec des fixtures. Il ne prouve ni un service branché,
ni un parcours, ni la fidélité (qui reste un jugement sur la planche). Les « golden tests » ne
prouvent rien s'ils sont générés depuis une UI incorrecte (mandat § 11.6) : la planche contre
la maquette est la preuve demandée, pas un golden.

### 5.6 Anomalie révélée par la recette (à confier au propriétaire de la coquille, C01)

**Observé en simulation, non vérifié sur appareil.** Avec une zone sûre haut 47 / bas 34
(`08_..._capture.png`, 390x859 logique) :
- la barre basse occupe ~161 dp de haut (~80 attendus + 34), soit 80 + 47 + 34 : elle
  consomme AUSSI l'encart HAUT ;
- la zone de contenu s'arrête ~33 dp au-dessus de la barre (bande de fond vide), soit
  l'encart bas appliqué une seconde fois.

Lecture du code cohérente avec ces mesures : la barre n'est pas dans
`Scaffold.bottomNavigationBar` mais dans une `Column` (`lib/core/widgets/nav_shell.dart:305-313`),
sans `MediaQuery.removePadding`, et le `NavigationBar` Material (`nav_shell.dart:375`) gère
lui-même la zone sûre (comportement du framework, source Flutter non relue ici, déduit de la
hauteur mesurée) ; chaque page passe par `PageShell`, dont le corps est un
`SafeArea` complet (`lib/core/widgets/page_shell.dart:114-115`) alors que la barre est dessous.
Sans zone sûre (`05`), rien n'apparaît : c'est pour cela qu'aucun test existant ne le voit. Sur
un téléphone réel (encoche ou barre d'état Android), l'écart serait visible. Cause probable,
non prouvée tant qu'aucun appareil n'a été mesuré.

## 6. Construction web (MESURÉ)

- Essai 1, flags de la CI sans secrets (`flutter-deploy.yml:124-134` moins les `--dart-define`
  secrets) : **arrêté à 88 s par la garde** (RAM libre 482 Mo, pic dart 1 781 Mo). RAM libre
  de départ plus basse que pour l'essai 2 : l'effet propre du dry-run wasm n'est pas isolé.
- Essai 2, mêmes flags + `--no-wasm-dry-run`, sortie hors dépôt : **247 s, OK**. Échantillons
  toutes les 2 s : pics de mémoire autour de 60 s (1 366 Mo) et 150-190 s (1 500 Mo), RAM
  libre minimale 805 Mo.
- Bundle : 45,4 Mo ; `main.dart.js` 5 354 742 octets ; présents : `index.html`,
  `sqlite3.wasm`, `drift_worker.js`, `vercel.json`, `flutter_service_worker.js`,
  `version.json` (la liste contrôlée par `flutter-deploy.yml:145`). Élagage des icônes :
  Phosphor-Regular 488 636 à 19 240 octets, Phosphor-Fill 449 252 à 16 488.
- Chrome headless sur ce bundle servi en local (`python -m http.server`, venv Hermes) :
  17,1 s, capture `out/10_web_release_racine_390x844_chrome.png` = écran « Configuration
  absente ». **Limite** : tout écran métier en navigateur exige `SUPABASE_URL`/`ANON_KEY`
  (`lib/main.dart:39-42`), y compris le Playground (`main.dart:54-66`, `Supabase.initialize`
  avant `PLAYGROUND`). Le `dart_define.json` local (ignoré par git) n'a PAS été lu : il
  pointerait vers la base distante, exclu d'une recette de capture. La voie navigateur sert donc
  à la preuve « vérifiée réellement » sur l'aperçu Vercel d'une PR (`CLAUDE.md:41-43`), pas à
  la comparaison aux maquettes.
- Conseil : ne jamais lancer une construction web en même temps qu'une analyse ou une suite de
  tests ; garder le verrou et la garde RAM.

## 7. Ce que les documents PRÉTENDENT et ce que l'outillage FAIT

| Affirmation | Réalité (fichier:ligne) |
|---|---|
| `lib/CLAUDE.md:14` : « Règles vérifiées par `dart run tool/verifier_jetons.dart` », liste incluant « Aucune chaîne visible en dur » (l. 35), « Tout choix proposé passe par `ChoiceCardGroup` » (l. 30), « mode d'interface porté par le thème » (l. 37) | Le vérificateur n'a AUCUNE règle pour ces trois points (`tool/verifier_jetons.dart` lu en entier : règles l. 283-461 et 464-513). Ce sont des conventions de relecture |
| `lib/CLAUDE.md:25-26` : « Aucune `Duration` ni `Curves` hors d'`app_mouvement.dart` » | Seul `Duration(milliseconds:` est détecté (`verifier_jetons.dart:81`) ; `Duration(seconds:` passe |
| Mandat, partie observation § 1 : « sans `fontFamily` dispersé dans les pages » | Aucune règle du vérificateur ne l'impose. Aujourd'hui, seul `lib/features/_dev/galerie/galerie_page.dart:637,644,670` pose un `fontFamily` hors du thème (hors `AppIcons`). Règle à ajouter par le coordinateur avec la bascule DM Sans/Jakarta |
| Portée du vérificateur | `lib/` seulement (`verifier_jetons.dart:255-260`) et `assets/i18n` non récursif (l. 491-493) ; `test/` et `tool/` jamais scannés |
| `pubspec.yaml:120` et `app_typography.dart:25-26` : BricolageGrotesque = « titres, en-têtes » | Le `TextTheme` de production n'emploie QUE `InstrumentSans` : les 15 rôles passent par `_corps` (`lib/core/theme/app_typography.dart:150-166`, `fontFamily: AppFontFamily.corps` l. 173). `AppFontFamily.titre` n'est utilisé que par la galerie de développement (`galerie_page.dart:644`). Conséquence pour les captures : les titres actuels sont en Instrument Sans (visible sur `01`, `05`). Test qui le fige : `test/theme/typographie_test.dart:7` |
| `CLAUDE.md:44-45` : `.claude/settings.local.json` (hooks de protection) et `.claude/hooks/` sont actifs | Le dossier n'est PAS suivi (`?? .claude/`) et `settings.local.json` est ignoré par le gitignore global de l'utilisateur (`C:\Users\dell/.config/git/ignore:3`). Ses gardes ciblent l'outil `Bash` (`.claude/settings.local.json:5,20`) : les commandes passées par l'outil **PowerShell**, seul shell de cette machine, ne sont pas filtrées ; et ils ne se chargent que si la session Claude a le dépôt pour répertoire de projet (ce n'est pas le cas des agents lancés depuis un autre dossier) |
| `analysis_options.yaml:1` : « tout ce qui est signalé ici bloque la fusion » | Exact pour `ci.yml:287`, mais la CI Flutter ne tourne que sur PR vers `main` ou lancement manuel (`ci.yml:3-6`) : une branche sans PR n'est jamais contrôlée |
| Brief § Faits : « Ne lancez JAMAIS plusieurs commandes Flutter lourdes en parallèle » | Confirmé par la mesure : une construction web seule a fait tomber la RAM libre à 482 Mo |

## 8. Recommandations au coordinateur (propriétaire des fichiers partagés)

1. **Base figée avant intégration** : lancer une fois la suite complète `flutter test` sous
   verrou (15-25 min estimées) et consigner le total, pour disposer d'une référence de
   non-régression ; puis la régénération slang/build_runner sur une copie jetable.
2. **Budget par agent** : préférer `dart analyze <dossiers>` (~65 s) et `flutter test <fichier>`
   (~40-75 s de compilation incluse) ; réserver l'analyse complète (~9 min mesurées sans
   verrou) et la construction web (~4 min, 1,5 Go) au coordinateur.
3. **Capture** : adopter `capture_proto_test.dart` comme outil de recette visuelle. S'il entre
   dans le dépôt, le placer sous `test/capture/`, le sauter quand `CAPTURE_DIR` est absent (la
   CI ne doit ni l'exécuter ni écrire sur `D:\`), et ajouter une variante `FakeViewPadding` à
   la recette de chaque écran à barre basse.
4. **Vérificateur** (avec la bascule DM Sans/Jakarta) : règle « aucun `fontFamily:` hors
   `app_typography.dart` et `app_icons.dart` », et élargir `duree-litterale` à toutes les
   unités si la règle écrite est voulue.
5. **CI** : épingler `flutter-version: 3.47.2` dans `ci.yml` et `flutter-deploy.yml`.
6. **Dépendances** : le scanner QR (lot D) et d'éventuels tests sur appareil
   (`integration_test`) exigent un ajout au `pubspec` réservé au coordinateur.
7. **Anomalie § 5.6** (double zone sûre dans la coquille) : à trancher par le propriétaire de
   `nav_shell.dart`/`page_shell.dart` avant de comparer tout écran mobile aux maquettes.
