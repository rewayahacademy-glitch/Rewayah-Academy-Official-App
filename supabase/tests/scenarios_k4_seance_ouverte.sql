-- Scenarios de K4 n° 16 et n° 13 (30/10/2026) :
-- supabase/migrations/20261030120000_seance_ouverte_par_l_enseignant.sql.
--
--   K1  un eleve entre : la seance reste `planned` ;
--   K2  l'enseignant entre : `planned` -> `in_progress`, temps paye ouvert,
--       presence ecrite, identite gardee dans le journal de reception ;
--   K3  le meme webhook rejoue ne change rien ;
--   K4  une seance close ou annulee ne rouvre jamais ;
--   K5  un passage refuse ne fait pas perdre la presence (erreur consignee) ;
--   K6  `track_published` garde l'identite et la piste ;
--   K7  la cloture automatique termine la seance ouverte (`ended`, temps
--       paye ferme).
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les
-- migrations. Une seule fois par base : il insere ses fixtures.

insert into auth.users (id, email) values
  ('4b4e0000-0000-0000-0000-000000000001', 'k4-enseignant@example.test'),
  ('4b4e0000-0000-0000-0000-000000000002', 'k4-eleve@example.test');

insert into public.households (id, timezone) values
  ('4b4effff-0000-0000-0000-00000000000a', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('4b4e0000-0000-0000-0000-000000000001', 'TEACH-K4-000001', 'teacher',
   '4b4effff-0000-0000-0000-00000000000a', 'Hakim', 'Test', 'provisional_active', 'male'),
  ('4b4e0000-0000-0000-0000-000000000002', 'STUD-K4-000001', 'student',
   '4b4effff-0000-0000-0000-00000000000a', 'Yanis', 'Test', 'active', 'male');

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values ('4b4e0000-0000-0000-0000-000000000002', 'minor', 'standard', 'forbidden');

-- a : la seance du jour, commencee il y a deux minutes ;
-- b : une seance close ; c : une seance annulee ; d : la seance du K5.
insert into public.sessions (id, teacher_id, started_at, ended_at, status)
values
  ('4b4e0a00-0000-0000-0000-00000000000a', '4b4e0000-0000-0000-0000-000000000001',
   now() - interval '2 minutes', now() + interval '58 minutes', 'planned'),
  ('4b4e0a00-0000-0000-0000-00000000000b', '4b4e0000-0000-0000-0000-000000000001',
   now() - interval '5 hours', now() - interval '4 hours', 'planned'),
  ('4b4e0a00-0000-0000-0000-00000000000c', '4b4e0000-0000-0000-0000-000000000001',
   now() + interval '1 day', now() + interval '1 day 1 hour', 'canceled'),
  ('4b4e0a00-0000-0000-0000-00000000000d', '4b4e0000-0000-0000-0000-000000000001',
   now() + interval '2 days', now() + interval '2 days 1 hour', 'planned');

update public.sessions set status = 'preflight' where id = '4b4e0a00-0000-0000-0000-00000000000b';
update public.sessions set status = 'in_progress' where id = '4b4e0a00-0000-0000-0000-00000000000b';
update public.sessions set status = 'ended' where id = '4b4e0a00-0000-0000-0000-00000000000b';

insert into public.session_participants (session_id, profile_id, role) values
  ('4b4e0a00-0000-0000-0000-00000000000a', '4b4e0000-0000-0000-0000-000000000002', 'student');

do $$
begin
  perform r.room_name
     from unnest(array[
       '4b4e0a00-0000-0000-0000-00000000000a',
       '4b4e0a00-0000-0000-0000-00000000000b',
       '4b4e0a00-0000-0000-0000-00000000000c',
       '4b4e0a00-0000-0000-0000-00000000000d']::uuid[]) s,
          lateral public.video_route_de_seance(s, 'wss://k4.cloud.test', 'wss://k4.auto.test') r;
end $$;

create function pg_temp.salle(p uuid) returns text language sql as
  $$ select room_name from public.session_video_route where session_id = p $$;
create function pg_temp.statut(p uuid) returns public.session_status language sql as
  $$ select status from public.sessions where id = p $$;

-- K1
do $$
begin
  if not public.enregistrer_webhook_livekit('evt_k4_1', 'participant_joined',
       pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000a'),
       '4b4e0000-0000-0000-0000-000000000002', now(), '{}'::jsonb) then
    raise exception 'K1 ECHEC : la presence de l''eleve n''a pas ete ecrite';
  end if;
  if pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000a') <> 'planned' then
    raise exception 'K1 ECHEC : un eleve a ouvert la seance (%)',
      pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000a');
  end if;
end $$;

-- K2
do $$
declare
  v_s public.sessions%rowtype;
begin
  if not public.enregistrer_webhook_livekit('evt_k4_2', 'participant_joined',
       pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000a'),
       '4b4e0000-0000-0000-0000-000000000001', now(), '{}'::jsonb) then
    raise exception 'K2 ECHEC : la presence de l''enseignant n''a pas ete ecrite';
  end if;
  select * into v_s from public.sessions where id = '4b4e0a00-0000-0000-0000-00000000000a';
  if v_s.status <> 'in_progress' then
    raise exception 'K2 ECHEC : attendu in_progress, lu %', v_s.status;
  end if;
  if v_s.finance_started_at is null or v_s.finance_ended_at is not null then
    raise exception 'K2 ECHEC : temps paye mal ouvert (% / %)',
      v_s.finance_started_at, v_s.finance_ended_at;
  end if;
  if not exists (select 1 from public.session_events e
                  where e.session_id = v_s.id and e.event_type = 'joined'
                    and e.profile_id = '4b4e0000-0000-0000-0000-000000000001') then
    raise exception 'K2 ECHEC : presence de l''enseignant absente';
  end if;
  if (select d.detail->>'profile_id' from public.livekit_webhook_deliveries d
       where d.event_id = 'evt_k4_2') is distinct from '4b4e0000-0000-0000-0000-000000000001' then
    raise exception 'K2 ECHEC : identite absente du journal de reception';
  end if;
end $$;

-- K3
do $$
declare
  v_debut timestamptz;
begin
  select finance_started_at into v_debut from public.sessions
   where id = '4b4e0a00-0000-0000-0000-00000000000a';
  if public.enregistrer_webhook_livekit('evt_k4_2', 'participant_joined',
       pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000a'),
       '4b4e0000-0000-0000-0000-000000000001', now(), '{}'::jsonb) then
    raise exception 'K3 ECHEC : un rejeu a ete applique';
  end if;
  -- Une seconde entree (reconnexion) ne rouvre pas le temps paye.
  perform public.enregistrer_webhook_livekit('evt_k4_3', 'participant_joined',
    pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000a'),
    '4b4e0000-0000-0000-0000-000000000001', now(), '{}'::jsonb);
  if (select finance_started_at from public.sessions
       where id = '4b4e0a00-0000-0000-0000-00000000000a') is distinct from v_debut
     or pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000a') <> 'in_progress' then
    raise exception 'K3 ECHEC : une seconde entree a change la seance';
  end if;
end $$;

-- K4
do $$
begin
  perform public.enregistrer_webhook_livekit('evt_k4_4', 'participant_joined',
    pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000b'),
    '4b4e0000-0000-0000-0000-000000000001', now(), '{}'::jsonb);
  perform public.enregistrer_webhook_livekit('evt_k4_5', 'participant_joined',
    pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000c'),
    '4b4e0000-0000-0000-0000-000000000001', now(), '{}'::jsonb);
  if pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000b') <> 'ended'
     or pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000c') <> 'canceled' then
    raise exception 'K4 ECHEC : une seance close ou annulee a change (%, %)',
      pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000b'),
      pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000c');
  end if;
  if exists (select 1 from public.livekit_webhook_deliveries
              where event_id in ('evt_k4_4', 'evt_k4_5') and detail ? 'statut_seance_erreur') then
    raise exception 'K4 ECHEC : un passage a ete tente sur une seance close';
  end if;
end $$;

-- K5 : un declencheur de test refuse le passage de la seance d.
create function pg_temp.k4_refus() returns trigger language plpgsql as $$
begin
  raise exception 'refus de test K5';
end $$;
create trigger k4_refus_test before update of status on public.sessions
  for each row when (new.id = '4b4e0a00-0000-0000-0000-00000000000d')
  execute function pg_temp.k4_refus();

do $$
begin
  if not public.enregistrer_webhook_livekit('evt_k4_6', 'participant_joined',
       pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000d'),
       '4b4e0000-0000-0000-0000-000000000001', now(), '{}'::jsonb) then
    raise exception 'K5 ECHEC : la presence a ete perdue avec le statut';
  end if;
  if pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000d') <> 'planned' then
    raise exception 'K5 ECHEC : passage a moitie fait (%)',
      pg_temp.statut('4b4e0a00-0000-0000-0000-00000000000d');
  end if;
  if not exists (select 1 from public.session_events
                  where session_id = '4b4e0a00-0000-0000-0000-00000000000d'
                    and event_type = 'joined') then
    raise exception 'K5 ECHEC : presence absente';
  end if;
  if coalesce((select detail->>'statut_seance_erreur' from public.livekit_webhook_deliveries
                where event_id = 'evt_k4_6'), '') not like '%refus de test K5%' then
    raise exception 'K5 ECHEC : erreur non consignee';
  end if;
end $$;

alter table public.sessions disable trigger k4_refus_test;

-- K6
do $$
declare
  v_d jsonb;
begin
  if public.enregistrer_webhook_livekit('evt_k4_7', 'track_published',
       pg_temp.salle('4b4e0a00-0000-0000-0000-00000000000a'),
       '4b4e0000-0000-0000-0000-000000000002', now(),
       '{"piste":{"sid":"TR_k4","type":"VIDEO","source":"CAMERA","muted":false}}'::jsonb) then
    raise exception 'K6 ECHEC : une piste a ete ecrite comme presence';
  end if;
  select detail into v_d from public.livekit_webhook_deliveries where event_id = 'evt_k4_7';
  if v_d->>'profile_id' is distinct from '4b4e0000-0000-0000-0000-000000000002'
     or v_d#>>'{piste,source}' is distinct from 'CAMERA' then
    raise exception 'K6 ECHEC : journal de piste incomplet : %', v_d;
  end if;
end $$;

-- K7
do $$
declare
  v_s public.sessions%rowtype;
begin
  perform private.ses_cloturer_seances_echues(now() + interval '3 hours');
  select * into v_s from public.sessions where id = '4b4e0a00-0000-0000-0000-00000000000a';
  if v_s.status <> 'ended' or v_s.finance_ended_at is null
     or v_s.finance_ended_at <= v_s.finance_started_at then
    raise exception 'K7 ECHEC : attendu ended avec temps paye ferme, lu % (% / %)',
      v_s.status, v_s.finance_started_at, v_s.finance_ended_at;
  end if;
end $$;

select 'scenarios_k4_seance_ouverte : 7 controles verts' as resultat;
