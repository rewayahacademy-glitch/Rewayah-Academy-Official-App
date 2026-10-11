CREATE OR REPLACE FUNCTION public.app_est_agent()
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select public.agent_jeton_id() is not null;
$function$

