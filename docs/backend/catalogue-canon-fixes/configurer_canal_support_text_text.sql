CREATE OR REPLACE FUNCTION public.configurer_canal_support(p_type text, p_adresse text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$

