-- NOUVEAU-LISTE (directeur, 16/11/2026) : migration 20261128700000_nouveau_liste.sql.
--
-- Cas couverts : (a) une candidature recue depuis moins de 7 jours et jamais ouverte par l'equipe est
-- « nouvelle » (cle nouveau de chaque ligne), une plus ancienne ne l'est jamais ; (b) filtre nouveau (vrai :
-- les nouvelles, faux : les autres), liste et voisins, et compteur compteurNouveaux ; (c) la
-- premiere ouverture par une direction (lire_candidature) trace qui et quand, une seule fois : une seconde
-- lecture n'ecrit rien, ni version ni derniere activite ne bougent ; la ligne rendue dit deja « pas
-- nouvelle » ; (d) la liste, les voisins et le compteur suivent ; (e) une lecture hors portee (autre genre)
-- ne trace rien ; (f) un filtre mal type est refuse ; (g) droits et empreintes.
-- Chaque controle leve 'NOUVEAU ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE (stub_auth puis toutes
-- les migrations) ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'NOUVEAU ROUGE : %', p_label;
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
    RAISE EXCEPTION 'NOUVEAU ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'NOUVEAU ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be4e0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be4ecccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.refs(p_page jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(right(t.l ->> 'id', 2) ORDER BY right(t.l ->> 'id', 2)), ARRAY[]::text[])
    FROM jsonb_array_elements(p_page -> 'lignes') AS t(l);
$$;
CREATE FUNCTION pg_temp.liste(p_filtre jsonb) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format('SELECT public.lister_candidatures(%L::jsonb, ''recente'', 1)', p_filtre::text));
$$;
CREATE FUNCTION pg_temp.nouveau_ligne(p_n text) RETURNS boolean
LANGUAGE sql AS $$
  SELECT (l ->> 'nouveau')::boolean FROM jsonb_array_elements(pg_temp.liste('{}'::jsonb) -> 'lignes') AS t(l)
   WHERE right(l ->> 'id', 2) = p_n;
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.refs(jsonb), pg_temp.liste(jsonb), pg_temp.nouveau_ligne(text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme). Candidats hommes : 01, 02, 03 recus depuis moins de 7 jours ; 04 recu il y a 10 jours.
-- 05 : une candidate (femme), recue depuis moins de 7 jours : hors de la portee de a1.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'nouveau-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'BE4E-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'BE4E-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '05' THEN 'female'::gender ELSE 'male'::gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, recue_le)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), v.g::gender, 'Fixture ' || v.s,
       'prequalification', 'a_completer', 'en_cours', 'lien_public', now() - v.age
FROM (VALUES ('01', 'male', interval '1 day'), ('02', 'male', interval '2 days'), ('03', 'male', interval '3 days'),
             ('04', 'male', interval '10 days'), ('05', 'female', interval '1 day')) AS v(s, g, age);
SELECT set_config('test.ref01', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), true);
SELECT set_config('test.avant03', (SELECT version || '|' || derniere_activite::text FROM public.candidatures WHERE id = pg_temp.c('03')), true);

-- ------------------------------------------------------------
-- (a) La cle nouveau de chaque ligne
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.nouveau_ligne('01') AND pg_temp.nouveau_ligne('02') AND pg_temp.nouveau_ligne('03')
  AND NOT pg_temp.nouveau_ligne('04'),
  'a1 : recues depuis moins de 7 jours et jamais ouvertes : nouvelles ; recue il y a 10 jours : jamais nouvelle');

-- ------------------------------------------------------------
-- (b) Le filtre et le compteur
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.refs(pg_temp.liste('{"nouveau": true}')) = ARRAY['01', '02', '03']
  AND pg_temp.refs(pg_temp.liste('{"nouveau": false}')) = ARRAY['04'],
  'b1 : filtre nouveau vrai : les trois nouvelles ; faux : la plus ancienne ; la candidate de l''autre genre n''y est jamais');
SELECT pg_temp.vrai((pg_temp.liste('{}') #>> '{compteurNouveaux}')::int = 3,
  'b2 : le compteur compteurNouveaux dit 3');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.voisins_candidature(%L, '{"nouveau": true}', 'recente')$q$, current_setting('test.ref01')))
    ->> 'total' = '3',
  'b3 : les voisins suivent le meme filtre (3 nouvelles)');

-- ------------------------------------------------------------
-- (c) La premiere ouverture
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT ouverte_par_equipe_le IS NULL FROM public.candidatures WHERE id = pg_temp.c('03')),
  'c0 : avant toute ouverture, aucune trace');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format($q$SELECT public.lire_candidature(%L)$q$, pg_temp.c('03')))
     ->> 'nouveau')::boolean = false,
  'c1 : la ligne rendue a l''ouverture dit deja « pas nouvelle »');
SELECT pg_temp.vrai((SELECT ouverte_par_equipe_le IS NOT NULL AND ouverte_par_equipe_par = pg_temp.p('a1')
                       FROM public.candidatures WHERE id = pg_temp.c('03')),
  'c2 : la premiere ouverture trace qui et quand');
SELECT set_config('test.ouverte03', (SELECT ouverte_par_equipe_le::text FROM public.candidatures WHERE id = pg_temp.c('03')), true);
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format($q$SELECT public.lire_candidature(%L)$q$, pg_temp.c('03')));
SELECT pg_temp.vrai((SELECT ouverte_par_equipe_le::text FROM public.candidatures WHERE id = pg_temp.c('03')) = current_setting('test.ouverte03'),
  'c3 : une seconde lecture n''ecrit rien (la trace de la premiere ouverture ne bouge pas)');
SELECT pg_temp.vrai((SELECT version || '|' || derniere_activite::text FROM public.candidatures WHERE id = pg_temp.c('03')) = current_setting('test.avant03'),
  'c4 : ni la version ni la derniere activite ne bougent (une lecture ne change pas l''etat du dossier)');

-- ------------------------------------------------------------
-- (d) La liste, les voisins et le compteur suivent
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.refs(pg_temp.liste('{"nouveau": true}')) = ARRAY['01', '02']
  AND pg_temp.refs(pg_temp.liste('{"nouveau": false}')) = ARRAY['03', '04']
  AND NOT pg_temp.nouveau_ligne('03'),
  'd1 : le dossier ouvert n''est plus nouveau : filtre et ligne le disent');
SELECT pg_temp.vrai((pg_temp.liste('{}') #>> '{compteurNouveaux}')::int = 2
  AND pg_temp.en(pg_temp.p('a1'), 'admin',
        pg_catalog.format($q$SELECT public.voisins_candidature(%L, '{"nouveau": true}', 'recente')$q$, current_setting('test.ref01')))
        ->> 'total' = '2',
  'd2 : le compteur et les voisins disent 2');

-- ------------------------------------------------------------
-- (e) Une lecture hors portee ne trace rien
-- ------------------------------------------------------------
SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format($q$SELECT public.lire_candidature(%L)$q$, pg_temp.c('05')));
SELECT pg_temp.vrai((SELECT ouverte_par_equipe_le IS NULL AND ouverte_par_equipe_par IS NULL
                       FROM public.candidatures WHERE id = pg_temp.c('05')),
  'e1 : lire un dossier de l''autre genre (hors portee) ne trace aucune ouverture');

-- ------------------------------------------------------------
-- (f) Un filtre mal type est refuse
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin',
  $q$SELECT public.lister_candidatures('{"nouveau": "oui"}', 'recente', 1)$q$, '22023',
  'f1 : un filtre nouveau qui n''est pas un booleen est refuse');

-- ------------------------------------------------------------
-- (g) Droits et empreintes
-- ------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('authenticated', 'private.be_nouvelle(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.be_nouvelle(public.candidatures)', 'EXECUTE'),
  'g1 : la regle (private.be_nouvelle) n''est executable par aucun compte');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%')
     FROM unnest(ARRAY['public.lire_candidature(uuid)', 'public.lister_candidatures(jsonb,text,integer)',
                       'public.voisins_candidature(text,jsonb,text)']::regprocedure[]) AS f),
  'g2 : empreintes F86 a jour pour les trois fonctions retouchees');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 15, 'z : au moins 15 controles passes');
DO $$ BEGIN RAISE NOTICE 'NOUVEAU : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
