-- BE-1h REFAIRE-ENTRETIEN (lot 8, T9) : migration 20261129700000_refaire_entretien.sql.
--
-- Cas couverts : (a) la direction ramene une candidature de decision_en_attente a entretien_a_planifier :
-- version, evenement (type entretien, transition 46), ligne de retour, journal sensible ; (b) rien n'est
-- efface (l'entretien tenu et la dispense restent) mais l'ancien resultat ne compte plus (entretien_conclusion,
-- controles de la salle 3), et une nouvelle dispense apres le retour compte de nouveau ; (c) motif obligatoire,
-- conflit de version, rejeu par la meme cle, second geste refuse ; (d) portee (hors etat, autre cote, role,
-- sans session) ; (e) la capacite ; (f) droits et empreintes F86.
-- Chaque controle leve 'REFAIRE ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
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
    RAISE EXCEPTION 'REFAIRE ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

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

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'REFAIRE ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'REFAIRE ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de200000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de20cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(etat, '-') FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.ref(p_n text, p_motif text, p_version integer, p_cle text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.refaire_entretien(%L, %L, %s, %L)', pg_temp.c(p_n), p_motif, p_version, p_cle));
$$;
CREATE FUNCTION pg_temp.disp(p_n text, p_cat text, p_motif text, p_version integer, p_cle text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.dispenser_entretien(%L, %L, %L, %s, %L)', pg_temp.c(p_n), p_cat, p_motif, p_version, p_cle));
$$;
CREATE FUNCTION pg_temp.controles(p_n text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT private.candidature_entretien_controles(pg_temp.c(p_n)); $$;
CREATE FUNCTION pg_temp.tenu(p_n text) RETURNS boolean
LANGUAGE sql AS $$ SELECT (private.entretien_conclusion(pg_temp.c(p_n)) ->> 'tenu')::boolean $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.v(text), pg_temp.etat(text), pg_temp.ref(text, text, integer, text),
  pg_temp.disp(text, text, text, integer, text), pg_temp.controles(text), pg_temp.tenu(text),
  pg_temp.refus_en(uuid, text, text, text, text) TO authenticated, anon;

-- Fixtures (donnees inventees). a1 direction (homme). Candidats hommes en salle de verification :
-- 01 decision_en_attente par une dispense, 02 decision_en_attente par un entretien tenu, 03 entretien a planifier,
-- 04 une candidate (femme) en decision_en_attente, 05 en pause, 06 refusee, 07 decision_en_attente (lot de controles).
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 're-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'RE-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'RE-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, en_pause)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), v.g::gender, 'Fixture ' || v.s, 'verifications', v.etat, v.issue,
       'lien_public', v.pause
FROM (VALUES
  ('01', 'male', 'decision_en_attente', 'en_cours', false),
  ('02', 'male', 'decision_en_attente', 'en_cours', false),
  ('03', 'male', 'entretien_a_planifier', 'en_cours', false),
  ('04', 'female', 'decision_en_attente', 'en_cours', false),
  ('05', 'male', 'decision_en_attente', 'en_cours', true),
  ('06', 'male', 'decision_en_attente', 'refusee', false),
  ('07', 'male', 'decision_en_attente', 'en_cours', false)) AS v(s, g, etat, issue, pause);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('de200000-0000-4000-8000-000000000301', pg_temp.p('a1'), now() - interval '2 days', now() - interval '2 days' + interval '30 minutes',
        'ended', 'entretien', now() - interval '2 days' - interval '10 minutes');
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par, issue, consigne_par, consigne_le)
VALUES ('de200000-0000-4000-8000-000000000301', pg_temp.c('02'), pg_temp.p('02'), pg_temp.p('a1'), 'tenu', pg_temp.p('a1'),
        now() - interval '1 day');
INSERT INTO public.candidature_dispenses_entretien (candidature_id, categorie, motif, auteur_id, etat_avant)
VALUES (pg_temp.c('01'), 'fondateur', 'Fondateur : pas d entretien', pg_temp.p('a1'), 'entretien_a_planifier');
SET LOCAL session_replication_role = origin;

-- (a) Refaire apres un entretien tenu
SELECT pg_temp.vrai(pg_temp.tenu('02') AND pg_temp.etat('02') = 'decision_en_attente',
  'a0 : avant le retour, l''entretien tenu compte et le dossier attend la decision');
SELECT set_config('test.v02', pg_temp.v('02')::text, true);
SELECT set_config('test.r02', pg_temp.ref('02', 'مراجعة : الحاجة إلى مقابلة ثانية', pg_temp.v('02'), 'cle-refaire-02')::text, true);
SELECT pg_temp.vrai(
  current_setting('test.r02')::jsonb ? 'candidature' AND NOT current_setting('test.r02')::jsonb ? 'erreur'
  AND pg_temp.etat('02') = 'entretien_a_planifier' AND pg_temp.v('02') = current_setting('test.v02')::int + 1,
  'a1 : le retour amene la candidature en entretien_a_planifier, une version de plus');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_entretiens_refaits r
    WHERE r.candidature_id = pg_temp.c('02') AND r.auteur_id = pg_temp.p('a1') AND r.etat_avant = 'decision_en_attente'
      AND r.motif LIKE 'مراجعة%') = 1
  AND (SELECT count(*) FROM public.candidature_evenements e
        WHERE e.candidature_id = pg_temp.c('02') AND e.type = 'entretien' AND e.etat_avant = 'decision_en_attente'
          AND e.etat_apres = 'entretien_a_planifier' AND e.auteur_id = pg_temp.p('a1')
          AND e.details @> '{"geste": "refaire_entretien", "transition": 46}'::jsonb
          AND e.motif_interne LIKE 'مراجعة%') = 1,
  'a2 : une ligne de retour (qui, motif, etat d''avant) et un evenement de type entretien sur le dossier');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.audit_logs a WHERE a.action = 'candidature_geste' AND a.row_id = pg_temp.c('02')::text
     AND a.payload ->> 'geste' = 'refaire_entretien' AND a.payload ->> 'etatApres' = 'entretien_a_planifier') = 1,
  'a3 : le journal sensible garde le retour');
SELECT pg_temp.vrai(
  (SELECT issue FROM public.entretiens WHERE session_id = 'de200000-0000-4000-8000-000000000301') = 'tenu'
  AND (SELECT count(*) FROM public.sessions WHERE id = 'de200000-0000-4000-8000-000000000301') = 1
  AND NOT pg_temp.tenu('02')
  AND (pg_temp.controles('02') -> 0 ->> 'valeur') = 'false' AND (pg_temp.controles('02') -> 1 ->> 'valeur') = 'false',
  'a4 : l''entretien tenu reste en base mais ne compte plus (entretien_conclusion, controles de la salle 3 faux)');
SELECT pg_temp.vrai(
  (pg_temp.ref('02', 'مراجعة : الحاجة إلى مقابلة ثانية', 1, 'cle-refaire-02') - 'rejoue') = (current_setting('test.r02')::jsonb - 'rejoue')
  AND (pg_temp.ref('02', 'مراجعة : الحاجة إلى مقابلة ثانية', 1, 'cle-refaire-02') ->> 'rejoue') = 'true'
  AND (SELECT count(*) FROM public.candidature_entretiens_refaits WHERE candidature_id = pg_temp.c('02')) = 1,
  'a5 : rejouer la meme cle rend le meme resultat (marque rejoue) sans nouvelle ligne');
SELECT pg_temp.vrai(
  pg_temp.ref('02', 'Encore', pg_temp.v('02'), 'cle-refaire-02b') ->> 'erreur' = 'transition_interdite',
  'a6 : une candidature deja revenue a entretien_a_planifier ne se refait pas deux fois');

-- (b) Refaire apres une dispense
SELECT pg_temp.vrai((pg_temp.controles('01') -> 0 ->> 'valeur') = 'true' AND (pg_temp.controles('01') -> 1 ->> 'valeur') = 'true',
  'b0 : avant le retour, la dispense vaut un entretien tenu et favorable');
SELECT pg_temp.vrai(NOT pg_temp.ref('01', 'Dispense a revoir', pg_temp.v('01'), 'cle-refaire-01') ? 'erreur'
  AND pg_temp.etat('01') = 'entretien_a_planifier'
  AND (SELECT count(*) FROM public.candidature_dispenses_entretien WHERE candidature_id = pg_temp.c('01')) = 1,
  'b1 : le retour apres une dispense est permis, la ligne de dispense reste');
SELECT pg_temp.vrai((pg_temp.controles('01') -> 0 ->> 'valeur') = 'false' AND (pg_temp.controles('01') -> 1 ->> 'valeur') = 'false',
  'b2 : la dispense d''avant le retour ne compte plus');
SELECT set_config('test.r01b', pg_temp.disp('01', 'autre', 'Nouvelle dispense', pg_temp.v('01'), 'cle-redispense-01')::text, true);
SELECT pg_temp.vrai(
  NOT current_setting('test.r01b')::jsonb ? 'erreur'
  AND pg_temp.etat('01') = 'decision_en_attente'
  AND (pg_temp.controles('01') -> 0 ->> 'valeur') = 'true' AND (pg_temp.controles('01') -> 1 ->> 'valeur') = 'true',
  'b3 : une nouvelle dispense apres le retour compte de nouveau');

-- (c) Les exigences
SELECT pg_temp.vrai(
  pg_temp.ref('07', '   ', pg_temp.v('07'), 'cle-refaire-07a') ->> 'erreur' = 'motif_requis'
  AND pg_temp.etat('07') = 'decision_en_attente'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_entretiens_refaits WHERE candidature_id = pg_temp.c('07')),
  'c1 : sans motif ecrit, rien n''est ecrit (motif_requis)');
SELECT pg_temp.vrai(
  pg_temp.ref('07', 'Motif', pg_temp.v('07') + 7, 'cle-refaire-07b') ->> 'erreur' = 'conflit_candidature'
  AND pg_temp.etat('07') = 'decision_en_attente',
  'c2 : une version perimee est refusee (conflit_candidature)');

-- (d) Portee
SELECT pg_temp.vrai(
  pg_temp.ref('03', 'Motif', pg_temp.v('03'), 'cle-refaire-03') ->> 'erreur' = 'transition_interdite'
  AND pg_temp.etat('03') = 'entretien_a_planifier',
  'd1 : hors de decision_en_attente, le geste est interdit');
SELECT pg_temp.vrai(
  pg_temp.ref('04', 'Motif', pg_temp.v('04'), 'cle-refaire-04') ->> 'erreur' = 'hors_portee'
  AND pg_temp.etat('04') = 'decision_en_attente',
  'd2 : une candidate de l''autre cote est hors de portee');
SELECT pg_temp.vrai(
  pg_temp.ref('05', 'Motif', pg_temp.v('05'), 'cle-refaire-05') ? 'erreur' AND pg_temp.etat('05') = 'decision_en_attente'
  AND pg_temp.ref('06', 'Motif', pg_temp.v('06'), 'cle-refaire-06') ? 'erreur' AND pg_temp.etat('06') = 'decision_en_attente'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_entretiens_refaits WHERE candidature_id IN (pg_temp.c('05'), pg_temp.c('06'))),
  'd3 : un dossier en pause ou refuse ne revient pas a l''entretien, rien n''est ecrit');
SELECT pg_temp.refus_en(pg_temp.p('02'), 'teacher',
  pg_catalog.format($q$SELECT public.refaire_entretien(%L, 'Motif', 1, 'cle-refaire-x')$q$, pg_temp.c('07')),
  '42501', 'd4 : un enseignant ne refait pas un entretien');
SELECT pg_temp.refus_en(NULL, NULL,
  pg_catalog.format($q$SELECT public.refaire_entretien(%L, 'Motif', 1, 'cle-refaire-y')$q$, pg_temp.c('07')),
  '42501', 'd5 : sans session, refus');

-- (e) La capacite
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.capacites_candidatures()') #>> '{gestes,refaireEntretien}') = 'true',
  'e1 : capacites_candidatures dit refaireEntretien');

-- (f) Droits
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.refaire_entretien(uuid,text,integer,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.refaire_entretien(uuid,text,integer,text)', 'EXECUTE')
  AND (SELECT bool_and(NOT has_function_privilege(r, 'private.candidature_geste_refaire_entretien(uuid,uuid,integer,text,text)', 'EXECUTE'))
         FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r)
  AND (SELECT bool_and(NOT has_table_privilege(r, 'public.candidature_entretiens_refaits', 'SELECT'))
         FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r)
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.candidature_entretiens_refaits'::regclass),
  'f1 : la porte est pour les comptes connectes ; le coeur prive et la table ne sont ouverts a personne ; RLS active');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || ';%')
     FROM unnest(ARRAY['public.refaire_entretien(uuid,text,integer,text)'::regprocedure]) AS f),
  'f2 : l''empreinte F86 est celle de la definition installee');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 21,
  'z : au moins 21 controles passes');
ROLLBACK;
