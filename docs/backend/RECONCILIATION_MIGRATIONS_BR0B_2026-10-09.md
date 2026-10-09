# Réconciliation des migrations — lot A (2026-10-09)

État vérifié en lecture seule sur PROD et STAGING le 2026-10-09. Ce document distingue l'ordre du ledger distant, les noms des fichiers locaux et l'application réelle du SQL.

## Écarts observés

| Fichiers locaux | Ledger PROD | Ledger STAGING | État |
|---|---|---|---|
| `0030_tc_socle.sql` / `0030_tc_socle_durcissement_search_path.sql` | versions `20260920151343` / `20260920151522` | `20261009163715` / `20261009163717` | Deux migrations distinctes, pas une seule entrée en double. |
| `0032_tc_catalogue.sql` / `0032_tc_catalogue_durcissement_grants.sql` | `20260920152540` / `20260920152709` | `20261009163720` / `20261009163721` | Deux migrations distinctes. |
| `0033_tc_vues_rpc.sql` / `0033_tc_vues_rpc_durcissement_grants.sql` | `20260920162022` / `20260920162540` | `20261009163723` / `20261009163724` | Deux migrations distinctes. |
| `0039`–`0042` | versions PROD `20260921054047`, `20260921055048`, `20260921084435`, `20260921133843` | versions STAGING `20261009163736`–`20261009163741` | Sources restaurées à l'identique depuis `observation/lot-2026-09-21`, conformément à Questions!B-01-Q1. |
| `0043_offres_horaires_et_intentions.sql` | absente | `20261009163743` | Appliquée sur STAGING; absente de PROD. Application PROD sans GO directeur interdite. |
| `0044_securiser_rpc_admin_et_kyc.sql` | absente | `20261009163744` | Appliquée sur STAGING; absente de PROD. |

Les premières migrations PROD conservent également des entrées historiques à versions courtes (`0001`–`0008`) et des entrées horodatées plus récentes pour certains socles. Le ledger ne permet pas, à lui seul, de déduire l'égalité de leurs corps SQL.

## Décision de lot

Les trois paires 0030/0032/0033 restent chacune comme deux fichiers SQL distincts : les six noms et versions distants prouvent que les correctifs ont été suivis comme migrations séparées. Aucun fichier déjà appliqué n'est réécrit ou supprimé. Les versions du ledger sont consignées ci-dessus pour éviter de confondre une paire de fichiers avec une unique migration.

Les migrations correctives nouvelles de cette branche utilisent des préfixes horodatés uniques, après l'entrée STAGING 0044 :

- `20261009180727_disambiguate_creer_groupe_overloads.sql` (ajoute une migration pour rendre le surchargement à six arguments non ambigu);
- `20261009180728_agent_ro_household_predicate.sql` (accorde le droit stable minimal à `agent_ro` pour le prédicat foyer utilisé par la RLS).

Le correctif de signature ne modifie pas le fichier 0044 déjà appliqué sur STAGING : il intervient dans une migration additive ultérieure.

## Limites et suite

La CLI Supabase associe les migrations locales à leurs préfixes timestampés et compare les versions, pas les noms. Les anciens fichiers du dépôt sont numérotés sur quatre chiffres, tandis que les ledgers distants portent des versions différentes; le workflow de déploiement garde donc `db push` manuel et conditionnel. Ne pas lancer cette commande tant qu'un manifeste local/remote n'établit pas la correspondance pour toute la chaîne.

Preuves de migration en exécution : CI PostgreSQL 17, PR #9 vers `ccr-1b1bfa0b-m1kvkk`, run #29 a appliqué les migrations jusqu'à 0044; les scénarios etape3 et etape4 y passent après réalignement de leurs oracles. Les corrections suivantes (claims actifs en etape5/N2, migrations horodatées 0045/0046 et CTR-01/AGT-01) attendent le run CI #39. Cela ne constitue ni un passage sur STAGING des migrations 0045/0046, ni une autorisation PROD.

Sources : Supabase MCP `list_migrations` PROD `gggmtelinlpseweouyav` et STAGING `xldmmlrnxyabdtvxqbyy`; [référence officielle Supabase sur la comparaison des versions de migration](https://supabase.com/docs/reference/cli/supabase-migration-list).
