-- inscrire_candidat : le code d'invitation se normalise comme a la verification.
-- Migration 20261117000000_inscrire_candidat_code_normalise.sql.
-- Defaut vu par le robot pieges_1 (07/11/2026) : « d3ve - 2xfy - yp8n » etait
-- valide a la verification, puis refuse (« inconnue ») a l'envoi de la candidature.
-- Cas : un code tape en minuscules, avec espaces autour des tirets, est accepte ;
-- sans tirets aussi ; un faux code reste refuse ; un code valide d'une autre
-- adresse reste refuse ; rien n'est ecrit par un refus ; la fonction garde son
-- proprietaire, SECURITY DEFINER, search_path et droits, et l'empreinte F86 de
-- son commentaire suit sa definition.
-- Aucune donnee reelle : adresses en @test.invalid, numeros fictifs.
-- Chaque controle leve 'CODE-NORMALISE ROUGE : ...' s'il echoue. A rejouer sur
-- une base NEUVE (stub_auth puis toutes les migrations) ; tout est annule a la fin.
\o /dev/null
BEGIN;

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
    RAISE EXCEPTION 'CODE-NORMALISE ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('c0de0000-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Un appel sous le role authenticated, au nom d'un compte ; le jsonb rendu
-- apres retour au proprietaire.
CREATE FUNCTION pg_temp.en(p_id uuid, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims',
    pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
                                 'app_metadata', pg_catalog.json_build_object())::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

-- Les appels et leurs controles sont dans des instructions SEPAREES : une
-- sous-requete ne voit pas, dans la meme instruction, ce que l'appel a ecrit.
CREATE FUNCTION pg_temp.ecritures() RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'profils', (SELECT count(*) FROM public.profiles),
    'candidatures', (SELECT count(*) FROM public.candidatures),
    'invitations_utilisees', (SELECT count(*) FROM public.invitations_enseignant WHERE utilisee_le IS NOT NULL));
$$;

-- Fixtures : une direction (auteur des invitations), quatre invitations, six comptes.
INSERT INTO auth.users (id, email, email_confirmed_at)
SELECT pg_temp.p(s), 'code-norm-' || s || '@test.invalid', pg_catalog.clock_timestamp()
FROM unnest(ARRAY['d1', 'b1', 'b2', 'b3', 'b4', 'b5']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('d1'), 'C0DE-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male');
INSERT INTO public.invitations_enseignant (code, email, cree_par, cree_le, expire_le)
VALUES
 ('ABCD-EFGH-JKMN', 'code-norm-b1@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days'),
 ('MNPQ-RSTU-VWXY', 'code-norm-b2@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days'),
 ('2345-6789-ABCD', 'code-norm-b3@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days'),
 ('KMNP-QRST-UVWX', 'code-norm-b4@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days');

-- 1. La fonction a la forme attendue (migration posee) et garde ses droits.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.strpos(p.prosrc, 'i.code = app_private.code_invitation_normalise(v_code)') > 0
          AND pg_catalog.strpos(p.prosrc, 'pg_catalog.upper(v_code)') = 0
     FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure),
  'inscrire_candidat compare le code par code_invitation_normalise, plus par upper seul');
SELECT pg_temp.vrai(
  (SELECT p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
          AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
     FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure)
  AND pg_catalog.has_function_privilege('authenticated',
        'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure, 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon',
        'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure, 'EXECUTE'),
  'proprietaire postgres, SECURITY DEFINER, search_path vide, execution pour authenticated seul');
SELECT pg_temp.vrai(
  (SELECT obj_description(p.oid, 'pg_proc') LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || '%'
     FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure),
  'l''empreinte F86 du commentaire suit la definition');

-- 2. Les refus ne laissent aucune ecriture.
SELECT pg_temp.garde('avant', pg_temp.ecritures());
SELECT pg_temp.garde('r_faux', pg_temp.en(pg_temp.p('b5'), $$SELECT public.inscrire_candidat('ZZZZ-ZZZZ-ZZZZ', 'Essai', 'Faux', 'male', '+966500000105', 'fr', '2026-11-v1')$$));
SELECT pg_temp.garde('r_autre', pg_temp.en(pg_temp.p('b5'), $$SELECT public.inscrire_candidat('abcd - efgh - jkmn', 'Essai', 'Autre', 'male', '+966500000105', 'fr', '2026-11-v1')$$));
SELECT pg_temp.garde('r_court', pg_temp.en(pg_temp.p('b5'), $$SELECT public.inscrire_candidat('abc', 'Essai', 'Court', 'male', '+966500000105', 'fr', '2026-11-v1')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('r_faux') = '{"resultat": "inconnue"}'::jsonb
  AND pg_temp.lu('r_autre') = '{"resultat": "inconnue"}'::jsonb
  AND pg_temp.lu('r_court') = '{"resultat": "inconnue"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant'),
  'un faux code, un code valide d''une autre adresse (meme tape en minuscules avec espaces) et un code trop court : inconnue ; 0 ecriture');

-- 3. Les formes tapees d'un code valide sont acceptees : minuscules et espaces
--    autour des tirets (le cas du robot), sans tirets, espaces seuls, forme stockee.
SELECT pg_temp.garde('r1', pg_temp.en(pg_temp.p('b1'), $$SELECT public.inscrire_candidat('abcd - efgh - jkmn', 'Essai', 'Un', 'female', '+966500000101', 'fr', '2026-11-v1')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('r1') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT utilisee_par = pg_temp.p('b1') AND utilisee_le IS NOT NULL
         FROM public.invitations_enseignant WHERE code = 'ABCD-EFGH-JKMN')
  AND (SELECT source = 'invitation' FROM public.candidatures WHERE profile_id = pg_temp.p('b1')),
  'code tape « abcd - efgh - jkmn » (minuscules, espaces autour des tirets) : acceptee, invitation consommee, provenance invitation');
SELECT pg_temp.garde('r2', pg_temp.en(pg_temp.p('b2'), $$SELECT public.inscrire_candidat('mnpqrstuvwxy', 'Essai', 'Deux', 'female', '+966500000102', 'fr', '2026-11-v1')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('r2') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT utilisee_par = pg_temp.p('b2') FROM public.invitations_enseignant WHERE code = 'MNPQ-RSTU-VWXY'),
  'code tape sans tirets, en minuscules : acceptee');
SELECT pg_temp.garde('r3', pg_temp.en(pg_temp.p('b3'), $$SELECT public.inscrire_candidat(' 2345 6789 abcd ', 'Essai', 'Trois', 'female', '+966500000103', 'fr', '2026-11-v1')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('r3') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT utilisee_par = pg_temp.p('b3') FROM public.invitations_enseignant WHERE code = '2345-6789-ABCD'),
  'code tape avec espaces seulement, espaces de bord compris : acceptee');
SELECT pg_temp.garde('r4', pg_temp.en(pg_temp.p('b4'), $$SELECT public.inscrire_candidat('KMNP-QRST-UVWX', 'Essai', 'Quatre', 'female', '+966500000104', 'fr', '2026-11-v1')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('r4') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT utilisee_par = pg_temp.p('b4') FROM public.invitations_enseignant WHERE code = 'KMNP-QRST-UVWX'),
  'code a la forme stockee : toujours accepte (aucune regression)');

SELECT pg_catalog.set_config('test.final', pg_catalog.current_setting('test.n', true), true);
\o
SELECT 'CODE-NORMALISE : ' || pg_catalog.current_setting('test.final') || ' controles verts' AS resultat;
ROLLBACK;
