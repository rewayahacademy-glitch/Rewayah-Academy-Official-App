-- RESEAU-PREUVE (11/11/2026) : le releve de qualite de connexion, garde 180 jours, lu par la direction seule.
-- Migration 20261123000000_releve_qualite_lien.sql. ROUGE sans la migration (les fonctions n'existent pas) ;
-- VERT avec. Base NEUVE ; tout est annule a la fin.
--   s1 (en cours) : enseignant b1 ; eleves e1 et e2 (foyer f1), e5 (foyer f2) ; d2 y observe son enfant.
--   s2 (finie depuis 3 heures) : e1 y avait un jeton.
--   s3 (finie depuis 10 minutes) : la frise de e3, ecrite a la main, pour prouver les durees.
--   s4, s5 : releves anciens, pour la purge.
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
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'RESEAU-PREUVE ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('d1900000-0000-4000-8000-0000000000' || p)::uuid $$;
-- L'appel d'ecriture, tel qu'un client le fait : 'true' (ligne ecrite), 'false' (ignore), 'refus'.
CREATE FUNCTION pg_temp.note(p_id uuid, p_role text, p_foyer uuid, p_seance text, p_profil text,
                             p_etat text, p_micro boolean) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v boolean;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    v := public.noter_qualite_lien(pg_temp.u(p_seance), pg_temp.u(p_profil), p_etat, p_micro);
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN 'refus';
  END;
  RETURN v::text;
END $$;
-- La lecture de la direction, telle qu'un client la fait : le nombre de lignes, ou 'refus'.
CREATE FUNCTION pg_temp.lit(p_id uuid, p_role text, p_foyer uuid, p_seance text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_foyer);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    SELECT pg_catalog.count(*)::integer INTO v FROM public.releve_qualite_seance(pg_temp.u(p_seance));
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN 'refus';
  END;
  RETURN v::text;
END $$;
-- Le temps passe : les lignes d'une seance reculent de p_duree (le declencheur qui interdit toute
-- modification est mis de cote le temps de ce recul, par le test seul).
CREATE FUNCTION pg_temp.vieillir(p_seance text, p_duree interval) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('session_replication_role', 'replica', true);
  UPDATE public.releve_qualite_lien SET releve_le = releve_le - p_duree WHERE session_id = pg_temp.u(p_seance);
  PERFORM pg_catalog.set_config('session_replication_role', 'origin', true);
END $$;
CREATE FUNCTION pg_temp.lignes(p_seance text, p_profil text) RETURNS integer LANGUAGE sql AS
  $$ SELECT pg_catalog.count(*)::integer FROM public.releve_qualite_lien r
      WHERE r.session_id = pg_temp.u(p_seance) AND r.profile_id = pg_temp.u(p_profil) $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text)
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'rq-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','a2','a3','b1','b2','d1','d2','e1','e2','e3','e5']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris'), (pg_temp.u('f2'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'RQ', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','RQ-ADM-01','admin',NULL,'Direction'),
   ('a2','RQ-CTR-01','controller',NULL,'Controle'),
   ('a3','RQ-CPT-01','accountant',NULL,'Comptes'),
   ('b1','RQ-ENS-01','teacher',NULL,'Maryam'),
   ('b2','RQ-ENS-02','teacher',NULL,'Khadija'),
   ('d1','RQ-TUT-01','guardian','f1','Amina'),
   ('d2','RQ-TUT-02','guardian','f2','Binta'),
   ('e1','RQ-ELV-01','student','f1','Yasmine'),
   ('e2','RQ-ELV-02','student','f1','Nour'),
   ('e3','RQ-ELV-03','student','f1','Safa'),
   ('e5','RQ-ELV-05','student','f2','Aicha')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e5']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour RQ', 1, 9, 'Europe/Paris');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.id), pg_temp.u('b1'), now() - x.debut, now() - x.debut + x.duree, 'planned', pg_temp.u('c1')
  FROM (VALUES ('51', interval '10 minutes', interval '60 minutes'),
               ('52', interval '4 hours', interval '60 minutes'),
               ('53', interval '30 minutes', interval '20 minutes'),
               ('54', interval '181 days 2 hours', interval '60 minutes'),
               ('55', interval '181 days 5 hours', interval '60 minutes')) AS x(id, debut, duree);
-- Les jetons que le serveur a delivres (ecrits par autoriser_jeton_video seule, ici a la main).
INSERT INTO public.video_token_grants(session_id, profile_id, role, provider, can_publish, can_publish_video,
                                      can_publish_data, hidden, emis_le, expire_le)
SELECT pg_temp.u(x.s), pg_temp.u(x.p), x.r::public.participant_role, 'cloud'::public.video_provider,
       x.r IN ('teacher', 'student'), x.r IN ('teacher', 'student'), x.r = 'teacher', x.r = 'guardian_observer',
       now() - interval '5 minutes', now() + interval '55 minutes'
  FROM (VALUES ('51','b1','teacher'), ('51','e1','student'), ('51','e2','student'), ('51','e5','student'),
               ('51','d2','guardian_observer'), ('51','a1','admin_masked'), ('52','e1','student'),
               ('53','e3','student')) AS x(s, p, r);

-- ------------------------------------------------------------------
-- 1. Un participant ecrit sa ligne ; le rythme est borne ; un etat inconnu est ignore
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'faible', true) = 'true',
  'l''eleve e1 ecrit sa ligne (faible, micro ouvert)');
SELECT pg_temp.vrai((SELECT r.etat = 'faible' AND r.micro_ouvert AND r.releve_le = now()
                       FROM public.releve_qualite_lien r
                      WHERE r.session_id = pg_temp.u('51') AND r.profile_id = pg_temp.u('e1')),
  'la ligne porte l''etat, le micro et l''heure du serveur');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'perdu', true) = 'false'
  AND pg_temp.lignes('51', 'e1') = 1,
  'une seconde ligne dans les 8 secondes est ignoree (pas de flot)');
SELECT pg_temp.vieillir('51', interval '10 seconds');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'faible', true) = 'false'
  AND pg_temp.lignes('51', 'e1') = 1,
  'le meme etat, meme micro : rien de nouveau, aucune ligne');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'faible', false) = 'true',
  'lien faible et micro qui se ferme : une ligne (ce n''est plus la meme situation)');
SELECT pg_temp.vieillir('51', interval '10 seconds');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'bon', false) = 'true',
  'le lien redevient bon : une ligne');
SELECT pg_temp.vieillir('51', interval '10 seconds');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'bon', true) = 'false'
  AND pg_temp.lignes('51', 'e1') = 3,
  'lien bon et micro qui s''ouvre : aucune ligne (les prises de parole ne sont pas gardees)');
SELECT pg_temp.vrai(
  pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'excellente', true) = 'false'
  AND pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', '', true) = 'false'
  AND pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', NULL, true) = 'false'
  AND pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', 'perdu', NULL) = 'false'
  AND pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e1', '203.0.113.7', true) = 'false'
  AND pg_temp.lignes('51', 'e1') = 3,
  'un etat qui n''est pas prevu (autre mot, vide, absent, une adresse) est ignore : aucune ligne');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('b1'), 'teacher', NULL, '51', 'b1', 'bon', true) = 'true',
  'l''enseignant b1 ecrit sa ligne');

-- ------------------------------------------------------------------
-- 2. Personne n'ecrit la ligne d'un autre
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'b1', 'perdu', true) = 'refus',
  'un eleve ne peut pas ecrire la ligne de l''enseignant');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51', 'e2', 'perdu', true) = 'refus',
  'un eleve ne peut pas ecrire la ligne d''un autre eleve, meme de son foyer');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('b1'), 'teacher', NULL, '51', 'e1', 'perdu', true) = 'refus',
  'l''enseignant ne peut pas ecrire la ligne d''un eleve');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('a1'), 'admin', NULL, '51', 'b1', 'bon', true) = 'refus'
  AND pg_temp.note(pg_temp.u('a1'), 'admin', NULL, '51', 'a1', 'bon', true) = 'refus',
  'la direction n''ecrit ni la ligne d''un autre ni une ligne pour elle (elle observe)');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('b2'), 'teacher', NULL, '51', 'b2', 'bon', true) = 'refus',
  'un enseignant sans jeton pour cette seance n''ecrit rien');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'), '51', 'e2', 'faible', true) = 'true',
  'le tuteur du foyer f1 ecrit la ligne de son enfant e2 (l''enfant suit le cours depuis le compte du tuteur)');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'), '51', 'e5', 'perdu', true) = 'refus',
  'un tuteur ne peut pas ecrire la ligne d''un enfant d''un autre foyer');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'), '51', 'b1', 'perdu', true) = 'refus',
  'un tuteur ne peut pas ecrire la ligne de l''enseignant');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('d2'), 'guardian', pg_temp.u('f2'), '51', 'd2', 'bon', false) = 'refus',
  'un tuteur qui observe n''a pas de ligne (on ne garde que ceux qui parlent)');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '52', 'e1', 'bon', true) = 'refus',
  'hors de la seance (finie depuis 3 heures) : refuse');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '99', 'e1', 'bon', true) = 'refus',
  'seance inconnue : refuse');
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('e5');
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e5'), 'student', pg_temp.u('f2'), '51', 'e5', 'bon', true) = 'refus',
  'compte desactive : refuse');
UPDATE public.profiles SET account_status = 'active' WHERE id = pg_temp.u('e5');
SELECT pg_temp.vrai(pg_temp.lignes('51', 'b1') = 1 AND pg_temp.lignes('51', 'e1') = 3
  AND pg_temp.lignes('51', 'e2') = 1 AND pg_temp.lignes('51', 'e5') = 0
  AND (SELECT pg_catalog.count(*) FROM public.releve_qualite_lien) = 5,
  'aucun refus n''a laisse de ligne');

-- Le plafond : 400 lignes par participant et par seance.
INSERT INTO public.releve_qualite_lien(session_id, profile_id, etat, micro_ouvert, releve_le)
SELECT pg_temp.u('51'), pg_temp.u('e5'), CASE WHEN n % 2 = 0 THEN 'bon' ELSE 'faible' END, false,
       now() - interval '9 minutes' + n * interval '1 second'
  FROM generate_series(1, 400) AS n;
SELECT pg_temp.vrai(pg_temp.note(pg_temp.u('e5'), 'student', pg_temp.u('f2'), '51', 'e5', 'perdu', true) = 'false'
  AND pg_temp.lignes('51', 'e5') = 400,
  'au plafond de 400 lignes, plus rien ne s''ecrit');

-- ------------------------------------------------------------------
-- 3. Qui lit : la direction seule
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.lit(pg_temp.u('b1'), 'teacher', NULL, '51') = 'refus',
  'l''enseignant de la seance ne lit rien');
SELECT pg_temp.vrai(pg_temp.lit(pg_temp.u('d1'), 'guardian', pg_temp.u('f1'), '51') = 'refus',
  'le tuteur ne lit rien');
SELECT pg_temp.vrai(pg_temp.lit(pg_temp.u('e1'), 'student', pg_temp.u('f1'), '51') = 'refus',
  'l''eleve ne lit rien');
SELECT pg_temp.vrai(pg_temp.lit(pg_temp.u('a2'), 'controller', NULL, '51') = 'refus'
  AND pg_temp.lit(pg_temp.u('a3'), 'accountant', NULL, '51') = 'refus',
  'le controleur et la comptabilite ne lisent rien');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.audit_logs l WHERE l.action = 'lecture_releve_qualite'),
  'une lecture refusee n''ecrit rien au journal d''audit');
SELECT pg_temp.vrai(pg_temp.lit(pg_temp.u('a1'), 'admin', NULL, '51') = '405',
  'la direction lit le releve de la seance (405 lignes)');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) = 1 FROM public.audit_logs l
                      WHERE l.action = 'lecture_releve_qualite' AND l.actor = pg_temp.u('a1')
                        AND l.row_id = pg_temp.u('51')::text),
  'la lecture de la direction est ecrite au journal d''audit');
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('a1');
SELECT pg_temp.vrai(pg_temp.lit(pg_temp.u('a1'), 'admin', NULL, '51') = 'refus',
  'un compte de direction desactive ne lit rien');
UPDATE public.profiles SET account_status = 'active' WHERE id = pg_temp.u('a1');

-- Aucun acces direct a la table, pour personne (pas meme la direction).
CREATE FUNCTION pg_temp.table_fermee(p_id uuid, p_role text, p_ordre text) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, NULL);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_ordre;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN true;
  END;
  RETURN false;
END $$;
SELECT pg_temp.vrai(
  pg_temp.table_fermee(pg_temp.u('a1'), 'admin', 'SELECT 1 FROM public.releve_qualite_lien LIMIT 1')
  AND pg_temp.table_fermee(pg_temp.u('b1'), 'teacher', 'SELECT 1 FROM public.releve_qualite_lien LIMIT 1')
  AND pg_temp.table_fermee(pg_temp.u('e1'), 'student',
        'INSERT INTO public.releve_qualite_lien(session_id, profile_id, etat, micro_ouvert) VALUES ('''
        || pg_temp.u('51') || ''', ''' || pg_temp.u('b1') || ''', ''perdu'', true)')
  AND pg_temp.table_fermee(pg_temp.u('b1'), 'teacher', 'UPDATE public.releve_qualite_lien SET etat = ''bon''')
  AND pg_temp.table_fermee(pg_temp.u('b1'), 'teacher', 'SELECT private.purger_releve_qualite()'),
  'la table est fermee : ni lecture, ni ajout, ni modification, ni purge par un client');

-- Une ligne ecrite ne se modifie pas, meme par le serveur.
CREATE FUNCTION pg_temp.modification_refusee() RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    UPDATE public.releve_qualite_lien SET etat = 'bon' WHERE session_id = pg_temp.u('51');
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN true;
  END;
  RETURN false;
END $$;
SELECT pg_temp.vrai(pg_temp.modification_refusee(), 'une ligne ecrite ne se modifie pas (declencheur), meme sans passer par un client');

-- ------------------------------------------------------------------
-- 4. La frise et les durees : s3, eleve e3, debut T = il y a 30 minutes, fin prevue T + 20 min
-- ------------------------------------------------------------------
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u('53'), pg_temp.u('e3'), x.t::public.session_event_type, s.started_at + x.d, 'livekit_webhook'
  FROM (VALUES ('joined', interval '0 seconds'), ('left', interval '12 minutes'), ('joined', interval '13 minutes')) AS x(t, d)
  JOIN public.sessions s ON s.id = pg_temp.u('53');
INSERT INTO public.releve_qualite_lien(session_id, profile_id, etat, micro_ouvert, releve_le)
SELECT pg_temp.u('53'), pg_temp.u('e3'), x.e, x.m, s.started_at + x.d
  FROM (VALUES ('bon', false, interval '5 seconds'), ('faible', true, interval '10 minutes'),
               ('bon', false, interval '14 minutes')) AS x(e, m, d)
  JOIN public.sessions s ON s.id = pg_temp.u('53');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin', NULL);
CREATE TEMP TABLE frise AS SELECT * FROM public.releve_qualite_seance(pg_temp.u('53'));
SELECT pg_temp.vrai((SELECT pg_catalog.string_agg(f.evenement || '/' || f.source || '/' || f.etat_courant || '/' || f.duree_secondes, ' ' ORDER BY f.instant)
                       FROM frise f)
  = 'entree/serveur/inconnu/5 bon/appareil/bon/595 faible/appareil/faible/120 sortie/serveur/absent/60 entree/serveur/faible/60 bon/appareil/bon/360',
  'la frise : entree, bon, faible, sortie, entree, bon, avec l''etat en vigueur et sa duree');
SELECT pg_temp.vrai((SELECT pg_catalog.bool_and(f.role_seance = 'student' AND f.profile_id = pg_temp.u('e3')) FROM frise f),
  'chaque ligne dit de qui il s''agit et son role dans la seance');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.sum(f.duree_secondes) FROM frise f WHERE f.etat_courant = 'bon') = 955
  AND (SELECT pg_catalog.sum(f.duree_secondes) FROM frise f WHERE f.etat_courant = 'faible') = 180
  AND (SELECT pg_catalog.sum(f.duree_secondes) FROM frise f WHERE f.etat_courant = 'absent') = 60
  AND (SELECT pg_catalog.count(*) FROM frise f WHERE f.evenement = 'sortie') = 1
  AND (SELECT pg_catalog.bool_or(f.micro_ouvert) FROM frise f WHERE f.evenement = 'faible'),
  'le resume se calcule de la frise : 955 s bon, 180 s faible, 60 s absent, 1 coupure, micro ouvert pendant le lien faible');

-- ------------------------------------------------------------------
-- 5. La purge : 180 jours, et rien d'autre
-- ------------------------------------------------------------------
-- s4 : tout a plus de 180 jours. s5 : une ligne ancienne et une ligne de 179 jours (le releve reste entier).
INSERT INTO public.releve_qualite_lien(session_id, profile_id, etat, micro_ouvert, releve_le) VALUES
  (pg_temp.u('54'), pg_temp.u('e1'), 'faible', true,  now() - interval '181 days'),
  (pg_temp.u('54'), pg_temp.u('b1'), 'bon',    true,  now() - interval '180 days 1 minute'),
  (pg_temp.u('55'), pg_temp.u('e1'), 'perdu',  false, now() - interval '181 days'),
  (pg_temp.u('55'), pg_temp.u('e1'), 'bon',    false, now() - interval '179 days 23 hours');
SELECT pg_temp.vrai(private.purger_releve_qualite() = 2, 'la purge retire les 2 lignes de la seance de plus de 180 jours');
SELECT pg_temp.vrai(pg_temp.lignes('54', 'e1') = 0 AND pg_temp.lignes('54', 'b1') = 0,
  'le releve de la seance de plus de 180 jours est parti en entier');
SELECT pg_temp.vrai(pg_temp.lignes('55', 'e1') = 2,
  'une seance dont la derniere ligne a 179 jours garde tout son releve');
SELECT pg_temp.vrai(pg_temp.lignes('51', 'e1') = 3 AND pg_temp.lignes('51', 'e5') = 400 AND pg_temp.lignes('53', 'e3') = 3,
  'les releves recents ne sont pas touches');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.session_events e WHERE e.session_id = pg_temp.u('53')) = 3
  AND (SELECT pg_catalog.count(*) FROM public.sessions s WHERE s.id IN (pg_temp.u('54'), pg_temp.u('55'))) = 2,
  'la purge ne touche que le releve : ni les seances ni les entrees et sorties');
SELECT pg_temp.vrai(private.purger_releve_qualite() = 0, 'une seconde purge ne retire rien');

-- ------------------------------------------------------------------
-- 6. Droits et forme
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.noter_qualite_lien(uuid,uuid,text,boolean)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.releve_qualite_seance(uuid)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.releve_qualite_seance(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.releve_qualite_seance(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.releve_qualite_seance(uuid)', 'EXECUTE'),
  'EXECUTE des deux fonctions : authenticated seul (la garde est dans la fonction)');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'private.purger_releve_qualite()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.purger_releve_qualite()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'private.purger_releve_qualite()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'private.purger_releve_qualite()', 'EXECUTE'),
  'la purge n''est executable par aucun role client');
SELECT pg_temp.vrai((SELECT pg_catalog.bool_and(p.prosecdef AND p.proconfig = ARRAY['search_path=""'])
                       FROM pg_catalog.pg_proc p
                      WHERE p.oid IN ('public.noter_qualite_lien(uuid,uuid,text,boolean)'::regprocedure,
                                      'public.releve_qualite_seance(uuid)'::regprocedure,
                                      'private.purger_releve_qualite()'::regprocedure)),
  'SECURITY DEFINER, search_path vide');
SELECT pg_temp.vrai((SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.releve_qualite_lien'::regclass)
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = 'public.releve_qualite_lien'::regclass),
  'securite par ligne active, aucune politique');
SELECT pg_temp.vrai((SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum)
                       FROM pg_catalog.pg_attribute a
                      WHERE a.attrelid = 'public.releve_qualite_lien'::regclass AND a.attnum > 0 AND NOT a.attisdropped)
  = 'id,session_id,profile_id,etat,micro_ouvert,releve_le',
  'la table ne garde que six colonnes : ni adresse, ni appareil, ni mesure');

ROLLBACK;
