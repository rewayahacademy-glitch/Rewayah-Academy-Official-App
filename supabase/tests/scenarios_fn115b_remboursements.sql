-- FN-115b (02/11/2026) : remboursements et contestations Stripe traites par le
-- serveur. Migrations 20261104300000 et 20261104400000.
-- Decision du directeur du 01/11/2026 (DECISION-TARIFS, section du 01/11).
--   1. remboursement cible (profil vise), partiel, solde encore positif :
--      rien ne se rouvre, aucune suspension ; famille et direction prevenues ;
--   2. idempotence : meme evenement (doublon), cumul deja traite ;
--   3. remboursement au prorata qui fait passer un solde sous zero : la facture
--      redevient a financer et l'acces est suspendu tout de suite ;
--   4. un compte client qui pose le drapeau ne rouvre aucune facture ;
--   5. contestation : simple demande de renseignement (aucun effet), puis
--      contestation ouverte (suspension) et gagnee (acces rendu) ;
--   6. contestation perdue : frais au plus ancien beneficiaire ;
--   7. paiement inconnu ; droits.
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
    RAISE EXCEPTION 'FN-115b ROUGE : %', p_label;
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
    RAISE EXCEPTION 'FN-115b ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
  END;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('fb000000-0000-4000-8000-0000000000' || p)::uuid $$;
CREATE FUNCTION pg_temp.fac(p_profil text) RETURNS public.factures_mensuelles LANGUAGE sql AS
  $$ SELECT f.* FROM public.factures_mensuelles f
      WHERE f.profile_id = pg_temp.id(p_profil) AND f.mois = pg_temp.mois() $$;
CREATE FUNCTION pg_temp.solde(p_profil text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT private.fac_solde_profil(pg_temp.id(p_profil)) $$;
CREATE FUNCTION pg_temp.suspendu(p_profil text) RETURNS boolean LANGUAGE sql AS
  $$ SELECT EXISTS (SELECT 1 FROM public.acces_suspensions_paiement
                     WHERE profile_id = pg_temp.id(p_profil) AND retabli_le IS NULL) $$;
CREATE FUNCTION pg_temp.notifs(p_evenement text, p_portee text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT count(*) FROM public.notifications
      WHERE evenement = p_evenement AND params ->> 'portee' = p_portee
        AND params ->> 'commande_id' IS NOT NULL $$;
CREATE FUNCTION pg_temp.mois_de(p_profil text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT ((x -> 'formules') -> 0 -> 'montant' ->> 'mineur')::bigint
       FROM jsonb_array_elements(public.recharge_beneficiaires()) AS x
      WHERE x ->> 'id' = pg_temp.id(p_profil)::text $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text), pg_temp.mois(), pg_temp.id(text), pg_temp.mois_de(text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
--   F1 : tuteur d1, deux enfants e1 et e2 (une commande, deux allocations)
--   F2 : adulte e4 (contestation gagnee)   F3 : adulte e5 (contestation perdue)
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'fb-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','d1','e1','e2','e4','e5']) AS x;
INSERT INTO public.households(id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['f1','f2','f3']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'FB', x.statut::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','FB-ADM-0001','admin',NULL,'Direction','active','female'),
   ('b1','FB-ENS-0001','teacher',NULL,'Maryam','provisional_active','female'),
   ('d1','FB-TUT-0001','guardian','f1','Amina','active','female'),
   ('e1','FB-ELV-0001','student','f1','Yasmine','active','female'),
   ('e2','FB-ELV-0002','student','f1','Bilal','active','male'),
   ('e4','FB-ELV-0004','guardian','f2','Aicha','active','female'),
   ('e5','FB-ELV-0005','guardian','f3','Khadija','active','female')) AS x(id, mat, role, foyer, prenom, statut, genre);
UPDATE public.households SET primary_guardian_id = pg_temp.id('d1') WHERE id = pg_temp.id('f1');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e4') WHERE id = pg_temp.id('f2');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e5') WHERE id = pg_temp.id('f3');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.id(x), (CASE WHEN x IN ('e4','e5') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e4','e5']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fb000000-0000-4000-8000-000000000c01', pg_temp.id('b1'), 'enfant', 5, 'An-Nour FB', 1, 9, 'Europe/Paris'),
 ('fb000000-0000-4000-8000-000000000c03', pg_temp.id('b1'), 'adulte', 6, 'Al-Huda FB', 3, 20, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT x.g::uuid, pg_temp.id(x.e), pg_temp.mois() - interval '20 days'
  FROM (VALUES ('fb000000-0000-4000-8000-000000000c01','e1'), ('fb000000-0000-4000-8000-000000000c01','e2'),
               ('fb000000-0000-4000-8000-000000000c03','e4'), ('fb000000-0000-4000-8000-000000000c03','e5')) AS x(g, e);
-- e1 a 50 USD d'avance : les remboursements partiels le laissent positif.
INSERT INTO public.wallets(id, household_id, currency) VALUES
 ('fb000000-0000-4000-8000-000000000901', pg_temp.id('f1'), 'USD');
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
VALUES ('fb000000-0000-4000-8000-000000000901', 5000, 'USD', 'credit', pg_temp.id('e1'), now());

-- Une commande payee : recapitulatif, commande, session, evenement Stripe.
CREATE FUNCTION pg_temp.payer(p_titulaire text, p_foyer text, p_lignes jsonb, p_cle text, p_pi text)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_r jsonb; v_c uuid; v_total bigint;
BEGIN
  PERFORM pg_temp.qui(pg_temp.id(p_titulaire), 'guardian', pg_temp.id(p_foyer));
  EXECUTE 'SET LOCAL ROLE authenticated';
  v_r := public.recharge_verifier_montants(p_lignes);
  v_c := (public.recharge_payer((v_r ->> 'id')::uuid, ('fb000000-0000-4000-8000-000000' || p_cle)::uuid) ->> 'commandeId')::uuid;
  EXECUTE 'RESET ROLE';
  SELECT total_mineur INTO v_total FROM public.commandes_recharge WHERE id = v_c;
  EXECUTE 'SET LOCAL ROLE service_role';
  PERFORM public.recharge_attacher_session(v_c, pg_temp.id(p_titulaire), 'cs_' || p_pi,
    'https://checkout.stripe.com/c/cs_' || p_pi, 'test');
  IF public.recharge_evenement_stripe('evt_pay_' || p_pi, 'checkout.session.completed', 'test', v_c,
       'cs_' || p_pi, p_pi, 'paid', v_total, 'usd') <> 'credite' THEN
    RAISE EXCEPTION 'FN-115b ROUGE : paiement % non credite', p_pi;
  END IF;
  EXECUTE 'RESET ROLE';
  RETURN v_c;
END $$;
CREATE FUNCTION pg_temp.evt(p_id text, p_type text, p_pi text, p_montant bigint,
  p_litige text DEFAULT NULL, p_statut text DEFAULT NULL, p_frais bigint DEFAULT NULL, p_profil text DEFAULT NULL)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  v := public.remboursement_evenement_stripe(p_id, p_type, 'test', p_pi, p_montant, 'usd',
         p_litige, p_statut, p_frais, CASE WHEN p_profil IS NULL THEN NULL ELSE pg_temp.id(p_profil) END);
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Les montants du mois, lus comme la famille les lit.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.m1', pg_temp.mois_de('e1')::text, true), set_config('test.m2', pg_temp.mois_de('e2')::text, true);
RESET ROLE;

SELECT set_config('test.c1', pg_temp.payer('d1', 'f1', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e1'), 'mineur', current_setting('test.m1')::bigint, 'devise', 'USD'),
  jsonb_build_object('profilId', pg_temp.id('e2'), 'mineur', current_setting('test.m2')::bigint, 'devise', 'USD')),
  '00a001', 'pi_fb_1')::text, true);
-- e2 a la remise de fratrie : sa facture est sous le prix paye, le reste
-- demeure a son solde.
SELECT set_config('test.s2', pg_temp.solde('e2')::text, true);
SELECT pg_temp.vrai((pg_temp.fac('e1')).statut = 'financee' AND (pg_temp.fac('e2')).statut = 'financee'
  AND pg_temp.solde('e1') = 5000 AND pg_temp.solde('e2') >= 0 AND pg_temp.solde('e2') < 1650,
  'depart : les deux mois finances ; e1 garde 50 USD d''avance, e2 un petit reste');

-- ------------------------------------------------------------------
-- 1. Remboursement cible, partiel, solde encore positif
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.evt('evt_r1', 'charge.refunded', 'pi_fb_1', 1000, p_profil := 'e1') = 'rembourse',
  '1 : remboursement de 10 USD vise sur e1');
SELECT pg_temp.vrai(pg_temp.solde('e1') = 4000 AND (pg_temp.fac('e1')).statut = 'financee'
  AND NOT pg_temp.suspendu('e1') AND pg_temp.solde('e2') = current_setting('test.s2')::bigint,
  '1 : solde de e1 encore positif : aucune facture rouverte, aucune suspension ; e2 intact');
SELECT pg_temp.vrai((SELECT count(*) = 1 AND sum(montant_mineur) = 1000 FROM public.remboursements_paiement
                       WHERE commande_id = current_setting('test.c1')::uuid AND profile_id = pg_temp.id('e1')),
  '1 : une part rendue a e1, une ligne refund');
SELECT pg_temp.vrai(pg_temp.notifs('remboursement_effectue', 'foyer') = 1
  AND pg_temp.notifs('remboursement_effectue', 'direction') = 1,
  '1 : la famille (tuteur) et la direction sont prevenues ; l''enseignant jamais');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications n
                                 WHERE n.destinataire = pg_temp.id('b1')
                                   AND n.evenement IN ('remboursement_effectue', 'litige_ouvert', 'litige_clos')),
  '1 : aucune notification a l''enseignant');
SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.courriels_sortants WHERE modele = 'remboursement_effectue'),
  '1 : un e-mail a la famille, aucun a la direction (application seulement)');

-- ------------------------------------------------------------------
-- 2. Idempotence
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.evt('evt_r1', 'charge.refunded', 'pi_fb_1', 1000, p_profil := 'e1') = 'doublon',
  '2 : le meme evenement rejoue : doublon');
SELECT pg_temp.vrai(pg_temp.evt('evt_r1bis', 'charge.refunded', 'pi_fb_1', 1000) = 'deja_rembourse'
  AND pg_temp.solde('e1') = 4000,
  '2 : un autre evenement au meme cumul : rien de plus');

-- ------------------------------------------------------------------
-- 3. Prorata, solde negatif : facture rouverte, suspension immediate
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.evt('evt_r2', 'charge.refunded', 'pi_fb_1', 4000) = 'rembourse',
  '3 : cumul 40 USD, soit 30 USD de plus, au prorata');
SELECT pg_temp.vrai((SELECT sum(montant_mineur) = 3000 FROM public.remboursements_paiement
                      WHERE evenement_id = 'evt_r2'),
  '3 : les parts du prorata font exactement 30 USD');
SELECT pg_temp.vrai((pg_temp.fac('e2')).statut = 'a_financer' AND (pg_temp.fac('e2')).debit_entry_id IS NULL
  AND pg_temp.suspendu('e2') AND pg_temp.solde('e2') >= 0,
  '3 : e2 sous zero : sa facture redevient a financer et son acces est suspendu tout de suite');
SELECT pg_temp.vrai((pg_temp.fac('e1')).statut = 'financee' AND NOT pg_temp.suspendu('e1') AND pg_temp.solde('e1') > 0,
  '3 : e1 reste positif : rien ne se rouvre pour lui (un remboursement partiel ne suspend pas a lui seul)');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.notifications
                             WHERE evenement = 'acces_suspendu_paiement' AND params ->> 'cause' = 'remboursement'),
  '3 : la suspension est annoncee avec sa cause');

-- ------------------------------------------------------------------
-- 4. Un compte client ne rouvre aucune facture, drapeau ou pas
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SELECT pg_temp.refus($q$
  SELECT set_config('fac.reouverture', 'on', true);
  UPDATE public.factures_mensuelles SET statut = 'a_financer', financee_le = NULL, debit_entry_id = NULL
   WHERE profile_id = pg_temp.id('e1') AND mois = pg_temp.mois()$q$,
  '4 : la direction connectee qui pose le drapeau ne rouvre pas une facture');
RESET ROLE;
SELECT pg_temp.vrai((pg_temp.fac('e1')).statut = 'financee', '4 : la facture de e1 est restee financee');
SELECT pg_temp.refus($q$
  UPDATE public.factures_mensuelles SET statut = 'a_financer', financee_le = NULL, debit_entry_id = NULL
   WHERE profile_id = pg_temp.id('e1') AND mois = pg_temp.mois()$q$,
  '4 : sans drapeau, meme le proprietaire ne rouvre pas une facture');

-- ------------------------------------------------------------------
-- 5. Contestation : renseignement, puis ouverte et gagnee (F2, e4)
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('e4'), 'guardian', pg_temp.id('f2'));
SELECT set_config('test.m4', pg_temp.mois_de('e4')::text, true);
RESET ROLE;
SELECT set_config('test.c4', pg_temp.payer('e4', 'f2', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e4'), 'mineur', current_setting('test.m4')::bigint, 'devise', 'USD')),
  '00a004', 'pi_fb_4')::text, true);
SELECT pg_temp.vrai(pg_temp.evt('evt_l0', 'charge.dispute.created', 'pi_fb_4', current_setting('test.m4')::bigint,
  'du_fb_0', 'warning_needs_response') = 'enquete'
  AND NOT pg_temp.suspendu('e4') AND (pg_temp.fac('e4')).statut = 'financee',
  '5 : une demande de renseignement de la banque ne retire rien et ne suspend rien');
SELECT pg_temp.vrai(pg_temp.evt('evt_l0c', 'charge.dispute.closed', 'pi_fb_4', current_setting('test.m4')::bigint,
  'du_fb_0', 'warning_closed') = 'enquete_close', '5 : la demande de renseignement se clot');
SELECT pg_temp.vrai(pg_temp.evt('evt_l1', 'charge.dispute.created', 'pi_fb_4', current_setting('test.m4')::bigint,
  'du_fb_1', 'needs_response') = 'litige_ouvert',
  '5 : contestation ouverte');
SELECT pg_temp.vrai(pg_temp.suspendu('e4') AND (pg_temp.fac('e4')).statut = 'a_financer',
  '5 : l''argent est repris : facture a financer, acces suspendu tout de suite');
SELECT pg_temp.vrai(pg_temp.evt('evt_l1', 'charge.dispute.created', 'pi_fb_4', current_setting('test.m4')::bigint,
  'du_fb_1', 'needs_response') = 'doublon'
  AND pg_temp.evt('evt_l1b', 'charge.dispute.created', 'pi_fb_4', current_setting('test.m4')::bigint,
  'du_fb_1', 'needs_response') = 'litige_deja_ouvert',
  '5 : la meme contestation ne compte qu''une fois');
SELECT pg_temp.vrai(pg_temp.evt('evt_l1c', 'charge.dispute.closed', 'pi_fb_4', current_setting('test.m4')::bigint,
  'du_fb_1', 'won') = 'litige_gagne',
  '5 : contestation gagnee par l''academie');
SELECT pg_temp.vrai(NOT pg_temp.suspendu('e4') AND (pg_temp.fac('e4')).statut = 'financee' AND pg_temp.solde('e4') = 0,
  '5 : l''argent revient, la facture est de nouveau financee, l''acces est rendu');
SELECT pg_temp.vrai(pg_temp.notifs('litige_ouvert', 'foyer') >= 1 AND pg_temp.notifs('litige_clos', 'direction') >= 1,
  '5 : famille et direction prevenues de l''ouverture et de la cloture');
SELECT pg_temp.vrai(pg_temp.evt('evt_l1d', 'charge.dispute.closed', 'pi_fb_4', 0, 'du_fb_1', 'lost') = 'litige_deja_clos',
  '5 : une contestation close ne se reclot pas');

-- ------------------------------------------------------------------
-- 6. Contestation perdue (F3, e5) : frais au solde du foyer
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('e5'), 'guardian', pg_temp.id('f3'));
SELECT set_config('test.m5', pg_temp.mois_de('e5')::text, true);
RESET ROLE;
SELECT set_config('test.c5', pg_temp.payer('e5', 'f3', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e5'), 'mineur', current_setting('test.m5')::bigint, 'devise', 'USD')),
  '00a005', 'pi_fb_5')::text, true);
SELECT pg_temp.vrai(pg_temp.evt('evt_l2', 'charge.dispute.created', 'pi_fb_5', current_setting('test.m5')::bigint,
  'du_fb_2', 'needs_response') = 'litige_ouvert' AND pg_temp.suspendu('e5'),
  '6 : contestation ouverte, acces suspendu');
SELECT pg_temp.vrai(pg_temp.evt('evt_l2c', 'charge.dispute.closed', 'pi_fb_5', current_setting('test.m5')::bigint,
  'du_fb_2', 'lost', 1500) = 'litige_perdu',
  '6 : contestation perdue, frais de 15 USD');
SELECT pg_temp.vrai(pg_temp.solde('e5') = -1500 AND pg_temp.suspendu('e5') AND (pg_temp.fac('e5')).statut = 'a_financer'
  AND (SELECT statut = 'perdu' AND frais_mineur = 1500 FROM public.litiges_paiement WHERE id = 'du_fb_2'),
  '6 : les frais vont au solde du plus ancien beneficiaire ; le mois reste a payer, l''acces suspendu');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'litige_clos'
                             AND params ->> 'issue' = 'perdu' AND (params ->> 'frais_mineur')::bigint = 1500),
  '6 : la famille lit l''issue et les frais');
-- Les frais se payent : la page propose le mois ET la dette, et ce paiement
-- rouvre l'acces (avant le 02/11, seul le mois etait propose : l'acces restait
-- suspendu apres paiement).
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('e5'), 'guardian', pg_temp.id('f3'));
SELECT set_config('test.du5', (SELECT (x -> 'montantSuggere' ->> 'mineur')
  FROM jsonb_array_elements(public.recharge_beneficiaires()) x WHERE x ->> 'id' = pg_temp.id('e5')::text), true);
RESET ROLE;
SELECT pg_temp.vrai(current_setting('test.du5')::bigint = current_setting('test.m5')::bigint + 1500,
  '6 : le montant suggere couvre le mois et les 15 USD de frais');
SELECT pg_temp.payer('e5', 'f3', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e5'), 'mineur', current_setting('test.du5')::bigint, 'devise', 'USD')),
  '00a006', 'pi_fb_6');
SELECT pg_temp.vrai(NOT pg_temp.suspendu('e5') AND (pg_temp.fac('e5')).statut = 'financee' AND pg_temp.solde('e5') = 0,
  '6 : payer le montant suggere finance le mois, solde la dette et rouvre l''acces');

-- ------------------------------------------------------------------
-- 7. Paiement inconnu ; droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.evt('evt_x', 'charge.refunded', 'pi_inconnu', 100) = 'commande_inconnue',
  '7 : un paiement inconnu ne touche rien');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated',
    'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon',
    'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)', 'EXECUTE')
  AND has_function_privilege('service_role',
    'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)', 'EXECUTE'),
  '7 : seul service_role appelle la fonction de remboursement');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT pg_temp.vrai((SELECT count(*) FROM public.remboursements_paiement) = 0
  AND (SELECT count(*) FROM public.litiges_paiement) = 0,
  '7 : une famille ne lit pas les tables des remboursements et des contestations');
RESET ROLE;

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 30,
  'au moins 30 controles ont passe (31 avec celui-ci)');
\o
SELECT 'FN-115b : scenarios verts' AS resultat;
ROLLBACK;
