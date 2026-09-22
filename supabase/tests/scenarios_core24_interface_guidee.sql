-- Scenarios d'acceptation de l'Interface guidee.
-- A executer sur un replay complet des migrations, apres stub_auth.sql.

do $$
begin
  if to_regprocedure('public.demander_affichage_standard()') is null
     or to_regprocedure('public.activer_affichage_standard_tuteur(uuid)') is null
     or to_regprocedure('public.repondre_demande_affichage_standard(uuid,boolean)') is null
  then
    raise exception 'INTERFACE SECURISEE : RPC de demande/activation absente';
  end if;
  if has_column_privilege(
    'authenticated', 'public.student_profiles', 'interface_mode', 'UPDATE'
  ) then
    raise exception 'INTERFACE SECURISEE : le client ecrit directement interface_mode';
  end if;
  if has_function_privilege(
    'anon', 'public.activer_affichage_standard_tuteur(uuid)', 'EXECUTE'
  ) then
    raise exception 'INTERFACE SECURISEE : anon peut activer l affichage';
  end if;
end $$;

insert into auth.users (id, email)
values
  ('c2400000-0000-0000-0000-000000000001', 'interface-guardian@example.test'),
  ('c2400000-0000-0000-0000-000000000002', 'interface-student-request@example.test'),
  ('c2400000-0000-0000-0000-000000000003', 'interface-student-direct@example.test')
on conflict (id) do nothing;

insert into public.households (id, timezone)
values ('c2400000-0000-0000-0000-000000000010', 'Europe/Paris')
on conflict (id) do nothing;

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('c2400000-0000-0000-0000-000000000001', 'interface-guardian', 'guardian',
   'c2400000-0000-0000-0000-000000000010', 'Tuteur', 'Interface', 'active'),
  ('c2400000-0000-0000-0000-000000000002', 'interface-student-request', 'student',
   'c2400000-0000-0000-0000-000000000010', 'Demandeur', 'Interface', 'active'),
  ('c2400000-0000-0000-0000-000000000003', 'interface-student-direct', 'student',
   'c2400000-0000-0000-0000-000000000010', 'Direct', 'Interface', 'active')
on conflict (id) do nothing;

update public.households
set primary_guardian_id = 'c2400000-0000-0000-0000-000000000001'
where id = 'c2400000-0000-0000-0000-000000000010';

insert into public.student_profiles
  (profile_id, student_type, interface_mode, date_naissance)
values
  ('c2400000-0000-0000-0000-000000000002', 'minor', 'child',
   (current_date - interval '10 years')::date),
  ('c2400000-0000-0000-0000-000000000003', 'minor', 'child',
   (current_date - interval '10 years')::date)
on conflict (profile_id) do update
set date_naissance = excluded.date_naissance,
    interface_mode = 'child',
    interface_standard_request_status = 'none';

-- Cas 1 : l'enfant de 10 ans depose une demande, sans changer son interface.
select set_config('test.uid', 'c2400000-0000-0000-0000-000000000002', false);
select set_config(
  'test.jwt',
  '{"app_metadata":{"role":"student","household_id":"c2400000-0000-0000-0000-000000000010"}}',
  false
);
set role authenticated;
select public.demander_affichage_standard();
reset role;

do $$
begin
  if not exists (
    select 1 from public.student_profiles
    where profile_id = 'c2400000-0000-0000-0000-000000000002'
      and interface_mode = 'child'
      and interface_standard_request_status = 'pending'
  ) then
    raise exception 'INTERFACE DEMANDE : la demande enfant est incorrecte';
  end if;
end $$;

-- Cas 2 : le tuteur active directement le second profil, sans demande.
select set_config('test.uid', 'c2400000-0000-0000-0000-000000000001', false);
select set_config(
  'test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"c2400000-0000-0000-0000-000000000010"}}',
  false
);
set role authenticated;
select public.activer_affichage_standard_tuteur(
  'c2400000-0000-0000-0000-000000000003'
);
reset role;

do $$
begin
  if not exists (
    select 1 from public.student_profiles
    where profile_id = 'c2400000-0000-0000-0000-000000000003'
      and interface_mode = 'standard'
      and interface_standard_request_status = 'none'
  ) then
    raise exception 'INTERFACE DIRECTE : activation tuteur absente';
  end if;
end $$;

