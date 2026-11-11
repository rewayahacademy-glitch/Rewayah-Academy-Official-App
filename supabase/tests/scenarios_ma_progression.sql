-- MA-PROGRESSION (08/11/2026) : public.ma_progression(uuid), public.regler_etape_progression et
-- public.reglages_progression_admin. Migration 20261122300000_ma_progression.sql.
-- Fixtures reprises de scenarios_suivi_eleve_pedagogique.sql. ROUGE sans la migration (la
-- fonction n'existe pas) ; VERT avec. Tout est annule a la fin.
--   1. la lecture : etape, etapes du cycle, sourates (jamais de versets), position de la Classe ;
--   2. ni motif ni decideur ; reglage vide par defaut, rempli par la direction ;
--   3. gardes : l'eleve, le tuteur du foyer ; refus a l'autre foyer, a l'autre eleve, a
--      l'enseignant, a la direction ; ecriture et lecture du reglage reservees a la direction.
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

CREATE FUNCTION pg_temp.attendu_position(p_page int) RETURNS int
LANGUAGE plpgsql AS $$
DECLARE v_liste int[] := ARRAY[1,114,113,112,111,110,109,108,107,106,105,104,103,102,101,100,99];
        i int;
BEGIN
  FOR i IN 1 .. 17 LOOP
    IF EXISTS (SELECT 1 FROM public.verset vs JOIN public.mushaf m ON m.id = vs.mushaf_id AND m.code = 'madina-hafs-604'
                WHERE vs.sourate_numero = v_liste[i]
               GROUP BY vs.sourate_numero
              HAVING min(vs.page_numero) <= p_page AND max(vs.page_numero) >= p_page) THEN
      RETURN i - 1;
    END IF;
  END LOOP;
  RETURN NULL;
END $$;

-- e1 entre a l'etape 4 (la Classe passe aussi a l'etape 4), et la Classe presente la page de
-- la derniere sourate de la liste (Az-Zalzalah).
INSERT INTO public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif, created_at)
VALUES (pg_temp.u('e1'), (SELECT id FROM se_ids WHERE cle = 'n4'), 'promotion', pg_temp.u('a1'),
        'MOTIF-SECRET-DIRECTION', pg_catalog.now() - interval '1 week');
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM se_ids WHERE cle = 'n4') WHERE id = pg_temp.u('c1');
CREATE TEMP TABLE ma_page AS
SELECT min(vs.page_numero) AS page
  FROM public.verset vs JOIN public.mushaf m ON m.id = vs.mushaf_id AND m.code = 'madina-hafs-604'
 WHERE vs.sourate_numero = 99;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s1'), pg_temp.u('b1'), pg_catalog.now() - interval '2 hours', pg_catalog.now() - interval '1 hour',
        'planned', pg_temp.u('c1'));
INSERT INTO public.classe_position_reprise(groupe_id, page, session_id, presentee_par)
SELECT pg_temp.u('c1'), page, pg_temp.u('s1'), pg_temp.u('b1') FROM ma_page;
GRANT SELECT ON ma_page TO authenticated;
CREATE TEMP TABLE ma_sortie(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON ma_sortie TO authenticated;

-- 1. La lecture, par l'eleve.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'etape' ->> 'ordre')::int = 4 AND j -> 'etape' ->> 'cycle' = 'Les bases'
          AND j -> 'etape' ->> 'nom' IS NOT NULL AND j -> 'etape' ->> 'rythme' IS NOT NULL
          AND (j -> 'etape' ->> 'page_reprise')::int = (SELECT page FROM ma_page)
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : l''etape 4, son rythme et la page de reprise viennent de suivi_pedagogique_eleve');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.jsonb_array_length(j -> 'etapes_du_cycle') = 4
          AND (SELECT pg_catalog.array_agg(x ->> 'statut' ORDER BY (x ->> 'ordre')::int)
                 FROM pg_catalog.jsonb_array_elements(j -> 'etapes_du_cycle') x)
              = ARRAY['franchie','franchie','franchie','en_cours']
          AND (SELECT (x ->> 'atteinte_le') IS NOT NULL
                 FROM pg_catalog.jsonb_array_elements(j -> 'etapes_du_cycle') x WHERE (x ->> 'ordre')::int = 4)
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : les 4 etapes du cycle dans l''ordre, trois franchies, la sienne en cours, avec sa date d''entree');
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'total')::int = 17
          AND pg_catalog.jsonb_array_length(j -> 'sourates' -> 'liste') = 17
          AND (j -> 'sourates' -> 'liste' -> 0 ->> 'numero')::int = 1
          AND (j -> 'sourates' -> 'liste' -> 16 ->> 'numero')::int = 99
          AND (j -> 'sourates' -> 'liste' -> 0 ->> 'nom') IS NOT NULL
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : 17 sourates des bases, Al-Fatiha puis 114 a 99, noms lus dans le corpus');
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'position_de_la_classe')::int = pg_temp.attendu_position((SELECT page FROM ma_page))
          AND (j -> 'sourates' ->> 'position_de_la_classe')::int BETWEEN 14 AND 16
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : la position de la Classe = sourates AVANT celle ou se trouve sa page (calcul independant)');
SELECT pg_temp.vrai(
  (SELECT (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_array_elements(j -> 'sourates' -> 'liste') x
            WHERE (x ->> 'etudiee_par_la_classe')::boolean) = (j -> 'sourates' ->> 'position_de_la_classe')::int
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : autant de sourates marquees « etudiee par la classe » que la position');
-- Jamais de versets, ni motif, ni decideur.
SELECT pg_temp.vrai(
  -- Les OBJECTIFS de l'etape sont le texte du programme (« fins de versets ») : on verifie les
  -- CLES, pas le texte. Ni cle de verset, ni motif, ni decideur ; ni la valeur du motif, ni
  -- l'identifiant de la direction.
  (SELECT j::text !~* '"[^"]*(verset|motif|decide|notes|evaluateur)[^"]*"\s*:'
          AND j::text NOT LIKE '%MOTIF-SECRET-DIRECTION%'
          AND j::text NOT LIKE '%' || pg_temp.u('a1')::text || '%'
     FROM ma_sortie WHERE cle = 'e1'),
  'aucune cle de verset, de motif ni de decideur ; ni le motif, ni la direction, dans la lecture');
SELECT pg_temp.vrai(
  (SELECT j -> 'reglage' = 'null'::jsonb OR j -> 'reglage' IS NULL FROM ma_sortie WHERE cle = 'e1'),
  'reglage de l''etape vide par defaut : rien n''est invente');

-- Avant l'etape des sourates : position inconnue (NULL), jamais 0.
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e2', public.ma_progression(pg_temp.u('e2')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'etape' ->> 'ordre')::int = 4 AND j -> 'sourates' ->> 'position_de_la_classe' IS NOT NULL
     FROM ma_sortie WHERE cle = 'e2'),
  'e2 est dans la meme Classe (etape 4) : meme position que la Classe');

-- Sans Classe : autorise, rien a montrer.
SELECT pg_temp.qui(pg_temp.u('e3'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e3', public.ma_progression(pg_temp.u('e3')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j -> 'etape' = 'null'::jsonb AND j -> 'etapes_du_cycle' = '[]'::jsonb FROM ma_sortie WHERE cle = 'e3'),
  'e3 sans Classe : reponse vide, sans erreur');

-- 2. Le reglage par la direction.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.regler_etape_progression('BASES-4', ARRAY[1,114,113,112,111,110,109,108,107,106,105,104,103,102,101,100,99], 2.5, 30);
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1b', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'reglage' ->> 'heures_revision_semaine')::numeric = 2.5 AND (j -> 'reglage' ->> 'repetitions_estimees')::int = 30
     FROM ma_sortie WHERE cle = 'e1b'),
  'reglage rempli par la direction : heures et repetitions lues par l''eleve');
-- Apres l'etape des sourates : toutes. (La liste passe a l'etape 3 ; e1 est a l'etape 4.)
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.regler_etape_progression('BASES-4', '{}'::integer[], 2.5, 30);
SELECT public.regler_etape_progression('BASES-3', ARRAY[1,114], NULL, NULL);
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1c', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'total')::int = 2 AND (j -> 'sourates' ->> 'position_de_la_classe')::int = 2
     FROM ma_sortie WHERE cle = 'e1c'),
  'etape au-dela de celle des sourates : toutes comptees ; la liste est reglable par la direction');
-- Eleve a l'etape 1 (e2 sorti de la Classe d'etape 4 ? non : on prend une Classe a l'etape 1).
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM se_ids WHERE cle = 'n1') WHERE id = pg_temp.u('c1');
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e2b', public.ma_progression(pg_temp.u('e2')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'etape' ->> 'ordre')::int = 1 AND j -> 'sourates' ->> 'position_de_la_classe' IS NULL
          AND (j -> 'sourates' ->> 'total')::int = 2
     FROM ma_sortie WHERE cle = 'e2b'),
  'avant l''etape des sourates : position inconnue (NULL), jamais 0');

-- 3. Gardes.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e1'))) = 'ok',
  'tuteur du foyer : lit la progression de son enfant');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e1'))) = 'refus',
  'tuteur d''un autre foyer : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e4'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e1'))) = 'refus',
  'un autre eleve, meme du foyer : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e1'))) = 'refus',
  'enseignant : refus (sa lecture reste etapes_eleves_classe)');
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', ''{}''::integer[], 1, 1)') = 'refus'
  AND pg_temp.essai('SELECT * FROM public.reglages_progression_admin()') = 'refus',
  'enseignant : ni ecriture ni lecture du reglage');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', ''{}''::integer[], 1, 1)') = 'refus'
  AND pg_temp.essai('SELECT * FROM public.reglages_progression_admin()') = 'refus'
  AND pg_temp.essai('SELECT * FROM public.programme_etape_reglages') = 'refus',
  'eleve : ni ecriture, ni lecture du reglage, ni acces a la table');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e1'))) = 'refus',
  'direction : refus (garde positive de suivi_pedagogique_eleve)');
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', ARRAY[115], 1, 1)') <> 'ok'
  AND pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', ARRAY[1,1], 1, 1)') <> 'ok'
  AND pg_temp.essai('SELECT public.regler_etape_progression(''NOPE'', ''{}''::integer[], 1, 1)') <> 'ok'
  AND pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', ''{}''::integer[], 0, 1)') <> 'ok',
  'direction : sourate hors corpus, doublon, etape inconnue, heures nulles : refuses');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.reglages_progression_admin()) >= 2,
  'direction : lit les reglages');
RESET ROLE;
-- Droits.
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.ma_progression(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.ma_progression(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.ma_progression(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'SELECT'),
  'EXECUTE pour authenticated seul ; la table reste fermee');
ROLLBACK;
