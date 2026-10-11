-- Scénario de bout en bout F70 (écrit par le relecteur) : pending_kyc -> signature -> activation
begin;
-- émule les privilèges par défaut de Supabase (SELECT seulement ; l'INSERT reste celui des migrations)
grant select on all tables in schema public to authenticated;
insert into auth.users(id,email) values
 ('e7000000-0000-0000-0000-000000000001','e2e-t1@example.test'),
 ('e7000000-0000-0000-0000-000000000002','e2e-t2@example.test'),
 ('e7000000-0000-0000-0000-000000000003','e2e-g@example.test');
insert into public.profiles(id,immutable_id,role,first_name,last_name,account_status,gender) values
 ('e7000000-0000-0000-0000-000000000001','E7TEACHER0000001','teacher','Pend','Un','pending_kyc','female'),
 ('e7000000-0000-0000-0000-000000000002','E7TEACHER0000002','teacher','Pend','Deux','pending_kyc','female');
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',false);
do $$ begin
  -- sans signature : activation refusée
  begin
    update public.profiles set account_status='active' where id='e7000000-0000-0000-0000-000000000002';
    raise exception 'E2E ECHEC : activation sans signature acceptée';
  exception when sqlstate '23514' then null; when others then
    if sqlerrm not like 'contract_not_signed_current%' then raise; end if;
  end;
end $$;
-- signature en pending_kyc par la RPC
set role authenticated;
select set_config('test.uid','e7000000-0000-0000-0000-000000000001',false);
select set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',false);
do $$ declare r record; begin
  select * into r from public.signer_contrat('2026-10-jur','Pend Un');
  if r.id is null then raise exception 'E2E ECHEC : signer_contrat n''a rien rendu'; end if;
  raise notice 'E2E ok : signer_contrat accepte pending_kyc';
  insert into public.contract_acceptances(profile_id,contract_kind,version) values ('e7000000-0000-0000-0000-000000000001','recording_and_control_notice','2026-10-jur');
end $$;
reset role;
select set_config('test.jwt','{"app_metadata":{"role":"admin"}}',false);
update public.profiles set account_status='active' where id='e7000000-0000-0000-0000-000000000001';
do $$ begin raise notice 'E2E ok : activation après signature'; end $$;
-- un tuteur ne peut pas signer comme enseignant
set role authenticated;
select set_config('test.uid','e7000000-0000-0000-0000-000000000003',false);
select set_config('test.jwt','{"app_metadata":{"role":"guardian"}}',false);
do $$ begin
  begin
    perform public.signer_contrat('2026-10-jur','Tuteur');
    raise exception 'E2E ECHEC : un tuteur a signé';
  exception when insufficient_privilege then raise notice 'E2E ok : tuteur refusé'; end;
end $$;
rollback;
