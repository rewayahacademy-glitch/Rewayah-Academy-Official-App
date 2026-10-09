# Inventaire distant Supabase — B-00

Date de constat : 2026-10-09. Références : branche `ccr-1b1bfa0b-m1kvkk` à `3163fb1be623b0e6650a92a5d04b011e79e46bf0`; projet PROD `gggmtelinlpseweouyav`; projet STAGING `xldmmlrnxyabdtvxqbyy`.

## Portée et méthode

Constat en lecture seule via Supabase MCP. Cette session n’a appliqué aucune migration, déployé aucune fonction et modifié aucun réglage distant. Ce document décrit uniquement les champs réellement retournés par les outils; il ne certifie pas les données métier, les politiques complètes, les secrets, ni les réglages faits manuellement.

## PROD — `gggmtelinlpseweouyav`

- Projet : Rewayah PROD (Real Users), état `ACTIVE_HEALTHY`, région `eu-west-1`, PostgreSQL `17.6.1.166`. URL vérifiée : `https://gggmtelinlpseweouyav.supabase.co`.
- `list_migrations` retourne 50 entrées. L’historique comprend des noms/versions historiques et des horodatages, avec des entrées jusqu’à la migration nommée `0042_etat_presence_fermee_et_jeton_video_verifie_le_compte`.
- Les fonctions Edge retournées sont actives : `creer-profil-enfant` (v34, JWT requis), `session-enfant` (v34, JWT requis), `create-room-token` (v33, JWT requis), `livekit-webhook` (v34, JWT non requis), `agent-session` (v33, JWT requis), `r2-selftest` (v49, JWT requis), `piece-identite-depot` (v1, JWT requis), `archive-seance-acces` (v1, JWT requis), `piece-identite-confirme` (v1, JWT requis), `piece-identite-acces` (v1, JWT requis). Les versions sont celles annoncées par l’API au moment de la lecture.
- Buckets Storage : `avatars`, `kyc`, `photos_enseignants`, `supports`; le champ `public` vaut `false` pour chacun. Les limites MIME et de taille retournées sont `NULL`; les policies Storage n’ont pas été auditées dans ce constat.
- Extensions installées lues dans `pg_extension` : `btree_gist 1.7`, `pg_stat_statements 1.11`, `pg_trgm 1.6`, `pgcrypto 1.3`, `plpgsql 1.0`, `supabase_vault 0.3.1`, `uuid-ossp 1.1`.
- Noms de secrets, valeurs (jamais consultées), variables d’environnement et réglages dashboard faits à la main : non vérifiés, car les outils disponibles dans cette session ne fournissent pas leur inventaire.

## STAGING — `xldmmlrnxyabdtvxqbyy`

- Projet Rewayah STAGING (test), état `ACTIVE_HEALTHY`, région `eu-west-2`, PostgreSQL `17.11.0.003`.
- `list_migrations` retourne une liste vide et `list_edge_functions` ne retourne aucune fonction.
- Cela ne démontre pas que tous les réglages dashboard ou secrets sont absents; ils n’ont pas été énumérés.

## Écart de provenance à traiter — B-01

Sur la branche d’intégration, l’arbre Git contient 42 fichiers SQL : migrations `0001` à `0038` avec des doublons numériques historiques `0030`, `0032`, `0033`, puis `0043_offres_horaires_et_intentions.sql`. Le fichier `LISEZ-MOI-0035-0037-non-appliquees.md` est documentaire, pas une migration SQL. Les sources SQL `0039` à `0042` présentes dans le ledger PROD ne figurent pas dans cet arbre, alors que `0043` y figure sans entrée de migration PROD observée.

Le ledger PROD confirme les entrées correspondant à `0035`, `0036` et `0037`; le libellé de suivi « migrations 0035 à 0037 non appliquées » est donc contredit par l’état distant observé. Il faut retrouver les sources et l’historique Git de `0039`–`0042`, vérifier la provenance de `0043` et résoudre la collision de numérotation avant de proposer une migration. Ne pas modifier une migration appliquée, ne pas rejouer `0035`–`0037`, et n’appliquer aucune migration distante sans GO explicite inscrit au Journal distant.

## Références d’observation

Supabase MCP : `list_projects`, `get_project`, `get_project_url`, `list_migrations`, `list_edge_functions`, `list_tables`, `list_extensions`, ainsi que deux requêtes `SELECT` en lecture seule sur `storage.buckets` et `pg_extension`. Le journal partagé conserve les mêmes observations et leurs limites.
