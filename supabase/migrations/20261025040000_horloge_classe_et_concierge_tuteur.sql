-- Arbitrage du pilote (24/10/2026, nuit) sur le concierge : (a) + tuteur.
--
-- (a) `horloge_classe(classe)` : l'horloge d'une Classe tiree de ses creneaux,
--     meme quand aucune seance n'existe. Avant, l'application ne connaissait
--     la fenetre d'entree que par l'horloge d'une seance existante
--     (`prochaine_seance_groupe` puis `horloge_seance`) : une Classe nee
--     pendant la fenetre ou dont l'horizon s'etait epuise montrait « Aucune
--     seance prevue » (ou la semaine suivante), sans bouton, et
--     `seance_a_rejoindre` n'etait jamais appele. Rendu : la meme ligne que
--     `horloge_seance`, `session_id` nul quand la seance de l'occurrence
--     n'existe pas encore. On rend la plus proche, entre la prochaine seance
--     vivante et la prochaine occurrence d'un creneau dont le cours n'est pas
--     fini ; une occurrence dont la seance a ete supprimee par la direction
--     n'est jamais rendue (la carte ne propose pas d'y entrer).
--     Memes ayants droit que `prochaine_seance_groupe` : direction,
--     enseignant de la Classe, eleve membre actif, tuteur du foyer d'un
--     membre actif.
--
-- (b) `seance_a_rejoindre` : un tuteur du foyer d'un eleve inscrit est
--     accepte (il entre avec l'eleve ; la seance rendue sert ensuite a
--     `autoriser_jeton_video_eleve`). Seul changement : la garde.
--
-- Aucune suppression.

BEGIN;

CREATE OR REPLACE FUNCTION public.horloge_classe(p_groupe_id uuid)
RETURNS TABLE (
  session_id           uuid,
  debut_utc            timestamptz,
  fin_prevue_utc       timestamptz,
  join_opens_at_utc    timestamptz,
  fenetre_minutes      int,
  grace_minutes        int,
  maintenant_utc       timestamptz,
  tz_utilisateur       text,
  heure_utilisateur    text,
  jour_iso_utilisateur int,
  date_utilisateur     date,
  tz_groupe            text,
  heure_groupe         text,
  jour_iso_groupe      int,
  date_groupe          date
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_creneau public.groupe_creneaux%ROWTYPE;
  v_fenetre integer := public.app_config_int('join_window_minutes', 20);
  v_grace integer := public.app_config_int('grace_after_end_minutes', 15);
  v_duree integer;
  v_occ timestamptz;
  v_seance public.sessions%ROWTYPE;
  v_id uuid;
  v_debut timestamptz;
  v_fin timestamptz;
  v_ouvre timestamptz;
  v_tz_u text := public.mon_fuseau();
  v_tz_g text;
BEGIN
  IF NOT coalesce(
       p_groupe_id IS NOT NULL
       AND public.app_account_valid()
       AND (
         public.app_role() = 'admin'
         OR (public.app_role() = 'teacher' AND EXISTS (
               SELECT 1 FROM public.groupes g
                WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()))
         OR EXISTS (
               SELECT 1 FROM public.groupe_membres m
                WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
                  AND (m.student_id = auth.uid()
                       OR (public.app_role() = 'guardian' AND public.est_du_foyer(m.student_id))))
       ), false) THEN
    RAISE EXCEPTION 'horloge de Classe non autorisee' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_g FROM public.groupes WHERE id = p_groupe_id;
  v_tz_g := coalesce(v_g.timezone_iana, v_tz_u);

  -- La prochaine seance vivante (la regle de prochaine_seance_groupe).
  SELECT s.* INTO v_seance
    FROM public.sessions s
   WHERE s.groupe_id = p_groupe_id
     AND s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND s.ended_at > pg_catalog.now()
   ORDER BY s.started_at, s.id
   LIMIT 1;
  IF FOUND THEN
    v_id := v_seance.id;
    v_debut := v_seance.started_at;
    v_fin := v_seance.ended_at;
    v_ouvre := coalesce(v_seance.join_opens_at,
                        v_seance.started_at - pg_catalog.make_interval(mins => v_fenetre));
  END IF;

  -- La prochaine occurrence d'un creneau, si elle vient avant et n'a pas
  -- (encore) de seance : Classe active, avec son enseignant.
  IF v_g.id IS NOT NULL AND v_g.ended_at IS NULL AND v_g.etat = 'active'
     AND v_g.teacher_id IS NOT NULL THEN
    v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
    FOR v_creneau IN
      SELECT gc.* FROM public.groupe_creneaux gc
       WHERE gc.groupe_id = p_groupe_id
       ORDER BY gc.weekday, gc.hour_local
    LOOP
      v_occ := public.instant_creneau_reference(
        v_creneau.weekday, v_creneau.hour_local, v_g.timezone_iana, 0,
        pg_catalog.now() - pg_catalog.make_interval(mins => v_duree));
      IF v_debut IS NOT NULL AND v_occ >= v_debut THEN
        CONTINUE;
      END IF;
      -- Une seance existe a cette heure (vivante, close ou supprimee) : ce
      -- n'est pas une occurrence a creer.
      IF EXISTS (SELECT 1 FROM public.sessions s
                  WHERE s.groupe_id = p_groupe_id AND s.started_at = v_occ) THEN
        CONTINUE;
      END IF;
      v_id := NULL;
      v_debut := v_occ;
      v_fin := v_occ + pg_catalog.make_interval(mins => v_duree);
      v_ouvre := v_occ - pg_catalog.make_interval(mins => v_fenetre);
    END LOOP;
  END IF;

  IF v_debut IS NULL THEN
    RETURN;
  END IF;

  session_id := v_id;
  debut_utc := v_debut;
  fin_prevue_utc := v_fin;
  join_opens_at_utc := v_ouvre;
  fenetre_minutes := v_fenetre;
  grace_minutes := v_grace;
  maintenant_utc := pg_catalog.now();
  tz_utilisateur := v_tz_u;
  heure_utilisateur := pg_catalog.to_char(v_debut AT TIME ZONE v_tz_u, 'HH24:MI');
  jour_iso_utilisateur := pg_catalog.date_part('isodow', v_debut AT TIME ZONE v_tz_u)::int;
  date_utilisateur := (v_debut AT TIME ZONE v_tz_u)::date;
  tz_groupe := v_tz_g;
  heure_groupe := pg_catalog.to_char(v_debut AT TIME ZONE v_tz_g, 'HH24:MI');
  jour_iso_groupe := pg_catalog.date_part('isodow', v_debut AT TIME ZONE v_tz_g)::int;
  date_groupe := (v_debut AT TIME ZONE v_tz_g)::date;
  RETURN NEXT;
END;
$function$;

ALTER FUNCTION public.horloge_classe(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.horloge_classe(uuid) FROM PUBLIC;
DO $droits$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION public.horloge_classe(uuid) FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;
GRANT EXECUTE ON FUNCTION public.horloge_classe(uuid) TO authenticated;

COMMENT ON FUNCTION public.horloge_classe(uuid) IS
  'Concierge (a), 24/10/2026 : horloge de la Classe tiree de ses creneaux, session_id nul tant que la seance de l''occurrence n''existe pas. Ayants droit de prochaine_seance_groupe.';

CREATE OR REPLACE FUNCTION public.seance_a_rejoindre(p_groupe_id uuid)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_g public.groupes%ROWTYPE;
  v_creneau public.groupe_creneaux%ROWTYPE;
  v_duree integer;
  v_fenetre integer;
  v_debut timestamptz;
  v_existante public.sessions%ROWTYPE;
  v_session uuid;
BEGIN
  IF p_groupe_id IS NULL THEN
    RAISE EXCEPTION 'ClasseInconnue' USING ERRCODE = '22023';
  END IF;
  IF NOT coalesce(
       public.app_account_valid() AND v_uid IS NOT NULL AND (
         public.app_role() = 'admin'
         OR EXISTS (SELECT 1 FROM public.groupes g
                    WHERE g.id = p_groupe_id AND g.teacher_id = v_uid)
         OR EXISTS (SELECT 1 FROM public.groupe_membres m
                    WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
                      AND (m.student_id = v_uid
                           OR (public.app_role() = 'guardian'
                               AND public.est_du_foyer(m.student_id))))),
       false) THEN
    RAISE EXCEPTION 'SeanceNonAutorisee' USING ERRCODE = '42501';
  END IF;

  -- Le verrou de la Classe : celui de materialiser_seances_groupe.
  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND OR v_g.teacher_id IS NULL OR v_g.etat <> 'active' THEN
    RETURN NULL;
  END IF;

  v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
  v_fenetre := public.app_config_int('join_window_minutes', 20);

  FOR v_creneau IN
    SELECT gc.* FROM public.groupe_creneaux gc
    WHERE gc.groupe_id = p_groupe_id
    ORDER BY gc.weekday, gc.hour_local
  LOOP
    -- L'occurrence dont le cours n'est pas fini : la premiere qui commence
    -- apres (maintenant - duree).
    v_debut := public.instant_creneau_reference(
      v_creneau.weekday, v_creneau.hour_local, v_g.timezone_iana, 0,
      pg_catalog.now() - pg_catalog.make_interval(mins => v_duree));
    IF v_debut - pg_catalog.make_interval(mins => v_fenetre) > pg_catalog.now() THEN
      CONTINUE;  -- la salle n'ouvre pas encore
    END IF;

    SELECT s.* INTO v_existante
    FROM public.sessions s
    WHERE s.groupe_id = p_groupe_id AND s.started_at = v_debut
    ORDER BY (s.deleted_at IS NULL) DESC, s.created_at
    LIMIT 1;
    IF FOUND THEN
      IF v_existante.deleted_at IS NOT NULL THEN
        CONTINUE;
      END IF;
      RETURN v_existante.id;
    END IF;

    INSERT INTO public.sessions
      (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
    VALUES
      (v_g.teacher_id, v_debut,
       v_debut + pg_catalog.make_interval(mins => v_duree),
       CASE v_g.type_public WHEN 'enfant' THEN 'child' ELSE 'standard' END,
       p_groupe_id, v_debut - pg_catalog.make_interval(mins => v_fenetre))
    RETURNING id INTO v_session;

    INSERT INTO public.session_participants (session_id, profile_id, role)
    SELECT v_session, m.student_id, 'student'
    FROM public.groupe_membres m
    WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;

    RETURN v_session;
  END LOOP;
  RETURN NULL;
END;
$function$;

COMMIT;
