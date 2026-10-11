-- F69 K-65: Super-admin KYC controls are operator-only. Client admins cannot
-- grant the exception or change its global switch through app_config.
BEGIN;

CREATE SCHEMA IF NOT EXISTS app_private;
-- Preserve the legacy nullable profile FK while adding the operator principal
-- named by K-65. This table is private and the legacy field has no readers.
ALTER TABLE private.super_admin_kyc RENAME COLUMN granted_by TO granted_by_profile_id;
ALTER TABLE private.super_admin_kyc
  ADD COLUMN IF NOT EXISTS motif text,
  ADD COLUMN granted_by text NOT NULL DEFAULT 'postgres'
    CHECK (granted_by = 'postgres');
UPDATE private.super_admin_kyc
SET motif = coalesce(motif, 'legacy_assignment');
ALTER TABLE private.super_admin_kyc
  ALTER COLUMN motif SET DEFAULT 'legacy_assignment',
  ALTER COLUMN motif SET NOT NULL;
COMMENT ON COLUMN private.super_admin_kyc.granted_by_profile_id IS
  'FK UUID legacy; les nouvelles écritures opérateur utilisent granted_by.';
COMMENT ON COLUMN private.super_admin_kyc.granted_by IS
  'Principal opérateur hors client. Seule valeur admise: postgres.';
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON TABLE private.super_admin_kyc
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT USAGE ON SCHEMA private TO postgres;

CREATE OR REPLACE PROCEDURE app_private.attribuer_super_admin_kyc(
  p_profile_id uuid, p_motif text
)
LANGUAGE plpgsql SET search_path = ''
AS $procedure$
BEGIN
  IF current_user IS DISTINCT FROM 'postgres' THEN
    RAISE EXCEPTION 'procedure reservee au role postgres' USING ERRCODE = '42501';
  END IF;
  IF p_profile_id IS NULL OR coalesce(btrim(p_motif), '') = ''
     OR length(btrim(p_motif)) > 1000 THEN
    RAISE EXCEPTION 'profil et motif requis' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id AND p.role = 'admin'
      AND p.account_status = 'active' AND p.deleted_at IS NULL
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
  ) THEN
    RAISE EXCEPTION 'le profil cible doit etre un administrateur actif' USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.super_admin_kyc(profile_id, granted_by, motif)
  VALUES (p_profile_id, 'postgres', btrim(p_motif))
  ON CONFLICT (profile_id) DO UPDATE
    SET granted_at = pg_catalog.now(), granted_by = 'postgres',
        motif = excluded.motif;
  PERFORM public.log_sensitive_access(
    'super_admin_kyc_attribue', 'private.super_admin_kyc', p_profile_id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profile_id, 'motif', btrim(p_motif),
      'granted_by', 'postgres')
  );
END;
$procedure$;
ALTER PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text) OWNER TO postgres;
REVOKE ALL ON PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text) TO postgres;

CREATE OR REPLACE PROCEDURE app_private.retirer_super_admin_kyc(
  p_profile_id uuid, p_motif text
)
LANGUAGE plpgsql SET search_path = ''
AS $procedure$
DECLARE
  v_lignes integer;
BEGIN
  IF current_user IS DISTINCT FROM 'postgres' THEN
    RAISE EXCEPTION 'procedure reservee au role postgres' USING ERRCODE = '42501';
  END IF;
  IF p_profile_id IS NULL OR coalesce(btrim(p_motif), '') = ''
     OR length(btrim(p_motif)) > 1000 THEN
    RAISE EXCEPTION 'profil et motif requis' USING ERRCODE = '22023';
  END IF;
  -- Une désactivation ne doit jamais empêcher de retirer l'exception d'un admin.
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id AND p.role = 'admin' AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'le profil cible doit etre un administrateur existant' USING ERRCODE = '22023';
  END IF;
  DELETE FROM private.super_admin_kyc WHERE profile_id = p_profile_id;
  GET DIAGNOSTICS v_lignes = ROW_COUNT;
  PERFORM public.log_sensitive_access(
    'super_admin_kyc_retire', 'private.super_admin_kyc', p_profile_id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profile_id, 'motif', btrim(p_motif),
      'granted_by', 'postgres', 'affectation_supprimee', v_lignes > 0)
  );
END;
$procedure$;
ALTER PROCEDURE app_private.retirer_super_admin_kyc(uuid, text) OWNER TO postgres;
REVOKE ALL ON PROCEDURE app_private.retirer_super_admin_kyc(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON PROCEDURE app_private.retirer_super_admin_kyc(uuid, text) TO postgres;

CREATE OR REPLACE PROCEDURE app_private.basculer_exception_kyc(
  p_actif boolean, p_motif text
)
LANGUAGE plpgsql SET search_path = ''
AS $procedure$
DECLARE
  v_ancien jsonb;
BEGIN
  IF current_user IS DISTINCT FROM 'postgres' THEN
    RAISE EXCEPTION 'procedure reservee au role postgres' USING ERRCODE = '42501';
  END IF;
  IF p_actif IS NULL OR coalesce(btrim(p_motif), '') = ''
     OR length(btrim(p_motif)) > 1000 THEN
    RAISE EXCEPTION 'etat et motif requis' USING ERRCODE = '22023';
  END IF;
  SELECT c.value INTO v_ancien FROM public.app_config c
  WHERE c.key = 'kyc_exception_super_admin' FOR UPDATE;
  INSERT INTO public.app_config(key, value)
  VALUES ('kyc_exception_super_admin', pg_catalog.to_jsonb(p_actif))
  ON CONFLICT (key) DO UPDATE SET value = excluded.value;
  PERFORM public.log_sensitive_access(
    'super_admin_kyc_exception_basculee', 'app_config', 'kyc_exception_super_admin',
    pg_catalog.jsonb_build_object('ancien', v_ancien, 'nouveau', p_actif,
      'motif', btrim(p_motif), 'granted_by', 'postgres')
  );
END;
$procedure$;
ALTER PROCEDURE app_private.basculer_exception_kyc(boolean, text) OWNER TO postgres;
REVOKE ALL ON PROCEDURE app_private.basculer_exception_kyc(boolean, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON PROCEDURE app_private.basculer_exception_kyc(boolean, text) TO postgres;

CREATE OR REPLACE FUNCTION app_private.proteger_exception_kyc_config()
RETURNS trigger
LANGUAGE plpgsql SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.key = 'kyc_exception_super_admin'
       AND current_user IS DISTINCT FROM 'postgres' THEN
      RAISE EXCEPTION 'cle KYC reservee au role postgres' USING ERRCODE = '42501';
    END IF;
    RETURN OLD;
  END IF;
  IF NEW.key = 'kyc_exception_super_admin'
     AND current_user IS DISTINCT FROM 'postgres' THEN
    RAISE EXCEPTION 'cle KYC reservee au role postgres' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION app_private.proteger_exception_kyc_config() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.proteger_exception_kyc_config()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
DROP TRIGGER IF EXISTS app_config_proteger_exception_kyc ON public.app_config;
CREATE TRIGGER app_config_proteger_exception_kyc
BEFORE INSERT OR UPDATE OR DELETE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION app_private.proteger_exception_kyc_config();

DO $verification$
DECLARE
  v_signature text;
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_catalog.pg_class
          WHERE oid = 'private.super_admin_kyc'::regclass)
     OR has_schema_privilege('authenticated', 'private', 'USAGE')
     OR has_table_privilege('anon', 'private.super_admin_kyc', 'SELECT')
     OR has_table_privilege('authenticated', 'private.super_admin_kyc', 'SELECT')
     OR has_table_privilege('service_role', 'private.super_admin_kyc', 'SELECT')
     OR has_table_privilege('agent_ro', 'private.super_admin_kyc', 'SELECT')
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
       JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
       WHERE c.oid = 'public.app_config'::regclass
         AND t.tgname = 'app_config_proteger_exception_kyc' AND NOT t.tgisinternal
     ) THEN
    RAISE EXCEPTION 'F69: controls de table/configuration incomplets';
  END IF;
  FOREACH v_signature IN ARRAY ARRAY[
    'app_private.attribuer_super_admin_kyc(uuid, text)',
    'app_private.retirer_super_admin_kyc(uuid, text)',
    'app_private.basculer_exception_kyc(boolean, text)'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
      WHERE p.oid = pg_catalog.to_regprocedure(v_signature)
        AND p.prokind = 'p'
        AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
        AND p.proconfig @> ARRAY['search_path=""']
        AND NOT EXISTS (
          SELECT 1 FROM pg_catalog.aclexplode(
            coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))
          ) AS acl
          WHERE acl.grantee = 0 AND acl.privilege_type = 'EXECUTE'
        )
        AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
        AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
        AND pg_catalog.has_function_privilege('postgres', p.oid, 'EXECUTE')
    ) THEN
      RAISE EXCEPTION 'F69: procedure ou ACL invalide: %', v_signature;
    END IF;
  END LOOP;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'app_private.proteger_exception_kyc_config()'::regprocedure
      AND p.prosecdef
  ) THEN
    RAISE EXCEPTION 'F69: le trigger de configuration ne doit pas etre SECURITY DEFINER';
  END IF;
END;
$verification$;

COMMIT;
