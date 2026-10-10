# Réconciliation des migrations — lot A (2026-10-10)

Constat en lecture seule des ledgers Supabase PROD et STAGING, rapproché de l'arbre de migrations de `ccr`. Ce rapport actualise la comparaison du 9 octobre sans réécrire ce document historique.

## Références et méthode

- `ccr-1b1bfa0b-m1kvkk` : HEAD vérifié le 2026-10-10 : `858dcc666fc3fc4a559dda1b996c15a4e413bb08`.
- L'arbre courant contient 51 fichiers SQL de migration. La comparaison GitHub de `05e87f92936cd4afa2ee95e64db8baf7732a0de8` à `858dcc666fc3fc4a559dda1b996c15a4e413bb08` porte sur cinq commits et ne retourne aucun changement sous `supabase/migrations/`; l'inventaire des 51 fichiers reste donc inchangé.
- Source live PROD : Supabase MCP `list_migrations`, projet `gggmtelinlpseweouyav`, 50 entrées.
- Source live STAGING : Supabase MCP `list_migrations`, projet `xldmmlrnxyabdtvxqbyy`, 76 entrées.
- La comparaison porte sur les noms du ledger et les noms de fichiers, normalisés en retirant l'extension `.sql`. Elle ne compare pas les corps SQL.

Aucune migration, réparation de ledger, écriture de schéma ou autre modification n'a été faite sur PROD ou STAGING pour ce rapport.

## Résultat de correspondance par nom

| Source | Entrées/fichiers | Correspondance par nom | Sans correspondant fiable |
|---|---:|---:|---:|
| Arbre `ccr` | 51 migrations SQL | 42 vers PROD ; 51 vers STAGING | 9 vers PROD ; 0 vers STAGING |
| Ledger PROD | 50 entrées | 42 vers l'arbre `ccr` | 8 entrées |
| Ledger STAGING | 76 entrées | 51 vers l'arbre `ccr` | 25 entrées STAGING-only |

« Sans correspondant fiable » ne signifie pas que le SQL n'existe pas dans la base. Les lignes vides et anciennes versions peuvent représenter une application manuelle ou un nom différent; le ledger seul ne permet pas de prouver l'équivalence.

## Neuf fichiers sans homonyme fiable dans PROD

- `0006_rattrapage_semaine_utc_et_foyer.sql`
- `0007_coran_structure_position_presence.sql`
- `0008_attribution_manuelle.sql`
- `0043_offres_horaires_et_intentions.sql`
- `0044_securiser_rpc_admin_et_kyc.sql`
- `0045_disambiguate_creer_groupe_overloads.sql`
- `0046_agent_ro_household_predicate.sql`
- `0047_mask_agent_peer_names.sql`
- `0048_revoke_public_volatile_function_execute.sql`

Les migrations 0043–0048 sont nommées séparément dans STAGING et sont absentes du ledger PROD observé. Aucune réparation ou application PROD n'est proposée par ce rapport.

## Huit entrées PROD sans homonyme local fiable

| Version PROD | Nom PROD |
|---|---|
| `0006` | nom vide |
| `0007` | nom vide |
| `0008` | nom vide |
| `20260912025111` | `0006_init` |
| `20260912025141` | `0007_init` |
| `20260912025212` | `0008_init` |
| `20260912025400` | `record_0006_0007_0008_versions` |
| `20260912212505` | `0011_presence_bornee_controleur_invisible` |

Les trois versions courtes et les trois entrées horodatées liées à 0006–0008 rendent toute réparation de ledger particulièrement risquée sans récupération des sources SQL d'origine. Le nom `0011_presence_bornee_controleur_invisible` n'a pas d'homonyme dans les 51 fichiers actuels.

### Sources historiques candidates examinées (10/10)

Le commit GitHub `0bfc9e46c0ddc4a013273b8ced8a49791e327ba8` (21/09/2026) contient des fichiers candidats pour les migrations anciennes, mais leurs blobs diffèrent des fichiers actuels de `ccr` : `0006` `17ddf39b` (candidat) contre `ff26f06a` (ccr), `0007` `9701feba` contre `ee0b87b3`, `0008` `f4257f47` contre `24a9f3f3`, `0011_presence_bornee` `e6b7e9c3` contre `40df0e22`. La branche `codex/backend-migrations-historiques` porte les mêmes blobs que `ccr` pour ces quatre chemins. Dans les arbres examinés, aucun fichier source nommé `0006_init`, `0007_init`, `0008_init`, `record_0006_0007_0008_versions` ou `0011_presence_bornee_controleur_invisible` n'a été retrouvé. Ces références historiques sont des pistes à comparer; aucune ne relie un blob donné à une version du ledger PROD. La lecture `list_migrations` fournit ici version et nom, sans empreinte du corps appliqué. Les huit entrées restent donc non résolues.

## Vingt-cinq entrées présentes dans STAGING seulement

| Version STAGING | Nom STAGING |
|---|---|
| `20261009211101` | `0049_creneau_personnalise_ouvert_au_quota` |
| `20261009211130` | `0050_demandes_horaires_privees_admin` |
| `20261009211508` | `0051_indexes_demandes_horaires_rls_initplan` |
| `20261009232659` | `backend_0052_profil_eleve_titulaire` |
| `20261009232703` | `backend_0053_invitations_foyer` |
| `20261009232707` | `backend_0054_seance_resumes_famille` |
| `20261009235736` | `backend_f1_0055_classes_en_attente_enseignant` |
| `20261009235828` | `backend_f1_0056_profil_eleve_titulaire_lecture` |
| `20261010002805` | `backend_0057_agent_identity_subject` |
| `20261010013345` | `0058_guardian_visit_admin_account_valid` |
| `20261010013350` | `0059_student_concern_rpc` |
| `20261010013354` | `0060_etat_partage_persistant` |
| `20261010013359` | `0061_assignations_annotations_securisees` |
| `20261010013404` | `0062_canal_support` |
| `20261010013411` | `0063_notifications_privatives` |
| `20261010013415` | `0064_learning_assignment_privileges` |
| `20261010013420` | `0065_feedback_questions_and_private_aggregate` |
| `20261010013424` | `0066_offres_transition_notifications` |
| `20261010013428` | `0067_positive_role_guards` |
| `20261010013436` | `0068_retirer_demandes_horaires_toutes_sources` |
| `20261010013440` | `0069_exclure_demandes_eleves_deja_groupes` |
| `20261010013445` | `0070_regroupements_normalises_utc` |
| `20261010013450` | `0071_classes_en_attente_visibles` |
| `20261010013454` | `0072_demandes_refus_retrait_sync` |
| `20261010015246` | `0073_break_group_rls_recursion` |

STAGING contient aussi les 51 noms correspondant aux fichiers `ccr`. Son ledger démontre qu'une version nommée est inscrite, pas que les octets SQL du fichier actuel sont identiques au SQL appliqué.

## Doublons numériques et ordre

Les fichiers `0030`, `0032` et `0033` ont chacun deux noms distincts. PROD et STAGING ont des entrées nommées distinctes pour les deux variantes de chaque paire. Il s'agit de migrations séparées, pas de doublons à fusionner ou supprimer.

L'ordre PROD du ledger place `0038_hook_jeton_foyer_absent` (version `20260921043316`) avant `0034_r2_stockage` (version `20260921043922`). L'ordre historique doit suivre la version du ledger et ses horodatages; un tri naïf par préfixe numérique local serait faux.

## Décision et suites B-01

1. Conserver les 51 fichiers `ccr` et les huit entrées PROD telles qu'observées; ne renommer, supprimer, marquer appliqué ou réparer aucune migration sur la seule base d'une ressemblance de nom.
2. Garder `0043`–`0048` identifiées comme présentes sur STAGING et absentes du ledger PROD. La différence nécessite une décision de migration séparée et un GO explicite inscrit dans « Journal distant » avant toute application PROD.
3. Rechercher des sources historiques exactes pour les huit entrées PROD supplémentaires, surtout les versions courtes 0006–0008 et `0011_presence_bornee_controleur_invisible`. Comparer les corps/empreintes à partir de sources de confiance avant de proposer un mapping.
4. Pour toute version sans correspondance résolue, maintenir B-01 ouvert/bloqué au regard de la « provenance exacte »; le rapport ne prétend ni à la parité de schéma ni à la complétude du manifest de corps SQL.

## Preuves et limites

Les comptes 50/76 et les noms ci-dessus proviennent de lectures live du ledger le 2026-10-10. Les 51 fichiers proviennent de l'inventaire Git `ccr@05e87f9`; le diff GitHub jusqu'à `ccr@5ea5e45` n'inclut aucun changement sous `supabase/migrations/`. L'état du code, le nom inscrit au ledger, la parité de corps SQL et le schéma runtime sont quatre preuves distinctes. Les vues, RPC, ACL et données runtime n'ont pas été auditées par le présent rapport.
