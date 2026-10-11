-- B-09 : boîte de notifications privée, lecture par destinataire et accusé borné.
-- Base PostgreSQL jetable après rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('b0900000-0000-0000-0000-000000000001', 'b09-recipient-a@example.test'),
  ('b0900000-0000-0000-0000-000000000002', 'b09-recipient-b@example.test');

insert into public.households (id, timezone)
values ('b09fffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('b0900000-0000-0000-0000-000000000001', 'B09RECIPIENTA01', 'guardian',
   'b09fffff-0000-0000-0000-000000000001', 'Recipient', 'A', 'active'),
  ('b0900000-0000-0000-0000-000000000002', 'B09RECIPIENTB01', 'guardian',
   'b09fffff-0000-0000-0000-000000000001', 'Recipient', 'B', 'active');

insert into public.notifications
  (id, destinataire, foyer_id, evenement, params, destination)
values
  ('b09fffff-0000-0000-0000-000000000002',
   'b0900000-0000-0000-0000-000000000001',
   'b09fffff-0000-0000-0000-000000000001',
   'demande_recue', '{}', '/tuteur/demandes'),
  ('b09fffff-0000-0000-0000-000000000003',
   'b0900000-0000-0000-0000-000000000002',
   'b09fffff-0000-0000-0000-000000000001',
   'classe_validee', '{}', '/tuteur/demandes');

set local role authenticated;
select set_config('test.uid', 'b0900000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b09fffff-0000-0000-0000-000000000001"}}',
  true);

do $b09_recipient_only$
declare
  v_count integer;
  v_changed integer;
begin
  if not pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'SELECT')
     or pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'INSERT')
     or pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'UPDATE')
     or pg_catalog.has_table_privilege('authenticated', 'public.notifications', 'DELETE')
     or pg_catalog.has_table_privilege('anon', 'public.notifications', 'SELECT') then
    raise exception 'B-09: table privileges do not match the read-only client contract';
  end if;

  select count(*) into v_count from public.notifications;
  if v_count <> 1 then
    raise exception 'B-09: recipient must see only their own notification';
  end if;

  update public.notifications
     set lu_le = pg_catalog.now()
   where id = 'b09fffff-0000-0000-0000-000000000003';
  get diagnostics v_changed = row_count;
  if v_changed <> 0 then
    raise exception 'B-09: a recipient changed another profile notification';
  end if;

  begin
    delete from public.notifications
     where id = 'b09fffff-0000-0000-0000-000000000002';
    raise exception 'B-09: client delete was accepted';
  exception when insufficient_privilege then
    null;
  end;

  update public.notifications
     set lu_le = pg_catalog.now()
   where id = 'b09fffff-0000-0000-0000-000000000002';
  get diagnostics v_changed = row_count;
  if v_changed <> 1 then
    raise exception 'B-09: recipient could not acknowledge own notification';
  end if;
end
$b09_recipient_only$;

reset role;
do $b09_read_marker$
declare
  v_read_at timestamptz;
  v_other_read_at timestamptz;
begin
  select lu_le into v_read_at from public.notifications
   where id = 'b09fffff-0000-0000-0000-000000000002';
  select lu_le into v_other_read_at from public.notifications
   where id = 'b09fffff-0000-0000-0000-000000000003';
  if v_read_at is null or v_other_read_at is not null then
    raise exception 'B-09: read acknowledgement changed the wrong row';
  end if;
end
$b09_read_marker$;

set local role anon;
do $b09_anonymous_denied$
begin
  begin
    perform 1 from public.notifications;
    raise exception 'B-09: anonymous reads were accepted';
  exception when insufficient_privilege then
    null;
  end;
end
$b09_anonymous_denied$;

reset role;
rollback;
