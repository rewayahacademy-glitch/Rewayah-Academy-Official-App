-- FAC-E-01 (18/10/2026) : les tarifs du 18/10 dans l'application.
-- Migrations 20261018120000 et 20261019130000 (paie a 47 % du prix, 19/10).
-- Valeurs : docs/current/tarifs-2026-10-18.json.
--   1. politique v2.0.0 : 55 et 65 USD, sans essai, remises de rang en pour
--      mille, paie par eleve present, prepaiement, bourse, parrainage ; elle
--      se relit telle quelle (contrat) ;
--   2. factures : fratrie 55 ; 50,60 ; 45,65 (151,25) ; couple d'adultes
--      65 + 59,80 (124,80) ; bourse -30 % seule, jamais avec le rang ;
--   3. prix payes d'avance : 157, 594, 185, 702 USD ; plafond de cumul 25 % ;
--   4. bourses : direction seule, une par eleve, places limitees, retrait ;
--   5. parrainage : 20 USD a chacun des deux foyers apres le premier mois
--      finance du filleul, une seule fois ;
--   6. recharge : trimestre et annee proposes une fois le mois regle ; payes
--      par le prestataire, ils ouvrent l'engagement du mois suivant, dont
--      chaque facture prend sa part.
-- Le scenario met la v2 en vigueur ce mois-ci (la vraie date d'effet est le
-- 1er novembre 2026) ; tout est annule a la fin.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
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

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
CREATE FUNCTION pg_temp.suivant() RETURNS date LANGUAGE sql AS
  $$ SELECT (pg_temp.mois() + interval '1 month')::date $$;
-- La facture d'un profil pour un mois (lue par le proprietaire).
CREATE FUNCTION pg_temp.fac(p_profil text, p_mois date) RETURNS public.factures_mensuelles LANGUAGE sql AS
  $$ SELECT f.* FROM public.factures_mensuelles f
      WHERE f.profile_id = ('fe000000-0000-4000-8000-0000000000' || p_profil)::uuid AND f.mois = p_mois $$;
-- Les formules proposees a un profil, lues par le titulaire connecte.
CREATE FUNCTION pg_temp.formules(p_profil text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x -> 'formules' FROM jsonb_array_elements(public.recharge_beneficiaires()) AS x
      WHERE x ->> 'id' = 'fe000000-0000-4000-8000-0000000000' || p_profil $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.mois(), pg_temp.suivant(), pg_temp.formules(text)
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
--   F1 : trois enfants (e1, e2, e3)  F2 : deux adultes (e4, e5)
--   F3 : deux enfants (e6, e7 boursier)  F4 : un enfant (e8), filleul de F1
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT ('fe000000-0000-4000-8000-0000000000' || x)::uuid, 'fe-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','d1','d2','d3','d4','e1','e2','e3','e4','e5','e6','e7','e8']) AS x;
INSERT INTO public.households(id, timezone)
SELECT ('fe000000-0000-4000-8000-0000000000' || x)::uuid, 'Europe/Paris'
  FROM unnest(ARRAY['f1','f2','f3','f4']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('fe000000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE ('fe000000-0000-4000-8000-0000000000' || x.foyer)::uuid END,
       x.prenom, 'FE', x.statut::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','FE-ADM-0001','admin',NULL,'Direction','active','female'),
   ('b1','FE-ENS-0001','teacher',NULL,'Maryam','provisional_active','female'),
   ('d1','FE-TUT-0001','guardian','f1','Amina','active','female'),
   ('d2','FE-TUT-0002','guardian','f2','Awa','active','female'),
   ('d3','FE-TUT-0003','guardian','f3','Fatou','active','female'),
   ('d4','FE-TUT-0004','guardian','f4','Mariam','active','female'),
   ('e1','FE-ELV-0001','student','f1','Yasmine','active','female'),
   ('e2','FE-ELV-0002','student','f1','Bilal','active','male'),
   ('e3','FE-ELV-0003','student','f1','Nour','active','female'),
   ('e4','FE-ELV-0004','student','f2','Aicha','active','female'),
   ('e5','FE-ELV-0005','student','f2','Khadija','active','female'),
   ('e6','FE-ELV-0006','student','f3','Omar','active','male'),
   ('e7','FE-ELV-0007','student','f3','Issa','active','male'),
   ('e8','FE-ELV-0008','student','f4','Adam','active','male')) AS x(id, mat, role, foyer, prenom, statut, genre);
UPDATE public.households h SET primary_guardian_id = ('fe000000-0000-4000-8000-0000000000d' || right(h.id::text, 1))::uuid
 WHERE h.id IN ('fe000000-0000-4000-8000-0000000000f1','fe000000-0000-4000-8000-0000000000f2',
                'fe000000-0000-4000-8000-0000000000f3','fe000000-0000-4000-8000-0000000000f4');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT ('fe000000-0000-4000-8000-0000000000' || x)::uuid,
       (CASE WHEN x IN ('e4','e5') THEN 'autonomous' ELSE 'minor' END)::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7','e8']) AS x;

INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fe000000-0000-4000-8000-000000000c01','fe000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour FE',1,9,'Europe/Paris'),
 ('fe000000-0000-4000-8000-000000000c02','fe000000-0000-4000-8000-0000000000b1','enfant',5,'Al-Fajr FE',2,9,'Europe/Paris'),
 ('fe000000-0000-4000-8000-000000000c03','fe000000-0000-4000-8000-0000000000b1','adulte',6,'Al-Huda FE',3,20,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT ('fe000000-0000-4000-8000-000000000c0' || x.g)::uuid, ('fe000000-0000-4000-8000-0000000000' || x.e)::uuid,
       pg_temp.mois() - interval '20 days'
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('3','e4'),('3','e5'),('2','e6'),('2','e7'),('2','e8')) AS x(g, e);
-- Une seance tenue dans le mois par classe : pas de prorata (tous entres avant).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT ('fe000000-0000-4000-8000-00000000050' || g)::uuid, 'fe000000-0000-4000-8000-0000000000b1',
       pg_temp.mois() + interval '14 days' + g::int * interval '2 hours',
       pg_temp.mois() + interval '14 days 1 hour' + g::int * interval '2 hours', 'planned',
       ('fe000000-0000-4000-8000-000000000c0' || g)::uuid
  FROM unnest(ARRAY['1','2','3']) AS g;
-- Le filleul F4 a deja de quoi payer son premier mois.
INSERT INTO public.wallets(id, household_id, currency) VALUES
 ('fe000000-0000-4000-8000-000000000904','fe000000-0000-4000-8000-0000000000f4','USD');
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le) VALUES
 ('fe000000-0000-4000-8000-000000000904', 6000,'USD','credit','fe000000-0000-4000-8000-0000000000e8', now());

-- ------------------------------------------------------------------
-- 1. La politique v2.0.0
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.p', public.politique_commerciale_active()::text, true);
SELECT pg_temp.vrai(current_setting('test.p')::jsonb ->> 'version' = 'v2.0.0'
  AND current_setting('test.p')::jsonb -> 'tarifEnfant' = '{"mineur":5500,"devise":"USD"}'::jsonb
  AND current_setting('test.p')::jsonb -> 'tarifAdulte' = '{"mineur":6500,"devise":"USD"}'::jsonb
  AND (current_setting('test.p')::jsonb ->> 'essaiActif')::boolean = false
  AND (current_setting('test.p')::jsonb ->> 'essaisMax')::int = 0
  AND (current_setting('test.p')::jsonb ->> 'minimumOuverture')::int = 3
  AND (current_setting('test.p')::jsonb ->> 'joursConservationPlace')::int = 14
  AND current_setting('test.p')::jsonb -> 'joursRelance' = '[7,3,1]'::jsonb,
  'politique : v2.0.0, 55 et 65 USD, sans essai, groupe a 3, place gardee 14 jours, relances J-7 J-3 J-1');
SELECT pg_temp.vrai(current_setting('test.p')::jsonb -> 'remisesParRang'
    = '[{"aPartirDuRang":2,"pourMille":80},{"aPartirDuRang":3,"pourMille":170}]'::jsonb,
  'politique : -8 % au 2e membre, -17 % au 3e et suivants');
SELECT pg_temp.vrai(current_setting('test.p')::jsonb -> 'tauxEleveHeureEnfant' = '{"mineur":199,"devise":"USD"}'::jsonb
  AND current_setting('test.p')::jsonb -> 'tauxEleveHeureAdulte' = '{"mineur":157,"devise":"USD"}'::jsonb
  AND current_setting('test.p')::jsonb -> 'plafondEleveHeureEnfant' = '{"mineur":199,"devise":"USD"}'::jsonb
  AND current_setting('test.p')::jsonb -> 'plafondEleveHeureAdulte' = '{"mineur":157,"devise":"USD"}'::jsonb
  AND (current_setting('test.p')::jsonb ->> 'dureeDueEnfantMinutes')::int = 45
  AND (current_setting('test.p')::jsonb ->> 'dureeDueAdulteMinutes')::int = 70,
  'politique : paie 1,99 et 1,57 USD par eleve present et par heure (47 % du prix), plafond egal au taux, seance due a 45 et 70 min');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                                 WHERE c.conname = 'politiques_commerciales_taux_enfant_sous_adulte'),
  'politique : le taux enfant peut depasser le taux adulte (meme part du prix, 19/10)');
SELECT pg_temp.vrai((current_setting('test.p')::jsonb ->> 'prepaiementTrimestrielPourMille')::int = 50
  AND (current_setting('test.p')::jsonb ->> 'prepaiementAnnuelPourMille')::int = 100
  AND current_setting('test.p')::jsonb -> 'parrainageCredit' = '{"mineur":2000,"devise":"USD"}'::jsonb
  AND (current_setting('test.p')::jsonb ->> 'boursePourMille')::int = 300
  AND (current_setting('test.p')::jsonb ->> 'boursePlacesPourMille')::int = 50
  AND (current_setting('test.p')::jsonb ->> 'bourseDureeMois')::int = 6
  AND (current_setting('test.p')::jsonb ->> 'cumulMaxPourMille')::int = 250
  AND (current_setting('test.p')::jsonb ->> 'jourSuspension')::int = 4,
  'politique : prepaiement 5 et 10 %, parrainage 20 USD, bourse 30 % (5 % des eleves, 6 mois), cumul 25 %, suspension le 4');
SELECT pg_temp.vrai(public.politiques_commerciales_versions() -> 0 ->> 'version' = 'v2.1.0'
  AND public.politiques_commerciales_versions() -> 0 -> 'remisesParRang' = current_setting('test.p')::jsonb -> 'remisesParRang'
  AND public.politiques_commerciales_versions() -> 0 -> 'tauxEleveHeureEnfant' = current_setting('test.p')::jsonb -> 'tauxEleveHeureEnfant',
  'brouillon : le suivant (v2.1.0) repart de la v2, remises en pour mille et paie comprises');
SELECT pg_temp.vrai(public.apercu_politique_famille(current_setting('test.p')::jsonb, 3) -> 'total' = '{"mineur":15125,"devise":"USD"}'::jsonb
  AND public.apercu_politique_famille(current_setting('test.p')::jsonb, 3) #> '{enfants,1,remise}' = '{"mineur":-440,"devise":"USD"}'::jsonb,
  'apercu : trois enfants 151,25 USD, -8 % au 2e');
RESET ROLE;
SELECT pg_temp.vrai((SELECT (l.remises_par_rang, l.taux_eleve_heure_enfant_mineur, l.taux_eleve_heure_adulte_mineur,
           l.plafond_eleve_heure_enfant_mineur, l.plafond_eleve_heure_adulte_mineur, l.duree_due_enfant_minutes,
           l.duree_due_adulte_minutes, l.prepaiement_trimestriel_pour_mille, l.prepaiement_annuel_pour_mille,
           l.parrainage_credit_mineur, l.bourse_pour_mille, l.bourse_places_pour_mille, l.bourse_duree_mois,
           l.cumul_max_pour_mille, l.jour_suspension, l.essai_actif, l.jours_relance)
        = (p.remises_par_rang, p.taux_eleve_heure_enfant_mineur, p.taux_eleve_heure_adulte_mineur,
           p.plafond_eleve_heure_enfant_mineur, p.plafond_eleve_heure_adulte_mineur, p.duree_due_enfant_minutes,
           p.duree_due_adulte_minutes, p.prepaiement_trimestriel_pour_mille, p.prepaiement_annuel_pour_mille,
           p.parrainage_credit_mineur, p.bourse_pour_mille, p.bourse_places_pour_mille, p.bourse_duree_mois,
           p.cumul_max_pour_mille, p.jour_suspension, p.essai_actif, p.jours_relance)
      FROM public.politiques_commerciales p,
           LATERAL private.fac_politique_lue(private.fac_politique_json(p, 'publiee')) l
     WHERE p.version = 'v2.0.0'),
  'contrat : la v2 relue depuis son JSON est identique');
SELECT pg_temp.refus($q$SELECT private.fac_politique_lue(jsonb_set(private.fac_politique_json(p, 'publiee'),
    '{remisesParRang}', '[{"aPartirDuRang":2,"pourMille":1200}]'))
    FROM public.politiques_commerciales p WHERE version = 'v2.0.0'$q$, '22023', 'contrat : une remise de plus de 100 % est refusee');
SELECT pg_temp.refus($q$SELECT private.fac_politique_lue(jsonb_set(private.fac_politique_json(p, 'publiee'),
    '{remisesParRang}', '[{"aPartirDuRang":2,"pourMille":80,"remise":{"mineur":-500,"devise":"USD"}}]'))
    FROM public.politiques_commerciales p WHERE version = 'v2.0.0'$q$, '22023', 'contrat : une remise a la fois en montant et en pour mille est refusee');

-- ------------------------------------------------------------------
-- 4. Bourses (avant l'emission, pour le mois courant)
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.accorder_bourse('fe000000-0000-4000-8000-0000000000e7', 'Famille en difficulte')$q$,
  '42501', 'bourse : un enseignant n''accorde rien');
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000d3', 'guardian', 'fe000000-0000-4000-8000-0000000000f3');
SELECT pg_temp.refus($q$SELECT public.accorder_bourse('fe000000-0000-4000-8000-0000000000e7', 'Famille en difficulte')$q$,
  '42501', 'bourse : un tuteur ne s''accorde rien');
SELECT pg_temp.refus($q$SELECT count(*) FROM public.bourses_eleves$q$, '42501', 'bourse : table illisible pour un tuteur');
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($q$SELECT public.accorder_bourse('fe000000-0000-4000-8000-0000000000e7', '  ')$q$,
  '22023', 'bourse : motif obligatoire');
SELECT pg_temp.refus($q$SELECT public.accorder_bourse('fe000000-0000-4000-8000-0000000000d3', 'Famille en difficulte')$q$,
  '22023', 'bourse : seulement pour un profil eleve');
SELECT set_config('test.b', public.accorder_bourse('fe000000-0000-4000-8000-0000000000e7', 'Famille en difficulte')::text, true);
SELECT pg_temp.vrai((current_setting('test.b')::jsonb ->> 'pourMille')::int = 300
  AND (current_setting('test.b')::jsonb ->> 'moisDebut')::date = pg_temp.mois()
  AND (current_setting('test.b')::jsonb ->> 'moisFin')::date = (pg_temp.mois() + interval '5 months')::date
  AND current_setting('test.b')::jsonb ->> 'matricule' = 'FE-ELV-0007',
  'bourse : -30 % pour six mois, du mois courant au sixieme');
SELECT pg_temp.refus($q$SELECT public.accorder_bourse('fe000000-0000-4000-8000-0000000000e7', 'Encore')$q$,
  'BO002', 'bourse : une seule par eleve');
SELECT pg_temp.refus($q$SELECT public.accorder_bourse('fe000000-0000-4000-8000-0000000000e1', 'Autre famille')$q$,
  'BO001', 'bourse : 5 % des eleves au plus (8 eleves : une place)');
SELECT pg_temp.vrai(jsonb_array_length(public.bourses_lister()) = 1, 'bourse : la direction liste les bourses actives');

-- ------------------------------------------------------------------
-- 5. Parrainage (note avant le premier mois du filleul)
-- ------------------------------------------------------------------
SELECT pg_temp.refus($q$SELECT public.enregistrer_parrainage('fe000000-0000-4000-8000-0000000000f1', 'fe000000-0000-4000-8000-0000000000f1')$q$,
  '22023', 'parrainage : un foyer ne se parraine pas');
SELECT public.enregistrer_parrainage('fe000000-0000-4000-8000-0000000000f1', 'fe000000-0000-4000-8000-0000000000f4');
SELECT pg_temp.refus($q$SELECT public.enregistrer_parrainage('fe000000-0000-4000-8000-0000000000f2', 'fe000000-0000-4000-8000-0000000000f4')$q$,
  '22023', 'parrainage : un seul parrain par foyer');
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000d1', 'guardian', 'fe000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.enregistrer_parrainage('fe000000-0000-4000-8000-0000000000f1', 'fe000000-0000-4000-8000-0000000000f3')$q$,
  '42501', 'parrainage : note par la direction seulement');

-- ------------------------------------------------------------------
-- 2. Factures du mois
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.em', public.emettre_factures_mois(pg_temp.mois())::text, true);
SELECT pg_temp.vrai((current_setting('test.em')::jsonb ->> 'emises')::int = 8,
  'emission : huit factures, aucun essai');
RESET ROLE;
SELECT pg_temp.vrai((pg_temp.fac('e1', pg_temp.mois())).total_mineur = 5500
  AND (pg_temp.fac('e2', pg_temp.mois())).total_mineur = 5060
  AND (pg_temp.fac('e3', pg_temp.mois())).total_mineur = 4565
  AND (pg_temp.fac('e2', pg_temp.mois())).lignes = '[{"nature":"tarif","montant":{"mineur":5500,"devise":"USD"},"rang":null},{"nature":"remise_rang","montant":{"mineur":-440,"devise":"USD"},"rang":2}]'::jsonb
  AND (pg_temp.fac('e3', pg_temp.mois())).lignes -> 1 = '{"nature":"remise_rang","montant":{"mineur":-935,"devise":"USD"},"rang":3}'::jsonb,
  'fratrie : 55 ; 50,60 (-8 %) ; 45,65 (-17 %)');
SELECT pg_temp.vrai((SELECT sum(total_mineur) FROM public.factures_mensuelles
                      WHERE household_id = 'fe000000-0000-4000-8000-0000000000f1' AND mois = pg_temp.mois()) = 15125
  AND (SELECT sum(total_mineur) FROM public.factures_mensuelles
                      WHERE household_id = 'fe000000-0000-4000-8000-0000000000f1' AND mois = pg_temp.mois()
                        AND rang_familial <= 2) = 10560,
  'fratrie : deux enfants 105,60 USD, trois enfants 151,25 USD (document du 18/10)');
SELECT pg_temp.vrai((pg_temp.fac('e4', pg_temp.mois())).total_mineur + (pg_temp.fac('e5', pg_temp.mois())).total_mineur = 12480
  AND (pg_temp.fac('e5', pg_temp.mois())).total_mineur = 5980,
  'couple d''adultes : 65 + 59,80 = 124,80 USD');
SELECT pg_temp.vrai((pg_temp.fac('e7', pg_temp.mois())).total_mineur = 3850
  AND (pg_temp.fac('e7', pg_temp.mois())).rang_familial = 2
  AND (pg_temp.fac('e7', pg_temp.mois())).lignes = '[{"nature":"tarif","montant":{"mineur":5500,"devise":"USD"},"rang":null},{"nature":"bourse","montant":{"mineur":-1650,"devise":"USD"},"rang":null}]'::jsonb,
  'bourse : 55 - 30 % = 38,50 USD, jamais cumulee avec la remise du 2e membre');

-- ------------------------------------------------------------------
-- 5 bis. Le premier mois du filleul est finance : les deux foyers recoivent 20 USD
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((pg_temp.fac('e8', pg_temp.mois())).statut = 'financee'
  AND (SELECT credite_le IS NOT NULL FROM public.parrainages WHERE filleul_household_id = 'fe000000-0000-4000-8000-0000000000f4')
  AND (SELECT count(*) FROM public.wallet_entries
        WHERE reference_type = 'credit' AND amount_minor = 2000
          AND beneficiaire_id IN ('fe000000-0000-4000-8000-0000000000e1', 'fe000000-0000-4000-8000-0000000000e8')) = 2,
  'parrainage : 20 USD de credit au parrain et au filleul apres le premier mois finance');
SELECT private.fac_crediter_parrainage('fe000000-0000-4000-8000-0000000000f4');
SELECT pg_temp.vrai((SELECT count(*) FROM public.wallet_entries WHERE reference_type = 'credit' AND amount_minor = 2000
          AND beneficiaire_id IN ('fe000000-0000-4000-8000-0000000000e1', 'fe000000-0000-4000-8000-0000000000e8')) = 2,
  'parrainage : credite une seule fois');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($q$SELECT public.enregistrer_parrainage('fe000000-0000-4000-8000-0000000000f3', 'fe000000-0000-4000-8000-0000000000f4')$q$,
  '22023', 'parrainage : refuse quand le filleul a deja un mois finance');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Prix payes d'avance
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e1', pg_temp.suivant(), 3) = 15700
  AND private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e1', pg_temp.suivant(), 12) = 59400
  AND private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e4', pg_temp.suivant(), 3) = 18500
  AND private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e4', pg_temp.suivant(), 12) = 70200,
  'prepaiement : enfant 157 et 594 USD, adulte 185 et 702 USD');
SELECT pg_temp.vrai(private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e3', pg_temp.mois(), 3) = 12900
  AND private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e3', pg_temp.mois(), 12) = 49500,
  'prepaiement : 3e membre, -17 % puis -5 % (129 USD) ; a l''annee le cumul est borne a 25 % (495 USD)');
SELECT pg_temp.vrai(private.fac_prix_prepaiement('fe000000-0000-4000-8000-0000000000e7', pg_temp.suivant(), 3) IS NULL,
  'prepaiement : jamais propose a un boursier (non cumulable)');

-- ------------------------------------------------------------------
-- 6. Recharge : le mois d'abord, puis le trimestre
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000d2', 'guardian', 'fe000000-0000-4000-8000-0000000000f2');
SELECT pg_temp.vrai(pg_temp.formules('e4') = '[{"montant":{"mineur":6500,"devise":"USD"},"formule":"mois"}]'::jsonb,
  'recharge : mois non regle, seul le mois est propose');
SELECT set_config('test.r1', public.recharge_verifier_montants(jsonb_build_array(jsonb_build_object(
  'profilId', 'fe000000-0000-4000-8000-0000000000e4', 'mineur', 6500, 'devise', 'USD')))::text, true);
SELECT set_config('test.c1', (public.recharge_payer((current_setting('test.r1')::jsonb ->> 'id')::uuid,
  'fe000000-0000-4000-8000-00000000a001') ->> 'commandeId'), true);
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT public.recharge_attacher_session(current_setting('test.c1')::uuid, 'fe000000-0000-4000-8000-0000000000d2',
  'cs_fe_1', 'https://checkout.stripe.com/c/cs_fe_1', 'test');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_fe_1', 'checkout.session.completed', 'test',
  current_setting('test.c1')::uuid, 'cs_fe_1', 'pi_fe_1', 'paid', 6500, 'usd') = 'credite',
  'recharge : le mois encaisse');
RESET ROLE;
SELECT pg_temp.vrai((pg_temp.fac('e4', pg_temp.mois())).statut = 'financee'
  AND NOT EXISTS (SELECT 1 FROM public.engagements_prepaiement WHERE profile_id = 'fe000000-0000-4000-8000-0000000000e4'),
  'recharge : le mois finance, aucun engagement');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000d2', 'guardian', 'fe000000-0000-4000-8000-0000000000f2');
SELECT pg_temp.vrai(pg_temp.formules('e4') = '[{"montant":{"mineur":6500,"devise":"USD"},"formule":"mois"},{"montant":{"mineur":18500,"devise":"USD"},"formule":"trimestriel"},{"montant":{"mineur":70200,"devise":"USD"},"formule":"annuel"}]'::jsonb
  AND NOT (pg_temp.formules('e5') @> '[{"formule":"trimestriel"}]'::jsonb),
  'recharge : mois regle, trimestre 185 et annee 702 USD proposes ; pas a qui doit encore son mois');
SELECT set_config('test.r2', public.recharge_verifier_montants(jsonb_build_array(jsonb_build_object(
  'profilId', 'fe000000-0000-4000-8000-0000000000e4', 'mineur', 18500, 'devise', 'USD')))::text, true);
SELECT pg_temp.vrai(current_setting('test.r2')::jsonb #>> '{lignes,0,formule}' = 'trimestriel',
  'recharge : le recapitulatif porte la formule');
SELECT set_config('test.c2', (public.recharge_payer((current_setting('test.r2')::jsonb ->> 'id')::uuid,
  'fe000000-0000-4000-8000-00000000a002') ->> 'commandeId'), true);
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT public.recharge_attacher_session(current_setting('test.c2')::uuid, 'fe000000-0000-4000-8000-0000000000d2',
  'cs_fe_2', 'https://checkout.stripe.com/c/cs_fe_2', 'test');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_fe_2', 'checkout.session.completed', 'test',
  current_setting('test.c2')::uuid, 'cs_fe_2', 'pi_fe_2', 'paid', 18500, 'usd') = 'credite',
  'recharge : le trimestre encaisse');
RESET ROLE;
SELECT pg_temp.vrai((SELECT mois_debut = pg_temp.suivant() AND nb_mois = 3 AND total_mineur = 18500 AND formule = 'trimestriel'
                       FROM public.engagements_prepaiement WHERE profile_id = 'fe000000-0000-4000-8000-0000000000e4'),
  'recharge : engagement de trois mois ouvert au mois suivant');

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000a1', 'admin');
SELECT public.emettre_factures_mois(pg_temp.suivant());
RESET ROLE;
SELECT pg_temp.vrai((pg_temp.fac('e4', pg_temp.suivant())).total_mineur = 6166
  AND (pg_temp.fac('e4', pg_temp.suivant())).statut = 'financee'
  AND (pg_temp.fac('e4', pg_temp.suivant())).lignes = '[{"nature":"tarif","montant":{"mineur":6500,"devise":"USD"},"rang":null},{"nature":"remise_prepaiement","montant":{"mineur":-334,"devise":"USD"},"rang":null}]'::jsonb,
  'engagement : le mois suivant prend sa part (61,66 USD), finance par le trimestre');
SELECT pg_temp.vrai((SELECT private.fac_part_engagement(e, (pg_temp.suivant() + interval '2 months')::date) = 6168
    AND private.fac_part_engagement(e, (pg_temp.suivant() + interval '1 month')::date) = 6166
    FROM public.engagements_prepaiement e WHERE e.profile_id = 'fe000000-0000-4000-8000-0000000000e4'),
  'engagement : trois parts 61,66 ; 61,66 ; 61,68 = 185 USD');

-- ------------------------------------------------------------------
-- 4 bis. Retrait de bourse
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('fe000000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($q$SELECT public.retirer_bourse('fe000000-0000-4000-8000-0000000000e7', '')$q$,
  '22023', 'bourse : retrait motive');
SELECT public.retirer_bourse('fe000000-0000-4000-8000-0000000000e7', 'Revue des six mois');
SELECT pg_temp.vrai(jsonb_array_length(public.bourses_lister()) = 0, 'bourse : retiree, plus listee');
SELECT pg_temp.refus($q$SELECT public.retirer_bourse('fe000000-0000-4000-8000-0000000000e7', 'Encore')$q$,
  'P0002', 'bourse : rien a retirer');
RESET ROLE;
SELECT pg_temp.vrai((pg_temp.fac('e7', pg_temp.mois())).total_mineur = 3850,
  'bourse : une facture emise ne change pas au retrait');

\o
SELECT 'FAC-E-01 : scenarios verts' AS resultat;
ROLLBACK;
