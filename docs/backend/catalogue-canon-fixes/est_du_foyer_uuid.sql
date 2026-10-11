CREATE OR REPLACE FUNCTION public.est_du_foyer(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.profiles p
    where p.id = p_profile_id
      and p.household_id = public.app_household_id()
      and p.deleted_at is null
  )
$function$

