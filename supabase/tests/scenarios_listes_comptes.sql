-- LISTES, Comptes séparé par rôle (directeur, 30/10/2026) :
-- `comptes_admin_par_role()` rend les mêmes comptes que `comptes_admin()`, avec
-- la tranche d'âge et la classe d'un élève, le tuteur dont il
-- dépend, le pays d'un enseignant et la demande d'admission encore à traiter.
-- Un tuteur qui est aussi élève (deux profils dans un foyer) a deux lignes de
-- rôles différents, jamais deux lignes du même rôle. Un compte qui n'est pas de
-- la direction ne lit rien ; anon et agent_ro n'exécutent pas la fonction.
-- Rejoué sur une base neuve, après stub_auth.sql et toutes les migrations.
-- Tout est annulé à la fin. Un échec lève 'LISTES ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('1c000000-0000-4000-8000-000000000001', 'listes-direction@example.test'),
  ('1c000000-0000-4000-8000-000000000002', 'listes-tuteur@example.test'),
  ('1c000000-0000-4000-8000-000000000003', 'listes-enfant@example.test'),
  ('1c000000-0000-4000-8000-000000000004', 'listes-tuteur-eleve@example.test'),
  ('1c000000-0000-4000-8000-000000000005', 'listes-enseignant@example.test'),
  ('1c000000-0000-4000-8000-000000000006', 'listes-famille@example.test'),
  ('1c000000-0000-4000-8000-000000000007', 'listes-titulaire@example.test');

INSERT INTO public.households (id) VALUES
  ('1c000000-0000-4000-8000-0000000000f1'),
  ('1c000000-0000-4000-8000-0000000000f2');

-- La direction est une femme : une demande d'admission en cours d'une famille
-- tenue par une femme est dans sa portée (compte_candidat_hors_portee).
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('1c000000-0000-4000-8000-000000000001', 'LISTESADMIN00001', 'admin', NULL,
   'Fixture', 'Direction', 'active', 'female'),
  ('1c000000-0000-4000-8000-000000000002', 'LISTESTUTEUR0001', 'guardian',
   '1c000000-0000-4000-8000-0000000000f1', 'Amina', 'Tuteur', 'active', 'female'),
  ('1c000000-0000-4000-8000-000000000003', 'LISTESENFANT0001', 'student',
   '1c000000-0000-4000-8000-0000000000f1', 'Yasmine', 'Enfant', 'active', 'female'),
  -- La même personne que la tutrice, élève adulte du même foyer.
  ('1c000000-0000-4000-8000-000000000004', 'LISTESADULTE0001', 'student',
   '1c000000-0000-4000-8000-0000000000f1', 'Amina', 'Tuteur', 'active', 'female'),
  ('1c000000-0000-4000-8000-000000000005', 'LISTESENSEIG0001', 'teacher', NULL,
   'Fixture', 'Enseignant', 'pending_kyc', 'female'),
  -- D5 (30/10/2026) : un adulte titulaire qui apprend pour lui-meme, un seul
  -- compte `guardian` avec une fiche d'eleve autonome sur lui-meme.
  ('1c000000-0000-4000-8000-000000000007', 'LISTESTITULA0001', 'guardian',
   '1c000000-0000-4000-8000-0000000000f2', 'Karim', 'Titulaire', 'active', 'female');

UPDATE public.households SET primary_guardian_id = '1c000000-0000-4000-8000-000000000002'
 WHERE id = '1c000000-0000-4000-8000-0000000000f1';

INSERT INTO public.student_profiles (profile_id, student_type) VALUES
  ('1c000000-0000-4000-8000-000000000003', 'minor'),
  ('1c000000-0000-4000-8000-000000000004', 'autonomous'),
  ('1c000000-0000-4000-8000-000000000007', 'autonomous');
INSERT INTO public.teacher_profiles (profile_id, country) VALUES
  ('1c000000-0000-4000-8000-000000000005', 'MA');

INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
VALUES ('1c000000-0000-4000-8000-0000000000c1', '1c000000-0000-4000-8000-000000000005',
        'enfant', 5, 'Classe des lettres', 2, 18);
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
VALUES ('1c000000-0000-4000-8000-0000000000c2', '1c000000-0000-4000-8000-000000000005',
        'adulte', 6, 'Classe des adultes', 3, 20);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES
  ('1c000000-0000-4000-8000-0000000000c1', '1c000000-0000-4000-8000-000000000003'),
  ('1c000000-0000-4000-8000-0000000000c2', '1c000000-0000-4000-8000-000000000007');

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Une famille s'inscrit (lot B) : sa demande est reçue, à traiter.
SELECT set_config('request.jwt.claim.sub', '1c000000-0000-4000-8000-000000000006', true);
SELECT set_config('test.uid', '1c000000-0000-4000-8000-000000000006', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', false,
  '[{"prenom": "Enfant Un", "age": 9, "genre": "female", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"}]'::jsonb);
RESET ROLE;

-- Un compte qui n'est pas de la direction ne lit rien.
SELECT set_config('request.jwt.claim.sub', '1c000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', '1c000000-0000-4000-8000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"guardian"}}', true);
SET LOCAL ROLE authenticated;
DO $tuteur$
BEGIN
  IF EXISTS (SELECT 1 FROM public.comptes_admin_par_role()) THEN
    RAISE EXCEPTION 'LISTES ROUGE : un tuteur lit les comptes de la direction';
  END IF;
  RAISE NOTICE 'LISTES OK : un tuteur ne lit aucun compte';
END;
$tuteur$;
RESET ROLE;

-- La direction.
SELECT set_config('request.jwt.claim.sub', '1c000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', '1c000000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

DO $direction$
DECLARE
  r record;
  v_nombre integer;
BEGIN
  -- Les mêmes comptes que comptes_admin(), ni plus ni moins.
  IF EXISTS (
       (SELECT profile_id FROM public.comptes_admin()
        EXCEPT SELECT profile_id FROM public.comptes_admin_par_role())
       UNION ALL
       (SELECT profile_id FROM public.comptes_admin_par_role()
        EXCEPT SELECT profile_id FROM public.comptes_admin())) THEN
    RAISE EXCEPTION 'LISTES ROUGE : comptes_admin_par_role ne rend pas les memes comptes';
  END IF;
  SELECT pg_catalog.count(*) INTO v_nombre FROM public.comptes_admin_par_role();
  IF v_nombre < 7 THEN
    RAISE EXCEPTION 'LISTES ROUGE : % comptes lus, 7 attendus au moins', v_nombre;
  END IF;
  RAISE NOTICE 'LISTES OK : les memes comptes que comptes_admin (%)', v_nombre;

  -- L'enfant : enfant, sa classe, sa tutrice.
  SELECT * INTO r FROM public.comptes_admin_par_role()
   WHERE profile_id = '1c000000-0000-4000-8000-000000000003';
  IF r.tranche_age IS DISTINCT FROM 'enfant'
     OR r.classe_id IS DISTINCT FROM '1c000000-0000-4000-8000-0000000000c1'
     OR r.classe_libelle IS DISTINCT FROM 'Classe des lettres'
     OR r.classe_numero IS DISTINCT FROM 1
     OR r.classes_actives IS DISTINCT FROM 1
     OR r.tuteur_id IS DISTINCT FROM '1c000000-0000-4000-8000-000000000002'
     OR r.tuteur_prenom IS DISTINCT FROM 'Amina'
     OR NOT r.est_apprenant THEN
    RAISE EXCEPTION 'LISTES ROUGE : ligne de l''enfant incomplete : %', r;
  END IF;
  RAISE NOTICE 'LISTES OK : un enfant porte sa tranche, sa classe et son tuteur';

  -- L'élève adulte, même personne que la tutrice : adulte, sans classe, même tuteur.
  SELECT * INTO r FROM public.comptes_admin_par_role()
   WHERE profile_id = '1c000000-0000-4000-8000-000000000004';
  IF r.role IS DISTINCT FROM 'student' OR r.tranche_age IS DISTINCT FROM 'adulte'
     OR r.classe_id IS NOT NULL OR r.classes_actives IS DISTINCT FROM 0
     OR r.tuteur_id IS DISTINCT FROM '1c000000-0000-4000-8000-000000000002' THEN
    RAISE EXCEPTION 'LISTES ROUGE : ligne de l''eleve adulte incorrecte : %', r;
  END IF;

  -- La tutrice : une ligne de tuteur, sans tranche, classe ni tuteur ; deux élèves au foyer.
  SELECT * INTO r FROM public.comptes_admin_par_role()
   WHERE profile_id = '1c000000-0000-4000-8000-000000000002';
  IF r.role IS DISTINCT FROM 'guardian' OR r.tranche_age IS NOT NULL OR r.classe_id IS NOT NULL
     OR r.classes_actives IS NOT NULL OR r.tuteur_id IS NOT NULL
     OR r.enfants_du_foyer IS DISTINCT FROM 2 OR r.admission_a_traiter
     OR r.est_apprenant THEN
    RAISE EXCEPTION 'LISTES ROUGE : ligne de la tutrice incorrecte : %', r;
  END IF;
  -- Jamais deux lignes du même rôle pour une même personne (même foyer, même nom).
  IF EXISTS (SELECT 1 FROM public.comptes_admin_par_role() c
              WHERE c.foyer_id = '1c000000-0000-4000-8000-0000000000f1'
              GROUP BY c.role, c.prenom, c.nom HAVING pg_catalog.count(*) > 1) THEN
    RAISE EXCEPTION 'LISTES ROUGE : une personne a deux lignes du meme role';
  END IF;
  RAISE NOTICE 'LISTES OK : la tutrice aussi eleve a une ligne de tuteur et une ligne d''eleve';

  -- L'adulte titulaire (D5) : un seul compte, tuteur ET apprenant, avec sa
  -- tranche et sa classe ; personne d'autre dont il depende.
  SELECT * INTO r FROM public.comptes_admin_par_role()
   WHERE profile_id = '1c000000-0000-4000-8000-000000000007';
  IF r.role IS DISTINCT FROM 'guardian' OR NOT r.est_apprenant
     OR r.tranche_age IS DISTINCT FROM 'adulte'
     OR r.classe_id IS DISTINCT FROM '1c000000-0000-4000-8000-0000000000c2'
     OR r.classes_actives IS DISTINCT FROM 1
     OR r.tuteur_id IS NOT NULL THEN
    RAISE EXCEPTION 'LISTES ROUGE : ligne de l''adulte titulaire incorrecte : %', r;
  END IF;
  RAISE NOTICE 'LISTES OK : l''adulte titulaire est apprenant, avec sa tranche et sa classe';

  -- L'enseignant : son pays ; aucune donnée d'élève.
  SELECT * INTO r FROM public.comptes_admin_par_role()
   WHERE profile_id = '1c000000-0000-4000-8000-000000000005';
  IF r.teacher_country IS DISTINCT FROM 'MA' OR r.tranche_age IS NOT NULL
     OR r.tuteur_id IS NOT NULL THEN
    RAISE EXCEPTION 'LISTES ROUGE : ligne de l''enseignant incorrecte : %', r;
  END IF;
  RAISE NOTICE 'LISTES OK : l''enseignant porte son pays';

  -- La famille inscrite : sa demande d'admission est à traiter.
  SELECT * INTO r FROM public.comptes_admin_par_role()
   WHERE profile_id = '1c000000-0000-4000-8000-000000000006';
  IF NOT FOUND OR NOT r.admission_a_traiter THEN
    RAISE EXCEPTION 'LISTES ROUGE : la demande de la famille n''est pas dite a traiter : %', r;
  END IF;
  RAISE NOTICE 'LISTES OK : la famille inscrite attend une decision d''admission';
END;
$direction$;
RESET ROLE;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.comptes_admin_par_role()'::pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'LISTES ROUGE : droits d''execution incorrects';
  END IF;
  RAISE NOTICE 'LISTES OK : anon et agent_ro n''executent pas, authenticated oui';
END;
$droits$;

ROLLBACK;
