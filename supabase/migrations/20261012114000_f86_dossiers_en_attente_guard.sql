BEGIN;

CREATE OR REPLACE FUNCTION public.dossiers_en_attente()
RETURNS TABLE(
  profile_id uuid,
  immutable_id text,
  first_name text,
  last_name text,
  role public.app_role,
  account_status public.account_status,
  inscrit_le timestamptz,
  document_id uuid,
  doc_type text,
  document_gender public.gender,
  object_key text,
  depose_le timestamptz,
  etat_piece text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_en_attente integer;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'validation des dossiers reservee a l''administration';
  END IF;

  SELECT count(*) INTO v_en_attente
  FROM public.kyc_documents k
  WHERE k.status = 'pending' AND k.deleted_at IS NULL;

  IF v_en_attente = 0 THEN
    RETURN QUERY
      SELECT
        p.id, p.immutable_id, p.first_name, p.last_name, p.role,
        p.account_status, p.created_at,
        NULL::uuid, NULL::text, NULL::public.gender, NULL::text,
        NULL::timestamptz,
        'aucune'::text
      FROM public.profiles p
      WHERE p.deleted_at IS NULL
        AND p.account_status = 'pending_kyc'
      ORDER BY p.created_at ASC;
    RETURN;
  END IF;

  RETURN QUERY
    WITH visibles AS (
      SELECT k.*
      FROM public.read_kyc_documents() k
      WHERE k.status = 'pending'
    )
    SELECT
      p.id, p.immutable_id, p.first_name, p.last_name, p.role,
      p.account_status, p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      CASE
        WHEN v.id IS NOT NULL THEN 'a_verifier'
        WHEN EXISTS (
          SELECT 1 FROM public.kyc_documents k2
          WHERE k2.profile_id = p.id
            AND k2.status = 'pending'
            AND k2.deleted_at IS NULL
        ) THEN 'non_visible'
        ELSE 'aucune'
      END::text
    FROM public.profiles p
    LEFT JOIN visibles v ON v.profile_id = p.id
    WHERE p.deleted_at IS NULL
      AND (p.account_status = 'pending_kyc' OR v.id IS NOT NULL)
    ORDER BY coalesce(v.created_at, p.created_at) ASC;
END;
$function$;

ALTER FUNCTION public.dossiers_en_attente() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.dossiers_en_attente()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.dossiers_en_attente() TO authenticated;
COMMENT ON FUNCTION public.dossiers_en_attente() IS
  'F86 candidate allowlist: signature=public.dossiers_en_attente(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_catalog.pg_roles r ON r.oid = p.proowner
  WHERE n.nspname = 'public'
    AND p.proname = 'dossiers_en_attente'
    AND pg_catalog.pg_get_function_identity_arguments(p.oid) = ''
    AND p.prosecdef
    AND r.rolname = 'postgres'
    AND 'search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[]))
    AND pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'NOT COALESCE') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ACCOUNT_VALID') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc), 'APP_ROLE') > 0;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'F86 dossiers_en_attente postflight failed: % of 1', v_count;
  END IF;
END;
$postflight$;

COMMIT;
