-- COM-BACK-1 : messages metier et annonces de Classe.
-- Chaque garde a au moins un controle de refus ; les controles positifs
-- prouvent que le refus vient de la garde et non d'une fixture cassee.
-- A rejouer sur une base NEUVE (les fixtures sont inserees puis annulees).
\o /dev/null
BEGIN;

-- ------------------------------------------------------------
-- Outils de test (schema temporaire de la session)
-- ------------------------------------------------------------
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_build_object('role', p_role))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.com_n',
    (coalesce(nullif(pg_catalog.current_setting('test.com_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text) TO authenticated, agent_ro;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('c0000000-0000-4000-8000-0000000000a1','com-admin@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000a2','com-compta@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000a3','com-ctrl@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000b1','com-t1@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000b2','com-t2@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000b3','com-td@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000d1','com-g1@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000d2','com-g1b@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000d3','com-g2@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000d4','com-g4@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000e1','com-e1@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000e2','com-e2@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000e3','com-s3@test.invalid'),
 ('c0000000-0000-4000-8000-0000000000e4','com-e4@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('c0000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('c0000000-0000-4000-8000-0000000000f2','Europe/Paris'),
 ('c0000000-0000-4000-8000-0000000000f3','Europe/Paris'),
 ('c0000000-0000-4000-8000-0000000000f4','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('c0000000-0000-4000-8000-0000000000a1','COM-ADM-0001','admin',NULL,'Direction','Com','active','female'),
 ('c0000000-0000-4000-8000-0000000000a2','COM-CPT-0001','accountant',NULL,'Comptable','Com','active','male'),
 ('c0000000-0000-4000-8000-0000000000a3','COM-CTL-0001','controller',NULL,'Controleur','Com','active','male'),
 ('c0000000-0000-4000-8000-0000000000b1','COM-ENS-0001','teacher',NULL,'Maryam','Exemple','provisional_active','female'),
 ('c0000000-0000-4000-8000-0000000000b2','COM-ENS-0002','teacher',NULL,'Ibrahim','Exemple','provisional_active','male'),
 ('c0000000-0000-4000-8000-0000000000b3','COM-ENS-0003','teacher',NULL,'Desactive','Exemple','provisional_active','male'),
 ('c0000000-0000-4000-8000-0000000000d1','COM-TUT-0001','guardian','c0000000-0000-4000-8000-0000000000f1','Amina','Foyer1','active','female'),
 ('c0000000-0000-4000-8000-0000000000d2','COM-TUT-0002','guardian','c0000000-0000-4000-8000-0000000000f1','Karim','Foyer1','active','male'),
 ('c0000000-0000-4000-8000-0000000000d3','COM-TUT-0003','guardian','c0000000-0000-4000-8000-0000000000f2','Sara','Foyer2','active','female'),
 ('c0000000-0000-4000-8000-0000000000d4','COM-TUT-0004','guardian','c0000000-0000-4000-8000-0000000000f4','Nadia','Foyer4','active','female'),
 ('c0000000-0000-4000-8000-0000000000e1','COM-ELV-0001','student','c0000000-0000-4000-8000-0000000000f1','Yasmine','Foyer1','active','female'),
 ('c0000000-0000-4000-8000-0000000000e2','COM-ELV-0002','student','c0000000-0000-4000-8000-0000000000f2','Adam','Foyer2','active','male'),
 ('c0000000-0000-4000-8000-0000000000e3','COM-ELV-0003','student','c0000000-0000-4000-8000-0000000000f3','Hamza','Adulte','active','male'),
 ('c0000000-0000-4000-8000-0000000000e4','COM-ELV-0004','student','c0000000-0000-4000-8000-0000000000f4','Lina','Foyer4','active','female');
-- E1 est mineur en interface standard : la regle tient sans l'interface guidee.
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('c0000000-0000-4000-8000-0000000000e1','minor','standard'),
 ('c0000000-0000-4000-8000-0000000000e2','minor','child'),
 ('c0000000-0000-4000-8000-0000000000e3','autonomous','standard'),
 ('c0000000-0000-4000-8000-0000000000e4','minor','child');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('c0000000-0000-4000-8000-0000000000c1','c0000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour Test',1,9,'Europe/Paris'),
 ('c0000000-0000-4000-8000-0000000000c2','c0000000-0000-4000-8000-0000000000b2','enfant',5,'Al-Fajr Test',2,10,'Europe/Paris'),
 ('c0000000-0000-4000-8000-0000000000c3','c0000000-0000-4000-8000-0000000000b3','enfant',5,'Ad-Duha Test',3,11,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('c0000000-0000-4000-8000-0000000000c1','c0000000-0000-4000-8000-0000000000e1'),
 ('c0000000-0000-4000-8000-0000000000c1','c0000000-0000-4000-8000-0000000000e2'),
 ('c0000000-0000-4000-8000-0000000000c1','c0000000-0000-4000-8000-0000000000e3'),
 ('c0000000-0000-4000-8000-0000000000c2','c0000000-0000-4000-8000-0000000000e4');

-- ------------------------------------------------------------
-- 1. ACL, RLS et F86 (proprietaire)
-- ------------------------------------------------------------
DO $acl$
DECLARE
  f regprocedure;
  t text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_lister_fils()'::regprocedure,
    'public.com_lire_fil(uuid)'::regprocedure,
    'public.com_conversations_pour_objet(text,uuid)'::regprocedure,
    'public.com_ouvrir_conversation(text,uuid,text)'::regprocedure,
    'public.com_fil_pour_objet(text,uuid)'::regprocedure,
    'public.com_marquer_lu(uuid)'::regprocedure,
    'public.com_envoyer_message(uuid,text,uuid)'::regprocedure,
    'public.com_annonces_de_classe(uuid)'::regprocedure,
    'public.com_annonce_lire(uuid)'::regprocedure,
    'public.com_annonce_marquer_lue(uuid)'::regprocedure,
    'public.com_annonces_cibles(uuid)'::regprocedure,
    'public.com_annonce_publier(text,text,text,timestamptz,uuid)'::regprocedure,
    'public.com_annonces_administration()'::regprocedure
  ] LOOP
    IF NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : ACL EXECUTE de %', f;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_proc p WHERE p.oid = f AND p.prosecdef
                   AND p.proconfig @> ARRAY['search_path=""']) THEN
      RAISE EXCEPTION 'ROUGE : % sans DEFINER a search_path vide', f;
    END IF;
    IF coalesce(pg_catalog.obj_description(f, 'pg_proc'), '') NOT LIKE
       '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'ROUGE : empreinte F86 de % absente ou perimee', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('ACL EXECUTE, DEFINER et empreintes F86 des 13 RPC');
  FOREACH t IN ARRAY ARRAY['public.com_fils','public.com_messages','public.com_lectures',
                           'public.com_annonces','public.com_annonce_lectures'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid = t::regclass) THEN
      RAISE EXCEPTION 'ROUGE : RLS absente sur %', t;
    END IF;
    IF has_table_privilege('authenticated', t, 'SELECT,INSERT,UPDATE,DELETE')
       OR has_table_privilege('anon', t, 'SELECT,INSERT,UPDATE,DELETE')
       OR has_table_privilege('agent_ro', t, 'SELECT,INSERT,UPDATE,DELETE')
       OR has_table_privilege('service_role', t, 'SELECT,INSERT,UPDATE,DELETE') THEN
      RAISE EXCEPTION 'ROUGE : privilege de table direct sur %', t;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('RLS active et aucun privilege direct sur les 5 tables');
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname = 'private' AND p.proname LIKE 'com\_%'
               AND (has_function_privilege('authenticated', p.oid, 'EXECUTE')
                    OR has_function_privilege('anon', p.oid, 'EXECUTE')
                    OR has_function_privilege('agent_ro', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'ROUGE : un predicat prive com_* est executable par un client';
  END IF;
  PERFORM pg_temp.ok('predicats prives fermes aux clients');
END $acl$;

-- agent_ro : aucune lecture, aucune ecriture.
SET LOCAL ROLE agent_ro;
SELECT pg_temp.refus('SELECT public.com_lister_fils()', '42501', 'agent_ro ne lit pas les fils');
SELECT pg_temp.refus('SELECT count(*) FROM public.com_messages', '42501', 'agent_ro ne lit pas la table des messages');
SELECT pg_temp.refus($$SELECT public.com_annonce_publier('toutes','t','x',NULL,'c0000000-0000-4000-8000-000000000999')$$,
  '42501', 'agent_ro ne publie pas');
RESET ROLE;

-- anon : aucune porte.
SET LOCAL ROLE anon;
SELECT pg_temp.refus('SELECT public.com_lister_fils()', '42501', 'anon refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 2. Messages metier : paires autorisees
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $g1$
DECLARE v jsonb; v_fil jsonb; v_bis jsonb;
BEGIN
  v := public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 2
    AND v -> 0 -> 'interlocuteur' ->> 'id' = 'c0000000-0000-4000-8000-0000000000b1'
    AND v -> 0 -> 'interlocuteur' ->> 'titre' = 'sayyida'
    AND v -> 1 ->> 'nature' = 'administration',
    'tuteur : deux conversations sur la Classe de son enfant (enseignante, Administration)');
  PERFORM pg_temp.vrai(NOT (v::text LIKE '%@%') AND NOT (v::text LIKE '%Foyer2%'),
    'tuteur : aucune coordonnee ni autre foyer dans les conversations');
  v_fil := public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                                          'c0000000-0000-4000-8000-0000000000b1');
  PERFORM pg_temp.vrai(v_fil ->> 'id' IS NOT NULL AND (v_fil ->> 'peut_ecrire')::boolean
    AND v_fil -> 'parties' -> 0 ->> 'nature' = 'foyer'
    AND (v_fil -> 'parties' -> 0 ->> 'est_soi')::boolean
    AND v_fil -> 'parties' -> 0 -> 'eleves' = '["Yasmine"]'::jsonb,
    'tuteur : fil foyer et enseignante ouvert, enfant concerne nomme');
  v_bis := public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                                          'c0000000-0000-4000-8000-0000000000b1');
  PERFORM pg_temp.vrai(v_bis ->> 'id' = v_fil ->> 'id', 'ouverture idempotente : meme fil canonique');
  PERFORM set_config('test.f1', v_fil ->> 'id', true);
  v := public.com_envoyer_message((v_fil ->> 'id')::uuid, '  Salam, une question sur le devoir.  ',
                                  'c0000000-0000-4000-8000-000000000101');
  v_bis := public.com_envoyer_message((v_fil ->> 'id')::uuid, 'Salam, une question sur le devoir.',
                                      'c0000000-0000-4000-8000-000000000101');
  PERFORM pg_temp.vrai(v ->> 'id' = v_bis ->> 'id' AND v ->> 'envoye_le' IS NOT NULL,
    'envoi idempotent : la cle rejouee rend le meme accuse');
  PERFORM pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                         'c0000000-0000-4000-8000-0000000000f2') IS NULL,
    'famille vers famille refusee (paire absente)');
  PERFORM pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                         'c0000000-0000-4000-8000-0000000000b2') IS NULL,
    'tuteur vers un enseignant hors de la Classe refuse');
  PERFORM pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                         'c0000000-0000-4000-8000-0000000000e1') IS NULL,
    'aucun fil direct avec l''enfant mineur');
  PERFORM pg_temp.vrai(jsonb_array_length(public.com_conversations_pour_objet('classe',
                         'c0000000-0000-4000-8000-0000000000c2')) = 0,
    'tuteur : aucune conversation sur une Classe sans enfant du foyer');
  PERFORM pg_temp.refus($$SELECT public.com_envoyer_message('$$ || (v_fil ->> 'id') || $$', '   ', 'c0000000-0000-4000-8000-000000000102')$$,
    '22023', 'message vide refuse');
  PERFORM pg_temp.refus($$SELECT public.com_envoyer_message('$$ || (v_fil ->> 'id') || $$', repeat('x', 5001), 'c0000000-0000-4000-8000-000000000103')$$,
    '22023', 'message de plus de 5000 caracteres refuse');
END $g1$;
RESET ROLE;

-- Le second tuteur du foyer lit le meme fil (tout echange sur un mineur est
-- visible de chacun de ses tuteurs) ; sa lecture est individuelle.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
DO $g1b$
DECLARE v jsonb;
BEGIN
  v := public.com_lister_fils();
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1 AND v -> 0 ->> 'id' = current_setting('test.f1')
    AND (v -> 0 ->> 'non_lus')::int = 1
    AND v -> 0 -> 'messages' -> 0 -> 'auteur' ->> 'prenom' = 'Amina',
    'second tuteur : lit le fil du foyer, 1 non lu, auteur nomme par son prenom');
END $g1b$;
RESET ROLE;

-- L'enseignante voit les quatre conversations de sa Classe et lit le fil.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
DO $t1$
DECLARE v jsonb;
BEGIN
  v := public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 4
    AND (SELECT count(*) FROM jsonb_array_elements(v) e WHERE e ->> 'nature' = 'famille') = 2
    AND (SELECT count(*) FROM jsonb_array_elements(v) e
          WHERE e -> 'interlocuteur' ->> 'id' = 'c0000000-0000-4000-8000-0000000000e3') = 1
    AND (SELECT count(*) FROM jsonb_array_elements(v) e
          WHERE e -> 'interlocuteur' ->> 'id' = 'c0000000-0000-4000-8000-0000000000e1') = 0,
    'enseignante : deux foyers, l''eleve adulte, l''Administration ; jamais le mineur');
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  PERFORM pg_temp.vrai(v IS NOT NULL AND (v ->> 'non_lus')::int = 1, 'enseignante : lit le fil, 1 non lu');
  PERFORM public.com_marquer_lu(current_setting('test.f1')::uuid);
  PERFORM pg_temp.vrai((public.com_lire_fil(current_setting('test.f1')::uuid) ->> 'non_lus')::int = 0,
    'marquer lu : non lus a zero pour l''enseignante');
  PERFORM public.com_envoyer_message(current_setting('test.f1')::uuid, 'Wa alaykum salam.',
                                     'c0000000-0000-4000-8000-000000000104');
  PERFORM pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                         'c0000000-0000-4000-8000-0000000000b2') IS NULL,
    'enseignant vers enseignant refuse');
  v := public.com_fil_pour_objet('eleve','c0000000-0000-4000-8000-0000000000e2');
  PERFORM pg_temp.vrai(v IS NOT NULL AND v -> 'parties' -> 0 ->> 'id' = 'c0000000-0000-4000-8000-0000000000f2'
    AND v -> 'objet' ->> 'prenom' = 'Adam',
    'fil sur un eleve mineur : ouvert avec son foyer, jamais avec lui');
  PERFORM pg_temp.vrai(public.com_fil_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1') IS NULL,
    'filPourObjet ambigu (plusieurs paires) rend null');
  v := public.com_conversations_pour_objet('eleve','c0000000-0000-4000-8000-0000000000e3');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1
    AND v -> 0 -> 'interlocuteur' ->> 'id' = 'c0000000-0000-4000-8000-0000000000e3',
    'eleve adulte : conversation directe avec son enseignante');
  v := public.com_conversations_pour_objet('dossier','c0000000-0000-4000-8000-0000000000b1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1 AND v -> 0 ->> 'nature' = 'administration',
    'dossier professionnel : enseignante et Administration');
  PERFORM pg_temp.vrai(public.com_annonces_cibles('c0000000-0000-4000-8000-0000000000c1')
                         = '[{"id":"classe:c0000000-0000-4000-8000-0000000000c1","nature":"classe","libelle":"An-Nour Test","classe_id":"c0000000-0000-4000-8000-0000000000c1"}]'::jsonb,
    'cibles enseignante : sa Classe seulement');
  PERFORM pg_temp.vrai(public.com_annonces_cibles('c0000000-0000-4000-8000-0000000000c2') = '[]'::jsonb
    AND jsonb_array_length(public.com_annonces_cibles(NULL)) = 1,
    'cibles enseignante : aucune autre Classe, aucun public');
END $t1$;
RESET ROLE;

-- Un autre foyer, un autre enseignant, le controleur, l'Administration et le
-- comptable ne lisent pas le fil foyer et enseignante.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d3','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_lire_fil(current_setting('test.f1')::uuid) IS NULL, 'autre foyer : fil absent');
SELECT pg_temp.vrai(jsonb_array_length(public.com_lister_fils()) = 1
  AND public.com_lister_fils() -> 0 -> 'objet' ->> 'prenom' = 'Adam'
  AND NOT public.com_lister_fils()::text LIKE '%' || current_setting('test.f1') || '%',
  'autre foyer : seul le fil de son enfant est liste');
SELECT pg_temp.refus($$SELECT public.com_envoyer_message('$$ || current_setting('test.f1') || $$', 'intrusion', 'c0000000-0000-4000-8000-000000000105')$$,
  '42501', 'autre foyer : envoi refuse');
SELECT pg_temp.refus($$SELECT public.com_marquer_lu('$$ || current_setting('test.f1') || $$')$$,
  '42501', 'autre foyer : marquer lu refuse');
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b2','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_lire_fil(current_setting('test.f1')::uuid) IS NULL, 'autre enseignant : fil absent');
SELECT pg_temp.vrai(public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1') = '[]'::jsonb,
  'autre enseignant : aucune conversation sur une Classe qui n''est pas la sienne');
SELECT pg_temp.refus($$SELECT public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c1')$$,
  '42501', 'autre enseignant : annonces d''une Classe qui n''est pas la sienne refusees');
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000a3','controller');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_lire_fil(current_setting('test.f1')::uuid) IS NULL
  AND public.com_lister_fils() = '[]'::jsonb
  AND public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1') = '[]'::jsonb,
  'controleur : aucun fil hors de sa mission (B-12)');
SELECT pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1','t','x',NULL,'c0000000-0000-4000-8000-000000000106')$$,
  '42501', 'controleur : publication refusee');
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $adm$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.vrai(public.com_lire_fil(current_setting('test.f1')::uuid) IS NULL,
    'Administration : ne lit pas un fil dont elle n''est pas partie (C6)');
  v := public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 3
    AND (SELECT count(*) FROM jsonb_array_elements(v) e
          WHERE e -> 'interlocuteur' ->> 'id' = 'c0000000-0000-4000-8000-0000000000e3') = 0,
    'Administration : enseignante et deux foyers, pas l''eleve adulte (C4)');
  v := public.com_conversations_pour_objet('dossier','c0000000-0000-4000-8000-0000000000d1');
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 1
    AND v -> 0 -> 'interlocuteur' ->> 'id' = 'c0000000-0000-4000-8000-0000000000f1',
    'dossier d''un tuteur : fil avec son foyer');
  v := public.com_fil_pour_objet('dossier','c0000000-0000-4000-8000-0000000000d1');
  PERFORM public.com_envoyer_message((v ->> 'id')::uuid, 'Votre dossier est complet.',
                                     'c0000000-0000-4000-8000-000000000107');
  PERFORM set_config('test.fdossier', v ->> 'id', true);
END $adm$;
RESET ROLE;

-- Le tuteur voit l'Administration sans le nom de la personne qui a ecrit.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (public.com_lire_fil(current_setting('test.fdossier')::uuid) -> 'messages' -> 0 -> 'auteur')
    = '{"id":"administration","nature":"equipe","fonction":"administration","est_soi":false}'::jsonb,
  'message de l''Administration : auteur rendu comme equipe, sans nom');
RESET ROLE;

-- Profil de paiement : comptable et enseignante (C7) ; le comptable ne lit rien d'autre.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000a2','accountant');
SET LOCAL ROLE authenticated;
DO $cpt$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.vrai(public.com_lire_fil(current_setting('test.f1')::uuid) IS NULL
    AND public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1') = '[]'::jsonb,
    'comptable : aucun fil de Classe');
  v := public.com_fil_pour_objet('profilPaiement','c0000000-0000-4000-8000-0000000000b1');
  PERFORM pg_temp.vrai(v IS NOT NULL AND (v ->> 'peut_ecrire')::boolean, 'comptable : fil profil de paiement ouvert');
  PERFORM public.com_envoyer_message((v ->> 'id')::uuid, 'Merci de completer votre profil de paiement.',
                                     'c0000000-0000-4000-8000-000000000108');
  PERFORM set_config('test.fpaie', v ->> 'id', true);
  PERFORM pg_temp.vrai(public.com_fil_pour_objet('profilPaiement','c0000000-0000-4000-8000-0000000000d1') IS NULL,
    'profil de paiement d''un non-enseignant : aucun fil');
END $cpt$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.com_lire_fil(current_setting('test.fpaie')::uuid) ->> 'non_lus')::int = 1,
  'enseignante : lit la relance du comptable');
RESET ROLE;

-- Un eleve adulte ecrit a son enseignante, pas a un autre eleve ni a
-- l'Administration.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000e3','student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                      'c0000000-0000-4000-8000-0000000000b1') IS NOT NULL,
  'eleve adulte : fil avec son enseignante');
SELECT pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                      'c0000000-0000-4000-8000-0000000000e2') IS NULL
  AND public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                      'c0000000-0000-4000-8000-0000000000f2') IS NULL,
  'eleve vers eleve et eleve vers famille refuses');
SELECT pg_temp.vrai(public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                      'administration') IS NULL,
  'eleve adulte vers Administration refuse (C4)');
SELECT pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1','t','x',NULL,'c0000000-0000-4000-8000-000000000109')$$,
  '42501', 'eleve adulte : publication refusee');
RESET ROLE;

-- Le mineur n'a aucune messagerie (il lit les annonces de sa Classe, plus bas).
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000e1','student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus('SELECT public.com_lister_fils()', '42501', 'mineur : liste des fils refusee');
SELECT pg_temp.refus($$SELECT public.com_lire_fil('$$ || current_setting('test.f1') || $$')$$,
  '42501', 'mineur : lecture du fil de son foyer refusee');
SELECT pg_temp.refus($$SELECT public.com_envoyer_message('$$ || current_setting('test.f1') || $$', 'coucou', 'c0000000-0000-4000-8000-000000000110')$$,
  '42501', 'mineur : envoi refuse');
SELECT pg_temp.refus($$SELECT public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c1')$$,
  '42501', 'mineur : conversations refusees');
SELECT pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1','t','x',NULL,'c0000000-0000-4000-8000-000000000111')$$,
  '42501', 'mineur : publication refusee');
RESET ROLE;

-- Jeton dont le role ne correspond pas au compte : refuse.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus('SELECT public.com_lister_fils()', '42501', 'role du jeton different du compte : refuse');
SELECT pg_temp.refus($$SELECT public.com_annonce_publier('toutes','t','x',NULL,'c0000000-0000-4000-8000-000000000112')$$,
  '42501', 'tuteur avec jeton admin : publication refusee');
RESET ROLE;

-- ------------------------------------------------------------
-- 3. Annonces
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
DO $ann_t1$
DECLARE v jsonb; v_bis jsonb;
BEGIN
  v := public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1',
         'Seance de jeudi', 'Pensez a reviser la sourate.', NULL, 'c0000000-0000-4000-8000-000000000201');
  v_bis := public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1',
         'Seance de jeudi', 'Pensez a reviser la sourate.', NULL, 'c0000000-0000-4000-8000-000000000201');
  PERFORM pg_temp.vrai(v ->> 'etat' = 'publiee' AND v ->> 'id' = v_bis ->> 'id',
    'enseignante : annonce publiee pour sa Classe, cle rejouee idempotente');
  PERFORM set_config('test.a1', v ->> 'id', true);
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c2','t','x',NULL,'c0000000-0000-4000-8000-000000000202')$$,
    '42501', 'enseignante : publication pour une autre Classe refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('toutes','t','x',NULL,'c0000000-0000-4000-8000-000000000203')$$,
    '42501', 'enseignante : annonce globale refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('familles','t','x',NULL,'c0000000-0000-4000-8000-000000000204')$$,
    '42501', 'enseignante : annonce par public refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1','t','x',now() + interval '1 day','c0000000-0000-4000-8000-000000000205')$$,
    '42501', 'enseignante : programmation refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1',repeat('t',121),'x',NULL,'c0000000-0000-4000-8000-000000000206')$$,
    '22023', 'titre de plus de 120 caracteres refuse');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('classe:pas-un-uuid','t','x',NULL,'c0000000-0000-4000-8000-000000000207')$$,
    '22023', 'audience mal formee refusee');
  PERFORM pg_temp.refus('SELECT public.com_annonces_administration()', '42501',
    'enseignante : vue de l''Administration refusee');
  PERFORM pg_temp.vrai((public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c1') ->> 'peut_publier')::boolean,
    'enseignante : capacite publier sur sa Classe');
END $ann_t1$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
DO $ann_adm$
DECLARE v jsonb;
BEGIN
  v := public.com_annonces_cibles(NULL);
  PERFORM pg_temp.vrai(jsonb_array_length(v) = 6
    AND v -> 0 ->> 'nature' IN ('toutes','public'),
    'Administration : trois publics et les trois Classes actives');
  v := public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1',
         'Vacances', 'Pas de seance la semaine prochaine.', now() + interval '1 day',
         'c0000000-0000-4000-8000-000000000208');
  PERFORM pg_temp.vrai(v ->> 'etat' = 'planifiee', 'Administration : annonce programmee');
  PERFORM set_config('test.a2', v ->> 'id', true);
  PERFORM pg_temp.vrai(public.com_annonce_publier('toutes', 'Ramadan', 'Horaires adaptes.', NULL,
                         'c0000000-0000-4000-8000-000000000209') ->> 'etat' = 'publiee',
    'Administration : annonce globale publiee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('toutes','t','x',now() + interval '20 days','c0000000-0000-4000-8000-000000000210')$$,
    '22023', 'programmation au-dela de 14 jours refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('toutes','t','x',now() + interval '1 minute','c0000000-0000-4000-8000-000000000211')$$,
    '22023', 'programmation a moins de 5 minutes refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('autre-public','t','x',NULL,'c0000000-0000-4000-8000-000000000212')$$,
    '22023', 'audience inconnue refusee');
  v := public.com_annonces_administration();
  PERFORM pg_temp.vrai(jsonb_array_length(v -> 'publiees') = 2 AND jsonb_array_length(v -> 'planifiees') = 1
    AND v -> 'planifiees' -> 0 ->> 'id' = current_setting('test.a2'),
    'Administration : 2 publiees, 1 planifiee');
END $ann_adm$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $ann_g1$
DECLARE v jsonb;
BEGIN
  v := public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c1');
  PERFORM pg_temp.vrai(jsonb_array_length(v -> 'annonces') = 1
    AND v -> 'annonces' -> 0 ->> 'id' = current_setting('test.a1')
    AND NOT (v ->> 'peut_publier')::boolean
    AND v -> 'annonces' -> 0 -> 'auteur' ->> 'fonction' = 'enseignant',
    'tuteur : lit l''annonce diffusee, pas la programmee, sans capacite de publier');
  PERFORM pg_temp.vrai(public.com_annonce_lire(current_setting('test.a2')::uuid) IS NULL,
    'tuteur : annonce programmee invisible avant sa date');
  PERFORM public.com_annonce_marquer_lue(current_setting('test.a1')::uuid);
  PERFORM pg_temp.vrai((public.com_annonce_lire(current_setting('test.a1')::uuid) ->> 'lue')::boolean,
    'tuteur : annonce marquee lue');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c1','t','x',NULL,'c0000000-0000-4000-8000-000000000213')$$,
    '42501', 'tuteur : publication refusee');
  PERFORM pg_temp.refus($$SELECT public.com_annonce_publier('toutes','','',NULL,'c0000000-0000-4000-8000-000000000215')$$,
    '42501', 'tuteur : refus de role avant toute validation du contenu');
END $ann_g1$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.com_annonce_lire(current_setting('test.a1')::uuid) ->> 'lue')::boolean,
  'lecture d''annonce individuelle : le second tuteur ne l''a pas lue');
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000e2','student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(jsonb_array_length(public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c1') -> 'annonces') = 1,
  'mineur membre : lit les annonces de sa Classe');
SELECT pg_temp.refus($$SELECT public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c2')$$,
  '42501', 'mineur : annonces d''une autre Classe refusees');
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d4','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c1')$$,
  '42501', 'tuteur d''une autre Classe : annonces refusees');
SELECT pg_temp.vrai(public.com_annonce_lire(current_setting('test.a1')::uuid) IS NULL,
  'tuteur d''une autre Classe : annonce absente');
SELECT pg_temp.refus($$SELECT public.com_annonce_marquer_lue('$$ || current_setting('test.a1') || $$')$$,
  '42501', 'tuteur d''une autre Classe : marquer lue refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 4. Comptes desactives
-- ------------------------------------------------------------
UPDATE public.profiles SET account_status = 'disabled'
 WHERE id IN ('c0000000-0000-4000-8000-0000000000b3','c0000000-0000-4000-8000-0000000000d2');
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b3','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.com_annonce_publier('classe:c0000000-0000-4000-8000-0000000000c3','t','x',NULL,'c0000000-0000-4000-8000-000000000214')$$,
  '42501', 'enseignant desactive : publication refusee sur sa Classe');
SELECT pg_temp.refus($$SELECT public.com_annonces_de_classe('c0000000-0000-4000-8000-0000000000c3')$$,
  '42501', 'enseignant desactive : lecture des annonces refusee');
RESET ROLE;
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus('SELECT public.com_lister_fils()', '42501', 'tuteur desactive : fils refuses');
RESET ROLE;
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000a1','admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c3') = '[]'::jsonb,
  'enseignant desactive : plus aucune paire sur sa Classe');
RESET ROLE;
-- Un enseignant desactive n'est plus l'interlocuteur des familles.
UPDATE public.profiles SET account_status = 'disabled' WHERE id = 'c0000000-0000-4000-8000-0000000000b2';
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d4','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(jsonb_array_length(public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c2')) = 1
  AND public.com_conversations_pour_objet('classe','c0000000-0000-4000-8000-0000000000c2') -> 0 ->> 'nature' = 'administration',
  'enseignant desactive : la famille ne garde que l''Administration');
RESET ROLE;
UPDATE public.profiles SET account_status = 'provisional_active' WHERE id = 'c0000000-0000-4000-8000-0000000000b2';
-- Un foyer sans tuteur valide n'est plus une partie.
UPDATE public.profiles SET account_status = 'disabled' WHERE id = 'c0000000-0000-4000-8000-0000000000d3';
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_conversations_pour_objet('eleve','c0000000-0000-4000-8000-0000000000e2') = '[]'::jsonb,
  'foyer sans tuteur valide : plus aucune paire');
RESET ROLE;
UPDATE public.profiles SET account_status = 'active' WHERE id = 'c0000000-0000-4000-8000-0000000000d3';

-- ------------------------------------------------------------
-- 5. Paire retiree (C5) : l'enfant quitte la Classe
-- ------------------------------------------------------------
UPDATE public.groupe_membres SET left_at = now(),
  left_by = 'c0000000-0000-4000-8000-0000000000a1', left_reason = 'test COM-BACK-1'
 WHERE student_id = 'c0000000-0000-4000-8000-0000000000e1' AND left_at IS NULL;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.com_lire_fil(current_setting('test.f1')::uuid) IS NULL,
  'paire retiree : l''enseignante ne lit plus le fil');
SELECT pg_temp.refus($$SELECT public.com_envoyer_message('$$ || current_setting('test.f1') || $$', 'encore', 'c0000000-0000-4000-8000-000000000113')$$,
  '42501', 'paire retiree : l''enseignante n''ecrit plus');
RESET ROLE;
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT (public.com_lire_fil(current_setting('test.f1')::uuid) ->> 'peut_ecrire')::boolean
  AND jsonb_array_length(public.com_lire_fil(current_setting('test.f1')::uuid) -> 'messages') = 2,
  'paire retiree : le foyer garde l''historique en lecture seule');
SELECT pg_temp.refus($$SELECT public.com_envoyer_message('$$ || current_setting('test.f1') || $$', 'encore', 'c0000000-0000-4000-8000-000000000114')$$,
  '42501', 'paire retiree : le foyer n''ecrit plus');
RESET ROLE;

-- ------------------------------------------------------------
-- 6. Invariants de table (proprietaire)
-- ------------------------------------------------------------
SELECT pg_temp.refus($$INSERT INTO public.com_fils(type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
  VALUES ('classe','c0000000-0000-4000-8000-0000000000c1','profil','c0000000-0000-4000-8000-0000000000e2','profil','c0000000-0000-4000-8000-0000000000b1')$$,
  '23514', 'un mineur ne peut jamais etre partie d''un fil');
SELECT pg_temp.refus($$UPDATE public.com_messages SET texte = 'modifie'$$, '55000', 'message non modifiable');
SELECT pg_temp.refus($$DELETE FROM public.com_messages$$, '55000', 'message non supprimable');
SELECT pg_temp.refus($$UPDATE public.com_annonces SET titre = 'modifie'$$, '55000', 'annonce non modifiable');
SELECT pg_temp.refus($$DELETE FROM public.com_annonces$$, '55000', 'annonce non supprimable');
SELECT pg_temp.vrai((SELECT count(*) FROM public.com_messages WHERE fil_id = current_setting('test.f1')::uuid) = 2,
  'idempotence : deux messages seulement dans le fil (cle rejouee)');
SELECT pg_temp.vrai((SELECT bool_and(envoye_le AT TIME ZONE 'UTC' IS NOT NULL)
                       AND pg_typeof(min(envoye_le))::text = 'timestamp with time zone'
                     FROM public.com_messages), 'horodatage en timestamptz');

DO $fin$
BEGIN
  IF current_setting('test.com_n')::int <> 101 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 101 attendus', current_setting('test.com_n');
  END IF;
  RAISE NOTICE 'COM-BACK-1 : % controles verts', current_setting('test.com_n');
END $fin$;

ROLLBACK;
