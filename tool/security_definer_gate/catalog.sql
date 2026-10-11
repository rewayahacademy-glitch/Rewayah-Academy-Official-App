-- Read-only catalog export for verify_allowlist.py.
-- Run on the exact disposable database after applying the candidate migrations.
SELECT pg_catalog.jsonb_build_object(
  'metadata', pg_catalog.jsonb_build_object(
    'database', pg_catalog.current_database(),
    'project_ref', :'project_ref'::text
  ),
  'functions', COALESCE((
    SELECT pg_catalog.jsonb_agg(row_data ORDER BY row_data->>'signature')
    FROM (
      SELECT pg_catalog.jsonb_build_object(
        'signature', pg_catalog.format(
          '%I.%I(%s)', n.nspname, p.proname,
          pg_catalog.pg_get_function_identity_arguments(p.oid)
        ),
        'schema', n.nspname,
        'security_definer', p.prosecdef,
        'md5_prosrc', pg_catalog.md5(p.prosrc),
        'prosrc', p.prosrc,
        'owner', r.rolname,
        'search_path', COALESCE((
          SELECT pg_catalog.array_agg(setting ORDER BY setting)
          FROM pg_catalog.unnest(COALESCE(p.proconfig, ARRAY[]::text[])) AS setting
          WHERE setting LIKE 'search_path=%'
        ), ARRAY[]::text[]),
        'execute', pg_catalog.jsonb_build_object(
          'anon', CASE WHEN pg_catalog.to_regrole('anon') IS NULL THEN false
            ELSE pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE') END,
          'authenticated', CASE WHEN pg_catalog.to_regrole('authenticated') IS NULL THEN false
            ELSE pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE') END,
          'agent_ro', CASE WHEN pg_catalog.to_regrole('agent_ro') IS NULL THEN false
            ELSE pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE') END
        )
      ) AS row_data
      FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      JOIN pg_catalog.pg_roles r ON r.oid = p.proowner
      WHERE n.nspname IN ('public', 'app_private')
        AND p.prokind IN ('f', 'p')
        AND p.prosecdef
    ) AS functions
  ), '[]'::jsonb),
  'trigger_functions', COALESCE((
    SELECT pg_catalog.jsonb_agg(row_data ORDER BY row_data->>'signature')
    FROM (
      SELECT pg_catalog.jsonb_build_object(
        'signature', pg_catalog.format(
          '%I.%I(%s)', n.nspname, p.proname,
          pg_catalog.pg_get_function_identity_arguments(p.oid)
        ),
        'security_definer', p.prosecdef
      ) AS row_data
      FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname IN ('public', 'app_private')
        AND p.prokind = 'f'
        AND p.prorettype = 'trigger'::pg_catalog.regtype
    ) AS triggers
  ), '[]'::jsonb),
  'event_triggers', COALESCE((
    SELECT pg_catalog.jsonb_agg(row_data ORDER BY row_data->>'name')
    FROM (
      SELECT pg_catalog.jsonb_build_object(
        'name', e.evtname,
        'event', e.evtevent,
        'enabled', e.evtenabled,
        'tags', e.evttags,
        'signature', pg_catalog.format(
          '%I.%I(%s)', n.nspname, p.proname,
          pg_catalog.pg_get_function_identity_arguments(p.oid)
        )
      ) AS row_data
      FROM pg_catalog.pg_event_trigger e
      JOIN pg_catalog.pg_proc p ON p.oid = e.evtfoid
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname IN ('public', 'app_private')
    ) AS event_triggers
  ), '[]'::jsonb)
)::text;
