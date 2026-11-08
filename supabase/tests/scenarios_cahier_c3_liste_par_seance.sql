-- CAHIER-C3, LISTE « CAHIERS A REMPLIR » PAR SEANCE (07/11/2026).
-- Migration 20261113000000 (apres 20261110620000).
--   * coupure par defaut (2100) : la liste reste HEBDOMADAIRE (une ligne par
--     Classe et par semaine), comme avant ;
--   * coupure posee : avant elle, toujours une ligne par semaine ; a partir
--     d'elle, UNE LIGNE PAR SEANCE non couverte ; deposer le cahier d'une
--     seance retire cette seule ligne ;
--   * EGALITE seance par seance (exigee par le garde-cap) : apres la coupure,
--     la liste = les seances « en attente » de private.pai_releve_seances ;
--   * mes_cahiers_echeances : echeance = fin + cahier.echeance_heures (24 h),
--     par_seance vrai apres la coupure seulement ;
--   * un autre enseignant ne voit rien ; anon ne peut pas appeler la RPC.
-- Dates fixes de novembre 2026, toutes passees (politique v2 en vigueur).
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

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('c3ab0000-0000-4000-8000-0000000000' || p)::uuid $$;

-- La liste de l'appelant, en identifiants courts tries.
CREATE FUNCTION pg_temp.liste() RETURNS text
LANGUAGE sql AS $$
  SELECT coalesce(pg_catalog.string_agg(pg_catalog.right(r.session_id::text, 2), ',' ORDER BY r.session_id), 'vide')
    FROM public.mes_rapports_en_attente() r
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.u(text), pg_temp.liste() TO authenticated, anon;

-- Dates FIXES, toutes passees : la remuneration n'a de regle qu'a partir de
-- la politique v2 (date d'effet 2026-11-01 ; avant, regle_remuneration_absente
-- et la paie attendrait la direction, pas le cahier). Repere : le lundi
-- 2026-11-09 00:00 UTC. Semaine A (avant la coupure) : 27 et 29/10.
-- Semaine B (a partir de la coupure, lundi 2026-11-02 00:00 UTC) : 03, 04 et
-- 05/11.
CREATE TEMP TABLE c3l_dates AS
SELECT '2026-11-09 00:00:00+00'::timestamptz AS lundi;
GRANT SELECT ON c3l_dates TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'c3l-' || x || '@test.invalid'
  FROM unnest(ARRAY['b1','b3','e1','e2']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'C3L', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('b1','C3L-ENS-01','teacher','Titulaire'),
   ('b3','C3L-ENS-03','teacher','Etrangere'),
   ('e1','C3L-ELV-01','student','Eleve un'),
   ('e2','C3L-ELV-02','student','Eleve deux')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour C3L', 1, 18, 'Europe/Paris');
-- Semaine A (avant la coupure) : 11 mardi, 12 jeudi. Semaine B (a partir de
-- la coupure) : 21 mardi, 22 mercredi, 23 jeudi. Toutes tenues, sans cahier.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.s), pg_temp.u('b1'), d.lundi + x.decalage, d.lundi + x.decalage + interval '1 hour',
       'planned', pg_temp.u('c3')
  FROM c3l_dates d,
       (VALUES ('11', interval '-13 days 7 hours'), ('12', interval '-11 days 7 hours'),
               ('21', interval '-6 days 7 hours'), ('22', interval '-5 days 7 hours'),
               ('23', interval '-4 days 7 hours')) AS x(s, decalage);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(s), pg_temp.u(e), 'student'::public.participant_role
  FROM unnest(ARRAY['11','12','21','22','23']) AS s, unnest(ARRAY['e1','e2']) AS e
ON CONFLICT DO NOTHING;
-- Presences reelles (eleves et enseignante connectes toute l'heure), puis la
-- seance menee jusqu'a « ended » : la remuneration due s'ecrit en tresorerie,
-- comme en production (meme mecanique que scenarios_cahier_hebdomadaire).
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT sp.session_id, sp.profile_id, 'joined', s.started_at + interval '1 minute', 'livekit_webhook'
  FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
 WHERE sp.session_id::text LIKE 'c3ab0000%';
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, pg_temp.u('b1'), x.t::public.session_event_type, s.started_at + x.m * interval '1 minute', 'livekit_webhook'
  FROM public.sessions s, (VALUES ('joined', 0), ('left', 60)) AS x(t, m)
 WHERE s.id::text LIKE 'c3ab0000%';
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id::text LIKE 'c3ab0000%';
UPDATE public.sessions SET status = 'in_progress' WHERE id::text LIKE 'c3ab0000%';
UPDATE public.sessions s SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE id::text LIKE 'c3ab0000%';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- 1. Forme et droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai((SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'cahier.echeance_heures') = 24,
  'reglage cahier.echeance_heures = 24');
SELECT pg_temp.vrai((SELECT p.provolatile FROM pg_catalog.pg_proc p
    WHERE p.oid = 'private.cahier_c3_coupure()'::pg_catalog.regprocedure) = 's',
  'coupure STABLE (aucun plan ne garde 2100 apres la bascule)');
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege('anon', 'public.mes_cahiers_echeances()', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.mes_cahiers_echeances()', 'EXECUTE'),
  'mes_cahiers_echeances : authenticated oui, anon non');

-- ------------------------------------------------------------------
-- 2. Coupure par defaut (2100) : la liste reste hebdomadaire
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.liste() = '12,23',
  'coupure 2100 : une ligne par Classe et par semaine (12 et 23), comme avant');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.mes_cahiers_echeances() WHERE par_seance),
  'coupure 2100 : aucune ligne par_seance');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. La coupure posee au lundi de la semaine B (dans la transaction)
-- ------------------------------------------------------------------
DO $coupure$
BEGIN
  EXECUTE pg_catalog.format(
    'CREATE OR REPLACE FUNCTION private.cahier_c3_coupure() RETURNS timestamptz '
    'LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '''' '
    'AS $f$ SELECT %L::timestamptz $f$',
    (SELECT lundi - interval '7 days' FROM c3l_dates));
END $coupure$;

SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.liste() = '12,21,22,23',
  'coupure posee : semaine A une ligne (12), semaine B chaque seance (21, 22, 23)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.string_agg(pg_catalog.right(e.session_id::text, 2) || ':' || e.par_seance, ',' ORDER BY e.session_id)
     FROM public.mes_cahiers_echeances() e) = '12:false,21:true,22:true,23:true',
  'mes_cahiers_echeances : par_seance vrai a partir de la coupure seulement');
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM public.mes_cahiers_echeances() e
    JOIN public.mes_rapports_en_attente() r USING (session_id)
   WHERE e.echeance <> r.ended_at + interval '24 hours'),
  'mes_cahiers_echeances : echeance = fin de seance + 24 h');
RESET ROLE;

-- La paie de la semaine B attend bien le CAHIER (remuneration due ecrite en
-- tresorerie, montant retenu), et non la direction : sans cela, l'egalite
-- ci-dessous ne prouverait rien.
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.tresorerie_mouvements m
    WHERE m.regle = 'remuneration_due'
      AND m.source_id IN (SELECT pg_temp.u(x)::text FROM unnest(ARRAY['21','22','23']) x)) = 3
  AND (SELECT count(*) FROM private.pai_releve_seances((SELECT lundi - interval '7 days' FROM c3l_dates),
                                                       (SELECT lundi FROM c3l_dates)) r
        WHERE r.seance::text LIKE 'c3ab0000%' AND r.en_attente AND r.montant IS NULL) = 3,
  'paie semaine B : trois remunerations dues, retenues faute de cahier');

-- EGALITE seance par seance (garde-cap) : apres la coupure, la liste de
-- l'enseignant = les seances en attente du releve de paie.
CREATE TEMP TABLE c3l_liste AS SELECT NULL::uuid AS session_id WITH NO DATA;
GRANT INSERT, SELECT ON c3l_liste TO authenticated;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO c3l_liste SELECT r.session_id FROM public.mes_rapports_en_attente() r;
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(l.session_id ORDER BY l.session_id) FROM c3l_liste l
    WHERE l.session_id IN (SELECT pg_temp.u(x) FROM unnest(ARRAY['21','22','23']) x))
  = (SELECT pg_catalog.array_agg(r.seance ORDER BY r.seance)
       FROM private.pai_releve_seances((SELECT lundi - interval '7 days' FROM c3l_dates),
                                       (SELECT lundi FROM c3l_dates)) r
      WHERE r.en_attente AND r.enseignant = pg_temp.u('b1')),
  'egalite : apres la coupure, la liste = les seances en attente de pai_releve_seances');

-- Deposer le cahier de 22 retire cette seule ligne (et libere sa paie).
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('22'), 'c3l-22', pg_catalog.jsonb_build_object('version', 1, 'position_reprise', 'Page 12',
  'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1')),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2')))), pg_temp.u('b1'));
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.liste() = '12,21,23',
  'cahier de 22 depose : seule sa ligne sort, 21 et 23 attendent toujours');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT NOT r.en_attente FROM private.pai_releve_seances((SELECT lundi - interval '7 days' FROM c3l_dates),
                                                            (SELECT lundi FROM c3l_dates)) r
    WHERE r.seance = pg_temp.u('22'))
  AND (SELECT r.en_attente FROM private.pai_releve_seances((SELECT lundi - interval '7 days' FROM c3l_dates),
                                                            (SELECT lundi FROM c3l_dates)) r
    WHERE r.seance = pg_temp.u('23')),
  'paie : 22 liberee, 23 toujours en attente (meme regle que la liste)');

-- Retouche 2 : une valeur non entiere dans la console ne casse pas la RPC,
-- l'echeance revient a fin + 24 h.
UPDATE public.app_config SET value = '"24h"'::jsonb WHERE key = 'cahier.echeance_heures';
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.bool_and(e.echeance = r.ended_at + interval '24 hours') AND pg_catalog.count(*) = 3
     FROM public.mes_cahiers_echeances() e
     JOIN public.mes_rapports_en_attente() r ON r.session_id = e.session_id),
  'reglage illisible ("24h") : la RPC repond, echeance = fin + 24 h');
RESET ROLE;
UPDATE public.app_config SET value = '24'::jsonb WHERE key = 'cahier.echeance_heures';

-- ------------------------------------------------------------------
-- 4. Un autre enseignant ne voit rien ; anon ne peut pas appeler
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.liste() = 'vide'
  AND NOT EXISTS (SELECT 1 FROM public.mes_cahiers_echeances()),
  'un autre enseignant : aucune ligne, aucune echeance');
RESET ROLE;
SET LOCAL ROLE anon;
DO $anon$
BEGIN
  PERFORM 1 FROM public.mes_cahiers_echeances();
  RAISE EXCEPTION 'ROUGE : anon appelle mes_cahiers_echeances';
EXCEPTION WHEN insufficient_privilege THEN
  PERFORM pg_temp.ok('anon : mes_cahiers_echeances refusee (42501)');
END $anon$;
RESET ROLE;

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 15 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 15 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'CAHIER-C3-LISTE : % controles verts', current_setting('test.r_n');
END $fin$;

\o
ROLLBACK;
