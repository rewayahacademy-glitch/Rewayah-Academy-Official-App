CREATE OR REPLACE FUNCTION public.jours_iso_valides(p_jours smallint[])
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT p_jours IS NOT NULL
     AND coalesce(array_length(p_jours, 1), 0) BETWEEN 1 AND 7
     AND NOT EXISTS (
       SELECT 1 FROM unnest(p_jours) AS j
       WHERE j IS NULL OR j < 1 OR j > 7
     )
     AND coalesce(array_length(p_jours, 1), 0) =
         (SELECT count(DISTINCT j) FROM unnest(p_jours) AS j);
$function$

