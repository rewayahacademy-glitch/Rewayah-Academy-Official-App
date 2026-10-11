CREATE OR REPLACE FUNCTION public.eleves_sans_enseignant()
 RETURNS TABLE(student_id uuid, first_name text, immutable_id text, household_id uuid, level text, interface_mode interface_mode, depuis timestamp with time zone, creneaux jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_masque boolean := public.agent_identite_masquee();
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'attribution manuelle reservee a l''administration';
  end if;

  return query
  select
    e.id,
    case when v_masque then null else e.first_name end,
    e.immutable_id,
    e.household_id,
    sp.level,
    sp.interface_mode,
    creneau.depuis,
    coalesce(creneau.cases, '[]'::jsonb)
  from public.profiles e
  join public.student_profiles sp
    on sp.profile_id = e.id and sp.deleted_at is null
  left join lateral (
    select
      min(w.created_at) as depuis,
      jsonb_agg(
        jsonb_build_object(
          'weekday', w.weekday,
          'hour_local', w.hour_local,
          'timezone_iana', w.timezone_iana,
          'created_at', w.created_at
        )
        order by w.weekday, w.hour_local
      ) as cases
    from public.weekly_availability w
    where w.profile_id = e.id
  ) creneau on true
  where e.role = 'student'
    and e.deleted_at is null
    and e.account_status in ('active', 'provisional_active')
    and not exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = e.id and a.ended_at is null
    )
  order by
    creneau.depuis asc nulls last,
    case when v_masque then e.immutable_id else e.first_name end asc;
end;
$function$

