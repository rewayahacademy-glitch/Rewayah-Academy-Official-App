BEGIN;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated, agent_ro;
GRANT USAGE ON SCHEMA private TO postgres;
CREATE TABLE IF NOT EXISTS private.super_admin_kyc (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  granted_at timestamptz NOT NULL DEFAULT now(),
  granted_by uuid REFERENCES public.profiles(id)
);
ALTER TABLE private.super_admin_kyc ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.super_admin_kyc
  FROM PUBLIC, anon, authenticated, agent_ro;

INSERT INTO public.app_config (key, value)
VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.kyc_super_admin_exception_active()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce(
    public.app_role() = 'admin'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.deleted_at IS NULL
    )
    AND EXISTS (
      SELECT 1 FROM private.super_admin_kyc s
      WHERE s.profile_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM public.app_config c
      WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb
    ), false
  );
$function$;
ALTER FUNCTION public.kyc_super_admin_exception_active() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.kyc_super_admin_exception_active()
  FROM PUBLIC, anon, authenticated, agent_ro;

CREATE OR REPLACE FUNCTION public.read_kyc_documents()
RETURNS SETOF public.kyc_documents
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_gender public.gender;
  v_exception boolean;
  v_piece public.kyc_documents%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false)
     OR NOT coalesce(public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'acces KYC refuse' USING errcode = '42501';
  END IF;

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  v_exception := public.kyc_super_admin_exception_active();
  IF v_gender IS NULL AND NOT v_exception THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier'
      USING errcode = '42501';
  END IF;

  IF v_exception THEN
    FOR v_piece IN
      SELECT k.* FROM public.kyc_documents k
      WHERE k.deleted_at IS NULL AND (v_gender IS NULL OR k.gender <> v_gender)
    LOOP
      PERFORM public.log_sensitive_access(
        'kyc_read', 'kyc_documents', v_piece.id::text,
        jsonb_build_object('profile_id', v_piece.profile_id,
                           'motif', 'exception_super_admin_kyc')
      );
    END LOOP;
  ELSE
    PERFORM public.log_sensitive_access('kyc_read', 'kyc_documents', null::text,
      jsonb_build_object('reader_gender', v_gender));
  END IF;

  RETURN QUERY
    SELECT k.* FROM public.kyc_documents k
    WHERE k.deleted_at IS NULL AND (v_exception OR k.gender = v_gender);
END;
$function$;
ALTER FUNCTION public.read_kyc_documents() OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.read_kyc_documents()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.read_kyc_documents() TO authenticated;

-- Les pièces se consultent par RPC puis URL signée courte, jamais par lecture
-- directe des lignes ou du bucket depuis un navigateur.
DROP POLICY IF EXISTS kyc_admin_all ON public.kyc_documents;
DROP POLICY IF EXISTS kyc_client_read_block ON public.kyc_documents;
CREATE POLICY kyc_client_read_block ON public.kyc_documents
  FOR SELECT TO authenticated USING (false);

DO $storage$
BEGIN
  IF to_regclass('storage.objects') IS NOT NULL THEN
    DROP POLICY IF EXISTS kyc_lecture_admin ON storage.objects;
    DROP POLICY IF EXISTS kyc_client_read_block ON storage.objects;
    CREATE POLICY kyc_client_read_block ON storage.objects
      FOR SELECT TO authenticated USING (bucket_id = 'kyc' AND false);
  END IF;
END
$storage$;

CREATE OR REPLACE FUNCTION public.autoriser_lecture_piece_identite(p_document_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_piece public.kyc_documents%ROWTYPE;
  v_gender public.gender;
  v_exception boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin', false)
     OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture des pieces d''identite reservee a l''administration'
      USING errcode = '42501';
  END IF;
  IF p_document_id IS NULL THEN
    RAISE EXCEPTION 'document non precise' USING errcode = '22023';
  END IF;

  SELECT k.* INTO v_piece FROM public.read_kyc_documents() k
  WHERE k.id = p_document_id;
  IF NOT FOUND OR v_piece.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'piece introuvable ou hors de votre perimetre'
      USING errcode = '42501';
  END IF;
  SELECT p.gender INTO v_gender FROM public.profiles p
  WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  v_exception := public.kyc_super_admin_exception_active()
    AND (v_gender IS NULL OR v_gender <> v_piece.gender);

  PERFORM public.log_sensitive_access(
    'kyc_document_open', 'kyc_documents', v_piece.id::text,
    jsonb_build_object(
      'profile_id', v_piece.profile_id,
      'storage_backend', v_piece.storage_backend,
      'status', v_piece.status,
      'motif', CASE WHEN v_exception THEN 'exception_super_admin_kyc'
                    ELSE 'meme_genre_admin' END
    )
  );
  RETURN jsonb_build_object(
    'document_id', v_piece.id,
    'profile_id', v_piece.profile_id,
    'object_key', v_piece.object_key,
    'storage_backend', v_piece.storage_backend,
    'doc_type', v_piece.doc_type
  );
END;
$function$;
ALTER FUNCTION public.autoriser_lecture_piece_identite(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.autoriser_lecture_piece_identite(uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.autoriser_lecture_piece_identite(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.autoriser_lecture_piece_identite(uuid) TO service_role;

DO $verification$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'private' AND c.relname = 'super_admin_kyc'
      AND c.relrowsecurity
  ) OR to_regprocedure('public.kyc_super_admin_exception_active()') IS NULL
    OR has_function_privilege('anon', 'public.read_kyc_documents()', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'EXECUTE')
    OR has_function_privilege('anon', 'public.autoriser_lecture_piece_identite(uuid)', 'EXECUTE')
    OR has_function_privilege('agent_ro', 'public.autoriser_lecture_piece_identite(uuid)', 'EXECUTE')
    OR NOT has_function_privilege('authenticated', 'public.autoriser_lecture_piece_identite(uuid)', 'EXECUTE')
    OR has_schema_privilege('authenticated', 'private', 'USAGE')
    OR has_table_privilege('authenticated', 'private.super_admin_kyc', 'SELECT')
    OR (to_regclass('storage.objects') IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_policies p
      WHERE p.schemaname = 'storage' AND p.tablename = 'objects'
        AND p.policyname = 'kyc_client_read_block'
        AND p.qual LIKE '%bucket_id%' AND p.qual LIKE '%false%'
    ))
  THEN RAISE EXCEPTION '0078 controles KYC incomplets'; END IF;
END
$verification$;

COMMIT;
