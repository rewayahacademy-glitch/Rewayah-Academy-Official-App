CREATE OR REPLACE FUNCTION public.get_config(p_key text, p_default jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce((select value from public.app_config where key = p_key), p_default);
$function$

