-- BE-2a-1 (16/11/2026, migration 20261129420000) : les missions. Une mission donne a une personne qui a deja un compte
-- quelques gestes sur les candidatures, dans un perimetre (cote, langues, etapes, dossiers), pour une duree, retirable,
-- sans toucher a son compte. Scenarios du cahier CAHIER-BE-2A-MISSION.md §3, un refus par cas, avec son code :
--  1 geste non coche ; 2 dossier de l'autre cote ; 3 mission expiree ; 4 mission retiree (liste vide, compte inchange) ;
--  5 mission archivee ; 6 hors langues / hors dossiers confies ; 7 piece d'identite ; 8 contact sans voir_contact ;
--  9 anon et authenticated sans mission ; 10 geste permis (journal avec mission_id, idempotence) ;
-- 11 non-regression de la direction (les scenarios de candidature deja au CI, rejoues a part).
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
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
    RAISE EXCEPTION 'BE2A ROUGE : %', p_label;
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
    RAISE EXCEPTION 'BE2A ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'BE2A ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a130000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5a13cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

CREATE FUNCTION pg_temp.u(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2a0000-0000-4000-8000-0000000000' || CASE p_n WHEN 'a1' THEN '01' WHEN 'a2' THEN '02' WHEN 'h1' THEN '11'
    WHEN 'h2' THEN '12' WHEN 'h3' THEN '13' WHEN 'h4' THEN '14' END)::uuid $$;
CREATE FUNCTION pg_temp.d(p_n text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('5b2acccc-0000-4000-8000-0000000000' || CASE p_n WHEN 'M1' THEN '01' WHEN 'M2' THEN '02' WHEN 'M3' THEN '03'
    WHEN 'M4' THEN '04' WHEN 'F1' THEN '05' END)::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(text), pg_temp.d(text) TO authenticated, anon;

-- Un appel qui rend une erreur jsonb ou une valeur ; le role authenticated, aal2 (la double verification).
-- a1 direction homme, a2 direction femme ; h1 porteur homme (controller), h2 porteuse (femme), h3 sans mission
-- (homme), h4 tuteur ; M1..M4 dossiers d'hommes, F1 dossier de femme.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(s), 'be2a-' || s || '@test.invalid'
  FROM unnest(ARRAY['a1', 'a2', 'h1', 'h2', 'h3', 'h4']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('5b2affff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u('a1'), 'B2-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.u('a2'), 'B2-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.u('h1'), 'B2-CTL-0001', 'controller', NULL, 'Porteur', 'Un', 'active', 'male'),
 (pg_temp.u('h2'), 'B2-CTL-0002', 'controller', NULL, 'Porteuse', 'Deux', 'active', 'female'),
 (pg_temp.u('h3'), 'B2-CTL-0003', 'controller', NULL, 'Sans', 'Mission', 'active', 'male'),
 (pg_temp.u('h4'), 'B2-TUT-0001', 'guardian', '5b2affff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai', 'active', 'female');
INSERT INTO auth.users (id, email) SELECT ('5b2a0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'be2a-c' || i || '@test.invalid'
  FROM generate_series(1, 5) i;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT ('5b2a0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'B2-ENS-000' || i, 'teacher', 'Candidat', 'N' || i,
       'pending_kyc', CASE WHEN i = 5 THEN 'female'::public.gender ELSE 'male'::public.gender END
  FROM generate_series(1, 5) i;
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT ('5b2a0000-0000-4000-8000-0000000000' || (20 + i))::uuid, 'SA', ARRAY[]::text[], 'pending' FROM generate_series(1, 5) i
ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, profile_id, type_code, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.d(n), ('5b2a0000-0000-4000-8000-0000000000' || (20 + (CASE n WHEN 'F1' THEN 5 ELSE right(n, 1)::int END)))::uuid,
       'enseignant', g::public.gender, 'Fixture BE2A ' || n, e,
       CASE e WHEN 'verifications' THEN 'entretien_a_planifier' ELSE 'en_examen' END, 'en_cours', false, 'lien_public'
  FROM (VALUES ('M1', 'male', 'prequalification'), ('M2', 'male', 'prequalification'),
               ('M3', 'male', 'verifications'), ('M4', 'male', 'prequalification'),
               ('F1', 'female', 'prequalification')) v(n, g, e);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
SELECT pg_temp.d(n), 'salle-examen-2', pg_catalog.jsonb_build_object('languesExplication', l, 'langueMaternelle', 'ar'),
       'candidat', false, pg_catalog.clock_timestamp()
  FROM (VALUES ('M1', '["francais"]'::jsonb), ('M2', '["poular"]'::jsonb), ('M3', '["francais"]'::jsonb),
               ('M4', '["francais"]'::jsonb), ('F1', '["francais"]'::jsonb)) v(n, l);
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
SELECT pg_temp.d(n), lower(n) || '@exemple.invalid', '+33600000000' FROM unnest(ARRAY['M1', 'M2', 'M3', 'M4', 'F1']) n;
-- Une direction de l'autre cote ne sert qu'aux scenarios de refus du cote de la direction : a2 est femme.

-- Les mots : une mission « Anglais » avec cinq gestes (cahier §0) ; une seconde sans geste de contact.
SELECT pg_temp.garde('m1', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Candidatures en anglais',
  ARRAY['lire', 'voir_contact', 'definir_responsable', 'demander_complement', 'valider_piece'], '11111111-0000-4000-8000-000000000001'::uuid))$$));
SELECT pg_temp.garde('m2', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT pg_catalog.to_jsonb(public.creer_mission(
  'Lecture seule', ARRAY['lire'], '11111111-0000-4000-8000-000000000002'::uuid))$$));
CREATE FUNCTION pg_temp.mid(p text) RETURNS uuid LANGUAGE sql AS $$ SELECT (pg_temp.lu(p) #>> '{}')::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.mid(text) TO authenticated, anon;

CREATE FUNCTION pg_temp.compte(p_n text) RETURNS text LANGUAGE sql AS $$
  SELECT role::text || '/' || account_status::text || '/' || coalesce(gender::text, '-') FROM public.profiles WHERE id = pg_temp.u(p_n) $$;
SELECT pg_temp.garde('compte_h1', to_jsonb(pg_temp.compte('h1')));

-- Un geste de la direction au nom d'un porteur : definir_responsable (version lue ici).
CREATE FUNCTION pg_temp.geste(p_qui text, p_dossier text, p_cle text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v_version integer;
BEGIN
  SELECT c.version INTO v_version FROM public.candidatures c WHERE c.id = pg_temp.d(p_dossier);
  RETURN pg_temp.en(pg_temp.u(p_qui), (SELECT role::text FROM public.profiles WHERE id = pg_temp.u(p_qui)),
    pg_catalog.format('SELECT public.definir_responsable_candidat(%L::uuid, %L::uuid, %s, %L)', pg_temp.d(p_dossier),
                      pg_temp.u('a1'), v_version, p_cle));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.geste(text, text, text) TO authenticated, anon;
CREATE FUNCTION pg_temp.etat_dossier(p_n text) RETURNS text LANGUAGE sql AS $$
  SELECT md5(to_jsonb(c)::text) FROM public.candidatures c WHERE c.id = pg_temp.d(p_n) $$;
CREATE FUNCTION pg_temp.accorder(p_h text, p_m text, p_perimetre jsonb, p_debut text, p_fin text, p_cle text) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  RETURN pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
    'SELECT pg_catalog.to_jsonb(public.accorder_mission(%L::uuid, %L::uuid, %L::jsonb, %s, %s, %L::uuid))',
    pg_temp.u(p_h), pg_temp.mid(p_m), p_perimetre::text, coalesce(pg_catalog.quote_literal(p_debut) || '::timestamptz', 'NULL'),
    coalesce(pg_catalog.quote_literal(p_fin) || '::timestamptz', 'NULL'), p_cle));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.accorder(text, text, jsonb, text, text, text) TO authenticated, anon;

-- Refus de l'accord par la direction : cote choisi a tort, cote d'une femme pour un homme, cle de liste, cle inconnue.
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.accorder_mission(pg_temp.u('h1'), pg_temp.mid('m1'), '{"cote": "female"}'::jsonb, NULL, NULL,
                                    '22222222-0000-4000-8000-0000000000a1'::uuid)$$,
  '22023', '2 : une mission ne peut pas etre accordee avec un autre cote');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.accorder_mission(pg_temp.u('h1'), pg_temp.mid('m1'), '{"liste": "x"}'::jsonb, NULL, NULL,
                                    '22222222-0000-4000-8000-0000000000a2'::uuid)$$,
  '22023', 'perimetre : la cle « liste » est reservee (vague 3)');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.accorder_mission(pg_temp.u('h1'), pg_temp.mid('m1'), '{"dossiers": ["5b2acccc-0000-4000-8000-000000000005"]}'::jsonb, NULL, NULL,
                                    '22222222-0000-4000-8000-0000000000a3'::uuid)$$,
  '22023', 'perimetre : un dossier de l''autre cote ou inconnu est refuse');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.creer_mission('Hors porte', ARRAY['mettre_en_pause'], '11111111-0000-4000-8000-0000000000ff'::uuid)$$,
  '22023', 'un geste sans porte ouverte aux missions ne se coche pas');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin',
  $$SELECT public.creer_mission('Piece', ARRAY['lire', 'piece_identite'], '11111111-0000-4000-8000-0000000000fe'::uuid)$$,
  '22023', '7 : la piece d''identite n''est pas un geste de mission');
SELECT pg_temp.refus_en(pg_temp.u('h3'), 'controller',
  $$SELECT public.creer_mission('Pirate', ARRAY['lire'], '11111111-0000-4000-8000-0000000000fd'::uuid)$$,
  '42501', 'sans etre la direction : aucune mission ne se cree');

-- L'accord : porteur h1, perimetre francais seulement (M1, M3, M4, hors M2 poular) ; h2 sur la mission lecture.
SELECT pg_temp.garde('att1', pg_temp.accorder('h1', 'm1', '{"langues": ["francais"]}'::jsonb, NULL, NULL,
  '22222222-0000-4000-8000-000000000001'));
SELECT pg_temp.garde('att1_bis', pg_temp.accorder('h1', 'm1', '{"langues": ["francais"]}'::jsonb, NULL, NULL,
  '22222222-0000-4000-8000-000000000001'));
SELECT pg_temp.vrai(pg_temp.lu('att1') = pg_temp.lu('att1_bis')
  AND (SELECT count(*) FROM private.mission_attributions WHERE profile_id = pg_temp.u('h1')) = 1
  AND (SELECT perimetre ->> 'cote' FROM private.mission_attributions WHERE profile_id = pg_temp.u('h1')) = 'male',
  'accord idempotent ; le cote du perimetre est celui de la personne, ecrit par le serveur');
SELECT pg_temp.vrai(pg_temp.compte('h1') = pg_temp.lu('compte_h1') #>> '{}',
  'accorder une mission ne change pas le compte (role, statut, genre)');

-- 10 : geste permis, journal avec mission_id, idempotence
SELECT pg_temp.garde('t_m1', to_jsonb(pg_temp.etat_dossier('M1')));
SELECT pg_temp.garde('g1', pg_temp.geste('h1', 'M1', 'cle-b2a-geste-0001'));
SELECT pg_temp.vrai(NOT (pg_temp.lu('g1') ? 'erreur')
  AND (SELECT responsable_id FROM public.candidatures WHERE id = pg_temp.d('M1')) = pg_temp.u('a1')
  AND (SELECT count(*) FROM private.mission_journal j WHERE j.evenement = 'geste_ouvert'
        AND j.mission_id = pg_temp.mid('m1') AND j.acteur_id = pg_temp.u('h1')
        AND j.payload ->> 'geste' = 'definir_responsable' AND j.payload ->> 'candidature' = pg_temp.d('M1')::text) = 1,
  '10 : geste permis : il aboutit et le journal de mission porte mission_id et le geste');
SELECT pg_temp.garde('g1b', pg_temp.geste('h1', 'M1', 'cle-b2a-geste-0001'));
SELECT pg_temp.vrai((pg_temp.lu('g1b') - 'rejoue') = (pg_temp.lu('g1') - 'rejoue')
  AND (SELECT count(*) FROM private.mission_journal j WHERE j.evenement = 'geste_ouvert' AND j.mission_id = pg_temp.mid('m1')) = 1,
  '10 : la meme cle rejoue le meme resultat, sans seconde ligne de journal');

-- 6 : hors des langues du perimetre
SELECT pg_temp.garde('t_m2', to_jsonb(pg_temp.etat_dossier('M2')));
SELECT pg_temp.garde('g6', pg_temp.geste('h1', 'M2', 'cle-b2a-geste-0006'));
SELECT pg_temp.vrai(pg_temp.lu('g6') ->> 'erreur' = 'hors_mission'
  AND to_jsonb(pg_temp.etat_dossier('M2')) = pg_temp.lu('t_m2')
  AND (SELECT count(*) FROM private.mission_journal WHERE evenement = 'geste_refuse' AND acteur_id = pg_temp.u('h1')) = 1,
  '6 : dossier hors des langues du perimetre : hors_mission, rien d''ecrit, refus au journal');

-- 2 : dossier de l'autre cote
SELECT pg_temp.garde('t_f1', to_jsonb(pg_temp.etat_dossier('F1')));
SELECT pg_temp.garde('g2', pg_temp.geste('h1', 'F1', 'cle-b2a-geste-0002'));
SELECT pg_temp.vrai(pg_temp.lu('g2') = '{"erreur": "hors_portee"}'::jsonb
  AND to_jsonb(pg_temp.etat_dossier('F1')) = pg_temp.lu('t_f1'),
  '2 : dossier de l''autre cote : hors_portee, rien d''ecrit');

-- 1 : un geste que la mission ne coche pas (consigner un retrait)
SELECT pg_temp.garde('g1x', pg_temp.en(pg_temp.u('h1'), 'controller', pg_catalog.format(
  'SELECT public.consigner_retrait_candidat(%L::uuid, ''conversation'', current_date, NULL, %s, %L)', pg_temp.d('M1'),
  (SELECT version FROM public.candidatures WHERE id = pg_temp.d('M1')), 'cle-b2a-geste-0101')));
SELECT pg_temp.vrai(pg_temp.lu('g1x') ->> 'erreur' = 'hors_mission'
  AND (SELECT issue FROM public.candidatures WHERE id = pg_temp.d('M1')) = 'en_cours',
  '1 : un geste non coche dans la mission : hors_mission, le dossier n''a pas bouge');

-- Lecture : liste, dossier, voisins, contact, capacites
SELECT pg_temp.garde('liste', pg_temp.en(pg_temp.u('h1'), 'controller',
  $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$));
SELECT pg_temp.vrai((SELECT array_agg(l ->> 'nomComplet' ORDER BY l ->> 'nomComplet') FROM jsonb_array_elements(pg_temp.lu('liste') -> 'lignes') l)
    = ARRAY['Fixture BE2A M1', 'Fixture BE2A M3', 'Fixture BE2A M4']
  AND (pg_temp.lu('liste') ->> 'total')::int = 3,
  '6 : la liste du porteur ne contient que son perimetre (langue francais, cote homme) ; M2 (poular) et F1 sont absents');
SELECT pg_temp.garde('lire_m2', pg_temp.en(pg_temp.u('h1'), 'controller',
  $$SELECT public.lire_candidature(pg_temp.d('M2'))$$));
SELECT pg_temp.garde('lire_m1', pg_temp.en(pg_temp.u('h1'), 'controller',
  $$SELECT public.lire_candidature(pg_temp.d('M1'))$$));
SELECT pg_temp.vrai(pg_temp.lu('lire_m2') = '{"erreur": "hors_portee"}'::jsonb AND NOT (pg_temp.lu('lire_m1') ? 'erreur')
  AND pg_temp.lu('lire_m1') -> 'piece' = 'null'::jsonb,
  'lire : le dossier du perimetre est lu, celui hors langues est hors_portee ; la piece d''identite n''est jamais dans le dossier');
SELECT pg_temp.garde('contact', pg_temp.en(pg_temp.u('h1'), 'controller',
  $$SELECT public.lire_contact_candidature(pg_temp.d('M1'))$$));
SELECT pg_temp.vrai(pg_temp.lu('contact') ->> 'courriel' = 'm1@exemple.invalid',
  'voir_contact coche : le contact du dossier du perimetre est lu');
SELECT pg_temp.garde('att2', pg_temp.accorder('h2', 'm2', '{}'::jsonb, NULL, NULL, '22222222-0000-4000-8000-000000000002'));
SELECT pg_temp.garde('liste_f', pg_temp.en(pg_temp.u('h2'), 'controller',
  $$SELECT public.lister_candidatures('{"recherche": "f1@exemple.invalid"}'::jsonb, 'recente', 1)$$));
SELECT pg_temp.refus_en(pg_temp.u('h2'), 'controller', $$SELECT public.lire_contact_candidature(pg_temp.d('F1'))$$,
  '42501', '8 : voir le contact sans voir_contact : refuse (42501)');
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('liste_f') -> 'lignes') = 0,
  '8 : la recherche par courriel ne trouve rien sans voir_contact (aucune fuite par la liste)');

SELECT pg_temp.garde('cap1', pg_temp.en(pg_temp.u('h1'), 'controller', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.vrai(pg_temp.lu('cap1') ->> 'peutLire' = 'true' AND pg_temp.lu('cap1') ->> 'peutVoirContact' = 'true'
  AND pg_temp.lu('cap1') -> 'gestes' ->> 'definirResponsable' = 'true'
  AND pg_temp.lu('cap1') -> 'gestes' ->> 'validerPiece' = 'true'
  AND pg_temp.lu('cap1') -> 'gestes' ->> 'refuser' = 'false'
  AND pg_temp.lu('cap1') -> 'gestes' ->> 'rouvrir' = 'false'
  AND pg_temp.lu('cap1') ->> 'peutImporter' = 'false' AND pg_temp.lu('cap1') ->> 'peutLireHorsGenre' = 'false',
  'capacites : le porteur recoit ses gestes cochés, rien d''autre');
SELECT pg_temp.garde('cap3', pg_temp.en(pg_temp.u('h3'), 'controller', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.vrai(pg_temp.lu('cap3') ->> 'peutLire' = 'false' AND pg_temp.lu('cap3') -> 'gestes' ->> 'definirResponsable' = 'false',
  'sans mission : aucune capacite');

-- 7 : la piece d'identite reste reservee a la direction
SELECT pg_temp.refus_en(pg_temp.u('h1'), 'controller', $$SELECT public.piece_dossier_candidat(pg_temp.d('M1'))$$,
  '42501', '7 : lire la piece d''identite avec une mission : refuse (42501)');

-- 9 : droits des portes
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.accorder_mission(uuid,uuid,jsonb,timestamptz,timestamptz,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.creer_mission(text,text[],uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.retirer_mission(uuid,text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.archiver_mission(uuid,text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.lister_missions()', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.accorder_mission(uuid,uuid,jsonb,timestamptz,timestamptz,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.cand_droit(uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.cand_acteur()', 'EXECUTE'),
  '9 : anon sans aucune porte, service_role sans accord, helpers prives fermes');
SELECT pg_temp.refus_en(pg_temp.u('h3'), 'controller', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$,
  '42501', '9 : authenticated sans mission : la liste est refusee (42501)');
SELECT pg_temp.refus_en(pg_temp.u('h3'), 'controller', $$SELECT public.lister_missions()$$,
  '42501', '9 : authenticated sans mission : lister_missions refuse (42501)');
SELECT pg_temp.refus_en(pg_temp.u('h4'), 'guardian', $$SELECT public.lire_candidature(pg_temp.d('M1'))$$,
  '42501', '9 : un tuteur : lire un dossier refuse (42501)');
SELECT pg_temp.refus_en(pg_temp.u('h3'), 'controller', pg_catalog.format(
  'SELECT public.definir_responsable_candidat(%L::uuid, %L::uuid, 1, %L)', pg_temp.d('M1'), pg_temp.u('a1'), 'cle-b2a-geste-0009'),
  '42501', '9 : authenticated sans mission : aucune porte de geste ne s''execute (42501)');

-- 3 : une mission dont la fin est passee (la fin se fixe au proprietaire : l'accord refuse une fin passee)
SELECT pg_temp.garde('att3', pg_temp.accorder('h3', 'm1', '{}'::jsonb, NULL, NULL, '22222222-0000-4000-8000-000000000003'));
UPDATE private.mission_attributions
   SET debut = pg_catalog.clock_timestamp() - interval '2 days', fin = pg_catalog.clock_timestamp() - interval '1 minute'
 WHERE id = (pg_temp.lu('att3') #>> '{}')::uuid;
SELECT pg_temp.refus_en(pg_temp.u('h3'), 'controller', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$,
  '42501', '3 : mission expiree : la lecture est refusee (42501)');
SELECT pg_temp.garde('t_m4', to_jsonb(pg_temp.etat_dossier('M4')));
SELECT pg_temp.refus_en(pg_temp.u('h3'), 'controller', pg_catalog.format(
  'SELECT public.definir_responsable_candidat(%L::uuid, %L::uuid, %s, %L)', pg_temp.d('M4'), pg_temp.u('a1'),
  (SELECT version FROM public.candidatures WHERE id = pg_temp.d('M4')), 'cle-b2a-geste-0003'),
  '42501', '3 : mission expiree : le geste est refuse (42501)');
SELECT pg_temp.vrai(to_jsonb(pg_temp.etat_dossier('M4')) = pg_temp.lu('t_m4'),
  '3 : mission expiree : rien n''est ecrit dans le dossier');

-- 4 : une mission retiree : refus, compte inchange
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT to_jsonb(public.retirer_mission(%L::uuid, ''fin de mission'', ''33333333-0000-4000-8000-000000000001''::uuid))',
  pg_temp.lu('att1') #>> '{}')) = 'true'::jsonb
  AND pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT to_jsonb(public.retirer_mission(%L::uuid, ''fin de mission'', ''33333333-0000-4000-8000-000000000001''::uuid))',
  pg_temp.lu('att1') #>> '{}')) = 'false'::jsonb,
  '4 : le retrait aboutit une fois (vrai), puis rend faux');
SELECT pg_temp.refus_en(pg_temp.u('h1'), 'controller', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$,
  '42501', '4 : mission retiree : la lecture est refusee (42501), la liste est vide');
SELECT pg_temp.refus_en(pg_temp.u('h1'), 'controller', pg_catalog.format(
  'SELECT public.definir_responsable_candidat(%L::uuid, %L::uuid, %s, %L)', pg_temp.d('M4'), pg_temp.u('a1'),
  (SELECT version FROM public.candidatures WHERE id = pg_temp.d('M4')), 'cle-b2a-geste-0004'),
  '42501', '4 : mission retiree : le geste est refuse (42501)');
SELECT pg_temp.vrai(pg_temp.compte('h1') = pg_temp.lu('compte_h1') #>> '{}'
  AND pg_temp.lu('cap1') ->> 'peutLire' = 'true'
  AND pg_temp.en(pg_temp.u('h1'), 'controller', $$SELECT public.capacites_candidatures()$$) ->> 'peutLire' = 'false',
  '4 : mission retiree : plus aucune capacite, et le compte (role, statut, genre) est inchange');
SELECT pg_temp.vrai((SELECT count(*) FROM private.mission_journal WHERE evenement = 'retrait'
                       AND attribution_id = (pg_temp.lu('att1') #>> '{}')::uuid) = 1,
  '4 : le retrait est au journal, une fois');

-- 5 : une mission archivee : refus
SELECT pg_temp.vrai(pg_temp.en(pg_temp.u('a1'), 'admin', pg_catalog.format(
  'SELECT to_jsonb(public.archiver_mission(%L::uuid, ''mission close'', ''44444444-0000-4000-8000-000000000001''::uuid))',
  pg_temp.lu('m2') #>> '{}')) = 'true'::jsonb,
  '5 : la mission « lecture seule » est archivee');
SELECT pg_temp.refus_en(pg_temp.u('h2'), 'controller', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$,
  '42501', '5 : mission archivee : la lecture est refusee (42501)');
SELECT pg_temp.refus_en(pg_temp.u('a1'), 'admin', $$SELECT public.accorder_mission(pg_temp.u('h3'), pg_temp.mid('m2'), '{}'::jsonb, NULL, NULL,
  '22222222-0000-4000-8000-0000000000b1'::uuid)$$, '22023', '5 : on n''accorde pas une mission archivee');

-- La direction n'est pas touchee : sa liste voit tout son cote.
SELECT pg_temp.vrai((pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$) ->> 'total')::int = 4
  AND (pg_temp.en(pg_temp.u('a2'), 'admin', $$SELECT public.lister_candidatures('{}'::jsonb, 'recente', 1)$$) ->> 'total')::int = 1
  AND pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.capacites_candidatures()$$) ->> 'peutLire' = 'true',
  '11 : la direction voit tout son cote (4 dossiers d''hommes, 1 de femme) et garde ses capacites');
SELECT pg_temp.garde('lm', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.lister_missions()$$));
SELECT pg_temp.garde('la', pg_temp.en(pg_temp.u('a1'), 'admin', $$SELECT public.lister_attributions('{"actives": true}'::jsonb)$$));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('lm')) = 2 AND jsonb_array_length(pg_temp.lu('la')) = 0,
  'lister_missions : deux missions ; lister_attributions : aucune attribution active (h1 retiree, h3 expiree, h2 archivee)');

\o
SELECT 'BE-2a : tous les controles sont verts' AS verdict;
ROLLBACK;
