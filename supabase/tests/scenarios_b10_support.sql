-- B-10 : canal de support lisible par un compte actif et modifiable par admin seul.
begin;

insert into auth.users (id, email) values
  ('b1000000-0000-0000-0000-000000000001', 'b10-admin@example.test'),
  ('b1000000-0000-0000-0000-000000000002', 'b10-student@example.test'),
  ('b1000000-0000-0000-0000-000000000003', 'b10-disabled@example.test');

insert into public.households (id, timezone)
values ('b10fffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b1000000-0000-0000-0000-000000000001', 'B10ADMIN000001', 'admin',
   'b10fffff-0000-0000-0000-000000000001', 'Support', 'Admin', 'active'),
  ('b1000000-0000-0000-0000-000000000002', 'B10STUDENT00001', 'student',
   'b10fffff-0000-0000-0000-000000000001', 'Support', 'Student', 'active'),
  ('b1000000-0000-0000-0000-000000000003', 'B10DISABLED0001', 'admin',
   'b10fffff-0000-0000-0000-000000000001', 'Disabled', 'Admin', 'disabled');

set local role authenticated;
select set_config('test.uid', 'b1000000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b10fffff-0000-0000-0000-000000000001"}}',
  true);
select public.configurer_canal_support('courriel', 'aide@example.test');

select set_config('test.uid', 'b1000000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"student","household_id":"b10fffff-0000-0000-0000-000000000001"}}',
  true);

do $b10_active_reader$
declare
  v_count integer;
  v_nature text;
  v_adresse text;
begin
  select count(*), min(nature), min(adresse)
    into v_count, v_nature, v_adresse
    from public.canal_support();
  if v_count <> 1 or v_nature <> 'courriel' or v_adresse <> 'aide@example.test' then
    raise exception 'B-10: active authenticated account must read the configured channel';
  end if;
end
$b10_active_reader$;

do $b10_student_cannot_configure$
begin
  begin
    perform public.configurer_canal_support('lien', 'https://help.example.test');
    raise exception 'B-10: student unexpectedly configured the support channel';
  exception when insufficient_privilege then
    null;
  end;
end
$b10_student_cannot_configure$;

select set_config('test.uid', 'b1000000-0000-0000-0000-000000000003', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b10fffff-0000-0000-0000-000000000001"}}',
  true);
do $b10_disabled_admin_cannot_configure$
begin
  begin
    perform public.configurer_canal_support('lien', 'https://help.example.test');
    raise exception 'B-10: disabled admin unexpectedly configured the support channel';
  exception when insufficient_privilege then
    null;
  end;
end
$b10_disabled_admin_cannot_configure$;

reset role;
rollback;
