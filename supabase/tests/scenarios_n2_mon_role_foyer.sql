-- N2 (03/11/2026) : public.mon_role_foyer(), migration 20261106700000.
--   1. le titulaire lit « titulaire » et son genre ;
--   2. le second adulte du meme foyer lit « second_adulte » ;
--   3. un tuteur d'un foyer ferme, un eleve, un compte desactive lisent « aucun » ;
--   4. anon est refuse ; l'appelant ne lit que lui-meme (aucune donnee d'une
--      autre personne dans la reponse) ;
--   5. droits et forme de la fonction.
-- A rejouer sur une base NEUVE : fixtures inserees puis annulees.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object('aal', 'aal1')::text
                ELSE pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                       pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'N2 ROUGE : %', p_label;
  END IF;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'N2 ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
  END;
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT ('a2000000-0000-4000-8000-0000000000' || p)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text), pg_temp.id(text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures : foyer f1 (titulaire a1, femme ; second adulte b1, genre non
-- enregistre ; eleve c1), tuteur d0 d'un foyer ferme f3, tuteur desactive e1
-- de f2.
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.id(x), 'n2-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','c1','d0','e1']) AS x;
INSERT INTO public.households(id, timezone)
SELECT pg_temp.id(x), 'Europe/Paris' FROM unnest(ARRAY['f1','f2','f3']) AS x;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NULL THEN NULL ELSE pg_temp.id(x.foyer) END,
       x.prenom, 'N2', x.statut::public.account_status, x.genre::public.gender
  FROM (VALUES
   ('a1','N2-TUT-0001','guardian','f1','Amina','active','female'),
   ('b1','N2-TUT-0002','guardian','f1','Karim','active',NULL),
   ('c1','N2-ELV-0001','student','f1','Yasmine','active','female'),
   ('d0','N2-TUT-0003','guardian','f3','Omar','active','male'),
   ('e1','N2-TUT-0004','guardian','f2','Sara','disabled','female')) AS x(id, mat, role, foyer, prenom, statut, genre);
UPDATE public.households SET primary_guardian_id = pg_temp.id('a1') WHERE id = pg_temp.id('f1');
UPDATE public.households SET primary_guardian_id = pg_temp.id('e1') WHERE id = pg_temp.id('f2');
-- f3 : un foyer ferme, sans titulaire ; son membre n'y a aucun role.
UPDATE public.households SET status = 'closed' WHERE id = pg_temp.id('f3');

-- ------------------------------------------------------------------
-- 1 a 3. Chacun lit son propre role.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.id('a1'), 'guardian', pg_temp.id('f1'));
SELECT pg_temp.vrai(public.mon_role_foyer() = '{"role":"titulaire","genre":"female"}'::jsonb,
  '1 : le titulaire lit titulaire et son genre');
SELECT pg_temp.qui(pg_temp.id('b1'), 'guardian', pg_temp.id('f1'));
SELECT pg_temp.vrai(public.mon_role_foyer() = '{"role":"second_adulte","genre":null}'::jsonb,
  '2 : le second adulte lit second_adulte, genre non enregistre : null');
SELECT pg_temp.qui(pg_temp.id('d0'), 'guardian', pg_temp.id('f3'));
SELECT pg_temp.vrai(public.mon_role_foyer() ->> 'role' = 'aucun'
  AND public.mon_role_foyer() ->> 'genre' = 'male',
  '3 : un tuteur d''un foyer ferme lit aucun, et son propre genre');
SELECT pg_temp.qui(pg_temp.id('c1'), 'student', pg_temp.id('f1'));
SELECT pg_temp.vrai(public.mon_role_foyer() ->> 'role' = 'aucun',
  '3 : un eleve lit aucun');
SELECT pg_temp.qui(pg_temp.id('e1'), 'guardian', pg_temp.id('f2'));
SELECT pg_temp.vrai(public.mon_role_foyer() ->> 'role' = 'aucun',
  '3 : un titulaire desactive (compte non valide) lit aucun');
-- 4. Seules les cles de l'appelant : jamais un prenom ni un identifiant.
SELECT pg_temp.qui(pg_temp.id('b1'), 'guardian', pg_temp.id('f1'));
SELECT pg_temp.vrai((SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(public.mon_role_foyer()) AS k)
    = ARRAY['genre', 'role']
  AND public.mon_role_foyer()::text NOT LIKE '%Amina%'
  AND public.mon_role_foyer()::text NOT LIKE '%' || pg_temp.id('a1')::text || '%',
  '4 : la reponse ne porte aucune donnee du titulaire');
RESET ROLE;

SET LOCAL ROLE anon;
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.refus('SELECT public.mon_role_foyer()', '4 : anon refuse');
RESET ROLE;

-- ------------------------------------------------------------------
-- 5. Droits et forme.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(has_function_privilege('authenticated', 'public.mon_role_foyer()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.mon_role_foyer()', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.mon_role_foyer()', 'EXECUTE')
  AND (SELECT prosecdef AND provolatile = 's' AND proconfig = ARRAY['search_path=""']
         FROM pg_proc WHERE oid = 'public.mon_role_foyer()'::regprocedure),
  '5 : DEFINER, STABLE, search_path vide, authenticated seul');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 8,
  'au moins 8 controles ont passe');
\o
SELECT 'N2 mon_role_foyer : scenarios verts' AS resultat;
ROLLBACK;
