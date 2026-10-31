-- CAHIER-EXCEPTION-PRESENCE (31/10/2026) : l'exception du cahier corrige la
-- presence calculee. Migration 20261103200000. Une seance d'enfants de 60
-- minutes, tenue en entier, quatre eleves du meme foyer :
--   e1 : jamais connecte (absente), l'enseignante signale une exception ;
--   e2 : excusee par la direction avant le cahier, exception aussi signalee ;
--   e3 : connectee toute l'heure, pas d'exception ;
--   e4 : n'est pas inscrit a la seance, une ligne a son nom dans le cahier.
--   1. avant : e1 absente, non payee ;
--   2. le cahier de l'enseignante applique l'exception de e1 : corrigee_manuel,
--      motif, auteur, presente, payee, journal ; e2 reste excusee ; e4 ignore ;
--   3. un cahier corrige rafraichit le motif, sans doublon ;
--   4. garde : la direction ne depose pas une exception au nom d'une autre ;
--      un enseignant etranger est refuse ; un cahier sans exception passe
--      sans rien ecrire ;
--   5. droits : la fonction du declencheur reste fermee.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales SET date_effet = '2026-09-01' WHERE version = 'v1.0.0';
UPDATE public.politiques_commerciales SET date_effet = '2026-10-01' WHERE version = 'v2.0.0';
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

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('c5000000-0000-4000-8000-0000000000' || p)::uuid $$;
CREATE FUNCTION pg_temp.statut(p text) RETURNS text LANGUAGE sql AS
  $$ SELECT t.statut FROM private.presence_temps_reel(pg_temp.u('51'), pg_temp.u(p)) t $$;
-- Un cahier : une ligne par eleve, motif facultatif.
CREATE FUNCTION pg_temp.cahier(p_eleves jsonb) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT pg_catalog.jsonb_build_object('version', 1, 'session_id', pg_temp.u('51'), 'eleves', p_eleves) $$;
CREATE FUNCTION pg_temp.ligne(p text, p_motif text DEFAULT NULL) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
              'student_id', pg_temp.u(p), 'confirme', p_motif IS NULL, 'motif_exception', p_motif)) $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.cahier(jsonb), pg_temp.ligne(text, text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'cx-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','e1','e2','e3','e4']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'CX', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','CX-ADM-01','admin','Direction'),
   ('b1','CX-ENS-01','teacher','Maryam'),
   ('b2','CX-ENS-02','teacher','Khadija'),
   ('e1','CX-ELV-01','student','Yasmine'),
   ('e2','CX-ELV-02','student','Nour'),
   ('e3','CX-ELV-03','student','Safa'),
   ('e4','CX-ELV-04','student','Amina')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3','e4']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour CX', 1, 18, 'America/Toronto');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id) VALUES
 (pg_temp.u('51'), pg_temp.u('b1'), '2026-10-12 22:00+00', '2026-10-12 23:00+00', 'planned', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u('51'), pg_temp.u(x), 'student'::public.participant_role
  FROM unnest(ARRAY['e1','e2','e3']) AS x;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT pg_temp.u('51'), pg_temp.u(x.p), x.t::public.session_event_type,
       '2026-10-12 22:00+00'::timestamptz + x.m * interval '1 minute', 'livekit_webhook'
  FROM (VALUES ('b1','joined',0), ('b1','left',60), ('e3','joined',0), ('e3','left',60)) AS x(p, t, m);

ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = pg_temp.u('51');
UPDATE public.sessions SET status = 'in_progress' WHERE id = pg_temp.u('51');
UPDATE public.sessions s SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE id = pg_temp.u('51');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- La direction a deja excuse e2.
INSERT INTO public.session_presence_override(session_id, profile_id, etat, motif, decide_par)
VALUES (pg_temp.u('51'), pg_temp.u('e2'), 'excusee', 'absence prevenue', pg_temp.u('a1'));

-- ------------------------------------------------------------------
-- 1. Avant le cahier
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.statut('e1') = 'absente' AND pg_temp.statut('e2') = 'excusee'
  AND pg_temp.statut('e3') = 'presente',
  'avant : e1 absente, e2 excusee, e3 presente');
SELECT pg_temp.vrai(private.pai_eleves_presents(pg_temp.u('51')) = 1, 'avant : un seul eleve paye (e3)');

-- ------------------------------------------------------------------
-- 2. Le cahier de l'enseignante
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('51'), 'cx-1', pg_temp.cahier(pg_catalog.jsonb_build_array(
          pg_temp.ligne('e1', 'Connexion coupée, présente en audio'),
          pg_temp.ligne('e2', 'Présente'),
          pg_temp.ligne('e3'),
          pg_temp.ligne('e4', 'Hors seance'))),
        pg_temp.u('b1'));
RESET ROLE;

SELECT pg_temp.vrai((SELECT etat = 'corrigee_manuel' AND motif = 'Connexion coupée, présente en audio'
                            AND decide_par = pg_temp.u('b1')
                       FROM public.session_presence_override
                      WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e1')),
  'e1 : exception appliquee (corrigee_manuel, motif, auteur)');
SELECT pg_temp.vrai(pg_temp.statut('e1') = 'presente', 'e1 : presente au calcul du serveur');
SELECT pg_temp.vrai((SELECT etat = 'excusee' AND motif = 'absence prevenue' AND decide_par = pg_temp.u('a1')
                       FROM public.session_presence_override
                      WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e2')),
  'e2 : la decision de la direction n''est pas ecrasee');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.session_presence_override
                                 WHERE session_id = pg_temp.u('51') AND profile_id IN (pg_temp.u('e3'), pg_temp.u('e4'))),
  'e3 sans exception, e4 non inscrit : rien d''ecrit');
SELECT pg_temp.vrai(private.pai_eleves_presents(pg_temp.u('51')) = 2, 'paie : e1 et e3 payes, e2 excusee non');
SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.audit_logs
                      WHERE action = 'presence_exception_cahier'
                        AND row_id = pg_temp.u('51')::text || ':' || pg_temp.u('e1')::text
                        AND actor = pg_temp.u('b1')),
  'journal : une ligne presence_exception_cahier pour e1, auteur l''enseignante');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.audit_logs
                                 WHERE action = 'presence_exception_cahier'
                                   AND row_id LIKE '%' || pg_temp.u('e2')::text),
  'journal : rien pour e2, decision non touchee');

-- La famille lit la presence corrigee.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT presence_temps = 'presente' FROM public.presence_seance_v
                      WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e1')),
  'lecture : l''eleve voit sa presence corrigee');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Le cahier corrige
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('51'), 'cx-2', pg_temp.cahier(pg_catalog.jsonb_build_array(
          pg_temp.ligne('e1', 'Présente, caméra en panne'), pg_temp.ligne('e3'))),
        pg_temp.u('b1'));
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) = 1 AND min(motif) = 'Présente, caméra en panne'
                       FROM public.session_presence_override
                      WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e1')),
  'correction : une seule ligne, motif rafraichi');

-- ------------------------------------------------------------------
-- 4. Gardes
-- ------------------------------------------------------------------
-- La direction ne depose pas une exception au nom de l'enseignante.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
  VALUES (pg_temp.u('51'), 'cx-3', pg_temp.cahier(pg_catalog.jsonb_build_array(pg_temp.ligne('e3', 'x'))),
          pg_temp.u('b1'));
  RAISE EXCEPTION 'ROUGE : exception deposee au nom d''une autre';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK exception au nom d''une autre refusee';
END $$;
RESET ROLE;

-- Un enseignant etranger a la seance.
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
  VALUES (pg_temp.u('51'), 'cx-4', pg_temp.cahier(pg_catalog.jsonb_build_array(pg_temp.ligne('e3', 'x'))),
          pg_temp.u('b2'));
  RAISE EXCEPTION 'ROUGE : un enseignant etranger depose une exception';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK enseignant etranger refuse';
END $$;
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.session_presence_override
                                 WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e3')),
  'gardes : e3 toujours sans exception');

-- La direction depose en son nom : l'exception passe.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('51'), 'cx-5', pg_temp.cahier(pg_catalog.jsonb_build_array(pg_temp.ligne('e3', 'Contrôle'))),
        pg_temp.u('a1'));
RESET ROLE;
SELECT pg_temp.vrai((SELECT decide_par = pg_temp.u('a1') FROM public.session_presence_override
                      WHERE session_id = pg_temp.u('51') AND profile_id = pg_temp.u('e3')),
  'direction : son exception s''applique a son nom');

-- Un cahier sans exception n'ecrit rien et ne demande rien.
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('51'), 'cx-6', pg_temp.cahier(pg_catalog.jsonb_build_array(pg_temp.ligne('e1'))),
        pg_temp.u('b1'));
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) = 3 FROM public.session_presence_override
                      WHERE session_id = pg_temp.u('51')),
  'sans exception : rien d''ecrit, rien de retire (limite : aucune suppression)');

-- ------------------------------------------------------------------
-- 5. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'private.cahier_appliquer_exceptions()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.cahier_appliquer_exceptions()', 'EXECUTE'),
  'droits : la fonction du declencheur reste fermee');

\o
SELECT 'scenarios_cahier_exception_presence : OK' AS resultat;
ROLLBACK;
