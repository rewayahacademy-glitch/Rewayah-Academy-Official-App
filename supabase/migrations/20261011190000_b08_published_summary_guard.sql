-- B-08: prevent a draft from changing an already published family summary.
begin;

CREATE OR REPLACE FUNCTION public.enregistrer_resume_seance(
  p_session_id uuid,
  p_student_id uuid,
  p_texte_famille text,
  p_jalon_atteint uuid,
  p_publier boolean
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_session public.sessions%ROWTYPE;
  v_before public.seance_resumes%ROWTYPE;
  v_publie_le timestamptz;
  v_est_membre boolean := false;
BEGIN
  IF v_user IS NULL
     OR p_session_id IS NULL
     OR p_student_id IS NULL
     OR p_publier IS NULL
     OR char_length(btrim(coalesce(p_texte_famille, ''))) NOT BETWEEN 1 AND 1000
     OR NOT coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'résumé indisponible';
  END IF;

  SELECT s.* INTO v_session
  FROM public.sessions s
  WHERE s.id = p_session_id
    AND s.teacher_id = v_user
    AND s.status = 'ended'
    AND s.ended_at IS NOT NULL
    AND s.deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'résumé indisponible';
  END IF;

  IF v_session.groupe_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.groupe_membres m
      JOIN public.profiles p ON p.id = m.student_id
      JOIN public.student_profiles sp ON sp.profile_id = p.id
      WHERE m.groupe_id = v_session.groupe_id
        AND m.student_id = p_student_id
        AND m.joined_at <= v_session.ended_at
        AND (m.left_at IS NULL OR m.left_at >= v_session.started_at)
        AND (
          p.role = 'student'
          OR (
            p.role = 'guardian'
            AND sp.titulaire_profile_id = p.id
            AND sp.student_type = 'autonomous'
          )
        )
        AND p.deleted_at IS NULL
        AND sp.deleted_at IS NULL
    ) INTO v_est_membre;
  ELSE
    SELECT EXISTS (
      SELECT 1
      FROM public.session_participants sp
      JOIN public.student_profiles st ON st.profile_id = sp.profile_id
      JOIN public.profiles p ON p.id = sp.profile_id
      WHERE sp.session_id = v_session.id
        AND sp.profile_id = p_student_id
        AND sp.role = 'student'::public.participant_role
        AND sp.deleted_at IS NULL
        AND st.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND (sp.entered_at IS NULL OR sp.entered_at <= v_session.ended_at)
        AND (sp.exited_at IS NULL OR sp.exited_at >= v_session.started_at)
    ) INTO v_est_membre;
  END IF;

  IF v_est_membre IS NOT TRUE THEN
    RAISE EXCEPTION 'résumé indisponible';
  END IF;

  SELECT r.* INTO v_before
  FROM public.seance_resumes r
  WHERE r.session_id = p_session_id
    AND r.student_id = p_student_id
  FOR UPDATE;

  IF NOT p_publier AND v_before.id IS NOT NULL AND v_before.publie_le IS NOT NULL THEN
    RAISE EXCEPTION 'resume_deja_publie' USING ERRCODE = '23514';
  END IF;

  INSERT INTO public.seance_resumes AS actuel
    (session_id, student_id, texte_famille, jalon_atteint, publie_le, auteur_profile_id)
  VALUES (
    p_session_id,
    p_student_id,
    btrim(p_texte_famille),
    p_jalon_atteint,
    CASE WHEN p_publier THEN now() ELSE NULL END,
    v_user
  )
  ON CONFLICT (session_id, student_id) DO UPDATE
  SET texte_famille = EXCLUDED.texte_famille,
      jalon_atteint = EXCLUDED.jalon_atteint,
      publie_le = CASE
        WHEN p_publier THEN coalesce(actuel.publie_le, now())
        ELSE actuel.publie_le
      END,
      auteur_profile_id = v_user,
      updated_at = now()
  RETURNING publie_le INTO v_publie_le;

  IF p_publier
     AND (v_before.id IS NULL
       OR v_before.publie_le IS NULL
       OR v_before.texte_famille IS DISTINCT FROM btrim(p_texte_famille)
       OR v_before.jalon_atteint IS DISTINCT FROM p_jalon_atteint) THEN
    PERFORM public.log_sensitive_access(
      'resume_seance_famille_publie',
      'seance_resumes',
      p_session_id::text || ':' || p_student_id::text,
      jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id)
    );
  END IF;

  RETURN jsonb_build_object('publie_le', v_publie_le);
END;
$function$;


ALTER FUNCTION public.enregistrer_resume_seance(uuid, uuid, text, uuid, boolean) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.enregistrer_resume_seance(uuid, uuid, text, uuid, boolean) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.enregistrer_resume_seance(uuid, uuid, text, uuid, boolean) TO authenticated;
DO $$ BEGIN
  IF NOT has_function_privilege('authenticated', 'public.enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'B-08 postflight: ACL enregistrer_resume_seance inattendue';
  END IF;
END; $$;
commit;
