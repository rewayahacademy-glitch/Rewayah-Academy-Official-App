# R2 - Registre des branches : ce qui existe hors de `main`, et ce qui est déjà dans `ui/tuteur-v1`

Relevé en **lecture seule** le 24/09/2026 entre 15:24 et 16:01 (+03:00), dépôt `D:\RA _APP\RA -OFFICIAL-APP`.
Aucun checkout, commit, stash, fetch, worktree créé ou retiré. Commandes utilisées : `git branch -a`, `for-each-ref`, `rev-list --count`, `merge-base`, `log main..<b>`, `cherry -v`, `diff --numstat/--name-status main...<b>`, `ls-tree -r`, `show`, `grep` sur des révisions. Scripts de mesure (lecture seule) dans le dossier scratchpad de la session : `r2_stats.ps1`, `r2_cmp2.ps1`, `r2_lines.ps1`, `r2_lines_tot.ps1`.

Légende : **constaté** = commande rejouée ici ; **prétendu** = écrit dans un commit ou une doc, non revérifié ; **INCONNU** = pas pu vérifier.

---

## 0. Trois faits à connaître avant de lire

1. **La branche `ui/tuteur-v1` a bougé pendant la mesure.** Mesures faites sur `db52be5` (15:07:59). À 16:01 elle est à `f075a7e` (+3 commits : `66cbfe1`, `adf2b3c`, `f075a7e`, routeur, compte, coquille). Ces 3 commits touchent 11 fichiers (`app_router.dart`, `redirection.dart`, `nav_shell.dart`, `compte_page.dart`, `preferences_page.dart` + tests) et **aucun** fichier de V0, d'observation ou de CORE24 (`git diff --name-only db52be5 f075a7e`, constaté) : les conclusions ci-dessous restent valables.
2. **Un commit a été ajouté sur la branche C0 du checkout principal pendant la mesure** : `5113656` à 15:25:37, « docs(08): constats de securite releves par l inventaire Tuteur V1 (non executes, aucun correctif) », 1 ligne dans `docs/current/08_…` (`git reflog show c0/configuration-baseline-2026-09-23`, `git show --stat 5113656`, constaté). Il n'est **pas poussé** (`origin/c0/…` = `3cf3544`) et n'est **pas** dans `ui/tuteur-v1` (`merge-base --is-ancestor 5113656 ui/tuteur-v1` = 1). Ce n'est pas moi : je n'ai rien écrit dans le dépôt. Le BRIEF (ligne 6) interdit de committer dans ce checkout ; à signaler au coordinateur.
3. **État distant = références locales de suivi**, dernier `fetch` le 23/09 à 17:52 (date de `.git/FETCH_HEAD`). Un `git ls-remote` de contrôle n'a pas répondu en 60 s (arrêté) : l'état distant **en direct** est INCONNU ici. C10 (§4.1) l'avait relevé par `ls-remote` à 04:27 le même jour : tous les SHA distants égaux aux locaux.

---

## 1. Synthèse

| Question | Réponse | Preuve |
|---|---|---|
| Combien de branches ? | 40 locales, 24 distantes (+ `origin/HEAD`) | `git for-each-ref refs/heads refs/remotes` |
| Distantes différentes de leur copie locale | **1 seule** : `c0/…` (local `5113656`, distant `3cf3544`) | comparaison `refs/remotes/origin/*` vs `refs/heads/*` |
| Branches entièrement dans `main` (0 commit absent) | 16 : `main`, `admin-complet`, `codex/production-google-auth-20260916`, `codex/release-all-20260915`, `codex/review-visible-20260915`, `integration/teaching-core`, `starlit-surge-glides-04h50`, `teaching-core/{a,b,c,d,e,f,g,h,q}` | `rev-list --count main..<b>` = 0 |
| Branches dont le contenu est dans `main` par recopie (SHA différents, lignes présentes) | 3 : `codex/presence-correction-ui` (498/498 lignes ajoutées présentes dans `main`), `sauvegarde/r2-du-tiers` (3772/3772), `codex/r1-adaptive-design-system` (945/948) | `r2_lines_tot.ps1` (§2) |
| Contenu unique **front** encore utile | `v0/verite-produit` (`33503fe`) et `observation/lot-2026-09-21` : **repris** dans `ui/tuteur-v1` (commits `b6df316` et `0401086`), avec deux réserves (§4.1, §4.2) | §4 |
| Contenu unique **backend** hors CORE24 | `observation/lot-2026-09-21` : migrations `0039`-`0042`, **absentes de `main`, de C0 et de `ui/tuteur-v1`** (volontaire : backend interdit au chantier) | `cmp_observation…tsv` : `NON_REPRIS(ui=main)` × 4 |
| CORE24 | 6 branches (`core24/fable-frontend`, `integration/core24-classes-v2`, `integration/core24-classes-v2-remediation`, `astra/core24-v2`, `astra/core24-presence-safeguard`, `astra/core24-classes-legacy-snapshot`) + 1 branche de docs (`docs/core24-classes-arbitration`). **Déclaré non conforme** (`docs/current/08…:27` « CORE24 non conforme et bloqué par une gate PostgreSQL » ; `08…:7` et `:90` « CORE24 reste suspendu » ; BRIEF:19 « ne jamais intégrer »). **Rien de CORE24 n'est dans `ui/tuteur-v1`** : aucun chemin créé par CORE24 n'y existe, 97 % des lignes ajoutées par `core24/fable-frontend` y sont absentes (9410/9677) | §4.4 |
| Seulement docs | `lot/onboarding-offres`, `docs/core24-classes-arbitration`, `teaching-core/0-coordinateur`, `specs` (sans ancêtre commun) | §3 |
| `ui/tuteur-v1` publiée ? | **Non.** Aucune référence `origin/ui/*` ; un push depuis ce dépôt ou l'un de ses worktrees (qui partagent les références) l'aurait créée. Donc **rien de `ui/tuteur-v1` ne peut être visible dans une app déployée** depuis Git | `for-each-ref refs/remotes` |

**Deux points qui répondent directement à l'inquiétude du directeur (fonction « faite » mais invisible) :**
- L'observation tuteur est **dans le code** de `ui/tuteur-v1` mais **fermée hors développement** par le commit `db52be5` : `lib/core/config/env.dart:76-79` (`demandee && environnement == 'developpement'`), lu par `lib/features/accueil_famille/accueil_famille_page.dart:356-360`. Une compilation de production ou d'aperçu **n'affiche pas** « Assister ». C'est voulu (dépendances serveur DB-OBS-01..05 citées `env.dart:48-50`), mais il faut le dire ainsi : « présent dans le code, désactivé », pas « fait ».
- Les trois libellés V0 qui cessaient d'affirmer un enregistrement **n'ont pas été repris** (`b6df316`, message : « aucun libelle d'enregistrement repris (valeurs de 3cf3544 conservees) »). `ui/tuteur-v1` affiche toujours « Cours enregistré, visite de contrôle possible. » (`assets/i18n/fr.i18n.json:136` sur `f075a7e`), anomalie que `08…:5` qualifie de « bloquante pour l'accueil de vrais élèves ».

---

## 2. Méthode et règles de classement

- **Commits absents de `main`** : `git log main..<b>` et `git rev-list --count` dans les deux sens.
- **Fichiers touchés** : `git diff --numstat --no-renames main...<b>` (depuis la base commune). Catégories : **docs** = tout `*.md` et tout `docs/**` (y compris `lib/CLAUDE.md`, `supabase/CLAUDE.md`) ; **front** = `lib/`, `test/`, `assets/` hors `.md` ; **backend** = `supabase/` hors `.md` ; **CI** = `.github/`, `vercel.json`, `.firebaserc` ; **autre** = `pubspec.yaml`, `tool/`, `android/`, `ios/`, `dart_define.example.json`, `slang.yaml`.
  Les gros volumes « docs » de C0 (±36 000 lignes) sont surtout des **déplacements** vers `docs/archive/` comptés en ajout + retrait (`--no-renames`).
- **Déjà dans `main` ou déjà dans `ui/tuteur-v1`** : pour chaque fichier, comparaison des blobs (`ls-tree -r`) entre la branche, `main`, la base commune et `ui/tuteur-v1@db52be5`. Statuts : `DEJA_DANS_MAIN` (même contenu que `main`), `REPRIS_IDENTIQUE` (ui = branche), `NON_REPRIS(ui=main)`, `DIFFERENT` (ui ≠ branche et ≠ `main`).
  Quand un fichier est `DIFFERENT`, second contrôle **ligne à ligne** : chaque ligne ajoutée par la branche (diff `main...<b>`, lignes de plus de 3 caractères) est-elle présente dans le fichier cible ? C'est une heuristique (elle ne vérifie pas l'ordre ni le contexte), suffisante pour dire « repris » ou « absent », pas pour prouver une équivalence de comportement.
- `git cherry -v main <b>` marque `+` **tous** les commits de toutes les branches non fusionnées (aucun équivalent de patch dans `main`) ; la recopie de `codex/*` et de `sauvegarde/r2-du-tiers` dans `main` s'est faite sous d'autres patchs, d'où le contrôle ligne à ligne.

---

## 3. Toutes les branches

Format des colonnes de fichiers : `n (+ajouts/-retraits)` sur `main...<b>`. « Distant » = une référence `origin/<même nom>` existe (au dernier fetch).

| Branche | HEAD | Distant | Absents de `main` / retard | Base commune | Front | Backend | Docs | CI | Autre | Classement |
|---|---|---|---|---|---|---|---|---|---|---|
| `main` | `4a7aa2b` | = | 0 / 0 | - | - | - | - | - | - | référence (= production selon `CLAUDE.md`) |
| `admin-complet` | `b19c8d3` | = | 0 / 89 | `b19c8d3` | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** |
| `codex/production-google-auth-20260916` | `b02ea98` | non | 0 / 110 | `b02ea98` | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** |
| `codex/release-all-20260915` | `b02ea98` | = | 0 / 110 | `b02ea98` | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** (fusionné par `3ac457b`) |
| `codex/review-visible-20260915` | `b02ea98` | non | 0 / 110 | `b02ea98` | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** |
| `integration/teaching-core` | `d5eb74c` | = | 0 / 18 | `d5eb74c` | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** |
| `starlit-surge-glides-04h50` | `9d0229b` | = | 0 / 106 | `9d0229b` | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** |
| `teaching-core/{a-group-space,b-library,c-quran,d-teaching-tools,e-classroom,f-realtime,g-observation,h-academic,q-qa}` | `28c2238`, `d5bc5bf`, `e60c5b4`, `bc40b4a`, `4e65e50`, `bf01953`, `3545f8c`, `a9b295b`, `8337531` | = (les 9) | 0 / 75 à 77 | elles-mêmes | 0 | 0 | 0 | 0 | 0 | **entièrement dans main** |
| `codex/presence-correction-ui` | `d55606c` | non | 1 / 116 | `cbc4ff8` | 3 (+679/-0) | 0 | 1 (+19/-0) | 0 | 0 | front, **déjà dans main par recopie** (3 fichiers `DEJA_DANS_MAIN`, 498/498 lignes) |
| `codex/r1-adaptive-design-system` | `405683a` | = | 1 / 116 | `cbc4ff8` | 29 (+1140/-2132) | 0 | 1 (+105/-0) | 0 | 0 | front, **déjà dans main par recopie** (945/948 lignes) |
| `codex/r2-adaptive-shell` | `65c564f` | non | 4 / 116 | `cbc4ff8` | 34 (+2058/-2262) | 0 | 3 (+113/-7) | 0 | 0 | front, **remplacé dans main** (§4.3) |
| `codex/vague5-integration` | `f8a6988` | non | 7 / 116 | `cbc4ff8` | 41 (+2897/-2266) | 0 | 6 (+187/-7) | 0 | 0 | front, **remplacé dans main** (§4.3) |
| `codex/login-demo` | `1110400` | non | 1 / 116 | `cbc4ff8` | 9 (+299/-36) | 0 | 0 | 0 | 1 (+3/-1) | front, **remplacé dans main** (§4.3) |
| `sauvegarde/r2-du-tiers` | `201b521` | non | 1 / 8 | `08d8edb` | 0 | 17 (+4057/-1) | 2 (+692/-0) | 1 (+88/-0) | 0 | backend, **déjà dans main par recopie** (3772/3772 lignes ; `main` porte `5a78726`, même message) |
| `v0/verite-produit` | `33503fe` | = | 2 / 0 | `4a7aa2b` | 118 (+622/-199) | 14 (+17/-17) | 195 (+36465/-36152) | 2 (+4/-11) | 4 (+11/-11) | **contenu unique front** (`33503fe`, 7 fichiers) ; le reste = `4e9903c`, déjà dans C0 et `ui` (§4.1) |
| `nettoyage/base-2026-09-23` | `2a8b847` | = | 3 / 0 | `4a7aa2b` | 118 (+622/-199) | 14 (+17/-17) | 198 (+36740/-36305) | 2 (+4/-11) | 4 (+11/-11) | = `4e9903c` + `33503fe` + `2a8b847` (docs C0 v1, remplacés par C0) ; aucun contenu propre |
| `observation/lot-2026-09-21` | `0bfc9e4` | = | 11 / 1 | `ae61eb6` | 20 (+1124/-181) | 4 (+1652/-0) | 2 (+268/-84) | 0 | 0 | **contenu unique front + backend** (§4.2) |
| `c0/configuration-baseline-2026-09-23` | local `5113656` / distant `3cf3544` | **différent** | 10 / 0 (distant : 9) | `4a7aa2b` | 113 (+175/-175) | 14 (+17/-17) | 198 (+36804/-36305) | 3 (+94/-29) | 4 (+11/-11) | **docs + CI** ; front et backend = commentaires seulement (§4.7) |
| `ui/tuteur-v1` | `db52be5` puis `f075a7e` | **non** | 36 puis 39 / 0 | `4a7aa2b` (C0 `3cf3544` ancêtre) | 260 (+19294/-1603) | 14 (+17/-17) | 199 (+36869/-36305) | 3 (+94/-29) | 7 (+190/-50) | **branche cible**, front unique, local seulement (§4.7) |
| `ui/tuteur-v1-p0d` | `bb7f094` | non | 16 / 0 | `4a7aa2b` | 158 (+5697/-228) | 14 (+17/-17) | 198 (+36803/-36305) | 3 (+94/-29) | 4 (+11/-11) | **entièrement dans `ui/tuteur-v1`** (`merge-base --is-ancestor` = 0, `rev-list ui/tuteur-v1..ui/tuteur-v1-p0d` = 0) |
| `lot/onboarding-offres` | `9a3ff0d` | = | 1 / 0 | `4a7aa2b` | 0 | 0 | 3 (+70/-9) | 0 | 0 | **seulement docs** (§4.5) |
| `docs/core24-classes-arbitration` | `196eb06` | non | 2 / 0 | `4a7aa2b` | 0 | 0 | 4 (+438/-9) | 0 | 0 | **seulement docs**, famille CORE24 (§4.4) |
| `teaching-core/0-coordinateur` | `6081601` | = | 2 / 78 | `0071557` | 0 | 0 | 10 (+5396/-0) | 0 | 0 | **seulement docs** (§4.5) |
| `specs` | `8a652d6` | = | 1 / 193 | **aucune** | - | - | 11 fichiers `.md` (+2150) | - | - | **seulement docs**, historique séparé (§4.6) |
| `refactor-ui-lavender-3628477128789856989` | `ed431ac` | = | 3 / 193 | **aucune** | voir §4.6 | | | | | prototype Jules sans ancêtre commun (§4.6) |
| `core24/fable-frontend` | `50fae3c` | = | 2 / 1 | `ae61eb6` | 79 (+12678/-5438) | 0 | 8 (+919/-0) | 0 | 0 | **CORE24, NON CONFORME** - front unique |
| `integration/core24-classes-v2` | `e8beeb7` | non | 10 / 0 | `4a7aa2b` | 40 (+6800/-278) | 16 (+3424/-11) | 5 (+540/-9) | 1 (+14/-5) | 0 | **CORE24, NON CONFORME** - front + backend |
| `integration/core24-classes-v2-remediation` | `3c0cb1c` | non | 15 / 0 | `4a7aa2b` | 40 (+6800/-278) | 18 (+3867/-11) | 6 (+754/-9) | 1 (+14/-5) | 0 | **CORE24, NON CONFORME** - front + backend |
| `astra/core24-v2` | `ce7e7e7` | non | 17 / 1 | `ae61eb6` | 63 (+10326/-817) | 10 (+2049/-0) | 6 (+953/-84) | 0 | 0 | **CORE24, NON CONFORME** - front + backend (contient l'observation) |
| `astra/core24-presence-safeguard` | `730b7b7` | non | 18 / 1 | `ae61eb6` | 63 (+10326/-817) | 15 (+2671/-11) | 6 (+953/-84) | 1 (+14/-5) | 0 | **CORE24, NON CONFORME** |
| `astra/core24-classes-legacy-snapshot` | `3e2b53c` | non | 19 / 1 | `ae61eb6` | 70 (+10534/-826) | 15 (+2733/-11) | 6 (+953/-84) | 1 (+14/-5) | 0 | **CORE24, NON CONFORME** |

Les 24 branches distantes ont toutes une copie locale de même nom ; le tableau vaut pour elles (seule `c0/…` diffère, voir §0).

**Branches qui n'existent que sur ce poste** (aucune référence `origin/<nom>`) : `astra/core24-v2`, `astra/core24-presence-safeguard`, `astra/core24-classes-legacy-snapshot`, `codex/login-demo`, `codex/presence-correction-ui`, `codex/production-google-auth-20260916`, `codex/r2-adaptive-shell`, `codex/review-visible-20260915`, `codex/vague5-integration`, `docs/core24-classes-arbitration`, `integration/core24-classes-v2`, `integration/core24-classes-v2-remediation`, `sauvegarde/r2-du-tiers`, **`ui/tuteur-v1`**, `ui/tuteur-v1-p0d`. Une perte du disque D: ou du dossier `.git` ferait disparaître `ui/tuteur-v1` (39 commits).

Hors branches (non analysés ici) : 3 stashes (`git stash list`), déjà décrits par C10 §4.4.

---

## 4. Détail des branches à contenu unique

### 4.1 `v0/verite-produit` (`33503fe`) : repris dans `ui/tuteur-v1`, **sauf les libellés d'enregistrement**

Fonction apportée (message de `33503fe` et `git show`) : en production, les groupes du tuteur viennent de la base (`GroupesSupabase`, vue `mes_groupes_famille_v`) et l'horloge de séance vient du serveur (`HorlogeSeanceSupabase`) ; les doubles de démonstration ne servent que sous `PLAYGROUND`. Trois libellés cessent d'affirmer un enregistrement audio.

Sur `main`, le tuteur voit encore des groupes inventés : `main:lib/core/tc_groupe/port_groupes.dart:38` `(Ref ref) => GroupesDemonstrationLocale()` (constaté).

| Fichier de `33503fe` | Dans `ui/tuteur-v1` | Preuve |
|---|---|---|
| `lib/core/tc_groupe/groupes_supabase.dart` | identique | blob `23851ec1` sur `33503fe`, `b6df316` et `db52be5` |
| `lib/core/tc_groupe/port_groupes.dart` | identique | blob `45fe1b94` ; `db52be5:…/port_groupes.dart:39-48` `portGroupesSelon(demo: Env.playgroundActif)` |
| `lib/core/tc_horloge/port_horloge_seance.dart` | identique | blob `499c07c5` ; `:53` `portHorlogeSelon` |
| `lib/core/tc_horloge/horloge_supabase.dart` | repris **et modifié** : noms de jours et de mois tirés de `t.commun.dates` au lieu de listes en dur sans accents | `git diff 33503fe db52be5 -- …/horloge_supabase.dart` |
| `test/teaching_core/a/groupes_supabase_test.dart` | repris et complété (+12 lignes) | `git diff --stat 33503fe db52be5` |
| `assets/i18n/fr.i18n.json`, `strings_fr.g.dart` : `salle.bandeauPermanent`, `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse` | **NON repris** : `ui` garde « Cours enregistré, visite de contrôle possible. » (`fr.i18n.json:136`), « Chaque cours est enregistré en audio, conservé trente jours… » (`:289`), « Enregistrement audio et visite de contrôle » (`:1694`) | `git show f075a7e:assets/i18n/fr.i18n.json` ; message de `b6df316` |

Statut : **présent dans le code de `ui/tuteur-v1`** (commit `b6df316`, 24/09 14:45) ; testé : INCONNU ici (aucun test lancé) ; déployé : **non** (branche non poussée). Les parties docs de `33503fe` (`CLAUDE.md`, `docs/current/08`, `09`) ne sont pas reprises, C0 porte ses propres versions (C10 §6.1).

`nettoyage/base-2026-09-23` n'apporte rien de plus : `4e9903c` est ancêtre de `ui/tuteur-v1` (`merge-base --is-ancestor` = 0) et les fichiers de `2a8b847` existent dans C0, 5 identiques et 3 en version plus récente (`CLAUDE.md`, `08`, `CONFIGURATION_BASELINE`).

### 4.2 `observation/lot-2026-09-21` : front repris **mais désactivé**, backend absent partout

Fonction apportée (messages de `e8cd50e`, `513efd4`, `0b5bfdb`, `8615138`, `3d377fe`, `546aca0`, `0bfc9e4`) : l'annonce d'observation du tuteur arrive à l'enseignant ; l'administration règle l'observation par groupe ; le tuteur n'apparaît plus dans la galerie et seul son enfant est prévenu ; la salle se ferme si la visite finit pendant la connexion ; le jeton vidéo répond à la visite en cours ; `etat_presence` fermée à `anon`, jeton vidéo vérifiant le compte.

| Partie | Fichiers | Dans `ui/tuteur-v1` | Preuve |
|---|---|---|---|
| Front | 20 (`lib/` 10, `test/` 9, `assets/` 1) | **20/20 repris** : 12 identiques, 8 retouchés ensuite ; ligne à ligne, toutes les lignes ajoutées par la branche sont présentes sauf l'en-tête généré de `strings.g.dart` et une ligne de test (`find.byKey(IndicateurObservation.cleBandePrenoms)`) réécrite par `db52be5` | `cmp_observation__lot-2026-09-21.tsv` ; `r2_lines.ps1 -range main...observation/lot-2026-09-21 -target db52be5` |
| Porte d'activation | - | **fermée hors développement** depuis `db52be5` (24/09 15:07) : `env.dart:76-79`, `activation_observation.dart:15-16`, `accueil_famille_page.dart:356-360`, `entree_observation_page.dart:142` | `git grep observationTuteurReelle db52be5` |
| Backend | `supabase/migrations/0039`-`0042` (+1652 lignes) | **absent** (ui = `main`), ni dans C0 | `NON_REPRIS(ui=main)` × 4 |
| Docs | `docs/teaching-core/ETAT_OBSERVATION_2026-09-21.md` (ajout), `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md` (suppression) | non repris | idem |

Le bilan C0 dit `0039`-`0042` **appliquées en production** : **prétendu**, non vérifié ici (aucun accès à la base). Si c'est vrai, la production porte des migrations dont les fichiers ne sont ni dans `main` ni dans C0 : le rejeu SQL de CI ne peut pas les couvrir.

### 4.3 Branches `codex/*` du 13-15/09 : remplacées dans `main`, rien à reprendre

Les cinq branches partent de `cbc4ff8` (13/09) et ont 116 commits de retard. `main` contient la fusion `3ac457b` (16/09) « consolidate codex production and vague 5 features into main branch », qui apporte `b02ea98`, lui-même porteur de `4cb8735` « add local email password login trial » et `cb3a220` « integrate finalized Vague 5 Rewayah work » (`git log cbc4ff8..b02ea98`). Mesure ligne à ligne contre `main` :

| Branche | Fonction (message) | Lignes ajoutées présentes dans `main` | Ce qui reste propre à la branche | Dans `ui/tuteur-v1` |
|---|---|---|---|---|
| `codex/presence-correction-ui` | surface de correction de présence (propriétaire) | 498/498 | rien | - |
| `codex/r1-adaptive-design-system` | système de design adaptatif R1 | 945/948 | `app_gabarit.dart` `seuilLarge = 1200`, `AppInkColorSource` dans `app_theme.dart` | non (thème réécrit par `a119036`, `fce058b`) |
| `codex/r2-adaptive-shell` | R1 + coque de navigation adaptative + profil enseignant en lecture seule | 1442/1610 | une **autre version** de `profil_enseignant_page.dart` (69/148 lignes absentes) et de son test ; `main` a sa propre page, issue de `0071557` (ENS-01 à ENS-08, 20/09) | non (ui = `main` pour ce fichier) |
| `codex/vague5-integration` | r1 + r2 + présence + route et libellés du profil enseignant | 1977/2231 | idem r2 + 22 clés i18n `enseignant.profil.*` de cette version | non |
| `codex/login-demo` | connexion e-mail + mot de passe pour essais locaux | 117/231 | une autre rédaction de `connexion_page.dart` et du drapeau ; **la fonction existe déjà dans `main`** : `main:lib/core/config/env.dart:39` `authParMotDePasseActive`, `main:lib/core/auth/service_auth.dart:56` `signInWithPassword` | fonction présente via `main` (mêmes lignes dans `db52be5`) |

Classement : front, **aucun contenu fonctionnel manquant dans `main`** ; les écarts restants sont des variantes antérieures remplacées.

### 4.4 CORE24 - **déclaré non conforme par le directeur**, rien n'est dans `ui/tuteur-v1`

Sources : `docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md:27` (« CORE24 non conforme et bloqué par une gate PostgreSQL »), `:7` et `:90` (« V0, V1 et CORE24 restent suspendus »), `docs/current/04_EXECUTION_GIT_CI_ET_MIGRATION.md:5` (« Ne jamais le fusionner sur la foi d'un nombre de fichiers présents »), BRIEF:19 (« ne jamais intégrer »). Décrit ici pour l'inventaire uniquement.

| Branche | Fonctions annoncées (messages de commit, **prétendu**) | Backend | Dans `ui/tuteur-v1` |
|---|---|---|---|
| `core24/fable-frontend` | `ae59cd7` : module `lib/features/classes` (ClasseVM, ports, adaptateurs sur `groupes_admin`, `creer_groupe`…), Admin « Classes » réécrit, `CreationClassePage` en trois pas, KYC V2 (exigence et état séparés, dispense), `/enseignant/classes`, porte photo. `50fae3c` : `/salle` rendue par `ClasseLivePage`, **suppression de `SallePage` (1421 lignes) et de `salle_enseignant/*`**, transport de données LiveKit, `SupportCoranClasse`, sélection de verset, dock, bibliothèque | aucun | **non** : 9410/9677 lignes ajoutées absentes ; 62 fichiers `NON_REPRIS(ui=main)` ; aucun chemin créé par la branche n'existe dans `ui` ; `ui` garde `salle_page.dart` |
| `integration/core24-classes-v2` | `86e588f` présence académique signée ; `f483425` dispatch transactionnel de groupe ; `e005729` choix d'offre répétés ; `3793c8e` cycle de vie des groupes brouillons ; `dcafddf` onboarding + interface guidée ; `8f819d0` admin enseignant et remplacement | 7 migrations `20260921000000`…`20260923000500_core24_*`, 6 scénarios SQL, `_shared/livekit.ts`, `livekit-webhook` | **non** : 16 fichiers backend et 32 front `NON_REPRIS(ui=main)` |
| `integration/core24-classes-v2-remediation` | ci-dessus + `53eb702` « reconcile data model and security », `20260923000600_core24_lot_a_contracts.sql`, `stub_storage.sql`, 3 commits de docs « gate blocker » | 8 migrations `core24`, 6 scénarios + `stub_storage.sql` | **non** : 4686/5101 lignes front absentes |
| `astra/core24-v2` | fusion de l'observation (`0bfc9e4`), de `ae59cd7` et `ae61eb6` ; `fccbbeb` KYC et préconditions Live ; `a376c80` RPC de Classe ambiguës | `0039`-`0042` + `20260921000100_core24_rpc_groupes_uniques`, `20260921000200_core24_conformite`, `create-room-token` | **non** pour CORE24 ; les 12 fichiers `REPRIS_IDENTIQUE` sont ceux de l'observation, venus par `0401086`, pas par CORE24 |
| `astra/core24-presence-safeguard` | + `730b7b7` présence académique signée (LiveKit) | + `20260922000100_core24_presence_academique`, `livekit-webhook` | **non** |
| `astra/core24-classes-legacy-snapshot` | + `3e2b53c` « snapshot legacy classes work » | idem | **non** : 6983/8041 lignes absentes (les présentes sont celles de l'observation) |
| `docs/core24-classes-arbitration` | `196eb06` : `docs/architecture/CORE24_CLASSES_ARBITRATION_FINAL.md` (+ `9a3ff0d`, voir §4.5) | - | **non** (fichier absent de `ui` et de `main`) ; lecture seule utile selon C10 §6.3 |

Contrôle de collision : sur les fichiers **créés** (`A`) par chaque branche CORE24 (49, 39, 42, 46, 49, 51 et 1), **aucun** n'existe dans `ui/tuteur-v1@db52be5` (`cmp_<branche>.tsv`, statut `A` toujours `NON_REPRIS`).

### 4.5 Seulement docs

| Branche | Contenu | Dans `ui/tuteur-v1` / `docs/current` |
|---|---|---|
| `lot/onboarding-offres` (`9a3ff0d`) | Décision académie du 22/09 : **cinq niveaux** de badge (Certifié Rewayah, Bronze, Argent, Or, Platine) ; `student_profiles.level` réservé au niveau académique d'un élève, jamais au grade d'un enseignant ; corrections de `docs/produit/badges-et-grades.md`, `onboarding-questions-expliquees.md`, `FABLE_ONBOARDING_CLASSES_REPORT.md` | **non** : les versions archivées dans `ui` (`docs/archive/2026-09-pre-remise-a-plat/produit/…`) sont celles de `main` (blobs `d3be6111`, `9f3abd83`) ; 49/50 et 7/7 lignes absentes ; `docs/current` ne cite la décision que comme « note badges » (`CONFIGURATION_BASELINE_2026-09-23.md:62`) |
| `teaching-core/0-coordinateur` (`eb967f3`, `6081601`) | 10 documents normatifs du Teaching Core (baseline, contrats, décisions, fichiers protégés, rapport pré-fusion) | **non** (absents de `main` et de `ui`, y compris sous `docs/archive`) |
| `docs/core24-classes-arbitration` | voir §4.4 | non |
| `specs` (`8a652d6`) | 11 fichiers `.md` « 10 documents de specification MVP0 pour Google Jules » (09/09), historique **sans ancêtre commun** avec `main` (racines `8a652d6` et `2d871da`) | non ; périmés selon C10 §4.3 |

### 4.6 `refactor-ui-lavender-3628477128789856989`

Historique séparé (racine `8a652d6` = `specs`). `0936f03` (09/09, 285 fichiers : `lib/` 100, `test/` 31, `supabase/` 16, plateformes) est un projet Flutter entier ; `ed431ac` (auteur `google-labs-jules[bot]`) est un **commit vide** (`git show --shortstat ed431ac` sans changement). `git diff --shortstat main ed431ac` : 647 fichiers, +4264/-182366. Aucun fichier de `lib/` de cette branche ne contient « lavande/lavender » ; les trois mentions « lavande doux » de `ui/tuteur-v1` (`app_palette.dart:258`, `app_theme.dart:99`, `action_principale.dart:17,225`) viennent de son propre commit `a119036` (`git log -S "lavande doux"`), pas de cette branche. Rien à reprendre ; PR #1 selon C10.

### 4.7 C0, `ui/tuteur-v1`, `ui/tuteur-v1-p0d`

- **C0 (`3cf3544`)** : 9 commits docs + CI. Les 350 lignes changées dans `lib/ test/ assets/ supabase/` (hors `CLAUDE.md`) sont des commentaires, sauf 3 retraits de BOM (`import 'teacher_student_projection.dart'`, `import 'dart:async'`, `import 'package:flutter/widgets.dart'`) et une chaîne de message de test (`test/icons/app_icons_rtl_test.dart:54`, chemin de doc) : `git diff -U0 main...3cf3544` filtré, 8 lignes non commentaires sur 350. `3cf3544` est ancêtre de `ui/tuteur-v1` ; `5113656` (local, non poussé) ne l'est pas.
- **`ui/tuteur-v1`** : 39 commits au-dessus de `main` à 16:01 (C0 ×9, contrats K1-K7, thème, coquille, routeur, reprises `b6df316` et `0401086`, porte `db52be5`, 3 correctifs). Frontière backend respectée : `git diff --stat 3cf3544...ui/tuteur-v1 -- supabase .github vercel.json .firebaserc dart_define.example.json` **vide** (constaté à 16:01). Hors `lib/ test/ assets/` elle touche `pubspec.yaml`, `pubspec.lock`, `tool/verifier_jetons.dart`, `android/…/AndroidManifest.xml`, `ios/Runner/Info.plist` (caméra, `f1bd506`).
- **`ui/tuteur-v1-p0d`** : entièrement contenue dans `ui/tuteur-v1`.

---

## 5. Ce qui existe ailleurs et **n'est pas** dans `ui/tuteur-v1`

| Élément | Où | Pourquoi absent | À décider par |
|---|---|---|---|
| Libellés V0 « le cours n'est pas enregistré » (3 clés) | `33503fe` | choix explicite de `b6df316` | directeur (anomalie bloquante selon `08…:5`) |
| Migrations d'observation `0039`-`0042` | `observation/lot-2026-09-21`, `astra/*` | backend interdit au chantier | directeur + lot backend ; production : INCONNU ici |
| Observation tuteur **active** | code présent, porte fermée par `db52be5` | dépendances serveur DB-OBS-01..05 | directeur |
| Décision badges (5 niveaux, `level` réservé aux élèves) | `9a3ff0d` | docs hors chantier UI | coordinateur (docs C0) |
| Docs Teaching Core, arbitrage CORE24, état observation | `teaching-core/0-coordinateur`, `196eb06`, `observation` | docs, lecture seule | - |
| Tout CORE24 (classes, KYC V2, salle unique, dispatch, remplacement…) | 6 branches CORE24 | **non conforme** | directeur ; ne pas intégrer |

Rien d'autre : les branches `codex/*` et `sauvegarde/r2-du-tiers` n'ont pas de fonction absente de `main`, et `main` est ancêtre de `ui/tuteur-v1`.

---

## 6. Limites

- Aucun test, aucune compilation : « repris » veut dire **présent dans le code** de la branche, pas « fonctionne ».
- Ce qui est **réellement déployé** n'a pas été vérifié (ni Vercel ni base). `08…:27` rapporte que « les huit derniers déploiements Vercel production seraient lancés via CLI, sans preuve de déploiement lié au Git » : la production peut ne pas être égale à `main`. INCONNU ici.
- État distant en direct INCONNU (`ls-remote` sans réponse) ; références au dernier fetch du 23/09 17:52.
- Le contrôle ligne à ligne est une heuristique (présence de lignes, pas d'ordre ni de comportement).
- Mesures sur `ui/tuteur-v1@db52be5`, branche active modifiée pendant le relevé (§0).
