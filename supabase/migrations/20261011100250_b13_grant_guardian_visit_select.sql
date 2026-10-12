-- The observation-history policies already restrict rows to the observer or
-- an active admin. Grant only SELECT so those intended policies are reachable
-- while all client writes continue to use the bounded observation RPCs.
BEGIN;

REVOKE ALL ON TABLE public.guardian_session_visit
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON TABLE public.guardian_session_visit TO authenticated;

DO $verification$
BEGIN
  IF NOT pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'SELECT'
     )
     OR pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'INSERT'
     )
     OR pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'UPDATE'
     )
     OR pg_catalog.has_table_privilege(
       'authenticated', 'public.guardian_session_visit', 'DELETE'
     )
     OR pg_catalog.has_table_privilege(
       'anon', 'public.guardian_session_visit', 'SELECT'
     )
     OR pg_catalog.has_table_privilege(
       'service_role', 'public.guardian_session_visit', 'SELECT'
     )
     OR pg_catalog.has_table_privilege(
       'agent_ro', 'public.guardian_session_visit', 'SELECT'
     )
     OR NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_class c
       JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'public'
         AND c.relname = 'guardian_session_visit'
         AND c.relrowsecurity
     )
     OR NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_policy p
       WHERE p.polrelid = 'public.guardian_session_visit'::regclass
         AND p.polname = 'guardian_visit_admin'
     ) THEN
    RAISE EXCEPTION 'B-13: observation history SELECT privilege or RLS postflight failed';
  END IF;
END
$verification$;

COMMIT;
