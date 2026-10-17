-- AF L2-08 (ALIGN-1410-BACK) : reglages serveur des decisions du 29/09 au 14/10.
-- Cohortes 6-9 / 10-13 / 14-17 / 18+, age minimum 6 ans avec exception tracee
-- par l'administration, minimum 4, pause 5, capacite debutant 4.
begin;

alter table auth.users add column if not exists raw_app_meta_data jsonb not null default '{}'::jsonb;
alter table auth.users add column if not exists created_at timestamptz default now();

insert into auth.users (id, email) values
  ('a2080000-0000-0000-0000-000000000001', 'l208-guardian@example.test'),
  ('a2080000-0000-0000-0000-000000000002', 'l208-admin@example.test'),
  ('a2080000-0000-0000-0000-000000000011', 'l208-e5@example.test'),
  ('a2080000-0000-0000-0000-000000000012', 'l208-e5b@example.test'),
  ('a2080000-0000-0000-0000-000000000013', 'l208-e7@example.test'),
  ('a2080000-0000-0000-0000-000000000014', 'l208-e11@example.test'),
  ('a2080000-0000-0000-0000-000000000015', 'l208-e15@example.test'),
  ('a2080000-0000-0000-0000-000000000016', 'l208-e18@example.test'),
  ('a2080000-0000-0000-0000-000000000017', 'l208-e5c@example.test'),
  ('a2080000-0000-0000-0000-000000000018', 'l208-e7a@example.test'),
  ('a2080000-0000-0000-0000-000000000019', 'l208-e5d@example.test'),
  ('a2080000-0000-0000-0000-000000000020', 'l208-autre-tuteur@example.test');
update auth.users set raw_app_meta_data = jsonb_build_object(
  'child_of', 'a2080000-0000-0000-0000-000000000001')
 where id::text like 'a2080000-0000-0000-0000-0000000000_%' and id::text >= 'a2080000-0000-0000-0000-000000000011'
   and id::text <> 'a2080000-0000-0000-0000-000000000019'
   and id::text <> 'a2080000-0000-0000-0000-000000000020';
-- Le compte ...19 porte un child_of etranger au tuteur du test (l'autre tuteur).
update auth.users set raw_app_meta_data = jsonb_build_object(
  'child_of', 'a2080000-0000-0000-0000-000000000020')
 where id = 'a2080000-0000-0000-0000-000000000019';

insert into public.households (id, timezone)
values ('a208ffff-0000-0000-0000-000000000001', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('a2080000-0000-0000-0000-000000000001', null, 'guardian',
   'a208ffff-0000-0000-0000-000000000001', 'Amira', 'L208', 'active'),
  ('a2080000-0000-0000-0000-000000000002', null, 'admin',
   null, 'Admin', 'L208', 'active');

-- 1. Valeurs de configuration.
do $config$
begin
  if public.app_config_int('groupe.minimum_lancement', 0) <> 4 then
    raise exception 'L2-08: minimum_lancement = %', public.app_config_int('groupe.minimum_lancement', 0);
  end if;
  if public.app_config_int('seance.pause_minutes_enfant', 0) <> 5 then
    raise exception 'L2-08: pause enfant = %', public.app_config_int('seance.pause_minutes_enfant', 0);
  end if;
  if public.app_config_int('groupe.capacite_debutant', 0) <> 4 then
    raise exception 'L2-08: capacite_debutant = %', public.app_config_int('groupe.capacite_debutant', 0);
  end if;
  if public.app_config_int('groupe.capacite_enfant', 0) <> 5
     or public.app_config_int('groupe.capacite_adulte', 0) <> 6 then
    raise exception 'L2-08: capacites enfant/adulte alterees';
  end if;
  if public.app_config_int('child_ui_mode_max_age', 0) <> 9 then
    raise exception 'L2-08: child_ui_mode_max_age = %', public.app_config_int('child_ui_mode_max_age', 0);
  end if;
end;
$config$;

-- 2. Cohortes : exactement quatre codes, avec leurs bornes et deductions.
do $cohortes$
declare
  v_liste text;
begin
  select string_agg(format('%s:%s:%s:%s:%s:%s', code, age_min, coalesce(age_max_inclus::text, ''),
           student_type, interface_mode, nom_humain), '|' order by ordre, code)
    into v_liste from public.cohortes_age;
  if v_liste is distinct from
     'enfant_6_9:6:9:minor:child:6 à 9 ans|enfant_10_13:10:13:minor:standard:10 à 13 ans|ado_14_17:14:17:minor:standard:14 à 17 ans|adulte_18_plus:18::autonomous:standard:18 ans et plus' then
    raise exception 'L2-08: cohortes = %', v_liste;
  end if;
  if exists (select 1 from public.student_profiles sp
              where sp.cohorte is not null
                and sp.cohorte not in (select code from public.cohortes_age)) then
    raise exception 'L2-08: cohorte orpheline';
  end if;
end;
$cohortes$;

-- 3. creer_profil_enfant.
create function pg_temp.l208_essai(
  p_actor uuid, p_role text, p_child uuid, p_age integer, p_motif text
) returns text language plpgsql as $essai$
begin
  perform set_config('request.jwt.claim.sub', p_actor::text, true);
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', p_actor, 'role', 'authenticated',
      'app_metadata', jsonb_build_object('role', p_role))::text, true);
  begin
    set local role authenticated;
    perform public.creer_profil_enfant(p_child, 'a2080000-0000-0000-0000-000000000001',
      'Enfant', 'L208', p_age, null, p_motif);
    reset role;
    return 'ok';
  exception when others then
    reset role;
    return sqlstate;
  end;
end;
$essai$;

do $age$
declare
  v_g constant uuid := 'a2080000-0000-0000-0000-000000000001';
  v_a constant uuid := 'a2080000-0000-0000-0000-000000000002';
  v_r text;
  v_msg text;
begin
  -- 5 ans sans motif : refus check_violation 23514, message exact.
  v_r := pg_temp.l208_essai(v_g, 'guardian', 'a2080000-0000-0000-0000-000000000011', 5, null);
  if v_r <> '23514' then raise exception 'L2-08: 5 ans sans motif, sqlstate %', v_r; end if;
  begin
    set local role authenticated;
    perform set_config('request.jwt.claim.sub', v_g::text, true);
    perform set_config('request.jwt.claims',
      '{"sub":"a2080000-0000-0000-0000-000000000001","app_metadata":{"role":"guardian"}}', true);
    perform public.creer_profil_enfant('a2080000-0000-0000-0000-000000000011', v_g, 'E', 'L', 5, null);
  exception when check_violation then
    get stacked diagnostics v_msg = message_text;
  end;
  reset role;
  if v_msg is distinct from 'âge minimum 6 ans' then
    raise exception 'L2-08: message = %', v_msg;
  end if;

  -- 5 ans avec motif, mais fourni par le tuteur : toujours refuse.
  v_r := pg_temp.l208_essai(v_g, 'guardian', 'a2080000-0000-0000-0000-000000000011', 5, 'je veux');
  if v_r <> '23514' then raise exception 'L2-08: tuteur avec motif, sqlstate %', v_r; end if;
  -- 5 ans, administrateur sans motif (ou motif blanc) : refuse.
  v_r := pg_temp.l208_essai(v_a, 'admin', 'a2080000-0000-0000-0000-000000000011', 5, '   ');
  if v_r not in ('23514', '42501') then raise exception 'L2-08: admin sans motif, sqlstate %', v_r; end if;
  if exists (select 1 from public.profiles where id = 'a2080000-0000-0000-0000-000000000011') then
    raise exception 'L2-08: un refus a laisse un profil';
  end if;

  -- 5 ans, administrateur valide avec motif : accepte, journalise.
  v_r := pg_temp.l208_essai(v_a, 'admin', 'a2080000-0000-0000-0000-000000000012', 5, 'dispense accordee, frere aine inscrit');
  if v_r <> 'ok' then raise exception 'L2-08: exception admin, sqlstate %', v_r; end if;
  if not exists (select 1 from public.profiles
                  where id = 'a2080000-0000-0000-0000-000000000012' and role = 'student') then
    raise exception 'L2-08: profil 5 ans absent';
  end if;
  if (select count(*) from public.audit_logs
       where action = 'age_exception' and row_id = 'a2080000-0000-0000-0000-000000000012'
         and payload ->> 'motif' = 'dispense accordee, frere aine inscrit'
         and payload ->> 'admin_id' = v_a::text) <> 1 then
    raise exception 'L2-08: exception d''age non journalisee';
  end if;

  -- Reprise D-6. L'exception ne vaut que sous 6 ans.
  -- Administrateur avec motif pour 7 ans, tuteur different de l'appelant : la
  -- voie tuteur s'applique, donc refus 42501 et aucun profil.
  v_r := pg_temp.l208_essai(v_a, 'admin', 'a2080000-0000-0000-0000-000000000018', 7, 'motif quelconque');
  if v_r <> '42501' then raise exception 'L2-08 D-6: admin 7 ans avec motif, sqlstate %', v_r; end if;
  if exists (select 1 from public.profiles where id = 'a2080000-0000-0000-0000-000000000018') then
    raise exception 'L2-08 D-6: un refus a laisse un profil';
  end if;
  -- Administrateur avec motif pour 5 ans, mais compte enfant dont child_of
  -- n'est pas ce tuteur : l'exception ne contourne pas le lien child_of.
  v_r := pg_temp.l208_essai(v_a, 'admin', 'a2080000-0000-0000-0000-000000000019', 5, 'dispense accordee');
  if v_r <> '42501' then raise exception 'L2-08 D-6: admin 5 ans, child_of etranger, sqlstate %', v_r; end if;
  if exists (select 1 from public.profiles where id = 'a2080000-0000-0000-0000-000000000019') then
    raise exception 'L2-08 D-6: child_of etranger a laisse un profil';
  end if;
  -- Le 5 ans accepte plus haut est journalise une seule fois, avec l'age.
  if (select count(*) from public.audit_logs
       where action = 'age_exception' and payload ->> 'age' = '5') <> 1 then
    raise exception 'L2-08 D-6: journal age_exception inattendu';
  end if;

  -- Un tuteur ne peut pas lancer la voie administrateur pour un autre foyer
  -- et un compte non administrateur n'est pas un administrateur : deja couvert
  -- ci-dessus. La borne haute reste 99 (decision inchangee) : 100 ans refuse.
  v_r := pg_temp.l208_essai(v_g, 'guardian', 'a2080000-0000-0000-0000-000000000016', 100, null);
  if v_r <> 'P0001' then raise exception 'L2-08: 100 ans, sqlstate %', v_r; end if;

  -- Deduction de la cohorte par l'age, cote serveur.
  v_r := pg_temp.l208_essai(v_g, 'guardian', 'a2080000-0000-0000-0000-000000000013', 7, null);
  if v_r <> 'ok' then raise exception 'L2-08: 7 ans, sqlstate %', v_r; end if;
  v_r := pg_temp.l208_essai(v_g, 'guardian', 'a2080000-0000-0000-0000-000000000014', 11, null);
  if v_r <> 'ok' then raise exception 'L2-08: 11 ans, sqlstate %', v_r; end if;
  v_r := pg_temp.l208_essai(v_g, 'guardian', 'a2080000-0000-0000-0000-000000000015', 15, null);
  if v_r <> 'ok' then raise exception 'L2-08: 15 ans, sqlstate %', v_r; end if;
  if (select cohorte from public.student_profiles where profile_id = 'a2080000-0000-0000-0000-000000000013') <> 'enfant_6_9'
     or (select interface_mode from public.student_profiles where profile_id = 'a2080000-0000-0000-0000-000000000013') <> 'child'
     or (select cohorte from public.student_profiles where profile_id = 'a2080000-0000-0000-0000-000000000014') <> 'enfant_10_13'
     or (select interface_mode from public.student_profiles where profile_id = 'a2080000-0000-0000-0000-000000000014') <> 'standard'
     or (select cohorte from public.student_profiles where profile_id = 'a2080000-0000-0000-0000-000000000015') <> 'ado_14_17' then
    raise exception 'L2-08: cohorte deduite de l''age incorrecte';
  end if;
  -- L'enfant exceptionnel de 5 ans n'entre dans aucune cohorte.
  if (select cohorte from public.student_profiles where profile_id = 'a2080000-0000-0000-0000-000000000012') is not null then
    raise exception 'L2-08: cohorte posee pour 5 ans';
  end if;
end;
$age$;

-- 4. Droits : la surcharge est ouverte aux comptes connectes seulement.
do $acl$
declare
  v_fn text;
begin
  foreach v_fn in array array[
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text)',
    'public.creer_profil_enfant(uuid,uuid,text,text,integer,text,text)'
  ] loop
    if not has_function_privilege('authenticated', v_fn, 'EXECUTE')
       or has_function_privilege('anon', v_fn, 'EXECUTE')
       or has_function_privilege('service_role', v_fn, 'EXECUTE')
       or has_function_privilege('agent_ro', v_fn, 'EXECUTE') then
      raise exception 'L2-08: droits EXECUTE incorrects sur %', v_fn;
    end if;
  end loop;
end;
$acl$;

rollback;
