-- RECH-BACK-1: invalidate role/household claims as soon as their source
-- authorization changes. The JWT remains the source of role and household;
-- the database stores only a generation counter to reject stale claims.

ALTER TABLE public.profiles
  ADD COLUMN authorization_version bigint NOT NULL DEFAULT 1
  CHECK (authorization_version > 0);

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.bump_profile_authorization_version()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role
     OR NEW.household_id IS DISTINCT FROM OLD.household_id
     OR NEW.account_status IS DISTINCT FROM OLD.account_status
     OR NEW.access_until IS DISTINCT FROM OLD.access_until
     OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
    NEW.authorization_version := OLD.authorization_version + 1;
  ELSE
    -- Clients with row UPDATE rights cannot lower or forge the generation.
    NEW.authorization_version := OLD.authorization_version;
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.bump_profile_authorization_version()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE TRIGGER profiles_bump_authorization_version
BEFORE UPDATE OF role, household_id, account_status, access_until, deleted_at,
  authorization_version ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION private.bump_profile_authorization_version();

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  claims jsonb;
  user_id uuid := (event ->> 'user_id')::uuid;
  v_profile public.profiles;
  v_student_type public.student_type;
  v_tranche_age text := 'inconnu';
BEGIN
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE public.profiles.id = user_id
    AND public.profiles.deleted_at IS NULL;

  claims := coalesce(event -> 'claims', '{}'::jsonb);

  IF v_profile.id IS NOT NULL THEN
    IF coalesce(jsonb_typeof(claims -> 'app_metadata'), 'absent') <> 'object' THEN
      claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb);
    END IF;

    claims := jsonb_set(
      claims,
      '{app_metadata, role}',
      coalesce(to_jsonb(v_profile.role::text), 'null'::jsonb)
    );
    claims := jsonb_set(
      claims,
      '{app_metadata, household_id}',
      coalesce(to_jsonb(v_profile.household_id::text), 'null'::jsonb)
    );

    claims := jsonb_set(
      claims,
      '{app_metadata, authorization_version}',
      to_jsonb(v_profile.authorization_version),
      true
    );

    SELECT sp.student_type INTO v_student_type
    FROM public.student_profiles sp
    WHERE sp.profile_id = user_id
      AND sp.deleted_at IS NULL;

    v_tranche_age := CASE v_student_type
      WHEN 'minor' THEN 'enfant'
      WHEN 'autonomous' THEN 'adulte'
      ELSE 'inconnu'
    END;
  END IF;

  -- Claim de présentation uniquement : aucune décision d'accès ne s'appuie
  -- sur lui. Il ne contient jamais de date de naissance.
  claims := jsonb_set(claims, '{tranche_age}', to_jsonb(v_tranche_age), true);

  RETURN coalesce(jsonb_set(event, '{claims}', claims), event);
END;
$function$;

ALTER FUNCTION public.custom_access_token_hook(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.custom_access_token_hook(jsonb)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb)
  TO supabase_auth_admin;

COMMENT ON FUNCTION public.custom_access_token_hook(jsonb) IS
  'F79 candidate allowlist: signature=public.custom_access_token_hook(jsonb); md5_prosrc=fc825b4f53ad01f251d6c8e311bb97a6; guard_type=NO_GUARD_HELPER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12; justification=Auth hook preserves tranche_age as presentation-only and adds the current authorization_version claim.';

DO $f79_rech_back1$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.custom_access_token_hook(jsonb)'::regprocedure
      AND p.prosecdef
      AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
      AND p.proconfig @> ARRAY['search_path=""']
      AND pg_catalog.md5(p.prosrc) = 'fc825b4f53ad01f251d6c8e311bb97a6'
      AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE
        '%F79 candidate allowlist:%signature=public.custom_access_token_hook(jsonb); md5_prosrc=fc825b4f53ad01f251d6c8e311bb97a6;%'
      AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
      AND NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
      AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
      AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
  ) OR NOT pg_catalog.has_function_privilege(
         'supabase_auth_admin',
         'public.custom_access_token_hook(jsonb)',
         'EXECUTE'
       ) THEN
    RAISE EXCEPTION 'RECH-BACK-1 F79 hook owner/path/hash/ACL postflight failed';
  END IF;
END;
$f79_rech_back1$;

-- Search endpoints call this before using the JWT role/household claims.
-- It exposes only the caller's validity; role and household remain JWT claims,
-- while each domain RPC checks its current assignments/capabilities in SQL.
CREATE OR REPLACE FUNCTION public.rech_session_autorisee()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT COALESCE(EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.statement_timestamp())
      AND COALESCE(
        NULLIF(auth.jwt() -> 'app_metadata' ->> 'authorization_version', '')::bigint,
        0
      ) = p.authorization_version
  ), false);
$function$;

REVOKE ALL ON FUNCTION public.rech_session_autorisee()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.rech_session_autorisee() TO authenticated;

COMMENT ON COLUMN public.profiles.authorization_version IS
  'Monotone generation for server-issued role/household JWT claims; incremented when profile authorization state changes.';
