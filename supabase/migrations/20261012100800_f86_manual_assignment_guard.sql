BEGIN;

-- Isolate the uniqueness translation so the public function starts with the
-- approved role guard and the static F86 gate can inspect it without guessing
-- about unrelated exception handlers.
CREATE FUNCTION private.attribuer_eleve_insert(
  p_student_profile_id uuid,
  p_teacher_profile_id uuid,
  p_weekday integer,
  p_hour integer,
  p_timezone text
) RETURNS uuid
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE v_assignment uuid;
BEGIN
  INSERT INTO public.teacher_student_assignments
    (teacher_id, student_id, weekday, hour_local, timezone_iana)
  VALUES (p_teacher_profile_id, p_student_profile_id, p_weekday, p_hour, p_timezone)
  RETURNING id INTO v_assignment;
  RETURN v_assignment;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'cet eleve vient d''etre pris par un enseignant';
END;
$function$;
ALTER FUNCTION private.attribuer_eleve_insert(uuid,uuid,integer,integer,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.attribuer_eleve_insert(uuid,uuid,integer,integer,text)
  FROM PUBLIC,anon,authenticated,service_role,agent_ro;

-- F86: null-safe administration gate for manual student assignment.
CREATE OR REPLACE FUNCTION public.attribuer_eleve(
  p_student_profile_id uuid,
  p_teacher_profile_id uuid,
  p_weekday int,
  p_hour int,
  p_motif text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_tz text;
  v_instant timestamptz;
  v_hors boolean;
  v_motif text := nullif(btrim(coalesce(p_motif, '')), '');
  v_assignment uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'attribution manuelle reservee a l''administration';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_teacher_profile_id
      AND p.role = 'teacher'
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
  ) THEN
    RAISE EXCEPTION 'cet enseignant n''existe pas ou son compte n''est pas valide';
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

  v_hors := NOT EXISTS (
    SELECT 1 FROM public.weekly_availability wt
    WHERE wt.profile_id = p_teacher_profile_id
      AND public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana) = v_instant
  );

  IF v_hors AND v_motif IS NULL THEN
    RAISE EXCEPTION 'attribuer hors des disponibilites de cet enseignant exige un motif';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.teacher_student_assignments a
    WHERE a.student_id = p_student_profile_id AND a.ended_at IS NULL
  ) THEN
    RAISE EXCEPTION 'cet eleve a deja un enseignant';
  END IF;

  v_assignment := private.attribuer_eleve_insert(
    p_student_profile_id, p_teacher_profile_id, p_weekday, p_hour, v_tz);

  PERFORM public.materialiser_seances(v_assignment);
  PERFORM public.log_sensitive_access('affectation_attribuee',
    'teacher_student_assignments', v_assignment::text,
    jsonb_build_object('student_id', p_student_profile_id,
      'teacher_id', p_teacher_profile_id, 'weekday', p_weekday, 'hour_local', p_hour,
      'hors_disponibilite', v_hors, 'motif', v_motif));

  RETURN v_assignment;
END;
$function$;
ALTER FUNCTION public.attribuer_eleve(uuid,uuid,integer,integer,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.attribuer_eleve(uuid,uuid,integer,integer,text)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.attribuer_eleve(uuid,uuid,integer,integer,text)
  TO authenticated;
COMMENT ON FUNCTION public.attribuer_eleve(uuid,uuid,integer,integer,text) IS
  'F86 candidate allowlist: signature=public.attribuer_eleve(uuid,uuid,integer,integer,text); md5_functiondef=2ab697ec188114774c8a4dfe82aec439; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE v_count integer; v_helper_ok boolean;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_catalog.pg_roles r ON r.oid=p.proowner
  WHERE n.nspname='public' AND p.proname='attribuer_eleve'
    AND pg_catalog.pg_get_function_identity_arguments(p.oid)=
      'p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text'
    AND p.prosecdef AND r.rolname='postgres'
    AND 'search_path=""'=ANY(coalesce(p.proconfig,ARRAY[]::text[]))
    AND NOT pg_catalog.has_function_privilege('anon',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('service_role',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('agent_ro',p.oid,'EXECUTE')
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'NOT COALESCE')>0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'APP_ACCOUNT_VALID')>0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'APP_ROLE')>0;
  SELECT count(*)=1 INTO v_helper_ok
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_catalog.pg_roles r ON r.oid=p.proowner
  WHERE n.nspname='private' AND p.proname='attribuer_eleve_insert'
    AND pg_catalog.pg_get_function_identity_arguments(p.oid)=
      'p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_timezone text'
    AND NOT p.prosecdef AND r.rolname='postgres'
    AND 'search_path=""'=ANY(coalesce(p.proconfig,ARRAY[]::text[]))
    AND NOT pg_catalog.has_function_privilege('anon',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('authenticated',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('agent_ro',p.oid,'EXECUTE');
  IF v_count<>1 OR NOT coalesce(v_helper_ok,false) THEN
    RAISE EXCEPTION 'F86 manual assignment guard postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
