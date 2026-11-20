-- PE-A1 (lot COURRIELS-CANDIDAT, 20/11/2026) : migration 20261130966000.
--
-- La langue d'un courriel de candidat :
--   a. un compte sans langue choisie mais dont la candidature est en arabe : le courriel part en arabe ;
--   b. la langue choisie dans le compte passe avant celle de la candidature ;
--   c. sans profil : l'adresse d'un compte existant retrouve sa candidature ; c2 sans tenir compte de la casse ;
--   d. sans profil : la langue donnee explicitement au dernier courriel de l'adresse ;
--   e. sans profil : la reponse importee ecrite en arabe ;
--   f. rien de connu : le francais ;
--   g. la langue du compte est recopiee dans user_metadata.langue (Supabase Auth), puis suit le choix du compte ;
--      un raw_user_meta_data JSON null, scalaire ou tableau n'est jamais touche ;
--   h. le rattrapage des comptes existants n'a PAS tourne a l'installation ; appele, il rend le nombre de comptes
--      changes, puis 0 au second appel ; il est ferme aux clients.
-- Le stub d'authentification de la CI n'a pas la colonne raw_user_meta_data : ce scenario l'ajoute DANS sa
-- transaction (ALTER TABLE ... ADD COLUMN IF NOT EXISTS, annule par le ROLLBACK final) ; les fonctions de la
-- migration lisent la colonne a l'appel (pg_attribute, puis EXECUTE), elles la voient donc.
-- Chaque controle leve 'PE-COURRIELS ROUGE : ...' s'il echoue. Transaction annulee a la fin.
\set ON_ERROR_STOP on
BEGIN;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_user_meta_data jsonb;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'PE-COURRIELS ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS
  $$ SELECT ('ce300000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS
  $$ SELECT ('ce30cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.langue(p_cle text) RETURNS text LANGUAGE sql AS
  $$ SELECT langue FROM public.courriels_sortants WHERE cle_idempotence = p_cle $$;
CREATE FUNCTION pg_temp.avis(p_n text) RETURNS integer LANGUAGE sql AS
  $$ SELECT count(*)::int FROM public.courriels_sortants
      WHERE modele = 'entretien_creneau_ouvert' AND destinataire_profil = pg_temp.p(p_n) $$;

-- Fixtures : a1 direction ; 01 a 06 candidats (01, 02, 03, 05 hommes ; 04 femme ; 06 homme pas encore admis) ;
-- f1, f2 fondateurs.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'pe-' || s || '@test.invalid'
  FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', 'f1', 'f2']) AS s;
-- 07 : une adresse enregistree avec des majuscules (fictive).
INSERT INTO auth.users (id, email) VALUES (pg_temp.p('07'), 'PE-07@Test.Invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('a1'), 'PE-ADM-0001', 'admin', 'Direction', 'Fictive', 'active', 'male'),
  (pg_temp.p('f1'), 'PE-FON-0001', 'admin', 'Fondateur', 'Un', 'active', 'male'),
  (pg_temp.p('f2'), 'PE-FON-0002', 'admin', 'Fondateur', 'Deux', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'PE-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END
  FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, langue)
SELECT pg_temp.c(s), 'enseignant', pg_temp.p(s), CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END,
       'Fixture ' || s,
       CASE WHEN s = '06' THEN 'prequalification' ELSE 'verifications' END,
       CASE WHEN s = '06' THEN 'en_examen' ELSE 'entretien_a_planifier' END,
       'en_cours', 'lien_public',
       CASE s WHEN '01' THEN 'ar' WHEN '02' THEN 'ar' WHEN '03' THEN 'en' WHEN '07' THEN 'ar' ELSE 'fr' END
  FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;
-- Langues d'entretien : 01, 02, 04, 06 parlent l'arabe ; 03 l'anglais ; 05 le francais seulement.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT pg_temp.c(s), 'v1-2026-10',
       CASE s WHEN '03' THEN '{"langueMaternelle": "en"}' WHEN '05' THEN '{"languesExplication": ["fr"]}'
              ELSE '{"langueMaternelle": "ar", "languesExplication": ["fr"]}' END::jsonb,
       'candidat', now() - interval '1 day'
  FROM unnest(ARRAY['01', '02', '03', '04', '05', '06']) AS s;
INSERT INTO public.personnel_fondateurs (profile_id, fondateur, modifie_par)
SELECT pg_temp.p(s), true, pg_temp.p('a1') FROM unnest(ARRAY['f1', 'f2']) AS s;
-- Une reponse importee ecrite en arabe, sans compte (adresse fictive).
INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('ce300000-0000-4000-8000-00000000a0a0', 'pe-lot-courriels-01', pg_temp.p('a1'), 'استمارة المعلمين', 'Feuille 1',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', '{}', '{}');
INSERT INTO public.formulaires_reponses (reference_source, lot_id, recue_le, genre, nom_affiche, courriel, contenu_empreinte)
VALUES ('pe-ref-01', 'ce300000-0000-4000-8000-00000000a0a0', now() - interval '20 days', 'male', 'Candidat Fictif',
        'importe-ar@test.invalid', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
SET LOCAL session_replication_role = origin;

-- ---------------------------------------------------------------- A1
SELECT public.courriel_enfiler('recrutement', 'retenu_entretien', 'pe-01@test.invalid', pg_temp.p('01'), '{}', 'pe-a');
SELECT pg_temp.vrai(pg_temp.langue('pe-a') = 'ar', 'a : sans langue choisie, la candidature en arabe : courriel en arabe');

UPDATE public.profiles SET langue_communication = 'en' WHERE id = pg_temp.p('02');
SELECT public.courriel_enfiler('recrutement', 'retenu_entretien', 'pe-02@test.invalid', pg_temp.p('02'), '{}', 'pe-b');
SELECT pg_temp.vrai(pg_temp.langue('pe-b') = 'en', 'b : la langue choisie dans le compte passe avant la candidature');

SELECT public.courriel_enfiler('recrutement', 'invitation_candidat_importe', 'pe-03@test.invalid', NULL, '{}', 'pe-c');
SELECT pg_temp.vrai(pg_temp.langue('pe-c') = 'en', 'c : sans profil, l''adresse d''un compte retrouve sa candidature (anglais)');

SELECT public.courriel_enfiler('recrutement', 'invitation_candidat_importe', 'pe-07@test.invalid', NULL, '{}', 'pe-c2');
SELECT pg_temp.vrai(pg_temp.langue('pe-c2') = 'ar', 'c2 : l''adresse du compte est retrouvee sans tenir compte de la casse');

SELECT public.courriel_enfiler('recrutement', 'attente_candidat', 'sans-compte@test.invalid', NULL, '{"langue": "ar"}', 'pe-d0');
SELECT public.courriel_enfiler('recrutement', 'invitation_candidat_importe', 'sans-compte@test.invalid', NULL, '{}', 'pe-d');
SELECT pg_temp.vrai(pg_temp.langue('pe-d') = 'ar', 'd : sans profil, la langue donnee au dernier courriel de l''adresse');

SELECT public.courriel_enfiler('recrutement', 'invitation_candidat_importe', 'importe-ar@test.invalid', NULL, '{}', 'pe-e');
SELECT pg_temp.vrai(pg_temp.langue('pe-e') = 'ar', 'e : sans profil, la reponse importee ecrite en arabe');

SELECT public.courriel_enfiler('recrutement', 'invitation_candidat_importe', 'inconnu@test.invalid', NULL, '{}', 'pe-f');
SELECT pg_temp.vrai(pg_temp.langue('pe-f') = 'fr', 'f : rien de connu : francais');

-- g. La langue du compte pour Supabase Auth.
SELECT set_config('test.g1', private.auth_langue_synchroniser(pg_temp.p('01'))::text, true);
SELECT set_config('test.g1b', private.auth_langue_synchroniser(pg_temp.p('01'))::text, true);
SELECT pg_temp.vrai(current_setting('test.g1') = 'true' AND current_setting('test.g1b') = 'false'
  AND (SELECT raw_user_meta_data ->> 'langue' FROM auth.users WHERE id = pg_temp.p('01')) = 'ar',
  'g1 : la langue de la candidature est recopiee une fois (rien a reecrire ensuite)');
UPDATE public.profiles SET langue_communication = 'fr' WHERE id = pg_temp.p('01');
SELECT pg_temp.vrai((SELECT raw_user_meta_data ->> 'langue' FROM auth.users WHERE id = pg_temp.p('01')) = 'fr',
  'g2 : le choix de langue du compte suit aussitot (declencheur des profils)');
UPDATE public.candidatures SET langue = 'ar' WHERE id = pg_temp.c('05');
SELECT pg_temp.vrai((SELECT raw_user_meta_data ->> 'langue' FROM auth.users WHERE id = pg_temp.p('05')) = 'ar',
  'g3 : la langue d''une candidature suit aussitot (declencheur des candidatures)');
UPDATE public.candidatures SET langue = 'fr' WHERE id = pg_temp.c('05');
UPDATE public.profiles SET langue_communication = NULL WHERE id = pg_temp.p('01');
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('authenticated', 'private.auth_langue_synchroniser(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.auth_langue_synchroniser(uuid)', 'EXECUTE'),
  'g4 : la recopie est fermee aux clients');

-- h. Le rattrapage n'a pas tourne a l'installation (les fixtures sont posees sans declencheur : aucune langue
--    recopiee), puis il rend le nombre de comptes changes, et 0 au second appel.
SELECT pg_temp.vrai((SELECT count(*) FROM auth.users WHERE id IN (pg_temp.p('03'), pg_temp.p('04'), pg_temp.p('06'), pg_temp.p('07'))
                       AND raw_user_meta_data IS NOT NULL) = 0,
  'h0 : rien n''est recopie tant que personne n''appelle le rattrapage');
-- g5. Un JSON null, un scalaire, un tableau : jamais touches.
UPDATE auth.users SET raw_user_meta_data = 'null'::jsonb WHERE id = pg_temp.p('03');
UPDATE auth.users SET raw_user_meta_data = '"texte"'::jsonb WHERE id = pg_temp.p('04');
UPDATE auth.users SET raw_user_meta_data = '[1, 2]'::jsonb WHERE id = pg_temp.p('06');
SELECT set_config('test.n1', private.auth_langue_rattraper()::text, true);
SELECT set_config('test.n2', private.auth_langue_rattraper()::text, true);
SELECT pg_temp.vrai(current_setting('test.n1')::int = 2 AND current_setting('test.n2') = '0',
  'h1 : le rattrapage rend le nombre de comptes changes (2 : 01 et 07 ; 03, 04, 06 intouchables ; 02 et 05 deja justes), puis 0');
SELECT pg_temp.vrai((SELECT raw_user_meta_data FROM auth.users WHERE id = pg_temp.p('03')) = 'null'::jsonb
  AND (SELECT raw_user_meta_data FROM auth.users WHERE id = pg_temp.p('04')) = '"texte"'::jsonb
  AND (SELECT raw_user_meta_data FROM auth.users WHERE id = pg_temp.p('06')) = '[1, 2]'::jsonb,
  'g5 : un JSON null, un scalaire ou un tableau n''est jamais touche');
SELECT pg_temp.vrai((SELECT raw_user_meta_data ->> 'langue' FROM auth.users WHERE id = pg_temp.p('07')) = 'ar'
  AND (SELECT raw_user_meta_data ->> 'langue' FROM auth.users WHERE id = pg_temp.p('02')) = 'en',
  'h2 : un objet ou une colonne vide recoit la langue (candidature, sinon choix du compte)');
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('authenticated', 'private.auth_langue_rattraper()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.auth_langue_rattraper()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'private.auth_langue_rattraper()', 'EXECUTE'),
  'h3 : le rattrapage est ferme aux clients');

ROLLBACK;
