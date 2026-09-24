# R3 - Worktrees, stashes et copies : travail non commité à risque de perte

Relevé en **lecture seule** le 24/09/2026 entre 15:40 et 16:25 (+03:00). Aucune écriture, aucun checkout, aucun commit, aucun stash, aucun worktree créé ou retiré, dans aucun dépôt. Précautions prises :
`git --no-optional-locks status` (pas de rafraîchissement de `.git/index`), `git hash-object` **sans** `-w` (aucun objet écrit), `git ls-remote` (lecture réseau, rien de local modifié). Seuls fichiers écrits : ce rapport et des fichiers de travail dans le scratchpad de la session (hors dépôts).
`D:\RA_TUTEUR\*` : **non lu** (chantier actif), seulement vu comme entrée de `git worktree list`.

Légende : **constaté** = commande rejouée ici ; **prétendu** = écrit dans un document, non revérifié ; **INCONNU**.

Méthode de preuve « contenu sauvegardé ou non » (constaté) :
1. `git rev-list --objects --branches --remotes --tags` du dépôt principal = 5 804 objets (291 commits). Un fichier non commité dont le blob (`git hash-object`) figure dans cet ensemble existe déjà **à l'identique** dans un commit d'une branche : pas de perte possible.
2. Sinon, comparaison **SHA-256 octet pour octet** avec la copie de `D:\RA _APP\_archive\2026-09-23_worktrees\<dossier>\<même chemin>`.
3. Ce qui échoue aux deux tests est **à risque**. Une égalité approchée (même idée, autre texte) n'est **pas** comptée comme sauvegarde.

---

## 1. Verdict

| # | Élément | Où | Commité ? | Archivé ? | Risque | Preuve |
|---|---|---|---|---|---|---|
| **1** | **2 commits `ca43141` + `79c0fad`** (branche `codex/audit-preproduction-20260915`) : audit préproduction du 15/09 (3 docs, 1 553 lignes) + validation de clé Supabase avec 2 tests absents de `main` | **uniquement** dans le clone autonome `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-release-20260915\.git` (worktree `...\rewayah-audit-20260915`) | oui, mais **ni dans le dépôt principal, ni sur GitHub** | **non** | **ÉLEVÉ** : le script en attente `A_VALIDER_retirer_worktrees.ps1:19-23` supprime ces deux dossiers par `Remove-Item -Recurse -Force` | §5.1 |
| **2** | `CORE24_CLASSES_COMPLIANCE_AUDIT.md` (336 lignes, 35 147 o, 22/09 21:35) : audit CORE24 « READY_FOR_INTEGRATION = NO » | worktree `...\WindowsTerminal\rewayah-classes-v2` (non suivi) | **non** (aucun blob, aucun chemin `*COMPLIANCE*` sur aucune branche) | **non** (absent du `JOURNAL_ARCHIVAGE.txt`, aucune autre copie sur `D:\RA _APP` ni `...\WindowsTerminal`) | **MOYEN** : perdu si ce worktree est un jour retiré ; il n'est pas dans la liste du script | §3.2 |
| 3 | `.claude/hooks/secret-scanner.py` (non suivi, 367 l.) et `.claude/settings.local.json` (ignoré) | checkout principal `D:\RA _APP\RA -OFFICIAL-APP` | non | non (`_archive\2026-09-23_instructions\.claude` ne contient que `agents/` et `commands/`) | faible : outillage local, aucun script ne vise ce checkout | §3.1 |
| 4 | Tout le reste du non commité (15 worktrees sales sur 32 examinés, 2 clones) | voir §2-§3 | contenu déjà dans un commit **ou** copie identique | voir §3 | **nul** (vérifié fichier par fichier) | §3, §6 |
| 5 | 3 stashes | dépôt principal | - | - | **nul** : aucun contenu qui ne soit déjà dans une branche | §4 |

Constat annexe : `A_VALIDER_retirer_worktrees.ps1` et `BRANCHES_A_VALIDER.md:57` affirment « le contenu unique est déjà dans ce dossier d'archive ». **Faux pour l'élément 1** (commits, non fichiers : l'archivage n'a copié que des fichiers non commités, `JOURNAL_ARCHIVAGE.txt:17-18`). **Ce script ne doit pas être lancé tel quel.**

---

## 2. Worktrees du dépôt principal (constaté)

Commande : `git -C "D:\RA _APP\RA -OFFICIAL-APP" worktree list --porcelain` : **34 entrées** (le checkout principal + 33 liés), dont 2 sous `D:\RA_TUTEUR\` non examinées. Puis, par worktree : `git --no-optional-locks -C <chemin> status --short` et `git log -1 --format="%H|%ci|%s"`.

| Chemin | Branche | HEAD | Date dernier commit | `status --short` | Verdict |
|---|---|---|---|---|---|
| `D:\RA _APP\RA -OFFICIAL-APP` | `c0/configuration-baseline-2026-09-23` | `5113656` | 2026-09-24 15:25 | `?? .claude/` | élément 3 ; voir aussi §7 (commit local non poussé) |
| `C:\Users\dell\.gemini\antigravity\worktrees\RA -OFFICIAL-APP\starlit-surge-glides-04h50` | `starlit-surge-glides-04h50` | `9d0229b` | 2026-09-16 06:25 | propre | - |
| `...\WindowsTerminal\rewayah-astra-core24` | `astra/core24-classes-legacy-snapshot` | `3e2b53c` | 2026-09-22 17:30 | 6 M, 3 ?? | archivé 6/6 (§3.3) |
| `...\WindowsTerminal\rewayah-classes-v2` | `integration/core24-classes-v2` | `e8beeb7` | 2026-09-22 21:05 | 3 M, 1 ?? | **élément 2** |
| `...\WindowsTerminal\rewayah-classes-v2-remediation` | `integration/core24-classes-v2-remediation` | `3c0cb1c` | 2026-09-23 02:10 | propre | - |
| `...\WindowsTerminal\rewayah-login` | `codex/login-demo` | `1110400` | 2026-09-15 01:04 | 4 M | sans risque (blobs dans les refs) |
| `...\WindowsTerminal\rewayah-presence-ui` | `codex/presence-correction-ui` | `d55606c` | 2026-09-15 00:02 | 3 M | générés seulement |
| `...\WindowsTerminal\rewayah-prod-release` | `codex/production-google-auth-20260916` | `b02ea98` | 2026-09-15 04:07 | 15 M, 1 ?? | archivé 16/16 (§3.4) |
| `...\WindowsTerminal\rewayah-r1` | `codex/r1-adaptive-design-system` | `405683a` | 2026-09-13 22:12 | propre | - |
| `...\WindowsTerminal\rewayah-r2` | `codex/r2-adaptive-shell` | `65c564f` | 2026-09-14 22:39 | 21 M, 5 ?? | archivé 23/23 (§3.5) |
| `...\WindowsTerminal\rewayah-review-20260915` | `codex/review-visible-20260915` | `b02ea98` | 2026-09-15 04:07 | propre | - |
| `...\WindowsTerminal\rewayah-vague5-integration` | `codex/vague5-integration` | `f8a6988` | 2026-09-15 00:50 | propre | - |
| `C:\Users\dell\AppData\Local\Temp\claude\...\93b5f5ca-...\scratchpad\baseline` | (détaché) | `e104605` | 2026-09-18 16:01 | 3 M | générés seulement ; HEAD ancêtre de `main` |
| `D:\ra-pwa-build` | (détaché) | `e76a14e` | 2026-09-12 17:46 | 62 M, 26 ?? (fichiers) | sans risque : 85/85 blobs dans les refs **et** archivés |
| `D:\ra-pwa-ctr` | (détaché) | `f1855de` | 2026-09-13 01:38 | 59 M, 14 ?? (fichiers) | archivé 70/70 (§3.6) |
| `D:\ra-pwa-deploy-20260918` | (détaché) | `99c7b6a` | 2026-09-16 06:33 | 10 M | sans risque : 7/7 blobs dans les refs et archivés |
| `D:\ra-pwa-fix` | (détaché) | `090ae6f` | 2026-09-13 09:53 | 3 M | générés seulement |
| `D:\ra-pwa-secure-deploy` | (détaché) | `cbc4ff8` | 2026-09-13 17:10 | 4 M, 1 ?? | archivé 2/2 (§3.7) |
| `D:\RA_CORE24\fable` | `core24/fable-frontend` | `50fae3c` | 2026-09-22 04:45 | propre | - |
| `D:\RA_OBS` | `observation/lot-2026-09-21` | `0bfc9e4` | 2026-09-21 16:00 | 3 M, 1 ?? | `0043` archivé identique (§3.8) |
| `D:\RA_ONBOARD` | `lot/onboarding-offres` | `9a3ff0d` | 2026-09-22 14:50 | 3 M, 1 ?? | archivé identique (§3.9) |
| `D:\RA_TC\0` | `teaching-core/0-coordinateur` | `6081601` | 2026-09-20 16:17 | propre | - |
| `D:\RA_TC\a` à `h`, `q` (9) | `teaching-core/{a-group-space, b-library, c-quran, d-teaching-tools, e-classroom, f-realtime, g-observation, h-academic, q-qa}` | `28c2238`, `d5bc5bf`, `e60c5b4`, `bc40b4a`, `4e65e50`, `bf01953`, `3545f8c`, `a9b295b`, `8337531` | 2026-09-20 06:50 à 15:57 | propres | - |
| `D:\RA_TC\z` | `integration/teaching-core` | `d5eb74c` | 2026-09-21 01:43 | propre | - |
| `D:\RA_TUTEUR\integration`, `D:\RA_TUTEUR\p0d` | `ui/tuteur-v1`, `ui/tuteur-v1-p0d` | `f075a7e`, `bb7f094` (au moment du `worktree list`) | - | **non examiné** (hors périmètre) | - |

Bilan : 32 worktrees examinés, **17 propres, 15 sales**.

Worktrees détachés : les 6 HEAD (`e104605`, `e76a14e`, `f1855de`, `99c7b6a`, `090ae6f`, `cbc4ff8`) sont tous ancêtres de `main` (`git merge-base --is-ancestor <sha> main` = vrai, constaté) : retirer ces worktrees ne perdrait aucun commit.

Fichiers `windows/flutter/generated_plugin*` : 48 occurrences modifiées (14 worktrees ci-dessus + les 2 dossiers du clone §5.1). Pour **48/48**, le contenu du fichier (`hash-object`, filtré ou brut) est un blob déjà commité : artefacts de `flutter pub get` / fins de ligne, **aucun travail**.

Fichiers ignorés non standard (`git status --ignored`, hors `build/`, `.dart_tool/`, éphémères) : seulement `dart_define.json` (checkout principal, starlit, ra-pwa-build, ra-pwa-ctr, ra-pwa-fix, ra-pwa-secure-deploy, clone release), `.claude/settings.local.json` et, dans `D:\ra-pwa-build`, `android/.kotlin/`, `android/gradlew*`, `gradle-wrapper.jar`. `dart_define.json` n'a **pas été lu** (secrets).

---

## 3. Contenu du travail non commité (hors fichiers générés)

Colonne « refs » : le blob du fichier existe-t-il dans un commit d'une branche ? Colonne « archive » : copie SHA-256 identique dans `D:\RA _APP\_archive\2026-09-23_worktrees\<dossier>` ?

### 3.1 Checkout principal
- `?? .claude/hooks/secret-scanner.py` (367 l., 19/09 19:50) : hook Python « Detects hardcoded secrets before git commits ». refs : **non** ; archive : **non**.
- `!! .claude/settings.local.json` (ignoré, 1 273 o, 19/09 19:50) : non commité, non archivé.
- Nature : configuration d'agent locale, pas du code de l'application.

### 3.2 `rewayah-classes-v2` : **élément 2, non sauvegardé**
- `?? CORE24_CLASSES_COMPLIANCE_AUDIT.md` (336 l., 22/09 21:35). Titre ligne 1 « CORE24 Classes V2 - audit forensique de conformité » ; ligne 9 « Verdict : READY_FOR_INTEGRATION = NO » ; sections 1-9 (matrices, manques critiques, « Rapport 8923564 vs réalité », plan de patch non implémenté).
- refs : **non** (`git log --branches --remotes -- "*COMPLIANCE*"` vide). archive : **non** (le journal n'a aucune ligne `classes-v2`). Aucune autre copie trouvée (`Get-ChildItem -Recurse -Filter *COMPLIANCE_AUDIT*` sur `D:\RA _APP`, `...\WindowsTerminal`, `D:\RA_CORE24`, `D:\RA_ONBOARD`, `D:\RA_OBS`).
- Ce document est la **preuve citée** du verdict « CORE24 non conforme » : le rapport commité `integration/core24-classes-v2-remediation:CORE24_CLASSES_REMEDIATION_REPORT.md:12` renvoie à ce chemin local exact.

### 3.3 `rewayah-astra-core24` (22/09 08:43-14:05)
- `M .github/workflows/ci.yml` (+4), `M supabase/tests/scenarios_n2.sql` (+20), `M ASTRA_24H_CHANGELOG_V2.md` (+39/-3), `?? ASTRA_24H_BLOCKERS_V2.md` (23 l.), `?? ASTRA_24H_SCHEMA_IMPACT_V2.md` (22 l.), `?? ASTRA_24H_TEST_REPORT_V2.md` (47 l.).
- refs : non pour les 6 ; archive `astra-core24` : **6/6 identiques**.
- Nature : rapports et ajustements CORE24 (« Astra Core24 V2 - coordination et blocages », « impact schéma local »). CORE24 est gelé (non conforme).

### 3.4 `rewayah-prod-release` (16/09 00:12-00:31)
- 12 fichiers suivis modifiés + `?? test/config/supabase_key_validation_test.dart`. Hors refs : `fr.i18n.json` (-7), `service_auth.dart` (+2/-18), `env.dart` (+66/-8), `strings.g.dart`, `strings_fr.g.dart` (+2/-30), `session_controleur.dart` (+1/-65), `connexion_page.dart` (+33/-148), `connexion_test.dart` (+30/-193), `harnais.dart` (+16/-26). Dans les refs : `dart_define.example.json`, `compte_page.dart`, `strings_ar.g.dart`, le test non suivi.
- Nature (constaté par `git diff HEAD`) : **retrait de la connexion de démonstration par mot de passe** (`connexionMotDePasse`, `ouvrirDemo`, `fermerDemo`, `demoAuthActiveProvider`, clés i18n `introDemo`, `demoTitre`, `motDePasse`…) et validation de la clé Supabase dans `env.dart`.
- archive `codex-prod-release` : **16/16 identiques** (journal ligne 32 le prétend, confirmé).

### 3.5 `rewayah-r2` (14/09 01:01-05:47)
- Hors refs : `fr.i18n.json` (+138/-2), `docs/HANDOFF.md` (+21), `docs/PROGRESS.md` (+21), `docs/design/08-catalogue-ecrans.md` (+149), `lib/app.dart` (+7/-7), `strings.g.dart`, `strings_fr.g.dart` (+555/-2), `app_router.dart` (+37/-3), `redirection.dart` (+10/-1), `tableau_de_bord_page.dart` (+10), `?? lib/core/preferences/preferences_locales.dart` (114 l., « choix local du thème »).
- Déjà dans un commit : `routes.dart`, `nav_shell.dart`, `setting_row.dart`, `planning_page.dart`, `reglages_enfant_page.dart`, 2 tests routeur, et les non suivis `lib/features/compte/compte_page.dart` (752 l.), `compte_galerie.dart`, `compte_galerie_test.dart`, `compte_test.dart`.
- Nature : écran Compte, préférences locales de thème, câblage routeur. archive `codex-r2` : **23/23 identiques**.

### 3.6 `D:\ra-pwa-ctr` (12-13/09)
- 70 fichiers : archive **70/70 identiques**. Trois seulement sont hors refs : `pubspec.yaml` (+7 : bloc `hooks: user_defines: sqlite3: … winsqlite3`, absent de `main:pubspec.yaml`), une variante de `supabase/migrations/0012_observation_controleur.sql` (451 l. : ajoute `begin;`/`commit;`, alors que la version commitée du même fichier retire ces lignes), une variante d'une ligne de `test/coran/vue_lecteur_test.dart`.

### 3.7 `D:\ra-pwa-secure-deploy` (14/09 05:16)
- `M lib/core/config/env.dart` (+67/-3, blob `58a2b944`, **même contenu** que `env.dart` de `rewayah-prod-release`) : hors refs, archivé identique. `?? test/config/supabase_key_validation_test.dart` : dans les refs.
- Remarque : la fonction qu'il apporte (`cleSupabaseValide`, `_urlSupabaseValide`, `_estPlaceholder`) existe déjà sur `main:lib/core/config/env.dart:65-119` sous une forme équivalente (texte accentué différent) : `git grep` constaté.

### 3.8 `D:\RA_OBS`
- `?? supabase/migrations/0043_autoriser_jeton_video_verifie_le_bon_compte.sql` (157 l., 21/09 16:47). Ligne 1 : « CORRECTIF D'URGENCE de 0042 », qui **prétend** que `0042` (appliquée en production selon le bilan C0) refuse tout jeton vidéo. refs : non ; archive `RA_OBS` : **identique**. Non appliquée à la base : INCONNU ici (aucune lecture distante).

### 3.9 `D:\RA_ONBOARD`
- `?? CORE24_CLASSES_ARBITRATION_FINAL.md` (526 l., 22/09 15:41). refs : non ; la version commitée `196eb06:docs/architecture/CORE24_CLASSES_ARBITRATION_FINAL.md` fait **368 l.** : c'est une version **différente** (plus longue). archive `RA_ONBOARD` : **identique**.

### 3.10 Sans aucun contenu propre
- `rewayah-login` : `strings_ar.g.dart` (blob `8a4f701c` dans les refs) ; `D:\ra-pwa-build` : 85 fichiers, **tous** dans les refs (lots N2-N5 commités depuis) ; `D:\ra-pwa-deploy-20260918` : 7 fichiers, tous dans les refs ; `presence-ui`, `baseline`, `ra-pwa-fix` : générés seulement.

---

## 4. Stashes (constaté)

Commande : `git -C "D:\RA _APP\RA -OFFICIAL-APP" stash list`, puis `git stash show --stat` et `--include-untracked`, `git diff-tree` base→stash et base→index, recherche de chaque blob dans les refs.

| Stash | Commit, date | Message | Base | Contenu | Déjà ailleurs ? | Risque |
|---|---|---|---|---|---|---|
| `stash@{0}` | `6bcc6d3`, 13/09 22:12 | « On codex/r1-adaptive-design-system: codex: generated Windows EOL-only » | `e42fe6e` (version amendée de « feat(ui): add adaptive R1 design system », joignable **seulement** via ce stash) | **vide** : `git diff-tree -r stash@{0}^1 stash@{0}` et `…^2` ne renvoient rien | les 30 blobs modifiés par `e42fe6e` sont tous présents dans les refs | nul |
| `stash@{1}` | `59288bb`, 12/09 17:49 | « copies de travail ADM-04, deja commitees sur main » | `1eddc9c` (sur `main`) | 11 fichiers, +647/-9 | 10/11 blobs sur `main` (6 introduits par `61a0ba8` « Lot N3 », 4 par `99c7b6a`) ; le 11e, `pubspec.yaml`, ajoute `livekit_client: ^2.12.0` (présent `main:pubspec.yaml:55`) + une ligne vide | nul |
| `stash@{2}` | `424aaa6`, 12/09 00:43 | « etat worktree avant rattrapage 5b8b868 » | `df96c6a` (sur `main`) | 9 fichiers, +186/-33 ; 3e parent (non suivis) = arbre **vide** | 9/9 blobs sur `main` (`1c60089`, `cb3a220`, `0071557`, `049d0ca`, `8f10686`) | nul |

Le message de `stash@{1}` (« déjà commitées ») est donc **exact**. Autres dépôts : le clone `rewayah-release-20260915` n'a **aucun** stash (`git stash list` vide) ; le clone `rewayah-review-all-20260915` n'a aucun commit.

---

## 5. Copies du projet hors worktrees

Recherche : `pubspec.yaml` contenant `name: rewayah_academy`, profondeur 3 maximum, sur `D:\` (tous les dossiers de premier niveau sauf `D:\RA_TUTEUR`, `$RECYCLE.BIN`, `System Volume Information`) et `C:\Users\dell\AppData\Local\Programs\WindowsTerminal`. **33 trouvés** : 30 sont les worktrees du §2, **3 sont hors du dépôt principal** :

### 5.1 Clone autonome `...\WindowsTerminal\rewayah-release-20260915` et son worktree `...\rewayah-audit-20260915` : **élément 1**

- `rewayah-release-20260915\.git` est un **répertoire** (clone indépendant), `origin` = `D:\RA _APP\RA -OFFICIAL-APP` (chemin local). Branche courante `codex/release-all-20260915` @ `b02ea98` (15/09 04:07). `status` : `strings_ar.g.dart` (blob dans les refs) + 3 générés.
- `rewayah-audit-20260915\.git` est un **fichier** `gitdir: …/rewayah-release-20260915/.git/worktrees/rewayah-audit-20260915` : worktree **du clone**, pas du dépôt principal. Branche `codex/audit-preproduction-20260915` @ `79c0fad` (15/09 22:41). `status` : 3 générés.
- `git -C <clone> rev-list --all` : 102 commits, dont **2 absents du dépôt principal** (`git -C "D:\RA _APP\RA -OFFICIAL-APP" cat-file -e <sha>` échoue) :

| Commit | Date | Message | Fichiers |
|---|---|---|---|
| `ca43141fc3bdd2e0843cf778c7442510eca9b465` (parent `b02ea98`) | 15/09 17:57 | fix: recover Supabase client configuration validation | `lib/core/config/env.dart` (+70/-3), `test/config/supabase_key_validation_test.dart` (+66) |
| `79c0fad8dc49bfd7fb97a32bb8fd85813ec700c9` (parent `ca43141`) | 15/09 22:41 | docs: publish preproduction audit evidence | `docs/audit-preproduction/INVENTAIRE.md` (697 l.), `RAPPORT.md` (797 l.), `VALIDATION.md` (59 l.) |

- Absents de GitHub : `git ls-remote origin` (dépôt `rewayahacademy-glitch/Rewayah-Academy-Official-App`) = 29 références, aucune ne contient « audit » ni ces SHA.
- Absents de l'archive : `JOURNAL_ARCHIVAGE.txt:18` « clone-audit-20260915 : 0 fichier(s) archive(s) » ; aucun `INVENTAIRE.md`, `RAPPORT.md`, `VALIDATION.md` ni dossier `audit-preproduction` sous `D:\RA _APP\_archive`. Les 5 blobs de ces commits sont absents de la base d'objets du dépôt principal.
- Ce qui serait perdu :
  - **l'audit préproduction du 15/09 en entier** (1 553 lignes) ;
  - dans le test, **2 cas absents de `main`** (diff constaté contre `main:test/config/supabase_key_validation_test.dart`, blob `a1f58a9c`, 28 lignes non vides) : « refuse une clé serveur et un JWT sans claims anon Supabase » (`service_role`, `iss` étranger, `sb_secret_…`) et « refuse les espaces et les segments JSON invalides sans lever ». La logique de `env.dart` existe déjà sur `main` (§3.7).
- **Danger** : `D:\RA _APP\_archive\2026-09-23_worktrees\A_VALIDER_retirer_worktrees.ps1:19-23` :
  `$dossiers = @("$wt\rewayah-release-20260915", "$wt\rewayah-audit-20260915", "$wt\rewayah-review-all-20260915", "D:\RA_TC", "$repo\build")` puis `Remove-Item -LiteralPath $p -Recurse -Force`. Script **non exécuté** à ce jour (les dossiers existent), mais présenté comme sûr par `BRANCHES_A_VALIDER.md:57`.

### 5.2 `...\WindowsTerminal\rewayah-review-all-20260915`
- `.git` = répertoire, **aucun commit** (`fatal: your current branch 'master' does not have any commits yet`) : tout est non suivi.
- 361 fichiers non suivis et non ignorés (`git ls-files --others --exclude-standard`) : **361/361** blobs présents dans les refs du dépôt principal. Rien d'unique dans le code.
- Ignorés, non lus : `dart_define.json`, `.vercel/`, `build/`, `.flutter-plugins-dependencies`, fichiers générés iOS/Android.

### 5.3 Dossiers vérifiés sans copie de code
- `D:\rewayah-app` : seulement `.claude\` et `CLAUDE.md` (05/09), pas de `pubspec.yaml`.
- `D:\RA_REVUE_TMP` : vide. `D:\a` : `_temp` seulement. `D:\RA_CORE24` : seulement le worktree `fable`.
- `D:\RA_TC` (racine, hors worktrees) : 6 fichiers `.md`/`.log` + `shared\` (8 `.md`) : **14/14 identiques** dans `_archive\…\RA_TC-racine`.
- `...\WindowsTerminal\supabase\.temp\` : cache de la CLI Supabase (`linked-project.json`, `cli-latest`), pas du code.

---

## 6. Contrôle de l'archive du 23/09 (`D:\RA _APP\_archive\2026-09-23_worktrees\`)

Les comptes de `JOURNAL_ARCHIVAGE.txt` sont **confirmés** fichier par fichier (SHA-256) : astra-core24 6, codex-login 1, codex-prod-release 16, codex-r2 23, ra-pwa-build 85, ra-pwa-ctr 70, ra-pwa-deploy-20260918 7, ra-pwa-secure-deploy 2, RA_OBS 1, RA_ONBOARD 1, clone-release 1, RA_TC racine 14 (les générés Windows non archivés sont déjà dans les refs, §2).
Limites de l'archive : **copie unique**, hors Git, sur le même disque `D:` que la plupart des worktrees ; elle ne contient **pas** `rewayah-classes-v2`, **ni** les commits propres au clone (§5.1).

---

## 7. Pour mémoire : commits présents seulement sur ce poste (non poussés)

Hors périmètre strict (ce sont des commits, pas du non commité), mais c'est aussi du travail sans deuxième copie. `git ls-remote --heads origin` comparé aux branches locales, commits comptés par `git rev-list --count <branche> --not <toutes les pointes distantes>` :

| Branche locale | Commits absents de GitHub |
|---|---|
| `c0/configuration-baseline-2026-09-23` | **1** : `5113656` (24/09 15:25, « docs(08): constats de securite releves par l inventaire Tuteur V1 », +1 ligne dans `docs/current/08_…`) ; distant = `3cf3544`. Le BRIEF (ligne 6) dit « NE RIEN y committer » dans ce checkout : auteur de l'action et accord **INCONNUS** ici |
| `integration/core24-classes-v2-remediation` | 14 |
| `integration/core24-classes-v2` | 9 |
| `astra/core24-classes-legacy-snapshot` / `astra/core24-presence-safeguard` / `astra/core24-v2` | 7 / 6 / 5 |
| `codex/vague5-integration` | 7 |
| `codex/r2-adaptive-shell` | 4 |
| `codex/login-demo`, `codex/presence-correction-ui`, `docs/core24-classes-arbitration`, `sauvegarde/r2-du-tiers` | 1 chacune |
| `ui/tuteur-v1`, `ui/tuteur-v1-p0d` | absentes de GitHub (chantier actif, non examiné) |
| `codex/audit-preproduction-20260915` (dans le **clone**, pas ici) | 2 (§5.1) |

---

## 8. Actions proposées (NON exécutées, chacune soumise à l'accord explicite du directeur)

1. **Ne pas lancer `A_VALIDER_retirer_worktrees.ps1` tel quel.** Au minimum, retirer `rewayah-release-20260915` et `rewayah-audit-20260915` de la liste (lignes 19-20) tant que les 2 commits ne sont pas rapatriés.
2. Rapatrier les 2 commits dans le dépôt principal sous une branche de sauvegarde, par exemple :
   `git -C "D:\RA _APP\RA -OFFICIAL-APP" fetch "C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-release-20260915" codex/audit-preproduction-20260915:sauvegarde/audit-preproduction-20260915`
   (écrit des objets et une branche locale : commande d'écriture, donc à valider ; ne pousse rien).
3. Copier `rewayah-classes-v2\CORE24_CLASSES_COMPLIANCE_AUDIT.md` dans `_archive\2026-09-23_worktrees\classes-v2\` (ou le commiter sur `integration/core24-classes-v2`) avant tout retrait de ce worktree.
4. Si le directeur veut garder les hooks locaux : copier `.claude\hooks\secret-scanner.py` et `.claude\settings.local.json` dans `_archive\2026-09-23_instructions\.claude\`.
5. Les stashes peuvent être supprimés sans perte (§4), après accord (`08` §3).

---

## 9. Limites de ce relevé

- `D:\RA_TUTEUR\*` non lu ; ses deux branches ne sont évoquées que par les références du dépôt principal.
- `dart_define.json` et autres fichiers ignorés contenant des secrets : non lus.
- Recherche de copies limitée à `D:\` et `...\WindowsTerminal`, profondeur 3 : `C:\Users\dell\.gemini\` (hors worktree déclaré), OneDrive et le reste de `C:` **non parcourus**.
- Test d'égalité strict (blob ou SHA-256) : un fichier « hors refs » peut avoir un équivalent reformulé ailleurs ; seuls les cas signalés ont été comparés à la main (`env.dart`, test de clé, `pubspec.yaml` de `stash@{1}`).
- Aucune lecture de la base distante : la réalité de l'incident décrit par `0043` reste INCONNUE.
- Les états datent de 15:40-16:25 ; un agent actif peut les avoir changés depuis (le HEAD de `ui/tuteur-v1` a bougé pendant le relevé : `f075a7e` puis `436c290`).
