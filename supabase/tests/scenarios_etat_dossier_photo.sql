-- PERF-ATTENTE dette 1 (migration 20261120200200) : etat_dossier() rend l'etat
-- de la photo et de l'accord de publication.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. un candidat enseignant sans photo : photo_posee faux, accord faux ;
--   2. avec une photo posee : photo_posee vrai, accord toujours faux ;
--   3. avec l'accord a la version publiee : vrai ; un accord a une AUTRE version
--      ou retire : faux (la meme regle que le refus de l'envoi) ;
--   4. un tuteur : les deux cles sont null, jamais faux ;
--   5. les cles d'avant (profil, role, statut, candidature...) sont toujours la ;
--   6. droits intacts : authenticated oui, anon non ; empreinte F86 a jour.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ETAT-DOSSIER-PHOTO ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('etat-photo-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'etat-photo-' || x || '@test.invalid' FROM unnest(ARRAY['cand', 'tut']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('f'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('cand'), 'EPH-ENS-0001', 'teacher', NULL, 'Candidat', 'Test', 'pending_kyc', 'female'),
       (pg_temp.id('tut'), 'EPH-TUT-0001', 'guardian', pg_temp.id('f'), 'Tuteur', 'Test', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id) VALUES (pg_temp.id('cand'))
  ON CONFLICT (profile_id) DO NOTHING;

-- 1. Sans photo, sans accord.
SELECT pg_temp.qui(pg_temp.id('cand'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (public.etat_dossier() -> 'photo_posee') = 'false'::jsonb
  AND (public.etat_dossier() -> 'accord_publication_signe') = 'false'::jsonb,
  'candidat sans photo ni accord : faux et faux');
RESET ROLE;

-- 2. Une photo posee.
UPDATE public.teacher_profiles SET photo_storage_key = 'photo.jpg' WHERE profile_id = pg_temp.id('cand');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (public.etat_dossier() -> 'photo_posee') = 'true'::jsonb
  AND (public.etat_dossier() -> 'accord_publication_signe') = 'false'::jsonb,
  'photo posee : vrai, accord toujours faux');
RESET ROLE;

-- 3. L'accord : a la version publiee, vrai ; autre version ou retire, faux.
INSERT INTO public.accords_publication (profile_id, version, nom_signe)
VALUES (pg_temp.id('cand'), 'ancienne-version', 'Candidat Test');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etat_dossier() -> 'accord_publication_signe') = 'false'::jsonb,
  'un accord a une autre version que la publiee : faux');
RESET ROLE;
UPDATE public.accords_publication
   SET version = (SELECT c.value #>> '{}' FROM public.app_config c WHERE c.key = 'enseignants.publication_version')
 WHERE profile_id = pg_temp.id('cand');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etat_dossier() -> 'accord_publication_signe') = 'true'::jsonb,
  'accord a la version publiee : vrai');
RESET ROLE;
UPDATE public.accords_publication SET retire_le = pg_catalog.clock_timestamp() WHERE profile_id = pg_temp.id('cand');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.etat_dossier() -> 'accord_publication_signe') = 'false'::jsonb,
  'accord retire : faux');

-- 5. Les cles d'avant sont toujours la.
SELECT pg_temp.vrai(
  public.etat_dossier() ?& ARRAY['profil', 'role', 'statut', 'piece_deposee', 'contrat_signe', 'accuse_signe',
                                  'code_conduite_signe', 'usage', 'suit_des_cours', 'candidature'],
  'les cles d''avant sont toujours la');
RESET ROLE;

-- 4. Un tuteur : null, jamais faux.
SELECT pg_temp.qui(pg_temp.id('tut'), 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  (public.etat_dossier() -> 'photo_posee') = 'null'::jsonb
  AND (public.etat_dossier() -> 'accord_publication_signe') = 'null'::jsonb,
  'un tuteur : photo_posee et accord_publication_signe valent null');
RESET ROLE;

-- 6. Droits et empreinte F86.
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('authenticated', 'public.etat_dossier()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.etat_dossier()', 'EXECUTE'),
  'etat_dossier : authenticated oui, anon non');
SELECT pg_temp.vrai(
  pg_catalog.obj_description('public.etat_dossier()'::regprocedure, 'pg_proc')
    LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.etat_dossier()'::regprocedure)) || ';%',
  'l''empreinte F86 est celle de la fonction en place');

ROLLBACK;
