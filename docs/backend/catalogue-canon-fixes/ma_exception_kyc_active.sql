CREATE OR REPLACE FUNCTION public.ma_exception_kyc_active()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'acces KYC refuse' USING errcode = '42501';
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM private.super_admin_kyc s
    WHERE s.profile_id = auth.uid()
  ) AND EXISTS (
    SELECT 1 FROM public.app_config c
    WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb
  );
END;
$function$

