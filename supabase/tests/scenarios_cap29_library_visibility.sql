-- CAP-29 §5.4 visibility regressions.
-- Run once after stub_auth.sql and every migration on a fresh disposable DB.

begin;

insert into auth.users (id, email) values
  ('c2910000-0000-0000-0000-000000000001', 'cap29-active-admin@example.test'),
  ('c2910000-0000-0000-0000-000000000002', 'cap29-active-teacher@example.test'),
  ('c2910000-0000-0000-0000-000000000003', 'cap29-disabled-admin@example.test');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('c2910000-0000-0000-0000-000000000001', 'ADMN-C29-100001', 'admin',
   null, 'Aminata', 'Ba', 'active', 'female'),
  ('c2910000-0000-0000-0000-000000000002', 'TEACH-C29-10001', 'teacher',
   null, 'Moussa', 'Sow', 'active', 'male'),
  ('c2910000-0000-0000-0000-000000000003', 'ADMN-C29-100003', 'admin',
   null, 'Kadiatou', 'Diallo', 'disabled', 'female');

select set_config('test.uid', 'c2910000-0000-0000-0000-000000000001', true);

insert into public.library_resource
  (id, title, short_title, resource_type, language, category,
   access_policy, offline_policy, archived_at)
values
  ('c29d0000-0000-0000-0000-000000000001', 'Public publie', 'Public', 'pdf',
   'fr', 'cours', 'publique', 'jamais', null),
  ('c29d0000-0000-0000-0000-000000000002', 'Brouillon public', 'Brouillon', 'pdf',
   'fr', 'cours', 'publique', 'jamais', null),
  ('c29d0000-0000-0000-0000-000000000003', 'Retire public', 'Retire', 'pdf',
   'fr', 'cours', 'publique', 'jamais', now()),
  ('c29d0000-0000-0000-0000-000000000004', 'Admin seulement', 'Admin', 'pdf',
   'fr', 'cours', 'admin', 'jamais', null),
  ('c29d0000-0000-0000-0000-000000000005', 'Versions', 'Versions', 'pdf',
   'fr', 'cours', 'publique', 'jamais', null);

insert into public.resource_version
  (id, resource_id, numero_version, empreinte)
values
  ('c29e0000-0000-0000-0000-000000000001',
   'c29d0000-0000-0000-0000-000000000001', 1, 'sha256-public'),
  ('c29e0000-0000-0000-0000-000000000002',
   'c29d0000-0000-0000-0000-000000000002', 1, 'sha256-draft'),
  ('c29e0000-0000-0000-0000-000000000003',
   'c29d0000-0000-0000-0000-000000000003', 1, 'sha256-retired'),
  ('c29e0000-0000-0000-0000-000000000004',
   'c29d0000-0000-0000-0000-000000000004', 1, 'sha256-admin'),
  ('c29e0000-0000-0000-0000-000000000005',
   'c29d0000-0000-0000-0000-000000000005', 1, 'sha256-old');

insert into public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, empreinte, origine)
values
  ('c29f0000-0000-0000-0000-000000000001',
   'c29e0000-0000-0000-0000-000000000001', 'pdf',
   'private/supports/c29f0000-0000-0000-0000-000000000001',
   2048, 'sha256-public', 'importe_tel_quel'),
  ('c29f0000-0000-0000-0000-000000000002',
   'c29e0000-0000-0000-0000-000000000002', 'pdf',
   'private/supports/c29f0000-0000-0000-0000-000000000002',
   2048, 'sha256-draft', 'importe_tel_quel');

update public.resource_version
   set download_asset_id = 'c29f0000-0000-0000-0000-000000000001'
 where id = 'c29e0000-0000-0000-0000-000000000001';
update public.resource_version
   set statut = 'publiee'
 where id in (
   'c29e0000-0000-0000-0000-000000000001',
   'c29e0000-0000-0000-0000-000000000003',
   'c29e0000-0000-0000-0000-000000000004',
   'c29e0000-0000-0000-0000-000000000005'
 );
update public.library_resource
   set current_version_id = case id
     when 'c29d0000-0000-0000-0000-000000000001' then 'c29e0000-0000-0000-0000-000000000001'::uuid
     when 'c29d0000-0000-0000-0000-000000000003' then 'c29e0000-0000-0000-0000-000000000003'::uuid
     when 'c29d0000-0000-0000-0000-000000000004' then 'c29e0000-0000-0000-0000-000000000004'::uuid
     when 'c29d0000-0000-0000-0000-000000000005' then 'c29e0000-0000-0000-0000-000000000005'::uuid
   end
 where id in (
   'c29d0000-0000-0000-0000-000000000001',
   'c29d0000-0000-0000-0000-000000000003',
   'c29d0000-0000-0000-0000-000000000004',
   'c29d0000-0000-0000-0000-000000000005'
 );
update public.library_resource
   set archived_at = now()
 where id = 'c29d0000-0000-0000-0000-000000000003';

insert into public.resource_version
  (id, resource_id, numero_version, empreinte)
values
  ('c29e0000-0000-0000-0000-000000000006',
   'c29d0000-0000-0000-0000-000000000005', 2, 'sha256-current');
update public.resource_version
   set statut = 'archivee'
 where id = 'c29e0000-0000-0000-0000-000000000005';
update public.resource_version
   set statut = 'publiee'
 where id = 'c29e0000-0000-0000-0000-000000000006';
update public.library_resource
   set current_version_id = 'c29e0000-0000-0000-0000-000000000006'
 where id = 'c29d0000-0000-0000-0000-000000000005';
set constraints all immediate;
set constraints all deferred;

-- Authenticated, active teacher: only current, active, non-admin resources and
-- versions. Raw download_asset storage keys remain hidden until licensed-use
-- records and per-use checks are available.
select set_config('test.uid', 'c2910000-0000-0000-0000-000000000002', true);
select set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
set local role authenticated;
do $$
declare
  v_resources int;
  v_versions int;
begin
  select count(*) into v_resources from public.library_resource;
  select count(*) into v_versions from public.resource_version;
  if v_resources <> 2 or v_versions <> 2 then
    raise exception 'CAP-29 teacher visibility expected resources=2 versions=2; got %, %',
      v_resources, v_versions;
  end if;
  begin
    perform 1 from public.download_asset;
    raise exception 'CAP-29 test failed: teacher can read storage keys directly';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;
reset role;

-- Active admin may inspect drafts and withdrawn records for review.
select set_config('test.uid', 'c2910000-0000-0000-0000-000000000001', true);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
declare
  v_resources int;
  v_versions int;
begin
  select count(*) into v_resources from public.library_resource;
  select count(*) into v_versions from public.resource_version;
  if v_resources <> 5 or v_versions <> 6 then
    raise exception 'CAP-29 admin visibility expected resources=5 versions=6; got %, %',
      v_resources, v_versions;
  end if;
  begin
    perform 1 from public.download_asset;
    raise exception 'CAP-29 test failed: admin can read storage keys directly';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;
reset role;

-- A disabled admin claim cannot outlive the server-side account state.
select set_config('test.uid', 'c2910000-0000-0000-0000-000000000003', true);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
declare
  v_resources int;
  v_versions int;
begin
  select count(*) into v_resources from public.library_resource;
  select count(*) into v_versions from public.resource_version;
  if v_resources <> 0 or v_versions <> 0 then
    raise exception 'CAP-29 disabled admin must see no library rows; got %, %',
      v_resources, v_versions;
  end if;
  begin
    perform 1 from public.download_asset;
    raise exception 'CAP-29 test failed: disabled admin can read storage keys directly';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;
reset role;

rollback;
