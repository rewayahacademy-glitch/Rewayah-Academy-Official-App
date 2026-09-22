-- Core24 P0.3. Les livraisons LiveKit sont signees par l'Edge existante.
-- Aucun heartbeat ni geste client ne peut accrediter du temps academique.
begin;

alter table public.livekit_webhook_deliveries
  add column session_id uuid references public.sessions(id),
  add column profile_id uuid references public.profiles(id),
  add column event_ts timestamptz;
create index livekit_deliveries_presence_ix
  on public.livekit_webhook_deliveries(session_id, profile_id, event_ts)
  where applique and event_type in ('participant_joined','participant_left');
create index livekit_deliveries_session_recu_ix
  on public.livekit_webhook_deliveries(session_id, recu_le)
  where session_id is not null;

create table public.attendance_records (
  session_id uuid not null references public.sessions(id),
  profile_id uuid not null references public.profiles(id),
  outcome text not null check (outcome in ('present','late','absent','review','excused')),
  validated_seconds int not null default 0 check (validated_seconds >= 0),
  first_joined_at timestamptz,
  last_left_at timestamptz,
  reconnection_count int not null default 0 check (reconnection_count >= 0),
  anomaly text,
  finalized_at timestamptz not null default now(),
  corrected_by uuid references public.profiles(id),
  corrected_at timestamptz,
  correction_reason text,
  primary key(session_id, profile_id)
);
alter table public.attendance_records enable row level security;
create policy attendance_read on public.attendance_records
  for select to authenticated using (
    public.app_account_valid() and (
      public.app_role() = 'admin'
      or profile_id = auth.uid()
      or (public.app_role() = 'guardian' and public.est_du_foyer(profile_id))
      or (public.app_role() = 'teacher' and exists (
        select 1 from public.sessions s where s.id = session_id and s.teacher_id = auth.uid()))
    )
  );
revoke all on public.attendance_records from public, anon, authenticated, agent_ro;
grant select on public.attendance_records to authenticated;

-- Projection derivee des livraisons : utile a l'Admin pour verifier une duree.
-- Les evenements signes demeurent dans livekit_webhook_deliveries.
create table public.attendance_intervals (
  session_id uuid not null references public.sessions(id),
  profile_id uuid not null references public.profiles(id),
  interval_no int not null check(interval_no > 0),
  joined_at timestamptz not null,
  left_at timestamptz not null,
  credited_seconds int not null check(credited_seconds >= 0),
  closed_by_room boolean not null default false,
  primary key(session_id,profile_id,interval_no),
  check(left_at >= joined_at)
);
alter table public.attendance_intervals enable row level security;
create policy attendance_intervals_read on public.attendance_intervals
  for select to authenticated using (
    public.app_account_valid() and (
      public.app_role()='admin' or profile_id=auth.uid()
      or (public.app_role()='guardian' and public.est_du_foyer(profile_id))
      or (public.app_role()='teacher' and exists(
        select 1 from public.sessions s where s.id=session_id and s.teacher_id=auth.uid()))
    )
  );
revoke all on public.attendance_intervals from public,anon,authenticated,agent_ro;
grant select on public.attendance_intervals to authenticated;

insert into public.app_config(key,value)
values ('presence.absence_grace_seconds',
        to_jsonb(public.app_config_int('presence.seuil_retard_secondes',300)))
on conflict (key) do nothing;
insert into public.app_config(key,value)
values ('presence.core24_started_at',to_jsonb(now()::text))
on conflict (key) do nothing;

-- Garder la signature existante : l'Edge et les tests historiques l'emploient.
create or replace function public.enregistrer_webhook_livekit(
  p_event_id text, p_event_type text, p_room_name text,
  p_profile_id uuid, p_server_ts timestamptz,
  p_detail jsonb default '{}'::jsonb
) returns boolean language plpgsql volatile security definer set search_path = '' as $$
declare v_session_id uuid; v_type public.session_event_type;
begin
  if p_event_id is null or length(p_event_id) not between 1 and 500 then
    raise exception 'event_id invalide' using errcode='22023';
  end if;
  insert into public.livekit_webhook_deliveries(event_id,event_type,room_name,detail)
    values(p_event_id,p_event_type,p_room_name,coalesce(p_detail,'{}'::jsonb))
    on conflict(event_id) do nothing;
  if not found then return false; end if;

  select r.session_id into v_session_id from public.session_video_route r
    where r.room_name=p_room_name;
  update public.livekit_webhook_deliveries d
    set session_id=v_session_id, profile_id=p_profile_id,
        event_ts=coalesce(p_server_ts,d.recu_le)
    where d.event_id=p_event_id;
  if v_session_id is null then return false; end if;

  if p_event_type in ('room_started','room_finished') then
    update public.livekit_webhook_deliveries set applique=true where event_id=p_event_id;
    return true;
  end if;
  v_type := case p_event_type
    when 'participant_joined' then 'joined'::public.session_event_type
    when 'participant_left' then 'left'::public.session_event_type
    else null end;
  if v_type is null or p_profile_id is null or not exists (
    select 1 from public.session_participants sp
    where sp.session_id=v_session_id and sp.profile_id=p_profile_id and sp.deleted_at is null
  ) then return false; end if;

  -- Le webhook de sortie reste la preuve academique meme si l'UI a deja
  -- inscrit un geste volontaire : ne pas remplacer 'sortie' par 'deconnectee'.
  if not (v_type='left' and exists (
    select 1 from public.session_events e
    where e.session_id=v_session_id and e.profile_id=p_profile_id
      and e.event_type='left' and e.source='user_action'
      and e.server_ts > coalesce(p_server_ts,now())-interval '30 seconds'
  )) then
    insert into public.session_events(session_id,profile_id,event_type,server_ts,source)
      values(v_session_id,p_profile_id,v_type,coalesce(p_server_ts,now()),'livekit_webhook');
  end if;
  update public.livekit_webhook_deliveries set applique=true where event_id=p_event_id;
  return true;
end;
$$;
revoke all on function public.enregistrer_webhook_livekit(text,text,text,uuid,timestamptz,jsonb)
  from public, anon, authenticated, agent_ro;
grant execute on function public.enregistrer_webhook_livekit(text,text,text,uuid,timestamptz,jsonb)
  to service_role;

create function core24_private.finaliser_presence_participant(
  p_session_id uuid, p_profile_id uuid
) returns void language plpgsql volatile security definer set search_path = '' as $$
declare v_session public.sessions; v_event record;
  v_open timestamptz; v_last_left timestamptz; v_first_join timestamptz;
  v_first_academic timestamptz;
  v_room_start timestamptz; v_room_end timestamptz; v_end timestamptz;
  v_seconds int:=0; v_reconnects int:=0; v_interval_no int:=0; v_credit int;
  v_anomaly text;
  v_outcome text; v_reconnect_window int;
begin
  select * into v_session from public.sessions s where s.id=p_session_id and s.deleted_at is null;
  if not found then return; end if;
  if exists (select 1 from public.attendance_records a where a.session_id=p_session_id
             and a.profile_id=p_profile_id and a.corrected_by is not null) then return; end if;
  select min(d.event_ts) filter (where d.event_type='room_started'),
         max(d.event_ts) filter (where d.event_type='room_finished')
    into v_room_start,v_room_end
    from public.livekit_webhook_deliveries d
    where d.session_id=p_session_id and d.applique;
  v_end:=least(v_session.ended_at,coalesce(v_room_end,v_session.ended_at));
  v_reconnect_window:=greatest(0,public.app_config_int('presence.fenetre_reconnexion_secondes',120));
  delete from public.attendance_intervals i where i.session_id=p_session_id
    and i.profile_id=p_profile_id;
  for v_event in
    select d.event_type,d.event_ts from public.livekit_webhook_deliveries d
    where d.session_id=p_session_id and d.profile_id=p_profile_id and d.applique
      and d.event_type in ('participant_joined','participant_left')
    order by d.event_ts,d.event_id
  loop
    if v_event.event_ts is null or v_event.event_ts > now()+interval '1 minute' then
      v_anomaly:='horodatage_invalide';
    elsif v_event.event_type='participant_joined' then
      v_first_join:=coalesce(v_first_join,v_event.event_ts);
      if v_open is null then
        if v_last_left is not null and v_event.event_ts-v_last_left <=
             make_interval(secs=>v_reconnect_window) then
          v_reconnects:=v_reconnects+1;
        end if;
        v_open:=v_event.event_ts;
      end if;
    elsif v_open is not null then
      v_credit:=greatest(0,extract(epoch from
        least(v_event.event_ts,v_end)-greatest(v_open,v_session.started_at))::int);
      if v_credit>0 then
        v_first_academic:=coalesce(v_first_academic,greatest(v_open,v_session.started_at));
      end if;
      v_seconds:=v_seconds+v_credit;
      v_interval_no:=v_interval_no+1;
      insert into public.attendance_intervals
        (session_id,profile_id,interval_no,joined_at,left_at,credited_seconds)
      values(p_session_id,p_profile_id,v_interval_no,v_open,v_event.event_ts,v_credit);
      v_open:=null;
      v_last_left:=v_event.event_ts;
    else
      v_anomaly:='sortie_sans_entree';
    end if;
  end loop;
  if v_open is not null then
    if v_room_end is not null then
      v_credit:=greatest(0,extract(epoch from
        v_end-greatest(v_open,v_session.started_at))::int);
      if v_credit>0 then
        v_first_academic:=coalesce(v_first_academic,greatest(v_open,v_session.started_at));
      end if;
      v_seconds:=v_seconds+v_credit;
      v_interval_no:=v_interval_no+1;
      insert into public.attendance_intervals
        (session_id,profile_id,interval_no,joined_at,left_at,credited_seconds,closed_by_room)
      values(p_session_id,p_profile_id,v_interval_no,v_open,greatest(v_open,v_room_end),v_credit,true);
    else
      v_anomaly:='sortie_non_confirmee';
    end if;
  end if;
  if v_session.status='tech_failure' or v_room_start is null or v_room_end is null
     or v_room_end <= v_session.started_at then
    v_anomaly:=coalesce(v_anomaly,'preuve_salle_incomplete');
  end if;
  if exists(select 1 from public.livekit_webhook_deliveries d
    where d.session_id=p_session_id and d.applique
      and d.detail->>'horodatage_reception'='true') then
    v_anomaly:=coalesce(v_anomaly,'horodatage_approxime');
  end if;
  if exists(select 1 from public.livekit_webhook_deliveries d
    where d.session_id=p_session_id and not d.applique
      and d.event_type in ('participant_joined','participant_left')) then
    v_anomaly:=coalesce(v_anomaly,'participant_non_reconnu');
  end if;
  v_outcome:=case
    when v_anomaly is not null then 'review'
    when v_seconds=0 and v_first_join is not null then 'review'
    when v_seconds=0 then 'absent'
    when v_first_academic > v_session.started_at+
         make_interval(secs=>public.app_config_int('presence.seuil_retard_secondes',300)) then 'late'
    else 'present' end;
  insert into public.attendance_records as a
    (session_id,profile_id,outcome,validated_seconds,first_joined_at,last_left_at,
     reconnection_count,anomaly,finalized_at)
  values(p_session_id,p_profile_id,v_outcome,v_seconds,v_first_join,v_last_left,
         v_reconnects,v_anomaly,now())
  on conflict(session_id,profile_id) do update
    set outcome=excluded.outcome, validated_seconds=excluded.validated_seconds,
        first_joined_at=excluded.first_joined_at,last_left_at=excluded.last_left_at,
        reconnection_count=excluded.reconnection_count,anomaly=excluded.anomaly,
        finalized_at=excluded.finalized_at
    where a.corrected_by is null;
end;
$$;
revoke all on function core24_private.finaliser_presence_participant(uuid,uuid)
 from public, anon, authenticated, agent_ro, service_role;

create function public.finaliser_presences_dues(p_limit int default 100)
returns int language plpgsql volatile security definer set search_path = '' as $$
declare v_session record; v_participant record; v_count int:=0; v_cutoff timestamptz;
begin
  if p_limit is null or p_limit not between 1 and 1000 then
    raise exception 'limite invalide' using errcode='22023'; end if;
  select (c.value #>> '{}')::timestamptz into v_cutoff from public.app_config c
    where c.key='presence.core24_started_at';
  for v_session in
    select s.id from public.sessions s
    where s.deleted_at is null and s.status not in ('canceled','canceled_late')
      and s.ended_at <= now()-make_interval(secs=>greatest(0,
        public.app_config_int('presence.absence_grace_seconds',300)))
      and (s.ended_at>=v_cutoff or s.created_at>=v_cutoff)
      and exists(
        select 1 from public.session_participants sp
        left join public.attendance_records a
          on a.session_id=sp.session_id and a.profile_id=sp.profile_id
        where sp.session_id=s.id and sp.deleted_at is null
          and sp.role in ('teacher','student') and a.corrected_by is null
          and (a.session_id is null or s.updated_at>a.finalized_at
            or exists(select 1 from public.livekit_webhook_deliveries d
              where d.session_id=s.id and d.recu_le>a.finalized_at))
      )
    order by s.ended_at,s.id limit p_limit
    for update of s skip locked
  loop
    for v_participant in select sp.profile_id from public.session_participants sp
      where sp.session_id=v_session.id and sp.deleted_at is null
        and sp.role in ('teacher','student')
    loop
      perform core24_private.finaliser_presence_participant(v_session.id,v_participant.profile_id);
    end loop;
    v_count:=v_count+1;
  end loop;
  return v_count;
end;
$$;
revoke all on function public.finaliser_presences_dues(int) from public,anon,authenticated,agent_ro;
grant execute on function public.finaliser_presences_dues(int) to service_role;

create function public.secondes_enseignement_validees()
returns bigint language sql stable security definer set search_path = '' as $$
  select coalesce(sum(a.validated_seconds),0)::bigint
    from public.attendance_records a
    join public.session_participants sp
      on sp.session_id=a.session_id and sp.profile_id=a.profile_id
    where sp.profile_id=auth.uid() and sp.role='teacher' and sp.deleted_at is null
      and a.outcome in ('present','late')
      and public.app_role()='teacher' and public.app_account_valid();
$$;
revoke all on function public.secondes_enseignement_validees() from public,anon,agent_ro;
grant execute on function public.secondes_enseignement_validees() to authenticated;

create function public.corriger_presence_academique(
  p_session_id uuid,p_profile_id uuid,p_outcome text,p_reason text
) returns public.attendance_records
language plpgsql volatile security definer set search_path = '' as $$
declare v_old public.attendance_records; v_new public.attendance_records;
begin
  if public.app_role() is distinct from 'admin'::public.app_role
     or not public.app_account_valid() then
    raise exception 'administration requise' using errcode='42501'; end if;
  if p_outcome not in ('present','late','absent','review','excused')
     or p_reason is null or length(btrim(p_reason)) not between 3 and 1000 then
    raise exception 'decision et motif requis' using errcode='22023'; end if;
  select * into v_old from public.attendance_records a
    where a.session_id=p_session_id and a.profile_id=p_profile_id for update;
  if not found then raise exception 'presence non finalisee' using errcode='22023'; end if;
  update public.attendance_records a set outcome=p_outcome,
    corrected_by=auth.uid(),corrected_at=now(),correction_reason=btrim(p_reason)
    where a.session_id=p_session_id and a.profile_id=p_profile_id returning * into v_new;
  perform public.log_sensitive_access('attendance_corrected','attendance_records',
    p_session_id::text,jsonb_build_object('profile_id',p_profile_id,
    'old_outcome',v_old.outcome,'new_outcome',p_outcome,'reason',btrim(p_reason),
    'validated_seconds',v_new.validated_seconds));
  return v_new;
end;
$$;
revoke all on function public.corriger_presence_academique(uuid,uuid,text,text)
 from public,anon,agent_ro;
grant execute on function public.corriger_presence_academique(uuid,uuid,text,text)
 to authenticated;

-- Supabase Cron executera la finalisation apres la grace, y compris si aucun
-- webhook ne suit la seance. Le conteneur PG generique des tests n'a pas
-- pg_cron : dans ce cas la fonction reste testable, mais le job est absent.
do $core24_cron$
begin
  if exists(select 1 from pg_catalog.pg_available_extensions
            where name='pg_cron') then
    execute 'create extension if not exists pg_cron';
    execute $sql$select cron.schedule(
      'core24-finaliser-presences', '* * * * *',
      'select public.finaliser_presences_dues(1000)')$sql$;
  else
    raise notice 'pg_cron indisponible : finalisation periodique non active';
  end if;
end;
$core24_cron$;
notify pgrst,'reload schema';
commit;
