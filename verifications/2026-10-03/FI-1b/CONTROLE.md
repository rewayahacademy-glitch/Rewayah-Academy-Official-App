# FI-1b — Contrôle adverse

Contrôleur adverse pour l'orchestratrice 00166a22, 03/10/2026. Aucun code modifié. Mes relances ont tourné dans un worktree **détaché** créé pour l'occasion, `D:\RA_TUTEUR\finance-controle-fi1b` (HEAD `af9f408b`, aucune branche créée). Le worktree de l'auteur, `D:\RA_TUTEUR\finance`, n'a pas été touché. Toutes les commandes Flutter et Dart sont passées par `flutter-verrou.ps1`, sans `CAPTURE_DIR`.

## Verdict

**Confirmé**, avec les réserves ci-dessous. Chaque affirmation importante du rapport a été revérifiée et tient. Les critères de l'énoncé de l'orchestratrice sont remplis. Le seul critère non tenu vient du « Fait quand » de `02_DECOUPAGE.md` (compilation sans `ENVIRONNEMENT`), et l'auteur l'a déclaré lui-même (AD-R m13).

## Ce que j'ai revérifié

| Affirmation | Preuve du contrôle |
|---|---|
| `ui/finance-v1` poussée à `af9f408b` | `git ls-remote origin` : `af9f408bf31a4439dd0aaaf2bb04b700b6b7aa29 refs/heads/ui/finance-v1` ; `git status -b` dans `D:\RA_TUTEUR\finance` : `ui/finance-v1...origin/ui/finance-v1`, donc la branche amont est posée |
| La base est `7c612872`, pas `4a4fbe7` ; elle contient `4a4fbe7f` | `git rev-parse af9f408b^` = `7c612872…` = `origin/corrections/revue-directeur-2026-10` (ls-remote) ; `merge-base --is-ancestor 4a4fbe7 origin/ui/finance-v1` donne 0 ; `git log 4a4fbe7..7c612872` liste les commits GALERIE-BENTO-2 et BENTO-1b (8 commits au total, dont les 4 cités par l'auteur sur la première ligne parente) |
| Pas de fusion eleves-adultes | `17_finance/00_REPRISE.md:4` (décision de l'orchestrateur) : « Plus aucune fusion séparée admin + adultes » |
| Un seul commit, préfixé « FI-1b : », 14 fichiers, rien d'interdit | `git show --stat af9f408b` : ni `pubspec.yaml`, ni `supabase/`, ni `.github/`, ni `vercel.json`, ni thème ou couleur ; diff relu en entier |
| `AdminDomaine.finance` actif, `ongletsFinance()` | `lib/core/admin/admin_domaine.dart` (switch `chemin` : `finance => Routes.adminFinance` ; `ongletsFinance()`) ; `routes.dart` : `/admin/finance`, `/admin/finance/politiques`, `/demo/finance` |
| Libellés et routes tirés des sources | Guide `17_finance/V/REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md:301-302` (« Finance - Vue globale », « Admin - Politiques commerciales »), `:555-559` (`/admin/finance`, `/admin/parametres/politiques-commerciales`, « conserver l'existant et mapper ») ; `UX_REVIEW_08_FINANCE.md:81`, `:91`, `:297` ; `ADMIN_FINANCE_CONFIGURATION.md:68` (`/admin/finance`, Vue d'ensemble). Les citations sont exactes |
| Page neutre honnête | `finance_page.dart` : `EtatSysteme(nature: indisponible)`, aucun bouton. Le champ `dependance: 'FI-1c, FI-11a…'` n'est jamais affiché ni lu au lecteur d'écran (`etat_systeme.dart:77-78`) |
| `/demo/finance` gardée comme les autres démos | `demo_finance_page.dart:23`, la même garde que `demo_adulte_page.dart:350` et les autres ; `redirection.dart:50-64` ; `app_router.dart:1192` |
| Slang régénéré et cohérent | Relance de `dart run slang` sur `af9f408b` : `git hash-object` des trois `strings*.g.dart` = blobs de HEAD (`ba09c482…`, `8402be76…`, `bccd0a96…`). Seules les fins de ligne diffèrent (autocrlf) |
| `dart analyze` à 0 | Relancé sur tout le projet : `Analyzing finance-controle-fi1b... No issues found!` (`controle_01_pubget_slang_analyze.log`) |
| Suites admin, routeur, widgets et démo vertes | **Relancées** : `test/features/admin_finance test/router test/widgets test/features/admin_coque_test.dart test/features/demo test/accessibilite/admin_ad11_test.dart` donnent `04:52 +702 ~10: All tests passed!`, code 0 (`controle_02_tests.log`). Les 6 tests de `finance_domaine_test.dart` passent. Les 10 sautés sont des captures |
| Journaux de l'auteur | `03_analyze_tests_passage2.log:29108` = `07:06 +880 ~10: All tests passed!` ; aucune ligne `[E]` ni « Some tests failed » ; lignes 1 à 3 : format 0 changé, puis « No issues found! » |
| Aucune nouvelle violation `verifier_revue` | **Lancé sur la base `7c612872`**, ce que l'auteur n'avait pas fait : 1662 violations. Sur `af9f408b` : 1662. Les deux sorties `--detail` sont **identiques ligne à ligne** (1669 lignes, 0 différence ; `controle_04_verifier_af9f408b.log`, `controle_05_verifier_base_7c612872.log`) |
| Preuves poussées dans le pilotage | `d8456147` = tête de `origin/pilotage/tuteur-v1` (ls-remote au début du contrôle) ; `git show --stat` : seulement `verifications/2026-10-03/FI-1b/` (5 fichiers) |

En plus de ce que demandait l'énoncé (le routeur et la porte de redirection sont partagés par tous les rôles), j'ai lancé `test/core test/agent test/theme test/teaching_core/g test/features/enseignant_recette test/features/foyer/vague_adulte_routeur_reel_test.dart test/tool`. Résultat : `03:52 +936 ~288: All tests passed!`, code 0. Les 288 sautés portent tous « CAPTURE_DIR absent » (`controle_03_tests_hors_perimetre.log`).

## Écarts relevés

1. **Moyen (déjà déclaré par l'auteur) : critère de `02_DECOUPAGE.md` non tenu.** Le « Fait quand » de FI-1b (`02_DECOUPAGE.md:30`) demande qu'un test prouve l'absence de `/demo/finance` en `production` **et** quand l'environnement n'est pas déclaré. Or `env.dart:97-100` donne `defaultValue: 'developpement'`, si bien qu'une compilation sans `--dart-define=ENVIRONNEMENT` enregistre la route. L'énoncé de l'orchestratrice ne demandait que la production, ce qui est tenu. La leçon 14 de `LECONS_DES_ROLES.md:183` cite précisément m13. **Étape proposée** (même proposition que l'auteur) : corriger m13 sur la porte partagée `environnementAutoriseDemo`, avec un test injectable, pour toutes les démos.
2. **Mineur (nouveau) : commentaire faux dans le code livré.** `lib/features/demo/demo_finance_page.dart:20-21` dit « AUCUNE en production, **ni quand l'environnement n'est pas declare** ». C'est le contraire de l'écart 1 et de ce que dit le propre rapport de l'auteur. Le commentaire hérité `mode_demonstration.dart:61-62` (« une compilation mal declaree ne l'ouvre jamais ») a le même défaut : il est antérieur, mais FI-1b l'a recopié. **À corriger dans l'étape m13**, pour ne pas rouvrir FI-1b.
3. **Mineur : suite complète non lancée.** L'auteur ne l'a pas lancée, et moi non plus. Restent hors de nos deux passages : `test/teaching_core` hors `g` et `q04`, le reste de `test/features`, `test/capture` avec captures, et les autres dossiers. La leçon 6 l'exige avant de dire une branche « prête », pas pour `dev_ok`. Build web non lancé.
4. **Remarque : l'énoncé dit « test/admin* ».** Ce dossier n'existe pas à la racine de `test/`. L'auteur l'a lu comme « tous les tests admin » (`test/features/admin_*`, `test/accessibilite/admin_ad11_test.dart`, `test/router/admin_domaine_test.dart`, `test/widgets/admin_shell_test.dart`). Cette lecture est raisonnable, et ces fichiers sont verts.

Les deux réserves mineures de l'auteur restent valables telles qu'il les décrit : le « Mon compte » et les autres domaines sont inertes dans la démo, et les cinq états seront à livrer avec FI-11a et FI-11b.

## Journaux de ce contrôle

- `controle_01_pubget_slang_analyze.log` : pub get, slang, `git status` après slang, analyze
- `controle_02_tests.log` : suites relancées (+702 ~10)
- `controle_03_tests_hors_perimetre.log` : test/core, agent, theme, teaching_core/g, enseignant_recette, vague_adulte_routeur_reel, tool (+936 ~288)
- `controle_04_verifier_af9f408b.log`, `controle_05_verifier_base_7c612872.log` : `verifier_revue --detail`, tête et base
- `controle_05_checkout.log` : les HEAD successifs du worktree de contrôle (base, puis retour à `af9f408b`)
