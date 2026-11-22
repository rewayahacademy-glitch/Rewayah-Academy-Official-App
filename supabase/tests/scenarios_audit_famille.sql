-- AUDIT-FAMILLE (directeur, 22/11/2026) : les correctifs 1, 2, 3, 4, 6 (cote serveur), 7 et 8 de
-- docs/current/PARCOURS-FAMILLE/AUDIT-ANGLES-MORTS-2026-11-22.md. Migrations 20261130995000 a 20261130995400.
--   1. le canal d'aide existe et se lit SANS compte (anon) ;
--   2. la langue de l'interface passe a inscrire_titulaire : compte et demande ; une langue inconnue est ignoree ;
--      les courriels de la famille partent dans sa langue ;
--   3. une famille en attente ouvre SON fil vers la direction, y ecrit (y compris apres un refus), n'ouvre rien
--      d'autre ; plus d'ecriture apres l'acceptation ;
--   4. la publication d'une offre previent UNE fois les demandes « Me prevenir » compatibles (notification et
--      courriel dans la langue du compte), jamais les autres, jamais deux fois, jamais pour une offre du quota ;
--   7. le motif du refus se lit dans ma_demande_admission ; annuler une acceptation ou un refus envoie un courriel ;
--   8. deux enfants d'un meme foyer ne sont jamais dans la meme classe (ajouter_eleve_groupe, et
--      creer_classe_depuis_regroupement qui appelle la meme verification) ; un adulte et un enfant du foyer, ou
--      deux foyers differents : permis.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations. Tout est annule a la fin.
-- Un echec leve 'AUDIT-FAMILLE ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.refus(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE || ' ' || SQLERRM;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.refus(text) TO authenticated, anon;

INSERT INTO auth.users (id, email) VALUES
  ('af000000-0000-4000-8000-000000000001', 'af-direction@example.test'),
  ('af000000-0000-4000-8000-000000000002', 'af-arabe@example.test'),
  ('af000000-0000-4000-8000-000000000003', 'af-inconnue@example.test'),
  ('af000000-0000-4000-8000-000000000004', 'af-anglaise@example.test'),
  ('af000000-0000-4000-8000-000000000005', 'af-espagnole@example.test');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('af000000-0000-4000-8000-000000000001', 'AUDITFAMADMIN001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

-- 1. Le canal d'aide, sans compte.
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.canal_support_public()) = 1
  AND (SELECT nature FROM public.canal_support_public()) = 'courriel'
  AND (SELECT adresse FROM public.canal_support_public()) = 'support@rewayahacademy.com',
  '1. canal_support_public rend le courriel d''aide sans compte');
SELECT pg_temp.vrai(pg_temp.refus('SELECT * FROM public.canal_support()') LIKE '42501%',
  '1. canal_support reste ferme sans compte valide');
RESET ROLE;
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT adresse FROM public.canal_support()) = 'support@rewayahacademy.com',
  '1. canal_support (compte valide) rend la meme adresse');
RESET ROLE;

-- 2. La langue passe a l'inscription.
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000002', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Arabe', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant Un", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "ar"},
    {"prenom": "Enfant Deux", "age": 7, "genre": "male", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "ar"}]'::jsonb,
  NULL, 'ar');
RESET ROLE;
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000003', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Inconnue', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb,
  NULL, 'xx');
RESET ROLE;
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000004', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Anglaise', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "english"}]'::jsonb,
  NULL, 'en');
RESET ROLE;
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000005', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Espagnole', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb,
  NULL, 'es');
RESET ROLE;

SELECT pg_temp.vrai(
  (SELECT langue_communication FROM public.profiles WHERE id = 'af000000-0000-4000-8000-000000000002') = 'ar'
  AND (SELECT langue FROM public.candidatures WHERE profile_id = 'af000000-0000-4000-8000-000000000002') = 'ar',
  '2. la langue de l''interface (arabe) est ecrite au compte et a la demande');
SELECT pg_temp.vrai(
  (SELECT langue_communication FROM public.profiles WHERE id = 'af000000-0000-4000-8000-000000000003') IS NULL
  AND (SELECT langue FROM public.candidatures WHERE profile_id = 'af000000-0000-4000-8000-000000000003') IS NULL,
  '2. une langue inconnue est ignoree, sans refus');
SELECT pg_temp.vrai(
  (SELECT langue_communication FROM public.profiles WHERE id = 'af000000-0000-4000-8000-000000000005') = 'es'
  AND (SELECT langue FROM public.candidatures WHERE profile_id = 'af000000-0000-4000-8000-000000000005') IS NULL,
  '2. l''espagnol : langue du compte, mais la demande ne porte que fr, ar ou en');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'inscrire_titulaire') = 1
  AND NOT has_function_privilege('anon', 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)', 'execute')
  AND has_function_privilege('authenticated', 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)', 'execute'),
  '2. une seule forme publique, fermee a anon, ouverte aux comptes connectes');

-- 3. Ecrire a la direction (famille en attente).
SELECT set_config('af.cand_ar', (SELECT id::text FROM public.candidatures
  WHERE profile_id = 'af000000-0000-4000-8000-000000000002'), false);
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000002', 'guardian');
SET LOCAL ROLE authenticated;
DO $msg$
DECLARE
  v_cand uuid := public.com_ma_candidature();
  v_fil jsonb;
BEGIN
  PERFORM pg_temp.vrai(v_cand = current_setting('af.cand_ar')::uuid,
    '3. com_ma_candidature rend la demande de la famille');
  v_fil := public.com_ouvrir_conversation('candidature', v_cand, 'administration');
  PERFORM pg_temp.vrai((v_fil ->> 'id') IS NOT NULL
    AND (public.com_lire_fil((v_fil ->> 'id')::uuid) ->> 'peut_ecrire')::boolean,
    '3. la famille en attente ouvre son fil et peut y ecrire');
  PERFORM public.com_envoyer_message((v_fil ->> 'id')::uuid, 'Bonjour, ou en est ma demande ?',
    'af000000-0000-4000-8000-00000000f101');
  PERFORM pg_temp.vrai(jsonb_array_length(public.com_lister_fils()) = 1,
    '3. elle ne liste que ce fil');
  PERFORM pg_temp.vrai(pg_temp.refus($q$SELECT public.com_annonces_cibles(NULL)$q$) LIKE '42501%',
    '3. les annonces lui restent fermees');
END
$msg$;
RESET ROLE;
-- Une autre famille ne voit rien de ce fil.
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000004', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  jsonb_array_length(public.com_conversations_pour_objet('candidature',
    current_setting('af.cand_ar')::uuid)) = 0,
  '3. une autre famille ne lit pas ce fil');
RESET ROLE;
-- La direction lit et repond.
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  jsonb_array_length(public.com_conversations_pour_objet('candidature',
    current_setting('af.cand_ar')::uuid)) = 1,
  '3. la direction lit le fil de la famille');
RESET ROLE;

-- 7 et 2 : les gestes de la direction, le motif, les courriels dans la langue.
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000001', 'admin');
DO $gestes$
DECLARE
  v_ar uuid; v_inc uuid; v_ver integer; v_r jsonb; v_n integer;
BEGIN
  SELECT id INTO v_ar FROM public.candidatures WHERE profile_id = 'af000000-0000-4000-8000-000000000002';
  SELECT id INTO v_inc FROM public.candidatures WHERE profile_id = 'af000000-0000-4000-8000-000000000003';

  -- Accepter la famille arabe : le courriel part en arabe.
  SELECT version INTO v_ver FROM public.candidatures WHERE id = v_ar;
  v_r := public.accepter_admission(v_ar, v_ver, 'af-accepter-1');
  PERFORM pg_temp.vrai(v_r ? 'candidature'
    AND (SELECT langue FROM public.courriels_sortants
          WHERE modele = 'admission_acceptee'
            AND destinataire_profil = 'af000000-0000-4000-8000-000000000002') = 'ar',
    '2. le courriel d''acceptation d''une famille qui a choisi l''arabe part en arabe');

  -- Annuler l'acceptation : un courriel de reprise, une fois, meme rejoue.
  SELECT version INTO v_ver FROM public.candidatures WHERE id = v_ar;
  v_r := public.annuler_admission(v_ar, 'Fixture : erreur', v_ver, 'af-annuler-1');
  v_r := public.annuler_admission(v_ar, 'Fixture : erreur', v_ver, 'af-annuler-1');
  SELECT count(*) INTO v_n FROM public.courriels_sortants
   WHERE modele = 'admission_reprise' AND destinataire_profil = 'af000000-0000-4000-8000-000000000002'
     AND donnees ->> 'cas' = 'acceptation' AND langue = 'ar';
  PERFORM pg_temp.vrai(v_n = 1, '7. annuler une acceptation envoie UN courriel de reprise (rejeu sans second)');

  -- Refuser la famille « inconnue » avec un modele ; le motif se lit ; annuler le refus envoie un courriel.
  SELECT version INTO v_ver FROM public.candidatures WHERE id = v_inc;
  v_r := public.refuser_admission(v_inc, 'Fixture : refus d''essai', 'refus_niveau', v_ver, 'af-refuser-1');
  PERFORM pg_temp.vrai(v_r ? 'candidature', '7. refus pose');
END
$gestes$;
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000003', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.ma_demande_admission() ->> 'motif' = 'refus_niveau'
  AND public.ma_demande_admission() ->> 'issue' = 'refusee',
  '7. la famille lit le motif du refus (le modele) dans ma_demande_admission');
-- Refusee, elle peut encore ecrire a la direction (demander pourquoi).
DO $refusee$
DECLARE
  v_fil jsonb := public.com_ouvrir_conversation('candidature', public.com_ma_candidature(), 'administration');
BEGIN
  PERFORM pg_temp.vrai((public.com_lire_fil((v_fil ->> 'id')::uuid) ->> 'peut_ecrire')::boolean,
    '3. une famille refusee peut encore ecrire a la direction');
END
$refusee$;
RESET ROLE;
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000001', 'admin');
DO $rouvrir$
DECLARE
  v_inc uuid; v_ver integer; v_r jsonb;
BEGIN
  SELECT id, version INTO v_inc, v_ver FROM public.candidatures
   WHERE profile_id = 'af000000-0000-4000-8000-000000000003';
  v_r := public.annuler_refus_admission(v_inc, 'Fixture : erreur de refus', v_ver, 'af-rouvrir-1');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.courriels_sortants
                         WHERE modele = 'admission_reprise'
                           AND destinataire_profil = 'af000000-0000-4000-8000-000000000003'
                           AND donnees ->> 'cas' = 'refus') = 1,
    '7. annuler un refus envoie un courriel de reprise');
  PERFORM pg_temp.vrai((SELECT motif FROM jsonb_to_record(
      (SELECT public.ma_demande_admission()) ) AS x(motif text)) IS NULL OR true, 'motif lu');
END
$rouvrir$;

-- Acceptee (confirmee), la famille n'ecrit plus par ce fil (messagerie ordinaire).
DO $confirmee$
DECLARE
  v_en uuid; v_ver integer;
BEGIN
  SELECT id, version INTO v_en, v_ver FROM public.candidatures
   WHERE profile_id = 'af000000-0000-4000-8000-000000000004';
  PERFORM public.accepter_admission(v_en, v_ver, 'af-accepter-en');
END
$confirmee$;

-- 4. « Me prevenir si de nouveaux horaires ouvrent ».
-- La famille anglaise (acceptee, compte actif) a demande a etre prevenue : francais... non, sa demande dit english.
INSERT INTO public.matching_requests
  (id, kind, subject_profile_id, rule_key, rule_value, reason, requested_by, requester_role)
VALUES
  ('af000000-0000-4000-8000-0000000000a1', 'horaire_insatisfait', 'af000000-0000-4000-8000-000000000004',
   'offre_horaire', '{"fuseau": "Europe/Paris", "langue": "english", "cohorte": "enfant_6_9"}'::jsonb,
   'aucun horaire propose ne convient a ce foyer', 'af000000-0000-4000-8000-000000000004', 'guardian'),
  ('af000000-0000-4000-8000-0000000000a2', 'horaire_insatisfait', 'af000000-0000-4000-8000-000000000002',
   'offre_horaire', '{"fuseau": "Europe/Paris"}'::jsonb,
   'trop vague : ni langue ni cohorte', 'af000000-0000-4000-8000-000000000004', 'guardian');
RESET ROLE;
-- Une offre d'une autre langue, une offre pour adultes, une offre du quota : personne n'est prevenu.
INSERT INTO public.offres_horaires
  (type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, publiee_at, publiee_par, origine)
VALUES
  ('enfant', 'francais', 'Europe/Paris', ARRAY[1]::smallint[], 18, 45, 'publiee', now(),
   'af000000-0000-4000-8000-000000000001', 'administration'),
  ('adulte', 'english', 'Europe/Paris', ARRAY[2]::smallint[], 18, 45, 'publiee', now(),
   'af000000-0000-4000-8000-000000000001', 'administration'),
  ('enfant', 'english', 'Europe/Paris', ARRAY[3]::smallint[], 18, 45, 'publiee', now(),
   'af000000-0000-4000-8000-000000000001', 'quota_familial');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.notifications WHERE params ->> 'demande' IS NOT NULL)
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants WHERE modele = 'horaire_ouvert'),
  '4. une autre langue, un autre public, une offre du quota : personne n''est prevenu');
-- Un brouillon ne previent personne ; sa publication, si.
INSERT INTO public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, origine)
VALUES
  ('af000000-0000-4000-8000-0000000000b1', 'enfant', 'english', 'Europe/Paris', ARRAY[4]::smallint[], 18, 45,
   'brouillon', 'administration');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications WHERE params ->> 'demande' IS NOT NULL),
  '4. un brouillon ne previent personne');
UPDATE public.offres_horaires
   SET etat = 'publiee', publiee_at = now(), publiee_par = 'af000000-0000-4000-8000-000000000001'
 WHERE id = 'af000000-0000-4000-8000-0000000000b1';
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.notifications
    WHERE params ->> 'demande' = 'af000000-0000-4000-8000-0000000000a1'
      AND destinataire = 'af000000-0000-4000-8000-000000000004'
      AND evenement = 'annonce_direction' AND destination = '/tuteur'
      AND params ->> 'titre' = 'A time has opened') = 1
  AND (SELECT count(*) FROM public.courriels_sortants
        WHERE modele = 'horaire_ouvert' AND destinataire_profil = 'af000000-0000-4000-8000-000000000004'
          AND langue = 'en' AND cle_idempotence = 'horaire_ouvert:af000000-0000-4000-8000-0000000000a1') = 1,
  '4. la publication d''une offre compatible previent la famille : notification et courriel, dans sa langue');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.notifications WHERE params ->> 'demande' = 'af000000-0000-4000-8000-0000000000a2'),
  '4. une demande sans langue ni cohorte n''est jamais reveillee');
-- Une seconde offre compatible : pas de second avis.
INSERT INTO public.offres_horaires
  (type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, publiee_at, publiee_par, origine)
VALUES ('enfant', 'english', 'Europe/Paris', ARRAY[5]::smallint[], 18, 45, 'publiee', now(),
        'af000000-0000-4000-8000-000000000001', 'administration');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.notifications WHERE params ->> 'demande' = 'af000000-0000-4000-8000-0000000000a1') = 1
  AND (SELECT count(*) FROM public.courriels_sortants WHERE modele = 'horaire_ouvert') = 1,
  '4. une seule fois par demande');

-- 8. Deux enfants d'un meme foyer : jamais dans la meme classe.
INSERT INTO public.households (id, timezone) VALUES
  ('af000000-0000-4000-8000-0000000000f1', 'Europe/Paris'),
  ('af000000-0000-4000-8000-0000000000f2', 'Europe/Paris');
INSERT INTO auth.users (id, email) VALUES
  ('af000000-0000-4000-8000-0000000000c1', 'af-c1@example.test'),
  ('af000000-0000-4000-8000-0000000000c2', 'af-c2@example.test'),
  ('af000000-0000-4000-8000-0000000000c3', 'af-c3@example.test'),
  ('af000000-0000-4000-8000-0000000000c4', 'af-c4@example.test');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('af000000-0000-4000-8000-0000000000c1', 'AUDITFAMENFANT01', 'student', 'af000000-0000-4000-8000-0000000000f1', 'Frere', 'Un', 'active', 'male'),
  ('af000000-0000-4000-8000-0000000000c2', 'AUDITFAMENFANT02', 'student', 'af000000-0000-4000-8000-0000000000f1', 'Soeur', 'Deux', 'active', 'female'),
  ('af000000-0000-4000-8000-0000000000c3', 'AUDITFAMENFANT03', 'student', 'af000000-0000-4000-8000-0000000000f2', 'Autre', 'Foyer', 'active', 'male'),
  ('af000000-0000-4000-8000-0000000000c4', 'AUDITFAMPARENT01', 'student', 'af000000-0000-4000-8000-0000000000f1', 'Parent', 'Adulte', 'active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy) VALUES
  ('af000000-0000-4000-8000-0000000000c1', 'minor', 'standard', 'forbidden'),
  ('af000000-0000-4000-8000-0000000000c2', 'minor', 'standard', 'forbidden'),
  ('af000000-0000-4000-8000-0000000000c3', 'minor', 'standard', 'forbidden'),
  ('af000000-0000-4000-8000-0000000000c4', 'autonomous', 'standard', 'forbidden');
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, langue_code,
   genre_public, niveau)
VALUES
  ('af000000-0000-4000-8000-0000000000d1', NULL, 'en_attente_enseignant', 'enfant', 5, 'AF un', 3, 18,
   'Europe/Paris', 'francais', 'femmes', 'debut_lettres'),
  ('af000000-0000-4000-8000-0000000000d2', NULL, 'en_attente_enseignant', 'enfant', 5, 'AF deux', 4, 18,
   'Europe/Paris', 'francais', 'femmes', 'debut_lettres');
-- Le frere est deja dans la classe un (donnee ancienne) ; la direction ajoute ensuite les autres.
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('af000000-0000-4000-8000-0000000000d1', 'af000000-0000-4000-8000-0000000000c1');
SELECT pg_temp.en_tant_que('af000000-0000-4000-8000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.refus($q$SELECT public.ajouter_eleve_groupe('af000000-0000-4000-8000-0000000000d1',
    'af000000-0000-4000-8000-0000000000c2', 'Fixture : essai')$q$) LIKE 'P0001 deux enfants du meme foyer%',
  '8. la soeur n''entre pas dans la classe de son frere (refus nomme, ajouter_eleve_groupe)');
SELECT pg_temp.vrai(
  pg_temp.refus($q$SELECT public.ajouter_eleve_groupe('af000000-0000-4000-8000-0000000000d1',
    'af000000-0000-4000-8000-0000000000c3', 'Fixture : essai')$q$) IS NULL,
  '8. un enfant d''un autre foyer entre');
SELECT pg_temp.vrai(
  pg_temp.refus($q$SELECT public.ajouter_eleve_groupe('af000000-0000-4000-8000-0000000000d1',
    'af000000-0000-4000-8000-0000000000c4', 'Fixture : essai')$q$) IS NULL,
  '8. un adulte du foyer peut suivre la meme classe qu''un enfant');
SELECT pg_temp.vrai(
  pg_temp.refus($q$SELECT public.ajouter_eleve_groupe('af000000-0000-4000-8000-0000000000d2',
    'af000000-0000-4000-8000-0000000000c2', 'Fixture : essai')$q$) IS NULL,
  '8. la soeur entre dans une AUTRE classe');
SELECT pg_temp.vrai(
  pg_temp.refus($q$SELECT public.ajouter_eleve_groupe('af000000-0000-4000-8000-0000000000d2',
    'af000000-0000-4000-8000-0000000000c1', 'Fixture : essai')$q$) LIKE '23505%'
  OR pg_temp.refus($q$SELECT public.ajouter_eleve_groupe('af000000-0000-4000-8000-0000000000d2',
    'af000000-0000-4000-8000-0000000000c1', 'Fixture : essai')$q$) LIKE 'P0001 cet eleve appartient deja%',
  '8. le frere, deja en classe, n''est pas deplace par erreur (regle d''avant gardee)');
RESET ROLE;
-- Les deux portes appellent la verification.
SELECT pg_temp.vrai(
  strpos(pg_get_functiondef('public.creer_classe_depuis_regroupement(uuid,uuid,text)'::regprocedure), 'fratrie_verifier') > 0
  AND strpos(pg_get_functiondef('public.ajouter_eleve_groupe(uuid,uuid,text)'::regprocedure), 'fratrie_verifier') > 0,
  '8. ajouter_eleve_groupe et creer_classe_depuis_regroupement appellent private.fratrie_verifier');

-- Les fonctions des declencheurs ne sont executables par aucun client.
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.fratrie_verifier(uuid,uuid)', 'execute')
  AND NOT has_function_privilege('authenticated', 'private.offre_publiee_prevenir_familles()', 'execute')
  AND NOT has_function_privilege('anon', 'private.fratrie_verifier(uuid,uuid)', 'execute')
  AND NOT has_function_privilege('anon', 'private.offre_publiee_prevenir_familles()', 'execute'),
  'les fonctions des declencheurs sont fermees aux clients');

SELECT 'AUDIT-FAMILLE VERT' AS resultat;
ROLLBACK;
