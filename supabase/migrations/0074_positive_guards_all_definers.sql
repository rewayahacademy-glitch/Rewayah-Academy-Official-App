-- 0074 — convertir les comparaisons de rôles négatives en gardes positives.
-- Le balayage couvre les fonctions SECURITY DEFINER de public et app_private,
-- sans dépendre d'une forme IF sur une seule ligne. Une comparaison non
-- transformée fait échouer la migration.
begin;

create or replace function app_private.has_unsafe_role_guard(p_definition text)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $function$
  select coalesce(
    p_definition ~*
      '(app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]*(<>|!=)[[:space:]]*''[^'']+''|app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]+not[[:space:]]+in[[:space:]]*[(]|''[^'']+''[[:space:]]*(<>|!=)[[:space:]]*app_role[[:space:]]*[(][[:space:]]*[)])',
    false
  );
$function$;
revoke all on function app_private.has_unsafe_role_guard(text) from public;
revoke all on function app_private.has_unsafe_role_guard(text) from anon, authenticated, agent_ro;

do $migration$
declare
  v record;
  v_definition text;
  v_corrigee text;
  v_modifiees integer := 0;
begin
  for v in
    select p.oid
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'app_private')
      and p.prokind = 'f'
      and p.prosecdef
      and app_private.has_unsafe_role_guard(p.prosrc)
  loop
    v_definition := pg_catalog.pg_get_functiondef(v.oid);

    -- Rôle requis et compte valide : toute valeur NULL devient un refus.
    v_corrigee := pg_catalog.regexp_replace(
      v_definition,
      '(?i)(public[.])?app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]*(<>|!=)[[:space:]]*''([^'']+)''',
      E'NOT coalesce(public.app_role() = ''\\3'' AND public.app_account_valid(), false)',
      'gi'
    );

    v_corrigee := pg_catalog.regexp_replace(
      v_corrigee,
      '(?i)(public[.])?app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]+NOT[[:space:]]+IN[[:space:]]*[(]([^)]*)[)]',
      E'NOT coalesce(public.app_role() IN (\\2) AND public.app_account_valid(), false)',
      'gi'
    );

    v_corrigee := pg_catalog.regexp_replace(
      v_corrigee,
      '(?i)''([^'']+)''[[:space:]]*(<>|!=)[[:space:]]*(public[.])?app_role[[:space:]]*[(][[:space:]]*[)]',
      E'NOT coalesce(public.app_role() = ''\\1'' AND public.app_account_valid(), false)',
      'gi'
    );

    if v_corrigee = v_definition then
      raise exception '0074: comparaison négative non transformée dans la fonction oid=%', v.oid;
    end if;

    execute v_corrigee;
    v_modifiees := v_modifiees + 1;
  end loop;

  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'app_private')
      and p.prokind = 'f'
      and p.prosecdef
      and app_private.has_unsafe_role_guard(p.prosrc)
  ) then
    raise exception '0074: une comparaison négative subsiste dans une fonction SECURITY DEFINER';
  end if;

  raise notice '0074: % fonctions SECURITY DEFINER mises à garde positive', v_modifiees;
end
$migration$;

commit;
