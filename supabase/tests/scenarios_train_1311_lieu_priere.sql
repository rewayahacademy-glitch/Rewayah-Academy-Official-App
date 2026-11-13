-- TRAIN 13/11/2026 : HORLOGE-ET-LIEU (20261123943200) et PRIERE-2 (20261124500000) ensemble.
-- Chaque lot prouve sa moitie avec un double de l'autre : scenarios_horloge_lieu_c.sql note
-- les appels dans une fausse `private.priere_lieu_auto`, et scenarios_priere_zero_saisie.sql
-- saute son rattrapage des que la vraie table public.lieux existe. Ce scenario prouve la
-- jonction REELLE, sans double :
--   1. un enseignant enregistre sa ville : son lieu de priere est pose (source « auto ») ;
--   2. il change de ville : le lieu suit, une seule ligne ;
--   3. un tuteur enregistre la ville de son foyer : aucun lieu de priere ;
--   4. un lieu pose a la main par la direction n'est pas remplace par la ville ;
--   5. le rattrapage lit la vraie table public.lieux.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations. Fixtures sans
-- donnee personnelle ; tout est annule a la fin. Un echec leve 'TRAIN ROUGE : ...'.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d7000000-0000-4000-8000-000000000001', 'train-admin@example.test'),
  ('d7000000-0000-4000-8000-000000000002', 'train-enseignant-a@example.test'),
  ('d7000000-0000-4000-8000-000000000003', 'train-enseignant-b@example.test'),
  ('d7000000-0000-4000-8000-000000000004', 'train-tuteur@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('d7000000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
VALUES
  ('d7000000-0000-4000-8000-000000000001', 'TRNADMIN00000001', 'admin', 'Fixture', 'Direction', 'active', 'female', NULL),
  ('d7000000-0000-4000-8000-000000000002', 'TRNTEACH00000002', 'teacher', 'Fixture', 'EnseignantA', 'provisional_active', 'male', NULL),
  ('d7000000-0000-4000-8000-000000000003', 'TRNTEACH00000003', 'teacher', 'Fixture', 'EnseignantB', 'provisional_active', 'female', NULL),
  ('d7000000-0000-4000-8000-000000000004', 'TRNGUARD00000004', 'guardian', 'Fixture', 'Tuteur', 'active', 'male', 'd7000000-0000-4000-8000-0000000000f1');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES ('d7000000-0000-4000-8000-000000000002', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris'),
       ('d7000000-0000-4000-8000-000000000003', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris');

SELECT set_config('test.lyon', (SELECT id FROM public.villes_ref WHERE nom = 'Lyon' AND pays_code = 'FR' ORDER BY milliers DESC LIMIT 1)::text, true),
       set_config('test.marseille', (SELECT id FROM public.villes_ref WHERE nom = 'Marseille' AND pays_code = 'FR' ORDER BY milliers DESC LIMIT 1)::text, true);

CREATE FUNCTION pg_temp.en_tant(p_uid uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE sql AS $f$
  SELECT set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('request.jwt.claims', pg_catalog.json_build_object('app_metadata',
           pg_catalog.jsonb_build_object('role', p_role) || coalesce(pg_catalog.jsonb_build_object('household_id', p_foyer), '{}'::jsonb))::text, true);
$f$;
CREATE FUNCTION pg_temp.vrai(p_ok boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $f$
BEGIN
  IF p_ok IS NOT TRUE THEN RAISE EXCEPTION 'TRAIN ROUGE : %', p_label; END IF;
  RAISE NOTICE 'TRAIN OK %', p_label;
END $f$;
GRANT EXECUTE ON FUNCTION pg_temp.en_tant(uuid, text, uuid) TO authenticated, anon;

-- 0. Les deux moities sont la, sans double.
SELECT pg_temp.vrai(
  pg_catalog.to_regprocedure('private.priere_lieu_auto(uuid,text,numeric,numeric,text)') IS NOT NULL
  AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
        WHERE t.tgrelid = 'public.lieux'::pg_catalog.regclass AND t.tgname = 'lieux_priere_auto') = 1
  AND (SELECT p.prorettype = 'boolean'::pg_catalog.regtype FROM pg_catalog.pg_proc p
        WHERE p.oid = pg_catalog.to_regprocedure('private.priere_lieu_auto(uuid,text,numeric,numeric,text)')),
  'la vraie fonction de PRIERE-2 et un seul declencheur lieux_priere_auto existent ensemble');

-- 1. Un enseignant enregistre sa ville : son lieu de priere est pose.
SELECT pg_temp.en_tant('d7000000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_ma_ville(current_setting('test.lyon')::bigint);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT ps.place_label = 'Lyon' AND ps.lieu_source = 'auto' AND ps.actif
          AND ps.timezone_iana = 'Europe/Paris'
          AND ps.latitude = (SELECT pg_catalog.round(v.latitude, 3) FROM public.villes_ref v WHERE v.id = current_setting('test.lyon')::bigint)
          AND ps.longitude = (SELECT pg_catalog.round(v.longitude, 3) FROM public.villes_ref v WHERE v.id = current_setting('test.lyon')::bigint)
     FROM public.prayer_settings ps WHERE ps.teacher_id = 'd7000000-0000-4000-8000-000000000002'),
  'un enseignant enregistre sa ville : son lieu de priere est pose (auto, nom, centre-ville, fuseau)');

-- 2. Il change de ville : le lieu suit, une seule ligne.
SELECT pg_temp.en_tant('d7000000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_ma_ville(current_setting('test.marseille')::bigint);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) = 1 AND pg_catalog.bool_and(ps.place_label = 'Marseille' AND ps.lieu_source = 'auto')
     FROM public.prayer_settings ps WHERE ps.teacher_id = 'd7000000-0000-4000-8000-000000000002'),
  'il change de ville : le lieu de priere suit, une seule ligne');

-- 3. Un tuteur enregistre la ville de son foyer : aucun lieu de priere.
SELECT pg_temp.en_tant('d7000000-0000-4000-8000-000000000004', 'guardian', 'd7000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_ma_ville(current_setting('test.lyon')::bigint);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.prayer_settings) = 1
  AND EXISTS (SELECT 1 FROM public.lieux l WHERE l.foyer_id = 'd7000000-0000-4000-8000-0000000000f1' AND l.ville = 'Lyon'),
  'la ville d''un foyer s''enregistre et ne pose aucun lieu de priere');

-- 4. Un lieu pose a la main par la direction n'est pas remplace par la ville.
SELECT pg_temp.en_tant('d7000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT public.priere_lieu_definir('d7000000-0000-4000-8000-000000000003', 'Paris', 48.8566, 2.3522, 'Europe/Paris');
RESET ROLE;
SELECT pg_temp.en_tant('d7000000-0000-4000-8000-000000000003', 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.enregistrer_ma_ville(current_setting('test.lyon')::bigint);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT ps.place_label = 'Paris' AND ps.lieu_source = 'direction'
     FROM public.prayer_settings ps WHERE ps.teacher_id = 'd7000000-0000-4000-8000-000000000003')
  AND EXISTS (SELECT 1 FROM public.lieux l WHERE l.profil_id = 'd7000000-0000-4000-8000-000000000003' AND l.ville = 'Lyon'),
  'le lieu pose a la main par la direction reste ; la ville de l''enseignant s''enregistre quand meme');

-- 5. Le rattrapage lit la vraie table public.lieux.
DELETE FROM public.prayer_settings WHERE teacher_id = 'd7000000-0000-4000-8000-000000000002';
SELECT pg_temp.vrai(private.priere_rattraper_villes() = 1,
  'rattrapage sur la vraie table des villes : un lieu pose (l''enseignant sans lieu), pas celui de la direction');
SELECT pg_temp.vrai(
  (SELECT ps.place_label = 'Marseille' AND ps.lieu_source = 'auto'
     FROM public.prayer_settings ps WHERE ps.teacher_id = 'd7000000-0000-4000-8000-000000000002')
  AND (SELECT ps.place_label = 'Paris' AND ps.lieu_source = 'direction'
         FROM public.prayer_settings ps WHERE ps.teacher_id = 'd7000000-0000-4000-8000-000000000003')
  AND (SELECT pg_catalog.count(*) FROM public.prayer_settings) = 2,
  'rattrapage : la ville de l''enseignant redevient son lieu de priere, rien d''autre ne bouge');

ROLLBACK;
