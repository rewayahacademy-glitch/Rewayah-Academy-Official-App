---
name: rewayah_remise_a_plat_2026-09-23
description: "État du dépôt Rewayah après la remise à plat du 23/09/2026 — specs canoniques docs/current, branche nettoyage/base-2026-09-23, ce qui reste à valider (worktrees, branches), arbitrages ouverts"
metadata:
  node_type: memory
  type: project
  originSessionId: 34fd3a1f-b7e3-4d8e-81e6-aaed073383c8
  modified: 2026-09-23T22:43:29.948Z
---

# Remise à plat du 23 septembre 2026

**Dépôt** : `D:\RA _APP\RA -OFFICIAL-APP` (origin `rewayahacademy-glitch/Rewayah-Academy-Official-App`).
`origin/main` = `4a7aa2b` (lot onboarding offres vitrines, poussé le 22/09). Pousser sur `main` déploie
(`flutter-deploy.yml`). Dernier déploiement Vercel production : 22/09 (projet `rewayah-academy`,
`team_VfPE1KP6vCKUyTeeG6AtAV8B`, tous les déploiements portent `meta: {}` = CLI, pas d'intégration Git).

**Specs canoniques** : `D:\RA _APP\docs de lancement\00..07` copiées dans `docs/current/` sur la branche
`nettoyage/base-2026-09-23`. Tous les anciens docs (HANDOFF 233 Ko, ADR, Bible V2, rapports d'agents,
CODEX*.md) sont sous `docs/archive/2026-09-pre-remise-a-plat/` par `git mv`. 135 fichiers de code ont
leurs liens de commentaire réécrits vers l'archive. `CLAUDE.md`, `lib/CLAUDE.md`, `supabase/CLAUDE.md`
réécrits en index courts. `.firebaserc` retiré.

**Commits `4e9903c` (docs) puis `33503fe` (V0) poussés sur `origin/nettoyage/base-2026-09-23`** (pas
sur `main`). Vérifié : `dart analyze --fatal-infos` sans problème, `verifier_jetons` 344 fichiers sans
violation, `flutter test` 1770 verts.

**Branches au 23/09 soir** : `v0/verite-produit` = `33503fe` (V0 conservé à part, poussé, ni fusionné ni déployé,
décision directeur) ; `c0/configuration-baseline-2026-09-23` = `7ee78ef` (docs `4e9903c` + C0 sans V0 + vérification
finale des 15 branches + preuve Actions + ménage des instructions) = branche de PR vers `main`.
**Ménage des instructions clos le 23/09 soir** : fichiers actifs = `CLAUDE.md`, `lib/CLAUDE.md`, `supabase/CLAUDE.md`,
`docs/current/` (00–04, 06–09, bilan C0), `.claude/settings.local.json` + `.claude/hooks/secret-scanner.py` (protection),
`MEMORY.md` + 23 mémoires actives. Déplacés hors du chemin actif : `.claude/agents/flutter-expert.md` et
`.claude/commands/supabase-*.md` (→ `D:\RA _APP\_archive\2026-09-23_instructions\`), six mémoires PISI
(→ `memory/archive/pisi/`, dont « commit & push always »). `~/.claude/CLAUDE.md` et `C:\Users\dell\AGENTS.md`
portent en tête un renvoi vers Rewayah et déclarent PISI/OfficialSays/BRAIN/Ponytail en pause. **PR #2 ouverte le 23/09 en brouillon** (non fusionnée) :
https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/pull/2. Ouverte par l'API REST depuis PowerShell
avec un jeton fourni par le directeur dans `C:\Users\dell\Downloads\gitacs.txt` (lu dans une variable, jamais affiché ;
à révoquer par le directeur quand il n'en a plus besoin). `gh` 2.101.0 portable est sous
`C:\Users\dell\AppData\Local\Programs\gh\bin` mais **inutilisable** : handshake TLS vers github.com > 10 s sur ce poste
(première négociation à 15 s, PowerShell passe grâce au cache de session), et `*.blob.core.windows.net` (journaux Actions)
est injoignable en TLS. **CI #4 de la PR** : migrations FAIL (psql sortie 3, probable absence de `stub_storage.sql`),
Windows FAIL (fins de ligne seulement, reproduit en local), apk FAIL (cause inconnue), web et Edge PASS.
**Preuve Git→Vercel** : run #28 pour `4a7aa2b` échoue à « Refuse de partir si un secret manque », les 5 secrets sont
absents ; idem pour tous les runs depuis le 20/09, dont `ae61eb6` (voir [[feedback_chaine_deploiement_reparee_le_21_09]]).
**Ménage validé en principe par le directeur (23/09)** : retrait des 15 branches entièrement dans `main` (liste exacte
bilan §3.3 : `admin-complet`, `starlit-surge-glides-04h50`, 3 `codex/*-2026091[56]`, `integration/teaching-core`,
`teaching-core/{a..h,q}`), worktrees contrôlés un par un (13 propres, `rewayah-prod-release` = 16 fichiers non
commités archivés) ; conserver branches à commits uniques, stashes, V0, C0 ; clones/profils/`build\` à part.
Aucune suppression exécutée : attendre le feu vert ligne par ligne. ;
`nettoyage/base-2026-09-23` = `2a8b847` (mélange) conservée jusqu'à décision. Migrations réconciliées en lecture
seule : `0039`–`0042` prod == fichiers `observation/lot-2026-09-21` (md5 normalisé), ne rien lancer (`0043`/`0044`).
Docker du poste : répond 1 fois sur 4 ; rejeu via montage `initdb.d` en un seul `docker run`.

**Commit précédent : `2a8b847` sur `origin/nettoyage/base-2026-09-23`** (lot C0 installé, bilan
`CONFIGURATION_BASELINE_2026-09-23.md`, gate C0 = BLOCKED : rejeu PostgreSQL non obtenu car le moteur Docker
répond 500 sur ce poste ; Git→Vercel non prouvé pour `4a7aa2b` faute de jeton GitHub ; fusion `main` en attente
d'une PR par le directeur). Migrations : `main` n'a pas `0039`–`0042` (appliquées en prod, sur
`observation/lot-2026-09-21`) et porte `0043_offres_horaires` non appliquée ; `stub_storage.sql` manque à `ci.yml`.

**Lot déploiement 24/09** : le directeur a fourni jetons GitHub (fine-grained, admin dépôt) et Vercel (compte entier,
ne toucher que `rewayah-academy` = `prj_xDldWMLNH726BpwEVUlIAJUOSzPe`, équipe `team_VfPE1KP6vCKUyTeeG6AtAV8B`) dans
`gitacs.txt`. Le projet Vercel est bien lié à GitHub (link github, productionBranch main) mais `vercel.json` coupe le
zero-config ; aucune protection SSO/mot de passe sur les aperçus. Le **classificateur auto mode refuse à l'agent** : écriture
de secrets Actions (« Secret-Store Writes ») et modification de `flutter-deploy.yml` (« Production Deploy »). Livrables
déposés dans le scratchpad `deploiement/` (workflow avec aperçu par PR, `appliquer.ps1`) et `secrets/creer_secrets.mjs`
(libsodium sealed box) : le directeur les lance lui-même avec `! powershell -File …`. Clé Supabase à compiler = anon JWT
legacy (déjà dans le bundle prod), URL `gggmtelinlpseweouyav`. **Fait par le directeur le 24/09** : 5 secrets créés (HTTP 201),
workflow amendé `ab5f7f7` (aperçu par PR, prod réservée à `main`), **run #29 = 14/14 PASS**, aperçu de la PR #2 servi,
production toujours sur `dpl_69MAn…` du 21/09. **Désormais toute fusion dans `main` déploie vraiment.** Pour « voir une
branche en live » : ouvrir une PR, lire l'URL en commentaire. Reste : `ci.yml` (migrations, Windows, apk), jeton Vercel à
limiter à l'équipe, `SENTRY_DSN_FLUTTER` et `SUPABASE_ACCESS_TOKEN` non traités.

**Amendement 23/09 soir (08 §5 bis)** : le ménage instructions/mémoires est clos et **la règle interdisant tout travail UI
avant clôture complète de C0 est levée**. UI autorisée sur branche dédiée, un parcours et un écran à la fois, sur ordre
explicite du directeur (visuels à transmettre). Fusion `main` et déploiement restent bloqués (CI, migrations, secrets).
V0, V1, CORE24 restent suspendus. **Ne commencer aucun écran sans cet ordre.**

**⛔ Direction 23/09, version 2 (lot C0, empreintes vérifiées)** : GEL FONCTIONNEL (amendé ci-dessus pour l'UI). Aucun lot V0–V6 tant que la
gate de configuration C0 n'est pas close (`docs/current/08` §0, `09` = seule mission exécutable, bilan dans
`docs/current/CONFIGURATION_BASELINE_2026-09-23.md`). `05_PROMPT_AGENT_INTEGRATEUR.md` archivé. Le commit V0
`33503fe` a été livré AVANT réception de la version 2 : conflit consigné, à conserver ou reverter sur décision
du directeur, ne pas trancher seul.

**Direction 23/09, version 1 (remplacée par la version 2)** : feuille de route en tranches verticales V0–V6, décisions
sur le nettoyage (ne PAS lancer le script de retrait des worktrees, pas d'accord global par catégorie
de branches, conserver les lots D/F/H, `core/video` + `/salle` restent le chemin vivant). V0 codé :
`portGroupesSelon`/`portHorlogeSelon` (démo seulement sous `PLAYGROUND=true`), `GroupesSupabase` sur
`mes_groupes_famille_v`, `HorlogeSeanceSupabase` sur `horloge_seance()`; libellés « Cours enregistré »
retirés (0 enregistrement en prod, aucun démarrage d'Egress). V5 bloqué : pas de jeton GitHub sur ce
poste pour lire les runs Actions ; le projet Vercel n'a aucun dépôt Git lié (chaîne = Actions + CLI).

## Ce qui a été décidé sur le code (et pourquoi rien n'a été supprimé)

- 45 fichiers de `lib/` (6 764 lignes) ne sont pas atteignables depuis `main.dart` : lots Teaching Core
  D (dock outils), F (état partagé / realtime), H (après-cours). **Conservés** : le MVP les exige
  (outils enseignant, reprise après reconnexion, cahier après cours) et `core24/fable-frontend` les
  raccorde déjà dans `tc_classe_live`. Les supprimer aurait retardé le dev.
- Contradictions vivantes avec les specs, à traiter en lots et non par suppression : matching
  individuel par disponibilités (`core/matching`, `creneaux`, `disponibilites`, `admin_attribution`,
  fil « élèves en attente » de `journee_page`) ; groupes de démonstration servis au tuteur en prod
  (`core/tc_groupe/port_groupes.dart:38`, `port_horloge_seance.dart:55`) ; bandeau « Cours enregistré »
  et point de contrat `pointEnregistrement` sans enregistrement réel ; « Mode enfant » à renommer
  `Interface guidée` (`InterfaceMode.enfant` valeur SQL `child`) ; « Cours individuel » dans
  `journee_page` ; défauts 5/6 documentés dans `service_groupes.dart` (spec : 4 enfants / 5 adultes).
- Doublons : `/salle` (vivant, 4 rôles) vs `/tc/classe` (sans entrée effective) ; `/tc/mushaf` doublon
  de `/eleve/coran` ; `fiche_groupe`/`revue_groupe` (enseignant, vraies données) vs
  `tc_espace_groupe`/`tc_mes_groupes` (tuteur, démo) ; `GroupeAdmin` vs `GroupSummaryVM`.
- Routes sans entrée : `/enseignant/bienvenue`, `/tc/observation/:id`, `/_galerie/compte`.
- Manque du MVP : aucun catalogue de classes ni choix familial d'une classe précréée
  (`tc_catalogue` est la Bibliothèque de ressources).

## Worktrees et branches (validation opérateur requise pour toute suppression)

Archivage fait dans `D:\RA _APP\_archive\2026-09-23_worktrees\` (489 fichiers, journal
`JOURNAL_ARCHIVAGE.txt`) : tout fichier modifié ou non suivi des worktrees à retirer, dont la migration
`0043_autoriser_jeton_video_verifie_le_bon_compte.sql` (RA_OBS, correctif de 0042, **collision de numéro
avec `0043_offres_horaires` de main**), `CORE24_CLASSES_ARBITRATION_FINAL.md` (RA_ONBOARD, version
différente de celle de `docs/core24-classes-arbitration`), les rapports `ASTRA_24H_*_V2.md`.
Le retrait effectif des worktrees a été refusé par le classificateur ; commandes à rejouer après accord
dans le rapport de session. À conserver : `main`, `rewayah-classes-v2`, `rewayah-classes-v2-remediation`
(agent actif le 23/09), `D:\RA_CORE24\fable`.

CORE24 : `integration/core24-classes-v2` (`e8beeb7`) auditée NON CONFORME ; remédiation
`integration/core24-classes-v2-remediation` (`3c0cb1c`, 23/09) bloquée sur la gate PostgreSQL du lot A.
Aucun merge.

## Arbitrages ouverts (spec 07 §Arbitrages)

Capacités/durées commerciales (5/60 et 6/90 académique vs 4/45 et 5/90 économique) ; enregistrement
audio ; prix, unités, salaire ; sources Salat/invocations, édition Nour al-Bayân, Mushaf Hafs ;
fournisseurs de collecte et payout.

**Why:** une mémoire de 150 fichiers avec des mises à jour contradictoires ne guidait plus personne.
**How to apply:** partir de `docs/current/00` ; ne rouvrir `memory/archive/` que pour une décision
nommée ; chaque bilan distingue spécifié / codé / testé / déployé.
