-- Élèves inscrits à la date de chaque séance passée ; présents selon leur disponibilité.
insert into public.session_participants (session_id, profile_id, role, entered_at, exited_at, created_at)
select s.id, m.student_id, 'student',
  case when s.status = 'ended' and abs(hashtext(s.id::text || m.student_id::text)) % 100 >= case substr('dodddddodoodoooooododooddodoooododdddddddoddoddooddddddodddddddoddddoddooddddodddddodddooodoododoood', right(m.student_id::text, 12)::int, 1) when 'o' then 25 else 8 end then s.started_at + interval '2 minutes' end,
  case when s.status = 'ended' and abs(hashtext(s.id::text || m.student_id::text)) % 100 >= case substr('dodddddodoodoooooododooddodoooododdddddddoddoddooddddddodddddddoddddoddooddddodddddodddooodoododoood', right(m.student_id::text, 12)::int, 1) when 'o' then 25 else 8 end then s.ended_at end, s.created_at
from public.sessions s join public.groupe_membres m on m.groupe_id = s.groupe_id
  and m.joined_at <= s.started_at and (m.left_at is null or m.left_at > s.started_at)
where s.groupe_id::text like 'e55%' and s.started_at < now() and s.started_at >= '2026-08-20' and s.deleted_at is null and s.status <> 'planned';
insert into public.session_participants (session_id, profile_id, role, entered_at, exited_at, created_at)
select s.id, s.teacher_id, 'teacher',
  case when s.status = 'ended' then s.started_at - interval '3 minutes' end,
  case when s.status = 'ended' then s.ended_at end, s.created_at
from public.sessions s where s.groupe_id::text like 'e55%' and s.started_at < now() and s.started_at >= '2026-08-20' and s.deleted_at is null and s.status <> 'planned';
