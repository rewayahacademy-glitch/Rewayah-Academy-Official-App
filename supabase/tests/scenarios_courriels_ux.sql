-- COURRIELS-UX (rang 18, 03/11/2026 ; migration 20261108100000) : UX-026 et
-- FN-108, vus dans la ligne de la file des courriels (courriels_sortants).
--
--   1. classe creee : la famille recoit un courriel qui porte le nom de la
--      classe, les prenoms de SES enfants, la premiere seance et le fuseau
--      dans lequel elle est ecrite ; l'enseignant, rien par courriel ;
--   2. eleve inscrit (FN-108) : le courriel part a la famille de l'eleve, avec
--      son prenom, jamais a l'enseignant ; l'autre foyer ne recoit rien ;
--   3. seance annulee : l'heure, son fuseau, la classe et les enfants ;
--   4. enseignant affecte : aucun courriel, a personne (decision du 01/11).
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin. Les declencheurs des notifications sont differes :
-- SET CONSTRAINTS ALL IMMEDIATE les fait tirer sans valider.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c0e10000-0000-4000-8000-' || pg_catalog.lpad(p, 12, '0'))::uuid $$;

-- Un instant a 03:00 UTC, N jours apres aujourd'hui (hors des seances
-- materialisees des classes, qui sont en soiree a Paris).
CREATE FUNCTION pg_temp.a_l_aube(p_jours integer) RETURNS timestamptz
LANGUAGE sql STABLE AS $$
  SELECT pg_catalog.date_trunc('day', pg_catalog.now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
         + pg_catalog.make_interval(days => p_jours, hours => 3)
$$;

-- Les courriels d'un evenement pour une classe.
CREATE FUNCTION pg_temp.courriels(p_modele text, p_groupe uuid)
RETURNS SETOF public.courriels_sortants
LANGUAGE sql AS $$
  SELECT c.* FROM public.courriels_sortants c
   WHERE c.modele = p_modele AND c.donnees ->> 'groupe_id' = p_groupe::text
$$;

-- ------------------------------------------------------------------
-- Fixtures
--   T enseignant (Europe/Paris) ; T2 enseignant sans classe ;
--   foyer H1 (America/Toronto) : tuteur P1, enfants Lina et Yanis ;
--   foyer H2 (Europe/Paris) : tuteur P2, enfant Sami.
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES
  (pg_temp.u('1'), 'cux-t@example.test', '{}'),
  (pg_temp.u('2'), 'cux-t2@example.test', '{}'),
  (pg_temp.u('11'), 'cux-p1@example.test', '{}'),
  (pg_temp.u('12'), 'cux-lina@example.test', '{}'),
  (pg_temp.u('13'), 'cux-yanis@example.test', '{}'),
  (pg_temp.u('21'), 'cux-p2@example.test', '{}'),
  (pg_temp.u('22'), 'cux-sami@example.test', '{}'),
  (pg_temp.u('23'), 'cux-nour@example.test', '{}');

INSERT INTO public.households (id, timezone) VALUES
  (pg_temp.u('101'), 'America/Toronto'),
  (pg_temp.u('102'), 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, gender, account_status)
VALUES
  (pg_temp.u('1'), 'CUX-T', 'teacher', NULL, 'Omar', 'Enseignant', 'male', 'provisional_active'),
  (pg_temp.u('2'), 'CUX-T2', 'teacher', NULL, 'Ali', 'Enseignant', 'male', 'provisional_active'),
  (pg_temp.u('11'), 'CUX-P1', 'guardian', pg_temp.u('101'), 'Samira', 'Foyer', 'female', 'active'),
  (pg_temp.u('12'), 'CUX-S1', 'student', pg_temp.u('101'), 'Lina', 'Foyer', 'male', 'active'),
  (pg_temp.u('13'), 'CUX-S2', 'student', pg_temp.u('101'), 'Yanis', 'Foyer', 'male', 'active'),
  (pg_temp.u('21'), 'CUX-P2', 'guardian', pg_temp.u('102'), 'Karim', 'Autre', 'male', 'active'),
  (pg_temp.u('22'), 'CUX-S3', 'student', pg_temp.u('102'), 'Sami', 'Autre', 'male', 'active'),
  (pg_temp.u('23'), 'CUX-S4', 'student', pg_temp.u('102'), 'Nour', 'Autre', 'male', 'active');

UPDATE public.households SET primary_guardian_id = pg_temp.u('11') WHERE id = pg_temp.u('101');
UPDATE public.households SET primary_guardian_id = pg_temp.u('21') WHERE id = pg_temp.u('102');

INSERT INTO public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES (pg_temp.u('1'), ARRAY['francais'], 20, 'approved', 'Europe/Paris'),
       (pg_temp.u('2'), ARRAY['francais'], 20, 'approved', 'Europe/Paris');

INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT t, d, h, 'Europe/Paris'
  FROM pg_catalog.unnest(ARRAY[pg_temp.u('1'), pg_temp.u('2')]) t,
       pg_catalog.unnest(ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]) d,
       pg_catalog.unnest(ARRAY[17, 18, 19, 20]::smallint[]) h;

INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy, langue_cours, cohorte, niveau_declare, objectif)
SELECT p.id, 'minor', 'child', 'forbidden', 'francais', 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire'
  FROM public.profiles p WHERE p.immutable_id LIKE 'CUX-S%';

-- Deux classes d'hier (G2, membres ; G3, sans enseignant), leurs seances a venir.
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, niveau, etat, created_at)
VALUES
  (pg_temp.u('202'), pg_temp.u('1'), 'enfant', 5, 'CUX Classe du mardi', 2, 18, 'Europe/Paris',
   'francais', 'hommes', 'debut_lettres', 'active', pg_catalog.now() - interval '1 day'),
  (pg_temp.u('203'), NULL, 'enfant', 5, 'CUX Classe en attente', 3, 18, 'Europe/Paris',
   'francais', 'hommes', 'debut_lettres', 'en_attente_enseignant', pg_catalog.now() - interval '1 day');
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at)
VALUES (pg_temp.u('203'), pg_temp.u('23'), pg_catalog.now() - interval '1 day');
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES (pg_temp.u('402'), pg_temp.u('1'), pg_temp.u('202'),
        pg_temp.a_l_aube(4), pg_temp.a_l_aube(4) + interval '1 hour', 'planned');
-- Les fixtures ne sont pas des faits : on repart sans notification ni courriel.
SET CONSTRAINTS ALL IMMEDIATE;
DELETE FROM public.courriels_sortants
 WHERE destinataire_profil IN (SELECT id FROM public.profiles WHERE immutable_id LIKE 'CUX-%');
DELETE FROM public.notifications
 WHERE destinataire IN (SELECT id FROM public.profiles WHERE immutable_id LIKE 'CUX-%');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 1. Classe creee avec Lina et Yanis, et sa premiere seance.
-- ------------------------------------------------------------------
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, niveau, etat)
VALUES (pg_temp.u('201'), pg_temp.u('1'), 'enfant', 5, 'CUX Les bases, lundi', 1, 18, 'Europe/Paris',
        'francais', 'hommes', 'debut_lettres', 'active');
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES (pg_temp.u('201'), pg_temp.u('12')), (pg_temp.u('201'), pg_temp.u('13'));
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES (pg_temp.u('401'), pg_temp.u('1'), pg_temp.u('201'),
        pg_temp.a_l_aube(3), pg_temp.a_l_aube(3) + interval '1 hour', 'planned');
SET CONSTRAINTS ALL IMMEDIATE;

-- La premiere seance attendue : la plus proche des seances prevues de la
-- classe (la materialisation peut en poser d'autres), dans le fuseau de H1.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM pg_temp.courriels('classe_creee', pg_temp.u('201'))
    WHERE destinataire_profil = pg_temp.u('11')) = 1
  AND (SELECT c.donnees ->> 'classe' FROM pg_temp.courriels('classe_creee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) = 'CUX Les bases, lundi'
  AND (SELECT c.donnees -> 'eleves' FROM pg_temp.courriels('classe_creee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) = '["Lina", "Yanis"]'::jsonb
  AND (SELECT c.donnees ->> 'fuseau' FROM pg_temp.courriels('classe_creee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) = 'America/Toronto'
  AND (SELECT c.donnees ->> 'prochaine_local' FROM pg_temp.courriels('classe_creee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11'))
      = (SELECT pg_catalog.to_char(pg_catalog.min(s.started_at) AT TIME ZONE 'America/Toronto', 'YYYY-MM-DD"T"HH24:MI:SS')
           FROM public.sessions s
          WHERE s.groupe_id = pg_temp.u('201') AND s.status = 'planned'
            AND s.deleted_at IS NULL AND s.started_at > pg_catalog.now()),
  '1.1 classe creee : un courriel a la famille, avec la classe, Lina et Yanis, la premiere seance et le fuseau du foyer');
SELECT pg_temp.vrai(
  (SELECT c.donnees -> 'eleves' FROM pg_temp.courriels('classe_creee', pg_temp.u('201')) c
    WHERE c.destinataire_profil = pg_temp.u('12')) IS NULL
  AND (SELECT c.donnees ->> 'classe' FROM pg_temp.courriels('classe_creee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('12')) = 'CUX Les bases, lundi',
  '1.2 classe creee : l''eleve recoit sa classe, sans la liste des prenoms');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_temp.courriels('classe_creee', pg_temp.u('201'))
               WHERE destinataire_profil = pg_temp.u('1'))
  AND (SELECT n.params -> 'eleves' FROM public.notifications n
        WHERE n.evenement = 'classe_creee' AND n.destinataire = pg_temp.u('1')) IS NULL
  AND (SELECT n.params ->> 'fuseau' FROM public.notifications n
        WHERE n.evenement = 'classe_creee' AND n.destinataire = pg_temp.u('1')) = 'Europe/Paris',
  '1.3 classe creee : l''enseignant, dans l''application seulement, sans prenom d''enfant, dans son fuseau');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 2. FN-108 : Sami rejoint la classe du mardi.
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.u('202'), pg_temp.u('22'));
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(c.destinataire_profil ORDER BY c.destinataire_profil)
     FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c)
    = ARRAY[pg_temp.u('21'), pg_temp.u('22')]
  AND EXISTS (SELECT 1 FROM public.notifications n
               WHERE n.evenement = 'eleve_inscrit' AND n.destinataire = pg_temp.u('1')
                 AND n.params ->> 'groupe_id' = pg_temp.u('202')::text),
  '2.1 eleve inscrit : courriel a Sami et a son tuteur, jamais a l''enseignant (application seulement)');
SELECT pg_temp.vrai(
  (SELECT c.donnees ->> 'portee' FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c
    WHERE c.destinataire_profil = pg_temp.u('21')) = 'foyer'
  AND (SELECT c.donnees -> 'eleves' FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c
        WHERE c.destinataire_profil = pg_temp.u('21')) = '["Sami"]'::jsonb
  AND (SELECT c.donnees ->> 'classe' FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c
        WHERE c.destinataire_profil = pg_temp.u('21')) = 'CUX Classe du mardi'
  AND (SELECT c.donnees ->> 'fuseau' FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c
        WHERE c.destinataire_profil = pg_temp.u('21')) = 'Europe/Paris'
  AND (SELECT c.donnees ->> 'prochaine_local' FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c
        WHERE c.destinataire_profil = pg_temp.u('21')) IS NOT NULL
  AND (SELECT c.donnees ->> 'destination' FROM pg_temp.courriels('eleve_inscrit', pg_temp.u('202')) c
        WHERE c.destinataire_profil = pg_temp.u('21')) = '/tuteur/classes/' || pg_temp.u('202')::text,
  '2.2 eleve inscrit : la famille lit sa portee, Sami seul, la classe, la premiere seance, son lien');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.courriels_sortants c
               WHERE c.destinataire_profil IN (pg_temp.u('11'), pg_temp.u('12'), pg_temp.u('13'))
                 AND c.donnees ->> 'groupe_id' = pg_temp.u('202')::text),
  '2.3 eleve inscrit : l''autre foyer ne recoit rien');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 3. Seance annulee : l'heure, son fuseau, la classe et les enfants.
-- ------------------------------------------------------------------
UPDATE public.sessions SET status = 'canceled' WHERE id = pg_temp.u('401');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  (SELECT c.donnees ->> 'debut_local' FROM pg_temp.courriels('seance_annulee', pg_temp.u('201')) c
    WHERE c.destinataire_profil = pg_temp.u('11'))
    = pg_catalog.to_char(pg_temp.a_l_aube(3) AT TIME ZONE 'America/Toronto', 'YYYY-MM-DD"T"HH24:MI:SS')
  AND (SELECT c.donnees ->> 'fuseau' FROM pg_temp.courriels('seance_annulee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) = 'America/Toronto'
  AND (SELECT c.donnees ->> 'classe' FROM pg_temp.courriels('seance_annulee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) = 'CUX Les bases, lundi'
  AND (SELECT c.donnees -> 'eleves' FROM pg_temp.courriels('seance_annulee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) = '["Lina", "Yanis"]'::jsonb
  AND (SELECT c.donnees ->> 'fuseau' FROM pg_temp.courriels('seance_annulee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('1')) = 'Europe/Paris'
  AND (SELECT c.donnees ->> 'prochaine_local' FROM pg_temp.courriels('seance_annulee', pg_temp.u('201')) c
        WHERE c.destinataire_profil = pg_temp.u('11')) IS NULL,
  '3.1 seance annulee : heure du foyer et son fuseau, classe, enfants ; l''enseignant dans le sien');
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- 4. Enseignant affecte : aucun courriel, a personne (decision du 01/11).
-- ------------------------------------------------------------------
UPDATE public.groupes SET teacher_id = pg_temp.u('2'), etat = 'active' WHERE id = pg_temp.u('203');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.notifications n
           WHERE n.evenement = 'enseignant_affecte' AND n.params ->> 'groupe_id' = pg_temp.u('203')::text)
  AND NOT EXISTS (SELECT 1 FROM pg_temp.courriels('enseignant_affecte', pg_temp.u('203'))),
  '4.1 enseignant affecte : notifie dans l''application, aucun courriel');

DO $fin$ BEGIN RAISE NOTICE 'COURRIELS-UX : scenario vert'; END $fin$;
ROLLBACK;
