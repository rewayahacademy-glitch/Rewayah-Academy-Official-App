-- La seance s'ouvre aussi au jeton video de l'enseignant effectif
-- (02/11/2026) : supabase/migrations/20261102800000_seance_ouverte_par_le_jeton.sql.
--
--   J1  le jeton seul ouvre la seance : `planned` -> `in_progress`, temps
--       paye ouvert, sans aucun webhook ;
--   J2  un second jeton ne change rien (pas de double ouverture, temps paye
--       inchange) ;
--   J3  le webhook de l'enseignant apres le jeton ne change rien, et la
--       presence est ecrite ;
--   J4  webhook d'abord, jeton ensuite : une seule ouverture ;
--   J5  le titulaire remplace n'obtient aucun jeton et n'ouvre rien ; le
--       remplacant ouvre ;
--   J6  le jeton d'un eleve n'ouvre rien ;
--   J7  une salle ouverte en avance (`join_opens_at` avancee) delivre le
--       jeton, mais n'ouvre pas la seance hors de la fenetre normale.
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les
-- migrations. Tout est annule a la fin. Un echec leve 'JT ROUGE : ...'.

begin;

insert into auth.users (id, email) values
  ('1e700000-0000-4000-8000-000000000001', 'jt-t1@example.test'),
  ('1e700000-0000-4000-8000-000000000002', 'jt-t2@example.test'),
  ('1e700000-0000-4000-8000-000000000003', 'jt-t3@example.test'),
  ('1e700000-0000-4000-8000-000000000004', 'jt-r@example.test'),
  ('1e700000-0000-4000-8000-000000000005', 'jt-eleve@example.test');

insert into public.households (id, timezone) values
  ('1e70ffff-0000-4000-8000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('1e700000-0000-4000-8000-000000000001', 'TEACH-JT-000001', 'teacher', null, 'Hakim', 'Test', 'provisional_active', 'male'),
  ('1e700000-0000-4000-8000-000000000002', 'TEACH-JT-000002', 'teacher', null, 'Ilyas', 'Test', 'provisional_active', 'male'),
  ('1e700000-0000-4000-8000-000000000003', 'TEACH-JT-000003', 'teacher', null, 'Yusuf', 'Test', 'provisional_active', 'male'),
  ('1e700000-0000-4000-8000-000000000004', 'TEACH-JT-000004', 'teacher', null, 'Rachid', 'Test', 'provisional_active', 'male'),
  ('1e700000-0000-4000-8000-000000000005', 'STUD-JT-000005', 'student',
   '1e70ffff-0000-4000-8000-000000000001', 'Yanis', 'Test', 'active', 'male');

insert into public.teacher_profiles (profile_id, kyc_status) values
  ('1e700000-0000-4000-8000-000000000001', 'approved'),
  ('1e700000-0000-4000-8000-000000000002', 'approved'),
  ('1e700000-0000-4000-8000-000000000003', 'approved'),
  ('1e700000-0000-4000-8000-000000000004', 'approved');

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values ('1e700000-0000-4000-8000-000000000005', 'minor', 'standard', 'forbidden');

-- a : t1, commencee il y a 2 min (J1, J2, J3, J6) ;
-- b : t2, commencee il y a 2 min (J4) ;
-- c : t3, remplace par r, commence dans 5 min (J5) ;
-- d : t1, dans 3 jours, salle ouverte en avance (J7).
insert into public.sessions (id, teacher_id, started_at, ended_at, status, join_opens_at)
values
  ('1e70a000-0000-4000-8000-00000000000a', '1e700000-0000-4000-8000-000000000001',
   now() - interval '2 minutes', now() + interval '58 minutes', 'planned', null),
  ('1e70a000-0000-4000-8000-00000000000b', '1e700000-0000-4000-8000-000000000002',
   now() - interval '2 minutes', now() + interval '58 minutes', 'planned', null),
  ('1e70a000-0000-4000-8000-00000000000c', '1e700000-0000-4000-8000-000000000003',
   now() + interval '5 minutes', now() + interval '65 minutes', 'planned', null),
  ('1e70a000-0000-4000-8000-00000000000d', '1e700000-0000-4000-8000-000000000001',
   now() + interval '3 days', now() + interval '3 days 1 hour', 'planned', now() - interval '1 hour');

insert into public.session_participants (session_id, profile_id, role) values
  ('1e70a000-0000-4000-8000-00000000000a', '1e700000-0000-4000-8000-000000000005', 'student');

insert into public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
values
  ('1e70a000-0000-4000-8000-00000000000c', 'remplacement_pris',
   '1e700000-0000-4000-8000-000000000003', '1e700000-0000-4000-8000-000000000004',
   '1e700000-0000-4000-8000-000000000004', '1e70e000-0000-4000-8000-000000000001');

create function pg_temp.statut(p uuid) returns public.session_status language sql as
  $$ select status from public.sessions where id = p $$;
create function pg_temp.debut_paye(p uuid) returns timestamptz language sql as
  $$ select finance_started_at from public.sessions where id = p $$;
create function pg_temp.jeton(p_seance uuid, p_profil uuid) returns jsonb language sql as
  $$ select public.autoriser_jeton_video(p_seance, p_profil, 'wss://jt.cloud.test', 'wss://jt.auto.test') $$;
create function pg_temp.salle(p uuid) returns text language sql as
  $$ select room_name from public.session_video_route where session_id = p $$;

-- J6 d'abord : l'eleve demande son jeton avant l'enseignant.
do $$
begin
  if pg_temp.jeton('1e70a000-0000-4000-8000-00000000000a',
                   '1e700000-0000-4000-8000-000000000005')->>'role' <> 'student' then
    raise exception 'JT ROUGE J6 : jeton eleve non delivre';
  end if;
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000a') <> 'planned' then
    raise exception 'JT ROUGE J6 : le jeton d''un eleve a ouvert la seance';
  end if;
  raise notice 'JT OK J6 : le jeton d''un eleve n''ouvre rien';
end $$;

-- J1 : le jeton seul, sans aucun webhook.
do $$
begin
  if pg_temp.jeton('1e70a000-0000-4000-8000-00000000000a',
                   '1e700000-0000-4000-8000-000000000001')->>'role' <> 'teacher' then
    raise exception 'JT ROUGE J1 : jeton enseignant non delivre';
  end if;
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000a') <> 'in_progress' then
    raise exception 'JT ROUGE J1 : attendu in_progress, lu %',
      pg_temp.statut('1e70a000-0000-4000-8000-00000000000a');
  end if;
  if pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000a') is null then
    raise exception 'JT ROUGE J1 : temps paye non ouvert';
  end if;
  if exists (select 1 from public.livekit_webhook_deliveries d
              where d.room_name = pg_temp.salle('1e70a000-0000-4000-8000-00000000000a')) then
    raise exception 'JT ROUGE J1 : un webhook a ete recu, la preuve ne vaut pas';
  end if;
  raise notice 'JT OK J1 : le jeton seul ouvre la seance';
end $$;

-- J2 et J3.
do $$
declare
  v_debut timestamptz := pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000a');
begin
  perform pg_temp.jeton('1e70a000-0000-4000-8000-00000000000a',
                        '1e700000-0000-4000-8000-000000000001');
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000a') <> 'in_progress'
     or pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000a') is distinct from v_debut then
    raise exception 'JT ROUGE J2 : un second jeton a change la seance';
  end if;
  raise notice 'JT OK J2 : un second jeton ne rouvre rien';

  if not public.enregistrer_webhook_livekit('evt_jt_1', 'participant_joined',
       pg_temp.salle('1e70a000-0000-4000-8000-00000000000a'),
       '1e700000-0000-4000-8000-000000000001', now(), '{}'::jsonb) then
    raise exception 'JT ROUGE J3 : presence de l''enseignant non ecrite';
  end if;
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000a') <> 'in_progress'
     or pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000a') is distinct from v_debut then
    raise exception 'JT ROUGE J3 : le webhook apres le jeton a change la seance';
  end if;
  if exists (select 1 from public.livekit_webhook_deliveries
              where event_id = 'evt_jt_1' and detail ? 'statut_seance_erreur') then
    raise exception 'JT ROUGE J3 : le webhook a tente une seconde ouverture';
  end if;
  raise notice 'JT OK J3 : webhook apres jeton, une seule ouverture';
end $$;

-- J4 : webhook d'abord, jeton ensuite.
do $$
declare
  v_debut timestamptz;
begin
  perform r.room_name from public.video_route_de_seance(
    '1e70a000-0000-4000-8000-00000000000b', 'wss://jt.cloud.test', 'wss://jt.auto.test') r;
  perform public.enregistrer_webhook_livekit('evt_jt_2', 'participant_joined',
    pg_temp.salle('1e70a000-0000-4000-8000-00000000000b'),
    '1e700000-0000-4000-8000-000000000002', now(), '{}'::jsonb);
  v_debut := pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000b');
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000b') <> 'in_progress' or v_debut is null then
    raise exception 'JT ROUGE J4 : le webhook n''a pas ouvert la seance';
  end if;
  perform pg_temp.jeton('1e70a000-0000-4000-8000-00000000000b',
                        '1e700000-0000-4000-8000-000000000002');
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000b') <> 'in_progress'
     or pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000b') is distinct from v_debut then
    raise exception 'JT ROUGE J4 : le jeton apres le webhook a change la seance';
  end if;
  raise notice 'JT OK J4 : jeton apres webhook, une seule ouverture';
end $$;

-- J5 : titulaire remplace, puis remplacant.
do $$
begin
  begin
    perform pg_temp.jeton('1e70a000-0000-4000-8000-00000000000c',
                          '1e700000-0000-4000-8000-000000000003');
    raise exception 'JT ROUGE J5 : le titulaire remplace a obtenu un jeton';
  exception when insufficient_privilege then
    null;
  end;
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000c') <> 'planned' then
    raise exception 'JT ROUGE J5 : le titulaire remplace a ouvert la seance';
  end if;
  if pg_temp.jeton('1e70a000-0000-4000-8000-00000000000c',
                   '1e700000-0000-4000-8000-000000000004')->>'role' <> 'teacher' then
    raise exception 'JT ROUGE J5 : le remplacant n''a pas de jeton enseignant';
  end if;
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000c') <> 'in_progress' then
    raise exception 'JT ROUGE J5 : le jeton du remplacant n''a pas ouvert la seance';
  end if;
  raise notice 'JT OK J5 : le titulaire remplace n''ouvre rien, le remplacant ouvre';
end $$;

-- J7 : salle ouverte en avance, seance dans 3 jours.
do $$
begin
  if pg_temp.jeton('1e70a000-0000-4000-8000-00000000000d',
                   '1e700000-0000-4000-8000-000000000001')->>'role' <> 'teacher' then
    raise exception 'JT ROUGE J7 : jeton non delivre malgre la salle ouverte';
  end if;
  if pg_temp.statut('1e70a000-0000-4000-8000-00000000000d') <> 'planned'
     or pg_temp.debut_paye('1e70a000-0000-4000-8000-00000000000d') is not null then
    raise exception 'JT ROUGE J7 : seance ouverte trois jours avant son debut';
  end if;
  raise notice 'JT OK J7 : jamais d''ouverture hors de la fenetre normale';
end $$;

rollback;

select 'scenarios_seance_ouverte_jeton : 7 controles verts' as resultat;
