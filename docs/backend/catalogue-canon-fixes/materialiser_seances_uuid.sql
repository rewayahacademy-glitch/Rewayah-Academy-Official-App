CREATE OR REPLACE FUNCTION public.materialiser_seances(p_assignment_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_a public.teacher_student_assignments;
  v_semaines int;
  v_duree int;
  v_type text;
  v_debut timestamptz;
  v_session uuid;
  v_creees int := 0;
  i int;
begin
  select * into v_a from public.teacher_student_assignments
  where id = p_assignment_id and ended_at is null;
  if v_a.id is null then
    raise exception 'affectation introuvable ou close';
  end if;

  v_semaines := coalesce(
    (public.get_config('matching_horizon_weeks', '4'::jsonb) #>> '{}')::int, 4);
  v_duree := public.regle_brute(v_a.student_id, 'session_duration_minutes');

  select case when sp.interface_mode = 'child' then 'child' else 'standard' end
    into v_type
  from public.student_profiles sp where sp.profile_id = v_a.student_id;

  for i in 0 .. (v_semaines - 1) loop
    v_debut := public.instant_creneau(v_a.weekday, v_a.hour_local, v_a.timezone_iana, i);
    if v_debut <= now() then
      continue;
    end if;

    -- Une seance deja posee sur ce creneau ne se double pas : la tache de
    -- prolongation repasse sur les memes semaines a chaque execution.
    if exists (
      select 1 from public.sessions s
      where s.teacher_id = v_a.teacher_id and s.started_at = v_debut
        and s.deleted_at is null
    ) then
      continue;
    end if;

    insert into public.sessions (teacher_id, started_at, ended_at, session_type)
    values (v_a.teacher_id, v_debut,
            v_debut + make_interval(mins => v_duree),
            coalesce(v_type, 'standard'))
    returning id into v_session;

    insert into public.session_participants (session_id, profile_id, role)
    values (v_session, v_a.teacher_id, 'teacher'),
           (v_session, v_a.student_id, 'student');

    v_creees := v_creees + 1;
  end loop;

  return v_creees;
end;
$function$

