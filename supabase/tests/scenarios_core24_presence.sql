-- Presence academique : seules les livraisons LiveKit signees font foi.
-- A executer dans une transaction sur la chaine complete des migrations.
begin;
create function pg_temp.verifier(p_ok boolean, p_message text) returns void
language plpgsql as $$ begin
  if p_ok is distinct from true then raise exception '%', p_message; end if;
end $$;

insert into auth.users(id) values
 ('c2430000-0000-0000-0000-000000000001'),
 ('c2430000-0000-0000-0000-000000000002'),
 ('c2430000-0000-0000-0000-000000000003'),
 ('c2430000-0000-0000-0000-000000000004'),
 ('c2430000-0000-0000-0000-000000000005');
insert into public.households(id) values ('c243bbbb-0000-0000-0000-000000000001');
insert into public.profiles
  (id,immutable_id,role,first_name,last_name,account_status,gender,household_id) values
 ('c2430000-0000-0000-0000-000000000001','TEACH-C243-001','teacher','Prof','Test','active','male',null),
 ('c2430000-0000-0000-0000-000000000002','STUD-C243-001','student','Eleve','Test','active','female','c243bbbb-0000-0000-0000-000000000001'),
 ('c2430000-0000-0000-0000-000000000003','STUD-C243-002','student','Absent','Test','active','male','c243bbbb-0000-0000-0000-000000000001'),
 ('c2430000-0000-0000-0000-000000000004','ADMIN-C243-001','admin','Admin','Test','active','male',null),
 ('c2430000-0000-0000-0000-000000000005','STUD-C243-003','student','Avant','Test','active','female','c243bbbb-0000-0000-0000-000000000001');
insert into public.teacher_profiles(profile_id,kyc_status)
 values ('c2430000-0000-0000-0000-000000000001','approved');
insert into public.contract_acceptances(profile_id,contract_kind,version)
 values ('c2430000-0000-0000-0000-000000000001','teacher_nda','v1');
insert into public.app_config(key,value) values ('allow_multi_participant_sessions','true'::jsonb)
 on conflict (key) do update set value = excluded.value;
insert into public.sessions(id,teacher_id,started_at,ended_at,status) values
 ('c243aaaa-0000-0000-0000-000000000001','c2430000-0000-0000-0000-000000000001',
  now()-interval '60 minutes',now()-interval '30 minutes','ended'),
 ('c243aaaa-0000-0000-0000-000000000002','c2430000-0000-0000-0000-000000000001',
  now()-interval '180 minutes',now()-interval '150 minutes','ended'),
 ('c243aaaa-0000-0000-0000-000000000003','c2430000-0000-0000-0000-000000000001',
  now()-interval '120 minutes',now()-interval '90 minutes','ended'),
 ('c243aaaa-0000-0000-0000-000000000004','c2430000-0000-0000-0000-000000000001',
  now()-interval '240 minutes',now()-interval '210 minutes','ended');
insert into public.session_participants(session_id,profile_id,role) values
 ('c243aaaa-0000-0000-0000-000000000001','c2430000-0000-0000-0000-000000000001','teacher'),
 ('c243aaaa-0000-0000-0000-000000000001','c2430000-0000-0000-0000-000000000002','student'),
 ('c243aaaa-0000-0000-0000-000000000001','c2430000-0000-0000-0000-000000000003','student'),
 ('c243aaaa-0000-0000-0000-000000000001','c2430000-0000-0000-0000-000000000005','student'),
 ('c243aaaa-0000-0000-0000-000000000002','c2430000-0000-0000-0000-000000000002','student'),
 ('c243aaaa-0000-0000-0000-000000000003','c2430000-0000-0000-0000-000000000002','student');
-- Une livraison de participant sans identite reconnue rend la preuve ambigue.
insert into public.session_participants(session_id,profile_id,role) values
 ('c243aaaa-0000-0000-0000-000000000004','c2430000-0000-0000-0000-000000000003','student');
insert into public.session_video_route(session_id,provider,ws_url,room_name) values
 ('c243aaaa-0000-0000-0000-000000000001','cloud','wss://local.example','core24-presence-1'),
 ('c243aaaa-0000-0000-0000-000000000002','cloud','wss://local.example','core24-presence-2'),
 ('c243aaaa-0000-0000-0000-000000000003','cloud','wss://local.example','core24-presence-3'),
 ('c243aaaa-0000-0000-0000-000000000004','cloud','wss://local.example','core24-presence-4');

set local role service_role;
select pg_temp.verifier(public.enregistrer_webhook_livekit(
 'c243-room-start','room_started','core24-presence-1',null,
 now()-interval '80 minutes','{}'), 'room_started applique');
select pg_temp.verifier(not public.enregistrer_webhook_livekit(
 'c243-room-start','room_started','core24-presence-1',null,
 now()-interval '80 minutes','{}'), 'rejeu de room_started ignore');
select pg_temp.verifier(public.enregistrer_webhook_livekit(
 'c243-teacher-join','participant_joined','core24-presence-1',
 'c2430000-0000-0000-0000-000000000001',now()-interval '80 minutes','{}'),
 'teacher pret a T-20');
select public.enregistrer_webhook_livekit('c243-teacher-left','participant_left',
 'core24-presence-1','c2430000-0000-0000-0000-000000000001',
 now()-interval '40 minutes','{}');
select public.enregistrer_webhook_livekit('c243-student-join-1','participant_joined',
 'core24-presence-1','c2430000-0000-0000-0000-000000000002',
 now()-interval '54 minutes','{}');
select public.enregistrer_webhook_livekit('c243-student-left-1','participant_left',
 'core24-presence-1','c2430000-0000-0000-0000-000000000002',
 now()-interval '50 minutes','{}');
select public.enregistrer_webhook_livekit('c243-student-join-2','participant_joined',
 'core24-presence-1','c2430000-0000-0000-0000-000000000002',
 now()-interval '49 minutes','{}');
select public.enregistrer_webhook_livekit('c243-student-left-2','participant_left',
 'core24-presence-1','c2430000-0000-0000-0000-000000000002',
 now()-interval '45 minutes','{}');
select public.enregistrer_webhook_livekit('c243-early-join','participant_joined',
 'core24-presence-1','c2430000-0000-0000-0000-000000000005',
 now()-interval '80 minutes','{}');
select public.enregistrer_webhook_livekit('c243-early-left','participant_left',
 'core24-presence-1','c2430000-0000-0000-0000-000000000005',
 now()-interval '70 minutes','{}');
select public.enregistrer_webhook_livekit('c243-early-rejoin','participant_joined',
 'core24-presence-1','c2430000-0000-0000-0000-000000000005',
 now()-interval '50 minutes','{}');
select public.enregistrer_webhook_livekit('c243-early-final-left','participant_left',
 'core24-presence-1','c2430000-0000-0000-0000-000000000005',
 now()-interval '45 minutes','{}');
select pg_temp.verifier(public.enregistrer_webhook_livekit(
 'c243-room-finish','room_finished','core24-presence-1',null,
 now()-interval '30 minutes','{}'), 'room_finished applique');
select public.enregistrer_webhook_livekit('c243-room3-start','room_started',
 'core24-presence-3',null,now()-interval '120 minutes','{}');
select public.enregistrer_webhook_livekit('c243-room3-join','participant_joined',
 'core24-presence-3','c2430000-0000-0000-0000-000000000002',
 now()-interval '115 minutes','{"horodatage_reception":true}');
select public.enregistrer_webhook_livekit('c243-room3-finish','room_finished',
 'core24-presence-3',null,now()-interval '90 minutes','{}');
select public.enregistrer_webhook_livekit('c243-room4-start','room_started',
 'core24-presence-4',null,now()-interval '240 minutes','{}');
select pg_temp.verifier(not public.enregistrer_webhook_livekit(
 'c243-room4-unknown','participant_joined','core24-presence-4',null,
 now()-interval '235 minutes','{"identite_non_exploitable":true}'),
 'participant inconnu journalise sans etre applique');
select public.enregistrer_webhook_livekit('c243-room4-finish','room_finished',
 'core24-presence-4',null,now()-interval '210 minutes','{}');
select public.finaliser_presences_dues();
select pg_temp.verifier(public.finaliser_presences_dues()=0,
 'finalisation idempotente sans nouveau signal');
reset role;

select pg_temp.verifier((select outcome='present' and validated_seconds=1200
 from public.attendance_records where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000001'),
 'T-20 ne credite que 20 minutes apres T0');
select pg_temp.verifier((select outcome='late' and validated_seconds=480
 and reconnection_count=1 from public.attendance_records
 where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000002'),
 'retard et reconnexion donnent 8 minutes reelles');
select pg_temp.verifier((select outcome='late' and validated_seconds=300
 from public.attendance_records
 where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000005'),
 'entree pre-cours puis depart avant T0 ne masque pas un retour tardif');
select pg_temp.verifier((select count(*)=2 and sum(credited_seconds)=480
 from public.attendance_intervals
 where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000002'),
 'deux intervalles signes restent consultables');
select pg_temp.verifier((select outcome='absent' from public.attendance_records
 where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000003'),
 'no-show apres grace et room prouvee');
select pg_temp.verifier((select outcome='review' from public.attendance_records
 where session_id='c243aaaa-0000-0000-0000-000000000002'
 and profile_id='c2430000-0000-0000-0000-000000000002'),
 'absence de trace room devient revue');
select pg_temp.verifier((select outcome='review' and validated_seconds=1500
 from public.attendance_records
 where session_id='c243aaaa-0000-0000-0000-000000000003'
 and profile_id='c2430000-0000-0000-0000-000000000002'),
 'horodatage serveur absent exige revue meme avec duree calculee');
select pg_temp.verifier((select count(*)=1 and bool_and(closed_by_room)
 from public.attendance_intervals
 where session_id='c243aaaa-0000-0000-0000-000000000003'
 and profile_id='c2430000-0000-0000-0000-000000000002'),
 'room_finished ferme un intervalle sans participant_left');
select pg_temp.verifier((select outcome='review' from public.attendance_records
 where session_id='c243aaaa-0000-0000-0000-000000000004'
 and profile_id='c2430000-0000-0000-0000-000000000003'),
 'un participant inconnu interdit de conclure a une absence');
select pg_temp.verifier((select count(*)=1 from public.livekit_webhook_deliveries
 where event_id='c243-room-start' and session_id='c243aaaa-0000-0000-0000-000000000001'
 and applique), 'room event durable et lie a la seance');

select set_config('test.uid','c2430000-0000-0000-0000-000000000002',true);
select set_config('test.jwt','{"app_metadata":{"role":"student"}}',true);
set local role authenticated;
do $$ begin
  perform public.finaliser_presences_dues();
  raise exception 'un eleve a pu finaliser les presences';
exception when insufficient_privilege then null;
end $$;
do $$ begin
  insert into public.attendance_records(session_id,profile_id,outcome)
    values('c243aaaa-0000-0000-0000-000000000001',
           'c2430000-0000-0000-0000-000000000002','present');
  raise exception 'un eleve a pu forger une presence';
exception when insufficient_privilege then null;
end $$;
do $$ begin
  perform public.corriger_presence_academique(
    'c243aaaa-0000-0000-0000-000000000001',
    'c2430000-0000-0000-0000-000000000002','excused','Sans autorisation');
  raise exception 'un eleve a pu corriger une presence';
exception when insufficient_privilege then null;
end $$;
reset role;

select set_config('test.uid','c2430000-0000-0000-0000-000000000001',true);
select set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
set local role authenticated;
select pg_temp.verifier(public.secondes_enseignement_validees()=1200,
 'heures enseignant issues des intervalles signes');
reset role;
select set_config('test.uid','c2430000-0000-0000-0000-000000000004',true);
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
set local role authenticated;
select public.corriger_presence_academique(
 'c243aaaa-0000-0000-0000-000000000001',
 'c2430000-0000-0000-0000-000000000003','excused','Incident justifie');
reset role;
select pg_temp.verifier((select outcome='excused' and corrected_by='c2430000-0000-0000-0000-000000000004'
 from public.attendance_records where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000003'),
 'correction Admin motivee');
select pg_temp.verifier((select count(*)=1 from public.audit_logs
 where action='attendance_corrected' and row_id='c243aaaa-0000-0000-0000-000000000001'),
 'correction audit append-only');
select pg_temp.verifier((select count(*)=0 from public.session_events
 where session_id='c243aaaa-0000-0000-0000-000000000001'
 and profile_id='c2430000-0000-0000-0000-000000000003'),
 'correction ne fabrique pas de webhook');
rollback;
