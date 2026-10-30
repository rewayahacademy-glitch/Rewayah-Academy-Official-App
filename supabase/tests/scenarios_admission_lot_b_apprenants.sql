-- ADMISSION lot B, onboarding (fiche du 29/10/2026, Q2) : la demande garde
-- ses apprenants, dans la meme transaction ; les champs sont bornes ; le
-- titulaire relit les siens, et seulement les siens ; aucun client ne lit la
-- table. Rejoue sur une base neuve, apres stub_auth.sql et toutes les
-- migrations. Fixtures sans donnee personnelle ; tout est annule a la fin.
-- Un echec leve 'ADM-B-APP ROUGE : ...'.
BEGIN;

ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

INSERT INTO auth.users (id, email) VALUES
  ('ac000000-0000-4000-8000-000000000001', 'adm-b-app-famille@example.test'),
  ('ac000000-0000-4000-8000-000000000002', 'adm-b-app-adulte@example.test'),
  ('ac000000-0000-4000-8000-000000000003', 'adm-b-app-trop@example.test'),
  ('ac000000-0000-4000-8000-000000000004', 'adm-b-app-age@example.test'),
  ('ac000000-0000-4000-8000-000000000005', 'adm-b-app-sansenfant@example.test');

SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('test.jwt', '{}', true);

-- Une famille : deux enfants et le parent, qui suit des cours.
SELECT set_config('request.jwt.claim.sub', 'ac000000-0000-4000-8000-000000000001', true);
SELECT set_config('test.uid', 'ac000000-0000-4000-8000-000000000001', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Fixture', 'Famille', 'female', 'Europe/Paris', true,
  '[{"prenom": "Enfant Un", "age": 9, "genre": "male", "niveau": "debut_lettres",
     "objectif": "apprendre_a_lire", "moments": ["soir"], "langue": "francais"},
    {"prenom": "Enfant Deux", "age": 14, "genre": "female", "niveau": "lecture_lente",
     "objectif": "memoriser", "moments": ["matin", "apres_midi"]},
    {"est_titulaire": true, "prenom": "ignore", "niveau": "lecture_courante",
     "objectif": "devenir_fluide", "moments": []}]'::jsonb);
SELECT pg_catalog.jsonb_array_length(public.mes_apprenants_demande()) AS relus_famille;
RESET ROLE;

-- « Pour moi » : un seul apprenant, le titulaire.
SELECT set_config('request.jwt.claim.sub', 'ac000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ac000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Fixture', 'Adulte', 'male', 'Europe/Paris', false,
  '[{"est_titulaire": true, "niveau": "memorisation_partielle", "objectif": "indecis",
     "moments": ["matin"]}]'::jsonb);
RESET ROLE;

DO $controles$
DECLARE
  v_n integer;
  v_relus jsonb;
BEGIN
  SELECT count(*) INTO v_n
    FROM public.candidature_apprenants a
    JOIN public.candidatures c ON c.id = a.candidature_id
   WHERE c.profile_id = 'ac000000-0000-4000-8000-000000000001' AND c.type_code = 'famille';
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : % apprenant(s) pour la famille, 3 attendus', v_n;
  END IF;
  -- Le titulaire porte son prenom et son genre de compte, jamais ceux du JSON.
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ac000000-0000-4000-8000-000000000001'
          AND a.est_titulaire AND a.prenom = 'Fixture' AND a.genre = 'female'
          AND a.age IS NULL AND a.rang = 3) THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : le titulaire n''a pas son prenom, son genre ou son rang';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ac000000-0000-4000-8000-000000000001'
          AND a.rang = 2 AND a.age = 14 AND a.genre = 'female'
          AND a.moments = ARRAY['matin', 'apres_midi'] AND a.langue_code IS NULL) THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : le second enfant n''est pas range tel quel';
  END IF;
  -- Aucun profil d'enfant avant la decision.
  SELECT count(*) INTO v_n FROM public.profiles p
    WHERE p.household_id = (SELECT household_id FROM public.profiles
                             WHERE id = 'ac000000-0000-4000-8000-000000000001')
      AND p.role = 'student';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : % profil(s) d''enfant cree(s) avant la decision', v_n;
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
         JOIN public.candidatures c ON c.id = a.candidature_id
        WHERE c.profile_id = 'ac000000-0000-4000-8000-000000000002'
          AND c.type_code = 'eleve_adulte' AND a.est_titulaire
          AND a.niveau_declare = 'memorisation_partielle') THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : l''apprenant de « pour moi » manque';
  END IF;
  -- Aucun client ne lit la table.
  IF pg_catalog.has_table_privilege('authenticated', 'public.candidature_apprenants', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.candidature_apprenants', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.candidature_apprenants', 'INSERT') THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : la table est ouverte a un client';
  END IF;
  RAISE NOTICE 'ADM-B-APP OK : apprenants ranges, titulaire de compte, aucun profil d''enfant, table fermee';
END
$controles$;

-- Le titulaire de « pour moi » ne relit que les siens.
SELECT set_config('request.jwt.claim.sub', 'ac000000-0000-4000-8000-000000000002', true);
SELECT set_config('test.uid', 'ac000000-0000-4000-8000-000000000002', true);
SET LOCAL ROLE authenticated;
DO $relecture$
DECLARE
  v_relus jsonb := public.mes_apprenants_demande();
BEGIN
  IF pg_catalog.jsonb_array_length(v_relus) <> 1
     OR (v_relus -> 0 ->> 'est_titulaire')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : relecture de « pour moi » fausse : %', v_relus;
  END IF;
  RAISE NOTICE 'ADM-B-APP OK : chacun relit ses apprenants, et seulement les siens';
END
$relecture$;
RESET ROLE;

-- Refus : plus de 6 apprenants, un age hors bornes, une famille sans enfant,
-- un enfant dans « pour moi ». Chaque refus n'a rien cree.
SET LOCAL ROLE authenticated;
DO $refus$
DECLARE
  v_cas record;
BEGIN
  FOR v_cas IN
    SELECT * FROM (VALUES
      ('ac000000-0000-4000-8000-000000000003', 'famille',
       (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
          'prenom', 'E' || i, 'age', 8, 'genre', 'male'))
          FROM pg_catalog.generate_series(1, 7) AS i), 'plus de 6'),
      ('ac000000-0000-4000-8000-000000000004', 'famille',
       '[{"prenom": "Grand", "age": 19, "genre": "male"}]'::jsonb, 'age 19'),
      ('ac000000-0000-4000-8000-000000000005', 'famille', '[]'::jsonb, 'sans enfant'),
      ('ac000000-0000-4000-8000-000000000005', 'moi',
       '[{"prenom": "Enfant", "age": 8, "genre": "male"}]'::jsonb, 'enfant pour moi')
    ) AS t(uid, usage, apprenants, nom)
  LOOP
    PERFORM set_config('request.jwt.claim.sub', v_cas.uid, true);
    PERFORM set_config('test.uid', v_cas.uid, true);
    BEGIN
      PERFORM public.inscrire_titulaire(v_cas.usage, 'Fixture', 'Refus', 'male',
                                        'Europe/Paris', false, v_cas.apprenants);
      RAISE EXCEPTION 'ADM-B-APP ROUGE : % accepte', v_cas.nom;
    EXCEPTION
      WHEN invalid_parameter_value OR check_violation THEN NULL;
    END;
  END LOOP;
  RAISE NOTICE 'ADM-B-APP OK : plus de 6, age hors bornes, famille sans enfant, enfant pour moi : refuses';
END
$refus$;
RESET ROLE;

DO $rien_cree$
BEGIN
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id IN (
       'ac000000-0000-4000-8000-000000000003', 'ac000000-0000-4000-8000-000000000004',
       'ac000000-0000-4000-8000-000000000005')) THEN
    RAISE EXCEPTION 'ADM-B-APP ROUGE : un refus a laisse un profil';
  END IF;
  RAISE NOTICE 'ADM-B-APP OK : un refus ne laisse rien';
END
$rien_cree$;

ROLLBACK;
