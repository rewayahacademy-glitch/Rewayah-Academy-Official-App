---
name: feedback_db_push_tue_le_job_et_les_fonctions_edge
description: "Une migration appliquée par le MCP Supabase est enregistrée sous une version HORODATÉE ; `supabase db push` ne reconnaît plus la numérotation du dépôt, s'arrête, et tue toutes les étapes suivantes du même job."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b30e2d16-b513-40af-a9aa-abfc569df7fe
  modified: 2026-09-21T06:39:26.074Z
---

Le dépôt numérote ses migrations `0001`…`0038`. Le MCP Supabase (`apply_migration`) les
enregistre dans `supabase_migrations.schema_migrations` sous une version **horodatée** :
`{"version":"20260921043922","name":"0034_r2_stockage"}`. Le nom du fichier survit, la version
non.

`supabase db push` compare les VERSIONS. Tout ce qui suit `0009` est alors vu comme « à insérer
avant la dernière migration distante » : la commande s'arrête. Dans un job CI où les migrations
précèdent les fonctions Edge, **tout ce qui vient après meurt avec elle**.

Mesuré sur Rewayah le 21/09/2026 : `origin/main` a reçu dix commits entre 01h43 et 04h56 ;
les six fonctions Edge en ligne portaient encore un `updated_at` du 06, du 12 et du
18 septembre. Aucune n'avait bougé. Quatre fonctions R2 versionnées n'avaient **jamais** été
déployées.

**Why:** l'étape qui échoue n'est pas celle qui manque. Le symptôme visible était « les
fonctions Edge ne sont pas à jour » ; la cause vivait deux lignes plus haut, dans une étape
dont personne ne lisait le journal. Un job qui enchaîne deux responsabilités sans rapport
transforme la panne de l'une en silence de l'autre.

**How to apply:**
- Ne pas mettre migrations et fonctions Edge dans le même job. Les fonctions suivent `main`,
  les migrations se déclenchent à la main.
- Pour savoir si une étape CI a tourné, **mesurer son effet**, pas son existence :
  un `updated_at` qui ne bouge pas après un push est une preuve, un workflow présent dans
  `.github/` n'en est pas une.
- `supabase functions deploy --no-verify-jwt` s'applique à **TOUTES** les fonctions du
  déploiement. L'option ouvrirait aux appels anonymes les sept fonctions qui exigent un jeton
  pour n'en ouvrir qu'une. Le cas particulier se déclare par fonction dans `supabase/config.toml`
  (`[functions.<nom>] verify_jwt = false`), jamais en ligne de commande. Contrôle qui le
  démontre sans lire les journaux : si `verify_jwt` vaut encore `true` sur les fonctions en
  ligne, c'est que l'option n'a jamais pris.
- Le MCP Supabase (`deploy_edge_function`) déploie sans la CLI et sans `SUPABASE_ACCESS_TOKEN` :
  passer chaque fichier avec son chemin relatif réel (`<fonction>/index.ts`, `_shared/**`) pour
  que les `import '../_shared/...'` résolvent. Coûteux en contexte — préférer
  `supabase login` puis `supabase functions deploy` quand l'opérateur est disponible.

Voir [[rewayah_chaine_deploiement_reparee_2026-09-21]] et
[[feedback_vercel_zero_config_ecrase_la_production]].
