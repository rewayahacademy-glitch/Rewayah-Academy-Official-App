-- D1-ter (20261107200000, 20261107200001) : la famille lit ce qui lui est
-- transmis.
-- Prouve, en authenticated :
--   1. le tuteur lit le message transmis sur son enfant, rangé sous l'enfant
--      (student_id) ; le titulaire du foyer est prévenu une seule fois
--      (message_academie_eleve, vers /tuteur/suivi), sans le résumé ;
--   2. l'élève adulte lit son propre message et il est prévenu (vers
--      /eleve/suivi) ;
--   3. un mineur ne lit rien, ni pour lui, ni pour son frère ou sa soeur ;
--   4. un tuteur d'un autre foyer ne lit rien ;
--   5. sécurité d'un enfant : rien, même une ligne forcée en base (transmise,
--      avec résumé) ; la transmission reste refusée ; aucune notification ;
--   6. la vue est en lecture seule : modifier, insérer ou retirer par elle
--      est refusé au tuteur ;
--   7. un message non transmis n'est pas lu.
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

-- A direction ; T enseignant ; foyer F1 : G tuteur titulaire, M mineur,
-- S soeur mineure ; foyer F2 : H tuteur d'un autre foyer ; foyer F3 : Y eleve
-- adulte, titulaire de son foyer.
insert into auth.users (id, email) values
  ('d1700000-0000-0000-0000-000000000001', 'd1t-admin@example.test'),
  ('d1700000-0000-0000-0000-000000000002', 'd1t-teacher@example.test'),
  ('d1700000-0000-0000-0000-000000000003', 'd1t-guardian@example.test'),
  ('d1700000-0000-0000-0000-000000000004', 'd1t-mineur@example.test'),
  ('d1700000-0000-0000-0000-000000000005', 'd1t-soeur@example.test'),
  ('d1700000-0000-0000-0000-000000000006', 'd1t-autre@example.test'),
  ('d1700000-0000-0000-0000-000000000007', 'd1t-adulte@example.test');
insert into public.households (id, timezone) values
  ('d17fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('d17fffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('d17fffff-0000-0000-0000-000000000003', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('d1700000-0000-0000-0000-000000000001', 'D1TADMIN00001', 'admin', null, 'Fixture', 'Admin', 'active', 'male'),
  ('d1700000-0000-0000-0000-000000000002', 'D1TTEACHER001', 'teacher', null, 'Teacher', 'One', 'provisional_active', 'male'),
  ('d1700000-0000-0000-0000-000000000003', 'D1TGUARDIAN01', 'guardian', 'd17fffff-0000-0000-0000-000000000001', 'Amina', 'Foyer', 'active', 'female'),
  ('d1700000-0000-0000-0000-000000000004', 'D1TMINEUR0001', 'student', 'd17fffff-0000-0000-0000-000000000001', 'Yasmine', 'Foyer', 'active', 'male'),
  ('d1700000-0000-0000-0000-000000000005', 'D1TSOEUR00001', 'student', 'd17fffff-0000-0000-0000-000000000001', 'Ines', 'Foyer', 'active', 'male'),
  ('d1700000-0000-0000-0000-000000000006', 'D1TAUTRE00001', 'guardian', 'd17fffff-0000-0000-0000-000000000002', 'Autre', 'Foyer', 'active', 'female'),
  ('d1700000-0000-0000-0000-000000000007', 'D1TADULTE0001', 'student', 'd17fffff-0000-0000-0000-000000000003', 'Karim', 'Adulte', 'active', 'male');
insert into public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values ('d1700000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris');
update public.households set primary_guardian_id = 'd1700000-0000-0000-0000-000000000003'
 where id = 'd17fffff-0000-0000-0000-000000000001';
update public.households set primary_guardian_id = 'd1700000-0000-0000-0000-000000000006'
 where id = 'd17fffff-0000-0000-0000-000000000002';
update public.households set primary_guardian_id = 'd1700000-0000-0000-0000-000000000007'
 where id = 'd17fffff-0000-0000-0000-000000000003';
insert into public.student_profiles (profile_id, student_type, interface_mode) values
  ('d1700000-0000-0000-0000-000000000004', 'minor', 'child'),
  ('d1700000-0000-0000-0000-000000000005', 'minor', 'child'),
  ('d1700000-0000-0000-0000-000000000007', 'autonomous', 'standard');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('d17fffff-0000-0000-0000-000000000010', 'd1700000-0000-0000-0000-000000000002', 'enfant', 5, 'D1T classe', 1, 10);
insert into public.groupe_membres (groupe_id, student_id) values
  ('d17fffff-0000-0000-0000-000000000010', 'd1700000-0000-0000-0000-000000000004'),
  ('d17fffff-0000-0000-0000-000000000010', 'd1700000-0000-0000-0000-000000000005'),
  ('d17fffff-0000-0000-0000-000000000010', 'd1700000-0000-0000-0000-000000000007');

create temporary table d1t_ids (nom text primary key, id uuid not null);
grant select, insert on d1t_ids to authenticated;

-- L'enseignant depose : un message pour M, un pour Y, une securite d'un enfant
-- pour M, un message non transmis pour S.
set local role authenticated;
select pg_temp.qui('d1700000-0000-0000-0000-000000000002', '{"app_metadata":{"role":"teacher"}}');
insert into d1t_ids values
  ('mineur', (public.deposer_student_concern('pedagogique', 'd17fffff-0000-0000-0000-000000000010', null,
     'D1TMINEUR0001', 'D1T note interne mineur', null) ->> 'id')::uuid),
  ('adulte', (public.deposer_student_concern('presence', 'd17fffff-0000-0000-0000-000000000010', null,
     'D1TADULTE0001', 'D1T note interne adulte', null) ->> 'id')::uuid),
  ('securite', (public.deposer_student_concern('securite_enfant', 'd17fffff-0000-0000-0000-000000000010', null,
     'D1TMINEUR0001', 'D1T note interne securite', null) ->> 'id')::uuid),
  ('soeur', (public.deposer_student_concern('technique', 'd17fffff-0000-0000-0000-000000000010', null,
     'D1TSOEUR00001', 'D1T note interne soeur', 'D1T message non transmis') ->> 'id')::uuid);

-- La direction redige et transmet.
select pg_temp.qui('d1700000-0000-0000-0000-000000000001', '{"app_metadata":{"role":"admin"}}');
do $direction$
begin
  perform public.rediger_resume_student_concern((select id from d1t_ids where nom = 'mineur'), 'D1T resume pour la famille de Yasmine');
  perform public.transmettre_student_concern((select id from d1t_ids where nom = 'mineur'), 'tuteur_du_mineur');
  perform public.rediger_resume_student_concern((select id from d1t_ids where nom = 'adulte'), 'D1T resume pour Karim');
  perform public.transmettre_student_concern((select id from d1t_ids where nom = 'adulte'), 'eleve_adulte');
  begin
    perform public.transmettre_student_concern((select id from d1t_ids where nom = 'securite'), 'tuteur_du_mineur');
    raise exception 'ROUGE : 5. une securite d un enfant transmise';
  exception when raise_exception then
    if sqlerrm not like '%securite%' then raise; end if;
  end;
  raise notice 'OK 5. la securite d un enfant ne se transmet pas (D1-bis)';
end
$direction$;
reset role;

-- La ligne forcee : une securite d'un enfant transmise avec resume, ecrite en
-- base sans passer par les fonctions (le cas qui ne doit jamais arriver).
-- La table la refuse deja (contrainte student_concern_securite_enfant_coherente) ;
-- pour prouver que la vue la refuse aussi, seule, la contrainte est levee dans
-- cette transaction (ROLLBACK a la fin).
do $contrainte$
begin
  begin
    update public.student_concern
       set family_summary = 'D1T resume force securite', transmis_le = now(),
           transmis_a = 'tuteur_du_mineur', statut = 'transmis'
     where id = (select id from d1t_ids where nom = 'securite');
    raise exception 'ROUGE : 5. la table accepte une securite d un enfant transmise';
  exception when check_violation then null;
  end;
  raise notice 'OK 5. la table refuse une securite d un enfant transmise (premier verrou)';
end
$contrainte$;
alter table public.student_concern drop constraint student_concern_securite_enfant_coherente;
update public.student_concern
   set family_summary = 'D1T resume force securite', transmis_le = now(),
       transmis_a = 'tuteur_du_mineur', statut = 'transmis'
 where id = (select id from d1t_ids where nom = 'securite');

-- 1 et 5. Le tuteur titulaire.
set local role authenticated;
select pg_temp.qui('d1700000-0000-0000-0000-000000000003',
  '{"app_metadata":{"role":"guardian","household_id":"d17fffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v
    where id = (select id from d1t_ids where nom = 'mineur')
      and student_id = 'd1700000-0000-0000-0000-000000000004'
      and family_summary = 'D1T resume pour la famille de Yasmine'
      and categorie = 'pedagogique' and transmis_a = 'tuteur_du_mineur') = 1,
  '1. le tuteur lit le message transmis, range sous l enfant (student_id)');
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v
    where id in (select id from d1t_ids where nom in ('securite', 'soeur', 'adulte'))) = 0,
  '5 et 7. le tuteur ne lit ni la securite d un enfant (meme forcee), ni un message non transmis, ni un autre foyer');
do $lecture_seule$
declare v_n integer;
begin
  begin
    update public.concern_famille_v set family_summary = 'reecrit' where id = (select id from d1t_ids where nom = 'mineur');
    raise exception 'ROUGE : 6. le tuteur reecrit par la vue';
  exception when insufficient_privilege then null;
  end;
  begin
    execute 'delete from public.concern_famille_v';
    raise exception 'ROUGE : 6. le tuteur retire par la vue';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.concern_famille_v (id, categorie, family_summary) values (gen_random_uuid(), 'autre', 'x');
    raise exception 'ROUGE : 6. le tuteur insere par la vue';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 6. la vue est en lecture seule pour le tuteur';
end
$lecture_seule$;
reset role;
select pg_temp.vrai(
  (select family_summary from public.student_concern where id = (select id from d1t_ids where nom = 'mineur'))
    = 'D1T resume pour la famille de Yasmine',
  '6. le message transmis est intact');

-- 3. Le mineur et sa soeur (jeton eleve du foyer).
set local role authenticated;
select pg_temp.qui('d1700000-0000-0000-0000-000000000004',
  '{"app_metadata":{"role":"student","household_id":"d17fffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai((select count(*) from public.concern_famille_v) = 0,
  '3. le mineur ne lit rien, pas meme son propre message');
select pg_temp.qui('d1700000-0000-0000-0000-000000000005',
  '{"app_metadata":{"role":"student","household_id":"d17fffff-0000-0000-0000-000000000001"}}');
select pg_temp.vrai((select count(*) from public.concern_famille_v) = 0,
  '3. la soeur mineure ne lit pas le message de son frere');

-- 4. Le tuteur d'un autre foyer.
select pg_temp.qui('d1700000-0000-0000-0000-000000000006',
  '{"app_metadata":{"role":"guardian","household_id":"d17fffff-0000-0000-0000-000000000002"}}');
select pg_temp.vrai((select count(*) from public.concern_famille_v) = 0,
  '4. un tuteur d un autre foyer ne lit rien');

-- 2. L'eleve adulte.
select pg_temp.qui('d1700000-0000-0000-0000-000000000007',
  '{"app_metadata":{"role":"student","household_id":"d17fffff-0000-0000-0000-000000000003"}}');
select pg_temp.vrai(
  (select count(*) from public.concern_famille_v
    where id = (select id from d1t_ids where nom = 'adulte')
      and student_id = 'd1700000-0000-0000-0000-000000000007'
      and family_summary = 'D1T resume pour Karim') = 1
  and (select count(*) from public.concern_famille_v) = 1,
  '2. l eleve adulte lit son propre message, et lui seul');
reset role;

-- Les notifications.
select pg_temp.vrai(
  (select count(*) from public.notifications n
    where n.evenement = 'message_academie_eleve'
      and n.destinataire = 'd1700000-0000-0000-0000-000000000003'
      and n.destination = '/tuteur/suivi'
      and n.foyer_id = 'd17fffff-0000-0000-0000-000000000001'
      and n.params ->> 'eleve_id' = 'd1700000-0000-0000-0000-000000000004'
      and n.params ->> 'prenom' = 'Yasmine' and n.params ->> 'portee' = 'foyer') = 1,
  '1. le titulaire du foyer est prevenu une fois, vers l Historique');
select pg_temp.vrai(
  (select count(*) from public.notifications n
    where n.evenement = 'message_academie_eleve'
      and n.destinataire = 'd1700000-0000-0000-0000-000000000007'
      and n.destination = '/eleve/suivi'
      and n.params ->> 'portee' = 'soi') = 1,
  '2. l eleve adulte est prevenu une fois, vers son Suivi');
select pg_temp.vrai(
  (select count(*) from public.notifications n where n.evenement = 'message_academie_eleve') = 2
  and not exists (select 1 from public.notifications n
                   where n.evenement = 'message_academie_eleve'
                     and (n.params::text like '%D1T resume%' or n.params::text like '%note interne%'))
  and not exists (select 1 from public.notifications n
                   where n.destinataire in ('d1700000-0000-0000-0000-000000000004',
                                            'd1700000-0000-0000-0000-000000000005')
                     and n.evenement = 'message_academie_eleve'),
  '1, 3 et 5. deux notifications en tout, sans resume ni note ; aucune aux mineurs ni pour la securite');
select pg_temp.vrai(
  not exists (select 1 from public.courriels_sortants c where c.modele = 'message_academie_eleve'),
  'application seulement : aucun e-mail (DECISION-NOTIFICATIONS-COURRIEL)');

-- Droits.
select pg_temp.vrai(
  has_table_privilege('authenticated', 'public.concern_famille_v', 'SELECT')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.concern_famille_v', 'INSERT')
  and not has_table_privilege('anon', 'public.concern_famille_v', 'SELECT'),
  'droits : lecture seule pour authenticated, rien pour anon');

rollback;
