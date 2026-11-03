-- D1-bis, correctif (20261107100000) : `concern_famille_v` en lecture seule.
-- Prouve, en authenticated, sous le jeton du tuteur du foyer :
--   1. il lit toujours le message transmis ;
--   2. il ne peut ni le reecrire, ni en retirer, ni en inserer par la vue ;
--   3. le message en base est intact ;
--   4. anon ne lit rien.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
begin;

create function pg_temp.vrai(p_condition boolean, p_label text) returns void
language plpgsql as $$
begin
  if p_condition is not true then
    raise exception 'ROUGE : %', p_label;
  end if;
  raise notice 'OK %', p_label;
end $$;
grant execute on function pg_temp.vrai(boolean, text) to authenticated;

insert into auth.users (id, email) values
  ('d1c00000-0000-0000-0000-000000000001', 'd1c-admin@example.test'),
  ('d1c00000-0000-0000-0000-000000000002', 'd1c-teacher@example.test'),
  ('d1c00000-0000-0000-0000-000000000003', 'd1c-guardian@example.test'),
  ('d1c00000-0000-0000-0000-000000000004', 'd1c-student@example.test');
insert into public.households (id, timezone) values ('d1cfffff-0000-0000-0000-000000000001', 'Europe/Paris');
insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
  ('d1c00000-0000-0000-0000-000000000001', 'D1CADMIN00001', 'admin', null, 'Fixture', 'Admin', 'active', 'male'),
  ('d1c00000-0000-0000-0000-000000000002', 'D1CTEACHER001', 'teacher', null, 'Teacher', 'One', 'provisional_active', 'male'),
  ('d1c00000-0000-0000-0000-000000000003', 'D1CGUARDIAN01', 'guardian', 'd1cfffff-0000-0000-0000-000000000001', 'Fixture', 'Guardian', 'active', 'female'),
  ('d1c00000-0000-0000-0000-000000000004', 'D1CSTUDENT001', 'student', 'd1cfffff-0000-0000-0000-000000000001', 'Fixture', 'Student', 'active', 'male');
insert into public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values ('d1c00000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris');
update public.households set primary_guardian_id = 'd1c00000-0000-0000-0000-000000000003'
 where id = 'd1cfffff-0000-0000-0000-000000000001';
insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('d1c00000-0000-0000-0000-000000000004', 'minor', 'child');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('d1cfffff-0000-0000-0000-000000000002', 'd1c00000-0000-0000-0000-000000000002', 'enfant', 5, 'D1C classe', 1, 10);
insert into public.groupe_membres (groupe_id, student_id)
values ('d1cfffff-0000-0000-0000-000000000002', 'd1c00000-0000-0000-0000-000000000004');

create temporary table d1c_ids (nom text primary key, id uuid not null);
grant select, insert on d1c_ids to authenticated;

set local role authenticated;
select set_config('test.uid', 'd1c00000-0000-0000-0000-000000000002', true);
select set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
insert into d1c_ids values ('m', (public.deposer_student_concern('pedagogique',
  'd1cfffff-0000-0000-0000-000000000002', null, 'D1CSTUDENT001', 'D1C note interne', null) ->> 'id')::uuid);

select set_config('test.uid', 'd1c00000-0000-0000-0000-000000000001', true);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
do $direction$
begin
  perform public.rediger_resume_student_concern((select id from d1c_ids where nom = 'm'), 'D1C message pour la famille');
  perform public.transmettre_student_concern((select id from d1c_ids where nom = 'm'), 'tuteur_du_mineur');
end
$direction$;

-- Le tuteur du foyer.
select set_config('test.uid', 'd1c00000-0000-0000-0000-000000000003', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d1cfffff-0000-0000-0000-000000000001"}}', true);
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v
    where id = (select id from d1c_ids where nom = 'm') and family_summary = 'D1C message pour la famille') = 1,
  '1. le tuteur lit toujours le message transmis');
do $lecture_seule$
begin
  begin
    update public.concern_famille_v set family_summary = 'reecrit par le tuteur'
     where id = (select id from d1c_ids where nom = 'm');
    raise exception 'ROUGE : 2. le tuteur reecrit par la vue';
  exception when insufficient_privilege then null;
  end;
  begin
    execute 'delete from public.concern_famille_v';
    raise exception 'ROUGE : 2. le tuteur retire par la vue';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.concern_famille_v (id, categorie, family_summary) values (gen_random_uuid(), 'autre', 'x');
    raise exception 'ROUGE : 2. le tuteur insere par la vue';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 2. reecrire, retirer, inserer par la vue : refuses au tuteur';
end
$lecture_seule$;
reset role;

select pg_temp.vrai(
  (select family_summary from public.student_concern where id = (select id from d1c_ids where nom = 'm'))
    = 'D1C message pour la famille'
  and (select count(*) from public.student_concern where id = (select id from d1c_ids where nom = 'm')) = 1,
  '3. le message en base est intact');
select pg_temp.vrai(
  has_table_privilege('authenticated', 'public.concern_famille_v', 'SELECT')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'INSERT')
  and not has_table_privilege('anon', 'public.concern_famille_v', 'SELECT'),
  '4. droits : lecture seule pour authenticated, rien pour anon');

rollback;
