-- RYTHME-LECTURE (08/11/2026) : public.rythme_classe(uuid) rend, pour chaque eleve present
-- d'une Classe, ses semaines ecoulees et sa vitesse, a la direction, au titulaire et a
-- l'enseignant effectif ; a personne d'autre. Meme regle de vitesse que
-- suivi_pedagogique_eleve (SUIVI-ELEVE). Migration 20261122000000_rythme_lecture.sql.
-- Fixtures reprises de scenarios_suivi_eleve_pedagogique.sql. ROUGE sans la migration
-- (la fonction n'existe pas) ; VERT avec. Tout est annule a la fin.
\o /dev/null
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
-- 1. Le rythme de chaque eleve, pour la direction
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.rythme_classe(pg_temp.u('c1'))) = 5,
  'direction : une ligne par eleve present de la Classe (e1, e2, e4, e5, g1)');
SELECT pg_temp.vrai(
  (SELECT r.semaines_ecoulees = 5 AND r.vitesse = 'dans_les_temps' AND r.duree_prevue_semaines = 14
          AND r.date_limite = (r.depuis + interval '18 weeks')::date
     FROM public.rythme_classe(pg_temp.u('c1')) r WHERE r.student_id = pg_temp.u('e1')),
  'e1, 5 semaines sur 14 : dans_les_temps');
SELECT pg_temp.vrai(
  (SELECT r.semaines_ecoulees = 16 AND r.vitesse = 'au_dela_du_prevu'
     FROM public.rythme_classe(pg_temp.u('c1')) r WHERE r.student_id = pg_temp.u('e4')),
  'e4, 16 semaines : au_dela_du_prevu');
SELECT pg_temp.vrai(
  (SELECT r.vitesse = 'date_limite_depassee'
     FROM public.rythme_classe(pg_temp.u('c1')) r WHERE r.student_id = pg_temp.u('e5')),
  'e5, 20 semaines : date_limite_depassee');
SELECT pg_temp.vrai(
  (SELECT r.vitesse = 'inconnu' AND r.semaines_ecoulees IS NULL AND r.date_limite IS NULL
     FROM public.rythme_classe(pg_temp.u('c1')) r WHERE r.student_id = pg_temp.u('e2')),
  'e2 sans decision : inconnu, aucune date supposee');
-- Meme regle que le suivi de l'eleve : les deux lectures s'accordent pour chaque eleve.
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.rythme_classe(pg_temp.u('c1')) r
               WHERE r.student_id IN (pg_temp.u('e1'), pg_temp.u('e4'), pg_temp.u('e5'))
                 AND r.vitesse IS DISTINCT FROM
                     (CASE r.student_id WHEN pg_temp.u('e1') THEN 'dans_les_temps'
                                        WHEN pg_temp.u('e4') THEN 'au_dela_du_prevu'
                                        ELSE 'date_limite_depassee' END)),
  'les trois etats attendus, eleve par eleve');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Gardes
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.rythme_classe(pg_temp.u('c1'))) > 0,
  'titulaire : lit le rythme de sa Classe');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.rythme_classe(%L)', pg_temp.u('c1'))) = 'refus',
  'enseignant etranger a la Classe : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.rythme_classe(%L)', pg_temp.u('c1'))) = 'refus',
  'tuteur : refus (la lecture famille reste suivi_pedagogique_eleve)');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.rythme_classe(%L)', pg_temp.u('c1'))) = 'refus',
  'eleve : refus (il ne voit pas le rythme des autres)');
RESET ROLE;
-- Compte desactive : la direction elle-meme est refusee.
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('a1');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.rythme_classe(%L)', pg_temp.u('c1'))) = 'refus',
  'direction au compte desactive : refus');
RESET ROLE;
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.rythme_classe(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.rythme_classe(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.rythme_classe(uuid)', 'EXECUTE'),
  'EXECUTE pour authenticated seul');
ROLLBACK;
