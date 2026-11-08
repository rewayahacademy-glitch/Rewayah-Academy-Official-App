-- HARMONISATION-A (08/11/2026, 20261120300000) : le fuseau de l'avis
-- d'entretien et la sortie rapide de remplacement_auto_passer. Prouve :
--   f1. un fuseau valide donne l'heure locale ; un fuseau de fiche invalide
--       laisse la place a celui de la candidature ; aucun fuseau valide :
--       '{}', jamais d'erreur ;
--   s1. rien a faire : la garde dit non, et remplacement_auto_passer rend ses
--       compteurs a zero sans rien ecrire ;
--   s2 a s6. la garde est le sur-ensemble exact des fenetres, prouve au bord
--       de chacune : une seance juste dedans (oui), une juste dehors (non) ;
--       a/c/d (seuil le plus petit, seance pas finie), e (seance non tenue,
--       finie ou non, pas reportee), b (pre-alerte ouverte, sans borne) ;
--   s7. avec une seance dans la fenetre, la fonction travaille comme avant
--       (pre-alerte posee) ;
--   s8. contre-epreuve : sans 20261120300000, le scenario est ROUGE (f1).
-- Le meme comportement qu'avant la sortie rapide est aussi prouve par les
-- scenarios existants rejoues tels quels : remplacement_auto, a3bis, snt.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'HARMONISATION-A ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
-- La garde, lue par son proprietaire (plpgsql : resolue a l'appel, pour la
-- contre-epreuve). Reglages du depot : avertissement 3, alerte 3, non tenue 30.
CREATE FUNCTION pg_temp.a_faire(p_t timestamptz) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  RETURN private.remplacement_auto_a_faire(p_t, 3, 3, 30);
END $$;

-- f1 : le fuseau.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) VALUES
  ('a8000000-0000-4000-8000-000000000001', 'ha-valide@test.invalid'),
  ('a8000000-0000-4000-8000-000000000002', 'ha-repli@test.invalid'),
  ('a8000000-0000-4000-8000-000000000003', 'ha-aucun@test.invalid'),
  ('a8000000-0000-4000-8000-000000000009', 'ha-titulaire@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('a8000000-0000-4000-8000-000000000001', 'HA-01', 'teacher', 'Fuseau', 'Valide', 'pending_kyc', 'male'),
  ('a8000000-0000-4000-8000-000000000002', 'HA-02', 'teacher', 'Fuseau', 'Repli', 'pending_kyc', 'male'),
  ('a8000000-0000-4000-8000-000000000003', 'HA-03', 'teacher', 'Fuseau', 'Aucun', 'pending_kyc', 'male'),
  ('a8000000-0000-4000-8000-000000000009', 'HA-09', 'teacher', 'Titulaire', 'Ha', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana) VALUES
  ('a8000000-0000-4000-8000-000000000001', 'SN', array['francais'], 40, 'pending', 'Africa/Dakar'),
  ('a8000000-0000-4000-8000-000000000002', 'SN', array['francais'], 40, 'pending', 'Pas/Une_Zone'),
  ('a8000000-0000-4000-8000-000000000003', 'SN', array['francais'], 40, 'pending', 'Encore/Fausse'),
  ('a8000000-0000-4000-8000-000000000009', 'SN', array['francais'], 40, 'approved', 'Africa/Dakar');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, fuseau_iana) VALUES
  ('a8000000-0000-4000-8000-000000000102', 'enseignant', 'a8000000-0000-4000-8000-000000000002',
   'male', 'Fuseau Repli', 'verifications', 'entretien_planifie', 'en_cours', 'lien_public', 'Asia/Dubai'),
  ('a8000000-0000-4000-8000-000000000103', 'enseignant', 'a8000000-0000-4000-8000-000000000003',
   'male', 'Fuseau Aucun', 'verifications', 'entretien_planifie', 'en_cours', 'lien_public', 'Toujours/Faux');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.vrai(
  private.entretien_heure_locale('a8000000-0000-4000-8000-000000000001', '2026-12-01 10:00+00')
    = '{"debut_local": "2026-12-01T10:00", "fuseau": "Africa/Dakar"}'::jsonb,
  'f1 : fuseau de fiche valide : heure locale');
SELECT pg_temp.vrai(
  private.entretien_heure_locale('a8000000-0000-4000-8000-000000000002', '2026-12-01 10:00+00')
    = '{"debut_local": "2026-12-01T14:00", "fuseau": "Asia/Dubai"}'::jsonb,
  'f1 : fiche invalide : le fuseau de la candidature prend le relais');
SELECT pg_temp.vrai(
  private.entretien_heure_locale('a8000000-0000-4000-8000-000000000003', '2026-12-01 10:00+00') = '{}'::jsonb,
  'f1 : aucun fuseau valide : {} (l''heure part sans fuseau), sans erreur');

-- Les seances : une classe active, un titulaire. T est fixe.
SET LOCAL session_replication_role = replica;
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('a8000000-0000-4000-8000-000000000201', 'a8000000-0000-4000-8000-000000000009',
        'adulte', 6, 'HA classe', 2, 12, 'UTC');
SET LOCAL session_replication_role = origin;
CREATE TEMP TABLE t (v timestamptz);
INSERT INTO t VALUES ('2030-01-08 12:00+00');
-- Une seance de la classe, de [debut] a [fin] ; rend son id.
CREATE FUNCTION pg_temp.seance(p_debut timestamptz, p_fin timestamptz) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v uuid := gen_random_uuid();
BEGIN
  SET LOCAL session_replication_role = replica;
  INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
  VALUES (v, 'a8000000-0000-4000-8000-000000000009', p_debut, p_fin, 'planned', 'standard',
          'a8000000-0000-4000-8000-000000000201');
  SET LOCAL session_replication_role = origin;
  RETURN v;
END $$;
-- Retire une seance des fenetres (supprimee logiquement).
CREATE FUNCTION pg_temp.retirer(p_id uuid) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  SET LOCAL session_replication_role = replica;
  UPDATE public.sessions SET deleted_at = pg_catalog.now() WHERE id = p_id;
  SET LOCAL session_replication_role = origin;
END $$;
-- Retire toutes les seances de la classe d'essai.
CREATE FUNCTION pg_temp.vider() RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  SET LOCAL session_replication_role = replica;
  UPDATE public.sessions SET deleted_at = pg_catalog.now()
   WHERE groupe_id = 'a8000000-0000-4000-8000-000000000201' AND deleted_at IS NULL;
  SET LOCAL session_replication_role = origin;
END $$;

-- La base de rejeu peut porter des seances d'autres scenarios : la garde se
-- lit a un instant T loin de tout, et l'on verifie d'abord qu'il est vide.
-- s1 : rien a faire.
SELECT pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's1 : aucune seance : la garde dit non');
SELECT pg_temp.vrai(
  private.remplacement_auto_passer((SELECT v FROM t))
    = '{"reportees": 0, "alertes_direction": 0, "pre_alertes": 0, "inutiles": 0, "absences": 0, "prises": 0, "erreurs": 0}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM public.remplacements_preparation p
                    JOIN public.sessions s ON s.id = p.session_id
                   WHERE s.groupe_id = 'a8000000-0000-4000-8000-000000000201'),
  's1 : remplacement_auto_passer rend zero et n''ecrit rien');

-- s2 : a/c/d, bord du debut (seuil 3 min).
SELECT pg_temp.seance((SELECT v FROM t) - interval '3 minutes', (SELECT v FROM t) + interval '40 minutes');
SELECT pg_temp.vrai(pg_temp.a_faire((SELECT v FROM t)), 's2 : commencee depuis 3 min pile : dedans');
SELECT pg_temp.vider();
SELECT pg_temp.seance((SELECT v FROM t) - interval '2 minutes 59 seconds', (SELECT v FROM t) + interval '40 minutes');
SELECT pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's2 : commencee depuis 2 min 59 s : dehors');
SELECT pg_temp.vider();

-- s2 bis : d seul (alerte de la direction plus tot que l'avertissement) : le
-- plus petit seuil commande.
SELECT pg_temp.seance((SELECT v FROM t) - interval '2 minutes', (SELECT v FROM t) + interval '40 minutes');
SELECT pg_temp.vrai(private.remplacement_auto_a_faire((SELECT v FROM t), 5, 2, 30),
  's2 bis : alerte a 2 min, avertissement a 5 : commencee depuis 2 min pile : dedans');
SELECT pg_temp.vider();
SELECT pg_temp.seance((SELECT v FROM t) - interval '1 minute 59 seconds', (SELECT v FROM t) + interval '40 minutes');
SELECT pg_temp.vrai(NOT private.remplacement_auto_a_faire((SELECT v FROM t), 5, 2, 30),
  's2 bis : alerte a 2 min : commencee depuis 1 min 59 s : dehors');
SELECT pg_temp.vider();

-- s3 : a/c/d, bord de la fin (seance pas finie).
SELECT pg_temp.seance((SELECT v FROM t) - interval '10 minutes', (SELECT v FROM t) + interval '1 second');
SELECT pg_temp.vrai(pg_temp.a_faire((SELECT v FROM t)), 's3 : finit dans 1 s : dedans');
SELECT pg_temp.vider();
SELECT pg_temp.seance((SELECT v FROM t) - interval '10 minutes', (SELECT v FROM t));
SELECT pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's3 : finit a T pile : dehors');
SELECT pg_temp.vider();

-- s4 : e, seance non tenue (30 min), finie, pas reportee.
SELECT pg_temp.seance((SELECT v FROM t) - interval '30 minutes', (SELECT v FROM t) - interval '5 minutes');
SELECT pg_temp.vrai(pg_temp.a_faire((SELECT v FROM t)), 's4 : commencee depuis 30 min, finie : dedans');
SELECT pg_temp.vider();
SELECT pg_temp.seance((SELECT v FROM t) - interval '29 minutes 59 seconds', (SELECT v FROM t) - interval '5 minutes');
SELECT pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's4 : commencee depuis 29 min 59 s, finie : dehors');
SELECT pg_temp.vider();
DO $s4b$
DECLARE vs uuid := pg_temp.seance((SELECT v FROM t) - interval '2 hours', (SELECT v FROM t) - interval '1 hour');
BEGIN
  SET LOCAL session_replication_role = replica;
  INSERT INTO public.seances_reportees (session_id, groupe_id, enseignant_titulaire_id)
  VALUES (vs, 'a8000000-0000-4000-8000-000000000201', 'a8000000-0000-4000-8000-000000000009');
  SET LOCAL session_replication_role = origin;
END
$s4b$;
SELECT pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's4 : seance deja reportee : dehors');
SELECT pg_temp.vider();

-- s5 : b, pre-alerte ouverte (aucune borne de temps).
DO $s5$
DECLARE vs uuid := pg_temp.seance((SELECT v FROM t) + interval '1 day', (SELECT v FROM t) + interval '1 day 45 minutes');
BEGIN
  SET LOCAL session_replication_role = replica;
  INSERT INTO public.remplacements_preparation (session_id, evenement) VALUES (vs, 'pre_alerte');
  SET LOCAL session_replication_role = origin;
  PERFORM pg_temp.vrai(pg_temp.a_faire((SELECT v FROM t)), 's5 : pre-alerte ouverte, seance demain : dedans');
  SET LOCAL session_replication_role = replica;
  INSERT INTO public.remplacements_preparation (session_id, evenement) VALUES (vs, 'remplacement_inutile');
  SET LOCAL session_replication_role = origin;
  PERFORM pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's5 : pre-alerte close (remplacement inutile) : dehors');
END
$s5$;
SELECT pg_temp.vider();
DO $s5b$
DECLARE vs uuid := pg_temp.seance((SELECT v FROM t) + interval '1 day', (SELECT v FROM t) + interval '1 day 45 minutes');
BEGIN
  SET LOCAL session_replication_role = replica;
  INSERT INTO public.remplacements_preparation (session_id, evenement) VALUES (vs, 'pre_alerte');
  INSERT INTO public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence)
  VALUES (vs, 'absence_declaree', 'a8000000-0000-4000-8000-000000000009',
          'a8000000-0000-4000-8000-000000000009', gen_random_uuid());
  SET LOCAL session_replication_role = origin;
  PERFORM pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's5 : pre-alerte suivie d''une absence : dehors');
END
$s5b$;
SELECT pg_temp.vider();

-- s6 : ce que les boucles ecartent, la garde l'ecarte aussi.
DO $s6$
DECLARE vs uuid;
BEGIN
  vs := pg_temp.seance((SELECT v FROM t) - interval '5 minutes', (SELECT v FROM t) + interval '40 minutes');
  PERFORM pg_temp.retirer(vs);
  PERFORM pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's6 : seance supprimee : dehors');
  vs := pg_temp.seance((SELECT v FROM t) - interval '5 minutes', (SELECT v FROM t) + interval '40 minutes');
  SET LOCAL session_replication_role = replica;
  UPDATE public.sessions SET status = 'ended' WHERE id = vs;
  SET LOCAL session_replication_role = origin;
  PERFORM pg_temp.vrai(NOT pg_temp.a_faire((SELECT v FROM t)), 's6 : seance terminee (ended) : dehors');
END
$s6$;
SELECT pg_temp.vider();

-- s7 : avec une seance dans la fenetre, la fonction travaille comme avant.
SELECT pg_temp.seance((SELECT v FROM t) - interval '4 minutes', (SELECT v FROM t) + interval '40 minutes');
SELECT pg_temp.vrai(
  (private.remplacement_auto_passer((SELECT v FROM t)) ->> 'pre_alertes')::integer = 1
  AND EXISTS (SELECT 1 FROM public.remplacements_preparation p
                JOIN public.sessions s ON s.id = p.session_id
               WHERE s.groupe_id = 'a8000000-0000-4000-8000-000000000201'
                 AND p.evenement = 'pre_alerte'),
  's7 : seance dans la fenetre : la pre-alerte est posee, comme avant');

-- Droits : la garde est fermee au client.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated',
        'private.remplacement_auto_a_faire(timestamptz,integer,integer,integer)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon',
        'private.remplacement_auto_a_faire(timestamptz,integer,integer,integer)', 'EXECUTE'),
  'droits : la garde est fermee au client');

ROLLBACK;
