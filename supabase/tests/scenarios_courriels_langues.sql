-- COURRIELS-2 (23/10/2026) : la langue de chaque e-mail. Migration 20261023140000.
--   1. sans choix, un e-mail part en francais ;
--   2. la personne choisit l'arabe : ses e-mails suivants sont en arabe, et le
--      travailleur recoit la langue, le sens d'ecriture et « modeles ecrits » ;
--   3. sans profil, la donnee `langue` de l'e-mail compte ; une langue inconnue
--      retombe sur le francais ;
--   4. une langue inconnue ou un appel anonyme sont refuses ; la liste est
--      publique ; la direction voit la langue dans la file.
\o /dev/null
BEGIN;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal2', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.refuse(p_sql text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN EXECUTE p_sql; EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'OK % (refuse : %)', p_label, SQLERRM; RETURN; END;
  RAISE EXCEPTION 'ROUGE : % (accepte)', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.refuse(text, text) TO authenticated, anon;

INSERT INTO auth.users(id, email) VALUES
  ('c0e20000-0000-4000-8000-0000000000a1', 'direction-l@test.invalid'),
  ('c0e20000-0000-4000-8000-0000000000b1', 'tuteur-l@test.invalid');
INSERT INTO public.households(id, timezone) VALUES ('c0e20000-0000-4000-8000-0000000000f1', 'Europe/Paris');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('c0e20000-0000-4000-8000-0000000000a1', 'CRL2-ADM', 'admin', NULL, 'Direction', 'L', 'active', 'female'),
  ('c0e20000-0000-4000-8000-0000000000b1', 'CRL2-TUT', 'guardian', 'c0e20000-0000-4000-8000-0000000000f1', 'Moussa', 'L', 'active', 'male');

-- 1
SELECT public.courriel_enfiler('classes', 'enseignant_affecte', 'tuteur-l@test.invalid',
  'c0e20000-0000-4000-8000-0000000000b1', '{}', 'l1');
SELECT pg_temp.vrai((SELECT langue FROM public.courriels_sortants WHERE cle_idempotence = 'l1') = 'fr', '1 sans choix : francais');

-- 2
SELECT pg_temp.qui('c0e20000-0000-4000-8000-0000000000b1', 'guardian');
SET LOCAL ROLE authenticated;
SELECT public.ma_langue_communication_regler(' AR ');
SELECT pg_temp.vrai(public.ma_langue_communication() = 'ar', '2 la personne choisit l arabe');
SELECT pg_temp.refuse($$SELECT public.ma_langue_communication_regler('xx')$$, '4 langue inconnue refusee');
SELECT pg_temp.refuse($$SELECT * FROM public.langues_communication$$, '4 table illisible directement');
RESET ROLE;
SELECT public.courriel_enfiler('classes', 'enseignant_affecte', 'tuteur-l@test.invalid',
  'c0e20000-0000-4000-8000-0000000000b1', '{}', 'l2');
SET LOCAL ROLE service_role;
SELECT set_config('test.lot', public.courriels_reserver(50)::text, true);
RESET ROLE;
SELECT pg_temp.vrai((SELECT bool_and(CASE e->>'id'
                       WHEN (SELECT id::text FROM public.courriels_sortants WHERE cle_idempotence = 'l2')
                       THEN e->>'langue' = 'ar' AND (e->>'droite_a_gauche')::boolean AND (e->>'langue_ecrite')::boolean
                       ELSE true END)
                       FROM jsonb_array_elements(current_setting('test.lot')::jsonb) e)
                    AND jsonb_array_length(current_setting('test.lot')::jsonb) = 2,
                    '2 le travailleur recoit la langue et le sens d ecriture');

-- 3
SELECT public.courriel_enfiler('recrutement', 'lien_inscription', 'candidat@test.invalid', NULL, '{"langue": "PT"}', 'l3');
SELECT public.courriel_enfiler('recrutement', 'lien_inscription', 'autre@test.invalid', NULL, '{"langue": "zz"}', 'l4');
SELECT pg_temp.vrai((SELECT langue FROM public.courriels_sortants WHERE cle_idempotence = 'l3') = 'pt', '3 sans profil : la donnee langue compte');
SELECT pg_temp.vrai((SELECT langue FROM public.courriels_sortants WHERE cle_idempotence = 'l4') = 'fr', '3 langue inconnue : francais');

-- 4
SET LOCAL ROLE anon;
SELECT pg_temp.vrai(jsonb_array_length(public.langues_communication_lister()) = 6, '4 la liste des langues est publique');
SELECT pg_temp.refuse($$SELECT public.ma_langue_communication_regler('fr')$$, '4 un anonyme ne regle rien');
RESET ROLE;
SELECT pg_temp.qui('c0e20000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT bool_and(r ? 'langue') FROM jsonb_array_elements(public.admin_courriels_lister(NULL, 50)) r),
                    '4 la direction voit la langue de chaque e-mail');
RESET ROLE;
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'public.courriel_langue_a_l_entree()', 'EXECUTE')
                    AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'langues_communication'), '4 droits bornes, RLS active');
\o
SELECT 'COURRIELS-2 : tous les controles sont verts' AS resultat;
ROLLBACK;
