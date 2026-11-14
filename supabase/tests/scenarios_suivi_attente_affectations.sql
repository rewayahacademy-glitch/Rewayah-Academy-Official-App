-- SUIVI-ATTENTE : chaque chemin d'affectation d'un enseignant, rejoue en
-- transactions SEPAREES (une validation par geste). Le scenario principal
-- (`scenarios_suivi_attente.sql`) tient dans une seule transaction, ou la
-- deduplication par instant (`cree_le = now()`) masque ce que les declencheurs
-- differes font vraiment ; celui-ci ne le masque pas. A rejouer sur une base
-- neuve apres stub_auth.sql et toutes les migrations.
--
-- Gestes, chacun dans sa transaction :
--   T1 : A vers nul    : A recoit enseignant_change, la famille et l'eleve aussi ;
--   T2 : nul vers A    : A recoit enseignant_affecte, jamais enseignant_change ;
--   T3 : A vers B      : B recoit enseignant_affecte seulement ; A, la famille et
--                        l'eleve recoivent enseignant_change ;
--   T4 : B, nul, A     : dans UNE transaction ; A recoit enseignant_affecte une
--                        fois, jamais enseignant_change ; B recoit enseignant_change ;
--   T5 : A, nul, B     : dans UNE transaction ; B recoit enseignant_affecte une
--                        fois, jamais enseignant_change ; A recoit enseignant_change.

CREATE FUNCTION pg_temp.n(p_dest uuid, p_evt text, p_depuis timestamptz) RETURNS integer
LANGUAGE sql AS $f$
  SELECT count(*)::integer FROM public.notifications n
   WHERE n.destinataire = p_dest AND n.evenement = p_evt
     AND n.params ->> 'groupe_id' = '5cfffff0-0000-0000-0000-0000000000a1'
     AND n.cree_le >= p_depuis
$f$;

CREATE FUNCTION pg_temp.attendu(p_dest uuid, p_evt text, p_n integer, p_depuis timestamptz, p_label text)
RETURNS void LANGUAGE plpgsql AS $f$
DECLARE v integer;
BEGIN
  v := pg_temp.n(p_dest, p_evt, p_depuis);
  IF v <> p_n THEN
    RAISE EXCEPTION 'AFFECTATIONS : % : % recu(s) %, attendu %', p_label, v, p_evt, p_n;
  END IF;
END
$f$;

-- Les personnes : A (5c..03), B (5c..07), un tuteur, un enfant, un adulte.
INSERT INTO auth.users (id, email) VALUES
  ('5c000000-0000-0000-0000-000000000001', 'aff-tuteur@example.test'),
  ('5c000000-0000-0000-0000-000000000002', 'aff-enfant@example.test'),
  ('5c000000-0000-0000-0000-000000000003', 'aff-a@example.test'),
  ('5c000000-0000-0000-0000-000000000007', 'aff-b@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('5cfffff0-0000-0000-0000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('5c000000-0000-0000-0000-000000000001', 'AFFTUTEUR00001', 'guardian',
   '5cfffff0-0000-0000-0000-000000000001', 'Tuteur', 'Un', 'active', 'male'),
  ('5c000000-0000-0000-0000-000000000002', 'AFFENFANT00001', 'student',
   '5cfffff0-0000-0000-0000-000000000001', 'Yusuf', 'Un', 'active', 'male'),
  ('5c000000-0000-0000-0000-000000000003', 'AFFENSEIGNA001', 'teacher',
   NULL, 'Ibrahim', 'Camara', 'provisional_active', 'male'),
  ('5c000000-0000-0000-0000-000000000007', 'AFFENSEIGNA002', 'teacher',
   NULL, 'Khadija', 'Diallo', 'provisional_active', 'female');
UPDATE public.households SET primary_guardian_id = '5c000000-0000-0000-0000-000000000001'
 WHERE id = '5cfffff0-0000-0000-0000-000000000001';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, cohorte) VALUES
  ('5c000000-0000-0000-0000-000000000002', 'minor', 'child', 'enfant_6_9');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status) VALUES
  ('5c000000-0000-0000-0000-000000000003', 'Guinée', ARRAY['fr']::text[], 'approved'),
  ('5c000000-0000-0000-0000-000000000007', 'Mali', ARRAY['fr']::text[], 'approved');

-- La classe, avec A, et l'enfant dedans.
BEGIN;
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code)
VALUES
  ('5cfffff0-0000-0000-0000-0000000000a1', '5c000000-0000-0000-0000-000000000003',
   'active', 'enfant', 5, 'Classe Al-Fatiha', 1, 18, 'Europe/Paris', 'francais');
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('5cfffff0-0000-0000-0000-0000000000a1', '5c000000-0000-0000-0000-000000000002');
COMMIT;

-- ------------------------------------------------------------------
-- T1 : A vers nul
-- ------------------------------------------------------------------
SELECT clock_timestamp() AS t \gset
BEGIN;
UPDATE public.groupes SET teacher_id = NULL, etat = 'en_attente_enseignant'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
COMMIT;
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_change', 1, :'t', 'T1 A est prevenu qu on le retire');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000001', 'enseignant_change', 1, :'t', 'T1 la famille');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000002', 'enseignant_change', 1, :'t', 'T1 l eleve');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_affecte', 0, :'t', 'T1 A n est pas affecte');

-- ------------------------------------------------------------------
-- T2 : nul vers A
-- ------------------------------------------------------------------
SELECT clock_timestamp() AS t \gset
BEGIN;
UPDATE public.groupes SET teacher_id = '5c000000-0000-0000-0000-000000000003', etat = 'active'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
COMMIT;
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_affecte', 1, :'t', 'T2 A est affecte, une fois');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_change', 0, :'t', 'T2 A n a pas enseignant_change');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000001', 'enseignant_affecte', 1, :'t', 'T2 la famille');

-- ------------------------------------------------------------------
-- T3 : A vers B
-- ------------------------------------------------------------------
SELECT clock_timestamp() AS t \gset
BEGIN;
UPDATE public.groupes SET teacher_id = '5c000000-0000-0000-0000-000000000007'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
COMMIT;
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000007', 'enseignant_affecte', 1, :'t', 'T3 B est affecte, une fois');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000007', 'enseignant_change', 0, :'t', 'T3 B n a pas enseignant_change');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_change', 1, :'t', 'T3 A est prevenu');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000001', 'enseignant_change', 1, :'t', 'T3 la famille');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000002', 'enseignant_change', 1, :'t', 'T3 l eleve');
-- Un seul courriel pour B sur cette affectation.
DO $courriel_b$
BEGIN
  IF (SELECT count(*) FROM public.courriels_sortants
       WHERE destinataire_profil = '5c000000-0000-0000-0000-000000000007'
         AND modele = 'enseignant_affecte') <> 1 THEN
    RAISE EXCEPTION 'AFFECTATIONS : T3 un seul courriel pour B';
  END IF;
END
$courriel_b$;

-- ------------------------------------------------------------------
-- T4 : B, nul, A dans UNE transaction
-- ------------------------------------------------------------------
SELECT clock_timestamp() AS t \gset
BEGIN;
UPDATE public.groupes SET teacher_id = NULL, etat = 'en_attente_enseignant'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
UPDATE public.groupes SET teacher_id = '5c000000-0000-0000-0000-000000000003', etat = 'active'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
COMMIT;
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_affecte', 1, :'t', 'T4 A est affecte, une fois');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_change', 0, :'t', 'T4 A n a pas enseignant_change');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000007', 'enseignant_change', 1, :'t', 'T4 B est prevenu qu on le retire');

-- ------------------------------------------------------------------
-- T5 : A, nul, B dans UNE transaction
-- ------------------------------------------------------------------
SELECT clock_timestamp() AS t \gset
BEGIN;
UPDATE public.groupes SET teacher_id = NULL, etat = 'en_attente_enseignant'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
UPDATE public.groupes SET teacher_id = '5c000000-0000-0000-0000-000000000007', etat = 'active'
 WHERE id = '5cfffff0-0000-0000-0000-0000000000a1';
COMMIT;
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000007', 'enseignant_affecte', 1, :'t', 'T5 B est affecte, une fois');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000007', 'enseignant_change', 0, :'t', 'T5 B n a pas enseignant_change');
SELECT pg_temp.attendu('5c000000-0000-0000-0000-000000000003', 'enseignant_change', 1, :'t', 'T5 A est prevenu qu on le retire');
