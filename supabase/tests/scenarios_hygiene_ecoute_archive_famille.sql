-- HYGIENE-GARDES point 6 (08/11/2026), migration 20261121800100_hygiene_ecoute_archive_famille.sql.
-- Rouge sans la migration, vert avec :
--   1. un comptable dont le profil porte le household_id du foyer (erreur de
--      saisie) n'ecoute plus l'enregistrement d'une seance de ce foyer ;
--   2. lectures legitimes : le tuteur du foyer, l'eleve, l'enseignant de la
--      seance et la direction ecoutent toujours.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'HYGIENE-ECOUTE ROUGE : %', p_label;
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
GRANT EXECUTE ON FUNCTION pg_temp.essai(text) TO authenticated;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated',
                       'app_metadata', jsonb_strip_nulls(jsonb_build_object(
                         'role', p_role, 'household_id', p_foyer)))::text, true);
END $$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('9a100000-0000-4000-8000-000000000001'), ('9a100000-0000-4000-8000-000000000002'),
  ('9a100000-0000-4000-8000-000000000003'), ('9a100000-0000-4000-8000-000000000004'),
  ('9a100000-0000-4000-8000-000000000005');
INSERT INTO public.households (id) VALUES ('9a100000-0000-4000-8000-0000000000f1');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('9a100000-0000-4000-8000-000000000001', 'HE-ENS', 'teacher',    NULL, 'Ens', 'He', 'active', 'female'),
  ('9a100000-0000-4000-8000-000000000002', 'HE-TUT', 'guardian',   '9a100000-0000-4000-8000-0000000000f1', 'Tut', 'He', 'active', 'female'),
  ('9a100000-0000-4000-8000-000000000003', 'HE-ELV', 'student',    '9a100000-0000-4000-8000-0000000000f1', 'Elv', 'He', 'active', 'female'),
  ('9a100000-0000-4000-8000-000000000004', 'HE-CPT', 'accountant', '9a100000-0000-4000-8000-0000000000f1', 'Cpt', 'He', 'active', 'male'),
  ('9a100000-0000-4000-8000-000000000005', 'HE-ADM', 'admin',      NULL, 'Adm', 'He', 'active', 'male');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status) VALUES
  ('9a100000-0000-4000-8000-0000000000c1', '9a100000-0000-4000-8000-000000000001',
   now() - interval '3 hours', now() - interval '2 hours', 'ended');
INSERT INTO public.session_participants (session_id, profile_id, role) VALUES
  ('9a100000-0000-4000-8000-0000000000c1', '9a100000-0000-4000-8000-000000000001', 'teacher'),
  ('9a100000-0000-4000-8000-0000000000c1', '9a100000-0000-4000-8000-000000000003', 'student');
INSERT INTO public.session_recordings (id, session_id, object_key, duration_seconds, size_bytes, expires_at) VALUES
  ('9a100000-0000-4000-8000-0000000000e1', '9a100000-0000-4000-8000-0000000000c1',
   'recordings/hygiene/e1.ogg', 3600, 1000, now() + interval '30 days');
SET LOCAL session_replication_role = origin;

-- 1. Le comptable rattache par erreur au foyer.
SELECT pg_temp.etre('9a100000-0000-4000-8000-000000000004', 'accountant', '9a100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT public.autoriser_ecoute_archive('9a100000-0000-4000-8000-0000000000e1')$q$) = '42501',
  '1 : comptable avec un household_id : ecoute refusee');
RESET ROLE;

-- 2. Lectures legitimes.
SELECT pg_temp.etre('9a100000-0000-4000-8000-000000000002', 'guardian', '9a100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT public.autoriser_ecoute_archive('9a100000-0000-4000-8000-0000000000e1')$q$) IS NULL,
  '2 : tuteur du foyer : ecoute permise');
RESET ROLE;
SELECT pg_temp.etre('9a100000-0000-4000-8000-000000000003', 'student', '9a100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT public.autoriser_ecoute_archive('9a100000-0000-4000-8000-0000000000e1')$q$) IS NULL,
  '2 : eleve du foyer : ecoute permise');
RESET ROLE;
SELECT pg_temp.etre('9a100000-0000-4000-8000-000000000001', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT public.autoriser_ecoute_archive('9a100000-0000-4000-8000-0000000000e1')$q$) IS NULL,
  '2 : enseignant de la seance : ecoute permise');
RESET ROLE;
SELECT pg_temp.etre('9a100000-0000-4000-8000-000000000005', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$SELECT public.autoriser_ecoute_archive('9a100000-0000-4000-8000-0000000000e1')$q$) IS NULL,
  '2 : direction : ecoute permise');
RESET ROLE;

\o
ROLLBACK;
