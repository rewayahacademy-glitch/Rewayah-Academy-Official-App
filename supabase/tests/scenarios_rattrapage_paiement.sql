-- RATTRAPAGE-PAIEMENT (16/11/2026) : les candidatures restees paiement_non_disponible alors que
-- leur versement est compatible (corrections faites avant l'installation de 20261128500100)
-- reviennent a a_completer par la transition 9 ; rien d'autre ne bouge. A rejouer sur une base
-- NEUVE ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'RATTRAPAGE ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a77aecc1-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a77a0000-0000-4000-8000-0000000000' || p_n)::uuid $$;


CREATE FUNCTION pg_temp.evenements(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c(p_n);
$$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT c.etat || '/' || c.paiement || '/' || c.version FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
$$;
CREATE FUNCTION pg_temp.transitions9(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = 'transition' AND e.details @> '{"transition": 9}'::jsonb;
$$;

-- 01 et 02 : bloquees, versement TR confirme (compatible). 03 : bloquee, pays sans ligne
-- (incompatible). 04 : en examen, compatible. 05 : bloquee mais refusee. 06 : bloquee, corrige sa
-- reponse APRES le correctif (cause reponses).
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'rattrapage-' || s || '@test.invalid' FROM unnest(ARRAY['01','02','03','04','05','06']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'A77A-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01','02','03','04','05','06']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, paiement)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s,
       'prequalification', v.etat, v.issue, 'lien_public', v.paiement
FROM (VALUES
  ('01', 'paiement_non_disponible', 'en_cours', 'compatible'),
  ('02', 'paiement_non_disponible', 'en_cours', 'compatible'),
  ('03', 'paiement_non_disponible', 'en_cours', 'incompatible'),
  ('04', 'en_examen', 'en_cours', 'compatible'),
  ('05', 'paiement_non_disponible', 'refusee', 'compatible'),
  ('06', 'paiement_non_disponible', 'en_cours', 'compatible')
) AS v(s, etat, issue, paiement);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT pg_temp.c(v.s), 'v1-2026-10', v.r::jsonb, 'candidat', now() - interval '1 day'
FROM (VALUES
  ('01', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('02', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('03', '{"paysVersement": "ZZ", "compteBancaire": true}'),
  ('04', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('05', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('06', '{"paysVersement": "TR", "compteBancaire": true}')
) AS v(s, r);

SELECT pg_temp.vrai(private.paiement_etat(pg_temp.c('01')) = 'compatible'
  AND private.paiement_etat(pg_temp.c('03')) <> 'compatible'
  AND (SELECT etat FROM public.referentiel_paiement WHERE pays = 'TR' AND methode = 'virement_bancaire') = 'confirme',
  'fixtures : TR confirme (compatible), ZZ sans ligne (pas compatible)');

-- Le correctif d'avenir : une correction de reponse ramene deja le dossier bloque.
SELECT private.paiement_recalculer(pg_temp.c('06'), 'reponses');
SELECT pg_temp.vrai(pg_temp.etat('06') LIKE 'a_completer/compatible/%' AND pg_temp.transitions9('06') = 1
  AND EXISTS (SELECT 1 FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('06')
                AND e.details @> '{"transition": 9, "cause": "reponses", "aNotifier": "paiement_possible"}'::jsonb),
  'a1 : le recalcul de cause reponses ramene un dossier compatible a a_completer (transition 9, avis paiement_possible)');

SELECT set_config('test.avant', (
  SELECT jsonb_object_agg(right(c.id::text, 2), pg_temp.etat(right(c.id::text, 2)))::text
    FROM public.candidatures c WHERE c.id::text LIKE 'a77aecc1%'), true);
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.candidatures c WHERE c.id::text LIKE 'a77aecc1%'
    AND c.issue = 'en_cours' AND c.etat = 'paiement_non_disponible' AND private.paiement_etat(c.id) = 'compatible'),
  'b0 : avant le rattrapage, des dossiers sont bloques alors que compatibles');

\ir ../migrations/20261128750000_rattrapage_paiement_non_disponible.sql

SELECT pg_temp.vrai(pg_temp.etat('01') LIKE 'a_completer/compatible/%' AND pg_temp.etat('02') LIKE 'a_completer/compatible/%'
  AND pg_temp.transitions9('01') = 1 AND pg_temp.transitions9('02') = 1
  AND (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id IN (pg_temp.c('01'), pg_temp.c('02'))
        AND e.details @> '{"transition": 9, "cause": "referentiel", "aCompleter": ["versement"], "aNotifier": "paiement_possible"}'::jsonb) = 2,
  'b1 : les dossiers bloques et compatibles reviennent a a_completer (transition 9, avis paiement_possible)');
SELECT pg_temp.vrai(pg_temp.etat('03') = (current_setting('test.avant')::jsonb ->> '03')
  AND pg_temp.transitions9('03') = 0,
  'b2 : un dossier qui reste incompatible n''est PAS ramene (etat, colonne, version intacts)');
SELECT pg_temp.vrai(pg_temp.etat('04') = (current_setting('test.avant')::jsonb ->> '04')
  AND pg_temp.etat('05') = (current_setting('test.avant')::jsonb ->> '05')
  AND pg_temp.transitions9('04') = 0 AND pg_temp.transitions9('05') = 0,
  'b3 : un dossier en examen et un dossier refuse ne bougent pas');
SELECT pg_temp.vrai(pg_temp.etat('06') = (current_setting('test.avant')::jsonb ->> '06') AND pg_temp.transitions9('06') = 1,
  'b4 : le dossier deja ramene par le correctif d''avenir n''est pas touche (une seule transition 9)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.candidatures c
    WHERE c.issue = 'en_cours' AND c.profile_id IS NOT NULL AND c.etape = 'prequalification'
      AND c.etat = 'paiement_non_disponible' AND private.paiement_etat(c.id) = 'compatible'),
  'b5 : controle final : plus aucune candidature bloquee alors que compatible');

SELECT set_config('test.apres1', (
  SELECT jsonb_object_agg(right(c.id::text, 2), pg_temp.etat(right(c.id::text, 2)) || '/' || pg_temp.evenements(right(c.id::text, 2)))::text
    FROM public.candidatures c WHERE c.id::text LIKE 'a77aecc1%'), true);
\ir ../migrations/20261128750000_rattrapage_paiement_non_disponible.sql
SELECT pg_temp.vrai(
  (SELECT jsonb_object_agg(right(c.id::text, 2), pg_temp.etat(right(c.id::text, 2)) || '/' || pg_temp.evenements(right(c.id::text, 2)))
     FROM public.candidatures c WHERE c.id::text LIKE 'a77aecc1%') = current_setting('test.apres1')::jsonb,
  'b6 : un second passage ne change plus rien (aucune version, aucun evenement)');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 8,
  'z : au moins 8 controles passes');
ROLLBACK;
