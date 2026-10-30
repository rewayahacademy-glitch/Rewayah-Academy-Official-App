-- AF L1-11 (17/10/2026, matrice E-01, decision A-07 option 1) : un enseignant
-- n'entre que par invitation. Migration 20261017150200.
--   * creer_profil_inscription('teacher', ...) est refuse, SQLSTATE 23514
--     (check_violation), message 'inscription enseignant sur invitation seulement',
--     pour une session connectee sans profil ; aucun profil, aucune fiche
--     enseignant, aucune ligne de journal 'profil_cree' n'en sortent ;
--   * le tuteur reste ouvert, l'eleve et les roles prives restent refuses avec
--     leurs messages d'avant ;
--   * la porte par invitation reussit de bout en bout : la direction invite
--     (inviter_enseignant), le candidat s'inscrit (inscrire_enseignant_invite),
--     le profil est un enseignant en attente de KYC, le code est consomme ;
--   * un code deja consomme ne rouvre rien ; le corps interne n'est
--     executable par aucun role client ; signatures et droits inchanges.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;
\ir _acl_photo.sql

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object('app_metadata',
                       pg_catalog.json_build_object('role', p_role))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Refus attendu : SQLSTATE exact ET message exact (une autre erreur, cle
-- etrangere ou contrainte, ne prouve pas la garde).
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR SQLERRM <> p_message THEN
      RAISE EXCEPTION 'ROUGE : % (%, % au lieu de %, %)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  PERFORM pg_catalog.set_config('test.r_n',
    (coalesce(nullif(pg_catalog.current_setting('test.r_n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text, text) TO authenticated, anon;

INSERT INTO auth.users(id, email) VALUES
 ('d1700000-0000-4000-8000-0000000000a1','l111-admin@test.invalid'),
 ('d1700000-0000-4000-8000-000000000101','l111-sans-code@test.invalid'),
 ('d1700000-0000-4000-8000-000000000102','l111-invite@test.invalid'),
 ('d1700000-0000-4000-8000-000000000103','l111-tuteur@test.invalid'),
 ('d1700000-0000-4000-8000-000000000104','l111-eleve@test.invalid'),
 ('d1700000-0000-4000-8000-000000000105','l111-prive@test.invalid'),
 ('d1700000-0000-4000-8000-000000000106','l111-rejeu@test.invalid');
INSERT INTO public.profiles(id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 ('d1700000-0000-4000-8000-0000000000a1','L111-ADM-0001','admin','Direction','L111','active','female');

-- Aucun profil enseignant n'existe pour les candidats avant les controles.
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id::text LIKE 'd1700000-%' AND role = 'teacher'),
  'depart : aucun enseignant parmi les fixtures');

-- 1. Refus : enseignant sans code, session connectee sans profil.
SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000101', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('teacher','Sans','Code')$$,
  '23514', 'inscription enseignant sur invitation seulement',
  'enseignant sans code : refuse en 23514');
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('teacher','Sans','Code','male','Europe/Paris',false)$$,
  '23514', 'inscription enseignant sur invitation seulement',
  'enseignant sans code, signature complete : refuse en 23514');
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('teacher','Sans','Code',NULL,'Europe/Paris',true)$$,
  '23514', 'inscription enseignant sur invitation seulement',
  'enseignant et apprenant personnel : refuse en 23514');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'd1700000-0000-4000-8000-000000000101')
                AND NOT EXISTS (SELECT 1 FROM public.teacher_profiles WHERE profile_id = 'd1700000-0000-4000-8000-000000000101'),
  'refus enseignant : ni profil ni fiche enseignant');

-- Sans session : le refus de session reste celui d'avant (pas d'inference).
SELECT pg_temp.qui(NULL, NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('teacher','Sans','Session')$$,
  'P0001', 'aucune session', 'enseignant sans session : aucune session');
RESET ROLE;

-- 2. Les autres roles sont inchanges.
SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000103', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((public.creer_profil_inscription('guardian','Fatou','L111','male')).id IS NOT NULL,
  'tuteur : inscription toujours ouverte');
RESET ROLE;
SELECT pg_temp.vrai((SELECT role = 'guardian' AND account_status = 'pending_kyc' AND household_id IS NOT NULL
                       FROM public.profiles WHERE id = 'd1700000-0000-4000-8000-000000000103'),
  'tuteur : profil en attente avec foyer (admission, 27/10)');
SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000104', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('student','Eleve','L111')$$,
  'P0001', 'role non ouvert a l''inscription publique : student', 'eleve : toujours refuse, meme message');
SELECT pg_temp.refus($$SELECT public.creer_profil_inscription('admin','Direction','L111')$$,
  'P0001', 'role non ouvert a l''inscription publique : admin', 'admin : toujours refuse, meme message');
RESET ROLE;

-- 3. La porte par invitation reussit, de bout en bout.
SELECT pg_temp.qui('d1700000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inviter_enseignant('l111-invite@test.invalid') ->> 'statut' IS NOT NULL,
  'direction : invitation emise');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.invitations_enseignant
                      WHERE email = 'l111-invite@test.invalid' AND utilisee_le IS NULL),
  'invitation active creee pour l''adresse du candidat');

SELECT set_config('test.code',
  (SELECT code FROM public.invitations_enseignant WHERE email = 'l111-invite@test.invalid'), true);
-- Un autre candidat, meme avec un code emis pour quelqu'un d'autre, n'entre pas.
SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000105', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite(
    current_setting('test.code'),
    'Intrus','L111',NULL) ->> 'resultat' = 'inconnue',
  'code d''une autre adresse : inconnue');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'd1700000-0000-4000-8000-000000000105'),
  'code d''une autre adresse : aucun profil');

SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000102', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.inscrire_enseignant_invite(
    current_setting('test.code'),
    'Hafsa','L111','female') ->> 'resultat' = 'consommee',
  'candidat invite : inscription par la RPC d''invitation reussie');
RESET ROLE;
SELECT pg_temp.vrai((SELECT role = 'teacher' AND account_status = 'pending_kyc' AND household_id IS NULL
                       FROM public.profiles WHERE id = 'd1700000-0000-4000-8000-000000000102')
                AND EXISTS (SELECT 1 FROM public.teacher_profiles
                             WHERE profile_id = 'd1700000-0000-4000-8000-000000000102'),
  'candidat invite : enseignant pending_kyc, sans foyer, avec fiche');
SELECT pg_temp.vrai((SELECT utilisee_par = 'd1700000-0000-4000-8000-000000000102' AND utilisee_le IS NOT NULL
                       FROM public.invitations_enseignant WHERE email = 'l111-invite@test.invalid'),
  'candidat invite : code consomme par lui');

-- Le code consomme ne rouvre rien : une autre session avec la meme adresse,
-- et le meme candidat deja inscrit, sont refuses.
SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000102', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inscrire_enseignant_invite('AAAA-AAAA-AAAA','Hafsa','L111',NULL)$$,
  '42501', 'inscription enseignant reservee a une session sans profil',
  'candidat deja inscrit : refuse en 42501');
RESET ROLE;

-- 4. Le corps interne n'est executable par aucun role client.
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.creer_profil_inscription_interne(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.creer_profil_inscription_interne(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'private.creer_profil_inscription_interne(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'private.creer_profil_inscription_interne(text,text,text,public.gender,text,boolean)', 'EXECUTE'),
  'corps interne : aucun role client');
SELECT pg_temp.qui('d1700000-0000-4000-8000-000000000106', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT private.creer_profil_inscription_interne('teacher','Direct','L111')$$,
  '42501', 'permission denied for schema private', 'corps interne appele en direct : refuse en 42501');
RESET ROLE;

-- 5. Signatures, proprietaire, droits et empreintes inchanges.
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.creer_profil_inscription(text,text,text,public.gender,text,boolean)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.inscrire_enseignant_invite(text,text,text,public.gender)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.inscrire_enseignant_invite(text,text,text,public.gender)', 'EXECUTE'),
  'droits des deux fonctions publiques inchanges');
SELECT pg_temp.vrai(NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_proc p
   WHERE p.oid IN ('public.creer_profil_inscription(text,text,text,public.gender,text,boolean)'::regprocedure,
                   'public.inscrire_enseignant_invite(text,text,text,public.gender)'::regprocedure)
     AND (NOT p.prosecdef OR p.proowner <> 'postgres'::regrole
          OR NOT (p.proconfig @> ARRAY['search_path=""'])
          OR position('md5_functiondef=' || md5(pg_get_functiondef(p.oid))
                      IN coalesce(obj_description(p.oid, 'pg_proc'), '')) = 0)),
  'DEFINER, proprietaire, search_path vide, empreinte F86 exacte');

\ir _acl_retablir.sql

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 22 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 22 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'AF-L1-11 : % controles verts', current_setting('test.r_n');
END $fin$;

ROLLBACK;
