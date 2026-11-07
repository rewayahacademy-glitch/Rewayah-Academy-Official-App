-- FINANCE-ENSEIGNANT (lot 9, 06/11/2026) : la direction note un versement de
-- paie fait hors de l'application ; l'enseignant le voit. Migration 20261110710000.
--   1. la direction et le comptable notent ; enseignant, tuteur, anon refuses ;
--   2. la meme cle ne cree qu'un versement ; tresorerie : sortie de paie_a_decaisser ;
--   3. sans taux de change, la tresorerie part en reprise ;
--   4. une reference longue ou avec espaces (un numero de compte) est refusee ;
--   5. annulation avec motif : ligne gardee, ecriture inverse ;
--   6. l'enseignant lit SES versements, sans note ; un autre ne les voit pas.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'VERSEMENT-NOTE ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'VERSEMENT-NOTE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
  END;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('fe000000-0000-4000-8000-0000000000' || p)::uuid $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated, service_role, anon;

INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'vn-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','ac','b1','b2','d1']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.id('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'VN', (CASE WHEN x.role = 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','VN-ADM-0001','admin',NULL,'Direction','female'),
   ('ac','VN-CPT-0001','accountant',NULL,'Karima','female'),
   ('b1','VN-ENS-0001','teacher',NULL,'Mamadou','male'),
   ('b2','VN-ENS-0002','teacher',NULL,'Fatou','female'),
   ('d1','VN-TUT-0001','guardian','f1','Amina','female')) AS x(id, mat, role, foyer, prenom, genre);


-- ------------------------------------------------------------------
-- 1. Qui note
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.versement_paie_noter('fe000000-0000-4000-8000-0000000000b1', 2500, 'USD',
  current_date, 'virement_bancaire', 'TX1', current_date, NULL, gen_random_uuid())$$,
  '1 : un enseignant ne note pas un versement');
SELECT pg_temp.refus('SELECT public.versements_paie_direction(NULL)', '1 : un enseignant ne lit pas la liste');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.versement_paie_noter('fe000000-0000-4000-8000-0000000000b1', 2500, 'USD',
  current_date, 'virement_bancaire', 'TX1', current_date, NULL, gen_random_uuid())$$,
  '1 : un tuteur ne note pas');
SELECT pg_temp.refus('SELECT public.mes_versements_paie()', '1 : un tuteur ne lit pas les versements');
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('anon',
  'public.versement_paie_noter(uuid, bigint, text, date, text, text, date, text, uuid)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.versements_paie', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.versements_paie', 'INSERT'),
  '1 : anon sans la fonction ; aucun droit direct sur la table');

-- ------------------------------------------------------------------
-- 2. La direction note, idempotent
-- ------------------------------------------------------------------
SELECT set_config('test.cle', gen_random_uuid()::text, true);
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT set_config('test.v1', public.versement_paie_noter(pg_temp.id('b1'), 2587, 'USD', current_date,
  'mobile_money', 'OM-2026-11-0042', current_date, 'paie d''octobre', current_setting('test.cle')::uuid) ->> 'id', true);
SELECT pg_temp.vrai(public.versement_paie_noter(pg_temp.id('b1'), 2587, 'USD', current_date,
  'mobile_money', 'OM-2026-11-0042', current_date, NULL, current_setting('test.cle')::uuid) ->> 'id'
  = current_setting('test.v1'), '2 : la meme cle rend le meme versement');
SELECT pg_temp.refus($$SELECT public.versement_paie_noter('fe000000-0000-4000-8000-0000000000d1', 100, 'USD',
  current_date, 'autre', NULL, current_date, NULL, gen_random_uuid())$$,
  '2 : un tuteur ne recoit pas de paie');
SELECT pg_temp.refus($$SELECT public.versement_paie_noter('fe000000-0000-4000-8000-0000000000b1', 0, 'USD',
  current_date, 'autre', NULL, current_date, NULL, gen_random_uuid())$$, '2 : montant nul refuse');
SELECT pg_temp.refus($$SELECT public.versement_paie_noter('fe000000-0000-4000-8000-0000000000b1', 100, 'USD',
  current_date + 30, 'autre', NULL, current_date, NULL, gen_random_uuid())$$, '2 : date future refusee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.versements_paie) = 1, '2 : un seul versement en base');
SELECT pg_temp.vrai((SELECT montant_minor FROM public.tresorerie_mouvements
  WHERE source_type = 'payout' AND source_id = current_setting('test.v1') AND regle = 'versement_note'
    AND coffre = 'paie_a_decaisser' AND sens = 'sortie') = 2587,
  '2 : tresorerie : sortie de paie_a_decaisser au montant note');

-- ------------------------------------------------------------------
-- 3. Sans taux de change
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('ac'), 'accountant');
SET LOCAL ROLE authenticated;
SELECT set_config('test.v2', public.versement_paie_noter(pg_temp.id('b2'), 250000, 'GNF', current_date,
  'virement_bancaire', NULL, current_date, NULL, gen_random_uuid()) ->> 'id', true);
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.tresorerie_a_reprendre
  WHERE source_type = 'payout' AND source_id = current_setting('test.v2') AND raison = 'taux_change_absent')
  AND NOT EXISTS (SELECT 1 FROM public.tresorerie_mouvements WHERE source_id = current_setting('test.v2')),
  '3 : le comptable note ; sans taux, la tresorerie part en reprise');

-- ------------------------------------------------------------------
-- 4. Reference
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.versement_paie_noter('fe000000-0000-4000-8000-0000000000b1', 100, 'USD',
  current_date, 'virement_bancaire', 'GN12 3456 7890 1234 5678', current_date, NULL, gen_random_uuid())$$,
  '4 : une reference avec espaces (un numero de compte) est refusee');

-- ------------------------------------------------------------------
-- 5. Annulation
-- ------------------------------------------------------------------
SELECT pg_temp.refus($$SELECT public.versement_paie_annuler(current_setting('test.v1')::uuid, '')$$,
  '5 : annuler sans motif est refuse');
SELECT pg_temp.vrai(public.versement_paie_annuler(current_setting('test.v1')::uuid, 'montant errone')
  ->> 'annuleMotif' = 'montant errone', '5 : annulation avec motif');
SELECT pg_temp.vrai(public.versement_paie_annuler(current_setting('test.v1')::uuid, 'deux fois')
  ->> 'annuleMotif' = 'montant errone', '5 : une seconde annulation ne change rien');
RESET ROLE;
SELECT pg_temp.vrai((SELECT montant_minor FROM public.tresorerie_mouvements
  WHERE source_id = current_setting('test.v1') AND regle = 'versement_note_annule'
    AND coffre = 'paie_a_decaisser' AND sens = 'entree') = 2587
  AND (SELECT count(*) FROM public.versements_paie) = 2,
  '5 : ecriture inverse ; la ligne reste');

-- ------------------------------------------------------------------
-- 6. L'enseignant
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.mes_versements_paie()) = 1
  AND (public.mes_versements_paie() -> 0 ->> 'annule')::boolean
  AND public.mes_versements_paie()::text NOT LIKE '%octobre%',
  '6 : l''enseignant voit son versement, annule, sans la note interne');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.mes_versements_paie()) = 1
  AND public.mes_versements_paie() -> 0 -> 'montant' ->> 'devise' = 'GNF',
  '6 : un autre enseignant ne voit que le sien');
RESET ROLE;

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 18,
  'au moins 18 controles ont passe');
\o
SELECT 'VERSEMENT-NOTE : scenarios verts' AS resultat;
ROLLBACK;
