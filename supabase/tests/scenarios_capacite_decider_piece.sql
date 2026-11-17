-- CAPACITE-DECIDER-PIECE (BE-SALLE, 17/11/2026, migration 20261129720000_capacite_decider_piece.sql).
-- Cas : la cle gestes.deciderPiece de capacites_candidatures() est vraie pour la direction active de genre connu,
-- fausse pour un porteur de mission (meme avec valider_piece dans sa mission), un controleur sans mission et un tuteur ;
-- fausse pour une direction sans genre. Fixtures reprises de scenarios_be2a_mission.sql.
-- (suite de l'en-tete d'origine, sans objet ici) : Une mission donne a une personne qui a deja un compte
-- quelques gestes sur les candidatures, dans un perimetre (cote, langues, etapes, dossiers), pour une duree, retirable,
-- sans toucher a son compte. Scenarios du cahier CAHIER-BE-2A-MISSION.md §3, un refus par cas, avec son code :
--  1 geste non coche ; 2 dossier de l'autre cote ; 3 mission expiree ; 4 mission retiree (liste vide, compte inchange) ;
--  5 mission archivee ; 6 hors langues / hors dossiers confies ; 7 piece d'identite ; 8 contact sans voir_contact ;
--  9 anon et authenticated sans mission ; 10 geste permis (journal avec mission_id, idempotence) ;
-- 11 non-regression de la direction (les scenarios de candidature deja au CI, rejoues a part).
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'DECIDER-PIECE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

-- Un appel sous le role authenticated, au nom d'un compte.
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Un appel qui doit etre refuse avec ce code.
CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_db_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'DECIDER-PIECE ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'DECIDER-PIECE ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a130000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a13cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2a0000-0000-4000-8000-0000000000' || CASE p_n WHEN 'a1' THEN '01' WHEN 'a2' THEN '02' WHEN 'h1' THEN '11'
    WHEN 'h2' THEN '12' WHEN 'h3' THEN '13' WHEN 'h4' THEN '14' END)::uuid $$;
CREATE FUNCTION pg_temp.d(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2acccc-0000-4000-8000-0000000000' || CASE p_n WHEN 'M1' THEN '01' WHEN 'M2' THEN '02' WHEN 'M3' THEN '03'
    WHEN 'M4' THEN '04' WHEN 'F1' THEN '05' END)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.d(text) TO authenticated, anon;

-- Un appel qui rend une erreur jsonb ou une valeur ; le role authenticated, aal2 (la double verification).
-- a1 direction homme, a2 direction femme ; h1 porteur homme (controller), h2 porteuse (femme), h3 sans mission
-- (homme), h4 tuteur ; M1..M4 dossiers d'hommes, F1 dossier de femme.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(s), 'be2a-' || s || '@test.invalid'
  FROM unnest(ARRAY['a1', 'a2', 'h1', 'h2', 'h3', 'h4']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('5b2affff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a1'), 'B2-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('a2'), 'B2-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('h1'), 'B2-CTL-0001', 'controller', NULL, 'Porteur', 'Un', 'active', 'male'),
 (pg_temp.u('h2'), 'B2-CTL-0002', 'controller', NULL, 'Porteuse', 'Deux', 'active', 'female'),
 (pg_temp.u('h3'), 'B2-CTL-0003', 'controller', NULL, 'Sans', 'Mission', 'active', 'male'),
 (pg_temp.u('h4'), 'B2-TUT-0001', 'guardian', '5b2affff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai', 'active', 'female');
INSERT INTO auth.users (id, email) SELECT ('5b2a0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'be2a-c' || i || '@test.invalid'
  FROM generate_series(1, 5) i;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT ('5b2a0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'B2-ENS-000' || i, 'teacher', 'Candidat', 'N' || i,
       'pending_kyc', CASE WHEN i = 5 THEN 'female'::public.gender ELSE 'male'::public.gender END
  FROM generate_series(1, 5) i;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT ('5b2a0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'SA', ARRAY[]::text[], 'pending' FROM generate_series(1, 5) i
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, profile_id, type_code, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.d(n), ('5b2a0000-0000-4000-8000-0000000000' || (20 + (CASE n WHEN 'F1' THEN 5 ELSE right(n, 1)::int END)))::uuid,
       'enseignant', g::public.gender, 'Fixture BE2A ' || n, e,
       CASE e WHEN 'verifications' THEN 'entretien_a_planifier' ELSE 'en_examen' END, 'en_cours', false, 'lien_public'
  FROM (VALUES ('M1', 'male', 'prequalification'), ('M2', 'male', 'prequalification'),
               ('M3', 'male', 'verifications'), ('M4', 'male', 'prequalification'),
               ('F1', 'female', 'prequalification')) v(n, g, e);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
SELECT pg_temp.d(n), 'salle-examen-2', pg_catalog.jsonb_build_object('languesExplication', l, 'langueMaternelle', 'ar'),
       'candidat', false, pg_catalog.clock_timestamp()
  FROM (VALUES ('M1', '["francais"]'::jsonb), ('M2', '["poular"]'::jsonb), ('M3', '["francais"]'::jsonb),
               ('M4', '["francais"]'::jsonb), ('F1', '["francais"]'::jsonb)) v(n, l);
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
SELECT pg_temp.d(n), lower(n) || '@exemple.invalid', '+33600000000' FROM unnest(ARRAY['M1', 'M2', 'M3', 'M4', 'F1']) n;
-- Une direction de l'autre cote ne sert qu'aux scenarios de refus du cote de la direction : a2 est femme.

-- Les mots : une mission « Anglais » avec cinq gestes (cahier §0) ; une seconde sans geste de contact.
SELECT pg_temp.garde('m1', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Candidatures en anglais',
  ARRAY['lire', 'voir_contact', 'definir_responsable', 'demander_complement', 'valider_piece'], '11111111-0000-4000-8000-000000000001'::uuid))$$));
SELECT pg_temp.garde('m2', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Lecture seule', ARRAY['lire'], '11111111-0000-4000-8000-000000000002'::uuid))$$));
CREATE FUNCTION pg_temp.mid(p text) RETURNS uuid LANGUAGE sql AS $$ SELECT (pg_temp.lu(p) #>> '{}')::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.mid(text) TO authenticated, anon;

CREATE FUNCTION pg_temp.compte(p_n text) RETURNS text LANGUAGE sql AS $$
  SELECT role::text || '/' || account_status::text || '/' || coalesce(gender::text, '-') FROM public.profiles WHERE id = pg_temp.u(p_n) $$;
SELECT pg_temp.garde('compte_h1', to_jsonb(pg_temp.compte('h1')));

-- Un geste de la direction au nom d'un porteur : definir_responsable (version lue ici).
CREATE FUNCTION pg_temp.geste(p_qui text, p_dossier text, p_cle text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v_version integer;
BEGIN
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = pg_temp.d(p_dossier);
  RETURN pg_temp.en(pg_temp.u(p_qui), (SELECT role::text FROM public.profiles WHERE id = pg_temp.u(p_qui)),
    pg_catalog.format('SELECT public.definir_responsable_candidat(%L::uuid, %L::uuid, %s, %L)', pg_temp.d(p_dossier),
                      pg_temp.u('a1'), v_version, p_cle));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.geste(text, text, text) TO authenticated, anon;
CREATE FUNCTION pg_temp.etat_dossier(p_n text) RETURNS text LANGUAGE sql AS $$
  SELECT md5(to_jsonb(c)::text) FROM public.candidatures c WHERE c.id = pg_temp.d(p_n) $$;
CREATE FUNCTION pg_temp.accorder(p_h text, p_m text, p_perimetre jsonb, p_debut text, p_fin text, p_cle text) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  RETURN pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
    'SELECT pg_catalog.to_jsonb(public.accorder_mission(%L::uuid, %L::uuid, %L::jsonb, %s, %s, %L::uuid))',
    pg_temp.u(p_h), pg_temp.mid(p_m), p_perimetre::text, coalesce(pg_catalog.quote_literal(p_debut) || '::timestamptz', 'NULL'),
    coalesce(pg_catalog.quote_literal(p_fin) || '::timestamptz', 'NULL'), p_cle));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.accorder(text, text, jsonb, text, text, text) TO authenticated, anon;

SELECT pg_temp.garde('att1', pg_temp.accorder('h1', 'm1', '{"langues": ["francais"]}'::jsonb, NULL, NULL,
  '22222222-0000-4000-8000-0000000000a1'));
SELECT pg_temp.vrai(NOT pg_temp.lu('att1') ? 'erreur', 'c0 : h1 porte une mission qui contient valider_piece (fixture)');

SELECT pg_temp.garde('cap_a1', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_h1', pg_temp.en(pg_temp.u('h1'), 'controller', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_h3', pg_temp.en(pg_temp.u('h3'), 'controller', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_h4', pg_temp.en(pg_temp.u('h4'), 'guardian', $$SELECT public.capacites_candidatures()$$));

SELECT pg_temp.vrai((pg_temp.lu('cap_a1') -> 'gestes' ->> 'deciderPiece')::boolean IS TRUE,
  'c1 : la direction active de genre connu a deciderPiece');
SELECT pg_temp.vrai((pg_temp.lu('cap_h1') -> 'gestes' ->> 'validerPiece')::boolean IS TRUE
  AND coalesce((pg_temp.lu('cap_h1') -> 'gestes' ->> 'deciderPiece')::boolean, false) IS FALSE,
  'c2 : un porteur de mission avec valider_piece a validerPiece mais PAS deciderPiece');
SELECT pg_temp.vrai(coalesce((pg_temp.lu('cap_h3') -> 'gestes' ->> 'deciderPiece')::boolean, false) IS FALSE
  AND coalesce((pg_temp.lu('cap_h4') -> 'gestes' ->> 'deciderPiece')::boolean, false) IS FALSE,
  'c3 : un controleur sans mission et un tuteur n''ont pas deciderPiece');

-- Une direction sans genre connu : decider_dossier lirait read_kyc_documents() et echouerait ; pas de capacite.
SET LOCAL session_replication_role = replica;
UPDATE public.profiles SET gender = NULL WHERE id = pg_temp.u('a2');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.garde('cap_a2', pg_temp.en(pg_temp.u('a2'), 'admin', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.vrai(coalesce((pg_temp.lu('cap_a2') -> 'gestes' ->> 'deciderPiece')::boolean, false) IS FALSE,
  'c4 : une direction sans genre connu n''a pas deciderPiece');

SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.capacites_candidatures()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.capacites_candidatures()', 'EXECUTE'),
  'c5 : capacites_candidatures reste fermee a anon, ouverte aux comptes connectes');
ROLLBACK;
