---
name: feedback_chaine_deploiement_reparee_le_21_09
description: "Depuis le 24/09/2026 pousser sur main DÉPLOIE RÉELLEMENT en production (5 secrets Actions créés, run #29 PASS) ; une PR vers main donne une URL d'aperçu Vercel ; avant cela aucun déploiement n'était jamais parti d'Actions"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 34fd3a1f-b7e3-4d8e-81e6-aaed073383c8
  modified: 2026-09-23T22:44:50.846Z
---

**Depuis le 24/09/2026, un push sur `main` déploie réellement en production.** Les cinq secrets
`VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, `VERCEL_TOKEN`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` ont été créés
par le directeur (script local à boîte scellée libsodium, HTTP 201). Le workflow `Flutter Web → Vercel`
amendé (`ab5f7f7`, branche C0) déploie en production pour `push` sur `main` et en **aperçu** (sans
`--prod`, `ENVIRONNEMENT=staging`, URL en commentaire de la PR) pour toute `pull_request` vers `main`.
Run #29 (PR #2) : 14/14 PASS, aperçu servi, production intacte.

Historique : du 20 au 23/09, chaque run `push` sur `main` (#22 à #28) échouait à l'étape « Refuse de
partir si un secret manque » ; tous les déploiements de production étaient des CLI manuelles (`meta`
sans `githubCommitSha` ou `source: cli`). Le mode production du workflow **n'a pas encore été exercé**
(aucun push sur `main` depuis la création des secrets).

**Why:** croire la chaîne inerte fait pousser sur `main` sans précaution ; croire qu'un aperçu
n'existe pas fait déployer en production « pour voir », ce qui a écrasé la prod le 18/09.

**How to apply:** toute fusion dans `main` = mise en production, à décider par le directeur. Pour
montrer une branche, ouvrir une PR vers `main` et lire l'URL d'aperçu en commentaire ; jamais de
`vercel deploy --prod` depuis un poste. Vérifier un déploiement de production avec `list_deployments`
(projet `prj_xDldWMLNH726BpwEVUlIAJUOSzPe`, équipe `team_VfPE1KP6vCKUyTeeG6AtAV8B`) : `target:
production` et `meta.githubCommitSha` du commit poussé. Lire un run Actions sans `gh` : API REST
depuis PowerShell avec le jeton lu dans une variable ; les annotations des check-runs suffisent, les
journaux bruts (`*.blob.core.windows.net`) sont injoignables en TLS depuis ce poste. Le classificateur
de Claude Code refuse à l'agent l'écriture de secrets et de `flutter-deploy.yml` : préparer les
scripts, le directeur les lance avec `! powershell -File …`.

Voir [[rewayah_remise_a_plat_2026-09-23]] et [[feedback_vercel_zero_config_ecrase_la_production]].
