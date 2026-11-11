-- SEC-GARDE-5 point b (11/11/2026), migration
-- 20261123400100_sec_garde_5_interrupteur_kyc.sql. Rouge sans la migration,
-- vert avec :
--   1. un admin actif ne bascule plus kyc_exception_super_admin : la ligne
--      reste telle quelle et la tentative est dans audit_logs ;
--   2. service_role non plus ;
--   3. postgres seul la modifie, et le changement est dans audit_logs ;
--   4. les autres cles de app_config restent modifiables par un admin.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SEC-GARDE-5 b ROUGE : %', p_label;
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
END $$;

CREATE FUNCTION pg_temp.traces(p_action text) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.audit_logs
   WHERE action = p_action AND table_name = 'app_config' AND row_id = 'kyc_exception_super_admin';
$$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES ('5e5b0000-0000-0000-0000-000000000001');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  ('5e5b0000-0000-0000-0000-000000000001', 'SG5B-ADM', 'admin', 'Adm', 'Un', 'active', 'male');
SET LOCAL session_replication_role = origin;

CREATE TEMP TABLE depart ON COMMIT DROP AS
  SELECT value FROM public.app_config WHERE key = 'kyc_exception_super_admin';
GRANT SELECT ON depart TO authenticated, service_role;

-- 1. Admin actif
SELECT pg_temp.etre('5e5b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'kyc_exception_super_admin';
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'kyc_exception_super_admin') = (SELECT value FROM depart),
  '1 : admin actif : l''interrupteur n''a pas bouge');
SELECT pg_temp.vrai(pg_temp.traces('kyc_exception_tentative_refusee') = 1
  AND (SELECT actor FROM public.audit_logs WHERE action = 'kyc_exception_tentative_refusee'
        ORDER BY id DESC LIMIT 1) = '5e5b0000-0000-0000-0000-000000000001',
  '1 : admin actif : la tentative est dans audit_logs, a son nom');

-- 2. service_role
SELECT set_config('request.jwt.claim.sub', '', true), set_config('request.jwt.claims', '', true);
SET LOCAL ROLE service_role;
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'kyc_exception_super_admin';
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'kyc_exception_super_admin') = (SELECT value FROM depart)
  AND pg_temp.traces('kyc_exception_tentative_refusee') = 2,
  '2 : service_role : refuse, et trace');

-- 3. postgres lui-meme
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'kyc_exception_super_admin';
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'kyc_exception_super_admin') = 'false'::jsonb
  AND pg_temp.traces('kyc_exception_modifiee') = 1
  AND (SELECT payload FROM public.audit_logs WHERE action = 'kyc_exception_modifiee'
        ORDER BY id DESC LIMIT 1) = jsonb_build_object('operation', 'UPDATE',
          'avant', (SELECT value FROM depart), 'apres', 'false'::jsonb),
  '3 : postgres : modifie, et le changement est trace (avant, apres)');

-- 4. Les autres cles
SELECT pg_temp.etre('5e5b0000-0000-0000-0000-000000000001', 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO public.app_config (key, value) VALUES ('sg5b.cle_libre', '1'::jsonb);
UPDATE public.app_config SET value = '2'::jsonb WHERE key = 'sg5b.cle_libre';
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'sg5b.cle_libre') = '2'::jsonb,
  '4 : admin actif : les autres cles restent modifiables');

\o
ROLLBACK;
