BEGIN;

-- B-09 replacement events are append-only. The effective teacher for a session
-- is the most recent accepted or admin-assigned replacement; sessions.teacher_id
-- remains the titular teacher and is never overwritten.
CREATE TABLE public.remplacements_seance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE RESTRICT,
  evenement text NOT NULL CHECK (evenement IN (
    'absence_declaree', 'remplacement_pris', 'remplacement_designe_admin'
  )),
  enseignant_titulaire_id uuid NOT NULL REFERENCES public.profiles(id),
  enseignant_remplacant_id uuid REFERENCES public.profiles(id),
  acteur_id uuid NOT NULL REFERENCES public.profiles(id),
  cle_idempotence uuid NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT remplacements_seance_payload_check CHECK (
    (evenement = 'absence_declaree' AND enseignant_remplacant_id IS NULL)
    OR (evenement IN ('remplacement_pris', 'remplacement_designe_admin')
        AND enseignant_remplacant_id IS NOT NULL
        AND enseignant_remplacant_id <> enseignant_titulaire_id)
  ),
  CONSTRAINT remplacements_seance_idempotence_unique UNIQUE (acteur_id, cle_idempotence)
);
CREATE INDEX remplacements_seance_session_latest_idx
  ON public.remplacements_seance (session_id, cree_le DESC, id DESC);
ALTER TABLE public.remplacements_seance ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.remplacements_seance FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.remplacements_seance_immutable()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
BEGIN
  RAISE EXCEPTION 'RemplacementsAppendOnly' USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION public.remplacements_seance_immutable()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER remplacements_seance_no_update
  BEFORE UPDATE OR DELETE ON public.remplacements_seance
  FOR EACH ROW EXECUTE FUNCTION public.remplacements_seance_immutable();

CREATE FUNCTION public.remplacement_enseignant_compatible(
  p_session_id uuid, p_teacher_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id
      JOIN public.profiles p ON p.id = p_teacher_id
      JOIN public.teacher_profiles tp ON tp.profile_id = p.id
     WHERE s.id = p_session_id
       AND s.deleted_at IS NULL
       AND s.groupe_id IS NOT NULL
       AND g.ended_at IS NULL
       AND p.role = 'teacher'
       AND p.gender IS NOT NULL
       AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
       AND tp.deleted_at IS NULL
       AND tp.kyc_status = 'approved'
       AND (g.genre_public = 'indetermine'
            OR (g.genre_public = 'hommes' AND p.gender = 'male')
            OR (g.genre_public = 'femmes' AND p.gender = 'female'))
  );
$function$;
ALTER FUNCTION public.remplacement_enseignant_compatible(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remplacement_enseignant_compatible(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.remplacements_seance_notifier_enseignants()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
DECLARE v_evenement text;
BEGIN
  IF NEW.evenement = 'absence_declaree' THEN
    v_evenement := 'remplacement_propose';
  ELSE
    v_evenement := 'remplacement_pris';
  END IF;
  INSERT INTO public.notifications (destinataire, evenement, params, destination)
  SELECT p.id, v_evenement,
         pg_catalog.jsonb_build_object('session_id', NEW.session_id),
         '/enseignant/journee/remplacements'
    FROM public.profiles p
    JOIN public.teacher_profiles tp ON tp.profile_id = p.id
   WHERE p.role = 'teacher'
     AND p.id <> NEW.enseignant_titulaire_id
     AND (NEW.evenement <> 'remplacement_pris'
          OR p.id <> NEW.enseignant_remplacant_id)
     AND p.account_status = 'active'
     AND p.deleted_at IS NULL
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
     AND tp.deleted_at IS NULL
     AND tp.kyc_status = 'approved'
     AND public.remplacement_enseignant_compatible(NEW.session_id, p.id);
  RETURN NEW;
END;
$function$;
ALTER FUNCTION public.remplacements_seance_notifier_enseignants() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remplacements_seance_notifier_enseignants()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER remplacements_seance_notifications
  AFTER INSERT ON public.remplacements_seance
  FOR EACH ROW EXECUTE FUNCTION public.remplacements_seance_notifier_enseignants();
CREATE FUNCTION public.declarer_absence_seance(
  p_session_id uuid, p_cle_idempotence uuid
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_session public.sessions%ROWTYPE; v_existing public.remplacements_seance%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE acteur_id = auth.uid() AND cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_existing.session_id <> p_session_id OR v_existing.evenement <> 'absence_declaree' THEN
      RAISE EXCEPTION 'CleIdempotenceDejaUtilisee' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('etat', 'absence_declaree', 'sessionId', p_session_id);
  END IF;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  IF NOT FOUND OR v_session.deleted_at IS NOT NULL OR v_session.status <> 'planned'
     OR v_session.started_at <= pg_catalog.now() OR v_session.groupe_id IS NULL THEN
    RAISE EXCEPTION 'SeanceIndisponible' USING ERRCODE = 'P0002';
  END IF;
  IF v_session.teacher_id <> auth.uid() THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
  IF FOUND THEN
    IF v_existing.acteur_id = auth.uid() AND v_existing.cle_idempotence = p_cle_idempotence THEN
      RETURN jsonb_build_object('etat', v_existing.evenement, 'sessionId', p_session_id);
    END IF;
    RAISE EXCEPTION 'RemplacementDejaDeclare' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence)
  VALUES (p_session_id, 'absence_declaree', v_session.teacher_id, auth.uid(), p_cle_idempotence);
  PERFORM public.log_sensitive_access('replacement_absence_declared', 'remplacements_seance',
    p_session_id::text, jsonb_build_object('session_id', p_session_id));
  RETURN jsonb_build_object('etat', 'absence_declaree', 'sessionId', p_session_id);
END;
$function$;

CREATE FUNCTION public.prendre_remplacement(
  p_session_id uuid, p_cle_idempotence uuid
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_session public.sessions%ROWTYPE; v_existing public.remplacements_seance%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE acteur_id = auth.uid() AND cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_existing.session_id <> p_session_id OR v_existing.evenement <> 'remplacement_pris' THEN
      RAISE EXCEPTION 'CleIdempotenceDejaUtilisee' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
  END IF;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  IF NOT FOUND OR v_session.deleted_at IS NOT NULL OR v_session.status <> 'planned'
     OR v_session.started_at <= pg_catalog.now() OR v_session.groupe_id IS NULL THEN
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  IF NOT public.remplacement_enseignant_compatible(p_session_id, auth.uid()) THEN
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
  IF NOT FOUND OR v_existing.evenement <> 'absence_declaree' THEN
    IF FOUND AND v_existing.acteur_id = auth.uid()
       AND v_existing.cle_idempotence = p_cle_idempotence THEN
      RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
    END IF;
    RETURN jsonb_build_object('etat', 'dejaPrise');
  END IF;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES (p_session_id, 'remplacement_pris', v_session.teacher_id, auth.uid(),
          auth.uid(), p_cle_idempotence);
  PERFORM public.log_sensitive_access('replacement_claimed', 'remplacements_seance',
    p_session_id::text, jsonb_build_object('session_id', p_session_id));
  RETURN jsonb_build_object('etat', 'acceptee', 'sessionId', p_session_id);
END;
$function$;

CREATE FUNCTION public.designer_remplacant_admin(
  p_session_id uuid, p_remplacant_id uuid, p_cle_idempotence uuid
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_session public.sessions%ROWTYPE; v_existing public.remplacements_seance%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  IF p_session_id IS NULL OR p_remplacant_id IS NULL OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'RemplacementParametresInvalides' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE acteur_id = auth.uid() AND cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_existing.session_id <> p_session_id OR v_existing.evenement <> 'remplacement_designe_admin'
       OR v_existing.enseignant_remplacant_id <> p_remplacant_id THEN
      RAISE EXCEPTION 'CleIdempotenceDejaUtilisee' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('etat', 'designe', 'sessionId', p_session_id);
  END IF;
  SELECT * INTO v_session FROM public.sessions WHERE id = p_session_id FOR UPDATE;
  IF NOT FOUND OR v_session.deleted_at IS NOT NULL OR v_session.status <> 'planned'
     OR v_session.started_at <= pg_catalog.now() OR v_session.groupe_id IS NULL THEN
    RAISE EXCEPTION 'SeanceIndisponible' USING ERRCODE = 'P0002';
  END IF;
  IF NOT public.remplacement_enseignant_compatible(p_session_id, p_remplacant_id)
     OR p_remplacant_id = v_session.teacher_id THEN
    RAISE EXCEPTION 'RemplacantIncompatible' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_existing FROM public.remplacements_seance
   WHERE session_id = p_session_id ORDER BY cree_le DESC, id DESC LIMIT 1;
  IF FOUND AND v_existing.evenement IN ('remplacement_pris', 'remplacement_designe_admin') THEN
    IF v_existing.acteur_id = auth.uid() AND v_existing.cle_idempotence = p_cle_idempotence
       AND v_existing.enseignant_remplacant_id = p_remplacant_id THEN
      RETURN jsonb_build_object('etat', 'designe', 'sessionId', p_session_id);
    END IF;
    RAISE EXCEPTION 'RemplacementDejaPris' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES (p_session_id, 'remplacement_designe_admin', v_session.teacher_id,
          p_remplacant_id, auth.uid(), p_cle_idempotence);
  PERFORM public.log_sensitive_access('replacement_admin_assigned', 'remplacements_seance',
    p_session_id::text,
    jsonb_build_object('session_id', p_session_id, 'replacement_teacher_id', p_remplacant_id));
  RETURN jsonb_build_object('etat', 'designe', 'sessionId', p_session_id);
END;
$function$;

REVOKE ALL ON FUNCTION public.declarer_absence_seance(uuid, uuid),
  public.prendre_remplacement(uuid, uuid),
  public.designer_remplacant_admin(uuid, uuid, uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.declarer_absence_seance(uuid, uuid),
  public.prendre_remplacement(uuid, uuid),
  public.designer_remplacant_admin(uuid, uuid, uuid) TO authenticated;
ALTER FUNCTION public.declarer_absence_seance(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION public.prendre_remplacement(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid) OWNER TO postgres;

COMMENT ON FUNCTION public.declarer_absence_seance(uuid, uuid) IS
  'F86 candidate allowlist: signature=public.declarer_absence_seance(uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: titulaire actif peut declarer une absence planifiee une fois, idempotence conservee, audit append-only.';
COMMENT ON FUNCTION public.prendre_remplacement(uuid, uuid) IS
  'F86 candidate allowlist: signature=public.prendre_remplacement(uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: premier enseignant actif compatible gagne atomiquement; second voit dejaPrise; audit append-only.';
COMMENT ON FUNCTION public.designer_remplacant_admin(uuid, uuid, uuid) IS
  'F86 candidate allowlist: signature=public.designer_remplacant_admin(uuid,uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: admin actif assigne un enseignant compatible; enseignant non-admin refuse; audit append-only.';

DO $postflight$
DECLARE f record;
BEGIN
  FOR f IN SELECT p.oid, p.prosrc, p.proconfig, p.proowner, p.prosecdef,
                  pg_catalog.obj_description(p.oid, 'pg_proc') AS comment,
                  p.proname, p.oid::regprocedure::text AS signature
             FROM pg_catalog.pg_proc p
             JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public'
              AND p.proname IN ('declarer_absence_seance','prendre_remplacement','designer_remplacant_admin')
  LOOP
    IF NOT f.prosecdef OR pg_catalog.pg_get_userbyid(f.proowner) <> 'postgres'
       OR f.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[]
       OR f.prosrc NOT ILIKE '%app_account_valid()%'
       OR f.prosrc NOT ILIKE '%app_role() = %'
       OR f.comment NOT LIKE '%F86 candidate allowlist:%signature=' || f.signature || '; md5_functiondef=A_CALCULER;%'
       OR pg_catalog.has_function_privilege('anon', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', f.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', f.oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'B-09: securite/F86 invalide pour %', f.signature;
    END IF;
  END LOOP;
END;
$postflight$;

COMMIT;
