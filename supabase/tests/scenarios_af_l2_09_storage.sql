-- L2-09 (P2-3, P3-3, avatars de classe) : policies Storage sur storage.objects.
-- Prerequis : stub_auth.sql (storage.objects avec RLS) et migrations rejouees.
-- Tout est dans une transaction annulee a la fin ; aucune donnee ne reste.
-- Un refus est prouve par SQLSTATE 42501 exact (insufficient_privilege), jamais
-- par une autre erreur.
begin;

-- Le stub ne donne pas aux roles les privileges Storage d'un projet Supabase
-- (authenticated y a SELECT, INSERT, UPDATE, DELETE). Ces grants sont locaux a la
-- transaction : le rollback final les annule.
grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to authenticated;

insert into auth.users (id, email) values
  ('d2090000-0000-0000-0000-000000000001', 'l209-eleve1@example.test'),
  ('d2090000-0000-0000-0000-000000000002', 'l209-eleve2@example.test'),
  ('d2090000-0000-0000-0000-000000000003', 'l209-enseignant@example.test'),
  ('d2090000-0000-0000-0000-000000000004', 'l209-enseignant2@example.test'),
  ('d2090000-0000-0000-0000-000000000005', 'l209-admin@example.test'),
  ('d2090000-0000-0000-0000-000000000006', 'l209-tuteur@example.test'),
  ('d2090000-0000-0000-0000-000000000007', 'l209-suspendu@example.test');

insert into public.households (id, timezone) values
  ('d2090fff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('d2090fff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('d2090fff-0000-0000-0000-000000000003', 'Europe/Paris'),
  ('d2090fff-0000-0000-0000-000000000004', 'Europe/Paris'),
  ('d2090fff-0000-0000-0000-000000000005', 'Europe/Paris'),
  ('d2090fff-0000-0000-0000-000000000006', 'Europe/Paris'),
  ('d2090fff-0000-0000-0000-000000000007', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('d2090000-0000-0000-0000-000000000001', 'L209STUDENT00001', 'student',
   'd2090fff-0000-0000-0000-000000000001', 'L209', 'Eleve1', 'active'),
  ('d2090000-0000-0000-0000-000000000002', 'L209STUDENT00002', 'student',
   'd2090fff-0000-0000-0000-000000000002', 'L209', 'Eleve2', 'active'),
  ('d2090000-0000-0000-0000-000000000003', 'L209TEACHER00001', 'teacher',
   'd2090fff-0000-0000-0000-000000000003', 'L209', 'Enseignant', 'pending_kyc'),
  ('d2090000-0000-0000-0000-000000000004', 'L209TEACHER00002', 'teacher',
   'd2090fff-0000-0000-0000-000000000004', 'L209', 'Enseignant2', 'pending_kyc'),
  ('d2090000-0000-0000-0000-000000000005', 'L209ADMIN0000001', 'admin',
   'd2090fff-0000-0000-0000-000000000005', 'L209', 'Admin', 'active'),
  ('d2090000-0000-0000-0000-000000000006', 'L209GUARDIAN00001', 'guardian',
   'd2090fff-0000-0000-0000-000000000006', 'L209', 'Tuteur', 'active'),
  ('d2090000-0000-0000-0000-000000000007', 'L209SUSPENDU00001', 'teacher',
   'd2090fff-0000-0000-0000-000000000007', 'L209', 'Suspendu', 'disabled');

-- Garde 0089 : un enseignant ne passe active qu'avec ses contrats signes.
-- Signature par la voie serveur (signer_contrat, comme le fixture L1-05), puis
-- activation en superutilisateur.
do $fixture_enseignants$
declare
  v_teacher uuid;
  v_teacher_version text;
  v_notice_version text;
begin
  select version into v_teacher_version from public.contract_texts
   where contract_kind = 'teacher_nda' and locale = 'fr' and is_current;
  select version into v_notice_version from public.contract_required_versions
   where contract_kind = 'recording_and_control_notice';
  foreach v_teacher in array array['d2090000-0000-0000-0000-000000000003'::uuid,
                                   'd2090000-0000-0000-0000-000000000004'::uuid] loop
    perform set_config('request.jwt.claim.sub', v_teacher::text, true);
    perform set_config('test.uid', v_teacher::text, true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
    perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    perform public.signer_contrat(v_teacher_version, 'Fixture enseignant L2-09');
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values (v_teacher, 'recording_and_control_notice', v_notice_version)
    on conflict (profile_id, contract_kind, version) do nothing;
    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claims', '', true);
    perform set_config('test.uid', '', true);
    perform set_config('test.jwt', '', true);
    update public.profiles set account_status = 'active' where id = v_teacher;
  end loop;
end
$fixture_enseignants$;

insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('d2090000-0000-0000-0000-000000000001', 'minor', 'child'),
       ('d2090000-0000-0000-0000-000000000002', 'minor', 'child');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
values
  ('d2090000-0000-0000-0000-0000000000a1', 'd2090000-0000-0000-0000-000000000003',
   'enfant', 5, 'L209 classe 1', 1, 18, 'Europe/Paris'),
  ('d2090000-0000-0000-0000-0000000000a2', 'd2090000-0000-0000-0000-000000000004',
   'enfant', 5, 'L209 classe 2', 2, 18, 'Europe/Paris');
insert into public.groupe_membres (groupe_id, student_id) values
  ('d2090000-0000-0000-0000-0000000000a1', 'd2090000-0000-0000-0000-000000000001'),
  ('d2090000-0000-0000-0000-0000000000a2', 'd2090000-0000-0000-0000-000000000002');

-- Support publie et visible de tout compte actif (access_policy 'inscrits') : la
-- RLS de library_resource laisse donc l'ancienne policy supports_lecture
-- atteindre le fichier. Fixture en replica (sans triggers de publication CAP-29).
set local session_replication_role = replica;
insert into public.resource_version (id, resource_id, numero_version, statut)
values ('d2090000-0000-0000-0000-0000000000b2', 'd2090000-0000-0000-0000-0000000000b1', 1, 'publiee');
insert into public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy, current_version_id)
values
  ('d2090000-0000-0000-0000-0000000000b1', 'L2-09 support', 'L2-09', 'pdf',
   'inscrits', 'jamais', 'd2090000-0000-0000-0000-0000000000b2');
set local session_replication_role = origin;

-- Buckets : crees par 0030 et 0004 quand le schema storage existe.
insert into storage.buckets (id, name, public) values
  ('supports', 'supports', false),
  ('avatars', 'avatars', false),
  ('photos_enseignants', 'photos_enseignants', false)
on conflict (id) do nothing;

insert into storage.objects (bucket_id, name, owner_id) values
  ('supports', 'd2090000-0000-0000-0000-0000000000b1/1/manuel.pdf', 'd2090000-0000-0000-0000-000000000003'),
  ('avatars', 'd2090000-0000-0000-0000-000000000001/avatar.jpg', 'd2090000-0000-0000-0000-000000000001'),
  ('avatars', 'd2090000-0000-0000-0000-000000000002/avatar.jpg', 'd2090000-0000-0000-0000-000000000002'),
  ('photos_enseignants', 'd2090000-0000-0000-0000-000000000003/photo.jpg', 'd2090000-0000-0000-0000-000000000003');

do $$
declare n int;
begin
  select count(*) into n from storage.objects;
  if n <> 4 then raise exception 'L2-09 fixture: % objets, 4 attendus', n; end if;
end $$;

-- 1. Eleve : aucune lecture directe d'un support, meme retire de sa classe.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000001","app_metadata":{"role":"student"}}', true);
do $$
declare n int;
begin
  select count(*) into n from storage.objects where bucket_id = 'supports';
  if n <> 0 then
    raise exception 'L2-09: un eleve lit % support(s) directement (attendu 0)', n;
  end if;
  select count(*) into n from storage.objects where bucket_id = 'avatars';
  if n <> 1 then
    raise exception 'L2-09: un eleve lit % avatar(s), attendu 1 (le sien seulement)', n;
  end if;
end $$;
reset role;

-- 2. Administration valide : lit le support et les deux avatars.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000005', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000005","app_metadata":{"role":"admin"}}', true);
do $$
declare n int;
begin
  select count(*) into n from storage.objects where bucket_id = 'supports';
  if n <> 1 then raise exception 'L2-09: admin lit % support(s), attendu 1', n; end if;
  select count(*) into n from storage.objects where bucket_id = 'avatars';
  if n <> 2 then raise exception 'L2-09: admin lit % avatar(s), attendu 2', n; end if;
end $$;
reset role;

-- 3. Enseignant de la classe 1 : son eleve seulement, pas celui de la classe 2.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000003","app_metadata":{"role":"teacher"}}', true);
do $$
declare n int;
begin
  select count(*) into n from storage.objects
   where bucket_id = 'avatars' and name like 'd2090000-0000-0000-0000-000000000001/%';
  if n <> 1 then raise exception 'L2-09: enseignant ne lit pas l avatar de son eleve (%)', n; end if;
  select count(*) into n from storage.objects
   where bucket_id = 'avatars' and name like 'd2090000-0000-0000-0000-000000000002/%';
  if n <> 0 then raise exception 'L2-09: enseignant lit l avatar d un eleve d une autre classe (%)', n; end if;
  select count(*) into n from storage.objects where bucket_id = 'supports';
  if n <> 0 then raise exception 'L2-09: enseignant lit un support directement (%)', n; end if;
end $$;
reset role;

-- 4. Tuteur : n'ecrit pas dans photos_enseignants (SQLSTATE 42501 exact).
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000006', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000006","app_metadata":{"role":"guardian"}}', true);
do $$
begin
  insert into storage.objects (bucket_id, name, owner_id)
  values ('photos_enseignants', 'd2090000-0000-0000-0000-000000000006/photo.jpg', 'd2090000-0000-0000-0000-000000000006');
  raise exception 'L2-09: le tuteur a ecrit une photo d enseignant';
exception when insufficient_privilege then
  null;
end $$;
reset role;

-- 5. Compte enseignant suspendu : n'ecrit pas, meme avec le role (app_account_valid).
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000007', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000007","app_metadata":{"role":"teacher"}}', true);
do $$
begin
  insert into storage.objects (bucket_id, name, owner_id)
  values ('photos_enseignants', 'd2090000-0000-0000-0000-000000000007/photo.jpg', 'd2090000-0000-0000-0000-000000000007');
  raise exception 'L2-09: un compte suspendu a ecrit une photo d enseignant';
exception when insufficient_privilege then
  null;
end $$;
reset role;

-- 6. Enseignant : ecrit dans son propre dossier.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000003","app_metadata":{"role":"teacher"}}', true);
insert into storage.objects (bucket_id, name, owner_id)
values ('photos_enseignants', 'd2090000-0000-0000-0000-000000000003/photo-2.jpg', 'd2090000-0000-0000-0000-000000000003');
reset role;

-- 7. Retrait : un eleve quitte la classe 1 ; son enseignant ne voit plus l'avatar.
update public.groupe_membres
   set left_at = now(), left_by = 'd2090000-0000-0000-0000-000000000003', left_reason = 'retrait test L2-09'
 where groupe_id = 'd2090000-0000-0000-0000-0000000000a1'
   and student_id = 'd2090000-0000-0000-0000-000000000001';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd2090000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"d2090000-0000-0000-0000-000000000003","app_metadata":{"role":"teacher"}}', true);
do $$
declare n int;
begin
  select count(*) into n from storage.objects
   where bucket_id = 'avatars' and name like 'd2090000-0000-0000-0000-000000000001/%';
  if n <> 0 then raise exception 'L2-09: un eleve retire reste visible a son enseignant (%)', n; end if;
end $$;
reset role;

select 'L2-09 storage : PASS' as resultat;

rollback;
