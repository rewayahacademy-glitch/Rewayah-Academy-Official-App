-- FAC-C-01 (17/10/2026) : saisie d'un paiement recu hors application.
-- Migrations 20261017170000, 20261017171000 et 20261017172000.
--   1. droits : direction et comptabilite seulement, compte valide ; tuteur,
--      enseignant, direction suspendue et anon refuses ;
--   2. la liste des eleves avec le reste a payer, le plus a regulariser d'abord ;
--   3. un paiement : portefeuille cree dans la devise de la politique, credit
--      compte, facture du mois emise et financee quand le paiement la couvre ;
--      un paiement partiel n'est pas consomme (FIN4-09) ;
--   4. idempotence par cle ; cle reutilisee pour un autre paiement refusee ;
--      montant, devise et profil invalides refuses ; table illisible hors
--      direction et comptabilite.
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
 ('fc000000-0000-4000-8000-0000000000a1','fc-admin@test.invalid'),
 ('fc000000-0000-4000-8000-0000000000a2','fc-admin-suspendu@test.invalid'),
 ('fc000000-0000-4000-8000-0000000000c1','fc-compta@test.invalid'),
 ('fc000000-0000-4000-8000-0000000000b1','fc-ens@test.invalid'),
 ('fc000000-0000-4000-8000-0000000000d1','fc-tit@test.invalid'),
 ('fc000000-0000-4000-8000-0000000000e1','fc-e1@test.invalid'),
 ('fc000000-0000-4000-8000-0000000000e2','fc-e2@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('fc000000-0000-4000-8000-0000000000f1','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('fc000000-0000-4000-8000-0000000000a1','FC-ADM-0001','admin',NULL,'Direction','FC','active','female'),
 ('fc000000-0000-4000-8000-0000000000a2','FC-ADM-0002','admin',NULL,'Direction','Suspendue','disabled','female'),
 ('fc000000-0000-4000-8000-0000000000c1','FC-CPT-0001','accountant',NULL,'Compta','FC','active','male'),
 ('fc000000-0000-4000-8000-0000000000b1','FC-ENS-0001','teacher',NULL,'Maryam','FC','provisional_active','female'),
 ('fc000000-0000-4000-8000-0000000000d1','FC-TUT-0001','guardian','fc000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('fc000000-0000-4000-8000-0000000000e1','FC-ELV-0001','student','fc000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('fc000000-0000-4000-8000-0000000000e2','FC-ELV-0002','student','fc000000-0000-4000-8000-0000000000f1','Bilal','F1','active','male');
UPDATE public.households SET primary_guardian_id = 'fc000000-0000-4000-8000-0000000000d1'
 WHERE id = 'fc000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('fc000000-0000-4000-8000-0000000000e1','minor','child'),
 ('fc000000-0000-4000-8000-0000000000e2','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fc000000-0000-4000-8000-000000000c01','fc000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour FC',1,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('fc000000-0000-4000-8000-000000000c01','fc000000-0000-4000-8000-0000000000e1',
  date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '20 days'),
 ('fc000000-0000-4000-8000-000000000c01','fc000000-0000-4000-8000-0000000000e2',
  date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '20 days');

-- ------------------------------------------------------------------
-- 1. Droits
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000d1', 'guardian', 'fc000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e1', 5000, 'USD', NULL, gen_random_uuid())$q$,
  '42501', 'droits : un tuteur ne saisit pas de paiement');
SELECT pg_temp.refus($q$SELECT public.eleves_pour_paiement()$q$, '42501', 'droits : un tuteur ne lit pas la liste');
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e1', 5000, 'USD', NULL, gen_random_uuid())$q$,
  '42501', 'droits : un enseignant ne saisit pas de paiement');
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000a2', 'admin');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e1', 5000, 'USD', NULL, gen_random_uuid())$q$,
  '42501', 'droits : une direction suspendue ne saisit pas de paiement');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e1', 5000, 'USD', NULL, gen_random_uuid())$q$,
  '42501', 'anon : saisie sans EXECUTE');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. La liste, avant tout paiement et apres l'emission du mois
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT pg_temp.vrai((SELECT count(*) FROM jsonb_array_elements(public.eleves_pour_paiement()) x
                      WHERE x ->> 'profilId' LIKE 'fc000000%') = 2,
  'liste : les deux eleves du foyer, avant tout portefeuille');
RESET ROLE;
-- Bilal a consomme ses deux seances d'essai : il sera facture ; Yasmine aussi
-- des qu'un paiement arrive pour elle.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT s.id::uuid, 'fc000000-0000-4000-8000-0000000000b1', s.debut, s.debut + interval '1 hour', 'ended',
       'fc000000-0000-4000-8000-000000000c01'
  FROM (VALUES ('fc000000-0000-4000-8000-000000000501', date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '10 days'),
               ('fc000000-0000-4000-8000-000000000502', date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '5 days')) AS s(id, debut);
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('fc000000-0000-4000-8000-000000000501','fc000000-0000-4000-8000-0000000000e2','student'),
 ('fc000000-0000-4000-8000-000000000502','fc000000-0000-4000-8000-0000000000e2','student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000a1', 'admin');
SELECT public.emettre_factures_mois(date_trunc('month', now() AT TIME ZONE 'Europe/Paris')::date);
SELECT pg_temp.vrai((SELECT x #>> '{resteAPayer,mineur}' FROM jsonb_array_elements(public.eleves_pour_paiement()) x
                      WHERE x ->> 'profilId' = 'fc000000-0000-4000-8000-0000000000e2') = '5000'
  AND public.eleves_pour_paiement() -> 0 ->> 'profilId' = 'fc000000-0000-4000-8000-0000000000e2',
  'liste : Bilal doit 50 USD et vient en tete');

-- ------------------------------------------------------------------
-- 3. Les paiements
-- ------------------------------------------------------------------
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e2', 0, 'USD', NULL, gen_random_uuid())$q$,
  '22023', 'saisie : montant nul refuse');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e2', 5000, 'EUR', NULL, gen_random_uuid())$q$,
  '22023', 'saisie : devise differente de celle du foyer refusee');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000d1', 5000, 'USD', NULL, gen_random_uuid())$q$,
  'P0002', 'saisie : un tuteur sans profil eleve n''est pas un beneficiaire');

-- Un paiement partiel pour Bilal : il n'est pas consomme.
SELECT set_config('test.p1', public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e2', 3000, 'USD', 'Virement 1',
  'fc000000-0000-4000-8000-00000000c001')::text, true);
SELECT pg_temp.vrai((current_setting('test.p1')::jsonb ->> 'nouveau')::boolean
  AND current_setting('test.p1')::jsonb #>> '{finance,etat}' IN ('a_regulariser', 'expire')
  AND current_setting('test.p1')::jsonb #>> '{finance,manque,mineur}' = '2000'
  AND current_setting('test.p1')::jsonb #>> '{finance,solde,mineur}' = '3000',
  'saisie : 30 USD pour 50 dus, aucun debit partiel, il manque 20 USD');
-- La meme saisie renvoyee : rien de plus.
SELECT pg_temp.vrai(NOT (public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e2', 3000, 'USD', 'Virement 1',
  'fc000000-0000-4000-8000-00000000c001') ->> 'nouveau')::boolean,
  'idempotence : la meme cle ne cree rien de plus');
SELECT pg_temp.refus($q$SELECT public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e2', 9999, 'USD', NULL, 'fc000000-0000-4000-8000-00000000c001')$q$,
  '22023', 'idempotence : une cle reutilisee pour un autre montant est refusee');
-- Le complement : la facture se finance en une fois.
SELECT set_config('test.p2', public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e2', 2000, 'USD', NULL,
  'fc000000-0000-4000-8000-00000000c002')::text, true);
SELECT pg_temp.vrai(current_setting('test.p2')::jsonb #>> '{finance,etat}' = 'finance'
  AND current_setting('test.p2')::jsonb #>> '{finance,solde,mineur}' = '0'
  AND current_setting('test.p2')::jsonb -> 'finance' -> 'manque' = 'null'::jsonb,
  'saisie : le complement de 20 USD finance le mois, solde 0');

-- Yasmine, sans essai consomme : un premier paiement la rend payante et
-- facture son mois (rang 2 du foyer). Saisi par la direction : depuis
-- FAC-D-01, la saisie de la comptabilite attend sa validation
-- (`scenarios_fac_d_validation_paiements.sql`).
SELECT set_config('test.p3', public.enregistrer_paiement('fc000000-0000-4000-8000-0000000000e1', 5000, 'USD', NULL,
  'fc000000-0000-4000-8000-00000000c003')::text, true);
SELECT pg_temp.vrai(current_setting('test.p3')::jsonb #>> '{finance,etat}' = 'finance',
  'saisie : Yasmine, payee, est facturee et financee le jour meme');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.wallet_entries e JOIN public.paiements_saisis p ON p.entry_id = e.id
                      WHERE e.reference_type = 'credit' AND e.confirme_par_prestataire_le IS NOT NULL) = 3,
  'saisie : trois credits comptes, chacun relie a sa saisie');
SELECT pg_temp.vrai((SELECT rang_familial FROM public.factures_mensuelles
                      WHERE profile_id = 'fc000000-0000-4000-8000-0000000000e1') = 2,
  'saisie : Yasmine facturee au rang 2 du foyer');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'paiement_saisi'),
  'saisie : inscrite au journal');

-- ------------------------------------------------------------------
-- 4. Lecture de la table
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000d1', 'guardian', 'fc000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai((SELECT count(*) FROM public.paiements_saisis) = 0, 'lecture : table illisible pour un tuteur');
SELECT pg_temp.qui('fc000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT pg_temp.vrai((SELECT count(*) FROM public.paiements_saisis) = 3, 'lecture : la comptabilite lit les saisies');
RESET ROLE;

\o
SELECT 'FAC-C paiements saisis : tous les controles sont verts' AS bilan;
ROLLBACK;
