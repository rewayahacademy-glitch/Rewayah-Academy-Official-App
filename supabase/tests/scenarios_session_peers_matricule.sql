-- SEC-6 (SERVEUR-PETITS, 13/11/2026, D-042) : le matricule des pairs d'une
-- seance n'est plus lu par un camarade.
-- supabase/migrations/20261124400000_session_peers_matricule.sql.
--
--   SP1  un eleve lit le prenom de ses pairs et un matricule NULL pour eux ;
--        la vue n'a pas de ligne pour lui-meme (son propre matricule n'y
--        figure donc pas : il le lit sur son profil) ;
--   SP2  l'enseignant titulaire de la seance lit les matricules ;
--   SP3  l'enseignant effectif d'un remplacement lit les matricules ;
--        un autre enseignant participant, sans remplacement, n'en lit aucun ;
--   SP4  la direction (participante visible) et le controleur (participant
--        masque) lisent les matricules ;
--   SP5  un participant d'une AUTRE seance ne lit rien de celle-ci ;
--   SP6  anon ne lit rien (pas de SELECT) ; forme de la vue inchangee.
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et toutes les
-- migrations. Tout est annule a la fin. Un echec leve 'SP ROUGE : ...'.

begin;

-- Plusieurs participants par seance (annule par le ROLLBACK final).
update public.app_config set value = 'true'::jsonb
 where key = 'allow_multi_participant_sessions';

insert into auth.users (id, email) values
  ('5e600000-0000-4000-8000-000000000001', 'sp-titulaire@example.test'),
  ('5e600000-0000-4000-8000-000000000002', 'sp-remplacant@example.test'),
  ('5e600000-0000-4000-8000-000000000003', 'sp-autre-ens@example.test'),
  ('5e600000-0000-4000-8000-000000000004', 'sp-admin@example.test'),
  ('5e600000-0000-4000-8000-000000000005', 'sp-ctrl@example.test'),
  ('5e600000-0000-4000-8000-000000000006', 'sp-ens-s2@example.test'),
  ('5e600000-0000-4000-8000-0000000000e1', 'sp-e1@example.test'),
  ('5e600000-0000-4000-8000-0000000000e2', 'sp-e2@example.test'),
  ('5e600000-0000-4000-8000-0000000000e3', 'sp-e3@example.test'),
  ('5e600000-0000-4000-8000-0000000000f1', 'sp-x1@example.test');

insert into public.households (id, timezone) values
  ('5e60ffff-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('5e60ffff-0000-4000-8000-000000000002', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('5e600000-0000-4000-8000-000000000001', 'RA-26-9001', 'teacher', null, 'Hakim', 'Titulaire', 'provisional_active', 'male'),
  ('5e600000-0000-4000-8000-000000000002', 'RA-26-9002', 'teacher', null, 'Rachid', 'Remplacant', 'provisional_active', 'male'),
  ('5e600000-0000-4000-8000-000000000003', 'RA-26-9003', 'teacher', null, 'Samir', 'Autre', 'provisional_active', 'male'),
  ('5e600000-0000-4000-8000-000000000004', 'RA-26-9004', 'admin', null, 'Direction', 'Test', 'active', 'female'),
  ('5e600000-0000-4000-8000-000000000005', 'RA-26-9005', 'controller', null, 'Nadia', 'Controle', 'active', 'female'),
  ('5e600000-0000-4000-8000-000000000006', 'RA-26-9006', 'teacher', null, 'Youssef', 'Seance2', 'provisional_active', 'male'),
  ('5e600000-0000-4000-8000-0000000000e1', 'RA-26-9101', 'student', '5e60ffff-0000-4000-8000-000000000001', 'Yanis', 'Famille', 'active', 'male'),
  ('5e600000-0000-4000-8000-0000000000e2', 'RA-26-9102', 'student', '5e60ffff-0000-4000-8000-000000000001', 'Ilyes', 'Famille', 'active', 'male'),
  ('5e600000-0000-4000-8000-0000000000e3', 'RA-26-9103', 'student', '5e60ffff-0000-4000-8000-000000000002', 'Adam', 'Autre', 'active', 'male'),
  ('5e600000-0000-4000-8000-0000000000f1', 'RA-26-9201', 'student', '5e60ffff-0000-4000-8000-000000000002', 'Rayan', 'Autre', 'active', 'male');

insert into public.teacher_profiles (profile_id, kyc_status) values
  ('5e600000-0000-4000-8000-000000000001', 'approved'),
  ('5e600000-0000-4000-8000-000000000002', 'approved'),
  ('5e600000-0000-4000-8000-000000000003', 'approved'),
  ('5e600000-0000-4000-8000-000000000006', 'approved');

-- S1 : Hakim (titulaire), Yanis, Ilyes, la direction (visible), Nadia
-- (controleuse masquee), Samir (autre enseignant participant).
-- S2 : Youssef, Rayan. S3 : Hakim titulaire, remplace par Rachid ; Adam.
insert into public.sessions (id, teacher_id, started_at, ended_at, status) values
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-000000000001',
   now() - interval '3 days', now() - interval '3 days' + interval '1 hour', 'planned'),
  ('5e60a000-0000-4000-8000-000000000002', '5e600000-0000-4000-8000-000000000006',
   now() - interval '3 days', now() - interval '3 days' + interval '1 hour', 'planned'),
  ('5e60a000-0000-4000-8000-000000000003', '5e600000-0000-4000-8000-000000000001',
   now() - interval '2 days', now() - interval '2 days' + interval '1 hour', 'planned');

insert into public.session_participants (session_id, profile_id, role) values
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-000000000001', 'teacher'),
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-0000000000e1', 'student'),
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-0000000000e2', 'student'),
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-000000000004', 'admin_visible'),
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-000000000005', 'masked_controller'),
  ('5e60a000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-000000000003', 'teacher'),
  ('5e60a000-0000-4000-8000-000000000002', '5e600000-0000-4000-8000-000000000006', 'teacher'),
  ('5e60a000-0000-4000-8000-000000000002', '5e600000-0000-4000-8000-0000000000f1', 'student'),
  ('5e60a000-0000-4000-8000-000000000003', '5e600000-0000-4000-8000-000000000002', 'teacher'),
  ('5e60a000-0000-4000-8000-000000000003', '5e600000-0000-4000-8000-0000000000e3', 'student');

insert into public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
values
  ('5e60a000-0000-4000-8000-000000000003', 'remplacement_designe_admin',
   '5e600000-0000-4000-8000-000000000001', '5e600000-0000-4000-8000-000000000002',
   '5e600000-0000-4000-8000-000000000004', '5e60e000-0000-4000-8000-000000000001');

create function pg_temp.en_tant_que(p_uid uuid, p_role text)
returns void language sql as $$
  select set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('request.jwt.claims', pg_catalog.jsonb_build_object(
           'sub', p_uid, 'app_metadata', pg_catalog.jsonb_build_object('role', p_role))::text, true),
         set_config('test.uid', p_uid::text, true),
         set_config('test.jwt', pg_catalog.jsonb_build_object(
           'sub', p_uid, 'app_metadata', pg_catalog.jsonb_build_object('role', p_role))::text, true);
$$;
grant execute on function pg_temp.en_tant_que(uuid, text) to authenticated;

set local role authenticated;

-- SP1 : Yanis, eleve de S1.
select pg_temp.en_tant_que('5e600000-0000-4000-8000-0000000000e1', 'student');
do $$
declare
  v_prenoms text[];
begin
  select pg_catalog.array_agg(v.first_name order by v.first_name) into v_prenoms
    from public.session_peers_v v
   where v.session_id = '5e60a000-0000-4000-8000-000000000001';
  -- Pairs visibles : Hakim, Ilyes, Samir, la direction (visible) ; ni la
  -- controleuse masquee, ni lui-meme.
  if v_prenoms is distinct from array['Direction', 'Hakim', 'Ilyes', 'Samir'] then
    raise exception 'SP ROUGE SP1 : prenoms lus %', v_prenoms;
  end if;
  if exists (select 1 from public.session_peers_v v where v.immutable_id is not null) then
    raise exception 'SP ROUGE SP1 : un eleve lit le matricule d''un pair';
  end if;
  if exists (select 1 from public.session_peers_v v
              where v.peer_id = '5e600000-0000-4000-8000-0000000000e1') then
    raise exception 'SP ROUGE SP1 : la vue rend une ligne pour soi';
  end if;
  raise notice 'SP OK SP1 : l''eleve lit les prenoms de ses pairs, aucun matricule';
end $$;

-- SP2 : Hakim, titulaire de S1.
select pg_temp.en_tant_que('5e600000-0000-4000-8000-000000000001', 'teacher');
do $$
begin
  if (select pg_catalog.array_agg(v.immutable_id order by v.immutable_id)
        from public.session_peers_v v
       where v.session_id = '5e60a000-0000-4000-8000-000000000001')
     is distinct from array['RA-26-9003', 'RA-26-9004', 'RA-26-9101', 'RA-26-9102'] then
    raise exception 'SP ROUGE SP2 : le titulaire ne lit pas les matricules de S1';
  end if;
  raise notice 'SP OK SP2 : le titulaire lit les matricules';
end $$;

-- SP3 : Rachid, remplacant effectif de S3 (titulaire Hakim) ; Samir, autre
-- enseignant participant de S1, sans remplacement.
select pg_temp.en_tant_que('5e600000-0000-4000-8000-000000000002', 'teacher');
do $$
begin
  if (select pg_catalog.array_agg(v.immutable_id) from public.session_peers_v v
       where v.session_id = '5e60a000-0000-4000-8000-000000000003')
     is distinct from array['RA-26-9103'] then
    raise exception 'SP ROUGE SP3 : le remplacant effectif ne lit pas le matricule';
  end if;
  raise notice 'SP OK SP3 : le remplacant effectif lit les matricules';
end $$;
select pg_temp.en_tant_que('5e600000-0000-4000-8000-000000000003', 'teacher');
do $$
begin
  if (select count(*) from public.session_peers_v v
       where v.session_id = '5e60a000-0000-4000-8000-000000000001') <> 4 then
    raise exception 'SP ROUGE SP3 : l''autre enseignant ne lit pas les prenoms de S1';
  end if;
  if exists (select 1 from public.session_peers_v v where v.immutable_id is not null) then
    raise exception 'SP ROUGE SP3 : un enseignant qui n''est pas celui de la seance lit un matricule';
  end if;
  raise notice 'SP OK SP3 : un autre enseignant participant ne lit aucun matricule';
end $$;

-- SP4 : la direction et la controleuse, participantes de S1.
do $$
declare
  v_qui record;
begin
  for v_qui in
    select * from (values
      ('5e600000-0000-4000-8000-000000000004'::uuid, 'admin'),
      ('5e600000-0000-4000-8000-000000000005'::uuid, 'controller')
    ) as t(uid, role)
  loop
    perform pg_temp.en_tant_que(v_qui.uid, v_qui.role);
    if exists (select 1 from public.session_peers_v v
                where v.session_id = '5e60a000-0000-4000-8000-000000000001'
                  and v.immutable_id is null) then
      raise exception 'SP ROUGE SP4 : % ne lit pas un matricule', v_qui.role;
    end if;
    if not exists (select 1 from public.session_peers_v v
                    where v.session_id = '5e60a000-0000-4000-8000-000000000001'
                      and v.immutable_id = 'RA-26-9101') then
      raise exception 'SP ROUGE SP4 : % ne lit pas le matricule de l''eleve', v_qui.role;
    end if;
  end loop;
  raise notice 'SP OK SP4 : la direction et le controleur lisent les matricules';
end $$;

-- SP5 : Rayan (S2) et Youssef (titulaire de S2) ne lisent rien de S1 ni de S3.
do $$
declare
  v_qui record;
begin
  for v_qui in
    select * from (values
      ('5e600000-0000-4000-8000-0000000000f1'::uuid, 'student'),
      ('5e600000-0000-4000-8000-000000000006'::uuid, 'teacher')
    ) as t(uid, role)
  loop
    perform pg_temp.en_tant_que(v_qui.uid, v_qui.role);
    if exists (select 1 from public.session_peers_v v
                where v.session_id in ('5e60a000-0000-4000-8000-000000000001',
                                       '5e60a000-0000-4000-8000-000000000003')) then
      raise exception 'SP ROUGE SP5 : % lit une autre seance', v_qui.uid;
    end if;
  end loop;
  raise notice 'SP OK SP5 : un participant d''une autre seance ne lit rien';
end $$;

reset role;

-- SP6 : anon sans SELECT ; forme inchangee.
set local role anon;
do $$
declare
  v_refuse boolean := false;
begin
  begin
    perform 1 from public.session_peers_v;
  exception when insufficient_privilege then
    v_refuse := true;
  end;
  if not v_refuse then
    raise exception 'SP ROUGE SP6 : anon lit session_peers_v';
  end if;
end $$;
reset role;
do $$
begin
  if pg_catalog.has_table_privilege('anon', 'public.session_peers_v', 'select') then
    raise exception 'SP ROUGE SP6 : anon a SELECT';
  end if;
  if (select string_agg(column_name || ':' || data_type, ',' order by ordinal_position)
        from information_schema.columns
       where table_schema = 'public' and table_name = 'session_peers_v')
     is distinct from 'session_id:uuid,peer_id:uuid,first_name:text,immutable_id:text' then
    raise exception 'SP ROUGE SP6 : forme de la vue changee';
  end if;
  raise notice 'SP OK SP6 : anon ne lit rien ; forme inchangee';
end $$;

rollback;

select 'scenarios_session_peers_matricule : 6 controles verts' as resultat;
