CREATE OR REPLACE FUNCTION public.instant_creneau(p_weekday integer, p_hour integer, p_tz text, p_semaine_offset integer DEFAULT 0)
 RETURNS timestamp with time zone
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  WITH semaine AS (
    SELECT pg_catalog.date_trunc(
      'week', pg_catalog.now() AT TIME ZONE p_tz
    )::date AS lundi_local
  ), candidat AS (
    SELECT (
      s.lundi_local + (p_weekday - 1) + (p_semaine_offset * 7)
      + pg_catalog.make_interval(hours => p_hour)
    )::timestamp without time zone AS local
    FROM semaine s
  )
  SELECT (c.local + CASE
      WHEN p_semaine_offset = 0
       AND (c.local AT TIME ZONE p_tz) <= pg_catalog.now()
      THEN interval '7 days'
      ELSE interval '0 days'
    END) AT TIME ZONE p_tz
  FROM candidat c;
$function$

