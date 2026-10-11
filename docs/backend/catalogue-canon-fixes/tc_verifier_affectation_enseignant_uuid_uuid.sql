CREATE OR REPLACE FUNCTION public.tc_verifier_affectation_enseignant(p_groupe_id uuid, p_teacher_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_gender public.gender;
  v_cap int;
  v_duree int;
  v_charge numeric;
  v_c record;
  v_busy record;
  v_w int;
  v_aw int;
  v_debut timestamptz;
  v_busy_debut timestamptz;
  v_trouve boolean;
BEGIN
  IF p_groupe_id IS NULL OR p_teacher_id IS NULL THEN
    RAISE EXCEPTION 'classe ou enseignant absent';
  END IF;

  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;

  -- Sérialise deux tentatives concurrentes d'affecter le même enseignant.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('teacher-schedule:' || p_teacher_id::text, 0)
  );

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  JOIN public.teacher_profiles tp ON tp.profile_id = p.id
  WHERE p.id = p_teacher_id
    AND p.role = 'teacher'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND tp.deleted_at IS NULL
    AND tp.kyc_status = 'approved'
    AND (v_g.langue_code IS NULL OR v_g.langue_code = ANY(tp.languages));
  IF NOT FOUND OR v_gender IS NULL THEN
    RAISE EXCEPTION 'enseignant indisponible ou genre inconnu';
  END IF;

  IF v_g.genre_public IS NULL
     OR v_g.genre_public NOT IN ('hommes', 'femmes', 'indetermine')
     OR (v_g.genre_public = 'hommes' AND v_gender <> 'male')
     OR (v_g.genre_public = 'femmes' AND v_gender <> 'female') THEN
    RAISE EXCEPTION 'enseignant incompatible avec le public de la classe';
  END IF;

  v_duree := public.app_config_int('session_duration_minutes', 60);
  SELECT tp.weekly_hours_cap INTO v_cap
  FROM public.teacher_profiles tp
  WHERE tp.profile_id = p_teacher_id;

  SELECT
    (
      SELECT count(*) FROM (
        SELECT DISTINCT g.id, gs.weekday, gs.hour_local
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) gs
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
      ) active_groups
    )
    +
    (
      SELECT count(*)
      FROM public.teacher_student_assignments tsa
      JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
      WHERE tsa.teacher_id = p_teacher_id AND tsa.ended_at IS NULL
    )
    +
    (
      SELECT count(*) FROM (
        SELECT DISTINCT gs.weekday, gs.hour_local
        FROM public.groupes target
        CROSS JOIN LATERAL (
          SELECT target.weekday, target.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = target.id
        ) gs
        WHERE target.id = p_groupe_id
      ) target_slots
    )
  INTO v_charge;

  IF v_cap IS NULL OR v_charge * v_duree / 60.0 > v_cap THEN
    RAISE EXCEPTION 'plafond horaire enseignant dépassé';
  END IF;

  -- Chaque occurrence de la classe doit être couverte par la disponibilité
  -- déclarée de l'enseignant, y compris avant/après les changements saisonniers.
  FOR v_c IN
    SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
    FROM (
      SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
      UNION
      SELECT gc.weekday, gc.hour_local
      FROM public.groupe_creneaux gc
      WHERE gc.groupe_id = p_groupe_id
    ) slots
  LOOP
    FOR v_w IN 0..51 LOOP
      v_debut := public.instant_creneau(v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w);
      v_trouve := false;
      FOR v_busy IN
        SELECT wa.weekday, wa.hour_local, wa.timezone_iana
        FROM public.weekly_availability wa
        WHERE wa.profile_id = p_teacher_id
      LOOP
        FOR v_aw IN greatest(0, v_w - 1)..least(52, v_w + 1) LOOP
          v_busy_debut := public.instant_creneau(
            v_busy.weekday, v_busy.hour_local, v_busy.timezone_iana, v_aw
          );
          IF v_busy_debut <= v_debut
             AND v_busy_debut + interval '1 hour' >= v_debut + make_interval(mins => v_duree) THEN
            v_trouve := true;
            EXIT;
          END IF;
        END LOOP;
        EXIT WHEN v_trouve;
      END LOOP;
      IF NOT v_trouve THEN
        RAISE EXCEPTION 'enseignant non disponible: jour %, heure %, fuseau %, semaine %, instant %',
          v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w, v_debut;
      END IF;
    END LOOP;
  END LOOP;

  -- C-07 : les créneaux principaux et secondaires des classes actives,
  -- les affectations individuelles récurrentes et les séances ponctuelles
  -- sont comparés comme des instants, pas comme des heures locales.
  FOR v_c IN
    SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
    FROM (
      SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
      UNION
      SELECT gc.weekday, gc.hour_local
      FROM public.groupe_creneaux gc
      WHERE gc.groupe_id = p_groupe_id
    ) slots
  LOOP
    FOR v_busy IN
      SELECT DISTINCT busy.weekday, busy.hour_local, busy.timezone_iana
      FROM (
        SELECT slots.weekday, slots.hour_local, g.timezone_iana
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) slots
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
        UNION
        SELECT wa.weekday, wa.hour_local, wa.timezone_iana
        FROM public.teacher_student_assignments tsa
        JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
        WHERE tsa.teacher_id = p_teacher_id AND tsa.ended_at IS NULL
      ) busy
    LOOP
      FOR v_w IN 0..51 LOOP
        v_debut := public.instant_creneau(v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w);
        FOR v_aw IN greatest(0, v_w - 1)..least(52, v_w + 1) LOOP
          v_busy_debut := public.instant_creneau(
            v_busy.weekday, v_busy.hour_local, v_busy.timezone_iana, v_aw
          );
          IF v_debut < v_busy_debut + make_interval(mins => v_duree)
             AND v_busy_debut < v_debut + make_interval(mins => v_duree) THEN
            RAISE EXCEPTION 'chevauchement avec une classe ou affectation active';
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP;

  IF EXISTS (
    SELECT 1
    FROM public.sessions s
    CROSS JOIN LATERAL generate_series(0, 51) AS w(n)
    CROSS JOIN LATERAL (
      SELECT public.instant_creneau(v_g.weekday, v_g.hour_local, v_g.timezone_iana, w.n) AS starts_at
      UNION
      SELECT public.instant_creneau(gc.weekday, gc.hour_local, v_g.timezone_iana, w.n)
      FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
    ) target
    WHERE s.teacher_id = p_teacher_id
      AND s.groupe_id IS NULL
      AND s.deleted_at IS NULL
      AND s.status NOT IN ('canceled')
      AND target.starts_at < s.ended_at
      AND s.started_at < target.starts_at + make_interval(mins => v_duree)
  ) THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante';
  END IF;
END;
$function$

