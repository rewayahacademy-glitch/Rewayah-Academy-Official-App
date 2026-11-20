-- PE-B1 (migration 20261130920000_juz_nombre_exact.sql, 20/11/2026) : le nombre exact de juz memorises.
-- Ce que le scenario prouve :
--   (a) le candidat ENREGISTRE « juz_12 » par la vraie porte (enregistrer_reponses_salle_examen) : brouillon complet, rien d'invalide ;
--       « juz_0 », « juz_30 », « juz_01 » sont refuses comme valeurs hors liste ; « moins_10_juz » (ancien code) reste accepte ;
--   (b) chaque lecture relit « juz_12 » sans perte ni echec : questionnaire_salle_examen() (brouillon et options), etat_dossier()
--       (rien ne manque), private.candidature_questionnaire_envoye (complet), lire_candidature (dossier de la direction),
--       lister_candidatures (liste de la direction, sans filtre et avec le filtre riwaya : le candidat n'en disparait pas),
--       voisins_candidature, private.praxis_reponses (ce que lit praxis_dossier) ;
--   (c) une ANCIENNE reponse (« moins_10_juz ») envoyee avant ce lot se relit telle quelle, complete, par les memes lectures ;
--   (d) les riwayat « les sept » (14 codes) et « toutes » (20 codes) sont acceptees telles quelles (aucun changement de format).
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated', 'aal', p_aal,
             'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PE-B1 ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$ SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true) $$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb $$;

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

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1b10000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1b1cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pg_temp TO authenticated;

-- Un document de reponses complet, avec la memorisation et les riwayat donnees.
CREATE FUNCTION pg_temp.doc(p_memo text, p_riwayat jsonb) RETURNS jsonb
LANGUAGE sql IMMUTABLE AS $$
  SELECT jsonb_build_object(
    'langueMaternelle', 'ar', 'languesExplication', '["francais"]'::jsonb,
    'niveauMemorisationDeclare', p_memo, 'niveauLectureTajwid', 'tajwid_enseigne',
    'riwayat', p_riwayat, 'ijazaPresentable', 'oui', 'experienceDebutants', 'oui',
    'disponibilitesDeclarees', '[{"jour": 1, "debut": "18:00", "fin": "20:00"}]'::jsonb,
    'fuseauIana', 'Africa/Casablanca', 'classesSouhaitees', '1', 'debutPossible', 'immediat',
    'publics', '["adultes"]'::jsonb, 'paysResidence', 'MA', 'paysVersement', 'MA', 'compteBancaire', true,
    'operateurs', '[]'::jsonb) $$;

-- Fixtures (donnees inventees) : a1 direction homme ; 01 le candidat qui ecrit juz_12 ; 02 une ancienne reponse moins_10_juz,
-- envoyee ; 03 envoye avec juz_12 (comme apres un envoi reel).
INSERT INTO auth.users (id, email) SELECT pg_temp.p(s), 'pe-b1-' || s || '@test.invalid' FROM unnest(ARRAY['a1', '01', '02', '03']) s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 (pg_temp.p('a1'), 'PEB1-ADM-0001', 'admin', 'Direction', 'Essai', 'active', 'male'),
 (pg_temp.p('01'), 'PEB1-ENS-0001', 'teacher', 'Essai', 'Un', 'pending_kyc', 'male'),
 (pg_temp.p('02'), 'PEB1-ENS-0002', 'teacher', 'Essai', 'Deux', 'pending_kyc', 'male'),
 (pg_temp.p('03'), 'PEB1-ENS-0003', 'teacher', 'Essai', 'Trois', 'pending_kyc', 'male');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status)
SELECT pg_temp.p(s), 'MA', ARRAY['francais'], 'pending' FROM unnest(ARRAY['01', '02', '03']) s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
SELECT pg_temp.c(s), 'enseignant', pg_temp.p(s), 'male', 'Fixture PEB1 ' || s, 'prequalification',
       CASE WHEN s = '01' THEN 'a_completer' ELSE 'en_examen' END, 'en_cours', false, 'lien_public'
  FROM unnest(ARRAY['01', '02', '03']) s;
UPDATE public.candidatures SET majorite_declaree = true, majorite_attestee_le = now() WHERE id IN (pg_temp.c('01'), pg_temp.c('02'), pg_temp.c('03'));
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le) VALUES
 (pg_temp.c('02'), 'salle-examen-2', pg_temp.doc('moins_10_juz', '["hafs"]') || '{"accordRemuneration": true}', 'candidat', false, clock_timestamp()),
 (pg_temp.c('03'), 'salle-examen-2', pg_temp.doc('juz_12', '["hafs", "warsh"]') || '{"accordRemuneration": true}', 'candidat', false, clock_timestamp());

-- ===== (a) ecrire par la vraie porte =====
SELECT pg_temp.garde('b1', pg_temp.en(pg_temp.p('01'), 'teacher', format(
  'SELECT public.enregistrer_reponses_salle_examen(%L, %L::jsonb, 0, %L)', 'salle-examen-2', pg_temp.doc('juz_12', '["hafs"]'), 'cle-peb1-01')));
SELECT pg_temp.vrai(pg_temp.lu('b1') ->> 'complet' = 'true' AND NOT pg_temp.lu('b1') ? 'erreur'
  AND (SELECT r.reponses ->> 'niveauMemorisationDeclare' FROM public.candidature_reponses r
        WHERE r.candidature_id = pg_temp.c('01') AND r.brouillon) = 'juz_12',
  'enregistrer : juz_12 est accepte, le brouillon est complet et garde juz_12');
SELECT pg_temp.vrai((SELECT bool_and(pg_temp.en(pg_temp.p('01'), 'teacher', format(
         'SELECT public.enregistrer_reponses_salle_examen(%L, %L::jsonb, 1, %L)', 'salle-examen-2', pg_temp.doc(v, '["hafs"]'), 'cle-peb1-x-' || v))
         = '{"champs": ["niveauMemorisationDeclare"], "erreur": "reponses_invalides"}'::jsonb)
       FROM unnest(ARRAY['juz_0', 'juz_30', 'juz_01']) v)
  AND (SELECT r.reponses ->> 'niveauMemorisationDeclare' FROM public.candidature_reponses r
        WHERE r.candidature_id = pg_temp.c('01') AND r.brouillon) = 'juz_12',
  'enregistrer : juz_0, juz_30 et juz_01 sont refuses (reponses_invalides, sur ce seul champ), le brouillon garde juz_12');
SELECT pg_temp.garde('b2', pg_temp.en(pg_temp.p('01'), 'teacher', format(
  'SELECT public.enregistrer_reponses_salle_examen(%L, %L::jsonb, 1, %L)', 'salle-examen-2', pg_temp.doc('moins_10_juz', '["hafs"]'), 'cle-peb1-02')));
SELECT pg_temp.vrai(pg_temp.lu('b2') ->> 'complet' = 'true' AND NOT pg_temp.lu('b2') ? 'erreur',
  'enregistrer : l''ancien code moins_10_juz reste accepte');
SELECT pg_temp.garde('b3', pg_temp.en(pg_temp.p('01'), 'teacher', format(
  'SELECT public.enregistrer_reponses_salle_examen(%L, %L::jsonb, 2, %L)', 'salle-examen-2',
  pg_temp.doc('juz_12', '["qalun", "warsh", "al_bazzi", "qunbul", "ad_duri_abi_amr", "as_susi", "hisham", "ibn_dhakwan", "shuba", "hafs", "khalaf_an_hamza", "khallad", "abu_al_harith", "ad_duri_al_kisai"]'),
  'cle-peb1-03')));
SELECT pg_temp.vrai(pg_temp.lu('b3') ->> 'complet' = 'true' AND NOT pg_temp.lu('b3') ? 'erreur',
  'riwayat « les sept » : les 14 codes des sept lecteurs sont acceptes tels quels');
SELECT pg_temp.garde('b4', pg_temp.en(pg_temp.p('01'), 'teacher', format(
  'SELECT public.enregistrer_reponses_salle_examen(%L, %L::jsonb, 3, %L)', 'salle-examen-2',
  pg_temp.doc('juz_12', '["hafs", "shuba", "warsh", "qalun", "al_bazzi", "qunbul", "ad_duri_abi_amr", "as_susi", "hisham", "ibn_dhakwan", "khalaf_an_hamza", "khallad", "abu_al_harith", "ad_duri_al_kisai", "ibn_wardan", "ibn_jammaz", "ruways", "rawh", "ishaq", "idris"]'),
  'cle-peb1-04')));
SELECT pg_temp.vrai(pg_temp.lu('b4') ->> 'complet' = 'true' AND NOT pg_temp.lu('b4') ? 'erreur',
  'riwayat « toutes » : les 20 codes sont acceptes tels quels');

-- ===== (b) chaque lecture relit juz_12 =====
SELECT pg_temp.garde('q1', pg_temp.en(pg_temp.p('01'), 'teacher', 'SELECT public.questionnaire_salle_examen()'));
SELECT pg_temp.vrai(pg_temp.lu('q1')::text ~ '"niveauMemorisationDeclare": "juz_12"'
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('q1') -> 'champs') c
               WHERE c ->> 'code' = 'niveauMemorisationDeclare'
                 AND (c -> 'options') @> '["juz_12", "juz_1", "juz_29", "moins_10_juz", "coran_entier"]'
                 AND NOT (c -> 'options') @> '["juz_30"]'),
  'questionnaire_salle_examen : le brouillon rend juz_12, et les options portent juz_1 a juz_29 avec les anciens codes');
SELECT pg_temp.garde('e3', pg_temp.en(pg_temp.p('03'), 'teacher', 'SELECT public.etat_dossier()'));
SELECT pg_temp.vrai(NOT coalesce(pg_temp.lu('e3')::text ~ 'niveauMemorisationDeclare', false)
  AND (SELECT private.candidature_questionnaire_envoye(c) FROM public.candidatures c WHERE c.id = pg_temp.c('03')) = 'complet',
  'etat_dossier et questionnaire envoye : juz_12 ne manque pas, le questionnaire est complet');
SELECT pg_temp.garde('d3', pg_temp.en(pg_temp.p('a1'), 'admin', format('SELECT public.lire_candidature(%L::uuid)', pg_temp.c('03'))));
SELECT pg_temp.vrai(pg_temp.lu('d3')::text ~ '"niveauMemorisationDeclare": "juz_12"' AND NOT pg_temp.lu('d3') ? 'erreur',
  'lire_candidature (dossier de la direction) : juz_12 se relit');
SELECT pg_temp.garde('l0', pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.lister_candidatures(''{}''::jsonb, ''activite'', 1)'));
SELECT pg_temp.garde('lr', pg_temp.en(pg_temp.p('a1'), 'admin', 'SELECT public.lister_candidatures(''{"riwaya": "warsh"}''::jsonb, ''activite'', 1)'));
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l0') -> 'lignes') l WHERE l ->> 'id' = pg_temp.c('03')::text)
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('lr') -> 'lignes') l WHERE l ->> 'id' = pg_temp.c('03')::text)
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l0') -> 'lignes') l WHERE l ->> 'id' = pg_temp.c('02')::text),
  'lister_candidatures : le candidat juz_12 est dans la liste, sans filtre et avec le filtre riwaya ; l''ancien aussi');
SELECT pg_temp.garde('v3', pg_temp.en(pg_temp.p('a1'), 'admin', format(
  'SELECT public.voisins_candidature(%L, ''{}''::jsonb, ''activite'')', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('03')))));
SELECT pg_temp.vrai(NOT coalesce(pg_temp.lu('v3') ? 'erreur', false), 'voisins_candidature : aucune erreur sur un dossier juz_12');
SELECT pg_temp.vrai(private.praxis_reponses(pg_temp.c('03')) ->> 'niveauMemorisationDeclare' = 'juz_12',
  'praxis_reponses (lu par praxis_dossier) : juz_12 se relit tel quel');

-- ===== (c) l'ancienne reponse =====
SELECT pg_temp.garde('e2', pg_temp.en(pg_temp.p('02'), 'teacher', 'SELECT public.etat_dossier()'));
SELECT pg_temp.garde('d2', pg_temp.en(pg_temp.p('a1'), 'admin', format('SELECT public.lire_candidature(%L::uuid)', pg_temp.c('02'))));
SELECT pg_temp.vrai(NOT coalesce(pg_temp.lu('e2')::text ~ 'niveauMemorisationDeclare', false)
  AND (SELECT private.candidature_questionnaire_envoye(c) FROM public.candidatures c WHERE c.id = pg_temp.c('02')) = 'complet'
  AND pg_temp.lu('d2')::text ~ '"niveauMemorisationDeclare": "moins_10_juz"'
  AND private.praxis_reponses(pg_temp.c('02')) ->> 'niveauMemorisationDeclare' = 'moins_10_juz',
  'ancienne reponse moins_10_juz : complete, relue telle quelle par le dossier et par Praxis');

ROLLBACK;
