-- C-35: la cle d'objet n'est remise qu'a une session active autorisee,
-- sous son JWT; aucun SELECT direct ne révèle download_asset.cle_stockage.
-- PostgreSQL disposable uniquement; la transaction annule fixtures et audit.
begin;

-- scenarios_r2.sql accorde des privilèges de harnais generiques; retablir ici
-- la frontière que cette migration doit imposer en production.
revoke all on table public.download_asset from public, anon, authenticated, service_role, agent_ro;

insert into auth.users (id, email) values
  ('c3500000-0000-0000-0000-000000000001', 'c35-student@example.test'),
  ('c3500000-0000-0000-0000-000000000002', 'c35-reviewer@example.test'),
  ('c3500000-0000-0000-0000-000000000003', 'c35-outsider@example.test');
insert into public.households (id, timezone) values
  ('c35fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('c35fffff-0000-0000-0000-000000000002', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('c3500000-0000-0000-0000-000000000001', 'C35STUDENT000001', 'student',
   'c35fffff-0000-0000-0000-000000000001', 'C35', 'Student', 'active'),
  ('c3500000-0000-0000-0000-000000000002', 'C35ADMIN0000002', 'admin',
   'c35fffff-0000-0000-0000-000000000001', 'C35', 'Reviewer', 'active'),
  ('c3500000-0000-0000-0000-000000000003', 'C35STUDENT000003', 'student',
   'c35fffff-0000-0000-0000-000000000002', 'C35', 'Outsider', 'active');

insert into public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy)
values
  ('c3500000-0000-0000-0000-000000000011', 'C35 support', 'C35', 'pdf', 'publique', 'jamais');
insert into public.resource_version (id, resource_id, numero_version, statut)
values ('c3500000-0000-0000-0000-000000000012',
        'c3500000-0000-0000-0000-000000000011', 1, 'publiee');
insert into public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, origine)
values ('c3500000-0000-0000-0000-000000000013',
        'c3500000-0000-0000-0000-000000000012', 'pdf',
        'private/supports/c3500000-0000-0000-0000-000000000012', 128, 'importe_tel_quel');
update public.resource_version
   set download_asset_id = 'c3500000-0000-0000-0000-000000000013'
 where id = 'c3500000-0000-0000-0000-000000000012';
update public.library_resource
   set current_version_id = 'c3500000-0000-0000-0000-000000000012'
 where id = 'c3500000-0000-0000-0000-000000000011';
insert into public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution,
   approuve, revu_par, revu_le, resource_id)
values ('c3500000-0000-0000-0000-000000000012', 'Support de test', 'Titulaire de test',
        array['application'], 'Attribution de test', true,
        'c3500000-0000-0000-0000-000000000002', now(),
        'c3500000-0000-0000-0000-000000000011');

do $$
begin
  if has_table_privilege('authenticated', 'public.download_asset', 'SELECT')
     or has_table_privilege('agent_ro', 'public.download_asset', 'SELECT')
     or has_function_privilege('anon', 'public.autoriser_lecture_version(uuid)', 'EXECUTE')
     or has_function_privilege('service_role', 'public.autoriser_lecture_version(uuid)', 'EXECUTE')
     or has_function_privilege('agent_ro', 'public.autoriser_lecture_version(uuid)', 'EXECUTE') then
    raise exception 'C-35: privileges directs trop larges';
  end if;
end $$;

set local role authenticated;
select set_config('test.uid', 'c3500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"app_metadata":{"role":"student"}}', true);
select set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
do $$
declare
  v_key text;
begin
  begin
    perform cle_stockage from public.download_asset;
    raise exception 'C-35: SELECT direct download_asset accepte';
  exception when insufficient_privilege then null;
  end;
  v_key := public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000012');
  if v_key <> 'private/supports/c3500000-0000-0000-0000-000000000012' then
    raise exception 'C-35: la RPC n'a pas rendu la cle opaque attendue';
  end if;
  begin
    perform public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000099');
    raise exception 'C-35: une version inconnue a ete autorisee';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('test.uid', 'c3500000-0000-0000-0000-000000000003', true);
do $$
begin
  begin
    perform public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000012');
    raise exception 'C-35: l'acces d'un compte non autorise a ete accorde';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

do $$
declare
  v_count integer;
  v_payload text;
begin
  select count(*), max(payload::text)
    into v_count, v_payload
    from public.audit_logs
   where actor = 'c3500000-0000-0000-0000-000000000001'
     and action = 'library_read'
     and table_name = 'resource_version'
     and row_id = 'c3500000-0000-0000-0000-000000000012';
  if v_count <> 1 or v_payload like '%private/supports/%' or v_payload like '%url%' then
    raise exception 'C-35: audit absent, duplique ou contient une cle/URL';
  end if;
end $$;

rollback;
