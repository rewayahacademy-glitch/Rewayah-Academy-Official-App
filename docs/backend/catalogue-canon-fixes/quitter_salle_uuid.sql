CREATE OR REPLACE FUNCTION public.quitter_salle(p_session_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not public.session_has_participant(p_session_id, auth.uid()) then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  insert into public.session_events (session_id, profile_id, event_type, source)
  values (p_session_id, auth.uid(), 'left', 'user_action');
end;
$function$

