-- Lot O1 (02/11/2026) : l'observation des parents, prouvee cote serveur.
-- Migration 20261105500000_o1_observation_coupure.sql.
--
-- Decision du directeur (31/10/2026) : 2 visites par seance au plus, 2
-- minutes au plus chacune ; une visite ecourtee compte. Le scenario pose ces
-- valeurs dans app_config (comme en production, relu le 02/11) : aucune n'est
-- lue en dur par le serveur.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque
-- controle reussi ecrit « O1 OK » ; un echec leve « O1 ROUGE : ... ».
BEGIN;

-- La politique de l'academie : 2 visites, 120 s par visite, 240 s au total.
INSERT INTO public.app_config (key, value) VALUES
  ('observation.activee', 'true'::jsonb),
  ('observation.max_visits_per_session', '2'::jsonb),
  ('observation.max_seconds_per_visit', '120'::jsonb),
  ('observation.max_total_seconds', '240'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

INSERT INTO auth.users (id, email) VALUES
  ('01000000-0000-4000-8000-0000000000a1', 'o1-admin@example.test'),
  ('01000000-0000-4000-8000-0000000000e1', 'o1-enseignant@example.test'),
  ('01000000-0000-4000-8000-0000000000f1', 'o1-tuteur1@example.test'),
  ('01000000-0000-4000-8000-0000000000c1', 'o1-enfant1@example.test'),
  ('01000000-0000-4000-8000-0000000000f2', 'o1-tuteur2@example.test'),
  ('01000000-0000-4000-8000-0000000000c2', 'o1-enfant2@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('01000000-0000-4000-8000-00000000f001', 'Europe/Paris'),
  ('01000000-0000-4000-8000-00000000f002', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('01000000-0000-4000-8000-0000000000a1', 'O1ADMIN00000001', 'admin', NULL,
   'Fixture', 'Direction', 'active', 'female'),
  ('01000000-0000-4000-8000-0000000000e1', 'O1TEACHER000001', 'teacher', NULL,
   'Fixture', 'Enseignante', 'provisional_active', 'female'),
  ('01000000-0000-4000-8000-0000000000f1', 'O1TUTEUR0000001', 'guardian',
   '01000000-0000-4000-8000-00000000f001', 'Fixture', 'Tuteur Un', 'active', 'female'),
  ('01000000-0000-4000-8000-0000000000c1', 'O1ENFANT0000001', 'student',
   '01000000-0000-4000-8000-00000000f001', 'Fixture', 'Enfant Un', 'active', 'female'),
  ('01000000-0000-4000-8000-0000000000f2', 'O1TUTEUR0000002', 'guardian',
   '01000000-0000-4000-8000-00000000f002', 'Fixture', 'Tuteur Deux', 'active', 'female'),
  ('01000000-0000-4000-8000-0000000000c2', 'O1ENFANT0000002', 'student',
   '01000000-0000-4000-8000-00000000f002', 'Fixture', 'Enfant Deux', 'active', 'female');

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('01000000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- Une classe (ses seances recurrentes tombent dans trois jours, loin de la
-- seance de ce scenario) et une seance en cours, ouverte il y a 10 minutes.
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('01000000-0000-4000-8000-00000000c1a5', '01000000-0000-4000-8000-0000000000e1',
        'enfant', 5, 'O1 classe',
        pg_catalog.date_part('isodow', pg_catalog.now() AT TIME ZONE 'UTC' + interval '3 days')::smallint,
        9, 'UTC');
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('01000000-0000-4000-8000-00000000c1a5', '01000000-0000-4000-8000-0000000000c1'),
  ('01000000-0000-4000-8000-00000000c1a5', '01000000-0000-4000-8000-0000000000c2');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
VALUES ('01000000-0000-4000-8000-0000005e55e0', '01000000-0000-4000-8000-0000000000e1',
        pg_catalog.now() - interval '10 minutes', pg_catalog.now() + interval '50 minutes',
        'child', '01000000-0000-4000-8000-00000000c1a5', pg_catalog.now() - interval '30 minutes');

-- Se mettre dans la peau d'un compte.
CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_claims text := pg_catalog.jsonb_build_object('sub', p_id,
    'app_metadata', pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
      'role', p_role, 'household_id', p_foyer)))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_claims, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('test.jwt', v_claims, true);
END $$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated;

CREATE TEMP TABLE o1_note (cle text PRIMARY KEY, valeur text);
GRANT ALL ON o1_note TO authenticated;

-- (1) Le tuteur entre ; l'enseignant et SON enfant sont prevenus, personne
-- d'autre.
SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000f1', 'guardian', '01000000-0000-4000-8000-00000000f001');
SET LOCAL ROLE authenticated;
DO $o1$
DECLARE v jsonb;
BEGIN
  v := public.entrer_observation('01000000-0000-4000-8000-0000005e55e0', 'guardian_observer');
  IF NOT coalesce((v->>'autorise')::boolean, false) THEN
    RAISE EXCEPTION 'O1 ROUGE : premiere visite refusee : %', v;
  END IF;
  IF v #>> '{visite,enfant_profile_id}' IS DISTINCT FROM '01000000-0000-4000-8000-0000000000c1' THEN
    RAISE EXCEPTION 'O1 ROUGE : la visite ne nomme pas l''enfant du tuteur : %', v;
  END IF;
  INSERT INTO o1_note VALUES ('visite1', v #>> '{visite,id}');
  RAISE NOTICE 'O1 OK : (1) premiere visite ouverte, rattachee a l''enfant du tuteur';
END $o1$;
RESET ROLE;

SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000e1', 'teacher');
SET LOCAL ROLE authenticated;
DO $o1$
DECLARE v jsonb;
BEGIN
  v := public.annonces_observation('01000000-0000-4000-8000-0000005e55e0');
  IF pg_catalog.jsonb_array_length(v) <> 1
     OR v->0->>'enfant_profile_id' <> '01000000-0000-4000-8000-0000000000c1' THEN
    RAISE EXCEPTION 'O1 ROUGE : l''enseignant n''est pas prevenu de la bonne visite : %', v;
  END IF;
  RAISE NOTICE 'O1 OK : (2) l''enseignant est prevenu (enfant concerne nomme)';
END $o1$;
RESET ROLE;

SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000c1', 'student', '01000000-0000-4000-8000-00000000f001');
SET LOCAL ROLE authenticated;
DO $o1$
BEGIN
  IF NOT (public.annonce_observation_pour_moi('01000000-0000-4000-8000-0000005e55e0')->>'observe')::boolean THEN
    RAISE EXCEPTION 'O1 ROUGE : l''enfant concerne n''est pas prevenu';
  END IF;
  RAISE NOTICE 'O1 OK : (3) l''enfant concerne est prevenu';
END $o1$;
RESET ROLE;

SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000c2', 'student', '01000000-0000-4000-8000-00000000f002');
SET LOCAL ROLE authenticated;
DO $o1$
BEGIN
  IF (public.annonce_observation_pour_moi('01000000-0000-4000-8000-0000005e55e0')->>'observe')::boolean THEN
    RAISE EXCEPTION 'O1 ROUGE : un autre enfant de la classe est prevenu';
  END IF;
  RAISE NOTICE 'O1 OK : (4) un autre enfant de la classe n''est pas prevenu';
END $o1$;
RESET ROLE;

SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000f2', 'guardian', '01000000-0000-4000-8000-00000000f002');
SET LOCAL ROLE authenticated;
DO $o1$
BEGIN
  BEGIN
    PERFORM public.annonces_observation('01000000-0000-4000-8000-0000005e55e0');
    RAISE EXCEPTION 'O1 ROUGE : un autre tuteur lit les annonces de l''enseignant';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'O1 OK : (5) un autre tuteur ne lit pas les annonces';
END $o1$;
RESET ROLE;

-- (6) Le jeton du tuteur qui regarde : ni micro, ni camera, ni partage
-- d'ecran ; invisible ; borne par le temps qui reste.
DO $o1$
DECLARE v jsonb;
BEGIN
  v := public.autoriser_jeton_video('01000000-0000-4000-8000-0000005e55e0',
         '01000000-0000-4000-8000-0000000000f1', 'wss://cloud.example.test', 'wss://self.example.test');
  IF coalesce((v #>> '{capabilities,can_publish}')::boolean, true)
     OR coalesce((v #>> '{capabilities,can_publish_video}')::boolean, true)
     OR NOT coalesce((v #>> '{capabilities,hidden}')::boolean, false)
     OR (v->>'ttl_seconds')::integer > 120 THEN
    RAISE EXCEPTION 'O1 ROUGE : jeton du tuteur trop large : %', v;
  END IF;
  RAISE NOTICE 'O1 OK : (6) jeton du tuteur sans publication, invisible, ttl % s <= 120', v->>'ttl_seconds';
END $o1$;

-- (7) La visite est coupee a la duree de la politique : on la fait commencer
-- il y a 130 s (au-dela des 120 s permises).
UPDATE public.guardian_session_visit
   SET entered_at = pg_catalog.now() - interval '130 seconds'
 WHERE id = (SELECT valeur::uuid FROM o1_note WHERE cle = 'visite1');
DO $o1$
DECLARE
  v jsonb;
  v_ligne public.guardian_session_visit;
BEGIN
  v := public.couper_visites_observation_echues('wss://cloud.example.test', 'wss://self.example.test');
  SELECT * INTO v_ligne FROM public.guardian_session_visit
   WHERE id = (SELECT valeur::uuid FROM o1_note WHERE cle = 'visite1');
  IF v_ligne.left_at IS NULL OR v_ligne.fin_de_visite <> 'quota_atteint'
     OR v_ligne.duration_seconds <> 120 THEN
    RAISE EXCEPTION 'O1 ROUGE : visite non coupee a 120 s : % / % / %',
      v_ligne.left_at, v_ligne.fin_de_visite, v_ligne.duration_seconds;
  END IF;
  IF pg_catalog.jsonb_array_length(v) <> 1
     OR v->0->>'identity' <> '01000000-0000-4000-8000-0000000000f1'
     OR v->0->>'room_name' IS NULL THEN
    RAISE EXCEPTION 'O1 ROUGE : la coupure ne rend pas la sortie a faire : %', v;
  END IF;
  -- Idempotente : un second appel ne change rien et rend la meme sortie.
  v := public.couper_visites_observation_echues('wss://cloud.example.test', 'wss://self.example.test');
  IF pg_catalog.jsonb_array_length(v) <> 1 THEN
    RAISE EXCEPTION 'O1 ROUGE : second appel non idempotent : %', v;
  END IF;
  RAISE NOTICE 'O1 OK : (7) visite coupee par le serveur a 120 s (quota_atteint), sortie LiveKit rendue, idempotente';
END $o1$;

-- Seul le service_role l'appelle.
SET LOCAL ROLE authenticated;
DO $o1$
BEGIN
  BEGIN
    PERFORM public.couper_visites_observation_echues('a', 'b');
    RAISE EXCEPTION 'O1 ROUGE : un client appelle la coupure';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'O1 OK : (8) la coupure est fermee aux clients';
END $o1$;
RESET ROLE;

-- (9) Une seconde visite ecourtee compte ; la troisieme est refusee.
SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000f1', 'guardian', '01000000-0000-4000-8000-00000000f001');
SET LOCAL ROLE authenticated;
DO $o1$
DECLARE v jsonb;
BEGIN
  v := public.entrer_observation('01000000-0000-4000-8000-0000005e55e0', 'guardian_observer');
  IF NOT coalesce((v->>'autorise')::boolean, false) THEN
    RAISE EXCEPTION 'O1 ROUGE : seconde visite refusee : %', v;
  END IF;
  PERFORM public.sortir_observation('01000000-0000-4000-8000-0000005e55e0');
  v := public.entrer_observation('01000000-0000-4000-8000-0000005e55e0', 'guardian_observer');
  IF coalesce((v->>'autorise')::boolean, true) OR v->>'motif_refus' <> 'quota_visites_atteint' THEN
    RAISE EXCEPTION 'O1 ROUGE : troisieme visite non refusee : %', v;
  END IF;
  RAISE NOTICE 'O1 OK : (9) visite ecourtee comptee, troisieme visite refusee (quota_visites_atteint)';
END $o1$;
RESET ROLE;

-- (10) La direction regarde sans etre vue, sans quota de tuteur.
SELECT pg_temp.etre('01000000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
DO $o1$
DECLARE v jsonb;
BEGIN
  FOR i IN 1..3 LOOP
    v := public.entrer_observation('01000000-0000-4000-8000-0000005e55e0', 'admin_masked');
    IF NOT coalesce((v->>'autorise')::boolean, false) THEN
      RAISE EXCEPTION 'O1 ROUGE : la direction est refusee a l''entree % : %', i, v;
    END IF;
    PERFORM public.sortir_observation('01000000-0000-4000-8000-0000005e55e0');
  END LOOP;
  v := public.entrer_observation('01000000-0000-4000-8000-0000005e55e0', 'admin_masked');
END $o1$;
RESET ROLE;
DO $o1$
DECLARE v jsonb;
BEGIN
  v := public.autoriser_jeton_video('01000000-0000-4000-8000-0000005e55e0',
         '01000000-0000-4000-8000-0000000000a1', 'wss://cloud.example.test', 'wss://self.example.test');
  IF NOT coalesce((v #>> '{capabilities,hidden}')::boolean, false)
     OR coalesce((v #>> '{capabilities,can_publish}')::boolean, true) THEN
    RAISE EXCEPTION 'O1 ROUGE : la direction en mode discret est visible ou publie : %', v;
  END IF;
  -- La coupure ne touche pas la visite de la direction.
  PERFORM public.couper_visites_observation_echues('wss://cloud.example.test', 'wss://self.example.test');
  IF NOT EXISTS (SELECT 1 FROM public.guardian_session_visit
                  WHERE observateur_profile_id = '01000000-0000-4000-8000-0000000000a1'
                    AND left_at IS NULL) THEN
    RAISE EXCEPTION 'O1 ROUGE : la coupure a clos la visite de la direction';
  END IF;
  RAISE NOTICE 'O1 OK : (10) la direction regarde invisible, sans quota, et n''est pas coupee';
END $o1$;

ROLLBACK;
