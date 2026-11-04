-- PHOTOS-2a (04/11/2026, PLAN-LOTS §11, point 2) : la seconde porte
-- d'ecriture de la photo d'un eleve est fermee. Joue sous `authenticated`,
-- comme un client.
--   1. le tuteur n'ecrit plus `student_profiles.avatar_storage_key` en direct ;
--   2. il pose toujours la photo de son enfant par `poser_photo_eleve` ;
--   3. ses autres reglages (interface_mode, camera_policy) restent ecrits en
--      direct, comme avant ;
--   4. l'eleve adulte n'ecrit pas sa colonne en direct, il passe par
--      `poser_ma_photo`.
-- Tout est dans une transaction annulee : aucune donnee ne reste.
begin;

grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to authenticated;

insert into auth.users (id, email) values
  ('f2a00000-0000-0000-0000-000000000001', 'p2a-tuteur@example.test'),
  ('f2a00000-0000-0000-0000-000000000002', 'p2a-enfant@example.test'),
  ('f2a00000-0000-0000-0000-000000000003', 'p2a-adulte@example.test');

insert into public.households (id, timezone) values
  ('f2a0ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('f2a0ffff-0000-0000-0000-000000000002', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('f2a00000-0000-0000-0000-000000000001', 'P2ATUTEUR0001', 'guardian',
   'f2a0ffff-0000-0000-0000-000000000001', 'Tuteur', 'Deuxa', 'active', 'male'),
  ('f2a00000-0000-0000-0000-000000000002', 'P2AELEVE00001', 'student',
   'f2a0ffff-0000-0000-0000-000000000001', 'Enfant', 'Deuxa', 'active', 'male'),
  ('f2a00000-0000-0000-0000-000000000003', 'P2AELEVE00002', 'student',
   'f2a0ffff-0000-0000-0000-000000000002', 'Adulte', 'Deuxa', 'active', 'female');

update public.households set primary_guardian_id = 'f2a00000-0000-0000-0000-000000000001'
 where id = 'f2a0ffff-0000-0000-0000-000000000001';

insert into public.student_profiles (profile_id, student_type, interface_mode) values
  ('f2a00000-0000-0000-0000-000000000002', 'minor', 'child'),
  ('f2a00000-0000-0000-0000-000000000003', 'autonomous', 'standard');

create function pg_temp.etre(p_id uuid, p_role text) returns void language sql
security definer as $$
  select set_config('test.uid', p_id::text, true),
         set_config('test.jwt', pg_catalog.json_build_object('app_metadata',
           pg_catalog.json_build_object('role', p_role, 'household_id',
             (select household_id from public.profiles where id = p_id)))::text, true);
$$;
grant execute on function pg_temp.etre(uuid, text) to authenticated;

set local role authenticated;

do $tuteur$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f2a00000-0000-0000-0000-000000000001', 'guardian');

  -- 1. L'ecriture directe de la colonne est refusee.
  begin
    update public.student_profiles
       set avatar_storage_key = 'f2a00000-0000-0000-0000-000000000002/direct.jpg'
     where profile_id = 'f2a00000-0000-0000-0000-000000000002';
    raise exception 'P2A-1: le tuteur ecrit encore la colonne en direct';
  exception when insufficient_privilege then null;
  end;

  -- 2. La porte nommee pose la photo de son enfant.
  select * into v_ligne from public.poser_photo_eleve(
    'f2a00000-0000-0000-0000-000000000002',
    'f2a00000-0000-0000-0000-000000000002/porte.jpg');
  if v_ligne.cle is distinct from 'f2a00000-0000-0000-0000-000000000002/porte.jpg' then
    raise exception 'P2A-2: poser_photo_eleve n''a pas pose la photo : %', v_ligne;
  end if;

  -- 3. Les autres reglages du foyer restent ecrits en direct.
  update public.student_profiles
     set interface_mode = 'standard', camera_policy = camera_policy
   where profile_id = 'f2a00000-0000-0000-0000-000000000002';
end
$tuteur$;

do $adulte$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f2a00000-0000-0000-0000-000000000003', 'student');
  -- 4. L'eleve adulte ne l'ecrit pas en direct ; poser_ma_photo le fait.
  begin
    update public.student_profiles
       set avatar_storage_key = 'f2a00000-0000-0000-0000-000000000003/direct.jpg'
     where profile_id = 'f2a00000-0000-0000-0000-000000000003';
    raise exception 'P2A-4: l''eleve adulte ecrit la colonne en direct';
  exception when insufficient_privilege then null;
  end;
  select * into v_ligne from public.poser_ma_photo('f2a00000-0000-0000-0000-000000000003/moi.jpg');
  if v_ligne.cle is distinct from 'f2a00000-0000-0000-0000-000000000003/moi.jpg' then
    raise exception 'P2A-4: poser_ma_photo n''a pas pose la photo : %', v_ligne;
  end if;
end
$adulte$;

reset role;

do $verif$
begin
  if (select avatar_storage_key from public.student_profiles
       where profile_id = 'f2a00000-0000-0000-0000-000000000002')
     is distinct from 'f2a00000-0000-0000-0000-000000000002/porte.jpg' then
    raise exception 'P2A: la photo de l''enfant n''est pas celle posee par la porte';
  end if;
  if (select interface_mode::text from public.student_profiles
       where profile_id = 'f2a00000-0000-0000-0000-000000000002') <> 'standard' then
    raise exception 'P2A-3: le reglage du foyer n''a pas ete ecrit';
  end if;
end
$verif$;

rollback;
