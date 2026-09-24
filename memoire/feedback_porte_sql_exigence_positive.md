---
name: feedback_porte_sql_exigence_positive
description: "Une porte SQL écrite en refus (`if role <> 'x' then raise`) s'ouvre pour l'appelant anonyme, car NULL ne déclenche pas le `if`"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0e2950ba-0747-41f6-8536-5f29f4c607ad
  modified: 2026-09-20T03:44:09.764Z
---

Un garde-fou SQL écrit comme un **refus** échoue ouvert pour l'appelant qui n'a
pas de rôle :

```sql
-- FAUX : pour anon, app_role() rend NULL, NULL <> 'admin' vaut NULL,
-- et `if NULL then` ne se declenche pas. La fonction continue.
if public.app_role() <> 'admin' then raise exception '...'; end if;

-- JUSTE : toute inconnue ferme la porte.
if not coalesce(public.app_role() = 'admin', false) then
  raise exception '...' using errcode = '42501';
end if;
```

**Why:** trouvé deux fois sur Rewayah. Dans `brouillon_cahier` (ma propre
migration `0025`), où la porte ne se fermait que par accident parce qu'une autre
fonction du `or` rendait un `false` franc — un garde-fou qui dépend du fait
qu'une **autre** fonction ne rende jamais NULL n'est pas un garde-fou. Puis dans
`dossiers_en_attente()` (lot antérieur), où rien ne rattrapait le NULL : mesuré,
`set local role anon; select count(*) from public.dossiers_en_attente()` rendait
**4 lignes** portant prénom, nom de famille et identifiant immuable de chaque
personne en attente de vérification. La fonction étant `security definer`, elle
lisait `profiles` avec les droits du propriétaire, RLS comprise. La clé publiable
`anon` est embarquée dans le bundle web servi : la porte était joignable sans
aucun compte.

**How to apply:** écrire toute porte en **exigence positive enveloppée de
`coalesce(..., false)`**, jamais en refus. Et la mesurer en rôle `anon` :

```sql
do $$ declare v_msg text; begin
  begin set local role anon; perform public.ma_fonction(); v_msg := 'PASSE';
  exception when others then v_msg := 'REFUSE ' || sqlstate; end;
  reset role; raise notice '%', v_msg;
end $$;
```

Balayage utile sur un schéma existant : `pg_proc.prosrc like '%app_role() <>%'`
croisé avec `has_function_privilege('anon', oid, 'execute')`. Sur Rewayah,
31 fonctions portaient la forme fragile ; une seule était atteignable par `anon`.

**La loi qui explique pourquoi une seule fuyait** — mesurée le 20/09 en
rebalayant tout ce qu'un anonyme peut atteindre, et c'est elle qu'il faut
retenir :

> Une porte posée dans un `where` échoue **fermée**.
> Une porte posée en `if … then raise` échoue **ouverte**.

`NULL = 'admin'` dans un `where` ne rend aucune ligne ; `if NULL then raise` ne se
déclenche pas et laisse couler. Les 30 autres fonctions portaient leur porte dans
un `where` (`language sql stable`, la porte est une clause de la requête) : sûres
**par construction**. `dossiers_en_attente()` était la seule en plpgsql avec un
`if` — d'où la seule fuite. Donc : en `sql`/`where`, la forme en refus est
tolérable ; en **plpgsql**, elle est un défaut, toujours.

**Vérification en grandeur réelle (20/09, `0021`–`0024`)** : huit portes
réécrites en exigence positive puis appliquées, et mesurées en rôle
`authenticated` **sans jeton** — les huit refusent en `P0001` avec leur propre
message. Les quatre lectures de ces mêmes migrations, portant leur porte dans un
`where`, passent et rendent **0 ligne**. C'est la loi observée des deux côtés
dans un même lot. La mesure utile n'est donc pas « en rôle `anon` » (le `revoke`
répond avant la porte, en `42501 permission denied`), mais **en rôle
`authenticated` sans jeton** : c'est le seul appelant qui franchit le droit
d'EXECUTE avec un `app_role()` NULL, donc le seul qui teste la porte elle-même.

Corollaire de méthode : balayer par `prosrc` répond « qui porte la forme », pas
« qui fuit ». La seule mesure qui répond est d'**appeler la cible en rôle `anon`
avec de vraies clés** et de compter les lignes. C'est aussi le seul moyen de
trancher sur une vue : `security_barrier=true` **n'est pas**
`security_invoker=true` — sans le second, la vue lit avec les droits de son
propriétaire, RLS contournée, et sa sûreté ne tient plus qu'à son `where`.

Compléter par [[feedback_double_chemin_execute_supabase]] : la porte et le
`revoke` sont deux défenses, et il faut les deux.
