CREATE OR REPLACE FUNCTION public.kyc_super_admin_exception_active()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
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
$function$

