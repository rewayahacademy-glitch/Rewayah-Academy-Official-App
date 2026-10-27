-- Fraicheur (27/10/2026) : les quatre tables des classes et des seances sont
-- protegees par la RLS, gardent l'identite de replication par defaut (la
-- suppression ne transmet que la cle primaire, jamais la ligne), et, quand
-- la publication supabase_realtime existe, y figurent toutes les quatre.
-- Base PostgreSQL jetable apres rejeu des migrations : sans publication, le
-- scenario ne verifie que la RLS et l'identite de replication.
begin;

do $fraicheur_realtime$
declare
  v_table text;
  v_relreplident "char";
  v_publication boolean;
begin
  v_publication := exists (
    select 1 from pg_catalog.pg_publication p where p.pubname = 'supabase_realtime'
  );
  foreach v_table in array array['groupes', 'groupe_membres', 'groupe_creneaux', 'sessions']
  loop
    if not exists (
      select 1 from pg_catalog.pg_class c
        join pg_catalog.pg_namespace n on n.oid = c.relnamespace
       where n.nspname = 'public' and c.relname = v_table and c.relrowsecurity
    ) then
      raise exception 'FRAICHEUR: % sans RLS', v_table;
    end if;

    select c.relreplident into v_relreplident
      from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relname = v_table;
    if v_relreplident is distinct from 'd' then
      raise exception 'FRAICHEUR: % a une identite de replication % (attendu : d, la cle primaire seule)',
        v_table, v_relreplident;
    end if;

    if v_publication and not exists (
      select 1 from pg_catalog.pg_publication_tables p
       where p.pubname = 'supabase_realtime'
         and p.schemaname = 'public'
         and p.tablename = v_table
    ) then
      raise exception 'FRAICHEUR: % absente de supabase_realtime', v_table;
    end if;
  end loop;
end;
$fraicheur_realtime$;

rollback;
