-- CAND-NOM-LATIN : le nom de reference des listes est en lettres latines.
-- Migration 20261024000000_cand_nom_latin.sql.
-- Decision du directeur du 23/10/2026 : DECISION-CANDIDATURES-2026-10-21.md, section
-- « Les noms dans une seule ecriture sur les listes ».
--
-- Cas couverts : (a) droits et empreintes F86 (deux RPC neuves, lister_candidatures
-- redefinie, l'aide interne fermee, la table sans privilege de client) ; (b) la definition
-- d'un nom latin (cas limites : accents, lettres etendues, chiffres, autres ecritures) ;
-- (c) refus par appelant (sans session, tuteur, direction, comptabilite, enseignant sans
-- candidature : 42501 d'abord, 22023 ensuite) ; (d) la confirmation : refus rendu d'un
-- texte non latin sans ecriture, blancs normalises, rejeu identique sans effet, remplacement,
-- ni version ni activite ni evenement de la candidature, aucune autre ligne, audit sans
-- le nom ; (e) la lecture du titulaire ; (f) la lecture de la direction (liste et dossier :
-- nomLatin, nomLatinAConfirmer, nom d'origine intact, portee par genre, forme a 21 cles) ;
-- (g) la recherche par l'une ou l'autre ecriture et le tri par nom latin ; (h) la
-- contrainte de la table (defense en profondeur). Rien n'est translittere par le serveur.
-- Chaque controle leve 'CAND-NOM-LATIN ROUGE : ...' s'il echoue. A rejouer sur une base
-- NEUVE (stub_auth puis toutes les migrations) ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'CAND-NOM-LATIN ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

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
    RAISE EXCEPTION 'CAND-NOM-LATIN ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CAND-NOM-LATIN ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CAND-NOM-LATIN ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'CAND-NOM-LATIN ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca1a0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca1acccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Tout ce qu'une ecriture du titulaire peut toucher pour sa candidature, hors les deux
-- colonnes du nom latin : version, activite, etape, nom d'origine, evenements, cles.
CREATE FUNCTION pg_temp.trace(p_id uuid) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'ligne', (SELECT md5((to_jsonb(c) - 'nom_latin' - 'nom_latin_confirme_le')::text)
                FROM public.candidatures c WHERE c.id = p_id),
    'evenements', (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id = p_id),
    'gestes', (SELECT count(*) FROM public.candidature_gestes g WHERE g.candidature_id = p_id));
$$;

-- Tout ce qui n'est PAS la candidature p_id : une confirmation n'y change rien.
CREATE FUNCTION pg_temp.hors(p_id uuid) RETURNS text
LANGUAGE sql AS $$
  SELECT md5(coalesce((SELECT string_agg(to_jsonb(c)::text, '|' ORDER BY c.id)
                         FROM public.candidatures c WHERE c.id <> p_id), ''));
$$;

CREATE FUNCTION pg_temp.nos(p_page jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(right(t.l ->> 'id', 2) ORDER BY t.n), ARRAY[]::text[])
    FROM jsonb_array_elements(p_page -> 'lignes') WITH ORDINALITY AS t(l, n);
$$;

CREATE FUNCTION pg_temp.cand(p_n text, p_genre public.gender, p_nom text) RETURNS uuid
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email) VALUES (pg_temp.p(p_n), 'cand-nomlatin-' || p_n || '@test.invalid');
  INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  VALUES (pg_temp.p(p_n), 'CA1A-ENS-00' || p_n, 'teacher', 'Essai' || p_n, 'Fictif', 'pending_kyc', p_genre);
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
  VALUES (pg_temp.c(p_n), 'enseignant', pg_temp.p(p_n), p_genre, p_nom, 'prequalification', 'a_completer',
          'en_cours', 'lien_public');
  RETURN pg_temp.c(p_n);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.p(text), pg_temp.c(text), pg_temp.trace(uuid)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, c1 comptable, e1 tuteur, b1 enseignant sans
-- candidature.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'cand-nomlatin-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'c1', 'e1', 'b1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca1affff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'CA1A-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('a2'), 'CA1A-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('c1'), 'CA1A-CPT-0001', 'accountant', NULL, 'Compta', 'Essai', 'active', 'male'),
 (pg_temp.p('e1'), 'CA1A-TUT-0001', 'guardian', 'ca1affff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female'),
 (pg_temp.p('b1'), 'CA1A-ENS-00B1', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male');

-- 01 nom en arabe (homme) ; 02 nom deja latin (homme) ; 03 nom en arabe (femme) ;
-- 04 nom en arabe (homme, qui ne confirme jamais) ; 05 nom mixte arabe et latin (homme).
SELECT pg_temp.cand('01', 'male', U&'\0623\062D\0645\062F \0628\0646 \0639\0644\064A');
SELECT pg_temp.cand('02', 'male', 'Zoe Martin');
SELECT pg_temp.cand('03', 'female', U&'\0641\0627\0637\0645\0629 \0627\0644\0632\0647\0631\0627\0621');
SELECT pg_temp.cand('04', 'male', U&'\064A\0648\0633\0641 \0627\0644\062F\0648\0633\0631\064A');
SELECT pg_temp.cand('05', 'male', U&'Bilal \0627\0644\062D\0628\0634\064A');

-- ------------------------------------------------------------
-- (a) Droits et empreintes F86
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT bool_and(has_function_privilege('authenticated', f, 'EXECUTE')
                   AND NOT has_function_privilege('anon', f, 'EXECUTE')
                   AND NOT has_function_privilege('service_role', f, 'EXECUTE')
                   AND NOT has_function_privilege('agent_ro', f, 'EXECUTE')
                   AND NOT has_function_privilege('public', f, 'EXECUTE'))
     FROM unnest(ARRAY['public.lire_nom_latin()', 'public.confirmer_nom_latin(text)',
                       'public.lister_candidatures(jsonb,text,integer)']::regprocedure[]) AS f),
  'a1 : seul authenticated execute les trois RPC (anon, service_role, agent_ro, public : non)');
SELECT pg_temp.vrai(
  (SELECT bool_and(NOT has_function_privilege(r, 'private.nom_est_latin(text)'::regprocedure, 'EXECUTE'))
     FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r),
  'a2 : l''aide interne nom_est_latin n''est executable par aucun compte');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
                   AND obj_description(f, 'pg_proc') LIKE '%CAND-NOM-LATIN%'
                   AND prosecdef AND proconfig @> ARRAY['search_path=""'])
     FROM unnest(ARRAY['public.lire_nom_latin()', 'public.confirmer_nom_latin(text)',
                       'public.lister_candidatures(jsonb,text,integer)']::regprocedure[]) AS f
     JOIN pg_proc p ON p.oid = f),
  'a3 : empreinte F86 a jour, DEFINER, search_path vide sur les trois RPC');
SELECT pg_temp.vrai(
  (SELECT p.provolatile = 's' FROM pg_proc p WHERE p.oid = 'public.lire_nom_latin()'::regprocedure)
  AND (SELECT p.provolatile = 'v' FROM pg_proc p WHERE p.oid = 'public.confirmer_nom_latin(text)'::regprocedure),
  'a4 : lire_nom_latin stable, confirmer_nom_latin volatile');
SELECT pg_temp.vrai(
  (SELECT bool_and(NOT has_table_privilege(r, 'public.candidatures', 'SELECT,INSERT,UPDATE'))
     FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r)
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.candidatures'::regclass)
  AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'candidatures'),
  'a5 : candidatures reste fermee (RLS, aucune policy, aucun privilege de client)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace AND proname LIKE 'cand\_%') = 9,
  'a6 : les neuf aides cand_ restent neuf');

-- ------------------------------------------------------------
-- (b) Ce qu'est un nom latin
-- ------------------------------------------------------------
SELECT pg_temp.vrai(private.nom_est_latin('Ahmed Ben Ali')
  AND private.nom_est_latin('Jean-Pierre O''Neil')
  AND private.nom_est_latin(U&'Fran\00E7ois N\00FA\00F1ez')
  AND private.nom_est_latin(U&'\0141ukasz Nowak')
  AND private.nom_est_latin(U&'Nguy\1EC5n V\0103n An')
  AND private.nom_est_latin('Abdel Rahman 2')
  AND private.nom_est_latin(U&'Cre\0301me'),
  'b1 : des noms latins (accents, lettres etendues, apostrophe, trait d''union, chiffre, accent combinant)');
SELECT pg_temp.vrai(NOT private.nom_est_latin(U&'\0623\062D\0645\062F')
  AND NOT private.nom_est_latin(U&'Ahmed \0623\062D\0645\062F')
  AND NOT private.nom_est_latin(U&'\041D\0438\043D\0430')
  AND NOT private.nom_est_latin('123 45')
  AND NOT private.nom_est_latin('')
  AND NOT private.nom_est_latin('   ')
  AND NOT private.nom_est_latin(NULL),
  'b2 : pas latins (arabe, mixte, cyrillique, chiffres seuls, vide, blancs, nul)');

-- ------------------------------------------------------------
-- (c) Refus par appelant : le titulaire d'abord (42501), les arguments ensuite (22023)
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.confirmer_nom_latin(''Essai'')', '42501',
  'c1 : sans session, confirmer est refuse', 'anon');
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.lire_nom_latin()', '42501',
  'c2 : sans session, lire est refuse', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('e1'), 'guardian', 'SELECT public.confirmer_nom_latin(''Essai'')', '42501',
  'c3 : un tuteur ne confirme pas');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.confirmer_nom_latin(''Essai'')', '42501',
  'c4 : la direction ne confirme le nom de personne');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', 'SELECT public.lire_nom_latin()', '42501',
  'c5 : la direction ne lit pas par cette voie');
SELECT pg_temp.refus_en(pg_temp.p('c1'), 'accountant', 'SELECT public.confirmer_nom_latin(''Essai'')', '42501',
  'c6 : la comptabilite ne confirme pas');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', 'SELECT public.confirmer_nom_latin(''Essai'')', '42501',
  'c7 : un enseignant sans candidature ne confirme pas');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', 'SELECT public.lire_nom_latin()', '42501',
  'c8 : un enseignant sans candidature ne lit pas');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', 'SELECT public.confirmer_nom_latin(NULL)', '42501',
  'c9 : le titulaire d''abord : sans candidature, un argument nul reste 42501');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher', 'SELECT public.confirmer_nom_latin(NULL)', '22023',
  'c10 : un titulaire, argument nul : 22023');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher', 'SELECT public.confirmer_nom_latin(''   '')', '22023',
  'c11 : un titulaire, texte de blancs : 22023');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  'SELECT public.confirmer_nom_latin(repeat(''a'', 201))', '22023',
  'c12 : un titulaire, texte de 201 signes : 22023');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  'SELECT public.confirmer_nom_latin(repeat(''a'', 401))', '22023',
  'c13 : un titulaire, texte de 401 signes : 22023 (borne avant tout calcul)');
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.p('04');
SELECT pg_temp.refus_en(pg_temp.p('04'), 'teacher', 'SELECT public.confirmer_nom_latin(''Youssef Dosari'')', '42501',
  'c14 : un compte desactive ne confirme pas');
UPDATE public.profiles SET account_status = 'pending_kyc' WHERE id = pg_temp.p('04');

-- ------------------------------------------------------------
-- (d) La confirmation
-- ------------------------------------------------------------
SELECT pg_temp.garde('t01', pg_temp.trace(pg_temp.c('01')));
SELECT pg_temp.garde('h01', to_jsonb(pg_temp.hors(pg_temp.c('01'))));

-- Un texte non latin : refus rendu, rien d'ecrit.
SELECT pg_temp.garde('r1', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.confirmer_nom_latin(U&'\0623\062D\0645\062F')$$));
SELECT pg_temp.vrai(pg_temp.lu('r1') = '{"erreur": "nom_non_latin"}'::jsonb
  AND (SELECT nom_latin IS NULL AND nom_latin_confirme_le IS NULL FROM public.candidatures WHERE id = pg_temp.c('01')),
  'd1 : un nom en arabe est refuse (nom_non_latin), rien n''est ecrit');
SELECT pg_temp.garde('r1b', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.confirmer_nom_latin('Ahmed 123 ?? ' || U&'\0623')$$));
SELECT pg_temp.vrai(pg_temp.lu('r1b') = '{"erreur": "nom_non_latin"}'::jsonb,
  'd2 : un nom mixte est refuse aussi');
SELECT pg_temp.garde('r1c', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.confirmer_nom_latin('1234')$$));
SELECT pg_temp.vrai(pg_temp.lu('r1c') = '{"erreur": "nom_non_latin"}'::jsonb,
  'd3 : des chiffres seuls ne sont pas un nom latin');

-- Avant : a confirmer.
SELECT pg_temp.garde('l0', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.lire_nom_latin()$$));
SELECT pg_temp.vrai(pg_temp.lu('l0') ->> 'nomComplet' = U&'\0623\062D\0645\062F \0628\0646 \0639\0644\064A'
  AND pg_temp.lu('l0') -> 'nomLatin' = 'null'::jsonb
  AND (pg_temp.lu('l0') ->> 'dejaLatin')::boolean = false
  AND (pg_temp.lu('l0') ->> 'aConfirmer')::boolean = true,
  'e1 : lire_nom_latin avant : nom d''origine rendu, pas de nom latin, a confirmer');

-- La confirmation, avec des blancs a normaliser.
SELECT pg_temp.garde('c1', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.confirmer_nom_latin('   Ahmed   Ben  Ali ')$$));
SELECT pg_temp.vrai(pg_temp.lu('c1') = '{"nomLatin": "Ahmed Ben Ali", "aConfirmer": false}'::jsonb
  AND (SELECT nom_latin = 'Ahmed Ben Ali' AND nom_latin_confirme_le IS NOT NULL
         AND nom_complet = U&'\0623\062D\0645\062F \0628\0646 \0639\0644\064A'
         FROM public.candidatures WHERE id = pg_temp.c('01')),
  'd4 : le nom latin est confirme, les blancs sont normalises, le nom d''origine ne change pas');
SELECT pg_temp.vrai(pg_temp.trace(pg_temp.c('01')) = pg_temp.lu('t01'),
  'd5 : ni version, ni activite, ni etape, ni evenement, ni geste de la candidature ne bougent');
SELECT pg_temp.vrai(pg_temp.hors(pg_temp.c('01')) = pg_temp.lu('h01') #>> '{}',
  'd6 : aucune autre candidature ne change');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs
                      WHERE row_id = pg_temp.c('01')::text AND action = 'candidature_nom_latin_confirme') = 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs
                   WHERE row_id = pg_temp.c('01')::text AND action = 'candidature_nom_latin_confirme'
                     AND payload::text LIKE '%Ahmed%'),
  'd7 : une ligne d''audit, sans le nom');

-- Rejeu identique : rien ne change, pas de nouvel audit, meme date.
SELECT pg_temp.garde('d0', to_jsonb((SELECT nom_latin_confirme_le FROM public.candidatures
                                      WHERE id = pg_temp.c('01'))));
SELECT pg_temp.garde('c2', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.confirmer_nom_latin('Ahmed Ben Ali')$$));
SELECT pg_temp.vrai(to_jsonb((SELECT nom_latin_confirme_le FROM public.candidatures WHERE id = pg_temp.c('01')))
    = pg_temp.lu('d0')
  AND (SELECT count(*) FROM public.audit_logs
        WHERE row_id = pg_temp.c('01')::text AND action = 'candidature_nom_latin_confirme') = 1,
  'd8 : une confirmation identique ne change rien (date, audit)');

-- Remplacement : la personne corrige.
SELECT pg_temp.garde('c3', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.confirmer_nom_latin('Ahmed Bin Ali')$$));
SELECT pg_temp.vrai((SELECT nom_latin = 'Ahmed Bin Ali' FROM public.candidatures WHERE id = pg_temp.c('01'))
  AND (SELECT count(*) FROM public.audit_logs
        WHERE row_id = pg_temp.c('01')::text AND action = 'candidature_nom_latin_confirme') = 2
  AND pg_temp.trace(pg_temp.c('01')) = pg_temp.lu('t01')
  AND pg_temp.hors(pg_temp.c('01')) = pg_temp.lu('h01') #>> '{}',
  'd9 : une correction remplace le nom latin, laisse une seconde ligne d''audit, ne touche rien d''autre');

-- Un nom deja latin peut aussi etre confirme (ecriture preferee, ex. translitteration voulue).
SELECT pg_temp.garde('c4', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.confirmer_nom_latin('Zoe  Martin-Lopez')$$));
SELECT pg_temp.vrai((SELECT nom_latin = 'Zoe Martin-Lopez' AND nom_complet = 'Zoe Martin'
                       FROM public.candidatures WHERE id = pg_temp.c('02')),
  'd10 : un nom deja latin peut aussi etre precise, le nom d''origine reste');

-- Lecture du titulaire apres.
SELECT pg_temp.garde('l1', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.lire_nom_latin()$$));
SELECT pg_temp.vrai(pg_temp.lu('l1') ->> 'nomLatin' = 'Ahmed Bin Ali'
  AND (pg_temp.lu('l1') ->> 'aConfirmer')::boolean = false,
  'e2 : lire_nom_latin apres : nom latin rendu, plus rien a confirmer');
SELECT pg_temp.garde('l2', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_nom_latin()$$));
SELECT pg_temp.vrai((pg_temp.lu('l2') ->> 'dejaLatin')::boolean AND NOT (pg_temp.lu('l2') ->> 'aConfirmer')::boolean,
  'e3 : un nom deja latin n''est jamais a confirmer');
SELECT pg_temp.garde('l4', pg_temp.en(pg_temp.p('04'), 'teacher', $$SELECT public.lire_nom_latin()$$));
SELECT pg_temp.vrai((pg_temp.lu('l4') ->> 'aConfirmer')::boolean AND pg_temp.lu('l4') -> 'nomLatin' = 'null'::jsonb,
  'e4 : un autre titulaire ne voit que sa propre ligne (04 reste a confirmer)');

-- ------------------------------------------------------------
-- (f) La lecture de la direction
-- ------------------------------------------------------------
SELECT pg_temp.garde('liste', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lister_candidatures('{}'::jsonb, 'nom', 1)$$));
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.lu('liste')) @> ARRAY['01', '02', '04', '05']
  AND NOT pg_temp.nos(pg_temp.lu('liste')) @> ARRAY['03'],
  'f1 : la direction des hommes voit 01, 02, 04, 05 et pas 03 (portee par genre)');
SELECT pg_temp.vrai(
  (SELECT l ->> 'nomLatin' = 'Ahmed Bin Ali' AND (l ->> 'nomLatinAConfirmer')::boolean = false
          AND l ->> 'nomComplet' = U&'\0623\062D\0645\062F \0628\0646 \0639\0644\064A'
     FROM jsonb_array_elements(pg_temp.lu('liste') -> 'lignes') l WHERE right(l ->> 'id', 2) = '01'),
  'f2 : 01 confirme : nomLatin rendu, pas a confirmer, nom d''origine intact');
SELECT pg_temp.vrai(
  (SELECT l ->> 'nomLatin' = 'Zoe Martin-Lopez' AND (l ->> 'nomLatinAConfirmer')::boolean = false
     FROM jsonb_array_elements(pg_temp.lu('liste') -> 'lignes') l WHERE right(l ->> 'id', 2) = '02'),
  'f3 : 02 precise : le nom latin confirme est rendu');
SELECT pg_temp.vrai(
  (SELECT l -> 'nomLatin' = 'null'::jsonb AND (l ->> 'nomLatinAConfirmer')::boolean
          AND l ->> 'nomComplet' = U&'\064A\0648\0633\0641 \0627\0644\062F\0648\0633\0631\064A'
     FROM jsonb_array_elements(pg_temp.lu('liste') -> 'lignes') l WHERE right(l ->> 'id', 2) = '04'),
  'f4 : 04 non confirme, nom arabe : nomLatin nul, a confirmer ; le serveur ne translittere rien');
SELECT pg_temp.vrai(
  (SELECT l -> 'nomLatin' = 'null'::jsonb AND (l ->> 'nomLatinAConfirmer')::boolean
     FROM jsonb_array_elements(pg_temp.lu('liste') -> 'lignes') l WHERE right(l ->> 'id', 2) = '05'),
  'f5 : 05 mixte non confirme : a confirmer');
-- 06 : un nom deja latin sans aucune confirmation (cree ici, rien d'ecrit).
SELECT pg_temp.cand('06', 'male', 'Omar Diallo');
SELECT pg_temp.garde('liste2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lister_candidatures('{}'::jsonb, 'nom', 1)$$));
SELECT pg_temp.vrai(
  (SELECT l ->> 'nomLatin' = 'Omar Diallo' AND NOT (l ->> 'nomLatinAConfirmer')::boolean
     FROM jsonb_array_elements(pg_temp.lu('liste2') -> 'lignes') l WHERE right(l ->> 'id', 2) = '06'),
  'f6 : 06 deja latin, rien de confirme : le nom d''origine fait office de nom latin, rien a confirmer');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('liste2') -> 'lignes') l
               WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(l) k) IS DISTINCT FROM
                     ARRAY['courrielAObtenir', 'derniereActivite', 'enPause', 'etape', 'etat', 'id',
                           'indicatifAConfirmer', 'indisponible', 'indisponibleJusquAu', 'issue', 'nomComplet',
                           'nomLatin', 'nomLatinAConfirmer', 'paiement', 'paysResidence', 'recueLe',
                           'reference', 'repriseLe', 'responsableId', 'restreinte', 'type']),
  'f7 : la ligne de liste a 21 cles : les 19 d''avant et nomLatin, nomLatinAConfirmer (ni courriel, ni telephone, ni genre)');
SELECT pg_temp.garde('dossier', pg_temp.en(pg_temp.p('a1'), 'admin',
  format($$SELECT public.lire_candidature(%L)$$, pg_temp.c('01'))));
SELECT pg_temp.vrai(pg_temp.lu('dossier') ->> 'nomLatin' = 'Ahmed Bin Ali'
  AND (pg_temp.lu('dossier') ->> 'nomLatinAConfirmer')::boolean = false
  AND pg_temp.lu('dossier') ->> 'nomComplet' = U&'\0623\062D\0645\062F \0628\0646 \0639\0644\064A',
  'f8 : le dossier porte nomLatin et le nom d''origine');
SELECT pg_temp.garde('dossier_hp', pg_temp.en(pg_temp.p('a2'), 'admin',
  format($$SELECT public.lire_candidature(%L)$$, pg_temp.c('01'))));
SELECT pg_temp.vrai(pg_temp.lu('dossier_hp') = '{"erreur": "hors_portee"}'::jsonb,
  'f9 : la direction des femmes ne lit pas 01 : hors portee, aucun nom');
SELECT pg_temp.garde('liste_f', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.lister_candidatures('{}'::jsonb, 'nom', 1)$$));
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.lu('liste_f')) = ARRAY['03']
  AND (pg_temp.lu('liste_f') -> 'lignes' -> 0 ->> 'nomLatinAConfirmer')::boolean,
  'f10 : la direction des femmes ne voit que 03, a confirmer');

-- ------------------------------------------------------------
-- (g) Recherche par l'une ou l'autre ecriture, tri par nom latin
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_candidatures('{"recherche": "ahmed bin"}'::jsonb, 'nom', 1)$$)) = ARRAY['01'],
  'g1 : la recherche trouve par le nom latin (casse ignoree)');
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_candidatures(jsonb_build_object('recherche', U&'\0628\0646 \0639\0644\064A'), 'nom', 1)$$))
    = ARRAY['01'],
  'g2 : la recherche trouve par le nom d''origine en arabe');
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_candidatures('{"recherche": "martin-lopez"}'::jsonb, 'nom', 1)$$)) = ARRAY['02'],
  'g3 : la recherche trouve par le nom latin precise (02)');
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_candidatures('{"recherche": "zoe martin"}'::jsonb, 'nom', 1)$$)) = ARRAY['02'],
  'g4 : la recherche trouve aussi par le nom d''origine latin (02)');
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_candidatures('{"recherche": "ahmed"}'::jsonb, 'nom', 1)$$)) = ARRAY['01'],
  'g5 : « ahmed » ne trouve pas 05 (Bilal) ni les autres');
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.lister_candidatures('{"recherche": "bilal"}'::jsonb, 'nom', 1)$$)) = ARRAY['05'],
  'g6 : le nom d''origine mixte se cherche par sa partie latine');
-- Le tri par nom : le nom latin quand il existe, sinon le nom d'origine.
SELECT pg_temp.vrai(
  (SELECT array_position(pg_temp.nos(pg_temp.lu('liste2')), '01') < array_position(pg_temp.nos(pg_temp.lu('liste2')), '06')
      AND array_position(pg_temp.nos(pg_temp.lu('liste2')), '06') < array_position(pg_temp.nos(pg_temp.lu('liste2')), '02')),
  'g7 : tri par nom : Ahmed Bin Ali (01) avant Omar Diallo (06) avant Zoe Martin-Lopez (02) ; le nom latin ordonne');

-- ------------------------------------------------------------
-- (h) La table se defend elle-meme (defense en profondeur)
-- ------------------------------------------------------------
SELECT pg_temp.refus(
  format($$UPDATE public.candidatures SET nom_latin = U&'\0623\062D\0645\062F', nom_latin_confirme_le = now() WHERE id = %L$$, pg_temp.c('03')),
  '23514', 'h1 : la table refuse un nom latin en arabe');
SELECT pg_temp.refus(
  format($$UPDATE public.candidatures SET nom_latin = 'Fatima Zahra' WHERE id = %L$$, pg_temp.c('03')),
  '23514', 'h2 : la table refuse un nom latin sans date de confirmation');
SELECT pg_temp.refus(
  format($$UPDATE public.candidatures SET nom_latin_confirme_le = now() WHERE id = %L$$, pg_temp.c('03')),
  '23514', 'h3 : la table refuse une date de confirmation sans nom latin');
SELECT pg_temp.refus(
  format($$UPDATE public.candidatures SET nom_latin = ' Fatima Zahra ', nom_latin_confirme_le = now() WHERE id = %L$$, pg_temp.c('03')),
  '23514', 'h4 : la table refuse un nom latin avec des blancs en bordure');
SELECT pg_temp.refus(
  format($$UPDATE public.candidatures SET nom_latin = repeat('a', 201), nom_latin_confirme_le = now() WHERE id = %L$$, pg_temp.c('03')),
  '23514', 'h5 : la table refuse un nom latin de plus de 200 signes');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 58,
  'z : au moins 58 controles passes');
DO $$ BEGIN RAISE NOTICE 'CAND-NOM-LATIN : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
