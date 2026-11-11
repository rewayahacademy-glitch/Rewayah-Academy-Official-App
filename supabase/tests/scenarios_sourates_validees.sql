-- SOURATES (directeur, 11/11/2026, option A) : l'enseignant coche la sourate
-- au cahier. Migration 20261122900000.
-- a1 direction ; b1 titulaire de la Classe c1 ; b3 enseignant d'une autre
-- Classe c2 ; t1 tuteur du foyer f1 ; t2 tuteur d'un autre foyer f2 ;
-- e1, e2 eleves de f1 dans c1 ; e9 eleve de f1 hors seance.
--   1. le cahier depose donne les sourates validees : numeros hors des 17,
--      doublons et texte ignores, eleve hors seance ecarte ;
--   2. l'enseignant d'une autre Classe ne peut pas deposer le cahier : aucune
--      sourate ;
--   3. une validation n'est jamais perdue : second cahier sans sourate,
--      cahier efface, changement de Classe ;
--   4. lecture : sourates_eleve, meme porte que suivi_pedagogique_eleve
--      (tuteur du foyer, eleve lui-meme ; refus au tuteur d'un autre foyer et
--      a un autre eleve), total 17, liste dans l'ordre d'etude ;
--      suivi_pedagogique_eleve inchangee ;
--      sourates_bases_classe (titulaire et direction oui ; autre enseignant
--      et eleve non) ;
--   5. droits : table fermee, declencheur prive, rien pour anon ni agent_ro.
-- Echoue sans la migration (premier ROUGE : la table n'existe pas). Tout est
-- annule a la fin.
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
  $$ SELECT pg_catalog.md5('sourates-' || p)::uuid $$;

CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

-- « validees/total » que rend sourates_eleve pour [p_eleve], ou 'refus'.
CREATE FUNCTION pg_temp.suivi(p_eleve uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE r jsonb;
BEGIN
  r := public.sourates_eleve(p_eleve);
  RETURN (r ->> 'sourates_validees') || '/' || (r ->> 'sourates_total');
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

-- Les sourates de la Classe [p_groupe] : « lignes/validees », ou 'refus'.
CREATE FUNCTION pg_temp.classe(p_groupe uuid) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  SELECT pg_catalog.count(*) || '/' || pg_catalog.count(*) FILTER (WHERE c.validee) INTO v
    FROM public.sourates_bases_classe(p_groupe) c;
  RETURN v;
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text), pg_temp.suivi(uuid), pg_temp.classe(uuid) TO authenticated, anon;

CREATE TEMP TABLE so_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON so_ids TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'so-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b3','t1','t2','e1','e2','e9']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'Europe/Paris'), (pg_temp.u('f2'), 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'SO', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','SO-ADM-01','admin',NULL,'Direction'),
   ('b1','SO-ENS-01','teacher',NULL,'Titulaire'),
   ('b3','SO-ENS-03','teacher',NULL,'Autre'),
   ('t1','SO-TUT-01','guardian','f1','Tutrice'),
   ('t2','SO-TUT-02','guardian','f2','Autre tutrice'),
   ('e1','SO-ELV-01','student','f1','Eleve un'),
   ('e2','SO-ELV-02','student','f1','Eleve deux'),
   ('e9','SO-ELV-09','student','f1','Hors seance')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
SELECT pg_temp.u(x), 'minor'::public.student_type, 'standard'::public.interface_mode, 'enfant_10_13'
  FROM unnest(ARRAY['e1','e2','e9']) AS x;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour SO', 1, 18, 'Europe/Paris'),
 (pg_temp.u('c2'), pg_temp.u('b3'), 'enfant', 6, 'Al-Fajr SO', 2, 18, 'Europe/Paris');
INSERT INTO public.groupe_membres(groupe_id, student_id)
SELECT pg_temp.u('c1'), pg_temp.u(x) FROM unnest(ARRAY['e1','e2']) AS x;

-- Le programme publie : le suivi rend une ligne pour un eleve d'une Classe.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO so_ids VALUES ('v1', public.creer_version_programme(NULL));
SELECT public.preremplir_bases_programme((SELECT id FROM so_ids WHERE cle = 'v1'));
INSERT INTO so_ids
SELECT 'n' || c.ordre, c.niveau_id
  FROM public.programme_contenu_admin((SELECT id FROM so_ids WHERE cle = 'v1')) c;
SELECT public.publier_version_programme((SELECT id FROM so_ids WHERE cle = 'v1'), 'Version 1 des bases');
RESET ROLE;
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM so_ids WHERE cle = 'n1')
 WHERE id IN (pg_temp.u('c1'), pg_temp.u('c2'));

-- s1 : seance tenue il y a une heure par le titulaire.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s1'), pg_temp.u('b1'), pg_catalog.now() - interval '2 hours',
        pg_catalog.now() - interval '1 hour', 'ended', pg_temp.u('c1'));
INSERT INTO public.session_participants(session_id, profile_id, role)
SELECT pg_temp.u('s1'), pg_temp.u(e), 'student'::public.participant_role
  FROM unnest(ARRAY['e1','e2']) AS e;

-- ------------------------------------------------------------------
-- 1. Le cahier depose donne les sourates validees
-- ------------------------------------------------------------------
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id)
VALUES (pg_temp.u('r1'), pg_temp.u('s1'), 'so-r1', pg_catalog.jsonb_build_object(
  'version', 1, 'position_reprise', 'Page 3',
  'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1'), 'confirme', true,
      'sourates_validees', pg_catalog.jsonb_build_array(1, 114, '114', 99, 200, 'abc', 2)),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2'), 'confirme', true,
      'sourates_validees', pg_catalog.jsonb_build_array(1)),
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e9'),
      'sourates_validees', pg_catalog.jsonb_build_array(1)),
    pg_catalog.jsonb_build_object('student_id', 'pas-un-uuid',
      'sourates_validees', pg_catalog.jsonb_build_array(1)))),
  pg_temp.u('b1'));
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(sourate_numero ORDER BY sourate_numero) FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e1')) = ARRAY[1, 99, 114]
  AND (SELECT pg_catalog.count(*) FROM public.sourates_validees WHERE student_id = pg_temp.u('e2')) = 1
  AND (SELECT pg_catalog.count(*) FROM public.sourates_validees WHERE student_id = pg_temp.u('e9')) = 0
  AND (SELECT pg_catalog.bool_and(validee_par = pg_temp.u('b1') AND lesson_report_id = pg_temp.u('r1'))
         FROM public.sourates_validees),
  'cahier : 1, 99 et 114 pour e1 (hors des 17, doublon et texte ignores), 1 pour e2, rien hors seance');

-- ------------------------------------------------------------------
-- 1 bis. Cahier modifie : la sourate est ajoutee (garde-cap, 11/11)
-- ------------------------------------------------------------------
-- L'enseignant de la seance modifie son cahier (politique FOR ALL) et coche
-- Al-Ikhlas (112) pour e2 : elle est validee ; 1 reste validee pour e2.
-- Bloc isole (point de sauvegarde annule a la fin) : la suite garde 1 pour e2.
SAVEPOINT cahier_modifie;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
UPDATE public.lesson_reports
   SET content = pg_catalog.jsonb_set(content, '{eleves,1,sourates_validees}',
                                      pg_catalog.jsonb_build_array(1, 112))
 WHERE id = pg_temp.u('r1');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(sourate_numero ORDER BY sourate_numero) FROM public.sourates_validees
    WHERE student_id = pg_temp.u('e2')) = ARRAY[1, 112]
  AND (SELECT validee_par = pg_temp.u('b1') FROM public.sourates_validees
        WHERE student_id = pg_temp.u('e2') AND sourate_numero = 112),
  'cahier modifie : Al-Ikhlas ajoutee pour e2, Al-Fatiha gardee');
-- Retirer la sourate du cahier ne l'efface pas (ajout seul).
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
UPDATE public.lesson_reports
   SET content = pg_catalog.jsonb_set(content, '{eleves,1,sourates_validees}',
                                      '[]'::jsonb)
 WHERE id = pg_temp.u('r1');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sourates_validees WHERE student_id = pg_temp.u('e2')) = 2,
  'cahier modifie : une sourate decochee ensuite reste validee');
ROLLBACK TO SAVEPOINT cahier_modifie;

-- ------------------------------------------------------------------
-- 2. L'enseignant d'une autre Classe ne depose pas le cahier
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format(
    'INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id) '
    'VALUES (%L, %L, %L::jsonb, %L)',
    pg_temp.u('s1'), 'so-r-etranger',
    pg_catalog.jsonb_build_object('eleves', pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('student_id', pg_temp.u('e2'),
        'sourates_validees', pg_catalog.jsonb_build_array(113)))),
    pg_temp.u('b3'))) <> 'ok',
  'autre enseignant : le cahier de la seance d''une autre Classe est refuse');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.sourates_validees WHERE sourate_numero = 113),
  'autre enseignant : aucune sourate validee');

-- ------------------------------------------------------------------
-- 3. Une validation n'est jamais perdue
-- ------------------------------------------------------------------
-- Un cahier corrige, sans sourate : rien n'est retire.
INSERT INTO public.lesson_reports(id, session_id, idempotency_key, content, author_profile_id, created_at)
VALUES (pg_temp.u('r2'), pg_temp.u('s1'), 'so-r2', pg_catalog.jsonb_build_object(
  'version', 1, 'eleves', pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object('student_id', pg_temp.u('e1'), 'confirme', true))),
  pg_temp.u('b1'), pg_catalog.now() + interval '1 minute');
-- Le premier cahier efface : rien n'est retire.
UPDATE public.lesson_reports SET deleted_at = pg_catalog.now() WHERE id = pg_temp.u('r1');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sourates_validees WHERE student_id = pg_temp.u('e1')) = 3,
  'jamais perdue : cahier corrige sans sourate, puis cahier efface');
-- Changement de Classe : e1 quitte c1 pour c2.
UPDATE public.groupe_membres
   SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'Changement de Classe'
 WHERE groupe_id = pg_temp.u('c1') AND student_id = pg_temp.u('e1');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (pg_temp.u('c2'), pg_temp.u('e1'));
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e1')) = '3/17',
  'jamais perdue : apres un changement de Classe, le tuteur lit toujours 3 sur 17');
RESET ROLE;

-- ------------------------------------------------------------------
-- 4. Lecture
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e2')) = '1/17', 'tuteur du foyer : 1 sur 17 pour e2');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e2')) = 'refus', 'tuteur d''un autre foyer : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e2')) = '1/17', 'eleve : lit les siennes');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.jsonb_array_length(public.sourates_eleve(pg_temp.u('e2')) -> 'sourates')) = 17
  AND (public.sourates_eleve(pg_temp.u('e2')) -> 'sourates' -> 0 ->> 'numero') = '1'
  AND (public.sourates_eleve(pg_temp.u('e2')) -> 'sourates' -> 0 ->> 'validee') = 'true'
  AND (public.sourates_eleve(pg_temp.u('e2')) -> 'sourates' -> 1 ->> 'numero') = '114'
  AND (public.sourates_eleve(pg_temp.u('e2')) -> 'sourates' -> 1 ->> 'validee') = 'false',
  'eleve : la liste des 17, dans l''ordre d''etude, avec l''etat de chacune');
SELECT pg_temp.vrai(pg_temp.suivi(pg_temp.u('e1')) = 'refus', 'eleve : refus pour un autre eleve');
SELECT pg_temp.vrai(pg_temp.classe(pg_temp.u('c1')) = 'refus', 'eleve : sourates de la Classe refusees');
RESET ROLE;
-- c1 ne compte plus que e2 : 17 lignes, 1 validee.
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.classe(pg_temp.u('c1')) = '17/1', 'titulaire : les 17 sourates de chaque eleve de sa Classe');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.classe(pg_temp.u('c1')) = '17/1', 'direction : lecture');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.classe(pg_temp.u('c1')) = 'refus', 'autre enseignant : sourates de la Classe refusees');
-- Sa Classe c2 compte maintenant e1, avec ses 3 sourates.
SELECT pg_temp.vrai(pg_temp.classe(pg_temp.u('c2')) = '17/3', 'nouvel enseignant : voit les sourates deja validees');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(numero ORDER BY ordre) FROM private.sourates_des_bases)
    = ARRAY[1, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99],
  'source unique : les 17 sourates des bases dans l''ordre d''etude');

-- ------------------------------------------------------------------
-- 5. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_table_privilege('authenticated', 'public.sourates_validees', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'public.sourates_validees', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.sourates_validees', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.sourates_validees', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'private.sourates_des_bases', 'SELECT')
  AND NOT has_function_privilege('authenticated', 'private.cahier_sourates_validees()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.sourates_eleve(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.sourates_bases_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.sourates_bases_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.sourates_eleve(uuid)', 'EXECUTE')
  -- suivi_pedagogique_eleve n'a pas change : ni sourate dans son resultat.
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                   WHERE p.oid = 'public.suivi_pedagogique_eleve(uuid)'::pg_catalog.regprocedure
                     AND 'sourates_validees' = ANY (coalesce(p.proargnames, ARRAY[]::text[]))),
  'droits : table fermee, declencheur prive, rien pour anon ni agent_ro');

\o
ROLLBACK;
