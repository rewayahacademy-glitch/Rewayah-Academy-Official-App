CREATE OR REPLACE FUNCTION public.ma_capacite_eleve()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT coalesce(public.app_account_valid(), false) AND EXISTS (
    SELECT 1 FROM public.student_profiles sp
    WHERE sp.profile_id = auth.uid()
      AND sp.student_type = 'autonomous'
      AND sp.deleted_at IS NULL
  );
$function$

