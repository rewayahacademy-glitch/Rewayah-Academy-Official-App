-- PE-LISTE-CANDIDATURES (migration 20261130930000) : tri par anciennete, filtres dossier complet / pile / etiquette de Praxis,
-- « Selectionner les N resultats », lecture de Praxis pour un dossier, gestes groupes admettre / demander un complement / ecrire.
-- Chaque verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue s'il reste un ROUGE.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
-- Donnees fictives seulement.
\o /dev/null
BEGIN;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

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

-- Le code SQL d'un refus, ou 'aucun'.
CREATE FUNCTION pg_temp.code_refus(p_id uuid, p_role text, p_sql text, p_db_role text DEFAULT 'authenticated') RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    EXECUTE 'RESET ROLE';
    RETURN 'aucun';
  EXCEPTION WHEN OTHERS THEN
    RETURN SQLSTATE;
  END;
END $$;

CREATE TEMP TABLE res (nom text PRIMARY KEY, ok boolean NOT NULL, detail text);
GRANT ALL ON res TO authenticated, anon;
CREATE FUNCTION pg_temp.note(p_nom text, p_ok boolean, p_detail text DEFAULT NULL) RETURNS void LANGUAGE sql AS $$
  INSERT INTO res VALUES (p_nom, coalesce(p_ok, false), p_detail)
  ON CONFLICT (nom) DO UPDATE SET ok = EXCLUDED.ok, detail = EXCLUDED.detail $$;
CREATE FUNCTION pg_temp.verif(p_nom text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v boolean;
BEGIN
  BEGIN
    EXECUTE p_sql INTO v;
    PERFORM pg_temp.note(p_nom, v);
  EXCEPTION WHEN OTHERS THEN
    PERFORM pg_temp.note(p_nom, false, SQLSTATE || ' ' || SQLERRM);
  END;
END $$;
CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true) $$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('9e1c0000-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('9e1ccccc-0000-4000-8000-0000000000' || lpad(p_n, 2, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.c(text), pg_temp.lu(text) TO authenticated, anon;

-- La direction : une femme (u2), un homme (u1). Les candidats (fictifs).
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n::text), 'pelc-' || n || '@test.invalid' FROM generate_series(1, 20) n;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('1'), 'PELC-ADM-01', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('2'), 'PELC-ADM-02', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('10'), 'PELC-CAN-10', 'teacher', NULL, 'Fictive', 'Dix', 'pending_kyc', 'female'),
 (pg_temp.u('11'), 'PELC-CAN-11', 'teacher', NULL, 'Fictive', 'Onze', 'pending_kyc', 'female'),
 (pg_temp.u('12'), 'PELC-CAN-12', 'teacher', NULL, 'Fictive', 'Douze', 'pending_kyc', 'female'),
 (pg_temp.u('15'), 'PELC-CAN-15', 'teacher', NULL, 'Fictif', 'Quinze', 'pending_kyc', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.u(n::text), 'SA', ARRAY[]::text[], 'pending' FROM unnest(ARRAY[10, 11, 12, 15]) n;
-- Anciennete (derniere activite) : c4 (20 j) < c1 (10 j) < c3 (5 j) < c2 (1 j). Reception dans un autre ordre.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source, recue_le,
                                 derniere_activite) VALUES
 (pg_temp.c('1'), 'enseignant', pg_temp.u('10'), 'female', 'Fictive Alpha', 'prequalification', 'en_examen', 'en_cours', false,
  'lien_public', now() - interval '2 days', now() - interval '10 days'),
 (pg_temp.c('2'), 'enseignant', pg_temp.u('11'), 'female', 'Fictive Beta', 'prequalification', 'en_examen', 'en_cours', false,
  'lien_public', now() - interval '30 days', now() - interval '1 day'),
 (pg_temp.c('3'), 'enseignant', NULL, 'female', 'Fictive Gamma', 'recue', NULL, 'en_cours', false,
  'lien_public', now() - interval '6 days', now() - interval '5 days'),
 (pg_temp.c('4'), 'enseignant', pg_temp.u('12'), 'female', 'Fictive Delta', 'verifications', 'entretien_a_planifier', 'en_cours', true,
  'lien_public', now() - interval '25 days', now() - interval '20 days'),
 (pg_temp.c('5'), 'enseignant', pg_temp.u('15'), 'male', 'Fictif Epsilon', 'prequalification', 'en_examen', 'en_cours', false,
  'lien_public', now() - interval '40 days', now() - interval '40 days');
-- Praxis a range c1 « pret a decider », c2 « incomplet » et note c1 « pepite », c3 « solide ».
INSERT INTO private.praxis_cles (id, libelle, prefixe, empreinte, usage, emise_par, cle_emission, expire_le)
VALUES ('9e1caaaa-0000-4000-8000-000000000001', 'Cle fictive', 'pxk_', repeat('a', 64), 'routine', pg_temp.u('1'),
        '9e1caaaa-0000-4000-8000-000000000002', now() + interval '10 days');
INSERT INTO private.praxis_rangements (candidature_id, pile, raison, cle_id, emise_par, cle_idempotence) VALUES
 (pg_temp.c('1'), 'pret_a_decider', 'Tout est la.', '9e1caaaa-0000-4000-8000-000000000001', pg_temp.u('1'), gen_random_uuid()),
 (pg_temp.c('2'), 'incomplet', 'Il manque la photo.', '9e1caaaa-0000-4000-8000-000000000001', pg_temp.u('1'), gen_random_uuid()),
 (pg_temp.c('5'), 'pret_a_decider', 'Tout est la.', '9e1caaaa-0000-4000-8000-000000000001', pg_temp.u('1'), gen_random_uuid());
INSERT INTO private.praxis_impressions (candidature_id, etiquette, texte, confiance, vision, cle_id, emise_par, cle_idempotence) VALUES
 (pg_temp.c('1'), 'pepite', 'Impression fictive.', 'forte', 5, '9e1caaaa-0000-4000-8000-000000000001', pg_temp.u('1'), gen_random_uuid()),
 (pg_temp.c('3'), 'solide', 'Impression fictive.', 'moyenne', 3, '9e1caaaa-0000-4000-8000-000000000001', pg_temp.u('1'), gen_random_uuid());

-- Les references, dans l'ordre d'une liste lue par la direction feminine.
CREATE FUNCTION pg_temp.refs(p_filtre text, p_tri text) RETURNS text[] LANGUAGE sql AS $$
  SELECT ARRAY(SELECT l ->> 'id' FROM pg_catalog.jsonb_array_elements(
    pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format('SELECT public.lister_candidatures(%L::jsonb, %L, 1)', p_filtre, p_tri))
      -> 'lignes') l) $$;
CREATE FUNCTION pg_temp.ids(VARIADIC p_n text[]) RETURNS text[] LANGUAGE sql AS $$
  SELECT ARRAY(SELECT pg_temp.c(n)::text FROM unnest(p_n) n) $$;

-- ===== 1. TRI =====
SELECT pg_temp.verif('TRI ancienne : la plus ancienne activite d''abord (c4, c1, c3, c2)', $$
  SELECT pg_temp.refs('{}', 'ancienne') = pg_temp.ids('4', '1', '3', '2') $$);
SELECT pg_temp.verif('TRI activite inchange : la plus recente d''abord (c2, c3, c1, c4)', $$
  SELECT pg_temp.refs('{}', 'activite') = pg_temp.ids('2', '3', '1', '4') $$);
SELECT pg_temp.verif('TRI recente inchange (reception) : c1, c3, c4, c2', $$
  SELECT pg_temp.refs('{}', 'recente') = pg_temp.ids('1', '3', '4', '2') $$);
SELECT pg_temp.verif('TRI inconnu : refuse 22023', $$
  SELECT pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.lister_candidatures('{}'::jsonb, 'au_hasard', 1)$q$) = '22023' $$);
SELECT pg_temp.verif('TRI ancienne : voisins_candidature suit le meme ordre (c1 entre c4 et c3, rang 2 sur 4)', $$
  SELECT v ->> 'precedent' = (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('4'))
     AND v ->> 'suivant' = (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('3'))
     AND (v ->> 'rang')::int = 2 AND (v ->> 'total')::int = 4
    FROM (SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
            'SELECT public.voisins_candidature(%L, ''{}''::jsonb, ''ancienne'')',
            (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('1')))) AS v) x $$);

-- ===== 2. FILTRES =====
SELECT pg_temp.verif('FILTRE pilePraxis pret_a_decider : c1 seulement (c5 est de l''autre cote)', $$
  SELECT pg_temp.refs('{"pilePraxis": "pret_a_decider"}', 'ancienne') = pg_temp.ids('1') $$);
SELECT pg_temp.verif('FILTRE pilePraxis incomplet : c2', $$
  SELECT pg_temp.refs('{"pilePraxis": "incomplet"}', 'ancienne') = pg_temp.ids('2') $$);
SELECT pg_temp.verif('FILTRE etiquettePraxis pepite : c1 ; solide : c3', $$
  SELECT pg_temp.refs('{"etiquettePraxis": "pepite"}', 'ancienne') = pg_temp.ids('1')
     AND pg_temp.refs('{"etiquettePraxis": "solide"}', 'ancienne') = pg_temp.ids('3') $$);
SELECT pg_temp.verif('FILTRE pile et etiquette se combinent avec les autres cles (etape)', $$
  SELECT pg_temp.refs('{"pilePraxis": "pret_a_decider", "etape": "recue"}', 'ancienne') = ARRAY[]::text[]
     AND pg_temp.refs('{"pilePraxis": "pret_a_decider", "etape": "prequalification"}', 'ancienne') = pg_temp.ids('1') $$);
SELECT pg_temp.verif('FILTRE dossierComplet : vrai et faux partagent exactement la liste, selon praxis_dossier_manques', $$
  SELECT pg_temp.refs('{"dossierComplet": true}', 'ancienne') = ARRAY(
           SELECT c.id::text FROM public.candidatures c WHERE c.genre = 'female'
              AND (private.praxis_dossier_manques(c) ->> 'complet')::boolean ORDER BY c.derniere_activite, c.id)
     AND pg_temp.refs('{"dossierComplet": false}', 'ancienne') = ARRAY(
           SELECT c.id::text FROM public.candidatures c WHERE c.genre = 'female'
              AND NOT (private.praxis_dossier_manques(c) ->> 'complet')::boolean ORDER BY c.derniere_activite, c.id)
     AND cardinality(pg_temp.refs('{"dossierComplet": false}', 'ancienne'))
         + cardinality(pg_temp.refs('{"dossierComplet": true}', 'ancienne')) = 4 $$);
SELECT pg_temp.verif('FILTRE dossierComplet : un dossier sans compte (c3) n''est jamais complet', $$
  SELECT pg_temp.c('3')::text = ANY (pg_temp.refs('{"dossierComplet": false}', 'ancienne')) $$);
SELECT pg_temp.verif('FILTRE valeurs mal formees : pile, etiquette inconnues et booleen en texte refuses 22023', $$
  SELECT pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.lister_candidatures('{"pilePraxis": "pepite"}'::jsonb)$q$) = '22023'
     AND pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.lister_candidatures('{"etiquettePraxis": "x"}'::jsonb)$q$) = '22023'
     AND pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.lister_candidatures('{"dossierComplet": "oui"}'::jsonb)$q$) = '22023'
     AND pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.lister_candidatures('{"inventee": 1}'::jsonb)$q$) = '22023' $$);
SELECT pg_temp.verif('FILTRE voisins_candidature connait les cles neuves', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.voisins_candidature(%L, ''{"pilePraxis": "incomplet"}''::jsonb, ''ancienne'')',
           (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('2')))) ->> 'total' = '1' $$);

-- ===== 3. SELECTION DE TOUS LES RESULTATS =====
SELECT pg_temp.verif('SELECTION : le nombre exact et les ids, dans l''ordre de la liste', $$
  SELECT (s ->> 'total')::int = 4 AND (s ->> 'plafond')::int = 1000
     AND ARRAY(SELECT jsonb_array_elements_text(s -> 'ids')) = pg_temp.ids('4', '1', '3', '2')
    FROM (SELECT pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.selection_resultats_file('{}'::jsonb, 'ancienne')$q$) s) x $$);
SELECT pg_temp.verif('SELECTION : meme filtre que la liste (pile incomplet : c2 ; en pause : c4)', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.selection_resultats_file('{"pilePraxis": "incomplet"}'::jsonb, 'activite')$q$)
           -> 'ids' = to_jsonb(pg_temp.ids('2'))
     AND pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.selection_resultats_file('{"enPause": true}'::jsonb)$q$) ->> 'total' = '1' $$);
SELECT pg_temp.verif('SELECTION : la portee de genre (l''homme ne voit que c5)', $$
  SELECT pg_temp.en(pg_temp.u('1'), 'admin', $q$SELECT public.selection_resultats_file('{}'::jsonb)$q$) -> 'ids' = to_jsonb(pg_temp.ids('5')) $$);
SELECT pg_temp.verif('SELECTION : refus 42501 pour un compte qui n''est pas la direction, et pour anon', $$
  SELECT pg_temp.code_refus(pg_temp.u('10'), 'teacher', $q$SELECT public.selection_resultats_file()$q$) = '42501'
     AND pg_temp.code_refus(NULL, NULL, $q$SELECT public.selection_resultats_file()$q$, 'anon') = '42501' $$);
SELECT pg_temp.verif('SELECTION : filtre et tri invalides refuses 22023', $$
  SELECT pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.selection_resultats_file('{"x": 1}'::jsonb)$q$) = '22023'
     AND pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.selection_resultats_file('{}'::jsonb, 'x')$q$) = '22023' $$);
SELECT pg_temp.verif('SELECTION : journalisee (candidatures_selection)', $$
  SELECT EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'candidatures_selection' AND a.actor = pg_temp.u('2')) $$);

-- ===== 4. LECTURE DE PRAXIS POUR UN DOSSIER =====
SELECT pg_temp.verif('PRAXIS dossier : rangement et impression de c1', $$
  SELECT d -> 'rangement' ->> 'pile' = 'pret_a_decider' AND d -> 'impression' ->> 'etiquette' = 'pepite'
     AND (d -> 'impression' -> 'notes' ->> 'vision')::int = 5
    FROM (SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format('SELECT public.direction_praxis_du_dossier(%L)',
            lower((SELECT reference FROM public.candidatures WHERE id = pg_temp.c('1'))))) d) x $$);
SELECT pg_temp.verif('PRAXIS dossier : l''autre cote rend la meme reponse vide qu''un dossier inconnu', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format('SELECT public.direction_praxis_du_dossier(%L)',
           (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('5'))))
         = '{"rangement": null, "impression": null}'::jsonb
     AND pg_temp.en(pg_temp.u('2'), 'admin', $q$SELECT public.direction_praxis_du_dossier('CAND-99999999999')$q$)
         = '{"rangement": null, "impression": null}'::jsonb $$);
SELECT pg_temp.verif('PRAXIS dossier : refus 42501 (enseignant, anon) et 22023 (reference vide)', $$
  SELECT pg_temp.code_refus(pg_temp.u('10'), 'teacher', $q$SELECT public.direction_praxis_du_dossier('CAND-1')$q$) = '42501'
     AND pg_temp.code_refus(NULL, NULL, $q$SELECT public.direction_praxis_du_dossier('CAND-1')$q$, 'anon') = '42501'
     AND pg_temp.code_refus(pg_temp.u('2'), 'admin', $q$SELECT public.direction_praxis_du_dossier('  ')$q$) = '22023' $$);

-- ===== 5. GESTES GROUPES =====
-- Admettre : l'apercu exclut, avec leur raison, les dossiers dont un controle d'admission est faux (la fixture n'a ni versement
-- compatible ni cadre accepte) ; c3 (recue) et c4 (en pause) sont exclus par la regle.
SELECT pg_temp.garde('ap_adm', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.apercu_lot_candidats(''admettre'', %L::uuid[])', pg_temp.ids('1', '2', '3', '4'))));
SELECT pg_temp.verif('ADMETTRE apercu : geste admettre_verifications, zero eligible, quatre exclus avec leur raison', $$
  SELECT a ->> 'geste' = 'admettre_verifications' AND (a ->> 'nombre')::int = 0
     AND jsonb_array_length(a -> 'eligibles') = 0 AND jsonb_array_length(a -> 'exclus') = 4
     AND (SELECT count(*) FROM jsonb_array_elements(a -> 'exclus') e WHERE e ->> 'raison' = 'controles_non_satisfaits'
             AND e ->> 'detail' IS NOT NULL) = 2
     AND (SELECT count(*) FROM jsonb_array_elements(a -> 'exclus') e WHERE e ->> 'raison' = 'transition_interdite') = 2
     AND a ->> 'jeton' ~ '^[0-9a-f]{32}$'
    FROM (SELECT pg_temp.lu('ap_adm') a) x $$);
SELECT pg_temp.verif('ADMETTRE execution : aucun eligible, rien n''est ecrit', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''admettre'', %L::uuid[], %L, 0, ''pelc-cle-adm-0001'')',
           pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_adm') ->> 'jeton')) ->> 'erreur' = 'aucun_eligible'
     AND (SELECT count(*) FROM public.candidatures WHERE etape = 'verifications' AND genre = 'female') = 1 $$);
SELECT pg_temp.verif('ADMETTRE execution : un modele est refuse 22023', $$
  SELECT pg_temp.code_refus(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''admettre'', %L::uuid[], %L, 0, ''pelc-cle-adm-0002'', NULL, ''un_modele'')',
           pg_temp.ids('1'), repeat('0', 32))) = '22023' $$);

-- Demander un complement : c1 et c2 (en examen) ; c3 et c4 exclus.
SELECT pg_temp.garde('ap_cpl', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.apercu_lot_candidats(''demanderComplement'', %L::uuid[])', pg_temp.ids('1', '2', '3', '4'))));
SELECT pg_temp.verif('COMPLEMENT apercu : deux eligibles, deux exclus, motif requis', $$
  SELECT a ->> 'geste' = 'demander_complement' AND (a ->> 'nombre')::int = 2 AND a ->> 'motifRequis' = 'true'
     AND jsonb_array_length(a -> 'exclus') = 2
    FROM (SELECT pg_temp.lu('ap_cpl') a) x $$);
SELECT pg_temp.verif('COMPLEMENT execution : sans motif, motif_requis ; sans element, elements_requis ; rien n''est ecrit', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''demanderComplement'', %L::uuid[], %L, 2, ''pelc-cle-cpl-0001'', NULL, ''photo'')',
           pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_cpl') ->> 'jeton')) ->> 'erreur' = 'motif_requis'
     AND pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''demanderComplement'', %L::uuid[], %L, 2, ''pelc-cle-cpl-0002'', ''Merci.'')',
           pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_cpl') ->> 'jeton')) ->> 'erreur' = 'elements_requis'
     AND (SELECT count(*) FROM public.candidatures WHERE etat = 'a_completer') = 0 $$);
SELECT pg_temp.garde('ex_cpl', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.executer_lot_candidats(''demanderComplement'', %L::uuid[], %L, 2, ''pelc-cle-cpl-0003'', ''Merci d''''ajouter votre photo.'', ''photo'')',
  pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_cpl') ->> 'jeton')));
SELECT pg_temp.verif('COMPLEMENT execution : deux reussies, deux exclues ; c1 et c2 passent a completer', $$
  SELECT (r ->> 'reussies')::int = 2 AND (r ->> 'exclues')::int = 2 AND (r ->> 'refusees')::int = 0
     AND r ->> 'rejoue' = 'false'
     AND (SELECT count(*) FROM public.candidatures WHERE id IN (pg_temp.c('1'), pg_temp.c('2')) AND etat = 'a_completer') = 2
     AND EXISTS (SELECT 1 FROM private.candidature_lots_suite l WHERE l.cle = 'pelc-cle-cpl-0003' AND l.geste = 'demander_complement')
     AND NOT EXISTS (SELECT 1 FROM public.candidature_lots l WHERE l.cle = 'pelc-cle-cpl-0003')
    FROM (SELECT pg_temp.lu('ex_cpl') r) x $$);
SELECT pg_temp.garde('rj_cpl', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.executer_lot_candidats(''demanderComplement'', %L::uuid[], %L, 2, ''pelc-cle-cpl-0003'', ''Merci d''''ajouter votre photo.'', ''photo'')',
  pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_cpl') ->> 'jeton')));
SELECT pg_temp.verif('COMPLEMENT rejeu : la meme cle rend le premier rapport, rien n''est fait deux fois', $$
  SELECT pg_temp.lu('rj_cpl') ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('1')
             AND e.etat_apres = 'a_completer') = 1 $$);
SELECT pg_temp.verif('COMPLEMENT : la cle d''un lot d''un autre geste est refusee (cle_idempotence_reutilisee)', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''refuser'', %L::uuid[], %L, 1, ''pelc-cle-cpl-0003'', ''x'', ''refus_general'')',
           pg_temp.ids('2'), repeat('0', 32))) ->> 'erreur' = 'cle_idempotence_reutilisee' $$);

-- Ecrire : c1, c2 (compte, en cours) ; c3 sans compte ; c4 en pause.
SELECT pg_temp.garde('ap_ecr', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.apercu_lot_candidats(''ecrire'', %L::uuid[])', pg_temp.ids('1', '2', '3', '4'))));
SELECT pg_temp.verif('ECRIRE apercu : deux eligibles ; sans compte et en pause exclus, en le disant', $$
  SELECT a ->> 'geste' = 'ecrire' AND (a ->> 'nombre')::int = 2 AND a ->> 'motifRequis' = 'true'
     AND (SELECT array_agg(e ->> 'detail' ORDER BY e ->> 'detail') FROM jsonb_array_elements(a -> 'exclus') e
           WHERE e ->> 'raison' = 'sans_conversation') = ARRAY['pause', 'sans_compte']
    FROM (SELECT pg_temp.lu('ap_ecr') a) x $$);
SELECT pg_temp.verif('ECRIRE : un jeton d''un autre geste est perime', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''ecrire'', %L::uuid[], %L, 2, ''pelc-cle-ecr-0001'', ''Bonjour.'')',
           pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_cpl') ->> 'jeton')) ->> 'erreur' = 'jeton_perime' $$);
SELECT pg_temp.garde('ex_ecr', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.executer_lot_candidats(''ecrire'', %L::uuid[], %L, 2, ''pelc-cle-ecr-0002'', ''Bonjour, message fictif de la direction.'')',
  pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_ecr') ->> 'jeton')));
SELECT pg_temp.verif('ECRIRE execution : deux messages, un par conversation de candidature', $$
  SELECT (r ->> 'reussies')::int = 2 AND (r ->> 'exclues')::int = 2
     AND (SELECT count(*) FROM public.com_messages m JOIN public.com_fils f ON f.id = m.fil_id
           WHERE f.type_objet = 'candidature' AND f.objet_id IN (pg_temp.c('1'), pg_temp.c('2'))
             AND m.texte = 'Bonjour, message fictif de la direction.' AND m.auteur_id = pg_temp.u('2')) = 2
    FROM (SELECT pg_temp.lu('ex_ecr') r) x $$);
SELECT pg_temp.garde('rj_ecr', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.executer_lot_candidats(''ecrire'', %L::uuid[], %L, 2, ''pelc-cle-ecr-0002'', ''Bonjour, message fictif de la direction.'')',
  pg_temp.ids('1', '2', '3', '4'), pg_temp.lu('ap_ecr') ->> 'jeton')));
SELECT pg_temp.verif('ECRIRE rejeu : rejoue, aucun message en plus', $$
  SELECT pg_temp.lu('rj_ecr') ->> 'rejoue' = 'true'
     AND (SELECT count(*) FROM public.com_messages m WHERE m.texte = 'Bonjour, message fictif de la direction.') = 2 $$);
SELECT pg_temp.verif('ECRIRE : sans message, motif_requis', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.executer_lot_candidats(''ecrire'', %L::uuid[], %L, 2, ''pelc-cle-ecr-0003'', ''   '')',
           pg_temp.ids('1', '2'), repeat('0', 32))) ->> 'erreur' = 'motif_requis' $$);
SELECT pg_temp.verif('LOT : de l''autre cote, c5 est hors portee dans l''apercu', $$
  SELECT (SELECT e ->> 'raison' FROM jsonb_array_elements(pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
            'SELECT public.apercu_lot_candidats(''ecrire'', %L::uuid[])', pg_temp.ids('5'))) -> 'exclus') e) = 'hors_portee' $$);
SELECT pg_temp.verif('LOT : un enseignant ne fait pas de lot (42501)', $$
  SELECT pg_temp.code_refus(pg_temp.u('10'), 'teacher', pg_catalog.format(
           'SELECT public.apercu_lot_candidats(''ecrire'', %L::uuid[])', pg_temp.ids('1'))) = '42501' $$);
SELECT pg_temp.verif('LOT : un geste inconnu reste non groupable', $$
  SELECT pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
           'SELECT public.apercu_lot_candidats(''inviter'', %L::uuid[])', pg_temp.ids('1'))) ->> 'erreur' = 'geste_non_groupable' $$);

-- Les gestes d'avant ne changent pas : une pause en lot passe par la table publique.
SELECT pg_temp.garde('ap_pause', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.apercu_lot_candidats(''mettreEnPause'', %L::uuid[])', pg_temp.ids('3'))));
SELECT pg_temp.garde('ex_pause', pg_temp.en(pg_temp.u('2'), 'admin', pg_catalog.format(
  'SELECT public.executer_lot_candidats(''mettreEnPause'', %L::uuid[], %L, 1, ''pelc-cle-pse-0001'', ''Motif interne.'', %L)',
  pg_temp.ids('3'), pg_temp.lu('ap_pause') ->> 'jeton',
  (SELECT m.code FROM private.candidature_modeles_message m WHERE m.usage = 'pause' AND m.actif ORDER BY m.code LIMIT 1))));
SELECT pg_temp.verif('AVANT : la pause en lot marche comme avant et ecrit dans public.candidature_lots', $$
  SELECT (pg_temp.lu('ex_pause') ->> 'reussies')::int = 1
     AND EXISTS (SELECT 1 FROM public.candidature_lots l WHERE l.cle = 'pelc-cle-pse-0001' AND l.geste = 'mettre_en_pause')
     AND NOT EXISTS (SELECT 1 FROM private.candidature_lots_suite l WHERE l.cle = 'pelc-cle-pse-0001') $$);

-- ===== 6. DROITS =====
SELECT pg_temp.verif('DROITS : fonctions publiques neuves pour authenticated seulement', $$
  SELECT bool_and(has_function_privilege('authenticated', f, 'EXECUTE') AND NOT has_function_privilege('anon', f, 'EXECUTE')
                  AND NOT has_function_privilege('agent_ro', f, 'EXECUTE'))
    FROM unnest(ARRAY['public.selection_resultats_file(jsonb,text)', 'public.direction_praxis_du_dossier(text)']) f $$);
SELECT pg_temp.verif('DROITS : aides privees fermees, table des rapports fermee avec RLS', $$
  SELECT bool_and(NOT has_function_privilege('authenticated', f, 'EXECUTE') AND NOT has_function_privilege('service_role', f, 'EXECUTE'))
     AND NOT has_table_privilege('authenticated', 'private.candidature_lots_suite', 'SELECT')
     AND NOT has_table_privilege('service_role', 'private.candidature_lots_suite', 'INSERT')
     AND (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.candidature_lots_suite'::regclass)
    FROM unnest(ARRAY['private.pelc_filtre_valider(jsonb)', 'private.pelc_predicat(public.candidatures,jsonb)',
                      'private.pelc_lot_examiner(text,uuid[],uuid,public.gender)', 'private.pelc_ecrire_un(uuid,text,text)',
                      'private.pelc_geste_de_lot(uuid,text,uuid,integer,text,text,text,date,jsonb)']) f $$);

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 110) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN
    RAISE EXCEPTION 'PE-LISTE-CANDIDATURES : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok);
  END IF;
END $$;
ROLLBACK;
