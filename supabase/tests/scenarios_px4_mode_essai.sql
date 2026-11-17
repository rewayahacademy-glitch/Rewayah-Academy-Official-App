-- PX-4 MODE ESSAI (migration 20261129650000). L'essai a blanc du directeur ne doit lire AUCUNE conversation reelle : tant que des
-- conversations d'essai sont nommees (private.praxis_reglages.essai_fils), Praxis ne voit QUE celles-la.
--   1 etat de depart : liste vide, comportement inchange (la boite voit tous les fils, un envoi passe) ;
--   2 la porte du directeur : administrateur valide EN aal2 seulement ; liste NULL, avec un NULL, de plus de 10, ou avec un fil
--     inconnu : refus 22023 et rien de change ; un doublon est rendu une seule fois ;
--   3 mode essai [F1] : la boite, la lecture d'un fil, l'envoi et le compte rendu ne voient que F1 ; un autre fil et un fil
--     INEXISTANT sont refuses `hors_essai` (aucune fuite d'existence) ; l'envoi hors liste n'ecrit rien ; l'annonce est refusee
--     `essai`, n'ecrit rien et est journalisee ;
--   4 le parcours est borne a la liste : un fil d'essai plus ancien que les 200 plus recents est quand meme vu ;
--   5 le mode essai ne donne aucun droit : un fil d'essai de type ferme ou d'un mineur reste refuse ;
--   6 fin du mode essai (liste vide) : tout revient, l'annonce n'est plus refusee pour `essai` ;
--   7 trace : une ligne d'audit par changement ; l'etat rend `essaiFils`.
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
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'PX4 ROUGE : %', p_label; END IF;
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
  IF v_passe THEN RAISE EXCEPTION 'PX4 ROUGE : % (aucun refus)', p_label; END IF;
  IF v_code <> p_code THEN RAISE EXCEPTION 'PX4 ROUGE : % (code % au lieu de %)', p_label, v_code, p_code; END IF;
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

-- La cle et l'interrupteur (aal2, direction).
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Chat de test', 'chat', pg_catalog.now() + interval '30 days', 'b4222222-0000-4000-8000-000000000001'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', $$SELECT public.direction_praxis_regler(true, false, 100)$$);

-- ============ 0 : donnees_reelles faux (PX-2) : seul le mode essai ouvre Praxis ============
SELECT pg_temp.vrai(NOT (SELECT donnees_reelles FROM private.praxis_reglages), '0 : donnees_reelles est faux apres installation');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"donnees_reelles_fermees"}'::jsonb, '0 : sans liste d''essai, un fil reel est refuse donnees_reelles_fermees');
SELECT pg_temp.srv(format('SELECT public.praxis_boite(%L, ''tout'', 50)', :'cle')) AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'fils') = 0, '0 : sans liste d''essai, la boite est vide');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L]::uuid[])', pg_temp.f(1)));
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' IS NULL, '0 : avec la liste d''essai, F1 est lisible meme si les donnees reelles sont fermees');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(2))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"hors_essai"}'::jsonb, '0 : et F2 reste hors de l''essai');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_essai(ARRAY[]::uuid[])');
-- PX-2 : les donnees reelles sont ouvertes (la politique est publiee) pour la suite.
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ============ 1 : etat de depart ============
SELECT pg_temp.vrai((SELECT essai_fils FROM private.praxis_reglages) = '{}'::uuid[], '1 : la liste d''essai est vide apres installation');
SELECT pg_temp.srv(format('SELECT public.praxis_boite(%L, ''tout'', 50)', :'cle')) AS j \gset
SELECT pg_temp.vrai(pg_temp.ids(:'j'::jsonb) = (SELECT string_agg(i::text, ',' ORDER BY i::text) FROM unnest(ARRAY[pg_temp.f(1), pg_temp.f(2), pg_temp.f(3)]) i),
  '1 : sans mode essai, la boite voit F1 F2 F3 (F4 mineur et F5 candidature restent exclus)');
SELECT pg_temp.srv(format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Un mot avant l essai.'', %L::uuid)', :'cle', pg_temp.f(2), pg_temp.idem(50)))
  AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean, '1 : sans mode essai, un envoi dans F2 passe (il entrera dans le compte rendu)');

-- ============ 2 : la porte du directeur ============
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal1', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L]::uuid[])', pg_temp.f(1)), '42501',
  '2 : sans double verification (aal1), refus');
SELECT pg_temp.refus(pg_temp.u(3), 'guardian', 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L]::uuid[])', pg_temp.f(1)), '42501',
  '2 : un tuteur, refus');
SELECT pg_temp.refus(NULL, NULL, 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L]::uuid[])', pg_temp.f(1)), '42501',
  '2 : sans identite, refus');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_essai(NULL)', '22023', '2 : liste NULL, refus');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_essai(ARRAY[NULL]::uuid[])', '22023', '2 : liste avec un NULL, refus');
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_essai(ARRAY[''b4cccccc-0000-4000-8000-0000000000aa'']::uuid[])', '22023',
  '2 : un fil inconnu, refus');
SELECT pg_temp.vrai((SELECT essai_fils FROM private.praxis_reglages) = '{}'::uuid[], '2 : aucun refus n''a change la liste');
-- Plus de dix : on ajoute des fils pour que la limite soit seule en cause.
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
  SELECT ('b4dddddd-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid, 'dossier', ('b4eeeeee-0000-4000-8000-0000000000' || lpad(n::text, 2, '0'))::uuid,
         'foyer', pg_temp.h(1), 'equipe', NULL FROM generate_series(1, 11) n;
SELECT format('SELECT public.direction_praxis_regler_essai(%L::uuid[])', (SELECT array_agg(id) FROM public.com_fils WHERE id::text LIKE 'b4dddddd%')) AS sql_onze \gset
SELECT pg_temp.refus(pg_temp.u(1), 'admin', 'aal2', :'sql_onze', '22023', '2 : onze fils, refus (dix au plus)');
SELECT pg_temp.vrai((SELECT essai_fils FROM private.praxis_reglages) = '{}'::uuid[], '2 : la liste est toujours vide');
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L, %L]::uuid[])', pg_temp.f(1), pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'essaiFils') = 1, '2 : un doublon est rendu une seule fois');

-- ============ 4 (prepare ici) : 205 fils plus recents que F3 ============
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id, dernier_message_le)
  SELECT ('b4aaaaaa-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'dossier', ('b4bbbbbb-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
         'foyer', pg_temp.h(1), 'equipe', NULL, pg_catalog.clock_timestamp() + interval '1 day' FROM generate_series(1, 205) n;
UPDATE public.com_fils SET dernier_message_le = pg_catalog.clock_timestamp() - interval '10 days' WHERE id = pg_temp.f(3);

-- ============ 3 : mode essai [F1] ============
SELECT pg_temp.nb_msg() AS nb0, pg_temp.nb_annonces() AS na0 \gset
SELECT pg_temp.srv(format('SELECT public.praxis_boite(%L, ''tout'', 50)', :'cle')) AS j \gset
SELECT pg_temp.vrai(pg_temp.ids(:'j'::jsonb) = pg_temp.f(1)::text, '3 : la boite ne voit que F1');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(1))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' IS NULL AND jsonb_array_length(:'j'::jsonb -> 'messages') = 1, '3 : la lecture de F1 passe');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(2))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"hors_essai"}'::jsonb, '3 : la lecture de F2 est refusee hors_essai, sans un mot de son contenu');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', 'b4cccccc-0000-4000-8000-0000000000bb')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"hors_essai"}'::jsonb, '3 : un fil inexistant est refuse de la meme facon (aucune fuite d''existence)');
SELECT pg_temp.srv(format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Hors liste.'', %L::uuid)', :'cle', pg_temp.f(2), pg_temp.idem(51))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"hors_essai"}'::jsonb AND pg_temp.nb_msg() = :nb0, '3 : l''envoi dans F2 est refuse hors_essai et n''ecrit rien');
SELECT pg_temp.srv(format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Dans la liste.'', %L::uuid)', :'cle', pg_temp.f(1), pg_temp.idem(52))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND pg_temp.nb_msg() = :nb0 + 1, '3 : l''envoi dans F1 passe');
SELECT pg_temp.srv(format('SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''Titre'', ''Une annonce.'', %L::uuid)', :'cle', pg_temp.idem(53))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"essai"}'::jsonb AND pg_temp.nb_annonces() = :na0, '3 : l''annonce est refusee `essai` et n''ecrit rien');
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_journal WHERE outil = 'annoncer' AND issue = 'essai') = 1, '3 : le refus de l''annonce est journalise');
SELECT pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', :'cle')) AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'envoye') = 1
  AND (:'j'::jsonb -> 'envoye' -> 0 ->> 'fil') = pg_temp.f(1)::text,
  '3 : le compte rendu ne montre que l''envoi de F1 (celui de F2 d''avant l''essai n''y est plus)');
SELECT pg_temp.vrai((:'j'::jsonb ->> 'laisse_en_attente')::integer = 0, '3 : le compte rendu ne compte que les fils d''essai en attente');

-- ============ 4 : le parcours est borne a la liste ============
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L]::uuid[])', pg_temp.f(3)));
SELECT pg_temp.srv(format('SELECT public.praxis_boite(%L, ''tout'', 50)', :'cle')) AS j \gset
SELECT pg_temp.vrai(pg_temp.ids(:'j'::jsonb) = pg_temp.f(3)::text, '4 : F3, plus ancien que 205 autres fils, est vu en mode essai');
SELECT pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', :'cle')) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'laisse_en_attente')::integer = 1, '4 : le compte rendu compte F3 en attente');

-- ============ 5 : le mode essai ne donne aucun droit ============
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', format('SELECT public.direction_praxis_regler_essai(ARRAY[%L, %L]::uuid[])', pg_temp.f(4), pg_temp.f(5)));
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(4))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"mineur"}'::jsonb, '5 : un fil d''essai qui touche un mineur reste refuse `mineur`');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(5))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"type_ferme"}'::jsonb, '5 : un fil d''essai de candidature reste refuse `type_ferme`');
SELECT pg_temp.srv(format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Non.'', %L::uuid)', :'cle', pg_temp.f(4), pg_temp.idem(54))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"mineur"}'::jsonb, '5 : l''envoi dans un fil d''essai de mineur reste refuse');

-- ============ 7 : etat et trace ============
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal1', 'SELECT public.direction_praxis_etat()') AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb -> 'essaiFils') @> to_jsonb(pg_temp.f(4)::text) AND jsonb_array_length(:'j'::jsonb -> 'essaiFils') = 2,
  '7 : l''etat rend les conversations d''essai (lecture en aal1 permise)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_regle_essai') = 5,
  '7 : une ligne d''audit par changement reussi (5 a ce stade), aucune pour les refus');

-- ============ 6 : fin du mode essai ============
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_essai(ARRAY[]::uuid[])') AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'essaiFils') = 0 AND (SELECT essai_fils FROM private.praxis_reglages) = '{}'::uuid[],
  '6 : une liste vide met fin au mode essai');
SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 10)', :'cle', pg_temp.f(2))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' IS NULL, '6 : F2 est de nouveau lisible');
SELECT pg_temp.srv(format('SELECT public.praxis_annoncer(%L, ARRAY[''inconnu''], ''Titre'', ''Une annonce.'', %L::uuid)', :'cle', pg_temp.idem(55))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"public"}'::jsonb, '6 : l''annonce n''est plus refusee pour `essai` (elle l''est pour son public invalide)');

ROLLBACK;
\o
\echo PX4 MODE ESSAI : tous les controles sont verts
