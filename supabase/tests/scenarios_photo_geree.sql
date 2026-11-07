-- PHOTO-GEREE (07/11/2026, migration 20261110340000) : le tuteur pose la
-- photo de TOUT profil eleve que son foyer gere (directeur : « on peut poser
-- une photo sur TOUS les profils que le tuteur gere »), joue sous
-- `authenticated`, comme un client.
--   1. accepte : un profil autonome (18 ans) du foyer, cree par le tuteur
--      (auth.users.raw_app_meta_data.child_of) ;
--   2. accepte toujours : un enfant mineur du foyer ;
--   3. refuse : un profil d'un autre foyer ;
--   4. refuse : un profil du foyer qui a son propre compte (aucun child_of) ;
--   5. refuse : le tuteur lui-meme (il passe par poser_ma_photo).
-- Tout est dans une transaction annulee : aucune donnee ne reste.
begin;

alter table auth.users add column if not exists raw_app_meta_data jsonb not null default '{}'::jsonb;

grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to authenticated;

insert into auth.users (id, email, raw_app_meta_data) values
  ('f9a00000-0000-0000-0000-000000000001', 'pg-tuteur@example.test', '{}'),
  ('f9a00000-0000-0000-0000-000000000002', 'pg-autonome-gere@example.test',
   '{"child_of": "f9a00000-0000-0000-0000-000000000001"}'),
  ('f9a00000-0000-0000-0000-000000000003', 'pg-mineur@example.test',
   '{"child_of": "f9a00000-0000-0000-0000-000000000001"}'),
  ('f9a00000-0000-0000-0000-000000000004', 'pg-autre-foyer@example.test',
   '{"child_of": "f9a00000-0000-0000-0000-000000000009"}'),
  ('f9a00000-0000-0000-0000-000000000005', 'pg-compte-propre@example.test', '{}');

insert into public.households (id, timezone) values
  ('f9a0ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('f9a0ffff-0000-0000-0000-000000000002', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('f9a00000-0000-0000-0000-000000000001', 'PGTUTEUR00001', 'guardian',
   'f9a0ffff-0000-0000-0000-000000000001', 'Tuteur', 'Gere', 'active', 'male'),
  ('f9a00000-0000-0000-0000-000000000002', 'PGELEVE000002', 'student',
   'f9a0ffff-0000-0000-0000-000000000001', 'Autonome', 'Gere', 'active', 'male'),
  ('f9a00000-0000-0000-0000-000000000003', 'PGELEVE000003', 'student',
   'f9a0ffff-0000-0000-0000-000000000001', 'Mineur', 'Gere', 'active', 'female'),
  ('f9a00000-0000-0000-0000-000000000004', 'PGELEVE000004', 'student',
   'f9a0ffff-0000-0000-0000-000000000002', 'Ailleurs', 'Gere', 'active', 'male'),
  ('f9a00000-0000-0000-0000-000000000005', 'PGELEVE000005', 'student',
   'f9a0ffff-0000-0000-0000-000000000001', 'Propre', 'Gere', 'active', 'female');

update public.households set primary_guardian_id = 'f9a00000-0000-0000-0000-000000000001'
 where id = 'f9a0ffff-0000-0000-0000-000000000001';

insert into public.student_profiles (profile_id, student_type, interface_mode) values
  ('f9a00000-0000-0000-0000-000000000002', 'autonomous', 'standard'),
  ('f9a00000-0000-0000-0000-000000000003', 'minor', 'child'),
  ('f9a00000-0000-0000-0000-000000000004', 'minor', 'child'),
  ('f9a00000-0000-0000-0000-000000000005', 'autonomous', 'standard');

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
  perform pg_temp.etre('f9a00000-0000-0000-0000-000000000001', 'guardian');

  -- 1. Le profil autonome que le tuteur a cree (cas reel du 07/11).
  select * into v_ligne from public.poser_photo_eleve(
    'f9a00000-0000-0000-0000-000000000002',
    'f9a00000-0000-0000-0000-000000000002/photo.jpg');
  if v_ligne.cle is distinct from 'f9a00000-0000-0000-0000-000000000002/photo.jpg' then
    raise exception 'PHOTO-GEREE ROUGE : la photo du profil autonome gere n''est pas posee : %', v_ligne;
  end if;
  raise notice 'PHOTO-GEREE OK : profil autonome cree par le tuteur, photo posee';

  -- 2. L'enfant mineur, comme avant.
  select * into v_ligne from public.poser_photo_eleve(
    'f9a00000-0000-0000-0000-000000000003',
    'f9a00000-0000-0000-0000-000000000003/photo.jpg');
  if v_ligne.cle is distinct from 'f9a00000-0000-0000-0000-000000000003/photo.jpg' then
    raise exception 'PHOTO-GEREE ROUGE : la photo de l''enfant mineur n''est plus posee : %', v_ligne;
  end if;
  raise notice 'PHOTO-GEREE OK : enfant mineur, photo posee comme avant';

  -- 3. Un profil d'un autre foyer.
  begin
    perform public.poser_photo_eleve('f9a00000-0000-0000-0000-000000000004',
      'f9a00000-0000-0000-0000-000000000004/photo.jpg');
    raise exception 'PHOTO-GEREE ROUGE : la photo d''un profil d''un autre foyer est posee';
  exception when raise_exception then
    if sqlerrm like 'PHOTO-GEREE ROUGE%' then raise; end if;
    raise notice 'PHOTO-GEREE OK : profil d''un autre foyer refuse (%)', sqlerrm;
  end;

  -- 4. Un profil du foyer qui a son propre compte.
  begin
    perform public.poser_photo_eleve('f9a00000-0000-0000-0000-000000000005',
      'f9a00000-0000-0000-0000-000000000005/photo.jpg');
    raise exception 'PHOTO-GEREE ROUGE : la photo d''un profil qui a son propre compte est posee';
  exception when raise_exception then
    if sqlerrm like 'PHOTO-GEREE ROUGE%' then raise; end if;
    raise notice 'PHOTO-GEREE OK : profil qui a son propre compte refuse (%)', sqlerrm;
  end;

  -- 5. Le tuteur lui-meme.
  begin
    perform public.poser_photo_eleve('f9a00000-0000-0000-0000-000000000001',
      'f9a00000-0000-0000-0000-000000000001/photo.jpg');
    raise exception 'PHOTO-GEREE ROUGE : le tuteur pose sa propre photo par poser_photo_eleve';
  exception when raise_exception then
    if sqlerrm like 'PHOTO-GEREE ROUGE%' then raise; end if;
    raise notice 'PHOTO-GEREE OK : le tuteur lui-meme refuse (poser_ma_photo)';
  end;
end
$tuteur$;

rollback;
