-- BE-VERSEMENT : un moyen de versement qui suit la regle se valide seul (directeur, 16/11/2026).
-- Migrations 20261128200000_be_versement_regle.sql (la regle) et
-- 20261128200100_be_versement_recalcul.sql (le recalcul unique).
--
-- Cas couverts : (a) un pays confirme : compatible sans geste, en prequalification comme en
-- salle 3 (jamais restreinte pour le paiement) ; (b) confirme puis infirme par la direction :
-- incompatible, en paiement_non_disponible ; (c) un pays dont la ligne est en_verification :
-- le calcul rend `incompatible` (aucun moyen ne croise une ligne confirme ; ce n'est PAS
-- `a_verifier`, voir le dernier controle de ce groupe), la candidature attend dans
-- paiement_non_disponible ; la direction confirme la ligne UNE fois, par la RPC du referentiel :
-- tous les candidats du pays suivent (compatible, a_completer) ; (d) une ligne indisponible :
-- incompatible ; (e) le recalcul unique : une valeur `a_verifier` de la colonne (donnee passee)
-- devient compatible, un evenement `controle` tracé, aucune version de plus qu'une, ni
-- etape, ni etat, ni issue changes, aucun `aNotifier` ; rejouer ne change rien ; (f) le geste
-- 24 n'est plus propose : aucun calcul ne rend `a_verifier` ; le geste 25 reste ouvert pour un
-- moyen compatible ; (g) droits : private.paiement_etat n'est executable par aucun compte.
-- Chaque controle leve 'BE-VERSEMENT ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE
-- (stub_auth puis toutes les migrations) ; le scenario annule tout a la fin.
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
    RAISE EXCEPTION 'BE-VERSEMENT ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be7ecccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be7e0000-0000-4000-8000-0000000000' || p_n)::uuid $$;

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

-- La ligne d'un pays (virement) et son ecriture par la RPC, au nom de l'appelant courant.
CREATE FUNCTION pg_temp.ligne(p_pays text) RETURNS public.referentiel_paiement
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT l.* FROM public.referentiel_paiement l
   WHERE l.pays = p_pays AND l.methode = 'virement_bancaire' AND l.operateur IS NULL;
$$;
CREATE FUNCTION pg_temp.ecrire(p_pays text, p_etat text, p_cle text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE
  v_l public.referentiel_paiement := pg_temp.ligne(p_pays);
BEGIN
  RETURN public.enregistrer_ligne_referentiel_paiement(
    v_l.id, p_pays, 'virement_bancaire', NULL, NULL, NULL, NULL, p_etat,
    CASE WHEN p_etat = 'confirme' THEN current_date END, NULL, v_l.version, p_cle);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.c(text), pg_temp.p(text), pg_temp.ligne(text), pg_temp.ecrire(text, text, text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme). Candidats, tous des hommes :
-- 01 Turquie, confirme, en examen ; 02 idem, que la direction infirmera ; 03 Royaume-Uni (ligne
-- passee en verification) en examen ; 04 Royaume-Uni en paiement_non_disponible ; 05 Jordanie
-- (ligne rendue indisponible) ; 06 Turquie en salle 3 ; 07 Turquie, colonne `a_verifier`
-- (donnee passee) ; 08 Turquie, colonne `a_verifier`, moyen infirme par la direction ; 09 Turquie,
-- colonne `a_verifier`, en paiement_non_disponible ; 10 Turquie, colonne `incompatible`,
-- refusee (hors du recalcul).
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'be-versement-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'BE7E-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'BE7E-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']) AS s;

INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s,
       v.etape, v.etat, v.issue, 'lien_public'
FROM (VALUES
  ('01', 'prequalification', 'en_examen', 'en_cours'),
  ('02', 'prequalification', 'en_examen', 'en_cours'),
  ('03', 'prequalification', 'en_examen', 'en_cours'),
  ('04', 'prequalification', 'paiement_non_disponible', 'en_cours'),
  ('05', 'prequalification', 'en_examen', 'en_cours'),
  ('06', 'confirmee', NULL, 'en_cours'),
  ('07', 'prequalification', 'en_examen', 'en_cours'),
  ('08', 'prequalification', 'en_examen', 'en_cours'),
  ('09', 'prequalification', 'paiement_non_disponible', 'en_cours'),
  ('10', 'prequalification', 'en_examen', 'refusee')
) AS v(s, etape, etat, issue);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT pg_temp.c(v.s), 'v1-2026-10', v.r::jsonb, 'candidat', now() - interval '1 day'
FROM (VALUES
  ('01', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('02', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('03', '{"paysVersement": "GB", "compteBancaire": true}'),
  ('04', '{"paysVersement": "GB", "compteBancaire": true}'),
  ('05', '{"paysVersement": "JO", "compteBancaire": true}'),
  ('06', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('07', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('08', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('09', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('10', '{"paysVersement": "TR", "compteBancaire": true}')
) AS v(s, r);

SELECT pg_temp.vrai((SELECT count(*) FROM public.candidatures WHERE id::text LIKE 'be7ecccc%') = 10
  AND (SELECT etat FROM public.referentiel_paiement WHERE pays = 'TR' AND methode = 'virement_bancaire') = 'confirme'
  AND (SELECT etat FROM public.referentiel_paiement WHERE pays = 'GB' AND methode = 'virement_bancaire') = 'confirme'
  AND (SELECT etat FROM public.referentiel_paiement WHERE pays = 'JO' AND methode = 'virement_bancaire') = 'confirme',
  'fixtures : 10 candidatures, lignes de TR, GB et JO confirmees au depart');

-- ------------------------------------------------------------
-- (a) Un pays confirme : compatible sans geste
-- ------------------------------------------------------------
SELECT pg_temp.vrai(private.paiement_etat(pg_temp.c('01')) = 'compatible'
  AND private.paiement_compatible(pg_temp.c('01')),
  'a1 : un moyen qui croise une ligne confirme est compatible, sans aucune decision de la direction');
SELECT private.paiement_recalculer(pg_temp.c('01'), 'reponses');
SELECT pg_temp.vrai(pg_temp.vue('01') = 'compatible/compatible/en_examen/libre'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_paiement_decisions d WHERE d.candidature_id = pg_temp.c('01')),
  'a2 : la colonne suit le calcul, la candidature reste en examen, aucune decision ecrite');
SELECT private.paiement_recalculer(pg_temp.c('06'), 'reponses');
SELECT pg_temp.vrai(pg_temp.vue('06') = 'compatible/compatible/-/libre',
  'a3 : en salle 3, un pays confirme n''est pas restreint pour le paiement');

-- ------------------------------------------------------------
-- (b) Confirme puis infirme par la direction (geste 25)
-- ------------------------------------------------------------
SELECT private.paiement_recalculer(pg_temp.c('02'), 'reponses');
INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, motif_interne, auteur_id)
VALUES (pg_temp.c('02'), 'TR', 'virement_bancaire', 'infirme',
        'Compte au nom d''un tiers (fixture).', pg_temp.p('a1'));
SELECT pg_temp.vrai(private.paiement_etat(pg_temp.c('02')) = 'incompatible',
  'b1 : une decision de la direction qui infirme le moyen rend incompatible, meme si la ligne est confirmee');
SELECT private.paiement_recalculer(pg_temp.c('02'), 'moyen_infirme', pg_temp.p('a1'), 'Compte au nom d''un tiers (fixture).');
SELECT pg_temp.vrai(pg_temp.vue('02') = 'incompatible/incompatible/paiement_non_disponible/libre',
  'b2 : la candidature attend en paiement_non_disponible (transition 8)');
INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, auteur_id)
VALUES (pg_temp.c('02'), 'TR', 'virement_bancaire', 'confirme', pg_temp.p('a1'));
SELECT pg_temp.vrai(private.paiement_etat(pg_temp.c('02')) = 'compatible',
  'b3 : la derniere decision fait foi : confirmee de nouveau, le moyen est compatible');

-- ------------------------------------------------------------
-- (c) Ligne en verification : la direction decide une fois par pays
-- ------------------------------------------------------------
UPDATE public.referentiel_paiement SET etat = 'en_verification', verifie_le = NULL
WHERE pays = 'GB' AND methode = 'virement_bancaire' AND operateur IS NULL;
SELECT private.paiement_recalculer(pg_temp.c('03'), 'referentiel');
SELECT private.paiement_recalculer(pg_temp.c('04'), 'referentiel');
SELECT pg_temp.vrai(private.paiement_etat(pg_temp.c('03')) = 'incompatible'
  AND private.paiement_etat(pg_temp.c('04')) = 'incompatible'
  AND pg_temp.vue('03') = 'incompatible/incompatible/paiement_non_disponible/libre',
  'c1 : ligne en verification : aucun moyen ne croise une ligne confirme, le calcul rend incompatible (jamais a_verifier) et la candidature attend en paiement_non_disponible');
SELECT pg_temp.qui(pg_temp.p('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT set_config('test.ecr', pg_temp.ecrire('GB', 'confirme', 'be-versement-gb-0001')::text, true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.vue('03') = 'compatible/compatible/paiement_non_disponible/libre'
  OR pg_temp.vue('03') = 'compatible/compatible/a_completer/libre',
  'c2 : la direction confirme la ligne une fois : le candidat du pays qui attendait est compatible, sans geste par dossier');
SELECT pg_temp.vrai(pg_temp.vue('04') LIKE 'compatible/compatible/a_completer/%'
  AND pg_temp.vue('03') LIKE 'compatible/compatible/%',
  'c3 : tous les candidats du pays suivent (transition 9 : a_completer pour qui attendait)');

-- ------------------------------------------------------------
-- (d) Ligne indisponible : incompatible, personne n'agit
-- ------------------------------------------------------------
UPDATE public.referentiel_paiement SET etat = 'indisponible', notes = 'Ecriture directe (fixture BE-VERSEMENT).'
WHERE pays = 'JO' AND methode = 'virement_bancaire' AND operateur IS NULL;
SELECT pg_temp.vrai(private.paiement_etat(pg_temp.c('05')) = 'incompatible'
  AND NOT private.paiement_compatible(pg_temp.c('05'))
  AND (SELECT etat FROM public.candidatures WHERE id = pg_temp.c('05')) = 'paiement_non_disponible',
  'd1 : ligne indisponible : incompatible ; le declencheur du referentiel a mis le candidat en paiement_non_disponible (transition 8)');

-- ------------------------------------------------------------
-- (e) Le recalcul unique (20261128200100)
-- ------------------------------------------------------------
-- Donnees passees : la colonne dit a_verifier, comme les 125 de la production avant ce lot.
UPDATE public.candidatures SET paiement = 'a_verifier' WHERE id IN (pg_temp.c('07'), pg_temp.c('08'), pg_temp.c('09'));
UPDATE public.candidatures SET paiement = 'incompatible' WHERE id = pg_temp.c('10');
INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, motif_interne, auteur_id)
VALUES (pg_temp.c('08'), 'TR', 'virement_bancaire', 'infirme', 'Compte au nom d''un tiers (fixture).', pg_temp.p('a1'));
SELECT set_config('test.avant', (
  SELECT jsonb_object_agg(right(c.id::text, 2), jsonb_build_object('v', c.version, 'e', c.etape, 'et', c.etat, 'i', c.issue,
                                                                  'ev', pg_temp.evenements(right(c.id::text, 2))))::text
    FROM public.candidatures c WHERE c.id::text LIKE 'be7ecccc%'), true);
\ir ../migrations/20261128200100_be_versement_recalcul.sql
SELECT pg_temp.vrai(pg_temp.vue('07') = 'compatible/compatible/en_examen/libre',
  'e1 : une donnee passee a_verifier devient compatible (07), etat et etape inchanges');
SELECT pg_temp.vrai(pg_temp.vue('08') = 'incompatible/incompatible/paiement_non_disponible/libre',
  'e2 : un moyen deja infirme par la direction devient incompatible (08), jamais compatible');
SELECT pg_temp.vrai(pg_temp.vue('09') = 'compatible/compatible/paiement_non_disponible/libre',
  'e3 : un dossier deja en paiement_non_disponible devient compatible mais n''est pas ramene a a_completer par ce recalcul (la transition 9 previent la personne : hors de ce recalcul)');
SELECT pg_temp.vrai(pg_temp.vue('10') = 'compatible/incompatible/en_examen/libre'
  AND pg_temp.evenements('10') = (current_setting('test.avant')::jsonb -> '10' ->> 'ev')::int,
  'e4 : une candidature refusee n''est pas recalculee (colonne et journal intacts)');
SELECT pg_temp.vrai(
  (SELECT bool_and((c.version = (current_setting('test.avant')::jsonb -> right(c.id::text, 2) ->> 'v')::int + 1)
                   AND c.etape = current_setting('test.avant')::jsonb -> right(c.id::text, 2) ->> 'e')
     FROM public.candidatures c WHERE c.id IN (pg_temp.c('07'), pg_temp.c('09')))
  AND (SELECT count(*) FROM public.candidature_evenements e
        WHERE e.candidature_id IN (pg_temp.c('07'), pg_temp.c('09')) AND e.type = 'controle'
          AND e.details @> '{"controle": "paiement_compatible", "cause": "referentiel", "paiementAvant": "a_verifier",
                             "paiementApres": "compatible", "valeurApres": true}'::jsonb) = 2,
  'e5 : une version de plus et un evenement controle journalise (cause referentiel, avant a_verifier, apres compatible) par dossier change');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                                 WHERE e.candidature_id IN (pg_temp.c('07'), pg_temp.c('08'), pg_temp.c('09'))
                                   AND e.details ? 'aNotifier')
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                   WHERE e.candidature_id IN (pg_temp.c('07'), pg_temp.c('09')) AND e.type <> 'controle'
                     AND e.cree_le > now() - interval '1 minute'),
  'e6 : aucun evenement a notifier : le recalcul ne previent personne (aucune transition, aucun aNotifier)');
SELECT set_config('test.apres1', (
  SELECT jsonb_object_agg(right(c.id::text, 2), jsonb_build_object('v', c.version, 'ev', pg_temp.evenements(right(c.id::text, 2))))::text
    FROM public.candidatures c WHERE c.id::text LIKE 'be7ecccc%'), true);
\ir ../migrations/20261128200100_be_versement_recalcul.sql
SELECT pg_temp.vrai(current_setting('test.apres1')::jsonb = (
  SELECT jsonb_object_agg(right(c.id::text, 2), jsonb_build_object('v', c.version, 'ev', pg_temp.evenements(right(c.id::text, 2))))
    FROM public.candidatures c WHERE c.id::text LIKE 'be7ecccc%'),
  'e7 : un second passage ne change plus rien (aucune version, aucun evenement)');

-- ------------------------------------------------------------
-- (f) Le geste 24 n'est plus propose ; le geste 25 reste ouvert
-- ------------------------------------------------------------
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM public.candidatures c
     WHERE c.id::text LIKE 'be7ecccc%' AND c.issue = 'en_cours' AND c.profile_id IS NOT NULL
       AND private.paiement_etat(c.id) = 'a_verifier'),
  'f1 : aucune candidature du scenario n''est a_verifier au calcul : la condition du geste 24 n''est jamais vraie');
SELECT pg_temp.vrai(private.candidature_condition(
    (SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('07')), 'paiement_a_verifier_ou_compatible')
  AND NOT private.candidature_condition(
    (SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('07')), 'paiement_a_verifier'),
  'f2 : pour un moyen compatible, le geste 25 (infirmer) reste ouvert et le geste 24 (confirmer) est ferme');

-- ------------------------------------------------------------
-- (g) Droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT bool_and(NOT has_function_privilege(r, 'private.paiement_etat(uuid)'::regprocedure, 'EXECUTE'))
     FROM unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) AS r),
  'g1 : private.paiement_etat n''est executable par aucun compte');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 21,
  'z : au moins 21 controles passes');
DO $$ BEGIN RAISE NOTICE 'BE-VERSEMENT : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
