-- Audit final 16/10/2026, lot L1-02 (P0-2). Les policies de foyer exigent le role
-- tuteur : un jeton `student` enfant, qui porte pourtant household_id, ne lit
-- ni portefeuille, ni ecritures, ni moyens de versement, ni versements, et ne
-- change ni la camera ni l'interface de qui que ce soit. L'eleve adulte
-- autonome (student_type = 'autonomous') garde la main sur lui-meme.
-- Se joue sur une base neuve apres stub_auth.sql et toutes les migrations ;
-- tout est annule en fin de script.
begin;

insert into auth.users (id, email) values
  ('a1020000-0000-4000-8000-000000000001', 'l102-tuteur@example.test'),
  ('a1020000-0000-4000-8000-000000000002', 'l102-enfant1@example.test'),
  ('a1020000-0000-4000-8000-000000000003', 'l102-enfant2@example.test'),
  ('a1020000-0000-4000-8000-000000000004', 'l102-adulte@example.test');
insert into public.households (id) values
  ('a1020000-0000-4000-8000-0000000000f1'),
  ('a1020000-0000-4000-8000-0000000000f2');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('a1020000-0000-4000-8000-000000000001', 'GUARD-L1-000001', 'guardian',
   'a1020000-0000-4000-8000-0000000000f1', 'Tuteur', 'L102', 'active', 'female'),
  ('a1020000-0000-4000-8000-000000000002', 'STUD-L1-000001', 'student',
   'a1020000-0000-4000-8000-0000000000f1', 'Enfant', 'Un', 'active', null),
  ('a1020000-0000-4000-8000-000000000003', 'STUD-L1-000002', 'student',
   'a1020000-0000-4000-8000-0000000000f1', 'Enfant', 'Deux', 'active', null),
  ('a1020000-0000-4000-8000-000000000004', 'STUD-L1-000003', 'student',
   'a1020000-0000-4000-8000-0000000000f2', 'Adulte', 'Seul', 'active', null);
insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values
  ('a1020000-0000-4000-8000-000000000002', 'minor', 'child', 'forbidden'),
  ('a1020000-0000-4000-8000-000000000003', 'minor', 'child', 'forbidden'),
  ('a1020000-0000-4000-8000-000000000004', 'autonomous', 'child', 'forbidden');
insert into public.wallets (id, household_id, currency) values
  ('a1020000-0000-4000-8000-0000000000a1', 'a1020000-0000-4000-8000-0000000000f1', 'EUR'),
  ('a1020000-0000-4000-8000-0000000000a2', 'a1020000-0000-4000-8000-0000000000f2', 'EUR')
on conflict (household_id) do nothing;
insert into public.wallet_entries (wallet_id, amount_minor, currency, reference_type) values
  ((select id from public.wallets where household_id = 'a1020000-0000-4000-8000-0000000000f1'), 1000, 'EUR', 'credit'),
  ((select id from public.wallets where household_id = 'a1020000-0000-4000-8000-0000000000f2'), 2000, 'EUR', 'credit');
insert into public.payout_methods (id, profile_id, kind, details) values
  ('a1020000-0000-4000-8000-0000000000b1', 'a1020000-0000-4000-8000-000000000001', 'bank_transfer', '{}'),
  ('a1020000-0000-4000-8000-0000000000b2', 'a1020000-0000-4000-8000-000000000004', 'bank_transfer', '{}');
insert into public.payouts (wallet_id, payout_method_id, amount_minor) values
  ((select id from public.wallets where household_id = 'a1020000-0000-4000-8000-0000000000f1'),
   'a1020000-0000-4000-8000-0000000000b1', 100),
  ((select id from public.wallets where household_id = 'a1020000-0000-4000-8000-0000000000f2'),
   'a1020000-0000-4000-8000-0000000000b2', 200);

-- 1. Enfant : rien, ni en lecture ni en ecriture, ni pour lui ni pour son frere.
select set_config('request.jwt.claim.sub', 'a1020000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"student","household_id":"a1020000-0000-4000-8000-0000000000f1"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets;
  if n <> 0 then raise exception 'L1-02: enfant lit wallets (%)', n; end if;
  select count(*) into n from public.wallet_entries;
  if n <> 0 then raise exception 'L1-02: enfant lit wallet_entries (%)', n; end if;
  select count(*) into n from public.payout_methods;
  if n <> 0 then raise exception 'L1-02: enfant lit payout_methods (%)', n; end if;
  select count(*) into n from public.payouts;
  if n <> 0 then raise exception 'L1-02: enfant lit payouts (%)', n; end if;
  update public.student_profiles set camera_policy = 'allowed'
   where profile_id in ('a1020000-0000-4000-8000-000000000002', 'a1020000-0000-4000-8000-000000000003');
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-02: enfant change camera_policy (%)', n; end if;
  update public.student_profiles set interface_mode = 'standard'
   where profile_id in ('a1020000-0000-4000-8000-000000000002', 'a1020000-0000-4000-8000-000000000003');
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-02: enfant change interface_mode (%)', n; end if;
end $$;
reset role;

-- 2. Tuteur : tout son foyer, rien d'un autre.
select set_config('request.jwt.claim.sub', 'a1020000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"a1020000-0000-4000-8000-0000000000f1"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets;
  if n <> 1 then raise exception 'L1-02: tuteur lit % portefeuilles, attendu 1', n; end if;
  select count(*) into n from public.wallet_entries;
  if n <> 1 then raise exception 'L1-02: tuteur lit % ecritures, attendu 1', n; end if;
  select count(*) into n from public.payout_methods;
  if n <> 1 then raise exception 'L1-02: tuteur lit % moyens de versement, attendu 1', n; end if;
  select count(*) into n from public.payouts;
  if n <> 1 then raise exception 'L1-02: tuteur lit % versements, attendu 1', n; end if;
  update public.student_profiles set camera_policy = 'allowed'
   where profile_id = 'a1020000-0000-4000-8000-000000000002';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'L1-02: tuteur ne regle pas la camera (%)', n; end if;
  update public.student_profiles set camera_policy = 'allowed'
   where profile_id = 'a1020000-0000-4000-8000-000000000004';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-02: tuteur regle un eleve d''un autre foyer (%)', n; end if;
end $$;
reset role;

-- 3. Adulte autonome : son portefeuille et son propre profil, pas ceux d'un autre foyer.
select set_config('request.jwt.claim.sub', 'a1020000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"student","household_id":"a1020000-0000-4000-8000-0000000000f2"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets;
  if n <> 1 then raise exception 'L1-02: adulte lit % portefeuilles, attendu 1', n; end if;
  select count(*) into n from public.wallet_entries;
  if n <> 1 then raise exception 'L1-02: adulte lit % ecritures, attendu 1', n; end if;
  select count(*) into n from public.payout_methods;
  if n <> 1 then raise exception 'L1-02: adulte lit % moyens de versement, attendu 1', n; end if;
  select count(*) into n from public.payouts;
  if n <> 1 then raise exception 'L1-02: adulte lit % versements, attendu 1', n; end if;
  update public.student_profiles set interface_mode = 'standard'
   where profile_id = 'a1020000-0000-4000-8000-000000000004';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'L1-02: adulte ne regle pas son interface (%)', n; end if;
  update public.student_profiles set interface_mode = 'standard'
   where profile_id in ('a1020000-0000-4000-8000-000000000002');
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-02: adulte regle un autre profil (%)', n; end if;
end $$;
reset role;

rollback;
select 'L1-02 PASS' as resultat;
