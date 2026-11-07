-- CAHIER-C3 (06/11/2026) : le cahier de confirmation. Migration 20261110610000.
-- b1 titulaire de la Classe c3 ; b3 enseignant etranger ; e1, e2 eleves.
--   1. un cahier depose avec des objectifs a renforcer et « pret pour le
--      petit bilan » donne des lignes ; les vides, doublons et eleves hors
--      seance sont ecartes ;
--   2. un cahier corrige remplace le precedent dans la lecture ;
--   3. lecture : titulaire et direction oui ; etranger et eleve non ; droits.
-- Echoue sans la migration. Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

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

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('c3c30000-0000-4000-8000-0000000000' || p)::uuid $$;

CREATE FUNCTION pg_temp.lire(p_groupe uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  SELECT pg_catalog.string_agg(o.nature || ':' || coalesce(o.objectif, '-'), ',' ORDER BY o.nature, o.objectif)
    INTO v FROM public.observations_classe(p_groupe) o;
  RETURN coalesce(v, 'vide');
EXCEPTION WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.lire(uuid) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'c3-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b3','e1','e2','e9']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'C3', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','C3-ADM-01','admin','Direction'),
   ('b1','C3-ENS-01','teacher','Titulaire'),
   ('b3','C3-ENS-03','teacher','Etrangere'),
   ('e1','C3-ELV-01','student','Eleve un'),
   ('e2','C3-ELV-02','student','Eleve deux'),
   ('e9','C3-ELV-09','student','Hors seance')) AS x(id, mat, role, prenom);
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour C3', 1, 18, 'Europe/Paris');
-- s1 : seance tenue hier ; s5 et s6 : jeudi et vendredi 05-06/11 (avant la
-- coupure) ; s9 et s10 : lundi et mardi 09-10/11 (apres la coupure).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.s), pg_temp.u('b1'), x.debut::timestamptz, x.debut::timestamptz + interval '1 hour',
       'ended', pg_temp.u('c3')
  FROM (VALUES ('01', '2026-11-04 17:00+00'), ('05', '2026-11-05 17:00+00'), ('06', '2026-11-06 17:00+00'),
               ('09', '2026-11-09 17:00+00'), ('10', '2026-11-10 17:00+00')) AS x(s, debut);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(s), pg_temp.u(e), 'student'::public.participant_role
  FROM unnest(ARRAY['01','05','06','09','10']) AS s, unnest(ARRAY['e1','e2']) AS e;

-- ------------------------------------------------------------------
-- 1. Le cahier depose donne des lignes
-- ------------------------------------------------------------------
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('a7'), pg_temp.u('01'), 'c3-r1', pg_catalog.jsonb_build_object(
  'version', 1, 'position_reprise', 'Page 14', 'page_reprise', 14,
  'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1'), 'confirme', true,
      'objectifs_a_renforcer', pg_catalog.jsonb_build_array('Lit le tanwin', ' Lit le tanwin ', '', 'Lit la chadda'),
      'pret_bilan', true),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2'), 'confirme', true),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e9'), 'pret_bilan', true),
    pg_catalog.jsonb_build_object('student_id', 'pas-un-uuid', 'pret_bilan', true))),
  pg_temp.u('b1'));
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.cahier_observations WHERE lesson_report_id = pg_temp.u('a7')) = 3
  AND (SELECT pg_catalog.count(*) FROM public.cahier_observations WHERE student_id = pg_temp.u('e9')) = 0,
  'cahier : 2 objectifs a renforcer (vides et doublons ecartes) et 1 pret pour le bilan ; eleve hors seance ecarte');

SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('c3')) = 'a_renforcer:Lit la chadda,a_renforcer:Lit le tanwin,pret_bilan:-',
  'titulaire : lit les observations de sa Classe');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Un cahier corrige remplace le precedent
-- ------------------------------------------------------------------
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id, created_at)
VALUES (pg_temp.u('a8'), pg_temp.u('01'), 'c3-r2', pg_catalog.jsonb_build_object(
  'version', 1, 'position_reprise', 'Page 15',
  'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2'), 'objectifs_a_renforcer',
      pg_catalog.jsonb_build_array('Lit les voyelles longues')))),
  pg_temp.u('b1'), pg_catalog.now() + interval '1 minute');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('c3')) = 'a_renforcer:Lit les voyelles longues',
  'direction : seul le dernier cahier de la seance compte');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Refus et droits
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('c3')) = 'refus', 'enseignant etranger : lecture refusee');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lire(pg_temp.u('c3')) = 'refus', 'eleve : lecture refusee');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_table_privilege('authenticated', 'public.cahier_observations', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.cahier_observations', 'INSERT')
  AND NOT has_function_privilege('anon', 'public.observations_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.observations_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.cahier_c3_observations()', 'EXECUTE'),
  'droits : table fermee, lecture fermee a anon et agent_ro, declencheur prive');

\o
ROLLBACK;
