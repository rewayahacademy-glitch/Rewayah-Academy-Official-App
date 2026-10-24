-- D6 et D8 (24/10/2026) : le jeton video de l'eleve demande par son tuteur,
-- et la sortie de l'enseignant par quitter_salle.
-- Migration 20261024170000_jeton_eleve_par_tuteur.sql.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque
-- controle reussi ecrit une ligne "D6 OK" ou "D8 OK" ; un echec leve
-- 'D6 ROUGE : ...' ou 'D8 ROUGE : ...' (ON_ERROR_STOP).
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('d6000000-0000-4000-8000-000000000001', 'd6-enseignant@example.test'),
  ('d6000000-0000-4000-8000-000000000002', 'd6-tuteur@example.test'),
  ('d6000000-0000-4000-8000-000000000003', 'd6-enfant@example.test'),
  ('d6000000-0000-4000-8000-000000000004', 'd6-autre-tuteur@example.test'),
  ('d6000000-0000-4000-8000-000000000005', 'd6-autre-enfant@example.test'),
  ('d6000000-0000-4000-8000-000000000006', 'd6-frere@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('d6f00000-0000-4000-8000-000000000001', 'Europe/Paris'),
  ('d6f00000-0000-4000-8000-000000000002', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('d6000000-0000-4000-8000-000000000001', 'D6TEACHER0000001', 'teacher', NULL,
   'Fixture', 'Enseignant', 'provisional_active', 'male'),
  ('d6000000-0000-4000-8000-000000000002', 'D6GUARDIAN000002', 'guardian',
   'd6f00000-0000-4000-8000-000000000001', 'Fixture', 'Tuteur', 'active', 'male'),
  ('d6000000-0000-4000-8000-000000000003', 'D6STUDENT0000003', 'student',
   'd6f00000-0000-4000-8000-000000000001', 'Fixture', 'Enfant', 'active', 'male'),
  ('d6000000-0000-4000-8000-000000000004', 'D6GUARDIAN000004', 'guardian',
   'd6f00000-0000-4000-8000-000000000002', 'Fixture', 'Autre', 'active', 'male'),
  ('d6000000-0000-4000-8000-000000000005', 'D6STUDENT0000005', 'student',
   'd6f00000-0000-4000-8000-000000000002', 'Fixture', 'AutreEnfant', 'active', 'male'),
  ('d6000000-0000-4000-8000-000000000006', 'D6STUDENT0000006', 'student',
   'd6f00000-0000-4000-8000-000000000001', 'Fixture', 'Frere', 'active', 'male');

-- Une seance dont la porte est ouverte : l'enfant et l'autre enfant y sont
-- eleves ; le frere n'y est pas ; l'enseignant n'est pas dans
-- session_participants (comme materialiser_seances_groupe).
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, join_opens_at, status)
VALUES ('d6a00000-0000-4000-8000-000000000001', 'd6000000-0000-4000-8000-000000000001',
        pg_catalog.now() + interval '5 minutes', pg_catalog.now() + interval '65 minutes',
        pg_catalog.now() - interval '1 minute', 'planned');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
  ('d6a00000-0000-4000-8000-000000000001', 'd6000000-0000-4000-8000-000000000003', 'student'),
  ('d6a00000-0000-4000-8000-000000000001', 'd6000000-0000-4000-8000-000000000005', 'student');

-- Droits : reservee au serveur.
DO $droits$
DECLARE
  v regprocedure := 'public.autoriser_jeton_video_eleve(uuid,uuid,uuid,text,text)'::regprocedure;
BEGIN
  IF pg_catalog.has_function_privilege('anon', v, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', v, 'EXECUTE') THEN
    RAISE EXCEPTION 'D6 ROUGE : droits de autoriser_jeton_video_eleve';
  END IF;
  RAISE NOTICE 'D6 OK : reservee a service_role';
END
$droits$;

-- Le tuteur obtient le jeton de son enfant : role eleve, identite de l'eleve,
-- grant au nom de l'eleve, journal avec demande_par.
DO $accepte$
DECLARE
  v jsonb;
BEGIN
  v := public.autoriser_jeton_video_eleve(
    'd6a00000-0000-4000-8000-000000000001',
    'd6000000-0000-4000-8000-000000000002',
    'd6000000-0000-4000-8000-000000000003',
    'wss://cloud.test', 'wss://auto.test');
  IF v->>'role' <> 'student' OR v->>'identity' <> 'd6000000-0000-4000-8000-000000000003' THEN
    RAISE EXCEPTION 'D6 ROUGE : jeton inattendu %', v;
  END IF;
  IF (v->'capabilities'->>'can_publish_data')::boolean THEN
    RAISE EXCEPTION 'D6 ROUGE : l''eleve recoit le canal de donnees';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.video_token_grants g
                  WHERE g.session_id = 'd6a00000-0000-4000-8000-000000000001'
                    AND g.profile_id = 'd6000000-0000-4000-8000-000000000003'
                    AND g.role = 'student') THEN
    RAISE EXCEPTION 'D6 ROUGE : aucun grant au nom de l''eleve';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs a
                  WHERE a.action = 'video_token_par_tuteur'
                    AND a.payload->>'demande_par' = 'd6000000-0000-4000-8000-000000000002'
                    AND a.payload->>'profile_id' = 'd6000000-0000-4000-8000-000000000003') THEN
    RAISE EXCEPTION 'D6 ROUGE : demande_par absent du journal';
  END IF;
  RAISE NOTICE 'D6 OK : jeton de l''eleve, role eleve, demande_par journalise';
END
$accepte$;

-- Les refus, avec leur phrase, et rien n'est ecrit.
CREATE TEMP TABLE d6_refus (cas text, tuteur uuid, eleve uuid, motif text) ON COMMIT DROP;
INSERT INTO d6_refus VALUES
  ('enfant d''un autre foyer', 'd6000000-0000-4000-8000-000000000002',
   'd6000000-0000-4000-8000-000000000005', 'eleve hors du foyer'),
  ('frere non inscrit a la seance', 'd6000000-0000-4000-8000-000000000002',
   'd6000000-0000-4000-8000-000000000006', 'non inscrit a cette seance'),
  ('enseignant demande comme eleve', 'd6000000-0000-4000-8000-000000000002',
   'd6000000-0000-4000-8000-000000000001', 'eleve hors du foyer'),
  ('eleve demandeur', 'd6000000-0000-4000-8000-000000000003',
   'd6000000-0000-4000-8000-000000000003', 'tuteur non valide'),
  ('enseignant demandeur', 'd6000000-0000-4000-8000-000000000001',
   'd6000000-0000-4000-8000-000000000003', 'tuteur non valide');

DO $refus$
DECLARE
  r record;
  v_grants bigint;
  v_n integer := 0;
BEGIN
  FOR r IN SELECT * FROM d6_refus LOOP
    SELECT pg_catalog.count(*) INTO v_grants FROM public.video_token_grants;
    BEGIN
      PERFORM public.autoriser_jeton_video_eleve(
        'd6a00000-0000-4000-8000-000000000001', r.tuteur, r.eleve,
        'wss://cloud.test', 'wss://auto.test');
      RAISE EXCEPTION 'D6 ROUGE : % accepte', r.cas;
    EXCEPTION WHEN insufficient_privilege THEN
      IF SQLERRM <> r.motif THEN
        RAISE EXCEPTION 'D6 ROUGE : % : « % », attendu « % »', r.cas, SQLERRM, r.motif;
      END IF;
    END;
    IF (SELECT pg_catalog.count(*) FROM public.video_token_grants) <> v_grants THEN
      RAISE EXCEPTION 'D6 ROUGE : % : un grant reste apres le refus', r.cas;
    END IF;
    v_n := v_n + 1;
    RAISE NOTICE 'D6 OK : % refuse (« % »)', r.cas, r.motif;
  END LOOP;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'D6 ROUGE : % cas joues, 5 attendus', v_n;
  END IF;
END
$refus$;

-- Un tuteur dont le compte est suspendu ne demande rien.
UPDATE public.profiles SET account_status = 'disabled'
 WHERE id = 'd6000000-0000-4000-8000-000000000002';
DO $suspendu$
BEGIN
  BEGIN
    PERFORM public.autoriser_jeton_video_eleve(
      'd6a00000-0000-4000-8000-000000000001',
      'd6000000-0000-4000-8000-000000000002',
      'd6000000-0000-4000-8000-000000000003',
      'wss://cloud.test', 'wss://auto.test');
    RAISE EXCEPTION 'D6 ROUGE : tuteur suspendu accepte';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'tuteur non valide' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'D6 OK : tuteur suspendu refuse';
END
$suspendu$;

-- D8 : l'enseignant de la seance sort par quitter_salle ; un tiers non.
SELECT set_config('request.jwt.claim.sub', 'd6000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'd6000000-0000-4000-8000-000000000001', true);
SET LOCAL ROLE authenticated;
SELECT public.quitter_salle('d6a00000-0000-4000-8000-000000000001');
RESET ROLE;
DO $d8$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.session_events e
                  WHERE e.session_id = 'd6a00000-0000-4000-8000-000000000001'
                    AND e.profile_id = 'd6000000-0000-4000-8000-000000000001'
                    AND e.event_type = 'left' AND e.source = 'user_action') THEN
    RAISE EXCEPTION 'D8 ROUGE : la sortie de l''enseignant n''est pas ecrite';
  END IF;
  RAISE NOTICE 'D8 OK : l''enseignant de la seance sort par quitter_salle';
END
$d8$;

SELECT set_config('request.jwt.claim.sub', 'd6000000-0000-4000-8000-000000000004', true);
SELECT set_config('test.uid', 'd6000000-0000-4000-8000-000000000004', true);
SET LOCAL ROLE authenticated;
DO $d8_tiers$
BEGIN
  BEGIN
    PERFORM public.quitter_salle('d6a00000-0000-4000-8000-000000000001');
    RAISE EXCEPTION 'D8 ROUGE : un tiers sort d''une seance qui n''est pas la sienne';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'non inscrit a cette seance' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'D8 OK : un tiers est refuse';
END
$d8_tiers$;
RESET ROLE;

ROLLBACK;
