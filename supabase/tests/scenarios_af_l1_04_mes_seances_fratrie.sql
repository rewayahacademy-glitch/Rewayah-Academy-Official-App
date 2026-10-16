-- Scenario d'acceptation du lot L1-04 (audit final 16/10/2026, P0-2 fratrie).
-- `mes_seances_v` filtre par role : un eleve ne voit que ses seances, le tuteur
-- voit le foyer, l'enseignant voit ses seances, l'administration et le controle
-- voient tout. Chaque controle echoue bruyamment.
--
-- Se rejoue sur une base NEUVE, apres stub_auth.sql et toutes les migrations
-- (les fixtures s'inserent une seule fois). Sur une base sans la migration
-- 20261017100400, le controle de l'enfant compte 2 et le scenario echoue.

-- ============================================================
-- Fixtures : foyer F (tuteur G, enfants E et E2), foyer A (enfant X),
-- enseignant T, controleur C.
-- ============================================================

insert into auth.users (id, email) values
  ('10000104-0000-0000-0000-000000000001', 'tuteurF@example.test'),
  ('10000104-0000-0000-0000-000000000002', 'enfantE@example.test'),
  ('10000104-0000-0000-0000-000000000003', 'enfantE2@example.test'),
  ('10000104-0000-0000-0000-000000000004', 'enseignantT@example.test'),
  ('10000104-0000-0000-0000-000000000005', 'enfantX@example.test'),
  ('10000104-0000-0000-0000-000000000006', 'controleurC@example.test');

insert into public.households (id, timezone) values
  ('10000104-0000-0000-0000-00000000000f', 'Europe/Paris'),
  ('10000104-0000-0000-0000-00000000000a', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('10000104-0000-0000-0000-000000000001', 'GUARD-L104-000001', 'guardian',
   '10000104-0000-0000-0000-00000000000f', 'Tuteur', 'Famille', 'active', 'male'),
  ('10000104-0000-0000-0000-000000000002', 'STUD-L104-000002', 'student',
   '10000104-0000-0000-0000-00000000000f', 'Enfant', 'Un', 'active', null),
  ('10000104-0000-0000-0000-000000000003', 'STUD-L104-000003', 'student',
   '10000104-0000-0000-0000-00000000000f', 'Enfant', 'Deux', 'active', null),
  ('10000104-0000-0000-0000-000000000004', 'TEACH-L104-000004', 'teacher',
   null, 'Ensei', 'Gnant', 'provisional_active', 'female'),
  ('10000104-0000-0000-0000-000000000005', 'STUD-L104-000005', 'student',
   '10000104-0000-0000-0000-00000000000a', 'Autre', 'Foyer', 'active', null),
  ('10000104-0000-0000-0000-000000000006', 'ADMIN-L104-000006', 'controller',
   null, 'Controle', 'Rewayah', 'active', 'female');

-- S1 : enseignant T avec E. S2 : enseignant T avec E2. Creneaux disjoints.
insert into public.sessions (id, teacher_id, started_at, ended_at)
values
  ('10000104-0000-0000-0000-0000000000a1', '10000104-0000-0000-0000-000000000004',
   '2027-01-15 10:00:00+00', '2027-01-15 11:00:00+00'),
  ('10000104-0000-0000-0000-0000000000b2', '10000104-0000-0000-0000-000000000004',
   '2027-01-15 14:00:00+00', '2027-01-15 15:00:00+00');

insert into public.session_participants (session_id, profile_id, role)
values
  ('10000104-0000-0000-0000-0000000000a1', '10000104-0000-0000-0000-000000000004', 'teacher'),
  ('10000104-0000-0000-0000-0000000000a1', '10000104-0000-0000-0000-000000000002', 'student'),
  ('10000104-0000-0000-0000-0000000000b2', '10000104-0000-0000-0000-000000000004', 'teacher'),
  ('10000104-0000-0000-0000-0000000000b2', '10000104-0000-0000-0000-000000000003', 'student');

-- ============================================================
-- Controles : chaque bloc prend le jeton d'un appelant, lit la vue, compare.
-- ============================================================

-- Enfant E : ses seances, et aucune de sa fratrie (E2 est dans son foyer).
do $$
declare
  v_total int; v_moi int; v_frere int;
  v_e  uuid := '10000104-0000-0000-0000-000000000002';
  v_e2 uuid := '10000104-0000-0000-0000-000000000003';
begin
  perform set_config('request.jwt.claim.sub', v_e::text, true);
  perform set_config('request.jwt.claims',
    '{"app_metadata":{"role":"student","household_id":"10000104-0000-0000-0000-00000000000f"}}', true);
  set local role authenticated;
  select count(*),
         count(*) filter (where student_id = v_e),
         count(*) filter (where student_id = v_e2)
    into v_total, v_moi, v_frere
    from public.mes_seances_v;
  reset role;
  if v_total <> 1 or v_moi <> 1 or v_frere <> 0 then
    raise exception 'L1-04 ECHEC enfant E : total=% (attendu 1), a lui=% (attendu 1), fratrie=% (attendu 0)',
      v_total, v_moi, v_frere;
  end if;
  raise notice 'L1-04 ok : l''enfant E lit une seance, la sienne, et aucune de E2';
end $$;

-- Enfant E2 : sa seance, rien de E.
do $$
declare
  v_total int; v_moi int; v_frere int;
  v_e  uuid := '10000104-0000-0000-0000-000000000002';
  v_e2 uuid := '10000104-0000-0000-0000-000000000003';
begin
  perform set_config('request.jwt.claim.sub', v_e2::text, true);
  perform set_config('request.jwt.claims',
    '{"app_metadata":{"role":"student","household_id":"10000104-0000-0000-0000-00000000000f"}}', true);
  set local role authenticated;
  select count(*),
         count(*) filter (where student_id = v_e2),
         count(*) filter (where student_id = v_e)
    into v_total, v_moi, v_frere
    from public.mes_seances_v;
  reset role;
  if v_total <> 1 or v_moi <> 1 or v_frere <> 0 then
    raise exception 'L1-04 ECHEC enfant E2 : total=% (attendu 1), a lui=% (attendu 1), fratrie=% (attendu 0)',
      v_total, v_moi, v_frere;
  end if;
  raise notice 'L1-04 ok : l''enfant E2 lit une seance, la sienne, et aucune de E';
end $$;

-- Tuteur G du foyer F : les deux seances du foyer.
do $$
declare
  v_total int; v_distincts int;
  v_g uuid := '10000104-0000-0000-0000-000000000001';
begin
  perform set_config('request.jwt.claim.sub', v_g::text, true);
  perform set_config('request.jwt.claims',
    '{"app_metadata":{"role":"guardian","household_id":"10000104-0000-0000-0000-00000000000f"}}', true);
  set local role authenticated;
  select count(*), count(distinct student_id)
    into v_total, v_distincts
    from public.mes_seances_v;
  reset role;
  if v_total <> 2 or v_distincts <> 2 then
    raise exception 'L1-04 ECHEC tuteur : lignes=% (attendu 2), eleves distincts=% (attendu 2)',
      v_total, v_distincts;
  end if;
  raise notice 'L1-04 ok : le tuteur lit les deux seances de son foyer';
end $$;

-- Enseignant T : ses deux seances, chacune avec son eleve.
do $$
declare
  v_total int; v_siennes int;
  v_t uuid := '10000104-0000-0000-0000-000000000004';
begin
  perform set_config('request.jwt.claim.sub', v_t::text, true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
  set local role authenticated;
  select count(*), count(*) filter (where teacher_id = v_t)
    into v_total, v_siennes
    from public.mes_seances_v;
  reset role;
  if v_total <> 2 or v_siennes <> 2 then
    raise exception 'L1-04 ECHEC enseignant : lignes=% (attendu 2), siennes=% (attendu 2)',
      v_total, v_siennes;
  end if;
  raise notice 'L1-04 ok : l''enseignant lit ses deux seances';
end $$;

-- Enfant X d'un autre foyer : aucune ligne.
do $$
declare
  v_total int;
  v_x uuid := '10000104-0000-0000-0000-000000000005';
begin
  perform set_config('request.jwt.claim.sub', v_x::text, true);
  perform set_config('request.jwt.claims',
    '{"app_metadata":{"role":"student","household_id":"10000104-0000-0000-0000-00000000000a"}}', true);
  set local role authenticated;
  select count(*) into v_total from public.mes_seances_v;
  reset role;
  if v_total <> 0 then
    raise exception 'L1-04 ECHEC enfant d''un autre foyer : lignes=% (attendu 0)', v_total;
  end if;
  raise notice 'L1-04 ok : l''enfant d''un autre foyer ne lit rien';
end $$;

-- Controleur C : tout, inchange.
do $$
declare
  v_total int;
  v_c uuid := '10000104-0000-0000-0000-000000000006';
begin
  perform set_config('request.jwt.claim.sub', v_c::text, true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"controller"}}', true);
  set local role authenticated;
  select count(*) into v_total from public.mes_seances_v;
  reset role;
  if v_total <> 2 then
    raise exception 'L1-04 ECHEC controleur : lignes=% (attendu 2)', v_total;
  end if;
  raise notice 'L1-04 ok : le controleur lit toutes les seances';
end $$;

-- Garde-fou : la vue garde security_barrier.
do $$
begin
  if not exists (
    select 1 from pg_class c
    where c.oid = 'public.mes_seances_v'::regclass
      and c.reloptions @> array['security_barrier=true']
  ) then
    raise exception 'L1-04 ECHEC : security_barrier absent de mes_seances_v';
  end if;
  raise notice 'L1-04 ok : security_barrier conserve';
end $$;

-- Remise a zero des reglages de session.
select set_config('request.jwt.claim.sub', '', false);
select set_config('request.jwt.claims', '', false);
