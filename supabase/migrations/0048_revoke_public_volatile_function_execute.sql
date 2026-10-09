-- 0048: remove inherited PUBLIC execution from application write-capable RPCs.
-- AGT-01 A12 found volatile public-schema functions still callable by agent_ro
-- through PUBLIC. Preserve explicit grants to authenticated/service_role while
-- narrowing these routines away from anonymous and scoped agent sessions.
BEGIN;

DO $migration$
DECLARE
  v_function record;
BEGIN
  FOR v_function IN
    SELECT p.oid::regprocedure AS signature
      FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.prokind = 'f'
       AND p.provolatile = 'v'
       AND NOT EXISTS (
         SELECT 1
           FROM pg_catalog.pg_depend d
          WHERE d.objid = p.oid
            AND d.deptype = 'e'
       )
  LOOP
    EXECUTE format(
      'REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, agent_ro',
      v_function.signature
    );
  END LOOP;
END
$migration$;

DO $verification$
DECLARE
  v_count integer;
  v_names text;
BEGIN
  SELECT count(*), string_agg(p.proname, ', ' ORDER BY p.proname)
    INTO v_count, v_names
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
     AND p.prokind = 'f'
     AND p.provolatile = 'v'
     AND pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
     AND NOT EXISTS (
       SELECT 1
         FROM pg_catalog.pg_depend d
        WHERE d.objid = p.oid
          AND d.deptype = 'e'
     );

  IF v_count > 0 THEN
    RAISE EXCEPTION '0048 incomplete: agent_ro can execute % volatile functions: %',
      v_count, v_names;
  END IF;
END
$verification$;

COMMIT;
