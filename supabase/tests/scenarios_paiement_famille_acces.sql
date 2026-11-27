-- PAIEMENT-FAMILLE-ACCES (23/11/2026) : D6 « un compte = une personne » et D7 « les frais d'une contestation
-- perdue vont a la famille ». Migration 20261203100000. Scenarios S6 a S9 de
-- docs/current/PAIEMENT/FAMILLE-SCENARIOS-2026-11-23.md. A rejouer sur une base NEUVE (stub + toutes les
-- migrations) : fixtures inserees puis annulees.
--
--   F1 : G1 tutrice ET eleve (compte « guardian »), enfant C1, meme Classe c1. G1 impayee, C1 payee   (S6, S8)
--   F3 : G3 tutrice ET eleve payee, enfant C3 impaye, meme Classe c3                                  (S7)
--   F4 : G4 tutrice seule, enfants C4 (impaye) et C5 (paye) dans la Classe c4                          (accompagner)
--   F2 : G2 tutrice, enfants K1 et K2 payes (une commande), K3 avec un mois du ; contestation perdue    (S9)
--   Enseignant et direction : acces inchange.
\set ON_ERROR_STOP 1
BEGIN;
SET LOCAL client_min_messages = warning;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('fa000000-0000-4000-8000-0000000' || lpad(p, 5, '0'))::uuid $$;

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
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'PAIEMENT-FAMILLE-ACCES ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  PERFORM pg_temp.vrai(true, p_label);
END $$;

CREATE FUNCTION pg_temp.nb(p_sql text) RETURNS integer LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  EXECUTE 'SELECT count(*)::integer FROM (' || p_sql || ') x' INTO v;
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.jeton(p_session uuid, p_profil uuid) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT public.autoriser_jeton_video(p_session, p_profil, 'wss://cloud.invalid', 'wss://self.invalid') $$;

CREATE FUNCTION pg_temp.suspendre(p_profil uuid, p_foyer uuid) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_f uuid;
BEGIN
  SELECT id INTO v_f FROM public.factures_mensuelles WHERE profile_id = p_profil AND mois = private.fac_mois_courant();
  IF v_f IS NULL THEN
    INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                           lignes, total_mineur)
    VALUES (p_profil, p_foyer, private.fac_mois_courant(), 'v2.0.0', 'USD', 1, '[]'::jsonb, 5500)
    RETURNING id INTO v_f;
  END IF;
  INSERT INTO public.acces_suspensions_paiement(profile_id, facture_id, jour)
  VALUES (p_profil, v_f, private.fac_aujourdhui());
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.id(text), pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.nb(text), pg_temp.jeton(uuid, uuid) TO authenticated, anon, service_role;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'fa-' || x || '@test.invalid'
  FROM unnest(ARRAY['1','2','3','4']) AS x;
-- 1 direction, 2 3 4 enseignants, 11 G1, 12 C1, 31 G3, 32 C3, 41 G4, 42 C4, 43 C5, 21 G2, 22 K1, 23 K2, 24 K3
INSERT INTO public.households(id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['101','102','103','104']) AS x;
-- F1 = 101, F2 = 102, F3 = 103, F4 = 104
INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'fa-' || x || '@test.invalid'
  FROM unnest(ARRAY['11','12','21','22','23','24','25','31','32','41','42','43','44']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'FA', (CASE WHEN x.role = 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('1','FA-ADM-0001','admin',NULL,'Direction','female'),
   ('2','FA-ENS-0001','teacher',NULL,'Maryam','female'),
   ('3','FA-ENS-0002','teacher',NULL,'Hajar','female'),
   ('4','FA-ENS-0003','teacher',NULL,'Salma','female'),
   ('11','FA-TUT-0011','guardian','101','Dyna','female'),
   ('12','FA-ELV-0012','student','101','Hallowx','female'),
   ('21','FA-TUT-0021','guardian','102','Amina','female'),
   ('22','FA-ELV-0022','student','102','Yasmine','female'),
   ('23','FA-ELV-0023','student','102','Bilal','male'),
   ('24','FA-ELV-0024','student','102','Ines','female'),
   ('31','FA-TUT-0031','guardian','103','Karim','male'),
   ('32','FA-ELV-0032','student','103','Adam','male'),
   ('41','FA-TUT-0041','guardian','104','Leila','female'),
   ('42','FA-ELV-0042','student','104','Sara','female'),
   ('43','FA-ELV-0043','student','104','Nour','female')) AS x(id, mat, role, foyer, prenom, genre);
UPDATE public.households h SET primary_guardian_id = pg_temp.id(x.g)
  FROM (VALUES ('101','11'),('102','21'),('103','31'),('104','41')) AS x(f, g) WHERE h.id = pg_temp.id(x.f);
-- Tuteurs eleves : G1 et G3 ont aussi un profil d'eleve (adulte).
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.id(x), (CASE WHEN x IN ('11','31') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['11','12','22','23','24','31','32','42','43']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.id('901'), pg_temp.id('2'), 'enfant', 5, 'Classe F1', 1, 9, 'Europe/Paris'),
 (pg_temp.id('903'), pg_temp.id('3'), 'enfant', 5, 'Classe F3', 2, 9, 'Europe/Paris'),
 (pg_temp.id('904'), pg_temp.id('4'), 'enfant', 5, 'Classe F4', 3, 9, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT pg_temp.id(x.g), pg_temp.id(x.e), now() - interval '20 days'
  FROM (VALUES ('901','11'),('901','12'),('903','31'),('903','32'),('904','42'),('904','43')) AS x(g, e);
DELETE FROM public.sessions WHERE groupe_id IN (pg_temp.id('901'), pg_temp.id('903'), pg_temp.id('904'));
INSERT INTO public.sessions(id, teacher_id, groupe_id, started_at, ended_at, status, session_type) VALUES
 (pg_temp.id('501'), pg_temp.id('2'), pg_temp.id('901'), now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard'),
 (pg_temp.id('503'), pg_temp.id('3'), pg_temp.id('903'), now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard'),
 (pg_temp.id('504'), pg_temp.id('4'), pg_temp.id('904'), now() - interval '10 minutes', now() + interval '50 minutes', 'planned', 'standard');
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.id(x.s), pg_temp.id(x.p), 'student'
  FROM (VALUES ('501','11'),('501','12'),('503','31'),('503','32'),('504','42'),('504','43')) AS x(s, p)
ON CONFLICT (session_id, profile_id) DO NOTHING;
SELECT private.fac_portefeuille(h.id, 'USD') FROM public.households h WHERE h.id::text LIKE 'fa000000-%';

-- S6 : G1 (tutrice-eleve) impayee ; C1 paye. S7 : G3 payee ; C3 impaye. F4 : C4 impaye, C5 paye.
SELECT pg_temp.suspendre(pg_temp.id('11'), pg_temp.id('101'));
SELECT pg_temp.suspendre(pg_temp.id('32'), pg_temp.id('103'));
SELECT pg_temp.suspendre(pg_temp.id('42'), pg_temp.id('104'));

SELECT pg_temp.vrai(NOT private.acces_paye(pg_temp.id('11')) AND private.acces_paye(pg_temp.id('12'))
  AND private.acces_paye(pg_temp.id('31')) AND NOT private.acces_paye(pg_temp.id('32'))
  AND NOT private.acces_paye(pg_temp.id('42')) AND private.acces_paye(pg_temp.id('43')),
  '0 : depart : G1 impayee, C1 payee ; G3 payee, C3 impaye ; C4 impaye, C5 paye');

-- ------------------------------------------------------------------
-- S6 : tutrice-eleve impayee, enfant paye, meme Classe : la tutrice est bloquee, l'enfant entre
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT private.acces_paye_seance_pour(pg_temp.id('501'), pg_temp.id('11'))
  AND private.acces_paye_seance_pour(pg_temp.id('501'), pg_temp.id('12'))
  AND NOT private.acces_paye_groupe_pour(pg_temp.id('901'), pg_temp.id('11'))
  AND private.acces_paye_groupe_pour(pg_temp.id('901'), pg_temp.id('12')),
  'S6 : la porte juge G1 sur SA place : refusee ; C1 passe');
SET LOCAL ROLE service_role;
SELECT pg_temp.refus($q$SELECT pg_temp.jeton(pg_temp.id('501'), pg_temp.id('11'))$q$, '42501',
  'S6 : pas de jeton video pour G1 (place d''eleve impayee), meme si son enfant a paye');
SELECT pg_temp.vrai((pg_temp.jeton(pg_temp.id('501'), pg_temp.id('12')) ->> 'role') = 'student'
  AND (pg_temp.jeton(pg_temp.id('501'), pg_temp.id('12')) ->> 'identity') = pg_temp.id('12')::text,
  'S6 : C1 recoit son jeton d''eleve ; l''identite de la salle est l''identifiant de SON profil');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('11'), 'guardian', pg_temp.id('101'));
SELECT pg_temp.refus($q$SELECT public.seance_a_rejoindre(pg_temp.id('901'))$q$, '42501',
  'S6 : G1 n''ouvre pas la seance de la Classe grace a son enfant');
SELECT pg_temp.vrai((public.entrer_observation(pg_temp.id('501'), 'guardian_observer') ->> 'autorise')::boolean IS FALSE,
  'S6 : G1 ne passe pas par l''observation pour suivre sa propre classe');
RESET ROLE;
-- Payee, elle entre comme ELEVE ; ni l'observation ne remplace sa place.
DELETE FROM public.acces_suspensions_paiement WHERE profile_id = pg_temp.id('11');
SELECT pg_temp.vrai(private.acces_paye_seance_pour(pg_temp.id('501'), pg_temp.id('11')),
  'S6 : G1 a jour : elle entre sur son propre paiement');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('11'), 'guardian', pg_temp.id('101'));
SELECT pg_temp.vrai(public.entrer_observation(pg_temp.id('501'), 'guardian_observer') ->> 'motif_refus' = 'place_eleve',
  'S6 : G1 a jour a sa place d''eleve : elle n''est pas convertie en observatrice');
RESET ROLE;
SELECT pg_temp.vrai((SELECT role = 'student' FROM public.session_participants
                      WHERE session_id = pg_temp.id('501') AND profile_id = pg_temp.id('11')),
  'S6 : sa ligne de participante reste « student »');
SELECT pg_temp.suspendre(pg_temp.id('11'), pg_temp.id('101'));

-- ------------------------------------------------------------------
-- S7 : tutrice-eleve payee, enfant impaye qui se connecte sur le compte de la tutrice
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.acces_paye_seance_pour(pg_temp.id('503'), pg_temp.id('31'))
  AND NOT private.acces_paye_seance_pour(pg_temp.id('503'), pg_temp.id('32')),
  'S7 : la porte : G3 passe sur SON paiement, C3 ne passe pas');
SET LOCAL ROLE service_role;
SELECT pg_temp.refus($q$SELECT public.autoriser_jeton_video_eleve(pg_temp.id('503'), pg_temp.id('31'), pg_temp.id('32'),
  'wss://cloud.invalid', 'wss://self.invalid')$q$, '42501',
  'S7 : C3 impaye ne rejoint pas depuis l''appareil de G3, meme si G3 a paye');
SELECT pg_temp.vrai((pg_temp.jeton(pg_temp.id('503'), pg_temp.id('31')) ->> 'role') = 'student',
  'S7 : G3 entre en son nom (eleve, son paiement)');
RESET ROLE;
-- Un enfant qui a paye entre toujours depuis l'appareil du tuteur, sous SON identite.
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai((public.autoriser_jeton_video_eleve(pg_temp.id('501'), pg_temp.id('11'), pg_temp.id('12'),
  'wss://cloud.invalid', 'wss://self.invalid') ->> 'identity') = pg_temp.id('12')::text,
  'S7 : C1 (paye) entre depuis l''appareil de G1 sous l''identite de C1 : une seule place par profil');
RESET ROLE;

-- ------------------------------------------------------------------
-- Accompagner : un tuteur seul observe seulement un enfant dont l'acces est paye
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.acces_paye_seance_pour(pg_temp.id('504'), pg_temp.id('41')),
  'accompagner : G4 (aucune place d''eleve) accompagne C5, qui a paye');
SELECT pg_temp.suspendre(pg_temp.id('43'), pg_temp.id('104'));
SELECT pg_temp.vrai(NOT private.acces_paye_seance_pour(pg_temp.id('504'), pg_temp.id('41'))
  AND NOT private.acces_paye_groupe_pour(pg_temp.id('904'), pg_temp.id('41')),
  'accompagner : aucun enfant paye, G4 n''accompagne personne');
DELETE FROM public.acces_suspensions_paiement WHERE profile_id = pg_temp.id('43');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('41'), 'guardian', pg_temp.id('104'));
SELECT pg_temp.vrai((public.entrer_observation(pg_temp.id('504'), 'guardian_observer') -> 'visite' ->> 'enfant_profile_id')
                    = pg_temp.id('43')::text,
  'accompagner : la visite nomme l''enfant qui a paye (C5), pas C4');
RESET ROLE;
-- Jamais compte comme eleve : le role est observateur, hors des presents payes.
SELECT pg_temp.vrai((SELECT role = 'guardian_observer' FROM public.session_participants
                      WHERE session_id = pg_temp.id('504') AND profile_id = pg_temp.id('41'))
  AND NOT EXISTS (SELECT 1 FROM public.session_participants sp
                   WHERE sp.session_id = pg_temp.id('504') AND sp.role = 'student' AND sp.profile_id = pg_temp.id('41')),
  'accompagner : G4 est observatrice, jamais « student » (donc jamais dans les presents payes)');
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai((pg_temp.jeton(pg_temp.id('504'), pg_temp.id('41')) ->> 'role') = 'guardian_observer'
  AND ((pg_temp.jeton(pg_temp.id('504'), pg_temp.id('41')) -> 'capabilities' ->> 'can_publish')::boolean IS FALSE),
  'accompagner : jeton d''observatrice, sans droit de publier');
RESET ROLE;

-- ------------------------------------------------------------------
-- S8 : tutrice-eleve suspendue : elle garde l'application, le paiement, les messages a la direction
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('11'), 'guardian', pg_temp.id('101'));
SELECT pg_temp.vrai(jsonb_typeof(public.recharge_beneficiaires()) = 'array',
  'S8 : G1 suspendue ouvre toujours la page de paiement');
SELECT pg_temp.vrai((public.ma_dette_famille() ->> 'ouverte')::boolean IS FALSE,
  'S8 : G1 suspendue lit toujours son espace famille');
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM private.com_paires('classe', pg_temp.id('901')) q
                             WHERE q.a_id = pg_temp.id('101') AND q.b_nature = 'equipe'),
  'S8 : le fil du foyer avec la direction reste ouvert');

-- ------------------------------------------------------------------
-- Enseignant et direction : acces inchange
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.id('2'), 'teacher', NULL);
SELECT pg_temp.vrai(private.acces_paye_seance(pg_temp.id('501')) AND private.acces_paye_groupe(pg_temp.id('901'))
  AND private.acces_paye_appelant(), 'enseignant : les portes de l''appelant restent ouvertes');
SELECT pg_temp.qui(pg_temp.id('1'), 'admin', NULL);
SELECT pg_temp.vrai(private.acces_paye_seance(pg_temp.id('501')) AND private.acces_paye_groupe(pg_temp.id('901'))
  AND private.acces_paye_appelant(), 'direction : les portes de l''appelant restent ouvertes');
SET LOCAL ROLE service_role;
SELECT pg_temp.vrai((pg_temp.jeton(pg_temp.id('501'), pg_temp.id('2')) ->> 'role') = 'teacher'
  AND (pg_temp.jeton(pg_temp.id('501'), pg_temp.id('2')) ->> 'identity') = pg_temp.id('2')::text,
  'enseignant : le jeton de l''enseignant titulaire est inchange (role teacher)');
RESET ROLE;

-- ------------------------------------------------------------------
-- S9 : contestation perdue sur le paiement de la famille F2
--   K1 (rang 1) et K2 payes par une commande ; K3 a un mois du. Le rang 1 est « presque a zero » apres la
--   contestation : avant D7 les 15 USD de frais le rendaient negatif, rouvraient sa facture et le suspendaient.
-- ------------------------------------------------------------------
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES (pg_temp.id('902'), pg_temp.id('2'), 'enfant', 5, 'Classe F2', 4, 9, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT pg_temp.id('902'), pg_temp.id(x), now() - interval '20 days' FROM unnest(ARRAY['22','23','24']) AS x;
INSERT INTO public.recharges_recapitulatifs(id, titulaire, household_id, devise, total_mineur, expire_le)
VALUES (pg_temp.id('801'), pg_temp.id('21'), pg_temp.id('102'), 'USD', 28000, now() + interval '1 hour');
INSERT INTO public.recharges_recap_lignes(recapitulatif_id, rang, profile_id, montant_mineur) VALUES
 (pg_temp.id('801'), 1, pg_temp.id('22'), 8000), (pg_temp.id('801'), 2, pg_temp.id('23'), 20000);
INSERT INTO public.commandes_recharge(id, reference, recapitulatif_id, titulaire, household_id, cle, devise,
  total_mineur, etat, session_prestataire, paiement_prestataire, environnement, confirme_le, termine_le)
VALUES (pg_temp.id('802'), 'RWY-FA000001', pg_temp.id('801'), pg_temp.id('21'), pg_temp.id('102'), pg_temp.id('803'),
  'USD', 28000, 'completed', 'cs_fa_1', 'pi_fa_1', 'test', now(), now());
INSERT INTO public.wallet_entries(wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id,
  confirme_par_prestataire_le)
SELECT w.id, x.m, 'USD', 'credit', pg_temp.id('802'), pg_temp.id(x.e), now()
  FROM public.wallets w, (VALUES ('22', 8000), ('23', 20000)) AS x(e, m)
 WHERE w.household_id = pg_temp.id('102');
INSERT INTO public.commandes_recharge_allocations(commande_id, rang, profile_id, montant_mineur, entry_id)
SELECT pg_temp.id('802'), x.r, pg_temp.id(x.e), x.m,
       (SELECT we.id FROM public.wallet_entries we WHERE we.reference_id = pg_temp.id('802')
         AND we.beneficiaire_id = pg_temp.id(x.e) AND we.reference_type = 'credit')
  FROM (VALUES (1, '22', 8000), (2, '23', 20000)) AS x(r, e, m);
-- Les mois de K1 et K2, finances par le credit (comme le fait le passage quotidien).
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                       lignes, total_mineur)
SELECT pg_temp.id(x.e), pg_temp.id('102'), private.fac_mois_courant(), 'v2.0.0', 'USD', 1, '[]'::jsonb, x.m
  FROM (VALUES ('22', 5500), ('23', 5500), ('24', 3000)) AS x(e, m);
SELECT private.fac_financer_profil(pg_temp.id('22')), private.fac_financer_profil(pg_temp.id('23'));
CREATE FUNCTION pg_temp.solde(p text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT private.fac_solde_profil(pg_temp.id(p)) $$;
CREATE FUNCTION pg_temp.suspendu(p text) RETURNS boolean LANGUAGE sql AS
  $$ SELECT EXISTS (SELECT 1 FROM public.acces_suspensions_paiement
                     WHERE profile_id = pg_temp.id(p) AND retabli_le IS NULL) $$;
CREATE FUNCTION pg_temp.evt(p_id text, p_type text, p_montant bigint, p_litige text, p_statut text, p_frais bigint DEFAULT NULL)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  v := public.remboursement_evenement_stripe(p_id, p_type, 'test', 'pi_fa_1', p_montant, 'usd',
         p_litige, p_statut, p_frais, NULL);
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.solde(text), pg_temp.suspendu(text), pg_temp.evt(text, text, bigint, text, text, bigint)
  TO authenticated, service_role;

SELECT pg_temp.vrai(pg_temp.solde('22') = 2500 AND pg_temp.solde('23') = 14500 AND NOT pg_temp.suspendu('22')
  AND NOT pg_temp.suspendu('23') AND private.acces_paye(pg_temp.id('22')) AND private.acces_paye(pg_temp.id('23')),
  'S9 : depart : K1 et K2 payes, soldes 25,00 et 145,00 USD');
SELECT pg_temp.vrai(pg_temp.evt('evt_fa_1', 'charge.dispute.created', 5500, 'du_fa_1', 'needs_response') = 'litige_ouvert',
  'S9 : contestation ouverte (55 USD repris au prorata des credits)');
SELECT set_config('test.k1', pg_temp.solde('22')::text, true), set_config('test.k2', pg_temp.solde('23')::text, true);
SELECT pg_temp.vrai(pg_temp.solde('22') BETWEEN 1 AND 1499 AND pg_temp.solde('23') > 0
  AND NOT pg_temp.suspendu('22') AND NOT pg_temp.suspendu('23'),
  'S9 : apres l''ouverture, K1 est proche de zero (moins de 15 USD) mais positif, personne n''est suspendu');
SELECT pg_temp.vrai(pg_temp.evt('evt_fa_2', 'charge.dispute.closed', 5500, 'du_fa_1', 'lost', 1500) = 'litige_perdu',
  'S9 : contestation perdue, 15 USD de frais');
SELECT pg_temp.vrai(pg_temp.solde('22') = current_setting('test.k1')::bigint
  AND pg_temp.solde('23') = current_setting('test.k2')::bigint,
  'S9 : les soldes des enfants ne bougent pas : les frais ne tombent sur aucun enfant');
SELECT pg_temp.vrai(NOT pg_temp.suspendu('22') AND NOT pg_temp.suspendu('23')
  AND (SELECT count(*) = 2 FROM public.factures_mensuelles f
        WHERE f.profile_id IN (pg_temp.id('22'), pg_temp.id('23')) AND f.statut = 'financee')
  AND private.acces_paye(pg_temp.id('22')) AND private.acces_paye(pg_temp.id('23')),
  'S9 : les cours deja payes de K1 et K2 restent intacts (factures financees, aucune suspension)');
SELECT pg_temp.vrai((SELECT count(*) = 1 AND sum(montant_mineur) = 1500 AND min(motif) = 'frais_contestation_perdue'
                       FROM public.dettes_famille WHERE household_id = pg_temp.id('102') AND reglee_le IS NULL)
  AND private.dette_famille_ouverte(pg_temp.id('102')) = 1500,
  'S9 : les 15 USD sont une dette de la famille F2, avec son motif');
SELECT pg_temp.vrai(pg_temp.evt('evt_fa_2', 'charge.dispute.closed', 5500, 'du_fa_1', 'lost', 1500) = 'doublon'
  AND private.dette_famille_ouverte(pg_temp.id('102')) = 1500,
  'S9 : l''evenement rejoue ne double pas la dette');

-- La famille voit sa dette et la raison ; une autre famille n'y voit rien.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('21'), 'guardian', pg_temp.id('102'));
SELECT pg_temp.vrai((public.ma_dette_famille() ->> 'ouverte')::boolean
  AND (public.ma_dette_famille() ->> 'total_mineur')::bigint = 1500
  AND (public.ma_dette_famille() -> 'lignes' -> 0 ->> 'motif') = 'frais_contestation_perdue'
  AND pg_temp.nb('SELECT 1 FROM public.dettes_famille') = 1,
  'S9 : G2 lit sa dette, 15 USD, motif « frais_contestation_perdue »');
SELECT pg_temp.qui(pg_temp.id('41'), 'guardian', pg_temp.id('104'));
SELECT pg_temp.vrai(pg_temp.nb('SELECT 1 FROM public.dettes_famille') = 0
  AND (public.ma_dette_famille() ->> 'ouverte')::boolean IS FALSE,
  'S9 : une autre famille ne lit pas cette dette');
SELECT pg_temp.refus($q$SELECT public.regler_dette_famille((SELECT id FROM public.dettes_famille LIMIT 1), 'pas ma dette')$q$,
  '42501', 'S9 : un tuteur ne regle pas une dette');
SELECT pg_temp.refus($q$INSERT INTO public.dettes_famille(household_id, montant_mineur, devise, motif)
  VALUES (pg_temp.id('104'), 100, 'USD', 'frais_contestation_perdue')$q$, '42501',
  'S9 : aucune ecriture directe dans la table des dettes');
RESET ROLE;

-- Les nouveaux achats de F2 sont bloques ; payer ce qui est du ne l'est pas.
SELECT pg_temp.refus($q$INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
  VALUES (pg_temp.id('25'), 'FA-ELV-0025', 'student', pg_temp.id('102'), 'Zaid', 'FA', 'active', 'male')$q$, 'P0001',
  'S9 : pas de nouvel enfant dans la famille F2 tant que la dette reste');
SELECT pg_temp.refus($q$INSERT INTO public.demandes_horaires_famille(eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source)
  VALUES (pg_temp.id('24'), 'enfant', 'fr', 'Europe/Paris', ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'creneau_libre')$q$, 'P0001',
  'S9 : pas de nouvelle demande de classe pour la famille F2');
INSERT INTO public.recharges_recapitulatifs(id, titulaire, household_id, devise, total_mineur, expire_le)
VALUES (pg_temp.id('811'), pg_temp.id('21'), pg_temp.id('102'), 'USD', 3001, now() + interval '1 hour'),
       (pg_temp.id('812'), pg_temp.id('21'), pg_temp.id('102'), 'USD', 3000, now() + interval '1 hour');
SELECT pg_temp.vrai(private.fac_reste_a_payer(pg_temp.id('24')) = 3000, 'S9 : K3 doit 30 USD');
SELECT pg_temp.refus($q$INSERT INTO public.recharges_recap_lignes(recapitulatif_id, rang, profile_id, montant_mineur)
  VALUES (pg_temp.id('811'), 1, pg_temp.id('24'), 3001)$q$, 'P0001',
  'S9 : pas de prepaiement (au-dela du du) pour la famille F2 tant que la dette reste');
INSERT INTO public.recharges_recap_lignes(recapitulatif_id, rang, profile_id, montant_mineur)
VALUES (pg_temp.id('812'), 1, pg_temp.id('24'), 3000);
SELECT pg_temp.vrai(true, 'S9 : payer exactement ce qui est du reste permis (le mois de K3)');
-- Une autre famille n'est pas touchee.
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('44'), 'FA-ELV-0044', 'student', pg_temp.id('104'), 'Rim', 'FA', 'active', 'female');
SELECT pg_temp.vrai(true, 'S9 : une autre famille ajoute un enfant sans obstacle');

-- La direction reconnait le reglement : tout se rouvre, la trace reste.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('1'), 'admin', NULL);
SELECT pg_temp.refus($q$SELECT public.regler_dette_famille((SELECT id FROM public.dettes_famille LIMIT 1), 'x')$q$, '22023',
  'S9 : le motif est obligatoire');
SELECT public.regler_dette_famille((SELECT id FROM public.dettes_famille WHERE household_id = pg_temp.id('102')),
  'Virement recu le 24/11');
RESET ROLE;
SELECT pg_temp.vrai(private.dette_famille_ouverte(pg_temp.id('102')) = 0
  AND (SELECT reglee_par = pg_temp.id('1') AND regle_motif = 'Virement recu le 24/11' FROM public.dettes_famille
        WHERE household_id = pg_temp.id('102')),
  'S9 : dette reglee par la direction, motif et auteur gardes');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('25'), 'FA-ELV-0025', 'student', pg_temp.id('102'), 'Zaid', 'FA', 'active', 'male');
SELECT pg_temp.vrai(true, 'S9 : dette reglee, la famille F2 peut de nouveau ajouter un enfant');

-- ------------------------------------------------------------------
-- Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.ma_dette_famille()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.regler_dette_famille(uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.ma_dette_famille()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.dette_famille_ouverte(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.acces_paye_seance_pour(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.acces_paye_groupe_pour(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.acces_paye_appelant()', 'EXECUTE')
  AND NOT has_table_privilege('anon', 'public.dettes_famille', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.dettes_famille', 'INSERT')
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.dettes_famille'::regclass),
  'droits : RLS active, aucune ecriture client, fonctions privees fermees, anon exclu');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM unnest(ARRAY['public.entrer_observation(uuid,text)'::regprocedure,
                               'public.ma_dette_famille()'::regprocedure,
                               'public.regler_dette_famille(uuid,text)'::regprocedure]) f
     WHERE coalesce(obj_description(f, 'pg_proc'), '')
           NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || ';%'),
  'droits : l''empreinte F86 de chaque fonction retouchee ou nouvelle est celle de la fonction installee');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 40,
  'au moins 40 controles ont passe (41 avec celui-ci)');
SELECT 'PAIEMENT-FAMILLE-ACCES : scenarios verts' AS resultat;
ROLLBACK;
