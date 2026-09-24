---
name: feedback_double_chemin_execute_supabase
description: "Sur Supabase, une fonction de `public` reçoit EXECUTE par deux chemins ; les deux `revoke` sont nécessaires et seul `has_function_privilege` le voit"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e2950ba-0747-41f6-8536-5f29f4c607ad
  modified: 2026-09-20T02:37:25.146Z
---

Sur un projet Supabase, une fonction créée dans le schéma `public` reçoit
`EXECUTE` par **deux chemins indépendants** :

1. le défaut de PostgreSQL, qui l'accorde à `PUBLIC` (grantee 0) ;
2. un `alter default privileges ... grant execute on functions to anon,
   authenticated, service_role` posé par Supabase, qui donne à `anon` un droit
   **nominal**.

`revoke ... from public` ferme le premier et laisse le second.
`revoke ... from anon` ferme le second et laisse le premier.
**Aucune des deux formules ne suffit seule. Les deux sont nécessaires.**

**Why:** j'ai écrit dans la migration `0026` de Rewayah que « `revoke ... from
anon` ne retire rien ». C'était vrai de ce que je mesurais et faux comme règle :
le revoke `anon` avait bien retiré le droit nominal, et c'est le `PUBLIC` qui
restait. Une migration suivante (`0027`) n'a porté que `revoke ... from public`
et a laissé `anon` capable d'exécuter la fonction, avec un `revoke` qui se lisait
comme correct. Mesuré : `proacl = {postgres=X, anon=X/postgres, …}` et
`anon_peut = true`.

**How to apply:** après **chaque** création ou remplacement de fonction, écrire
les deux `revoke`, puis **mesurer** :

```sql
select has_function_privilege('anon', 'public.ma_fonction(uuid)', 'execute');
```

Ne jamais conclure depuis la relecture du `revoke` écrit dans le fichier : les
deux fautes se lisent comme du code correct. Ni `get_advisors` ni une relecture
attentive ne les voient — seule la mesure les voit. Vérifier
`pg_default_acl` une fois par projet dit lesquels des deux chemins sont armés.

Voir aussi [[feedback_agent_ro_jamais_sur_rpc_ecriture]] : même classe de faute,
même angle mort des advisors.
