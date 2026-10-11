CREATE OR REPLACE FUNCTION public.agent_jeton_vivant(p_id uuid)
 RETURNS jetons_agent
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select t.*
  from public.jetons_agent t
  where t.id = p_id
    and t.revoque_le is null
    and t.expire_le > now();
$function$

