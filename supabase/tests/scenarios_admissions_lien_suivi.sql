-- ADMISSIONS-CHAMPS (migration 20261130985000) : lister_demandes_admission rend `suivi`, le lien de suivi
-- (private.sources_inscription.source_ref) du titulaire de la demande, ou nul ; seule la direction active lit ;
-- la table reste illisible pour un client. Rejoue apres stub_auth.sql et toutes les migrations.
-- Donnees fictives, tout est annule a la fin. Un echec leve 'ADM-SUIVI ROUGE : ...'. Aucun mot d'effacement.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('af000000-0000-4000-8000-000000000001', 'suivi-direction@example.test'),
  ('af000000-0000-4000-8000-000000000002', 'suivi-avec@example.test'),
  ('af000000-0000-4000-8000-000000000003', 'suivi-sans@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('af000000-0000-4000-8000-000000000001', 'ADMSUIVIADMIN001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Une famille venue par un lien de suivi, un adulte sans lien.
SELECT set_config('request.jwt.claim.sub', 'af000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'af000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'SuiviAvec', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant", "age": 8, "genre": "male", "niveau": "debut_lettres"}]'::jsonb, 'mosquee');
SELECT public.noter_source_inscription('chingford-londres');
RESET ROLE;

SELECT set_config('request.jwt.claim.sub', 'af000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'af000000-0000-4000-8000-000000000003', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Fixture', 'SuiviSans', 'male', 'Europe/Paris', false,
  '[{"est_titulaire": true, "niveau": "debut_lettres"}]'::jsonb);
RESET ROLE;

-- La direction lit.
SELECT set_config('request.jwt.claim.sub', 'af000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'af000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $direction$
DECLARE
  v_avec jsonb;
  v_sans jsonb;
BEGIN
  SELECT l INTO v_avec
    FROM pg_catalog.jsonb_array_elements(public.lister_demandes_admission('famille', NULL, 1) -> 'lignes') AS l
   WHERE l ->> 'nom' LIKE '%SuiviAvec%';
  SELECT l INTO v_sans
    FROM pg_catalog.jsonb_array_elements(public.lister_demandes_admission('eleve_adulte', NULL, 1) -> 'lignes') AS l
   WHERE l ->> 'nom' LIKE '%SuiviSans%';
  IF v_avec IS NULL OR v_avec ->> 'suivi' IS DISTINCT FROM 'chingford-londres'
     OR v_avec ->> 'source' IS DISTINCT FROM 'mosquee' THEN
    RAISE EXCEPTION 'ADM-SUIVI ROUGE : le lien de suivi (ou la source) n''est pas rendu : %', v_avec;
  END IF;
  IF v_sans IS NULL OR NOT (v_sans ? 'suivi')
     OR pg_catalog.jsonb_typeof(v_sans -> 'suivi') IS DISTINCT FROM 'null' THEN
    RAISE EXCEPTION 'ADM-SUIVI ROUGE : sans lien, suivi doit etre nul : %', v_sans;
  END IF;
  RAISE NOTICE 'ADM-SUIVI OK : la direction lit le lien de suivi';
END
$direction$;
RESET ROLE;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Une famille ne lit ni la liste ni la table.
SELECT set_config('request.jwt.claim.sub', 'af000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'af000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
DO $famille$
BEGIN
  BEGIN
    PERFORM public.lister_demandes_admission('famille', NULL, 1);
    RAISE EXCEPTION 'ADM-SUIVI ROUGE : une famille lit la liste de la direction';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM 1 FROM private.sources_inscription;
    RAISE EXCEPTION 'ADM-SUIVI ROUGE : la table des sources est lisible par un client';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'ADM-SUIVI OK : la famille ne lit ni la liste ni la table';
END
$famille$;
RESET ROLE;

DO $acl$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.lister_demandes_admission(text,text,integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
          'public.lister_demandes_admission(text,text,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ADM-SUIVI ROUGE : droits d''execution invalides';
  END IF;
  RAISE NOTICE 'ADM-SUIVI OK : droits d''execution';
END
$acl$;

ROLLBACK;
