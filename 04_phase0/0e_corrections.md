# 0e - Corrections des revues de phase 0 (jetons / a11y, routes / contrats)

Date : 24/09/2026, 14:30 à 17:30 (+03:00). Worktree `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, départ `125fe78`.
Statut global : **13 commits locaux, aucun push, aucune PR, aucun merge.** Frontière backend vide. Statut de preuve : « testé en simulation » (analyse, tests de widget, vrai routeur, vraies polices pour les mesures de rendu). Rien n'est « vérifié réellement » (aucun appareil, aucun navigateur, aucun Supabase).

Entrées lues : `BRIEF.md`, `03_DECISIONS_COORDINATEUR.md`, `CLAUDE.md` et `lib/CLAUDE.md` du worktree, `revue_jetons_a11y.md`, `revue_routes_contrats.md`, `0a_base.md`, `0b_jetons.md`, `0c2_coquille_routeur.md`, `02_code/00_OWNERSHIP.md` (§1, §3 C-obs, §4), `00_CONTRADICTIONS.md` (X40, X41, P2, P8), mandat (§8, §11, complément observation §2-§5). Chaque défaut a été vérifié dans le code avant d'être corrigé (fichier:ligne ci-dessous).

## 1. Commits (branche `ui/tuteur-v1`, locaux)

| # | Hash | Message | Défauts |
|---|---|---|---|
| 1 | `b6df316` | feat(tuteur): reprise front de 33503fe, vraies classes et horloge serveur (sans migration) | routes D1 (1/2) |
| 2 | `0401086` | feat(observation): reprise front de observation/lot-2026-09-21 (sans migration) | routes D1 (2/2) |
| 3 | `db52be5` | fix(observation): OBSERVATION_TUTEUR_REELLE en liste d'autorisation et branche sur le tuteur | routes D2 |
| 4 | `66cbfe1` | fix(routeur): acces refuse reserve au tuteur, jamais repris apres connexion | routes D3 (accès refusé), D6 |
| 5 | `adf2b3c` | fix(compte): disque retour des preferences et Foyer rejoint par go | routes D4, D7 |
| 6 | `f075a7e` | fix(coquille): rail a libelles pour l'eleve et l'enseignant sur tablette | jetons D2, routes D3 (rail) |
| 7 | `436c290` | fix(theme): la graisse passe par l'axe wght, regle graisse-hors-typographie | jetons D1 |
| 8 | `f3348de` | fix(widgets): en Interface guidee, le CTA garde l'aplat surfacePrimary | jetons D3 |
| 9 | `9116bc6` | fix(typo): heures et comptes a rebours en chiffres tabulaires | jetons D4 |
| 10 | `0d1030a` | fix(classe-tuteur): pas de Rejoindre pour le tuteur, alias observer marque STUB | routes D8 |
| 11 | `49c796c` | fix(theme): onglets en Jakarta, mot-marque en DM Sans, points de statut des pastilles | jetons D5, D6, D8 |
| 12 | `df769c9` | test(theme): encres sur fonds doux, paires sous le seuil nommees et interdites | jetons D7 |
| 13 | `cefab7f` | test(fixtures): K7 releve aussi les doubles *Local, dette de la Bibliotheque nommee | routes D9 |

Non commités, volontairement : `windows/flutter/generated_plugin_registrant.{cc,h}`, `generated_plugins.cmake` (fins de ligne seulement, effet de `flutter pub get` relevé par 0a).

## 2. Revue routes / contrats : sort de chaque défaut

| ID | Vérification dans le code | Sort |
|---|---|---|
| **D1 bloquant** | Confirmé : `git show 125fe78:lib/core/tc_groupe/port_groupes.dart` l. 38 `GroupesDemonstrationLocale()` sans condition, idem `HorlogeSeanceDemonstration()` ; K7 ne passait que par `_detteConnue`. | **Corrigé** (`b6df316`, `0401086`). Étape 2 de 0a commitée : `GroupesSupabase` / `HorlogeSeanceSupabase` en production, doubles sous `PLAYGROUND` seulement ; les listes `_jours` / `_mois` en dur et sans accents (0a §2.4) remplacées par `commun.dates.{jours,mois,jourDate}` (espace COORD) + test « Samedi 6 février », « août », « décembre ». K7 : `_detteConnue` vidée. Étape 3 : patch `git diff main...observation/lot-2026-09-21 -- lib test assets ":(exclude)lib/core/i18n/*.g.dart"` appliqué par `git apply --3way` (18 fichiers, hunks K4 déjà présents fusionnés sans conflit), slang régénéré. Libellés signés (`salle.bandeauPermanent`, `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse`) : `git diff 3cf3544 HEAD -- assets/i18n/fr.i18n.json` n'en montre aucun. |
| **D2 majeur** | Confirmé : `Env.observationTuteurReelleActive` sans consommateur ; `observationTuteurReelleSelon` = `environnement != 'production'`. | **Corrigé** (`db52be5`). Liste d'autorisation : seul `developpement` ouvre (staging, `Production`, vide : fermés, testé). `observationTuteurReelleProvider` (`lib/core/tc_observation/activation_observation.dart`) est la seule entrée des écrans. Fermé : « Assister » n'est pas rendu sur l'Accueil famille, et `/tc/observation/:id` rend au tuteur `PageEtat(indisponible, dependance: DB-OBS-01)` **sans aucun appel serveur** (test : `rolesDemandes` vide) ; admin et contrôleur gardent leur porte (test). |
| **D3 majeur** (3 volets) | Confirmés dans le code. | (a) Clés i18n « Cours en cours » d'élève et d'enseignant : **réfuté en partie, reporté au directeur**. La revue les dit « hors espaces COORD » : `00_OWNERSHIP.md` §4 (l. 140) les attribue explicitement à COORD ; le mandat (complément §2, l. 356) interdit le libellé sans borne de rôle, et X41 proposait ce changement par COORD. Non rétablies ; `journee_test` et `classe_live_page_test` verts. Décision de portée à confirmer. (b) Accès refusé pour tous les rôles : **corrigé** (`66cbfe1`), les autres rôles retrouvent le renvoi à leur racine de `3cf3544` ; le tuteur garde `/acces-refuse`. Tests d'autres rôles rétablis à leurs attentes d'origine (`redirection_test`, `etats_transverses_test`, `acces_agent_test`). (c) Rail replié sans libellés : **corrigé** (`f075a7e`, voir jetons D2). |
| **D4 majeur** | Confirmé : `preferences_page.dart` rendait `ReglagesComptePage` sans `onRetour`, route en tâche focalisée (`routes.dart:273`). | **Corrigé** (`adf2b3c`) : `ReglagesComptePage.onRetour` (nul pour les autres rôles), la délégation tuteur pointe vers `/tuteur/compte`. Test sur le vrai routeur à 390x844 : pas de barre basse, un `DisqueRetour`, retour au Compte et barre revenue. |
| D5 mineur | Confirmé par lecture : `Uri.decodeComponent` de `go_router-18.0.1/lib/src/match.dart:207` hors de tout `try`, et le parseur ne rattrape que les erreurs d'`onEnter`. Non rejoué par moi. | **Reporté** : pas simple. Correction proposée : envelopper `GoRouteInformationParser` (dans `lib/app.dart`, `MaterialApp.router(routeInformationParser: AnalyseurSain(routeur.routeInformationParser), routerDelegate: …, routeInformationProvider: …)`) pour réécrire une adresse dont le décodage lève `FormatException` vers un chemin inconnu (donc `PageIntrouvable`), en gardant `state` ; le harnais `support_routeur.dart` doit monter le même enveloppement pour que le test le prouve. |
| D6 mineur | Confirmé : `_reprise` (`redirection.dart:195-216`) n'excluait pas `/acces-refuse`. | **Corrigé** (`66cbfe1`) : `/acces-refuse` et `/hors-ligne` exclus ; test pour tuteur, enseignant, élève. |
| D7 mineur | Confirmé : `compte_page.dart:72` `push(Routes.compteProfils)`. | **Corrigé** (`adf2b3c`) : `go(Routes.tuteurFoyer)` (ligne réservée au tuteur), idem dans le profil personnel ; test : Foyer affiché, `indexActif == 1`. |
| D8 mineur | Confirmé : `carte_session.dart:59-64` rendait `ActionPrincipale(Rejoindre)` pour tout rôle ; aucune occurrence « observ » dans `tc_espace_groupe`. | **Corrigé** (`0d1030a`) : pas de « Rejoindre » pour `RoleEspaceGroupe.tuteur` (test T-20) ; alias `/tuteur/classes/:id/observer` marqué `STUB PHASE 0 : propriété du lot C-obs`. |
| D9 mineur | Confirmé : `donnees_catalogue.dart:33,38` sert `CatalogueLocal()` et `VersionsLocales()`. | **Détecteur corrigé** (`cefab7f`) : K7 relève `*Local(e)(s)` (piège ajouté) ; les deux doubles sont inscrits en dette connue nominative. **La dette elle-même est reportée au lot C** (implémentation `Indisponible` ou adaptateur réel de la Bibliothèque). |
| D10 mineur | Confirmé : `BornesAge.clientActuelle = BornesAge(min: 3, max: 18)` (`profil_eleve_brouillon.dart:59`). | **Reporté (décision)** : constante conforme au texte de K3, contraire au principe « aucune constante métier » ; à trancher par le directeur (P7, `regles_academie`). Non modifiée. |

## 3. Revue jetons / accessibilité : sort de chaque défaut

| ID | Vérification | Sort |
|---|---|---|
| **D1 majeur** | Confirmé : 3 `copyWith(fontWeight:)` sans axe dans `nav_shell.dart` (onglet actif, mot-symbole, libellé de colonne), seuls `fontWeight:` de `lib/` hors typographie. | **Corrigé** (`436c290`) : `AppTypography.graisse(style, poids)` pose `fontWeight` et `wght` (bornée à l'axe de la famille, `opsz` gardé), employée aux 3 endroits ; règle `graisse-hors-typographie` dans `verifier_jetons.dart`, **prouvée sur un fichier piège** (1 violation, code 1, piège supprimé) ; tests de style et **de rendu avec les vraies polices** (la largeur augmente réellement pour `labelMedium` 600, `bodyLarge` 600, `titleLarge` 700). |
| **D2 majeur** (arbitrage) | Confirmé : `nav_shell.dart:522-523` repliait le rail pour tous les rôles sur tablette. | **Corrigé en repli conservateur** (`f075a7e`) : `NavShell.libellesDansLeRail`, posé par le routeur pour tout rôle autre que le tuteur : nom visible sous l'icône (borné à 150 %, lu en entier, pastille active). Le tuteur garde le rail à icônes et infobulles de sa maquette. `parcours_enseignant_test` rétabli sur les libellés visibles (dans le rail) ; test du rail à 100 % et 200 %. Capture enseignant non refaite (voir §6). |
| **D3 majeur** (arbitrage) | Confirmé : `action_principale.dart:228-230` peignait `surfaceActionDouce` en Interface guidée. | **Corrigé en repli** (`f3348de`) : en Interface guidée, le niveau principal reprend `surfacePrimary` (≥ 3:1 contre chaque surface, déjà testé par la matrice) ; mode standard inchangé ; sombre identique. **Décision du directeur sur capture toujours demandée.** |
| D4 mineur | Confirmé pour 3 des 5 endroits. | **Corrigé** (`9116bc6`) : compte à rebours / heure de la Journée enseignant (`journee_page.dart:453-460`), heure (`carte_session.dart`, `_LigneValeur`) et état du temps « Dans 12 min » de la Session Card en `AppTypography.tabulaire` ; test (Journée : `tnum` + Jakarta). **Réfuté** pour `carte_session.dart:128` (date « Lundi 28 septembre », un titre) et `cahier_page.dart:325` (durée statique « 45 min ») : ni horaire ni chronomètre au sens des décisions §3.4. La liste 0b §6.3 est à compléter par COORD avec ces trois lignes (je n'ai pas réécrit le rapport de 0b). |
| D5 mineur | Confirmé : aucun `tabBarTheme`. | **Corrigé** (`49c796c`) : `TabBarThemeData(labelStyle/unselectedLabelStyle: labelLarge)` ; test sur les 4 thèmes (modes x luminosités). |
| D6 mineur | Confirmé : `marque_page.dart:28` en `displaySmall`. | **Corrigé** (`49c796c`) : `headlineLarge` (DM Sans, même 36/44/700) ; test. |
| D7 mineur | Confirmé et mesuré par test : clair `inkFaint/washAccent` ; sombre `inkFaint/washSuccess`, `inkFaint/washWarning`, `inkAlert/washWarning`. | **Corrigé côté garde-fou** (`df769c9`) : la matrice mesure toute encre sur tout fond doux et exige la liste exacte des paires sous 4,5:1, déclarées interdites. **Teinte non modifiée** (décision de palette §3.1). Aucun usage trouvé (recherche non exhaustive de la revue). |
| D8 mineur | Confirmé : `status_pill.dart:123-129` n'employait pas `pointsStatut`. | **Corrigé** (`49c796c`) : succès, attention, alerte, neutre posent `palette.pointsStatut.*.pastille()` ; test : couleur du point et ≥ 3:1 sur le fond doux de la pilule. Accent inchangé (`surfacePrimary`). |
| D9 mineur | Non remesuré (mesure de la revue). | **Reporté** : arbitrage du directeur sur capture (apostrophe de Plus Jakarta Sans plus large qu'une espace). |
| D10 mineur | Confirmé : `preferences_locales.dart:239-244`, mémoire seule sur le web. | **Reporté** : options web de Drift dans `AppDatabase` (propriétaire du cache) et présence de `sqlite3.wasm` / `drift_worker.js` dans le bundle à vérifier sur build web ; hors correction simple. |
| D11 mineur (doc) | Confirmé : `lib/CLAUDE.md:45-46`, `:58-59` périmés. | **Reporté** : `00_OWNERSHIP.md` §1 (l. 42) réserve `lib/CLAUDE.md` au chantier C0, mise à jour « hors branche UI ». Formulation proposée (0b §6.3) : « `inkFaint` clair mesure 4,65 sur `surfaceSunken` (testé) » ; « DM Sans sort en `opsz` 9 si l'axe n'est pas posé ; DM Sans n'a pas de chiffres tabulaires : chiffres en `AppTypography.chiffre` ; une graisse passe par `AppTypography.graisse` ». |

## 4. Commandes lancées et résultats exacts (toutes sous `flutter-verrou.ps1`, dossier `D:\RA_TUTEUR\integration`)

| # | Commande | Résultat exact | Statut |
|---|---|---|---|
| 1 | `dart run slang && dart analyze --fatal-infos lib/core/tc_groupe lib/core/tc_horloge test/teaching_core/a test/config && flutter test --no-pub test/teaching_core/a test/config/fixtures_isolees_test.dart` | `Translations generated successfully.` ; `No issues found!` ; `+123: All tests passed!` (551 s) | PASS |
| 2 | `dart run slang && dart analyze --fatal-infos` (icons, tc_observation, accueil_famille, salle, tc_classe_live, tc_observation_ui + tests) `&& flutter test --no-pub -r failures-only test/teaching_core/g test/teaching_core/e test/teaching_core/q/q03_quota_observation_tuteur_test.dart test/features/accueil_famille_test.dart test/features/salle_test.dart test/tc_observation` | `No issues found!` ; `+274: All tests passed!` (267 s) | PASS |
| 3 | `dart format` (8 fichiers) `&& dart analyze --fatal-infos` (config, tc_observation, tc_observation_ui, accueil_famille + tests) `&& flutter test … test/teaching_core/g test/features/accueil_famille_test.dart test/tc_observation` | `No issues found!` ; `+132: All tests passed!` (132 s) | PASS |
| 4 | `dart format` `&& dart analyze --fatal-infos lib/core/router lib/core/widgets/nav_shell.dart lib/core/theme lib/features/compte tool test/router test/agent/acces_agent_test.dart test/widgets/nav_shell_adaptatif_test.dart test/theme && dart run tool/verifier_jetons.dart && flutter test … test/router test/agent/acces_agent_test.dart test/widgets/nav_shell_adaptatif_test.dart test/theme/typographie_test.dart test/theme/rendu_polices_test.dart test/features/compte_test.dart` | `No issues found!` ; `Jetons verifies : 418 fichiers, aucune violation.` ; `+333: All tests passed!` (542 s) | PASS |
| 5 | `dart run tool/verifier_jetons.dart` avec piège `lib/piege_graisse_tmp.dart` | `1 violation(s) : lib/piege_graisse_tmp.dart:4 [graisse-hors-typographie]`, code 1 ; piège supprimé (`PIEGE_SUPPRIME=True`) | PASS (règle prouvée) |
| 6 | `flutter test … test/theme/contraste_test.dart test/theme/contraste_sombre_test.dart` (liste d'exemptions vide, pour mesurer) | `-2` attendus : clair `{inkFaint / washAccent}`, sombre `{inkFaint / washSuccess, inkFaint / washWarning, inkAlert / washWarning}` | mesure, puis listes déclarées |
| 7 | `dart format` + `dart analyze --fatal-infos` (widgets, theme, app_router, journee, tc_espace_groupe + tests) | `1 issue found` (`directives_ordering`, `composants_test.dart:20`) | FAIL puis corrigé |
| 8 | `dart analyze --fatal-infos test/widgets/composants_test.dart && dart run tool/verifier_jetons.dart && flutter test … test/widgets/composants_test.dart test/theme test/features/journee_test.dart test/teaching_core/a/espace_groupe_page_test.dart test/config/fixtures_isolees_test.dart test/features/accueil_eleve_test.dart test/features/creneaux_test.dart test/accessibilite` | `No issues found!` ; `418 fichiers, aucune violation.` ; `+255: All tests passed!` (317 s) | PASS |
| 9 | `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc dart_define.example.json` | vide | PASS |
| 10 | Final sur HEAD `cefab7f` : `dart analyze --fatal-infos` (dépôt entier), `dart run tool/verifier_jetons.dart`, `flutter test --no-pub -r expanded` (suite complète) | voir §5 | voir §5 |

Réserves de méthode : après les n° 4 et 8, deux fichiers ont été ramenés à leur version commitée puis ré-édités à la main pour retirer le bruit de `dart format` (`test/agent/acces_agent_test.dart`, `lib/features/journee/journee_page.dart` + `test/features/journee_test.dart`, même logique, helper `_heureTabulaire`) : ils ne sont couverts que par le n° 10. `dart format` a par ailleurs reformaté quelques fichiers touchés au-delà de mes lignes (`entree_observation_page.dart`, `ecrans_observation_test.dart`, `hote_tc_g.dart`, `parcours_enseignant_test.dart`, `navigation_test.dart`, `redirection_test.dart`) ; `test/router/admin_domaine_test.dart`, reformaté sans raison, a été rétabli. `build_runner` non exécuté : aucune source d'un générateur `build_runner` modifiée (seul slang, régénéré et commité).

## 5. Vérification finale sur HEAD `cefab7f`

Un seul appel sous verrou, 16:49:54, durée 2 410 s, code 0. Arbre = HEAD `cefab7f` + les 3 fichiers `windows/flutter/*` (fins de ligne). Journaux copiés dans `04_phase0\` : `0e_analyse.log`, `0e_jetons.log`, `0e_tests_complets.log`.

| Commande | Résultat exact | Statut |
|---|---|---|
| `dart analyze --fatal-infos` (dépôt entier) | `Analyzing integration...` puis `No issues found!` | PASS |
| `dart run tool/verifier_jetons.dart` | `Jetons verifies : 418 fichiers, aucune violation.` | PASS |
| `flutter test --no-pub -r expanded` (suite complète) | `30:10 +2110 ~18: All tests passed!` ; 0 échec. Les 18 sautés sont les tests de capture sans `CAPTURE_DIR` (« CAPTURE_DIR absent : captures sautees ») ajoutés par 0c2 ; la base `3cf3544` comptait 1 762 tests, 0 sauté. | PASS |
| Frontière backend (n° 9) | vide | PASS |

**Non exécutés** : `dart run build_runner` (aucune source concernée) ; `flutter build web` ; captures comparatives élève, enseignant et tuteur après correction ; appareil réel, navigateur, Android, iOS ; aucune vérification contre Supabase (les adaptateurs réels repris ne sont testés que par leurs fonctions pures et le choix du port).

## 6. Écarts, demandes, points ouverts

1. **[DIRECTEUR]** Portée de « Cours en cours » (routes D3-a) : les trois clés élève / enseignant restent à « Séance en direct » / « Séance toujours en direct » ; les rétablir à `3cf3544` est un geste i18n d'une ligne chacune si le directeur borne la règle au tuteur.
2. **[DIRECTEUR]** CTA doux (jetons D3) et rail des autres rôles (jetons D2) : replis conservateurs appliqués (aplat en Interface guidée, rail à libellés hors tuteur) ; décision sur capture attendue. **Captures élève et enseignant non refaites** après ces corrections (seulement tests de widget).
3. **[DIRECTEUR / P3]** Conséquence de D2 : avec l'interrupteur fermé (production, aperçus), le tuteur n'a plus aucun « Assister » sur l'Accueil famille (avant la reprise d'observation, il passait par `assister_seance` vers `/salle`). C'est l'application de P3 ; à confirmer.
4. **Lot C** : dette K7 `CatalogueLocal` / `VersionsLocales` (routes D9) ; bloc d'observation de la classe pour l'alias `observer` (D8).
5. **COORD** : D5 (lien profond mal encodé) selon la proposition du §2 ; D10 web (Drift) ; D11 (`lib/CLAUDE.md`, sur la branche C0) ; compléter 0b §6.3 (jetons D4).
6. Clé morte après la reprise d'observation : `tuteur.accueil.assisterRefuse` (plus lue par `lib/`), suppression sur accord seulement.
7. Dossier vide `D:\RA_REVUE_TMP` laissé par la revue jetons : non touché.
