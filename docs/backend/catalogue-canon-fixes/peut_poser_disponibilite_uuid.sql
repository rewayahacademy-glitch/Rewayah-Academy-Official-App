CREATE OR REPLACE FUNCTION public.peut_poser_disponibilite(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    (p_profile_id = auth.uid() and public.app_role() = 'teacher')
    or (
      public.app_role() = 'guardian'
      and exists (
        select 1 from public.profiles p
        where p.id = p_profile_id and p.role = 'student'
          and p.household_id is not null
          and p.household_id = public.app_household_id()
          and p.deleted_at is null
      )
    )
    or (
      p_profile_id = auth.uid()
      and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid()
          and sp.student_type = 'autonomous'
          and sp.deleted_at is null
      )
    );
$function$

