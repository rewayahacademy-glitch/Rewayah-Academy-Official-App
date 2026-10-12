BEGIN;

CREATE OR REPLACE FUNCTION public.rejoindre_observation(p_session_id uuid)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_seance public.sessions%ROWTYPE;
  v_role public.participant_role;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'controller' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'observation reservee au controle qualite'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_seance
  FROM public.sessions s
  WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'seance introuvable' USING ERRCODE = 'no_data_found';
  END IF;

  IF v_seance.status IN ('ended', 'canceled', 'canceled_late') THEN
    RAISE EXCEPTION 'seance close' USING ERRCODE = 'check_violation';
  END IF;

  IF pg_catalog.now() < v_seance.started_at THEN
    RAISE EXCEPTION 'seance pas encore commencee' USING ERRCODE = 'check_violation';
  END IF;
  IF pg_catalog.now() > v_seance.ended_at + interval '15 minutes' THEN
    RAISE EXCEPTION 'seance terminee' USING ERRCODE = 'check_violation';
  END IF;

  SELECT sp.role INTO v_role
  FROM public.session_participants sp
  WHERE sp.session_id = p_session_id
    AND sp.profile_id = auth.uid()
    AND sp.deleted_at IS NULL;
  IF FOUND AND v_role <> 'masked_controller' THEN
    RAISE EXCEPTION 'observer une seance dont on est partie prenante est interdit'
      USING ERRCODE = 'check_violation';
  END IF;
  IF v_seance.teacher_id = auth.uid() THEN
    RAISE EXCEPTION 'observer une seance dont on est partie prenante est interdit'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.session_participants (session_id, profile_id, role)
  VALUES (p_session_id, auth.uid(), 'masked_controller')
  ON CONFLICT (session_id, profile_id) DO UPDATE
    SET deleted_at = NULL, role = 'masked_controller';

  PERFORM public.log_sensitive_access(
    'controller_observation_started',
    'session_participants',
    p_session_id::text,
    jsonb_build_object(
      'teacher_id', v_seance.teacher_id,
      'started_at', v_seance.started_at,
      'hidden', true
    )
  );

  RETURN p_session_id;
END;
$function$;

ALTER FUNCTION public.rejoindre_observation(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rejoindre_observation(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.rejoindre_observation(uuid) TO authenticated;
COMMENT ON FUNCTION public.rejoindre_observation(uuid) IS
  'F86 candidate allowlist: signature=public.rejoindre_observation(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.rejoindre_observation(uuid)');
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
    RAISE EXCEPTION 'F86 observation join postflight failed: % of 1', v_count;
  END IF;
END;
$postflight$;

COMMIT;
