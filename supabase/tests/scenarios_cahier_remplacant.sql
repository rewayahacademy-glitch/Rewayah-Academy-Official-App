-- CAHIER-REMPLACANT (31/10/2026) : le remplacant depose le cahier de la
-- seance qui lui est confiee. Migration 20261103300000.
-- Une Classe d'enfants a Toronto, titulaire b1, trois seances :
--   s61 lundi 12/10 18:00 (e1, e2), tenue par b1 ;
--   s62 mercredi 14/10 18:00 (e1, e2), meme semaine, remplacee par b2
--       (absence declaree puis remplacement pris) ;
--   s63 lundi 19/10 18:00 (e1), semaine suivante, non remplacee.
-- b3 est un enseignant etranger a la Classe ; a1 la direction.
--   1. avant tout cahier : chacun voit sa seance a remplir (semaine mixte) ;
--   2. le titulaire ecarte : pas de brouillon, depot refuse sur s62 ;
--   3. un enseignant etranger : refuse partout, ne lit rien ;
--   4. le remplacant : brouillon, depot reussi sur s62 ;
--   5. le titulaire lit ce cahier ; la semaine mixte est couverte pour les
--      deux, la paie de s62 va au remplacant et n'est plus en attente ;
--   6. s63 non remplacee ne change pas : b1 depose, b2 refuse et ne lit pas ;
--   7. la direction depose toujours, sur la seance remplacee comme ailleurs.
-- Echoue sans la migration (premier ROUGE : le remplacant ne voit pas s62).
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

-- La politique par eleve present en vigueur pour octobre 2026 (meme reglage
-- que scenarios_cahier_hebdomadaire).
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
-- Les seances a remplir de l'appelant, triees.
CREATE FUNCTION pg_temp.a_remplir() RETURNS text LANGUAGE sql AS
  $$ SELECT coalesce(string_agg(right(r.session_id::text, 2), ',' ORDER BY r.ended_at), '')
       FROM public.mes_rapports_en_attente() r $$;
-- Le brouillon est-il servi a l'appelant ? (refus = faux, tout autre echec remonte)
CREATE FUNCTION pg_temp.brouillon_ok(p_seance uuid) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  RETURN public.brouillon_cahier(p_seance) IS NOT NULL;
EXCEPTION WHEN insufficient_privilege THEN
  RETURN false;
END $$;
-- Deposer un cahier (e1, e2) ; vrai si accepte, faux si la RLS refuse.
CREATE FUNCTION pg_temp.deposer(p_seance uuid, p_cle text, p_auteur uuid) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
  VALUES (p_seance, p_cle, pg_catalog.jsonb_build_object('version', 1, 'eleves',
            pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1')),
                                         pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2')))),
          p_auteur);
  RETURN true;
EXCEPTION WHEN insufficient_privilege THEN
  RETURN false;
END $$;
-- Les cahiers lisibles par l'appelant sur une seance.
CREATE FUNCTION pg_temp.lus(p_seance uuid) RETURNS integer LANGUAGE sql AS
  $$ SELECT count(*)::integer FROM public.lesson_reports WHERE session_id = p_seance $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.a_remplir(), pg_temp.brouillon_ok(uuid), pg_temp.deposer(uuid, text, uuid),
  pg_temp.lus(uuid) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'cr-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','b3','e1','e2']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'CR', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','CR-ADM-01','admin','Direction'),
   ('b1','CR-ENS-01','teacher','Titulaire'),
   ('b2','CR-ENS-02','teacher','Remplacante'),
   ('b3','CR-ENS-03','teacher','Etrangere'),
   ('e1','CR-ELV-01','student','Eleve un'),
   ('e2','CR-ELV-02','student','Eleve deux')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode
  FROM unnest(ARRAY['e1','e2']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour CR', 1, 18, 'America/Toronto');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
SELECT pg_temp.u(x.s), pg_temp.u('b1'),
       (x.debut::timestamp AT TIME ZONE 'America/Toronto'),
       (x.debut::timestamp AT TIME ZONE 'America/Toronto') + interval '1 hour',
       'planned', pg_temp.u('c1')
  FROM (VALUES ('61','2026-10-12 18:00'), ('62','2026-10-14 18:00'),
               ('63','2026-10-19 18:00')) AS x(s, debut);
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u(x.s), pg_temp.u(x.e), 'student'::public.participant_role
  FROM (VALUES ('61','e1'),('61','e2'),('62','e1'),('62','e2'),('63','e1')) AS x(s, e);

-- s62 : absence declaree par la titulaire, puis remplacement pris par b2.
INSERT INTO public.remplacements_seance
  (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, cree_le)
VALUES
  (pg_temp.u('62'), 'absence_declaree', pg_temp.u('b1'), NULL, pg_temp.u('b1'),
   pg_temp.u('91'), pg_catalog.clock_timestamp()),
  (pg_temp.u('62'), 'remplacement_pris', pg_temp.u('b1'), pg_temp.u('b2'), pg_temp.u('b2'),
   pg_temp.u('92'), pg_catalog.clock_timestamp() + interval '1 millisecond');

-- Presences : eleves et enseignant effectif connectes toute l'heure.
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT sp.session_id, sp.profile_id, 'joined', s.started_at + interval '1 minute', 'livekit_webhook'
  FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
 WHERE sp.session_id::text LIKE 'c5000000%';
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
SELECT s.id, CASE WHEN s.id = pg_temp.u('62') THEN pg_temp.u('b2') ELSE pg_temp.u('b1') END,
       x.t::public.session_event_type, s.started_at + x.m * interval '1 minute', 'livekit_webhook'
  FROM public.sessions s, (VALUES ('joined', 0), ('left', 60)) AS x(t, m)
 WHERE s.id::text LIKE 'c5000000%';

ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id::text LIKE 'c5000000%';
UPDATE public.sessions SET status = 'in_progress' WHERE id::text LIKE 'c5000000%';
UPDATE public.sessions s SET finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
 WHERE id::text LIKE 'c5000000%';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;

SELECT pg_temp.vrai(private.c29_enseignant_effectif_session(pg_temp.u('62')) = pg_temp.u('b2')
  AND private.c29_enseignant_effectif_session(pg_temp.u('61')) = pg_temp.u('b1')
  AND private.c29_enseignant_effectif_session(pg_temp.u('63')) = pg_temp.u('b1'),
  'fixtures : s62 confiee a b2, s61 et s63 a la titulaire');

-- ------------------------------------------------------------------
-- 1. Avant tout cahier : la semaine mixte
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.a_remplir() = '62',
  'remplacant : la seance remplacee est dans ses cahiers a remplir, et elle seule');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.a_remplir() = '61,63',
  'titulaire : s61 pour sa semaine (plus s62, remplacee), s63 la semaine suivante');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. La titulaire ecartee ne depose pas
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT pg_temp.brouillon_ok(pg_temp.u('62')),
  'titulaire ecartee : pas de brouillon pour la seance remplacee');
SELECT pg_temp.vrai(NOT pg_temp.deposer(pg_temp.u('62'), 'cr-b1-62', pg_temp.u('b1')),
  'titulaire ecartee : depot refuse sur la seance remplacee');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Un enseignant etranger est refuse
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.a_remplir() = '', 'etrangere : rien a remplir');
SELECT pg_temp.vrai(NOT pg_temp.brouillon_ok(pg_temp.u('62')) AND NOT pg_temp.brouillon_ok(pg_temp.u('63')),
  'etrangere : pas de brouillon');
SELECT pg_temp.vrai(NOT pg_temp.deposer(pg_temp.u('62'), 'cr-b3-62', pg_temp.u('b3'))
  AND NOT pg_temp.deposer(pg_temp.u('63'), 'cr-b3-63', pg_temp.u('b3')),
  'etrangere : depot refuse, seance remplacee ou non');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Le remplacant depose
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.brouillon_ok(pg_temp.u('62')),
  'remplacant : le brouillon du cahier de la seance remplacee lui est servi');
SELECT pg_temp.vrai(NOT pg_temp.brouillon_ok(pg_temp.u('61')),
  'remplacant : pas de brouillon pour une seance de la titulaire');
SELECT pg_temp.vrai(pg_temp.deposer(pg_temp.u('62'), 'cr-b2-62', pg_temp.u('b2')),
  'remplacant : depot du cahier reussi');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.u('62')) = 1, 'remplacant : relit son cahier');
SELECT pg_temp.vrai(pg_temp.a_remplir() = '', 'remplacant : plus rien a remplir');
DO $$ BEGIN
  INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
  VALUES (pg_temp.u('62'), 'cr-b2-usurpe', '{"version":1,"eleves":[]}'::jsonb, pg_temp.u('b1'));
  RAISE EXCEPTION 'ROUGE : le remplacant depose au nom de la titulaire';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'OK le remplacant ne depose pas au nom d''un autre';
END $$;
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. La titulaire lit ; semaine mixte couverte ; paie inchangee
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.u('62')) = 1,
  'titulaire ecartee : lit le cahier du remplacant');
SELECT pg_temp.vrai(pg_temp.a_remplir() = '63',
  'semaine mixte : le cahier du remplacant (e1, e2) couvre aussi s61, il ne reste que s63');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.u('62')) = 0, 'etrangere : ne lit pas le cahier');
RESET ROLE;
SELECT pg_temp.vrai((SELECT enseignant = pg_temp.u('b2') AND NOT en_attente
                       FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00')
                      WHERE seance = pg_temp.u('62'))
  AND (SELECT enseignant = pg_temp.u('b1') AND NOT en_attente
         FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00')
        WHERE seance = pg_temp.u('61'))
  AND (SELECT en_attente FROM private.pai_releve_seances('2026-10-01 00:00+00', '2026-11-01 00:00+00')
        WHERE seance = pg_temp.u('63')),
  'paie (regle inchangee) : s62 au remplacant, s61 a la titulaire, liberees ; s63 attend son cahier');

-- ------------------------------------------------------------------
-- 6. La seance non remplacee ne change pas
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT pg_temp.brouillon_ok(pg_temp.u('63'))
  AND NOT pg_temp.deposer(pg_temp.u('63'), 'cr-b2-63', pg_temp.u('b2')),
  'non remplacee : le remplacant d''une autre seance n''y depose pas');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.brouillon_ok(pg_temp.u('63'))
  AND pg_temp.deposer(pg_temp.u('63'), 'cr-b1-63', pg_temp.u('b1')),
  'non remplacee : la titulaire a son brouillon et depose');
SELECT pg_temp.vrai(pg_temp.a_remplir() = '', 'titulaire : plus rien a remplir');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.u('63')) = 0,
  'non remplacee : le remplacant ne lit pas le cahier de la titulaire');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. La direction depose toujours
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.deposer(pg_temp.u('62'), 'cr-a1-62', pg_temp.u('a1'))
  AND pg_temp.deposer(pg_temp.u('63'), 'cr-a1-63', pg_temp.u('a1')),
  'direction : depose sur la seance remplacee et sur la seance non remplacee');
SELECT pg_temp.vrai(pg_temp.lus(pg_temp.u('62')) = 2 AND pg_temp.lus(pg_temp.u('63')) = 2,
  'direction : lit tous les cahiers');
RESET ROLE;

-- ------------------------------------------------------------------
-- 8. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.cahier_seance_confiee(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.c29_enseignant_effectif_session(uuid)', 'EXECUTE'),
  'droits : l''enseignant effectif reste prive, son enveloppe fermee a anon');

\o
ROLLBACK;
