-- PRAXIS-DOSSIER-COMPLET (PX-4, migration 20261130200000, directeur 20/11/2026) : lire tout un dossier (`dossier`), noter une impression
-- (criteres et contexte), ouvrir le dialogue (boite des candidats, `ouvrir`, `ecrire` resserre), chercher les meilleurs (`lire`). Chaque
-- verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue s'il reste un ROUGE. Couvre, par point : le cas
-- passant, chaque refus, chaque plafond, l'idempotence, les droits (anon et authenticated refuses), et l'ABSENCE de toute donnee interdite
-- dans ce que rend `dossier`. Les aides du debut sont celles de scenarios_praxis_travail.sql.
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


-- Une verification dont les ecritures de preparation sont ANNULEES (un plafond se prouve sans laisser de ligne).
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
-- Un compte lu APRES l'appel qui precede dans la meme verification : une sous-requete simple garderait l'image d'avant l'appel.
CREATE FUNCTION pg_temp.n(p_sql text) RETURNS bigint LANGUAGE plpgsql VOLATILE AS $$
DECLARE v bigint;
BEGIN EXECUTE 'SELECT count(*) FROM ' || p_sql INTO v; RETURN v; END $$;
-- Un fuseau ou il est `p_heure` heures maintenant (pour prouver la regle de nuit a toute heure du jour).
CREATE FUNCTION pg_temp.fuseau_ou_il_est(p_heure integer) RETURNS text LANGUAGE sql AS $$
  SELECT CASE WHEN k = 0 THEN 'Etc/GMT' WHEN k <= 12 THEN 'Etc/GMT-' || k ELSE 'Etc/GMT+' || (24 - k) END
    FROM (SELECT ((p_heure - EXTRACT(hour FROM clock_timestamp() AT TIME ZONE 'UTC')::integer) % 24 + 24) % 24 AS k) x $$;

INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'px4-' || n || '@test.invalid' FROM generate_series(1, 30) n;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.h('1'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'P4-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'P4-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('3'), 'P4-TUT-0001', 'guardian', pg_temp.h('1'), 'Tutrice', 'Un', 'active', 'female');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(n::text), 'P4-CAN-00' || n, 'teacher', NULL, 'Candidat' || n, 'Nomsecret', 'pending_kyc',
       CASE WHEN n = 11 THEN 'male' ELSE 'female' END::public.gender FROM generate_series(10, 24) n;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(10, 24) n;
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('1'));
-- c10 : le dossier complet (reponses, conversation, evenements). c11 : l'autre cote. c12 refusee, c13 en pause, c14 restreinte, c15 majorite
-- non attestee : FERMES. c16 : sans conversation, inactif depuis 10 jours. c17 : il fait nuit chez lui. c18 : admis en verification il y a
-- une heure. c20 : la direction vient de lui ecrire. c22 : recu a l'instant. c23, c24 : inactifs, sans conversation.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, restreinte, source, recue_le, derniere_activite) VALUES
 (pg_temp.c('10'), 'enseignant', pg_temp.u('10'), 'female', 'Prenomdix Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '9 days', now() - interval '5 days'),
 (pg_temp.c('11'), 'enseignant', pg_temp.u('11'), 'male', 'Homme Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '9 days', now()),
 (pg_temp.c('12'), 'enseignant', pg_temp.u('12'), 'female', 'Refusee Nomsecret', 'prequalification', 'a_completer', 'refusee', false, false, 'lien_public', now() - interval '9 days', now()),
 (pg_temp.c('13'), 'enseignant', pg_temp.u('13'), 'female', 'Pause Nomsecret', 'prequalification', 'a_completer', 'en_cours', true, false, 'lien_public', now() - interval '9 days', now()),
 (pg_temp.c('14'), 'enseignant', pg_temp.u('14'), 'female', 'Restreinte Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '9 days', now()),
 (pg_temp.c('15'), 'enseignant', pg_temp.u('15'), 'female', 'Sansmajorite Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '9 days', now()),
 (pg_temp.c('16'), 'enseignant', pg_temp.u('16'), 'female', 'Seize Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '10 days'),
 (pg_temp.c('17'), 'enseignant', pg_temp.u('17'), 'female', 'Nuit Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '9 days'),
 (pg_temp.c('18'), 'enseignant', pg_temp.u('18'), 'female', 'Admise Nomsecret', 'verifications', 'en_examen', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '1 hour'),
 (pg_temp.c('20'), 'enseignant', pg_temp.u('20'), 'female', 'Vingt Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '8 days'),
 (pg_temp.c('21'), 'enseignant', pg_temp.u('21'), 'female', 'Vingtetun Nomsecret', 'verifications', 'entretien_a_planifier', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '6 days'),
 (pg_temp.c('22'), 'enseignant', pg_temp.u('22'), 'female', 'Recente Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now(), now()),
 (pg_temp.c('23'), 'enseignant', pg_temp.u('23'), 'female', 'Vingttrois Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '7 days'),
 (pg_temp.c('24'), 'enseignant', pg_temp.u('24'), 'female', 'Vingtquatre Nomsecret', 'prequalification', 'a_completer', 'en_cours', false, false, 'lien_public', now() - interval '10 days', now() - interval '6 days');
UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = clock_timestamp()
 WHERE id IN (SELECT pg_temp.c(n::text) FROM generate_series(10, 24) n WHERE n <> 15);
UPDATE public.candidatures SET restreinte = true, restriction_cause = 'manuelle' WHERE id = pg_temp.c('14');
UPDATE public.candidatures SET fuseau_iana = pg_temp.fuseau_ou_il_est(2) WHERE id = pg_temp.c('17');
UPDATE public.candidatures SET fuseau_iana = pg_temp.fuseau_ou_il_est(12), pays_residence = 'MA', langue = 'ar' WHERE id = pg_temp.c('10');
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone) VALUES (pg_temp.c('10'), 'adresse.secrete@test.invalid', '+33612345678');
-- Les reponses de c10 : les champs utiles, plus trois champs de MOYEN DE VERSEMENT qui ne doivent jamais sortir.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le) VALUES
 (pg_temp.c('10'), 'salle-examen-2', '{"langueMaternelle": "ar", "languesExplication": ["ar", "fr"], "niveauMemorisationDeclare": "coran_entier",
   "niveauLectureTajwid": "tajwid_enseigne", "riwayat": ["hafs", "warsh"], "ijazaPresentable": "oui", "experienceDebutants": "oui",
   "disponibilitesDeclarees": [{"jour": 1, "debut": "18:00", "fin": "20:00"}], "fuseauIana": "Africa/Casablanca", "classesSouhaitees": "2",
   "debutPossible": "immediat", "publics": ["6_9", "adultes"], "paysResidence": "MA", "paysVersement": "MA",
   "compteBancaire": true, "operateurs": ["OPERATEURSECRET"], "moyensAccessibles": ["MOYENSECRET"]}'::jsonb, 'candidat', now() - interval '6 days'),
 (pg_temp.c('16'), 'salle-examen-2', '{"languesExplication": ["en"], "riwayat": ["hafs"], "ijazaPresentable": "non", "publics": ["adultes"]}'::jsonb, 'candidat', now() - interval '10 days');
-- Revue PX-4 : un BROUILLON de c10, plus recent que son envoi, avec d'autres valeurs : il n'est jamais lu (ni par dossier, ni par les filtres).
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le, brouillon, envoye_le) VALUES
 (pg_temp.c('10'), 'salle-examen-2', '{"langueMaternelle": "BROUILLONSECRET", "ijazaPresentable": "non", "paysVersement": "XX"}'::jsonb, 'candidat',
  now() - interval '5 days 1 hour', true, NULL);
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, auteur_id, motif_interne, details, cree_le) VALUES
 (pg_temp.c('10'), 'transition', 'invitee', 'prequalification', pg_temp.u('2'), 'MOTIFSECRET de la direction', '{"geste": "inviter", "auteur": "direction"}', now() - interval '8 days'),
 (pg_temp.c('10'), 'lecture_contact', NULL, NULL, pg_temp.u('2'), NULL, '{}', now() - interval '7 days'),
 (pg_temp.c('18'), 'transition', 'prequalification', 'verifications', pg_temp.u('2'), NULL, '{"geste": "admettre_verifications", "auteur": "direction"}', now() - interval '1 hour'),
 -- Une decision positive de plus de 72 heures (c20) : elle ne se felicite plus.
 (pg_temp.c('20'), 'transition', 'prequalification', 'verifications', pg_temp.u('2'), NULL, '{"geste": "admettre_verifications", "auteur": "direction"}', now() - interval '4 days');
-- Les conversations : c10 (la candidate a ecrit il y a 5 jours) ; c20 (la direction a ecrit il y a une heure, la candidate jamais).
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id) VALUES
 (pg_temp.f('10'), 'candidature', pg_temp.c('10'), 'profil', pg_temp.u('10'), 'equipe', NULL),
 (pg_temp.f('20'), 'candidature', pg_temp.c('20'), 'profil', pg_temp.u('20'), 'equipe', NULL);
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le) VALUES
 (pg_temp.f('10'), pg_temp.u('10'), pg_temp.idem('1'), 'Bonjour, je veux transmettre le Coran aux enfants.', clock_timestamp() - interval '5 days'),
 (pg_temp.f('20'), pg_temp.u('2'), pg_temp.idem('2'), 'Bonjour, la direction vous ecrit.', clock_timestamp() - interval '1 hour');

CREATE FUNCTION pg_temp.k(p_nom text) RETURNS text LANGUAGE sql AS $$ SELECT pg_temp.lu(p_nom) ->> 'secret' $$;
CREATE FUNCTION pg_temp.ref(p_n text) RETURNS text LANGUAGE sql AS $$ SELECT c.reference FROM public.candidatures c WHERE c.id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.dossier(p_cle text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_dossier(%L, %L)', pg_temp.k(p_cle), pg_temp.ref(p_n))) $$;
CREATE FUNCTION pg_temp.impression(p_cle text, p_n text, p_etiquette text, p_notes text, p_texte text, p_confiance text, p_idem text,
                                    p_contexte text DEFAULT '[]', p_synthese text DEFAULT NULL) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_noter_impression(%L, %L, %L, %L::jsonb, %L::jsonb, %L::jsonb, %L, %L, %L::uuid)',
    pg_temp.k(p_cle), pg_temp.ref(p_n), p_etiquette, p_notes, p_contexte, p_synthese, p_texte, p_confiance, pg_temp.idem(p_idem))) $$;
-- Ecrire le premier avec un texte choisi (l'entretien ecrit compte les questions).
CREATE FUNCTION pg_temp.ouvrir_t(p_cle text, p_n text, p_raison text, p_texte text, p_idem text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, %L, %L, %L, %L::uuid)', pg_temp.k(p_cle), pg_temp.ref(p_n), p_raison, p_texte, pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.ouvrir(p_cle text, p_n text, p_raison text, p_idem text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, %L, %L, ''Bonjour, un mot de Praxis.'', %L::uuid)',
    pg_temp.k(p_cle), pg_temp.ref(p_n), p_raison, pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.ecrire(p_cle text, p_fil uuid, p_idem text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Reponse de Praxis.'', %L::uuid)', pg_temp.k(p_cle), p_fil, pg_temp.idem(p_idem))) $$;
CREATE FUNCTION pg_temp.boite(p_cle text, p_filtre text, p_jours integer DEFAULT 3) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_boite_candidats(%L, %L, %s, 50)', pg_temp.k(p_cle), p_filtre, p_jours)) $$;
-- La ligne d'une candidature dans la boite des candidats.
CREATE FUNCTION pg_temp.dans_boite(p_cle text, p_filtre text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT l.x FROM jsonb_array_elements(pg_temp.boite(p_cle, p_filtre) -> 'candidats') l(x) WHERE l.x ->> 'reference' = pg_temp.ref(p_n) $$;
CREATE FUNCTION pg_temp.lire(p_cle text, p_filtre text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(format('SELECT public.praxis_lire(%L, ''candidatures'', %L::jsonb, 50)', pg_temp.k(p_cle), p_filtre)) $$;
CREATE FUNCTION pg_temp.refs(p_j jsonb) RETURNS text[] LANGUAGE sql AS $$
  SELECT coalesce(array_agg(l.x ->> 'reference' ORDER BY l.o), '{}') FROM jsonb_array_elements(p_j -> 'lignes') WITH ORDINALITY l(x, o) $$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated, anon, service_role;

SELECT pg_temp.garde('both', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat deux cotes', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000041'::uuid)$$));
SELECT pg_temp.garde('fem', pg_temp.en(pg_temp.u('2'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat femme', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000042'::uuid)$$));

-- ===== DROITS =====
SELECT pg_temp.verif('DROITS outil ' || x.f || ' : service_role seul', format(
  $v$SELECT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('authenticated', %L, 'EXECUTE') AND NOT has_function_privilege('agent_ro', %L, 'EXECUTE')$v$, x.f, x.f, x.f, x.f))
  FROM (VALUES ('public.praxis_dossier(text,text)'), ('public.praxis_noter_impression(text,text,text,jsonb,jsonb,jsonb,text,text,uuid)'),
               ('public.praxis_boite_candidats(text,text,integer,integer)'), ('public.praxis_ouvrir(text,text,text,text,uuid)'),
               ('public.praxis_lire(text,text,jsonb,integer)'), ('public.praxis_ecrire(text,uuid,text,uuid)'),
               ('public.praxis_noter_refus(text,text)')) x(f);
SELECT pg_temp.verif('DROITS porte direction_praxis_impressions : authenticated seul', $$
  SELECT has_function_privilege('authenticated', 'public.direction_praxis_impressions(text,integer,integer)', 'EXECUTE')
     AND NOT has_function_privilege('anon', 'public.direction_praxis_impressions(text,integer,integer)', 'EXECUTE')
     AND NOT has_function_privilege('service_role', 'public.direction_praxis_impressions(text,integer,integer)', 'EXECUTE')
     AND NOT has_function_privilege('agent_ro', 'public.direction_praxis_impressions(text,integer,integer)', 'EXECUTE') $$);
SELECT pg_temp.verif('DROITS aide ' || x.f || ' : aucun role client', format(
  $v$SELECT NOT has_function_privilege('service_role', %L, 'EXECUTE') AND NOT has_function_privilege('anon', %L, 'EXECUTE')
        AND NOT has_function_privilege('authenticated', %L, 'EXECUTE')$v$, x.f, x.f, x.f))
  FROM (VALUES ('private.praxis_dossier_ouvert(public.candidatures,public.gender[])'), ('private.praxis_reponses(uuid)'),
               ('private.praxis_heure_locale(text)'), ('private.praxis_fil_candidature(public.candidatures)'),
               ('private.praxis_decision_positive(uuid)'), ('private.praxis_impression_mot_interdit(text)'),
               ('private.praxis_ouverture_refus(public.candidatures,text,public.gender[])')) x(f);
SELECT pg_temp.verif('DROITS tables : RLS active, aucune politique, aucun droit client', $$
  SELECT (SELECT bool_and(c.relrowsecurity) FROM pg_class c WHERE c.oid IN ('private.praxis_impressions'::regclass, 'private.praxis_ouvertures'::regclass))
     AND NOT EXISTS (SELECT 1 FROM pg_policies p WHERE p.schemaname = 'private' AND p.tablename IN ('praxis_impressions', 'praxis_ouvertures'))
     AND NOT has_table_privilege('authenticated', 'private.praxis_impressions', 'SELECT') AND NOT has_table_privilege('service_role', 'private.praxis_impressions', 'INSERT')
     AND NOT has_table_privilege('anon', 'private.praxis_ouvertures', 'SELECT') AND NOT has_table_privilege('service_role', 'private.praxis_ouvertures', 'SELECT') $$);
SELECT pg_temp.refus_en(NULL, NULL, format('SELECT public.praxis_dossier(%L, ''CAND-00001'')', pg_temp.k('both')),
  '42501', 'DROITS appel : anon ne peut pas appeler praxis_dossier', 'anon');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', format('SELECT public.praxis_dossier(%L, ''CAND-00001'')', pg_temp.k('both')),
  '42501', 'DROITS appel : un administrateur connecte ne peut pas appeler praxis_dossier');
SELECT pg_temp.refus_en(pg_temp.u('1'), 'admin', format('SELECT public.praxis_noter_impression(%L, ''CAND-00001'', ''solide'', ''{}'', ''[]'', NULL, ''x'', ''forte'', %L::uuid)', pg_temp.k('both'), pg_temp.idem('900')),
  '42501', 'DROITS appel : un administrateur connecte ne peut pas appeler praxis_noter_impression');
SELECT pg_temp.refus_en(NULL, NULL, format('SELECT public.praxis_ouvrir(%L, ''CAND-00001'', ''question'', ''x'', %L::uuid)', pg_temp.k('both'), pg_temp.idem('901')),
  '42501', 'DROITS appel : anon ne peut pas appeler praxis_ouvrir', 'anon');
SELECT pg_temp.refus_en(pg_temp.u('10'), 'teacher', format('SELECT public.praxis_boite_candidats(%L, ''sans_nouvelles'', 3, 5)', pg_temp.k('both')),
  '42501', 'DROITS appel : un candidat ne peut pas appeler praxis_boite_candidats');
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.direction_praxis_impressions()', '42501', 'DROITS appel : anon ne lit pas les impressions', 'anon');
SELECT pg_temp.refus_en(pg_temp.u('3'), 'guardian', 'SELECT public.direction_praxis_impressions()', '42501', 'DROITS garde : une tutrice ne lit pas les impressions');
SELECT pg_temp.refus_en(pg_temp.u('10'), 'teacher', 'SELECT public.direction_praxis_impressions()', '42501', 'DROITS garde : un candidat ne lit pas les impressions');

-- ===== PORTE : eteint, puis donnees reelles fermees =====
SELECT pg_temp.verif('PORTE eteint : les quatre outils refusent, rien d''ecrit', $$
  SELECT pg_temp.dossier('both', '10') ->> 'erreur' = 'eteint'
     AND pg_temp.impression('both', '10', 'solide', '{}', 'Texte.', 'forte', '100') ->> 'erreur' = 'eteint'
     AND pg_temp.boite('both', 'sans_nouvelles') ->> 'erreur' = 'eteint'
     AND pg_temp.ouvrir('both', '16', 'relance', '101') ->> 'erreur' = 'eteint'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_impressions) AND NOT EXISTS (SELECT 1 FROM private.praxis_ouvertures) $$);
SELECT pg_temp.garde('on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));
SELECT pg_temp.verif('PORTE donnees reelles fermees : les quatre outils refusent, aucune conversation creee', $$
  SELECT pg_temp.dossier('both', '10') ->> 'erreur' = 'donnees_reelles_fermees'
     AND pg_temp.impression('both', '10', 'solide', '{}', 'Texte.', 'forte', '102') ->> 'erreur' = 'donnees_reelles_fermees'
     AND pg_temp.boite('both', 'sans_nouvelles') ->> 'erreur' = 'donnees_reelles_fermees'
     AND pg_temp.ouvrir('both', '16', 'relance', '103') ->> 'erreur' = 'donnees_reelles_fermees'
     AND NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.objet_id = pg_temp.c('16')) $$);
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ===== 1. DOSSIER =====
SELECT pg_temp.garde('d10', pg_temp.dossier('both', '10'));
SELECT pg_temp.verif('DOSSIER passant : identite du dossier (cote, langue, etape, etat, anciennete, pays, fuseau)', $$
  SELECT d ->> 'reference' = pg_temp.ref('10') AND d ->> 'cote' = 'female' AND d ->> 'langue' = 'ar' AND d ->> 'etape' = 'prequalification'
     AND d ->> 'etat' = 'a_completer' AND (d ->> 'anciennete_jours')::int = 9 AND d ->> 'pays_residence' = 'MA' AND d ->> 'fuseau' IS NOT NULL
     AND (d ->> 'jours_sans_activite_candidat')::int = 5 AND d -> 'entretien' ->> 'etat' = 'aucun'
    FROM (SELECT pg_temp.lu('d10') AS d) x $$);
SELECT pg_temp.verif('DOSSIER passant : toutes les reponses utiles, sous contenu_tiers', $$
  SELECT r ->> 'langueMaternelle' = 'ar' AND r -> 'languesExplication' = '["ar", "fr"]' AND r ->> 'niveauMemorisationDeclare' = 'coran_entier'
     AND r ->> 'niveauLectureTajwid' = 'tajwid_enseigne' AND r -> 'riwayat' = '["hafs", "warsh"]' AND r ->> 'ijazaPresentable' = 'oui'
     AND r ->> 'experienceDebutants' = 'oui' AND jsonb_array_length(r -> 'disponibilitesDeclarees') = 1 AND r ->> 'fuseauIana' = 'Africa/Casablanca'
     AND r ->> 'classesSouhaitees' = '2' AND r ->> 'debutPossible' = 'immediat' AND r -> 'publics' = '["6_9", "adultes"]' AND r ->> 'paysResidence' = 'MA'
     AND d -> 'contenu_tiers' ->> 'prenom' = 'Prenomdix' AND NOT d ? 'questionnaire'
    FROM (SELECT pg_temp.lu('d10') AS d, pg_temp.lu('d10') -> 'contenu_tiers' -> 'questionnaire' -> 'reponses' AS r) x $$);
SELECT pg_temp.verif('DOSSIER brouillon : le questionnaire non envoye n''est jamais lu (revue PX-4)', $$
  SELECT pg_temp.lu('d10')::text !~ 'BROUILLONSECRET' AND pg_temp.lu('d10') -> 'versement' ->> 'pays' = 'MA'
     AND pg_temp.lu('d10') -> 'contenu_tiers' -> 'questionnaire' ->> 'soumis_le' IS NOT NULL
     AND (pg_temp.lu('d10') -> 'contenu_tiers' -> 'questionnaire' ->> 'soumis_le')::timestamptz < now() - interval '5 days 12 hours' $$);
SELECT pg_temp.verif('DOSSIER passant : versement = pays et possible, rien d''autre', $$
  SELECT pg_temp.lu('d10') -> 'versement' = '{"pays": "MA", "possible": "inconnu"}'::jsonb $$);
SELECT pg_temp.verif('DOSSIER passant : ce qui manque, les gestes, l''historique (types et dates, sans lecture de contact)', $$
  SELECT jsonb_typeof(d -> 'manquants') = 'array' AND jsonb_typeof(d -> 'attend_direction') = 'array' AND d ? 'complet' AND jsonb_typeof(d -> 'gestes') = 'array'
     AND jsonb_array_length(d -> 'historique') = 1 AND d -> 'historique' -> 0 ->> 'geste' = 'inviter' AND d -> 'historique' -> 0 ->> 'auteur' = 'direction'
     AND d -> 'historique' -> 0 ->> 'etape_apres' = 'prequalification' AND NOT (d -> 'historique' -> 0) ? 'motif_interne'
    FROM (SELECT pg_temp.lu('d10') AS d) x $$);
SELECT pg_temp.verif('DOSSIER passant : la conversation en comptes, Praxis sans impression ni rangement', $$
  SELECT d -> 'conversation' ->> 'existe' = 'true' AND d -> 'conversation' ->> 'fil' = pg_temp.f('10')::text AND (d -> 'conversation' ->> 'messages')::int = 1
     AND (d -> 'conversation' ->> 'du_candidat')::int = 1 AND d -> 'praxis' -> 'impression' = 'null'::jsonb AND d -> 'praxis' -> 'ouvertures' = '[]'::jsonb
     AND NOT (d -> 'conversation') ? 'texte'
    FROM (SELECT pg_temp.lu('d10') AS d) x $$);
SELECT pg_temp.verif('DOSSIER FUITE : ni courriel, ni telephone, ni nom, ni moyen de versement, ni motif interne, ni texte de message', $$
  SELECT t !~* 'nomsecret' AND t !~* 'adresse\.secrete' AND t !~ '@' AND t !~ '33612345678' AND t !~* 'OPERATEURSECRET' AND t !~* 'MOYENSECRET'
     AND t !~* 'MOTIFSECRET' AND t !~* 'compteBancaire' AND t !~* 'operateurs' AND t !~* 'moyensAccessibles' AND t !~* 'transmettre le Coran'
     AND t !~* 'courriel' AND t !~* 'telephone' AND t !~* 'naissance' AND t !~* 'nom_complet' AND t !~* 'storage' AND t !~* 'P4-CAN'
    FROM (SELECT pg_temp.lu('d10')::text AS t) x $$);
SELECT pg_temp.verif('DOSSIER FUITE : les cles de premier niveau sont exactement la liste attendue', $$
  SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.lu('d10')) k) = ARRAY['a_un_compte', 'anciennete_jours', 'attend_direction',
    'attente_jours', 'complement_en_cours', 'complet', 'contenu_tiers', 'conversation', 'cote', 'entretien', 'entretien_ecrit', 'etape', 'etat', 'fuseau', 'gestes',
    'historique', 'jours_sans_activite_candidat', 'langue', 'manquants', 'pays_residence', 'praxis', 'reference', 'source', 'versement'] $$);
SELECT pg_temp.verif('DOSSIER ferme : refuse, en pause, restreint, majorite non attestee, inconnu = la meme reponse', $$
  SELECT pg_temp.dossier('both', '12') = '{"erreur": "candidature_inconnue"}' AND pg_temp.dossier('both', '13') = '{"erreur": "candidature_inconnue"}'
     AND pg_temp.dossier('both', '14') = '{"erreur": "candidature_inconnue"}' AND pg_temp.dossier('both', '15') = '{"erreur": "candidature_inconnue"}'
     AND pg_temp.srv(format('SELECT public.praxis_dossier(%L, ''CAND-99999999'')', pg_temp.k('both'))) = '{"erreur": "candidature_inconnue"}' $$);
SELECT pg_temp.verif('DOSSIER cote : la cle des femmes ne lit pas un homme ; la cle des deux cotes le lit', $$
  SELECT pg_temp.dossier('fem', '11') = '{"erreur": "candidature_inconnue"}' AND pg_temp.dossier('both', '11') ->> 'cote' = 'male' $$);
SELECT pg_temp.verif('DOSSIER parametre : une reference mal formee', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_dossier(%L, ''x'')', pg_temp.k('both'))) ->> 'erreur' = 'parametre'
     AND pg_temp.srv(format('SELECT public.praxis_dossier(%L, NULL)', pg_temp.k('both'))) ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.verif_annule('DOSSIER plafond : 120 lectures par heure, la 121e est refusee',
  $$INSERT INTO private.praxis_journal (cle_id, emise_par, outil, issue)
    SELECT j.cle_id, j.emise_par, 'dossier', 'ok' FROM (SELECT cle_id, emise_par FROM private.praxis_journal WHERE outil = 'dossier' AND issue = 'ok' LIMIT 1) j, generate_series(1, 120)$$,
  $$SELECT pg_temp.dossier('both', '10') ->> 'erreur' = 'plafond_dossiers'$$);
SELECT pg_temp.verif('DOSSIER journal : ok, candidature_inconnue, parametre, eteint, donnees_reelles_fermees', $$
  SELECT (SELECT count(DISTINCT j.issue) FROM private.praxis_journal j WHERE j.outil = 'dossier'
           AND j.issue IN ('ok', 'candidature_inconnue', 'parametre', 'eteint', 'donnees_reelles_fermees')) = 5 $$);

-- ===== 2. IMPRESSIONS =====
SELECT pg_temp.verif('IMPRESSION passant : notee, une ligne courante', $$
  SELECT pg_temp.impression('both', '10', 'a_creuser', '{"maitrise": 5, "pedagogie": 4, "vision": 3}', 'Coran entier, ijaza presentable, hafs et warsh. Vision peu dite : a demander.', 'moyenne', '200') ->> 'ok' = 'true'
     AND pg_temp.n($q$private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('10') AND i.courant AND i.vision = 3 AND i.comportement IS NULL AND i.contexte = '[]'::jsonb AND i.synthese IS NULL$q$) = 1 $$);
SELECT pg_temp.verif('IMPRESSION idempotence : la meme cle ne reecrit rien', $$
  SELECT pg_temp.impression('both', '10', 'pepite', '{}', 'Autre texte.', 'forte', '200') ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('10')) = 1 $$);
SELECT pg_temp.verif('IMPRESSION inchangee : la meme impression sous une autre cle n''ajoute rien', $$
  SELECT pg_temp.impression('both', '10', 'a_creuser', '{"maitrise": 5, "pedagogie": 4, "vision": 3}', 'Coran entier, ijaza presentable, hafs et warsh. Vision peu dite : a demander.', 'moyenne', '201') ->> 'inchange' = 'true'
     AND (SELECT count(*) FROM private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('10')) = 1 $$);
SELECT pg_temp.verif('IMPRESSION par ajout : la nouvelle fait foi, l''ancienne est gardee', $$
  SELECT pg_temp.impression('both', '10', 'pepite', '{"maitrise": 5, "pedagogie": 4, "vision": 5, "comportement": 4, "disponibilite": 3}', 'Veut transmettre aux enfants, repond vite et clairement.', 'moyenne', '202') ->> 'etiquette_precedente' = 'a_creuser'
     AND pg_temp.n($q$private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('10')$q$) = 2
     AND pg_temp.n($q$private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('10') AND i.courant AND i.etiquette = 'pepite'$q$) = 1 $$);
SELECT pg_temp.verif('IMPRESSION refus parametre : etiquette, confiance, note hors de 1 a 5, note non entiere, critere inconnu, texte vide', $$
  SELECT pg_temp.impression('both', '16', 'geniale', '{}', 'T.', 'forte', '210') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '16', 'solide', '{}', 'T.', 'totale', '211') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '16', 'solide', '{"vision": 6}', 'T.', 'forte', '212') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '16', 'solide', '{"vision": 2.5}', 'T.', 'forte', '213') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '16', 'solide', '{"beaute": 3}', 'T.', 'forte', '214') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '16', 'solide', '{"vision": "3"}', 'T.', 'forte', '215') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '16', 'solide', '{}', '   ', 'forte', '216') ->> 'erreur' = 'parametre'
     AND NOT EXISTS (SELECT 1 FROM private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('16')) $$);
SELECT pg_temp.verif('IMPRESSION refus longueur : plus de 800 signes', $$
  SELECT pg_temp.impression('both', '16', 'solide', '{}', repeat('a', 801), 'forte', '217') ->> 'erreur' = 'longueur'
     AND pg_temp.impression('both', '16', 'solide', '{}', repeat('a', 800), 'forte', '218') ->> 'ok' = 'true' $$);
SELECT pg_temp.verif('IMPRESSION texte interdit : ethnie, couleur, apparence, handicap, situation de couple ou de famille', $$
  SELECT pg_temp.impression('both', '16', 'reserve', '{}', 'Son ethnie pose question.', 'faible', '220') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'Sa couleur de peau.', 'faible', '221') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'Apparence peu soignee.', 'faible', '222') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'A un handicap.', 'faible', '223') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'Elle est mariée avec trois enfants.', 'faible', '224') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'Divorcee, situation familiale instable.', 'faible', '225') ->> 'mot' IS NOT NULL
     AND (SELECT count(*) FROM private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('16')) = 1 $$);
SELECT pg_temp.verif('IMPRESSION texte interdit : toute accusation, en francais, en anglais et en arabe', $$
  SELECT pg_temp.impression('both', '16', 'reserve', '{}', 'Risque : associe a des terroristes.', 'faible', '226') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'Peut-etre un fraudeur.', 'faible', '227') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'Looks like a criminal or a terrorist.', 'faible', '228') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'قد يكون إرهابيا', 'faible', '229') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '16', 'reserve', '{}', 'شخص محتال', 'faible', '2290') ->> 'erreur' = 'texte_interdit'
     AND (SELECT count(*) FROM private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('16')) = 1 $$);
SELECT pg_temp.garde('ctx24', pg_temp.impression('both', '24', 'solide', '{"pedagogie": 5, "disponibilite": 5}',
  'Tres bonne pedagogue, beaucoup de creneaux. Reside au Yemen : reseau incertain, versement difficile vers ce pays, conformite du versement a examiner. Dit avoir besoin de ce travail. A decider par la direction.',
  'moyenne', '2291',
  '[{"theme": "besoin du travail", "constat": "Dit que ce travail ferait vivre son foyer.", "source": "message du 12/11", "effet": "a_verifier"},
    {"theme": "stabilite de la connexion et de l''electricite", "constat": "Coupures frequentes, telephone seul.", "source": "message du 12/11 ; pays de residence", "effet": "risque"},
    {"theme": "moyen de recevoir un versement", "constat": "Versement difficile vers ce pays : conformite a examiner par la direction.", "source": "dossier : versement", "effet": "risque"},
    {"theme": "ce qu''elle apporterait de rare", "constat": "Enseigne warsh et hafs aux enfants depuis dix ans.", "source": "questionnaire ; message du 12/11", "effet": "atout"}]',
  '{"utile_pour": "Classes d''enfants debutants, en arabe.", "situation": "Creneaux du matin, si le reseau tient.", "reserves": "Reseau et versement a verifier.", "video": true, "video_pourquoi": "Verifier la connexion en conditions reelles."}'));
SELECT pg_temp.verif('IMPRESSION contexte ouvert : themes libres, source citee, pays admis ; la synthese est gardee', $$
  SELECT pg_temp.lu('ctx24') ->> 'ok' = 'true'
     AND (SELECT jsonb_array_length(i.contexte) = 4 AND i.contexte -> 1 ->> 'effet' = 'risque' AND i.contexte -> 3 ->> 'theme' LIKE 'ce qu%'
                 AND i.synthese ->> 'video' = 'true' AND i.synthese ->> 'utile_pour' LIKE 'Classes%'
            FROM private.praxis_impressions i WHERE i.candidature_id = pg_temp.c('24') AND i.courant) $$);
SELECT pg_temp.verif('IMPRESSION contexte refus de forme : pas une liste, cle en trop, cle manquante (source), effet hors liste, texte trop long, plus de 12', $$
  SELECT pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2293', '{"theme": "x"}') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2294', '[{"theme": "a", "constat": "b", "source": "c", "effet": "atout", "note": 3}]') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2295', '[{"theme": "a", "constat": "b", "effet": "atout"}]') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2296', '[{"theme": "a", "constat": "b", "source": "c", "effet": "defaut"}]') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2297', format('[{"theme": "a", "constat": "%s", "source": "c", "effet": "atout"}]', repeat('b', 201))) ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2298', (SELECT jsonb_agg('{"theme": "a", "constat": "b", "source": "c", "effet": "atout"}'::jsonb)::text FROM generate_series(1, 13))) ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '2299', '["texte"]') ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.verif('IMPRESSION contexte refus de fond : accusation, religion pratiquee, sante, ethnie ou opinion dans un element', $$
  SELECT pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22100', '[{"theme": "risque", "constat": "Lie a des terroristes.", "source": "pays", "effet": "risque"}]') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22101', '[{"theme": "religion", "constat": "Elle est salafie.", "source": "message", "effet": "risque"}]') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22102', '[{"theme": "santé", "constat": "Souvent absente.", "source": "message", "effet": "risque"}]') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22103', '[{"theme": "divers", "constat": "Ses opinions politiques.", "source": "message", "effet": "risque"}]') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22104', '[{"theme": "divers", "constat": "Son ethnie.", "source": "message", "effet": "risque"}]') ->> 'erreur' = 'texte_interdit' $$);
SELECT pg_temp.verif('IMPRESSION synthese refus : cle inconnue, video non booleen, texte trop long, mot interdit', $$
  SELECT pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22110', '[]', '{"decision": "admettre"}') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22111', '[]', '{"video": "oui"}') ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22112', '[]', format('{"reserves": "%s"}', repeat('b', 201))) ->> 'erreur' = 'parametre'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22113', '[]', '{"reserves": "Peut-etre une fraudeuse."}') ->> 'erreur' = 'texte_interdit'
     AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '22114', '[]', '["x"]') ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.verif('IMPRESSION contexte : la direction et le dossier lisent le contexte et la synthese', $$
  SELECT (SELECT l.x -> 'contexte' -> 0 ->> 'theme' = 'besoin du travail' AND l.x -> 'synthese' ->> 'video' = 'true'
            FROM jsonb_array_elements(pg_temp.en(pg_temp.u('2'), 'admin', 'SELECT public.direction_praxis_impressions()') -> 'impressions') l(x)
           WHERE l.x ->> 'reference' = pg_temp.ref('24'))
     AND jsonb_array_length(pg_temp.dossier('both', '24') -> 'praxis' -> 'impression' -> 'contexte') = 4
     AND pg_temp.dossier('both', '24') -> 'praxis' -> 'impression' -> 'synthese' ->> 'situation' LIKE 'Creneaux%' $$);
SELECT pg_temp.verif('IMPRESSION dossier ferme ou de l''autre cote : la meme reponse', $$
  SELECT pg_temp.impression('both', '12', 'solide', '{}', 'T.', 'forte', '230') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.impression('both', '13', 'solide', '{}', 'T.', 'forte', '231') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.impression('both', '14', 'solide', '{}', 'T.', 'forte', '232') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.impression('both', '15', 'solide', '{}', 'T.', 'forte', '233') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.impression('fem', '11', 'solide', '{}', 'T.', 'forte', '234') ->> 'erreur' = 'candidature_inconnue' $$);
SELECT pg_temp.verif_annule('IMPRESSION plafond : 120 par heure',
  $$INSERT INTO private.praxis_impressions (candidature_id, etiquette, texte, confiance, courant, cle_id, emise_par, cle_idempotence)
    SELECT gen_random_uuid(), 'solide', 'x', 'forte', false, i.cle_id, i.emise_par, gen_random_uuid()
      FROM (SELECT cle_id, emise_par FROM private.praxis_impressions LIMIT 1) i, generate_series(1, 120)$$,
  $$SELECT pg_temp.impression('both', '23', 'solide', '{}', 'T.', 'forte', '240') ->> 'erreur' = 'plafond_impressions'$$);
SELECT pg_temp.garde('imp23', pg_temp.impression('both', '23', 'solide', '{"vision": 4}', 'Reponses nettes ; la vision reste a entendre.', 'faible', '241'));
SELECT pg_temp.garde('imp11', pg_temp.impression('both', '11', 'reserve', '{"vision": 1}', 'Peu de faits.', 'forte', '242'));
SELECT pg_temp.verif('IMPRESSION le dossier rend l''impression courante et le compte des anciennes', $$
  SELECT d -> 'praxis' -> 'impression' ->> 'etiquette' = 'pepite' AND (d -> 'praxis' -> 'impression' -> 'notes' ->> 'vision')::int = 5
     AND (d -> 'praxis' ->> 'impressions_passees')::int = 1
    FROM (SELECT pg_temp.dossier('both', '10') AS d) x $$);
SELECT pg_temp.verif('IMPRESSION lecture de la direction : tri par etiquette puis vision, cote, pagination, compteurs', $$
  SELECT (f ->> 'total')::int = 4 AND f -> 'impressions' -> 0 ->> 'etiquette' = 'pepite' AND f -> 'impressions' -> 1 ->> 'reference' = pg_temp.ref('23')
     AND f -> 'impressions' -> 2 ->> 'reference' = pg_temp.ref('24') AND f -> 'impressions' -> 3 ->> 'reference' = pg_temp.ref('16') AND f -> 'parEtiquette' = '{"pepite": 1, "solide": 3}'::jsonb
     AND (h ->> 'total')::int = 5 AND jsonb_array_length(p -> 'impressions') = 1 AND (s ->> 'total')::int = 3
    FROM (SELECT pg_temp.en(pg_temp.u('2'), 'admin', 'SELECT public.direction_praxis_impressions()') AS f,
                 pg_temp.en(pg_temp.u('1'), 'admin', 'SELECT public.direction_praxis_impressions()') AS h,
                 pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.direction_praxis_impressions(NULL, 1, 2)$q$) AS p,
                 pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.direction_praxis_impressions('solide')$q$) AS s) x $$);
SELECT pg_temp.refus_en(pg_temp.u('2'), 'admin', $$SELECT public.direction_praxis_impressions('geniale')$$, '22023', 'IMPRESSION lecture : une etiquette inconnue est refusee');
SELECT pg_temp.verif('IMPRESSION ne declenche rien : aucun evenement, aucune proposition, aucun message, etape inchangee', $$
  SELECT (SELECT count(*) FROM public.candidature_evenements) = 4 AND NOT EXISTS (SELECT 1 FROM private.praxis_propositions)
     AND (SELECT count(*) FROM public.com_messages) = 2 AND (SELECT etape FROM public.candidatures WHERE id = pg_temp.c('10')) = 'prequalification' $$);

-- ===== 4. LIRE : chercher les meilleurs =====
SELECT pg_temp.verif('LIRE : chaque ligne rend l''impression (ou null)', $$
  SELECT (SELECT l.x -> 'impression' ->> 'etiquette' FROM jsonb_array_elements(j -> 'lignes') l(x) WHERE l.x ->> 'reference' = pg_temp.ref('10')) = 'pepite'
     AND (SELECT l.x -> 'impression' FROM jsonb_array_elements(j -> 'lignes') l(x) WHERE l.x ->> 'reference' = pg_temp.ref('20')) = 'null'::jsonb
    FROM (SELECT pg_temp.lire('both', '{}') AS j) x $$);
SELECT pg_temp.verif('LIRE filtres : etiquette, sans impression', $$
  SELECT pg_temp.refs(pg_temp.lire('both', '{"etiquette": "pepite"}')) = ARRAY[pg_temp.ref('10')]
     AND NOT (pg_temp.ref('10') = ANY (pg_temp.refs(pg_temp.lire('both', '{"sans_impression": true}'))))
     AND pg_temp.ref('20') = ANY (pg_temp.refs(pg_temp.lire('both', '{"sans_impression": true}')))
     AND pg_temp.ref('10') = ANY (pg_temp.refs(pg_temp.lire('both', '{"sans_impression": false}')))
     AND NOT (pg_temp.ref('20') = ANY (pg_temp.refs(pg_temp.lire('both', '{"sans_impression": false}')))) $$);
SELECT pg_temp.verif('LIRE filtres : ijaza, riwaya, langue d''explication, public', $$
  SELECT pg_temp.refs(pg_temp.lire('both', '{"ijaza": "oui"}')) = ARRAY[pg_temp.ref('10')]
     AND pg_temp.refs(pg_temp.lire('both', '{"ijaza": "non"}')) = ARRAY[pg_temp.ref('16')]
     AND pg_temp.refs(pg_temp.lire('both', '{"riwaya": "warsh"}')) = ARRAY[pg_temp.ref('10')]
     AND cardinality(pg_temp.refs(pg_temp.lire('both', '{"riwaya": "hafs"}'))) = 2
     AND pg_temp.refs(pg_temp.lire('both', '{"langue_explication": "fr"}')) = ARRAY[pg_temp.ref('10')]
     AND pg_temp.refs(pg_temp.lire('both', '{"public": "6_9"}')) = ARRAY[pg_temp.ref('10')]
     AND cardinality(pg_temp.refs(pg_temp.lire('both', '{"public": "adultes", "riwaya": "hafs", "ijaza": "non"}'))) = 1 $$);
SELECT pg_temp.verif('LIRE tri par vision : la meilleure note d''abord, les dossiers sans note a la fin', $$
  SELECT r[1] = pg_temp.ref('10') AND r[2] = pg_temp.ref('23') AND r[3] = pg_temp.ref('11')
    FROM (SELECT pg_temp.refs(pg_temp.lire('both', '{"tri": "vision"}')) AS r) x $$);
SELECT pg_temp.verif('LIRE refus : valeurs hors liste, types faux, etiquette avec sans_impression', $$
  SELECT pg_temp.lire('both', '{"etiquette": "geniale"}') ->> 'erreur' = 'parametre' AND pg_temp.lire('both', '{"ijaza": "peut_etre"}') ->> 'erreur' = 'parametre'
     AND pg_temp.lire('both', '{"riwaya": "HAFS; x"}') ->> 'erreur' = 'parametre' AND pg_temp.lire('both', '{"public": "bebes"}') ->> 'erreur' = 'parametre'
     AND pg_temp.lire('both', '{"tri": "nom"}') ->> 'erreur' = 'parametre' AND pg_temp.lire('both', '{"sans_impression": "oui"}') ->> 'erreur' = 'parametre'
     AND pg_temp.lire('both', '{"etiquette": "pepite", "sans_impression": true}') ->> 'erreur' = 'parametre'
     AND pg_temp.lire('both', '{"nom": "x"}') ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.verif('LIRE inchange : sans filtre, les dossiers en pause et restreints restent listes comme avant, les anciens filtres marchent', $$
  SELECT pg_temp.ref('13') = ANY (pg_temp.refs(pg_temp.lire('both', '{}'))) AND pg_temp.refs(pg_temp.lire('both', '{"etape": "verifications"}')) @> ARRAY[pg_temp.ref('18'), pg_temp.ref('21')] AND cardinality(pg_temp.refs(pg_temp.lire('both', '{"etape": "verifications"}'))) = 2
     AND NOT (pg_temp.ref('11') = ANY (pg_temp.refs(pg_temp.lire('fem', '{}')))) $$);

-- ===== 3. DIALOGUE =====
SELECT pg_temp.verif('BOITE sans_nouvelles : il manque quelque chose et rien depuis 3 jours ; les dossiers fermes et recents n''y sont pas', $$
  SELECT pg_temp.dans_boite('both', 'sans_nouvelles', '16') ->> 'permis' = 'true' AND pg_temp.dans_boite('both', 'sans_nouvelles', '16') ->> 'raison' = 'relance'
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '16') -> 'fil' = 'null'::jsonb AND jsonb_array_length(pg_temp.dans_boite('both', 'sans_nouvelles', '16') -> 'manquants') > 0
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '10') IS NOT NULL
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '22') IS NULL AND pg_temp.dans_boite('both', 'sans_nouvelles', '12') IS NULL
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '13') IS NULL AND pg_temp.dans_boite('both', 'sans_nouvelles', '14') IS NULL
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '15') IS NULL AND pg_temp.dans_boite('fem', 'sans_nouvelles', '11') IS NULL
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '17') ->> 'refus' = 'heure_tardive'
     AND pg_temp.dans_boite('both', 'sans_nouvelles', '20') ->> 'refus' = 'direction_recente'
     AND pg_temp.boite('both', 'sans_nouvelles', 8) -> 'candidats' @> jsonb_build_array(jsonb_build_object('reference', pg_temp.ref('16')))
     AND NOT (pg_temp.boite('both', 'sans_nouvelles', 8) -> 'candidats' @> jsonb_build_array(jsonb_build_object('reference', pg_temp.ref('10')))) $$);
SELECT pg_temp.verif('BOITE refus parametre : filtre inconnu, moins de 3 jours', $$
  SELECT pg_temp.boite('both', 'tout') ->> 'erreur' = 'parametre' AND pg_temp.boite('both', 'sans_nouvelles', 2) ->> 'erreur' = 'parametre' $$);
SELECT pg_temp.verif('BOITE fuite : ni nom, ni contact', $$
  SELECT pg_temp.boite('both', 'sans_nouvelles')::text !~* 'nomsecret|@|33612345678' $$);
SELECT pg_temp.verif('BOITE a_approfondir : etiquette a entendre et confiance faible ou moyenne ; pas une confiance forte', $$
  SELECT pg_temp.dans_boite('both', 'a_approfondir', '23') ->> 'etiquette' = 'solide' AND pg_temp.dans_boite('both', 'a_approfondir', '10') ->> 'confiance' = 'moyenne'
     AND pg_temp.dans_boite('both', 'a_approfondir', '16') IS NULL AND pg_temp.dans_boite('both', 'a_approfondir', '11') IS NULL
     AND pg_temp.dans_boite('both', 'a_approfondir', '20') IS NULL $$);
SELECT pg_temp.verif('BOITE a_feliciter : l''admission en verification d''il y a une heure, et elle seule', $$
  SELECT jsonb_array_length(pg_temp.boite('both', 'a_feliciter') -> 'candidats') = 1 AND pg_temp.dans_boite('both', 'a_feliciter', '18') ->> 'permis' = 'true' $$);

-- Ecrire le premier : la relance de c16, qui n'a pas encore de conversation.
SELECT pg_temp.garde('o16', pg_temp.ouvrir('both', '16', 'relance', '300'));
SELECT pg_temp.verif('OUVRIR relance : la conversation STANDARD de candidature est creee, le message est de Praxis, l''ouverture est notee', $$
  SELECT pg_temp.lu('o16') ->> 'ok' = 'true'
     AND (SELECT count(*) FROM public.com_fils f WHERE f.objet_id = pg_temp.c('16') AND f.type_objet = 'candidature' AND f.partie_a_nature = 'profil'
           AND f.partie_a_id = pg_temp.u('16') AND f.partie_b_nature = 'equipe' AND f.partie_b_id IS NULL) = 1
     AND (SELECT count(*) FROM public.com_fils f WHERE f.objet_id = pg_temp.c('16')) = 1
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = (pg_temp.lu('o16') ->> 'fil')::uuid AND m.auteur_id = private.praxis_profil()) = 1
     AND (SELECT count(*) FROM private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('16') AND o.raison = 'relance' AND o.evenement_id IS NULL) = 1
     AND EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'ecrire' AND j.issue = 'ok' AND j.fil_id = (pg_temp.lu('o16') ->> 'fil')::uuid AND j.texte_envoye IS NOT NULL) $$);
SELECT pg_temp.verif('OUVRIR idempotence : la meme cle ne renvoie pas le message', $$
  SELECT pg_temp.ouvrir('both', '16', 'relance', '300') ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = (pg_temp.lu('o16') ->> 'fil')::uuid) = 1
     AND (SELECT count(*) FROM private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('16')) = 1 $$);
SELECT pg_temp.verif('OUVRIR 7 jours : ni relance ni question a la meme personne avant 7 jours', $$
  SELECT pg_temp.ouvrir('both', '16', 'relance', '301') ->> 'erreur' = 'ouverture_recente' AND pg_temp.ouvrir('both', '16', 'question', '302') ->> 'erreur' = 'ouverture_recente'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = (pg_temp.lu('o16') ->> 'fil')::uuid) = 1 $$);
SELECT pg_temp.verif('ECRIRE sans raison : refuse quand la personne n''a jamais ecrit (c16) ou que la direction a repondu (c20)', $$
  SELECT pg_temp.ecrire('both', (pg_temp.lu('o16') ->> 'fil')::uuid, '310') ->> 'erreur' = 'raison_requise'
     AND pg_temp.ecrire('both', pg_temp.f('20'), '311') ->> 'erreur' = 'raison_requise'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = pg_temp.f('20')) = 1 $$);
SELECT pg_temp.verif('OUVRIR nuit : refuse entre 21 h et 8 h a l''heure du candidat', $$
  SELECT pg_temp.ouvrir('both', '17', 'relance', '320') ->> 'erreur' = 'heure_tardive' AND pg_temp.ouvrir('both', '17', 'question', '321') ->> 'erreur' = 'heure_tardive'
     AND NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.objet_id = pg_temp.c('17')) $$);
SELECT pg_temp.verif('OUVRIR 48 heures : refuse quand la direction vient d''ecrire a la personne', $$
  SELECT pg_temp.ouvrir('both', '20', 'question', '330') ->> 'erreur' = 'direction_recente' AND pg_temp.ouvrir('both', '20', 'relance', '331') ->> 'erreur' = 'direction_recente' $$);
SELECT pg_temp.verif('OUVRIR relance sans objet : la personne vient d''agir', $$
  SELECT pg_temp.ouvrir('both', '22', 'relance', '340') ->> 'erreur' = 'relance_sans_objet' $$);
SELECT pg_temp.verif('OUVRIR dossier ferme ou de l''autre cote : la meme reponse, rien de cree', $$
  SELECT pg_temp.ouvrir('both', '12', 'question', '350') ->> 'erreur' = 'candidature_inconnue' AND pg_temp.ouvrir('both', '13', 'question', '351') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.ouvrir('both', '14', 'relance', '352') ->> 'erreur' = 'candidature_inconnue' AND pg_temp.ouvrir('both', '15', 'question', '353') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.ouvrir('fem', '11', 'question', '354') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, ''CAND-99999999'', ''question'', ''x'', %L::uuid)', pg_temp.k('both'), pg_temp.idem('355'))) ->> 'erreur' = 'candidature_inconnue'
     AND NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.objet_id IN (pg_temp.c('12'), pg_temp.c('13'), pg_temp.c('14'), pg_temp.c('15'), pg_temp.c('11'))) $$);
SELECT pg_temp.verif('OUVRIR refus parametre et longueur : raison inconnue, texte vide, plus de 1500 signes', $$
  SELECT pg_temp.ouvrir('both', '23', 'pression', '360') ->> 'erreur' = 'parametre'
     AND pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, %L, ''question'', '' '', %L::uuid)', pg_temp.k('both'), pg_temp.ref('23'), pg_temp.idem('361'))) ->> 'erreur' = 'parametre'
     AND pg_temp.srv(format('SELECT public.praxis_ouvrir(%L, %L, ''question'', %L, %L::uuid)', pg_temp.k('both'), pg_temp.ref('23'), repeat('a', 1501), pg_temp.idem('362'))) ->> 'erreur' = 'longueur' $$);
SELECT pg_temp.verif_annule('OUVRIR plafond : 3 relances en tout par personne',
  $$INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT pg_temp.c('24'), 'relance', gen_random_uuid(), gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '30 days'
      FROM (SELECT cle_id, emise_par FROM private.praxis_ouvertures LIMIT 1) o, generate_series(1, 3)$$,
  $$SELECT pg_temp.ouvrir('both', '24', 'relance', '370') ->> 'erreur' = 'plafond_relances'$$);
SELECT pg_temp.verif_annule('OUVRIR plafond : 25 ouvertures par jour au total',
  $$INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT gen_random_uuid(), 'question', gen_random_uuid(), gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '2 hours'
      FROM (SELECT cle_id, emise_par FROM private.praxis_ouvertures LIMIT 1) o, generate_series(1, 24)$$,
  $$SELECT pg_temp.ouvrir('both', '24', 'relance', '371') ->> 'erreur' = 'plafond_ouvertures' AND pg_temp.ouvrir('both', '23', 'question', '372') ->> 'erreur' = 'plafond_ouvertures'$$);
SELECT pg_temp.verif_annule('OUVRIR plafond horaire des envois : partage avec ecrire',
  $$UPDATE private.praxis_reglages SET envois_par_heure = 1$$,
  $$SELECT pg_temp.ouvrir('both', '24', 'relance', '373') ->> 'erreur' = 'plafond'$$);
SELECT pg_temp.verif('OUVRIR question : a une personne etiquetee, puis elle sort de la boite a_approfondir', $$
  SELECT pg_temp.ouvrir('both', '23', 'question', '380') ->> 'ok' = 'true' AND pg_temp.dans_boite('both', 'a_approfondir', '23') IS NULL
     AND pg_temp.n($q$private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('23') AND o.raison = 'question'$q$) = 1 $$);

-- Repondre : la candidate c10 a ecrit ; Praxis repond (deux messages de suite au plus), puis plus rien sans reponse.
SELECT pg_temp.verif('ECRIRE repondre : permis quand la personne a ecrit ; 2 messages de suite au plus dans une conversation de candidature', $$
  SELECT pg_temp.ecrire('both', pg_temp.f('10'), '400') ->> 'ok' = 'true' AND pg_temp.ecrire('both', pg_temp.f('10'), '401') ->> 'ok' = 'true'
     AND pg_temp.ecrire('both', pg_temp.f('10'), '402') ->> 'erreur' = 'plafond_fil'
     AND pg_temp.ouvrir('both', '10', 'question', '403') ->> 'erreur' = 'plafond_fil'
     AND pg_temp.n($q$public.com_messages m WHERE m.fil_id = pg_temp.f('10') AND m.auteur_id = private.praxis_profil()$q$) = 2 $$);

-- Feliciter : une seule fois par decision, jamais sans decision positive.
SELECT pg_temp.verif('OUVRIR felicitations : sans decision positive, refuse', $$
  SELECT pg_temp.ouvrir('both', '24', 'felicitations', '410') ->> 'erreur' = 'felicitations_sans_objet'
     AND pg_temp.ouvrir('both', '12', 'felicitations', '411') ->> 'erreur' = 'candidature_inconnue'
     AND pg_temp.ouvrir('both', '13', 'felicitations', '412') ->> 'erreur' = 'candidature_inconnue' $$);
SELECT pg_temp.verif('OUVRIR felicitations : une fois par decision, puis la boite a_feliciter est vide', $$
  SELECT pg_temp.ouvrir('both', '18', 'felicitations', '420') ->> 'ok' = 'true' AND pg_temp.ouvrir('both', '18', 'felicitations', '421') ->> 'erreur' = 'deja_felicite'
     AND pg_temp.n($q$private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('18') AND o.raison = 'felicitations' AND o.evenement_id IS NOT NULL$q$) = 1
     AND jsonb_array_length(pg_temp.boite('both', 'a_feliciter') -> 'candidats') = 0
     AND pg_temp.n($q$public.com_messages m JOIN public.com_fils f ON f.id = m.fil_id WHERE f.objet_id = pg_temp.c('18')$q$) = 1 $$);
SELECT pg_temp.verif('OUVRIR felicitations : une decision de plus de 72 heures ne se felicite plus', $$
  SELECT NOT EXISTS (SELECT 1 FROM private.praxis_decision_positive(pg_temp.c('20')))
     AND EXISTS (SELECT 1 FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('20') AND e.details ->> 'geste' = 'admettre_verifications')
     AND pg_temp.ouvrir('both', '20', 'felicitations', '430') ->> 'erreur' = 'felicitations_sans_objet'
     AND pg_temp.dans_boite('both', 'a_feliciter', '20') IS NULL $$);
SELECT pg_temp.verif('DOSSIER apres dialogue : les ouvertures et les comptes de la conversation', $$
  SELECT d -> 'praxis' -> 'ouvertures' -> 0 ->> 'raison' = 'relance' AND (d -> 'conversation' ->> 'de_praxis')::int = 1 AND (d -> 'conversation' ->> 'du_candidat')::int = 0
    FROM (SELECT pg_temp.dossier('both', '16') AS d) x $$);
-- ===== ENTRETIEN ECRIT (directeur, 20/11/2026) : quelques questions par ecrit a la place de la video =====
SELECT pg_temp.verif('ENTRETIEN boite a_interroger : l''entretien reste a planifier et aucune serie n''a ete envoyee', $$
  SELECT pg_temp.dans_boite('both', 'a_interroger', '21') ->> 'permis' = 'true' AND pg_temp.dans_boite('both', 'a_interroger', '21') ->> 'raison' = 'entretien_ecrit'
     AND jsonb_array_length(pg_temp.boite('both', 'a_interroger') -> 'candidats') = 1 $$);
SELECT pg_temp.verif('ENTRETIEN 5 questions au plus par envoi, une au moins', $$
  SELECT pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Un ? Deux ? Trois ? Quatre ? Cinq ? Six ?', '600') ->> 'erreur' = 'trop_de_questions'
     AND pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'واحد؟ اثنان؟ ثلاثة؟ أربعة؟ خمسة؟ ستة؟', '601') ->> 'erreur' = 'trop_de_questions'
     AND pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Bonjour, sans question.', '602') ->> 'erreur' = 'trop_de_questions'
     AND NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.objet_id = pg_temp.c('21')) $$);
SELECT pg_temp.garde('e21', pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Bonjour. Pourquoi enseignez-vous le Coran ? Que faites-vous quand un enfant se decourage ? Qu''aimeriez-vous construire avec nous ?', '603'));
SELECT pg_temp.verif('ENTRETIEN envoye : une serie, dans la conversation de candidature ; le dossier la dit en cours ; elle sort de la boite', $$
  SELECT pg_temp.lu('e21') ->> 'ok' = 'true' AND pg_temp.lu('e21') ->> 'raison' = 'entretien_ecrit'
     AND (SELECT count(*) FROM private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('21') AND o.raison = 'entretien_ecrit') = 1
     AND pg_temp.dossier('both', '21') -> 'entretien_ecrit' ->> 'etat' = 'en_cours'
     AND pg_temp.dossier('both', '21') -> 'contenu_tiers' -> 'entretien_ecrit_reponses' = '[]'::jsonb
     AND pg_temp.dans_boite('both', 'a_interroger', '21') IS NULL $$);
SELECT pg_temp.verif('ENTRETIEN une seule serie ouverte, aucune relance avant 7 jours', $$
  SELECT pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Encore ?', '604') ->> 'erreur' = 'ouverture_recente'
     AND pg_temp.ouvrir_t('both', '21', 'relance_entretien', 'Avez-vous vu mes questions ?', '605') ->> 'erreur' = 'ouverture_recente'
     AND pg_temp.ouvrir('both', '21', 'question', '606') ->> 'erreur' = 'ouverture_recente' $$);
SELECT pg_temp.verif_annule('ENTRETIEN apres 8 jours sans reponse : pas de seconde serie ; UNE relance, puis plus rien',
  $$UPDATE private.praxis_ouvertures SET ouverte_le = now() - interval '8 days' WHERE candidature_id = pg_temp.c('21')$$,
  $$SELECT pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Encore ?', '610') ->> 'erreur' = 'entretien_en_cours'
       AND pg_temp.ouvrir_t('both', '21', 'relance_entretien', 'Un petit rappel, sans urgence.', '611') ->> 'ok' = 'true'
       AND pg_temp.ouvrir_t('both', '21', 'relance_entretien', 'Second rappel.', '612') ->> 'erreur' = 'plafond_fil'$$);
SELECT pg_temp.verif_annule('ENTRETIEN une relance par serie, meme longtemps apres',
  $$UPDATE private.praxis_ouvertures SET ouverte_le = now() - interval '30 days' WHERE candidature_id = pg_temp.c('21');
    INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT o.candidature_id, 'relance_entretien', o.fil_id, gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '20 days'
      FROM private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('21')$$,
  $$SELECT pg_temp.ouvrir_t('both', '21', 'relance_entretien', 'Troisieme rappel.', '613') ->> 'erreur' = 'entretien_deja_relance'
       AND pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Encore ?', '614') ->> 'erreur' = 'entretien_en_cours'$$);
SELECT pg_temp.verif_annule('ENTRETIEN deux series en tout par candidat',
  $$UPDATE private.praxis_ouvertures SET ouverte_le = now() - interval '30 days' WHERE candidature_id = pg_temp.c('21');
    INSERT INTO private.praxis_ouvertures (candidature_id, raison, fil_id, message_id, cle_id, emise_par, cle_idempotence, ouverte_le)
    SELECT o.candidature_id, 'entretien_ecrit', o.fil_id, gen_random_uuid(), o.cle_id, o.emise_par, gen_random_uuid(), now() - interval '20 days'
      FROM private.praxis_ouvertures o WHERE o.candidature_id = pg_temp.c('21');
    INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
    SELECT f.id, pg_temp.u('21'), gen_random_uuid(), 'Reponse ancienne.', clock_timestamp() - interval '10 days' FROM public.com_fils f WHERE f.objet_id = pg_temp.c('21')$$,
  $$SELECT pg_temp.ouvrir_t('both', '21', 'entretien_ecrit', 'Une troisieme serie ?', '615') ->> 'erreur' = 'plafond_entretiens'$$);
-- La candidate repond.
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
SELECT f.id, pg_temp.u('21'), pg_temp.idem('620'), 'REPONSEENTRETIEN : j''enseigne pour que les enfants aiment le Coran.', clock_timestamp() FROM public.com_fils f WHERE f.objet_id = pg_temp.c('21');
SELECT pg_temp.verif('ENTRETIEN repondu : le dossier rend les reponses sous contenu_tiers, sans nom ni contact', $$
  SELECT d -> 'entretien_ecrit' ->> 'etat' = 'repondu' AND jsonb_array_length(d -> 'contenu_tiers' -> 'entretien_ecrit_reponses') = 1
     AND d -> 'contenu_tiers' -> 'entretien_ecrit_reponses' -> 0 ->> 'texte' LIKE 'REPONSEENTRETIEN%'
     AND (d - 'contenu_tiers')::text !~ 'REPONSEENTRETIEN' AND d::text !~* 'nomsecret|@'
    FROM (SELECT pg_temp.dossier('both', '21') AS d) x $$);
SELECT pg_temp.verif_annule('ENTRETIEN repondu : plus de relance',
  $$UPDATE private.praxis_ouvertures SET ouverte_le = now() - interval '8 days' WHERE candidature_id = pg_temp.c('21');
    INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
    SELECT f.id, pg_temp.u('21'), gen_random_uuid(), 'Reponse.', clock_timestamp() - interval '1 day' FROM public.com_fils f WHERE f.objet_id = pg_temp.c('21')$$,
  $$SELECT pg_temp.ouvrir_t('both', '21', 'relance_entretien', 'Rappel.', '621') ->> 'erreur' = 'relance_entretien_sans_objet'$$);
SELECT pg_temp.verif('ENTRETIEN sans serie : la relance d''entretien est sans objet ; un dossier ferme reste ferme', $$
  SELECT pg_temp.ouvrir_t('both', '24', 'relance_entretien', 'Rappel.', '622') ->> 'erreur' = 'relance_entretien_sans_objet'
     AND pg_temp.ouvrir_t('both', '13', 'entretien_ecrit', 'Pourquoi ?', '623') ->> 'erreur' = 'candidature_inconnue' $$);
SELECT pg_temp.verif('ENTRETIEN ne decide rien : l''etape et l''etat du dossier ne bougent pas, aucune proposition, aucune dispense', $$
  SELECT (SELECT c.etape = 'verifications' AND c.etat = 'entretien_a_planifier' FROM public.candidatures c WHERE c.id = pg_temp.c('21'))
     AND NOT EXISTS (SELECT 1 FROM private.praxis_propositions) AND NOT EXISTS (SELECT 1 FROM public.candidature_dispenses_entretien)
     AND (SELECT count(*) FROM public.candidature_evenements) = 4 $$);
SELECT pg_temp.verif('ETAT : le plafond des ouvertures est lisible (25 par 24 heures, moins les questions, relances et entretiens envoyes)', $$
  SELECT (e ->> 'ouverturesRestantesJour')::int = 25 - (SELECT count(*) FROM private.praxis_ouvertures o WHERE o.raison <> 'felicitations')::int
     AND (e ->> 'ouverturesRestantesJour')::int = 22 AND e ? 'plafondRestantHeure' AND e ? 'annoncesRestantesJour' AND e ->> 'actif' = 'true'
    FROM (SELECT pg_temp.srv(format('SELECT public.praxis_etat(%L)', pg_temp.k('both'))) AS e) x $$);
SELECT pg_temp.verif('JOURNAL dialogue : chaque refus de l''ouverture laisse une ligne sous ecrire', $$
  SELECT (SELECT count(DISTINCT j.issue) FROM private.praxis_journal j WHERE j.outil = 'ecrire' AND j.issue IN ('ok', 'rejoue', 'ouverture_recente', 'raison_requise',
            'heure_tardive', 'direction_recente', 'relance_sans_objet', 'candidature_inconnue', 'parametre', 'longueur', 'plafond_fil',
            'felicitations_sans_objet', 'deja_felicite', 'eteint', 'donnees_reelles_fermees', 'trop_de_questions')) = 16
     AND EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'boite' AND j.issue = 'ok')
     AND EXISTS (SELECT 1 FROM private.praxis_journal j WHERE j.outil = 'noter_impression' AND j.issue = 'texte_interdit') $$);
SELECT pg_temp.verif('REFUS de parametre : praxis_noter_refus connait dossier et noter_impression, pas un outil invente', $$
  SELECT pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''dossier'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''noter_impression'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''ranger'')', pg_temp.k('both'))) ->> 'ok' = 'true'
     AND pg_temp.srv(format('SELECT public.praxis_noter_refus(%L, ''ouvrir_tout'')', pg_temp.k('both'))) ->> 'ok' = 'false' $$);

-- Mode essai : les outils de dossier sont fermes ; aucune ouverture hors des conversations d'essai.
UPDATE private.praxis_reglages SET essai_fils = ARRAY[pg_temp.f('20')];
SELECT pg_temp.verif('ESSAI : dossier, impression et boite refusent ; ouvrir refuse hors essai', $$
  SELECT pg_temp.dossier('both', '10') ->> 'erreur' = 'essai' AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '500') ->> 'erreur' = 'essai'
     AND pg_temp.boite('both', 'sans_nouvelles') ->> 'erreur' = 'essai' AND pg_temp.ouvrir('both', '24', 'relance', '501') ->> 'erreur' = 'hors_essai'
     AND NOT EXISTS (SELECT 1 FROM public.com_fils f WHERE f.objet_id = pg_temp.c('24')) $$);
UPDATE private.praxis_reglages SET essai_fils = '{}';
SELECT pg_temp.garde('off', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(false, false, NULL)$$));
SELECT pg_temp.verif('INTERRUPTEUR : eteint, plus rien ne passe', $$
  SELECT pg_temp.dossier('both', '10') ->> 'erreur' = 'eteint' AND pg_temp.ouvrir('both', '24', 'relance', '510') ->> 'erreur' = 'eteint'
     AND pg_temp.boite('both', 'a_approfondir') ->> 'erreur' = 'eteint' AND pg_temp.impression('both', '24', 'solide', '{}', 'T.', 'forte', '511') ->> 'erreur' = 'eteint' $$);

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 110) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN RAISE EXCEPTION 'PRAXIS-DOSSIER-COMPLET : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok); END IF;
END $$;
ROLLBACK;
