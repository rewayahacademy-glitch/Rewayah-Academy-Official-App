CREATE OR REPLACE FUNCTION public.guard_teacher_activation_signatures()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE
  v_teacher_version text;
  v_teacher_hash text;
  v_notice_version text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.role = 'teacher'::public.app_role
     AND OLD.account_status = 'active'::public.account_status THEN
    RETURN NEW;
  END IF;
  IF NEW.role <> 'teacher'::public.app_role
     OR NEW.account_status <> 'active'::public.account_status THEN
    RETURN NEW;
  END IF;

  SELECT t.version, t.sha256 INTO v_teacher_version, v_teacher_hash
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda'
    AND t.locale = 'fr'
    AND t.is_current;
  IF v_teacher_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'teacher_nda'
      AND c.version = v_teacher_version
      AND c.signed_sha256 = v_teacher_hash
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:teacher_nda';
  END IF;

  SELECT r.version INTO v_notice_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'recording_and_control_notice';
  IF v_notice_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'recording_and_control_notice'
      AND c.version = v_notice_version
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:recording_and_control_notice';
  END IF;

  RETURN NEW;
END;
$function$

