-- Ecrans de l'eleve adulte (02/11/2026) :
-- supabase/migrations/20261102700000_eleve_adulte_lectures.sql.
--
--   EA1  l'adulte lit son prenom et SA Classe, jamais celle de son enfant ;
--   EA2  il lit son historique, le plus recent d'abord, avec son absence ;
--        ni seance future ni seance annulee ; pagination par `p_avant` ;
--        une seance remplacee rend l'enseignant qui a fait le cours (le
--        remplacant), jamais le titulaire absent ;
--   EA3  il ne lit ni les seances d'une autre Classe, ni celles de son
--        enfant, ni celles d'un autre adulte ;
--   EA4  il lit les prenoms de sa Classe, sa propre photo seule ;
--   EA5  un autre adulte, d'une autre Classe, ne lit que la sienne ;
--   EA6  un tuteur qui n'est pas eleve, un enfant, un compte desactive ne
--        lisent rien ; anon n'a pas EXECUTE ;
--   EA7  l'adulte sans Classe a une ligne, Classe nulle, et rien d'autre.
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les
-- migrations. Tout est annule a la fin. Un echec leve 'EA ROUGE : ...'.

begin;

insert into auth.users (id, email) values
  ('ea000000-0000-4000-8000-000000000001', 'ea-ens@example.test'),
  ('ea000000-0000-4000-8000-000000000002', 'ea-remplacant@example.test'),
  ('ea000000-0000-4000-8000-0000000000a1', 'ea-a1@example.test'),
  ('ea000000-0000-4000-8000-0000000000a2', 'ea-a2@example.test'),
  ('ea000000-0000-4000-8000-0000000000a3', 'ea-a3@example.test'),
  ('ea000000-0000-4000-8000-0000000000a4', 'ea-a4@example.test'),
  ('ea000000-0000-4000-8000-0000000000c1', 'ea-c1@example.test'),
  ('ea000000-0000-4000-8000-0000000000d1', 'ea-d1@example.test'),
  ('ea000000-0000-4000-8000-0000000000e1', 'ea-e1@example.test');

insert into public.households (id, timezone) values
  ('ea00ffff-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('ea00ffff-0000-4000-8000-000000000002', 'Europe/Paris'),
  ('ea00ffff-0000-4000-8000-000000000003', 'Europe/Paris'),
  ('ea00ffff-0000-4000-8000-000000000004', 'Europe/Paris');

-- a1 : adulte titulaire, Classe adulte A, parent de c1 (meme foyer).
-- a3 : adulte titulaire, meme Classe A. a2 : adulte titulaire, Classe B.
-- a4 : adulte titulaire sans Classe. c1 : enfant de a1, Classe enfant K.
-- d1 : tuteur qui n'apprend pas. e1 : adulte titulaire desactive, Classe A.
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('ea000000-0000-4000-8000-000000000001', 'TEACH-EA-000001', 'teacher',
   null, 'Hakim', 'Test', 'provisional_active', 'male'),
  ('ea000000-0000-4000-8000-000000000002', 'TEACH-EA-000002', 'teacher',
   null, 'Rachid', 'Test', 'provisional_active', 'male'),
  ('ea000000-0000-4000-8000-0000000000a1', 'GUARD-EA-0000A1', 'guardian',
   'ea00ffff-0000-4000-8000-000000000001', 'Karim', 'Test', 'active', 'male'),
  ('ea000000-0000-4000-8000-0000000000a2', 'GUARD-EA-0000A2', 'guardian',
   'ea00ffff-0000-4000-8000-000000000002', 'Malik', 'Test', 'active', 'male'),
  ('ea000000-0000-4000-8000-0000000000a3', 'GUARD-EA-0000A3', 'guardian',
   'ea00ffff-0000-4000-8000-000000000003', 'Bilal', 'Test', 'active', 'male'),
  ('ea000000-0000-4000-8000-0000000000a4', 'GUARD-EA-0000A4', 'guardian',
   'ea00ffff-0000-4000-8000-000000000004', 'Samir', 'Test', 'active', 'male'),
  ('ea000000-0000-4000-8000-0000000000c1', 'STUD-EA-0000C1', 'student',
   'ea00ffff-0000-4000-8000-000000000001', 'Yanis', 'Test', 'active', 'male'),
  ('ea000000-0000-4000-8000-0000000000d1', 'GUARD-EA-0000D1', 'guardian',
   'ea00ffff-0000-4000-8000-000000000002', 'Nadia', 'Test', 'active', 'female'),
  ('ea000000-0000-4000-8000-0000000000e1', 'GUARD-EA-0000E1', 'guardian',
   'ea00ffff-0000-4000-8000-000000000003', 'Omar', 'Test', 'active', 'male');

insert into public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy, avatar_storage_key)
values
  ('ea000000-0000-4000-8000-0000000000a1', 'autonomous', 'standard', 'allowed', 'avatars/a1.jpg'),
  ('ea000000-0000-4000-8000-0000000000a2', 'autonomous', 'standard', 'allowed', null),
  ('ea000000-0000-4000-8000-0000000000a3', 'autonomous', 'standard', 'allowed', 'avatars/a3.jpg'),
  ('ea000000-0000-4000-8000-0000000000a4', 'autonomous', 'standard', 'allowed', null),
  ('ea000000-0000-4000-8000-0000000000c1', 'minor', 'standard', 'forbidden', null),
  ('ea000000-0000-4000-8000-0000000000e1', 'autonomous', 'standard', 'allowed', null);

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
values
  ('ea00c000-0000-4000-8000-00000000000a', 'ea000000-0000-4000-8000-000000000001',
   'adulte', 6, 'EA Classe A', 1, 6, 'Europe/Paris'),
  ('ea00c000-0000-4000-8000-00000000000b', 'ea000000-0000-4000-8000-000000000001',
   'adulte', 6, 'EA Classe B', 2, 6, 'Europe/Paris'),
  ('ea00c000-0000-4000-8000-00000000000c', 'ea000000-0000-4000-8000-000000000001',
   'enfant', 6, 'EA Classe K', 3, 6, 'Europe/Paris');

insert into public.groupe_membres (groupe_id, student_id) values
  ('ea00c000-0000-4000-8000-00000000000a', 'ea000000-0000-4000-8000-0000000000a1'),
  ('ea00c000-0000-4000-8000-00000000000a', 'ea000000-0000-4000-8000-0000000000a3'),
  ('ea00c000-0000-4000-8000-00000000000a', 'ea000000-0000-4000-8000-0000000000e1'),
  ('ea00c000-0000-4000-8000-00000000000b', 'ea000000-0000-4000-8000-0000000000a2'),
  ('ea00c000-0000-4000-8000-00000000000c', 'ea000000-0000-4000-8000-0000000000c1');

-- Seances : s1 (A, il y a 3 jours, a1 present), s2 (A, il y a 2 jours, a1
-- absent), s3 (A, annulee), s4 (A, demain), s5 (B, a2), s6 (K, c1).
insert into public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
values
  ('ea00a000-0000-4000-8000-000000000001', 'ea000000-0000-4000-8000-000000000001',
   'ea00c000-0000-4000-8000-00000000000a', now() - interval '3 days', now() - interval '3 days' + interval '1 hour', 'planned'),
  ('ea00a000-0000-4000-8000-000000000002', 'ea000000-0000-4000-8000-000000000001',
   'ea00c000-0000-4000-8000-00000000000a', now() - interval '2 days', now() - interval '2 days' + interval '1 hour', 'planned'),
  ('ea00a000-0000-4000-8000-000000000003', 'ea000000-0000-4000-8000-000000000001',
   'ea00c000-0000-4000-8000-00000000000a', now() - interval '1 day', now() - interval '1 day' + interval '1 hour', 'canceled'),
  ('ea00a000-0000-4000-8000-000000000004', 'ea000000-0000-4000-8000-000000000001',
   'ea00c000-0000-4000-8000-00000000000a', now() + interval '1 day', now() + interval '1 day 1 hour', 'planned'),
  ('ea00a000-0000-4000-8000-000000000005', 'ea000000-0000-4000-8000-000000000001',
   'ea00c000-0000-4000-8000-00000000000b', now() - interval '4 days', now() - interval '4 days' + interval '1 hour', 'planned'),
  ('ea00a000-0000-4000-8000-000000000006', 'ea000000-0000-4000-8000-000000000001',
   'ea00c000-0000-4000-8000-00000000000c', now() - interval '5 days', now() - interval '5 days' + interval '1 hour', 'planned');

insert into public.session_participants (session_id, profile_id, role) values
  ('ea00a000-0000-4000-8000-000000000001', 'ea000000-0000-4000-8000-0000000000a1', 'student'),
  ('ea00a000-0000-4000-8000-000000000001', 'ea000000-0000-4000-8000-0000000000a3', 'student'),
  ('ea00a000-0000-4000-8000-000000000002', 'ea000000-0000-4000-8000-0000000000a1', 'student'),
  ('ea00a000-0000-4000-8000-000000000003', 'ea000000-0000-4000-8000-0000000000a1', 'student'),
  ('ea00a000-0000-4000-8000-000000000004', 'ea000000-0000-4000-8000-0000000000a1', 'student'),
  ('ea00a000-0000-4000-8000-000000000005', 'ea000000-0000-4000-8000-0000000000a2', 'student'),
  ('ea00a000-0000-4000-8000-000000000006', 'ea000000-0000-4000-8000-0000000000c1', 'student');

insert into public.teacher_profiles (profile_id, kyc_status) values
  ('ea000000-0000-4000-8000-000000000001', 'approved'),
  ('ea000000-0000-4000-8000-000000000002', 'approved');

-- s2 a ete faite par un remplacant (Rachid), pas par le titulaire (Hakim).
insert into public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
values
  ('ea00a000-0000-4000-8000-000000000002', 'remplacement_pris',
   'ea000000-0000-4000-8000-000000000001', 'ea000000-0000-4000-8000-000000000002',
   'ea000000-0000-4000-8000-000000000002', 'ea00e000-0000-4000-8000-000000000001');

-- a1 est entre dans s1, pas dans s2.
insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
values ('ea00a000-0000-4000-8000-000000000001', 'ea000000-0000-4000-8000-0000000000a1',
        'joined', now() - interval '3 days' + interval '1 minute', 'livekit_webhook');

update public.sessions set status = 'preflight'
 where id in ('ea00a000-0000-4000-8000-000000000001', 'ea00a000-0000-4000-8000-000000000002',
              'ea00a000-0000-4000-8000-000000000005', 'ea00a000-0000-4000-8000-000000000006');
update public.sessions set status = 'in_progress'
 where id in ('ea00a000-0000-4000-8000-000000000001', 'ea00a000-0000-4000-8000-000000000002',
              'ea00a000-0000-4000-8000-000000000005', 'ea00a000-0000-4000-8000-000000000006');
update public.sessions set status = 'ended'
 where id in ('ea00a000-0000-4000-8000-000000000001', 'ea00a000-0000-4000-8000-000000000002',
              'ea00a000-0000-4000-8000-000000000005', 'ea00a000-0000-4000-8000-000000000006');

update public.profiles set account_status = 'disabled'
 where id = 'ea000000-0000-4000-8000-0000000000e1';

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

-- EA1 a EA4 : a1.
select pg_temp.en_tant_que('ea000000-0000-4000-8000-0000000000a1', 'guardian',
                           'ea00ffff-0000-4000-8000-000000000001');
do $$
declare
  v_prenom text;
  v_groupe uuid;
  v_n integer;
  v_ids uuid[];
  v_abs boolean[];
  v_page uuid[];
begin
  select e.prenom, e.groupe_id into v_prenom, v_groupe from public.espace_eleve_adulte() e;
  if v_prenom is distinct from 'Karim'
     or v_groupe is distinct from 'ea00c000-0000-4000-8000-00000000000a' then
    raise exception 'EA ROUGE EA1 : espace lu % / %', v_prenom, v_groupe;
  end if;
  raise notice 'EA OK EA1 : l''adulte lit sa Classe, pas celle de son enfant';

  select pg_catalog.array_agg(h.session_id order by h.started_at desc),
         pg_catalog.array_agg(h.absent order by h.started_at desc)
    into v_ids, v_abs
    from public.seances_passees_eleve_adulte() h;
  if v_ids is distinct from array['ea00a000-0000-4000-8000-000000000002',
                                  'ea00a000-0000-4000-8000-000000000001']::uuid[] then
    raise exception 'EA ROUGE EA2 : historique lu %', v_ids;
  end if;
  if v_abs is distinct from array[true, false] then
    raise exception 'EA ROUGE EA2 : absences lues %', v_abs;
  end if;
  select pg_catalog.array_agg(h.session_id) into v_page
    from public.seances_passees_eleve_adulte(1, null) h;
  if v_page is distinct from array['ea00a000-0000-4000-8000-000000000002']::uuid[] then
    raise exception 'EA ROUGE EA2 : premiere page %', v_page;
  end if;
  select pg_catalog.array_agg(h.session_id) into v_page
    from public.seances_passees_eleve_adulte(1, now() - interval '2 days') h;
  if v_page is distinct from array['ea00a000-0000-4000-8000-000000000001']::uuid[] then
    raise exception 'EA ROUGE EA2 : seconde page %', v_page;
  end if;
  if (select h.date_locale || '/' || h.jour_iso
        from public.seances_passees_eleve_adulte(1, null) h)
     is distinct from pg_catalog.to_char((now() - interval '2 days') at time zone 'Europe/Paris', 'YYYY-MM-DD')
                      || '/' || pg_catalog.date_part('isodow', (now() - interval '2 days') at time zone 'Europe/Paris')::integer then
    raise exception 'EA ROUGE EA2 : date rendue hors du fuseau du foyer';
  end if;
  if (select h.teacher_first_name || '/' || h.teacher_id
        from public.seances_passees_eleve_adulte() h
       where h.session_id = 'ea00a000-0000-4000-8000-000000000002')
     is distinct from 'Rachid/ea000000-0000-4000-8000-000000000002'
     or (select h.teacher_first_name from public.seances_passees_eleve_adulte() h
          where h.session_id = 'ea00a000-0000-4000-8000-000000000001')
     is distinct from 'Hakim' then
    raise exception 'EA ROUGE EA2 : la seance remplacee ne rend pas le remplacant';
  end if;
  raise notice 'EA OK EA2 : historique, absence, pagination, date dans le fuseau du foyer, remplacant rendu';

  select pg_catalog.count(*) into v_n from public.seances_passees_eleve_adulte(100, null) h
   where h.session_id in ('ea00a000-0000-4000-8000-000000000005',
                          'ea00a000-0000-4000-8000-000000000006');
  if v_n <> 0 then
    raise exception 'EA ROUGE EA3 : % seance(s) d''un autre ou de l''enfant lues', v_n;
  end if;
  raise notice 'EA OK EA3 : ni l''enfant ni une autre Classe';

  select pg_catalog.count(*) into v_n from public.participants_classe_eleve_adulte();
  if v_n <> 2 then
    raise exception 'EA ROUGE EA4 : % participant(s) au lieu de 2 (le desactive compte ?)', v_n;
  end if;
  if (select pg_catalog.array_agg(p.prenom order by p.est_moi desc, p.prenom)
        from public.participants_classe_eleve_adulte() p)
     is distinct from array['Karim', 'Bilal'] then
    raise exception 'EA ROUGE EA4 : participants mal ordonnes';
  end if;
  if (select p.cle_avatar from public.participants_classe_eleve_adulte() p where p.est_moi)
       is distinct from 'avatars/a1.jpg'
     or (select p.cle_avatar from public.participants_classe_eleve_adulte() p where not p.est_moi)
       is not null then
    raise exception 'EA ROUGE EA4 : la photo d''un camarade est rendue';
  end if;
  raise notice 'EA OK EA4 : prenoms de la Classe, sa photo seule';
end $$;

-- EA5 : a2, autre Classe.
select pg_temp.en_tant_que('ea000000-0000-4000-8000-0000000000a2', 'guardian',
                           'ea00ffff-0000-4000-8000-000000000002');
do $$
declare
  v_ids uuid[];
begin
  if (select e.groupe_id from public.espace_eleve_adulte() e)
       is distinct from 'ea00c000-0000-4000-8000-00000000000b' then
    raise exception 'EA ROUGE EA5 : Classe de a2 mal lue';
  end if;
  select pg_catalog.array_agg(h.session_id) into v_ids from public.seances_passees_eleve_adulte() h;
  if v_ids is distinct from array['ea00a000-0000-4000-8000-000000000005']::uuid[] then
    raise exception 'EA ROUGE EA5 : historique de a2 %', v_ids;
  end if;
  if exists (select 1 from public.participants_classe_eleve_adulte() p
              where p.prenom in ('Karim', 'Bilal')) then
    raise exception 'EA ROUGE EA5 : a2 lit les participants de la Classe A';
  end if;
  raise notice 'EA OK EA5 : un autre adulte ne lit que sa Classe';
end $$;

-- EA6 : d1 (tuteur qui n'apprend pas), c1 (enfant), e1 (desactive).
do $$
declare
  v_qui record;
begin
  for v_qui in
    select * from (values
      ('ea000000-0000-4000-8000-0000000000d1'::uuid, 'guardian', 'ea00ffff-0000-4000-8000-000000000002'::uuid),
      ('ea000000-0000-4000-8000-0000000000c1'::uuid, 'student', 'ea00ffff-0000-4000-8000-000000000001'::uuid),
      ('ea000000-0000-4000-8000-0000000000e1'::uuid, 'guardian', 'ea00ffff-0000-4000-8000-000000000003'::uuid)
    ) as t(uid, role, foyer)
  loop
    perform pg_temp.en_tant_que(v_qui.uid, v_qui.role, v_qui.foyer);
    if exists (select 1 from public.espace_eleve_adulte())
       or exists (select 1 from public.seances_passees_eleve_adulte())
       or exists (select 1 from public.participants_classe_eleve_adulte()) then
      raise exception 'EA ROUGE EA6 : % lit l''espace adulte', v_qui.uid;
    end if;
  end loop;
  if pg_catalog.has_function_privilege('anon', 'public.espace_eleve_adulte()', 'EXECUTE')
     or pg_catalog.has_function_privilege('anon', 'public.seances_passees_eleve_adulte(integer, timestamptz)', 'EXECUTE')
     or pg_catalog.has_function_privilege('anon', 'public.participants_classe_eleve_adulte()', 'EXECUTE') then
    raise exception 'EA ROUGE EA6 : anon a EXECUTE';
  end if;
  raise notice 'EA OK EA6 : tuteur, enfant, compte desactive et anon ne lisent rien';
end $$;

-- EA7 : a4, adulte sans Classe.
select pg_temp.en_tant_que('ea000000-0000-4000-8000-0000000000a4', 'guardian',
                           'ea00ffff-0000-4000-8000-000000000004');
do $$
declare
  v_n integer;
begin
  select pg_catalog.count(*) into v_n from public.espace_eleve_adulte() e
   where e.prenom = 'Samir' and e.groupe_id is null;
  if v_n <> 1 then
    raise exception 'EA ROUGE EA7 : l''adulte sans Classe a % ligne(s)', v_n;
  end if;
  if exists (select 1 from public.participants_classe_eleve_adulte())
     or exists (select 1 from public.seances_passees_eleve_adulte()) then
    raise exception 'EA ROUGE EA7 : l''adulte sans Classe lit des donnees';
  end if;
  raise notice 'EA OK EA7 : sans Classe, une ligne et rien d''autre';
end $$;

reset role;
rollback;

select 'scenarios_eleve_adulte : 7 controles verts' as resultat;
