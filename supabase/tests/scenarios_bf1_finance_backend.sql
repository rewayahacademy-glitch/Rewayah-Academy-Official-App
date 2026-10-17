-- BF1 (17/10/2026) : lectures finance hors administration et invitation du
-- comptable. Migrations 20261017160000, 20261017160100, 20261017160200.
--   1. revenus de l'enseignant connecte : valeurs lues dans la tresorerie,
--      remplacement, mois disponibles, regle absente ; un autre enseignant,
--      un tuteur, un compte desactive et anon sont refuses ;
--   2. finance par profil : ventilation (beneficiaire), remboursement qui
--      herite, solde, etats, synthese du foyer, mouvements, paiements ; le
--      second adulte, l'enfant, un autre foyer et anon sont refuses ;
--   3. invitation du comptable : aal2 exige, reponses metier, verification,
--      consommation unique a l'inscription, revocation, expiration ; un code
--      enseignant ne cree jamais un comptable.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL, p_aal text DEFAULT 'aal1')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', p_aal)::text
                ELSE pg_catalog.json_build_object('aal', p_aal, 'app_metadata',
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

-- Refus attendu : SQLSTATE exact (et message quand il est donne).
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR (p_message IS NOT NULL AND SQLERRM <> p_message) THEN
      RAISE EXCEPTION 'ROUGE : % (%, % au lieu de %, %)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('bf100000-0000-4000-8000-0000000000a1','bf1-admin@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000b1','bf1-ens1@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000b2','bf1-ens2@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000b3','bf1-ens3@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000d1','bf1-tit1@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000d2','bf1-second1@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000d3','bf1-tit2@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000e1','bf1-e1@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000e2','bf1-e2@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000e3','bf1-e3@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000e4','bf1-adulte@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000c1','bf1-candidat-cpt@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000c2','bf1-autre@test.invalid'),
 ('bf100000-0000-4000-8000-0000000000c3','bf1-candidat-ens@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('bf100000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('bf100000-0000-4000-8000-0000000000f2','Europe/Paris'),
 ('bf100000-0000-4000-8000-0000000000f3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('bf100000-0000-4000-8000-0000000000a1','BF1-ADM-0001','admin',NULL,'Direction','BF1','active','female'),
 ('bf100000-0000-4000-8000-0000000000b1','BF1-ENS-0001','teacher',NULL,'Maryam','BF1','provisional_active','female'),
 ('bf100000-0000-4000-8000-0000000000b2','BF1-ENS-0002','teacher',NULL,'Khadija','BF1','provisional_active','female'),
 ('bf100000-0000-4000-8000-0000000000b3','BF1-ENS-0003','teacher',NULL,'Desactive','BF1','disabled','female'),
 ('bf100000-0000-4000-8000-0000000000d1','BF1-TUT-0001','guardian','bf100000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('bf100000-0000-4000-8000-0000000000d2','BF1-TUT-0002','guardian','bf100000-0000-4000-8000-0000000000f1','Omar','F1','active','male'),
 ('bf100000-0000-4000-8000-0000000000d3','BF1-TUT-0003','guardian','bf100000-0000-4000-8000-0000000000f2','Sara','F2','active','female'),
 ('bf100000-0000-4000-8000-0000000000e1','BF1-ELV-0001','student','bf100000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('bf100000-0000-4000-8000-0000000000e2','BF1-ELV-0002','student','bf100000-0000-4000-8000-0000000000f1','Bilal','F1','active','male'),
 ('bf100000-0000-4000-8000-0000000000e3','BF1-ELV-0003','student','bf100000-0000-4000-8000-0000000000f2','Adam','F2','active','male'),
 ('bf100000-0000-4000-8000-0000000000e4','BF1-ELV-0004','student','bf100000-0000-4000-8000-0000000000f3','Hind','F3','active','female');
UPDATE public.households SET primary_guardian_id = 'bf100000-0000-4000-8000-0000000000d1'
 WHERE id = 'bf100000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = 'bf100000-0000-4000-8000-0000000000d3'
 WHERE id = 'bf100000-0000-4000-8000-0000000000f2';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, titulaire_profile_id) VALUES
 ('bf100000-0000-4000-8000-0000000000e1','minor','child',NULL),
 ('bf100000-0000-4000-8000-0000000000e2','minor','standard',NULL),
 ('bf100000-0000-4000-8000-0000000000e3','minor','standard',NULL),
 ('bf100000-0000-4000-8000-0000000000e4','autonomous','standard',NULL),
 ('bf100000-0000-4000-8000-0000000000d1','autonomous','standard','bf100000-0000-4000-8000-0000000000d1');

INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('bf100000-0000-4000-8000-000000000c01','bf100000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour BF1',1,9,'Europe/Paris'),
 ('bf100000-0000-4000-8000-000000000c02','bf100000-0000-4000-8000-0000000000b2','adulte',6,'Al-Fajr BF1',2,10,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES
 ('bf100000-0000-4000-8000-000000000c01','bf100000-0000-4000-8000-0000000000e1');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 ('bf100000-0000-4000-8000-000000000501','bf100000-0000-4000-8000-0000000000b1', now()-interval '3 hours', now()-interval '2 hours','planned','bf100000-0000-4000-8000-000000000c01'),
 ('bf100000-0000-4000-8000-000000000502','bf100000-0000-4000-8000-0000000000b1', now()-interval '5 hours', now()-interval '4 hours','planned','bf100000-0000-4000-8000-000000000c01'),
 ('bf100000-0000-4000-8000-000000000503','bf100000-0000-4000-8000-0000000000b1', now()-interval '7 hours', now()-interval '6 hours','planned','bf100000-0000-4000-8000-000000000c02'),
 ('bf100000-0000-4000-8000-000000000504','bf100000-0000-4000-8000-0000000000b2', now()-interval '9 hours', now()-interval '8 hours','planned','bf100000-0000-4000-8000-000000000c02'),
 ('bf100000-0000-4000-8000-000000000505','bf100000-0000-4000-8000-0000000000b1', now()-interval '62 days', now()-interval '62 days'+interval '1 hour','planned','bf100000-0000-4000-8000-000000000c01');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('bf100000-0000-4000-8000-000000000501','bf100000-0000-4000-8000-0000000000e1','student'),
 ('bf100000-0000-4000-8000-000000000501','bf100000-0000-4000-8000-0000000000e2','student'),
 ('bf100000-0000-4000-8000-000000000502','bf100000-0000-4000-8000-0000000000e1','student'),
 ('bf100000-0000-4000-8000-000000000503','bf100000-0000-4000-8000-0000000000e3','student');
-- Les durees financieres, par decision de reprise de la direction.
INSERT INTO public.tresorerie_a_reprendre(source_type, source_id, raison, decision_debut, decision_fin, decide_par, decide_le) VALUES
 ('prestation','bf100000-0000-4000-8000-000000000501','duree_indeterminee', now()-interval '3 hours', now()-interval '2 hours','bf100000-0000-4000-8000-0000000000a1', now()),
 ('prestation','bf100000-0000-4000-8000-000000000502','duree_indeterminee', now()-interval '5 hours', now()-interval '4 hours 30 minutes','bf100000-0000-4000-8000-0000000000a1', now()),
 ('prestation','bf100000-0000-4000-8000-000000000503','duree_indeterminee', now()-interval '7 hours 30 minutes', now()-interval '6 hours','bf100000-0000-4000-8000-0000000000a1', now());
-- Les remunerations dues, telles que remuneration_due_seance les ecrit.
INSERT INTO public.tresorerie_mouvements(coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref,
  survenu_le, source_type, regle, source_id) VALUES
 ('paie_a_decaisser','entree',400,'USD',400,'USD', now(),'prestation','remuneration_due','bf100000-0000-4000-8000-000000000501'),
 ('paie_a_decaisser','entree',200,'USD',200,'USD', now(),'prestation','remuneration_due','bf100000-0000-4000-8000-000000000502'),
 ('paie_a_decaisser','entree',600,'USD',600,'USD', now(),'prestation','remuneration_due','bf100000-0000-4000-8000-000000000503'),
 ('paie_a_decaisser','entree',999,'USD',999,'USD', now(),'prestation','remuneration_due','bf100000-0000-4000-8000-000000000504'),
 ('paie_a_decaisser','entree',300,'USD',300,'USD', now()-interval '62 days','prestation','remuneration_due','bf100000-0000-4000-8000-000000000505'),
 -- une autre ecriture de la meme seance (session_debit) ne compte pas
 ('fonds_clients_engages','sortie',5000,'USD',5000,'USD', now(),'prestation','session_debit','bf100000-0000-4000-8000-000000000501');
INSERT INTO public.regles_remuneration_enseignant(enseignant_id, taux_minor_par_heure, devise, date_effet, motif, cree_par)
VALUES (NULL, 400, 'USD', DATE '2026-01-01', 'BF1 taux global', 'bf100000-0000-4000-8000-0000000000a1');

-- ------------------------------------------------------------------
-- 1. Revenus de l'enseignant connecte
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;

SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000b1', 'teacher');
DO $revenus$
DECLARE r jsonb := public.mes_revenus_enseignant(NULL);
        c jsonb;
BEGIN
  PERFORM pg_temp.vrai(r ->> 'devise' = 'USD' AND r -> 'allocationInternet' = 'null'::jsonb,
    'revenus : devise USD, aucune aide Internet');
  PERFORM pg_temp.vrai(r #>> '{regle,base,mineur}' = '400' AND r #>> '{regle,plafond,mineur}' = '400',
    'revenus : base et plafond = taux de la regle en vigueur');
  PERFORM pg_temp.vrai(pg_catalog.jsonb_array_length(r -> 'classes') = 2, 'revenus : deux classes, rien de l''autre enseignant');
  c := r -> 'classes' -> 0;
  PERFORM pg_temp.vrai(c ->> 'classe' = 'Al-Fajr BF1' AND (c ->> 'enRemplacement')::boolean
    AND c ->> 'type' = 'adultes' AND (c ->> 'minutesAssurees')::int = 90 AND (c ->> 'capacite')::int = 6
    AND (c ->> 'siegesEligibles')::int = 1 AND c #>> '{montantEstime,mineur}' = '600'
    AND c #>> '{tauxHoraireEffectif,mineur}' = '400',
    'revenus : la seance assuree en remplacement, au taux de la classe');
  c := r -> 'classes' -> 1;
  PERFORM pg_temp.vrai(c ->> 'classe' = 'An-Nour BF1' AND NOT (c ->> 'enRemplacement')::boolean
    AND c ->> 'type' = 'enfants' AND (c ->> 'minutesAssurees')::int = 90 AND (c ->> 'siegesEligibles')::int = 2
    AND c #>> '{montantEstime,mineur}' = '600',
    'revenus : la classe titulaire, deux seances, deux eleves distincts');
  PERFORM pg_temp.vrai((r #>> '{total,minutesAssurees}')::int = 180 AND (r #>> '{total,capacite}')::int = 11
    AND (r #>> '{total,siegesEligibles}')::int = 3 AND r #>> '{total,tauxHoraireMoyen,mineur}' = '400'
    AND r #>> '{totalEstime,mineur}' = '1200',
    'revenus : total serveur (session_debit et autre mois exclus)');
END $revenus$;

SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.mes_revenus_mois_disponibles()) = 2
  AND public.mes_revenus_mois_disponibles() ->> 0 = pg_catalog.to_char(
        pg_catalog.date_trunc('month', pg_catalog.now() AT TIME ZONE 'Europe/Paris'), 'YYYY-MM-DD'),
  'revenus : mois en cours puis le mois de la seance passee');
SELECT pg_temp.vrai((public.mes_revenus_enseignant(
    (pg_catalog.date_trunc('month', (pg_catalog.now() - interval '62 days') AT TIME ZONE 'Europe/Paris'))::date)
    #>> '{totalEstime,mineur}') = '300',
  'revenus : le mois passe se relit');
SELECT pg_temp.vrai(public.mes_revenus_enseignant(DATE '2025-06-01') -> 'regle' = 'null'::jsonb
  AND pg_catalog.jsonb_array_length(public.mes_revenus_enseignant(DATE '2025-06-01') -> 'classes') = 0,
  'revenus : avant toute regle, regle nulle et aucune classe');

SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000b2', 'teacher');
SELECT pg_temp.vrai(public.mes_revenus_enseignant(NULL) #>> '{totalEstime,mineur}' = '999'
  AND pg_catalog.jsonb_array_length(public.mes_revenus_enseignant(NULL) -> 'classes') = 1,
  'revenus : l''autre enseignant ne voit que sa seance');

SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000b3', 'teacher');
SELECT pg_temp.refus('SELECT public.mes_revenus_enseignant(NULL)', '42501', NULL, 'revenus : compte desactive refuse');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000d1', 'guardian', 'bf100000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus('SELECT public.mes_revenus_enseignant(NULL)', '42501', NULL, 'revenus : tuteur refuse');
SELECT pg_temp.refus('SELECT public.mes_revenus_mois_disponibles()', '42501', NULL, 'mois disponibles : tuteur refuse');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus('SELECT public.mes_revenus_enseignant(NULL)', '42501', NULL, 'revenus : la direction passe par la tresorerie, pas par cette RPC');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000b1', NULL);
SELECT pg_temp.refus('SELECT public.mes_revenus_enseignant(NULL)', '42501', NULL, 'revenus : jeton sans role refuse');

RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus('SELECT public.mes_revenus_enseignant(NULL)', '42501', NULL, 'revenus : anon sans EXECUTE');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Finance par profil
-- ------------------------------------------------------------------
INSERT INTO public.wallets(id, household_id, currency) VALUES
 ('bf100000-0000-4000-8000-000000000901','bf100000-0000-4000-8000-0000000000f1','USD'),
 ('bf100000-0000-4000-8000-000000000903','bf100000-0000-4000-8000-0000000000f3','USD');
-- Foyer 1 : Yasmine (e1) credit confirme 5000, debit 1200, remboursement 1000
-- du credit (herite du beneficiaire) ; Bilal (e2) credit 3000 en confirmation
-- et correction -500 ; le titulaire (d1, profil adulte) debit 700 ; une
-- ecriture du foyer sans beneficiaire, credit confirme 1000.
INSERT INTO public.wallet_entries(id, wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le, created_at)
OVERRIDING SYSTEM VALUE VALUES
 (9100001,'bf100000-0000-4000-8000-000000000901',5000,'USD','credit','bf100000-0000-4000-8000-0000000000e1', now(), now()-interval '6 minutes'),
 (9100002,'bf100000-0000-4000-8000-000000000901',1200,'USD','debit','bf100000-0000-4000-8000-0000000000e1', NULL, now()-interval '5 minutes'),
 (9100003,'bf100000-0000-4000-8000-000000000901',3000,'USD','credit','bf100000-0000-4000-8000-0000000000e2', NULL, now()-interval '4 minutes'),
 (9100004,'bf100000-0000-4000-8000-000000000901',-500,'USD','adjustment','bf100000-0000-4000-8000-0000000000e2', NULL, now()-interval '3 minutes'),
 (9100005,'bf100000-0000-4000-8000-000000000901',700,'USD','debit','bf100000-0000-4000-8000-0000000000d1', NULL, now()-interval '2 minutes'),
 (9100006,'bf100000-0000-4000-8000-000000000901',1000,'USD','credit',NULL, now(), now()-interval '90 seconds'),
 (9100008,'bf100000-0000-4000-8000-000000000903',2000,'USD','credit','bf100000-0000-4000-8000-0000000000e4', now(), now()-interval '1 minute');
INSERT INTO public.wallet_entries(id, wallet_id, amount_minor, currency, reference_type, refund_of_entry_id, confirme_par_prestataire_le, created_at)
OVERRIDING SYSTEM VALUE VALUES
 (9100007,'bf100000-0000-4000-8000-000000000901',1000,'USD','refund',9100001, now(), now()-interval '30 seconds');

SELECT pg_temp.vrai((SELECT beneficiaire_id FROM public.wallet_entries WHERE id = 9100007)
  = 'bf100000-0000-4000-8000-0000000000e1', 'ventilation : le remboursement herite du beneficiaire du credit');
SELECT pg_temp.refus($q$INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id)
  VALUES ('bf100000-0000-4000-8000-000000000901',100,'USD','debit','bf100000-0000-4000-8000-0000000000e3')$q$,
  '23514', 'beneficiaire hors du foyer du portefeuille', 'ventilation : un eleve d''un autre foyer est refuse');
SELECT pg_temp.refus($q$INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id)
  VALUES ('bf100000-0000-4000-8000-000000000901',100,'USD','debit','bf100000-0000-4000-8000-0000000000d2')$q$,
  '23514', 'beneficiaire hors du foyer du portefeuille', 'ventilation : un adulte sans profil eleve est refuse');
SELECT pg_temp.refus($q$INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id)
  VALUES ('bf100000-0000-4000-8000-000000000901',100,'USD','payout','bf100000-0000-4000-8000-0000000000e1')$q$,
  '23514', 'un payout n''a pas de beneficiaire eleve', 'ventilation : payout sans beneficiaire eleve');
SELECT pg_temp.refus($q$INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, refund_of_entry_id, confirme_par_prestataire_le)
  VALUES ('bf100000-0000-4000-8000-000000000901',10,'USD','refund','bf100000-0000-4000-8000-0000000000e2',9100001, now())$q$,
  '23514', 'beneficiaire du remboursement different du credit', 'ventilation : remboursement impute a un autre profil refuse');

SET LOCAL ROLE authenticated;

-- Titulaire du foyer 1.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000d1', 'guardian', 'bf100000-0000-4000-8000-0000000000f1');
DO $foyer$
DECLARE r jsonb := public.finances_foyer();
        y jsonb; b jsonb; t jsonb;
BEGIN
  SELECT v INTO y FROM pg_catalog.jsonb_array_elements(r -> 'profils') v WHERE v ->> 'profilId' = 'bf100000-0000-4000-8000-0000000000e1';
  SELECT v INTO b FROM pg_catalog.jsonb_array_elements(r -> 'profils') v WHERE v ->> 'profilId' = 'bf100000-0000-4000-8000-0000000000e2';
  SELECT v INTO t FROM pg_catalog.jsonb_array_elements(r -> 'profils') v WHERE v ->> 'profilId' = 'bf100000-0000-4000-8000-0000000000d1';
  PERFORM pg_temp.vrai(pg_catalog.jsonb_array_length(r -> 'profils') = 3, 'foyer : trois profils eleves rendus');
  PERFORM pg_temp.vrai(y #>> '{solde,mineur}' = '2800' AND y ->> 'etat' = 'finance' AND y -> 'manque' = 'null'::jsonb
    AND y ->> 'classe' = 'An-Nour BF1' AND y ->> 'prenom' = 'Yasmine' AND NOT (y ->> 'estAdulte')::boolean,
    'foyer : Yasmine 5000 - 1200 - 1000 = 2800, finance');
  PERFORM pg_temp.vrai(b #>> '{solde,mineur}' = '-500' AND b ->> 'etat' = 'en_confirmation',
    'foyer : Bilal, credit non confirme exclu du solde, en confirmation');
  PERFORM pg_temp.vrai(t #>> '{solde,mineur}' = '-700' AND t ->> 'etat' = 'manque' AND t #>> '{manque,mineur}' = '700'
    AND (t ->> 'estAdulte')::boolean, 'foyer : le titulaire apprenant, manque 700');
  PERFORM pg_temp.vrai(y -> 'periode' = 'null'::jsonb AND y -> 'prochainDebit' = 'null'::jsonb
    AND pg_catalog.jsonb_array_length(y -> 'lignesMensualite') = 0 AND y #>> '{mensualite,mineur}' = '0',
    'foyer : aucune echeance inventee (periode, prochain debit, mensualite sans ligne)');
  PERFORM pg_temp.vrai(r #>> '{synthese,totalSoldes,mineur}' = '2600' AND r #>> '{synthese,aPayerCeMois,mineur}' = '700'
    AND (r #>> '{synthese,profilsFinances}')::int = 1 AND (r #>> '{synthese,profils}')::int = 3
    AND (r #>> '{synthese,paiementsDuMois}')::int = 2,
    'foyer : synthese serveur (ecriture du foyer comprise dans le total)');
END $foyer$;

SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e1')) = 3
  AND public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e1') #>> '{0,nature}' = 'remboursement'
  AND public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e1') #>> '{0,montant,mineur}' = '-1000'
  AND public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e1') #>> '{2,nature}' = 'recharge',
  'mouvements : trois ecritures de Yasmine, signees, la plus recente d''abord');
SELECT pg_temp.vrai(public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e2') #>> '{0,nature}' = 'correction'
  AND public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e2') #>> '{1,statut}' = 'en_confirmation',
  'mouvements : correction negative et credit en confirmation');
SELECT pg_temp.refus($q$SELECT public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e3')$q$, 'P0002', NULL,
  'mouvements : un eleve d''un autre foyer est introuvable');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.derniers_mouvements_foyer(3)) = 3
  AND public.derniers_mouvements_foyer(3) #>> '{0,prenom}' = 'Yasmine'
  AND public.derniers_mouvements_foyer(3) #>> '{1,prenom}' = 'Amina',
  'derniers mouvements : trois, tous profils, sans l''ecriture du foyer');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.paiements_foyer(NULL)) = 3
  AND public.paiements_foyer(NULL) #>> '{0,statut}' = 'confirme'
  AND public.paiements_foyer(NULL) #>> '{1,statut}' = 'en_confirmation'
  AND public.paiements_foyer(NULL) #>> '{1,montantMineur}' = '3000'
  AND NOT (public.paiements_foyer(NULL) #>> '{0,justificatifDisponible}')::boolean,
  'paiements : les trois credits du foyer, statut serveur, aucun justificatif');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.paiements_foyer(9100001)) = 1
  AND pg_catalog.jsonb_array_length(public.paiements_foyer(9100008)) = 0,
  'paiements : detail du foyer, jamais celui d''un autre');
SELECT pg_temp.vrai(public.mes_finances_eleve() ->> 'profilId' = 'bf100000-0000-4000-8000-0000000000d1'
  AND pg_catalog.jsonb_array_length(public.mes_mouvements_eleve(50)) = 1,
  'mes finances : le titulaire apprenant lit son seul profil');

-- Second adulte du foyer 1 : rien.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000d2', 'guardian', 'bf100000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', 'finances du foyer reservees au titulaire', 'second adulte : finances du foyer refusees');
SELECT pg_temp.refus($q$SELECT public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e1')$q$, '42501', NULL, 'second adulte : mouvements refuses');
SELECT pg_temp.refus('SELECT public.derniers_mouvements_foyer(3)', '42501', NULL, 'second adulte : derniers mouvements refuses');
SELECT pg_temp.refus('SELECT public.paiements_foyer(NULL)', '42501', NULL, 'second adulte : paiements refuses');
SELECT pg_temp.refus('SELECT public.mes_finances_eleve()', '42501', NULL, 'second adulte sans profil apprenant : refuse');

-- Enfant du foyer 1 : rien.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000e1', 'student', 'bf100000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus('SELECT public.mes_finances_eleve()', '42501', NULL, 'enfant : mes finances refusees');
SELECT pg_temp.refus('SELECT public.mes_mouvements_eleve(50)', '42501', NULL, 'enfant : mes mouvements refuses');
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', NULL, 'enfant : finances du foyer refusees');

-- Titulaire du foyer 2 (sans portefeuille) : rien du foyer 1.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000d3', 'guardian', 'bf100000-0000-4000-8000-0000000000f2');
SELECT pg_temp.vrai(public.finances_foyer() IS NULL, 'foyer sans portefeuille : nul');
SELECT pg_temp.refus($q$SELECT public.mouvements_profil_foyer('bf100000-0000-4000-8000-0000000000e1')$q$, 'P0002', NULL,
  'autre foyer : profil du foyer 1 introuvable');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.paiements_foyer(9100001)) = 0, 'autre foyer : aucun paiement du foyer 1');
-- Jeton qui pretend le foyer 1 sans en etre titulaire.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000d3', 'guardian', 'bf100000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', NULL, 'foyer pretendu : le titulaire est verifie en base');

-- Eleve adulte autonome (foyer 3).
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000e4', 'student', 'bf100000-0000-4000-8000-0000000000f3');
SELECT pg_temp.vrai(public.mes_finances_eleve() #>> '{solde,mineur}' = '2000'
  AND public.mes_finances_eleve() ->> 'etat' = 'finance'
  AND (public.mes_finances_eleve() ->> 'estAdulte')::boolean
  AND pg_catalog.jsonb_array_length(public.mes_mouvements_eleve(50)) = 1,
  'eleve adulte : son solde et ses mouvements');
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', NULL, 'eleve adulte : pas de vue foyer');
SELECT pg_temp.refus('SELECT public.paiements_foyer(NULL)', '42501', NULL, 'eleve adulte : pas de paiements du foyer');

-- Enseignant et role absent.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus('SELECT public.mes_finances_eleve()', '42501', NULL, 'enseignant : mes finances refusees');
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', NULL, 'enseignant : finances du foyer refusees');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000d1', NULL, 'bf100000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', NULL, 'jeton sans role : refuse');

RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus('SELECT public.finances_foyer()', '42501', NULL, 'anon : finances du foyer sans EXECUTE');
SELECT pg_temp.refus('SELECT public.mes_finances_eleve()', '42501', NULL, 'anon : mes finances sans EXECUTE');
SELECT pg_temp.refus('SELECT public.paiements_foyer(NULL)', '42501', NULL, 'anon : paiements sans EXECUTE');
RESET ROLE;

-- Une devise etrangere imputee : aucun change invente.
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id)
VALUES ('bf100000-0000-4000-8000-000000000903', 100, 'EUR', 'debit', 'bf100000-0000-4000-8000-0000000000e4');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000e4', 'student', 'bf100000-0000-4000-8000-0000000000f3');
SELECT pg_temp.refus('SELECT public.mes_finances_eleve()', '22023', 'finances du profil en plusieurs devises',
  'devise etrangere : refus explicite, aucun solde converti');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Invitation du comptable
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal1');
SELECT pg_temp.refus($q$SELECT public.inviter_comptable('bf1-candidat-cpt@test.invalid')$q$, '42501', NULL,
  'comptable : direction en aal1 refusee');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.vrai(public.inviter_comptable(' BF1-Candidat-Cpt@test.invalid ') ->> 'statut' = 'creee',
  'comptable : la direction en aal2 invite');
SELECT pg_temp.vrai(public.inviter_comptable('bf1-candidat-cpt@test.invalid') ->> 'statut' = 'deja_invite',
  'comptable : une seconde emission rend l''invitation active');
SELECT pg_temp.vrai(public.inviter_comptable('pas-une-adresse') ->> 'statut' = 'email_invalide', 'comptable : adresse invalide');
SELECT pg_temp.vrai(public.inviter_comptable('bf1-ens1@test.invalid') ->> 'statut' = 'compte_existant', 'comptable : compte existant');
SELECT pg_temp.vrai(public.inviter_comptable('bf1-autre@test.invalid') ->> 'statut' = 'creee', 'comptable : seconde invitation (a revoquer)');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(public.invitations_comptable_admin()) = 2
  AND public.invitations_comptable_admin() #>> '{0,etat}' = 'active', 'comptable : la direction liste');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000b1', 'teacher', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.inviter_comptable('x@test.invalid')$q$, '42501', NULL, 'comptable : un enseignant n''invite pas');
SELECT pg_temp.refus('SELECT public.invitations_comptable_admin()', '42501', NULL, 'comptable : un enseignant ne liste pas');
SELECT pg_temp.refus($q$SELECT public.revoquer_invitation_comptable('AAAA-AAAA-AAAA')$q$, '42501', NULL, 'comptable : un enseignant ne revoque pas');
SELECT pg_temp.vrai((SELECT count(*) FROM public.invitations_comptable) = 0, 'comptable : la table reste fermee hors direction');
RESET ROLE;

-- Une invitation enseignant, pour prouver l'etancheite des deux portes.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT public.inviter_enseignant('bf1-candidat-cpt@test.invalid');
RESET ROLE;
SELECT pg_catalog.set_config('test.code_cpt',
  (SELECT code FROM public.invitations_comptable WHERE email = 'bf1-candidat-cpt@test.invalid'), true);
SELECT pg_catalog.set_config('test.code_ens',
  (SELECT code FROM public.invitations_enseignant WHERE email = 'bf1-candidat-cpt@test.invalid'), true);
SELECT pg_catalog.set_config('test.code_autre',
  (SELECT code FROM public.invitations_comptable WHERE email = 'bf1-autre@test.invalid'), true);

SET LOCAL ROLE authenticated;
-- Une autre session ne peut pas se servir du code.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000c3', NULL);
SELECT pg_temp.vrai(public.verifier_invitation_comptable(current_setting('test.code_cpt')) ->> 'resultat' = 'inconnue',
  'comptable : code d''une autre adresse inconnu');
SELECT pg_temp.vrai(public.inscrire_comptable_invite(current_setting('test.code_cpt'), 'X', 'Y') ->> 'resultat' = 'inconnue',
  'comptable : inscription avec le code d''une autre adresse refusee');
-- Le candidat.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000c1', NULL);
SELECT pg_temp.vrai(public.verifier_invitation_comptable(lower(current_setting('test.code_cpt'))) ->> 'resultat' = 'valide',
  'comptable : le candidat verifie son code');
SELECT pg_temp.vrai(public.inscrire_comptable_invite(current_setting('test.code_ens'), 'Nadia', 'BF1') ->> 'resultat' = 'inconnue',
  'comptable : un code enseignant ne cree pas de comptable');
SELECT pg_temp.vrai(public.inscrire_comptable_invite(current_setting('test.code_cpt'), 'Nadia', 'BF1', 'female') ->> 'resultat' = 'consommee',
  'comptable : inscription sur invitation');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = 'bf100000-0000-4000-8000-0000000000c1'
    AND p.role = 'accountant' AND p.account_status = 'active' AND p.household_id IS NULL AND p.immutable_id IS NOT NULL)
  AND NOT EXISTS (SELECT 1 FROM public.teacher_profiles t WHERE t.profile_id = 'bf100000-0000-4000-8000-0000000000c1')
  AND (SELECT utilisee_par FROM public.invitations_comptable WHERE email = 'bf1-candidat-cpt@test.invalid')
      = 'bf100000-0000-4000-8000-0000000000c1'
  AND (SELECT utilisee_le FROM public.invitations_enseignant WHERE email = 'bf1-candidat-cpt@test.invalid') IS NULL,
  'comptable : profil accountant actif sans foyer, invitation consommee, invitation enseignant intacte');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000c1', NULL);
SELECT pg_temp.refus($q$SELECT public.inscrire_comptable_invite(current_setting('test.code_cpt'), 'Nadia', 'BF1')$q$, '42501', NULL,
  'comptable : une seconde inscription est refusee (profil existant)');
SELECT pg_temp.vrai(public.verifier_invitation_comptable(current_setting('test.code_cpt')) ->> 'resultat' = 'deja_utilisee',
  'comptable : le code consomme se dit deja utilise');
-- Revocation puis expiration.
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal1');
SELECT public.revoquer_invitation_comptable(current_setting('test.code_autre'));
SELECT pg_temp.refus($q$SELECT public.revoquer_invitation_comptable('AAAA-AAAA-AAAA')$q$, 'P0002', NULL, 'comptable : code inconnu a la revocation');
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000c2', NULL);
SELECT pg_temp.vrai(public.verifier_invitation_comptable(current_setting('test.code_autre')) ->> 'resultat' = 'inconnue',
  'comptable : un code revoque se dit inconnu');
SELECT pg_temp.vrai(public.inscrire_comptable_invite(current_setting('test.code_autre'), 'A', 'B') ->> 'resultat' = 'inconnue',
  'comptable : un code revoque ne cree rien');
RESET ROLE;
UPDATE public.invitations_comptable SET revoquee_le = NULL, revoquee_par = NULL,
  cree_le = now() - interval '30 days', expire_le = now() - interval '1 day'
 WHERE email = 'bf1-autre@test.invalid';
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('bf100000-0000-4000-8000-0000000000c2', NULL);
SELECT pg_temp.vrai(public.verifier_invitation_comptable(current_setting('test.code_autre')) ->> 'resultat' = 'expiree',
  'comptable : un code expire se dit expire');
SELECT pg_temp.vrai(public.inscrire_comptable_invite(current_setting('test.code_autre'), 'A', 'B') ->> 'resultat' = 'expiree',
  'comptable : un code expire ne cree rien');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'bf100000-0000-4000-8000-0000000000c2'),
  'comptable : aucun profil cree par un code revoque ou expire');

SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.inscrire_comptable_invite('AAAA-AAAA-AAAA', 'A', 'B')$q$, '42501', NULL, 'anon : inscription comptable sans EXECUTE');
SELECT pg_temp.refus($q$SELECT public.inviter_comptable('a@b.cd')$q$, '42501', NULL, 'anon : invitation sans EXECUTE');
RESET ROLE;

\o
SELECT 'BF1 finance backend : tous les controles sont verts' AS bilan;
ROLLBACK;
