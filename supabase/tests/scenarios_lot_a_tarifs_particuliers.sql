-- Lot (A), 02/11/2026 : « Accès offert » et « Prix spécial », saisis par la
-- direction. Scenario sur une base nue (stub + toutes les migrations).
--
-- Trois eleves : e1 suspendu pour paiement, e2 et e3 a jour. La direction
-- offre l'acces a e1 (la suspension se leve), accorde un prix special a e3,
-- puis une bourse de la politique a e2 : le quota des bourses ne compte pas
-- les deux premiers.
\set ON_ERROR_STOP 1
BEGIN;
SET LOCAL client_min_messages = warning;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'Lot A ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'Lot A ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'Lot A ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  PERFORM pg_temp.vrai(true, p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon, service_role;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('8a000000-0000-4000-8000-0000000000a1','la-admin@test.invalid'),
 ('8a000000-0000-4000-8000-0000000000d1','la-tut1@test.invalid'),
 ('8a000000-0000-4000-8000-0000000000e1','la-e1@test.invalid'),
 ('8a000000-0000-4000-8000-0000000000e2','la-e2@test.invalid'),
 ('8a000000-0000-4000-8000-0000000000e3','la-e3@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('8a000000-0000-4000-8000-0000000000f1','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('8a000000-0000-4000-8000-0000000000a1','LA-ADM-0001','admin',NULL,'Direction','LA','active','female'),
 ('8a000000-0000-4000-8000-0000000000d1','LA-TUT-0001','guardian','8a000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('8a000000-0000-4000-8000-0000000000e1','LA-ELV-0001','student','8a000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('8a000000-0000-4000-8000-0000000000e2','LA-ELV-0002','student','8a000000-0000-4000-8000-0000000000f1','Bilal','F1','active','male'),
 ('8a000000-0000-4000-8000-0000000000e3','LA-ELV-0003','student','8a000000-0000-4000-8000-0000000000f1','Salma','F1','active','female');
UPDATE public.households SET primary_guardian_id = '8a000000-0000-4000-8000-0000000000d1'
 WHERE id = '8a000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('8a000000-0000-4000-8000-0000000000e1','minor','standard'),
 ('8a000000-0000-4000-8000-0000000000e2','minor','standard'),
 ('8a000000-0000-4000-8000-0000000000e3','minor','standard');
SELECT private.fac_portefeuille('8a000000-0000-4000-8000-0000000000f1', 'USD');
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur)
VALUES ('8a000000-0000-4000-8000-0000000000e1','8a000000-0000-4000-8000-0000000000f1',
        private.fac_mois_courant(), 'v2.0.0', 'USD', 1, '[]'::jsonb, 5500);
INSERT INTO public.acces_suspensions_paiement(profile_id, facture_id, jour)
SELECT f.profile_id, f.id, private.fac_aujourdhui() FROM public.factures_mensuelles f
 WHERE f.profile_id = '8a000000-0000-4000-8000-0000000000e1';

SELECT set_config('test.fin', (private.fac_mois_courant() + interval '3 months')::date::text, false),
       set_config('test.passe', (private.fac_mois_courant() - interval '1 month')::date::text, false);

-- ------------------------------------------------------------------
-- 1. Seule la direction accorde ; les valeurs se controlent
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('8a000000-0000-4000-8000-0000000000d1', 'guardian', '8a000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e1',
  'acces_offert', NULL, current_setting('test.fin')::date, 'essai')$q$, '42501',
  '1 : un tuteur n''accorde rien');
SELECT pg_temp.qui('8a000000-0000-4000-8000-0000000000a1', 'admin', NULL);
SELECT pg_temp.refus($q$SELECT public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e3',
  'prix_special', 1000, current_setting('test.fin')::date, 'essai')$q$, '22023',
  '1 : un prix special de 100 % est refuse (c''est un acces offert)');
SELECT pg_temp.refus($q$SELECT public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e3',
  'prix_special', 300, current_setting('test.passe')::date, 'essai')$q$, '22023',
  '1 : un mois de fin passe est refuse');
SELECT pg_temp.refus($q$SELECT public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e3',
  'prix_special', 300, current_setting('test.fin')::date, '  ')$q$, '22023',
  '1 : la raison est obligatoire');
SELECT pg_temp.refus($q$SELECT public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e3',
  'cadeau', 300, current_setting('test.fin')::date, 'essai')$q$, '22023',
  '1 : une nature inconnue est refusee');

-- ------------------------------------------------------------------
-- 2. Acces offert a e1 : la suspension se leve tout de suite
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e1',
  'acces_offert', NULL, current_setting('test.fin')::date, 'Famille aidee par l''academie')
  ->> 'nature') = 'acces_offert',
  '2 : l''acces offert est accorde et rendu avec sa nature');
RESET ROLE;
SELECT pg_temp.vrai((SELECT pour_mille = 1000 AND mois_fin = current_setting('test.fin')::date
                       FROM public.bourses_eleves WHERE profile_id = '8a000000-0000-4000-8000-0000000000e1'
                        AND retiree_le IS NULL)
  AND (SELECT retabli_motif = 'bourse' FROM public.acces_suspensions_paiement
        WHERE profile_id = '8a000000-0000-4000-8000-0000000000e1')
  AND private.acces_paye('8a000000-0000-4000-8000-0000000000e1')
  AND private.fac_bourse_couvre('8a000000-0000-4000-8000-0000000000e1', private.fac_mois_courant()),
  '2 : 100 % jusqu''au mois choisi ; la suspension est levee ; aucune relance ne viendra');

-- ------------------------------------------------------------------
-- 3. Prix special a e3 : la reduction choisie, une seule remise active
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('8a000000-0000-4000-8000-0000000000a1', 'admin', NULL);
SELECT pg_temp.vrai((public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e3',
  'prix_special', 350, current_setting('test.fin')::date, 'Inscrite avant novembre 2026')
  ->> 'pourMille')::int = 350,
  '3 : le prix special est accorde avec la reduction choisie');
SELECT pg_temp.refus($q$SELECT public.accorder_tarif_particulier('8a000000-0000-4000-8000-0000000000e3',
  'prix_special', 200, current_setting('test.fin')::date, 'essai')$q$, 'BO002',
  '3 : une seule remise active par eleve');
RESET ROLE;
SELECT pg_temp.vrai((private.fac_bourse('8a000000-0000-4000-8000-0000000000e3', private.fac_mois_courant())).pour_mille = 350
  AND NOT private.fac_bourse_couvre('8a000000-0000-4000-8000-0000000000e3', private.fac_mois_courant()),
  '3 : la facture du mois lira 35 % de reduction ; le reste se paie (relances normales)');

-- ------------------------------------------------------------------
-- 4. Le quota des bourses ne compte que les bourses
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('8a000000-0000-4000-8000-0000000000a1', 'admin', NULL);
SELECT pg_temp.vrai((public.accorder_bourse('8a000000-0000-4000-8000-0000000000e2',
    'Bourse de la politique') ->> 'nature') = 'bourse',
  '4 : une bourse de la politique reste possible malgre deux remises particulieres');
SELECT pg_temp.vrai((SELECT count(*) FROM jsonb_array_elements(public.bourses_lister()) x
                      WHERE x ->> 'nature' IN ('acces_offert', 'prix_special', 'bourse')) = 3,
  '4 : la liste de la direction rend les trois remises avec leur nature');
RESET ROLE;
SELECT pg_temp.vrai(has_function_privilege('agent_ro', 'private.acces_paye_seance(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.accorder_tarif_particulier(uuid,text,integer,date,text)', 'EXECUTE'),
  '4 : agent_ro lit les enregistrements (remarque du pilote sur B) ; anon n''accorde rien');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 13,
  'au moins 13 controles ont passe (14 avec celui-ci)');
SELECT 'Lot A : scenarios verts' AS resultat;
ROLLBACK;
