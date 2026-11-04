-- NIV1 (03/11/2026, migration 20261106800000) : le niveau demande une seule
-- fois.
--   1. Un enfant venu de la demande, lie a son profil (lier_apprenant_profil),
--      a une fiche remplie (onboarding_fait_le) : le Parcours s'ouvre sur les
--      horaires. Un enfant sans tranche (exception de la direction sous 6 ans)
--      garde le questionnaire.
--   2. Le titulaire qui suit des cours retrouve sur son profil eleve (ne a
--      l'inscription) le niveau, l'objectif et la langue de sa demande.
--   3. UX-032 : une candidature d'enfant de 5 ans est refusee.
--   4. Droits : anon n'execute pas lier_apprenant_profil ; personne n'execute
--      la fonction du declencheur.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'NIV1 ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('a1000000-0000-4000-8000-000000000001', 'niv1-direction@example.test'),
  ('a1000000-0000-4000-8000-000000000002', 'niv1-famille@example.test'),
  ('a1000000-0000-4000-8000-000000000003', 'niv1-cinq-ans@example.test'),
  ('a1000000-0000-4000-8000-000000000004', 'niv1-enfant@example.test'),
  ('a1000000-0000-4000-8000-000000000005', 'niv1-petit@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('a1000000-0000-4000-8000-000000000001', 'NIV1ADMIN0000001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- La famille s'inscrit : deux enfants et le parent qui suit des cours.
SELECT set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'a1000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Niveau', 'female', 'Europe/Paris', true,
  '[{"prenom": "Enfant Neuf", "age": 9, "genre": "female", "niveau": "lecture_lente",
     "objectif": "devenir_fluide", "moments": ["soir"], "langue": "francais"},
    {"prenom": "Enfant Petit", "age": 6, "genre": "male", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["matin"], "langue": "francais"},
    {"est_titulaire": true, "niveau": "lecture_courante", "objectif": "memoriser",
     "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;

-- UX-032 : un enfant de 5 ans est refuse a la soumission.
SELECT set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'a1000000-0000-4000-8000-000000000003', true);
SET LOCAL ROLE authenticated;
DO $cinq_ans$
BEGIN
  BEGIN
    PERFORM public.inscrire_titulaire('famille', 'Fixture', 'Cinq', 'female', 'Europe/Paris', false,
      '[{"prenom": "Enfant Cinq", "age": 5, "genre": "male", "niveau": "debut_lettres",
         "objectif": "apprendre_a_lire", "moments": ["matin"], "langue": "francais"}]'::jsonb);
    RAISE EXCEPTION 'NIV1 ROUGE : une candidature d''enfant de 5 ans est acceptee';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'NIV1 OK : un enfant de 5 ans est refuse a la soumission (UX-032)';
  END;
END;
$cinq_ans$;
RESET ROLE;

-- La direction accepte la famille.
SELECT set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'a1000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $direction$
DECLARE
  v_c public.candidatures;
  v_r jsonb;
BEGIN
  SELECT c.* INTO v_c FROM public.candidatures c
   WHERE c.profile_id = 'a1000000-0000-4000-8000-000000000002';
  v_r := public.accepter_admission(v_c.id, v_c.version, 'niv1-accepter-1');
  IF NOT (v_r ? 'candidature') THEN
    RAISE EXCEPTION 'NIV1 ROUGE : acceptation refusee : %', v_r;
  END IF;
END;
$direction$;

-- Les profils que la fonction Edge cree : Enfant Neuf avec sa tranche
-- (creer_profil_enfant la deduit de l'age) ; Enfant Petit sans tranche
-- (cas d'une exception de la direction, aucune tranche ne le couvre).
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
SELECT v.id, v.imm, 'student', p.household_id, v.prenom, 'Niveau', 'active'
  FROM public.profiles p,
       (VALUES ('a1000000-0000-4000-8000-000000000004'::uuid, 'NIV1ENFANT000004', 'Enfant Neuf'),
               ('a1000000-0000-4000-8000-000000000005'::uuid, 'NIV1ENFANT000005', 'Enfant Petit'))
         AS v(id, imm, prenom)
 WHERE p.id = 'a1000000-0000-4000-8000-000000000002';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy, cohorte)
VALUES
  ('a1000000-0000-4000-8000-000000000004', 'minor', 'child', 'forbidden',
   (SELECT c.code FROM public.cohortes_age c
     WHERE c.actif AND c.type_public = 'enfant' AND 9 BETWEEN c.age_min AND coalesce(c.age_max_inclus, 999)
     ORDER BY c.ordre LIMIT 1)),
  ('a1000000-0000-4000-8000-000000000005', 'minor', 'child', 'forbidden', NULL);

-- La famille lie ses enfants ; son propre profil eleve existe deja.
SELECT set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'a1000000-0000-4000-8000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
SET LOCAL ROLE authenticated;
DO $famille$
DECLARE
  v_apprenants jsonb := public.mes_apprenants_demande();
  v_neuf uuid;
  v_petit uuid;
BEGIN
  SELECT (e ->> 'id')::uuid INTO v_neuf FROM pg_catalog.jsonb_array_elements(v_apprenants) e
   WHERE e ->> 'prenom' = 'Enfant Neuf';
  SELECT (e ->> 'id')::uuid INTO v_petit FROM pg_catalog.jsonb_array_elements(v_apprenants) e
   WHERE e ->> 'prenom' = 'Enfant Petit';
  IF v_neuf IS NULL OR v_petit IS NULL THEN
    RAISE EXCEPTION 'NIV1 ROUGE : apprenants de la demande introuvables : %', v_apprenants;
  END IF;
  PERFORM public.lier_apprenant_profil(v_neuf, 'a1000000-0000-4000-8000-000000000004');
  PERFORM public.lier_apprenant_profil(v_petit, 'a1000000-0000-4000-8000-000000000005');
END;
$famille$;
RESET ROLE;

-- Controles (hors de portee d'un client).
DO $controles$
DECLARE
  v_sp public.student_profiles;
BEGIN
  SELECT * INTO v_sp FROM public.student_profiles
   WHERE profile_id = 'a1000000-0000-4000-8000-000000000004';
  IF v_sp.onboarding_fait_le IS NULL OR v_sp.niveau_declare IS DISTINCT FROM 'lecture_lente'
     OR v_sp.objectif IS DISTINCT FROM 'devenir_fluide' OR v_sp.langue_cours IS DISTINCT FROM 'francais'
     OR v_sp.cohorte IS NULL THEN
    RAISE EXCEPTION 'NIV1 ROUGE : l''enfant venu de la demande n''a pas une fiche remplie : %', row_to_json(v_sp);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.v_parcours_onboarding v
                  WHERE v.eleve_id = 'a1000000-0000-4000-8000-000000000004'
                    AND v.onboarding_fait_le IS NOT NULL) THEN
    RAISE EXCEPTION 'NIV1 ROUGE : le Parcours ne lit pas la fiche remplie';
  END IF;
  RAISE NOTICE 'NIV1 OK : un enfant venu de la demande ouvre son Parcours sur les horaires';

  SELECT * INTO v_sp FROM public.student_profiles
   WHERE profile_id = 'a1000000-0000-4000-8000-000000000005';
  IF v_sp.onboarding_fait_le IS NOT NULL THEN
    RAISE EXCEPTION 'NIV1 ROUGE : un enfant sans tranche est marque rempli';
  END IF;
  IF v_sp.niveau_declare IS DISTINCT FROM 'debut_lettres' THEN
    RAISE EXCEPTION 'NIV1 ROUGE : le niveau de l''enfant sans tranche n''est pas repris';
  END IF;
  RAISE NOTICE 'NIV1 OK : un enfant sans tranche garde le questionnaire, son niveau est repris';

  SELECT * INTO v_sp FROM public.student_profiles
   WHERE profile_id = 'a1000000-0000-4000-8000-000000000002';
  IF v_sp.niveau_declare IS DISTINCT FROM 'lecture_courante' OR v_sp.objectif IS DISTINCT FROM 'memoriser'
     OR v_sp.langue_cours IS DISTINCT FROM 'francais' OR v_sp.onboarding_fait_le IS NULL
     OR v_sp.cohorte IS DISTINCT FROM 'adulte_18_plus' THEN
    RAISE EXCEPTION 'NIV1 ROUGE : le niveau du titulaire ne rejoint pas son profil : %', row_to_json(v_sp);
  END IF;
  RAISE NOTICE 'NIV1 OK : le titulaire retrouve son niveau, son objectif et sa langue';

  IF pg_catalog.has_function_privilege('anon', 'public.lier_apprenant_profil(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.niv1_reponses_titulaire_vers_profil()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.lier_apprenant_profil(uuid,uuid)', 'EXECUTE')
     THEN
    RAISE EXCEPTION 'NIV1 ROUGE : droits d''execution incorrects';
  END IF;
  RAISE NOTICE 'NIV1 OK : anon refuse, authenticated autorise';
END;
$controles$;

ROLLBACK;
