-- 0059 — canal de support minimal, configure par l'administration.
-- Le canal est absent par defaut; aucun ticket ni piece jointe n'est cree.
begin;

create or replace function public.canal_support()
returns table (nature text, adresse text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_valeur jsonb;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte inactif' using errcode = '42501';
  end if;

  select c.value into v_valeur
    from public.app_config c
   where c.key = 'support_canal';

  if pg_catalog.jsonb_typeof(v_valeur) = 'object'
     and v_valeur ->> 'type' in ('courriel', 'lien')
     and pg_catalog.length(pg_catalog.btrim(v_valeur ->> 'adresse')) > 0 then
    return query
      select v_valeur ->> 'type', pg_catalog.btrim(v_valeur ->> 'adresse');
  end if;
end;
$function$;

create or replace function public.configurer_canal_support(
  p_type text,
  p_adresse text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_adresse text := pg_catalog.btrim(p_adresse);
begin
  if not coalesce(
    public.app_account_valid() and public.app_role() = 'admin',
    false
  ) then
    raise exception 'configuration du support reservee a un admin actif'
      using errcode = '42501';
  end if;

  if p_type is null
     or p_type not in ('courriel', 'lien')
     or v_adresse is null
     or pg_catalog.length(v_adresse) > 320
     or v_adresse ~ '[[:cntrl:]]'
     or (p_type = 'courriel'
         and v_adresse !~ '^[A-Za-z0-9.!#$%&''*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
     or (p_type = 'lien'
         and v_adresse !~ '^https://[^[:space:]/]+(/[^[:space:]]*)?$') then
    raise exception 'canal de support invalide' using errcode = '22023';
  end if;

  insert into public.app_config (key, value)
  values ('support_canal', pg_catalog.jsonb_build_object(
    'type', p_type,
    'adresse', v_adresse
  ))
  on conflict (key) do update set value = excluded.value;
end;
$function$;

revoke all on function public.canal_support() from public, anon, authenticated, agent_ro;
grant execute on function public.canal_support() to authenticated;
revoke all on function public.configurer_canal_support(text, text)
  from public, anon, authenticated, agent_ro;
grant execute on function public.configurer_canal_support(text, text) to authenticated;

commit;
