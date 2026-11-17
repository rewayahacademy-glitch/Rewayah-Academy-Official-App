-- VU-UNE-FOIS (16/11/2026) : ce que la personne a vu ne revient plus, par compte. A rejouer sur
-- une base NEUVE ; le scenario annule tout a la fin.
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'VU-UNE-FOIS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
-- Le code SQLSTATE d'un appel qui doit etre refuse.
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  BEGIN
    EXECUTE p_sql INTO v;
    EXECUTE 'RESET ROLE';
    RETURN 'ACCEPTE';
  EXCEPTION WHEN OTHERS THEN
    EXECUTE 'RESET ROLE';
    RETURN SQLSTATE;
  END;
END $$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) VALUES
  ('c8000000-0000-0000-0000-000000000001', 'vu-tuteur@test.invalid'),
  ('c8000000-0000-0000-0000-000000000002', 'vu-enseignant@test.invalid'),
  ('c8000000-0000-0000-0000-000000000003', 'vu-attente@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('c8000000-0000-0000-0000-000000000101', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('c8000000-0000-0000-0000-000000000001', 'VU-01', 'guardian', 'c8000000-0000-0000-0000-000000000101', 'Nour', 'Tuteur', 'active', 'female'),
  ('c8000000-0000-0000-0000-000000000002', 'VU-02', 'teacher', NULL, 'Oumar', 'Enseignant', 'active', 'male'),
  ('c8000000-0000-0000-0000-000000000003', 'VU-03', 'guardian', 'c8000000-0000-0000-0000-000000000101', 'Compte', 'Attente', 'pending_kyc', 'male');
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(
  pg_temp.en('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.lire_vus())$$) = '[]'::jsonb,
  'v1 : un compte neuf n''a rien vu');
SELECT pg_temp.vrai(
  pg_temp.en('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_vu('aide.tour-accueil'))$$) = 'true'::jsonb,
  'v2 : marquer_vu rend vrai');
SELECT pg_temp.vrai(
  pg_temp.en('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.lire_vus())$$) = '["aide.tour-accueil"]'::jsonb,
  'v3 : la cle est lue ensuite');
SELECT pg_temp.vrai(
  pg_temp.en('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_vu('aide.tour-accueil'))$$) = 'true'::jsonb
  AND (SELECT count(*) FROM public.vus_une_fois WHERE profile_id = 'c8000000-0000-0000-0000-000000000001') = 1,
  'v4 : idempotent, une seule ligne');
SELECT pg_temp.vrai(
  (SELECT vu_le FROM public.vus_une_fois WHERE profile_id = 'c8000000-0000-0000-0000-000000000001') IS NOT NULL,
  'v5 : la date est posee');
SELECT pg_temp.vrai(
  pg_temp.en('c8000000-0000-0000-0000-000000000002', 'teacher', $$SELECT to_jsonb(public.lire_vus())$$) = '[]'::jsonb,
  'v6 : un autre compte ne voit pas ce que le premier a vu (par compte, pas global)');
SELECT pg_temp.vrai(
  pg_temp.en('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(count(*)) FROM public.vus_une_fois$$) = '1'::jsonb
  AND pg_temp.en('c8000000-0000-0000-0000-000000000002', 'teacher', $$SELECT to_jsonb(count(*)) FROM public.vus_une_fois$$) = '0'::jsonb,
  'v7 : la table n''est lisible que par son titulaire');
SELECT pg_temp.vrai(
  pg_temp.refus('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_vu('Mauvaise Cle'))$$) = '22023'
  AND pg_temp.refus('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_vu('ab'))$$) = '22023'
  AND pg_temp.refus('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_vu(NULL))$$) = '22023'
  AND pg_temp.refus('c8000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_vu(repeat('a', 61)))$$) = '22023',
  'v8 : une cle hors format (majuscules, espace, trop courte, nulle, trop longue) est refusee');
SELECT pg_temp.vrai(
  pg_temp.refus('c8000000-0000-0000-0000-000000000003', 'guardian', $$SELECT to_jsonb(public.marquer_vu('aide.autre'))$$) = '42501'
  AND pg_temp.en('c8000000-0000-0000-0000-000000000003', 'guardian', $$SELECT to_jsonb(public.lire_vus())$$) = '[]'::jsonb,
  'v9 : un compte non valide ne marque rien et ne lit rien');
SELECT pg_temp.vrai(
  pg_temp.refus(NULL, 'guardian', $$SELECT to_jsonb(public.marquer_vu('aide.autre'))$$) = '42501',
  'v10 : sans session, refus');
-- Plafond de 200 cles par compte.
INSERT INTO public.vus_une_fois (profile_id, cle)
SELECT 'c8000000-0000-0000-0000-000000000002', 'cle_' || g FROM generate_series(1, 200) g;
SELECT pg_temp.vrai(
  pg_temp.refus('c8000000-0000-0000-0000-000000000002', 'teacher', $$SELECT to_jsonb(public.marquer_vu('cle_nouvelle'))$$) = '54000'
  AND pg_temp.en('c8000000-0000-0000-0000-000000000002', 'teacher', $$SELECT to_jsonb(public.marquer_vu('cle_7'))$$) = 'true'::jsonb,
  'v11 : au plafond de 200 cles, une cle nouvelle est refusee, une cle deja vue reste acceptee');
-- Aucune ecriture directe.
SELECT pg_temp.vrai(
  pg_temp.refus('c8000000-0000-0000-0000-000000000001', 'guardian', $$WITH i AS (INSERT INTO public.vus_une_fois (profile_id, cle) VALUES ('c8000000-0000-0000-0000-000000000001', 'direct_x') RETURNING 1) SELECT to_jsonb(count(*)) FROM i$$) = '42501'
  AND pg_temp.refus('c8000000-0000-0000-0000-000000000001', 'guardian', $$WITH u AS (UPDATE public.vus_une_fois SET vu_le = now() RETURNING 1) SELECT to_jsonb(count(*)) FROM u$$) = '42501',
  'v12 : aucune ecriture directe par le client');
-- Droits.
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.lire_vus()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.marquer_vu(text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.lire_vus()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.marquer_vu(text)', 'EXECUTE')
  AND NOT has_table_privilege('anon', 'public.vus_une_fois', 'SELECT')
  AND NOT has_table_privilege('agent_ro', 'public.vus_une_fois', 'SELECT'),
  'v13 : anon et agent_ro sans droit, authenticated seulement par les deux fonctions');
SELECT pg_temp.vrai(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.vus_une_fois'::regclass),
  'v14 : RLS active');
ROLLBACK;
