-- SEC-GARDE-5 point a (11/11/2026), migration
-- 20261123400000_sec_garde_5_compte_desactive.sql. Rouge sans la migration,
-- vert avec. Pour chaque table (profiles, households, student_profiles,
-- devices, teacher_student_assignments, groupes) : un tuteur 'disabled' ne
-- lit plus son foyer, meme avec un ancien jeton qui porte encore son role ;
-- un tuteur actif et un tuteur pending_kyc lisent comme avant ; le compte
-- desactive lit toujours sa propre ligne de profil. Puis le hook de jeton :
-- sans role ni foyer et avec account_status pour 'disabled', inchange pour
-- pending_kyc. Fixtures sans declencheurs ; tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SEC-GARDE-5 a ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated',
                       'app_metadata', jsonb_strip_nulls(jsonb_build_object(
                         'role', p_role, 'household_id', p_foyer)))::text, true);
END $$;

-- Ce qu'un tuteur lit de son foyer, table par table : la ligne
-- (profils autres que soi, foyer, fiche eleve, appareil, affectation, classe).
CREATE FUNCTION pg_temp.lu(p_foyer uuid, p_eleve uuid, p_groupe uuid) RETURNS int[]
LANGUAGE sql AS $$
  SELECT ARRAY[
    (SELECT count(*)::int FROM public.profiles WHERE household_id = p_foyer AND id <> auth.uid()),
    (SELECT count(*)::int FROM public.households WHERE id = p_foyer),
    (SELECT count(*)::int FROM public.student_profiles WHERE profile_id = p_eleve),
    (SELECT count(*)::int FROM public.devices WHERE profile_id = p_eleve),
    (SELECT count(*)::int FROM public.teacher_student_assignments WHERE student_id = p_eleve),
    (SELECT count(*)::int FROM public.groupes WHERE id = p_groupe)];
$$;
GRANT EXECUTE ON FUNCTION pg_temp.lu(uuid, uuid, uuid) TO authenticated;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('5e500000-0000-0000-0000-000000000001'), ('5e500000-0000-0000-0000-000000000002'),
  ('5e500000-0000-0000-0000-000000000003'), ('5e500000-0000-0000-0000-000000000011'),
  ('5e500000-0000-0000-0000-000000000012'), ('5e500000-0000-0000-0000-000000000013'),
  ('5e500000-0000-0000-0000-000000000021');
INSERT INTO public.households (id, timezone, primary_guardian_id) VALUES
  ('5e500000-0000-0000-0000-0000000000f1', 'Europe/Paris', '5e500000-0000-0000-0000-000000000001'),
  ('5e500000-0000-0000-0000-0000000000f2', 'Europe/Paris', '5e500000-0000-0000-0000-000000000002'),
  ('5e500000-0000-0000-0000-0000000000f3', 'Europe/Paris', '5e500000-0000-0000-0000-000000000003');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('5e500000-0000-0000-0000-000000000001', 'SG5-TUT-OFF', 'guardian', '5e500000-0000-0000-0000-0000000000f1', 'Tut', 'Off', 'disabled',    'male'),
  ('5e500000-0000-0000-0000-000000000002', 'SG5-TUT-ON',  'guardian', '5e500000-0000-0000-0000-0000000000f2', 'Tut', 'On',  'active',      'male'),
  ('5e500000-0000-0000-0000-000000000003', 'SG5-TUT-KYC', 'guardian', '5e500000-0000-0000-0000-0000000000f3', 'Tut', 'Kyc', 'pending_kyc', 'female'),
  ('5e500000-0000-0000-0000-000000000011', 'SG5-ELV-1',   'student',  '5e500000-0000-0000-0000-0000000000f1', 'Elv', 'Un',  'active',      'male'),
  ('5e500000-0000-0000-0000-000000000012', 'SG5-ELV-2',   'student',  '5e500000-0000-0000-0000-0000000000f2', 'Elv', 'Deux','active',      'male'),
  ('5e500000-0000-0000-0000-000000000013', 'SG5-ELV-3',   'student',  '5e500000-0000-0000-0000-0000000000f3', 'Elv', 'Trois','active',     'female'),
  ('5e500000-0000-0000-0000-000000000021', 'SG5-ENS',     'teacher',  NULL, 'Ens', 'Gnt', 'active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type) VALUES
  ('5e500000-0000-0000-0000-000000000011', 'minor'),
  ('5e500000-0000-0000-0000-000000000012', 'minor'),
  ('5e500000-0000-0000-0000-000000000013', 'minor');
INSERT INTO public.devices (profile_id, device_fingerprint, platform) VALUES
  ('5e500000-0000-0000-0000-000000000011', 'sg5-a', 'web'),
  ('5e500000-0000-0000-0000-000000000012', 'sg5-b', 'web'),
  ('5e500000-0000-0000-0000-000000000013', 'sg5-c', 'web');
INSERT INTO public.teacher_student_assignments (teacher_id, student_id, weekday, hour_local) VALUES
  ('5e500000-0000-0000-0000-000000000021', '5e500000-0000-0000-0000-000000000011', 1, 10),
  ('5e500000-0000-0000-0000-000000000021', '5e500000-0000-0000-0000-000000000012', 2, 10),
  ('5e500000-0000-0000-0000-000000000021', '5e500000-0000-0000-0000-000000000013', 3, 10);
INSERT INTO public.groupes (id, type_public, seuil_max, libelle, weekday, hour_local, teacher_id) VALUES
  ('5e500000-0000-0000-0000-0000000000a1', 'enfant', 6, 'Classe un',    1, 10, '5e500000-0000-0000-0000-000000000021'),
  ('5e500000-0000-0000-0000-0000000000a2', 'enfant', 6, 'Classe deux',  2, 10, '5e500000-0000-0000-0000-000000000021'),
  ('5e500000-0000-0000-0000-0000000000a3', 'enfant', 6, 'Classe trois', 3, 10, '5e500000-0000-0000-0000-000000000021');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('5e500000-0000-0000-0000-0000000000a1', '5e500000-0000-0000-0000-000000000011'),
  ('5e500000-0000-0000-0000-0000000000a2', '5e500000-0000-0000-0000-000000000012'),
  ('5e500000-0000-0000-0000-0000000000a3', '5e500000-0000-0000-0000-000000000013');
SET LOCAL session_replication_role = origin;

-- ------------------------------------------------------------------
-- 1. Tuteur desactive, ancien jeton qui porte encore role et foyer
-- ------------------------------------------------------------------
SELECT pg_temp.etre('5e500000-0000-0000-0000-000000000001', 'guardian', '5e500000-0000-0000-0000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f1', '5e500000-0000-0000-0000-000000000011', '5e500000-0000-0000-0000-0000000000a1'))[1] = 0,
  '1 : tuteur desactive, refuse : profiles (autres que soi)');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f1', '5e500000-0000-0000-0000-000000000011', '5e500000-0000-0000-0000-0000000000a1'))[2] = 0,
  '1 : tuteur desactive, refuse : households');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f1', '5e500000-0000-0000-0000-000000000011', '5e500000-0000-0000-0000-0000000000a1'))[3] = 0,
  '1 : tuteur desactive, refuse : student_profiles');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f1', '5e500000-0000-0000-0000-000000000011', '5e500000-0000-0000-0000-0000000000a1'))[4] = 0,
  '1 : tuteur desactive, refuse : devices');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f1', '5e500000-0000-0000-0000-000000000011', '5e500000-0000-0000-0000-0000000000a1'))[5] = 0,
  '1 : tuteur desactive, refuse : teacher_student_assignments');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f1', '5e500000-0000-0000-0000-000000000011', '5e500000-0000-0000-0000-0000000000a1'))[6] = 0,
  '1 : tuteur desactive, refuse : groupes');
SELECT pg_temp.vrai((SELECT count(*) FROM public.profiles
                      WHERE id = '5e500000-0000-0000-0000-000000000001') = 1,
  '1 : tuteur desactive : lit toujours sa propre ligne de profil');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Temoins : tuteur actif et tuteur pending_kyc lisent comme avant
-- ------------------------------------------------------------------
SELECT pg_temp.etre('5e500000-0000-0000-0000-000000000002', 'guardian', '5e500000-0000-0000-0000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f2', '5e500000-0000-0000-0000-000000000012', '5e500000-0000-0000-0000-0000000000a2'))[1] = 1,
  '2 : tuteur actif, lit : profiles (autres que soi)');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f2', '5e500000-0000-0000-0000-000000000012', '5e500000-0000-0000-0000-0000000000a2'))[2] = 1,
  '2 : tuteur actif, lit : households');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f2', '5e500000-0000-0000-0000-000000000012', '5e500000-0000-0000-0000-0000000000a2'))[3] = 1,
  '2 : tuteur actif, lit : student_profiles');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f2', '5e500000-0000-0000-0000-000000000012', '5e500000-0000-0000-0000-0000000000a2'))[4] = 1,
  '2 : tuteur actif, lit : devices');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f2', '5e500000-0000-0000-0000-000000000012', '5e500000-0000-0000-0000-0000000000a2'))[5] = 1,
  '2 : tuteur actif, lit : teacher_student_assignments');
SELECT pg_temp.vrai(
  (pg_temp.lu('5e500000-0000-0000-0000-0000000000f2', '5e500000-0000-0000-0000-000000000012', '5e500000-0000-0000-0000-0000000000a2'))[6] = 1,
  '2 : tuteur actif, lit : groupes');
RESET ROLE;

-- Le pending_kyc lit exactement ce qu'il lisait sans les politiques
-- restrictives : on compare a la meme lecture sans elles.
SELECT pg_temp.etre('5e500000-0000-0000-0000-000000000003', 'guardian', '5e500000-0000-0000-0000-0000000000f3');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE kyc_avec ON COMMIT DROP AS SELECT pg_temp.lu('5e500000-0000-0000-0000-0000000000f3',
  '5e500000-0000-0000-0000-000000000013', '5e500000-0000-0000-0000-0000000000a3') AS v;
RESET ROLE;
ALTER POLICY profiles_compte_non_desactive ON public.profiles USING (true);
ALTER POLICY households_compte_non_desactive ON public.households USING (true);
ALTER POLICY student_profiles_compte_non_desactive ON public.student_profiles USING (true);
ALTER POLICY devices_compte_non_desactive ON public.devices USING (true);
ALTER POLICY assignments_compte_non_desactive ON public.teacher_student_assignments USING (true);
ALTER POLICY groupes_compte_non_desactive ON public.groupes USING (true);
SELECT pg_temp.etre('5e500000-0000-0000-0000-000000000003', 'guardian', '5e500000-0000-0000-0000-0000000000f3');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT v FROM kyc_avec) = pg_temp.lu('5e500000-0000-0000-0000-0000000000f3',
     '5e500000-0000-0000-0000-000000000013', '5e500000-0000-0000-0000-0000000000a3'),
  '2 : tuteur pending_kyc : les politiques restrictives ne lui retirent rien');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Le hook de jeton
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT public.custom_access_token_hook(jsonb_build_object(
     'user_id', '5e500000-0000-0000-0000-000000000001', 'claims', '{}'::jsonb))
     -> 'claims' -> 'app_metadata')
  = jsonb_build_object('role', null, 'household_id', null, 'account_status', 'disabled',
                       'authorization_version',
                       (SELECT authorization_version FROM public.profiles
                         WHERE id = '5e500000-0000-0000-0000-000000000001')),
  '3 : hook, compte desactive : ni role ni foyer, account_status = disabled');
SELECT pg_temp.vrai(
  (SELECT public.custom_access_token_hook(jsonb_build_object(
     'user_id', '5e500000-0000-0000-0000-000000000003', 'claims', '{}'::jsonb))
     -> 'claims' -> 'app_metadata') ->> 'role' = 'guardian'
  AND (SELECT public.custom_access_token_hook(jsonb_build_object(
     'user_id', '5e500000-0000-0000-0000-000000000003', 'claims', '{}'::jsonb))
     -> 'claims' -> 'app_metadata') ->> 'household_id' = '5e500000-0000-0000-0000-0000000000f3'
  AND NOT ((SELECT public.custom_access_token_hook(jsonb_build_object(
     'user_id', '5e500000-0000-0000-0000-000000000003', 'claims', '{}'::jsonb))
     -> 'claims' -> 'app_metadata') ? 'account_status'),
  '3 : hook, compte pending_kyc : role et foyer comme avant, pas d''account_status');
SELECT pg_temp.vrai(
  public.custom_access_token_hook(jsonb_build_object(
    'user_id', '5e500000-0000-0000-0000-0000000000ff', 'claims', '{}'::jsonb)) IS NOT NULL,
  '3 : hook, utilisateur sans profil : jamais null');

-- ------------------------------------------------------------------
-- 4. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'app_private.compte_non_desactive()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'app_private.compte_non_desactive()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.custom_access_token_hook(jsonb)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.custom_access_token_hook(jsonb)', 'EXECUTE'),
  '4 : droits : aide a authenticated seul ; hook ni a authenticated ni a anon');

\o
ROLLBACK;
