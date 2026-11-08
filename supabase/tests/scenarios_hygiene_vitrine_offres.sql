-- HYGIENE-GARDES point 7 (08/11/2026), migration 20261121800200_hygiene_vitrine_offres.sql.
-- Rouge sans la migration, vert avec :
--   1. un controleur desactive et un admin desactive ne lisent plus les
--      offres en brouillon ;
--   2. lectures legitimes : un admin actif lit le brouillon ; une famille en
--      pending_kyc lit toujours l'offre publiee (et pas le brouillon) ; un
--      compte desactive lit toujours l'offre publiee (branche inchangee).
-- Fixtures sans declencheurs (session_replication_role = replica) ; tout est
-- annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'HYGIENE-VITRINE ROUGE : %', p_label;
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

CREATE FUNCTION pg_temp.voit(p_etat text) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.offres_horaires
   WHERE id IN ('9a200000-0000-4000-8000-0000000000b1', '9a200000-0000-4000-8000-0000000000b2')
     AND etat = p_etat
$$;
GRANT EXECUTE ON FUNCTION pg_temp.voit(text) TO authenticated;

SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id) VALUES
  ('9a200000-0000-4000-8000-000000000001'), ('9a200000-0000-4000-8000-000000000002'),
  ('9a200000-0000-4000-8000-000000000003'), ('9a200000-0000-4000-8000-000000000004');
INSERT INTO public.households (id) VALUES ('9a200000-0000-4000-8000-0000000000f1');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('9a200000-0000-4000-8000-000000000001', 'HV-CTL-OFF', 'controller', NULL, 'Ctl', 'Off', 'disabled',    'male'),
  ('9a200000-0000-4000-8000-000000000002', 'HV-ADM-OFF', 'admin',      NULL, 'Adm', 'Off', 'disabled',    'male'),
  ('9a200000-0000-4000-8000-000000000003', 'HV-ADM-ON',  'admin',      NULL, 'Adm', 'On',  'active',      'male'),
  ('9a200000-0000-4000-8000-000000000004', 'HV-TUT-KYC', 'guardian',   '9a200000-0000-4000-8000-0000000000f1', 'Tut', 'Kyc', 'pending_kyc', 'female');
INSERT INTO public.offres_horaires (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, publiee_at, publiee_par) VALUES
  ('9a200000-0000-4000-8000-0000000000b1', 'enfant', 'fr', 'Europe/Paris', ARRAY[1]::smallint[], 18, 60, 'publiee',
   now(), '9a200000-0000-4000-8000-000000000003'),
  ('9a200000-0000-4000-8000-0000000000b2', 'enfant', 'fr', 'Europe/Paris', ARRAY[2]::smallint[], 18, 60, 'brouillon',
   NULL, NULL);
SET LOCAL session_replication_role = origin;

-- 1. Comptes desactives de la direction et du controle.
SELECT pg_temp.etre('9a200000-0000-4000-8000-000000000001', 'controller', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.voit('brouillon') = 0, '1 : controleur desactive : aucune offre en brouillon');
SELECT pg_temp.vrai(pg_temp.voit('publiee') = 1, '2 : controleur desactive : l''offre publiee reste lisible (branche inchangee)');
RESET ROLE;
SELECT pg_temp.etre('9a200000-0000-4000-8000-000000000002', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.voit('brouillon') = 0, '1 : admin desactive : aucune offre en brouillon');
RESET ROLE;

-- 2. Lectures legitimes.
SELECT pg_temp.etre('9a200000-0000-4000-8000-000000000003', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.voit('brouillon') = 1 AND pg_temp.voit('publiee') = 1,
  '2 : admin actif : lit le brouillon et l''offre publiee');
RESET ROLE;
SELECT pg_temp.etre('9a200000-0000-4000-8000-000000000004', 'guardian', '9a200000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.voit('publiee') = 1, '2 : famille en pending_kyc : lit toujours l''offre publiee');
SELECT pg_temp.vrai(pg_temp.voit('brouillon') = 0, '2 : famille en pending_kyc : ne lit pas le brouillon');
RESET ROLE;

\o
ROLLBACK;
