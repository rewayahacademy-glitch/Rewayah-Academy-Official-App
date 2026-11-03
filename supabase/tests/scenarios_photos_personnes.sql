-- PHOTOS-1 (03/11/2026, PLAN-LOTS §11) : une seule photo par personne, la
-- meme partout. Joue sous `authenticated`, comme un client.
--   1. le camarade de Classe voit la photo de l'enfant ; le parent du
--      camarade non (K-44 stricte, garde-cap 03/11) ; une autre famille non ;
--   2. l'enseignant voit celles de ses eleves, un autre enseignant non ;
--   3. l'eleve adulte pose la sienne (dans sa colonne, son dossier) ;
--   4. le tuteur ne pose pas celle d'un enfant d'un autre foyer ;
--   5. l'enfant en Interface guidee ne pose rien ;
--   6. un mineur d'une autre famille, hors de la Classe, ne voit rien ;
-- et : la photo d'un tuteur (colonne nouvelle), celle de la direction, celle
-- d'un enseignant, une cle hors de son dossier refusee, une ecriture directe
-- refusee, l'effacement a l'anonymisation ; et (PHOTOS-2a) la cle de photo
-- d'un eleve n'est plus ecrite en direct par un client.
-- Tout est dans une transaction annulee : aucune donnee ne reste.
begin;

-- Le stub ne donne pas a `authenticated` les droits Storage d'un projet
-- Supabase ; locaux a la transaction.
grant usage on schema storage to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to authenticated;

-- Hakim (enfant, Interface guidee) et son tuteur ; Camil, camarade de Classe,
-- et son tuteur ; Omar, d'une autre famille, hors de la Classe, et son
-- tuteur ; Adam, eleve adulte de la Classe ; deux enseignants ; la direction.
insert into auth.users (id, email) values
  ('f0700000-0000-0000-0000-000000000001', 'ph-tuteur-hakim@example.test'),
  ('f0700000-0000-0000-0000-000000000002', 'ph-hakim@example.test'),
  ('f0700000-0000-0000-0000-000000000003', 'ph-tuteur-camil@example.test'),
  ('f0700000-0000-0000-0000-000000000004', 'ph-camil@example.test'),
  ('f0700000-0000-0000-0000-000000000005', 'ph-tuteur-omar@example.test'),
  ('f0700000-0000-0000-0000-000000000006', 'ph-omar@example.test'),
  ('f0700000-0000-0000-0000-000000000007', 'ph-adam@example.test'),
  ('f0700000-0000-0000-0000-000000000008', 'ph-enseignant@example.test'),
  ('f0700000-0000-0000-0000-000000000009', 'ph-enseignant2@example.test'),
  ('f0700000-0000-0000-0000-00000000000a', 'ph-direction@example.test');

insert into public.households (id, timezone) values
  ('f070ffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('f070ffff-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('f070ffff-0000-0000-0000-000000000003', 'Europe/Paris'),
  ('f070ffff-0000-0000-0000-000000000004', 'Europe/Paris'),
  ('f070ffff-0000-0000-0000-000000000005', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('f0700000-0000-0000-0000-000000000001', 'PHTUTEUR00001', 'guardian',
   'f070ffff-0000-0000-0000-000000000001', 'Tuteur', 'Hakim', 'active', 'male'),
  ('f0700000-0000-0000-0000-000000000002', 'PHELEVE000001', 'student',
   'f070ffff-0000-0000-0000-000000000001', 'Hakim', 'Eleve', 'active', 'male'),
  ('f0700000-0000-0000-0000-000000000003', 'PHTUTEUR00002', 'guardian',
   'f070ffff-0000-0000-0000-000000000002', 'Tuteur', 'Camil', 'active', 'female'),
  ('f0700000-0000-0000-0000-000000000004', 'PHELEVE000002', 'student',
   'f070ffff-0000-0000-0000-000000000002', 'Camil', 'Eleve', 'active', 'male'),
  ('f0700000-0000-0000-0000-000000000005', 'PHTUTEUR00003', 'guardian',
   'f070ffff-0000-0000-0000-000000000003', 'Tuteur', 'Omar', 'active', 'female'),
  ('f0700000-0000-0000-0000-000000000006', 'PHELEVE000003', 'student',
   'f070ffff-0000-0000-0000-000000000003', 'Omar', 'Eleve', 'active', 'male'),
  ('f0700000-0000-0000-0000-000000000007', 'PHELEVE000004', 'student',
   'f070ffff-0000-0000-0000-000000000004', 'Adam', 'Adulte', 'active', 'male'),
  ('f0700000-0000-0000-0000-000000000008', 'PHENSEIGN0001', 'teacher',
   'f070ffff-0000-0000-0000-000000000005', 'Enseignant', 'Un', 'provisional_active', 'male'),
  ('f0700000-0000-0000-0000-000000000009', 'PHENSEIGN0002', 'teacher',
   'f070ffff-0000-0000-0000-000000000005', 'Enseignant', 'Deux', 'provisional_active', 'male'),
  ('f0700000-0000-0000-0000-00000000000a', 'PHDIRECTION01', 'admin',
   null, 'Direction', 'Une', 'active', 'male');

update public.households set primary_guardian_id = 'f0700000-0000-0000-0000-000000000001'
 where id = 'f070ffff-0000-0000-0000-000000000001';
update public.households set primary_guardian_id = 'f0700000-0000-0000-0000-000000000003'
 where id = 'f070ffff-0000-0000-0000-000000000002';
update public.households set primary_guardian_id = 'f0700000-0000-0000-0000-000000000005'
 where id = 'f070ffff-0000-0000-0000-000000000003';

insert into public.student_profiles (profile_id, student_type, interface_mode, avatar_storage_key) values
  ('f0700000-0000-0000-0000-000000000002', 'minor', 'child', 'f0700000-0000-0000-0000-000000000002/hakim.jpg'),
  ('f0700000-0000-0000-0000-000000000004', 'minor', 'child', null),
  ('f0700000-0000-0000-0000-000000000006', 'minor', 'child', null),
  ('f0700000-0000-0000-0000-000000000007', 'autonomous', 'standard', null);

insert into public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values
  ('f0700000-0000-0000-0000-000000000008', array['francais'], 10, 'approved', 'Europe/Paris'),
  ('f0700000-0000-0000-0000-000000000009', array['francais'], 10, 'approved', 'Europe/Paris');

-- La Classe active : Hakim, Camil et Adam, chez l'enseignant Un.
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('f070ffff-0000-0000-0000-00000000000c', 'f0700000-0000-0000-0000-000000000008',
        'enfant', 6, 'PH Classe', 1, 10);
insert into public.groupe_membres (groupe_id, student_id) values
  ('f070ffff-0000-0000-0000-00000000000c', 'f0700000-0000-0000-0000-000000000002'),
  ('f070ffff-0000-0000-0000-00000000000c', 'f0700000-0000-0000-0000-000000000004'),
  ('f070ffff-0000-0000-0000-00000000000c', 'f0700000-0000-0000-0000-000000000007');

-- Le fichier de la photo de Hakim, deja dans le seau.
insert into storage.objects (bucket_id, name) values
  ('avatars', 'f0700000-0000-0000-0000-000000000002/hakim.jpg');

-- Un appelant : son id et son role, comme le jeton d'un client.
-- Le jeton porte aussi le foyer (`app_household_id`), comme en production.
create function pg_temp.etre(p_id uuid, p_role text) returns void language sql
security definer as $$
  select set_config('test.uid', p_id::text, true),
         set_config('test.jwt', pg_catalog.json_build_object('app_metadata',
           pg_catalog.json_build_object('role', p_role, 'household_id',
             (select household_id from public.profiles where id = p_id)))::text, true);
$$;
-- Combien de photos de [p_ids] l'appelant voit par photos_personnes.
create function pg_temp.vues(p_ids uuid[]) returns integer language sql as $$
  select count(*)::int from public.photos_personnes(p_ids) where cle is not null;
$$;
-- Combien de fichiers de photo de Hakim l'appelant lit dans le seau.
create function pg_temp.fichier_hakim() returns integer language sql as $$
  select count(*)::int from storage.objects
   where bucket_id = 'avatars' and name = 'f0700000-0000-0000-0000-000000000002/hakim.jpg';
$$;
grant execute on function pg_temp.etre(uuid, text), pg_temp.vues(uuid[]),
  pg_temp.fichier_hakim() to authenticated;

set local role authenticated;

-- ===========================================================================
-- 1. Le camarade voit Hakim ; le parent du camarade non ; une autre famille non
-- ===========================================================================
do $camarade$
declare
  v_hakim uuid[] := array['f0700000-0000-0000-0000-000000000002'::uuid];
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000004', 'student');
  if pg_temp.vues(v_hakim) <> 1 or pg_temp.fichier_hakim() <> 1 then
    raise exception 'PH1: le camarade Camil ne voit pas Hakim';
  end if;
  -- K-44 stricte : le parent du camarade ne voit pas la photo, ni par la
  -- fonction, ni dans le seau.
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000003', 'guardian');
  if pg_temp.vues(v_hakim) <> 0 or pg_temp.fichier_hakim() <> 0 then
    raise exception 'PH1: le parent du camarade voit Hakim';
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000005', 'guardian');
  if pg_temp.vues(v_hakim) <> 0 or pg_temp.fichier_hakim() <> 0 then
    raise exception 'PH1: une autre famille voit Hakim';
  end if;
end
$camarade$;

-- ===========================================================================
-- 6. Un mineur d'une autre famille, hors de la Classe, ne voit rien
-- ===========================================================================
do $hors_classe$
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000006', 'student');
  if pg_temp.vues(array['f0700000-0000-0000-0000-000000000002'::uuid]) <> 0
     or pg_temp.fichier_hakim() <> 0 then
    raise exception 'PH6: Omar, hors de la Classe, voit Hakim';
  end if;
  if exists (select 1 from public.photos_personnes(array[
               'f0700000-0000-0000-0000-000000000002'::uuid,
               'f0700000-0000-0000-0000-000000000004'::uuid,
               'f0700000-0000-0000-0000-000000000001'::uuid])) then
    raise exception 'PH6: Omar recoit une ligne pour un enfant ou un adulte d''une autre famille';
  end if;
end
$hors_classe$;

-- ===========================================================================
-- 2. L'enseignant voit ses eleves ; un autre enseignant non
-- ===========================================================================
do $enseignant$
declare
  v_hakim uuid[] := array['f0700000-0000-0000-0000-000000000002'::uuid];
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000008', 'teacher');
  if pg_temp.vues(v_hakim) <> 1 or pg_temp.fichier_hakim() <> 1 then
    raise exception 'PH2: l''enseignant ne voit pas son eleve';
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000009', 'teacher');
  if pg_temp.vues(v_hakim) <> 0 or pg_temp.fichier_hakim() <> 0 then
    raise exception 'PH2: un autre enseignant voit Hakim';
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-00000000000a', 'admin');
  if pg_temp.vues(v_hakim) <> 1 or pg_temp.fichier_hakim() <> 1 then
    raise exception 'PH2: la direction ne voit pas Hakim';
  end if;
end
$enseignant$;

-- ===========================================================================
-- 3. L'eleve adulte pose la sienne, dans son dossier et sa colonne
-- ===========================================================================
do $eleve_adulte$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000007', 'student');
  insert into storage.objects (bucket_id, name)
  values ('avatars', 'f0700000-0000-0000-0000-000000000007/moi.jpg');
  select * into v_ligne from public.poser_ma_photo('f0700000-0000-0000-0000-000000000007/moi.jpg');
  if v_ligne.seau <> 'avatars' or v_ligne.cle <> 'f0700000-0000-0000-0000-000000000007/moi.jpg' then
    raise exception 'PH3: l''eleve adulte n''a pas pose sa photo : %', v_ligne;
  end if;
  begin
    insert into storage.objects (bucket_id, name)
    values ('avatars', 'f0700000-0000-0000-0000-000000000002/pirate.jpg');
    raise exception 'PH3: l''eleve adulte ecrit dans le dossier d''un autre';
  exception when insufficient_privilege then null;
  end;
end
$eleve_adulte$;

-- ===========================================================================
-- 4. Le tuteur pose celle de son enfant, jamais celle d'un autre foyer
-- ===========================================================================
do $tuteur$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000005', 'guardian');
  begin
    perform public.poser_photo_eleve('f0700000-0000-0000-0000-000000000002',
      'f0700000-0000-0000-0000-000000000002/pirate.jpg');
    raise exception 'PH4: un tuteur a pose la photo d''un enfant d''un autre foyer';
  exception when raise_exception then
    if sqlerrm <> 'enfant introuvable dans votre foyer' then raise; end if;
  end;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000001', 'guardian');
  select * into v_ligne from public.poser_photo_eleve('f0700000-0000-0000-0000-000000000002',
    'f0700000-0000-0000-0000-000000000002/hakim2.jpg');
  if v_ligne.cle <> 'f0700000-0000-0000-0000-000000000002/hakim2.jpg' then
    raise exception 'PH4: le tuteur n''a pas pose la photo de son enfant';
  end if;
  begin
    perform public.poser_photo_eleve('f0700000-0000-0000-0000-000000000002',
      'f0700000-0000-0000-0000-000000000001/pas-son-dossier.jpg');
    raise exception 'PH4: cle hors du dossier de l''enfant acceptee';
  exception when raise_exception then
    if sqlerrm <> 'cle de photo invalide' then raise; end if;
  end;
end
$tuteur$;

-- ===========================================================================
-- 5. L'enfant en Interface guidee ne pose rien
-- ===========================================================================
do $enfant$
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000002', 'student');
  begin
    perform public.poser_ma_photo('f0700000-0000-0000-0000-000000000002/moi.jpg');
    raise exception 'PH5: l''enfant a pose sa photo';
  exception when raise_exception then
    if sqlerrm <> 'un eleve mineur ne pose pas de photo' then raise; end if;
  end;
  begin
    perform public.poser_photo_eleve('f0700000-0000-0000-0000-000000000002',
      'f0700000-0000-0000-0000-000000000002/moi.jpg');
    raise exception 'PH5: l''enfant a pose une photo d''eleve';
  exception when raise_exception then
    if sqlerrm <> 'photo d''un enfant reservee a son tuteur' then raise; end if;
  end;
  begin
    insert into storage.objects (bucket_id, name)
    values ('avatars', 'f0700000-0000-0000-0000-000000000002/moi.jpg');
    raise exception 'PH5: l''enfant ecrit dans le seau';
  exception when insufficient_privilege then null;
  end;
end
$enfant$;

-- ===========================================================================
-- 7. Le tuteur pose la sienne (colonne nouvelle) ; qui la voit
-- ===========================================================================
do $photo_tuteur$
declare
  v_tuteur uuid[] := array['f0700000-0000-0000-0000-000000000001'::uuid];
  v_ligne record;
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000001', 'guardian');
  insert into storage.objects (bucket_id, name)
  values ('avatars', 'f0700000-0000-0000-0000-000000000001/moi.jpg');
  select * into v_ligne from public.poser_ma_photo('f0700000-0000-0000-0000-000000000001/moi.jpg');
  if v_ligne.seau <> 'avatars' then
    raise exception 'PH7: seau du tuteur faux : %', v_ligne;
  end if;
  -- Une cle hors de son dossier, ou qui remonte, est refusee.
  begin
    perform public.poser_ma_photo('f0700000-0000-0000-0000-000000000002/hakim.jpg');
    raise exception 'PH7: cle dans le dossier d''un autre acceptee';
  exception when raise_exception then
    if sqlerrm <> 'cle de photo invalide' then raise; end if;
  end;
  begin
    perform public.poser_ma_photo('f0700000-0000-0000-0000-000000000001/../x.jpg');
    raise exception 'PH7: cle qui remonte acceptee';
  exception when raise_exception then
    if sqlerrm <> 'cle de photo invalide' then raise; end if;
  end;
  -- L'ecriture directe de la colonne est refusee : seule la fonction pose.
  begin
    update public.profiles set photo_storage_key = 'f0700000-0000-0000-0000-000000000001/x.jpg'
     where id = 'f0700000-0000-0000-0000-000000000001';
    raise exception 'PH7: la colonne s''ecrit directement';
  exception when insufficient_privilege then null;
  end;

  -- L'enseignant de son enfant la voit ; le foyer d'un camarade et une
  -- autre famille non.
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000008', 'teacher');
  if pg_temp.vues(v_tuteur) <> 1 then
    raise exception 'PH7: l''enseignant de l''enfant ne voit pas le tuteur';
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000003', 'guardian');
  if pg_temp.vues(v_tuteur) <> 0 then
    raise exception 'PH7: le foyer d''un camarade voit le tuteur';
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000005', 'guardian');
  if pg_temp.vues(v_tuteur) <> 0 then
    raise exception 'PH7: une autre famille voit le tuteur';
  end if;
  -- L'enfant du foyer voit son tuteur.
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000002', 'student');
  if pg_temp.vues(v_tuteur) <> 1 then
    raise exception 'PH7: l''enfant ne voit pas son tuteur';
  end if;
end
$photo_tuteur$;

-- ===========================================================================
-- 8. La direction et l'enseignant posent la leur ; qui les voit
-- ===========================================================================
do $direction_enseignant$
declare
  v_ligne record;
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-00000000000a', 'admin');
  perform public.poser_ma_photo('f0700000-0000-0000-0000-00000000000a/moi.jpg');
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000005', 'guardian');
  if pg_temp.vues(array['f0700000-0000-0000-0000-00000000000a'::uuid]) <> 1 then
    raise exception 'PH8: un compte connecte ne voit pas la direction';
  end if;

  perform pg_temp.etre('f0700000-0000-0000-0000-000000000008', 'teacher');
  select * into v_ligne from public.poser_ma_photo('f0700000-0000-0000-0000-000000000008/moi.jpg');
  if v_ligne.seau <> 'photos_enseignants' then
    raise exception 'PH8: la photo de l''enseignant n''est pas dans son seau : %', v_ligne;
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000001', 'guardian');
  if pg_temp.vues(array['f0700000-0000-0000-0000-000000000008'::uuid]) <> 1 then
    raise exception 'PH8: le foyer d''un eleve ne voit pas l''enseignant';
  end if;
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000005', 'guardian');
  if pg_temp.vues(array['f0700000-0000-0000-0000-000000000008'::uuid]) <> 0 then
    raise exception 'PH8: une autre famille voit l''enseignant';
  end if;
end
$direction_enseignant$;

-- ===========================================================================
-- 9. Les sources, une par personne, et l'anonymisation
-- ===========================================================================
reset role;
do $sources$
begin
  if (select avatar_storage_key from public.student_profiles
       where profile_id = 'f0700000-0000-0000-0000-000000000007')
     is distinct from 'f0700000-0000-0000-0000-000000000007/moi.jpg'
     or (select photo_storage_key from public.profiles
          where id = 'f0700000-0000-0000-0000-000000000007') is not null then
    raise exception 'PH9: la photo de l''eleve adulte n''est pas dans sa seule colonne';
  end if;
  if (select photo_storage_key from public.teacher_profiles
       where profile_id = 'f0700000-0000-0000-0000-000000000008')
     is distinct from 'f0700000-0000-0000-0000-000000000008/moi.jpg'
     or (select photo_storage_key from public.profiles
          where id = 'f0700000-0000-0000-0000-000000000008') is not null then
    raise exception 'PH9: la photo de l''enseignant n''est pas dans sa seule colonne';
  end if;

  -- L'anonymisation efface la photo de la colonne nouvelle.
  update public.profiles
     set first_name = 'Compte', last_name = 'supprimé', account_status = 'disabled'
   where id = 'f0700000-0000-0000-0000-000000000001';
  if (select photo_storage_key from public.profiles
       where id = 'f0700000-0000-0000-0000-000000000001') is not null then
    raise exception 'PH9: la photo reste apres l''anonymisation';
  end if;

  -- Les fonctions privees ne sont pas appelables par un client.
  if pg_catalog.has_function_privilege('authenticated',
       'private.photo_visible_par(uuid,uuid)', 'EXECUTE')
     or pg_catalog.has_function_privilege('anon', 'public.photos_personnes(uuid[])', 'EXECUTE') then
    raise exception 'PH9: droits trop larges';
  end if;
end
$sources$;

-- ===========================================================================
-- 10. PHOTOS-2a (20261107400000) : la photo d'un eleve ne s'ecrit plus en
--     direct ; les deux reglages du foyer, si
-- ===========================================================================
set local role authenticated;
do $direct$
declare
  v_n integer;
begin
  perform pg_temp.etre('f0700000-0000-0000-0000-000000000003', 'guardian');
  begin
    update public.student_profiles
       set avatar_storage_key = 'f0700000-0000-0000-0000-000000000004/direct.jpg'
     where profile_id = 'f0700000-0000-0000-0000-000000000004';
    raise exception 'PH10: un tuteur a ecrit la cle de photo en direct';
  exception when insufficient_privilege then
    null;
  end;
  update public.student_profiles
     set interface_mode = interface_mode
   where profile_id = 'f0700000-0000-0000-0000-000000000004';
  get diagnostics v_n = row_count;
  if v_n <> 1 then
    raise exception 'PH10: le tuteur ne regle plus l''interface de son enfant';
  end if;
end
$direct$;
reset role;

rollback;
