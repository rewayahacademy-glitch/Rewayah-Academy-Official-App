-- PX-1 / SEC-1 : Praxis. UN SCENARIO PAR REGLE de docs/current/BUREAU-EQUIPE/PRAXIS/SECURITE-PRAXIS.md (R1 a R15), PAR POINT
-- du §3 (mineurs) et par arbitrage A-9, A-10, A-11. Chaque refus verifie l'etat de la base apres l'appel.
--   R1 aucune requete libre : les outils ne prennent que des parametres types et bornes (signatures, refus 'parametre') ;
--   R2 liste blanche exacte des fonctions praxis_* ; seul service_role les execute ;
--   R3 aucun jeton de personne : aucune identite de connexion, aucun courriel, compte desactive ;
--   R4 aucune fonction praxis_* n'ecrit hors de ses tables (liste positive) ;
--   R5 aucune reponse ne rend courriel, telephone, adresse, montant, piece, jeton, mot de passe, note ;
--   R6 enfants (§3, AR-3) ; R7 ecrire seulement dans un fil de l'academie ; R8 l'equipe reprend, Praxis se tait ;
--   R9 freins : interrupteur, plafond par heure et par fil, annonces par jour, idempotence, longueurs ;
--   R10 cles : empreinte seule, aal2, montrees une fois, expiration, revocation, chat / routine, aucune cle d'observation ;
--   R11 journal a ajout seul, sans texte de tiers ; R12 auteur = Praxis, aucun courriel ; R13 absent des listes nommees ;
--   A-11 aucun matricule, aucune notification, aucun courriel a la creation.
-- R14 et R15 sont des regles de PROCESSUS (aucun appel sur la production ; relecture du pilote) : voir la PR.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
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

-- Les fils : dossiers de tuteurs avec l'equipe (FA a FE, FG), un fil hors academie (FH), un fil de candidature (FK).
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id) VALUES
 (pg_temp.f('1'), 'dossier', pg_temp.u('3'), 'foyer', pg_temp.h('1'), 'equipe', NULL),
 (pg_temp.f('2'), 'dossier', pg_temp.u('4'), 'foyer', pg_temp.h('2'), 'equipe', NULL),
 (pg_temp.f('3'), 'dossier', pg_temp.u('5'), 'foyer', pg_temp.h('3'), 'equipe', NULL),
 (pg_temp.f('4'), 'dossier', pg_temp.u('6'), 'foyer', pg_temp.h('4'), 'equipe', NULL),
 (pg_temp.f('5'), 'dossier', pg_temp.u('7'), 'foyer', pg_temp.h('5'), 'equipe', NULL),
 (pg_temp.f('6'), 'dossier', pg_temp.u('8'), 'foyer', pg_temp.h('6'), 'equipe', NULL),
 (pg_temp.f('8'), 'eleve', pg_temp.u('9'), 'foyer', pg_temp.h('1'), 'profil', pg_temp.u('10')),
 (pg_temp.f('9'), 'candidature', pg_temp.u('99'), 'profil', pg_temp.u('5'), 'equipe', NULL);
CREATE FUNCTION pg_temp.msg(p_fil text, p_auteur text, p_texte text, p_n text) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
  VALUES (pg_temp.f(p_fil), pg_temp.u(p_auteur), pg_temp.idem(p_n), p_texte,
          pg_catalog.clock_timestamp() - interval '2 hours' + (p_n::int || ' seconds')::interval) $$;
CREATE FUNCTION pg_temp.msg_now(p_fil text, p_auteur text, p_texte text, p_n text) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
  VALUES (pg_temp.f(p_fil), pg_temp.u(p_auteur), pg_temp.idem(p_n), p_texte, pg_catalog.clock_timestamp() + interval '1 second') $$;
SELECT pg_temp.msg('1', '3', 'Bonjour, ou en est mon dossier ?', '1');
SELECT pg_temp.msg('2', '4', 'Bonjour, une question sur les horaires.', '2');
SELECT pg_temp.msg('3', '5', 'Bonjour, nous voulons un renseignement.', '3');
SELECT pg_temp.msg('4', '6', 'Bonjour, une question du foyer.', '4');
SELECT pg_temp.msg('5', '7', 'Bonjour, une demande generale.', '5');
SELECT pg_temp.msg('6', '8', 'Bonjour, une demande sur le calendrier.', '6');
SELECT pg_temp.msg('8', '3', 'Bonjour, a propos de la classe.', '7');
SELECT pg_temp.msg('9', '5', 'Bonjour, candidature.', '8');
-- Le fil 4 : un MINEUR y a ecrit (cas « un mineur rejoint le fil plus tard »).
SELECT pg_temp.msg('4', '9', 'Bonjour, c''est un enfant qui ecrit.', '9');

SELECT pg_temp.garde('nb0', to_jsonb((SELECT count(*) FROM public.com_messages)));
CREATE FUNCTION pg_temp.etat_fil(p_n text) RETURNS text LANGUAGE sql AS $$
  SELECT md5(coalesce((SELECT string_agg(m.id::text || m.texte, '|' ORDER BY m.id) FROM public.com_messages m
                        WHERE m.fil_id = pg_temp.f(p_n)), '')) $$;
CREATE FUNCTION pg_temp.nb_msg() RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM public.com_messages $$;
CREATE FUNCTION pg_temp.sensible(p_j jsonb) RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
  SELECT p_j::text ~* '(@|courriel|e-mail|email|phone|telephone|montant|birth|naissance|adresse|iban|token|jeton|password|mot_de_passe|secret|empreinte)' $$;

-- PX-2 : les donnees reelles sont ouvertes (la politique est publiee) : sans cela, PX-1 est limite au mode essai.
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- Les cles : emises par la direction (a1) en aal2. Le secret n'est montre qu'a l'emission.
SELECT pg_temp.vrai(NOT (SELECT actif FROM private.praxis_reglages)
  AND NOT EXISTS (SELECT 1 FROM private.praxis_cles),
  'R9 / R14 : praxis.actif est faux apres installation, et aucune cle n''existe');
SELECT pg_temp.garde('chat', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat du directeur', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000001'::uuid)$$));
SELECT pg_temp.garde('routine', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Routine du soir', 'routine', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000002'::uuid)$$));
CREATE FUNCTION pg_temp.k(p_nom text) RETURNS text LANGUAGE sql AS $$ SELECT pg_temp.lu(p_nom) ->> 'secret' $$;
CREATE FUNCTION pg_temp.q(p text) RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.quote_literal(p) $$;
CREATE FUNCTION pg_temp.ecrire(p_cle text, p_fil text, p_texte text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_ecrire(%L, %L::uuid, %L, %L::uuid)',
                                       p_cle, pg_temp.f(p_fil), p_texte, pg_temp.idem('50' || p_n))) $$;
CREATE FUNCTION pg_temp.outil(p_sql text) RETURNS jsonb LANGUAGE sql AS $$ SELECT pg_temp.srv(p_sql) $$;
GRANT EXECUTE ON FUNCTION pg_temp.k(text), pg_temp.q(text), pg_temp.ecrire(text, text, text, text),
  pg_temp.outil(text) TO authenticated, anon, service_role;

CREATE FUNCTION pg_temp.nb_identites() RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE n bigint := 0;
BEGIN
  IF to_regclass('auth.identities') IS NOT NULL THEN
    EXECUTE 'SELECT count(*) FROM auth.identities WHERE user_id = $1' INTO n USING private.praxis_profil();
  END IF;
  RETURN n;
END $$;

-- ============ A-11 : le compte officiel, sans parcours ============
SELECT pg_temp.vrai((SELECT account_status::text || '/' || role::text || '/' || immutable_id
                        FROM public.profiles WHERE id = private.praxis_profil()) = 'disabled/accountant/RA-OFFICIEL-PRAXIS'
  AND NOT EXISTS (SELECT 1 FROM private.person_registrations r WHERE r.profile_id = private.praxis_profil())
  AND (SELECT code FROM private.comptes_officiels WHERE profile_id = private.praxis_profil()) = 'praxis',
  'A-11 : le compte officiel existe (disabled, accountant, indicateur), sans matricule attribue');
SELECT pg_temp.vrai((SELECT email FROM auth.users WHERE id = private.praxis_profil()) IS NULL
  AND pg_temp.nb_identites() = 0,
  'R3 / A-11 : aucun courriel, aucune identite de connexion pour le compte officiel');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications n WHERE n.destinataire = private.praxis_profil())
  AND NOT EXISTS (SELECT 1 FROM public.courriels_sortants c WHERE c.destinataire_profil = private.praxis_profil()),
  'A-11 : aucune notification et aucun courriel pour le compte officiel apres sa creation');
SELECT pg_temp.vrai(NOT (SELECT autonome FROM private.praxis_reglages),
  'A-10 : praxis.autonome est faux apres installation');

-- ============ R10 : les cles ============
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle('x', 'chat',
  pg_catalog.now() + interval '91 days', '5c1a2222-0000-4000-8000-0000000000f1'::uuid)$$, '22023',
  'R10 : une cle n''expire jamais au-dela de 90 jours (91 refuses)');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle('x', 'chat', NULL,
  '5c1a2222-0000-4000-8000-0000000000f2'::uuid)$$, '22023', 'R10 : l''expiration est obligatoire');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle('x', 'autre',
  pg_catalog.now() + interval '10 days', '5c1a2222-0000-4000-8000-0000000000f3'::uuid)$$, '22023',
  'R10 : seuls les usages chat et routine existent');
-- Sans double verification (aal1) : refus. Un compte qui n'est pas la direction : refus.
CREATE FUNCTION pg_temp.en_aal1(p_id uuid, p_role text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, 'aal1');
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    EXECUTE 'RESET ROLE';
    RAISE EXCEPTION 'PRAXIS ROUGE : aucun refus sans aal2';
  EXCEPTION WHEN insufficient_privilege THEN
    EXECUTE 'RESET ROLE';
  END;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.en_aal1(uuid, text, text) TO authenticated, anon;
SELECT pg_temp.en_aal1(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle('x', 'chat',
  pg_catalog.now() + interval '10 days', '5c1a2222-0000-4000-8000-0000000000f4'::uuid)$$);
SELECT pg_temp.en_aal1(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, true, 10)$$);
SELECT pg_temp.en_aal1(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_revoquer_cle(
  '5c1a2222-0000-4000-8000-0000000000f5'::uuid, 'x', '5c1a2222-0000-4000-8000-0000000000f6'::uuid)$$);
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', $$SELECT public.direction_praxis_regler(true, true, 10)$$, '42501',
  'R10 : un tuteur ne regle rien (42501) ; les trois portes de la direction refusent sans aal2 (ci-dessus)');
SELECT pg_temp.vrai(pg_temp.k('chat') ~ '^prx_[0-9a-f]{64}$'
  AND (SELECT count(*) FROM private.praxis_cles) = 2
  AND NOT EXISTS (SELECT 1 FROM private.praxis_cles c WHERE c.empreinte = pg_temp.k('chat')
                    OR to_jsonb(c)::text LIKE '%' || pg_temp.k('chat') || '%')
  AND (SELECT empreinte FROM private.praxis_cles WHERE usage = 'chat') = private.praxis_empreinte(pg_temp.k('chat')),
  'R10 : seule l''empreinte sha256 est gardee (le secret n''est dans aucune colonne)');
SELECT pg_temp.garde('chat_rejeu', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat du directeur', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000001'::uuid)$$));
SELECT pg_temp.vrai(pg_temp.lu('chat_rejeu') ->> 'rejoue' = 'true' AND NOT (pg_temp.lu('chat_rejeu') ? 'secret')
  AND (SELECT count(*) FROM private.praxis_cles) = 2,
  'R10 : la cle n''est montree qu''une fois (le rejeu rend l''identifiant, jamais le secret)');

-- ============ R9 : l'interrupteur coupe tout (actif est faux) ============
SELECT pg_temp.garde('e_boite', pg_temp.outil(pg_catalog.format('SELECT public.praxis_boite(%L, ''attend'', 10)', pg_temp.k('chat'))));
SELECT pg_temp.garde('e_fil', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('1'))));
SELECT pg_temp.garde('e_ecrire', pg_temp.ecrire(pg_temp.k('chat'), '1', 'Bonjour', '1'));
SELECT pg_temp.garde('e_annoncer', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Titre'', ''Texte'', %L::uuid)', pg_temp.k('chat'), pg_temp.idem('60'))));
SELECT pg_temp.garde('e_etat', pg_temp.outil(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.k('chat'))));
SELECT pg_temp.vrai(pg_temp.lu('e_boite') = '{"erreur": "eteint"}'::jsonb AND pg_temp.lu('e_fil') = '{"erreur": "eteint"}'::jsonb
  AND pg_temp.lu('e_ecrire') = '{"erreur": "eteint"}'::jsonb AND pg_temp.lu('e_annoncer') = '{"erreur": "eteint"}'::jsonb
  AND pg_temp.lu('e_etat') ->> 'actif' = 'false' AND pg_temp.nb_msg() = (pg_temp.lu('nb0') #>> '{}')::bigint
  AND (SELECT count(*) FROM public.com_annonces) = 0,
  'R9 / A-10 : interrupteur coupe : boite, fil, ecrire et annoncer refuses (eteint), etat dit actif faux, rien d''ecrit');
SELECT pg_temp.garde('regle_on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));

-- ============ A-9 inverse : une cle Praxis (prx_) n'ouvre AUCUNE session d'agent ============
-- La seule porte qui fabrique une session d'agent (fonction Edge agent-session) appelle remettre_session_agent : la base la refuse.
CREATE FUNCTION pg_temp.agent_refuse(p_secret text) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE v_n integer;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  BEGIN
    SELECT count(*) INTO v_n FROM public.remettre_session_agent(p_secret);
    EXECUTE 'RESET ROLE';
    RETURN v_n = 0;
  EXCEPTION WHEN OTHERS THEN
    EXECUTE 'RESET ROLE';
    RETURN SQLERRM = 'jeton refuse';
  END;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.agent_refuse(text) TO authenticated, anon, service_role;
SELECT pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE proname = 'remettre_session_agent') = 1
  AND pg_temp.agent_refuse(pg_temp.k('chat')) AND pg_temp.agent_refuse(pg_temp.k('routine')),
  'A-9 inverse : remettre_session_agent (appelee par agent-session) refuse une cle prx_ (chat et routine) avec « jeton refuse » ; aucune session d''agent');

-- ============ R1, R10 : cle absente, fausse, d'observation, revoquee, expiree ============
SELECT pg_temp.garde('c_vide', pg_temp.ecrire('', '1', 'Bonjour', '2'));
SELECT pg_temp.garde('c_fausse', pg_temp.ecrire('prx_' || repeat('0', 64), '1', 'Bonjour', '3'));
SELECT pg_temp.garde('c_obs', pg_temp.ecrire('rag_' || repeat('a', 64), '1', 'Bonjour', '4'));
SELECT pg_temp.garde('c_null', pg_temp.srv(pg_catalog.format('SELECT public.praxis_ecrire(NULL, %L::uuid, ''x'', %L::uuid)',
  pg_temp.f('1'), pg_temp.idem('70'))));
SELECT pg_temp.vrai(pg_temp.lu('c_vide') = '{"erreur": "cle_refusee"}'::jsonb AND pg_temp.lu('c_fausse') = '{"erreur": "cle_refusee"}'::jsonb
  AND pg_temp.lu('c_obs') = '{"erreur": "cle_refusee"}'::jsonb AND pg_temp.lu('c_null') = '{"erreur": "cle_refusee"}'::jsonb
  AND pg_temp.nb_msg() = (pg_temp.lu('nb0') #>> '{}')::bigint AND NOT EXISTS (SELECT 1 FROM private.praxis_journal WHERE cle_id IS NULL),
  'R1 / R10 : cle absente, fausse, vide ou d''observation (rag_...) : cle_refusee, rien d''ecrit, rien de journalise (anti-inondation)');
-- Une cle revoquee et une cle expiree.
INSERT INTO private.praxis_cles (libelle, prefixe, empreinte, usage, emise_par, cle_emission, emise_le, expire_le)
VALUES ('expiree', 'prx_expiree1', private.praxis_empreinte('prx_' || repeat('e', 64)), 'chat', pg_temp.u('1'),
        '5c1a2222-0000-4000-8000-0000000000e1', pg_catalog.clock_timestamp() - interval '2 days',
        pg_catalog.clock_timestamp() - interval '1 day');
SELECT pg_temp.garde('exp', pg_temp.ecrire('prx_' || repeat('e', 64), '1', 'Bonjour', '5'));
SELECT pg_temp.garde('chat_b', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'A revoquer', 'chat', pg_catalog.now() + interval '5 days', '5c1a2222-0000-4000-8000-000000000003'::uuid)$$));
SELECT pg_temp.garde('revoque', pg_temp.en(pg_temp.u('1'), 'admin', pg_catalog.format(
  'SELECT to_jsonb(public.direction_praxis_revoquer_cle(%L::uuid, ''fin de test'', ''5c1a2222-0000-4000-8000-000000000004''::uuid))',
  pg_temp.lu('chat_b') ->> 'id')));
SELECT pg_temp.garde('rev', pg_temp.ecrire(pg_temp.k('chat_b'), '1', 'Bonjour', '6'));
SELECT pg_temp.vrai(pg_temp.lu('exp') = '{"erreur": "cle_refusee"}'::jsonb AND pg_temp.lu('revoque') = 'true'::jsonb
  AND pg_temp.lu('rev') = '{"erreur": "cle_refusee"}'::jsonb AND pg_temp.nb_msg() = (pg_temp.lu('nb0') #>> '{}')::bigint
  AND (SELECT issue FROM private.praxis_journal WHERE outil = 'ecrire' ORDER BY id DESC LIMIT 1) = 'cle_revoquee'
  AND (SELECT count(*) FROM private.praxis_journal WHERE issue = 'cle_expiree') = 1,
  'R10 : cle expiree ou revoquee : refus (la vraie cause est au journal), rien d''ecrit ; la revocation est immediate');

-- ============ A-10 : chat / routine / autonome ============
SELECT pg_temp.garde('r_off', pg_temp.outil(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.k('routine'))));
SELECT pg_temp.garde('chat_on', pg_temp.outil(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.k('chat'))));
SELECT pg_temp.garde('r_ecrire_off', pg_temp.ecrire(pg_temp.k('routine'), '1', 'Bonjour', '7'));
SELECT pg_temp.garde('autonome_on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(NULL, true, NULL)$$));
SELECT pg_temp.garde('r_on', pg_temp.outil(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.k('routine'))));
SELECT pg_temp.garde('autonome_off', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(NULL, false, NULL)$$));
SELECT pg_temp.garde('chat_off', pg_temp.outil(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.k('chat'))));
SELECT pg_temp.vrai(pg_temp.lu('r_off') = '{"erreur": "autonome_requis"}'::jsonb AND pg_temp.lu('r_ecrire_off') = '{"erreur": "autonome_requis"}'::jsonb
  AND pg_temp.lu('chat_on') ->> 'mode' = 'dirige' AND pg_temp.lu('chat_on') ->> 'actif' = 'true'
  AND pg_temp.lu('r_on') ->> 'mode' = 'autonome' AND pg_temp.lu('chat_off') ->> 'mode' = 'dirige'
  AND pg_temp.nb_msg() = (pg_temp.lu('nb0') #>> '{}')::bigint,
  'A-10 : routine refusee avec autonome faux et acceptee a vrai ; chat accepte dans les deux cas ; etat rend le mode');
SELECT pg_temp.garde('actif_off', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(false, true, NULL)$$));
SELECT pg_temp.garde('o1', pg_temp.ecrire(pg_temp.k('chat'), '1', 'Bonjour', '8'));
SELECT pg_temp.garde('o2', pg_temp.ecrire(pg_temp.k('routine'), '1', 'Bonjour', '9'));
SELECT pg_temp.vrai(pg_temp.lu('o1') = '{"erreur": "eteint"}'::jsonb AND pg_temp.lu('o2') = '{"erreur": "eteint"}'::jsonb AND pg_temp.nb_msg() = (pg_temp.lu('nb0') #>> '{}')::bigint,
  'A-10 : actif faux coupe les deux sortes de cles');
SELECT pg_temp.garde('regle_on2', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));

-- ============ R2, R4, R5, R3 : liste blanche, tables ecrites, rien de sensible ============
SELECT pg_temp.vrai((SELECT array_agg(p.oid::regprocedure::text ORDER BY p.proname) FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace AND p.proname LIKE 'praxis\_%')
  = ARRAY['praxis_acte_confirmer(text,uuid,text)', 'praxis_acte_preparer(text,text,jsonb)', 'praxis_actes(text)',
          'praxis_agir(text,text,jsonb,uuid)', 'praxis_annoncer(text,text[],text,text,uuid)',
          'praxis_boite(text,text,integer)', 'praxis_calendrier_ajouter(text,text,text,date,text,uuid)',
          'praxis_calendrier_lire(text,date,date)', 'praxis_ecrire(text,uuid,text,uuid)', 'praxis_etat(text)',
          'praxis_fil(text,uuid,integer)', 'praxis_lire(text,text,jsonb,integer)', 'praxis_noter_refus(text,text)',
          'praxis_preparer(text,text,text,jsonb,text,uuid)', 'praxis_rendre_compte(text,integer)',
          'praxis_terminer(text,text,integer,integer,integer,integer,text)'],
  'R2 : la liste des fonctions public.praxis_* est exactement la liste blanche ecrite ici (dix outils + praxis_noter_refus, M4 ; PX-2 : lire et preparer ; PRAXIS-ROUTINE : terminer)');
SELECT pg_temp.vrai((SELECT bool_and(has_function_privilege('service_role', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('agent_ro', p.oid, 'EXECUTE')
                       AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
                      FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname LIKE 'praxis\_%')
  AND (SELECT bool_and(NOT has_function_privilege('anon', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('service_role', p.oid, 'EXECUTE')
                       AND NOT has_function_privilege('agent_ro', p.oid, 'EXECUTE'))
         FROM pg_proc p WHERE p.pronamespace = 'private'::regnamespace
           AND (p.proname LIKE 'praxis\_%' OR p.proname LIKE 'com\_%interne' OR p.proname LIKE 'mission%')),
  'R2 : seuls service_role execute les outils (SECURITY DEFINER, search_path vide) ; anon, authenticated, agent_ro : aucun ; les aides privees et les deux fonctions internes : aucun EXECUTE');
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.com_annonce_envoyer_interne(uuid,gender[],text[],text,text,timestamptz,boolean,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'private.com_annonce_envoyer_interne(uuid,gender[],text[],text,text,timestamptz,boolean,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'private.com_envoyer_message_interne(uuid,text,uuid,uuid,text,uuid,boolean)', 'EXECUTE'),
  'AR-6 : les deux fonctions internes de la messagerie n''ont aucun EXECUTE pour anon, authenticated, agent_ro ni service_role');
-- R4 (exigence positive, AR-9) : TOUTES les fonctions praxis_* (outils publics, aides privees) et direction_praxis_* sont couvertes.
-- Les couples (fonction, table ecrite) sont une liste fermee ecrite ici ; toute autre ecriture, tout nouveau couple, est rouge.
SELECT pg_temp.vrai((SELECT coalesce(array_agg(DISTINCT n.nspname || '.' || p.proname || '>' || lower(m[1]) ORDER BY n.nspname || '.' || p.proname || '>' || lower(m[1])), ARRAY[]::text[])
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace,
         LATERAL regexp_matches(p.prosrc, '(?:INSERT\s+INTO|UPDATE|MERGE\s+INTO)\s+([a-z_]+\.[a-z_]+|[a-z_]+)\s', 'gi') m
   WHERE n.nspname IN ('public', 'private') AND (p.proname LIKE 'praxis\_%' OR p.proname LIKE 'direction\_praxis\_%'))
  = (SELECT array_agg(x ORDER BY x) FROM unnest(ARRAY['private.praxis_noter>private.praxis_journal', 'private.praxis_porte>private.praxis_cles',
          'public.direction_praxis_emettre_cle>private.praxis_cles', 'public.direction_praxis_regler>private.praxis_reglages',
          'public.direction_praxis_regler_essai>private.praxis_reglages',
          'private.praxis_propositions_expirer>private.praxis_propositions',
          'public.direction_praxis_ecarter>private.praxis_propositions', 'public.direction_praxis_regler_donnees_reelles>private.praxis_reglages',
          -- PRAXIS-PLAFOND-GLOBAL (20261129870000) : la porte du reglage du plafond d'appels par cle et par heure.
          'public.direction_praxis_regler_plafond>private.praxis_reglages',
          'public.direction_praxis_valider>private.praxis_propositions',
          -- PX-BD-0 (20261129960000) : le SOCLE DES ACTES du mode chat. Les lots prepares et leur code, les actes executes (plafonds,
          -- idempotence) ; jamais un dossier, un compte, un role, un paiement ou une piece : les ECRITURES des actes eux-memes sont dans les
          -- adaptateurs private.praxis_acte_* de chaque lot, relus un par un.
          'public.direction_praxis_confirmation_annuler>private.praxis_confirmations',
          'public.direction_praxis_confirmations>private.praxis_confirmations',
          'public.praxis_acte_confirmer>private.praxis_confirmations', 'public.praxis_acte_confirmer>private.praxis_executions',
          'public.praxis_acte_preparer>private.praxis_confirmations', 'public.praxis_agir>private.praxis_executions',
          'public.direction_praxis_revoquer_cle>private.praxis_cles', 'public.praxis_calendrier_ajouter>private.praxis_calendrier',
          'public.praxis_preparer>private.praxis_propositions',
          -- PRAXIS-ROUTINE (20261129900000) : la routine note la fin de son tir.
          'public.praxis_terminer>private.praxis_tirs']) x),
  'R4 : les couples (fonction praxis_* ou direction_praxis_*, table ecrite) sont exactement la liste fermee ecrite ici : journal, cles, reglages, calendrier ; aucune ecriture dans profiles, app_config, paiements, pieces, comptes');
-- R4 (suite, AR-10) : les ecritures INDIRECTES. TOUT appel qualifie `schema.fonction(` fait par une fonction praxis_*, private.praxis_* ou
-- direction_praxis_* (schemas public, private, auth, extensions, tout schema hors pg_catalog) est dans une liste fermee ecrite ici. Un appel
-- vers une autre fonction (par exemple direction_praxis_regler depuis un outil, ou une fonction de paiement) est rouge. Les noms de tables
-- suivies d'une parenthese de colonnes (INSERT INTO private.praxis_cles (...)) sont dans la liste : leurs ecritures sont fermees par le test R4 precedent.
SELECT pg_temp.vrai((SELECT coalesce(array_agg(DISTINCT lower(m[1]) ORDER BY lower(m[1])), ARRAY[]::text[])
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace,
         LATERAL regexp_matches(p.prosrc, '\m([a-z_][a-z_0-9]*\.[a-z_][a-z_0-9]*)\s*\(', 'gi') m
   WHERE n.nspname IN ('public', 'private') AND (p.proname LIKE 'praxis\_%' OR p.proname LIKE 'direction\_praxis\_%')
     AND lower(m[1]) NOT LIKE 'pg\_catalog.%')
  = (SELECT array_agg(x ORDER BY x) FROM unnest(ARRAY['auth.jwt', 'auth.uid', 'extensions.gen_random_bytes',
          'private.com_annonce_envoyer_interne', 'private.com_annonce_personnes', 'private.com_annonce_publics_valides',
          'private.com_envoyer_message_interne', 'private.com_est_mineur', 'private.com_est_partie', 'private.com_paires',
          'private.com_profil_valide', 'private.praxis_auteur_json', 'private.praxis_calendrier', 'private.praxis_cles',
          'private.praxis_cotes', 'private.praxis_empreinte', 'private.praxis_essai', 'private.praxis_est_equipe', 'private.praxis_est_officiel',
          'private.praxis_est_partie_a', 'private.praxis_fil_dans_cotes', 'private.praxis_fil_refus', 'private.praxis_journal',
          'private.praxis_noter', 'private.praxis_porte', 'private.praxis_profil', 'private.praxis_types_fil',
          -- PX-2 : la lecture des dossiers (cotes, gestes du moteur, complement), la table et l'aide des propositions, et les TROIS portes
          -- publiques de geste que SEULE la validation (sous l'identite de la direction) appelle.
          'private.cand_lecteur', 'private.candidature_complement_codes', 'private.candidature_complement_en_cours',
          'private.gestes_regles_de_la_ligne', 'private.praxis_gestes_ligne', 'private.praxis_propositions',
          -- PRAXIS-ROUTINE : la table des tirs de la routine (INSERT INTO private.praxis_tirs (...)).
          'private.praxis_tirs',
          -- PX-BD-0 : le pont borne, le fabricant d'identite de la direction emettrice, les trois tables des actes.
          'private.praxis_confirmations', 'private.praxis_executer_acte', 'private.praxis_executions', 'private.praxis_identite',
          'private.praxis_propositions_expirer', 'public.admettre_salle_verification', 'public.demander_complement_candidat',
          'public.planifier_entretien',
          'public.app_account_valid', 'public.app_role', 'public.log_sensitive_access']) x),
  'R4 / AR-10 : tout appel qualifie fait par les fonctions praxis_* et direction_praxis_* est dans la liste fermee ecrite ici (45 noms) ; aucun autre appel de public, private ou d''un autre schema');

-- R4 / AR-10 (PX-2, revue R15) : des COUPLES (appelante, appelee), pas seulement une liste de noms. Les trois portes publiques de geste de la
-- candidature ne sont appelees QUE par direction_praxis_valider (qui s'execute sous l'identite de la direction) : aucun outil de Praxis,
-- aucune autre porte de la direction, ne peut les appeler.
SELECT pg_temp.vrai((SELECT coalesce(array_agg(DISTINCT p.proname || '>' || lower(m[1]) ORDER BY p.proname || '>' || lower(m[1])), ARRAY[]::text[])
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace,
         LATERAL regexp_matches(p.prosrc, '\m(public\.(?:demander_complement_candidat|planifier_entretien|admettre_salle_verification))\s*\(', 'gi') m
   WHERE n.nspname IN ('public', 'private') AND (p.proname LIKE 'praxis\_%' OR p.proname LIKE 'direction\_praxis\_%'))
  = (SELECT array_agg(x ORDER BY x) FROM unnest(ARRAY[
       'direction_praxis_valider>public.admettre_salle_verification', 'direction_praxis_valider>public.demander_complement_candidat',
       'direction_praxis_valider>public.planifier_entretien']) x),
  'R4 / AR-10 : les trois portes de geste de la candidature ne sont appelees que depuis direction_praxis_valider (couples appelante > appelee)');
-- R1 (AR-9) : un controle qui a un sens. Chaque outil public a EXACTEMENT les arguments attendus (nom : type) ; aucun argument n'est un texte libre
-- hors des champs listes (cle, filtre, texte borne, titre, sujet, public, recurrence, nom d'outil) ; aucun EXECUTE dynamique dans les corps.
SELECT pg_temp.vrai((SELECT array_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')' ORDER BY p.proname)
                       FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname LIKE 'praxis\_%')
  = ARRAY[
          -- PX-BD-0 : les actes du mode chat. DEUX jsonb de plus, et seulement ceux-la : les parametres d'un acte A (p_params) et le lot d'un
          -- acte S (p_lot). Ce ne sont pas des requetes : l'acte DOIT etre dans le catalogue ferme (private.praxis_actes), et chaque parametre
          -- est valide par l'adaptateur de l'acte contre une liste fermee (scenarios_praxis_actes_socle.sql §3 et §4).
          'praxis_acte_confirmer(p_cle text, p_jeton uuid, p_code text)',
          'praxis_acte_preparer(p_cle text, p_acte text, p_lot jsonb)',
          'praxis_actes(p_cle text)',
          'praxis_agir(p_cle text, p_acte text, p_params jsonb, p_cle_idempotence uuid)',
          'praxis_annoncer(p_cle text, p_publics text[], p_titre text, p_texte text, p_cle_idempotence uuid)',
          'praxis_boite(p_cle text, p_filtre text, p_limite integer)',
          'praxis_calendrier_ajouter(p_cle text, p_sujet text, p_public text, p_date date, p_recurrence text, p_cle_idempotence uuid)',
          'praxis_calendrier_lire(p_cle text, p_du date, p_au date)',
          'praxis_ecrire(p_cle text, p_fil uuid, p_texte text, p_cle_idempotence uuid)',
          'praxis_etat(p_cle text)', 'praxis_fil(p_cle text, p_fil uuid, p_limite integer)',
          -- PX-2 : DEUX arguments jsonb, et seulement ceux-la : le filtre de praxis_lire et les parametres de praxis_preparer. Ce ne sont
          -- pas des requetes : leurs cles et leurs valeurs sont validees contre des listes fermees (une cle ou une valeur inconnue est
          -- refusee `parametre`, scenarios_px2_preparer.sql §2 et §5). Un jsonb de plus, ou un autre, est rouge ici.
          'praxis_lire(p_cle text, p_vue text, p_filtre jsonb, p_limite integer)',
          'praxis_noter_refus(p_cle text, p_outil text)',
          'praxis_preparer(p_cle text, p_geste text, p_candidature text, p_parametres jsonb, p_texte text, p_cle_idempotence uuid)',
          'praxis_rendre_compte(p_cle text, p_heures integer)',
          'praxis_terminer(p_cle text, p_issue text, p_lus integer, p_envoyes integer, p_passes integer, p_refus integer, p_note text)'],
  'R1 : les arguments de chaque outil public sont exactement ceux ecrits ici (aucun argument « requete » ni regclass ; jsonb seulement pour le filtre de praxis_lire et les parametres de praxis_preparer, valides contre des listes fermees ; les seuls textes sont les champs bornes listes)');
SELECT pg_temp.vrai((SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
                      WHERE n.nspname IN ('public', 'private') AND (p.proname LIKE 'praxis\_%' OR p.proname LIKE 'direction\_praxis\_%')
                        AND p.prosrc ~* 'EXECUTE\s') = 0,
  'R1 : aucun EXECUTE dynamique dans les fonctions praxis_* (outils et aides) ni dans les portes de la direction');

-- R5 : toutes les reponses de lecture, sur des fils vivants.
SELECT pg_temp.garde('b_tout', pg_temp.outil(pg_catalog.format('SELECT public.praxis_boite(%L, ''tout'', 50)', pg_temp.k('chat'))));
SELECT pg_temp.garde('f_un', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 50)', pg_temp.k('chat'), pg_temp.f('1'))));
SELECT pg_temp.garde('etat_ok', pg_temp.outil(pg_catalog.format('SELECT public.praxis_etat(%L)', pg_temp.k('chat'))));
SELECT pg_temp.garde('rc_ok', pg_temp.outil(pg_catalog.format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('chat'))));
SELECT pg_temp.vrai(NOT pg_temp.sensible(pg_temp.lu('b_tout')) AND NOT pg_temp.sensible(pg_temp.lu('f_un'))
  AND NOT pg_temp.sensible(pg_temp.lu('etat_ok') - 'interdits') AND NOT pg_temp.sensible(pg_temp.lu('rc_ok')),
  'R5 : aucune reponse (boite, fil, etat, rendre_compte) ne contient courriel, telephone, adresse, montant, naissance, jeton, mot de passe ni secret');
SELECT pg_temp.vrai(pg_temp.lu('f_un') -> 'messages' -> 0 -> 'contenu_tiers' ->> 'texte' = 'Bonjour, ou en est mon dossier ?'
  AND pg_temp.lu('f_un') -> 'messages' -> 0 -> 'contenu_tiers' ->> 'prenom' = 'Tuteur'
  AND NOT (pg_temp.lu('f_un') -> 'messages' -> 0 ? 'texte')
  AND pg_temp.lu('f_un') -> 'messages' -> 0 -> 'auteur' ->> 'role' = 'famille'
  AND NOT (pg_temp.lu('f_un') -> 'messages' -> 0 -> 'auteur' ? 'prenom')
  AND NOT (pg_temp.lu('f_un') -> 'messages' -> 0 -> 'auteur' ? 'nom'),
  'R5 / AR-7 I6 : tout texte et tout prenom d''un tiers sortent dans contenu_tiers (donnee, jamais consigne) ; l''auteur est rendu par role et cote seulement');

-- ============ R6, §3, AR-3 : les enfants ============
SELECT pg_temp.vrai(
  (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('b_tout') -> 'fils') f
    WHERE f ->> 'id' IN (pg_temp.f('1')::text, pg_temp.f('2')::text, pg_temp.f('3')::text, pg_temp.f('5')::text,
                         pg_temp.f('6')::text)) = 5
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('b_tout') -> 'fils') f
                   WHERE f ->> 'id' IN (pg_temp.f('4')::text, pg_temp.f('8')::text, pg_temp.f('9')::text)),
  '§3.2 / AR-3 / AR-7 B2 : la boite montre les fils de foyer lus et ecrits par des adultes ; elle ne montre ni le fil ou un mineur a ecrit (4), ni le fil hors academie (8), ni le fil de candidature (9, type ferme)');
SELECT pg_temp.garde('m_fil4', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('4'))));
SELECT pg_temp.garde('m_ecr4', pg_temp.ecrire(pg_temp.k('chat'), '4', 'Bonjour', '10'));
SELECT pg_temp.vrai(pg_temp.lu('m_fil4') = '{"erreur": "mineur"}'::jsonb AND pg_temp.lu('m_ecr4') = '{"erreur": "mineur"}'::jsonb
  AND pg_temp.nb_msg() = (pg_temp.lu('nb0') #>> '{}')::bigint,
  '§3.2 / §3.3 : un fil ou un mineur a ecrit est refuse en lecture et en ecriture (mineur), rien d''ecrit');
SELECT pg_temp.garde('ok_fil1', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('1'))));
SELECT pg_temp.vrai(NOT (pg_temp.lu('ok_fil1') ? 'erreur'),
  'AR-3 : un fil de foyer lu par les seuls tuteurs adultes, ou seuls des adultes ont ecrit, est ouvert a Praxis');
-- Un mineur (ou une personne d'age inconnu) qui rejoint un fil plus tard le ferme.
SELECT pg_temp.msg('2', '9', 'Je suis un enfant.', '11');
SELECT pg_temp.garde('m_ferme', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('2'))));
SELECT pg_temp.garde('m_ecr2', pg_temp.ecrire(pg_temp.k('chat'), '2', 'Bonjour', '12'));
SELECT pg_temp.vrai(pg_temp.lu('m_ferme') = '{"erreur": "mineur"}'::jsonb AND pg_temp.lu('m_ecr2') = '{"erreur": "mineur"}'::jsonb,
  'AR-3 : un mineur qui rejoint le fil plus tard le referme a Praxis (lecture et ecriture)');
-- Age inconnu = mineur : un eleve sans fiche d'eleve est traite comme mineur.
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.u('11'), 'PX-ELV-0002', 'student', pg_temp.h('3'), 'Eleve', 'Inconnu', 'active', 'female');
SELECT pg_temp.msg('3', '11', 'Message d''un eleve sans age connu.', '13');
SELECT pg_temp.garde('m_inconnu', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('3'))));
SELECT pg_temp.vrai(pg_temp.lu('m_inconnu') = '{"erreur": "mineur"}'::jsonb,
  '§3.1 : un eleve dont l''age est inconnu est traite comme mineur (le fil se referme)');

SELECT pg_temp.garde('nb1', to_jsonb(pg_temp.nb_msg()));
-- ============ R7 : seulement un fil de l'academie, jamais de destinataire choisi ============
SELECT pg_temp.garde('h_ecr', pg_temp.ecrire(pg_temp.k('chat'), '8', 'Bonjour', '14'));
SELECT pg_temp.garde('h_fil', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('8'))));
SELECT pg_temp.garde('i_ecr', pg_temp.ecrire(pg_temp.k('chat'), '99', 'Bonjour', '15'));
SELECT pg_temp.vrai(pg_temp.lu('h_ecr') = '{"erreur": "hors_academie"}'::jsonb AND pg_temp.lu('h_fil') = '{"erreur": "hors_academie"}'::jsonb
  AND pg_temp.lu('i_ecr') = '{"erreur": "fil_inconnu"}'::jsonb AND pg_temp.nb_msg() = (pg_temp.lu('nb1') #>> '{}')::bigint,
  'R7 : fil sans l''academie ou fil inconnu : refus, rien d''ecrit (le seul parametre est l''identifiant d''un fil existant)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_proc p WHERE p.pronamespace = 'public'::regnamespace AND p.proname = 'praxis_ecrire'
    AND p.proargnames::text ~ '(destinataire|personne|profil|participant)'),
  'R7 : aucun outil ne prend une personne comme destinataire ; aucun outil ne cree un fil ni n''ajoute un participant');
SELECT pg_temp.garde('cand', pg_temp.ecrire(pg_temp.k('chat'), '9', 'Bonjour', '16'));
SELECT pg_temp.vrai(pg_temp.lu('cand') = '{"erreur": "type_ferme"}'::jsonb,
  'AR-6 / AR-7 B2 : les fils de candidature (type hors liste positive) sont fermes a Praxis : type_ferme');

-- ============ Un envoi nominal : auteur Praxis, memes effets que pour une personne, R12 ============
SELECT pg_temp.garde('n1', pg_temp.ecrire(pg_temp.k('chat'), '1', 'Bonjour, votre demande est bien recue. La direction repondra.', '17'));
SELECT pg_temp.vrai(pg_temp.lu('n1') ->> 'ok' = 'true'
  AND (SELECT auteur_id FROM public.com_messages WHERE id = (pg_temp.lu('n1') ->> 'id')::uuid) = private.praxis_profil()
  AND (SELECT dernier_message_le FROM public.com_fils WHERE id = pg_temp.f('1'))
      = (SELECT envoye_le FROM public.com_messages WHERE id = (pg_temp.lu('n1') ->> 'id')::uuid)
  AND EXISTS (SELECT 1 FROM public.com_lectures l WHERE l.fil_id = pg_temp.f('1') AND l.profile_id = private.praxis_profil())
  AND (SELECT texte_envoye FROM private.praxis_journal WHERE outil = 'ecrire' AND issue = 'ok' ORDER BY id DESC LIMIT 1)
      = 'Bonjour, votre demande est bien recue. La direction repondra.'
  AND (SELECT emise_par FROM private.praxis_journal WHERE outil = 'ecrire' AND issue = 'ok' ORDER BY id DESC LIMIT 1) = pg_temp.u('1'),
  'R12 / R11 : l''auteur du message est le profil Praxis ; memes effets que la porte humaine (dernier message, lectures) ; le journal garde son texte, la cle et la personne qui l''a emise');
-- Le message de test d'un tiers n'est PAS copie au journal (R11).
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM private.praxis_journal j
    WHERE j.texte_envoye LIKE '%en est mon dossier%' OR to_jsonb(j)::text LIKE '%en est mon dossier%'),
  'R11 : le texte d''une personne n''est jamais copie dans le journal');

-- R9 : idempotence, longueur, plafond par fil, repris par l'equipe, plafond par heure
SELECT pg_temp.garde('n1b', pg_temp.ecrire(pg_temp.k('chat'), '1', 'Bonjour, votre demande est bien recue. La direction repondra.', '17'));
SELECT pg_temp.vrai(pg_temp.lu('n1b') ->> 'rejoue' = 'true' AND pg_temp.lu('n1b') -> 'id' = pg_temp.lu('n1') -> 'id'
  AND (SELECT count(*) FROM public.com_messages WHERE fil_id = pg_temp.f('1') AND auteur_id = private.praxis_profil()) = 1,
  'R9 : meme cle d''idempotence : un seul message');
SELECT pg_temp.garde('long', pg_temp.ecrire(pg_temp.k('chat'), '5', repeat('a', 1501), '18'));
SELECT pg_temp.garde('court', pg_temp.ecrire(pg_temp.k('chat'), '5', '   ', '19'));
SELECT pg_temp.vrai(pg_temp.lu('long') = '{"erreur": "longueur"}'::jsonb AND pg_temp.lu('court') = '{"erreur": "parametre"}'::jsonb
  AND (SELECT count(*) FROM public.com_messages WHERE fil_id = pg_temp.f('5') AND auteur_id = private.praxis_profil()) = 0,
  'R9 : message de plus de 1 500 signes ou vide : refus (longueur, parametre), rien d''ecrit');
SELECT pg_temp.garde('pf1', pg_temp.ecrire(pg_temp.k('chat'), '6', 'Premiere reponse.', '20'));
SELECT pg_temp.garde('pf2', pg_temp.ecrire(pg_temp.k('chat'), '6', 'Deuxieme reponse.', '21'));
SELECT pg_temp.garde('pf3', pg_temp.ecrire(pg_temp.k('chat'), '6', 'Troisieme reponse.', '22'));
SELECT pg_temp.garde('pf4', pg_temp.ecrire(pg_temp.k('chat'), '6', 'Quatrieme reponse.', '23'));
SELECT pg_temp.vrai(pg_temp.lu('pf3') ->> 'ok' = 'true' AND pg_temp.lu('pf4') = '{"erreur": "plafond_fil"}'::jsonb
  AND (SELECT count(*) FROM public.com_messages WHERE fil_id = pg_temp.f('6') AND auteur_id = private.praxis_profil()) = 3,
  'R9 : plafond par fil : trois messages de suite sans reponse de la personne, puis silence (plafond_fil), rien d''ecrit au quatrieme');
SELECT pg_temp.msg_now('6', '8', 'Merci, une autre question.', '24');
SELECT pg_temp.garde('pf5', pg_temp.ecrire(pg_temp.k('chat'), '6', 'Cinquieme reponse.', '25'));
SELECT pg_temp.vrai(pg_temp.lu('pf5') ->> 'ok' = 'true',
  'R9 : quand la personne repond, le plafond du fil repart');
-- R8 : l'equipe reprend (a2 ecrit apres Praxis dans le fil 1), Praxis se tait.
SELECT pg_temp.msg_now('1', '2', 'Bonjour, je reprends ce dossier.', '26');
SELECT pg_temp.garde('rep', pg_temp.ecrire(pg_temp.k('chat'), '1', 'Autre message', '27'));
SELECT pg_temp.garde('rep_fil', pg_temp.outil(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k('chat'), pg_temp.f('1'))));
SELECT pg_temp.vrai(pg_temp.lu('rep') = '{"erreur": "repris_par_equipe"}'::jsonb AND pg_temp.lu('rep_fil') ->> 'repris_par_equipe' = 'true'
  AND (SELECT count(*) FROM public.com_messages WHERE fil_id = pg_temp.f('1') AND auteur_id = private.praxis_profil()) = 1,
  'R8 : un membre de l''equipe a ecrit apres Praxis : ecrire refuse (repris_par_equipe), rien d''ecrit, fil dit repris_par_equipe');
-- Plafond par heure (reglage) : on le met a 3, deja 5 envois ok.
SELECT pg_temp.garde('regle_3', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(NULL, NULL, 3)$$));
SELECT pg_temp.garde('ph', pg_temp.ecrire(pg_temp.k('chat'), '5', 'Reponse du foyer cinq.', '28'));
SELECT pg_temp.vrai(pg_temp.lu('regle_3') ->> 'envoisParHeure' = '3' AND pg_temp.lu('ph') = '{"erreur": "plafond"}'::jsonb
  AND (SELECT count(*) FROM public.com_messages WHERE fil_id = pg_temp.f('5') AND auteur_id = private.praxis_profil()) = 0,
  'R9 : plafond par heure atteint : plafond (private.praxis_reglages.envois_par_heure), rien d''ecrit');
SELECT pg_temp.garde('regle_30', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(NULL, NULL, 30)$$));
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(NULL, NULL, 500)$$, '22023',
  'R9 : un plafond hors de 1 a 120 est refuse');

-- ============ Annonces : R9 (2 par jour, longueurs, idempotence), R12 (aucun courriel), §3.4 ============
SELECT pg_temp.garde('courriels_avant', to_jsonb((SELECT count(*) FROM public.courriels_sortants)));
SELECT pg_temp.garde('a1', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Rappel du mois'', ''Le paiement du mois est attendu.'', %L::uuid)',
  pg_temp.k('chat'), pg_temp.idem('61'))));
SELECT pg_temp.garde('a1b', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Rappel du mois'', ''Le paiement du mois est attendu.'', %L::uuid)',
  pg_temp.k('chat'), pg_temp.idem('61'))));
SELECT pg_temp.vrai(pg_temp.lu('a1') ->> 'ok' = 'true' AND pg_temp.lu('a1b') ->> 'rejoue' = 'true'
  AND (SELECT count(*) FROM public.com_annonces WHERE auteur_id = private.praxis_profil()) = 1
  AND (SELECT courriel FROM public.com_annonce_envois WHERE annonce_id = (pg_temp.lu('a1') ->> 'id')::uuid) = false
  AND (SELECT count(*) FROM public.courriels_sortants) = (pg_temp.lu('courriels_avant') #>> '{}')::bigint,
  'R9 / R12 : une annonce a un auteur Praxis, la meme cle ne la double pas, aucun courriel n''est mis en file (courriel toujours faux)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications n WHERE n.destinataire = private.praxis_profil())
  AND NOT EXISTS (SELECT 1 FROM public.com_annonce_destinataires d WHERE d.profile_id = private.praxis_profil()),
  'R13 : Praxis n''est pas destinataire d''une annonce et ne recoit aucune notification');
SELECT pg_temp.garde('a_el', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''eleves''], ''Aux eleves'', ''Texte.'', %L::uuid)', pg_temp.k('chat'), pg_temp.idem('62'))));
SELECT pg_temp.vrai(pg_temp.lu('a_el') = '{"erreur": "mineur"}'::jsonb
  AND (SELECT count(*) FROM public.com_annonces WHERE auteur_id = private.praxis_profil()) = 1,
  '§3.4 : un public qui contient des eleves (donc des mineurs) est refuse (mineur) : Praxis s''adresse aux familles');
SELECT pg_temp.garde('a_long', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Long'', %L, %L::uuid)', pg_temp.k('chat'), repeat('a', 3001), pg_temp.idem('63'))));
SELECT pg_temp.garde('a_pub', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''inconnu''], ''Titre'', ''Texte.'', %L::uuid)', pg_temp.k('chat'), pg_temp.idem('64'))));
SELECT pg_temp.vrai(pg_temp.lu('a_long') = '{"erreur": "longueur"}'::jsonb AND pg_temp.lu('a_pub') = '{"erreur": "public"}'::jsonb,
  'R9 : annonce de plus de 3 000 signes ou public inconnu : refus (longueur, public)');
SELECT pg_temp.garde('a2', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Deuxieme'', ''Un second rappel.'', %L::uuid)', pg_temp.k('chat'), pg_temp.idem('65'))));
SELECT pg_temp.garde('a3', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Troisieme'', ''Un troisieme rappel.'', %L::uuid)', pg_temp.k('chat'), pg_temp.idem('66'))));
SELECT pg_temp.vrai(pg_temp.lu('a2') ->> 'ok' = 'true' AND pg_temp.lu('a3') = '{"erreur": "plafond_annonces"}'::jsonb
  AND (SELECT count(*) FROM public.com_annonces WHERE auteur_id = private.praxis_profil()) = 2,
  'R9 : au plus deux annonces par jour (la troisieme : plafond_annonces), rien d''ecrit');

-- ============ Calendrier, rendre compte ============
SELECT pg_temp.garde('cal', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_calendrier_ajouter(%L, ''Rappel de paiement'', ''familles'', current_date + 10, ''mensuelle'', %L::uuid)',
  pg_temp.k('chat'), pg_temp.idem('67'))));
SELECT pg_temp.garde('cal_b', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_calendrier_ajouter(%L, ''Rappel de paiement'', ''familles'', current_date + 10, ''mensuelle'', %L::uuid)',
  pg_temp.k('chat'), pg_temp.idem('67'))));
SELECT pg_temp.garde('cal_l', pg_temp.outil(pg_catalog.format(
  'SELECT public.praxis_calendrier_lire(%L, current_date, current_date + 30)', pg_temp.k('chat'))));
SELECT pg_temp.vrai(pg_temp.lu('cal') = pg_temp.lu('cal_b') AND jsonb_array_length(pg_temp.lu('cal_l') -> 'sujets') = 1
  AND NOT pg_temp.sensible(pg_temp.lu('cal_l')),
  'Calendrier : un sujet connu d''avance s''ajoute (idempotent) et se relit');
SELECT pg_temp.garde('rc', pg_temp.outil(pg_catalog.format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('chat'))));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('rc') -> 'envoye') >= 4 AND (pg_temp.lu('rc') ->> 'refuses')::int >= 3
  AND NOT pg_temp.sensible(pg_temp.lu('rc')),
  'rendre_compte : ce que Praxis a envoye (extraits de SES textes) et le nombre de refus, sans donnee sensible');

-- ============ R11 : le journal est a ajout seul ============
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_journal) >= 20
  AND NOT EXISTS (SELECT 1 FROM private.praxis_journal WHERE issue = '' OR outil = '')
  AND (SELECT array_agg(column_name::text ORDER BY column_name) FROM information_schema.columns
        WHERE table_schema = 'private' AND table_name = 'praxis_journal' AND data_type IN ('text', 'ARRAY', 'jsonb'))
      = ARRAY['ids_touches', 'issue', 'outil', 'texte_envoye'],
  'R11 : chaque appel est journalise (refus compris), et la seule colonne de texte libre est texte_envoye (ce que Praxis a lui-meme envoye)');
DO $j$
BEGIN
  BEGIN
    UPDATE private.praxis_journal SET issue = 'x' WHERE id = (SELECT min(id) FROM private.praxis_journal);
    RAISE EXCEPTION 'PRAXIS ROUGE : le journal a ete modifie';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $j$;
SELECT pg_temp.vrai(NOT has_table_privilege('service_role', 'private.praxis_journal', 'UPDATE')
  AND NOT has_table_privilege('service_role', 'private.praxis_journal', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'private.praxis_journal', 'SELECT')
  AND NOT has_table_privilege('service_role', 'private.praxis_cles', 'SELECT')
  AND (SELECT bool_and(c.relrowsecurity) FROM pg_class c WHERE c.oid IN ('private.praxis_journal'::regclass,
       'private.praxis_cles'::regclass, 'private.praxis_calendrier'::regclass, 'private.comptes_officiels'::regclass)),
  'R11 : le journal n''est modifiable par aucune fonction ni aucun role de l''API (mise a jour refusee par declencheur et par droits), RLS active sur les quatre tables');

-- ============ R13 : Praxis absent des listes de personnes nommees ============
SELECT pg_temp.garde('l_comptes', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT coalesce(jsonb_agg(c.profile_id), '[]'::jsonb) FROM public.comptes_admin() c$$));
SELECT pg_temp.garde('l_comptes_role', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT coalesce(jsonb_agg(c.profile_id), '[]'::jsonb) FROM public.comptes_admin_par_role() c$$));
SELECT pg_temp.garde('l_ens', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.lister_enseignants('{}'::jsonb, 'nom', 1)$$));
SELECT pg_temp.garde('l_matricule', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT to_jsonb(public.rechercher_personne_par_matricule('RA-OFFICIEL-PRAXIS'))$$));
SELECT pg_temp.vrai(NOT (pg_temp.lu('l_comptes') @> to_jsonb(private.praxis_profil()::text))
  AND NOT (pg_temp.lu('l_comptes_role') @> to_jsonb(private.praxis_profil()::text))
  AND jsonb_array_length(pg_temp.lu('l_comptes')) >= 8 AND jsonb_array_length(pg_temp.lu('l_comptes_role')) >= 8
  AND NOT (pg_temp.lu('l_ens')::text LIKE '%' || private.praxis_profil()::text || '%')
  AND NOT (pg_temp.lu('l_matricule')::text LIKE '%' || private.praxis_profil()::text || '%'),
  'R13 : Praxis est absent des comptes de la direction (deux lectures), de la liste des enseignants et de la recherche par matricule');
-- R13 (AR-9) : les autres lectures de personnes de la direction (missions, recherche d'eleves) n'exposent pas Praxis. La liste « equipe » et une
-- recherche generale de personnes n'existent pas sous ces noms dans le depot (aucune fonction publique correspondante, releve) : a designer.
SELECT pg_temp.garde('l_missions', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT coalesce(jsonb_agg(to_jsonb(m)), '[]'::jsonb) FROM public.lister_missions() m$$));
SELECT pg_temp.garde('l_pauses', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT coalesce(jsonb_agg(to_jsonb(m)), '[]'::jsonb) FROM public.pauses_eleves_recherche('Praxis') m$$));
SELECT pg_temp.vrai(NOT (pg_temp.lu('l_missions')::text LIKE '%' || private.praxis_profil()::text || '%')
  AND NOT (pg_temp.lu('l_pauses')::text LIKE '%' || private.praxis_profil()::text || '%'),
  'R13 : ni la liste des missions ni la recherche d''eleves (pauses) ne montrent Praxis');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM private.com_annonce_personnes(private.com_annonce_codes(),
        ARRAY['male', 'female']::public.gender[]) x WHERE x.profile_id = private.praxis_profil()),
  'R13 : Praxis n''est destinataire d''aucun public d''annonce (tous les codes, les deux cotes)');
SELECT pg_temp.garde('notif_avant', to_jsonb((SELECT count(*) FROM public.notifications WHERE destinataire = private.praxis_profil())));
SELECT pg_temp.vrai(private.notifier_direction('demande_recue', '{"titre": "t", "extrait": "e"}'::jsonb, '/admin/alertes',
                                              '/comptable/tresorerie/paiements-familles') >= 2
  AND NOT EXISTS (SELECT 1 FROM public.notifications WHERE destinataire = private.praxis_profil()),
  'R13 : les notifications par role (administration, comptabilite) n''atteignent pas Praxis (statut desactive)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.teacher_profiles WHERE profile_id = private.praxis_profil())
  AND NOT EXISTS (SELECT 1 FROM public.weekly_availability WHERE profile_id = private.praxis_profil())
  AND NOT EXISTS (SELECT 1 FROM public.groupe_membres WHERE student_id = private.praxis_profil())
  AND NOT EXISTS (SELECT 1 FROM public.groupes WHERE teacher_id = private.praxis_profil()),
  'R13 : Praxis n''a ni profil d''enseignant, ni disponibilite, ni classe : absent de la paie, de la presence et du matching');
SELECT pg_temp.vrai(public.app_account_valid() IS NOT TRUE OR true, '(garde de compilation)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM private.person_registrations r WHERE r.profile_id = private.praxis_profil()),
  'R13 / A-11 : aucun matricule pour Praxis apres toutes les operations');

\o
SELECT 'PRAXIS : tous les controles sont verts' AS verdict;
ROLLBACK;
