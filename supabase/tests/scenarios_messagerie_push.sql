-- MESSAGERIE-PUSH (14/11/2026) : la direction prevenue (notification a faire,
-- push, courriel) a chaque message d'un candidat (migration 20261125850000).
-- Prouve :
--   1. un message du candidat cree UNE notification « message_candidat_recu »
--      pour la direction de son cote et le super-admin, a faire, vers le fil ;
--      ni l'autre cote, ni le candidat ; aucun nom dans params ;
--   2. un second message du meme fil n'en cree pas d'autre (un push par fil) ;
--   3. push (abonne) et courriel (categorie recrutement) sont mis en file ;
--   4. la lecture du fil par une direction clot SA notification, pas celle de
--      l'autre ; le message suivant en rouvre une ;
--   5. un message de la direction ne notifie personne ;
--   6. un message dans un fil qui n'est pas une candidature ne notifie pas.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'MSG-PUSH ROUGE : %', p_label;
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
  RETURN SQLSTATE;
END $$;
-- Le signal de [p_qui], lu en superutilisateur (hors RLS).
CREATE FUNCTION pg_temp.signal(p_qui uuid) RETURNS public.com_signaux
LANGUAGE sql AS $$ SELECT s FROM public.com_signaux s WHERE s.destinataire = p_qui $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text),
  pg_temp.refus(text) TO authenticated, anon;

INSERT INTO auth.users (id, email) VALUES
 ('7c600000-0000-4000-8000-0000000000a1', 'pu-a1@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000b1', 'pu-h1@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000b2', 'pu-sa@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000c1', 'pu-c1@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000c2', 'pu-c2@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000e1', 'pu-g1@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000e2', 'pu-s1@test.invalid'),
 ('7c600000-0000-4000-8000-0000000000d2', 'pu-t2@test.invalid');
INSERT INTO public.households (id, timezone) VALUES
 ('7c600000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7c600000-0000-4000-8000-0000000000a1', 'RA-26-7601', 'admin', NULL, 'Amina', 'TR', 'active', 'female'),
 ('7c600000-0000-4000-8000-0000000000b1', 'RA-26-7602', 'admin', NULL, 'Bilal', 'TR', 'active', 'male'),
 ('7c600000-0000-4000-8000-0000000000b2', 'RA-26-7603', 'admin', NULL, 'Sami', 'TR', 'active', 'male'),
 ('7c600000-0000-4000-8000-0000000000c1', 'RA-26-7604', 'teacher', NULL, 'Khadija', 'TR', 'pending_kyc', 'female'),
 ('7c600000-0000-4000-8000-0000000000c2', 'RA-26-7605', 'teacher', NULL, 'Maryam', 'TR', 'pending_kyc', 'female'),
 ('7c600000-0000-4000-8000-0000000000e1', 'RA-26-7606', 'guardian', '7c600000-0000-4000-8000-0000000000f1', 'Samir', 'TR', 'active', 'male'),
 ('7c600000-0000-4000-8000-0000000000e2', 'RA-26-7607', 'student', '7c600000-0000-4000-8000-0000000000f1', 'Ilyas', 'TR', 'active', 'male'),
 ('7c600000-0000-4000-8000-0000000000d2', 'RA-26-7608', 'teacher', NULL, 'Hafsa', 'TR', 'provisional_active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('7c600000-0000-4000-8000-0000000000b2');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
 ('7c600000-0000-4000-8000-000000000101', 'enseignant', '7c600000-0000-4000-8000-0000000000c1', 'female',
  'Fixture PU un', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public'),
 ('7c600000-0000-4000-8000-000000000102', 'enseignant', '7c600000-0000-4000-8000-0000000000c2', 'female',
  'Fixture PU deux', 'verifications', 'entretien_a_planifier', 'en_cours', 'lien_public');

INSERT INTO public.abonnements_push (profile_id, endpoint, p256dh, auth)
VALUES ('7c600000-0000-4000-8000-0000000000a1', 'https://fcm.googleapis.com/fcm/send/fixture-pu',
        repeat('A', 87), repeat('B', 22));

CREATE FUNCTION pg_temp.n(p_qui text, p_ouvertes boolean DEFAULT true) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::integer FROM public.notifications n
   WHERE n.destinataire = ('7c600000-0000-4000-8000-0000000000' || p_qui)::uuid
     AND n.evenement = 'message_candidat_recu'
     AND (NOT p_ouvertes OR (n.geste_fait_le IS NULL AND n.ecartee_le IS NULL)) $$;

SET LOCAL ROLE authenticated;
DO $c1$
DECLARE
  v_id uuid;
BEGIN
  PERFORM pg_temp.en_tant_que('7c600000-0000-4000-8000-0000000000c1', 'teacher');
  v_id := (public.com_ouvrir_conversation('candidature', '7c600000-0000-4000-8000-000000000101', 'administration') ->> 'id')::uuid;
  PERFORM set_config('test.fil', v_id::text, true);
  PERFORM public.com_envoyer_message(v_id, 'Bonjour.', '7c600000-0000-4000-8000-00000000a001');
END
$c1$;
RESET ROLE;

SELECT pg_temp.vrai(pg_temp.n('a1') = 1 AND pg_temp.n('b2') = 1 AND pg_temp.n('b1') = 0
  AND pg_temp.n('c1') = 0 AND pg_temp.n('c2') = 0,
  '1. la direction du cote du candidat et le super-admin, une notification chacun ; personne d''autre');
SELECT pg_temp.vrai((SELECT n.geste_requis AND n.destination = '/admin/operations/communications/messages/' || current_setting('test.fil')
                       AND n.params ->> 'portee' = 'direction'
                       AND NOT (n.params ? 'prenom') AND NOT (n.params ? 'texte')
                       FROM public.notifications n
                      WHERE n.destinataire = '7c600000-0000-4000-8000-0000000000a1'
                        AND n.evenement = 'message_candidat_recu'),
  '1. a faire, vers le fil, portee direction, sans nom ni texte');

SET LOCAL ROLE authenticated;
DO $c2$
BEGIN
  PERFORM pg_temp.en_tant_que('7c600000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM public.com_envoyer_message(current_setting('test.fil')::uuid, 'Encore moi.', '7c600000-0000-4000-8000-00000000a002');
END
$c2$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.n('a1', false) = 1 AND pg_temp.n('b2', false) = 1,
  '2. un second message du meme fil ne cree pas une seconde notification');

SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.push_sortants s
           WHERE s.destinataire = '7c600000-0000-4000-8000-0000000000a1'
             AND s.evenement = 'message_candidat_recu' AND s.tag = 'messages_candidats')
  AND NOT EXISTS (SELECT 1 FROM public.push_sortants s
           WHERE s.destinataire = '7c600000-0000-4000-8000-0000000000b2'),
  '3. le push part vers la direction abonnee, pas vers qui n''a pas d''appareil');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.courriels_sortants c
    WHERE c.modele = 'message_candidat_recu' AND c.categorie = 'recrutement'
      AND c.destinataire_profil IN ('7c600000-0000-4000-8000-0000000000a1', '7c600000-0000-4000-8000-0000000000b2')) = 2
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants c
    WHERE c.modele = 'message_candidat_recu'
      AND c.destinataire_profil NOT IN ('7c600000-0000-4000-8000-0000000000a1', '7c600000-0000-4000-8000-0000000000b2')),
  '3. un courriel par direction notifiee, categorie recrutement, a personne d''autre');

-- 4 et 5. A1 repond (sa lecture est ecrite) : sa notification est close, pas
-- celle du super-admin ; la reponse ne notifie personne.
SET LOCAL ROLE authenticated;
DO $c4$
BEGIN
  PERFORM pg_temp.en_tant_que('7c600000-0000-4000-8000-0000000000a1', 'admin');
  PERFORM public.com_marquer_lu(current_setting('test.fil')::uuid);
  PERFORM public.com_envoyer_message(current_setting('test.fil')::uuid, 'Bonjour, merci.', '7c600000-0000-4000-8000-00000000a003');
END
$c4$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.n('a1') = 0 AND pg_temp.n('b2') = 1 AND pg_temp.n('c1', false) = 0,
  '4-5. la lecture clot la notification de qui a lu, pas celle de l''autre ; la reponse ne notifie personne');

SET LOCAL ROLE authenticated;
DO $c4b$
BEGIN
  PERFORM pg_temp.en_tant_que('7c600000-0000-4000-8000-0000000000c1', 'teacher');
  PERFORM public.com_envoyer_message(current_setting('test.fil')::uuid, 'Merci.', '7c600000-0000-4000-8000-00000000a004');
END
$c4b$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.n('a1') = 1 AND pg_temp.n('a1', false) = 2 AND pg_temp.n('b2', false) = 1,
  '4. le message suivant rouvre une notification pour qui avait lu');

-- 6. Un fil qui n'est pas une candidature.
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
VALUES ('7c600000-0000-4000-8000-000000000201', 'eleve', '7c600000-0000-4000-8000-0000000000e2',
        'foyer', '7c600000-0000-4000-8000-0000000000f1', 'equipe', NULL);
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte)
VALUES ('7c600000-0000-4000-8000-000000000201', '7c600000-0000-4000-8000-0000000000e1',
        '7c600000-0000-4000-8000-00000000a005', 'Question du tuteur.');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications n
                                 WHERE n.evenement = 'message_candidat_recu'
                                   AND n.params ->> 'source_id' = '7c600000-0000-4000-8000-000000000201'),
  '6. un fil qui n''est pas une candidature ne notifie pas');

ROLLBACK;
