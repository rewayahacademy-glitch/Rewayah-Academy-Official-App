CREATE OR REPLACE FUNCTION public.peut_deposer_piece_identite(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(
    public.app_account_valid()
    and p_profile_id is not null
    and (
      public.app_role() = 'admin'
      or (
        public.app_role() = 'guardian'
        and exists (
          select 1 from public.profiles p
          where p.id = p_profile_id
            and p.deleted_at is null
            and p.household_id is not null
            and p.household_id = public.app_household_id()
        )
      )
      or (
        public.app_role() in ('teacher', 'controller')
        and p_profile_id = auth.uid()
      )
    ),
    false
  );
$function$

