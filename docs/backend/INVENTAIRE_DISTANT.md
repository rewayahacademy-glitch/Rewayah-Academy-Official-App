# Inventaire distant Supabase — B-00

Constat en lecture seule : 2026-10-09, actualisé par Supabase MCP. Références fixes : PROD `gggmtelinlpseweouyav`, STAGING `xldmmlrnxyabdtvxqbyy`. Les URLs ont été vérifiées avec `get_project_url` avant tout accès. Aucun secret ni identifiant de compte Auth individuel n'est consigné.

## Synthèse vérifiée

| Élément | PROD | STAGING |
|---|---:|---:|
| État / région / PostgreSQL | ACTIVE_HEALTHY / eu-west-1 / 17.6.1.166 | ACTIVE_HEALTHY / eu-west-2 / 17.11.0.003 |
| Ledger migrations | 50 entrées, jusqu'à 0042 | 47 entrées, jusqu'à 0044 |
| Tables / vues public | 67 / 15 | 72 / 16 |
| Tables publiées sur supabase_realtime | 0 observée | 0 observée |
| Utilisateurs Auth | 11 (comptage seulement) | 0 |
| Buckets Storage | 4 | 4 |
| Extensions installées | 7 | 7 |
| Edge Functions actives | 10 | 0 |

Les quatre buckets des deux projets sont `avatars`, `kyc`, `photos_enseignants`, `supports`. Les sept extensions installées sont `btree_gist 1.7`, `pg_stat_statements 1.11`, `pg_trgm 1.6`, `pgcrypto 1.3`, `plpgsql 1.0`, `supabase_vault 0.3.1`, `uuid-ossp 1.1`.

## Edge Functions PROD

Les dix fonctions actives retournées par l'API : `creer-profil-enfant` (v34), `session-enfant` (v34), `create-room-token` (v33), `livekit-webhook` (v34), `agent-session` (v33), `r2-selftest` (v49), `piece-identite-depot` (v1), `archive-seance-acces` (v1), `piece-identite-confirme` (v1), `piece-identite-acces` (v1). `verify_jwt=false` est retourné pour `livekit-webhook`; les neuf autres fonctions ont `verify_jwt=true`. Ceci décrit la configuration observée, sans attester la sécurité fonctionnelle.

## Écart migrations

Le ledger PROD conserve des versions timestampées distinctes pour les paires historiques locales 0030/0032/0033. 0039–0042 sont présentes au ledger et leurs sources exactes ont été restaurées sur `codex/backend-lot-a` selon Questions!B-01-Q1. Les migrations 0043 (offres) et 0044 (RPC/KYC) sont absentes de PROD et présentes sur STAGING. Aucun DDL ni migration n'a été appliqué à PROD pendant cette session.

STAGING a déjà été initialisée avant ce constat : 47 migrations jusqu'à 0044, 72 tables public, 4 buckets, et 0 utilisateur Auth. Le service Storage distant existe; les Edge Functions n'y sont pas déployées. Les migrations correctives 0045/0046 de la branche ne sont pas encore appliquées sur STAGING.

## Ce qui n'est pas vérifié

Le décompte et les métadonnées ne prouvent pas la parité des schémas, les droits effectifs via l'API PostgREST, la validité des Auth flows, les policies Storage complètes, les réglages dashboard faits manuellement, les valeurs/présence des secrets, les sauvegardes restaurables, ni la configuration de paiement, email, LiveKit ou R2. Le nombre de comptes Auth PROD n'identifie pas les personnes. Les tests API réels sur STAGING restent à exécuter avec des comptes synthétiques. Les réponses du catalogue et du ledger ne suffisent pas à établir le corps SQL historique; B-01 porte cette réconciliation.

Sources : Supabase MCP `get_project`, `get_project_url`, `list_migrations`, `list_edge_functions`, `list_tables`, `list_extensions`, et requêtes SELECT limitées à `storage.buckets`, `pg_extension`, `pg_publication_tables` et au nombre de comptes Auth. Journal partagé : onglet « Journal distant ». Aucun secret n'a été consulté.

PROD ne doit être modifiée qu'après GO explicite consigné dans « Journal distant ». STAGING est l'environnement d'essai autorisé, sans données réelles; chaque mutation y reste à journaliser.
