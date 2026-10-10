-- 0074 — SEC-01 hardening: revalidate account expiry and remove PUBLIC EXECUTE.
-- PostgREST's per-request hook validates the token and current observed profile
-- before adapting auth.uid() to that profile for existing scoped policies.
BEGIN;

CREATE OR REPLACE FUNCTION public.agent_pre_request()
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = ''
AS $agent_pre_request$
DECLARE
  v_id uuid;
  v_profil_observe uuid;
BEGIN
  v_id := public.agent_jeton_id();
  IF v_id IS NULL THEN
    RETURN;
  END IF;

  IF auth.jwt() ->> 'sub' IS DISTINCT FROM v_id::text THEN
    RAISE EXCEPTION 'jeton agent refuse'
      USING ERRCODE = '42501';
  END IF;

  SELECT p.id
    INTO v_profil_observe
    FROM public.jetons_agent t
    JOIN public.profiles p ON p.id = t.profil_observe
   WHERE t.id = v_id
     AND t.revoque_le IS NULL
     AND t.expire_le > pg_catalog.now()
     AND p.deleted_at IS NULL
     AND p.account_status IN ('active', 'provisional_active')
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
     AND p.role = t.parcours;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'jeton agent refuse'
      USING ERRCODE = '42501';
  END IF;

  -- Transaction-local compatibility for existing auth.uid()-bounded policies.
  -- auth.jwt() still exposes the signed token's opaque subject and claims.
  PERFORM pg_catalog.set_config(
    'request.jwt.claim.sub',
    v_profil_observe::text,
    true
  );
END;
$agent_pre_request$;

-- SEC-01 exception to the general agent_ro volatile-function denylist:
-- PostgREST must execute this no-argument, SECURITY DEFINER hook as agent_ro.
-- Its only non-read effect is transaction-local GUC state; it performs no
-- business-table writes. scenarios_agt01.sql asserts it is the sole exception.
-- The request hook runs after PostgREST impersonates the JWT role. Keep the
-- explicit anon grant so anonymous requests can reach their RLS policies, but
-- remove PostgreSQL's default PUBLIC grant.
REVOKE EXECUTE ON FUNCTION public.agent_pre_request() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.agent_pre_request()
  TO anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION public.agent_pre_request() IS
  'Valide à chaque requête le jeton agent et le profil observé courant; '
  'auth.uid() reçoit le profil après validation tandis que auth.jwt()->>sub '
  'conserve l’identifiant opaque du jeton.';

COMMIT;
