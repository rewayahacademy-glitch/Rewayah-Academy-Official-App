-- FICHE-ELEVE-DIRECTION (directeur, 22/11/2026) : `fiche_eleve_direction(uuid)`.
-- La direction lit la fiche complete d'un eleve (identite, tuteur, admission, classe, presences) ;
-- un tuteur, un enseignant, anon et agent_ro ne la lisent pas ; un profil qui n'est pas un eleve
-- rend NULL ; sous masquage d'identite, aucun nom ni contact. Rejoue sur une base neuve, apres
-- stub_auth.sql et toutes les migrations. Tout est annule a la fin. Un echec leve 'FICHE ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('fe000000-0000-4000-8000-000000000001', 'fiche-direction@example.test'),
  ('fe000000-0000-4000-8000-000000000002', 'fiche-tuteur@example.test'),
  ('fe000000-0000-4000-8000-000000000003', 'fiche-enfant@example.test'),
  ('fe000000-0000-4000-8000-000000000005', 'fiche-enseignant@example.test'),
  ('fe000000-0000-4000-8000-000000000007', 'fiche-adulte@example.test');

INSERT INTO public.households (id) VALUES
  ('fe000000-0000-4000-8000-0000000000f1'),
  ('fe000000-0000-4000-8000-0000000000f2');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('fe000000-0000-4000-8000-000000000001', 'FICHEADMIN000001', 'admin', NULL,
   'Fixture', 'Direction', 'active', 'female'),
  ('fe000000-0000-4000-8000-000000000002', 'FICHETUTEUR00001', 'guardian',
   'fe000000-0000-4000-8000-0000000000f1', 'Amina', 'Tuteur', 'pending_kyc', 'female'),
  ('fe000000-0000-4000-8000-000000000003', 'FICHEENFANT00001', 'student',
   'fe000000-0000-4000-8000-0000000000f1', 'Yasmine', 'Enfant', 'active', 'female'),
  ('fe000000-0000-4000-8000-000000000005', 'FICHEENSEIG00001', 'teacher', NULL,
   'Salma', 'Enseignante', 'pending_kyc', 'female'),
  ('fe000000-0000-4000-8000-000000000007', 'FICHEADULTE00001', 'guardian',
   'fe000000-0000-4000-8000-0000000000f2', 'Karim', 'Adulte', 'active', 'female');

UPDATE public.households SET primary_guardian_id = 'fe000000-0000-4000-8000-000000000002'
 WHERE id = 'fe000000-0000-4000-8000-0000000000f1';

INSERT INTO public.student_profiles (profile_id, student_type, niveau_declare, objectif, langue_cours)
VALUES
  ('fe000000-0000-4000-8000-000000000003', 'minor', 'lecture_lente', 'devenir_fluide', 'francais'),
  ('fe000000-0000-4000-8000-000000000007', 'autonomous', NULL, NULL, NULL);
INSERT INTO public.teacher_profiles (profile_id, country) VALUES
  ('fe000000-0000-4000-8000-000000000005', 'MA');

INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
VALUES ('fe000000-0000-4000-8000-0000000000c1', 'fe000000-0000-4000-8000-000000000005',
        'enfant', 5, 'Classe des lettres', 2, 18);
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('fe000000-0000-4000-8000-0000000000c1', 'fe000000-0000-4000-8000-000000000003');

-- Une seance terminee ou l'enfant etait present.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, groupe_id)
VALUES ('fe000000-0000-4000-8000-0000000000d1', 'fe000000-0000-4000-8000-000000000005',
        now() - interval '2 days', now() - interval '2 days' + interval '45 minutes', 'ended',
        'fe000000-0000-4000-8000-0000000000c1');
INSERT INTO public.session_participants (session_id, profile_id, role)
VALUES ('fe000000-0000-4000-8000-0000000000d1', 'fe000000-0000-4000-8000-000000000003', 'student');

-- La demande d'admission de la famille : la ligne de l'enfant, liee par son profil.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, source, source_declaree)
VALUES ('fe000000-0000-4000-8000-0000000000e1', 'famille', 'fe000000-0000-4000-8000-000000000002',
        'female', 'Amina Tuteur', 'lien_public', 'mosquee');
INSERT INTO public.candidature_apprenants
  (candidature_id, rang, est_titulaire, prenom, age, genre, niveau_declare, objectif, moments,
   profil_eleve_id)
VALUES ('fe000000-0000-4000-8000-0000000000e1', 1, false, 'Yasmine', 9, 'female', 'lecture_lente',
        'devenir_fluide', ARRAY['soir'], 'fe000000-0000-4000-8000-000000000003');

-- Un compte qui n'est pas de la direction ne lit rien (tuteur, puis enseignant).
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
SELECT set_config('request.jwt.claim.sub', 'fe000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'fe000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
DO $tuteur$
BEGIN
  BEGIN
    PERFORM public.fiche_eleve_direction('fe000000-0000-4000-8000-000000000003');
    RAISE EXCEPTION 'FICHE ROUGE : un tuteur lit la fiche de la direction';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'FICHE OK : un tuteur ne lit pas la fiche';
  END;
END;
$tuteur$;
RESET ROLE;

SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
SELECT set_config('request.jwt.claim.sub', 'fe000000-0000-4000-8000-000000000005', true);
SELECT set_config('test.uid', 'fe000000-0000-4000-8000-000000000005', true);
SET LOCAL ROLE authenticated;
DO $ens$
BEGIN
  BEGIN
    PERFORM public.fiche_eleve_direction('fe000000-0000-4000-8000-000000000003');
    RAISE EXCEPTION 'FICHE ROUGE : un enseignant lit la fiche de la direction';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'FICHE OK : un enseignant ne lit pas la fiche';
  END;
END;
$ens$;
RESET ROLE;

-- anon et agent_ro n'ont pas le droit d'executer.
DO $acl$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.fiche_eleve_direction(uuid)'::pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'FICHE ROUGE : anon ou agent_ro execute la fiche';
  END IF;
  RAISE NOTICE 'FICHE OK : anon et agent_ro n''executent pas la fiche';
END;
$acl$;

-- La direction.
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('request.jwt.claim.sub', 'fe000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'fe000000-0000-4000-8000-000000000001', true);
SET LOCAL ROLE authenticated;
DO $direction$
DECLARE
  f jsonb;
BEGIN
  f := public.fiche_eleve_direction('fe000000-0000-4000-8000-000000000003');
  IF f IS NULL THEN
    RAISE EXCEPTION 'FICHE ROUGE : la direction ne lit pas la fiche d''un eleve';
  END IF;
  IF f #>> '{identite,prenom}' <> 'Yasmine' OR f #>> '{identite,matricule}' <> 'FICHEENFANT00001'
     OR f #>> '{identite,tranche}' <> 'enfant' OR f #>> '{identite,genre}' <> 'female' THEN
    RAISE EXCEPTION 'FICHE ROUGE : identite fausse : %', f -> 'identite';
  END IF;
  IF f #>> '{tuteur,prenom}' <> 'Amina' OR f #>> '{tuteur,courriel}' <> 'fiche-tuteur@example.test' THEN
    RAISE EXCEPTION 'FICHE ROUGE : tuteur faux : %', f -> 'tuteur';
  END IF;
  IF f #>> '{admission,niveau}' <> 'lecture_lente' OR f #>> '{admission,objectif}' <> 'devenir_fluide'
     OR f #>> '{admission,langue}' <> 'francais' THEN
    RAISE EXCEPTION 'FICHE ROUGE : admission fausse : %', f -> 'admission';
  END IF;
  IF pg_catalog.jsonb_array_length(f -> 'classes') <> 1
     OR f #>> '{classes,0,libelle}' <> 'Classe des lettres'
     OR f #>> '{classes,0,enseignant,prenom}' <> 'Salma'
     OR (f #>> '{classes,0,creneaux,0,jour}')::int <> 2
     OR (f #>> '{classes,0,creneaux,0,heure}')::int <> 18 THEN
    RAISE EXCEPTION 'FICHE ROUGE : classe fausse : %', f -> 'classes';
  END IF;
  IF (f #>> '{presences,total}')::int <> 1
     OR pg_catalog.jsonb_array_length(f #> '{presences,dernieres}') <> 1 THEN
    RAISE EXCEPTION 'FICHE ROUGE : presences fausses : %', f -> 'presences';
  END IF;
  IF f #>> '{admission,source}' <> 'mosquee' OR f #>> '{admission,moments,0}' <> 'soir'
     OR (f #>> '{admission,age}')::int <> 9 THEN
    RAISE EXCEPTION 'FICHE ROUGE : reponses de l''admission fausses : %', f -> 'admission';
  END IF;
  RAISE NOTICE 'FICHE OK : la direction lit identite, tuteur, admission, classe, presences';

  -- Un adulte qui apprend pour lui-meme : aucun tuteur, sans classe : liste vide.
  f := public.fiche_eleve_direction('fe000000-0000-4000-8000-000000000007');
  IF f IS NULL OR f #> '{tuteur}' <> 'null'::jsonb OR f #>> '{identite,tranche}' <> 'adulte'
     OR pg_catalog.jsonb_array_length(f -> 'classes') <> 0
     OR (f #>> '{presences,total}')::int <> 0 THEN
    RAISE EXCEPTION 'FICHE ROUGE : fiche d''un adulte fausse : %', f;
  END IF;
  RAISE NOTICE 'FICHE OK : un adulte n''a ni tuteur ni classe inventes';

  -- Un profil qui n'est pas un eleve, un inconnu : NULL, jamais une fiche vide.
  IF public.fiche_eleve_direction('fe000000-0000-4000-8000-000000000005') IS NOT NULL
     OR public.fiche_eleve_direction('fe000000-0000-4000-8000-0000000000aa') IS NOT NULL
     OR public.fiche_eleve_direction(NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'FICHE ROUGE : une fiche est rendue pour un non-eleve';
  END IF;
  RAISE NOTICE 'FICHE OK : un non-eleve ou un inconnu rend NULL';
END;
$direction$;
RESET ROLE;

ROLLBACK;
