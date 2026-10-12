-- RECH-BACK-3: exact lookup, uniform empty results and shared account quota.
begin;

insert into auth.users (id, email) values
  ('a3300000-0000-0000-0000-000000000001', 'rech3-owner@example.test'),
  ('a3300000-0000-0000-0000-000000000002', 'rech3-outsider@example.test');
insert into public.households (id, timezone) values
  ('a33fffff-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('a33fffff-0000-0000-0000-000000000002', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('a3300000-0000-0000-0000-000000000001', null, 'guardian',
   'a33fffff-0000-0000-0000-000000000001', 'Owner', 'Fixture', 'active'),
  ('a3300000-0000-0000-0000-000000000002', null, 'guardian',
   'a33fffff-0000-0000-0000-000000000002', 'Outside', 'Fixture', 'active');

do $exact_lookup$
declare
  v_owner_code text;
  v_outside_code text;
  v_rows integer;
  v_authz bigint;
begin
  select immutable_id into v_owner_code from public.profiles
   where id = 'a3300000-0000-0000-0000-000000000001';
  select immutable_id into v_outside_code from public.profiles
   where id = 'a3300000-0000-0000-0000-000000000002';

  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims', '{}', true);
  if exists (select 1 from public.rechercher_personne_par_matricule(v_owner_code)) then
    raise exception 'RECH-03: unauthenticated lookup returned a row';
  end if;

  perform set_config('request.jwt.claim.sub', 'a3300000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a3300000-0000-0000-0000-000000000001',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a33fffff-0000-0000-0000-000000000001',
      'authorization_version', 1
    )
  )::text, true);
  update public.profiles set account_status = 'suspended'
   where id = 'a3300000-0000-0000-0000-000000000001';
  if exists (select 1 from public.rechercher_personne_par_matricule(v_owner_code)) then
    raise exception 'RECH-03: inactive account lookup returned a row';
  end if;
  update public.profiles set account_status = 'active'
   where id = 'a3300000-0000-0000-0000-000000000001';
  select authorization_version into v_authz from public.profiles
   where id = 'a3300000-0000-0000-0000-000000000001';
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a3300000-0000-0000-0000-000000000001',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a33fffff-0000-0000-0000-000000000001',
      'authorization_version', v_authz
    )
  )::text, true);

  select count(*) into v_rows
    from public.rechercher_personne_par_matricule(lower(replace(v_owner_code, '-', ' '))) r
   where r.profile_id = 'a3300000-0000-0000-0000-000000000001'
     and r.matricule = v_owner_code;
  if v_rows <> 1
     or exists (select 1 from public.rechercher_personne_par_matricule(v_outside_code))
     or exists (select 1 from public.rechercher_personne_par_matricule('RA-99-0000'))
     or exists (select 1 from public.rechercher_personne_par_matricule('RA-O1-12I4'))
     or exists (select 1 from public.rechercher_personne_par_matricule('R-A--99--0000')) then
    raise exception 'RECH-03: exact lookup or identical empty outcomes are incorrect';
  end if;
end;
$exact_lookup$;

do $quota$
declare
  v_owner_code text;
  v_rows integer;
  v_attempt integer;
  v_bucket text := 'rech:all:' || md5('a3300000-0000-0000-0000-000000000001');
  v_refill_anchor timestamptz;
  v_authz bigint;
  v_d1_response jsonb;
begin
  -- Reset only this synthetic actor so the burst boundary is deterministic.
  delete from public.rate_limits where bucket = v_bucket;
  select immutable_id into v_owner_code from public.profiles
   where id = 'a3300000-0000-0000-0000-000000000001';
  select authorization_version into v_authz from public.profiles
   where id = 'a3300000-0000-0000-0000-000000000001';

  perform set_config('request.jwt.claim.sub', 'a3300000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'a3300000-0000-0000-0000-000000000001',
    'role', 'authenticated',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'a33fffff-0000-0000-0000-000000000001',
      'authorization_version', v_authz
    )
  )::text, true);

  select count(*) into v_rows
    from public.rechercher_personne_par_matricule(v_owner_code);
  if v_rows <> 1 then
    raise exception 'RECH-03: first exact lookup should consume one token and return self';
  end if;
  update public.rate_limits
     set updated_at = pg_catalog.statement_timestamp() + interval '1 day'
   where bucket = v_bucket;
  perform public.rech_d1_rechercher_classes('synthetic query', null, 20);
  perform public.rech_d1_rechercher_supports('synthetic query', null, 20);
  if (select tokens from public.rate_limits where bucket = v_bucket) <> 17.0 then
    raise exception 'RECH-03: D1 did not consume the person-domain shared quota';
  end if;
  delete from public.rate_limits where bucket = v_bucket;
  select count(*) into v_rows
    from public.rechercher_personne_par_matricule(v_owner_code);
  if v_rows <> 1 then
    raise exception 'RECH-03: exact lookup should return after a fixture reset';
  end if;
  update public.rate_limits
     set updated_at = pg_catalog.statement_timestamp() + interval '1 day'
   where bucket = v_bucket;
  for v_attempt in 1..19 loop
    if exists (
      select 1 from public.rechercher_personne_par_matricule('RA-99-0000')
    ) then
      raise exception 'RECH-03: unknown exact code unexpectedly resolved';
    end if;
  end loop;
  select updated_at into v_refill_anchor from public.rate_limits where bucket = v_bucket;
  if exists (select 1 from public.rechercher_personne_par_matricule(v_owner_code)) then
    raise exception 'RECH-03: 21st request was not rate-limited';
  end if;
  select public.rech_d1_rechercher_classes('synthetic query', null, 20)
    into v_d1_response;
  if v_d1_response <> jsonb_build_object(
       'items', '[]'::jsonb, 'has_more', false, 'next_cursor', null
     ) then
    raise exception 'RECH-03: quota-denied D1 response did not keep the empty shape';
  end if;
  if (select tokens from public.rate_limits where bucket = v_bucket) > 0
     or v_refill_anchor is null
     or (select updated_at from public.rate_limits where bucket = v_bucket)
          is distinct from v_refill_anchor
     or (select count(*) from public.rate_limits
          where bucket like 'rech:all:%'
            and bucket <> v_bucket) > 0
     or has_function_privilege('anon', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or has_function_privilege('service_role', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.rech_recherche_quota_ok()', 'EXECUTE') then
    raise exception 'RECH-03: quota storage or RPC ACL is incorrect';
  end if;

  -- A half-token refill stays partial across repeated denials; the same
  -- elapsed interval must not be counted twice.
  update public.rate_limits
     set tokens = 0,
         updated_at = pg_catalog.statement_timestamp() - interval '5 seconds'
   where bucket = v_bucket;
  if private.rech_recherche_quota_ok() then
    raise exception 'RECH-03: five-second refill granted a full token';
  end if;
  if private.rech_recherche_quota_ok() then
    raise exception 'RECH-03: denied retry double-counted the same refill interval';
  end if;
  if (select tokens from public.rate_limits where bucket = v_bucket) < 0.49
     or (select tokens from public.rate_limits where bucket = v_bucket) > 0.51 then
    raise exception 'RECH-03: partial refill was not preserved with its new anchor';
  end if;

  update public.rate_limits
     set tokens = 0,
         updated_at = pg_catalog.statement_timestamp() - interval '10 seconds'
   where bucket = v_bucket;
  if not private.rech_recherche_quota_ok() then
    raise exception 'RECH-03: account quota did not refill after ten seconds';
  end if;
end;
$quota$;

rollback;
