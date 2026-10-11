CREATE OR REPLACE FUNCTION public.maj_eleve_pedagogie(p_profile_id uuid, p_level text DEFAULT NULL::text, p_riwaya text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'seul un administrateur modifie le niveau ou la riwaya';
  end if;

  update public.student_profiles
  set level = coalesce(p_level, level),
      riwaya = coalesce(p_riwaya, riwaya)
  where profile_id = p_profile_id and deleted_at is null;

  perform public.log_sensitive_access('maj_pedagogie', 'student_profiles',
    p_profile_id::text,
    jsonb_build_object('level', p_level, 'riwaya', p_riwaya));
end;
$function$

