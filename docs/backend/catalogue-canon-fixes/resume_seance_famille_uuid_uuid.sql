CREATE OR REPLACE FUNCTION public.resume_seance_famille(p_session_id uuid, p_student_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_resume text;
BEGIN
  IF v_user IS NULL
     OR p_session_id IS NULL
     OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
     OR NOT EXISTS (
       SELECT 1
       FROM public.profiles p
       JOIN public.student_profiles sp ON sp.profile_id = p.id
       WHERE p.id = p_student_id
         AND p.deleted_at IS NULL
         AND sp.deleted_at IS NULL
         AND (
           (
             p.role = 'student'
             AND p.household_id IS NOT NULL
             AND p.household_id = public.app_household_id()
           )
           OR (
             p.id = v_user
             AND sp.titulaire_profile_id = v_user
           )
         )
     ) THEN
    RAISE EXCEPTION 'résumé indisponible';
  END IF;

  SELECT r.texte_famille INTO v_resume
  FROM public.seance_resumes r
  WHERE r.session_id = p_session_id
    AND r.student_id = p_student_id
    AND r.publie_le IS NOT NULL;

  RETURN v_resume;
END;
$function$

