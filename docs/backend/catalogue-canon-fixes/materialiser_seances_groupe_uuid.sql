CREATE OR REPLACE FUNCTION public.materialiser_seances_groupe(p_groupe_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_creneau public.groupe_creneaux%ROWTYPE;
  v_semaines integer;
  v_duree integer;
  v_fenetre integer;
  v_debut timestamptz;
  v_session uuid;
  v_n integer := 0;
BEGIN
  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND OR v_g.teacher_id IS NULL OR v_g.etat <> 'active' THEN
    RETURN 0;
  END IF;

  v_semaines := public.app_config_int('matching_horizon_weeks', 4);
  v_duree := public.app_config_int('session_duration_minutes', 60);
  v_fenetre := public.app_config_int('join_window_minutes', 20);

  FOR v_creneau IN
    SELECT gc.* FROM public.groupe_creneaux gc
    WHERE gc.groupe_id = p_groupe_id
    ORDER BY gc.weekday, gc.hour_local
  LOOP
    FOR i IN 0 .. v_semaines - 1 LOOP
      v_debut := public.instant_creneau(
        v_creneau.weekday, v_creneau.hour_local, v_g.timezone_iana, i
      );
      SELECT s.id INTO v_session
      FROM public.sessions s
      WHERE s.groupe_id = p_groupe_id
        AND s.started_at = v_debut
        AND s.deleted_at IS NULL;

      IF v_session IS NOT NULL THEN
        IF v_debut > now() THEN
          INSERT INTO public.session_participants (session_id, profile_id, role)
          SELECT v_session, m.student_id, 'student'
          FROM public.groupe_membres m
          WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
          ON CONFLICT (session_id, profile_id) DO NOTHING;
        END IF;
        CONTINUE;
      END IF;

      INSERT INTO public.sessions
        (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
      VALUES
        (v_g.teacher_id, v_debut,
         v_debut + make_interval(mins => v_duree),
         CASE v_g.type_public WHEN 'enfant' THEN 'child' ELSE 'standard' END,
         p_groupe_id, v_debut - make_interval(mins => v_fenetre))
      RETURNING id INTO v_session;

      INSERT INTO public.session_participants (session_id, profile_id, role)
      SELECT v_session, m.student_id, 'student'
      FROM public.groupe_membres m
      WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;

      v_n := v_n + 1;
    END LOOP;
  END LOOP;
  RETURN v_n;
END;
$function$

