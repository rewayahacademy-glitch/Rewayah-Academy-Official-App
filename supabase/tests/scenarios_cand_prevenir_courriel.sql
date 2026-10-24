-- CAND-PREVENIR : le lien d'inscription part par e-mail aux personnes des formulaires
-- importes. Migration 20261024010000_cand_prevenir_par_courriel.sql.
-- Decision du directeur : DECISION-CANDIDATURES-2026-10-21.md, « Le message qui previent
-- les inscrits des formulaires Google », regles 1 a 8 ; feu vert « oui Prevenir » du 24/10.
--
-- Cas couverts : (a) droits et empreintes F86, file fermee aux comptes ; (b) refus par
-- appelant (sans session, tuteur, comptable, enseignant, direction sans genre : 42501 ;
-- limite hors bornes : 22023) ; (c) inscription fermee : refus rendu, rien en file ;
-- (d) l'apercu : compteurs par adresse, de son cote seulement, aucune adresse rendue ;
-- (e) l'envoi : qui est en file (adresse, modele, categorie, origine, auteur, cle, donnees :
-- date et formulaire sans « (reponses) », jamais une reponse ni un telephone), qui ne l'est
-- pas (deja inscrit, prevenu par WhatsApp, sans adresse, rattache, historique, autre cote),
-- une adresse une seule fois ; (f) jamais deux fois : un second envoi ne met rien en file,
-- meme apres un echec d'envoi ; la limite ; (g) audit des compteurs, sans adresse.
-- Chaque controle leve 'CAND-PREVENIR ROUGE : ...' s'il echoue. A rejouer sur une base
-- NEUVE (stub_auth puis toutes les migrations) ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CAND-PREVENIR ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_db_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'CAND-PREVENIR ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CAND-PREVENIR ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca1b0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.r(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca1b7777-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Les lignes de la file pour le modele lien_inscription.
CREATE FUNCTION pg_temp.file() RETURNS bigint
LANGUAGE sql AS $$ SELECT count(*) FROM public.courriels_sortants WHERE modele = 'lien_inscription' $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.p(text),
  pg_temp.r(text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction sans genre, c1 comptable,
-- e1 tuteur, b1 enseignant.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'prev-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'c1', 'e1', 'b1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca1bffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'CA1B-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('a2'), 'CA1B-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('a3'), 'CA1B-ADM-0003', 'admin', NULL, 'Direction', 'Inconnue', 'active', NULL),
 (pg_temp.p('c1'), 'CA1B-CPT-0001', 'accountant', NULL, 'Compta', 'Essai', 'active', 'male'),
 (pg_temp.p('e1'), 'CA1B-TUT-0001', 'guardian', 'ca1bffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female'),
 (pg_temp.p('b1'), 'CA1B-ENS-0001', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male');

-- Un deja inscrit : un compte existe a l'adresse de la reponse 03 (casse differente).
INSERT INTO auth.users (id, email) VALUES (pg_temp.p('f1'), 'Prev-Rep03@Test.Invalid');

INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('ca1b5555-0000-4000-8000-000000000001', 'cle-lot-prevenir-0001', pg_temp.p('a1'),
        'Candidature enseignants Rewayah (réponses)', 'Réponses au formulaire 1', md5('lot'), '{}', '{}');

-- 01 homme a prevenir ; 02 homme, meme adresse que 01, plus recente (un seul message) ;
-- 03 homme deja inscrit ; 04 homme sans adresse ; 05 homme prevenu par WhatsApp (suivi) ;
-- 06 homme rattache ; 07 homme historique ; 08 femme a prevenir ; 09 homme a prevenir.
INSERT INTO public.candidatures (id, type_code, genre, nom_complet, etape, issue, source, source_ref)
VALUES ('ca1bcccc-0000-4000-8000-000000000005', 'enseignant', 'male', 'Suivi Cinq', 'recue', 'en_cours', 'import',
        'prev|r|05');
INSERT INTO public.candidature_evenements (candidature_id, type, etape_apres, issue_apres, auteur_id, details)
VALUES ('ca1bcccc-0000-4000-8000-000000000005', 'prevenu', 'recue', 'en_cours', pg_temp.p('a1'),
        '{"canal": "whatsapp", "date": "2026-10-20"}');

INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         telephone, reponses, contenu_empreinte, suivi_id)
VALUES
 (pg_temp.r('01'), 'prev|r|01', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-14 09:30+00', 'male',
  'Reponse Un', 'prev-rep01@test.invalid', '+33600000001', '{"ijaza": "oui"}', md5('01'), NULL),
 (pg_temp.r('02'), 'prev|r|02', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-16 09:30+00', 'male',
  'Reponse Deux', 'prev-rep01@test.invalid', NULL, '{}', md5('02'), NULL),
 (pg_temp.r('03'), 'prev|r|03', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-14 10:00+00', 'male',
  'Reponse Trois', 'prev-rep03@test.invalid', NULL, '{}', md5('03'), NULL),
 (pg_temp.r('04'), 'prev|r|04', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-14 11:00+00', 'male',
  'Reponse Quatre', NULL, '+33600000004', '{}', md5('04'), NULL),
 (pg_temp.r('05'), 'prev|r|05', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-14 12:00+00', 'male',
  'Reponse Cinq', 'prev-rep05@test.invalid', NULL, '{}', md5('05'), 'ca1bcccc-0000-4000-8000-000000000005'),
 (pg_temp.r('08'), 'prev|r|08', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-15 08:00+00', 'female',
  'Reponse Huit', 'prev-rep08@test.invalid', NULL, '{}', md5('08'), NULL),
 (pg_temp.r('09'), 'prev|r|09', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-15 09:00+00', 'male',
  'Reponse Neuf', 'prev-rep09@test.invalid', NULL, '{}', md5('09'), NULL);

-- 06 rattachee a une candidature (sans compte a son adresse, pour isoler ce critere).
INSERT INTO public.candidatures (id, type_code, genre, nom_complet, etape, issue, source, source_ref)
VALUES ('ca1bcccc-0000-4000-8000-000000000006', 'enseignant', 'male', 'Rattachee Six', 'recue', 'en_cours', 'import',
        'prev|r|06');
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         contenu_empreinte, candidature_id, rattachement, rattachee_le)
VALUES (pg_temp.r('06'), 'prev|r|06', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-14 13:00+00', 'male',
        'Reponse Six', 'prev-rep06@test.invalid', md5('06'), 'ca1bcccc-0000-4000-8000-000000000006',
        'courriel', now());
-- 07 historique, remplacee par 09.
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         contenu_empreinte, etat, remplacee_par)
VALUES (pg_temp.r('07'), 'prev|r|07', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-13 13:00+00', 'male',
        'Reponse Sept', 'prev-rep07@test.invalid', md5('07'), 'historique', pg_temp.r('09'));

-- ------------------------------------------------------------
-- (a) Droits et empreintes F86
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT bool_and(has_function_privilege('authenticated', f, 'EXECUTE')
                   AND NOT has_function_privilege('anon', f, 'EXECUTE')
                   AND NOT has_function_privilege('service_role', f, 'EXECUTE')
                   AND NOT has_function_privilege('agent_ro', f, 'EXECUTE')
                   AND NOT has_function_privilege('public', f, 'EXECUTE'))
     FROM unnest(ARRAY['public.apercu_prevenir_par_courriel()',
                       'public.prevenir_par_courriel(integer)']::regprocedure[]) AS f),
  'a1 : seul authenticated execute les deux RPC');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
                   AND obj_description(f, 'pg_proc') LIKE '%CAND-PREVENIR%'
                   AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] AND p.provolatile = 'v'
                   AND pg_get_userbyid(p.proowner) = 'postgres')
     FROM unnest(ARRAY['public.apercu_prevenir_par_courriel()',
                       'public.prevenir_par_courriel(integer)']::regprocedure[]) AS f
     JOIN pg_proc p ON p.oid = f),
  'a2 : empreinte F86 a jour, DEFINER, postgres, search_path vide, volatile');
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated',
        'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure, 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.courriels_sortants', 'SELECT,INSERT,UPDATE,DELETE'),
  'a3 : la file reste fermee aux comptes (ni courriel_enfiler, ni la table)');

-- ------------------------------------------------------------
-- (b) Refus par appelant
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.apercu_prevenir_par_courriel()', '42501',
  'b1 : sans session, apercu refuse');
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.prevenir_par_courriel(10)', '42501',
  'b2 : sans session, envoi refuse');
SELECT pg_temp.refus_en(pg_temp.p('e1'), 'guardian', 'SELECT public.prevenir_par_courriel(10)', '42501',
  'b3 : tuteur refuse');
SELECT pg_temp.refus_en(pg_temp.p('c1'), 'accountant', 'SELECT public.prevenir_par_courriel(10)', '42501',
  'b4 : comptable refuse');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', 'SELECT public.apercu_prevenir_par_courriel()', '42501',
  'b5 : enseignant refuse');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin', 'SELECT public.prevenir_par_courriel(10)', '42501',
  'b6 : direction sans genre refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(0)', '22023',
  'b7 : limite 0 refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(501)', '22023',
  'b8 : limite 501 refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(NULL)', '22023',
  'b9 : limite nulle refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(10)', '42501',
  'b10 : le role anon n''execute pas l''envoi', 'anon');

-- ------------------------------------------------------------
-- (c) Inscription fermee : rien ne part
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 2, "dejaPrevenus": 1, "dejaInscrits": 1, "inscriptionOuverte": false}'::jsonb,
  'c1 : apercu cote hommes, inscription fermee (01 et 02 une adresse, 09 ; 05 prevenu ; 03 inscrit)');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(200)')
    = '{"erreur": "inscription_fermee"}'::jsonb,
  'c2 : inscription fermee : refus rendu, rien en file');
SELECT pg_temp.vrai(
  pg_temp.file() = 0,
  'c2bis : la file apres c2');

UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';

-- ------------------------------------------------------------
-- (d) L'apercu, de chaque cote
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a2'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 1, "dejaPrevenus": 0, "dejaInscrits": 0, "inscriptionOuverte": true}'::jsonb,
  'd1 : apercu cote femmes : la seule reponse 08');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')::text
    NOT LIKE '%@%',
  'd2 : l''apercu ne rend aucune adresse');

-- ------------------------------------------------------------
-- (e) L'envoi
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(200)')
    = '{"misEnFile": 2, "restants": 0}'::jsonb,
  'e1 : deux messages en file cote hommes, plus personne a prevenir');
SELECT pg_temp.vrai(
  (SELECT array_agg(s.destinataire_adresse ORDER BY s.destinataire_adresse)
     FROM public.courriels_sortants s WHERE s.modele = 'lien_inscription')
    = ARRAY['prev-rep01@test.invalid', 'prev-rep09@test.invalid'],
  'e2 : les adresses de 01 et 09 seulement (ni 03 inscrit, 04 sans adresse, 05 WhatsApp, 06 rattache, 07 historique, 08 autre cote)');
SELECT pg_temp.vrai(
  (SELECT bool_and(s.categorie = 'recrutement' AND s.origine = 'manuel' AND s.cree_par = pg_temp.p('a1')
                   AND s.statut = 'en_attente' AND s.destinataire_profil IS NULL)
     FROM public.courriels_sortants s WHERE s.modele = 'lien_inscription'),
  'e3 : categorie recrutement, origine manuel, auteur la direction, en attente, sans profil');
SELECT pg_temp.vrai(
  (SELECT s.cle_idempotence FROM public.courriels_sortants s
    WHERE s.destinataire_adresse = 'prev-rep01@test.invalid') = 'candidat_prevenu:' || pg_temp.r('01')::text,
  'e4 : une adresse partagee part une fois, avec la cle de la reponse la plus ancienne (01, pas 02)');
SELECT pg_temp.vrai(
  (SELECT s.donnees FROM public.courriels_sortants s WHERE s.destinataire_adresse = 'prev-rep01@test.invalid')
    = jsonb_build_object('date_reponse', '2026-10-14 09:30+00'::timestamptz,
                         'formulaire', 'Candidature enseignants Rewayah'),
  'e5 : donnees : date de la reponse et nom du formulaire sans « (reponses) », rien d''autre');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.courriels_sortants s
               WHERE s.modele = 'lien_inscription'
                 AND (s.donnees::text LIKE '%+336%' OR s.donnees::text LIKE '%ijaza%'
                      OR s.donnees::text LIKE '%Reponse%')),
  'e6 : ni telephone, ni reponse du formulaire, ni nom dans les donnees');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 0, "dejaPrevenus": 3, "dejaInscrits": 1, "inscriptionOuverte": true}'::jsonb,
  'e7 : apres l''envoi, l''apercu les compte prevenus');

-- ------------------------------------------------------------
-- (f) Jamais deux fois, et la limite
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(200)')
    = '{"misEnFile": 0, "restants": 0}'::jsonb,
  'f1 : un second envoi ne met rien en file');
SELECT pg_temp.vrai(
  pg_temp.file() = 2,
  'f1bis : la file apres f1');
UPDATE public.courriels_sortants SET statut = 'echec', tentatives = 10 WHERE modele = 'lien_inscription';
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(200)')
    = '{"misEnFile": 0, "restants": 0}'::jsonb,
  'f2 : meme apres un echec d''envoi, rien ne repart tout seul');
SELECT pg_temp.vrai(
  pg_temp.file() = 2,
  'f2bis : la file apres f2');
-- Une nouvelle reponse arrive cote hommes, et la limite n'en prend qu'une.
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         contenu_empreinte)
VALUES (pg_temp.r('10'), 'prev|r|10', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-17 09:00+00', 'male',
        'Reponse Dix', 'prev-rep10@test.invalid', md5('10')),
       (pg_temp.r('11'), 'prev|r|11', 'ca1b5555-0000-4000-8000-000000000001', '2026-10-17 10:00+00', 'male',
        'Reponse Onze', 'prev-rep11@test.invalid', md5('11'));
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(1)')
    = '{"misEnFile": 1, "restants": 1}'::jsonb,
  'f3 : la limite 1 met une adresse en file et en laisse une');
SELECT pg_temp.vrai(
  pg_temp.file() = 3,
  'f3bis : la file apres f3');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a2'), 'admin', 'SELECT public.prevenir_par_courriel(200)')
    = '{"misEnFile": 1, "restants": 0}'::jsonb,
  'f4 : la direction femme previent son cote seulement');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.courriels_sortants WHERE destinataire_adresse = 'prev-rep08@test.invalid')
  AND pg_temp.file() = 4,
  'f4bis : la file apres f4 : la reponse 08 seulement de plus');

-- ------------------------------------------------------------
-- (g) Audit des compteurs, sans adresse
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.audit_logs a
    WHERE a.action IN ('prevenir_courriel_apercu', 'prevenir_courriel_envoi')) >= 8
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs a
                   WHERE a.action IN ('prevenir_courriel_apercu', 'prevenir_courriel_envoi')
                     AND a::text LIKE '%@test.invalid%'),
  'g1 : chaque apercu et chaque envoi tracent leurs compteurs, jamais une adresse');

ROLLBACK;
