-- CANDIDATS-FLUX (PLAN-LOTS §7 rang 22 k, 06/11/2026). Migration
-- 20261110300000_candidats_flux.sql.
--
-- Cas couverts : (a) le reglage courriels.non_essentiels_par_jour (300 par
-- defaut, 1 a 2000, refus d'un texte, de 0, de 2001) ; (b) la file a 15 par
-- jour : 40 invitations et 5 messages essentiels ; le premier lot prend les 5
-- essentiels et 15 invitations ; les lots suivants du meme jour ne prennent
-- aucune invitation mais tous les essentiels nouveaux ; le lendemain (24 h
-- simulees), 15 de plus ; le surlendemain les 10 dernieres ; aucune ligne
-- reservee deux fois ; (c) le reglage releve en cours de route ; (d) Prevenir
-- avec doublons et un desinscrit : une invitation par adresse (cle
-- lien_inscription:<adresse>), le desinscrit exclu et compte a part, la
-- langue du message d'attente reprise, l'arabe pour un nom arabe, rien deux
-- fois au second appel ; (e) l'etat de la file pour la direction.
-- Chaque controle leve 'CANDIDATS-FLUX ROUGE : ...' s'il echoue. A rejouer sur
-- une base NEUVE ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : %', p_label;
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
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.r(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('cf107777-0000-4000-8000-0000000000' || p_n)::uuid $$;


GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.p(text),
  pg_temp.r(text) TO authenticated, anon;

-- Reserve un lot comme le travailleur (service_role) et rend les lignes.
CREATE FUNCTION pg_temp.reserver(p_lot integer) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  v := public.courriels_reserver(p_lot);
  EXECUTE 'RESET ROLE';
  -- Le travailleur consigne chaque envoi.
  UPDATE public.courriels_sortants s SET statut = 'envoye', envoye_le = now()
   WHERE s.id IN (SELECT (e->>'id')::uuid FROM jsonb_array_elements(v) e);
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.nb(p_v jsonb, p_essentielle boolean) RETURNS integer
LANGUAGE sql AS $$ SELECT count(*)::integer FROM jsonb_array_elements(p_v) e
                    WHERE (e->>'modele' <> 'lien_inscription') = p_essentielle $$;
-- Fait passer un jour : tout ce qui a ete reserve l'a ete il y a 25 heures.
CREATE FUNCTION pg_temp.un_jour_passe() RETURNS void
LANGUAGE sql AS $$
  UPDATE public.courriels_sortants SET reserve_le = reserve_le - interval '25 hours'
   WHERE reserve_le IS NOT NULL;
$$;
-- Toutes les reservations du scenario, pour prouver qu'aucune ligne ne part deux fois.
CREATE TEMP TABLE reservees (id uuid, tour integer);

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES (pg_temp.p('a1'), 'flux-a1@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'CF10-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male');

-- Comme en production depuis le 25/10/2026 : la categorie recrutement est non
-- essentielle (le depot la seme essentielle ; reglage pose hors migration).
UPDATE public.courriel_categories SET essentielle = false WHERE code = 'recrutement';

-- Une file vide au depart (la base neuve n'a aucun envoi).
SELECT pg_temp.vrai((SELECT count(*) FROM public.courriels_sortants) = 0, 'z0 : file vide au depart');

-- ------------------------------------------------------------
-- (a) Le reglage
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'courriels.non_essentiels_par_jour') = '300'::jsonb,
  'a1 : 300 par defaut');
DO $$
DECLARE v_val text; v_ok boolean;
BEGIN
  FOREACH v_val IN ARRAY ARRAY['0', '2001', '"cent"', '12.5', '-3'] LOOP
    v_ok := false;
    BEGIN
      UPDATE public.app_config SET value = v_val::jsonb WHERE key = 'courriels.non_essentiels_par_jour';
    EXCEPTION WHEN SQLSTATE '22023' THEN v_ok := true;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : a2 : valeur % acceptee', v_val; END IF;
  END LOOP;
  RAISE NOTICE 'OK a2 : 0, 2001, texte, decimal et negatif refuses';
END $$;
-- La direction regle 15 par jour, par la table (RLS app_config_admin_update).
SELECT pg_temp.qui(pg_temp.p('a1'), 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = '15'::jsonb WHERE key = 'courriels.non_essentiels_par_jour';
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'courriels.non_essentiels_par_jour') = '15'::jsonb,
  'a3 : la direction regle 15 par jour');

-- ------------------------------------------------------------
-- (b) La file a 15 par jour
-- ------------------------------------------------------------
-- 40 invitations (recrutement, non essentiel) en file AVANT 5 messages
-- essentiels (compte) : l'ordre d'arrivee ne doit pas retarder les essentiels.
SELECT public.courriel_enfiler('recrutement', 'lien_inscription', 'flux-' || g || '@test.invalid', NULL,
  '{}'::jsonb, 'lien_inscription:flux-' || g || '@test.invalid', 'manuel', pg_temp.p('a1'))
  FROM generate_series(1, 40) g;
UPDATE public.courriels_sortants SET prochaine_tentative = now() - interval '1 hour'
 WHERE modele = 'lien_inscription';
SELECT public.courriel_enfiler('compte', 'message_libre', 'flux-ess-' || g || '@test.invalid', NULL,
  '{}'::jsonb, 'flux-ess-' || g, 'manuel', pg_temp.p('a1'))
  FROM generate_series(1, 5) g;
SELECT pg_temp.vrai((SELECT count(*) FROM public.courriels_sortants) = 45, 'b0 : 40 invitations et 5 essentiels en file');

DO $$
DECLARE v jsonb;
BEGIN
  v := pg_temp.reserver(20);
  INSERT INTO reservees SELECT (e->>'id')::uuid, 1 FROM jsonb_array_elements(v) e;
  IF pg_temp.nb(v, true) <> 5 OR pg_temp.nb(v, false) <> 15 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : b1 : % essentiels et % invitations au lieu de 5 et 15',
      pg_temp.nb(v, true), pg_temp.nb(v, false);
  END IF;
  RAISE NOTICE 'OK b1 : premier lot de 20 = 5 essentiels + 15 invitations';
  v := pg_temp.reserver(20);
  IF jsonb_array_length(v) <> 0 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : b2 : % lignes au second lot du jour', jsonb_array_length(v);
  END IF;
  RAISE NOTICE 'OK b2 : le plafond du jour est atteint, plus aucune invitation';
END $$;

-- Un message essentiel arrive le meme jour, et deux messages individuels de
-- la categorie recrutement (non essentielle) : ils partent tout de suite.
SELECT public.courriel_enfiler('compte', 'message_libre', 'flux-ess-tard@test.invalid', NULL,
  '{}'::jsonb, 'flux-ess-tard', 'manuel', pg_temp.p('a1'));
SELECT public.courriel_enfiler('recrutement', 'compte_enseignant_valide', 'flux-d2@test.invalid', NULL,
  '{}'::jsonb, 'flux-d2', 'auto', NULL);
SELECT public.courriel_enfiler('recrutement', 'invitation_enseignant', 'flux-i1@test.invalid', NULL,
  '{"code": "X"}'::jsonb, 'flux-i1', 'manuel', pg_temp.p('a1'));
DO $$
DECLARE v jsonb;
BEGIN
  v := pg_temp.reserver(20);
  INSERT INTO reservees SELECT (e->>'id')::uuid, 2 FROM jsonb_array_elements(v) e;
  IF pg_temp.nb(v, true) <> 3 OR pg_temp.nb(v, false) <> 0 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : b3 : % essentiels et % invitations au lieu de 3 et 0',
      pg_temp.nb(v, true), pg_temp.nb(v, false);
  END IF;
  RAISE NOTICE 'OK b3 : apres le plafond, un essentiel, « compte enseignant valide » et une invitation d''enseignant partent quand meme';
END $$;

-- (e) L'etat de la file, cote direction, au soir du premier jour.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.etat_file_courriels()')
    = '{"parJour": 15, "partis24h": 15, "enAttente": 25, "joursEstimes": 2}'::jsonb,
  'e1 : la direction lit 15 par jour, 15 partis, 25 en attente, 2 jours');
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.etat_file_courriels()', '42501', 'e2 : sans session, refus');

-- Le lendemain.
SELECT pg_temp.un_jour_passe();
DO $$
DECLARE v jsonb; v2 jsonb;
BEGIN
  v := pg_temp.reserver(20);
  INSERT INTO reservees SELECT (e->>'id')::uuid, 3 FROM jsonb_array_elements(v) e;
  v2 := pg_temp.reserver(20);
  INSERT INTO reservees SELECT (e->>'id')::uuid, 3 FROM jsonb_array_elements(v2) e;
  IF pg_temp.nb(v, false) + pg_temp.nb(v2, false) <> 15 OR pg_temp.nb(v, true) + pg_temp.nb(v2, true) <> 0 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : b4 : % invitations le deuxieme jour au lieu de 15',
      pg_temp.nb(v, false) + pg_temp.nb(v2, false);
  END IF;
  RAISE NOTICE 'OK b4 : le deuxieme jour, 15 invitations de plus, pas une de trop';
END $$;

-- (c) La direction releve le reglage a 300 le troisieme jour : les 10 dernieres partent.
SELECT pg_temp.un_jour_passe();
UPDATE public.app_config SET value = '300'::jsonb WHERE key = 'courriels.non_essentiels_par_jour';
DO $$
DECLARE v jsonb;
BEGIN
  v := pg_temp.reserver(20);
  INSERT INTO reservees SELECT (e->>'id')::uuid, 4 FROM jsonb_array_elements(v) e;
  IF pg_temp.nb(v, false) <> 10 THEN
    RAISE EXCEPTION 'CANDIDATS-FLUX ROUGE : c1 : % invitations le troisieme jour au lieu de 10', pg_temp.nb(v, false);
  END IF;
  RAISE NOTICE 'OK c1 : le troisieme jour, les 10 dernieres';
END $$;
SELECT pg_temp.vrai(
  (SELECT count(*) = count(DISTINCT id) AND count(*) = 48 FROM reservees)
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE statut <> 'envoye')
  AND (SELECT max(tentatives) FROM public.courriels_sortants) = 1,
  'c2 : 48 lignes reservees chacune une seule fois, tout est parti, aucune deux fois');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants WHERE modele = 'lien_inscription'
     AND reserve_le > now() - interval '72 hours' - interval '1 hour') = 40,
  'c3 : les 40 invitations sont parties sur trois jours');

-- ------------------------------------------------------------
-- (d) Prevenir : doublons, desinscrit, langue
-- ------------------------------------------------------------
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';
INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
VALUES ('cf105555-0000-4000-8000-000000000001', 'cle-lot-flux-0001', pg_temp.p('a1'),
        'Candidature enseignants Rewayah (réponses)', 'Réponses au formulaire 1', md5('lotflux'), '{}', '{}');
-- 01 et 02 : la meme adresse (doublon) ; 03 : desinscrit du recrutement ;
-- 04 : a recu le message d'attente en anglais ; 05 : nom ecrit en arabe ;
-- 06 : rien de connu (francais par defaut).
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         reponses, contenu_empreinte)
VALUES
 (pg_temp.r('01'), 'flux|r|01', 'cf105555-0000-4000-8000-000000000001', '2026-10-14 09:30+00', 'male',
  'Reponse Un', 'pre-01@test.invalid', '{}', md5('f01')),
 (pg_temp.r('02'), 'flux|r|02', 'cf105555-0000-4000-8000-000000000001', '2026-10-16 09:30+00', 'male',
  'Reponse Deux', 'pre-01@test.invalid', '{}', md5('f02')),
 (pg_temp.r('03'), 'flux|r|03', 'cf105555-0000-4000-8000-000000000001', '2026-10-14 10:00+00', 'male',
  'Reponse Trois', 'pre-03@test.invalid', '{}', md5('f03')),
 (pg_temp.r('04'), 'flux|r|04', 'cf105555-0000-4000-8000-000000000001', '2026-10-14 11:00+00', 'male',
  'Reponse Quatre', 'pre-04@test.invalid', '{}', md5('f04')),
 (pg_temp.r('05'), 'flux|r|05', 'cf105555-0000-4000-8000-000000000001', '2026-10-14 12:00+00', 'male',
  'عبد الله يوسف', 'pre-05@test.invalid', '{}', md5('f05')),
 (pg_temp.r('06'), 'flux|r|06', 'cf105555-0000-4000-8000-000000000001', '2026-10-14 13:00+00', 'male',
  'Reponse Six', 'pre-06@test.invalid', '{}', md5('f06'));
INSERT INTO public.courriel_desinscriptions (adresse, categorie) VALUES ('pre-03@test.invalid', 'recrutement');
SELECT public.courriel_enfiler('recrutement', 'attente_candidat', 'pre-04@test.invalid', NULL,
  '{"langue": "en"}'::jsonb, 'candidat_attente:pre-04@test.invalid', 'manuel', pg_temp.p('a1'));

SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.apercu_prevenir_par_courriel()')
    = '{"aPrevenir": 4, "desinscrits": 1, "dejaPrevenus": 0, "dejaInscrits": 0, "inscriptionOuverte": true}'::jsonb,
  'd1 : 4 adresses a prevenir (doublon compte une fois), le desinscrit a part');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(2000)')
    = '{"misEnFile": 4, "restants": 0}'::jsonb,
  'd2 : 4 invitations en file, plus personne a prevenir (le desinscrit ne reste pas compte)');
SELECT pg_temp.vrai(
  (SELECT array_agg(cle_idempotence ORDER BY cle_idempotence) FROM public.courriels_sortants
    WHERE modele = 'lien_inscription' AND destinataire_adresse LIKE 'pre-%')
    = ARRAY['lien_inscription:pre-01@test.invalid', 'lien_inscription:pre-04@test.invalid',
            'lien_inscription:pre-05@test.invalid', 'lien_inscription:pre-06@test.invalid'],
  'd3 : une invitation par adresse, cle lien_inscription:<adresse>, rien pour le desinscrit');
SELECT pg_temp.vrai(
  (SELECT jsonb_object_agg(destinataire_adresse, langue) FROM public.courriels_sortants
    WHERE modele = 'lien_inscription' AND destinataire_adresse LIKE 'pre-%')
    = '{"pre-01@test.invalid": "fr", "pre-04@test.invalid": "en", "pre-05@test.invalid": "ar",
        "pre-06@test.invalid": "fr"}'::jsonb,
  'd4 : la langue du message d''attente (en), l''arabe pour un nom arabe, sinon le francais');
SELECT pg_temp.vrai(
  (SELECT (donnees->>'date_reponse')::timestamptz = '2026-10-14 09:30+00' FROM public.courriels_sortants
    WHERE cle_idempotence = 'lien_inscription:pre-01@test.invalid'),
  'd5 : le doublon rappelle la date de la reponse la plus ancienne');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(2000)')
    = '{"misEnFile": 0, "restants": 0}'::jsonb
  AND (SELECT count(*) FROM public.courriels_sortants WHERE modele = 'lien_inscription'
         AND destinataire_adresse LIKE 'pre-%') = 4,
  'd6 : un second appel ne met rien en file (jamais deux)');
-- Une nouvelle reponse arrive pour une adresse deja invitee, et une invitation
-- annulee : ni l'une ni l'autre ne repart.
INSERT INTO public.formulaires_reponses (id, reference_source, lot_id, recue_le, genre, nom_affiche, courriel,
                                         reponses, contenu_empreinte)
VALUES (pg_temp.r('07'), 'flux|r|07', 'cf105555-0000-4000-8000-000000000001', '2026-10-20 13:00+00', 'male',
        'Reponse Sept', 'pre-06@test.invalid', '{}', md5('f07'));
UPDATE public.courriels_sortants SET statut = 'annule' WHERE cle_idempotence = 'lien_inscription:pre-04@test.invalid';
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(2000)')
    = '{"misEnFile": 0, "restants": 0}'::jsonb,
  'd7 : ni une nouvelle reponse a une adresse invitee, ni une invitation annulee ne repartent');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.prevenir_par_courriel(2001)', '22023',
  'd8 : limite 2001 refusee');

-- ------------------------------------------------------------
-- (f) Langues des cours (rang 22 m)
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT array_agg(code ORDER BY ordre) FROM public.langues_cours)
    = ARRAY['poular', 'francais', 'english', 'man', 'ar', 'pt']
  AND (SELECT nom_humain FROM public.langues_cours WHERE code = 'man') = 'Malinké (mandinka)',
  'f1 : man « Malinke (mandinka) », ar et pt sont des langues de cours');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM private.formulaires_libelles WHERE champ = 'langue' AND valeur = 'mnk'),
  'f2 : plus aucun libelle importe vers mnk');
CREATE TEMP TABLE lu_langues AS
SELECT private.formulaires_lire(
  'Horodateur,هل أنت,الاسم الكامل,رقم الواتساب مع رمز الدولة,ما هي لغتك الأم,بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه,البريد الألكتروني'
  || E'\n' || '14/10/2026 09:00:00,ذكر,Essai Un,+33600000001,الماندينكا,"العربية, الماندينكا, الفرنسية",un@test.invalid'
  || E'\n' || '14/10/2026 09:05:00,ذكر,Essai Deux,+33600000002,العربية,العربية,deux@test.invalid',
  'Classeur flux', 'Onglet flux', NULL, 'Europe/Paris') AS j;
SELECT pg_temp.vrai(
  (SELECT j -> 'lignes' -> 0 -> 'reponses' FROM lu_langues)
    = '{"langueMaternelle": "man", "languesExplication": ["ar", "man", "francais"]}'::jsonb,
  'f3 : une reponse en mandinka (mnk) arrive en man ; l''arabe de la colonne F est garde');
SELECT pg_temp.vrai(
  (SELECT j -> 'lignes' -> 1 -> 'reponses' -> 'languesExplication' FROM lu_langues) = '["ar"]'::jsonb
  AND (SELECT j -> 'lignes' -> 1 -> 'avertissements' FROM lu_langues) = '[]'::jsonb,
  'f4 : « arabe » seul en colonne F donne la langue ar, sans avertissement « arabe retire »');
SELECT pg_temp.vrai(
  (SELECT bool_and((o ->> 'referentiel')::boolean)
     FROM jsonb_array_elements(private.questionnaire_langues('{"languesHorsReferentiel": ["man", "ar", "mnk"]}'::jsonb)) o
    WHERE o ->> 'code' IN ('man', 'ar', 'pt')),
  'f5 : le questionnaire propose man, ar et pt comme langues de cours (referentiel)');

ROLLBACK;
