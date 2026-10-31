-- PRESENCE-MINUTES (31/10/2026) : la presence de l'eleve au temps reel.
-- Migration 20261102900000. Une seance d'enfants de 60 minutes, tenue en
-- entier, cinq eleves du meme foyer :
--   e1 : 0-20 puis 25-45 (reconnexion)            -> 40 min, presente ;
--   e2 : joined 5, joined 10 (doublon), left 20   -> 15 min, partielle ;
--   e3 : arrive 5 min avant, sort a 2             ->  2 min, partielle ;
--   e4 : jamais connecte                          ->  0 min, absente ;
--   e5 : entered_at 0 sans sortie + joined 30     -> 60 min, presente.
--   1. minutes, arrivee, sortie, etats (reconnexion, chevauchement, bornes) ;
--   2. le seuil est un reglage : a 80 %, e1 passe en presence partielle ;
--   3. paie : presents et partiels payes (4), l'absent non ; une absence
--      excusee par la direction sort de la paie ;
--   4. lecture : le tuteur voit son foyer, l'eleve sa ligne, anon rien ;
--   5. le calcul reste au serveur.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('b7000000-0000-4000-8000-0000000000' || p)::uuid $$;
-- Minutes et etat d'un eleve a la seance s1, lus par l'aide privee.
CREATE FUNCTION pg_temp.t(p_eleve text) RETURNS TABLE (arrivee timestamptz, sortie timestamptz,
  minutes integer, minutes_prevues integer, statut text) LANGUAGE sql AS
  $$ SELECT * FROM private.presence_temps_reel(pg_temp.u('51'), pg_temp.u(p_eleve)) $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.mois(),
  pg_temp.u(text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pm-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','d1','e1','e2','e3','e4','e5']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role IN ('student', 'guardian') THEN pg_temp.u('f1') END,
       x.prenom, 'PM', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PM-ADM-01','admin','Direction'),
   ('b1','PM-ENS-01','teacher','Maryam'),
   ('d1','PM-TUT-01','guardian','Amina'),
   ('e1','PM-ELV-01','student','Yasmine'),
   ('e2','PM-ELV-02','student','Nour'),
   ('e3','PM-ELV-03','student','Safa'),
   ('e4','PM-ELV-04','student','Hawa'),
   ('e5','PM-ELV-05','student','Aicha')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour PM', 1, 9, 'Europe/Paris');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('51'), pg_temp.u('b1'),
        pg_temp.mois() + interval '10 days 9 hours',
        pg_temp.mois() + interval '10 days 10 hours', 'planned', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role, entered_at)
SELECT pg_temp.u('51'), pg_temp.u(x), 'student'::public.participant_role,
       CASE WHEN x = 'e5' THEN pg_temp.mois() + interval '10 days 9 hours' END
  FROM unnest(ARRAY['e1','e2','e3','e4','e5']) AS x;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u('51'), pg_temp.u(x.e), x.t::public.session_event_type,
       pg_temp.mois() + interval '10 days 9 hours' + x.m * interval '1 minute', x.src
  FROM (VALUES ('e1','joined',0,'livekit_webhook'), ('e1','left',20,'livekit_webhook'),
               ('e1','joined',25,'livekit_webhook'), ('e1','left',45,'user_action'),
               ('e2','joined',5,'livekit_webhook'), ('e2','joined',10,'livekit_webhook'),
               ('e2','left',20,'livekit_webhook'),
               ('e3','joined',-5,'livekit_webhook'), ('e3','left',2,'user_action'),
               ('e5','joined',30,'livekit_webhook')) AS x(e, t, m, src);

-- Cloture : 60 minutes tenues, puis « ended » qui declenche la paie.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = pg_temp.u('51');
UPDATE public.sessions SET status = 'in_progress' WHERE id = pg_temp.u('51');
UPDATE public.sessions s
   SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE s.id = pg_temp.u('51');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- 1. Minutes, arrivee, sortie, etats
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT minutes = 40 AND minutes_prevues = 60 AND statut = 'presente'
                       AND arrivee = pg_temp.mois() + interval '10 days 9 hours'
                       AND sortie = pg_temp.mois() + interval '10 days 9 hours 45 minutes' FROM pg_temp.t('e1')),
  'reconnexion : 20 + 20 minutes = 40 sur 60, presente, arrivee 9:00, sortie 9:45');
SELECT pg_temp.vrai((SELECT minutes = 15 AND statut = 'partielle' FROM pg_temp.t('e2')),
  'chevauchement : deux joined pour un left comptent une fois (15 min), presence partielle');
SELECT pg_temp.vrai((SELECT minutes = 2 AND statut = 'partielle'
                       AND arrivee = pg_temp.mois() + interval '10 days 9 hours' FROM pg_temp.t('e3')),
  'arrivee avant l''heure : bornee au debut prevu (2 min comptees), presence partielle');
SELECT pg_temp.vrai((SELECT minutes = 0 AND statut = 'absente' AND arrivee IS NULL AND sortie IS NULL
                       FROM pg_temp.t('e4')),
  'aucune connexion : absente, ni arrivee ni sortie');
SELECT pg_temp.vrai((SELECT minutes = 60 AND statut = 'presente'
                       AND sortie = pg_temp.mois() + interval '10 days 10 hours' FROM pg_temp.t('e5')),
  'entered_at sans sortie + joined sans left : ferme a la fin de la seance, compte une fois (60 min)');

-- ------------------------------------------------------------------
-- 2. Le seuil est un reglage app_config
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT (value #>> '{}')::int = 50 FROM public.app_config
                      WHERE key = 'presence.seuil_present_pourcentage'),
  'reglage presence.seuil_present_pourcentage = 50');
UPDATE public.app_config SET value = '80'::jsonb WHERE key = 'presence.seuil_present_pourcentage';
SELECT pg_temp.vrai((SELECT statut = 'partielle' FROM pg_temp.t('e1'))
  AND (SELECT statut = 'presente' FROM pg_temp.t('e5')),
  'seuil a 80 % : 40/60 devient partielle, 60/60 reste presente');
UPDATE public.app_config SET value = '50'::jsonb WHERE key = 'presence.seuil_present_pourcentage';

-- ------------------------------------------------------------------
-- 3. Paie : presents et partiels payes, absent non
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.pai_eleves_presents(pg_temp.u('51')) = 4,
  'paie : 2 presentes + 2 partielles = 4 eleves payes, l''absente non');
SELECT pg_temp.vrai((SELECT m.montant_minor FROM public.tresorerie_mouvements m
                      WHERE m.source_type = 'prestation' AND m.source_id = pg_temp.u('51')::text
                        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree')
                    = 4 * (private.fac_politique_au(pg_temp.mois())).taux_eleve_heure_enfant_mineur,
  'paie ecrite a la cloture : taux enfant x 4 eleves x 1 h');
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par)
VALUES (pg_temp.u('51'), pg_temp.u('e3'), 'excusee', 'absence prevenue', pg_temp.u('a1'));
SELECT pg_temp.vrai((SELECT statut = 'excusee' FROM pg_temp.t('e3'))
  AND private.pai_eleves_presents(pg_temp.u('51')) = 3,
  'absence excusee par la direction : hors paie');
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par)
VALUES (pg_temp.u('51'), pg_temp.u('e4'), 'corrigee_manuel', 'camera en panne', pg_temp.u('a1'));
SELECT pg_temp.vrai((SELECT statut = 'presente' FROM pg_temp.t('e4'))
  AND private.pai_eleves_presents(pg_temp.u('51')) = 4,
  'presence corrigee par la direction : presente et payee');

-- ------------------------------------------------------------------
-- 4. Lecture par la vue
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.presence_seance_v WHERE session_id = pg_temp.u('51')) = 5,
  'tuteur : les cinq eleves de son foyer');
SELECT pg_temp.vrai((SELECT minutes_connectees = 40 AND minutes_prevues = 60 AND presence_temps = 'presente'
                       AND sortie_le = pg_temp.mois() + interval '10 days 9 hours 45 minutes'
                       AND entre_le = pg_temp.mois() + interval '10 days 9 hours'
                       FROM public.presence_seance_v
                      WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e1')),
  'tuteur : arrivee, sortie, 40 min sur 60, presente');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.presence_seance_v WHERE session_id = pg_temp.u('51')) = 1
  AND (SELECT presence_temps FROM public.presence_seance_v WHERE profile_id = pg_temp.u('e2')
          AND session_id = pg_temp.u('51')) = 'partielle',
  'eleve : sa seule ligne, presence partielle');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.presence_seance_v
                      WHERE session_id = pg_temp.u('51') AND minutes_connectees IS NOT NULL) = 5,
  'direction : les cinq lignes avec leurs minutes');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. Le calcul reste au serveur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.pai_eleves_presents(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.presence_temps_seance(uuid,uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.presence_temps_seance(uuid,uuid)', 'EXECUTE'),
  'droits : aides privees fermees, lecture gardee ouverte au seul authenticated');

\o
ROLLBACK;
