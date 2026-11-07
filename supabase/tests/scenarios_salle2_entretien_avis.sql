-- SALLE-2-ENTRETIEN (07/11/2026) : les avis de l'entretien. A rejouer sur une
-- base NEUVE ou PUSH-1 (20261112000000) et 20261119200000 sont installes ;
-- le scenario annule tout a la fin.
BEGIN;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SALLE2 AVIS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Fixtures (gardes d'ecriture des tables hors de l'objet du scenario).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) VALUES
  ('e2000000-0000-0000-0000-000000000001', 'av-candidat@test.invalid'),
  ('e2000000-0000-0000-0000-000000000002', 'av-direction@test.invalid'),
  ('e2000000-0000-0000-0000-000000000003', 'av-candidat2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('e2000000-0000-0000-0000-000000000001', 'AV-01', 'teacher', 'Candidat', 'Un', 'pending_kyc', 'male'),
  ('e2000000-0000-0000-0000-000000000002', 'AV-02', 'admin', 'Direction', 'Une', 'active', 'male'),
  ('e2000000-0000-0000-0000-000000000003', 'AV-03', 'teacher', 'Candidat', 'Deux', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source) VALUES
  ('e2000000-0000-0000-0000-000000000101', 'enseignant', 'e2000000-0000-0000-0000-000000000001',
   'male', 'Candidat Un', 'verifications', 'entretien_planifie', 'en_cours', 'lien_public'),
  ('e2000000-0000-0000-0000-000000000103', 'enseignant', 'e2000000-0000-0000-0000-000000000003',
   'male', 'Candidat Deux', 'verifications', 'entretien_planifie', 'en_cours', 'lien_public');
-- Entretien 1 : fixe 3 jours avant, dans 2 jours a 10:00 UTC.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type) VALUES
  ('e2000000-0000-0000-0000-000000000201', 'e2000000-0000-0000-0000-000000000002',
   '2026-11-12 10:00+00', '2026-11-12 10:45+00', 'planned', 'entretien'),
  -- Entretien 2 : fixe 2 heures avant son debut (pas de rappel de la veille).
  ('e2000000-0000-0000-0000-000000000203', 'e2000000-0000-0000-0000-000000000002',
   '2026-11-12 12:00+00', '2026-11-12 12:45+00', 'planned', 'entretien');
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par, planifie_le) VALUES
  ('e2000000-0000-0000-0000-000000000201', 'e2000000-0000-0000-0000-000000000101',
   'e2000000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000002', '2026-11-09 10:00+00'),
  ('e2000000-0000-0000-0000-000000000203', 'e2000000-0000-0000-0000-000000000103',
   'e2000000-0000-0000-0000-000000000003', 'e2000000-0000-0000-0000-000000000002', '2026-11-12 10:00+00');
INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par) VALUES
  ('e2000000-0000-0000-0000-000000000201', 'e2000000-0000-0000-0000-000000000002', false,
   'e2000000-0000-0000-0000-000000000002'),
  ('e2000000-0000-0000-0000-000000000203', 'e2000000-0000-0000-0000-000000000002', false,
   'e2000000-0000-0000-0000-000000000002');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES ('e2000000-0000-0000-0000-000000000001', 'GN', array['francais'], 40, 'pending', 'Africa/Conakry');
-- Le candidat 2 n'a pas de fiche enseignant : son fuseau est celui de sa
-- candidature.
UPDATE public.candidatures SET fuseau_iana = 'Asia/Dubai' WHERE id = 'e2000000-0000-0000-0000-000000000103';
SET LOCAL session_replication_role = origin;

CREATE TEMP TABLE r (n integer, quand text);
CREATE FUNCTION pg_temp.notifs(p_qui uuid, p_evt text) RETURNS integer LANGUAGE sql AS $$
  SELECT count(*)::integer FROM public.notifications WHERE destinataire = p_qui AND evenement = p_evt $$;
CREATE FUNCTION pg_temp.courriels(p_qui uuid, p_modele text) RETURNS integer LANGUAGE sql AS $$
  SELECT count(*)::integer FROM public.courriels_sortants
   WHERE destinataire_profil = p_qui AND modele = p_modele AND categorie = 'recrutement' $$;

-- a1 : le 10/11 a 10:00 UTC, hors de toute fenetre de rappel : les deux
-- entretiens recoivent « reserve ».
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-10 10:00+00'), 'a1';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a1') = 2, 'a1 : deux avis « reserve »');
SELECT pg_temp.vrai(
  pg_temp.notifs('e2000000-0000-0000-0000-000000000001', 'entretien_reserve') = 1
  AND (SELECT destination FROM public.notifications
        WHERE destinataire = 'e2000000-0000-0000-0000-000000000001' AND evenement = 'entretien_reserve')
      = '/attente/entretien'
  AND pg_temp.courriels('e2000000-0000-0000-0000-000000000001', 'entretien_reserve') = 1,
  'a1 : le candidat a la notification (vers /attente/entretien) et le courriel « recrutement »');
SELECT pg_temp.vrai(
  (SELECT donnees ->> 'debut_local' FROM public.courriels_sortants
    WHERE destinataire_profil = 'e2000000-0000-0000-0000-000000000001' AND modele = 'entretien_reserve')
    = '2026-11-12T10:00'
  AND (SELECT donnees ->> 'fuseau' FROM public.courriels_sortants
    WHERE destinataire_profil = 'e2000000-0000-0000-0000-000000000001' AND modele = 'entretien_reserve')
    = 'Africa/Conakry',
  'a1 : le courriel porte l''heure locale du candidat (Conakry), jamais l''heure UTC seule');
SELECT pg_temp.vrai(
  (SELECT donnees ->> 'debut_local' FROM public.courriels_sortants
    WHERE destinataire_profil = 'e2000000-0000-0000-0000-000000000003' AND modele = 'entretien_reserve')
    = '2026-11-12T16:00'
  AND (SELECT donnees ->> 'fuseau' FROM public.courriels_sortants
    WHERE destinataire_profil = 'e2000000-0000-0000-0000-000000000003' AND modele = 'entretien_reserve')
    = 'Asia/Dubai',
  'a1 : sans fiche enseignant, le candidat a l''heure de SA candidature (Dubai)');
SELECT pg_temp.vrai(
  pg_temp.notifs('e2000000-0000-0000-0000-000000000002', 'entretien_reserve') = 2
  AND (SELECT count(*) FROM public.courriels_sortants
        WHERE destinataire_profil = 'e2000000-0000-0000-0000-000000000002') = 0,
  'a1 : la personne qui mene l''entretien a la notification, sans courriel');

-- a2 : rejoue a la meme heure : rien de plus.
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-10 10:00+00'), 'a2';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a2') = 0
  AND pg_temp.courriels('e2000000-0000-0000-0000-000000000001', 'entretien_reserve') = 1,
  'a2 : idempotent, aucun doublon');

-- a3 : le 11/11 a 12:00 : l'entretien 1 (fixe 3 jours avant) a son rappel de
-- la veille ; l'entretien 2 (fixe 2 heures avant son debut) n'en a pas.
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-11 12:00+00'), 'a3';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a3') = 1
  AND pg_temp.notifs('e2000000-0000-0000-0000-000000000001', 'entretien_rappel') = 1
  AND pg_temp.notifs('e2000000-0000-0000-0000-000000000003', 'entretien_rappel') = 0,
  'a3 : la veille pour l''entretien fixe longtemps avant, pas pour l''autre');

-- a4 : le 12/11 a 09:50 : 15 minutes avant l'entretien 1. Le candidat et la
-- personne qui mene l'entretien recoivent aussi un courriel.
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-12 09:50+00'), 'a4';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a4') = 1
  AND pg_temp.courriels('e2000000-0000-0000-0000-000000000001', 'entretien_rappel') = 2
  AND pg_temp.courriels('e2000000-0000-0000-0000-000000000002', 'entretien_rappel_direction') = 1,
  'a4 : 15 minutes avant, courriel au candidat et a la personne qui mene l''entretien');

-- a5 : l'entretien 1 est consigne « tenu » : le candidat apprend que
-- l'academie lui ecrit la suite (jamais l'avis ni le compte rendu).
SET LOCAL session_replication_role = replica;
UPDATE public.entretiens SET issue = 'tenu', consigne_le = '2026-11-12 10:50+00',
       consigne_par = 'e2000000-0000-0000-0000-000000000002'
 WHERE session_id = 'e2000000-0000-0000-0000-000000000201';
SET LOCAL session_replication_role = origin;
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-12 11:00+00'), 'a5';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a5') = 1
  AND pg_temp.notifs('e2000000-0000-0000-0000-000000000001', 'entretien_tenu') = 1
  AND pg_temp.courriels('e2000000-0000-0000-0000-000000000001', 'entretien_tenu') = 1
  AND (SELECT params ? 'avis' OR params ? 'texte' FROM public.notifications
        WHERE destinataire = 'e2000000-0000-0000-0000-000000000001' AND evenement = 'entretien_tenu') = false,
  'a5 : « tenu » au candidat, sans avis ni compte rendu');

-- a6 : l'entretien 2 n'a pas eu lieu : le candidat est invite a choisir un
-- autre moment.
SET LOCAL session_replication_role = replica;
UPDATE public.entretiens SET issue = 'manque_candidat', consigne_le = '2026-11-12 13:00+00',
       consigne_par = 'e2000000-0000-0000-0000-000000000002'
 WHERE session_id = 'e2000000-0000-0000-0000-000000000203';
SET LOCAL session_replication_role = origin;
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-12 13:05+00'), 'a6';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a6') = 1
  AND pg_temp.notifs('e2000000-0000-0000-0000-000000000003', 'entretien_a_replanifier') = 1,
  'a6 : non tenu, le candidat est invite a choisir un autre moment');

-- a7 : aucun droit client sur l'envoi.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.entretien_avis_passer(timestamptz)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.entretien_avis_passer(timestamptz)', 'EXECUTE'),
  'a7 : l''envoi des avis est ferme au client');

-- a8 : contre-epreuve. Un entretien piege (fuseau inconnu : AT TIME ZONE
-- echoue) ne bloque pas un autre entretien du meme passage.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) VALUES
  ('e2000000-0000-0000-0000-000000000004', 'av-piege@test.invalid'),
  ('e2000000-0000-0000-0000-000000000005', 'av-sain@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('e2000000-0000-0000-0000-000000000004', 'AV-04', 'teacher', 'Candidat', 'Piege', 'pending_kyc', 'male'),
  ('e2000000-0000-0000-0000-000000000005', 'AV-05', 'teacher', 'Candidat', 'Sain', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, fuseau_iana) VALUES
  ('e2000000-0000-0000-0000-000000000104', 'enseignant', 'e2000000-0000-0000-0000-000000000004',
   'male', 'Candidat Piege', 'verifications', 'entretien_planifie', 'en_cours', 'lien_public', 'Pas/Une_Zone'),
  ('e2000000-0000-0000-0000-000000000105', 'enseignant', 'e2000000-0000-0000-0000-000000000005',
   'male', 'Candidat Sain', 'verifications', 'entretien_planifie', 'en_cours', 'lien_public', 'Africa/Dakar');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type) VALUES
  ('e2000000-0000-0000-0000-000000000204', 'e2000000-0000-0000-0000-000000000002',
   '2026-11-20 10:00+00', '2026-11-20 10:45+00', 'planned', 'entretien'),
  ('e2000000-0000-0000-0000-000000000205', 'e2000000-0000-0000-0000-000000000002',
   '2026-11-20 12:00+00', '2026-11-20 12:45+00', 'planned', 'entretien');
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par, planifie_le) VALUES
  ('e2000000-0000-0000-0000-000000000204', 'e2000000-0000-0000-0000-000000000104',
   'e2000000-0000-0000-0000-000000000004', 'e2000000-0000-0000-0000-000000000002', '2026-11-12 14:00+00'),
  ('e2000000-0000-0000-0000-000000000205', 'e2000000-0000-0000-0000-000000000105',
   'e2000000-0000-0000-0000-000000000005', 'e2000000-0000-0000-0000-000000000002', '2026-11-12 14:00+00');
SET LOCAL session_replication_role = origin;
INSERT INTO r SELECT private.entretien_avis_passer('2026-11-13 10:00+00'), 'a8';
SELECT pg_temp.vrai((SELECT n FROM r WHERE quand = 'a8') = 1
  AND pg_temp.notifs('e2000000-0000-0000-0000-000000000005', 'entretien_reserve') = 1
  AND pg_temp.notifs('e2000000-0000-0000-0000-000000000004', 'entretien_reserve') = 0
  AND NOT EXISTS (SELECT 1 FROM private.entretien_avis_envoyes
                   WHERE session_id = 'e2000000-0000-0000-0000-000000000204'),
  'a8 : l''entretien piege est ecarte (rien d''ecrit, repris au passage suivant), l''autre recoit son avis');

ROLLBACK;
