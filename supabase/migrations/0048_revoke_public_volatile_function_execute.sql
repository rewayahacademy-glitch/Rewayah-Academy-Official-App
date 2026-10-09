-- 0048: remove inherited PUBLIC execution from volatile public functions
-- without removing access authenticated already had through PUBLIC.
-- AGT-01 A12 found volatile public-schema functions still callable by agent_ro
-- through PUBLIC. Keep existing authenticated capabilities and narrow these
-- routines away from anonymous and scoped agent sessions.
BEGIN;

DO $migration$
DECLARE
  v_function record;
BEGIN
  FOR v_function IN
    SELECT p.oid::regprocedure AS signature,
           p.oid AS function_oid,
           pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
             AS authenticated_had_execute
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

    -- Removing PUBLIC also removes inherited access for authenticated. Restore
    -- only functions that this role could execute before the migration; an
    -- explicit grant to authenticated survives future PUBLIC revocations.
    IF v_function.authenticated_had_execute THEN
      EXECUTE format(
        'GRANT EXECUTE ON FUNCTION %s TO authenticated',
        v_function.signature
      );
      IF NOT pg_catalog.has_function_privilege(
        'authenticated', v_function.function_oid, 'EXECUTE'
      ) THEN
        RAISE EXCEPTION
          '0048 incomplete: authenticated lost prior EXECUTE on %',
          v_function.signature;
      END IF;
    END IF;
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
