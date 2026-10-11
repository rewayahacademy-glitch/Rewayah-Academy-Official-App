CREATE OR REPLACE FUNCTION public.diagnostics_a_traiter()
 RETURNS TABLE(student_id uuid, student_immutable_id text, student_prenom text, student_nom text, inscrit_depuis timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.created_at
  from public.profiles p
  where public.app_role() = 'admin' and public.app_account_valid()
    and p.role = 'student'
    and p.deleted_at is null
    and p.account_status in ('active', 'provisional_active')
    and not exists (
      select 1 from public.progression_historique h where h.student_id = p.id
    )
  order by p.created_at asc;
$function$

