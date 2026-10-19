-- FAC-F-01 (18/10/2026) : relances avant echeance et suspension pour paiement
-- (politique v2 : jours_relance {7,3,1}, jour_suspension 4). Migration
-- 20261018170000.
--   1. relance J-7, J-3, J-1 : une seule fois chacune, au bon destinataire ;
--   2. pas de relance ni de suspension pour un mois paye, une bourse de 100 %,
--      un paiement en attente de validation, ni sous une politique sans jours ;
--   3. suspension le 4 si impaye, une seule fois, rattrapable apres le 4 ;
--   4. lecture : l'enfant ne lit jamais la cause, le tuteur et l'adulte oui ;
--   5. le jeton video refuse l'eleve suspendu ;
--   6. le paiement rend l'acces tout de suite ; une facture close aussi ;
--   7. droits : lancement a la main reserve a la direction en AAL2.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees. Les dates
-- sont passees en argument, le scenario ne depend pas de l'horloge.
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

-- Le nombre de notifications d'un evenement pour un destinataire.
CREATE FUNCTION pg_temp.nb(p_dest uuid, p_evt text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::integer FROM public.notifications WHERE destinataire = p_dest AND evenement = p_evt
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.nb(uuid, text) TO authenticated, anon, service_role;

INSERT INTO auth.users(id, email) VALUES
 ('f6000000-0000-4000-8000-0000000000a1','ff-admin@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000a2','ff-admin-suspendu@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000c1','ff-compta@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000b1','ff-ens@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000d1','ff-tut1@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000d3','ff-tut3@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e1','ff-e1@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e2','ff-e2@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e3','ff-e3@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e4','ff-e4@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e5','ff-e5@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e6','ff-e6@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e7','ff-e7@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('f6000000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('f6000000-0000-4000-8000-0000000000f2','Europe/Paris'),
 ('f6000000-0000-4000-8000-0000000000f3','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('f6000000-0000-4000-8000-0000000000a1','FF-ADM-0001','admin',NULL,'Direction','FF','active','female'),
 ('f6000000-0000-4000-8000-0000000000a2','FF-ADM-0002','admin',NULL,'Direction','Suspendue','disabled','female'),
 ('f6000000-0000-4000-8000-0000000000c1','FF-CPT-0001','accountant',NULL,'Compta','FF','active','male'),
 ('f6000000-0000-4000-8000-0000000000b1','FF-ENS-0001','teacher',NULL,'Maryam','FF','provisional_active','female'),
 ('f6000000-0000-4000-8000-0000000000d1','FF-TUT-0001','guardian','f6000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('f6000000-0000-4000-8000-0000000000d3','FF-TUT-0003','guardian','f6000000-0000-4000-8000-0000000000f3','Karim','F3','active','male'),
 ('f6000000-0000-4000-8000-0000000000e1','FF-ELV-0001','student','f6000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('f6000000-0000-4000-8000-0000000000e2','FF-ELV-0002','student','f6000000-0000-4000-8000-0000000000f1','Bilal','F1','active','male'),
 ('f6000000-0000-4000-8000-0000000000e3','FF-ELV-0003','student','f6000000-0000-4000-8000-0000000000f1','Salma','F1','active','female'),
 ('f6000000-0000-4000-8000-0000000000e4','FF-ELV-0004','student','f6000000-0000-4000-8000-0000000000f1','Omar','F1','active','male'),
 ('f6000000-0000-4000-8000-0000000000e5','FF-ELV-0005','student','f6000000-0000-4000-8000-0000000000f2','Nadia','Adulte','active','female'),
 ('f6000000-0000-4000-8000-0000000000e6','FF-ELV-0006','student','f6000000-0000-4000-8000-0000000000f3','Zaid','F3','active','male'),
 ('f6000000-0000-4000-8000-0000000000e7','FF-ELV-0007','student','f6000000-0000-4000-8000-0000000000f1','Lina','F1','active','female');
UPDATE public.households SET primary_guardian_id = 'f6000000-0000-4000-8000-0000000000d1'
 WHERE id = 'f6000000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = 'f6000000-0000-4000-8000-0000000000d3'
 WHERE id = 'f6000000-0000-4000-8000-0000000000f3';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('f6000000-0000-4000-8000-0000000000e1','minor','child'),
 ('f6000000-0000-4000-8000-0000000000e2','minor','standard'),
 ('f6000000-0000-4000-8000-0000000000e3','minor','standard'),
 ('f6000000-0000-4000-8000-0000000000e4','minor','standard'),
 ('f6000000-0000-4000-8000-0000000000e5','autonomous','standard'),
 ('f6000000-0000-4000-8000-0000000000e6','minor','standard'),
 ('f6000000-0000-4000-8000-0000000000e7','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('f6000000-0000-4000-8000-000000000c01','f6000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour FF',1,9,'Europe/Paris'),
 ('f6000000-0000-4000-8000-000000000c02','f6000000-0000-4000-8000-0000000000b1','enfant',5,'Al-Fajr FF',2,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT CASE WHEN p.immutable_id IN ('FF-ELV-0005','FF-ELV-0006')
            THEN 'f6000000-0000-4000-8000-000000000c02'::uuid
            ELSE 'f6000000-0000-4000-8000-000000000c01'::uuid END,
       p.id, TIMESTAMPTZ '2026-09-01 10:00+00'
  FROM public.profiles p WHERE p.immutable_id LIKE 'FF-ELV-%';

-- Un portefeuille par foyer et les factures de novembre 2026 (politique v2,
-- 55 USD) : e1, e5, e6 impayees ; e2 payee ; e3 boursiere a 100 % ; e4 avec un
-- paiement attendant sa validation. e7 : une facture de decembre sous la v1
-- (sans jours de relance ni de suspension).
SELECT private.fac_portefeuille(h.id, 'USD') FROM public.households h WHERE h.id::text LIKE 'f6000000-%';
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur)
SELECT p.id, p.household_id, DATE '2026-11-01', 'v2.0.0', 'USD', 1, '[]'::jsonb, 5500
  FROM public.profiles p WHERE p.immutable_id IN ('FF-ELV-0001','FF-ELV-0002','FF-ELV-0003','FF-ELV-0004','FF-ELV-0005','FF-ELV-0006');
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur)
VALUES ('f6000000-0000-4000-8000-0000000000e7','f6000000-0000-4000-8000-0000000000f1', DATE '2026-12-01', 'v1.0.0', 'USD', 1, '[]'::jsonb, 5000);

-- e2 paie : un credit confirme, puis le financement (le chemin commun de la
-- saisie, de la validation et du webhook).
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
SELECT w.id, 5500, 'USD', 'credit', 'f6000000-0000-4000-8000-0000000000e2', clock_timestamp()
  FROM public.wallets w WHERE w.household_id = 'f6000000-0000-4000-8000-0000000000f1';
SELECT private.fac_financer_profil('f6000000-0000-4000-8000-0000000000e2');
SELECT pg_temp.vrai((SELECT statut FROM public.factures_mensuelles
                      WHERE profile_id = 'f6000000-0000-4000-8000-0000000000e2' AND mois = DATE '2026-11-01') = 'financee',
  'fixture : le mois de Bilal est paye');

INSERT INTO public.bourses_eleves(profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par)
VALUES ('f6000000-0000-4000-8000-0000000000e3', 1000, DATE '2026-11-01', DATE '2027-04-01', 'Bourse de test',
        'f6000000-0000-4000-8000-0000000000a1');
INSERT INTO public.finance_validations(nature, objet_id, demandeur, montant_mineur, devise, raison)
VALUES ('paiement_recu', 'f6000000-0000-4000-8000-0000000000e4', 'f6000000-0000-4000-8000-0000000000c1',
        5500, 'USD', 'paiement_hors_application');

-- ------------------------------------------------------------------
-- 1. Relances : J-8 rien, puis J-7, J-3, J-1 une seule fois chacune
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-10-24') ->> 'relances')::int = 0,
  'relance : 8 jours avant l''echeance, rien');
SELECT set_config('test.r7', private.fac_traiter_relances(DATE '2026-10-25')::text, true);
SELECT pg_temp.vrai((current_setting('test.r7')::jsonb ->> 'relances')::int = 3
  AND (current_setting('test.r7')::jsonb ->> 'suspensions')::int = 0,
  'relance J-7 : trois eleves impayes (ni paye, ni boursier, ni paiement en attente)');
SELECT pg_temp.vrai(pg_temp.nb('f6000000-0000-4000-8000-0000000000d1', 'paiement_relance') = 1
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000d3', 'paiement_relance') = 1
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000e5', 'paiement_relance') = 1,
  'relance : le tuteur du foyer 1, celui du foyer 3 et l''adulte lui-meme sont prevenus');
SELECT pg_temp.vrai(pg_temp.nb('f6000000-0000-4000-8000-0000000000e1', 'paiement_relance') = 0
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000e6', 'paiement_relance') = 0
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000b1', 'paiement_relance') = 0,
  'relance : un enfant et un enseignant ne recoivent jamais la relance');
SELECT pg_temp.vrai((SELECT count(*) FROM public.notifications
                      WHERE evenement = 'paiement_relance' AND destination = '/tuteur/foyer/recharge'
                        AND params ->> 'jours_avant' = '7') = 3,
  'relance : destination Payer et jours d''avance dans la notification');
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-10-25') ->> 'relances')::int = 0
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000d1', 'paiement_relance') = 1,
  'idempotence : rejouer J-7 le meme jour ne cree aucun doublon');
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-10-26') ->> 'relances')::int = 0
  AND (private.fac_traiter_relances(DATE '2026-10-28') ->> 'relances')::int = 0,
  'relance : aucun autre jour que ceux de la politique');
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-10-29') ->> 'relances')::int = 3
  AND (private.fac_traiter_relances(DATE '2026-10-29') ->> 'relances')::int = 0,
  'relance J-3 : une fois, rejouee sans doublon');
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-10-31') ->> 'relances')::int = 3
  AND (private.fac_traiter_relances(DATE '2026-10-31') ->> 'relances')::int = 0,
  'relance J-1 : une fois, rejouee sans doublon');
SELECT pg_temp.vrai(pg_temp.nb('f6000000-0000-4000-8000-0000000000d1', 'paiement_relance') = 3
  AND (SELECT count(DISTINCT jours_avant) FROM public.relances_paiement
        WHERE profile_id = 'f6000000-0000-4000-8000-0000000000e1' AND action = 'relance') = 3
  AND (SELECT count(*) FROM public.relances_paiement
        WHERE profile_id = 'f6000000-0000-4000-8000-0000000000e1' AND action = 'relance') = 3,
  'relance : trois relances en tout pour Yasmine, une par jour d''avance');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.relances_paiement
                                 WHERE profile_id IN ('f6000000-0000-4000-8000-0000000000e2',
                                                      'f6000000-0000-4000-8000-0000000000e3',
                                                      'f6000000-0000-4000-8000-0000000000e4',
                                                      'f6000000-0000-4000-8000-0000000000e7')),
  'relance : ni le mois paye, ni la bourse, ni le paiement en attente, ni la politique sans jours');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'paiement_relance'),
  'journal : chaque relance est inscrite');

-- ------------------------------------------------------------------
-- 2. Suspension : pas avant le 4, le 4 si impaye, une seule fois
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-11-03') ->> 'suspensions')::int = 0
  AND NOT EXISTS (SELECT 1 FROM public.acces_suspensions_paiement),
  'suspension : le 3, personne n''est suspendu');
SELECT set_config('test.s4', private.fac_traiter_relances(DATE '2026-11-04')::text, true);
SELECT pg_temp.vrai((current_setting('test.s4')::jsonb ->> 'suspensions')::int = 3
  AND (current_setting('test.s4')::jsonb ->> 'relances')::int = 0,
  'suspension : le 4, trois eleves impayes sont suspendus');
SELECT pg_temp.vrai((SELECT array_agg(profile_id::text ORDER BY profile_id::text) FROM public.acces_suspensions_paiement WHERE retabli_le IS NULL)
  = ARRAY['f6000000-0000-4000-8000-0000000000e1', 'f6000000-0000-4000-8000-0000000000e5', 'f6000000-0000-4000-8000-0000000000e6'],
  'suspension : Yasmine, Nadia et Zaid seulement');
SELECT pg_temp.vrai(NOT private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e2')
  AND NOT private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e3')
  AND NOT private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e4'),
  'suspension : pas le mois paye, pas la bourse a 100 %, pas le paiement en attente');
SELECT pg_temp.vrai(pg_temp.nb('f6000000-0000-4000-8000-0000000000d1', 'acces_suspendu_paiement') = 1
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000e5', 'acces_suspendu_paiement') = 1,
  'suspension : le tuteur et l''adulte en sont prevenus');
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-11-04') ->> 'suspensions')::int = 0
  AND (private.fac_traiter_relances(DATE '2026-11-05') ->> 'suspensions')::int = 0
  AND (SELECT count(*) FROM public.acces_suspensions_paiement) = 3
  AND pg_temp.nb('f6000000-0000-4000-8000-0000000000d1', 'acces_suspendu_paiement') = 1,
  'idempotence : rejouer le 4 ou le lendemain ne suspend personne de plus');
SELECT pg_temp.vrai((SELECT count(*) FROM public.relances_paiement WHERE action = 'suspension') = 3
  AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'acces_suspendu_paiement'),
  'journal : trois suspensions inscrites');
-- La politique v1 de la facture de decembre d'e7 ne porte ni relance ni suspension.
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-11-24') ->> 'relances')::int = 0
  AND (private.fac_traiter_relances(DATE '2026-12-05') ->> 'suspensions')::int = 0
  AND NOT private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e7'),
  'politique : sans jours dans la politique de la facture, ni relance ni suspension');

-- ------------------------------------------------------------------
-- 3. Lecture : l'enfant ne lit jamais la cause
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000e1', 'student', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(public.mon_acces() ->> 'seancesPayantesOuvertes' = 'false'
  AND public.mon_acces() -> 'place' = 'null'::jsonb
  AND public.mon_acces() -> 'datePlace' = 'null'::jsonb
  AND (public.mon_acces() ->> 'gereSonAcces')::boolean = false
  AND public.mon_acces()::text !~* '(montant|manque|paiement|facture|USD)',
  'lecture enfant : seances fermees, jamais une cause ni un montant');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000e2', 'student', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(public.mon_acces() -> 'seancesPayantesOuvertes' = 'null'::jsonb,
  'lecture enfant : un eleve a jour ne lit aucune fermeture');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000e5', 'student', 'f6000000-0000-4000-8000-0000000000f2');
SELECT pg_temp.vrai(public.mon_acces() ->> 'place' = 'suspendu_paiement'
  AND public.mon_acces() ->> 'datePlace' = '2026-11-04'
  AND (public.mon_acces() ->> 'gereSonAcces')::boolean,
  'lecture adulte : il lit la cause, le jour et qu''il gere son acces');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(jsonb_array_length(public.acces_du_foyer()) = 5
  AND (SELECT x ->> 'place' FROM jsonb_array_elements(public.acces_du_foyer()) x
        WHERE x ->> 'eleveId' = 'f6000000-0000-4000-8000-0000000000e1') = 'suspendu_paiement'
  AND (SELECT count(*) FROM jsonb_array_elements(public.acces_du_foyer()) x WHERE x ->> 'place' IS NOT NULL) = 1,
  'lecture tuteur : les cinq eleves du foyer, un seul suspendu, avec le motif');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.acces_du_foyer()$q$, '42501', 'lecture : un enseignant ne lit pas les acces d''un foyer');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.mon_acces()$q$, '42501', 'anon : mon_acces sans EXECUTE');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Le jeton video refuse l'eleve suspendu
-- ------------------------------------------------------------------
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, session_type, groupe_id, join_opens_at)
VALUES ('f6000000-0000-4000-8000-000000000501','f6000000-0000-4000-8000-0000000000b1',
        clock_timestamp() + interval '10 minutes', clock_timestamp() + interval '70 minutes',
        'planned','standard','f6000000-0000-4000-8000-000000000c01', clock_timestamp() - interval '1 hour');
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
 ('f6000000-0000-4000-8000-000000000501','f6000000-0000-4000-8000-0000000000e1','student'),
 ('f6000000-0000-4000-8000-000000000501','f6000000-0000-4000-8000-0000000000e2','student');
SET LOCAL ROLE service_role;
SELECT pg_temp.refus($q$SELECT public.autoriser_jeton_video('f6000000-0000-4000-8000-000000000501','f6000000-0000-4000-8000-0000000000e1','wss://x','wss://y')$q$,
  '42501', 'jeton : l''eleve suspendu pour paiement n''entre pas dans la salle');
SELECT pg_temp.vrai(public.autoriser_jeton_video('f6000000-0000-4000-8000-000000000501','f6000000-0000-4000-8000-0000000000e2','wss://x','wss://y') ->> 'role' = 'student',
  'jeton : un eleve a jour entre toujours');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. Le paiement rend l'acces tout de suite ; une facture close aussi
-- ------------------------------------------------------------------
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
SELECT w.id, 5500, 'USD', 'credit', 'f6000000-0000-4000-8000-0000000000e1', clock_timestamp()
  FROM public.wallets w WHERE w.household_id = 'f6000000-0000-4000-8000-0000000000f1';
SELECT private.fac_financer_profil('f6000000-0000-4000-8000-0000000000e1');
SELECT pg_temp.vrai(NOT private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e1')
  AND (SELECT retabli_motif FROM public.acces_suspensions_paiement
        WHERE profile_id = 'f6000000-0000-4000-8000-0000000000e1') = 'paiement',
  'retablissement : le paiement valide rend l''acces sans attendre le traitement du jour');
SELECT pg_temp.vrai(pg_temp.nb('f6000000-0000-4000-8000-0000000000d1', 'acces_retabli_paiement') = 1
  AND (SELECT count(*) FROM public.relances_paiement WHERE action = 'retablissement'
        AND profile_id = 'f6000000-0000-4000-8000-0000000000e1') = 1
  AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'acces_retabli_paiement'),
  'retablissement : le tuteur est prevenu, l''action est journalisee');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000e1', 'student', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(public.mon_acces() -> 'seancesPayantesOuvertes' = 'null'::jsonb,
  'retablissement : l''enfant ne lit plus de fermeture');
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(public.autoriser_jeton_video('f6000000-0000-4000-8000-000000000501','f6000000-0000-4000-8000-0000000000e1','wss://x','wss://y') ->> 'role' = 'student',
  'retablissement : Yasmine rentre de nouveau dans la salle');
RESET ROLE;
SELECT pg_temp.vrai((private.fac_traiter_relances(DATE '2026-11-06') ->> 'suspensions')::int = 0
  AND NOT private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e1'),
  'idempotence : un eleve paye n''est pas suspendu de nouveau');

-- La facture de Nadia est annulee (hors paiement) : le traitement du jour
-- rend l'acces.
UPDATE public.factures_mensuelles SET statut = 'annulee', annulee_le = clock_timestamp(),
       annulee_par = 'f6000000-0000-4000-8000-0000000000a1', motif_annulation = 'Erreur de facturation'
 WHERE profile_id = 'f6000000-0000-4000-8000-0000000000e5' AND mois = DATE '2026-11-01';
SELECT set_config('test.r6', private.fac_traiter_relances(DATE '2026-11-06')::text, true);
SELECT pg_temp.vrai((current_setting('test.r6')::jsonb ->> 'retablissements')::int = 1
  AND (SELECT retabli_motif FROM public.acces_suspensions_paiement
        WHERE profile_id = 'f6000000-0000-4000-8000-0000000000e5') = 'facture_close',
  'retablissement : une facture close rend l''acces au traitement du jour');
SELECT pg_temp.vrai(private.fac_eleve_suspendu('f6000000-0000-4000-8000-0000000000e6'),
  'retablissement : Zaid, toujours impaye, reste suspendu');

-- ------------------------------------------------------------------
-- 6. Droits
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1', 'aal2');
SELECT pg_temp.refus($q$SELECT public.fac_traiter_relances_du_jour()$q$, '42501', 'droits : un tuteur ne lance pas les relances');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000c1', 'accountant', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.fac_traiter_relances_du_jour()$q$, '42501', 'droits : la comptabilite ne lance pas les relances');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal1');
SELECT pg_temp.refus($q$SELECT public.fac_traiter_relances_du_jour()$q$, '42501', 'droits : la direction sans verification renforcee est refusee');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000a2', 'admin', NULL, 'aal2');
SELECT pg_temp.refus($q$SELECT public.fac_traiter_relances_du_jour()$q$, '42501', 'droits : une direction au compte suspendu est refusee');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000a1', 'admin', NULL, 'aal2');
SELECT pg_temp.vrai(public.fac_traiter_relances_du_jour() ? 'jour'
  AND public.fac_traiter_relances_du_jour() ? 'relances',
  'droits : la direction en AAL2 lance le traitement du jour');
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.fac_traiter_relances(date)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.fac_retablir_acces(uuid,date)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.relances_paiement', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.acces_suspensions_paiement', 'SELECT'),
  'droits : le traitement, le retablissement et les tables restent fermes aux clients');
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.fac_traiter_relances_du_jour()$q$, '42501', 'anon : lancement sans EXECUTE');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'relances_paiement_lancees'),
  'droits : le lancement a la main est inscrit au journal');

\o
SELECT 'FAC-F relances et suspension : tous les controles sont verts' AS bilan;
ROLLBACK;
