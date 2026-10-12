BEGIN;

-- Calcule une prochaine occurrence depuis un instant de reference fourni. Le
-- fuseau recu est celui de reference de la Classe; les foyers n'effectuent pas
-- un second calcul local, ils affichent l'instant UTC materalise par la Classe.
CREATE OR REPLACE FUNCTION public.instant_creneau_reference(
  p_weekday int,
  p_hour int,
  p_tz text,
  p_semaine_offset int,
  p_reference_at timestamptz
) RETURNS timestamptz
LANGUAGE sql STABLE SET search_path = ''
AS $function$
  WITH reference AS (
    SELECT pg_catalog.date_trunc(
      'week', p_reference_at AT TIME ZONE p_tz
    )::date AS lundi_local
  ), candidat AS (
    SELECT (
      r.lundi_local + (p_weekday - 1)
      + pg_catalog.make_interval(hours => p_hour)
    )::timestamp without time zone AS local
    FROM reference r
  ), prochaine AS (
    SELECT CASE
      WHEN c.local AT TIME ZONE p_tz <= p_reference_at
        THEN c.local + interval '7 days'
      ELSE c.local
    END AS local
    FROM candidat c
  )
  SELECT (p.local + (p_semaine_offset * interval '7 days')) AT TIME ZONE p_tz
  FROM prochaine p;
$function$;

REVOKE ALL ON FUNCTION public.instant_creneau_reference(int, int, text, int, timestamptz)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.instant_creneau_reference(int, int, text, int, timestamptz)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.instant_creneau(
  p_weekday int,
  p_hour int,
  p_tz text,
  p_semaine_offset int DEFAULT 0
) RETURNS timestamptz
LANGUAGE sql STABLE SET search_path = ''
AS $function$
  SELECT public.instant_creneau_reference(
    p_weekday, p_hour, p_tz, p_semaine_offset, pg_catalog.now()
  );
$function$;

DO $postflight$
BEGIN
  IF pg_catalog.to_regprocedure(
       'public.instant_creneau_reference(integer,integer,text,integer,timestamp with time zone)'
     ) IS NULL
     OR NOT pg_catalog.has_function_privilege(
       'authenticated',
       'public.instant_creneau_reference(integer,integer,text,integer,timestamp with time zone)',
       'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'anon',
       'public.instant_creneau_reference(integer,integer,text,integer,timestamp with time zone)',
       'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role',
       'public.instant_creneau_reference(integer,integer,text,integer,timestamp with time zone)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'instant_creneau_reference privilege postflight failed';
  END IF;
END
$postflight$;

COMMIT;
