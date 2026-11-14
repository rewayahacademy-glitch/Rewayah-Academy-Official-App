-- BANNISSEMENT-DATE-FINIE (14/11/2026 ; migration 20261125500000) : un compte
-- supprime ne porte jamais banned_until = 'infinity' (le serveur Auth plante a
-- la lecture : POST /otp 500, « unsupported Scan »).
--
--   A. retrait et anonymisation : date finie lointaine, jamais infinity ;
--   B. la restauration marche encore et ne reecrit jamais l'infini ;
--   C. le rattrapage des comptes deja bannis a l'infini.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR (p_message IS NOT NULL AND SQLERRM <> p_message) THEN
      RAISE EXCEPTION 'ROUGE : % (% « % » au lieu de % « % »)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5e9b0000-0000-4000-8000-' || pg_catalog.lpad(p, 12, '0'))::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated', 'aal', p_aal,
  'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;


GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text, text),
  pg_temp.qui(uuid, text, text), pg_temp.u(text) TO authenticated, anon;

-- Le stub d'auth n'a pas la colonne de Supabase ; les fonctions la lisent au catalogue.
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS banned_until timestamptz;

-- Fixtures : D direction ; A1, A2 eleves adultes (un compte retire par la direction,
-- un compte deja banni a l'infini par l'ancien code) ; A3 compte anonymise.
INSERT INTO auth.users (id, email) VALUES
  (pg_temp.u('1'), 'bandf-a1@example.test'), (pg_temp.u('2'), 'bandf-a2@example.test'),
  (pg_temp.u('3'), 'bandf-a3@example.test'), (pg_temp.u('31'), 'bandf-d@example.test');
INSERT INTO public.households (id, timezone) VALUES (pg_temp.u('101'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, gender, account_status) VALUES
  (pg_temp.u('1'), 'BANDF-A1', 'student', pg_temp.u('101'), 'Karim', 'Un', 'male', 'active'),
  (pg_temp.u('2'), 'BANDF-A2', 'student', pg_temp.u('101'), 'Yacine', 'Deux', 'male', 'active'),
  (pg_temp.u('3'), 'BANDF-A3', 'student', pg_temp.u('101'), 'Salma', 'Trois', 'female', 'active'),
  (pg_temp.u('31'), 'BANDF-D', 'admin', NULL, 'Direction', 'Une', 'female', 'active');
INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy, langue_cours, cohorte, niveau_declare, objectif)
VALUES
  (pg_temp.u('1'), 'autonomous', 'standard', 'allowed', 'francais', NULL, 'debut_lettres', 'apprendre_a_lire'),
  (pg_temp.u('2'), 'autonomous', 'standard', 'allowed', 'francais', NULL, 'debut_lettres', 'apprendre_a_lire'),
  (pg_temp.u('3'), 'autonomous', 'standard', 'allowed', 'francais', NULL, 'debut_lettres', 'apprendre_a_lire');

-- A. Retrait par la direction : le bannissement est une date FINIE.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('1')], 'profil de test', false);
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('3')], 'profil de test', true);
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.vrai(
  (SELECT u.banned_until IS NOT NULL AND u.banned_until <> 'infinity'::timestamptz
          AND u.banned_until > pg_catalog.now() + interval '100 years'
     FROM auth.users u WHERE u.id = pg_temp.u('1')),
  'A.1 un compte retire est banni jusqu''a une date finie lointaine, jamais infinity');
SELECT pg_temp.vrai(
  (SELECT u.banned_until IS NOT NULL AND u.banned_until <> 'infinity'::timestamptz
     FROM auth.users u WHERE u.id = pg_temp.u('3')),
  'A.2 un compte anonymise est banni jusqu''a une date finie, jamais infinity');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.banned_until = 'infinity'::timestamptz),
  'A.3 aucun compte ne porte infinity apres retrait et anonymisation');

-- B. La restauration marche encore, et ne remet pas d'infini.
-- Etat d'avant infini (ancien code) : la restauration ecrit une date finie.
UPDATE private.retraits_comptes SET banni_avant = 'infinity'::timestamptz WHERE profile_id = pg_temp.u('1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT pg_temp.vrai(
  (public.direction_restaurer_comptes(ARRAY[pg_temp.u('1')]) -> 0 ->> 'statut') = 'restaure',
  'B.1 la restauration d''un compte retire marche encore');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT u.banned_until <> 'infinity'::timestamptz FROM auth.users u WHERE u.id = pg_temp.u('1')),
  'B.2 un banni_avant infini n''est jamais reecrit en infini');
-- Etat d'avant normal (NULL) : le compte restaure n'est plus banni.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('1')], 'second retrait', false);
RESET ROLE;
UPDATE private.retraits_comptes SET banni_avant = NULL WHERE profile_id = pg_temp.u('1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT public.direction_restaurer_comptes(ARRAY[pg_temp.u('1')]);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT u.banned_until IS NULL FROM auth.users u WHERE u.id = pg_temp.u('1')),
  'B.3 la restauration rend un compte non banni quand il ne l''etait pas avant');

-- C. La migration rattrape les comptes deja bannis a l'infini.
UPDATE auth.users SET banned_until = 'infinity'::timestamptz WHERE id = pg_temp.u('2');
UPDATE auth.users SET banned_until = '2999-12-31 00:00:00+00'::timestamptz
 WHERE banned_until = 'infinity'::timestamptz;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.banned_until = 'infinity'::timestamptz),
  'C.1 la requete de rattrapage de la migration ne laisse aucun infini');

-- D. Reinviter une adresse dont le compte a ete supprime : la fonction renvoie
-- l'id de l'ancien compte et journalise, sans toucher a auth.
SET session_replication_role = replica;
INSERT INTO public.invitations_enseignant (code, email, cree_par, cree_le, expire_le)
VALUES ('BAND-2345-6789', 'bandf-a1@example.test', pg_temp.u('31'), now(), now() + interval '14 days'),
       ('BAND-2345-ECHU', 'bandf-a2@example.test', pg_temp.u('31'), now() - interval '20 days', now() - interval '1 day');
SET session_replication_role = origin;
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('1'), pg_temp.u('2')], 'second retrait', false);
RESET ROLE;
SELECT pg_temp.vrai(
  pg_catalog.has_function_privilege('service_role', 'public.invitation_compte_ancien_a_liberer(text,text,text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.invitation_compte_ancien_a_liberer(text,text,text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'public.invitation_compte_ancien_a_liberer(text,text,text)', 'EXECUTE'),
  'D.1 seul service_role execute la recherche du compte a liberer');
SELECT pg_temp.vrai(
  public.invitation_compte_ancien_a_liberer('foyer', 'BAND-2345-6789', 'bandf-a1@example.test') IS NULL
  AND public.invitation_compte_ancien_a_liberer('equipe', 'BAND-2345-0000', 'bandf-a1@example.test') IS NULL
  AND public.invitation_compte_ancien_a_liberer('equipe', 'BAND-2345-6789', 'autre@example.test') IS NULL
  AND public.invitation_compte_ancien_a_liberer('equipe', 'BAND-2345-ECHU', 'bandf-a2@example.test') IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs l WHERE l.action = 'invitation_adresse_liberee'),
  'D.2 jamais pour foyer, un faux code, une autre adresse ou un code echu : aucun id, aucun audit');
SELECT pg_catalog.set_config('test.ancien', coalesce(public.invitation_compte_ancien_a_liberer(
  'equipe', 'band-2345-6789', 'Bandf-A1@Example.test')::text, ''), true);
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.ancien') = pg_temp.u('1')::text
  AND EXISTS (SELECT 1 FROM public.audit_logs l WHERE l.action = 'invitation_adresse_liberee')
  AND (SELECT u.email FROM auth.users u WHERE u.id = pg_temp.u('1')) = 'bandf-a1@example.test'
  AND (SELECT p.deleted_at IS NOT NULL FROM public.profiles p WHERE p.id = pg_temp.u('1')),
  'D.3 un code valide : l''id de l''ancien compte est rendu et journalise ; auth.users n''est pas touche (l''Edge libere par l''API admin)');
-- Un compte banni pour une autre raison (profil actif, aucun retrait) : rien.
UPDATE auth.users SET banned_until = '2999-12-31 00:00:00+00'::timestamptz WHERE id = pg_temp.u('31');
SET session_replication_role = replica;
INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le)
VALUES ('BAND-2345-7777', 'bandf-d@example.test', pg_temp.u('31'), now() + interval '14 days');
SET session_replication_role = origin;
SELECT pg_temp.vrai(
  public.invitation_compte_ancien_a_liberer('equipe', 'BAND-2345-7777', 'bandf-d@example.test') IS NULL,
  'D.4 un compte banni pour une autre raison que la suppression n''est jamais rendu');

DO $fin$ BEGIN RAISE NOTICE 'BANNISSEMENT-DATE-FINIE : scenario vert'; END $fin$;
ROLLBACK;
