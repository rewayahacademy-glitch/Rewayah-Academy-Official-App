-- IMAGES-MESSAGERIE (16/11/2026) : images de messagerie et coeurs, partie serveur.
-- RLS (un non-participant est refuse), mineur refuse, limite de 20 par heure,
-- confirmation signee, coeur pose / retire / compte, image expiree lue comme
-- supprimee, purge reservee au role de service.
-- A rejouer sur une base NEUVE apres toutes les migrations (fixtures annulees).
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


-- Le secret de confirmation (le meme que celui de la bibliotheque, fixture de test).
INSERT INTO private.library_upload_confirmation_secrets(singleton, secret)
VALUES (true, 'secret-de-test-images-messagerie-0123456789')
ON CONFLICT (singleton) DO UPDATE SET secret = EXCLUDED.secret;

CREATE FUNCTION pg_temp.signature(p_id uuid, p_sha text, p_octets bigint) RETURNS text
LANGUAGE sql AS $$
  SELECT pg_catalog.encode(extensions.hmac(
    pg_catalog.convert_to('message-image-v1' || E'\n' || p_id::text || E'\n' || p_sha || E'\n' || p_octets::text, 'UTF8'),
    pg_catalog.convert_to('secret-de-test-images-messagerie-0123456789', 'UTF8'), 'sha256'), 'hex')
$$;
GRANT EXECUTE ON FUNCTION pg_temp.signature(uuid, text, bigint) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text) TO service_role;

-- ------------------------------------------------------------
-- 1. Droits : RLS, aucun privilege d'ecriture, fonctions fermees
-- ------------------------------------------------------------
DO $acl$
DECLARE f regprocedure;
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid = 'public.com_message_images'::regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid = 'public.com_message_coeurs'::regclass) THEN
    RAISE EXCEPTION 'ROUGE : RLS absente';
  END IF;
  IF has_table_privilege('authenticated', 'public.com_message_images', 'INSERT,UPDATE,DELETE')
     OR has_table_privilege('authenticated', 'public.com_message_coeurs', 'INSERT,UPDATE,DELETE')
     OR has_table_privilege('anon', 'public.com_message_images', 'SELECT')
     OR has_table_privilege('service_role', 'public.com_message_images', 'INSERT,UPDATE,DELETE')
     OR has_table_privilege('agent_ro', 'public.com_message_images', 'SELECT,INSERT,UPDATE,DELETE')
     OR has_table_privilege('agent_ro', 'public.com_message_coeurs', 'SELECT,INSERT,UPDATE,DELETE')
     OR has_column_privilege('authenticated', 'public.com_message_images', 'cle_r2', 'SELECT')
     OR has_column_privilege('authenticated', 'public.com_message_images', 'cle_miniature', 'SELECT') THEN
    RAISE EXCEPTION 'ROUGE : privilege de table ou de colonne inattendu';
  END IF;
  PERFORM pg_temp.ok('RLS active, aucune ecriture directe, cles R2 illisibles par un client');
  FOREACH f IN ARRAY ARRAY[
    'public.message_image_demander(uuid,text,bigint,text,bigint,integer,integer,text)'::regprocedure,
    'public.message_image_lire_depot(uuid)'::regprocedure,
    'public.message_image_confirmer(uuid,text,text,text,text)'::regprocedure,
    'public.message_image_annuler(uuid)'::regprocedure,
    'public.message_images_a_signer(uuid,uuid)'::regprocedure,
    'public.aimer_message(uuid)'::regprocedure,
    'public.ne_plus_aimer_message(uuid)'::regprocedure] LOOP
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
  END LOOP;
  PERFORM pg_temp.ok('RPC clientes : authenticated seul, DEFINER a search_path vide');
  FOREACH f IN ARRAY ARRAY[
    'public.message_images_purge_lire(integer)'::regprocedure,
    'public.message_images_purge_marquer(uuid[])'::regprocedure] LOOP
    IF has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE')
       OR NOT has_function_privilege('service_role', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE : ACL EXECUTE de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('RPC de purge : role de service seul');
  IF has_function_privilege('authenticated', 'private.com_image_droits(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.com_coeur_poser(uuid,boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE : predicat prive executable par un client';
  END IF;
  PERFORM pg_temp.ok('predicats prives fermes aux clients');
END $acl$;

-- ------------------------------------------------------------
-- 2. Un fil, des messages
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $fil$
DECLARE v_fil jsonb; v jsonb;
BEGIN
  v_fil := public.com_ouvrir_conversation('classe','c0000000-0000-4000-8000-0000000000c1',
                                          'c0000000-0000-4000-8000-0000000000b1');
  PERFORM set_config('test.f1', v_fil ->> 'id', true);
  v := public.com_envoyer_message((v_fil ->> 'id')::uuid, 'Voici la page.', 'c0000000-0000-4000-8000-000000000201');
  PERFORM set_config('test.m1', v ->> 'id', true);
  v := public.com_envoyer_message((v_fil ->> 'id')::uuid, 'Et la suivante.', 'c0000000-0000-4000-8000-000000000202');
  PERFORM set_config('test.m2', v ->> 'id', true);
  PERFORM pg_temp.ok('fixture : un fil et deux messages de la tutrice');
END $fil$;
RESET ROLE;

-- ------------------------------------------------------------
-- 3. Mineur refuse, non-participant refuse
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000e1','student');
SET LOCAL ROLE authenticated;
DO $mineur$
DECLARE v_msg text;
BEGIN
  BEGIN
    PERFORM public.message_image_demander(current_setting('test.m1')::uuid, 'image/jpeg', 1000, 'image/jpeg', 100, 800, 600, NULL);
    RAISE EXCEPTION 'ROUGE : un mineur a depose une image';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    PERFORM pg_temp.vrai(SQLSTATE = '42501' AND v_msg = 'ImageMineurRefuse', 'eleve mineur : refus net ImageMineurRefuse');
  END;
END $mineur$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d3','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.message_image_demander(current_setting('test.m1')::uuid, 'image/jpeg', 1000, 'image/jpeg', 100, 800, 600, NULL)$$,
  '42501', 'non-participant : depot refuse');
SELECT pg_temp.refus($$SELECT public.message_images_a_signer(current_setting('test.f1')::uuid, NULL)$$,
  '42501', 'non-participant : lecture des images refusee');
SELECT pg_temp.refus($$SELECT public.aimer_message(current_setting('test.m1')::uuid)$$,
  '42501', 'non-participant : coeur refuse');
SELECT pg_temp.refus($$SELECT public.ne_plus_aimer_message(current_setting('test.m1')::uuid)$$,
  '42501', 'non-participant : retrait de coeur refuse');
RESET ROLE;

-- ------------------------------------------------------------
-- 4. Depot, relecture, confirmation signee (la tutrice)
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $depot$
DECLARE v jsonb; v2 jsonb; v_id uuid; v_sha text := repeat('ab', 32);
BEGIN
  v := public.message_image_demander(current_setting('test.m1')::uuid, 'image/jpeg', 150000, 'image/webp', 8000, 800, 600, '#A1B2C3');
  v_id := (v ->> 'image_id')::uuid;
  PERFORM set_config('test.i1', v ->> 'image_id', true);
  PERFORM pg_temp.vrai((v ->> 'cle_r2') = 'fils/' || current_setting('test.f1') || '/' || (v ->> 'image_id') || '.jpg'
    AND (v ->> 'cle_miniature') = 'fils/' || current_setting('test.f1') || '/' || (v ->> 'image_id') || '-min.webp',
    'cles fabriquees par le serveur : fils/<fil>/<uuid>.jpg et -min.webp');
  v2 := public.message_image_demander(current_setting('test.m1')::uuid, 'image/jpeg', 150001, 'image/webp', 8000, 800, 600, '#a1b2c3');
  PERFORM pg_temp.vrai(v2 ->> 'image_id' = v ->> 'image_id', 'redemande du meme depot : meme image, memes cles');
  PERFORM pg_temp.refus($$SELECT public.message_image_demander(current_setting('test.m1')::uuid, 'image/png', 1000, 'image/webp', 8000, 800, 600, NULL)$$,
    '23505', 'une seule image par message (autre type : refus)');
  PERFORM pg_temp.refus($$SELECT public.message_image_demander(current_setting('test.m2')::uuid, 'image/gif', 1000, 'image/webp', 8000, 800, 600, NULL)$$,
    '22023', 'type GIF refuse');
  PERFORM pg_temp.refus($$SELECT public.message_image_demander(current_setting('test.m2')::uuid, 'image/jpeg', 2097153, 'image/webp', 8000, 800, 600, NULL)$$,
    '22023', 'image de plus de 2 Mo refusee');
  PERFORM pg_temp.refus($$SELECT public.message_image_demander(current_setting('test.m2')::uuid, 'image/jpeg', 1000, 'image/webp', 102401, 800, 600, NULL)$$,
    '22023', 'miniature de plus de 100 Ko refusee');
  PERFORM pg_temp.refus($$SELECT public.message_image_demander(current_setting('test.m2')::uuid, 'image/jpeg', 1000, 'image/webp', 100, 800, 600, 'rouge')$$,
    '22023', 'couleur moyenne invalide refusee');
  PERFORM pg_temp.refus($$SELECT public.message_image_demander('c0000000-0000-4000-8000-00000000dead', 'image/jpeg', 1000, 'image/webp', 100, 800, 600, NULL)$$,
    '42501', 'message inconnu : refus');
  v2 := public.message_image_lire_depot(v_id);
  PERFORM pg_temp.vrai(v2 ->> 'cle_r2' = v ->> 'cle_r2' AND (v2 ->> 'octets')::int = 150001,
    'relecture du depot par son auteur');
  -- Avant confirmation : l'autre tuteur du foyer ne voit pas l'image en attente.
  PERFORM pg_temp.refus(format($$SELECT public.message_image_confirmer('%s', '%s', 'image/jpeg', 'image/webp', '%s')$$,
      v_id, v_sha, repeat('0', 64)),
    '42501', 'confirmation : signature fausse refusee');
  PERFORM pg_temp.refus(format($$SELECT public.message_image_confirmer('%s', 'pasunsha', 'image/jpeg', 'image/webp', '%s')$$,
      v_id, repeat('0', 64)),
    '42501', 'confirmation : empreinte mal formee refusee');
END $depot$;
RESET ROLE;

-- Le second tuteur du foyer : en attente, il ne voit rien ; il ne confirme pas.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
DO $attente$
DECLARE v jsonb; m jsonb;
BEGIN
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  SELECT e INTO m FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1');
  -- IMAGES-CORRECTIF : le message dont l'image n'est pas confirmee n'est rendu qu'a son auteur.
  PERFORM pg_temp.vrai(m IS NULL
    AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1')),
    'lecture du fil : le message dont l''image est en attente n''est pas rendu a l''autre tuteur');
  PERFORM pg_temp.vrai((v ->> 'non_lus')::int = 1,
    'lecture du fil : le message dont l''image est en attente ne compte pas dans les non lus');
  PERFORM pg_temp.vrai(public.message_images_a_signer(current_setting('test.f1')::uuid, NULL) = '[]'::jsonb,
    'liste des images : une image en attente n''est pas rendue a l''autre tuteur');
  PERFORM pg_temp.refus(format($$SELECT public.message_image_confirmer('%s', '%s', 'image/jpeg', 'image/webp', '%s')$$,
      current_setting('test.i1'), repeat('ab', 32), pg_temp.signature(current_setting('test.i1')::uuid, repeat('ab', 32), 150001)),
    '42501', 'confirmation par un autre que l''auteur refusee');
END $attente$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $confirmer$
DECLARE v jsonb; m jsonb;
BEGIN
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  SELECT e INTO m FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1');
  PERFORM pg_temp.vrai(m -> 'image' ->> 'etat' = 'en_attente' AND (m -> 'image' ->> 'largeur')::int = 800,
    'l''auteur voit son image en attente dans la lecture du fil');
  PERFORM pg_temp.refus(format($$SELECT public.message_image_confirmer('%s', '%s', 'image/png', 'image/webp', '%s')$$,
      current_setting('test.i1'), repeat('ab', 32), pg_temp.signature(current_setting('test.i1')::uuid, repeat('ab', 32), 150001)),
    '22023', 'confirmation : type reel different du type annonce refuse');
  v := public.message_image_confirmer(current_setting('test.i1')::uuid, repeat('ab', 32), 'image/jpeg', 'image/webp',
         pg_temp.signature(current_setting('test.i1')::uuid, repeat('ab', 32), 150001));
  PERFORM pg_temp.vrai(v ->> 'etat' = 'confirmee', 'confirmation signee : etat confirmee');
  PERFORM pg_temp.refus(format($$SELECT public.message_image_confirmer('%s', '%s', 'image/jpeg', 'image/webp', '%s')$$,
      current_setting('test.i1'), repeat('ab', 32), pg_temp.signature(current_setting('test.i1')::uuid, repeat('ab', 32), 150001)),
    '42501', 'confirmation rejouee : refusee');
END $confirmer$;
RESET ROLE;

-- ------------------------------------------------------------
-- 5. Lecture : metadonnees dans le fil, cles en une fois, RLS de la table
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
DO $lecture$
DECLARE v jsonb; m jsonb; l jsonb;
BEGIN
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  SELECT e INTO m FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1');
  PERFORM pg_temp.vrai(m -> 'image' ->> 'id' = current_setting('test.i1')
    AND m -> 'image' ->> 'etat' = 'confirmee'
    AND (m -> 'image' ->> 'largeur')::int = 800 AND (m -> 'image' ->> 'hauteur')::int = 600
    AND m -> 'image' ->> 'couleur_moyenne' = '#a1b2c3'
    AND NOT (m -> 'image' ? 'cle_r2') AND NOT (m::text LIKE '%fils/%'),
    'lecture du fil : id, largeur, hauteur, couleur_moyenne, etat ; aucune cle R2');
  l := public.message_images_a_signer(current_setting('test.f1')::uuid, NULL);
  PERFORM pg_temp.vrai(jsonb_array_length(l) = 1 AND l -> 0 ->> 'etat' = 'confirmee'
    AND l -> 0 ->> 'cle' LIKE 'fils/%-min.webp' AND l -> 0 ->> 'mime' = 'image/webp',
    'liste : la miniature du fil, en un seul appel');
  l := public.message_images_a_signer(current_setting('test.f1')::uuid, current_setting('test.i1')::uuid);
  PERFORM pg_temp.vrai(jsonb_array_length(l) = 1 AND l -> 0 ->> 'cle' LIKE 'fils/%.jpg'
    AND l -> 0 ->> 'cle' NOT LIKE '%-min.%' AND l -> 0 ->> 'mime' = 'image/jpeg',
    'image precise : la cle de l''image complete');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.com_message_images) = 1,
    'RLS : un participant lit la ligne de l''image');
  PERFORM pg_temp.refus($$SELECT cle_r2 FROM public.com_message_images$$, '42501',
    'la cle R2 n''est pas une colonne lisible par un client');
  PERFORM pg_temp.refus($$INSERT INTO public.com_message_images(message_id) VALUES (gen_random_uuid())$$, '42501',
    'aucune ecriture directe dans la table des images');
END $lecture$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d3','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.com_message_images) = 0
  AND (SELECT count(*) FROM public.com_message_coeurs) = 0,
  'RLS : un non-participant ne lit aucune image ni aucun coeur');
RESET ROLE;

-- ------------------------------------------------------------
-- 5 bis. IMAGES-CORRECTIF : confirmee_le, depot annule, liste des fils
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $corr1$
DECLARE v jsonb; m jsonb; v_id uuid; l jsonb;
BEGIN
  PERFORM pg_temp.vrai((SELECT confirmee_le IS NOT NULL FROM public.com_message_images
                         WHERE id = current_setting('test.i1')::uuid),
    'la confirmation pose confirmee_le');
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  SELECT e INTO m FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1');
  PERFORM pg_temp.vrai(m IS NOT NULL, 'l''auteur voit son message une fois l''image confirmee');
  -- Un message dont le depot est annule : rendu a personne, pas meme a son auteur.
  v := public.com_envoyer_message(current_setting('test.f1')::uuid, '[image]', 'c0000000-0000-4000-8000-000000000203');
  PERFORM set_config('test.m3', v ->> 'id', true);
  v := public.message_image_demander(current_setting('test.m3')::uuid, 'image/jpeg', 1000, 'image/webp', 100, 80, 60, NULL);
  v_id := (v ->> 'image_id')::uuid;
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  SELECT e INTO m FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m3');
  PERFORM pg_temp.vrai(m IS NOT NULL AND m -> 'image' ->> 'etat' = 'en_attente',
    'l''auteur voit son message dont l''image est en attente');
  l := public.com_lister_fils();
  PERFORM pg_temp.vrai((SELECT e -> 'messages' -> -1 ->> 'id' FROM jsonb_array_elements(l) e
                         WHERE e ->> 'id' = current_setting('test.f1')) = current_setting('test.m3'),
    'liste des fils : l''auteur voit son message en attente comme dernier message');
  PERFORM pg_temp.vrai(public.message_image_annuler(v_id), 'depot annule');
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m3')),
    'depot annule (supprimee sans confirmee_le) : le message n''est rendu a personne, pas meme a son auteur');
  l := public.com_lister_fils();
  PERFORM pg_temp.vrai((SELECT e -> 'messages' -> -1 ->> 'id' FROM jsonb_array_elements(l) e
                         WHERE e ->> 'id' = current_setting('test.f1')) = current_setting('test.m2'),
    'liste des fils : le message annule n''est plus le dernier message');
END $corr1$;
RESET ROLE;

-- Un message dont l'image est en attente n'est jamais le dernier message de la liste de l'autre tuteur.
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $corr2$
DECLARE v jsonb;
BEGIN
  v := public.com_envoyer_message(current_setting('test.f1')::uuid, '[image]', 'c0000000-0000-4000-8000-000000000204');
  PERFORM set_config('test.m4', v ->> 'id', true);
  PERFORM public.message_image_demander(current_setting('test.m4')::uuid, 'image/jpeg', 1000, 'image/webp', 100, 80, 60, NULL);
END $corr2$;
RESET ROLE;
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
DO $corr3$
DECLARE l jsonb;
BEGIN
  l := public.com_lister_fils();
  PERFORM pg_temp.vrai((SELECT e -> 'messages' -> -1 ->> 'id' FROM jsonb_array_elements(l) e
                         WHERE e ->> 'id' = current_setting('test.f1')) = current_setting('test.m2')
     AND (SELECT (e ->> 'non_lus')::int FROM jsonb_array_elements(l) e
           WHERE e ->> 'id' = current_setting('test.f1')) = 2,
    'liste des fils : l''autre tuteur ne voit ni dernier message ni non lu pour une image en attente');
END $corr3$;
RESET ROLE;

-- ------------------------------------------------------------
-- 6. Coeurs
-- ------------------------------------------------------------
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $coeurs1$
DECLARE v jsonb;
BEGIN
  v := public.aimer_message(current_setting('test.m1')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 1 AND (v ->> 'aime_par_moi')::boolean, 'coeur pose : 1, aime_par_moi');
  v := public.aimer_message(current_setting('test.m1')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 1, 'coeur repose : sans effet (toujours 1)');
END $coeurs1$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000b1','teacher');
SET LOCAL ROLE authenticated;
DO $coeurs2$
DECLARE v jsonb;
BEGIN
  v := public.aimer_message(current_setting('test.m1')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 2 AND (v ->> 'aime_par_moi')::boolean, 'l''enseignante pose le sien : 2 coeurs');
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  PERFORM pg_temp.vrai((SELECT (e ->> 'coeurs')::int = 2 AND (e ->> 'aime_par_moi')::boolean
      FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1')),
    'lecture du fil : coeurs = 2, aime_par_moi vrai pour elle');
END $coeurs2$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $coeurs3$
DECLARE v jsonb;
BEGIN
  v := public.ne_plus_aimer_message(current_setting('test.m1')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 1 AND NOT (v ->> 'aime_par_moi')::boolean, 'coeur retire : 1, plus aime');
  v := public.ne_plus_aimer_message(current_setting('test.m1')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 1 AND NOT (v ->> 'aime_par_moi')::boolean, 'retrait repete : sans effet');
  v := public.aimer_message(current_setting('test.m1')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 2 AND (v ->> 'aime_par_moi')::boolean, 'coeur repose apres retrait : 2');
  v := public.ne_plus_aimer_message(current_setting('test.m2')::uuid);
  PERFORM pg_temp.vrai((v ->> 'coeurs')::int = 0, 'retirer un coeur jamais donne : sans effet');
  -- On ne touche pas au coeur d'un autre : aucune ecriture directe.
  PERFORM pg_temp.refus($$UPDATE public.com_message_coeurs SET retire_le = now()$$, '42501',
    'aucune ecriture directe dans la table des coeurs');
END $coeurs3$;
RESET ROLE;

-- ------------------------------------------------------------
-- 7. Limite de 20 images par heure et par personne
-- ------------------------------------------------------------
INSERT INTO public.com_messages(fil_id, auteur_id, cle_idempotence, texte)
SELECT current_setting('test.f1')::uuid, 'c0000000-0000-4000-8000-0000000000d1',
       ('c0000000-0000-4000-8000-00000000' || lpad(g::text, 4, '0'))::uuid, 'lot ' || g
FROM generate_series(1000, 1024) g;

SELECT set_config('test.lots', (SELECT string_agg(id::text, ',' ORDER BY texte) FROM public.com_messages WHERE texte LIKE 'lot %'), true);
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
DO $limite$
DECLARE r record; n integer := 0; v_msg text;
BEGIN
  -- Trois depots comptent deja (message 1 et IMAGES-CORRECTIF m3, m4) : 17 de plus passent, la 20e (21e) est refusee.
  FOR r IN SELECT x::uuid AS id FROM unnest((string_to_array(current_setting('test.lots'), ','))[1:17]) x LOOP
    PERFORM public.message_image_demander(r.id, 'image/png', 1000, 'image/png', 100, 100, 100, NULL);
    n := n + 1;
  END LOOP;
  PERFORM pg_temp.vrai(n = 17, '20 images dans l''heure acceptees (17 de plus que les trois premieres)');
  BEGIN
    PERFORM public.message_image_demander((string_to_array(current_setting('test.lots'), ','))[25]::uuid,
      'image/png', 1000, 'image/png', 100, 100, 100, NULL);
    RAISE EXCEPTION 'ROUGE : la 21e image de l''heure a ete acceptee';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    PERFORM pg_temp.vrai(SQLSTATE = '54000' AND v_msg = 'ImageLimiteHoraire', '21e image de l''heure : refus ImageLimiteHoraire');
  END;
END $limite$;
RESET ROLE;

-- Une heure plus tard, la personne depose de nouveau.
UPDATE public.com_message_images SET cree_le = cree_le - interval '2 hours' WHERE auteur = 'c0000000-0000-4000-8000-0000000000d1';
SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.message_image_demander((string_to_array(current_setting('test.lots'), ','))[25]::uuid,
  'image/png', 1000, 'image/png', 100, 100, 100, NULL) ->> 'image_id') IS NOT NULL,
  'une heure plus tard : le compteur est reparti');
-- Annuler un depot qu'on ne confirmera pas.
SELECT pg_temp.vrai(public.message_image_annuler((SELECT i.id FROM public.com_message_images i
    WHERE i.message_id = (string_to_array(current_setting('test.lots'), ','))[1]::uuid)) IS TRUE
  AND NOT public.message_image_annuler((SELECT i.id FROM public.com_message_images i
    WHERE i.message_id = (string_to_array(current_setting('test.lots'), ','))[1]::uuid)),
  'depot annule : etat supprimee, un second appel est sans effet');
RESET ROLE;

-- ------------------------------------------------------------
-- 7 bis. CONVERSATIONS-PARTOUT : rattrapage de confirmee_le (migration 20261129300000)
-- ------------------------------------------------------------
UPDATE public.com_message_images SET confirmee_le = NULL
 WHERE id = current_setting('test.i1')::uuid;
SELECT pg_temp.vrai((SELECT confirmee_le IS NULL FROM public.com_message_images
                      WHERE id = current_setting('test.i1')::uuid),
  'fixture : une image confirmee avant la migration n''a pas de date');
-- L'instruction de la migration, mot pour mot.
UPDATE public.com_message_images
   SET confirmee_le = cree_le
 WHERE etat = 'confirmee'
   AND confirmee_le IS NULL;
SELECT pg_temp.vrai((SELECT confirmee_le = cree_le FROM public.com_message_images
                      WHERE id = current_setting('test.i1')::uuid)
  AND NOT EXISTS (SELECT 1 FROM public.com_message_images
                   WHERE etat = 'confirmee' AND confirmee_le IS NULL),
  'rattrapage : toute image confirmee a une date (celle du depot), rejouable');

-- ------------------------------------------------------------
-- 8. Expiration a 90 jours : lue comme supprimee, puis purgee
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT expire_le BETWEEN clock_timestamp() + interval '89 days 23 hours' AND clock_timestamp() + interval '90 days 1 hour'
    FROM public.com_message_images WHERE id = current_setting('test.i1')::uuid),
  'expire_le = depot + 90 jours');
UPDATE public.com_message_images SET expire_le = clock_timestamp() - interval '1 day'
 WHERE id = current_setting('test.i1')::uuid;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d2','guardian');
SET LOCAL ROLE authenticated;
DO $expire$
DECLARE v jsonb; m jsonb; l jsonb;
BEGIN
  v := public.com_lire_fil(current_setting('test.f1')::uuid);
  SELECT e INTO m FROM jsonb_array_elements(v -> 'messages') e WHERE e ->> 'id' = current_setting('test.m1');
  PERFORM pg_temp.vrai(m -> 'image' ->> 'etat' = 'supprimee', 'image expiree : lue comme supprimee dans le fil');
  l := public.message_images_a_signer(current_setting('test.f1')::uuid, current_setting('test.i1')::uuid);
  PERFORM pg_temp.vrai(jsonb_array_length(l) = 1 AND l -> 0 ->> 'etat' = 'supprimee' AND NOT (l -> 0 ? 'cle'),
    'image expiree : un etat, aucune cle a signer');
END $expire$;
RESET ROLE;

SELECT pg_temp.qui('c0000000-0000-4000-8000-0000000000d1','guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.message_images_purge_lire(200)$$, '42501', 'un client ne lit pas la liste de purge');
SELECT pg_temp.refus($$SELECT public.message_images_purge_marquer(ARRAY[gen_random_uuid()])$$, '42501', 'un client ne marque pas la purge');
RESET ROLE;

SET LOCAL ROLE service_role;
DO $purge$
DECLARE l jsonb; v_n integer;
BEGIN
  l := public.message_images_purge_lire(200);
  PERFORM pg_temp.vrai(l @> jsonb_build_array(jsonb_build_object('id', current_setting('test.i1')))
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(l) e WHERE e ->> 'id' = current_setting('test.i1')),
    'purge : l''image expiree est dans le lot');
  PERFORM pg_temp.vrai(jsonb_array_length(l) = 1, 'purge : seule l''image expiree (les autres ne sont pas dues)');
  PERFORM pg_temp.vrai(l -> 0 ->> 'cle_r2' LIKE 'fils/%.jpg' AND l -> 0 ->> 'cle_miniature' LIKE 'fils/%-min.webp',
    'purge : les deux cles a retirer de R2 sont rendues');
  v_n := public.message_images_purge_marquer(ARRAY[current_setting('test.i1')::uuid]);
  PERFORM pg_temp.vrai(v_n = 1 AND public.message_images_purge_marquer(ARRAY[current_setting('test.i1')::uuid]) = 0,
    'purge : marquee supprimee une fois, sans effet ensuite');
END $purge$;
RESET ROLE;

SELECT pg_temp.vrai((SELECT etat = 'supprimee' AND supprimee_le IS NOT NULL
    FROM public.com_message_images WHERE id = current_setting('test.i1')::uuid),
  'la ligne reste, etat supprimee, supprimee_le renseigne');
-- Un depot jamais confirme depuis plus d'un jour est aussi du.
UPDATE public.com_message_images SET cree_le = clock_timestamp() - interval '2 days'
 WHERE etat = 'en_attente' AND id = (SELECT id FROM public.com_message_images WHERE etat = 'en_attente' LIMIT 1);
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(jsonb_array_length(public.message_images_purge_lire(200)) = 1,
  'purge : un depot jamais confirme depuis plus d''un jour est du');
RESET ROLE;

DO $fin$
BEGIN
  IF current_setting('test.com_n')::int <> 70 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 70 attendus', current_setting('test.com_n');
  END IF;
  RAISE NOTICE 'IMAGES-MESSAGERIE : % controles verts', current_setting('test.com_n');
END $fin$;

ROLLBACK;
