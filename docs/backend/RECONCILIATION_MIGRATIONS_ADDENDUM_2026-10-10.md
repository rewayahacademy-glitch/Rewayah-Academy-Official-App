# Addendum B-01 — correspondance des entrées PROD sans homonyme (2026-10-10)

Branche : `codex/backend-lota-ledger-provenance`, créée depuis `ccr-1b1bfa0b-m1kvkk` à `f340a0c124ba37cf39882a1a8271c15ef43c39f3`.

## Portée et méthode

Vérification en lecture seule du ledger `supabase_migrations.schema_migrations` de PROD (`gggmtelinlpseweouyav`, URL vérifiée : `https://gggmtelinlpseweouyav.supabase.co`). Les requêtes ont lu uniquement les versions, noms et corps SQL de cinq entrées nommées, puis la présence de corps pour les versions courtes 0006–0008. Aucun schéma, ledger ou donnée métier n'a été modifié.

Les corps SQL du ledger ont été comparés aux fichiers locaux après retrait des commentaires et des espaces inter-token, en conservant les littéraux, les identifiants cités et les corps dollar-quoted. C'est une comparaison de contenu observé, pas une preuve de provenance de déploiement indépendante du ledger.

## Résultat vérifié

| Entrée PROD | Corps ledger | Source locale comparée | Résultat |
|---|---:|---|---|
| `20260912212505 / 0011_presence_bornee_controleur_invisible` | 2 344 caractères, 1 instruction | `supabase/migrations/0011_presence_bornee.sql`, blob `40df0e22cb5a5276c30199d3f179c0ad2becd5fe` sur ccr ; candidat historique `0011_presence_bornee.sql` à `0bfc9e46c0ddc4a013273b8ced8a49791e327ba8`, blob `e6b7e9c37aebf9e46facc49b29cc57c469f1530d` | Les deux sources donnent l'égalité normalisée exacte avec le corps du ledger. Cette entrée n'est plus « sans homonyme fiable » pour le rapprochement de corps. |
| `20260912025111 / 0006_init` | 923 caractères, 1 instruction | `0006_rattrapage_semaine_utc_et_foyer.sql`, blob `ff26f06a17b5797198a3b37bb206f464927842bd` | Différent après normalisation. |
| `20260912025141 / 0007_init` | 11 575 caractères, 1 instruction | `0007_coran_structure_position_presence.sql`, blob `ee0b87b3c4f90654bc3c4662fca5ff1ee05a553c` | Différent après normalisation. |
| `20260912025212 / 0008_init` | 6 598 caractères, 1 instruction | `0008_attribution_manuelle.sql`, blob `24a9f3f3b3827c58cb2a0f5c580770209486d12b` | Différent après normalisation. |
| `20260912025400 / record_0006_0007_0008_versions` | 129 caractères, 1 instruction | Aucun fichier de migration correspondant retrouvé dans ccr | L'instruction insère uniquement les versions courtes `0006`, `0007`, `0008` dans le ledger, avec `ON CONFLICT DO NOTHING`. Elle n'est pas le contenu des migrations métier. |

Les entrées courtes `0006`, `0007`, `0008` existent séparément dans le ledger avec nom NULL, `statements IS NULL` et zéro instruction. Leur SQL appliqué n'est donc pas récupérable à partir de ces trois lignes.

## État B-01 après cette vérification

Une des huit entrées PROD précédemment sans source fiable (`0011_presence_bornee_controleur_invisible`) a maintenant une correspondance de corps au fichier ccr `0011_presence_bornee.sql`. Sept restent sans source exacte : les trois entrées courtes sans corps, les trois corps `0006_init`–`0008_init` différents des fichiers actuels, et l'instruction d'enregistrement `record_0006_0007_0008_versions` sans fichier source local.

Aucune entrée ni migration n'a été réparée, renommée ou réappliquée. Les fichiers 0043–0048 présents à STAGING et absents du ledger PROD restent un écart distinct. La clôture de B-01 exige toujours la récupération/provenance des corps manquants, le rejeu complet PostgreSQL 17 frais et les scénarios. STAGING, dont le ledger courant atteint 0074, n'est pas la cible vierge compatible avec le préflight du candidat SEC-PROD qui attend le ledger PROD 0042.

Aucun GO d'exécution PROD n'est demandé ni implicite dans cet addendum.


## Vérification complémentaire de l'historique GitHub (2026-10-10)

L'API GitHub des commits par chemin retourne un commit source pour chaque fichier candidat courant, et aucun fichier `0006_init.sql` ni `record_0006_0007_0008_versions.sql` dans l'historique interrogé :

| Migration PROD | Commit qui introduit le fichier candidat | Portée de la preuve historique |
|---|---|---|
| `0006_init` | `9f92a0aea9c37881a80d8df83ff194c43e03e964`, fichier blob `17ddf39bf625710377bbf215d983aff54c920cc7` | Le message décrit la migration de rattrapage. Le diff dit explicitement que son application au projet réel reste à faire, car `db push` est bloqué. Le corps de ce fichier reste différent du corps PROD `0006_init` après normalisation. |
| `0007_init` | `a736a43580deea36c50656801d2d6324ed761749`, fichier blob `9701feba4dc31b8dde1b17553e59e9080f92fff3` | Le message documente le lot N1 et ses scénarios de test; il ne nomme pas un déploiement PROD. Le corps reste différent de `0007_init`. |
| `0008_init` | `1eddc9ca8f2736bead401adddea0fa45f68a8a58`, fichier blob `f4257f473f5664c797df04e031e516f8dcad56bc` | Le message documente le lot ADM-05 et un rejeu SQL 0001–0008 sur une base; il n'identifie pas cette base comme PROD. Le corps reste différent de `0008_init`. |

Cette chronologie réduit l'ensemble des sources candidates mais ne prouve pas quel artefact a été exécuté pour créer les entrées PROD. Le commit 0006 prouve même qu'à son propre instant l'application réelle était annoncée comme restante; il ne permet pas d'exclure une application manuelle ultérieure. La clôture de provenance exige toujours un enregistrement d'exécution ou une source d'archive qui corresponde au corps PROD, pas seulement un commit proche dans le temps.
