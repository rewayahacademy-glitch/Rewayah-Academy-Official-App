CREATE OR REPLACE FUNCTION public.guard_rule_override_coherente()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_role public.app_role;
begin
  select p.role into v_role from public.profiles p where p.id = new.profile_id;

  if new.key = 'max_students_per_teacher' and v_role is distinct from 'teacher' then
    raise exception 'un plafond d''eleves ne se pose que sur un enseignant';
  end if;
  if new.key <> 'max_students_per_teacher' and v_role is distinct from 'student' then
    raise exception 'cette regle ne se pose que sur un eleve';
  end if;
  if (new.value #>> '{}') !~ '^[0-9]+$' or (new.value #>> '{}')::int <= 0 then
    raise exception 'une regle est un entier positif';
  end if;
  return new;
end;
$function$

