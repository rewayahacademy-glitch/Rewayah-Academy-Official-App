# C10 - Base Git et travaux concurrents (chantier frontend Tuteur V1)

Relevé en **lecture seule** le 24/09/2026 entre 04:27 et 04:40 (+03:00). Aucune écriture dans le dépôt, aucun changement de branche, aucun `fetch`, aucun `stash`. Les seuls contrôles d'application de patch ont été faits avec `git apply --cached --check` (lecture pure ; horodatage de `.git/index` vérifié inchangé avant/après).

Dépôt : `D:\RA _APP\RA -OFFICIAL-APP` (checkout `c0/configuration-baseline-2026-09-23` = `3cf3544`, seul écart local : `?? .claude/`).

Légende des statuts : **constaté** (commande rejouée ici), **prétendu** (écrit dans un commentaire, un commit ou une doc, non revérifié ici), **INCONNU**.

---

## 1. Synthèse et décision proposée

| Question | Réponse | Preuve |
|---|---|---|
| Base de la branche UI | **`c0/configuration-baseline-2026-09-23` @ `3cf3544`**, dans un **nouveau worktree** (le checkout principal reste sur C0, rien n'y est commité) | §5 |
| Récupérer `v0/verite-produit` (`33503fe`) | **Oui, partie `lib/ test/ assets/` seulement** (7 fichiers, 0 fichier `supabase/`), en commit séparé et identifié ; décision directeur à tracer (V0 « suspendu » dans `08`) | §6.1 |
| Récupérer la partie frontend d'`observation/lot-2026-09-21` | **Oui, `lib/ test/ assets/` seulement** (20 fichiers), **sans aucune migration** ; régénérer `strings.g.dart` | §6.2 |
| Autres branches non fusionnées | **Rien à récupérer** (CORE24 non conforme, lots Codex du 13-15/09 antérieurs à la refonte, backend, docs) ; deux docs à **lire** seulement | §6.3 |
| Agent actif sur le dépôt | **Aucun agent concurrent** ; un `dart analyze` d'un agent frère de ce workflow tournait à 04:38 ; un Codex TUI ouvert sur un sujet sans rapport (Windows Store) | §2 |
| Danger majeur découvert | `main:.github/workflows/flutter-deploy.yml` déploie **en production** sur `workflow_dispatch` depuis **n'importe quelle branche** qui ne contient pas `ab5f7f7` (secrets présents depuis le 24/09) | §8.1 |

---

## 2. Agents et processus actifs (constaté)

Commande : `Get-Process | Where-Object Name -match "dart|flutter|claude|codex"` + `Get-CimInstance Win32_Process` (lignes de commande).

| Heure | Processus | PID | Ligne de commande / origine | Verdict |
|---|---|---|---|---|
| 01:59 | `claude.exe` | 1616 | session Claude Code (ce workflow et ses sous-agents en processus) | coordinateur, pas un concurrent |
| 03:31 | `node.exe` -> `codex.exe` -> `codex-code-mode-host.exe` | 32 / 2108 / 1636 | Codex TUI, `cwd = C:\Users\dell\AppData\Local\Programs\WindowsTerminal` (métadonnée de `~\.codex\sessions\2026\09\24\rollout-2026-09-24T03-32-21-…jsonl`, ligne 1) | **sans rapport avec Rewayah** : les messages utilisateur de la session portent sur le Windows Store et l'installation de l'app ChatGPT ; aucune commande `git`, aucun `apply_patch` sur le dépôt ; dernière entrée 01:15:23Z (04:15 locale). Laisser tourner, ne pas le considérer comme propriétaire de fichiers |
| 04:38 | `dart.exe analyze --fatal-infos` -> `dartaotruntime.exe` | 14228 / 13852 | parent `cmd.exe` <- `powershell.exe` lancé par `CLAUDE_CODE_SHELL_LAUNCHER_SCRIPT` | **agent frère de ce workflow** (analyse en lecture). Rappel du brief : une seule commande Flutter lourde à la fois (RAM libre mesurée : 1,34 Go) |

Aucun `flutter` en cours. Aucun fichier sale d'un worktree n'a été modifié après le 23/09 20:06 (§3) : **aucune écriture active constatée** dans les worktrees.

---

## 3. Worktrees (32 entrées : le checkout principal + 31 liés) - constaté

Commande : `git worktree list` puis, par worktree, `git -C <chemin> status --short` et `git log -1 --format="%h|%ci|%s"`.

| Chemin | Branche | HEAD | Dernier commit | `status --short` (suivis modifiés) | Contenu non commité notable |
|---|---|---|---|---|---|
| `D:\RA _APP\RA -OFFICIAL-APP` | `c0/configuration-baseline-2026-09-23` | `3cf3544` | 2026-09-24 01:46 | 1 (0) | `?? .claude/` (hooks, 23/09 20:06), voir §8.3 |
| `C:\Users\dell\.gemini\antigravity\worktrees\RA -OFFICIAL-APP\starlit-surge-glides-04h50` | `starlit-surge-glides-04h50` | `9d0229b` | 2026-09-16 06:25 | 0 | - |
| `…\WindowsTerminal\rewayah-astra-core24` | `astra/core24-classes-legacy-snapshot` | `3e2b53c` | 2026-09-22 17:30 | 9 (6) | `.github/workflows/ci.yml`, `supabase/tests/scenarios_n2.sql`, `ASTRA_24H_*` (22/09 08:43-14:05) |
| `…\WindowsTerminal\rewayah-classes-v2` | `integration/core24-classes-v2` | `e8beeb7` | 2026-09-22 21:05 | 4 (3) | `?? CORE24_CLASSES_COMPLIANCE_AUDIT.md` (22/09 21:35) |
| `…\WindowsTerminal\rewayah-classes-v2-remediation` | `integration/core24-classes-v2-remediation` | `3c0cb1c` | 2026-09-23 02:10 | 0 | - |
| `…\WindowsTerminal\rewayah-login` | `codex/login-demo` | `1110400` | 2026-09-15 01:04 | 4 (4) | `strings_ar.g.dart` + générés Windows |
| `…\WindowsTerminal\rewayah-presence-ui` | `codex/presence-correction-ui` | `d55606c` | 2026-09-15 00:02 | 3 (3) | générés Windows |
| `…\WindowsTerminal\rewayah-prod-release` | `codex/production-google-auth-20260916` | `b02ea98` | 2026-09-15 04:07 | 16 (15) | `service_auth.dart`, `env.dart`, `connexion_page.dart`, `compte_page.dart`… (16/09 00:12-00:31 ; archivés selon bilan C0 §3.3) |
| `…\WindowsTerminal\rewayah-r1` | `codex/r1-adaptive-design-system` | `405683a` | 2026-09-13 22:12 | 0 | - |
| `…\WindowsTerminal\rewayah-r2` | `codex/r2-adaptive-shell` | `65c564f` | 2026-09-14 22:39 | 26 (21) | routeur ×3, `nav_shell.dart`, `?? lib/features/compte/`, `?? lib/core/preferences/` (14/09 ; archivés selon bilan §3.2) |
| `…\WindowsTerminal\rewayah-review-20260915` | `codex/review-visible-20260915` | `b02ea98` | 2026-09-15 04:07 | 0 | - |
| `…\WindowsTerminal\rewayah-vague5-integration` | `codex/vague5-integration` | `f8a6988` | 2026-09-15 00:50 | 0 | - |
| `…\Temp\claude\…\scratchpad\baseline` | (détaché) | `e104605` | 2026-09-18 16:01 | 3 (3) | - |
| `D:\ra-pwa-build` | (détaché) | `e76a14e` | 2026-09-12 17:46 | 84 (62) | anciens lots N2 |
| `D:\ra-pwa-ctr` | (détaché) | `f1855de` | 2026-09-13 01:38 | 71 (59) | ancien lot N4 |
| `D:\ra-pwa-deploy-20260918` | (détaché) | `99c7b6a` | 2026-09-16 06:33 | 10 (10) | - |
| `D:\ra-pwa-fix` | (détaché) | `090ae6f` | 2026-09-13 09:53 | 3 (3) | - |
| `D:\ra-pwa-secure-deploy` | (détaché) | `cbc4ff8` | 2026-09-13 17:10 | 5 (4) | - |
| `D:\RA_CORE24\fable` | `core24/fable-frontend` | `50fae3c` | 2026-09-22 04:45 | 0 | - |
| `D:\RA_OBS` | `observation/lot-2026-09-21` | `0bfc9e4` | 2026-09-21 16:00 | 4 (3) | **`?? supabase/migrations/0043_autoriser_jeton_video_verifie_le_bon_compte.sql`** (21/09 16:47), jamais commité, voir §8.4 |
| `D:\RA_ONBOARD` | `lot/onboarding-offres` | `9a3ff0d` | 2026-09-22 14:50 | 4 (3) | `?? CORE24_CLASSES_ARBITRATION_FINAL.md` (22/09 15:41, divergent selon bilan C0 §3.2) |
| `D:\RA_TC\0` | `teaching-core/0-coordinateur` | `6081601` | 2026-09-20 16:17 | 0 | - |
| `D:\RA_TC\{a,b,c,d,e,f,g,h,q}` | `teaching-core/{a…q}` | `28c2238`, `d5bc5bf`, `e60c5b4`, `bc40b4a`, `4e65e50`, `bf01953`, `3545f8c`, `a9b295b`, `8337531` | 2026-09-20 | 0 chacun | - |
| `D:\RA_TC\z` | `integration/teaching-core` | `d5eb74c` | 2026-09-21 01:43 | 0 | - |

Dans presque tous les worktrees sales, les 3 fichiers `windows/flutter/generated_plugin*` modifiés sont des artefacts de `flutter pub get`, pas du travail.

**Aucun worktree ne doit être modifié, nettoyé ni retiré par ce chantier** (brief : suppression de worktree interdite ; `08` §3 ligne « Worktrees »).

---

## 4. Branches

### 4.1 Distant (constaté, `git ls-remote`, lecture seule)

`origin/main` = `4a7aa2b` (inchangé : aucune poussée sur `main` depuis le 22/09). Tous les SHA distants listés sont égaux aux locaux. Références de PR : `refs/pull/1/head = ed431ac` (lavande -> `specs`), `refs/pull/2/head = 3cf3544` (C0 -> `main`). L'état ouvert/brouillon des PR n'est pas lisible par `ls-remote` : **INCONNU ici** (le bilan C0 les dit ouvertes, #2 en brouillon ; le MCP GitHub a échoué à la connexion).

### 4.2 Fusionnées dans `main` (0 commit unique, constaté `git branch --merged main`)

`admin-complet`, `codex/production-google-auth-20260916`, `codex/release-all-20260915`, `codex/review-visible-20260915`, `integration/teaching-core`, `starlit-surge-glides-04h50`, `teaching-core/{a,b,c,d,e,f,g,h,q}`. Rien à récupérer.

### 4.3 Non fusionnées dans `main` (constaté : `git log main..<b>`, `git cherry -v main <b>`, `git diff --stat main...<b> -- lib test assets`, `-- supabase`)

`git cherry` marque **tous** les commits ci-dessous `+` (aucun équivalent de patch déjà dans `main`).

| Branche | HEAD, date | Avance / retard sur `main` | merge-base | `lib/ test/ assets/` | `supabase/` | Intérêt tuteur | Verdict |
|---|---|---|---|---|---|---|---|
| `c0/configuration-baseline-2026-09-23` | `3cf3544`, 24/09 01:46 | +9 / -0 | `4a7aa2b` | ~120 fichiers, **commentaires seulement** (§5.2) | `supabase/CLAUDE.md` + commentaires `--` de 14 migrations appliquées | règles actives, CI d'aperçu | **BASE** |
| `v0/verite-produit` | `33503fe`, 23/09 15:32 | +2 / -0 ; **vs C0 : +1 (`33503fe`)** | `4a7aa2b` | `33503fe` : 7 fichiers (+524/-24 au total du commit) | **0** dans `33503fe` | élevé : groupes réels, horloge serveur, libellés d'enregistrement | **récupérer `lib/ test/ assets/`** (§6.1) |
| `nettoyage/base-2026-09-23` | `2a8b847`, 23/09 16:35 | +3 / -0 | `4a7aa2b` | = `4e9903c` + `33503fe` + docs C0 v1 | commentaires | aucun en propre | remplacée par C0 + V0 ; ne pas utiliser |
| `observation/lot-2026-09-21` | `0bfc9e4`, 21/09 16:00 | +11 / -1 | `ae61eb6` | 20 fichiers (+1124/-181) | `0039`-`0042` (+1652) et suppression de `LISEZ-MOI-0035-0037` | **élevé** (parcours Observation) | **récupérer `lib/ test/ assets/` sans `supabase/`** (§6.2) |
| `lot/onboarding-offres` | `9a3ff0d`, 22/09 14:50 | +1 / -0 | `4a7aa2b` | 0 | 0 | lecture : `docs/produit/onboarding-questions-expliquees.md` (+10/-2), badges | lire seulement (Admission) |
| `docs/core24-classes-arbitration` | `196eb06`, 22/09 17:35 | +2 / -0 | `4a7aa2b` | 0 | 0 | lecture : `docs/architecture/CORE24_CLASSES_ARBITRATION_FINAL.md` (368 lignes, **absent de C0**) = décisions « Classes V2 » demandées par le mandat §2 | lire seulement, via `git show 196eb06:<chemin>` |
| `integration/core24-classes-v2` | `e8beeb7`, 22/09 21:05 | +10 / -0 | `4a7aa2b` | 40 (33 `lib/`) | 16, dont 7 migrations `20260921…_core24_*` | CORE24 | **NON CONFORME, ne pas intégrer** |
| `integration/core24-classes-v2-remediation` | `3c0cb1c`, 23/09 02:10 | +15 / -0 | `4a7aa2b` | 40 | 18, dont 8 migrations `core24` | CORE24 | **ne pas intégrer** |
| `astra/core24-v2` / `astra/core24-presence-safeguard` / `astra/core24-classes-legacy-snapshot` | `ce7e7e7` / `730b7b7` / `3e2b53c`, 22/09 | +17 / +18 / +19, -1 | `ae61eb6` | jusqu'à 70 | `0039`-`0042` + migrations `core24` | CORE24 + fusion d'observation | **ne pas intégrer** |
| `core24/fable-frontend` | `50fae3c`, 22/09 04:45 | +2 / -1 | `ae61eb6` | 79 (+12678/-5438) : **supprime** `features/salle/salle_page.dart` (1421 lignes), `salle_enseignant/*`, crée `features/tuteur_classes/classes_foyer_page.dart`, `features/classes/**` | 0 | CORE24 | **NON CONFORME, jamais intégrer, jamais copier** |
| `codex/r1-adaptive-design-system` | `405683a`, 13/09 22:12 | +1 / **-116** | `cbc4ff8` (13/09) | 29 : réécrit `app_palette.dart` (538), `app_theme.dart` (289), `app_typography.dart` (84) | 0 | thème | non : antérieur à la refonte, conflit massif |
| `codex/r2-adaptive-shell` | `65c564f`, 14/09 22:39 | +4 / -116 | `cbc4ff8` | 34 (r1 + `nav_shell.dart` adaptatif 259, profil enseignant) | 0 | shell | non (référence de lecture au plus) |
| `codex/vague5-integration` | `f8a6988`, 15/09 00:50 | +7 / -116 | `cbc4ff8` | 41 (r1 + r2 + correction de présence) | 0 | - | non |
| `codex/login-demo` | `1110400`, 15/09 01:04 | +1 / -116 | `cbc4ff8` | 9 (connexion locale par mot de passe) | 0 | - | non (parcours de démo) |
| `codex/presence-correction-ui` | `d55606c`, 15/09 00:02 | +1 / -116 | `cbc4ff8` | 3 (surface propriétaire) | 0 | - | non |
| `sauvegarde/r2-du-tiers` | `201b521`, 21/09 06:13 | +1 / -8 | `08d8edb` | 0 | 17 (`supabase/functions/_shared/r2/*`) | backend | non |
| `teaching-core/0-coordinateur` | `6081601`, 20/09 16:17 | +2 / -78 | `0071557` | 0 | 0 | docs TC | non |
| `refactor-ui-lavender-3628477128789856989` | `ed431ac`, 09/09 | **aucun ancêtre commun** (racine `8a652d6` ≠ racine de `main` `2d871da`) | - | - | - | palette lavande, contredit `03` | non ; PR #1 |
| `specs` | `8a652d6`, 09/09 | aucun ancêtre commun | - | - | - | docs Jules périmés | non |

### 4.4 Stashes (constaté, `git stash list`)

`stash@{0}` (EOL Windows sur r1), `stash@{1}` (copies ADM-04 déjà commitées), `stash@{2}` (état avant `5b8b868`). Ne pas appliquer (`08` §3).

---

## 5. Base de la branche UI dédiée

### 5.1 Recommandation

**Partir de `c0/configuration-baseline-2026-09-23` @ `3cf3544`** (= `origin/c0/…`, 9 commits devant `main`, 0 derrière), dans un **worktree neuf** hors du checkout principal, par exemple branche `ui/tuteur-v1`, dossier `D:\RA_TUTEUR` (nom au choix du coordinateur ; D: a 48 Go libres).

### 5.2 Justification (constatée)

| Critère | `main` @ `4a7aa2b` | C0 @ `3cf3544` |
|---|---|---|
| Règles actives lues par les agents | **Absentes** : `git ls-tree main docs/current/` est vide ; `main:lib/CLAUDE.md:3` impose « Avant tout : `docs/design/00-bible-frontend-v2.md` » (Bible V2, archivée) ; `main:CLAUDE.md` ne cite jamais `docs/current` | `docs/current/00`-`09` + `CLAUDE.md` et `lib/CLAUDE.md` réécrits (seules règles actives selon `08` §5 bis, ligne du 23/09 soir) |
| Code Flutter | référence | **identique à `main` à des commentaires près** : 370 lignes changées dans `lib/ test/ tool/ assets/ pubspec.yaml slang.yaml` (hors `lib/CLAUDE.md`), toutes des réécritures de liens `docs/…` -> `docs/archive/2026-09-pre-remise-a-plat/…`, sauf 3 retraits de BOM (`import 'teacher_student_projection.dart'`, `import 'dart:async'`, `import 'package:flutter/widgets.dart'`). Ex. `app_router.dart:75,378,419,440,548,746,831`, `routes.dart:9,119,162,222`, `pubspec.yaml:33`, `tool/verifier_jetons.dart:5,28,48,91,120,138,354,430` : commentaires seulement |
| Aperçu Vercel d'une PR | **impossible** : `main:.github/workflows/flutter-deploy.yml:19-22` ne se déclenche que sur `push main` et `workflow_dispatch` | `c0:flutter-deploy.yml:29-34` ajoute `pull_request: [main]` ; `:68` réserve `--prod` à `push`/dispatch sur `refs/heads/main` ; `:176` seul `--prod` |
| Sécurité d'un `workflow_dispatch` depuis la branche | **dangereux** : `main:flutter-deploy.yml:132-135` exécute `vercel deploy --prod` sans condition de branche | aperçu seulement hors `main` |
| Risque | aucun lien avec la PR #2 | si le directeur modifie encore C0 (ex. retirer les 14 hunks de commentaires de migrations, `08` §5 bis ligne du 23/09), la branche UI devra réintégrer C0 ; aucun conflit attendu puisque la branche UI ne touche ni `docs/`, ni `supabase/`, ni `.github/` |

Conséquence de mesure : la frontière « aucun changement backend » se contrôle **contre C0**, pas contre `main` (sinon les commentaires de migrations de C0 apparaissent) :
`git diff --stat 3cf3544...<branche-ui> -- supabase .github vercel.json .firebaserc dart_define.example.json` doit être **vide**.

### 5.3 Commandes proposées au coordinateur (NON exécutées ici)

```powershell
# 0. Revérifier la base au moment de créer (ne pas reprendre aveuglément un hash)
git -C "D:\RA _APP\RA -OFFICIAL-APP" rev-parse c0/configuration-baseline-2026-09-23 origin/c0/configuration-baseline-2026-09-23 origin/main
# 1. Worktree dédié (n'altère pas le checkout principal)
git -C "D:\RA _APP\RA -OFFICIAL-APP" worktree add -b ui/tuteur-v1 "D:\RA_TUTEUR" 3cf3544
# 2. Fichier local ignoré par Git, nécessaire à flutter run (ne jamais l'afficher)
Copy-Item "D:\RA _APP\RA -OFFICIAL-APP\dart_define.json" "D:\RA_TUTEUR\"
# 3. Reprises frontend (§6) : via cmd /c, JAMAIS via un pipe PowerShell 5.1 (§8.5)
cmd /c "cd /d D:\RA_TUTEUR && git diff 33503fe~1 33503fe -- lib test assets | git apply --index"
cmd /c "cd /d D:\RA_TUTEUR && git diff main...observation/lot-2026-09-21 -- lib test assets :!lib/core/i18n/strings.g.dart | git apply --index"
# 4. Régénération puis contrôles, une commande lourde à la fois
dart run slang ; dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos ; dart run tool/verifier_jetons.dart ; flutter test <fichiers ciblés>
# 5. Frontière backend
git -C D:\RA_TUTEUR diff --stat 3cf3544...HEAD -- supabase .github vercel.json .firebaserc
```

Le nouveau worktree n'aura ni `.claude/` (non suivi), ni `dart_define.json` (ignoré), ni `.dart_tool/` : un `flutter pub get` sera nécessaire (réseau et RAM).

---

## 6. Changements frontend à récupérer par diff

### 6.1 `v0/verite-produit` : commit `33503fe` (partie `lib/ test/ assets/`)

**Ce que fait le code aujourd'hui sur C0 (= `main`)** (constaté) :
- `lib/core/tc_groupe/port_groupes.dart:38` : `(Ref ref) => GroupesDemonstrationLocale()` sans condition, donc un tuteur en production voit des groupes inventés via `/tc/groupes` (entrée `lib/features/accueil_famille/accueil_famille_page.dart:467`).
- `lib/core/tc_horloge/port_horloge_seance.dart:55` : `HorlogeSeanceDemonstration()` sans condition.
- Le mandat interdit ce comportement (« fixtures … jamais comme fallback silencieux de production », §3).

**Ce qu'apporte `33503fe`** (constaté par `git show`) : `portGroupesSelon(demo: Env.playgroundActif)` -> `GroupesSupabase` (vue `mes_groupes_famille_v`) en production, double seulement sous `PLAYGROUND=true` ; idem `HorlogeSeanceSupabase` (`horloge_seance()`, `maintenant_serveur()`) ; trois libellés i18n qui cessaient d'affirmer un enregistrement (`salle.bandeauPermanent`, `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse`). `Env.playgroundActif` existe sur C0 (`lib/core/config/env.dart:33`).

Fichiers : `assets/i18n/fr.i18n.json`, `lib/core/i18n/strings_fr.g.dart`, `lib/core/tc_groupe/groupes_supabase.dart` (nouveau, 95 l.), `lib/core/tc_groupe/port_groupes.dart`, `lib/core/tc_horloge/horloge_supabase.dart` (nouveau, 152 l.), `lib/core/tc_horloge/port_horloge_seance.dart`, `test/teaching_core/a/groupes_supabase_test.dart` (nouveau, 156 l.). **Aucun fichier `supabase/`.** Les autres fichiers du commit (`CLAUDE.md`, `docs/current/08`, `docs/current/09`) sont **à exclure** : C0 porte déjà ses propres versions.

Application : `git diff 33503fe~1 33503fe -- lib test assets | git apply --cached --check` contre l'index C0 = **OK** (constaté, via `cmd /c`).

Réserve de gouvernance : `08` §0 et §5 bis (lignes du 23/09 et du 23/09 soir) gardent **V0 suspendu** et laissent au directeur « conserver `33503fe` … ou le reverter » (`08:66`, `08:82`). Le mandat Tuteur V1 (demande la plus récente du directeur, qui prime selon `CLAUDE.md` « Invariants ») exige des sources réelles : la reprise est cohérente avec lui, mais doit être **un commit séparé, nommé, réversible**, et signalée dans le rapport au directeur. Limites prétendues par le message de `33503fe` : 0 groupe et 0 séance en production le 23/09, titre enseignant replié sur Sayyid si absent, pas d'occurrence dans la vue donc pas de « Rejoindre » avant V1/V2 (dépendances backend pour Agent C).

### 6.2 `observation/lot-2026-09-21` (partie `lib/ test/ assets/`, sans migration)

**Ce que fait le code aujourd'hui sur C0** (constaté) :
- `lib/core/tc_observation/guardian_observation_policy.dart:78-80` : défauts **1 visite / 120 s au total / pas de plafond par visite**, alors que `supabase/migrations/0036_observation_defauts_academie_et_plafond_visite_groupe.sql:17-19,191` (présente sur `main`, appliquée selon le bilan C0 §5) pose 2 / 120 s par visite / 240 s, exactement la règle du mandat (partie observation §4).
- `lib/features/accueil_famille/accueil_famille_page.dart:180-193` : « Assister » appelle `assisterEnTuteur` puis `go(Routes.salle)` ; la porte d'observation `/tc/observation/:seanceId` (`lib/core/router/routes.dart:338`, `lib/features/tc_observation_ui/routes_tc_g.dart:21`) **n'a aucun appelant** dans `lib/` (grep constaté) ; le commentaire `lib/features/tc_classe_live/entete_classe.dart:199` le dit aussi.

**Ce qu'apporte la branche** (constaté par `git diff main...observation/lot-2026-09-21`) :
- `guardian_observation_policy.dart` : défauts 2 / 240 s / 120 s par visite ;
- `port_annonce_observation.dart` : `prenomEnfant` et `PortAnnonceObservationEnfant` (RPC `annonce_observation_pour_moi`, migration `0040`) ;
- `accueil_famille_page.dart` : « Assister » -> `Routes.tcObservation(seanceId)` ; retrait de l'inscription préalable `assister_seance` ;
- `salle_page.dart`, `classe_live_page.dart`, `entete_classe.dart` : notice discrète pour l'enseignant (`annonces_observation`) et pour l'enfant concerné seulement ;
- `indicateur_observation.dart` (373 lignes changées) : indicateur agrégé ; `app_icons.dart` : `observationEnCours` (`0xe220`) ; i18n `tc.observation.annonce.tuteursObservent` ;
- tests : `accueil_famille_test`, `salle_test`, `teaching_core/e/*`, `teaching_core/g/*`, `q03_quota_observation_tuteur_test`.

Application contre l'index C0 (constaté, via `cmd /c`) : **OK pour 19 fichiers sur 20** ; seul `lib/core/i18n/strings.g.dart` échoue (en-tête généré « Strings: 1833 » sur la branche contre « 1902 » sur C0) : l'exclure et relancer `dart run slang`.

Cumul avec `33503fe` : fichiers communs `assets/i18n/fr.i18n.json` (hunks V0 aux lignes 27, 177, 1534 ; observation ligne 2012) et `strings_fr.g.dart` (V0 : 179, 613, 4939, 7299, 7437, 8675, sans variation nette de lignes ; observation : 6621, 8794). Aucun chevauchement de hunk ; l'application successive n'a **pas** été testée (elle exigerait d'écrire) : INCONNU, attendu sans conflit.

Dépendances backend de cette reprise (à documenter, pas à coder) :
- les RPC consommées (`entrer_observation`, `annonce_observation_pour_moi`, `annonces_observation`) existent en production (`0039`-`0042` identiques à la branche selon bilan C0 §5, lignes 125-128), mais **les fichiers `0039`-`0042` ne sont pas dans `main` ni dans C0** : le rejeu SQL de CI ne peut pas les couvrir ; les tests Flutter reposent sur des doubles ;
- voir §8.4 sur `0043` (jeton vidéo).

La compilation et les tests après reprise **n'ont pas été exécutés ici** (phase lecture) : statut « présent sur branche », « testé localement : INCONNU ». Le document de la branche (`docs/teaching-core/ETAT_OBSERVATION_2026-09-21.md`) prétend `dart analyze` propre et 337 fichiers sans violation au 21/09.

### 6.3 À ne pas récupérer

- **`core24/fable-frontend`, `integration/core24-*`, `astra/*`** : CORE24 déclaré non conforme (`CLAUDE.md` « État du code », `08` §3 et §5 bis). Ne pas copier non plus leurs idées de fichiers sous les mêmes chemins (§7-E).
- **`codex/r1`, `codex/r2`, `codex/vague5`, `codex/login-demo`, `codex/presence-correction-ui`** : base `cbc4ff8` du 13/09, 116 commits de retard ; r1/r2 réécrivent tout le thème avant la refonte actuelle ; login-demo réintroduit une connexion de démonstration.
- **`sauvegarde/r2-du-tiers`** (backend), **`teaching-core/0-coordinateur`**, **`specs`**, **`refactor-ui-lavender-*`**, **`nettoyage/base-2026-09-23`**.
- **Lecture seule utile** : `git show 196eb06:docs/architecture/CORE24_CLASSES_ARBITRATION_FINAL.md` (décisions Classes V2) et `git show 9a3ff0d:docs/produit/onboarding-questions-expliquees.md` (questionnaire). Ne pas les commiter dans la branche UI (docs = chantier C0).

---

## 7. Fichiers réservés (ne pas toucher dans la branche UI)

| Groupe | Chemins | Propriétaire / raison |
|---|---|---|
| A. Interdits du mandat | `supabase/**` (migrations, functions, tests, `CLAUDE.md`), `.github/workflows/**`, `vercel.json`, `.firebaserc`, `dart_define*.json`, tout secret | mandat §3 ; brief « Interdits absolus » |
| B. Chantier C0 (PR #2 ouverte, non fusionnée) | `CLAUDE.md`, `lib/CLAUDE.md`, `supabase/CLAUDE.md`, `docs/current/**` (dont `08`, `CONFIGURATION_BASELINE_2026-09-23.md`), `docs/archive/**`, `FABLE_*.md` racine | C0 / directeur ; toute mise à jour de `08` passe par le coordinateur avec accord |
| C. Observation (branche `observation/lot-2026-09-21`, worktree `D:\RA_OBS`) | `supabase/migrations/0039`-`0042` (et le fichier non suivi `0043_autoriser_jeton_video…` de `D:\RA_OBS`) : **jamais** ; les 20 fichiers `lib/ test/ assets/` du §6.2 : repris **une seule fois, en bloc, par le coordinateur**, puis confiés à l'agent C (Cours) | éviter une double écriture concurrente du même parcours |
| D. V0 (`33503fe`) | `lib/core/tc_groupe/port_groupes.dart`, `groupes_supabase.dart`, `lib/core/tc_horloge/port_horloge_seance.dart`, `horloge_supabase.dart`, `test/teaching_core/a/groupes_supabase_test.dart`, clés `salle.bandeauPermanent`, `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse` | repris en bloc par le coordinateur (§6.1) ; ensuite lecture seule pour les agents |
| E. CORE24 gelé : chemins créés par ces branches, à **ne pas créer** dans la branche UI (collision future) | `lib/features/classes/**`, `lib/features/tuteur_classes/classes_foyer_page.dart`, `lib/features/enseignant_classes/**`, `lib/features/admin_groupes/creation_classe_page.dart`, `lib/core/admin/service_classes_admin.dart`, `lib/core/interface_guidee/service_interface_guidee.dart`, `lib/core/planning/service_remplacement_session.dart`, `lib/features/tc_classe_live/{bibliotheque_en_classe,commandes_classe,entree_salle,etat_partage_classe,hote_dock_classe,support_coran_classe}.dart`, `lib/features/tc_mushaf/selection_verset.dart` | constaté `git diff --diff-filter=A main...<b> -- lib` |
| F. Points chauds partagés (coordinateur seul, mandat §10) | `lib/core/router/{app_router,routes,redirection}.dart`, `lib/core/widgets/nav_shell.dart`, `lib/core/theme/**`, `lib/core/icons/app_icons.dart`, `pubspec.yaml`, `assets/i18n/fr.i18n.json` + `lib/core/i18n/strings*.g.dart`, `lib/main.dart`/`lib/app.dart` | déjà touchés par 3 à 7 branches concurrentes (table ci-dessous) |
| G. Dossiers des autres worktrees | tout `D:\RA_*`, `D:\ra-pwa-*`, `…\WindowsTerminal\rewayah-*`, `.gemini\…` | aucune écriture, aucun retrait |

Chevauchements mesurés (`git diff --name-only main...<b>`) sur les fichiers qui intéressent le tuteur :

| Fichier | Branches non fusionnées qui le modifient |
|---|---|
| `lib/core/router/app_router.dart` | `core24/fable-frontend`, `integration/core24-classes-v2-remediation`, `astra/*`, `codex/vague5-integration` (+ `v0`/C0 : commentaires) |
| `assets/i18n/fr.i18n.json` | `observation`, `v0`, `core24/fable-frontend`, `integration/core24-*`, `astra/*`, `codex/vague5-integration`, `codex/login-demo` |
| `lib/features/accueil_famille/accueil_famille_page.dart` | `observation`, `core24/fable-frontend`, `astra/*` (+ C0 : commentaires) |
| `lib/features/salle/salle_page.dart` | `observation` (ajouts), `core24/fable-frontend` (**suppression**), `astra/*` |
| `lib/core/appairage/service_appairage.dart` | `integration/core24-classes-v2(-remediation)` |
| `lib/features/reglages_enfant/reglages_enfant_page.dart` | `integration/core24-classes-v2-remediation` (+ C0 : commentaire) |
| `lib/core/widgets/nav_shell.dart`, `lib/core/theme/*` | `codex/r2`, `codex/vague5` (anciens) |
| `lib/features/compte/compte_page.dart` | aucune branche commitée ; non commité dans `rewayah-prod-release` (archivé) |

---

## 8. Risques et pièges constatés

1. **Déploiement production involontaire.** `main:.github/workflows/flutter-deploy.yml:19-22` accepte `workflow_dispatch` et `:132-135` lance `vercel deploy --prod` sans condition de branche ; les secrets existent depuis le 24/09 (`08` §5 bis, dernière ligne). Toute branche distante qui ne contient pas `ab5f7f7` (c'est-à-dire **toutes sauf C0**, dont `v0/verite-produit`, `observation/*`, `core24/*`) serait déployée **en production** si quelqu'un lançait le workflow manuellement depuis elle. Idem `deploy.yml` (`c0:.github/workflows/deploy.yml:31-35`) : un tag `v*` poussé déploie les fonctions Edge. Aucun push, aucun tag, aucun lancement manuel dans ce chantier.
2. **Aperçu de la branche UI** : n'existe que par une PR vers `main` (C0 `flutter-deploy.yml:32-33`), ce qui suppose un **push**, interdit sans autorisation explicite du directeur.
3. **Protections locales inertes dans cet environnement.** `CLAUDE.md` (C0) dit les hooks de `.claude/settings.local.json` actifs. Le code : les deux blocs « force push » et le scanner de secrets ont `"matcher": "Bash"` (`settings.local.json:5,20`) alors que les agents de ce poste passent par l'outil **PowerShell** : ils ne se déclenchent pas. De plus `.claude/` n'est **pas suivi** (`?? .claude/`) : un nouveau worktree n'aura aucun hook. Ne pas compter sur eux.
4. **`0043` jeton vidéo.** Le fichier non suivi `D:\RA_OBS\supabase\migrations\0043_autoriser_jeton_video_verifie_le_bon_compte.sql:1-11` **prétend** que `0042` (appliquée en production) fait refuser **tout** jeton vidéo (`auth.uid()` nul sous `service_role`). Non vérifié ici. Si c'est vrai, ni `/salle` ni l'observation réelle ne peuvent fonctionner en production tant que le backend n'est pas corrigé : à inscrire comme **dépendance backend** du parcours Observation, sans rien toucher.
5. **Pipes PowerShell 5.1.** `git diff … | git apply` via un pipe PowerShell a échoué sur **tous** les fichiers (le texte du patch est réencodé ligne à ligne en CRLF) ; le même contrôle via `cmd /c` passe. Utiliser `cmd /c` ou un fichier patch écrit en octets bruts.
6. **Fichiers générés et fins de ligne.** Bilan C0 ligne CI : `core.autocrlf=true`, générateurs en LF ; `slang`/`build_runner` font apparaître `app_database.g.dart` et `strings_fr.g.dart` modifiés sans diff réel (`git diff --ignore-cr-at-eol -w` vide). Ne pas commiter un diff EOL seul.
7. **Ressources machine.** RAM libre mesurée 1,34 Go à 04:39 ; un `dart analyze` d'agent frère tournait déjà. Sérialiser les commandes Flutter.

---

## 9. Code contre docs : écarts relevés

| Ce que disent docs, commentaires ou mandat | Ce que fait le code / Git | Preuve |
|---|---|---|
| Mandat (partie observation §1) : « Jakarta est déjà déclarée dans les jetons » | 0 occurrence de `jakarta`, `DM Sans`, `DMSans` dans `lib/`, `assets/`, `pubspec.yaml` des **37 branches locales** (toutes les branches distantes ont leur copie locale au même SHA) ; familles déclarées sur `main` : `UthmanTahaNaskh`, `NotoSansArabic`, `InstrumentSans`, `BricolageGrotesque`, `Phosphor`, `PhosphorFill` | `git grep -i -E "jakarta\|dm ?sans\|DMSans" <toutes les branches> -- lib assets pubspec.yaml` ; `git show main:pubspec.yaml` |
| Mandat : « une visite et 120 s » obsolète, 2 / 120 / 240 | Serveur (fichier `0036` sur `main`) : 2 / 120 / 240 ; frontend C0 : encore 1 / 120 / null | `0036_…sql:17-19,191` ; `guardian_observation_policy.dart:78-80` |
| Bilan C0 §3.1 : worktree `D:\RA _APP\RA -OFFICIAL-APP` = `main` `4a7aa2b` | ce worktree est désormais sur C0 `3cf3544` | `git worktree list` |
| `CLAUDE.md` : hooks de protection actifs | hooks limités à l'outil `Bash`, dossier non suivi | §8.3 |
| Brief : « C0 = 9 commits docs + CI » | exact en nombre (+9/-0) ; contenu : docs, CI, **et** commentaires dans ~120 fichiers `lib/` et 14 migrations appliquées (aucune ligne de code ou de SQL) | §5.2 ; `08` §5 bis ligne « réécriture des liens » |
| `08` §5 : V0 et observation en attente de décision d'intégration | aucune des deux n'est dans `main` ni dans C0 | `git log c0..v0` = `33503fe` ; `git rev-list --count c0..observation` = 11 |
| Bilan C0 : PR #1 ouverte, PR #2 brouillon | références `refs/pull/1` et `refs/pull/2` présentes ; état ouvert/brouillon INCONNU ici | `git ls-remote origin "refs/pull/*"` |

---

## 10. Ce qui n'a pas été fait (limites)

- Aucune compilation, aucun test, aucune application réelle de patch (phase lecture) : la compatibilité de compilation des reprises §6 est **INCONNUE**, seule l'applicabilité textuelle est constatée.
- Aucune lecture de la base distante ni de GitHub API (MCP GitHub en échec de connexion) : l'état des PR et la réalité du défaut `0042`/`0043` restent INCONNUS.
- Aucun fichier du dépôt modifié ; seul ce rapport a été écrit, hors dépôt.
