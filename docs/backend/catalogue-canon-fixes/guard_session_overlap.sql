CREATE OR REPLACE FUNCTION public.guard_session_overlap()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if new.role in ('masked_controller', 'guardian_observer', 'admin_masked', 'admin_visible') then
    return new;
  end if;

  if exists (
    select 1
    from public.session_participants sp
    join public.sessions s1 on s1.id = sp.session_id
    join public.sessions s2 on s2.id = new.session_id
    where sp.profile_id = new.profile_id
      and sp.deleted_at is null
      and sp.role in ('teacher', 'student')
      and s1.deleted_at is null and s2.deleted_at is null
      and s1.status in ('planned', 'preflight', 'in_progress')
      and tstzrange(s1.started_at, s1.ended_at, '[)')
          && tstzrange(s2.started_at, s2.ended_at, '[)')
      and s1.id <> s2.id
  ) then
    raise exception 'chevauchement de sessions pour le meme profil';
  end if;
  return new;
end;
$function$

