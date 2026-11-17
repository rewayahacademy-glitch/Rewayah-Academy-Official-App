-- PX-BD-0 (17/11/2026, migration 20261129960000_praxis_actes_socle.sql, plan PLAN-BRAS-DROIT.md, decisions DB1 a DB9) : le socle des actes de
-- Praxis en mode CHAT. Aucune personne reelle : des profils fictifs, des cles fictives. Le catalogue des actes est VIDE a l'installation ; ce
-- scenario y pose, DANS la transaction (annulee a la fin), deux actes d'essai (un A, un S) et leurs adaptateurs, et branche le pont par la meme
-- ancre que les lots suivants.
-- Cas :
--  1 le catalogue est vide a l'installation ;
--  2 une cle de ROUTINE est refusee par chaque outil (chat_seulement), rien d'ecrit ; une cle inconnue aussi ;
--  3 l'acte A : inconnu, sensible, parametres ; execute sous l'identite de la DIRECTION emettrice (aal1), trace « via Praxis », identite RESTAUREE
--    (apres un succes et apres une erreur), idempotent, plafonne a 60 par heure ;
--  4 l'acte S, preparation : refus (acte simple, lot hors taille, ligne invalide a sec), RIEN n'est execute, le code n'est jamais rendu ;
--  5 la porte de la direction : aal2 seulement, seul l'emetteur voit le code, le code est montre une fois pour toutes ;
--  6 la confirmation : code non affiche, mauvais code (trois essais, verrouillage du lot ET de la cle), bon code (aal2, tout le lot, un seul code),
--    rejeu, jeton d'une autre cle, jeton expire, lot altere (empreinte), lot annule, echec partiel d'un lot ;
--  7 les plafonds : 10 actes S par heure (refuse des la preparation), cinq lots en attente au plus ;
--  8 le pont : aucun role client ne l'appelle ; l'identite de prete n'est jamais celle d'un compte qui n'est pas une direction active ;
--  9 donnees reelles fermees : tout est refuse.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'PX-BD-0 ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal, 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
-- Un appel sous le role authenticated, au nom d'un compte.
CREATE FUNCTION pg_temp.appel(p_id uuid, p_role text, p_aal text, p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_aal text, p_sql text, p_code text, p_label text,
                              p_db_role text DEFAULT 'authenticated') RETURNS void LANGUAGE plpgsql AS $$
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
  END;
  EXECUTE 'RESET ROLE';
  IF v_passe THEN RAISE EXCEPTION 'PX-BD-0 ROUGE : % (aucun refus)', p_label; END IF;
  IF v_code <> p_code THEN RAISE EXCEPTION 'PX-BD-0 ROUGE : % (code % au lieu de %)', p_label, v_code, p_code; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
-- Un appel d'outil, au role service_role, avec des revendications SENTINELLES : on prouve qu'elles sont rendues intactes.
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claims', '{"sentinelle":true}', true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.appel(uuid, text, text, text),
  pg_temp.refus(uuid, text, text, text, text, text, text), pg_temp.srv(text) TO authenticated, anon, service_role;

CREATE FUNCTION pg_temp.u(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b0d00000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b0d11111-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(integer), pg_temp.idem(integer) TO authenticated, anon, service_role;

-- Le code d'un lot, tel que la direction emettrice le lit dans l'application (la liste peut contenir d'autres lots en attente).
CREATE FUNCTION pg_temp.code_de(p_jeton text) RETURNS text LANGUAGE sql AS $$
  SELECT x ->> 'code' FROM pg_catalog.jsonb_array_elements(
    pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_confirmations()')) x WHERE x ->> 'id' = p_jeton $$;
GRANT EXECUTE ON FUNCTION pg_temp.code_de(text) TO authenticated, anon, service_role;

-- u1 direction (homme), u2 direction (femme), u3 enseignant, u4 direction SUSPENDUE.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n), 'pxbd0-' || n || '@test.invalid' FROM generate_series(1, 4) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u(1), 'BD0-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male'),
 (pg_temp.u(2), 'BD0-ADM-0002', 'admin', 'Direction', 'Deux', 'active', 'female'),
 (pg_temp.u(3), 'BD0-ENS-0001', 'teacher', 'Enseignant', 'Trois', 'pending_kyc', 'male'),
 (pg_temp.u(4), 'BD0-ADM-0004', 'admin', 'Direction', 'Suspendue', 'disabled', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u(1));

-- ===================================================================================================
-- 1. Le catalogue est VIDE a l'installation.
-- ===================================================================================================
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.praxis_actes) = 0, '1a : le catalogue des actes est vide a l''installation du socle');

-- Des cles : un chat (k1), une routine (kr), puis d'autres chats au besoin. Reglages : Praxis allume, autonome ouvert, donnees reelles FERMEES.
CREATE FUNCTION pg_temp.cle(p_n integer, p_usage text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE j jsonb;
BEGIN
  j := pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', pg_catalog.format(
    'SELECT public.direction_praxis_emettre_cle(%L, %L, pg_catalog.now() + interval ''30 days'', %L::uuid)',
    'Cle d''essai ' || p_n, p_usage, pg_temp.idem(900 + p_n)));
  RETURN j ->> 'secret';
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.cle(integer, text) TO authenticated, anon, service_role;
SELECT pg_temp.cle(1, 'chat') AS k1 \gset
SELECT pg_temp.cle(2, 'routine') AS kr \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler(true, true, 100)');

-- 9 d'abord : donnees reelles FERMEES : tout est refuse.
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''x'', ''{}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(1)))
                    = '{"erreur": "donnees_reelles_fermees"}'::jsonb, '9a : agir est refuse tant que les donnees reelles sont fermees');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''x'', ''[]''::jsonb)', :'k1'))
                    = '{"erreur": "donnees_reelles_fermees"}'::jsonb, '9b : preparer est refuse tant que les donnees reelles sont fermees');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, ''123456'')', :'k1', pg_temp.idem(1)))
                    = '{"erreur": "donnees_reelles_fermees"}'::jsonb, '9c : confirmer est refuse tant que les donnees reelles sont fermees');
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ===================================================================================================
-- Les actes d'essai (dans la transaction) : un A, un S, leurs adaptateurs, et la branche du pont, par l'ancre.
-- ===================================================================================================
CREATE TABLE public.px_bd0_trace (n serial, uid uuid, role text, aal text, note text);
GRANT ALL ON public.px_bd0_trace TO postgres;
CREATE FUNCTION private.praxis_acte_test_a(p jsonb, p_a_sec boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $f$
BEGIN
  IF pg_catalog.jsonb_typeof(p -> 'note') IS DISTINCT FROM 'string' OR pg_catalog.length(p ->> 'note') > 50
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k WHERE k <> ALL (ARRAY['note', 'boom', 'boom_reel'])) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF p ->> 'boom' = 'oui' OR (p ->> 'boom_reel' = 'oui' AND NOT p_a_sec) THEN
    RAISE EXCEPTION 'echec voulu' USING ERRCODE = 'P0001';
  END IF;
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', 'Note A : ' || (p ->> 'note'));
  END IF;
  INSERT INTO public.px_bd0_trace (uid, role, aal, note) VALUES (auth.uid(), public.app_role()::text, auth.jwt() ->> 'aal', p ->> 'note');
  RETURN pg_catalog.jsonb_build_object('fait', true);
END;
$f$;
CREATE FUNCTION private.praxis_acte_test_s(p jsonb, p_a_sec boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $f$
BEGIN
  IF pg_catalog.jsonb_typeof(p -> 'note') IS DISTINCT FROM 'string' OR pg_catalog.length(p ->> 'note') > 50
     OR EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(p) k WHERE k <> ALL (ARRAY['note', 'boom', 'boom_reel'])) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF p ->> 'boom' = 'oui' OR (p ->> 'boom_reel' = 'oui' AND NOT p_a_sec) THEN
    RAISE EXCEPTION 'echec voulu' USING ERRCODE = 'P0001';
  END IF;
  IF p_a_sec THEN
    RETURN pg_catalog.jsonb_build_object('resume', 'Note S : ' || (p ->> 'note'));
  END IF;
  INSERT INTO public.px_bd0_trace (uid, role, aal, note) VALUES (auth.uid(), public.app_role()::text, auth.jwt() ->> 'aal', p ->> 'note');
  RETURN pg_catalog.jsonb_build_object('fait', true);
END;
$f$;
INSERT INTO private.praxis_actes (acte, niveau, description, lot_max) VALUES
  ('test_a', 'A', 'Acte d''essai de niveau A', 1), ('test_s', 'S', 'Acte d''essai de niveau S', 12);
DO $branche$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)'::regprocedure);
  v_ancre text := '    -- ACTES-ANCRE : une branche ELSIF par acte, ajoutee par la migration du lot qui cree l''acte';
  v_n integer := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, ''))) / pg_catalog.length(v_ancre);
BEGIN
  IF v_n <> 1 THEN RAISE EXCEPTION 'PX-BD-0 ROUGE : l''ancre du pont est trouvee % fois (une attendue)', v_n; END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '    ELSIF p_acte = ''test_a'' THEN v_res := private.praxis_acte_test_a(p_params, p_a_sec);' || chr(10) ||
    '    ELSIF p_acte = ''test_s'' THEN v_res := private.praxis_acte_test_s(p_params, p_a_sec);' || chr(10) || v_ancre);
END;
$branche$;

-- ===================================================================================================
-- 2. Chat seulement.
-- ===================================================================================================
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_actes(%L)', :'k1')) -> 'actes' @> '[{"acte": "test_a", "niveau": "A"}]'::jsonb,
  '2a : la cle de chat voit le catalogue');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_actes(%L)', :'kr')) = '{"erreur": "chat_seulement"}'::jsonb,
  '2b : la cle de routine ne voit pas le catalogue (chat_seulement)');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "x"}''::jsonb, %L::uuid)', :'kr', pg_temp.idem(2)))
                    = '{"erreur": "chat_seulement"}'::jsonb, '2c : la cle de routine ne peut pas agir');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "x"}]''::jsonb)', :'kr'))
                    = '{"erreur": "chat_seulement"}'::jsonb, '2d : la cle de routine ne peut pas preparer');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, ''123456'')', :'kr', pg_temp.idem(2)))
                    = '{"erreur": "chat_seulement"}'::jsonb, '2e : la cle de routine ne peut pas confirmer');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.praxis_executions) = 0 AND (SELECT pg_catalog.count(*) FROM private.praxis_confirmations) = 0
                    AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 0, '2f : la routine n''a rien ecrit ni execute');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_actes(%L)', 'prx_' || pg_catalog.repeat('0', 64))) ->> 'erreur' = 'cle_refusee',
  '2g : une cle inconnue est refusee');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "x"}''::jsonb, %L::uuid)', 'mauvaise forme', pg_temp.idem(2)))
                    ->> 'erreur' = 'cle_refusee', '2h : une cle mal formee est refusee');

-- ===================================================================================================
-- 3. L'acte A.
-- ===================================================================================================
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''inconnu'', ''{}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(3)))
                    = '{"erreur": "acte_inconnu"}'::jsonb, '3a : un acte hors catalogue est refuse');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_s'', ''{"note": "x"}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(4)))
                    = '{"erreur": "acte_sensible"}'::jsonb, '3b : un acte S ne passe pas par agir');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''[1]''::jsonb, %L::uuid)', :'k1', pg_temp.idem(5)))
                    = '{"erreur": "parametre"}'::jsonb, '3c : des parametres qui ne sont pas un objet sont refuses');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "x"}''::jsonb, NULL)', :'k1'))
                    = '{"erreur": "parametre"}'::jsonb, '3d : sans cle d''idempotence, refus');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 0, '3e : aucun de ces refus n''a rien execute');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "premier"}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(6))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"ok": true, "resultat": {"fait": true}}'::jsonb, '3f : l''acte A est execute');
SELECT pg_temp.vrai((SELECT t.uid = pg_temp.u(1) AND t.role = 'admin' AND t.aal = 'aal1' AND t.note = 'premier' FROM public.px_bd0_trace t),
  '3g : l''acte a ete execute sous l''identite de la DIRECTION emettrice, role admin, en aal1 (pas aal2 : aucun code)');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'praxis_acte' AND a.actor = pg_temp.u(1)
                              AND a.payload ->> 'via' = 'praxis' AND a.row_id = 'test_a'),
  '3h : la trace « via Praxis » est ecrite au journal d''audit AU NOM de la direction');
SELECT pg_temp.vrai(pg_catalog.current_setting('request.jwt.claims') = '{"sentinelle":true}' AND pg_catalog.current_setting('request.jwt.claim.sub') = '',
  '3i : l''identite d''avant l''appel est rendue intacte (rien n''est garde)');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "premier"}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(6))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'rejoue')::boolean AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 1,
  '3j : la meme cle d''idempotence rend le resultat sans rien refaire');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "boum", "boom": "oui"}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(7))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur": "refuse", "code": "P0001"}'::jsonb, '3k : une erreur de l''acte rend une cause fermee (le code SQL), jamais le message');
SELECT pg_temp.vrai(pg_catalog.current_setting('request.jwt.claims') = '{"sentinelle":true}' AND pg_catalog.current_setting('request.jwt.claim.sub') = '',
  '3l : l''identite est rendue intacte APRES UNE ERREUR aussi');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 1
                    AND (SELECT NOT ok AND cause = 'P0001' FROM private.praxis_executions WHERE cle_idempotence = pg_temp.idem(7)),
  '3m : l''acte en erreur n''a rien ecrit et son echec est note');
-- Plafond A : 60 par heure. On vieillit les executions pour les compter juste.
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.praxis_executions WHERE niveau = 'A') = 2, '3n : deux executions A notees');
INSERT INTO private.praxis_executions (cle_id, emetteur, acte, niveau, ok)
SELECT (SELECT cle_id FROM private.praxis_executions LIMIT 1), pg_temp.u(1), 'test_a', 'A', true FROM generate_series(1, 58);
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "plafond"}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(8)))
                    = '{"erreur": "plafond_actes"}'::jsonb, '3o : a soixante actes A dans l''heure, le suivant est refuse');
UPDATE private.praxis_executions SET cree_le = pg_catalog.clock_timestamp() - interval '2 hours' WHERE niveau = 'A';
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''test_a'', ''{"note": "apres"}''::jsonb, %L::uuid)', :'k1', pg_temp.idem(9)))
                    ->> 'ok' = 'true', '3p : une heure plus tard, le plafond est libere');

-- ===================================================================================================
-- 4. L'acte S, preparation.
-- ===================================================================================================
SELECT pg_temp.cle(3, 'chat') AS k3 \gset
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_a'', ''[{"note": "x"}]''::jsonb)', :'k3'))
                    = '{"erreur": "acte_simple"}'::jsonb, '4a : un acte A ne se prepare pas (il s''execute)');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''inconnu'', ''[{"note": "x"}]''::jsonb)', :'k3'))
                    = '{"erreur": "acte_inconnu"}'::jsonb, '4b : un acte hors catalogue est refuse');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''{"note": "x"}''::jsonb)', :'k3'))
                    = '{"erreur": "parametre"}'::jsonb, '4c : un lot qui n''est pas une liste est refuse');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[]''::jsonb)', :'k3'))
                    = '{"erreur": "lot_taille", "max": 12}'::jsonb, '4d : un lot vide est refuse');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', %L::jsonb)', :'k3',
  (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('note', 'x' || i))::text FROM generate_series(1, 13) i)))
                    = '{"erreur": "lot_taille", "max": 12}'::jsonb, '4e : un lot de treize pieces est refuse (douze au plus pour cet acte)');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "ok"}, 5]''::jsonb)', :'k3'))
                    = '{"erreur": "parametre", "indice": 1}'::jsonb, '4f : une ligne qui n''est pas un objet est refusee, avec son indice');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "ok"}, {"note": "mal", "boom": "oui"}]''::jsonb)', :'k3'))
                    = '{"erreur": "refuse", "code": "P0001", "indice": 1}'::jsonb, '4g : une ligne invalide a sec refuse tout le lot, avec son indice');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "ok"}, {"autre": "mal"}]''::jsonb)', :'k3'))
                    = '{"erreur": "refuse", "indice": 1, "detail": "parametre"}'::jsonb, '4h : un parametre hors schema est refuse, avec la cause de l''adaptateur');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM private.praxis_confirmations) = 0 AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 2,
  '4i : aucun de ces refus n''a cree de lot ni rien execute');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "un"}, {"note": "deux"}, {"note": "trois"}]''::jsonb)', :'k3')) AS j4 \gset
SELECT :'j4'::jsonb ->> 'jeton' AS jeton4 \gset
SELECT pg_temp.vrai((:'j4'::jsonb ->> 'ok')::boolean AND (:'j4'::jsonb ->> 'nb')::int = 3
                    AND :'j4'::jsonb -> 'resume' = '["Note S : un", "Note S : deux", "Note S : trois"]'::jsonb,
  '4j : la preparation rend le jeton et le resume en clair de chaque ligne');
SELECT c.code AS code4 FROM private.praxis_confirmations c WHERE c.id = :'jeton4'::uuid \gset
SELECT pg_temp.vrai(:'code4' ~ '^[0-9]{6}$' AND pg_catalog.strpos(:'j4'::text, :'code4') = 0 AND NOT (:'j4'::jsonb ? 'code'),
  '4k : le code a six chiffres existe en base et n''est JAMAIS rendu au modele');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 2 AND (SELECT pg_catalog.count(*) FROM private.praxis_executions WHERE niveau = 'S') = 0,
  '4l : la preparation n''a RIEN execute');

-- ===================================================================================================
-- 5. La porte de la direction.
-- ===================================================================================================
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_confirmations()', '42501', '5a : la porte exige aal2');
SELECT pg_temp.refus(pg_temp.u(3), 'teacher', 'aal2', 'SELECT public.direction_praxis_confirmations()', '42501', '5b : un enseignant ne voit rien');
SELECT pg_temp.refus(NULL, NULL, 'aal2', 'SELECT public.direction_praxis_confirmations()', '42501', '5c : anon ne voit rien', 'anon');
SELECT pg_temp.refus(NULL, NULL, 'aal2', 'SELECT public.direction_praxis_confirmations()', '42501', '5d : le serveur (service_role) ne lit pas les codes', 'service_role');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.appel(pg_temp.u(2), 'admin', 'aal2', 'SELECT public.direction_praxis_confirmations()')) = 0,
  '5e : une AUTRE direction ne voit pas le lot de l''emettrice de la cle');
SELECT pg_temp.vrai((SELECT code_affiche_le IS NULL FROM private.praxis_confirmations WHERE id = :'jeton4'::uuid), '5f : tant que personne n''a regarde, le code n''est pas marque affiche');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k3', :'jeton4', :'code4')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur": "code_non_affiche"}'::jsonb AND (SELECT essais = 0 AND etat = 'en_attente' FROM private.praxis_confirmations WHERE id = :'jeton4'::uuid),
  '5g : meme avec le BON code, un code jamais montre a la direction ne vaut rien (et aucun essai n''est consomme)');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_confirmations()') AS l \gset
SELECT pg_temp.vrai(:'l'::jsonb -> 0 ->> 'code' = :'code4' AND (:'l'::jsonb -> 0 ->> 'nb')::int = 3 AND :'l'::jsonb -> 0 ->> 'acte' = 'test_s'
                    AND :'l'::jsonb -> 0 -> 'resume' = :'j4'::jsonb -> 'resume', '5h : la direction emettrice voit le code, le nombre de lignes et le resume');
SELECT pg_temp.vrai((SELECT code_affiche_le IS NOT NULL FROM private.praxis_confirmations WHERE id = :'jeton4'::uuid)
                    AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'praxis_code_affiche' AND row_id = :'jeton4'), '5i : le code est marque affiche et l''affichage est journalise');

-- ===================================================================================================
-- 6. La confirmation.
-- ===================================================================================================
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, ''12345'')', :'k3', :'jeton4')) = '{"erreur": "parametre"}'::jsonb,
  '6a : un code qui n''a pas six chiffres est un parametre invalide');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k3', pg_temp.idem(555), :'code4')) = '{"erreur": "jeton_inconnu"}'::jsonb,
  '6b : un jeton inconnu est refuse');
SELECT pg_temp.cle(4, 'chat') AS k4 \gset
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k4', :'jeton4', :'code4')) = '{"erreur": "jeton_inconnu"}'::jsonb,
  '6c : le jeton d''une AUTRE cle est inconnu, meme avec le bon code');
-- Le code faux : trois essais, puis verrouillage.
SELECT :'code4'::int AS c \gset
SELECT pg_catalog.lpad(((:c + 1) % 1000000)::text, 6, '0') AS mauvais \gset
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k3', :'jeton4', :'mauvais')) = '{"erreur": "code_faux", "restants": 2}'::jsonb,
  '6d : un mauvais code : il en reste deux');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k3', :'jeton4', :'mauvais')) = '{"erreur": "code_faux", "restants": 1}'::jsonb,
  '6e : un deuxieme : il en reste un');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k3', :'jeton4', :'mauvais')) = '{"erreur": "verrouillee"}'::jsonb,
  '6f : le troisieme verrouille le lot');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k3', :'jeton4', :'code4')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur": "verrouillee"}'::jsonb
                    AND (SELECT code IS NULL AND etat = 'verrouillee' FROM private.praxis_confirmations WHERE id = :'jeton4'::uuid),
  '6g : un lot verrouille refuse meme le bon code, et son code est vide');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.px_bd0_trace) = 2, '6h : rien n''a ete execute');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "apres"}]''::jsonb)', :'k3')) = '{"erreur": "cle_verrouillee"}'::jsonb,
  '6i : la cle est verrouillee pour l''heure : plus aucune preparation');
SELECT pg_temp.vrai((pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "autre cle"}]''::jsonb)', :'k4')) ->> 'ok')::boolean,
  '6j : une autre cle n''est pas verrouillee');

-- Le bon code : tout le lot, UN seul code, en aal2.
SELECT pg_temp.cle(5, 'chat') AS k5 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "a"}, {"note": "b"}, {"note": "c"}]''::jsonb)', :'k5')) ->> 'jeton' AS jeton5 \gset
SELECT pg_temp.code_de(:'jeton5') AS code5 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k5', :'jeton5', :'code5')) AS j5 \gset
SELECT pg_temp.vrai((:'j5'::jsonb ->> 'ok')::boolean AND (:'j5'::jsonb ->> 'nb')::int = 3 AND (:'j5'::jsonb ->> 'reussis')::int = 3,
  '6k : le bon code execute les trois lignes du lot');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note IN ('a', 'b', 'c') AND uid = pg_temp.u(1) AND role = 'admin' AND aal = 'aal2') = 3,
  '6l : chaque ligne a ete executee sous l''identite de la direction EN AAL2 (le code a ete lu en aal2)');
SELECT pg_temp.vrai((SELECT etat = 'confirmee' AND code IS NULL AND confirmee_le IS NOT NULL FROM private.praxis_confirmations WHERE id = :'jeton5'::uuid)
                    AND (SELECT pg_catalog.count(*) FROM private.praxis_executions WHERE confirmation = :'jeton5'::uuid AND ok) = 3,
  '6m : le lot est confirme, son code vide, trois executions notees');
SELECT pg_temp.vrai(pg_catalog.current_setting('request.jwt.claims') = '{"sentinelle":true}', '6n : l''identite d''avant l''appel est rendue intacte apres un lot');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k5', :'jeton5', :'code5')) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'rejoue')::boolean AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note IN ('a', 'b', 'c')) = 3,
  '6o : rejouer un lot confirme rend son resultat, sans rien executer de plus');

-- Expire.
SELECT pg_temp.cle(6, 'chat') AS k6 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "lent"}]''::jsonb)', :'k6')) ->> 'jeton' AS jeton6 \gset
SELECT pg_temp.code_de(:'jeton6') AS code6 \gset
UPDATE private.praxis_confirmations SET expire_le = pg_catalog.clock_timestamp() - interval '1 second' WHERE id = :'jeton6'::uuid;
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k6', :'jeton6', :'code6')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur": "expiree"}'::jsonb
                    AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note = 'lent') = 0,
  '6p : un lot expire (cinq minutes) ne s''execute pas, meme avec le bon code');
SELECT pg_temp.vrai(pg_temp.code_de(:'jeton6') IS NULL, '6q : un lot expire n''est plus montre a la direction');

-- Lot altere : l'empreinte.
SELECT pg_temp.cle(7, 'chat') AS k7 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "vrai"}]''::jsonb)', :'k7')) ->> 'jeton' AS jeton7 \gset
SELECT pg_temp.code_de(:'jeton7') AS code7 \gset
UPDATE private.praxis_confirmations SET lot = '[{"note": "TRUQUE"}]'::jsonb WHERE id = :'jeton7'::uuid;
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k7', :'jeton7', :'code7')) AS j7 \gset
SELECT pg_temp.vrai(:'j7'::jsonb = '{"erreur": "empreinte"}'::jsonb
                    AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note IN ('vrai', 'TRUQUE')) = 0
                    AND (SELECT etat = 'annulee' AND code IS NULL FROM private.praxis_confirmations WHERE id = :'jeton7'::uuid),
  '6r : un lot dont les parametres ne sont plus ceux de l''empreinte n''est PAS execute et est annule');

-- Annule par la direction.
SELECT pg_temp.cle(8, 'chat') AS k8 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "annule"}]''::jsonb)', :'k8')) ->> 'jeton' AS jeton8 \gset
SELECT pg_temp.code_de(:'jeton8') AS code8 \gset
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal1', pg_catalog.format('SELECT public.direction_praxis_confirmation_annuler(%L::uuid)', :'jeton8'), '42501', '6s : annuler exige aal2');
SELECT pg_temp.vrai(pg_temp.appel(pg_temp.u(2), 'admin', 'aal2', pg_catalog.format('SELECT public.direction_praxis_confirmation_annuler(%L::uuid)', :'jeton8')) = '{"annule": false}'::jsonb,
  '6t : une autre direction ne peut pas annuler le lot de l''emettrice');
SELECT pg_temp.vrai(pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', pg_catalog.format('SELECT public.direction_praxis_confirmation_annuler(%L::uuid)', :'jeton8')) = '{"annule": true}'::jsonb,
  '6u : l''emettrice annule son lot');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k8', :'jeton8', :'code8')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur": "annulee"}'::jsonb
                    AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note = 'annule') = 0, '6v : un lot annule ne s''execute pas, meme avec le bon code');

-- Echec partiel : la ligne du milieu echoue a l'execution (pas a sec).
SELECT pg_temp.cle(9, 'chat') AS k9 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "p1"}, {"note": "p2", "boom_reel": "oui"}, {"note": "p3"}]''::jsonb)', :'k9')) ->> 'jeton' AS jeton9 \gset
SELECT pg_temp.code_de(:'jeton9') AS code9 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k9', :'jeton9', :'code9')) AS j9 \gset
SELECT pg_temp.vrai((:'j9'::jsonb ->> 'reussis')::int = 2 AND (:'j9'::jsonb -> 'resultats' -> 1 ->> 'ok')::boolean IS FALSE
                    AND :'j9'::jsonb -> 'resultats' -> 1 ->> 'code' = 'P0001'
                    AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note IN ('p1', 'p3')) = 2
                    AND (SELECT pg_catalog.count(*) FROM public.px_bd0_trace WHERE note = 'p2') = 0,
  '6w : un echec au milieu du lot n''empeche pas les autres lignes et n''ecrit rien pour la sienne ; chaque ligne rend son resultat');

-- ===================================================================================================
-- 7. Les plafonds.
-- ===================================================================================================
SELECT pg_temp.cle(10, 'chat') AS k10 \gset
INSERT INTO private.praxis_executions (cle_id, emetteur, acte, niveau, ok)
SELECT c.id, pg_temp.u(1), 'test_s', 'S', true FROM private.praxis_cles c, generate_series(1, 8) WHERE c.libelle = 'Cle d''essai 10';
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "1"}, {"note": "2"}, {"note": "3"}]''::jsonb)', :'k10'))
                    = '{"erreur": "plafond_actes"}'::jsonb, '7a : huit actes S dans l''heure + un lot de trois depasse dix : refuse DES la preparation (aucun code montre)');
SELECT pg_temp.vrai((pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "1"}, {"note": "2"}]''::jsonb)', :'k10')) ->> 'ok')::boolean,
  '7b : huit + deux font dix : permis');
-- Cinq lots en attente au plus.
SELECT pg_temp.cle(11, 'chat') AS k11 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "q"}]''::jsonb)', :'k11')) FROM generate_series(1, 5);
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''test_s'', ''[{"note": "q"}]''::jsonb)', :'k11')) = '{"erreur": "trop_en_attente"}'::jsonb,
  '7c : un sixieme lot en attente est refuse');

-- ===================================================================================================
-- 8. Le pont : aucun role client ; jamais l'identite d'un compte qui n'est pas une direction active.
-- ===================================================================================================
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege(r, 'private.praxis_executer_acte(uuid, uuid, text, jsonb, text, boolean)', 'EXECUTE')
                    AND NOT pg_catalog.has_function_privilege(r, 'private.praxis_identite(uuid, text)', 'EXECUTE'),
  '8a : ni le pont ni le fabricant d''identite ne sont executables par ' || r)
  FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r;
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2',
  pg_catalog.format('SELECT private.praxis_executer_acte(%L::uuid, %L::uuid, ''test_a'', ''{"note": "x"}''::jsonb, ''aal2'', false)', pg_temp.idem(1), pg_temp.u(1)),
  '42501', '8b : une direction elle-meme ne peut pas appeler le pont');
SELECT pg_temp.vrai(private.praxis_identite(pg_temp.u(1), 'aal2') ->> 'sub' = pg_temp.u(1)::text
                    AND private.praxis_identite(pg_temp.u(1), 'aal2') -> 'app_metadata' ->> 'role' = 'admin'
                    AND private.praxis_identite(pg_temp.u(1), 'aal2') ->> 'via' = 'praxis', '8c : l''identite d''une direction active est fabriquee, marquee « praxis »');
SELECT pg_temp.vrai(private.praxis_identite(pg_temp.u(3), 'aal2') IS NULL, '8d : jamais l''identite d''un enseignant');
SELECT pg_temp.vrai(private.praxis_identite(pg_temp.u(4), 'aal2') IS NULL, '8e : jamais l''identite d''une direction suspendue');
SELECT pg_temp.vrai(private.praxis_identite(pg_temp.u(1), 'aal3') IS NULL AND private.praxis_identite(pg_temp.u(1), NULL) IS NULL,
  '8f : le niveau d''authentification est aal1 ou aal2, rien d''autre');
SELECT pg_temp.vrai(private.praxis_identite(pg_temp.idem(1), 'aal2') IS NULL, '8g : un compte inconnu n''a pas d''identite');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p WHERE p.pronamespace = 'private'::regnamespace
                      AND p.proname = 'praxis_executer_acte' AND p.prosrc ~* 'EXECUTE\s') = 0, '8h : aucun SQL dynamique dans le pont (R1) : branchement statique');
SELECT pg_temp.vrai(pg_catalog.has_table_privilege(r, t, 'SELECT') IS FALSE AND pg_catalog.has_table_privilege(r, t, 'INSERT') IS FALSE
                    AND pg_catalog.has_table_privilege(r, t, 'UPDATE') IS FALSE,
  '8i : aucun role client ne touche ' || t || ' (' || r || ')')
  FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r,
       unnest(ARRAY['private.praxis_actes', 'private.praxis_confirmations', 'private.praxis_executions']) t;
SELECT pg_temp.vrai((SELECT pg_catalog.bool_and(c.relrowsecurity) FROM pg_catalog.pg_class c
                      WHERE c.oid IN ('private.praxis_actes'::regclass, 'private.praxis_confirmations'::regclass, 'private.praxis_executions'::regclass)),
  '8j : la securite par ligne est active sur les trois tables');

ROLLBACK;
\o
SELECT 'PX-BD-0 : tous les scenarios sont verts' AS resultat;
