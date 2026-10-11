CREATE OR REPLACE FUNCTION public.session_has_participant(p_session_id uuid, p_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id and sp.profile_id = p_uid and sp.deleted_at is null
  );
$function$

