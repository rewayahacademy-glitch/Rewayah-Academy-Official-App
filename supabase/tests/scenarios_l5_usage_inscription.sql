-- L5-01 (17/10/2026, audit d'entree E6) : l'inscription garde « Moi » ou
-- « Famille » et la reponse « Suivez-vous aussi des cours ? ». Migration
-- 20261017180000.
--   * inscrire_titulaire('moi', ...) : profil tuteur en attente, foyer marque
--     'moi', fiche d'eleve du titulaire creee meme sans p_suit_des_cours ;
--   * 'famille' sans cours : foyer 'famille', aucune fiche d'eleve ;
--     'famille' avec cours : fiche d'eleve du titulaire ;
--   * etat_dossier rend usage et suit_des_cours ;
--   * usage inconnu refuse en 22023 sans rien creer ; second appel refuse ;
--     anon n'execute rien ; empreinte F86 exacte.
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
 ('d1800000-0000-4000-8000-000000000101','l5-moi@test.invalid'),
 ('d1800000-0000-4000-8000-000000000102','l5-famille@test.invalid'),
 ('d1800000-0000-4000-8000-000000000103','l5-famille-cours@test.invalid'),
 ('d1800000-0000-4000-8000-000000000104','l5-inconnu@test.invalid');

-- 1. « Moi » : eleve adulte, son propre tuteur.
SELECT pg_temp.qui('d1800000-0000-4000-8000-000000000101', NULL);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('moi', 'Amina', 'L5');
SELECT set_config('test.etat', public.etat_dossier()::text, true);
RESET ROLE;
SELECT pg_temp.vrai((SELECT role = 'guardian' AND account_status = 'active' FROM public.profiles
                     WHERE id = 'd1800000-0000-4000-8000-000000000101'),
  'moi : profil tuteur actif (D4)');
SELECT pg_temp.vrai((SELECT h.usage_inscription = 'moi' FROM public.households h
                     JOIN public.profiles p ON p.household_id = h.id
                     WHERE p.id = 'd1800000-0000-4000-8000-000000000101'),
  'moi : foyer marque moi');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.student_profiles
                     WHERE profile_id = 'd1800000-0000-4000-8000-000000000101'
                       AND titulaire_profile_id = 'd1800000-0000-4000-8000-000000000101'),
  'moi : fiche d eleve du titulaire creee sans le drapeau');
SELECT pg_temp.vrai(current_setting('test.etat')::jsonb @> '{"usage":"moi","suit_des_cours":true}',
  'moi : etat_dossier rend usage et suit_des_cours');

-- 2. « Famille » sans cours.
SELECT pg_temp.qui('d1800000-0000-4000-8000-000000000102', NULL);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Karim', 'L5', 'male', 'Europe/Paris', false);
SELECT set_config('test.etat', public.etat_dossier()::text, true);
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.student_profiles
                     WHERE profile_id = 'd1800000-0000-4000-8000-000000000102'),
  'famille sans cours : aucune fiche d eleve');
SELECT pg_temp.vrai(current_setting('test.etat')::jsonb @> '{"usage":"famille","suit_des_cours":false}',
  'famille sans cours : etat_dossier');

-- 3. « Famille » avec cours.
SELECT pg_temp.qui('d1800000-0000-4000-8000-000000000103', NULL);
SET LOCAL ROLE authenticated;
SELECT public.inscrire_titulaire('famille', 'Sara', 'L5', 'female', 'Europe/Paris', true);
SELECT set_config('test.etat', public.etat_dossier()::text, true);
SELECT pg_temp.refus($$SELECT public.inscrire_titulaire('famille','Sara','L5')$$,
  'P0001', 'ce compte a deja un profil', 'second appel refuse');
RESET ROLE;
SELECT pg_temp.vrai(current_setting('test.etat')::jsonb @> '{"usage":"famille","suit_des_cours":true}',
  'famille avec cours : fiche d eleve et etat_dossier');

-- 4. Usage inconnu : rien n'est cree.
SELECT pg_temp.qui('d1800000-0000-4000-8000-000000000104', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.inscrire_titulaire('enseignant','X','L5')$$,
  '22023', 'usage inconnu : enseignant', 'usage inconnu refuse');
SELECT pg_temp.refus($$SELECT public.inscrire_titulaire(NULL,'X','L5')$$,
  '22023', 'usage inconnu : <NULL>', 'usage nul refuse');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'd1800000-0000-4000-8000-000000000104'),
  'usage refuse : aucun profil');

-- 5. Droits.
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean)', 'EXECUTE')
                AND has_function_privilege('authenticated', 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean)', 'EXECUTE')
                AND NOT has_function_privilege('anon', 'public.etat_dossier()', 'EXECUTE'),
  'anon n execute rien, authenticated oui');
SELECT pg_temp.vrai((SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
                       AND position('md5_functiondef=' || md5(pg_get_functiondef(p.oid))
                                    IN coalesce(obj_description(p.oid, 'pg_proc'), '')) > 0
                     FROM pg_proc p WHERE p.oid = 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean)'::regprocedure),
  'DEFINER, search_path vide, empreinte F86 exacte');

\ir _acl_retablir.sql

DO $fin$
BEGIN
  IF current_setting('test.r_n')::int <> 13 THEN
    RAISE EXCEPTION 'ROUGE : % controles executes, 13 attendus', current_setting('test.r_n');
  END IF;
  RAISE NOTICE 'L5-01 : % controles verts', current_setting('test.r_n');
END $fin$;

ROLLBACK;
