-- Départs, un par semaine.
update public.groupe_membres m set left_at = (d.jour || 'T18:00:00Z')::timestamptz, left_by = 'e5300000-0000-4000-8000-000000000001'::uuid, left_reason = d.motif
from (values
  (2, '2026-09-05', 'depart : trop de travail cette annee'),
  (8, '2026-09-12', 'depart : horaires incompatibles'),
  (9, '2026-09-19', 'depart : insatisfaction du rythme'),
  (10, '2026-09-26', 'depart : demenagement'),
  (11, '2026-10-03', 'depart : raisons familiales'),
  (12, '2026-10-10', 'depart : pas de progres ressenti')
) d(n, jour, motif)
where m.student_id = ('e5100000-0000-4000-8000-' || lpad((d.n)::text, 12, '0'))::uuid and m.left_at is null;
-- Familles défaillantes : suspendues le 1er octobre, leurs élèves quittent leur classe.
update public.households set status = 'suspended' where id in ('e5400000-0000-4000-8000-000000000003'::uuid, 'e5400000-0000-4000-8000-000000000008'::uuid, 'e5400000-0000-4000-8000-000000000035'::uuid, 'e5400000-0000-4000-8000-000000000036'::uuid, 'e5400000-0000-4000-8000-000000000054'::uuid);
update public.groupe_membres set left_at = '2026-10-01T08:00:00Z', left_by = 'e5300000-0000-4000-8000-000000000001'::uuid,
  left_reason = 'suspension : deux mensualites impayees'
where left_at is null and student_id in ('e5100000-0000-4000-8000-000000000004'::uuid, 'e5100000-0000-4000-8000-000000000005'::uuid, 'e5100000-0000-4000-8000-000000000006'::uuid, 'e5100000-0000-4000-8000-000000000016'::uuid, 'e5100000-0000-4000-8000-000000000048'::uuid, 'e5100000-0000-4000-8000-000000000053'::uuid, 'e5100000-0000-4000-8000-000000000068'::uuid, 'e5100000-0000-4000-8000-000000000069'::uuid, 'e5100000-0000-4000-8000-000000000087'::uuid);
-- Comme retirer_eleve_groupe : plus de place dans les séances à venir.
update public.session_participants sp set deleted_at = now()
from public.sessions s, public.groupe_membres m
where s.id = sp.session_id and s.started_at > now() and sp.deleted_at is null and sp.role = 'student'
  and m.student_id = sp.profile_id and m.groupe_id = s.groupe_id and m.left_at is not null;
