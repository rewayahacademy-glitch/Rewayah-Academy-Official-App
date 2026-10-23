-- PE (18/10/2026) : protection des enfants.
--   1. un signalement de securite d'un enfant est lu par la direction, jamais
--      par l'enseignant concerne ni par la famille, et ne se transmet pas ;
--   2. l'acceptation du code de conduite est tracee (version, date), reservee
--      a l'enseignant, a la version requise, et ne se modifie pas ;
--   3. seule l'administration modifie le responsable de la protection des enfants.
-- Base PostgreSQL jetable apres rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('be000000-0000-0000-0000-000000000001', 'pe-admin@example.test'),
  ('be000000-0000-0000-0000-000000000002', 'pe-teacher-a@example.test'),
  ('be000000-0000-0000-0000-000000000003', 'pe-teacher-b@example.test'),
  ('be000000-0000-0000-0000-000000000004', 'pe-guardian@example.test'),
  ('be000000-0000-0000-0000-000000000005', 'pe-student@example.test');

insert into public.households (id, timezone)
values ('befffff0-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('be000000-0000-0000-0000-000000000001', 'PEADMIN000001', 'admin',
   'befffff0-0000-0000-0000-000000000001', 'Fixture', 'Admin', 'active', 'male'),
  ('be000000-0000-0000-0000-000000000002', 'PETEACHER0001', 'teacher',
   'befffff0-0000-0000-0000-000000000001', 'Teacher', 'One', 'provisional_active', 'male'),
  ('be000000-0000-0000-0000-000000000003', 'PETEACHER0002', 'teacher',
   'befffff0-0000-0000-0000-000000000001', 'Teacher', 'Two', 'provisional_active', 'female'),
  ('be000000-0000-0000-0000-000000000004', 'PEGUARDIAN001', 'guardian',
   'befffff0-0000-0000-0000-000000000001', 'Fixture', 'Guardian', 'active', 'female'),
  ('be000000-0000-0000-0000-000000000005', 'PESTUDENT0001', 'student',
   'befffff0-0000-0000-0000-000000000001', 'Fixture', 'Student', 'active', 'male');

insert into public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values
  ('be000000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris'),
  ('be000000-0000-0000-0000-000000000003', array['francais'], 10, 'approved', 'Europe/Paris');

update public.households
   set primary_guardian_id = 'be000000-0000-0000-0000-000000000004'
 where id = 'befffff0-0000-0000-0000-000000000001';

insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('be000000-0000-0000-0000-000000000005', 'minor', 'child');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('befffff0-0000-0000-0000-000000000002',
   'be000000-0000-0000-0000-000000000002', 'enfant', 5, 'PE groupe A', 1, 10);

insert into public.groupe_membres (groupe_id, student_id)
values ('befffff0-0000-0000-0000-000000000002',
        'be000000-0000-0000-0000-000000000005');

-- ===========================================================================
-- 1. Signalement de securite d'un enfant
-- ===========================================================================
set local role authenticated;
select set_config('test.uid', 'be000000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);

do $pe_depot$
declare
  v_res jsonb;
  v_ordinaire jsonb;
  v_n integer;
begin
  -- Le message famille est ecarte, le signalement est prioritaire.
  v_res := public.deposer_student_concern(
    'securite_enfant', 'befffff0-0000-0000-0000-000000000002', null,
    'PESTUDENT0001', 'PE note securite', 'Un message qui ne doit pas rester');
  if (v_res ->> 'prioritaire')::boolean is not true
     or v_res ->> 'family_summary' is not null
     or v_res ->> 'categorie' <> 'securite_enfant' then
    raise exception 'PE: depot securite_enfant mal enregistre: %', v_res;
  end if;

  v_ordinaire := public.deposer_student_concern(
    'pedagogique', 'befffff0-0000-0000-0000-000000000002', null,
    'PESTUDENT0001', 'PE note ordinaire', null);
  if (v_ordinaire ->> 'prioritaire')::boolean is not false then
    raise exception 'PE: un signalement ordinaire ne doit pas etre prioritaire';
  end if;

  -- Celui qui l'a depose ne le relit pas : ni par la RPC, ni par la table.
  select count(*) into v_n from public.mes_student_concerns(null);
  if v_n <> 1 then
    raise exception 'PE: la liste de l enseignant doit exclure la securite d un enfant (%)', v_n;
  end if;
  select count(*) into v_n from public.student_concern
   where categorie::text = 'securite_enfant';
  if v_n <> 0 then
    raise exception 'PE: l enseignant depositaire lit la table (%)', v_n;
  end if;

  begin
    perform public.deposer_student_concern(
      'inconnue', 'befffff0-0000-0000-0000-000000000002', null,
      'PESTUDENT0001', 'x', null);
    raise exception 'PE: categorie inconnue acceptee';
  exception when raise_exception then
    if sqlerrm <> 'categorie de signalement invalide' then raise; end if;
  end;
end
$pe_depot$;

-- Un signalement qui concerne l'enseignant du groupe, depose par un autre
-- canal (ici insere par le proprietaire, avec teacher_id = l'enseignant concerne).
reset role;
insert into public.student_concern
  (categorie, groupe_id, student_id, teacher_id, internal_details, prioritaire)
values
  ('securite_enfant', 'befffff0-0000-0000-0000-000000000002',
   'be000000-0000-0000-0000-000000000005',
   'be000000-0000-0000-0000-000000000002', 'PE sur l enseignant', true);

-- Une contrainte interdit un message famille sur la securite d'un enfant.
do $pe_contrainte$
begin
  begin
    insert into public.student_concern
      (categorie, groupe_id, student_id, teacher_id, internal_details,
       prioritaire, family_summary)
    values
      ('securite_enfant', 'befffff0-0000-0000-0000-000000000002',
       'be000000-0000-0000-0000-000000000005',
       'be000000-0000-0000-0000-000000000002', 'x', true, 'message famille');
    raise exception 'PE: message famille accepte sur securite_enfant';
  exception when check_violation then
    null;
  end;
end
$pe_contrainte$;

-- L'enseignant concerne : rien.
set local role authenticated;
select set_config('test.uid', 'be000000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_concerne$
declare
  v_n integer;
begin
  select count(*) into v_n from public.student_concern
   where categorie::text = 'securite_enfant';
  if v_n <> 0 then
    raise exception 'PE: l enseignant concerne lit un signalement de securite (%)', v_n;
  end if;
  select count(*) into v_n from public.mes_student_concerns(null) m
   where m ->> 'categorie' = 'securite_enfant';
  if v_n <> 0 then
    raise exception 'PE: la RPC rend un signalement de securite a l enseignant';
  end if;
  -- Il lit toujours ses signalements ordinaires.
  select count(*) into v_n from public.student_concern;
  if v_n <> 1 then
    raise exception 'PE: l enseignant doit lire son signalement ordinaire (%)', v_n;
  end if;
end
$pe_concerne$;

-- Un autre enseignant : rien non plus.
select set_config('test.uid', 'be000000-0000-0000-0000-000000000003', true);
do $pe_autre$
declare
  v_n integer;
begin
  select count(*) into v_n from public.student_concern;
  if v_n <> 0 then
    raise exception 'PE: un autre enseignant lit des signalements (%)', v_n;
  end if;
end
$pe_autre$;

-- La famille : rien, ni dans la table ni dans la vue.
select set_config('test.uid', 'be000000-0000-0000-0000-000000000004', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_famille$
declare
  v_n integer;
begin
  select count(*) into v_n from public.student_concern;
  if v_n <> 0 then
    raise exception 'PE: la famille lit la table (%)', v_n;
  end if;
  select count(*) into v_n from public.concern_famille_v;
  if v_n <> 0 then
    raise exception 'PE: la famille lit la vue (%)', v_n;
  end if;
  begin
    perform public.signalements_ouverts_direction();
    raise exception 'PE: la famille appelle la file de la direction';
  exception when raise_exception then
    if sqlerrm <> 'lecture reservee a la direction' then raise; end if;
  end;
end
$pe_famille$;

-- La direction : lit tout, securite d'un enfant en premier, ne transmet pas.
select set_config('test.uid', 'be000000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_direction$
declare
  v_n integer;
  v_premier jsonb;
  v_securite uuid;
begin
  select count(*) into v_n from public.student_concern
   where categorie::text = 'securite_enfant';
  if v_n <> 2 then
    raise exception 'PE: la direction doit lire les deux signalements de securite (%)', v_n;
  end if;

  select s into v_premier from public.signalements_ouverts_direction() s limit 1;
  if v_premier ->> 'categorie' <> 'securite_enfant'
     or (v_premier ->> 'prioritaire')::boolean is not true then
    raise exception 'PE: la file de la direction doit commencer par la securite (%)', v_premier;
  end if;
  select count(*) into v_n from public.signalements_ouverts_direction();
  if v_n <> 3 then
    raise exception 'PE: la file de la direction doit rendre 3 lignes (%)', v_n;
  end if;

  select id into v_securite from public.student_concern
   where internal_details = 'PE note securite';
  begin
    perform public.transmettre_student_concern(v_securite, 'tuteur_du_mineur');
    raise exception 'PE: un signalement de securite a ete transmis';
  exception when raise_exception then
    if sqlerrm <> 'signalement de securite d''un enfant non transmissible' then raise; end if;
  end;
end
$pe_direction$;

-- ===========================================================================
-- 2. Code de conduite de l'enseignant
-- ===========================================================================
select set_config('test.uid', 'be000000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_code$
declare
  v_version text := public.code_conduite_version_requise();
  v_n integer;
  v_quand timestamptz;
begin
  if v_version is null then
    raise exception 'PE: version requise du code de conduite absente';
  end if;

  -- Une version qui n'est pas la version requise est refusee.
  begin
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values ('be000000-0000-0000-0000-000000000002', 'teacher_conduct_code', 'ancienne');
    raise exception 'PE: version perimee acceptee';
  exception when insufficient_privilege then
    null;
  end;

  -- On n'accepte pas pour un autre.
  begin
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values ('be000000-0000-0000-0000-000000000003', 'teacher_conduct_code', v_version);
    raise exception 'PE: acceptation au nom d un autre';
  exception when insufficient_privilege then
    null;
  end;

  insert into public.contract_acceptances (profile_id, contract_kind, version)
  values ('be000000-0000-0000-0000-000000000002', 'teacher_conduct_code', v_version);

  select count(*), max(accepted_at) into v_n, v_quand
    from public.contract_acceptances
   where contract_kind = 'teacher_conduct_code' and version = v_version;
  if v_n <> 1 or v_quand is null then
    raise exception 'PE: acceptation non tracee (% lignes)', v_n;
  end if;

  -- Une seule fois par version.
  begin
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values ('be000000-0000-0000-0000-000000000002', 'teacher_conduct_code', v_version);
    raise exception 'PE: double acceptation';
  exception when unique_violation then
    null;
  end;

  -- Une acceptation ne se modifie ni ne s'efface.
  begin
    update public.contract_acceptances set version = 'x'
     where contract_kind = 'teacher_conduct_code';
    raise exception 'PE: acceptation modifiee';
  exception when insufficient_privilege then
    null;
  end;
  begin
    delete from public.contract_acceptances
     where contract_kind = 'teacher_conduct_code';
    raise exception 'PE: acceptation effacee';
  exception when insufficient_privilege then
    null;
  end;
end
$pe_code$;

-- Une famille ne peut pas accepter le code de conduite.
select set_config('test.uid', 'be000000-0000-0000-0000-000000000004', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_code_famille$
begin
  begin
    insert into public.contract_acceptances (profile_id, contract_kind, version)
    values ('be000000-0000-0000-0000-000000000004', 'teacher_conduct_code',
            public.code_conduite_version_requise());
    raise exception 'PE: une famille a accepte le code de conduite';
  exception when insufficient_privilege then
    null;
  end;
end
$pe_code_famille$;

-- La direction lit l'acceptation.
select set_config('test.uid', 'be000000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_code_direction$
declare
  v_n integer;
begin
  select count(*) into v_n from public.contract_acceptances
   where contract_kind = 'teacher_conduct_code'
     and profile_id = 'be000000-0000-0000-0000-000000000002';
  if v_n <> 1 then
    raise exception 'PE: la direction ne lit pas l acceptation (%)', v_n;
  end if;
end
$pe_code_direction$;

-- ===========================================================================
-- 3. Responsable de la protection des enfants
-- ===========================================================================
select set_config('test.uid', 'be000000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_responsable_enseignant$
declare
  v_res jsonb := public.responsable_protection_enfants();
  v_n integer;
begin
  if v_res ->> 'nom' <> '' or v_res ->> 'courriel' <> '' then
    raise exception 'PE: valeur par defaut non vide: %', v_res;
  end if;
  -- Aucune ecriture possible.
  update public.app_config set value = '"Pirate"'::jsonb
   where key = 'protection_enfants.responsable_nom';
  get diagnostics v_n = row_count;
  if v_n <> 0 then
    raise exception 'PE: un enseignant a modifie le responsable';
  end if;
end
$pe_responsable_enseignant$;

select set_config('test.uid', 'be000000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"befffff0-0000-0000-0000-000000000001"}}',
  true);
do $pe_responsable_admin$
declare
  v_res jsonb;
  v_n integer;
begin
  update public.app_config set value = '"  Sayyid Yusuf  "'::jsonb
   where key = 'protection_enfants.responsable_nom';
  get diagnostics v_n = row_count;
  if v_n <> 1 then raise exception 'PE: l administration ne modifie pas le nom'; end if;

  update public.app_config set value = '"protection@example.test"'::jsonb
   where key = 'protection_enfants.responsable_courriel';

  v_res := public.responsable_protection_enfants();
  if v_res ->> 'nom' <> 'Sayyid Yusuf'
     or v_res ->> 'courriel' <> 'protection@example.test' then
    raise exception 'PE: reglage non relu ou non nettoye: %', v_res;
  end if;

  begin
    update public.app_config set value = '"pas un courriel"'::jsonb
     where key = 'protection_enfants.responsable_courriel';
    raise exception 'PE: courriel invalide accepte';
  exception when raise_exception then
    if sqlerrm <> 'reglage de protection des enfants : courriel invalide' then raise; end if;
  end;
  begin
    update public.app_config set value = '12'::jsonb
     where key = 'protection_enfants.responsable_nom';
    raise exception 'PE: valeur non textuelle acceptee';
  exception when raise_exception then
    if sqlerrm <> 'reglage de protection des enfants : un texte est attendu' then raise; end if;
  end;

  -- Vider le reglage est permis : l'ecran redit alors « la direction ».
  update public.app_config set value = '""'::jsonb
   where key = 'protection_enfants.responsable_courriel';
end
$pe_responsable_admin$;

-- Le journal de l'historique garde l'ancienne valeur.
reset role;
do $pe_historique$
declare
  v_n integer;
begin
  select count(*) into v_n from public.app_config_history
   where key = 'protection_enfants.responsable_nom';
  if v_n < 1 then
    raise exception 'PE: le changement du responsable n est pas journalise';
  end if;
end
$pe_historique$;

-- anon : aucune des nouvelles fonctions.
do $pe_anon$
begin
  if pg_catalog.has_function_privilege('anon', 'public.responsable_protection_enfants()', 'EXECUTE')
     or pg_catalog.has_function_privilege('anon', 'public.signalements_ouverts_direction()', 'EXECUTE')
     or pg_catalog.has_function_privilege('anon', 'public.code_conduite_version_requise()', 'EXECUTE') then
    raise exception 'PE: anon a EXECUTE sur une fonction de protection des enfants';
  end if;
end
$pe_anon$;

do $pe_ok$
begin
  raise notice 'OK scenarios_pe_protection_enfants';
end
$pe_ok$;

rollback;
