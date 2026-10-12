-- B-11 : signalement borné au groupe/seance du professeur et transmission sûre.
-- Base PostgreSQL jetable après rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('b1100000-0000-0000-0000-000000000001', 'b11-admin@example.test'),
  ('b1100000-0000-0000-0000-000000000002', 'b11-teacher-a@example.test'),
  ('b1100000-0000-0000-0000-000000000003', 'b11-teacher-b@example.test'),
  ('b1100000-0000-0000-0000-000000000004', 'b11-guardian@example.test'),
  ('b1100000-0000-0000-0000-000000000005', 'b11-student@example.test'),
  ('b1100000-0000-0000-0000-000000000006', 'b11-teacher-disabled@example.test');

insert into public.households (id, timezone)
values ('b11fffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('b1100000-0000-0000-0000-000000000001', 'B11ADMIN000001', 'admin',
   'b11fffff-0000-0000-0000-000000000001', 'Fixture', 'Admin', 'active', 'male'),
  ('b1100000-0000-0000-0000-000000000002', 'B11TEACHER0001', 'teacher',
   'b11fffff-0000-0000-0000-000000000001', 'Teacher', 'One', 'provisional_active', 'male'),
  ('b1100000-0000-0000-0000-000000000003', 'B11TEACHER0002', 'teacher',
   'b11fffff-0000-0000-0000-000000000001', 'Teacher', 'Two', 'provisional_active', 'female'),
  ('b1100000-0000-0000-0000-000000000004', 'B11GUARDIAN001', 'guardian',
   'b11fffff-0000-0000-0000-000000000001', 'Fixture', 'Guardian', 'active', 'female'),
  ('b1100000-0000-0000-0000-000000000005', 'B11STUDENT0001', 'student',
   'b11fffff-0000-0000-0000-000000000001', 'Fixture', 'Student', 'active', 'male'),
  ('b1100000-0000-0000-0000-000000000006', 'B11TEACHER0003', 'teacher',
   'b11fffff-0000-0000-0000-000000000001', 'Teacher', 'Disabled', 'disabled', 'male');

insert into public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values
  ('b1100000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris'),
  ('b1100000-0000-0000-0000-000000000003', array['francais'], 10, 'approved', 'Europe/Paris');

insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
values
  ('b1100000-0000-0000-0000-000000000002', 1, 10, 'Europe/Paris'),
  ('b1100000-0000-0000-0000-000000000003', 2, 11, 'Europe/Paris');

update public.households
   set primary_guardian_id = 'b1100000-0000-0000-0000-000000000004'
 where id = 'b11fffff-0000-0000-0000-000000000001';

insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('b1100000-0000-0000-0000-000000000005', 'minor', 'child');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('b11fffff-0000-0000-0000-000000000002',
   'b1100000-0000-0000-0000-000000000002', 'enfant', 5, 'B11 groupe A', 1, 10),
  ('b11fffff-0000-0000-0000-000000000003',
   'b1100000-0000-0000-0000-000000000003', 'enfant', 5, 'B11 groupe B', 2, 11);

insert into public.groupe_membres (groupe_id, student_id)
values ('b11fffff-0000-0000-0000-000000000002',
        'b1100000-0000-0000-0000-000000000005');

insert into public.sessions (id, teacher_id, started_at, ended_at)
values ('b11fffff-0000-0000-0000-000000000004',
        'b1100000-0000-0000-0000-000000000002',
        TIMESTAMPTZ '2030-01-02 03:00:00+00',
        TIMESTAMPTZ '2030-01-02 04:00:00+00');

insert into public.session_participants (session_id, profile_id, role)
values
  ('b11fffff-0000-0000-0000-000000000004',
   'b1100000-0000-0000-0000-000000000002', 'teacher'),
  ('b11fffff-0000-0000-0000-000000000004',
   'b1100000-0000-0000-0000-000000000005', 'student');

set local role authenticated;
select set_config('test.uid', 'b1100000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"b11fffff-0000-0000-0000-000000000001"}}',
  true);

do $b11_submit$
declare
  v_private_id uuid;
  v_family_id uuid;
  v_count integer;
begin
  if pg_catalog.has_table_privilege('authenticated', 'public.student_concern', 'INSERT')
     or pg_catalog.has_table_privilege('authenticated', 'public.student_concern', 'UPDATE') then
    raise exception 'B-11: clients must not bypass the bounded signalement RPCs';
  end if;

  v_private_id := (public.deposer_student_concern(
    'pedagogique', 'b11fffff-0000-0000-0000-000000000002',
    'b11fffff-0000-0000-0000-000000000004', 'B11STUDENT0001',
    'Note interne fixture', null
  ) ->> 'id')::uuid;

  v_family_id := (public.deposer_student_concern(
    'presence', 'b11fffff-0000-0000-0000-000000000002',
    null, 'B11STUDENT0001', 'Note interne distincte',
    'Message écrit pour le tuteur'
  ) ->> 'id')::uuid;

  select count(*) into v_count from public.mes_student_concerns(
    'b11fffff-0000-0000-0000-000000000002'
  );
  if v_count <> 2 then
    raise exception 'B-11: teacher must read only concerns they deposited';
  end if;

  perform set_config('test.uid', 'b1100000-0000-0000-0000-000000000003', true);

  perform set_config('test.jwt',
    '{"app_metadata":{"role":"teacher","household_id":"b11fffff-0000-0000-0000-000000000001"}}',
    true);
  begin
    perform public.deposer_student_concern(
      'autre', 'b11fffff-0000-0000-0000-000000000002',
      null, 'B11STUDENT0001', 'Tentative inter-groupe', null
    );
    raise exception 'B-11: a different teacher deposited into another group';
  exception when raise_exception then
    if sqlerrm <> 'eleve ou groupe introuvable dans votre classe' then raise; end if;
  end;

  perform set_config('test.uid', 'b1100000-0000-0000-0000-000000000003', true);

  perform set_config('test.jwt',
    '{"app_metadata":{"role":"teacher","household_id":"b11fffff-0000-0000-0000-000000000001"}}',
    true);
  select count(*) into v_count from public.mes_student_concerns(null);
  if v_count <> 0 then
    raise exception 'B-11: a teacher must not read another teacher concerns';
  end if;

  perform set_config('test.uid', 'b1100000-0000-0000-0000-000000000006', true);

  perform set_config('test.jwt',
    '{"app_metadata":{"role":"teacher","household_id":"b11fffff-0000-0000-0000-000000000001"}}',
    true);
  select count(*) into v_count from public.student_concern;
  if v_count <> 0 then
    raise exception 'B-11: a disabled teacher must not read internal concerns';
  end if;
  begin
    perform 1 from public.mes_student_concerns(null);
    raise exception 'B-11: a disabled teacher read concerns through the RPC';
  exception when raise_exception then
    if sqlerrm <> 'lecture de signalements reservee a un enseignant actif' then raise; end if;
  end;

  if v_private_id = v_family_id then
    raise exception 'B-11: signalement identifiers must be distinct';
  end if;
end
$b11_submit$;

select set_config('test.uid', 'b1100000-0000-0000-0000-000000000001', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"admin","household_id":"b11fffff-0000-0000-0000-000000000001"}}',
  true);

do $b11_transmit$
declare
  v_family_id uuid;
  v_status text;
begin
  select id into v_family_id
    from public.student_concern
   where internal_details = 'Note interne distincte';

  begin
    perform public.transmettre_student_concern(v_family_id, 'eleve_adulte');
    raise exception 'B-11: target mismatching a minor was accepted';
  exception when raise_exception then
    if sqlerrm <> 'cible incompatible avec le profil de l''eleve' then raise; end if;
  end;

  perform public.transmettre_student_concern(v_family_id, 'tuteur_du_mineur');

  select statut::text into v_status
    from public.student_concern where id = v_family_id;
  if v_status <> 'transmis' then
    raise exception 'B-11: admin transmission did not persist';
  end if;

  begin
    perform public.transmettre_student_concern(
      (select id from public.student_concern
        where internal_details = 'Note interne fixture'),
      'tuteur_du_mineur'
    );
    raise exception 'B-11: internal-only concern was transmitted';
  exception when raise_exception then
    if sqlerrm <> 'aucun message famille a transmettre' then raise; end if;
  end;
end
$b11_transmit$;

select set_config('test.uid', 'b1100000-0000-0000-0000-000000000004', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"b11fffff-0000-0000-0000-000000000001"}}',
  true);

do $b11_family_isolation$
declare
  v_count integer;
begin
  select count(*) into v_count from public.student_concern;
  if v_count <> 0 then
    raise exception 'B-11: a family account must not read internal concerns';
  end if;
end
$b11_family_isolation$;

reset role;
rollback;
