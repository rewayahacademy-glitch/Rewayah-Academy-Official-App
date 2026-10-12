BEGIN;

-- instant_creneau_reference is already restricted to authenticated callers.
-- Keep the public wrapper on the same allowlist; server-owned SECURITY
-- DEFINER callers do not need a direct service_role grant.
REVOKE ALL ON FUNCTION public.instant_creneau(integer, integer, text, integer)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.instant_creneau(integer, integer, text, integer)
  TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege(
       'authenticated',
       'public.instant_creneau(integer,integer,text,integer)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'anon',
       'public.instant_creneau(integer,integer,text,integer)', 'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'service_role',
       'public.instant_creneau(integer,integer,text,integer)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'instant_creneau privilege postflight failed';
  END IF;
END
$postflight$;

COMMIT;
