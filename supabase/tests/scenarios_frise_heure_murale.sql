-- FRISE-HEURE, partie serveur (08/11/2026), migration 20261121700000_frise_heure_murale.sql.
-- Rouge sans la migration (la colonne survenu_le_murale n'existe pas), vert
-- avec. Prouve :
--   1. survenu_le_murale est l'heure murale du foyer, ete comme hiver, pour
--      deux fuseaux differents ;
--   2. survenu_le_foyer reste l'instant UTC de C-28, inchange ;
--   3. la vue garde son filtre : un autre foyer ne lit rien.
-- Fixtures sans declencheurs (session_replication_role = replica) ; tout est
-- annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'FRISE-HEURE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text) TO authenticated;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated',
                       'app_metadata', jsonb_build_object('role', 'guardian', 'household_id', p_foyer))::text, true);
END $$;

DO $garde$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute
                  WHERE attrelid = 'public.demande_evenements_foyer_v'::regclass
                    AND attname = 'survenu_le_murale' AND NOT attisdropped) THEN
    RAISE EXCEPTION 'FRISE-HEURE ROUGE : la vue n''a pas de colonne survenu_le_murale';
  END IF;
END $garde$;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('9e000000-0000-4000-8000-000000000001'), ('9e000000-0000-4000-8000-000000000002'),
  ('9e000000-0000-4000-8000-000000000003'), ('9e000000-0000-4000-8000-000000000004');
INSERT INTO public.households (id, timezone, status) VALUES
  ('9e000000-0000-4000-8000-0000000000f1', 'Europe/Paris', 'active'),
  ('9e000000-0000-4000-8000-0000000000f2', 'Africa/Abidjan', 'active');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('9e000000-0000-4000-8000-000000000001', 'FH-TUT-P', 'guardian', '9e000000-0000-4000-8000-0000000000f1', 'Tut', 'Paris',   'active', 'female'),
  ('9e000000-0000-4000-8000-000000000002', 'FH-ELV-P', 'student',  '9e000000-0000-4000-8000-0000000000f1', 'Elv', 'Paris',   'active', 'male'),
  ('9e000000-0000-4000-8000-000000000003', 'FH-TUT-A', 'guardian', '9e000000-0000-4000-8000-0000000000f2', 'Tut', 'Abidjan', 'active', 'male'),
  ('9e000000-0000-4000-8000-000000000004', 'FH-ELV-A', 'student',  '9e000000-0000-4000-8000-0000000000f2', 'Elv', 'Abidjan', 'active', 'male');
INSERT INTO public.demande_evenements (id, demande_id, eleve_id, household_id, type, survenu_le) VALUES
  -- Paris, heure d'ete (UTC+2) puis heure d'hiver (UTC+1).
  ('9e000000-0000-4000-8000-0000000000e1', '9e000000-0000-4000-8000-0000000000d1', '9e000000-0000-4000-8000-000000000002',
   '9e000000-0000-4000-8000-0000000000f1', 'envoyee', '2026-10-11 06:15:00+00'),
  ('9e000000-0000-4000-8000-0000000000e2', '9e000000-0000-4000-8000-0000000000d1', '9e000000-0000-4000-8000-000000000002',
   '9e000000-0000-4000-8000-0000000000f1', 'classe_creee', '2026-11-02 23:30:00+00'),
  -- Abidjan (UTC+0, sans changement d'heure).
  ('9e000000-0000-4000-8000-0000000000e3', '9e000000-0000-4000-8000-0000000000d2', '9e000000-0000-4000-8000-000000000004',
   '9e000000-0000-4000-8000-0000000000f2', 'envoyee', '2026-10-11 06:15:00+00');
SET LOCAL session_replication_role = origin;

-- 1 et 2. Le tuteur de Paris.
SELECT pg_temp.etre('9e000000-0000-4000-8000-000000000001', '9e000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT survenu_le_murale FROM public.demande_evenements_foyer_v
                      WHERE id = '9e000000-0000-4000-8000-0000000000e1') = '2026-10-11 08:15:00'::timestamp,
  '1 : Paris en heure d''ete : 06:15 UTC se lit 08:15');
SELECT pg_temp.vrai((SELECT survenu_le_murale FROM public.demande_evenements_foyer_v
                      WHERE id = '9e000000-0000-4000-8000-0000000000e2') = '2026-11-03 00:30:00'::timestamp,
  '1 : Paris en heure d''hiver : 23:30 UTC se lit 00:30 le lendemain (le jour change aussi)');
SELECT pg_temp.vrai((SELECT survenu_le_foyer FROM public.demande_evenements_foyer_v
                      WHERE id = '9e000000-0000-4000-8000-0000000000e1') = '2026-10-11 06:15:00+00'::timestamptz,
  '2 : survenu_le_foyer reste l''instant UTC de C-28');
SELECT pg_temp.vrai((SELECT count(*) FROM public.demande_evenements_foyer_v
                      WHERE id = '9e000000-0000-4000-8000-0000000000e3') = 0,
  '3 : le foyer de Paris ne lit pas l''evenement du foyer d''Abidjan');
RESET ROLE;

-- 1. Le tuteur d'Abidjan.
SELECT pg_temp.etre('9e000000-0000-4000-8000-000000000003', '9e000000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT survenu_le_murale FROM public.demande_evenements_foyer_v
                      WHERE id = '9e000000-0000-4000-8000-0000000000e3') = '2026-10-11 06:15:00'::timestamp,
  '1 : Abidjan (UTC+0) : 06:15 UTC se lit 06:15');
SELECT pg_temp.vrai((SELECT count(*) FROM public.demande_evenements_foyer_v) = 1,
  '3 : le foyer d''Abidjan ne lit que son evenement');
RESET ROLE;

-- Droits inchanges.
SELECT pg_temp.vrai(has_table_privilege('authenticated', 'public.demande_evenements_foyer_v', 'SELECT')
                AND NOT has_table_privilege('anon', 'public.demande_evenements_foyer_v', 'SELECT'),
  'droits : authenticated lit, anon non');

\o
ROLLBACK;
