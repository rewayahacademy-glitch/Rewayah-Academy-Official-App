-- PAIE-FENETRE (13/11/2026, migration 20261124900000) : la fenetre payable.
-- Regle du directeur : une classe d'adultes, c'est 1 h 30 ; une classe
-- d'enfants, 1 heure ; les minutes d'avant et d'apres ne comptent pas dans la
-- paie ; un enseignant peut entrer et sortir plusieurs fois.
--
-- Taux de la politique en vigueur : 199 (enfant) et 157 (adulte) centiemes par
-- eleve present et par heure ; duree due 45 (enfant) et 70 (adulte) minutes.
-- Une eleve presente a chaque seance. Secondes depuis le debut prevu.
--
--  s61 enfant, planifiee 60 : entrees et sorties multiples, arrivee 10 minutes
--      avant, depart 15 minutes apres : -600..600, 900..2100, 2400..4500
--      -> dans la fenetre 600 + 1200 + 1200 = 3000 s = 50 minutes ; duree due
--      atteinte, 60 minutes payees = 199.
--  s62 enfant, planifiee 90 (plus longue que la formule) : 0..5400
--      -> 60 minutes comptees, 60 payees = 199 (299 avant).
--  s63 enfant, planifiee 40 (plus courte) : 0..2400
--      -> fenetre de 40 minutes, 40 comptees, 40 payees = 133.
--  s64 adulte, planifiee 90 : -300..1800, 2100..6000
--      -> 1800 + 3300 = 5100 s = 85 minutes ; due atteinte, 90 payees = 236.
--  s65 adulte, planifiee 120 : 0..7200 -> 90 comptees, 90 payees = 236 (314 avant).
--  s66 adulte, planifiee 75 (plus courte) : 0..4500 -> 75 comptees, 75 payees = 196.
--  s67 enfant, planifiee 60, remplacante : la titulaire 0..600, la remplacante
--      600..3900 -> seules les minutes de la remplacante comptent : 50, 60 payees.
--  s68 enfant, planifiee 60 : entree a 1800, depart jamais recu, seance close
--      deux heures apres -> fermee a la fin de la fenetre : 30 minutes, 30
--      payees = 100.
--  s6b enfant, planifiee 90 : l'enseignante n'entre qu'apres la fenetre
--      (3700..5400) -> 0 minute de paie, la seance part a la direction.
--  s69 enfant, EN COURS depuis 20 minutes, sans fin financiere : enseignante
--      entree 5 minutes avant, eleve entree a 60 s, toutes deux encore la.
--      -> jamais de temps a venir : au plus 20 minutes (74 avant), eleve
--      « partielle » tant que la moitie n'est pas atteinte (« presente » avant).
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'ROUGE : ...'.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('b9100000-0000-4000-8000-0000000000' || p)::uuid $$;
CREATE FUNCTION pg_temp.d(p_seance text) RETURNS timestamptz LANGUAGE sql AS
  $$ SELECT s.started_at FROM public.sessions s WHERE s.id = pg_temp.u(p_seance) $$;
-- Montant de paie ecrit pour une seance (NULL s'il n'y en a pas).
CREATE FUNCTION pg_temp.paie(p_seance text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT m.montant_minor FROM public.tresorerie_mouvements m
      WHERE m.source_type = 'prestation' AND m.source_id = pg_temp.u(p_seance)::text
        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
CREATE FUNCTION pg_temp.fenetre(p_seance text) RETURNS numeric LANGUAGE sql AS
  $$ SELECT f.minutes FROM private.pai_fenetre(pg_temp.u(p_seance)) f $$;
CREATE FUNCTION pg_temp.tenues(p_seance text) RETURNS integer LANGUAGE sql AS
  $$ SELECT private.pai_minutes_enseignant(pg_temp.u(p_seance)) $$;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT p.taux_eleve_heure_enfant_mineur = 199 AND p.taux_eleve_heure_adulte_mineur = 157
                       AND p.duree_due_enfant_minutes = 45 AND p.duree_due_adulte_minutes = 70
                       FROM private.fac_politique_au(pg_temp.mois()) p),
  'politique en vigueur : taux 199 et 157, durees dues 45 et 70 (ce lot ne les change pas)');
SELECT pg_temp.vrai(public.app_config_int('seance.duree_minutes_enfant', 0) = 60
                AND public.app_config_int('seance.duree_minutes_adulte', 0) = 90,
  'reglage de la direction : formule de 60 minutes (enfants) et 90 minutes (adultes)');

INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'pfe-' || x || '@test.invalid' FROM unnest(ARRAY['a1','b1','b2','d1','e1','e2']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role IN ('student', 'guardian') THEN pg_temp.u('f1') END,
       x.prenom, 'PFE', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','PFE-ADM-01','admin','Direction'),
   ('b1','PFE-ENS-01','teacher','Maryam'),
   ('b2','PFE-ENS-02','teacher','Khadija'),
   ('d1','PFE-TUT-01','guardian','Amina'),
   ('e1','PFE-ELV-01','student','Yasmine'),
   ('e2','PFE-ELV-02','student','Nour')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour PFE', 1, 8, 'Europe/Paris'),
 (pg_temp.u('c2'), pg_temp.u('b1'), 'adulte', 6, 'Al-Fajr PFE', 2, 8, 'Europe/Paris');

-- Une seance par jour, passee, dans le mois ; s69 a commence il y a 20 minutes.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.id), pg_temp.u('b1'),
       pg_temp.mois() + x.jour * interval '1 day' + interval '8 hours',
       pg_temp.mois() + x.jour * interval '1 day' + interval '8 hours' + x.duree * interval '1 minute',
       'planned', pg_temp.u(x.classe)
  FROM (VALUES ('61', 0, 60, 'c1'), ('62', 1, 90, 'c1'), ('63', 2, 40, 'c1'),
               ('64', 3, 90, 'c2'), ('65', 4, 120, 'c2'), ('66', 5, 75, 'c2'),
               ('67', 6, 60, 'c1'), ('68', 7, 60, 'c1'), ('6b', 8, 90, 'c1')) AS x(id, jour, duree, classe);
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('69'), pg_temp.u('b1'),
        date_trunc('second', now()) - interval '20 minutes',
        date_trunc('second', now()) + interval '40 minutes', 'planned', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(x), pg_temp.u('e1'), 'student'::public.participant_role
  FROM unnest(ARRAY['61','62','63','64','65','66','67','68','6b','69']) AS x;

-- s67 : absence declaree par la titulaire, remplacement pris par b2.
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, cree_le)
VALUES
  (pg_temp.u('67'), 'absence_declaree', pg_temp.u('b1'), NULL, pg_temp.u('b1'),
   pg_temp.u('91'), pg_catalog.clock_timestamp()),
  (pg_temp.u('67'), 'remplacement_pris', pg_temp.u('b1'), pg_temp.u('b2'), pg_temp.u('b2'),
   pg_temp.u('92'), pg_catalog.clock_timestamp() + interval '1 millisecond');

INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u(x.s), pg_temp.u(x.p), x.t::public.session_event_type,
       pg_temp.d(x.s) + x.sec * interval '1 second', 'livekit_webhook'
  FROM (VALUES
    -- L'eleve e1 : presente tout le long de chaque seance close.
    (1,'61','e1','joined',0), (2,'61','e1','left',3600),
    (3,'62','e1','joined',0), (4,'62','e1','left',5400),
    (5,'63','e1','joined',0), (6,'63','e1','left',2400),
    (7,'64','e1','joined',0), (8,'64','e1','left',5400),
    (9,'65','e1','joined',0), (10,'65','e1','left',7200),
    (11,'66','e1','joined',0), (12,'66','e1','left',4500),
    (13,'67','e1','joined',0), (14,'67','e1','left',3600),
    (15,'68','e1','joined',0), (16,'68','e1','left',3600),
    (17,'6b','e1','joined',0), (18,'6b','e1','left',5400),
    -- s61 : trois passages, avant l'heure, pendant, apres l'heure.
    (20,'61','b1','joined',-600), (21,'61','b1','left',600),
    (22,'61','b1','joined',900), (23,'61','b1','left',2100),
    (24,'61','b1','joined',2400), (25,'61','b1','left',4500),
    -- s62, s63 : toute la duree planifiee.
    (30,'62','b1','joined',0), (31,'62','b1','left',5400),
    (32,'63','b1','joined',0), (33,'63','b1','left',2400),
    -- s64 : adulte, deux passages, avant et apres l'heure.
    (40,'64','b1','joined',-300), (41,'64','b1','left',1800),
    (42,'64','b1','joined',2100), (43,'64','b1','left',6000),
    -- s65, s66 : toute la duree planifiee.
    (50,'65','b1','joined',0), (51,'65','b1','left',7200),
    (52,'66','b1','joined',0), (53,'66','b1','left',4500),
    -- s67 : la titulaire dix minutes, puis la remplacante jusqu'apres l'heure.
    (60,'67','b1','joined',0), (61,'67','b1','left',600),
    (62,'67','b2','joined',600), (63,'67','b2','left',3900),
    -- s68 : entree a la demie, depart jamais recu.
    (70,'68','b1','joined',1800),
    -- s6b : seulement apres la fenetre de 60 minutes.
    (80,'6b','b1','joined',3700), (81,'6b','b1','left',5400),
    -- s69 (en cours) : enseignante 5 minutes avant, eleve a 60 s, encore la.
    (90,'69','b1','joined',-300), (91,'69','e1','joined',60)
  ) AS x(ordre, s, p, t, sec)
 ORDER BY x.ordre;

-- Cloture : « ended » declenche la paie. La fin financiere est posee deux
-- heures apres la fin prevue (cloture tardive). s69 reste en cours.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id::text LIKE 'b9100000-0000-4000-8000-00000000006_';
UPDATE public.sessions SET status = 'in_progress' WHERE id::text LIKE 'b9100000-0000-4000-8000-00000000006_';
UPDATE public.sessions s
   SET finance_started_at = s.started_at, finance_ended_at = s.ended_at + interval '2 hours', status = 'ended'
 WHERE s.id::text LIKE 'b9100000-0000-4000-8000-00000000006_' AND s.id <> pg_temp.u('69');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- 1. La fenetre payable
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.fenetre('61') = 60 AND pg_temp.fenetre('64') = 90,
  'fenetre : 60 minutes pour une classe d''enfants, 90 pour une classe d''adultes');
SELECT pg_temp.vrai(pg_temp.fenetre('62') = 60 AND pg_temp.fenetre('65') = 90,
  'seance planifiee plus longue que la formule (90 enfant, 120 adulte) : la fenetre reste 60 et 90');
SELECT pg_temp.vrai(pg_temp.fenetre('63') = 40 AND pg_temp.fenetre('66') = 75,
  'seance planifiee plus courte que la formule (40 enfant, 75 adulte) : la fenetre s''arrete a la fin planifiee');
SELECT pg_temp.vrai((SELECT f.debut = pg_temp.d('62') AND f.fin = pg_temp.d('62') + interval '60 minutes'
                       AND f.formule_minutes = 60 FROM private.pai_fenetre(pg_temp.u('62')) f),
  'fenetre : du debut prevu au debut prevu plus la duree de la formule');

-- ------------------------------------------------------------------
-- 2. Les minutes de paie : rien avant, rien apres, les passages s'additionnent
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.tenues('61') = 50,
  'entrees et sorties multiples, arrivee avant et depart apres l''heure : 600 + 1200 + 1200 s = 50 minutes');
SELECT pg_temp.vrai((SELECT t.minutes = 65 FROM private.presence_temps_reel(pg_temp.u('61'), pg_temp.u('b1')) t),
  'la presence (hors paie) garde sa regle : 65 minutes avec la grace, la paie n''en compte que 50');
SELECT pg_temp.vrai(pg_temp.tenues('62') = 60 AND pg_temp.tenues('65') = 90,
  'seance plus longue : 60 minutes (enfant) et 90 (adulte) comptees, pas 90 ni 120');
SELECT pg_temp.vrai(pg_temp.tenues('63') = 40 AND pg_temp.tenues('66') = 75,
  'seance plus courte : 40 et 75 minutes comptees');
SELECT pg_temp.vrai(pg_temp.tenues('64') = 85,
  'adulte, deux passages, 5 minutes avant et 10 apres : 1800 + 3300 s = 85 minutes');
SELECT pg_temp.vrai(pg_temp.tenues('67') = 50,
  'remplacante : seules ses minutes dans la fenetre comptent (50), pas les 10 de la titulaire');
SELECT pg_temp.vrai(pg_temp.tenues('68') = 30,
  'depart jamais recu : la connexion est fermee a la fin de la fenetre (30 minutes), pas a la cloture');
SELECT pg_temp.vrai(pg_temp.tenues('6b') = 0,
  'presence seulement apres la fenetre : zero minute de paie');

-- ------------------------------------------------------------------
-- 3. La paie ecrite a la cloture
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.paie('61') = 199,
  's61 : 50 minutes tenues >= 45 dues, 60 payees : 199 x 1 x 60 / 60 = 199');
SELECT pg_temp.vrai(pg_temp.paie('62') = 199,
  's62 enfant planifiee 90 : 60 minutes payees = 199 (299 avant)');
SELECT pg_temp.vrai(pg_temp.paie('63') = 133,
  's63 enfant planifiee 40 : 40 minutes payees : round(199 x 40 / 60) = 133');
SELECT pg_temp.vrai(pg_temp.paie('64') = 236,
  's64 adulte : 85 minutes tenues >= 70 dues, 90 payees : round(157 x 90 / 60) = 236');
SELECT pg_temp.vrai(pg_temp.paie('65') = 236,
  's65 adulte planifiee 120 : 90 minutes payees = 236 (314 avant)');
SELECT pg_temp.vrai(pg_temp.paie('66') = 196,
  's66 adulte planifiee 75 : 75 tenues >= 70 dues, 75 payees : round(157 x 75 / 60) = 196');
SELECT pg_temp.vrai(pg_temp.paie('67') = 199,
  's67 remplacante : 50 minutes tenues, 60 payees = 199');
SELECT pg_temp.vrai(pg_temp.paie('68') = 100,
  's68 : 30 minutes tenues < 45 dues, 30 payees : round(199 x 30 / 60) = 100');
SELECT pg_temp.vrai(pg_temp.paie('6b') IS NULL AND EXISTS (
    SELECT 1 FROM public.tresorerie_a_reprendre q
     WHERE q.source_type = 'prestation' AND q.source_id = pg_temp.u('6b')::text
       AND q.raison = 'duree_indeterminee'),
  's6b : aucune minute dans la fenetre, rien n''est paye, la seance part a la direction');
SELECT pg_temp.vrai(private.pai_eleves_presents(pg_temp.u('62')) = 1,
  'le compte des eleves presents ne change pas');

-- ------------------------------------------------------------------
-- 4. Ce que lit l'ecran des revenus et le releve de la direction
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT bool_and(p.minutes = pg_temp.tenues(right(p.seance::text, 2)))
          AND count(*) = 7
     FROM private.bf1_prestations(pg_temp.u('b1'), pg_temp.mois()::timestamptz - interval '1 day',
                                  pg_temp.mois()::timestamptz + interval '40 days') p),
  'revenus de la titulaire : 7 seances payees, les memes minutes que la paie');
SELECT pg_temp.vrai(
  (SELECT p.minutes = 50 AND p.montant = 199
     FROM private.bf1_prestations(pg_temp.u('b2'), pg_temp.mois()::timestamptz - interval '1 day',
                                  pg_temp.mois()::timestamptz + interval '40 days') p),
  'revenus de la remplacante : s67, 50 minutes, 199');
SELECT pg_temp.vrai(
  (SELECT r.minutes = 60 AND coalesce(r.montant, 199) = 199
     FROM private.pai_releve_seances(pg_temp.mois()::timestamptz - interval '1 day',
                                     pg_temp.mois()::timestamptz + interval '40 days') r
    WHERE r.seance = pg_temp.u('62')),
  'releve de la direction : s62, 60 minutes (montant 199, masque tant que le cahier de la semaine manque)');

-- ------------------------------------------------------------------
-- 5. Seance en cours, sans fin financiere : jamais de temps a venir
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT t.minutes BETWEEN 18 AND 19 AND t.sortie IS NULL AND t.statut = 'partielle'
                       AND t.arrivee = pg_temp.d('69') + interval '60 seconds'
                       FROM private.presence_temps_reel(pg_temp.u('69'), pg_temp.u('e1')) t),
  'seance en cours : l''eleve entree a 60 s a 18 ou 19 minutes (58 avant), partielle (presente avant), sans heure de sortie');
SELECT pg_temp.vrai((SELECT t.minutes BETWEEN 19 AND 20 AND t.sortie IS NULL
                       AND t.arrivee = pg_temp.d('69')
                       FROM private.presence_temps_reel(pg_temp.u('69'), pg_temp.u('b1')) t),
  'seance en cours : l''enseignante entree avant l''heure est comptee depuis le debut prevu, jusqu''a maintenant');
SELECT pg_temp.vrai(pg_temp.tenues('69') BETWEEN 19 AND 20,
  'seance en cours : minutes de paie jusqu''a maintenant, pas jusqu''a la fin de la fenetre');
SELECT pg_temp.vrai(private.pai_due_seance(pg_temp.u('69'), private.fac_politique_au(pg_temp.mois())) IS NULL
                AND pg_temp.paie('69') IS NULL,
  'seance en cours : aucune paie tant qu''elle n''est pas close');
-- Sans fin financiere et fin prevue passee : la borne est la fin prevue, sans
-- la grace (elle ne vaut qu'avec une fin financiere).
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET finance_ended_at = NULL WHERE id = pg_temp.u('68');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
SELECT pg_temp.vrai((SELECT t.minutes = 30 FROM private.presence_temps_reel(pg_temp.u('68'), pg_temp.u('b1')) t),
  'sans fin financiere, fin prevue passee : la presence s''arrete a la fin prevue (30 minutes, 45 avant)');

-- ------------------------------------------------------------------
-- 6. La duree de la formule est le reglage de la direction
-- ------------------------------------------------------------------
UPDATE public.app_config SET value = to_jsonb(75) WHERE key = 'seance.duree_minutes_enfant';
SELECT pg_temp.vrai(pg_temp.fenetre('62') = 75 AND pg_temp.tenues('62') = 75 AND pg_temp.fenetre('61') = 60,
  'reglage enfant passe a 75 : la fenetre d''une seance planifiee 90 devient 75, celle d''une seance de 60 reste 60');
SELECT pg_temp.vrai(pg_temp.fenetre('65') = 90,
  'reglage enfant change : la fenetre d''une classe d''adultes ne bouge pas');
SELECT pg_temp.vrai(pg_temp.paie('62') = 199,
  'changer le reglage ne recalcule aucun montant deja ecrit');
UPDATE public.app_config SET value = to_jsonb(60) WHERE key = 'seance.duree_minutes_enfant';

-- ------------------------------------------------------------------
-- 7. Le calcul reste au serveur
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT bool_and(NOT has_function_privilege(r, f, 'EXECUTE'))
                       FROM unnest(ARRAY['authenticated', 'anon', 'public', 'agent_ro']) AS r,
                            unnest(ARRAY['private.presence_mesure(uuid,uuid,timestamptz,timestamptz)',
                                         'private.pai_fenetre(uuid)',
                                         'private.pai_minutes_enseignant(uuid)',
                                         'private.presence_temps_reel(uuid,uuid)',
                                         'private.pai_due_seance(uuid,public.politiques_commerciales)']) AS f)
  AND has_function_privilege('authenticated', 'public.presence_temps_seance(uuid,uuid)', 'EXECUTE'),
  'droits : les cinq fonctions privees fermees, la lecture gardee ouverte au seul authenticated');

\o
ROLLBACK;
