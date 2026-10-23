-- RECH-BACK-4: expired control missions and stale authorization are invisible.
begin;

insert into auth.users (id, email) values
  ('d1400000-0000-0000-0000-000000000001', 'rech-d3-admin@example.test'),
  ('d1400000-0000-0000-0000-000000000002', 'rech-d3-teacher@example.test'),
  ('d1400000-0000-0000-0000-000000000003', 'rech-d3-controller@example.test'),
  ('d1400000-0000-0000-0000-000000000004', 'rech-d3-controller-disabled@example.test');
insert into public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
values
  ('d1400000-0000-0000-0000-000000000001', 'D3-ADMIN', 'admin', 'D3', 'Admin', 'active', 'male'),
  ('d1400000-0000-0000-0000-000000000002', 'D3-TEACHER', 'teacher', 'D3', 'Teacher', 'provisional_active', 'male'),
  ('d1400000-0000-0000-0000-000000000003', 'D3-CONTROLLER', 'controller', 'D3', 'Controller', 'active', 'female'),
  ('d1400000-0000-0000-0000-000000000004', 'D3-CONTROLLER-DISABLED', 'controller', 'D3', 'Controller', 'disabled', 'female');
-- 0089 requires current teacher NDA and recording notice before activation.
do $fixture_teacher_contract$
declare
  v_teacher record;
  v_teacher_version text;
  v_notice_version text;
begin
  select version into v_teacher_version
    from public.contract_texts
   where contract_kind = 'teacher_nda' and locale = 'fr' and is_current;
  select version into v_notice_version
    from public.contract_required_versions
   where contract_kind = 'recording_and_control_notice';
  for v_teacher in
    select id from public.profiles
     where role = 'teacher' and account_status = 'provisional_active'
  loop
    perform set_config('request.jwt.claim.sub', v_teacher.id::text, true);
    perform set_config('test.uid', v_teacher.id::text, true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
    perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    perform public.signer_contrat(v_teacher_version, 'Fixture RECH-D3');
    insert into public.contract_acceptances(profile_id, contract_kind, version)
    values (v_teacher.id, 'recording_and_control_notice', v_notice_version)
    on conflict (profile_id, contract_kind, version) do nothing;
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values (v_teacher.id, 'teacher_conduct_code', public.code_conduite_version_requise())
    on conflict (profile_id, contract_kind, version) do nothing;
    perform set_config('request.jwt.claim.sub', 'd1400000-0000-0000-0000-000000000001', true);
    perform set_config('test.uid', 'd1400000-0000-0000-0000-000000000001', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
    perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
    update public.profiles set account_status = 'active' where id = v_teacher.id;
  end loop;
end
$fixture_teacher_contract$;

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, genre_public)
values
  ('d1400000-0000-0000-0000-000000000101',
   'd1400000-0000-0000-0000-000000000002', 'enfant', 5, 'D3 mission fixture A', 1, 9, 'indetermine'),
  ('d1400000-0000-0000-0000-000000000102',
   'd1400000-0000-0000-0000-000000000002', 'enfant', 5, 'D3 mission fixture B', 2, 10, 'indetermine'),
  ('d1400000-0000-0000-0000-000000000103',
   'd1400000-0000-0000-0000-000000000002', 'enfant', 5, 'D3 mission fixture C', 3, 11, 'indetermine');
insert into public.sessions
  (id, teacher_id, started_at, ended_at, status, groupe_id)
values
  ('d1400000-0000-0000-0000-000000000201',
   'd1400000-0000-0000-0000-000000000002', now() - interval '2 hours',
   now() - interval '1 hour', 'ended', 'd1400000-0000-0000-0000-000000000101'),
  ('d1400000-0000-0000-0000-000000000202',
   'd1400000-0000-0000-0000-000000000002', now() - interval '1 hour',
   now() + interval '1 hour', 'in_progress', 'd1400000-0000-0000-0000-000000000102'),
  ('d1400000-0000-0000-0000-000000000203',
   'd1400000-0000-0000-0000-000000000002', now() + interval '2 hours',
   now() + interval '3 hours', 'in_progress', 'd1400000-0000-0000-0000-000000000103');

insert into private.controle_capacites
  (id, profile_id, approved_by, active_from, expires_at,
   scope_all_groups, grant_idempotency_key)
values
  ('d1400000-0000-0000-0000-000000000301',
   'd1400000-0000-0000-0000-000000000003',
   'd1400000-0000-0000-0000-000000000001', now() - interval '1 day',
   now() + interval '1 day', true, 'd1400000-0000-0000-0000-000000000302'),
  ('d1400000-0000-0000-0000-000000000303',
   'd1400000-0000-0000-0000-000000000004',
   'd1400000-0000-0000-0000-000000000001', now() - interval '1 day',
   now() + interval '1 day', true, 'd1400000-0000-0000-0000-000000000304');

insert into private.controle_missions
  (id, session_id, groupe_id, enseignant_effectif_id, controleur_id,
   version_regles, cycle_debut, critere, affectee_le, echeance, statut)
values
  ('d1400000-0000-0000-0000-000000000401',
   'd1400000-0000-0000-0000-000000000201',
   'd1400000-0000-0000-0000-000000000101',
   'd1400000-0000-0000-0000-000000000002',
   'd1400000-0000-0000-0000-000000000003', 1, current_date,
   'aleatoire', now() - interval '2 hours', now() - interval '1 minute', 'attribuee'),
  ('d1400000-0000-0000-0000-000000000403',
   'd1400000-0000-0000-0000-000000000203',
   'd1400000-0000-0000-0000-000000000103',
   'd1400000-0000-0000-0000-000000000002',
   'd1400000-0000-0000-0000-000000000004', 1, current_date,
   'aleatoire', now(), now() + interval '30 minutes', 'attribuee');

select set_config('request.jwt.claim.sub', 'd1400000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'd1400000-0000-0000-0000-000000000003',
  'aal', 'aal2',
  'app_metadata', jsonb_build_object('role', 'controller', 'authorization_version', 1)
)::text, true);
set local role authenticated;

do $expired$
begin
  if public.ma_mission_controle() <> '{}'::jsonb then
    raise exception 'RECH-D3: mission échue encore exposée';
  end if;
end;
$expired$;

reset role;
insert into private.controle_missions
  (id, session_id, groupe_id, enseignant_effectif_id, controleur_id,
   version_regles, cycle_debut, critere, affectee_le, echeance, statut)
values
  ('d1400000-0000-0000-0000-000000000402',
   'd1400000-0000-0000-0000-000000000202',
   'd1400000-0000-0000-0000-000000000102',
   'd1400000-0000-0000-0000-000000000002',
   'd1400000-0000-0000-0000-000000000003', 1, current_date,
   'aleatoire', now(), now() + interval '30 minutes', 'attribuee');
set local role authenticated;

do $active$
begin
  if public.ma_mission_controle() ->> 'id' <> 'd1400000-0000-0000-0000-000000000402' then
    raise exception 'RECH-D3: mission active de la portée non rendue';
  end if;
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'd1400000-0000-0000-0000-000000000003',
    'aal', 'aal2',
    'app_metadata', jsonb_build_object('role', 'controller', 'authorization_version', 99)
  )::text, true);
  if public.ma_mission_controle() <> '{}'::jsonb then
    raise exception 'RECH-D3: session à autorisation périmée acceptée';
  end if;
end;
$active$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', 'd1400000-0000-0000-0000-000000000004', true);
select set_config('test.uid', 'd1400000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'd1400000-0000-0000-0000-000000000004',
  'aal', 'aal2',
  'app_metadata', jsonb_build_object('role', 'controller', 'authorization_version', 1)
)::text, true);
select set_config('test.jwt', jsonb_build_object(
  'aal', 'aal2',
  'app_metadata', jsonb_build_object('role', 'controller', 'authorization_version', 1)
)::text, true);
do $disabled_controller$
begin
  if public.ma_mission_controle() <> '{}'::jsonb then
    raise exception 'RECH-D3: disabled controller saw an otherwise valid mission';
  end if;
end;
$disabled_controller$;

reset role;
do $anon_acl$
begin
  if pg_catalog.has_function_privilege('anon', 'public.ma_mission_controle()', 'EXECUTE') then
    raise exception 'RECH-D3: anon unexpectedly has mission RPC EXECUTE';
  end if;
end;
$anon_acl$;

set local role anon;
do $anon_call$
begin
  begin
    perform public.ma_mission_controle();
    raise exception 'RECH-D3: anon read a control mission';
  exception when insufficient_privilege then null;
  end;
end;
$anon_call$;
reset role;
rollback;
