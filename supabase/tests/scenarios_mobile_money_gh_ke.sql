-- MOBILE-MONEY-GH-KE (pilote, 16/11/2026) : migration 20261129480000_mobile_money_gh_ke.sql.
--
-- Cas couverts : (a) quatre operateurs au catalogue et quatre lignes confirmees (GH : MTN MoMo, AirtelTigo,
-- Telecel ; KE : M-Pesa), source decision du directeur, verifiee le 16/11/2026 ; (b) une candidature en
-- paiement_non_disponible dont le moyen declare croise une de ces lignes revient a a_completer (transition 9,
-- avis paiement_possible) ; (c) une candidature en paiement_non_disponible qui reste incompatible (aucun moyen,
-- ou un operateur sans ligne) n'est PAS ramenee : pas de transition, pas d'avis, version intacte ; (d) une
-- candidature en examen dont le calcul devient compatible ne change que sa colonne paiement ; une refusee
-- n'est pas touchee ; (e) le journal du referentiel et l'audit portent chaque ligne, avec les compteurs ;
-- (f) le declencheur est remis en service ; (g) un second passage ne change plus rien.
-- Chaque controle leve 'MOBILE-MONEY ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE ; le scenario annule tout.
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
    RAISE EXCEPTION 'MOBILE-MONEY ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a77bcc00-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a77b0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT c.etat || '/' || c.paiement || '/' || c.version FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
$$;
CREATE FUNCTION pg_temp.t9(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = 'transition' AND e.details @> '{"transition": 9}'::jsonb;
$$;
CREATE FUNCTION pg_temp.evenements(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT count(*)::int FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c(p_n) $$;

-- (a) Les lignes existent des l'installation (la migration s'est jouee avec toutes les autres).
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.referentiel_paiement_operateurs
    WHERE code IN ('mtn_momo', 'airteltigo', 'telecel', 'm_pesa') AND methode = 'mobile_money' AND actif) = 4
  AND (SELECT count(*) FROM public.referentiel_paiement l
        WHERE l.methode = 'mobile_money' AND l.etat = 'confirme' AND l.source = 'decision_directeur'
          AND l.verifie_le = DATE '2026-11-16' AND l.prestataire = 'wise' AND l.type_decaissement = 'payout_portefeuille'
          AND ((l.pays = 'GH' AND l.operateur IN ('mtn_momo', 'airteltigo', 'telecel') AND l.devise = 'GHS')
               OR (l.pays = 'KE' AND l.operateur = 'm_pesa' AND l.devise = 'KES'))) = 4
  AND (SELECT count(*) FROM public.referentiel_paiement WHERE methode = 'mobile_money' AND pays IN ('GH', 'KE')) = 4,
  'a1 : quatre operateurs au catalogue, quatre lignes confirmees (decision du directeur, 16/11/2026), aucune autre ligne mobile au Ghana ni au Kenya');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.referentiel_paiement_journal j JOIN public.referentiel_paiement l ON l.id = j.ligne_id
    WHERE l.methode = 'mobile_money' AND l.pays IN ('GH', 'KE') AND j.avant IS NULL AND j.auteur_id IS NULL) = 4
  AND (SELECT count(*) FROM public.audit_logs a WHERE a.action = 'referentiel_paiement_ecriture'
        AND a.payload ->> 'methode' = 'mobile_money' AND a.payload ->> 'voie' = 'directe') >= 4
  AND (SELECT tgenabled FROM pg_trigger WHERE tgrelid = 'public.referentiel_paiement'::regclass
        AND tgname = 'referentiel_paiement_effets') = 'O',
  'a2 : le journal du referentiel et l''audit portent les quatre lignes ; le declencheur est remis en service');

-- Fixtures : on retire les quatre lignes (declencheurs suspendus pour le scenario seulement) pour rejouer le fichier
-- avec des candidatures en place.
SET LOCAL session_replication_role = replica;
DELETE FROM public.referentiel_paiement_journal j USING public.referentiel_paiement l
 WHERE l.id = j.ligne_id AND l.methode = 'mobile_money' AND l.pays IN ('GH', 'KE');
DELETE FROM public.referentiel_paiement WHERE methode = 'mobile_money' AND pays IN ('GH', 'KE');
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'mm-' || s || '@test.invalid' FROM unnest(ARRAY['01', '02', '03', '04', '05', '06']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'MM-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, paiement)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, 'prequalification', v.etat, v.issue, 'lien_public', 'incompatible'
FROM (VALUES
  ('01', 'paiement_non_disponible', 'en_cours'), ('02', 'paiement_non_disponible', 'en_cours'),
  ('03', 'paiement_non_disponible', 'en_cours'), ('04', 'en_examen', 'en_cours'),
  ('05', 'paiement_non_disponible', 'en_cours'), ('06', 'paiement_non_disponible', 'refusee')) AS v(s, etat, issue);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT pg_temp.c(v.s), 'v1-2026-10', v.r::jsonb, 'candidat', now() - interval '1 day'
FROM (VALUES
  ('01', '{"paysVersement": "GH", "compteBancaire": false, "operateurs": ["mtn_momo"]}'),
  ('02', '{"paysVersement": "GH", "compteBancaire": false, "operateurs": []}'),
  ('03', '{"paysVersement": "KE", "compteBancaire": false, "operateurs": ["m_pesa"]}'),
  ('04', '{"paysVersement": "GH", "compteBancaire": false, "operateurs": ["telecel"]}'),
  ('05', '{"paysVersement": "KE", "compteBancaire": false, "operateurs": ["orange_money"]}'),
  ('06', '{"paysVersement": "GH", "compteBancaire": false, "operateurs": ["mtn_momo"]}')) AS v(s, r);
SET LOCAL session_replication_role = origin;

SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.referentiel_paiement WHERE methode = 'mobile_money' AND pays IN ('GH', 'KE')) = 0
  AND private.paiement_etat(pg_temp.c('01')) = 'incompatible' AND private.paiement_etat(pg_temp.c('03')) = 'incompatible'
  AND private.paiement_etat(pg_temp.c('04')) = 'incompatible',
  'b0 : sans les lignes, les moyens mobiles declares sont incompatibles (fixtures)');
SELECT set_config('test.avant', (
  SELECT jsonb_object_agg(right(c.id::text, 2), pg_temp.etat(right(c.id::text, 2)) || '/' || pg_temp.evenements(right(c.id::text, 2)))::text
    FROM public.candidatures c WHERE c.id::text LIKE 'a77bcc00%'), true);

\ir ../migrations/20261129480000_mobile_money_gh_ke.sql

SELECT pg_temp.vrai(
  pg_temp.etat('01') LIKE 'a_completer/compatible/%' AND pg_temp.t9('01') = 1 AND pg_temp.etat('03') LIKE 'a_completer/compatible/%'
  AND pg_temp.t9('03') = 1
  AND (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id IN (pg_temp.c('01'), pg_temp.c('03'))
        AND e.details @> '{"transition": 9, "cause": "referentiel", "aCompleter": ["versement"], "aNotifier": "paiement_possible"}'::jsonb) = 2,
  'c1 : un dossier en paiement_non_disponible dont le moyen mobile croise une ligne revient a a_completer (transition 9, avis paiement_possible)');
SELECT pg_temp.vrai(
  pg_temp.etat('02') || '/' || pg_temp.evenements('02') = current_setting('test.avant')::jsonb ->> '02'
  AND pg_temp.etat('05') || '/' || pg_temp.evenements('05') = current_setting('test.avant')::jsonb ->> '05'
  AND pg_temp.t9('02') = 0 AND pg_temp.t9('05') = 0
  AND pg_temp.etat('02') LIKE 'paiement_non_disponible/incompatible/%' AND pg_temp.etat('05') LIKE 'paiement_non_disponible/incompatible/%',
  'c2 : un dossier qui reste incompatible (aucun moyen ; un operateur sans ligne) n''est pas ramene : ni transition, ni avis, version et journal intacts');
SELECT pg_temp.vrai(
  pg_temp.etat('04') LIKE 'en_examen/compatible/%' AND pg_temp.t9('04') = 0
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('04') AND e.details ? 'aNotifier')
  AND pg_temp.etat('06') || '/' || pg_temp.evenements('06') = current_setting('test.avant')::jsonb ->> '06',
  'd1 : un dossier en examen devient compatible sans changer d''etat ni prevenir personne ; un dossier refuse n''est pas touche');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.referentiel_paiement_journal j JOIN public.referentiel_paiement l ON l.id = j.ligne_id
    WHERE l.methode = 'mobile_money' AND l.pays IN ('GH', 'KE')) = 4
  AND (SELECT (j.impact ->> 'aCompleter')::int FROM public.referentiel_paiement_journal j JOIN public.referentiel_paiement l ON l.id = j.ligne_id
        WHERE l.operateur = 'mtn_momo') = 1
  AND (SELECT (j.impact ->> 'aCompleter')::int FROM public.referentiel_paiement_journal j JOIN public.referentiel_paiement l ON l.id = j.ligne_id
        WHERE l.operateur = 'm_pesa') = 1
  AND (SELECT (j.impact ->> 'recalculees')::int FROM public.referentiel_paiement_journal j JOIN public.referentiel_paiement l ON l.id = j.ligne_id
        WHERE l.operateur = 'm_pesa') = 2,
  'e1 : le journal porte les quatre lignes avec leurs compteurs (une candidature ramenee pour MTN MoMo et pour M-Pesa ; deux recalculees pour M-Pesa)');
SELECT pg_temp.vrai(
  (SELECT tgenabled FROM pg_trigger WHERE tgrelid = 'public.referentiel_paiement'::regclass AND tgname = 'referentiel_paiement_effets') = 'O',
  'f1 : le declencheur du referentiel est remis en service apres le fichier');

SELECT set_config('test.apres1', (
  SELECT jsonb_object_agg(right(c.id::text, 2), pg_temp.etat(right(c.id::text, 2)) || '/' || pg_temp.evenements(right(c.id::text, 2)))::text
    FROM public.candidatures c WHERE c.id::text LIKE 'a77bcc00%'), true);
\ir ../migrations/20261129480000_mobile_money_gh_ke.sql
SELECT pg_temp.vrai(
  (SELECT jsonb_object_agg(right(c.id::text, 2), pg_temp.etat(right(c.id::text, 2)) || '/' || pg_temp.evenements(right(c.id::text, 2)))
     FROM public.candidatures c WHERE c.id::text LIKE 'a77bcc00%') = current_setting('test.apres1')::jsonb
  AND (SELECT count(*) FROM public.referentiel_paiement WHERE methode = 'mobile_money' AND pays IN ('GH', 'KE')) = 4,
  'g1 : un second passage ne change plus rien (quatre lignes, aucune version, aucun evenement)');
ROLLBACK;
