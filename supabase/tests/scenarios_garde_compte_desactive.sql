-- GARDE-COMPTE-DESACTIVE (08/11/2026), migration 20261121500000_garde_compte_desactive.sql.
-- Rouge sans la migration, vert avec. Trois preuves demandees par le pilote :
--   1. un admin desactive ne lit plus les dossiers des autres (disponibilites,
--      priere, intentions, recherche par matricule) ;
--   2. un controleur desactive non plus ;
--   3. l'ecran du compte suspendu marche encore : le compte desactive lit sa
--      propre ligne de profil ; et un admin actif lit toujours (temoin).
-- Fixtures sans declencheurs (session_replication_role = replica) ; tout est
-- annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'GARDE-COMPTE-DESACTIVE ROUGE : %', p_label;
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

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('9c000000-0000-0000-0000-000000000001'), ('9c000000-0000-0000-0000-000000000002'),
  ('9c000000-0000-0000-0000-000000000003'), ('9c000000-0000-0000-0000-000000000004'),
  ('9c000000-0000-0000-0000-000000000005'), ('9c000000-0000-0000-0000-000000000006');
INSERT INTO public.households (id, timezone) VALUES
  ('9c000000-0000-0000-0000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('9c000000-0000-0000-0000-000000000001', 'GCD-ADM-OFF', 'admin',      NULL, 'Adm', 'Off', 'disabled', 'male'),
  ('9c000000-0000-0000-0000-000000000002', 'GCD-ADM-ON',  'admin',      NULL, 'Adm', 'On',  'active',   'male'),
  ('9c000000-0000-0000-0000-000000000003', 'GCD-CTL-OFF', 'controller', NULL, 'Ctl', 'Off', 'disabled', 'male'),
  ('9c000000-0000-0000-0000-000000000004', 'GCD-ENS',     'teacher',    NULL, 'Ens', 'Gnt', 'active',   'female'),
  ('9c000000-0000-0000-0000-000000000005', 'GCD-TUT-OFF', 'guardian',   '9c000000-0000-0000-0000-0000000000f1', 'Tut', 'Off', 'disabled', 'male'),
  ('9c000000-0000-0000-0000-000000000006', 'GCD-ELV',     'student',    '9c000000-0000-0000-0000-0000000000f1', 'Elv', 'Un',  'active',   'male');
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local) VALUES
  ('9c000000-0000-0000-0000-000000000004', 1, 10);
INSERT INTO public.prayer_settings (teacher_id, latitude, longitude) VALUES
  ('9c000000-0000-0000-0000-000000000004', 48.85, 2.35);
INSERT INTO public.intentions_horaire (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
  VALUES ('9c000000-0000-0000-0000-000000000006', gen_random_uuid(), 'Europe/Paris', 18, ARRAY[1]::smallint[],
          '9c000000-0000-0000-0000-000000000005');
SET LOCAL session_replication_role = origin;

-- ------------------------------------------------------------------
-- 1. Admin desactive
-- ------------------------------------------------------------------
SELECT pg_temp.etre('9c000000-0000-0000-0000-000000000001', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT public.app_account_valid(), '1 : le compte de l''admin est bien desactive');
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings
                      WHERE teacher_id = '9c000000-0000-0000-0000-000000000004') = 0,
  '1 : admin desactive : aucun reglage de priere (position du domicile) d''un enseignant');
SELECT pg_temp.vrai((SELECT count(*) FROM public.weekly_availability
                      WHERE profile_id = '9c000000-0000-0000-0000-000000000004') = 0,
  '1 : admin desactive : aucune disponibilite d''un enseignant');
SELECT pg_temp.vrai((SELECT count(*) FROM public.intentions_horaire
                      WHERE eleve_id = '9c000000-0000-0000-0000-000000000006') = 0,
  '1 : admin desactive : aucune intention horaire d''un eleve');
SELECT pg_temp.vrai(NOT public.partie_concernee('9c000000-0000-0000-0000-000000000004'),
  '1 : admin desactive : n''est plus partie au dossier d''un enseignant');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Controleur desactive
-- ------------------------------------------------------------------
SELECT pg_temp.etre('9c000000-0000-0000-0000-000000000003', 'controller', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings
                      WHERE teacher_id = '9c000000-0000-0000-0000-000000000004') = 0,
  '2 : controleur desactive : aucun reglage de priere');
SELECT pg_temp.vrai((SELECT count(*) FROM public.weekly_availability
                      WHERE profile_id = '9c000000-0000-0000-0000-000000000004') = 0,
  '2 : controleur desactive : aucune disponibilite');
SELECT pg_temp.vrai((SELECT count(*) FROM public.intentions_horaire
                      WHERE eleve_id = '9c000000-0000-0000-0000-000000000006') = 0,
  '2 : controleur desactive : aucune intention horaire');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Temoin et ecran du compte suspendu
-- ------------------------------------------------------------------
SELECT pg_temp.etre('9c000000-0000-0000-0000-000000000002', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.prayer_settings
                      WHERE teacher_id = '9c000000-0000-0000-0000-000000000004') = 1
                AND (SELECT count(*) FROM public.weekly_availability
                      WHERE profile_id = '9c000000-0000-0000-0000-000000000004') = 1
                AND (SELECT count(*) FROM public.intentions_horaire
                      WHERE eleve_id = '9c000000-0000-0000-0000-000000000006') = 1,
  '3 : temoin : un admin actif lit toujours priere, disponibilites et intentions');
RESET ROLE;

SELECT pg_temp.etre('9c000000-0000-0000-0000-000000000001', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.profiles
                      WHERE id = '9c000000-0000-0000-0000-000000000001') = 1,
  '3 : ecran du compte suspendu : l''admin desactive lit sa propre ligne de profil');
RESET ROLE;

SELECT pg_temp.etre('9c000000-0000-0000-0000-000000000005', 'guardian', '9c000000-0000-0000-0000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.profiles
                      WHERE id = '9c000000-0000-0000-0000-000000000005') = 1,
  '3 : ecran du compte suspendu : le tuteur desactive lit sa propre ligne de profil');
SELECT pg_temp.vrai(public.partie_concernee('9c000000-0000-0000-0000-000000000005'),
  '3 : la lecture de soi par partie_concernee est inchangee');
RESET ROLE;

-- Droits inchanges.
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.partie_concernee(uuid)', 'EXECUTE')
                AND has_function_privilege('authenticated', 'public.partie_concernee(uuid)', 'EXECUTE'),
  'droits : authenticated seul, comme avant');

\o
ROLLBACK;
