CREATE OR REPLACE FUNCTION public.canal_support()
 RETURNS TABLE(nature text, adresse text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$

