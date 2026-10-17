-- Ce que LiveKit aurait signalé : arrivée et départ de chaque présent.
insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
select sp.session_id, sp.profile_id, e.type::public.session_event_type, case e.type when 'joined' then sp.entered_at else sp.exited_at end, 'livekit_webhook'
from public.session_participants sp join public.sessions s on s.id = sp.session_id cross join (values ('joined'), ('left')) e(type)
where s.groupe_id::text like 'e55%' and s.started_at < now() and s.started_at >= '2026-08-20' and s.deleted_at is null and s.status <> 'planned' and sp.entered_at is not null;
