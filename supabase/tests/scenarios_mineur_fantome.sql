-- MINEUR-FANTOME (06 et 07/11/2026, migration 20261110340000) :
-- creer_profil_enfant ne cree plus de profil eleve mineur pour un adulte, et
-- enregistre le genre lu dans app_metadata.
--   1. 18 ans (et 35 ans) : refuse (check_violation, « age adulte »).
--   2. Les prenom et nom du titulaire appelant, meme en majuscules, avec un
--      accent et des espaces doubles : refuse (« profil du titulaire »).
--   3. Genre hors de public.gender dans app_metadata : refuse (« genre_requis »).
--   4. Genre « male » dans app_metadata : enregistre sur le profil.
--   5. Genre absent (ancienne fonction Edge, regle B6) : accepte, genre nul.
--   6. Aucun profil refuse n'est ecrit ; les profils crees sont mineurs.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque
-- controle reussi ecrit une ligne "FANTOME OK" ; un echec leve 'FANTOME ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('f4000000-0000-4000-8000-000000000001', 'fantome-tuteur@example.test'),
  ('f4000000-0000-4000-8000-000000000002', 'fantome-adulte@example.test'),
  ('f4000000-0000-4000-8000-000000000003', 'fantome-soi@example.test'),
  ('f4000000-0000-4000-8000-000000000004', 'fantome-enfant@example.test'),
  ('f4000000-0000-4000-8000-000000000005', 'fantome-genre-inconnu@example.test'),
  ('f4000000-0000-4000-8000-000000000006', 'fantome-sans-genre@example.test');

-- Le titulaire s'inscrit, puis la direction l'admet (geste joue a la main).
SELECT set_config('request.jwt.claim.sub', 'f4000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'f4000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Amina', 'Diallo', 'female', 'Europe/Paris', false);
RESET ROLE;
UPDATE public.candidatures SET etape = 'confirmee'
 WHERE profile_id = 'f4000000-0000-4000-8000-000000000001' AND type_code = 'famille';
UPDATE public.profiles SET account_status = 'active'
 WHERE id = 'f4000000-0000-4000-8000-000000000001';

-- Les comptes que la fonction Edge cree avant d'appeler la RPC : child_of,
-- et le genre dans app_metadata (sauf le compte 6, ancienne fonction Edge).
UPDATE auth.users SET raw_app_meta_data = jsonb_build_object(
  'child_of', 'f4000000-0000-4000-8000-000000000001', 'gender', 'male'), created_at = now()
 WHERE id IN ('f4000000-0000-4000-8000-000000000002',
              'f4000000-0000-4000-8000-000000000003',
              'f4000000-0000-4000-8000-000000000004');
UPDATE auth.users SET raw_app_meta_data = jsonb_build_object(
  'child_of', 'f4000000-0000-4000-8000-000000000001', 'gender', 'autre'), created_at = now()
 WHERE id = 'f4000000-0000-4000-8000-000000000005';
UPDATE auth.users SET raw_app_meta_data = jsonb_build_object(
  'child_of', 'f4000000-0000-4000-8000-000000000001'), created_at = now()
 WHERE id = 'f4000000-0000-4000-8000-000000000006';

SELECT set_config('request.jwt.claims',
  '{"sub":"f4000000-0000-4000-8000-000000000001","app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt',
  '{"sub":"f4000000-0000-4000-8000-000000000001","app_metadata":{"role":"guardian"}}', true);

DO $adulte$
BEGIN
  BEGIN
    PERFORM public.creer_profil_enfant(
      'f4000000-0000-4000-8000-000000000002',
      'f4000000-0000-4000-8000-000000000001', 'Autre', 'Adulte', 18);
    RAISE EXCEPTION 'FANTOME ROUGE : un profil mineur de 18 ans est cree';
  EXCEPTION WHEN check_violation THEN
    IF position('age adulte' in SQLERRM) = 0 THEN
      RAISE EXCEPTION 'FANTOME ROUGE : 18 ans refuse sans le marqueur « age adulte » : %', SQLERRM;
    END IF;
    RAISE NOTICE 'FANTOME OK : 18 ans refuse (age adulte)';
  END;
  BEGIN
    PERFORM public.creer_profil_enfant(
      'f4000000-0000-4000-8000-000000000002',
      'f4000000-0000-4000-8000-000000000001', 'Autre', 'Adulte', 35);
    RAISE EXCEPTION 'FANTOME ROUGE : un profil mineur de 35 ans est cree';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'FANTOME OK : 35 ans refuse';
  END;
END;
$adulte$;

DO $soi$
BEGIN
  BEGIN
    PERFORM public.creer_profil_enfant(
      'f4000000-0000-4000-8000-000000000003',
      'f4000000-0000-4000-8000-000000000001', '  AMÎNA ', 'diallo', 12);
    RAISE EXCEPTION 'FANTOME ROUGE : le titulaire se recree en mineur';
  EXCEPTION WHEN check_violation THEN
    IF position('profil du titulaire' in SQLERRM) = 0 THEN
      RAISE EXCEPTION 'FANTOME ROUGE : refus sans le marqueur « profil du titulaire » : %', SQLERRM;
    END IF;
    RAISE NOTICE 'FANTOME OK : prenom et nom du titulaire refuses (casse, accent, espaces)';
  END;
END;
$soi$;

DO $genre_inconnu$
BEGIN
  BEGIN
    PERFORM public.creer_profil_enfant(
      'f4000000-0000-4000-8000-000000000005',
      'f4000000-0000-4000-8000-000000000001', 'Sami', 'Diallo', 10);
    RAISE EXCEPTION 'FANTOME ROUGE : un genre hors de public.gender est accepte';
  EXCEPTION WHEN check_violation THEN
    IF position('genre_requis' in SQLERRM) = 0 THEN
      RAISE EXCEPTION 'FANTOME ROUGE : genre hors liste refuse sans « genre_requis » : %', SQLERRM;
    END IF;
    RAISE NOTICE 'FANTOME OK : genre hors liste refuse (genre_requis)';
  END;
END;
$genre_inconnu$;

SELECT public.creer_profil_enfant(
  'f4000000-0000-4000-8000-000000000004',
  'f4000000-0000-4000-8000-000000000001', 'Yanis', 'Diallo', 9);
SELECT public.creer_profil_enfant(
  'f4000000-0000-4000-8000-000000000006',
  'f4000000-0000-4000-8000-000000000001', 'Nour', 'Diallo', 17);

DO $crees$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
      JOIN public.student_profiles sp ON sp.profile_id = p.id
     WHERE p.id = 'f4000000-0000-4000-8000-000000000004'
       AND p.role = 'student' AND sp.student_type = 'minor'
       AND p.gender = 'male') THEN
    RAISE EXCEPTION 'FANTOME ROUGE : le genre « male » de app_metadata n''est pas enregistre';
  END IF;
  RAISE NOTICE 'FANTOME OK : un enfant de 9 ans est cree, mineur, genre male enregistre';
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
      JOIN public.student_profiles sp ON sp.profile_id = p.id
     WHERE p.id = 'f4000000-0000-4000-8000-000000000006'
       AND sp.student_type = 'minor' AND p.gender IS NULL) THEN
    RAISE EXCEPTION 'FANTOME ROUGE : sans genre (ancienne fonction Edge, B6), la creation est refusee';
  END IF;
  RAISE NOTICE 'FANTOME OK : 17 ans sans genre (ancienne fonction Edge) accepte, genre nul (B6)';
  IF EXISTS (SELECT 1 FROM public.profiles p
              WHERE p.id IN ('f4000000-0000-4000-8000-000000000002',
                             'f4000000-0000-4000-8000-000000000003',
                             'f4000000-0000-4000-8000-000000000005')) THEN
    RAISE EXCEPTION 'FANTOME ROUGE : un profil refuse a ete ecrit';
  END IF;
  RAISE NOTICE 'FANTOME OK : aucun profil refuse n''est ecrit';
END
$crees$;

ROLLBACK;
