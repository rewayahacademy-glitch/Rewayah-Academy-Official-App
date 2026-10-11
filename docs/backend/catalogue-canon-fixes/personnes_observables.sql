CREATE OR REPLACE FUNCTION public.personnes_observables()
 RETURNS TABLE(id uuid, immutable_id text, first_name text, last_name text, role app_role)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.role
  from public.profiles p
  where p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and public.app_role() = 'admin'
    and public.app_account_valid()
  order by
    p.role,
    case
      when public.agent_identite_masquee() then p.immutable_id
      else p.first_name
    end;
$function$

