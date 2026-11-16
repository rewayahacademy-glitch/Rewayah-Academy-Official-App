-- VERSEMENT-QUESTIONS, PR 1 : la correction de donnees de CAND-00013 (directeur, 16/11/2026).
-- Migration 20261128500000_versement_cand_00013.sql, rejouee ici (la commande psql i) sur des donnees inventees.
--
-- Cas couverts : (a) le point de depart (« non » au compte bancaire + Arabie saoudite : aucun moyen
-- possible, en attente) ; (b) une reponse envoyee de plus, copie de la derniere avec seulement
-- compteBancaire = oui, l'historique et le brouillon intacts ; (c) un evenement controle qui cite
-- la decision ; (d) paiement compatible, dossier de retour a a_completer (transition 9) ; (e) une
-- autre candidate jamais touchee ; (f) rejouer ne change rien.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations), depuis la racine du depot
-- (le chemin de l'inclusion est relatif) ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'VERSEMENT-CAND ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- '13' est la vraie CAND-00013 (l'identifiant que la migration vise) ; les autres sont inventees.
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN p_n = '13' THEN '4bf5377e-a3bb-4d97-9623-63b380fd9b22'::uuid
              ELSE ('be7fcccc-0000-4000-8000-0000000000' || p_n)::uuid END $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be7f0000-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- L'etat lu par le calcul en direct, la colonne, l'etat de la candidature.
CREATE FUNCTION pg_temp.vue(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT private.paiement_etat(c.id) || '/' || c.paiement || '/' || coalesce(c.etat, '-') || '/'
         || CASE WHEN c.restreinte THEN 'restreinte' ELSE 'libre' END
    FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
$$;

CREATE FUNCTION pg_temp.evenements(p_n text, p_type text DEFAULT NULL) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND (p_type IS NULL OR e.type = p_type);
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.c(text), pg_temp.p(text) TO authenticated, anon;
-- ------------------------------------------------------------
-- Fixtures (donnees inventees ; l'identifiant de 13 est celui de la vraie CAND-00013)
-- ------------------------------------------------------------
-- a1 direction (homme). 13 : candidate (femme), en paiement_non_disponible, a repondu « non » au
-- compte bancaire puis pays de versement SA (virement confirme) ; une reponse plus ancienne et un
-- brouillon plus recent existent aussi. 14 : une autre candidate, meme situation, qui ne doit
-- jamais etre touchee.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'versement-cand-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '13', '14']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'BE7F-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'BE7F-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictive', 'pending_kyc', 'female'
FROM unnest(ARRAY['13', '14']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(s), 'enseignant', pg_temp.p(s), 'female', 'Fixture ' || s,
       'prequalification', 'paiement_non_disponible', 'en_cours', 'lien_public'
FROM unnest(ARRAY['13', '14']) AS s;
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, soumis_le)
SELECT pg_temp.c(v.s), 'v1-2026-10', v.r::jsonb, 'candidat', v.b, v.t
FROM (VALUES
  ('13', '{"paysVersement": "FR", "compteBancaire": true, "ancienne": 1}', false, now() - interval '3 days'),
  ('13', '{"paysVersement": "SA", "compteBancaire": false, "texte": "garde"}', false, now() - interval '1 day'),
  ('13', '{"paysVersement": "SA", "compteBancaire": false, "brouillon": 1}', true, now() - interval '1 hour'),
  ('14', '{"paysVersement": "SA", "compteBancaire": false}', false, now() - interval '1 day')
) AS v(s, r, b, t);
SELECT private.paiement_recalculer(pg_temp.c(s), 'reponses') FROM unnest(ARRAY['13', '14']) AS s;

CREATE FUNCTION pg_temp.envoyees(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_reponses r
   WHERE r.candidature_id = pg_temp.c(p_n) AND r.source = 'candidat' AND NOT r.brouillon;
$$;
CREATE FUNCTION pg_temp.evenement(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = 'controle'
     AND e.details ->> 'controle' = 'compte_bancaire_corrige';
$$;
GRANT EXECUTE ON FUNCTION pg_temp.envoyees(text), pg_temp.evenement(text) TO authenticated, anon;

SELECT pg_temp.vrai((SELECT etat FROM public.referentiel_paiement WHERE pays = 'SA' AND methode = 'virement_bancaire') = 'confirme',
  'a0 : le virement saoudien est confirme au referentiel (point de depart du cas)');
SELECT pg_temp.vrai(pg_temp.vue('13') LIKE 'incompatible/incompatible/paiement_non_disponible/%'
  AND pg_temp.vue('14') LIKE 'incompatible/incompatible/paiement_non_disponible/%',
  'a1 : avant la correction, « non » au compte bancaire + Arabie saoudite : aucun moyen possible, en attente');
SELECT set_config('test.v13', (SELECT version::text FROM public.candidatures WHERE id = pg_temp.c('13')), true);
SELECT set_config('test.v14', (SELECT version::text FROM public.candidatures WHERE id = pg_temp.c('14')), true);

-- ------------------------------------------------------------
-- La correction (le fichier de migration lui-meme, rejoue sur ces donnees)
-- ------------------------------------------------------------
\i supabase/migrations/20261128500000_versement_cand_00013.sql

SELECT pg_temp.vrai(pg_temp.envoyees('13') = 3 AND pg_temp.envoyees('14') = 1,
  'b1 : une reponse envoyee de plus pour 13 (l''historique est garde), aucune pour 14');
SELECT pg_temp.vrai(
  (SELECT r.reponses FROM public.candidature_reponses r
    WHERE r.candidature_id = pg_temp.c('13') AND r.source = 'candidat' AND NOT r.brouillon
    ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1)
  = '{"paysVersement": "SA", "compteBancaire": true, "texte": "garde"}'::jsonb,
  'b2 : la derniere reponse envoyee est la copie de l''avant-derniere (SA, texte garde), seul compteBancaire passe a oui');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_reponses r
    WHERE r.candidature_id = pg_temp.c('13') AND r.reponses ->> 'compteBancaire' = 'false'
      AND r.reponses ->> 'paysVersement' = 'SA') = 2
  AND (SELECT count(*) FROM public.candidature_reponses r
        WHERE r.candidature_id = pg_temp.c('13') AND r.brouillon AND r.reponses ? 'brouillon') = 1,
  'b3 : l''ancienne reponse « non » et le brouillon sont intacts (rien de reecrit)');
SELECT pg_temp.vrai(pg_temp.evenement('13') = 1 AND pg_temp.evenement('14') = 0
  AND (SELECT e.motif_interne LIKE '%16/11/2026%' AND e.motif_interne LIKE '%mari%' AND e.auteur_id IS NULL
         AND e.details @> '{"compteBancaireAvant": false, "compteBancaireApres": true, "paysVersement": "SA"}'::jsonb
         FROM public.candidature_evenements e
        WHERE e.candidature_id = pg_temp.c('13') AND e.details ->> 'controle' = 'compte_bancaire_corrige'),
  'c1 : un evenement controle cite la decision du directeur et le message de la candidate');
SELECT pg_temp.vrai(pg_temp.vue('13') LIKE 'compatible/compatible/a_completer/%',
  'd1 : le paiement passe a compatible, le dossier revient a a_completer (transition 9)');
SELECT pg_temp.vrai(
  (SELECT e.details ->> 'aNotifier' = 'paiement_possible'
     FROM public.candidature_evenements e
    WHERE e.candidature_id = pg_temp.c('13') AND e.type = 'transition' AND e.etat_apres = 'a_completer'
    ORDER BY e.id DESC LIMIT 1),
  'd2 : l''avis « paiement possible » est pose par la transition (comme le recalcul de BE-VERSEMENT)');
SELECT pg_temp.vrai(pg_temp.vue('14') LIKE 'incompatible/incompatible/paiement_non_disponible/%'
  AND (SELECT version::text FROM public.candidatures WHERE id = pg_temp.c('14')) = current_setting('test.v14'),
  'e1 : l''autre candidate n''a pas bouge (paiement, etat, version)');

-- Rejouer ne change plus rien.
SELECT set_config('test.v13b', (SELECT version::text FROM public.candidatures WHERE id = pg_temp.c('13')), true);
\i supabase/migrations/20261128500000_versement_cand_00013.sql
SELECT pg_temp.vrai(pg_temp.envoyees('13') = 3 AND pg_temp.evenement('13') = 1
  AND (SELECT version::text FROM public.candidatures WHERE id = pg_temp.c('13')) = current_setting('test.v13b'),
  'f1 : rejouee, la migration ne change rien (aucune reponse, aucun evenement, aucune version)');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 10,
  'z : au moins 10 controles passes');
DO $$ BEGIN RAISE NOTICE 'VERSEMENT-CAND : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
