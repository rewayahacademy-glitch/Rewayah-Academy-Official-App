BEGIN;

-- X2-20 slice: preserve the current B-08 projection while making a targeted
-- administrative revocation effective on every existing family read.
ALTER TABLE public.seance_resumes
  ADD COLUMN revoque_le timestamptz,
  ADD COLUMN publication_manuelle boolean NOT NULL DEFAULT false,
  ADD COLUMN version_partage bigint NOT NULL DEFAULT 1
    CHECK (version_partage > 0);

DROP POLICY seance_resumes_lecture ON public.seance_resumes;
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
      AND seance_resumes.revoque_le IS NULL
      AND coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
      AND EXISTS (
        SELECT 1
        FROM public.profiles p
        JOIN public.student_profiles sp ON sp.profile_id = p.id
        WHERE p.id = seance_resumes.student_id
          AND p.deleted_at IS NULL
          AND sp.deleted_at IS NULL
          AND (
            (p.role = 'student' AND p.household_id IS NOT NULL
              AND p.household_id = public.app_household_id())
            OR (p.id = auth.uid() AND sp.titulaire_profile_id = auth.uid())
          )
      )
    )
  );

CREATE TABLE public.pedagogie_partage_idempotence (
  actor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cle_idempotence text NOT NULL CHECK (length(btrim(cle_idempotence)) BETWEEN 1 AND 200),
  operation text NOT NULL,
  requete jsonb NOT NULL,
  resultat jsonb NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (actor_id, cle_idempotence)
);
ALTER TABLE public.pedagogie_partage_idempotence ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pedagogie_partage_idempotence FROM PUBLIC, anon, authenticated, agent_ro;

CREATE OR REPLACE FUNCTION public.revoquer_resume_seance(
  p_session_id uuid,
  p_student_id uuid,
  p_version_attendue text,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_actor uuid := auth.uid();
  v_resume public.seance_resumes%ROWTYPE;
  v_request jsonb;
  v_result jsonb;
  v_previous public.pedagogie_partage_idempotence%ROWTYPE;
BEGIN
  IF v_actor IS NULL
     OR p_session_id IS NULL
     OR p_student_id IS NULL
     OR coalesce(length(btrim(p_cle_idempotence)), 0) NOT BETWEEN 1 AND 200
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'partage pedagogique refuse';
  END IF;

  v_request := jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id,
    'version_attendue', p_version_attendue);
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text || ':' || p_cle_idempotence, 0));
  SELECT i.* INTO v_previous
    FROM public.pedagogie_partage_idempotence i
   WHERE i.actor_id = v_actor AND i.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_previous.operation <> 'revoquer'
       OR v_previous.requete IS DISTINCT FROM v_request THEN
      RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'cle idempotence reutilisee';
    END IF;
    RETURN v_previous.resultat;
  END IF;

  SELECT r.* INTO v_resume
    FROM public.seance_resumes r
   WHERE r.session_id = p_session_id AND r.student_id = p_student_id
   FOR UPDATE;
  IF NOT FOUND OR v_resume.publie_le IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'compte rendu introuvable';
  END IF;
  IF p_version_attendue IS DISTINCT FROM v_resume.version_partage::text THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'conflit_partage';
  END IF;
  IF v_resume.revoque_le IS NULL THEN
    UPDATE public.seance_resumes
       SET revoque_le = now(), version_partage = version_partage + 1, updated_at = now()
     WHERE id = v_resume.id
     RETURNING * INTO v_resume;
    PERFORM public.log_sensitive_access(
      'resume_seance_famille_revoque', 'seance_resumes',
      p_session_id::text || ':' || p_student_id::text,
      jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id,
        'version', v_resume.version_partage)
    );
  END IF;

  v_result := jsonb_build_object('session_id', p_session_id, 'eleve_id', p_student_id,
    'etat', 'revoque', 'version', v_resume.version_partage::text,
    'revoque_le', v_resume.revoque_le);
  INSERT INTO public.pedagogie_partage_idempotence
    (actor_id, cle_idempotence, operation, requete, resultat)
  VALUES (v_actor, p_cle_idempotence, 'revoquer', v_request, v_result);
  RETURN v_result;
END;
$function$;

ALTER FUNCTION public.revoquer_resume_seance(uuid, uuid, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.revoquer_resume_seance(uuid, uuid, text, text) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.revoquer_resume_seance(uuid, uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.publier_resume_seance(
  p_session_id uuid,
  p_student_id uuid,
  p_version_attendue text,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_actor uuid := auth.uid();
  v_resume public.seance_resumes%ROWTYPE;
  v_request jsonb;
  v_result jsonb;
  v_previous public.pedagogie_partage_idempotence%ROWTYPE;
BEGIN
  IF v_actor IS NULL OR p_session_id IS NULL OR p_student_id IS NULL
     OR coalesce(length(btrim(p_cle_idempotence)), 0) NOT BETWEEN 1 AND 200
     OR NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'partage pedagogique refuse';
  END IF;
  v_request := jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id,
    'version_attendue', p_version_attendue);
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text || ':' || p_cle_idempotence, 0));
  SELECT i.* INTO v_previous FROM public.pedagogie_partage_idempotence i
   WHERE i.actor_id = v_actor AND i.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_previous.operation <> 'publier' OR v_previous.requete IS DISTINCT FROM v_request THEN
      RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'cle idempotence reutilisee';
    END IF;
    RETURN v_previous.resultat;
  END IF;
  SELECT r.* INTO v_resume FROM public.seance_resumes r
   WHERE r.session_id = p_session_id AND r.student_id = p_student_id FOR UPDATE;
  IF NOT FOUND OR coalesce(length(btrim(v_resume.texte_famille)), 0) = 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'compte rendu partageable introuvable';
  END IF;
  IF p_version_attendue IS DISTINCT FROM v_resume.version_partage::text THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'conflit_partage';
  END IF;
  IF v_resume.publie_le IS NULL OR v_resume.revoque_le IS NOT NULL
     OR NOT v_resume.publication_manuelle THEN
    UPDATE public.seance_resumes
       SET publie_le = coalesce(publie_le, now()), revoque_le = NULL,
           publication_manuelle = true, version_partage = version_partage + 1,
           updated_at = now()
     WHERE id = v_resume.id
     RETURNING * INTO v_resume;
    PERFORM public.log_sensitive_access(
      'resume_seance_famille_publie_manuellement', 'seance_resumes',
      p_session_id::text || ':' || p_student_id::text,
      jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id,
        'version', v_resume.version_partage)
    );
  END IF;
  v_result := jsonb_build_object('session_id', p_session_id, 'eleve_id', p_student_id,
    'etat', 'partageManuel', 'version', v_resume.version_partage::text,
    'publie_le', v_resume.publie_le);
  INSERT INTO public.pedagogie_partage_idempotence
    (actor_id, cle_idempotence, operation, requete, resultat)
  VALUES (v_actor, p_cle_idempotence, 'publier', v_request, v_result);
  RETURN v_result;
END;
$function$;
ALTER FUNCTION public.publier_resume_seance(uuid, uuid, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.publier_resume_seance(uuid, uuid, text, text) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.publier_resume_seance(uuid, uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.resume_seance_famille(
  p_session_id uuid,
  p_student_id uuid
)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_resume text;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false)
     OR NOT EXISTS (
       SELECT 1 FROM public.profiles p
       JOIN public.student_profiles sp ON sp.profile_id = p.id
       WHERE p.id = p_student_id AND p.deleted_at IS NULL AND sp.deleted_at IS NULL
         AND ((p.role = 'student' AND p.household_id IS NOT NULL
               AND p.household_id = public.app_household_id())
              OR (p.id = v_user AND sp.titulaire_profile_id = v_user))
     ) THEN
    RAISE EXCEPTION 'resume indisponible';
  END IF;
  SELECT r.texte_famille INTO v_resume
    FROM public.seance_resumes r
   WHERE r.session_id = p_session_id AND r.student_id = p_student_id
     AND r.publie_le IS NOT NULL AND r.revoque_le IS NULL;
  RETURN v_resume;
END;
$function$;
ALTER FUNCTION public.resume_seance_famille(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.resume_seance_famille(uuid, uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.resume_seance_famille(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.progression_famille(
  p_student_id uuid,
  p_limit integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_level text;
  v_niveau_humain text;
  v_jalon_humain text;
  v_jalons jsonb;
  v_seances jsonb;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
BEGIN
  IF v_user IS NULL OR p_student_id IS NULL
     OR NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'progression indisponible';
  END IF;
  SELECT sp.level INTO v_level
    FROM public.profiles p JOIN public.student_profiles sp ON sp.profile_id = p.id
   WHERE p.id = p_student_id AND p.deleted_at IS NULL AND sp.deleted_at IS NULL
     AND ((p.role = 'student' AND p.household_id IS NOT NULL
           AND p.household_id = public.app_household_id())
          OR (p.id = v_user AND sp.titulaire_profile_id = v_user));
  IF NOT FOUND THEN RAISE EXCEPTION 'progression indisponible'; END IF;

  SELECT CASE WHEN count(DISTINCT n.nom_humain) = 1 THEN min(n.nom_humain) ELSE NULL END
    INTO v_niveau_humain
    FROM public.programme_niveaux n
    JOIN public.programme_versions v ON v.id = n.version_id
   WHERE n.code_technique = v_level AND v.statut = 'publiee';

  SELECT n.nom_humain INTO v_jalon_humain
    FROM public.seance_resumes r
    JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
   WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
     AND r.revoque_le IS NULL AND r.jalon_atteint IS NOT NULL
   ORDER BY r.publie_le DESC LIMIT 1;

  SELECT coalesce(jsonb_agg(q.nom_humain ORDER BY q.derniere_publication DESC), '[]'::jsonb)
    INTO v_jalons
    FROM (
      SELECT n.nom_humain, max(r.publie_le) AS derniere_publication
        FROM public.seance_resumes r
        JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
       WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
         AND r.revoque_le IS NULL
       GROUP BY n.nom_humain
    ) q;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'session_id', q.session_id, 'texte_famille', q.texte_famille,
    'publie_le', q.publie_le, 'jalon_humain', q.jalon_humain
  ) ORDER BY q.publie_le DESC), '[]'::jsonb)
    INTO v_seances
    FROM (
      SELECT r.session_id, r.texte_famille, r.publie_le, n.nom_humain AS jalon_humain
        FROM public.seance_resumes r
        LEFT JOIN public.programme_niveaux n ON n.id = r.jalon_atteint
       WHERE r.student_id = p_student_id AND r.publie_le IS NOT NULL
         AND r.revoque_le IS NULL
       ORDER BY r.publie_le DESC LIMIT v_limit
    ) q;

  RETURN jsonb_build_object('niveau_humain', v_niveau_humain,
    'jalon_humain', v_jalon_humain, 'jalons', v_jalons, 'seances', v_seances);
END;
$function$;
ALTER FUNCTION public.progression_famille(uuid, integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.progression_famille(uuid, integer) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.progression_famille(uuid, integer) TO authenticated;

DO $verification$
BEGIN
  IF has_function_privilege('anon', 'public.revoquer_resume_seance(uuid,uuid,text,text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.revoquer_resume_seance(uuid,uuid,text,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.publier_resume_seance(uuid,uuid,text,text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.publier_resume_seance(uuid,uuid,text,text)', 'EXECUTE')
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_policy p
       WHERE p.polrelid = 'public.seance_resumes'::regclass
         AND p.polname = 'seance_resumes_lecture'
         AND pg_catalog.pg_get_expr(p.polqual, p.polrelid) LIKE '%revoque_le%'
     ) THEN
    RAISE EXCEPTION 'X2-20 postflight: ACL ou retrait familial invalide';
  END IF;
END;
$verification$;

COMMIT;
