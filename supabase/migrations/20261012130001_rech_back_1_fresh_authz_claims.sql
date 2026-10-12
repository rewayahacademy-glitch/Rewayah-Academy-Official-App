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
BEGIN
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE public.profiles.id = user_id
    AND public.profiles.deleted_at IS NULL;

  claims := COALESCE(event -> 'claims', '{}'::jsonb);

  IF v_profile.id IS NOT NULL THEN
    IF jsonb_typeof(claims -> 'app_metadata') IS DISTINCT FROM 'object' THEN
      claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb, true);
    END IF;
    claims := jsonb_set(claims, '{app_metadata,role}', to_jsonb(v_profile.role::text), true);
    claims := jsonb_set(
      claims,
      '{app_metadata,household_id}',
      COALESCE(to_jsonb(v_profile.household_id::text), 'null'::jsonb),
      true
    );
    claims := jsonb_set(
      claims,
      '{app_metadata,authorization_version}',
      to_jsonb(v_profile.authorization_version),
      true
    );
  END IF;

  RETURN jsonb_set(event, '{claims}', claims, true);
END;
$function$;

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
