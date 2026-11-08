-- PHOTO-FOYER (07/11/2026) : le tuteur pose la photo de tout membre de son
-- foyer qui n'a pas de compte propre, et la sienne ; une seule cle par personne.
-- Joue sous `authenticated`, comme un client. ROUGE sans
-- 20261120400000_photo_foyer.sql (PF1 echoue d'emblee), VERT avec.
--   PF1. adulte du foyer cree par le tuteur (child_of, autonome) : photo posee,
--        fichier ecrit dans son dossier. Cas en attente de la decision du
--        directeur : isole sur une ligne de private.photo_foyer_permise ; si
--        elle est retiree, PF1 s'inverse (refus attendu) ;
--   PF2. le tuteur qui etudie pose sa propre photo par poser_photo_eleve ; la
--        reprise recopie sa photo de profiles, qui reapparait par photo_source ;
--   PF3. adulte du foyer qui a son propre compte : refuse (RPC, ecriture,
--        remplacement et retrait du fichier) ;
--   PF4. tuteur d'un autre foyer : refuse ;
--   PF5. l'enfant mineur reste permis (non-regression).
-- Tout est dans une transaction annulee : aucune donnee ne reste.
begin;

grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to authenticated;

-- Foyer 1 : le tuteur (qui etudie aussi), son enfant mineur, un adulte qu'il a
-- cree (child_of), un adulte inscrit seul. Foyer 2 : un autre tuteur.
insert into auth.users (id, email, raw_app_meta_data) values
  ('f9f00000-0000-0000-0000-000000000001', 'pf-tuteur@example.test', '{}'::jsonb),
  ('f9f00000-0000-0000-0000-000000000002', 'pf-enfant@example.test',
   '{"child_of": "f9f00000-0000-0000-0000-000000000001"}'::jsonb),
  ('f9f00000-0000-0000-0000-000000000003', 'pf-adulte-cree@example.test',
   '{"child_of": "f9f00000-0000-0000-0000-000000000001"}'::jsonb),
  ('f9f00000-0000-0000-0000-000000000004', 'pf-adulte-seul@example.test', '{}'::jsonb),
  ('f9f00000-0000-0000-0000-000000000005', 'pf-autre-tuteur@example.test', '{}'::jsonb);

insert into public.households (id, timezone) values
  ('f9f0ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('f9f0ffff-0000-0000-0000-000000000002', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender,
   photo_storage_key)
values
  ('f9f00000-0000-0000-0000-000000000001', 'PFTUTEUR00001', 'guardian',
   'f9f0ffff-0000-0000-0000-000000000001', 'Tuteur', 'Foyer', 'active', 'male',
   'f9f00000-0000-0000-0000-000000000001/ancienne.jpg'),
  ('f9f00000-0000-0000-0000-000000000002', 'PFELEVE000001', 'student',
   'f9f0ffff-0000-0000-0000-000000000001', 'Enfant', 'Foyer', 'active', 'male', null),
  ('f9f00000-0000-0000-0000-000000000003', 'PFELEVE000002', 'student',
   'f9f0ffff-0000-0000-0000-000000000001', 'Adulte', 'Cree', 'active', 'female', null),
  ('f9f00000-0000-0000-0000-000000000004', 'PFELEVE000003', 'student',
   'f9f0ffff-0000-0000-0000-000000000001', 'Adulte', 'Seul', 'active', 'male', null),
  ('f9f00000-0000-0000-0000-000000000005', 'PFTUTEUR00002', 'guardian',
   'f9f0ffff-0000-0000-0000-000000000002', 'Autre', 'Tuteur', 'active', 'female', null);

update public.households set primary_guardian_id = 'f9f00000-0000-0000-0000-000000000001'
 where id = 'f9f0ffff-0000-0000-0000-000000000001';
update public.households set primary_guardian_id = 'f9f00000-0000-0000-0000-000000000005'
 where id = 'f9f0ffff-0000-0000-0000-000000000002';

insert into public.student_profiles (profile_id, student_type, interface_mode) values
  ('f9f00000-0000-0000-0000-000000000001', 'autonomous', 'standard'),
  ('f9f00000-0000-0000-0000-000000000002', 'minor', 'child'),
  ('f9f00000-0000-0000-0000-000000000003', 'autonomous', 'standard'),
  ('f9f00000-0000-0000-0000-000000000004', 'autonomous', 'standard');

-- Le fichier de l'adulte inscrit seul, deja dans le seau.
insert into storage.objects (bucket_id, name) values
  ('avatars', 'f9f00000-0000-0000-0000-000000000004/a-moi.jpg');

-- PF2 (avant la reprise) : la photo du tuteur qui etudie est masquee, la
-- source lit student_profiles en premier.
do $masquee$
begin
  if (select cle from private.photo_source('f9f00000-0000-0000-0000-000000000001')) is not null then
    raise exception 'PF2: fixture, la photo du tuteur n''est pas masquee';
  end if;
end
$masquee$;

create function pg_temp.etre(p_id uuid, p_role text) returns void language sql
security definer as $$
  select set_config('test.uid', p_id::text, true),
         set_config('test.jwt', pg_catalog.json_build_object('app_metadata',
           pg_catalog.json_build_object('role', p_role, 'household_id',
             (select household_id from public.profiles where id = p_id)))::text, true);
$$;
grant execute on function pg_temp.etre(uuid, text) to authenticated;

set local role authenticated;

-- ===========================================================================
-- PF1, PF5. Le tuteur pose la photo de l'adulte qu'il a cree et de l'enfant
-- ===========================================================================
do $permis$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f9f00000-0000-0000-0000-000000000001', 'guardian');

  select * into v_ligne from public.poser_photo_eleve(
    'f9f00000-0000-0000-0000-000000000003',
    'f9f00000-0000-0000-0000-000000000003/cree.jpg');
  if v_ligne.cle is distinct from 'f9f00000-0000-0000-0000-000000000003/cree.jpg' then
    raise exception 'PF1: la photo de l''adulte cree par le tuteur n''est pas posee : %', v_ligne;
  end if;
  insert into storage.objects (bucket_id, name)
  values ('avatars', 'f9f00000-0000-0000-0000-000000000003/cree.jpg');

  select * into v_ligne from public.poser_photo_eleve(
    'f9f00000-0000-0000-0000-000000000002',
    'f9f00000-0000-0000-0000-000000000002/enfant.jpg');
  if v_ligne.cle is distinct from 'f9f00000-0000-0000-0000-000000000002/enfant.jpg' then
    raise exception 'PF5: la photo de l''enfant mineur n''est plus posee : %', v_ligne;
  end if;
  insert into storage.objects (bucket_id, name)
  values ('avatars', 'f9f00000-0000-0000-0000-000000000002/enfant.jpg');
end
$permis$;

-- ===========================================================================
-- PF3. L'adulte du foyer qui a son propre compte : refuse
-- ===========================================================================
do $adulte_seul$
declare
  v_n integer;
begin
  perform pg_temp.etre('f9f00000-0000-0000-0000-000000000001', 'guardian');
  begin
    perform public.poser_photo_eleve('f9f00000-0000-0000-0000-000000000004',
      'f9f00000-0000-0000-0000-000000000004/par-le-tuteur.jpg');
    raise exception 'PF3: le tuteur a pose la photo d''un adulte qui a son compte';
  exception when raise_exception then
    if sqlerrm <> 'enfant introuvable dans votre foyer' then raise; end if;
  end;
  begin
    insert into storage.objects (bucket_id, name)
    values ('avatars', 'f9f00000-0000-0000-0000-000000000004/par-le-tuteur.jpg');
    raise exception 'PF3: le tuteur ecrit dans le dossier d''un adulte qui a son compte';
  exception when insufficient_privilege then null;
  end;
  update storage.objects set name = name
   where bucket_id = 'avatars' and name = 'f9f00000-0000-0000-0000-000000000004/a-moi.jpg';
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'PF3: le tuteur remplace le fichier d''un adulte qui a son compte';
  end if;
  delete from storage.objects
   where bucket_id = 'avatars' and name = 'f9f00000-0000-0000-0000-000000000004/a-moi.jpg';
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'PF3: le tuteur retire le fichier d''un adulte qui a son compte';
  end if;
end
$adulte_seul$;

-- ===========================================================================
-- PF4. Le tuteur d'un autre foyer : refuse
-- ===========================================================================
do $autre_foyer$
begin
  perform pg_temp.etre('f9f00000-0000-0000-0000-000000000005', 'guardian');
  begin
    perform public.poser_photo_eleve('f9f00000-0000-0000-0000-000000000003',
      'f9f00000-0000-0000-0000-000000000003/pirate.jpg');
    raise exception 'PF4: un tuteur a pose la photo d''un adulte d''un autre foyer';
  exception when raise_exception then
    if sqlerrm <> 'enfant introuvable dans votre foyer' then raise; end if;
  end;
  begin
    perform public.poser_photo_eleve('f9f00000-0000-0000-0000-000000000002',
      'f9f00000-0000-0000-0000-000000000002/pirate.jpg');
    raise exception 'PF4: un tuteur a pose la photo d''un enfant d''un autre foyer';
  exception when raise_exception then
    if sqlerrm <> 'enfant introuvable dans votre foyer' then raise; end if;
  end;
  begin
    insert into storage.objects (bucket_id, name)
    values ('avatars', 'f9f00000-0000-0000-0000-000000000003/pirate.jpg');
    raise exception 'PF4: un tuteur ecrit dans le dossier d''un autre foyer';
  exception when insufficient_privilege then null;
  end;
end
$autre_foyer$;

reset role;

-- ===========================================================================
-- PF2. Le tuteur qui etudie : reprise, puis sa propre photo
-- ===========================================================================
do $tuteur_eleve$
begin
  if private.photo_foyer_reprise() < 1 then
    raise exception 'PF2: la reprise n''a pas recopie la photo du tuteur';
  end if;
  if (select cle from private.photo_source('f9f00000-0000-0000-0000-000000000001'))
     is distinct from 'f9f00000-0000-0000-0000-000000000001/ancienne.jpg' then
    raise exception 'PF2: la photo du tuteur qui etudie ne reapparait pas';
  end if;
  if private.photo_foyer_reprise() <> 0 then
    raise exception 'PF2: la reprise n''est pas idempotente';
  end if;
end
$tuteur_eleve$;

set local role authenticated;

do $soi$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f9f00000-0000-0000-0000-000000000001', 'guardian');
  select * into v_ligne from public.poser_photo_eleve(
    'f9f00000-0000-0000-0000-000000000001',
    'f9f00000-0000-0000-0000-000000000001/nouvelle.jpg');
  if v_ligne.cle is distinct from 'f9f00000-0000-0000-0000-000000000001/nouvelle.jpg' then
    raise exception 'PF2: le tuteur qui etudie n''a pas pose sa photo : %', v_ligne;
  end if;
end
$soi$;

rollback;
