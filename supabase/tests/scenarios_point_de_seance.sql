-- POINT-DE-SEANCE (lot 6 ; migration 20261125000000).
-- a1 direction ; b1 titulaire de la classe c1 ; b2 remplacant de la seance s4 ;
-- b3 enseignant d'une autre classe ; t1 tuteur du foyer f1 ; t2 tuteur d'un
-- autre foyer ; e1 (10-13 ans), e2 (6-9 ans), e3 (10-13 ans, sans etape)
-- eleves de f1 dans c1, dans cet ordre.
-- Seances de c1 : s1 lundi, s2 mercredi, s3 vendredi (il y a deux semaines),
-- s4 lundi (remplacant), s5 mercredi (semaine derniere) ; s6 en cours ; s7
-- annulee. e3 present en partie a s2 ; e2 absent a s3.
--   1. droits : tables fermees, rien pour anon, gardes par role ;
--   2. premiere seance : pas de tirage, envoi sans toucher, rejouable ;
--   3. eleve tire : toucher obligatoire, tour de role, absent qui garde sa
--      place, « pas eu le temps » qui garde la tete ;
--   4. mutations rouges : absent, present en partie, reponse inconnue,
--      seance non tenue, autre enseignant, direction, ecriture directe ;
--   5. correction pendant le delai reglable, refus apres, journal ;
--   6. rattrapage : les points a faire ;
--   7. le hub : ce que lisent l'enseignant, la direction, le tuteur, l'eleve
--      de 10 ans et plus ; refus a l'enfant de 6 a 9 ans ; acquis, a
--      renforcer, deux de suite, garde-fou du « A suivi » ;
--   8. mineurs et paie : aucune notification, aucun push, aucun courriel,
--      aucun cahier ecrit, la paie attend toujours.
-- Echoue sans la migration (premier ROUGE : la table n'existe pas). Tout est
-- annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

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

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT pg_catalog.md5('point-seance-' || p)::uuid $$;

-- 'ok', 'refus' (42501) ou le message de l'erreur.
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

-- Envoi du point de [p_seance] : 'ok', 'refus' ou le code de l'erreur.
CREATE FUNCTION pg_temp.envoi(p_seance text, p_reponses jsonb, p_note text DEFAULT NULL) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.point_seance_envoyer(pg_temp.u(p_seance), p_reponses, p_note);
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

-- { "<uuid de e1>": "acquis", ... } a partir de { "e1": "acquis", ... }.
CREATE FUNCTION pg_temp.rep(p jsonb) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT coalesce(pg_catalog.jsonb_object_agg(pg_temp.u(k)::text, v), '{}'::jsonb)
       FROM pg_catalog.jsonb_each(p) AS x(k, v) $$;

-- La page de [p_seance], ou {"refus": true}.
CREATE FUNCTION pg_temp.page(p_seance text) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  RETURN public.point_seance_lire(pg_temp.u(p_seance));
EXCEPTION
  WHEN insufficient_privilege THEN RETURN '{"refus": true}'::jsonb;
END $$;

-- L'historique de [p_eleve], ou {"refus": true}.
CREATE FUNCTION pg_temp.histo(p_eleve text) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  RETURN public.historique_seances_eleve(pg_temp.u(p_eleve));
EXCEPTION
  WHEN insufficient_privilege THEN RETURN '{"refus": true}'::jsonb;
END $$;

-- La reponse lue dans l'historique de [p_eleve] pour [p_seance].
CREATE FUNCTION pg_temp.ligne(p_h jsonb, p_seance text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x FROM pg_catalog.jsonb_array_elements(p_h -> 'seances') x
      WHERE x ->> 'session_id' = pg_temp.u(p_seance)::text $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text), pg_temp.envoi(text, jsonb, text), pg_temp.rep(jsonb), pg_temp.page(text),
  pg_temp.histo(text), pg_temp.ligne(jsonb, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'ps-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','b3','t1','t2','e1','e2','e3','e9']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'Europe/Paris'), (pg_temp.u('f2'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'PS', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PS-ADM-01','admin',NULL,'Direction'),
   ('b1','PS-ENS-01','teacher',NULL,'Titulaire'),
   ('b2','PS-ENS-02','teacher',NULL,'Remplacante'),
   ('b3','PS-ENS-03','teacher',NULL,'Autre'),
   ('t1','PS-TUT-01','guardian','f1','Tutrice'),
   ('t2','PS-TUT-02','guardian','f2','Autre tutrice'),
   ('e1','PS-ELV-01','student','f1','Aicha'),
   ('e2','PS-ELV-02','student','f1','Bilal'),
   ('e3','PS-ELV-03','student','f1','Chams'),
   ('e9','PS-ELV-09','student','f2','Autre classe')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
SELECT pg_temp.u(x.e), 'minor'::public.student_type, x.mode::public.interface_mode, x.coh
  FROM (VALUES ('e1','standard','enfant_10_13'), ('e2','child','enfant_6_9'),
               ('e3','standard','enfant_10_13'), ('e9','standard','enfant_10_13')) AS x(e, mode, coh);
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour PS', 1, 18, 'Europe/Paris'),
 (pg_temp.u('c2'), pg_temp.u('b3'), 'enfant', 6, 'Al-Fajr PS', 2, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT pg_temp.u(x.c), pg_temp.u(x.e), pg_catalog.now() - interval '90 days' + x.n * interval '1 minute'
  FROM (VALUES ('c1','e1',1), ('c1','e2',2), ('c1','e3',3), ('c2','e9',1)) AS x(c, e, n);

-- Le programme publie ; e1 et e2 a l'etape 1 ; e3 sans etape (en attente).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE ps_ids(cle text PRIMARY KEY, id uuid);
INSERT INTO ps_ids VALUES ('v1', public.creer_version_programme(NULL));
SELECT public.preremplir_bases_programme((SELECT id FROM ps_ids WHERE cle = 'v1'));
INSERT INTO ps_ids
SELECT 'n' || c.ordre, c.niveau_id
  FROM public.programme_contenu_admin((SELECT id FROM ps_ids WHERE cle = 'v1')) c;
SELECT public.publier_version_programme((SELECT id FROM ps_ids WHERE cle = 'v1'), 'Version 1 des bases');
RESET ROLE;
GRANT ALL ON ps_ids TO authenticated;
INSERT INTO public.eleve_etape_en_cours(student_id, niveau_id, cohorte, entree_etape_le, entree_niveau_le, origine)
SELECT pg_temp.u(x.e), (SELECT id FROM ps_ids WHERE cle = 'n1'), x.coh,
       current_date - 60, current_date - 60, 'classe'
  FROM (VALUES ('e1','enfant_10_13'), ('e2','enfant_6_9')) AS x(e, coh)
ON CONFLICT (student_id) DO UPDATE SET niveau_id = EXCLUDED.niveau_id;

-- Les seances : lundi 17 h UTC d'il y a deux semaines, et les suivantes.
CREATE FUNCTION pg_temp.lundi() RETURNS timestamptz LANGUAGE sql AS
  $$ SELECT pg_catalog.date_trunc('week', pg_catalog.now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
            - interval '14 days' + interval '12 hours' $$;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.s), pg_temp.u('b1'),
       pg_temp.lundi() + x.j * interval '1 day',
       pg_temp.lundi() + x.j * interval '1 day' + interval '60 minutes',
       x.st::public.session_status, pg_temp.u('c1')
  FROM (VALUES ('s1',0,'ended'), ('s2',2,'ended'), ('s3',4,'ended'), ('s4',7,'ended'),
               ('s5',9,'ended'), ('s7',10,'canceled')) AS x(s, j, st);
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s6'), pg_temp.u('b1'), pg_catalog.now() - interval '10 minutes',
        pg_catalog.now() + interval '50 minutes', 'in_progress', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(s), pg_temp.u(e), 'student'::public.participant_role
  FROM unnest(ARRAY['s1','s2','s3','s4','s5','s6','s7']) AS s,
       unnest(ARRAY['e1','e2','e3']) AS e;
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(s), pg_temp.u('b1'), 'teacher'::public.participant_role
  FROM unnest(ARRAY['s1','s2','s3','s4','s5','s6','s7']) AS s;
-- Presence mesuree : tous de 0 a 60, sauf e3 dix minutes a s2 et e2 absent a s3.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, pg_temp.u(e.e), t.t::public.session_event_type,
       s.started_at + (CASE WHEN t.t = 'joined' THEN 0
                            WHEN e.e = 'e3' AND s.id = pg_temp.u('s2') THEN 10
                            ELSE 60 END) * interval '1 minute',
       'livekit_webhook'
  FROM public.sessions s
  CROSS JOIN (VALUES ('e1'), ('e2'), ('e3')) AS e(e)
  CROSS JOIN (VALUES ('joined'), ('left')) AS t(t)
 WHERE s.id IN (pg_temp.u('s1'), pg_temp.u('s2'), pg_temp.u('s3'), pg_temp.u('s4'), pg_temp.u('s5'))
   AND NOT (e.e = 'e2' AND s.id = pg_temp.u('s3'));
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u('s6'), pg_temp.u(e), 'joined'::public.session_event_type,
       pg_catalog.now() - interval '9 minutes', 'livekit_webhook'
  FROM unnest(ARRAY['e1','e2','e3']) AS e;
-- s4 : la direction designe la remplacante b2 avant la seance.
INSERT INTO public.remplacements_seance(session_id, evenement, enseignant_titulaire_id,
  enseignant_remplacant_id, acteur_id, cle_idempotence, origine, cree_le)
VALUES (pg_temp.u('s4'), 'remplacement_designe_admin', pg_temp.u('b1'), pg_temp.u('b2'),
        pg_temp.u('a1'), pg_temp.u('r4'), 'manuelle', pg_temp.lundi() + interval '6 days');

-- Compteurs d'avant : rien ne doit partir vers personne.
CREATE TEMP TABLE ps_avant AS
SELECT (SELECT pg_catalog.count(*) FROM public.notifications) AS notifications,
       (SELECT pg_catalog.count(*) FROM public.push_sortants) AS push,
       (SELECT pg_catalog.count(*) FROM public.courriels_sortants) AS courriels,
       (SELECT pg_catalog.count(*) FROM public.lesson_reports) AS cahiers;
GRANT ALL ON ps_avant TO authenticated;

-- Le point attend toutes les seances de la fixture.
UPDATE public.app_config SET value = pg_catalog.to_jsonb(pg_catalog.now() - interval '40 days')
 WHERE key = 'point_seance.debut';

-- ------------------------------------------------------------------
-- 1. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT pg_catalog.bool_and(c.relrowsecurity) FROM pg_catalog.pg_class c
    WHERE c.oid IN ('public.point_seance'::regclass, 'public.point_seance_eleves'::regclass,
                    'public.point_seance_journal'::regclass)),
  '1.1 RLS activee sur les trois tables');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.point_seance_lire(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.point_seance_envoyer(uuid,jsonb,text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.points_seance_a_faire()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.historique_seances_eleve(uuid,int)', 'EXECUTE'),
  '1.2 rien pour anon');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.point_seance_tirer(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.point_seance_presents(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.point_seance_etat(uuid,boolean)', 'EXECUTE'),
  '1.3 fonctions privees fermees');

SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT 1 FROM public.point_seance') = 'refus', '1.4 table fermee a l''enseignant (lecture)');
SELECT pg_temp.vrai(
  pg_temp.essai(format('INSERT INTO public.point_seance(session_id, groupe_id, auteur_id) VALUES (%L, %L, %L)',
                       pg_temp.u('s1'), pg_temp.u('c1'), pg_temp.u('b1'))) = 'refus',
  '1.5 table fermee a l''enseignant (ecriture directe)');
SELECT pg_temp.vrai(pg_temp.essai('SELECT 1 FROM public.point_seance_eleves') = 'refus', '1.6 lignes fermees');
SELECT pg_temp.vrai(pg_temp.essai('SELECT 1 FROM public.point_seance_journal') = 'refus', '1.7 journal ferme');
RESET ROLE;

-- Eleve, tuteur, autre enseignant : ni lecture ni envoi. Direction : lecture seule.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.page('s1') ? 'refus', '1.8 l''eleve ne lit pas la page du point');
SELECT pg_temp.vrai(pg_temp.envoi('s1', '{}') = 'refus', '1.9 l''eleve n''envoie pas');
SELECT pg_temp.vrai(pg_temp.essai('SELECT * FROM public.points_seance_a_faire()') = 'refus', '1.10 l''eleve n''a pas de points a faire');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.page('s1') ? 'refus', '1.11 le tuteur ne lit pas la page du point');
SELECT pg_temp.vrai(pg_temp.envoi('s1', '{}') = 'refus', '1.12 le tuteur n''envoie pas');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.page('s1') ? 'refus', '1.13 l''enseignant d''une autre classe ne lit pas');
SELECT pg_temp.vrai(pg_temp.envoi('s1', '{}') = 'refus', '1.14 l''enseignant d''une autre classe n''envoie pas');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.page('s1') ->> 'peut_envoyer') = 'false'
                    AND pg_catalog.jsonb_array_length(pg_temp.page('s1') -> 'eleves') = 3,
                    '1.15 la direction lit, sans pouvoir envoyer');
SELECT pg_temp.vrai(pg_temp.envoi('s1', '{}') = 'refus', '1.16 la direction n''envoie pas');
RESET ROLE;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.point_seance) = 0, '1.17 aucun point ecrit par les refus');

-- ------------------------------------------------------------------
-- 2. Premiere seance : pas de tirage, envoi sans toucher, rejouable
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.page('s1') -> 'eleve_tire') = 'null'::jsonb
                    AND (pg_temp.page('s1') ->> 'peut_envoyer') = 'true'
                    AND (pg_temp.page('s1') ->> 'envoye') = 'false',
                    '2.1 premiere seance tenue de la classe : pas de tirage');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.bool_and(x ->> 'reponse' = 'a_suivi' AND x ->> 'etape' IS NOT DISTINCT FROM
            CASE WHEN x ->> 'prenom' = 'Chams' THEN NULL ELSE x ->> 'etape' END)
     FROM pg_catalog.jsonb_array_elements(pg_temp.page('s1') -> 'eleves') x),
  '2.2 tous les presents « A suivi » par defaut');
SELECT pg_temp.vrai(pg_temp.envoi('s1', '{}') = 'ok', '2.3 le point s''envoie sans aucun toucher');
SELECT pg_temp.vrai(pg_temp.envoi('s1', '{}') = 'ok', '2.4 renvoye a l''identique : accepte');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.point_seance WHERE session_id = pg_temp.u('s1')) = 1
  AND (SELECT pg_catalog.count(*) FROM public.point_seance_eleves
        WHERE session_id = pg_temp.u('s1') AND reponse = 'a_suivi' AND NOT tire) = 3,
  '2.5 une ligne de point, trois « A suivi », aucun doublon au rejeu');
SELECT pg_temp.vrai(
  (SELECT niveau_id FROM public.point_seance_eleves
    WHERE session_id = pg_temp.u('s1') AND student_id = pg_temp.u('e1')) = (SELECT id FROM ps_ids WHERE cle = 'n1')
  AND (SELECT niveau_id FROM public.point_seance_eleves
        WHERE session_id = pg_temp.u('s1') AND student_id = pg_temp.u('e3')) IS NULL,
  '2.6 la reponse est rattachee a l''etape de l''eleve (aucune pour l''eleve sans etape)');

-- ------------------------------------------------------------------
-- 3. L'eleve tire, a tour de role
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
-- s2 : e3 present en partie n'est pas au point ; e1 est tire (premier de la classe).
SELECT pg_temp.vrai((pg_temp.page('s2') ->> 'eleve_tire') = pg_temp.u('e1')::text, '3.1 s2 : e1 est tire');
SELECT pg_temp.vrai(
  pg_catalog.jsonb_array_length(pg_temp.page('s2') -> 'eleves') = 2
  AND (pg_temp.page('s2') -> 'hors_point' -> 0 ->> 'presence') = 'partielle'
  AND (pg_temp.page('s2') -> 'hors_point' -> 0 ->> 'student_id') = pg_temp.u('e3')::text,
  '3.2 s2 : le present en partie ne figure pas au point');
SELECT pg_temp.vrai(
  (SELECT x -> 'reponse' FROM pg_catalog.jsonb_array_elements(pg_temp.page('s2') -> 'eleves') x
    WHERE x ->> 'student_id' = pg_temp.u('e1')::text) = 'null'::jsonb,
  '3.3 l''eleve tire n''a pas de defaut');
SELECT pg_temp.vrai(pg_temp.envoi('s2', '{}') = 'point_seance_eleve_tire_sans_reponse',
                    '3.4 ROUGE : sans toucher pour l''eleve tire, le point ne s''envoie pas');
SELECT pg_temp.vrai(pg_temp.envoi('s2', pg_temp.rep('{"e1": "a_suivi"}')) = 'point_seance_eleve_tire_sans_reponse',
                    '3.5 ROUGE : « A suivi » n''est pas une reponse pour l''eleve tire');
SELECT pg_temp.vrai(pg_temp.envoi('s2', pg_temp.rep('{"e1": "acquis", "e3": "a_renforcer"}')) = 'point_seance_eleve_absent',
                    '3.6 ROUGE : aucune reponse pour un present en partie');
SELECT pg_temp.vrai(pg_temp.envoi('s2', pg_temp.rep('{"e1": "acquis", "e2": "acquis"}')) = 'point_seance_reponse_inconnue',
                    '3.7 ROUGE : « Acquis » est reserve a l''eleve tire');
SELECT pg_temp.vrai(pg_temp.envoi('s2', pg_temp.rep('{"e1": "acquis", "e2": "bien"}')) = 'point_seance_reponse_inconnue',
                    '3.8 ROUGE : reponse inconnue');
SELECT pg_temp.vrai(pg_temp.envoi('s2', pg_temp.rep('{"e1": "acquis", "e9": "a_renforcer"}')) = 'point_seance_eleve_absent',
                    '3.9 ROUGE : eleve d''une autre classe');
RESET ROLE;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.point_seance WHERE session_id = pg_temp.u('s2')) = 0,
                    '3.10 les refus n''ont rien ecrit');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.envoi('s2', pg_temp.rep('{"e1": "acquis", "e2": "a_renforcer"}'), '  Bilal confond ba et ta.  ') = 'ok',
                    '3.11 s2 : e1 « Acquis », e2 « A renforcer », une note');
-- s3 : e2 absent. e1 a ete tire a s2 ; e3 jamais : c'est lui.
SELECT pg_temp.vrai((pg_temp.page('s3') ->> 'eleve_tire') = pg_temp.u('e3')::text
                    AND (pg_temp.page('s3') -> 'hors_point' -> 0 ->> 'presence') = 'absente',
                    '3.12 s3 : e2 absent n''est pas au point ; e3 est tire');
SELECT pg_temp.vrai(pg_temp.envoi('s3', pg_temp.rep('{"e2": "a_renforcer", "e3": "acquis"}')) = 'point_seance_eleve_absent',
                    '3.13 ROUGE : aucune reponse pour un absent');
SELECT pg_temp.vrai(pg_temp.envoi('s3', pg_temp.rep('{"e3": "pas_ecoute"}')) = 'ok',
                    '3.14 s3 : « Pas eu le temps de l''ecouter » envoie le point');
-- s4 : seance de la remplacante. Le titulaire n'est plus l'enseignant de la seance.
SELECT pg_temp.vrai(pg_temp.page('s4') ? 'refus' AND pg_temp.envoi('s4', '{}') = 'refus',
                    '3.15 s4 : le titulaire remplace ne fait pas le point');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
-- e2, absent a s3, a garde sa place : il passe a son retour, avant e3 (dont
-- le « pas eu le temps » ne compte pas comme un tirage).
SELECT pg_temp.vrai((pg_temp.page('s4') ->> 'eleve_tire') = pg_temp.u('e2')::text,
                    '3.16 s4 : l''absent de s3 passe a son retour');
SELECT pg_temp.vrai(pg_temp.envoi('s4', pg_temp.rep('{"e2": "a_renforcer"}')) = 'ok',
                    '3.17 s4 : la remplacante envoie le point de sa seance');
SELECT pg_temp.vrai(pg_temp.page('s5') ? 'refus', '3.18 la remplacante ne lit pas une autre seance');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.page('s5') ->> 'eleve_tire') = pg_temp.u('e3')::text,
                    '3.19 s5 : e3 est reste en tete apres « pas eu le temps »');
SELECT pg_temp.vrai(pg_temp.envoi('s5', pg_temp.rep('{"e3": "a_renforcer", "e2": "a_suivi"}')) = 'ok', '3.20 s5 envoye');
-- Seance en cours, seance annulee : pas de point.
SELECT pg_temp.vrai((pg_temp.page('s6') ->> 'tenue') = 'false'
                    AND pg_temp.envoi('s6', '{}') = 'point_seance_seance_non_tenue',
                    '3.21 ROUGE : seance encore en cours');
SELECT pg_temp.vrai(pg_temp.envoi('s7', '{}') = 'point_seance_seance_non_tenue', '3.22 ROUGE : seance annulee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.point_seance_eleves WHERE tire) = 4
  AND (SELECT note FROM public.point_seance WHERE session_id = pg_temp.u('s2')) = 'Bilal confond ba et ta.',
  '3.23 un eleve tire par seance (s2 a s5) ; note nettoyee');

-- ------------------------------------------------------------------
-- 5. Correction pendant le delai reglable
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.envoi('s5', pg_temp.rep('{"e3": "acquis", "e2": "a_renforcer"}')) = 'ok',
                    '5.1 correction dans le delai : acceptee');
SELECT pg_temp.vrai((pg_temp.page('s5') ->> 'eleve_tire') = pg_temp.u('e3')::text
                    AND (pg_temp.page('s5') ->> 'modifie_le') IS NOT NULL,
                    '5.2 l''eleve tire ne change pas a la correction');
SELECT pg_temp.vrai(pg_temp.envoi('s5', pg_temp.rep('{"e2": "a_renforcer"}')) = 'point_seance_eleve_tire_sans_reponse',
                    '5.3 ROUGE : correction sans reponse pour l''eleve tire');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT reponse FROM public.point_seance_eleves WHERE session_id = pg_temp.u('s5') AND student_id = pg_temp.u('e3')) = 'acquis'
  AND (SELECT reponse FROM public.point_seance_eleves WHERE session_id = pg_temp.u('s5') AND student_id = pg_temp.u('e2')) = 'a_renforcer'
  AND (SELECT pg_catalog.count(*) FROM public.point_seance_journal WHERE session_id = pg_temp.u('s5')) = 2,
  '5.4 reponses corrigees ; le journal garde les deux envois');
UPDATE public.point_seance SET envoye_le = pg_catalog.now() - interval '25 hours' WHERE session_id = pg_temp.u('s5');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.envoi('s5', pg_temp.rep('{"e3": "a_renforcer"}')) = 'point_seance_delai_depasse'
                    AND (pg_temp.page('s5') ->> 'peut_envoyer') = 'false',
                    '5.5 ROUGE : apres le delai (24 h), plus de correction');
RESET ROLE;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(48) WHERE key = 'point_seance.modifiable_heures';
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.page('s5') ->> 'peut_envoyer') = 'true'
                    AND pg_temp.envoi('s5', pg_temp.rep('{"e3": "acquis", "e2": "a_renforcer"}')) = 'ok',
                    '5.6 le delai est un reglage : a 48 h, la correction repasse');
RESET ROLE;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(24) WHERE key = 'point_seance.modifiable_heures';

-- ------------------------------------------------------------------
-- 6. Rattrapage : les points a faire
-- ------------------------------------------------------------------
-- On retire le point de s3 du decor pour le voir « a faire » : nouvelle seance s8 sans point.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s8'), pg_temp.u('b1'), pg_temp.lundi() + interval '11 days',
        pg_temp.lundi() + interval '11 days 1 hour', 'ended', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u('s8'), pg_temp.u(e), 'student'::public.participant_role FROM unnest(ARRAY['e1','e2','e3']) AS e;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u('s8'), pg_temp.u('e1'), t.t::public.session_event_type,
       pg_temp.lundi() + interval '11 days' + t.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('joined', 0), ('left', 60)) AS t(t, m);
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(a.session_id) FROM public.points_seance_a_faire() a) = ARRAY[pg_temp.u('s8')],
  '6.1 le titulaire voit la seance tenue sans point (ni la seance en cours, ni l''annulee, ni celle de la remplacante)');
SELECT pg_temp.vrai((pg_temp.page('s8') ->> 'eleve_tire') = pg_temp.u('e1')::text
                    AND pg_catalog.jsonb_array_length(pg_temp.page('s8') -> 'eleves') = 1,
                    '6.2 un seul present : c''est lui qui est tire');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.points_seance_a_faire()) = 0,
                    '6.3 la remplacante n''a plus rien a faire (son point est envoye)');
RESET ROLE;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(pg_catalog.now()) WHERE key = 'point_seance.debut';
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.points_seance_a_faire()) = 0,
                    '6.4 les seances d''avant « point_seance.debut » n''attendent aucun point');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. Le hub : l'historique des seances et ce que le serveur en deduit
-- ------------------------------------------------------------------
-- e2 : s1 « A suivi », s2 « A renforcer », s3 absent, s4 « A renforcer » (tire), s5 « A renforcer ».
-- e1 : s1 « A suivi », s2 « Acquis » (tire), s3, s4, s5 « A suivi ».
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE ps_h AS SELECT 'b1-e2' AS cle, pg_temp.histo('e2') AS h;
INSERT INTO ps_h SELECT 'b1-e1', pg_temp.histo('e1');
INSERT INTO ps_h SELECT 'b1-e3', pg_temp.histo('e3');
RESET ROLE;
GRANT ALL ON ps_h TO authenticated;
SELECT pg_temp.vrai(
  (h ->> 'lecteur') = 'academie'
  AND (h -> 'synthese' ->> 'a_renforcer') = 'true'
  AND (h -> 'synthese' ->> 'deux_de_suite') = 'true'
  AND (h -> 'synthese' ->> 'travail') = 'cible'
  AND (pg_temp.ligne(h, 's2') ->> 'note') = 'Bilal confond ba et ta.'
  AND (pg_temp.ligne(h, 's4') ->> 'tire') = 'true'
  AND (pg_temp.ligne(h, 's3') ->> 'presence') = 'absente'
  AND NOT (pg_temp.ligne(h, 's3') ? 'reponse'),
  '7.1 enseignant : a renforcer, deux de suite, note, tirage ; l''absence n''est pas un « A renforcer »')
  FROM ps_h WHERE cle = 'b1-e2';
-- e1 : deux semaines, quatre « A suivi » par defaut (un compte par semaine) et un « Acquis » touche.
SELECT pg_temp.vrai(
  (h -> 'synthese' ->> 'acquis') = '3' AND (h -> 'synthese' ->> 'points') = '5'
  AND (h -> 'synthese' ->> 'a_renforcer') = 'false' AND (h -> 'synthese' ->> 'travail') = 'relire',
  '7.2 garde-fou : un « A suivi » par defaut compte une fois par semaine')
  FROM ps_h WHERE cle = 'b1-e1';
-- e3 (sans etape) : s3 « pas eu le temps » n'est pas une observation ; s5 « Acquis ».
SELECT pg_temp.vrai(
  (h -> 'synthese' ->> 'points') = '3' AND NOT (h -> 'synthese' ? 'etape')
  AND (pg_temp.ligne(h, 's3') ->> 'reponse') = 'pas_ecoute'
  AND (pg_temp.ligne(h, 's2') ->> 'presence') = 'partielle' AND NOT (pg_temp.ligne(h, 's2') ? 'reponse'),
  '7.3 « pas eu le temps » ne compte aucune observation ; presence partielle sans reponse')
  FROM ps_h WHERE cle = 'b1-e3';
UPDATE public.app_config SET value = pg_catalog.to_jsonb(2) WHERE key = 'point_seance.a_suivi_par_semaine';
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.histo('e1') -> 'synthese' ->> 'acquis') = '5'
                    AND (pg_temp.histo('e2') -> 'synthese' ->> 'deux_de_suite') = 'true'
                    AND (pg_temp.ligne(pg_temp.histo('e2'), 's2') ->> 'note') IS NOT NULL,
                    '7.4 direction : tout ; le garde-fou est un reglage');
RESET ROLE;
UPDATE public.app_config SET value = pg_catalog.to_jsonb(1) WHERE key = 'point_seance.a_suivi_par_semaine';

-- Le tuteur du foyer : « A suivi » ou « A renforcer », ni note, ni tirage, ni « deux de suite ».
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ps_h SELECT 't1-e2', pg_temp.histo('e2');
INSERT INTO ps_h SELECT 't1-e1', pg_temp.histo('e1');
INSERT INTO ps_h SELECT 't1-e3', pg_temp.histo('e3');
RESET ROLE;
SELECT pg_temp.vrai(
  (h ->> 'lecteur') = 'famille'
  AND (h -> 'synthese' ->> 'a_renforcer') = 'true' AND (h -> 'synthese' ->> 'travail') = 'cible'
  AND NOT (h -> 'synthese' ? 'deux_de_suite')
  AND h::text NOT LIKE '%Bilal confond%' AND h::text NOT LIKE '%"note"%' AND h::text NOT LIKE '%"tire"%'
  AND (pg_temp.ligne(h, 's4') ->> 'reponse') = 'a_renforcer'
  AND (pg_temp.ligne(h, 's1') ->> 'reponse') = 'a_suivi'
  AND (pg_temp.ligne(h, 's1') ->> 'travail') = 'relire',
  '7.5 tuteur : a renforcer et travail cible ; jamais la note, le tirage, ni « deux de suite »')
  FROM ps_h WHERE cle = 't1-e2';
SELECT pg_temp.vrai((pg_temp.ligne(h, 's2') ->> 'reponse') = 'a_suivi' AND h::text NOT LIKE '%: "acquis"%',
  '7.6 tuteur : l''« Acquis » de l''eleve tire se lit « A suivi »')
  FROM ps_h WHERE cle = 't1-e1';
SELECT pg_temp.vrai(NOT (pg_temp.ligne(h, 's3') ? 'reponse') AND h::text NOT LIKE '%pas_ecoute%',
  '7.7 tuteur : « pas eu le temps » ne se lit pas')
  FROM ps_h WHERE cle = 't1-e3';

SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.histo('e2') ? 'refus', '7.8 le tuteur d''un autre foyer est refuse');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.histo('e2') ? 'refus', '7.9 l''enseignant d''une autre classe est refuse');
RESET ROLE;
-- L'eleve de 10 a 13 ans lit le sien, comme la famille ; pas celui d'un autre.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.histo('e1') ->> 'lecteur') = 'famille'
                    AND pg_temp.histo('e1')::text NOT LIKE '%"note"%'
                    AND pg_temp.histo('e2') ? 'refus',
                    '7.10 l''eleve de 10 ans et plus lit son historique, jamais celui d''un autre');
RESET ROLE;
-- L'enfant de 6 a 9 ans ne lit pas l'historique avec son compte.
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.histo('e2') ? 'refus', '7.11 l''enfant de 6 a 9 ans : aucun historique, son tuteur le lit');
RESET ROLE;
SELECT pg_temp.qui(NULL, 'anon');
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.essai(format('SELECT public.historique_seances_eleve(%L)', pg_temp.u('e1'))) <> 'ok',
                    '7.12 anon : rien');
RESET ROLE;

-- ------------------------------------------------------------------
-- 8. Mineurs et paie : rien ne part, rien n'est ecrit ailleurs
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications) = a.notifications
  AND (SELECT pg_catalog.count(*) FROM public.push_sortants) = a.push
  AND (SELECT pg_catalog.count(*) FROM public.courriels_sortants) = a.courriels,
  '8.1 aucune notification, aucun push, aucun courriel (ni a un enfant, ni a personne)')
  FROM ps_avant a;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.lesson_reports) = a.cahiers
  AND NOT private.cahier_semaine_couvert(pg_temp.u('s1')),
  '8.2 paie intacte : aucun cahier ecrit, la seance attend toujours son cahier')
  FROM ps_avant a;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute at
               WHERE at.attrelid IN ('public.point_seance'::regclass, 'public.point_seance_eleves'::regclass)
                 AND at.attnum > 0 AND at.attname ~ '(motif|sante|religi|montant|prix)'),
  '8.3 aucune colonne de motif, de sante, de religion ni d''argent');

ROLLBACK;
\o
\echo scenarios_point_de_seance : termine
