CREATE OR REPLACE FUNCTION public.guard_profile_privileged_columns()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin')
     and not coalesce(
       public.app_role() = 'admin' and public.app_account_valid(),
       false
     )
     and (
       old.role is distinct from new.role
       or old.household_id is distinct from new.household_id
       or old.account_status is distinct from new.account_status
       or old.access_until is distinct from new.access_until
     )
  then
    raise exception 'seul un admin modifie rôle, foyer, statut ou accès'
      using errcode = 'insufficient_privilege';
  end if;
  return new;
end;
$function$

