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
insert into public.student_profiles(profile_id,student_type,interface_mode)
values ('c3500000-0000-0000-0000-000000000001','minor','child'),
       ('c3500000-0000-0000-0000-000000000003','minor','child');
insert into public.groupes
  (id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
values ('c3500000-0000-0000-0000-000000000021',
  'c3500000-0000-0000-0000-000000000002','enfant',5,'C35 groupe assigne',1,18,'Europe/Paris');
insert into public.groupe_membres(groupe_id,student_id)
values ('c3500000-0000-0000-0000-000000000021','c3500000-0000-0000-0000-000000000001');

insert into public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy)
values
  ('c3500000-0000-0000-0000-000000000011', 'C35 support', 'C35', 'pdf', 'groupe_assigne', 'jamais');
insert into public.resource_version (id, resource_id, numero_version, statut)
values ('c3500000-0000-0000-0000-000000000012',
        'c3500000-0000-0000-0000-000000000011', 1, 'brouillon');
insert into public.library_resource_groupe(resource_id,groupe_id)
values ('c3500000-0000-0000-0000-000000000011','c3500000-0000-0000-0000-000000000021');
insert into public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, origine)
values ('c3500000-0000-0000-0000-000000000013',
        'c3500000-0000-0000-0000-000000000012', 'pdf',
        'supports/c3500000-0000-0000-0000-000000000013/1/manuel.pdf', 128, 'importe_tel_quel');
update public.resource_version
   set download_asset_id = 'c3500000-0000-0000-0000-000000000013'
 where id = 'c3500000-0000-0000-0000-000000000012';


insert into public.library_resource
  (id, title, short_title, resource_type, access_policy, offline_policy)
values
  ('c3500000-0000-0000-0000-000000000014', 'C35 public', 'C35 public', 'pdf', 'publique', 'jamais'),
  ('c3500000-0000-0000-0000-000000000017', 'C35 inscrits', 'C35 inscrits', 'pdf', 'inscrits', 'jamais');
insert into public.resource_version (id, resource_id, numero_version, statut)
values
  ('c3500000-0000-0000-0000-000000000015', 'c3500000-0000-0000-0000-000000000014', 1, 'brouillon'),
  ('c3500000-0000-0000-0000-000000000018', 'c3500000-0000-0000-0000-000000000017', 1, 'brouillon');
insert into public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, origine)
values
  ('c3500000-0000-0000-0000-000000000016', 'c3500000-0000-0000-0000-000000000015', 'pdf',
   'supports/c3500000-0000-0000-0000-000000000016/1/public.pdf', 128, 'importe_tel_quel'),
  ('c3500000-0000-0000-0000-000000000019', 'c3500000-0000-0000-0000-000000000018', 'pdf',
   'supports/c3500000-0000-0000-0000-000000000019/1/inscrits.pdf', 128, 'importe_tel_quel');
update public.resource_version
   set download_asset_id = 'c3500000-0000-0000-0000-000000000016'
 where id = 'c3500000-0000-0000-0000-000000000015';
update public.resource_version
   set download_asset_id = 'c3500000-0000-0000-0000-000000000019'
 where id = 'c3500000-0000-0000-0000-000000000018';


insert into public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution,
   approuve, revu_par, revu_le)
values ('c3500000-0000-0000-0000-000000000012', 'Support de test', 'Titulaire de test',
        array['application'], 'Attribution de test', true,
        'c3500000-0000-0000-0000-000000000002', now());
insert into public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution,
   approuve, revu_par, revu_le)
values
  ('c3500000-0000-0000-0000-000000000015', 'Support public de test', 'Titulaire de test',
   array['application'], 'Attribution de test', true,
   'c3500000-0000-0000-0000-000000000002', now()),
  ('c3500000-0000-0000-0000-000000000018', 'Support inscrit de test', 'Titulaire de test',
   array['application'], 'Attribution de test', true,
   'c3500000-0000-0000-0000-000000000002', now());
-- CAP-29 : chaque version suit le cycle brouillon -> publiee avant le pointeur courant.
select set_config('request.jwt.claim.sub', 'c3500000-0000-0000-0000-000000000002', true);
update public.resource_version
   set statut = 'publiee'
 where id in ('c3500000-0000-0000-0000-000000000012',
             'c3500000-0000-0000-0000-000000000015',
             'c3500000-0000-0000-0000-000000000018');
update public.library_resource
   set current_version_id = 'c3500000-0000-0000-0000-000000000012'
 where id = 'c3500000-0000-0000-0000-000000000011';
update public.library_resource
   set current_version_id = 'c3500000-0000-0000-0000-000000000015'
 where id = 'c3500000-0000-0000-0000-000000000014';
update public.library_resource
   set current_version_id = 'c3500000-0000-0000-0000-000000000018'
 where id = 'c3500000-0000-0000-0000-000000000017';

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
select set_config('request.jwt.claim.sub', 'c3500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"c3500000-0000-0000-0000-000000000001","app_metadata":{"role":"student"}}', true);
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
  if v_key <> 'supports/c3500000-0000-0000-0000-000000000013/1/manuel.pdf' then
    raise exception 'C-35: la RPC n''a pas rendu le chemin de stockage attendu';
  end if;
  v_key := public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000015');
  if v_key <> 'supports/c3500000-0000-0000-0000-000000000016/1/public.pdf' then
    raise exception 'C-35: un élève autorisé ne lit pas la ressource publique';
  end if;
  v_key := public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000018');
  if v_key <> 'supports/c3500000-0000-0000-0000-000000000019/1/inscrits.pdf' then
    raise exception 'C-35: un élève authentifié ne lit pas la ressource inscrits';
  end if;
  begin
    perform public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000099');
    raise exception 'C-35: une version inconnue a ete autorisee';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;
-- Une cle d'une version publiee est immuable : la correction cree une nouvelle
-- version brouillon et son artefact, sans retoucher l'asset publie.
insert into public.resource_version (id, resource_id, numero_version, statut)
values ('c3500000-0000-0000-0000-000000000020',
        'c3500000-0000-0000-0000-000000000011', 2, 'brouillon');
insert into public.download_asset
  (id, resource_version_id, format, cle_stockage, taille_octets, origine)
values ('c3500000-0000-0000-0000-000000000022',
        'c3500000-0000-0000-0000-000000000020', 'pdf',
        'supports/c3500000-0000-0000-0000-000000000022/2/manuel.pdf', 128, 'importe_tel_quel');
update public.resource_version
   set download_asset_id = 'c3500000-0000-0000-0000-000000000022'
 where id = 'c3500000-0000-0000-0000-000000000020';
set local role authenticated;
select set_config('test.uid', 'c3500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.sub', 'c3500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"c3500000-0000-0000-0000-000000000001","app_metadata":{"role":"student"}}', true);
reset role;
select set_config('test.uid', 'c3500000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claim.sub', 'c3500000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"c3500000-0000-0000-0000-000000000003","app_metadata":{"role":"student"}}', true);
do $$
begin
  begin
    perform public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000012');
    raise exception 'C-35: l''acces d''un compte non autorise a ete accorde';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

update public.profiles set account_status = 'disabled'
 where id = 'c3500000-0000-0000-0000-000000000001';
set local role authenticated;
select set_config('test.uid', 'c3500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.sub', 'c3500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"c3500000-0000-0000-0000-000000000001","app_metadata":{"role":"student"}}', true);
select set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
do $c35_disabled_account_denied$
begin
  begin
    perform public.autoriser_lecture_version('c3500000-0000-0000-0000-000000000012');
    raise exception 'C-35: un compte desactive a pu lire une cle de stockage';
  exception when insufficient_privilege then null;
  end;
end
$c35_disabled_account_denied$;
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
  if v_count <> 1 or v_payload like '%supports/%' or v_payload like '%url%' then
    raise exception 'C-35: audit absent, duplique ou contient une cle/URL';
  end if;
end $$;

rollback;
