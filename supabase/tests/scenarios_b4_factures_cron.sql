-- B4 (31/10/2026) : emission planifiee des factures et relances quotidiennes.
-- Migration 20261102600000_b4_factures_et_relances_planifiees.sql.
-- A rejouer sur une base NEUVE (stub_auth.sql puis toutes les migrations) :
-- fixtures inserees puis annulees. Prouve :
--   1. la planification ne leve aucune erreur sans pg_cron (le bloc de la
--      migration est rejoue ici) et ne laisse aucune tache ;
--   2. les fonctions du job n'ont aucun droit client ; la porte publique
--      `emettre_factures_mois` refuse toujours un enseignant ;
--   3. le job n'emet rien hors des jours prevus (milieu de mois) ;
--   4. le 1er, il emet le mois courant ; un second passage n'emet rien de plus
--      (une facture par eleve et par mois) ; la porte publique non plus ;
--   5. a l'entree dans la plus grande avance de relance de la politique du
--      mois suivant, il emet le mois suivant une seule fois, et la relance de
--      ce jour-la trouve la facture.
-- Le scenario calcule ses dates a partir du jour : il ne depend pas de la date
-- a laquelle il tourne.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Le mois courant et le suivant dans le fuseau comptable, et le nombre de
-- factures du foyer de test.
CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT private.fac_mois_courant() $$;
CREATE FUNCTION pg_temp.suivant() RETURNS date LANGUAGE sql AS
  $$ SELECT (pg_temp.mois() + interval '1 month')::date $$;
CREATE FUNCTION pg_temp.nb(p_mois date) RETURNS bigint LANGUAGE sql AS
  $$ SELECT count(*) FROM public.factures_mensuelles
      WHERE household_id = 'b4000000-0000-4000-8000-0000000000f1' AND mois = p_mois AND statut <> 'annulee' $$;
-- La plus grande avance de relance de la politique du mois suivant (nulle si aucune).
CREATE FUNCTION pg_temp.avance() RETURNS integer LANGUAGE sql AS
  $$ SELECT max(j) FROM unnest((private.fac_politique_au(pg_temp.suivant())).jours_relance) AS j $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- 1. Planification sans pg_cron
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'),
  'base nue : pg_cron absente');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron'),
  'planification : aucune tache posee sans pg_cron');
-- Le bloc de la migration, rejoue tel quel : aucune erreur.
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$SELECT cron.schedule('fac-emission-factures', '45 4 * * *',
      'SELECT private.fac_emission_planifiee(private.fac_aujourdhui())')$cron$;
    EXECUTE $cron$SELECT cron.schedule('fac-relances-quotidiennes', '15 5 * * *',
      'SELECT private.fac_traiter_relances(private.fac_aujourdhui())')$cron$;
  ELSE
    RAISE NOTICE 'B4 : pg_cron absente, rien n''est planifie';
  END IF;
END;
$planification$;
SELECT pg_temp.vrai(true, 'planification : le bloc se rejoue sans erreur sans pg_cron');

-- ------------------------------------------------------------------
-- 2. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.fac_emission_planifiee(date)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.fac_emission_planifiee(date)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'private.fac_emission_planifiee(date)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.fac_emettre_factures_du_mois(date,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.fac_emettre_factures_du_mois(date,uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.emettre_factures_mois(date)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.emettre_factures_mois(date)', 'EXECUTE'),
  'droits : le job sans droit client, la porte publique a authenticated seulement');
SELECT pg_temp.vrai(coalesce(obj_description('public.emettre_factures_mois(date)'::regprocedure, 'pg_proc'), '')
    LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.emettre_factures_mois(date)'::regprocedure)) || '%',
  'droits : ligne F86 de emettre_factures_mois a jour de son corps');

-- ------------------------------------------------------------------
-- Fixtures : un foyer, un tuteur, une eleve sortie de l'essai le mois dernier,
-- une classe avec deux seances le mois courant et deux le suivant.
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('b4000000-0000-4000-8000-0000000000a1','b4-admin@test.invalid'),
 ('b4000000-0000-4000-8000-0000000000b1','b4-ens@test.invalid'),
 ('b4000000-0000-4000-8000-0000000000d1','b4-tit@test.invalid'),
 ('b4000000-0000-4000-8000-0000000000e1','b4-e1@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('b4000000-0000-4000-8000-0000000000f1','America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('b4000000-0000-4000-8000-0000000000a1','B4-ADM-0001','admin',NULL,'Direction','B4','active','female'),
 ('b4000000-0000-4000-8000-0000000000b1','B4-ENS-0001','teacher',NULL,'Maryam','B4','provisional_active','female'),
 ('b4000000-0000-4000-8000-0000000000d1','B4-TUT-0001','guardian','b4000000-0000-4000-8000-0000000000f1','Amina','B4','active','female'),
 ('b4000000-0000-4000-8000-0000000000e1','B4-ELV-0001','student','b4000000-0000-4000-8000-0000000000f1','Yasmine','B4','active','female');
UPDATE public.households SET primary_guardian_id = 'b4000000-0000-4000-8000-0000000000d1'
 WHERE id = 'b4000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('b4000000-0000-4000-8000-0000000000e1','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('b4000000-0000-4000-8000-000000000c01','b4000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour B4',1,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('b4000000-0000-4000-8000-000000000c01','b4000000-0000-4000-8000-0000000000e1', pg_temp.mois() - interval '20 days');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT s.id::uuid, 'b4000000-0000-4000-8000-0000000000b1', s.debut, s.debut + interval '1 hour',
       s.statut::public.session_status, 'b4000000-0000-4000-8000-000000000c01'
  FROM (VALUES
    ('b4000000-0000-4000-8000-000000000501', pg_temp.mois() - interval '10 days' + interval '15 hours', 'ended'),
    ('b4000000-0000-4000-8000-000000000502', pg_temp.mois() - interval '5 days' + interval '15 hours', 'ended'),
    ('b4000000-0000-4000-8000-000000000503', pg_temp.mois() + interval '1 day 15 hours', 'planned'),
    ('b4000000-0000-4000-8000-000000000504', pg_temp.mois() + interval '8 days 15 hours', 'planned'),
    ('b4000000-0000-4000-8000-000000000505', pg_temp.suivant() + interval '1 day 15 hours', 'planned'),
    ('b4000000-0000-4000-8000-000000000506', pg_temp.suivant() + interval '8 days 15 hours', 'planned')) AS s(id, debut, statut);
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('b4000000-0000-4000-8000-000000000501','b4000000-0000-4000-8000-0000000000e1','student'),
 ('b4000000-0000-4000-8000-000000000502','b4000000-0000-4000-8000-0000000000e1','student');

-- ------------------------------------------------------------------
-- 3. Milieu de mois : rien
-- ------------------------------------------------------------------
SELECT set_config('test.r', private.fac_emission_planifiee(pg_temp.mois() + 10)::text, true);
SELECT pg_temp.vrai(jsonb_array_length(current_setting('test.r')::jsonb -> 'emissions') = 0
  AND pg_temp.nb(pg_temp.mois()) = 0 AND pg_temp.nb(pg_temp.suivant()) = 0,
  'milieu de mois : le job n''emet rien');

-- ------------------------------------------------------------------
-- 4. Le 1er : le mois courant, une seule fois
-- ------------------------------------------------------------------
SELECT set_config('test.r', private.fac_emission_planifiee(pg_temp.mois())::text, true);
SELECT pg_temp.vrai((current_setting('test.r')::jsonb #>> '{emissions,0,mois}') = to_char(pg_temp.mois(), 'YYYY-MM-DD')
  AND (current_setting('test.r')::jsonb #>> '{emissions,0,emises}')::int >= 1
  AND pg_temp.nb(pg_temp.mois()) = 1,
  'le 1er : la facture du mois courant est emise');
SELECT pg_temp.vrai((SELECT emise_par IS NULL AND total_mineur > 0
                       AND politique_version = (private.fac_politique_au(pg_temp.mois())).version
                       FROM public.factures_mensuelles
                      WHERE household_id = 'b4000000-0000-4000-8000-0000000000f1' AND mois = pg_temp.mois()),
  'le 1er : emise par le job, montant lu dans la politique du mois');
SELECT set_config('test.r', private.fac_emission_planifiee(pg_temp.mois())::text, true);
SELECT pg_temp.vrai((current_setting('test.r')::jsonb #>> '{emissions,0,emises}')::int = 0
  AND pg_temp.nb(pg_temp.mois()) = 1,
  'le 1er, second passage : rien de plus (idempotente)');
SELECT private.fac_emission_planifiee(pg_temp.mois() + 1);
SELECT pg_temp.vrai(pg_temp.nb(pg_temp.mois()) = 1, 'le 2 : rattrapage sans doublon');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('b4000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois(date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date)$q$, '42501',
  'porte publique : enseignant refuse');
SELECT pg_temp.qui('b4000000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.r', public.emettre_factures_mois(
  date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date)::text, true);
RESET ROLE;
SELECT pg_temp.vrai((current_setting('test.r')::jsonb ->> 'emises')::int = 0
  AND pg_temp.nb(pg_temp.mois()) = 1,
  'porte publique apres le job : rien de plus');

-- ------------------------------------------------------------------
-- 5. Le mois suivant, a l'avance de relance de sa politique
-- ------------------------------------------------------------------
DO $suivant$
DECLARE
  v_avance integer := pg_temp.avance();
  v_r jsonb;
BEGIN
  IF v_avance IS NULL OR v_avance <= 0 THEN
    v_r := private.fac_emission_planifiee(pg_temp.suivant() - 1);
    PERFORM pg_temp.vrai(pg_temp.nb(pg_temp.suivant()) = 0,
      'mois suivant : politique sans relance, rien avant le 1er');
    RETURN;
  END IF;
  v_r := private.fac_emission_planifiee(pg_temp.suivant() - v_avance - 1);
  PERFORM pg_temp.vrai(pg_temp.nb(pg_temp.suivant()) = 0,
    'mois suivant : rien la veille de la plus grande avance de relance');
  v_r := private.fac_emission_planifiee(pg_temp.suivant() - v_avance);
  PERFORM pg_temp.vrai(pg_temp.nb(pg_temp.suivant()) = 1,
    pg_catalog.format('mois suivant : emis a J-%s', v_avance));
  v_r := private.fac_emission_planifiee(pg_temp.suivant() - v_avance);
  v_r := private.fac_emission_planifiee(pg_temp.suivant() - 1);
  PERFORM pg_temp.vrai(pg_temp.nb(pg_temp.suivant()) = 1,
    'mois suivant : les passages suivants n''en emettent pas d''autre');
  -- La relance du jour J-avance trouve la facture.
  v_r := private.fac_traiter_relances(pg_temp.suivant() - v_avance);
  PERFORM pg_temp.vrai(EXISTS (
    SELECT 1 FROM public.relances_paiement r JOIN public.factures_mensuelles f ON f.id = r.facture_id
     WHERE f.household_id = 'b4000000-0000-4000-8000-0000000000f1' AND f.mois = pg_temp.suivant()
       AND r.action = 'relance' AND r.jours_avant = v_avance),
    pg_catalog.format('relance J-%s : partie sur la facture du mois suivant', v_avance));
END;
$suivant$;

\o
\echo 'scenarios_b4_factures_cron : OK'
ROLLBACK;
