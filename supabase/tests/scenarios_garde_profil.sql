-- GARDE-PROFIL (04/11/2026 ; migration 20261110000000) : la garde des
-- colonnes de `profiles`, jouee sous `authenticated` comme un client.
--
--   A. l'eleve mineur, sur sa propre ligne : first_name, last_name,
--      created_at, deleted_at (se retirer soi-meme) et immutable_id refuses ;
--      langue_communication reste libre (decision du pilote, 04/11) ;
--   B. l'adulte (tuteur, eleve adulte) : first_name, last_name et
--      langue_communication acceptes ; created_at et deleted_at refuses ;
--   C. le tuteur qui renomme son enfant en direct : refuse (aucune ligne) ;
--   D. la direction (aal2) renomme l'enfant (accepte), le retire par
--      SUPPRIMER (direction_supprimer_comptes) puis le restaure
--      (direction_restaurer_comptes) ; l'anonymisation efface le nom ;
--   E. service_role et postgres passent toujours.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR (p_message IS NOT NULL AND SQLERRM <> p_message) THEN
      RAISE EXCEPTION 'ROUGE : % (% « % » au lieu de % « % »)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('9a7d0000-0000-4000-8000-' || pg_catalog.lpad(p, 12, '0'))::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated', 'aal', p_aal,
  'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

-- Lecture sans RLS (fonction des tests, executee en postgres).
CREATE FUNCTION pg_temp.champ(p_id uuid, p_col text) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v text;
BEGIN
  EXECUTE pg_catalog.format('SELECT %I::text FROM public.profiles WHERE id = $1', p_col) INTO v USING p_id;
  RETURN coalesce(v, '∅');
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text, text),
  pg_temp.qui(uuid, text, text), pg_temp.u(text), pg_temp.champ(uuid, text) TO authenticated, anon, service_role;

-- ------------------------------------------------------------------
-- Fixtures : un foyer H (tuteur P, enfants E et E2, mineurs) ; un eleve
-- adulte A dans son propre foyer H2 ; la direction D.
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  (pg_temp.u('1'), 'gp-tuteur@example.test'), (pg_temp.u('2'), 'gp-enfant@example.test'),
  (pg_temp.u('3'), 'gp-enfant2@example.test'), (pg_temp.u('4'), 'gp-adulte@example.test'),
  (pg_temp.u('9'), 'gp-direction@example.test');
INSERT INTO public.households (id, timezone) VALUES
  (pg_temp.u('101'), 'Europe/Paris'), (pg_temp.u('102'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, gender, account_status) VALUES
  (pg_temp.u('1'), 'GP-P', 'guardian', pg_temp.u('101'), 'Samira', 'Garde', 'female', 'active'),
  (pg_temp.u('2'), 'GP-E', 'student', pg_temp.u('101'), 'Hakim', 'Garde', 'male', 'active'),
  (pg_temp.u('3'), 'GP-E2', 'student', pg_temp.u('101'), 'Yasmine', 'Garde', 'female', 'active'),
  (pg_temp.u('4'), 'GP-A', 'student', pg_temp.u('102'), 'Nadia', 'Adulte', 'female', 'active'),
  (pg_temp.u('9'), 'GP-D', 'admin', NULL, 'Direction', 'Garde', 'male', 'active');
UPDATE public.households SET primary_guardian_id = pg_temp.u('1') WHERE id = pg_temp.u('101');
UPDATE public.households SET primary_guardian_id = pg_temp.u('4') WHERE id = pg_temp.u('102');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  (pg_temp.u('2'), 'minor', 'standard'),
  (pg_temp.u('3'), 'minor', 'child'),
  (pg_temp.u('4'), 'autonomous', 'standard');

-- ------------------------------------------------------------------
-- A. L'eleve mineur, sur sa propre ligne (hors Interface guidee, puis en
--    Interface guidee : la regle est la meme)
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('2'), 'student');
SELECT pg_temp.vrai(public.photo_adulte_moi() IS FALSE, 'A0 : le serveur dit que l''enfant n''est pas adulte');
SELECT pg_temp.refus($q$UPDATE public.profiles SET first_name = 'Pirate' WHERE id = pg_temp.u('2')$q$,
  '42501', 'le nom d''un eleve mineur se change par l''academie', 'A1 : l''enfant ne change pas son prenom');
SELECT pg_temp.refus($q$UPDATE public.profiles SET last_name = 'Pirate' WHERE id = pg_temp.u('2')$q$,
  '42501', 'le nom d''un eleve mineur se change par l''academie', 'A2 : l''enfant ne change pas son nom');
SELECT pg_temp.refus($q$UPDATE public.profiles SET created_at = '2020-01-01' WHERE id = pg_temp.u('2')$q$,
  '42501', 'seule la direction retire un compte, ou change sa date de creation ou son matricule',
  'A3 : l''enfant ne change pas sa date de creation');
SELECT pg_temp.refus($q$UPDATE public.profiles SET deleted_at = now() WHERE id = pg_temp.u('2')$q$,
  '42501', NULL, 'A4 : l''enfant ne se retire pas lui-meme');
SELECT pg_temp.refus($q$UPDATE public.profiles SET immutable_id = 'GP-X' WHERE id = pg_temp.u('2')$q$,
  'P0001', 'immutable_id ne peut pas être modifié', 'A5 : l''enfant ne change pas son matricule');
UPDATE public.profiles SET langue_communication = 'ar' WHERE id = pg_temp.u('2');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'langue_communication') = 'ar',
  'A6 : la langue reste libre (ecran officiel, decision du pilote)');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'first_name') = 'Hakim'
  AND pg_temp.champ(pg_temp.u('2'), 'last_name') = 'Garde'
  AND pg_temp.champ(pg_temp.u('2'), 'deleted_at') = '∅', 'A7 : la ligne de l''enfant est intacte');

SELECT pg_temp.qui(pg_temp.u('3'), 'student');
SELECT pg_temp.refus($q$UPDATE public.profiles SET first_name = 'Pirate' WHERE id = pg_temp.u('3')$q$,
  '42501', 'le nom d''un eleve mineur se change par l''academie', 'A8 : en Interface guidee aussi');

-- ------------------------------------------------------------------
-- B. Les adultes, sur leur propre ligne
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('1'), 'guardian');
UPDATE public.profiles SET first_name = 'Samia', last_name = 'Gardee', langue_communication = 'ar'
 WHERE id = pg_temp.u('1');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('1'), 'first_name') = 'Samia'
  AND pg_temp.champ(pg_temp.u('1'), 'last_name') = 'Gardee'
  AND pg_temp.champ(pg_temp.u('1'), 'langue_communication') = 'ar',
  'B1 : le tuteur change son prenom, son nom et sa langue');
SELECT pg_temp.refus($q$UPDATE public.profiles SET created_at = '2020-01-01' WHERE id = pg_temp.u('1')$q$,
  '42501', 'seule la direction retire un compte, ou change sa date de creation ou son matricule',
  'B2 : le tuteur ne change pas sa date de creation');
SELECT pg_temp.refus($q$UPDATE public.profiles SET deleted_at = now() WHERE id = pg_temp.u('1')$q$,
  '42501', NULL, 'B3 : le tuteur ne se retire pas lui-meme');

SELECT pg_temp.qui(pg_temp.u('4'), 'student');
SELECT pg_temp.vrai(public.photo_adulte_moi() IS TRUE, 'B4 : le serveur dit que l''eleve adulte est adulte');
UPDATE public.profiles SET first_name = 'Nadira', langue_communication = 'ar' WHERE id = pg_temp.u('4');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('4'), 'first_name') = 'Nadira'
  AND pg_temp.champ(pg_temp.u('4'), 'langue_communication') = 'ar',
  'B5 : l''eleve adulte change son prenom et sa langue');

-- ------------------------------------------------------------------
-- C. Le tuteur ne renomme pas son enfant en direct
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('1'), 'guardian');
UPDATE public.profiles SET first_name = 'Renomme' WHERE id = pg_temp.u('2');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'first_name') = 'Hakim',
  'C1 : le tuteur ne renomme pas son enfant en direct (aucune ligne touchee)');

-- ------------------------------------------------------------------
-- D. La direction : renommer, SUPPRIMER, restaurer, anonymiser
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('9'), 'admin', 'aal2');
UPDATE public.profiles SET first_name = 'Hakime' WHERE id = pg_temp.u('2');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'first_name') = 'Hakime',
  'D1 : la direction renomme l''enfant');
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('2')]);
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'deleted_at') <> '∅',
  'D2 : SUPPRIMER de la direction retire le compte de l''enfant');
SELECT public.direction_restaurer_comptes(ARRAY[pg_temp.u('2')]);
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'deleted_at') = '∅',
  'D3 : la direction restaure le compte');
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('3')], NULL, true);
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('3'), 'deleted_at') <> '∅'
  AND pg_temp.champ(pg_temp.u('3'), 'first_name') <> 'Yasmine',
  'D4 : l''anonymisation retire le compte et efface le nom');

-- ------------------------------------------------------------------
-- E. service_role et postgres passent toujours
-- ------------------------------------------------------------------
RESET ROLE;
SET LOCAL ROLE service_role;
UPDATE public.profiles SET first_name = 'Service', created_at = '2021-01-01' WHERE id = pg_temp.u('2');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'first_name') = 'Service',
  'E1 : service_role change le nom et la date de creation');
RESET ROLE;
UPDATE public.profiles SET last_name = 'Postgres' WHERE id = pg_temp.u('2');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'last_name') = 'Postgres', 'E2 : postgres passe');

ROLLBACK;
