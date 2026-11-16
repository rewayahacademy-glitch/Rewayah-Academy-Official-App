-- COMPLEMENT-EN-COURS (pilote, 16/11/2026) : migration 20261129450000_complement_en_cours.sql.
--
-- Cas couverts : la cle complementEnCours de chaque ligne (liste, dossier) est vraie quand une demande de
-- complement est ouverte, fausse sinon ; elle suit la demande (ouverte, puis close par complement_clos en salle de
-- verification) ; chaque ligne porte un booleen. Chaque controle leve 'COMPLEMENT ROUGE : ...' s'il echoue.
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
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c0100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c010cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.cle_liste(p_n text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT (l ->> 'complementEnCours')::boolean
    FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin',
      $q$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$q$) -> 'lignes') AS t(l)
   WHERE right(l ->> 'id', 2) = p_n;
$$;
CREATE FUNCTION pg_temp.cle_dossier(p_n text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT (pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.c(p_n))) ->> 'complementEnCours')::boolean;
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.v(text), pg_temp.cle_liste(text), pg_temp.cle_dossier(text)
  TO authenticated, anon;

-- a1 direction (homme). 01 en examen (salle d'examen), sans complement ; 02 en examen, complement demande ;
-- 03 en salle de verification, complement demande puis clos ; 04 en salle de verification, sans demande.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'cmp-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'CMP-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'CMP-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, v.etape, v.etat, 'en_cours', 'lien_public'
FROM (VALUES ('01', 'prequalification', 'en_examen'), ('02', 'prequalification', 'en_examen'),
             ('03', 'verifications', 'entretien_a_planifier'), ('04', 'verifications', 'entretien_a_planifier')) AS v(s, etape, etat);
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(
  pg_temp.cle_liste('01') = false AND pg_temp.cle_liste('02') = false AND pg_temp.cle_liste('03') = false
  AND pg_temp.cle_dossier('01') = false,
  'a1 : sans demande, la cle complementEnCours est fausse (liste et dossier)');
SELECT set_config('test.r02', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''langues''], ''Il manque les langues'', %s, ''cle-cmp-02'')',
  pg_temp.c('02'), pg_temp.v('02')))::text, true);
SELECT set_config('test.r03', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''piece_identite''], ''Piece illisible'', %s, ''cle-cmp-03'')',
  pg_temp.c('03'), pg_temp.v('03')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r02')::jsonb ? 'erreur' AND NOT current_setting('test.r03')::jsonb ? 'erreur',
  'a2 : les deux demandes de complement sont acceptees (fixtures)');
SELECT pg_temp.vrai(
  pg_temp.cle_liste('02') = true AND pg_temp.cle_liste('03') = true AND pg_temp.cle_liste('01') = false
  AND pg_temp.cle_liste('04') = false
  AND pg_temp.cle_dossier('02') = true AND pg_temp.cle_dossier('03') = true AND pg_temp.cle_dossier('01') = false,
  'a3 : une demande ouverte rend la cle vraie, dans la liste et dans le dossier ; les autres candidatures restent fausses');
SELECT set_config('test.r03b', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''complement_clos''], ''Complement recu'', %s, ''cle-cmp-03b'')',
  pg_temp.c('03'), pg_temp.v('03')))::text, true);
SELECT pg_temp.vrai(NOT current_setting('test.r03b')::jsonb ? 'erreur'
  AND pg_temp.cle_liste('03') = false AND pg_temp.cle_dossier('03') = false AND pg_temp.cle_liste('02') = true,
  'a4 : apres complement_clos, la cle redevient fausse ; la demande de 02 reste ouverte');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin',
     $q$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$q$) -> 'lignes') AS t(l)) = 4
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin',
     $q$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$q$) -> 'lignes') AS t(l)
     WHERE jsonb_typeof(l -> 'complementEnCours') <> 'boolean'),
  'a5 : chaque ligne de la liste porte la cle, toujours un booleen');
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.cand_ligne_json(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.cand_ligne_json(public.candidatures)', 'EXECUTE'),
  'a6 : la fonction privee reste fermee aux comptes connectes et a anon');
ROLLBACK;
