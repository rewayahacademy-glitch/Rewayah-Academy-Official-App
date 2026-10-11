CREATE OR REPLACE FUNCTION public.heures_locales_valides(p_heures smallint[])
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT p_heures IS NOT NULL
     AND coalesce(array_length(p_heures, 1), 0) > 0
     AND NOT EXISTS (
       SELECT 1 FROM unnest(p_heures) h
       WHERE h IS NULL OR h < 0 OR h > 23
     );
$function$

