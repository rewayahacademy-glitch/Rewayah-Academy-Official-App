-- FAC-D-01 (18/10/2026) : la saisie de la comptabilite attend la validation
-- de la direction (dossier maitre du 14/10, permissions par role, « Crediter
-- apres paiement manuel » ; Q-8 = a). Migration 20261018090000.
--   1. la comptabilite soumet : demande creee, rien credite, idempotence ;
--   2. chacun ne voit que ce qu'il doit voir ; seule la direction decide ;
--   3. refus avec motif obligatoire, decision unique et idempotente,
--      validation qui credite, facture et finance ;
--   4. la direction qui saisit elle-meme credite tout de suite.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
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

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text) TO authenticated, anon;

INSERT INTO auth.users(id, email) VALUES
 ('fd000000-0000-4000-8000-0000000000a1','fd-admin@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000a2','fd-admin-suspendu@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000c2','fd-compta2@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000c1','fd-compta@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000b1','fd-ens@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000d1','fd-tit@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000e1','fd-e1@test.invalid'),
 ('fd000000-0000-4000-8000-0000000000e2','fd-e2@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('fd000000-0000-4000-8000-0000000000f1','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('fd000000-0000-4000-8000-0000000000a1','FD-ADM-0001','admin',NULL,'Direction','FD','active','female'),
 ('fd000000-0000-4000-8000-0000000000a2','FD-ADM-0002','admin',NULL,'Direction','Suspendue','disabled','female'),
 ('fd000000-0000-4000-8000-0000000000c1','FD-CPT-0001','accountant',NULL,'Compta','FD','active','male'),
 ('fd000000-0000-4000-8000-0000000000c2','FD-CPT-0002','accountant',NULL,'Compta','Deux','active','female'),
 ('fd000000-0000-4000-8000-0000000000b1','FD-ENS-0001','teacher',NULL,'Maryam','FD','provisional_active','female'),
 ('fd000000-0000-4000-8000-0000000000d1','FD-TUT-0001','guardian','fd000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('fd000000-0000-4000-8000-0000000000e1','FD-ELV-0001','student','fd000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('fd000000-0000-4000-8000-0000000000e2','FD-ELV-0002','student','fd000000-0000-4000-8000-0000000000f1','Bilal','F1','active','male');
UPDATE public.households SET primary_guardian_id = 'fd000000-0000-4000-8000-0000000000d1'
 WHERE id = 'fd000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('fd000000-0000-4000-8000-0000000000e1','minor','child'),
 ('fd000000-0000-4000-8000-0000000000e2','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fd000000-0000-4000-8000-000000000c01','fd000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour FD',1,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('fd000000-0000-4000-8000-000000000c01','fd000000-0000-4000-8000-0000000000e1',
  date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '20 days'),
 ('fd000000-0000-4000-8000-000000000c01','fd000000-0000-4000-8000-0000000000e2',
  date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '20 days');

-- ------------------------------------------------------------------
-- 1. La comptabilite soumet : rien n'est credite
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT set_config('test.s1', public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e1', 5000, 'USD', 'VIR-1',
  'fd000000-0000-4000-8000-00000000d001')::text, true);
SELECT pg_temp.vrai(current_setting('test.s1')::jsonb ->> 'etat' = 'validation_demandee'
  AND (current_setting('test.s1')::jsonb ->> 'nouveau')::boolean
  AND current_setting('test.s1')::jsonb ->> 'paiement' IS NULL,
  'soumission : la comptabilite demande une validation, aucun paiement cree');
SELECT pg_temp.vrai(current_setting('test.s1')::jsonb #>> '{finance,solde,mineur}' IS DISTINCT FROM '5000',
  'soumission : le solde de l''eleve ne bouge pas');
SELECT pg_temp.vrai(public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e1', 5000, 'USD', 'VIR-1',
  'fd000000-0000-4000-8000-00000000d001') ->> 'etat' = 'validation_demandee'
  AND NOT (public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e1', 5000, 'USD', 'VIR-1',
  'fd000000-0000-4000-8000-00000000d001') ->> 'nouveau')::boolean,
  'soumission : la meme cle rejouee rend la meme demande');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e1', 7000, 'USD', NULL, 'fd000000-0000-4000-8000-00000000d001')$q$,
  '22023', 'soumission : cle reutilisee pour un autre montant refusee');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e1', 5000, 'EUR', NULL, gen_random_uuid())$q$,
  '22023', 'soumission : devise differente refusee');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000d1', 5000, 'USD', NULL, gen_random_uuid())$q$,
  'P0002', 'soumission : un tuteur sans profil eleve n''est pas un beneficiaire');
SELECT set_config('test.s2', public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e2', 5000, 'USD', NULL,
  'fd000000-0000-4000-8000-00000000d002')::text, true);
SELECT set_config('test.v1', current_setting('test.s1')::jsonb ->> 'validation', true);
SELECT set_config('test.v2', current_setting('test.s2')::jsonb ->> 'validation', true);
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.wallet_entries WHERE beneficiaire_id IN ('fd000000-0000-4000-8000-0000000000e1', 'fd000000-0000-4000-8000-0000000000e2')),
  'soumission : aucune ecriture au portefeuille avant validation');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'paiement_soumis'),
  'soumission : inscrite au journal');

-- ------------------------------------------------------------------
-- 2. Ce que chacun voit
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT pg_temp.vrai(jsonb_array_length(public.finance_validations_lister()) = 2
  AND public.finance_validations_lister() -> 0 -> 'actions' = '[]'::jsonb
  AND public.finance_validations_lister() -> 0 #>> '{blocages,approuver}' = 'auto_paiement',
  'lecture : la comptabilite voit ses deux demandes, sans pouvoir les decider');
SELECT pg_temp.vrai(public.finance_validations_lister() -> 0 ->> 'objet' LIKE '%FD-ELV-%'
  AND public.finance_validations_lister() -> 0 ->> 'nature' = 'paiement_recu'
  AND public.finance_validations_lister() -> 0 ->> 'raison' = 'paiement_hors_application',
  'lecture : nature, raison et eleve rendus');
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000c2', 'accountant');
SELECT pg_temp.vrai(jsonb_array_length(public.finance_validations_lister()) = 0,
  'lecture : une autre comptable ne voit pas ces demandes');
SELECT pg_temp.refus(format($q$SELECT public.finance_validation_decider(%L, 'valider', NULL, gen_random_uuid())$q$, current_setting('test.v1')),
  '42501', 'decision : la comptabilite ne decide jamais');
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000d1', 'guardian', 'fd000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.finance_validations_lister()$q$, '42501', 'lecture : un tuteur ne lit pas les validations');
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(jsonb_array_length(public.finance_validations_lister('en_attente')) = 2
  AND public.finance_validations_lister() -> 0 -> 'actions' = '["approuver"]'::jsonb,
  'lecture : la direction voit les deux demandes et peut les decider');
SELECT pg_temp.vrai(jsonb_array_length(public.finance_validation_journal(current_setting('test.v1')::uuid)) = 1
  AND public.finance_validation_journal(current_setting('test.v1')::uuid) -> 0 ->> 'reference' = 'VIR-1',
  'journal : la demande et sa reference');
SELECT pg_temp.vrai(NOT has_table_privilege('authenticated', 'public.finance_validations', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.paiements_soumis', 'SELECT'),
  'lecture : tables illisibles hors RPC');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.finance_validations_lister()$q$, '42501', 'anon : lecture sans EXECUTE');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. La direction refuse puis valide
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus(format($q$SELECT public.finance_validation_decider(%L, 'refuser', '  ', gen_random_uuid())$q$, current_setting('test.v2')),
  'RV002', 'decision : un refus sans motif est refuse');
SELECT pg_temp.vrai(public.finance_validation_decider(current_setting('test.v2')::uuid, 'refuser',
  'Montant a verifier a la source', 'fd000000-0000-4000-8000-00000000e002') ->> 'etat' = 'refusee',
  'decision : la direction refuse avec motif');
SELECT pg_temp.vrai(public.finance_validation_decider(current_setting('test.v2')::uuid, 'refuser',
  'Montant a verifier a la source', 'fd000000-0000-4000-8000-00000000e002') ->> 'etat' = 'refusee',
  'decision : la meme cle rejouee rend la meme reponse');
SELECT pg_temp.refus(format($q$SELECT public.finance_validation_decider(%L, 'valider', NULL, gen_random_uuid())$q$, current_setting('test.v2')),
  'RV003', 'decision : une demande decidee ne se decide plus');
SELECT set_config('test.d1', public.finance_validation_decider(current_setting('test.v1')::uuid, 'valider', NULL,
  'fd000000-0000-4000-8000-00000000e001')::text, true);
SELECT pg_temp.vrai(current_setting('test.d1')::jsonb ->> 'etat' = 'validee'
  AND current_setting('test.d1')::jsonb ->> 'decideur' = 'Direction FD'
  AND current_setting('test.d1')::jsonb -> 'actions' = '[]'::jsonb,
  'decision : la direction valide');
SELECT pg_temp.vrai(jsonb_array_length(public.finance_validation_journal(current_setting('test.v1')::uuid)) = 2,
  'journal : la demande puis la decision');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.wallet_entries e JOIN public.paiements_saisis p ON p.entry_id = e.id
                      WHERE e.beneficiaire_id = 'fd000000-0000-4000-8000-0000000000e1' AND e.amount_minor = 5000
                        AND p.saisi_par = 'fd000000-0000-4000-8000-0000000000c1' AND p.valide_par = 'fd000000-0000-4000-8000-0000000000a1') = 1,
  'validation : un credit de 50 USD pour Yasmine, saisi par la comptabilite, valide par la direction');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.wallet_entries WHERE beneficiaire_id = 'fd000000-0000-4000-8000-0000000000e2'),
  'refus : rien n''est credite a Bilal');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.factures_mensuelles
                             WHERE profile_id = 'fd000000-0000-4000-8000-0000000000e1' AND statut = 'financee'),
  'validation : le mois de Yasmine est facture et regle');

-- La comptabilite relit ses saisies : etat courant par la meme cle.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT pg_temp.vrai(public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e1', 5000, 'USD', 'VIR-1',
  'fd000000-0000-4000-8000-00000000d001') ->> 'etat' = 'enregistre',
  'relecture : la saisie validee est enregistree');
SELECT pg_temp.vrai(public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e2', 5000, 'USD', NULL,
  'fd000000-0000-4000-8000-00000000d002') ->> 'motif' = 'Montant a verifier a la source',
  'relecture : la saisie refusee rend son motif');

-- ------------------------------------------------------------------
-- 4. La direction saisit elle-meme : credit immediat
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fd000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.enregistrer_paiement('fd000000-0000-4000-8000-0000000000e2', 5000, 'USD', NULL, gen_random_uuid()) ->> 'etat' = 'enregistre',
  'direction : sa saisie est creditee tout de suite');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'validation_finance_decidee'),
  'decision : inscrite au journal');

\o
SELECT 'FAC-D validation des paiements : tous les controles sont verts' AS bilan;
ROLLBACK;
