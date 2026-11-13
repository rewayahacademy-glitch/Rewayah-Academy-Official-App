-- CAMARADES (directeur, 12/11/2026) : les eleves d'une Classe se voient par
-- leur photo et leur prenom.
-- supabase/migrations/20261124300000_camarades_prenoms.sql.
--
--   CP1  un eleve mineur lit le prenom des membres actifs de sa Classe, lui
--        compris (`est_moi`), et seulement eux : ni le compte desactive, ni
--        l'eleve retire ;
--   CP2  la reponse n'a que trois colonnes (profile_id, prenom, est_moi) :
--        ni nom de famille, ni matricule, ni photo, ni foyer, ni age ;
--   CP3  un eleve adulte autonome lit aussi sa Classe ;
--   CP4  un eleve d'une AUTRE Classe ne lit rien de celle-ci ;
--   CP5  un eleve retire, et un eleve d'une Classe close, ne lisent rien ;
--   CP6  un tuteur qui n'apprend pas, un enseignant, la direction, un eleve
--        au compte desactive sont refuses (42501) ; anon n'a pas EXECUTE.
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les
-- migrations. Tout est annule a la fin. Un echec leve 'CP ROUGE : ...'.

begin;

insert into auth.users (id, email) values
  ('cb000000-0000-4000-8000-000000000001', 'cp-ens@example.test'),
  ('cb000000-0000-4000-8000-000000000002', 'cp-admin@example.test'),
  ('cb000000-0000-4000-8000-0000000000a1', 'cp-a1@example.test'),
  ('cb000000-0000-4000-8000-0000000000c1', 'cp-c1@example.test'),
  ('cb000000-0000-4000-8000-0000000000c2', 'cp-c2@example.test'),
  ('cb000000-0000-4000-8000-0000000000c3', 'cp-c3@example.test'),
  ('cb000000-0000-4000-8000-0000000000c4', 'cp-c4@example.test'),
  ('cb000000-0000-4000-8000-0000000000c5', 'cp-c5@example.test'),
  ('cb000000-0000-4000-8000-0000000000c6', 'cp-c6@example.test'),
  ('cb000000-0000-4000-8000-0000000000d1', 'cp-d1@example.test');

insert into public.households (id, timezone) values
  ('cb00ffff-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('cb00ffff-0000-4000-8000-000000000002', 'Europe/Paris'),
  ('cb00ffff-0000-4000-8000-000000000003', 'Europe/Paris');

-- Classe K (enfants, active) : c1, c2, c3 (desactive), c4 (retire).
-- Classe L (enfants, active) : c5. Classe M (enfants, close) : c6.
-- Classe A (adultes, active) : a1. d1 : tuteur de c1, n'apprend pas.
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('cb000000-0000-4000-8000-000000000001', 'TEACH-CP-000001', 'teacher',
   null, 'Hakim', 'Enseignant', 'provisional_active', 'male'),
  ('cb000000-0000-4000-8000-000000000002', 'ADMIN-CP-000002', 'admin',
   null, 'Direction', 'Test', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000a1', 'GUARD-CP-0000A1', 'guardian',
   'cb00ffff-0000-4000-8000-000000000002', 'Karim', 'Adulte', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000c1', 'STUD-CP-0000C1', 'student',
   'cb00ffff-0000-4000-8000-000000000001', 'Yanis', 'Famillun', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000c2', 'STUD-CP-0000C2', 'student',
   'cb00ffff-0000-4000-8000-000000000003', 'Ilyes', 'Famildeux', 'provisional_active', 'male'),
  ('cb000000-0000-4000-8000-0000000000c3', 'STUD-CP-0000C3', 'student',
   'cb00ffff-0000-4000-8000-000000000003', 'Adam', 'Famildeux', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000c4', 'STUD-CP-0000C4', 'student',
   'cb00ffff-0000-4000-8000-000000000003', 'Sami', 'Famildeux', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000c5', 'STUD-CP-0000C5', 'student',
   'cb00ffff-0000-4000-8000-000000000003', 'Nael', 'Famildeux', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000c6', 'STUD-CP-0000C6', 'student',
   'cb00ffff-0000-4000-8000-000000000003', 'Rayan', 'Famildeux', 'active', 'male'),
  ('cb000000-0000-4000-8000-0000000000d1', 'GUARD-CP-0000D1', 'guardian',
   'cb00ffff-0000-4000-8000-000000000001', 'Nadia', 'Famillun', 'active', 'female');

insert into public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy, avatar_storage_key)
values
  ('cb000000-0000-4000-8000-0000000000a1', 'autonomous', 'standard', 'allowed', 'avatars/a1.jpg'),
  ('cb000000-0000-4000-8000-0000000000c1', 'minor', 'child', 'forbidden', 'avatars/c1.jpg'),
  ('cb000000-0000-4000-8000-0000000000c2', 'minor', 'child', 'forbidden', 'avatars/c2.jpg'),
  ('cb000000-0000-4000-8000-0000000000c3', 'minor', 'standard', 'forbidden', null),
  ('cb000000-0000-4000-8000-0000000000c4', 'minor', 'standard', 'forbidden', null),
  ('cb000000-0000-4000-8000-0000000000c5', 'minor', 'standard', 'forbidden', null),
  ('cb000000-0000-4000-8000-0000000000c6', 'minor', 'standard', 'forbidden', null);

insert into public.teacher_profiles (profile_id, kyc_status) values
  ('cb000000-0000-4000-8000-000000000001', 'approved');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
values
  ('cb00c000-0000-4000-8000-00000000000a', 'cb000000-0000-4000-8000-000000000001',
   'adulte', 6, 'CP Classe A', 1, 7, 'Europe/Paris'),
  ('cb00c000-0000-4000-8000-00000000000b', 'cb000000-0000-4000-8000-000000000001',
   'enfant', 6, 'CP Classe K', 2, 7, 'Europe/Paris'),
  ('cb00c000-0000-4000-8000-00000000000c', 'cb000000-0000-4000-8000-000000000001',
   'enfant', 6, 'CP Classe L', 3, 7, 'Europe/Paris'),
  ('cb00c000-0000-4000-8000-00000000000d', 'cb000000-0000-4000-8000-000000000001',
   'enfant', 6, 'CP Classe M', 4, 7, 'Europe/Paris');

insert into public.groupe_membres (groupe_id, student_id) values
  ('cb00c000-0000-4000-8000-00000000000a', 'cb000000-0000-4000-8000-0000000000a1'),
  ('cb00c000-0000-4000-8000-00000000000b', 'cb000000-0000-4000-8000-0000000000c1'),
  ('cb00c000-0000-4000-8000-00000000000b', 'cb000000-0000-4000-8000-0000000000c2'),
  ('cb00c000-0000-4000-8000-00000000000b', 'cb000000-0000-4000-8000-0000000000c3'),
  ('cb00c000-0000-4000-8000-00000000000b', 'cb000000-0000-4000-8000-0000000000c4'),
  ('cb00c000-0000-4000-8000-00000000000c', 'cb000000-0000-4000-8000-0000000000c5'),
  ('cb00c000-0000-4000-8000-00000000000d', 'cb000000-0000-4000-8000-0000000000c6');

-- c4 quitte la Classe K ; la Classe M est close ; c3 est desactive.
update public.groupe_membres
   set left_at = now(), left_by = 'cb000000-0000-4000-8000-000000000002',
       left_reason = 'scenario : retire'
 where groupe_id = 'cb00c000-0000-4000-8000-00000000000b'
   and student_id = 'cb000000-0000-4000-8000-0000000000c4';
update public.groupes
   set ended_at = now(), ended_by = 'cb000000-0000-4000-8000-000000000002',
       end_reason = 'scenario : Classe close'
 where id = 'cb00c000-0000-4000-8000-00000000000d';
update public.profiles set account_status = 'disabled'
 where id = 'cb000000-0000-4000-8000-0000000000c3';

-- Se faire passer pour un compte : son identifiant et son jeton.
create function pg_temp.en_tant_que(p_uid uuid, p_role text, p_foyer uuid)
returns void language sql as $$
  select set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('request.jwt.claims', pg_catalog.jsonb_build_object(
           'sub', p_uid, 'app_metadata', pg_catalog.jsonb_build_object(
             'role', p_role, 'household_id', p_foyer))::text, true),
         set_config('test.uid', p_uid::text, true),
         set_config('test.jwt', pg_catalog.jsonb_build_object(
           'sub', p_uid, 'app_metadata', pg_catalog.jsonb_build_object(
             'role', p_role, 'household_id', p_foyer))::text, true);
$$;
grant execute on function pg_temp.en_tant_que(uuid, text, uuid) to authenticated;

set local role authenticated;

-- CP1 et CP2 : c1, enfant de la Classe K (session de l'appareil jumele :
-- son propre profil, role student).
select pg_temp.en_tant_que('cb000000-0000-4000-8000-0000000000c1', 'student',
                           'cb00ffff-0000-4000-8000-000000000001');
do $$
declare
  v_prenoms text[];
  v_moi uuid;
  v_colonnes text[];
begin
  select pg_catalog.array_agg(c.prenom order by c.est_moi desc, c.prenom)
    into v_prenoms from public.camarades_classe_eleve() c;
  if v_prenoms is distinct from array['Yanis', 'Ilyes'] then
    raise exception 'CP ROUGE CP1 : prenoms lus %', v_prenoms;
  end if;
  select c.profile_id into v_moi from public.camarades_classe_eleve() c where c.est_moi;
  if v_moi is distinct from 'cb000000-0000-4000-8000-0000000000c1' then
    raise exception 'CP ROUGE CP1 : est_moi mal pose (%)', v_moi;
  end if;
  if exists (select 1 from public.camarades_classe_eleve() c
              where c.prenom like '%Famil%' or c.prenom in ('Adam', 'Sami')) then
    raise exception 'CP ROUGE CP1 : nom de famille, desactive ou retire lu';
  end if;
  raise notice 'CP OK CP1 : l''enfant lit le prenom des membres actifs de sa Classe';

  select pg_catalog.array_agg(x.a order by x.n)
    into v_colonnes
    from pg_catalog.pg_proc p,
         unnest(p.proargnames, p.proargmodes::text[]) with ordinality as x(a, m, n)
   where p.oid = 'public.camarades_classe_eleve()'::pg_catalog.regprocedure
     and x.m = 't';
  if v_colonnes is distinct from array['profile_id', 'prenom', 'est_moi'] then
    raise exception 'CP ROUGE CP2 : colonnes rendues %', v_colonnes;
  end if;
  raise notice 'CP OK CP2 : trois colonnes, ni nom, ni matricule, ni photo, ni foyer';
end $$;

-- CP3 : a1, adulte autonome de la Classe A.
select pg_temp.en_tant_que('cb000000-0000-4000-8000-0000000000a1', 'guardian',
                           'cb00ffff-0000-4000-8000-000000000002');
do $$
begin
  if (select pg_catalog.array_agg(c.prenom) from public.camarades_classe_eleve() c)
     is distinct from array['Karim'] then
    raise exception 'CP ROUGE CP3 : l''adulte ne lit pas sa Classe';
  end if;
  raise notice 'CP OK CP3 : l''eleve adulte lit sa Classe';
end $$;

-- CP4 : c5, eleve de la Classe L, ne lit rien de la Classe K.
select pg_temp.en_tant_que('cb000000-0000-4000-8000-0000000000c5', 'student',
                           'cb00ffff-0000-4000-8000-000000000003');
do $$
begin
  if exists (select 1 from public.camarades_classe_eleve() c
              where c.prenom in ('Yanis', 'Ilyes', 'Karim')) then
    raise exception 'CP ROUGE CP4 : un eleve lit une autre Classe';
  end if;
  if (select pg_catalog.array_agg(c.prenom) from public.camarades_classe_eleve() c)
     is distinct from array['Nael'] then
    raise exception 'CP ROUGE CP4 : sa propre Classe mal lue';
  end if;
  raise notice 'CP OK CP4 : un eleve d''une autre Classe ne lit que la sienne';
end $$;

-- CP5 : c4 (retire de K) et c6 (Classe M close) ne lisent rien.
do $$
declare
  v_uid uuid;
begin
  foreach v_uid in array array['cb000000-0000-4000-8000-0000000000c4',
                               'cb000000-0000-4000-8000-0000000000c6']::uuid[] loop
    perform pg_temp.en_tant_que(v_uid, 'student', 'cb00ffff-0000-4000-8000-000000000003');
    if exists (select 1 from public.camarades_classe_eleve()) then
      raise exception 'CP ROUGE CP5 : % lit une Classe quittee ou close', v_uid;
    end if;
  end loop;
  raise notice 'CP OK CP5 : eleve retire et Classe close : aucune ligne';
end $$;

-- CP6 : tuteur sans profil d'eleve, enseignant, direction, eleve desactive
-- sont refuses ; anon n'a pas EXECUTE.
do $$
declare
  v_qui record;
  v_refuse boolean;
begin
  for v_qui in
    select * from (values
      ('cb000000-0000-4000-8000-0000000000d1'::uuid, 'guardian', 'cb00ffff-0000-4000-8000-000000000001'::uuid),
      ('cb000000-0000-4000-8000-000000000001'::uuid, 'teacher', null::uuid),
      ('cb000000-0000-4000-8000-000000000002'::uuid, 'admin', null::uuid),
      ('cb000000-0000-4000-8000-0000000000c3'::uuid, 'student', 'cb00ffff-0000-4000-8000-000000000003'::uuid)
    ) as t(uid, role, foyer)
  loop
    perform pg_temp.en_tant_que(v_qui.uid, v_qui.role, v_qui.foyer);
    v_refuse := false;
    begin
      perform 1 from public.camarades_classe_eleve();
    exception when insufficient_privilege then
      v_refuse := true;
    end;
    if not v_refuse then
      raise exception 'CP ROUGE CP6 : % (%) n''est pas refuse', v_qui.uid, v_qui.role;
    end if;
  end loop;
  if pg_catalog.has_function_privilege('anon', 'public.camarades_classe_eleve()', 'EXECUTE')
     or pg_catalog.has_function_privilege('public', 'public.camarades_classe_eleve()', 'EXECUTE') then
    raise exception 'CP ROUGE CP6 : anon ou public a EXECUTE';
  end if;
  raise notice 'CP OK CP6 : tuteur, enseignant, direction, desactive refuses ; anon sans EXECUTE';
end $$;

reset role;
rollback;

select 'scenarios_camarades_prenoms : 6 controles verts' as resultat;
