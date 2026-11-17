-- PX-KYC-1 (17/11/2026, migration 20261129940000_px_kyc_lectures.sql, plan docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-KYC.md).
-- Aucune vraie piece, aucune vraie personne : des profils et des lignes fictifs, un role d'appel simule.
-- Cas : 1 ferme par defaut (etat, lancer, file, ecriture) ; 2 reglage (aal2, validation, motif du modele) ;
-- 3 la file ne rend que les genres decides et jamais deux fois la meme version ; 4 une piece d'un genre non envoye
-- ne s'ecrit pas ; 5 la regle de la proposition, cas par cas, le plus prudent l'emporte ; 6 lire une lecture : meme
-- perimetre que la piece, journalisee ; 7 les compteurs et la liste des pieces pretes (sans nom, hors salle 3) ;
-- 8 le lot : taille, eligibilite, echantillon tire par le serveur ; 9 la validation exige l'ouverture REELLE de
-- l'echantillon (journal d'audit), est rejouable, refuse le lot d'un autre, ecarte une piece decidee entre-temps ;
-- 10 un lot ne valide jamais une piece de salle 3 ; 11 l'effacement des donnees de lecture avec la piece ;
-- 12 aucun droit pour anon, agent_ro, ni pour les tables ; Praxis ne cite rien de tout cela ; une porte du serveur
-- n'est pas une porte de la direction, et inversement.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PX-KYC ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un appel sous le role authenticated, au nom d'un compte (aal2 par defaut).
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text, p_aal text DEFAULT 'aal2') RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Un appel sous le role service_role (la fonction Edge).
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(NULL, NULL);
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Un appel qui doit etre refuse avec ce code.
CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_db_role text DEFAULT 'authenticated', p_aal text DEFAULT 'aal2') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  EXECUTE 'RESET ROLE';
  IF v_passe THEN
    RAISE EXCEPTION 'PX-KYC ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'PX-KYC ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('4b4c0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.d(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('4b4cdddd-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('4b4ccccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.d(text), pg_temp.c(text) TO authenticated, anon, service_role;

-- Fixtures : a1 direction homme, a2 direction femme ; candidats 01..14 hommes, 15 femme. Documents d01..d15.
-- 14 est un candidat en salle 3 (etape confirmee, en cours) : sa piece n'entre jamais dans un lot.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(lpad(i::text, 2, '0')), 'pxkyc-' || i || '@test.invalid'
  FROM generate_series(1, 15) i;
INSERT INTO auth.users (id, email) VALUES (pg_temp.u('91'), 'pxkyc-a1@test.invalid'), (pg_temp.u('92'), 'pxkyc-a2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('91'), 'PK-ADM-0001', 'admin', 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('92'), 'PK-ADM-0002', 'admin', 'Direction', 'Femme', 'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.u(lpad(i::text, 2, '0')), 'PK-ENS-' || lpad(i::text, 4, '0'), 'teacher', 'Fictif', 'Numero' || i,
       'pending_kyc', CASE WHEN i = 15 THEN 'female'::public.gender ELSE 'male'::public.gender END
  FROM generate_series(1, 15) i;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(lpad(i::text, 2, '0')), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(1, 15) i
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.kyc_documents (id, profile_id, doc_type, object_key, status)
SELECT pg_temp.d(lpad(i::text, 2, '0')), pg_temp.u(lpad(i::text, 2, '0')), 'id_card',
       'fictif/' || i, 'pending' FROM generate_series(1, 15) i;
-- Les candidats avant la salle 3 (etape prequalification) : leur piece se decide seule, sans activer le compte.
INSERT INTO public.candidatures (id, profile_id, type_code, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.c(lpad(i::text, 2, '0')), pg_temp.u(lpad(i::text, 2, '0')), 'enseignant',
       CASE WHEN i = 15 THEN 'female'::public.gender ELSE 'male'::public.gender END,
       'Fixture PX-KYC ' || i, 'prequalification', 'en_examen', 'en_cours', false, 'lien_public'
  FROM generate_series(1, 15) i WHERE i <> 14;
INSERT INTO public.candidatures (id, profile_id, type_code, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.c('14'), pg_temp.u('14'), 'enseignant', 'male', 'Fixture PX-KYC 14', 'confirmee', NULL, 'en_cours', false,
        'lien_public');

-- ===================================================================================================
-- 1. Ferme par defaut.
-- ===================================================================================================
SELECT pg_temp.vrai((SELECT NOT actif AND modele IS NULL AND genres_envoyes = '{}'::text[] AND marge_expiration_mois = 3
                            AND lot_max = 50 AND echantillon_pct = 10 AND echantillon_min = 3
                       FROM private.kyc_lecture_reglages),
  '1a : a l''installation tout est ferme (actif faux, modele nul, aucun genre ; marge 3 mois, lot 50, 10 % et 3)');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) = 1 FROM private.kyc_lecture_reglages), '1b : une seule ligne de reglage');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.direction_kyc_lecture_lancer()') = '{"ok": false, "cause": "ferme"}'::jsonb,
  '1c : lancer une lecture fermee rend ferme, sans rien envoyer');
SELECT pg_temp.vrai(pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 20)') = '{"actif": false, "items": []}'::jsonb,
  '1d : la file est vide tant que la lecture est fermee');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.kyc_lecture_ecrire(pg_temp.d('01'), 1::smallint, 'claude-test', '{"etat": "non_lue", "cause": "panne"}'::jsonb)$$,
  '42501', '1e : ecrire une lecture est refuse tant que la lecture est fermee', 'service_role');

-- ===================================================================================================
-- 2. Le reglage.
-- ===================================================================================================
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lecture_regler(true, 'claude-test-model', ARRAY['male'])$$,
  '42501', '2a : regler exige aal2', 'authenticated', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('01'), 'teacher', $$SELECT public.direction_kyc_lecture_regler(true, 'claude-test-model', ARRAY['male'])$$,
  '42501', '2b : un enseignant ne regle rien');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.direction_kyc_lecture_regler(true, 'claude-test-model', ARRAY['male'])$$,
  '42501', '2c : un appel sans compte ne regle rien', 'anon');
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lecture_regler(true, NULL, ARRAY['male'])$$,
  '22023', '2d : ouvrir sans modele est refuse');
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lecture_regler(true, 'claude-test-model', ARRAY[]::text[])$$,
  '22023', '2e : ouvrir sans aucun genre est refuse');
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lecture_regler(true, 'claude-test-model', ARRAY['autre'])$$,
  '22023', '2f : un genre inconnu est refuse');
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lecture_regler(true, 'gpt-pas-claude', ARRAY['male'])$$,
  '23514', '2g : un nom de modele hors forme est refuse par la base');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin',
  $$SELECT public.direction_kyc_lecture_regler(true, 'claude-test-model', ARRAY['male'])$$) ->> 'modele' = 'claude-test-model',
  '2h : un reglage valide est pris');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'kyc_lecture_reglee'), '2i : le reglage est journalise');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.direction_kyc_lecture_lancer()') = '{"ok": true}'::jsonb,
  '2j : lancer est permis une fois ouvert');

-- ===================================================================================================
-- 3. La file : les genres decides seulement.
-- ===================================================================================================
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 50)') -> 'items') = 14,
  '3a : la file rend les 14 pieces d''hommes et AUCUNE piece de femme (genre non envoye)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 50)') -> 'items') i
                                 WHERE (i ->> 'documentId')::uuid = pg_temp.d('15')),
  '3b : la piece de la femme n''est pas dans la file');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 5)') -> 'items') = 5,
  '3c : la limite est respectee');
SELECT pg_temp.vrai((pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 1)') -> 'items' -> 0 ->> 'nomDossier') = 'Fictif Numero1',
  '3d : la file porte le nom du dossier (pour la comparaison cote serveur, jamais envoye au fournisseur)');
SELECT pg_temp.vrai(pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 1)') ->> 'modele' = 'claude-test-model',
  '3e : la file porte le modele du reglage');

-- ===================================================================================================
-- 4. Ecrire une lecture : un genre non envoye est refuse.
-- ===================================================================================================
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.kyc_lecture_ecrire(pg_temp.d('15'), 1::smallint, 'claude-test-model', '{"etat": "non_lue", "cause": "panne"}'::jsonb)$$,
  '42501', '4a : une piece d''un genre non envoye ne s''ecrit pas', 'service_role');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.kyc_lecture_ecrire(pg_temp.d('01'), 1::smallint, 'claude-test-model', '{"etat": "lue", "typePiece": "carte_identite"}'::jsonb)$$,
  '23514', '4b : une lecture « lue » incomplete est refusee par la base', 'service_role');

-- ===================================================================================================
-- 5. La regle de la proposition, cas par cas (dates relatives a aujourd'hui).
-- ===================================================================================================
CREATE FUNCTION pg_temp.ecrire(p_n text, p_expiration date, p_surcharge jsonb DEFAULT '{}'::jsonb) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
  v_json jsonb := pg_catalog.jsonb_build_object('etat', 'lue', 'typePiece', 'carte_identite', 'nomEcrit', 'FICTIF Numero',
    'nomConcordance', 'oui', 'dateExpiration', p_expiration, 'lisible', true, 'photoPresente', 'oui',
    'retouche', 'aucun', 'causesRetouche', '[]'::jsonb, 'mrz', 'sans_objet') || p_surcharge;
  v_r jsonb;
BEGIN
  v_r := pg_temp.srv(pg_catalog.format('SELECT public.kyc_lecture_ecrire(%L::uuid, 1::smallint, ''claude-test-model'', %L::jsonb)',
                                       pg_temp.d(p_n), v_json::text));
  RETURN v_r ->> 'proposition';
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.ecrire(text, date, jsonb) TO authenticated, anon, service_role;

SELECT pg_temp.vrai(pg_temp.ecrire('01', current_date + 365) = 'conforme', '5a : lisible, type admis, photo, nom oui, sans retouche, expiration lointaine : conforme');
SELECT pg_temp.vrai(pg_temp.ecrire('02', current_date - 1) = 'non_conforme', '5b : expiree : non conforme');
SELECT pg_temp.vrai(pg_temp.ecrire('03', current_date + 60) = 'a_verifier', '5c : expiration a moins de 3 mois : a verifier');
SELECT pg_temp.vrai(pg_temp.ecrire('04', current_date + 365, '{"nomConcordance": "doute"}') = 'a_verifier', '5d : doute de nom : a verifier');
SELECT pg_temp.vrai(pg_temp.ecrire('05', current_date + 365, '{"retouche": "probables", "causesRetouche": ["zone_floue"]}') = 'non_conforme',
  '5e : retouche probable : non conforme');
SELECT pg_temp.vrai(pg_temp.ecrire('06', current_date + 365, '{"retouche": "possibles"}') = 'a_verifier', '5f : retouche possible : a verifier');
SELECT pg_temp.vrai(pg_temp.srv('SELECT public.kyc_lecture_ecrire(pg_temp.d(''07''), 1::smallint, ''claude-test-model'', ''{"etat": "non_lue", "cause": "format_non_lu"}''::jsonb)') ->> 'proposition' = 'a_verifier',
  '5g : une piece non lue (HEIC) est a verifier, JAMAIS non conforme');
SELECT pg_temp.vrai(pg_temp.ecrire('08', current_date + 365, '{"mrz": "invalide"}') = 'a_verifier', '5h : somme MRZ fausse : a verifier');
SELECT pg_temp.vrai(pg_temp.ecrire('09', current_date + 365, '{"photoPresente": "non"}') = 'a_verifier', '5i : photo absente : a verifier');
SELECT pg_temp.vrai(pg_temp.ecrire('10', current_date + 365) = 'conforme' AND pg_temp.ecrire('11', current_date + 365) = 'conforme'
                    AND pg_temp.ecrire('12', current_date + 365) = 'conforme' AND pg_temp.ecrire('13', current_date + 365) = 'conforme'
                    AND pg_temp.ecrire('14', current_date + 365) = 'conforme', '5j : cinq autres conformes (dont la piece de salle 3, d14)');
SELECT pg_temp.vrai(pg_temp.srv('SELECT public.kyc_lecture_ecrire(pg_temp.d(''01''), 1::smallint, ''claude-test-model'', ''{"etat": "non_lue", "cause": "panne"}''::jsonb)')
                    = '{"ecrite": false, "cause": "deja_lue"}'::jsonb, '5k : ecrire deux fois la meme version est sans effet (idempotent)');
SELECT pg_temp.vrai((SELECT proposition FROM private.kyc_lectures WHERE document_id = pg_temp.d('01')) = 'conforme',
  '5l : la deuxieme ecriture n''a pas remplace la premiere');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.srv('SELECT public.kyc_lecture_file(1::smallint, 50)') -> 'items') = 0,
  '5m : la file de la version 1 est vide une fois les 14 lues');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.srv('SELECT public.kyc_lecture_file(2::smallint, 50)') -> 'items') = 14,
  '5n : une nouvelle version de consigne remet les 14 dans la file');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.kyc_lecture_ecrire(pg_temp.d('01'), 2::smallint, 'claude-test-model', '{"etat": "lue", "typePiece": "carte_identite", "lisible": true, "photoPresente": "oui", "retouche": "aucun", "mrz": "sans_objet", "nomConcordance": "oui", "causesRetouche": ["inventee"]}'::jsonb)$$,
  '23514', '5o : une cause de retouche hors liste est refusee', 'service_role');

-- ===================================================================================================
-- 6. Lire une lecture : meme perimetre que la piece, journalisee.
-- ===================================================================================================
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.kyc_lecture_dossier(pg_temp.d('01'))$$) #>> '{lecture,proposition}' = 'conforme',
  '6a : la direction du meme cote lit la lecture');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.kyc_lecture_dossier(pg_temp.d('01'))$$) #>> '{lecture,nomEcrit}' = 'FICTIF Numero',
  '6b : la lecture porte le nom ecrit');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('92'), 'admin', $$SELECT public.kyc_lecture_dossier(pg_temp.d('01'))$$) = '{"erreur": "hors_portee"}'::jsonb,
  '6c : la direction de l''autre cote ne lit rien (hors portee)');
SELECT pg_temp.refus_en(pg_temp.u('01'), 'teacher', $$SELECT public.kyc_lecture_dossier(pg_temp.d('01'))$$, '42501', '6d : un enseignant ne lit rien');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'kyc_lecture_ouverte' AND row_id = pg_temp.d('01')::text),
  '6e : la lecture d''une lecture est journalisee');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.kyc_lecture_dossier(pg_temp.d('01'))$$) #>> '{lecture,horsLot}' = 'false'
                    AND pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.kyc_lecture_dossier(pg_temp.d('14'))$$) #>> '{lecture,horsLot}' = 'true',
  '6f : la lecture dit si la piece est hors lot (salle 3)');

-- ===================================================================================================
-- 7. Compteurs et pieces pretes.
-- ===================================================================================================
SELECT pg_temp.vrai((pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.direction_kyc_lecture_etat()') ->> 'enAttente')::int = 14
                    AND (pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.direction_kyc_lecture_etat()') ->> 'lues')::int = 14
                    AND (pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.direction_kyc_lecture_etat()') ->> 'pretes')::int = 5,
  '7a : compteurs de la direction homme : 14 en attente, 14 lues, 5 pretes (6 conformes moins la piece de salle 3)');
SELECT pg_temp.vrai((pg_temp.en(pg_temp.u('92'), 'admin', 'SELECT public.direction_kyc_lecture_etat()') ->> 'enAttente')::int = 1
                    AND (pg_temp.en(pg_temp.u('92'), 'admin', 'SELECT public.direction_kyc_lecture_etat()') ->> 'lues')::int = 0,
  '7b : la direction femme ne compte que la piece d''une femme, non lue');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.kyc_lectures_pretes()')) = 5,
  '7c : cinq pieces pretes pour la direction homme');
SELECT pg_temp.vrai(NOT (pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.kyc_lectures_pretes()')::text LIKE '%Fictif%')
                    AND NOT (pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.kyc_lectures_pretes()')::text LIKE '%nomEcrit%')
                    AND NOT (pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.kyc_lectures_pretes()')::text LIKE '%profil%'),
  '7d : la liste des pieces pretes ne porte ni nom ni profil');
SELECT pg_temp.vrai(NOT (pg_temp.en(pg_temp.u('91'), 'admin', 'SELECT public.kyc_lectures_pretes()')::text LIKE '%' || pg_temp.d('14')::text || '%'),
  '7e : la piece de salle 3 n''est pas dans la liste des pretes');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.en(pg_temp.u('92'), 'admin', 'SELECT public.kyc_lectures_pretes()')) = 0,
  '7f : la direction femme n''a aucune piece prete');
SELECT pg_temp.refus_en(pg_temp.u('01'), 'teacher', 'SELECT public.kyc_lectures_pretes()', '42501', '7g : un enseignant ne lit pas la liste');

-- ===================================================================================================
-- 8. Preparer un lot.
-- ===================================================================================================
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('01')])$$,
  '42501', '8a : preparer un lot exige aal2', 'authenticated', 'aal1');
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_preparer(ARRAY[]::uuid[])$$,
  '22023', '8b : un lot vide est refuse');
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin',
  $$SELECT public.direction_kyc_lot_preparer((SELECT pg_catalog.array_agg(gen_random_uuid()) FROM generate_series(1, 51)))$$,
  '22023', '8c : un lot de 51 pieces est refuse (50 au plus)');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('01'), pg_temp.d('02')])$$)
                    = '{"erreur": "piece_non_eligible"}'::jsonb, '8d : un lot qui contient une piece non conforme est refuse en entier');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('01'), pg_temp.d('14')])$$)
                    = '{"erreur": "piece_non_eligible"}'::jsonb, '8e : une piece de salle 3 ne peut pas entrer dans un lot');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('92'), 'admin', $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('01')])$$)
                    = '{"erreur": "piece_non_eligible"}'::jsonb, '8f : la direction de l''autre cote ne peut pas mettre cette piece dans un lot');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('01'), pg_temp.d('01')])$$) ? 'lotId',
  '8g : un doublon est replie, le lot est valide');
SELECT pg_catalog.set_config('test.lotA', (pg_temp.en(pg_temp.u('91'), 'admin',
  $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('01'), pg_temp.d('10'), pg_temp.d('11')])$$))::text, true);
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.lotA')::jsonb -> 'echantillon') = 3,
  '8h : pour 3 pieces, l''echantillon est de 3 (au moins 3, au plus le lot)');
SELECT pg_catalog.set_config('test.lotB', (pg_temp.en(pg_temp.u('91'), 'admin',
  $$SELECT public.direction_kyc_lot_preparer(ARRAY[pg_temp.d('12'), pg_temp.d('13')])$$))::text, true);
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.lotB')::jsonb -> 'echantillon') = 2,
  '8i : pour 2 pieces, l''echantillon est de 2 (jamais plus que le lot)');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.kyc_lots) = 3, '8j : trois lots ecrits (celui du doublon, A et B)');

-- ===================================================================================================
-- 9. Valider un lot.
-- ===================================================================================================
CREATE FUNCTION pg_temp.lot(p text) RETURNS uuid LANGUAGE sql AS $$ SELECT (pg_catalog.current_setting('test.' || p)::jsonb ->> 'lotId')::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.lot(text) TO authenticated;
SELECT pg_temp.refus_en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotA'))$$,
  '42501', '9a : valider un lot exige aal2', 'authenticated', 'aal1');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotA'))$$)
                    = '{"erreur": "echantillon_non_ouvert", "restantes": 3}'::jsonb,
  '9b : sans ouvrir une seule piece de l''echantillon, la validation est refusee (3 restantes)');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.kyc_documents WHERE status = 'approved') = 0,
  '9c : rien n''a ete decide');
-- Ouvrir deux pieces sur trois : par la porte REELLE d'ouverture, qui journalise.
SELECT pg_temp.en(pg_temp.u('91'), 'admin', pg_catalog.format('SELECT public.autoriser_lecture_piece_identite(%L::uuid)', pg_temp.d('01')));
SELECT pg_temp.en(pg_temp.u('91'), 'admin', pg_catalog.format('SELECT public.autoriser_lecture_piece_identite(%L::uuid)', pg_temp.d('10')));
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotA'))$$)
                    = '{"erreur": "echantillon_non_ouvert", "restantes": 1}'::jsonb,
  '9d : deux pieces ouvertes sur trois : une reste, refuse');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('92'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotA'))$$)
                    = '{"erreur": "lot_inconnu"}'::jsonb, '9e : le lot d''une autre personne est inconnu');
SELECT pg_temp.en(pg_temp.u('91'), 'admin', pg_catalog.format('SELECT public.autoriser_lecture_piece_identite(%L::uuid)', pg_temp.d('11')));
SELECT pg_catalog.set_config('test.resA', (pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotA'))$$))::text, true);
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.resA')::jsonb -> 'valides') = 3
                    AND pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.resA')::jsonb -> 'refuses') = 0,
  '9f : l''echantillon ouvert, les trois pieces sont validees');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.kyc_documents WHERE status = 'approved'
                        AND id IN (pg_temp.d('01'), pg_temp.d('10'), pg_temp.d('11')) AND verified_by = pg_temp.u('91')) = 3,
  '9g : les trois sont approuvees, au nom de la direction qui a valide');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotA'))$$)::text
                    = pg_catalog.current_setting('test.resA'), '9h : rejouer le lot rend le meme resultat, sans rien redecider');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.audit_logs WHERE action = 'kyc_decision') = 3
                    AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'kyc_lot_valide' AND payload ->> 'sur_proposition' = 'true'),
  '9i : trois decisions journalisees, plus la ligne du lot « sur proposition »');
-- Lot B : une piece decidee par un humain entre la preparation et la validation.
SELECT pg_temp.en(pg_temp.u('91'), 'admin', pg_catalog.format('SELECT public.autoriser_lecture_piece_identite(%L::uuid)', pg_temp.d('12')));
SELECT pg_temp.en(pg_temp.u('91'), 'admin', pg_catalog.format('SELECT public.autoriser_lecture_piece_identite(%L::uuid)', pg_temp.d('13')));
SELECT pg_temp.en(pg_temp.u('91'), 'admin', pg_catalog.format('SELECT pg_catalog.to_jsonb(public.decider_dossier(%L::uuid, false, ''motif de test'')::text)', pg_temp.d('13')));
SELECT pg_catalog.set_config('test.resB', (pg_temp.en(pg_temp.u('91'), 'admin', $$SELECT public.direction_kyc_lot_valider(pg_temp.lot('lotB'))$$))::text, true);
SELECT pg_temp.vrai(pg_catalog.current_setting('test.resB')::jsonb -> 'valides' = pg_catalog.jsonb_build_array(pg_temp.d('12'))
                    AND pg_catalog.current_setting('test.resB')::jsonb #>> '{refuses,0,cause}' = 'plus_eligible'
                    AND pg_catalog.current_setting('test.resB')::jsonb #>> '{refuses,0,documentId}' = pg_temp.d('13')::text,
  '9j : une piece refusee entre-temps par un humain est ecartee du lot (plus_eligible), l''autre est validee');
SELECT pg_temp.vrai((SELECT status::text FROM public.kyc_documents WHERE id = pg_temp.d('13')) = 'rejected',
  '9k : le refus humain n''a pas ete ecrase par le lot');

-- ===================================================================================================
-- 10. Le refus ne se fait jamais en lot : aucune porte de lot ne refuse.
-- ===================================================================================================
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                                  WHERE p.pronamespace = 'public'::regnamespace
                                    AND p.proname IN ('direction_kyc_lot_preparer', 'direction_kyc_lot_valider')
                                    AND (p.prosrc LIKE '%false, %motif%' OR p.prosrc LIKE '%decider_dossier(v_doc, false%')),
  '10a : aucune porte de lot n''appelle decider_dossier pour refuser');
SELECT pg_temp.vrai((SELECT status::text FROM public.kyc_documents WHERE id = pg_temp.d('14')) = 'pending',
  '10b : la piece de salle 3 est toujours en attente, jamais touchee par un lot');
SELECT pg_temp.vrai((SELECT status::text FROM public.kyc_documents WHERE id = pg_temp.d('03')) = 'pending'
                    AND (SELECT status::text FROM public.kyc_documents WHERE id = pg_temp.d('02')) = 'pending',
  '10c : les pieces « a verifier » et « non conforme » restent en attente de l''humain');

-- ===================================================================================================
-- 11. Les donnees de lecture partent avec la piece.
-- ===================================================================================================
SELECT pg_temp.vrai(private.kyc_lectures_effacer_donnees() = 0, '11a : aucune piece echue, aucune lecture videe');
UPDATE public.kyc_documents SET purge_at = pg_catalog.now() - interval '1 day' WHERE id = pg_temp.d('02');
SELECT pg_temp.vrai(private.kyc_lectures_effacer_donnees() = 1, '11b : une piece echue : une lecture videe');
SELECT pg_temp.vrai((SELECT nom_ecrit IS NULL AND date_expiration IS NULL AND type_piece IS NULL AND mrz IS NULL
                            AND proposition = 'a_verifier' AND donnees_effacees_le IS NOT NULL
                       FROM private.kyc_lectures WHERE document_id = pg_temp.d('02')),
  '11c : nom, date et champs sont vides, la ligne reste comme trace (a verifier)');
SELECT pg_temp.vrai((SELECT nom_ecrit = 'FICTIF Numero' FROM private.kyc_lectures WHERE document_id = pg_temp.d('01')),
  '11d : les lectures des autres pieces ne sont pas touchees');
SELECT pg_temp.vrai(private.kyc_lectures_effacer_donnees() = 0, '11e : rejouable, la deuxieme fois ne vide rien');

-- ===================================================================================================
-- 12. Droits, isolement de Praxis, portes qui ne se melangent pas.
-- ===================================================================================================
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('anon', f, 'EXECUTE') AND NOT pg_catalog.has_function_privilege('agent_ro', f, 'EXECUTE'),
  '12a : anon et agent_ro n''executent aucune des neuf portes (' || f || ')')
  FROM unnest(ARRAY['public.direction_kyc_lecture_etat()', 'public.direction_kyc_lecture_lancer()',
    'public.direction_kyc_lecture_regler(boolean, text, text[])', 'public.kyc_lecture_dossier(uuid)', 'public.kyc_lectures_pretes()',
    'public.direction_kyc_lot_preparer(uuid[])', 'public.direction_kyc_lot_valider(uuid)',
    'public.kyc_lecture_file(smallint, integer)', 'public.kyc_lecture_ecrire(uuid, smallint, text, jsonb)']) f;
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('authenticated', 'public.kyc_lecture_file(smallint, integer)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('authenticated', 'public.kyc_lecture_ecrire(uuid, smallint, text, jsonb)', 'EXECUTE'),
  '12b : un compte connecte n''ouvre pas les portes du serveur');
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('service_role', 'public.direction_kyc_lot_valider(uuid)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('service_role', 'public.direction_kyc_lot_preparer(uuid[])', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege('service_role', 'public.direction_kyc_lecture_regler(boolean, text, text[])', 'EXECUTE'),
  '12c : le serveur ne valide ni ne regle : ce sont des portes de la direction');
SELECT pg_temp.vrai(NOT pg_catalog.has_table_privilege(r, t, 'SELECT') AND NOT pg_catalog.has_table_privilege(r, t, 'UPDATE')
                    AND NOT pg_catalog.has_table_privilege(r, t, 'INSERT'),
  '12d : aucun role client ne touche ' || t || ' (' || r || ')')
  FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r,
       unnest(ARRAY['private.kyc_lectures', 'private.kyc_lecture_reglages', 'private.kyc_lots']) t;
SELECT pg_temp.vrai((SELECT pg_catalog.bool_and(c.relrowsecurity) FROM pg_catalog.pg_class c
                      WHERE c.oid IN ('private.kyc_lectures'::regclass, 'private.kyc_lecture_reglages'::regclass, 'private.kyc_lots'::regclass)),
  '12e : la securite par ligne est active sur les trois tables');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                                  WHERE p.pronamespace IN ('public'::regnamespace, 'private'::regnamespace)
                                    AND (p.proname LIKE 'praxis\_%' ESCAPE '\' OR p.proname LIKE 'direction\_praxis\_%' ESCAPE '\')
                                    AND (p.prosrc LIKE '%kyc_lecture%' OR p.prosrc LIKE '%kyc_lots%')),
  '12f : aucune fonction de Praxis ne cite les lectures, les reglages ni les lots (R4)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                                  WHERE p.pronamespace IN ('public'::regnamespace, 'private'::regnamespace)
                                    AND p.proname IN ('direction_kyc_lecture_etat', 'direction_kyc_lecture_lancer', 'direction_kyc_lecture_regler',
                                                      'kyc_lecture_dossier', 'kyc_lectures_pretes', 'direction_kyc_lot_preparer',
                                                      'direction_kyc_lot_valider', 'kyc_lecture_file', 'kyc_lecture_ecrire')
                                    AND NOT (p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])),
  '12g : les neuf portes sont DEFINER a chemin de recherche vide');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
                      WHERE p.pronamespace = 'public'::regnamespace
                        AND p.proname IN ('direction_kyc_lecture_etat', 'direction_kyc_lecture_lancer', 'direction_kyc_lecture_regler',
                                          'kyc_lecture_dossier', 'kyc_lectures_pretes', 'direction_kyc_lot_preparer',
                                          'direction_kyc_lot_valider', 'kyc_lecture_file', 'kyc_lecture_ecrire')
                        AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE 'F86 candidate allowlist:%md5_functiondef=%guard_type=%') = 9,
  '12h : les neuf portes portent leur empreinte F86');
SELECT pg_temp.refus_en(pg_temp.u('01'), 'teacher', 'UPDATE private.kyc_lecture_reglages SET actif = false', '42501',
  '12i : un compte ne modifie pas les reglages par la table');

ROLLBACK;
\o
SELECT 'PX-KYC : tous les scenarios sont verts' AS resultat;
