-- Scenario d'acceptation du lot L1-08 (audit final 16/10/2026, P1-6 et P2-1).
-- Un administrateur dont le compte est desactive ne lit ni n'ecrit plus rien par
-- les policies par role ; le controleur ne lit plus le journal d'audit ; un
-- administrateur valide lit toujours. Dernier bloc : plus aucune policy qui teste
-- app_role() sans app_account_valid(), hors les neuf laissees (cinq lectures non privilegiees,
-- quatre policies d'accueil du compte pending_kyc, dont le code de conduite de
-- l'enseignant depuis CAND-Q15, 20261021210400).
--
-- Se rejoue sur une base NEUVE, apres stub_auth.sql et toutes les migrations.
-- Sans la migration 20261017100800, A2 lit profiles et le scenario echoue.

insert into auth.users (id, email) values
  ('10000108-0000-0000-0000-000000000001', 'adminA1@example.test'),
  ('10000108-0000-0000-0000-000000000002', 'adminA2@example.test'),
  ('10000108-0000-0000-0000-000000000003', 'controleurC@example.test'),
  ('10000108-0000-0000-0000-000000000004', 'tuteurG@example.test');

insert into public.households (id, timezone)
values ('10000108-0000-0000-0000-00000000000f', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('10000108-0000-0000-0000-000000000001', 'ADMIN-L108-000001', 'admin',
   null, 'Admin', 'Valide', 'active', 'male'),
  ('10000108-0000-0000-0000-000000000002', 'ADMIN-L108-000002', 'admin',
   null, 'Admin', 'Suspendu', 'disabled', 'male'),
  ('10000108-0000-0000-0000-000000000003', 'CTRL-L108-000003', 'controller',
   null, 'Controle', 'Valide', 'active', 'female'),
  ('10000108-0000-0000-0000-000000000004', 'GUARD-L108-000004', 'guardian',
   '10000108-0000-0000-0000-00000000000f', 'Tuteur', 'Famille', 'active', 'male');

insert into public.wallets (household_id) values ('10000108-0000-0000-0000-00000000000f');

insert into public.sessions (id, teacher_id, started_at, ended_at)
values ('10000108-0000-0000-0000-0000000000a1', '10000108-0000-0000-0000-000000000001',
        '2027-01-15 10:00:00+00', '2027-01-15 11:00:00+00');

insert into public.app_config (key, value) values ('l108_sonde', '1'::jsonb)
  on conflict (key) do nothing;

select public.log_sensitive_access('l108_acces', 'profiles', 'x', '{}'::jsonb);
select public.log_sensitive_access('l108_acces', 'profiles', 'y', '{}'::jsonb);

-- app_account_valid() doit rester STABLE (une evaluation par requete, pas par ligne).
do $$
begin
  if (select provolatile from pg_proc where oid = 'public.app_account_valid()'::regprocedure) <> 's' then
    raise exception 'L1-08 ECHEC : app_account_valid() n''est plus STABLE';
  end if;
end $$;

-- A2 suspendu : zero ligne lue sur cinq tables, zero ligne ecrite.
do $$
declare
  v_profiles int; v_sessions int; v_audit int; v_config int; v_wallets int; v_rows int;
begin
  perform set_config('request.jwt.claim.sub', '10000108-0000-0000-0000-000000000002', true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
  set local role authenticated;
  -- sa propre ligne reste lisible par profiles_self_select (ecran compte suspendu)
  select count(*) into v_profiles from public.profiles
   where id <> '10000108-0000-0000-0000-000000000002';
  select count(*) into v_sessions from public.sessions;
  select count(*) into v_audit    from public.audit_logs;
  select count(*) into v_config   from public.app_config;
  select count(*) into v_wallets  from public.wallets;
  update public.profiles set first_name = 'x' where id = '10000108-0000-0000-0000-000000000001';
  get diagnostics v_rows = row_count;
  reset role;
  if v_profiles <> 0 or v_sessions <> 0 or v_audit <> 0 or v_config <> 0 or v_wallets <> 0 then
    raise exception 'L1-08 ECHEC A2 suspendu lit : profiles=% sessions=% audit_logs=% app_config=% wallets=% (attendu 0 partout)',
      v_profiles, v_sessions, v_audit, v_config, v_wallets;
  end if;
  if v_rows <> 0 then
    raise exception 'L1-08 ECHEC A2 suspendu ecrit : update profiles row_count=% (attendu 0)', v_rows;
  end if;
  raise notice 'L1-08 ok : l''administrateur suspendu ne lit ni n''ecrit rien';
end $$;

-- C valide : plus aucune ligne du journal d'audit.
do $$
declare v_audit int;
begin
  perform set_config('request.jwt.claim.sub', '10000108-0000-0000-0000-000000000003', true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"controller"}}', true);
  set local role authenticated;
  select count(*) into v_audit from public.audit_logs;
  reset role;
  if v_audit <> 0 then
    raise exception 'L1-08 ECHEC controleur lit audit_logs : % lignes (attendu 0)', v_audit;
  end if;
  raise notice 'L1-08 ok : le controleur ne lit plus le journal d''audit';
end $$;

-- A1 valide : les lignes attendues, et l'ecriture passe.
do $$
declare
  v_profiles int; v_audit int; v_config int; v_wallets int; v_sessions int; v_rows int;
begin
  perform set_config('request.jwt.claim.sub', '10000108-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
  set local role authenticated;
  select count(*) into v_profiles from public.profiles;
  select count(*) into v_sessions from public.sessions;
  select count(*) into v_audit    from public.audit_logs;
  select count(*) into v_config   from public.app_config;
  select count(*) into v_wallets  from public.wallets;
  update public.profiles set first_name = 'Admin' where id = '10000108-0000-0000-0000-000000000004';
  get diagnostics v_rows = row_count;
  reset role;
  if v_profiles < 4 or v_audit < 2 or v_sessions < 1 or v_config < 1 or v_wallets < 1 then
    raise exception 'L1-08 ECHEC A1 valide : profiles=% (>=4) audit_logs=% (>=2) sessions=% (>=1) app_config=% (>=1) wallets=% (>=1)',
      v_profiles, v_audit, v_sessions, v_config, v_wallets;
  end if;
  if v_rows <> 1 then
    raise exception 'L1-08 ECHEC A1 valide ne peut plus ecrire : row_count=% (attendu 1)', v_rows;
  end if;
  raise notice 'L1-08 ok : l''administrateur valide lit et ecrit';
end $$;

-- Depots (piece, signature) : un compte disabled est refuse (42501), pending_kyc passe.
insert into auth.users (id, email) values
  ('10000108-0000-0000-0000-000000000005', 'profD@example.test'),
  ('10000108-0000-0000-0000-000000000006', 'profP@example.test');
insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
values
  ('10000108-0000-0000-0000-000000000005', 'TCH-L108-000005', 'teacher', 'Prof', 'Suspendu', 'disabled', 'male'),
  ('10000108-0000-0000-0000-000000000006', 'TCH-L108-000006', 'teacher', 'Prof', 'Attente', 'pending_kyc', 'male');

do $$
declare
  v_u text; v_etat text; v_ok boolean; v_code text;
begin
  foreach v_u in array array['10000108-0000-0000-0000-000000000005', '10000108-0000-0000-0000-000000000006'] loop
    v_etat := case when v_u like '%5' then 'disabled' else 'pending_kyc' end;
    perform set_config('request.jwt.claim.sub', v_u, true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
    set local role authenticated;
    -- piece KYC
    begin
      insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
      values (v_u::uuid, 'id_card', 'male', v_u || '/piece.webp');
      v_ok := true; v_code := null;
    exception when others then v_ok := false; v_code := sqlstate; end;
    if v_etat = 'disabled' and (v_ok or v_code <> '42501') then
      reset role;
      raise exception 'L1-08 ECHEC compte disabled : depot KYC ok=% sqlstate=% (attendu refus 42501)', v_ok, v_code;
    elsif v_etat = 'pending_kyc' and not v_ok then
      reset role;
      raise exception 'L1-08 ECHEC compte pending_kyc : depot KYC refuse (%)', v_code;
    end if;
    -- signature de contrat
    begin
      insert into public.contract_acceptances (profile_id, contract_kind, version)
      values (v_u::uuid, 'guardian_terms', 'l108');
      v_ok := true; v_code := null;
    exception when others then v_ok := false; v_code := sqlstate; end;
    reset role;
    if v_etat = 'disabled' and (v_ok or v_code <> '42501') then
      raise exception 'L1-08 ECHEC compte disabled : signature ok=% sqlstate=% (attendu refus 42501)', v_ok, v_code;
    elsif v_etat = 'pending_kyc' and not v_ok then
      raise exception 'L1-08 ECHEC compte pending_kyc : signature refusee (%)', v_code;
    end if;
  end loop;
  raise notice 'L1-08 ok : disabled refuse (42501) au depot et a la signature, pending_kyc admis';
end $$;

-- Controle automatique : exactement les neuf policies laissees, aucune autre
-- (huit jusqu'a CAND-Q15 ; la neuvieme est le code de conduite de l'enseignant).
do $$
declare v_liste text; v_nb int;
begin
  select count(*), string_agg(tablename || '.' || policyname, ', ' order by tablename || '.' || policyname)
    into v_nb, v_liste
    from pg_policies
   where schemaname = 'public'
     and (coalesce(qual,'') || coalesce(with_check,'')) like '%app_role()%'
     and (coalesce(qual,'') || coalesce(with_check,'')) not like '%app_account_valid%';
  if v_nb <> 9 or v_liste is distinct from 'contract_acceptances.contract_acceptances_code_conduite_enseignant, contract_acceptances.contract_acceptances_self_insert, households.households_guardian_select, intentions_horaire.intentions_horaire_parties, kyc_documents.kyc_guardian_insert, kyc_documents.kyc_staff_self_insert, offres_horaires.offres_horaires_vitrine, profiles.profiles_family_select, student_reading_position.srp_foyer_lecture' then
    raise exception 'L1-08 ECHEC controle automatique : % policies sans app_account_valid (attendu 9) : %',
      v_nb, coalesce(v_liste, '(aucune)');
  end if;
  raise notice 'L1-08 ok : 9 policies laissees, liste : %', v_liste;
end $$;
