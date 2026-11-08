-- NOMS-CLASSES (08/11/2026) : migration 20261121100000_noms_classes.sql.
--
-- Decision du directeur du 25/10/2026 (BOUCLE-1_PLAN_2026-10-24.md §5) : une
-- classe creee sans nom recoit un nom de la banque, feminin pour une classe de
-- femmes, masculin pour une classe d'hommes ; un nom sert a une seule classe
-- active ; la direction peut le changer apres coup ; un nom qui manque n'est
-- jamais un blocage (repli « Classe N »).
--
-- Rejoue sur une base NEUVE (stub_auth.sql puis toutes les migrations), sous une
-- direction active (role authenticated). Fixtures sans donnee personnelle ; tout
-- est annule a la fin. Chaque controle reussi ecrit « NOMS OK » ; un echec leve
-- « NOMS ROUGE : ... ». Avant la migration, le scenario echoue des le premier
-- controle (la banque n'existe pas).
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'NOMS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'NOMS OK %', p_label;
END $$;

-- (a) La banque : 40 noms au moins par genre, RLS active, aucun droit client.
SELECT pg_temp.vrai(pg_catalog.to_regclass('private.noms_classes') IS NOT NULL,
  '(a) la banque des noms existe');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM private.noms_classes WHERE genre = 'femmes') >= 40
  AND (SELECT pg_catalog.count(*) FROM private.noms_classes WHERE genre = 'hommes') >= 40,
  '(a) 40 noms feminins et 40 masculins au moins');
SELECT pg_temp.vrai(
  (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.noms_classes'::regclass),
  '(a) RLS active sur la banque');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('authenticated', 'private.noms_classes', 'SELECT,INSERT,UPDATE,DELETE')
  AND NOT pg_catalog.has_table_privilege('anon', 'private.noms_classes', 'SELECT,INSERT,UPDATE,DELETE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.nom_classe_choisir(text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.nom_classe_choisir(text)', 'EXECUTE'),
  '(a) aucun droit client sur la banque ni sur le choix');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.groupes WHERE ended_at IS NULL),
  '(a) base neuve : aucune classe active avant le scenario');

INSERT INTO auth.users (id, email) VALUES
  ('a0c10000-0000-4000-8000-000000000001', 'noms-admin@example.test'),
  ('a0c10000-0000-4000-8000-0000000000f1', 'noms-f1@example.test'),
  ('a0c10000-0000-4000-8000-0000000000f2', 'noms-f2@example.test'),
  ('a0c10000-0000-4000-8000-0000000000a1', 'noms-m1@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('a0c10000-0000-4000-8000-000000000001', 'NOMSADMIN0000001', 'admin',
   'Fixture', 'Direction', 'active', 'female', NULL),
  ('a0c10000-0000-4000-8000-0000000000f1', 'NOMSTEACHER000F1', 'teacher',
   'Fixture', 'EnseignanteUn', 'provisional_active', 'female', NULL),
  ('a0c10000-0000-4000-8000-0000000000f2', 'NOMSTEACHER000F2', 'teacher',
   'Fixture', 'EnseignanteDeux', 'provisional_active', 'female', NULL),
  ('a0c10000-0000-4000-8000-0000000000a1', 'NOMSTEACHER000A1', 'teacher',
   'Fixture', 'EnseignantUn', 'provisional_active', 'male', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('a0c10000-0000-4000-8000-0000000000f1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('a0c10000-0000-4000-8000-0000000000f2', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('a0c10000-0000-4000-8000-0000000000a1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- Une classe d'adultes en UTC, un seul creneau, dans le genre demande.
CREATE FUNCTION pg_temp.creer(p_teacher uuid, p_nom text, p_jour integer, p_genre text)
RETURNS uuid LANGUAGE sql AS $$
  SELECT public.creer_classe_creneaux_admin(p_teacher, 'adulte', p_nom, 6::smallint, 'UTC',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('jour', p_jour, 'heure', 9)),
    p_genre, NULL::smallint);
$$;
CREATE FUNCTION pg_temp.nom(p_groupe uuid) RETURNS text LANGUAGE sql AS $$
  SELECT g.libelle FROM public.groupes g WHERE g.id = p_groupe;
$$;
CREATE FUNCTION pg_temp.banque(p_groupe uuid) RETURNS smallint LANGUAGE sql AS $$
  SELECT g.nom_banque_id FROM public.groupes g WHERE g.id = p_groupe;
$$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated;

CREATE TEMP TABLE noms_fixture (cle text PRIMARY KEY, groupe uuid);
GRANT ALL ON noms_fixture TO authenticated;

SELECT set_config('request.jwt.claim.sub', 'a0c10000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'a0c10000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

-- (b) La direction cree des classes sans saisir de nom.
SET LOCAL ROLE authenticated;
INSERT INTO noms_fixture VALUES
  ('f_null',  pg_temp.creer('a0c10000-0000-4000-8000-0000000000f1', NULL, 1, 'femmes')),
  ('f_vide',  pg_temp.creer('a0c10000-0000-4000-8000-0000000000f1', '  ', 2, 'femmes')),
  ('h_null',  pg_temp.creer('a0c10000-0000-4000-8000-0000000000a1', NULL, 1, 'hommes')),
  ('mixte',   pg_temp.creer('a0c10000-0000-4000-8000-0000000000f2', NULL, 3, 'mixte')),
  ('saisi',   pg_temp.creer('a0c10000-0000-4000-8000-0000000000f2', 'Classe du matin', 4, 'femmes'));
RESET ROLE;

SELECT pg_temp.vrai(pg_temp.nom((SELECT groupe FROM noms_fixture WHERE cle = 'f_null')) = 'Khadija',
  '(b) classe de femmes sans nom : premier nom feminin (Khadija)');
SELECT pg_temp.vrai(pg_temp.nom((SELECT groupe FROM noms_fixture WHERE cle = 'f_vide')) = 'Aïcha',
  '(b) nom fait d''espaces : nom feminin suivant (Aïcha)');
SELECT pg_temp.vrai(pg_temp.nom((SELECT groupe FROM noms_fixture WHERE cle = 'h_null')) = 'Ibrahim',
  '(b) classe d''hommes sans nom : premier nom masculin (Ibrahim)');
SELECT pg_temp.vrai(pg_temp.nom((SELECT groupe FROM noms_fixture WHERE cle = 'mixte')) = 'Ismaïl',
  '(b) classe mixte : premier nom libre des deux listes, par rang (Ismaïl)');
SELECT pg_temp.vrai(
  pg_temp.banque((SELECT groupe FROM noms_fixture WHERE cle = 'f_null')) IS NOT NULL
  AND pg_temp.banque((SELECT groupe FROM noms_fixture WHERE cle = 'h_null')) IS NOT NULL,
  '(b) la classe porte la reference du nom de la banque');

-- (c) Un nom saisi est garde tel quel, sans reference a la banque.
SELECT pg_temp.vrai(
  pg_temp.nom((SELECT groupe FROM noms_fixture WHERE cle = 'saisi')) = 'Classe du matin'
  AND pg_temp.banque((SELECT groupe FROM noms_fixture WHERE cle = 'saisi')) IS NULL,
  '(c) un nom saisi est garde, sans reference a la banque');

-- (d) Un nom saisi a la main egal a un nom de la banque le prend : il n'est plus
-- propose tant que la classe est active.
INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                            hour_local, timezone_iana, genre_public)
VALUES (NULL, 'en_attente_enseignant', 'adulte', 6, 'Fatima', 5, 9, 'UTC', 'femmes');
INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                            hour_local, timezone_iana, genre_public)
VALUES (NULL, 'en_attente_enseignant', 'adulte', 6, NULL, 5, 10, 'UTC', 'femmes');
SELECT pg_temp.vrai(
  (SELECT g.libelle FROM public.groupes g WHERE g.hour_local = 10 AND g.weekday = 5) = 'Maryam',
  '(d) « Fatima » deja porte par une classe active : le choix passe a Maryam');

-- (e) La direction renomme la classe « Khadija » : la reference a la banque
-- tombe, et le nom redevient libre pour la classe suivante.
UPDATE public.groupes SET libelle = 'Classe des mamans'
 WHERE id = (SELECT groupe FROM noms_fixture WHERE cle = 'f_null');
SELECT pg_temp.vrai(pg_temp.banque((SELECT groupe FROM noms_fixture WHERE cle = 'f_null')) IS NULL,
  '(e) renommee par la direction : la classe ne porte plus le nom de la banque');
INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                            hour_local, timezone_iana, genre_public)
VALUES (NULL, 'en_attente_enseignant', 'adulte', 6, '', 6, 9, 'UTC', 'femmes');
SELECT pg_temp.vrai(
  (SELECT g.libelle FROM public.groupes g WHERE g.weekday = 6 AND g.hour_local = 9) = 'Khadija',
  '(e) le nom libere (Khadija) est repris par la classe suivante');

-- (f) Une classe cloturee libere son nom.
UPDATE public.groupes
   SET ended_at = pg_catalog.now(), ended_by = 'a0c10000-0000-4000-8000-000000000001',
       end_reason = 'scenario NOMS-CLASSES'
 WHERE id = (SELECT groupe FROM noms_fixture WHERE cle = 'h_null');
INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                            hour_local, timezone_iana, genre_public)
VALUES (NULL, 'en_attente_enseignant', 'adulte', 6, NULL, 6, 10, 'UTC', 'hommes');
SELECT pg_temp.vrai(
  (SELECT g.libelle FROM public.groupes g WHERE g.weekday = 6 AND g.hour_local = 10) = 'Ibrahim',
  '(f) la classe cloturee a libere Ibrahim');

-- (g) Un meme nom de la banque ne peut pas servir a deux classes actives.
DO $g$
BEGIN
  INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                              hour_local, timezone_iana, genre_public, nom_banque_id)
  VALUES (NULL, 'en_attente_enseignant', 'adulte', 6, 'Doublon', 7, 9, 'UTC', 'hommes',
          (SELECT g.nom_banque_id FROM public.groupes g WHERE g.libelle = 'Ibrahim' AND g.ended_at IS NULL));
  RAISE EXCEPTION 'NOMS ROUGE : (g) deux classes actives portent le meme nom de la banque';
EXCEPTION WHEN unique_violation THEN
  RAISE NOTICE 'NOMS OK (g) un nom de la banque sert a une seule classe active';
END $g$;

-- (h) REPLI : tous les noms feminins sont pris par des classes actives ; une
-- classe de femmes de plus recoit « Classe 1 », puis « Classe 2 ». Jamais de
-- blocage.
INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                            hour_local, timezone_iana, genre_public)
SELECT NULL, 'en_attente_enseignant', 'adulte', 6, b.nom_fr, 7, 11, 'UTC', 'femmes'
  FROM private.noms_classes b
 WHERE b.genre = 'femmes'
   AND NOT EXISTS (SELECT 1 FROM public.groupes g
                    WHERE g.ended_at IS NULL AND pg_catalog.lower(g.libelle) = pg_catalog.lower(b.nom_fr));
INSERT INTO public.groupes (teacher_id, etat, type_public, seuil_max, libelle, weekday,
                            hour_local, timezone_iana, genre_public)
VALUES (NULL, 'en_attente_enseignant', 'adulte', 6, NULL, 7, 12, 'UTC', 'femmes'),
       (NULL, 'en_attente_enseignant', 'adulte', 6, NULL, 7, 13, 'UTC', 'femmes');
SELECT pg_temp.vrai(
  (SELECT g.libelle FROM public.groupes g WHERE g.weekday = 7 AND g.hour_local = 12) = 'Classe 1'
  AND (SELECT g.libelle FROM public.groupes g WHERE g.weekday = 7 AND g.hour_local = 13) = 'Classe 2'
  AND (SELECT g.nom_banque_id FROM public.groupes g WHERE g.weekday = 7 AND g.hour_local = 12) IS NULL,
  '(h) banque feminine epuisee : repli « Classe 1 » puis « Classe 2 », sans blocage');
SELECT pg_temp.vrai(
  (SELECT g.libelle FROM public.groupes g WHERE g.weekday = 6 AND g.hour_local = 10) = 'Ibrahim',
  '(h) la banque masculine n''est pas touchee par le repli feminin');

-- (i) « Créer la classe » depuis un regroupement accepte un nom vide : le refus
-- n'est plus « parametres_creation_classe_invalides » (le regroupement fictif
-- est refuse plus loin, pour sa propre raison).
SET LOCAL ROLE authenticated;
DO $i$
DECLARE
  v_msg text;
BEGIN
  BEGIN
    PERFORM public.creer_classe_depuis_regroupement(
      'a0c10000-0000-4000-8000-00000000dead'::uuid,
      'a0c10000-0000-4000-8000-00000000beef'::uuid, '');
    v_msg := 'aucun refus';
  EXCEPTION WHEN OTHERS THEN
    v_msg := SQLERRM;
  END;
  IF v_msg = 'parametres_creation_classe_invalides' THEN
    RAISE EXCEPTION 'NOMS ROUGE : (i) le regroupement refuse encore un nom vide';
  END IF;
  RAISE NOTICE 'NOMS OK (i) le regroupement accepte un nom vide (refus suivant : %)', v_msg;
END $i$;
RESET ROLE;

ROLLBACK;

SELECT 'NOMS-CLASSES VERT' AS resultat;
