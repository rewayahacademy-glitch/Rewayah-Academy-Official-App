CREATE OR REPLACE FUNCTION public.mon_groupe_detail(p_groupe_id uuid)
 RETURNS TABLE(student_id uuid, identifiant_immuable text, prenom text, niveau text, riwaya text, joined_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    sp.level,
    sp.riwaya,
    m.joined_at
  from public.groupe_membres m
    join public.groupes g on g.id = m.groupe_id
    join public.profiles p on p.id = m.student_id
    left join public.student_profiles sp on sp.profile_id = p.id
  where m.groupe_id = p_groupe_id
    and m.left_at is null
    and p.deleted_at is null
    and g.ended_at is null
    and g.teacher_id = auth.uid()
    and public.app_account_valid()
  order by m.joined_at asc;
$function$

