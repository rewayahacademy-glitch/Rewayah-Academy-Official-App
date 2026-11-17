-- PX-SUIVI (migration 20261129930000) : Praxis demande a l'equipe ce qu'il ne sait pas et revient vers la personne.
--   0 apres installation : aucune question, la direction lit une liste vide, un tuteur est refuse ;
--   1 Praxis eteint : rien ne s'ecrit ; 2 demander_equipe : une question OUVERTE par conversation, mineur / type ferme / inconnue
--     refuses, bornes de 300 signes ; 3 la direction lit, ouvertes d'abord (les plus anciennes en tete) ;
--   4 reponses_equipe vide tant que rien n'est repondu ; 5 repondre : aal2, bornes, une seule reponse, audit sans le texte ;
--   6 reponses_equipe rend la reponse (jamais d'une conversation fermee a Praxis), question_traitee la marque utilisee, jamais deux fois ;
--   7 plafonds (20 par cle et par heure, 100 ouvertes) ; 8 droits.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal, 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.vrai(p boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'SUIVI ROUGE : %', p_label; END IF;
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
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_aal text, p_sql text, p_code text, p_label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_passe boolean := false; v_code text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN RAISE EXCEPTION 'SUIVI ROUGE : % (aucun refus)', p_label; END IF;
  IF v_code <> p_code THEN RAISE EXCEPTION 'SUIVI ROUGE : % (code % au lieu de %)', p_label, v_code, p_code; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.appel(uuid, text, text, text),
  pg_temp.refus(uuid, text, text, text, text, text), pg_temp.srv(text) TO authenticated, anon, service_role;

CREATE FUNCTION pg_temp.u(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b4000000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.h(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b4ffffff-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.f(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b4cccccc-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b4111111-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(integer), pg_temp.h(integer), pg_temp.f(integer), pg_temp.idem(integer) TO authenticated, anon, service_role;

-- a1 direction (super-administration : les deux cotes), a2 administrateur, g1 a g3 tuteurs adultes (un foyer chacun), s1 eleve MINEUR du foyer 1.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n), 'px4-' || n || '@test.invalid' FROM generate_series(1, 9) n;
INSERT INTO public.households (id, timezone) SELECT pg_temp.h(n), 'Europe/Paris' FROM generate_series(1, 4) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u(1), 'PX4-ADM-0001', 'admin', NULL, 'Direction', 'Un', 'active', 'male'),
 (pg_temp.u(2), 'PX4-ADM-0002', 'admin', NULL, 'Direction', 'Deux', 'active', 'female'),
 (pg_temp.u(3), 'PX4-TUT-0001', 'guardian', pg_temp.h(1), 'Tuteur', 'Un', 'active', 'female'),
 (pg_temp.u(4), 'PX4-TUT-0002', 'guardian', pg_temp.h(2), 'Tuteur', 'Deux', 'active', 'male'),
 (pg_temp.u(5), 'PX4-TUT-0003', 'guardian', pg_temp.h(3), 'Tuteur', 'Trois', 'active', 'female'),
 (pg_temp.u(6), 'PX4-ELV-0001', 'student', pg_temp.h(4), 'Eleve', 'Mineur', 'active', 'male'),
 (pg_temp.u(7), 'PX4-TUT-0004', 'guardian', pg_temp.h(4), 'Tuteur', 'Quatre', 'active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u(1));
INSERT INTO public.student_profiles (profile_id, student_type) VALUES (pg_temp.u(6), 'minor');

-- F1 F2 F3 : dossiers de tuteurs adultes ; F4 : fil d'un mineur (foyer 4) ; F5 : fil de candidature (type ferme).
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id) VALUES
 (pg_temp.f(1), 'dossier', pg_temp.u(3), 'foyer', pg_temp.h(1), 'equipe', NULL),
 (pg_temp.f(2), 'dossier', pg_temp.u(4), 'foyer', pg_temp.h(2), 'equipe', NULL),
 (pg_temp.f(3), 'dossier', pg_temp.u(5), 'foyer', pg_temp.h(3), 'equipe', NULL),
 (pg_temp.f(4), 'eleve', pg_temp.u(6), 'foyer', pg_temp.h(4), 'equipe', NULL),
 (pg_temp.f(5), 'candidature', pg_temp.u(98), 'profil', pg_temp.u(5), 'equipe', NULL);
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
 (pg_temp.f(1), pg_temp.u(3), pg_temp.idem(1), 'Bonjour, ou en est mon dossier ?', pg_catalog.clock_timestamp() - interval '2 hours'),
 (pg_temp.f(2), pg_temp.u(4), pg_temp.idem(2), 'Bonjour, une question sur les horaires.', pg_catalog.clock_timestamp() - interval '3 hours'),
 (pg_temp.f(3), pg_temp.u(5), pg_temp.idem(3), 'Bonjour, un renseignement.', pg_catalog.clock_timestamp() - interval '4 hours'),
 (pg_temp.f(4), pg_temp.u(6), pg_temp.idem(4), 'Bonjour, c''est un enfant.', pg_catalog.clock_timestamp() - interval '2 hours'),
 (pg_temp.f(5), pg_temp.u(5), pg_temp.idem(5), 'Bonjour, candidature.', pg_catalog.clock_timestamp() - interval '2 hours');

CREATE FUNCTION pg_temp.nb_msg() RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM public.com_messages $$;
CREATE FUNCTION pg_temp.nb_annonces() RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM public.com_annonces $$;
CREATE FUNCTION pg_temp.ids(p_j jsonb) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT coalesce(string_agg(x ->> 'id', ',' ORDER BY x ->> 'id'), '') FROM jsonb_array_elements(p_j -> 'fils') x $$;


-- La cle de chat et celle de routine, puis l'interrupteur (direction, aal2).
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Chat de test', 'chat', pg_catalog.now() + interval '30 days', 'b4222222-0000-4000-8000-000000000001'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Routine de test', 'routine', pg_catalog.now() + interval '30 days', 'b4222222-0000-4000-8000-000000000002'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle_routine \gset

CREATE FUNCTION pg_temp.nb_q() RETURNS bigint LANGUAGE sql AS $$ SELECT count(*) FROM private.praxis_questions $$;
CREATE FUNCTION pg_temp.nb_j(p_outil text, p_issue text) RETURNS bigint LANGUAGE sql AS $$
  SELECT count(*) FROM private.praxis_journal WHERE outil = p_outil AND issue = p_issue $$;
GRANT EXECUTE ON FUNCTION pg_temp.nb_q(), pg_temp.nb_j(text, text) TO authenticated, anon, service_role;

-- ============ 0 : apres installation ============
SELECT pg_temp.vrai(pg_temp.nb_q() = 0, '0 : aucune question apres installation');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_questions(100)') AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"questions": [], "total": 0}'::jsonb, '0 : la direction lit une liste vide (lecture sans MFA, comme les autres lectures)');
SELECT pg_temp.refus(pg_temp.u(3), 'guardian', 'aal2', 'SELECT public.direction_praxis_questions(100)', '42501', '0 : un tuteur ne lit pas les questions');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_questions(0)', '22023', '0 : limite 0 refusee');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_questions(201)', '22023', '0 : limite 201 refusee');

-- ============ 1 : Praxis eteint : rien ne s'ecrit ============
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Question.'')', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"eteint"}'::jsonb AND pg_temp.nb_q() = 0, '1 : praxis.actif faux : demander_equipe refuse `eteint`, aucune question');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_regler(true, true, 100)$$);
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ============ 2 : demander_equipe ============
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Le tuteur demande si le cours du lundi peut passer au mardi : on peut ?'')', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND pg_temp.nb_q() = 1, '2 : une question est posee dans une conversation ouverte');
SELECT :'j'::jsonb ->> 'id' AS q1 \gset
SELECT pg_temp.vrai((SELECT fil_id = pg_temp.f(1) AND reponse IS NULL AND repondue_le IS NULL AND utilisee_le IS NULL
                       AND question LIKE 'Le tuteur demande%' FROM private.praxis_questions WHERE id = :'q1'::uuid),
  '2 : elle porte la conversation et le resume de Praxis, sans reponse');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Une autre question sur le meme fil.'')', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"question_ouverte"}'::jsonb AND pg_temp.nb_q() = 1 AND pg_temp.nb_j('demander_equipe', 'question_ouverte') = 1,
  '2 : une seule question OUVERTE par conversation (refus journalise)');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Question sur un autre dossier.'')', :'cle_routine', pg_temp.f(2))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND pg_temp.nb_q() = 2, '2 : une autre conversation a sa propre question (la cle de routine le peut aussi)');
SELECT :'j'::jsonb ->> 'id' AS q2 \gset
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Question sur un enfant.'')', :'cle', pg_temp.f(4))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"mineur"}'::jsonb AND pg_temp.nb_q() = 2, '2 : la conversation d''un mineur est refusee, aucune question');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Question sur une candidature.'')', :'cle', pg_temp.f(5))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ? 'erreur' AND pg_temp.nb_q() = 2, '2 : un fil de type ferme est refuse par la porte existante, aucune question');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, ''b4000000-0000-4000-8000-0000000fffff''::uuid, ''Question.'')', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ? 'erreur' AND pg_temp.nb_q() = 2, '2 : une conversation inconnue est refusee');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, %L)', :'cle', pg_temp.f(3), repeat('x', 301))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_q() = 2, '2 : 301 signes refuses `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''    '')', :'cle', pg_temp.f(3))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_q() = 2, '2 : question vide refusee `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, NULL, ''Question.'')', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb AND pg_temp.nb_q() = 2, '2 : conversation NULL refusee `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, repeat(''y'', 300))', :'cle', pg_temp.f(3))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND pg_temp.nb_q() = 3, '2 : 300 signes passent');
SELECT :'j'::jsonb ->> 'id' AS q3 \gset
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Question.'')', 'prx_' || repeat('0', 64), pg_temp.f(3))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' = 'cle_refusee' AND pg_temp.nb_q() = 3, '2 : une cle inconnue est refusee');

-- ============ 3 : la direction lit, ouvertes d'abord (les plus anciennes en tete) ============
UPDATE private.praxis_questions SET posee_le = pg_catalog.clock_timestamp() - interval '3 hours' WHERE id = :'q2'::uuid;
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_questions(100)') AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'total')::int = 3
    AND jsonb_array_length(:'j'::jsonb -> 'questions') = 3
    AND (:'j'::jsonb #>> '{questions,0,id}') = :'q2'
    AND (:'j'::jsonb #>> '{questions,0,filId}') = pg_temp.f(2)::text
    AND (:'j'::jsonb #> '{questions,0,reponse}') = 'null'::jsonb,
  '3 : trois questions ouvertes, la plus ancienne en tete, avec la conversation et sans reponse');

-- ============ 4 : reponses_equipe est vide tant que rien n'est repondu ============
SELECT pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 20)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"reponses": []}'::jsonb, '4 : aucune reponse tant que la direction n''a pas repondu');
SELECT pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 0)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '4 : limite 0 refusee `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 51)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '4 : limite 51 refusee `parametre`');

-- ============ 5 : la direction repond (aal2, une seule fois) ============
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal1', format('SELECT public.direction_praxis_repondre(%L::uuid, ''Oui.'')', :'q1'), '42501',
  '5 : sans MFA (aal1), repondre est refuse');
SELECT pg_temp.refus(pg_temp.u(3), 'guardian', 'aal2', format('SELECT public.direction_praxis_repondre(%L::uuid, ''Oui.'')', :'q1'), '42501',
  '5 : un tuteur ne repond pas');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_repondre(%L::uuid, ''   '')', :'q1'), '22023',
  '5 : une reponse vide est refusee');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_repondre(%L::uuid, %L)', :'q1', repeat('r', 1501)), '22023',
  '5 : une reponse de 1501 signes est refusee');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_repondre(%L::uuid, NULL)', :'q1'), '22023',
  '5 : une reponse NULL est refusee');
SELECT pg_temp.vrai((SELECT reponse IS NULL FROM private.praxis_questions WHERE id = :'q1'::uuid), '5 : aucun refus n''a ecrit de reponse');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_repondre(''b4000000-0000-4000-8000-0000000fffff''::uuid, ''Oui.'')') AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"inconnue"}'::jsonb, '5 : une question inconnue : `inconnue`');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format($$SELECT public.direction_praxis_repondre(%L::uuid, '  Oui, le cours passe au mardi à la même heure.  ')$$, :'q1')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"ok": true}'::jsonb, '5 : la direction repond');
SELECT pg_temp.vrai((SELECT reponse = 'Oui, le cours passe au mardi à la même heure.' AND repondue_le IS NOT NULL AND repondue_par = pg_temp.u(1)
                       AND utilisee_le IS NULL FROM private.praxis_questions WHERE id = :'q1'::uuid),
  '5 : reponse nettoyee, date, auteur : pas encore utilisee');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format($$SELECT public.direction_praxis_repondre(%L::uuid, 'Autre texte.')$$, :'q1')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"deja_repondue"}'::jsonb
    AND (SELECT reponse FROM private.praxis_questions WHERE id = :'q1'::uuid) = 'Oui, le cours passe au mardi à la même heure.',
  '5 : une seule reponse par question : `deja_repondue`, la premiere reste');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_repond_question' AND row_id = 'praxis') = 1
    AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'praxis_repond_question' AND payload::text LIKE '%Oui, le cours%'),
  '5 : une ligne d''audit, sans le texte de la reponse');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_questions(100)') AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb #>> '{questions,0,id}') <> :'q1' AND (:'j'::jsonb #>> '{questions,2,id}') = :'q1'
    AND (:'j'::jsonb #>> '{questions,2,repondueParPrenom}') = 'Direction' AND (:'j'::jsonb #> '{questions,2,utiliseeLe}') = 'null'::jsonb,
  '5 : la repondue passe apres les ouvertes, avec le prenom de la direction');

-- ============ 6 : reponses_equipe, puis question_traitee ============
SELECT pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 20)', :'cle')) AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'reponses') = 1
    AND (:'j'::jsonb #>> '{reponses,0,id}') = :'q1' AND (:'j'::jsonb #>> '{reponses,0,fil}') = pg_temp.f(1)::text
    AND (:'j'::jsonb #>> '{reponses,0,reponse_de_la_direction}') = 'Oui, le cours passe au mardi à la même heure.'
    AND (:'j'::jsonb #>> '{reponses,0,question}') LIKE 'Le tuteur demande%',
  '6 : Praxis lit la reponse de la direction avec sa conversation ; la question sans reponse n''y est pas');
-- Une conversation qui n'est plus ouverte a Praxis (mode essai sur une autre) : la reponse n'est pas rendue.
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L]::uuid[])', pg_temp.f(2)));
SELECT pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 20)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"reponses": []}'::jsonb, '6 : hors mode essai (F1 n''est pas dans la liste), la reponse n''est pas rendue');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_essai(ARRAY[]::uuid[])');
SELECT pg_temp.srv(format('SELECT public.praxis_question_traitee(%L, %L::uuid)', :'cle', :'q2')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"inconnue"}'::jsonb, '6 : une question sans reponse ne se marque pas utilisee');
SELECT pg_temp.srv(format('SELECT public.praxis_question_traitee(%L, ''b4000000-0000-4000-8000-0000000fffff''::uuid)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"inconnue"}'::jsonb, '6 : une question inconnue : `inconnue`');
SELECT pg_temp.srv(format('SELECT public.praxis_question_traitee(%L, NULL)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '6 : question NULL : `parametre`');
SELECT pg_temp.srv(format('SELECT public.praxis_question_traitee(%L, %L::uuid)', :'cle', :'q1')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"ok": true}'::jsonb AND (SELECT utilisee_le IS NOT NULL FROM private.praxis_questions WHERE id = :'q1'::uuid),
  '6 : apres avoir ecrit, Praxis marque la question utilisee');
SELECT pg_temp.srv(format('SELECT public.praxis_question_traitee(%L, %L::uuid)', :'cle', :'q1')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"inconnue"}'::jsonb, '6 : on ne la marque pas deux fois');
SELECT pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 20)', :'cle')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"reponses": []}'::jsonb, '6 : une reponse utilisee n''est plus rendue (jamais deux fois a la personne)');
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Nouvelle question sur le meme fil.'')', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean, '6 : une fois repondue, une nouvelle question est permise dans la conversation');

-- ============ 7 : plafonds ============
-- 20 questions par cle et par heure : on en insere jusqu'a 20 (autres conversations fictives), la suivante est refusee.
INSERT INTO private.praxis_questions (fil_id, cle_id, question)
SELECT ('b4dddddd-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, (SELECT id FROM private.praxis_cles WHERE libelle = 'Chat de test'), 'Question ' || n
  FROM generate_series(1, 20 - (SELECT count(*)::int FROM private.praxis_questions q JOIN private.praxis_cles c ON c.id = q.cle_id
                                  WHERE c.libelle = 'Chat de test' AND q.posee_le > pg_catalog.clock_timestamp() - interval '1 hour')) n;
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Au-dela du plafond.'')', :'cle', pg_temp.f(3))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"plafond"}'::jsonb, '7 : 20 questions par cle et par heure : la 21e est refusee `plafond` (le plafond joue avant la question ouverte)');
-- F3 a sa question ouverte (q3) : on la repond pour la liberer ; le plafond horaire refuse encore, il ne depend pas d'elle.
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format($$SELECT public.direction_praxis_repondre(%L::uuid, 'Reponse.')$$, :'q3'));
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Au-dela du plafond.'')', :'cle', pg_temp.f(3))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"plafond"}'::jsonb, '7 : conversation libre, le plafond horaire refuse toujours');
SELECT pg_temp.vrai(pg_temp.nb_j('demander_equipe', 'plafond') = 2, '7 : chaque refus du plafond est journalise');
-- Hors de l'heure, le plafond horaire ne compte plus ; 100 questions ouvertes au plus.
UPDATE private.praxis_questions SET posee_le = pg_catalog.clock_timestamp() - interval '2 hours';
INSERT INTO private.praxis_questions (fil_id, cle_id, question, posee_le)
SELECT ('b4eeeeee-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, (SELECT id FROM private.praxis_cles WHERE libelle = 'Chat de test'), 'Ouverte ' || n,
       pg_catalog.clock_timestamp() - interval '2 hours'
  FROM generate_series(1, 100 - (SELECT count(*)::int FROM private.praxis_questions WHERE repondue_le IS NULL)) n;
SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, ''Une de trop.'')', :'cle', pg_temp.f(3))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"trop_ouvertes"}'::jsonb, '7 : 100 questions ouvertes au plus : la suivante est refusee `trop_ouvertes`');

-- ============ 8 : droits ============
SELECT pg_temp.vrai(NOT has_table_privilege('anon', 'private.praxis_questions', 'SELECT')
    AND NOT has_table_privilege('authenticated', 'private.praxis_questions', 'SELECT')
    AND NOT has_table_privilege('service_role', 'private.praxis_questions', 'SELECT')
    AND NOT has_table_privilege('agent_ro', 'private.praxis_questions', 'SELECT')
    AND NOT has_table_privilege('authenticated', 'private.praxis_questions', 'UPDATE')
    AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.praxis_questions'::regclass),
  '8 : private.praxis_questions : RLS active, aucun droit direct');
SELECT pg_temp.vrai(has_function_privilege('service_role', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
    AND has_function_privilege('service_role', 'public.praxis_reponses_equipe(text,integer)', 'EXECUTE')
    AND has_function_privilege('service_role', 'public.praxis_question_traitee(text,uuid)', 'EXECUTE')
    AND NOT has_function_privilege('anon', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
    AND NOT has_function_privilege('authenticated', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
    AND NOT has_function_privilege('agent_ro', 'public.praxis_demander_equipe(text,uuid,text)', 'EXECUTE')
    AND NOT has_function_privilege('authenticated', 'public.praxis_reponses_equipe(text,integer)', 'EXECUTE')
    AND NOT has_function_privilege('authenticated', 'public.praxis_question_traitee(text,uuid)', 'EXECUTE')
    AND has_function_privilege('authenticated', 'public.direction_praxis_repondre(uuid,text)', 'EXECUTE')
    AND NOT has_function_privilege('service_role', 'public.direction_praxis_repondre(uuid,text)', 'EXECUTE')
    AND NOT has_function_privilege('anon', 'public.direction_praxis_questions(integer)', 'EXECUTE'),
  '8 : les trois outils au seul service_role, les deux portes de la direction aux seuls comptes connectes');

ROLLBACK;
\o
\echo PX-SUIVI : tous les controles sont verts
