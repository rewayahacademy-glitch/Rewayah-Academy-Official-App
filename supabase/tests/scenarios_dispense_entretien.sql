-- BE-1g DISPENSE-ENTRETIEN (directeur, 16/11/2026) : migration 20261129470000_dispense_entretien.sql.
--
-- Cas couverts : (a) la direction dispense une candidature en entretien_a_planifier : etat d'arrivee
-- decision_en_attente (celui d'un entretien tenu), version et evenement (type entretien, categorie), ligne
-- de dispense, controles de la salle 3 vrais ; (b) un entretien deja planifie est annule sans rien effacer
-- (issue annule, seance canceled) ; (c) motif obligatoire, categorie fondateur ou autre, conflit de version,
-- rejeu par la meme cle, second geste refuse ; (d) portee (hors etape, autre cote, role) ; (e) le lot :
-- apercu puis execution, motif et categorie exiges, nom camelCase accepte ; (f) la capacite et la ligne de
-- la liste des enseignants ; (g) la table n'est lisible par personne, droits.
-- Chaque controle leve 'DISPENSE ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
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
    RAISE EXCEPTION 'DISPENSE ROUGE : %', p_label;
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
    RAISE EXCEPTION 'DISPENSE ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'DISPENSE ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de100000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('de10cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$ SELECT coalesce(etat, '-') FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
CREATE FUNCTION pg_temp.disp(p_n text, p_cat text, p_motif text, p_version integer, p_cle text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.dispenser_entretien(%L, %L, %L, %s, %L)', pg_temp.c(p_n), p_cat, p_motif, p_version, p_cle));
$$;
CREATE FUNCTION pg_temp.controles(p_n text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT private.candidature_entretien_controles(pg_temp.c(p_n));
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text), pg_temp.v(text), pg_temp.etat(text), pg_temp.disp(text, text, text, integer, text),
  pg_temp.controles(text), pg_temp.refus_en(uuid, text, text, text, text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme). Candidats hommes en Salle de verification : 01 et 05 et 06 et 07 entretien a planifier ;
-- 02 entretien planifie (seance et entretien reels) ; 03 en examen (salle d'examen) ; 04 une candidate (femme),
-- entretien a planifier : hors du cote de a1.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'de-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07', '08']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'DE-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'DE-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc',
       CASE WHEN s = '04' THEN 'female'::gender ELSE 'male'::gender END
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), v.g::gender, 'Fixture ' || v.s, v.etape, v.etat, 'en_cours', 'lien_public'
FROM (VALUES
  ('01', 'male', 'verifications', 'entretien_a_planifier'),
  ('02', 'male', 'verifications', 'entretien_planifie'),
  ('03', 'male', 'prequalification', 'en_examen'),
  ('04', 'female', 'verifications', 'entretien_a_planifier'),
  ('05', 'male', 'verifications', 'entretien_a_planifier'),
  ('06', 'male', 'verifications', 'entretien_a_planifier'),
  ('07', 'male', 'verifications', 'entretien_a_planifier'),
  ('08', 'male', 'verifications', 'entretien_a_planifier')) AS v(s, g, etape, etat);
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, join_opens_at)
VALUES ('de100000-0000-4000-8000-000000000301', pg_temp.p('a1'), now() + interval '2 days', now() + interval '2 days 30 minutes',
        'planned', 'entretien', now() + interval '2 days' - interval '10 minutes');
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
VALUES ('de100000-0000-4000-8000-000000000301', pg_temp.c('02'), pg_temp.p('02'), pg_temp.p('a1'));
SET LOCAL session_replication_role = origin;

-- ------------------------------------------------------------
-- (a) Dispenser un fondateur
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.controles('01') -> 0 ->> 'valeur') = 'false' AND (pg_temp.controles('01') -> 1 ->> 'valeur') = 'false',
  'a0 : avant la dispense, les controles entretien_conclu et evaluation_validee sont faux');
SELECT set_config('test.v01', pg_temp.v('01')::text, true);
SELECT set_config('test.r01', pg_temp.disp('01', 'fondateur', 'مؤسس : pas d''entretien pour l''instant', pg_temp.v('01'), 'cle-dispense-01')::text, true);
SELECT pg_temp.vrai(
  current_setting('test.r01')::jsonb ? 'candidature' AND NOT current_setting('test.r01')::jsonb ? 'erreur'
  AND pg_temp.etat('01') = 'decision_en_attente' AND pg_temp.v('01') = current_setting('test.v01')::int + 1,
  'a1 : la dispense amene la candidature en decision_en_attente, comme un entretien tenu, une version de plus');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_dispenses_entretien d
    WHERE d.candidature_id = pg_temp.c('01') AND d.categorie = 'fondateur' AND d.auteur_id = pg_temp.p('a1')
      AND d.etat_avant = 'entretien_a_planifier' AND d.session_annulee IS NULL AND d.motif LIKE 'مؤسس%') = 1
  AND (SELECT count(*) FROM public.candidature_evenements e
        WHERE e.candidature_id = pg_temp.c('01') AND e.type = 'entretien' AND e.etat_avant = 'entretien_a_planifier'
          AND e.etat_apres = 'decision_en_attente' AND e.auteur_id = pg_temp.p('a1')
          AND e.details @> '{"geste": "dispenser_entretien", "transition": 45, "dispense": "fondateur", "entretienAnnule": false}'::jsonb
          AND e.motif_interne LIKE 'مؤسس%') = 1,
  'a2 : une ligne de dispense (qui, categorie, motif, etat d''avant) et un evenement de type entretien sur le dossier');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.audit_logs a WHERE a.action = 'candidature_geste' AND a.row_id = pg_temp.c('01')::text
     AND a.payload ->> 'geste' = 'dispenser_entretien' AND a.payload ->> 'etatApres' = 'decision_en_attente') = 1,
  'a3 : le journal sensible garde la dispense');
SELECT pg_temp.vrai(
  (pg_temp.controles('01') -> 0 ->> 'valeur') = 'true' AND (pg_temp.controles('01') -> 1 ->> 'valeur') = 'true'
  AND (pg_temp.controles('01') -> 0 ->> 'cause') IS NULL,
  'a4 : apres la dispense, entretien_conclu et evaluation_validee sont vrais (valider_piece peut conclure)');
SELECT pg_temp.vrai(
  (pg_temp.disp('01', 'fondateur', 'مؤسس : pas d''entretien pour l''instant', 1, 'cle-dispense-01') - 'rejoue')
    = (current_setting('test.r01')::jsonb - 'rejoue')
  AND (pg_temp.disp('01', 'fondateur', 'مؤسس : pas d''entretien pour l''instant', 1, 'cle-dispense-01') ->> 'rejoue') = 'true'
  AND (SELECT count(*) FROM public.candidature_dispenses_entretien d WHERE d.candidature_id = pg_temp.c('01')) = 1,
  'a5 : rejouer la meme cle rend le meme resultat (marque rejoue) sans nouvelle ligne');
SELECT pg_temp.vrai(
  pg_temp.disp('01', 'fondateur', 'Encore', pg_temp.v('01'), 'cle-dispense-01b') ->> 'erreur' = 'transition_interdite',
  'a6 : une candidature deja en decision_en_attente n''est plus dispensable');

-- ------------------------------------------------------------
-- (b) Un entretien deja planifie est annule, rien n'est efface
-- ------------------------------------------------------------
SELECT set_config('test.r02', pg_temp.disp('02', 'autre', 'Reprise d''un ancien enseignant', pg_temp.v('02'), 'cle-dispense-02')::text, true);
SELECT pg_temp.vrai(
  NOT current_setting('test.r02')::jsonb ? 'erreur'
  AND pg_temp.etat('02') = 'decision_en_attente'
  AND (SELECT issue || '|' || coalesce(consigne_par::text, '') FROM public.entretiens
        WHERE session_id = 'de100000-0000-4000-8000-000000000301') = 'annule|' || pg_temp.p('a1')::text
  AND (SELECT status::text FROM public.sessions WHERE id = 'de100000-0000-4000-8000-000000000301') = 'canceled'
  AND (SELECT session_annulee FROM public.candidature_dispenses_entretien WHERE candidature_id = pg_temp.c('02'))
      = 'de100000-0000-4000-8000-000000000301'
  AND EXISTS (SELECT 1 FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('02')
              AND e.details @> '{"dispense": "autre", "entretienAnnule": true}'::jsonb),
  'b1 : un entretien planifie est annule (issue annule, seance canceled), la dispense garde la seance, rien n''est efface');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.entretiens WHERE candidature_id = pg_temp.c('02')) = 1
  AND (SELECT count(*) FROM public.sessions WHERE id = 'de100000-0000-4000-8000-000000000301') = 1,
  'b2 : la ligne d''entretien et la seance existent toujours');

-- ------------------------------------------------------------
-- (c) Les exigences et les refus
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.disp('05', 'fondateur', '   ', pg_temp.v('05'), 'cle-dispense-05a') ->> 'erreur' = 'motif_requis'
  AND pg_temp.etat('05') = 'entretien_a_planifier'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_dispenses_entretien WHERE candidature_id = pg_temp.c('05')),
  'c1 : sans motif ecrit, rien n''est ecrit (motif_requis)');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin',
  pg_catalog.format($q$SELECT public.dispenser_entretien(%L, 'autre_chose', 'Motif', 1, 'cle-dispense-05b')$q$, pg_temp.c('05')),
  '22023', 'c2 : une categorie inconnue est refusee (22023)');
SELECT pg_temp.vrai(
  pg_temp.disp('05', 'fondateur', 'Motif', pg_temp.v('05') + 7, 'cle-dispense-05c') ->> 'erreur' = 'conflit_candidature'
  AND pg_temp.etat('05') = 'entretien_a_planifier',
  'c3 : une version perimee est refusee (conflit_candidature)');
SELECT pg_temp.vrai(
  pg_temp.disp('03', 'fondateur', 'Motif', pg_temp.v('03'), 'cle-dispense-03') ->> 'erreur' = 'transition_interdite'
  AND pg_temp.etat('03') = 'en_examen',
  'd1 : hors de la salle de verification (en examen), le geste est interdit');
SELECT pg_temp.vrai(
  pg_temp.disp('04', 'fondateur', 'Motif', pg_temp.v('04'), 'cle-dispense-04') ->> 'erreur' = 'hors_portee'
  AND pg_temp.etat('04') = 'entretien_a_planifier'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_dispenses_entretien WHERE candidature_id = pg_temp.c('04')),
  'd2 : une candidate de l''autre cote est hors de portee, rien n''est ecrit');
SELECT pg_temp.refus_en(pg_temp.p('02'), 'teacher',
  pg_catalog.format($q$SELECT public.dispenser_entretien(%L, 'fondateur', 'Motif', 1, 'cle-dispense-x')$q$, pg_temp.c('05')),
  '42501', 'd3 : un enseignant ne dispense pas');
SELECT pg_temp.refus_en(NULL, NULL,
  pg_catalog.format($q$SELECT public.dispenser_entretien(%L, 'fondateur', 'Motif', 1, 'cle-dispense-y')$q$, pg_temp.c('05')),
  '42501', 'd4 : sans session, refus');

-- ------------------------------------------------------------
-- (e) Le lot : 05, 06 et 07 sont eligibles, 03 est exclue
-- ------------------------------------------------------------
SELECT set_config('test.apercu', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
  'SELECT public.apercu_lot_candidats(%L, %L::uuid[])', 'dispenserEntretien',
  ARRAY[pg_temp.c('05'), pg_temp.c('06'), pg_temp.c('07'), pg_temp.c('03')]::text)) ::text, true);
SELECT pg_temp.vrai(
  (current_setting('test.apercu')::jsonb ->> 'nombre') = '3' AND current_setting('test.apercu')::jsonb ->> 'geste' = 'dispenser_entretien'
  AND (current_setting('test.apercu')::jsonb ->> 'motifRequis') = 'true'
  AND jsonb_array_length(current_setting('test.apercu')::jsonb -> 'exclus') = 1
  AND (current_setting('test.apercu')::jsonb #>> '{effet,etat}') = 'decision_en_attente',
  'e1 : l''apercu du lot dit trois eligibles, une exclue (en examen), l''effet decision_en_attente, le motif requis');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.executer_lot_candidats(%L, %L::uuid[], %L, 3, %L, NULL, ''fondateur'', NULL)', 'dispenser_entretien',
    ARRAY[pg_temp.c('05'), pg_temp.c('06'), pg_temp.c('07'), pg_temp.c('03')]::text,
    current_setting('test.apercu')::jsonb ->> 'jeton', 'cle-lot-dispense-1')) ->> 'erreur' = 'motif_requis',
  'e2 : le lot sans motif est refuse avant toute ecriture');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.executer_lot_candidats(%L, %L::uuid[], %L, 3, %L, ''Fondateurs : pas d entretien'', NULL, NULL)', 'dispenser_entretien',
    ARRAY[pg_temp.c('05'), pg_temp.c('06'), pg_temp.c('07'), pg_temp.c('03')]::text,
    current_setting('test.apercu')::jsonb ->> 'jeton', 'cle-lot-dispense-2')) ->> 'erreur' = 'categorie_requise'
  AND pg_temp.etat('05') = 'entretien_a_planifier',
  'e3 : le lot sans categorie est refuse avant toute ecriture');
SELECT set_config('test.lot', pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
    'SELECT public.executer_lot_candidats(%L, %L::uuid[], %L, 3, %L, ''Fondateurs : pas d entretien'', ''fondateur'', NULL)', 'dispenser_entretien',
    ARRAY[pg_temp.c('05'), pg_temp.c('06'), pg_temp.c('07'), pg_temp.c('03')]::text,
    current_setting('test.apercu')::jsonb ->> 'jeton', 'cle-lot-dispense-3'))::text, true);
SELECT pg_temp.vrai(
  (current_setting('test.lot')::jsonb ->> 'reussies') = '3' AND (current_setting('test.lot')::jsonb ->> 'exclues') = '1'
  AND pg_temp.etat('05') = 'decision_en_attente' AND pg_temp.etat('06') = 'decision_en_attente'
  AND pg_temp.etat('07') = 'decision_en_attente' AND pg_temp.etat('03') = 'en_examen'
  AND (SELECT count(*) FROM public.candidature_dispenses_entretien
        WHERE candidature_id IN (pg_temp.c('05'), pg_temp.c('06'), pg_temp.c('07')) AND categorie = 'fondateur') = 3,
  'e4 : le lot dispense les trois eligibles (categorie fondateur, motif), laisse la quatrieme inchangee, une ligne par candidature');

-- ------------------------------------------------------------
-- (f) La capacite et la liste des enseignants
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.capacites_candidatures()') #>> '{gestes,dispenserEntretien}') = 'true'
  AND (pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.capacites_candidatures()') -> 'gestesGroupables') @> '["dispenserEntretien"]'::jsonb,
  'f1 : capacites_candidatures dit dispenserEntretien et le range parmi les gestes groupables');
SELECT pg_temp.vrai(
  (SELECT (l -> 'gestes') @> '["dispenser_entretien"]'::jsonb AND (l -> 'gestesGroupables') @> '["dispenser_entretien"]'::jsonb
     FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin',
       $q$SELECT public.lister_enseignants('{"recherche": "fixture 08"}'::jsonb, 'recente', 1)$q$) -> 'lignes') AS t(l))
  AND (SELECT NOT ((l -> 'gestes') @> '["dispenser_entretien"]'::jsonb)
     FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin',
       $q$SELECT public.lister_enseignants('{"recherche": "fixture 01"}'::jsonb, 'recente', 1)$q$) -> 'lignes') AS t(l)),
  'f2 : la liste des enseignants propose dispenser_entretien (et le dit groupable) pour une candidature a planifier, pas pour une candidature deja dispensee');

-- ------------------------------------------------------------
-- (g) Droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.dispenser_entretien(uuid,text,text,integer,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.dispenser_entretien(uuid,text,text,integer,text)', 'EXECUTE')
  AND (SELECT bool_and(NOT has_function_privilege(r, 'private.candidature_geste_dispenser(uuid,text,uuid,integer,text,text,jsonb)', 'EXECUTE'))
         FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r)
  AND (SELECT bool_and(NOT has_table_privilege(r, 'public.candidature_dispenses_entretien', 'SELECT'))
         FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r)
  AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.candidature_dispenses_entretien'::regclass),
  'g1 : la porte est pour les comptes connectes ; le coeur prive et la table ne sont ouverts a personne ; RLS active');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || ';%')
     FROM unnest(ARRAY['public.dispenser_entretien(uuid,text,text,integer,text)'::regprocedure,
                       'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure,
                       'public.apercu_lot_candidats(text,uuid[])'::regprocedure,
                       'public.capacites_candidatures()'::regprocedure]) AS f),
  'g2 : les empreintes F86 sont celles des definitions installees');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 24,
  'z : au moins 24 controles passes');
ROLLBACK;
