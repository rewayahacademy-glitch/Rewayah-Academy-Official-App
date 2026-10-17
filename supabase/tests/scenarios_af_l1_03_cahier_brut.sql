-- Audit final 16/10/2026, lot L1-03 : le cahier brut (lesson_reports) et les
-- constats de prononciation (makharij_findings) ne sont lus que par l'auteur,
-- l'administration et le controleur EN MISSION sur la seance.
-- Six jetons, attendu ecrit avant la migration :
--   enseignant auteur 1/1, admin 1/1, controleur en mission 1/1,
--   controleur sans mission 0/0, eleve du foyer 0/0, tuteur du foyer 0/0.
-- Se rejoue sur une base neuve (stub_auth.sql, migrations) : il insere ses
-- fixtures.
begin;

insert into auth.users (id, email) values
  ('a1030000-0000-0000-0000-000000000001', 'l103-admin@example.test'),
  ('a1030000-0000-0000-0000-000000000002', 'l103-teacher@example.test'),
  ('a1030000-0000-0000-0000-000000000003', 'l103-student@example.test'),
  ('a1030000-0000-0000-0000-000000000004', 'l103-guardian@example.test'),
  ('a1030000-0000-0000-0000-000000000005', 'l103-ctrl-mission@example.test'),
  ('a1030000-0000-0000-0000-000000000006', 'l103-ctrl-libre@example.test');
insert into public.households (id) values ('a1030000-0000-0000-0000-000000000101');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status) values
  ('a1030000-0000-0000-0000-000000000001', 'L103-ADMIN', 'admin', 'a1030000-0000-0000-0000-000000000101', 'Direction', 'Test', 'active'),
  ('a1030000-0000-0000-0000-000000000002', 'L103-TEACHER', 'teacher', 'a1030000-0000-0000-0000-000000000101', 'Enseignant', 'Test', 'provisional_active'),
  ('a1030000-0000-0000-0000-000000000003', 'L103-STUDENT', 'student', 'a1030000-0000-0000-0000-000000000101', 'Eleve', 'Test', 'active'),
  ('a1030000-0000-0000-0000-000000000004', 'L103-GUARDIAN', 'guardian', 'a1030000-0000-0000-0000-000000000101', 'Tuteur', 'Test', 'active'),
  ('a1030000-0000-0000-0000-000000000005', 'L103-CTRL-M', 'controller', 'a1030000-0000-0000-0000-000000000101', 'Controleur', 'Mission', 'active'),
  ('a1030000-0000-0000-0000-000000000006', 'L103-CTRL-L', 'controller', 'a1030000-0000-0000-0000-000000000101', 'Controleur', 'Libre', 'active');
insert into public.student_profiles (profile_id) values ('a1030000-0000-0000-0000-000000000003');
insert into public.teacher_profiles (profile_id) values ('a1030000-0000-0000-0000-000000000002');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values ('a1030000-0000-0000-0000-000000000201', 'a1030000-0000-0000-0000-000000000002', 'enfant', 5, 'L1-03 classe', 1, 10);
insert into public.groupe_membres (groupe_id, student_id, joined_at)
values ('a1030000-0000-0000-0000-000000000201', 'a1030000-0000-0000-0000-000000000003', now() - interval '2 days');
insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
values ('a1030000-0000-0000-0000-000000000301', 'a1030000-0000-0000-0000-000000000002',
  now() - interval '2 hours', now() - interval '1 hour', 'ended', 'standard',
  'a1030000-0000-0000-0000-000000000201');
insert into public.session_participants (session_id, profile_id, role) values
  ('a1030000-0000-0000-0000-000000000301', 'a1030000-0000-0000-0000-000000000002', 'teacher'),
  ('a1030000-0000-0000-0000-000000000301', 'a1030000-0000-0000-0000-000000000003', 'student');
insert into public.lesson_reports (id, session_id, idempotency_key, author_profile_id, content)
values ('a1030000-0000-0000-0000-000000000401', 'a1030000-0000-0000-0000-000000000301',
  'l103-cahier', 'a1030000-0000-0000-0000-000000000002', '{"note":"interne"}');
insert into public.makharij_findings (lesson_report_id, makhraj, finding)
values ('a1030000-0000-0000-0000-000000000401', 'jawf', '{"ecart":"interne"}');
insert into private.controle_missions
  (session_id, groupe_id, enseignant_effectif_id, controleur_id, version_regles,
   cycle_debut, critere, echeance, statut)
values ('a1030000-0000-0000-0000-000000000301', 'a1030000-0000-0000-0000-000000000201',
  'a1030000-0000-0000-0000-000000000002', 'a1030000-0000-0000-0000-000000000005', 0,
  current_date, 'aleatoire', now() + interval '2 days', 'attribuee');

grant usage on schema public to authenticated;
grant select on public.lesson_reports, public.makharij_findings to authenticated;

create temp table l103_attendu (uid uuid, role text, cahiers int, constats int);
grant all on l103_attendu to authenticated;
insert into l103_attendu values
  ('a1030000-0000-0000-0000-000000000002', 'teacher', 1, 1),
  ('a1030000-0000-0000-0000-000000000001', 'admin', 1, 1),
  ('a1030000-0000-0000-0000-000000000005', 'controller', 1, 1),
  ('a1030000-0000-0000-0000-000000000006', 'controller', 0, 0),
  ('a1030000-0000-0000-0000-000000000003', 'student', 0, 0),
  ('a1030000-0000-0000-0000-000000000004', 'guardian', 0, 0);

do $scenario$
declare
  r record;
  v_cahiers int;
  v_constats int;
begin
  for r in select * from l103_attendu loop
    perform set_config('request.jwt.claim.sub', r.uid::text, true);
    perform set_config('request.jwt.claims', jsonb_build_object(
      'sub', r.uid::text,
      'app_metadata', jsonb_build_object('role', r.role,
        'household_id', 'a1030000-0000-0000-0000-000000000101'))::text, true);
    set local role authenticated;
    select count(*) into v_cahiers from public.lesson_reports;
    select count(*) into v_constats from public.makharij_findings;
    reset role;
    if v_cahiers <> r.cahiers or v_constats <> r.constats then
      raise exception 'L1-03: % (%) lit % cahier(s) et % constat(s), attendu % et %',
        r.role, r.uid, v_cahiers, v_constats, r.cahiers, r.constats;
    end if;
  end loop;
  raise notice 'L1-03 PASS: 6 jetons, cahier brut et constats conformes';
end
$scenario$;

rollback;
