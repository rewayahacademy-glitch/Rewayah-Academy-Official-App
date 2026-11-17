-- COMPLEMENT-SALLE-EXAMEN (BE-SALLE, 16/11/2026) : migration 20261129710000_complement_salle_examen.sql.
--
-- Cas couverts : en a_completer SANS complement (questionnaire non envoye), ni annuler ni modifier ; une demande en
-- examen puis sa MODIFICATION (l'etat reste a_completer, les codes changent) puis son ANNULATION (retour en_examen,
-- complement clos, motif exige, pas de seconde annulation) ; en paiement_non_disponible, une demande sur le seul code
-- `versement` (autre code refuse), etat d'arrivee a_completer ; en_examen sans complement : rien a annuler ; droits
-- (anon sans droit, non-direction refusee). Chaque controle leve 'COMPLEMENT ROUGE : ...' s'il echoue.
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
    RAISE EXCEPTION 'COMPLEMENT ROUGE : %', p_label;
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
    RAISE EXCEPTION 'COMPLEMENT ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'COMPLEMENT ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c0200000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c020cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT etat FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.codes(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT private.candidature_complement_en_cours(c)::text FROM public.candidatures c WHERE c.id = pg_temp.c(p_n) $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.v(text), pg_temp.etat(text), pg_temp.codes(text)
  TO authenticated, anon;


-- a1 direction (homme), b1 enseignant (non direction). 01 en examen ; 02 a_completer sans complement ;
-- 03 paiement_non_disponible ; 04 en examen, sans complement.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'cse-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'b1', '01', '02', '03', '04']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'CSE-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male'),
       (pg_temp.p('b1'), 'CSE-ENS-00b1', 'teacher', 'Essai', 'Enseignant', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'CSE-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, 'prequalification', v.etat, 'en_cours', 'lien_public'
FROM (VALUES ('01', 'en_examen'), ('02', 'a_completer'), ('03', 'paiement_non_disponible'), ('04', 'en_examen')) AS v(s, etat);
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.annuler_complement_candidat(%L, ''Annulation'', %s, ''cle-cse-a1a'')',
    pg_temp.c('02'), pg_temp.v('02'))) ->> 'erreur' = 'transition_interdite'
  AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.demander_complement_candidat(%L, ARRAY[''langues''], ''Modifier'', %s, ''cle-cse-a1b'')',
    pg_temp.c('02'), pg_temp.v('02'))) ->> 'erreur' = 'transition_interdite'
  AND pg_temp.etat('02') = 'a_completer',
  'a1 : a_completer sans complement : annuler et modifier refuses (transition_interdite), etat inchange');

SELECT set_config('test.r01', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''langues''], ''Il manque les langues'', %s, ''cle-cse-a2a'')',
  pg_temp.c('01'), pg_temp.v('01')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r01')::jsonb ? 'erreur' AND pg_temp.etat('01') = 'a_completer'
  AND pg_temp.codes('01') = '["langues"]', 'a2 : la demande en examen est acceptee (a_completer, code langues)');
SELECT set_config('test.r01b', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''cadre_religieux''], ''Plutot le cadre'', %s, ''cle-cse-a2b'')',
  pg_temp.c('01'), pg_temp.v('01')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r01b')::jsonb ? 'erreur' AND pg_temp.etat('01') = 'a_completer'
  AND pg_temp.codes('01') = '["cadre_religieux"]',
  'a3 : la MODIFICATION remplace la demande, l''etat reste a_completer');

SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.annuler_complement_candidat(%L, '''', %s, ''cle-cse-a4a'')',
    pg_temp.c('01'), pg_temp.v('01'))) ->> 'erreur' = 'motif_requis'
  AND pg_temp.etat('01') = 'a_completer',
  'a4 : annuler sans motif refuse (motif_requis), rien n''est ecrit');
SELECT set_config('test.r01c', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.annuler_complement_candidat(%L, ''Demande retiree'', %s, ''cle-cse-a4b'')',
  pg_temp.c('01'), pg_temp.v('01')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r01c')::jsonb ? 'erreur' AND pg_temp.etat('01') = 'en_examen'
  AND pg_temp.codes('01') = '[]',
  'a5 : l''ANNULATION ramene le dossier en en_examen et clot la demande');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.annuler_complement_candidat(%L, ''Encore'', %s, ''cle-cse-a5'')',
    pg_temp.c('01'), pg_temp.v('01'))) ->> 'erreur' = 'transition_interdite',
  'a6 : pas de seconde annulation (transition_interdite)');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.annuler_complement_candidat(%L, ''Rien a annuler'', %s, ''cle-cse-a6'')',
    pg_temp.c('04'), pg_temp.v('04'))) ->> 'erreur' = 'transition_interdite',
  'a7 : en examen sans complement : rien a annuler');

SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.demander_complement_candidat(%L, ARRAY[''langues''], ''Mauvais code'', %s, ''cle-cse-a8a'')',
    pg_temp.c('03'), pg_temp.v('03'))) ->> 'erreur' = 'elements_invalides'
  AND pg_temp.etat('03') = 'paiement_non_disponible',
  'a8 : paiement non disponible : un autre code que versement est refuse (elements_invalides)');
SELECT set_config('test.r03', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''versement''], ''Precisez votre moyen de versement'', %s, ''cle-cse-a8b'')',
  pg_temp.c('03'), pg_temp.v('03')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r03')::jsonb ? 'erreur' AND pg_temp.etat('03') = 'a_completer'
  AND pg_temp.codes('03') = '["versement"]',
  'a9 : paiement non disponible : la demande sur le versement est acceptee, la personne repasse a_completer');

SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.annuler_complement_candidat(uuid,text,integer,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.annuler_complement_candidat(uuid,text,integer,text)', 'EXECUTE'),
  'a10 : annuler_complement_candidat fermee a anon, ouverte aux comptes connectes');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', pg_catalog.format(
  'SELECT public.annuler_complement_candidat(%L, ''x'', 1, ''cle-cse-a11'')', pg_temp.c('01')),
  '42501', 'a11 : un compte qui n''est pas la direction est refuse (42501)');
ROLLBACK;
