-- CAP-29 §4.2/§5.1 acceptance scenarios for immutable published versions.
-- Run once after stub_auth.sql and all migrations on a fresh disposable DB.
-- No R2 credentials or remote project are needed.

begin;

insert into auth.users (id, email) values
  ('c2900000-0000-0000-0000-000000000001', 'cap29-version-admin@example.test');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('c2900000-0000-0000-0000-000000000001', 'ADMN-C29-000001', 'admin',
   null, 'Amadou', 'Ba', 'active', 'male');

select set_config('test.uid', 'c2900000-0000-0000-0000-000000000001', true);

insert into public.library_resource
  (id, title, short_title, resource_type, language, category,
   access_policy, offline_policy)
values
  ('c29a0000-0000-0000-0000-000000000001', 'Support A', 'A', 'pdf',
   'fr', 'cours', 'admin', 'jamais'),
  ('c29a0000-0000-0000-0000-000000000002', 'Support B', 'B', 'pdf',
   'fr', 'cours', 'admin', 'jamais');

insert into public.resource_version
  (id, resource_id, numero_version, empreinte)
values
  ('c29b0000-0000-0000-0000-000000000001',
   'c29a0000-0000-0000-0000-000000000001', 1, 'sha256-a'),
  ('c29b0000-0000-0000-0000-000000000002',
   'c29a0000-0000-0000-0000-000000000002', 1, 'sha256-b');

insert into public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, empreinte, origine)
values
  ('c29c0000-0000-0000-0000-000000000001',
   'c29b0000-0000-0000-0000-000000000001', 'pdf',
   'private/supports/c29c0000-0000-0000-0000-000000000001',
   1024, 'sha256-a', 'importe_tel_quel');

update public.resource_version
   set download_asset_id = 'c29c0000-0000-0000-0000-000000000001'
 where id = 'c29b0000-0000-0000-0000-000000000001';

-- A pointer to a draft must fail immediately.
do $$
begin
  begin
    update public.library_resource
       set current_version_id = 'c29b0000-0000-0000-0000-000000000001'
     where id = 'c29a0000-0000-0000-0000-000000000001';
    raise exception 'CAP-29 test failed: draft became current';
  exception when check_violation then
    null;
  end;

  begin
    update public.resource_version
       set statut = 'archivee'
     where id = 'c29b0000-0000-0000-0000-000000000002';
    raise exception 'CAP-29 test failed: draft archived without publication';
  exception when check_violation then
    null;
  end;

  begin
    update public.resource_version
       set statut = 'publiee'
     where id = 'c29b0000-0000-0000-0000-000000000002';
    set constraints all immediate;
    raise exception 'CAP-29 test failed: published version without current pointer';
  exception when check_violation then
    null;
  end;
end;
$$;
set constraints all deferred;

-- Cross-resource pointers fail even if the referenced version is published.
update public.resource_version
   set statut = 'publiee'
 where id = 'c29b0000-0000-0000-0000-000000000001';
update public.library_resource
   set current_version_id = 'c29b0000-0000-0000-0000-000000000001'
 where id = 'c29a0000-0000-0000-0000-000000000001';
set constraints all immediate;
set constraints all deferred;

do $$
begin
  begin
    update public.library_resource
       set current_version_id = 'c29b0000-0000-0000-0000-000000000001'
     where id = 'c29a0000-0000-0000-0000-000000000002';
    raise exception 'CAP-29 test failed: cross-resource pointer accepted';
  exception when foreign_key_violation then
    null;
  end;

  begin
    update public.resource_version
       set empreinte = 'tampered'
     where id = 'c29b0000-0000-0000-0000-000000000001';
    raise exception 'CAP-29 test failed: published hash changed';
  exception when check_violation then
    null;
  end;

  begin
    update public.download_asset
       set empreinte = 'tampered'
     where id = 'c29c0000-0000-0000-0000-000000000001';
    raise exception 'CAP-29 test failed: published asset changed';
  exception when check_violation then
    null;
  end;

  begin
    delete from public.resource_version
     where id = 'c29b0000-0000-0000-0000-000000000001';
    raise exception 'CAP-29 test failed: published version deleted';
  exception when check_violation then
    null;
  end;

  begin
    update public.library_resource
       set current_version_id = null
     where id = 'c29a0000-0000-0000-0000-000000000001';
    set constraints all immediate;
    raise exception 'CAP-29 test failed: active resource lost its publication';
  exception when check_violation then
    null;
  end;
end;
$$;
set constraints all deferred;

-- Supersession is valid only as one transaction: archive old, publish draft,
-- then update the pointer. The old bytes/hash remain immutable.
insert into public.resource_version
  (id, resource_id, numero_version, empreinte)
values
  ('c29b0000-0000-0000-0000-000000000003',
   'c29a0000-0000-0000-0000-000000000001', 2, 'sha256-a2');

update public.resource_version
   set statut = 'archivee'
 where id = 'c29b0000-0000-0000-0000-000000000001';
update public.resource_version
   set statut = 'publiee'
 where id = 'c29b0000-0000-0000-0000-000000000003';
update public.library_resource
   set current_version_id = 'c29b0000-0000-0000-0000-000000000003'
 where id = 'c29a0000-0000-0000-0000-000000000001';
set constraints all immediate;

do $$
declare
  v_current uuid;
  v_old_status public.statut_version_ressource;
  v_new_actor uuid;
begin
  select current_version_id into v_current
    from public.library_resource
   where id = 'c29a0000-0000-0000-0000-000000000001';
  select statut into v_old_status
    from public.resource_version
   where id = 'c29b0000-0000-0000-0000-000000000001';
  select publiee_par into v_new_actor
    from public.resource_version
   where id = 'c29b0000-0000-0000-0000-000000000003';

  if v_current <> 'c29b0000-0000-0000-0000-000000000003'
     or v_old_status <> 'archivee'
     or v_new_actor <> 'c2900000-0000-0000-0000-000000000001' then
    raise exception 'CAP-29 test failed: atomic version supersession inconsistent';
  end if;
end;
$$;

-- Withdrawal archives the resource and clears its current pointer atomically.
update public.resource_version
   set statut = 'archivee'
 where id = 'c29b0000-0000-0000-0000-000000000003';
update public.library_resource
   set archived_at = now(), current_version_id = null
 where id = 'c29a0000-0000-0000-0000-000000000001';
set constraints all immediate;

rollback;
