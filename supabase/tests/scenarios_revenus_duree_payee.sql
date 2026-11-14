-- REVENUS-DUREE-PAYEE (14/11/2026), migration 20261125300000_revenus_duree_payee.sql.
-- Rouge sans la migration (fonction absente), vert avec. Suppose
-- 20261124800000 et 20261124900000 (PAIE-FENETRE) installees.
--   1. duree payee = regle de pai_due_seance : duree due atteinte -> toute la
--      fenetre ; sinon les minutes connectees ;
--   2. les minutes connectees dans la fenetre sont distinctes (rien avant ni
--      apres la fenetre ; plusieurs passages additionnes) ;
--   3. garde de coherence : un montant qui ne redonne pas la duree -> null ;
--   4. acces : l'enseignant lit les siennes, pas celles d'un autre ; la
--      direction lit celles d'un enseignant designe ; eleve, anonyme refuses ;
--   3 bis. heures assurees sur la duree payee (270, pas 265) ; bf1_prestations
--      inchangee ;
--   5. droits.
-- Seances (mois en cours, enseignante Maryam, un eleve present) :
--   sA enfants planifiee 90 min, connectee 0-75 : fenetre 60, connectees 60, payees 60 ;
--   sB enfants 60 min, connectee 30 min (< 45) : payees 30, connectees 30 ;
--   sC adultes 90 min, connectee 0-100 : fenetre 90, connectees 90, payees 90 ;
--   sD enfants 60 min, connectee 0-20 puis 25-60 (deux passages) : 55 connectees, payees 60 ;
--   sE enfants 60 min, connectee 30 min, presence corrigee apres la paie : coherence rompue -> null.
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
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.mois() RETURNS date LANGUAGE sql AS
  $$ SELECT date_trunc('month', (now() AT TIME ZONE 'Europe/Paris')::date)::date $$;
-- Vrai quand l'appel leve le code SQLSTATE attendu.
CREATE FUNCTION pg_temp.refuse(p_sql text, p_code text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN false;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE = p_code;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.mois(),
  pg_temp.refuse(text, text) TO authenticated, anon;

INSERT INTO auth.users(id, email)
SELECT ('fd400000-0000-4000-8000-0000000000' || x)::uuid, 'rdp-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','e1','e2']) AS x;
INSERT INTO public.households(id, timezone) VALUES ('fd400000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT ('fd400000-0000-4000-8000-0000000000' || x.id)::uuid, x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN 'fd400000-0000-4000-8000-0000000000f1'::uuid END,
       x.prenom, 'RDP', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender
  FROM (VALUES
   ('a1','RDP-ADM-01','admin','Direction'),
   ('b1','RDP-ENS-01','teacher','Maryam'),
   ('b2','RDP-ENS-02','teacher','Amal'),
   ('e1','RDP-ELV-01','student','Yasmine'),
   ('e2','RDP-ELV-02','student','Aicha')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('fd400000-0000-4000-8000-0000000000e1', 'minor'::public.student_type, 'standard'::public.interface_mode),
 ('fd400000-0000-4000-8000-0000000000e2', 'autonomous'::public.student_type, 'standard'::public.interface_mode);
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 ('fd400000-0000-4000-8000-000000000c01','fd400000-0000-4000-8000-0000000000b1','enfant',5,'An-Nour RDP',1,9,'Europe/Paris'),
 ('fd400000-0000-4000-8000-000000000c02','fd400000-0000-4000-8000-0000000000b1','adulte',6,'Al-Huda RDP',3,20,'Europe/Paris');

-- (suffixe, groupe, minutes planifiees, eleve, passages de l'enseignante)
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT ('fd400000-0000-4000-8000-00000000050' || x.s)::uuid, 'fd400000-0000-4000-8000-0000000000b1',
       pg_temp.mois() + interval '10 days' + x.n * interval '3 hours',
       pg_temp.mois() + interval '10 days' + x.n * interval '3 hours' + x.duree * interval '1 minute',
       'planned', ('fd400000-0000-4000-8000-000000000c0' || x.g)::uuid
  FROM (VALUES ('1','1',90,1),('2','1',60,2),('3','2',90,3),('4','1',60,4),('5','1',60,5)) AS x(s, g, duree, n);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT ('fd400000-0000-4000-8000-00000000050' || x.s)::uuid, ('fd400000-0000-4000-8000-0000000000' || x.e)::uuid,
       'student'::public.participant_role
  FROM (VALUES ('1','e1'),('2','e1'),('3','e2'),('4','e1'),('5','e1')) AS x(s, e);
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, ('fd400000-0000-4000-8000-0000000000' || x.p)::uuid, x.t::public.session_event_type,
       s.started_at + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES
    ('1','e1','joined',1),
    ('2','e1','joined',1),
    ('3','e2','joined',1),
    ('4','e1','joined',1),
    ('5','e1','joined',1),
    ('1','b1','joined',0),('1','b1','left',75),
    ('2','b1','joined',0),('2','b1','left',30),
    ('3','b1','joined',0),('3','b1','left',100),
    ('4','b1','joined',0),('4','b1','left',20),('4','b1','joined',25),('4','b1','left',60),
    ('5','b1','joined',0),('5','b1','left',30)) AS x(s, p, t, m)
  JOIN public.sessions s ON s.id = ('fd400000-0000-4000-8000-00000000050' || x.s)::uuid;

ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id::text LIKE 'fd400000-0000-4000-8000-00000000050%';
UPDATE public.sessions SET status = 'in_progress' WHERE id::text LIKE 'fd400000-0000-4000-8000-00000000050%';
UPDATE public.sessions s
   SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE id::text LIKE 'fd400000-0000-4000-8000-00000000050%';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

CREATE FUNCTION pg_temp.paie(p_seance text) RETURNS bigint LANGUAGE sql AS
  $$ SELECT m.montant_minor FROM public.tresorerie_mouvements m
      WHERE m.source_type = 'prestation' AND m.source_id = 'fd400000-0000-4000-8000-00000000050' || p_seance
        AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree' $$;
-- Une entree du resultat.
CREATE FUNCTION pg_temp.ligne(p_r jsonb, p_s text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT x FROM jsonb_array_elements(p_r) x
      WHERE x ->> 'seanceId' = 'fd400000-0000-4000-8000-00000000050' || p_s $$;
GRANT EXECUTE ON FUNCTION pg_temp.paie(text), pg_temp.ligne(jsonb, text) TO authenticated;

-- Les montants ecrits par le serveur (taux enfants 1,99 ; adultes 1,57 USD).
SELECT pg_temp.vrai(pg_temp.paie('1') = 199 AND pg_temp.paie('2') = 100
                    AND pg_temp.paie('3') = 236 AND pg_temp.paie('4') = 199 AND pg_temp.paie('5') = 100,
  'paie ecrite : 1,99 (60 min) ; 1,00 (30 min) ; 2,36 (90 min adultes) ; 1,99 ; 1,00');

-- sE : la presence est corrigee APRES la paie (une seconde eleve presente) :
-- le montant ecrit (100) ne redonne plus la duree (200 pour 30 min a deux).
INSERT INTO public.session_participants(session_id, profile_id, role)
VALUES ('fd400000-0000-4000-8000-000000000505', 'fd400000-0000-4000-8000-0000000000e2', 'student');
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, 'fd400000-0000-4000-8000-0000000000e2', 'joined', s.started_at + interval '1 minute', 'livekit_webhook'
  FROM public.sessions s WHERE s.id = 'fd400000-0000-4000-8000-000000000505';

-- bf1_prestations ne change pas : ses minutes restent les minutes CONNECTEES
-- (60 + 30 + 90 + 55 + 30 = 265), c'est mes_revenus_enseignant qui les remplace.
CREATE TEMP TABLE bf AS SELECT sum(minutes)::int AS m FROM private.bf1_prestations(
  'fd400000-0000-4000-8000-0000000000b1', pg_temp.mois()::timestamptz - interval '1 day',
  pg_temp.mois()::timestamptz + interval '40 days');
GRANT SELECT ON bf TO authenticated;
SELECT pg_temp.vrai((SELECT m FROM bf) = 265, '0 : bf1_prestations inchangee, 265 minutes connectees');

SELECT pg_temp.qui('fd400000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
CREATE TEMP TABLE rdp AS SELECT public.mes_durees_payees_enseignant(NULL) AS j;
CREATE TEMP TABLE rv AS SELECT public.mes_revenus_enseignant(NULL) AS j;

-- 1. Duree payee
SELECT pg_temp.vrai((SELECT (pg_temp.ligne(j,'1') ->> 'minutesPayees')::int = 60
                        AND (pg_temp.ligne(j,'1') ->> 'fenetreMinutes')::int = 60 FROM rdp),
  '1 : enfants planifiee 90 min : fenetre 60, payee 60 (rien au-dela)');
SELECT pg_temp.vrai((SELECT (pg_temp.ligne(j,'2') ->> 'minutesPayees')::int = 30 FROM rdp),
  '1 : 30 min connectees, duree due non atteinte : payee 30');
SELECT pg_temp.vrai((SELECT (pg_temp.ligne(j,'3') ->> 'minutesPayees')::int = 90
                        AND (pg_temp.ligne(j,'3') ->> 'fenetreMinutes')::int = 90 FROM rdp),
  '1 : adultes : fenetre 90, payee 90');
SELECT pg_temp.vrai((SELECT (pg_temp.ligne(j,'4') ->> 'minutesPayees')::int = 60 FROM rdp),
  '1 : deux passages, duree due atteinte : toute la fenetre payee, 60');

-- 2. Minutes connectees dans la fenetre
SELECT pg_temp.vrai((SELECT (pg_temp.ligne(j,'1') ->> 'minutesConnectees')::int = 60
                        AND (pg_temp.ligne(j,'3') ->> 'minutesConnectees')::int = 90 FROM rdp),
  '2 : connectee 75 ou 100 min : seules les minutes DANS la fenetre comptent (60, 90)');
SELECT pg_temp.vrai((SELECT (pg_temp.ligne(j,'4') ->> 'minutesConnectees')::int = 55 FROM rdp),
  '2 : deux passages additionnes : 20 + 35 = 55, differente de la duree payee 60');

-- 3. Coherence
SELECT pg_temp.vrai((SELECT pg_temp.ligne(j,'5') -> 'minutesPayees' = 'null'::jsonb
                        AND (pg_temp.ligne(j,'5') ->> 'minutesConnectees')::int = 30 FROM rdp),
  '3 : montant ecrit qui ne redonne plus la duree : duree payee absente (jamais inventee), connectees gardees');

-- 3 bis. Heures assurees : la duree payee, plus les minutes connectees
-- sA 60, sB 30, sC 90, sD 60 (payees) ; sE non affirmable : 30 connectees
-- gardees. Total 270 (et non 265), une seance comptee faute de mieux.
SELECT pg_temp.vrai((SELECT (j #>> '{total,minutesAssurees}')::int = 270 FROM rv),
  '3 bis : heures assurees 270 min (duree payee) au lieu de 265 (connectees)');
SELECT pg_temp.vrai((SELECT (j ->> 'seancesSansDureePayee')::int = 1 FROM rv),
  '3 bis : une seance comptee au temps de connexion (duree payee non affirmable), dite');
SELECT pg_temp.vrai((SELECT (SELECT (x ->> 'minutesAssurees')::int FROM jsonb_array_elements(j -> 'classes') x
                              WHERE x ->> 'type' = 'enfants') = 180
                        AND (SELECT (x ->> 'minutesAssurees')::int FROM jsonb_array_elements(j -> 'classes') x
                              WHERE x ->> 'type' = 'adultes') = 90 FROM rv),
  '3 bis : minutes par Classe : enfants 60+30+60+30 = 180, adultes 90');
SELECT pg_temp.vrai((SELECT (j #>> '{total,minutesAssurees}')::int = (
    SELECT sum((x ->> 'minutesAssurees')::int) FROM jsonb_array_elements(j -> 'classes') x) FROM rv),
  '3 bis : le total vaut la somme des Classes');

-- 4. Acces
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.mes_durees_payees_enseignant(NULL, 'fd400000-0000-4000-8000-0000000000b2')$q$, '42501'),
  '4 : un enseignant ne lit pas les durees d un autre enseignant');
SELECT pg_temp.vrai((SELECT jsonb_array_length(public.mes_durees_payees_enseignant(NULL, 'fd400000-0000-4000-8000-0000000000b1')) = 5),
  '4 : il peut se designer lui-meme');
SELECT pg_temp.qui('fd400000-0000-4000-8000-0000000000b2', 'teacher');
SELECT pg_temp.vrai((SELECT public.mes_durees_payees_enseignant(NULL) = '[]'::jsonb),
  '4 : un autre enseignant ne voit rien des seances de Maryam');
SELECT pg_temp.qui('fd400000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.mes_durees_payees_enseignant(NULL, NULL)$q$, '22023'),
  '4 : la direction doit designer l enseignant');
SELECT pg_temp.vrai((SELECT jsonb_array_length(public.mes_durees_payees_enseignant(NULL, 'fd400000-0000-4000-8000-0000000000b1')) = 5
                        AND (pg_temp.ligne(public.mes_durees_payees_enseignant(NULL, 'fd400000-0000-4000-8000-0000000000b1'),'4') ->> 'minutesPayees')::int = 60),
  '4 : la direction lit l enseignant designe');
SELECT pg_temp.qui('fd400000-0000-4000-8000-0000000000e1', 'student');
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.mes_durees_payees_enseignant(NULL)$q$, '42501'),
  '4 : un eleve est refuse');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.refuse($q$SELECT public.mes_durees_payees_enseignant(NULL)$q$, '42501'),
  '4 : anonyme refuse (pas de droit EXECUTE)');
RESET ROLE;

-- 5. Droits
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.mes_durees_payees_enseignant(date,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.mes_durees_payees_enseignant(date,uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.mes_durees_payees_enseignant(date,uuid)', 'EXECUTE'),
  '5 : authenticated seul');

\o
ROLLBACK;
