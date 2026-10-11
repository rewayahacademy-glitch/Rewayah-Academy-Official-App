CREATE OR REPLACE FUNCTION public.maintenant_serveur()
 RETURNS timestamp with time zone
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$ select now() $function$

