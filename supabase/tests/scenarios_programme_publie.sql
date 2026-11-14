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

-- PROGRAMME-PUBLIE (14/11/2026) : public.programme_publie(uuid). Migration
-- 20261125600000_programme_publie.sql. ROUGE sans la migration ; VERT avec. Tout est annule a la fin.
--   1. la version publiee seulement (un brouillon ne sort pas) ; cycles et etapes avec objectifs ;
--   2. l'enfant de 6 a 9 ans qui lit pour lui-meme : aucune duree ; son tuteur et l'adulte : les durees ;
--   3. sans eleve nomme : aucune matiere, aucune duree ;
--   4. aucune donnee personnelle ; gardes : anon refuse, autre foyer refuse, droits d'execution.
CREATE TEMP TABLE pp_sortie(cle text PRIMARY KEY, j jsonb);
GRANT ALL ON pp_sortie TO authenticated;

-- Un brouillon de plus, ouvert apres la publication : il ne doit pas sortir.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO se_ids VALUES ('v2', public.creer_version_programme((SELECT id FROM se_ids WHERE cle = 'v1')));
RESET ROLE;

-- 1. L'eleve de 6 a 9 ans, pour lui-meme.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO pp_sortie VALUES ('e1', public.programme_publie(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j -> 'version' ->> 'numero' = (SELECT numero_version::text FROM public.programme_versions
                                            WHERE id = (SELECT id FROM se_ids WHERE cle = 'v1'))
          AND pg_catalog.jsonb_array_length(j -> 'cycles') >= 1
          AND pg_catalog.jsonb_array_length(j -> 'cycles' -> 0 -> 'etapes') = 4
          AND j -> 'cycles' -> 0 -> 'etapes' -> 0 ->> 'nom' IS NOT NULL
          AND pg_catalog.jsonb_array_length(j -> 'cycles' -> 0 -> 'etapes' -> 0 -> 'objectifs') >= 1
     FROM pp_sortie WHERE cle = 'e1'),
  'e1 : la version publiee (pas le brouillon), un cycle, quatre etapes avec nom et objectifs');
SELECT pg_temp.vrai(
  (SELECT j -> 'eleve_voit_dates' = 'false'::jsonb
          AND j -> 'cycles' -> 0 -> 'duree_prevue_semaines' = 'null'::jsonb
          AND j -> 'cycles' -> 0 -> 'date_limite_semaines' = 'null'::jsonb
          AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(j -> 'cycles' -> 0 -> 'etapes') x
                           WHERE x -> 'duree_prevue_semaines' <> 'null'::jsonb
                              OR x -> 'date_limite_semaines' <> 'null'::jsonb)
     FROM pp_sortie WHERE cle = 'e1'),
  'e1 (6 a 9 ans, pour lui-meme) : aucune duree, aucune date limite, ni sur le cycle ni sur les etapes');
SELECT pg_temp.vrai(
  (SELECT j -> 'cycles' -> 0 -> 'etapes' -> 0 ->> 'matiere_principale' IS NOT NULL
     FROM pp_sortie WHERE cle = 'e1'),
  'e1 : les matieres de sa tranche sont rendues');

-- 2. Son tuteur : les durees.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO pp_sortie VALUES ('e1-tuteur', public.programme_publie(pg_temp.u('e1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT (j -> 'cycles' -> 0 ->> 'duree_prevue_semaines')::int = 37
          AND (j -> 'cycles' -> 0 ->> 'date_limite_semaines')::int = 48
          AND (j -> 'cycles' -> 0 -> 'etapes' -> 1 ->> 'duree_prevue_semaines')::int = 14
          AND (j -> 'cycles' -> 0 -> 'etapes' -> 1 ->> 'date_limite_semaines')::int = 19
     FROM pp_sortie WHERE cle = 'e1-tuteur'),
  'le tuteur de e1 recoit les durees du cycle (37 / 48) et de l''etape 2 (14 / 19, tranche 6 a 9 ans)');

-- 3. L'adulte, pour lui-meme.
SELECT pg_temp.qui(pg_temp.u('g1'), 'guardian', pg_temp.u('f3'));
SET LOCAL ROLE authenticated;
INSERT INTO pp_sortie VALUES ('g1', public.programme_publie(pg_temp.u('g1')));
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT j -> 'eleve_voit_dates' = 'true'::jsonb
          AND (j -> 'cycles' -> 0 ->> 'duree_prevue_semaines') IS NOT NULL
          AND (j -> 'cycles' -> 0 -> 'etapes' -> 0 ->> 'duree_prevue_semaines') IS NOT NULL
     FROM pp_sortie WHERE cle = 'g1'),
  'l''adulte lit le programme avec les durees de sa tranche');

-- 4. Sans eleve nomme : aucune matiere, aucune duree.
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO pp_sortie VALUES ('sans-eleve', public.programme_publie());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.jsonb_array_length(j -> 'cycles' -> 0 -> 'etapes') = 4
          AND j -> 'cycles' -> 0 -> 'etapes' -> 0 -> 'matiere_principale' = 'null'::jsonb
          AND j -> 'cycles' -> 0 -> 'duree_prevue_semaines' = 'null'::jsonb
          AND j -> 'cycles' -> 0 -> 'etapes' -> 0 -> 'duree_prevue_semaines' = 'null'::jsonb
          AND j -> 'eleve_voit_dates' = 'null'::jsonb
     FROM pp_sortie WHERE cle = 'sans-eleve'),
  'sans eleve nomme : les etapes et objectifs, aucune matiere, aucune duree');

-- 5. Aucune donnee personnelle ni place : trois cles, pas d'identifiant d'eleve ni de nom.
SELECT pg_temp.vrai(
  (SELECT (SELECT pg_catalog.array_agg(k ORDER BY k) FROM pg_catalog.jsonb_object_keys(j) k)
            = ARRAY['cycles', 'eleve_voit_dates', 'version']
          AND j::text NOT LIKE '%' || pg_temp.u('e1')::text || '%'
          AND j::text NOT LIKE '%Eleve un%'
     FROM pp_sortie WHERE cle = 'e1-tuteur'),
  'la lecture ne porte ni identifiant ni nom d''eleve, ni place : version, eleve_voit_dates, cycles');

-- 6. Gardes.
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.programme_publie(pg_temp.u(''e1''))') = 'refus',
  'le tuteur d''un autre foyer n''ouvre pas la lecture d''un eleve');
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.programme_publie()') = 'ok',
  'un tuteur lit le programme sans eleve nomme');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.programme_publie(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.programme_publie(uuid)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.programme_publie(uuid)', 'EXECUTE'),
  'anon et agent_ro n''executent pas la lecture ; authenticated oui');
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(
  pg_temp.essai('SELECT public.programme_publie()') = 'refus',
  'anon est refuse');
RESET ROLE;

ROLLBACK;
