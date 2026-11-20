-- PRAXIS PX-5 (migration 20261130300000, 20/11/2026) : Praxis sait ou en est la personne qui lui ecrit (`dossier` dans `boite` et `fil`),
-- pagine `lire` (`decalage`, `fil`, `total`), ferme ses propres questions (`questions_ouvertes`, `retirer_question`), et le plafond des
-- ouvertures de dialogue devient 100 par 5 heures glissantes, reglable (directeur, 20/11/2026).
-- Chaque verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue s'il reste un ROUGE. Les aides du debut sont
-- celles de scenarios_praxis_dossier_complet.sql. La preuve A PLUSIEURS SESSIONS du plafond (verrou) est dans
-- supabase/tests/concurrence_praxis_px5.sh (elle a besoin de donnees validees, hors de cette transaction).
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
CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true); $$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb; $$;
-- Un appel sous le role authenticated, au nom d'un compte (aal2 par defaut).
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text, p_aal text DEFAULT 'aal2') RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
-- Le code SQLSTATE d'un appel (NULL s'il passe), sous un role donne ; l'appel ne laisse rien (sous-transaction annulee).
CREATE FUNCTION pg_temp.code_en(p_id uuid, p_role text, p_sql text, p_db_role text DEFAULT 'authenticated', p_aal text DEFAULT 'aal2') RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v_code text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    RAISE EXCEPTION 'PASSE' USING ERRCODE = 'P0042';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
  END;
  EXECUTE 'RESET ROLE';
  RETURN CASE WHEN v_code = 'P0042' THEN NULL ELSE v_code END;
END $$;
CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1b0000-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1bcccc-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.f(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1bffff-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1b1111-0000-4000-8000-' || lpad(p_n, 12, '0'))::uuid $$;
-- Un appel d'outil Praxis : le role service_role (le seul qui l'execute), sans session humaine.
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  PERFORM pg_catalog.set_config('request.jwt.claims', '{}', true);
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE TEMP TABLE res (nom text PRIMARY KEY, ok boolean NOT NULL, detail text);
GRANT ALL ON res TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.note(p_nom text, p_ok boolean, p_detail text DEFAULT NULL) RETURNS void LANGUAGE sql AS $$
  INSERT INTO res VALUES (p_nom, coalesce(p_ok, false), p_detail) ON CONFLICT (nom) DO UPDATE SET ok = EXCLUDED.ok, detail = EXCLUDED.detail $$;
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
-- Une verification dont les ecritures de preparation sont ANNULEES.
CREATE FUNCTION pg_temp.verif_annule(p_nom text, p_prep text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v boolean;
BEGIN
  BEGIN
    EXECUTE p_prep;
    EXECUTE p_sql INTO v;
    RAISE EXCEPTION 'ANNULE:%', coalesce(v, false);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'ANNULE:%' THEN PERFORM pg_temp.note(p_nom, SQLERRM = 'ANNULE:t');
    ELSE PERFORM pg_temp.note(p_nom, false, SQLSTATE || ' ' || SQLERRM); END IF;
  END;
END $$;

-- Un compte lu APRES les appels qui precedent dans la meme verification (une sous-requete simple garderait l'image d'avant les appels).
CREATE FUNCTION pg_temp.n(p_sql text) RETURNS bigint LANGUAGE plpgsql VOLATILE AS $$
DECLARE v bigint;
BEGIN EXECUTE 'SELECT count(*) FROM ' || p_sql INTO v; RETURN v; END $$;

-- ===== Fixture =====
-- c10 : admise en verification il y a 3 jours ; la direction lui avait ecrit AVANT (5 jours), personne depuis : NON informee.
-- c12 : admise il y a 3 jours, la direction a ecrit il y a 2 jours : informee. c13 : admise il y a 3 jours, Praxis a ecrit depuis : informee.
-- c14 : restreinte (sa conversation reste lisible, son dossier est FERME : dossier null). c11 : l'autre cote (homme).
-- c16 a c19 : sans conversation (pagination, ouvertures).
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'px5-' || n || '@test.invalid' FROM generate_series(1, 30) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'P5-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'P5-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(n::text), 'P5-CAN-00' || n, 'teacher', NULL, 'Prenomsecret' || n, 'Famillesecrete', 'pending_kyc',
       CASE WHEN n = 11 THEN 'male' ELSE 'female' END::public.gender FROM generate_series(10, 19) n;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(10, 19) n;
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('1'));
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, recue_le, derniere_activite)
SELECT pg_temp.c(n::text), 'enseignant', pg_temp.u(n::text), CASE WHEN n = 11 THEN 'male' ELSE 'female' END::public.gender,
       'Prenomsecret' || n || ' Famillesecrete',
       CASE WHEN n IN (10, 11, 12, 13, 14) THEN 'verifications' ELSE 'prequalification' END,
       CASE WHEN n IN (10, 11, 12, 13, 14) THEN 'entretien_a_planifier' ELSE 'a_completer' END,
       'en_cours', 'lien_public', now() - interval '20 days', now() - (n || ' days')::interval
  FROM generate_series(10, 19) n;
UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = clock_timestamp() WHERE id IN (SELECT pg_temp.c(n::text) FROM generate_series(10, 19) n);
UPDATE public.candidatures SET restreinte = true, restriction_cause = 'manuelle' WHERE id = pg_temp.c('14');
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone) VALUES (pg_temp.c('10'), 'adresse.secrete@test.invalid', '+33612345678');
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, auteur_id, motif_interne, details, cree_le)
SELECT pg_temp.c(n::text), 'transition', 'prequalification', 'verifications', pg_temp.u('2'), 'MOTIFSECRET', '{"geste": "admettre_verifications", "auteur": "direction"}',
       now() - interval '3 days'
  FROM generate_series(10, 14) n;
-- Une transition d'ETAT apres l'admission (meme etape) : elle ne compte pas comme transition d'etape.
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, details, cree_le) VALUES
 (pg_temp.c('10'), 'transition', 'verifications', 'verifications', 'en_examen', 'entretien_a_planifier', '{}', now() - interval '1 day');
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
SELECT pg_temp.f(n::text), 'candidature', pg_temp.c(n::text), 'profil', pg_temp.u(n::text), 'equipe', NULL FROM generate_series(10, 14) n;
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
 (pg_temp.f('10'), pg_temp.u('2'), pg_temp.idem('1'), 'Message de la direction avant la decision.', clock_timestamp() - interval '5 days'),
 (pg_temp.f('10'), pg_temp.u('10'), pg_temp.idem('2'), 'Ou en est mon dossier ?', clock_timestamp() - interval '1 day'),
 (pg_temp.f('11'), pg_temp.u('11'), pg_temp.idem('3'), 'Bonjour.', clock_timestamp() - interval '1 day'),
 (pg_temp.f('12'), pg_temp.u('2'), pg_temp.idem('4'), 'Vous etes admise a l''etape suivante.', clock_timestamp() - interval '2 days'),
 (pg_temp.f('12'), pg_temp.u('12'), pg_temp.idem('5'), 'Merci.', clock_timestamp() - interval '1 day'),
 (pg_temp.f('13'), pg_temp.u('13'), pg_temp.idem('6'), 'Bonjour.', clock_timestamp() - interval '2 days'),
 (pg_temp.f('13'), private.praxis_profil(), pg_temp.idem('7'), 'Votre dossier est a l''etape des verifications.', clock_timestamp() - interval '1 day'),
 (pg_temp.f('14'), pg_temp.u('14'), pg_temp.idem('8'), 'Bonjour.', clock_timestamp() - interval '1 day');

CREATE FUNCTION pg_temp.k(p_nom text) RETURNS text LANGUAGE sql AS $$ SELECT pg_temp.lu(p_nom) ->> 'secret' $$;
CREATE FUNCTION pg_temp.ref(p_n text) RETURNS text LANGUAGE sql AS $$ SELECT c.reference FROM public.candidatures c WHERE c.id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.boite(p_cle text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_boite(%L, ''tout'', 50)', pg_temp.k(p_cle))) $$;
CREATE FUNCTION pg_temp.ligne_boite(p_cle text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM jsonb_array_elements(pg_temp.boite(p_cle) -> 'fils') l(x) WHERE (l.x ->> 'id')::uuid = pg_temp.f(p_n) $$;
CREATE FUNCTION pg_temp.fil(p_cle text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 20)', pg_temp.k(p_cle), pg_temp.f(p_n))) $$;
CREATE FUNCTION pg_temp.lire(p_cle text, p_filtre text, p_limite integer DEFAULT 50) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', %L::jsonb, %s)', pg_temp.k(p_cle), p_filtre, p_limite)) $$;
CREATE FUNCTION pg_temp.refs(p_j jsonb) RETURNS text[] LANGUAGE sql AS $$
  SELECT coalesce(array_agg(l.x ->> 'reference' ORDER BY l.o), '{}') FROM jsonb_array_elements(p_j -> 'lignes') WITH ORDINALITY l(x, o) $$;
CREATE FUNCTION pg_temp.ligne_lire(p_cle text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM jsonb_array_elements(pg_temp.lire(p_cle, '{}') -> 'lignes') l(x) WHERE l.x ->> 'reference' = pg_temp.ref(p_n) $$;
CREATE FUNCTION pg_temp.demander(p_cle text, p_fil uuid, p_q text DEFAULT 'Le candidat demande la date de son entretien.') RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, %L)', pg_temp.k(p_cle), p_fil, p_q)) $$;
CREATE FUNCTION pg_temp.ouvertes(p_cle text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_questions_ouvertes(%L, 50)', pg_temp.k(p_cle))) $$;
CREATE FUNCTION pg_temp.retirer(p_cle text, p_q uuid, p_motif text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_retirer_question(%L, %L::uuid, %L)', pg_temp.k(p_cle), p_q, p_motif)) $$;
CREATE FUNCTION pg_temp.ouvrir(p_cle text, p_n text, p_idem text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, %L, ''question'', ''Bonjour, une question de Praxis ?'', %L::uuid)',
    pg_temp.k(p_cle), pg_temp.ref(p_n), pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.etat(p_cle text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_etat(%L)', pg_temp.k(p_cle))) $$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated, anon, service_role;

SELECT pg_temp.garde('both', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat deux cotes', 'chat', pg_catalog.now() + interval '30 days', '5c1b2222-0000-4000-8000-000000000041'::uuid)$$));
SELECT pg_temp.garde('fem', pg_temp.en(pg_temp.u('2'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat femme', 'chat', pg_catalog.now() + interval '30 days', '5c1b2222-0000-4000-8000-000000000042'::uuid)$$));
SELECT pg_temp.garde('on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));

-- ===== DROITS =====
SELECT pg_temp.verif('DROITS outil ' || x.f || ' : service_role seul', format(
  $v$SELECT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('authenticated', %L, 'EXECUTE') AND NOT has_function_privilege('agent_ro', %L, 'EXECUTE')
        AND NOT has_function_privilege('public', %L, 'EXECUTE')$v$, x.f, x.f, x.f, x.f, x.f))
  FROM (VALUES ('public.praxis_questions_ouvertes(text,integer)'), ('public.praxis_retirer_question(text,uuid,text)'),
               ('public.praxis_boite(text,text,integer)'), ('public.praxis_fil(text,uuid,integer)'), ('public.praxis_lire(text,text,jsonb,integer)'),
               ('public.praxis_demander_equipe(text,uuid,text)'), ('public.praxis_reponses_equipe(text,integer)'),
               ('public.praxis_noter_refus(text,text)'), ('public.praxis_etat(text)')) x(f);
SELECT pg_temp.verif('DROITS porte ' || x.f || ' : authenticated seul', format(
  $v$SELECT has_function_privilege('authenticated', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('agent_ro', %L, 'EXECUTE')$v$, x.f, x.f, x.f, x.f))
  FROM (VALUES ('public.direction_praxis_regler_ouvertures(integer,integer)'), ('public.direction_praxis_questions(integer)')) x(f);
SELECT pg_temp.verif('DROITS aide private.praxis_dossier_resume : aucun role', $$
  SELECT NOT has_function_privilege('service_role', 'private.praxis_dossier_resume(uuid,public.gender[])', 'EXECUTE')
     AND NOT has_function_privilege('anon', 'private.praxis_dossier_resume(uuid,public.gender[])', 'EXECUTE')
     AND NOT has_function_privilege('authenticated', 'private.praxis_dossier_resume(uuid,public.gender[])', 'EXECUTE')
     AND NOT has_function_privilege('agent_ro', 'private.praxis_dossier_resume(uuid,public.gender[])', 'EXECUTE') $$);
SELECT pg_temp.verif('DROITS definitions : SECURITY DEFINER, search_path vide, proprietaire postgres', $$
  SELECT bool_and(p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::regrole)
    FROM pg_proc p WHERE p.oid IN ('public.praxis_questions_ouvertes(text,integer)'::regprocedure, 'public.praxis_retirer_question(text,uuid,text)'::regprocedure,
      'public.direction_praxis_regler_ouvertures(integer,integer)'::regprocedure, 'public.praxis_boite(text,text,integer)'::regprocedure,
      'public.praxis_fil(text,uuid,integer)'::regprocedure, 'public.praxis_lire(text,text,jsonb,integer)'::regprocedure,
      'public.praxis_etat(text)'::regprocedure, 'public.direction_praxis_questions(integer)'::regprocedure) $$);
SELECT pg_temp.verif('DROITS appel : anon ne peut appeler ni questions_ouvertes ni retirer_question (42501)', $$
  SELECT pg_temp.code_en(NULL, NULL, format('SELECT public.praxis_questions_ouvertes(%L, 5)', pg_temp.k('both')), 'anon') = '42501'
     AND pg_temp.code_en(NULL, NULL, format('SELECT public.praxis_retirer_question(%L, gen_random_uuid(), ''sans_objet'')', pg_temp.k('both')), 'anon') = '42501' $$);
SELECT pg_temp.verif('DROITS appel : un administrateur connecte ne peut pas appeler les outils de Praxis (42501)', $$
  SELECT pg_temp.code_en(pg_temp.u('1'), 'admin', format('SELECT public.praxis_questions_ouvertes(%L, 5)', pg_temp.k('both'))) = '42501'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', format('SELECT public.praxis_retirer_question(%L, gen_random_uuid(), ''sans_objet'')', pg_temp.k('both'))) = '42501' $$);
SELECT pg_temp.verif('DROITS tables : RLS active, aucun droit client sur les questions et les reglages', $$
  SELECT (SELECT bool_and(c.relrowsecurity) FROM pg_class c WHERE c.oid IN ('private.praxis_questions'::regclass, 'private.praxis_reglages'::regclass))
     AND NOT has_table_privilege('authenticated', 'private.praxis_questions', 'SELECT') AND NOT has_table_privilege('service_role', 'private.praxis_questions', 'UPDATE')
     AND NOT has_table_privilege('anon', 'private.praxis_reglages', 'SELECT') AND NOT has_table_privilege('service_role', 'private.praxis_reglages', 'SELECT') $$);

-- ===== 1. DOSSIER dans BOITE et FIL : donnees reelles fermees, puis ouvertes =====
SELECT pg_temp.verif('DOSSIER donnees reelles fermees : l''aide rend null (memes portes que praxis_dossier)', $$
  SELECT private.praxis_dossier_resume(pg_temp.f('10'), ARRAY['male', 'female']::public.gender[]) IS NULL $$);
UPDATE private.praxis_reglages SET donnees_reelles = true;
SELECT pg_temp.garde('b10', pg_temp.ligne_boite('both', '10'));
SELECT pg_temp.garde('b12', pg_temp.ligne_boite('both', '12'));
SELECT pg_temp.garde('b13', pg_temp.ligne_boite('both', '13'));
SELECT pg_temp.garde('b14', pg_temp.ligne_boite('both', '14'));
SELECT pg_temp.garde('fil10', pg_temp.fil('both', '10'));
SELECT pg_temp.verif('BOITE dossier : la candidate admise il y a 3 jours, jamais prevenue depuis : etape, etat, issue, informe faux, 3 jours', $$
  SELECT d ->> 'reference' = pg_temp.ref('10') AND d ->> 'etape' = 'verifications' AND d ->> 'etat' = 'entretien_a_planifier'
     AND d ->> 'issue' = 'en_cours' AND d ->> 'informe_de_l_etape' = 'false' AND (d ->> 'etape_depuis_jours')::int = 3
    FROM (SELECT pg_temp.lu('b10') -> 'dossier' AS d) x $$);
SELECT pg_temp.verif('BOITE dossier : un message de la direction AVANT la transition ne compte pas ; une transition d''etat n''est pas une transition d''etape', $$
  SELECT pg_temp.lu('b10') #>> '{dossier,informe_de_l_etape}' = 'false' AND (pg_temp.lu('b10') #>> '{dossier,etape_depuis_jours}')::int = 3 $$);
SELECT pg_temp.verif('BOITE dossier : la direction a ecrit apres la transition : informe vrai', $$
  SELECT pg_temp.lu('b12') #>> '{dossier,informe_de_l_etape}' = 'true' $$);
SELECT pg_temp.verif('BOITE dossier : Praxis a ecrit apres la transition : informe vrai', $$
  SELECT pg_temp.lu('b13') #>> '{dossier,informe_de_l_etape}' = 'true' $$);
SELECT pg_temp.verif('BOITE dossier : complet, manquants, attend_direction sont ceux de lire (meme aide, memes valeurs)', $$
  SELECT (pg_temp.lu('b10') -> 'dossier') -> 'manquants' = pg_temp.ligne_lire('both', '10') -> 'manquants'
     AND (pg_temp.lu('b10') -> 'dossier') -> 'attend_direction' = pg_temp.ligne_lire('both', '10') -> 'attend_direction'
     AND (pg_temp.lu('b10') -> 'dossier') -> 'complet' = pg_temp.ligne_lire('both', '10') -> 'complet'
     AND jsonb_typeof((pg_temp.lu('b10') -> 'dossier') -> 'manquants') = 'array' $$);
SELECT pg_temp.verif('BOITE dossier : les cles sont une liste fermee, sans aucune donnee de personne', $$
  SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.lu('b10') -> 'dossier') k)
       = ARRAY['attend_direction', 'complet', 'etape', 'etape_depuis_jours', 'etat', 'informe_de_l_etape', 'issue', 'manquants', 'reference']
     AND (pg_temp.lu('b10') -> 'dossier')::text !~* '(Prenomsecret|Famillesecrete|test\.invalid|@|\+33|0612|MOTIFSECRET|5c1b0000)' $$);
SELECT pg_temp.verif('BOITE dossier null : une candidature RESTREINTE (conversation lisible, dossier ferme a Praxis)', $$
  SELECT pg_temp.lu('b14') IS NOT NULL AND pg_temp.lu('b14') ? 'dossier' AND jsonb_typeof(pg_temp.lu('b14') -> 'dossier') = 'null' $$);
SELECT pg_temp.verif('BOITE cote : la cle femme ne voit pas la conversation du candidat homme ; la cle des deux cotes la voit, avec son dossier', $$
  SELECT pg_temp.ligne_boite('fem', '11') IS NULL AND pg_temp.ligne_boite('both', '11') #>> '{dossier,etape}' = 'verifications' $$);
SELECT pg_temp.verif('FIL dossier : le meme objet que la boite, dans la reponse de fil', $$
  SELECT pg_temp.lu('fil10') -> 'dossier' = pg_temp.lu('b10') -> 'dossier' AND pg_temp.fil('both', '12') #>> '{dossier,informe_de_l_etape}' = 'true'
     AND jsonb_typeof(pg_temp.fil('both', '14') -> 'dossier') = 'null' $$);
SELECT pg_temp.verif('FIL dossier : aucune donnee de personne ajoutee hors contenu_tiers (le dossier est sans nom ni contact)', $$
  SELECT (pg_temp.lu('fil10') -> 'dossier')::text !~* '(Prenomsecret|Famillesecrete|test\.invalid|@|\+33)' $$);
-- Fermetures de l'aide elle-meme (les conversations sont alors fermees aussi par praxis_fil_refus, l'aide doit l'etre de son cote).
SELECT pg_temp.verif('DOSSIER ferme : en pause, refusee, retiree, majorite non attestee, autre cote, fil inconnu : null', $$
  SELECT bool_and(r IS NULL) FROM (
    SELECT (SELECT private.praxis_dossier_resume(pg_temp.f('11'), ARRAY['female']::public.gender[])) AS r
    UNION ALL SELECT private.praxis_dossier_resume(gen_random_uuid(), ARRAY['male', 'female']::public.gender[])
    UNION ALL SELECT private.praxis_dossier_resume(NULL, ARRAY['male', 'female']::public.gender[])) x $$);
SELECT pg_temp.verif_annule('DOSSIER ferme apres coup : pause, refus, majorite retiree rendent null',
  $$UPDATE public.candidatures SET en_pause = true WHERE id = pg_temp.c('12');
    UPDATE public.candidatures SET issue = 'refusee' WHERE id = pg_temp.c('13');
    UPDATE public.candidatures SET majorite_declaree = NULL, majorite_attestee_le = NULL WHERE id = pg_temp.c('10')$$,
  $$SELECT private.praxis_dossier_resume(pg_temp.f('12'), ARRAY['male', 'female']::public.gender[]) IS NULL
       AND private.praxis_dossier_resume(pg_temp.f('13'), ARRAY['male', 'female']::public.gender[]) IS NULL
       AND private.praxis_dossier_resume(pg_temp.f('10'), ARRAY['male', 'female']::public.gender[]) IS NULL$$);
SELECT pg_temp.verif_annule('DOSSIER essai : en mode essai, la conversation d''essai est lisible mais son dossier est null',
  $$UPDATE private.praxis_reglages SET essai_fils = ARRAY[pg_temp.f('10')]$$,
  $$SELECT pg_temp.ligne_boite('both', '10') IS NOT NULL AND jsonb_typeof(pg_temp.ligne_boite('both', '10') -> 'dossier') = 'null'
       AND jsonb_typeof(pg_temp.fil('both', '10') -> 'dossier') = 'null'$$);
SELECT pg_temp.verif_annule('DOSSIER informe : un nouveau message de la direction apres la transition fait passer informe a vrai',
  $$INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
    VALUES (pg_temp.f('10'), pg_temp.u('2'), pg_temp.idem('20'), 'Votre dossier avance.', clock_timestamp())$$,
  $$SELECT pg_temp.fil('both', '10') #>> '{dossier,informe_de_l_etape}' = 'true'$$);
SELECT pg_temp.verif_annule('DOSSIER informe : le message du candidat lui-meme ne compte pas',
  $$INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
    VALUES (pg_temp.f('10'), pg_temp.u('10'), pg_temp.idem('21'), 'Encore moi.', clock_timestamp())$$,
  $$SELECT pg_temp.fil('both', '10') #>> '{dossier,informe_de_l_etape}' = 'false'$$);
SELECT pg_temp.verif('JOURNAL : boite et fil restent journalises', $$
  SELECT EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'boite' AND j.issue = 'ok')
     AND EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'fil' AND j.issue = 'ok' AND j.fil_id = pg_temp.f('10')) $$);

-- ===== 2. LIRE : fil, decalage, total =====
SELECT pg_temp.garde('tout', pg_temp.lire('both', '{}'));
SELECT pg_temp.verif('LIRE fil : la conversation lisible est rendue ; sans conversation : null ; restreinte lisible : rendue', $$
  SELECT pg_temp.ligne_lire('both', '10') ->> 'fil' = pg_temp.f('10')::text AND jsonb_typeof(pg_temp.ligne_lire('both', '16') -> 'fil') = 'null'
     AND pg_temp.ligne_lire('both', '14') ->> 'fil' = pg_temp.f('14')::text
     AND pg_temp.ligne_lire('both', '10') ->> 'a_une_conversation' = 'true' $$);
SELECT pg_temp.verif('LIRE total : le nombre de lignes du filtre (9 de la cle des deux cotes : 10 moins 0 ferme ; la cle femme en voit 8)', $$
  SELECT (pg_temp.lu('tout') ->> 'total')::int = jsonb_array_length(pg_temp.lu('tout') -> 'lignes')
     AND (pg_temp.lu('tout') ->> 'total')::int = 10 AND (pg_temp.lire('fem', '{}') ->> 'total')::int = 9
     AND (pg_temp.lu('tout') ->> 'decalage')::int = 0 AND (pg_temp.lu('tout') ->> 'reste')::int = 0 $$);
SELECT pg_temp.verif('LIRE pagination : pages de 3 par decalage 0, 3, 6, 9 : la suite exacte de la liste entiere, sans doublon ni trou', $$
  SELECT pg_temp.refs(pg_temp.lire('both', '{"decalage":0}', 3)) || pg_temp.refs(pg_temp.lire('both', '{"decalage":3}', 3))
         || pg_temp.refs(pg_temp.lire('both', '{"decalage":6}', 3)) || pg_temp.refs(pg_temp.lire('both', '{"decalage":9}', 3))
       = pg_temp.refs(pg_temp.lu('tout'))
     AND (SELECT count(DISTINCT r) FROM unnest(pg_temp.refs(pg_temp.lu('tout'))) r) = 10 $$);
SELECT pg_temp.verif('LIRE pagination : chaque page dit le total et ce qu''il reste', $$
  SELECT (j ->> 'total')::int = 10 AND (j ->> 'decalage')::int = 3 AND (j ->> 'reste')::int = 4 AND jsonb_array_length(j -> 'lignes') = 3
    FROM (SELECT pg_temp.lire('both', '{"decalage":3}', 3) AS j) x $$);
SELECT pg_temp.verif('LIRE pagination avec filtre et tri vision : sans doublon ni trou', $$
  SELECT pg_temp.refs(pg_temp.lire('both', '{"etape":"prequalification","tri":"vision","decalage":0}', 2))
         || pg_temp.refs(pg_temp.lire('both', '{"etape":"prequalification","tri":"vision","decalage":2}', 2))
         || pg_temp.refs(pg_temp.lire('both', '{"etape":"prequalification","tri":"vision","decalage":4}', 2))
       = pg_temp.refs(pg_temp.lire('both', '{"etape":"prequalification","tri":"vision"}'))
     AND (pg_temp.lire('both', '{"etape":"prequalification"}') ->> 'total')::int = 5 $$);
SELECT pg_temp.verif('LIRE decalage au-dela de la fin : aucune ligne, mais le total reste juste', $$
  SELECT jsonb_array_length(j -> 'lignes') = 0 AND (j ->> 'total')::int = 10 AND (j ->> 'reste')::int = 0
    FROM (SELECT pg_temp.lire('both', '{"decalage":40}', 5) AS j) x $$);
SELECT pg_temp.verif('LIRE decalage refuse : negatif, plus de 5000, decimal, texte (parametre, journalise)', $$
  SELECT pg_temp.lire('both', '{"decalage":-1}') ->> 'erreur' = 'parametre' AND pg_temp.lire('both', '{"decalage":5001}') ->> 'erreur' = 'parametre'
     AND pg_temp.lire('both', '{"decalage":1.5}') ->> 'erreur' = 'parametre' AND pg_temp.lire('both', '{"decalage":"2"}') ->> 'erreur' = 'parametre'
     AND pg_temp.n('private.praxis_journal j WHERE j.outil = ''lire'' AND j.issue = ''parametre''') >= 4 $$);
SELECT pg_temp.verif('LIRE sobre : ni nom de famille, ni courriel, ni motif interne dans la vue paginee', $$
  SELECT pg_temp.lire('both', '{"decalage":2}', 5)::text !~* '(Famillesecrete|test\.invalid|MOTIFSECRET|5c1b0000)' $$);

-- ===== 3. QUESTIONS : ouvertes, retirees =====
SELECT pg_temp.garde('q10', pg_temp.demander('both', pg_temp.f('10')));
SELECT pg_temp.garde('q12', pg_temp.demander('both', pg_temp.f('12'), 'Le candidat demande si l''ijaza est obligatoire.'));
SELECT pg_temp.garde('q11', pg_temp.demander('both', pg_temp.f('11'), 'Le candidat demande les horaires.'));
UPDATE private.praxis_questions SET posee_le = now() - interval '5 hours' WHERE id = (pg_temp.lu('q10') ->> 'id')::uuid;
SELECT pg_temp.verif('QUESTIONS ouvertes : les trois questions, la plus ancienne d''abord, avec fil, resume et age en heures', $$
  SELECT jsonb_array_length(j -> 'questions') = 3 AND j #>> '{questions,0,id}' = pg_temp.lu('q10') ->> 'id'
     AND j #>> '{questions,0,fil}' = pg_temp.f('10')::text AND (j #>> '{questions,0,age_heures}')::int = 5
     AND j #>> '{questions,0,question}' = 'Le candidat demande la date de son entretien.'
     AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(j -> 'questions' -> 0) k) = ARRAY['age_heures', 'fil', 'id', 'posee_le', 'question']
    FROM (SELECT pg_temp.ouvertes('both') AS j) x $$);
SELECT pg_temp.verif('QUESTIONS ouvertes cote : la cle femme ne voit pas la question de la conversation du candidat homme', $$
  SELECT jsonb_array_length(pg_temp.ouvertes('fem') -> 'questions') = 2 $$);
SELECT pg_temp.verif('QUESTIONS ouvertes limite : 0 ou 51 refuses (parametre)', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_questions_ouvertes(%L, 0)', pg_temp.k('both'))) ->> 'erreur' = 'parametre'
     AND pg_temp.srv(format('SELECT public.praxis_questions_ouvertes(%L, 51)', pg_temp.k('both'))) ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.verif('RETIRER refus : motif hors liste, question nulle (parametre) ; question inconnue (inconnue) ; rien ne change', $$
  SELECT pg_temp.retirer('both', (pg_temp.lu('q10') ->> 'id')::uuid, 'pourquoi_pas') ->> 'erreur' = 'parametre'
     AND pg_temp.srv(format('SELECT public.praxis_retirer_question(%L, NULL, ''sans_objet'')', pg_temp.k('both'))) ->> 'erreur' = 'parametre'
     AND pg_temp.retirer('both', gen_random_uuid(), 'sans_objet') ->> 'erreur' = 'inconnue'
     AND pg_temp.n('private.praxis_questions q WHERE q.retiree_le IS NOT NULL') = 0 $$);
SELECT pg_temp.verif('RETIRER cote : la cle femme ne peut pas retirer la question du candidat homme (inconnue)', $$
  SELECT pg_temp.retirer('fem', (pg_temp.lu('q11') ->> 'id')::uuid, 'sans_objet') ->> 'erreur' = 'inconnue'
     AND pg_temp.n(format('private.praxis_questions q WHERE q.id = %L::uuid AND q.retiree_le IS NULL', pg_temp.lu('q11') ->> 'id')) = 1 $$);
SELECT pg_temp.garde('r10', pg_temp.retirer('both', (pg_temp.lu('q10') ->> 'id')::uuid, 'repondu_par_praxis'));
SELECT pg_temp.verif('RETIRER : Praxis retire sa question ; la ligne est GARDEE (motif et date), rien d''efface, journalise', $$
  SELECT pg_temp.lu('r10') = '{"ok": true}'::jsonb
     AND (SELECT q.retiree_le IS NOT NULL AND q.retiree_motif = 'repondu_par_praxis' AND q.repondue_le IS NULL AND q.question = 'Le candidat demande la date de son entretien.'
            FROM private.praxis_questions q WHERE q.id = (pg_temp.lu('q10') ->> 'id')::uuid)
     AND (SELECT count(*) FROM private.praxis_questions) = 3
     AND EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'retirer_question' AND j.issue = 'ok'
                   AND j.ids_touches = ARRAY[(pg_temp.lu('q10') ->> 'id')::uuid] AND j.fil_id = pg_temp.f('10')) $$);
SELECT pg_temp.verif('RETIRER : une question retiree n''est plus ouverte (questions_ouvertes)', $$
  SELECT jsonb_array_length(j -> 'questions') = 2
     AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(j -> 'questions') e WHERE e ->> 'id' = pg_temp.lu('q10') ->> 'id')
    FROM (SELECT pg_temp.ouvertes('both') AS j) x $$);
SELECT pg_temp.verif('RETIRER une seconde fois : deja_retiree ; rien ne change', $$
  SELECT pg_temp.retirer('both', (pg_temp.lu('q10') ->> 'id')::uuid, 'sans_objet') ->> 'erreur' = 'deja_retiree'
     AND pg_temp.n(format('private.praxis_questions q WHERE q.id = %L::uuid AND q.retiree_motif = ''repondu_par_praxis''', pg_temp.lu('q10') ->> 'id')) = 1 $$);
SELECT pg_temp.verif('DEMANDER sur la meme conversation : refus clair question_retiree (la place se libere quand la direction repond)', $$
  SELECT pg_temp.demander('both', pg_temp.f('10'), 'Une autre question.') ->> 'erreur' = 'question_retiree'
     AND pg_temp.demander('both', pg_temp.f('12'), 'Une autre question.') ->> 'erreur' = 'question_ouverte' $$);
SELECT pg_temp.verif_annule('DEMANDER plafond : une question retiree ne compte plus parmi les 100 ouvertes',
  $$INSERT INTO private.praxis_questions (fil_id, cle_id, question, posee_le)
    SELECT gen_random_uuid(), q.cle_id, 'Question de remplissage.', now() - interval '3 hours'
      FROM (SELECT cle_id FROM private.praxis_questions LIMIT 1) q, generate_series(1, 97)$$,
  $$SELECT (SELECT count(*) FROM private.praxis_questions q WHERE q.repondue_le IS NULL) = 100
       AND pg_temp.demander('both', pg_temp.f('13'), 'Question de plus.') ->> 'ok' = 'true'$$);
SELECT pg_temp.verif_annule('DEMANDER plafond : 100 questions vraiment ouvertes, la suivante est refusee (trop_ouvertes)',
  $$INSERT INTO private.praxis_questions (fil_id, cle_id, question, posee_le)
    SELECT gen_random_uuid(), q.cle_id, 'Question de remplissage.', now() - interval '3 hours'
      FROM (SELECT cle_id FROM private.praxis_questions LIMIT 1) q, generate_series(1, 98)$$,
  $$SELECT pg_temp.demander('both', pg_temp.f('13'), 'Question de trop.') ->> 'erreur' = 'trop_ouvertes'$$);
SELECT pg_temp.verif('DIRECTION : la liste montre la question retiree, apres les ouvertes, avec sa date et son motif', $$
  SELECT j -> 'questions' -> 2 ->> 'id' = pg_temp.lu('q10') ->> 'id' AND j -> 'questions' -> 2 ->> 'retireeMotif' = 'repondu_par_praxis'
     AND j -> 'questions' -> 2 ->> 'retireeLe' IS NOT NULL AND jsonb_typeof(j -> 'questions' -> 0 -> 'retireeLe') = 'null'
     AND (j ->> 'total')::int = 3
    FROM (SELECT pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_questions(100)') AS j) x $$);
-- La direction repond quand meme a la question retiree : la place se libere, la reponse est transmise, marquee.
SELECT pg_temp.garde('rep', pg_temp.en(pg_temp.u('2'), 'admin', format('SELECT public.direction_praxis_repondre(%L::uuid, ''La direction fixe la date.'')', pg_temp.lu('q10') ->> 'id')));
SELECT pg_temp.verif('REPONSES : la reponse de la direction a une question retiree est transmise avec question_retiree vrai ; les autres faux', $$
  SELECT pg_temp.lu('rep') = '{"ok": true}'::jsonb
     AND (SELECT e ->> 'question_retiree' FROM jsonb_array_elements(pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 20)', pg_temp.k('both'))) -> 'reponses') e
           WHERE e ->> 'id' = pg_temp.lu('q10') ->> 'id') = 'true' $$);
SELECT pg_temp.verif('RETIRER une question repondue : deja_repondue', $$
  SELECT pg_temp.retirer('both', (pg_temp.lu('q10') ->> 'id')::uuid, 'sans_objet') ->> 'erreur' = 'deja_repondue' $$);
SELECT pg_temp.verif('DEMANDER : apres la reponse de la direction, la conversation accepte une nouvelle question', $$
  SELECT pg_temp.demander('both', pg_temp.f('10'), 'Nouvelle question.') ->> 'ok' = 'true' $$);
SELECT pg_temp.verif('REFUS de parametre : praxis_noter_refus connait questions_ouvertes et retirer_question, pas un outil invente', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''questions_ouvertes'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''retirer_question'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''demander_equipe'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''effacer_question'')', pg_temp.k('both'))) ->> 'ok' = 'false' $$);
SELECT pg_temp.verif('CONTRAINTES : un motif hors liste ou une date sans motif sont refuses par la table', $$
  SELECT pg_temp.code_en(NULL, NULL, 'UPDATE private.praxis_questions SET retiree_le = now(), retiree_motif = ''autre''', 'postgres') = '23514'
     AND pg_temp.code_en(NULL, NULL, 'UPDATE private.praxis_questions SET retiree_le = now(), retiree_motif = NULL', 'postgres') = '23514' $$);

-- ===== 4. PLAFOND DES OUVERTURES : 100 par 5 heures glissantes, reglable =====
SELECT pg_temp.verif('ETAT : ouverturesRestantesFenetre, ouverturesParFenetre (100), ouverturesFenetreHeures (5) ; ouverturesRestantesJour gardee, meme valeur', $$
  SELECT (e ->> 'ouverturesRestantesFenetre')::int = 100 AND (e ->> 'ouverturesParFenetre')::int = 100 AND (e ->> 'ouverturesFenetreHeures')::int = 5
     AND (e ->> 'ouverturesRestantesJour')::int = 100
    FROM (SELECT pg_temp.etat('both') AS e) x $$);
SELECT pg_temp.garde('o16', pg_temp.ouvrir('both', '16', '160'));
SELECT pg_temp.verif('OUVRIR : une question passe, et le restant de la fenetre baisse d''une unite', $$
  SELECT pg_temp.lu('o16') ->> 'ok' = 'true' AND (pg_temp.etat('both') ->> 'ouverturesRestantesFenetre')::int = 99 $$);
SELECT pg_temp.verif_annule('OUVRIR plafond : 100 ouvertures dans les 5 heures, la suivante est refusee (plafond_ouvertures), la boite le dit',
  $$INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT gen_random_uuid(), 'question', gen_random_uuid(), gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '4 hours 50 minutes'
      FROM (SELECT cle_id, emise_par FROM private.praxis_ouvertures LIMIT 1) o, generate_series(1, 99)$$,
  $$SELECT pg_temp.ouvrir('both', '17', '170') ->> 'erreur' = 'plafond_ouvertures'
       AND (pg_temp.etat('both') ->> 'ouverturesRestantesFenetre')::int = 0
       AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.srv(format('SELECT public.praxis_boite_candidats(%L, ''sans_nouvelles'', 3, 50)', pg_temp.k('both'))) -> 'candidats') l
                    WHERE l ->> 'reference' = pg_temp.ref('17') AND l ->> 'refus' = 'plafond_ouvertures')$$);
SELECT pg_temp.verif_annule('OUVRIR fenetre glissante : 99 ouvertures d''il y a 5 h 10 ne comptent plus ; l''ouverture passe',
  $$INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT gen_random_uuid(), 'question', gen_random_uuid(), gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '5 hours 10 minutes'
      FROM (SELECT cle_id, emise_par FROM private.praxis_ouvertures LIMIT 1) o, generate_series(1, 99)$$,
  $$SELECT pg_temp.ouvrir('both', '17', '171') ->> 'ok' = 'true'$$);
SELECT pg_temp.verif_annule('OUVRIR : 25 par 24 heures ne s''applique plus (30 ouvertures il y a 6 heures, une de plus passe)',
  $$INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT gen_random_uuid(), 'question', gen_random_uuid(), gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '6 hours'
      FROM (SELECT cle_id, emise_par FROM private.praxis_ouvertures LIMIT 1) o, generate_series(1, 30)$$,
  $$SELECT pg_temp.ouvrir('both', '17', '172') ->> 'ok' = 'true'$$);
SELECT pg_temp.verif_annule('OUVRIR : les felicitations ne comptent pas dans le plafond',
  $$INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le, evenement_id)
    SELECT gen_random_uuid(), 'felicitations', gen_random_uuid(), gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '1 hour',
           900000 + g
      FROM (SELECT cle_id, emise_par FROM private.praxis_ouvertures LIMIT 1) o, generate_series(1, 150) g$$,
  $$SELECT (pg_temp.etat('both') ->> 'ouverturesRestantesFenetre')::int = 99 AND pg_temp.ouvrir('both', '17', '173') ->> 'ok' = 'true'$$);
-- Le reglage : la direction seule, en aal2, dans les bornes.
SELECT pg_temp.verif('REGLER : sans aal2, refus 42501 ; un enseignant, refus 42501 ; anon, refus 42501 ; hors bornes, 22023 ; rien ne change', $$
  SELECT pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_ouvertures(50, 3)', 'authenticated', 'aal1') = '42501'
     AND pg_temp.code_en(pg_temp.u('10'), 'teacher', 'SELECT public.direction_praxis_regler_ouvertures(50, 3)') = '42501'
     AND pg_temp.code_en(NULL, NULL, 'SELECT public.direction_praxis_regler_ouvertures(50, 3)', 'anon') = '42501'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_ouvertures(0, 3)') = '22023'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_ouvertures(501, 3)') = '22023'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_ouvertures(50, 49)') = '22023'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_ouvertures(50, NULL)') = '22023'
     AND (SELECT r.ouvertures_par_fenetre = 100 AND r.ouvertures_fenetre_heures = 5 FROM private.praxis_reglages r) $$);
SELECT pg_temp.verif('CONTRAINTES reglages : la table refuse 0 ouverture ou une fenetre de 49 heures', $$
  SELECT pg_temp.code_en(NULL, NULL, 'UPDATE private.praxis_reglages SET ouvertures_par_fenetre = 0', 'postgres') = '23514'
     AND pg_temp.code_en(NULL, NULL, 'UPDATE private.praxis_reglages SET ouvertures_fenetre_heures = 49', 'postgres') = '23514' $$);
SELECT pg_temp.garde('regle', pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_ouvertures(1, 2)'));
SELECT pg_temp.verif('REGLER : le directeur en aal2 met 1 par 2 heures ; journalise ; etat le lit ; la seconde ouverture est refusee', $$
  SELECT pg_temp.lu('regle') = '{"ouverturesParFenetre": 1, "ouverturesFenetreHeures": 2}'::jsonb
     AND (SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_regle_ouvertures') = 1
     AND (pg_temp.etat('both') ->> 'ouverturesParFenetre')::int = 1 AND (pg_temp.etat('both') ->> 'ouverturesFenetreHeures')::int = 2
     AND (pg_temp.etat('both') ->> 'ouverturesRestantesFenetre')::int = 0
     AND pg_temp.ouvrir('both', '18', '180') ->> 'erreur' = 'plafond_ouvertures' $$);

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 110) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN RAISE EXCEPTION 'PRAXIS-PX5 : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok); END IF;
  RAISE NOTICE 'PRAXIS-PX5 : % verifications, toutes vertes', (SELECT count(*) FROM res);
END $$;
ROLLBACK;
