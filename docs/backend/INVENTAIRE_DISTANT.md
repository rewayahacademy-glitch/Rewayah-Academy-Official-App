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


## Ledger de migrations PROD retourné par Supabase MCP

Lecture seule le 2026-10-09. Les entrées ci-dessous sont les noms et versions retournés par l’API, sans déduction sur l’auteur ni sur le contenu SQL. Correspondance avec les fichiers Git à vérifier dans B-01.

| Version | Nom retourné |
| --- | --- |
| `0001` | `fondations` |
| `0002` | `statut_attente_kyc` |
| `0003` | `profil_defaut_attente` |
| `0004` | `inscription_kyc_appairage` |
| `0005` | `dashboards_affectation_regles` |
| `0006` | `` |
| `0007` | `` |
| `0008` | `` |
| `20260912025111` | `0006_init` |
| `20260912025141` | `0007_init` |
| `20260912025212` | `0008_init` |
| `20260912025400` | `record_0006_0007_0008_versions` |
| `20260912032421` | `0009_journal_audit` |
| `20260912130044` | `video_jeton_presence` |
| `20260912211806` | `0011_presence_bornee` |
| `20260912212505` | `0011_presence_bornee_controleur_invisible` |
| `20260913063307` | `0012_observation_controleur` |
| `20260913064731` | `0013_corpus_coranique` |
| `20260918025655` | `0014_acces_agent` |
| `20260918155948` | `administration_voit_les_personnes` |
| `20260918195349` | `masquage_coherent_en_observation` |
| `20260919115041` | `groupes_pedagogiques` |
| `20260919115420` | `groupes_revoke_anon` |
| `20260919123347` | `groupes_durcissement` |
| `20260919224503` | `role_enseignant` |
| `20260919224844` | `durcissement_execute_enseignant` |
| `20260919232916` | `0020_programme_pedagogique` |
| `20260919235846` | `0027_maj_profil_enseignant` |
| `20260919235944` | `0028_maj_profil_enseignant_revoke_anon` |
| `20260920025402` | `fermeture_dossiers_en_attente_anon` |
| `20260920033433` | `diagnostics_placement` |
| `20260920033522` | `progression_suivi` |
| `20260920033612` | `evaluations` |
| `20260920033657` | `qualite_pedagogique` |
| `20260920151343` | `0030_tc_socle` |
| `20260920151522` | `0030_tc_socle_durcissement_search_path` |
| `20260920151612` | `0031_participant_role_admin` |
| `20260920152540` | `0032_tc_catalogue` |
| `20260920152709` | `0032_tc_catalogue_durcissement_grants` |
| `20260920162022` | `0033_tc_vues_rpc` |
| `20260920162540` | `0033_tc_vues_rpc_durcissement_grants` |
| `20260921043316` | `0038_hook_jeton_foyer_absent` |
| `20260921043922` | `0034_r2_stockage` |
| `20260921053639` | `0035_ressources_du_groupe_rejoue_visibilite` |
| `20260921053819` | `0036_observation_defauts_academie_et_plafond_visite_groupe` |
| `20260921053926` | `0037_entrer_observation_rend_l_enfant_concerne` |
| `20260921054047` | `0039_budget_observation_repond_sur_la_visite_en_cours` |
| `20260921055048` | `0040_tuteur_masque_et_annonce_reservee_a_son_enfant` |
| `20260921084435` | `0041_les_surfaces_d_invisibilite_oubliees_par_0040` |
| `20260921133843` | `0042_etat_presence_fermee_et_jeton_video_verifie_le_compte` |
