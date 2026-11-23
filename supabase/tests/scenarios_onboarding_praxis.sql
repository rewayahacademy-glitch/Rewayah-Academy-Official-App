-- ONBOARDING-PRAXIS (directeur, 22/11/2026) : la demande garde la lecture
-- (riwaya, autre a preciser), ce qui est deja memorise (quantite, juz,
-- sourates), l'objectif « priere et invocations », la langue choisie (meme
-- hors referentiel des classes), la langue de secours, une langue absente de
-- la liste, et la source declaree ; la direction les relit dans
-- lister_demandes_admission ; chaque valeur hors borne est refusee sans rien
-- laisser ; l'ancienne forme a sept parametres n'est plus appelable.
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations.
-- Fixtures sans donnee personnelle ; tout est annule a la fin.
-- Un echec leve 'ONB-PRAXIS ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ae000000-0000-4000-8000-000000000001', 'onb-direction@example.test'),
  ('ae000000-0000-4000-8000-000000000002', 'onb-famille@example.test'),
  ('ae000000-0000-4000-8000-000000000003', 'onb-adulte@example.test'),
  ('ae000000-0000-4000-8000-000000000004', 'onb-refus@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('ae000000-0000-4000-8000-000000000001', 'ONBPRAXADMIN0001', 'admin',
   'Fixture', 'Direction', 'active', 'male', NULL);

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Une famille : un debutant (priere, langue au referentiel, secours hors
-- referentiel), un enfant qui a memorise des sourates (Warsh), et le parent
-- qui suit des cours (autre lecture, juz).
SELECT set_config('request.jwt.claim.sub', 'ae000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ae000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', true,
  '[{"prenom": "Enfant Un", "age": 8, "genre": "male", "niveau": "debut_lettres",
     "objectif": "priere_invocations", "langue": "francais", "langue_secours": "ha",
     "langue_autre": "Tamoul"},
    {"prenom": "Enfant Deux", "age": 12, "genre": "female", "niveau": "memorisation_partielle",
     "objectif": "memoriser", "riwaya": "warsh", "memorise": "quelques_sourates",
     "sourates": ["fatiha", "nas", "ikhlas"], "langue": "francais"},
    {"est_titulaire": true, "niveau": "memorisation_partielle", "objectif": "memoriser",
     "riwaya": "autre", "riwaya_autre": "Qalun", "memorise": "1_5_juz", "juz": [30, 29],
     "langue": "francais"}]'::jsonb,
  'mosquee');
RESET ROLE;

-- « Pour moi » : une langue hors referentiel des classes (ourdou), sans source.
SELECT set_config('request.jwt.claim.sub', 'ae000000-0000-4000-8000-000000000003', true);
SELECT set_config('test.uid', 'ae000000-0000-4000-8000-000000000003', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Fixture', 'Adulte', 'male', 'Europe/Paris', false,
  '[{"est_titulaire": true, "niveau": "lecture_courante", "objectif": "devenir_fluide",
     "riwaya": "hafs", "langue": "ur"}]'::jsonb);
RESET ROLE;

DO $controles$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ae000000-0000-4000-8000-000000000002' AND a.rang = 1
          AND a.objectif IS NULL AND a.objectif_priere AND a.riwaya IS NULL
          AND a.langue_code = 'francais' AND a.langue_demandee = 'francais'
          AND a.langue_secours = 'ha' AND a.langue_autre = 'Tamoul'
          AND c.source_declaree = 'mosquee') THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : le debutant (priere, langues, source) n''est pas range tel quel';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ae000000-0000-4000-8000-000000000002' AND a.rang = 2
          AND a.riwaya = 'warsh' AND a.memorise_quantite = 'quelques_sourates'
          AND a.sourates = ARRAY['fatiha', 'nas', 'ikhlas'] AND a.juz = '{}'::smallint[]
          AND a.objectif = 'memoriser' AND NOT a.objectif_priere) THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : l''enfant qui a memorise n''est pas range tel quel';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ae000000-0000-4000-8000-000000000002' AND a.est_titulaire
          AND a.riwaya = 'autre' AND a.riwaya_autre = 'Qalun'
          AND a.memorise_quantite = '1_5_juz' AND a.juz = '{29,30}'::smallint[]) THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : le parent (autre lecture, juz tries) n''est pas range tel quel';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ae000000-0000-4000-8000-000000000003'
          AND c.type_code = 'eleve_adulte' AND a.langue_code IS NULL
          AND a.langue_demandee = 'ur' AND c.source_declaree IS NULL) THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : une langue hors referentiel doit rester dans langue_demandee';
  END IF;
  RAISE NOTICE 'ONB-PRAXIS OK : lecture, memorise, priere, langues et source ranges';
END
$controles$;

-- La direction relit les nouveaux champs.
SELECT set_config('request.jwt.claim.sub', 'ae000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ae000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;
DO $direction$
DECLARE
  v_ligne jsonb;
  v_adulte jsonb;
BEGIN
  SELECT l INTO v_ligne
    FROM pg_catalog.jsonb_array_elements(public.lister_demandes_admission('famille', NULL, 1) -> 'lignes') AS l
   WHERE l ->> 'nom' LIKE '%Famille%';
  IF v_ligne IS NULL OR v_ligne ->> 'source' IS DISTINCT FROM 'mosquee'
     OR v_ligne -> 'apprenants' -> 0 ->> 'objectif' IS DISTINCT FROM 'priere_invocations'
     OR v_ligne -> 'apprenants' -> 0 ->> 'langueSecours' IS DISTINCT FROM 'ha'
     OR v_ligne -> 'apprenants' -> 0 ->> 'langueAutre' IS DISTINCT FROM 'Tamoul'
     OR v_ligne -> 'apprenants' -> 1 ->> 'riwaya' IS DISTINCT FROM 'warsh'
     OR v_ligne -> 'apprenants' -> 1 -> 'sourates' IS DISTINCT FROM '["fatiha", "nas", "ikhlas"]'::jsonb
     OR v_ligne -> 'apprenants' -> 2 ->> 'riwayaAutre' IS DISTINCT FROM 'Qalun'
     OR v_ligne -> 'apprenants' -> 2 -> 'juz' IS DISTINCT FROM '[29, 30]'::jsonb
     OR v_ligne -> 'apprenants' -> 2 ->> 'memorise' IS DISTINCT FROM '1_5_juz' THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : la liste de la direction ne rend pas les nouveaux champs : %', v_ligne;
  END IF;
  v_adulte := public.lister_demandes_admission('eleve_adulte', NULL, 1) -> 'lignes' -> 0;
  IF v_adulte -> 'apprenants' -> 0 ->> 'langue' IS DISTINCT FROM 'ur' THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : la langue hors referentiel ne se relit pas : %', v_adulte;
  END IF;
  RAISE NOTICE 'ONB-PRAXIS OK : la direction relit lecture, memorise, priere, langues et source';
END
$direction$;
RESET ROLE;
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Refus : chaque valeur hors borne, et rien n'est laisse.
SET LOCAL ROLE authenticated;
DO $refus$
DECLARE
  v_cas record;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'ae000000-0000-4000-8000-000000000004', true);
  PERFORM set_config('test.uid', 'ae000000-0000-4000-8000-000000000004', true);
  FOR v_cas IN
    SELECT * FROM (VALUES
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "debut_lettres", "riwaya": "hafs"}]'::jsonb,
       NULL::text, 'lecture pour un debutant'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "lecture_courante", "riwaya": "qalun"}]'::jsonb,
       NULL, 'lecture inconnue'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "lecture_courante", "riwaya": "hafs",
          "riwaya_autre": "Qalun"}]'::jsonb, NULL, 'autre lecture sans « autre »'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "lecture_lente",
          "memorise": "1_5_juz"}]'::jsonb, NULL, 'memorise sans memorisation'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "memorisation_partielle",
          "memorise": "1_5_juz", "juz": [31]}]'::jsonb, NULL, 'juz 31'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "memorisation_partielle",
          "memorise": "quelques_sourates", "sourates": ["baqara"]}]'::jsonb, NULL, 'sourate hors des bases'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "niveau": "memorisation_partielle",
          "memorise": "coran_entier", "juz": [1]}]'::jsonb, NULL, 'detail pour tout le Coran'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "langue": "fr", "langue_secours": "fr"}]'::jsonb,
       NULL, 'secours egal a la langue'),
      ('[{"prenom": "E", "age": 8, "genre": "male", "langue": "Français"}]'::jsonb, NULL, 'code de langue illisible'),
      ('[{"prenom": "E", "age": 8, "genre": "male"}]'::jsonb, 'publicite', 'source inconnue')
    ) AS t(apprenants, source, nom)
  LOOP
    BEGIN
      PERFORM public.inscrire_titulaire('famille', 'Fixture', 'Refus', 'male',
                                        'Europe/Paris', false, v_cas.apprenants, v_cas.source);
      RAISE EXCEPTION 'ONB-PRAXIS ROUGE : % accepte', v_cas.nom;
    EXCEPTION
      WHEN invalid_parameter_value OR check_violation THEN NULL;
    END;
  END LOOP;
  -- L'objectif « priere » n'est pas celui d'un adulte titulaire.
  BEGIN
    PERFORM public.inscrire_titulaire('moi', 'Fixture', 'Refus', 'male', 'Europe/Paris', false,
      '[{"est_titulaire": true, "objectif": "priere_invocations"}]'::jsonb);
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : priere accepte pour un adulte';
  EXCEPTION
    WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE 'ONB-PRAXIS OK : valeurs hors bornes refusees';
END
$refus$;
RESET ROLE;

DO $fin$
BEGIN
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = 'ae000000-0000-4000-8000-000000000004') THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : un refus a laisse un profil';
  END IF;
  IF pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb)') IS NOT NULL THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : la forme a sept parametres est encore dans public';
  END IF;
  IF pg_catalog.has_function_privilege('anon',
       'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
       'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'private.inscrire_titulaire_avant_onboarding(text,text,text,public.gender,text,boolean,jsonb)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ONB-PRAXIS ROUGE : droits d''execution faux';
  END IF;
  RAISE NOTICE 'ONB-PRAXIS OK : un refus ne laisse rien ; une seule forme appelable, par un compte connecte';
END
$fin$;

ROLLBACK;
