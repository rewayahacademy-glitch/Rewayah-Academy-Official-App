-- V2-e (20261109600000) : fondateurs_personnel(). Prouve :
--   1. la direction active (femme, homme, super-admin) lit toutes les coches
--      vraies, des deux cotes, et seulement les vraies ;
--   2. une enseignante, une direction desactivee, et anon ne lisent rien ;
--   3. la lecture suit poser_fondateur (cocher, decocher).
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier (ROLLBACK).
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.en_tant_que(p_qui text, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('app_metadata',
  pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_qui, true);
  PERFORM set_config('test.uid', p_qui, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.en_tant_que(text, text) TO authenticated;

INSERT INTO auth.users (id, email) VALUES
 ('7e300000-0000-4000-8000-0000000000a1', 'v2e-a1@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000b1', 'v2e-h1@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000a9', 'v2e-off@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000d1', 'v2e-t1@test.invalid'),
 ('7e300000-0000-4000-8000-0000000000d2', 'v2e-t2@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7e300000-0000-4000-8000-0000000000a1', 'RA-26-7301', 'admin', NULL, 'Amina', 'V2e', 'active', 'female'),
 ('7e300000-0000-4000-8000-0000000000b1', 'RA-26-7302', 'admin', NULL, 'Bilal', 'V2e', 'active', 'male'),
 ('7e300000-0000-4000-8000-0000000000a9', 'RA-26-7303', 'admin', NULL, 'Asma', 'V2e', 'disabled', 'female'),
 ('7e300000-0000-4000-8000-0000000000d1', 'RA-26-7304', 'teacher', NULL, 'Yusuf', 'V2e', 'provisional_active', 'male'),
 ('7e300000-0000-4000-8000-0000000000d2', 'RA-26-7305', 'teacher', NULL, 'Hafsa', 'V2e', 'provisional_active', 'female');
-- Une coche vraie de chaque cote, une fausse.
INSERT INTO public.personnel_fondateurs (profile_id, fondateur, modifie_par) VALUES
 ('7e300000-0000-4000-8000-0000000000a1', true, '7e300000-0000-4000-8000-0000000000a1'),
 ('7e300000-0000-4000-8000-0000000000b1', true, '7e300000-0000-4000-8000-0000000000a1'),
 ('7e300000-0000-4000-8000-0000000000d1', false, '7e300000-0000-4000-8000-0000000000a1');

SET LOCAL ROLE authenticated;
DO $lire$
DECLARE
  v_ids uuid[];
BEGIN
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000a1', 'admin');
  SELECT pg_catalog.array_agg(x ORDER BY x) INTO v_ids
    FROM public.fondateurs_personnel() x WHERE x::text LIKE '7e300000-%';
  PERFORM pg_temp.vrai(v_ids = ARRAY['7e300000-0000-4000-8000-0000000000a1',
                                     '7e300000-0000-4000-8000-0000000000b1']::uuid[],
    '1. la direction femme lit les coches vraies des deux cotes, pas la fausse : ' || coalesce(v_ids::text, 'aucune'));
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000b1', 'admin');
  SELECT pg_catalog.array_agg(x ORDER BY x) INTO v_ids
    FROM public.fondateurs_personnel() x WHERE x::text LIKE '7e300000-%';
  PERFORM pg_temp.vrai(pg_catalog.cardinality(v_ids) = 2, '1. la direction homme lit les memes coches');

  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000d2', 'teacher');
  BEGIN
    PERFORM public.fondateurs_personnel();
    RAISE EXCEPTION 'ROUGE : 2. une enseignante a lu les coches';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 2. une enseignante ne lit pas les coches';
  END;
  PERFORM pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000a9', 'admin');
  BEGIN
    PERFORM public.fondateurs_personnel();
    RAISE EXCEPTION 'ROUGE : 2. une direction desactivee a lu les coches';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK 2. une direction desactivee ne lit pas les coches';
  END;
END
$lire$;
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.fondateurs_personnel()', 'EXECUTE'),
  '2. anon n''execute pas la lecture');

-- 3. La lecture suit la coche (directement en base : poser_fondateur exige un
-- personnel actif, prouve par scenarios_v1_entretiens.sql).
UPDATE public.personnel_fondateurs SET fondateur = false WHERE profile_id = '7e300000-0000-4000-8000-0000000000b1';
UPDATE public.personnel_fondateurs SET fondateur = true WHERE profile_id = '7e300000-0000-4000-8000-0000000000d1';
SET LOCAL ROLE authenticated;
SELECT pg_temp.en_tant_que('7e300000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(x ORDER BY x) FROM public.fondateurs_personnel() x WHERE x::text LIKE '7e300000-%')
  = ARRAY['7e300000-0000-4000-8000-0000000000a1', '7e300000-0000-4000-8000-0000000000d1']::uuid[],
  '3. decocher et cocher : la lecture suit');
RESET ROLE;

ROLLBACK;
