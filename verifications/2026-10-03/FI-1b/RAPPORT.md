# FI-1b — Socle 1 Finance : branche, domaine Finance, route /demo/finance

Session agent pour l'orchestratrice 00166a22, 03/10/2026. Voie FIN, étape de code.

## Résultat

- Branche `ui/finance-v1` créée par la commande de l'énoncé, poussée : `origin/ui/finance-v1` = `af9f408b` (sortie `git ls-remote`).
- Worktree `D:\RA_TUTEUR\finance`.
- Un commit : `af9f408b FI-1b : domaine Finance actif dans l'AdminShell (...)`.

### Écart de base, à connaître

L'énoncé dit `origin/corrections/revue-directeur-2026-10` « = 4a4fbe7 ». Au `fetch` de 08:4x, la branche valait **`7c612872`** (fusion GALERIE-BENTO-2), qui **contient** `4a4fbe7f` (`git merge-base --is-ancestor` → 0). La commande de l'énoncé, appliquée telle quelle, part donc de `7c612872` (4 commits de plus : `c72fbe4e`, `e00c24b7`, `235b18ab`, `7c612872`, galerie et Bento). Aucune fusion `eleves-adultes` à faire : `00_REPRISE.md:4` (décision de l'orchestrateur) l'a retirée.

## Ce qui a été fait (fichier:ligne sur `af9f408b`)

| Quoi | Où |
|---|---|
| `AdminDomaine.finance.chemin` = `Routes.adminFinance` (Direction reste seul à `null`) | `lib/core/admin/admin_domaine.dart` (switch `chemin`) |
| `ongletsFinance()` : « Vue globale » → `/admin/finance`, « Politiques commerciales » → `/admin/finance/politiques` | `lib/core/admin/admin_domaine.dart` (avant `ongletsConfiguration`) |
| Routes `adminFinance`, `adminFinancePolitiques`, `demoFinance` | `lib/core/router/routes.dart` |
| Deux `GoRoute` dans `_CoquilleAdmin(domaine: finance)` ; commentaire « aucune route » corrigé (Pédagogie et Configuration en avaient déjà) | `lib/core/router/app_router.dart` |
| `...routesDemoFinance(Env.environnement)` | `lib/core/router/app_router.dart` (fin de liste des routes) |
| Porte de redirection : `/demo/finance` passe sans session **hors production seulement** | `lib/core/router/redirection.dart:50-66` |
| `FinancePage` : `PageShell` + `SousNavigationDomaine` + `EtatSysteme(nature: indisponible)` (« Pas encore disponible », textes `commun.etats.indisponible` existants), aucun port lu, aucun bouton | `lib/features/admin_finance/finance_page.dart` |
| `/demo/finance?ecran=vueGlobale|politiques` : vraie `AdminShell`, Finance actif, vraie `FinancePage`, sous `RepereDemonstration` ; liste vide si `environnementAutoriseDemo` est faux | `lib/features/demo/demo_finance_page.dart` |
| Libellés `admin.finance.vueGlobale`, `admin.finance.politiques` ; slang régénéré (`strings.g.dart`, `strings_fr.g.dart`) | `assets/i18n/fr.i18n.json` |
| Sources déclarées (convention vérifiée : `tool/verifier_revue.dart:12-14, 45, 285-322` lit `tool/libelles_sources.json` pour tout texte absent de `docs/`) | `tool/libelles_sources.json` |

**Choix des libellés et des routes, avec leur source (rien d'inventé)** :
- Onglets « Vue globale », « Politiques commerciales », dans cet ordre : `17_finance/02_DECOUPAGE.md` ligne FI-1b ; lexique de la revue `UX_REVIEW_08_FINANCE.md:297` (« guide §2 ; maquettes 09, 10 »). Déclarés comme venant du guide du directeur, **pas** « à faire valider » (ce ne sont pas des textes d'agent).
- `/admin/finance/politiques` : revue FI-1a `UX_REVIEW_08_FINANCE.md:81` a) et `:91` (le guide §4 propose `/admin/parametres/politiques-commerciales` mais dit « conserver l'existant et mapper » ; la revue a tranché pour Finance).
- `/admin/finance` = Vue globale (racine, pas de redirection) : route canonique « Vue d'ensemble » du contrat métier `ADMIN_FINANCE_CONFIGURATION.md:68` et guide §4 (`/admin/finance`).
- Page neutre honnête en production : `02_DECOUPAGE.md` ligne FI-1b (« page neutre honnête en production (port indisponible, EtatSysteme) »). Aucun texte nouveau : titres et phrase par défaut de `NatureEtat.indisponible`.

Aucune couleur, aucun thème, aucun fichier interdit (K-19) touché : `git show --stat af9f408b` liste 14 fichiers : les 10 du tableau ci-dessus (dont les deux `strings*.g.dart`) et les 4 tests ci-dessous.

## Tests et analyse (dernier passage, K-29)

Tout par `flutter-verrou.ps1`, sans `CAPTURE_DIR`.

1. `01_pubget_slang_format_analyze.log` : `flutter pub get`, `dart run slang` (« Translations generated successfully »), `dart format` (2 fichiers de test reformatés), `dart analyze` → **No issues found!**
2. `02_tests_passage1_1echec.log` : premier passage, **1 échec**, dans mon test (`find.bySemanticsLabel` du repère hors `RewayahApp` : 0 trouvé). Corrigé : le test vérifie que `RepereDemonstration` est ancêtre de l'`AdminShell`.
3. `03_analyze_tests_passage2.log` (**passage cité**) : `dart format --set-exit-if-changed` sur mes fichiers → 0 changé ; `dart analyze` → **No issues found!** ; `flutter test` sur `test/features/admin_finance`, `test/router`, `test/widgets`, `test/features/demo`, `test/features/admin_coque_test.dart`, `test/features/admin_configuration`, `admin_dossiers`, `admin_observations`, `admin_pedagogie_programmes`, les 6 fichiers `test/features/*admin*_test.dart`, `test/accessibilite/admin_ad11_test.dart`, `test/teaching_core/q/q04_capacites_admin_controleur_test.dart` → **`07:06 +880 ~10: All tests passed!`** (log:29108). Les 10 sautés : « CAPTURE_DIR absent : captures sautées ».
4. `dart run tool/verifier_revue.dart` : 1662 violations au total, **aucune** dans mes fichiers ni mes clés (`04_verifier_revue_detail.log`, recherche `admin_finance|demo_finance|admin\.finance|admin_domaine|app_router|redirection|routes\.dart` → seule ligne sans rapport, `sortie_forfait.dart:140`). Les 1662 sont antérieures (non comptées sur la base : non lancé sur `7c612872`).

Tests ajoutés ou modifiés :
- `test/features/admin_finance/finance_domaine_test.dart` (nouveau, 6 tests) : sur le **vrai** `routeurProvider` + `RewayahApp` + `surchargesDemoAdmin`, « Finance » est **tapé** dans la barre 288 à 1440 → `/admin/finance`, domaine sélectionné, onglet « Vue globale », état `indisponible` ; puis « Politiques commerciales » choisi → `/admin/finance/politiques`. Même chose depuis le tiroir mobile à 390. `/demo/finance` : `routesDemoFinance` vide pour `production`, ` Production `, `preprod`, `''`, `'   '` ; porte de redirection fermée pour `production` et `''` ; hors production, vraie coquille et l'onglet reste dans `/demo/finance?ecran=politiques`.
- `test/router/admin_domaine_test.dart` : Finance passe dans les domaines à route réelle ; « Direction n'a aucune route » ; 7 cibles de recherche (au lieu de 6).
- `test/widgets/admin_shell_test.dart` : l'exemple de domaine inerte devient Direction.
- `test/features/admin_coque_test.dart` : commentaire seulement (la boucle tapait déjà chaque domaine ; Finance y mène maintenant à sa route, testé par le même `expect`).

**Non lancés** : la suite complète (`test/core`, `test/teaching_core` hors q04, le reste de `test/features`) ; build web ; captures (FI-1b ne livre pas d'écran à maquette).

## Défauts et réserves (rien n'est rouvert, K-38)

1. **AD-R m13 toujours ouvert sur cette base** (`05_recette/AD/REVUE_AD-R.md`, m13) : `Env.environnement` vaut `developpement` par défaut (`lib/core/config/env.dart`), donc une compilation **sans** `--dart-define=ENVIRONNEMENT` ouvre toutes les démonstrations, `/demo/finance` comprise. Mon test prouve l'absence pour `production` et pour un environnement **vide** (`''`), pas pour une compilation non déclarée. `02_DECOUPAGE.md` (FI-1b, « Fait quand ») demandait les deux. Je n'ai pas modifié la porte partagée `environnementAutoriseDemo` (`mode_demonstration.dart:63`, utilisée par toutes les démos). Le déploiement passe `production` ou `staging` (`.github/workflows/flutter-deploy.yml:120-130`), risque réel limité. **Étape proposée** : corriger m13 (`kReleaseMode && !bool.hasEnvironment('ENVIRONNEMENT')` → fermé), avec un test injectable, toutes démos confondues.
2. `/demo/finance` : le pied « Mon compte » et les domaines autres que Finance ne mènent nulle part dans la démonstration (`onCompte: () {}`), comme le précédent `espaces_controleur_demo.dart:256-263`. Mineur ; à reprendre quand FI-1c pose les vues de démonstration.
3. Les cinq états (leçon 9) ne sont pas livrés : la page n'a que l'état `indisponible`, exigé ici en production. Le chargement, le vide, l'erreur, le hors-ligne et le contenu arrivent avec les ports (FI-1c) et les écrans (FI-11a, FI-11b).
4. `dart format` a aussi reformaté le `group('ciblesRechercheAdmin…')` de `test/router/admin_domaine_test.dart` (fichier que je modifiais) : diff de forme, sans changement de sens.

## Questions au directeur

Aucune nouvelle. Le choix `/admin/finance/politiques` contre `/admin/parametres/politiques-commerciales` (guide §4) suit la revue FI-1a (`UX_REVIEW_08_FINANCE.md:91`) : à confirmer si le directeur tient à la route du guide.
