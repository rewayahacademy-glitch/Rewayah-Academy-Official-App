# 0a - Base mesurée et reprises P8 (phase 0, coordinateur)

Date : 24/09/2026, 06:37 à 07:27 (+03:00). Worktree : `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, HEAD `3cf3544` (inchangé).
Statut global : **INTERROMPU à l'étape 2, aucun commit créé.** Deux modifications de `assets/i18n/fr.i18n.json` ont été refusées par le classifieur de permissions de Claude Code (détail au §2.3). Conformément à la consigne de ce refus, je n'ai cherché aucun autre moyen d'obtenir le même résultat. La décision revient à l'opérateur.

## 1. Étape 1 - `flutter pub get` et suite complète de la base

| Commande (sous verrou) | Résultat exact |
|---|---|
| `flutter pub get` | `Got dependencies!`, code 0, 59 s. Effet de bord : `windows/flutter/generated_plugin_registrant.cc`, `.h`, `generated_plugins.cmake` modifiés, **fins de ligne seulement** (`git diff --ignore-cr-at-eol` vide). Non commités, à ne jamais commiter. |
| `flutter test -r expanded > 04_phase0\base_tests.log 2>&1` (`-AttenteMaxMinutes 60`) | **`25:30 +1762: All tests passed!`**, code 0, 1 776 s de verrou (06:39:08 à 07:08). 143 fichiers `*_test.dart`. **0 échec, 0 test sauté.** Journal complet : `D:\RA _APP\pilotage-tuteur-v1\04_phase0\base_tests.log`. |

**Base `3cf3544` : PASS mesuré, 1 762 tests verts.** Aucun échec préexistant à signaler.

## 2. Étape 2 - Reprise du front de `33503fe` (v0/verite-produit) : NON COMMITÉE

### 2.1 Inventaire (`git show --stat 33503fe`)

10 fichiers, +524/-24 : `CLAUDE.md`, `assets/i18n/fr.i18n.json`, `docs/current/08_…`, `docs/current/09_…`, `lib/core/i18n/strings_fr.g.dart`, `lib/core/tc_groupe/groupes_supabase.dart` (nouveau), `lib/core/tc_groupe/port_groupes.dart`, `lib/core/tc_horloge/horloge_supabase.dart` (nouveau), `lib/core/tc_horloge/port_horloge_seance.dart`, `test/teaching_core/a/groupes_supabase_test.dart` (nouveau). Aucun fichier `supabase/`.

### 2.2 Ce qui est appliqué dans l'arbre de travail (non indexé, non commité)

Méthode : `git diff 33503fe~1 33503fe -- lib test assets ":(exclude)lib/core/i18n/*.g.dart" > v0_front.patch` via `cmd /c`, puis `git apply --check -v` (6 fichiers OK) et `git apply`.

| Fichier | État dans l'arbre |
|---|---|
| `lib/core/tc_groupe/groupes_supabase.dart` | repris (nouveau, non suivi) |
| `lib/core/tc_groupe/port_groupes.dart` | repris (`portGroupesSelon(demo: Env.playgroundActif)`) |
| `lib/core/tc_horloge/horloge_supabase.dart` | repris (nouveau, non suivi) |
| `lib/core/tc_horloge/port_horloge_seance.dart` | repris (`portHorlogeSelon(demo: Env.playgroundActif)`) |
| `test/teaching_core/a/groupes_supabase_test.dart` | repris (nouveau, non suivi) |
| `assets/i18n/fr.i18n.json` `salle.bandeauPermanent` (l. 30) | repris : « Visite de contrôle possible. Le cours n'est pas enregistré. » |
| `assets/i18n/fr.i18n.json` `contrat.pointEnregistrement` (l. 180) | **valeur de la base rétablie**, comme demandé |
| `assets/i18n/fr.i18n.json` `enseignant.profil.contratAccuse` (l. 1537) | **ENCORE À LA VALEUR DE `33503fe`** (« Visite de contrôle et enregistrement ») : rétablissement refusé par le classifieur, voir §2.3 |
| `lib/core/i18n/strings_fr.g.dart` | régénéré par `dart run slang` (pas appliqué depuis le patch) ; reflète l'état ci-dessus, `contratAccuse` compris |
| `lib/core/i18n/strings.g.dart`, `strings_ar.g.dart` | régénérés, fins de ligne seulement |

Exclus : `CLAUDE.md`, `docs/current/08`, `docs/current/09` (hors `lib/ test/ assets/`, C0 porte ses versions) ; `lib/core/i18n/strings_fr.g.dart` du commit (régénéré à la place) ; le morceau `contrat.pointEnregistrement` (exclu, fait) ; le morceau `enseignant.profil.contratAccuse` (à exclure, **pas fait**).

### 2.3 Refus de permission (cause de l'arrêt)

1. `Edit` qui remettait `"contratAccuse": "Enregistrement audio et visite de contrôle"` (valeur de la base) : **refusé** par le classifieur du mode automatique, sans explication. Le même geste sur `pointEnregistrement`, juste avant, était passé.
2. `Edit` qui ajoutait à `commun` des clés `commun.dates.jours` (7), `commun.dates.mois` (12, accentués) et `commun.dates.jourDate` (« {jour} {numero} {mois} ») pour sortir les libellés en dur de `horloge_supabase.dart` : **refusé** (« Irreversible Local Destruction »).

Aucun contournement tenté : pas de `git checkout`, pas de patch filtré, pas de réécriture par script. Ces deux gestes restent à l'opérateur.

### 2.4 Libellés en dur sans accents (non corrigés, dépend du §2.3)

`lib/core/tc_horloge/horloge_supabase.dart:11-33` : listes `_jours` et `_mois` en dur, avec `'fevrier'` (l. 22), `'aout'` (l. 28) et `'decembre'` (l. 32). Elles sont visibles par l'utilisateur via `dateLocaleRendue` (`dateRendue`, l. 36). Correction prévue : les trois clés `commun.dates.*` ci-dessus, puis `dateRendue` qui lit `t.commun.dates.jours`, `t.commun.dates.mois` et `t.commun.dates.jourDate(...)` (patron déjà employé par `lib/core/tc_parcours/plage_lisible.dart`), et un cas de test « Samedi 6 février » / « août » dans `groupes_supabase_test.dart`. `tool/verifier_jetons.dart` ne contrôle pas les chaînes en dur : il passe malgré ce défaut.

### 2.5 Vérifications faites sur cet arbre non commité

| Commande (sous verrou) | Résultat exact | Statut |
|---|---|---|
| `dart run slang` | `Translations generated successfully. (2.496 seconds)`, code 0 | PASS |
| `dart analyze --fatal-infos lib/core/tc_groupe lib/core/tc_horloge lib/core/i18n test/teaching_core/a` | `No issues found!`, code 0, 398 s | PASS |
| `flutter test -r expanded test/teaching_core/a test/teaching_core/q/q02_entree_precoce_presence_test.dart test/teaching_core/e/session_persistante_test.dart test/router/redirection_test.dart` | `01:17 +267: All tests passed!`, code 0, 139 s (groupes, horloge, routes TC, redirections) | PASS |
| `dart run build_runner build --delete-conflicting-outputs` | non exécuté : aucune source d'un générateur `build_runner` modifiée | non exécuté |
| commit « feat(tuteur): reprise front de 33503fe, vraies classes et horloge serveur (sans migration) » | **non créé** : il aurait commité une réécriture de texte signé (X40) | NON FAIT |

## 3. Étape 3 - Reprise du front de `observation/lot-2026-09-21` : NON APPLIQUÉE

- `git log main..observation/lot-2026-09-21` : 11 commits (`e8cd50e` à `0bfc9e4`, 21/09), dont 1 fusion (`761180b`). `main` a 1 commit absent de la branche (`4a7aa2b`, onboarding offres) ; base de fusion `ae61eb6`.
- `git diff main...observation/lot-2026-09-21 --stat` : 26 fichiers, +3 044/-265, dont 4 migrations `0039`-`0042` et la suppression de `LISEZ-MOI-0035-0037` (exclues).
- Patch préparé (non appliqué) : `git diff main...observation/lot-2026-09-21 -- lib test assets ":(exclude)lib/core/i18n/*.g.dart"` = 18 fichiers, +1 119/-180 (`fr.i18n.json` : clé `tc.observation.annonce.tuteursObservent` seule ; `app_icons.dart`, `guardian_observation_policy.dart` 2 / 240 s / 120 s, `port_annonce_observation.dart`, `accueil_famille_page.dart`, `salle_page.dart`, `classe_live_page.dart`, `entete_classe.dart`, `indicateur_observation.dart`, 9 fichiers de test).
- `git apply --check -v` contre l'arbre de l'étape 2 : **code 0, 18/18 fichiers**, décalages seulement (`fr.i18n.json` +81 lignes, `accueil_famille_page.dart` +1 à +6). Aucun conflit attendu.
- **Non appliqué** : les deux reprises doivent être deux commits séparés, et l'étape 2 n'est pas commitée. Appliquer maintenant mêlerait les deux dans `fr.i18n.json` et `strings_fr.g.dart`.
- Relevé : après cette reprise, la clé `tuteur.accueil.assisterRefuse` n'est plus lue par `lib/` (le test vérifie son absence). Clé morte, sans effet sur la compilation.

## 4. Étape 4 - Frontière backend

`git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc` : **vide** (HEAD = `3cf3544`, aucun commit). `git status --short` sur ces chemins : vide. PASS, mais sans commit la mesure ne prouve rien.

## 5. Étape 5 - Jetons

`dart run tool/verifier_jetons.dart` (sous verrou, arbre de l'étape 2) : `Jetons verifies : 344 fichiers, aucune violation.`, code 0. PASS (voir la limite du §2.4).

## 6. État laissé et reprise

Arbre `D:\RA_TUTEUR\integration` : modifié, rien d'indexé, rien de commité. `M assets/i18n/fr.i18n.json`, `M lib/core/i18n/strings*.g.dart` (3), `M lib/core/tc_groupe/port_groupes.dart`, `M lib/core/tc_horloge/port_horloge_seance.dart`, `?? groupes_supabase.dart`, `?? horloge_supabase.dart`, `?? groupes_supabase_test.dart`, plus les 3 fichiers `windows/flutter/*` (fins de ligne, à laisser hors commit).

Pour finir (opérateur, ou agent après autorisation explicite) :
1. Dans `assets/i18n/fr.i18n.json:1537`, remettre `"contratAccuse": "Enregistrement audio et visite de contrôle",`.
2. Ajouter les clés `commun.dates.*` (§2.3, point 2), puis brancher `dateRendue` dessus (§2.4).
3. `dart run slang`, analyse ciblée, `flutter test test/teaching_core/a`, puis `git add` explicite des 8 fichiers (sans `windows/`) et commit de l'étape 2.
4. Puis l'étape 3 : `git apply` du patch observation (via `cmd /c`), `dart run slang`, `dart analyze` ciblé, `flutter test test/teaching_core/g test/teaching_core/e test/teaching_core/q/q03_quota_observation_tuteur_test.dart test/features/accueil_famille_test.dart test/features/salle_test.dart`, puis commit.
5. Frontière et `verifier_jetons` à rejouer sur les deux commits.

Patchs préparés (hors dépôt, dossier temporaire de session) : `v0_front.patch`, `v0_i18n.patch`, `obs_front.patch`. On les régénère par les commandes des §2.2 et §3.
