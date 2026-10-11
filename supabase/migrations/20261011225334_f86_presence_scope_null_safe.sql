BEGIN;

-- F86: authorization scope must deny SQL NULL when a valid account has no role.
CREATE OR REPLACE FUNCTION public.etat_presence(
  p_session_id uuid,
  p_profile_id uuid
) RETURNS public.presence_state
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_seance         public.sessions%ROWTYPE;
  v_seance_trouvee boolean;
  v_override       public.presence_state;
  v_premier_joined timestamptz;
  v_dernier_type   public.session_event_type;
  v_dernier_ts     timestamptz;
  v_dernier_source text;
  v_left_subi      boolean;
  v_jeton_le       timestamptz;
  v_seuil_retard   int := public.app_config_int('presence.seuil_retard_secondes', 300);
  v_fenetre_reco   int := public.app_config_int('presence.fenetre_reconnexion_secondes', 120);
  v_fenetre_conn   int := public.app_config_int('presence.fenetre_connexion_secondes', 90);
  v_fenetre_join   int := public.app_config_int('join_window_minutes', 20);
BEGIN
  IF NOT public.app_account_valid() THEN
    RAISE EXCEPTION 'compte non valide' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_seance FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  v_seance_trouvee := FOUND;

  -- Keep the exact four authorized paths; NULL in any branch now denies access.
  IF NOT coalesce(
    public.app_role() = ANY (ARRAY['admin', 'controller']::public.app_role[])
    OR (v_seance_trouvee AND v_seance.teacher_id = auth.uid())
    OR (public.app_role() = 'guardian' AND public.est_du_foyer(p_profile_id))
    OR p_profile_id = auth.uid(),
    false
  ) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT v_seance_trouvee THEN
    RETURN NULL;
  END IF;

  SELECT o.etat INTO v_override FROM public.session_presence_override o
   WHERE o.session_id = p_session_id AND o.profile_id = p_profile_id;
  IF v_override IS NOT NULL THEN
    RETURN v_override;
  END IF;

  SELECT min(e.server_ts) INTO v_premier_joined
    FROM public.session_events e
   WHERE e.session_id = p_session_id
     AND e.profile_id = p_profile_id
     AND e.event_type = 'joined';

  SELECT e.event_type, e.server_ts, e.source
    INTO v_dernier_type, v_dernier_ts, v_dernier_source
    FROM public.session_events e
   WHERE e.session_id = p_session_id
     AND e.profile_id = p_profile_id
     AND e.event_type IN ('joined', 'left', 'track_subscribed')
   ORDER BY e.server_ts DESC, e.id DESC
   LIMIT 1;

  IF v_premier_joined IS NULL THEN
    IF v_seance.status IN ('ended', 'teacher_absent', 'student_absent') THEN
      RETURN 'absente';
    END IF;

    SELECT max(g.emis_le) INTO v_jeton_le
      FROM public.video_token_grants g
     WHERE g.session_id = p_session_id
       AND g.profile_id = p_profile_id;

    IF v_jeton_le IS NOT NULL
       AND now() - v_jeton_le <= make_interval(secs => v_fenetre_conn) THEN
      RETURN 'en_connexion';
    END IF;

    IF now() < v_seance.started_at - make_interval(mins => v_fenetre_join) THEN
      RETURN 'planifiee';
    END IF;
    RETURN 'en_attente';
  END IF;

  IF v_dernier_type = 'left' THEN
    IF v_dernier_source = 'user_action' THEN
      RETURN 'sortie';
    END IF;
    IF now() - v_dernier_ts <= make_interval(secs => v_fenetre_reco) THEN
      RETURN 'en_reconnexion';
    END IF;
    RETURN 'deconnectee';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.session_events e
     WHERE e.session_id = p_session_id
       AND e.profile_id = p_profile_id
       AND e.event_type = 'left'
       AND e.source <> 'user_action'
       AND e.server_ts < v_dernier_ts
  ) INTO v_left_subi;

  IF v_left_subi THEN
    RETURN 'reconnectee';
  END IF;

  IF v_premier_joined > v_seance.started_at + make_interval(secs => v_seuil_retard) THEN
    RETURN 'en_retard';
  END IF;

  IF v_seance.status IN ('ended', 'teacher_absent', 'student_absent') THEN
    RETURN 'confirmation_en_attente';
  END IF;

  RETURN 'presente';
END;
$function$;
ALTER FUNCTION public.etat_presence(uuid, uuid) OWNER TO postgres;
COMMENT ON FUNCTION public.etat_presence(uuid, uuid) IS
  'F86 candidate allowlist: signature=public.etat_presence(uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: require valid account; null-safe allowlist for admin/controller, session teacher, household guardian, or self; all other scopes denied.';

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.etat_presence(uuid,uuid)');
  v_definition text;
BEGIN
  IF v_oid IS NULL THEN
    RAISE EXCEPTION 'F86: public.etat_presence(uuid,uuid) is missing';
  END IF;
  SELECT pg_catalog.pg_get_functiondef(v_oid) INTO v_definition;
  IF NOT (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
          FROM pg_catalog.pg_proc p WHERE p.oid = v_oid)
     OR pg_catalog.strpos(pg_catalog.lower(v_definition), 'if not coalesce(') = 0
     OR pg_catalog.strpos(pg_catalog.lower(v_definition), 'public.est_du_foyer(p_profile_id)') = 0
     OR pg_catalog.strpos(pg_catalog.lower(v_definition), 'p_profile_id = auth.uid()') = 0
     OR coalesce(pg_catalog.obj_description(v_oid, 'pg_proc'), '')
        NOT LIKE '%md5_functiondef=A_CALCULER%' THEN
    RAISE EXCEPTION 'F86: etat_presence scope postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
