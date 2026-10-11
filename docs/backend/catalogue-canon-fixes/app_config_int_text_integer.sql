CREATE OR REPLACE FUNCTION public.app_config_int(p_key text, p_defaut integer)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce((select c.value #>> '{}' from public.app_config c
                   where c.key = p_key)::int, p_defaut);
$function$

