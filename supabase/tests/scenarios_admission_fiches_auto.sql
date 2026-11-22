-- ADMISSION-FICHES-AUTO (directeur, 22/11/2026) : l'acceptation d'une demande
-- cree les fiches des eleves a partir des reponses de l'onboarding.
--   1. Une famille a deux enfants et un parent apprenant est acceptee : trois
--      fiches liees (deux profils d'enfant du foyer avec tranche, genre,
--      niveau, objectif, langue, fiche remplie ; le titulaire lie a sa propre
--      fiche), un compte d'identite par enfant, les claims de la direction
--      rendus, un journal.
--   2. Rejouee (meme cle, puis l'aide seule) : rien de neuf, aucun doublon.
--   3. Un eleve adulte (« moi ») accepte : sa fiche autonome est liee.
--   4. Un enfant que la regle refuse ne bloque pas l'acceptation : l'echec est
--      journalise, l'apprenant reste a lier.
--   5. Rattrapage (la boucle de la migration) : l'enfant reste a lier recoit sa
--      fiche ; un enfant deja cree a la main au meme prenom est lie, sans
--      doublon. Postflight : plus aucun apprenant d'une demande acceptee sans
--      fiche.
--   6. Droits : les deux aides privees ne s'executent par aucun role client.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Tout est annule a la fin. Un echec leve 'FICHES-AUTO ROUGE : ...'.
BEGIN;

-- auth.users et auth.identities au plus pres de Supabase (le stub n'a que
-- quelques colonnes) : l'aide pose les colonnes presentes, saute les generees.
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS updated_at timestamptz;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS instance_id uuid;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS aud varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS role varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS encrypted_password varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_user_meta_data jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS confirmation_token varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS recovery_token varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change_token_new varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change varchar(255);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_sso_user boolean NOT NULL DEFAULT false;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_anonymous boolean NOT NULL DEFAULT false;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS confirmed_at timestamptz
  GENERATED ALWAYS AS (email_confirmed_at) STORED;
UPDATE auth.users SET created_at = now() WHERE created_at IS NULL;
CREATE TABLE IF NOT EXISTS auth.identities (
  provider_id text NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  identity_data jsonb NOT NULL,
  provider text NOT NULL,
  last_sign_in_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  email text GENERATED ALWAYS AS (lower(identity_data ->> 'email')) STORED,
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY
);

INSERT INTO auth.users (id, email, created_at) VALUES
  ('fa000000-0000-4000-8000-000000000001', 'fa-direction@example.test', now()),
  ('fa000000-0000-4000-8000-000000000002', 'fa-famille@example.test', now()),
  ('fa000000-0000-4000-8000-000000000003', 'fa-adulte@example.test', now()),
  ('fa000000-0000-4000-8000-000000000004', 'fa-rattrapage@example.test', now()),
  ('fa000000-0000-4000-8000-000000000005', 'fa-doublon@example.test', now()),
  ('fa000000-0000-4000-8000-000000000006', 'fa-main@example.test', now());

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('fa000000-0000-4000-8000-000000000001', 'FAADMIN000000001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Les inscriptions (lot B).
SELECT set_config('request.jwt.claim.sub', 'fa000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'fa000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Mariama', 'Auto', 'female', 'Europe/Paris', true,
  '[{"prenom": "Amina", "age": 9, "genre": "female", "niveau": "lecture_lente",
     "objectif": "devenir_fluide", "moments": ["soir"], "langue": "francais"},
    {"prenom": "Yusuf", "age": 12, "genre": "male", "niveau": "lettres_avec_aide",
     "objectif": "indecis", "moments": ["matin"], "langue": "francais"},
    {"est_titulaire": true, "niveau": "lecture_courante", "objectif": "memoriser",
     "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', 'fa000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'fa000000-0000-4000-8000-000000000003', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Ousmane', 'Adulte', 'male', 'Europe/Paris', false,
  '[{"est_titulaire": true, "niveau": "debut_lettres", "objectif": "apprendre_a_lire",
     "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;
-- Un enfant au prenom du titulaire : creer_profil_enfant le refuse.
SELECT set_config('request.jwt.claim.sub', 'fa000000-0000-4000-8000-000000000004', true);
SELECT set_config('test.uid', 'fa000000-0000-4000-8000-000000000004', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Safi', 'Rattrapage', 'female', 'Europe/Paris', true,
  '[{"prenom": "Safi", "age": 12, "genre": "male", "niveau": "lettres_avec_aide",
     "objectif": "indecis", "moments": ["soir"], "langue": "francais"},
    {"est_titulaire": true, "niveau": "lettres_avec_aide", "objectif": "indecis",
     "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', 'fa000000-0000-4000-8000-000000000005', true);
SELECT set_config('test.uid', 'fa000000-0000-4000-8000-000000000005', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Awa', 'Doublon', 'female', 'Europe/Paris', false,
  '[{"prenom": "Awa", "age": 10, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;

-- La direction accepte.
SELECT set_config('request.jwt.claim.sub', 'fa000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'fa000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $accepter$
DECLARE
  v_c public.candidatures;
  v_r jsonb;
  v_foyer uuid := (SELECT p.household_id FROM public.profiles p
                    WHERE p.id = 'fa000000-0000-4000-8000-000000000002');
  v_n integer;
  v_comptes integer;
  v_amina uuid;
  v_yusuf uuid;
  v_sp public.student_profiles;
BEGIN
  -- 1. La famille a deux enfants et un parent apprenant.
  SELECT c.* INTO v_c FROM public.candidatures c
   WHERE c.profile_id = 'fa000000-0000-4000-8000-000000000002';
  v_r := public.accepter_admission(v_c.id, v_c.version, 'fa-accepter-1');
  IF NOT (v_r ? 'candidature') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : acceptation refusee : %', v_r;
  END IF;
  IF auth.uid() IS DISTINCT FROM 'fa000000-0000-4000-8000-000000000001'::uuid
     OR current_setting('request.jwt.claims', true) <> '{"app_metadata":{"role":"admin"}}' THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : les claims de la direction ne sont pas rendus (%, %)',
      auth.uid(), current_setting('request.jwt.claims', true);
  END IF;
  SELECT pg_catalog.count(*) INTO v_n FROM public.candidature_apprenants a
   WHERE a.candidature_id = v_c.id AND a.profil_eleve_id IS NOT NULL;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : % fiche(s) liee(s) sur 3', v_n;
  END IF;
  IF (SELECT a.profil_eleve_id FROM public.candidature_apprenants a
       WHERE a.candidature_id = v_c.id AND a.est_titulaire)
     IS DISTINCT FROM 'fa000000-0000-4000-8000-000000000002'::uuid THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : le parent apprenant n''est pas lie a sa propre fiche';
  END IF;
  SELECT a.profil_eleve_id INTO v_amina FROM public.candidature_apprenants a
   WHERE a.candidature_id = v_c.id AND a.prenom = 'Amina';
  SELECT a.profil_eleve_id INTO v_yusuf FROM public.candidature_apprenants a
   WHERE a.candidature_id = v_c.id AND a.prenom = 'Yusuf';
  IF NOT EXISTS (SELECT 1 FROM public.profiles p
                  WHERE p.id = v_amina AND p.role = 'student' AND p.household_id = v_foyer
                    AND p.first_name = 'Amina' AND p.last_name = 'Auto' AND p.gender = 'female'
                    AND p.account_status = 'active')
     OR NOT EXISTS (SELECT 1 FROM public.profiles p
                     WHERE p.id = v_yusuf AND p.role = 'student' AND p.household_id = v_foyer
                       AND p.first_name = 'Yusuf' AND p.gender = 'male') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : profils d''enfant absents ou mal remplis';
  END IF;
  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = v_amina;
  IF v_sp.student_type <> 'minor' OR v_sp.cohorte IS NULL OR v_sp.interface_mode <> 'child'
     OR v_sp.niveau_declare IS DISTINCT FROM 'lecture_lente'
     OR v_sp.objectif IS DISTINCT FROM 'devenir_fluide'
     OR v_sp.langue_cours IS DISTINCT FROM 'francais' OR v_sp.onboarding_fait_le IS NULL THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : fiche d''Amina incomplete : %', row_to_json(v_sp);
  END IF;
  SELECT * INTO v_sp FROM public.student_profiles WHERE profile_id = v_yusuf;
  IF v_sp.camera_policy <> 'allowed' OR v_sp.interface_mode <> 'standard'
     OR v_sp.niveau_declare IS DISTINCT FROM 'lettres_avec_aide' OR v_sp.onboarding_fait_le IS NULL THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : fiche de Yusuf incomplete : %', row_to_json(v_sp);
  END IF;
  SELECT * INTO v_sp FROM public.student_profiles
   WHERE profile_id = 'fa000000-0000-4000-8000-000000000002';
  IF v_sp.niveau_declare IS DISTINCT FROM 'lecture_courante' OR v_sp.objectif IS DISTINCT FROM 'memoriser' THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : la fiche du parent apprenant n''a pas ses reponses';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM auth.users u
       WHERE u.id IN (v_amina, v_yusuf)
         AND u.raw_app_meta_data ->> 'child_of' = 'fa000000-0000-4000-8000-000000000002'
         AND u.email LIKE 'eleve-%@eleves.rewayahacademy.com'
         AND u.email_confirmed_at IS NULL AND u.aud = 'authenticated'
         AND u.encrypted_password = '' AND u.created_at IS NOT NULL) <> 2
     OR (SELECT u.raw_app_meta_data ->> 'gender' FROM auth.users u WHERE u.id = v_yusuf) <> 'male'
     OR (SELECT pg_catalog.count(*) FROM auth.identities i
          WHERE i.user_id IN (v_amina, v_yusuf) AND i.provider = 'email'
            AND i.provider_id = i.user_id::text) <> 2 THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : comptes d''identite des enfants mal formes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs l
                  WHERE l.action = 'admission_fiches_auto' AND l.row_id = v_c.id::text
                    AND (l.payload ->> 'lies')::integer = 3
                    AND l.actor = 'fa000000-0000-4000-8000-000000000001') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : journal de la creation absent ou mal attribue';
  END IF;
  RAISE NOTICE 'FICHES-AUTO OK : famille acceptee, 3 fiches liees (2 enfants crees, parent lie), claims rendus';

  -- 2. Rejouee : rien de neuf.
  SELECT pg_catalog.count(*) INTO v_comptes FROM auth.users;
  v_r := public.accepter_admission(v_c.id, v_c.version, 'fa-accepter-1');
  IF private.admission_fiches_auto(v_c.id) <> 0
     OR (SELECT pg_catalog.count(*) FROM auth.users) <> v_comptes
     OR (SELECT pg_catalog.count(*) FROM public.profiles p
          WHERE p.household_id = v_foyer AND p.role = 'student') <> 2 THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : un rejeu cree quelque chose';
  END IF;
  RAISE NOTICE 'FICHES-AUTO OK : rejouee, aucun doublon';

  -- 3. L'eleve adulte.
  SELECT c.* INTO v_c FROM public.candidatures c
   WHERE c.profile_id = 'fa000000-0000-4000-8000-000000000003';
  v_r := public.accepter_admission(v_c.id, v_c.version, 'fa-accepter-2');
  IF (SELECT a.profil_eleve_id FROM public.candidature_apprenants a
       WHERE a.candidature_id = v_c.id AND a.est_titulaire)
       IS DISTINCT FROM 'fa000000-0000-4000-8000-000000000003'::uuid
     OR NOT EXISTS (SELECT 1 FROM public.student_profiles s
                     WHERE s.profile_id = 'fa000000-0000-4000-8000-000000000003'
                       AND s.titulaire_profile_id = s.profile_id AND s.deleted_at IS NULL
                       AND s.niveau_declare = 'debut_lettres') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : l''eleve adulte n''a pas sa fiche liee : %', v_r;
  END IF;
  RAISE NOTICE 'FICHES-AUTO OK : eleve adulte accepte, sa fiche autonome est liee';

  -- 4. Un enfant que la regle refuse ne bloque pas l'acceptation.
  SELECT c.* INTO v_c FROM public.candidatures c
   WHERE c.profile_id = 'fa000000-0000-4000-8000-000000000004';
  v_r := public.accepter_admission(v_c.id, v_c.version, 'fa-accepter-3');
  IF NOT (v_r ? 'candidature')
     OR (SELECT c.etape FROM public.candidatures c WHERE c.id = v_c.id) <> 'confirmee'
     OR (SELECT a.profil_eleve_id FROM public.candidature_apprenants a
          WHERE a.candidature_id = v_c.id AND NOT a.est_titulaire) IS NOT NULL
     OR (SELECT a.profil_eleve_id FROM public.candidature_apprenants a
          WHERE a.candidature_id = v_c.id AND a.est_titulaire) IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.audit_logs l
                     WHERE l.action = 'admission_fiche_auto_echec' AND l.row_id = v_c.id::text) THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : un refus de la regle bloque l''acceptation ou n''est pas journalise : %', v_r;
  END IF;
  IF EXISTS (SELECT 1 FROM auth.users u
              WHERE u.raw_app_meta_data ->> 'child_of' = 'fa000000-0000-4000-8000-000000000004') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : un compte d''identite orphelin reste apres le refus';
  END IF;
  -- Meme refus pour la famille Doublon (« Awa » est le prenom du titulaire).
  SELECT c.* INTO v_c FROM public.candidatures c
   WHERE c.profile_id = 'fa000000-0000-4000-8000-000000000005';
  v_r := public.accepter_admission(v_c.id, v_c.version, 'fa-accepter-4');
  RAISE NOTICE 'FICHES-AUTO OK : un enfant refuse par la regle ne bloque pas l''acceptation, echec journalise, aucun compte orphelin';
END
$accepter$;

-- 5. Rattrapage. Les deux demandes acceptees gardent un enfant a lier ; la
-- cause est levee (prenoms corriges, fixture), et la famille Doublon a deja
-- cree le profil de son enfant a la main.
UPDATE public.candidature_apprenants a SET prenom = 'Abdoul'
  FROM public.candidatures c
 WHERE c.id = a.candidature_id AND c.profile_id = 'fa000000-0000-4000-8000-000000000004'
   AND NOT a.est_titulaire;
UPDATE public.candidature_apprenants a SET prenom = 'Mariam'
  FROM public.candidatures c
 WHERE c.id = a.candidature_id AND c.profile_id = 'fa000000-0000-4000-8000-000000000005';
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status)
SELECT 'fa000000-0000-4000-8000-000000000006', 'FAMAIN0000000006', 'student', p.household_id,
       'mariam', 'Doublon', 'active'
  FROM public.profiles p WHERE p.id = 'fa000000-0000-4000-8000-000000000005';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
VALUES ('fa000000-0000-4000-8000-000000000006', 'minor', 'standard', 'forbidden');
-- La migration tourne sans claims.
SELECT set_config('request.jwt.claim.sub', '', true);
SELECT set_config('test.uid', '', true);
SELECT set_config('request.jwt.claims', '', true);
SELECT set_config('test.jwt', '', true);

DO $rattrapage$
DECLARE
  v_id uuid;
  v_n integer;
BEGIN
  -- La boucle de la migration, a l'identique.
  FOR v_id IN
    SELECT c.id
      FROM public.candidatures c
      JOIN public.profiles t ON t.id = c.profile_id
     WHERE c.type_code IN ('famille', 'eleve_adulte')
       AND c.etape = 'confirmee' AND c.issue = 'en_cours'
       AND t.role = 'guardian' AND t.deleted_at IS NULL
       AND t.account_status IN ('active', 'provisional_active')
       AND EXISTS (SELECT 1 FROM public.candidature_apprenants a
                    WHERE a.candidature_id = c.id AND a.profil_eleve_id IS NULL)
     ORDER BY c.reference
  LOOP
    v_n := private.admission_fiches_auto(v_id);
  END LOOP;
  IF auth.uid() IS NOT NULL THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : la boucle laisse les claims d''un titulaire (%)', auth.uid();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.candidature_apprenants a
                   JOIN public.candidatures c ON c.id = a.candidature_id
                   JOIN public.profiles e ON e.id = a.profil_eleve_id
                  WHERE c.profile_id = 'fa000000-0000-4000-8000-000000000004' AND NOT a.est_titulaire
                    AND e.first_name = 'Abdoul' AND e.role = 'student') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : le rattrapage ne cree pas la fiche de l''enfant';
  END IF;
  IF (SELECT a.profil_eleve_id FROM public.candidature_apprenants a
        JOIN public.candidatures c ON c.id = a.candidature_id
       WHERE c.profile_id = 'fa000000-0000-4000-8000-000000000005')
       IS DISTINCT FROM 'fa000000-0000-4000-8000-000000000006'::uuid
     OR (SELECT pg_catalog.count(*) FROM public.profiles p
          WHERE p.role = 'student'
            AND p.household_id = (SELECT t.household_id FROM public.profiles t
                                   WHERE t.id = 'fa000000-0000-4000-8000-000000000005')) <> 1
     OR EXISTS (SELECT 1 FROM auth.users u
                 WHERE u.raw_app_meta_data ->> 'child_of' = 'fa000000-0000-4000-8000-000000000005') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : le rattrapage double un enfant deja cree a la main';
  END IF;
  IF (SELECT pg_catalog.count(*)
        FROM public.candidature_apprenants a
        JOIN public.candidatures c ON c.id = a.candidature_id
        JOIN public.profiles t ON t.id = c.profile_id
       WHERE c.type_code IN ('famille', 'eleve_adulte')
         AND c.etape = 'confirmee' AND c.issue = 'en_cours'
         AND t.role = 'guardian' AND t.deleted_at IS NULL
         AND t.account_status IN ('active', 'provisional_active')
         AND a.profil_eleve_id IS NULL) <> 0 THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : un apprenant d''une demande acceptee reste sans fiche';
  END IF;
  RAISE NOTICE 'FICHES-AUTO OK : rattrapage, fiche creee, enfant fait a la main lie sans doublon, plus aucun apprenant sans fiche';
END
$rattrapage$;

-- 6. Droits.
DO $droits$
DECLARE
  v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, 'private.admission_fiches_auto(uuid)', 'EXECUTE')
       OR pg_catalog.has_function_privilege(v_role, 'private.admission_compte_enfant(uuid,text)', 'EXECUTE') THEN
      RAISE EXCEPTION 'FICHES-AUTO ROUGE : % execute une aide privee', v_role;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.accepter_admission(uuid,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.accepter_admission(uuid,integer,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FICHES-AUTO ROUGE : droits d''accepter_admission incorrects';
  END IF;
  RAISE NOTICE 'FICHES-AUTO OK : aides privees fermees a tout role client';
END
$droits$;

ROLLBACK;
