-- 0082 — C-03/C-04/C-07 : genre de classe, proposition serveur et garde de collisions.
-- Le titre public est toujours dérivé de profiles.gender; aucune valeur de titre n'est stockée.
BEGIN;

-- 0077 already introduced genre_public as checked text. Keep that
-- canonical column; assigning to a class with NULL/unknown public is forbidden.
ALTER TABLE public.groupes
  ALTER COLUMN genre_public SET DEFAULT 'indetermine';

COMMENT ON COLUMN public.groupes.genre_public IS
  'Public de genre de la classe. Le titre public enseignant est dérivé côté serveur depuis profiles.gender.';

CREATE OR REPLACE FUNCTION public.tc_verifier_affectation_enseignant(
  p_groupe_id uuid,
  p_teacher_id uuid
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
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
$function$;

REVOKE ALL ON FUNCTION public.tc_verifier_affectation_enseignant(uuid, uuid)
  FROM PUBLIC, anon, authenticated, agent_ro;

DROP TRIGGER IF EXISTS groupes_affectation_enseignant_guard ON public.groupes;
DROP TRIGGER IF EXISTS groupe_creneaux_affectation_guard ON public.groupe_creneaux;

CREATE OR REPLACE FUNCTION public.affecter_enseignant_classe(
  p_groupe_id uuid,
  p_teacher_profile_id uuid
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false)
     OR p_groupe_id IS NULL OR p_teacher_profile_id IS NULL THEN
    RAISE EXCEPTION 'affectation reservee a l''administration';
  END IF;

  SELECT * INTO v_groupe FROM public.groupes
  WHERE id = p_groupe_id FOR UPDATE;
  IF NOT FOUND OR v_groupe.teacher_id IS NOT NULL
     OR v_groupe.etat <> 'en_attente_enseignant'
     OR v_groupe.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'deja_affecte ou classe indisponible';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    JOIN public.teacher_profiles tp ON tp.profile_id = p.id
    WHERE p.id = p_teacher_profile_id
      AND p.role = 'teacher' AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > now())
      AND tp.deleted_at IS NULL
      AND tp.kyc_status = 'approved'
      AND v_groupe.langue_code = ANY(tp.languages)
  ) THEN
    RAISE EXCEPTION 'enseignant indisponible';
  END IF;

  -- C-04/C-07: the same eligibility/collision check is enforced at the
  -- authorization boundary, not on arbitrary group creation or edits.
  PERFORM public.tc_verifier_affectation_enseignant(
    p_groupe_id, p_teacher_profile_id
  );

  UPDATE public.groupes
     SET teacher_id = p_teacher_profile_id, etat = 'active'
   WHERE id = p_groupe_id;

  PERFORM public.log_sensitive_access(
    'enseignant_affecte_classe', 'groupes', p_groupe_id::text,
    jsonb_build_object('teacher_id', p_teacher_profile_id)
  );
  IF pg_catalog.to_regclass('public.notifications') IS NOT NULL THEN
    EXECUTE $sql$
      INSERT INTO public.notifications
        (destinataire, foyer_id, evenement, params, destination)
      SELECT DISTINCT h.primary_guardian_id, h.id, 'enseignant_affecte',
             jsonb_build_object(
               'groupe_id', $1,
               'debut_local', to_char(s.started_at AT TIME ZONE g.timezone_iana,
                                      'YYYY-MM-DD"T"HH24:MI:SS')
             ),
             '/tuteur/demandes'
      FROM public.groupe_membres gm
      JOIN public.profiles p ON p.id = gm.student_id
      JOIN public.households h ON h.id = p.household_id
      JOIN public.groupes g ON g.id = gm.groupe_id
      JOIN public.sessions s ON s.groupe_id = g.id AND s.deleted_at IS NULL
      WHERE gm.groupe_id = $1 AND gm.left_at IS NULL
        AND h.primary_guardian_id IS NOT NULL
        AND s.started_at = (
          SELECT min(s2.started_at) FROM public.sessions s2
          WHERE s2.groupe_id = g.id AND s2.deleted_at IS NULL
        )
    $sql$ USING p_groupe_id;
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.creer_classe_depuis_regroupement(text, uuid, text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_classe_depuis_regroupement(text, uuid, text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.enseignants_pour_classe(p_classe_id uuid)
RETURNS TABLE (
  teacher_id uuid,
  first_name text,
  last_name text,
  immutable_id text,
  country text,
  titre_public text,
  timezone_iana text,
  classes_actives integer,
  creneaux_pris jsonb,
  creneaux_libres jsonb
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_teacher record;
  v_pris jsonb;
  v_libres jsonb;
BEGIN
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
          AND slots.weekday = wa.weekday AND slots.hour_local = wa.hour_local
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.teacher_student_assignments tsa
        JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
        WHERE tsa.teacher_id = v_teacher.id AND tsa.ended_at IS NULL
          AND busy.weekday = wa.weekday AND busy.hour_local = wa.hour_local
      );

    teacher_id := v_teacher.id;
    first_name := v_teacher.first_name;
    last_name := v_teacher.last_name;
    immutable_id := v_teacher.immutable_id;
    country := v_teacher.country;
    titre_public := CASE v_teacher.gender
      WHEN 'female' THEN 'sayyida'
      WHEN 'male' THEN 'sayyid'
      ELSE NULL
    END;
    timezone_iana := v_teacher.timezone_iana;
    creneaux_pris := v_pris;
    creneaux_libres := v_libres;
    RETURN NEXT;
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION public.enseignants_pour_classe(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.enseignants_pour_classe(uuid) TO authenticated;

COMMENT ON FUNCTION public.enseignants_pour_classe(uuid) IS
  'C-04: entrée classe_id seule; genre/titre, langue, fuseau et toutes occurrences viennent du serveur.';

COMMIT;
