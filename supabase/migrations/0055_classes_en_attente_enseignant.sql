-- 0055 — C-12 : classe créée sans enseignant, activation atomique après affectation.
-- Les sessions ne sont produites qu'après la confirmation administrative.
BEGIN;

ALTER TABLE public.groupes
  ALTER COLUMN teacher_id DROP NOT NULL,
  ADD COLUMN etat text NOT NULL DEFAULT 'active'
    CHECK (etat IN ('en_attente_enseignant', 'active')),
  ADD CONSTRAINT groupes_enseignant_etat_coherent
    CHECK (teacher_id IS NOT NULL OR etat = 'en_attente_enseignant');

CREATE TABLE public.demandes_horaires_creation_classe (
  cle_idempotence uuid PRIMARY KEY,
  regroupement_id text NOT NULL,
  groupe_id uuid NOT NULL UNIQUE REFERENCES public.groupes(id) ON DELETE CASCADE,
  cree_par uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.demandes_horaires_creation_classe ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.demandes_horaires_creation_classe FROM PUBLIC, anon, authenticated, agent_ro;

CREATE OR REPLACE FUNCTION public.tc_materialiser_apres_creation_groupe()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NEW.ended_at IS NULL
     AND NEW.teacher_id IS NOT NULL
     AND NEW.etat = 'active' THEN
    PERFORM public.materialiser_seances_groupe(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS tc_materialiser_apres_creation_groupe ON public.groupes;
CREATE TRIGGER tc_materialiser_apres_creation_groupe
AFTER INSERT OR UPDATE OF teacher_id, etat, weekday, hour_local, timezone_iana
ON public.groupes
FOR EACH ROW EXECUTE FUNCTION public.tc_materialiser_apres_creation_groupe();

-- La classe peut porter plusieurs créneaux locaux. Toutes les séances gardent
-- le même enseignant confirmé et les participants du groupe.
CREATE OR REPLACE FUNCTION public.materialiser_seances_groupe(p_groupe_id uuid)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
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
$function$;

CREATE OR REPLACE FUNCTION public.creer_classe_depuis_regroupement(
  p_regroupement_id text,
  p_cle_idempotence uuid,
  p_libelle text
)
RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_type text;
  v_langue text;
  v_fuseau text;
  v_jours smallint[];
  v_heures smallint[];
  v_nombre integer;
  v_quota integer;
  v_groupe uuid;
  v_cle text;
  v_student uuid;
  v_i integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false)
     OR p_regroupement_id IS NULL
     OR p_cle_idempotence IS NULL
     OR coalesce(btrim(p_libelle), '') = '' THEN
    RAISE EXCEPTION 'creation de classe reservee a l''administration';
  END IF;

  SELECT regroupement_id, type_public, langue_code, fuseau_iana, jours,
         heures_locales, nombre_eleves, quota
    INTO v_cle, v_type, v_langue, v_fuseau, v_jours, v_heures, v_nombre, v_quota
  FROM public.regroupements_demandes_horaires_admin() r
  WHERE r.regroupement_id = p_regroupement_id AND r.pret;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'regroupement absent ou quota non atteint';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('classe:' || p_regroupement_id, 0)
  );

  SELECT groupe_id INTO v_groupe
  FROM public.demandes_horaires_creation_classe
  WHERE cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF EXISTS (
      SELECT 1 FROM public.demandes_horaires_creation_classe
      WHERE cle_idempotence = p_cle_idempotence
        AND regroupement_id = p_regroupement_id
    ) THEN
      RETURN v_groupe;
    END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee';
  END IF;

  IF cardinality(v_jours) <> cardinality(v_heures)
     OR cardinality(v_jours) < 1
     OR cardinality(v_jours) <> (
       SELECT count(DISTINCT j) FROM unnest(v_jours) AS x(j)
     )
     OR v_nombre < v_quota THEN
    RAISE EXCEPTION 'regroupement invalide';
  END IF;

  INSERT INTO public.groupes
    (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
     timezone_iana, langue_code)
  VALUES
    (NULL, 'en_attente_enseignant', v_type, v_quota, btrim(p_libelle),
     v_jours[1], v_heures[1], v_fuseau, v_langue)
  RETURNING id INTO v_groupe;

  -- Le trigger d'ancrage crée le premier créneau; ON CONFLICT protège les
  -- variations historiques du schéma qui l'ajoutent déjà au même insert.
  FOR v_i IN 1..cardinality(v_jours) LOOP
    INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
    VALUES (v_groupe, v_jours[v_i], v_heures[v_i])
    ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;
  END LOOP;

  FOR v_student IN
    SELECT d.eleve_id
    FROM public.demandes_horaires_famille d
    JOIN public.profiles p ON p.id = d.eleve_id
    JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
    JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.actif
    JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.actif
    JOIN public.households h ON h.id = p.household_id
    WHERE d.etat = 'envoyee'
      AND d.type_public = v_type AND d.langue_code = v_langue
      AND d.fuseau_iana = v_fuseau AND d.jours = v_jours
      AND d.heures_locales = v_heures
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > now())
      AND h.status = 'active' AND h.deleted_at IS NULL
      AND sp.deleted_at IS NULL
    ORDER BY d.created_at, d.eleve_id
    LIMIT v_quota
    FOR UPDATE OF d
  LOOP
    INSERT INTO public.groupe_membres (groupe_id, student_id)
    VALUES (v_groupe, v_student);
    UPDATE public.demandes_horaires_famille
       SET etat = 'classe_validee', groupe_id = v_groupe, updated_at = now()
     WHERE eleve_id = v_student AND etat = 'envoyee';
  END LOOP;

  IF (SELECT count(*) FROM public.groupe_membres
      WHERE groupe_id = v_groupe AND left_at IS NULL) < v_quota THEN
    RAISE EXCEPTION 'les demandes ont change pendant la creation';
  END IF;

  INSERT INTO public.demandes_horaires_creation_classe
    (cle_idempotence, regroupement_id, groupe_id, cree_par)
  VALUES (p_cle_idempotence, p_regroupement_id, v_groupe, auth.uid());

  PERFORM public.log_sensitive_access(
    'classe_creee_depuis_regroupement', 'groupes', v_groupe::text,
    jsonb_build_object('regroupement_id', p_regroupement_id)
  );
  IF pg_catalog.to_regclass('public.notifications') IS NOT NULL THEN
    EXECUTE $sql$
      INSERT INTO public.notifications
        (destinataire, foyer_id, evenement, params, destination)
      SELECT DISTINCT h.primary_guardian_id, h.id, 'classe_validee',
             jsonb_build_object('groupe_id', $1), '/tuteur/demandes'
      FROM public.groupe_membres gm
      JOIN public.profiles p ON p.id = gm.student_id
      JOIN public.households h ON h.id = p.household_id
      WHERE gm.groupe_id = $1 AND gm.left_at IS NULL
        AND h.primary_guardian_id IS NOT NULL
    $sql$ USING v_groupe;
  END IF;
  RETURN v_groupe;
END;
$function$;

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
REVOKE ALL ON FUNCTION public.affecter_enseignant_classe(uuid, uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.affecter_enseignant_classe(uuid, uuid)
  TO authenticated;

COMMIT;
