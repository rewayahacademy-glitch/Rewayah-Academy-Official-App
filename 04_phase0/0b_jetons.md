# 0b - Jetons : polices, typographie, palette, thème appliqué, vérificateur

Date : 24/09/2026, 07:40 à 09:20 (+03:00). Worktree `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, base `3cf3544`.
Statut global : **fait, 5 commits locaux, aucun push**. Frontière backend vide (`git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc` : vide).

Arbre de travail : les modifications NON commitées de l'agent 0a (`fr.i18n.json`, `strings*.g.dart`, `port_groupes.dart`, `port_horloge_seance.dart`, `groupes_supabase*.dart`, `horloge_supabase.dart`, `windows/flutter/*`) étaient présentes pendant tous mes tests ; je ne les ai ni touchées ni indexées (chaque `git add` nomme ses fichiers). Aucun fichier de 0d touché (`lib/core/foyer`, `seance_famille`, `capacites`, `tc_observation`, `config`, `planning`, `tc_horloge`, `app_delais.dart`, `test/fixtures`). Aucune clé i18n ajoutée : `dart run slang` et `build_runner` **non exécutés** (rien à régénérer).

## 1. Commits

| Hash | Message | Fichiers |
|---|---|---|
| `fce058b` | feat(theme): polices DM Sans et Plus Jakarta Sans, style chiffre | `assets/fonts/` (+DMSans, +PlusJakartaSans, +2 licences ; -Instrument, -Bricolage, -2 licences), `pubspec.yaml` (section fonts), `lib/core/theme/app_typography.dart`, `lib/core/widgets/pin_pad.dart`, `avatar_tile.dart`, `lib/features/_dev/galerie/galerie_page.dart`, `test/theme/typographie_test.dart`, `test/theme/rendu_polices_test.dart` (nouveau), `test/theme/support/lecteur_police.dart` (nouveau) |
| `a119036` | feat(theme): palette ajustee, CTA doux, points de statut et contrastes | `app_color_pair.dart` (type `AppIndicatorColor`), `app_palette.dart`, `app_theme.dart`, `lib/core/icons/app_icons.dart` (`flecheAction`), `action_principale.dart`, galerie, `test/theme/contraste_test.dart`, `contraste_sombre_test.dart`, `test/theme/support/contraste.dart` (nouveau), `test/widgets/composants_test.dart` |
| `7464821` | feat(theme): la preference Apparence pilote enfin le themeMode | `lib/core/preferences/preferences_locales.dart`, `lib/app.dart`, `app_icons.dart` (`themeClair`, `themeSombre`), `test/theme/theme_applique_test.dart` (nouveau) |
| `c163127` | chore(outils): regle police-hors-typographie et familles autorisees | `tool/verifier_jetons.dart` |
| `1d411b7` | fix(widgets): initiales et chiffres du pave tiennent a 200 % | `avatar_tile.dart`, `pin_pad.dart`, `test/widgets/chiffre_texte_agrandi_test.dart` (nouveau) |

Le 5e commit n'était pas prévu : la capture à 200 % a montré un écrêtage réel (section 5), corrigé dans mes fichiers.

## 2. Ce qui est fait

### 2.1 Polices (priorité du mandat observation §1)
- Copiés depuis `pilotage-tuteur-v1\polices` : `DMSans-Variable.ttf` (240 164 o, SHA-256 `8CD08D97...1C0D`), `PlusJakartaSans-Variable.ttf` (176 288 o, `89B3FB38...8BC8`), `LICENSE-DMSans.txt`, `LICENSE-PlusJakartaSans.txt` (OFL 1.1). Retirés : `InstrumentSans-Variable.ttf`, `BricolageGrotesque-Variable.ttf` et leurs licences (`git rm`). Familles du pubspec : `UthmanTahaNaskh`, `NotoSansArabic`, `PlusJakartaSans`, `DMSans`, `Phosphor`, `PhosphorFill` (4 de texte + 2 d'icônes).
- Axes **relus sur les binaires** par un script Dart de lecture `fvar`/`GSUB`/`cmap` (scratchpad), puis figés par test (`LecteurPolice`) : DM Sans `opsz` 9 / **9** / 40, `wght` 100 / 400 / 1000, 9 instances, **pas de `tnum` ni `pnum`** ; Plus Jakarta Sans `wght` 200 / 400 / 800, 7 instances, `tnum` présent. Accents français, « », ’ et U+00A0 couverts par les deux ; U+202F (espace fine insécable) absent des deux. Commentaires du pubspec réécrits en conséquence.

### 2.2 Typographie (`app_typography.dart`)
- `AppFontFamily.titre = 'DMSans'`, `corps = 'PlusJakartaSans'`, nouvelle liste `texte` (4 familles). `AppFontAxis` : `opszTitreMin/Max` 9/40, `wghtTitreMin/Max` 100/1000, `wghtCorpsMin/Max` 200/800.
- `headline*` et `title*` en DM Sans via `_titre()`, qui pose **`wght` ET `opsz` = taille bornée 9..40** ; `body*`, `label*` en Jakarta (`wght` seul). Graisses : `headline*` **700** (titres de page, manifeste §3.3), `title*` 600, corps 400, `labelLarge` 600, `label*` 500. Tailles et interlignes inchangés (tous en px entiers, testé). Échelle enfant alignée (headlineSmall et titleLarge en DM Sans).
- `display*` = **Jakarta tabulaire 36/44, 700** (interprétation, voir §6.1).
- `AppTypography.chiffre({taille = 32, poids = w600, interligne})` : Jakarta, `tnum`, interligne par défaut taille + 8 px. `AppTypography.tabulaire(style)` bascule désormais un style DM Sans sur Jakarta (taille, interligne, graisse, couleur conservées) : `SectionHeader` (compteur en `titleMedium`) garde ainsi des chiffres alignés.
- Widgets partagés : `PinPad` (touches) et `AvatarTile` (initiales) passent de `headlineMedium` détourné à `chiffre`.
- Galerie : aucun `fontFamily` ; quinze rôles affichés avec famille et graisse ; spécimens DM Sans, Jakarta, chiffres, arabe par repli.

### 2.3 Palette (`app_palette.dart`, décisions §3.1)
- Clair : `inkStrong #110E20` (et `onBackground` des surfaces neutres canvas, raised, sunken, overlay, washFamily, pour que le texte par défaut du thème suive), `inkFaint #6A687E`, `inkAccent #6538E4`, `washWarning #FEF5E4` (encre `#755200` gardée), `inkAlert #C21D3D`.
- Sombre ardoise : canvas `#1A1A25`, raised `#22222E`, overlay `#2B2B39`, sunken `#262534` (et washFamily), borderHairline `#32323F`, inkMuted `#AEB1CE`, inkFaint `#9194B0`, surfacePrimary `#BA98FB` / `#25113F`, inkAlert `#F4777D`.
- Ajouts : `surfaceMiseEnAvant` (`#F7F5FE` / `#2B2B39`), `surfaceActionDouce` (clair `#DCCAFD` + `#110E20` ; sombre = `surfacePrimary`), `pointsStatut` (`AppPointsStatut` de 4 `AppIndicatorColor`, type qui ne sait peindre qu'un disque `pastille(cerclage:)` ou un thème d'icône, jamais un texte).
- Points : clair succès `#199C55`, attention `#B38000`, alerte `#E0375A`, neutre `#8685A5` ; sombre `#70EE9C`, `#FFB703`, `#F9505E`, `#7F7D9E` (écart au manifeste, §6.2).
- `surfaceQuran` inchangée (testé). `contourCarte`, `borderResting`, `borderStrong`, `washAccent`, `washSuccess`, `washAlert` inchangés.
- `app_theme.dart` : boutons et champs au rayon `AppRadius.sm` (12), cartes à `md` (16) ; `FilledButton` sur `surfaceActionDouce`.
- `ActionPrincipale` : `principale` sur `surfaceActionDouce`, rayon `sm` ; options **opt-in** `fleche` (icône `AppIcons.flecheAction`, Phosphor arrow-right `0xe06c`, miroitée en RTL, décorative) et `pilule` (rayon `full`, réservé au CTA d'admission, décisions §3.2).

### 2.4 Thème appliqué (`preferences_locales.dart`, `app.dart`)
- `RewayahApp` lit `modeThemeProvider` (tiré de `preferencesLocalesProvider.theme`) ; `themeMode` du constructeur devient `ThemeMode?`, ne force que s'il est fourni (Playground, tests). Avant : préférence écrite par Réglages, lue nulle part.
- Même préférence, deux entrées : `theme(valeur)` (page Apparence, Système / Clair / Sombre) et `basculerClairSombre(affichee)` (bascule d'en-tête, passe au thème opposé à celui affiché) ; `PreferenceTheme.luminosite(systeme)` donne le thème affiché que la bascule reflète.
- Persistance : un stockage clé-valeur non sensible existe (`PreferenceLocale`, table Drift de `app_database.dart`, « ouvert à tout agent ») : `StockagePreferencesDrift` l'utilise, clé `apparence.theme`. **Web : mémoire seulement** (`StockagePreferencesMemoire`), car `AppDatabase()` appelle `driftDatabase(name:)` sans `web:` et drift_flutter 0.3.1 lève `ArgumentError` dès la construction dans un navigateur (`drift_flutter-0.3.1/lib/src/web.dart:11-14`). `persistanceApparenceProvider`, monté par `RewayahApp` seulement : lecture au lancement sans écraser un choix fait entre-temps, écriture à chaque changement, panne du stockage sans effet (préférence en mémoire).
- Icônes pour la future bascule : `AppIcons.themeClair` (sun `0xe472`), `themeSombre` (moon `0xe330`). Points de code relevés dans `phosphor_flutter` 2.1.0 (cache pub), dont les deux TTF embarqués sont des copies à l'octet près (SHA-256 identiques vérifiés).

### 2.5 Vérificateur (`tool/verifier_jetons.dart`)
- `police-hors-typographie` : aucun `fontFamily:` hors `app_typography.dart` et `app_icons.dart` (`fontFamilyFallback:` non visé).
- `famillesAutorisees` (6 noms) : `famille-non-autorisee` sur tout `fontFamily: '...'` littéral, sur les constantes `static const String` des deux fichiers de police et sur chaque `- family:` du `pubspec.yaml` ; `famille-absente` si une famille autorisée n'est pas déclarée.
- `vocabulaire-perime` : `InstrumentSans`, `BricolageGrotesque` ajoutés ; messages de remplacement pointés vers DMSans / PlusJakartaSans.

## 3. Commandes lancées et résultats exacts (toutes sous `flutter-verrou.ps1`, sauf scripts de scratchpad)

| # | Commande | Résultat | Statut |
|---|---|---|---|
| 1 | `dart lire_ttf.dart` (scratchpad, hors verrou, script léger) sur les 4 TTF | axes et fonctions ci-dessus | mesuré |
| 2 | `dart analyze --fatal-infos lib/core/theme lib/core/widgets/pin_pad.dart lib/core/widgets/avatar_tile.dart lib/features/_dev/galerie test/theme` | `No issues found!`, 128 s | PASS |
| 3 | `flutter test test/theme/typographie_test.dart test/theme/rendu_polices_test.dart -r expanded` | `+23: All tests passed!`, 97 s (pub get implicite, `pubspec.lock` inchangé) | PASS |
| 4 | `dart run tool/verifier_jetons.dart && flutter test test/widgets --reporter compact` | `Jetons verifies : 344 fichiers, aucune violation.` puis `+79: All tests passed!`, 216 s | PASS |
| 5 | `dart contrastes.dart` (scratchpad) | toutes les encres >= 4,5 sur 5 surfaces dans les 2 thèmes ; points clairs proposés 1,51 à 2,10 min | mesuré |
| 6 | `dart analyze --fatal-infos lib/core/theme lib/core/icons lib/core/widgets/action_principale.dart lib/features/_dev/galerie test/theme test/widgets/composants_test.dart && flutter test test/theme test/widgets/composants_test.dart` | `No issues found!` puis `+84: All tests passed!`, 185 s | PASS |
| 7 | `dart run tool/verifier_jetons.dart && flutter test test/features/accueil_famille_test.dart test/features/accueil_eleve_test.dart test/features/compte_test.dart test/features/eleve_connexion_test.dart test/features/appareils_test.dart test/features/connexion_test.dart test/accessibilite` | 344 fichiers, aucune violation ; `+124: All tests passed!`, 130 s | PASS (non-régression partielle) |
| 8 | `dart analyze --fatal-infos lib/app.dart lib/core/preferences lib/core/icons test/theme/theme_applique_test.dart && flutter test test/theme/theme_applique_test.dart test/features/compte_test.dart` | `No issues found!` ; `+15: All tests passed!`, 121 s | PASS |
| 9 | `dart run tool/verifier_jetons.dart` avec fichier piège temporaire `lib/piege_police_tmp.dart` | code 1, **5 violations attendues** (vocabulaire-perime, 2 police-hors-typographie, 2 famille-non-autorisee), ligne `fontFamilyFallback` ignorée ; piège supprimé | PASS (règle prouvée) |
| 10 | `dart run tool/verifier_jetons.dart && dart analyze --fatal-infos tool/verifier_jetons.dart` | 344 fichiers, aucune violation ; `No issues found!` | PASS |
| 11 | `flutter test test/theme test/widgets --reporter compact` (état `c163127`) | `+129: All tests passed!`, 189 s | PASS |
| 12 | capture `planche_0b_test.dart` (1re passe) | `+12: All tests passed!`, 44 s, 11 PNG | PASS |
| 13 | `dart analyze --fatal-infos lib/core/widgets/avatar_tile.dart lib/core/widgets/pin_pad.dart test/widgets/chiffre_texte_agrandi_test.dart && flutter test test/widgets test/features/eleve_connexion_test.dart test/features/accueil_famille_test.dart test/accessibilite` | `No issues found!` ; `+156: All tests passed!`, 194 s | PASS |
| 14 | capture (2e passe, planche 08 ajoutée) | `+13: All tests passed!`, 42 s, 12 PNG ; `test/_capture_tmp` supprimé (`TMP_SUPPRIME=True`) | PASS |
| 15 | `dart run tool/verifier_jetons.dart` (état final) | `Jetons verifies : 344 fichiers, aucune violation.` | PASS |

Base de comparaison : `test/theme` comptait 9 tests (C02) ; `test/widgets` 79 au départ. État final mesuré : `test/theme` + `test/widgets` = 129 (avant le 5e commit), puis `test/widgets` +2 tests au 5e commit (inclus dans le 156 du #13). `test/theme` n'a pas été relancé après `1d411b7` (commit sans effet sur ces tests : `avatar_tile`, `pin_pad`).

**Non exécuté** : `dart analyze --fatal-infos` sur tout le dépôt et suite complète `flutter test` (réservés au coordinateur, ~9 et ~25 min) ; `dart run slang` / `build_runner` (aucune modification i18n ni source générée) ; `flutter build web` ; captures d'écrans réels (seulement des planches) ; comparaison aux maquettes.

## 4. Contrastes mesurés (formule WCAG, figés par `test/theme/support/contraste.dart`)

Matrice appliquée aux deux thèmes : 17 paires fond/texte >= 4,5 ; 7 encres (strong, muted, faint, accent, alert, success, warning) sur 5 surfaces (canvas, raised, sunken, overlay, miseEnAvant) >= 4,5 ; encre de rôle sur fond doux du rôle >= 4,5 ; `borderStrong` et `surfacePrimary` sur les 5 surfaces >= 3 ; chaque point sur raised, canvas, miseEnAvant, sunken (+ son wash) >= 3.

Valeurs limites : clair `inkFaint` 4,65 sur sunken (3,55 avant), `inkFaint` 4,99 sur miseEnAvant, `borderStrong` 3,55 sur sunken, `surfacePrimary` 4,15 sur sunken, `surfaceActionDouce` 12,56 ; points clairs min 3,06 (succès sur sunken), 3,02 (attention sur sunken), 3,68 (alerte sur washAlert), 3,07 (neutre sur sunken). Sombre `inkFaint` 4,69 sur overlay/miseEnAvant, `inkAlert` 5,05 sur washAlert, `borderStrong` 4,22 sur overlay, point neutre 3,54 sur miseEnAvant, alerte 4,11 sur washAlert.

## 5. Preuve visuelle (captures)

Méthode C11 §5 (polices de `FontManifest.json` chargées par `FontLoader`, garde-fou de largeur, `RepaintBoundary` enfant direct du défilement pour capturer la planche entière, PNG dans `runAsync`), test source hors dépôt : `D:\RA _APP\pilotage-tuteur-v1\04_phase0\captures_0b\planche_0b_test.dart`, copié dans `D:\RA_TUTEUR\integration\test\_capture_tmp\` le temps de l'exécution puis supprimé (jamais dans le checkout C0). Sonde : `DMSans=48,2 px`, `Jakarta=45,8 px`, police inconnue `200 px`.

Fichiers (`04_phase0\captures_0b\`) : `01_titres_{clair,sombre}_390@2.png`, `02_corps_chiffres_{clair,sombre}_390@2.png`, `03_surfaces_{clair,sombre}_390@2.png`, `04_encres_points_cta_{clair,sombre}_390@2.png`, `05_titres_texte200_clair_390@2.png`, `06_corps_texte200_sombre_390@2.png`, `07_specimen_zoom_clair_390@4.png`, `08_avatar_pave_texte200_clair_390@2.png`.

Ouverts et relus (Read) : 07, 01 clair, 02 clair, 04 clair et sombre, 03 sombre, 05, 06, 08. Constat :
- Deux familles distinctes réellement rendues (07) : DM Sans 700 à opsz 36 (dessin géométrique serré, « G » à éperon, « Q » à queue traversante) contre Jakarta 400 (plus large, « Q » à queue longue) ; aucune boîte vide.
- Accents, « », ’, œ, Ç, Â, É corrects dans les 15 rôles, clair et sombre ; pas de contact visible entre lignes sur les titres 36/44 multilignes.
- Chiffres tabulaires : `11:11` et `00:00` alignés en colonnes (02) ; PIN et initiales en Jakarta ; arabe rendu par repli NotoSansArabic sur la même ligne.
- CTA : lavande doux + encre noire + flèche en clair, lavande plein + encre sombre en sombre ; pilule ; champ au rayon 12, invite lisible.
- **Défaut trouvé puis corrigé** : à 200 %, `AvatarTile` coupait « MA » en « M » et les chiffres du `PinPad` débordaient sur l'anneau (06, 1re passe). Après `1d411b7`, « MA », « YN » et 0-9 tiennent dans leur disque (08) ; test de non-régression ajouté.
- Limite observée (non corrigée, règle d'écran) : à 200 % sur 390 px, `headlineLarge` (72 px effectifs) coupe un mot long au milieu (« commenc/e », 05). Le manifeste prévoit déjà `headlineSmall` pour le titre de page mobile.

Statut : « UI réalisée » et « testée en simulation » sur planches ; **pas** « vérifiée réellement » (aucun écran réel, aucune comparaison aux maquettes, aucun navigateur).

## 6. Écarts, interprétations, points ouverts

### 6.1 Interprétations prises (réversibles)
1. **`display*` en Jakarta tabulaire, pas en DM Sans.** Dans `lib/`, `display*` ne porte que des valeurs fortes : compte à rebours (`accueil_eleve_page.dart:337`), `StatTile`, monogramme (`vignette_ressource.dart:89`), mot-marque (`marque_page.dart:28`). DM Sans n'ayant pas de `tnum`, les passer en DM Sans ferait sauter le compte à rebours. Un titre de 36 px prend `headlineLarge` (DM Sans). Conséquence : le mot-marque « Rewayah » de `MarquePage` est en Jakarta 700 ; s'il doit être en DM Sans, le propriétaire du shell (0c) le passe en `headlineLarge`.
2. `title*` en DM Sans comme l'imposent les décisions §3.4, y compris là où `titleMedium`/`titleSmall` servent de libellé de ligne (liste §6.3).
3. `inkStrong #110E20` appliqué aussi à l'`onBackground` des surfaces neutres (sinon le texte par défaut du thème restait en `#211E28`). `surfaceInverse`, `ombre`, `contourCarte` gardent `#211E28`.
4. `ActionPrincipale.fleche` et `pilule` sont opt-in : aucun écran existant ne change de forme ; seul le fond du niveau `principale` change pour tous les rôles (P9).

### 6.2 Écart au manifeste
- Points de statut clairs : les propositions `#1FC46A`, `#FFB703`, `#A5A4BC` mesuraient 1,98, 1,51 et 2,10:1 au pire ; les décisions §3.1 exigent 3:1 par test. Assombris à teinte égale (HSL, pas de 0,5 %) jusqu'à 3:1 : `#199C55`, `#B38000`, `#8685A5`. `#E0375A` et les 4 points sombres passent tels que proposés. **[DIRECTEUR / COORD : valider la teinte ambre `#B38000`]**.

### 6.3 Demandes aux lots (usages équivalents à corriger, fichiers hors 0b)
| Fichier:ligne | Usage | Correction demandée | Propriétaire |
|---|---|---|---|
| `lib/features/appareils/appairage_page.dart:208` | code d'appairage en `headlineMedium` (désormais DM Sans, sans `tnum`) | `AppTypography.chiffre()` (ou `tabulaire(textes.headlineMedium)`) | lot D |
| `lib/features/eleve_connexion/eleve_connexion_page.dart:316` | champ du code élève en `headlineMedium` | idem | lot D |
| `lib/core/widgets/schedule_option.dart:75` | heures en `titleLarge` (DM Sans, chiffres proportionnels) | `AppTypography.tabulaire(titleLarge)` ou `chiffre(taille: 22)` | COORD (composant partagé) / lot C catalogue |
| `lib/core/widgets/setting_row.dart:73`, `choice_card_group.dart:233`, `child_card.dart:202`, `data_collection.dart:420`, `timeline_row.dart:57`, `schedule_option.dart:71`, `signal_row.dart:76` | `titleMedium`/`titleSmall` employés comme libellé de ligne ou de carte, désormais en DM Sans | garder si c'est un titre de bloc ; sinon `labelLarge`/`bodyLarge` (Jakarta) | COORD, à trancher écran par écran |
| `lib/core/widgets/marque_page.dart:28` | mot-marque en `displaySmall` (Jakarta 700) | `headlineLarge` si DM Sans voulu | 0c (shell) |
| `lib/core/widgets/app_bottom_sheet.dart:100-102` | voile `surfaceInverse` clair en sombre (C02 défaut 1), inchangé | voile `palette.voile` | COORD (composant partagé) |
| `lib/CLAUDE.md:58-59` | piège « Bricolage sort à wght 800 » périmé | « DM Sans sort en opsz 9 si l'axe n'est pas posé ; DM Sans n'a pas de chiffres tabulaires : chiffres en `AppTypography.chiffre` » | COORD (doc) |
| `lib/CLAUDE.md:45-46` | « `inkFaint` interdit sur `surfaceSunken` (4,48) » périmé | `inkFaint` clair mesure désormais 4,65 sur `surfaceSunken` (testé) | COORD (doc) |

Sans objet : `connexion_page.dart:264,438` (`headlineMedium` en vrai titre), compte à rebours `accueil_eleve_page.dart:337` (reste Jakarta tabulaire), `section_header.dart:60` (`tabulaire(titleMedium)` bascule automatiquement sur Jakarta).

### 6.4 Points ouverts
1. **Persistance du thème sur le web** (cible de production) : mémoire seulement tant que `AppDatabase` (`lib/core/cache/db/app_database.dart:165`, hors périmètre 0b) ne passe pas `web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js'))` (fichiers présents dans le bundle web selon C11 §6). À décider par le propriétaire du cache ; aucune autre voie clé-valeur non sensible dans le dépôt (le coffre sécurisé ne doit pas servir à cela).
2. Sur natif, la préférence est lue de façon asynchrone après le premier rendu : un éclair du thème système est possible au lancement. Parade si voulue : lecture avant `runApp` dans `lib/main.dart` (COORD).
3. Le widget de bascule d'en-tête (`bascule_theme.dart`, composant partagé à créer) reste à écrire : l'état est prêt (`basculerClairSombre(pref.luminosite(MediaQuery.platformBrightnessOf(context)))`, icônes `themeClair`/`themeSombre`).
4. `animationsReduites`, `effetsReduits`, `lectureGrande`, `economieDonnees` : toujours sans consommateur hors Réglages (C02 défaut 2, hors mandat 0b).
5. `borderStrong`/`borderResting` sombres (`#95899F`, gris chaud) non ajustés par les décisions ; ils passent 3:1 mais tranchent sur l'ardoise froide. Proposition à valider sur capture d'écran réel.
6. Rendu : un `ActionPrincipale` inerte (fond raised, filet 3) ressemble beaucoup à un secondaire (fond raised, filet 2) sur les planches ; comportement antérieur, à revoir par le propriétaire du composant si gênant.
7. Autres rôles (élève, enseignant, admin) : palette sombre et CTA doux s'appliquent à eux (P9) ; non-régression mesurée par tests (124 + 156 tests verts), **pas** par captures de leurs écrans.
