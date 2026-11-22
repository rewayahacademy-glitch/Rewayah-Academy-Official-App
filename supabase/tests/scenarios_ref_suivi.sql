-- REF-SUIVI (migration 20261130978000) : public.noter_source_inscription(p_ref) et private.sources_inscription.
-- Controles : sans session -> refus 28000 ; ref invalide (majuscule, souligne, 49 signes, vide, null) -> 22023 ;
-- premiere pose vraie, seconde (autre ref) fausse et sans effet ; un compte ne touche pas la source d'un autre ;
-- aucun acces direct a la table pour authenticated et anon ; droit d'execution : authenticated oui, anon non ;
-- CHECK de format sur la table. Donnees fictives. Annule tout a la fin. Aucun mot d'effacement.
-- Ce scenario n'est PAS dans .github/workflows/ci.yml (zone interdite a ce lot) : il se rejoue a la main ou par tool/e2e/.
\o /dev/null
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims',
    CASE WHEN p_id IS NULL THEN '{}' ELSE pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated')::text END, true);
END $$;

CREATE FUNCTION pg_temp.code_refus(p_id uuid, p_sql text, p_db_role text DEFAULT 'authenticated') RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    EXECUTE 'RESET ROLE';
    RETURN 'aucun';
  EXCEPTION WHEN OTHERS THEN
    RETURN SQLSTATE;
  END;
END $$;

CREATE FUNCTION pg_temp.appel(p_id uuid, p_ref text) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE v boolean;
BEGIN
  PERFORM pg_temp.qui(p_id);
  EXECUTE 'SET LOCAL ROLE authenticated';
  SELECT public.noter_source_inscription(p_ref) INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE TEMP TABLE res (nom text PRIMARY KEY, ok boolean NOT NULL, detail text);
GRANT ALL ON res TO authenticated, anon;
CREATE FUNCTION pg_temp.note(p_nom text, p_ok boolean, p_detail text DEFAULT NULL) RETURNS void LANGUAGE sql AS $$
  INSERT INTO res VALUES (p_nom, coalesce(p_ok, false), p_detail) $$;

CREATE FUNCTION pg_temp.p(s text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_catalog.md5('ref-suivi-' || s)::uuid $$;

INSERT INTO auth.users (id, email) VALUES (pg_temp.p('a'), 'ref-a@test.invalid'), (pg_temp.p('b'), 'ref-b@test.invalid');

SELECT pg_temp.note('1 sans session : refus 28000',
  pg_temp.code_refus(NULL, $s$SELECT public.noter_source_inscription('chingford-londres')$s$) = '28000');
SELECT pg_temp.note('2a ref avec majuscule : 22023',
  pg_temp.code_refus(pg_temp.p('a'), $s$SELECT public.noter_source_inscription('Chingford')$s$) = '22023');
SELECT pg_temp.note('2b ref avec souligne : 22023',
  pg_temp.code_refus(pg_temp.p('a'), $s$SELECT public.noter_source_inscription('a_b')$s$) = '22023');
SELECT pg_temp.note('2c ref de 49 signes : 22023',
  pg_temp.code_refus(pg_temp.p('a'), format('SELECT public.noter_source_inscription(%L)', repeat('a', 49))) = '22023');
SELECT pg_temp.note('2d ref vide : 22023',
  pg_temp.code_refus(pg_temp.p('a'), $s$SELECT public.noter_source_inscription('')$s$) = '22023');
SELECT pg_temp.note('2e ref nul : 22023',
  pg_temp.code_refus(pg_temp.p('a'), $s$SELECT public.noter_source_inscription(NULL)$s$) = '22023');
SELECT pg_temp.note('2f ref de 48 signes accepte',
  pg_temp.appel(pg_temp.p('b'), repeat('z', 48)) IS TRUE);
SELECT pg_temp.note('3 aucune ligne apres les refus pour a',
  NOT EXISTS (SELECT 1 FROM private.sources_inscription WHERE profile_id = pg_temp.p('a')));
SELECT pg_temp.note('4 premiere pose : vrai', pg_temp.appel(pg_temp.p('a'), 'chingford-londres') IS TRUE);
SELECT pg_temp.note('5 seconde pose avec une autre ref : faux', pg_temp.appel(pg_temp.p('a'), 'autre-mosquee') IS FALSE);
SELECT pg_temp.note('6 la premiere ref et sa date sont gardees',
  (SELECT source_ref = 'chingford-londres' AND source_ref_le > now() - interval '1 minute'
     FROM private.sources_inscription WHERE profile_id = pg_temp.p('a')));
SELECT pg_temp.note('7 la source de b est la sienne',
  (SELECT source_ref = repeat('z', 48) FROM private.sources_inscription WHERE profile_id = pg_temp.p('b')));
SELECT pg_temp.note('8 authenticated ne lit pas la table (42501)',
  pg_temp.code_refus(pg_temp.p('a'), 'SELECT * FROM private.sources_inscription') = '42501');
SELECT pg_temp.note('9 authenticated n''ecrit pas la table (42501)',
  pg_temp.code_refus(pg_temp.p('a'), $s$UPDATE private.sources_inscription SET source_ref = 'x'$s$) = '42501');
SELECT pg_temp.note('10 anon n''execute pas la porte',
  NOT has_function_privilege('anon', 'public.noter_source_inscription(text)', 'EXECUTE')
  AND pg_temp.code_refus(NULL, $s$SELECT public.noter_source_inscription('x')$s$, 'anon') = '42501');
SELECT pg_temp.note('11 authenticated execute la porte',
  has_function_privilege('authenticated', 'public.noter_source_inscription(text)', 'EXECUTE'));
SELECT pg_temp.note('12 la table a la RLS active',
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.sources_inscription'::regclass));
SELECT pg_temp.note('13 le CHECK de format refuse une ecriture directe',
  pg_temp.code_refus(NULL, $s$INSERT INTO private.sources_inscription (profile_id, source_ref) VALUES (gen_random_uuid(), 'MAJ')$s$, 'postgres') = '23514');
SELECT pg_temp.note('14 la porte est SECURITY DEFINER avec search_path vide',
  (SELECT prosecdef AND 'search_path=""' = ANY (proconfig) FROM pg_proc WHERE oid = 'public.noter_source_inscription(text)'::regprocedure));

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 110) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN
    RAISE EXCEPTION 'REF-SUIVI : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok);
  END IF;
END $$;
ROLLBACK;
