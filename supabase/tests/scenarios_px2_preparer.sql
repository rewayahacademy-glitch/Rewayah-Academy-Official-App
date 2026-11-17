-- PX-2 PRAXIS niveau B (migration 20261129840000) : Praxis LIT les dossiers et PREPARE des propositions. Les neuf scenarios du cahier :
--  1 donnees_reelles faux : praxis_lire, praxis_preparer et les outils de PX-1 refuses (PX-1 limite au mode essai) ; la porte du
--    directeur exige l'aal2 ; vrai, l'acces s'ouvre ;
--  2 aucune reponse de praxis_lire ne contient courriel, telephone, piece, photo, note, motif ni montant (les cles de chaque ligne sont
--    une liste fermee) ; le prenom est dans contenu_tiers ; `demandes` ne rend que des compteurs ;
--  3 une cle de direction d'un cote ne lit que ce cote ;
--  4 praxis_preparer n'ecrit qu'une ligne dans praxis_propositions : 0 ligne ecrite dans les tables de candidature ;
--  5 un geste non servi pour la ligne est refuse (geste_non_servi) ; un dossier inconnu, un autre cote, un parametre hors liste aussi ;
--  6 la validation par une direction execute le geste par la porte publique ; l'evenement porte l'identite de CETTE direction ;
--  7 ecarter, ou laisser expirer, ne fait rien sur le dossier ;
--  8 le plafond (50 ouvertes) et l'idempotence tiennent ;
--  9 un dossier qui a change d'etat depuis : la validation est refusee par le moteur, avec sa phrase, la proposition reste ouverte.
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
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'PX2 ROUGE : %', p_label; END IF;
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
  IF v_passe THEN RAISE EXCEPTION 'PX2 ROUGE : % (aucun refus)', p_label; END IF;
  IF v_code <> p_code THEN RAISE EXCEPTION 'PX2 ROUGE : % (code % au lieu de %)', p_label, v_code, p_code; END IF;
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

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b2000000-0000-4000-8000-0000000000' || p)::uuid $$;
CREATE FUNCTION pg_temp.c(p text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b2cccccc-0000-4000-8000-0000000000' || p)::uuid $$;
CREATE FUNCTION pg_temp.idem(p integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b2111111-0000-4000-8000-' || lpad(p::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.v(p text) RETURNS integer LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p) $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.c(text), pg_temp.idem(integer), pg_temp.v(text) TO authenticated, anon, service_role;

-- Fixtures : a1 direction homme (super-administration : les deux cotes), a2 direction femme (son cote seulement), tuteur t1.
-- Candidatures d'enseignants : 01 homme et 02 femme en examen ; 03 homme en salle de verification ; 04 homme en examen (contact et piece
-- renseignes pour prouver qu'ils ne sortent jamais) ; 05 une famille (compteurs seulement).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) SELECT pg_temp.u(s), 'px2-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'a2', '01', '02', '03', '04', '05']) s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
  (pg_temp.u('a1'), 'PX2-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male'),
  (pg_temp.u('a2'), 'PX2-ADM-0002', 'admin', 'Direction', 'Deux', 'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  SELECT pg_temp.u(s), 'PX2-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', CASE WHEN s = '02' THEN 'female'::public.gender ELSE 'male'::public.gender END
  FROM unnest(ARRAY['01', '02', '03', '04']) s;
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('a1'));
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, langue)
  SELECT pg_temp.c(v.s), 'enseignant', pg_temp.u(v.s), v.g::public.gender, 'Prenom' || v.s || ' Fictif', v.etape, v.etat, 'en_cours', 'lien_public', 'fr'
  FROM (VALUES ('01', 'male', 'prequalification', 'en_examen'), ('02', 'female', 'prequalification', 'en_examen'),
               ('03', 'male', 'verifications', 'entretien_a_planifier'), ('04', 'male', 'prequalification', 'en_examen')) v(s, g, etape, etat);
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
  VALUES (pg_temp.c('05'), 'famille', pg_temp.u('05'), 'female', 'Famille Fictive', 'recue', NULL, 'en_cours', 'lien_public');
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
  VALUES (pg_temp.c('04'), 'secret.px2@test.invalid', '+33699887766');
SET LOCAL session_replication_role = origin;

-- Les cles : emises par la direction en aal2 (a1 : les deux cotes ; a2 : le cote femme).
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Cle A', 'chat', pg_catalog.now() + interval '30 days', 'b2222222-0000-4000-8000-000000000001'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle_a \gset
SELECT pg_temp.appel(pg_temp.u('a2'), 'admin', 'aal2', $$SELECT public.direction_praxis_emettre_cle(
  'Cle B', 'chat', pg_catalog.now() + interval '30 days', 'b2222222-0000-4000-8000-000000000002'::uuid)$$) AS j \gset
SELECT :'j'::jsonb ->> 'secret' AS cle_b \gset
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', 'SELECT public.direction_praxis_regler(true, false, 100)');

-- Une empreinte de toutes les tables de candidature (pour prouver qu'un outil de Praxis n'y a rien ecrit).
CREATE FUNCTION pg_temp.empreinte_candidatures() RETURNS text LANGUAGE plpgsql AS $$
DECLARE r record; v_t text := ''; v_h text;
BEGIN
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname LIKE 'candidature%' ORDER BY c.relname LOOP
    EXECUTE format('SELECT md5(coalesce(string_agg(t::text, ''|'' ORDER BY t::text), '''')) FROM public.%I t', r.relname) INTO v_h;
    v_t := v_t || r.relname || ':' || v_h || ';';
  END LOOP;
  RETURN md5(v_t);
END $$;
SELECT pg_temp.empreinte_candidatures() AS e0 \gset
SELECT count(*) AS nb_prop0 FROM private.praxis_propositions \gset

-- ============ 1 : donnees_reelles faux ============
SELECT pg_temp.vrai(NOT (SELECT donnees_reelles FROM private.praxis_reglages), '1 : donnees_reelles est faux apres installation');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}'', 20)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"donnees_reelles_fermees"}'::jsonb, '1 : praxis_lire est refuse');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Il manque les langues.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), pg_temp.idem(1))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"donnees_reelles_fermees"}'::jsonb AND (SELECT count(*) FROM private.praxis_propositions) = :nb_prop0,
  '1 : praxis_preparer est refuse, aucune proposition ecrite');
SELECT pg_temp.srv(format('SELECT public.praxis_annoncer(%L, ARRAY[''familles''], ''T'', ''Annonce.'', %L::uuid)', :'cle_a', pg_temp.idem(2))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"donnees_reelles_fermees"}'::jsonb, '1 : PX-1 limite au mode essai : l''annonce est refusee');
SELECT pg_temp.refus(pg_temp.u('a1'), 'admin', 'aal1', 'SELECT public.direction_praxis_regler_donnees_reelles(true)', '42501', '1 : sans aal2, refus');
SELECT pg_temp.refus(pg_temp.u('01'), 'teacher', 'aal2', 'SELECT public.direction_praxis_regler_donnees_reelles(true)', '42501', '1 : un enseignant, refus');
SELECT pg_temp.vrai(NOT (SELECT donnees_reelles FROM private.praxis_reglages), '1 : les refus n''ont rien change');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', 'SELECT public.direction_praxis_regler_donnees_reelles(true)') AS j \gset
SELECT pg_temp.vrai((SELECT donnees_reelles FROM private.praxis_reglages) AND (SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_regle_donnees_reelles') = 1,
  '1 : le directeur en aal2 ouvre les donnees reelles, une ligne d''audit');

-- ============ 2 : rien de sensible ============
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}'', 50)', :'cle_a')) AS lu \gset
SELECT pg_temp.vrai(jsonb_array_length(:'lu'::jsonb -> 'lignes') = 4 AND (:'lu'::jsonb ->> 'total')::int = 4,
  '2 : la vue candidatures rend les 4 enseignants (pas la famille)');
SELECT pg_temp.vrai(:'lu'::text !~* '(@|secret|0699|\+33|telephone|courriel|email|piece|photo|note|motif|montant|paiement|iban)',
  '2 : aucune reponse ne contient courriel, telephone, piece, photo, note, motif ni montant');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(:'lu'::jsonb -> 'lignes') l
    WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(l) k)
          <> ARRAY['attente_jours', 'complement_en_cours', 'contenu_tiers', 'cote', 'etape', 'etat', 'gestes', 'langue', 'reference']),
  '2 : les cles de chaque ligne sont une liste fermee');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(:'lu'::jsonb -> 'lignes') l
    WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(l -> 'contenu_tiers') k) <> ARRAY['prenom']
       OR l ->> 'prenom' IS NOT NULL),
  '2 : le prenom, seul texte de personne, est dans contenu_tiers');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''demandes'', ''{}'', 50)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"vue":"demandes","compteurs":[{"population":"famille","etape":"recue","nombre":1}]}'::jsonb,
  '2 : la vue demandes ne rend que des compteurs');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''profiles'', ''{}'', 50)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '2 : une vue hors liste est refusee');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{"requete":"x"}'', 50)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '2 : un filtre hors liste est refuse (aucune requete libre)');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{"etape":"verifications"}'', 50)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'lignes') = 1 AND :'j'::jsonb -> 'lignes' -> 0 ->> 'etape' = 'verifications',
  '2 : le filtre par etape fonctionne');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}'', 51)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '2 : plus de 50 lignes, refus');

-- ============ 3 : les cotes de l'emetteur ============
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}'', 50)', :'cle_b')) AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb -> 'lignes') = 1 AND :'j'::jsonb -> 'lignes' -> 0 ->> 'cote' = 'female',
  '3 : la cle d''une direction femme ne lit que le cote femme (1 ligne)');
SELECT pg_temp.vrai(jsonb_array_length(:'lu'::jsonb -> 'lignes') = 4, '3 : la cle de la super-administration lit les deux cotes');

-- ============ 4 : une proposition, rien d'autre ============
SELECT pg_temp.empreinte_candidatures() AS e1 \gset
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Il manque les langues.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), pg_temp.idem(10))) AS j \gset
SELECT :'j'::jsonb ->> 'id' AS p1 \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND (SELECT count(*) FROM private.praxis_propositions) = :nb_prop0 + 1
  AND (SELECT statut FROM private.praxis_propositions WHERE id = :'p1'::uuid) = 'proposee',
  '4 : une proposition ecrite, statut proposee');
SELECT pg_temp.vrai(pg_temp.empreinte_candidatures() = :'e1', '4 : 0 ligne ecrite dans les tables de candidature');
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_journal WHERE outil = 'preparer' AND issue = 'ok') = 1, '4 : l''appel est journalise');

-- ============ 5 : geste non servi, dossier inconnu, autre cote, parametres ============
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''planifier_entretien'', %L, %L, ''Entretien.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')),
  json_build_object('debut', (now() + interval '3 days')::text, 'duree_minutes', 30)::text, pg_temp.idem(12))) AS j2 \gset
SELECT pg_temp.vrai(:'j2'::jsonb = '{"erreur":"geste_non_servi"}'::jsonb,
  '5 : planifier un entretien pour un dossier en examen : geste_non_servi (le moteur ne le sert pas pour cette ligne)');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', ''CAND-INCONNUE'', ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''X.'', %L::uuid)',
  :'cle_a', pg_temp.idem(13))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"candidature_inconnue"}'::jsonb, '5 : un dossier inconnu est refuse');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''X.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('05')), pg_temp.idem(14))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"candidature_inconnue"}'::jsonb, '5 : une demande d''admission (famille) n''est pas une candidature pour Praxis');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''X.'', %L::uuid)',
  :'cle_b', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), pg_temp.idem(15))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"cote"}'::jsonb, '5 : un dossier de l''autre cote est refuse');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["rien_de_tel"],"motif":"x"}'', ''X.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('02')), pg_temp.idem(16))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' = 'elements_invalides', '5 : une piece hors de la liste fermee du moteur est refusee');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"x","courriel":"x@y.z"}'', ''X.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('02')), pg_temp.idem(17))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '5 : un parametre hors liste est refuse');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''supprimer_dossier'', %L, ''{}'', ''X.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('02')), pg_temp.idem(18))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"parametre"}'::jsonb, '5 : un geste hors de la liste fermee est refuse');
SELECT pg_temp.vrai(pg_temp.empreinte_candidatures() = :'e1' AND (SELECT count(*) FROM private.praxis_propositions) = :nb_prop0 + 1,
  '5 : aucun de ces refus n''a ecrit quoi que ce soit');

-- ============ 8 (idempotence) ============
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Il manque les langues.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), pg_temp.idem(10))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'rejoue')::boolean AND :'j'::jsonb ->> 'id' = :'p1' AND (SELECT count(*) FROM private.praxis_propositions) = :nb_prop0 + 1,
  '8 : la meme cle d''idempotence rejoue la meme proposition, rien d''ecrit');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Autre texte.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), pg_temp.idem(19))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"deja_proposee"}'::jsonb, '8 : une seule proposition ouverte par dossier et par geste');

-- ============ 6 : la validation, sous l'identite de la direction ============
SELECT pg_temp.refus(pg_temp.u('a1'), 'admin', 'aal1', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-001'')', :'p1', pg_temp.v('01')), '42501',
  '6 : valider sans aal2, refus');
SELECT pg_temp.refus(pg_temp.u('01'), 'teacher', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-001'')', :'p1', pg_temp.v('01')), '42501',
  '6 : valider par un enseignant, refus');
SELECT pg_temp.vrai((SELECT statut FROM private.praxis_propositions WHERE id = :'p1'::uuid) = 'proposee' AND pg_temp.empreinte_candidatures() = :'e1',
  '6 : ces refus n''ont rien change');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal1', 'SELECT public.direction_praxis_propositions(''ouvertes'')') AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb) = 1 AND :'j'::jsonb -> 0 ->> 'id' = :'p1' AND :'j'::jsonb -> 0 ->> 'statut' = 'proposee'
  AND (:'j'::jsonb -> 0 ->> 'versionProposee')::int = pg_temp.v('01'),
  '6 : la direction lit les propositions ouvertes (sans aal2)');
SELECT pg_temp.appel(pg_temp.u('a2'), 'admin', 'aal1', 'SELECT public.direction_praxis_propositions(''ouvertes'')') AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb) = 0, '6 : une direction du cote femme ne voit pas la proposition d''un dossier homme');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-001'')', :'p1', pg_temp.v('01'))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND NOT (:'j'::jsonb -> 'resultat') ? 'erreur', '6 : la validation reussit par la porte publique ' || :'j');
SELECT pg_temp.vrai((SELECT etat FROM public.candidatures WHERE id = pg_temp.c('01')) = 'a_completer'
  AND (SELECT statut FROM private.praxis_propositions WHERE id = :'p1'::uuid) = 'validee'
  AND (SELECT traitee_par FROM private.praxis_propositions WHERE id = :'p1'::uuid) = pg_temp.u('a1'),
  '6 : le dossier est passe a completer, la proposition est validee par a1');
SELECT pg_temp.vrai((SELECT auteur_id FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('01') AND type = 'transition'
                      ORDER BY id DESC LIMIT 1) = pg_temp.u('a1')
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements WHERE auteur_id = private.praxis_profil()),
  '6 : l''evenement porte l''identite de la direction qui a valide, jamais celle de Praxis');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-001'')', :'p1', 1)) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'rejoue')::boolean, '6 : rejouer la meme validation rend le meme resultat, rien de plus');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-002'')', :'p1', 1)) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"proposition_validee"}'::jsonb, '6 : une proposition validee ne se valide pas une seconde fois');

-- ============ 7 : ecarter, ou expirer, ne fait rien sur le dossier ============
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Pour 02.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('02')), pg_temp.idem(20))) AS j \gset
SELECT :'j'::jsonb ->> 'id' AS p2 \gset
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Pour 04.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('04')), pg_temp.idem(21))) AS j \gset
SELECT :'j'::jsonb ->> 'id' AS p3 \gset
SELECT pg_temp.empreinte_candidatures() AS e2 \gset
SELECT pg_temp.refus(pg_temp.u('a1'), 'admin', 'aal1', format('SELECT public.direction_praxis_ecarter(%L::uuid, ''non'', ''b2333333-0000-4000-8000-000000000001''::uuid)', :'p2'), '42501',
  '7 : ecarter sans aal2, refus');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_ecarter(%L::uuid, ''Pas pour l''''instant'', ''b2333333-0000-4000-8000-000000000001''::uuid)', :'p2')) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND (SELECT statut FROM private.praxis_propositions WHERE id = :'p2'::uuid) = 'ecartee'
  AND pg_temp.empreinte_candidatures() = :'e2', '7 : ecarter marque la proposition ecartee et ne touche pas au dossier');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-003'')', :'p2', pg_temp.v('02'))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"proposition_ecartee"}'::jsonb AND pg_temp.empreinte_candidatures() = :'e2', '7 : une proposition ecartee ne se valide plus');
UPDATE private.praxis_propositions SET expire_le = now() - interval '1 minute' WHERE id = :'p3'::uuid;
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal1', 'SELECT public.direction_praxis_propositions(''ouvertes'')') AS j \gset
SELECT pg_temp.vrai(jsonb_array_length(:'j'::jsonb) = 0, '7 : une proposition expiree n''est plus dans les ouvertes');
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-004'')', :'p3', pg_temp.v('04'))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"proposition_expiree"}'::jsonb AND pg_temp.empreinte_candidatures() = :'e2'
  AND (SELECT statut FROM private.praxis_propositions WHERE id = :'p3'::uuid) = 'expiree',
  '7 : une proposition expiree ne se valide plus et ne fait rien sur le dossier');

-- ============ 9 : le dossier a change depuis ============
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''admettre_verifications'', %L, ''{}'', ''Admettre 04.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('04')), pg_temp.idem(22))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' IS NULL OR :'j'::jsonb ->> 'erreur' = 'geste_non_servi', '9 : (preparation de la proposition de scenario, ou geste non servi)');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Relance 04.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('04')), pg_temp.idem(23))) AS j \gset
SELECT :'j'::jsonb ->> 'id' AS p4 \gset
SELECT pg_temp.vrai(:'p4' IS NOT NULL AND :'p4' <> '', '9 : proposition pour 04 prete');
-- Un humain change le dossier de 04 entre-temps (par la porte publique) : la version avance.
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format(
  'SELECT public.demander_complement_candidat(%L, ARRAY[''piece_identite''], ''Autre demande'', %s, ''cle-humain-04'')', pg_temp.c('04'), pg_temp.v('04'))) AS j \gset
SELECT pg_temp.vrai(NOT :'j'::jsonb ? 'erreur', '9 : un humain a change le dossier de 04 entre-temps');
SELECT pg_temp.empreinte_candidatures() AS e3 \gset
SELECT version_candidature AS v_prop FROM private.praxis_propositions WHERE id = :'p4'::uuid \gset
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valide-005'')', :'p4', :v_prop)) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ? 'erreur' AND :'j'::jsonb ->> 'proposition' = :'p4' AND :'j'::jsonb ->> 'erreur' <> 'proposition_perimee',
  '9 : la validation est refusee PAR LE MOTEUR (sa phrase : ' || coalesce(:'j'::jsonb ->> 'erreur', '?') || ')');
SELECT pg_temp.vrai((SELECT statut FROM private.praxis_propositions WHERE id = :'p4'::uuid) = 'proposee' AND pg_temp.empreinte_candidatures() = :'e3',
  '9 : le dossier n''a pas bouge et la proposition reste ouverte (on peut l''ecarter)');

-- ============ 8 : le plafond ============
INSERT INTO private.praxis_propositions (geste, candidature_id, version_candidature, texte, cle_id, emise_par, cle_idempotence, expire_le)
  SELECT 'demander_complement', pg_catalog.gen_random_uuid(), 1, 'Remplissage.', (SELECT id FROM private.praxis_cles LIMIT 1),
         pg_temp.u('a1'), pg_catalog.gen_random_uuid(), now() + interval '1 day'
  FROM generate_series(1, 50 - (SELECT count(*)::int FROM private.praxis_propositions WHERE statut = 'proposee')) n;
SELECT pg_temp.vrai((SELECT count(*) FROM private.praxis_propositions WHERE statut = 'proposee') = 50, '8 : 50 propositions ouvertes (remplissage)');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Une de trop.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('02')), pg_temp.idem(24))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"plafond_propositions"}'::jsonb AND (SELECT count(*) FROM private.praxis_propositions WHERE statut = 'proposee') = 50,
  '8 : la 51e proposition ouverte est refusee (plafond de 50)');
SELECT pg_temp.srv(format('SELECT public.praxis_preparer(%L, ''demander_complement'', %L, ''{"elements":["langues"],"motif":"Il manque les langues."}'', ''Il manque les langues.'', %L::uuid)',
  :'cle_a', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('01')), pg_temp.idem(10))) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'rejoue')::boolean, '8 : meme au plafond, un rejeu d''idempotence reste un rejeu');

-- ============ M4 : la note d'un refus de parametre connait lire et preparer ============
SELECT pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''lire'')', :'cle_a')) AS j \gset
SELECT pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''preparer'')', :'cle_a')) AS j2 \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND (:'j2'::jsonb ->> 'ok')::boolean, 'M4 : le refus de parametre de lire et de preparer est journalise');

-- ============ Eteint : tout est refuse ============
SELECT pg_temp.appel(pg_temp.u('a1'), 'admin', 'aal2', 'SELECT public.direction_praxis_regler(false, NULL, NULL)');
SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}'', 20)', :'cle_a')) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur":"eteint"}'::jsonb, 'eteint : praxis_lire est refuse quand Praxis est eteint');

ROLLBACK;
\o
\echo PX2 PREPARER : tous les controles sont verts
