CREATE OR REPLACE FUNCTION public.agent_jeton_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'agent_token_id', '')::uuid;
$function$

