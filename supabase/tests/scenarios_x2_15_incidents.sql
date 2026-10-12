-- X2-15: la liste d'incidents reste sous les RLS de l'appelant.
begin;
insert into auth.users(id,email) values
 ('a1500000-0000-0000-0000-000000000001','x215-admin@test'),
 ('a1500000-0000-0000-0000-000000000002','x215-controller@test'),
 ('a1500000-0000-0000-0000-000000000003','x215-teacher@test'),
 ('a1500000-0000-0000-0000-000000000004','x215-guardian@test');
insert into public.households(id) values ('a15fffff-0000-0000-0000-000000000001');
insert into public.profiles(id,immutable_id,role,household_id,first_name,last_name,gender) values
 ('a1500000-0000-0000-0000-000000000001','ADM-X215-001','admin','a15fffff-0000-0000-0000-000000000001','Admin','Test','male'),
 ('a1500000-0000-0000-0000-000000000002','CTR-X215-001','controller','a15fffff-0000-0000-0000-000000000001','Control','Test','female'),
 ('a1500000-0000-0000-0000-000000000003','TEA-X215-001','teacher','a15fffff-0000-0000-0000-000000000001','Teach','Test','male'),
 ('a1500000-0000-0000-0000-000000000004','GUA-X215-001','guardian','a15fffff-0000-0000-0000-000000000001','Guard','Test','female');
update public.profiles
set account_status = case
  when role = 'teacher' then 'provisional_active'::public.account_status
  else 'active'::public.account_status
end
where id in (
 'a1500000-0000-0000-0000-000000000001',
 'a1500000-0000-0000-0000-000000000002',
 'a1500000-0000-0000-0000-000000000003',
 'a1500000-0000-0000-0000-000000000004'
);
insert into public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local) values
 ('a15aaaaa-0000-0000-0000-000000000001','a1500000-0000-0000-0000-000000000003','enfant',5,'Classe X215',1,9);
insert into public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,updated_at) values
 ('a15bbbbb-0000-0000-0000-000000000001','a1500000-0000-0000-0000-000000000003','a15aaaaa-0000-0000-0000-000000000001',now()-interval '1 hour',now()-interval '30 minutes','tech_failure',now());
do $$ begin
 if (select prosecdef from pg_proc where oid='public.lister_incidents_seances(timestamptz,integer,integer)'::regprocedure) then
   raise exception 'X2-15 RPC must be SECURITY INVOKER';
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
rollback;
