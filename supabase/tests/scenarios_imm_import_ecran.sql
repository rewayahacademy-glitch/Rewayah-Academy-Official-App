-- IMM-ACCUEIL-FRONT : capacites_import_inscriptions().
-- L'import n'est offert qu'a la direction active en aal2 ; sans jeton, refus ;
-- un enseignant ne l'a pas ; anon n'a aucun droit d'execution.
begin;

insert into auth.users (id, email) values
  ('ec200000-0000-0000-0000-000000000001', 'imm-ecran-admin@example.test'),
  ('ec200000-0000-0000-0000-000000000002', 'imm-ecran-teacher@example.test');
insert into public.households (id, timezone) values
  ('ec2fffff-ffff-ffff-ffff-000000000001', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('ec200000-0000-0000-0000-000000000001', 'ADM-IMM-ECR-000001', 'admin',
   'ec2fffff-ffff-ffff-ffff-000000000001', 'Admin', 'Fixture', 'active', 'female'),
  ('ec200000-0000-0000-0000-000000000002', 'TCH-IMM-ECR-000001', 'teacher',
   'ec2fffff-ffff-ffff-ffff-000000000001', 'Teacher', 'Fixture', 'provisional_active', 'male');

do $$
begin
  if has_function_privilege('anon', 'public.capacites_import_inscriptions()', 'execute')
     or has_function_privilege('service_role', 'public.capacites_import_inscriptions()', 'execute')
     or not has_function_privilege('authenticated', 'public.capacites_import_inscriptions()', 'execute') then
    raise exception 'ACL de capacites_import_inscriptions incorrecte';
  end if;
  raise notice 'OK acl capacites_import_inscriptions';
end $$;

set local role authenticated;

-- Direction en aal2 : peut importer.
select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal2","app_metadata":{"role":"admin"}}', true);
do $$
declare r jsonb := public.capacites_import_inscriptions();
begin
  if r->>'peutImporter' <> 'true' or r->>'doubleVerificationRequise' <> 'false'
     or (r->>'ageMinimum')::int <> (select min(age_min) from public.cohortes_age where actif)
     or (r->>'ageAdulte')::int <> (select age_min from public.cohortes_age where actif and type_public = 'adulte' limit 1) then
    raise exception 'admin aal2 : %', r;
  end if;
  raise notice 'OK direction aal2 peut importer';
end $$;

-- Direction en aal1 : ne peut pas, et le serveur dit pourquoi.
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000001","role":"authenticated","aal":"aal1","app_metadata":{"role":"admin"}}', true);
do $$
declare r jsonb := public.capacites_import_inscriptions();
begin
  if r->>'peutImporter' <> 'false' or r->>'doubleVerificationRequise' <> 'true' then
    raise exception 'admin aal1 : %', r;
  end if;
  raise notice 'OK direction aal1 : double verification requise';
end $$;

-- Enseignant, meme en aal2 : aucune capacite, et aucune indication sur la direction.
select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000002","role":"authenticated","aal":"aal2","app_metadata":{"role":"teacher"}}', true);
do $$
declare r jsonb := public.capacites_import_inscriptions();
begin
  if r->>'peutImporter' <> 'false' or r->>'doubleVerificationRequise' <> 'false'
     or r->'ageMinimum' <> 'null'::jsonb then
    raise exception 'enseignant : %', r;
  end if;
  raise notice 'OK enseignant sans capacite';
end $$;

-- Sans jeton : refus.
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{"role":"authenticated"}', true);
do $$
declare refuse boolean := false;
begin
  begin
    perform public.capacites_import_inscriptions();
  exception when sqlstate '42501' then refuse := true;
  end;
  if not refuse then raise exception 'sans jeton : accepte'; end if;
  raise notice 'OK sans jeton refuse';
end $$;

rollback;
