CREATE OR REPLACE FUNCTION public.autoriser_lecture_piece_identite(p_document_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
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
$function$

