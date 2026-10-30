-- D4 (24/10/2026) faisait naitre le tuteur ACTIF. Annule par la decision du
-- directeur du 27/10/2026 (DECISION-ADMISSION-2026-10-27.md, lot B, migration
-- 20261029120000_admission_lot_b_famille_en_attente.sql) : le tuteur nait en
-- attente avec sa demande ; une fois la demande confirmee et le compte active
-- par la direction, l'enfant cree par le tuteur nait actif, donc proposable a
-- « Ajouter un eleve ». L'enseignant reste en attente de sa piece.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin. Chaque
-- controle reussi ecrit une ligne "D4 OK" ; un echec leve 'D4 ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('d4000000-0000-4000-8000-000000000001', 'd4-tuteur@example.test'),
  ('d4000000-0000-4000-8000-000000000002', 'd4-enseignant@example.test'),
  ('d4000000-0000-4000-8000-000000000003', 'd4-enfant@example.test');

-- Le tuteur s'inscrit (« famille »), sous le role connecte.
SELECT set_config('request.jwt.claim.sub', 'd4000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'd4000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Tuteur', 'male', 'Europe/Paris', false);
RESET ROLE;

-- L'enseignant s'inscrit par la voie interne (le statut se pose au meme
-- endroit pour les deux roles).
SELECT set_config('request.jwt.claim.sub', 'd4000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'd4000000-0000-4000-8000-000000000002', true);
SELECT private.creer_profil_inscription_interne('teacher', 'Fixture', 'Enseignant', 'female');

DO $statuts$
BEGIN
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'd4000000-0000-4000-8000-000000000001') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'D4 ROUGE : le tuteur ne nait pas en attente (admission, 27/10)';
  END IF;
  IF (SELECT p.household_id FROM public.profiles p
       WHERE p.id = 'd4000000-0000-4000-8000-000000000001') IS NULL THEN
    RAISE EXCEPTION 'D4 ROUGE : le tuteur n''a pas de foyer';
  END IF;
  IF (SELECT p.account_status FROM public.profiles p
       WHERE p.id = 'd4000000-0000-4000-8000-000000000002') <> 'pending_kyc' THEN
    RAISE EXCEPTION 'D4 ROUGE : l''enseignant ne nait plus en attente de sa piece';
  END IF;
  RAISE NOTICE 'D4 OK : tuteur en attente avec foyer, enseignant en attente';
END
$statuts$;

-- La direction admet la famille (geste du lot C, joue ici a la main) : la
-- demande est confirmee, puis le compte est active.
UPDATE public.candidatures SET etape = 'confirmee'
 WHERE profile_id = 'd4000000-0000-4000-8000-000000000001' AND type_code = 'famille';
UPDATE public.profiles SET account_status = 'active'
 WHERE id = 'd4000000-0000-4000-8000-000000000001';

-- Le tuteur cree un enfant (comme la fonction Edge creer-profil-enfant).
UPDATE auth.users SET raw_app_meta_data = jsonb_build_object(
  'child_of', 'd4000000-0000-4000-8000-000000000001')
 WHERE id = 'd4000000-0000-4000-8000-000000000003';
SELECT set_config('request.jwt.claim.sub', 'd4000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'd4000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims',
  '{"sub":"d4000000-0000-4000-8000-000000000001","app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt',
  '{"sub":"d4000000-0000-4000-8000-000000000001","app_metadata":{"role":"guardian"}}', true);
SELECT public.creer_profil_enfant(
  'd4000000-0000-4000-8000-000000000003',
  'd4000000-0000-4000-8000-000000000001', 'Fixture', 'Enfant', 8);

DO $enfant$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = 'd4000000-0000-4000-8000-000000000003'
       AND p.role = 'student' AND p.account_status = 'active'
       AND p.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'D4 ROUGE : l''enfant ne nait pas eleve actif';
  END IF;
  RAISE NOTICE 'D4 OK : l''enfant nait eleve actif (proposable a « Ajouter un eleve »)';
END
$enfant$;

ROLLBACK;
