-- NIV1-reprise (03/11/2026, migration 20261107000000, regle G12) : la reprise
-- des profils eleves existants, rejouee sur des profils de ce scenario.
--   p1 : fiche deja complete sans onboarding -> marquee remplie, rien d'autre.
--   p2 : fiche vide, reponses sur la demande liee -> reprises, remplie.
--   p3 : niveau et langue sur la demande liee, sans objectif -> repris, la
--        fiche reste a completer (pas d'onboarding).
--   p4 : rien de connu -> intact, aucune ligne de reprise.
--   p5 : deja rempli -> intact.
--   t1 : titulaire dont le profil eleve est ne apres ses reponses -> reprises.
-- Un second appel ne touche plus rien. Les valeurs d'avant sont gardees.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'NIV1R ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('b2000000-0000-4000-8000-0000000000f1', 'niv1r-tuteur@example.test'),
  ('b2000000-0000-4000-8000-000000000001', 'niv1r-p1@example.test'),
  ('b2000000-0000-4000-8000-000000000002', 'niv1r-p2@example.test'),
  ('b2000000-0000-4000-8000-000000000003', 'niv1r-p3@example.test'),
  ('b2000000-0000-4000-8000-000000000004', 'niv1r-p4@example.test'),
  ('b2000000-0000-4000-8000-000000000005', 'niv1r-p5@example.test');

-- La famille s'inscrit (vraie fonction) : deux enfants de la demande, et le
-- titulaire qui suit des cours.
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('request.jwt.claim.sub', 'b2000000-0000-4000-8000-0000000000f1', true);
SELECT set_config('test.uid', 'b2000000-0000-4000-8000-0000000000f1', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Reprise', 'female', 'Europe/Paris', false,
  '[{"prenom": "Deux", "age": 9, "genre": "female", "niveau": "lecture_lente",
     "objectif": "devenir_fluide", "moments": ["soir"], "langue": "francais"},
    {"prenom": "Trois", "age": 8, "genre": "male", "niveau": "debut_lettres",
     "moments": ["matin"], "langue": "francais"}]'::jsonb);
RESET ROLE;

-- Les profils eleves, comme avant NIV1 (aucun onboarding_fait_le).
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
SELECT v.id, v.imm, 'student', p.household_id, v.prenom, 'Reprise', 'active'
  FROM public.profiles p,
       (VALUES ('b2000000-0000-4000-8000-000000000001'::uuid, 'NIV1R00000000001', 'Un'),
               ('b2000000-0000-4000-8000-000000000002'::uuid, 'NIV1R00000000002', 'Deux'),
               ('b2000000-0000-4000-8000-000000000003'::uuid, 'NIV1R00000000003', 'Trois'),
               ('b2000000-0000-4000-8000-000000000004'::uuid, 'NIV1R00000000004', 'Quatre'),
               ('b2000000-0000-4000-8000-000000000005'::uuid, 'NIV1R00000000005', 'Cinq'))
         AS v(id, imm, prenom)
 WHERE p.id = 'b2000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy, cohorte, niveau_declare, objectif, langue_cours, onboarding_fait_le)
SELECT v.id, 'minor', 'child', 'forbidden',
       (SELECT c.code FROM public.cohortes_age c
         WHERE c.actif AND c.type_public = 'enfant' AND 9 BETWEEN c.age_min AND coalesce(c.age_max_inclus, 999)
         ORDER BY c.ordre LIMIT 1),
       v.niveau, v.objectif, v.langue, v.fait
  FROM (VALUES
    ('b2000000-0000-4000-8000-000000000001'::uuid, 'lecture_courante', 'memoriser', 'francais', NULL::timestamptz),
    ('b2000000-0000-4000-8000-000000000002'::uuid, NULL, NULL, NULL, NULL),
    ('b2000000-0000-4000-8000-000000000003'::uuid, NULL, NULL, NULL, NULL),
    ('b2000000-0000-4000-8000-000000000004'::uuid, NULL, NULL, NULL, NULL),
    ('b2000000-0000-4000-8000-000000000005'::uuid, 'debut_lettres', 'apprendre_a_lire', 'francais',
       '2026-10-01 10:00+00'::timestamptz)) AS v(id, niveau, objectif, langue, fait);

-- Des liaisons anciennes, posees avant NIV1 sans recopie.
UPDATE public.candidature_apprenants a SET profil_eleve_id = 'b2000000-0000-4000-8000-000000000002'
  FROM public.candidatures c
 WHERE c.id = a.candidature_id AND c.profile_id = 'b2000000-0000-4000-8000-0000000000f1' AND a.prenom = 'Deux';
UPDATE public.candidature_apprenants a SET profil_eleve_id = 'b2000000-0000-4000-8000-000000000003'
  FROM public.candidatures c
 WHERE c.id = a.candidature_id AND c.profile_id = 'b2000000-0000-4000-8000-0000000000f1' AND a.prenom = 'Trois';

-- Le titulaire : ses reponses pour lui-meme existent, son profil eleve nait
-- apres (le declencheur NIV1 n'a donc rien pu reprendre).
INSERT INTO public.candidature_apprenants
  (candidature_id, rang, est_titulaire, prenom, age, genre, niveau_declare, objectif, moments, langue_code)
SELECT c.id, 3, true, 'Fixture', NULL, 'female', 'lecture_courante', 'memoriser', '{soir}', 'francais'
  FROM public.candidatures c WHERE c.profile_id = 'b2000000-0000-4000-8000-0000000000f1';
INSERT INTO public.student_profiles
  (profile_id, titulaire_profile_id, student_type, interface_mode, camera_policy, cohorte)
VALUES ('b2000000-0000-4000-8000-0000000000f1', 'b2000000-0000-4000-8000-0000000000f1',
        'autonomous', 'standard', 'forbidden', 'adulte_18_plus');

DO $reprise$
DECLARE
  v_r jsonb;
  v_sp public.student_profiles;
  v_av private.niv1_reprise_avant;
BEGIN
  v_r := private.niv1_reprendre_profils();
  RAISE NOTICE 'NIV1R premier appel : %', v_r;

  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = 'b2000000-0000-4000-8000-000000000001';
  IF v_sp.onboarding_fait_le IS NULL OR v_sp.niveau_declare <> 'lecture_courante' THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p1 (fiche complete) non marque rempli : %', row_to_json(v_sp);
  END IF;
  SELECT * INTO v_av FROM private.niv1_reprise_avant WHERE profile_id = 'b2000000-0000-4000-8000-000000000001';
  IF v_av.profile_id IS NULL OR NOT v_av.onboarding_pose OR v_av.niveau_declare <> 'lecture_courante' THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p1 sans valeur d''avant';
  END IF;
  RAISE NOTICE 'NIV1R OK : p1, fiche deja complete, marquee remplie, valeur d''avant gardee';

  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = 'b2000000-0000-4000-8000-000000000002';
  IF v_sp.onboarding_fait_le IS NULL OR v_sp.niveau_declare IS DISTINCT FROM 'lecture_lente'
     OR v_sp.objectif IS DISTINCT FROM 'devenir_fluide' OR v_sp.langue_cours IS DISTINCT FROM 'francais' THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p2, reponses de la demande non reprises : %', row_to_json(v_sp);
  END IF;
  SELECT * INTO v_av FROM private.niv1_reprise_avant WHERE profile_id = 'b2000000-0000-4000-8000-000000000002';
  IF v_av.profile_id IS NULL OR v_av.niveau_declare IS NOT NULL THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p2, valeur d''avant (vide) absente';
  END IF;
  RAISE NOTICE 'NIV1R OK : p2, reponses de la demande reprises, fiche remplie';

  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = 'b2000000-0000-4000-8000-000000000003';
  IF v_sp.onboarding_fait_le IS NOT NULL OR v_sp.niveau_declare IS DISTINCT FROM 'debut_lettres'
     OR v_sp.langue_cours IS DISTINCT FROM 'francais' OR v_sp.objectif IS NOT NULL THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p3 (sans objectif) mal repris : %', row_to_json(v_sp);
  END IF;
  RAISE NOTICE 'NIV1R OK : p3, niveau et langue repris, fiche a completer (aucun objectif invente)';

  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = 'b2000000-0000-4000-8000-000000000004';
  IF v_sp.onboarding_fait_le IS NOT NULL OR v_sp.niveau_declare IS NOT NULL
     OR EXISTS (SELECT 1 FROM private.niv1_reprise_avant WHERE profile_id = 'b2000000-0000-4000-8000-000000000004') THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p4 (rien de connu) modifie';
  END IF;
  RAISE NOTICE 'NIV1R OK : p4, rien de connu, intact';

  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = 'b2000000-0000-4000-8000-000000000005';
  IF v_sp.onboarding_fait_le <> '2026-10-01 10:00+00'::timestamptz
     OR EXISTS (SELECT 1 FROM private.niv1_reprise_avant WHERE profile_id = 'b2000000-0000-4000-8000-000000000005') THEN
    RAISE EXCEPTION 'NIV1R ROUGE : p5 (deja rempli) modifie';
  END IF;
  RAISE NOTICE 'NIV1R OK : p5, deja rempli, intact';

  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = 'b2000000-0000-4000-8000-0000000000f1';
  IF v_sp.onboarding_fait_le IS NULL OR v_sp.niveau_declare IS DISTINCT FROM 'lecture_courante'
     OR v_sp.objectif IS DISTINCT FROM 'memoriser' OR v_sp.langue_cours IS DISTINCT FROM 'francais' THEN
    RAISE EXCEPTION 'NIV1R ROUGE : t1, reponses du titulaire non reprises : %', row_to_json(v_sp);
  END IF;
  RAISE NOTICE 'NIV1R OK : t1, reponses du titulaire reprises sur son profil';

  v_r := private.niv1_reprendre_profils();
  IF (v_r ->> 'touches')::integer <> 0 THEN
    RAISE EXCEPTION 'NIV1R ROUGE : un second appel touche encore % profils', v_r ->> 'touches';
  END IF;
  RAISE NOTICE 'NIV1R OK : un second appel ne touche plus rien';

  IF pg_catalog.has_function_privilege('authenticated', 'private.niv1_reprendre_profils()', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'private.niv1_reprise_avant', 'SELECT') THEN
    RAISE EXCEPTION 'NIV1R ROUGE : reprise atteignable par un compte connecte';
  END IF;
  RAISE NOTICE 'NIV1R OK : ni la fonction ni la table ne sont atteignables par un client';
END;
$reprise$;

ROLLBACK;
