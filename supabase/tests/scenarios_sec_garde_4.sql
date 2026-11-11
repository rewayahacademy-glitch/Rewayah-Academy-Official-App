-- SEC-GARDE-4 (11/11/2026), migration 20261123300000_sec_garde_4_lectures.sql.
-- Rouge sans la migration, vert avec. Preuves demandees par le pilote :
--   1. un admin desactive est refuse sur chacune des trois lectures ;
--   2. un enseignant desactive aussi ;
--   3. temoins : un admin actif et un enseignant actif sont toujours acceptes ;
--   4. etat_dossier (lecture de soi, ecartee) repond encore a un compte
--      desactive : le portail d'attente reste ouvert ;
--   5. droits d'execution inchanges ;
--   6. partie b (20261123300100_sec_garde_4_droits_tables.sql) : aucune table
--      de public ne donne TRUNCATE, REFERENCES ni TRIGGER a anon ou
--      authenticated ; aucune ne donne UPDATE ou l'effacement sans politique ;
--      les gestes permis (disponibilites de l'enseignante) passent toujours.
-- Fixtures sans declencheurs (session_replication_role = replica) ; tout est
-- annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SEC-GARDE-4 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated',
                       'app_metadata', jsonb_strip_nulls(jsonb_build_object(
                         'role', p_role, 'household_id', p_foyer)))::text, true);
END $$;

-- Vrai si la position de la classe est refusee (42501).
-- Vrai si vider la table est refuse (42501).
CREATE FUNCTION pg_temp.vider_refuse() RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  TRUNCATE public.weekly_availability;
  RETURN false;
EXCEPTION WHEN insufficient_privilege THEN
  RETURN true;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vider_refuse() TO authenticated;

CREATE FUNCTION pg_temp.position_refusee(p_groupe uuid) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.derniere_position_groupe(p_groupe);
  RETURN false;
EXCEPTION WHEN insufficient_privilege THEN
  RETURN true;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.position_refusee(uuid) TO authenticated;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('5e400000-0000-0000-0000-000000000001'), ('5e400000-0000-0000-0000-000000000002'),
  ('5e400000-0000-0000-0000-000000000003'), ('5e400000-0000-0000-0000-000000000004'),
  ('5e400000-0000-0000-0000-000000000005');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('5e400000-0000-0000-0000-000000000001', 'SG4-ADM-OFF', 'admin',   NULL, 'Adm', 'Off', 'disabled', 'male'),
  ('5e400000-0000-0000-0000-000000000002', 'SG4-ADM-ON',  'admin',   NULL, 'Adm', 'On',  'active',   'male'),
  ('5e400000-0000-0000-0000-000000000003', 'SG4-ENS-OFF', 'teacher', NULL, 'Ens', 'Off', 'disabled', 'female'),
  ('5e400000-0000-0000-0000-000000000004', 'SG4-ENS-ON',  'teacher', NULL, 'Ens', 'On',  'active',   'female'),
  ('5e400000-0000-0000-0000-000000000005', 'SG4-ENS-OFF2','teacher', NULL, 'Ens', 'Off2','disabled', 'female');
-- Deux classes : g1 a l'enseignante desactivee, g2 a l'enseignante active.
INSERT INTO public.groupes (id, type_public, seuil_max, libelle, weekday, hour_local, teacher_id) VALUES
  ('5e400000-0000-0000-0000-0000000000a1', 'enfant', 6, 'Classe un', 1, 10, '5e400000-0000-0000-0000-000000000003'),
  ('5e400000-0000-0000-0000-0000000000a2', 'enfant', 6, 'Classe deux', 2, 10, '5e400000-0000-0000-0000-000000000004');
INSERT INTO public.sessions (id, groupe_id, teacher_id, started_at, ended_at) VALUES
  ('5e400000-0000-0000-0000-0000000000b1', '5e400000-0000-0000-0000-0000000000a1',
   '5e400000-0000-0000-0000-000000000003', now() - interval '2 hours', now() - interval '1 hour'),
  ('5e400000-0000-0000-0000-0000000000b2', '5e400000-0000-0000-0000-0000000000a2',
   '5e400000-0000-0000-0000-000000000004', now() - interval '2 hours', now() - interval '1 hour');
INSERT INTO public.session_shared_content (session_id, resource_id, content_position, display_mode, revision, updated_by, group_resume_position) VALUES
  ('5e400000-0000-0000-0000-0000000000b1', gen_random_uuid(), '{}'::jsonb, 'page', 0,
   '5e400000-0000-0000-0000-000000000003', '{"page": 4}'::jsonb),
  ('5e400000-0000-0000-0000-0000000000b2', gen_random_uuid(), '{}'::jsonb, 'page', 0,
   '5e400000-0000-0000-0000-000000000004', '{"page": 7}'::jsonb);
-- Une visite d'observation faite par chaque admin sur s2.
INSERT INTO public.guardian_session_visit (session_id, groupe_id, observateur_profile_id, role, visit_number, policy_version) VALUES
  ('5e400000-0000-0000-0000-0000000000b2', '5e400000-0000-0000-0000-0000000000a2',
   '5e400000-0000-0000-0000-000000000001', 'admin_visible', 1, 'v1'),
  ('5e400000-0000-0000-0000-0000000000b2', '5e400000-0000-0000-0000-0000000000a2',
   '5e400000-0000-0000-0000-000000000002', 'admin_visible', 1, 'v1');
SET LOCAL session_replication_role = origin;

-- ------------------------------------------------------------------
-- 1. Admin desactive : refuse sur chacune
-- ------------------------------------------------------------------
SELECT pg_temp.etre('5e400000-0000-0000-0000-000000000001', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT public.app_account_valid(), '1 : le compte de l''admin est bien desactive');
SELECT pg_temp.vrai(pg_temp.position_refusee('5e400000-0000-0000-0000-0000000000a2'),
  '1 : admin desactive : derniere_position_groupe refuse (42501)');
SELECT pg_temp.vrai(public.visites_observation('5e400000-0000-0000-0000-0000000000b2') = '[]'::jsonb,
  '1 : admin desactive : visites_observation rend la liste vide, meme sa propre visite');
SELECT pg_temp.vrai(NOT public.peut_poser_disponibilite('5e400000-0000-0000-0000-000000000001'),
  '1 : admin desactive : peut_poser_disponibilite rend faux');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Enseignant desactive : refuse sur chacune
-- ------------------------------------------------------------------
SELECT pg_temp.etre('5e400000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.position_refusee('5e400000-0000-0000-0000-0000000000a1'),
  '2 : enseignant desactive : derniere_position_groupe de sa propre classe refuse');
SELECT pg_temp.vrai(public.visites_observation('5e400000-0000-0000-0000-0000000000b1') = '[]'::jsonb,
  '2 : enseignant desactive : visites_observation vide');
SELECT pg_temp.vrai(NOT public.peut_poser_disponibilite('5e400000-0000-0000-0000-000000000003'),
  '2 : enseignant desactive : ne pose plus ses propres disponibilites');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Temoins : comptes actifs toujours acceptes
-- ------------------------------------------------------------------
SELECT pg_temp.etre('5e400000-0000-0000-0000-000000000002', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.derniere_position_groupe('5e400000-0000-0000-0000-0000000000a1') = '{"page": 4}'::jsonb,
  '3 : admin actif : lit la position de la classe');
SELECT pg_temp.vrai(jsonb_array_length(public.visites_observation('5e400000-0000-0000-0000-0000000000b2')) = 2,
  '3 : admin actif : lit les deux visites de la seance');
RESET ROLE;

SELECT pg_temp.etre('5e400000-0000-0000-0000-000000000004', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.derniere_position_groupe('5e400000-0000-0000-0000-0000000000a2') = '{"page": 7}'::jsonb,
  '3 : enseignant actif : lit la position de sa classe');
SELECT pg_temp.vrai(pg_temp.position_refusee('5e400000-0000-0000-0000-0000000000a1'),
  '3 : enseignant actif : toujours refuse sur la classe d''un autre');
SELECT pg_temp.vrai(public.peut_poser_disponibilite('5e400000-0000-0000-0000-000000000004'),
  '3 : enseignant actif : pose ses disponibilites');
SELECT pg_temp.vrai(NOT public.peut_poser_disponibilite('5e400000-0000-0000-0000-000000000005'),
  '3 : enseignant actif : ne pose pas celles d''un autre');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Lecture de soi ecartee : le portail d'attente reste ouvert
-- ------------------------------------------------------------------
SELECT pg_temp.etre('5e400000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.etat_dossier() ->> 'statut' = 'disabled',
  '4 : un compte desactive lit encore l''etat de son propre dossier');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. Droits inchanges
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.derniere_position_groupe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.visites_observation(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.peut_poser_disponibilite(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.derniere_position_groupe(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.visites_observation(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.peut_poser_disponibilite(uuid)', 'EXECUTE'),
  '5 : droits : authenticated seul, comme avant');

-- ------------------------------------------------------------------
-- 6. Partie b : droits de table
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace,
           LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
     WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p')
       AND a.grantee IN ('anon'::regrole, 'authenticated'::regrole)
       AND a.privilege_type IN ('TRUNCATE', 'REFERENCES', 'TRIGGER')),
  '6 : aucune table de public ne donne TRUNCATE, REFERENCES ni TRIGGER a anon ou authenticated');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace,
           LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
     WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p')
       AND a.grantee IN ('anon'::regrole, 'authenticated'::regrole)
       AND ((a.privilege_type = 'UPDATE' AND NOT EXISTS (
               SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polcmd IN ('w', '*')))
         OR (a.privilege_type = 'DELETE' AND NOT EXISTS (
               SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polcmd IN ('d', '*'))))),
  '6 : aucune table ne donne UPDATE ou l''effacement sans politique pour la commande');

SELECT pg_temp.etre('5e400000-0000-0000-0000-000000000004', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.vider_refuse(), '6 : un compte connecte ne peut pas vider une table');
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local)
  VALUES ('5e400000-0000-0000-0000-000000000004', 3, 9);
SELECT pg_temp.vrai((SELECT count(*) FROM public.weekly_availability
                      WHERE profile_id = '5e400000-0000-0000-0000-000000000004') = 1,
  '6 : geste permis : l''enseignante active pose une disponibilite');
DELETE FROM public.weekly_availability
 WHERE profile_id = '5e400000-0000-0000-0000-000000000004';
SELECT pg_temp.vrai((SELECT count(*) FROM public.weekly_availability
                      WHERE profile_id = '5e400000-0000-0000-0000-000000000004') = 0,
  '6 : geste permis : elle la retire');
RESET ROLE;

\o
ROLLBACK;
