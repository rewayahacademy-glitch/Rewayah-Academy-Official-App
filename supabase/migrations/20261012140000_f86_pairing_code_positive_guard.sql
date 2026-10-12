BEGIN;

-- F86: a non-active or non-guardian caller must be rejected before any
-- household or student state is read.
CREATE OR REPLACE FUNCTION public.creer_code_appairage(p_student_profile_id uuid)
RETURNS TABLE (code text, expires_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  -- 32 characters, without 0 O 1 I: 32^6 gives about 1.07 billion codes.
  v_alphabet CONSTANT text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code text;
  v_expire timestamptz;
  v_max int;
  v_actifs int;
BEGIN
  IF NOT COALESCE(
    public.app_account_valid() AND public.app_role() = 'guardian',
    false
  ) THEN
    RAISE EXCEPTION 'seul un tuteur au compte valide appaire un appareil'
      USING errcode = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_student_profile_id
      AND p.household_id IS NOT NULL
      AND p.household_id = public.app_household_id()
      AND p.role = 'student'
      AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'cet eleve n''appartient pas a votre foyer';
  END IF;

  SELECT COALESCE((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    INTO v_max;
  SELECT count(*) INTO v_actifs FROM public.devices d
  WHERE d.profile_id = p_student_profile_id
    AND d.revoked_at IS NULL AND d.deleted_at IS NULL;
  IF v_actifs >= v_max THEN
    RAISE EXCEPTION 'plafond d''appareils atteint';
  END IF;

  -- One live code per student: creating a new one expires the previous code.
  UPDATE public.device_pairing_codes
  SET deleted_at = pg_catalog.now()
  WHERE student_profile_id = p_student_profile_id
    AND consumed_at IS NULL AND deleted_at IS NULL;

  SELECT pg_catalog.string_agg(
    pg_catalog.substr(v_alphabet, 1 + (pg_catalog.get_byte(s.b, i) % 32), 1),
    '' ORDER BY i
  )
  INTO v_code
  FROM (SELECT extensions.gen_random_bytes(6) AS b) s,
       pg_catalog.generate_series(0, 5) AS i;

  v_expire := pg_catalog.now() + pg_catalog.make_interval(mins =>
    COALESCE((public.get_config('pairing_code_ttl_minutes', '10'::jsonb) #>> '{}')::int, 10));

  INSERT INTO public.device_pairing_codes (student_profile_id, code_hash, created_by, expires_at)
  VALUES (
    p_student_profile_id,
    pg_catalog.encode(extensions.digest(pg_catalog.convert_to(v_code, 'UTF8'), 'sha256'), 'hex'),
    auth.uid(),
    v_expire
  );

  PERFORM public.log_sensitive_access('appairage_code_cree', 'device_pairing_codes',
    p_student_profile_id::text, '{}'::jsonb);

  RETURN QUERY SELECT v_code, v_expire;
END;
$function$;

ALTER FUNCTION public.creer_code_appairage(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_code_appairage(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.creer_code_appairage(uuid) TO authenticated;

COMMENT ON FUNCTION public.creer_code_appairage(uuid) IS
  'F86 candidate allowlist: signature=public.creer_code_appairage(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: active guardian creates a code only for a student in the caller household; device cap, expiry, one-live-code, audit, and authenticated-only ACL remain enforced.';

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.creer_code_appairage(uuid)'::regprocedure);
BEGIN
  IF v_def NOT LIKE '%IF NOT COALESCE(%app_account_valid()%app_role()%guardian%false%'
     OR v_def NOT LIKE '%SET search_path TO ''''%'
     OR NOT has_function_privilege('authenticated', 'public.creer_code_appairage(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.creer_code_appairage(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'F86 pairing-code guard postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
