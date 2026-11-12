-- SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026). Migration 20261123900000.
-- On rejoue l'installation en production : un brouillon v1 avec une seule
-- etape vide (`bases-lecture`, comme en production le 12/11), deux classes
-- actives sans etape, des eleves deja membres ; puis le semis de la migration
-- (private.semer_programme_bases, private.rattacher_classes_et_eleves).
-- a1 direction ; b1 titulaire de c1 ; b2 titulaire de c2 ; b3 enseignant
-- etranger ; t1 tuteur du foyer f1 ; t2 tuteur du foyer f2 ;
-- e1 (6-9 ans, f1) et e2 (10-13 ans, f1) membres de c1 avant le semis ;
-- e3 (adulte titulaire de son profil, role guardian, f3) membre de c2 ;
-- e4 (6-9 ans, f2) entre en classe apres le semis ; e5 (6-9 ans, f2) apres la v2.
--   1. programme publie, une seule version, 4 etapes a code stable, le brouillon
--      de production complete ; matieres, objectifs, niveau ;
--   2. sommes : durees prevues = 37/28/24/15, reperes = 48/36/31/20 ;
--   3. classes sans etape : etape 1 des bases ; classe neuve : idem ;
--   4. eleves deja presents et nouvel eleve : une etape, datee de l'entree ;
--      date limite = entree + 48 semaines (6-9 ans), 36 (10-13), 20 (adulte) ;
--   5. lecture unique : meme etape pour l'eleve, le tuteur, l'enseignant, la
--      direction ; refus pour un etranger ; pas de date limite a l'enfant de
--      6 a 9 ans qui lit pour lui-meme (son tuteur la recoit) ; 10-13 la voit ;
--   6. la correction par un geste existant de la direction (promotion) : etape 2,
--      meme date limite ; etapes_eleves_classe et suivi_pedagogique_eleve disent
--      la meme chose ;
--   7. publier une seconde version archive la premiere ; l'etape de l'eleve
--      reste la meme (meme code) ; un eleve qui entre ensuite recoit la v2 ;
--   8. publication refusee si les reperes ne font pas la date du niveau ;
--   9. droits : aucune lecture directe du fait ; anon refuse.
-- Echoue sans la migration (la fonction de semis n'existe pas). Tout est annule.
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
  $$ SELECT pg_catalog.md5('socle-programme-' || p)::uuid $$;

CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

CREATE FUNCTION pg_temp.lire(p_eleve text) RETURNS jsonb LANGUAGE sql AS
  $$ SELECT public.etape_eleve_lecture(pg_temp.u(p_eleve)) $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text), pg_temp.lire(text) TO authenticated, anon;

CREATE TEMP TABLE sp_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON sp_ids TO authenticated;
CREATE TEMP TABLE sp_lectures(qui text PRIMARY KEY, j jsonb);
GRANT ALL ON sp_lectures TO authenticated;

-- Aucune version publiee avant le semis (base nue : la migration n'a rien seme).
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.programme_versions WHERE statut = 'publiee'),
  'base nue : aucune version publiee avant le semis');

-- ------------------------------------------------------------------
-- Fixtures : l'etat de production du 12/11
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'sp-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b2','b3','t1','t2','e1','e2','e3','e4','e5']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f2'), 'America/Toronto'),
  (pg_temp.u('f3'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'SP', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','SP-ADM-01','admin',NULL,'Direction'),
   ('b1','SP-ENS-01','teacher',NULL,'Titulaire un'),
   ('b2','SP-ENS-02','teacher',NULL,'Titulaire deux'),
   ('b3','SP-ENS-03','teacher',NULL,'Etrangere'),
   ('t1','SP-TUT-01','guardian','f1','Tutrice'),
   ('t2','SP-TUT-02','guardian','f2','Autre'),
   ('e1','SP-ELV-01','student','f1','Eleve un'),
   ('e2','SP-ELV-02','student','f1','Eleve deux'),
   ('e3','SP-TIT-03','guardian','f3','Adulte'),
   ('e4','SP-ELV-04','student','f2','Eleve quatre'),
   ('e5','SP-ELV-05','student','f2','Eleve cinq')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e4'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9');
INSERT INTO public.student_profiles(profile_id, titulaire_profile_id, student_type, interface_mode, cohorte)
VALUES (pg_temp.u('e3'), pg_temp.u('e3'), 'autonomous', 'standard', 'adulte_18_plus');

-- Le brouillon de production : v1, une seule etape vide « bases-lecture ».
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO sp_ids VALUES ('v1', public.creer_version_programme(NULL));
INSERT INTO sp_ids VALUES ('n_prod', public.ajouter_niveau_programme(
  (SELECT id FROM sp_ids WHERE cle = 'v1'), 'bases-lecture', 'Les bases', 'Les bases', 1, NULL));
RESET ROLE;

-- Deux classes actives sans etape (le declencheur de classe neuve ne pose rien :
-- aucun programme publie), des eleves deja membres depuis 3 semaines.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour SP', 1, 18, 'America/Toronto'),
 (pg_temp.u('c2'), pg_temp.u('b2'), 'adulte', 6, 'Al-Huda SP', 2, 19, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now() - interval '3 weeks'),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now() - interval '3 weeks'),
 (pg_temp.u('c2'), pg_temp.u('e3'), pg_catalog.now() - interval '3 weeks');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.groupes WHERE id IN (pg_temp.u('c1'), pg_temp.u('c2'))
      AND programme_niveau_id IS NULL) = 2
  AND NOT EXISTS (SELECT 1 FROM public.eleve_etape_en_cours
                   WHERE student_id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'))),
  'avant le semis : classes sans etape, eleves sans etape (etat de production)');

-- ------------------------------------------------------------------
-- Le semis, comme a l'installation de la migration
-- ------------------------------------------------------------------
SELECT private.semer_programme_bases(
  (SELECT cree_par FROM public.programme_versions WHERE id = (SELECT id FROM sp_ids WHERE cle = 'v1')));
SELECT private.rattacher_classes_et_eleves();

-- ------------------------------------------------------------------
-- 1. Le programme publie
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.programme_versions WHERE statut = 'publiee') = 1
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM sp_ids WHERE cle = 'v1')) = 'publiee',
  'une seule version publiee : le brouillon de production, complete puis publie');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(n.code_technique ORDER BY n.ordre)
     FROM public.programme_niveaux n WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1'))
    = ARRAY['BASES-1','BASES-2','BASES-3','BASES-4']
  AND (SELECT code_technique FROM public.programme_niveaux WHERE id = (SELECT id FROM sp_ids WHERE cle = 'n_prod')) = 'BASES-1',
  '4 etapes a code stable ; la ligne bases-lecture de production est devenue BASES-1 (rien n''est retire)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(n.nom_humain ORDER BY n.ordre)
     FROM public.programme_niveaux n WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1'))
    = ARRAY['Les lettres','Lire avec les voyelles','Lire dans le Coran',
            'Les sourates courtes, d''Al-Masad à Az-Zalzalah']
  AND NOT EXISTS (SELECT 1 FROM public.programme_niveaux n
                   WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1')
                     AND (pg_catalog.cardinality(n.objectifs) NOT BETWEEN 3 AND 5
                          OR n.cycle_code IS DISTINCT FROM 'bases' OR n.cycle IS DISTINCT FROM 'Les bases')),
  'noms decides des 4 etapes, 3 a 5 objectifs chacune, niveau « les bases »');
SELECT pg_temp.vrai(
  (SELECT n.matieres -> 'enfant_6_9' ->> 'secondaire' IS NULL
          AND n.matieres -> 'enfant_10_13' ->> 'secondaire' LIKE 'Al-Fatiha dès la première semaine%'
     FROM public.programme_niveaux n
    WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1') AND n.code_technique = 'BASES-1')
  AND (SELECT n.matieres -> 'enfant_6_9' ->> 'secondaire' LIKE 'Al-Fatiha, puis An-Nâs%'
     FROM public.programme_niveaux n
    WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1') AND n.code_technique = 'BASES-3')
  AND (SELECT n.matieres -> 'adulte_18_plus' ->> 'principale' LIKE 'Le Coran%'
     FROM public.programme_niveaux n
    WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1') AND n.code_technique = 'BASES-4'),
  'matieres : 6-9 ans le livre seul jusqu''a la chadda ; 10 ans et plus Al-Fatiha des la premiere semaine ; le Coran principal a l''etape 4');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM private.sourates_des_bases) = 17,
  'les 17 sourates des bases (source unique SOURATES)');

-- ------------------------------------------------------------------
-- 2. Les sommes, pour les quatre tranches
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT pg_catalog.bool_and(
            (SELECT pg_catalog.sum((n.durees -> t.coh ->> 'prevue')::int) FROM public.programme_niveaux n
              WHERE n.version_id = cy.version_id AND n.cycle_code = cy.code) = (cy.durees -> t.coh ->> 'prevue')::int
        AND (SELECT pg_catalog.sum((n.durees -> t.coh ->> 'limite')::int) FROM public.programme_niveaux n
              WHERE n.version_id = cy.version_id AND n.cycle_code = cy.code) = (cy.durees -> t.coh ->> 'limite')::int)
     FROM public.programme_cycles cy
    CROSS JOIN (VALUES ('enfant_6_9'), ('enfant_10_13'), ('ado_14_17'), ('adulte_18_plus')) AS t(coh)
    WHERE cy.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1') AND cy.code = 'bases'),
  'somme des durees prevues = duree du niveau, somme des reperes = date limite du niveau, 4 tranches');
SELECT pg_temp.vrai(
  (SELECT cy.durees FROM public.programme_cycles cy
    WHERE cy.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1') AND cy.code = 'bases')
  = '{"enfant_6_9": {"prevue": 37, "limite": 48}, "enfant_10_13": {"prevue": 28, "limite": 36},
      "ado_14_17": {"prevue": 24, "limite": 31}, "adulte_18_plus": {"prevue": 15, "limite": 20}}'::jsonb,
  'niveau des bases : 37/28/24/15 semaines prevues, date limite 48/36/31/20 (decide le 14/10)');

-- ------------------------------------------------------------------
-- 3. Les classes recoivent les bases
-- ------------------------------------------------------------------
INSERT INTO sp_ids SELECT 'n' || n.ordre, n.id FROM public.programme_niveaux n
 WHERE n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v1');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.groupes
    WHERE id IN (pg_temp.u('c1'), pg_temp.u('c2'))
      AND programme_niveau_id = (SELECT id FROM sp_ids WHERE cle = 'n1')) = 2,
  'chaque classe active sans etape recoit l''etape 1 des bases');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c3'), pg_temp.u('b1'), 'enfant', 5, 'Ar-Rahma SP', 3, 17, 'America/Toronto');
SELECT pg_temp.vrai(
  (SELECT programme_niveau_id FROM public.groupes WHERE id = pg_temp.u('c3')) = (SELECT id FROM sp_ids WHERE cle = 'n1'),
  'une classe neuve recoit seule l''etape 1 des bases');

-- ------------------------------------------------------------------
-- 4. Chaque eleve a une etape, datee de son entree
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.eleve_etape_en_cours f
    WHERE f.student_id IN (pg_temp.u('e1'), pg_temp.u('e2'), pg_temp.u('e3'))
      AND f.niveau_id = (SELECT id FROM sp_ids WHERE cle = 'n1')
      AND f.entree_etape_le = (pg_catalog.now() - interval '3 weeks')::date
      AND f.entree_niveau_le = f.entree_etape_le AND f.origine = 'classe' AND f.recul_jours = 0) = 3,
  'eleves deja presents : etape 1, entree = date d''entree en classe');
SELECT pg_temp.vrai(
  (SELECT f.date_limite_niveau = (f.entree_niveau_le + interval '48 weeks')::date
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e1'))
  AND (SELECT f.date_limite_niveau = (f.entree_niveau_le + interval '36 weeks')::date
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e2'))
  AND (SELECT f.date_limite_niveau = (f.entree_niveau_le + interval '20 weeks')::date
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e3')),
  'date limite du niveau : entree + 48 (6-9), 36 (10-13), 20 semaines (adulte)');
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (pg_temp.u('c3'), pg_temp.u('e4'));
SELECT pg_temp.vrai(
  (SELECT f.niveau_id = (SELECT id FROM sp_ids WHERE cle = 'n1') AND f.entree_etape_le = pg_catalog.now()::date
          AND f.cohorte = 'enfant_6_9'
     FROM public.eleve_etape_en_cours f WHERE f.student_id = pg_temp.u('e4')),
  'nouvel eleve : etape posee seule a l''entree en classe, datee du jour');

-- ------------------------------------------------------------------
-- 5. La lecture unique, pour tous les roles
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO sp_lectures VALUES ('eleve', pg_temp.lire('e2'));
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO sp_lectures VALUES ('tuteur', pg_temp.lire('e2'));
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO sp_lectures VALUES ('enseignant', pg_temp.lire('e2'));
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO sp_lectures VALUES ('direction', pg_temp.lire('e2'));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(DISTINCT j -> 'etape') = 1 AND pg_catalog.count(DISTINCT j -> 'niveau') = 1
          AND pg_catalog.count(DISTINCT j -> 'chemin') = 1 AND pg_catalog.count(*) = 4
     FROM sp_lectures),
  'eleve (10-13), tuteur, enseignant, direction : la meme etape, le meme niveau, le meme chemin');
SELECT pg_temp.vrai(
  (SELECT j #>> '{etape,code}' = 'BASES-1' AND (j #>> '{etape,ordre}')::int = 1
          AND j #>> '{niveau,cohorte}' = 'enfant_10_13'
          AND (j #>> '{niveau,date_limite_semaines}')::int = 36
          AND (j #>> '{niveau,date_limite}')::date = (pg_catalog.now() - interval '3 weeks' + interval '36 weeks')::date
          AND (j #>> '{niveau,date_limite_visible}')::boolean
          AND (j #>> '{etape,duree_prevue_semaines}')::int = 6 AND (j #>> '{etape,repere_semaines}')::int = 8
          AND (j #>> '{etape,entree_le}')::date = (pg_catalog.now() - interval '3 weeks')::date
          AND pg_catalog.jsonb_array_length(j -> 'chemin') = 4
          AND j #>> '{chemin,0,statut}' = 'en_cours' AND j #>> '{chemin,3,statut}' = 'a_venir'
          AND (SELECT pg_catalog.sum((x ->> 'repere_semaines')::int)
                 FROM pg_catalog.jsonb_array_elements(j -> 'chemin') x) = 36
          AND pg_catalog.jsonb_array_length(j #> '{chemin,1,objectifs}') = 5
          AND (j #>> '{sourates,total}')::int = 17 AND (j #>> '{sourates,validees}')::int = 0
     FROM sp_lectures WHERE qui = 'eleve'),
  'contenu : etape 1, entree, duree prevue et repere de SA tranche, chemin des 4 etapes avec objectifs, reperes = 36, date limite, 17 sourates');

-- L'enfant de 6 a 9 ans ne recoit pas la date limite ; son tuteur la recoit.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT j #>> '{etape,code}' = 'BASES-1'
          AND j #> '{niveau,date_limite}' = 'null'::jsonb
          AND j #> '{niveau,date_limite_semaines}' = 'null'::jsonb
          AND NOT (j #>> '{niveau,date_limite_visible}')::boolean
          AND j #> '{etape,rythme}' = 'null'::jsonb
          AND pg_catalog.jsonb_array_length(j -> 'chemin') = 4
     FROM (SELECT pg_temp.lire('e1') AS j) l),
  'enfant de 6-9 ans : son etape et son chemin, ni date limite ni rythme');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT (j #>> '{niveau,date_limite}')::date = (pg_catalog.now() - interval '3 weeks' + interval '48 weeks')::date
     FROM (SELECT pg_temp.lire('e1') AS j) l),
  'son tuteur recoit la date limite de l''enfant (48 semaines)');
RESET ROLE;
-- L'adulte titulaire de son profil la voit.
SELECT pg_temp.qui(pg_temp.u('e3'), 'guardian', pg_temp.u('f3'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT (j #>> '{niveau,date_limite_semaines}')::int = 20 AND (j #>> '{niveau,date_limite_visible}')::boolean
     FROM (SELECT pg_temp.lire('e3') AS j) l),
  'adulte titulaire de son profil : sa date limite (20 semaines)');
RESET ROLE;

-- Refus pour un etranger.
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT pg_temp.lire(''e2'')') = 'refus',
  'tuteur d''un autre foyer : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT pg_temp.lire(''e2'')') = 'refus',
  'enseignant etranger a la classe : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT pg_temp.lire(''e2'')') = 'refus'
  AND (SELECT j #>> '{etape,code}' = 'BASES-1' FROM (SELECT pg_temp.lire('e3') AS j) l),
  'titulaire d''une autre classe : refus pour e2, lecture de son propre eleve e3');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT pg_temp.lire(''e2'')') = 'refus',
  'un autre eleve, meme du foyer : refus');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), NULL, pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT pg_temp.lire(''e2'')') = 'refus',
  'role nul : refus');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(pg_temp.essai('SELECT public.etape_eleve_lecture(''00000000-0000-0000-0000-000000000000'')') = 'refus',
  'anon : refus');
RESET ROLE;

-- ------------------------------------------------------------------
-- 6. La direction corrige par un geste existant
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.decider_placement(pg_temp.u('e2'), (SELECT id FROM sp_ids WHERE cle = 'n1'), 'Entretien de lecture');
SELECT public.progression_promouvoir(pg_temp.u('e2'), (SELECT id FROM sp_ids WHERE cle = 'n2'), 'Petit bilan valide');
SELECT pg_temp.vrai(
  (SELECT j #>> '{etape,code}' = 'BASES-2' AND (j #>> '{etape,entree_le}')::date = pg_catalog.now()::date
          AND (j #>> '{niveau,date_limite}')::date = (pg_catalog.now() - interval '3 weeks' + interval '36 weeks')::date
          AND j #>> '{chemin,0,statut}' = 'franchie' AND j #>> '{chemin,1,statut}' = 'en_cours'
     FROM (SELECT pg_temp.lire('e2') AS j) l),
  'promotion par la direction : etape 2 des aujourd''hui, la date limite du niveau ne change pas');
SELECT pg_temp.vrai(
  (SELECT e.etape_ordre = 2 AND e.date_limite = (pg_catalog.now() - interval '3 weeks' + interval '36 weeks')::date
     FROM public.etapes_eleves_classe(pg_temp.u('c1')) e WHERE e.student_id = pg_temp.u('e2')),
  'etapes_eleves_classe (enseignant, direction) rend la meme etape et la meme date (source unique)');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT s.etape_ordre = 2 AND s.date_limite = (pg_catalog.now() - interval '3 weeks' + interval '36 weeks')::date
     FROM public.suivi_pedagogique_eleve(pg_temp.u('e2')) s),
  'suivi_pedagogique_eleve (ancienne lecture) rend aussi la meme etape');
RESET ROLE;

-- ------------------------------------------------------------------
-- 7. Une seconde version archive la premiere ; l'etape reste la meme
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO sp_ids VALUES ('v2', public.creer_version_programme((SELECT id FROM sp_ids WHERE cle = 'v1')));
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.programme_contenu_admin((SELECT id FROM sp_ids WHERE cle = 'v2')) c
    WHERE c.complet) = 4,
  'copie de la v1 : les 4 etapes suivent dans le brouillon v2');
SELECT public.publier_version_programme((SELECT id FROM sp_ids WHERE cle = 'v2'), 'Version 2 des bases');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM sp_ids WHERE cle = 'v1')) = 'archivee'
  AND (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM sp_ids WHERE cle = 'v2')) = 'publiee'
  AND (SELECT pg_catalog.count(*) FROM public.programme_versions WHERE statut = 'publiee') = 1,
  'publier la v2 archive la v1 : une seule version publiee');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT j #>> '{etape,code}' = 'BASES-2' AND (j #>> '{version,numero}')::int = 1
          AND j #>> '{version,statut}' = 'archivee'
     FROM (SELECT pg_temp.lire('e2') AS j) l)
  AND (SELECT j #>> '{etape,code}' = 'BASES-1' FROM (SELECT pg_temp.lire('e1') AS j) l),
  'apres la v2 : e2 reste a BASES-2 et e1 a BASES-1, dans leur version (code stable)');
RESET ROLE;
INSERT INTO public.groupe_membres(groupe_id, student_id) VALUES (pg_temp.u('c3'), pg_temp.u('e5'));
SELECT pg_temp.vrai(
  (SELECT n.code_technique = 'BASES-1' AND n.version_id = (SELECT id FROM sp_ids WHERE cle = 'v2')
     FROM public.eleve_etape_en_cours f JOIN public.programme_niveaux n ON n.id = f.niveau_id
    WHERE f.student_id = pg_temp.u('e5')),
  'un eleve qui entre apres la v2 recoit BASES-1 de la v2 (classe resolue par son code)');

-- ------------------------------------------------------------------
-- 8. Publication refusee si les reperes ne font pas la date du niveau
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO sp_ids VALUES ('v3', public.creer_version_programme((SELECT id FROM sp_ids WHERE cle = 'v2')));
SELECT public.modifier_contenu_niveau(c.niveau_id, c.objectifs, c.plage_support,
         pg_catalog.jsonb_set(c.durees, '{enfant_6_9,limite}', '11'::jsonb))
  FROM public.programme_contenu_admin((SELECT id FROM sp_ids WHERE cle = 'v3')) c WHERE c.ordre = 1;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.publier_version_programme(%L, %L)',
    (SELECT id FROM sp_ids WHERE cle = 'v3'), 'essai')) LIKE 'programme_incoherent%',
  'reperes 6-9 ans a 49 semaines au lieu de 48 : publication refusee');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT statut FROM public.programme_versions WHERE id = (SELECT id FROM sp_ids WHERE cle = 'v2')) = 'publiee',
  'la v2 reste publiee apres le refus');

-- ------------------------------------------------------------------
-- 9. Droits
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai('SELECT * FROM public.eleve_etape_en_cours') = 'refus',
  'direction : aucune lecture directe du fait (seulement par la lecture unique)');
SELECT pg_temp.vrai(pg_temp.essai(pg_catalog.format('SELECT private.semer_programme_bases(%L)', pg_temp.u('a1'))) = 'refus',
  'le semis n''est ouvert a personne');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.etape_eleve_lecture(uuid)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.etape_eleve_lecture(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'public.eleve_etape_en_cours', 'SELECT')
  AND (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
         FROM pg_catalog.pg_proc p WHERE p.oid = 'public.etape_eleve_lecture(uuid)'::pg_catalog.regprocedure),
  'etape_eleve_lecture : DEFINER, search_path vide, EXECUTE a authenticated seul');

\o
SELECT 'scenarios_socle_programme : tous les controles sont verts' AS resultat;
ROLLBACK;
