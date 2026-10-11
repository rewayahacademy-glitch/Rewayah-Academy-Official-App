CREATE OR REPLACE FUNCTION public.effacer_etat_partage(p_session_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(
    public.app_account_valid()
    and (
      (public.app_role() = 'teacher'
       and public.session_belongs_to_teacher(p_session_id, auth.uid()))
      or public.app_role() = 'admin'
    ),
    false
  ) then
    raise exception 'effacement etat partage refuse' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.sessions s
     where s.id = p_session_id
       and s.status = 'ended'
       and (
         s.teacher_id = auth.uid()
         or public.app_role() = 'admin'
       )
  ) then
    raise exception 'etat partage effacable apres cloture de la seance';
  end if;

  delete from public.session_shared_content
   where session_id = p_session_id;
end;
$function$

