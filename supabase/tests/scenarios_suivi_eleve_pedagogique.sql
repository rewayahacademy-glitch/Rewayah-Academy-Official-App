-- SUIVI-ELEVE (07/11/2026) : le suivi pedagogique de l'eleve et de sa
-- famille. Migration 20261115000000.
-- a1 direction ; b1 titulaire de la Classe c1 ; b3 enseignant etranger ;
-- t1 tuteur du foyer f1 ; t2 tuteur d'un autre foyer f2 ;
-- e1, e4, e5 eleves de f1 en 6-9 ans, decides a l'etape 2 (14 semaines
-- prevues, date limite a 18) il y a 5, 16 et 20 semaines ; e2 eleve de f1
-- sans decision ; e3 eleve de f1 sans Classe ; g1 adulte titulaire de son
-- propre profil eleve (role guardian, 0052), dans la Classe.
--   1. vitesse : dans_les_temps, au_dela_du_prevu, date_limite_depassee,
--      inconnu ; date limite et semaines ecoulees ; aucun etat « en avance » ;
--   2. derniere page presentee : absente, puis lue apres CAHIER-C1 ;
--   3. gardes : l'eleve lui-meme, le titulaire de son profil, le tuteur du
--      foyer ; refus a un autre eleve, a l'enseignant, au tuteur d'un autre
--      foyer, a un role nul ; aucun droit pour anon ni agent_ro ;
--   4. etapes_eleves_classe rend toujours la meme chose (source unique).
-- Echoue sans la migration (premier ROUGE : la fonction n'existe pas).
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
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
  $$ SELECT pg_catalog.md5('suivi-eleve-' || p)::uuid $$;

CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

CREATE TEMP TABLE se_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON se_ids TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'se-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b3','t1','t2','e1','e2','e3','e4','e5','g1']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f2'), 'America/Toronto'),
  (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'SE', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','SE-ADM-01','admin',NULL,'Direction'),
   ('b1','SE-ENS-01','teacher',NULL,'Titulaire'),
   ('b3','SE-ENS-03','teacher',NULL,'Etrangere'),
   ('t1','SE-TUT-01','guardian','f1','Tutrice'),
   ('t2','SE-TUT-02','guardian','f2','Autre'),
   ('e1','SE-ELV-01','student','f1','Eleve un'),
   ('e2','SE-ELV-02','student','f1','Eleve deux'),
   ('e3','SE-ELV-03','student','f1','Eleve trois'),
   ('e4','SE-ELV-04','student','f1','Eleve quatre'),
   ('e5','SE-ELV-05','student','f1','Eleve cinq'),
   ('g1','SE-TIT-01','guardian','f3','Adulte')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode, 'enfant_6_9'
  FROM unnest(ARRAY['e1','e2','e3','e4','e5']) AS x;
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte)
VALUES (pg_temp.u('g1'), pg_temp.u('g1'), 'autonomous'::public.student_type, 'standard'::public.interface_mode,
        'adulte_18_plus');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour SE', 1, 18, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id)
SELECT pg_temp.u('c1'), pg_temp.u(x) FROM unnest(ARRAY['e1','e2','e4','e5','g1']) AS x;

-- Le programme : la proposition des bases, publiee.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO se_ids VALUES ('v1', public.creer_version_programme(NULL));
SELECT public.preremplir_bases_programme((SELECT id FROM se_ids WHERE cle = 'v1'));
INSERT INTO se_ids
SELECT 'n' || c.ordre, c.niveau_id
  FROM public.programme_contenu_admin((SELECT id FROM se_ids WHERE cle = 'v1')) c;
SELECT public.publier_version_programme((SELECT id FROM se_ids WHERE cle = 'v1'), 'Version 1 des bases');
RESET ROLE;
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM se_ids WHERE cle = 'n1')
 WHERE id = pg_temp.u('c1');
-- Decisions datees : 5, 16 et 20 semaines (etape 2 : 14 prevues, 18 limite).
INSERT INTO public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif, created_at)
SELECT pg_temp.u(x.e), (SELECT id FROM se_ids WHERE cle = 'n2'), 'diagnostic_initial', pg_temp.u('a1'),
       'Diagnostic', pg_catalog.now() - x.semaines * interval '1 week' - interval '1 hour'
  FROM (VALUES ('e1', 5), ('e4', 16), ('e5', 20)) AS x(e, semaines);
SELECT pg_temp.vrai(
  (SELECT (n.durees -> 'enfant_6_9' ->> 'prevue')::int = 14 AND (n.durees -> 'enfant_6_9' ->> 'limite')::int = 18
     FROM public.programme_niveaux n WHERE n.id = (SELECT id FROM se_ids WHERE cle = 'n2')),
  'fixture : etape 2, 14 semaines prevues, date limite a 18 (6-9 ans)');

-- ------------------------------------------------------------------
-- 1. La vitesse, calculee en base
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.etape_ordre = 2 AND s.duree_prevue_semaines = 14 AND s.semaines_ecoulees = 5
          AND s.rythme = 'dans_les_temps'
          AND s.date_limite = (s.depuis + interval '18 weeks')::date
          AND pg_catalog.cardinality(s.objectifs) BETWEEN 3 AND 5
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e1')) s),
  'eleve e1, 5 semaines sur 14 prevues : dans_les_temps, date limite a 18 semaines');
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('e4'))) = 'refus',
  'eleve e1 : le suivi d''un autre eleve, meme du foyer, est refuse');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('e4'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.rythme = 'au_dela_du_prevu' AND s.semaines_ecoulees = 16
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e4')) s),
  'eleve e4, 16 semaines : au_dela_du_prevu (entre la duree prevue et la date limite)');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('e5'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.rythme = 'date_limite_depassee' AND s.date_limite < pg_catalog.now()::date
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e5')) s),
  'eleve e5, 20 semaines : date_limite_depassee');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.etape_ordre = 1 AND s.rythme = 'inconnu' AND s.depuis IS NULL AND s.date_limite IS NULL
          AND s.semaines_ecoulees IS NULL
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e2')) s),
  'eleve e2 sans decision : etape de la Classe, vitesse inconnue, aucune date limite supposee');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('e3'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.suivi_pedagogique_eleve(pg_temp.u('e3'))) = 0,
  'eleve e3 sans Classe : aucune ligne, sans erreur');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. La derniere page presentee (CAHIER-C1)
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.page_reprise IS NULL AND s.page_reprise_le IS NULL
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e1')) s),
  'rien presente : aucune page, la ligne se cache');
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s1'), pg_temp.u('b1'), pg_catalog.now() - interval '2 hours',
        pg_catalog.now() - interval '1 hour', 'planned', pg_temp.u('c1'));
INSERT INTO public.classe_position_reprise(groupe_id, page, session_id, presentee_par)
VALUES (pg_temp.u('c1'), 42, pg_temp.u('s1'), pg_temp.u('b1'));
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.page_reprise = 42 AND s.page_reprise_le IS NOT NULL
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e1')) s),
  'page 42 presentee : l''eleve la lit');
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT * FROM public.classe_position_reprise') = 'refus',
  'la table de position reste fermee en lecture directe');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Gardes
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.rythme = 'au_dela_du_prevu' FROM public.suivi_pedagogique_eleve(pg_temp.u('e4')) s)
  AND (SELECT s.page_reprise = 42 FROM public.suivi_pedagogique_eleve(pg_temp.u('e1')) s),
  'tuteur du foyer : lit le suivi de ses enfants');
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('g1'))) = 'refus'
  AND pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('t1'))) = 'refus',
  'tuteur du foyer : refus hors de ses enfants (autre foyer, lui-meme sans profil eleve)');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('g1'), 'guardian', pg_temp.u('f3'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.etape_ordre = 1 AND s.rythme = 'inconnu' AND s.page_reprise = 42
     FROM public.suivi_pedagogique_eleve(pg_temp.u('g1')) s),
  'titulaire de son propre profil eleve (role guardian) : lit son suivi');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('e1'))) = 'refus',
  'tuteur d''un autre foyer : refus');
RESET ROLE;

SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('e1'))) = 'refus',
  'enseignant, meme titulaire : refus (il lit etapes_eleves_classe)');
-- Source unique : etapes_eleves_classe rend la meme etape et la meme date.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.etapes_eleves_classe(pg_temp.u('c1'))) = 5
  AND (SELECT e.etape_ordre = 2 AND e.duree_prevue_semaines = 14 AND e.date_limite_semaines = 18
              AND e.date_limite = (e.depuis + interval '18 weeks')::date
         FROM public.etapes_eleves_classe(pg_temp.u('c1')) e WHERE e.student_id = pg_temp.u('e1'))
  AND (SELECT e.etape_ordre = 1 AND e.depuis IS NULL AND e.date_limite IS NULL
         FROM public.etapes_eleves_classe(pg_temp.u('c1')) e WHERE e.student_id = pg_temp.u('e2')),
  'titulaire : etapes_eleves_classe inchangee (source unique)');
RESET ROLE;

-- Garde positive : un compte valide sans role n'entre pas.
SELECT pg_catalog.set_config('request.jwt.claim.sub', pg_temp.u('e1')::text, true);
SELECT pg_catalog.set_config('test.uid', pg_temp.u('e1')::text, true);
SELECT pg_catalog.set_config('request.jwt.claims', '{"aal": "aal1", "app_metadata": {}}', true);
SELECT pg_catalog.set_config('test.jwt', '{"aal": "aal1", "app_metadata": {}}', true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.app_role() IS NULL
  AND pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('e1'))) = 'refus',
  'role nul : refus (garde positive)');
RESET ROLE;

-- Un compte desactive n'entre pas.
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('e5');
SELECT pg_temp.qui(pg_temp.u('e5'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.suivi_pedagogique_eleve(%L)', pg_temp.u('e5'))) = 'refus',
  'compte non valide : refus');
RESET ROLE;

SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.suivi_pedagogique_eleve(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.suivi_pedagogique_eleve(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.suivi_pedagogique_eleve(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.etape_eleve(uuid, uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
  AND (SELECT p.prosecdef AND p.provolatile = 's'
            AND p.proconfig = ARRAY['search_path=""']
         FROM pg_catalog.pg_proc p WHERE p.oid = 'public.suivi_pedagogique_eleve(uuid)'::regprocedure),
  'droits : authenticated seul, aide privee fermee, DEFINER, STABLE, search_path vide');

\o
ROLLBACK;
