-- ACCUEIL-SEPARE (16/11/2026, migration 20261129410000) : « Accueillir dans l'equipe »
-- (public.valider_piece_candidat) ne decide plus de la piece et ne passe pas sur un complement.
--   (a) piece en attente : refus nomme (piece_validee, piece_a_verifier), piece intacte ;
--       piece refusee : piece_a_redeposer ; la piece se decide a part (decider_dossier), l'etape ne bouge pas ;
--   (b) complement en cours : refus nomme (complement_clos, complement_en_cours), rien d'ecrit ;
--       complement clos : l'accueil passe ;
--   (c) piece validee, aucun complement : accepte (confirmee, compte actif) ;
--   (d) non-regression : l'accueil reste refuse hors de decision_en_attente.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin.
-- Mots d'effacement : aucun. Entretien : une dispense de la direction (BE-1g) tient lieu d'entretien.
\o /dev/null
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

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ACCUEIL ROUGE : %', p_label;
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
    RAISE EXCEPTION 'ACCUEIL ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'ACCUEIL ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a130000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a13cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Tout ce que le geste peut ecrire pour une candidate : sa ligne, son
-- journal, sa piece, son profil enseignant, ses disponibilites, son compte.
CREATE FUNCTION pg_temp.trace(p_n text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'ligne', (SELECT md5(to_jsonb(c)::text) FROM public.candidatures c WHERE c.id = pg_temp.c(p_n)),
    'transitions', (SELECT count(*) FROM public.candidature_evenements e
                     WHERE e.candidature_id = pg_temp.c(p_n) AND e.type <> 'lecture_hors_portee'),
    'gestes', (SELECT count(*) FROM public.candidature_gestes g WHERE g.candidature_id = pg_temp.c(p_n)),
    'piece', (SELECT md5(coalesce(string_agg(to_jsonb(k)::text, '|' ORDER BY k.id), ''))
                FROM public.kyc_documents k WHERE k.profile_id = pg_temp.p(p_n)),
    'profil', (SELECT md5(to_jsonb(tp)::text) FROM public.teacher_profiles tp WHERE tp.profile_id = pg_temp.p(p_n)),
    'heures', (SELECT count(*) FROM public.weekly_availability w WHERE w.profile_id = pg_temp.p(p_n)),
    'compte', (SELECT account_status::text FROM public.profiles WHERE id = pg_temp.p(p_n)));
$$;

-- Valider la piece au nom d'une direction : la version courante est lue ici,
-- par le proprietaire, puis l'appel part sous authenticated.
CREATE FUNCTION pg_temp.valider(p_admin text, p_n text, p_cle text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v_version integer;
BEGIN
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
  RETURN pg_temp.en(pg_temp.p(p_admin), 'admin',
    pg_catalog.format('SELECT public.valider_piece_candidat(%L::uuid, %s, %L)', pg_temp.c(p_n), v_version, p_cle));
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text),
  pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.p(text), pg_temp.c(text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction au genre inconnu, a4
-- super-admin homme (exception de 0088), e1 tuteur.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'salle3-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'a4', 'e1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('5a13ffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'S3-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('a2'), 'S3-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('a3'), 'S3-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 (pg_temp.p('a4'), 'S3-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 (pg_temp.p('e1'), 'S3-TUT-0001', 'guardian', '5a13ffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('a4'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

-- Une version de TEST du cadre religieux, le temps du scenario.
INSERT INTO public.contract_required_versions (contract_kind, version)
VALUES ('teacher_religious_framework', 'test-cadre-s3')
ON CONFLICT (contract_kind) DO UPDATE SET version = excluded.version;

SELECT pg_temp.garde('reponses', $j$
{"langueMaternelle": "ar", "languesExplication": ["francais", "poular"],
 "niveauMemorisationDeclare": "coran_entier", "niveauLectureTajwid": "tajwid_enseigne",
 "riwayat": ["hafs", "warsh"], "ijazaPresentable": "oui", "experienceDebutants": "oui",
 "disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "22:00"},
                              {"jour": 3, "debut": "22:00", "fin": "24:00"}],
 "fuseauIana": "Asia/Riyadh", "classesSouhaitees": "2", "debutPossible": "immediat",
 "publics": ["6_9", "adultes"], "paysResidence": "SA", "paysVersement": "SA", "compteBancaire": true,
 "operateurs": [], "accordRemuneration": true}
$j$::jsonb);

-- Une candidate enseignante : compte teacher en attente, profil enseignant
-- vide (comme a l'inscription), reponses envoyees, moyen de paiement confirme
-- par la direction, accords signes (sauf ceux qu'on retire), et au besoin sa
-- piece deposee.
CREATE FUNCTION pg_temp.cand(p_n text, p_genre public.gender, p_etat text,
                             p_piece boolean DEFAULT true, p_sans text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email) VALUES (pg_temp.p(p_n), 'salle3-' || p_n || '@test.invalid');
  INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  VALUES (pg_temp.p(p_n), 'S3-ENS-00' || p_n, 'teacher', 'Candidate' || p_n, 'Fictive', 'pending_kyc', p_genre);
  INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
  VALUES (pg_temp.p(p_n), 'SA', ARRAY[]::text[], 'pending')
  ON CONFLICT (profile_id) DO NOTHING;
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
  VALUES (pg_temp.c(p_n), 'enseignant', pg_temp.p(p_n), p_genre, 'Fixture salle 3 ' || p_n,
          'verifications', p_etat, 'en_cours', false, 'lien_public');
  INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon,
                                           envoye_le)
  VALUES (pg_temp.c(p_n), 'salle-examen-2', pg_temp.lu('reponses'), 'candidat', false, pg_catalog.clock_timestamp());
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, operateur, decision, auteur_id)
  VALUES (pg_temp.c(p_n), 'SA', 'virement_bancaire', NULL, 'confirme',
          CASE WHEN p_genre = 'female' THEN pg_temp.p('a2') ELSE pg_temp.p('a1') END);
  UPDATE public.candidatures SET paiement = private.paiement_etat(id) WHERE id = pg_temp.c(p_n);
  -- Le contrat se signe par sa RPC, au nom de la candidate (empreinte posee
  -- par le serveur).
  PERFORM pg_temp.qui(pg_temp.p(p_n), 'teacher');
  PERFORM public.signer_contrat((SELECT version FROM public.contract_texts
                                  WHERE contract_kind = 'teacher_nda' AND locale = 'fr' AND is_current),
                                'Candidate ' || p_n);
  PERFORM pg_temp.qui(NULL, NULL);
  INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  SELECT pg_temp.p(p_n), r.contract_kind, r.version
    FROM public.contract_required_versions r
   WHERE r.contract_kind IN ('recording_and_control_notice', 'teacher_conduct_code', 'teacher_religious_framework')
     AND r.contract_kind IS DISTINCT FROM p_sans;
  IF p_piece THEN
    INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
    VALUES (pg_temp.p(p_n), 'passport', p_genre, 'salle3/' || p_n || '.jpg');
  END IF;
  RETURN pg_temp.c(p_n);
END $$;

-- 01 : piece en attente ; 02 : piece refusee ; 03 : piece validee, complement en cours ;
-- 04 : piece validee, aucun complement ; 05 : piece validee, complement demande puis clos ;
-- 06 : piece validee mais encore en entretien a planifier.
SELECT pg_temp.cand('01', 'female', 'decision_en_attente');
SELECT pg_temp.cand('02', 'female', 'decision_en_attente');
SELECT pg_temp.cand('03', 'female', 'decision_en_attente');
SELECT pg_temp.cand('04', 'female', 'decision_en_attente');
SELECT pg_temp.cand('05', 'female', 'decision_en_attente');
SELECT pg_temp.cand('06', 'female', 'entretien_a_planifier');
INSERT INTO public.candidature_dispenses_entretien (candidature_id, categorie, motif, auteur_id, etat_avant)
SELECT pg_temp.c(n), 'autre', 'fixture', pg_temp.p('a2'), 'decision_en_attente'
  FROM unnest(ARRAY['01', '02', '03', '04', '05']) AS n;
UPDATE public.kyc_documents SET status = 'rejected', rejection_reason = 'illisible', verified_by = pg_temp.p('a2'),
       verified_at = now() WHERE profile_id = pg_temp.p('02');
UPDATE public.kyc_documents SET status = 'approved', verified_by = pg_temp.p('a2'), verified_at = now()
 WHERE profile_id IN (pg_temp.p('03'), pg_temp.p('04'), pg_temp.p('05'), pg_temp.p('06'));
-- Un complement demande (transition 9) ; pour 05 il est clos ensuite (transition 6).
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, auteur_id, details)
SELECT pg_temp.c(n), 'transition', 'verifications', 'verifications', pg_temp.p('a2'),
       '{"transition": 9, "aCompleter": ["piece_identite"]}'::jsonb
  FROM unnest(ARRAY['03', '05']) AS n;
INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres, auteur_id, details)
VALUES (pg_temp.c('05'), 'transition', 'verifications', 'verifications', pg_temp.p('a2'), '{"transition": 6}'::jsonb);

-- (a) Piece en attente, puis refusee
SELECT pg_temp.garde('t01', pg_temp.trace('01'));
SELECT pg_temp.garde('r_a1', pg_temp.valider('a2', '01', 'cle-accueil-a-0001'));
SELECT pg_temp.vrai(pg_temp.lu('r_a1') ->> 'erreur' = 'controles_non_satisfaits'
  AND pg_temp.lu('r_a1') -> 'controles' = '[{"nom": "piece_validee", "cause": "piece_a_verifier"}]'::jsonb
  AND pg_temp.trace('01') = pg_temp.lu('t01')
  AND (SELECT status::text FROM public.kyc_documents WHERE profile_id = pg_temp.p('01')) = 'pending',
  'piece en attente : refus nomme (piece_validee, piece_a_verifier), la piece reste en attente, rien d''ecrit');
SELECT pg_temp.garde('r_a2', pg_temp.valider('a2', '02', 'cle-accueil-a-0002'));
SELECT pg_temp.vrai(pg_temp.lu('r_a2') -> 'controles' = '[{"nom": "piece_validee", "cause": "piece_a_redeposer"}]'::jsonb,
  'piece refusee : refus nomme (piece_a_redeposer)');

-- La piece se decide a part ; l'etape ne bouge pas, le compte reste en attente.
SELECT pg_temp.en(pg_temp.p('a2'), 'admin', pg_catalog.format(
  'SELECT pg_catalog.to_jsonb(public.decider_dossier(%L::uuid, true, NULL)::text)',
  (SELECT id FROM public.kyc_documents WHERE profile_id = pg_temp.p('01'))));
SELECT pg_temp.vrai((SELECT status::text FROM public.kyc_documents WHERE profile_id = pg_temp.p('01')) = 'approved'
  AND (SELECT etape || '/' || etat FROM public.candidatures WHERE id = pg_temp.c('01')) = 'verifications/decision_en_attente'
  AND (SELECT account_status::text FROM public.profiles WHERE id = pg_temp.p('01')) = 'pending_kyc',
  'decider_dossier : piece approuvee, etape inchangee (avant confirmee), compte encore en attente');

-- (b) Complement en cours / clos
SELECT pg_temp.garde('t03', pg_temp.trace('03'));
SELECT pg_temp.garde('r_b1', pg_temp.valider('a2', '03', 'cle-accueil-b-0001'));
SELECT pg_temp.vrai(pg_temp.lu('r_b1') ->> 'erreur' = 'controles_non_satisfaits'
  AND pg_temp.lu('r_b1') -> 'controles' = '[{"nom": "complement_clos", "cause": "complement_en_cours"}]'::jsonb
  AND pg_temp.trace('03') = pg_temp.lu('t03'),
  'complement en cours : refus nomme (complement_clos, complement_en_cours), rien d''ecrit');
SELECT pg_temp.garde('r_b2', pg_temp.valider('a2', '05', 'cle-accueil-b-0002'));
SELECT pg_temp.vrai(NOT (pg_temp.lu('r_b2') ? 'erreur')
  AND (SELECT etape FROM public.candidatures WHERE id = pg_temp.c('05')) = 'confirmee',
  'complement clos : l''accueil passe');

-- (c) Piece validee, aucun complement
SELECT pg_temp.garde('r_c', pg_temp.valider('a2', '04', 'cle-accueil-c-0001'));
SELECT pg_temp.vrai(NOT (pg_temp.lu('r_c') ? 'erreur')
  AND (SELECT etape = 'confirmee' AND issue = 'en_cours' FROM public.candidatures WHERE id = pg_temp.c('04'))
  AND (SELECT account_status::text FROM public.profiles WHERE id = pg_temp.p('04')) = 'active'
  AND (SELECT kyc_status FROM public.teacher_profiles WHERE profile_id = pg_temp.p('04')) = 'approved',
  'piece validee, aucun complement : accueillie (confirmee, compte actif)');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT pg_catalog.to_jsonb(public.valider_piece_candidat(pg_temp.c('04'), 1, 'cle-accueil-c-0001'))$$) ? 'erreur' IS NOT TRUE,
  'cle rejouee : meme reponse, sans erreur');

-- (d) Non-regression : hors de decision_en_attente
SELECT pg_temp.garde('t06', pg_temp.trace('06'));
SELECT pg_temp.garde('r_d', pg_temp.valider('a2', '06', 'cle-accueil-d-0001'));
SELECT pg_temp.vrai(pg_temp.lu('r_d') ->> 'erreur' = 'transition_interdite' AND pg_temp.trace('06') = pg_temp.lu('t06'),
  'entretien a planifier : transition_interdite, rien d''ecrit');
SELECT pg_temp.vrai((SELECT count(*) FROM jsonb_array_elements(private.candidature_controles_salle3(
         (SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('06')))) e
       WHERE e ->> 'nom' IN ('piece_validee', 'complement_clos')) = 2,
  'private.candidature_controles_salle3 : les deux controles nommes sont lus');

\o
SELECT 'ACCUEIL-SEPARE : tous les controles sont verts' AS verdict;
ROLLBACK;
