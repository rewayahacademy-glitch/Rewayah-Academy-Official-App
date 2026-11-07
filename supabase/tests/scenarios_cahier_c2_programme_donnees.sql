-- CAHIER-C2 (06/11/2026) : le programme en donnees. Migration 20261110600000.
-- a1 la direction ; b1 titulaire de la Classe c2 ; b3 enseignant etranger ;
-- e1 et e2 eleves de c2 (e1 en 6-9 ans, e2 adulte) ; e3 eleve hors Classe.
--   1. la direction preremplit un brouillon vide : 4 etapes completes ;
--      seconde proposition refusee (version non vide) ; enseignant refuse ;
--   2. modifier le contenu : valeurs invalides refusees, valeur juste ecrite ;
--   3. publication refusee tant qu'une etape est incomplete ;
--   4. publication de la version proposee ; plus aucune modification ;
--      la copie d'une version publiee emporte le contenu ;
--   5. etape des eleves d'une Classe : decision de niveau (e1, avec date
--      limite de sa tranche), sinon etape de la Classe (e2, sans date
--      limite) ; une decision sur un brouillon ne compte pas ;
--   6. etranger, eleve : lecture refusee ; droits des fonctions.
-- Echoue sans la migration (premier ROUGE : la fonction n'existe pas).
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

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
  $$ SELECT ('c2c20000-0000-4000-8000-0000000000' || p)::uuid $$;

-- Execute une instruction ; rend 'ok', 'refus' (42501) ou le message d'erreur.
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text) TO authenticated, anon;

CREATE TEMP TABLE c2_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON c2_ids TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'c2-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b3','e1','e2','e3']) AS x;
INSERT INTO public.households(id, timezone) VALUES (pg_temp.u('f1'), 'America/Toronto');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.role = 'student' THEN pg_temp.u('f1') END,
       x.prenom, 'C2', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','C2-ADM-01','admin','Direction'),
   ('b1','C2-ENS-01','teacher','Titulaire'),
   ('b3','C2-ENS-03','teacher','Etrangere'),
   ('e1','C2-ELV-01','student','Eleve un'),
   ('e2','C2-ELV-02','student','Eleve deux'),
   ('e3','C2-ELV-03','student','Eleve trois')) AS x(id, mat, role, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte)
VALUES (pg_temp.u('e1'), 'minor'::public.student_type, 'child'::public.interface_mode, 'enfant_6_9'),
       (pg_temp.u('e2'), 'autonomous'::public.student_type, 'standard'::public.interface_mode, 'adulte_18_plus'),
       (pg_temp.u('e3'), 'minor'::public.student_type, 'standard'::public.interface_mode, 'enfant_10_13');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c2'), pg_temp.u('b1'), 'enfant', 6, 'An-Nour C2', 1, 18, 'America/Toronto');
INSERT INTO public.groupe_membres(groupe_id, student_id)
VALUES (pg_temp.u('c2'), pg_temp.u('e1')), (pg_temp.u('c2'), pg_temp.u('e2'));

-- ------------------------------------------------------------------
-- 1. La proposition des bases
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO c2_ids VALUES ('v1', public.creer_version_programme(NULL));
SELECT pg_temp.vrai(public.preremplir_bases_programme((SELECT id FROM c2_ids WHERE cle = 'v1')) = 4,
  'direction : la proposition des bases remplit 4 etapes');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c
    WHERE c.complet AND c.cycle = 'Les bases'
      AND pg_catalog.cardinality(c.objectifs) BETWEEN 3 AND 5) = 4,
  'les 4 etapes proposees sont completes (3 a 5 objectifs, 4 tranches)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.sum((c.durees -> 'enfant_6_9' ->> 'prevue')::int)
     FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c) = 37
  AND (SELECT pg_catalog.sum((c.durees -> 'enfant_10_13' ->> 'prevue')::int)
     FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c) = 28
  AND (SELECT pg_catalog.sum((c.durees -> 'ado_14_17' ->> 'prevue')::int)
     FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c) = 24
  AND (SELECT pg_catalog.sum((c.durees -> 'adulte_18_plus' ->> 'prevue')::int)
     FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c) = 15,
  'la somme des durees prevues par etape egale le total decide des bases (37, 28, 24, 15)');
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.preremplir_bases_programme(%L)',
    (SELECT id FROM c2_ids WHERE cle = 'v1'))) LIKE 'version_non_vide%',
  'seconde proposition refusee : la version n''est plus vide');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.preremplir_bases_programme(%L)',
    (SELECT id FROM c2_ids WHERE cle = 'v1'))) = 'refus'
  AND pg_temp.essai(pg_catalog.format('SELECT * FROM public.programme_contenu_admin(%L)',
    (SELECT id FROM c2_ids WHERE cle = 'v1'))) = 'refus',
  'enseignant : ni proposition ni lecture du contenu de la direction');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Modifier le contenu d'une etape
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO c2_ids
SELECT 'n' || c.ordre, c.niveau_id
  FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a'',''b'',''c'',''d'',''e'',''f''], NULL, ''{}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n1'))) LIKE 'objectifs_trop_nombreux%',
  'six objectifs refuses');
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a''], NULL, ''{"enfant_6_9": {"prevue": 10, "limite": 8}}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n1'))) LIKE 'durees_invalides%'
  AND pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a''], NULL, ''{"martiens": {"prevue": 1, "limite": 2}}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n1'))) LIKE 'durees_invalides%',
  'date limite avant la duree prevue, tranche inconnue : refusees');
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a''], ''{"support": "mushaf", "page_debut": 600, "page_fin": 610}''::jsonb, ''{}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n4'))) LIKE 'plage_support_invalide%'
  AND pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a''], ''{"support": "autre"}''::jsonb, ''{}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n4'))) LIKE 'plage_support_invalide%',
  'plage hors du Mushaf, support inconnu : refuses');
SELECT public.modifier_contenu_niveau(
  (SELECT id FROM c2_ids WHERE cle = 'n4'),
  ARRAY['  Récite les sourates de l''étape  ', '', 'S''arrête aux fins de versets', 'Garde les sourates apprises'],
  '{"support": "mushaf", "page_debut": 599, "page_fin": 603}'::jsonb,
  (SELECT c.durees FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c
    WHERE c.ordre = 4));
SELECT pg_temp.vrai(
  (SELECT c.objectifs = ARRAY['Récite les sourates de l''étape', 'S''arrête aux fins de versets', 'Garde les sourates apprises']
          AND (c.plage_support ->> 'page_fin')::int = 603 AND c.complet
     FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v1')) c
    WHERE c.ordre = 4),
  'contenu juste ecrit : objectifs nettoyes, vides retires, plage du Mushaf retenue');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Publication refusee d'une version incomplete
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO c2_ids VALUES ('v2', public.creer_version_programme(NULL));
INSERT INTO c2_ids VALUES ('n21', public.ajouter_niveau_programme(
  (SELECT id FROM c2_ids WHERE cle = 'v2'), 'X-1', 'Etape sans contenu', 'Essai', 1, NULL));
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT public.publier_version_programme(%L, %L)',
    (SELECT id FROM c2_ids WHERE cle = 'v2'), 'essai')) LIKE 'programme_incomplet: Etape sans contenu%',
  'publication refusee : une etape sans objectifs ni durees, nommee dans le refus');
SELECT pg_temp.vrai(
  (SELECT v.statut FROM public.programme_versions_admin() v
    WHERE v.version_id = (SELECT id FROM c2_ids WHERE cle = 'v2')) = 'brouillon',
  'la version incomplete reste en brouillon');

-- ------------------------------------------------------------------
-- 4. Publication de la proposition, puis plus aucune modification
-- ------------------------------------------------------------------
SELECT public.publier_version_programme((SELECT id FROM c2_ids WHERE cle = 'v1'), 'Version 1 des bases');
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a'',''b'',''c''], NULL, ''{}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n1'))) LIKE 'version publiee%',
  'version publiee : son contenu ne se modifie plus');
INSERT INTO c2_ids VALUES ('v3', public.creer_version_programme((SELECT id FROM c2_ids WHERE cle = 'v1')));
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.programme_contenu_admin((SELECT id FROM c2_ids WHERE cle = 'v3')) c
    WHERE c.complet) = 4,
  'copie d''une version publiee : le contenu suit dans le nouveau brouillon');
-- e1 : decision de niveau a l'etape 2 publiee ; e2 : aucune decision.
SELECT public.decider_placement(pg_temp.u('e1'), (SELECT id FROM c2_ids WHERE cle = 'n2'), 'Diagnostic');
RESET ROLE;
UPDATE public.groupes SET programme_niveau_id = (SELECT id FROM c2_ids WHERE cle = 'n1')
 WHERE id = pg_temp.u('c2');

-- ------------------------------------------------------------------
-- 5. L'etape des eleves de la Classe
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT e.etape_nom = 'Lire avec les voyelles' AND e.etape_ordre = 2
          AND e.cohorte = 'enfant_6_9'
          AND e.duree_prevue_semaines = 14 AND e.date_limite_semaines = 18
          AND e.date_limite = (e.depuis + interval '18 weeks')::date
          AND pg_catalog.cardinality(e.objectifs) = 5
     FROM public.etapes_eleves_classe(pg_temp.u('c2')) e
    WHERE e.student_id = pg_temp.u('e1')),
  'titulaire : e1 a l''etape 2, 14 semaines prevues, date limite a 18 semaines de sa decision');
SELECT pg_temp.vrai(
  (SELECT e.etape_ordre = 1 AND e.cohorte = 'adulte_18_plus'
          AND e.duree_prevue_semaines = 3 AND e.depuis IS NULL AND e.date_limite IS NULL
     FROM public.etapes_eleves_classe(pg_temp.u('c2')) e
    WHERE e.student_id = pg_temp.u('e2')),
  'titulaire : e2 sans decision suit l''etape de la Classe, sans date limite supposee');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.etapes_eleves_classe(pg_temp.u('c2'))) = 2,
  'seuls les eleves actifs de la Classe sont rendus');
RESET ROLE;

-- Une decision posterieure sur une etape de brouillon ne compte pas.
-- (une minute plus tard : dans une meme transaction, now() ne bouge pas)
INSERT INTO public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif, created_at)
VALUES (pg_temp.u('e1'), (SELECT id FROM c2_ids WHERE cle = 'n21'), 'correction', pg_temp.u('a1'), 'essai',
        pg_catalog.now() + interval '1 minute');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (SELECT e.etape_ordre = 1 AND e.date_limite IS NULL
     FROM public.etapes_eleves_classe(pg_temp.u('c2')) e
    WHERE e.student_id = pg_temp.u('e1')),
  'direction : une decision sur un brouillon n''est pas montree, l''etape de la Classe la remplace');
RESET ROLE;

-- ------------------------------------------------------------------
-- 6. Refus et droits
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.etapes_eleves_classe(%L)', pg_temp.u('c2'))) = 'refus',
  'enseignant etranger : lecture refusee');
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  pg_temp.essai(pg_catalog.format('SELECT * FROM public.etapes_eleves_classe(%L)', pg_temp.u('c2'))) = 'refus'
  AND pg_temp.essai(pg_catalog.format(
    'SELECT public.modifier_contenu_niveau(%L, ARRAY[''a''], NULL, ''{}''::jsonb)',
    (SELECT id FROM c2_ids WHERE cle = 'n21'))) = 'refus',
  'eleve : ni lecture ni ecriture');
RESET ROLE;
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.preremplir_bases_programme(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.modifier_contenu_niveau(uuid, text[], jsonb, jsonb)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.etapes_eleves_classe(uuid)', 'EXECUTE')
  AND has_function_privilege('agent_ro', 'public.programme_contenu_admin(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.programme_c2_durees_completes(jsonb)', 'EXECUTE')
  AND NOT has_table_privilege('authenticated', 'public.programme_niveaux', 'UPDATE'),
  'droits : ecritures fermees a anon et agent_ro, aides privees, table fermee');

-- Garde positive (0067) : un compte valide dont le role est nul ne cree
-- aucune version (une garde negative le laisserait passer : NULL OR false).
SELECT pg_catalog.set_config('request.jwt.claim.sub', pg_temp.u('a1')::text, true);
SELECT pg_catalog.set_config('test.uid', pg_temp.u('a1')::text, true);
SELECT pg_catalog.set_config('request.jwt.claims', '{"aal": "aal1", "app_metadata": {}}', true);
SELECT pg_catalog.set_config('test.jwt', '{"aal": "aal1", "app_metadata": {}}', true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.app_role() IS NULL
  AND pg_temp.essai('SELECT public.creer_version_programme(NULL)') LIKE 'creation de version%',
  'role nul : creer_version_programme refuse (garde positive de production)');
RESET ROLE;

\o
ROLLBACK;
