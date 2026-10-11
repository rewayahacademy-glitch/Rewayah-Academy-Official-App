CREATE OR REPLACE FUNCTION public.app_household_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'household_id', '')::uuid;
$function$

