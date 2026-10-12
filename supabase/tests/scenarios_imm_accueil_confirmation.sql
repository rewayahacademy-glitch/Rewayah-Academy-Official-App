begin;

insert into auth.users (id, email) values
  ('ec100000-0000-0000-0000-000000000001', 'imm-confirm-admin@example.test'),
  ('ec100000-0000-0000-0000-000000000002', 'imm-confirm-teacher@example.test');
insert into public.households (id, timezone) values
  ('ec1fffff-ffff-ffff-ffff-000000000001', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('ec100000-0000-0000-0000-000000000001', 'ADM-IMM-CFM-000001', 'admin',
   'ec1fffff-ffff-ffff-ffff-000000000001', 'Admin', 'Fixture', 'active', 'female'),
  ('ec100000-0000-0000-0000-000000000002', 'TCH-IMM-CFM-000001', 'teacher',
   'ec1fffff-ffff-ffff-ffff-000000000001', 'TeachFirst', 'Fixture', 'provisional_active', 'male');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec100000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claims',
  '{"sub":"ec100000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}', true);

do $$
declare
  v_result jsonb;
  v_replay jsonb;
  v_unknown_email_rejected boolean := false;
  v_students_csv text := E'Email,Email du tuteur,Nom,Prénom,Date de naissance,Nom de l\'élève 1,Prénom de l\'élève 1,Date de naissance de l\'élève 1,Pour qui faites-vous cette inscription ?\r\nfamily@example.test,family@example.test,ParentLast,ParentFirst,01/01/1980,ChildLast,Lina,02/02/2015,Pour mon enfant\r\n';
  v_teachers_csv text := E'Horodateur,Prénom,Nom,Email\r\n2026-10-01,TeachFirst,TeacherLast,teacher@example.test\r\n';
begin
  v_result := public.confirmer_import_inscriptions(
    v_students_csv, v_teachers_csv,
    '[{"email":"family@example.test","a_patiente":true}]'::jsonb);
  if v_result->>'foyers_traites' <> '2'
     or v_result->>'foyers_crees' <> '2'
     or v_result->>'personnes_creees' <> '3'
     or v_result->>'personnes_deja_importees' <> '0'
     or v_result->>'journal_audit' <> 'true'
     or v_result::text like '%ParentFirst%'
     or v_result::text like '%family@example.test%' then
    raise exception 'unexpected confirmation result';
  end if;

  v_replay := public.confirmer_import_inscriptions(
    v_students_csv, v_teachers_csv,
    '[{"email":"family@example.test","a_patiente":true}]'::jsonb);
  if v_replay->>'foyers_traites' <> '2'
     or v_replay->>'foyers_crees' <> '0'
     or v_replay->>'personnes_creees' <> '0'
     or v_replay->>'personnes_deja_importees' <> '3' then
    raise exception 'identical confirmation replay was not idempotent';
  end if;

  begin
    perform public.confirmer_import_inscriptions(
      v_students_csv, v_teachers_csv,
      '[{"email":"absent@example.test","a_patiente":false}]'::jsonb);
  exception when sqlstate '22023' then
    v_unknown_email_rejected := true;
  end;
  if not v_unknown_email_rejected then
    raise exception 'option for a household absent from the accepted import was allowed';
  end if;
end;
$$;

reset role;

do $$
declare
  v_household_id uuid;
  v_audit_payload jsonb;
begin
  select id into v_household_id from private.preinscription_households
   where email_normalise = 'family@example.test';
  if v_household_id is null or not exists (
    select 1 from private.preinscription_households
     where id = v_household_id and status = 'confirmed' and a_patiente
       and welcomed_at is not null and waited_at is not null
       and mot_accueil like '%ParentFirst%Lina%'
       and mot_patience like '%ParentFirst%Lina%'
       and mot_patience like '%[Signature du directeur]%'
  ) then
    raise exception 'family welcome/patience state was not persisted';
  end if;
  if (select count(*) from private.preinscription_households) <> 2
     or (select count(*) from private.preinscription_persons) <> 3
     or not exists (
       select 1 from private.preinscription_persons
        where household_id = v_household_id and person_kind = 'student'
          and first_name = 'Lina' and last_name = 'ChildLast'
     )
     or not exists (
       select 1 from private.preinscription_persons p
       join private.preinscription_households h on h.id = p.household_id
        where h.email_normalise = 'teacher@example.test'
          and p.person_kind = 'teacher' and p.first_name = 'TeachFirst'
     ) then
    raise exception 'expected private household/person rows were not persisted';
  end if;
  select payload into v_audit_payload from public.audit_logs
   where action = 'preinscription_import_confirmed'
   order by created_at desc, id desc limit 1;
  if v_audit_payload is null
     or v_audit_payload->>'households_created' <> '0'
     or v_audit_payload->>'persons_created' <> '0'
     or v_audit_payload->>'persons_existing' <> '3'
     or v_audit_payload::text like '%ParentFirst%'
     or v_audit_payload::text like '%family@example.test%' then
    raise exception 'audit payload does not contain counters only';
  end if;
  if (select count(*) from public.audit_logs
       where action = 'preinscription_import_confirmed') <> 2 then
    raise exception 'expected one audit entry per successful confirmation';
  end if;
end;
$$;

set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec100000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims',
  '{"sub":"ec100000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{"role":"teacher"}}', true);
do $$
declare v_rejected boolean := false;
begin
  begin
    perform public.confirmer_import_inscriptions('', '', '[]'::jsonb);
  exception when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then raise exception 'non-admin user executed confirmation RPC'; end if;
end;
$$;
reset role;

update public.profiles set account_status = 'disabled'
 where id = 'ec100000-0000-0000-0000-000000000001';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec100000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims',
  '{"sub":"ec100000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}', true);
do $$
declare v_rejected boolean := false;
begin
  begin
    perform public.confirmer_import_inscriptions('', '', '[]'::jsonb);
  exception when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then raise exception 'disabled admin executed confirmation RPC'; end if;
end;
$$;
reset role;
update public.profiles set account_status = 'active'
 where id = 'ec100000-0000-0000-0000-000000000001';

set local role anon;
do $$
declare v_rejected boolean := false;
begin
  begin
    perform public.confirmer_import_inscriptions('', '', '[]'::jsonb);
  exception when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then raise exception 'anon executed confirmation RPC'; end if;
end;
$$;
reset role;

set local role service_role;
do $$
declare v_rejected boolean := false;
begin
  begin
    perform public.confirmer_import_inscriptions('', '', '[]'::jsonb);
  exception when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then raise exception 'service_role executed confirmation RPC'; end if;
end;
$$;
reset role;

rollback;
