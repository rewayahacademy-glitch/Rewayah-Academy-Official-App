-- NOUVEAUTES (07/11/2026) : le badge « Nouveau » par compte. A rejouer sur une
-- base NEUVE ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'NOUVEAUTES ROUGE : %', p_label;
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

-- Les gardes d'activation (contrat signe) ne sont pas l'objet du scenario.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) VALUES
  ('c7000000-0000-0000-0000-000000000001', 'nv-tuteur@test.invalid'),
  ('c7000000-0000-0000-0000-000000000002', 'nv-enseignant@test.invalid'),
  ('c7000000-0000-0000-0000-000000000003', 'nv-attente@test.invalid');
INSERT INTO public.households (id, timezone) VALUES ('c7000000-0000-0000-0000-000000000101', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('c7000000-0000-0000-0000-000000000001', 'NV-01', 'guardian', 'c7000000-0000-0000-0000-000000000101', 'Nour', 'Tuteur', 'active', 'female'),
  ('c7000000-0000-0000-0000-000000000002', 'NV-02', 'teacher', NULL, 'Oumar', 'Enseignant', 'active', 'male'),
  ('c7000000-0000-0000-0000-000000000003', 'NV-03', 'guardian', 'c7000000-0000-0000-0000-000000000101', 'Compte', 'Attente', 'pending_kyc', 'male');
SET LOCAL session_replication_role = origin;
INSERT INTO public.nouveautes (cle, sortie_le, roles, description) VALUES
  ('essai_recent', now() - interval '1 day', ARRAY['guardian']::public.app_role[], 'Essai recent'),
  ('essai_ancien', now() - interval '15 days', ARRAY['guardian']::public.app_role[], 'Essai de plus de 14 jours'),
  ('essai_futur', now() + interval '1 day', ARRAY['guardian']::public.app_role[], 'Essai pas encore sorti'),
  ('essai_prof', now() - interval '1 day', ARRAY['teacher']::public.app_role[], 'Essai enseignant');

SELECT pg_temp.vrai(
  pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.mes_nouveautes())$$)
    ? 'essai_recent'
  AND NOT pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.mes_nouveautes())$$)
    ?| ARRAY['essai_ancien', 'essai_futur', 'essai_prof'],
  'n1 : le tuteur voit la nouveaute recente de son role ; ni l''ancienne (14 jours), ni la future, ni celle d''un autre role');
SELECT pg_temp.vrai(
  pg_temp.en('c7000000-0000-0000-0000-000000000002', 'teacher', $$SELECT to_jsonb(public.mes_nouveautes())$$)
    ? 'essai_prof'
  AND NOT pg_temp.en('c7000000-0000-0000-0000-000000000002', 'teacher', $$SELECT to_jsonb(public.mes_nouveautes())$$)
    ? 'essai_recent',
  'n2 : l''enseignant voit la sienne seulement');
-- Chaque appel est sa propre instruction, comme deux requetes de l'application.
CREATE TEMP TABLE r (n integer, v jsonb);
INSERT INTO r SELECT 1, pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_nouveaute_vue('essai_recent'))$$);
INSERT INTO r SELECT 2, pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_nouveaute_vue('essai_recent'))$$);
INSERT INTO r SELECT 3, pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.mes_nouveautes())$$);
SELECT pg_temp.vrai(
  (SELECT v FROM r WHERE n = 1) = 'true' AND (SELECT v FROM r WHERE n = 2) = 'true'
  AND (SELECT count(*) FROM public.nouveautes_vues WHERE profile_id = 'c7000000-0000-0000-0000-000000000001') = 1
  AND NOT (SELECT v FROM r WHERE n = 3) ? 'essai_recent',
  'n3 : ouverte une fois, elle ne revient plus (par compte, donc sur tout appareil) ; idempotent');
SELECT pg_temp.vrai(
  pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_nouveaute_vue('essai_prof'))$$) = 'false'
  AND pg_temp.en('c7000000-0000-0000-0000-000000000001', 'guardian', $$SELECT to_jsonb(public.marquer_nouveaute_vue('inconnue'))$$) = 'false'
  AND (SELECT count(*) FROM public.nouveautes_vues WHERE profile_id = 'c7000000-0000-0000-0000-000000000001') = 1,
  'n4 : la cle d''un autre role ou inconnue : rien de marque');
DO $refus$
BEGIN
  PERFORM pg_temp.qui('c7000000-0000-0000-0000-000000000003', 'guardian');
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.marquer_nouveaute_vue('essai_recent');
    RAISE EXCEPTION 'NOUVEAUTES ROUGE : n5 : un compte non valide marque';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK n5 : un compte non valide ne marque rien (42501)';
  END;
  IF array_length(public.mes_nouveautes(), 1) IS NOT NULL THEN
    RAISE EXCEPTION 'NOUVEAUTES ROUGE : n5bis : un compte non valide lit des nouveautes';
  END IF;
  BEGIN
    INSERT INTO public.nouveautes_vues (profile_id, cle) VALUES ('c7000000-0000-0000-0000-000000000003', 'essai_recent');
    RAISE EXCEPTION 'NOUVEAUTES ROUGE : n6 : ecriture client directe';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK n6 : aucune ecriture client directe';
  END;
  RESET ROLE;
END
$refus$;
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.nouveautes WHERE cle IN ('couleur_profil', 'moyen_paiement', 'historique_classe',
                                                         'recevoir_paiements', 'export_wise')) = 5
  AND NOT has_function_privilege('anon', 'public.mes_nouveautes()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.marquer_nouveaute_vue(text)', 'EXECUTE'),
  'n7 : liste de depart posee ; rien pour anon');
ROLLBACK;
