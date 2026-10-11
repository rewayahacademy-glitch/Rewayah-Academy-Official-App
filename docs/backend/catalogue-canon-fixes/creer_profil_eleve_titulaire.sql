CREATE OR REPLACE FUNCTION public.creer_profil_eleve_titulaire()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_profile public.profiles%ROWTYPE;
  v_student public.student_profiles%ROWTYPE;
BEGIN
  IF v_user IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'création réservée au titulaire connecté';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles p
  WHERE p.id = v_user
    AND p.role = 'guardian'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > now())
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'profil titulaire indisponible';
  END IF;

  SELECT * INTO v_student
  FROM public.student_profiles sp
  WHERE sp.titulaire_profile_id = v_user
    AND sp.profile_id = v_user
    AND sp.deleted_at IS NULL;

  IF FOUND THEN
    RETURN v_user;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.student_profiles sp
    WHERE sp.profile_id = v_user
      AND sp.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'une fiche d''apprentissage existe déjà pour ce profil';
  END IF;

  INSERT INTO public.student_profiles
    (profile_id, titulaire_profile_id, student_type, interface_mode, camera_policy, cohorte)
  VALUES
    (v_user, v_user, 'autonomous', 'standard', 'forbidden', 'adulte_18_plus');

  PERFORM public.log_sensitive_access(
    'profil_eleve_titulaire_cree', 'student_profiles', v_user::text,
    jsonb_build_object('student_type', 'autonomous', 'cohorte', 'adulte_18_plus')
  );

  RETURN v_user;
END;
$function$

