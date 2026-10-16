-- Audit final 16/10/2026, lot L1-06 (P1-4). Le grand livre wallet_entries est
-- un journal : aucun update ni delete, même pour postgres ; une correction est
-- une écriture inverse (reference_type = 'adjustment').
-- Sur Postgres nu, sous le stub de stub_auth.sql. Base neuve à chaque rejeu.
begin;

insert into auth.users (id, email) values
  ('6f160000-0000-4000-8000-000000000001', 'l1-06-admin@example.invalid');
insert into public.households (id, timezone) values
  ('6f160000-0000-4000-8000-000000000101', 'Europe/Paris');
insert into public.profiles (
  id, immutable_id, role, household_id, first_name, last_name, account_status
) values (
  '6f160000-0000-4000-8000-000000000001', 'L1-06-ADMIN', 'admin',
  '6f160000-0000-4000-8000-000000000101', 'Test', 'Direction', 'active'
);
insert into public.wallets (id, household_id, currency) values
  ('6f160000-0000-4000-8000-000000000301', '6f160000-0000-4000-8000-000000000101', 'EUR');

do $l1_06$
declare
  v_entry bigint;
  v_denied boolean;
  v_count integer;
begin
  -- 1. Admin valide : insertion d'une écriture de crédit (réussit).
  set local role authenticated;
  perform set_config('test.uid', '6f160000-0000-4000-8000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  insert into public.wallet_entries (wallet_id, amount_minor, currency, reference_type)
  values ('6f160000-0000-4000-8000-000000000301', 1000, 'EUR', 'credit')
  returning id into v_entry;
  if v_entry is null then
    raise exception 'L1-06: l''admin valide n''arrive pas à insérer une écriture';
  end if;

  -- 2. Admin valide : update refusé (pas de privilège UPDATE).
  v_denied := false;
  begin
    update public.wallet_entries set amount_minor = 1 where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: l''admin a pu modifier une écriture du grand livre';
  end if;

  -- 3. Admin valide : delete refusé.
  v_denied := false;
  begin
    delete from public.wallet_entries where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: l''admin a pu effacer une écriture du grand livre';
  end if;

  -- 4. Correction par écriture inverse : réussit.
  insert into public.wallet_entries (wallet_id, amount_minor, currency, reference_type)
  values ('6f160000-0000-4000-8000-000000000301', -1000, 'EUR', 'adjustment');
  reset role;

  -- 5. Même postgres : update lève insufficient_privilege (trigger).
  v_denied := false;
  begin
    update public.wallet_entries set amount_minor = 1 where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: postgres a pu modifier une écriture (trigger absent)';
  end if;

  -- 6. Même postgres : delete lève insufficient_privilege (trigger).
  v_denied := false;
  begin
    delete from public.wallet_entries where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: postgres a pu effacer une écriture (trigger absent)';
  end if;

  -- 6 bis. Postgres : confirmation prestataire seule, première pose : admise.
  update public.wallet_entries set confirme_par_prestataire_le = clock_timestamp()
   where id = v_entry;

  -- 6 ter. Confirmation déjà posée : une seconde pose est refusée.
  v_denied := false;
  begin
    update public.wallet_entries set confirme_par_prestataire_le = clock_timestamp()
     where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: une confirmation prestataire déjà posée a pu être réécrite';
  end if;

  -- 6 quater. Admin (authenticated) qui pose la confirmation : refusé.
  insert into public.wallet_entries (wallet_id, amount_minor, currency, reference_type)
  values ('6f160000-0000-4000-8000-000000000301', 500, 'EUR', 'credit')
  returning id into v_entry;
  set local role authenticated;
  perform set_config('test.uid', '6f160000-0000-4000-8000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  v_denied := false;
  begin
    update public.wallet_entries set confirme_par_prestataire_le = clock_timestamp()
     where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: un admin a pu poser une confirmation prestataire';
  end if;
  reset role;

  -- 6 quinquies. Postgres : confirmation et changement de montant ensemble : refusé.
  v_denied := false;
  begin
    update public.wallet_entries set confirme_par_prestataire_le = clock_timestamp(), amount_minor = 1
     where id = v_entry;
  exception when insufficient_privilege then v_denied := true;
  end;
  if not v_denied then
    raise exception 'L1-06: postgres a pu changer un montant en même temps que la confirmation';
  end if;

  -- 7 (avant le suspendu). Postgres : la même confirmation seule est admise.
  update public.wallet_entries set confirme_par_prestataire_le = clock_timestamp()
   where id = v_entry;

  -- 7. Admin suspendu : le journal n'est plus lisible.
  update public.profiles set account_status = 'disabled'
   where id = '6f160000-0000-4000-8000-000000000001';
  set local role authenticated;
  perform set_config('test.uid', '6f160000-0000-4000-8000-000000000001', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
  select count(*) into v_count from public.wallet_entries;
  reset role;
  if v_count <> 0 then
    raise exception 'L1-06: un admin suspendu lit % écritures', v_count;
  end if;

  raise notice 'L1-06 PASS';
end
$l1_06$;

rollback;
