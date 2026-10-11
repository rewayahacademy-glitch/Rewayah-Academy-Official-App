CREATE OR REPLACE FUNCTION public.verdict_acces_dossier_kyc(p_profile_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_reader_gender public.gender;
  v_document_gender public.gender;
  v_exception boolean;
BEGIN
  IF NOT coalesce(
       public.app_role() = 'admin' AND public.app_account_valid(), false
     ) THEN
    RAISE EXCEPTION 'verdict KYC reserve a l''administration'
      USING errcode = '42501';
  END IF;

  IF p_profile_id IS NULL THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  SELECT p.gender INTO v_reader_gender
  FROM public.profiles p
  WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  SELECT k.gender INTO v_document_gender
  FROM public.kyc_documents k
  WHERE k.profile_id = p_profile_id AND k.deleted_at IS NULL
  ORDER BY k.created_at DESC, k.id
  LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'profilNonAutorise');
  END IF;

  IF v_reader_gender IS NOT NULL AND v_reader_gender = v_document_gender THEN
    RETURN jsonb_build_object('type', 'memeGenre');
  END IF;

  v_exception := public.ma_exception_kyc_active();
  IF v_exception THEN
    RETURN jsonb_build_object('type', 'exceptionSuperAdmin');
  END IF;
  IF v_reader_gender IS NULL THEN
    RETURN jsonb_build_object('type', 'refus', 'raison', 'adminSansGenre');
  END IF;
  RETURN jsonb_build_object('type', 'refus', 'raison', 'genreDifferent');
END;
$function$

