---
name: feedback_hook_jeton_null_ferme_tout_en_silence
description: to_jsonb et jsonb_set sont STRICTS - un hook de jeton Supabase qui rend NULL fait emettre un jeton sans revendication et ferme toutes les RLS sans aucune erreur
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fdb00ca8-c853-4e97-b470-cf9ab4128757
  modified: 2026-09-21T04:45:48.772Z
---

Quand une autorisation repose sur un claim du jeton, **la fonction qui pose ce claim est un point de défaillance unique et silencieux**. Si elle rend `NULL`, Supabase Auth émet quand même un jeton — simplement sans revendication — et *toutes* les policies qui lisent `app_role()` refusent, sans erreur, sans log, sans trace.

Cas réel (Rewayah, 21/09/2026). `custom_access_token_hook` posait :

```sql
claims := jsonb_set(claims, '{app_metadata, household_id}',
                    to_jsonb(v_profile.household_id::text));
```

`to_jsonb()` est **STRICT** : `to_jsonb(NULL::text)` rend SQL `NULL`, pas le jsonb `null`. `jsonb_set()` est **STRICT** aussi : une valeur `NULL` fait rendre `NULL` à tout l'appel. Donc, pour un profil sans foyer, `claims` devenait `NULL`, puis le `jsonb_set` final annulait le retour entier.

Symptôme : quatre enseignants bloqués neuf jours, **seize fichiers déposés dans le seau `kyc` et zéro ligne** dans `kyc_documents`. La policy de stockage compare `auth.uid()` au chemin et passait ; celle de la table passe par `app_role()` et fermait. Le seau existait, la policy était juste, le déclencheur ne refusait rien : **chaque maillon pris seul était correct.**

**Why :** le défaut était invisible à tous les niveaux sauf un. Il a survécu à la CI, à deux revues et à deux livraisons de rôle complet. La contrainte `profiles_household_required` autorise un foyer NULL pour exactement quatre rôles — `admin`, `accountant`, `controller`, `teacher` — et le tuteur, l'élève et l'unique admin de production avaient tous un foyer. **Le chemin par lequel l'application avait été essayée ne rencontrait jamais le défaut.**

**How to apply :**
1. Une fonction dont l'appelant ne sait pas lire l'échec ne doit **jamais** pouvoir rendre `NULL` — `return coalesce(..., event)` en dernier filet.
2. `coalesce(to_jsonb(x), 'null'::jsonb)` sur **chaque** valeur nullable qui entre dans un `jsonb_set`.
3. Une garde `jsonb_typeof(x) is null` ne voit que la clé **absente** ; écrire `coalesce(jsonb_typeof(x), 'absent') <> 'object'`.
4. Tester la chaîne **entière** (hook → `app_role()` → insertion réelle), jamais les maillons séparément — c'était le seul niveau où ce défaut existait.
5. Choisir les fixtures par **la contrainte qui autorise le cas limite**, pas par le rôle qu'on a sous la main : ici `profiles_household_required` désignait exactement la population touchée.
6. Après correction, **les jetons déjà émis restent muets** : le hook ne tourne qu'à l'émission. Il faut se reconnecter.

**Corrigé et APPLIQUÉ en production le 21/09/2026.** Mesure avant/après sur les quatre profils concernés, dans la même requête :

| | avant `0038` | après `0038` |
|---|---|---|
| le hook rend NULL | `true` (4/4) | `false` (4/4) |
| `app_role()` | `(NULL)` | `teacher` |
| insertion `kyc_documents` | `REFUSEE 42501` | `ACCEPTEE` |

Témoin négatif joué dans la même sonde : avec un jeton sans revendication, l'insertion est toujours refusée en `42501`. Tout annulé par un `raise` terminal, zéro résidu.

⚠ Piège de sonde à connaître : `insert ... returning <colonne>` déclenche AUSSI les policies **SELECT**. `kyc_documents` n'a aucune policy de lecture pour le titulaire (c'est voulu, il suit son dossier par `etat_dossier()`), donc un `returning` échoue en `42501` alors que l'insertion seule passe. J'ai d'abord cru à un second verrou. Sonder avec `returning 1` ou sans `returning`.

Même famille que [[feedback_porte_sql_exigence_positive]] : une inconnue qui traverse et ferme tout. Lié : [[rewayah_r2_integration_2026-09-21]], [[feedback_double_chemin_execute_supabase]], [[feedback_porte_serveur_doit_etre_confrontee_a_la_policy]].
