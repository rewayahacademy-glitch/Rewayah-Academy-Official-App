-- PROFIL-TITULAIRE (07/11/2026, migration 20261111100000) : le profil eleve
-- du titulaire apparait dans profils_du_foyer_v, sous les memes gardes.
--   * le titulaire cree son profil eleve (creer_profil_eleve_titulaire) et
--     le lit dans la vue, a cote de son enfant ;
--   * un second tuteur du foyer le lit aussi, mais n'a pas de ligne lui-meme
--     (aucune fiche d'apprentissage) ;
--   * l'enfant ne lit que sa propre ligne, jamais celle du titulaire ;
--   * un autre foyer ne lit rien de celui-ci ; anon n'a plus SELECT sur la
--     vue (lecture refusee), authenticated l'a toujours ;
--   * le parcours connait deja sa tranche (adulte_18_plus) : aucune question
--     d'age a reposer ;
--   * la recharge lui propose le tarif ADULTE du mois, 6500 (65 $), et 5500
--     (55 $) a l'enfant : docs/current/tarifs-2026-10-18.json,
--     formules.adulte.prix_mensuel_mineur et formules.enfant.prix_mensuel_mineur.
-- Chaque refus a son controle positif. Base NEUVE (fixtures annulees).
\o /dev/null
BEGIN;
\ir _acl_photo.sql

CREATE FUNCTION pg_temp.qui_foyer(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('app_metadata',
    pg_catalog.json_strip_nulls(pg_catalog.json_build_object('role', p_role,
      'household_id', p_foyer)))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.personne() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  PERFORM pg_catalog.set_config('test.uid', '', true);
  PERFORM pg_catalog.set_config('request.jwt.claims', '', true);
  PERFORM pg_catalog.set_config('test.jwt', '', true);
END $$;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui_foyer(uuid, text, uuid), pg_temp.personne(),
  pg_temp.ok(text), pg_temp.vrai(boolean, text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users(id, email) VALUES
 ('7f100000-0000-4000-8000-0000000000a1','pt-tit@test.invalid'),
 ('7f100000-0000-4000-8000-0000000000a2','pt-co@test.invalid'),
 ('7f100000-0000-4000-8000-0000000000a3','pt-autre@test.invalid'),
 ('7f100000-0000-4000-8000-0000000000e1','pt-e1@test.invalid'),
 ('7f100000-0000-4000-8000-0000000000e2','pt-e2@test.invalid');
INSERT INTO public.households(id, timezone) VALUES
 ('7f100000-0000-4000-8000-0000000000f1','Europe/Paris'),
 ('7f100000-0000-4000-8000-0000000000f2','Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 ('7f100000-0000-4000-8000-0000000000a1','PT-TUT-0001','guardian','7f100000-0000-4000-8000-0000000000f1','Dyna','PT','active','female'),
 ('7f100000-0000-4000-8000-0000000000a2','PT-TUT-0002','guardian','7f100000-0000-4000-8000-0000000000f1','Karim','PT','active','male'),
 ('7f100000-0000-4000-8000-0000000000a3','PT-TUT-0003','guardian','7f100000-0000-4000-8000-0000000000f2','Sara','PT','active','female'),
 ('7f100000-0000-4000-8000-0000000000e1','PT-ELV-0001','student','7f100000-0000-4000-8000-0000000000f1','Yasmine','PT','active','female'),
 ('7f100000-0000-4000-8000-0000000000e2','PT-ELV-0002','student','7f100000-0000-4000-8000-0000000000f2','Adam','PT','active','male');
UPDATE public.households SET primary_guardian_id = '7f100000-0000-4000-8000-0000000000a1'
 WHERE id = '7f100000-0000-4000-8000-0000000000f1';
UPDATE public.households SET primary_guardian_id = '7f100000-0000-4000-8000-0000000000a3'
 WHERE id = '7f100000-0000-4000-8000-0000000000f2';
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('7f100000-0000-4000-8000-0000000000e1','minor','standard'),
 ('7f100000-0000-4000-8000-0000000000e2','minor','standard');

-- ------------------------------------------------------------
-- 1. Forme : memes colonnes, meme ordre, garde intacte
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum)
                       FROM pg_catalog.pg_attribute a
                      WHERE a.attrelid = 'public.profils_du_foyer_v'::pg_catalog.regclass
                        AND a.attnum > 0 AND NOT a.attisdropped)
                    = 'id,first_name,immutable_id,interface_mode,camera_policy,avatar_storage_key,access_until',
  'profils_du_foyer_v : memes colonnes, meme ordre');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                             WHERE c.oid = 'public.profils_du_foyer_v'::pg_catalog.regclass
                               AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']),
  'profils_du_foyer_v : security_barrier garde');

-- ------------------------------------------------------------
-- 2. Avant la creation : le titulaire n'a pas de ligne (aucune fiche)
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('7f100000-0000-4000-8000-0000000000a1','guardian','7f100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(id ORDER BY id) FROM public.profils_du_foyer_v)
                    = ARRAY['7f100000-0000-4000-8000-0000000000e1'::uuid],
  'titulaire sans fiche : seul son enfant (un tuteur sans fiche n''a pas de ligne)');
-- Le titulaire cree son profil eleve (0052).
SELECT pg_temp.vrai(public.creer_profil_eleve_titulaire() = '7f100000-0000-4000-8000-0000000000a1',
  'titulaire : creer_profil_eleve_titulaire rend son identifiant');
-- 3. Apres : il se lit a cote de son enfant, une ligne chacun.
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(id ORDER BY id) FROM public.profils_du_foyer_v)
                    = ARRAY['7f100000-0000-4000-8000-0000000000a1'::uuid,
                            '7f100000-0000-4000-8000-0000000000e1'::uuid],
  'titulaire : son profil eleve ET son enfant, une ligne chacun');
SELECT pg_temp.vrai((SELECT first_name FROM public.profils_du_foyer_v
                      WHERE id = '7f100000-0000-4000-8000-0000000000a1') = 'Dyna',
  'titulaire : sa ligne porte son prenom');
-- Le parcours connait deja sa tranche : aucune question d'age a reposer.
SELECT pg_temp.vrai((SELECT cohorte FROM public.v_parcours_onboarding
                      WHERE eleve_id = '7f100000-0000-4000-8000-0000000000a1') = 'adulte_18_plus',
  'titulaire : le parcours lit sa tranche adulte_18_plus (pas de question d''age)');
-- La recharge : tarif adulte du mois pour lui, tarif enfant pour son enfant.
SELECT pg_temp.vrai(EXISTS (
         SELECT 1 FROM pg_catalog.jsonb_array_elements(public.recharge_beneficiaires()) b,
                       pg_catalog.jsonb_array_elements(b -> 'formules') f
          WHERE b ->> 'id' = '7f100000-0000-4000-8000-0000000000a1'
            AND f ->> 'formule' = 'mois'
            AND (f -> 'montant' ->> 'mineur')::bigint = 6500
            AND f -> 'montant' ->> 'devise' = 'USD'),
  'recharge : le titulaire au tarif adulte du mois, 6500 USD (65 $)');
SELECT pg_temp.vrai(NOT EXISTS (
         SELECT 1 FROM pg_catalog.jsonb_array_elements(public.recharge_beneficiaires()) b,
                       pg_catalog.jsonb_array_elements(b -> 'formules') f
          WHERE b ->> 'id' = '7f100000-0000-4000-8000-0000000000a1'
            AND f ->> 'formule' = 'mois'
            AND (f -> 'montant' ->> 'mineur')::bigint = 5500),
  'recharge : jamais le tarif enfant pour le titulaire');
SELECT pg_temp.vrai(EXISTS (
         SELECT 1 FROM pg_catalog.jsonb_array_elements(public.recharge_beneficiaires()) b,
                       pg_catalog.jsonb_array_elements(b -> 'formules') f
          WHERE b ->> 'id' = '7f100000-0000-4000-8000-0000000000e1'
            AND f ->> 'formule' = 'mois'
            AND (f -> 'montant' ->> 'mineur')::bigint = 5500),
  'recharge : son enfant au tarif enfant du mois, 5500 USD (controle positif)');
RESET ROLE;

-- ------------------------------------------------------------
-- 4. Le second tuteur du foyer, l'enfant, l'autre foyer, anon
-- ------------------------------------------------------------
SELECT pg_temp.qui_foyer('7f100000-0000-4000-8000-0000000000a2','guardian','7f100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(id ORDER BY id) FROM public.profils_du_foyer_v)
                    = ARRAY['7f100000-0000-4000-8000-0000000000a1'::uuid,
                            '7f100000-0000-4000-8000-0000000000e1'::uuid],
  'second tuteur : le profil eleve du titulaire et l''enfant, pas de ligne a lui');
RESET ROLE;

SELECT pg_temp.qui_foyer('7f100000-0000-4000-8000-0000000000e1','student','7f100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(id) FROM public.profils_du_foyer_v)
                    = ARRAY['7f100000-0000-4000-8000-0000000000e1'::uuid],
  'enfant : sa seule ligne, jamais celle du titulaire');
RESET ROLE;

SELECT pg_temp.qui_foyer('7f100000-0000-4000-8000-0000000000a3','guardian','7f100000-0000-4000-8000-0000000000f2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(id) FROM public.profils_du_foyer_v)
                    = ARRAY['7f100000-0000-4000-8000-0000000000e2'::uuid],
  'autre foyer : son enfant seul, rien du foyer 1');
RESET ROLE;

-- anon n'a plus SELECT (garde-cap, 07/11/2026) ; authenticated l'a.
SELECT pg_temp.vrai(NOT pg_catalog.has_table_privilege('anon', 'public.profils_du_foyer_v', 'SELECT'),
  'anon : plus de droit SELECT sur la vue');
SELECT pg_temp.vrai(pg_catalog.has_table_privilege('authenticated', 'public.profils_du_foyer_v', 'SELECT'),
  'authenticated : garde SELECT sur la vue');
SELECT pg_temp.personne();
SET LOCAL ROLE anon;
DO $anon$
BEGIN
  PERFORM 1 FROM public.profils_du_foyer_v;
  RAISE EXCEPTION 'ROUGE : anon lit encore la vue';
EXCEPTION WHEN insufficient_privilege THEN
  PERFORM pg_temp.ok('anon : la lecture est refusee (42501)');
END $anon$;
RESET ROLE;

-- ------------------------------------------------------------
-- 5. Un tuteur dont la fiche n'est pas celle d'un titulaire : pas de ligne
-- ------------------------------------------------------------
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
 ('7f100000-0000-4000-8000-0000000000a2','autonomous','standard');
SELECT pg_temp.qui_foyer('7f100000-0000-4000-8000-0000000000a1','guardian','7f100000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profils_du_foyer_v
                                 WHERE id = '7f100000-0000-4000-8000-0000000000a2'),
  'tuteur avec une fiche sans titulaire_profile_id : toujours pas de ligne');
RESET ROLE;

\ir _acl_retablir.sql

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 17 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 17 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'PROFIL-TITULAIRE : % controles verts', current_setting('test.r_n');
END $fin$;

ROLLBACK;
