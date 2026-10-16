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
BEGIN
  IF NOT coalesce(
    auth.uid() = p_guardian_id AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'appelant tuteur invalide'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_guardian
    FROM public.profiles p
   WHERE p.id = p_guardian_id AND p.deleted_at IS NULL;
  IF v_guardian.id IS NULL OR v_guardian.role <> 'guardian' THEN
    RAISE EXCEPTION 'l''appelant n''est pas un tuteur';
  END IF;
  IF v_guardian.household_id IS NULL THEN
    RAISE EXCEPTION 'ce tuteur n''a pas de foyer';
  END IF;
  IF v_guardian.account_status NOT IN ('active', 'provisional_active') THEN
    RAISE EXCEPTION 'compte tuteur non valide';
  END IF;
  IF coalesce(btrim(p_first_name), '') = '' OR coalesce(btrim(p_last_name), '') = '' THEN
    RAISE EXCEPTION 'prenom et nom sont requis';
  END IF;
  IF p_age IS NULL OR p_age < 3 OR p_age > 99 THEN
    RAISE EXCEPTION 'age hors bornes';
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

ALTER FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.creer_profil_enfant(uuid, uuid, text, text, integer, text)
  TO authenticated;

REVOKE ALL ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.creer_profil_inscription(
  text, text, text, public.gender, text, boolean
) TO authenticated;

-- Empreinte F86 : posee par 20261013000200, qui fixe la definition finale.

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege(
       'authenticated',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'anon',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role',
       'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)', 'EXECUTE'
     )
     OR NOT pg_catalog.has_function_privilege(
       'authenticated',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'anon',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role',
       'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'F86 registration EXECUTE postflight failed';
  END IF;
END
$postflight$;

COMMIT;
