CREATE OR REPLACE FUNCTION public.guard_session_participant_cap()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  allow_multi boolean;
  max_participants int;
  current_count int;
begin
  if new.role in ('masked_controller', 'guardian_observer', 'admin_masked', 'admin_visible') then
    return new;
  end if;

  select (value)::boolean into allow_multi
  from public.app_config where key = 'allow_multi_participant_sessions';
  if allow_multi is null then allow_multi := false; end if;

  select coalesce(value #>> '{}', '2')::int into max_participants
  from public.app_config where key = 'max_participants_per_session';
  if max_participants is null then max_participants := 2; end if;

  if not allow_multi then
    select count(*) into current_count
    from public.session_participants
    where session_id = new.session_id and deleted_at is null
      and role in ('teacher', 'student');
    if current_count >= max_participants then
      raise exception 'plafond de participants atteint';
    end if;
  end if;
  return new;
end;
$function$

