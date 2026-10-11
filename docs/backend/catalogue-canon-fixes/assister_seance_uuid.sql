CREATE OR REPLACE FUNCTION public.assister_seance(p_session_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance public.sessions%rowtype;
  v_role   public.participant_role;
begin
  if NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) or not public.app_account_valid() then
    raise exception 'assister est reserve au tuteur du foyer'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if not public.session_in_household(p_session_id, public.app_household_id()) then
    raise exception 'cette seance n''est pas celle d''un enfant du foyer'
      using errcode = 'insufficient_privilege';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;
  if now() < v_seance.started_at then
    raise exception 'seance pas encore commencee' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'seance terminee' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id and sp.profile_id = auth.uid()
     and sp.deleted_at is null;
  if found and v_role <> 'guardian_observer' then
    raise exception 'ce profil participe deja a cette seance a un autre titre'
      using errcode = 'check_violation';
  end if;

  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), 'guardian_observer')
  on conflict (session_id, profile_id) do update
    set deleted_at = null, role = 'guardian_observer';

  return p_session_id;
end;
$function$

