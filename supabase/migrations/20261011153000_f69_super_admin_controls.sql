BEGIN;

CREATE SCHEMA IF NOT EXISTS private;
CREATE SCHEMA IF NOT EXISTS app_private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON SCHEMA app_private FROM PUBLIC, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA private, app_private TO postgres;

CREATE TABLE IF NOT EXISTS private.super_admin_kyc (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  granted_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  granted_by text NOT NULL DEFAULT 'postgres',
  motif text NOT NULL
);

DO $compat$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_attribute a
    WHERE a.attrelid = 'private.super_admin_kyc'::regclass
      AND a.attname = 'granted_by'
      AND NOT a.attisdropped
      AND a.atttypid <> 'text'::regtype
  ) THEN
    ALTER TABLE private.super_admin_kyc
      RENAME COLUMN granted_by TO granted_by_profile_id;
  END IF;

  ALTER TABLE private.super_admin_kyc
    ADD COLUMN IF NOT EXISTS granted_by text NOT NULL DEFAULT 'postgres',
    ADD COLUMN IF NOT EXISTS motif text;

  UPDATE private.super_admin_kyc
     SET motif = 'Historique antérieur à la journalisation du motif.'
   WHERE motif IS NULL;

  ALTER TABLE private.super_admin_kyc
    ALTER COLUMN motif SET NOT NULL;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'private.super_admin_kyc'::regclass
      AND c.conname = 'super_admin_kyc_postgres_reason_only'
  ) THEN
    ALTER TABLE private.super_admin_kyc
      ADD CONSTRAINT super_admin_kyc_postgres_reason_only
      CHECK (granted_by = 'postgres' AND pg_catalog.btrim(motif) <> '');
  END IF;
END
$compat$;

ALTER TABLE private.super_admin_kyc ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.super_admin_kyc
  FROM PUBLIC, anon, authenticated, service_role;
DO $agent_acl$
BEGIN
  IF pg_catalog.to_regrole('agent_ro') IS NOT NULL THEN
    REVOKE ALL ON TABLE private.super_admin_kyc FROM agent_ro;
    REVOKE ALL ON SCHEMA private FROM agent_ro;
    REVOKE ALL ON SCHEMA app_private FROM agent_ro;
  END IF;
END
$agent_acl$;

INSERT INTO public.app_config(key, value)
VALUES ('kyc_exception_super_admin', 'false'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION app_private.guard_kyc_exception_config()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF current_user <> 'postgres' THEN
    IF (TG_OP = 'INSERT' AND NEW.key = 'kyc_exception_super_admin')
       OR (TG_OP = 'UPDATE' AND (
             OLD.key = 'kyc_exception_super_admin'
             OR NEW.key = 'kyc_exception_super_admin'
          ))
       OR (TG_OP = 'DELETE' AND OLD.key = 'kyc_exception_super_admin') THEN
      RAISE EXCEPTION 'seul postgres peut modifier kyc_exception_super_admin'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END
$function$;
ALTER FUNCTION app_private.guard_kyc_exception_config() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.guard_kyc_exception_config()
  FROM PUBLIC, anon, authenticated, service_role;
DO $agent_trigger_acl$
BEGIN
  IF pg_catalog.to_regrole('agent_ro') IS NOT NULL THEN
    REVOKE ALL ON FUNCTION app_private.guard_kyc_exception_config() FROM agent_ro;
  END IF;
END
$agent_trigger_acl$;
DROP TRIGGER IF EXISTS guard_kyc_exception_config ON public.app_config;
CREATE TRIGGER guard_kyc_exception_config
BEFORE INSERT OR UPDATE OR DELETE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION app_private.guard_kyc_exception_config();

CREATE OR REPLACE PROCEDURE app_private.attribuer_super_admin_kyc(
  p_profile_id uuid,
  p_motif text
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $procedure$
BEGIN
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION 'operation reservee a postgres' USING ERRCODE = '42501';
  END IF;
  IF p_profile_id IS NULL OR pg_catalog.btrim(coalesce(p_motif, '')) = ''
     OR pg_catalog.char_length(pg_catalog.btrim(coalesce(p_motif, ''))) > 1000 THEN
    RAISE EXCEPTION 'profil et motif requis' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id
      AND p.role = 'admin'::public.app_role
      AND p.account_status = 'active'::public.account_status
      AND p.deleted_at IS NULL
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
  ) THEN
    RAISE EXCEPTION 'le profil cible doit etre un admin actif' USING ERRCODE = '42501';
  END IF;

  INSERT INTO private.super_admin_kyc(profile_id, granted_at, granted_by, motif)
  VALUES (p_profile_id, pg_catalog.now(), 'postgres', pg_catalog.btrim(p_motif));

  PERFORM public.log_sensitive_access(
    'super_admin_kyc_attribue', 'private.super_admin_kyc', p_profile_id::text,
    pg_catalog.jsonb_build_object('granted_by', 'postgres', 'motif', pg_catalog.btrim(p_motif))
  );
END
$procedure$;
ALTER PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text) OWNER TO postgres;
REVOKE ALL ON PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text) TO postgres;

CREATE OR REPLACE PROCEDURE app_private.retirer_super_admin_kyc(
  p_profile_id uuid,
  p_motif text
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $procedure$
BEGIN
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION 'operation reservee a postgres' USING ERRCODE = '42501';
  END IF;
  IF p_profile_id IS NULL OR pg_catalog.btrim(coalesce(p_motif, '')) = ''
     OR pg_catalog.char_length(pg_catalog.btrim(coalesce(p_motif, ''))) > 1000 THEN
    RAISE EXCEPTION 'profil et motif requis' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id
      AND p.role = 'admin'::public.app_role
      AND p.account_status = 'active'::public.account_status
      AND p.deleted_at IS NULL
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
  ) THEN
    RAISE EXCEPTION 'le profil cible doit etre un admin actif' USING ERRCODE = '42501';
  END IF;

  DELETE FROM private.super_admin_kyc s WHERE s.profile_id = p_profile_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'profil non present dans la liste super-admin KYC' USING ERRCODE = 'P0002';
  END IF;

  PERFORM public.log_sensitive_access(
    'super_admin_kyc_retire', 'private.super_admin_kyc', p_profile_id::text,
    pg_catalog.jsonb_build_object('granted_by', 'postgres', 'motif', pg_catalog.btrim(p_motif))
  );
END
$procedure$;
ALTER PROCEDURE app_private.retirer_super_admin_kyc(uuid, text) OWNER TO postgres;
REVOKE ALL ON PROCEDURE app_private.retirer_super_admin_kyc(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON PROCEDURE app_private.retirer_super_admin_kyc(uuid, text) TO postgres;

CREATE OR REPLACE PROCEDURE app_private.basculer_exception_kyc(
  p_actif boolean,
  p_motif text
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $procedure$
BEGIN
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION 'operation reservee a postgres' USING ERRCODE = '42501';
  END IF;
  IF p_actif IS NULL OR pg_catalog.btrim(coalesce(p_motif, '')) = ''
     OR pg_catalog.char_length(pg_catalog.btrim(coalesce(p_motif, ''))) > 1000 THEN
    RAISE EXCEPTION 'etat et motif requis' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.app_config(key, value, updated_by, updated_at)
  VALUES ('kyc_exception_super_admin', pg_catalog.to_jsonb(p_actif), NULL, pg_catalog.now())
  ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value, updated_by = NULL, updated_at = pg_catalog.now();

  PERFORM public.log_sensitive_access(
    'kyc_exception_super_admin_bascule', 'app_config', 'kyc_exception_super_admin',
    pg_catalog.jsonb_build_object('actif', p_actif, 'motif', pg_catalog.btrim(p_motif))
  );
END
$procedure$;
ALTER PROCEDURE app_private.basculer_exception_kyc(boolean, text) OWNER TO postgres;
REVOKE ALL ON PROCEDURE app_private.basculer_exception_kyc(boolean, text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON PROCEDURE app_private.basculer_exception_kyc(boolean, text) TO postgres;

DO $agent_procedure_acl$
BEGIN
  IF pg_catalog.to_regrole('agent_ro') IS NOT NULL THEN
    REVOKE ALL ON PROCEDURE app_private.attribuer_super_admin_kyc(uuid, text) FROM agent_ro;
    REVOKE ALL ON PROCEDURE app_private.retirer_super_admin_kyc(uuid, text) FROM agent_ro;
    REVOKE ALL ON PROCEDURE app_private.basculer_exception_kyc(boolean, text) FROM agent_ro;
  END IF;
END
$agent_procedure_acl$;

-- This KYC read RPC remains available to authenticated administrators. Remove
-- the historical service_role grant; identity access still uses the caller JWT.
DO $kyc_read_acl$
BEGIN
  IF pg_catalog.to_regprocedure('public.autoriser_lecture_piece_identite(uuid)') IS NOT NULL THEN
    REVOKE ALL ON FUNCTION public.autoriser_lecture_piece_identite(uuid)
      FROM PUBLIC, anon, service_role;
    GRANT EXECUTE ON FUNCTION public.autoriser_lecture_piece_identite(uuid) TO authenticated;
    IF pg_catalog.to_regrole('agent_ro') IS NOT NULL THEN
      REVOKE ALL ON FUNCTION public.autoriser_lecture_piece_identite(uuid) FROM agent_ro;
    END IF;
  END IF;
END
$kyc_read_acl$;

DO $verification$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'private' AND c.relname = 'super_admin_kyc' AND c.relrowsecurity
    )
    OR pg_catalog.has_schema_privilege('authenticated', 'private', 'USAGE')
    OR pg_catalog.has_table_privilege('authenticated', 'private.super_admin_kyc', 'SELECT')
    OR pg_catalog.has_table_privilege('anon', 'private.super_admin_kyc', 'SELECT')
    OR pg_catalog.has_table_privilege('service_role', 'private.super_admin_kyc', 'SELECT')
    OR pg_catalog.has_function_privilege('anon', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('authenticated', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('service_role', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('anon', 'app_private.retirer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('authenticated', 'app_private.retirer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('service_role', 'app_private.retirer_super_admin_kyc(uuid,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('anon', 'app_private.basculer_exception_kyc(boolean,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('authenticated', 'app_private.basculer_exception_kyc(boolean,text)', 'EXECUTE')
    OR pg_catalog.has_function_privilege('service_role', 'app_private.basculer_exception_kyc(boolean,text)', 'EXECUTE')
    OR (pg_catalog.to_regprocedure('public.autoriser_lecture_piece_identite(uuid)') IS NOT NULL
        AND pg_catalog.has_function_privilege('service_role', 'public.autoriser_lecture_piece_identite(uuid)', 'EXECUTE'))
    OR EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'app_private'
        AND p.proname IN ('attribuer_super_admin_kyc', 'retirer_super_admin_kyc', 'basculer_exception_kyc')
        AND (p.prosecdef OR p.proowner <> 'postgres'::regrole)
    )
    OR EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'app_private'
        AND p.proname IN ('attribuer_super_admin_kyc', 'retirer_super_admin_kyc', 'basculer_exception_kyc')
        AND p.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[]
    )
    OR EXISTS (
      SELECT 1 FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'app_private' AND p.proname = 'guard_kyc_exception_config'
        AND (p.prosecdef OR p.proconfig IS DISTINCT FROM ARRAY['search_path=""']::text[])
    ) THEN
    RAISE EXCEPTION 'F69: controles de privilèges, ownership, RLS ou INVOKER incomplets';
  END IF;
  IF pg_catalog.to_regrole('agent_ro') IS NOT NULL AND (
       pg_catalog.has_function_privilege('agent_ro', 'app_private.attribuer_super_admin_kyc(uuid,text)', 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', 'app_private.retirer_super_admin_kyc(uuid,text)', 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', 'app_private.basculer_exception_kyc(boolean,text)', 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', 'app_private.guard_kyc_exception_config()', 'EXECUTE')
       OR pg_catalog.has_schema_privilege('agent_ro', 'private', 'USAGE')
       OR pg_catalog.has_schema_privilege('agent_ro', 'app_private', 'USAGE')
       OR pg_catalog.has_table_privilege('agent_ro', 'private.super_admin_kyc', 'SELECT')
     ) THEN
    RAISE EXCEPTION 'F69: agent_ro conserve un privilège interdit';
  END IF;
END
$verification$;

COMMIT;
