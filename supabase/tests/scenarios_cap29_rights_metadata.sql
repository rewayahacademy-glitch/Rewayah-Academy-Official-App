BEGIN;

DO $rights_private$
DECLARE
  v_resource_id uuid := 'c2930000-0000-0000-0000-000000000001';
  v_revision integer;
  v_updated timestamptz;
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_catalog.pg_class
          WHERE oid = 'private.library_rights_proofs'::regclass)
     OR NOT (SELECT relrowsecurity FROM pg_catalog.pg_class
             WHERE oid = 'public.library_version_rights'::regclass) THEN
    RAISE EXCEPTION 'CAP29: RLS missing on rights metadata';
  END IF;
  IF has_table_privilege('anon', 'private.library_rights_proofs', 'SELECT')
     OR has_table_privilege('authenticated', 'private.library_rights_proofs', 'SELECT')
     OR has_table_privilege('service_role', 'private.library_rights_proofs', 'SELECT')
     OR has_table_privilege('anon', 'public.library_version_rights', 'SELECT')
     OR has_table_privilege('authenticated', 'public.library_version_rights', 'SELECT')
     OR has_table_privilege('service_role', 'public.library_version_rights', 'SELECT') THEN
    RAISE EXCEPTION 'CAP29: direct rights metadata access remains';
  END IF;

  INSERT INTO public.library_resource (
    id, title, short_title, resource_type, access_policy, offline_policy
  ) VALUES (
    v_resource_id, 'CAP29 fixture', 'CAP29', 'lesson', 'admin', 'jamais'
  );
  UPDATE public.library_resource SET title = 'CAP29 fixture updated'
  WHERE id = v_resource_id;
  SELECT revision, updated_at INTO v_revision, v_updated
  FROM public.library_resource WHERE id = v_resource_id;
  IF v_revision <> 2 OR v_updated IS NULL THEN
    RAISE EXCEPTION 'CAP29: revision/updated_at did not advance';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
    JOIN pg_catalog.pg_proc p ON p.oid = t.tgfoid
    WHERE t.tgname IN (
      'cap29_resource_version_guard',
      'cap29_download_asset_guard',
      'cap29_current_resource_version_guard',
      'cap29_resource_published_pointer_check',
      'cap29_version_published_pointer_check'
    ) AND p.prosecdef
  ) THEN
    RAISE EXCEPTION 'CAP29: a library trigger uses SECURITY DEFINER';
  END IF;
END
$rights_private$;

ROLLBACK;
