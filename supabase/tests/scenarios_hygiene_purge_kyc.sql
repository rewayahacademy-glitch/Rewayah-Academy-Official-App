-- HYGIENE-2, point 10 (08/11/2026), migration 20261122100000_hygiene_purge_kyc.sql.
-- Rouge sans la migration, vert avec. Preuves :
--   1. un enseignant qui depose sa propre piece sous RLS en fournissant
--      purge_at = 2100 obtient la date de la base (maintenant + duree de
--      conservation), pas la sienne ;
--   2. un depot sans purge_at obtient la meme date (temoin, inchange) ;
--   3. une insertion par le role postgres qui fournit purge_at est ramenee
--      aussi a la date de la base ;
--   4. l'UPDATE de l'anonymisation (purge anticipee) n'est pas touche :
--      purge_at ramene a maintenant reste a maintenant.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'HYGIENE-2 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated',
                       'app_metadata', jsonb_build_object('role', p_role))::text, true);
  PERFORM set_config('test.uid', p_id::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', p_role))::text, true);
END $$;

-- Postgres nu : les droits de table de la plateforme, le temps du scenario.
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT ON public.kyc_documents TO authenticated;

INSERT INTO auth.users (id) VALUES
  ('9d000000-0000-0000-0000-000000000001'), ('9d000000-0000-0000-0000-000000000002'),
  ('9d000000-0000-0000-0000-000000000003');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('9d000000-0000-0000-0000-000000000001', 'HYG2-ENS-1', 'teacher', 'Ens', 'Un',    'pending_kyc', 'male'),
  ('9d000000-0000-0000-0000-000000000002', 'HYG2-ENS-2', 'teacher', 'Ens', 'Deux',  'pending_kyc', 'female'),
  ('9d000000-0000-0000-0000-000000000003', 'HYG2-ENS-3', 'teacher', 'Ens', 'Trois', 'pending_kyc', 'male');
-- FN-101 B : le contenu de la piece est confirme par le serveur avant le depot.
INSERT INTO private.kyc_contenus_confirmes (object_key, depose_par, type_contenu) VALUES
  ('9d000000-0000-0000-0000-000000000001/piece.webp', '9d000000-0000-0000-0000-000000000001', 'image/jpeg'),
  ('9d000000-0000-0000-0000-000000000002/piece.webp', '9d000000-0000-0000-0000-000000000002', 'image/jpeg');

-- La duree attendue, lue comme le declencheur la lit.
CREATE TEMP TABLE hyg2_attendu ON COMMIT DROP AS
SELECT pg_catalog.make_interval(days =>
         coalesce((public.get_config('kyc_retention_days', '90'::jsonb) #>> '{}')::int, 90)) AS duree;
GRANT SELECT ON hyg2_attendu TO authenticated;

-- 1. Depot sous RLS avec une date de purge fournie (2100).
SET LOCAL ROLE authenticated;
SELECT pg_temp.etre('9d000000-0000-0000-0000-000000000001', 'teacher');
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, purge_at)
VALUES ('9d000000-0000-0000-0000-000000000001', 'id_card', 'male',
        '9d000000-0000-0000-0000-000000000001/piece.webp', '2100-01-01T00:00:00Z');

-- 2. Depot sous RLS sans date de purge (temoin).
SELECT pg_temp.etre('9d000000-0000-0000-0000-000000000002', 'teacher');
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
VALUES ('9d000000-0000-0000-0000-000000000002', 'id_card', 'female',
        '9d000000-0000-0000-0000-000000000002/piece.webp');
RESET ROLE;

-- 3. Insertion par le role postgres avec une date fournie.
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, purge_at)
VALUES ('9d000000-0000-0000-0000-000000000003', 'id_card', 'male',
        '9d000000-0000-0000-0000-000000000003/piece.webp', '2100-01-01T00:00:00Z');

\o
SELECT pg_temp.vrai(
  (SELECT purge_at = now() + (SELECT duree FROM hyg2_attendu)
     FROM public.kyc_documents WHERE profile_id = '9d000000-0000-0000-0000-000000000001'),
  '1. depot sous RLS avec purge_at 2100 : la date est celle de la base');
SELECT pg_temp.vrai(
  (SELECT purge_at = now() + (SELECT duree FROM hyg2_attendu)
     FROM public.kyc_documents WHERE profile_id = '9d000000-0000-0000-0000-000000000002'),
  '2. depot sans purge_at : la date de la base (inchange)');
SELECT pg_temp.vrai(
  (SELECT purge_at = now() + (SELECT duree FROM hyg2_attendu)
     FROM public.kyc_documents WHERE profile_id = '9d000000-0000-0000-0000-000000000003'),
  '3. insertion postgres avec purge_at 2100 : la date est celle de la base');

-- 4. L'UPDATE de l'anonymisation (20261018150000) ne passe pas par le
-- declencheur : la purge anticipee reste anticipee.
\o /dev/null
UPDATE public.kyc_documents
   SET purge_at = least(coalesce(purge_at, pg_catalog.clock_timestamp()), pg_catalog.clock_timestamp())
 WHERE profile_id = '9d000000-0000-0000-0000-000000000001';
\o
SELECT pg_temp.vrai(
  (SELECT purge_at <= pg_catalog.clock_timestamp()
     FROM public.kyc_documents WHERE profile_id = '9d000000-0000-0000-0000-000000000001'),
  '4. purge anticipee par UPDATE : inchangee');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
               WHERE t.tgrelid = 'public.kyc_documents'::regclass
                 AND t.tgfoid = 'public.completer_kyc_document()'::regprocedure
                 AND (t.tgtype & 16) <> 0),
  '4b. completer_kyc_document ne s''arme pas sur UPDATE');

ROLLBACK;
SELECT 'HYGIENE-2 PURGE : TOUS LES SCENARIOS SONT PASSES' AS verdict;
