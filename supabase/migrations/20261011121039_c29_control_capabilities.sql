BEGIN;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TABLE private.controle_capacites (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  approved_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  active_from timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  scope_all_groups boolean NOT NULL DEFAULT false,
  scope_group_ids uuid[] NOT NULL DEFAULT '{}',
  scope_teacher_ids uuid[] NOT NULL DEFAULT '{}',
  grant_idempotency_key uuid NOT NULL,
  granted_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  revoked_at timestamptz,
  revoked_by uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  revoke_reason text,
  revoke_idempotency_key uuid,
  CONSTRAINT controle_capacites_dates CHECK (expires_at > active_from),
  CONSTRAINT controle_capacites_scope CHECK (
    (scope_all_groups AND cardinality(scope_group_ids) = 0
                     AND cardinality(scope_teacher_ids) = 0)
    OR (NOT scope_all_groups
        AND (cardinality(scope_group_ids) > 0 OR cardinality(scope_teacher_ids) > 0))
  ),
  CONSTRAINT controle_capacites_revocation_complete CHECK (
    (revoked_at IS NULL AND revoked_by IS NULL AND revoke_reason IS NULL
                       AND revoke_idempotency_key IS NULL)
    OR (revoked_at IS NOT NULL AND revoked_by IS NOT NULL
        AND nullif(pg_catalog.btrim(revoke_reason), '') IS NOT NULL
        AND revoke_idempotency_key IS NOT NULL)
  ),
  CONSTRAINT controle_capacites_grant_key UNIQUE (approved_by, grant_idempotency_key),
  CONSTRAINT controle_capacites_revoke_key UNIQUE (approved_by, revoke_idempotency_key)
);

CREATE UNIQUE INDEX controle_capacites_une_active_par_profil
  ON private.controle_capacites (profile_id) WHERE revoked_at IS NULL;
CREATE INDEX controle_capacites_actives_idx
  ON private.controle_capacites (profile_id, active_from, expires_at)
  WHERE revoked_at IS NULL;

ALTER TABLE private.controle_capacites ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.controle_capacites FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON TABLE private.controle_capacites IS
  'Capacités Contrôle attribuées par la Direction, bornées dans le temps et par périmètre. Aucune lecture ou écriture directe par les rôles API.';

CREATE FUNCTION public.accorder_capacite_controle(
  p_profile_id uuid,
  p_active_from timestamptz,
  p_expires_at timestamptz,
  p_scope_all_groups boolean,
  p_scope_group_ids uuid[],
  p_scope_teacher_ids uuid[],
  p_cle_envoi uuid
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_group_ids uuid[];
  v_teacher_ids uuid[];
  v_existing private.controle_capacites%ROWTYPE;
  v_replaced private.controle_capacites%ROWTYPE;
  v_id uuid;
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
    AND public.app_role() = 'admin'
    AND auth.jwt() ->> 'aal' = 'aal2'
    AND EXISTS (
      SELECT 1 FROM public.profiles actor
       WHERE actor.id = auth.uid() AND actor.role = 'admin'
         AND actor.account_status = 'active' AND actor.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_profile_id IS NULL OR p_active_from IS NULL OR p_expires_at IS NULL
     OR p_scope_all_groups IS NULL
     OR p_cle_envoi IS NULL OR p_expires_at <= p_active_from
     OR p_expires_at <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'parametres de capacite invalides';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = p_profile_id AND p.deleted_at IS NULL
       AND p.account_status = 'active'
       AND p.role IN ('admin', 'teacher', 'controller')
  ) THEN
    RAISE EXCEPTION 'profil controleur indisponible';
  END IF;

  SELECT coalesce(pg_catalog.array_agg(x.id ORDER BY x.id), '{}'::uuid[])
    INTO v_group_ids
    FROM (SELECT DISTINCT unnest(coalesce(p_scope_group_ids, '{}'::uuid[])) AS id) x;
  SELECT coalesce(pg_catalog.array_agg(x.id ORDER BY x.id), '{}'::uuid[])
    INTO v_teacher_ids
    FROM (SELECT DISTINCT unnest(coalesce(p_scope_teacher_ids, '{}'::uuid[])) AS id) x;

  IF coalesce(p_scope_all_groups, false) THEN
    IF cardinality(v_group_ids) > 0 OR cardinality(v_teacher_ids) > 0 THEN
      RAISE EXCEPTION 'portee globale incompatible avec des cibles explicites';
    END IF;
  ELSIF cardinality(v_group_ids) = 0 AND cardinality(v_teacher_ids) = 0 THEN
    RAISE EXCEPTION 'portee de controle vide';
  END IF;
  IF cardinality(v_group_ids) > 0 AND (
    SELECT count(*) FROM public.groupes g
     WHERE g.id = ANY(v_group_ids) AND g.ended_at IS NULL
  ) <> cardinality(v_group_ids) THEN
    RAISE EXCEPTION 'groupe cible indisponible';
  END IF;
  IF cardinality(v_teacher_ids) > 0 AND (
    SELECT count(*) FROM public.profiles p
     WHERE p.id = ANY(v_teacher_ids) AND p.role = 'teacher'
       AND p.deleted_at IS NULL AND p.account_status = 'active'
  ) <> cardinality(v_teacher_ids) THEN
    RAISE EXCEPTION 'enseignant cible indisponible';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('controle-capacite:' || p_profile_id::text, 0)
  );
  SELECT c.* INTO v_existing
    FROM private.controle_capacites c
   WHERE c.approved_by = auth.uid() AND c.grant_idempotency_key = p_cle_envoi;
  IF FOUND THEN
    IF v_existing.profile_id = p_profile_id
       AND v_existing.active_from = p_active_from
       AND v_existing.expires_at = p_expires_at
       AND v_existing.scope_all_groups = p_scope_all_groups
       AND v_existing.scope_group_ids = v_group_ids
       AND v_existing.scope_teacher_ids = v_teacher_ids THEN
      RETURN v_existing.id;
    END IF;
    RAISE EXCEPTION 'cle de capacite deja utilisee';
  END IF;

  UPDATE private.controle_capacites
     SET revoked_at = pg_catalog.clock_timestamp(), revoked_by = auth.uid(),
         revoke_reason = 'remplacement par une nouvelle capacite',
         revoke_idempotency_key = pg_catalog.gen_random_uuid()
   WHERE profile_id = p_profile_id AND revoked_at IS NULL
  RETURNING * INTO v_replaced;
  IF FOUND THEN
    PERFORM public.log_sensitive_access(
      'controle_capacite_retiree', 'private.controle_capacites', v_replaced.id::text,
      pg_catalog.jsonb_build_object(
        'profile_id', p_profile_id,
        'motif', 'remplacement par une nouvelle capacite'
      )
    );
  END IF;

  INSERT INTO private.controle_capacites (
    profile_id, approved_by, active_from, expires_at,
    scope_all_groups, scope_group_ids, scope_teacher_ids, grant_idempotency_key
  ) VALUES (
    p_profile_id, auth.uid(), p_active_from, p_expires_at,
    p_scope_all_groups, v_group_ids, v_teacher_ids, p_cle_envoi
  ) RETURNING id INTO v_id;

  PERFORM public.log_sensitive_access(
    'controle_capacite_accordee', 'private.controle_capacites', v_id::text,
    pg_catalog.jsonb_build_object(
      'profile_id', p_profile_id, 'active_from', p_active_from,
      'expires_at', p_expires_at, 'scope_all_groups', p_scope_all_groups,
      'scope_group_ids', v_group_ids, 'scope_teacher_ids', v_teacher_ids
    )
  );
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.retirer_capacite_controle(
  p_capacite_id uuid,
  p_motif text,
  p_cle_envoi uuid
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_row private.controle_capacites%ROWTYPE;
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
    AND public.app_role() = 'admin'
    AND auth.jwt() ->> 'aal' = 'aal2'
    AND EXISTS (
      SELECT 1 FROM public.profiles actor
       WHERE actor.id = auth.uid() AND actor.role = 'admin'
         AND actor.account_status = 'active' AND actor.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_capacite_id IS NULL OR p_cle_envoi IS NULL
     OR pg_catalog.length(v_motif) NOT BETWEEN 1 AND 240 THEN
    RAISE EXCEPTION 'parametres de retrait invalides';
  END IF;
  SELECT c.* INTO v_row
    FROM private.controle_capacites c
   WHERE c.id = p_capacite_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  IF v_row.revoked_at IS NOT NULL THEN
    IF v_row.approved_by = auth.uid() AND v_row.revoke_idempotency_key = p_cle_envoi THEN
      RETURN false;
    END IF;
    RETURN false;
  END IF;
  UPDATE private.controle_capacites
     SET revoked_at = pg_catalog.clock_timestamp(), revoked_by = auth.uid(),
         revoke_reason = v_motif, revoke_idempotency_key = p_cle_envoi
   WHERE id = p_capacite_id;
  PERFORM public.log_sensitive_access(
    'controle_capacite_retiree', 'private.controle_capacites', p_capacite_id::text,
    pg_catalog.jsonb_build_object('profile_id', v_row.profile_id, 'motif', v_motif)
  );
  RETURN true;
END;
$function$;

CREATE FUNCTION public.ma_capacite_controle_active()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
    AND auth.uid() IS NOT NULL
    AND auth.jwt() ->> 'aal' = 'aal2'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
       WHERE p.id = auth.uid()
         AND p.role IN ('admin', 'teacher', 'controller')
         AND p.account_status = 'active' AND p.deleted_at IS NULL
    ),
    false
  ) THEN
    RETURN false;
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM private.controle_capacites c
     WHERE c.profile_id = auth.uid() AND c.revoked_at IS NULL
       AND c.active_from <= pg_catalog.clock_timestamp()
       AND c.expires_at > pg_catalog.clock_timestamp()
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.retirer_capacite_controle(uuid,text,uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.ma_capacite_controle_active()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.retirer_capacite_controle(uuid,text,uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.ma_capacite_controle_active()
  TO authenticated;

COMMENT ON FUNCTION public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid) IS
  'F79 candidate allowlist: signature=public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid); md5_prosrc=1949480f7b43b7de9724049cf7f247e1; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: admin account with aal2 grants only active teacher/admin/controller profiles; grant is scoped, audited and idempotent; aal1/non-admin cannot grant.';
COMMENT ON FUNCTION public.retirer_capacite_controle(uuid,text,uuid) IS
  'F79 candidate allowlist: signature=public.retirer_capacite_controle(uuid,text,uuid); md5_prosrc=d95932d9af9c9ed55111ec1fdb0cb29b; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: only active admin aal2 revokes; revocation is immediate, scoped, audited and idempotent.';
COMMENT ON FUNCTION public.ma_capacite_controle_active() IS
  'F79 candidate allowlist: signature=public.ma_capacite_controle_active(); md5_prosrc=c9fb15780e387e635e2861732e133229; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: only auth.uid() active capability is evaluated; account, role, expiry, revocation and aal2 are checked.';

DO $postflight$
DECLARE v_signature text;
BEGIN
  FOREACH v_signature IN ARRAY ARRAY[
    'public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)',
    'public.retirer_capacite_controle(uuid,text,uuid)',
    'public.ma_capacite_controle_active()'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid = pg_catalog.to_regprocedure(v_signature)
         AND p.prosecdef
         AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
         AND p.proconfig @> ARRAY['search_path=""']
         AND p.prosrc ILIKE '%IF NOT coalesce(%'
         AND p.prosrc ILIKE '%app_account_valid()%'
         AND p.prosrc ILIKE '%aal2%'
         AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE
             '%F79 candidate allowlist:%signature=' || v_signature || '; md5_prosrc=' ||
               CASE v_signature
                 WHEN 'public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)' THEN '1949480f7b43b7de9724049cf7f247e1'
                 WHEN 'public.retirer_capacite_controle(uuid,text,uuid)' THEN 'd95932d9af9c9ed55111ec1fdb0cb29b'
                 WHEN 'public.ma_capacite_controle_active()' THEN 'c9fb15780e387e635e2861732e133229'
               END || ';%'
         AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
         AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
         AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
         AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
    ) THEN
      RAISE EXCEPTION 'C-29/F86 allowlist, owner, search_path ou ACL invalide: %', v_signature;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'private.controle_capacites', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'private.controle_capacites', 'SELECT') THEN
    RAISE EXCEPTION 'C-29: la table des capacités ne doit pas être directement lisible';
  END IF;
END;
$postflight$;

COMMIT;
