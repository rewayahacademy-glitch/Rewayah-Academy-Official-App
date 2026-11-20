-- PX-OAUTH 2b : la partie SQL du serveur d'autorisation de Praxis (docs/current/BUREAU-EQUIPE/PRAXIS/PLAN-OAUTH.md). Un scenario par
-- regle du plan : droits, enregistrement borne, demande a rappel exact et PKCE, decision de la direction (aal2), echange d'un code a usage
-- unique, rotation du renouvellement, rejeu = revocation de la connexion, revocation d'une cle = revocation de la connexion, emetteur qui
-- cesse d'etre direction, 401 par praxis_cle_valide, audit sans secret. A rejouer sur une base NEUVE. Annule tout a la fin.
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

-- ============ Droits ============
SELECT pg_temp.vrai(
  (SELECT bool_and(has_function_privilege('service_role', p.oid, 'EXECUTE') AND NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                   AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE') AND NOT has_function_privilege('agent_ro', p.oid, 'EXECUTE'))
     FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname IN
       ('praxis_oauth_enregistrer', 'praxis_oauth_demander', 'praxis_oauth_echanger', 'praxis_oauth_renouveler', 'praxis_cle_valide'))
  AND (SELECT bool_and(has_function_privilege('authenticated', p.oid, 'EXECUTE') AND NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('service_role', p.oid, 'EXECUTE'))
     FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname IN ('direction_praxis_oauth_lire', 'direction_praxis_oauth_decider'))
  AND NOT EXISTS (SELECT 1 FROM pg_proc p WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'praxis\_oauth\_%'
                    AND (has_function_privilege('anon', p.oid, 'EXECUTE') OR has_function_privilege('authenticated', p.oid, 'EXECUTE')
                         OR has_function_privilege('service_role', p.oid, 'EXECUTE') OR has_function_privilege('agent_ro', p.oid, 'EXECUTE')))
  AND NOT EXISTS (SELECT 1 FROM information_schema.table_privileges t WHERE t.table_schema = 'private' AND t.table_name LIKE 'praxis\_oauth\_%'
                    AND t.grantee IN ('anon', 'authenticated', 'service_role', 'agent_ro', 'PUBLIC')),
  'OAUTH-1 : les cinq fonctions du serveur sont a service_role seul, les deux portes de la page de consentement a authenticated seul, les aides et les trois tables n''ont aucun droit');
SELECT pg_temp.vrai((SELECT bool_and(c.relrowsecurity) FROM pg_class c WHERE c.relnamespace = 'private'::regnamespace AND c.relname LIKE 'praxis\_oauth\_%' AND c.relkind = 'r'),
  'OAUTH-1 : les trois tables praxis_oauth_* ont la RLS activee');

-- ============ Enregistrement (DCR) ============
SELECT pg_temp.vrai(pg_temp.cl() ~ '^prxc_[0-9a-f]{32}$' AND (SELECT count(*) FROM private.praxis_oauth_clients) = 1,
  'OAUTH-2 : un client enregistre a un identifiant prxc_ + 32 hex, rien d''autre n''est cree');
SELECT pg_temp.garde('e1', pg_temp.srv($$SELECT public.praxis_oauth_enregistrer('Pirate', ARRAY['https://evil.example/cb'])$$));
SELECT pg_temp.garde('e2', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_enregistrer(%L, ARRAY[%L, %L])', 'Mixte', pg_temp.rap(), 'http://claude.ai/api/mcp/auth_callback')));
SELECT pg_temp.garde('e3', pg_temp.srv($$SELECT public.praxis_oauth_enregistrer('   ', ARRAY['https://claude.ai/api/mcp/auth_callback'])$$));
SELECT pg_temp.garde('e4', pg_temp.srv($$SELECT public.praxis_oauth_enregistrer('X', ARRAY[]::text[])$$));
SELECT pg_temp.vrai(pg_temp.lu('e1') = '{"erreur":"invalid_redirect_uri"}'::jsonb AND pg_temp.lu('e2') = '{"erreur":"invalid_redirect_uri"}'::jsonb
  AND pg_temp.lu('e3') = '{"erreur":"invalid_client_metadata"}'::jsonb AND pg_temp.lu('e4') = '{"erreur":"invalid_client_metadata"}'::jsonb
  AND (SELECT count(*) FROM private.praxis_oauth_clients) = 1,
  'OAUTH-2 : un rappel hors liste blanche (meme parmi d''autres), un nom vide, aucun rappel : refuses, aucun client cree');
-- Debit : au plus 10 clients par heure.
DO $$ BEGIN FOR i IN 1..12 LOOP PERFORM pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_enregistrer(%L, ARRAY[%L])', 'C' || i, pg_temp.rap())); END LOOP; END $$;
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_oauth_clients) = 10
  AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_enregistrer(%L, ARRAY[%L])', 'Trop', pg_temp.rap())) = '{"erreur":"debit"}'::jsonb,
  'OAUTH-2 : au plus dix clients par heure (le onzieme est refuse « debit », rien d''ecrit)');

-- ============ Demande d'autorisation ============
SELECT pg_temp.garde('d1', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_demander(%L, %L, %L, %L, NULL, NULL)', 'prxc_' || repeat('0', 32), pg_temp.rap(), pg_temp.ch(pg_temp.verif()), 'S256')));
SELECT pg_temp.garde('d2', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_demander(%L, %L, %L, %L, NULL, NULL)', pg_temp.cl(), 'https://claude.ai/api/mcp/auth_callback/', pg_temp.ch(pg_temp.verif()), 'S256')));
SELECT pg_temp.garde('d3', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_demander(%L, %L, %L, %L, NULL, NULL)', pg_temp.cl(), pg_temp.rap(), pg_temp.ch(pg_temp.verif()), 'plain')));
SELECT pg_temp.garde('d4', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_demander(%L, %L, %L, %L, NULL, NULL)', pg_temp.cl(), pg_temp.rap(), 'trop-court', 'S256')));
SELECT pg_temp.vrai(pg_temp.lu('d1') = '{"erreur":"client_inconnu"}'::jsonb AND pg_temp.lu('d2') = '{"erreur":"redirect_invalide"}'::jsonb
  AND pg_temp.lu('d3') = '{"erreur":"requete_invalide"}'::jsonb AND pg_temp.lu('d4') = '{"erreur":"requete_invalide"}'::jsonb
  AND (SELECT count(*) FROM private.praxis_oauth_demandes) = 0,
  'OAUTH-3 : client inconnu, rappel different d''un seul caractere, methode plain, challenge mal forme : refuses, aucune demande creee');
SELECT pg_temp.garde('d5', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_demander(%L, %L, %L, %L, %L, %L)', pg_temp.cl(), pg_temp.rap(), pg_temp.ch(pg_temp.verif()), 'S256', 'x', 'praxis admin inconnu')));
SELECT pg_temp.vrai(pg_temp.lu('d5') ? 'demande' AND (SELECT scope FROM private.praxis_oauth_demandes) = 'praxis'
  AND (SELECT abs(extract(epoch FROM expire_le - cree_le) - 600) < 2 FROM private.praxis_oauth_demandes) AND (SELECT accordee FROM private.praxis_oauth_demandes) IS NULL,
  'OAUTH-3 : une demande valable dure dix minutes, ne garde que les scopes connus, n''est ni accordee ni refusee');

-- ============ Page de consentement : la direction, avec la double verification ============
SELECT pg_temp.garde('dm', (SELECT to_jsonb(d.id) FROM private.praxis_oauth_demandes d));
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', pg_catalog.format('SELECT public.direction_praxis_oauth_lire(%L::uuid)', pg_temp.lu('dm') #>> '{}'), '42501',
  'OAUTH-4 : un tuteur ne lit pas une demande (42501)');
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, true)', pg_temp.lu('dm') #>> '{}'), '42501',
  'OAUTH-4 : un tuteur ne decide pas (42501)');
SELECT pg_temp.refus_en(NULL, NULL, pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, true)', pg_temp.lu('dm') #>> '{}'), '42501',
  'OAUTH-4 : anonyme : refus (42501)', 'anon');
SELECT pg_temp.vrai((SELECT decidee_le IS NULL AND code_empreinte IS NULL FROM private.praxis_oauth_demandes), 'OAUTH-4 : les refus n''ont rien decide');
-- Sans double verification : `qui` met aal2 par defaut, on le baisse ici explicitement.
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
  BEGIN PERFORM pg_temp.en_aal1(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, true)', pg_catalog.current_setting('test.dm')::jsonb #>> '{}'));
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true; END;
  IF NOT v_ok THEN RAISE EXCEPTION 'PRAXIS ROUGE : OAUTH-4 : aal1 : aucun refus'; END IF;
  RAISE NOTICE 'OK OAUTH-4 : la direction en aal1 est refusee (42501)';
END $$;
SELECT pg_temp.garde('l1', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_lire(%L::uuid)', pg_temp.lu('dm') #>> '{}')));
SELECT pg_temp.vrai(pg_temp.lu('l1') ->> 'etat' = 'en_attente' AND pg_temp.lu('l1') ->> 'client' = 'Claude' AND pg_temp.lu('l1') ->> 'hote' = 'claude.ai'
  AND (pg_temp.lu('l1') ->> 'peutAutoriser')::boolean AND NOT (pg_temp.lu('l1')::text ~* 'code|challenge|empreinte'),
  'OAUTH-4 : la direction lit une demande en attente (client, hote, droit), sans code ni challenge');
SELECT pg_temp.garde('l2', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_oauth_lire('00000000-0000-4000-8000-000000000000'::uuid)$$));
SELECT pg_temp.vrai(pg_temp.lu('l2') = '{"etat":"inconnue"}'::jsonb, 'OAUTH-4 : une demande inconnue est dite « inconnue »');

-- Refuser : la redirection porte access_denied et l'etat, jamais de code.
SELECT pg_temp.garde('r1', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, false)', pg_temp.lu('dm') #>> '{}')));
SELECT pg_temp.vrai(pg_temp.lu('r1') ->> 'redirection' = 'https://claude.ai/api/mcp/auth_callback?error=access_denied&state=x'
  AND (SELECT accordee = false AND code_empreinte IS NULL FROM private.praxis_oauth_demandes WHERE id = (pg_temp.lu('dm') #>> '{}')::uuid),
  'OAUTH-5 : refuser rend access_denied et l''etat, ne cree aucun code');
SELECT pg_temp.garde('r2', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, true)', pg_temp.lu('dm') #>> '{}')));
SELECT pg_temp.vrai(pg_temp.lu('r2') = '{"erreur":"deja_decidee"}'::jsonb AND (SELECT code_empreinte IS NULL FROM private.praxis_oauth_demandes WHERE id = (pg_temp.lu('dm') #>> '{}')::uuid),
  'OAUTH-5 : une demande deja decidee ne se rouvre pas (rejeu de la decision refuse)');
-- Expiree.
INSERT INTO private.praxis_oauth_demandes (client_id, rappel, code_challenge, etat, scope, expire_le)
  VALUES (pg_temp.cl(), pg_temp.rap(), pg_temp.ch(pg_temp.verif()), NULL, 'praxis', pg_catalog.clock_timestamp() - interval '1 minute');
SELECT pg_temp.garde('x1', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT public.direction_praxis_oauth_decider(%L::uuid, true)',
   (SELECT id FROM private.praxis_oauth_demandes WHERE expire_le < pg_catalog.clock_timestamp()))));
SELECT pg_temp.vrai(pg_temp.lu('x1') = '{"erreur":"expiree"}'::jsonb, 'OAUTH-5 : une demande expiree ne s''accorde pas');

-- La direction femme n'a que son cote : elle peut autoriser (au moins un cote) ; sans cote, « sans_cote ».
SELECT pg_temp.vrai(pg_temp.code_de(pg_temp.u('2')) ~ '^[0-9a-f]{64}$', 'OAUTH-5 : la direction a un cote : accorder rend un code de 64 hex');
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_oauth_demandes WHERE code_empreinte IS NOT NULL) = 1
  AND NOT EXISTS (SELECT 1 FROM private.praxis_oauth_demandes WHERE code_empreinte ~ '^[0-9a-f]{64}$' AND code_empreinte = (SELECT code_empreinte FROM private.praxis_oauth_demandes ORDER BY cree_le DESC LIMIT 1) AND false),
  'OAUTH-5 : seul le condense du code est garde (le code lui-meme n''est dans aucune colonne)');

-- ============ Echange du code ============
SELECT pg_catalog.set_config('test.code1', pg_temp.code_de(pg_temp.u('1')), true);
CREATE FUNCTION pg_temp.code1() RETURNS text LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.code1') $$;
GRANT EXECUTE ON FUNCTION pg_temp.code1() TO authenticated, anon, service_role;
SELECT pg_temp.garde('t0', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_temp.code1(), pg_temp.rap(), repeat('b', 43))));
SELECT pg_temp.garde('t0b', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_temp.code1(), pg_temp.rap(), pg_temp.verif())));
SELECT pg_temp.vrai(pg_temp.lu('t0') = '{"erreur":"invalid_grant"}'::jsonb AND pg_temp.lu('t0b') = '{"erreur":"invalid_grant"}'::jsonb
  AND (SELECT count(*) FROM private.praxis_oauth_connexions) = 0,
  'OAUTH-6 : un mauvais verifier est refuse ET brule le code (le bon verifier echoue ensuite) : aucune connexion creee');
SELECT pg_catalog.set_config('test.code2', pg_temp.code_de(pg_temp.u('1')), true);
CREATE FUNCTION pg_temp.code2() RETURNS text LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.code2') $$;
GRANT EXECUTE ON FUNCTION pg_temp.code2() TO authenticated, anon, service_role;
SELECT pg_temp.garde('t1', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', 'prxc_' || repeat('0', 32), pg_temp.code2(), pg_temp.rap(), pg_temp.verif())));
SELECT pg_catalog.set_config('test.code3', pg_temp.code_de(pg_temp.u('1')), true);
CREATE FUNCTION pg_temp.code3() RETURNS text LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.code3') $$;
GRANT EXECUTE ON FUNCTION pg_temp.code3() TO authenticated, anon, service_role;
SELECT pg_temp.garde('t2', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_temp.code3(), 'https://claude.ai/autre', pg_temp.verif())));
SELECT pg_temp.vrai(pg_temp.lu('t1') = '{"erreur":"invalid_grant"}'::jsonb AND pg_temp.lu('t2') = '{"erreur":"invalid_grant"}'::jsonb
  AND (SELECT count(*) FROM private.praxis_oauth_connexions) = 0,
  'OAUTH-6 : un autre client, un autre rappel : refuses (le code est lie au client et au rappel)');
-- Code expire.
SELECT pg_catalog.set_config('test.code4', pg_temp.code_de(pg_temp.u('1')), true);
UPDATE private.praxis_oauth_demandes SET code_expire_le = pg_catalog.clock_timestamp() - interval '1 second'
 WHERE code_empreinte = private.praxis_empreinte(pg_catalog.current_setting('test.code4'));
SELECT pg_temp.garde('t3', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_catalog.current_setting('test.code4'), pg_temp.rap(), pg_temp.verif())));
SELECT pg_temp.vrai(pg_temp.lu('t3') = '{"erreur":"invalid_grant"}'::jsonb AND (SELECT count(*) FROM private.praxis_oauth_connexions) = 0, 'OAUTH-6 : un code de plus de dix minutes est refuse');
-- Formes invalides : invalid_request, rien ne bouge.
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), 'pas-un-code', pg_temp.rap(), pg_temp.verif())) = '{"erreur":"invalid_request"}'::jsonb,
  'OAUTH-6 : un code de forme invalide est « invalid_request »');

-- Le bon echange.
SELECT pg_catalog.set_config('test.code5', pg_temp.code_de(pg_temp.u('1')), true);
SELECT pg_temp.garde('ok', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_catalog.current_setting('test.code5'), pg_temp.rap(), pg_temp.verif())));
SELECT pg_temp.vrai(pg_temp.lu('ok') ->> 'access_token' ~ '^prx_[0-9a-f]{64}$' AND pg_temp.lu('ok') ->> 'refresh_token' ~ '^prxr_[0-9a-f]{64}$'
  AND pg_temp.lu('ok') ->> 'token_type' = 'Bearer' AND (pg_temp.lu('ok') ->> 'expires_in')::int = 3600
  AND (SELECT count(*) FROM private.praxis_oauth_connexions) = 1
  AND (SELECT count(*) FROM private.praxis_cles WHERE connexion_id IS NOT NULL) = 1,
  'OAUTH-7 : un bon echange rend une cle prx_ d''une heure, un jeton de renouvellement prxr_, et cree UNE connexion et UNE cle');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM private.praxis_cles WHERE empreinte = pg_temp.lu('ok') ->> 'access_token')
  AND NOT EXISTS (SELECT 1 FROM private.praxis_oauth_connexions WHERE refresh_empreinte = pg_temp.lu('ok') ->> 'refresh_token')
  AND (SELECT refresh_empreinte ~ '^[0-9a-f]{64}$' FROM private.praxis_oauth_connexions),
  'OAUTH-7 : seules les empreintes sha256 sont gardees (ni la cle d''acces ni le renouvellement ne sont dans une colonne)');
SELECT pg_temp.vrai((SELECT usage = 'chat' AND expire_le <= pg_catalog.clock_timestamp() + interval '1 hour 1 minute' AND emise_par = pg_temp.u('1') AND revoquee_le IS NULL FROM private.praxis_cles WHERE connexion_id IS NOT NULL)
  AND (SELECT refresh_expire_le <= pg_catalog.clock_timestamp() + interval '30 days 1 minute' AND absolue_expire_le <= pg_catalog.clock_timestamp() + interval '90 days 1 minute' FROM private.praxis_oauth_connexions),
  'OAUTH-7 : usage chat, une heure, emise par la direction qui a approuve ; renouvellement 30 jours, connexion 90 jours au plus');
-- La cle d'acces est une cle Praxis ordinaire : l'outil l'accepte, et praxis_cle_valide dit vrai.
SELECT pg_temp.garde('et', pg_temp.srv(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.lu('ok') ->> 'access_token')));
SELECT pg_temp.vrai(NOT (pg_temp.lu('et') ? 'erreur') AND (pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('ok') ->> 'access_token'))) = 'true'::jsonb,
  'OAUTH-7 : la cle d''acces ouvre praxis_etat (une cle Praxis ordinaire) et praxis_cle_valide dit vrai');
SELECT pg_temp.vrai(pg_temp.srv($$SELECT to_jsonb(public.praxis_cle_valide('prx_' || repeat('0', 64)))$$) = 'false'::jsonb
  AND pg_temp.srv($$SELECT to_jsonb(public.praxis_cle_valide('n''importe quoi'))$$) = 'false'::jsonb
  AND pg_temp.srv($$SELECT to_jsonb(public.praxis_cle_valide(NULL))$$) = 'false'::jsonb,
  'OAUTH-7 : une cle inconnue, mal formee ou nulle : praxis_cle_valide dit faux (praxis-mcp rendra 401)');

-- Rejeu du code : refuse ET la connexion qu'il avait creee est revoquee, avec ses cles.
SELECT pg_temp.garde('rj', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_catalog.current_setting('test.code5'), pg_temp.rap(), pg_temp.verif())));
SELECT pg_temp.vrai(pg_temp.lu('rj') = '{"erreur":"invalid_grant"}'::jsonb
  AND (SELECT revoquee_le IS NOT NULL FROM private.praxis_oauth_connexions)
  AND (SELECT bool_and(revoquee_le IS NOT NULL) FROM private.praxis_cles WHERE connexion_id IS NOT NULL)
  AND pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('ok') ->> 'access_token')) = 'false'::jsonb,
  'OAUTH-8 : un code rejoue est refuse, la connexion qu''il avait creee et sa cle sont revoquees (le vol d''un code se paie)');

-- ============ Renouvellement ============
SELECT pg_catalog.set_config('test.c6', pg_temp.code_de(pg_temp.u('1')), true);
SELECT pg_temp.garde('b', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), pg_catalog.current_setting('test.c6'), pg_temp.rap(), pg_temp.verif())));
SELECT pg_temp.garde('rn', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('b') ->> 'refresh_token')));
SELECT pg_temp.vrai(pg_temp.lu('rn') ->> 'refresh_token' ~ '^prxr_[0-9a-f]{64}$' AND pg_temp.lu('rn') ->> 'refresh_token' <> pg_temp.lu('b') ->> 'refresh_token'
  AND pg_temp.lu('rn') ->> 'access_token' ~ '^prx_[0-9a-f]{64}$' AND pg_temp.lu('rn') ->> 'access_token' <> pg_temp.lu('b') ->> 'access_token'
  AND (SELECT count(*) FROM private.praxis_cles k WHERE k.connexion_id = (SELECT id FROM private.praxis_oauth_connexions WHERE revoquee_le IS NULL)) = 2
  AND (SELECT count(*) FROM private.praxis_oauth_connexions WHERE revoquee_le IS NULL) = 1,
  'OAUTH-9 : le renouvellement fait tourner le jeton (un nouveau, jamais le meme), emet une nouvelle cle ; la connexion reste UNE');
SELECT pg_temp.vrai((SELECT derniere_utilisation_le IS NOT NULL AND refresh_expire_le <= absolue_expire_le FROM private.praxis_oauth_connexions WHERE revoquee_le IS NULL),
  'OAUTH-9 : la derniere utilisation est notee ; le glissement de 30 jours ne depasse jamais les 90 jours de la connexion');
-- Mauvais client : refus, la connexion reste vivante.
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', (SELECT client_id FROM private.praxis_oauth_clients WHERE client_id <> pg_temp.cl() LIMIT 1), pg_temp.lu('rn') ->> 'refresh_token')) = '{"erreur":"invalid_grant"}'::jsonb
  AND (SELECT revoquee_le IS NULL FROM private.praxis_oauth_connexions WHERE refresh_empreinte = private.praxis_empreinte(pg_temp.lu('rn') ->> 'refresh_token')),
  'OAUTH-9 : un autre client ne peut pas renouveler (le jeton est lie a son client) ; la connexion reste vivante');
-- Rejeu de l'ancien renouvellement : toute la connexion est revoquee.
SELECT pg_temp.garde('rj2', pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('b') ->> 'refresh_token')));
SELECT pg_temp.vrai(pg_temp.lu('rj2') = '{"erreur":"invalid_grant"}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM private.praxis_oauth_connexions c WHERE c.id = (SELECT connexion_id FROM private.praxis_cles WHERE empreinte = private.praxis_empreinte(pg_temp.lu('rn') ->> 'access_token')) AND c.revoquee_le IS NULL)
  AND pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('rn') ->> 'access_token')) = 'false'::jsonb
  AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('rn') ->> 'refresh_token')) = '{"erreur":"invalid_grant"}'::jsonb,
  'OAUTH-9 : rejouer un ancien renouvellement revoque la connexion entiere : la cle courante et le jeton courant meurent aussi');

-- ============ Revocation par la direction, emetteur, expirations ============
CREATE FUNCTION pg_temp.neuve(p_admin uuid) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v_code text;
BEGIN
  v_code := pg_temp.code_de(p_admin);
  RETURN pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_echanger(%L, %L, %L, %L)', pg_temp.cl(), v_code, pg_temp.rap(), pg_temp.verif()));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.neuve(uuid) TO authenticated, anon, service_role;
SELECT pg_temp.garde('n1', pg_temp.neuve(pg_temp.u('1')));
SELECT pg_temp.garde('n1id', (SELECT to_jsonb(k.id) FROM private.praxis_cles k WHERE k.empreinte = private.praxis_empreinte(pg_temp.lu('n1') ->> 'access_token')));
SELECT pg_temp.garde('rv', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format('SELECT to_jsonb(public.direction_praxis_revoquer_cle(%L::uuid, %L, %L::uuid))', pg_temp.lu('n1id') #>> '{}', 'plus utile', gen_random_uuid())));
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('n1') ->> 'access_token')) = 'false'::jsonb
  AND (SELECT revoquee_le IS NOT NULL AND motif_revocation = 'plus utile' FROM private.praxis_oauth_connexions WHERE id = (SELECT connexion_id FROM private.praxis_cles WHERE id = (pg_temp.lu('n1id') #>> '{}')::uuid))
  AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('n1') ->> 'refresh_token')) = '{"erreur":"invalid_grant"}'::jsonb,
  'OAUTH-10 : revoquer la cle d''une connexion revoque la connexion : le jeton de renouvellement ne marche plus (le client ne se reconnecte pas tout seul)');
-- Une cle ordinaire (hors connexion) se revoque comme avant : la cascade ne la touche pas.
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_cles WHERE connexion_id IS NULL AND revoquee_le IS NOT NULL) = 0,
  'OAUTH-10 : aucune cle ordinaire n''a ete revoquee par la cascade');

-- L'emetteur cesse d'etre direction : plus de renouvellement, la cle courante est refusee (401).
SELECT pg_temp.garde('n2', pg_temp.neuve(pg_temp.u('2')));
UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('2');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('n2') ->> 'refresh_token')) = '{"erreur":"invalid_grant"}'::jsonb
  AND pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('n2') ->> 'access_token')) = 'false'::jsonb,
  'OAUTH-11 : un compte de direction desactive : le renouvellement est refuse et la cle courante est refusee (401)');
UPDATE public.profiles SET account_status = 'active' WHERE id = pg_temp.u('2');

-- Expirations : la connexion de 90 jours, la cle d'une heure.
SELECT pg_temp.garde('n3', pg_temp.neuve(pg_temp.u('1')));
UPDATE private.praxis_oauth_connexions SET cree_le = pg_catalog.clock_timestamp() - interval '100 days', absolue_expire_le = pg_catalog.clock_timestamp() - interval '10 days',
       refresh_expire_le = pg_catalog.clock_timestamp() - interval '10 days'
 WHERE id = (SELECT connexion_id FROM private.praxis_cles WHERE empreinte = private.praxis_empreinte(pg_temp.lu('n3') ->> 'access_token'));
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('n3') ->> 'refresh_token')) = '{"erreur":"invalid_grant"}'::jsonb,
  'OAUTH-12 : au bout des 90 jours, la connexion ne se renouvelle plus (il faut une nouvelle approbation)');
SELECT pg_temp.garde('n4', pg_temp.neuve(pg_temp.u('1')));
UPDATE private.praxis_cles SET emise_le = pg_catalog.clock_timestamp() - interval '2 hours', expire_le = pg_catalog.clock_timestamp() - interval '1 second' WHERE empreinte = private.praxis_empreinte(pg_temp.lu('n4') ->> 'access_token');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('n4') ->> 'access_token')) = 'false'::jsonb
  AND (pg_temp.srv(pg_catalog.format('SELECT public.praxis_oauth_renouveler(%L, %L)', pg_temp.cl(), pg_temp.lu('n4') ->> 'refresh_token'))) ? 'access_token',
  'OAUTH-12 : la cle expiree est refusee (401), mais le renouvellement en emet une neuve : c''est le chemin normal de claude.ai');

-- Interrupteur : ce n'est pas un probleme de jeton. praxis_cle_valide reste vrai, l'outil dit « eteint ».
SELECT pg_temp.garde('n5', pg_temp.neuve(pg_temp.u('1')));
SELECT pg_temp.garde('regle_off', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(false, false, NULL)$$));
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT to_jsonb(public.praxis_cle_valide(%L))', pg_temp.lu('n5') ->> 'access_token')) = 'true'::jsonb
  AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.lu('n5') ->> 'access_token')) ->> 'actif' = 'false'
  AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_ecrire(%L, %L::uuid, %L, %L::uuid)', pg_temp.lu('n5') ->> 'access_token', pg_temp.f('1'), 'Bonjour', pg_temp.idem('77'))) = '{"erreur":"eteint"}'::jsonb,
  'OAUTH-13 : Praxis eteint : la cle reste valide (pas de 401, pas de reconnexion), l''etat dit « inactif » et l''ecriture repond « eteint »');
SELECT pg_temp.garde('regle_on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));

-- ============ Audit : jamais de secret ============
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.audit_logs l
                                 WHERE l.action LIKE 'praxis\_oauth\_%'
                                   AND (l.payload::text ~* '(prx_|prxr_)[0-9a-f]{20}' OR l.payload::text ~ '[0-9a-f]{64}'))
  AND (SELECT count(*) FROM public.audit_logs WHERE action LIKE 'praxis\_oauth\_%') >= 4,
  'OAUTH-14 : l''audit note les connexions, decisions et rejeux, sans code, sans cle, sans renouvellement');

\o
SELECT 'PRAXIS OAUTH 2b : tous les scenarios sont verts' AS resultat;
ROLLBACK;
