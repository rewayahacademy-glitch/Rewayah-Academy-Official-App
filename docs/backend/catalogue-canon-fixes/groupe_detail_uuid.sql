CREATE OR REPLACE FUNCTION public.groupe_detail(p_groupe_id uuid)
 RETURNS TABLE(student_id uuid, student_immutable_id text, student_prenom text, student_nom text, joined_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    m.joined_at
  from public.groupe_membres m
  join public.profiles p on p.id = m.student_id
  where public.app_role() = 'admin' and public.app_account_valid()
    and m.groupe_id = p_groupe_id
    and m.left_at is null
  order by m.joined_at asc;
$function$

