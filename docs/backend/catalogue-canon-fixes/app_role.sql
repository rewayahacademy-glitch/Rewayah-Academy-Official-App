CREATE OR REPLACE FUNCTION public.app_role()
 RETURNS app_role
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'role', '')::public.app_role;
$function$

