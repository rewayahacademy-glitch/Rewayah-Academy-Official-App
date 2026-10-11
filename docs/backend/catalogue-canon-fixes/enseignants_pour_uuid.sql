CREATE OR REPLACE FUNCTION public.enseignants_pour(p_student_profile_id uuid)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, eleves_actifs integer, plafond integer, creneaux_communs jsonb)
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
    ens.id,
    case when v_masque then null else ens.first_name end,
    case when v_masque then null else ens.last_name end,
    ens.immutable_id,
    tp.country,
    charge.actifs::int,
    public.regle_brute(ens.id, 'max_students_per_teacher'),
    coalesce(communs.cases, '[]'::jsonb)
  from public.profiles ens
  join public.teacher_profiles tp
    on tp.profile_id = ens.id and tp.deleted_at is null
  join lateral (
    select count(*) as actifs
    from public.teacher_student_assignments a
    where a.teacher_id = ens.id and a.ended_at is null
  ) charge on true
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'weekday', we.weekday,
        'hour_local', we.hour_local,
        'timezone_iana', we.timezone_iana
      )
      order by we.weekday, we.hour_local
    ) as cases
    from public.weekly_availability we
    join public.weekly_availability wt on wt.profile_id = ens.id
     and public.instant_creneau(wt.weekday, wt.hour_local, wt.timezone_iana)
       = public.instant_creneau(we.weekday, we.hour_local, we.timezone_iana)
    where we.profile_id = p_student_profile_id
  ) communs on true
  where ens.role = 'teacher'
    and ens.deleted_at is null
    and ens.account_status in ('active', 'provisional_active')
  order by
    (coalesce(jsonb_array_length(communs.cases), 0) > 0) desc,
    charge.actifs asc,
    case when v_masque then ens.immutable_id else ens.first_name end asc;
end;
$function$

