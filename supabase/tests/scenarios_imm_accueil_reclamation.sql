begin;

insert into auth.users (id, email, email_confirmed_at) values
  ('ec200000-0000-0000-0000-000000000001', 'family@example.test', null),
  ('ec200000-0000-0000-0000-000000000002', 'unknown@example.test', null);
insert into private.preinscription_households
  (id, email_normalise, status, welcomed_at, a_patiente, waited_at, mot_accueil, mot_patience)
values
  ('ec2fffff-ffff-ffff-ffff-000000000001', 'family@example.test', 'confirmed',
   now(), true, now(), 'Bonjour ParentFirst, bienvenue avec Lina.', 'Merci ParentFirst et Lina.');
insert into private.preinscription_persons
  (id, household_id, person_kind, first_name, last_name, source_row)
values
  ('ec200000-ffff-ffff-ffff-000000000001', 'ec2fffff-ffff-ffff-ffff-000000000001',
   'guardian', 'ParentFirst', 'ParentLast', 2),
  ('ec200000-ffff-ffff-ffff-000000000002', 'ec2fffff-ffff-ffff-ffff-000000000001',
   'student', 'Lina', 'ChildLast', 2);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000001","role":"authenticated"}', true);
do $$
declare v_known_unverified jsonb;
begin
  v_known_unverified := public.reclamer_preinscription_apres_preuve();
  if v_known_unverified <> '{"email_prouve":false,"inscription_connue":false}'::jsonb
     or v_known_unverified::text like '%ParentFirst%'
     or v_known_unverified::text like '%family@example.test%' then
    raise exception 'unverified email received pre-registration information';
  end if;
end;
$$;

select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000002","role":"authenticated"}', true);
do $$
declare v_unknown_unverified jsonb;
begin
  v_unknown_unverified := public.reclamer_preinscription_apres_preuve();
  if v_unknown_unverified <> '{"email_prouve":false,"inscription_connue":false}'::jsonb then
    raise exception 'unverified known/unknown response is not neutral';
  end if;
end;
$$;
reset role;

delete from auth.users
 where id in ('ec200000-0000-0000-0000-000000000001', 'ec200000-0000-0000-0000-000000000002');
insert into auth.users (id, email, email_confirmed_at) values
  ('ec200000-0000-0000-0000-000000000003', 'family@example.test', now()),
  ('ec200000-0000-0000-0000-000000000004', 'unknown@example.test', now()),
  ('ec200000-0000-0000-0000-000000000005', 'previous-owner@example.test', now());

set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000003","role":"authenticated"}', true);
do $$
declare
  v_first jsonb;
  v_replay jsonb;
begin
  v_first := public.reclamer_preinscription_apres_preuve();
  if v_first->>'email_prouve' <> 'true'
     or v_first->>'inscription_connue' <> 'true'
     or v_first->>'message_accueil' not like '%ParentFirst%Lina%'
     or v_first->>'message_patience' not like '%ParentFirst%Lina%'
     or jsonb_array_length(v_first->'personnes') <> 2
     or v_first::text like '%family@example.test%' then
    raise exception 'verified claim did not return the expected household data';
  end if;
  v_replay := public.reclamer_preinscription_apres_preuve();
  if v_replay->>'inscription_connue' <> 'true'
     or v_replay->>'message_accueil' is not null
     or jsonb_array_length(v_replay->'personnes') <> 2 then
    raise exception 'claim replay was not idempotent or repeated the one-time welcome';
  end if;
end;
$$;

select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000004","role":"authenticated"}', true);
do $$
declare v_unknown jsonb;
begin
  v_unknown := public.reclamer_preinscription_apres_preuve();
  if v_unknown <> '{"email_prouve":true,"inscription_connue":false}'::jsonb
     or v_unknown::text like '%ParentFirst%' then
    raise exception 'verified unknown address returned pre-registration data';
  end if;
end;
$$;
reset role;

do $$
begin
  if not exists (
    select 1 from private.preinscription_households
     where id = 'ec2fffff-ffff-ffff-ffff-000000000001'
       and linked_auth_user_id = 'ec200000-0000-0000-0000-000000000003'
       and linked_at is not null
  ) then
    raise exception 'confirmed Auth user was not linked to the matching household';
  end if;
  if (select count(*) from public.audit_logs where action = 'preinscription_claimed') <> 1
     or exists (
       select 1 from public.audit_logs
        where action = 'preinscription_claimed'
          and (payload::text like '%family@example.test%' or payload::text like '%ParentFirst%')
     ) then
    raise exception 'claim audit is missing, duplicated, or contains PII';
  end if;
end;
$$;

update private.preinscription_households
   set linked_auth_user_id = 'ec200000-0000-0000-0000-000000000005',
       linked_at = now()
 where id = 'ec2fffff-ffff-ffff-ffff-000000000001';
set local role authenticated;
select set_config('request.jwt.claim.sub', 'ec200000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims',
  '{"sub":"ec200000-0000-0000-0000-000000000003","role":"authenticated"}', true);
do $linked_to_other_account$
declare v_result jsonb;
begin
  v_result := public.reclamer_preinscription_apres_preuve();
  if v_result <> '{"email_prouve":true,"inscription_connue":false}'::jsonb
     or v_result::text like '%ParentFirst%'
     or v_result::text like '%Lina%'
     or v_result ? 'personnes' then
    raise exception 'household linked to another Auth account returned private data';
  end if;
end;
$linked_to_other_account$;
reset role;
do $$
begin
  if (select count(*) from public.audit_logs where action = 'preinscription_claimed') <> 1 then
    raise exception 'refusing a second account claim wrote another audit event';
  end if;
end;
$$;

set local role anon;
do $$
declare v_rejected boolean := false;
begin
  begin
    perform public.reclamer_preinscription_apres_preuve();
  exception when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then raise exception 'anon executed claim RPC'; end if;
end;
$$;
reset role;

set local role service_role;
do $$
declare v_rejected boolean := false;
begin
  begin
    perform public.reclamer_preinscription_apres_preuve();
  exception when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then raise exception 'service_role executed claim RPC'; end if;
end;
$$;
reset role;

rollback;
