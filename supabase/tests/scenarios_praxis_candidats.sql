-- PRAXIS-CANDIDATS (migration 20261129910000, directeur 17/11/2026) : Praxis lit et ecrit les conversations de CANDIDATURE d'un candidat
-- enseignant, jusqu'ici fermees (type_ferme). Chaque verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue
-- s'il reste un ROUGE. Avant la migration, les lignes « ouvert » sont ROUGES ; les lignes « ferme » (refus conserves) sont vertes avant et apres.
-- Ouvert : candidature d'enseignant vivante (en_cours, hors pause, avant confirmee), partie A = le candidat, cote de la cle, adulte.
-- Ferme : majorite non attestee (NULL ou faux : com_est_mineur ne voit pas un candidat mineur), issue refusee, pause, confirmee, fil sans candidature, partie A etrangere, mineur, autre cote, mode essai, donnees reelles fermees.
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


INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'pc-' || n || '@test.invalid' FROM generate_series(1, 30) n;
INSERT INTO public.households (id, timezone) SELECT pg_temp.h(n::text), 'Europe/Paris' FROM generate_series(1, 3) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'PC-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'PC-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('3'), 'PC-TUT-0001', 'guardian', pg_temp.h('1'), 'Tutrice', 'Un', 'active', 'female'),
 -- Les candidats (enseignants en attente) : u10 a u16.
 (pg_temp.u('10'), 'PC-CAN-0010', 'teacher', NULL, 'Candidate', 'Vivante', 'pending_kyc', 'female'),
 (pg_temp.u('11'), 'PC-CAN-0011', 'teacher', NULL, 'Candidat', 'Homme', 'pending_kyc', 'male'),
 (pg_temp.u('12'), 'PC-CAN-0012', 'teacher', NULL, 'Candidate', 'Refusee', 'pending_kyc', 'female'),
 (pg_temp.u('13'), 'PC-CAN-0013', 'teacher', NULL, 'Candidate', 'Pause', 'pending_kyc', 'female'),
 (pg_temp.u('14'), 'PC-CAN-0014', 'teacher', NULL, 'Candidate', 'Confirmee', 'pending_kyc', 'female'),
 (pg_temp.u('15'), 'PC-CAN-0015', 'teacher', NULL, 'Candidate', 'Quinze', 'pending_kyc', 'female');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(10, 15) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('17'), 'PC-CAN-0017', 'teacher', NULL, 'Candidate', 'SansAge', 'pending_kyc', 'female'),
 (pg_temp.u('18'), 'PC-CAN-0018', 'teacher', NULL, 'Candidate', 'Moins18', 'pending_kyc', 'female');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM generate_series(17, 18) n;
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u('1'));
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source) VALUES
 (pg_temp.c('10'), 'enseignant', pg_temp.u('10'), 'female', 'Fixture PC vivante', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public'),
 (pg_temp.c('11'), 'enseignant', pg_temp.u('11'), 'male', 'Fixture PC homme', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public'),
 (pg_temp.c('12'), 'enseignant', pg_temp.u('12'), 'female', 'Fixture PC refusee', 'verifications', 'entretien_a_planifier', 'refusee', false, 'lien_public'),
 (pg_temp.c('13'), 'enseignant', pg_temp.u('13'), 'female', 'Fixture PC pause', 'verifications', 'entretien_a_planifier', 'en_cours', true, 'lien_public'),
 (pg_temp.c('14'), 'enseignant', pg_temp.u('14'), 'female', 'Fixture PC confirmee', 'confirmee', NULL, 'en_cours', false, 'lien_public'),
 (pg_temp.c('15'), 'enseignant', pg_temp.u('15'), 'female', 'Fixture PC quinze', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source) VALUES
 (pg_temp.c('17'), 'enseignant', pg_temp.u('17'), 'female', 'Fixture PC sans age', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public'),
 (pg_temp.c('18'), 'enseignant', pg_temp.u('18'), 'female', 'Fixture PC moins 18', 'verifications', 'entretien_a_planifier', 'en_cours', false, 'lien_public');
-- La majorite est attestee (vrai) pour toutes, sauf c17 (aucune declaration : NULL) et c18 (« moins de 18 ans » : faux, ici sans pause).
UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = pg_catalog.clock_timestamp()
 WHERE id NOT IN (pg_temp.c('17'), pg_temp.c('18'));
UPDATE public.candidatures SET majorite_declaree = false, majorite_attestee_le = pg_catalog.clock_timestamp() WHERE id = pg_temp.c('18');
-- Un mineur (u16, eleve) ecrit dans le fil de la candidature u15 : ce fil se ferme (mineur), quoi que dise la candidature.
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.u('16'), 'PC-ELV-0016', 'student', pg_temp.h('2'), 'Eleve', 'Mineur', 'active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type) VALUES (pg_temp.u('16'), 'minor');
INSERT INTO public.com_fils (id, type_objet, objet_id, partie_a_nature, partie_a_id, partie_b_nature, partie_b_id) VALUES
 (pg_temp.f('10'), 'candidature', pg_temp.c('10'), 'profil', pg_temp.u('10'), 'equipe', NULL),
 (pg_temp.f('11'), 'candidature', pg_temp.c('11'), 'profil', pg_temp.u('11'), 'equipe', NULL),
 (pg_temp.f('12'), 'candidature', pg_temp.c('12'), 'profil', pg_temp.u('12'), 'equipe', NULL),
 (pg_temp.f('13'), 'candidature', pg_temp.c('13'), 'profil', pg_temp.u('13'), 'equipe', NULL),
 (pg_temp.f('14'), 'candidature', pg_temp.c('14'), 'profil', pg_temp.u('14'), 'equipe', NULL),
 (pg_temp.f('15'), 'candidature', pg_temp.c('15'), 'profil', pg_temp.u('15'), 'equipe', NULL),
 -- Aucune candidature derriere ce fil ; et un fil dont la partie A n'est pas le candidat de la candidature.
 (pg_temp.f('16'), 'candidature', pg_temp.u('98'), 'profil', pg_temp.u('10'), 'equipe', NULL),
 (pg_temp.f('17'), 'candidature', pg_temp.c('10'), 'profil', pg_temp.u('3'), 'equipe', NULL),
 (pg_temp.f('18'), 'candidature', pg_temp.c('17'), 'profil', pg_temp.u('17'), 'equipe', NULL),
 (pg_temp.f('19'), 'candidature', pg_temp.c('18'), 'profil', pg_temp.u('18'), 'equipe', NULL),
 (pg_temp.f('1'), 'dossier', pg_temp.u('3'), 'foyer', pg_temp.h('1'), 'equipe', NULL);
CREATE FUNCTION pg_temp.msg(p_fil text, p_auteur text, p_texte text, p_n text) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
  VALUES (pg_temp.f(p_fil), pg_temp.u(p_auteur), pg_temp.idem(p_n), p_texte,
          pg_catalog.clock_timestamp() - interval '2 hours' + (p_n::int || ' seconds')::interval) $$;
SELECT pg_temp.msg(n::text, n::text, 'Bonjour, ma candidature.', n::text) FROM generate_series(10, 15) n;
SELECT pg_temp.msg('16', '10', 'Bonjour, fil sans candidature.', '16');
SELECT pg_temp.msg('18', '17', 'Bonjour, sans declaration d''age.', '20');
SELECT pg_temp.msg('19', '18', 'Bonjour, moins de 18 ans.', '21');
SELECT pg_temp.msg('15', '16', 'Bonjour, c''est un enfant qui ecrit.', '19');
SELECT pg_temp.msg('17', '3', 'Bonjour, partie A etrangere.', '17');
SELECT pg_temp.msg('1', '3', 'Bonjour du dossier.', '18');
CREATE FUNCTION pg_temp.k(p_nom text) RETURNS text LANGUAGE sql AS $$ SELECT pg_temp.lu(p_nom) ->> 'secret' $$;
GRANT EXECUTE ON FUNCTION pg_temp.k(text), pg_temp.note(text, boolean, text), pg_temp.verif(text, text) TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.fil(p_cle text, p_fil text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_fil(%L, %L::uuid, 10)', pg_temp.k(p_cle), pg_temp.f(p_fil))) $$;
CREATE FUNCTION pg_temp.ecrire(p_cle text, p_fil text, p_n text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_ecrire(%L, %L::uuid, ''Bonjour, bien recu.'', %L::uuid)', pg_temp.k(p_cle), pg_temp.f(p_fil), pg_temp.idem(p_n))) $$;
GRANT EXECUTE ON FUNCTION pg_temp.fil(text, text), pg_temp.ecrire(text, text, text) TO authenticated, anon, service_role;

-- Cle de la super-administration (les deux cotes), cle d'une direction femme (cote femme seul).
SELECT pg_temp.garde('both', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat deux cotes', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000021'::uuid)$$));
SELECT pg_temp.garde('fem', pg_temp.en(pg_temp.u('2'), 'admin', $$SELECT public.direction_praxis_emettre_cle(
  'Chat femme', 'chat', pg_catalog.now() + interval '30 days', '5c1a2222-0000-4000-8000-000000000022'::uuid)$$));
SELECT pg_temp.garde('on', pg_temp.en(pg_temp.u('1'), 'admin', $$SELECT public.direction_praxis_regler(true, false, NULL)$$));

-- ===== Donnees reelles fermees (defaut) : meme une candidature vivante reste fermee =====
SELECT pg_temp.verif('FERME donnees reelles fermees : la candidature vivante est refusee', $$
  SELECT pg_temp.fil('both', '10') ->> 'erreur' = 'donnees_reelles_fermees' $$);
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ===== OUVERT : la candidature vivante =====
SELECT pg_temp.verif('OUVERT lecture : le fil de la candidate vivante se lit', $$
  SELECT pg_temp.fil('both', '10') ->> 'erreur' IS NULL AND jsonb_array_length(pg_temp.fil('both', '10') -> 'messages') = 1 $$);
SELECT pg_temp.verif('OUVERT boite : le fil de la candidate vivante y figure', $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_boite(%L, ''tout'', 50)', pg_temp.k('both')))::text LIKE '%' || pg_temp.f('10')::text || '%' $$);
SELECT pg_temp.garde('e101', pg_temp.ecrire('both', '10', '101'));
SELECT pg_temp.verif('OUVERT ecriture : Praxis repond au candidat (message ecrit par Praxis, dans ce fil)', $$
  SELECT pg_temp.lu('e101') ->> 'ok' = 'true'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = pg_temp.f('10') AND m.auteur_id = private.praxis_profil()) = 1 $$);
SELECT pg_temp.verif('OUVERT rejeu : le meme message n''est pas ecrit deux fois', $$
  SELECT pg_temp.ecrire('both', '10', '101') ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = pg_temp.f('10') AND m.auteur_id = private.praxis_profil()) = 1 $$);
-- Reprise par l'equipe : un message d'un administrateur apres celui de Praxis ferme l'ecriture, la lecture reste.
INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte, envoye_le)
VALUES (pg_temp.f('10'), pg_temp.u('2'), pg_temp.idem('102'), 'Je prends la suite.', pg_catalog.clock_timestamp() + interval '1 second');
SELECT pg_temp.verif('OUVERT reprise : apres un message de l''equipe, Praxis n''ecrit plus (repris_par_equipe), rien d''ecrit', $$
  SELECT pg_temp.ecrire('both', '10', '103') ->> 'erreur' = 'repris_par_equipe'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.fil_id = pg_temp.f('10') AND m.auteur_id = private.praxis_profil()) = 1 $$);
SELECT pg_temp.verif('OUVERT reprise : la lecture reste possible apres la reprise', $$
  SELECT pg_temp.fil('both', '10') ->> 'erreur' IS NULL $$);

-- ===== OUVERT, cote : la candidate (femme) pour une cle femme ; le candidat (homme) seulement pour la super-administration =====
SELECT pg_temp.verif('OUVERT cote : la cle femme lit la candidate', $$ SELECT pg_temp.fil('fem', '10') ->> 'erreur' IS NULL $$);
SELECT pg_temp.verif('OUVERT cote : la cle des deux cotes lit le candidat homme', $$ SELECT pg_temp.fil('both', '11') ->> 'erreur' IS NULL $$);
SELECT pg_temp.verif('FERME cote : la cle femme ne lit pas le candidat homme (cote)', $$ SELECT pg_temp.fil('fem', '11') ->> 'erreur' = 'cote' $$);
SELECT pg_temp.verif('FERME cote : la cle femme n''ecrit pas au candidat homme, rien d''ecrit', $$
  SELECT pg_temp.ecrire('fem', '11', '111') ->> 'erreur' = 'cote'
     AND NOT EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = pg_temp.f('11') AND m.auteur_id = private.praxis_profil()) $$);
SELECT pg_temp.verif('FERME cote : la boite de la cle femme ne montre pas le fil du candidat homme', $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_boite(%L, ''tout'', 50)', pg_temp.k('fem')))::text NOT LIKE '%' || pg_temp.f('11')::text || '%' $$);

-- ===== FERME : tout ce qui n'est pas une candidature vivante, en lecture ET en ecriture =====
SELECT pg_temp.verif('FERME refusee : lecture ' || x.f, format($v$SELECT pg_temp.fil('both', %L) ->> 'erreur' = 'type_ferme'$v$, x.f))
  FROM (VALUES ('12'), ('13'), ('14'), ('16'), ('17'), ('18'), ('19')) x(f);
SELECT pg_temp.verif('FERME ecriture ' || x.f || ' : type_ferme, rien d''ecrit', format(
  $v$SELECT pg_temp.ecrire('both', %L, %L) ->> 'erreur' = 'type_ferme'
        AND NOT EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = pg_temp.f(%L) AND m.auteur_id = private.praxis_profil())$v$,
  x.f, '2' || x.f, x.f))
  FROM (VALUES ('12'), ('13'), ('14'), ('16'), ('17'), ('18'), ('19')) x(f);
SELECT pg_temp.verif('FERME mineur : un mineur a ecrit dans le fil, refuse en lecture et en ecriture', $$
  SELECT pg_temp.fil('both', '15') ->> 'erreur' = 'mineur' AND pg_temp.ecrire('both', '15', '215') ->> 'erreur' = 'mineur' $$);
SELECT pg_temp.verif('FERME boite : aucun fil refuse (12 a 19) n''apparait dans la boite', $$
  SELECT NOT (pg_temp.srv(pg_catalog.format('SELECT public.praxis_boite(%L, ''tout'', 50)', pg_temp.k('both')))::text ~ ('(' ||
    pg_temp.f('12') || '|' || pg_temp.f('13') || '|' || pg_temp.f('14') || '|' || pg_temp.f('15') || '|' || pg_temp.f('16') || '|' || pg_temp.f('17') || '|' || pg_temp.f('18') || '|' || pg_temp.f('19') || ')')) $$);
-- Une candidature qui devient confirmee, en pause ou refusee APRES ouverture se referme.
UPDATE public.candidatures SET en_pause = true WHERE id = pg_temp.c('11');
SELECT pg_temp.verif('FERME apres coup : la candidature mise en pause se referme', $$ SELECT pg_temp.fil('both', '11') ->> 'erreur' = 'type_ferme' $$);
UPDATE public.candidatures SET en_pause = false WHERE id = pg_temp.c('11');
SELECT pg_temp.verif('OUVERT apres coup : la pause levee rouvre', $$ SELECT pg_temp.fil('both', '11') ->> 'erreur' IS NULL $$);

-- ===== Rien d'autre que le fil : ni piece, ni paiement, ni note d'entretien =====
SELECT pg_temp.verif('SOBRE : la lecture d''un fil de candidature ne rend que les cles habituelles', $$
  SELECT (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.fil('both', '11')) k)
       = (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.fil('both', '1')) k) $$);

-- ===== Mode essai : un fil de candidature hors liste reste refuse =====
UPDATE private.praxis_reglages SET essai_fils = ARRAY[pg_temp.f('1')];
SELECT pg_temp.verif('FERME essai : la candidature vivante est hors_essai tant que l''essai nomme un autre fil', $$
  SELECT pg_temp.fil('both', '11') ->> 'erreur' = 'hors_essai' AND pg_temp.ecrire('both', '11', '311') ->> 'erreur' = 'hors_essai' $$);
UPDATE private.praxis_reglages SET essai_fils = ARRAY[pg_temp.f('11')];
SELECT pg_temp.verif('OUVERT essai : nommee dans l''essai, la candidature vivante se lit', $$ SELECT pg_temp.fil('both', '11') ->> 'erreur' IS NULL $$);
SELECT pg_temp.verif('FERME essai : nommee dans l''essai, une candidature refusee reste fermee', $$
  SELECT (SELECT private.praxis_fil_refus(pg_temp.f('12'), ARRAY['female','male']::public.gender[])) = 'hors_essai' $$);
UPDATE private.praxis_reglages SET essai_fils = ARRAY[pg_temp.f('12')];
SELECT pg_temp.verif('FERME essai : nommee dans l''essai, une candidature refusee reste type_ferme', $$
  SELECT pg_temp.fil('both', '12') ->> 'erreur' = 'type_ferme' $$);

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 90) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN RAISE EXCEPTION 'PRAXIS-CANDIDATS : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok); END IF;
END $$;
ROLLBACK;
