-- Les élèves sont inscrits depuis le 2026-08-20, avant les 8 semaines rejouées.
update public.groupe_membres set joined_at = '2026-08-20T08:00:00Z'
where student_id::text like 'e51%' and groupe_id::text like 'e55%' and left_at is null;
