-- Changements de classe le 5 octobre (même public, une place libre).
update public.groupe_membres m set left_at = (t.jour || 'T18:00:00Z')::timestamptz, left_by = 'e5300000-0000-4000-8000-000000000001'::uuid, left_reason = 'transfert : changement de creneau demande'
from (values
  (50, 'e5500000-0000-4000-8000-000000000002', '2026-10-05'),
  (73, 'e5500000-0000-4000-8000-000000000001', '2026-10-05'),
  (77, 'e5500000-0000-4000-8000-000000000001', '2026-10-05')
) t(n, cible, jour)
where m.student_id = ('e5100000-0000-4000-8000-' || lpad((t.n)::text, 12, '0'))::uuid and m.left_at is null;
-- Libérer les séances à venir de l’ancienne classe avant d’entrer dans la nouvelle
-- (sinon le garde-fou de chevauchement refuse les nouvelles séances).
update public.session_participants sp set deleted_at = now()
from public.sessions s, public.groupe_membres m
where s.id = sp.session_id and s.started_at > now() and sp.deleted_at is null and sp.role = 'student'
  and m.student_id = sp.profile_id and m.groupe_id = s.groupe_id and m.left_at is not null;
insert into public.groupe_membres (groupe_id, student_id, joined_at)
select t.cible::uuid, ('e5100000-0000-4000-8000-' || lpad((t.n)::text, 12, '0'))::uuid, (t.jour || 'T18:00:00Z')::timestamptz from (values
  (50, 'e5500000-0000-4000-8000-000000000002', '2026-10-05'),
  (73, 'e5500000-0000-4000-8000-000000000001', '2026-10-05'),
  (77, 'e5500000-0000-4000-8000-000000000001', '2026-10-05')
) t(n, cible, jour);
