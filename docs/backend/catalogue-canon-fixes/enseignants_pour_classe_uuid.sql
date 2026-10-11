CREATE OR REPLACE FUNCTION public.enseignants_pour_classe(p_classe_id uuid)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, titre_public text, timezone_iana text, classes_actives integer, creneaux_pris jsonb, creneaux_libres jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_teacher record;
  v_pris jsonb;
  v_libres jsonb;
  v_duree integer;
BEGIN
  v_duree := public.app_config_int('session_duration_minutes', 60);
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(), false
  ) THEN
    RAISE EXCEPTION 'proposition d''enseignants réservée à la direction active';
  END IF;

  SELECT g.* INTO v_g
  FROM public.groupes AS g
  WHERE g.id = p_classe_id
    AND g.etat = 'en_attente_enseignant'
    AND g.teacher_id IS NULL
    AND g.ended_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe en attente absente ou indisponible';
  END IF;

  FOR v_teacher IN
    SELECT p.id, p.first_name, p.last_name, p.immutable_id, p.gender,
           tp.country, tp.timezone_iana, tp.weekly_hours_cap
    FROM public.profiles p
    JOIN public.teacher_profiles tp ON tp.profile_id = p.id
    WHERE p.role = 'teacher'
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
      AND p.gender IS NOT NULL
      AND tp.deleted_at IS NULL
      AND tp.kyc_status = 'approved'
      AND (v_g.langue_code IS NULL OR v_g.langue_code = ANY(tp.languages))
      AND (v_g.genre_public = 'indetermine'
           OR (v_g.genre_public = 'hommes' AND p.gender = 'male')
           OR (v_g.genre_public = 'femmes' AND p.gender = 'female'))
  LOOP
    BEGIN
      PERFORM public.tc_verifier_affectation_enseignant(v_g.id, v_teacher.id);
    EXCEPTION WHEN OTHERS THEN
      CONTINUE;
    END;

    SELECT count(*)::integer INTO classes_actives
    FROM public.groupes g
    WHERE g.teacher_id = v_teacher.id
      AND g.ended_at IS NULL AND g.etat = 'active';

    SELECT coalesce(jsonb_agg(jsonb_build_object(
             'weekday', busy.weekday,
             'hour_local', busy.hour_local,
             'timezone_iana', busy.timezone_iana
           ) ORDER BY busy.weekday, busy.hour_local), '[]'::jsonb)
      INTO v_pris
    FROM (
      SELECT DISTINCT slots.weekday, slots.hour_local, g.timezone_iana
      FROM public.groupes g
      CROSS JOIN LATERAL (
        SELECT g.weekday, g.hour_local
        UNION
        SELECT gc.weekday, gc.hour_local
        FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
      ) slots
      WHERE g.teacher_id = v_teacher.id
        AND g.ended_at IS NULL AND g.etat = 'active'
      UNION
      SELECT wa.weekday, wa.hour_local, wa.timezone_iana
      FROM public.teacher_student_assignments tsa
      JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
      WHERE tsa.teacher_id = v_teacher.id AND tsa.ended_at IS NULL
    ) busy;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
             'weekday', wa.weekday,
             'hour_local', wa.hour_local,
             'timezone_iana', wa.timezone_iana
           ) ORDER BY wa.weekday, wa.hour_local), '[]'::jsonb)
      INTO v_libres
    FROM public.weekly_availability wa
    WHERE wa.profile_id = v_teacher.id
      AND NOT EXISTS (
        SELECT 1
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
        ) slots
        WHERE g.teacher_id = v_teacher.id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND app_private.creneaux_recurrents_se_chevauchent(
            wa.weekday, wa.hour_local, wa.timezone_iana,
            slots.weekday, slots.hour_local, g.timezone_iana, v_duree
          )
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.teacher_student_assignments tsa
        JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
        WHERE tsa.teacher_id = v_teacher.id AND tsa.ended_at IS NULL
          AND app_private.creneaux_recurrents_se_chevauchent(
            wa.weekday, wa.hour_local, wa.timezone_iana,
            busy.weekday, busy.hour_local, busy.timezone_iana, v_duree
          )
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.teacher_id = v_teacher.id
          AND s.groupe_id IS NULL
          AND s.deleted_at IS NULL
          AND s.status NOT IN ('canceled')
          AND app_private.creneau_recurrent_chevauche_session(
            wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
            s.started_at, s.ended_at
          )
      );

    teacher_id := v_teacher.id;
    first_name := v_teacher.first_name;
    last_name := v_teacher.last_name;
    immutable_id := v_teacher.immutable_id;
    country := v_teacher.country;
    titre_public := CASE v_teacher.gender
      WHEN 'female' THEN 'sayyida'
      WHEN 'male' THEN 'sayid'
      ELSE NULL
    END;
    timezone_iana := v_teacher.timezone_iana;
    creneaux_pris := v_pris;
    creneaux_libres := v_libres;
    RETURN NEXT;
  END LOOP;
END;
$function$

