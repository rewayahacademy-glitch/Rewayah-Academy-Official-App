# 0035, 0036, 0037 ne sont PAS appliquées en production — demande à leur auteur

**Écrit le 21 septembre 2026 par la session Claude Code qui a livré `0034` et `0038`.**
Ce fichier n'est pas une migration : la CLI Supabase ne lit que les `.sql`, il est
ici parce que c'est l'endroit où l'on regarde quand on touche à ces trois
fichiers. Supprime-le quand la question ci-dessous est tranchée.

## Ce que j'ai appliqué, et ce que je n'ai pas touché

Projet `gggmtelinlpseweouyav`. Avant mon passage, la dernière migration appliquée
était `0033_tc_vues_rpc_durcissement_grants`.

| Migration | Auteur | Appliquée ? |
|---|---|---|
| `0034_r2_stockage.sql` | moi | **oui**, le 21/09 |
| `0035_ressources_du_groupe_rejoue_visibilite.sql` | toi | **non** |
| `0036_observation_defauts_academie_et_plafond_visite_groupe.sql` | toi | **non** |
| `0037_entrer_observation_rend_l_enfant_concerne.sql` | toi | **non** |
| `0038_hook_jeton_foyer_absent.sql` | moi | **oui**, le 21/09 |

Je me suis arrêté à la limite de ton périmètre sur consigne explicite de
l'opérateur. Je n'ai ni appliqué, ni modifié, ni déplacé, ni renommé tes trois
fichiers, et je n'ai touché aucun des objets qu'ils redéfinissent.

## Appliquer les miennes hors ordre était sûr, et voici la mesure

J'ai vérifié qu'il n'existe **aucun chevauchement et aucune dépendance** entre nos
deux lots avant d'écrire quoi que ce soit :

- tes trois fichiers redéfinissent `ressources_du_groupe`,
  `definir_politique_observation_groupe`, `budget_observation` et
  `entrer_observation` ;
- `0034` et `0038` ne touchent aucun de ces quatre objets — `0038` ne contient que
  `custom_access_token_hook`, `0034` sept fonctions de stockage plus deux colonnes
  sur `session_recordings` et une sur `kyc_documents` ;
- aucun des deux ne mentionne un seul de tes quatre objets.

La même mesure vaut dans l'autre sens : **tes trois migrations restent applicables
telles quelles, dans n'importe quel ordre, sans rien rejouer de mon côté.**

## Ce que ça coûte aujourd'hui

Tes quatre objets existent déjà en production, dans la version posée par
`0030`–`0033`. Autrement dit : **les fonctions tournent, mais avec les défauts que
tes trois migrations corrigent.** Ce n'est pas un état neutre. Si `0036` corrige
bien un plafond de visite et un défaut d'académie, ces défauts sont vivants en
production en ce moment.

## La question

**Veux-tu que j'applique `0035`, `0036` et `0037` pour toi ?**

L'opérateur m'y autorise à condition que ça vienne de toi. Réponds en ajoutant une
ligne sous ce paragraphe, ou en le faisant toi-même et en supprimant ce fichier :

```
REPONSE : oui, applique-les  /  non, je m'en occupe  /  pas encore, elles ne sont pas prêtes
```

## Deux précisions utiles avant un `supabase db push`

1. **Le journal de migrations enregistre mes deux lots sous un horodatage, pas sous
   `0034`/`0038`.** C'est ainsi que `apply_migration` du MCP écrit. Un `db push`
   depuis le dépôt voudra donc les repousser, puisqu'il ne verra pas les versions
   `0034` ni `0038` côté distant. Ce n'est pas un danger : les deux sont
   idempotentes — `0038` n'est qu'un `create or replace function`, et `0034`
   n'emploie que `add column if not exists`, `create index if not exists`, une
   contrainte gardée par un `do $$` et des `create or replace`. Les rejouer ne
   casse rien. Je n'ai volontairement pas fabriqué de fausses lignes de version
   pour masquer l'écart.
2. **Rien n'est poussé sur `origin`.** Mes deux commits (`5a78726` R2, `1355669`
   hook) sont locaux. Un `git push` les emportera en même temps que ton travail.

## Et pendant que tu es là : deux choses mesurées qui te concernent peut-être

1. `custom_access_token_hook` rendait `NULL` pour tout profil sans foyer
   (`to_jsonb` et `jsonb_set` sont STRICTS). Auth émettait alors un jeton **sans
   revendication**, `app_role()` rendait `NULL`, et toute policy qui en dépend se
   fermait sans erreur ni trace. Conséquence mesurée : **les rôles enseignant et
   contrôleur étaient inertes en production depuis leur livraison** (20/09 et
   13/09). Corrigé par `0038`. Si tu travailles sur l'observation contrôleur, tes
   essais en production avant aujourd'hui ne prouvaient rien.
2. Les jetons déjà émis restent muets : le hook ne tourne qu'à l'émission. **Il
   faut se reconnecter** pour que le correctif prenne effet sur un compte.
