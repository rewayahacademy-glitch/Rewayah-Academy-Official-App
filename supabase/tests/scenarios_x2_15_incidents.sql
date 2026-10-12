-- X2-15: les policies de groupe ne se récursent pas et la RPC garde ses rôles.
begin;
insert into auth.users(id,email) values
 ('a1500000-0000-0000-0000-000000000001','x215-admin@test'),
 ('a1500000-0000-0000-0000-000000000002','x215-controller@test'),
 ('a1500000-0000-0000-0000-000000000003','x215-teacher@test'),
 ('a1500000-0000-0000-0000-000000000004','x215-guardian@test'),
 ('a1500000-0000-0000-0000-000000000005','x215-disabled-admin@test'),
 ('a1500000-0000-0000-0000-000000000006','x215-accountant@test'),
 ('a1500000-0000-0000-0000-000000000007','x215-student@test'),
 ('a1500000-0000-0000-0000-000000000008','x215-other-student@test');
insert into public.households(id) values ('a15fffff-0000-0000-0000-000000000001');
insert into public.households(id) values ('a15fffff-0000-0000-0000-000000000002');
insert into public.profiles(id,immutable_id,role,household_id,first_name,last_name,gender) values
 ('a1500000-0000-0000-0000-000000000001','ADM-X215-001','admin','a15fffff-0000-0000-0000-000000000001','Admin','Test','male'),
 ('a1500000-0000-0000-0000-000000000002','CTR-X215-001','controller','a15fffff-0000-0000-0000-000000000001','Control','Test','female'),
 ('a1500000-0000-0000-0000-000000000003','TEA-X215-001','teacher','a15fffff-0000-0000-0000-000000000001','Teach','Test','male'),
 ('a1500000-0000-0000-0000-000000000004','GUA-X215-001','guardian','a15fffff-0000-0000-0000-000000000001','Guard','Test','female'),
 ('a1500000-0000-0000-0000-000000000005','ADM-X215-002','admin','a15fffff-0000-0000-0000-000000000001','Disabled','Admin','male'),
 ('a1500000-0000-0000-0000-000000000006','ACC-X215-001','accountant','a15fffff-0000-0000-0000-000000000001','Account','Test','female'),
 ('a1500000-0000-0000-0000-000000000007','STU-X215-001','student','a15fffff-0000-0000-0000-000000000001','Student','Test','male'),
 ('a1500000-0000-0000-0000-000000000008','STU-X215-002','student','a15fffff-0000-0000-0000-000000000002','Other','Student','female');
update public.profiles
set account_status = case
  when role = 'teacher' then 'provisional_active'::public.account_status
  else 'active'::public.account_status
end
where id in (
 'a1500000-0000-0000-0000-000000000001',
 'a1500000-0000-0000-0000-000000000002',
 'a1500000-0000-0000-0000-000000000003',
 'a1500000-0000-0000-0000-000000000004',
 'a1500000-0000-0000-0000-000000000005',
 'a1500000-0000-0000-0000-000000000006',
 'a1500000-0000-0000-0000-000000000007',
 'a1500000-0000-0000-0000-000000000008'
);
update public.profiles
set account_status = 'disabled'::public.account_status
where id = 'a1500000-0000-0000-0000-000000000005';
insert into public.student_profiles(profile_id) values
 ('a1500000-0000-0000-0000-000000000007'),
 ('a1500000-0000-0000-0000-000000000008');
insert into public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local) values
 ('a15aaaaa-0000-0000-0000-000000000001','a1500000-0000-0000-0000-000000000003','enfant',5,'Classe X215',1,9);
insert into public.groupe_membres(groupe_id,student_id) values
 ('a15aaaaa-0000-0000-0000-000000000001','a1500000-0000-0000-0000-000000000007'),
 ('a15aaaaa-0000-0000-0000-000000000001','a1500000-0000-0000-0000-000000000008');
insert into public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,updated_at) values
 ('a15bbbbb-0000-0000-0000-000000000001','a1500000-0000-0000-0000-000000000003','a15aaaaa-0000-0000-0000-000000000001',now()-interval '1 hour',now()-interval '30 minutes','tech_failure',now());
do $$ begin
 if not (select prosecdef from pg_proc where oid='public.lister_incidents_seances(timestamptz,integer,integer)'::regprocedure) then
   raise exception 'X2-15 RPC must be SECURITY DEFINER to avoid recursive groupes policies';
 end if;
 if not has_function_privilege('authenticated','public.lister_incidents_seances(timestamptz,integer,integer)','EXECUTE') then
   raise exception 'X2-15 authenticated must execute RPC';
 end if;
 if has_function_privilege('anon','public.lister_incidents_seances(timestamptz,integer,integer)','EXECUTE') then
   raise exception 'X2-15 anon must not execute RPC';
 end if;
 if has_function_privilege('service_role','public.lister_incidents_seances(timestamptz,integer,integer)','EXECUTE') then
   raise exception 'X2-15 service_role must not execute RPC';
 end if;
end $$;
set local role authenticated;
select set_config('test.uid','a1500000-0000-0000-0000-000000000001',true);
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 1 then raise exception 'X2-15 admin expected 1 incident, got %',n; end if;
end $$;
select set_config('test.uid','a1500000-0000-0000-0000-000000000002',true);
select set_config('test.jwt','{"app_metadata":{"role":"controller"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 1 then raise exception 'X2-15 controller expected 1 incident, got %',n; end if;
end $$;
select set_config('test.uid','a1500000-0000-0000-0000-000000000003',true);
select set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 0 then raise exception 'X2-15 teacher must see zero incidents'; end if;
end $$;
select set_config('test.uid','a1500000-0000-0000-0000-000000000004',true);
select set_config('test.jwt','{"app_metadata":{"role":"guardian","household_id":"a15fffff-0000-0000-0000-000000000001"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 0 then raise exception 'X2-15 guardian must see zero incidents'; end if;
end $$;
select set_config('test.uid','a1500000-0000-0000-0000-000000000005',true);
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 0 then raise exception 'X2-15 disabled admin must see zero incidents'; end if;
end $$;
select set_config('test.uid','a1500000-0000-0000-0000-000000000006',true);
select set_config('test.jwt','{"app_metadata":{"role":"accountant"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 0 then raise exception 'X2-15 accountant must see zero incidents'; end if;
end $$;
select set_config('test.uid','a1500000-0000-0000-0000-000000000007',true);
select set_config('test.jwt','{"app_metadata":{"role":"student","household_id":"a15fffff-0000-0000-0000-000000000001"}}',true);
do $$ declare n int; begin
 select count(*) into n from public.lister_incidents_seances(now(),100,0);
 if n <> 0 then raise exception 'X2-15 student must see zero incidents'; end if;
end $$;

-- The policy helpers must preserve the exact row scopes for all six roles.
do $$
declare
  v_uid uuid;
  v_role text;
  v_household uuid;
  v_expected_groups integer;
  v_expected_members integer;
  v_groups integer;
  v_members integer;
begin
  for v_uid, v_role, v_household, v_expected_groups, v_expected_members in
    select * from (values
      ('a1500000-0000-0000-0000-000000000001'::uuid, 'admin', 'a15fffff-0000-0000-0000-000000000001'::uuid, 1, 2),
      ('a1500000-0000-0000-0000-000000000002'::uuid, 'controller', 'a15fffff-0000-0000-0000-000000000001'::uuid, 0, 0),
      ('a1500000-0000-0000-0000-000000000003'::uuid, 'teacher', 'a15fffff-0000-0000-0000-000000000001'::uuid, 1, 2),
      ('a1500000-0000-0000-0000-000000000004'::uuid, 'guardian', 'a15fffff-0000-0000-0000-000000000001'::uuid, 1, 1),
      ('a1500000-0000-0000-0000-000000000007'::uuid, 'student', 'a15fffff-0000-0000-0000-000000000001'::uuid, 1, 1),
      ('a1500000-0000-0000-0000-000000000006'::uuid, 'accountant', 'a15fffff-0000-0000-0000-000000000001'::uuid, 0, 0)
    ) as expected_cases(uid, role_name, household_id, group_count, member_count)
  loop
    perform set_config('test.uid', v_uid::text, true);
    perform set_config('test.jwt', jsonb_build_object('app_metadata', jsonb_build_object(
      'role', v_role, 'household_id', v_household
    ))::text, true);
    select count(*) into v_groups from public.groupes;
    select count(*) into v_members from public.groupe_membres;
    if v_groups <> v_expected_groups or v_members <> v_expected_members then
      raise exception 'X2-15 % expected groups/members %/%, got %/%',
        v_role, v_expected_groups, v_expected_members, v_groups, v_members;
    end if;
  end loop;
end $$;
rollback;
