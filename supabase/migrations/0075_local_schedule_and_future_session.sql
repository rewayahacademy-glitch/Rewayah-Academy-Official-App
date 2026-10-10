-- 0075 — préserver l'heure murale, rendre les clés indépendantes de now(),
-- commencer à la prochaine séance future et notifier dans le fuseau du foyer.
BEGIN;

-- Les tableaux restent dans le fuseau IANA demandé. La conversion à un offset
-- UTC calculé cette semaine n'est pas une clé stable aux changements DST.
CREATE OR REPLACE FUNCTION public.creneaux_normalises_utc(
  p_jours smallint[],
  p_heures smallint[],
  p_fuseau text
) RETURNS TABLE (jour_iso smallint, heure_locale smallint)
LANGUAGE plpgsql STABLE SET search_path = ''
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
$function$;

CREATE OR REPLACE FUNCTION public.cle_horaire_utc(
  p_jours smallint[],
  p_heures smallint[],
  p_fuseau text
) RETURNS text
LANGUAGE plpgsql STABLE SET search_path = ''
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
$function$;

DO $migration$
DECLARE
  v_oid oid := 'public.regroupements_demandes_horaires_admin()'::regprocedure;
  v_definition text;
  v_old text;
  v_new text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  v_old := $pattern$case when p.source = 'offre' then p.fuseau_offre else 'UTC' end as fuseau_groupe$pattern$;
  v_new := $replacement$case when p.source = 'offre' then p.fuseau_offre else p.fuseau_iana end as fuseau_groupe$replacement$;
  v_definition := pg_catalog.replace(v_definition, v_old, v_new);
  IF v_definition = pg_catalog.pg_get_functiondef(v_oid) THEN
    RAISE EXCEPTION 'M-a : fuseau local du regroupement introuvable';
  END IF;
  EXECUTE v_definition;
END
$migration$;

DO $migration$
DECLARE
  v_oid oid := 'public.regroupements_demandes_horaires_admin()'::regprocedure;
  v_definition text;
  v_old text;
  v_new text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  v_old := $pattern$case when p.source = 'offre' then p.fuseau_offre else 'UTC' end as fuseau_groupe,$pattern$;
  v_new := $replacement$case when p.source = 'offre' then p.fuseau_offre else p.fuseau_iana end as fuseau_groupe,$replacement$;
  v_definition := pg_catalog.replace(v_definition, v_old, v_new);

  v_old := $pattern$      h.fuseau_groupe,
      h.jours_groupe,$pattern$;
  v_new := $replacement$      pg_catalog.mode() WITHIN GROUP (ORDER BY h.fuseau_groupe) as fuseau_groupe,
      h.jours_groupe,$replacement$;
  v_definition := pg_catalog.replace(v_definition, v_old, v_new);

  v_old := $pattern$    group by h.cle, h.type_public, h.langue_code,
             h.fuseau_groupe, h.jours_groupe, h.heures_groupe$pattern$;
  v_new := $replacement$    group by h.cle, h.type_public, h.langue_code,
             h.jours_groupe, h.heures_groupe$replacement$;
  v_definition := pg_catalog.replace(v_definition, v_old, v_new);

  IF v_definition NOT LIKE '%mode() WITHIN GROUP (ORDER BY h.fuseau_groupe)%'
     OR v_definition LIKE '%group by h.cle, h.type_public, h.langue_code,%h.fuseau_groupe%' THEN
    RAISE EXCEPTION 'M-a : fuseau majoritaire non installe pour les regroupements compatibles';
  END IF;
  EXECUTE v_definition;
END
$migration$;

-- La semaine courante peut déjà être passée pour le jour/heure demandé.
-- L'offset zéro désigne alors la prochaine occurrence réelle.
CREATE OR REPLACE FUNCTION public.instant_creneau(
  p_weekday int,
  p_hour int,
  p_tz text,
  p_semaine_offset int DEFAULT 0
) RETURNS timestamptz
LANGUAGE sql STABLE SET search_path = ''
AS $function$
  WITH semaine AS (
    SELECT pg_catalog.date_trunc(
      'week', pg_catalog.now() AT TIME ZONE 'UTC'
    )::date AS lundi_utc
  ), candidat AS (
    SELECT (
      s.lundi_utc + (p_weekday - 1) + (p_semaine_offset * 7)
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
$function$;

DO $migration$
DECLARE
  v_oid oid := 'public.affecter_enseignant_classe(uuid, uuid)'::regprocedure;
  v_definition text;
  v_old text;
  v_new text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(v_oid);

  v_old := $pattern$to_char(s.started_at AT TIME ZONE g.timezone_iana,$pattern$;
  v_new := $replacement$to_char(s.started_at AT TIME ZONE h.timezone,$replacement$;
  v_definition := pg_catalog.replace(v_definition, v_old, v_new);
  IF v_definition = pg_catalog.pg_get_functiondef(v_oid) THEN
    RAISE EXCEPTION 'M-b : fuseau du destinataire absent dans la notification';
  END IF;

  v_old := $pattern$AND s.started_at = (
          SELECT min(s2.started_at) FROM public.sessions s2
          WHERE s2.groupe_id = g.id AND s2.deleted_at IS NULL
        )$pattern$;
  v_new := $replacement$AND s.started_at = (
          SELECT min(s2.started_at) FROM public.sessions s2
          WHERE s2.groupe_id = g.id AND s2.deleted_at IS NULL
            AND s2.started_at > pg_catalog.now()
        )$replacement$;
  v_definition := pg_catalog.replace(v_definition, v_old, v_new);
  IF v_definition NOT LIKE '%s2.started_at > pg_catalog.now()%' THEN
    RAISE EXCEPTION 'M-b : sélection de la première séance future non installée';
  END IF;

  EXECUTE v_definition;
END
$migration$;

COMMIT;
