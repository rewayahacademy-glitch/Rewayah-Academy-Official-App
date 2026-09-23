# Rewayah - bilan de la gate C0 (configuration de départ)

Date : 23 septembre 2026. Agent : Claude Code. Branche de la PR C0 : `c0/configuration-baseline-2026-09-23`
(documentation `4e9903c` + ce lot C0, sans V0). Le commit V0 `33503fe` est conservé sur la branche distincte
`v0/verite-produit` (poussée), ni fusionnée ni déployée. La branche `nettoyage/base-2026-09-23` (`2a8b847`,
mélange docs + V0 + C0) reste en place jusqu'à décision ; elle n'est pas la branche de PR.
Statut de la gate : **BLOCKED** (voir la colonne Décision). Aucune cellule PASS sans preuve reproductible.
Aucun secret n'est recopié ici. Aucune donnée distante n'a été modifiée pendant cette mission.

## 1. Tableau C0

| Point | Statut | Preuve vérifiable | Décision | Responsable | Prochaine action |
|---|---|---|---|---|---|
| Base Git : inventaire | PASS | `git worktree list` (31 worktrees), `git for-each-ref` (35 locales, 22 distantes), `git stash list` (3), `git merge-base` par branche ; tableau complet dans `D:\RA _APP\_archive\2026-09-23_worktrees\BRANCHES_A_VALIDER.md` et §3 ci-dessous. `origin/main` = `4a7aa2b`. Branche documentaire `4e9903c` puis `33503fe`. CORE24 : `integration/core24-classes-v2` = `e8beeb7` (audit NON CONFORME), `integration/core24-classes-v2-remediation` = `3c0cb1c` (gate A `BLOCKED_INFRA`). PR ouvertes : INCONNU (voir ligne GitHub). | Aucun travail orphelin perdu : les fichiers modifiés ou non suivis de tous les worktrees candidats au retrait sont copiés dans `_archive/2026-09-23_worktrees/` (489 fichiers, `JOURNAL_ARCHIVAGE.txt`). | Claude Code | Aucune suppression ; liste cible par cible en §3 à valider une par une. |
| Instructions et mémoire | PASS | `CLAUDE.md` racine = index vers `00`, `08` v2, `09`, ce bilan ; `lib/CLAUDE.md` et `supabase/CLAUDE.md` réécrits ; `docs/archive/README.md` classe l'historique ; `05_PROMPT_AGENT_INTEGRATEUR.md` archivé sous `docs/archive/.../racine/`. Mémoire agent : `MEMORY.md` réécrit, 122 mémoires déplacées sous `memory/archive/`, aucune ne relance l'ancien prompt. Empreintes SHA-256 du lot C0 vérifiées conformes au `C0_MANIFEST.json` avant remplacement. | Seules règles actives : `docs/current/` + `CLAUDE.md`. | Claude Code | Relecture par le directeur du diff `4e9903c..HEAD`. |
| Documents : specs canoniques sans doublon | PASS (dépôt) / BLOCKED (fusion) | `docs/current/` : `00`–`04`, `06`–`09`, ce bilan. Anciens docs sous `docs/archive/2026-09-pre-remise-a-plat/` par `git mv` (89 renommages, historique conservé) ; 135 fichiers de code ont leurs liens de commentaire réécrits. `dart analyze --fatal-infos` : 0 problème ; `dart run tool/verifier_jetons.dart` : 344 fichiers, 0 violation ; `flutter test` : 1 770 verts. | Fusion dans `main` NON faite : pas d'outil PR sur ce poste (ni `gh`, ni MCP GitHub, ni jeton), et pousser `main` déclenche un déploiement production. | Directeur | Ouvrir la PR `nettoyage/base-2026-09-23 -> main` sur GitHub, laisser `ci.yml` tourner (il ne tourne que sur `pull_request`), fusionner. **Écart à trancher avant fusion** : le commit `33503fe` (V0) a été livré avant réception de la version 2 de `08` qui gèle V0 ; le conserver ou le reverter (`git revert 33503fe`) est une décision de direction. |
| Supabase : migrations appliquées | PASS (inventaire) | `list_migrations` sur `gggmtelinlpseweouyav` (lecture seule) : 0001–0005 en versions courtes, puis versions horodatées `20260912…` à `20260921133843` couvrant `0006`–`0042` (dont `0038` avant `0034`). **Non appliquée : `0043_offres_horaires_et_intentions`** (présente sur `main`). **Appliquées mais absentes de `main` : `0039`–`0042`** (sur `observation/lot-2026-09-21` et `astra/*`). Branches CORE24 : 7 à 8 migrations en nomenclature horodatée `20260921000000_core24_*` … `20260923000600_*`, incompatible avec la numérotation `00xx`. | **Réconciliation en lecture seule faite** (§5) : le texte des migrations appliquées en production est conservé dans `supabase_migrations.schema_migrations.statements` ; comparé aux fichiers Git après la même normalisation (commentaires `--` et blancs retirés), **`0039`–`0042` en production sont identiques, caractère pour caractère, aux fichiers de `observation/lot-2026-09-21`**. 33 des 37 migrations horodatées correspondent exactement à un fichier Git ; les 4 autres s'expliquent (§5). Collision `0043` : `0043_offres_horaires` (main, non appliquée) et `0043_autoriser_jeton_video_verifie_le_bon_compte` (correctif de `0042`, jamais commité, archivé hors dépôt). Conformément à la consigne : **ni `0043` ni `0044` ne sont lancées ni créées** tant que l'ordre d'intégration n'est pas décidé ; aucune migration renommée. | Directeur pour l'ordre d'intégration | Décider l'intégration de `observation/lot-2026-09-21` dans `main` (merge, pas ff : `main` a avancé de `4a7aa2b`), puis seulement le sort des deux `0043`. |
| Supabase : rejeu sur Postgres neuf | BLOCKED_INFRA | Script `rejouer_migrations.ps1` (conteneur jetable `postgres:17-alpine`, `stub_auth.sql` + `stub_storage.sql` de la branche de remédiation + 42 migrations + 12 scénarios, comme `ci.yml`). Docker Desktop 29.7.2 relancé (moteur prêt après 20 s), puis le moteur a cessé de répondre : `docker ps` bloque au delà de 60 s, comme l'avait consigné le rapport CORE24 du 23/09. Résultat du rejeu : non obtenu dans cette session. Constat de lecture : `ci.yml` sur `main` ne charge pas `stub_storage.sql`, or `0030_tc_socle.sql:209` référence `storage.buckets` ; sur un Postgres nu, le rejeu de `main` échoue donc à `0030` (constat de la remédiation, non reproduit ici). | Le stub est un artefact de test (`TEST_ONLY`), pas une migration. À versionner sur `main` avec l'appel dans `ci.yml`. | Opérateur (poste Docker stable ou runner CI) ; Claude Code pour le stub | Rejouer sur un Postgres neuf (CI `pull_request` ou poste stable) et consigner PASS ou la première erreur exacte. |
| Git -> Vercel | BLOCKED (accès) | Projet Vercel `rewayah-academy` (`prj_xDldWMLNH726BpwEVUlIAJUOSzPe`, équipe `team_VfPE1KP6vCKUyTeeG6AtAV8B`) : **aucun dépôt Git lié**, `framework: null`, domaines `rewayah-academy.vercel.app`. `vercel.json` : `git.deploymentEnabled: false` (voulu, ADR de `fdf5168`). Chaîne prévue : `push main -> flutter-deploy.yml -> vercel deploy --prod` (CLI depuis le runner, donc `meta: {}` attendu). Horodatages : commit `ae61eb6` 2026-09-21 06:14 UTC ; dernier déploiement production `dpl_69MAn4kGe7Bf5698qbRaWPxp2sng` 2026-09-21 06:16 UTC ; fonctions Edge `piece-identite-*` et `archive-seance-acces` créées 06:25 UTC. Commit `4a7aa2b` 2026-09-22 06:02 UTC : **aucun déploiement production postérieur**. Lecture des variables d'environnement Vercel : refusée (403, `projectEnvVars`). Runs GitHub Actions : illisibles (pas de jeton). | Le push de `ae61eb6` a très probablement été déployé automatiquement (2 min d'écart) ; le push de `4a7aa2b` ne l'a **pas** été. La cause exacte (workflow non déclenché, garde amont sur un secret, échec de build ou de la garde aval) n'est pas établie. La CLI manuelle ne satisfait pas la gate. | Directeur (accès GitHub Actions et Vercel) | Fournir le journal du run `Flutter Web → Vercel` pour `4a7aa2b` ; ou donner un jeton GitHub lecture Actions à l'agent. |
| Environnements et secrets | INCONNU (présence) | Carte des noms attendus (§2). Vérifiés présents : URL Supabase `https://gggmtelinlpseweouyav.supabase.co` ; 10 fonctions Edge déployées dont `r2-selftest` (v49, **absente du dépôt**) ; `livekit-webhook` seule avec `verify_jwt: false` (conforme). Non vérifiables depuis ce poste : secrets GitHub (8 noms), secrets Supabase des fonctions (8 noms + 4 groupes R2 à 4 variables chacun), variables Vercel (403), statut LiveKit Cloud ou auto-hébergé (les deux jeux de clés sont prévus dans `_shared/livekit.ts`). Aucun environnement `staging` n'existe dans le dépôt (`ENVIRONNEMENT` vaut `developpement` ou `production`). | Tant que la présence de chaque secret n'est pas attestée par son détenteur, la ligne reste INCONNU. | Directeur / opérateur des consoles GitHub, Supabase, Cloudflare, LiveKit, Vercel | Cocher §2 nom par nom depuis les consoles, sans valeurs. Décider du sort de `r2-selftest` (retirer ou versionner). |
| Nettoyage Git : classement | PASS (classement) / suppressions reportées | §3 : chaque worktree, clone, branche et stash classé avec SHA, données uniques et restauration. Le retrait effectif a été refusé par le classificateur de sécurité de l'outil et n'a pas été retenté. | Aucune suppression irréversible avant validation cible par cible. | Directeur | Valider ou refuser chaque ligne de §3. |
| Bilan unique | PASS | Ce fichier, dans le même commit que la mise à jour de `08` §5. | | Claude Code | Tenir à jour à chaque point clos. |

## 2. Carte des environnements et des secrets (noms seulement)

| Système | Environnement | Nom attendu | Où il est requis | Présence | Détenteur |
|---|---|---|---|---|---|
| GitHub Actions | production | `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, `VERCEL_TOKEN` | `flutter-deploy.yml` (garde amont) | INCONNU | Directeur (Settings > Secrets) |
| GitHub Actions | production | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `flutter-deploy.yml` (compilées dans le bundle web) | INCONNU | Directeur |
| GitHub Actions | production | `SENTRY_DSN_FLUTTER` | `flutter-deploy.yml` (optionnel) | INCONNU | Directeur |
| GitHub Actions | production | `SUPABASE_ACCESS_TOKEN` | `deploy.yml` (fonctions Edge) | Probablement présent (fonctions déployées le 21/09 06:25 UTC) | Directeur |
| GitHub Actions | manuel | `SUPABASE_DB_URL` | `deploy.yml` job migrations (déclencheur manuel seulement) | INCONNU | Directeur |
| Supabase Edge | production | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` | toutes les fonctions | Fournis par la plateforme | Supabase |
| Supabase Edge | production | `STUDENT_EMAIL_DOMAIN` | `creer-profil-enfant`, `session-enfant` | INCONNU | Directeur |
| Supabase Edge | production | `LIVEKIT_CLOUD_API_KEY`, `LIVEKIT_CLOUD_API_SECRET` | `create-room-token`, `livekit-webhook` | INCONNU ; statut Cloud vs auto-hébergé à confirmer | Directeur |
| Supabase Edge | production | `LIVEKIT_SELFHOST_API_KEY`, `LIVEKIT_SELFHOST_API_SECRET` | idem (second fournisseur, ADR-023) | INCONNU | Directeur |
| Supabase Edge | production | `R2_IDENTITY_VAULT_*`, `R2_RECORDINGS_*`, `R2_MESSAGING_*`, `R2_APP_PRIVATE_*` (par groupe : `ACCOUNT_ID`, `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `BUCKET`, `ENDPOINT` selon `_shared/r2/domaines.ts`) | fonctions `piece-identite-*`, `archive-seance-acces`, `livekit-webhook` | Validés au vert le 21/09 (mémoire de session, `r2-selftest`), non revérifiés ici ; juridiction EU | Directeur (Cloudflare) |
| Vercel | production | variables du projet | aucune requise par le bundle (tout est compilé par `--dart-define`) | Lecture refusée (403) | Directeur |
| Flutter local | développement | `dart_define.json` (ignoré par Git) | `flutter run --dart-define-from-file` | Présent sur ce poste | Développeur |

Il n'existe pas d'environnement `staging` configuré (ni projet Supabase, ni projet Vercel, ni workflow). C'est un écart avec `06` « Fondations : environnements séparés ».

## 3. Nettoyage Git : classement cible par cible

Base : `origin/main` = `4a7aa2b`. Sauvegarde des fichiers non commités : `D:\RA _APP\_archive\2026-09-23_worktrees\<nom>\`. Restauration d'une branche : `git branch <nom> <sha>`.

### 3.1 Conserver (travail unique ou agent actif)

| Cible | SHA | Pourquoi |
|---|---|---|
| `main` (worktree `D:\RA _APP\RA -OFFICIAL-APP`) | `4a7aa2b` | production |
| `nettoyage/base-2026-09-23` | `33503fe` | remise à plat, à fusionner |
| `core24/fable-frontend` (worktree `D:\RA_CORE24\fable`) | `50fae3c` | 2 commits uniques, 87 fichiers, raccorde les lots TC D/F/H |
| `integration/core24-classes-v2` (worktree `rewayah-classes-v2`) | `e8beeb7` | audit de référence, 10 commits uniques |
| `integration/core24-classes-v2-remediation` (worktree `rewayah-classes-v2-remediation`) | `3c0cb1c` | agent actif le 23/09, 15 commits uniques |
| `docs/core24-classes-arbitration` | `196eb06` | arbitrage, 2 commits uniques |
| `observation/lot-2026-09-21` | `0bfc9e4` | 11 commits uniques ; migrations `0039`–`0042` appliquées en production |
| `astra/core24-presence-safeguard` | `730b7b7` | 18 commits uniques, « à intégrer plus tard » (arbitrage CORE24) |
| `astra/core24-v2` | `ce7e7e7` | 17 commits uniques |
| `astra/core24-classes-legacy-snapshot` | `3e2b53c` | 19 commits uniques ; rapports `ASTRA_24H_*_V2.md` non commités archivés |
| `lot/onboarding-offres` | `9a3ff0d` | 1 commit unique (note badges) |
| `sauvegarde/r2-du-tiers` | `201b521` | 1 commit unique, à comparer à `5a78726` |
| `codex/vague5-integration` | `f8a6988` | 7 commits uniques |
| `codex/r2-adaptive-shell` | `65c564f` | 4 commits uniques ; 23 fichiers non commités archivés |
| `codex/r1-adaptive-design-system` | `405683a` | 1 commit unique |
| `codex/login-demo` | `1110400` | 1 commit unique ; 1 fichier archivé |
| `codex/presence-correction-ui` | `d55606c` | 1 commit unique |
| `teaching-core/0-coordinateur` | `6081601` | 2 commits uniques (docs) |
| `refactor-ui-lavender-3628477128789856989` | `ed431ac` | 3 commits sans ancêtre commun ; contredit `03` mais historique |
| `specs` | `8a652d6` | 1 commit sans ancêtre commun ; périmé par `docs/current` |
| Stashes `stash@{0..2}` | | conservés ; contenu : EOL Windows (vide), copies ADM-04 déjà commitées, état avant `5b8b868` |

### 3.2 Worktrees dont la branche est conservée mais le dossier est retirable (fichiers uniques déjà archivés)

`rewayah-astra-core24` (6 fichiers archivés), `rewayah-login` (1), `rewayah-presence-ui` (0), `rewayah-prod-release` (13), `rewayah-r1` (0), `rewayah-r2` (23), `rewayah-review-20260915` (0), `rewayah-vague5-integration` (0), `D:\RA_OBS` (1 : la `0043` jeton vidéo), `D:\RA_ONBOARD` (1 : arbitrage CORE24 divergent). Commande par cible : `git worktree remove --force <chemin>`.

### 3.3 Cibles exactes de suppression proposées (0 commit unique, contenu entièrement dans `main`)

| Cible | SHA local = distant | Intégration prouvée par | Restauration |
|---|---|---|---|
| branche `admin-complet` | `b19c8d3` | `git merge-base --is-ancestor` vrai | `git branch admin-complet b19c8d3` |
| branche `starlit-surge-glides-04h50` + worktree `.gemini/antigravity/.../starlit-surge-glides-04h50` | `9d0229b` | idem | idem |
| branches `codex/release-all-20260915`, `codex/review-visible-20260915`, `codex/production-google-auth-20260916` | `b02ea98` | idem | idem |
| branche `integration/teaching-core` + worktree `D:\RA_TC\z` | `d5eb74c` | idem | idem |
| branches `teaching-core/{a,b,c,d,e,f,g,h,q}` + worktrees `D:\RA_TC\{a..q}` (1,6 Go) | `28c2238`, `d5bc5bf`, `e60c5b4`, `bc40b4a`, `4e65e50`, `bf01953`, `3545f8c`, `a9b295b`, `8337531` | idem, 0 fichier unique | idem |
| worktrees détachés `D:\ra-pwa-build`, `D:\ra-pwa-ctr`, `D:\ra-pwa-deploy-20260918`, `D:\ra-pwa-fix`, `D:\ra-pwa-secure-deploy` | `e76a14e`, `f1855de`, `99c7b6a`, `090ae6f`, `cbc4ff8` (tous dans `main`) | fichiers modifiés vérifiés présents dans l'historique (`git log --find-object`), 2 inédits archivés | `git worktree add` |
| worktree scratchpad `baseline` | `e104605` | dans `main` | |
| clones orphelins `rewayah-release-20260915` (+ `rewayah-audit-20260915`), `rewayah-review-all-20260915` (dépôt sans commit) | `b02ea98` | copie de `main` du 15/09 ; contenu archivé | archive |
| profils navigateur QA `qa-*`, `chrome-*` (12 dossiers, ~40 Mo) | | artefacts de test du 14 et 15/09 | aucun |
| `D:\RA _APP\RA -OFFICIAL-APP\build\` (276 Mo) | | régénéré par `flutter build` | aucun |

## 5. Réconciliation des migrations appliquées en production (lecture seule, 23/09)

Méthode : `supabase_migrations.schema_migrations` conserve le texte SQL appliqué (colonne `statements`, une entrée par migration). Empreinte MD5 calculée des deux côtés après la même normalisation : suppression des commentaires `--` jusqu'à la fin de ligne, puis de tout blanc (`regexp_replace` côté SQL, `[regex]::Replace` côté PowerShell, script `comparer_migrations.ps1` / `md5_normalise_git.ps1` conservés dans l'archive de session). Aucune écriture.

| Version prod | Nom prod | Fichier Git | Réf Git | Résultat |
|---|---|---|---|---|
| `0001`–`0005` | (CLI, versions courtes) | `0001`–`0005` | `origin/main` | `statements` vide en production (appliquées par la CLI) : texte non comparable, structure présente |
| `0006`, `0007`, `0008` (courtes) + `20260912025400 record_0006_0007_0008_versions` | | | | lignes de comptabilité (insert des versions), pas de SQL applicatif |
| `20260912025111 0006_init` | | `0006_rattrapage_semaine_utc_et_foyer.sql` | main | identique **hors `begin;`/`commit;`** (13 caractères : le MCP applique sans le bloc de transaction) |
| `20260912025141 0007_init` | | `0007_coran_structure_position_presence.sql` | main | idem, 13 caractères |
| `20260912025212 0008_init` | | `0008_attribution_manuelle.sql` | main | idem, 13 caractères (vérifié : le texte prod commence à `create function public.eleves_sans_enseignant()`) |
| `20260912032421 0009_journal_audit` | | `0009_journal_audit.sql` | main | idem, 13 caractères |
| `20260912130044 video_jeton_presence` | | `0010_video_jeton_presence.sql` | main | **identique** |
| `20260912211806 0011_presence_bornee` | | `0011_presence_bornee.sql` | main | première version appliquée (1 362 caractères normalisés) puis corrigée par la suivante |
| `20260912212505 0011_presence_bornee_controleur_invisible` | | `0011_presence_bornee.sql` | main | **identique** au fichier Git actuel (1 467) : la production a reçu deux versions de `0011`, le dépôt garde la seconde |
| `20260913063307 0012_observation_controleur` | | `0012_observation_controleur.sql` | main | **identique** |
| `20260913064731 0013_corpus_coranique` | | `0013_corpus_coranique.sql` | main | **différent par construction** : la production a enregistré la structure seule (2 674 caractères) ; le corpus (734 950) a été chargé par un autre canal. Données présentes en production : 114 sourates, 604 pages, 6 236 versets, 1 mushaf |
| `20260918025655 0014_acces_agent` | | `0014_acces_agent.sql` | main | 13 caractères `begin;`/`commit;` + **27 caractères non expliqués** (19 813 prod / 19 853 Git) : à diffuser avant toute réapplication |
| `20260918155948 administration_voit_les_personnes` | | `0015_administration_voit_les_personnes.sql` | main | **51 caractères non expliqués** (6 175 / 6 226), sans `begin;`/`commit;` : à diffuser |
| `20260918195349 masquage_coherent_en_observation` | | `0016_...` | main | **identique** |
| `20260919115041`, `115420`, `123347` (`groupes_*`) | | `0017`, `0018`, `0019` | main | **identiques** |
| `20260919224503 role_enseignant`, `224844 durcissement_execute_enseignant` | | `0025`, `0026` | main | **identiques** |
| `20260919232916 0020`, `235846 0027`, `235944 0028` | | `0020`, `0027`, `0028` | main | **identiques** |
| `20260920025402 fermeture_dossiers_en_attente_anon` | | `0029` | main | **identique** |
| `20260920033433`…`033657` (`diagnostics_placement`, `progression_suivi`, `evaluations`, `qualite_pedagogique`) | | `0021`, `0022`, `0023`, `0024` | main | **identiques** |
| `20260920151343`…`162540` (`0030` ×2, `0031`, `0032` ×2, `0033` ×2) | | idem | main | **identiques** (7/7) |
| `20260921043316 0038_hook_jeton_foyer_absent` | | `0038` | main | **identique** (appliquée avant `0034`) |
| `20260921043922`…`053926` (`0034`, `0035`, `0036`, `0037`) | | idem | main | **identiques** (4/4) |
| `20260921054047 0039_budget_observation_repond_sur_la_visite_en_cours` | | `0039_...sql` | `observation/lot-2026-09-21` | **identique** (md5 `0fa5c0d1…`, 7 177 caractères) |
| `20260921055048 0040_tuteur_masque_et_annonce_reservee_a_son_enfant` | | `0040_...sql` | `observation/lot-2026-09-21` | **identique** (md5 `fdb313a1…`, 9 713) |
| `20260921084435 0041_les_surfaces_d_invisibilite_oubliees_par_0040` | | `0041_...sql` | `observation/lot-2026-09-21` | **identique** (md5 `668986d9…`, 5 782) |
| `20260921133843 0042_etat_presence_fermee_et_jeton_video_verifie_le_compte` | | `0042_...sql` | `observation/lot-2026-09-21` | **identique** (md5 `7f7ac5a5…`, 6 706) |
| (absente) | | `0043_offres_horaires_et_intentions.sql` | main | **non appliquée** (md5 `b1498c12…`, 33 379) |
| (absente) | | `0043_autoriser_jeton_video_verifie_le_bon_compte.sql` | archive hors dépôt (`_archive/2026-09-23_worktrees/RA_OBS/`) | **non appliquée** (md5 `83f4888b…`, 3 665) ; correctif de `0042`, jamais commité |

Conclusion : la chaîne appliquée en production est expliquée de bout en bout. La production est en avance sur `main` de `0039`–`0042` (contenu exact = branche d'observation) et en retard de `0043_offres_horaires`. Deux écarts résiduels (27 et 51 caractères sur `0014` et `0015`) restent à diffuser avant toute réapplication de ces fichiers ailleurs ; ils n'affectent pas `0039`–`0042`.

## 4. Anomalies inspectées (sans correction pendant C0, sauf le commit `33503fe` antérieur à la version 2)

| Anomalie | Exposition confirmée ? | Preuve | Blocage |
|---|---|---|---|
| Groupes fictifs servis au tuteur | OUI sur `main` (`4a7aa2b`) : `lib/core/tc_groupe/port_groupes.dart:38` rend `GroupesDemonstrationLocale()` sans condition ; entrée depuis l'accueil tuteur (`accueil_famille_page.dart:465`, route `/tc/groupes`). Production : 0 groupe réel, la vue `mes_groupes_famille_v` existe. | lecture du code ; `execute_sql` lecture seule | Ne pas ouvrir `/tc/groupes` à une vraie famille tant que `main` porte le double. Le commit `33503fe` (branche) le corrige ; décision en attente. |
| « Cours enregistré » | OUI sur `main` : `salle.bandeauPermanent`, `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse`. Serveur : 0 ligne `session_recordings`, aucun démarrage d'Egress dans les fonctions (seule l'ingestion `egress_ended` existe), `recording_retention_days = 30`, 8 accusés `recording_and_control_notice` signés. | `git grep`, `execute_sql` | Aucune séance réelle avec ce texte. Le commit `33503fe` réécrit les trois libellés ; décision en attente. Arbitrage enregistrement (`07` §2) ouvert. |
| Deux salles | OUI : `/salle` (`features/salle`, atteinte par les 4 rôles) et `/tc/classe` (`features/tc_classe_live`, entrée « Rejoindre » inopérante pour le tuteur, `redirection.dart:138`). Deux chemins de jeton : `core/video` (vivant) et `tc_realtime` (non branché sur `main`, branché sur `core24/fable-frontend`). | rapport d'analyse du 23/09 | Aucune correction pendant C0 ; `08` §3 fixe `core/video` + `/salle` comme chemin vivant. |
| Migration `0043` en double | OUI (voir §1) | `git ls-tree`, archive | Ne rien renommer ; `0044` après C0. |
| `r2-selftest` en production sans source dans le dépôt | OUI : fonction v49, `verify_jwt: true` | `list_edge_functions` | Décider : versionner ou retirer. |
