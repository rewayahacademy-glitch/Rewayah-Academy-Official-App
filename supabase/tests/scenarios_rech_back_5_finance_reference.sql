-- RECH-BACK-5 partial: exact finance reference is household-scoped by RLS.
begin;

insert into auth.users (id, email) values
  ('d1500000-0000-0000-0000-000000000001', 'rech-d4-guardian@example.test'),
  ('d1500000-0000-0000-0000-000000000002', 'rech-d4-other@example.test');
insert into public.households (id, timezone) values
  ('d1500000-0000-0000-0000-000000000101', 'Europe/Paris'),
  ('d1500000-0000-0000-0000-000000000102', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('d1500000-0000-0000-0000-000000000001', 'D4-GUARDIAN', 'guardian',
   'd1500000-0000-0000-0000-000000000101', 'D4', 'Guardian', 'active', 'female'),
  ('d1500000-0000-0000-0000-000000000002', 'D4-OTHER', 'guardian',
   'd1500000-0000-0000-0000-000000000102', 'D4', 'Other', 'active', 'male');
insert into public.wallets (id, household_id, currency) values
  ('d1500000-0000-0000-0000-000000000201',
   'd1500000-0000-0000-0000-000000000101', 'EUR'),
  ('d1500000-0000-0000-0000-000000000202',
   'd1500000-0000-0000-0000-000000000102', 'EUR');
insert into public.wallet_entries
  (wallet_id, amount_minor, currency, reference_type, reference_id)
values
  ('d1500000-0000-0000-0000-000000000201', 12500, 'EUR', 'credit',
   'd1500000-0000-0000-0000-000000000301'),
  ('d1500000-0000-0000-0000-000000000202', 99000, 'EUR', 'credit',
   'd1500000-0000-0000-0000-000000000301'),
  ('d1500000-0000-0000-0000-000000000202', 7000, 'EUR', 'debit',
   'd1500000-0000-0000-0000-000000000302');

select set_config('request.jwt.claim.sub', 'd1500000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'd1500000-0000-0000-0000-000000000001',
  'app_metadata', jsonb_build_object(
    'role', 'guardian', 'household_id', 'd1500000-0000-0000-0000-000000000101',
    'authorization_version', 1
  )
)::text, true);
set local role authenticated;

do $scenario$
declare
  v_result jsonb;
  v_stale_denied boolean := false;
begin
  v_result := public.rech_d4_rechercher_reference_finance(
    'd1500000-0000-0000-0000-000000000301'
  );
  if jsonb_array_length(v_result -> 'items') <> 1
     or v_result -> 'items' -> 0 ->> 'referenceType' <> 'credit'
     or (v_result -> 'items' -> 0) ?| array[
       'amount', 'amount_minor', 'wallet_id', 'payout_method', 'payment_details'
     ] then
    raise exception 'RECH-D4: projection finance étrangère, sensible ou incorrecte';
  end if;

  v_result := public.rech_d4_rechercher_reference_finance(
    'd1500000-0000-0000-0000-000000000302'
  );
  if jsonb_array_length(v_result -> 'items') <> 0 then
    raise exception 'RECH-D4: référence d''un autre foyer visible';
  end if;

  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'd1500000-0000-0000-0000-000000000001',
    'app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'd1500000-0000-0000-0000-000000000101',
      'authorization_version', 99
    )
  )::text, true);
  begin
    perform public.rech_d4_rechercher_reference_finance(
      'd1500000-0000-0000-0000-000000000301'
    );
  exception when insufficient_privilege then
    v_stale_denied := true;
  end;
  if not v_stale_denied then
    raise exception 'RECH-D4: jeton de recherche financier périmé accepté';
  end if;
end;
$scenario$;

reset role;
do $acl$
begin
  if has_function_privilege('anon',
       'public.rech_d4_rechercher_reference_finance(uuid)', 'EXECUTE')
     or (select prosecdef from pg_proc where oid =
       'public.rech_d4_rechercher_reference_finance(uuid)'::regprocedure) then
    raise exception 'RECH-D4: droit ajouté ou contournement de RLS';
  end if;
end;
$acl$;

rollback;
