-- GESTES-DU-SERVEUR (16/11/2026, migration 20261129740000) : chaque ligne de candidature rend `gestes`, la liste des
-- gestes que la regle (private.candidature_gestes_regles) ET le droit (private.mission_droit) permettent a la session.
-- La liste, le dossier et les voisins la lisent ; l'ecran n'a plus sa propre copie des regles. Scenarios :
--  1 la direction, par etat (en_examen, paiement_non_disponible, entretien_a_planifier, decision_en_attente) ;
--  2 « clore_complement » seulement quand un complement court ;
--  3 la direction de l'autre cote : rien ; 4 un porteur de mission : seulement les gestes COCHES, dans son perimetre ;
--  5 un dossier hors du perimetre (langue) ou de l'autre cote : rien ; 6 une mission retiree : rien ;
--  7 la liste, le dossier et la ligne disent la meme chose ; 8 l'aide est fermee a authenticated et anon.
-- Rouge avant la migration (la cle `gestes` est absente), vert apres. A rejouer sur une base NEUVE (stub_auth puis toutes
-- les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
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
    RAISE EXCEPTION 'GESTES ROUGE : %', p_label;
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

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('6e570000-0000-4000-8000-0000000000' || CASE p_n WHEN 'a1' THEN '01' WHEN 'a2' THEN '02' WHEN 'h1' THEN '11'
    WHEN 'h3' THEN '13' END)::uuid $$;
CREATE FUNCTION pg_temp.d(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('6e57cccc-0000-4000-8000-0000000000' || CASE p_n WHEN 'M1' THEN '01' WHEN 'M2' THEN '02' WHEN 'M3' THEN '03'
    WHEN 'M4' THEN '04' WHEN 'M5' THEN '05' WHEN 'F1' THEN '06' END)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.d(text) TO authenticated, anon;

-- a1 direction homme, a2 direction femme ; h1 porteur homme (controller) ; h3 sans mission (homme).
-- M1 en examen (francais) ; M2 en examen (poular) ; M3 en Salle de verification, entretien a planifier (francais) ;
-- M4 paiement non disponible ; M5 decision en attente ; F1 dossier de femme.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(s), 'gds-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'a2', 'h1', 'h3']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a1'), 'GD-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('a2'), 'GD-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('h1'), 'GD-CTL-0001', 'controller', NULL, 'Porteur', 'Un', 'active', 'male'),
 (pg_temp.u('h3'), 'GD-CTL-0003', 'controller', NULL, 'Sans', 'Mission', 'active', 'male');
INSERT INTO auth.users (id, email) SELECT ('6e570000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'gds-c' || i || '@test.invalid'
  FROM generate_series(1, 6) i;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT ('6e570000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'GD-ENS-000' || i, 'teacher', 'Candidat', 'N' || i,
       'pending_kyc', CASE WHEN i = 6 THEN 'female'::public.gender ELSE 'male'::public.gender END
  FROM generate_series(1, 6) i;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT ('6e570000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'SA', ARRAY[]::text[], 'pending' FROM generate_series(1, 6) i
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, profile_id, type_code, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.d(v.n), ('6e570000-0000-4000-8000-0000000000' || (20 + v.i))::uuid, 'enseignant', v.g::public.gender,
       'Fixture GDS ' || v.n, v.e, v.s, 'en_cours', false, 'lien_public'
  FROM (VALUES ('M1', 1, 'male', 'prequalification', 'en_examen'),
               ('M2', 2, 'male', 'prequalification', 'en_examen'),
               ('M3', 3, 'male', 'verifications', 'entretien_a_planifier'),
               ('M4', 4, 'male', 'prequalification', 'paiement_non_disponible'),
               ('M5', 5, 'male', 'verifications', 'decision_en_attente'),
               ('F1', 6, 'female', 'prequalification', 'en_examen')) v(n, i, g, e, s);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
SELECT pg_temp.d(n), 'salle-examen-2', pg_catalog.jsonb_build_object('languesExplication', l, 'langueMaternelle', 'ar'),
       'candidat', false, pg_catalog.clock_timestamp()
  FROM (VALUES ('M1', '["francais"]'::jsonb), ('M2', '["poular"]'::jsonb), ('M3', '["francais"]'::jsonb),
               ('M4', '["francais"]'::jsonb), ('M5', '["francais"]'::jsonb), ('F1', '["francais"]'::jsonb)) v(n, l);
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
SELECT pg_temp.d(n), lower(n) || '@exemple.invalid', '+33600000000' FROM unnest(ARRAY['M1', 'M2', 'M3', 'M4', 'M5', 'F1']) n;

-- Les gestes d'une ligne, lus par la liste du compte (la porte publique, pas l'aide) : un tableau trie, ou NULL si la
-- ligne n'y est pas ou si la cle est absente.
CREATE FUNCTION pg_temp.liste_gestes(p_qui text, p_role text, p_dossier text) RETURNS text[]
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  v := pg_temp.en(pg_temp.u(p_qui), p_role, pg_catalog.format(
    'SELECT public.lister_candidatures(%L::jsonb, ''recente'', 1)',
    pg_catalog.jsonb_build_object('recherche', 'Fixture GDS ' || p_dossier)::text));
  RETURN (SELECT CASE WHEN l ? 'gestes' THEN ARRAY(SELECT pg_catalog.jsonb_array_elements_text(l -> 'gestes') ORDER BY 1) END
            FROM pg_catalog.jsonb_array_elements(v -> 'lignes') l
           WHERE l ->> 'id' = pg_temp.d(p_dossier)::text);
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.liste_gestes(text, text, text) TO authenticated, anon;

CREATE FUNCTION pg_temp.dossier_gestes(p_qui text, p_role text, p_dossier text) RETURNS text[]
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  v := pg_temp.en(pg_temp.u(p_qui), p_role, pg_catalog.format('SELECT public.lire_candidature(%L::uuid)', pg_temp.d(p_dossier)));
  RETURN CASE WHEN v ? 'erreur' THEN NULL
              WHEN v ? 'gestes' THEN ARRAY(SELECT pg_catalog.jsonb_array_elements_text(v -> 'gestes') ORDER BY 1) END;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.dossier_gestes(text, text, text) TO authenticated, anon;

-- 1 : la direction (homme), par etat. Les gestes sont ceux des regles de l'etat, tous, sans en retirer un par controle.
SELECT pg_temp.garde('m1', to_jsonb(pg_temp.liste_gestes('a1', 'admin', 'M1')));
SELECT pg_temp.vrai(pg_temp.lu('m1') IS NOT NULL AND pg_temp.lu('m1') <> 'null'::jsonb,
  '1 : la ligne de la liste porte la cle gestes (rouge tant que la migration manque)');
SELECT pg_temp.vrai(pg_temp.liste_gestes('a1', 'admin', 'M1') @> ARRAY['demander_complement', 'admettre_verifications',
    'debloquer_versement', 'refuser', 'mettre_en_pause', 'definir_responsable', 'retirer']
  AND NOT (pg_temp.liste_gestes('a1', 'admin', 'M1') && ARRAY['planifier_entretien', 'dispenser_entretien', 'valider_piece',
    'clore_complement', 'lever_pause', 'rouvrir']),
  '1 : en examen, la direction recoit les gestes de la Salle d''examen, ni l''entretien, ni la piece, ni « clore », ni « lever la pause »');
-- Une regle a condition suit la condition du moteur : confirmer ou ecarter un moyen exige un versement a verifier
-- (private.paiement_etat, calcule des moyens declares) ; aucun moyen declare ici, donc ces deux gestes ne sont pas rendus.
SELECT pg_temp.vrai(NOT (pg_temp.liste_gestes('a1', 'admin', 'M1') && ARRAY['confirmer_moyen_paiement', 'infirmer_moyen_paiement']),
  '1 : sans versement a verifier, la condition de la regle retire confirmer et ecarter le moyen');
-- COMPLEMENT-SALLE-EXAMEN (T7, #578) : en « paiement non disponible », la direction peut demander un complement
-- sur le versement (variante 4 de demander_complement) ; l'admission reste fermee.
SELECT pg_temp.vrai(pg_temp.liste_gestes('a1', 'admin', 'M4') @> ARRAY['debloquer_versement', 'refuser', 'mettre_en_pause',
    'demander_complement']
  AND NOT (pg_temp.liste_gestes('a1', 'admin', 'M4') && ARRAY['admettre_verifications', 'annuler_complement']),
  '1 : « paiement non disponible » : debloquer le versement, demander un complement (versement), refuser ; pas d''admission');
SELECT pg_temp.vrai(pg_temp.liste_gestes('a1', 'admin', 'M3') @> ARRAY['planifier_entretien', 'dispenser_entretien',
    'demander_complement', 'refuser']
  AND NOT (pg_temp.liste_gestes('a1', 'admin', 'M3') && ARRAY['admettre_verifications', 'debloquer_versement', 'valider_piece']),
  '1 : entretien a planifier : planifier, dispenser (T10), demander un complement ; ni admission ni deblocage');
SELECT pg_temp.vrai(pg_temp.liste_gestes('a1', 'admin', 'M5') @> ARRAY['valider_piece', 'demander_complement', 'refuser']
  AND NOT (pg_temp.liste_gestes('a1', 'admin', 'M5') && ARRAY['planifier_entretien', 'admettre_verifications']),
  '1 : decision en attente : valider la piece, complement, refuser');

-- 2 : « clore_complement » seulement quand un complement court (T5)
SELECT pg_temp.vrai(NOT ('clore_complement' = ANY (pg_temp.liste_gestes('a1', 'admin', 'M3'))),
  '2 : sans complement en cours, « clore_complement » n''est pas rendu (T5, 50 dossiers aujourd''hui)');
SELECT pg_temp.garde('dem', pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT public.demander_complement_candidat(%L::uuid, ARRAY[''piece_identite''], %L, %s, %L)',
  pg_temp.d('M3'), 'Piece illisible', (SELECT version FROM public.candidatures WHERE id = pg_temp.d('M3')),
  'cle-gds-complement-0001')));
SELECT pg_temp.vrai(NOT (pg_temp.lu('dem') ? 'erreur'),
  '2 : fixture : un complement « piece d''identite » est demande en Salle de verification');
SELECT pg_temp.vrai('clore_complement' = ANY (pg_temp.liste_gestes('a1', 'admin', 'M3'))
  AND 'demander_complement' = ANY (pg_temp.liste_gestes('a1', 'admin', 'M3')),
  '2 : complement en cours : « clore_complement » est rendu, avec demander_complement');
SELECT pg_temp.vrai(NOT ('clore_complement' = ANY (pg_temp.liste_gestes('a1', 'admin', 'M1'))),
  '2 : en Salle d''examen, « clore_complement » n''est jamais rendu (la cloture est celle de la Salle de verification)');

-- 3 : la direction de l'autre cote ne voit rien de ces dossiers ; la porte de lecture est le cote
SELECT pg_temp.vrai(pg_temp.liste_gestes('a2', 'admin', 'M1') IS NULL AND pg_temp.dossier_gestes('a2', 'admin', 'M1') IS NULL,
  '3 : la direction de l''autre cote : le dossier n''est ni dans la liste ni lisible (aucun geste a montrer)');
SELECT pg_temp.vrai(pg_temp.liste_gestes('a2', 'admin', 'F1') @> ARRAY['refuser', 'demander_complement'],
  '3 : la direction femme reste servie sur les dossiers de son cote');

-- 4 : un porteur de mission : seulement les gestes coches, dans son perimetre (francais, cote homme)
SELECT pg_temp.garde('m_ens', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Gestes du serveur', ARRAY['lire', 'definir_responsable', 'demander_complement', 'valider_piece'],
  '6e570000-1111-4000-8000-000000000001'::uuid))$$));
SELECT pg_temp.garde('att', pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT pg_catalog.to_jsonb(public.accorder_mission(%L::uuid, %L::uuid, ''{"langues": ["francais"]}''::jsonb, NULL, NULL, %L::uuid))',
  pg_temp.u('h1'), pg_temp.lu('m_ens') #>> '{}', '6e570000-2222-4000-8000-000000000001')));
SELECT pg_temp.vrai(pg_temp.liste_gestes('h1', 'controller', 'M1') = ARRAY['definir_responsable', 'demander_complement'],
  '4 : le porteur ne recoit sur M1 que les gestes COCHES que la regle de l''etat permet (definir_responsable, demander_complement)');
SELECT pg_temp.vrai(NOT (pg_temp.liste_gestes('h1', 'controller', 'M1') && ARRAY['refuser', 'mettre_en_pause', 'retirer',
    'admettre_verifications', 'debloquer_versement', 'confirmer_moyen_paiement']),
  '4 : aucun geste que la mission ne coche pas (refuser, pause, retirer, admettre, versement)');
SELECT pg_temp.vrai(pg_temp.liste_gestes('h1', 'controller', 'M5') = ARRAY['definir_responsable', 'demander_complement', 'valider_piece'],
  '4 : en decision en attente, le porteur recoit valider_piece parce que sa mission le coche');
SELECT pg_temp.vrai(pg_temp.liste_gestes('h1', 'controller', 'M3') @> ARRAY['demander_complement']
  AND 'clore_complement' = ANY (pg_temp.liste_gestes('h1', 'controller', 'M3')),
  '4 : « clore_complement » suit demander_complement : rendu au porteur quand un complement court et qu''il a ce geste');
SELECT pg_temp.vrai(pg_temp.dossier_gestes('h1', 'controller', 'M1') = ARRAY['definir_responsable', 'demander_complement'],
  '4 : le dossier du porteur dit la meme chose que sa liste');

-- 5 : hors du perimetre : langue (M2 poular), autre cote (F1) : le dossier n'est pas lu, donc aucun geste a montrer ;
--     et l'aide elle-meme, appelee sur la ligne, rend rien
SELECT pg_temp.vrai(pg_temp.liste_gestes('h1', 'controller', 'M2') IS NULL AND pg_temp.dossier_gestes('h1', 'controller', 'M2') IS NULL
  AND pg_temp.liste_gestes('h1', 'controller', 'F1') IS NULL AND pg_temp.dossier_gestes('h1', 'controller', 'F1') IS NULL,
  '5 : dossiers hors langue et de l''autre cote : ni dans la liste ni lisibles');
SELECT pg_temp.qui(pg_temp.u('h1'), 'controller');
SELECT pg_temp.vrai((SELECT private.gestes_de_la_ligne(c) FROM public.candidatures c WHERE c.id = pg_temp.d('M2')) = '[]'::jsonb
  AND (SELECT private.gestes_de_la_ligne(c) FROM public.candidatures c WHERE c.id = pg_temp.d('F1')) = '[]'::jsonb,
  '5 : l''aide rend la liste vide pour un dossier hors du perimetre, meme appelee directement');

-- 5 bis : sans mission, ni direction : rien
SELECT pg_temp.qui(pg_temp.u('h3'), 'controller');
SELECT pg_temp.vrai((SELECT private.gestes_de_la_ligne(c) FROM public.candidatures c WHERE c.id = pg_temp.d('M1')) = '[]'::jsonb,
  '5 bis : un compte sans mission et sans droit de direction : liste vide');

-- 6 : une mission retiree : rien
SELECT pg_temp.garde('retrait', pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT to_jsonb(public.retirer_mission(%L::uuid, ''fin de mission'', %L::uuid))', pg_temp.lu('att') #>> '{}',
  '6e570000-3333-4000-8000-000000000001')));
SELECT pg_temp.qui(pg_temp.u('h1'), 'controller');
SELECT pg_temp.vrai((SELECT private.gestes_de_la_ligne(c) FROM public.candidatures c WHERE c.id = pg_temp.d('M1')) = '[]'::jsonb,
  '6 : mission retiree : liste vide');

-- 7 : la direction n'est pas touchee par les missions ; la ligne est la meme dans la liste et dans le dossier
SELECT pg_temp.vrai(pg_temp.liste_gestes('a1', 'admin', 'M3') = pg_temp.dossier_gestes('a1', 'admin', 'M3')
  AND pg_temp.liste_gestes('a1', 'admin', 'M1') = pg_temp.dossier_gestes('a1', 'admin', 'M1'),
  '7 : pour la direction, la liste et le dossier rendent exactement les memes gestes');

-- 8 : l'aide est fermee
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE'),
  '8 : l''aide n''a aucun EXECUTE pour anon, authenticated, service_role, agent_ro');

\o
SELECT 'GESTES-DU-SERVEUR : tous les controles sont verts' AS resultat;
ROLLBACK;
