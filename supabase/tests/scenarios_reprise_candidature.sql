-- PE-A6 REPRISE-CANDIDATURE (directeur, 19/11/2026 : le retrait se defait seul pendant 7 jours) :
-- migration 20261130910000_reprise_candidature.sql.
--
-- Cas couverts : (a) avant tout retrait, etat_dossier() (cle candidature.reprise) dit le delai et rien d'autre ; (b) un candidat retire sa
-- candidature puis la reprend lui-meme : elle revient en cours, a la meme etape et au meme etat, l'evenement et
-- l'audit sont ecrits, la meme cle rejoue le premier resultat ; (c) une version perimee est refusee ; (d) apres
-- 7 jours la reprise est refusee et le dit ; (e) un retrait consigne par la direction ne se reprend pas par la
-- personne ; (f) une candidature en cours ne se « reprend » pas ; (g) en salle 2, un controle de la reouverture
-- faux (versement, cadre) refuse la reprise sans rien ecrire ; (h) une demande de famille est refusee ; (i) un
-- compte sans candidature, une session absente ; (j) droits, et etat_dossier() seule lecture ; (k) la direction rouvre toujours apres le delai.
-- Chaque controle leve 'REPRISE ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
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

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'REPRISE ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Execute [p_sql] sous la session de [p_id] ; rend le jsonb. Les resultats sont gardes par nom (pg_temp.r).
CREATE TEMP TABLE resultats (nom text PRIMARY KEY, valeur jsonb);
GRANT ALL ON resultats TO authenticated, anon;
CREATE FUNCTION pg_temp.en(p_nom text, p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  INSERT INTO resultats (nom, valeur) VALUES (p_nom, v)
    ON CONFLICT (nom) DO UPDATE SET valeur = excluded.valeur;
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.r(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT valeur FROM resultats WHERE nom = p_nom $$;

-- Attend un refus leve (SQLSTATE) sous la session de [p_id].
CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_sql text, p_etat text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v jsonb; v_etat text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql INTO v;
    EXECUTE 'RESET ROLE';
    RAISE EXCEPTION 'REPRISE ROUGE : % (aucun refus, rendu %)', p_label, v;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_etat = RETURNED_SQLSTATE;
    EXECUTE 'RESET ROLE';
    IF v_etat <> p_etat THEN
      RAISE EXCEPTION 'REPRISE ROUGE : % (etat %, attendu % : %)', p_label, v_etat, p_etat, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e9100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('e910cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.issue(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT issue FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT etape || '/' || coalesce(etat, '-') FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.reprises(p_n text) RETURNS bigint
LANGUAGE sql AS $$
  SELECT count(*) FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = 'transition' AND e.details ->> 'geste' = 'reprendre'
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.en(text, uuid, text, text), pg_temp.r(text), pg_temp.p(text), pg_temp.c(text), pg_temp.v(text),
  pg_temp.issue(text), pg_temp.etat(text), pg_temp.reprises(text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme). Candidats hommes :
-- 01, 02, 03, 04 en salle 1, a completer ; 06 en salle 2, entretien a planifier (versement et cadre non verifies) ;
-- 05 une demande de type famille deja retiree (le compte de la fixture reste un compte simple : seul le type de la
-- demande est lu par la reprise) ; 09 un compte sans candidature.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'rp-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '09']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'RP-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'RP-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '09']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), v.type_code, pg_temp.p(v.s), 'male', 'Fixture ' || v.s, v.etape, v.etat, v.issue, 'lien_public'
FROM (VALUES
  ('01', 'enseignant', 'prequalification', 'a_completer', 'en_cours'),
  ('02', 'enseignant', 'prequalification', 'a_completer', 'en_cours'),
  ('03', 'enseignant', 'prequalification', 'a_completer', 'en_cours'),
  ('04', 'enseignant', 'prequalification', 'a_completer', 'en_cours'),
  ('05', 'famille', 'recue', NULL, 'retiree'),
  ('06', 'enseignant', 'verifications', 'entretien_a_planifier', 'en_cours')) AS v(s, type_code, etape, etat, issue);
SET LOCAL session_replication_role = origin;

-- ------------------------------------------------------------
-- (a) Avant tout retrait : la lecture dit le delai, rien d'autre
-- ------------------------------------------------------------
SELECT pg_temp.en('a', pg_temp.p('01'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(
  pg_temp.r('a') = '{"delaiJours": 7}'::jsonb,
  'a1 : candidature en cours, etat_dossier() rend le delai de 7 jours et rien d''autre');

-- ------------------------------------------------------------
-- (b) Le candidat retire, puis reprend lui-meme
-- ------------------------------------------------------------
SELECT pg_temp.en('b-retrait', pg_temp.p('01'), 'teacher', pg_catalog.format(
  'SELECT public.retrait_candidat(%s, %L)', pg_temp.v('01'), 'cle-reprise-retrait-01'));
SELECT pg_temp.vrai(pg_temp.issue('01') = 'retiree', 'b1 : le retrait par la personne pose l''issue retiree');
SELECT pg_temp.en('b-lue', pg_temp.p('01'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(
  (pg_temp.r('b-lue') ->> 'possible')::boolean AND (pg_temp.r('b-lue') ->> 'delaiJours')::int = 7
  AND (pg_temp.r('b-lue') ->> 'parLeCandidat')::boolean AND NOT (pg_temp.r('b-lue') ? 'raison')
  AND (pg_temp.r('b-lue') ->> 'repriseJusquAu')::timestamptz
      = (pg_temp.r('b-lue') ->> 'retireeLe')::timestamptz + interval '7 days'
  AND (pg_temp.r('b-lue') ->> 'retireeLe')::timestamptz <= pg_catalog.clock_timestamp(),
  'b2 : retiree, la lecture dit « se reprend », jusqu''a la date du retrait plus 7 jours');
SELECT pg_temp.en('b-reprise', pg_temp.p('01'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('01'), 'cle-reprise-01'));
SELECT pg_temp.vrai(
  NOT (pg_temp.r('b-reprise') ? 'erreur') AND (pg_temp.r('b-reprise') ->> 'rejoue') = 'false'
  AND pg_temp.r('b-reprise') -> 'candidature' ->> 'issue' = 'en_cours',
  'b3 : la reprise rend le bloc candidature relu, en cours');
SELECT pg_temp.vrai(pg_temp.issue('01') = 'en_cours' AND pg_temp.etat('01') = 'prequalification/a_completer',
  'b4 : la candidature est de nouveau en cours, a la meme etape et au meme etat');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.candidature_evenements e
           WHERE e.candidature_id = pg_temp.c('01') AND e.type = 'transition'
             AND e.issue_avant = 'retiree' AND e.issue_apres = 'en_cours' AND e.auteur_id = pg_temp.p('01')
             AND e.details @> '{"geste": "reprendre", "transition": 19, "auteur": "candidat", "canal": "application"}'::jsonb),
  'b5 : l''evenement de la reprise est ecrit (transition 19, par le candidat, depuis l''application)');
SELECT pg_temp.en('b-rejoue', pg_temp.p('01'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('01') - 1, 'cle-reprise-01'));
SELECT pg_temp.vrai((pg_temp.r('b-rejoue') ->> 'rejoue') = 'true' AND pg_temp.reprises('01') = 1,
  'b6 : la meme cle rejoue le premier resultat, sans seconde ecriture');
SELECT pg_temp.en('b-apres', pg_temp.p('01'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(pg_temp.r('b-apres') = '{"delaiJours": 7}'::jsonb,
  'b7 : apres la reprise, la lecture ne dit plus que le delai');
-- Un second retrait ouvre un nouveau delai, et se reprend aussi.
SELECT pg_temp.en('b-retrait2', pg_temp.p('01'), 'teacher', pg_catalog.format(
  'SELECT public.retrait_candidat(%s, %L)', pg_temp.v('01'), 'cle-reprise-retrait-01-bis'));
SELECT pg_temp.en('b-reprise2', pg_temp.p('01'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('01'), 'cle-reprise-01-bis'));
SELECT pg_temp.vrai(pg_temp.issue('01') = 'en_cours' AND pg_temp.reprises('01') = 2,
  'b8 : un second retrait se reprend aussi (nouveau delai)');

-- ------------------------------------------------------------
-- (c) Version perimee
-- ------------------------------------------------------------
SELECT pg_temp.en('c-retrait', pg_temp.p('02'), 'teacher', pg_catalog.format(
  'SELECT public.retrait_candidat(%s, %L)', pg_temp.v('02'), 'cle-reprise-retrait-02'));
SELECT pg_temp.en('c-conflit', pg_temp.p('02'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('02') - 1, 'cle-reprise-02-conflit'));
SELECT pg_temp.vrai(pg_temp.r('c-conflit') ->> 'erreur' = 'conflit_candidature' AND pg_temp.issue('02') = 'retiree',
  'c1 : une version perimee est refusee (conflit), rien n''est ecrit');

-- ------------------------------------------------------------
-- (d) Apres 7 jours
-- ------------------------------------------------------------
-- Le retrait de 02 est vieilli de 8 jours (ecriture de fixture, hors declencheurs).
SET LOCAL session_replication_role = replica;
UPDATE public.candidature_evenements e
   SET cree_le = e.cree_le - interval '8 days'
 WHERE e.candidature_id = pg_temp.c('02') AND e.details ->> 'geste' = 'retirer';
SET LOCAL session_replication_role = origin;
SELECT pg_temp.en('d-lue', pg_temp.p('02'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(
  NOT (pg_temp.r('d-lue') ->> 'possible')::boolean
  AND pg_temp.r('d-lue') ->> 'raison' = 'delai_depasse'
  AND (pg_temp.r('d-lue') ->> 'repriseJusquAu')::timestamptz < pg_catalog.clock_timestamp(),
  'd1 : apres 7 jours, la lecture dit « delai depasse » et la date passee');
SELECT pg_temp.en('d-reprise', pg_temp.p('02'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('02'), 'cle-reprise-02'));
SELECT pg_temp.vrai(
  pg_temp.r('d-reprise') ->> 'erreur' = 'reprise_fermee' AND pg_temp.r('d-reprise') ->> 'raison' = 'delai_depasse'
  AND pg_temp.issue('02') = 'retiree' AND pg_temp.reprises('02') = 0,
  'd2 : apres 7 jours, la reprise est refusee, rien n''est ecrit');

-- ------------------------------------------------------------
-- (k) Apres le delai, la direction rouvre toujours
-- ------------------------------------------------------------
SELECT pg_temp.en('k-rouvrir', pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.rouvrir_candidat(%L, %L, %s, %L)', pg_temp.c('02'), 'Demande du candidat', pg_temp.v('02'),
  'cle-reprise-rouvrir-02'));
SELECT pg_temp.vrai(NOT (pg_temp.r('k-rouvrir') ? 'erreur') AND pg_temp.issue('02') = 'en_cours',
  'k1 : apres le delai, la direction rouvre comme avant');

-- ------------------------------------------------------------
-- (e) Retrait consigne par la direction
-- ------------------------------------------------------------
SELECT pg_temp.en('e-retrait', pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.consigner_retrait_candidat(%L, %L, %L, %L, %s, %L)', pg_temp.c('03'), 'courriel',
  (now() AT TIME ZONE 'UTC')::date, 'Demande par courriel', pg_temp.v('03'), 'cle-reprise-consigne-03'));
SELECT pg_temp.vrai(NOT (pg_temp.r('e-retrait') ? 'erreur') AND pg_temp.issue('03') = 'retiree',
  'e0 : la direction consigne le retrait');
SELECT pg_temp.en('e-lue', pg_temp.p('03'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(
  NOT (pg_temp.r('e-lue') ->> 'possible')::boolean AND pg_temp.r('e-lue') ->> 'raison' = 'retrait_par_la_direction'
  AND NOT (pg_temp.r('e-lue') ? 'repriseJusquAu'),
  'e1 : un retrait consigne par la direction : la lecture ne promet aucune date');
SELECT pg_temp.en('e-reprise', pg_temp.p('03'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('03'), 'cle-reprise-03'));
SELECT pg_temp.vrai(
  pg_temp.r('e-reprise') ->> 'erreur' = 'reprise_fermee'
  AND pg_temp.r('e-reprise') ->> 'raison' = 'retrait_par_la_direction' AND pg_temp.issue('03') = 'retiree',
  'e2 : il ne se reprend pas par la personne');

-- ------------------------------------------------------------
-- (f) Une candidature en cours ne se reprend pas
-- ------------------------------------------------------------
SELECT pg_temp.en('f', pg_temp.p('04'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('04'), 'cle-reprise-04'));
SELECT pg_temp.vrai(pg_temp.r('f') ->> 'erreur' = 'transition_interdite' AND pg_temp.reprises('04') = 0,
  'f1 : candidature en cours : transition interdite');

-- ------------------------------------------------------------
-- (g) Salle 2 : un controle de la reouverture faux refuse la reprise
-- ------------------------------------------------------------
SELECT pg_temp.en('g-retrait', pg_temp.p('06'), 'teacher', pg_catalog.format(
  'SELECT public.retrait_candidat(%s, %L)', pg_temp.v('06'), 'cle-reprise-retrait-06'));
SELECT pg_temp.en('g-lue', pg_temp.p('06'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(
  NOT (pg_temp.r('g-lue') ->> 'possible')::boolean AND pg_temp.r('g-lue') ->> 'raison' = 'controles_non_satisfaits'
  AND NOT (pg_temp.r('g-lue') ? 'controles'),
  'g1 : salle 2 sans versement compatible : la lecture dit « controles », sans leur detail');
SELECT pg_temp.en('g-reprise', pg_temp.p('06'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('06'), 'cle-reprise-06'));
SELECT pg_temp.vrai(
  pg_temp.r('g-reprise') ->> 'erreur' = 'controles_non_satisfaits'
  AND pg_catalog.jsonb_array_length(pg_temp.r('g-reprise') -> 'controles') > 0
  AND pg_temp.issue('06') = 'retiree' AND pg_temp.reprises('06') = 0,
  'g2 : la reprise est refusee par les controles de la reouverture, rien n''est ecrit');

-- ------------------------------------------------------------
-- (h) Une demande de famille
-- ------------------------------------------------------------
SELECT pg_temp.en('h-lue', pg_temp.p('05'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(
  NOT (pg_temp.r('h-lue') ->> 'possible')::boolean AND pg_temp.r('h-lue') ->> 'raison' = 'type',
  'h1 : une demande de famille retiree : la lecture dit qu''elle ne se reprend pas ici');
SELECT pg_temp.en('h-reprise', pg_temp.p('05'), 'teacher', pg_catalog.format(
  'SELECT public.reprise_candidat(%s, %L)', pg_temp.v('05'), 'cle-reprise-05'));
SELECT pg_temp.vrai(
  pg_temp.r('h-reprise') ->> 'erreur' = 'reprise_fermee' AND pg_temp.r('h-reprise') ->> 'raison' = 'type'
  AND pg_temp.issue('05') = 'retiree',
  'h2 : la reprise d''une demande de famille est refusee');

-- ------------------------------------------------------------
-- (i) Sans candidature, sans session, anon
-- ------------------------------------------------------------
SELECT pg_temp.en('i-lue', pg_temp.p('09'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature' -> 'reprise'$q$);
SELECT pg_temp.vrai(pg_temp.r('i-lue') IS NULL,
  'i1 : un compte sans candidature : etat_dossier() ne rend aucune cle de reprise');
SELECT pg_temp.refus(pg_temp.p('09'), 'teacher',
  $$SELECT public.reprise_candidat(1, 'cle-reprise-09')$$, '42501',
  'i2 : un compte sans candidature ne reprend rien (42501)');
SELECT pg_temp.refus(NULL, NULL, $$SELECT public.reprise_candidat(1, 'cle-reprise-00')$$, '42501',
  'i3 : sans session, la reprise est refusee (42501)');
-- La candidature d'un autre : la fonction ne prend aucun identifiant, elle ne lit que celle de la session.
SELECT pg_temp.vrai(pg_temp.issue('03') = 'retiree' AND pg_temp.reprises('03') = 0,
  'i4 : aucune reprise n''a touche la candidature d''une autre personne');

-- ------------------------------------------------------------
-- (j) Droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.reprise_candidat(integer,text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.reprise_candidat(integer,text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'public.reprise_candidat(integer,text)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('authenticated', 'public.reprise_candidat(integer,text)', 'EXECUTE'),
  'j1 : la porte est fermee a anon, a agent_ro et a service_role, ouverte a un compte connecte');
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('authenticated', 'private.candidature_reprise_delai()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.candidature_dernier_retrait(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.candidature_reprise(public.candidatures)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.candidature_etat_candidat()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'private.candidature_reprise(public.candidatures)', 'EXECUTE'),
  'j2 : les aides privees ne sont executables par aucun client');
SELECT pg_temp.vrai(
  (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.reprise_candidat(integer,text)'::regprocedure),
  'j3 : SECURITY DEFINER et search_path vide');
-- Le contrat des ports (section 3) : etat_dossier() reste la seule lecture de l'etat du candidat.
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
               WHERE n.nspname = 'public' AND p.proname LIKE '%reprise%candidature%'),
  'j5 : aucune fonction publique de lecture de la reprise : elle vit dans etat_dossier()');
-- Le reste du bloc candidature n'a pas bouge : memes cles qu'avant, plus `reprise`.
SELECT pg_temp.en('j6', pg_temp.p('04'), 'teacher', $q$SELECT public.etat_dossier() -> 'candidature'$q$);
SELECT pg_temp.vrai(
  pg_temp.r('j6') ?& ARRAY['version', 'questionnaire', 'cadreReligieux', 'conditionsRemuneration', 'paiement',
                           'majorite', 'aCompleter', 'complementDemande', 'peutEnvoyer', 'envoiBloque', 'reprise']
  AND pg_temp.r('j6') ->> 'issue' = 'en_cours',
  'j6 : le bloc candidature garde ses cles, avec `reprise` en plus');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
               WHERE r.geste = 'reprendre' AND 'direction' = ANY (r.auteurs)),
  'j4 : « reprendre » n''est pas un geste de la direction (la liste de ses gestes ne change pas)');

DO $$
BEGIN
  RAISE NOTICE 'REPRISE-CANDIDATURE : % controles verts', pg_catalog.current_setting('test.n', true);
END $$;

ROLLBACK;
