-- APRES-CONFIRMEE (BE-SALLE, 17/11/2026) : migration 20261129730000_apres_confirmee.sql.
--
-- Cas couverts : restreindre (cause manuelle), demander une verification de la piece ou du versement (causes piece et
-- paiement), lever la restriction avec controles revérifiés (piece approuvee, versement compatible), refus hors
-- etape et en pause, motif exige, cause invalide, droits. Chaque controle leve 'APRES ROUGE : ...' s'il echoue.
-- A rejouer sur une base NEUVE ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
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

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'APRES ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

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

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'APRES ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'APRES ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c0300000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c030cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.restr(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT restreinte::text || '/' || coalesce(restriction_cause, '-') FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.v(text), pg_temp.restr(text)
  TO authenticated, anon;



-- a1 direction (homme), b1 enseignant (non direction). 01 : confirmee, manuelle ; 02 : confirmee, verification de la
-- piece ; 03 : confirmee, verification du versement ; 04 : en examen (hors etape) ; 05 : confirmee, en pause.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'apc-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'b1', '01', '02', '03', '04', '05']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'APC-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male'),
       (pg_temp.p('b1'), 'APC-ENS-00b1', 'teacher', 'Essai', 'Enseignant', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'APC-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'active', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, v.etape, CASE WHEN v.etape = 'prequalification' THEN 'en_examen' END, 'en_cours', v.pause, 'lien_public'
FROM (VALUES ('01', 'confirmee', false), ('02', 'confirmee', false), ('03', 'confirmee', false),
             ('04', 'prequalification', false), ('05', 'confirmee', true)) AS v(s, etape, pause);
SET LOCAL session_replication_role = origin;

-- Une cause invalide : 22023.
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.restreindre_candidat(%L, ''inconnue'', ''x'', %s, ''cle-apc-a0'')', pg_temp.c('01'), pg_temp.v('01')),
  '22023', 'a0 : une cause invalide est refusee (22023)');

SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.restreindre_candidat(%L, ''manuelle'', '''', %s, ''cle-apc-a1a'')',
    pg_temp.c('01'), pg_temp.v('01'))) ->> 'erreur' = 'motif_requis'
  AND pg_temp.restr('01') = 'false/-',
  'a1 : restreindre sans motif refuse (motif_requis), rien n''est ecrit');
SELECT set_config('test.r01', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.restreindre_candidat(%L, ''manuelle'', ''Controle de routine'', %s, ''cle-apc-a1b'')',
  pg_temp.c('01'), pg_temp.v('01')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r01')::jsonb ? 'erreur' AND pg_temp.restr('01') = 'true/manuelle',
  'a2 : restreindre pose la restriction, cause manuelle');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.restreindre_candidat(%L, ''manuelle'', ''Encore'', %s, ''cle-apc-a1c'')',
    pg_temp.c('01'), pg_temp.v('01'))) ->> 'erreur' = 'transition_interdite',
  'a3 : pas de seconde restriction (transition_interdite)');
SELECT set_config('test.l01', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.lever_restriction_candidat(%L, ''Fin du controle'', %s, ''cle-apc-a1d'')',
  pg_temp.c('01'), pg_temp.v('01')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.l01')::jsonb ? 'erreur' AND pg_temp.restr('01') = 'false/-',
  'a4 : lever une restriction manuelle : aucun controle, la restriction est levee');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.lever_restriction_candidat(%L, ''Rien a lever'', %s, ''cle-apc-a1e'')',
    pg_temp.c('01'), pg_temp.v('01'))) ->> 'erreur' = 'transition_interdite',
  'a5 : lever sans restriction : transition_interdite');

SELECT set_config('test.r02', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.restreindre_candidat(%L, ''piece'', ''Piece a reverifier'', %s, ''cle-apc-a6a'')',
  pg_temp.c('02'), pg_temp.v('02')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r02')::jsonb ? 'erreur' AND pg_temp.restr('02') = 'true/piece',
  'a6 : demander la verification de la piece : restriction de cause piece');
SELECT set_config('test.l02', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.lever_restriction_candidat(%L, ''Piece revue'', %s, ''cle-apc-a6b'')',
  pg_temp.c('02'), pg_temp.v('02')))::text, true);
SELECT pg_temp.vrai(current_setting('test.l02')::jsonb ->> 'erreur' = 'controles_non_satisfaits'
  AND current_setting('test.l02')::jsonb -> 'controles' @> '[{"nom": "piece_validee"}]'::jsonb
  AND pg_temp.restr('02') = 'true/piece',
  'a7 : lever une restriction piece sans piece approuvee : controles_non_satisfaits (piece_validee), rien n''est ecrit');
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key, status)
VALUES (pg_temp.p('02'), 'id_card', 'male', 'apc-test/02.jpg', 'approved');
SELECT set_config('test.l02b', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.lever_restriction_candidat(%L, ''Piece revue'', %s, ''cle-apc-a6c'')',
  pg_temp.c('02'), pg_temp.v('02')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.l02b')::jsonb ? 'erreur' AND pg_temp.restr('02') = 'false/-',
  'a8 : piece approuvee : la restriction piece se leve');

SELECT set_config('test.r03', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.restreindre_candidat(%L, ''paiement'', ''Versement a reverifier'', %s, ''cle-apc-a9a'')',
  pg_temp.c('03'), pg_temp.v('03')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r03')::jsonb ? 'erreur' AND pg_temp.restr('03') = 'true/paiement',
  'a9 : demander la verification du versement : restriction de cause paiement');
SELECT set_config('test.l03', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.lever_restriction_candidat(%L, ''Versement revu'', %s, ''cle-apc-a9b'')',
  pg_temp.c('03'), pg_temp.v('03')))::text, true);
SELECT pg_temp.vrai(current_setting('test.l03')::jsonb ->> 'erreur' = 'controles_non_satisfaits'
  AND current_setting('test.l03')::jsonb -> 'controles' @> '[{"nom": "paiement_compatible"}]'::jsonb
  AND pg_temp.restr('03') = 'true/paiement',
  'a10 : lever une restriction paiement sans versement compatible : controles_non_satisfaits (paiement_compatible)');
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source)
VALUES (pg_temp.c('03'), 'salle-examen-2', '{"paysVersement": "SA", "compteBancaire": true}', 'candidat');
SELECT set_config('test.l03b', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.lever_restriction_candidat(%L, ''Versement revu'', %s, ''cle-apc-a9c'')',
  pg_temp.c('03'), pg_temp.v('03')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.l03b')::jsonb ? 'erreur' AND pg_temp.restr('03') = 'false/-',
  'a11 : versement compatible : la restriction paiement se leve');

SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.restreindre_candidat(%L, ''manuelle'', ''Hors etape'', %s, ''cle-apc-a12a'')',
    pg_temp.c('04'), pg_temp.v('04'))) ->> 'erreur' = 'transition_interdite'
  AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.restreindre_candidat(%L, ''manuelle'', ''En pause'', %s, ''cle-apc-a12b'')',
    pg_temp.c('05'), pg_temp.v('05'))) ->> 'erreur' = 'transition_interdite',
  'a12 : avant l''accueil et en pause : transition_interdite');

SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.restreindre_candidat(uuid,text,text,integer,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.lever_restriction_candidat(uuid,text,integer,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.restreindre_candidat(uuid,text,text,integer,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.lever_restriction_candidat(uuid,text,integer,text)', 'EXECUTE'),
  'a13 : les deux portes sont fermees a anon, ouvertes aux comptes connectes');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', pg_catalog.format(
  'SELECT public.restreindre_candidat(%L, ''manuelle'', ''x'', 1, ''cle-apc-a14'')', pg_temp.c('01')),
  '42501', 'a14 : un compte qui n''est pas la direction est refuse (42501)');
SELECT set_config('test.cap', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.capacites_candidatures()$$)::text, true);
SELECT pg_temp.vrai((current_setting('test.cap')::jsonb -> 'gestes' ->> 'restreindre')::boolean IS TRUE
  AND (current_setting('test.cap')::jsonb -> 'gestes' ->> 'leverRestriction')::boolean IS TRUE
  AND (current_setting('test.cap')::jsonb -> 'gestes' ->> 'demanderVerification')::boolean IS TRUE,
  'a15 : la direction a les capacites restreindre, leverRestriction et demanderVerification');
ROLLBACK;
