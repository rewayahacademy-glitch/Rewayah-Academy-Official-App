-- SECU-ANON (07/11/2026) : `anon` n'execute plus groupes_admin(),
-- personnes_observables() ni profil_de_mon_foyer(text) ; un administrateur et un
-- tuteur obtiennent le meme resultat qu'avant.
-- A rejouer sur un Postgres nu : stub_auth.sql, toutes les migrations, puis ce
-- fichier. Tout est annule en fin de script.
begin;

insert into auth.users (id, email) values
  ('5e000000-0000-4000-8000-000000000001', 'secu-admin@example.test'),
  ('5e000000-0000-4000-8000-000000000002', 'secu-tuteur@example.test'),
  ('5e000000-0000-4000-8000-000000000003', 'secu-enfant@example.test'),
  ('5e000000-0000-4000-8000-000000000004', 'secu-ens@example.test'),
  ('5e000000-0000-4000-8000-000000000005', 'secu-autre@example.test');

insert into public.households (id) values
  ('5e000000-0000-4000-8000-0000000000f1'),
  ('5e000000-0000-4000-8000-0000000000f2');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('5e000000-0000-4000-8000-000000000001', 'SECUADMIN0000001', 'admin', null,
   'Fixture', 'Direction', 'active', 'female'),
  ('5e000000-0000-4000-8000-000000000002', 'SECUTUTEUR000001', 'guardian',
   '5e000000-0000-4000-8000-0000000000f1', 'Amina', 'Tuteur', 'active', 'female'),
  ('5e000000-0000-4000-8000-000000000003', 'SECUENFANT000001', 'student',
   '5e000000-0000-4000-8000-0000000000f1', 'Yasmine', 'Enfant', 'active', 'female'),
  ('5e000000-0000-4000-8000-000000000004', 'SECUENSEIGN0001', 'teacher', null,
   'Fixture', 'Enseignant', 'pending_kyc', 'female'),
  ('5e000000-0000-4000-8000-000000000005', 'SECUAUTRE000001', 'student',
   '5e000000-0000-4000-8000-0000000000f2', 'Autre', 'Foyer', 'active', 'female');

update public.households set primary_guardian_id = '5e000000-0000-4000-8000-000000000002'
 where id = '5e000000-0000-4000-8000-0000000000f1';
insert into public.student_profiles (profile_id, student_type) values
  ('5e000000-0000-4000-8000-000000000003', 'minor'),
  ('5e000000-0000-4000-8000-000000000005', 'minor');
insert into public.teacher_profiles (profile_id, country) values
  ('5e000000-0000-4000-8000-000000000004', 'MA');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('5e000000-0000-4000-8000-0000000000c1', '5e000000-0000-4000-8000-000000000004',
        'enfant', 5, 'Classe secu-anon', 2, 18);

-- Resultats observes, gardes pour les comparaisons.
create temp table secu_res (cle text primary key, valeur text);
grant all on secu_res to anon, authenticated;

-- 1. Droits d'execution : ni anon ni PUBLIC ; authenticated garde le sien.
do $$
declare
  v_sig text;
begin
  foreach v_sig in array array['public.groupes_admin()', 'public.personnes_observables()',
                               'public.profil_de_mon_foyer(text)'] loop
    if pg_catalog.has_function_privilege('anon', v_sig, 'EXECUTE') then
      raise exception 'SECU-ANON 1 : anon execute encore %', v_sig;
    end if;
    if not pg_catalog.has_function_privilege('authenticated', v_sig, 'EXECUTE') then
      raise exception 'SECU-ANON 1 : authenticated a perdu %', v_sig;
    end if;
    if exists (
      select 1 from pg_catalog.pg_proc p, pg_catalog.aclexplode(p.proacl) a
       where p.oid = pg_catalog.to_regprocedure(v_sig) and a.grantee = 0
    ) then
      raise exception 'SECU-ANON 1 : PUBLIC garde EXECUTE sur %', v_sig;
    end if;
  end loop;
  raise notice 'SECU-ANON 1 ok : droits d''execution';
end $$;

-- 2. anon est refuse (42501, permission denied), pour chacune des trois.
do $$
declare
  v_sql text;
  v_state text;
begin
  perform pg_catalog.set_config('test.jwt', '{}', true);
  perform pg_catalog.set_config('request.jwt.claims', '{}', true);
  set local role anon;
  foreach v_sql in array array[
    'select count(*) from public.groupes_admin()',
    'select count(*) from public.personnes_observables()',
    'select public.profil_de_mon_foyer(''5e000000-0000-4000-8000-000000000003'')'
  ] loop
    v_state := null;
    begin
      execute v_sql;
    exception when others then
      v_state := sqlstate;
    end;
    if v_state is distinct from '42501' then
      reset role;
      raise exception 'SECU-ANON 2 : anon n''est pas refuse (%) pour %', coalesce(v_state, 'aucune erreur'), v_sql;
    end if;
  end loop;
  reset role;
  raise notice 'SECU-ANON 2 ok : anon refuse (3/3)';
end $$;

-- 3. L'administrateur obtient ce qu'il obtenait.
select pg_catalog.set_config('test.uid', '5e000000-0000-4000-8000-000000000001', true);
select pg_catalog.set_config('test.jwt',
  '{"sub":"5e000000-0000-4000-8000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}', true);
select pg_catalog.set_config('request.jwt.claims', current_setting('test.jwt'), true);
set local role authenticated;
insert into secu_res
select 'admin_groupes', count(*)::text from public.groupes_admin()
 where groupe_id = '5e000000-0000-4000-8000-0000000000c1' and libelle = 'Classe secu-anon';
insert into secu_res
select 'admin_personnes', count(*)::text from public.personnes_observables()
 where id::text like '5e000000-%';
insert into secu_res
select 'admin_foyer', public.profil_de_mon_foyer('5e000000-0000-4000-8000-000000000003')::text;
reset role;

-- 4. Le tuteur obtient ce qu'il obtenait : rien d'administratif, mais son enfant.
select pg_catalog.set_config('test.uid', '5e000000-0000-4000-8000-000000000002', true);
select pg_catalog.set_config('test.jwt',
  '{"sub":"5e000000-0000-4000-8000-000000000002","role":"authenticated","app_metadata":{"role":"guardian","household_id":"5e000000-0000-4000-8000-0000000000f1"}}', true);
select pg_catalog.set_config('request.jwt.claims', current_setting('test.jwt'), true);
set local role authenticated;
insert into secu_res
select 'tuteur_groupes', count(*)::text from public.groupes_admin();
insert into secu_res
select 'tuteur_personnes', count(*)::text from public.personnes_observables();
insert into secu_res
select 'tuteur_son_enfant', public.profil_de_mon_foyer('5e000000-0000-4000-8000-000000000003')::text;
insert into secu_res
select 'tuteur_autre_foyer', public.profil_de_mon_foyer('5e000000-0000-4000-8000-000000000005')::text;
insert into secu_res
select 'tuteur_texte_mal_forme', public.profil_de_mon_foyer('pas-un-uuid')::text;
reset role;

do $$
declare
  v_attendu constant jsonb := '{
    "admin_groupes": "1", "admin_personnes": "4", "admin_foyer": "false",
    "tuteur_groupes": "0", "tuteur_personnes": "0",
    "tuteur_son_enfant": "true", "tuteur_autre_foyer": "false",
    "tuteur_texte_mal_forme": "false"}';
  r record;
  v_n int := 0;
begin
  for r in select cle, valeur from secu_res order by cle loop
    raise notice 'SECU-ANON observe : % = %', r.cle, r.valeur;
    if v_attendu ->> r.cle is distinct from r.valeur then
      raise exception 'SECU-ANON 3/4 : % vaut %, attendu %', r.cle, r.valeur, v_attendu ->> r.cle;
    end if;
    v_n := v_n + 1;
  end loop;
  if v_n <> (select count(*) from pg_catalog.jsonb_object_keys(v_attendu)) then
    raise exception 'SECU-ANON 3/4 : % resultats, attendu %', v_n, (select count(*) from pg_catalog.jsonb_object_keys(v_attendu));
  end if;
  raise notice 'SECU-ANON 3/4 ok : admin et tuteur inchanges (% mesures)', v_n;
end $$;

rollback;
