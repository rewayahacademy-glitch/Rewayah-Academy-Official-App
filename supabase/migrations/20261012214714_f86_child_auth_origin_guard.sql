BEGIN;

CREATE OR REPLACE FUNCTION public.creer_profil_enfant(
  p_auth_user_id uuid,
  p_guardian_id uuid,
  p_first_name text,
  p_last_name text,
  p_age integer,
  p_level text DEFAULT NULL
) RETURNS public.profiles
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_guardian public.profiles;
  v_profile public.profiles;
  v_mode public.interface_mode;
  v_camera public.camera_policy;
  v_seuil_enfant integer;
  v_age_camera integer;
  v_auth_user jsonb;
BEGIN
  IF NOT coalesce(auth.uid() = p_guardian_id AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'appelant tuteur invalide' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_guardian FROM public.profiles p
   WHERE p.id = p_guardian_id AND p.deleted_at IS NULL;
  IF v_guardian.id IS NULL OR v_guardian.role <> 'guardian' THEN
    RAISE EXCEPTION 'l''appelant n''est pas un tuteur';
  END IF;
  IF v_guardian.household_id IS NULL THEN
    RAISE EXCEPTION 'ce tuteur n''a pas de foyer';
  END IF;
  -- Defense in depth: keep this local status assertion even though the shared
  -- account-validity guard currently rejects the same statuses.
  IF v_guardian.account_status NOT IN ('active', 'provisional_active') THEN
    RAISE EXCEPTION 'compte tuteur non valide';
  END IF;
  IF coalesce(btrim(p_first_name), '') = '' OR coalesce(btrim(p_last_name), '') = '' THEN
    RAISE EXCEPTION 'prenom et nom sont requis';
  END IF;
  IF p_age IS NULL OR p_age < 3 OR p_age > 99 THEN
    RAISE EXCEPTION 'age hors bornes';
  END IF;

  SELECT pg_catalog.to_jsonb(u) INTO v_auth_user
    FROM auth.users u WHERE u.id = p_auth_user_id FOR UPDATE;
  IF v_auth_user IS NULL
     OR v_auth_user #>> '{raw_app_meta_data,child_of}' IS DISTINCT FROM auth.uid()::text
     OR nullif(v_auth_user->>'created_at', '') IS NULL
     OR (v_auth_user->>'created_at')::timestamptz < pg_catalog.now() - interval '15 minutes'
     OR (v_auth_user->>'created_at')::timestamptz > pg_catalog.now()
     OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = p_auth_user_id) THEN
    RAISE EXCEPTION 'compte enfant non issu de la creation serveur recente'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT coalesce((public.get_config('child_ui_mode_max_age', '8'::jsonb) #>> '{}')::integer, 8)
    INTO v_seuil_enfant;
  SELECT coalesce((public.get_config('camera_auto_allow_min_age', '11'::jsonb) #>> '{}')::integer, 11)
    INTO v_age_camera;
  v_mode := CASE WHEN p_age <= v_seuil_enfant THEN 'child' ELSE 'standard' END;
  v_camera := CASE WHEN p_age >= v_age_camera THEN 'allowed' ELSE 'forbidden' END;

  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, account_status)
  VALUES (p_auth_user_id, NULL, 'student', v_guardian.household_id,
    btrim(p_first_name), btrim(p_last_name), v_guardian.account_status)
  RETURNING * INTO v_profile;
  INSERT INTO public.student_profiles
    (profile_id, student_type, interface_mode, camera_policy, level)
  VALUES (p_auth_user_id, 'minor', v_mode, v_camera, p_level);
  PERFORM public.log_sensitive_access('profil_enfant_cree', 'profiles', p_auth_user_id::text,
    jsonb_build_object('household_id', v_guardian.household_id, 'mode', v_mode::text));
  RETURN v_profile;
END;
$function$;

ALTER FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  TO authenticated;
REVOKE ALL ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) TO authenticated;

COMMENT ON FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text) IS
  'F86 candidate allowlist: signature=public.creer_profil_enfant(uuid,uuid,text,text,integer,text); md5_functiondef=A_CALCULER; guard_type=AUTHENTICATED_GUARDIAN_AND_SERVER_CHILD_OF_RECENT_NO_PROFILE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-13.';
COMMENT ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) IS 'F86 candidate allowlist: signature=public.creer_profil_inscription(text,text,text,public.gender,text,boolean); md5_functiondef=6e62676fc9cce5c0f76d7f6ae39d6959; guard_type=PUBLIC_REGISTRATION; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-13.';

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)'::regprocedure
     )) <> '6e62676fc9cce5c0f76d7f6ae39d6959' THEN
    RAISE EXCEPTION 'F86 registration ACL or fingerprint postflight failed';
  END IF;
END
$postflight$;

COMMIT;
