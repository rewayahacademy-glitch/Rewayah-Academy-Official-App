-- PAIE-MINUTES-RECONNEXION (13/11/2026, migration 20261123940000) :
-- private.presence_temps_reel ne perd plus le temps d'une reconnexion dont le
-- left (ancienne connexion) et le joined (nouvelle) portent le meme horodatage.
--
-- s1, seance de 60 minutes close, une eleve : la suite REELLE de l'enseignant
--     de la seance du 12/11/2026 (relevee en production, lecture seule), en
--     secondes depuis le debut :
--       joined 141, left 174, joined 174, joined 184, left 184, left 436,
--       joined 636, left 2617, joined 2617, left 2628, joined 2628, left 2689
--     -> 141..436 (295 s) + 636..2689 (2053 s) = 2348 s = 39 minutes.
--     L'ancienne definition rendait 33 minutes.
-- s2, seance de 60 minutes close, huit eleves :
--   e2 : reconnexion simple a la meme seconde            -> 30 min ;
--   e3 : deux appareils qui se chevauchent                -> 20 min (union) ;
--   e4 : joined sans left                                 -> 20 min, ferme a la fin ;
--   e5 : left orphelin avant le joined                    -> 15 min ;
--   e6 : la suite de e2 inseree a l'envers                -> 30 min ;
--   e7 : joined et left a la meme seconde, rien d'ouvert  ->  0 min, absente ;
--   e8 : deux joined pour un seul left (regle conservee)  -> 15 min ;
--   e9 : reconnexion a la meme seconde, plus aucun left   -> 60 min.
-- s3, seance en cours : reconnexion a la meme seconde, toujours connectee
--     -> toujours comptee comme connectee, pas d'heure de sortie.
--   1. la suite reelle : 39 minutes, arrivee, sortie ;
--   2. les huit cas de s2 ;
--   3. seance en cours ;
--   4. paie : la duree tenue de l'enseignante est 39 minutes, et la paie ecrite
--      a la cloture les utilise ; aucune regle de prix ne change ;
--   5. droits inchanges.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'ROUGE : ...'.
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
  $$ SELECT ('b9000000-0000-4000-8000-0000000000' || p)::uuid $$;
-- Debut d'une seance des fixtures.
CREATE FUNCTION pg_temp.d(p_seance text) RETURNS timestamptz LANGUAGE sql AS
  $$ SELECT s.started_at FROM public.sessions s WHERE s.id = pg_temp.u(p_seance) $$;
-- Minutes et etat d'un profil a une seance, lus par l'aide privee.
CREATE FUNCTION pg_temp.t(p_seance text, p_profil text) RETURNS TABLE (arrivee timestamptz, sortie timestamptz,
  minutes integer, minutes_prevues integer, statut text) LANGUAGE sql AS
  $$ SELECT * FROM private.presence_temps_reel(pg_temp.u(p_seance), pg_temp.u(p_profil)) $$;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pmr-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','d1','e1','e2','e3','e4','e5','e6','e7','e8','e9']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role IN ('student', 'guardian') THEN pg_temp.u('f1') END,
       x.prenom, 'PMR', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PMR-ADM-01','admin','Direction'),
   ('b1','PMR-ENS-01','teacher','Maryam'),
   ('d1','PMR-TUT-01','guardian','Amina'),
   ('e1','PMR-ELV-01','student','Yasmine'),
   ('e2','PMR-ELV-02','student','Nour'),
   ('e3','PMR-ELV-03','student','Safa'),
   ('e4','PMR-ELV-04','student','Hawa'),
   ('e5','PMR-ELV-05','student','Aicha'),
   ('e6','PMR-ELV-06','student','Salma'),
   ('e7','PMR-ELV-07','student','Lina'),
   ('e8','PMR-ELV-08','student','Rima'),
   ('e9','PMR-ELV-09','student','Dina')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7','e8','e9']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour PMR', 1, 17, 'Europe/Paris');
-- s1 et s2 : passees, dans le mois. s3 : commencee il y a 30 minutes.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('51'), pg_temp.u('b1'),
        pg_temp.mois() + interval '10 days 17 hours',
        pg_temp.mois() + interval '10 days 18 hours', 'planned', pg_temp.u('c1')),
       (pg_temp.u('52'), pg_temp.u('b1'),
        pg_temp.mois() + interval '11 days 17 hours',
        pg_temp.mois() + interval '11 days 18 hours', 'planned', pg_temp.u('c1')),
       (pg_temp.u('53'), pg_temp.u('b1'),
        date_trunc('second', now()) - interval '30 minutes',
        date_trunc('second', now()) + interval '30 minutes', 'planned', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
VALUES (pg_temp.u('51'), pg_temp.u('e1'), 'student'), (pg_temp.u('53'), pg_temp.u('e1'), 'student');
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u('52'), pg_temp.u(x), 'student'::public.participant_role
  FROM unnest(ARRAY['e2','e3','e4','e5','e6','e7','e8','e9']) AS x;

-- L'ordre des lignes ci-dessous est l'ordre d'insertion (donc de id). Les
-- horodatages sont a la seconde, comme ceux du webhook video.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u(x.s), pg_temp.u(x.p), x.t::public.session_event_type,
       pg_temp.d(x.s) + x.sec * interval '1 second', 'livekit_webhook'
  FROM (VALUES
    -- s1, l'enseignante : la suite reelle du 12/11/2026.
    (1,'51','b1','joined',141), (2,'51','b1','left',174), (3,'51','b1','joined',174),
    (4,'51','b1','joined',184), (5,'51','b1','left',184), (6,'51','b1','left',436),
    (7,'51','b1','joined',636), (8,'51','b1','left',2617), (9,'51','b1','joined',2617),
    (10,'51','b1','left',2628), (11,'51','b1','joined',2628), (12,'51','b1','left',2689),
    -- s1, l'eleve e1 : toute la seance.
    (13,'51','e1','joined',0), (14,'51','e1','left',3600),
    -- s2, e2 : reconnexion simple, left et joined a la meme seconde.
    (20,'52','e2','joined',0), (21,'52','e2','left',600), (22,'52','e2','joined',600), (23,'52','e2','left',1800),
    -- s2, e3 : deux appareils, 0..600 et 300..1200.
    (30,'52','e3','joined',0), (31,'52','e3','joined',300), (32,'52','e3','left',600), (33,'52','e3','left',1200),
    -- s2, e4 : joined sans left.
    (40,'52','e4','joined',2400),
    -- s2, e5 : left orphelin, puis 600..1500.
    (50,'52','e5','left',300), (51,'52','e5','joined',600), (52,'52','e5','left',1500),
    -- s2, e6 : la suite de e2, inseree a l'envers.
    (60,'52','e6','left',1800), (61,'52','e6','joined',600), (62,'52','e6','left',600), (63,'52','e6','joined',0),
    -- s2, e7 : joined et left a la meme seconde, rien d'ouvert avant.
    (70,'52','e7','joined',1200), (71,'52','e7','left',1200),
    -- s2, e8 : deux joined pour un seul left.
    (80,'52','e8','joined',300), (81,'52','e8','joined',600), (82,'52','e8','left',1200),
    -- s2, e9 : reconnexion a la meme seconde, puis plus aucun left.
    (90,'52','e9','joined',0), (91,'52','e9','left',600), (92,'52','e9','joined',600),
    -- s3 (en cours), e1 : entree a 60 s, reconnexion a 600 s, toujours la.
    (100,'53','e1','joined',60), (101,'53','e1','left',600), (102,'53','e1','joined',600)
  ) AS x(ordre, s, p, t, sec)
 ORDER BY x.ordre;

-- Cloture de s1 et s2 : « ended » declenche la paie. s3 reste en cours.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id IN (pg_temp.u('51'), pg_temp.u('52'), pg_temp.u('53'));
UPDATE public.sessions SET status = 'in_progress' WHERE id IN (pg_temp.u('51'), pg_temp.u('52'), pg_temp.u('53'));
UPDATE public.sessions s
   SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE s.id IN (pg_temp.u('51'), pg_temp.u('52'));
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- 1. La suite reelle du 12/11/2026
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT minutes = 39 AND minutes_prevues = 60 AND statut = 'presente'
                       AND arrivee = pg_temp.d('51') + interval '141 seconds'
                       AND sortie = pg_temp.d('51') + interval '2689 seconds' FROM pg_temp.t('51', 'b1')),
  'suite reelle : 295 s + 2053 s = 39 minutes (33 avant), arrivee et sortie exactes');

-- ------------------------------------------------------------------
-- 2. Les cas un par un
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT minutes = 30 AND statut = 'presente' AND arrivee = pg_temp.d('52')
                       AND sortie = pg_temp.d('52') + interval '1800 seconds' FROM pg_temp.t('52', 'e2')),
  'reconnexion simple a la meme seconde : 30 minutes sans trou (10 avant)');
SELECT pg_temp.vrai((SELECT minutes = 20 AND statut = 'partielle' AND arrivee = pg_temp.d('52')
                       AND sortie = pg_temp.d('52') + interval '1200 seconds' FROM pg_temp.t('52', 'e3')),
  'deux appareils qui se chevauchent : union 0..1200 s = 20 minutes (10 avant)');
SELECT pg_temp.vrai((SELECT minutes = 20 AND statut = 'partielle'
                       AND arrivee = pg_temp.d('52') + interval '2400 seconds'
                       AND sortie = pg_temp.d('52') + interval '1 hour' FROM pg_temp.t('52', 'e4')),
  'joined sans left : compte jusqu''a la fin de la seance (20 minutes)');
SELECT pg_temp.vrai((SELECT minutes = 15 AND statut = 'partielle'
                       AND arrivee = pg_temp.d('52') + interval '600 seconds'
                       AND sortie = pg_temp.d('52') + interval '1500 seconds' FROM pg_temp.t('52', 'e5')),
  'left orphelin : ignore, 600..1500 s = 15 minutes');
SELECT pg_temp.vrai((SELECT minutes = 30 AND statut = 'presente' AND arrivee = pg_temp.d('52')
                       AND sortie = pg_temp.d('52') + interval '1800 seconds' FROM pg_temp.t('52', 'e6')),
  'evenements inseres a l''envers : meme resultat que dans l''ordre (30 minutes)');
SELECT pg_temp.vrai((SELECT minutes = 0 AND statut = 'absente' AND arrivee IS NULL AND sortie IS NULL
                       FROM pg_temp.t('52', 'e7')),
  'joined et left a la meme seconde, rien d''ouvert : zero minute, absente');
SELECT pg_temp.vrai((SELECT minutes = 15 AND statut = 'partielle'
                       AND sortie = pg_temp.d('52') + interval '1200 seconds' FROM pg_temp.t('52', 'e8')),
  'deux joined pour un seul left : comptes une fois, fermes au left (15 minutes, regle conservee)');
SELECT pg_temp.vrai((SELECT minutes = 60 AND statut = 'presente' AND arrivee = pg_temp.d('52')
                       AND sortie = pg_temp.d('52') + interval '1 hour' FROM pg_temp.t('52', 'e9')),
  'reconnexion a la meme seconde puis plus aucun left : compte jusqu''a la fin (60 minutes, 10 avant)');

-- ------------------------------------------------------------------
-- 3. Seance en cours
-- ------------------------------------------------------------------
-- Seul le plancher est affirme (29 minutes ecoulees depuis l'arrivee ; 9 avant,
-- avec une heure de sortie a tort). Le plafond ne l'est pas : defaut DISTINCT,
-- signale et non corrige ici, la borne de fin d'une seance sans fin financiere
-- vaut la fin prevue plus la grace (least() ignore NULL), donc du temps a venir
-- est compte tant que la seance n'est pas close.
SELECT pg_temp.vrai((SELECT minutes >= 28 AND sortie IS NULL
                       AND arrivee = pg_temp.d('53') + interval '60 seconds' FROM pg_temp.t('53', 'e1')),
  'seance en cours, reconnexion a la meme seconde : toujours comptee comme connectee, pas d''heure de sortie');

-- ------------------------------------------------------------------
-- 4. Paie : la mesure change, aucune regle ne change
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.pai_minutes_enseignant(pg_temp.u('51')) = 39,
  'duree tenue de l''enseignante : 39 minutes');
SELECT pg_temp.vrai(private.pai_eleves_presents(pg_temp.u('51')) = 1,
  'paie : une eleve presente');
SELECT pg_temp.vrai((SELECT m.montant_minor FROM public.tresorerie_mouvements m
                      WHERE m.source_type = 'prestation' AND m.source_id = pg_temp.u('51')::text
                        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree')
                    = round((private.fac_politique_au(pg_temp.mois())).taux_eleve_heure_enfant_mineur * 39 / 60.0),
  'paie ecrite a la cloture : taux enfant x 1 eleve x 39 minutes (sous les 45 dues), regle inchangee');

-- ------------------------------------------------------------------
-- 5. Le calcul reste au serveur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('public', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.presence_temps_seance(uuid,uuid)', 'EXECUTE'),
  'droits : aide privee fermee, lecture gardee ouverte au seul authenticated');

\o
ROLLBACK;
