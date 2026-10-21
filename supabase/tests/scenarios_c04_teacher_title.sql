-- C-04 : le titre public vient toujours du genre porté par le profil enseignant.
-- PostgreSQL jetable après rejeu complet des migrations; aucun appel à PROD/STAGING.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c0400000-0000-0000-0000-000000000001', 'c04-admin@example.test'),
  ('c0400000-0000-0000-0000-000000000002', 'c04-teacher-female@example.test'),
  ('c0400000-0000-0000-0000-000000000003', 'c04-teacher-male@example.test'),
  ('c0400000-0000-0000-0000-000000000004', 'c04-teacher-unknown@example.test'),
  ('c0400000-0000-0000-0000-000000000005', 'c04-student@example.test'),
  ('c0400000-0000-0000-0000-000000000006', 'c04-admin-disabled@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('c0400000-0000-0000-0000-000000000001', 'C04ADMIN0000001', 'admin',
   'Fixture', 'Admin', 'active', 'female'),
  ('c0400000-0000-0000-0000-000000000002', 'C04TEACHFEMALE02', 'teacher',
   'Amira', 'Female', 'provisional_active', 'female'),
  ('c0400000-0000-0000-0000-000000000003', 'C04TEACHMALE0003', 'teacher',
   'Youssef', 'Male', 'provisional_active', 'male'),
  ('c0400000-0000-0000-0000-000000000004', 'C04TEACHUNKNOWN04', 'teacher',
   'Sam', 'Unknown', 'provisional_active', NULL),
  ('c0400000-0000-0000-0000-000000000006', 'C04ADMINDIS0006', 'admin',
   'Fixture', 'Disabled', 'disabled', 'female');

-- Un eleve a toujours un foyer (profiles_household_required).
INSERT INTO public.households (id, timezone)
VALUES ('c0400000-0000-0000-0000-000000000105', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('c0400000-0000-0000-0000-000000000005', 'C04STUDENT00005', 'student',
   'c0400000-0000-0000-0000-000000000105', 'Fixture', 'Student', 'active', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
  ('c0400000-0000-0000-0000-000000000002', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris'),
  ('c0400000-0000-0000-0000-000000000003', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris'),
  ('c0400000-0000-0000-0000-000000000004', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris');

INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
VALUES
  ('c0400000-0000-0000-0000-000000000002', 1, 10, 'Europe/Paris'),
  ('c0400000-0000-0000-0000-000000000003', 1, 10, 'Europe/Paris'),
  ('c0400000-0000-0000-0000-000000000004', 1, 10, 'Europe/Paris');

INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, genre_public, seuil_max, libelle,
   weekday, hour_local, timezone_iana, langue_code)
VALUES
  ('c04fffff-0000-0000-0000-000000000001', NULL, 'en_attente_enseignant',
   'enfant', 'femmes', 5, 'C04 femmes', 1, 10, 'Europe/Paris', 'francais'),
  ('c04fffff-0000-0000-0000-000000000002', NULL, 'en_attente_enseignant',
   'enfant', 'hommes', 5, 'C04 hommes', 1, 10, 'Europe/Paris', 'francais');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'c0400000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $c04$
DECLARE
  v_femmes int;
  v_hommes int;
  v_invalid int;
BEGIN
  SELECT count(*) FILTER (WHERE teacher_id = 'c0400000-0000-0000-0000-000000000002'
                           AND titre_public = 'sayyida'),
         count(*) FILTER (WHERE teacher_id = 'c0400000-0000-0000-0000-000000000003'
                           AND titre_public = 'sayyida'),
         count(*) FILTER (WHERE teacher_id = 'c0400000-0000-0000-0000-000000000004')
    INTO v_femmes, v_hommes, v_invalid
  FROM public.enseignants_pour_classe('c04fffff-0000-0000-0000-000000000001');

  IF v_femmes <> 1 OR v_hommes <> 0 OR v_invalid <> 0 THEN
    RAISE EXCEPTION 'C-04 femmes: titres ou compatibilité genre incorrects (female %, male %, inconnu %)',
      v_femmes, v_hommes, v_invalid;
  END IF;

  SELECT count(*) FILTER (WHERE teacher_id = 'c0400000-0000-0000-0000-000000000003'
                           AND titre_public = 'sayid'),
         count(*) FILTER (WHERE teacher_id = 'c0400000-0000-0000-0000-000000000002'
                           AND titre_public = 'sayid'),
         count(*) FILTER (WHERE teacher_id = 'c0400000-0000-0000-0000-000000000004')
    INTO v_hommes, v_femmes, v_invalid
  FROM public.enseignants_pour_classe('c04fffff-0000-0000-0000-000000000002');

  IF v_hommes <> 1 OR v_femmes <> 0 OR v_invalid <> 0 THEN
    RAISE EXCEPTION 'C-04 hommes: titres ou compatibilité genre incorrects (male %, female %, inconnu %)',
      v_hommes, v_femmes, v_invalid;
  END IF;
END
$c04$;

RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'c0400000-0000-0000-0000-000000000005', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
DO $c04_student_denied$
BEGIN
  BEGIN
    PERFORM 1 FROM public.enseignants_pour_classe(
      'c04fffff-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION USING ERRCODE = 'ZX001', MESSAGE = 'C-04: student unexpectedly queried teacher candidates';
  EXCEPTION WHEN raise_exception THEN
    IF SQLSTATE <> 'P0001' THEN RAISE; END IF;
  END;
END
$c04_student_denied$;

SELECT set_config('test.uid', 'c0400000-0000-0000-0000-000000000006', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $c04_disabled_admin_denied$
BEGIN
  BEGIN
    PERFORM 1 FROM public.enseignants_pour_classe(
      'c04fffff-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION USING ERRCODE = 'ZX001', MESSAGE = 'C-04: disabled admin unexpectedly queried teacher candidates';
  EXCEPTION WHEN raise_exception THEN
    IF SQLSTATE <> 'P0001' THEN RAISE; END IF;
  END;
END
$c04_disabled_admin_denied$;

RESET ROLE;
DO $c04_anon_acl$
BEGIN
  IF pg_catalog.has_function_privilege(
       'anon', 'public.enseignants_pour_classe(uuid)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C-04: anon unexpectedly has candidate RPC EXECUTE';
  END IF;
END
$c04_anon_acl$;

SET LOCAL ROLE anon;
DO $c04_anon_denied$
BEGIN
  BEGIN
    PERFORM 1 FROM public.enseignants_pour_classe(
      'c04fffff-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'C-04: anon unexpectedly queried teacher candidates';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$c04_anon_denied$;
RESET ROLE;
ROLLBACK;
