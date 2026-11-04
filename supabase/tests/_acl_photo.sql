-- Les droits globaux ci-dessous reproduisent les privilèges par défaut de
-- Supabase, mais ils arrivent APRÈS les migrations et annulent leurs REVOKE
-- explicites. La CI rejoue tous les scénarios sur la même base : un scénario qui
-- élargit les droits inclut ce fichier avant ses grants et _acl_retablir.sql à la
-- fin, sinon les suivants (C-21, C-35...) voient tomber des invariants de production.
create temp table acl_avant_scenario as
  select case c.relkind when 'S' then 'sequence' else 'table' end as genre,
         c.oid, c.relacl as acl
    from pg_catalog.pg_class c
   where c.relnamespace = 'public'::regnamespace
     and c.relkind in ('r', 'v', 'm', 'p', 'S', 'f')
  union all
  select 'fn', p.oid, p.proacl
    from pg_catalog.pg_proc p
   where p.pronamespace = 'public'::regnamespace and p.prokind in ('f', 'p');

-- Droits par colonne (rang 19 B, 03/11/2026) : « revoke all on table », dans
-- _acl_retablir.sql, retire aussi les droits par colonne. Sans cette seconde
-- photographie, les grants par colonne des migrations (groupes,
-- contract_acceptances, student_profiles...) disparaissaient pour tous les
-- scénarios suivants de la même base.
create temp table acl_colonnes_avant_scenario as
  select a.attrelid as oid, a.attname, a.attacl as acl
    from pg_catalog.pg_attribute a
    join pg_catalog.pg_class c on c.oid = a.attrelid
   where c.relnamespace = 'public'::regnamespace
     and c.relkind in ('r', 'v', 'm', 'p', 'f')
     and a.attnum > 0 and not a.attisdropped
     and a.attacl is not null;
