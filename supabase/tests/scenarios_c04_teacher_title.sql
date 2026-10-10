-- C-04 : le titre public vient toujours du genre porté par le profil enseignant.
-- PostgreSQL jetable après rejeu complet des migrations; aucun appel à PROD/STAGING.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c0400000-0000-0000-0000-000000000001', 'c04-admin@example.test'),
  ('c0400000-0000-0000-0000-000000000002', 'c04-teacher-female@example.test'),
  ('c0400000-0000-0000-0000-000000000003', 'c04-teacher-male@example.test'),
  ('c0400000-0000-0000-0000-000000000004', 'c04-teacher-unknown@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('c0400000-0000-0000-0000-000000000001', 'C04ADMIN0000001', 'admin',
   'Fixture', 'Admin', 'active', 'female'),
  ('c0400000-0000-0000-0000-000000000002', 'C04TEACHFEMALE02', 'teacher',
   'Amira', 'Female', 'active', 'female'),
  ('c0400000-0000-0000-0000-000000000003', 'C04TEACHMALE0003', 'teacher',
   'Youssef', 'Male', 'active', 'male'),
  ('c0400000-0000-0000-0000-000000000004', 'C04TEACHUNKNOWN04', 'teacher',
   'Sam', 'Unknown', 'active', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
  ('c0400000-0000-0000-0000-000000000002', 'FR', ARRAY['ar'], 40, 'approved', 'Europe/Paris'),
  ('c0400000-0000-0000-0000-000000000003', 'FR', ARRAY['ar'], 40, 'approved', 'Europe/Paris'),
  ('c0400000-0000-0000-0000-000000000004', 'FR', ARRAY['ar'], 40, 'approved', 'Europe/Paris');

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
   'enfant', 'femmes', 5, 'C04 femmes', 1, 10, 'Europe/Paris', 'ar'),
  ('c04fffff-0000-0000-0000-000000000002', NULL, 'en_attente_enseignant',
   'enfant', 'hommes', 5, 'C04 hommes', 1, 10, 'Europe/Paris', 'ar');

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
ROLLBACK;
