begin;

insert into auth.users (id, email) values
  ('ec000000-0000-0000-0000-000000000001', 'imm-accueil-admin@example.test'),
  ('ec000000-0000-0000-0000-000000000002', 'imm-accueil-teacher@example.test'),
  ('ec000000-0000-0000-0000-000000000003', 'imm-accueil-no-profile@example.test');
insert into public.households (id, timezone) values
  ('ecffffff-ffff-ffff-ffff-000000000001', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('ec000000-0000-0000-0000-000000000001', 'ADM-IMM-ACC-000001', 'admin',
   'ecffffff-ffff-ffff-ffff-000000000001', 'Admin', 'Fixture', 'active', 'female'),
  ('ec000000-0000-0000-0000-000000000002', 'TCH-IMM-ACC-000001', 'teacher',
   'ecffffff-ffff-ffff-ffff-000000000001', 'Teacher', 'Fixture', 'provisional_active', 'male');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claims',
  '{"sub":"ec000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}', true);

do $$
declare
  report jsonb;
  repeated_header_report jsonb;
  invalid_date_report jsonb;
  malformed_csv_rejected boolean := false;
  non_admin_rejected boolean := false;
begin
  report := public.previsualiser_import_inscriptions(
    E'Email,Nom,Prénom,Genre,Email,Date de naissance\r\nparent@example.test,"Nom, composé",Lina,F,parent@example.test,01/02/2010\r\nparent@example.test,Deuxième,Enfant,F,parent@example.test,02/03/2012\r\nparent@example.test,TEST ROW,Test,F,parent@example.test,03/04/2014\r\n,,,,,\r\n',
    E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n2026-10-02,Sam,Prof,\r\n2026-10-03,Sam,Prof2,parent@example.test\r\n');
  if report->>'foyers' <> '1' or report->>'personnes' <> '4'
     or report->>'doublons' <> '2' or report->>'lignes_rejetees' <> '3'
     or report->>'ecriture_effectuee' <> 'false' then
    raise exception 'unexpected dry-run report: %', report;
  end if;
  repeated_header_report := public.previsualiser_import_inscriptions(
    E'Email,Nom,Prénom,Nom,Prénom\r\nsecond@example.test,Dupont,,Martin,Julie\r\n',
    E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  if repeated_header_report->>'foyers' <> '1'
     or repeated_header_report->>'personnes' <> '2'
     or repeated_header_report->>'lignes_rejetees' <> '0' then
    raise exception 'repeated headers were not paired by occurrence: %', repeated_header_report;
  end if;
  invalid_date_report := public.previsualiser_import_inscriptions(
    E'Email,Nom,Prénom,Date de naissance\r\ndate@example.test,Nom,Prénom,31/02/2010\r\n',
    E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  if invalid_date_report->>'foyers' <> '0'
     or invalid_date_report->>'personnes' <> '1'
     or invalid_date_report->>'lignes_rejetees' <> '1' then
    raise exception 'invalid birth date was not rejected: %', invalid_date_report;
  end if;
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\r\na@example.test,"Nom"x,Lina\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when sqlstate '22023' then
    malformed_csv_rejected := true;
  end;
  if not malformed_csv_rejected then raise exception 'malformed quoted CSV was accepted'; end if;
  perform set_config('request.jwt.claim.sub', 'ec000000-0000-0000-0000-000000000002', true);
  perform set_config('request.jwt.claims',
    '{"sub":"ec000000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{"role":"teacher"}}', true);
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\na@example.test,Nom,Prénom\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when insufficient_privilege then
    non_admin_rejected := true;
  end;
  if not non_admin_rejected then raise exception 'non-admin user was allowed to preview import'; end if;
end;
$$;

reset role;

-- An admin claim alone cannot replace an active profile or account status.
update public.profiles set account_status = 'disabled'
 where id = 'ec000000-0000-0000-0000-000000000001';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims',
  '{"sub":"ec000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}', true);
do $$
declare rejected boolean := false;
begin
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\na@example.test,Nom,Prénom\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when insufficient_privilege then rejected := true;
  end;
  if not rejected then raise exception 'disabled admin was allowed to preview import'; end if;
end;
$$;
reset role;
update public.profiles set account_status = 'active'
 where id = 'ec000000-0000-0000-0000-000000000001';

-- A JWT claiming admin without a matching profile is also denied.
set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec000000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims',
  '{"sub":"ec000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}', true);
do $$
declare rejected boolean := false;
begin
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\na@example.test,Nom,Prénom\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when insufficient_privilege then rejected := true;
  end;
  if not rejected then raise exception 'admin without profile was allowed to preview import'; end if;
end;
$$;
reset role;

-- A caller on the authenticated role still needs a user identity.
set local role authenticated;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims',
  '{"role":"authenticated","app_metadata":{"role":"admin"}}', true);
do $$
declare rejected boolean := false;
begin
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\na@example.test,Nom,Prénom\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when insufficient_privilege then rejected := true;
  end;
  if not rejected then raise exception 'authenticated caller without uid was allowed to preview import'; end if;
end;
$$;
reset role;

-- The RPC is denied to anon and service_role by its execute ACL.
set local role anon;
do $$
declare rejected boolean := false;
begin
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\na@example.test,Nom,Prénom\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when insufficient_privilege then rejected := true;
  end;
  if not rejected then raise exception 'anon role was allowed to preview import'; end if;
end;
$$;
reset role;

set local role service_role;
do $$
declare rejected boolean := false;
begin
  begin
    perform public.previsualiser_import_inscriptions(
      E'Email,Nom,Prénom\na@example.test,Nom,Prénom\r\n',
      E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,Prof,Enseignant,teacher@example.test\r\n');
  exception when insufficient_privilege then rejected := true;
  end;
  if not rejected then raise exception 'service_role was allowed to preview import'; end if;
end;
$$;
reset role;

do $$
begin
  if has_table_privilege('authenticated', 'private.preinscription_households', 'select')
     or has_table_privilege('service_role', 'private.preinscription_persons', 'insert')
     or has_function_privilege('anon', 'public.previsualiser_import_inscriptions(text,text)', 'execute')
     or has_function_privilege('service_role', 'public.previsualiser_import_inscriptions(text,text)', 'execute') then
    raise exception 'pre-registration tables or RPC are exposed';
  end if;
end;
$$;

do $$
begin
  if (select count(*) from private.preinscription_households) <> 0
     or (select count(*) from private.preinscription_persons) <> 0 then
    raise exception 'dry-run wrote pre-registration rows';
  end if;
end;
$$;

rollback;
