-- L1-01 : les fonctions du serveur refusent un compte connecte, meme administrateur.
-- Les deux triggers d'audit (regles de remuneration, coffres) restent fonctionnels
-- pour un administrateur aal2 : ils passent en SECURITY DEFINER.
begin;
insert into auth.users (id, email, email_confirmed_at)
  values ('00000000-0000-0000-0000-000000000a01', 'l1-01@test.invalid', now())
  on conflict do nothing;
insert into public.profiles (id, role, first_name, last_name, account_status)
  values ('00000000-0000-0000-0000-000000000a01', 'admin', 'L1', 'Admin', 'active')
  on conflict do nothing;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000a01', true);
select set_config('request.jwt.claims', '{"aal":"aal2","app_metadata":{"role":"admin"}}', true);
set local role authenticated;
do $$
begin
  begin
    perform public.record_session_event('00000000-0000-0000-0000-000000000b01', '00000000-0000-0000-0000-000000000a01', 'joined', 'user_action');
    raise exception 'L1-01: record_session_event accepte sous authenticated';
  exception when others then
    if sqlstate <> '42501' then
      raise exception 'L1-01: record_session_event SQLSTATE % (attendu 42501) : %', sqlstate, sqlerrm;
    end if;
  end;
  begin
    perform public.log_sensitive_access('test', 'profiles', 'x', '{}'::jsonb);
    raise exception 'L1-01: log_sensitive_access accepte sous authenticated';
  exception when others then
    if sqlstate <> '42501' then
      raise exception 'L1-01: log_sensitive_access SQLSTATE % (attendu 42501) : %', sqlstate, sqlerrm;
    end if;
  end;
  begin
    perform public.materialiser_seances('00000000-0000-0000-0000-000000000c01');
    raise exception 'L1-01: materialiser_seances accepte sous authenticated';
  exception when others then
    if sqlstate <> '42501' then
      raise exception 'L1-01: materialiser_seances SQLSTATE % (attendu 42501) : %', sqlstate, sqlerrm;
    end if;
  end;
end $$;
-- Sonde : un insert de regle par un admin aal2 traverse toujours le trigger d'audit.
insert into public.regles_remuneration_enseignant (enseignant_id, taux_minor_par_heure, devise, date_effet, motif, cree_par)
  values (null, 1000, 'EUR', current_date, 'L1-01 sonde', '00000000-0000-0000-0000-000000000a01');
reset role;
do $$
begin
  if not has_function_privilege('service_role', 'public.record_session_event(uuid,uuid,session_event_type,text)', 'execute')
     or not has_function_privilege('service_role', 'public.log_sensitive_access(text,text,text,jsonb)', 'execute')
     or not has_function_privilege('service_role', 'public.materialiser_seances(uuid)', 'execute') then
    raise exception 'L1-01: service_role a perdu EXECUTE sur une fonction serveur';
  end if;
  if not (select p.prosecdef from pg_catalog.pg_proc p
           where p.oid = 'public.auditer_regle_remuneration_enseignant()'::regprocedure)
     or not (select p.prosecdef from pg_catalog.pg_proc p
           where p.oid = 'public.x217_valider_politique_coffres()'::regprocedure) then
    raise exception 'L1-01: trigger d''audit non SECURITY DEFINER';
  end if;
end $$;
rollback;
