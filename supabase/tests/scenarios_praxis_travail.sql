-- PRAXIS-TRAVAIL (PX-3, migration 20261130100000, directeur 20/11/2026) : lire ce qui manque a un dossier, ranger en piles, proposer la
-- dispense d'entretien, objectifs. Chaque verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue s'il reste
-- un ROUGE. Couvre, par point : le cas passant, les refus, les plafonds, l'idempotence, les droits (anon et authenticated refuses), le
-- cote, le mode essai, les donnees reelles fermees, l'interrupteur, le journal.
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
  -- Praxis n'a pas de session humaine : auth.uid() est NUL (sans cela les identites posees plus haut fausseraient com_paires).
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  PERFORM pg_catalog.set_config('request.jwt.claims', '{}', true);
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.srv(text) TO authenticated, anon, service_role;


CREATE TEMP TABLE res (nom text PRIMARY KEY, ok boolean NOT NULL, detail text);
GRANT ALL ON res TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.note(p_nom text, p_ok boolean, p_detail text DEFAULT NULL) RETURNS void LANGUAGE sql AS $$
  INSERT INTO res VALUES (p_nom, coalesce(p_ok, false), p_detail) ON CONFLICT (nom) DO UPDATE SET ok = EXCLUDED.ok, detail = EXCLUDED.detail $$;
-- Une verification isolee : le bloc rend vrai ou faux ; une erreur vaut ROUGE.
CREATE FUNCTION pg_temp.verif(p_nom text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v boolean;
BEGIN
  BEGIN
    EXECUTE p_sql INTO v;
    PERFORM pg_temp.note(p_nom, v);
  EXCEPTION WHEN OTHERS THEN
    PERFORM pg_temp.note(p_nom, false, SQLSTATE || ' ' || SQLERRM);
  END;
END $$;


INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'pt-' || n || '@test.invalid' FROM generate_series(1, 30) n;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.h('1'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'PT-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'PT-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('3'), 'PT-TUT-0001', 'guardian', pg_temp.h('1'), 'Tutrice', 'Un', 'active', 'female'),
 (pg_temp.u('10'), 'PT-CAN-0010', 'teacher', NULL, 'Candidate', 'Examen', 'pending_kyc', 'female'),
 (pg_temp.u('11'), 'PT-CAN-0011', 'teacher', NULL, 'Candidat', 'Entretien', 'pending_kyc', 'male'),
 (pg_temp.u('12'), 'PT-CAN-0012', 'teacher', NULL, 'Candidate', 'Refusee', 'pending_kyc', 'female'),
 (pg_temp.u('13'), 'PT-CAN-0013', 'teacher', NULL, 'Candidate', 'Entretien', 'pending_kyc', 'female');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(10, 13) n;
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('1'));
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source, recue_le, derniere_activite) VALUES
 (pg_temp.c('10'), 'enseignant', pg_temp.u('10'), 'female', 'Prenomdix Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, 'lien_public', now() - interval '9 days', now()),
 (pg_temp.c('11'), 'enseignant', pg_temp.u('11'), 'male', 'Fixture PT homme', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public', now() - interval '2 days', now()),
 (pg_temp.c('12'), 'enseignant', pg_temp.u('12'), 'female', 'Fixture PT refusee', 'verifications', 'entretien_a_planifier', 'refusee', false, 'lien_public', now(), now()),
 (pg_temp.c('13'), 'enseignant', pg_temp.u('13'), 'female', 'Fixture PT femme entretien', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public', now(), now()),
 (pg_temp.c('14'), 'enseignant', NULL, 'female', 'Fixture PT sans compte', 'recue', NULL, 'en_cours', false, 'lien_public', now(), now());
UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = pg_catalog.clock_timestamp() WHERE id IN (pg_temp.c('10'), pg_temp.c('11'), pg_temp.c('13'));
-- Une conversation de candidature pour c10 seulement ; le candidat y a ecrit il y a 4 jours.
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id) VALUES
 (pg_temp.f('10'), 'candidature', pg_temp.c('10'), 'profil', pg_temp.u('10'), 'equipe', NULL);
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
VALUES (pg_temp.f('10'), pg_temp.u('10'), pg_temp.idem('1'), 'Bonjour, ma candidature.', pg_catalog.clock_timestamp() - interval '4 days 2 hours');
CREATE FUNCTION pg_temp.k(p_nom text) RETURNS text LANGUAGE sql AS $$ SELECT pg_temp.lu(p_nom) ->> 'secret' $$;
GRANT EXECUTE ON FUNCTION pg_temp.k(text), pg_temp.note(text, boolean, text), pg_temp.verif(text, text) TO authenticated, anon, service_role;
-- La reference d'une candidature de la fixture.
CREATE FUNCTION pg_temp.ref(p_n text) RETURNS text LANGUAGE sql AS $$ SELECT c.reference FROM public.candidatures c WHERE c.id = pg_temp.c(p_n) $$;
-- La ligne d'une candidature dans praxis_lire.
CREATE FUNCTION pg_temp.ligne(p_cle text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM pg_catalog.jsonb_array_elements(
    pg_temp.srv(pg_catalog.format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}''::jsonb, 50)', pg_temp.k(p_cle))) -> 'lignes') l(x)
   WHERE l.x ->> 'reference' = pg_temp.ref(p_n) $$;
CREATE FUNCTION pg_temp.ranger(p_cle text, p_ref text, p_pile text, p_raison text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_ranger(%L, %L, %L, %L, %L::uuid)', pg_temp.k(p_cle), p_ref, p_pile, p_raison, pg_temp.idem(p_n))) $$;
CREATE FUNCTION pg_temp.preparer(p_cle text, p_geste text, p_n text, p_param text, p_idem text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_preparer(%L, %L, %L, %L::jsonb, ''Propose par Praxis.'', %L::uuid)',
    pg_temp.k(p_cle), p_geste, pg_temp.ref(p_n), p_param, pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.fixer(p_cle text, p_periode text, p_date date, p_libelle text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_objectif_fixer(%L, %L, %L::date, %L, 5, %L::uuid)', pg_temp.k(p_cle), p_periode, p_date, p_libelle, pg_temp.idem(p_n))) $$;
CREATE FUNCTION pg_temp.clore(p_cle text, p_id text, p_etat text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_objectif_clore(%L, %L::uuid, %L, ''Note de cloture.'')', pg_temp.k(p_cle), p_id, p_etat)) $$;
GRANT EXECUTE ON FUNCTION pg_temp.ref(text), pg_temp.ligne(text, text), pg_temp.ranger(text, text, text, text, text),
  pg_temp.preparer(text, text, text, text, text), pg_temp.fixer(text, text, date, text, text), pg_temp.clore(text, text, text)
  TO authenticated, anon, service_role;

SELECT pg_temp.garde('both', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat deux cotes', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000021'::uuid)$$));
SELECT pg_temp.garde('fem', pg_temp.en(pg_temp.u('2'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat femme', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000022'::uuid)$$));

-- ===== DROITS : anon et authenticated n'executent aucun outil ; service_role n'execute aucune porte de la direction =====
SELECT pg_temp.verif('DROITS outil ' || x.f || ' : service_role seul', format(
  $v$SELECT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('authenticated', %L, 'EXECUTE') AND NOT has_function_privilege('agent_ro', %L, 'EXECUTE')$v$, x.f, x.f, x.f, x.f))
  FROM (VALUES ('public.praxis_ranger(text,text,text,text,uuid)'), ('public.praxis_objectif_fixer(text,text,date,text,integer,uuid)'),
               ('public.praxis_objectif_clore(text,uuid,text,text)'), ('public.praxis_objectifs_lire(text,text,integer)'),
               ('public.praxis_lire(text,text,jsonb,integer)'), ('public.praxis_preparer(text,text,text,jsonb,text,uuid)'),
               ('public.praxis_rendre_compte(text,integer)'), ('public.praxis_noter_refus(text,text)')) x(f);
SELECT pg_temp.verif('DROITS porte ' || x.f || ' : authenticated seul', format(
  $v$SELECT has_function_privilege('authenticated', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('agent_ro', %L, 'EXECUTE')$v$, x.f, x.f, x.f, x.f))
  FROM (VALUES ('public.direction_praxis_rangements(text,integer,integer)'), ('public.direction_praxis_objectifs(text,integer,integer)'),
               ('public.direction_praxis_valider(uuid,integer,text,uuid[])')) x(f);
SELECT pg_temp.verif('DROITS aide ' || x.f || ' : aucun role client', format(
  $v$SELECT NOT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('authenticated', %L, 'EXECUTE')$v$, x.f, x.f, x.f))
  FROM (VALUES ('private.praxis_dossier_manques(public.candidatures)'), ('private.praxis_candidat_derniere_action(public.candidatures)'),
               ('private.praxis_objectifs_json(text,integer)')) x(f);
SELECT pg_temp.verif('DROITS tables : RLS active, aucun droit client', $$
  SELECT (SELECT bool_and(c.relrowsecurity) FROM pg_class c WHERE c.oid IN ('private.praxis_rangements'::regclass, 'private.praxis_objectifs'::regclass))
     AND NOT has_table_privilege('authenticated', 'private.praxis_rangements', 'SELECT') AND NOT has_table_privilege('service_role', 'private.praxis_rangements', 'INSERT')
     AND NOT has_table_privilege('anon', 'private.praxis_objectifs', 'SELECT') AND NOT has_table_privilege('service_role', 'private.praxis_objectifs', 'SELECT') $$);
SELECT pg_temp.refus_en(NULL, NULL, format('SELECT public.praxis_ranger(%L, ''CAND-00001'', ''incomplet'', ''x'', %L::uuid)', pg_temp.k('both'), pg_temp.idem('900')),
  '42501', 'DROITS appel : anon ne peut pas appeler praxis_ranger', 'anon');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', format('SELECT public.praxis_objectifs_lire(%L, ''ouvert'', 5)', pg_temp.k('both')),
  '42501', 'DROITS appel : un administrateur connecte ne peut pas appeler praxis_objectifs_lire');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', format('SELECT public.praxis_objectif_fixer(%L, ''jour'', current_date, ''x'', NULL, %L::uuid)', pg_temp.k('both'), pg_temp.idem('901')),
  '42501', 'DROITS appel : un administrateur connecte ne peut pas appeler praxis_objectif_fixer');
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.direction_praxis_rangements()', '42501', 'DROITS appel : anon ne lit pas les rangements', 'anon');
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', 'SELECT public.direction_praxis_rangements()', '42501', 'DROITS garde : une tutrice ne lit pas les rangements');
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', 'SELECT public.direction_praxis_objectifs()', '42501', 'DROITS garde : une tutrice ne lit pas les objectifs');
SELECT pg_temp.refus_en(pg_temp.u('10'), 'teacher', 'SELECT public.direction_praxis_objectifs()', '42501', 'DROITS garde : un candidat ne lit pas les objectifs');

-- ===== PORTE : eteint, puis donnees reelles fermees =====
SELECT pg_temp.verif('PORTE eteint : ranger et objectif_fixer refusent, rien d''ecrit', $$
  SELECT pg_temp.ranger('both', pg_temp.ref('10'), 'incomplet', 'Raison.', '100') ->> 'erreur' = 'eteint'
     AND pg_temp.fixer('both', 'jour', current_date, 'Objectif.', '101') ->> 'erreur' = 'eteint'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_rangements) AND NOT EXISTS (SELECT 1 FROM private.praxis_objectifs) $$);
SELECT pg_temp.garde('on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));
SELECT pg_temp.verif('PORTE donnees reelles fermees : ranger refuse, rien d''ecrit', $$
  SELECT pg_temp.ranger('both', pg_temp.ref('10'), 'incomplet', 'Raison.', '102') ->> 'erreur' = 'donnees_reelles_fermees'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_rangements) $$);
SELECT pg_temp.verif('PORTE cle inconnue : cle_refusee', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ranger(%L, ''CAND-00001'', ''incomplet'', ''x'', %L::uuid)', 'prx_' || repeat('0', 64), pg_temp.idem('103'))) ->> 'erreur' = 'cle_refusee' $$);
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ===== 1. LIRE CE QUI MANQUE =====
SELECT pg_temp.garde('l10', pg_temp.ligne('both', '10'));
SELECT pg_temp.garde('l14', pg_temp.ligne('both', '14'));
SELECT pg_temp.verif('LIRE manquants : la candidate sans piece ni photo a une liste de codes, complet faux', $$
  SELECT jsonb_typeof(pg_temp.lu('l10') -> 'manquants') = 'array'
     AND pg_temp.lu('l10') -> 'manquants' @> '["piece_identite", "photo", "accord_publication"]'::jsonb
     AND pg_temp.lu('l10') ->> 'complet' = 'false' AND jsonb_typeof(pg_temp.lu('l10') -> 'attend_direction') = 'array' $$);
SELECT pg_temp.verif('LIRE manquants : chaque code est un code ferme (aucun texte libre)', $$
  SELECT NOT EXISTS (SELECT 1 FROM jsonb_array_elements_text((pg_temp.lu('l10') -> 'manquants') || (pg_temp.lu('l10') -> 'attend_direction')) x(code)
                      WHERE x.code !~ '^[a-z][a-z0-9_]{1,59}$') $$);
SELECT pg_temp.verif('LIRE inactivite : 4 jours depuis le dernier message du candidat (et non 9 depuis la reception, ni 0)', $$
  SELECT (pg_temp.lu('l10') ->> 'jours_sans_activite_candidat')::int = 4 $$);
SELECT pg_temp.verif('LIRE conversation : vraie pour la candidate qui a un fil, fausse pour le candidat sans fil', $$
  SELECT pg_temp.lu('l10') ->> 'a_une_conversation' = 'true' AND pg_temp.ligne('both', '11') ->> 'a_une_conversation' = 'false' $$);
SELECT pg_temp.verif('LIRE sans compte : la candidature recue sans compte manque de « compte »', $$
  SELECT pg_temp.lu('l14') -> 'manquants' = '["compte"]'::jsonb AND pg_temp.lu('l14') ->> 'complet' = 'false' $$);
SELECT pg_temp.verif('LIRE sobre : les cles d''une ligne sont la liste fermee', $$
  SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.lu('l10')) k)
       = ARRAY['a_une_conversation', 'attend_direction', 'attente_jours', 'complement_en_cours', 'complet', 'contenu_tiers', 'cote', 'etape', 'etat',
               -- PX-4 (20261130200000) : + `impression` (etiquette, note de vision, confiance de l'impression de Praxis ; aucune donnee de personne).
               'gestes', 'impression', 'jours_sans_activite_candidat', 'langue', 'manquants', 'pile', 'reference'] $$);
SELECT pg_temp.verif('LIRE sobre : ni courriel, ni nom de famille, ni identifiant de compte dans la vue', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}''::jsonb, 50)', pg_temp.k('both')))::text !~* '(test\.invalid|Nomsecret|5c1a0000)' $$);
SELECT pg_temp.verif('LIRE cote : la cle femme ne voit pas le candidat homme', $$ SELECT pg_temp.ligne('fem', '11') IS NULL AND pg_temp.ligne('fem', '10') IS NOT NULL $$);
SELECT pg_temp.verif('LIRE ferme : une candidature refusee n''est pas listee', $$ SELECT pg_temp.ligne('both', '12') IS NULL $$);
-- Un complement demande : ses codes entrent dans les manquants.
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, issue_avant, issue_apres, auteur_id, details)
VALUES (pg_temp.c('10'), 'transition', 'prequalification', 'prequalification', 'en_examen', 'a_completer', 'en_cours', 'en_cours', pg_temp.u('2'),
        '{"geste": "demander_complement", "transition": 7, "auteur": "direction", "aCompleter": ["pays_versement", "avis"]}'::jsonb);
SELECT pg_temp.verif('LIRE complement : les codes du complement en cours sont dans les manquants ; un geste de la direction ne compte pas comme activite du candidat', $$
  SELECT pg_temp.ligne('both', '10') -> 'manquants' @> '["pays_versement", "avis"]'::jsonb AND pg_temp.ligne('both', '10') ->> 'complement_en_cours' = 'true'
     AND (pg_temp.ligne('both', '10') ->> 'jours_sans_activite_candidat')::int = 4 $$);

-- ===== 2. RANGER =====
SELECT pg_temp.garde('r1', pg_temp.ranger('both', pg_temp.ref('10'), 'incomplet', 'Piece et photo manquantes.', '200'));
SELECT pg_temp.verif('RANGER ok : une ligne courante, la pile lue dans praxis_lire', $$
  SELECT pg_temp.lu('r1') ->> 'ok' = 'true' AND (SELECT count(*) FROM private.praxis_rangements WHERE candidature_id = pg_temp.c('10') AND courant) = 1
     AND pg_temp.ligne('both', '10') ->> 'pile' = 'incomplet' $$);
SELECT pg_temp.verif('RANGER rejeu : la meme cle d''idempotence n''ecrit rien', $$
  SELECT pg_temp.ranger('both', pg_temp.ref('10'), 'a_regarder', 'Autre.', '200') ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM private.praxis_rangements) = 1 AND (SELECT pile FROM private.praxis_rangements WHERE courant) = 'incomplet' $$);
SELECT pg_temp.verif('RANGER inchange : meme pile et meme raison, rien d''ecrit', $$
  SELECT pg_temp.ranger('both', pg_temp.ref('10'), 'incomplet', 'Piece et photo manquantes.', '201') ->> 'inchange' = 'true'
     AND (SELECT count(*) FROM private.praxis_rangements) = 1 $$);
SELECT pg_temp.garde('r2', pg_temp.ranger('both', pg_temp.ref('10'), 'sans_nouvelles', 'Rien depuis 4 jours.', '202'));
SELECT pg_temp.verif('RANGER historique : changer de pile ajoute une ligne, l''ancienne reste (non courante)', $$
  SELECT pg_temp.lu('r2') ->> 'pile_precedente' = 'incomplet'
     AND (SELECT count(*) FROM private.praxis_rangements WHERE candidature_id = pg_temp.c('10')) = 2
     AND (SELECT count(*) FROM private.praxis_rangements WHERE candidature_id = pg_temp.c('10') AND courant) = 1
     AND (SELECT pile FROM private.praxis_rangements WHERE candidature_id = pg_temp.c('10') AND courant) = 'sans_nouvelles' $$);
SELECT pg_temp.verif('RANGER refus : pile hors liste, raison vide, raison trop longue', $$
  SELECT pg_temp.ranger('both', pg_temp.ref('10'), 'refuser', 'x', '203') ->> 'erreur' = 'parametre'
     AND pg_temp.ranger('both', pg_temp.ref('10'), 'incomplet', '   ', '204') ->> 'erreur' = 'parametre'
     AND pg_temp.ranger('both', pg_temp.ref('10'), 'incomplet', repeat('x', 201), '205') ->> 'erreur' = 'longueur' $$);
SELECT pg_temp.verif('RANGER refus : dossier inconnu, refuse, ou de l''autre cote = la meme reponse, rien d''ecrit', $$
  SELECT pg_temp.ranger('both', 'CAND-99999999', 'incomplet', 'x', '206') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.ranger('both', pg_temp.ref('12'), 'incomplet', 'x', '207') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.ranger('fem', pg_temp.ref('11'), 'incomplet', 'x', '208') ->> 'erreur' = 'candidature_inconnue'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_rangements WHERE candidature_id IN (pg_temp.c('11'), pg_temp.c('12'))) $$);
SELECT pg_temp.garde('r11', pg_temp.ranger('both', pg_temp.ref('11'), 'pret_a_decider', 'Entretien a planifier ou dispense.', '209'));
SELECT pg_temp.verif('RANGER journal : chaque appel laisse une ligne (ok, rejoue, inchange, parametre, candidature_inconnue)', $$
  SELECT (SELECT count(DISTINCT j.issue) FROM private.praxis_journal j WHERE j.outil = 'ranger'
           AND j.issue IN ('ok', 'rejoue', 'inchange', 'parametre', 'longueur', 'candidature_inconnue', 'eteint', 'donnees_reelles_fermees')) = 8 $$);
SELECT pg_temp.garde('dr', pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_rangements()'));
SELECT pg_temp.verif('RANGER direction : la super-administration lit les deux rangements courants et le compte par pile', $$
  SELECT (pg_temp.lu('dr') ->> 'total')::int = 2 AND jsonb_array_length(pg_temp.lu('dr') -> 'rangements') = 2
     AND pg_temp.lu('dr') -> 'parPile' = '{"sans_nouvelles": 1, "pret_a_decider": 1}'::jsonb $$);
SELECT pg_temp.verif('RANGER direction : la direction femme ne voit pas le dossier du cote homme ; filtre et pagination', $$
  SELECT (pg_temp.en(pg_temp.u('2'), 'admin', 'SELECT public.direction_praxis_rangements()') ->> 'total')::int = 1
     AND (pg_temp.en(pg_temp.u('1'), 'admin', $q$SELECT public.direction_praxis_rangements('pret_a_decider')$q$) ->> 'total')::int = 1
     AND jsonb_array_length(pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_rangements(NULL, 1, 1)') -> 'rangements') = 1 $$);
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', $q$SELECT public.direction_praxis_rangements('refuser')$q$, '22023', 'RANGER direction : pile hors liste refusee');
-- Mode essai : ranger et lire refusent (l'essai ne touche aucun dossier).
UPDATE private.praxis_reglages SET essai_fils = ARRAY[pg_temp.f('10')];
SELECT pg_temp.verif('RANGER essai : refuse en mode essai, rien d''ecrit', $$
  SELECT pg_temp.ranger('both', pg_temp.ref('10'), 'a_regarder', 'x', '210') ->> 'erreur' = 'essai' AND (SELECT count(*) FROM private.praxis_rangements) = 3 $$);
UPDATE private.praxis_reglages SET essai_fils = '{}';
-- Plafond : 60 rangements ecrits par heure.
INSERT INTO private.praxis_rangements (candidature_id, pile, raison, courant, cle_id, emise_par, cle_idempotence)
SELECT gen_random_uuid(), 'a_regarder', 'Remplissage du plafond.', true, (pg_temp.lu('both') ->> 'id')::uuid, pg_temp.u('1'), gen_random_uuid() FROM generate_series(1, 57);
SELECT pg_temp.verif('RANGER plafond : le 61e rangement de l''heure est refuse, rien d''ecrit', $$
  SELECT (SELECT count(*) FROM private.praxis_rangements) = 60
     AND pg_temp.ranger('both', pg_temp.ref('13'), 'a_regarder', 'x', '211') ->> 'erreur' = 'plafond_rangements'
     AND (SELECT count(*) FROM private.praxis_rangements) = 60 $$);

-- ===== 3. DISPENSE D'ENTRETIEN =====
SELECT pg_temp.verif('DISPENSE servie : le geste figure dans les gestes d''une candidature en salle de verification, pas en salle d''examen', $$
  SELECT pg_temp.ligne('both', '11') -> 'gestes' ? 'dispenser_entretien' AND NOT (pg_temp.ligne('both', '10') -> 'gestes' ? 'dispenser_entretien') $$);
SELECT pg_temp.verif('DISPENSE refus : geste non servi pour une candidature en salle d''examen', $$
  SELECT pg_temp.preparer('both', 'dispenser_entretien', '10', '{"categorie": "autre", "motif": "Motif."}', '300') ->> 'erreur' = 'geste_non_servi' $$);
SELECT pg_temp.verif('DISPENSE refus : categorie hors liste, motif absent, cle en trop', $$
  SELECT pg_temp.preparer('both', 'dispenser_entretien', '11', '{"categorie": "ami", "motif": "Motif."}', '301') ->> 'erreur' = 'parametre'
     AND pg_temp.preparer('both', 'dispenser_entretien', '11', '{"categorie": "autre"}', '302') ->> 'erreur' = 'parametre'
     AND pg_temp.preparer('both', 'dispenser_entretien', '11', '{"categorie": "autre", "motif": "Motif.", "debut": "x"}', '303') ->> 'erreur' = 'parametre'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_propositions) $$);
SELECT pg_temp.verif('DISPENSE refus : l''autre cote ne peut pas proposer (candidature_inconnue)', $$
  SELECT pg_temp.preparer('fem', 'dispenser_entretien', '11', '{"categorie": "autre", "motif": "Motif."}', '304') ->> 'erreur' = 'candidature_inconnue' $$);
SELECT pg_temp.garde('p1', pg_temp.preparer('both', 'dispenser_entretien', '11', '{"categorie": "fondateur", "motif": "Fondateur connu de la direction."}', '305'));
SELECT pg_temp.verif('DISPENSE proposee : une proposition, le dossier n''a pas bouge', $$
  SELECT pg_temp.lu('p1') ->> 'ok' = 'true' AND (SELECT count(*) FROM private.praxis_propositions WHERE geste = 'dispenser_entretien' AND statut = 'proposee') = 1
     AND (SELECT etat FROM public.candidatures WHERE id = pg_temp.c('11')) = 'entretien_a_planifier'
     AND NOT EXISTS (SELECT 1 FROM public.candidature_dispenses_entretien) $$);
SELECT pg_temp.verif('DISPENSE rejeu et doublon : meme cle = rejoue ; une seule proposition ouverte par dossier et par geste', $$
  SELECT pg_temp.preparer('both', 'dispenser_entretien', '11', '{"categorie": "fondateur", "motif": "Fondateur connu de la direction."}', '305') ->> 'rejoue' = 'true'
     AND pg_temp.preparer('both', 'dispenser_entretien', '11', '{"categorie": "autre", "motif": "Encore."}', '306') ->> 'erreur' = 'deja_proposee'
     AND (SELECT count(*) FROM private.praxis_propositions) = 1 $$);
SELECT pg_temp.verif('DISPENSE compte rendu : une proposition attend la direction (cle des deux cotes), aucune pour la cle femme', $$
  SELECT (pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('both'))) ->> 'propositions_en_attente')::int = 1
     AND (pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('fem'))) ->> 'propositions_en_attente')::int = 0 $$);
SELECT pg_temp.verif('DISPENSE valider : la direction de l''autre cote ne peut pas valider (hors_portee), le dossier n''a pas bouge', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valider-0002'')', pg_temp.lu('p1') ->> 'id',
           (SELECT version FROM public.candidatures WHERE id = pg_temp.c('11')))) ->> 'erreur' = 'hors_portee'
     AND (SELECT etat FROM public.candidatures WHERE id = pg_temp.c('11')) = 'entretien_a_planifier' $$);
SELECT pg_temp.garde('v1', pg_temp.en(pg_temp.u('1'), 'admin', format('SELECT public.direction_praxis_valider(%L::uuid, %s, ''cle-valider-0003'')', pg_temp.lu('p1') ->> 'id',
           (SELECT version FROM public.candidatures WHERE id = pg_temp.c('11')))));
SELECT pg_temp.verif('DISPENSE validee : le geste est execute par la porte humaine (etat decision_en_attente, dispense tracee au nom de la direction)', $$
  SELECT pg_temp.lu('v1') ->> 'ok' = 'true' AND (SELECT etat FROM public.candidatures WHERE id = pg_temp.c('11')) = 'decision_en_attente'
     AND (SELECT count(*) FROM public.candidature_dispenses_entretien d WHERE d.candidature_id = pg_temp.c('11') AND d.categorie = 'fondateur'
           AND d.auteur_id = pg_temp.u('1') AND d.motif = 'Fondateur connu de la direction.') = 1
     AND (SELECT statut FROM private.praxis_propositions WHERE id = (pg_temp.lu('p1') ->> 'id')::uuid) = 'validee' $$);
SELECT pg_temp.verif('DISPENSE validee : rejouer la validation avec la meme cle ne refait rien', $$
  SELECT pg_temp.en(pg_temp.u('1'), 'admin', format('SELECT public.direction_praxis_valider(%L::uuid, 1, ''cle-valider-0003'')', pg_temp.lu('p1') ->> 'id')) ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM public.candidature_dispenses_entretien) = 1 $$);
SELECT pg_temp.verif('DISPENSE apres : le geste n''est plus servi (decision_en_attente)', $$
  SELECT NOT (pg_temp.ligne('both', '11') -> 'gestes' ? 'dispenser_entretien') $$);
-- Les trois gestes d'avant restent acceptes par le CHECK ; un geste inconnu est refuse par le CHECK.
SELECT pg_temp.verif('DISPENSE check : la table refuse un geste hors des quatre', $$
  SELECT (SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c WHERE c.conname = 'praxis_propositions_geste_check') ~ 'dispenser_entretien'
     AND (SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c WHERE c.conname = 'praxis_propositions_geste_check') ~ 'admettre_verifications'
     AND (SELECT pg_get_constraintdef(c.oid) FROM pg_constraint c WHERE c.conname = 'praxis_propositions_geste_check') !~ 'refuser' $$);
SELECT pg_temp.verif('PREPARER inchange : un geste hors liste reste refuse (parametre)', $$
  SELECT pg_temp.preparer('both', 'refuser', '13', '{}', '307') ->> 'erreur' = 'parametre' $$);

-- ===== 4. OBJECTIFS =====
SELECT pg_temp.garde('o1', pg_temp.fixer('both', 'jour', current_date, 'Ranger vingt dossiers.', '400'));
SELECT pg_temp.verif('OBJECTIF ok : fixe, lu dans objectifs_lire et dans rendre_compte', $$
  SELECT pg_temp.lu('o1') ->> 'ok' = 'true'
     AND jsonb_array_length(pg_temp.srv(format('SELECT public.praxis_objectifs_lire(%L, ''ouvert'', 20)', pg_temp.k('both'))) -> 'objectifs') = 1
     AND pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('both'))) -> 'objectifs_ouverts' -> 0 ->> 'libelle' = 'Ranger vingt dossiers.' $$);
SELECT pg_temp.verif('OBJECTIF rejeu : la meme cle d''idempotence n''ecrit rien', $$
  SELECT pg_temp.fixer('both', 'jour', current_date, 'Autre.', '400') ->> 'rejoue' = 'true' AND (SELECT count(*) FROM private.praxis_objectifs) = 1 $$);
SELECT pg_temp.garde('o2', pg_temp.fixer('both', 'jour', current_date, 'Deux.', '401'));
SELECT pg_temp.garde('o3', pg_temp.fixer('both', 'jour', current_date, 'Trois.', '402'));
SELECT pg_temp.garde('o4', pg_temp.fixer('both', 'jour', current_date, 'Quatre.', '403'));
SELECT pg_temp.garde('o5', pg_temp.fixer('both', 'jour', current_date + 1, 'Demain.', '404'));
SELECT pg_temp.verif('OBJECTIF plafond : 3 ouverts par jour, le 4e refuse ; un autre jour reste possible', $$
  SELECT pg_temp.lu('o2') ->> 'ok' = 'true' AND pg_temp.lu('o3') ->> 'ok' = 'true'
     AND pg_temp.lu('o4') ->> 'erreur' = 'plafond_objectifs'
     AND pg_temp.lu('o5') ->> 'ok' = 'true'
     AND (SELECT count(*) FROM private.praxis_objectifs) = 4 $$);
SELECT pg_temp.verif('OBJECTIF semaine : range sous son lundi ; 3 ouverts par semaine, le 4e refuse (meme semaine, autre jour)', $$
  SELECT (pg_temp.fixer('both', 'semaine', current_date, 'S1.', '410') ->> 'debut')::date = date_trunc('week', current_date::timestamp)::date
     AND pg_temp.fixer('both', 'semaine', date_trunc('week', current_date::timestamp)::date, 'S2.', '411') ->> 'ok' = 'true'
     AND pg_temp.fixer('both', 'semaine', current_date, 'S3.', '412') ->> 'ok' = 'true'
     AND pg_temp.fixer('both', 'semaine', date_trunc('week', current_date::timestamp)::date, 'S4.', '413') ->> 'erreur' = 'plafond_objectifs' $$);
-- Revue du 20/11/2026 : la semaine PRECEDENTE (la veille du lundi en cours) est refusee, quel que soit le jour de la semaine.
SELECT pg_temp.verif('OBJECTIF semaine passee : la veille du lundi de la semaine en cours est refusee `parametre`, rien d''ecrit', $$
  SELECT pg_temp.fixer('both', 'semaine', date_trunc('week', current_date::timestamp)::date - 1, 'Semaine passee.', '414') ->> 'erreur' = 'parametre'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_objectifs o WHERE o.libelle = 'Semaine passee.') $$);
SELECT pg_temp.verif('OBJECTIF refus : periode hors liste, date trop loin, libelle vide, libelle trop long, cible hors bornes', $$
  SELECT pg_temp.fixer('both', 'mois', current_date, 'x', '420') ->> 'erreur' = 'parametre'
     AND pg_temp.fixer('both', 'jour', current_date + 30, 'x', '421') ->> 'erreur' = 'parametre'
     AND pg_temp.fixer('both', 'jour', current_date, '  ', '422') ->> 'erreur' = 'parametre'
     AND pg_temp.fixer('both', 'jour', current_date + 2, repeat('x', 201), '423') ->> 'erreur' = 'longueur'
     AND pg_temp.srv(format('SELECT public.praxis_objectif_fixer(%L, ''jour'', current_date + 2, ''x'', 0, %L::uuid)', pg_temp.k('both'), pg_temp.idem('424'))) ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.garde('c1', pg_temp.clore('both', pg_temp.lu('o1') ->> 'id', 'atteint'));
SELECT pg_temp.verif('OBJECTIF clore : atteint, puis rejeu, puis deja_clos, puis inconnu ; la place se libere', $$
  SELECT pg_temp.lu('c1') ->> 'ok' = 'true'
     AND pg_temp.clore('both', pg_temp.lu('o1') ->> 'id', 'atteint') ->> 'rejoue' = 'true'
     AND pg_temp.clore('both', pg_temp.lu('o1') ->> 'id', 'abandonne') ->> 'erreur' = 'deja_clos'
     AND pg_temp.clore('both', gen_random_uuid()::text, 'atteint') ->> 'erreur' = 'inconnu'
     AND pg_temp.clore('both', pg_temp.lu('o1') ->> 'id', 'ouvert') ->> 'erreur' = 'parametre'
     AND (SELECT etat = 'atteint' AND clos_le IS NOT NULL AND note_cloture = 'Note de cloture.' FROM private.praxis_objectifs WHERE id = (pg_temp.lu('o1') ->> 'id')::uuid)
     AND pg_temp.fixer('both', 'jour', current_date, 'Quatre, apres cloture.', '430') ->> 'ok' = 'true' $$);
SELECT pg_temp.verif('OBJECTIF direction : la direction lit les ouverts (7) et tous (8), pagines', $$
  SELECT (pg_temp.en(pg_temp.u('2'), 'admin', 'SELECT public.direction_praxis_objectifs()') ->> 'total')::int = 7
     AND (pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.direction_praxis_objectifs('tous', 3, 0)$q$) ->> 'total')::int = 8
     AND jsonb_array_length(pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.direction_praxis_objectifs('tous', 3, 6)$q$) -> 'objectifs') = 2 $$);
SELECT pg_temp.verif('OBJECTIF journal : chaque appel laisse une ligne', $$
  SELECT (SELECT count(DISTINCT j.issue) FROM private.praxis_journal j WHERE j.outil = 'objectif_fixer' AND j.issue IN ('ok', 'rejoue', 'parametre', 'longueur', 'plafond_objectifs', 'eteint')) = 6
     AND (SELECT count(DISTINCT j.issue) FROM private.praxis_journal j WHERE j.outil = 'objectif_clore' AND j.issue IN ('ok', 'rejoue', 'deja_clos', 'inconnu', 'parametre')) = 5
     AND EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'objectifs_lire' AND j.issue = 'ok') $$);
SELECT pg_temp.verif('REFUS de parametre : praxis_noter_refus connait les outils neufs, pas un outil invente', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''ranger'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''objectif_fixer'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''supprimer'')', pg_temp.k('both'))) ->> 'ok' = 'false' $$);
-- Eteint : plus rien ne passe.
SELECT pg_temp.garde('off', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(false, false, NULL)$$));
SELECT pg_temp.verif('INTERRUPTEUR : eteint, lire, ranger, preparer et les objectifs refusent', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', ''{}''::jsonb, 5)', pg_temp.k('both'))) ->> 'erreur' = 'eteint'
     AND pg_temp.ranger('both', pg_temp.ref('13'), 'a_regarder', 'x', '500') ->> 'erreur' = 'eteint'
     AND pg_temp.preparer('both', 'dispenser_entretien', '13', '{"categorie": "autre", "motif": "m"}', '501') ->> 'erreur' = 'eteint'
     AND pg_temp.srv(format('SELECT public.praxis_objectifs_lire(%L, ''ouvert'', 5)', pg_temp.k('both'))) ->> 'erreur' = 'eteint'
     AND pg_temp.clore('both', gen_random_uuid()::text, 'atteint') ->> 'erreur' = 'eteint' $$);

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 90) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN RAISE EXCEPTION 'PRAXIS-TRAVAIL : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok); END IF;
END $$;
ROLLBACK;
