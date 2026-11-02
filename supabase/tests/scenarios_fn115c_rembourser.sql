-- FN-115c (02/11/2026) : le bouton « Rembourser » de l'ecran Finance.
-- Migration 20261105100000. Decision du directeur du 01/11/2026 (points 2, 3,
-- 7) ; regle de delai en attente du directeur (le texte en vigueur : premiere
-- semaine, 7 jours, colonne de la politique).
--   1. la direction seule lit les paiements, les eleves remboursables et
--      confirme ; un tuteur, un eleve, un comptable, anon sont refuses ;
--   2. dans le delai : ce qui a ete paye moins les seances suivies, au prix
--      d'une seance tire de la politique (tarif / seances du mois) ;
--   3. la confirmation est plafonnee au montant propose ; un double clic
--      (meme cle, ou deux cles) ne cree qu'une demande ;
--   4. la fonction Edge relit la demande ; le resultat Stripe note
--      l'identifiant ; le webhook retrouve le profil par cet identifiant,
--      rend la part a ce seul eleve, solde la demande ;
--   5. apres le delai : rien pour un mois paye ; pour une formule payee
--      d'avance, les mois commences au prix mensuel normal, le reste rendu ;
--   6. droits des fonctions du prestataire (service_role seulement).
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
    RAISE EXCEPTION 'FN-115c ROUGE : %', p_label;
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
    RAISE EXCEPTION 'FN-115c ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
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
  $$ SELECT ('fc000000-0000-4000-8000-0000000000' || p)::uuid $$;
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
        AND params ->> 'commande_id' IS NOT NULL
        -- Seulement les destinataires de ce scenario : en CI, d'autres
        -- scenarios laissent des comptes de direction actifs dans la base.
        AND destinataire::text LIKE 'fc000000-%' $$;
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
SELECT pg_temp.id(x), 'fc-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','d1','e1','e2','e4','e5','ac']) AS x;
INSERT INTO public.households(id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['f1','f2','f3']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'FC', x.statut::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','FC-ADM-0001','admin',NULL,'Direction','active','female'),
   ('ac','FC-CPT-0001','accountant',NULL,'Karima','active','female'),
   ('b1','FC-ENS-0001','teacher',NULL,'Maryam','provisional_active','female'),
   ('d1','FC-TUT-0001','guardian','f1','Amina','active','female'),
   ('e1','FC-ELV-0001','student','f1','Yasmine','active','female'),
   ('e2','FC-ELV-0002','student','f1','Bilal','active','male'),
   ('e4','FC-ELV-0004','guardian','f2','Aicha','active','female'),
   ('e5','FC-ELV-0005','guardian','f3','Khadija','active','female')) AS x(id, mat, role, foyer, prenom, statut, genre);
UPDATE public.households SET primary_guardian_id = pg_temp.id('d1') WHERE id = pg_temp.id('f1');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e4') WHERE id = pg_temp.id('f2');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e5') WHERE id = pg_temp.id('f3');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.id(x), (CASE WHEN x IN ('e4','e5') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e4','e5']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fc000000-0000-4000-8000-000000000c01', pg_temp.id('b1'), 'enfant', 5, 'An-Nour FC', 1, 9, 'Europe/Paris'),
 ('fc000000-0000-4000-8000-000000000c03', pg_temp.id('b1'), 'adulte', 6, 'Al-Huda FC', 3, 20, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT x.g::uuid, pg_temp.id(x.e), pg_temp.mois() - interval '20 days'
  FROM (VALUES ('fc000000-0000-4000-8000-000000000c01','e1'), ('fc000000-0000-4000-8000-000000000c01','e2'),
               ('fc000000-0000-4000-8000-000000000c03','e4'), ('fc000000-0000-4000-8000-000000000c03','e5')) AS x(g, e);
-- e1 a 50 USD d'avance : les remboursements partiels le laissent positif.
INSERT INTO public.wallets(id, household_id, currency) VALUES
 ('fc000000-0000-4000-8000-000000000901', pg_temp.id('f1'), 'USD');
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
VALUES ('fc000000-0000-4000-8000-000000000901', 5000, 'USD', 'credit', pg_temp.id('e1'), now());

-- Une commande payee : recapitulatif, commande, session, evenement Stripe.
CREATE FUNCTION pg_temp.payer(p_titulaire text, p_foyer text, p_lignes jsonb, p_cle text, p_pi text)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_r jsonb; v_c uuid; v_total bigint;
BEGIN
  PERFORM pg_temp.qui(pg_temp.id(p_titulaire), 'guardian', pg_temp.id(p_foyer));
  EXECUTE 'SET LOCAL ROLE authenticated';
  v_r := public.recharge_verifier_montants(p_lignes);
  v_c := (public.recharge_payer((v_r ->> 'id')::uuid, ('fc000000-0000-4000-8000-000000' || p_cle)::uuid) ->> 'commandeId')::uuid;
  EXECUTE 'RESET ROLE';
  SELECT total_mineur INTO v_total FROM public.commandes_recharge WHERE id = v_c;
  EXECUTE 'SET LOCAL ROLE service_role';
  PERFORM public.recharge_attacher_session(v_c, pg_temp.id(p_titulaire), 'cs_' || p_pi,
    'https://checkout.stripe.com/c/cs_' || p_pi, 'test');
  IF public.recharge_evenement_stripe('evt_pay_' || p_pi, 'checkout.session.completed', 'test', v_c,
       'cs_' || p_pi, p_pi, 'paid', v_total, 'usd') <> 'credite' THEN
    RAISE EXCEPTION 'FN-115c ROUGE : paiement % non credite', p_pi;
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


CREATE FUNCTION pg_temp.propose(p_commande uuid, p_profil text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT private.fn115c_montant_propose(p_commande, pg_temp.id(p_profil)) $$;
CREATE FUNCTION pg_temp.montant(p_commande uuid, p_profil text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT (pg_temp.propose(p_commande, p_profil) ->> 'montant_mineur')::bigint $$;
-- Une seance suivie par l'eleve, apres le paiement.
CREATE FUNCTION pg_temp.seance_suivie(p_eleve text, p_n int) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_s uuid;
BEGIN
  INSERT INTO public.sessions(teacher_id, started_at, ended_at)
  VALUES (pg_temp.id('b1'), now() + make_interval(hours => p_n), now() + make_interval(hours => p_n, mins => 60))
  RETURNING id INTO v_s;
  INSERT INTO public.session_participants(session_id, profile_id, role, entered_at)
  VALUES (v_s, pg_temp.id(p_eleve), 'student', now() + make_interval(hours => p_n));
END $$;

-- La direction lit, comme elle lirait depuis l'ecran Finance.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.m1', pg_temp.mois_de('e1')::text, true);
RESET ROLE;

SELECT set_config('test.c1', pg_temp.payer('d1', 'f1', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e1'), 'mineur', current_setting('test.m1')::bigint, 'devise', 'USD')),
  '00c001', 'pi_fc_1')::text, true);
SELECT set_config('test.paye1', (SELECT montant_mineur FROM public.commandes_recharge_allocations
   WHERE commande_id = current_setting('test.c1')::uuid AND profile_id = pg_temp.id('e1'))::text, true);
SELECT set_config('test.prix', (SELECT pg_catalog.round(private.fac_tarif_profil(pg_temp.id('e1'),
   private.fac_politique_au(current_date))::numeric / 13)::bigint)::text, true);

-- ------------------------------------------------------------------
-- 1. La direction seule
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT * FROM public.remboursement_paiements_eleve('fc000000-0000-4000-8000-0000000000e1')$$,
  '1 : un tuteur ne lit pas les paiements remboursables');
SELECT pg_temp.refus($$SELECT * FROM public.remboursement_eleves_remboursables()$$,
  '1 : un tuteur ne lit pas les eleves remboursables');
SELECT pg_temp.refus(format($$SELECT public.remboursement_confirmer(%L, 'fc000000-0000-4000-8000-0000000000e1', 100, gen_random_uuid())$$,
  current_setting('test.c1')), '1 : un tuteur ne confirme aucun remboursement');
SELECT pg_temp.refus($$INSERT INTO public.remboursements_demandes(commande_id) VALUES (gen_random_uuid())$$,
  '1 : aucune ecriture directe dans remboursements_demandes');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.id('ac'), 'accountant');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format($$SELECT public.remboursement_confirmer(%L, 'fc000000-0000-4000-8000-0000000000e1', 100, gen_random_uuid())$$,
  current_setting('test.c1')), '1 : un comptable ne confirme pas (la direction seule)');
RESET ROLE;
SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT * FROM public.remboursement_eleves_remboursables()$$, '1 : anon refuse');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Dans le delai : paye moins les seances suivies
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.montant(current_setting('test.c1')::uuid, 'e1') = current_setting('test.paye1')::bigint
  AND pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'regle' = 'delai',
  '2 : aucune seance suivie : tout ce qui a ete paye');
SELECT pg_temp.seance_suivie('e1', 1);
SELECT pg_temp.seance_suivie('e1', 30);
SELECT pg_temp.vrai(pg_temp.montant(current_setting('test.c1')::uuid, 'e1')
    = current_setting('test.paye1')::bigint - 2 * current_setting('test.prix')::bigint
  AND (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'prix_seance_mineur')::bigint
    = current_setting('test.prix')::bigint
  AND current_setting('test.prix')::bigint IN (423, 500),
  '2 : deux seances suivies, au prix d''une seance de la politique (423 ou 500)');

SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.remboursement_eleves_remboursables() x WHERE x = pg_temp.id('e1')),
  '2 : e1 est remboursable : « Rembourser » apparait dans son menu');
SELECT pg_temp.vrai((SELECT count(*) = 1 AND min(montant_propose_mineur)
                       = current_setting('test.paye1')::bigint - 2 * current_setting('test.prix')::bigint
                       FROM public.remboursement_paiements_eleve(pg_temp.id('e1'))),
  '2 : la direction lit le paiement et le montant propose');

-- ------------------------------------------------------------------
-- 3. Confirmer : plafond et double clic
-- ------------------------------------------------------------------
SELECT pg_temp.refus(format($$SELECT public.remboursement_confirmer(%L, 'fc000000-0000-4000-8000-0000000000e1', %s, gen_random_uuid())$$,
  current_setting('test.c1'), current_setting('test.paye1')), '3 : au-dessus du montant propose : refuse');
SELECT set_config('test.d1', public.remboursement_confirmer(current_setting('test.c1')::uuid, pg_temp.id('e1'),
  1000, 'fc000000-0000-4000-8000-00000000d001')::text, true);
SELECT pg_temp.vrai(public.remboursement_confirmer(current_setting('test.c1')::uuid, pg_temp.id('e1'),
  1000, 'fc000000-0000-4000-8000-00000000d001') = current_setting('test.d1')::uuid,
  '3 : double clic, meme cle : la meme demande');
SELECT pg_temp.vrai(public.remboursement_confirmer(current_setting('test.c1')::uuid, pg_temp.id('e1'),
  1000, 'fc000000-0000-4000-8000-00000000d002') = current_setting('test.d1')::uuid,
  '3 : double clic, deux cles : toujours la meme demande');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.remboursements_demandes
                      WHERE commande_id = current_setting('test.c1')::uuid) = 1,
  '3 : une seule demande en base');
SELECT pg_temp.vrai(pg_temp.montant(current_setting('test.c1')::uuid, 'e1')
    = current_setting('test.paye1')::bigint - 2 * current_setting('test.prix')::bigint - 1000,
  '3 : la demande en cours est deduite du montant propose');

-- ------------------------------------------------------------------
-- 4. Fonction Edge, prestataire, webhook
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT paiement = 'pi_fc_1' AND montant_mineur = 1000 AND profil = pg_temp.id('e1')
                       AND etat = 'confirmee'
                       FROM public.remboursement_a_envoyer(current_setting('test.d1')::uuid)),
  '4 : la fonction Edge relit la demande cote serveur (paiement, montant, profil)');
SELECT pg_temp.refus(format($$SELECT public.remboursement_resultat_stripe(%L, 're_x', NULL)$$,
  current_setting('test.d1')), '4 : le resultat du prestataire n''est pas ecrit par un compte');
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(public.remboursement_resultat_stripe(current_setting('test.d1')::uuid, 're_fc_1', NULL) = 'envoyee',
  '4 : l''identifiant du remboursement Stripe est note');
SELECT pg_temp.vrai(public.remboursement_profil_stripe('re_fc_1') = pg_temp.id('e1'),
  '4 : le webhook retrouve le profil vise par cet identifiant');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.evt('evt_fc_r1', 'charge.refunded', 'pi_fc_1', 1000,
    p_profil := 'e1') = 'rembourse',
  '4 : le remboursement passe aux ecritures, vise sur e1');
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(public.remboursement_solder_stripe('re_fc_1'), '4 : la demande est soldee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT etat = 'remboursee' FROM public.remboursements_demandes
                      WHERE id = current_setting('test.d1')::uuid)
  AND (SELECT sum(montant_mineur) = 1000 FROM public.remboursements_paiement
        WHERE commande_id = current_setting('test.c1')::uuid AND profile_id = pg_temp.id('e1')),
  '4 : 10 USD rendus a e1, demande remboursee');
SELECT pg_temp.vrai(pg_temp.montant(current_setting('test.c1')::uuid, 'e1')
    = current_setting('test.paye1')::bigint - 2 * current_setting('test.prix')::bigint - 1000,
  '4 : le deja rendu reste deduit du montant propose');

-- ------------------------------------------------------------------
-- 5. Apres le delai
-- ------------------------------------------------------------------
UPDATE public.commandes_recharge SET confirme_le = now() - interval '20 days'
 WHERE id = current_setting('test.c1')::uuid;
SELECT pg_temp.vrai(pg_temp.montant(current_setting('test.c1')::uuid, 'e1') = 0
  AND pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'regle' = 'hors_delai',
  '5 : un mois paye, apres le delai : rien a rendre');
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.remboursement_eleves_remboursables() x WHERE x = pg_temp.id('e1')),
  '5 : « Rembourser » disparait du menu de e1');
SELECT pg_temp.refus(format($$SELECT public.remboursement_confirmer(%L, 'fc000000-0000-4000-8000-0000000000e1', 1, gen_random_uuid())$$,
  current_setting('test.c1')), '5 : rien a rembourser : refuse');
RESET ROLE;
-- Une formule payee d'avance (trois mois), commencee ce mois-ci.
INSERT INTO public.engagements_prepaiement(profile_id, formule, mois_debut, nb_mois, total_mineur, devise, commande_id)
VALUES (pg_temp.id('e1'), 'trimestriel', pg_temp.mois(), 3, current_setting('test.paye1')::bigint, 'USD',
        current_setting('test.c1')::uuid);
SELECT pg_temp.vrai(pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'regle' = 'prepaiement'
  AND (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'mois_commences')::int = 1
  AND pg_temp.montant(current_setting('test.c1')::uuid, 'e1')
      = GREATEST(current_setting('test.paye1')::bigint
                 - (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'prix_mensuel_mineur')::bigint
                 - 1000, 0),
  '5 : formule d''avance : un mois commence au prix mensuel normal, le reste rendu');

-- ------------------------------------------------------------------
-- 6. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'public.remboursement_resultat_stripe(uuid, text, text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.remboursement_profil_stripe(text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.remboursement_solder_stripe(text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.remboursement_confirmer(uuid, uuid, bigint, uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.fn115c_montant_propose(uuid, uuid)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.remboursements_demandes', 'INSERT'),
  '6 : les fonctions du prestataire au service_role seul ; aucune ecriture directe');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 25,
  'au moins 25 controles ont passe');
\o
SELECT 'FN-115c : scenarios verts' AS resultat;
ROLLBACK;
