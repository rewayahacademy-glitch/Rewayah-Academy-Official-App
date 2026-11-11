-- CAHIER-C3, PAIE PAR SEANCE (07/11/2026). Migration 20261110620000.
-- Par defaut (coupure au 01/01/2100), rien ne change ; la coupure posee au
-- 07/11/2026 06:00 UTC dans la transaction du scenario : avant elle, le
-- cahier de la semaine couvre encore ; apres, chaque seance attend le sien.
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
-- 1. Coupure par defaut : aucun effet ; 2. coupure posee : avant, apres
-- ------------------------------------------------------------------
-- Le cahier de s6 et celui de s10 (memes eleves).
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
SELECT pg_temp.u(x.s), 'c3-' || x.s, pg_catalog.jsonb_build_object('version', 1, 'position_reprise', 'Page 20',
  'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1')),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2')))), pg_temp.u('b1')
  FROM (VALUES ('06'), ('10')) AS x(s);
-- Le scenario pose SA PROPRE coupure dans sa transaction : il ne depend jamais de la valeur
-- installee (garde-cap, 11/11/2026 : la coupure est active depuis 20261123600000).
CREATE OR REPLACE FUNCTION private.cahier_c3_coupure() RETURNS timestamptz
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $f$ SELECT '2100-01-01 00:00:00+00'::timestamptz $f$;
SELECT pg_temp.vrai(private.cahier_c3_coupure() = '2100-01-01 00:00:00+00'::timestamptz
  AND private.cahier_semaine_couvert(pg_temp.u('05'))
  AND private.cahier_semaine_couvert(pg_temp.u('09')),
  'coupure par defaut (2100) : rien ne change, la semaine couvre encore');
-- La coupure posee a l'installation (ici dans la transaction du scenario).
CREATE OR REPLACE FUNCTION private.cahier_c3_coupure() RETURNS timestamptz
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $f$ SELECT '2026-11-07 06:00:00+00'::timestamptz $f$;
SELECT pg_temp.vrai(private.cahier_semaine_couvert(pg_temp.u('05'))
  AND private.cahier_semaine_couvert(pg_temp.u('06')),
  'avant la coupure : le cahier de la semaine couvre encore la seance sans cahier (regle de stabilite 2)');
SELECT pg_temp.vrai(NOT private.cahier_semaine_couvert(pg_temp.u('09'))
  AND private.cahier_semaine_couvert(pg_temp.u('10')),
  'apres la coupure : la seance sans sa confirmation attend, celle qui l''a est couverte');

\o
ROLLBACK;
