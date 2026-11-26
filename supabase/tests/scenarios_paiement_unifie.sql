-- PAIEMENT-UNIFIE (23/11/2026), migration 20261202000000 : P2 (taxe), P4 (porte « jamais paye »),
-- P5 (fiche et « demander maintenant »), P6 (moment du premier paiement).
-- A rejouer sur une base neuve : fixtures inserees puis annulees.
\set ON_ERROR_STOP 1
BEGIN;
SET LOCAL client_min_messages = warning;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PAIEMENT-UNIFIE ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
END $$;
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'PAIEMENT-UNIFIE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'PAIEMENT-UNIFIE ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  PERFORM pg_temp.vrai(true, p_label);
END $$;
CREATE FUNCTION pg_temp.reglage(p_cle text, p_valeur jsonb) RETURNS void LANGUAGE sql AS
$$ UPDATE public.app_config SET value = p_valeur WHERE key = p_cle $$;
CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
$$ SELECT ('9c000000-0000-4000-8000-0000000000' || p)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.id(text) TO authenticated, anon, service_role;

-- ------------------------------------------------------------------
-- Fixtures : une direction, un tuteur, huit eleves, une classe
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), x || '@pu.invalid'
  FROM unnest(ARRAY['a1','d1','b1','e1','e2','e3','e4','e5','e6','e7','e8']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.id('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.id('a1'), 'PU-ADM-0001', 'admin', NULL, 'Direction', 'PU', 'active', 'female'),
 (pg_temp.id('b1'), 'PU-ENS-0001', 'teacher', NULL, 'Maryam', 'PU', 'provisional_active', 'female'),
 (pg_temp.id('d1'), 'PU-TUT-0001', 'guardian', pg_temp.id('f1'), 'Amina', 'F1', 'active', 'female');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x), 'PU-ELV-000' || right(x, 1), 'student', pg_temp.id('f1'), 'Eleve' || x, 'F1', 'active', 'female'
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7','e8']) AS x;
UPDATE public.households SET primary_guardian_id = pg_temp.id('d1') WHERE id = pg_temp.id('f1');
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.id(x), 'minor', 'standard' FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7','e8']) AS x;
SELECT private.fac_portefeuille(pg_temp.id('f1'), 'USD');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('9c000000-0000-4000-8000-000000000c01', pg_temp.id('b1'), 'enfant', 5, 'An-Nour PU', 1, 9, 'Europe/Paris');

-- Une facture du mois precedent, a 0 et financee, pour chaque eleve : la facture du mois n'est jamais
-- une « premiere » au prorata (meme methode que scenarios_fn115b), et un 0 n'est pas un paiement.
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                       lignes, total_mineur, statut, financee_le)
SELECT pg_temp.id(x), pg_temp.id('f1'), (private.fac_mois_courant() - interval '1 month')::date,
       (private.fac_politique_au(private.fac_mois_courant())).version, 'USD', 1, '[]'::jsonb, 0, 'financee', now()
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7','e8']) AS x;

-- ------------------------------------------------------------------
-- 0. Les reglages dorment
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'paiement.taxe_stripe_active') = 'false'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'paiement.premier_avant_cours') = 'false'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'paiement.delai_jours') = '3'::jsonb,
  '0 : taxe et premier paiement eteints, delai de 3 jours');
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.fac_etat_paiement(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.demander_paiement_maintenant(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.demander_paiement_maintenant(uuid)', 'EXECUTE'),
  '0 : droits des aides et de la fonction nouvelle');

-- ------------------------------------------------------------------
-- 1. P4 : la porte. e1 : facture a payer emise il y a 10 jours ; e2 : emise maintenant
-- ------------------------------------------------------------------
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                       lignes, total_mineur, emise_le)
VALUES (pg_temp.id('e1'), pg_temp.id('f1'), private.fac_mois_courant(),
        (private.fac_politique_au(private.fac_mois_courant())).version, 'USD', 1, '[]'::jsonb, 5500,
        clock_timestamp() - interval '10 days'),
       (pg_temp.id('e2'), pg_temp.id('f1'), private.fac_mois_courant(),
        (private.fac_politique_au(private.fac_mois_courant())).version, 'USD', 2, '[]'::jsonb, 5500,
        clock_timestamp());
SELECT pg_temp.vrai(private.fac_etat_paiement(pg_temp.id('e1')) = 'a_payer'
  AND private.acces_paye(pg_temp.id('e1')),
  '1 : reglage eteint, une premiere facture impayee ne ferme rien (comme avant)');
SELECT pg_temp.reglage('paiement.premier_avant_cours', 'true'::jsonb);
SELECT pg_temp.vrai(private.fac_etat_paiement(pg_temp.id('e1')) = 'en_retard'
  AND NOT private.acces_paye(pg_temp.id('e1')),
  '1 : reglage allume, jamais paye et facture ancienne : en retard, acces ferme');
SELECT pg_temp.vrai(private.fac_etat_paiement(pg_temp.id('e2')) = 'a_payer'
  AND private.acces_paye(pg_temp.id('e2')),
  '1 : facture de moins de 3 jours : a payer, acces ouvert (le delai)');
SELECT pg_temp.vrai(private.fac_etat_paiement(pg_temp.id('e3')) = 'a_payer'
  AND private.acces_paye(pg_temp.id('e3')),
  '1 : aucune facture demandee : a payer, rien n''est ferme');
-- Exoneration : acces offert a e1 -> exonere, acces ouvert.
SELECT set_config('test.fin', (private.fac_mois_courant() + interval '2 months')::date::text, false);
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin', NULL);
SELECT public.accorder_tarif_particulier(pg_temp.id('e1'), 'acces_offert', NULL, NULL,
  current_setting('test.fin')::date, 'Reporte jusqu''au mois suivant');
RESET ROLE;
SELECT pg_temp.vrai(private.fac_etat_paiement(pg_temp.id('e1')) = 'exonere' AND private.acces_paye(pg_temp.id('e1')),
  '1 : acces offert : exonere, acces ouvert');
-- Paye : un credit confirme.
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
SELECT w.id, 5500, 'USD', 'credit', pg_temp.id('e2'), now() FROM public.wallets w WHERE w.household_id = pg_temp.id('f1');
SELECT pg_temp.vrai(private.fac_deja_paye(pg_temp.id('e2')), '1 : un credit confirme = deja paye');
-- Une facture a 0 financee n'est pas un paiement.
SELECT pg_temp.vrai(NOT private.fac_deja_paye(pg_temp.id('e3')), '1 : une facture a 0 n''est pas un paiement');
SELECT pg_temp.reglage('paiement.premier_avant_cours', 'false'::jsonb);

-- ------------------------------------------------------------------
-- 2. P6 : la suspension de la nuit attend le delai pour une premiere facture
-- ------------------------------------------------------------------
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                       lignes, total_mineur, emise_le)
VALUES (pg_temp.id('e4'), pg_temp.id('f1'), private.fac_mois_courant(),
        (private.fac_politique_au(private.fac_mois_courant())).version, 'USD', 3, '[]'::jsonb, 5500, clock_timestamp()),
       (pg_temp.id('e5'), pg_temp.id('f1'), private.fac_mois_courant(),
        (private.fac_politique_au(private.fac_mois_courant())).version, 'USD', 4, '[]'::jsonb, 5500,
        clock_timestamp() - interval '10 days');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 ('9c000000-0000-4000-8000-000000000c01', pg_temp.id('e4'), now() - interval '20 days'),
 ('9c000000-0000-4000-8000-000000000c01', pg_temp.id('e5'), now() - interval '20 days');
SELECT private.fac_traiter_relances((private.fac_mois_courant() + interval '27 days')::date);
SELECT pg_temp.vrai(NOT private.fac_eleve_suspendu(pg_temp.id('e4')),
  '2 : une premiere facture emise depuis moins de 3 jours n''est pas suspendue la nuit');
SELECT pg_temp.vrai(private.fac_eleve_suspendu(pg_temp.id('e5')),
  '2 : une premiere facture de 10 jours est suspendue (regle d''avant, inchangee)');

-- ------------------------------------------------------------------
-- 3. P6 : l'entree en classe emet la premiere facture et previent la famille
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
VALUES ('9c000000-0000-4000-8000-000000000c01', pg_temp.id('e6'), now() - interval '20 days');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.factures_mensuelles
                                 WHERE profile_id = pg_temp.id('e6') AND mois = private.fac_mois_courant()),
  '3 : reglage eteint, l''entree en classe n''emet rien');
SELECT pg_temp.reglage('paiement.premier_avant_cours', 'true'::jsonb);
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
VALUES ('9c000000-0000-4000-8000-000000000c01', pg_temp.id('e7'), now() - interval '20 days');
SELECT pg_temp.vrai((SELECT total_mineur > 0 AND statut = 'a_financer' FROM public.factures_mensuelles
                      WHERE profile_id = pg_temp.id('e7') AND mois = private.fac_mois_courant()),
  '3 : reglage allume, l''entree en classe emet la premiere facture');
SELECT pg_temp.vrai((SELECT count(*) FROM public.notifications n
                      WHERE n.evenement = 'paiement_relance' AND n.destinataire = pg_temp.id('d1')
                        AND (n.params ->> 'premier')::boolean AND (n.params ->> 'delai_jours')::int = 3
                        AND (n.params ->> 'remboursement_jours')::int > 0) = 1,
  '3 : le tuteur recoit l''avis « premier paiement » avec le delai lu des reglages');
SELECT pg_temp.reglage('paiement.premier_avant_cours', 'false'::jsonb);

-- ------------------------------------------------------------------
-- 4. P5 : demander maintenant, et la fiche
-- ------------------------------------------------------------------
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
VALUES ('9c000000-0000-4000-8000-000000000c01', pg_temp.id('e8'), now() - interval '20 days');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT pg_temp.refus($q$SELECT public.demander_paiement_maintenant('9c000000-0000-4000-8000-0000000000e8')$q$,
  '42501', '4 : un tuteur ne demande aucun paiement');
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin', NULL);
SELECT pg_temp.refus($q$SELECT public.demander_paiement_maintenant('9c000000-0000-4000-8000-0000000000d1')$q$,
  '22023', '4 : seul un eleve se demande');
SELECT set_config('test.r1', public.demander_paiement_maintenant(pg_temp.id('e8'))::text, true);
SELECT pg_temp.vrai((current_setting('test.r1')::jsonb ->> 'facture_emise')::boolean
  AND (current_setting('test.r1')::jsonb ->> 'etat') = 'a_payer'
  AND (current_setting('test.r1')::jsonb ->> 'avertis')::int >= 1,
  '4 : la facture du mois est emise et la famille prevenue');
SELECT set_config('test.r2', public.demander_paiement_maintenant(pg_temp.id('e8'))::text, true);
SELECT pg_temp.vrai(NOT (current_setting('test.r2')::jsonb ->> 'facture_emise')::boolean,
  '4 : deuxieme demande : aucune seconde facture (idempotent)');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.factures_mensuelles
                      WHERE profile_id = pg_temp.id('e8') AND mois = private.fac_mois_courant()) = 1,
  '4 : une seule facture du mois');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('a1'), 'admin', NULL);
SELECT pg_temp.vrai((public.fiche_eleve_direction(pg_temp.id('e8')) -> 'paiement' ->> 'etat') = 'a_payer'
  AND (public.fiche_eleve_direction(pg_temp.id('e8')) -> 'paiement' -> 'facture' ->> 'statut') = 'a_financer'
  AND (public.fiche_eleve_direction(pg_temp.id('e1')) -> 'paiement' ->> 'etat') = 'exonere'
  AND (public.fiche_eleve_direction(pg_temp.id('e1')) -> 'paiement' -> 'remise' ->> 'nature') = 'acces_offert'
  AND (public.fiche_eleve_direction(pg_temp.id('e2')) -> 'paiement' ->> 'deja_paye')::boolean,
  '4 : la fiche dit l''etat, la facture, la remise et « deja paye »');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. P2 : la taxe s'ajoute au prix, jamais au credit
-- ------------------------------------------------------------------
-- PAIEMENT-FAMILLE-PRIX (23/11/2026) : aucune offre sans classe ; e3 entre en classe, et son paiement est
-- une offre du serveur (un mois d'avance), jamais un montant suppose.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES ('9c000000-0000-4000-8000-000000000c02', pg_temp.id('b1'), 'enfant', 5, 'Al-Fajr PU', 3, 15, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
VALUES ('9c000000-0000-4000-8000-000000000c02', pg_temp.id('e3'), now() - interval '20 days');
CREATE FUNCTION pg_temp.commande(p_cle text, p_pi text) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v_r jsonb; v_c uuid;
BEGIN
  PERFORM pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
  EXECUTE 'SET LOCAL ROLE authenticated';
  v_r := public.recharge_verifier_montants(jsonb_build_array(
    jsonb_build_object('profilId', pg_temp.id('e3'), 'devise', 'USD', 'mineur',
      (SELECT (o -> 'montant' ->> 'mineur')::bigint
         FROM jsonb_array_elements(public.recharge_beneficiaires()) x, jsonb_array_elements(x -> 'options') o
        WHERE x ->> 'id' = pg_temp.id('e3')::text AND (o ->> 'nbMois')::int = 1))));
  v_c := (public.recharge_payer((v_r ->> 'id')::uuid, ('9c000000-0000-4000-8000-000000' || p_cle)::uuid)
          ->> 'commandeId')::uuid;
  EXECUTE 'RESET ROLE';
  EXECUTE 'SET LOCAL ROLE service_role';
  PERFORM public.recharge_attacher_session(v_c, pg_temp.id('d1'), 'cs_' || p_pi,
    'https://checkout.stripe.com/c/cs_' || p_pi, 'test');
  EXECUTE 'RESET ROLE';
  RETURN v_c;
END $$;
CREATE FUNCTION pg_temp.evt(p_c uuid, p_pi text, p_id text, p_montant bigint) RETURNS text LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  v := public.recharge_evenement_stripe(p_id, 'checkout.session.completed', 'test', p_c,
         'cs_' || p_pi, p_pi, 'paid', p_montant, 'usd');
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
SELECT set_config('test.c1', pg_temp.commande('00a001', 'pi_pu_1')::text, true);
SELECT set_config('test.t', (SELECT total_mineur::text FROM public.commandes_recharge
                              WHERE id = current_setting('test.c1')::uuid), true);
SELECT pg_temp.vrai(current_setting('test.t')::bigint > 0, '5 : la commande a un total');
SELECT pg_temp.vrai(pg_temp.evt(current_setting('test.c1')::uuid, 'pi_pu_1', 'evt_pu_1',
  current_setting('test.t')::bigint + 500) = 'montant_incoherent',
  '5 : taxe eteinte, un total superieur au prix est refuse (comme avant)');
SELECT set_config('test.c2', pg_temp.commande('00a002', 'pi_pu_2')::text, true);
SELECT pg_temp.reglage('paiement.taxe_stripe_active', 'true'::jsonb);
SELECT pg_temp.vrai(pg_temp.evt(current_setting('test.c2')::uuid, 'pi_pu_2', 'evt_pu_2',
  current_setting('test.t')::bigint - 1) = 'montant_incoherent',
  '5 : taxe allumee, un total inferieur au prix reste refuse');
SELECT set_config('test.c3', pg_temp.commande('00a003', 'pi_pu_3')::text, true);
SELECT pg_temp.vrai(pg_temp.evt(current_setting('test.c3')::uuid, 'pi_pu_3', 'evt_pu_3',
  current_setting('test.t')::bigint * 14 / 10) = 'montant_incoherent',
  '5 : taxe allumee, une taxe de 40 % est refusee (plafond de 30 %)');
SELECT set_config('test.c4', pg_temp.commande('00a004', 'pi_pu_4')::text, true);
SELECT pg_temp.vrai(pg_temp.evt(current_setting('test.c4')::uuid, 'pi_pu_4', 'evt_pu_4',
  current_setting('test.t')::bigint * 12 / 10) = 'credite',
  '5 : taxe allumee, prix plus 20 % de taxe : credite');
SELECT pg_temp.vrai((SELECT sum(amount_minor) FROM public.wallet_entries
                      WHERE reference_type = 'credit' AND reference_id = current_setting('test.c4')::uuid)
    = current_setting('test.t')::bigint,
  '5 : le credit est le prix hors taxes, pas le total paye');
SELECT pg_temp.vrai(pg_temp.evt(current_setting('test.c4')::uuid, 'pi_pu_4', 'evt_pu_4', 1) = 'doublon',
  '5 : le meme evenement ne credite pas deux fois');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 24,
  'au moins 24 controles ont passe');
SELECT 'PAIEMENT-UNIFIE : scenarios verts' AS resultat;
ROLLBACK;
