---
name: feedback_creer_groupe_surchargee_appel_ambigu
description: "Sur Rewayah, creer_groupe existe en deux surcharges 6 et 8 arguments — tout appel positionnel à 6 arguments est ambigu et échoue à l'exécution"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ac703dcf-56dc-4a00-be1c-cac6c196bdfd
  modified: 2026-09-22T06:06:18.283Z
---

`public.creer_groupe` existe en **deux surcharges** dans la base Rewayah :

- 6 paramètres, dont **1** par défaut (accepte donc 5 ou 6 arguments) ;
- 8 paramètres, dont **3** par défaut (accepte donc 5, 6, 7 ou 8 arguments).

Les six premiers portent **exactement les mêmes types** dans les deux. Un appel
positionnel à 5 ou 6 arguments est donc **ambigu**, et PostgreSQL le refuse à
l'exécution : `function creer_groupe(...) is not unique`.

**Why:** ce n'est visible ni à la création de la fonction, ni à l'analyse
statique, ni par `get_advisors`. Ça n'échoue qu'au moment de l'appel — c'est-à-
dire, pour `publier_groupe_depuis_offre`, au moment précis où l'académie
publierait son premier groupe. Trouvé le 22/09/2026 en relisant ma propre
migration `0043` avant de l'appliquer, en interrogeant
`pg_proc.pronargs` / `pronargdefaults` plutôt qu'en lisant
`pg_get_function_identity_arguments`, qui ne montre pas les valeurs par défaut.

**How to apply:** appeler `creer_groupe` en **arguments nommés**, en incluant
`p_timezone_iana` — ce nom n'existe que dans la surcharge à huit et désigne donc
une seule candidate. Plus généralement, avant d'appeler une fonction SQL
existante depuis une migration de ce dépôt, vérifier
`select pronargs, pronargdefaults from pg_proc where proname = '<nom>'` : s'il y
a plusieurs lignes, n'appeler qu'en arguments nommés.

Même famille de piège que [[feedback_double_chemin_execute_supabase]] et
[[feedback_porte_sql_exigence_positive]] : invisible à la relecture, mesurable
en une requête.
