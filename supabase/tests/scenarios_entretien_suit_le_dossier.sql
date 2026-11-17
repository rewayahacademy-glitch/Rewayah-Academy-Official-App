-- BE-1h ENTRETIEN-SUIT-LE-DOSSIER (pilote, 16/11/2026 ; trou T11) : migration 20261129460000_entretien_suit_le_dossier.sql.
--
-- Cas couverts : (a) mettre en pause une candidature « entretien planifie » annule son entretien ouvert (issue
-- annule, seance canceled), la ramene a « entretien a planifier », ecrit un evenement de type entretien ; lever la
-- pause ne rend rien et n'invente pas d'entretien ; (b) refuser et (c) consigner un retrait font de meme ; (d) un
-- changement d'issue hors de ces gestes (ecriture directe, retrait par la personne) est suivi aussi ; (e) un
-- dossier sans entretien ouvert n'est pas touche, un entretien deja tenu garde son issue, un autre geste
-- (choisir le responsable) laisse l'entretien ouvert ; (f) le coeur partage, rejoue, rend NULL sans entretien
-- ouvert et ne fait rien d'une seconde annulation ; (g) droits : aucune des deux fonctions n'est executable par un
-- client.
-- Chaque controle leve 'SUIT ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SUIT ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e5100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e510cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.s(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e5100000-0000-4000-8000-0000000003' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(etat, '-') FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.issue_entretien(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(issue, 'ouvert') FROM public.entretiens WHERE session_id = pg_temp.s(p_n) $$;
CREATE FUNCTION pg_temp.statut_seance(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT status::text FROM public.sessions WHERE id = pg_temp.s(p_n) $$;
CREATE FUNCTION pg_temp.evenements(p_n text) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = 'entretien' AND e.details @> '{"suitLeDossier": true}'::jsonb
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.en(uuid, text, text), pg_temp.p(text), pg_temp.c(text), pg_temp.s(text), pg_temp.v(text),
  pg_temp.etat(text), pg_temp.issue_entretien(text), pg_temp.statut_seance(text), pg_temp.evenements(text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme). Candidats hommes en Salle de verification :
-- 01 pause, 02 refus, 03 retrait, 06 ecriture directe, 08 autre geste : entretien planifie, entretien ouvert ;
-- 04 entretien a planifier, sans entretien ; 05 decision en attente, entretien deja tenu ;
-- 07 entretien planifie et dossier DEJA ferme (la base du rattrapage, fabriquee hors declencheur).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'su-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07', '08']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'SU-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'SU-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, 'verifications', v.etat, v.issue, 'lien_public'
FROM (VALUES
  ('01', 'entretien_planifie', 'en_cours'),
  ('02', 'entretien_planifie', 'en_cours'),
  ('03', 'entretien_planifie', 'en_cours'),
  ('04', 'entretien_a_planifier', 'en_cours'),
  ('05', 'decision_en_attente', 'en_cours'),
  ('06', 'entretien_planifie', 'en_cours'),
  ('07', 'entretien_planifie', 'refusee'),
  ('08', 'entretien_planifie', 'en_cours')) AS v(s, etat, issue);
-- Une seance planifiee et un entretien OUVERT pour 01, 02, 03, 06, 07, 08 ; un entretien TENU pour 05.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
SELECT pg_temp.s(s), pg_temp.p('a1'), now() + interval '2 days', now() + interval '2 days 30 minutes',
       'planned', 'entretien', now() + interval '2 days' - interval '10 minutes'
FROM unnest(ARRAY['01', '02', '03', '05', '06', '07', '08']) AS s;
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
SELECT pg_temp.s(s), pg_temp.c(s), pg_temp.p(s), pg_temp.p('a1')
FROM unnest(ARRAY['01', '02', '03', '06', '07', '08']) AS s;
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par, issue, consigne_par, consigne_le)
VALUES (pg_temp.s('05'), pg_temp.c('05'), pg_temp.p('05'), pg_temp.p('a1'), 'tenu', pg_temp.p('a1'), now());
SET LOCAL session_replication_role = origin;

-- ------------------------------------------------------------
-- (a) La pause annule l'entretien ouvert ; lever la pause n'en invente pas
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.issue_entretien('01') = 'ouvert' AND pg_temp.statut_seance('01') = 'planned'
  AND pg_temp.etat('01') = 'entretien_planifie',
  'a0 : avant la pause, l''entretien est ouvert, la seance planifiee, le dossier « entretien planifie »');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.mettre_en_pause_candidat(%L, %L, %L, NULL, %s, %L)',
  pg_temp.c('01'), 'Pause demandee', 'pause_general', pg_temp.v('01'), 'cle-suit-01'));
SELECT pg_temp.vrai(
  (SELECT en_pause FROM public.candidatures WHERE id = pg_temp.c('01'))
  AND pg_temp.issue_entretien('01') = 'annule' AND pg_temp.statut_seance('01') = 'canceled'
  AND (SELECT consigne_par FROM public.entretiens WHERE session_id = pg_temp.s('01')) = pg_temp.p('a1'),
  'a1 : la pause annule l''entretien (issue annule, seance canceled, annule par la direction)');
SELECT pg_temp.vrai(pg_temp.etat('01') = 'entretien_a_planifier',
  'a2 : le dossier revient a « entretien a planifier » : aucun dossier ne porte « planifie » sans entretien');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.candidature_evenements e
           WHERE e.candidature_id = pg_temp.c('01') AND e.type = 'entretien' AND e.etat_avant = 'entretien_planifie'
             AND e.etat_apres = 'entretien_a_planifier' AND e.auteur_id = pg_temp.p('a1')
             AND e.details @> pg_catalog.jsonb_build_object('entretienAnnule', true, 'cause', 'pause',
                                                            'sessionAnnulee', pg_temp.s('01'))),
  'a3 : un evenement de type entretien garde la trace (cause pause, seance annulee, qui)');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.lever_pause_candidat(%L, %s, %L, NULL)', pg_temp.c('01'), pg_temp.v('01'), 'cle-suit-01b'));
SELECT pg_temp.vrai(
  NOT (SELECT en_pause FROM public.candidatures WHERE id = pg_temp.c('01'))
  AND pg_temp.etat('01') = 'entretien_a_planifier' AND pg_temp.issue_entretien('01') = 'annule'
  AND pg_temp.evenements('01') = 1
  AND NOT EXISTS (SELECT 1 FROM public.entretiens WHERE candidature_id = pg_temp.c('01') AND issue IS NULL),
  'a4 : lever la pause ne rouvre rien : toujours « a planifier », entretien annule, aucun entretien ouvert, un seul evenement');

-- ------------------------------------------------------------
-- (b) Le refus, (c) le retrait
-- ------------------------------------------------------------
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.refuser_candidat(%L, %L, %L, %s, %L)', pg_temp.c('02'), 'Niveau', 'refus_niveau', pg_temp.v('02'), 'cle-suit-02'));
SELECT pg_temp.vrai(
  (SELECT issue FROM public.candidatures WHERE id = pg_temp.c('02')) = 'refusee'
  AND pg_temp.issue_entretien('02') = 'annule' AND pg_temp.statut_seance('02') = 'canceled'
  AND pg_temp.etat('02') = 'entretien_a_planifier' AND pg_temp.evenements('02') = 1,
  'b1 : le refus annule l''entretien, ramene le dossier a « a planifier », une trace');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.consigner_retrait_candidat(%L, %L, %L, %L, %s, %L)',
  pg_temp.c('03'), 'courriel', current_date::text, 'Demande recue', pg_temp.v('03'), 'cle-suit-03'));
SELECT pg_temp.vrai(
  (SELECT issue FROM public.candidatures WHERE id = pg_temp.c('03')) = 'retiree'
  AND pg_temp.issue_entretien('03') = 'annule' AND pg_temp.statut_seance('03') = 'canceled'
  AND pg_temp.etat('03') = 'entretien_a_planifier' AND pg_temp.evenements('03') = 1,
  'c1 : le retrait annule l''entretien, ramene le dossier a « a planifier », une trace');

-- ------------------------------------------------------------
-- (d) Hors des trois gestes : un changement d'issue est suivi aussi (retrait par la personne, ecriture directe)
-- ------------------------------------------------------------
UPDATE public.candidatures SET issue = 'retiree' WHERE id = pg_temp.c('06');
SELECT pg_temp.vrai(
  pg_temp.issue_entretien('06') = 'annule' AND pg_temp.statut_seance('06') = 'canceled'
  AND pg_temp.etat('06') = 'entretien_a_planifier'
  AND (SELECT consigne_par FROM public.entretiens WHERE session_id = pg_temp.s('06')) = pg_temp.p('a1'),
  'd1 : sans appelant, le declencheur annule aussi, au nom de la personne qui avait planifie');

-- ------------------------------------------------------------
-- (e) Ce qui ne bouge pas
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_evenements e
    WHERE e.candidature_id = pg_temp.c('04') AND e.details @> '{"suitLeDossier": true}'::jsonb) = 0,
  'e0 : avant : aucune trace pour le dossier 04');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.mettre_en_pause_candidat(%L, %L, %L, NULL, %s, %L)',
  pg_temp.c('04'), 'Pause', 'pause_general', pg_temp.v('04'), 'cle-suit-04'));
SELECT pg_temp.vrai(
  (SELECT en_pause FROM public.candidatures WHERE id = pg_temp.c('04')) AND pg_temp.etat('04') = 'entretien_a_planifier'
  AND pg_temp.evenements('04') = 0,
  'e1 : un dossier sans entretien ouvert est mis en pause comme avant, sans trace d''annulation');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.refuser_candidat(%L, %L, %L, %s, %L)', pg_temp.c('05'), 'Niveau', 'refus_niveau', pg_temp.v('05'), 'cle-suit-05'));
SELECT pg_temp.vrai(
  pg_temp.issue_entretien('05') = 'tenu' AND pg_temp.etat('05') = 'decision_en_attente' AND pg_temp.evenements('05') = 0,
  'e2 : un entretien deja tenu garde son issue, le dossier son etat : seul un entretien OUVERT est annule');
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.definir_responsable_candidat(%L, %L, %s, %L)', pg_temp.c('08'), pg_temp.p('a1'), pg_temp.v('08'), 'cle-suit-08'));
SELECT pg_temp.vrai(
  pg_temp.issue_entretien('08') = 'ouvert' AND pg_temp.statut_seance('08') = 'planned'
  AND pg_temp.etat('08') = 'entretien_planifie' AND pg_temp.evenements('08') = 0,
  'e3 : un autre geste (choisir le responsable) laisse l''entretien ouvert et la seance planifiee');

-- ------------------------------------------------------------
-- (f) Le coeur partage (celui du rattrapage)
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.issue_entretien('07') = 'ouvert'
  AND (SELECT issue FROM public.candidatures WHERE id = pg_temp.c('07')) = 'refusee',
  'f0 : le dossier 07 est ferme et garde un entretien ouvert (le cas que le rattrapage corrige)');
SELECT pg_temp.vrai(
  private.entretien_annuler_pour_dossier(pg_temp.c('07'), NULL) = pg_temp.s('07')
  AND pg_temp.issue_entretien('07') = 'annule' AND pg_temp.statut_seance('07') = 'canceled',
  'f1 : le coeur annule l''entretien ouvert et rend la seance annulee (sans appelant : celui qui avait planifie)');
SELECT pg_temp.vrai(
  private.entretien_annuler_pour_dossier(pg_temp.c('07'), NULL) IS NULL
  AND private.entretien_annuler_pour_dossier(pg_temp.c('04'), NULL) IS NULL,
  'f2 : sans entretien ouvert, le coeur ne fait rien et rend NULL (deux fois de suite aussi)');

-- ------------------------------------------------------------
-- (g) Droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.entretien_annuler_pour_dossier(uuid, uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.entretien_annuler_pour_dossier(uuid, uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.candidatures_entretien_suit()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.candidatures_entretien_suit()', 'EXECUTE'),
  'g1 : ni anon ni authenticated n''executent le coeur ni le declencheur');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
           WHERE p.oid = 'private.candidatures_entretien_suit()'::regprocedure AND p.prosecdef
             AND p.proconfig @> ARRAY['search_path=""']),
  'g2 : le declencheur est SECURITY DEFINER avec search_path vide');

DO $$ BEGIN RAISE NOTICE 'SUIT : % controles verts', pg_catalog.current_setting('test.n'); END $$;
ROLLBACK;
