-- PX-OAUTH 2e : la liste des connexions de claude.ai a Praxis et leur revocation. Un scenario par regle : droits, lecture (une ligne par
-- connexion, sans secret, etat de la base), revocation (aal2, motif, cascade sur les cles, rejeu sans effet, audit sans motif), et la liste
-- des cles (direction_praxis_etat) qui ne montre plus les cles nees d'une connexion. A rejouer sur une base NEUVE. Annule tout a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
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

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PRAXIS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

-- Un appel sous le role authenticated, au nom d'un compte.
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

-- Un appel qui doit etre refuse avec ce code.
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
    RAISE EXCEPTION 'PRAXIS ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'PRAXIS ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a130000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a13cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1a0000-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.h(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1affff-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.f(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1acccc-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1a1111-0000-4000-8000-' || lpad(p_n, 12, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.h(text), pg_temp.f(text), pg_temp.idem(text)
  TO authenticated, anon, service_role;

-- Un appel d'outil Praxis : le role service_role (le seul qui l'execute).
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.srv(text) TO authenticated, anon, service_role;

-- Fixtures (personnes fictives) : a1 direction homme, a2 direction femme, g1 a g6 tuteurs (un foyer chacun), s1 eleve
-- MINEUR du foyer 1, t1 enseignant.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'px-' || n || '@test.invalid' FROM generate_series(1, 20) n;
INSERT INTO public.households (id, timezone) SELECT pg_temp.h(n::text), 'Europe/Paris' FROM generate_series(1, 6) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'PX-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'PX-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('3'), 'PX-TUT-0001', 'guardian', pg_temp.h('1'), 'Tuteur', 'Un', 'active', 'female'),
 (pg_temp.u('4'), 'PX-TUT-0002', 'guardian', pg_temp.h('2'), 'Tuteur', 'Deux', 'active', 'male'),
 (pg_temp.u('5'), 'PX-TUT-0003', 'guardian', pg_temp.h('3'), 'Tuteur', 'Trois', 'active', 'female'),
 (pg_temp.u('6'), 'PX-TUT-0004', 'guardian', pg_temp.h('4'), 'Tuteur', 'Quatre', 'active', 'male'),
 (pg_temp.u('7'), 'PX-TUT-0005', 'guardian', pg_temp.h('5'), 'Tuteur', 'Cinq', 'active', 'female'),
 (pg_temp.u('8'), 'PX-TUT-0006', 'guardian', pg_temp.h('6'), 'Tuteur', 'Six', 'active', 'male'),
 (pg_temp.u('9'), 'PX-ELV-0001', 'student', pg_temp.h('1'), 'Eleve', 'Mineur', 'active', 'male'),
 (pg_temp.u('10'), 'PX-ENS-0001', 'teacher', NULL, 'Enseignant', 'Un', 'pending_kyc', 'male');
-- a1 est la super-administration (les deux cotes, AR-7 I2) ; a2 (femme) n'a que le sien.
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('1'));
INSERT INTO public.student_profiles (profile_id, student_type) VALUES (pg_temp.u('9'), 'minor');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status) VALUES (pg_temp.u('10'), 'SA', ARRAY[]::text[], 'pending');

-- Aides propres a ce scenario : le client enregistre, un verifier PKCE et son challenge (S256).
CREATE FUNCTION pg_temp.ch(p_verifier text) RETURNS text LANGUAGE sql AS $$
  SELECT private.praxis_oauth_b64url(pg_catalog.sha256(pg_catalog.convert_to(p_verifier, 'UTF8'))) $$;
GRANT EXECUTE ON FUNCTION pg_temp.ch(text) TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.verif() RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT repeat('a', 43) $$;
CREATE FUNCTION pg_temp.rap() RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT 'https://claude.ai/api/mcp/auth_callback' $$;
GRANT EXECUTE ON FUNCTION pg_temp.verif(), pg_temp.rap() TO authenticated, anon, service_role;
SELECT pg_catalog.set_config('test.cl', (pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_enregistrer(%L, ARRAY[%L])', 'Claude', pg_temp.rap())) ->> 'client_id'), true);
CREATE FUNCTION pg_temp.cl() RETURNS text LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.cl') $$;
GRANT EXECUTE ON FUNCTION pg_temp.cl() TO authenticated, anon, service_role;

-- Une demande decidee et acceptee par la direction : rend le code (extrait de la redirection).
CREATE FUNCTION pg_temp.code_de(p_admin uuid) RETURNS text LANGUAGE plpgsql AS $$
DECLARE v_d uuid; v_r jsonb;
BEGIN
  v_d := (pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_demander(%L, %L, %L, %L, %L, %L)',
          pg_temp.cl(), pg_temp.rap(), pg_temp.ch(pg_temp.verif()), 'S256', 'etat-1', 'praxis offline_access')) ->> 'demande')::uuid;
  v_r := pg_temp.en(p_admin, 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, true)', v_d));
  RETURN substring(v_r ->> 'redirection' FROM 'code=([0-9a-f]{64})');
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.code_de(uuid) TO authenticated, anon, service_role;


CREATE FUNCTION pg_temp.neuve(p_admin uuid) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v_code text;
BEGIN
  v_code := pg_temp.code_de(p_admin);
  RETURN pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), v_code, pg_temp.rap(), pg_temp.verif()));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.neuve(uuid) TO authenticated, anon, service_role;

-- ============ Droits ============
SELECT pg_temp.vrai(
  (SELECT bool_and(has_function_privilege('authenticated', p.oid, 'EXECUTE') AND NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                   AND NOT has_function_privilege('service_role', p.oid, 'EXECUTE') AND NOT has_function_privilege('agent_ro', p.oid, 'EXECUTE')
                   AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
     FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname IN ('direction_praxis_oauth_connexions', 'direction_praxis_oauth_revoquer')),
  'CONN-1 : les deux portes sont a authenticated seul (SECURITY DEFINER, search_path vide)');
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', $$SELECT public.direction_praxis_oauth_connexions()$$, '42501', 'CONN-1 : un tuteur ne lit pas les connexions (42501)');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.direction_praxis_oauth_connexions()$$, '42501', 'CONN-1 : anonyme : refus (42501)', 'anon');

-- ============ Lecture : une ligne par connexion ============
SELECT pg_temp.garde('vide', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_oauth_connexions()$$));
SELECT pg_temp.vrai(pg_temp.lu('vide') = '[]'::jsonb, 'CONN-2 : aucune connexion : une liste vide');
SELECT pg_temp.garde('n1', pg_temp.neuve(pg_temp.u('1')));
SELECT pg_temp.garde('r1', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('n1') ->> 'refresh_token')));
SELECT pg_temp.garde('r2', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('r1') ->> 'refresh_token')));
SELECT pg_temp.garde('liste', pg_temp.en(pg_temp.u('2'), 'admin', $$SELECT public.direction_praxis_oauth_connexions()$$));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('liste')) = 1
  AND (SELECT count(*) FROM private.praxis_cles WHERE connexion_id IS NOT NULL) = 3
  AND pg_temp.lu('liste') -> 0 ->> 'client' = 'Claude' AND pg_temp.lu('liste') -> 0 ->> 'etat' = 'active'
  AND pg_temp.lu('liste') -> 0 ->> 'revoqueeLe' IS NULL,
  'CONN-2 : une connexion renouvelee deux fois = UNE ligne (trois cles derriere), active, nom du client ; lisible par toute direction valide');
SELECT pg_temp.vrai(NOT (pg_temp.lu('liste')::text ~* '(prx_|prxr_)[0-9a-f]{20}|empreinte|refresh|[0-9a-f]{64}'),
  'CONN-2 : aucun secret, aucune empreinte, aucun jeton dans la liste');
SELECT pg_temp.vrai((pg_temp.lu('liste') -> 0 ->> 'derniereUtilisationLe') IS NOT NULL
  AND ((pg_temp.lu('liste') -> 0 ->> 'expireLe')::timestamptz - pg_catalog.clock_timestamp()) BETWEEN interval '89 days' AND interval '90 days 1 minute',
  'CONN-2 : la derniere utilisation est notee (renouvellement) ; le terme est celui des 90 jours');

-- ============ La liste des cles ne montre plus les cles nees d'une connexion ============
SELECT pg_temp.garde('cle_normale', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format(
  'SELECT public.direction_praxis_emettre_cle(%L, %L, %L::timestamptz, %L::uuid)', 'Conversation du directeur', 'chat',
  (pg_catalog.clock_timestamp() + interval '30 days')::text, gen_random_uuid())));
SELECT pg_temp.garde('etat', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_etat()$$));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('etat') -> 'cles') = 1
  AND pg_temp.lu('etat') -> 'cles' -> 0 ->> 'libelle' = 'Conversation du directeur'
  AND NOT (pg_temp.lu('etat')::text ~* 'Connexion claude'),
  'CONN-3 : direction_praxis_etat ne montre que la cle ordinaire : les trois cles d''une connexion n''y figurent pas');

-- ============ Revocation ============
SELECT pg_temp.garde('id', (SELECT to_jsonb(c.id) FROM private.praxis_oauth_connexions c));
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', pg_catalog.format('SELECT public.direction_praxis_oauth_revoquer(%L::uuid, ''x'')', pg_temp.lu('id') #>> '{}'), '42501',
  'CONN-4 : un tuteur ne revoque pas (42501)');
CREATE FUNCTION pg_temp.en_aal1(p_id uuid, p_role text, p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, 'aal1');
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.en_aal1(uuid, text, text) TO authenticated, anon, service_role;
DO $$ DECLARE v_ok boolean := false; BEGIN
  BEGIN PERFORM pg_temp.en_aal1(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT to_jsonb(public.direction_praxis_oauth_revoquer(%L::uuid, ''x''))', pg_catalog.current_setting('test.id')::jsonb #>> '{}'));
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true; END;
  IF NOT v_ok THEN RAISE EXCEPTION 'PRAXIS ROUGE : CONN-4 : aal1 : aucun refus'; END IF;
  RAISE NOTICE 'OK CONN-4 : la direction en aal1 ne revoque pas (42501)';
END $$;
SELECT pg_temp.vrai((SELECT revoquee_le IS NULL FROM private.praxis_oauth_connexions), 'CONN-4 : les refus n''ont rien revoque');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_revoquer(%L::uuid, ''   '')', pg_temp.lu('id') #>> '{}'), '22023',
  'CONN-4 : un motif vide est refuse (22023)');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_revoquer(%L::uuid, %L)', pg_temp.lu('id') #>> '{}', repeat('x', 241)), '22023',
  'CONN-4 : un motif de plus de 240 signes est refuse (22023)');
SELECT pg_temp.garde('rv', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT to_jsonb(public.direction_praxis_oauth_revoquer(%L::uuid, %L))', pg_temp.lu('id') #>> '{}', 'plus utilisee')));
SELECT pg_temp.vrai(pg_temp.lu('rv') = 'true'::jsonb
  AND (SELECT revoquee_le IS NOT NULL AND motif_revocation = 'plus utilisee' AND revoquee_par = pg_temp.u('1') FROM private.praxis_oauth_connexions)
  AND (SELECT bool_and(revoquee_le IS NOT NULL) FROM private.praxis_cles WHERE connexion_id IS NOT NULL)
  AND pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('r2') ->> 'access_token')) = 'false'::jsonb
  AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('r2') ->> 'refresh_token')) = '{"erreur":"invalid_grant"}'::jsonb,
  'CONN-4 : la revocation coupe la connexion, TOUTES ses cles, et le renouvellement (le client ne se reconnecte pas seul)');
SELECT pg_temp.vrai((SELECT revoquee_le IS NULL FROM private.praxis_cles WHERE connexion_id IS NULL),
  'CONN-4 : la cle ordinaire n''est pas touchee');
SELECT pg_temp.garde('rv2', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT to_jsonb(public.direction_praxis_oauth_revoquer(%L::uuid, %L))', pg_temp.lu('id') #>> '{}', 'encore')));
SELECT pg_temp.garde('rv3', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT to_jsonb(public.direction_praxis_oauth_revoquer('00000000-0000-4000-8000-000000000000'::uuid, 'x'))$$));
SELECT pg_temp.vrai(pg_temp.lu('rv2') = 'false'::jsonb AND pg_temp.lu('rv3') = 'false'::jsonb
  AND (SELECT motif_revocation = 'plus utilisee' FROM private.praxis_oauth_connexions),
  'CONN-4 : rejouer, ou une connexion inconnue, rend faux et ne change pas le motif d''origine');
SELECT pg_temp.garde('apres', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_oauth_connexions()$$));
SELECT pg_temp.vrai(pg_temp.lu('apres') -> 0 ->> 'etat' = 'revoquee' AND pg_temp.lu('apres') -> 0 ->> 'motifRevocation' = 'plus utilisee'
  AND (pg_temp.lu('apres') -> 0 ->> 'revoqueeLe') IS NOT NULL,
  'CONN-4 : la liste montre la connexion revoquee, avec son motif');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.audit_logs l WHERE l.action = 'praxis_oauth_revocation' AND l.payload::text ~ 'plus utilisee')
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_oauth_revocation') = 1,
  'CONN-5 : une ligne d''audit par revocation reelle (rien pour les rejeux), sans le motif');

-- Une connexion expiree se lit « expiree ».
SELECT pg_temp.garde('n2', pg_temp.neuve(pg_temp.u('1')));
UPDATE private.praxis_oauth_connexions SET cree_le = pg_catalog.clock_timestamp() - interval '100 days', absolue_expire_le = pg_catalog.clock_timestamp() - interval '10 days',
       refresh_expire_le = pg_catalog.clock_timestamp() - interval '10 days'
 WHERE revoquee_le IS NULL;
SELECT pg_temp.garde('fin', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_oauth_connexions()$$));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('fin')) = 2
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('fin')) e WHERE e ->> 'etat' = 'expiree') = 1
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('fin')) e WHERE e ->> 'etat' = 'revoquee') = 1,
  'CONN-2 : une connexion au terme de ses 90 jours se lit « expiree », une revoquee « revoquee » ; les plus recentes d''abord');

\o
SELECT 'PRAXIS OAUTH 2e : tous les scenarios sont verts' AS resultat;
ROLLBACK;
