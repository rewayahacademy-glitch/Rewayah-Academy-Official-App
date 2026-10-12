-- X2-16: planning hebdomadaire admin/controller uniquement.
begin;
insert into auth.users(id,email) values
 ('a1600000-0000-0000-0000-000000000001','x216-admin@test'),
 ('a1600000-0000-0000-0000-000000000002','x216-controller@test'),
 ('a1600000-0000-0000-0000-000000000003','x216-teacher@test'),
 ('a1600000-0000-0000-0000-000000000004','x216-guardian@test'),
 ('a1600000-0000-0000-0000-000000000005','x216-disabled-admin@test'),
 ('a1600000-0000-0000-0000-000000000006','x216-accountant@test'),
 ('a1600000-0000-0000-0000-000000000007','x216-student@test');
insert into public.households(id) values ('a16fffff-0000-0000-0000-000000000001');
insert into public.profiles(id,immutable_id,role,household_id,first_name,last_name,gender) values
 ('a1600000-0000-0000-0000-000000000001','ADM-X216-001','admin','a16fffff-0000-0000-0000-000000000001','Admin','Test','male'),
 ('a1600000-0000-0000-0000-000000000002','CTR-X216-001','controller','a16fffff-0000-0000-0000-000000000001','Control','Test','female'),
 ('a1600000-0000-0000-0000-000000000003','TEA-X216-001','teacher','a16fffff-0000-0000-0000-000000000001','Teach','Test','male'),
 ('a1600000-0000-0000-0000-000000000004','GUA-X216-001','guardian','a16fffff-0000-0000-0000-000000000001','Guard','Test','female'),
 ('a1600000-0000-0000-0000-000000000005','ADM-X216-002','admin','a16fffff-0000-0000-0000-000000000001','Disabled','Admin','male'),
 ('a1600000-0000-0000-0000-000000000006','ACC-X216-001','accountant','a16fffff-0000-0000-0000-000000000001','Account','Test','female'),
 ('a1600000-0000-0000-0000-000000000007','STU-X216-001','student','a16fffff-0000-0000-0000-000000000001','Student','Test','male');
update public.profiles
set account_status = case
  when role = 'teacher' then 'provisional_active'::public.account_status
  else 'active'::public.account_status
end
where id in (
 'a1600000-0000-0000-0000-000000000001',
 'a1600000-0000-0000-0000-000000000002',
 'a1600000-0000-0000-0000-000000000003',
 'a1600000-0000-0000-0000-000000000004',
 'a1600000-0000-0000-0000-000000000005',
 'a1600000-0000-0000-0000-000000000006',
 'a1600000-0000-0000-0000-000000000007'
);
update public.profiles
set account_status = 'disabled'::public.account_status
where id = 'a1600000-0000-0000-0000-000000000005';
insert into public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local) values
 ('a16aaaaa-0000-0000-0000-000000000001','a1600000-0000-0000-0000-000000000003','enfant',5,'Classe X216',1,9);
insert into public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status) values
 ('a16bbbbb-0000-0000-0000-000000000001','a1600000-0000-0000-0000-000000000003','a16aaaaa-0000-0000-0000-000000000001',date_trunc('week',now())+interval '1 day',date_trunc('week',now())+interval '1 day 1 hour','planned');
do $$ begin
 if not (select prosecdef from pg_proc where oid='public.lister_planning_direction(timestamptz,integer,integer)'::regprocedure) then raise exception 'X2-16 RPC must be SECURITY DEFINER to avoid recursive groupes policies'; end if;
 if has_function_privilege('anon','public.lister_planning_direction(timestamptz,integer,integer)','EXECUTE') then raise exception 'X2-16 anon must not execute'; end if;
 if has_function_privilege('service_role','public.lister_planning_direction(timestamptz,integer,integer)','EXECUTE') then raise exception 'X2-16 service_role must not execute'; end if;
end $$;
set local role authenticated;
select set_config('test.uid','a1600000-0000-0000-0000-000000000001',true);
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0) where id='a16bbbbb-0000-0000-0000-000000000001'; if n<>1 then raise exception 'X2-16 admin expected target session'; end if; end $$;
select set_config('test.uid','a1600000-0000-0000-0000-000000000002',true);
select set_config('test.jwt','{"app_metadata":{"role":"controller"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0) where id='a16bbbbb-0000-0000-0000-000000000001'; if n<>1 then raise exception 'X2-16 controller expected target session'; end if; end $$;
select set_config('test.uid','a1600000-0000-0000-0000-000000000003',true);
select set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0); if n<>0 then raise exception 'X2-16 teacher must see zero sessions'; end if; end $$;
select set_config('test.uid','a1600000-0000-0000-0000-000000000004',true);
select set_config('test.jwt','{"app_metadata":{"role":"guardian"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0); if n<>0 then raise exception 'X2-16 guardian must see zero sessions'; end if; end $$;
select set_config('test.uid','a1600000-0000-0000-0000-000000000005',true);
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0); if n<>0 then raise exception 'X2-16 disabled admin must see zero sessions'; end if; end $$;
select set_config('test.uid','a1600000-0000-0000-0000-000000000006',true);
select set_config('test.jwt','{"app_metadata":{"role":"accountant"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0); if n<>0 then raise exception 'X2-16 accountant must see zero sessions'; end if; end $$;
select set_config('test.uid','a1600000-0000-0000-0000-000000000007',true);
select set_config('test.jwt','{"app_metadata":{"role":"student"}}',true);
do $$ declare n int; begin select count(*) into n from public.lister_planning_direction(date_trunc('week',now()),100,0); if n<>0 then raise exception 'X2-16 student must see zero sessions'; end if; end $$;
rollback;
