-- 0054 — B-08 : projection explicite et minimale des résumés de séance vers le foyer.
-- Les brouillons restent réservés à l'enseignant de la séance.
BEGIN;

CREATE TABLE public.seance_resumes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  texte_famille text NOT NULL CHECK (
    char_length(btrim(texte_famille)) BETWEEN 1 AND 1000
  ),
  jalon_atteint uuid REFERENCES public.programme_niveaux(id) ON DELETE SET NULL,
  publie_le timestamptz,
  auteur_profile_id uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT seance_resumes_session_eleve_unique UNIQUE (session_id, student_id)
);

CREATE INDEX seance_resumes_eleve_publie_idx
  ON public.seance_resumes (student_id, publie_le DESC)
  WHERE publie_le IS NOT NULL;

ALTER TABLE public.seance_resumes ENABLE ROW LEVEL SECURITY;

CREATE POLICY seance_resumes_lecture
  ON public.seance_resumes
  FOR SELECT TO authenticated
  USING (
    (
      coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false)
      AND EXISTS (
        SELECT 1 FROM public.sessions s
        WHERE s.id = seance_resumes.session_id
          AND s.teacher_id = auth.uid()
          AND s.deleted_at IS NULL
      )
    )
    OR
    (
      seance_resumes.publie_le IS NOT NULL
      AND coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
      AND EXISTS (
        SELECT 1
        FROM public.profiles p
        JOIN public.student_profiles sp ON sp.profile_id = p.id
        WHERE p.id = seance_resumes.student_id
          AND p.deleted_at IS NULL
          AND sp.deleted_at IS NULL
          AND (
            (
              p.role = 'student'
              AND p.household_id IS NOT NULL
              AND p.household_id = public.app_household_id()
            )
            OR (
              p.id = auth.uid()
              AND sp.titulaire_profile_id = auth.uid()
            )
          )
      )
    )
  );

REVOKE ALL ON public.seance_resumes FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT ON public.seance_resumes TO authenticated;

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
        AND p.role = 'student'
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
REVOKE EXECUTE ON FUNCTION public.enregistrer_resume_seance(uuid, uuid, text, uuid, boolean)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.enregistrer_resume_seance(uuid, uuid, text, uuid, boolean)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.progression_famille(
  p_student_id uuid,
  p_limit integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_niveau text;
  v_jalon_humain text;
  v_seances jsonb;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
BEGIN
  IF v_user IS NULL
     OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'progression indisponible';
  END IF;

  SELECT sp.level INTO v_niveau
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
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'progression indisponible';
  END IF;

  SELECT n.nom_humain INTO v_jalon_humain
  FROM public.seance_resumes r
  LEFT JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
  WHERE r.student_id = p_student_id
    AND r.publie_le IS NOT NULL
    AND r.jalon_atteint IS NOT NULL
  ORDER BY r.publie_le DESC
  LIMIT 1;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'session_id', q.session_id,
        'texte_famille', q.texte_famille,
        'publie_le', q.publie_le,
        'jalon_humain', q.jalon_humain
      ) ORDER BY q.publie_le DESC
    ),
    '[]'::jsonb
  )
  INTO v_seances
  FROM (
    SELECT r.session_id, r.texte_famille, r.publie_le, n.nom_humain AS jalon_humain
    FROM public.seance_resumes r
    LEFT JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
    WHERE r.student_id = p_student_id
      AND r.publie_le IS NOT NULL
    ORDER BY r.publie_le DESC
    LIMIT v_limit
  ) q;

  RETURN jsonb_build_object(
    'niveau_officiel', v_niveau,
    'jalon_humain', v_jalon_humain,
    'seances', v_seances
  );
END;
$function$;

ALTER FUNCTION public.progression_famille(uuid, integer) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.progression_famille(uuid, integer) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.progression_famille(uuid, integer) TO authenticated;

DO $verification$
BEGIN
  IF NOT (
       has_function_privilege('authenticated',
         'public.enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)', 'EXECUTE')
       AND has_function_privilege('authenticated',
         'public.progression_famille(uuid,integer)', 'EXECUTE')
       AND NOT has_function_privilege('anon',
         'public.enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)', 'EXECUTE')
       AND NOT has_function_privilege('agent_ro',
         'public.enregistrer_resume_seance(uuid,uuid,text,uuid,boolean)', 'EXECUTE')
       AND NOT has_function_privilege('anon',
         'public.progression_famille(uuid,integer)', 'EXECUTE')
       AND NOT has_function_privilege('agent_ro',
         'public.progression_famille(uuid,integer)', 'EXECUTE')
       AND (SELECT relrowsecurity FROM pg_catalog.pg_class
            WHERE oid = 'public.seance_resumes'::regclass)
  ) THEN
    RAISE EXCEPTION '0054 incomplete: résumé family ACL or RLS invalid';
  END IF;
END
$verification$;

COMMIT;
