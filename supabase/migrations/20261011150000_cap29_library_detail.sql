BEGIN;

-- CAP-29 C-30: admin detail projection. This returns metadata only; storage
-- object keys and signed URLs are never exposed through PostgREST.
CREATE FUNCTION public.library_get_detail(p_resource_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_resource public.library_resource%ROWTYPE;
  v_versions jsonb;
  v_rights jsonb;
  v_history jsonb;
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin', false
  ) THEN
    RAISE EXCEPTION 'BibliothequeNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_resource_id IS NULL THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT r.* INTO v_resource
    FROM public.library_resource r
   WHERE r.id = p_resource_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'BibliothequeIntrouvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', v.id,
    'numeroVersion', v.numero_version,
    'statut', v.statut::text,
    'publieeLeUtc', v.publiee_le,
    'empreinte', v.empreinte,
    'droits', CASE WHEN d.resource_version_id IS NULL THEN NULL ELSE
      pg_catalog.jsonb_build_object(
        'sourceTitre', d.source_titre,
        'titulaire', d.titulaire,
        'preuveFournie', d.preuve_id IS NOT NULL,
        'preuveStatut', p.statut,
        'preuveMime', p.mime,
        'preuveTaille', p.taille,
        'preuveSha256', p.sha256,
        'usages', d.usages,
        'attribution', d.attribution,
        'expireLeUtc', d.expire_le,
        'approuve', d.approuve,
        'revuLeUtc', d.revu_le
      ) END
  ) ORDER BY v.numero_version DESC), '[]'::jsonb),
  coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'versionId', d.resource_version_id,
    'sourceTitre', d.source_titre,
    'titulaire', d.titulaire,
    'preuveFournie', d.preuve_id IS NOT NULL,
    'preuveStatut', p.statut,
    'preuveMime', p.mime,
    'preuveTaille', p.taille,
    'preuveSha256', p.sha256,
    'usages', d.usages,
    'attribution', d.attribution,
    'expireLeUtc', d.expire_le,
    'approuve', d.approuve,
    'revuLeUtc', d.revu_le
  ) ORDER BY v.numero_version DESC) FILTER (WHERE d.resource_version_id IS NOT NULL), '[]'::jsonb)
  INTO v_versions, v_rights
  FROM public.resource_version v
  LEFT JOIN public.library_version_rights d ON d.resource_version_id = v.id
  LEFT JOIN private.library_rights_proofs p
    ON p.id = d.preuve_id AND p.resource_version_id = v.id
  WHERE v.resource_id = p_resource_id;

  SELECT coalesce(pg_catalog.jsonb_agg(x.entree ORDER BY x.created_at DESC), '[]'::jsonb)
    INTO v_history
    FROM (
      SELECT pg_catalog.jsonb_build_object(
        'action', a.action,
        'creeLeUtc', a.created_at
      ) AS entree, a.created_at
        FROM public.audit_logs a
       WHERE a.table_name = 'library_resource'
         AND a.row_id = p_resource_id::text
         AND a.action IN (
           'library_resource_draft_created', 'library_resource_draft_updated',
           'library_rights_review', 'library_version_published',
           'library_resource_withdrawn', 'library_groups_assigned'
         )
       ORDER BY a.created_at DESC, a.id DESC
       LIMIT 100
    ) x;

  PERFORM public.log_sensitive_access(
    'library_resource_detail_read', 'library_resource', p_resource_id::text,
    pg_catalog.jsonb_build_object('resource_id', p_resource_id)
  );

  RETURN pg_catalog.jsonb_build_object(
    'support', pg_catalog.jsonb_build_object(
      'id', v_resource.id,
      'titre', v_resource.title,
      'titreCourt', v_resource.short_title,
      'type', v_resource.resource_type::text,
      'edition', v_resource.edition,
      'langue', v_resource.language,
      'categorie', v_resource.category,
      'niveaux', v_resource.level_scope,
      'politiqueAcces', v_resource.access_policy::text,
      'politiqueHorsLigne', v_resource.offline_policy::text,
      'capacitesContenu', v_resource.capabilities,
      'retire', v_resource.archived_at IS NOT NULL,
      'retireLeUtc', v_resource.archived_at,
      'versionCouranteId', v_resource.current_version_id,
      'modifieLeUtc', v_resource.updated_at
    ),
    'revision', v_resource.revision,
    'versions', v_versions,
    'droits', v_rights,
    'historique', v_history,
    'capacites', pg_catalog.jsonb_build_object(
      'peutModifier', false,
      'peutPublier', false,
      'peutAttribuer', false,
      'peutRetirer', false
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.library_get_detail(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.library_get_detail(uuid) TO authenticated;
ALTER FUNCTION public.library_get_detail(uuid) OWNER TO postgres;
COMMENT ON FUNCTION public.library_get_detail(uuid) IS
  'F86 candidate allowlist: signature=public.library_get_detail(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: active admin reads allowlisted resource, version and rights metadata; non-admin is refused; storage object keys and signed URLs are absent.';

DO $postflight$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.library_get_detail(uuid)'::regprocedure
       AND p.prosecdef
       AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=""']
       AND p.prosrc ILIKE '%app_account_valid()%'
       AND p.prosrc ILIKE '%app_role() = ''admin''%'
       AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE
         '%F86 candidate allowlist:%signature=public.library_get_detail(uuid); md5_functiondef=A_CALCULER;%'
       AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
       AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CAP-29: garde, propriétaire, search_path ou ACL de library_get_detail invalide';
  END IF;
END;
$postflight$;

COMMIT;
