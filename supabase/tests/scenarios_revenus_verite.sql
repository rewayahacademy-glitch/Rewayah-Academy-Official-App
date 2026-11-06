-- REVENUS-VERITE (06/11/2026), migration 20261110200000_revenus_verite.sql.
-- Rouge sur main (aucune lecture par seance, sieges et fourchette encore
-- rendus, aucun jour de paie, aucun apercu par eleve present), vert avec la
-- migration.
--   1. mes_revenus_enseignant ne rend plus ni base, ni plafond, ni sieges ;
--   2. chaque seance du mois, et chaque eleve : present ou absent, et ce
--      qu'il a rapporte (la somme des parts vaut le montant ecrit) ;
--      seance sans present : 0 ; panne sans decision : en attente ;
--   3. le jour de paie : du 1er au 10 du mois suivant, puis le reglage de la
--      direction, verifie ;
--   4. l'apercu de la direction, par eleve present ;
--   5. droits.
-- Donnees du scenario FAC-E-02 (scenarios_fac_e_paie_par_eleve.sql),
-- prefixe fe3, plus une seance s5 de 30 minutes (part arrondie). Tout est
-- annule a la fin.
\o /dev/null
BEGIN;
-- Les notifications de seance (20261027120000) sont un declencheur differe :
-- immediat ici, sinon ALTER TABLE sessions refuse les evenements en attente.
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales
   SET date_effet = (date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date) - interval '1 month')::date
 WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales
   SET date_effet = date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
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

CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
-- La paie ecrite pour une seance (nul si rien n'est ecrit).
CREATE FUNCTION pg_temp.paie(p_seance text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT m.montant_minor FROM public.tresorerie_mouvements m
      WHERE m.source_type = 'prestation' AND m.source_id = 'fe300000-0000-4000-8000-00000000050' || p_seance
        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.mois()
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : une enseignante, une classe d'enfants (e1-e4), une classe
-- d'adultes (e5-e7), quatre seances dans le mois.
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT ('fe300000-0000-4000-8000-0000000000' || x)::uuid, 'rv1-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.households(id, timezone) VALUES ('fe300000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('fe300000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN 'fe300000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, 'RV1', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender
  FROM (VALUES
   ('a1','RV1-ADM-01','admin','Direction'),
   ('b1','RV1-ENS-01','teacher','Maryam'),
   ('e1','RV1-ELV-01','student','Yasmine'),
   ('e2','RV1-ELV-02','student','Nour'),
   ('e3','RV1-ELV-03','student','Safa'),
   ('e4','RV1-ELV-04','student','Hawa'),
   ('e5','RV1-ELV-05','student','Aicha'),
   ('e6','RV1-ELV-06','student','Khadija'),
   ('e7','RV1-ELV-07','student','Zeynab')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT ('fe300000-0000-4000-8000-0000000000' || x)::uuid,
       (CASE WHEN x IN ('e5','e6','e7') THEN 'autonomous' ELSE 'minor' END)::public.student_type,
       'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4','e5','e6','e7']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fe300000-0000-4000-8000-000000000c01','fe300000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour RV1',1,9,'Europe/Paris'),
 ('fe300000-0000-4000-8000-000000000c02','fe300000-0000-4000-8000-0000000000b1','adulte',6,'Al-Huda RV1',3,20,'Europe/Paris');

-- s1 enfants 60 min ; s2 adultes 90 min ; s3 enfants, personne ; s4 enfants, panne.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT ('fe300000-0000-4000-8000-00000000050' || x.s)::uuid, 'fe300000-0000-4000-8000-0000000000b1',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours',
       pg_temp.mois() + interval '10 days' + x.s::int * interval '3 hours' + x.duree * interval '1 minute',
       'planned', ('fe300000-0000-4000-8000-000000000c0' || x.g)::uuid
  FROM (VALUES ('1','1',60),('2','2',90),('3','1',60),('4','1',60)) AS x(s, g, duree);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT ('fe300000-0000-4000-8000-00000000050' || x.s)::uuid, ('fe300000-0000-4000-8000-0000000000' || x.e)::uuid,
       'student'::public.participant_role
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('1','e4'),
               ('2','e5'),('2','e6'),('2','e7'),
               ('3','e1'),('3','e2'),('4','e1')) AS x(s, e);
-- Arrivees mesurees par la salle : s1 e1, e2, e3 ; s2 e5, e6 ; s4 e1.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT ('fe300000-0000-4000-8000-00000000050' || x.s)::uuid, ('fe300000-0000-4000-8000-0000000000' || x.e)::uuid,
       'joined'::public.session_event_type, s.started_at + interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','e1'),('1','e2'),('1','e3'),('2','e5'),('2','e6'),('4','e1')) AS x(s, e)
  JOIN public.sessions s ON s.id = ('fe300000-0000-4000-8000-00000000050' || x.s)::uuid;
-- PRESENCE-MINUTES (20261102900000) : la duree payee est celle ou
-- l'enseignante etait connectee (s1 50 min, s2 60, s3 60 ; s4 en panne).
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, 'fe300000-0000-4000-8000-0000000000b1', x.t::public.session_event_type,
       s.started_at + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('1','joined',0),('1','left',50),('2','joined',0),('2','left',60),
               ('3','joined',0),('3','left',60)) AS x(s, t, m)
  JOIN public.sessions s ON s.id = ('fe300000-0000-4000-8000-00000000050' || x.s)::uuid;
-- Corrections de la direction : e3 excusee malgre son arrivee, e4 presente.
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par) VALUES
 ('fe300000-0000-4000-8000-000000000501','fe300000-0000-4000-8000-0000000000e3','excusee','absence prevenue','fe300000-0000-4000-8000-0000000000a1'),
 ('fe300000-0000-4000-8000-000000000501','fe300000-0000-4000-8000-0000000000e4','corrigee_manuel','camera en panne','fe300000-0000-4000-8000-0000000000a1');

-- Cloture : durees tenues fixees a la main (l'horodatage serveur est coupe le
-- temps du scenario), puis passage a « ended » qui declenche la paie.
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight'
 WHERE id::text LIKE 'fe300000-0000-4000-8000-00000000050%';
UPDATE public.sessions SET status = 'in_progress'
 WHERE id::text LIKE 'fe300000-0000-4000-8000-00000000050%';
UPDATE public.sessions s
   SET finance_started_at = s.started_at,
       finance_ended_at = s.started_at + x.tenues * interval '1 minute',
       status = x.fin::public.session_status
  FROM (VALUES ('1',50,'ended'),('2',60,'ended'),('3',60,'ended'),('4',20,'tech_failure')) AS x(s, tenues, fin)
 WHERE s.id = ('fe300000-0000-4000-8000-00000000050' || x.s)::uuid;
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------

-- s5 : enfants, 60 min prevues, 30 tenues (< 45) ; e1 et e2 presents :
-- 1,99 x 2 x 0,5 h = 1,99 USD, a partager en 1,00 + 0,99.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('fe300000-0000-4000-8000-000000000505', 'fe300000-0000-4000-8000-0000000000b1',
        pg_temp.mois() + interval '12 days', pg_temp.mois() + interval '12 days' + interval '60 minutes',
        'planned', 'fe300000-0000-4000-8000-000000000c01');
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT 'fe300000-0000-4000-8000-000000000505', ('fe300000-0000-4000-8000-0000000000' || x)::uuid, 'student'
  FROM unnest(ARRAY['e1','e2','e3']) AS x;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT 'fe300000-0000-4000-8000-000000000505', ('fe300000-0000-4000-8000-0000000000' || x.p)::uuid,
       x.t::public.session_event_type, pg_temp.mois() + interval '12 days' + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('b1','joined',0),('b1','left',30),('e1','joined',1),('e2','joined',1)) AS x(p, t, m);
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = 'fe300000-0000-4000-8000-000000000505';
UPDATE public.sessions SET status = 'in_progress' WHERE id = 'fe300000-0000-4000-8000-000000000505';
UPDATE public.sessions SET finance_started_at = started_at, finance_ended_at = started_at + interval '30 minutes',
       status = 'ended' WHERE id = 'fe300000-0000-4000-8000-000000000505';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- Le cahier de la semaine de la Classe d'adultes est depose (s2) ; celui de
-- la Classe d'enfants manque : le versement de s1 et s5 attend le cahier.
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES ('fe300000-0000-4000-8000-000000000502', 'rv1-cahier-s2',
        jsonb_build_object('version', 1, 'session_id', 'fe300000-0000-4000-8000-000000000502', 'eleves',
          jsonb_build_array(jsonb_build_object('student_id', 'fe300000-0000-4000-8000-0000000000e5', 'confirme', true),
                            jsonb_build_object('student_id', 'fe300000-0000-4000-8000-0000000000e6', 'confirme', true),
                            jsonb_build_object('student_id', 'fe300000-0000-4000-8000-0000000000e7', 'confirme', true))),
        'fe300000-0000-4000-8000-0000000000b1');

SELECT pg_temp.vrai(pg_temp.paie('1') = 597 AND pg_temp.paie('2') = 314 AND pg_temp.paie('5') = 199,
  'paie ecrite par le serveur : 5,97 ; 3,14 ; 1,99 USD');

-- Une seance et un eleve du resultat.
CREATE FUNCTION pg_temp.seance(p_r jsonb, p_s text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x FROM jsonb_array_elements(p_r -> 'seances') x
      WHERE x ->> 'seanceId' = 'fe300000-0000-4000-8000-00000000050' || p_s $$;
CREATE FUNCTION pg_temp.eleve(p_r jsonb, p_s text, p_prenom text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT e FROM jsonb_array_elements(pg_temp.seance(p_r, p_s) -> 'eleves') e
      WHERE e ->> 'prenom' = p_prenom $$;
GRANT EXECUTE ON FUNCTION pg_temp.seance(jsonb, text), pg_temp.eleve(jsonb, text, text) TO authenticated;

-- ------------------------------------------------------------------
-- 1. Ni base, ni plafond, ni sieges
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe300000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE rv AS SELECT public.mes_revenus_enseignant(NULL) AS j;
SELECT pg_temp.vrai((SELECT j::text FROM rv) !~ '(siegesEligibles|"base"|"plafond")',
  '1 : plus de base, de plafond ni de sieges eligibles');
SELECT pg_temp.vrai((SELECT j -> 'regle' FROM rv) = '{"parElevePresent": true}'::jsonb,
  '1 : la regle dit seulement : par eleve present');
SELECT pg_temp.vrai((SELECT j #>> '{totalEstime,mineur}' FROM rv) = '1110',
  '1 : total inchange, lu du serveur : 5,97 + 3,14 + 1,99 = 11,10 USD');

-- ------------------------------------------------------------------
-- 2. Par seance et par eleve
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT jsonb_array_length(j -> 'seances') FROM rv) = 5,
  '2 : les cinq seances tenues du mois, payees ou non');
SELECT pg_temp.vrai((SELECT pg_temp.seance(j, '1') #>> '{montant,mineur}' = '597'
                        AND (pg_temp.seance(j, '1') ->> 'minutes')::int = 50
                        AND pg_temp.seance(j, '1') ->> 'classe' = 'An-Nour RV1'
                        AND jsonb_array_length(pg_temp.seance(j, '1') -> 'eleves') = 4
                        AND pg_temp.seance(j, '1') ->> 'attente' = 'cahier' FROM rv),
  '2 : seance 1, 50 minutes tenues, 5,97 USD, quatre eleves ; versement en attente du cahier de la semaine');
SELECT pg_temp.vrai((SELECT pg_temp.seance(j, '2') -> 'attente' = 'null'::jsonb
                        AND pg_temp.seance(j, '2') #>> '{montant,mineur}' = '314' FROM rv),
  '2 : seance 2, cahier depose : 3,14 USD, rien en attente');
SELECT pg_temp.vrai((SELECT (pg_temp.eleve(j, '1', 'Yasmine') ->> 'present')::boolean
                        AND pg_temp.eleve(j, '1', 'Yasmine') #>> '{montant,mineur}' = '199'
                        AND (pg_temp.eleve(j, '1', 'Hawa') ->> 'present')::boolean
                        AND pg_temp.eleve(j, '1', 'Hawa') #>> '{montant,mineur}' = '199' FROM rv),
  '2 : un present (arrivee mesuree) et un present corrige par la direction : 1,99 USD chacun');
SELECT pg_temp.vrai((SELECT NOT (pg_temp.eleve(j, '1', 'Safa') ->> 'present')::boolean
                        AND pg_temp.eleve(j, '1', 'Safa') #>> '{montant,mineur}' = '0' FROM rv),
  '2 : une absente excusee : absente, 0');
SELECT pg_temp.vrai((SELECT NOT (pg_temp.eleve(j, '2', 'Zeynab') ->> 'present')::boolean
                        AND pg_temp.eleve(j, '2', 'Zeynab') #>> '{montant,mineur}' = '0'
                        AND pg_temp.eleve(j, '2', 'Aicha') #>> '{montant,mineur}' = '157' FROM rv),
  '2 : adultes : une absente a 0, une presente a 1,57 USD');
SELECT pg_temp.vrai((SELECT pg_temp.eleve(j, '5', 'Nour') #>> '{montant,mineur}' = '100'
                        AND pg_temp.eleve(j, '5', 'Yasmine') #>> '{montant,mineur}' = '99' FROM rv),
  '2 : 1,99 USD a deux : 1,00 + 0,99 (le centime au premier prenom)');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM rv, jsonb_array_elements(j -> 'seances') s
     WHERE s -> 'montant' <> 'null'::jsonb AND s -> 'montant' IS NOT NULL
       AND (s #>> '{montant,mineur}')::bigint <> (
         SELECT coalesce(sum((e #>> '{montant,mineur}')::bigint), 0)
           FROM jsonb_array_elements(s -> 'eleves') e)
       AND EXISTS (SELECT 1 FROM jsonb_array_elements(s -> 'eleves') e WHERE (e ->> 'present')::boolean)),
  '2 : pour chaque seance, la somme des parts vaut le montant ecrit');
SELECT pg_temp.vrai((SELECT pg_temp.seance(j, '3') #>> '{montant,mineur}' = '0'
                        AND pg_temp.seance(j, '3') -> 'attente' = 'null'::jsonb
                        AND NOT (pg_temp.eleve(j, '3', 'Nour') ->> 'present')::boolean FROM rv),
  '2 : seance sans eleve present : montree, 0, eleves absents');
SELECT pg_temp.vrai((SELECT pg_temp.seance(j, '4') -> 'montant' = 'null'::jsonb
                        AND pg_temp.seance(j, '4') ->> 'attente' = 'direction'
                        AND pg_temp.eleve(j, '4', 'Yasmine') -> 'montant' = 'null'::jsonb FROM rv),
  '2 : panne sans decision : en attente de la direction, aucun montant invente');

-- ------------------------------------------------------------------
-- 3. Le jour de paie
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT j -> 'versement' FROM rv) = jsonb_build_object(
    'du', to_char(pg_temp.mois() + interval '1 month', 'YYYY-MM-DD'),
    'au', to_char(pg_temp.mois() + interval '1 month' + interval '9 days', 'YYYY-MM-DD')),
  '3 : par defaut, du 1er au 10 du mois suivant');
RESET ROLE;
DO $reglage$
BEGIN
  BEGIN
    UPDATE public.app_config SET value = '{"jourDebut": 12, "jourFin": 3}' WHERE key = 'paie.fenetre_versement';
    RAISE EXCEPTION 'ROUGE : 3 : une fenetre a l''envers est acceptee';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    UPDATE public.app_config SET value = '{"jourDebut": 1, "jourFin": 31}' WHERE key = 'paie.fenetre_versement';
    RAISE EXCEPTION 'ROUGE : 3 : un 31 est accepte';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
END $reglage$;
UPDATE public.app_config SET value = '{"jourDebut": 3, "jourFin": 12}' WHERE key = 'paie.fenetre_versement';
SELECT pg_temp.qui('fe300000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.mes_revenus_enseignant(NULL) #>> '{versement,du}'
                      = to_char(pg_temp.mois() + interval '1 month' + interval '2 days', 'YYYY-MM-DD')
  AND public.mes_revenus_enseignant(NULL) #>> '{versement,au}'
                      = to_char(pg_temp.mois() + interval '1 month' + interval '11 days', 'YYYY-MM-DD'),
  '3 : le reglage de la direction est lu (du 3 au 12)');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. L'apercu de la direction
-- ------------------------------------------------------------------
SELECT pg_temp.qui('fe300000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.p', public.politique_commerciale_active()::text, true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.apercu_paie_enseignant(current_setting('test.p')::jsonb, 'enfants', 3)
    @> '{"presents": 3, "tauxEleveHeure": {"mineur": 199}, "montantHeure": {"mineur": 597}, "montantAbsent": {"mineur": 0}}'::jsonb,
  '4 : enfants, 3 presents : 1,99 par eleve present, 5,97 USD l''heure, 0 pour un absent');
SELECT pg_temp.vrai(public.apercu_paie_enseignant(current_setting('test.p')::jsonb, 'adultes', 2)
    @> '{"presents": 2, "tauxEleveHeure": {"mineur": 157}, "montantHeure": {"mineur": 314}}'::jsonb,
  '4 : adultes, 2 presents : 3,14 USD l''heure');
DO $bornes$
BEGIN
  BEGIN
    PERFORM public.apercu_paie_enseignant(current_setting('test.p')::jsonb, 'enfants', 99);
    RAISE EXCEPTION 'ROUGE : 4 : plus de presents que de places';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
END $bornes$;
RESET ROLE;
SELECT pg_temp.qui('fe300000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
DO $refus$
BEGIN
  BEGIN
    PERFORM public.apercu_paie_enseignant(current_setting('test.p')::jsonb, 'enfants', 1);
    RAISE EXCEPTION 'ROUGE : 4 : un enseignant lit l''apercu de la direction';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $refus$;
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.apercu_paie_enseignant(jsonb,text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.pai_due_seance(uuid,public.politiques_commerciales)', 'EXECUTE'),
  '5 : le calcul reste au serveur, anon n''entre pas');

\o
ROLLBACK;
