-- PREVENIR-TOUS : « Prevenir » couvre les deux genres pour le super-admin seulement.
-- Migration 20261125200000_prevenir_tous_genres.sql. Rejouer sur une base NEUVE (stub_auth
-- puis toutes les migrations) ; le scenario annule tout a la fin.
-- Cas : super-admin homme -> les deux genres (apercu, repartition, envoi, journal) ;
-- direction non super-admin -> son genre seulement ; anti-doublon ; desinscrite exclue ;
-- tuteur, enseignant, anon refuses ; l'apercu ne rend aucune adresse.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims',
    CASE WHEN p_id IS NULL THEN '{}' ELSE pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated',
      'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text END, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'PREVENIR-TOUS ROUGE : %', p_label; END IF;
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
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_sql text, p_label text, p_db text DEFAULT 'authenticated')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_passe boolean := false; v_code text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN v_code := SQLSTATE;
  END;
  IF v_passe OR v_code <> '42501' THEN
    RAISE EXCEPTION 'PREVENIR-TOUS ROUGE : % (code %)', p_label, coalesce(v_code, 'aucun refus');
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS
$$ SELECT ('ca1d0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.r(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS
$$ SELECT ('ca1d7777-0000-4000-8000-0000000000' || p_n)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.p(text),
  pg_temp.r(text) TO authenticated, anon;

-- a4 super-admin homme ; a1 direction homme ; a2 direction femme ; e1 tuteur ; b1 enseignant.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'pt-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'a2', 'a4', 'e1', 'b1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca1dffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'CA1D-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('a2'), 'CA1D-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('a4'), 'CA1D-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 (pg_temp.p('e1'), 'CA1D-TUT-0001', 'guardian', 'ca1dffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai', 'active', 'female'),
 (pg_temp.p('b1'), 'CA1D-ENS-0001', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('a4'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';

INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('ca1d5555-0000-4000-8000-000000000001', 'cle-lot-pt-0001', pg_temp.p('a4'),
        'Candidature enseignants Rewayah (réponses)', 'Réponses', md5('lotpt'), '{}', '{}');
-- 01, 02 hommes (02 desinscrit) ; 03, 04 femmes (04 meme adresse que 03) ; 05 femme deja inscrite ;
-- 06 femme prevenue ; 07 femme sans adresse.
INSERT INTO auth.users (id, email) VALUES (pg_temp.p('f5'), 'PT-Rep05@Test.Invalid');
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         contenu_empreinte)
VALUES
 (pg_temp.r('01'), 'pt|r|01', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-14 09:00+00', 'male', 'Un', 'pt-rep01@test.invalid', md5('pt1')),
 (pg_temp.r('02'), 'pt|r|02', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-14 09:10+00', 'male', 'Deux', 'pt-rep02@test.invalid', md5('pt2')),
 (pg_temp.r('03'), 'pt|r|03', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-14 09:20+00', 'female', 'Trois', 'pt-rep03@test.invalid', md5('pt3')),
 (pg_temp.r('04'), 'pt|r|04', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-15 09:20+00', 'female', 'Quatre', 'pt-rep03@test.invalid', md5('pt4')),
 (pg_temp.r('05'), 'pt|r|05', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-14 09:30+00', 'female', 'Cinq', 'pt-rep05@test.invalid', md5('pt5')),
 (pg_temp.r('06'), 'pt|r|06', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-14 09:40+00', 'female', 'Six', 'pt-rep06@test.invalid', md5('pt6')),
 (pg_temp.r('07'), 'pt|r|07', 'ca1d5555-0000-4000-8000-000000000001', '2026-10-14 09:50+00', 'female', 'Sept', NULL, md5('pt7'));
INSERT INTO public.courriel_desinscriptions (adresse, categorie) VALUES ('pt-rep02@test.invalid', 'recrutement');
SELECT public.courriel_enfiler('recrutement', 'lien_inscription', 'pt-rep06@test.invalid', NULL, '{}'::jsonb,
  'lien_inscription:pt-rep06@test.invalid', 'manuel', pg_temp.p('a1'));

-- (a) Apercu : super-admin = deux genres ; autre direction = son genre.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a4'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 2, "aPrevenirHommes": 1, "aPrevenirFemmes": 1, "desinscrits": 1, "dejaPrevenus": 1, "dejaInscrits": 1, "inscriptionOuverte": true}'::jsonb,
  'a1 : super-admin homme : 01 et 03 (04 meme adresse), 02 desinscrit, 05 inscrite, 06 prevenue');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 1, "aPrevenirHommes": 1, "aPrevenirFemmes": 0, "desinscrits": 1, "dejaPrevenus": 0, "dejaInscrits": 0, "inscriptionOuverte": true}'::jsonb,
  'a2 : direction homme non super-admin : son genre seulement');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a2'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 1, "aPrevenirHommes": 0, "aPrevenirFemmes": 1, "desinscrits": 0, "dejaPrevenus": 1, "dejaInscrits": 1, "inscriptionOuverte": true}'::jsonb,
  'a3 : direction femme non super-admin : son genre seulement');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a4'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')::text NOT LIKE '%@%',
  'a4 : l''apercu ne rend aucune adresse');

-- (b) Refus.
SELECT pg_temp.refus(pg_temp.p('e1'), 'guardian', 'SELECT public.prevenir_par_courriel(10)', 'b1 : tuteur refuse');
SELECT pg_temp.refus(pg_temp.p('b1'), 'teacher', 'SELECT public.apercu_prevenir_par_courriel()', 'b2 : enseignant refuse');
SELECT pg_temp.refus(NULL, NULL, 'SELECT public.prevenir_par_courriel(10)', 'b3 : sans session, envoi refuse');
SELECT pg_temp.refus(pg_temp.p('a4'), 'admin', 'SELECT public.prevenir_par_courriel(10)', 'b4 : anon n''execute pas', 'anon');

-- (c) Envoi : direction non super-admin, son genre seulement.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(200)') = '{"misEnFile": 1, "restants": 0}'::jsonb,
  'c1 : direction homme non super-admin : un message en file');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.courriels_sortants WHERE destinataire_adresse = 'pt-rep01@test.invalid')
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE destinataire_adresse = 'pt-rep03@test.invalid'),
  'c1bis : 01 part, la femme (03) ne part pas');

-- (d) Envoi : super-admin, les deux genres, une seule fois par adresse.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a4'), 'admin', 'SELECT public.prevenir_par_courriel(200)') = '{"misEnFile": 1, "restants": 0}'::jsonb,
  'd1 : super-admin : un message en file (la candidate 03/04)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants WHERE destinataire_adresse = 'pt-rep03@test.invalid') = 1
  AND (SELECT cle_idempotence FROM public.courriels_sortants WHERE destinataire_adresse = 'pt-rep03@test.invalid')
        = 'lien_inscription:pt-rep03@test.invalid',
  'd1bis : la candidate 03/04 part une fois, cle par adresse');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.courriels_sortants
               WHERE destinataire_adresse IN ('pt-rep02@test.invalid', 'pt-rep05@test.invalid')),
  'd2 : desinscrite (02) et inscrite (05) exclues');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a4'), 'admin', 'SELECT public.prevenir_par_courriel(200)') = '{"misEnFile": 0, "restants": 0}'::jsonb,
  'd3 : un second envoi ne met rien en file');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants WHERE modele = 'lien_inscription') = 3,
  'd4 : file : 06 (deja la), 01, 03');

-- (e) Journal.
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'prevenir_courriel_envoi'
           AND a.payload ->> 'exception_active' = 'true' AND a.payload ->> 'reader_gender' = 'male'
           AND a.payload ->> 'mis_en_file_femmes' = '1' AND a.payload ->> 'mis_en_file_hommes' = '0')
  AND EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'prevenir_courriel_apercu'
           AND a.payload ->> 'aPrevenirFemmes' = '1' AND a.payload ->> 'aPrevenirHommes' = '1')
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs a
           WHERE a.action IN ('prevenir_courriel_apercu', 'prevenir_courriel_envoi') AND a::text LIKE '%@test.invalid%'),
  'e1 : journal : reader_gender, exception_active et les comptes par genre, jamais une adresse');

ROLLBACK;
