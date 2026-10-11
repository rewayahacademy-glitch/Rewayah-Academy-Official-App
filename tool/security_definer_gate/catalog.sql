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
        ),
        'execute_acl', COALESCE((
          SELECT pg_catalog.jsonb_agg(
            pg_catalog.jsonb_build_object(
              'grantee', CASE WHEN acl.grantee = 0 THEN 'PUBLIC' ELSE grantee.rolname END,
              'grantor', grantor.rolname,
              'privilege', acl.privilege_type,
              'is_grantable', acl.is_grantable
            ) ORDER BY acl.grantee, acl.grantor, acl.privilege_type, acl.is_grantable
          )
          FROM pg_catalog.aclexplode(COALESCE(
            p.proacl, pg_catalog.acldefault('f', p.proowner)
          )) AS acl
          LEFT JOIN pg_catalog.pg_roles AS grantee ON grantee.oid = acl.grantee
          JOIN pg_catalog.pg_roles AS grantor ON grantor.oid = acl.grantor
          WHERE acl.privilege_type = 'EXECUTE'
        ), '[]'::jsonb),
        'effective_execute_roles', COALESCE((
          SELECT pg_catalog.jsonb_agg(r.rolname ORDER BY r.rolname)
          FROM pg_catalog.pg_roles AS r
          WHERE pg_catalog.has_function_privilege(r.oid, p.oid, 'EXECUTE')
        ), '[]'::jsonb)
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
  ), '[]'::jsonb)
)::text;
