CREATE OR REPLACE FUNCTION public.groupe_roster_enseignant(p_groupe_id uuid)
 RETURNS TABLE(student_id uuid, first_name text, immutable_id text, level text, riwaya text, interface_mode interface_mode, curriculum_path text, current_unit text, active_goals text[], resume_page integer, resume_sourate integer, resume_verset integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    p.id,
    case when public.agent_identite_masquee() then p.immutable_id else p.first_name end,
    p.immutable_id,
    sp.level,
    sp.riwaya,
    sp.interface_mode,
    prog.cycle,
    prog.nom_humain,
    coalesce(goals.objectifs, '{}'),
    pos.page_mushaf,
    pos.sourate,
    pos.verset
  from public.groupe_membres m
    join public.groupes g on g.id = m.groupe_id
    join public.profiles p on p.id = m.student_id
    join public.student_profiles sp on sp.profile_id = p.id
    left join lateral (
      select pn.cycle, pn.nom_humain
        from public.progression_historique ph
        join public.programme_niveaux pn on pn.id = ph.niveau_id
       where ph.student_id = p.id
       order by ph.created_at desc
       limit 1
    ) prog on true
    left join lateral (
      select srp.page_mushaf, srp.sourate, srp.verset
        from public.student_reading_position srp
       where srp.student_profile_id = p.id
       order by srp.updated_at desc
       limit 1
    ) pos on true
    left join lateral (
      select array(
        select la.purpose
          from public.learning_assignment la
         where (la.student_id = p.id or (la.student_id is null and la.group_id = g.id))
           and la.status in ('a_faire', 'en_cours')
         order by la.due_at nulls last, la.starts_at
         limit 3
      ) as objectifs
    ) goals on true
  where m.groupe_id = p_groupe_id
    and m.left_at is null
    and p.deleted_at is null
    and g.teacher_id = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid();
$function$

