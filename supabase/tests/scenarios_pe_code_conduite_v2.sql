-- PE / conformite (19/10/2026) :
--   1. le code de conduite definitif : la version requise est 2026-10-19 ; une
--      acceptation de l'ancienne version est refusee, celle de la nouvelle passe ;
--   2. le representant dans l'UE : vide par defaut, reserve a l'administration,
--      valide par le declencheur, lu par un compte connecte, jamais par anon.
-- Base PostgreSQL jetable apres rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('bf000000-0000-0000-0000-000000000001', 'cc2-admin@example.test'),
  ('bf000000-0000-0000-0000-000000000002', 'cc2-teacher@example.test');

insert into public.households (id, timezone)
values ('bfffff00-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('bf000000-0000-0000-0000-000000000001', 'CCADMIN000001', 'admin',
   'bfffff00-0000-0000-0000-000000000001', 'Fixture', 'Admin', 'active', 'male'),
  ('bf000000-0000-0000-0000-000000000002', 'CCTEACHER0001', 'teacher',
   'bfffff00-0000-0000-0000-000000000001', 'Teacher', 'One', 'provisional_active', 'male');

insert into public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values
  ('bf000000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris');


-- ===========================================================================
-- 1. Code de conduite definitif
-- ===========================================================================
do $cc2_version$
begin
  if (select version from public.contract_required_versions
       where contract_kind = 'teacher_conduct_code') <> '2026-10-19' then
    raise exception 'CC2: la version requise n est pas 2026-10-19';
  end if;
end
$cc2_version$;

set local role authenticated;
select set_config('test.uid', 'bf000000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"bfffff00-0000-0000-0000-000000000001"}}',
  true);
do $cc2_acceptation$
begin
  begin
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values ('bf000000-0000-0000-0000-000000000002', 'teacher_conduct_code', '2026-10-cond');
    raise exception 'CC2: l ancienne version est encore acceptee';
  exception when insufficient_privilege then
    null;
  end;
  insert into public.contract_acceptances (profile_id, contract_kind, version)
  values ('bf000000-0000-0000-0000-000000000002', 'teacher_conduct_code', '2026-10-19');
end
$cc2_acceptation$;

-- ===========================================================================
-- 2. Representant dans l'Union europeenne
-- ===========================================================================
do $cc2_rep_enseignant$
declare
  v_n integer;
begin
  if public.representant_ue_conformite() ->> 'nom' <> '' then
    raise exception 'CC2: le representant n est pas vide par defaut: %',
      public.representant_ue_conformite();
  end if;
  update public.app_config set value = '"Pirate"'::jsonb
   where key = 'conformite.representant_ue';
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'CC2: un enseignant a modifie le representant';
  end if;
end
$cc2_rep_enseignant$;

select set_config('test.uid', 'bf000000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"bfffff00-0000-0000-0000-000000000001"}}',
  true);
do $cc2_rep_admin$
declare
  v_n integer;
begin
  update public.app_config set value = '"  Cabinet Exemple SARL  "'::jsonb
   where key = 'conformite.representant_ue';
  get diagnostics v_n = row_count;
  if v_n <> 1 then raise exception 'CC2: l administration ne modifie pas le representant'; end if;
  if public.representant_ue_conformite() ->> 'nom' <> 'Cabinet Exemple SARL' then
    raise exception 'CC2: reglage non relu ou non nettoye: %', public.representant_ue_conformite();
  end if;

  begin
    update public.app_config set value = '12'::jsonb
     where key = 'conformite.representant_ue';
    raise exception 'CC2: valeur non textuelle acceptee';
  exception when raise_exception then
    if sqlerrm <> 'reglage de conformite : un texte est attendu' then raise; end if;
  end;
  begin
    update public.app_config set value = pg_catalog.to_jsonb(pg_catalog.repeat('a', 121))
     where key = 'conformite.representant_ue';
    raise exception 'CC2: nom trop long accepte';
  exception when raise_exception then
    if sqlerrm <> 'reglage de conformite : nom trop long' then raise; end if;
  end;
  begin
    update public.app_config set value = pg_catalog.to_jsonb('a' || chr(10) || 'b')
     where key = 'conformite.representant_ue';
    raise exception 'CC2: caractere de commande accepte';
  exception when raise_exception then
    if sqlerrm <> 'reglage de conformite : caractere interdit' then raise; end if;
  end;

  -- Vider le reglage est permis : l'application redit « Rewayah Academy ».
  update public.app_config set value = '""'::jsonb
   where key = 'conformite.representant_ue';
  if public.representant_ue_conformite() ->> 'nom' <> '' then
    raise exception 'CC2: le reglage n a pas ete vide';
  end if;
end
$cc2_rep_admin$;

reset role;
do $cc2_droits$
begin
  if pg_catalog.has_function_privilege('anon', 'public.representant_ue_conformite()', 'EXECUTE')
     or pg_catalog.has_function_privilege('agent_ro', 'public.representant_ue_conformite()', 'EXECUTE') then
    raise exception 'CC2: anon ou agent_ro a EXECUTE sur representant_ue_conformite';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', 'public.representant_ue_conformite()', 'EXECUTE') then
    raise exception 'CC2: authenticated n a pas EXECUTE sur representant_ue_conformite';
  end if;
  if (select count(*) from public.app_config_history
       where key = 'conformite.representant_ue') < 1 then
    raise exception 'CC2: le changement du representant n est pas journalise';
  end if;
end
$cc2_droits$;

do $cc2_ok$
begin
  raise notice 'OK scenarios_pe_code_conduite_v2';
end
$cc2_ok$;

rollback;
