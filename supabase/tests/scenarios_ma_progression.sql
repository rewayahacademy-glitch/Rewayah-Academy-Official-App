-- MA-PROGRESSION (08/11/2026) : public.ma_progression(uuid), public.regler_etape_progression et
-- public.reglages_progression_admin. Migration 20261123830000_ma_progression.sql.
-- Fixtures reprises de scenarios_suivi_eleve_pedagogique.sql. ROUGE sans la migration (la
-- fonction n'existe pas) ; VERT avec. Tout est annule a la fin.
--   1. la lecture : etape, etapes du cycle, sourates (celles que l'enseignant a validees au cahier,
--      lues dans public.sourates_eleve du lot SOURATES, jamais copiees ici ; jamais de versets) ;
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
-- Decisions datees : 5, 16 et 20 semaines (etape 2 : 14 prevues, 19 limite : tableau 1 bis du
-- SOCLE-PROGRAMME, a la place de l'ancien x 1,3).
INSERT INTO public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif, created_at)
SELECT pg_temp.u(x.e), (SELECT id FROM se_ids WHERE cle = 'n2'), 'diagnostic_initial', pg_temp.u('a1'),
       'Diagnostic', pg_catalog.now() - x.semaines * interval '1 week' - interval '1 hour'
  FROM (VALUES ('e1', 5), ('e4', 16), ('e5', 20)) AS x(e, semaines);
SELECT pg_temp.vrai(
  (SELECT (n.durees -> 'enfant_6_9' ->> 'prevue')::int = 14 AND (n.durees -> 'enfant_6_9' ->> 'limite')::int = 19
     FROM public.programme_niveaux n WHERE n.id = (SELECT id FROM se_ids WHERE cle = 'n2')),
  'fixture : etape 2, 14 semaines prevues, date limite a 19 (6-9 ans, tableau 1 bis)');
-- SOCLE-PROGRAMME : l'etape se lit dans le fait propre a chaque eleve, plus dans l'etape de la
-- Classe. e1, e4, e5 ont le leur par la decision ci-dessus ; e2 et g1 (membres sans decision) le
-- recoivent comme a l'installation : etape 1 des bases.
SELECT private.rattacher_classes_et_eleves();

-- e1 entre a l'etape 4 (la Classe passe aussi a l'etape 4), et la Classe presente une page de
-- reprise (verifiee dans la lecture : elle vient de suivi_pedagogique_eleve).
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
-- Trois sourates cochees au cahier pour e1 (ecrites par le declencheur du lot SOURATES ; ici
-- directement, en proprietaire de la table : le declencheur a son propre scenario).
INSERT INTO public.sourates_validees (student_id, sourate_numero, session_id, lesson_report_id, validee_par)
SELECT pg_temp.u('e1'), x, pg_temp.u('s1'), pg_catalog.md5('rapport-' || x)::uuid, pg_temp.u('b1')
  FROM unnest(ARRAY[1, 114, 113]) AS x;
CREATE TEMP TABLE ma_sortie(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON ma_sortie TO authenticated;

-- 1. La lecture, par l'eleve.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'etape' ->> 'ordre')::int = 4 AND j -> 'etape' ->> 'cycle' = 'Les bases'
          AND j -> 'etape' ->> 'nom' IS NOT NULL
          AND (j -> 'etape' ->> 'page_reprise')::int = (SELECT page FROM ma_page)
          -- SOCLE-PROGRAMME : l'enfant de 6 a 9 ans qui lit pour lui-meme ne recoit ni rythme,
          -- ni date, ni nombre de semaines.
          AND j -> 'etape' -> 'rythme' = 'null'::jsonb
          AND j -> 'etape' -> 'date_limite' = 'null'::jsonb
          AND j -> 'etape' -> 'entree_le' = 'null'::jsonb
          AND j -> 'etape' -> 'semaines_ecoulees' = 'null'::jsonb
          AND j -> 'etape' -> 'duree_prevue_semaines' = 'null'::jsonb
          AND j -> 'etape' -> 'date_limite_semaines' = 'null'::jsonb
          AND j -> 'eleve_voit_dates' = 'false'::jsonb
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : l''etape 4 et la page de reprise sont rendues ; aucun rythme, aucune date, aucune duree pour l''enfant de 6 a 9 ans');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.jsonb_array_length(j -> 'etapes_du_cycle') = 4
          AND (SELECT pg_catalog.array_agg(x ->> 'statut' ORDER BY (x ->> 'ordre')::int)
                 FROM pg_catalog.jsonb_array_elements(j -> 'etapes_du_cycle') x)
              = ARRAY['franchie','franchie','franchie','en_cours']
          -- SOCLE-PROGRAMME : aucune date d'entree dans une etape, ni duree, pour l'enfant de 6 a 9 ans.
          AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(j -> 'etapes_du_cycle') x
                           WHERE x -> 'atteinte_le' <> 'null'::jsonb
                              OR x -> 'duree_prevue_semaines' <> 'null'::jsonb
                              OR x -> 'date_limite_semaines' <> 'null'::jsonb)
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : les 4 etapes du cycle dans l''ordre, trois franchies, la sienne en cours, sans aucune date ni duree (enfant de 6 a 9 ans)');
-- Ni la date de validation d'une sourate, ni la date de la reprise de la Classe, pour l'enfant de 6 a 9 ans.
SELECT pg_temp.vrai(
  (SELECT NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(j -> 'sourates' -> 'sourates') x WHERE x ? 'valide_le')
          AND j -> 'etape' -> 'page_reprise_le' = 'null'::jsonb
          AND (j -> 'etape' ->> 'page_reprise') IS NOT NULL
     FROM ma_sortie WHERE cle = 'e1'),
  'enfant de 6 a 9 ans : ni sourates[].valide_le ni etape.page_reprise_le (la page de reprise reste)');
-- Son tuteur lit la meme progression AVEC ses dates (l'eleve de moins de 10 ans les retient, pas lui).
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1-tuteur', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j -> 'etape' ->> 'rythme' IS NOT NULL AND j -> 'etape' ->> 'date_limite' IS NOT NULL
          AND j -> 'etape' ->> 'entree_le' IS NOT NULL
          AND (SELECT (x ->> 'atteinte_le') IS NOT NULL
                 FROM pg_catalog.jsonb_array_elements(j -> 'etapes_du_cycle') x WHERE (x ->> 'ordre')::int = 4)
          AND (SELECT (x ->> 'date_limite_semaines')::int = 9
                 FROM pg_catalog.jsonb_array_elements(j -> 'etapes_du_cycle') x WHERE (x ->> 'ordre')::int = 4)
     FROM ma_sortie WHERE cle = 'e1-tuteur'),
  'le tuteur de e1 recoit rythme, date limite, date d''entree et date d''entree dans l''etape 4, et la date limite de chaque etape');
SELECT pg_temp.vrai(
  (SELECT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(j -> 'sourates' -> 'sourates') x WHERE x ->> 'valide_le' IS NOT NULL)
          AND j -> 'etape' ->> 'page_reprise_le' IS NOT NULL
     FROM ma_sortie WHERE cle = 'e1-tuteur'),
  'le tuteur de e1 recoit sourates[].valide_le et etape.page_reprise_le');
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'sourates_total')::int = 17
          AND (j -> 'sourates' ->> 'sourates_validees')::int = 3
          AND pg_catalog.jsonb_array_length(j -> 'sourates' -> 'sourates') = 17
          AND (j -> 'sourates' -> 'sourates' -> 0 ->> 'numero')::int = 1
          AND (j -> 'sourates' -> 'sourates' -> 16 ->> 'numero')::int = 99
          AND (j -> 'sourates' -> 'sourates' -> 0 ->> 'nom') IS NOT NULL
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : 17 sourates des bases (Al-Fatiha puis 114 a 99), 3 validees, noms lus dans le corpus');
SELECT pg_temp.vrai(
  (SELECT (SELECT pg_catalog.array_agg((x ->> 'numero')::int ORDER BY (x ->> 'ordre')::int)
             FROM pg_catalog.jsonb_array_elements(j -> 'sourates' -> 'sourates') x
            WHERE (x ->> 'validee')::boolean) = ARRAY[1, 114, 113]
     FROM ma_sortie WHERE cle = 'e1'),
  'e1 : « acquises » = les sourates cochees par l''enseignant pour CET eleve (et non la position de la Classe)');
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

-- Aucune copie : la lecture est EXACTEMENT celle de sourates_eleve (meme porte, meme contenu).
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1-source', public.sourates_eleve(pg_temp.u('e1')));
RESET ROLE;
-- Pour le tuteur : EXACTEMENT sourates_eleve. Pour l'enfant de 6 a 9 ans qui lit pour lui-meme :
-- la meme chose moins `valide_le` (aucune date), rien d'autre.
SELECT pg_temp.vrai(
  (SELECT t.j -> 'sourates' = s.j
     FROM ma_sortie t, ma_sortie s WHERE t.cle = 'e1-tuteur' AND s.cle = 'e1-source')
  AND (SELECT m.j -> 'sourates' = pg_catalog.jsonb_set(s.j, '{sourates}',
                (SELECT pg_catalog.jsonb_agg(x - 'valide_le') FROM pg_catalog.jsonb_array_elements(s.j -> 'sourates') x))
         FROM ma_sortie m, ma_sortie s WHERE m.cle = 'e1' AND s.cle = 'e1-source'),
  'ma_progression place sourates_eleve telle quelle sous « sourates » (tuteur), moins valide_le pour l''enfant de 6 a 9 ans : aucune copie');

-- Un autre eleve de la meme Classe : AUCUNE sourate validee, la Classe n'y change rien.
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e2', public.ma_progression(pg_temp.u('e2')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'etape' ->> 'ordre')::int = 1
          AND (j -> 'sourates' ->> 'sourates_validees')::int = 0
          AND (j -> 'sourates' ->> 'sourates_total')::int = 17
     FROM ma_sortie WHERE cle = 'e2'),
  'e2 est dans la meme Classe (etape 4) mais a sa propre etape (1, son fait) et aucune sourate cochee : 0 sur 17, jamais la position de la Classe');

-- Sans Classe : autorise ; pas d'etape a montrer, mais les sourates VALIDEES de l'eleve sont
-- rendues quand meme (ce qu'il a acquis lui appartient).
INSERT INTO public.sourates_validees (student_id, sourate_numero, session_id, lesson_report_id, validee_par)
SELECT pg_temp.u('e3'), x, pg_temp.u('s1'), pg_catalog.md5('rapport-e3-' || x)::uuid, pg_temp.u('b1')
  FROM unnest(ARRAY[1, 114]) AS x;
SELECT pg_temp.qui(pg_temp.u('e3'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e3', public.ma_progression(pg_temp.u('e3')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j -> 'etape' = 'null'::jsonb AND j -> 'etapes_du_cycle' = '[]'::jsonb
          AND j -> 'reglage' = 'null'::jsonb
     FROM ma_sortie WHERE cle = 'e3'),
  'e3 sans Classe : ni etape, ni cycle, ni reglage, sans erreur');
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'sourates_validees')::int = 2
          AND (j -> 'sourates' ->> 'sourates_total')::int = 17
          AND (SELECT pg_catalog.array_agg((x ->> 'numero')::int ORDER BY (x ->> 'ordre')::int)
                 FROM pg_catalog.jsonb_array_elements(j -> 'sourates' -> 'sourates') x
                WHERE (x ->> 'validee')::boolean) = ARRAY[1, 114]
     FROM ma_sortie WHERE cle = 'e3'),
  'e3 sans Classe active, 2 sourates validees : elles sont rendues (2 sur 17, les bonnes)');
SELECT pg_temp.vrai(
  (SELECT NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(j -> 'sourates' -> 'sourates') x WHERE x ? 'valide_le')
     FROM ma_sortie WHERE cle = 'e3'),
  'e3 (enfant de 6 a 9 ans, sans Classe) : les sourates rendues n''ont aucune valide_le');

-- 2. Le reglage par la direction.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.regler_etape_progression('BASES-4', 2.5, 30);
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1b', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'reglage' ->> 'heures_revision_semaine')::numeric = 2.5 AND (j -> 'reglage' ->> 'repetitions_estimees')::int = 30
     FROM ma_sortie WHERE cle = 'e1b'),
  'reglage rempli par la direction : heures et repetitions lues par l''eleve');
-- Une sourate de plus cochee au cahier : l'eleve la voit.
INSERT INTO public.sourates_validees (student_id, sourate_numero, session_id, lesson_report_id, validee_par)
VALUES (pg_temp.u('e1'), 112, pg_temp.u('s1'), pg_catalog.md5('rapport-112')::uuid, pg_temp.u('b1'));
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1c', public.ma_progression(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'sourates_validees')::int = 4 FROM ma_sortie WHERE cle = 'e1c'),
  'une sourate de plus cochee au cahier : 4 sur 17 a la lecture suivante');
-- Une sourate retiree (CORRIGER-SOURATE) garde sa ligne mais ne compte plus, ni dans le hub, ni
-- dans la lecture unique de l'etape (SOCLE-PROGRAMME) : memes 3 sourates sur 17.
UPDATE public.sourates_validees SET retiree_le = pg_catalog.now(), retiree_par = pg_temp.u('b1')
 WHERE student_id = pg_temp.u('e1') AND sourate_numero = 113;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e1d', public.ma_progression(pg_temp.u('e1')));
INSERT INTO ma_sortie VALUES ('e1d-lecture', public.etape_eleve_lecture(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'sourates' ->> 'sourates_validees')::int = 3 FROM ma_sortie WHERE cle = 'e1d')
  AND (SELECT (j -> 'sourates' ->> 'validees')::int = 3 FROM ma_sortie WHERE cle = 'e1d-lecture'),
  'une sourate retiree ne compte plus : 3 sur 17 dans le hub ET dans la lecture unique de l''etape');
-- Quelle que soit l'etape de la Classe, les 17 sourates comptent (decision du directeur 11/11).
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM se_ids WHERE cle = 'n1') WHERE id = pg_temp.u('c1');
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e2b', public.ma_progression(pg_temp.u('e2')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'etape' ->> 'ordre')::int = 1 AND (j -> 'sourates' ->> 'sourates_total')::int = 17
     FROM ma_sortie WHERE cle = 'e2b'),
  'etape 1 : le total reste 17 (les 17 sourates des bases comptent a toute etape)');

-- -- 3. Gardes.
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
  pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', 1, 1)') = 'refus'
  AND pg_temp.essai('SELECT * FROM public.reglages_progression_admin()') = 'refus',
  'enseignant : ni ecriture ni lecture du reglage');
RESET ROLE;
-- Un eleve SANS Classe (e3) : dans cette branche, c'est sourates_eleve seul qui garde la porte.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e3'))) = 'ok',
  'eleve sans Classe : son tuteur lit');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e3'))) = 'refus',
  'eleve sans Classe : le tuteur d''un autre foyer est refuse');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e3'))) = 'refus',
  'eleve sans Classe : un enseignant est refuse');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e3'))) = 'refus',
  'eleve sans Classe : l''enseignant d''aucune Classe de lui est refuse');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e4'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e3'))) = 'refus',
  'eleve sans Classe : un autre eleve, meme du foyer, est refuse');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.ma_progression(%L)', pg_temp.u('e3'))) = 'refus',
  'eleve sans Classe : la direction est refusee comme pour les autres');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', 1, 1)') = 'refus'
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
  pg_temp.essai('SELECT public.regler_etape_progression(''NOPE'', 1, 1)') <> 'ok'
  AND pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', 0, 1)') <> 'ok'
  AND pg_temp.essai('SELECT public.regler_etape_progression(''BASES-4'', 1, 0)') <> 'ok',
  'direction : etape inconnue, heures nulles, repetitions nulles : refuses');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.reglages_progression_admin()) >= 1,
  'direction : lit les reglages');
RESET ROLE;
-- Droits.
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.ma_progression(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.ma_progression(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.ma_progression(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'SELECT'),
  'EXECUTE pour authenticated seul ; la table reste fermee');
-- Invariants de SEC-GARDE-4 (partie b, 20261123300100) : cette table naissant APRES lui, il ne la
-- verifie plus ; le scenario le prouve lui-meme pour public.programme_etape_reglages.
SELECT pg_temp.vrai(
  (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
    WHERE c.oid = 'public.programme_etape_reglages'::pg_catalog.regclass),
  'programme_etape_reglages : RLS activee');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'TRUNCATE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'TRUNCATE')
  AND NOT pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'REFERENCES')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'REFERENCES')
  AND NOT pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'TRIGGER')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'TRIGGER'),
  'programme_etape_reglages : aucun droit TRUNCATE, REFERENCES ni TRIGGER pour anon et authenticated');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'INSERT')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'INSERT')
  AND NOT pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'UPDATE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'UPDATE')
  AND NOT pg_catalog.has_table_privilege('anon', 'public.programme_etape_reglages', 'DELETE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.programme_etape_reglages', 'DELETE')
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                   WHERE schemaname = 'public' AND tablename = 'programme_etape_reglages'),
  'programme_etape_reglages : aucune ecriture sans politique (aucune politique, aucun droit d ecriture)');
-- La page de reprise et sa date viennent de la MEME adhesion (classe non terminee). e3 reste
-- membre d'une classe TERMINEE qui avait une reprise : ni la page, ni sa date ne sont rendues.
-- (e3, sans classe jusqu'ici, recoit d'abord une etape par une decision de la direction.)
INSERT INTO public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif, created_at)
VALUES (pg_temp.u('e3'), (SELECT id FROM se_ids WHERE cle = 'n2'), 'diagnostic_initial', pg_temp.u('a1'),
        'Diagnostic', pg_catalog.now() - interval '2 weeks');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES (pg_temp.u('c9'), pg_temp.u('b1'), 'enfant', 6, 'Classe terminee SE', 3, 18, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (pg_temp.u('c9'), pg_temp.u('e3'));
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES (pg_temp.u('s9'), pg_temp.u('b1'), pg_catalog.now() - interval '3 hours', pg_catalog.now() - interval '2 hours',
        'planned', pg_temp.u('c9'));
INSERT INTO public.classe_position_reprise(groupe_id, page, session_id, presentee_par)
SELECT pg_temp.u('c9'), page, pg_temp.u('s9'), pg_temp.u('b1') FROM ma_page;
UPDATE public.groupes SET ended_at = pg_catalog.now(), ended_by = pg_temp.u('a1'), end_reason = 'Classe terminee'
 WHERE id = pg_temp.u('c9');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO ma_sortie VALUES ('e3-tuteur', public.ma_progression(pg_temp.u('e3')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j -> 'etape' ->> 'ordre' IS NOT NULL
          AND j -> 'etape' -> 'page_reprise' = 'null'::jsonb
          AND j -> 'etape' -> 'page_reprise_le' = 'null'::jsonb
     FROM ma_sortie WHERE cle = 'e3-tuteur'),
  'eleve reste membre d''une classe terminee : ni la page de reprise, ni sa date (meme adhesion pour les deux)');

ROLLBACK;
