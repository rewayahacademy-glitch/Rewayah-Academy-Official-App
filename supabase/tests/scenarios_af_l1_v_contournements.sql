-- L1-V (verification croisee de la vague 1, nuit du 16 au 17/10/2026).
-- Tentatives de contournement, ecrites par un relecteur qui n'a ecrit aucun lot.
-- Chaque refus attendu verifie SQLSTATE 42501 exactement, ou un row_count nul
-- quand c'est le comportement REST (UPDATE filtre par la RLS).
--
-- Les defauts constates mais non corriges par la vague (fiches de reprise
-- L1-02-reprise, L1-05-reprise, L1-08-reprise) ne font pas echouer ce scenario :
-- ils sortent en NOTICE prefixee « L1-V DEFAUT ». La fiche de reprise demande de
-- les changer en exception une fois corriges. Une NOTICE « L1-V OK » marque un
-- point prouve.
--
-- Se joue sur une base neuve apres stub_auth.sql et toutes les migrations ;
-- tout est annule en fin de script.
begin;

-- ============================================================
-- Fixtures
-- 01 admin valide, 02 admin suspendu, 03 enseignant actif, 04 tuteur F1,
-- 05 enfant E1 (F1), 06 enfant E2 (F1), 07 adulte autonome (F2),
-- 08 enseignant suspendu, 09 controleur suspendu.
-- ============================================================
insert into auth.users (id, email, email_confirmed_at) values
  ('a1f00000-0000-4000-8000-000000000001', 'l1v-admin@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000002', 'l1v-admin-susp@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000003', 'l1v-ens@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000004', 'l1v-tuteur@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000005', 'l1v-e1@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000006', 'l1v-e2@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000007', 'l1v-adulte@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000008', 'l1v-ens-susp@example.test', now()),
  ('a1f00000-0000-4000-8000-000000000009', 'l1v-ctrl-susp@example.test', now());
insert into public.households (id) values
  ('a1f00000-0000-4000-8000-0000000000f1'),
  ('a1f00000-0000-4000-8000-0000000000f2');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('a1f00000-0000-4000-8000-000000000001', 'L1V-ADM-1', 'admin', null, 'Direction', 'Valide', 'active', 'male'),
  ('a1f00000-0000-4000-8000-000000000002', 'L1V-ADM-2', 'admin', null, 'Direction', 'Suspendue', 'disabled', 'male'),
  ('a1f00000-0000-4000-8000-000000000003', 'L1V-ENS-3', 'teacher', null, 'Enseignant', 'Actif', 'provisional_active', 'male'),
  ('a1f00000-0000-4000-8000-000000000004', 'L1V-TUT-4', 'guardian', 'a1f00000-0000-4000-8000-0000000000f1', 'Tuteur', 'F1', 'active', 'female'),
  ('a1f00000-0000-4000-8000-000000000005', 'L1V-STU-5', 'student', 'a1f00000-0000-4000-8000-0000000000f1', 'Enfant', 'Un', 'active', null),
  ('a1f00000-0000-4000-8000-000000000006', 'L1V-STU-6', 'student', 'a1f00000-0000-4000-8000-0000000000f1', 'Enfant', 'Deux', 'active', null),
  ('a1f00000-0000-4000-8000-000000000007', 'L1V-STU-7', 'student', 'a1f00000-0000-4000-8000-0000000000f2', 'Adulte', 'Seul', 'active', null),
  ('a1f00000-0000-4000-8000-000000000008', 'L1V-ENS-8', 'teacher', null, 'Enseignant', 'Suspendu', 'disabled', 'male'),
  ('a1f00000-0000-4000-8000-000000000009', 'L1V-CTL-9', 'controller', null, 'Controle', 'Suspendu', 'disabled', 'male');
insert into public.teacher_profiles (profile_id) values
  ('a1f00000-0000-4000-8000-000000000003'), ('a1f00000-0000-4000-8000-000000000008');
insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy) values
  ('a1f00000-0000-4000-8000-000000000005', 'minor', 'child', 'forbidden'),
  ('a1f00000-0000-4000-8000-000000000006', 'minor', 'child', 'forbidden'),
  ('a1f00000-0000-4000-8000-000000000007', 'autonomous', 'standard', 'forbidden');
insert into public.wallets (id, household_id, currency) values
  ('a1f00000-0000-4000-8000-0000000000a1', 'a1f00000-0000-4000-8000-0000000000f1', 'EUR'),
  ('a1f00000-0000-4000-8000-0000000000a2', 'a1f00000-0000-4000-8000-0000000000f2', 'EUR')
on conflict (household_id) do nothing;
insert into public.wallet_entries (wallet_id, amount_minor, currency, reference_type) values
  ((select id from public.wallets where household_id = 'a1f00000-0000-4000-8000-0000000000f1'), 1000, 'EUR', 'credit'),
  ((select id from public.wallets where household_id = 'a1f00000-0000-4000-8000-0000000000f2'), 2000, 'EUR', 'credit');
insert into public.payout_methods (id, profile_id, kind, details) values
  ('a1f00000-0000-4000-8000-0000000000b1', 'a1f00000-0000-4000-8000-000000000004', 'bank_transfer', '{}');
insert into public.payouts (wallet_id, payout_method_id, amount_minor) values
  ((select id from public.wallets where household_id = 'a1f00000-0000-4000-8000-0000000000f1'),
   'a1f00000-0000-4000-8000-0000000000b1', 100);
-- S1 : enseignant 03 avec E1. S2 : enseignant 03 avec E2.
insert into public.sessions (id, teacher_id, started_at, ended_at) values
  ('a1f00000-0000-4000-8000-0000000000c1', 'a1f00000-0000-4000-8000-000000000003',
   '2027-02-01 10:00:00+00', '2027-02-01 11:00:00+00'),
  ('a1f00000-0000-4000-8000-0000000000c2', 'a1f00000-0000-4000-8000-000000000003',
   '2027-02-01 14:00:00+00', '2027-02-01 15:00:00+00');
insert into public.session_participants (session_id, profile_id, role) values
  ('a1f00000-0000-4000-8000-0000000000c1', 'a1f00000-0000-4000-8000-000000000003', 'teacher'),
  ('a1f00000-0000-4000-8000-0000000000c1', 'a1f00000-0000-4000-8000-000000000005', 'student'),
  ('a1f00000-0000-4000-8000-0000000000c2', 'a1f00000-0000-4000-8000-000000000003', 'teacher'),
  ('a1f00000-0000-4000-8000-0000000000c2', 'a1f00000-0000-4000-8000-000000000006', 'student');
insert into public.lesson_reports (id, session_id, idempotency_key, author_profile_id, content) values
  ('a1f00000-0000-4000-8000-0000000000d1', 'a1f00000-0000-4000-8000-0000000000c1', 'l1v-1',
   'a1f00000-0000-4000-8000-000000000003', '{"note":"interne E1"}'),
  ('a1f00000-0000-4000-8000-0000000000d2', 'a1f00000-0000-4000-8000-0000000000c2', 'l1v-2',
   'a1f00000-0000-4000-8000-000000000003', '{"note":"interne E2"}');
insert into public.makharij_findings (lesson_report_id, makhraj, finding) values
  ('a1f00000-0000-4000-8000-0000000000d1', 'jawf', '{"ecart":"interne"}');
insert into public.session_recordings (id, session_id, object_key, duration_seconds, size_bytes, expires_at, legal_hold_since)
values ('a1f00000-0000-4000-8000-0000000000e1', 'a1f00000-0000-4000-8000-0000000000c1',
        'l1v/enregistrement.ogg', 60, 1000, now() + interval '30 days', now() - interval '1 day');

-- ============================================================
-- A. P0-1 : le serveur peut, un administrateur aal2 ne peut plus.
-- ============================================================
set local role service_role;
do $$
declare n int;
begin
  perform public.record_session_event('a1f00000-0000-4000-8000-0000000000c1',
    'a1f00000-0000-4000-8000-000000000005', 'joined', 'livekit_webhook');
  select count(*) into n from public.session_events
   where session_id = 'a1f00000-0000-4000-8000-0000000000c1' and event_type = 'joined';
  if n <> 1 then raise exception 'L1-V A1: service_role n''ecrit plus la presence (%)', n; end if;
  raise notice 'L1-V OK A1 : service_role ecrit la presence';
end $$;
reset role;

select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
begin
  begin
    perform public.record_session_event('a1f00000-0000-4000-8000-0000000000c1',
      'a1f00000-0000-4000-8000-000000000005', 'left', 'livekit_webhook');
    raise exception 'L1-V A2: record_session_event accepte un admin aal2';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V A2: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    perform public.log_sensitive_access('kyc_decision', 'kyc_documents', 'forge', '{}'::jsonb);
    raise exception 'L1-V A3: log_sensitive_access accepte un admin aal2';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V A3: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    perform public.materialiser_seances('a1f00000-0000-4000-8000-0000000000c1');
    raise exception 'L1-V A4: materialiser_seances accepte un admin aal2';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V A4: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  raise notice 'L1-V OK A2-A4 : les trois fonctions serveur refusent un admin aal2 en 42501';
end $$;

-- A5. Detournement des triggers d'audit passes SECURITY DEFINER (L1-01) :
-- un compte connecte cree une table temporaire et tente d'y attacher la fonction
-- de trigger, pour ecrire une ligne d'audit signee a sa guise.
do $$
begin
  create temp table l1v_piege (id uuid, enseignant_id uuid, taux_minor_par_heure bigint,
    devise text, date_effet date, motif text, cree_par uuid, date_effet2 date,
    taux_taxes_permille int, taux_charges_permille int, taux_reserve_permille int);
  raise notice 'L1-V A5 : la table temporaire est creee (le privilege TEMP est bien la)';
  begin
    create trigger l1v_piege_audit before insert on pg_temp.l1v_piege
      for each row execute function public.auditer_regle_remuneration_enseignant();
    raise exception 'L1-V A5: authenticated attache auditer_regle_remuneration_enseignant a sa table';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V A5: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    create trigger l1v_piege_coffres before insert on pg_temp.l1v_piege
      for each row execute function public.x217_valider_politique_coffres();
    raise exception 'L1-V A5: authenticated attache x217_valider_politique_coffres a sa table';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V A5b: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    perform public.auditer_regle_remuneration_enseignant();
    raise exception 'L1-V A5: appel direct de la fonction de trigger accepte';
  exception when others then
    if sqlstate not in ('42501', '0A000') then raise exception 'L1-V A5c: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  raise notice 'L1-V OK A5 : les deux triggers DEFINER ne s''attachent pas a une table de l''attaquant (42501)';
end $$;
reset role;

-- A6. Le trigger DEFINER n'ecrit l'audit que pour une insertion deja admise par
-- la policy : enseignant, admin aal1 et admin suspendu sont refuses en 42501 ;
-- l'admin aal2 valide passe et laisse une ligne d'audit.
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"teacher"}}', true);
set local role authenticated;
do $$
begin
  insert into public.regles_remuneration_enseignant (enseignant_id, taux_minor_par_heure, devise, date_effet, motif, cree_par)
    values ('a1f00000-0000-4000-8000-000000000003', 999999, 'EUR', date '2027-03-01', 'l1v forge',
            'a1f00000-0000-4000-8000-000000000003');
  raise exception 'L1-V A6: un enseignant ecrit sa regle de remuneration';
exception when others then
  if sqlstate <> '42501' then raise exception 'L1-V A6: SQLSTATE % : %', sqlstate, sqlerrm; end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
begin
  insert into public.regles_remuneration_enseignant (enseignant_id, taux_minor_par_heure, devise, date_effet, motif, cree_par)
    values (null, 1, 'EUR', date '2027-03-02', 'l1v admin suspendu', 'a1f00000-0000-4000-8000-000000000002');
  raise exception 'L1-V A6b: un admin suspendu ecrit une regle';
exception when others then
  if sqlstate <> '42501' then raise exception 'L1-V A6b: SQLSTATE % : %', sqlstate, sqlerrm; end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"aal":"aal1","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
begin
  insert into public.regles_remuneration_enseignant (enseignant_id, taux_minor_par_heure, devise, date_effet, motif, cree_par)
    values (null, 1, 'EUR', date '2027-03-03', 'l1v admin aal1', 'a1f00000-0000-4000-8000-000000000001');
  raise exception 'L1-V A6c: un admin aal1 ecrit une regle';
exception when others then
  if sqlstate <> '42501' then raise exception 'L1-V A6c: SQLSTATE % : %', sqlstate, sqlerrm; end if;
end $$;
reset role;
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
insert into public.regles_remuneration_enseignant (enseignant_id, taux_minor_par_heure, devise, date_effet, motif, cree_par)
  values (null, 1500, 'EUR', date '2027-03-04', 'l1v sonde admin aal2', 'a1f00000-0000-4000-8000-000000000001');
reset role;
do $$
begin
  if not exists (select 1 from public.audit_logs where action = 'regle_remuneration_creee'
                  and actor = 'a1f00000-0000-4000-8000-000000000001') then
    raise exception 'L1-V A6d: le trigger DEFINER n''a pas journalise l''insertion admise';
  end if;
  if exists (select 1 from public.audit_logs where action = 'regle_remuneration_creee'
              and actor <> 'a1f00000-0000-4000-8000-000000000001'
              and payload ->> 'motif' like 'l1v%') then
    raise exception 'L1-V A6e: une ligne d''audit vient d''une insertion refusee';
  end if;
  raise notice 'L1-V OK A6 : seule l''insertion admin aal2 valide est journalisee, au nom de l''admin';
end $$;

-- ============================================================
-- B. L1-06 : la pose unique de confirme_par_prestataire_le ne s'ouvre a aucun
-- compte connecte, ni directement, ni par une fonction DEFINER.
-- ============================================================
do $$
declare v_liste text;
begin
  select string_agg(p.oid::regprocedure::text, ', ') into v_liste
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private', 'app_private')
     and p.prosrc ~* '(update|delete\s+from)\s+(only\s+)?(public\.)?wallet_entries';
  if v_liste is not null then
    raise exception 'L1-V B1: une fonction modifie wallet_entries : %', v_liste;
  end if;
  raise notice 'L1-V OK B1 : aucune fonction (public, private, app_private) ne fait UPDATE ni DELETE sur wallet_entries';
end $$;

select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
begin
  begin
    update public.wallet_entries set confirme_par_prestataire_le = now()
     where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
    raise exception 'L1-V B2: un admin pose la confirmation prestataire par REST';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V B2: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    delete from public.wallet_entries where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
    raise exception 'L1-V B3: un admin efface une ecriture';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V B3: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  raise notice 'L1-V OK B2-B3 : admin valide refuse en 42501 sur UPDATE et DELETE du grand livre';
end $$;
reset role;

set local role agent_ro;
do $$
begin
  update public.wallet_entries set confirme_par_prestataire_le = now()
   where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
  raise exception 'L1-V B4: agent_ro pose la confirmation';
exception when others then
  if sqlstate <> '42501' then raise exception 'L1-V B4: SQLSTATE % : %', sqlstate, sqlerrm; end if;
end $$;
reset role;

set local role service_role;
do $$
declare n int;
begin
  begin
    update public.wallet_entries set amount_minor = 1
     where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
    raise exception 'L1-V B5: service_role reecrit un montant';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V B5: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    update public.wallet_entries set confirme_par_prestataire_le = now(), amount_minor = 1
     where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
    raise exception 'L1-V B6: service_role glisse un montant avec la confirmation';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V B6: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  update public.wallet_entries set confirme_par_prestataire_le = now()
   where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'L1-V B7: service_role ne pose plus la confirmation (%)', n; end if;
  begin
    update public.wallet_entries set confirme_par_prestataire_le = now() + interval '1 day'
     where wallet_id = 'a1f00000-0000-4000-8000-0000000000a1';
    raise exception 'L1-V B8: service_role repose la confirmation';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V B8: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  raise notice 'L1-V OK B4-B8 : agent_ro refuse ; service_role pose une fois, sans autre colonne, jamais deux fois';
end $$;
reset role;

-- ============================================================
-- C. P0-2 : un jeton eleve enfant, lecture et ecriture, puis claims forges.
-- ============================================================
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000005', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"student","household_id":"a1f00000-0000-4000-8000-0000000000f1"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets;
  if n <> 0 then raise exception 'L1-V C1: enfant lit wallets (%)', n; end if;
  select count(*) into n from public.wallet_entries;
  if n <> 0 then raise exception 'L1-V C1: enfant lit wallet_entries (%)', n; end if;
  select count(*) into n from public.payout_methods;
  if n <> 0 then raise exception 'L1-V C1: enfant lit payout_methods (%)', n; end if;
  select count(*) into n from public.payouts;
  if n <> 0 then raise exception 'L1-V C1: enfant lit payouts (%)', n; end if;
  select count(*) into n from public.mes_seances_v;
  if n <> 1 then raise exception 'L1-V C2: enfant lit % seances dans mes_seances_v, attendu 1', n; end if;
  select count(*) into n from public.mes_seances_v where student_id = 'a1f00000-0000-4000-8000-000000000006';
  if n <> 0 then raise exception 'L1-V C2: enfant lit les seances de sa soeur'; end if;
  select count(*) into n from public.lesson_reports;
  if n <> 0 then raise exception 'L1-V C3: enfant lit lesson_reports (%)', n; end if;
  select count(*) into n from public.makharij_findings;
  if n <> 0 then raise exception 'L1-V C3: enfant lit makharij_findings (%)', n; end if;
  select count(*) into n from public.presence_seance_v where profile_id = 'a1f00000-0000-4000-8000-000000000006';
  if n <> 0 then raise exception 'L1-V C4: enfant lit la presence de sa soeur (%)', n; end if;
  update public.student_profiles set camera_policy = 'allowed'
   where profile_id in ('a1f00000-0000-4000-8000-000000000005', 'a1f00000-0000-4000-8000-000000000006');
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-V C5: enfant change camera_policy (%)', n; end if;
  update public.wallets set currency = 'USD';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-V C5: enfant modifie wallets (%)', n; end if;
  begin
    insert into public.wallet_entries (wallet_id, amount_minor, currency, reference_type)
      values ('a1f00000-0000-4000-8000-0000000000a1', 50000, 'EUR', 'credit');
    raise exception 'L1-V C6: enfant credite le portefeuille';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V C6: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    insert into public.lesson_reports (session_id, idempotency_key, author_profile_id, content)
      values ('a1f00000-0000-4000-8000-0000000000c1', 'l1v-forge', 'a1f00000-0000-4000-8000-000000000005', '{}');
    raise exception 'L1-V C6: enfant ecrit un cahier';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V C6b: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    update public.student_profiles set student_type = 'autonomous'
     where profile_id = 'a1f00000-0000-4000-8000-000000000005';
    raise exception 'L1-V C7: enfant se declare autonome';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V C7: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  raise notice 'L1-V OK C1-C7 : enfant sans finances, sans seances ni cahier ni presence de sa soeur, sans ecriture';

  -- Profil d'apprentissage de la soeur : table et vue.
  select count(*) into n from public.student_profiles where profile_id = 'a1f00000-0000-4000-8000-000000000006';
  if n <> 0 then
    raise notice 'L1-V DEFAUT C8 : enfant lit student_profiles de sa soeur (% ligne)', n;
  else
    raise notice 'L1-V OK C8 : student_profiles de la soeur invisible par la table (la sous-requete sur profiles est filtree par la RLS)';
  end if;
  select count(*) into n from public.profils_du_foyer_v where id = 'a1f00000-0000-4000-8000-000000000006';
  if n <> 0 then
    raise exception 'L1-V C9: enfant lit profils_du_foyer_v de sa soeur (prenom, matricule, camera, interface, fin d''acces) : % ligne', n;
  end if;
  select count(*) into n from public.profils_du_foyer_v where id = 'a1f00000-0000-4000-8000-000000000005';
  if n <> 1 then raise exception 'L1-V C9: enfant ne lit plus sa propre ligne (%)', n; end if;
  select count(*) into n from public.profils_du_foyer_v;
  if n <> 1 then raise exception 'L1-V C9: enfant lit % lignes de profils_du_foyer_v, attendu 1', n; end if;
  raise notice 'L1-V OK C9 : profils_du_foyer_v ne montre pas la soeur, l''enfant lit sa propre ligne';
end $$;
reset role;

-- C9b. Le tuteur du foyer F1 lit toujours ses deux enfants dans la vue ; l'adulte
-- autonome (F2) lit sa propre ligne.
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"a1f00000-0000-4000-8000-0000000000f1"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.profils_du_foyer_v;
  if n <> 2 then raise exception 'L1-V C9b: le tuteur F1 lit % lignes de profils_du_foyer_v, attendu 2', n; end if;
  raise notice 'L1-V OK C9b : le tuteur lit ses 2 enfants dans profils_du_foyer_v';
end $$;
reset role;
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000007', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"student","household_id":"a1f00000-0000-4000-8000-0000000000f2"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.profils_du_foyer_v;
  if n <> 1 then raise exception 'L1-V C9b: l''adulte autonome lit % lignes de profils_du_foyer_v, attendu 1', n; end if;
  raise notice 'L1-V OK C9b : l''adulte autonome lit sa propre ligne';
end $$;
reset role;

-- C10. Claims forges : un enfant qui porterait le foyer F2, un adulte autonome
-- qui porterait le foyer F1. Le hook pose le vrai foyer ; ce bloc mesure si les
-- policies recoupent le claim avec profiles.household_id.
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000005', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"student","household_id":"a1f00000-0000-4000-8000-0000000000f2"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets;
  if n <> 0 then raise exception 'L1-V C10: enfant au foyer forge lit wallets (%)', n; end if;
  select count(*) into n from public.wallet_entries;
  if n <> 0 then raise exception 'L1-V C10: enfant au foyer forge lit wallet_entries (%)', n; end if;
  raise notice 'L1-V OK C10 : un enfant au foyer forge ne lit rien (le role suffit a fermer)';
end $$;
reset role;
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000007', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"student","household_id":"a1f00000-0000-4000-8000-0000000000f1"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets where household_id = 'a1f00000-0000-4000-8000-0000000000f1';
  if n <> 0 then
    raise notice 'L1-V CONSTAT C11 : un adulte autonome dont le claim household_id serait faux lit le portefeuille de ce foyer (% ligne) ; les policies font confiance au claim signe, sans recouper profiles.household_id', n;
  else
    raise notice 'L1-V OK C11 : claim household_id recoupe (la sous-requete student_profiles passe par profiles du titulaire)';
  end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000004', true);
select set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"a1f00000-0000-4000-8000-0000000000f2"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.wallets where household_id = 'a1f00000-0000-4000-8000-0000000000f2';
  if n <> 0 then
    raise notice 'L1-V CONSTAT C12 : un tuteur dont le claim household_id serait faux lit le portefeuille de ce foyer (% ligne) ; la branche tuteur fait confiance au claim signe', n;
  else
    raise notice 'L1-V OK C12 : claim household_id du tuteur recoupe';
  end if;
end $$;
reset role;

-- ============================================================
-- D. L1-08 : ce qu'un compte suspendu peut encore faire.
-- ============================================================
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
declare n int; v_ok boolean;
begin
  select count(*) into n from public.profiles where id <> auth.uid();
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit % profils', n; end if;
  select count(*) into n from public.sessions;
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit % seances', n; end if;
  select count(*) into n from public.audit_logs;
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit le journal (%)', n; end if;
  select count(*) into n from public.wallets;
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit wallets (%)', n; end if;
  select count(*) into n from public.wallet_entries;
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit wallet_entries (%)', n; end if;
  select count(*) into n from public.lesson_reports;
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit les cahiers (%)', n; end if;
  select count(*) into n from public.mes_seances_v;
  if n <> 0 then raise exception 'L1-V D1: admin suspendu lit mes_seances_v (%)', n; end if;
  update public.profiles set first_name = 'Pirate' where id = 'a1f00000-0000-4000-8000-000000000003';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'L1-V D2: admin suspendu ecrit un profil (%)', n; end if;
  begin
    perform public.decider_dossier(gen_random_uuid(), true, null);
    raise exception 'L1-V D3: decider_dossier passe pour un admin suspendu';
  exception when others then
    if sqlerrm not like 'seul un administrateur%' then raise exception 'L1-V D3: %', sqlerrm; end if;
  end;
  raise notice 'L1-V OK D1-D3 : admin suspendu sans lecture ni ecriture REST, decider_dossier refuse';

  -- Vues et RPC hors du perimetre de L1-08.
  select count(*) into n from public.presence_seance_v;
  if n <> 0 then
    raise exception 'L1-V D4: admin suspendu lit presence_seance_v (% lignes, prenoms et etats de presence de toute l''academie)', n;
  else
    raise notice 'L1-V OK D4 : presence_seance_v vide pour un admin suspendu';
  end if;
  begin
    v_ok := public.geler_archive_seance('a1f00000-0000-4000-8000-0000000000e1', null, false);
    raise exception 'L1-V D5: admin suspendu leve le gel de conservation d''un enregistrement (retour %)', v_ok using errcode = 'P0001';
  exception when others then
    if sqlstate <> '42501' then
      raise exception 'L1-V D5: geler_archive_seance, SQLSTATE % (42501 attendu) : %', sqlstate, sqlerrm;
    end if;
    raise notice 'L1-V OK D5 : geler_archive_seance refuse un admin suspendu (SQLSTATE %)', sqlstate;
  end;
end $$;
reset role;
do $$
begin
  if (select legal_hold_since from public.session_recordings where id = 'a1f00000-0000-4000-8000-0000000000e1') is null then
    raise exception 'L1-V D5: legal_hold_since est NULL apres l''appel de l''admin suspendu';
  end if;
end $$;

-- D6. Controleur suspendu : ni journal ni presence.
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000009', true);
select set_config('request.jwt.claims', '{"app_metadata":{"role":"controller"}}', true);
set local role authenticated;
do $$
declare n int;
begin
  select count(*) into n from public.audit_logs;
  if n <> 0 then raise exception 'L1-V D6: controleur suspendu lit le journal (%)', n; end if;
  select count(*) into n from public.presence_seance_v;
  if n <> 0 then
    raise exception 'L1-V D6: controleur suspendu lit presence_seance_v (% lignes)', n;
  end if;
end $$;
reset role;

-- D7. Enseignant suspendu : les trois policies de depot gardees « ni disabled ni
-- supprime » le refusent ; signer_contrat aussi.
select set_config('request.jwt.claim.sub', 'a1f00000-0000-4000-8000-000000000008', true);
select set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
set local role authenticated;
do $$
begin
  begin
    insert into public.kyc_documents (profile_id, doc_type, gender, object_key)
      values ('a1f00000-0000-4000-8000-000000000008', 'id_card', 'male',
              'a1f00000-0000-4000-8000-000000000008/piece.webp');
    raise exception 'L1-V D7: enseignant suspendu depose une piece';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V D7: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  begin
    insert into public.contract_acceptances (profile_id, contract_kind, version)
      values ('a1f00000-0000-4000-8000-000000000008', 'teacher_nda', 'v1');
    raise exception 'L1-V D7b: enseignant suspendu signe';
  exception when others then
    if sqlstate not in ('42501', '23502') then raise exception 'L1-V D7b: SQLSTATE % : %', sqlstate, sqlerrm; end if;
    if sqlstate = '23502' then raise notice 'L1-V D7b : contrainte NOT NULL avant la RLS, refus non prouve par ce test'; end if;
  end;
  begin
    perform public.signer_contrat('v1', 'Enseignant Suspendu');
    raise exception 'L1-V D7c: signer_contrat accepte un compte suspendu';
  exception when others then
    if sqlstate <> '42501' then raise exception 'L1-V D7c: SQLSTATE % : %', sqlstate, sqlerrm; end if;
  end;
  raise notice 'L1-V OK D7 : enseignant suspendu ne depose ni piece ni signature';
end $$;
reset role;

-- D8. Les huit policies laissees sans app_account_valid(), liste exacte.
do $$
declare v_liste text;
begin
  select string_agg(tablename || '.' || policyname, ', ' order by tablename || '.' || policyname)
    into v_liste
    from pg_policies
   where schemaname = 'public'
     and (coalesce(qual,'') || coalesce(with_check,'')) like '%app_role()%'
     and (coalesce(qual,'') || coalesce(with_check,'')) not like '%app_account_valid%';
  if v_liste is distinct from 'contract_acceptances.contract_acceptances_self_insert, households.households_guardian_select, intentions_horaire.intentions_horaire_parties, kyc_documents.kyc_guardian_insert, kyc_documents.kyc_staff_self_insert, offres_horaires.offres_horaires_vitrine, profiles.profiles_family_select, student_reading_position.srp_foyer_lecture' then
    raise exception 'L1-V D8: liste des policies laissees differente : %', v_liste;
  end if;
  raise notice 'L1-V OK D8 : huit policies laissees, liste exacte : %', v_liste;
end $$;

rollback;
select 'L1-V contournements PASS' as resultat;
