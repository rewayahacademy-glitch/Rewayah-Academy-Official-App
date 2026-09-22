-- Scenarios d'acceptation du premier lot Classes/Groupes.
-- A executer sur un replay complet des migrations, apres stub_auth.sql.

do $$
declare
  v_code text;
  v_min smallint;
  v_max smallint;
begin
  select count(*)::int into v_min
  from public.cohortes_age
  where actif;
  if v_min <> 4 then
    raise exception 'CLASSES AGE : % cohortes actives au lieu de 4', v_min;
  end if;

  select code into v_code from public.cohortes_age
  where actif and age_min = 6 and age_max_inclus = 9;
  if v_code <> 'enfant_6_9' then
    raise exception 'CLASSES AGE : 6-9 absent';
  end if;

  select code into v_code from public.cohortes_age
  where actif and age_min = 10 and age_max_inclus = 13;
  if v_code <> 'enfant_10_13' then
    raise exception 'CLASSES AGE : 10-13 absent';
  end if;

  select code into v_code from public.cohortes_age
  where actif and age_min = 14 and age_max_inclus = 17;
  if v_code <> 'ado_14_17' then
    raise exception 'CLASSES AGE : 14-17 absent';
  end if;

  select age_min into v_min from public.cohortes_age
  where actif and age_max_inclus is null and type_public = 'adulte';
  if v_min <> 18 then
    raise exception 'CLASSES AGE : adulte 18+ absent';
  end if;
end $$;

do $$
begin
  if has_column_privilege(
    'authenticated', 'public.student_profiles', 'date_naissance', 'UPDATE'
  ) then
    raise exception 'CLASSES SECURITE : le client peut modifier date_naissance';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'student_profiles'
      and column_name = 'date_naissance'
  ) then
    raise exception 'CLASSES AGE : colonne date_naissance absente';
  end if;
end $$;

-- Fixture mineur/tuteur minimale, hors RLS via service_role.
insert into auth.users (id, email)
values
  ('c2300000-0000-0000-0000-000000000001', 'classes-guardian@example.test'),
  ('c2300000-0000-0000-0000-000000000002', 'classes-student@example.test')
on conflict (id) do nothing;

insert into public.households (id, timezone)
values ('c2300000-0000-0000-0000-000000000010', 'Europe/Paris')
on conflict (id) do nothing;

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('c2300000-0000-0000-0000-000000000001', 'classes-guardian', 'guardian',
   'c2300000-0000-0000-0000-000000000010', 'Tuteur', 'Classes', 'active'),
  ('c2300000-0000-0000-0000-000000000002', 'classes-student', 'student',
   'c2300000-0000-0000-0000-000000000010', 'Eleve', 'Classes', 'active')
on conflict (id) do nothing;

update public.households
set primary_guardian_id = 'c2300000-0000-0000-0000-000000000001'
where id = 'c2300000-0000-0000-0000-000000000010';

insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('c2300000-0000-0000-0000-000000000002', 'minor', 'child')
on conflict (profile_id) do nothing;

select set_config('test.uid', 'c2300000-0000-0000-0000-000000000001', false);
select set_config(
  'test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"c2300000-0000-0000-0000-000000000010"}}',
  false
);
set role authenticated;

do $$
declare
  v_result jsonb;
begin
  v_result := public.definir_date_naissance_apprenant(
    'c2300000-0000-0000-0000-000000000002',
    (current_date - interval '10 years')::date
  );
  if v_result->>'cohorte' <> 'enfant_10_13' then
    raise exception 'CLASSES AGE : 10 ans mal derive (%)', v_result->>'cohorte';
  end if;
end $$;

reset role;

do $$
declare
  v_date date;
  v_cohorte text;
begin
  select date_naissance, cohorte
    into v_date, v_cohorte
  from public.student_profiles
  where profile_id = 'c2300000-0000-0000-0000-000000000002';
  if v_date <> (current_date - interval '10 years')::date then
    raise exception 'CLASSES AGE : date de naissance non conservee';
  end if;
  if v_cohorte <> 'enfant_10_13' then
    raise exception 'CLASSES AGE : cohorte persistante incorrecte (%)', v_cohorte;
  end if;
end $$;

-- L'ancienne signature ne peut pas forcer une cohorte adulte pour un mineur.
set role authenticated;
select public.enregistrer_profil_apprentissage(
  'c2300000-0000-0000-0000-000000000002',
  'francais',
  'adulte_18_plus',
  'debut_lettres',
  'apprendre_a_lire',
  'Europe/Paris'
);
reset role;

do $$
begin
  if not exists (
    select 1 from public.student_profiles
    where profile_id = 'c2300000-0000-0000-0000-000000000002'
      and cohorte = 'enfant_10_13'
      and diagnostic_statut = 'non_requis'
      and placement_basis = 'debutant_declare'
  ) then
    raise exception 'CLASSES PLACEMENT : le debutant n''est pas trace sans faux diagnostic';
  end if;
end $$;

-- Un moins de six ans reste hors dispatch standard : aucune coercition en 6-9.
set role authenticated;
select public.definir_date_naissance_apprenant(
  'c2300000-0000-0000-0000-000000000002',
  (current_date - interval '5 years')::date
);
reset role;

do $$
begin
  if exists (
    select 1 from public.student_profiles
    where profile_id = 'c2300000-0000-0000-0000-000000000002'
      and cohorte is not null
  ) then
    raise exception 'CLASSES AGE : moins de 6 ans force dans une cohorte';
  end if;
end $$;

do $$
declare
  v_groupe uuid;
begin
  insert into public.groupes
    (teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
     timezone_iana, etat)
  values
    (null, 'enfant', 5, 'Classes draft test', 1, 18, 'Europe/Paris', 'brouillon')
  returning id into v_groupe;

  begin
    update public.groupes set etat = 'active' where id = v_groupe;
    raise exception 'CLASSES GROUPE : publication sans titulaire acceptee';
  exception when check_violation then
    null;
  end;

  if not exists (
    select 1 from public.groupes
    where id = v_groupe and etat = 'brouillon' and teacher_id is null
  ) then
    raise exception 'CLASSES GROUPE : draft sans titulaire absent';
  end if;
end $$;
