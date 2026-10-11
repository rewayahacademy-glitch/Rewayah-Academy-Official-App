CREATE OR REPLACE FUNCTION public.session_in_household(p_session_id uuid, p_household_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.session_participants sp
    join public.profiles p on p.id = sp.profile_id
    where sp.session_id = p_session_id and sp.deleted_at is null
      and p.household_id = p_household_id and p.deleted_at is null
  );
$function$

