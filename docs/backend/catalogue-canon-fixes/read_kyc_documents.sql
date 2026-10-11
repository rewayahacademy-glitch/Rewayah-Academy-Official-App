CREATE OR REPLACE FUNCTION public.read_kyc_documents()
 RETURNS SETOF kyc_documents
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_gender public.gender;
  v_exception boolean;
  v_count integer;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
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

  SELECT count(*)::integer INTO v_count
  FROM public.kyc_documents k
  WHERE k.deleted_at IS NULL AND (v_exception OR k.gender = v_gender);

  PERFORM public.log_sensitive_access(
    'kyc_read', 'kyc_documents', NULL,
    jsonb_build_object(
      'reader_gender', v_gender,
      'exception_active', v_exception,
      'document_count', v_count
    )
  );

  RETURN QUERY
    SELECT k.* FROM public.kyc_documents k
    WHERE k.deleted_at IS NULL AND (v_exception OR k.gender = v_gender);
END;
$function$

