-- REVENUS (07/11/2026), migration 20261110220000_revenus_presence.sql.
-- Rouge sans la migration (ni 'presence' ni 'payable'), vert avec.
--   1. par eleve, 'presence' : 'presente', 'partielle' ou 'absente' ; un
--      eleve present en partie est paye comme un present ('present' vrai,
--      sa part du montant) ; une absente excusee se dit 'absente' ;
--   2. par seance, 'payable' : seance terminee et au moins un eleve present
--      ou present en partie (meme quand la direction doit encore trancher le
--      montant) ; faux pour une seance sans aucun present ;
--   2 bis. 'totalARecevoir' : seances payables hors attentes (cahier ou
--      direction) ; 'totalAttenteCahier' a part ; par Classe,
--      'montantARecevoir', et la somme des Classes vaut le total ;
--   3. rien d'autre ne change : 'present' reste rendu (regle B6), les
--      montants restent ceux ecrits par le serveur, et le total vaut la
--      somme des seances ;
--   4. droits.
-- Fixtures de scenarios_revenus_verite.sql (prefixe fe3, seances s1 a s5),
-- plus une seance s6 : enfants, 60 minutes tenues, Yasmine 9 minutes
-- (present en partie, sous le seuil de 50 %), Nour toute la seance, Safa
-- absente. Tout est annule a la fin.
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


-- s6 : enfants, 60 min prevues et tenues ; Yasmine (e1) arrive a 1 min et
-- part a 10 (9 min < 50 % : present en partie), Nour (e2) reste, Safa (e3)
-- ne vient pas. 1,99 x 2 x 1 h = 3,98 USD : 1,99 chacune.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('fe300000-0000-4000-8000-000000000506', 'fe300000-0000-4000-8000-0000000000b1',
        pg_temp.mois() + interval '14 days', pg_temp.mois() + interval '14 days' + interval '60 minutes',
        'planned', 'fe300000-0000-4000-8000-000000000c01');
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT 'fe300000-0000-4000-8000-000000000506', ('fe300000-0000-4000-8000-0000000000' || x)::uuid, 'student'
  FROM unnest(ARRAY['e1','e2','e3']) AS x;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT 'fe300000-0000-4000-8000-000000000506', ('fe300000-0000-4000-8000-0000000000' || x.p)::uuid,
       x.t::public.session_event_type, pg_temp.mois() + interval '14 days' + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('b1','joined',0),('b1','left',60),('e1','joined',1),('e1','left',10),('e2','joined',1)) AS x(p, t, m);
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = 'fe300000-0000-4000-8000-000000000506';
UPDATE public.sessions SET status = 'in_progress' WHERE id = 'fe300000-0000-4000-8000-000000000506';
UPDATE public.sessions SET finance_started_at = started_at, finance_ended_at = started_at + interval '60 minutes',
       status = 'ended' WHERE id = 'fe300000-0000-4000-8000-000000000506';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

SELECT pg_temp.vrai(pg_temp.paie('6') = 398,
  'paie ecrite par le serveur pour s6 : 3,98 USD (le present en partie compte)');

-- Une seance et un eleve du resultat.
CREATE FUNCTION pg_temp.seance(p_r jsonb, p_s text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x FROM jsonb_array_elements(p_r -> 'seances') x
      WHERE x ->> 'seanceId' = 'fe300000-0000-4000-8000-00000000050' || p_s $$;
CREATE FUNCTION pg_temp.eleve(p_r jsonb, p_s text, p_prenom text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT e FROM jsonb_array_elements(pg_temp.seance(p_r, p_s) -> 'eleves') e
      WHERE e ->> 'prenom' = p_prenom $$;
GRANT EXECUTE ON FUNCTION pg_temp.seance(jsonb, text), pg_temp.eleve(jsonb, text, text) TO authenticated;

SELECT pg_temp.qui('fe300000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE rv AS SELECT public.mes_revenus_enseignant(NULL) AS j;

-- ------------------------------------------------------------------
-- 1. Par eleve : presence
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT pg_temp.eleve(j, '6', 'Yasmine') ->> 'presence' = 'partielle'
                        AND (pg_temp.eleve(j, '6', 'Yasmine') ->> 'present')::boolean
                        AND pg_temp.eleve(j, '6', 'Yasmine') #>> '{montant,mineur}' = '199' FROM rv),
  '1 : present en partie : presence partielle, present, paye 1,99 USD comme un present');
SELECT pg_temp.vrai((SELECT pg_temp.eleve(j, '6', 'Nour') ->> 'presence' = 'presente'
                        AND pg_temp.eleve(j, '6', 'Nour') #>> '{montant,mineur}' = '199' FROM rv),
  '1 : presente toute la seance : presence presente, 1,99 USD');
SELECT pg_temp.vrai((SELECT pg_temp.eleve(j, '6', 'Safa') ->> 'presence' = 'absente'
                        AND NOT (pg_temp.eleve(j, '6', 'Safa') ->> 'present')::boolean
                        AND pg_temp.eleve(j, '6', 'Safa') #>> '{montant,mineur}' = '0' FROM rv),
  '1 : absente : presence absente, 0');
SELECT pg_temp.vrai((SELECT pg_temp.eleve(j, '1', 'Safa') ->> 'presence' = 'absente'
                        AND pg_temp.eleve(j, '1', 'Hawa') ->> 'presence' = 'presente' FROM rv),
  '1 : corrections de la direction : excusee dite absente, corrigee dite presente');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM rv, jsonb_array_elements(j -> 'seances') s, jsonb_array_elements(s -> 'eleves') e
     WHERE e ->> 'presence' IS NULL
        OR (e ->> 'present')::boolean IS DISTINCT FROM (e ->> 'presence' IN ('presente', 'partielle'))),
  '1 : chaque eleve a une presence, et present vaut presence presente ou partielle');

-- ------------------------------------------------------------------
-- 2. Par seance : payable
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT (pg_temp.seance(j, '6') ->> 'payable')::boolean
                        AND (pg_temp.seance(j, '1') ->> 'payable')::boolean FROM rv),
  '2 : une seance avec un present (ou present en partie) est payable');
SELECT pg_temp.vrai((SELECT NOT (pg_temp.seance(j, '3') ->> 'payable')::boolean
                        AND pg_temp.seance(j, '3') #>> '{montant,mineur}' = '0' FROM rv),
  '2 : seance sans aucun present : non payable (montant 0, que l ecran ne montre pas)');
SELECT pg_temp.vrai((SELECT (pg_temp.seance(j, '4') ->> 'payable')::boolean
                        AND pg_temp.seance(j, '4') -> 'montant' = 'null'::jsonb
                        AND pg_temp.seance(j, '4') ->> 'attente' = 'direction' FROM rv),
  '2 : panne avec un present : payable, montant encore a trancher par la direction');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM rv, jsonb_array_elements(j -> 'seances') s
     WHERE (s ->> 'payable')::boolean IS DISTINCT FROM EXISTS (
             SELECT 1 FROM jsonb_array_elements(s -> 'eleves') e WHERE (e ->> 'present')::boolean)),
  '2 : payable vaut, pour chaque seance, au moins un eleve paye');

-- ------------------------------------------------------------------
-- 2 bis. A recevoir, en attente du cahier
-- ------------------------------------------------------------------
-- s2 (adultes, cahier depose) seule est a recevoir : 3,14 USD. Le cahier des
-- enfants manque : s1 (5,97), s5 (1,99) et s6 (3,98) attendent, 11,94 USD.
-- s4 (panne) attend la direction, sans montant ; s3 n'est pas payable.
SELECT pg_temp.vrai((SELECT j #>> '{totalARecevoir,mineur}' = '314'
                        AND j #>> '{totalAttenteCahier,mineur}' = '1194' FROM rv),
  '2 bis : a recevoir 3,14 USD (hors attentes) ; en attente du cahier 11,94 USD, a part');
SELECT pg_temp.vrai((SELECT (SELECT x #>> '{montantARecevoir,mineur}' FROM jsonb_array_elements(j -> 'classes') x
                              WHERE x ->> 'classe' = 'Al-Huda RV1') = '314'
                        AND (SELECT x #>> '{montantARecevoir,mineur}' FROM jsonb_array_elements(j -> 'classes') x
                              WHERE x ->> 'classe' = 'An-Nour RV1') = '0' FROM rv),
  '2 bis : par Classe : adultes 3,14 USD, enfants 0 (tout attend le cahier)');
SELECT pg_temp.vrai((SELECT (j #>> '{totalARecevoir,mineur}')::bigint = (
    SELECT sum((x #>> '{montantARecevoir,mineur}')::bigint) FROM jsonb_array_elements(j -> 'classes') x) FROM rv),
  '2 bis : la somme des Classes vaut le total a recevoir');
SELECT pg_temp.vrai((SELECT (j #>> '{totalARecevoir,mineur}')::bigint + (j #>> '{totalAttenteCahier,mineur}')::bigint
                          = (j #>> '{totalEstime,mineur}')::bigint FROM rv),
  '2 bis : a recevoir + en attente du cahier = total estime (la panne et s3 sans montant)');

-- ------------------------------------------------------------------
-- 3. Rien d'autre ne change
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT j #>> '{totalEstime,mineur}' FROM rv) = '1508',
  '3 : total lu du serveur : 11,10 + 3,98 = 15,08 USD');
SELECT pg_temp.vrai((SELECT (j #>> '{totalEstime,mineur}')::bigint = (
    SELECT sum(coalesce((s #>> '{montant,mineur}')::bigint, 0)) FROM jsonb_array_elements(j -> 'seances') s) FROM rv),
  '3 : le total vaut la somme des seances');
SELECT pg_temp.vrai((SELECT pg_temp.eleve(j, '5', 'Nour') #>> '{montant,mineur}' = '100'
                        AND pg_temp.eleve(j, '5', 'Yasmine') #>> '{montant,mineur}' = '99' FROM rv),
  '3 : parts inchangees : 1,99 USD a deux, 1,00 + 0,99');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.mes_revenus_enseignant(date)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE'),
  '4 : authenticated seul, le calcul reste au serveur');

\o
ROLLBACK;
