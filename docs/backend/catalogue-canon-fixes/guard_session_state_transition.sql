CREATE OR REPLACE FUNCTION public.guard_session_state_transition()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.status = new.status then
    return new;
  end if;
  if not (
    (old.status = 'planned' and new.status in ('preflight', 'teacher_absent', 'student_absent', 'canceled_late', 'canceled')) or
    (old.status = 'preflight' and new.status in ('in_progress', 'teacher_absent', 'student_absent')) or
    (old.status = 'in_progress' and new.status in ('ended', 'tech_failure'))
  ) then
    raise exception 'transition de session non autorisée: % -> %', old.status::text, new.status::text;
  end if;
  return new;
end;
$function$

