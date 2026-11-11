-- HYGIENE-GARDES point 5 (08/11/2026), migration 20261121800000_hygiene_agent_acces_expire.sql.
-- Rouge sans la migration, vert avec :
--   1. un jeton agent dont la personne observee a un acces expire ne recoit
--      plus de session (remettre_session_agent) et ne passe plus le crochet
--      de requete (agent_pre_request) ;
--   2. lecture legitime : avec un acces sans fin, la session est remise et le
--      crochet passe, comme avant.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'HYGIENE-AGENT ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.essai(text) TO agent_ro, service_role;

CREATE FUNCTION pg_temp.agent(p_jeton uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_jeton::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_jeton, 'role', 'agent_ro',
                       'app_metadata', jsonb_build_object('agent_token_id', p_jeton))::text, true);
END $$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('9f000000-0000-4000-8000-000000000001'), ('9f000000-0000-4000-8000-000000000002'),
  ('9f000000-0000-4000-8000-000000000003');
INSERT INTO public.households (id) VALUES
  ('9f000000-0000-4000-8000-0000000000f1'), ('9f000000-0000-4000-8000-0000000000f2');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, access_until) VALUES
  ('9f000000-0000-4000-8000-000000000001', 'HA-ADM', 'admin', NULL, 'Adm', 'Ha', 'active', 'male', NULL),
  ('9f000000-0000-4000-8000-000000000002', 'HA-EXP', 'guardian', '9f000000-0000-4000-8000-0000000000f1', 'Tut', 'Expire', 'active', 'female', now() - interval '1 day'),
  ('9f000000-0000-4000-8000-000000000003', 'HA-OK',  'guardian', '9f000000-0000-4000-8000-0000000000f2', 'Tut', 'Ok',     'active', 'female', NULL);
INSERT INTO public.jetons_agent (id, cree_par, prefixe, empreinte, profil_observe, parcours, expire_le, libelle) VALUES
  ('9f000000-0000-4000-8000-0000000000a1', '9f000000-0000-4000-8000-000000000001', 'hyg1',
   encode(extensions.digest(convert_to('JETON-EXPIRE', 'UTF8'), 'sha256'), 'hex'),
   '9f000000-0000-4000-8000-000000000002', 'guardian', now() + interval '1 hour', 'agent acces expire'),
  ('9f000000-0000-4000-8000-0000000000a2', '9f000000-0000-4000-8000-000000000001', 'hyg2',
   encode(extensions.digest(convert_to('JETON-OK', 'UTF8'), 'sha256'), 'hex'),
   '9f000000-0000-4000-8000-000000000003', 'guardian', now() + interval '1 hour', 'agent acces ouvert');
SET LOCAL session_replication_role = origin;

-- 1. Acces expire.
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT * FROM public.remettre_session_agent('JETON-EXPIRE')$q$) = '28000',
  '1 : acces expire : aucune session remise (jeton refuse)');
RESET ROLE;
SELECT pg_temp.agent('9f000000-0000-4000-8000-0000000000a1');
SET LOCAL ROLE agent_ro;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.agent_pre_request()') = '42501',
  '1 : acces expire : le crochet de requete refuse le jeton');
RESET ROLE;

-- 2. Lecture legitime : acces sans fin.
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT * FROM public.remettre_session_agent('JETON-OK')$q$) IS NULL,
  '2 : acces ouvert : la session est remise');
RESET ROLE;
SELECT pg_temp.agent('9f000000-0000-4000-8000-0000000000a2');
SET LOCAL ROLE agent_ro;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.agent_pre_request()') IS NULL,
  '2 : acces ouvert : le crochet de requete passe');
SELECT pg_temp.vrai(current_setting('request.jwt.claim.sub', true) = '9f000000-0000-4000-8000-000000000003',
  '2 : acces ouvert : auth.uid() devient la personne observee, comme avant');
RESET ROLE;

\o
ROLLBACK;
