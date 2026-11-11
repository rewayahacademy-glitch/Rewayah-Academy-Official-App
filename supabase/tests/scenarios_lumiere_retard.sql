-- LUMIERE-RETARD (11/11/2026) : public.retard_en_direct(uuid) rend les eleves lisibles par l'appelant
-- qui ne sont pas encore entres dans une seance EN DIRECT, au-dela de presence.seuil_retard_secondes.
-- Migration 20261122700000_lumiere_retard_eleve.sql. ROUGE sans la migration (la fonction n'existe pas) ;
-- VERT avec. Base NEUVE ; tout est annule a la fin.
--   s1 (en direct, debut -10 min) : e1 jamais connecte ; e2 entre a +1 min ; e3 entre a +7 min (en retard,
--      mais ENTRE) ; e4 jamais connecte mais excuse par la direction ; e5 jamais connecte, autre foyer.
--   s2 (en direct, debut -2 min, avant le seuil) : e6 jamais connecte.
--   s3 (planifiee, debut -10 min) ; s4 (terminee) : e1 jamais connecte.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'LUMIERE-RETARD ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('d1700000-0000-4000-8000-0000000000' || p)::uuid $$;
-- Les eleves que la fonction rend a cet appelant pour cette seance, en texte trie.
CREATE FUNCTION pg_temp.lues(p_id uuid, p_role text, p_foyer uuid, p_seance text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT coalesce(string_agg(r.student_id::text, ',' ORDER BY r.student_id), '')
    INTO v FROM public.retard_en_direct(pg_temp.u(p_seance)) r;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.lues(uuid, text, uuid, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : direction a1 ; enseignants b1 (titulaire) et b2 (autre) ; tuteurs d1 (foyer f1), d2 (foyer f2) ;
-- eleves e1 a e4 (foyer f1), e5 (foyer f2).
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'lr-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','b3','d1','d2','e1','e2','e3','e4','e5','e6','e7','e8']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris'), (pg_temp.u('f2'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'LR', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','LR-ADM-01','admin',NULL,'Direction'),
   ('b1','LR-ENS-01','teacher',NULL,'Maryam'),
   ('b2','LR-ENS-02','teacher',NULL,'Khadija'),
   ('b3','LR-ENS-03','teacher',NULL,'Fanta'),
   ('d1','LR-TUT-01','guardian','f1','Amina'),
   ('d2','LR-TUT-02','guardian','f2','Binta'),
   ('e1','LR-ELV-01','student','f1','Yasmine'),
   ('e2','LR-ELV-02','student','f1','Nour'),
   ('e3','LR-ELV-03','student','f1','Safa'),
   ('e4','LR-ELV-04','student','f1','Hawa'),
   ('e5','LR-ELV-05','student','f2','Aicha'),
   ('e6','LR-ELV-06','student','f1','Mariam'),
   ('e7','LR-ELV-07','student','f1','Fatou'),
   ('e8','LR-ELV-08','student','f1','Oumou')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour LR', 1, 9, 'Europe/Paris');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.id), pg_temp.u(x.ens), now() - x.debut, now() - x.debut + interval '60 minutes', 'planned', pg_temp.u('c1')
  FROM (VALUES ('51', 'b1', interval '10 minutes'), ('52', 'b2', interval '2 minutes'),
               ('53', 'b3', interval '10 minutes'), ('54', 'b1', interval '90 minutes')) AS x(id, ens, debut);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(s), pg_temp.u(e), 'student'::public.participant_role
  FROM (VALUES ('51','e1'),('51','e2'),('51','e3'),('51','e4'),('51','e5'),
               ('52','e6'),('53','e7'),('54','e8')) AS x(s, e);
-- e2 entre a +1 min, e3 entre a +7 min (apres le seuil de 300 s : « en_retard », mais present).
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u('51'), pg_temp.u(x.e), 'joined'::public.session_event_type,
       s.started_at + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('e2', 1), ('e3', 7)) AS x(e, m)
  JOIN public.sessions s ON s.id = pg_temp.u('51');
-- Statuts : s1 et s2 en direct, s4 terminee, s3 reste planifiee.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id IN (pg_temp.u('51'), pg_temp.u('52'), pg_temp.u('54'));
UPDATE public.sessions SET status = 'in_progress' WHERE id IN (pg_temp.u('51'), pg_temp.u('52'), pg_temp.u('54'));
UPDATE public.sessions SET status = 'ended' WHERE id = pg_temp.u('54');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
-- e4 : la direction a deja juge sa presence (excusee).
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par)
VALUES (pg_temp.u('51'), pg_temp.u('e4'), 'excusee', 'test', pg_temp.u('a1'));

-- ------------------------------------------------------------------
-- 1. Le seuil et l'etat
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('a1'), 'admin', NULL, '51') = pg_temp.u('e1')::text || ',' || pg_temp.u('e5')::text,
  'direction, s1 : e1 et e5 (jamais entres, seuil depasse) ; e2 et e3 sont entres, e4 est excuse');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('a1'), 'admin', NULL, '52') = '',
  'pas encore au seuil (s2, debut il y a 2 min) : aucune ligne');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('a1'), 'admin', NULL, '53') = '',
  's3 planifiee : aucune ligne');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('a1'), 'admin', NULL, '54') = '',
  's4 terminee : aucune ligne');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('a1'), 'admin', NULL, '99') = '',
  'seance inconnue : aucune ligne');

-- Le seuil est un reglage, le meme que celui d'etat_presence : a 900 s, e1 n'est plus en retard a +10 min.
UPDATE public.app_config SET value = '900'::jsonb WHERE key = 'presence.seuil_retard_secondes';
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('a1'), 'admin', NULL, '51') = '',
  'seuil a 900 s : plus personne a +10 min');
UPDATE public.app_config SET value = '300'::jsonb WHERE key = 'presence.seuil_retard_secondes';

-- ------------------------------------------------------------------
-- 2. Qui lit quoi
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'), '51') = pg_temp.u('e1')::text,
  'tuteur du foyer f1 : e1 seulement (jamais e5, d''un autre foyer)');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('d2'), 'guardian', pg_temp.u('f2'), '51') = pg_temp.u('e5')::text,
  'tuteur du foyer f2 : e5 seulement');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51') = pg_temp.u('e1')::text,
  'eleve e1 : sa propre ligne');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('e2'), 'student', pg_temp.u('f1'), '51') = '',
  'eleve e2 (entre) : aucune ligne, et jamais celle d''un autre');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('b1'), 'teacher', NULL, '51') = pg_temp.u('e1')::text || ',' || pg_temp.u('e5')::text,
  'enseignant titulaire : e1 et e5');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('b2'), 'teacher', NULL, '51') = '',
  'autre enseignant : aucune ligne');
-- Un tuteur sans enfant dans la seance (autre foyer) : refuse, c'est-a-dire aucune ligne, jamais d'erreur.
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f3'), 'Europe/Paris');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('d2'), 'guardian', pg_temp.u('f3'), '51') = '',
  'tuteur dont le foyer ne correspond a aucun eleve : refuse (aucune ligne)');

-- ------------------------------------------------------------------
-- 3. Portes et droits
-- ------------------------------------------------------------------
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('d1');
SELECT pg_temp.vrai(pg_temp.lues(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'), '51') = '',
  'compte desactive : aucune ligne');
UPDATE public.profiles SET account_status = 'active' WHERE id = pg_temp.u('d1');

SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('anon', 'public.retard_en_direct(uuid)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.retard_en_direct(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.retard_en_direct(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.retard_en_direct(uuid)', 'EXECUTE'),
  'EXECUTE : authenticated seul');
SELECT pg_temp.vrai((SELECT p.provolatile = 's' AND p.prosecdef AND p.proconfig = ARRAY['search_path=""']
                       FROM pg_catalog.pg_proc p WHERE p.oid = 'public.retard_en_direct(uuid)'::regprocedure),
  'STABLE, SECURITY DEFINER, search_path vide');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.session_events e WHERE e.session_id = pg_temp.u('51') AND e.profile_id = pg_temp.u('e1')),
  'aucune ecriture : e1 n''a toujours aucun evenement');

ROLLBACK;
