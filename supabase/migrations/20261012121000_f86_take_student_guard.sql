BEGIN;

CREATE OR REPLACE FUNCTION public.prendre_eleve(
  p_student_profile_id uuid,
  p_weekday integer,
  p_hour integer
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_tz text;
  v_instant timestamptz;
  v_assignment uuid;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'teacher' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'seul un enseignant au compte valide prend un eleve';
  END IF;

  SELECT w.timezone_iana INTO v_tz
  FROM public.weekly_availability w
  JOIN public.profiles p ON p.id = w.profile_id
  WHERE w.profile_id = p_student_profile_id
    AND w.weekday = p_weekday AND w.hour_local = p_hour
    AND p.role = 'student' AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active');

  IF v_tz IS NULL THEN
    RAISE EXCEPTION 'ce creneau n''est pas propose par ce foyer';
  END IF;

  v_instant := public.instant_creneau(p_weekday, p_hour, v_tz);

  IF NOT EXISTS (
    SELECT 1 FROM public.weekly_availability wt
    WHERE wt.profile_id = auth.uid()
      AND public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  ) THEN
    RAISE EXCEPTION 'ce creneau ne figure pas dans vos disponibilites';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.teacher_student_assignments a
    WHERE a.student_id = p_student_profile_id AND a.ended_at IS NULL
  ) THEN
    RAISE EXCEPTION 'cet eleve a deja un enseignant';
  END IF;

  BEGIN
    INSERT INTO public.teacher_student_assignments
      (teacher_id, student_id, weekday, hour_local, timezone_iana)
    VALUES (auth.uid(), p_student_profile_id, p_weekday, p_hour, v_tz)
    RETURNING id INTO v_assignment;
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'cet eleve vient d''etre pris par un autre enseignant';
  END;

  PERFORM public.materialiser_seances(v_assignment);
  PERFORM public.log_sensitive_access(
    'affectation_creee',
    'teacher_student_assignments',
    v_assignment::text,
    jsonb_build_object(
      'student_id', p_student_profile_id,
      'weekday', p_weekday,
      'hour_local', p_hour
    )
  );

  RETURN v_assignment;
END;
$function$;

ALTER FUNCTION public.prendre_eleve(uuid, integer, integer) OWNER TO postgres;
COMMENT ON FUNCTION public.prendre_eleve(uuid, integer, integer) IS
  'F86 candidate allowlist: signature=public.prendre_eleve(uuid,integer,integer); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.prendre_eleve(uuid,integer,integer)');
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
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'NOT COALESCE') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ACCOUNT_VALID') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ROLE') > 0;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'F86 take-student postflight failed: % of 1', v_count;
  END IF;
END;
$postflight$;

COMMIT;
