CREATE OR REPLACE FUNCTION public.record_session_event(p_session_id uuid, p_profile_id uuid, p_event_type session_event_type, p_source text DEFAULT 'livekit_webhook'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  insert into public.session_events (session_id, profile_id, event_type, source)
  values (p_session_id, p_profile_id, p_event_type, p_source);
end;
$function$

