CREATE OR REPLACE FUNCTION public.traduire_occurrences_fuseau(p_jours smallint[], p_heures smallint[], p_fuseau_source text, p_fuseau_destination text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  IF p_jours IS NULL OR p_heures IS NULL
     OR cardinality(p_jours) = 0
     OR cardinality(p_jours) <> cardinality(p_heures)
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names
       WHERE name = p_fuseau_source
     )
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names
       WHERE name = p_fuseau_destination
     ) THEN
    RAISE EXCEPTION 'créneaux ou fuseaux invalides';
  END IF;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'jour_iso', extract(isodow FROM c.heure_locale_destination)::integer,
        'heure', extract(hour FROM c.heure_locale_destination)::integer,
        'minute', extract(minute FROM c.heure_locale_destination)::integer,
        'decalage_jour',
          (c.heure_locale_destination::date - c.heure_locale_source::date)::integer
      )
      ORDER BY c.position
    ),
    '[]'::jsonb
  )
  INTO v_result
  FROM (
    SELECT
      p.position,
      p.heure_locale_source,
      (p.heure_locale_source AT TIME ZONE p_fuseau_source)
        AT TIME ZONE p_fuseau_destination AS heure_locale_destination
    FROM (
      SELECT
        i AS position,
        (
          date_trunc('week', pg_catalog.now() AT TIME ZONE p_fuseau_source)::date
          + (p_jours[i] - 1)
          + pg_catalog.make_interval(hours => p_heures[i])
        )::timestamp without time zone AS heure_locale_source
      FROM pg_catalog.generate_subscripts(p_jours, 1) AS positions(i)
    ) AS p
  ) AS c;
  RETURN v_result;
END;
$function$

