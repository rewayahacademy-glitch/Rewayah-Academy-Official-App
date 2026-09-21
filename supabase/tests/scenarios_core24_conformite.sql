begin;
create function pg_temp.verifier(p_ok boolean, p_message text) returns void
language plpgsql as $$ begin
  if p_ok is distinct from true then raise exception '%', p_message; end if;
end $$;
grant usage on schema public to authenticated, service_role;

insert into auth.users(id) values
 ('c2400000-0000-0000-0000-000000000001'),
 ('c2400000-0000-0000-0000-000000000002'),
 ('c2400000-0000-0000-0000-000000000003'),
 ('c2400000-0000-0000-0000-000000000004');
insert into public.households(id) values ('c240bbbb-0000-0000-0000-000000000001');
insert into public.profiles(id, immutable_id, role, first_name, last_name, account_status, gender, household_id) values
 ('c2400000-0000-0000-0000-000000000001','ADMIN-C24-0001','admin','Admin','Test','active','male',null),
 ('c2400000-0000-0000-0000-000000000002','TEACH-C24-0001','teacher','Prof','Test','pending_kyc','male',null),
 ('c2400000-0000-0000-0000-000000000003','STUD-C24-0001','student','Eleve','Test','pending_kyc','male','c240bbbb-0000-0000-0000-000000000001'),
 ('c2400000-0000-0000-0000-000000000004','GUARD-C24-0001','guardian','Tuteur','Test','pending_kyc','male','c240bbbb-0000-0000-0000-000000000001');
insert into public.teacher_profiles(profile_id) values ('c2400000-0000-0000-0000-000000000002');
insert into public.student_profiles(profile_id, student_type, avatar_storage_key) values
 ('c2400000-0000-0000-0000-000000000003','minor','c2400000-0000-0000-0000-000000000003/photo.jpg');
insert into public.sessions(id, teacher_id, started_at, ended_at) values
 ('c240aaaa-0000-0000-0000-000000000001','c2400000-0000-0000-0000-000000000002',now(),now()+interval '1 hour');
insert into public.session_participants(session_id, profile_id, role) values
 ('c240aaaa-0000-0000-0000-000000000001','c2400000-0000-0000-0000-000000000002','teacher'),
 ('c240aaaa-0000-0000-0000-000000000001','c2400000-0000-0000-0000-000000000003','student');

select set_config('test.uid','c2400000-0000-0000-0000-000000000003',true);
select set_config('test.jwt','{"app_metadata":{"role":"student"}}',true);
set local role authenticated;
select pg_temp.verifier(public.app_account_valid(), 'KYC eleve ne bloque pas la navigation');
select pg_temp.verifier(public.conformite_classe()->>'kyc_requirement' = 'optional', 'KYC eleve optionnel');
select pg_temp.verifier((public.conformite_classe()->>'live_photo_uploaded')::boolean = false, 'la cle seule ne prouve pas un upload');
do $$ begin
  begin
    perform public.conformite_classe('c2400000-0000-0000-0000-000000000002');
    raise exception 'lecture conformite tierce acceptee';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

select set_config('test.uid','c2400000-0000-0000-0000-000000000004',true);
select set_config('test.jwt','{"app_metadata":{"role":"guardian"}}',true);
select pg_temp.verifier(public.app_account_valid(), 'KYC tuteur ne bloque pas la navigation');

select set_config('test.uid','c2400000-0000-0000-0000-000000000002',true);
select set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
set local role authenticated;
select pg_temp.verifier(not public.app_account_valid(), 'nouvel enseignant ferme');
select pg_temp.verifier(public.conformite_classe()->>'kyc_requirement' = 'required', 'KYC enseignant requis par defaut');
do $$ begin
  begin
    perform public.definir_exigence_kyc_enseignant('c2400000-0000-0000-0000-000000000002',false,'auto dispense');
    raise exception 'auto dispense acceptee';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.teacher_kyc_requirements(teacher_id, required, changed_by, reason)
      values ('c2400000-0000-0000-0000-000000000002',false,auth.uid(),'auto dispense');
    raise exception 'ecriture directe acceptee';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

select set_config('test.uid','c2400000-0000-0000-0000-000000000001',true);
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
set local role authenticated;
select public.definir_exigence_kyc_enseignant('c2400000-0000-0000-0000-000000000002',false,'Identite deja verifiee');
select public.definir_exigence_kyc_enseignant('c2400000-0000-0000-0000-000000000002',false,'Identite deja verifiee');
reset role;
select pg_temp.verifier((select count(*) = 1 from public.audit_logs
 where action = 'teacher_kyc_requirement_changed' and row_id = 'c2400000-0000-0000-0000-000000000002'), 'audit idempotent');
select pg_temp.verifier(not core24_private.enseignant_autorise('c2400000-0000-0000-0000-000000000002'), 'dispense ne dispense pas du contrat');
insert into public.contract_acceptances(profile_id, contract_kind, version) values
 ('c2400000-0000-0000-0000-000000000002','teacher_nda','v1');
select pg_temp.verifier(core24_private.enseignant_autorise('c2400000-0000-0000-0000-000000000002'), 'dispense et contrat ouvrent');
set local role authenticated;
select public.definir_exigence_kyc_enseignant('c2400000-0000-0000-0000-000000000002',true,'Nouvelle verification necessaire');
reset role;
select pg_temp.verifier(not core24_private.enseignant_autorise('c2400000-0000-0000-0000-000000000002'), 'reactivation ferme immediatement');
update public.teacher_profiles set kyc_status = 'approved' where profile_id = 'c2400000-0000-0000-0000-000000000002';
select pg_temp.verifier(core24_private.enseignant_autorise('c2400000-0000-0000-0000-000000000002'), 'KYC approuve et contrat ouvrent');

set local role service_role;
do $$ begin
  begin
    perform public.autoriser_jeton_video('c240aaaa-0000-0000-0000-000000000001',
      'c2400000-0000-0000-0000-000000000003','wss://cloud.example','wss://self.example');
    raise exception 'token mineur sans photo accepte';
  exception when insufficient_privilege then
    if sqlerrm <> 'photo_identification_requise' then raise; end if;
  end;
  begin
    perform public.autoriser_jeton_video('c240aaaa-0000-0000-0000-000000000001',
      'c2400000-0000-0000-0000-000000000004','wss://cloud.example','wss://self.example');
    raise exception 'token non participant accepte';
  exception when insufficient_privilege then
    if sqlerrm <> 'acces_salle_refuse' then raise; end if;
  end;
end $$;
reset role;
insert into storage.objects(bucket_id,name) values
 ('avatars','c2400000-0000-0000-0000-000000000003/photo.jpg');
set local role service_role;
select pg_temp.verifier(public.autoriser_jeton_video('c240aaaa-0000-0000-0000-000000000001',
 'c2400000-0000-0000-0000-000000000003','wss://cloud.example','wss://self.example')->>'identity'
 = 'c2400000-0000-0000-0000-000000000003', 'token mineur apres upload');
reset role;
delete from storage.objects where bucket_id = 'avatars';
update public.student_profiles set student_type = 'autonomous' where profile_id = 'c2400000-0000-0000-0000-000000000003';
set local role service_role;
select pg_temp.verifier(public.autoriser_jeton_video('c240aaaa-0000-0000-0000-000000000001',
 'c2400000-0000-0000-0000-000000000003','wss://cloud.example','wss://self.example') is not null,
 'adulte sans photo autorise');
reset role;
rollback;
