-- SALLE-SECOND-APPAREIL (23/11/2026) : un profil, un appareil a la fois dans une seance, sans coupure brusque.
-- Migration 20261203200000. A rejouer sur une base NEUVE (stub + toutes les migrations) : fixtures annulees.
--   demande -> le premier appareil la voit ; accepter (il cede) ; refuser ; premier appareil silencieux (30 s) ;
--   attente sans reponse (45 s) ; annulation ; demande d'un autre profil refusee ; tuteur pour son enfant ;
--   l'enseignant suit la meme regle ; l'administration n'est pas suivie ; droits.
\set ON_ERROR_STOP 1
BEGIN;
SET LOCAL client_min_messages = warning;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('fc000000-0000-4000-8000-' || substr(md5(p), 1, 12))::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
             pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SALLE-SECOND-APPAREIL ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'SALLE-SECOND-APPAREIL ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'SALLE-SECOND-APPAREIL ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  PERFORM pg_temp.vrai(true, p_label);
END $$;

-- Ce que create-room-token demande au serveur (service_role).
CREATE FUNCTION pg_temp.passage(p_profil text, p_demandeur text, p_appareil text, p_demande uuid DEFAULT NULL,
  p_libelle text DEFAULT 'Chrome · Android') RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  v := public.salle_passage(pg_temp.id('501'), pg_temp.id(p_profil), pg_temp.id(p_demandeur),
         pg_temp.id(p_appareil), p_libelle, p_demande);
  EXECUTE 'RESET ROLE';
  RETURN v;
EXCEPTION WHEN OTHERS THEN
  EXECUTE 'RESET ROLE';
  RAISE;
END $$;

-- Un appel client (authenticated) sous l'identite donnee.
CREATE FUNCTION pg_temp.client(p_qui text, p_role text, p_sql text, p_foyer text DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(pg_temp.id(p_qui), p_role, CASE WHEN p_foyer IS NULL THEN NULL ELSE pg_temp.id(p_foyer) END);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
EXCEPTION WHEN OTHERS THEN
  EXECUTE 'RESET ROLE';
  RAISE;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.id(text), pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, service_role;

CREATE FUNCTION pg_temp.battement(p_qui text, p_role text, p_profil text, p_appareil text, p_foyer text DEFAULT NULL)
RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.client(p_qui, p_role, format('SELECT public.salle_battement(%L, %L, %L, %L)::jsonb',
    pg_temp.id('501'), pg_temp.id(p_profil), pg_temp.id(p_appareil), 'Firefox · Windows'), p_foyer) $$;
CREATE FUNCTION pg_temp.etat(p_qui text, p_role text, p_demande uuid) RETURNS text LANGUAGE sql AS $$
  SELECT (pg_temp.client(p_qui, p_role, format('SELECT public.salle_etat_passage(%L)::jsonb', p_demande)) ->> 'etat') $$;
CREATE FUNCTION pg_temp.annuler(p_qui text, p_role text, p_demande uuid) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.client(p_qui, p_role, format('SELECT to_jsonb(public.salle_annuler_passage(%L))', p_demande)) $$;
CREATE FUNCTION pg_temp.repondre(p_qui text, p_role text, p_demande uuid, p_accepter boolean, p_foyer text DEFAULT NULL)
RETURNS text LANGUAGE sql AS $$
  SELECT (pg_temp.client(p_qui, p_role, format('SELECT to_jsonb(public.salle_repondre_passage(%L, %L))', p_demande, p_accepter),
    p_foyer) #>> '{}') $$;

-- ------------------------------------------------------------------
-- Fixtures : 1 direction, 2 enseignant, 3 eleve S, 4 eleve T (autre foyer), 5 tuteur, 6 enfant du tuteur, 7 autre tuteur
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) SELECT pg_temp.id(x), 'fc-' || x || '@test.invalid'
  FROM unnest(ARRAY['1','2','3','4','5','6','7']) AS x;
INSERT INTO public.households(id, timezone) SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['101','102','103']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END, x.prenom, 'FC',
       (CASE WHEN x.role = 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       x.genre::public.gender
  FROM (VALUES
   ('1','FC-ADM-0001','admin',NULL,'Direction','female'),
   ('2','FC-ENS-0001','teacher',NULL,'Maryam','female'),
   ('3','FC-ELV-0003','student','101','Yasmine','female'),
   ('4','FC-ELV-0004','student','102','Bilal','male'),
   ('5','FC-TUT-0005','guardian','103','Amina','female'),
   ('6','FC-ELV-0006','student','103','Adam','male'),
   ('7','FC-TUT-0007','guardian','102','Karim','male')) AS x(id, mat, role, foyer, prenom, genre);
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES (pg_temp.id('901'), pg_temp.id('2'), 'enfant', 5, 'Classe FC', 1, 9, 'Europe/Paris');
DELETE FROM public.sessions WHERE groupe_id = pg_temp.id('901');
INSERT INTO public.sessions(id, teacher_id, groupe_id, started_at, ended_at, status, session_type)
VALUES (pg_temp.id('501'), pg_temp.id('2'), pg_temp.id('901'), now() - interval '10 minutes',
        now() + interval '50 minutes', 'planned', 'standard');

INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.id('501'), pg_temp.id(x), 'student' FROM unnest(ARRAY['3','4','6']) AS x
ON CONFLICT (session_id, profile_id) DO NOTHING;

-- Pour vieillir un battement ou une demande sans attendre.
CREATE FUNCTION pg_temp.vieillir_battement(p_profil text, p_secondes int) RETURNS void LANGUAGE sql AS $$
  UPDATE public.salle_appareils SET battement_le = clock_timestamp() - make_interval(secs => p_secondes)
   WHERE session_id = pg_temp.id('501') AND profile_id = pg_temp.id(p_profil) $$;
CREATE FUNCTION pg_temp.vieillir_demande(p_demande uuid, p_secondes int) RETURNS void LANGUAGE sql AS $$
  UPDATE public.salle_passages SET cree_le = clock_timestamp() - make_interval(secs => p_secondes)
   WHERE id = p_demande $$;

-- ------------------------------------------------------------------
-- 1. Le premier appareil entre ; aucun second : aucune question
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'a1') ->> 'decision' = 'entrer'
  AND (pg_temp.passage('3', '3', 'a1') ->> 'note') IS NULL,
  '1 : le premier appareil entre sans question, et un rejeu du meme appareil aussi');
SELECT pg_temp.vrai((pg_temp.battement('3', 'student', '3', 'a1') ->> 'cede')::boolean IS FALSE
  AND pg_temp.battement('3', 'student', '3', 'a1') -> 'demande' = 'null'::jsonb,
  '1 : son battement ne dit rien : pas de demande, il ne cede pas');

-- ------------------------------------------------------------------
-- 2. Un second appareil : le serveur ne rend pas le jeton, il demande
-- ------------------------------------------------------------------
SELECT set_config('test.d1', (pg_temp.passage('3', '3', 'b1', NULL, 'Chrome · Android') ->> 'demande'), true);
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'b1', current_setting('test.d1')::uuid) ->> 'decision' = 'attendre',
  '2 : le second appareil attend, aucun jeton');
SELECT pg_temp.vrai(pg_temp.battement('3', 'student', '3', 'a1') -> 'demande' ->> 'libelle' = 'Chrome · Android'
  AND pg_temp.battement('3', 'student', '3', 'a1') -> 'demande' ->> 'id' = current_setting('test.d1'),
  '2 : le premier appareil voit la demande et l''etiquette de l''autre appareil (jamais une adresse)');
SELECT pg_temp.vrai(pg_temp.etat('3', 'student', current_setting('test.d1')::uuid) = 'en_attente',
  '2 : le second appareil lit « en attente »');

-- ------------------------------------------------------------------
-- 3. Accepter : le premier cede, le second recoit son jeton
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.repondre('3', 'student', current_setting('test.d1')::uuid, true) = 'accepte',
  '3 : le premier appareil accepte');
SELECT pg_temp.vrai((pg_temp.battement('3', 'student', '3', 'a1') ->> 'cede')::boolean,
  '3 : son battement suivant lui dit de sortir proprement');
SELECT pg_temp.vrai(pg_temp.etat('3', 'student', current_setting('test.d1')::uuid) = 'accepte',
  '3 : le second appareil lit « accepte »');
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'b1', current_setting('test.d1')::uuid) ->> 'decision' = 'entrer',
  '3 : le second appareil recoit son jeton');
SELECT pg_temp.vrai((SELECT appareil = pg_temp.id('b1') AND cede_le IS NULL FROM public.salle_appareils
                      WHERE session_id = pg_temp.id('501') AND profile_id = pg_temp.id('3')),
  '3 : la place est au second appareil : jamais deux appareils pour un profil');
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'b1', current_setting('test.d1')::uuid) ->> 'decision' = 'entrer',
  '3 : la meme demande, rejouee par le meme appareil, ne bloque pas');
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'a1') ->> 'decision' = 'attendre',
  '3 : l''ancien appareil ne rentre pas par la petite porte : il doit demander a son tour');
SELECT pg_temp.vrai((pg_temp.battement('3', 'student', '3', 'a1') ->> 'cede')::boolean,
  '3 : un battement de l''ancien appareil n''efface pas la place du nouveau : il doit sortir');

-- ------------------------------------------------------------------
-- 4. Refuser
-- ------------------------------------------------------------------
SELECT set_config('test.d2', (pg_temp.passage('3', '3', 'a1', NULL, 'Safari · iPhone') ->> 'demande'), true);
SELECT pg_temp.vrai(pg_temp.battement('3', 'student', '3', 'b1') -> 'demande' ->> 'libelle' = 'Safari · iPhone',
  '4 : le nouvel appareil de reference voit la demande de l''autre');
SELECT pg_temp.vrai(pg_temp.repondre('3', 'student', current_setting('test.d2')::uuid, false) = 'refuse',
  '4 : il refuse');
SELECT pg_temp.vrai(pg_temp.etat('3', 'student', current_setting('test.d2')::uuid) = 'refuse'
  AND pg_temp.passage('3', '3', 'a1', current_setting('test.d2')::uuid) ->> 'decision' = 'refuse',
  '4 : le demandeur lit « refuse » et ne recoit aucun jeton');
SELECT pg_temp.vrai((pg_temp.battement('3', 'student', '3', 'b1') ->> 'cede')::boolean IS FALSE
  AND pg_temp.battement('3', 'student', '3', 'b1') -> 'demande' = 'null'::jsonb,
  '4 : l''appareil refusant reste dans la salle, rien ne le coupe');

-- ------------------------------------------------------------------
-- 5. Premier appareil silencieux (30 s) : le second entre directement, avec sa note
-- ------------------------------------------------------------------
SELECT pg_temp.vieillir_battement('3', 40);
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'c1') ->> 'decision' = 'entrer'
  AND pg_temp.passage('3', '3', 'c1') ->> 'note' IS NULL,
  '5 : place silencieuse : le nouvel appareil entre tout de suite (la note n''est dite qu''une fois)');
-- ... la note vient quand l'appareil silencieux est remplace par un autre.
SELECT pg_temp.vieillir_battement('3', 40);
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'd1') ->> 'note' = 'ancien_silencieux',
  '5 : l''ancien appareil ne repondait plus : le serveur le dit au nouveau (note ancien_silencieux)');
-- Une demande deja posee devient « libre » quand le premier se tait.
SELECT set_config('test.d3', (pg_temp.passage('3', '3', 'e1') ->> 'demande'), true);
SELECT pg_temp.vieillir_battement('3', 40);
SELECT pg_temp.vrai(pg_temp.etat('3', 'student', current_setting('test.d3')::uuid) = 'libre'
  AND pg_temp.passage('3', '3', 'e1', current_setting('test.d3')::uuid) ->> 'note' = 'ancien_silencieux',
  '5 : une demande en attente devient libre quand le premier appareil se tait, avec la note');

-- ------------------------------------------------------------------
-- 6. Premier appareil vivant, sans reponse en 45 s : « pas de reponse », on peut recommencer
-- ------------------------------------------------------------------
SELECT pg_temp.battement('3', 'student', '3', 'e1');
SELECT set_config('test.d4', (pg_temp.passage('3', '3', 'f1') ->> 'demande'), true);
SELECT pg_temp.battement('3', 'student', '3', 'e1');
SELECT pg_temp.vieillir_demande(current_setting('test.d4')::uuid, 50);
SELECT pg_temp.vrai(pg_temp.etat('3', 'student', current_setting('test.d4')::uuid) = 'sans_reponse'
  AND pg_temp.passage('3', '3', 'f1', current_setting('test.d4')::uuid) ->> 'decision' = 'sans_reponse',
  '6 : le premier appareil est vivant mais n''a pas repondu : « sans reponse », aucun jeton');
SELECT pg_temp.vrai((pg_temp.battement('3', 'student', '3', 'e1') -> 'demande') = 'null'::jsonb,
  '6 : la demande expiree disparait de l''ecran du premier appareil');
SELECT pg_temp.vrai(pg_temp.passage('3', '3', 'f1') ->> 'decision' = 'attendre',
  '6 : le second appareil peut recommencer : une demande neuve');
SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.salle_passages WHERE appareil = pg_temp.id('f1') AND etat = 'en_attente'),
  '6 : une seule demande ouverte pour cet appareil');

-- ------------------------------------------------------------------
-- 7. Annuler
-- ------------------------------------------------------------------
SELECT set_config('test.d5', (SELECT id::text FROM public.salle_passages
                               WHERE appareil = pg_temp.id('f1') AND etat = 'en_attente'), true);
SELECT pg_temp.annuler('3', 'student', current_setting('test.d5')::uuid);
SELECT pg_temp.vrai(pg_temp.etat('3', 'student', current_setting('test.d5')::uuid) = 'annule'
  AND (pg_temp.battement('3', 'student', '3', 'e1') -> 'demande') = 'null'::jsonb,
  '7 : annuler : la demande disparait chez le premier appareil');

-- ------------------------------------------------------------------
-- 8. Une demande qui n'est pas la sienne est refusee
-- ------------------------------------------------------------------
SELECT set_config('test.d6', (pg_temp.passage('3', '3', 'g1') ->> 'demande'), true);
SELECT pg_temp.refus(format($q$SELECT pg_temp.etat('4', 'student', %L)$q$, current_setting('test.d6')::uuid), '42501',
  '8 : un autre profil ne lit pas l''etat d''une demande qui n''est pas la sienne');
SELECT pg_temp.refus(format($q$SELECT pg_temp.repondre('4', 'student', %L, true)$q$, current_setting('test.d6')::uuid), '42501',
  '8 : un autre profil n''accepte pas la demande d''un autre');
SELECT pg_temp.refus(format($q$SELECT pg_temp.annuler('4', 'student', %L)$q$, current_setting('test.d6')::uuid), '42501',
  '8 : un autre profil n''annule pas la demande d''un autre');
SELECT pg_temp.refus($q$SELECT pg_temp.battement('4', 'student', '3', 'z1')$q$, '42501',
  '8 : un autre profil ne bat pas pour le profil d''un autre');
SELECT pg_temp.refus(format($q$SELECT pg_temp.passage('4', '4', 'g1', %L)$q$, current_setting('test.d6')::uuid), '42501',
  '8 : un identifiant de demande falsifie (autre profil) n''ouvre pas la salle');
SELECT pg_temp.refus(format($q$SELECT pg_temp.passage('3', '3', 'h1', %L)$q$, current_setting('test.d6')::uuid), '42501',
  '8 : la demande d''un autre appareil du meme profil n''est pas utilisable par un troisieme');
SELECT pg_temp.refus($q$SELECT pg_temp.etat('3', 'student', gen_random_uuid())$q$, '42501',
  '8 : un identifiant inconnu est refuse de la meme facon');

-- ------------------------------------------------------------------
-- 9. Le tuteur agit pour son enfant, pas pour celui d'un autre foyer
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.passage('6', '5', 'k1') ->> 'decision' = 'entrer', '9 : l''enfant entre depuis l''appareil du tuteur');
SELECT set_config('test.d7', (pg_temp.passage('6', '5', 'k2') ->> 'demande'), true);
SELECT pg_temp.vrai(pg_temp.battement('5', 'guardian', '6', 'k1', '103') -> 'demande' ->> 'id' = current_setting('test.d7'),
  '9 : le tuteur, premier appareil de l''enfant, voit la demande');
SELECT pg_temp.refus($q$SELECT pg_temp.battement('7', 'guardian', '6', 'k1', '102')$q$, '42501',
  '9 : le tuteur d''un autre foyer ne bat pas pour cet enfant');
SELECT pg_temp.refus(format($q$SELECT pg_temp.repondre('7', 'guardian', %L, true, '102')$q$, current_setting('test.d7')::uuid), '42501',
  '9 : le tuteur d''un autre foyer ne repond pas pour cet enfant');
SELECT pg_temp.vrai(pg_temp.repondre('5', 'guardian', current_setting('test.d7')::uuid, true, '103') = 'accepte',
  '9 : le tuteur de l''enfant repond');

-- Un inconnu (ni participant, ni tuteur du profil) ne prend la place de personne.
SELECT pg_temp.vrai(pg_temp.passage('3', '7', 'p1') ->> 'decision' = 'entrer'
  AND NOT EXISTS (SELECT 1 FROM public.salle_appareils WHERE appareil = pg_temp.id('p1')),
  '9 : un tuteur d''un autre foyer ne prend pas la place de l''enfant (rien n''est suivi ; le jeton sera refuse par la base)');

-- ------------------------------------------------------------------
-- 10. L'enseignant suit la meme regle ; l'administration n'est pas suivie
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.passage('2', '2', 'm1') ->> 'decision' = 'entrer'
  AND pg_temp.passage('2', '2', 'm2') ->> 'decision' = 'attendre',
  '10 : un enseignant sur un second appareil doit lui aussi demander');
SELECT pg_temp.vrai(pg_temp.passage('1', '1', 'n1') ->> 'decision' = 'entrer'
  AND pg_temp.passage('1', '1', 'n2') ->> 'decision' = 'entrer'
  AND NOT EXISTS (SELECT 1 FROM public.salle_appareils WHERE profile_id = pg_temp.id('1')),
  '10 : l''administration (identite visible partagee) est hors perimetre : jamais suivie');

-- ------------------------------------------------------------------
-- 11. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'public.salle_passage(uuid,uuid,uuid,uuid,text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.salle_passage(uuid,uuid,uuid,uuid,text,uuid)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.salle_passage(uuid,uuid,uuid,uuid,text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.salle_battement(uuid,uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.salle_battement(uuid,uuid,uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.salle_repondre_passage(uuid,boolean)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.salle_passages', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.salle_appareils', 'INSERT')
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.salle_passages'::regclass)
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.salle_appareils'::regclass),
  '11 : la table n''est pas lisible par un client, RLS active ; create-room-token seul appelle salle_passage');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM unnest(ARRAY['public.salle_battement(uuid,uuid,uuid,text)'::regprocedure,
                               'public.salle_repondre_passage(uuid,boolean)'::regprocedure,
                               'public.salle_etat_passage(uuid)'::regprocedure,
                               'public.salle_annuler_passage(uuid)'::regprocedure]) f
     WHERE coalesce(obj_description(f, 'pg_proc'), '')
           NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || ';%'),
  '11 : l''empreinte F86 de chaque fonction est celle de la fonction installee');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 38,
  'au moins 38 controles ont passe');
SELECT 'SALLE-SECOND-APPAREIL : scenarios verts' AS resultat;
ROLLBACK;
