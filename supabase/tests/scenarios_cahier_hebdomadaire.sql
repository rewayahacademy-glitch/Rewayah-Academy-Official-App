-- CAHIER-HEBDOMADAIRE (31/10/2026) : un cahier par eleve et par semaine.
-- Migration 20261103000000. Une Classe d'enfants a Toronto, quatre seances :
--   s1 lundi 12/10 18:00 (e1, e2) ; s2 mercredi 14/10 18:00 (e1, e2, e3) ;
--   s3 dimanche 18/10 21:00 a Toronto, deja lundi 19/10 en UTC (e1, e2) ;
--   s4 lundi 19/10 18:00, semaine suivante (e1).
--   1. la semaine est celle du fuseau de la Classe : s3 est dans la semaine
--      de s1 (en UTC, elle serait dans la suivante) ;
--   2. sans cahier : une ligne a remplir par semaine, toutes les paies en
--      attente ;
--   3. un cahier sur s1 (e1, e2) couvre s1 et s3, pas s2 (e3 manque) ;
--   4. un cahier sur s2 pour e3 seul complete la semaine ;
--   5. la paie : en attente tant que le cahier de la semaine manque, montant
--      hors du total ;
--   6. la vue de l'enseignant et les droits.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

-- La politique par eleve present en vigueur pour octobre 2026.
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
  $$ SELECT ('c4000000-0000-4000-8000-0000000000' || p)::uuid $$;
-- Les seances a remplir de l'enseignante, triees.
CREATE FUNCTION pg_temp.a_remplir() RETURNS text LANGUAGE sql AS
  $$ SELECT coalesce(string_agg(right(r.session_id::text, 2), ',' ORDER BY r.ended_at), '')
       FROM public.mes_rapports_en_attente() r $$;
-- Les seances en attente dans le releve d'octobre.
CREATE FUNCTION pg_temp.en_attente() RETURNS text LANGUAGE sql AS
  $$ SELECT coalesce(string_agg(right(r.seance::text, 2), ',' ORDER BY r.debut), '')
       FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00') r
      WHERE r.en_attente AND r.seance::text LIKE 'c4000000%' $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.a_remplir() TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'ch-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','e1','e2','e3']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'CH', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','CH-ADM-01','admin','Direction'),
   ('b1','CH-ENS-01','teacher','Maryam'),
   ('e1','CH-ELV-01','student','Yasmine'),
   ('e2','CH-ELV-02','student','Nour'),
   ('e3','CH-ELV-03','student','Safa')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2','e3']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour CH', 1, 18, 'America/Toronto');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.s), pg_temp.u('b1'),
       (x.debut::timestamp AT TIME ZONE 'America/Toronto'),
       (x.debut::timestamp AT TIME ZONE 'America/Toronto') + interval '1 hour',
       'planned', pg_temp.u('c1')
  FROM (VALUES ('51','2026-10-12 18:00'), ('52','2026-10-14 18:00'),
               ('53','2026-10-18 21:00'), ('54','2026-10-19 18:00')) AS x(s, debut);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(x.s), pg_temp.u(x.e), 'student'::public.participant_role
  FROM (VALUES ('51','e1'),('51','e2'),('52','e1'),('52','e2'),('52','e3'),
               ('53','e1'),('53','e2'),('54','e1')) AS x(s, e);
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT sp.session_id, sp.profile_id, 'joined', s.started_at + interval '1 minute', 'livekit_webhook'
  FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
 WHERE sp.session_id::text LIKE 'c4000000%';

ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id::text LIKE 'c4000000%';
UPDATE public.sessions SET status = 'in_progress' WHERE id::text LIKE 'c4000000%';
UPDATE public.sessions s SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE id::text LIKE 'c4000000%';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

-- ------------------------------------------------------------------
-- 1. La semaine de la Classe
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  date_trunc('week', (SELECT started_at FROM public.sessions WHERE id = pg_temp.u('53')) AT TIME ZONE 'America/Toronto')
  = date_trunc('week', (SELECT started_at FROM public.sessions WHERE id = pg_temp.u('51')) AT TIME ZONE 'America/Toronto')
  AND date_trunc('week', (SELECT started_at FROM public.sessions WHERE id = pg_temp.u('53')) AT TIME ZONE 'UTC')
  <> date_trunc('week', (SELECT started_at FROM public.sessions WHERE id = pg_temp.u('51')) AT TIME ZONE 'UTC'),
  'fuseau : le dimanche soir a Toronto est dans la semaine du lundi 12/10, en UTC il serait dans la suivante');

-- ------------------------------------------------------------------
-- 2. Aucun cahier
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT private.cahier_semaine_couvert(pg_temp.u('51'))
  AND NOT private.cahier_semaine_couvert(pg_temp.u('53')),
  'sans cahier : la semaine n''est pas couverte');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.a_remplir() = '53,54',
  'a remplir : une ligne par semaine, la derniere seance (s3 pour la semaine du 12, s4)');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.en_attente() = '51,52,53,54',
  'paie : les quatre seances en attente tant que le cahier manque');
SELECT pg_temp.vrai((SELECT count(*) FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00') r
                      WHERE r.seance::text LIKE 'c4000000%' AND r.montant IS NOT NULL) = 0,
  'paie : aucun montant a verser tant que le cahier manque');

-- ------------------------------------------------------------------
-- 3. Un cahier sur s1 (e1, e2)
-- ------------------------------------------------------------------
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('51'), 'ch-s1', pg_catalog.jsonb_build_object('version', 1, 'eleves',
          pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1')),
                                       pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2')))),
        pg_temp.u('b1'));
SELECT pg_temp.vrai(private.cahier_semaine_couvert(pg_temp.u('51'))
  AND private.cahier_semaine_couvert(pg_temp.u('53'))
  AND NOT private.cahier_semaine_couvert(pg_temp.u('52'))
  AND NOT private.cahier_semaine_couvert(pg_temp.u('54')),
  'cahier de s1 : couvre s1 et s3 (memes eleves, meme semaine), pas s2 (e3 manque) ni s4 (autre semaine)');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.a_remplir() = '52,54', 'a remplir : s2 (e3 manque), s4');
SELECT pg_temp.vrai((SELECT cahier_semaine_depose AND NOT cahier_depose FROM public.mes_seances_enseignant_v
                      WHERE session_id = pg_temp.u('53')),
  'vue de l''enseignant : s3 a son cahier de la semaine sans cahier propre (plus de « Remplir le cahier »)');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.en_attente() = '52,54', 'paie : s1 et s3 liberees, s2 et s4 en attente');

-- ------------------------------------------------------------------
-- 4. Un cahier sur s2 pour e3 seul
-- ------------------------------------------------------------------
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('52'), 'ch-s2', pg_catalog.jsonb_build_object('version', 1, 'eleves',
          pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('student_id', pg_temp.u('e3')))),
        pg_temp.u('b1'));
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.a_remplir() = '54', 'a remplir : seule la semaine suivante reste');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. La paie
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.en_attente() = '54', 'paie : seule s4 attend son cahier');
SELECT pg_temp.vrai((SELECT montant IS NULL FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00')
                      WHERE seance = pg_temp.u('54'))
  AND EXISTS (SELECT 1 FROM public.tresorerie_mouvements m
               WHERE m.source_id = pg_temp.u('54')::text AND m.regle = 'remuneration_due'),
  'paie : s4 est due (ecrite en tresorerie) mais pas versee tant que le cahier manque');
SELECT pg_temp.vrai((SELECT montant FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00')
                      WHERE seance = pg_temp.u('52'))
                    = 3 * (private.fac_politique_au('2026-10-14')).taux_eleve_heure_enfant_mineur,
  'paie : s2 liberee, 3 eleves x 1 h x taux enfant');

-- ------------------------------------------------------------------
-- 6. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.cahier_semaine_couvert(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.cahier_semaine_depose(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.mes_rapports_en_attente()', 'EXECUTE'),
  'droits : la regle reste au serveur');
SELECT pg_temp.qui(pg_temp.u('e1'), 'student');
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  PERFORM public.cahier_semaine_depose(pg_temp.u('51'));
  RAISE EXCEPTION 'ROUGE : un eleve lit l''etat du cahier';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK un eleve ne lit pas l''etat du cahier';
END $$;
RESET ROLE;

\o
ROLLBACK;
