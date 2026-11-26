-- PAIEMENT-FAMILLE-PRIX (23/11/2026) : le prix d'une famille a plusieurs profils, corrige et explique.
-- Migration 20261203000000. Decisions : docs/current/PAIEMENT/FAMILLE-SCENARIOS-2026-11-23.md §6.
--   1. D1, prorata : le denominateur est l'horaire de la classe sur le mois ENTIER, pas les seances creees ;
--   2. un profil offert (acces offert) ne prend aucun rang ; les profils qui paient gardent leur rang ;
--   3. politique v2.2.0 : 8 % au 2e, 15 % au 3e et suivants (3 enfants = 55 + 50,60 + 46,75 = 152,35 USD) ;
--   4. plafond de cumul 25 % (essaye sur une version de test, 17 % + 10 % = 27 % ramene a 25 %) ;
--   5. dette + N mois : la dette d'abord et a part, N de 1 a 12, 1 et 2 sans remise de prepaiement ;
--   6. aucune offre sans classe ni creneau choisi ; avant le premier mois reel : un mois seulement ;
--   7. la verification refuse un montant forge, un mauvais nombre de mois, un profil en double ;
--   8. remboursement d'un engagement de N mois : les mois commences au prix normal, le reste rendu, la dette
--      jamais rendue ;
--   9. le contrat d'explication : lignes, remises non appliquees avec leur code, prorata, mois couverts.
-- Les mois sont relatifs a l'horloge de la base : jamais une date en dur (sauf la version de test, 2099).
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

-- Les remboursements relisent la politique du jour du paiement : v2.0.0 (55 / 65 USD) couvre les 40 derniers
-- jours, v1.0.0 (50 / 60 USD) est reculee avant elle.
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '4 months')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '3 months')::date
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
    RAISE EXCEPTION 'PAIEMENT-FAMILLE ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'PAIEMENT-FAMILLE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'PAIEMENT-FAMILLE ROUGE : % (%, % au lieu de %)', p_label, SQLSTATE, SQLERRM, p_code;
    END IF;
  END;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('fa000000-0000-4000-8000-0000000000' || p)::uuid $$;
CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql SECURITY DEFINER AS $$ SELECT private.fac_mois_courant() $$;
CREATE FUNCTION pg_temp.suivant() RETURNS date LANGUAGE sql SECURITY DEFINER AS
  $$ SELECT (private.fac_mois_courant() + interval '1 month')::date $$;
CREATE FUNCTION pg_temp.prix(p_profil text, p_nb int) RETURNS bigint LANGUAGE sql AS
  $$ SELECT (private.rch_prix_avance(pg_temp.id(p_profil), pg_temp.suivant(), p_nb) ->> 'totalMineur')::bigint $$;
CREATE FUNCTION pg_temp.fac(p_profil text) RETURNS public.factures_mensuelles LANGUAGE sql AS
  $$ SELECT f.* FROM public.factures_mensuelles f
      WHERE f.profile_id = pg_temp.id(p_profil) AND f.mois = pg_temp.mois() AND f.statut <> 'annulee' $$;
CREATE FUNCTION pg_temp.solde(p_profil text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT private.fac_solde_profil(pg_temp.id(p_profil)) $$;
-- Le profil tel que le titulaire connecte le lit, et l'une de ses offres.
CREATE FUNCTION pg_temp.profil(p_profil text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x FROM jsonb_array_elements(public.recharge_beneficiaires()) x
      WHERE x ->> 'id' = pg_temp.id(p_profil)::text $$;
CREATE FUNCTION pg_temp.offre(p_profil text, p_nb int) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT o FROM jsonb_array_elements(pg_temp.profil(p_profil) -> 'options') o WHERE (o ->> 'nbMois')::int = p_nb $$;
CREATE FUNCTION pg_temp.montant(p_profil text, p_nb int) RETURNS bigint LANGUAGE sql AS
  $$ SELECT (pg_temp.offre(p_profil, p_nb) -> 'montant' ->> 'mineur')::bigint $$;
CREATE FUNCTION pg_temp.ligne(p_offre jsonb, p_code text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT l FROM jsonb_array_elements(p_offre -> 'lignes') l WHERE l ->> 'code' = p_code $$;
CREATE FUNCTION pg_temp.non(p_offre jsonb, p_code text) RETURNS boolean LANGUAGE sql AS
  $$ SELECT EXISTS (SELECT 1 FROM jsonb_array_elements(p_offre -> 'nonAppliquees') l WHERE l ->> 'code' = p_code) $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text),
  pg_temp.id(text), pg_temp.mois(), pg_temp.suivant(), pg_temp.profil(text), pg_temp.offre(text, int),
  pg_temp.montant(text, int), pg_temp.ligne(jsonb, text), pg_temp.non(jsonb, text), pg_temp.solde(text)
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
--   F1 : trois enfants k11 k12 k13 (classe G1)      F2 : k21, k22 (acces offert), k23 (classe G2)
--   F3 : k31 entre en cours de mois (classe G3, trois seances par semaine)
--   F4 : k41 sans classe ni creneau   F5 : k51 avec un creneau choisi, sans classe
--   F6 : k61 mois regle (remboursement)   F7 : k71 doit son mois (dette + N mois, remboursement)
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'fa-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','b3','b4','b6','b7','d1','d2','d3','d4','d5','d6','d7',
                    '11','12','13','21','22','23','31','41','51','61','71']) AS x;
INSERT INTO public.households(id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['f1','f2','f3','f4','f5','f6','f7']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender, created_at)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'FA', (CASE WHEN x.role = 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, x.genre::public.gender,
       now() - make_interval(days => x.age)
  FROM (VALUES
   ('a1','FA-ADM-0001','admin',NULL,'Direction','female',100),
   ('b1','FA-ENS-0001','teacher',NULL,'Maryam','female',100),
   ('b2','FA-ENS-0002','teacher',NULL,'Hawa','female',100),
   ('b3','FA-ENS-0003','teacher',NULL,'Safia','female',100),
   ('b4','FA-ENS-0004','teacher',NULL,'Nadia','female',100),
   ('b6','FA-ENS-0006','teacher',NULL,'Salma','female',100),
   ('b7','FA-ENS-0007','teacher',NULL,'Zaynab','female',100),
   ('d1','FA-TUT-0001','guardian','f1','Amina','female',90),
   ('d2','FA-TUT-0002','guardian','f2','Awa','female',90),
   ('d3','FA-TUT-0003','guardian','f3','Fatou','female',90),
   ('d4','FA-TUT-0004','guardian','f4','Mariam','female',90),
   ('d5','FA-TUT-0005','guardian','f5','Hindou','female',90),
   ('d6','FA-TUT-0006','guardian','f6','Rokia','female',90),
   ('d7','FA-TUT-0007','guardian','f7','Salimata','female',90),
   ('11','FA-ELV-0011','student','f1','Yasmine','female',50),
   ('12','FA-ELV-0012','student','f1','Bilal','male',40),
   ('13','FA-ELV-0013','student','f1','Nour','female',30),
   ('21','FA-ELV-0021','student','f2','Omar','male',50),
   ('22','FA-ELV-0022','student','f2','Issa','male',40),
   ('23','FA-ELV-0023','student','f2','Adam','male',30),
   ('31','FA-ELV-0031','student','f3','Aicha','female',50),
   ('41','FA-ELV-0041','student','f4','Khadija','female',50),
   ('51','FA-ELV-0051','student','f5','Hamza','male',50),
   ('61','FA-ELV-0061','student','f6','Ibrahim','male',50),
   ('71','FA-ELV-0071','student','f7','Sara','female',50)) AS x(id, mat, role, foyer, prenom, genre, age);
UPDATE public.households h SET primary_guardian_id = pg_temp.id('d' || right(h.id::text, 1))
 WHERE h.id IN (SELECT pg_temp.id('f' || n) FROM unnest(ARRAY['1','2','3','4','5','6','7']) n);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.id(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['11','12','13','21','22','23','31','41','51','61','71']) AS x;

-- Un enseignant par classe : aucune collision d'horaire. Une seance, deux creneaux de plus pour G3.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.id('c1'), pg_temp.id('b1'), 'enfant', 5, 'An-Nour FA', 1, 9, 'Europe/Paris'),
 (pg_temp.id('c2'), pg_temp.id('b2'), 'enfant', 5, 'Al-Fajr FA', 2, 9, 'Europe/Paris'),
 (pg_temp.id('c3'), pg_temp.id('b3'), 'enfant', 5, 'Al-Huda FA', 1, 10, 'Europe/Paris'),
 (pg_temp.id('c6'), pg_temp.id('b6'), 'enfant', 5, 'Ar-Rahma FA', 4, 9, 'Europe/Paris'),
 (pg_temp.id('c7'), pg_temp.id('b7'), 'enfant', 5, 'Az-Zahra FA', 5, 9, 'Europe/Paris');
-- (les controles d'affectation de l'enseignant ne sont pas l'objet de ce scenario)
SET LOCAL session_replication_role = replica;
INSERT INTO public.groupe_creneaux(groupe_id, weekday, hour_local) VALUES
 (pg_temp.id('c3'), 3, 10), (pg_temp.id('c3'), 5, 10)
ON CONFLICT DO NOTHING;
SET LOCAL session_replication_role = origin;
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
SELECT pg_temp.id(x.g), pg_temp.id(x.e), pg_temp.mois() - interval '20 days'
  FROM (VALUES ('c1','11'),('c1','12'),('c1','13'),('c2','21'),('c2','22'),('c2','23'),
               ('c6','61'),('c7','71')) AS x(g, e);
-- k31 entre en cours de mois : le 15, a minuit a Paris (la classe vient d'etre creee).
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
VALUES (pg_temp.id('c3'), pg_temp.id('31'), ((pg_temp.mois() + 14)::timestamp AT TIME ZONE 'Europe/Paris'));
-- Une classe qui vient d'etre creee n'a AUCUNE seance avant l'entree, et seulement trois seances apres : le
-- denominateur de l'ancienne formule (seances existantes) valait 3 et le mois etait plein (cas de Dyna).
UPDATE public.sessions SET status = 'canceled' WHERE groupe_id = pg_temp.id('c3');
INSERT INTO public.sessions(teacher_id, started_at, ended_at, groupe_id, status) VALUES
 (pg_temp.id('b3'), (pg_temp.mois() + 19)::timestamp AT TIME ZONE 'Europe/Paris' + interval '10 hours',
  (pg_temp.mois() + 19)::timestamp AT TIME ZONE 'Europe/Paris' + interval '11 hours', pg_temp.id('c3'), 'planned'),
 (pg_temp.id('b3'), (pg_temp.mois() + 21)::timestamp AT TIME ZONE 'Europe/Paris' + interval '10 hours',
  (pg_temp.mois() + 21)::timestamp AT TIME ZONE 'Europe/Paris' + interval '11 hours', pg_temp.id('c3'), 'planned'),
 (pg_temp.id('b3'), (pg_temp.mois() + 23)::timestamp AT TIME ZONE 'Europe/Paris' + interval '10 hours',
  (pg_temp.mois() + 23)::timestamp AT TIME ZONE 'Europe/Paris' + interval '11 hours', pg_temp.id('c3'), 'planned');
-- k51 a choisi son creneau, sans classe.
INSERT INTO public.demandes_horaires_famille(eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source)
VALUES (pg_temp.id('51'), 'enfant', 'francais', 'Europe/Paris', ARRAY[1]::smallint[], ARRAY[10]::smallint[], 'personnalisee');
-- k22 : acces offert (la direction l'a accorde).
INSERT INTO public.bourses_eleves(profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par, nature)
VALUES (pg_temp.id('22'), 1000, pg_temp.mois(), (pg_temp.mois() + interval '5 months')::date, 'Acces offert FA',
        pg_temp.id('a1'), 'acces_offert');
-- k61 : le mois en cours est regle (facture a zero, financee, comme les autres scenarios de paiement).
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                       lignes, total_mineur, statut, financee_le)
VALUES (pg_temp.id('61'), pg_temp.id('f6'), pg_temp.mois(),
        (private.fac_politique_au(pg_temp.mois())).version, 'USD', 1, '[]'::jsonb, 0, 'financee', now());
-- k71 doit son mois : une facture de 55 USD a financer.
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial,
                                       lignes, total_mineur)
VALUES (pg_temp.id('71'), pg_temp.id('f7'), pg_temp.mois(),
        (private.fac_politique_au(pg_temp.mois())).version, 'USD', 1,
        '[{"nature":"tarif","montant":{"mineur":5500,"devise":"USD"},"rang":null}]'::jsonb, 5500);

-- ------------------------------------------------------------------
-- 1. D1 : le prorata suit l'horaire de la classe sur le mois entier
-- ------------------------------------------------------------------
SELECT set_config('test.o', (SELECT count(*) FROM generate_series(pg_temp.mois()::timestamp,
    (pg_temp.mois() + interval '1 month' - interval '1 day')::timestamp, interval '1 day') d
   WHERE extract(isodow FROM d) IN (1, 3, 5))::text, true);
SELECT set_config('test.e', (SELECT count(*) FROM generate_series(pg_temp.mois()::timestamp,
    (pg_temp.mois() + interval '1 month' - interval '1 day')::timestamp, interval '1 day') d
   WHERE extract(isodow FROM d) IN (1, 3, 5) AND d >= (pg_temp.mois() + 14)::timestamp)::text, true);
SELECT pg_temp.vrai(current_setting('test.e')::int < current_setting('test.o')::int AND current_setting('test.e')::int > 3,
  '1 : le mois compte plus de seances que les trois seances existantes apres l''entree');
SELECT pg_temp.vrai((SELECT count(*) FROM private.rch_seances_mois(pg_temp.id('c3'), pg_temp.mois()))
    = current_setting('test.o')::int,
  '1 : l''horaire de la classe donne ses seances sur le mois entier, creees ou non');
SELECT pg_temp.vrai(private.fac_emettre_facture(pg_temp.id('31'), pg_temp.mois(), NULL), '1 : la premiere facture de k31 est emise');
SELECT pg_temp.vrai((pg_temp.fac('31')).total_mineur = 5500 * current_setting('test.e')::bigint / current_setting('test.o')::bigint
  AND (pg_temp.fac('31')).total_mineur < 5500,
  '1 : D1, entre en cours de mois, k31 ne paie pas le mois plein : 55 x seances restantes / seances du mois');
SELECT pg_temp.vrai((SELECT (l ->> 'seances_restantes')::int = current_setting('test.e')::int
                          AND (l ->> 'seances_du_mois')::int = current_setting('test.o')::int
                          AND l ->> 'entree_le' = to_char(pg_temp.mois() + 14, 'YYYY-MM-DD')
                       FROM jsonb_array_elements((pg_temp.fac('31')).lignes) l WHERE l ->> 'nature' = 'prorata'),
  '1 : la ligne de prorata garde la date d''entree et « x seances sur y »');

-- ------------------------------------------------------------------
-- 2. Un profil offert ne prend aucun rang ; les payants gardent le leur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.fac_rang_attendu(pg_temp.id('21'), pg_temp.suivant()) = 1
  AND private.fac_rang_attendu(pg_temp.id('22'), pg_temp.suivant()) IS NULL
  AND private.fac_rang_attendu(pg_temp.id('23'), pg_temp.suivant()) = 2,
  '2 : acces offert : k22 sans rang, k23 2e inscrit payant (et non 3e)');
SELECT pg_temp.vrai(private.fac_emettre_facture(pg_temp.id('22'), pg_temp.mois(), NULL)
  AND private.fac_emettre_facture(pg_temp.id('23'), pg_temp.mois(), NULL)
  AND private.fac_emettre_facture(pg_temp.id('21'), pg_temp.mois(), NULL),
  '2 : les trois factures du mois sont emises, le profil offert au milieu');
SELECT pg_temp.vrai((pg_temp.fac('22')).rang_familial IS NULL
  AND (pg_temp.fac('21')).rang_familial = 1 AND (pg_temp.fac('23')).rang_familial = 2
  AND (pg_temp.fac('22')).total_mineur = 0,
  '2 : la facture du profil offert n''a pas de rang ; les deux payants ont les rangs 1 et 2 dans l''ordre d''inscription, quel que soit l''ordre d''emission');
SELECT pg_temp.vrai((pg_temp.fac('23')).total_mineur = 5060 AND (pg_temp.fac('21')).total_mineur = 5500
  AND private.fac_rang_attendu(pg_temp.id('21'), pg_temp.mois()) = 1
  AND private.fac_rang_attendu(pg_temp.id('23'), pg_temp.mois()) = 2,
  '2 : l''apercu et la facture donnent le meme rang et le meme prix (21 : 55 USD, 23 : 50,60 USD)');
SELECT pg_temp.vrai(pg_temp.prix('23', 1) = 5060 AND pg_temp.prix('21', 1) = 5500,
  '2 : l''offre d''un mois suit ce rang : 55 USD pour le 1er, 50,60 USD (8 %) pour le 2e payant');

-- ------------------------------------------------------------------
-- 3. Politique v2.2.0 : 15 % au 3e inscrit
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.rch_remise_pour_mille(private.fac_politique_au(pg_temp.suivant()), 2) = 80
  AND private.rch_remise_pour_mille(private.fac_politique_au(pg_temp.suivant()), 3) = 150
  AND private.rch_remise_pour_mille(private.fac_politique_au(pg_temp.suivant()), 5) = 150
  AND (private.fac_politique_au(pg_temp.suivant())).cumul_max_pour_mille = 250,
  '3 : la politique du mois suivant : 8 % au 2e, 15 % au 3e et suivants, cumul 25 %');
SELECT pg_temp.vrai(private.fac_rang_attendu(pg_temp.id('11'), pg_temp.suivant()) = 1
  AND private.fac_rang_attendu(pg_temp.id('12'), pg_temp.suivant()) = 2
  AND private.fac_rang_attendu(pg_temp.id('13'), pg_temp.suivant()) = 3,
  '3 : trois enfants : rangs 1, 2, 3 dans l''ordre d''inscription');
SELECT pg_temp.vrai(pg_temp.prix('11', 1) = 5500 AND pg_temp.prix('12', 1) = 5060 AND pg_temp.prix('13', 1) = 4675
  AND pg_temp.prix('11', 1) + pg_temp.prix('12', 1) + pg_temp.prix('13', 1) = 15235,
  '3 : trois enfants = 55 + 50,60 + 46,75 = 152,35 USD');
SELECT pg_temp.vrai(pg_temp.prix('13', 12) = 49500 AND pg_temp.prix('13', 3) = 13200,
  '3 : le 3e enfant : 3 mois 132 USD (15 % + 5 %), 12 mois 495 USD (15 % + 10 % = le plafond de 25 %)');
-- Les factures deja emises ne changent pas : la politique d'avant garde ses 17 %.
SELECT pg_temp.vrai((SELECT remises_par_rang FROM public.politiques_commerciales WHERE version = 'v2.1.0')
    = '[{"pour_mille": 80, "a_partir_du_rang": 2}, {"pour_mille": 170, "a_partir_du_rang": 3}]'::jsonb,
  '3 : v2.1.0 garde ses 17 % (une version publiee ne change pas)');

-- ------------------------------------------------------------------
-- 4. Plafond de cumul 25 % (version d'essai a 17 %, annee a 10 %)
-- ------------------------------------------------------------------
INSERT INTO public.politiques_commerciales
SELECT (jsonb_populate_record(NULL::public.politiques_commerciales, to_jsonb(p) || jsonb_build_object(
   'version', 'v99.0.0', 'date_effet', DATE '2099-01-01', 'publiee_par', NULL))).*
  FROM public.politiques_commerciales p WHERE p.version = 'v2.1.0';
SELECT set_config('test.cap', private.rch_prix_avance(pg_temp.id('13'), DATE '2099-01-01', 12)::text, true);
SELECT pg_temp.vrai((current_setting('test.cap')::jsonb ->> 'totalMineur')::bigint = 49500
  AND pg_temp.ligne(jsonb_build_object('lignes', current_setting('test.cap')::jsonb -> 'lignes'), 'plafond') -> 'montant' ->> 'mineur' = '1320',
  '4 : 17 % + 10 % = 27 % : ramene a 25 %, 495 USD, une ligne « plafond » de 13,20 USD');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(current_setting('test.cap')::jsonb -> 'nonAppliquees') l
                              WHERE l ->> 'code' = 'plafond_atteint' AND l -> 'montant' ->> 'mineur' = '1320'
                                AND (l ->> 'pourMille')::int = 250),
  '4 : la remise non accordee dit « plafond atteint » avec son montant');
SELECT pg_temp.vrai((SELECT sum((l -> 'montant' ->> 'mineur')::bigint)
                       FROM jsonb_array_elements(current_setting('test.cap')::jsonb -> 'lignes') l)
    = (current_setting('test.cap')::jsonb ->> 'totalMineur')::bigint,
  '4 : les lignes s''additionnent exactement au total');

-- ------------------------------------------------------------------
-- 5. Dette + N mois (k31 : la premiere facture au prorata est emise, a financer)
-- ------------------------------------------------------------------
SELECT set_config('test.fac31', (pg_temp.fac('31')).total_mineur::text, true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d3'), 'guardian', pg_temp.id('f3'));
SELECT set_config('test.p31', pg_temp.profil('31')::text, true);
SELECT pg_temp.vrai(current_setting('test.p31')::jsonb ->> 'etat' = 'en_classe'
  AND jsonb_array_length(current_setting('test.p31')::jsonb -> 'options') = 13
  AND (SELECT bool_and((o ->> 'nbMois')::int = n - 1) FROM jsonb_array_elements(current_setting('test.p31')::jsonb -> 'options') WITH ORDINALITY t(o, n)),
  '5 : une dette : treize offres, la dette seule (0), puis dette + 1 a 12 mois');
SELECT pg_temp.vrai((pg_temp.offre('31', 0) -> 'montant' ->> 'mineur')::bigint = current_setting('test.fac31')::bigint
  AND (pg_temp.offre('31', 0) ->> 'formule') = 'libre',
  '5 : l''offre 0 est la dette, au prix de la facture');
SELECT pg_temp.vrai(pg_temp.montant('31', 2) = pg_temp.montant('31', 0) + 2 * 5500
  AND (pg_temp.offre('31', 2) -> 'dette' ->> 'mineur')::bigint = pg_temp.montant('31', 0)
  AND (pg_temp.offre('31', 2) -> 'avance' ->> 'mineur')::bigint = 11000,
  '5 : dette + 2 mois = la dette + 110 USD, la dette montree a part');
SELECT pg_temp.vrai(pg_temp.non(pg_temp.offre('31', 1), 'moins_de_trois_mois')
  AND pg_temp.non(pg_temp.offre('31', 2), 'moins_de_trois_mois')
  AND pg_temp.ligne(pg_temp.offre('31', 2), 'remise_prepaiement') IS NULL
  AND pg_temp.non(pg_temp.offre('31', 2), 'premier_inscrit'),
  '5 : 1 et 2 mois : aucune remise de prepaiement, dite « moins de trois mois » ; 1er inscrit : pas de remise famille, dite');
SELECT pg_temp.vrai(pg_temp.ligne(pg_temp.offre('31', 3), 'remise_prepaiement') -> 'montant' ->> 'mineur' = '-825'
  AND (pg_temp.ligne(pg_temp.offre('31', 3), 'remise_prepaiement') ->> 'pourMille')::int = 50
  AND (pg_temp.offre('31', 12) -> 'avance' ->> 'mineur')::bigint = 59400
  AND (pg_temp.ligne(pg_temp.offre('31', 12), 'remise_prepaiement') ->> 'pourMille')::int = 100,
  '5 : 3 a 11 mois : le taux trimestriel de la politique (5 %) ; 12 mois : le taux annuel (10 %), 594 USD');
SELECT pg_temp.vrai((pg_temp.offre('31', 2) -> 'moisCouverts' ->> 'debut')::date = pg_temp.suivant()
  AND (pg_temp.offre('31', 2) -> 'moisCouverts' ->> 'fin')::date = (pg_temp.suivant() + interval '1 month')::date
  AND pg_temp.offre('31', 0) -> 'moisCouverts' = 'null'::jsonb,
  '5 : les mois couverts commencent le mois suivant (deux mois : debut et fin) ; la dette seule n''en couvre aucun');
SELECT pg_temp.vrai((current_setting('test.p31')::jsonb #>> '{dette,mois,0,prorata,seancesRestantes}')::int = current_setting('test.e')::int
  AND (current_setting('test.p31')::jsonb #>> '{dette,mois,0,prorata,seancesDuMois}')::int = current_setting('test.o')::int
  AND current_setting('test.p31')::jsonb #>> '{dette,mois,0,prorata,entreeLe}' = to_char(pg_temp.mois() + 14, 'YYYY-MM-DD')
  AND current_setting('test.p31')::jsonb #>> '{dette,mois,0,apercu}' = 'false'
  AND (current_setting('test.p31')::jsonb #>> '{dette,mois,0,mois}')::date = pg_temp.mois(),
  '5 : la dette dit son mois, la date d''entree et « x seances sur y »');
RESET ROLE;

-- La premiere facture pas encore emise : l'apercu du serveur vaut ce qu'il emettra.
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at)
VALUES (pg_temp.id('c3'), pg_temp.id('41'), ((pg_temp.mois() + 14)::timestamp AT TIME ZONE 'Europe/Paris'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d4'), 'guardian', pg_temp.id('f4'));
SELECT set_config('test.p41', pg_temp.profil('41')::text, true);
RESET ROLE;
SELECT pg_temp.vrai(current_setting('test.p41')::jsonb #>> '{dette,mois,0,apercu}' = 'true'
  AND (current_setting('test.p41')::jsonb #>> '{dette,total,mineur}')::bigint
      = 5500 * current_setting('test.e')::bigint / current_setting('test.o')::bigint,
  '5 : avant l''emission, la premiere facture est montree au prorata (apercu)');
SELECT pg_temp.vrai(private.fac_emettre_facture(pg_temp.id('41'), pg_temp.mois(), NULL)
  AND (pg_temp.fac('41')).total_mineur = (current_setting('test.p41')::jsonb #>> '{dette,total,mineur}')::bigint,
  '5 : la facture emise ensuite est exactement l''apercu');
-- k41 sort de la classe : plus de classe, plus de creneau.
UPDATE public.groupe_membres SET left_at = now(), left_by = pg_temp.id('a1'), left_reason = 'test FA'
 WHERE student_id = pg_temp.id('41');
UPDATE public.factures_mensuelles SET statut = 'annulee', annulee_le = now(), annulee_par = pg_temp.id('a1'),
       motif_annulation = 'test FA'
 WHERE profile_id = pg_temp.id('41');

-- ------------------------------------------------------------------
-- 6. Aucune offre sans classe ni creneau ; un mois avant le premier mois reel
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d4'), 'guardian', pg_temp.id('f4'));
SELECT pg_temp.vrai(pg_temp.profil('41') ->> 'etat' = 'aucun_creneau'
  AND jsonb_array_length(pg_temp.profil('41') -> 'options') = 0
  AND jsonb_array_length(pg_temp.profil('41') -> 'montantsProposes') = 0
  AND pg_temp.profil('41') -> 'montantSuggere' = 'null'::jsonb,
  '6 : sans classe ni creneau choisi : aucune offre, aucun montant propose');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": 5500, "devise": "USD"}]')$q$,
  pg_temp.id('41')), '22023', '6 : un montant pour un profil sans offre est refuse');
SELECT pg_temp.qui(pg_temp.id('d5'), 'guardian', pg_temp.id('f5'));
SELECT pg_temp.vrai(pg_temp.profil('51') ->> 'etat' = 'avant_premier_mois'
  AND jsonb_array_length(pg_temp.profil('51') -> 'options') = 1
  AND (pg_temp.offre('51', 1) ->> 'formule') = 'mois'
  AND (pg_temp.offre('51', 1) -> 'montant' ->> 'mineur')::bigint = 5500
  AND pg_temp.offre('51', 1) -> 'moisCouverts' = 'null'::jsonb,
  '6 : creneau choisi, pas encore de classe : un mois seulement, au prix du mois');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": 11000, "devise": "USD"}]')$q$,
  pg_temp.id('51')), '22023', '6 : deux mois avant le premier mois reel : refuse');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": 16100, "devise": "USD"}]')$q$,
  pg_temp.id('51')), '22023', '6 : trois mois avant le premier mois reel : refuse');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. La verification n'accepte que les offres du serveur
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.m11_3', pg_temp.montant('11', 3)::text, true);
SELECT set_config('test.d13', (pg_temp.offre('13', 3) -> 'dette' ->> 'mineur'), true);
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": %s, "devise": "USD"}]')$q$,
  pg_temp.id('11'), current_setting('test.m11_3')::bigint + 1), '22023', '7 : un montant forge (un cent de plus) est refuse');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": %s, "devise": "USD"}]')$q$,
  pg_temp.id('11'), current_setting('test.m11_3')::bigint - 100), '22023', '7 : un montant forge (un dollar de moins) est refuse');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": %s, "devise": "USD", "nbMois": 4}]')$q$,
  pg_temp.id('11'), current_setting('test.m11_3')::bigint), '22023', '7 : le bon montant avec un mauvais nombre de mois est refuse');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": 100, "devise": "USD"}]')$q$,
  pg_temp.id('11')), '22023', '7 : aucun montant libre');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": %s, "devise": "USD"}, {"profilId": "%s", "mineur": %s, "devise": "USD"}]')$q$,
  pg_temp.id('11'), pg_temp.montant('11', 1), pg_temp.id('11'), pg_temp.montant('11', 1)),
  '22023', '7 : le meme profil deux fois dans un recapitulatif est refuse');
SELECT pg_temp.refus(format($q$SELECT public.recharge_verifier_montants('[{"profilId": "%s", "mineur": %s, "devise": "USD"}]')$q$,
  pg_temp.id('21'), 5500), '42501', '7 : un profil d''un autre foyer est refuse');
SELECT set_config('test.r1', public.recharge_verifier_montants(jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('13'), 'mineur', pg_temp.montant('13', 3), 'devise', 'USD', 'nbMois', 3),
  jsonb_build_object('profilId', pg_temp.id('11'), 'mineur', pg_temp.montant('11', 1), 'devise', 'USD')))::text, true);
SELECT pg_temp.vrai((current_setting('test.r1')::jsonb #>> '{total,mineur}')::bigint
      = pg_temp.montant('13', 3) + pg_temp.montant('11', 1)
  AND current_setting('test.r1')::jsonb #>> '{lignes,0,beneficiaireId}' = pg_temp.id('11')::text
  AND (current_setting('test.r1')::jsonb #>> '{lignes,1,nbMois}')::int = 3
  AND current_setting('test.r1')::jsonb #>> '{lignes,1,formule}' = 'trimestriel',
  '7 : une offre du serveur passe ; les lignes suivent l''ordre d''inscription et gardent le nombre de mois');
RESET ROLE;
SELECT pg_temp.vrai((SELECT nb_mois = 3 AND mois_debut = pg_temp.suivant() AND dette_mineur = current_setting('test.d13')::bigint
                       FROM public.recharges_recap_lignes
                      WHERE recapitulatif_id = (current_setting('test.r1')::jsonb ->> 'id')::uuid
                        AND profile_id = pg_temp.id('13')),
  '7 : le recapitulatif enregistre le nombre de mois, le premier mois couvert et la dette');

-- ------------------------------------------------------------------
-- 8. Payer N mois, puis se faire rembourser : les mois commences au prix normal, le reste rendu
-- ------------------------------------------------------------------
CREATE FUNCTION pg_temp.payer(p_titulaire text, p_foyer text, p_lignes jsonb, p_cle text, p_pi text)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_r jsonb; v_c uuid; v_total bigint;
BEGIN
  PERFORM pg_temp.qui(pg_temp.id(p_titulaire), 'guardian', pg_temp.id(p_foyer));
  EXECUTE 'SET LOCAL ROLE authenticated';
  v_r := public.recharge_verifier_montants(p_lignes);
  v_c := (public.recharge_payer((v_r ->> 'id')::uuid, ('fa000000-0000-4000-8000-000000' || p_cle)::uuid) ->> 'commandeId')::uuid;
  EXECUTE 'RESET ROLE';
  SELECT total_mineur INTO v_total FROM public.commandes_recharge WHERE id = v_c;
  EXECUTE 'SET LOCAL ROLE service_role';
  PERFORM public.recharge_attacher_session(v_c, pg_temp.id(p_titulaire), 'cs_' || p_pi,
    'https://checkout.stripe.com/c/cs_' || p_pi, 'test');
  IF public.recharge_evenement_stripe('evt_pay_' || p_pi, 'checkout.session.completed', 'test', v_c,
       'cs_' || p_pi, p_pi, 'paid', v_total, 'usd') <> 'credite' THEN
    RAISE EXCEPTION 'PAIEMENT-FAMILLE ROUGE : paiement % non credite', p_pi;
  END IF;
  EXECUTE 'RESET ROLE';
  RETURN v_c;
END $$;
CREATE FUNCTION pg_temp.propose(p_commande uuid, p_profil text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT private.fn115c_montant_propose(p_commande, pg_temp.id(p_profil)) $$;

-- k61 : le mois est regle ; trois mois d'avance (decembre en general, selon l'horloge).
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d6'), 'guardian', pg_temp.id('f6'));
SELECT pg_temp.vrai(pg_temp.profil('61') ->> 'etat' = 'en_classe'
  AND jsonb_array_length(pg_temp.profil('61') -> 'options') = 12
  AND pg_temp.profil('61') #>> '{dette,total,mineur}' = '0'
  AND pg_temp.montant('61', 3) = 15700,
  '8 : mois regle : douze offres (1 a 12 mois), pas de dette ; 3 mois = 157 USD');
SELECT set_config('test.m61', pg_temp.montant('61', 3)::text, true);
RESET ROLE;
SELECT set_config('test.c61', pg_temp.payer('d6', 'f6', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('61'), 'mineur', current_setting('test.m61')::bigint, 'devise', 'USD', 'nbMois', 3)),
  '00a061', 'pi_fa_61')::text, true);
SELECT pg_temp.vrai((SELECT e.nb_mois = 3 AND e.formule = 'trimestriel' AND e.mois_debut = pg_temp.suivant()
                            AND e.total_mineur = current_setting('test.m61')::bigint
                       FROM public.engagements_prepaiement e WHERE e.profile_id = pg_temp.id('61')),
  '8 : le paiement ouvre l''engagement de 3 mois au mois suivant, pour le prix payé');
-- Une offre suivante commence APRES l'engagement : jamais deux engagements qui se recouvrent.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d6'), 'guardian', pg_temp.id('f6'));
SELECT pg_temp.vrai((pg_temp.offre('61', 1) -> 'moisCouverts' ->> 'debut')::date
      = (pg_temp.suivant() + interval '3 months')::date,
  '8 : l''offre suivante commence apres l''engagement en cours');
RESET ROLE;
-- Le paiement est vieux de 40 jours (apres le delai) et le trimestre a commence il y a deux mois.
UPDATE public.commandes_recharge SET confirme_le = now() - interval '40 days'
 WHERE id = current_setting('test.c61')::uuid;
UPDATE public.engagements_prepaiement
   SET mois_debut = (date_trunc('month', now() - interval '40 days') + interval '1 month')::date
 WHERE commande_id = current_setting('test.c61')::uuid;
SELECT pg_temp.vrai(pg_temp.propose(current_setting('test.c61')::uuid, '61') ->> 'regle' = 'prepaiement'
  AND (pg_temp.propose(current_setting('test.c61')::uuid, '61') ->> 'mois_commences')::int BETWEEN 1 AND 2
  AND (pg_temp.propose(current_setting('test.c61')::uuid, '61') ->> 'montant_mineur')::bigint
      = current_setting('test.m61')::bigint
        - (pg_temp.propose(current_setting('test.c61')::uuid, '61') ->> 'mois_commences')::int * 5500,
  '8 : remboursement apres le delai : le trimestre moins les mois commences au prix normal (55 USD), le reste rendu');

-- k71 doit son mois : dette + 3 mois. L'engagement ne porte que les 3 mois, jamais la dette.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d7'), 'guardian', pg_temp.id('f7'));
SELECT pg_temp.vrai((pg_temp.offre('71', 0) -> 'montant' ->> 'mineur')::bigint = 5500
  AND pg_temp.montant('71', 3) = 5500 + 15700
  AND pg_temp.profil('71') -> 'montantSuggere' ->> 'mineur' = '5500',
  '8 : une dette de 55 USD : l''offre 3 mois = 55 (dette) + 157 USD, la dette est le montant suggere');
SELECT set_config('test.m71', pg_temp.montant('71', 3)::text, true);
RESET ROLE;
SELECT set_config('test.c71', pg_temp.payer('d7', 'f7', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('71'), 'mineur', current_setting('test.m71')::bigint, 'devise', 'USD', 'nbMois', 3)),
  '00a071', 'pi_fa_71')::text, true);
SELECT pg_temp.vrai((pg_temp.fac('71')).statut = 'financee'
  AND (SELECT e.total_mineur = 15700 AND e.nb_mois = 3 FROM public.engagements_prepaiement e
        WHERE e.profile_id = pg_temp.id('71'))
  AND (SELECT a.dette_mineur = 5500 AND a.montant_mineur = 21200 FROM public.commandes_recharge_allocations a
        WHERE a.commande_id = current_setting('test.c71')::uuid)
  AND pg_temp.solde('71') = 15700,
  '8 : la dette finance la facture du mois ; l''engagement porte 157 USD (3 mois), sans la dette ; 157 USD restent en solde');
UPDATE public.commandes_recharge SET confirme_le = now() - interval '40 days'
 WHERE id = current_setting('test.c71')::uuid;
UPDATE public.engagements_prepaiement
   SET mois_debut = (date_trunc('month', now() - interval '40 days') + interval '1 month')::date
 WHERE commande_id = current_setting('test.c71')::uuid;
SELECT pg_temp.vrai((pg_temp.propose(current_setting('test.c71')::uuid, '71') ->> 'montant_mineur')::bigint
      = 15700 - (pg_temp.propose(current_setting('test.c71')::uuid, '71') ->> 'mois_commences')::int * 5500
  AND (pg_temp.propose(current_setting('test.c71')::uuid, '71') ->> 'montant_mineur')::bigint <= 15700 - 5500,
  '8 : dette + 3 mois, rembourse apres le delai : calcule sur les 157 USD d''avance seulement, jamais sur la dette de 55 USD');


-- ------------------------------------------------------------------
-- 8 ter. Le prix mensuel normal garde la remise de rang (DECISION-TARIFS point 3)
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d2'), 'guardian', pg_temp.id('f2'));
SELECT set_config('test.m23', pg_temp.montant('23', 3)::text, true);
RESET ROLE;
SELECT set_config('test.c23', pg_temp.payer('d2', 'f2', jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('23'), 'mineur', current_setting('test.m23')::bigint, 'devise', 'USD', 'nbMois', 3)),
  '00a023', 'pi_fa_23')::text, true);
SELECT pg_temp.vrai((SELECT e.prix_mensuel_mineur = 5060 AND e.nb_mois = 3
                       FROM public.engagements_prepaiement e WHERE e.profile_id = pg_temp.id('23')),
  '8 ter : l''engagement garde le prix mensuel normal du 2e inscrit : 50,60 USD (8 % de rang, sans la remise du trimestre)');
UPDATE public.commandes_recharge SET confirme_le = now() - interval '40 days'
 WHERE id = current_setting('test.c23')::uuid;
UPDATE public.engagements_prepaiement
   SET mois_debut = (date_trunc('month', now() - interval '40 days') + interval '1 month')::date
 WHERE commande_id = current_setting('test.c23')::uuid;
SELECT pg_temp.vrai((pg_temp.propose(current_setting('test.c23')::uuid, '23') ->> 'montant_mineur')::bigint
      = (SELECT e.total_mineur FROM public.engagements_prepaiement e WHERE e.commande_id = current_setting('test.c23')::uuid)
        - (pg_temp.propose(current_setting('test.c23')::uuid, '23') ->> 'mois_commences')::int * 5060
  AND (pg_temp.propose(current_setting('test.c23')::uuid, '23') ->> 'mois_commences')::int BETWEEN 1 AND 2,
  '8 ter : rembourse apres le delai : les mois commences comptes a 50,60 USD (pas 55), jamais moins que la regle');

-- ------------------------------------------------------------------
-- 8 quater. Les mois couverts sont figes au recapitulatif
-- ------------------------------------------------------------------
CREATE FUNCTION pg_temp.refus_message(p_sql text, p_fragment text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'PAIEMENT-FAMILLE ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> '22023' OR position(p_fragment in SQLERRM) = 0 THEN
      RAISE EXCEPTION 'PAIEMENT-FAMILLE ROUGE : % (%, %)', p_label, SQLSTATE, SQLERRM;
    END IF;
  END;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.refus_message(text, text, text) TO authenticated;

-- (a) La dette change entre la verification et le paiement : refuse AVANT Stripe, message clair.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.r13', public.recharge_verifier_montants(jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('13'), 'mineur', pg_temp.montant('13', 1), 'devise', 'USD', 'nbMois', 1)))::text, true);
RESET ROLE;
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur)
VALUES (pg_temp.id('13'), pg_temp.id('f1'), (pg_temp.mois() - interval '1 month')::date,
        (private.fac_politique_au(pg_temp.mois())).version, 'USD', 3, '[]'::jsonb, 1234);
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT pg_temp.refus_message(format($q$SELECT public.recharge_payer(%L, gen_random_uuid())$q$,
  current_setting('test.r13')::jsonb ->> 'id'), 'le montant a changé, vérifiez à nouveau',
  '8 quater : une nouvelle facture entre la verification et le paiement : refuse avant Stripe, « le montant a changé, vérifiez à nouveau »');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.commandes_recharge
                                 WHERE recapitulatif_id = (current_setting('test.r13')::jsonb ->> 'id')::uuid),
  '8 quater : aucune commande creee, donc rien envoye a Stripe');

-- (b) Le mois change avant que le prestataire confirme : l'engagement prend EXACTEMENT les mois figes.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d1'), 'guardian', pg_temp.id('f1'));
SELECT set_config('test.r11', public.recharge_verifier_montants(jsonb_build_array(
  jsonb_build_object('profilId', pg_temp.id('11'), 'mineur', pg_temp.montant('11', 2), 'devise', 'USD', 'nbMois', 2)))::text, true);
SELECT set_config('test.m11', pg_temp.montant('11', 2)::text, true);
SELECT set_config('test.cm11', public.recharge_payer((current_setting('test.r11')::jsonb ->> 'id')::uuid,
  'fa000000-0000-4000-8000-00000000a111') ->> 'commandeId', true);
RESET ROLE;
-- La verification date du mois d'avant : ses mois figes commencent ce mois-ci, et le mois a change depuis.
UPDATE public.commandes_recharge_allocations SET mois_debut = pg_temp.mois()
 WHERE commande_id = current_setting('test.cm11')::uuid;
-- Une nouvelle facture est tombee entre-temps (le prestataire a deja debite la carte).
INSERT INTO public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur)
VALUES (pg_temp.id('11'), pg_temp.id('f1'), (pg_temp.mois() - interval '1 month')::date,
        (private.fac_politique_au(pg_temp.mois())).version, 'USD', 1, '[]'::jsonb, 700);
SET LOCAL ROLE service_role;
SELECT public.recharge_attacher_session(current_setting('test.cm11')::uuid, pg_temp.id('d1'), 'cs_fa_m11', 'https://x/cs_fa_m11', 'test');
SELECT pg_temp.vrai(public.recharge_evenement_stripe('evt_fa_m11', 'checkout.session.completed', 'test',
  current_setting('test.cm11')::uuid, 'cs_fa_m11', 'pi_fa_m11', 'paid', current_setting('test.m11')::bigint, 'usd') = 'credite',
  '8 quater : le prestataire a debite : credite');
RESET ROLE;
SELECT pg_temp.vrai((SELECT e.mois_debut = pg_temp.mois() AND e.nb_mois = 2
                            AND e.total_mineur = (SELECT a.montant_mineur - a.dette_mineur FROM public.commandes_recharge_allocations a
                                                   WHERE a.commande_id = current_setting('test.cm11')::uuid)
                       FROM public.engagements_prepaiement e WHERE e.profile_id = pg_temp.id('11')),
  '8 quater : l''engagement couvre exactement les mois figes au recapitulatif, jamais « le mois suivant maintenant »');
SELECT pg_temp.vrai((SELECT amount_minor FROM public.wallet_entries WHERE reference_id = current_setting('test.cm11')::uuid
                        AND reference_type = 'credit' AND beneficiaire_id = pg_temp.id('11')) = current_setting('test.m11')::bigint,
  '8 quater : tout ce que le prestataire a debite est credite, au profil, exactement');

-- Un profil a acces offert : rien a payer, aucune offre ; son frere paye au rang 2.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('d2'), 'guardian', pg_temp.id('f2'));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.profil('22') -> 'options') = 0
  AND jsonb_array_length(pg_temp.profil('23') -> 'options') >= 12
  AND (pg_temp.profil('23') ->> 'rang')::int = 2,
  '8 bis : acces offert : aucune offre pour k22 ; k23 est le 2e payant');
RESET ROLE;

-- ------------------------------------------------------------------
-- 9. Les droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.rch_options(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.rch_prix_avance(uuid, date, integer)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.rch_dette(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.rch_explication(uuid, text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.recharge_beneficiaires()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.recharge_verifier_montants(jsonb)', 'EXECUTE'),
  '9 : les aides de prix restent privees ; la recharge reste au titulaire connecte');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('11'), 'student', pg_temp.id('f1'));
SELECT pg_temp.refus($q$SELECT public.recharge_beneficiaires()$q$, '42501', '9 : un enfant ne lit pas les offres');
RESET ROLE;

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 57,
  'au moins 57 controles ont passe (58 avec celui-ci)');
\o
SELECT 'PAIEMENT-FAMILLE-PRIX : scenarios verts' AS resultat;
ROLLBACK;
