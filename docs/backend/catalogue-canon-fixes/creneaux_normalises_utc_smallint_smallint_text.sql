CREATE OR REPLACE FUNCTION public.creneaux_normalises_utc(p_jours smallint[], p_heures smallint[], p_fuseau text)
 RETURNS TABLE(jour_iso smallint, heure_locale smallint)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_i integer;
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

  FOR v_i IN 1..cardinality(p_jours) LOOP
    IF p_jours[v_i] NOT BETWEEN 1 AND 7
       OR p_heures[v_i] NOT BETWEEN 0 AND 23 THEN
      RAISE EXCEPTION 'jour ou heure locale invalide';
    END IF;
    jour_iso := p_jours[v_i];
    heure_locale := p_heures[v_i];
    RETURN NEXT;
  END LOOP;
END;
$function$

