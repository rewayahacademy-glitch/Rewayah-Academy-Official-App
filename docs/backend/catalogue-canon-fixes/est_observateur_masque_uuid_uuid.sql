CREATE OR REPLACE FUNCTION public.est_observateur_masque(p_session_id uuid, p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.session_participants sp
    where sp.session_id = p_session_id
      and sp.profile_id = p_profile_id
      and sp.role in ('masked_controller', 'admin_masked', 'guardian_observer')
      and sp.deleted_at is null
  );
$function$

