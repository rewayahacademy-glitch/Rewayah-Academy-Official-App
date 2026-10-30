-- FAC-A-01 (17/10/2026) : politique commerciale versionnee.
-- Migration 20261017170000_fac_a_01_politiques_commerciales.sql.
--   1. lecture : version de lancement (guide V4), brouillon propose au numero
--      et a la date suivants ; enseignant, tuteur, direction suspendue et anon
--      refuses, table illisible hors direction et comptabilite ;
--   2. apercus : mensualites par rang (exemples du guide §1.3) et taux horaire
--      (formule du guide §1.4), bornes refusees ;
--   3. publication : direction en aal2 seulement, numero et date controles,
--      remise superieure au tarif et forme invalide refusees, version publiee
--      immuable, aucune ecriture directe dans la table.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

-- FAC-E-01 : ce scenario eprouve la politique v1 ; la v2 (en vigueur le
-- 1er novembre 2026) est retiree le temps du scenario, annule a la fin.
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
-- TRANSPARENCE (31/10) : sa repartition s'en va avec elle.
DELETE FROM public.repartitions_paiement WHERE politique_version = 'v2.0.0';
DELETE FROM public.politiques_commerciales WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', p_aal)::text
                ELSE pg_catalog.json_build_object('aal', p_aal, 'app_metadata',
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

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

INSERT INTO auth.users(id, email) VALUES
 ('fa000000-0000-4000-8000-0000000000a1','fa-admin@test.invalid'),
 ('fa000000-0000-4000-8000-0000000000a2','fa-admin-suspendu@test.invalid'),
 ('fa000000-0000-4000-8000-0000000000c1','fa-comptable@test.invalid'),
 ('fa000000-0000-4000-8000-0000000000b1','fa-ens@test.invalid'),
 ('fa000000-0000-4000-8000-0000000000d1','fa-tuteur@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('fa000000-0000-4000-8000-0000000000f1','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('fa000000-0000-4000-8000-0000000000a1','FA-ADM-0001','admin',NULL,'Direction','FA','active','female'),
 ('fa000000-0000-4000-8000-0000000000a2','FA-ADM-0002','admin',NULL,'Direction','Suspendue','disabled','female'),
 ('fa000000-0000-4000-8000-0000000000c1','FA-CPT-0001','accountant',NULL,'Compta','FA','active','male'),
 ('fa000000-0000-4000-8000-0000000000b1','FA-ENS-0001','teacher',NULL,'Ens','FA','provisional_active','male'),
 ('fa000000-0000-4000-8000-0000000000d1','FA-TUT-0001','guardian','fa000000-0000-4000-8000-0000000000f1','Tut','FA','active','female');

-- ------------------------------------------------------------------
-- 1. Lecture
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.politique_commerciale_active() ->> 'version' = 'v1.0.0', 'lecture : v1.0.0 en vigueur');
SELECT pg_temp.vrai(public.politique_commerciale_active() -> 'tarifEnfant' = '{"mineur":5000,"devise":"USD"}'::jsonb
  AND public.politique_commerciale_active() -> 'tarifAdulte' = '{"mineur":6000,"devise":"USD"}'::jsonb,
  'lecture : tarifs 50 et 60 USD (FIN4-01)');
SELECT pg_temp.vrai(public.politique_commerciale_active() -> 'remisesParRang' =
  '[{"aPartirDuRang":3,"remise":{"mineur":-500,"devise":"USD"}},{"aPartirDuRang":4,"remise":{"mineur":-700,"devise":"USD"}}]'::jsonb,
  'lecture : remises de rang 3 et 4 (guide §1.3)');
SELECT pg_temp.vrai((public.politique_commerciale_active() ->> 'essaisMax')::int = 2
  AND (public.politique_commerciale_active() ->> 'joursConservationPlace')::int = 7
  AND public.politique_commerciale_active() -> 'joursRelance' = 'null'::jsonb
  AND public.politique_commerciale_active() -> 'railsActifs' = '["webStripe"]'::jsonb,
  'lecture : essai 2, conservation 7 jours, relances non decidees, paiement web seul');
SELECT pg_temp.vrai(public.politiques_commerciales_versions() -> 0 ->> 'statut' = 'brouillon'
  AND public.politiques_commerciales_versions() -> 0 ->> 'version' = 'v1.1.0'
  AND (public.politiques_commerciales_versions() -> 0 ->> 'dateEffet')::date
      = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) + interval '1 month')::date
  AND public.politiques_commerciales_versions() -> 1 ->> 'version' = 'v1.0.0'
  AND jsonb_array_length(public.politiques_commerciales_versions()) = 2,
  'lecture : brouillon v1.1.0 au premier du mois suivant, puis v1.0.0');

SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT pg_temp.vrai(public.politique_commerciale_active() ->> 'version' = 'v1.0.0', 'lecture : la comptabilite lit la politique');
SELECT pg_temp.vrai((SELECT count(*) FROM public.politiques_commerciales) = 1, 'lecture : la comptabilite lit la table');

SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.politique_commerciale_active()$q$, '42501', 'lecture : enseignant refuse');
SELECT pg_temp.vrai((SELECT count(*) FROM public.politiques_commerciales) = 0, 'lecture : table illisible pour un enseignant');
SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000d1', 'guardian');
SELECT pg_temp.refus($q$SELECT public.politiques_commerciales_versions()$q$, '42501', 'lecture : tuteur refuse');
SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000a2', 'admin', 'aal2');
SELECT pg_temp.refus($q$SELECT public.politique_commerciale_active()$q$, '42501', 'lecture : direction suspendue refusee');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.politique_commerciale_active()$q$, '42501', 'anon : lecture sans EXECUTE');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Apercus
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.brouillon', (public.politiques_commerciales_versions() -> 0)::text, true);
SELECT pg_temp.vrai(public.apercu_politique_famille(current_setting('test.brouillon')::jsonb, 3) -> 'total'
  = '{"mineur":14500,"devise":"USD"}'::jsonb, 'apercu : 3 enfants = 145 USD (guide §1.3)');
SELECT pg_temp.vrai(public.apercu_politique_famille(current_setting('test.brouillon')::jsonb, 4) -> 'total'
  = '{"mineur":18800,"devise":"USD"}'::jsonb, 'apercu : 4 enfants = 188 USD (guide §1.3)');
SELECT pg_temp.vrai(public.apercu_politique_famille(current_setting('test.brouillon')::jsonb, 4) -> 'enfants' -> 0 -> 'remise' = 'null'::jsonb
  AND public.apercu_politique_famille(current_setting('test.brouillon')::jsonb, 4) -> 'enfants' -> 3 -> 'mensualite'
      = '{"mineur":4300,"devise":"USD"}'::jsonb,
  'apercu : rang 1 sans remise, rang 4 a 43 USD');
SELECT pg_temp.refus($q$SELECT public.apercu_politique_famille(current_setting('test.brouillon')::jsonb, 6)$q$, '22023', 'apercu : 6 enfants hors bornes');
SELECT pg_temp.vrai(public.apercu_politique_enseignant(current_setting('test.brouillon')::jsonb, 5, 3) -> 'tauxHoraire'
  = '{"mineur":580,"devise":"USD"}'::jsonb
  AND public.apercu_politique_enseignant(current_setting('test.brouillon')::jsonb, 5, 3) -> 'occupation'
  = '{"mineur":180,"devise":"USD"}'::jsonb, 'apercu : 3 sieges sur 5 = 5,80 USD/h (guide §1.4)');
SELECT pg_temp.vrai(public.apercu_politique_enseignant(current_setting('test.brouillon')::jsonb, 5, 9) -> 'tauxHoraire'
  = '{"mineur":700,"devise":"USD"}'::jsonb
  AND (public.apercu_politique_enseignant(current_setting('test.brouillon')::jsonb, 5, 9) ->> 'eligibles')::int = 5,
  'apercu : jamais au-dessus du plafond, eligibles bornes a la capacite');
SELECT pg_temp.refus($q$SELECT public.apercu_politique_enseignant(current_setting('test.brouillon')::jsonb, 0, 0)$q$, '22023', 'apercu : capacite nulle refusee');

-- ------------------------------------------------------------------
-- 3. Publication
-- ------------------------------------------------------------------
SELECT set_config('test.nouveau', jsonb_set(current_setting('test.brouillon')::jsonb,
  '{tarifEnfant,mineur}', '5500')::text, true);
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(current_setting('test.nouveau')::jsonb)$q$, '42501', 'publication : direction sans double verification refusee');
SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000c1', 'accountant', 'aal2');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(current_setting('test.nouveau')::jsonb)$q$, '42501', 'publication : comptabilite refusee');
SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000a2', 'admin', 'aal2');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(current_setting('test.nouveau')::jsonb)$q$, '42501', 'publication : direction suspendue refusee');

SELECT pg_temp.qui('fa000000-0000-4000-8000-0000000000a1', 'admin', 'aal2');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(jsonb_set(current_setting('test.nouveau')::jsonb, '{dateEffet}', to_jsonb(to_char((now() AT TIME ZONE 'Europe/Paris')::date, 'YYYY-MM-DD'))))$q$,
  '22023', 'publication : date d''effet du jour refusee (jamais retroactive)');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(jsonb_set(current_setting('test.nouveau')::jsonb, '{version}', '"v1.0.0"'))$q$,
  '22023', 'publication : numero deja publie refuse');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(jsonb_set(current_setting('test.nouveau')::jsonb, '{remisesParRang,0,remise,mineur}', '-6000'))$q$,
  '22023', 'publication : remise superieure au tarif refusee');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(jsonb_set(current_setting('test.nouveau')::jsonb, '{tarifAdulte,devise}', '"EUR"'))$q$,
  '22023', 'publication : devise melangee refusee');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(current_setting('test.nouveau')::jsonb - 'essaisMax')$q$,
  '22023', 'publication : champ manquant refuse');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(jsonb_set(current_setting('test.nouveau')::jsonb, '{railsActifs}', '["carte"]'))$q$,
  '22023', 'publication : rail inconnu refuse');

SELECT pg_temp.vrai(public.publier_politique_commerciale(current_setting('test.nouveau')::jsonb) ->> 'version' = 'v1.1.0',
  'publication : v1.1.0 publiee par la direction en aal2');
SELECT pg_temp.vrai(public.politique_commerciale_active() ->> 'version' = 'v1.0.0',
  'publication : la version future ne s''applique pas avant sa date d''effet');
SELECT pg_temp.vrai(public.politiques_commerciales_versions() -> 0 ->> 'version' = 'v1.2.0'
  AND public.politiques_commerciales_versions() -> 1 -> 'tarifEnfant' = '{"mineur":5500,"devise":"USD"}'::jsonb
  AND (public.politiques_commerciales_versions() -> 0 ->> 'dateEffet')::date
      > (public.politiques_commerciales_versions() -> 1 ->> 'dateEffet')::date,
  'publication : le brouillon suivant est v1.2.0, apres la date de v1.1.0');
SELECT pg_temp.refus($q$SELECT public.publier_politique_commerciale(current_setting('test.nouveau')::jsonb)$q$,
  '22023', 'publication : republier la meme version refuse');
SELECT pg_temp.refus($q$INSERT INTO public.politiques_commerciales SELECT * FROM public.politiques_commerciales WHERE version = 'v1.0.0'$q$,
  '42501', 'publication : aucune ecriture directe dans la table');
RESET ROLE;

SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'politique_commerciale_publiee'),
  'publication : inscrite au journal');
SELECT pg_temp.refus($q$UPDATE public.politiques_commerciales SET tarif_enfant_mineur = 1 WHERE version = 'v1.0.0'$q$,
  '42501', 'immuable : une version publiee ne se modifie pas, meme par le proprietaire');
SELECT pg_temp.refus($q$DELETE FROM public.politiques_commerciales WHERE version = 'v1.0.0'$q$,
  '42501', 'immuable : une version publiee ne se supprime pas');

\o
SELECT 'FAC-A politiques commerciales : tous les controles sont verts' AS bilan;
ROLLBACK;
