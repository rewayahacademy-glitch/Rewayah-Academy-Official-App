-- REMB-14 (02/11/2026) : le delai de retractation vient de la politique.
-- Migration 20261106100000. Decision du directeur du 02/11/2026
-- (DECISION-TARIFS-2026-10-18.md) : pendant le delai de retractation (14 jours
-- a compter du paiement), on rembourse ce qui a ete paye moins les seances
-- suivies ; ensuite, une formule payee d'avance est remboursee du reste, mois
-- commences au prix mensuel normal, sans la remise ; un mois paye est du.
-- Cas R3 :
--   1. tarifs_publics() publie le delai, lisible sans connexion ;
--   2. J+10, delai 14 : paye moins les seances suivies ;
--   3. J+10, delai 7 (valeur d'aujourd'hui en production) : hors delai, rien
--      pour un mois paye : le delai n'est ecrit nulle part ailleurs que dans
--      la politique ;
--   4. J+40, mois paye : rien a rendre ;
--   5. J+40, trimestre paye d'avance : deux mois commences au prix mensuel
--      normal, le reste rendu.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
-- Montage repris de scenarios_fn115c_rembourser.sql (prefixe fd000000).
\o /dev/null
BEGIN;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '6 months')::date
 WHERE version = 'v1.0.0';
-- La decision du directeur : 14 jours, dans toutes les versions (la valeur
-- reelle se publie par une nouvelle version, par la direction).
UPDATE public.politiques_commerciales SET remboursement_delai_jours = 14;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '3 months')::date
 WHERE version = 'v2.0.0';
-- Une seule politique (v2.0.0) couvre le paiement d'il y a 40 jours et
-- aujourd'hui : le prix mensuel compte est celui du jour du paiement.
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
    RAISE EXCEPTION 'REMB-14 ROUGE : %', p_label;
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
    RAISE EXCEPTION 'REMB-14 ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
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
  $$ SELECT ('fd000000-0000-4000-8000-0000000000' || p)::uuid $$;
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
        AND destinataire::text LIKE 'fd000000-%' $$;
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
SELECT pg_temp.id(x), 'fd-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','d1','e1','e2','e4','e5','ac']) AS x;
INSERT INTO public.households(id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['f1','f2','f3']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'FC', x.statut::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','FD-ADM-0001','admin',NULL,'Direction','active','female'),
   ('ac','FD-CPT-0001','accountant',NULL,'Karima','active','female'),
   ('b1','FD-ENS-0001','teacher',NULL,'Maryam','provisional_active','female'),
   ('d1','FD-TUT-0001','guardian','f1','Amina','active','female'),
   ('e1','FD-ELV-0001','student','f1','Yasmine','active','female'),
   ('e2','FD-ELV-0002','student','f1','Bilal','active','male'),
   ('e4','FD-ELV-0004','guardian','f2','Aicha','active','female'),
   ('e5','FD-ELV-0005','guardian','f3','Khadija','active','female')) AS x(id, mat, role, foyer, prenom, statut, genre);
UPDATE public.households SET primary_guardian_id = pg_temp.id('d1') WHERE id = pg_temp.id('f1');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e4') WHERE id = pg_temp.id('f2');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e5') WHERE id = pg_temp.id('f3');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.id(x), (CASE WHEN x IN ('e4','e5') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e4','e5']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fd000000-0000-4000-8000-000000000c01', pg_temp.id('b1'), 'enfant', 5, 'An-Nour FD', 1, 9, 'Europe/Paris'),
 ('fd000000-0000-4000-8000-000000000c03', pg_temp.id('b1'), 'adulte', 6, 'Al-Huda FD', 3, 20, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT x.g::uuid, pg_temp.id(x.e), pg_temp.mois() - interval '20 days'
  FROM (VALUES ('fd000000-0000-4000-8000-000000000c01','e1'), ('fd000000-0000-4000-8000-000000000c01','e2'),
               ('fd000000-0000-4000-8000-000000000c03','e4'), ('fd000000-0000-4000-8000-000000000c03','e5')) AS x(g, e);
-- e1 a 50 USD d'avance : les remboursements partiels le laissent positif.
INSERT INTO public.wallets(id, household_id, currency) VALUES
 ('fd000000-0000-4000-8000-000000000901', pg_temp.id('f1'), 'USD');
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
VALUES ('fd000000-0000-4000-8000-000000000901', 5000, 'USD', 'credit', pg_temp.id('e1'), now());

-- Une commande payee : recapitulatif, commande, session, evenement Stripe.
CREATE FUNCTION pg_temp.payer(p_titulaire text, p_foyer text, p_lignes jsonb, p_cle text, p_pi text)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_r jsonb; v_c uuid; v_total bigint;
BEGIN
  PERFORM pg_temp.qui(pg_temp.id(p_titulaire), 'guardian', pg_temp.id(p_foyer));
  EXECUTE 'SET LOCAL ROLE authenticated';
  v_r := public.recharge_verifier_montants(p_lignes);
  v_c := (public.recharge_payer((v_r ->> 'id')::uuid, ('fd000000-0000-4000-8000-000000' || p_cle)::uuid) ->> 'commandeId')::uuid;
  EXECUTE 'RESET ROLE';
  SELECT total_mineur INTO v_total FROM public.commandes_recharge WHERE id = v_c;
  EXECUTE 'SET LOCAL ROLE service_role';
  PERFORM public.recharge_attacher_session(v_c, pg_temp.id(p_titulaire), 'cs_' || p_pi,
    'https://checkout.stripe.com/c/cs_' || p_pi, 'test');
  IF public.recharge_evenement_stripe('evt_pay_' || p_pi, 'checkout.session.completed', 'test', v_c,
       'cs_' || p_pi, p_pi, 'paid', v_total, 'usd') <> 'credite' THEN
    RAISE EXCEPTION 'REMB-14 ROUGE : paiement % non credite', p_pi;
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


-- ------------------------------------------------------------------
-- 1. Le delai publie, lisible sans connexion
-- ------------------------------------------------------------------
SET LOCAL ROLE anon;
SELECT pg_temp.vrai((public.tarifs_publics() #>> '{courante,remboursementDelaiJours}')::int = 14,
  '1 : tarifs_publics() publie le delai de la politique en vigueur (14), sans connexion');
RESET ROLE;

-- Le mois de e1, paye aujourd'hui.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.m1', pg_temp.mois_de('e1')::text, true);
RESET ROLE;
SELECT set_config('test.c1', pg_temp.payer('d1', 'f1', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e1'), 'mineur', current_setting('test.m1')::bigint, 'devise', 'USD')),
  '00d001', 'pi_fd_1')::text, true);
SELECT set_config('test.paye1', (SELECT montant_mineur FROM public.commandes_recharge_allocations
   WHERE commande_id = current_setting('test.c1')::uuid AND profile_id = pg_temp.id('e1'))::text, true);

-- ------------------------------------------------------------------
-- 2. J+10, delai 14 : paye moins les seances suivies
-- ------------------------------------------------------------------
UPDATE public.commandes_recharge SET confirme_le = now() - interval '10 days'
 WHERE id = current_setting('test.c1')::uuid;
SELECT pg_temp.seance_suivie('e1', 1);
SELECT pg_temp.vrai(pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'regle' = 'delai'
  AND (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'delai_jours')::int = 14
  AND (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'jours_depuis_paiement')::int = 10
  AND (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'seances_suivies')::int = 1
  AND pg_temp.montant(current_setting('test.c1')::uuid, 'e1')
      = current_setting('test.paye1')::bigint
        - (pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'prix_seance_mineur')::bigint
  AND pg_temp.montant(current_setting('test.c1')::uuid, 'e1') > 0,
  '2 : J+10, delai 14 : ce qui a ete paye, moins la seance suivie');

-- ------------------------------------------------------------------
-- 3. J+10, delai 7 : le delai vient de la politique, rien n'est en dur
-- ------------------------------------------------------------------
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales SET remboursement_delai_jours = 7;
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;
SELECT pg_temp.vrai(pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'regle' = 'hors_delai'
  AND pg_temp.montant(current_setting('test.c1')::uuid, 'e1') = 0,
  '3 : J+10, delai 7 : hors delai, un mois paye est du');
SET LOCAL ROLE anon;
SELECT pg_temp.vrai((public.tarifs_publics() #>> '{courante,remboursementDelaiJours}')::int = 7,
  '3 : tarifs_publics() suit la politique (7)');
RESET ROLE;
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales SET remboursement_delai_jours = 14;
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

-- ------------------------------------------------------------------
-- 4. J+40, mois paye : rien a rendre
-- ------------------------------------------------------------------
UPDATE public.commandes_recharge SET confirme_le = now() - interval '40 days'
 WHERE id = current_setting('test.c1')::uuid;
SELECT pg_temp.vrai(pg_temp.propose(current_setting('test.c1')::uuid, 'e1') ->> 'regle' = 'hors_delai'
  AND pg_temp.montant(current_setting('test.c1')::uuid, 'e1') = 0,
  '4 : J+40, un mois paye : rien a rendre');

-- ------------------------------------------------------------------
-- 5. J+40, trimestre paye d'avance : mois commences au prix normal
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.t1', (SELECT ((f ->> 'montant')::jsonb ->> 'mineur')
   FROM jsonb_array_elements(public.recharge_beneficiaires()) AS x,
        jsonb_array_elements(x -> 'formules') AS f
  WHERE x ->> 'id' = pg_temp.id('e1')::text AND f ->> 'formule' = 'trimestriel'), true);
RESET ROLE;
SELECT pg_temp.vrai(nullif(current_setting('test.t1'), '') IS NOT NULL,
  '5 : le trimestre est propose a e1, son mois regle');
SELECT set_config('test.c2', pg_temp.payer('d1', 'f1', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('e1'), 'mineur', current_setting('test.t1')::bigint, 'devise', 'USD')),
  '00d002', 'pi_fd_2')::text, true);
-- Le trimestre a ete paye il y a 40 jours et a commence le mois suivant :
-- deux mois sont commences aujourd'hui.
UPDATE public.commandes_recharge SET confirme_le = now() - interval '40 days'
 WHERE id = current_setting('test.c2')::uuid;
UPDATE public.engagements_prepaiement
   SET mois_debut = (date_trunc('month', now() - interval '40 days') + interval '1 month')::date
 WHERE commande_id = current_setting('test.c2')::uuid;
SELECT set_config('test.mois_c', (EXTRACT(YEAR FROM age(date_trunc('month', now())::date,
   (date_trunc('month', now() - interval '40 days') + interval '1 month')::date))::int * 12
 + EXTRACT(MONTH FROM age(date_trunc('month', now())::date,
   (date_trunc('month', now() - interval '40 days') + interval '1 month')::date))::int + 1)::text, true);
SELECT pg_temp.vrai(pg_temp.propose(current_setting('test.c2')::uuid, 'e1') ->> 'regle' = 'prepaiement'
  AND (pg_temp.propose(current_setting('test.c2')::uuid, 'e1') ->> 'mois_commences')::int
      = current_setting('test.mois_c')::int
  AND (pg_temp.propose(current_setting('test.c2')::uuid, 'e1') ->> 'mois_commences')::int BETWEEN 1 AND 2
  AND pg_temp.montant(current_setting('test.c2')::uuid, 'e1')
      = current_setting('test.t1')::bigint
        - current_setting('test.mois_c')::int
          * (pg_temp.propose(current_setting('test.c2')::uuid, 'e1') ->> 'prix_mensuel_mineur')::bigint
  AND pg_temp.montant(current_setting('test.c2')::uuid, 'e1') > 0,
  '5 : J+40, trimestre : les mois commences au prix mensuel normal, sans la remise, le reste rendu');
-- Le prix mensuel compte est le prix normal, pas celui de la formule.
SELECT pg_temp.vrai((pg_temp.propose(current_setting('test.c2')::uuid, 'e1') ->> 'prix_mensuel_mineur')::bigint
      = current_setting('test.m1')::bigint
  AND (pg_temp.propose(current_setting('test.c2')::uuid, 'e1') ->> 'politique') = 'v2.0.0'
  AND current_setting('test.m1')::bigint * 3 > current_setting('test.t1')::bigint,
  '5 : le prix mensuel compte est sans la remise du trimestre');

-- ------------------------------------------------------------------
-- 6. La direction publie une nouvelle version (cassee depuis FN-115c)
-- ------------------------------------------------------------------
-- La copie de la derniere version, en JSON, telle que l'ecran la relit.
SELECT set_config('test.pol', (SELECT private.fac_politique_json(p, 'publiee')::text
   FROM public.politiques_commerciales p ORDER BY p.date_effet DESC LIMIT 1), true);
SELECT pg_temp.vrai((current_setting('test.pol')::jsonb ->> 'remboursementDelaiJours')::int = 14,
  '6 : le JSON de la politique porte le delai (relu par l''ecran)');
CREATE FUNCTION pg_temp.publier(p_version text, p_jours int, p_jour_effet int) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb := current_setting('test.pol')::jsonb;
BEGIN
  v := jsonb_set(jsonb_set(v, '{version}', to_jsonb(p_version)), '{dateEffet}',
                 to_jsonb((current_date + p_jour_effet)::text));
  v := CASE WHEN p_jours IS NULL THEN v - 'remboursementDelaiJours'
            ELSE jsonb_set(v, '{remboursementDelaiJours}', to_jsonb(p_jours)) END;
  RETURN public.publier_politique_commerciale(v);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.publier(text, int, int) TO authenticated;
CREATE FUNCTION pg_temp.qui_aal2(p_id uuid) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := '{"aal":"aal2","app_metadata":{"role":"admin"}}';
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('test.uid', p_id::text, true);
  PERFORM set_config('request.jwt.claims', v_jwt, true);
  PERFORM set_config('test.jwt', v_jwt, true);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui_aal2(uuid) TO authenticated;
SELECT set_config('test.vsuiv', private.fac_version_suivante(
  (SELECT version FROM public.politiques_commerciales ORDER BY date_effet DESC LIMIT 1)), true);
SELECT pg_temp.qui_aal2(pg_temp.id('a1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus(format('SELECT pg_temp.publier(%L, 99, 40)', current_setting('test.vsuiv')),
  '6 : delai hors bornes (99) : refuse');
-- Sans la cle : la nouvelle version reprend le delai de la precedente.
-- (La reponse est faite de la ligne d'avant le declencheur : la table fait foi.)
SELECT pg_temp.vrai((pg_temp.publier(current_setting('test.vsuiv'), NULL, 40) ->> 'version')
                     = current_setting('test.vsuiv'),
  '6 : publication sans la cle : publiee (elle echouait depuis FN-115c)');
RESET ROLE;
SELECT pg_temp.vrai((SELECT remboursement_delai_jours = 14 AND seances_par_mois = 13
                       FROM public.politiques_commerciales WHERE version = current_setting('test.vsuiv')),
  '6 : la version publiee garde le delai et les seances du mois');
SELECT set_config('test.vsuiv2', private.fac_version_suivante(current_setting('test.vsuiv')), true);
SELECT pg_temp.qui_aal2(pg_temp.id('a1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((pg_temp.publier(current_setting('test.vsuiv2'), 21, 50)
                     ->> 'remboursementDelaiJours')::int = 21,
  '6 : la direction publie un autre delai (21)');
RESET ROLE;

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 13,
  'au moins 8 controles ont passe');
\o
SELECT 'REMB-14 : scenarios verts' AS resultat;
ROLLBACK;
