# État backend et STAGING — 2026-10-09

## Périmètre appliqué

- Branche de travail : `codex/backend-staging-deploy`, issue du commit de référence `ccr-1b1bfa0b-m1kvkk`.
- Projet Supabase STAGING : `xldmmlrnxyabdtvxqbyy`.
- L’autorisation explicite du propriétaire pour initialiser STAGING a été consignée dans l’onglet « Journal distant » avant les écritures.
- Les 47 migrations du dépôt, de 0001 à 0044, sont enregistrées sur STAGING. Pour les numéros en double, les migrations de socle ont précédé leurs durcissements.
- Contrôles après application : 72 tables publiques, 4 buckets, aucun utilisateur Auth. Pour `comptes_admin` et `read_kyc_documents`, EXECUTE est refusé à `anon` et `agent_ro`, et accordé à `authenticated`.
- Aucune migration, configuration ou donnée n’a été écrite sur PROD.

## Raccordements et CI

- Les builds d’aperçu Flutter utilisent l’URL STAGING et la clé `SUPABASE_STAGING_ANON_KEY`; les builds de production sur `main` gardent les identifiants PROD.
- Le déploiement Edge STAGING est séparé du job PROD. Les jobs PROD sont ignorés sur cette branche.
- Le job Edge STAGING ne peut pas déployer tant que le secret GitHub Actions `SUPABASE_STAGING_ACCESS_TOKEN` n’existe pas. Aucun jeton PROD n’est réutilisé. La présence de `SUPABASE_STAGING_ANON_KEY` dans GitHub Actions reste à vérifier.
- Le scénario B-18 passe après remplacement des appels ambigus à deux surcharges SQL par une vérification de la définition de la signature courte.
- La suite CI complète s’arrête ensuite dans `scenarios_etape3.sql` : ADM-02 attend 2 dossiers et en trouve 4. Ce résultat demande une investigation distincte.
- Le job CI comporte aussi les validations Flutter et Edge; leur résultat final doit être vérifié dans GitHub Actions.

## À vérifier par Claude

1. Revoir les changements de workflow et la séparation des environnements.
2. Examiner la migration 0044 et la couverture B-18, en particulier les signatures surchargées.
3. Enquêter sur le résultat ADM-02 de la suite historique.
4. Revoir le catalogue de migrations et leur compatibilité avec l’historique distant avant toute automatisation `supabase db push`.
