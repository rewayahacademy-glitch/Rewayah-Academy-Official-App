CREATE OR REPLACE FUNCTION public.cle_horaire_utc(p_jours smallint[], p_heures smallint[], p_fuseau text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_cle text;
  v_offset_hiver integer;
  v_offset_ete integer;
BEGIN
  IF p_jours IS NULL OR p_heures IS NULL
     OR cardinality(p_jours) = 0
     OR cardinality(p_jours) <> cardinality(p_heures)
     OR p_fuseau IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_fuseau
     ) THEN
    RAISE EXCEPTION 'créneaux ou fuseau invalides';
  END IF;

  SELECT extract(epoch FROM (
           (timestamp '2026-01-15 12:00:00' AT TIME ZONE 'UTC')
           - (timestamp '2026-01-15 12:00:00' AT TIME ZONE p_fuseau)
         ))::integer,
         extract(epoch FROM (
           (timestamp '2026-07-15 12:00:00' AT TIME ZONE 'UTC')
           - (timestamp '2026-07-15 12:00:00' AT TIME ZONE p_fuseau)
         ))::integer
    INTO v_offset_hiver, v_offset_ete;

  SELECT v_offset_hiver::text || ':' || v_offset_ete::text || '|' ||
      pg_catalog.string_agg(
        pg_catalog.lpad(c.jour::text, 2, '0') || ':' ||
          pg_catalog.lpad(c.heure::text, 2, '0'),
        ',' ORDER BY c.jour, c.heure
      )
    INTO v_cle
    FROM unnest(p_jours, p_heures) AS c(jour, heure);
  RETURN v_cle;
END;
$function$

