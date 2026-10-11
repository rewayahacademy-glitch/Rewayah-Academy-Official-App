CREATE OR REPLACE FUNCTION public.mon_fuseau()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(
    (select h.timezone from public.households h
      where h.id = public.app_household_id() and h.deleted_at is null),
    (select tp.timezone_iana from public.teacher_profiles tp
      where tp.profile_id = auth.uid() and tp.deleted_at is null),
    'Europe/Paris'
  );
$function$

