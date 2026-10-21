-- FAC-B-01 (17/10/2026) : factures mensuelles et etat financier par profil.
-- Migrations 20261017170000 (FAC-A-01) et 20261017171000 (FAC-B-01).
--   1. emission : direction ou comptabilite seulement, mois courant ou
--      suivant, idempotente ; essai sans facture ; rangs du foyer et remise
--      (guide §1.3) ; prorata du premier mois (M x E / O) ; portefeuille cree ;
--   2. financement : en une fois si le solde du profil couvre (FIN4-09),
--      jamais partiel ; un paiement ulterieur finance a la prochaine emission ;
--   3. etats rendus au titulaire : finance (periode, prochain debit),
--      a regulariser ou expire (manque, fin de conservation), essai ;
--   4. une facture emise ne change plus et ne se supprime pas ; table
--      illisible hors direction et comptabilite.
-- Les etats « a regulariser » et « expire » dependent du jour du mois : le
-- scenario calcule l'attendu a partir de la date du jour.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

-- FAC-E-01 : ce scenario eprouve la politique v1 ; la v2 (en vigueur le
-- 1er novembre 2026) est retiree le temps du scenario, annule a la fin.
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
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

-- Le mois courant, le suivant, et la fin de conservation du mois courant.
CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
CREATE FUNCTION pg_temp.suivant() RETURNS date LANGUAGE sql AS
  $$ SELECT (pg_temp.mois() + interval '1 month')::date $$;
CREATE FUNCTION pg_temp.etat_impaye() RETURNS text LANGUAGE sql AS
  $$ SELECT CASE WHEN (now() AT TIME ZONE 'Europe/Paris')::date <= pg_temp.mois() + 7
                 THEN 'a_regulariser' ELSE 'expire' END $$;
-- La finance d'un profil, lue par le titulaire du foyer F1.
CREATE FUNCTION pg_temp.fin(p_profil uuid) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x FROM jsonb_array_elements(public.finances_foyer() -> 'profils') AS x
      WHERE x ->> 'profilId' = p_profil::text $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.mois(), pg_temp.suivant(), pg_temp.etat_impaye(),
  pg_temp.fin(uuid) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('fb000000-0000-4000-8000-0000000000a1','fb-admin@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000c1','fb-compta@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000b1','fb-ens@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000d1','fb-tit1@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000d2','fb-tit2@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e1','fb-e1@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e2','fb-e2@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e3','fb-e3@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e4','fb-e4@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e5','fb-e5@test.invalid'),
 ('fb000000-0000-4000-8000-0000000000e6','fb-e6@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('fb000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('fb000000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('fb000000-0000-4000-8000-0000000000a1','FB-ADM-0001','admin',NULL,'Direction','FB','active','female'),
 ('fb000000-0000-4000-8000-0000000000c1','FB-CPT-0001','accountant',NULL,'Compta','FB','active','male'),
 ('fb000000-0000-4000-8000-0000000000b1','FB-ENS-0001','teacher',NULL,'Maryam','FB','provisional_active','female'),
 ('fb000000-0000-4000-8000-0000000000d1','FB-TUT-0001','guardian','fb000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('fb000000-0000-4000-8000-0000000000d2','FB-TUT-0002','guardian','fb000000-0000-4000-8000-0000000000f2','Sara','F2','active','female'),
 ('fb000000-0000-4000-8000-0000000000e1','FB-ELV-0001','student','fb000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('fb000000-0000-4000-8000-0000000000e2','FB-ELV-0002','student','fb000000-0000-4000-8000-0000000000f1','Bilal','F1','active','male'),
 ('fb000000-0000-4000-8000-0000000000e3','FB-ELV-0003','student','fb000000-0000-4000-8000-0000000000f1','Nour','F1','active','female'),
 ('fb000000-0000-4000-8000-0000000000e4','FB-ELV-0004','student','fb000000-0000-4000-8000-0000000000f1','Hind','F1','active','female'),
 ('fb000000-0000-4000-8000-0000000000e5','FB-ELV-0005','student','fb000000-0000-4000-8000-0000000000f1','Ilyes','F1','active','male'),
 ('fb000000-0000-4000-8000-0000000000e6','FB-ELV-0006','student','fb000000-0000-4000-8000-0000000000f2','Adam','F2','active','male');
UPDATE public.households SET primary_guardian_id = 'fb000000-0000-4000-8000-0000000000d1'
 WHERE id = 'fb000000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = 'fb000000-0000-4000-8000-0000000000d2'
 WHERE id = 'fb000000-0000-4000-8000-0000000000f2';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('fb000000-0000-4000-8000-0000000000e1','minor','child'),
 ('fb000000-0000-4000-8000-0000000000e2','minor','standard'),
 ('fb000000-0000-4000-8000-0000000000e3','minor','standard'),
 ('fb000000-0000-4000-8000-0000000000e4','minor','standard'),
 ('fb000000-0000-4000-8000-0000000000e5','minor','standard'),
 ('fb000000-0000-4000-8000-0000000000e6','minor','standard');

INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fb000000-0000-4000-8000-000000000c01','fb000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour FB',1,9,'Europe/Paris'),
 ('fb000000-0000-4000-8000-000000000c02','fb000000-0000-4000-8000-0000000000b1','enfant',5,'Al-Fajr FB',1,12,'Europe/Paris');
-- Entres avant le mois, sauf Ilyes, entre au dixieme jour (prorata).
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT CASE WHEN e.id LIKE '%e6' THEN 'fb000000-0000-4000-8000-000000000c02'::uuid
            ELSE 'fb000000-0000-4000-8000-000000000c01'::uuid END, e.id::uuid,
       CASE WHEN e.id LIKE '%e5' THEN pg_temp.mois() + interval '9 days'
            ELSE pg_temp.mois() - interval '20 days' END
  FROM (VALUES ('fb000000-0000-4000-8000-0000000000e1'), ('fb000000-0000-4000-8000-0000000000e2'),
               ('fb000000-0000-4000-8000-0000000000e3'), ('fb000000-0000-4000-8000-0000000000e4'),
               ('fb000000-0000-4000-8000-0000000000e5'), ('fb000000-0000-4000-8000-0000000000e6')) AS e(id);
-- Quatre seances du mois par classe (jours 2, 7, 14, 21), une annulee (hors
-- du compte), et deux seances tenues le mois dernier : l'essai de Bilal (An-Nour)
-- et d'Adam (Al-Fajr, trois heures plus tard).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT s.id::uuid, 'fb000000-0000-4000-8000-0000000000b1', pg_temp.mois() + s.decalage,
       pg_temp.mois() + s.decalage + interval '1 hour', s.statut::public.session_status,
       'fb000000-0000-4000-8000-000000000c01'
  FROM (VALUES
    ('fb000000-0000-4000-8000-000000000501', interval '1 day 8 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000502', interval '6 days 8 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000503', interval '13 days 8 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000504', interval '20 days 8 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000505', interval '24 days 8 hours', 'canceled'),
    ('fb000000-0000-4000-8000-000000000506', interval '-10 days 8 hours', 'ended'),
    ('fb000000-0000-4000-8000-000000000507', interval '-5 days 8 hours', 'student_absent')) AS s(id, decalage, statut);
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT s.id::uuid, 'fb000000-0000-4000-8000-0000000000b1', pg_temp.mois() + s.decalage,
       pg_temp.mois() + s.decalage + interval '1 hour', s.statut::public.session_status,
       'fb000000-0000-4000-8000-000000000c02'
  FROM (VALUES
    ('fb000000-0000-4000-8000-000000000601', interval '1 day 11 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000602', interval '6 days 11 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000603', interval '13 days 11 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000604', interval '20 days 11 hours', 'planned'),
    ('fb000000-0000-4000-8000-000000000606', interval '-10 days 11 hours', 'ended'),
    ('fb000000-0000-4000-8000-000000000607', interval '-5 days 11 hours', 'ended')) AS s(id, decalage, statut);
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('fb000000-0000-4000-8000-000000000506','fb000000-0000-4000-8000-0000000000e2','student'),
 ('fb000000-0000-4000-8000-000000000507','fb000000-0000-4000-8000-0000000000e2','student'),
 ('fb000000-0000-4000-8000-000000000606','fb000000-0000-4000-8000-0000000000e6','student'),
 ('fb000000-0000-4000-8000-000000000607','fb000000-0000-4000-8000-0000000000e6','student');
-- Le foyer F1 a un portefeuille et des paiements confirmes ; F2 n'en a pas.
INSERT INTO public.wallets(id, household_id, currency) VALUES
 ('fb000000-0000-4000-8000-000000000901','fb000000-0000-4000-8000-0000000000f1','USD');
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le) VALUES
 ('fb000000-0000-4000-8000-000000000901',10000,'USD','credit','fb000000-0000-4000-8000-0000000000e1', now()),
 ('fb000000-0000-4000-8000-000000000901', 2000,'USD','credit','fb000000-0000-4000-8000-0000000000e4', now()),
 ('fb000000-0000-4000-8000-000000000901',10000,'USD','credit','fb000000-0000-4000-8000-0000000000e5', now());

-- ------------------------------------------------------------------
-- 1. Emission
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois(pg_temp.mois())$q$, '42501', 'emission : enseignant refuse');
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000d1', 'guardian', 'fb000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois(pg_temp.mois())$q$, '42501', 'emission : tuteur refuse');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e3') ->> 'etat' = 'essai'
  AND (pg_temp.fin('fb000000-0000-4000-8000-0000000000e3') ->> 'essaisUtilises')::int = 0,
  'avant emission : Nour en essai, 0 seance consommee');

SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois((pg_temp.mois() - interval '1 month')::date)$q$, '22023', 'emission : mois passe refuse');
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois((pg_temp.mois() + interval '2 months')::date)$q$, '22023', 'emission : mois trop lointain refuse');
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois(pg_temp.mois() + 3)$q$, '22023', 'emission : date qui n''est pas un premier du mois refusee');

SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000c1', 'accountant');
SELECT set_config('test.emission', public.emettre_factures_mois(pg_temp.mois())::text, true);
SELECT pg_temp.vrai((current_setting('test.emission')::jsonb ->> 'emises')::int = 5
  AND (current_setting('test.emission')::jsonb ->> 'financees')::int = 2,
  'emission : 5 factures (Nour en essai), 2 financees (Yasmine, Ilyes)');
SELECT pg_temp.vrai((public.emettre_factures_mois(pg_temp.mois()) ->> 'emises')::int = 0,
  'emission : relancer n''emet rien de plus (idempotente)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.factures_mensuelles WHERE household_id = 'fb000000-0000-4000-8000-0000000000f1') = 4,
  'emission : la comptabilite lit les factures');

SELECT pg_temp.vrai((SELECT rang_familial = 3 AND total_mineur = 4500
    AND lignes = '[{"nature":"tarif","montant":{"mineur":5000,"devise":"USD"},"rang":null},{"nature":"remise_rang","montant":{"mineur":-500,"devise":"USD"},"rang":3}]'::jsonb
    FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e4'),
  'facture : Hind, 3e membre payant, 50 - 5 = 45 USD (guide §1.3)');
-- O et E recomptes ici, independamment : l'adhesion cree aussi les seances a
-- venir de la classe (materialisation), elles comptent comme les autres.
SELECT set_config('test.o', (SELECT count(*) FROM public.sessions s
   WHERE s.groupe_id = 'fb000000-0000-4000-8000-000000000c01' AND s.deleted_at IS NULL
     AND s.status NOT IN ('canceled', 'canceled_late')
     AND s.started_at >= pg_temp.mois() AND s.started_at < pg_temp.suivant())::text, true);
SELECT set_config('test.e', (SELECT count(*) FROM public.sessions s
   WHERE s.groupe_id = 'fb000000-0000-4000-8000-000000000c01' AND s.deleted_at IS NULL
     AND s.status NOT IN ('canceled', 'canceled_late')
     AND s.started_at >= pg_temp.mois() + 9 AND s.started_at < pg_temp.suivant())::text, true);
SELECT pg_temp.vrai(current_setting('test.e')::int < current_setting('test.o')::int
  AND (SELECT rang_familial = 4
    AND total_mineur = 4300 * current_setting('test.e')::int / current_setting('test.o')::int
    AND lignes -> 2 ->> 'nature' = 'prorata'
    AND (lignes -> 2 #>> '{montant,mineur}')::bigint
        = 4300 * current_setting('test.e')::int / current_setting('test.o')::int - 4300
    FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e5'),
  'facture : Ilyes, 4e membre (43 USD), entre au dixieme jour : prorata 43 x E / O');
SELECT pg_temp.vrai((SELECT rang_familial = 2 AND total_mineur = 5000 AND jsonb_array_length(lignes) = 1
    FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e2'),
  'facture : Bilal, essai du mois dernier non refacture, mois plein');
SELECT pg_temp.vrai((SELECT rang_familial = 1 AND total_mineur = 5000
    FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e6'),
  'facture : Adam, premier payant de son foyer');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e3'),
  'facture : aucune pour Nour, en essai');
RESET ROLE;
SELECT pg_temp.vrai((SELECT currency FROM public.wallets WHERE household_id = 'fb000000-0000-4000-8000-0000000000f2') = 'USD',
  'emission : le portefeuille du foyer F2 est cree dans la devise de la politique');

-- ------------------------------------------------------------------
-- 2. Financement
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT statut = 'financee' AND debit_entry_id IS NOT NULL
    FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e1'),
  'financement : Yasmine financee par une ecriture de debit');
SELECT pg_temp.vrai((SELECT amount_minor = 5000 AND reference_type = 'debit'
    FROM public.wallet_entries WHERE id = (SELECT debit_entry_id FROM public.factures_mensuelles
                                            WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e1')),
  'financement : le debit vaut la facture, en une fois');
SELECT pg_temp.vrai((SELECT statut = 'a_financer' FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e4')
  AND NOT EXISTS (SELECT 1 FROM public.wallet_entries WHERE beneficiaire_id = 'fb000000-0000-4000-8000-0000000000e4'
                   AND reference_type = 'debit'),
  'financement : Hind (20 USD pour 45 dus) n''est pas debitee en partie (FIN4-09)');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000d1', 'guardian', 'fb000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') ->> 'etat' = 'finance'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{periode,debut}' = to_char(pg_temp.mois(), 'YYYY-MM-DD')
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{periode,fin}' = to_char(pg_temp.suivant() - 1, 'YYYY-MM-DD')
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{prochainDebit,date}' = to_char(pg_temp.suivant(), 'YYYY-MM-DD')
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{prochainDebit,montant,mineur}' = '5000'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{solde,mineur}' = '5000',
  'etat : Yasmine financee ce mois, prochain debit de 50 USD le premier du mois suivant, solde 50 USD');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') ->> 'etat' = pg_temp.etat_impaye()
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') #>> '{manque,mineur}' = '2500'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') ->> 'finConservation' = to_char(pg_temp.mois() + 7, 'YYYY-MM-DD')
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') #>> '{mensualite,mineur}' = '4500'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') -> 'lignesMensualite' -> 1 ->> 'rang' = '3'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') -> 'prochainDebit' = 'null'::jsonb,
  'etat : Hind, il manque 25 USD, place conservee 7 jours, mensualite 45 USD avec sa ligne de rang');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e3') ->> 'etat' = 'essai'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e3') -> 'periode' = 'null'::jsonb,
  'etat : Nour reste en essai, sans periode');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e5') -> 'lignesMensualite' -> 2 ->> 'nature' = 'prorata',
  'etat : Ilyes voit la ligne de prorata de son premier mois');
SELECT pg_temp.vrai((public.finances_foyer() #>> '{synthese,aPayerCeMois,mineur}')::int = 5000 + 2500,
  'synthese : il reste 75 USD a payer ce mois (Bilal 50, Hind 25)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.factures_mensuelles) = 0,
  'lecture : la table des factures est illisible pour un tuteur');
RESET ROLE;

-- Un paiement de 25 USD pour Hind : la prochaine emission la finance.
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le) VALUES
 ('fb000000-0000-4000-8000-000000000901',2500,'USD','credit','fb000000-0000-4000-8000-0000000000e4', now());
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai((public.emettre_factures_mois(pg_temp.mois()) ->> 'financees')::int = 1,
  'financement : le paiement complet de Hind finance sa facture');
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000d1', 'guardian', 'fb000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') ->> 'etat' = 'finance'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') -> 'manque' = 'null'::jsonb,
  'etat : Hind financee, plus de manque');

-- Le mois suivant : Yasmine (50 USD restants) se finance d'avance.
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai((public.emettre_factures_mois(pg_temp.suivant()) ->> 'emises')::int >= 4,
  'mois suivant : les factures sont emises');
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000d1', 'guardian', 'fb000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') ->> 'etat' = 'finance'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{periode,fin}'
      = to_char((pg_temp.suivant() + interval '1 month')::date - 1, 'YYYY-MM-DD')
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e1') #>> '{solde,mineur}' = '0',
  'etat : Yasmine financee jusqu''a la fin du mois suivant, solde 0 (FIN4-08 : l''acces tient a la periode)');
SELECT pg_temp.vrai(pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') ->> 'etat' = 'manque'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') #>> '{manque,mineur}' = '4500'
  AND pg_temp.fin('fb000000-0000-4000-8000-0000000000e4') #>> '{prochainDebit,date}' = to_char(pg_temp.suivant(), 'YYYY-MM-DD'),
  'etat : Hind financee ce mois, il manque 45 USD pour le mois suivant');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Immuabilite et ecritures directes
-- ------------------------------------------------------------------
SELECT pg_temp.refus($q$UPDATE public.factures_mensuelles SET total_mineur = 1 WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e2'$q$,
  '42501', 'immuable : le total d''une facture emise ne change pas');
SELECT pg_temp.refus($q$UPDATE public.factures_mensuelles SET statut = 'a_financer', financee_le = NULL, debit_entry_id = NULL WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e1' AND mois = pg_temp.mois()$q$,
  '42501', 'immuable : une facture financee ne redevient pas a financer');
SELECT pg_temp.refus($q$DELETE FROM public.factures_mensuelles WHERE profile_id = 'fb000000-0000-4000-8000-0000000000e2'$q$,
  '42501', 'immuable : une facture ne se supprime pas');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fb000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($q$INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, lignes, total_mineur) VALUES ('fb000000-0000-4000-8000-0000000000e3','fb000000-0000-4000-8000-0000000000f1', pg_temp.mois(), 'v1.0.0', 'USD', '[]', 0)$q$,
  '42501', 'ecriture directe : aucune facture ne s''insere hors de l''emission');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.emettre_factures_mois(pg_temp.mois())$q$, '42501', 'anon : emission sans EXECUTE');
RESET ROLE;

\o
SELECT 'FAC-B factures mensuelles : tous les controles sont verts' AS bilan;
ROLLBACK;
