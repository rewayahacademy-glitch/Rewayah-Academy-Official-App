-- 8 semaines de séances passées, copiées des créneaux de la première semaine
-- à venir ; 2 séances sur 100 annulées.
insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id, join_opens_at, prayer_pause_minutes, created_at, updated_at)
select md5('vie-staging' || s.id::text || k)::uuid, s.teacher_id,
  s.started_at - k * interval '7 days', s.ended_at - k * interval '7 days',
  (case when abs(hashtext(s.id::text || k)) % 100 < 2 then 'canceled' else 'ended' end)::public.session_status,
  s.session_type, s.groupe_id, s.join_opens_at - k * interval '7 days', s.prayer_pause_minutes,
  s.started_at - k * interval '7 days' - interval '28 days', s.ended_at - k * interval '7 days'
from public.sessions s cross join generate_series(1, 8) k
where s.groupe_id::text like 'e55%' and s.deleted_at is null and s.status = 'planned'
  and s.started_at >= now() and s.started_at < now() + interval '7 days'
  -- Une séance du jour déjà commencée garde son original : pas de doublon.
  and not exists (select 1 from public.sessions o where o.groupe_id = s.groupe_id and o.deleted_at is null
    and o.started_at = s.started_at - k * interval '7 days');
