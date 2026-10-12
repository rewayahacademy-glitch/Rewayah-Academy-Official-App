BEGIN;

CREATE OR REPLACE FUNCTION public.transitions_fuseau_a_venir(p_jours integer DEFAULT 30)
RETURNS TABLE (
  groupe_id uuid,
  fuseau text,
  transition_utc timestamptz,
  heure_avant text,
  heure_apres text,
  jours_restants integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'reserve a l''administration'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN QUERY
    WITH occurrences AS (
      SELECT
        g.id AS gid,
        g.timezone_iana AS tz,
        i,
        public.instant_creneau(g.weekday, g.hour_local, g.timezone_iana, i) AS debut
      FROM public.groupes g
      CROSS JOIN generate_series(0, 4) AS i
      WHERE g.ended_at IS NULL
    ),
    paires AS (
      SELECT
        o1.gid, o1.tz, o1.debut AS debut_semaine,
        o2.debut AS debut_semaine_suivante,
        (o1.debut AT TIME ZONE o1.tz) - (o1.debut AT TIME ZONE 'UTC') AS decalage_avant,
        (o2.debut AT TIME ZONE o1.tz) - (o2.debut AT TIME ZONE 'UTC') AS decalage_apres
      FROM occurrences o1
      JOIN occurrences o2 ON o2.gid = o1.gid AND o2.i = o1.i + 1
    )
    SELECT
      p.gid,
      p.tz,
      p.debut_semaine_suivante,
      pg_catalog.to_char(p.debut_semaine AT TIME ZONE p.tz, 'HH24:MI'),
      pg_catalog.to_char(p.debut_semaine_suivante AT TIME ZONE p.tz, 'HH24:MI'),
      extract(day FROM p.debut_semaine_suivante - pg_catalog.now())::integer
    FROM paires p
    WHERE p.decalage_avant IS DISTINCT FROM p.decalage_apres
      AND p.debut_semaine_suivante <= pg_catalog.now() + pg_catalog.make_interval(days => p_jours)
      AND p.debut_semaine_suivante >= pg_catalog.now();
END;
$function$;

ALTER FUNCTION public.transitions_fuseau_a_venir(integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.transitions_fuseau_a_venir(integer)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.transitions_fuseau_a_venir(integer) TO authenticated;
COMMENT ON FUNCTION public.transitions_fuseau_a_venir(integer) IS
  'F86 candidate allowlist: signature=public.transitions_fuseau_a_venir(integer); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.transitions_fuseau_a_venir(integer)');
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_roles r ON r.oid = p.proowner
  WHERE p.oid = v_oid
    AND p.prosecdef
    AND r.rolname = 'postgres'
    AND 'search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[]))
    AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'NOT COALESCE') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ACCOUNT_VALID') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ROLE') > 0;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'F86 timezone transition postflight failed: % of 1', v_count;
  END IF;
END;
$postflight$;

COMMIT;
