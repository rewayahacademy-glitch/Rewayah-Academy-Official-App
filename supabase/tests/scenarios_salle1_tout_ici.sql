-- SALLE-1-TOUT-ICI (07/11/2026 ; migration 20261119100000) : la piece
-- d'identite se depose des la salle 1 (« Votre candidature »), tant que la
-- candidature est a completer.
--
-- Ce que le scenario prouve :
--   1. une candidate en salle 1 a completer : la porte R2 est ouverte, la
--      reservation R2 passe, la piece posee par la voie serveur passe le
--      declencheur du depot et nait en attente ;
--   2. cette piece n'entre PAS dans la file d'ADM-02 ni dans le compteur
--      d'ADM-01 : elle y entrera a l'admission en salle 2 ;
--   3. pendant l'examen (en_examen), apres un refus, apres un retrait : refus
--      par toute voie, cause depot_piece_hors_etape ;
--   4. une candidature d'un autre type que enseignant, en salle 1 a
--      completer, ne profite pas de la nouvelle regle ;
--   5. la regle et le declencheur ne sont appelables par aucun client.
-- Le courriel « retenu pour un entretien » est prouve dans
-- scenarios_cand_l2a2_gestes_direction.sql (parcours reel d'admission).
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'SALLE-1 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('salle1-' || p)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

-- Refus attendu : code et message.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RAISE EXCEPTION 'SALLE-1 ROUGE : % (accepte)', p_label;
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM LIKE 'SALLE-1 ROUGE%' THEN
    RAISE;
  END IF;
  IF SQLSTATE <> p_code OR pg_catalog.strpos(SQLERRM, p_message) = 0 THEN
    RAISE EXCEPTION 'SALLE-1 ROUGE : % (% % au lieu de % %)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Fixtures : une candidate en salle 1 a completer (s1), une en examen (ex),
-- une refusee (rf), une retiree (rt) ; une directrice active (dir) ; un type
-- de candidature d'un autre role (fixture) pour la regle 4.
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'salle1-' || x || '@test.invalid'
  FROM unnest(ARRAY['s1', 'ex', 'rf', 'rt', 'dir', 'au']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.id(x), 'SALLE1-' || pg_catalog.upper(x), 'teacher', NULL, 'Candidate', 'Test', 'pending_kyc', 'female'
  FROM unnest(ARRAY['s1', 'ex', 'rf', 'rt']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('dir'), 'SALLE1-DIR', 'admin', NULL, 'Directrice', 'Test', 'active', 'female');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES (pg_temp.id('c-s1'), 'enseignant', pg_temp.id('s1'), 'female', 'Candidate S1', 'prequalification', 'a_completer', 'en_cours', 'lien_public'),
       (pg_temp.id('c-ex'), 'enseignant', pg_temp.id('ex'), 'female', 'Candidate EX', 'prequalification', 'en_examen', 'en_cours', 'lien_public'),
       (pg_temp.id('c-rf'), 'enseignant', pg_temp.id('rf'), 'female', 'Candidate RF', 'prequalification', 'a_completer', 'refusee', 'lien_public'),
       (pg_temp.id('c-rt'), 'enseignant', pg_temp.id('rt'), 'female', 'Candidate RT', 'prequalification', 'a_completer', 'retiree', 'lien_public');

-- 1. La candidate en salle 1 a completer depose sa piece.
SELECT pg_temp.qui(pg_temp.id('s1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.peut_deposer_piece_identite(pg_temp.id('s1')),
  'salle 1 a completer : la porte du depot R2 est ouverte');
SELECT pg_temp.vrai(public.preparer_depot_piece_identite(pg_temp.id('s1'), 'passport') IS NOT NULL,
  'salle 1 a completer : la reservation R2 passe');
RESET ROLE;
-- La voie serveur (la fonction Edge de confirmation pose la ligne apres
-- verification du contenu) : le declencheur du depot la laisse passer.
INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
VALUES (pg_temp.id('s1'), 'passport', 's1/piece.jpg');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.kyc_documents k
    WHERE k.profile_id = pg_temp.id('s1') AND k.object_key = 's1/piece.jpg' AND k.status = 'pending'
      AND k.verified_by IS NULL AND k.verified_at IS NULL) = 1,
  'salle 1 a completer : la piece passe le declencheur du depot et nait en attente, sans decision');

-- 1 bis. Les accords en salle 1 : aucun changement serveur n'etait
-- necessaire ; on le prouve. Le contrat par signer_contrat (version en
-- vigueur), l'avis d'enregistrement et le code de conduite aux versions
-- requises, par la candidate elle-meme, compte pending_kyc.
SELECT pg_temp.qui(pg_temp.id('s1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.signer_contrat(
  (SELECT t.version FROM public.contract_texts t
    WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current), 'Candidate Test');
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES (pg_temp.id('s1'), 'recording_and_control_notice', '2026-10-jur'),
       (pg_temp.id('s1'), 'teacher_conduct_code', public.code_conduite_version_requise());
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT count(DISTINCT a.contract_kind) FROM public.contract_acceptances a
    WHERE a.profile_id = pg_temp.id('s1')
      AND a.contract_kind IN ('teacher_nda', 'recording_and_control_notice', 'teacher_conduct_code')) = 3
  AND (SELECT r.version FROM public.contract_required_versions r
        WHERE r.contract_kind = 'recording_and_control_notice') = '2026-10-jur',
  'salle 1 a completer : contrat, avis d''enregistrement et code de conduite acceptes par la candidate');

-- 2. Elle n'entre pas dans la file de la direction avant la salle 2.
SELECT pg_temp.qui(pg_temp.id('dir'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.dossiers_en_attente() d WHERE d.profile_id = pg_temp.id('s1'))
  AND (SELECT i.dossiers_en_attente FROM public.indicateurs_admin() i)
      = (SELECT count(DISTINCT d.profile_id)::int FROM public.dossiers_en_attente() d
          WHERE d.account_status = 'pending_kyc'),
  'piece de salle 1 : ni dans la file d''ADM-02, ni dans le compteur d''ADM-01');
RESET ROLE;
-- Admise en salle 2 (etat pose comme le ferait la transition 10) : la piece
-- entre dans la file.
UPDATE public.candidatures SET etape = 'verifications', etat = 'entretien_a_planifier'
 WHERE id = pg_temp.id('c-s1');
SELECT pg_temp.qui(pg_temp.id('dir'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.dossiers_en_attente() d
           WHERE d.profile_id = pg_temp.id('s1') AND d.etat_piece = 'a_verifier'),
  'admise en salle 2 : la piece deposee en salle 1 entre dans la file d''ADM-02, a verifier');
RESET ROLE;

-- 3. Pendant l'examen, apres un refus, apres un retrait : refus par toute voie.
DO $refus$
DECLARE
  v text;
BEGIN
  FOREACH v IN ARRAY ARRAY['ex', 'rf', 'rt'] LOOP
    PERFORM pg_temp.qui(pg_temp.id(v), 'teacher');
    SET LOCAL ROLE authenticated;
    PERFORM pg_temp.vrai(NOT public.peut_deposer_piece_identite(pg_temp.id(v)),
      v || ' : la porte du depot R2 reste fermee');
    PERFORM pg_temp.refus(pg_catalog.format(
      'SELECT public.preparer_depot_piece_identite(%L, %L)', pg_temp.id(v), 'passport'),
      '42501', 'depot refuse pour ce profil', v || ' : reservation R2 refusee');
    RESET ROLE;
    PERFORM pg_temp.refus(pg_catalog.format(
      'INSERT INTO public.kyc_documents (profile_id, doc_type, object_key) VALUES (%L, %L, %L)',
      pg_temp.id(v), 'passport', v || '/piece.jpg'),
      '42501', 'depot_piece_hors_etape', v || ' : piece posee par la voie serveur : refusee');
  END LOOP;
END $refus$;

-- 4. Un autre type de candidature en salle 1 a completer : la regle de
-- SALLE-1 ne vaut que pour le type enseignant.
INSERT INTO public.candidature_types (code, role_compte) VALUES ('salle_autre_type', 'teacher');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('au'), 'SALLE1-AU', 'teacher', NULL, 'Autre', 'Type', 'pending_kyc', 'female');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES (pg_temp.id('c-au'), 'salle_autre_type', pg_temp.id('au'), 'female', 'Autre Type',
        'prequalification', 'a_completer', 'en_cours', 'lien_public');
SELECT pg_temp.refus($$INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
  VALUES (pg_temp.id('au'), 'passport', 'au/piece.jpg')$$,
  '42501', 'depot_piece_hors_etape', 'autre type de candidature en salle 1 : piece refusee');

-- 5. Droits.
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'private.candidature_accepte_depot_piece(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.candidature_accepte_depot_piece(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('service_role', 'private.candidature_accepte_depot_piece(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('agent_ro', 'private.candidature_accepte_depot_piece(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.kyc_depot_etape_trg()', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.peut_deposer_piece_identite(uuid)', 'EXECUTE')
  AND pg_catalog.obj_description('public.peut_deposer_piece_identite(uuid)'::regprocedure, 'pg_proc')
      LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.peut_deposer_piece_identite(uuid)'::regprocedure)) || '%'
  AND pg_catalog.obj_description('public.admettre_salle_verification(uuid,integer,text)'::regprocedure, 'pg_proc')
      LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.admettre_salle_verification(uuid,integer,text)'::regprocedure)) || '%',
  'regle et declencheur : aucun client ; fiches F86 des deux RPC a leur empreinte reelle');

ROLLBACK;
