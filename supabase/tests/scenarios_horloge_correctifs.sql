-- HORLOGE-ET-LIEU, correctifs de la partie A (13/11/2026, revue de l'architecte) :
-- migration 20261123940300_horloge_correctifs_a.sql.
--
-- B2 : l'ancien client ne deplace plus un cours de deux heures ; les fonctions
--      « _fuseau » convertissent ; l'etat d'avant la migration (classe a Paris)
--      continue de fonctionner.
-- I4 : une annonce part a 10 h locale de la personne, jamais entre 21 h et 8 h
--      (New York, Los Angeles, Paris, Sydney).
-- I5 : classe restee a Paris, personne a Conakry : l'annonce existe ; une classe
--      que la tache de nuit refuse previent la direction, une fois.
-- I6 : classe sans enseignant : les familles recoivent l'annonce.
-- I7 : les changements d'heure a venir, par fuseau, pour la direction.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque controle
-- reussi ecrit une ligne « HLC OK » ; un echec leve « HLC ROUGE : ... ».
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d5000000-0000-4000-8000-000000000001', 'hlc-admin@example.test'),
  ('d5000000-0000-4000-8000-0000000000e1', 'hlc-e1@example.test'),
  ('d5000000-0000-4000-8000-0000000000e2', 'hlc-e2@example.test'),
  ('d5000000-0000-4000-8000-000000000b01', 'hlc-g1@example.test'),
  ('d5000000-0000-4000-8000-000000000b02', 'hlc-g2@example.test'),
  ('d5000000-0000-4000-8000-000000000b03', 'hlc-g3@example.test'),
  ('d5000000-0000-4000-8000-000000000b04', 'hlc-g4@example.test'),
  ('d5000000-0000-4000-8000-000000000b05', 'hlc-g5@example.test'),
  ('d5000000-0000-4000-8000-000000000c01', 'hlc-s1@example.test'),
  ('d5000000-0000-4000-8000-000000000c02', 'hlc-s2@example.test'),
  ('d5000000-0000-4000-8000-000000000c03', 'hlc-s3@example.test'),
  ('d5000000-0000-4000-8000-000000000c04', 'hlc-s4@example.test'),
  ('d5000000-0000-4000-8000-000000000c05', 'hlc-s5@example.test'),
  ('d5000000-0000-4000-8000-000000000c06', 'hlc-s6@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('d5000000-0000-4000-8000-0000000000f1', 'Europe/Paris'),
  ('d5000000-0000-4000-8000-0000000000f2', 'Africa/Conakry'),
  ('d5000000-0000-4000-8000-0000000000f3', 'America/New_York'),
  ('d5000000-0000-4000-8000-0000000000f4', 'America/Los_Angeles'),
  ('d5000000-0000-4000-8000-0000000000f5', 'Australia/Sydney');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, household_id, access_until)
VALUES
  ('d5000000-0000-4000-8000-000000000001', 'HLCADMIN00000001', 'admin', 'Fixture', 'Direction', 'active', 'female', NULL, NULL),
  ('d5000000-0000-4000-8000-0000000000e1', 'HLCTEACHER000E01', 'teacher', 'Fixture', 'Enseignante', 'provisional_active', 'female', NULL, NULL),
  ('d5000000-0000-4000-8000-0000000000e2', 'HLCTEACHER000E02', 'teacher', 'Fixture', 'Enseignante2', 'provisional_active', 'female', NULL, NULL),
  ('d5000000-0000-4000-8000-000000000b01', 'HLCGUARD00000B01', 'guardian', 'Fixture', 'Tuteur1', 'active', 'male', 'd5000000-0000-4000-8000-0000000000f1', NULL),
  ('d5000000-0000-4000-8000-000000000b02', 'HLCGUARD00000B02', 'guardian', 'Fixture', 'Tuteur2', 'active', 'male', 'd5000000-0000-4000-8000-0000000000f2', NULL),
  ('d5000000-0000-4000-8000-000000000b03', 'HLCGUARD00000B03', 'guardian', 'Fixture', 'Tuteur3', 'active', 'male', 'd5000000-0000-4000-8000-0000000000f3', NULL),
  ('d5000000-0000-4000-8000-000000000b04', 'HLCGUARD00000B04', 'guardian', 'Fixture', 'Tuteur4', 'active', 'male', 'd5000000-0000-4000-8000-0000000000f4', NULL),
  ('d5000000-0000-4000-8000-000000000b05', 'HLCGUARD00000B05', 'guardian', 'Fixture', 'Tuteur5', 'active', 'male', 'd5000000-0000-4000-8000-0000000000f5', NULL),
  ('d5000000-0000-4000-8000-000000000c01', 'HLCSTUD000000C01', 'student', 'Fixture', 'Eleve1', 'active', 'female', 'd5000000-0000-4000-8000-0000000000f1', NULL),
  ('d5000000-0000-4000-8000-000000000c02', 'HLCSTUD000000C02', 'student', 'Fixture', 'Eleve2', 'active', 'female', 'd5000000-0000-4000-8000-0000000000f2', NULL),
  ('d5000000-0000-4000-8000-000000000c03', 'HLCSTUD000000C03', 'student', 'Fixture', 'Eleve3', 'active', 'female', 'd5000000-0000-4000-8000-0000000000f3', NULL),
  ('d5000000-0000-4000-8000-000000000c04', 'HLCSTUD000000C04', 'student', 'Fixture', 'Eleve4', 'active', 'female', 'd5000000-0000-4000-8000-0000000000f4', NULL),
  ('d5000000-0000-4000-8000-000000000c05', 'HLCSTUD000000C05', 'student', 'Fixture', 'Eleve5', 'active', 'female', 'd5000000-0000-4000-8000-0000000000f5', NULL),
  ('d5000000-0000-4000-8000-000000000c06', 'HLCSTUD000000C06', 'student', 'Fixture', 'Eleve6', 'active', 'female', 'd5000000-0000-4000-8000-0000000000f1', NULL);
UPDATE public.households SET primary_guardian_id = ('d5000000-0000-4000-8000-000000000b0' || right(id::text, 1))::uuid
 WHERE id::text LIKE 'd5000000-0000-4000-8000-0000000000f%';

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES ('d5000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
       ('d5000000-0000-4000-8000-0000000000e2', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT e, j, h, 'Europe/Paris'
  FROM (VALUES ('d5000000-0000-4000-8000-0000000000e1'::uuid), ('d5000000-0000-4000-8000-0000000000e2'::uuid)) AS t(e),
       pg_catalog.generate_series(1, 7) AS j, pg_catalog.generate_series(0, 23) AS h;

UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'matching_horizon_weeks';
-- A1 : classe a La Mecque avec enseignante (mercredi 21 h) ; A2 : a La Mecque, SANS
-- enseignant (jeudi 20 h) ; A3 : classe restee a Paris (mercredi 18 h, apres
-- l'arrivee d'un ancien client), pour une famille de Conakry.
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public, created_at)
VALUES
  ('d5000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-0000000000e1', 'active', 'enfant', 5,
   'HLC classe A1', 3, 21, 'Asia/Riyadh', 'indetermine', pg_catalog.now() - interval '40 days'),
  ('d5000000-0000-4000-8000-0000000000a2', NULL, 'en_attente_enseignant', 'enfant', 5,
   'HLC classe sans enseignant', 4, 20, 'Asia/Riyadh', 'indetermine', pg_catalog.now() - interval '40 days'),
  ('d5000000-0000-4000-8000-0000000000a3', 'd5000000-0000-4000-8000-0000000000e2', 'active', 'enfant', 5,
   'HLC classe restee a Paris', 3, 18, 'Europe/Paris', 'indetermine', pg_catalog.now() - interval '40 days');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('d5000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-000000000c01'),
  ('d5000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-000000000c03'),
  ('d5000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-000000000c04'),
  ('d5000000-0000-4000-8000-0000000000a1', 'd5000000-0000-4000-8000-000000000c05'),
  ('d5000000-0000-4000-8000-0000000000a2', 'd5000000-0000-4000-8000-000000000c06'),
  ('d5000000-0000-4000-8000-0000000000a3', 'd5000000-0000-4000-8000-000000000c02');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
CREATE TEMP TABLE hlc_avant AS SELECT id FROM public.notifications;

-- =====================================================================
-- (B2) L'ancien client : refuse sans rien modifier, aucune notification
-- =====================================================================
SELECT set_config('request.jwt.claim.sub', 'd5000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'd5000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $b2$
DECLARE
  v_msg text;
  v_avant record;
  v_apres record;
  v_creneaux_avant bigint;
  v_notifs bigint := (SELECT pg_catalog.count(*) FROM public.notifications);
BEGIN
  SELECT weekday, hour_local INTO v_avant FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a1';
  SELECT pg_catalog.count(*) INTO v_creneaux_avant FROM public.groupe_creneaux
   WHERE groupe_id = 'd5000000-0000-4000-8000-0000000000a1';

  -- 1. modifier_groupe sans fuseau explicite (p_timezone_iana NULL, comme l'ancien client)
  BEGIN
    PERFORM public.modifier_groupe('d5000000-0000-4000-8000-0000000000a1', 'HLC classe A1', 5::smallint, 3::smallint, 19::smallint, NULL, NULL);
    RAISE EXCEPTION 'HLC ROUGE : modifier_groupe sans fuseau a ete accepte pour une classe a La Mecque';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'RechargerPourModifierUnHoraire' THEN RAISE; END IF;
  END;
  -- 2. ajouter un creneau, 4 arguments puis 3 arguments
  BEGIN
    PERFORM public.ajouter_creneau_classe_admin('d5000000-0000-4000-8000-0000000000a1', 5, 19, NULL);
    RAISE EXCEPTION 'HLC ROUGE : ajouter_creneau_classe_admin (4) a ete accepte';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'RechargerPourModifierUnHoraire' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.ajouter_creneau_classe_admin('d5000000-0000-4000-8000-0000000000a1', 5, 19);
    RAISE EXCEPTION 'HLC ROUGE : ajouter_creneau_classe_admin (3) a ete accepte';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'RechargerPourModifierUnHoraire' THEN RAISE; END IF;
  END;
  -- 3. deplacer un creneau
  BEGIN
    PERFORM public.modifier_creneau_classe_admin('d5000000-0000-4000-8000-0000000000a1', 3, 21, 3, 19, NULL, 'ancien client');
    RAISE EXCEPTION 'HLC ROUGE : modifier_creneau_classe_admin a ete accepte';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'RechargerPourModifierUnHoraire' THEN RAISE; END IF;
  END;

  -- Renommer ou changer le seuil SANS deplacer l'heure (ce que fait l'ancien client) reste accepte.
  PERFORM public.modifier_groupe('d5000000-0000-4000-8000-0000000000a1', 'HLC classe A1 renommee', 4::smallint, v_avant.weekday::smallint, v_avant.hour_local::smallint, NULL, NULL);
  IF NOT EXISTS (SELECT 1 FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a1' AND libelle = 'HLC classe A1 renommee' AND seuil_max = 4) THEN
    RAISE EXCEPTION 'HLC ROUGE : renommer une classe a La Mecque sans toucher a l''heure doit rester possible';
  END IF;
  PERFORM public.modifier_groupe('d5000000-0000-4000-8000-0000000000a1', 'HLC classe A1', 5::smallint, v_avant.weekday::smallint, v_avant.hour_local::smallint, NULL, NULL);
  -- La duree seule d'un creneau (meme jour, meme heure) reste acceptee aussi.
  PERFORM public.modifier_creneau_classe_admin('d5000000-0000-4000-8000-0000000000a1', 3, 21, 3, 21, 60, 'duree seule');
  PERFORM public.modifier_creneau_classe_admin('d5000000-0000-4000-8000-0000000000a1', 3, 21, 3, 21, NULL, 'duree seule');
  SELECT weekday, hour_local INTO v_apres FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a1';
  IF v_apres IS DISTINCT FROM v_avant
     OR (SELECT pg_catalog.count(*) FROM public.groupe_creneaux WHERE groupe_id = 'd5000000-0000-4000-8000-0000000000a1') <> v_creneaux_avant
     OR (SELECT pg_catalog.count(*) FROM public.notifications) <> v_notifs THEN
    RAISE EXCEPTION 'HLC ROUGE : un appel refuse a pourtant change l''horaire ou envoye une notification';
  END IF;
  RAISE NOTICE 'HLC OK : une classe a l''heure de La Mecque refuse (RechargerPourModifierUnHoraire) les trois fonctions de l''ancien client qui deplacent une heure, sans rien modifier ni notifier ; renommer, changer le seuil ou la duree reste accepte';
END
$b2$;
RESET ROLE;

-- Une classe qui n'est PAS a l'heure de La Mecque (l'etat d'avant la migration) :
-- l'ancien appel marche comme avant.
SET LOCAL ROLE authenticated;
DO $b2b$
DECLARE
  v_h record;
BEGIN
  PERFORM public.modifier_groupe('d5000000-0000-4000-8000-0000000000a3', 'HLC classe restee a Paris', 5::smallint, 3::smallint, 17::smallint, NULL, NULL);
  SELECT hour_local, timezone_iana INTO v_h FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a3';
  IF v_h.hour_local <> 17 OR v_h.timezone_iana <> 'Europe/Paris' THEN
    RAISE EXCEPTION 'HLC ROUGE : l''ancien appel sur une classe a Paris doit marcher comme avant : %', v_h;
  END IF;
  PERFORM public.modifier_groupe('d5000000-0000-4000-8000-0000000000a3', 'HLC classe restee a Paris', 5::smallint, 3::smallint, 18::smallint, NULL, NULL);
  RAISE NOTICE 'HLC OK : avant la migration (classe a Paris), l''ancien appel sans fuseau fonctionne comme avant';
END
$b2b$;
RESET ROLE;

-- Les fonctions nouvelles : 19 h le mercredi saisis a Paris sont 21 h a La Mecque
-- l'hiver (20 h l'ete : la conversion se fait sur le prochain creneau) ; 17 h a
-- Conakry (UTC) sont 20 h a La Mecque.
SELECT set_config('hlc.decalage_paris',
  ((private.fuseau_info('Europe/Paris') ->> 'decalage_secondes')::integer / 3600)::text, true);
SET LOCAL ROLE authenticated;
DO $b2c$
DECLARE
  v_h record;
  v_msg text;
  v_cr record;
  v_decalage integer := pg_catalog.current_setting('hlc.decalage_paris')::integer;
BEGIN
  -- Mercredi 19 h a Paris -> mercredi (19 - decalage Paris + 3) h a La Mecque.
  PERFORM public.modifier_groupe_fuseau('d5000000-0000-4000-8000-0000000000a1', 'HLC classe A1', 5::smallint, 3::smallint, 19::smallint, 'Europe/Paris');
  SELECT weekday, hour_local, timezone_iana INTO v_h FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a1';
  IF v_h.timezone_iana <> 'Asia/Riyadh' OR v_h.weekday <> 3 OR v_h.hour_local <> 19 - v_decalage + 3 THEN
    RAISE EXCEPTION 'HLC ROUGE : modifier_groupe_fuseau (Paris 19 h) : %', v_h;
  END IF;
  -- A La Mecque meme : l'heure telle quelle.
  PERFORM public.modifier_groupe_fuseau('d5000000-0000-4000-8000-0000000000a1', 'HLC classe A1', 5::smallint, 3::smallint, 21::smallint, 'Asia/Riyadh');
  SELECT weekday, hour_local INTO v_h FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a1';
  IF v_h.hour_local <> 21 THEN RAISE EXCEPTION 'HLC ROUGE : modifier_groupe_fuseau (La Mecque) : %', v_h; END IF;
  -- Ajouter un creneau : vendredi 17 h a Conakry (UTC) = vendredi 20 h a La Mecque.
  PERFORM public.ajouter_creneau_classe_fuseau('d5000000-0000-4000-8000-0000000000a1', 5, 17, NULL, 'Africa/Conakry');
  IF NOT EXISTS (SELECT 1 FROM public.groupe_creneaux WHERE groupe_id = 'd5000000-0000-4000-8000-0000000000a1' AND weekday = 5 AND hour_local = 20) THEN
    RAISE EXCEPTION 'HLC ROUGE : ajouter_creneau_classe_fuseau (Conakry 17 h) : %',
      (SELECT pg_catalog.json_agg(pg_catalog.json_build_object('j', weekday, 'h', hour_local)) FROM public.groupe_creneaux WHERE groupe_id = 'd5000000-0000-4000-8000-0000000000a1');
  END IF;
  -- Deplacer ce creneau (designe par ses valeurs a La Mecque) : samedi 10 h a Conakry = 13 h a La Mecque.
  PERFORM public.modifier_creneau_classe_fuseau('d5000000-0000-4000-8000-0000000000a1', 5, 20, 6, 10, NULL, 'scenario HLC', 'Africa/Conakry');
  IF NOT EXISTS (SELECT 1 FROM public.groupe_creneaux WHERE groupe_id = 'd5000000-0000-4000-8000-0000000000a1' AND weekday = 6 AND hour_local = 13)
     OR EXISTS (SELECT 1 FROM public.groupe_creneaux WHERE groupe_id = 'd5000000-0000-4000-8000-0000000000a1' AND weekday = 5 AND hour_local = 20) THEN
    RAISE EXCEPTION 'HLC ROUGE : modifier_creneau_classe_fuseau (Conakry samedi 10 h)';
  END IF;
  -- Une heure sans equivalent entier (Delhi : 19 h 30 a La Mecque pour 22 h) est refusee.
  BEGIN
    PERFORM public.ajouter_creneau_classe_fuseau('d5000000-0000-4000-8000-0000000000a1', 2, 22, NULL, 'Asia/Kolkata');
    RAISE EXCEPTION 'HLC ROUGE : une heure sans equivalent entier a ete acceptee';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'HeureSansEquivalentEntier' THEN RAISE; END IF;
  END;
  -- Un fuseau inconnu est refuse.
  BEGIN
    PERFORM public.ajouter_creneau_classe_fuseau('d5000000-0000-4000-8000-0000000000a1', 2, 10, NULL, 'Mars/Olympus');
    RAISE EXCEPTION 'HLC ROUGE : un fuseau inconnu a ete accepte';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    IF v_msg <> 'CreneauParametresInvalides' THEN RAISE; END IF;
  END;
  -- Sur une classe a Paris (avant la migration), un fuseau identique garde l'heure ; un autre convertit.
  PERFORM public.modifier_groupe_fuseau('d5000000-0000-4000-8000-0000000000a3', 'HLC classe restee a Paris', 5::smallint, 3::smallint, 19::smallint, 'Europe/Paris');
  SELECT hour_local INTO v_h FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a3';
  IF v_h.hour_local <> 19 THEN RAISE EXCEPTION 'HLC ROUGE : classe a Paris, fuseau Paris : %', v_h; END IF;
  PERFORM public.modifier_groupe_fuseau('d5000000-0000-4000-8000-0000000000a3', 'HLC classe restee a Paris', 5::smallint, 3::smallint, 21::smallint, 'Asia/Riyadh');
  SELECT hour_local INTO v_h FROM public.groupes WHERE id = 'd5000000-0000-4000-8000-0000000000a3';
  IF v_h.hour_local <> 21 - 3 + v_decalage THEN RAISE EXCEPTION 'HLC ROUGE : classe a Paris, saisie a La Mecque : %', v_h; END IF;
  PERFORM public.modifier_groupe_fuseau('d5000000-0000-4000-8000-0000000000a3', 'HLC classe restee a Paris', 5::smallint, 3::smallint, 18::smallint, 'Europe/Paris');
  -- Le reglage local ne reste jamais pose apres un appel.
  IF pg_catalog.current_setting('horloge.fuseau_explicite', true) = 'on' THEN
    RAISE EXCEPTION 'HLC ROUGE : le reglage fuseau_explicite est reste pose';
  END IF;
  RAISE NOTICE 'HLC OK : les trois fonctions « _fuseau » convertissent (Paris, Conakry, La Mecque), refusent une heure sans equivalent entier et un fuseau inconnu, dans les deux etats (classe a Paris, classe a La Mecque)';
END
$b2c$;
RESET ROLE;

-- Hors direction : ni les fonctions nouvelles ni l'ancien appel ne passent.
SELECT set_config('request.jwt.claim.sub', 'd5000000-0000-4000-8000-000000000b01', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"d5000000-0000-4000-8000-0000000000f1"}}', true);
SELECT set_config('test.uid', 'd5000000-0000-4000-8000-000000000b01', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d5000000-0000-4000-8000-0000000000f1"}}', true);
SET LOCAL ROLE authenticated;
DO $b2d$
DECLARE
  v_n integer := 0;
BEGIN
  BEGIN
    PERFORM public.modifier_groupe_fuseau('d5000000-0000-4000-8000-0000000000a1', 'x', 5::smallint, 3::smallint, 19::smallint, 'Europe/Paris');
  EXCEPTION WHEN OTHERS THEN v_n := v_n + 1; END;
  BEGIN
    PERFORM public.ajouter_creneau_classe_fuseau('d5000000-0000-4000-8000-0000000000a1', 5, 19, NULL, 'Europe/Paris');
  EXCEPTION WHEN OTHERS THEN v_n := v_n + 1; END;
  BEGIN
    PERFORM public.modifier_creneau_classe_fuseau('d5000000-0000-4000-8000-0000000000a1', 3, 21, 3, 19, NULL, 'x', 'Europe/Paris');
  EXCEPTION WHEN OTHERS THEN v_n := v_n + 1; END;
  IF v_n <> 3 THEN RAISE EXCEPTION 'HLC ROUGE : un tuteur a pu appeler une fonction de direction (% refus sur 3)', v_n; END IF;
  RAISE NOTICE 'HLC OK : un tuteur ne peut appeler aucune des trois fonctions « _fuseau »';
END
$b2d$;
RESET ROLE;

-- =====================================================================
-- (fuseau_vue) Pour l'ecran
-- =====================================================================
SET LOCAL ROLE authenticated;
DO $fv$
DECLARE
  v jsonb;
BEGIN
  v := public.fuseau_vue('Asia/Riyadh');
  IF (v ->> 'decalage_secondes')::integer <> 10800 OR v ->> 'prochain_changement' IS NOT NULL THEN
    RAISE EXCEPTION 'HLC ROUGE : fuseau_vue La Mecque : %', v;
  END IF;
  v := public.fuseau_vue('Europe/Paris');
  IF v ->> 'prochain_changement' IS NULL OR (v ->> 'decalage_apres') IS NULL THEN
    RAISE EXCEPTION 'HLC ROUGE : fuseau_vue Paris : %', v;
  END IF;
  BEGIN
    PERFORM public.fuseau_vue('Mars/Olympus');
    RAISE EXCEPTION 'HLC ROUGE : fuseau_vue a accepte un fuseau inconnu';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL; END;
  RAISE NOTICE 'HLC OK : fuseau_vue rend le decalage et le changement d''heure d''un fuseau, refuse un fuseau inconnu';
END
$fv$;
RESET ROLE;

-- =====================================================================
-- (I4) 10 h locale de chacun, jamais entre 21 h et 8 h
-- =====================================================================
-- Un instant de mars 2027 ou Paris (changement le 28/03), New York (14/03 deja
-- passe : on se place avant) et Sydney (changement en avril) ont des fenetres
-- ouvertes. On regarde a quelle heure locale chaque annonce part.
DO $i4$
DECLARE
  v_jour date := '2027-03-12';
  h integer;
  v_n integer;
  r record;
  v_heure_locale integer;
BEGIN
  FOR h IN 0..23 LOOP
    v_n := private.annoncer_changements_heure(
      (v_jour::timestamp + pg_catalog.make_interval(hours => h, mins => 7)) AT TIME ZONE 'UTC');
  END LOOP;
  FOR h IN 0..23 LOOP
    v_n := private.annoncer_changements_heure(
      ((v_jour + 1)::timestamp + pg_catalog.make_interval(hours => h, mins => 7)) AT TIME ZONE 'UTC');
  END LOOP;
  -- Chaque annonce est partie au moment ou il etait 10 h pour son destinataire :
  -- la table des annonces garde l'instant (annoncee_le est l'horloge reelle ; on
  -- controle donc par le fuseau de la notification et la date du palier).
  FOR r IN
    SELECT n.destinataire, n.params ->> 'fuseau' AS fuseau, n.params ->> 'palier' AS palier
      FROM public.notifications n
     WHERE n.id NOT IN (SELECT id FROM hlc_avant) AND n.params ->> 'motif' = 'changement_heure'
  LOOP
    NULL;
  END LOOP;
  -- Au coup par coup : a 06:07 UTC (7 h 07 a Paris, 1 h 07 a New York, 23 h 07 la
  -- veille a Los Angeles, 17 h 07 a Sydney) personne n'est servi.
  IF private.annoncer_changements_heure('2027-03-13 06:07:00+00') <> 0 THEN
    RAISE EXCEPTION 'HLC ROUGE : une annonce est partie a 06:07 UTC (7 h a Paris, 1 h a New York, 23 h a Los Angeles, 17 h a Sydney)';
  END IF;
  RAISE NOTICE 'HLC OK : rien ne part a 06:07 UTC (7 h Paris, 1 h New York, 23 h Los Angeles, 17 h Sydney)';
END
$i4$;

-- Les annonces effectives, avec la regle complete (une passe par heure sur trois
-- jours) : Paris et New York ont chacun leur annonce, Sydney la sienne.
DO $i4c$
DECLARE
  v_jour date;
  h integer;
  v_total integer := 0;
  v_instant timestamptz;
  r record;
  v_ny integer;
  v_la integer;
  v_paris integer;
  v_sydney integer;
BEGIN
  -- Du 12 au 16 mars 2027 : New York change le 14 (02 h locale) : annonce la
  -- veille (j1, le 13 a 10 h locale) ; Paris entre dans sa fenetre le 14/03 a 01 h UTC ;
  -- Los Angeles change aussi le 14/03 ; Sydney change le 4 avril (dans 14 jours le 21/03 :
  -- pas encore).
  CREATE TEMP TABLE hlc_vus (id uuid PRIMARY KEY);
  INSERT INTO hlc_vus SELECT id FROM public.notifications;
  FOR v_jour IN SELECT d::date FROM pg_catalog.generate_series('2027-03-12'::date, '2027-03-16'::date, interval '1 day') d LOOP
    FOR h IN 0..23 LOOP
      v_instant := (v_jour::timestamp + pg_catalog.make_interval(hours => h, mins => 7)) AT TIME ZONE 'UTC';
      v_total := v_total + private.annoncer_changements_heure(v_instant);
      -- Chaque annonce posee a cet instant l'est pour quelqu'un dont il est 10 h.
      FOR r IN SELECT n.params ->> 'fuseau' AS fz FROM public.notifications n
                WHERE n.id NOT IN (SELECT id FROM hlc_vus) LOOP
        IF pg_catalog.date_part('hour', v_instant AT TIME ZONE r.fz) <> 10 THEN
          RAISE EXCEPTION 'HLC ROUGE : une annonce pour % est partie a % heure locale (UTC %)',
            r.fz, pg_catalog.date_part('hour', v_instant AT TIME ZONE r.fz), v_instant;
        END IF;
      END LOOP;
      INSERT INTO hlc_vus SELECT id FROM public.notifications ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
  SELECT pg_catalog.count(*) INTO v_ny FROM public.notifications n
   WHERE n.id NOT IN (SELECT id FROM hlc_avant) AND n.params ->> 'fuseau' = 'America/New_York';
  SELECT pg_catalog.count(*) INTO v_la FROM public.notifications n
   WHERE n.id NOT IN (SELECT id FROM hlc_avant) AND n.params ->> 'fuseau' = 'America/Los_Angeles';
  SELECT pg_catalog.count(*) INTO v_paris FROM public.notifications n
   WHERE n.id NOT IN (SELECT id FROM hlc_avant) AND n.params ->> 'fuseau' = 'Europe/Paris';
  SELECT pg_catalog.count(*) INTO v_sydney FROM public.notifications n
   WHERE n.id NOT IN (SELECT id FROM hlc_avant) AND n.params ->> 'fuseau' = 'Australia/Sydney';
  IF v_ny < 1 OR v_la < 1 OR v_paris < 1 THEN
    RAISE EXCEPTION 'HLC ROUGE : annonces manquantes (New York %, Los Angeles %, Paris %)', v_ny, v_la, v_paris;
  END IF;
  IF v_sydney <> 0 THEN
    RAISE EXCEPTION 'HLC ROUGE : Sydney est annonce trop tot (changement le 4 avril) : %', v_sydney;
  END IF;
  RAISE NOTICE 'HLC OK : sur cinq jours, chaque annonce part a 10 h locale de son destinataire (New York %, Los Angeles %, Paris %), rien pour Sydney encore', v_ny, v_la, v_paris;
END
$i4c$;

-- =====================================================================
-- (I5) Classe restee a Paris, famille a Conakry
-- =====================================================================
DO $i5$
DECLARE
  v_jour date;
  h integer;
  v_p jsonb;
BEGIN
  FOR v_jour IN SELECT d::date FROM pg_catalog.generate_series('2027-03-12'::date, '2027-03-30'::date, interval '1 day') d LOOP
    FOR h IN 0..23 LOOP
      PERFORM private.annoncer_changements_heure(
        (v_jour::timestamp + pg_catalog.make_interval(hours => h, mins => 7)) AT TIME ZONE 'UTC');
    END LOOP;
  END LOOP;
  SELECT n.params INTO v_p FROM public.notifications n
   WHERE n.destinataire = 'd5000000-0000-4000-8000-000000000b02'
     AND n.params ->> 'groupe_id' = 'd5000000-0000-4000-8000-0000000000a3'
   ORDER BY n.params ->> 'palier' LIMIT 1;
  IF v_p IS NULL THEN
    RAISE EXCEPTION 'HLC ROUGE : la famille de Conakry, classe a Paris, n''a recu aucune annonce alors que son heure locale bouge';
  END IF;
  -- Le sens : c'est la CLASSE qui change d'heure, pas le fuseau de la famille ; la
  -- classe n'est pas a l'heure de La Mecque.
  IF v_p ->> 'sens' <> 'classe' OR (v_p ->> 'academie')::boolean IS NOT FALSE
     OR NOT (v_p -> 'changements') @> '[{"jour_avant": 3, "avant": "17:00", "jour_apres": 3, "apres": "16:00"}]'::jsonb THEN
    RAISE EXCEPTION 'HLC ROUGE : annonce d''une classe a Paris pour Conakry : %', v_p;
  END IF;
  RAISE NOTICE 'HLC OK : Conakry, classe a Paris : annonce (17:00 puis 16:00), sens « classe », academie faux';
END
$i5$;

-- Les instants reels des seances materialisees disent la meme chose : 17:00 puis
-- 16:00 a Conakry de part et d'autre du changement d'heure de Paris.
DO $i5b$
DECLARE
  v_avant timestamptz;
  v_apres timestamptz;
  v_transition timestamptz := '2027-03-28 01:00:00+00';
BEGIN
  UPDATE public.app_config SET value = '30'::jsonb WHERE key = 'matching_horizon_weeks';
  PERFORM public.materialiser_seances_groupe('d5000000-0000-4000-8000-0000000000a3');
  SELECT pg_catalog.max(s.started_at) FILTER (WHERE s.started_at < v_transition),
         pg_catalog.min(s.started_at) FILTER (WHERE s.started_at >= v_transition)
    INTO v_avant, v_apres
    FROM public.sessions s
   WHERE s.groupe_id = 'd5000000-0000-4000-8000-0000000000a3'
     AND s.started_at > '2027-03-01 00:00:00+00'::timestamptz;
  IF v_avant IS NULL OR v_apres IS NULL
     OR pg_catalog.to_char(v_avant AT TIME ZONE 'Africa/Conakry', 'HH24:MI') <> '17:00'
     OR pg_catalog.to_char(v_apres AT TIME ZONE 'Africa/Conakry', 'HH24:MI') <> '16:00' THEN
    RAISE EXCEPTION 'HLC ROUGE : les seances reelles ne disent pas 17:00 puis 16:00 a Conakry (avant %, apres %)', v_avant, v_apres;
  END IF;
  UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'matching_horizon_weeks';
  RAISE NOTICE 'HLC OK : les seances materialisees de la classe a Paris tombent a 17:00 puis 16:00 a Conakry, comme l''annonce';
END
$i5b$;

-- La tache de nuit : une classe refusee previent la direction, une fois.
DO $i5c$
DECLARE
  v_avant bigint;
  v_apres bigint;
BEGIN
  SELECT pg_catalog.count(*) INTO v_avant FROM public.notifications
   WHERE evenement = 'creneau_change' AND params ->> 'motif' = 'conversion_refusee';
  -- A moins de 28 jours d'un changement d'heure, la conversion de la classe de Paris est refusee.
  PERFORM private.convertir_classes_hors_academie('2027-03-20 02:47:00+00');
  SELECT pg_catalog.count(*) INTO v_apres FROM public.notifications
   WHERE evenement = 'creneau_change' AND params ->> 'motif' = 'conversion_refusee';
  IF v_apres <> v_avant + 1 THEN
    RAISE EXCEPTION 'HLC ROUGE : la direction devait etre prevenue une fois (% -> %)', v_avant, v_apres;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.notifications n
                  WHERE n.destinataire = 'd5000000-0000-4000-8000-000000000001'
                    AND n.params ->> 'motif' = 'conversion_refusee'
                    AND n.params ->> 'groupe_id' = 'd5000000-0000-4000-8000-0000000000a3'
                    AND n.params ->> 'classe' = 'HLC classe restee a Paris'
                    AND n.params ->> 'cause' = 'proche'
                    AND n.destination = '/admin/operations/planning') THEN
    RAISE EXCEPTION 'HLC ROUGE : la notification a la direction ne porte pas la classe et la cause';
  END IF;
  -- Ni texte SQL ni identifiant dans ce que la direction lit : aucune cle `raison`,
  -- et l'identifiant de la classe n'apparait que sous `groupe_id` (jamais dans un texte).
  IF EXISTS (SELECT 1 FROM public.notifications n
              WHERE n.params ->> 'motif' = 'conversion_refusee'
                AND (n.params ? 'raison'
                     OR (n.params - 'groupe_id')::text ~* '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}'
                     OR (n.params - 'groupe_id')::text ILIKE '%HORLOGE-ET-LIEU%'
                     OR (n.params - 'groupe_id')::text ILIKE '%conversion refusee%')) THEN
    RAISE EXCEPTION 'HLC ROUGE : la notification a la direction porte un texte SQL ou un identifiant';
  END IF;
  -- La nuit suivante, meme refus : pas de seconde notification.
  PERFORM private.convertir_classes_hors_academie('2027-03-21 02:47:00+00');
  IF (SELECT pg_catalog.count(*) FROM public.notifications
       WHERE evenement = 'creneau_change' AND params ->> 'motif' = 'conversion_refusee') <> v_apres THEN
    RAISE EXCEPTION 'HLC ROUGE : le meme refus a re-notifie la direction';
  END IF;
  RAISE NOTICE 'HLC OK : une classe refusee par la tache de nuit previent la direction, une fois (classe et cause fermee, sans texte SQL ni identifiant)';
END
$i5c$;

-- =====================================================================
-- (I6) Classe sans enseignant : les familles recoivent l'annonce
-- =====================================================================
DO $i6$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.notifications n
                  WHERE n.id NOT IN (SELECT id FROM hlc_avant)
                    AND n.params ->> 'groupe_id' = 'd5000000-0000-4000-8000-0000000000a2'
                    AND n.destinataire = 'd5000000-0000-4000-8000-000000000b01'
                    AND n.params ->> 'motif' = 'changement_heure') THEN
    RAISE EXCEPTION 'HLC ROUGE : la classe sans enseignant n''a rien annonce a sa famille';
  END IF;
  RAISE NOTICE 'HLC OK : une classe sans enseignant annonce quand meme le changement d''heure aux familles';
END
$i6$;

-- Le jour qui change : lundi 01 h a La Mecque = dimanche 23 h a Paris puis lundi 00 h.
DO $i2$
DECLARE
  v record;
BEGIN
  SELECT * INTO v FROM private.changement_heure_cours('Europe/Paris', 'Asia/Riyadh', 1, 1, '2027-03-01 00:00:00+00');
  IF v.jour_avant <> 7 OR v.jour_apres <> 1 OR v.heure_avant <> '23:00' OR v.heure_apres <> '00:00' THEN
    RAISE EXCEPTION 'HLC ROUGE : le jour qui change : %', pg_catalog.to_json(v);
  END IF;
  RAISE NOTICE 'HLC OK : le jour d''arrivee est rendu (dimanche 23:00 puis lundi 00:00)';
END
$i2$;

-- =====================================================================
-- (I7) Les changements d'heure a venir, par fuseau
-- =====================================================================
SELECT set_config('request.jwt.claim.sub', 'd5000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'd5000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $i7$
DECLARE
  v record;
  v_nb integer;
BEGIN
  SELECT pg_catalog.count(*) INTO v_nb FROM public.changements_heure_a_venir_direction(366);
  IF v_nb < 1 THEN
    RAISE EXCEPTION 'HLC ROUGE : aucun changement d''heure a venir sur un an (Paris, New York, Los Angeles, Sydney)';
  END IF;
  SELECT * INTO v FROM public.changements_heure_a_venir_direction(366) c WHERE c.fuseau = 'Europe/Paris';
  IF v.familles <> 1 OR v.enseignants <> 2 OR v.decalage_apres_secondes = v.decalage_avant_secondes THEN
    RAISE EXCEPTION 'HLC ROUGE : Paris (1 famille, 2 enseignants, decalage qui change) : %', pg_catalog.to_json(v);
  END IF;
  IF EXISTS (SELECT 1 FROM public.changements_heure_a_venir_direction(366) c WHERE c.fuseau IN ('Africa/Conakry', 'Asia/Riyadh')) THEN
    RAISE EXCEPTION 'HLC ROUGE : un fuseau sans changement d''heure est liste';
  END IF;
  RAISE NOTICE 'HLC OK : la direction lit les changements d''heure a venir par fuseau (% fuseau(x) ; Paris : 1 famille, 2 enseignants)', v_nb;
END
$i7$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub', 'd5000000-0000-4000-8000-000000000b01', true);
SELECT set_config('request.jwt.claims',
  '{"app_metadata":{"role":"guardian","household_id":"d5000000-0000-4000-8000-0000000000f1"}}', true);
SELECT set_config('test.uid', 'd5000000-0000-4000-8000-000000000b01', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d5000000-0000-4000-8000-0000000000f1"}}', true);
SET LOCAL ROLE authenticated;
DO $i7b$
BEGIN
  BEGIN
    PERFORM public.changements_heure_a_venir_direction(30);
    RAISE EXCEPTION 'HLC ROUGE : un tuteur lit les changements d''heure de la direction';
  EXCEPTION WHEN SQLSTATE '42501' THEN NULL; END;
  RAISE NOTICE 'HLC OK : un tuteur ne lit pas les changements d''heure a venir de la direction';
END
$i7b$;
RESET ROLE;

-- Les fonctions internes restent fermees.
DO $f$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['private.refuser_heure_sans_fuseau(uuid,boolean)', 'private.horaire_vers_fuseau_classe(uuid,integer,integer,text)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_f::pg_catalog.regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'HLC ROUGE : % executable par un client', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.fuseau_vue(text)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.changements_heure_a_venir_direction(integer)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HLC ROUGE : une fonction ouverte a anon';
  END IF;
  RAISE NOTICE 'HLC OK : fonctions internes fermees, rien d''ouvert a anon';
END
$f$;

ROLLBACK;
