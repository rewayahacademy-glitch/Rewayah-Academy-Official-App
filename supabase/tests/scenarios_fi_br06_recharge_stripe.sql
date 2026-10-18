-- FI-BR-06 (18/10/2026) : le paiement des familles par le prestataire.
-- Migration 20261018100000.
--   1. droits : seul le titulaire du foyer recharge ; la session du
--      prestataire et sa confirmation restent au serveur ;
--   2. montants proposes et recapitulatif arretes par le serveur ;
--   3. commande idempotente ; le retour du navigateur ne confirme rien ;
--   4. seul un evenement encaisse, du bon environnement, du bon montant,
--      credite ; un evenement rejoue ou une double confirmation ne credite
--      qu'une fois ;
--   5. montant incoherent, refus, expiration, session etrangere : rien.
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
 ('f6000000-0000-4000-8000-0000000000a1','f6-admin@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000a2','f6-admin-suspendu@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000c1','f6-compta@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000b1','f6-ens@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000d1','f6-tit@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e1','f6-e1@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e2','f6-e2@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000d2','f6-tit2@test.invalid'),
 ('f6000000-0000-4000-8000-0000000000e3','f6-e3@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('f6000000-0000-4000-8000-0000000000f1','Europe/Paris'), ('f6000000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('f6000000-0000-4000-8000-0000000000a1','F6-ADM-0001','admin',NULL,'Direction','F6','active','female'),
 ('f6000000-0000-4000-8000-0000000000a2','F6-ADM-0002','admin',NULL,'Direction','Suspendue','disabled','female'),
 ('f6000000-0000-4000-8000-0000000000c1','F6-CPT-0001','accountant',NULL,'Compta','F6','active','male'),
 ('f6000000-0000-4000-8000-0000000000b1','F6-ENS-0001','teacher',NULL,'Maryam','F6','provisional_active','female'),
 ('f6000000-0000-4000-8000-0000000000d1','F6-TUT-0001','guardian','f6000000-0000-4000-8000-0000000000f1','Amina','F1','active','female'),
 ('f6000000-0000-4000-8000-0000000000e1','F6-ELV-0001','student','f6000000-0000-4000-8000-0000000000f1','Yasmine','F1','active','female'),
 ('f6000000-0000-4000-8000-0000000000e2','F6-ELV-0002','student','f6000000-0000-4000-8000-0000000000f1','Bilal','F1','active','male'),
 ('f6000000-0000-4000-8000-0000000000d2','F6-TUT-0002','guardian','f6000000-0000-4000-8000-0000000000f2','Awa','F2','active','female'),
 ('f6000000-0000-4000-8000-0000000000e3','F6-ELV-0003','student','f6000000-0000-4000-8000-0000000000f2','Omar','F2','active','male');
UPDATE public.households SET primary_guardian_id = 'f6000000-0000-4000-8000-0000000000d1'
 WHERE id = 'f6000000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = 'f6000000-0000-4000-8000-0000000000d2'
 WHERE id = 'f6000000-0000-4000-8000-0000000000f2';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('f6000000-0000-4000-8000-0000000000e1','minor','child'),
 ('f6000000-0000-4000-8000-0000000000e2','minor','standard'),
 ('f6000000-0000-4000-8000-0000000000e3','minor','standard');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('f6000000-0000-4000-8000-000000000c01','f6000000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour F6',1,9,'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('f6000000-0000-4000-8000-000000000c01','f6000000-0000-4000-8000-0000000000e1',
  date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '20 days'),
 ('f6000000-0000-4000-8000-000000000c01','f6000000-0000-4000-8000-0000000000e2',
  date_trunc('month', now() AT TIME ZONE 'Europe/Paris') - interval '20 days');

-- Le tarif enfant publie, pour les montants attendus.
SELECT set_config('test.tarif', (private.fac_politique_au(private.fac_aujourdhui())).tarif_enfant_mineur::text, true);
SELECT set_config('test.devise', (private.fac_politique_au(private.fac_aujourdhui())).devise, true);

-- ------------------------------------------------------------------
-- 1. Droits
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000b1', 'teacher');
SELECT pg_temp.refus($q$SELECT public.recharge_beneficiaires()$q$, '42501', 'droits : un enseignant ne recharge pas');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000e1', 'student', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.recharge_beneficiaires()$q$, '42501', 'droits : un enfant ne recharge pas');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.recharge_attacher_session(gen_random_uuid(), gen_random_uuid(), 'cs_x', 'https://x', 'test')$q$,
  '42501', 'droits : le client n''attache jamais une session');
SELECT pg_temp.refus($q$SELECT public.recharge_evenement_stripe('evt_x', 'checkout.session.completed', 'test', gen_random_uuid(), 'cs_x', 'pi_x', 'paid', 1, 'USD')$q$,
  '42501', 'droits : le client ne confirme jamais un paiement');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.recharge_beneficiaires()$q$, '42501', 'anon : aucune recharge');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Beneficiaires et recapitulatif
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(jsonb_array_length(public.recharge_beneficiaires()) = 2
  AND (SELECT bool_and(x -> 'montantsProposes' @> jsonb_build_array(jsonb_build_object(
         'mineur', current_setting('test.tarif')::bigint, 'devise', current_setting('test.devise'))))
         FROM jsonb_array_elements(public.recharge_beneficiaires()) x),
  'beneficiaires : les deux enfants du foyer, un mois au tarif publie propose');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": 1234, "devise": "%s"}]')$q$,
  'f6000000-0000-4000-8000-0000000000e1', current_setting('test.devise')), '22023', 'recapitulatif : un montant non propose est refuse');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": %s, "devise": "%s"}]')$q$,
  'f6000000-0000-4000-8000-0000000000e3', current_setting('test.tarif'), current_setting('test.devise')), '42501', 'recapitulatif : un enfant d''un autre foyer est refuse');
SELECT set_config('test.r1', public.recharge_verifier_montants(jsonb_build_array(
  jsonb_build_object('profilId', 'f6000000-0000-4000-8000-0000000000e1', 'mineur', current_setting('test.tarif')::bigint, 'devise', current_setting('test.devise')),
  jsonb_build_object('profilId', 'f6000000-0000-4000-8000-0000000000e2', 'mineur', 2 * current_setting('test.tarif')::bigint, 'devise', current_setting('test.devise'))))::text, true);
SELECT pg_temp.vrai((current_setting('test.r1')::jsonb #>> '{total,mineur}')::bigint = 3 * current_setting('test.tarif')::bigint
  AND jsonb_array_length(current_setting('test.r1')::jsonb -> 'lignes') = 2,
  'recapitulatif : total arrete par le serveur, une ligne par profil');

-- ------------------------------------------------------------------
-- 3. La commande
-- ------------------------------------------------------------------
SELECT set_config('test.c1', public.recharge_payer((current_setting('test.r1')::jsonb ->> 'id')::uuid,
  'f6000000-0000-4000-8000-00000000a001')::text, true);
SELECT set_config('test.cid', current_setting('test.c1')::jsonb ->> 'commandeId', true);
SELECT pg_temp.vrai(current_setting('test.c1')::jsonb ->> 'etat' = 'preparing'
  AND current_setting('test.c1')::jsonb ->> 'reference' LIKE 'RWY-%'
  AND jsonb_array_length(current_setting('test.c1')::jsonb -> 'lignesPaiement') = 2,
  'commande : creee, en preparation, avec sa reference');
SELECT pg_temp.vrai(public.recharge_payer((current_setting('test.r1')::jsonb ->> 'id')::uuid,
  'f6000000-0000-4000-8000-00000000a001') ->> 'commandeId' = current_setting('test.cid'),
  'commande : la meme cle rend la meme commande');
SELECT pg_temp.refus(format($q$SELECT public.recharge_payer(%L, gen_random_uuid())$q$, current_setting('test.r1')::jsonb ->> 'id'),
  '22023', 'commande : un recapitulatif ne se paie qu''une fois');
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d2', 'guardian', 'f6000000-0000-4000-8000-0000000000f2');
SELECT pg_temp.refus(format($q$SELECT public.recharge_suivre(%L)$q$, current_setting('test.cid')),
  'P0002', 'suivi : un autre titulaire ne lit pas la commande');
RESET ROLE;

-- Le serveur ouvre la page du prestataire.
SET LOCAL ROLE service_role;
SELECT public.recharge_attacher_session(current_setting('test.cid')::uuid, 'f6000000-0000-4000-8000-0000000000d1', 'cs_test_1', 'https://checkout.stripe.com/c/cs_test_1', 'test');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(public.recharge_suivre(current_setting('test.cid')::uuid) ->> 'etat' = 'awaiting_confirmation',
  'retour du navigateur : en attente de confirmation, jamais confirme');
SELECT pg_temp.vrai(public.recharge_payer((current_setting('test.r1')::jsonb ->> 'id')::uuid,
  'f6000000-0000-4000-8000-00000000a001') ->> 'urlPaiement' = 'https://checkout.stripe.com/c/cs_test_1',
  'reprise : la meme commande rend la meme page de paiement');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.wallet_entries WHERE beneficiaire_id IN ('f6000000-0000-4000-8000-0000000000e1', 'f6000000-0000-4000-8000-0000000000e2')),
  'avant le prestataire : aucun credit');

-- ------------------------------------------------------------------
-- 4. Le prestataire confirme
-- ------------------------------------------------------------------
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_1', 'checkout.session.completed', 'test',
  current_setting('test.cid')::uuid, 'cs_test_1', 'pi_1', 'unpaid',
  3 * current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'paiement_en_attente',
  'prestataire : un paiement pas encore encaisse ne credite rien');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_2', 'checkout.session.async_payment_succeeded', 'live',
  current_setting('test.cid')::uuid, 'cs_test_1', 'pi_1', 'paid',
  3 * current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'environnement_different',
  'prestataire : un evenement d''un autre environnement ne credite rien');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_3', 'checkout.session.async_payment_succeeded', 'test',
  current_setting('test.cid')::uuid, 'cs_test_1', 'pi_1', 'paid',
  3 * current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'credite',
  'prestataire : paiement encaisse, chaque profil credite de sa part');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_3', 'checkout.session.async_payment_succeeded', 'test',
  current_setting('test.cid')::uuid, 'cs_test_1', 'pi_1', 'paid',
  3 * current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'doublon',
  'idempotence : le meme evenement recu deux fois ne fait rien');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_4', 'checkout.session.completed', 'test',
  current_setting('test.cid')::uuid, 'cs_test_1', 'pi_1', 'paid',
  3 * current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'deja_credite',
  'double confirmation : un seul credit');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.wallet_entries WHERE reference_id = current_setting('test.cid')::uuid
                      AND reference_type = 'credit' AND confirme_par_prestataire_le IS NOT NULL) = 2
  AND (SELECT amount_minor FROM public.wallet_entries WHERE reference_id = current_setting('test.cid')::uuid
        AND beneficiaire_id = 'f6000000-0000-4000-8000-0000000000e2') = 2 * current_setting('test.tarif')::bigint,
  'credit : deux ecritures, chacune au nom de son profil');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT set_config('test.s1', public.recharge_suivre(current_setting('test.cid')::uuid)::text, true);
SELECT pg_temp.vrai(current_setting('test.s1')::jsonb ->> 'etat' = 'completed'
  AND current_setting('test.s1')::jsonb ->> 'moyen' = 'web_stripe'
  AND (SELECT bool_and(a -> 'nouveauSolde' IS NOT NULL AND a -> 'nouveauSolde' <> 'null'::jsonb)
         FROM jsonb_array_elements(current_setting('test.s1')::jsonb -> 'allocations') a),
  'suivi : termine, moyen et nouveau solde par profil');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'recharge_creditee'),
  'credit : inscrit au journal');

-- ------------------------------------------------------------------
-- 5. Echecs : montant incoherent, refus, expiration
-- ------------------------------------------------------------------
CREATE FUNCTION pg_temp.commande(p_cle uuid, p_session text) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v_r jsonb; v_c uuid;
BEGIN
  SET LOCAL ROLE authenticated;
  PERFORM pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
  v_r := public.recharge_verifier_montants(jsonb_build_array(jsonb_build_object(
    'profilId', 'f6000000-0000-4000-8000-0000000000e1',
    'mineur', current_setting('test.tarif')::bigint, 'devise', current_setting('test.devise'))));
  v_c := (public.recharge_payer((v_r ->> 'id')::uuid, p_cle) ->> 'commandeId')::uuid;
  RESET ROLE;
  SET LOCAL ROLE service_role;
  PERFORM public.recharge_attacher_session(v_c, 'f6000000-0000-4000-8000-0000000000d1', p_session, 'https://x/' || p_session, 'test');
  RESET ROLE;
  RETURN v_c;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.commande(uuid, text) TO authenticated, service_role;
SELECT set_config('test.c2', pg_temp.commande('f6000000-0000-4000-8000-00000000a002', 'cs_test_2')::text, true);
SELECT set_config('test.c3', pg_temp.commande('f6000000-0000-4000-8000-00000000a003', 'cs_test_3')::text, true);
SELECT set_config('test.c4', pg_temp.commande('f6000000-0000-4000-8000-00000000a004', 'cs_test_4')::text, true);
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_5', 'checkout.session.completed', 'test',
  current_setting('test.c2')::uuid, 'cs_test_2', 'pi_2', 'paid', 1, lower(current_setting('test.devise'))) = 'montant_incoherent',
  'echec : un montant different de la commande ne credite rien');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_6', 'checkout.session.async_payment_failed', 'test',
  current_setting('test.c3')::uuid, 'cs_test_3', 'pi_3', 'unpaid', NULL, NULL) = 'echec',
  'echec : paiement refuse par la banque');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_7', 'checkout.session.expired', 'test',
  current_setting('test.c4')::uuid, 'cs_test_4', NULL, 'unpaid', NULL, NULL) = 'perime',
  'perime : page de paiement expiree');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_8', 'checkout.session.completed', 'test',
  current_setting('test.c4')::uuid, 'cs_autre', 'pi_4', 'paid', current_setting('test.tarif')::bigint,
  lower(current_setting('test.devise'))) = 'commande_inconnue',
  'securite : une session qui n''est pas celle de la commande ne credite rien');
RESET ROLE;
SELECT pg_temp.vrai((SELECT etat FROM public.commandes_recharge WHERE id = current_setting('test.c2')::uuid) = 'failed'
  AND (SELECT etat FROM public.commandes_recharge WHERE id = current_setting('test.c3')::uuid) = 'failed'
  AND (SELECT etat FROM public.commandes_recharge WHERE id = current_setting('test.c4')::uuid) = 'stale'
  AND NOT EXISTS (SELECT 1 FROM public.wallet_entries WHERE reference_id IN (
        current_setting('test.c2')::uuid, current_setting('test.c3')::uuid, current_setting('test.c4')::uuid)),
  'echecs : aucun credit');

\o
SELECT 'FI-BR-06 recharge Stripe : tous les controles sont verts' AS bilan;
ROLLBACK;
