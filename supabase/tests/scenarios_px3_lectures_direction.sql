-- PX-3 : les deux lectures de la direction pour l'ecran « Praxis » (migration 20261129640000).
--  1 admin valide en aal1 : lit l'etat et le journal (la double verification n'est PAS exigee pour lire) ;
--  2 un tuteur, un compte non valide, anon : refus (42501 ou pas d'EXECUTE) ;
--  3 l'etat rend interrupteur, mode, plafond, cles (prefixe, usage, dates, revoquee), JAMAIS l'empreinte ni le secret ;
--  4 le journal rend seulement les lignes ecrire et annoncer, avec un extrait de 300 signes au plus ; pas d'autre outil ;
--  5 curseur : p_limite et p_avant, ordre decroissant, `suite` nul a la fin ; limite hors bornes refusee (22023) ;
--  6 trace de qui lit : chaque lecture du journal laisse UNE ligne d'audit (action praxis_journal_lu, sans texte), la lecture de
--    l'etat aucune ; l'etat est STABLE, le journal VOLATILE (il ecrit l'audit) ; les portes d'ecriture exigent toujours aal2.
-- A rejouer sur une base NEUVE. Annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal, 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'PX3 ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.appel(p_id uuid, p_role text, p_aal text, p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_sql text, p_code text, p_label text, p_db_role text DEFAULT 'authenticated', p_aal text DEFAULT 'aal2')
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_passe boolean := false; v_code text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN RAISE EXCEPTION 'PX3 ROUGE : % (aucun refus)', p_label; END IF;
  IF v_code <> p_code THEN RAISE EXCEPTION 'PX3 ROUGE : % (code % au lieu de %)', p_label, v_code, p_code; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.appel(uuid, text, text, text),
  pg_temp.refus(uuid, text, text, text, text, text, text) TO authenticated, anon;

INSERT INTO auth.users (id, email) VALUES
  ('b3000000-0000-4000-8000-000000000001', 'px3-admin@example.test'),
  ('b3000000-0000-4000-8000-000000000002', 'px3-tuteur@example.test'),
  ('b3000000-0000-4000-8000-000000000003', 'px3-admin-desactive@example.test');
INSERT INTO public.households (id, timezone) VALUES ('b3ffffff-0000-4000-8000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('b3000000-0000-4000-8000-000000000001', 'PX3-ADM-0001', 'admin', NULL, 'Direction', 'Un', 'active', 'male'),
  ('b3000000-0000-4000-8000-000000000002', 'PX3-TUT-0001', 'guardian', 'b3ffffff-0000-4000-8000-000000000001', 'Tuteur', 'Un', 'active', 'female'),
  ('b3000000-0000-4000-8000-000000000003', 'PX3-ADM-0002', 'admin', NULL, 'Direction', 'Deux', 'disabled', 'female');

-- Une cle (emise en aal2 par la porte existante) et des lignes de journal posees par l'aide du journal.
SELECT pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Chat de test', 'chat', pg_catalog.now() + interval '30 days', 'b3222222-0000-4000-8000-000000000001'::uuid)$$);
DO $$
DECLARE v_cle uuid; v_i integer;
BEGIN
  SELECT id INTO v_cle FROM private.praxis_cles LIMIT 1;
  FOR v_i IN 1..7 LOOP
    PERFORM private.praxis_noter(v_cle, 'b3000000-0000-4000-8000-000000000001', 'ecrire', 'ok',
      ('b3aaaaaa-0000-4000-8000-00000000000' || v_i)::uuid, NULL, repeat('x', 400) || v_i, pg_catalog.clock_timestamp());
  END LOOP;
  PERFORM private.praxis_noter(v_cle, 'b3000000-0000-4000-8000-000000000001', 'annoncer', 'ok', NULL, NULL, 'Annonce courte', pg_catalog.clock_timestamp());
  PERFORM private.praxis_noter(v_cle, 'b3000000-0000-4000-8000-000000000001', 'ecrire', 'plafond_fil', NULL, NULL, NULL, pg_catalog.clock_timestamp());
  PERFORM private.praxis_noter(v_cle, 'b3000000-0000-4000-8000-000000000001', 'boite', 'ok', NULL, NULL, NULL, pg_catalog.clock_timestamp());
  PERFORM private.praxis_noter(v_cle, 'b3000000-0000-4000-8000-000000000001', 'fil', 'ok', NULL, NULL, NULL, pg_catalog.clock_timestamp());
END $$;

-- 1 : lecture en aal1 (sans double verification)
CREATE TEMP TABLE r (nom text PRIMARY KEY, v jsonb);
GRANT ALL ON r TO authenticated;
INSERT INTO r SELECT 'etat', pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1', 'SELECT public.direction_praxis_etat()');
INSERT INTO r SELECT 'j1', pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1', 'SELECT public.direction_praxis_journal(4, NULL)');
INSERT INTO r SELECT 'j2', pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1',
  pg_catalog.format('SELECT public.direction_praxis_journal(4, %s)', (SELECT (v ->> 'suite')::bigint FROM r WHERE nom = 'j1')));
SELECT pg_temp.vrai((SELECT v FROM r WHERE nom = 'etat') ->> 'actif' = 'false' AND (SELECT v FROM r WHERE nom = 'etat') ->> 'autonome' = 'false'
  AND (SELECT v FROM r WHERE nom = 'etat') ->> 'envoisParHeure' = '30',
  '1 : un administrateur en aal1 lit l''etat (interrupteur faux, mode non autonome, plafond 30 par defaut)');

-- 3 : la cle, sans empreinte ni secret
SELECT pg_temp.vrai(jsonb_array_length((SELECT v FROM r WHERE nom = 'etat') -> 'cles') = 1
  AND (SELECT v FROM r WHERE nom = 'etat') -> 'cles' -> 0 ->> 'usage' = 'chat'
  AND (SELECT v FROM r WHERE nom = 'etat') -> 'cles' -> 0 ->> 'prefixe' LIKE 'prx\_%'
  AND NOT ((SELECT v FROM r WHERE nom = 'etat') -> 'cles' -> 0 ? 'empreinte')
  AND NOT ((SELECT v FROM r WHERE nom = 'etat') -> 'cles' -> 0 ? 'secret')
  AND (SELECT v FROM r WHERE nom = 'etat') ->> 'cles' !~ 'prx_[0-9a-f]{20}'
  AND (SELECT v FROM r WHERE nom = 'etat') -> 'cles' -> 0 ->> 'revoqueeLe' IS NULL
  AND (SELECT v FROM r WHERE nom = 'etat') -> 'cles' -> 0 ->> 'etat' = 'active',
  '3 : l''etat rend la cle par son prefixe, son usage et ses dates, jamais l''empreinte ni le secret');

-- 4, 5 : le journal
SELECT pg_temp.vrai(jsonb_array_length((SELECT v FROM r WHERE nom = 'j1') -> 'lignes') = 4
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'j1') -> 'lignes') l WHERE l ->> 'outil' NOT IN ('ecrire', 'annoncer'))
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'j2') -> 'lignes') l WHERE l ->> 'outil' NOT IN ('ecrire', 'annoncer'))
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'j1') -> 'lignes') l WHERE length(l ->> 'extrait') > 300),
  '4 : le journal rend seulement les lignes ecrire et annoncer, extrait de 300 signes au plus');
SELECT pg_temp.vrai((SELECT v FROM r WHERE nom = 'j1') -> 'lignes' -> 0 ->> 'issue' = 'plafond_fil'
  AND (SELECT v FROM r WHERE nom = 'j1') -> 'lignes' -> 0 -> 'extrait' = 'null'::jsonb
  AND (SELECT v FROM r WHERE nom = 'j1') -> 'lignes' -> 1 ->> 'outil' = 'annoncer'
  AND (SELECT v FROM r WHERE nom = 'j1') -> 'lignes' -> 1 ->> 'extrait' = 'Annonce courte',
  '4 : les plus recentes d''abord ; un refus n''a pas d''extrait ; l''annonce rend son texte');
SELECT pg_temp.vrai((SELECT (v ->> 'suite') IS NOT NULL FROM r WHERE nom = 'j1')
  AND jsonb_array_length((SELECT v FROM r WHERE nom = 'j2') -> 'lignes') = 4
  AND (SELECT v FROM r WHERE nom = 'j2') -> 'lignes' -> 0 ->> 'id' <> (SELECT v FROM r WHERE nom = 'j1') -> 'lignes' -> 3 ->> 'id'
  AND ((SELECT v FROM r WHERE nom = 'j2') -> 'lignes' -> 0 ->> 'id')::bigint < ((SELECT v FROM r WHERE nom = 'j1') -> 'lignes' -> 3 ->> 'id')::bigint,
  '5 : le curseur (suite) donne la page suivante sans repeter ni sauter une ligne');
SELECT pg_temp.vrai((SELECT count(*) FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'j1') -> 'lignes')) +
                    (SELECT count(*) FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'j2') -> 'lignes')) = 8
  AND (SELECT count(*) FROM private.praxis_journal WHERE outil IN ('ecrire', 'annoncer')) = 9,
  '5 : huit lignes lues sur neuf (la derniere page n''est pas encore lue) ; les lignes d''autres outils ne sont jamais comptees');

-- 3 bis : l'etat vient de la base (revoquee, expiree)
SELECT pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Chat a revoquer', 'chat', pg_catalog.now() + interval '10 days', 'b3222222-0000-4000-8000-000000000002'::uuid)$$);
SELECT pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal2', pg_catalog.format(
  $q$SELECT public.direction_praxis_revoquer_cle(%L::uuid, 'Test de revocation', 'b3222222-0000-4000-8000-000000000003'::uuid)::text::jsonb$q$,
  (SELECT id FROM private.praxis_cles WHERE libelle = 'Chat a revoquer')));
UPDATE private.praxis_cles SET emise_le = pg_catalog.clock_timestamp() - interval '40 days', expire_le = pg_catalog.clock_timestamp() - interval '10 days'
 WHERE libelle = 'Chat de test';
INSERT INTO r SELECT 'etat2', pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1', 'SELECT public.direction_praxis_etat()');
SELECT pg_temp.vrai((SELECT count(*) FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'etat2') -> 'cles') c WHERE c ->> 'libelle' = 'Chat a revoquer' AND c ->> 'etat' = 'revoquee' AND c ->> 'motifRevocation' = 'Test de revocation') = 1
  AND (SELECT count(*) FROM jsonb_array_elements((SELECT v FROM r WHERE nom = 'etat2') -> 'cles') c WHERE c ->> 'libelle' = 'Chat de test' AND c ->> 'etat' = 'expiree') = 1,
  '3 bis : l''etat d''une cle (revoquee, expiree) est calcule par la base');

-- 2 : refus
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000002', 'guardian', 'SELECT public.direction_praxis_etat()', '42501', '2 : un tuteur ne lit pas l''etat');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000002', 'guardian', 'SELECT public.direction_praxis_journal(10, NULL)', '42501', '2 : un tuteur ne lit pas le journal');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000003', 'admin', 'SELECT public.direction_praxis_etat()', '42501', '2 : un administrateur au compte desactive ne lit pas l''etat');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000003', 'admin', 'SELECT public.direction_praxis_journal(10, NULL)', '42501', '2 : un administrateur au compte desactive ne lit pas le journal');
SELECT pg_temp.refus(NULL, NULL, 'SELECT public.direction_praxis_etat()', '42501', '2 : anon n''a aucun EXECUTE (etat)', 'anon');
SELECT pg_temp.refus(NULL, NULL, 'SELECT public.direction_praxis_journal(10, NULL)', '42501', '2 : anon n''a aucun EXECUTE (journal)', 'anon');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000001', 'admin', 'SELECT public.direction_praxis_journal(0, NULL)', '22023', '5 : limite 0 refusee');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000001', 'admin', 'SELECT public.direction_praxis_journal(101, NULL)', '22023', '5 : limite 101 refusee');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000001', 'admin', 'SELECT public.direction_praxis_journal(NULL, NULL)', '22023', '5 : limite nulle refusee');

-- 6 : trace de qui lit. Les lectures de l'etat n'en laissent pas ; chaque lecture du journal en laisse une, sans texte.
CREATE TEMP TABLE aud (avant_journal bigint, apres_journal bigint, apres_etat bigint);
GRANT ALL ON aud TO authenticated;
DO $$
DECLARE n0 bigint; n1 bigint; n2 bigint;
BEGIN
  SELECT count(*) INTO n0 FROM public.audit_logs WHERE action = 'praxis_journal_lu';
  PERFORM pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1', 'SELECT public.direction_praxis_etat()');
  SELECT count(*) INTO n1 FROM public.audit_logs WHERE action = 'praxis_journal_lu';
  PERFORM pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1', 'SELECT public.direction_praxis_journal(5, NULL)');
  SELECT count(*) INTO n2 FROM public.audit_logs WHERE action = 'praxis_journal_lu';
  INSERT INTO aud VALUES (n0, n2, n1);
END $$;
SELECT pg_temp.vrai((SELECT apres_etat = avant_journal AND apres_journal = avant_journal + 1 FROM aud),
  '6 : lire l''etat ne laisse aucune ligne d''audit ; lire le journal en laisse exactement une');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_journal_lu'
                        AND actor = 'b3000000-0000-4000-8000-000000000001'
                        AND table_name = 'private.praxis_journal' AND payload ? 'limite'
                        AND NOT (payload::text ~* '(Bonjour|Annonce courte|xxxx)')) >= 1,
  '6 : la ligne d''audit dit qui a lu (l''administrateur), la limite et le curseur, jamais un texte');
-- Un refus de limite ou d'autorisation ne laisse aucune trace de lecture.
DO $$
DECLARE n0 bigint; n1 bigint;
BEGIN
  SELECT count(*) INTO n0 FROM public.audit_logs WHERE action = 'praxis_journal_lu';
  BEGIN PERFORM pg_temp.appel('b3000000-0000-4000-8000-000000000002', 'guardian', 'aal1', 'SELECT public.direction_praxis_journal(5, NULL)'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN PERFORM pg_temp.appel('b3000000-0000-4000-8000-000000000001', 'admin', 'aal1', 'SELECT public.direction_praxis_journal(0, NULL)'); EXCEPTION WHEN OTHERS THEN NULL; END;
  SELECT count(*) INTO n1 FROM public.audit_logs WHERE action = 'praxis_journal_lu';
  IF n1 <> n0 THEN RAISE EXCEPTION 'PX3 ROUGE : un refus a laisse une ligne d''audit de lecture'; END IF;
  RAISE NOTICE 'OK 6 : un refus (tuteur, limite hors bornes) ne laisse aucune ligne d''audit de lecture';
END $$;
SELECT pg_temp.vrai((SELECT p.provolatile = 's' FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname = 'direction_praxis_etat')
  AND (SELECT p.provolatile = 'v' FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname = 'direction_praxis_journal')
  AND (SELECT bool_and(p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
         FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname IN ('direction_praxis_etat', 'direction_praxis_journal'))
  AND NOT has_function_privilege('service_role', 'public.direction_praxis_etat()', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.direction_praxis_journal(integer,bigint)', 'EXECUTE'),
  '6 : l''etat est STABLE, le journal VOLATILE (il ecrit l''audit) ; SECURITY DEFINER, search_path vide ; ni service_role ni agent_ro ne les executent');
SELECT pg_temp.refus('b3000000-0000-4000-8000-000000000001', 'admin', 'SELECT public.direction_praxis_regler(true, false, 30)', '42501',
  '6 : regler exige toujours la double verification (aal1 refuse)', 'authenticated', 'aal1');
ROLLBACK;
