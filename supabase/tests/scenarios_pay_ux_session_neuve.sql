-- PAY-UX (02/11/2026, migration 20261105900000) : un formulaire neuf a chaque
-- nouveau depart, sans jamais deux credits (regle « aucun double paiement »,
-- pilote, 02/11/2026). Le montage est celui de scenarios_fi_br06_recharge_stripe.sql.
--   1. droits : remplacer une session reste au serveur ;
--   2. les lignes de paiement disent la formule et le mois ;
--   3. nouveau depart : l'ancienne session est remplacee (apres son
--      expiration chez Stripe, faite par la fonction Edge) ; un evenement de
--      l'ancienne ne credite rien ; la nouvelle, payee, credite une fois ;
--   4. un evenement rejoue deux fois ne credite qu'une fois ;
--   5. une commande payee ne se remplace plus ; une ancienne session
--      inconnue ne remplace rien.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

-- FAC-E-01 : ce scenario eprouve la politique v1 ; la v2 (en vigueur le
-- 1er novembre 2026) est retiree le temps du scenario, annule a la fin.
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
-- TRANSPARENCE (31/10) : sa repartition s'en va avec elle.
DELETE FROM public.repartitions_paiement WHERE politique_version = 'v2.0.0';
DELETE FROM public.politiques_commerciales WHERE version = 'v2.0.0';
-- REMB-14 (migration 20261106100000) : la v2.1.0, copie de la v2 avec le
-- delai de 14 jours, s'en va aussi (sans effet tant qu'elle n'existe pas).
DELETE FROM public.repartitions_paiement WHERE politique_version = 'v2.1.0';
DELETE FROM public.politiques_commerciales WHERE version = 'v2.1.0';
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
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.refus($q$SELECT public.recharge_remplacer_session(gen_random_uuid(), gen_random_uuid(), 'cs_a', 'cs_b', 'stripe-integre:cs_b', 'test')$q$,
  '42501', 'droits : le client ne remplace jamais une session');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.recharge_remplacer_session(gen_random_uuid(), gen_random_uuid(), 'cs_a', 'cs_b', 'stripe-integre:cs_b', 'test')$q$,
  '42501', 'droits : anon ne remplace jamais une session');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. La commande et ses lignes
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT set_config('test.r1', public.recharge_verifier_montants(jsonb_build_array(
  jsonb_build_object('profilId', 'f6000000-0000-4000-8000-0000000000e1', 'mineur', current_setting('test.tarif')::bigint, 'devise', current_setting('test.devise'))))::text, true);
SELECT set_config('test.c1', public.recharge_payer((current_setting('test.r1')::jsonb ->> 'id')::uuid,
  'f6000000-0000-4000-8000-00000000b001')::text, true);
SELECT set_config('test.cid', current_setting('test.c1')::jsonb ->> 'commandeId', true);
SELECT pg_temp.vrai((SELECT bool_and(l ? 'formule' AND l ->> 'mois' ~ '^\d{4}-\d{2}-01$' AND l ? 'prenom' AND l ? 'mineur')
                       FROM jsonb_array_elements(current_setting('test.c1')::jsonb -> 'lignesPaiement') l),
  'lignes : formule et mois en plus, prenom et montant gardes (ancien code)');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Nouveau depart : une nouvelle session remplace l'ancienne
-- ------------------------------------------------------------------
SET LOCAL ROLE service_role;
SELECT public.recharge_attacher_session(current_setting('test.cid')::uuid, 'f6000000-0000-4000-8000-0000000000d1',
  'cs_ancienne', 'stripe-integre:cs_ancienne', 'test');
SELECT pg_temp.refus(format($q$SELECT public.recharge_remplacer_session(%L, 'f6000000-0000-4000-8000-0000000000d1', 'cs_inconnue', 'cs_neuve', 'stripe-integre:cs_neuve', 'test')$q$,
  current_setting('test.cid')), 'P0002', 'remplacement : une ancienne session qui n''est pas celle de la commande ne remplace rien');
SELECT pg_temp.refus(format($q$SELECT public.recharge_remplacer_session(%L, 'f6000000-0000-4000-8000-0000000000d2', 'cs_ancienne', 'cs_neuve', 'stripe-integre:cs_neuve', 'test')$q$,
  current_setting('test.cid')), 'P0002', 'remplacement : un autre titulaire ne remplace rien');
SELECT public.recharge_remplacer_session(current_setting('test.cid')::uuid, 'f6000000-0000-4000-8000-0000000000d1',
  'cs_ancienne', 'cs_neuve', 'stripe-integre:cs_neuve', 'test');
SELECT public.recharge_remplacer_session(current_setting('test.cid')::uuid, 'f6000000-0000-4000-8000-0000000000d1',
  'cs_ancienne', 'cs_neuve', 'stripe-integre:cs_neuve', 'test');
RESET ROLE;
SELECT pg_temp.vrai((SELECT session_prestataire = 'cs_neuve' AND url_paiement = 'stripe-integre:cs_neuve'
                            AND etat = 'awaiting_confirmation'
                       FROM public.commandes_recharge WHERE id = current_setting('test.cid')::uuid),
  'remplacement : la commande porte la nouvelle session, toujours en attente ; un second appel identique ne change rien');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('f6000000-0000-4000-8000-0000000000d1', 'guardian', 'f6000000-0000-4000-8000-0000000000f1');
SELECT pg_temp.vrai(public.recharge_payer((current_setting('test.r1')::jsonb ->> 'id')::uuid,
  'f6000000-0000-4000-8000-00000000b001') ->> 'urlPaiement' = 'stripe-integre:cs_neuve',
  'reprise : la meme cle rend la nouvelle session');
RESET ROLE;

SET LOCAL ROLE service_role;
-- L'ancienne session, expiree chez Stripe : son evenement d'expiration ne
-- touche pas la commande, un paiement de l'ancienne ne credite rien.
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_pu_1', 'checkout.session.expired', 'test',
  current_setting('test.cid')::uuid, 'cs_ancienne', NULL, 'unpaid', NULL, NULL) = 'commande_inconnue',
  'ancienne session expiree : la commande n''est pas marquee perimee');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_pu_2', 'checkout.session.completed', 'test',
  current_setting('test.cid')::uuid, 'cs_ancienne', 'pi_ancien', 'paid',
  current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'commande_inconnue',
  'ancienne session : un paiement d''elle ne credite rien');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_pu_3', 'checkout.session.completed', 'test',
  current_setting('test.cid')::uuid, 'cs_neuve', 'pi_neuf', 'paid',
  current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'credite',
  'nouvelle session payee : credit');
-- 4. Le meme evenement rejoue, puis un second evenement de la meme session.
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_pu_3', 'checkout.session.completed', 'test',
  current_setting('test.cid')::uuid, 'cs_neuve', 'pi_neuf', 'paid',
  current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'doublon',
  'webhook rejoue : rien de plus');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_pu_4', 'checkout.session.completed', 'test',
  current_setting('test.cid')::uuid, 'cs_neuve', 'pi_neuf', 'paid',
  current_setting('test.tarif')::bigint, lower(current_setting('test.devise'))) = 'deja_credite',
  'second evenement de la meme session : rien de plus');
-- 5. Une commande payee ne se remplace plus.
SELECT pg_temp.refus(format($q$SELECT public.recharge_remplacer_session(%L, 'f6000000-0000-4000-8000-0000000000d1', 'cs_neuve', 'cs_troisieme', 'stripe-integre:cs_troisieme', 'test')$q$,
  current_setting('test.cid')), 'P0002', 'commande payee : aucune nouvelle session');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.wallet_entries WHERE reference_id = current_setting('test.cid')::uuid
                      AND reference_type = 'credit') = 1,
  'un seul credit pour la commande, quelles que soient les sessions et les evenements');

DO $fin$ BEGIN RAISE NOTICE 'PAY-UX session neuve : scenario vert'; END $fin$;

ROLLBACK;
