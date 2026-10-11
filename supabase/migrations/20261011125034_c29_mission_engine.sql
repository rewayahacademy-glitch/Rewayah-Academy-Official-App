BEGIN;

-- C-29 part 1: versioned control rules and their administrator API.
-- Mission assignment and lifecycle are delivered by the next migration slice.

CREATE TABLE public.controle_regles (
  version integer PRIMARY KEY CHECK (version > 0),
  missions_par_semaine integer NOT NULL CHECK (missions_par_semaine BETWEEN 0 AND 50),
  ponderations jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(ponderations) = 'object'),
  payload jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(payload) = 'object'),
  cree_par uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  cle uuid NOT NULL UNIQUE
);

CREATE TABLE public.controle_regles_cibles (
  version integer NOT NULL REFERENCES public.controle_regles(version) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('classe', 'enseignant')),
  cible_id uuid NOT NULL,
  libelle text NOT NULL CHECK (pg_catalog.btrim(libelle) <> ''),
  PRIMARY KEY (version, type, cible_id)
);

CREATE FUNCTION private.refuser_modification_regles_controle()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'les versions de règles de contrôle sont append-only'
    USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION private.refuser_modification_regles_controle()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER controle_regles_append_only
  BEFORE UPDATE OR DELETE ON public.controle_regles
  FOR EACH ROW EXECUTE FUNCTION private.refuser_modification_regles_controle();
CREATE TRIGGER controle_regles_cibles_append_only
  BEFORE UPDATE OR DELETE ON public.controle_regles_cibles
  FOR EACH ROW EXECUTE FUNCTION private.refuser_modification_regles_controle();

ALTER TABLE public.controle_regles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.controle_regles_cibles ENABLE ROW LEVEL SECURITY;
CREATE POLICY controle_regles_admin_lit ON public.controle_regles
  FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid() AND public.app_role() = 'admin', false));
CREATE POLICY controle_regles_cibles_admin_lit ON public.controle_regles_cibles
  FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid() AND public.app_role() = 'admin', false));
REVOKE ALL ON public.controle_regles, public.controle_regles_cibles
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.controle_regles, public.controle_regles_cibles TO authenticated;

CREATE FUNCTION public.capacites_tirage_controle()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'peut_lire', coalesce(public.app_account_valid() AND public.app_role() = 'admin', false),
    'peut_modifier', coalesce(
      public.app_account_valid() AND public.app_role() = 'admin'
      AND auth.jwt() ->> 'aal' = 'aal2', false
    )
  );
$function$;

CREATE FUNCTION public.lire_regles_tirage()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
  SELECT CASE WHEN NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin', false
  ) THEN pg_catalog.jsonb_build_object('erreur', 'autorisation_direction_requise')
  ELSE coalesce((
    SELECT pg_catalog.jsonb_build_object(
      'version', r.version,
      'missions_par_semaine', r.missions_par_semaine,
      'ponderations', r.ponderations,
      'cibles', coalesce((
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
          'id', c.cible_id, 'type', c.type, 'libelle', c.libelle
        ) ORDER BY c.type, c.cible_id)
        FROM public.controle_regles_cibles c WHERE c.version = r.version
      ), '[]'::jsonb)
    )
    FROM public.controle_regles r
    ORDER BY r.version DESC LIMIT 1
  ), pg_catalog.jsonb_build_object(
    'version', 0,
    'missions_par_semaine', 0,
    'ponderations', pg_catalog.jsonb_build_object(
      'enseignants_recents', 'aucun',
      'classes_signalees', 'aucun',
      'heures_de_pointe', 'aucun'
    ),
    'cibles', '[]'::jsonb
  )) END;
$function$;

CREATE FUNCTION public.candidats_cible_tirage()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_cibles jsonb;
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin'
    AND EXISTS (SELECT 1 FROM public.profiles actor WHERE actor.id = auth.uid()
      AND actor.role = 'admin' AND actor.account_status = 'active' AND actor.deleted_at IS NULL),
    false
  ) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(x.valeur ORDER BY x.nom, x.type, x.id), '[]'::jsonb)
    INTO v_cibles
    FROM (
      SELECT q.* FROM (
      SELECT g.id, g.libelle AS nom, 'classe'::text AS type,
        pg_catalog.jsonb_build_object('id', g.id, 'type', 'classe', 'libelle', g.libelle) AS valeur
      FROM public.groupes g
      WHERE g.ended_at IS NULL AND g.etat = 'active'
      UNION ALL
      SELECT p.id, pg_catalog.concat_ws(' ', p.first_name, p.last_name), 'enseignant',
        pg_catalog.jsonb_build_object('id', p.id, 'type', 'enseignant',
          'libelle', pg_catalog.concat_ws(' ', p.first_name, p.last_name))
      FROM public.profiles p
      JOIN public.teacher_profiles tp ON tp.profile_id = p.id
      WHERE p.role = 'teacher' AND p.account_status = 'active'
        AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp())
        AND p.deleted_at IS NULL AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
      ) q
      ORDER BY q.nom, q.type, q.id
      LIMIT 500
    ) x;
  RETURN pg_catalog.jsonb_build_object('cibles', v_cibles);
END;
$function$;

CREATE FUNCTION public.enregistrer_regles_tirage(p_regles jsonb, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_version integer;
  v_missions integer;
  v_ponderations jsonb;
  v_cible jsonb;
  v_type text;
  v_id uuid;
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin'
    AND auth.jwt() ->> 'aal' = 'aal2'
    AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()
      AND p.role = 'admin' AND p.account_status = 'active' AND p.deleted_at IS NULL),
    false
  ) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR pg_catalog.jsonb_typeof(p_regles) <> 'object'
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(p_regles)) <> 3
     OR NOT (p_regles ?& ARRAY['missions_par_semaine', 'ponderations', 'cibles'])
     OR pg_catalog.jsonb_typeof(p_regles->'missions_par_semaine') <> 'number'
     OR (p_regles->>'missions_par_semaine') !~ '^(0|[1-9][0-9]*)$'
     OR pg_catalog.jsonb_typeof(p_regles->'ponderations') <> 'object'
     OR pg_catalog.jsonb_typeof(p_regles->'cibles') <> 'array' THEN
    RAISE EXCEPTION 'regles de tirage invalides' USING ERRCODE = '22023';
  END IF;
  v_missions := (p_regles->>'missions_par_semaine')::integer;
  v_ponderations := p_regles->'ponderations';
  IF v_missions NOT BETWEEN 0 AND 50
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_ponderations)) <> 3
     OR NOT (v_ponderations ?& ARRAY[
       'enseignants_recents', 'classes_signalees', 'heures_de_pointe'
     ])
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_each_text(v_ponderations) x
       WHERE x.value IS NULL OR x.value NOT IN ('aucun', 'normal', 'fort'))
     OR pg_catalog.jsonb_array_length(p_regles->'cibles') > 500 THEN
    RAISE EXCEPTION 'ponderations ou limites invalides' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('controle-regles-tirage', 0)
  );
  SELECT r.version INTO v_version FROM public.controle_regles r WHERE r.cle = p_cle;
  IF FOUND THEN
    IF NOT EXISTS (SELECT 1 FROM public.controle_regles r
      WHERE r.version = v_version AND r.cree_par = auth.uid() AND r.payload = p_regles) THEN
      RAISE EXCEPTION 'cle_idempotence_deja_utilisee' USING ERRCODE = '22023';
    END IF;
    RETURN pg_catalog.jsonb_build_object('statut', 'enregistrees', 'version', v_version);
  END IF;

  FOR v_cible IN SELECT value FROM pg_catalog.jsonb_array_elements(p_regles->'cibles') LOOP
    IF pg_catalog.jsonb_typeof(v_cible) <> 'object'
       OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_cible)) <> 2
       OR NOT (v_cible ?& ARRAY['id', 'type']) THEN
      RAISE EXCEPTION 'cible invalide' USING ERRCODE = '22023';
    END IF;
    v_type := v_cible->>'type';
    BEGIN
      v_id := (v_cible->>'id')::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'identifiant de cible invalide' USING ERRCODE = '22023';
    END;
    IF v_type = 'classe' THEN
      IF NOT EXISTS (SELECT 1 FROM public.groupes g
        WHERE g.id = v_id AND g.ended_at IS NULL AND g.etat = 'active') THEN
        RAISE EXCEPTION 'classe cible indisponible' USING ERRCODE = '22023';
      END IF;
    ELSIF v_type = 'enseignant' THEN
      IF NOT EXISTS (SELECT 1 FROM public.profiles p JOIN public.teacher_profiles tp
        ON tp.profile_id = p.id WHERE p.id = v_id AND p.role = 'teacher'
        AND p.account_status = 'active' AND p.deleted_at IS NULL
        AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp())
        AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved') THEN
        RAISE EXCEPTION 'enseignant cible indisponible' USING ERRCODE = '22023';
      END IF;
    ELSE
      RAISE EXCEPTION 'type de cible invalide' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_array_elements(p_regles->'cibles'))
     <> (SELECT pg_catalog.count(DISTINCT (value->>'type', value->>'id'))
           FROM pg_catalog.jsonb_array_elements(p_regles->'cibles')) THEN
    RAISE EXCEPTION 'cibles dupliquees' USING ERRCODE = '22023';
  END IF;

  SELECT coalesce(pg_catalog.max(r.version), 0) + 1 INTO v_version
    FROM public.controle_regles r;
  INSERT INTO public.controle_regles
    (version, missions_par_semaine, ponderations, payload, cree_par, cle)
  VALUES (v_version, v_missions, v_ponderations, p_regles, auth.uid(), p_cle);
  INSERT INTO public.controle_regles_cibles (version, type, cible_id, libelle)
    SELECT v_version, x.type, x.id,
      CASE x.type WHEN 'classe' THEN g.libelle
        ELSE pg_catalog.concat_ws(' ', p.first_name, p.last_name) END
    FROM (
      SELECT value->>'type' AS type, (value->>'id')::uuid AS id
      FROM pg_catalog.jsonb_array_elements(p_regles->'cibles')
    ) x
    LEFT JOIN public.groupes g ON x.type = 'classe' AND g.id = x.id
    LEFT JOIN public.profiles p ON x.type = 'enseignant' AND p.id = x.id;
  PERFORM public.log_sensitive_access(
    'tirage_regles_modifiees', 'controle_regles', v_version::text,
    pg_catalog.jsonb_build_object('version', v_version, 'missions_par_semaine', v_missions)
  );
  RETURN pg_catalog.jsonb_build_object('statut', 'enregistrees', 'version', v_version);
END;
$function$;

REVOKE ALL ON FUNCTION public.capacites_tirage_controle() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.lire_regles_tirage() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.candidats_cible_tirage() FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.enregistrer_regles_tirage(jsonb, uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.capacites_tirage_controle() TO authenticated;
GRANT EXECUTE ON FUNCTION public.lire_regles_tirage() TO authenticated;
GRANT EXECUTE ON FUNCTION public.candidats_cible_tirage() TO authenticated;
GRANT EXECUTE ON FUNCTION public.enregistrer_regles_tirage(jsonb, uuid) TO authenticated;
ALTER FUNCTION public.enregistrer_regles_tirage(jsonb, uuid) OWNER TO postgres;
ALTER FUNCTION public.candidats_cible_tirage() OWNER TO postgres;

COMMENT ON FUNCTION public.enregistrer_regles_tirage(jsonb, uuid) IS
  'F86 candidate allowlist: signature=public.enregistrer_regles_tirage(jsonb,uuid); md5_functiondef=aa5ec79d03fa2659be4cb08cb45fc792; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: active admin aal2 stores a new immutable, audited rule version; same key/payload replays same version; changed payload is refused; targets must be active.';
COMMENT ON FUNCTION public.candidats_cible_tirage() IS
  'F86 candidate allowlist: signature=public.candidats_cible_tirage(); md5_functiondef=eb7dbf83173d2dca2917ee368fbf4289; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: active admin receives at most 500 active classes and approved active teachers sorted by display name; non-admin is refused.';

DO $postflight$
DECLARE v_signature text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.enregistrer_regles_tirage(jsonb,uuid)',
    'public.candidats_cible_tirage()'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = pg_catalog.to_regprocedure(v_signature)
        AND p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
        AND p.proconfig @> ARRAY['search_path=""']
        AND p.prosrc ILIKE '%IF NOT coalesce(%'
        AND p.prosrc ILIKE '%app_account_valid()%'
        AND (v_signature <> 'public.enregistrer_regles_tirage(jsonb,uuid)'
          OR p.prosrc ILIKE '%aal2%')
        AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE
          '%F86 candidate allowlist:%signature=' || v_signature || '; md5_functiondef=' ||
            CASE v_signature
              WHEN 'public.enregistrer_regles_tirage(jsonb,uuid)' THEN 'aa5ec79d03fa2659be4cb08cb45fc792'
              WHEN 'public.candidats_cible_tirage()' THEN 'eb7dbf83173d2dca2917ee368fbf4289'
            END || ';%'
        AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
        AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
    ) THEN RAISE EXCEPTION 'C-29/F86 garde, propriétaire, search_path ou ACL invalide: %', v_signature; END IF;
  END LOOP;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
    JOIN pg_catalog.pg_proc p ON p.oid = t.tgfoid
    WHERE t.tgname IN ('controle_regles_append_only', 'controle_regles_cibles_append_only')
      AND (t.tgenabled <> 'O' OR p.prosecdef)
  ) OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
      WHERE t.tgname IN ('controle_regles_append_only', 'controle_regles_cibles_append_only')
        AND NOT t.tgisinternal) <> 2 THEN
    RAISE EXCEPTION 'C-29: les garde-fous append-only sont absents ou SECURITY DEFINER';
  END IF;
END;
$postflight$;

COMMIT;
