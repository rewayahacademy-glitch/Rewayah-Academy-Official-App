-- Retire les 8 semaines rejouées par jouer_vie_staging.mjs (STAGING seulement) et
-- remet la population de test dans son état du 17/10 au matin. La population
-- elle-même se retire avec supabase/seed/staging_population_test_nettoyage.sql.

-- Séances passées (toutes copiées : les séances d'origine sont « planned »).
delete from public.session_events e using public.sessions s
where e.session_id = s.id and s.groupe_id::text like 'e55%' and s.status in ('ended', 'canceled');
delete from public.session_participants sp using public.sessions s
where sp.session_id = s.id and s.groupe_id::text like 'e55%' and s.status in ('ended', 'canceled');
delete from public.sessions where groupe_id::text like 'e55%' and status in ('ended', 'canceled');

-- Signalements et demandes de créneau.
delete from public.student_concern where groupe_id::text like 'e55%';
delete from public.notifications where evenement in ('demande_recue', 'demande_close')
  and destinataire::text like 'e51%';
delete from public.demande_evenements where eleve_id::text like 'e51%';
delete from public.demandes_horaires_famille where eleve_id::text like 'e51%';

-- Changements de classe : on retire l'inscription d'arrivée, on rouvre celle de départ.
delete from public.session_participants sp using public.sessions s, public.groupe_membres m
where sp.session_id = s.id and s.started_at > now() and m.groupe_id = s.groupe_id and m.student_id = sp.profile_id
  and m.joined_at = '2026-10-05T18:00:00Z' and m.student_id::text like 'e51%';
delete from public.groupe_membres where student_id::text like 'e51%' and joined_at = '2026-10-05T18:00:00Z';
update public.groupe_membres set left_at = null, left_by = null, left_reason = null
where student_id::text like 'e51%' and groupe_id::text like 'e55%'
  and (left_reason like 'depart :%' or left_reason like 'suspension :%' or left_reason like 'transfert :%');
update public.session_participants sp set deleted_at = null
from public.sessions s
where sp.session_id = s.id and s.groupe_id::text like 'e55%' and s.started_at > now() and sp.deleted_at is not null;
update public.households set status = 'active' where id::text like 'e54%' and status = 'suspended';
