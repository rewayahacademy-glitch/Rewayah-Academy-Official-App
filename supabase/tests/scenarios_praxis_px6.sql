-- PRAXIS PX-6 (migration 20261130800000, 20/11/2026) : Praxis ne repond plus a la place de la direction (une conversation TENUE PAR LA
-- DIRECTION sort de `boite` attend et de `laisse_en_attente`, `ecrire` la refuse `fil_de_la_direction` sans exception),
-- `direction_recente` vaut pour toutes les raisons de `ouvrir` sur N jours, les entretiens ecrits sont suspendus (reouverture par la
-- direction seule), et une serie d'entretien dont le message a disparu n'est plus annoncee ni relancee (les limites la comptent toujours).
-- Relecture du 20/11/2026 : « la direction » inclut un compte officiel autre que Praxis (#RA_STAFF fictif, u3) ; `reponses_equipe` dit si
-- une reponse est tenue, perimee, a transmettre ; une conversation de foyer (type dossier) suit la meme regle.
-- Chaque verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue s'il reste un ROUGE. Les aides du debut sont
-- celles de scenarios_praxis_px5.sql. A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin.
-- Aucun mot d'effacement.
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
  SELECT ('5c1d0000-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1dcccc-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.f(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1dffff-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5c1d1111-0000-4000-8000-' || lpad(p_n, 12, '0'))::uuid $$;
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
-- Toutes des candidates (cote femme), conversations de candidature. La direction : u1 (homme), u2 (femme).
-- c10 « merci » : la direction a ecrit il y a 2 jours, la candidate remercie il y a 1 jour (TENUE PAR LA DIRECTION).
-- c11 « d'elle-meme » : la candidate a ecrit, l'academie jamais.
-- c12 « ancienne » : la direction a ecrit il y a 10 jours (plus que N = 7), la candidate a ecrit il y a 1 jour.
-- c13 « Praxis apres » : la direction il y a 3 jours, Praxis il y a 2 jours, la candidate il y a 1 jour.
-- c14 « exception » : la direction il y a 2 jours, la candidate il y a 1 jour ; Praxis a pose une question a la direction par le canal prive.
-- c15 « ouvrir apres la direction » : la direction a ecrit il y a 3 jours (plus que 48 heures, moins que 7 jours) ; admise il y a 1 jour.
-- c16 « ouvrir, direction ancienne » : la direction a ecrit il y a 8 jours.
-- c17 : sans conversation, entretien a planifier (entretiens ecrits).
-- c18 : entretien a planifier ; DEUX series d'entretien ecrit dont les messages ont DISPARU (retires), il y a 10 et 9 jours.
-- c19 : une serie d'entretien ecrit dont le message a DISPARU, il y a une heure.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'px6-' || n || '@test.invalid' FROM generate_series(1, 30) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'P6-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'P6-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(n::text), 'P6-CAN-00' || n, 'teacher', NULL, 'Prenomsecret' || n, 'Famillesecrete', 'pending_kyc', 'female'
  FROM generate_series(10, 19) n;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(10, 19) n;
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('1'));
-- u3 : le compte de l'administration (#RA_STAFF fictif), role accountant ; il n'est compte officiel ('staff') que dans les verifications
-- qui l'inscrivent (annulees). Le role importe peu : c'est l'inscription officielle qui en fait « la direction ».
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('3'), 'P6-STAFF-0003', 'accountant', NULL, 'Staff', 'Officiel', 'active', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, recue_le, derniere_activite)
SELECT pg_temp.c(n::text), 'enseignant', pg_temp.u(n::text), 'female', 'Prenomsecret' || n || ' Famillesecrete',
       CASE WHEN n IN (15, 17, 18, 19) THEN 'verifications' ELSE 'prequalification' END,
       CASE WHEN n IN (17, 18, 19) THEN 'entretien_a_planifier' WHEN n = 15 THEN 'en_examen' ELSE 'a_completer' END,
       'en_cours', 'lien_public', now() - interval '20 days', now() - interval '1 day'
  FROM generate_series(10, 19) n;
UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = clock_timestamp()
 WHERE id IN (SELECT pg_temp.c(n::text) FROM generate_series(10, 19) n);
-- c15 : admise en verification il y a 1 jour (une decision positive a feliciter, APRES le message de la direction).
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, auteur_id, details, cree_le) VALUES
 (pg_temp.c('15'), 'transition', 'prequalification', 'verifications', pg_temp.u('2'), '{"geste": "admettre_verifications", "auteur": "direction"}',
  now() - interval '1 day');
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
SELECT pg_temp.f(n::text), 'candidature', pg_temp.c(n::text), 'profil', pg_temp.u(n::text), 'equipe', NULL FROM generate_series(10, 19) n
 WHERE n <> 17;
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
 (pg_temp.f('10'), pg_temp.u('2'), pg_temp.idem('1'), 'Information de la direction : votre dossier avance.', clock_timestamp() - interval '2 days'),
 (pg_temp.f('10'), pg_temp.u('10'), pg_temp.idem('2'), 'Merci beaucoup.', clock_timestamp() - interval '1 day'),
 (pg_temp.f('11'), pg_temp.u('11'), pg_temp.idem('3'), 'Bonjour, quand commence la formation ?', clock_timestamp() - interval '1 day'),
 (pg_temp.f('12'), pg_temp.u('2'), pg_temp.idem('4'), 'Ancien message de la direction.', clock_timestamp() - interval '10 days'),
 (pg_temp.f('12'), pg_temp.u('12'), pg_temp.idem('5'), 'Bonjour, une nouvelle question.', clock_timestamp() - interval '1 day'),
 (pg_temp.f('13'), pg_temp.u('2'), pg_temp.idem('6'), 'Message de la direction.', clock_timestamp() - interval '3 days'),
 (pg_temp.f('13'), private.praxis_profil(), pg_temp.idem('7'), 'Message de Praxis.', clock_timestamp() - interval '2 days'),
 (pg_temp.f('13'), pg_temp.u('13'), pg_temp.idem('8'), 'Reponse a Praxis.', clock_timestamp() - interval '1 day'),
 (pg_temp.f('14'), pg_temp.u('2'), pg_temp.idem('9'), 'Message de la direction.', clock_timestamp() - interval '2 days'),
 (pg_temp.f('14'), pg_temp.u('14'), pg_temp.idem('10'), 'Merci, et quel est le jour de mon entretien ?', clock_timestamp() - interval '1 day'),
 (pg_temp.f('15'), pg_temp.u('2'), pg_temp.idem('11'), 'Message de la direction.', clock_timestamp() - interval '3 days'),
 (pg_temp.f('16'), pg_temp.u('2'), pg_temp.idem('12'), 'Message de la direction.', clock_timestamp() - interval '8 days');

CREATE FUNCTION pg_temp.k(p_nom text) RETURNS text LANGUAGE sql AS $$ SELECT pg_temp.lu(p_nom) ->> 'secret' $$;
CREATE FUNCTION pg_temp.ref(p_n text) RETURNS text LANGUAGE sql AS $$ SELECT c.reference FROM public.candidatures c WHERE c.id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.boite(p_filtre text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_boite(%L, %L, 50)', pg_temp.k('both'), p_filtre)) $$;
CREATE FUNCTION pg_temp.ligne_boite(p_filtre text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM jsonb_array_elements(pg_temp.boite(p_filtre) -> 'fils') l(x) WHERE (l.x ->> 'id')::uuid = pg_temp.f(p_n) $$;
CREATE FUNCTION pg_temp.fil(p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_fil(%L, %L::uuid, 20)', pg_temp.k('both'), pg_temp.f(p_n))) $$;
CREATE FUNCTION pg_temp.ecrire(p_n text, p_idem text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Reponse de Praxis.'', %L::uuid)', pg_temp.k('both'), pg_temp.f(p_n), pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.ouvrir(p_n text, p_raison text, p_idem text, p_texte text DEFAULT 'Bonjour, une question de Praxis ?') RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, %L, %L, %L, %L::uuid)', pg_temp.k('both'), pg_temp.ref(p_n), p_raison, p_texte, pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.candidats(p_filtre text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_boite_candidats(%L, %L, 3, 50)', pg_temp.k('both'), p_filtre)) $$;
CREATE FUNCTION pg_temp.dans_candidats(p_filtre text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM jsonb_array_elements(pg_temp.candidats(p_filtre) -> 'candidats') l(x) WHERE l.x ->> 'reference' = pg_temp.ref(p_n) $$;
CREATE FUNCTION pg_temp.dossier(p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_dossier(%L, %L)', pg_temp.k('both'), pg_temp.ref(p_n))) $$;
CREATE FUNCTION pg_temp.etat() RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_etat(%L)', pg_temp.k('both'))) $$;
CREATE FUNCTION pg_temp.tenue(p_n text) RETURNS boolean LANGUAGE sql AS $$ SELECT private.praxis_tenue_par_direction(pg_temp.f(p_n)) $$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated, anon, service_role;

SELECT pg_temp.garde('both', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat deux cotes', 'chat', pg_catalog.now() + interval '30 days', '5c1d2222-0000-4000-8000-000000000041'::uuid)$$));
SELECT pg_temp.garde('on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- c18 et c19 : des series d'entretien ecrit dont le message n'existe plus dans public.com_messages (comme apres 20261130700000).
INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
SELECT x.c, 'entretien_ecrit', x.f, gen_random_uuid(), k.id, k.emise_par, gen_random_uuid(), now() - x.age
  FROM (VALUES (pg_temp.c('18'), pg_temp.f('18'), interval '10 days'), (pg_temp.c('18'), pg_temp.f('18'), interval '9 days'),
               (pg_temp.c('19'), pg_temp.f('19'), interval '1 hour')) x(c, f, age)
 CROSS JOIN (SELECT kk.id, kk.emise_par FROM private.praxis_cles kk ORDER BY kk.emise_le LIMIT 1) k;

-- ===== DROITS =====
SELECT pg_temp.verif('DROITS porte direction_praxis_regler_conversations : authenticated seul ; aide privee : aucun role', $$
  SELECT has_function_privilege('authenticated', 'public.direction_praxis_regler_conversations(integer,boolean)', 'EXECUTE')
     AND NOT has_function_privilege('anon', 'public.direction_praxis_regler_conversations(integer,boolean)', 'EXECUTE')
     AND NOT has_function_privilege('service_role', 'public.direction_praxis_regler_conversations(integer,boolean)', 'EXECUTE')
     AND NOT has_function_privilege('agent_ro', 'public.direction_praxis_regler_conversations(integer,boolean)', 'EXECUTE')
     AND NOT has_function_privilege('service_role', 'private.praxis_tenue_par_direction(uuid)', 'EXECUTE')
     AND NOT has_function_privilege('authenticated', 'private.praxis_tenue_par_direction(uuid)', 'EXECUTE')
     AND NOT has_function_privilege('anon', 'private.praxis_tenue_par_direction(uuid)', 'EXECUTE')
     AND NOT has_function_privilege('service_role', 'private.praxis_auteur_direction(uuid,uuid)', 'EXECUTE')
     AND NOT has_function_privilege('authenticated', 'private.praxis_auteur_direction(uuid,uuid)', 'EXECUTE')
     AND NOT has_function_privilege('anon', 'private.praxis_auteur_direction(uuid,uuid)', 'EXECUTE') $$);
SELECT pg_temp.verif('DROITS outils remplaces : service_role seul, SECURITY DEFINER, search_path vide', $$
  SELECT bool_and(has_function_privilege('service_role', p.oid, 'EXECUTE') AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  AND NOT has_function_privilege('anon', p.oid, 'EXECUTE') AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""'])
           AND count(*) = 8
    FROM pg_proc p WHERE p.oid IN ('public.praxis_boite(text,text,integer)'::regprocedure, 'public.praxis_fil(text,uuid,integer)'::regprocedure,
      'public.praxis_ecrire(text,uuid,text,uuid)'::regprocedure, 'public.praxis_etat(text)'::regprocedure,
      'public.praxis_dossier(text,text)'::regprocedure, 'public.praxis_boite_candidats(text,text,integer,integer)'::regprocedure,
      'public.praxis_rendre_compte(text,integer)'::regprocedure, 'public.praxis_reponses_equipe(text,integer)'::regprocedure) $$);
SELECT pg_temp.verif('REGLAGES a l''installation : 7 jours, entretiens ecrits suspendus', $$
  SELECT r.direction_tient_jours = 7 AND NOT r.entretiens_ecrits_ouverts FROM private.praxis_reglages r $$);

-- ===== 1. LA DEFINITION =====
SELECT pg_temp.verif('1 TENUE : c10 (la direction a informe, la candidate remercie) est tenue par la direction', $$ SELECT pg_temp.tenue('10') $$);
SELECT pg_temp.verif('1 TENUE : c11 (la candidate ecrit d''elle-meme, l''academie jamais) n''est pas tenue', $$ SELECT NOT pg_temp.tenue('11') $$);
SELECT pg_temp.verif('1 TENUE : c12 (la direction a ecrit il y a 10 jours, N = 7) n''est pas tenue', $$ SELECT NOT pg_temp.tenue('12') $$);
SELECT pg_temp.verif('1 TENUE : c13 (Praxis a ecrit apres la direction) n''est pas tenue', $$ SELECT NOT pg_temp.tenue('13') $$);
SELECT pg_temp.verif('1 TENUE : une conversation inconnue n''est pas tenue', $$ SELECT NOT private.praxis_tenue_par_direction(gen_random_uuid()) $$);
SELECT pg_temp.verif_annule('1 REGLAGE N : a 30 jours, c12 (direction il y a 10 jours) devient tenue', $$
  SELECT pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(30, NULL)') $$, $$
  SELECT pg_temp.tenue('12') AND pg_temp.tenue('10') AND pg_temp.ligne_boite('attend', '12') IS NULL $$);
SELECT pg_temp.verif_annule('1 REGLAGE N : a 1 jour, c10 (direction il y a 2 jours) n''est plus tenue et revient dans attend', $$
  SELECT pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(1, NULL)') $$, $$
  SELECT NOT pg_temp.tenue('10') AND NOT pg_temp.tenue('12') AND pg_temp.ligne_boite('attend', '10') IS NOT NULL $$);

-- ===== 1 bis. LA DIRECTION, AUTEUR : un compte officiel autre que Praxis (#RA_STAFF) compte ; Praxis et un compte ordinaire non =====
SELECT pg_temp.verif_annule('1 bis STAFF : la direction ecrit par le compte officiel staff, la candidate remercie (c11) : tenue, hors attend, de = direction, ecrire refuse', $$
  INSERT INTO private.comptes_officiels (profile_id, code) VALUES (pg_temp.u('3'), 'staff');
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
   (pg_temp.f('11'), pg_temp.u('3'), pg_temp.idem('901'), 'Note d''information de la direction.', clock_timestamp() - interval '2 hours'),
   (pg_temp.f('11'), pg_temp.u('11'), pg_temp.idem('902'), 'Merci beaucoup.', clock_timestamp() - interval '1 hour') $$, $$
  SELECT pg_temp.tenue('11') AND pg_temp.ligne_boite('attend', '11') IS NULL AND pg_temp.ligne_boite('direction', '11') IS NOT NULL
     AND (SELECT m ->> 'de' FROM jsonb_array_elements(pg_temp.fil('11') -> 'messages') m WHERE m #>> '{contenu_tiers,texte}' LIKE 'Note%') = 'direction'
     AND pg_temp.ecrire('11', '903') ->> 'erreur' = 'fil_de_la_direction'
     AND pg_temp.n($q$public.com_messages m WHERE m.fil_id = pg_temp.f('11')$q$) = 3 $$);
SELECT pg_temp.verif_annule('1 bis STAFF : un message du compte staff il y a 1 jour suffit a direction_recente (c16, question refusee)', $$
  INSERT INTO private.comptes_officiels (profile_id, code) VALUES (pg_temp.u('3'), 'staff');
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
   (pg_temp.f('16'), pg_temp.u('3'), pg_temp.idem('904'), 'Note d''information de la direction.', clock_timestamp() - interval '1 day') $$, $$
  SELECT pg_temp.ouvrir('16', 'question', '905') ->> 'erreur' = 'direction_recente' $$);
SELECT pg_temp.verif_annule('1 bis TEMOIN : le meme compte NON officiel (accountant ordinaire) n''est pas la direction : non tenue, de = autre', $$
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
   (pg_temp.f('11'), pg_temp.u('3'), pg_temp.idem('906'), 'Message ordinaire.', clock_timestamp() - interval '2 hours') $$, $$
  SELECT NOT pg_temp.tenue('11')
     AND (SELECT m ->> 'de' FROM jsonb_array_elements(pg_temp.fil('11') -> 'messages') m WHERE m #>> '{contenu_tiers,texte}' = 'Message ordinaire.') = 'autre' $$);
SELECT pg_temp.verif('1 bis PRAXIS n''est jamais la direction (aide privee)', $$
  SELECT NOT private.praxis_auteur_direction(private.praxis_profil(), pg_temp.f('13')) AND private.praxis_auteur_direction(pg_temp.u('2'), pg_temp.f('13'))
     AND NOT private.praxis_auteur_direction(pg_temp.u('13'), pg_temp.f('13')) AND NOT private.praxis_auteur_direction(NULL, pg_temp.f('13'))
     AND NOT private.praxis_auteur_direction(gen_random_uuid(), pg_temp.f('13')) $$);
-- Hors candidature : une conversation de FOYER (type dossier, une tutrice), meme regle.
SELECT pg_temp.verif_annule('1 bis FOYER (type dossier) : la direction informe, la tutrice remercie : tenue, hors attend, ecrire refuse', $$
  INSERT INTO public.households (id) VALUES ('5c1dbbbb-0000-4000-8000-000000000020');
  INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
   (pg_temp.u('20'), 'P6-TUT-0020', 'guardian', '5c1dbbbb-0000-4000-8000-000000000020', 'Tutrice', 'Foyer', 'active', 'female');
  INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
  VALUES (pg_temp.f('20'), 'dossier', pg_temp.u('20'), 'foyer', '5c1dbbbb-0000-4000-8000-000000000020', 'equipe', NULL);
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
   (pg_temp.f('20'), pg_temp.u('2'), pg_temp.idem('920'), 'Information de la direction au foyer.', clock_timestamp() - interval '2 days'),
   (pg_temp.f('20'), pg_temp.u('20'), pg_temp.idem('921'), 'Merci.', clock_timestamp() - interval '1 day') $$, $$
  SELECT pg_temp.tenue('20') AND pg_temp.ligne_boite('attend', '20') IS NULL AND pg_temp.ligne_boite('direction', '20') IS NOT NULL
     AND pg_temp.ecrire('20', '922') ->> 'erreur' = 'fil_de_la_direction'
     AND pg_temp.n($q$public.com_messages m WHERE m.fil_id = pg_temp.f('20')$q$) = 2 $$);
SELECT pg_temp.verif_annule('1 bis FOYER (type dossier) TEMOIN : a N = 1 jour, la meme conversation attend Praxis et ecrire passe', $$
  INSERT INTO public.households (id) VALUES ('5c1dbbbb-0000-4000-8000-000000000020');
  INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
   (pg_temp.u('20'), 'P6-TUT-0020', 'guardian', '5c1dbbbb-0000-4000-8000-000000000020', 'Tutrice', 'Foyer', 'active', 'female');
  INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id)
  VALUES (pg_temp.f('20'), 'dossier', pg_temp.u('20'), 'foyer', '5c1dbbbb-0000-4000-8000-000000000020', 'equipe', NULL);
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
   (pg_temp.f('20'), pg_temp.u('2'), pg_temp.idem('923'), 'Information de la direction au foyer.', clock_timestamp() - interval '2 days'),
   (pg_temp.f('20'), pg_temp.u('20'), pg_temp.idem('924'), 'Merci.', clock_timestamp() - interval '1 day');
  UPDATE private.praxis_reglages SET direction_tient_jours = 1 $$, $$
  SELECT NOT pg_temp.tenue('20') AND pg_temp.ligne_boite('attend', '20') IS NOT NULL AND pg_temp.ecrire('20', '925') ->> 'ok' = 'true' $$);

-- ===== 2. BOITE =====
SELECT pg_temp.verif('2 BOITE attend : c10 (remerciement apres la direction) n''y est PAS ; c11, c12, c13 y sont', $$
  SELECT pg_temp.ligne_boite('attend', '10') IS NULL AND pg_temp.ligne_boite('attend', '11') IS NOT NULL
     AND pg_temp.ligne_boite('attend', '12') IS NOT NULL AND pg_temp.ligne_boite('attend', '13') IS NOT NULL $$);
SELECT pg_temp.verif('2 BOITE direction : seulement les conversations tenues ou la personne a ecrit en dernier (c10, c14), avec attente_heures', $$
  SELECT (SELECT array_agg((l.x ->> 'id')::uuid ORDER BY l.x ->> 'id') FROM jsonb_array_elements(pg_temp.boite('direction') -> 'fils') l(x))
         = (SELECT array_agg(x ORDER BY x::text) FROM unnest(ARRAY[pg_temp.f('10'), pg_temp.f('14')]) x)
     AND (pg_temp.ligne_boite('direction', '10') ->> 'attente_heures')::int BETWEEN 23 AND 25
     AND pg_temp.ligne_boite('direction', '10') ->> 'tenue_par_la_direction' = 'true' $$);
SELECT pg_temp.verif('2 BOITE direction : une conversation tenue dont le dernier message est de la direction (c15) n''y est pas', $$
  SELECT pg_temp.tenue('15') AND pg_temp.ligne_boite('direction', '15') IS NULL AND pg_temp.ligne_boite('tout', '15') ->> 'tenue_par_la_direction' = 'true' $$);
SELECT pg_temp.verif('2 BOITE tout : chaque conversation porte le booleen tenue_par_la_direction', $$
  SELECT bool_and(jsonb_typeof(l.x -> 'tenue_par_la_direction') = 'boolean') AND count(*) = 7
     AND bool_or((l.x ->> 'id')::uuid = pg_temp.f('11') AND l.x ->> 'tenue_par_la_direction' = 'false')
    FROM jsonb_array_elements(pg_temp.boite('tout') -> 'fils') l(x) $$);
SELECT pg_temp.verif('2 BOITE : un filtre inconnu est refuse (parametre)', $$ SELECT pg_temp.boite('annonces') ->> 'erreur' = 'parametre' $$);

-- ===== 3. FIL =====
SELECT pg_temp.garde('fil10', pg_temp.fil('10'));
SELECT pg_temp.verif('3 FIL : c10 est tenue par la direction ; le message de la direction est « direction », celui de la candidate « interlocuteur »', $$
  SELECT pg_temp.lu('fil10') ->> 'tenue_par_la_direction' = 'true'
     AND pg_temp.lu('fil10') -> 'messages' -> 0 ->> 'de' = 'direction' AND pg_temp.lu('fil10') -> 'messages' -> 0 #>> '{auteur,role}' = 'equipe'
     AND pg_temp.lu('fil10') -> 'messages' -> 1 ->> 'de' = 'interlocuteur' AND pg_temp.lu('fil10') -> 'messages' -> 1 #>> '{auteur,role}' = 'enseignant' $$);
SELECT pg_temp.verif('3 FIL : c13 n''est pas tenue ; le message de Praxis est « praxis »', $$
  SELECT f ->> 'tenue_par_la_direction' = 'false'
     AND (SELECT array_agg(m ->> 'de' ORDER BY o) FROM jsonb_array_elements(f -> 'messages') WITH ORDINALITY x(m, o)) = ARRAY['direction', 'praxis', 'interlocuteur']
    FROM (SELECT pg_temp.fil('13') AS f) y $$);

-- ===== 4. ECRIRE =====
SELECT pg_temp.verif('4 ECRIRE : la candidate remercie apres un message de la direction (c10) : refus fil_de_la_direction, rien n''est ecrit', $$
  SELECT pg_temp.ecrire('10', '100') ->> 'erreur' = 'fil_de_la_direction'
     AND pg_temp.n($q$public.com_messages m WHERE m.fil_id = pg_temp.f('10')$q$) = 2
     AND pg_temp.n($q$private.praxis_journal j WHERE j.outil = 'ecrire' AND j.issue = 'fil_de_la_direction'$q$) = 1 $$);
SELECT pg_temp.verif_annule('4 ECRIRE : la candidate ecrit d''elle-meme, sans message de la direction (c11) : Praxis peut repondre', 'SELECT 1', $$
  SELECT pg_temp.ecrire('11', '110') ->> 'ok' = 'true' $$);
SELECT pg_temp.verif_annule('4 ECRIRE : la direction a ecrit il y a plus de N jours (c12) : Praxis peut repondre', 'SELECT 1', $$
  SELECT pg_temp.ecrire('12', '120') ->> 'ok' = 'true' $$);
SELECT pg_temp.verif_annule('4 ECRIRE : Praxis a ecrit apres la direction, puis la candidate repond (c13) : Praxis peut repondre', 'SELECT 1', $$
  SELECT pg_temp.ecrire('13', '130') ->> 'ok' = 'true' $$);
-- Pas d'exception (decision du pilote, 20/11/2026) : meme une reponse privee de la direction a une question de Praxis sur c14 ne lui permet
-- pas d'ecrire tant que la conversation est tenue.
SELECT pg_temp.verif('4 ECRIRE : c14 tenue par la direction : refus fil_de_la_direction', $$
  SELECT pg_temp.ecrire('14', '140') ->> 'erreur' = 'fil_de_la_direction' $$);
SELECT pg_temp.garde('q14', pg_temp.srv(format('SELECT public.praxis_demander_equipe(%L, %L::uuid, %L)', pg_temp.k('both'), pg_temp.f('14'),
  'La candidate demande le jour de son entretien.')));
SELECT pg_temp.verif('4 ECRIRE : Praxis signale en prive (demander_equipe passe) ; ecrire reste refuse', $$
  SELECT pg_temp.lu('q14') ->> 'ok' = 'true' AND pg_temp.ecrire('14', '141') ->> 'erreur' = 'fil_de_la_direction' $$);
SELECT pg_temp.garde('r14', pg_temp.en(pg_temp.u('2'), 'admin', format('SELECT public.direction_praxis_repondre(%L::uuid, %L)',
  pg_temp.lu('q14') ->> 'id', 'Ne reponds pas, je m''en occupe.')));
SELECT pg_temp.verif('4 ECRIRE sans exception : la direction a repondu en prive : toujours refuse, rien n''est ecrit', $$
  SELECT EXISTS (SELECT 1 FROM private.praxis_questions q WHERE q.id = (pg_temp.lu('q14') ->> 'id')::uuid AND q.repondue_le IS NOT NULL)
     AND pg_temp.ecrire('14', '142') ->> 'erreur' = 'fil_de_la_direction'
     AND pg_temp.n($q$public.com_messages m WHERE m.fil_id = pg_temp.f('14')$q$) = 2 $$);
-- ===== 4 ter. REPONSES_EQUIPE : tenue, perimee, a transmettre =====
CREATE FUNCTION pg_temp.reponse(p_q text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM jsonb_array_elements(pg_temp.srv(format('SELECT public.praxis_reponses_equipe(%L, 50)', pg_temp.k('both'))) -> 'reponses') l(x)
   WHERE l.x ->> 'id' = pg_temp.lu(p_q) ->> 'id' $$;
GRANT EXECUTE ON FUNCTION pg_temp.reponse(text) TO service_role;
SELECT pg_temp.verif('4 ter REPONSES : c14 tenue, la direction a repondu en prive : rendue, tenue vrai, perimee faux, a_transmettre faux', $$
  SELECT pg_temp.reponse('q14') ->> 'reponse_de_la_direction' = 'Ne reponds pas, je m''en occupe.'
     AND pg_temp.reponse('q14') ->> 'tenue_par_la_direction' = 'true' AND pg_temp.reponse('q14') ->> 'perimee' = 'false'
     AND pg_temp.reponse('q14') ->> 'a_transmettre' = 'false' $$);
SELECT pg_temp.verif_annule('4 ter REPONSES : la direction ecrit a c14 APRES sa reponse privee : perimee, jamais a transmettre, meme a N = 1 jour ; toujours rendue', $$
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte) VALUES
   (pg_temp.f('14'), pg_temp.u('2'), pg_temp.idem('930'), 'La direction repond elle-meme.');
  UPDATE private.praxis_reglages SET direction_tient_jours = 1 $$, $$
  SELECT pg_temp.reponse('q14') IS NOT NULL AND pg_temp.reponse('q14') ->> 'perimee' = 'true'
     AND pg_temp.reponse('q14') ->> 'a_transmettre' = 'false'
     AND EXISTS (SELECT 1 FROM private.praxis_questions q WHERE q.id = (pg_temp.lu('q14') ->> 'id')::uuid AND q.utilisee_le IS NULL) $$);
SELECT pg_temp.verif_annule('4 ter REPONSES : perimee aussi quand la direction ecrit par le compte officiel staff', $$
  INSERT INTO private.comptes_officiels (profile_id, code) VALUES (pg_temp.u('3'), 'staff');
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte) VALUES
   (pg_temp.f('14'), pg_temp.u('3'), pg_temp.idem('931'), 'Note de la direction.') $$, $$
  SELECT pg_temp.reponse('q14') ->> 'perimee' = 'true' AND pg_temp.reponse('q14') ->> 'a_transmettre' = 'false' $$);
SELECT pg_temp.verif_annule('4 ter REPONSES : c14 n''est plus tenue (N = 1 jour) et rien n''est venu depuis : a_transmettre vrai', $$
  UPDATE private.praxis_reglages SET direction_tient_jours = 1 $$, $$
  SELECT pg_temp.reponse('q14') ->> 'tenue_par_la_direction' = 'false' AND pg_temp.reponse('q14') ->> 'perimee' = 'false'
     AND pg_temp.reponse('q14') ->> 'a_transmettre' = 'true' $$);
SELECT pg_temp.verif_annule('4 ter REPONSES : un message de la personne apres la reponse ne la rend pas perimee (N = 1 jour)', $$
  UPDATE private.praxis_reglages SET direction_tient_jours = 1;
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte) VALUES
   (pg_temp.f('14'), pg_temp.u('14'), pg_temp.idem('932'), 'Encore une question.') $$, $$
  SELECT pg_temp.reponse('q14') ->> 'perimee' = 'false' AND pg_temp.reponse('q14') ->> 'a_transmettre' = 'true' $$);

SELECT pg_temp.verif_annule('4 ECRIRE sans exception : une question retiree puis repondue ne rouvre rien non plus', $$
  UPDATE private.praxis_questions SET retiree_le = clock_timestamp(), retiree_motif = 'sans_objet' WHERE id = (pg_temp.lu('q14') ->> 'id')::uuid $$, $$
  SELECT pg_temp.ecrire('14', '143') ->> 'erreur' = 'fil_de_la_direction' $$);
SELECT pg_temp.verif_annule('4 ECRIRE : quand la conversation n''est plus tenue (N = 1 jour), Praxis peut transmettre a c14', $$
  UPDATE private.praxis_reglages SET direction_tient_jours = 1 $$, $$
  SELECT pg_temp.ecrire('14', '144') ->> 'ok' = 'true' $$);

-- ===== 4 bis. RENDRE_COMPTE : laisse_en_attente suit `attend` =====
SELECT pg_temp.verif('4 bis RENDRE_COMPTE : laisse_en_attente ne compte pas les conversations tenues par la direction (c11, c12, c13 seulement)', $$
  SELECT (pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('both'))) ->> 'laisse_en_attente')::int = 3
     AND jsonb_array_length(pg_temp.boite('attend') -> 'fils') = 3 $$);
SELECT pg_temp.verif_annule('4 bis RENDRE_COMPTE : a N = 1 jour, c10 et c14 attendent de nouveau (5)', $$
  UPDATE private.praxis_reglages SET direction_tient_jours = 1 $$, $$
  SELECT (pg_temp.srv(format('SELECT public.praxis_rendre_compte(%L, 24)', pg_temp.k('both'))) ->> 'laisse_en_attente')::int = 5 $$);

-- ===== 5. OUVRIR : direction_recente pour toutes les raisons, sur N jours =====
SELECT pg_temp.verif('5 OUVRIR : la direction a ecrit il y a 3 jours (c15) : question, relance et felicitations refusees direction_recente', $$
  SELECT pg_temp.ouvrir('15', 'question', '150') ->> 'erreur' = 'direction_recente'
     AND pg_temp.ouvrir('15', 'relance', '151') ->> 'erreur' = 'direction_recente'
     AND pg_temp.ouvrir('15', 'felicitations', '152', 'Felicitations.') ->> 'erreur' = 'direction_recente'
     AND pg_temp.dans_candidats('a_feliciter', '15') ->> 'refus' = 'direction_recente'
     AND pg_temp.n($q$public.com_messages m WHERE m.fil_id = pg_temp.f('15')$q$) = 1 $$);
SELECT pg_temp.verif_annule('5 OUVRIR : la direction a ecrit il y a 8 jours (c16) : la question passe', 'SELECT 1', $$
  SELECT pg_temp.ouvrir('16', 'question', '160') ->> 'ok' = 'true' $$);
SELECT pg_temp.verif_annule('5 OUVRIR : avec N = 2 jours, c15 (direction il y a 3 jours) peut etre felicitee', $$
  SELECT pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(2, NULL)') $$, $$
  SELECT pg_temp.ouvrir('15', 'felicitations', '153', 'Felicitations.') ->> 'ok' = 'true' $$);

-- ===== 6. ENTRETIENS ECRITS SUSPENDUS =====
SELECT pg_temp.verif('6 ENTRETIEN suspendu : entretien_ecrit et relance_entretien refuses entretiens_suspendus ; rien n''est ecrit', $$
  SELECT pg_temp.ouvrir('17', 'entretien_ecrit', '170', 'Pourquoi enseignez-vous ?') ->> 'erreur' = 'entretiens_suspendus'
     AND pg_temp.ouvrir('17', 'relance_entretien', '171', 'Un rappel ?') ->> 'erreur' = 'entretiens_suspendus'
     AND pg_temp.n($q$private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('17')$q$) = 0
     AND NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.objet_id = pg_temp.c('17')) $$);
SELECT pg_temp.verif('6 ENTRETIEN suspendu : boite_candidats a_interroger rend permis faux, refus entretiens_suspendus', $$
  SELECT pg_temp.dans_candidats('a_interroger', '17') ->> 'permis' = 'false'
     AND pg_temp.dans_candidats('a_interroger', '17') ->> 'refus' = 'entretiens_suspendus'
     AND (SELECT bool_and(l.x ->> 'refus' = 'entretiens_suspendus') FROM jsonb_array_elements(pg_temp.candidats('a_interroger') -> 'candidats') l(x)) $$);
SELECT pg_temp.verif('6 ENTRETIEN suspendu : etat le dit (entretiensEcritsSuspendus, directionTientJours)', $$
  SELECT pg_temp.etat() ->> 'entretiensEcritsSuspendus' = 'true' AND (pg_temp.etat() ->> 'directionTientJours')::int = 7 $$);
SELECT pg_temp.verif('6 PORTE : refusee hors direction, sans aal2, et pour une valeur invalide ; rien ne change', $$
  SELECT pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(NULL, true)', 'authenticated', 'aal1') = '42501'
     AND pg_temp.code_en(pg_temp.u('10'), 'teacher', 'SELECT public.direction_praxis_regler_conversations(NULL, true)') = '42501'
     AND pg_temp.code_en(NULL, NULL, 'SELECT public.direction_praxis_regler_conversations(NULL, true)', 'anon') = '42501'
     AND pg_temp.code_en(NULL, NULL, 'SELECT public.direction_praxis_regler_conversations(NULL, true)', 'service_role') = '42501'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(0, NULL)') = '22023'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(61, NULL)') = '22023'
     AND pg_temp.code_en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(NULL, NULL)') = '22023'
     AND (SELECT r.direction_tient_jours = 7 AND NOT r.entretiens_ecrits_ouverts FROM private.praxis_reglages r) $$);
SELECT pg_temp.verif('6 CONTRAINTE : la table refuse 0 ou 61 jours', $$
  SELECT pg_temp.code_en(NULL, NULL, 'UPDATE private.praxis_reglages SET direction_tient_jours = 0', 'postgres') = '23514'
     AND pg_temp.code_en(NULL, NULL, 'UPDATE private.praxis_reglages SET direction_tient_jours = 61', 'postgres') = '23514' $$);
SELECT pg_temp.garde('rouvre', pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_regler_conversations(NULL, true)'));
SELECT pg_temp.verif('6 ROUVERT par la direction (aal2, journalise) : etat le dit, l''entretien ecrit est permis et part', $$
  SELECT pg_temp.lu('rouvre') = '{"directionTientJours": 7, "entretiensEcritsOuverts": true}'::jsonb
     AND (SELECT count(*) FROM public.audit_logs WHERE action = 'praxis_regle_conversations') = 1
     AND pg_temp.etat() ->> 'entretiensEcritsSuspendus' = 'false'
     AND pg_temp.dans_candidats('a_interroger', '17') ->> 'permis' = 'true'
     AND pg_temp.ouvrir('17', 'entretien_ecrit', '172', 'Pourquoi enseignez-vous ? Qu''aimeriez-vous construire ?') ->> 'ok' = 'true'
     AND pg_temp.dans_candidats('a_interroger', '17') IS NULL $$);

-- ===== 8. UN ENTRETIEN RETIRE (message disparu) N'EST PLUS EN COURS, MAIS LES LIMITES LE COMPTENT =====
SELECT pg_temp.verif('8 RETIRE : le dossier de c18 et de c19 ne dit plus d''entretien ecrit, ni d''ouverture d''entretien', $$
  SELECT pg_temp.dossier('18') -> 'entretien_ecrit' ->> 'etat' = 'aucun' AND pg_temp.dossier('19') -> 'entretien_ecrit' ->> 'etat' = 'aucun'
     AND pg_temp.dossier('18') -> 'praxis' -> 'ouvertures' = '[]'::jsonb AND pg_temp.dossier('19') -> 'praxis' -> 'ouvertures' = '[]'::jsonb $$);
SELECT pg_temp.verif('8 RETIRE : aucune relance d''entretien n''est permise (c18 : serie retiree il y a 9 jours ; c19 : il y a une heure)', $$
  SELECT pg_temp.ouvrir('18', 'relance_entretien', '180', 'Un rappel ?') ->> 'erreur' = 'relance_entretien_sans_objet'
     -- c19 : l'ouverture d'il y a une heure compte toujours pour la frequence, qui refuse avant meme de chercher une serie.
     AND pg_temp.ouvrir('19', 'relance_entretien', '190', 'Un rappel ?') ->> 'erreur' = 'ouverture_recente' $$);
SELECT pg_temp.verif('8 RETIRE : la boite a_interroger ne compte plus la serie retiree, et le refus vient des LIMITES', $$
  SELECT pg_temp.dans_candidats('a_interroger', '18') ->> 'refus' = 'plafond_entretiens'
     AND pg_temp.dans_candidats('a_interroger', '19') ->> 'refus' = 'ouverture_recente' $$);
SELECT pg_temp.verif('8 RETIRE : les limites comptent toujours ces ouvertures (deux series en tout ; une ouverture par 7 jours ; la fenetre)', $$
  SELECT pg_temp.ouvrir('18', 'entretien_ecrit', '181', 'Pourquoi enseignez-vous ?') ->> 'erreur' = 'plafond_entretiens'
     AND pg_temp.ouvrir('19', 'entretien_ecrit', '191', 'Pourquoi enseignez-vous ?') ->> 'erreur' = 'ouverture_recente'
     AND pg_temp.ouvrir('19', 'question', '192') ->> 'erreur' = 'ouverture_recente'
     AND (pg_temp.etat() ->> 'ouverturesRestantesFenetre')::int
         = 100 - pg_temp.n($q$private.praxis_ouvertures o WHERE o.raison <> 'felicitations' AND o.ouverte_le > now() - interval '5 hours'$q$)::int
     AND pg_temp.n($q$private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('19') AND o.ouverte_le > now() - interval '5 hours'$q$) = 1 $$);
SELECT pg_temp.verif('8 TEMOIN : une serie dont le message existe reste en cours (c17, envoyee plus haut)', $$
  SELECT pg_temp.dossier('17') -> 'entretien_ecrit' ->> 'etat' = 'en_cours' $$);
-- La serie de c17 est vieillie de 8 jours (hors ouverture_recente) : seul entretien_en_cours peut refuser une nouvelle serie.
SELECT pg_temp.verif_annule('8 TEMOIN : serie de c17 vieillie de 8 jours, message present : une nouvelle serie est refusee entretien_en_cours', $$
  UPDATE private.praxis_ouvertures SET ouverte_le = ouverte_le - interval '8 days' WHERE candidature_id = pg_temp.c('17') $$, $$
  SELECT pg_temp.ouvrir('17', 'entretien_ecrit', '173', 'Encore ?') ->> 'erreur' = 'entretien_en_cours' $$);

-- ===== AUCUNE DONNEE EFFACEE =====
SELECT pg_temp.verif('AUCUN EFFACEMENT : les messages et les ouvertures de la fixture sont tous la', $$
  -- Les 12 messages de la fixture (cles idem 1 a 12) sont tous la, plus l'entretien ecrit de c17 (6 ROUVERT), rien d'autre.
  SELECT pg_temp.n('public.com_messages m WHERE m.cle_idempotence IN (SELECT pg_temp.idem(n::text) FROM generate_series(1, 12) n)') = 12
     AND pg_temp.n('public.com_messages m WHERE m.fil_id IN (SELECT f.id FROM public.com_fils f WHERE f.objet_id IN (SELECT c.id FROM public.candidatures c WHERE c.nom_complet LIKE ''Prenomsecret%''))') = 13
     AND pg_temp.n('private.praxis_ouvertures o WHERE o.candidature_id IN (pg_temp.c(''18''), pg_temp.c(''19''))') = 3 $$);

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 110) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN RAISE EXCEPTION 'PRAXIS-PX6 : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok); END IF;
  RAISE NOTICE 'PRAXIS-PX6 : % verifications, toutes vertes', (SELECT count(*) FROM res);
END $$;
ROLLBACK;
