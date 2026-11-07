-- MINEUR-FANTOME (06/11/2026, migration 20261110340000) : creer_profil_enfant
-- ne cree plus de profil eleve mineur pour un adulte.
--   1. 18 ans ou plus : refuse (check_violation, « age adulte »).
--   2. Les prenom et nom du titulaire appelant, meme en majuscules, avec un
--      accent et des espaces doubles : refuse (« profil du titulaire »).
--   3. Un vrai enfant du foyer (autre prenom, 9 ans) : cree, mineur.
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
  ('f4000000-0000-4000-8000-000000000004', 'fantome-enfant@example.test');

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

-- Les comptes que la fonction Edge cree avant d'appeler la RPC.
UPDATE auth.users SET raw_app_meta_data = jsonb_build_object(
  'child_of', 'f4000000-0000-4000-8000-000000000001'), created_at = now()
 WHERE id IN ('f4000000-0000-4000-8000-000000000002',
              'f4000000-0000-4000-8000-000000000003',
              'f4000000-0000-4000-8000-000000000004');

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

SELECT public.creer_profil_enfant(
  'f4000000-0000-4000-8000-000000000004',
  'f4000000-0000-4000-8000-000000000001', 'Yanis', 'Diallo', 9);

DO $enfant$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
      JOIN public.student_profiles sp ON sp.profile_id = p.id
     WHERE p.id = 'f4000000-0000-4000-8000-000000000004'
       AND p.role = 'student' AND sp.student_type = 'minor') THEN
    RAISE EXCEPTION 'FANTOME ROUGE : le vrai enfant n''est pas cree';
  END IF;
  IF EXISTS (SELECT 1 FROM public.profiles p
              WHERE p.id IN ('f4000000-0000-4000-8000-000000000002',
                             'f4000000-0000-4000-8000-000000000003')) THEN
    RAISE EXCEPTION 'FANTOME ROUGE : un profil refuse a ete ecrit';
  END IF;
  RAISE NOTICE 'FANTOME OK : un vrai enfant (autre prenom, 9 ans) est cree, mineur';
END
$enfant$;

ROLLBACK;
