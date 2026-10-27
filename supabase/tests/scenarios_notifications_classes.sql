-- Notifications des classes et des seances (fiche « Fraicheur et
-- notifications » du 27/10/2026, lignes 10 a 15 ; migration 20261027120000).
--
-- Pour chaque evenement de la ligne 11, un changement en base produit
-- exactement les notifications attendues (destinataires, evenement,
-- destination), jamais deux pour le meme fait ; une ligne de la file des
-- courriels (23/10) par notification dont le destinataire a une adresse, et
-- une seule ; les anciennes lignes restent valides ; la table est protegee par
-- la RLS et, quand la publication supabase_realtime existe, y figure.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin. Les declencheurs de la migration sont differes a la
-- validation : SET CONSTRAINTS ALL IMMEDIATE les fait tirer sans valider.
-- Toute la lecture se fait dans une seule transaction : la regle « jamais
-- deux fois le meme fait dans une transaction » vaut donc ici par classe, et
-- chaque etape prend sa propre classe.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Refus attendu par SQLSTATE.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (% au lieu de %)', p_label, SQLSTATE, p_code;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Les notifications d'un evenement pour une classe, en « destinataire=destination ».
CREATE FUNCTION pg_temp.lignes(p_evenement text, p_groupe uuid)
RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(pg_catalog.array_agg(
           pg_catalog.substr(n.destinataire::text, 33, 4) || '=' || n.destination
           ORDER BY n.destinataire), ARRAY[]::text[])
    FROM public.notifications n
   WHERE n.evenement = p_evenement
     AND n.params ->> 'groupe_id' = p_groupe::text
$$;

-- Un instant a 03:00 UTC, N jours apres aujourd'hui : hors de toute seance
-- materialisee des classes (17 h a 20 h a Paris), donc sans chevauchement.
CREATE FUNCTION pg_temp.a_l_aube(p_jours integer)
RETURNS timestamptz
LANGUAGE sql STABLE AS $$
  SELECT pg_catalog.date_trunc('day', pg_catalog.now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
         + pg_catalog.make_interval(days => p_jours, hours => 3)
$$;

CREATE FUNCTION pg_temp.nombre(p_groupe uuid, p_evenement text DEFAULT NULL)
RETURNS integer
LANGUAGE sql AS $$
  SELECT pg_catalog.count(*)::integer
    FROM public.notifications n
   WHERE n.params ->> 'groupe_id' = p_groupe::text
     AND (p_evenement IS NULL OR n.evenement = p_evenement)
$$;

-- ------------------------------------------------------------------
-- Fixtures
--   T1, T2 enseignants (pieces validees, lundi 18 h et mardi 18 h Paris) ;
--   P1 tuteur principal du foyer H1 (America/Toronto) : S1 (compte enfant,
--   child_of : aucun courriel), S3, S5, S7 ;
--   P2 tuteur principal du foyer H2 (Europe/Paris) : S2, S4, S6, S8.
--   Un eleve n'a qu'une classe active a la fois : chaque etape a les siens.
--   Classes nees hier (created_at - 1 jour) : G2 membres, G3 creneaux,
--   G4 seances, G5 fermeture, G6 enseignant, G7 absence. G1 nait pendant le
--   scenario.
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES
  ('f27b0000-0000-0000-0000-000000000001', 'f27b-t1@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000002', 'f27b-t2@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000011', 'f27b-p1@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000012', 'f27b-s1@example.test',
   '{"child_of": "f27b0000-0000-0000-0000-000000000011"}'),
  ('f27b0000-0000-0000-0000-000000000013', 'f27b-s3@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000014', 'f27b-s5@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000015', 'f27b-s7@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000021', 'f27b-p2@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000022', 'f27b-s2@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000023', 'f27b-s4@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000024', 'f27b-s6@example.test', '{}'),
  ('f27b0000-0000-0000-0000-000000000025', 'f27b-s8@example.test', '{}');

INSERT INTO public.households (id, timezone) VALUES
  ('f27b0000-0000-0000-0000-000000000101', 'America/Toronto'),
  ('f27b0000-0000-0000-0000-000000000102', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
VALUES
  ('f27b0000-0000-0000-0000-000000000001', 'F27B-T1', 'teacher', NULL,
   'Enseignant', 'Un', 'male', 'provisional_active'),
  ('f27b0000-0000-0000-0000-000000000002', 'F27B-T2', 'teacher', NULL,
   'Enseignant', 'Deux', 'male', 'provisional_active'),
  ('f27b0000-0000-0000-0000-000000000011', 'F27B-P1', 'guardian',
   'f27b0000-0000-0000-0000-000000000101', 'Tuteur', 'Un', 'female', 'active'),
  ('f27b0000-0000-0000-0000-000000000012', 'F27B-S1', 'student',
   'f27b0000-0000-0000-0000-000000000101', 'Eleve', 'Un', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000021', 'F27B-P2', 'guardian',
   'f27b0000-0000-0000-0000-000000000102', 'Tuteur', 'Deux', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000022', 'F27B-S2', 'student',
   'f27b0000-0000-0000-0000-000000000102', 'Eleve', 'Deux', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000013', 'F27B-S3', 'student',
   'f27b0000-0000-0000-0000-000000000101', 'Eleve', 'Trois', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000023', 'F27B-S4', 'student',
   'f27b0000-0000-0000-0000-000000000102', 'Eleve', 'Quatre', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000014', 'F27B-S5', 'student',
   'f27b0000-0000-0000-0000-000000000101', 'Eleve', 'Cinq', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000024', 'F27B-S6', 'student',
   'f27b0000-0000-0000-0000-000000000102', 'Eleve', 'Six', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000015', 'F27B-S7', 'student',
   'f27b0000-0000-0000-0000-000000000101', 'Eleve', 'Sept', 'male', 'active'),
  ('f27b0000-0000-0000-0000-000000000025', 'F27B-S8', 'student',
   'f27b0000-0000-0000-0000-000000000102', 'Eleve', 'Huit', 'male', 'active');

UPDATE public.households SET primary_guardian_id = 'f27b0000-0000-0000-0000-000000000011'
 WHERE id = 'f27b0000-0000-0000-0000-000000000101';
UPDATE public.households SET primary_guardian_id = 'f27b0000-0000-0000-0000-000000000021'
 WHERE id = 'f27b0000-0000-0000-0000-000000000102';

INSERT INTO public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
  ('f27b0000-0000-0000-0000-000000000001', ARRAY['francais'], 20, 'approved', 'Europe/Paris'),
  ('f27b0000-0000-0000-0000-000000000002', ARRAY['francais'], 20, 'approved', 'Europe/Paris');

INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT t, d, h, 'Europe/Paris'
  FROM pg_catalog.unnest(ARRAY['f27b0000-0000-0000-0000-000000000001',
                               'f27b0000-0000-0000-0000-000000000002']::uuid[]) t,
       pg_catalog.unnest(ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]) d,
       pg_catalog.unnest(ARRAY[17, 18, 19, 20]::smallint[]) h;

INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy,
   langue_cours, cohorte, niveau_declare, objectif)
SELECT p.id, 'minor', 'child', 'forbidden', 'francais', 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire'
  FROM public.profiles p WHERE p.immutable_id LIKE 'F27B-S%';

-- Les classes d'hier. Les declencheurs de materialisation creent leurs
-- seances ; elles ne genent pas (les seances du scenario sont inserees a part).
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, niveau, etat, created_at)
VALUES
  ('f27b0000-0000-0000-0000-000000000202', 'f27b0000-0000-0000-0000-000000000001',
   'enfant', 5, 'F27B G2 membres', 1, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'active', pg_catalog.now() - interval '1 day'),
  ('f27b0000-0000-0000-0000-000000000203', 'f27b0000-0000-0000-0000-000000000001',
   'enfant', 5, 'F27B G3 creneaux', 2, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'active', pg_catalog.now() - interval '1 day'),
  ('f27b0000-0000-0000-0000-000000000204', 'f27b0000-0000-0000-0000-000000000001',
   'enfant', 5, 'F27B G4 seances', 3, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'active', pg_catalog.now() - interval '1 day'),
  ('f27b0000-0000-0000-0000-000000000205', 'f27b0000-0000-0000-0000-000000000001',
   'enfant', 5, 'F27B G5 fermeture', 4, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'active', pg_catalog.now() - interval '1 day'),
  ('f27b0000-0000-0000-0000-000000000206', NULL,
   'enfant', 5, 'F27B G6 enseignant', 5, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'en_attente_enseignant', pg_catalog.now() - interval '1 day'),
  ('f27b0000-0000-0000-0000-000000000207', 'f27b0000-0000-0000-0000-000000000001',
   'enfant', 5, 'F27B G7 absence', 6, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'active', pg_catalog.now() - interval '1 day');

-- Les membres d'hier : S3 (foyer H1) et S6 (foyer H2) dans G4.
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at) VALUES
  ('f27b0000-0000-0000-0000-000000000204', 'f27b0000-0000-0000-0000-000000000013',
   pg_catalog.now() - interval '1 day'),
  ('f27b0000-0000-0000-0000-000000000204', 'f27b0000-0000-0000-0000-000000000024',
   pg_catalog.now() - interval '1 day');

-- Rien n'est dit pour les fixtures : ces lignes d'hier ne sont pas des faits.
SET CONSTRAINTS ALL IMMEDIATE;
DELETE FROM public.courriels_sortants WHERE cle_idempotence LIKE 'notification:%'
   AND destinataire_profil IN (SELECT id FROM public.profiles WHERE immutable_id LIKE 'F27B-%');
DELETE FROM public.notifications
 WHERE destinataire IN (SELECT id FROM public.profiles WHERE immutable_id LIKE 'F27B-%');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 0. Les anciennes lignes restent valides ; un evenement inconnu est refuse.
-- ------------------------------------------------------------------
INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
VALUES ('f27b0000-0000-0000-0000-000000000011', 'f27b0000-0000-0000-0000-000000000101',
        'demande_recue', '{"demande_id": "x", "etat": "envoyee"}', '/tuteur/demandes'),
       ('f27b0000-0000-0000-0000-000000000001', NULL,
        'remplacement_propose', '{"session_id": "x"}', '/enseignant/journee/remplacements'),
       ('f27b0000-0000-0000-0000-000000000011', 'f27b0000-0000-0000-0000-000000000101',
        'paiement_relance', '{}', '/tuteur/foyer/recharge');
SELECT pg_temp.vrai(true, '0.1 anciens evenements et anciennes destinations acceptes');
SELECT pg_temp.refus(
  $$INSERT INTO public.notifications (destinataire, evenement, params, destination)
    VALUES ('f27b0000-0000-0000-0000-000000000011', 'evenement_futur', '{}', '/tuteur')$$,
  '23514', '0.2 un evenement hors liste est refuse');
SELECT pg_temp.refus(
  $$INSERT INTO public.notifications (destinataire, evenement, params, destination)
    VALUES ('f27b0000-0000-0000-0000-000000000011', 'classe_creee', '{}', '/tuteur/classes/pas-un-uuid')$$,
  '23514', '0.3 une destination hors liste est refusee');

-- ------------------------------------------------------------------
-- 1. Classe creee avec ses eleves et ses creneaux : une notification par
--    personne, « classe creee » seulement (ligne 4, 10, 11).
-- ------------------------------------------------------------------
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, niveau, etat)
VALUES
  ('f27b0000-0000-0000-0000-000000000201', 'f27b0000-0000-0000-0000-000000000001',
   'enfant', 5, 'F27B G1 creation', 7, 18, 'Europe/Paris', 'francais', 'hommes',
   'debut_lettres', 'active');
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('f27b0000-0000-0000-0000-000000000201', 'f27b0000-0000-0000-0000-000000000012');
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
VALUES ('f27b0000-0000-0000-0000-000000000201', 7, 19)
ON CONFLICT DO NOTHING;
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('classe_creee', 'f27b0000-0000-0000-0000-000000000201')
    = ARRAY['0001=/enseignant/classes',
            '0011=/tuteur/classes/f27b0000-0000-0000-0000-000000000201',
            '0012=/eleve'],
  '1.1 classe creee : l''eleve, son tuteur, l''enseignant, chacun vers son ecran');
SELECT pg_temp.vrai(
  pg_temp.nombre('f27b0000-0000-0000-0000-000000000201') = 3,
  '1.2 classe creee : rien d''autre (ni inscrit, ni creneau) pour la meme classe');
SELECT pg_temp.vrai(
  (SELECT n.params ->> 'portee' FROM public.notifications n
    WHERE n.evenement = 'classe_creee' AND n.destinataire = 'f27b0000-0000-0000-0000-000000000011') = 'foyer'
  AND (SELECT n.params ->> 'portee' FROM public.notifications n
    WHERE n.evenement = 'classe_creee' AND n.destinataire = 'f27b0000-0000-0000-0000-000000000012') = 'soi'
  AND (SELECT n.foyer_id FROM public.notifications n
    WHERE n.evenement = 'classe_creee' AND n.destinataire = 'f27b0000-0000-0000-0000-000000000011')
      = 'f27b0000-0000-0000-0000-000000000101',
  '1.3 classe creee : portee et foyer poses');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 2. Eleve inscrit, puis retire (ligne 5).
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('f27b0000-0000-0000-0000-000000000202', 'f27b0000-0000-0000-0000-000000000022');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('eleve_inscrit', 'f27b0000-0000-0000-0000-000000000202')
    = ARRAY['0001=/enseignant/classes',
            '0021=/tuteur/classes/f27b0000-0000-0000-0000-000000000202',
            '0022=/eleve'],
  '2.1 eleve inscrit : l''eleve, son tuteur, l''enseignant ; pas l''autre foyer');
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.groupe_membres
   SET left_at = pg_catalog.now(), left_by = 'f27b0000-0000-0000-0000-000000000001',
       left_reason = 'scenario'
 WHERE groupe_id = 'f27b0000-0000-0000-0000-000000000202'
   AND student_id = 'f27b0000-0000-0000-0000-000000000022';
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('eleve_retire', 'f27b0000-0000-0000-0000-000000000202')
    = ARRAY['0001=/enseignant/classes', '0021=/tuteur', '0022=/eleve'],
  '2.2 eleve retire : les memes, le tuteur et l''eleve vers leur accueil');
SELECT pg_temp.vrai(
  pg_temp.nombre('f27b0000-0000-0000-0000-000000000202') = 6,
  '2.3 inscrit puis retire : six lignes, aucun doublon');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 3. Creneau change : deux creneaux poses d'un coup, une seule notification
--    par personne (ligne 6).
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('f27b0000-0000-0000-0000-000000000203', 'f27b0000-0000-0000-0000-000000000023');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
VALUES ('f27b0000-0000-0000-0000-000000000203', 2, 19),
       ('f27b0000-0000-0000-0000-000000000203', 2, 20)
ON CONFLICT DO NOTHING;
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('creneau_change', 'f27b0000-0000-0000-0000-000000000203')
    = ARRAY['0001=/enseignant/classes',
            '0021=/tuteur/classes/f27b0000-0000-0000-0000-000000000203',
            '0023=/eleve'],
  '3.1 creneau change : une notification par personne pour deux creneaux');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 4. Enseignant affecte (sans doublon avec c11bis), puis change (ligne 8).
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('f27b0000-0000-0000-0000-000000000206', 'f27b0000-0000-0000-0000-000000000015');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
-- Ce que affecter_enseignant_classe_c11bis ecrit deja pour le tuteur
-- principal, dans la meme transaction que l'affectation.
INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
VALUES ('f27b0000-0000-0000-0000-000000000011', 'f27b0000-0000-0000-0000-000000000101',
        'enseignant_affecte',
        pg_catalog.jsonb_build_object('groupe_id', 'f27b0000-0000-0000-0000-000000000206',
                                      'debut_local', '2026-11-06T12:00:00'),
        '/tuteur/demandes');
UPDATE public.groupes
   SET teacher_id = 'f27b0000-0000-0000-0000-000000000001', etat = 'active'
 WHERE id = 'f27b0000-0000-0000-0000-000000000206';
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('enseignant_affecte', 'f27b0000-0000-0000-0000-000000000206')
    = ARRAY['0001=/enseignant/classes', '0011=/tuteur/demandes', '0015=/eleve'],
  '4.1 enseignant affecte : le tuteur garde la ligne de c11bis, l''eleve et l''enseignant s''ajoutent');
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.groupes
   SET teacher_id = 'f27b0000-0000-0000-0000-000000000002'
 WHERE id = 'f27b0000-0000-0000-0000-000000000206';
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('enseignant_change', 'f27b0000-0000-0000-0000-000000000206')
    = ARRAY['0001=/enseignant/classes', '0002=/enseignant/classes',
            '0011=/tuteur/classes/f27b0000-0000-0000-0000-000000000206', '0015=/eleve'],
  '4.2 enseignant change : l''ancien et le nouvel enseignant, le tuteur, l''eleve');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 5. Seance annulee, seance deplacee, seance passee, creation de routine
--    (ligne 9).
-- ------------------------------------------------------------------
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES
  ('f27b0000-0000-0000-0000-000000000401', 'f27b0000-0000-0000-0000-000000000001',
   'f27b0000-0000-0000-0000-000000000204',
   pg_temp.a_l_aube(10), pg_temp.a_l_aube(10) + interval '1 hour', 'planned'),
  ('f27b0000-0000-0000-0000-000000000402', 'f27b0000-0000-0000-0000-000000000001',
   'f27b0000-0000-0000-0000-000000000204',
   pg_temp.a_l_aube(17), pg_temp.a_l_aube(17) + interval '1 hour', 'planned'),
  ('f27b0000-0000-0000-0000-000000000403', 'f27b0000-0000-0000-0000-000000000001',
   'f27b0000-0000-0000-0000-000000000204',
   pg_temp.a_l_aube(-7), pg_temp.a_l_aube(-7) + interval '1 hour', 'planned');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.nombre('f27b0000-0000-0000-0000-000000000204') = 0,
  '5.1 une seance creee (routine de la cloche) ne previent personne');
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.sessions SET status = 'canceled'
 WHERE id = 'f27b0000-0000-0000-0000-000000000401';
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('seance_annulee', 'f27b0000-0000-0000-0000-000000000204')
    = ARRAY['0001=/enseignant/journee',
            '0011=/tuteur/classes/f27b0000-0000-0000-0000-000000000204/planning',
            '0013=/eleve',
            '0021=/tuteur/classes/f27b0000-0000-0000-0000-000000000204/planning',
            '0024=/eleve'],
  '5.2 seance annulee : les deux foyers et l''enseignant, vers le planning et la journee');
SELECT pg_temp.vrai(
  (SELECT n.params ->> 'debut_local' FROM public.notifications n
    WHERE n.evenement = 'seance_annulee' AND n.destinataire = 'f27b0000-0000-0000-0000-000000000011')
  = pg_catalog.to_char(pg_temp.a_l_aube(10) AT TIME ZONE 'America/Toronto',
                       'YYYY-MM-DD"T"HH24:MI:SS')
  AND (SELECT n.params ->> 'session_id' FROM public.notifications n
    WHERE n.evenement = 'seance_annulee' AND n.destinataire = 'f27b0000-0000-0000-0000-000000000011')
  = 'f27b0000-0000-0000-0000-000000000401',
  '5.3 seance annulee : heure locale du foyer et seance dans les parametres');
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.sessions
   SET started_at = started_at + interval '1 day', ended_at = ended_at + interval '1 day'
 WHERE id = 'f27b0000-0000-0000-0000-000000000402';
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_catalog.cardinality(pg_temp.lignes('seance_deplacee', 'f27b0000-0000-0000-0000-000000000204')) = 5
  AND (SELECT n.params ->> 'debut_local' FROM public.notifications n
        WHERE n.evenement = 'seance_deplacee' AND n.destinataire = 'f27b0000-0000-0000-0000-000000000021')
      = pg_catalog.to_char(pg_temp.a_l_aube(18) AT TIME ZONE 'Europe/Paris',
                           'YYYY-MM-DD"T"HH24:MI:SS'),
  '5.4 seance deplacee : cinq personnes, la nouvelle heure dans le fuseau du foyer');
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.sessions SET status = 'canceled'
 WHERE id = 'f27b0000-0000-0000-0000-000000000403';
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.nombre('f27b0000-0000-0000-0000-000000000204') = 10,
  '5.5 une seance passee annulee ne previent personne ; aucun doublon');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 6. Enseignante absente, puis remplacee (ligne 11) : les familles ; les
--    enseignants restent prevenus par b09.
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('f27b0000-0000-0000-0000-000000000207', 'f27b0000-0000-0000-0000-000000000025');
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES
  ('f27b0000-0000-0000-0000-000000000407', 'f27b0000-0000-0000-0000-000000000001',
   'f27b0000-0000-0000-0000-000000000207',
   pg_temp.a_l_aube(20), pg_temp.a_l_aube(20) + interval '1 hour', 'planned');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence)
VALUES ('f27b0000-0000-0000-0000-000000000407', 'absence_declaree',
        'f27b0000-0000-0000-0000-000000000001', 'f27b0000-0000-0000-0000-000000000001',
        'f27b0000-0000-0000-0000-000000000501');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('enseignante_absente', 'f27b0000-0000-0000-0000-000000000207')
    = ARRAY['0021=/tuteur/classes/f27b0000-0000-0000-0000-000000000207/planning', '0025=/eleve'],
  '6.1 enseignante absente : le foyer de la classe, pas l''enseignante elle-meme');
SET CONSTRAINTS ALL DEFERRED;
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence)
VALUES ('f27b0000-0000-0000-0000-000000000407', 'remplacement_pris',
        'f27b0000-0000-0000-0000-000000000001', 'f27b0000-0000-0000-0000-000000000002',
        'f27b0000-0000-0000-0000-000000000002', 'f27b0000-0000-0000-0000-000000000502');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('remplacement_pris', 'f27b0000-0000-0000-0000-000000000207')
    = ARRAY['0021=/tuteur/classes/f27b0000-0000-0000-0000-000000000207/planning', '0025=/eleve'],
  '6.2 remplacement pris : le foyer de la classe est prevenu, vers le planning');
-- Absence posee puis remplacement pris dans la meme transaction : pour la
-- meme seance, une seule ligne par personne et par evenement, en comptant
-- celles de b09 (remplacement_propose et remplacement_pris vers les autres
-- enseignants ; ici les enseignants sont en provisional_active, que b09
-- n'adresse pas : ses lignes, quand il y en a, entrent dans le meme compte),
-- et l'enseignante absente ne recoit rien.
SELECT pg_temp.vrai(
  NOT EXISTS (
    SELECT 1 FROM public.notifications n
     WHERE n.params ->> 'session_id' = 'f27b0000-0000-0000-0000-000000000407'
     GROUP BY n.destinataire, n.evenement
    HAVING pg_catalog.count(*) > 1)
  AND NOT EXISTS (
    SELECT 1 FROM public.notifications n
     WHERE n.params ->> 'session_id' = 'f27b0000-0000-0000-0000-000000000407'
       AND n.destinataire = 'f27b0000-0000-0000-0000-000000000001')
  AND (SELECT pg_catalog.count(*) FROM public.notifications n
        WHERE n.params ->> 'session_id' = 'f27b0000-0000-0000-0000-000000000407') = 4,
  '6.3 absence puis remplacement : quatre lignes, une par personne et par evenement, rien a l''absente');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 7. Classe fermee comme cloturer_groupe le fait : membres sortis, classe
--    close, seances annulees ; une seule notification par personne (ligne 7).
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('f27b0000-0000-0000-0000-000000000205', 'f27b0000-0000-0000-0000-000000000014');
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES
  ('f27b0000-0000-0000-0000-000000000405', 'f27b0000-0000-0000-0000-000000000001',
   'f27b0000-0000-0000-0000-000000000205',
   pg_temp.a_l_aube(30), pg_temp.a_l_aube(30) + interval '1 hour', 'planned');
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
UPDATE public.groupe_membres
   SET left_at = pg_catalog.now(), left_by = 'f27b0000-0000-0000-0000-000000000001',
       left_reason = 'groupe cloture : scenario'
 WHERE groupe_id = 'f27b0000-0000-0000-0000-000000000205' AND left_at IS NULL;
UPDATE public.groupes
   SET ended_at = pg_catalog.now(), ended_by = 'f27b0000-0000-0000-0000-000000000001',
       end_reason = 'scenario'
 WHERE id = 'f27b0000-0000-0000-0000-000000000205';
UPDATE public.sessions SET status = 'canceled'
 WHERE groupe_id = 'f27b0000-0000-0000-0000-000000000205' AND status = 'planned'
   AND started_at > pg_catalog.now();
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  pg_temp.lignes('classe_supprimee', 'f27b0000-0000-0000-0000-000000000205')
    = ARRAY['0001=/enseignant/classes', '0011=/tuteur', '0014=/eleve'],
  '7.1 classe fermee : l''eleve sorti, son tuteur, l''enseignant, vers leur accueil');
SELECT pg_temp.vrai(
  pg_temp.nombre('f27b0000-0000-0000-0000-000000000205', 'eleve_retire') = 0
  AND pg_temp.nombre('f27b0000-0000-0000-0000-000000000205', 'seance_annulee') = 0
  AND pg_temp.nombre('f27b0000-0000-0000-0000-000000000205', 'eleve_inscrit') = 3
  AND pg_temp.nombre('f27b0000-0000-0000-0000-000000000205') = 6,
  '7.2 classe fermee : ni retrait ni annulation en plus (l''inscription d''avant reste)');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 8. Un courriel par notification, une fois, jamais a un compte enfant
--    (ligne 15, mecanisme du 23/10).
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT EXISTS (
    SELECT 1 FROM public.notifications n
     WHERE n.destinataire IN (SELECT id FROM public.profiles WHERE immutable_id LIKE 'F27B-%')
       AND n.destinataire <> 'f27b0000-0000-0000-0000-000000000012'
       AND (SELECT pg_catalog.count(*) FROM public.courriels_sortants c
             WHERE c.cle_idempotence = 'notification:' || n.id::text) <> 1)
  AND NOT EXISTS (
    SELECT 1 FROM public.courriels_sortants c
      JOIN public.notifications n ON c.cle_idempotence = 'notification:' || n.id::text
     WHERE n.destinataire = 'f27b0000-0000-0000-0000-000000000012'),
  '8.1 un courriel par notification, aucun pour le compte enfant');
SELECT pg_temp.vrai(
  NOT EXISTS (
    SELECT 1 FROM public.courriels_sortants c
      JOIN public.notifications n ON c.cle_idempotence = 'notification:' || n.id::text
     WHERE n.evenement IN ('classe_creee', 'seance_annulee', 'enseignante_absente')
       AND c.categorie <> 'classes'),
  '8.2 les evenements des classes partent de la categorie « classes »');

-- ------------------------------------------------------------------
-- 9. RLS, identite de replication, publication (ligne 12 et 14).
-- ------------------------------------------------------------------
DO $realtime$
DECLARE
  v_relreplident "char";
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relname = 'notifications' AND c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'ROUGE : notifications sans RLS';
  END IF;
  SELECT c.relreplident INTO v_relreplident
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relname = 'notifications';
  IF v_relreplident IS DISTINCT FROM 'd' THEN
    RAISE EXCEPTION 'ROUGE : notifications a une identite de replication % (attendu : d)', v_relreplident;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_publication p WHERE p.pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_publication_tables p
        WHERE p.pubname = 'supabase_realtime' AND p.schemaname = 'public'
          AND p.tablename = 'notifications') THEN
    RAISE EXCEPTION 'ROUGE : notifications absente de supabase_realtime';
  END IF;
  RAISE NOTICE 'OK 9.1 notifications : RLS, cle primaire seule, publication si elle existe';
END;
$realtime$;

ROLLBACK;
