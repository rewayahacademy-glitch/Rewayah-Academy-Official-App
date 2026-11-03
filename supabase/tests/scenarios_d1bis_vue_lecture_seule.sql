-- D1-bis, correctif (20261107100000) : `concern_famille_v` en lecture seule,
-- et fermee aux mineurs.
-- Prouve, en authenticated :
--   1. le tuteur titulaire et un second tuteur du foyer lisent le message
--      transmis sur l'enfant ;
--   2. l'enfant ne lit rien, ni pour lui, ni pour son frere ou sa soeur ;
--   3. l'eleve adulte ne lit que ses propres lignes ;
--   4. un tuteur d'un autre foyer ne lit rien ;
--   5. modifier, retirer ou inserer par la vue est refuse au tuteur, et le
--      message en base reste intact ;
--   6. controle general : aucune vue de `public` n'est a la fois modifiable
--      et ouverte en ecriture a anon ou authenticated ;
--   7. droits : lecture seule pour authenticated, rien pour anon.
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
create function pg_temp.qui(p_uid text, p_jwt text) returns void
language plpgsql as $$
begin
  perform set_config('test.uid', p_uid, true);
  perform set_config('test.jwt', p_jwt, true);
  perform set_config('request.jwt.claim.sub', p_uid, true);
  perform set_config('request.jwt.claims', p_jwt, true);
end $$;
grant execute on function pg_temp.vrai(boolean, text), pg_temp.qui(text, text) to authenticated;

-- A direction ; T enseignant ; foyer F1 : G tuteur titulaire, G2 second
-- tuteur, M enfant, S soeur ; foyer F2 : H tuteur d'un autre foyer ; foyer
-- F3 : Y eleve adulte, titulaire de son foyer.
insert into auth.users (id, email) values
  ('d1c00000-0000-0000-0000-000000000001', 'd1c-admin@example.test'),
  ('d1c00000-0000-0000-0000-000000000002', 'd1c-teacher@example.test'),
  ('d1c00000-0000-0000-0000-000000000003', 'd1c-guardian@example.test'),
  ('d1c00000-0000-0000-0000-000000000004', 'd1c-enfant@example.test'),
  ('d1c00000-0000-0000-0000-000000000005', 'd1c-soeur@example.test'),
  ('d1c00000-0000-0000-0000-000000000006', 'd1c-autre@example.test'),
  ('d1c00000-0000-0000-0000-000000000007', 'd1c-adulte@example.test'),
  ('d1c00000-0000-0000-0000-000000000008', 'd1c-guardian2@example.test');
insert into public.households (id, timezone) values
  ('d1cfffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('d1cfffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('d1cfffff-0000-0000-0000-000000000003', 'Europe/Paris');
insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
  ('d1c00000-0000-0000-0000-000000000001', 'D1CADMIN00001', 'admin', null, 'Fixture', 'Admin', 'active', 'male'),
  ('d1c00000-0000-0000-0000-000000000002', 'D1CTEACHER001', 'teacher', null, 'Teacher', 'One', 'provisional_active', 'male'),
  ('d1c00000-0000-0000-0000-000000000003', 'D1CGUARDIAN01', 'guardian', 'd1cfffff-0000-0000-0000-000000000001', 'Fixture', 'Guardian', 'active', 'female'),
  ('d1c00000-0000-0000-0000-000000000004', 'D1CENFANT0001', 'student', 'd1cfffff-0000-0000-0000-000000000001', 'Fixture', 'Enfant', 'active', 'male'),
  ('d1c00000-0000-0000-0000-000000000005', 'D1CSOEUR00001', 'student', 'd1cfffff-0000-0000-0000-000000000001', 'Fixture', 'Soeur', 'active', 'male'),
  ('d1c00000-0000-0000-0000-000000000006', 'D1CAUTRE00001', 'guardian', 'd1cfffff-0000-0000-0000-000000000002', 'Fixture', 'Autre', 'active', 'female'),
  ('d1c00000-0000-0000-0000-000000000007', 'D1CADULTE0001', 'student', 'd1cfffff-0000-0000-0000-000000000003', 'Fixture', 'Adulte', 'active', 'male'),
  ('d1c00000-0000-0000-0000-000000000008', 'D1CGUARDIAN02', 'guardian', 'd1cfffff-0000-0000-0000-000000000001', 'Second', 'Guardian', 'active', 'male');
insert into public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values ('d1c00000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris');
update public.households set primary_guardian_id = 'd1c00000-0000-0000-0000-000000000003'
 where id = 'd1cfffff-0000-0000-0000-000000000001';
update public.households set primary_guardian_id = 'd1c00000-0000-0000-0000-000000000006'
 where id = 'd1cfffff-0000-0000-0000-000000000002';
update public.households set primary_guardian_id = 'd1c00000-0000-0000-0000-000000000007'
 where id = 'd1cfffff-0000-0000-0000-000000000003';
insert into public.student_profiles (profile_id, student_type, interface_mode) values
  ('d1c00000-0000-0000-0000-000000000004', 'minor', 'child'),
  ('d1c00000-0000-0000-0000-000000000005', 'minor', 'child'),
  ('d1c00000-0000-0000-0000-000000000007', 'autonomous', 'standard');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('d1cfffff-0000-0000-0000-000000000010', 'd1c00000-0000-0000-0000-000000000002', 'enfant', 5, 'D1C classe', 1, 10);
insert into public.groupe_membres (groupe_id, student_id) values
  ('d1cfffff-0000-0000-0000-000000000010', 'd1c00000-0000-0000-0000-000000000004'),
  ('d1cfffff-0000-0000-0000-000000000010', 'd1c00000-0000-0000-0000-000000000005'),
  ('d1cfffff-0000-0000-0000-000000000010', 'd1c00000-0000-0000-0000-000000000007');

create temporary table d1c_ids (nom text primary key, id uuid not null);
grant select, insert on d1c_ids to authenticated;

set local role authenticated;
select pg_temp.qui('d1c00000-0000-0000-0000-000000000002', '{"app_metadata":{"role":"teacher"}}');
insert into d1c_ids values
  ('enfant', (public.deposer_student_concern('pedagogique', 'd1cfffff-0000-0000-0000-000000000010', null,
     'D1CENFANT0001', 'D1C note interne enfant', null) ->> 'id')::uuid),
  ('adulte', (public.deposer_student_concern('presence', 'd1cfffff-0000-0000-0000-000000000010', null,
     'D1CADULTE0001', 'D1C note interne adulte', null) ->> 'id')::uuid);

select pg_temp.qui('d1c00000-0000-0000-0000-000000000001', '{"app_metadata":{"role":"admin"}}');
do $direction$
begin
  perform public.rediger_resume_student_concern((select id from d1c_ids where nom = 'enfant'), 'D1C message pour la famille');
  perform public.transmettre_student_concern((select id from d1c_ids where nom = 'enfant'), 'tuteur_du_mineur');
  perform public.rediger_resume_student_concern((select id from d1c_ids where nom = 'adulte'), 'D1C message pour l adulte');
  perform public.transmettre_student_concern((select id from d1c_ids where nom = 'adulte'), 'eleve_adulte');
end
$direction$;

-- 1. Le tuteur titulaire, puis le second tuteur du foyer.
select pg_temp.qui('d1c00000-0000-0000-0000-000000000003',
  '{"app_metadata":{"role":"guardian","household_id":"d1cfffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v
    where id = (select id from d1c_ids where nom = 'enfant') and family_summary = 'D1C message pour la famille') = 1
  and (select count(*) from public.concern_famille_v) = 1,
  '1. le tuteur titulaire lit le message sur l enfant, et lui seul');

-- 5. Lecture seule.
do $lecture_seule$
begin
  begin
    update public.concern_famille_v set family_summary = 'reecrit par le tuteur'
     where id = (select id from d1c_ids where nom = 'enfant');
    raise exception 'ROUGE : 5. le tuteur reecrit par la vue';
  exception when insufficient_privilege then null;
  end;
  begin
    execute 'delete from public.concern_famille_v';
    raise exception 'ROUGE : 5. le tuteur retire par la vue';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.concern_famille_v (id, categorie, family_summary) values (gen_random_uuid(), 'autre', 'x');
    raise exception 'ROUGE : 5. le tuteur insere par la vue';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 5. modifier, retirer, inserer par la vue : refuses au tuteur';
end
$lecture_seule$;

select pg_temp.qui('d1c00000-0000-0000-0000-000000000008',
  '{"app_metadata":{"role":"guardian","household_id":"d1cfffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v where id = (select id from d1c_ids where nom = 'enfant')) = 1,
  '1. le second tuteur du foyer lit aussi le message');

-- 2. L'enfant et sa soeur (jeton eleve du foyer).
select pg_temp.qui('d1c00000-0000-0000-0000-000000000004',
  '{"app_metadata":{"role":"student","household_id":"d1cfffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai((select count(*) from public.concern_famille_v) = 0,
  '2. l enfant ne lit rien, pas meme son propre message');
select pg_temp.qui('d1c00000-0000-0000-0000-000000000005',
  '{"app_metadata":{"role":"student","household_id":"d1cfffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai((select count(*) from public.concern_famille_v) = 0,
  '2. la soeur ne lit pas le message de son frere');

-- 3. L'eleve adulte.
select pg_temp.qui('d1c00000-0000-0000-0000-000000000007',
  '{"app_metadata":{"role":"student","household_id":"d1cfffff-0000-0000-0000-000000000003"}}');
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v where id = (select id from d1c_ids where nom = 'adulte')) = 1
  and (select count(*) from public.concern_famille_v) = 1,
  '3. l eleve adulte ne lit que ses propres lignes');

-- 4. Un tuteur d'un autre foyer.
select pg_temp.qui('d1c00000-0000-0000-0000-000000000006',
  '{"app_metadata":{"role":"guardian","household_id":"d1cfffff-0000-0000-0000-000000000002"}}');
select pg_temp.vrai((select count(*) from public.concern_famille_v) = 0,
  '4. un tuteur d un autre foyer ne lit rien');
reset role;

select pg_temp.vrai(
  (select family_summary from public.student_concern where id = (select id from d1c_ids where nom = 'enfant'))
    = 'D1C message pour la famille',
  '5. le message en base est intact');

-- 6. Controle general des vues de public.
select pg_temp.vrai(
  not exists (
    select 1
      from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'v'
       and pg_catalog.pg_relation_is_updatable(c.oid, true) <> 0
       and exists (select 1 from unnest(array['anon', 'authenticated']) r(role)
                    where pg_catalog.has_table_privilege(r.role, c.oid, 'INSERT')
                       or pg_catalog.has_table_privilege(r.role, c.oid, 'UPDATE')
                       or pg_catalog.has_table_privilege(r.role, c.oid, 'DELETE'))),
  '6. aucune vue de public modifiable et ouverte en ecriture a anon ou authenticated');

-- 7. Droits.
select pg_temp.vrai(
  has_table_privilege('authenticated', 'public.concern_famille_v', 'SELECT')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'INSERT')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'DELETE')
  and not has_table_privilege('anon', 'public.concern_famille_v', 'SELECT'),
  '7. droits : lecture seule pour authenticated, rien pour anon');

rollback;
