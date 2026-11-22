-- PARCOURS-BOUT-EN-BOUT (22/11/2026) : `ma_demande_admission` rend `recue_le`
-- des l'envoi, et `decision_le` seulement apres un geste de la direction.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'FRISE ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('fe000000-0000-4000-8000-000000000001', 'frise-direction@example.test'),
  ('fe000000-0000-4000-8000-000000000002', 'frise-famille@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('fe000000-0000-4000-8000-000000000001', 'FRISEADMIN000001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

SELECT set_config('request.jwt.claim.sub', 'fe000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'fe000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant Un", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb);

DO $envoyee$
DECLARE
  v jsonb;
BEGIN
  v := public.ma_demande_admission();
  IF v ->> 'recue_le' IS NULL THEN
    RAISE EXCEPTION 'FRISE ROUGE : recue_le absent apres l''envoi : %', v;
  END IF;
  IF v ->> 'decision_le' IS NOT NULL THEN
    RAISE EXCEPTION 'FRISE ROUGE : decision_le present avant tout geste : %', v;
  END IF;
  RAISE NOTICE 'FRISE OK : envoyee, aucune decision';
END;
$envoyee$;
RESET ROLE;

SELECT set_config('request.jwt.claim.sub', 'fe000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'fe000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $precisions$
DECLARE
  v_id uuid;
  v_version integer;
BEGIN
  SELECT c.id, c.version INTO v_id, v_version FROM public.candidatures c
   WHERE c.profile_id = 'fe000000-0000-4000-8000-000000000002';
  PERFORM public.demander_precisions_admission(v_id, 'Quel est le niveau exact ?',
                                               v_version, 'frise-precisions-1');
END;
$precisions$;

SELECT set_config('request.jwt.claim.sub', 'fe000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'fe000000-0000-4000-8000-000000000002', true);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);
SET LOCAL ROLE authenticated;

DO $decidee$
DECLARE
  v jsonb;
BEGIN
  v := public.ma_demande_admission();
  IF v ->> 'etat' IS DISTINCT FROM 'a_completer' OR v ->> 'decision_le' IS NULL
     OR v ->> 'precisions' IS NULL THEN
    RAISE EXCEPTION 'FRISE ROUGE : a completer sans date de decision : %', v;
  END IF;
  RAISE NOTICE 'FRISE OK : a completer, decision datee';
END;
$decidee$;
RESET ROLE;

ROLLBACK;
