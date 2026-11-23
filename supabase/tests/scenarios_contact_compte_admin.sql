-- APERCU-COMPTE (directeur, 22/11/2026) : contact_compte_admin(uuid) rend le courriel d'un compte a la
-- direction seulement ; un tuteur n'en lit aucun ; anon n'execute pas la fonction ; un compte inconnu ne
-- rend rien. Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations. Tout est annule a la
-- fin. Un echec leve 'APERCU ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ac000000-0000-4000-8000-000000000001', 'apercu-direction@example.test'),
  ('ac000000-0000-4000-8000-000000000002', 'apercu-tuteur@example.test');
INSERT INTO public.households (id) VALUES ('ac000000-0000-4000-8000-0000000000f1');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('ac000000-0000-4000-8000-000000000001', 'APERCUADMIN00001', 'admin', NULL,
   'Fixture', 'Direction', 'active', 'female'),
  ('ac000000-0000-4000-8000-000000000002', 'APERCUTUTEUR0001', 'guardian',
   'ac000000-0000-4000-8000-0000000000f1', 'Amina', 'Tuteur', 'active', 'female');

-- Un tuteur ne lit rien.
SELECT set_config('request.jwt.claim.sub', 'ac000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ac000000-0000-4000-8000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
SET LOCAL ROLE authenticated;
DO $tuteur$
BEGIN
  IF public.contact_compte_admin('ac000000-0000-4000-8000-000000000002') IS NOT NULL THEN
    RAISE EXCEPTION 'APERCU ROUGE : un tuteur lit un courriel';
  END IF;
  RAISE NOTICE 'APERCU OK : un tuteur ne lit aucun courriel';
END;
$tuteur$;
RESET ROLE;

-- anon n'execute pas la fonction.
DO $anon$
BEGIN
  IF has_function_privilege('anon', 'public.contact_compte_admin(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'APERCU ROUGE : anon peut executer contact_compte_admin';
  END IF;
  RAISE NOTICE 'APERCU OK : anon n''execute pas la fonction';
END;
$anon$;

-- La direction lit le courriel du tuteur ; un compte inconnu ne rend rien.
SELECT set_config('request.jwt.claim.sub', 'ac000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ac000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $direction$
BEGIN
  IF public.contact_compte_admin('ac000000-0000-4000-8000-000000000002')
       IS DISTINCT FROM 'apercu-tuteur@example.test' THEN
    RAISE EXCEPTION 'APERCU ROUGE : la direction ne lit pas le courriel du tuteur';
  END IF;
  IF public.contact_compte_admin('ac000000-0000-4000-8000-0000000000ee') IS NOT NULL THEN
    RAISE EXCEPTION 'APERCU ROUGE : un compte inconnu rend un courriel';
  END IF;
  RAISE NOTICE 'APERCU OK : la direction lit le courriel d''un compte';
END;
$direction$;
RESET ROLE;

ROLLBACK;
