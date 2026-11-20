-- PE-A1 et PE-A7 (lot COURRIELS-CANDIDAT, 20/11/2026) : migrations 20261130940000 et 20261130941000.
--
-- A1, la langue d'un courriel de candidat :
--   a. un compte sans langue choisie mais dont la candidature est en arabe : le courriel part en arabe ;
--   b. la langue choisie dans le compte passe avant celle de la candidature ;
--   c. sans profil : l'adresse d'un compte existant retrouve sa candidature ;
--   d. sans profil : la langue donnee explicitement au dernier courriel de l'adresse ;
--   e. sans profil : la reponse importee ecrite en arabe ;
--   f. rien de connu : le francais ;
--   g. la langue du compte est recopiee dans user_metadata.langue (Supabase Auth), puis suit le choix du compte.
-- A7, l'avis quand un creneau d'entretien s'ouvre :
--   h. un creneau tenable du bon cote et d'une langue commune : UN courriel au candidat qui attend, dans sa langue ;
--   i. ni a l'autre cote, ni a une autre langue, ni a un candidat qui n'attend pas ;
--   j. un second creneau dans la foulee : pas de second courriel ;
--   k. un creneau non tenable (sans fondateurs) ou annule avant la fin de la transaction : aucun courriel ;
--   l. le modele passe hors plafond, et la fonction de l'avis est fermee aux clients.
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
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  (pg_temp.p('a1'), 'PE-ADM-0001', 'admin', 'Direction', 'Fictive', 'active', 'male'),
  (pg_temp.p('f1'), 'PE-FON-0001', 'admin', 'Fondateur', 'Un', 'active', 'male'),
  (pg_temp.p('f2'), 'PE-FON-0002', 'admin', 'Fondateur', 'Deux', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'PE-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END
  FROM unnest(ARRAY['01', '02', '03', '04', '05', '06']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, langue)
SELECT pg_temp.c(s), 'enseignant', pg_temp.p(s), CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END,
       'Fixture ' || s,
       CASE WHEN s = '06' THEN 'prequalification' ELSE 'verifications' END,
       CASE WHEN s = '06' THEN 'en_examen' ELSE 'entretien_a_planifier' END,
       'en_cours', 'lien_public',
       CASE s WHEN '01' THEN 'ar' WHEN '02' THEN 'ar' WHEN '03' THEN 'en' ELSE 'fr' END
  FROM unnest(ARRAY['01', '02', '03', '04', '05', '06']) AS s;
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

-- ---------------------------------------------------------------- A7
-- h, i. Un creneau homme, arabe, dans deux jours, deux fondateurs.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce300000-0000-4000-8000-000000000501', 'male', now() + interval '2 days', 30, ARRAY['ar'], pg_temp.p('a1'));
INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
VALUES ('ce300000-0000-4000-8000-000000000501', pg_temp.p('f1')), ('ce300000-0000-4000-8000-000000000501', pg_temp.p('f2'));
SELECT pg_temp.vrai(pg_temp.avis('01') = 0, 'h0 : differe : rien avant la fin de la transaction (participants poses apres le creneau)');
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('01') = 1 AND pg_temp.avis('02') = 1,
  'h1 : les deux candidats qui attendent, du bon cote, de langue commune : un avis chacun');
SELECT pg_temp.vrai(
  (SELECT langue FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert' AND destinataire_profil = pg_temp.p('01')) = 'ar'
  AND (SELECT langue FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert' AND destinataire_profil = pg_temp.p('02')) = 'en',
  'h2 : chaque avis part dans la langue de la personne');
SELECT pg_temp.vrai(pg_temp.avis('03') = 0 AND pg_temp.avis('04') = 0 AND pg_temp.avis('05') = 0 AND pg_temp.avis('06') = 0,
  'i1 : ni l''autre langue (03, 05), ni l''autre cote (04), ni un candidat pas encore admis (06)');

-- j. Un second creneau dans la foulee.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce300000-0000-4000-8000-000000000502', 'male', now() + interval '3 days', 30, ARRAY['ar', 'en'], pg_temp.p('a1'));
INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
VALUES ('ce300000-0000-4000-8000-000000000502', pg_temp.p('f1')), ('ce300000-0000-4000-8000-000000000502', pg_temp.p('f2'));
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('01') = 1 AND pg_temp.avis('02') = 1 AND pg_temp.avis('03') = 1,
  'j1 : pas de second avis en 20 heures ; 03 (anglais) prevenu par ce creneau-ci');

-- k. Non tenable (aucun fondateur) ; annule avant la fin de la transaction.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce300000-0000-4000-8000-000000000503', 'male', now() + interval '3 days', 30, ARRAY['fr'], pg_temp.p('a1'));
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('05') = 0, 'k1 : un creneau non tenable ne previent personne');
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce300000-0000-4000-8000-000000000504', 'male', now() + interval '3 days', 30, ARRAY['fr'], pg_temp.p('a1'));
INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
VALUES ('ce300000-0000-4000-8000-000000000504', pg_temp.p('f1')), ('ce300000-0000-4000-8000-000000000504', pg_temp.p('f2'));
UPDATE public.entretien_creneaux SET annule_le = now(), annule_par = pg_temp.p('a1')
 WHERE id = 'ce300000-0000-4000-8000-000000000504';
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SET CONSTRAINTS entretien_creneau_ouvert_avis DEFERRED;
SELECT pg_temp.vrai(pg_temp.avis('05') = 0, 'k2 : un creneau annule avant la fin de la transaction ne previent personne');

-- Le meme creneau, tenable : 05 (francais) est prevenu.
INSERT INTO public.entretien_creneaux (id, cote, debut, duree_minutes, langues, ouvert_par)
VALUES ('ce300000-0000-4000-8000-000000000505', 'male', now() + interval '4 days', 30, ARRAY['fr'], pg_temp.p('a1'));
INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
VALUES ('ce300000-0000-4000-8000-000000000505', pg_temp.p('f1')), ('ce300000-0000-4000-8000-000000000505', pg_temp.p('f2'));
SET CONSTRAINTS entretien_creneau_ouvert_avis IMMEDIATE;
SELECT pg_temp.vrai(pg_temp.avis('05') = 1, 'k3 : temoin, le creneau tenable et ouvert previent 05');

-- l.
SELECT pg_temp.vrai(private.courriel_hors_plafond(false, 'entretien_creneau_ouvert')
  AND NOT private.courriel_hors_plafond(false, 'lien_inscription'),
  'l1 : l''avis part hors plafond, pas les envois en nombre');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.entretien_creneau_ouvert_prevenir()', 'EXECUTE'),
  'l2 : la fonction de l''avis est fermee aux clients');
SELECT pg_temp.vrai((SELECT bool_and(categorie = 'recrutement' AND NOT essentielle_calc)
                       FROM (SELECT s.categorie, k.essentielle AS essentielle_calc FROM public.courriels_sortants s
                               JOIN public.courriel_categories k ON k.code = s.categorie
                              WHERE s.modele = 'entretien_creneau_ouvert') x)
  AND (SELECT bool_and(donnees ? 'jeton_desinscription') FROM public.courriels_sortants WHERE modele = 'entretien_creneau_ouvert'),
  'l3 : categorie recrutement, lien de desinscription present');

ROLLBACK;
