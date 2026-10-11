# SEC-PROD-27 — revue des fonctions SECURITY DEFINER

Date : 2026-10-12  
Branche : `codex/backend-sec-prod-27-invoker`

## Portée vérifiée dans ce lot

Les six fonctions ci-dessous sont des déclencheurs de garde. Leur corps ne lit
ni n'écrit de table : il vérifie `OLD` et `NEW` et utilise des fonctions de
`pg_catalog`. Elles n'ont donc pas besoin d'emprunter les droits de leur
propriétaire. La migration les passe en `SECURITY INVOKER`; la migration et le
scénario B-18 vérifient `prosecdef = false`.

| Fonction | Invariant conservé | Pourquoi INVOKER suffit |
| --- | --- | --- |
| `guard_audit_logs_immutable()` | Interdit les mutations et suppressions du journal d'audit. | Compare seulement les valeurs `OLD` et `NEW`. |
| `guard_contract_acceptances_immutable()` | Protège les acceptations de contrat immuables. | Compare seulement les valeurs `OLD` et `NEW`. |
| `guard_profile_immutable_id()` | Empêche la modification de l'identifiant immuable du profil. | Compare seulement les valeurs `OLD` et `NEW`. |
| `guard_session_state_transition()` | Refuse les transitions d'état de séance non prévues. | Valide seulement l'état avant et après la mutation. |
| `guard_rule_override_immutable()` | Empêche la réécriture des décisions d'override. | Compare seulement les valeurs `OLD` et `NEW`. |
| `guard_prayer_adjustments()` | Protège les ajustements de prière contre les changements interdits. | Valide seulement les valeurs `OLD` et `NEW`. |

Le scénario B-18 teste leur attribut catalogue en plus des scénarios fonctionnels
existants. La migration conserve les triggers et leurs corps.

## Limite de preuve sur les 19 autres fonctions

La revue Claude du 2026-10-12 demande aussi de justifier 19 fonctions
`SECURITY DEFINER` conservées, mais ne fournit ni leurs signatures ni leur
empreinte de catalogue. Le worktree local ne contient pas de rejeu PG16; les
fichiers source seuls ne permettent pas d'établir cette liste de façon fiable
après réapplication de toutes les migrations. Le snapshot `PROD_SECURITY_SNAPSHOT_2026-10-10.md`
décrit un catalogue antérieur et ne prouve pas l'état de cette branche.

Je ne qualifie donc pas arbitrairement 19 fonctions de « conservées » et ne
présente pas de justifications non recoupées. Pour compléter ce tableau au
rejeu isolé, relever les identités, propriétaires, `prosecdef`, `proconfig`,
ACL et empreintes avec :

```sql
select p.oid::regprocedure as signature,
       pg_catalog.pg_get_userbyid(p.proowner) as owner,
       p.prosecdef,
       p.proconfig,
       md5(pg_catalog.pg_get_functiondef(p.oid)) as md5_functiondef,
       p.prosrc
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.prosecdef
 order by p.oid::regprocedure::text;
```

Statut : six transitions invoker documentées et testées statiquement; les 19
justifications individuelles et leur identité catalogue restent `NON PROUVÉ`.
