CREATE OR REPLACE FUNCTION public.guard_assignment_cap()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_max int;
  v_actifs int;
begin
  if new.ended_at is not null then
    return new;
  end if;

  -- regle_brute et non regle_effective : le declencheur tourne aussi pour un
  -- appelant qui n'est pas partie concernee, et un plafond ne se contourne pas
  -- faute de droit de lecture.
  v_max := public.regle_brute(new.teacher_id, 'max_students_per_teacher');

  select count(*) into v_actifs
  from public.teacher_student_assignments a
  where a.teacher_id = new.teacher_id and a.ended_at is null and a.id <> new.id;

  if v_actifs >= v_max then
    raise exception 'plafond d''eleves atteint pour cet enseignant (%)', v_max;
  end if;

  return new;
end;
$function$

