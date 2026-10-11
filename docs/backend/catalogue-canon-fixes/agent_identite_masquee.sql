CREATE OR REPLACE FUNCTION public.agent_identite_masquee()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(
    (select t.identite_masquee
       from public.jetons_agent t
      where t.id = public.agent_jeton_id()),
    -- Session agent dont la ligne a disparu : on masque.
    public.agent_jeton_id() is not null
  );
$function$

