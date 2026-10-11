CREATE OR REPLACE FUNCTION public.teacher_signature_statuses(p_profile_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_teacher_version text;
  v_teacher_signed text;
  v_notice_version text;
  v_notice_signed text;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin'::public.app_role
      AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'admin_required';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id AND p.role = 'teacher'::public.app_role
      AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'teacher_profile_not_found';
  END IF;

  SELECT t.version INTO v_teacher_version
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current;
  SELECT c.version INTO v_teacher_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id AND c.contract_kind = 'teacher_nda'
  ORDER BY c.accepted_at DESC LIMIT 1;

  SELECT r.version INTO v_notice_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'recording_and_control_notice';
  SELECT c.version INTO v_notice_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id
    AND c.contract_kind = 'recording_and_control_notice'
  ORDER BY c.accepted_at DESC LIMIT 1;

  RETURN jsonb_build_object(
    'contrat', jsonb_build_object(
      'status', CASE
        WHEN v_teacher_signed IS NULL THEN 'non_signe'
        WHEN v_teacher_version IS NOT NULL AND v_teacher_signed = v_teacher_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_teacher_signed,
      'version_courante', v_teacher_version
    ),
    'accuse', jsonb_build_object(
      'status', CASE
        WHEN v_notice_signed IS NULL THEN 'non_signe'
        WHEN v_notice_version IS NOT NULL AND v_notice_signed = v_notice_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_notice_signed,
      'version_courante', v_notice_version
    )
  );
END;
$function$

