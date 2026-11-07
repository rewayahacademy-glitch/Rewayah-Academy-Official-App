-- Salle 3 (03/11/2026) : « Valider la piece » fait entrer une candidate
-- enseignante en Salle des prets a enseigner (transition 14), et la direction
-- lit son affectation. Migration 20261108300000_salle3_valider_piece.sql.
--
-- Ce que le scenario prouve :
--   (a) droits : anon ne peut rien, un tuteur est refuse, les aides internes
--       ne sont executables par aucun compte ; validerPiece suit peutDecider ;
--   (b) tant que l'entretien n'existe pas (voie (a) de CAND-Q01), la
--       validation refuse avec entretien_conclu et evaluation_validee, cause
--       entretien_non_disponible, et RIEN n'est ecrit (piece, profil
--       enseignant, disponibilites, compte, candidature, journal) ;
--   (c) cloisonnement femmes/hommes (CAND-Q07) : une direction de l'autre
--       cote est hors portee (trace), sans aucune ecriture ; le super-admin ne
--       fait pas le geste hors de son cote ;
--   (d) hors de decision_en_attente : transition_interdite ;
--   (e) V1-a simule (`private.entretien_conclusion` creee dans la
--       transaction, lue dynamiquement) : avis non favorable, constat
--       incomplet, accord manquant, piece absente refusent sans rien ecrire ;
--   (f) tout est en ordre : en une transaction, piece approuvee, langues et
--       fuseau copies, quatre heures de disponibilites, candidature
--       confirmee, compte actif, evenement et journal ; une cle rejouee rend
--       le meme resultat sans ecrire deux fois ;
--   (g) affectation_candidat : avant (causes nommees), apres (affectable,
--       aucune Classe), puis une Classe ; hors portee pour l'autre cote, lue
--       par le super-admin (trace).
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures et annule tout a la fin. Mots d'effacement :
-- aucun.
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
    RAISE EXCEPTION 'SALLE3 ROUGE : %', p_label;
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
    RAISE EXCEPTION 'SALLE3 ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'SALLE3 ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
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

-- 01 : en ordre (femme) ; 02 : sans code de conduite ; 03 : sans piece ;
-- 04 : encore en entretien a planifier ; 05 : un homme en ordre.
SELECT pg_temp.cand('01', 'female', 'decision_en_attente');
SELECT pg_temp.cand('02', 'female', 'decision_en_attente', true, 'teacher_conduct_code');
SELECT pg_temp.cand('03', 'female', 'decision_en_attente', false);
SELECT pg_temp.cand('04', 'female', 'entretien_a_planifier');
SELECT pg_temp.cand('05', 'male', 'decision_en_attente');

SELECT pg_temp.vrai((SELECT count(*) FROM public.candidatures WHERE id::text LIKE '5a13cccc%') = 5
  AND (SELECT bool_and(paiement = 'compatible') FROM public.candidatures WHERE id::text LIKE '5a13cccc%')
  AND (SELECT count(*) FROM public.kyc_documents k WHERE k.profile_id::text LIKE '5a130000%'
         AND k.status = 'pending') = 4,
  'fixtures : cinq candidates en salle 2, paiement compatible, quatre pieces deposees en attente');

-- ------------------------------------------------------------
-- (a) Droits et capacites
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.valider_piece_candidat(pg_temp.c('01'), 1, 'cle-anon-0001')$$,
  '42501', 'anon : valider_piece_candidat refuse (aucun EXECUTE)', 'anon');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.affectation_candidat(pg_temp.c('01'))$$,
  '42501', 'anon : affectation_candidat refuse (aucun EXECUTE)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('e1'), 'guardian',
  $$SELECT public.valider_piece_candidat(pg_temp.c('01'), 1, 'cle-tuteur-0001')$$,
  '42501', 'tuteur : valider_piece_candidat refuse');
SELECT pg_temp.refus_en(pg_temp.p('e1'), 'guardian', $$SELECT public.affectation_candidat(pg_temp.c('01'))$$,
  '42501', 'tuteur : affectation_candidat refuse');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin',
  $$SELECT public.valider_piece_candidat(pg_temp.c('01'), 1, 'cle-inconnu-0001')$$,
  '42501', 'direction au genre inconnu : aucun geste');
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.candidature_controles_salle3(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.candidature_entretien_controles(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.valider_piece_candidat(uuid,integer,text)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.affectation_candidat(uuid)', 'EXECUTE'),
  'aides internes executables par aucun compte ; service_role sans EXECUTE sur les deux RPC');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.capacites_candidatures()$$) -> 'gestes' ->> 'validerPiece')::boolean
  AND NOT (pg_temp.en(pg_temp.p('a3'), 'admin', $$SELECT public.capacites_candidatures()$$) -> 'gestes' ->> 'validerPiece')::boolean
  AND (pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.capacites_candidatures()$$) -> 'gestes' -> 'validerPiece')
      = (pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.capacites_candidatures()$$) -> 'peutDecider'),
  'capacites : validerPiece vrai pour la direction de genre connu, faux sans genre, egal a peutDecider');

-- ------------------------------------------------------------
-- (b) Sans entretien en base : refus nomme, rien d'ecrit
-- ------------------------------------------------------------
SELECT pg_temp.garde('t01', pg_temp.trace('01'));
SELECT pg_temp.garde('r_b', pg_temp.valider('a2', '01', 'cle-salle3-b-0001'));
SELECT pg_temp.vrai(pg_temp.lu('r_b') ->> 'erreur' = 'controles_non_satisfaits'
  -- V1-a absente : entretien_non_disponible ; V1-a installee (20261108000001,
  -- PR 189), sans entretien tenu : entretien_non_tenu.
  AND pg_temp.lu('r_b') -> 'controles' = pg_catalog.replace(
        '[{"nom": "entretien_conclu", "cause": "X"}, {"nom": "evaluation_validee", "cause": "X"}]',
        'X', CASE WHEN pg_catalog.to_regprocedure('private.entretien_conclusion(uuid)') IS NULL
                  THEN 'entretien_non_disponible' ELSE 'entretien_non_tenu' END)::jsonb,
  'sans entretien : controles_non_satisfaits, entretien_conclu et evaluation_validee nommes (non disponible ou non tenu)');
SELECT pg_temp.vrai(pg_temp.trace('01') = pg_temp.lu('t01')
  AND (SELECT kyc_status FROM public.teacher_profiles WHERE profile_id = pg_temp.p('01')) = 'pending'
  AND (SELECT count(*) FROM public.weekly_availability WHERE profile_id = pg_temp.p('01')) = 0
  AND (SELECT account_status::text FROM public.profiles WHERE id = pg_temp.p('01')) = 'pending_kyc',
  'refus : rien n''est ecrit (piece, profil enseignant, aucune disponibilite, compte en attente, candidature, journal)');

-- ------------------------------------------------------------
-- (c) L'autre cote : hors portee, rien d'ecrit
-- ------------------------------------------------------------
SELECT pg_temp.garde('r_c', pg_temp.valider('a1', '01', 'cle-salle3-c-0001'));
SELECT pg_temp.garde('r_c4', pg_temp.valider('a4', '01', 'cle-salle3-c-0004'));
-- V1-a-bis (20261109100000, directeur, 03/11) : le super-admin de 0088 agit
-- des deux cotes ; il passe la borne de genre et bute, comme la direction de
-- ce cote en (b), sur les controles ; son geste est au journal sensible.
SELECT pg_temp.vrai(pg_temp.lu('r_c') = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.lu('r_c4') ->> 'erreur' = 'controles_non_satisfaits'
  AND pg_temp.trace('01') = pg_temp.lu('t01')
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('01') AND type = 'lecture_hors_portee') = 1
  AND EXISTS (SELECT 1 FROM public.audit_logs a
               WHERE a.action = 'super_admin_hors_cote' AND a.row_id = pg_temp.c('01')::text
                 AND a.actor = pg_temp.p('a4') AND a.payload ->> 'geste' = 'valider_piece'),
  'CAND-Q07 : direction homme hors de son cote : hors_portee trace ; super-admin : passe la borne, controles, journal hors cote ; rien d''autre n''est ecrit');

-- ------------------------------------------------------------
-- (d) Hors de decision_en_attente
-- ------------------------------------------------------------
SELECT pg_temp.garde('t04', pg_temp.trace('04'));
SELECT pg_temp.garde('r_d', pg_temp.valider('a2', '04', 'cle-salle3-d-0001'));
SELECT pg_temp.vrai(pg_temp.lu('r_d') ->> 'erreur' = 'transition_interdite' AND pg_temp.trace('04') = pg_temp.lu('t04'),
  'entretien a planifier : transition_interdite, rien d''ecrit');

-- ------------------------------------------------------------
-- (e) V1-a simule (private.entretien_conclusion) : avis, constat, accord manquant, piece
--     absente
-- ------------------------------------------------------------
-- La fonction que pose V1-a (accord du 03/11 avec Fin de seance), simulee
-- ici : sa conclusion se regle par test.conclusion. OR REPLACE : V1-a peut
-- deja etre installee ; la transaction est annulee a la fin.
CREATE OR REPLACE FUNCTION private.entretien_conclusion(p_candidature uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.current_setting('test.conclusion')::jsonb || pg_catalog.jsonb_build_object('candidature', p_candidature);
$function$;
SELECT pg_temp.garde('conclusion', '{"tenu": true, "avisFavorable": false, "constatComplet": true}'::jsonb);
SELECT pg_temp.garde('t01e', pg_temp.trace('01'));
SELECT pg_temp.garde('r_e0', pg_temp.valider('a2', '01', 'cle-salle3-e-0000'));
SELECT pg_temp.vrai(pg_temp.lu('r_e0') -> 'controles' = '[{"nom": "entretien_conclu", "cause": "avis_non_favorable"}]'::jsonb
  AND pg_temp.trace('01') = pg_temp.lu('t01e'),
  'V1-a present, entretien tenu mais avis non favorable : entretien_conclu nomme (avis_non_favorable), rien d''ecrit');
SELECT pg_temp.garde('conclusion', '{"tenu": true, "avisFavorable": true, "constatComplet": false}'::jsonb);
SELECT pg_temp.garde('r_e00', pg_temp.valider('a2', '01', 'cle-salle3-e-0010'));
SELECT pg_temp.vrai(pg_temp.lu('r_e00') -> 'controles' = '[{"nom": "evaluation_validee", "cause": "constat_incomplet"}]'::jsonb
  AND pg_temp.trace('01') = pg_temp.lu('t01e'),
  'constat incomplet : evaluation_validee nomme (constat_incomplet), rien d''ecrit');
SELECT pg_temp.garde('conclusion', '{"tenu": true, "avisFavorable": true, "constatComplet": true}'::jsonb);

SELECT pg_temp.garde('t02', pg_temp.trace('02'));
SELECT pg_temp.garde('r_e1', pg_temp.valider('a2', '02', 'cle-salle3-e-0001'));
SELECT pg_temp.vrai(pg_temp.lu('r_e1') ->> 'erreur' = 'controles_non_satisfaits'
  AND pg_temp.lu('r_e1') -> 'controles' = '[{"nom": "accords_signes", "cause": "teacher_conduct_code"}]'::jsonb
  AND pg_temp.trace('02') = pg_temp.lu('t02'),
  'code de conduite non signe : accords_signes nomme (teacher_conduct_code), rien d''ecrit');

SELECT pg_temp.garde('t03', pg_temp.trace('03'));
SELECT pg_temp.garde('r_e2', pg_temp.valider('a2', '03', 'cle-salle3-e-0002'));
SELECT pg_temp.vrai(pg_temp.lu('r_e2') ->> 'erreur' = 'controles_non_satisfaits'
  AND pg_temp.lu('r_e2') -> 'controles' = '[{"nom": "piece_validee", "cause": "absente"}]'::jsonb
  AND pg_temp.trace('03') = pg_temp.lu('t03')
  AND (SELECT count(*) FROM public.weekly_availability WHERE profile_id = pg_temp.p('03')) = 0,
  'aucune piece deposee : piece_validee nomme (absente), rien d''ecrit');

-- Version perimee : conflit, rien d'ecrit.
SELECT pg_temp.garde('r_e3', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.valider_piece_candidat(pg_temp.c('01'), 999, 'cle-salle3-e-0003')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_e3') ->> 'erreur' = 'conflit_candidature' AND pg_temp.trace('01') = pg_temp.lu('t01'),
  'version attendue perimee : conflit_candidature, rien d''ecrit');

-- ------------------------------------------------------------
-- (f) Tout en ordre : la candidate entre en salle 3
-- ------------------------------------------------------------
SELECT pg_temp.garde('aff_avant', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.affectation_candidat(pg_temp.c('01'))$$));
SELECT pg_temp.garde('r_f', pg_temp.valider('a2', '01', 'cle-salle3-f-0001'));
SELECT pg_temp.vrai(NOT (pg_temp.lu('r_f') ? 'erreur') AND (pg_temp.lu('r_f') ->> 'rejoue')::boolean IS FALSE,
  'valider la piece : le geste aboutit');
SELECT pg_temp.vrai((SELECT etape = 'confirmee' AND etat IS NULL AND issue = 'en_cours'
                       FROM public.candidatures WHERE id = pg_temp.c('01')),
  'candidature : confirmee (Salle des prets a enseigner, « Bienvenue dans l''equipe » cote candidate)');
SELECT pg_temp.vrai((SELECT status = 'approved' AND verified_by = pg_temp.p('a2') AND verified_at IS NOT NULL
                       FROM public.kyc_documents WHERE profile_id = pg_temp.p('01')),
  'piece : approuvee par la direction qui a fait le geste');
SELECT pg_temp.vrai((SELECT kyc_status = 'approved' AND timezone_iana = 'Asia/Riyadh'
                            AND cardinality(languages) = 2
                       FROM public.teacher_profiles WHERE profile_id = pg_temp.p('01')),
  'profil enseignant : piece approuvee, fuseau Asia/Riyadh et les deux langues d''explication copies');
SELECT pg_temp.vrai((SELECT array_agg(weekday || ':' || hour_local ORDER BY weekday, hour_local)
                       FROM public.weekly_availability WHERE profile_id = pg_temp.p('01'))
                    = ARRAY['1:20', '1:21', '3:22', '3:23']
  AND (SELECT bool_and(timezone_iana = 'Asia/Riyadh') FROM public.weekly_availability
        WHERE profile_id = pg_temp.p('01')),
  'disponibilites : une ligne par heure couverte (lundi 20 et 21 h, mercredi 22 et 23 h), dans le fuseau declare');
SELECT pg_temp.vrai((SELECT account_status::text FROM public.profiles WHERE id = pg_temp.p('01')) = 'active',
  'compte : actif (sous la garde des signatures et le declencheur L1B)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements e
                      WHERE e.candidature_id = pg_temp.c('01') AND e.type = 'transition'
                        AND e.etape_avant = 'verifications' AND e.etape_apres = 'confirmee'
                        AND e.auteur_id = pg_temp.p('a2')
                        AND (e.details ->> 'transition')::int = 14) = 1
  AND (SELECT count(*) FROM public.audit_logs a WHERE a.row_id = pg_temp.c('01')::text) >= 1,
  'journal : une transition 14 de la direction, et sa ligne d''audit');

SELECT pg_temp.garde('t01f', pg_temp.trace('01'));
SELECT pg_temp.garde('r_f2', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.valider_piece_candidat(pg_temp.c('01'), 1, 'cle-salle3-f-0001')$$));
SELECT pg_temp.vrai((pg_temp.lu('r_f2') ->> 'rejoue')::boolean
  AND (pg_temp.lu('r_f2') - 'rejoue') = (pg_temp.lu('r_f') - 'rejoue')
  AND pg_temp.trace('01') = pg_temp.lu('t01f'),
  'cle rejouee : le meme resultat, rien n''est ecrit deux fois');
SELECT pg_temp.garde('r_f3', pg_temp.valider('a2', '01', 'cle-salle3-f-0002'));
SELECT pg_temp.vrai(pg_temp.lu('r_f3') ->> 'erreur' = 'transition_interdite' AND pg_temp.trace('01') = pg_temp.lu('t01f'),
  'deja en salle 3 : une nouvelle cle rend transition_interdite, rien d''ecrit');

-- ------------------------------------------------------------
-- (g) L'affectation
-- ------------------------------------------------------------
SELECT pg_temp.vrai(pg_temp.lu('aff_avant') @> '{"affectable": false, "nombreClasses": 0}'::jsonb
  AND pg_temp.lu('aff_avant') -> 'causes' @> '["pas_en_salle_3", "compte_inactif", "piece_non_validee", "langues_absentes"]'::jsonb,
  'avant la salle 3 : non affectable, causes nommees (pas en salle 3, compte inactif, piece, langues)');
SELECT pg_temp.garde('aff_apres', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.affectation_candidat(pg_temp.c('01'))$$));
SELECT pg_temp.vrai(pg_temp.lu('aff_apres') @> '{"affectable": true, "causes": [], "nombreClasses": 0, "classes": []}'::jsonb,
  'en salle 3 : affectable, pas encore affectee');
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
VALUES ('5a13aaaa-0000-4000-8000-000000000001', pg_temp.p('01'), 'enfant', 5, 'Classe salle 3', 1, 20);
SELECT pg_temp.garde('aff_classe', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.affectation_candidat(pg_temp.c('01'))$$));
SELECT pg_temp.vrai((pg_temp.lu('aff_classe') ->> 'nombreClasses')::int = 1
  AND pg_temp.lu('aff_classe') -> 'classes' -> 0 ->> 'libelle' = 'Classe salle 3',
  'une Classe : « Affectee a 1 classe », sa ligne lue');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.affectation_candidat(pg_temp.c('01'))$$)
                    = '{"erreur": "hors_portee"}'::jsonb,
  'CAND-Q07 : la direction de l''autre cote ne lit pas l''affectation (hors_portee)');
SELECT pg_temp.garde('aff_super', pg_temp.en(pg_temp.p('a4'), 'admin',
  $$SELECT public.affectation_candidat(pg_temp.c('01'))$$));
SELECT pg_temp.vrai((pg_temp.lu('aff_super') ->> 'nombreClasses')::int = 1,
  'super-admin : lit l''affectation de l''autre cote');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.row_id = pg_temp.c('01')::text
                              AND a.action = 'candidature_exception_super_admin'),
  'super-admin : sa lecture hors de son cote est tracee (audit_logs)');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.affectation_candidat(pg_temp.c('05'))$$)
                    = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.en(pg_temp.p('a2'), 'admin',
        $$SELECT public.affectation_candidat('5a13cccc-0000-4000-8000-00000000ffff')$$) = '{"erreur": "absente"}'::jsonb,
  'affectation : candidate de l''autre cote hors portee, candidature inconnue absente');

\o
SELECT 'SALLE3 : tous les controles sont verts' AS verdict;
ROLLBACK;
