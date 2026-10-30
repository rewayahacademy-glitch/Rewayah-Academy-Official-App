-- CAND-L2A2 : gestes de la direction (transitions 7, 10, 16, 17, 18, 19, 23,
-- 24, 25, 28) et action groupee (ADM-22). Migration
-- 20261022000100_cand_l2a2_gestes_direction.sql, sur le moteur de CAND-L2A1.
-- Cas de la spec consolidee, section 12.1 : L2-4 (entree en salle 2 sans
-- paiement compatible, puis sans cadre religieux : refus nommes), L2-7 (lot de
-- 10 pauses dont 3 refusees : 7 reussies, 3 exclues avec raison, 3
-- inchangees), L2-8 (cle rejouee, version perimee), L2-9 (gestes en pause),
-- L2-10 (gestes a motif sans motif), L2-11 (une ligne audit_logs par
-- transition, chaine verifiable), L2-17 (rouvrir avec un controle de l'etape
-- faux : controles_non_satisfaits nommes, 0 ecriture), L2-18 (complement en
-- salle 2 : meme etat, compte dans les informations manquantes), L2-5 en
-- partie (refus : 0 motif interne dans etat_dossier()), L6-10 second temps
-- (moyen infirme par la direction : paiement_non_disponible, motif trace) ;
-- plus la portee par genre de chaque geste (hors portee trace, super-admin
-- compris), les listes fermees (modeles, elements), la reouverture et ses
-- controles, le responsable du meme cote, la confirmation en salle 3 sous
-- restriction de paiement, l'apercu et l'execution d'un lot (jeton, nombre,
-- geste non groupable, rejeu, isolement des lignes), les capacites et la
-- liste de CAND-L1 redefinies, les droits (F86, ACL, aides internes).
-- Section (o), relecture du 22/10 : L2-21 (chaque refus d'un lot trace d'abord
-- les identifiants de l'autre cote), L2-22 (jeton sous une cle du serveur, une
-- ligne d'audit par apercu), L2-23 (rejeu apres un changement de genre),
-- L2-24 (reouverture et paiement_non_disponible, transition 9), L2-25 (fin d'un
-- complement de salle 2), L2-26 (vocabulaire des gestes groupables,
-- lire_candidature), plus l'entretien planifie fige pour L4.
-- Section (p), reponses du directeur du 22/10 (questionnaire de CAND-L2A1, C17) :
-- le controle questionnaire_complet ecarte moyensAccessibles (champ
-- informatif) ; sans langue maternelle ni plafond de langues il reste complet ;
-- les anciens codes (ijaza, public, heures) le rendent incomplet ; admission de
-- bout en bout malgre un moyen accessible invalide.
-- Chaque controle leve 'CAND-L2A2 ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE (stub_auth puis toutes les migrations) ; le scenario pose ses
-- propres fixtures, publie une version de TEST du cadre religieux dans sa
-- transaction, et annule tout a la fin.
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
    RAISE EXCEPTION 'CAND-L2A2 ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

-- Un appel sous le role authenticated (la RLS et les ACL jouent), au nom d'un
-- compte ; le resultat jsonb est rendu apres retour au proprietaire.
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

-- Un appel qui doit etre refuse avec ce code, sous authenticated (ou anon).
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
    RAISE EXCEPTION 'CAND-L2A2 ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CAND-L2A2 ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Tout ce qu'un geste peut ecrire pour une candidature.
CREATE FUNCTION pg_temp.trace(p_id uuid) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'evenements', (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id = p_id),
    'audit', (SELECT count(*) FROM public.audit_logs a WHERE a.row_id = p_id::text),
    'gestes', (SELECT count(*) FROM public.candidature_gestes g WHERE g.candidature_id = p_id),
    'decisions', (SELECT count(*) FROM public.candidature_paiement_decisions d WHERE d.candidature_id = p_id),
    'reponses', (SELECT md5(coalesce(string_agg(r.reponses::text, '|' ORDER BY r.id), ''))
                   FROM public.candidature_reponses r WHERE r.candidature_id = p_id),
    'ligne', (SELECT md5(to_jsonb(c)::text) FROM public.candidatures c WHERE c.id = p_id));
$$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca2b0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca2bcccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Une fixture : compte enseignant (en attente par defaut), candidature, et
-- au besoin un document de reponses ENVOYE (jamais un brouillon), la colonne
-- paiement alignee sur le calcul de L6.
CREATE FUNCTION pg_temp.cand(p_n text, p_genre public.gender, p_etape text, p_etat text, p_issue text,
                             p_pause boolean, p_doc jsonb, p_qv text DEFAULT 'salle-examen-1',
                             p_statut text DEFAULT 'pending_kyc') RETURNS uuid
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email) VALUES (pg_temp.p(p_n), 'cand-l2a2-' || p_n || '@test.invalid');
  INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  VALUES (pg_temp.p(p_n), 'CA2B-ENS-00' || p_n, 'teacher', 'Essai' || p_n, 'Fictif', p_statut::public.account_status,
          p_genre);
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause,
                                   pause_modele, issue_modele, source)
  VALUES (pg_temp.c(p_n), 'enseignant', pg_temp.p(p_n), p_genre, 'Fixture L2A2 ' || p_n, p_etape, p_etat, p_issue,
          p_pause, CASE WHEN p_pause THEN 'pause_general' END,
          CASE WHEN p_issue = 'refusee' THEN 'refus_general' END, 'lien_public');
  IF p_doc IS NOT NULL THEN
    INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon,
                                             envoye_le)
    VALUES (pg_temp.c(p_n), p_qv, p_doc || '{"accordRemuneration": true}'::jsonb, 'candidat', false,
            pg_catalog.clock_timestamp());
    UPDATE public.candidatures SET paiement = private.paiement_etat(id) WHERE id = pg_temp.c(p_n);
  END IF;
  RETURN pg_temp.c(p_n);
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.p(text), pg_temp.c(text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction au genre inconnu, a4
-- super-admin homme (exception de 0088), a5 seconde direction homme, c1
-- comptable, e1 tuteur, b1 enseignant (provisoire) sans candidature.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'cand-l2a2-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'a4', 'a5', 'c1', 'e1', 'b1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca2bffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'CA2B-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('a2'), 'CA2B-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('a3'), 'CA2B-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 (pg_temp.p('a4'), 'CA2B-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 (pg_temp.p('a5'), 'CA2B-ADM-0005', 'admin', NULL, 'Seconde', 'Direction', 'active', 'male'),
 (pg_temp.p('c1'), 'CA2B-CPT-0001', 'accountant', NULL, 'Compta', 'Essai', 'active', 'male'),
 (pg_temp.p('e1'), 'CA2B-TUT-0001', 'guardian', 'ca2bffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female'),
 (pg_temp.p('b1'), 'CA2B-ENS-00B1', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('a4'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

-- Les reponses completes d'un candidat d'Arabie saoudite (compte bancaire) et
-- d'un candidat du Nigeria (Afrique, CAND-Q05 ouvert).
SELECT pg_temp.garde('complet_sa', $j$
{"langueMaternelle": "ar", "languesExplication": ["francais", "poular"],
 "niveauMemorisationDeclare": "coran_entier", "niveauLectureTajwid": "tajwid_enseigne",
 "riwayat": ["hafs", "warsh"], "ijazaPresentable": "oui", "experienceDebutants": "oui",
 "disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "22:00"},
                              {"jour": 3, "debut": "22:00", "fin": "24:00"}],
 "fuseauIana": "Asia/Riyadh", "classesSouhaitees": "2", "debutPossible": "immediat",
 "publics": ["6_9", "adultes"], "paysResidence": "SA", "paysVersement": "SA", "compteBancaire": true,
 "operateurs": []}
$j$::jsonb);
SELECT pg_temp.garde('complet_ng', pg_temp.lu('complet_sa')
  || '{"paysResidence": "NG", "paysVersement": "NG", "fuseauIana": "Africa/Lagos", "publics": ["6_9"]}'::jsonb);

-- Candidatures (hommes sauf 06 et 27).
SELECT pg_temp.cand('01', 'male', 'prequalification', 'a_completer', 'en_cours', false, NULL);
SELECT pg_temp.cand('02', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('03', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'),
                    'salle-examen-0');
SELECT pg_temp.cand('04', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('05', 'male', 'prequalification', 'en_examen', 'en_cours', false,
                    pg_temp.lu('complet_sa') || '{"operateurs": ["wave"]}'::jsonb);
SELECT pg_temp.cand('06', 'female', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('07', 'male', 'confirmee', NULL, 'en_cours', false, pg_temp.lu('complet_sa'), 'salle-examen-1',
                    'provisional_active');
UPDATE public.candidatures SET restreinte = true, restriction_cause = 'paiement' WHERE id = pg_temp.c('07');
SELECT pg_temp.cand('09', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('10', 'male', 'verifications', 'entretien_planifie', 'en_cours', true, NULL);
SELECT pg_temp.cand('11', 'male', 'prequalification', 'en_examen', 'refusee', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('12', 'male', 'prequalification', 'en_examen', 'refusee', false, pg_temp.lu('complet_ng'));
SELECT pg_temp.cand('13', 'male', 'prequalification', 'a_completer', 'retiree', false, NULL);
SELECT pg_temp.cand('14', 'male', 'prequalification', 'a_completer', 'refusee', false, NULL, 'salle-examen-1',
                    'disabled');
SELECT pg_temp.cand('15', 'male', 'prequalification', 'a_completer', 'en_cours', false, NULL);
SELECT pg_temp.cand('16', 'male', 'prequalification', 'a_completer', 'en_cours', true, NULL);
SELECT pg_temp.cand(s, 'male', 'prequalification', 'a_completer', CASE WHEN s IN ('24', '25', '26') THEN 'refusee'
                    ELSE 'en_cours' END, false, NULL)
FROM unnest(ARRAY['17', '18', '19', '20', '21', '22', '23', '24', '25', '26']) AS s;
SELECT pg_temp.cand('27', 'female', 'prequalification', 'a_completer', 'en_cours', false, NULL);
SELECT pg_temp.cand('28', 'male', 'verifications', 'entretien_a_planifier', 'en_cours', false, NULL);
SELECT pg_temp.cand('29', 'male', 'confirmee', NULL, 'en_cours', false, NULL, 'salle-examen-1', 'provisional_active');
SELECT pg_temp.cand('31', 'male', 'prequalification', 'en_examen', 'refusee', false, pg_temp.lu('complet_sa'),
                    'salle-examen-0');
-- Le cadre religieux accepte par les comptes qui en ont besoin (comme par la
-- page d'accords, insere ici par le proprietaire), une fois la version de
-- TEST publiee plus bas.

SELECT pg_temp.vrai((SELECT count(*) FROM public.candidatures WHERE id::text LIKE 'ca2bcccc%') = 29
  AND (SELECT paiement FROM public.candidatures WHERE id = pg_temp.c('02')) = 'a_verifier'
  AND (SELECT paiement FROM public.candidatures WHERE id = pg_temp.c('12')) = 'incompatible'
  AND (SELECT genre FROM public.candidatures WHERE id = pg_temp.c('06')) = 'female'
  AND public.cadre_religieux_version_requise() IS NULL,
  'fixtures : 29 candidatures, paiement aligne sur L6, 06 et 27 du cote des femmes, aucun cadre publie');

-- ------------------------------------------------------------
-- (a) Droits, empreintes F86, aides internes, tables
-- ------------------------------------------------------------
DO $f86$
DECLARE
  f regprocedure;
  r text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
      'public.demander_complement_candidat(uuid,text[],text,integer,text)'::regprocedure,
      'public.admettre_salle_verification(uuid,integer,text)'::regprocedure,
      'public.refuser_candidat(uuid,text,text,integer,text)'::regprocedure,
      'public.mettre_en_pause_candidat(uuid,text,text,date,integer,text)'::regprocedure,
      'public.lever_pause_candidat(uuid,integer,text,text)'::regprocedure,
      'public.consigner_retrait_candidat(uuid,text,date,text,integer,text)'::regprocedure,
      'public.rouvrir_candidat(uuid,text,integer,text)'::regprocedure,
      'public.definir_responsable_candidat(uuid,uuid,integer,text)'::regprocedure,
      'public.confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)'::regprocedure,
      'public.infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)'::regprocedure,
      'public.apercu_lot_candidats(text,uuid[])'::regprocedure,
      'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure,
      'public.capacites_candidatures()'::regprocedure,
      'public.lire_candidature(uuid)'::regprocedure,
      'public.lister_candidatures(jsonb,text,integer)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                   AND coalesce(proconfig @> ARRAY['search_path=""'], false)
            FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%CAND-L2A2%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-L2A2 ROUGE : DEFINER, proprietaire, search_path, empreinte ou ACL de %', f;
    END IF;
    IF app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f))
       OR (SELECT prosrc LIKE '%app_role()%' AND prosrc NOT LIKE '%app_account_valid%' FROM pg_proc WHERE oid = f) THEN
      RAISE EXCEPTION 'CAND-L2A2 ROUGE : garde negative ou sans app_account_valid dans %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('quinze RPC (douze gestes et lots, trois lectures redefinies) : DEFINER postgres, search_path vide, empreinte reelle, authenticated seul, garde positive');
  IF (SELECT array_agg(provolatile::text ORDER BY proname) FROM pg_proc
      WHERE pronamespace = 'public'::regnamespace
        AND proname IN ('admettre_salle_verification', 'apercu_lot_candidats', 'capacites_candidatures',
                        'executer_lot_candidats', 'lister_candidatures', 'refuser_candidat'))
     IS DISTINCT FROM ARRAY['v', 'v', 's', 'v', 'v', 'v'] THEN
    RAISE EXCEPTION 'CAND-L2A2 ROUGE : volatilite inattendue';
  END IF;
  PERFORM pg_temp.ok('gestes, apercu et execution VOLATILE ; capacites STABLE');
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p
           WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'candidature\_%' LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_function_privilege(r, f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L2A2 ROUGE : aide interne % executable par %', f, r;
      END IF;
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND proname IN ('candidature_etat_direction', 'candidature_complement_codes',
                                         'candidature_complement_en_cours', 'candidature_questionnaire_envoye',
                                         'candidature_controles_entree', 'candidature_controles_faux',
                                         'candidature_geste_groupe', 'candidature_lot_tracer',
                                         'candidature_lot_examiner')) = 9,
    'neuf aides internes du lot (dont la trace des lots, D16), executables par aucun compte');
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND proname LIKE 'cand\_%') = 9,
    'aucune aide cand_ de plus : les neuf de CAND-L1');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
         AND proname LIKE '%candidature%' AND has_function_privilege('authenticated', oid, 'EXECUTE')
         AND proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature',
                             'lire_contact_candidature', 'historique_candidature')),
    'aucune RPC du lot ne double etat_dossier() : aucun nom ne contient candidature');
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF has_table_privilege(r, 'public.candidature_lots', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'private.candidature_lot_secret', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'private.candidature_modeles_message', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
      RAISE EXCEPTION 'CAND-L2A2 ROUGE : % garde un privilege sur une table du lot', r;
    END IF;
  END LOOP;
  PERFORM pg_temp.vrai((SELECT bool_and(relrowsecurity) FROM pg_class
                         WHERE oid IN ('public.candidature_lots'::regclass, 'private.candidature_modeles_message'::regclass,
                                       'private.candidature_lot_secret'::regclass))
    AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename IN ('candidature_lots', 'candidature_modeles_message',
                                                                  'candidature_lot_secret')),
    'tables du lot (dont la cle des jetons, D17) : RLS active, aucun privilege client, aucune policy');
  PERFORM pg_temp.vrai((SELECT count(*) FROM private.candidature_lot_secret) = 1
    AND (SELECT length(secret) >= 64 FROM private.candidature_lot_secret),
    'la cle des jetons de lot : une ligne engendree par la base, 64 signes au moins');
  -- Les regles de l'admission (lot C, gestes *_admission) ont leur scenario.
  PERFORM pg_temp.vrai((SELECT count(*) FROM private.candidature_gestes_regles
                         WHERE geste NOT LIKE '%admission') = 26,
    'la table des regles de CAND-L2A1 est inchangee (vingt-six variantes)');
END $f86$;

SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.refuser_candidat(pg_temp.c('15'), 'Motif', 'refus_general', 1, 'cle-anon-0001')$$,
  '42501', 'anon : refus ferme', 'anon');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('15')])$$,
  '42501', 'anon : apercu ferme', 'anon');

-- Chaque RPC du lot refuse (42501) tout compte hors de la direction active.
DO $hors_direction$
DECLARE
  v record;
  q text;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      (pg_temp.p('e1'), 'guardian', 'tuteur'),
      (pg_temp.p('c1'), 'accountant', 'comptable'),
      (pg_temp.p('b1'), 'teacher', 'enseignant'),
      (pg_temp.p('15'), 'teacher', 'candidat')) AS t(id, role, nom) LOOP
    FOREACH q IN ARRAY ARRAY[
        $$SELECT public.demander_complement_candidat(pg_temp.c('15'), ARRAY['langues'], 'Motif', 1, 'cle-hd-00001')$$,
        $$SELECT public.admettre_salle_verification(pg_temp.c('15'), 1, 'cle-hd-00002')$$,
        $$SELECT public.refuser_candidat(pg_temp.c('15'), 'Motif', 'refus_general', 1, 'cle-hd-00003')$$,
        $$SELECT public.mettre_en_pause_candidat(pg_temp.c('15'), 'Motif', 'pause_general', NULL, 1, 'cle-hd-00004')$$,
        $$SELECT public.lever_pause_candidat(pg_temp.c('15'), 1, 'cle-hd-00005')$$,
        $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'), 'courriel', current_date, 'Motif', 1, 'cle-hd-00006')$$,
        $$SELECT public.rouvrir_candidat(pg_temp.c('15'), 'Motif', 1, 'cle-hd-00007')$$,
        $$SELECT public.definir_responsable_candidat(pg_temp.c('15'), NULL, 1, 'cle-hd-00008')$$,
        $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('15'), 'virement_bancaire', NULL, 1, 'cle-hd-00009')$$,
        $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('15'), 'virement_bancaire', NULL, 'Motif', 1, 'cle-hd-00010')$$,
        $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('15')])$$,
        $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('15')], md5('x'), 1, 'cle-hd-00011', 'Motif', 'refus_general')$$] LOOP
      PERFORM pg_temp.refus_en(v.id, v.role, q, '42501', 'hors de la direction (' || v.nom || ') : ' || left(q, 50));
    END LOOP;
  END LOOP;
END $hors_direction$;
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_gestes WHERE candidature_id::text LIKE 'ca2bcccc%') = 0
  AND (SELECT count(*) FROM public.candidature_lots) = 0,
  'quarante-huit refus hors de la direction : 0 cle, 0 lot');

-- ------------------------------------------------------------
-- (b) Capacites (spec 8.1, D13)
-- ------------------------------------------------------------
SELECT pg_temp.garde('cap_a1', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_a3', pg_temp.en(pg_temp.p('a3'), 'admin', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_a4', pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_k1', pg_temp.en(pg_temp.p('c1'), 'accountant', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.garde('cap_e1', pg_temp.en(pg_temp.p('e1'), 'guardian', $$SELECT public.capacites_candidatures()$$));
SELECT pg_temp.vrai(pg_temp.lu('cap_a1') @> '{"peutLire": true, "peutDecider": true, "peutEcrireReferentiel": true,
    "peutImporter": false, "peutMenerEntretien": false, "doubleVerificationRequise": false,
    "gestesGroupables": ["mettreEnPause", "leverPause", "refuser"]}'::jsonb
  AND pg_temp.lu('cap_a1') -> 'gestes' = '{"demanderComplement": true, "cloreComplement": true, "admettreVerifications": true,
    "confirmerMoyenPaiement": true, "infirmerMoyenPaiement": true, "mettreEnPause": true, "leverPause": true,
    "refuser": true, "consignerRetrait": true, "rouvrir": true, "definirResponsable": true, "agirEnLot": true,
    "inviter": false, "consignerPrevenu": true, "garderPourSuivi": true, "rattacher": true,
    "planifierEntretien": false, "consignerEntretien": false, "pieceACorriger": false, "validerPiece": false,
    "restreindre": false, "leverRestriction": false, "noterIndisponibilite": false,
    "leverIndisponibilite": false}'::jsonb,
  'direction homme : decide de son cote ; une capacite par geste, vraie pour les seuls gestes que le serveur sait faire (CAND-L3 : prevenu, garder pour suivi et rattacher le sont desormais)');
SELECT pg_temp.vrai(pg_temp.lu('cap_a1') -> 'listes' = '{
    "modelesRefus": ["refus_general", "refus_niveau", "refus_besoins", "refus_sans_reponse"],
    "modelesPause": ["pause_attente_besoin", "pause_attente_informations", "pause_demande_candidat", "pause_general"],
    "complementSalleExamen": ["langues", "recitation", "disponibilites", "publics", "versement", "cadre_religieux"],
    "complementSalleVerification": ["piece_identite", "cadre_religieux", "contrat", "avis"],
    "canauxRetrait": ["conversation", "courriel"],
    "codesClotureComplement": ["complement_clos"],
    "canauxPrevenu": ["whatsapp"], "modelesPrevenu": ["lien_inscription"]}'::jsonb,
  'listes fermees rendues a l''ecran : modeles, elements par salle, canaux du retrait, code de cloture du complement (D20) ; CAND-L3 (23/10) : canal et modele du geste « prevenu »');
SELECT pg_temp.vrai(pg_temp.lu('cap_a3') @> '{"peutLire": false, "peutDecider": false, "peutEcrireReferentiel": false,
    "gestesGroupables": []}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM jsonb_each(pg_temp.lu('cap_a3') -> 'gestes') g WHERE g.value <> 'false'::jsonb)
  AND pg_temp.lu('cap_a3') #> '{listes,modelesRefus}' = '[]'::jsonb,
  'direction au genre inconnu : aucun geste, aucune liste');
SELECT pg_temp.vrai(pg_temp.lu('cap_a4') @> '{"peutLire": true, "peutLireHorsGenre": true, "peutDecider": true}'::jsonb,
  'super-admin : lit les deux cotes, ne decide que du sien (les gestes de l''autre cote rendent hors_portee)');
SELECT pg_temp.vrai(pg_temp.lu('cap_k1') @> '{"peutLire": false, "peutDecider": false, "peutEcrireReferentiel": true}'::jsonb
  AND pg_temp.lu('cap_e1') @> '{"peutLire": false, "peutDecider": false, "peutEcrireReferentiel": false}'::jsonb,
  'peutEcrireReferentiel lu dans private.paiement_gestionnaire() : comptabilite oui, tuteur non (L6)');

-- ------------------------------------------------------------
-- (c) Transition 10 et 24 : L2-4 (entree en salle 2 refusee, puis admise)
-- ------------------------------------------------------------
-- 02 : paiement a verifier, confirme par la direction (24), cadre pas encore
-- publie : refus nomme cadre_religieux non_publie.
SELECT pg_temp.garde('t02', pg_temp.trace(pg_temp.c('02')));
SELECT pg_temp.garde('ad02a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('02'), 1, 'cle-admission-02-a')$$));
SELECT pg_temp.vrai(pg_temp.lu('ad02a') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "paiement_compatible", "cause": "a_verifier"}, {"nom": "cadre_religieux", "cause": "non_publie"}]}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02'),
  'L2-4 : admission sans paiement compatible ni cadre publie : deux controles nommes avec leur cause, 0 ecriture');
SELECT pg_temp.garde('cf02', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('02'), 'virement_bancaire', NULL, 1, 'cle-confirmer-02')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf02') ->> 'rejoue' = 'false' AND pg_temp.lu('cf02') ->> 'paiement' = 'compatible'
  AND pg_temp.lu('cf02') #>> '{candidature,paiement}' = 'compatible'
  AND pg_temp.lu('cf02') #>> '{candidature,etat}' = 'en_examen'
  AND (SELECT count(*) FROM public.candidature_paiement_decisions
        WHERE candidature_id = pg_temp.c('02') AND decision = 'confirme' AND methode = 'virement_bancaire'
          AND pays = 'SA' AND operateur IS NULL AND auteur_id = pg_temp.p('a1')) = 1
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('02') AND type = 'controle' AND auteur_id = pg_temp.p('a1')
          AND details @> '{"geste": "confirmer_moyen_paiement", "transition": 24, "decision": "confirme",
                           "pays": "SA", "methode": "virement_bancaire"}'::jsonb) = 1
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('02') AND type = 'controle'
          AND details @> '{"cause": "moyen_confirme", "paiementAvant": "a_verifier", "paiementApres": "compatible"}'::jsonb) = 1,
  'transition 24 : moyen confirme, decision ecrite dans candidature_paiement_decisions, paiement recalcule par L6 (compatible), deux evenements');
SELECT pg_temp.garde('t02', pg_temp.trace(pg_temp.c('02')));
SELECT pg_temp.garde('cf02r', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('02'), 'virement_bancaire', NULL, 1, 'cle-confirmer-02')$$));
SELECT pg_temp.garde('cf02b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('02'), 'virement_bancaire', NULL, 3, 'cle-confirmer-02-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf02r') = (pg_temp.lu('cf02') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('cf02b') @> '{"erreur": "transition_interdite", "geste": "confirmer_moyen_paiement", "raison": "etat"}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02'),
  'L2-8 : confirmation rejouee, premier resultat sans ecriture ; deja compatible, la regle refuse une seconde confirmation');

-- Version de TEST du cadre religieux, publiee dans la transaction du scenario.
INSERT INTO public.contract_required_versions (contract_kind, version)
VALUES ('teacher_religious_framework', 'test-cadre-1');
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
SELECT pg_temp.p(s), 'teacher_religious_framework', 'test-cadre-1'
FROM unnest(ARRAY['01', '03', '04', '05', '06', '09', '11', '12']) AS s;

SELECT pg_temp.garde('ad02b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('02'), 3, 'cle-admission-02-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('ad02b') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "cadre_religieux", "cause": "non_accepte"}]}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02'),
  'L2-4 : paiement compatible, cadre publie mais pas accepte : refus nomme cadre_religieux, 0 ecriture');

-- 03 : questionnaire envoye a une version perimee.
SELECT pg_temp.garde('cf03', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('03'), 'virement_bancaire', NULL, 1, 'cle-confirmer-03')$$));
SELECT pg_temp.garde('t03', pg_temp.trace(pg_temp.c('03')));
SELECT pg_temp.garde('ad03', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('03'), 3, 'cle-admission-03')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf03') ->> 'paiement' = 'compatible'
  AND pg_temp.lu('ad03') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "questionnaire_complet", "cause": "perime"}]}'::jsonb
  AND pg_temp.trace(pg_temp.c('03')) = pg_temp.lu('t03'),
  'admission : questionnaire envoye a une version perimee, refus nomme, 0 ecriture');

-- 01 : le parcours reel. Le candidat envoie (transition 6 de CAND-L2A1), la
-- direction tente l'admission, confirme le moyen, puis admet.
SELECT pg_temp.garde('e01', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true, 'v2.0.0', 1,
    'cle-envoi-l2a2-01')$$));
SELECT pg_temp.garde('t01', pg_temp.trace(pg_temp.c('01')));
SELECT pg_temp.garde('ad01a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('01'), 3, 'cle-admission-01-a')$$));
SELECT pg_temp.vrai(pg_temp.lu('e01') #>> '{candidature,etat}' = 'en_examen'
  AND pg_temp.lu('e01') #>> '{candidature,paiement}' = 'a_verifier'
  AND pg_temp.lu('ad01a') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "paiement_compatible", "cause": "a_verifier"}]}'::jsonb
  AND pg_temp.trace(pg_temp.c('01')) = pg_temp.lu('t01'),
  'L2-4 : apres un envoi reel, admission refusee tant que le moyen n''est pas confirme par la direction');
SELECT pg_temp.garde('cf01', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('01'), 'virement_bancaire', NULL, 3, 'cle-confirmer-01')$$));
SELECT pg_temp.garde('ad01p', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('01'), 3, 'cle-admission-01-p')$$));
SELECT pg_temp.garde('t01', pg_temp.trace(pg_temp.c('01')));
SELECT pg_temp.garde('ad01', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('01'), 5, 'cle-admission-01-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf01') #>> '{candidature,version}' = '5'
  AND pg_temp.lu('ad01p') = '{"erreur": "conflit_candidature", "versionCourante": 5}'::jsonb
  AND pg_temp.lu('ad01') ->> 'rejoue' = 'false'
  AND pg_temp.lu('ad01') -> 'candidature' @> '{"etape": "verifications", "etat": "entretien_a_planifier",
      "issue": "en_cours", "paiement": "compatible", "version": 6}'::jsonb
  AND NOT (pg_temp.lu('ad01') -> 'candidature') ?| ARRAY['nomComplet', 'paysResidence', 'reponses'],
  'transition 10 : version perimee refusee (conflit_candidature) ; puis admise en Salle de verification et d''entretien, etat relu sans nom ni reponse');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements
                      WHERE candidature_id = pg_temp.c('01') AND type = 'transition'
                        AND etape_avant = 'prequalification' AND etape_apres = 'verifications'
                        AND etat_avant = 'en_examen' AND etat_apres = 'entretien_a_planifier'
                        AND auteur_id = pg_temp.p('a1') AND motif_interne IS NULL
                        AND details @> '{"geste": "admettre_verifications", "transition": 10, "auteur": "direction",
                          "aNotifier": "admis_salle_verification",
                          "controles": [{"nom": "paiement_compatible", "valeur": true},
                                        {"nom": "cadre_religieux", "valeur": true},
                                        {"nom": "questionnaire_complet", "valeur": true}]}'::jsonb) = 1
  AND (pg_temp.trace(pg_temp.c('01')) ->> 'audit')::int = (pg_temp.lu('t01') ->> 'audit')::int + 1
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = pg_temp.c('01')::text AND action = 'candidature_geste'
          AND payload @> '{"geste": "admettre_verifications", "transition": 10, "etapeApres": "verifications"}'::jsonb) = 1,
  'L2-11 : la transition 10 laisse 1 evenement (controles vrais, marqueur pour L5) et 1 ligne audit_logs');
SELECT pg_temp.garde('d01', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$));
SELECT pg_temp.vrai(pg_temp.lu('d01') @> '{"etape": "verifications", "etat": "entretien_a_planifier",
    "paiement": "compatible", "complementDemande": []}'::jsonb,
  'le candidat admis lit sa Salle de verification et d''entretien par etat_dossier()');

-- ------------------------------------------------------------
-- (d) Transitions 24 et 25 : moyens nommes, lignes non confirmees, salle 3
-- ------------------------------------------------------------
-- Une ligne de mobile money en_verification pour l'Arabie saoudite (hors
-- d'Afrique), ecrite par le proprietaire comme une migration le ferait.
INSERT INTO public.referentiel_paiement (pays, methode, operateur, etat, source, source_ref)
VALUES ('SA', 'mobile_money', 'wave', 'en_verification', 'decision_directeur', 'scenario CAND-L2A2');
SELECT pg_temp.garde('t05', pg_temp.trace(pg_temp.c('05')));
SELECT pg_temp.garde('cf05a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('05'), 'mobile_money', 'wave', 1, 'cle-confirmer-05-a')$$));
SELECT pg_temp.garde('cf05b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('05'), 'mobile_money', 'orange_money', 1, 'cle-confirmer-05-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf05a') = '{"erreur": "moyen_non_confirmable", "cause": "ligne_non_confirmee",
    "etatLigne": "en_verification"}'::jsonb
  AND pg_temp.lu('cf05b') = '{"erreur": "moyen_non_confirmable", "cause": "non_declare"}'::jsonb
  AND pg_temp.trace(pg_temp.c('05')) = pg_temp.lu('t05')
  AND (SELECT paiement FROM public.candidatures WHERE id = pg_temp.c('05')) = 'a_verifier',
  'transition 24 : une ligne en_verification ne se confirme jamais ; un moyen non declare non plus ; 0 ecriture, 0 decision');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('05'),
  'virement_bancaire', 'wave', 1, 'cle-confirmer-05-c')$$, '22023', 'virement avec un operateur : 22023');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('05'),
  'cheque', NULL, 1, 'cle-confirmer-05-d')$$, '22023', 'methode hors liste : 22023');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('05'),
  'mobile_money', NULL, 'Motif', 1, 'cle-infirmer-05-e')$$, '22023', 'mobile money sans operateur : 22023');

-- 04 : infirmation (25) du seul moyen : la transition 8 suit (L6-10, second
-- temps, par le geste reel).
SELECT pg_temp.garde('t04', pg_temp.trace(pg_temp.c('04')));
SELECT pg_temp.garde('if04a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('04'), 'virement_bancaire', NULL, NULL, 1, 'cle-infirmer-04-a')$$));
SELECT pg_temp.garde('if04b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('04'), 'mobile_money', 'wave', 'Motif', 1, 'cle-infirmer-04-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('if04a') = '{"erreur": "motif_requis", "geste": "infirmer_moyen_paiement"}'::jsonb
  AND pg_temp.lu('if04b') = '{"erreur": "moyen_non_declare"}'::jsonb
  AND pg_temp.trace(pg_temp.c('04')) = pg_temp.lu('t04'),
  'transition 25 : sans motif, motif_requis ; moyen non declare, moyen_non_declare ; 0 ecriture');
SELECT pg_temp.garde('if04', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('04'), 'virement_bancaire', NULL,
    E' \tMotif interne L2A2 : compte au nom d''un tiers\n', 1, 'cle-infirmer-04')$$));
SELECT pg_temp.vrai(pg_temp.lu('if04') ->> 'paiement' = 'incompatible'
  AND pg_temp.lu('if04') -> 'candidature' @> '{"etape": "prequalification", "etat": "paiement_non_disponible",
      "issue": "en_cours", "paiement": "incompatible"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_paiement_decisions
        WHERE candidature_id = pg_temp.c('04') AND decision = 'infirme'
          AND motif_interne = 'Motif interne L2A2 : compte au nom d''un tiers') = 1
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('04') AND type = 'transition' AND details ->> 'transition' = '8'
          AND etat_avant = 'en_examen' AND etat_apres = 'paiement_non_disponible' AND auteur_id = pg_temp.p('a1')
          AND motif_interne = 'Motif interne L2A2 : compte au nom d''un tiers'
          AND details ->> 'cause' = 'moyen_infirme') = 1
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('04') AND details @> '{"geste": "infirmer_moyen_paiement", "transition": 25,
          "decision": "infirme"}'::jsonb AND motif_interne IS NOT NULL) = 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE row_id = pg_temp.c('04')::text
                   AND payload::text LIKE '%tiers%'),
  'L6-10 : moyen infirme par le geste 25 : decision et motif (sans blancs) traces, transition 8 vers paiement_non_disponible, jamais le motif dans audit_logs');
SELECT pg_temp.garde('d04', pg_temp.en(pg_temp.p('04'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.vrai(pg_temp.lu('d04') -> 'candidature' @> '{"etat": "paiement_non_disponible", "paiement": "incompatible"}'::jsonb
  AND pg_temp.lu('d04')::text NOT LIKE '%Motif interne%' AND pg_temp.lu('d04')::text NOT LIKE '%tiers%',
  'le candidat lit paiement_non_disponible, jamais le motif de l''infirmation');
-- La liste de CAND-L1 filtre desormais cet etat.
SELECT pg_temp.garde('l04', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lister_candidatures('{"etat": "paiement_non_disponible"}'::jsonb)$$));
SELECT pg_temp.vrai((pg_temp.lu('l04') ->> 'total')::int >= 1
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l04') -> 'lignes') l WHERE l ->> 'id' = pg_temp.c('04')::text)
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l04') -> 'lignes') l
                   WHERE l ->> 'etat' <> 'paiement_non_disponible'),
  'lister_candidatures : le filtre etat accepte paiement_non_disponible (L6) et ne rend que cet etat');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"etat": "en_pause"}'::jsonb)$$,
  '22023', 'lister_candidatures : un etat inconnu reste refuse');

-- 24 depuis un etat qui ne le permet pas ; 25 en salle 3.
SELECT pg_temp.garde('cf15', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('15'), 'virement_bancaire', NULL, 1, 'cle-confirmer-15')$$));
SELECT pg_temp.garde('if07', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('07'), 'virement_bancaire', NULL, 'Motif', 1, 'cle-infirmer-07')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf15') @> '{"erreur": "transition_interdite", "etat": "a_completer", "raison": "etat"}'::jsonb
  AND pg_temp.lu('if07') @> '{"erreur": "transition_interdite", "etape": "confirmee", "raison": "etat"}'::jsonb,
  'transition 24 depuis a_completer (paiement inconnu) et 25 en salle 3 : transition_interdite');
-- 07 : salle 3 en restriction de cause paiement (24, variante 2) : le
-- paiement devient compatible, la restriction reste (21, L2B).
SELECT pg_temp.garde('cf07', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('07'), 'virement_bancaire', NULL, 1, 'cle-confirmer-07')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf07') ->> 'paiement' = 'compatible'
  AND pg_temp.lu('cf07') -> 'candidature' @> '{"etape": "confirmee", "restreinte": true, "restrictionCause": "paiement",
      "paiement": "compatible"}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('07')
               AND etape_avant = 'confirmee' AND etape_apres = 'confirmee'
               AND details @> '{"geste": "confirmer_moyen_paiement", "transition": 24}'::jsonb),
  'transition 24 en salle 3 sous restriction de cause paiement : paiement compatible, restriction gardee (levee par 21, L2B)');

-- ------------------------------------------------------------
-- (e) Transitions 7 et 23 : complement nomme ; L2-18
-- ------------------------------------------------------------
SELECT pg_temp.garde('t02', pg_temp.trace(pg_temp.c('02')));
SELECT pg_temp.garde('dc02a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('02'), ARRAY['langues'], NULL, 3, 'cle-complement-02-a')$$));
SELECT pg_temp.garde('dc02b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('02'), ARRAY[]::text[], 'Motif', 3, 'cle-complement-02-b')$$));
SELECT pg_temp.garde('dc02c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('02'), ARRAY['langues', 'piece_identite', 'Commentaire libre'],
    'Motif', 3, 'cle-complement-02-c')$$));
SELECT pg_temp.vrai(pg_temp.lu('dc02a') = '{"erreur": "motif_requis", "geste": "demander_complement"}'::jsonb
  AND pg_temp.lu('dc02b') = '{"erreur": "elements_requis"}'::jsonb
  AND pg_temp.lu('dc02c') ->> 'erreur' = 'elements_invalides'
  AND pg_temp.lu('dc02c') -> 'elements' = '["?", "piece_identite"]'::jsonb
  AND pg_temp.lu('dc02c') -> 'permis' = '["langues", "recitation", "disponibilites", "publics", "versement", "cadre_religieux"]'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02'),
  'transition 7 : sans motif, sans element, element hors de la liste de la salle (jamais un texte libre) : refus nommes, 0 ecriture');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.demander_complement_candidat(pg_temp.c('02'),
  ARRAY['langues', NULL], 'Motif', 3, 'cle-complement-02-n')$$, '22023', 'element nul : 22023');
SELECT pg_temp.garde('dc02', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('02'), ARRAY['versement', 'langues', 'versement'],
    'Motif interne L2A2 du complement', 3, 'cle-complement-02')$$));
SELECT pg_temp.vrai(pg_temp.lu('dc02') ->> 'rejoue' = 'false'
  AND pg_temp.lu('dc02') -> 'aCompleter' = '["versement", "langues"]'::jsonb
  AND pg_temp.lu('dc02') -> 'candidature' @> '{"etape": "prequalification", "etat": "a_completer", "version": 4}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('02') AND type = 'transition' AND etat_avant = 'en_examen'
          AND etat_apres = 'a_completer' AND motif_interne = 'Motif interne L2A2 du complement'
          AND details @> '{"geste": "demander_complement", "transition": 7, "aCompleter": ["versement", "langues"],
                           "aNotifier": "complement_demande"}'::jsonb) = 1,
  'transition 7 : en examen vers a completer, elements nommes sans doublon, marqueur pour L5, motif garde au serveur');
SELECT pg_temp.garde('d02', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$));
SELECT pg_temp.vrai(pg_temp.lu('d02') @> '{"etat": "a_completer", "complementDemande": ["versement", "langues"]}'::jsonb
  AND pg_temp.lu('d02')::text NOT LIKE '%Motif interne%',
  'le candidat lit les elements demandes (complementDemande), jamais le motif');
SELECT pg_temp.garde('dc02d', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('02'), ARRAY['langues'], 'Motif', 4, 'cle-complement-02-d')$$));
SELECT pg_temp.vrai(pg_temp.lu('dc02d') @> '{"erreur": "transition_interdite", "etat": "a_completer", "raison": "etat"}'::jsonb,
  'transition 7 depuis a_completer : transition_interdite');

-- 23 (01, Salle de verification et d'entretien) et le compteur des
-- informations manquantes (L2-18).
SELECT pg_temp.garde('lst_avant', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.garde('dc01a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['langues'], 'Motif', 6, 'cle-complement-01-a')$$));
SELECT pg_temp.garde('dc01', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['piece_identite', 'contrat'],
    'Motif interne L2A2 salle 2', 6, 'cle-complement-01')$$));
SELECT pg_temp.garde('lst_apres', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.garde('d01', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$));
SELECT pg_temp.vrai(pg_temp.lu('dc01a') @> '{"erreur": "elements_invalides", "elements": ["langues"]}'::jsonb
  AND pg_temp.lu('dc01a') -> 'permis' = '["piece_identite", "cadre_religieux", "contrat", "avis"]'::jsonb
  AND pg_temp.lu('dc01') -> 'candidature' @> '{"etape": "verifications", "etat": "entretien_a_planifier", "version": 7}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('01')
               AND details @> '{"geste": "demander_complement", "transition": 23,
                 "aCompleter": ["piece_identite", "contrat"], "aNotifier": "complement_demande"}'::jsonb
               AND etat_avant = 'entretien_a_planifier' AND etat_apres = 'entretien_a_planifier'),
  'transition 23 : complement en salle 2, meme etat, elements de la liste de la salle 2 (langues refuse)');
SELECT pg_temp.vrai((pg_temp.lu('lst_apres') #>> '{compteursAlertes,informationsManquantes}')::int
    = (pg_temp.lu('lst_avant') #>> '{compteursAlertes,informationsManquantes}')::int + 1
  AND pg_temp.lu('d01') -> 'complementDemande' = '["piece_identite", "contrat"]'::jsonb
  AND private.candidature_complement_en_cours((SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('01')))
      = pg_temp.lu('d01') -> 'complementDemande',
  'L2-18 : la candidature de salle 2 compte dans les informations manquantes ; le compteur et etat_dossier() lisent le meme complement');
-- Une pause sort la candidature des informations manquantes ; la levee l'y
-- remet.
SELECT pg_temp.garde('pa01', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('01'), 'Motif', 'pause_attente_informations', NULL, 7, 'cle-pause-01')$$));
SELECT pg_temp.garde('lst_pause', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.garde('lv01', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lever_pause_candidat(pg_temp.c('01'), 8, 'cle-levee-01')$$));
SELECT pg_temp.garde('lst_levee', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.vrai((pg_temp.lu('lst_pause') #>> '{compteursAlertes,informationsManquantes}')::int
    = (pg_temp.lu('lst_avant') #>> '{compteursAlertes,informationsManquantes}')::int
  AND (pg_temp.lu('lst_levee') #>> '{compteursAlertes,informationsManquantes}')::int
    = (pg_temp.lu('lst_apres') #>> '{compteursAlertes,informationsManquantes}')::int,
  'une pause n''entre dans aucune alerte : retiree pendant la pause, comptee de nouveau apres la levee');

-- ------------------------------------------------------------
-- (f) Transition 16 : refus motive, modele de la liste fermee
-- ------------------------------------------------------------
SELECT pg_temp.garde('t10', pg_temp.trace(pg_temp.c('10')));
SELECT pg_temp.garde('rf10a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), 'Motif', NULL, 1, 'cle-refus-10-a')$$));
SELECT pg_temp.garde('rf10b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), 'Motif', 'refus_imaginaire', 1, 'cle-refus-10-b')$$));
SELECT pg_temp.garde('rf10c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), 'Motif', 'pause_general', 1, 'cle-refus-10-c')$$));
SELECT pg_temp.garde('rf10d', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), chr(160) || ' ', 'refus_niveau', 1, 'cle-refus-10-d')$$));
SELECT pg_temp.vrai(pg_temp.lu('rf10a') = '{"erreur": "modele_requis", "geste": "refuser"}'::jsonb
  AND pg_temp.lu('rf10b') = '{"erreur": "modele_inconnu", "geste": "refuser"}'::jsonb
  AND pg_temp.lu('rf10c') = '{"erreur": "modele_inconnu", "geste": "refuser"}'::jsonb
  AND pg_temp.lu('rf10d') = '{"erreur": "motif_requis", "geste": "refuser"}'::jsonb
  AND pg_temp.trace(pg_temp.c('10')) = pg_temp.lu('t10'),
  'transition 16 : sans modele, modele hors liste ou d''une pause, motif fait d''espaces : refus nommes, 0 ecriture');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.refuser_candidat(pg_temp.c('10'), 'Motif',
  'Refus ! texte libre', 1, 'cle-refus-10-e')$$, '22023', 'modele qui n''est pas une cle : 22023');
SELECT pg_temp.garde('rf10', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), '  Motif interne L2A2 du refus  ', 'refus_niveau', 1, 'cle-refus-10')$$));
SELECT pg_temp.vrai(pg_temp.lu('rf10') -> 'candidature' @> '{"issue": "refusee", "refusModele": "refus_niveau",
    "enPause": false, "pauseModele": null, "etape": "verifications", "etat": "entretien_planifie", "version": 2}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('10') AND type = 'transition' AND issue_apres = 'refusee'
          AND motif_interne = 'Motif interne L2A2 du refus'
          AND details @> '{"geste": "refuser", "transition": 16, "modele": "refus_niveau", "entretienPlanifie": true,
                           "pauseLevee": true, "aNotifier": "refus"}'::jsonb) = 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE row_id = pg_temp.c('10')::text AND payload::text LIKE '%Motif%'),
  'transition 16 en pause : refusee, pause levee, entretien planifie note (L4), modele pose ; motif dans l''evenement seulement');
SELECT pg_temp.garde('d10', pg_temp.en(pg_temp.p('10'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.vrai(pg_temp.lu('d10') -> 'candidature' @> '{"issue": "refusee", "refusModele": "refus_niveau",
    "enPause": false}'::jsonb
  AND pg_temp.lu('d10')::text NOT LIKE '%Motif interne%',
  'L2-5 : le candidat lit le modele du refus, 0 motif interne dans etat_dossier()');
SELECT pg_temp.garde('rf10r', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), 'Autre', 'refus_general', 1, 'cle-refus-10')$$));
SELECT pg_temp.garde('rf10x', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('10'), 'Autre', 'refus_general', 2, 'cle-refus-10-x')$$));
SELECT pg_temp.garde('rf29', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('29'), 'Motif', 'refus_general', 1, 'cle-refus-29')$$));
SELECT pg_temp.vrai(pg_temp.lu('rf10r') = (pg_temp.lu('rf10') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('rf10x') @> '{"erreur": "transition_interdite", "issue": "refusee", "raison": "etat"}'::jsonb
  AND pg_temp.lu('rf29') @> '{"erreur": "transition_interdite", "etape": "confirmee", "raison": "etat"}'::jsonb,
  'L2-8 : refus rejoue (premier resultat, meme a l''ancienne version) ; deja refusee ou en salle 3 : transition_interdite');

-- ------------------------------------------------------------
-- (g) Transition 17 par la direction
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'),
  'whatsapp', current_date, 'Motif', 1, 'cle-retrait-15-a')$$, '22023', 'retrait : canal whatsapp refuse (22023)');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'),
  'courriel', NULL, 'Motif', 1, 'cle-retrait-15-b')$$, '22023', 'retrait : date de la demande absente (22023)');
SELECT pg_temp.garde('t15', pg_temp.trace(pg_temp.c('15')));
SELECT pg_temp.garde('rt15a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'), 'courriel', ((now() AT TIME ZONE 'UTC')::date + 1),
    'Motif', 1, 'cle-retrait-15-c')$$));
SELECT pg_temp.garde('rt15b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'), 'courriel', ((now() AT TIME ZONE 'UTC')::date - 1),
    'Motif', 1, 'cle-retrait-15-d')$$));
SELECT pg_temp.garde('rt15c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'), 'courriel', ((now() AT TIME ZONE 'UTC')::date), NULL,
    1, 'cle-retrait-15-e')$$));
SELECT pg_temp.vrai(pg_temp.lu('rt15a') = '{"erreur": "date_demande_invalide"}'::jsonb
  AND pg_temp.lu('rt15b') = '{"erreur": "date_demande_invalide"}'::jsonb
  AND pg_temp.lu('rt15c') = '{"erreur": "motif_requis", "geste": "retirer"}'::jsonb
  AND pg_temp.trace(pg_temp.c('15')) = pg_temp.lu('t15'),
  'transition 17 par la direction : date future ou anterieure a la reception, sans motif : refus nommes, 0 ecriture');
SELECT pg_temp.garde('rt15', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.consigner_retrait_candidat(pg_temp.c('15'), 'conversation', ((now() AT TIME ZONE 'UTC')::date),
    'Motif interne L2A2 du retrait', 1, 'cle-retrait-15')$$));
SELECT pg_temp.vrai(pg_temp.lu('rt15') -> 'candidature' @> '{"issue": "retiree", "etape": "prequalification",
    "etat": "a_completer"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('15') AND type = 'transition' AND issue_apres = 'retiree'
          AND auteur_id = pg_temp.p('a1') AND motif_interne = 'Motif interne L2A2 du retrait'
          AND details @> jsonb_build_object('geste', 'retirer', 'transition', 17, 'auteur', 'direction',
                'canal', 'conversation', 'demandeRecueLe', to_char((now() AT TIME ZONE 'UTC')::date, 'YYYY-MM-DD'),
                'entretienPlanifie', false, 'pauseLevee', false, 'aNotifier', 'retrait_enregistre')) = 1,
  'transition 17 : retrait consigne pour une demande recue par la conversation, canal et date traces, motif au serveur');
SELECT pg_temp.garde('rt16', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.consigner_retrait_candidat(pg_temp.c('16'), 'courriel', ((now() AT TIME ZONE 'UTC')::date),
    'Motif', 1, 'cle-retrait-16')$$));
SELECT pg_temp.vrai(pg_temp.lu('rt16') -> 'candidature' @> '{"issue": "retiree", "enPause": false, "pauseModele": null}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('16')
               AND details @> '{"transition": 17, "pauseLevee": true, "canal": "courriel"}'::jsonb),
  'retrait par la direction pendant une pause : permis, la pause est levee avec l''issue (C5)');

-- ------------------------------------------------------------
-- (h) Transition 18 et L2-9 (gestes pendant une pause)
-- ------------------------------------------------------------
SELECT pg_temp.garde('t09', pg_temp.trace(pg_temp.c('09')));
SELECT pg_temp.garde('pa09a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('09'), 'Motif', 'refus_general', NULL, 1, 'cle-pause-09-a')$$));
SELECT pg_temp.garde('pa09b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('09'), 'Motif', 'pause_general',
    ((now() AT TIME ZONE 'UTC')::date), 1, 'cle-pause-09-b')$$));
SELECT pg_temp.garde('pa09c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('09'), 'Motif', 'pause_general', 'infinity'::date, 1, 'cle-pause-09-c')$$));
SELECT pg_temp.garde('pa09d', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('09'), E'\t\n', 'pause_general', NULL, 1, 'cle-pause-09-d')$$));
SELECT pg_temp.vrai(pg_temp.lu('pa09a') = '{"erreur": "modele_inconnu", "geste": "mettre_en_pause"}'::jsonb
  AND pg_temp.lu('pa09b') = '{"erreur": "date_reprise_invalide"}'::jsonb
  AND pg_temp.lu('pa09c') = '{"erreur": "date_reprise_invalide"}'::jsonb
  AND pg_temp.lu('pa09d') = '{"erreur": "motif_requis", "geste": "mettre_en_pause"}'::jsonb
  AND pg_temp.trace(pg_temp.c('09')) = pg_temp.lu('t09'),
  'transition 18 : modele d''un refus, reprise aujourd''hui ou infinie, motif de blancs : refus nommes, 0 ecriture');
SELECT pg_temp.garde('pa09', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('09'), 'Motif interne L2A2 de la pause', 'pause_attente_besoin',
    ((now() AT TIME ZONE 'UTC')::date + 14), 1, 'cle-pause-09')$$));
SELECT pg_temp.vrai(pg_temp.lu('pa09') -> 'candidature' @> jsonb_build_object('enPause', true,
    'pauseModele', 'pause_attente_besoin', 'repriseLe', ((now() AT TIME ZONE 'UTC')::date + 14), 'etat', 'en_examen',
    'version', 2)
  AND EXISTS (SELECT 1 FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('09') AND type = 'pause'
               AND motif_interne = 'Motif interne L2A2 de la pause'
               AND details @> jsonb_build_object('geste', 'mettre_en_pause', 'transition', 18, 'aNotifier', 'pause_posee',
                 'modele', 'pause_attente_besoin',
                 'changements', jsonb_build_object('reprise_le', jsonb_build_object('avant', NULL,
                   'apres', ((now() AT TIME ZONE 'UTC')::date + 14))))),
  'transition 18 (pose) : pause, modele, reprise ; changement trace avant et apres ; marqueur pause_posee');
SELECT pg_temp.garde('d09', pg_temp.en(pg_temp.p('09'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.vrai(pg_temp.lu('d09') -> 'candidature' @> '{"enPause": true, "pauseModele": "pause_attente_besoin"}'::jsonb
  AND pg_temp.lu('d09')::text NOT LIKE '%Motif interne%',
  'le candidat lit le modele de la pause et sa reprise, jamais le motif');

SELECT pg_temp.garde('t09', pg_temp.trace(pg_temp.c('09')));
DO $l2_9$
DECLARE
  q text;
  v jsonb;
  n integer := 0;
BEGIN
  FOREACH q IN ARRAY ARRAY[
      $$SELECT public.demander_complement_candidat(pg_temp.c('09'), ARRAY['langues'], 'Motif', 2, 'cle-l2-9-0001')$$,
      $$SELECT public.admettre_salle_verification(pg_temp.c('09'), 2, 'cle-l2-9-0002')$$,
      $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('09'), 'virement_bancaire', NULL, 2, 'cle-l2-9-0003')$$,
      $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('09'), 'virement_bancaire', NULL, 'Motif', 2, 'cle-l2-9-0004')$$,
      $$SELECT public.definir_responsable_candidat(pg_temp.c('09'), pg_temp.p('a5'), 2, 'cle-l2-9-0005')$$,
      $$SELECT public.mettre_en_pause_candidat(pg_temp.c('09'), 'Motif', 'pause_general', NULL, 2, 'cle-l2-9-0006')$$] LOOP
    n := n + 1;
    v := pg_temp.en(pg_temp.p('a1'), 'admin', q);
    PERFORM pg_temp.vrai(v @> '{"erreur": "transition_interdite", "enPause": true, "raison": "pause"}'::jsonb
      AND pg_temp.trace(pg_temp.c('09')) = pg_temp.lu('t09'),
      'L2-9 : en pause, ' || split_part(split_part(q, '(', 1), '.', 2) || ' refuse (raison pause), 0 ecriture');
  END LOOP;
END $l2_9$;
SELECT pg_temp.garde('lv09', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lever_pause_candidat(pg_temp.c('09'), 2, 'cle-levee-09')$$));
SELECT pg_temp.garde('lv09b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lever_pause_candidat(pg_temp.c('09'), 3, 'cle-levee-09-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('lv09') -> 'candidature' @> '{"enPause": false, "pauseModele": null, "repriseLe": null,
    "etat": "en_examen", "version": 3}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('09') AND type = 'reprise'
               AND motif_interne IS NULL AND details @> '{"geste": "lever_pause", "aNotifier": "pause_levee"}'::jsonb)
  AND pg_temp.lu('lv09b') @> '{"erreur": "transition_interdite", "enPause": false}'::jsonb,
  'transition 18 (levee) : sans motif, pause, modele et reprise leves ; marqueur pause_levee ; seconde levee refusee');

-- ------------------------------------------------------------
-- (i) Transition 19 : rouvrir, controles de l'etape (L2-17)
-- ------------------------------------------------------------
SELECT pg_temp.garde('t10', pg_temp.trace(pg_temp.c('10')));
SELECT pg_temp.garde('ro10a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('10'), NULL, 2, 'cle-rouvrir-10-a')$$));
SELECT pg_temp.garde('ro10', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('10'), 'Motif interne L2A2 de reouverture', 2, 'cle-rouvrir-10')$$));
SELECT pg_temp.vrai(pg_temp.lu('ro10a') = '{"erreur": "motif_requis", "geste": "rouvrir"}'::jsonb
  AND pg_temp.lu('ro10') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "paiement_compatible", "cause": "inconnu"}, {"nom": "cadre_religieux", "cause": "non_accepte"},
    {"nom": "questionnaire_complet", "cause": "absent"}]}'::jsonb
  AND pg_temp.trace(pg_temp.c('10')) = pg_temp.lu('t10'),
  'L2-17 : rouvrir en salle 2 sans paiement, sans cadre, sans questionnaire envoye : trois controles nommes, 0 ecriture');
SELECT pg_temp.garde('t14', pg_temp.trace(pg_temp.c('14')));
SELECT pg_temp.garde('ro14', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('14'), 'Motif', 1, 'cle-rouvrir-14')$$));
SELECT pg_temp.garde('t31', pg_temp.trace(pg_temp.c('31')));
SELECT pg_temp.garde('ro31', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('31'), 'Motif', 1, 'cle-rouvrir-31')$$));
SELECT pg_temp.vrai(pg_temp.lu('ro14') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "compte_conforme", "cause": "statut"}]}'::jsonb
  AND pg_temp.lu('ro31') = '{"erreur": "controles_non_satisfaits", "controles": [
    {"nom": "questionnaire_complet", "cause": "perime"}]}'::jsonb
  AND pg_temp.trace(pg_temp.c('14')) = pg_temp.lu('t14') AND pg_temp.trace(pg_temp.c('31')) = pg_temp.lu('t31'),
  'L2-17 : compte desactive (regle de CAND-L1B nommee, jamais levee) ; questionnaire envoye a une version perimee : refus nommes, 0 ecriture');
SELECT pg_temp.garde('t11', pg_temp.trace(pg_temp.c('11')));
SELECT pg_temp.garde('ro11', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('11'), 'Motif interne L2A2 de reouverture', 1, 'cle-rouvrir-11')$$));
SELECT pg_temp.vrai(pg_temp.lu('ro11') -> 'candidature' @> '{"issue": "en_cours", "etape": "prequalification",
    "etat": "en_examen", "refusModele": null, "paiement": "a_verifier"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('11') AND type = 'transition' AND issue_avant = 'refusee'
          AND issue_apres = 'en_cours' AND motif_interne = 'Motif interne L2A2 de reouverture'
          AND details @> '{"geste": "rouvrir", "transition": 19, "issueAvant": "refusee", "refusModeleAvant": "refus_general",
                           "controles": [{"nom": "compte_conforme", "valeur": true},
                                         {"nom": "questionnaire_complet", "valeur": true}]}'::jsonb) = 1
  AND (pg_temp.trace(pg_temp.c('11')) ->> 'audit')::int = (pg_temp.lu('t11') ->> 'audit')::int + 1,
  'transition 19 : rouverte a l''etape et a l''etat d''origine, modele du refus efface, controles vrais traces, 1 ligne audit_logs');
SELECT pg_temp.garde('ro12', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('12'), 'Motif', 1, 'cle-rouvrir-12')$$));
SELECT pg_temp.garde('ro13', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('13'), 'Motif', 1, 'cle-rouvrir-13')$$));
SELECT pg_temp.garde('ro11b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('11'), 'Motif', 2, 'cle-rouvrir-11-b')$$));
SELECT pg_temp.vrai(pg_temp.lu('ro12') -> 'candidature' @> '{"issue": "en_cours", "etat": "paiement_non_disponible",
    "paiement": "incompatible"}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('12')
               AND type = 'transition' AND details ->> 'transition' = '8' AND details ->> 'cause' = 'reouverture')
  AND pg_temp.lu('ro13') -> 'candidature' @> '{"issue": "en_cours", "etat": "a_completer"}'::jsonb
  AND pg_temp.lu('ro11b') @> '{"erreur": "transition_interdite", "issue": "en_cours", "raison": "etat"}'::jsonb,
  'reouverture : depuis l''Afrique, le paiement recalcule mene a la transition 8 ; retiree a completer rouverte ; une candidature en cours ne se rouvre pas');

-- ------------------------------------------------------------
-- (j) Transition 28 : responsable du meme cote
-- ------------------------------------------------------------
SELECT pg_temp.garde('t28', pg_temp.trace(pg_temp.c('28')));
SELECT pg_temp.garde('rs28a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('28'), pg_temp.p('a2'), 1, 'cle-responsable-28-a')$$));
SELECT pg_temp.garde('rs28b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('28'), pg_temp.p('b1'), 1, 'cle-responsable-28-b')$$));
SELECT pg_temp.garde('rs28c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('28'), pg_temp.p('a3'), 1, 'cle-responsable-28-c')$$));
SELECT pg_temp.vrai(pg_temp.lu('rs28a') = '{"erreur": "responsable_invalide"}'::jsonb
  AND pg_temp.lu('rs28b') = '{"erreur": "responsable_invalide"}'::jsonb
  AND pg_temp.lu('rs28c') = '{"erreur": "responsable_invalide"}'::jsonb
  AND pg_temp.trace(pg_temp.c('28')) = pg_temp.lu('t28'),
  'transition 28 : responsable de l''autre cote, hors de la direction ou au genre inconnu : responsable_invalide rendu, 0 ecriture');
SELECT pg_temp.garde('rs28', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('28'), pg_temp.p('a5'), 1, 'cle-responsable-28')$$));
SELECT pg_temp.garde('rs28r', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('28'), pg_temp.p('a5'), 1, 'cle-responsable-28')$$));
SELECT pg_temp.garde('rs28n', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('28'), NULL, 2, 'cle-responsable-28-n')$$));
SELECT pg_temp.vrai(pg_temp.lu('rs28') #>> '{candidature,responsableId}' = pg_temp.p('a5')::text
  AND pg_temp.lu('rs28r') = (pg_temp.lu('rs28') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('rs28n') #> '{candidature,responsableId}' = 'null'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('28') AND type = 'responsable'
         AND details ? 'changements') = 2
  AND (SELECT responsable_id IS NULL AND version = 3 FROM public.candidatures WHERE id = pg_temp.c('28')),
  'transition 28 : responsable du meme cote pose, rejeu sans effet, puis retire ; avant et apres traces');

-- ------------------------------------------------------------
-- (k) Portee par genre de chaque geste (C4 de CAND-L2A1)
-- ------------------------------------------------------------
SELECT pg_temp.garde('t06', pg_temp.trace(pg_temp.c('06')));
DO $portee$
DECLARE
  q text;
  a record;
  v jsonb;
  n integer := 0;
BEGIN
  FOR a IN SELECT * FROM (VALUES (pg_temp.p('a1'), 'direction homme'), (pg_temp.p('a4'), 'super-admin homme'))
           AS t(id, nom) LOOP
    FOREACH q IN ARRAY ARRAY[
        $$SELECT public.demander_complement_candidat(pg_temp.c('06'), ARRAY['langues'], 'Motif', 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.admettre_salle_verification(pg_temp.c('06'), 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.refuser_candidat(pg_temp.c('06'), 'Motif', 'refus_general', 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.mettre_en_pause_candidat(pg_temp.c('06'), 'Motif', 'pause_general', NULL, 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.lever_pause_candidat(pg_temp.c('06'), 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.consigner_retrait_candidat(pg_temp.c('06'), 'courriel', (now() AT TIME ZONE 'UTC')::date, 'Motif', 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.rouvrir_candidat(pg_temp.c('06'), 'Motif', 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.definir_responsable_candidat(pg_temp.c('06'), NULL, 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('06'), 'virement_bancaire', NULL, 1, 'cle-hp-' || md5(random()::text))$$,
        $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('06'), 'virement_bancaire', NULL, 'Motif', 1, 'cle-hp-' || md5(random()::text))$$] LOOP
      n := n + 1;
      v := pg_temp.en(a.id, 'admin', q);
      PERFORM pg_temp.vrai(v = '{"erreur": "hors_portee"}'::jsonb,
        'hors portee (' || a.nom || ') : ' || split_part(split_part(q, '(', 1), '.', 2));
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai(n = 20, 'vingt gestes de l''autre cote, super-admin compris');
END $portee$;
SELECT pg_temp.vrai((pg_temp.trace(pg_temp.c('06')) ->> 'ligne') = pg_temp.lu('t06') ->> 'ligne'
  AND (pg_temp.trace(pg_temp.c('06')) ->> 'decisions') = pg_temp.lu('t06') ->> 'decisions'
  AND (pg_temp.trace(pg_temp.c('06')) ->> 'gestes') = pg_temp.lu('t06') ->> 'gestes'
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('06') AND type = 'lecture_hors_portee') = 20
  AND (SELECT count(*) FROM public.audit_logs
        WHERE row_id = pg_temp.c('06')::text AND action = 'candidature_hors_portee'
          AND payload ->> 'lecture' LIKE 'geste:%') = 20
  AND (SELECT count(DISTINCT payload ->> 'lecture') FROM public.audit_logs
        WHERE row_id = pg_temp.c('06')::text AND action = 'candidature_hors_portee') = 10,
  'hors portee : candidature intacte, 0 cle, 0 decision ; chaque tentative tracee comme une lecture hors portee, geste nomme');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin', $$SELECT public.refuser_candidat(pg_temp.c('06'), 'Motif',
  'refus_general', 1, 'cle-a3-refus-06')$$, '42501', 'direction au genre inconnu : aucun geste (42501)');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin', $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('06')])$$,
  '42501', 'direction au genre inconnu : aucun lot (42501)');
SELECT pg_temp.garde('pa06', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('06'), 'Motif', 'pause_demande_candidat', NULL, 1, 'cle-pause-06')$$));
SELECT pg_temp.vrai(pg_temp.lu('pa06') -> 'candidature' @> '{"enPause": true, "pauseModele": "pause_demande_candidat"}'::jsonb,
  'la direction du meme cote agit : la direction femme met en pause la candidate');

-- ------------------------------------------------------------
-- (l) Action groupee (ADM-22) : L2-7, jeton, nombre, rejeu, isolement
-- ------------------------------------------------------------
SELECT pg_temp.garde('lot10', to_jsonb(ARRAY[pg_temp.c('17'), pg_temp.c('18'), pg_temp.c('19'), pg_temp.c('20'),
  pg_temp.c('21'), pg_temp.c('22'), pg_temp.c('23'), pg_temp.c('24'), pg_temp.c('25'), pg_temp.c('26')]));
CREATE FUNCTION pg_temp.ids(p_nom text) RETURNS uuid[]
LANGUAGE sql AS $$ SELECT ARRAY(SELECT x::uuid FROM jsonb_array_elements_text(pg_temp.lu(p_nom)) x) $$;
GRANT EXECUTE ON FUNCTION pg_temp.ids(text) TO authenticated;
CREATE FUNCTION pg_temp.traces(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT jsonb_agg(pg_temp.trace(x) ORDER BY x) FROM unnest(pg_temp.ids(p_nom)) x $$;

DO $non_groupable$
DECLARE
  g text;
BEGIN
  FOREACH g IN ARRAY ARRAY['inviter', 'consigner_prevenu', 'admettre_verifications', 'demander_complement', 'rouvrir',
                           'confirmer_moyen_paiement', 'geste_inconnu'] LOOP
    PERFORM pg_temp.vrai(pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
        $$SELECT public.apercu_lot_candidats(%L, pg_temp.ids('lot10'))$$, g))
        = jsonb_build_object('erreur', 'geste_non_groupable', 'geste', g)
      AND pg_temp.en(pg_temp.p('a1'), 'admin', pg_catalog.format(
        $$SELECT public.executer_lot_candidats(%L, pg_temp.ids('lot10'), md5('x'), 7, 'cle-lot-ng-' || %L, 'Motif', NULL)$$, g, g))
        = jsonb_build_object('erreur', 'geste_non_groupable', 'geste', g),
      'geste_non_groupable (apercu et execution) : ' || g);
  END LOOP;
END $non_groupable$;

SELECT pg_temp.garde('tr_lot10', pg_temp.traces('lot10'));
SELECT pg_temp.garde('ap1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', pg_temp.ids('lot10') || pg_temp.c('17'))$$));
SELECT pg_temp.vrai(pg_temp.lu('ap1') ->> 'nombre' = '7' AND pg_temp.lu('ap1') ->> 'jeton' ~ '^[0-9a-f]{32}$'
  AND jsonb_array_length(pg_temp.lu('ap1') -> 'eligibles') = 7
  AND jsonb_array_length(pg_temp.lu('ap1') -> 'exclus') = 3
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('ap1') -> 'exclus') e
                   WHERE e ->> 'raison' <> 'transition_interdite' OR e ->> 'detail' <> 'etat' OR e ->> 'issue' <> 'refusee')
  AND (SELECT bool_and(e ? 'nomComplet' AND e ? 'reference' AND e ? 'version' AND NOT e ? 'paysResidence')
         FROM jsonb_array_elements(pg_temp.lu('ap1') -> 'eligibles') e)
  AND pg_temp.lu('ap1') -> 'effet' = '{"en_pause": true}'::jsonb
  AND pg_temp.lu('ap1') @> '{"motifRequis": true, "modeleRequis": true}'::jsonb
  AND pg_temp.traces('lot10') = pg_temp.lu('tr_lot10'),
  'apercu de 10 pauses dont 3 refusees (et un doublon) : 7 eligibles nommes, 3 exclus avec raison, effet, jeton, 0 ecriture');

SELECT pg_temp.garde('ex1a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap1') ->> 'jeton', 6,
    'cle-lot-pause-1', 'Motif interne L2A2 du lot', 'pause_attente_besoin')$$));
SELECT pg_temp.garde('ex1b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), md5('jeton invente'), 7,
    'cle-lot-pause-1', 'Motif interne L2A2 du lot', 'pause_attente_besoin')$$));
SELECT pg_temp.garde('ex1c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap1') ->> 'jeton', 7,
    'cle-lot-pause-1', '   ', 'pause_attente_besoin')$$));
SELECT pg_temp.garde('ex1d', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap1') ->> 'jeton', 7,
    'cle-lot-pause-1', 'Motif', NULL)$$));
SELECT pg_temp.garde('ex1e', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap1') ->> 'jeton', 7,
    'cle-lot-pause-1', 'Motif', 'refus_general')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex1a') = '{"erreur": "nombre_discordant", "nombre": 7}'::jsonb
  AND pg_temp.lu('ex1b') = '{"erreur": "jeton_perime"}'::jsonb
  AND pg_temp.lu('ex1c') = '{"erreur": "motif_requis", "geste": "mettre_en_pause"}'::jsonb
  AND pg_temp.lu('ex1d') = '{"erreur": "modele_requis", "geste": "mettre_en_pause"}'::jsonb
  AND pg_temp.lu('ex1e') = '{"erreur": "modele_inconnu", "geste": "mettre_en_pause"}'::jsonb
  AND pg_temp.traces('lot10') = pg_temp.lu('tr_lot10')
  AND (SELECT count(*) FROM public.candidature_lots) = 0,
  'execution : nombre discordant, jeton invente, motif de blancs, modele absent ou hors liste : rien n''est ecrit');
-- Le jeton d'un autre auteur : la direction femme reprend le jeton de la
-- direction homme sur les memes dix identifiants, qui sont de l'autre cote
-- pour elle. Jeton perime, rien d'ecrit sur les candidatures, mais chacune
-- laisse sa trace (CAND-L2A2, D16 : la trace ne depend pas du refus rendu).
SELECT pg_temp.garde('tr_avant_f', pg_temp.traces('lot10'));
SELECT pg_temp.garde('ex1f', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap1') ->> 'jeton', 7,
    'cle-lot-pause-1', 'Motif', 'pause_attente_besoin')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex1f') = '{"erreur": "jeton_perime"}'::jsonb
  AND (SELECT bool_and(
         (a ->> 'ligne') = (b ->> 'ligne') AND (a ->> 'gestes') = (b ->> 'gestes')
         AND (a ->> 'decisions') = (b ->> 'decisions') AND (a ->> 'reponses') = (b ->> 'reponses')
         AND (b ->> 'evenements')::int = (a ->> 'evenements')::int + 1
         AND (b ->> 'audit')::int = (a ->> 'audit')::int + 1)
         FROM jsonb_array_elements(pg_temp.lu('tr_avant_f')) WITH ORDINALITY AS x(a, o)
         JOIN jsonb_array_elements(pg_temp.traces('lot10')) WITH ORDINALITY AS y(b, o2) ON o = o2)
  AND (SELECT count(*) FROM public.candidature_lots) = 0,
  'execution par la direction de l''autre cote avec le jeton d''un autre auteur : jeton_perime, rien d''ecrit, mais une trace par candidature (evenement et ligne d''audit)');

-- Le lot change depuis l'apercu (18 recoit un responsable) : jeton perime.
SELECT pg_temp.garde('rs18', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.definir_responsable_candidat(pg_temp.c('18'), pg_temp.p('a1'), 1, 'cle-responsable-18')$$));
SELECT pg_temp.garde('tr_lot10', pg_temp.traces('lot10'));
SELECT pg_temp.garde('ex1g', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap1') ->> 'jeton', 7,
    'cle-lot-pause-1', 'Motif', 'pause_attente_besoin')$$));
SELECT pg_temp.vrai(pg_temp.lu('rs18') #>> '{candidature,version}' = '2'
  AND pg_temp.lu('ex1g') = '{"erreur": "jeton_perime"}'::jsonb
  AND pg_temp.traces('lot10') = pg_temp.lu('tr_lot10'),
  'une candidature du lot a change depuis l''apercu : jeton_perime, 0 ecriture');

SELECT pg_temp.garde('ap2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'))$$));
SELECT pg_temp.garde('ex1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap2') ->> 'jeton', 7,
    'cle-lot-pause-1', 'Motif interne L2A2 du lot', 'pause_attente_besoin',
    ((now() AT TIME ZONE 'UTC')::date + 30))$$));
SELECT pg_temp.vrai(pg_temp.lu('ap2') ->> 'jeton' <> pg_temp.lu('ap1') ->> 'jeton'
  AND pg_temp.lu('ex1') @> '{"rejoue": false, "geste": "mettre_en_pause", "nombre": 7, "reussies": 7, "exclues": 3,
      "refusees": 0}'::jsonb
  AND jsonb_array_length(pg_temp.lu('ex1') -> 'lignes') = 10
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('ex1') -> 'lignes') l
        WHERE l ->> 'issue' = 'exclue' AND l ->> 'raison' = 'transition_interdite' AND l ->> 'detail' = 'etat'
          AND l ->> 'id' IN (pg_temp.c('24')::text, pg_temp.c('25')::text, pg_temp.c('26')::text)) = 3
  AND (SELECT count(*) FROM public.candidatures
        WHERE id = ANY (pg_temp.ids('lot10')) AND en_pause AND pause_modele = 'pause_attente_besoin'
          AND reprise_le = (now() AT TIME ZONE 'UTC')::date + 30) = 7
  AND (SELECT jsonb_agg(t ORDER BY o) FROM jsonb_array_elements(pg_temp.traces('lot10')) WITH ORDINALITY AS x(t, o) WHERE o > 7)
    = (SELECT jsonb_agg(t ORDER BY o) FROM jsonb_array_elements(pg_temp.lu('tr_lot10')) WITH ORDINALITY AS x(t, o) WHERE o > 7),
  'L2-7 : lot de 10 pauses dont 3 refusees : 7 reussies, 3 exclues avec raison, 3 inchangees');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements e
                      WHERE e.candidature_id = ANY (pg_temp.ids('lot10')) AND e.type = 'pause'
                        AND e.motif_interne = 'Motif interne L2A2 du lot'
                        AND e.details @> jsonb_build_object('geste', 'mettre_en_pause', 'lot', md5('cle-lot-pause-1'),
                                                            'aNotifier', 'pause_posee')) = 7
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id IN (SELECT x::text FROM unnest(pg_temp.ids('lot10')) x)
          AND a.action = 'candidature_geste' AND a.payload ->> 'geste' = 'mettre_en_pause') = 7
  AND (SELECT count(*) FROM public.candidature_gestes WHERE cle LIKE 'lot-' || md5('cle-lot-pause-1') || '-%') = 7
  AND (SELECT count(*) FROM public.candidature_lots WHERE cle = 'cle-lot-pause-1' AND auteur_id = pg_temp.p('a1')) = 1,
  'chaque ligne passe seule par le moteur : 7 evenements marques du lot, 7 lignes audit_logs, 7 cles derivees, 1 rapport garde');
SELECT pg_temp.garde('tr_lot10', pg_temp.traces('lot10'));
SELECT pg_temp.garde('ex1r', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), md5('peu importe'), 0,
    'cle-lot-pause-1', 'Autre', 'pause_general')$$));
SELECT pg_temp.garde('ex1s', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', (pg_temp.ids('lot10'))[1:5], pg_temp.lu('ap2') ->> 'jeton', 5,
    'cle-lot-pause-1', 'Motif', 'pause_general')$$));
SELECT pg_temp.garde('ex1t', pg_temp.en(pg_temp.p('a5'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', pg_temp.ids('lot10'), pg_temp.lu('ap2') ->> 'jeton', 7,
    'cle-lot-pause-1', 'Motif', 'pause_general')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex1r') = (pg_temp.lu('ex1') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('ex1s') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('ex1t') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.traces('lot10') = pg_temp.lu('tr_lot10'),
  'L2-8 : lot rejoue avec sa cle, le premier rapport sans ecriture ; cle reprise pour d''autres candidatures ou par un autre auteur : refusee');

-- Lever la pause en lot, avec une candidate de l'autre cote et un
-- identifiant inconnu : exclus, sans donnee, la tentative hors portee tracee.
SELECT pg_temp.garde('lot_levee', to_jsonb((pg_temp.ids('lot10'))[1:7] || pg_temp.c('27')
                                             || 'ca2bdddd-0000-4000-8000-000000000000'::uuid));
SELECT pg_temp.garde('hp27', to_jsonb((SELECT count(*) FROM public.audit_logs
                                        WHERE row_id = pg_temp.c('27')::text AND action = 'candidature_hors_portee')));
SELECT pg_temp.garde('ap3', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('lever_pause', pg_temp.ids('lot_levee'))$$));
SELECT pg_temp.garde('ex3', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('lever_pause', pg_temp.ids('lot_levee'), pg_temp.lu('ap3') ->> 'jeton', 7,
    'cle-lot-levee-1')$$));
SELECT pg_temp.vrai(pg_temp.lu('ap3') @> '{"nombre": 7, "motifRequis": false, "modeleRequis": false}'::jsonb
  AND pg_temp.lu('ap3') -> 'exclus' = jsonb_build_array(
        jsonb_build_object('id', pg_temp.c('27'), 'raison', 'hors_portee'),
        jsonb_build_object('id', 'ca2bdddd-0000-4000-8000-000000000000', 'raison', 'absente'))
  AND pg_temp.lu('ex3') @> '{"reussies": 7, "exclues": 2, "refusees": 0}'::jsonb
  AND (SELECT count(*) FROM public.candidatures WHERE id = ANY ((pg_temp.ids('lot10'))[1:7]) AND NOT en_pause) = 7
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = pg_temp.c('27')::text AND action = 'candidature_hors_portee'
         AND payload ->> 'lecture' = 'lot:lever_pause') = 2
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = pg_temp.c('27')::text AND action = 'candidature_hors_portee')
      = pg_temp.lu('hp27')::int + 2
  AND (SELECT en_pause = false AND version = 1 FROM public.candidatures WHERE id = pg_temp.c('27'))
  AND pg_temp.lu('ap3')::text NOT LIKE '%Fixture L2A2 27%',
  'lever la pause en lot : 7 reussies ; une candidate de l''autre cote et un identifiant inconnu exclus sans donnee, la tentative tracee a l''apercu et a l''execution');

-- Refuser en lot : une ligne refusee par le moteur (cle derivee deja prise)
-- et une ligne en erreur n'annulent pas la reussite voisine.
INSERT INTO public.candidature_gestes (cle, candidature_id, geste, auteur_id, resultat)
VALUES ('lot-' || md5('cle-lot-refus-1') || '-' || pg_temp.c('18'), pg_temp.c('20'), 'refuser', pg_temp.p('a1'),
        '{"essai": true}');
CREATE FUNCTION pg_temp.boum() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'erreur provoquee par le scenario' USING ERRCODE = 'P0001'; END $$;
CREATE TRIGGER cand_l2a2_boum BEFORE UPDATE ON public.candidatures
  FOR EACH ROW WHEN (OLD.reference IS NOT NULL AND OLD.id = 'ca2bcccc-0000-4000-8000-000000000019'::uuid)
  EXECUTE FUNCTION pg_temp.boum();
SELECT pg_temp.garde('lot_refus', to_jsonb(ARRAY[pg_temp.c('17'), pg_temp.c('18'), pg_temp.c('19')]));
SELECT pg_temp.garde('tr_refus', pg_temp.traces('lot_refus'));
SELECT pg_temp.garde('ap4', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', pg_temp.ids('lot_refus'))$$));
SELECT pg_temp.garde('ex4', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('refuser', pg_temp.ids('lot_refus'), pg_temp.lu('ap4') ->> 'jeton', 3,
    'cle-lot-refus-1', 'Motif interne L2A2 du refus en lot', 'refus_besoins')$$));
DROP TRIGGER cand_l2a2_boum ON public.candidatures;
SELECT pg_temp.vrai(pg_temp.lu('ex4') @> '{"nombre": 3, "reussies": 1, "exclues": 0, "refusees": 2}'::jsonb
  AND pg_temp.lu('ex4') -> 'lignes' = jsonb_build_array(
        jsonb_build_object('id', pg_temp.c('17'), 'reference', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('17')),
                           'issue', 'reussie',
                           'candidature', private.candidature_etat_direction(pg_temp.c('17'))),
        jsonb_build_object('id', pg_temp.c('18'), 'reference', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('18')),
                           'issue', 'refusee', 'raison', 'cle_idempotence_reutilisee'),
        jsonb_build_object('id', pg_temp.c('19'), 'reference', (SELECT reference FROM public.candidatures WHERE id = pg_temp.c('19')),
                           'issue', 'refusee', 'raison', 'erreur_serveur', 'code', 'P0001'))
  AND (SELECT issue = 'refusee' AND issue_modele = 'refus_besoins' FROM public.candidatures WHERE id = pg_temp.c('17'))
  AND (SELECT jsonb_agg(t ORDER BY o) FROM jsonb_array_elements(pg_temp.traces('lot_refus')) WITH ORDINALITY AS x(t, o) WHERE o > 1)
    = (SELECT jsonb_agg(t ORDER BY o) FROM jsonb_array_elements(pg_temp.lu('tr_refus')) WITH ORDINALITY AS x(t, o) WHERE o > 1),
  'chaque ligne seule : un refus du moteur et une erreur n''annulent jamais la reussite voisine ; les deux lignes refusees sont inchangees');

-- Rien de garde sous une cle ne porte une reponse, un nom ou un motif.
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_gestes WHERE candidature_id::text LIKE 'ca2bcccc%') > 20
  AND NOT EXISTS (SELECT 1 FROM public.candidature_gestes g
                   WHERE g.candidature_id::text LIKE 'ca2bcccc%'
                     AND (jsonb_path_exists(g.resultat, 'lax $.**.reponses')
                          OR jsonb_path_exists(g.resultat, 'lax $.**.paysResidence')
                          OR jsonb_path_exists(g.resultat, 'lax $.**.nomComplet')
                          OR g.resultat::text LIKE '%Motif%' OR g.resultat::text LIKE '%Fixture%'))
  AND NOT EXISTS (SELECT 1 FROM public.candidature_lots l
                   WHERE jsonb_path_exists(l.resultat, 'lax $.**.nomComplet')
                      OR jsonb_path_exists(l.resultat, 'lax $.**.reponses')
                      OR l.resultat::text LIKE '%Motif%' OR l.resultat::text LIKE '%Fixture%'),
  'conservation : aucun resultat garde (gestes, lots) ne porte une reponse, un nom ni un motif (CAND-Q21)');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $$SELECT count(*) FROM public.candidature_lots$$, '42501',
  'la direction ne lit pas la table des lots (RPC seulement)');

-- ------------------------------------------------------------
-- (m) L2-10 : chaque geste a motif, sans motif ou avec des blancs
-- ------------------------------------------------------------
SELECT pg_temp.cand(s, 'male', CASE WHEN s = '45' THEN 'verifications' ELSE 'prequalification' END,
                    CASE WHEN s = '45' THEN 'entretien_a_planifier' ELSE 'en_examen' END,
                    CASE WHEN s = '44' THEN 'refusee' ELSE 'en_cours' END, s = '43', pg_temp.lu('complet_sa'))
FROM unnest(ARRAY['41', '42', '43', '44', '45']) AS s;
DO $l2_10$
DECLARE
  v record;
  m text;
  r jsonb;
  t jsonb;
  n integer := 0;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('41', 'demander_complement', $$SELECT public.demander_complement_candidat(pg_temp.c('41'), ARRAY['langues'], %L, 1, %L)$$),
      ('45', 'demander_complement', $$SELECT public.demander_complement_candidat(pg_temp.c('45'), ARRAY['contrat'], %L, 1, %L)$$),
      ('41', 'refuser', $$SELECT public.refuser_candidat(pg_temp.c('41'), %L, 'refus_general', 1, %L)$$),
      ('41', 'retirer', $$SELECT public.consigner_retrait_candidat(pg_temp.c('41'), 'courriel', (now() AT TIME ZONE 'UTC')::date, %L, 1, %L)$$),
      ('42', 'mettre_en_pause', $$SELECT public.mettre_en_pause_candidat(pg_temp.c('42'), %L, 'pause_general', NULL, 1, %L)$$),
      ('44', 'rouvrir', $$SELECT public.rouvrir_candidat(pg_temp.c('44'), %L, 1, %L)$$),
      ('42', 'infirmer_moyen_paiement', $$SELECT public.infirmer_moyen_paiement_candidat(pg_temp.c('42'), 'virement_bancaire', NULL, %L, 1, %L)$$))
      AS x(n, geste, q) LOOP
    t := pg_temp.trace(pg_temp.c(v.n));
    FOREACH m IN ARRAY ARRAY[NULL, '   ', E'\t\n\r', chr(160) || chr(8203) || chr(12288)] LOOP
      n := n + 1;
      r := pg_temp.en(pg_temp.p('a1'), 'admin', format(v.q, m, 'cle-l2-10-' || n || '-' || md5(random()::text)));
      PERFORM pg_temp.vrai(r = jsonb_build_object('erreur', 'motif_requis', 'geste', v.geste)
        AND pg_temp.trace(pg_temp.c(v.n)) = t,
        'L2-10 : ' || v.geste || ' (' || v.n || ') sans motif ou fait de blancs : motif_requis, 0 ecriture');
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai(n = 28, 'L2-10 : sept gestes a motif, quatre motifs vides chacun');
END $l2_10$;
-- 43 est en pause : la pause l'emporte sur le motif (raison pause, pas de
-- fuite de la regle de motif).
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('a1'), 'admin',
    $$SELECT public.demander_complement_candidat(pg_temp.c('43'), ARRAY['langues'], NULL, 1, 'cle-l2-10-pause')$$)
    @> '{"erreur": "transition_interdite", "raison": "pause"}'::jsonb,
  'en pause et sans motif : transition_interdite (raison pause) d''abord');

-- ------------------------------------------------------------
-- (o) Relecture du 22/10 : traces des lots (D16), jeton (D17), vocabulaire
-- (D18), reouverture et paiement (D19), fin d'un complement (D20), dossier
-- (D21), entretien planifie (D22)
-- ------------------------------------------------------------
-- a6 : seconde direction homme, dont le genre change dans ce bloc. 51 a 59 :
-- candidatures neuves ; 53 et 54 declarent un mobile money d'Arabie saoudite
-- sans ligne confirmee, 55 un autre ; 56 est en entretien planifie, paiement
-- compatible, cadre accepte.
INSERT INTO auth.users (id, email) VALUES (pg_temp.p('a6'), 'cand-l2a2-a6@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a6'), 'CA2B-ADM-0006', 'admin', 'Sixieme', 'Direction', 'active', 'male');
SELECT pg_temp.cand(s, 'male', 'prequalification', 'a_completer', 'en_cours', false, NULL)
FROM unnest(ARRAY['51', '52', '57', '58', '59']) AS s;
SELECT pg_temp.cand('53', 'male', 'prequalification', 'paiement_non_disponible', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"compteBancaire": false, "operateurs": ["orange_money"]}'::jsonb);
SELECT pg_temp.cand('54', 'male', 'prequalification', 'paiement_non_disponible', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"compteBancaire": false, "operateurs": ["orange_money"]}'::jsonb);
SELECT pg_temp.cand('55', 'male', 'prequalification', 'paiement_non_disponible', 'refusee', false,
  pg_temp.lu('complet_sa') || '{"compteBancaire": false, "operateurs": ["moov_money"]}'::jsonb);
SELECT pg_temp.cand('56', 'male', 'verifications', 'entretien_planifie', 'en_cours', false, pg_temp.lu('complet_sa'));
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES (pg_temp.p('56'), 'teacher_religious_framework', 'test-cadre-1');
INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, operateur, decision, auteur_id)
VALUES (pg_temp.c('56'), 'SA', 'virement_bancaire', NULL, 'confirme', pg_temp.p('a1'));
UPDATE public.candidatures SET paiement = private.paiement_etat(id) WHERE id = pg_temp.c('56');
SELECT pg_temp.vrai((SELECT array_agg(paiement ORDER BY id) FROM public.candidatures
                      WHERE id IN (pg_temp.c('53'), pg_temp.c('54'), pg_temp.c('55'), pg_temp.c('56')))
    = ARRAY['incompatible', 'incompatible', 'incompatible', 'compatible'],
  'relecture, fixtures : 53, 54 et 55 sans moyen qui croise une ligne confirmee, 56 compatible');

-- Les traces d'une candidature de l'autre cote : evenements et lignes d'audit.
CREATE FUNCTION pg_temp.hp(p_id uuid) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'evenements', (SELECT count(*) FROM public.candidature_evenements e
                    WHERE e.candidature_id = p_id AND e.type = 'lecture_hors_portee'),
    'audit', (SELECT count(*) FROM public.audit_logs a
               WHERE a.row_id = p_id::text AND a.action = 'candidature_hors_portee'));
$$;
CREATE FUNCTION pg_temp.v(p_n text) RETURNS integer
LANGUAGE sql SECURITY DEFINER AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n) $$;
GRANT EXECUTE ON FUNCTION pg_temp.v(text) TO authenticated;

-- (o1) D16 : un identifiant de l'autre cote laisse sa trace des l'entree dans
-- l'apercu ou l'execution, quel que soit le refus rendu ensuite (finding 1 de
-- la relecture : motif, modele, date, jeton, cle, geste non groupable).
SELECT pg_temp.garde('t06', pg_temp.trace(pg_temp.c('06')));
SELECT pg_temp.garde('hp06', pg_temp.hp(pg_temp.c('06')));
SELECT pg_temp.garde('lots_av', to_jsonb((SELECT count(*) FROM public.candidature_lots)));
DO $o1$
DECLARE
  v record;
  r jsonb;
  b jsonb;
  n integer := 0;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('a1', $$SELECT public.executer_lot_candidats('inviter', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-inviter-1')$$,
        '{"erreur": "geste_non_groupable", "geste": "inviter"}'::jsonb, 'executer, geste non groupable'),
      ('a1', $$SELECT public.apercu_lot_candidats('inviter', ARRAY[pg_temp.c('06')])$$,
        '{"erreur": "geste_non_groupable", "geste": "inviter"}'::jsonb, 'apercu, geste non groupable'),
      ('a1', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-motif-001', NULL, 'refus_general')$$,
        '{"erreur": "motif_requis", "geste": "refuser"}'::jsonb, 'motif absent'),
      ('a1', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-modele-01', 'Motif', NULL)$$,
        '{"erreur": "modele_requis", "geste": "refuser"}'::jsonb, 'modele absent'),
      ('a1', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-modele-02', 'Motif', 'refus_inexistant')$$,
        '{"erreur": "modele_inconnu", "geste": "refuser"}'::jsonb, 'modele hors liste'),
      ('a1', $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-date-0001', 'Motif', 'pause_general', current_date - 1)$$,
        '{"erreur": "date_reprise_invalide"}'::jsonb, 'date de reprise passee'),
      ('a1', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-jeton-001', 'Motif', 'refus_general')$$,
        '{"erreur": "jeton_perime"}'::jsonb, 'jeton invente'),
      ('a1', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')],
           md5(pg_temp.p('a1')::text || '|refuser||' || pg_temp.c('06')::text || ':hors_portee'), 0, 'cle-o1-jeton-002', 'Motif', 'refus_general')$$,
        '{"erreur": "jeton_perime"}'::jsonb, 'jeton calcule par le client (l''ancienne empreinte md5)'),
      ('a1', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06'), 'ca2bdddd-0000-4000-8000-000000000000'::uuid],
           md5('x'), 0, 'cle-o1-jeton-003', 'Motif', 'refus_general')$$,
        '{"erreur": "jeton_perime"}'::jsonb, 'identifiant inconnu a cote : meme reponse, aucun oracle'),
      ('a4', $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-jeton-004', 'Motif', 'refus_general')$$,
        '{"erreur": "jeton_perime"}'::jsonb, 'super-admin : aucune exception de lecture pour un geste'),
      ('a1', $$SELECT public.executer_lot_candidats('Robert''); DROP TABLE x;--', ARRAY[pg_temp.c('06')], md5('x'), 0, 'cle-o1-garbage-1')$$,
        '{"erreur": "geste_non_groupable", "geste": null}'::jsonb, 'geste mal forme : jamais recopie')
      ) AS t(qui, q, attendu, nom) LOOP
    b := pg_temp.hp(pg_temp.c('06'));
    r := pg_temp.en(pg_temp.p(v.qui), 'admin', v.q);
    n := n + 1;
    PERFORM pg_temp.vrai(r = v.attendu
      AND (pg_temp.hp(pg_temp.c('06')) ->> 'evenements')::int = (b ->> 'evenements')::int + 1
      AND (pg_temp.hp(pg_temp.c('06')) ->> 'audit')::int = (b ->> 'audit')::int + 1,
      'D16 : ' || v.nom || ' : ' || (r ->> 'erreur') || ', une trace (evenement et ligne d''audit) pour la candidate de l''autre cote');
  END LOOP;
  PERFORM pg_temp.vrai(n = 11, 'D16 : onze refus rendus avant la boucle, chacun trace');
END $o1$;
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs
                      WHERE row_id = pg_temp.c('06')::text AND action = 'candidature_hors_portee'
                        AND payload ->> 'lecture' = 'lot:inconnu') = 1
  AND (SELECT count(*) FROM public.audit_logs
        WHERE row_id = pg_temp.c('06')::text AND action = 'candidature_hors_portee'
          AND payload ->> 'lecture' = 'lot:inviter') = 2
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE row_id = pg_temp.c('06')::text AND payload::text LIKE '%DROP%')
  AND (pg_temp.trace(pg_temp.c('06')) ->> 'ligne') = pg_temp.lu('t06') ->> 'ligne'
  AND (pg_temp.trace(pg_temp.c('06')) ->> 'gestes') = pg_temp.lu('t06') ->> 'gestes'
  AND (SELECT count(*) FROM public.candidature_lots) = pg_temp.lu('lots_av')::int,
  'D16 : la trace nomme la lecture (lot:inviter, lot:inconnu pour un geste mal forme), jamais le texte recu ; candidate intacte, aucun rapport de lot garde');

-- Les refus qui demandent un jeton valide (nombre discordant, aucun
-- eligible) et la cle reprise : l'apercu, puis l'execution, tracent chacun.
SELECT pg_temp.garde('hp06', pg_temp.hp(pg_temp.c('06')));
SELECT pg_temp.garde('ap_o1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('06'), pg_temp.c('52')])$$));
SELECT pg_temp.garde('ex_o1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06'), pg_temp.c('52')],
    pg_temp.lu('ap_o1') ->> 'jeton', 5, 'cle-o1-nombre-01', 'Motif', 'refus_general')$$));
SELECT pg_temp.garde('ap_o2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('06')])$$));
SELECT pg_temp.garde('ex_o2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('06')],
    pg_temp.lu('ap_o2') ->> 'jeton', 0, 'cle-o1-vide-0001', 'Motif', 'refus_general')$$));
SELECT pg_temp.vrai(pg_temp.lu('ap_o1') ->> 'nombre' = '1'
  AND pg_temp.lu('ex_o1') = '{"erreur": "nombre_discordant", "nombre": 1}'::jsonb
  AND pg_temp.lu('ap_o2') ->> 'nombre' = '0'
  AND pg_temp.lu('ex_o2') = '{"erreur": "aucun_eligible"}'::jsonb
  AND (pg_temp.hp(pg_temp.c('06')) ->> 'evenements')::int = (pg_temp.lu('hp06') ->> 'evenements')::int + 4
  AND (pg_temp.hp(pg_temp.c('06')) ->> 'audit')::int = (pg_temp.lu('hp06') ->> 'audit')::int + 4
  AND (SELECT etat = 'a_completer' AND issue = 'en_cours' FROM public.candidatures WHERE id = pg_temp.c('52')),
  'D16 : apercu puis execution avec un jeton valide (nombre_discordant, aucun_eligible) : quatre traces pour la candidate de l''autre cote, 52 intacte');

-- Un lot execute, puis la cle reprise avec un identifiant de l'autre cote.
SELECT pg_temp.garde('hp06', pg_temp.hp(pg_temp.c('06')));
SELECT pg_temp.garde('ap_o3', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('51')])$$));
SELECT pg_temp.garde('ex_o3', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('51')], pg_temp.lu('ap_o3') ->> 'jeton', 1,
    'cle-o1-lot-00001', 'Motif interne L2A2 de relecture', 'pause_attente_besoin')$$));
SELECT pg_temp.garde('ex_o3b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('51'), pg_temp.c('06')], md5('x'), 1,
    'cle-o1-lot-00001', 'Motif', 'pause_general')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex_o3') @> '{"reussies": 1, "rejoue": false}'::jsonb
  AND pg_temp.lu('ex_o3b') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND (pg_temp.hp(pg_temp.c('06')) ->> 'evenements')::int = (pg_temp.lu('hp06') ->> 'evenements')::int + 1
  AND (pg_temp.hp(pg_temp.c('06')) ->> 'audit')::int = (pg_temp.lu('hp06') ->> 'audit')::int + 1,
  'D16 : cle de lot reprise avec un identifiant de l''autre cote : cle_idempotence_reutilisee, et la trace');

-- (o2) D16 : l'apercu est une lecture de liste : une ligne audit_logs, sans nom.
SELECT pg_temp.garde('au_avant', to_jsonb((SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_apercu_lot')));
SELECT pg_temp.garde('ap_o4', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('52'), pg_temp.c('57'), pg_temp.c('06'),
    'ca2bdddd-0000-4000-8000-000000000000'::uuid])$$));
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_apercu_lot')
    = pg_temp.lu('au_avant')::int + 1
  AND (SELECT payload = jsonb_build_object('reader_gender', 'male', 'geste', 'refuser', 'nombre', 2, 'exclus', 2,
                                           'hors_portee', 1)
              AND actor = pg_temp.p('a1') AND row_id IS NULL AND table_name = 'candidatures'
         FROM public.audit_logs WHERE action = 'candidatures_apercu_lot' ORDER BY id DESC LIMIT 1)
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs
                   WHERE action = 'candidatures_apercu_lot' AND payload::text LIKE '%Fixture%')
  AND jsonb_array_length(pg_temp.lu('ap_o4') -> 'eligibles') = 2,
  'D16 : un apercu ecrit une ligne audit_logs (cote du lecteur, geste, nombres), jamais un nom ni un identifiant');
SELECT pg_temp.garde('au_avant', to_jsonb((SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_apercu_lot')));
SELECT pg_temp.garde('ap_o5', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('inviter', ARRAY[pg_temp.c('52')])$$));
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_apercu_lot')
    = pg_temp.lu('au_avant')::int
  AND pg_temp.lu('ap_o5') ->> 'erreur' = 'geste_non_groupable',
  'D16 : un apercu de geste non groupable ne lit aucun nom : aucune ligne candidatures_apercu_lot');

-- (o3) D17 : le jeton est une empreinte sous une cle du serveur.
SELECT pg_temp.garde('ap_j1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('52')])$$));
SELECT pg_temp.garde('ap_j2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('52')])$$));
SELECT pg_temp.garde('ap_j3', pg_temp.en(pg_temp.p('a5'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('52')])$$));
SELECT pg_temp.garde('tr52', pg_temp.trace(pg_temp.c('52')));
SELECT pg_temp.garde('ex_j1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('52')],
    md5(pg_temp.p('a1')::text || '|refuser|' || pg_temp.c('52')::text || ':' || pg_temp.v('52') || '|'), 1,
    'cle-o3-client-001', 'Motif', 'refus_general')$$));
SELECT pg_temp.vrai(pg_temp.lu('ap_j1') ->> 'jeton' = pg_temp.lu('ap_j2') ->> 'jeton'
  AND pg_temp.lu('ap_j1') ->> 'jeton' <> pg_temp.lu('ap_j3') ->> 'jeton'
  AND pg_temp.lu('ap_j1') ->> 'jeton' <> md5(pg_temp.p('a1')::text || '|refuser|' || pg_temp.c('52')::text || ':'
                                              || pg_temp.v('52') || '|')
  AND pg_temp.lu('ex_j1') = '{"erreur": "jeton_perime"}'::jsonb
  AND pg_temp.trace(pg_temp.c('52')) = pg_temp.lu('tr52')
  AND (SELECT count(*) FROM public.candidature_lots WHERE cle = 'cle-o3-client-001') = 0
  AND position((SELECT secret FROM private.candidature_lot_secret) IN pg_temp.lu('ap_j1')::text) = 0,
  'D17 : le jeton ne se calcule pas cote client (l''ancienne empreinte md5 est refusee, rien d''ecrit) ; il est stable pour un meme auteur et un meme lot, different pour un autre auteur ; la cle ne sort jamais');

-- (o4) D16 : la portee avant le rejeu. Un lot et un geste seul, executes par
-- a6 (homme), puis le genre de a6 change (ecriture du proprietaire : le
-- defaut CORRECTIFS 0 ter permet aussi cette ecriture a la direction ; il
-- n'est pas corrige ici). Rejoues, l'un et l'autre rendent hors_portee, sans
-- rapport garde ; le lot retrace chaque identifiant. Le genre rendu, le
-- rapport revient.
SELECT pg_temp.garde('ap_g1', pg_temp.en(pg_temp.p('a6'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('57'), pg_temp.c('58')])$$));
SELECT pg_temp.garde('ex_g1', pg_temp.en(pg_temp.p('a6'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('57'), pg_temp.c('58')],
    pg_temp.lu('ap_g1') ->> 'jeton', 2, 'cle-o4-lot-00001', 'Motif interne de relecture', 'pause_general')$$));
SELECT pg_temp.garde('se_g1', pg_temp.en(pg_temp.p('a6'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('59'), 'Motif interne de relecture', 'pause_general', NULL,
    1, 'cle-o4-seul-0001')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex_g1') @> '{"reussies": 2, "rejoue": false}'::jsonb
  AND pg_temp.lu('se_g1') #>> '{candidature,enPause}' = 'true',
  'D16 : a6 (homme) met 57 et 58 en pause par un lot, 59 par un geste seul');
UPDATE public.profiles SET gender = 'female' WHERE id = pg_temp.p('a6');
SELECT pg_temp.garde('hp57', pg_temp.hp(pg_temp.c('57')));
SELECT pg_temp.garde('hp58', pg_temp.hp(pg_temp.c('58')));
SELECT pg_temp.garde('rj_g1', pg_temp.en(pg_temp.p('a6'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('57'), pg_temp.c('58')], md5('peu importe'), 0,
    'cle-o4-lot-00001')$$));
SELECT pg_temp.garde('rj_g2', pg_temp.en(pg_temp.p('a6'), 'admin',
  $$SELECT public.mettre_en_pause_candidat(pg_temp.c('59'), 'Motif interne de relecture', 'pause_general', NULL,
    1, 'cle-o4-seul-0001')$$));
SELECT pg_temp.vrai(pg_temp.lu('rj_g2') = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.lu('rj_g1') = '{"erreur": "hors_portee"}'::jsonb
  AND (pg_temp.hp(pg_temp.c('57')) ->> 'evenements')::int = (pg_temp.lu('hp57') ->> 'evenements')::int + 1
  AND (pg_temp.hp(pg_temp.c('58')) ->> 'audit')::int = (pg_temp.lu('hp58') ->> 'audit')::int + 1,
  'D16 : lot rejoue apres un changement de genre de son auteur : hors_portee comme le geste seul, ni reference ni etat du cote quitte, une trace par identifiant');
UPDATE public.profiles SET gender = 'male' WHERE id = pg_temp.p('a6');
SELECT pg_temp.garde('rj_g3', pg_temp.en(pg_temp.p('a6'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('57'), pg_temp.c('58')], md5('peu importe'), 0,
    'cle-o4-lot-00001')$$));
SELECT pg_temp.vrai(pg_temp.lu('rj_g3') = (pg_temp.lu('ex_g1') - 'rejoue') || '{"rejoue": true}'::jsonb,
  'D16 : le genre rendu, le meme lot rejoue rend le premier rapport sans ecriture');

-- (o5) D19 : la reouverture d'une candidature en paiement_non_disponible.
-- 53 est refusee par la direction, puis une ligne passe confirme ; le
-- declencheur de L6 ne voit que 54 (en cours). La reouverture applique la
-- transition 9 a 53 ; 55 (aucune ligne) reste en paiement_non_disponible.
SELECT pg_temp.garde('rf53', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('53'), 'Motif interne de relecture', 'refus_niveau', 1, 'cle-o5-refus-0001')$$));
SELECT pg_temp.garde('lr53', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature(pg_temp.c('53'))$$));
INSERT INTO public.referentiel_paiement (pays, methode, operateur, etat, source, source_ref, verifie_le)
VALUES ('SA', 'mobile_money', 'orange_money', 'confirme', 'decision_directeur', 'scenario CAND-L2A2 relecture', current_date);
SELECT pg_temp.vrai((SELECT etat = 'paiement_non_disponible' AND issue = 'refusee' AND paiement = 'incompatible'
                       FROM public.candidatures WHERE id = pg_temp.c('53'))
  AND (SELECT etat = 'a_completer' AND issue = 'en_cours' AND paiement = 'a_verifier'
         FROM public.candidatures WHERE id = pg_temp.c('54'))
  AND pg_temp.lu('lr53') @> '{"issue": "refusee", "etat": "paiement_non_disponible", "refusModele": "refus_niveau"}'::jsonb,
  'D19 : la ligne passe confirme pendant le refus de 53 : le declencheur ne la voit pas, 54 (en cours) passe a_completer');
SELECT pg_temp.garde('t55', pg_temp.trace(pg_temp.c('55')));
SELECT pg_temp.garde('ro53', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('53'), 'Motif interne de relecture', 2, 'cle-o5-rouv-0001')$$));
SELECT pg_temp.garde('ro55', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('55'), 'Motif interne de relecture', 1, 'cle-o5-rouv-0002')$$));
SELECT pg_temp.garde('d53', pg_temp.en(pg_temp.p('53'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$));
SELECT pg_temp.garde('d54', pg_temp.en(pg_temp.p('54'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$));
SELECT pg_temp.vrai(pg_temp.lu('ro53') -> 'candidature' @> '{"issue": "en_cours", "etape": "prequalification",
      "etat": "a_completer", "paiement": "a_verifier", "refusModele": null, "version": 4}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('53') AND type = 'transition' AND details ->> 'transition' = '9'
          AND etat_avant = 'paiement_non_disponible' AND etat_apres = 'a_completer' AND auteur_id IS NULL
          AND details @> '{"cause": "reouverture", "aCompleter": ["versement"], "aNotifier": "paiement_possible",
                           "paiementAvant": "incompatible", "paiementApres": "a_verifier"}'::jsonb) = 1
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = pg_temp.c('53')::text
        AND action = 'candidature_effet_paiement' AND payload @> '{"cause": "reouverture", "effet": "a_completer"}'::jsonb) = 1
  AND pg_temp.lu('d53') @> '{"etat": "a_completer", "paiement": "a_verifier", "complementDemande": ["versement"]}'::jsonb
  AND NOT (pg_temp.lu('d53') -> 'envoiBloque') ? 'etat'
  AND pg_temp.lu('d53') -> 'complementDemande' = pg_temp.lu('d54') -> 'complementDemande',
  'D19 : 53 rouverte apres le passage de la ligne : transition 9 (a_completer, carte versement nommee, marqueur paiement_possible), le candidat peut de nouveau repondre, comme 54');
SELECT pg_temp.vrai(pg_temp.lu('ro55') -> 'candidature' @> '{"issue": "en_cours", "etat": "paiement_non_disponible",
      "paiement": "incompatible"}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements
                   WHERE candidature_id = pg_temp.c('55') AND type = 'transition' AND details ->> 'transition' IN ('8', '9')),
  'D19 : sans ligne confirmee, la candidature rouverte reste en paiement_non_disponible (ni 8 ni 9)');

-- (o6) D20 : la fin d'un complement de salle 2. 01 a un complement ouvert
-- (piece_identite, contrat) depuis (e). Rien ne le ferme tout seul : la
-- direction le cloture par la transition 23 avec le seul code complement_clos.
SELECT pg_temp.garde('l_av', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.garde('t01', pg_temp.trace(pg_temp.c('01')));
SELECT pg_temp.garde('t09', pg_temp.trace(pg_temp.c('09')));
SELECT pg_temp.garde('cl_a', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['complement_clos', 'contrat'], 'Motif', pg_temp.v('01'),
    'cle-o6-mixte-0001')$$));
SELECT pg_temp.garde('cl_b', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('09'), ARRAY['complement_clos'], 'Motif', pg_temp.v('09'),
    'cle-o6-salle1-001')$$));
SELECT pg_temp.garde('cl_c', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['complement_clos'], '  ', pg_temp.v('01'),
    'cle-o6-sansmotif1')$$));
SELECT pg_temp.vrai(private.candidature_complement_en_cours((SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('01')))
    = '["piece_identite", "contrat"]'::jsonb
  AND pg_temp.lu('cl_a') @> '{"erreur": "elements_invalides", "elements": ["complement_clos"]}'::jsonb
  AND pg_temp.lu('cl_b') @> '{"erreur": "elements_invalides", "elements": ["complement_clos"]}'::jsonb
  AND pg_temp.lu('cl_c') = '{"erreur": "motif_requis", "geste": "demander_complement"}'::jsonb
  AND pg_temp.trace(pg_temp.c('01')) = pg_temp.lu('t01') AND pg_temp.trace(pg_temp.c('09')) = pg_temp.lu('t09'),
  'D20 : complement_clos seul, en salle 2 et avec un complement en cours ; mele a un autre code ou en Salle d''examen, c''est un code inconnu ; sans motif, motif_requis ; 0 ecriture');
SELECT pg_temp.garde('cl_ok', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['complement_clos'], 'Motif interne de cloture',
    pg_temp.v('01'), 'cle-o6-cloture-01')$$));
SELECT pg_temp.garde('l_ap', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.garde('d01', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.etat_dossier() -> 'candidature'$$));
SELECT pg_temp.vrai(pg_temp.lu('cl_ok') @> '{"aCompleter": [], "rejoue": false}'::jsonb
  AND pg_temp.lu('cl_ok') -> 'candidature' @> '{"etape": "verifications", "etat": "entretien_a_planifier"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('01') AND type = 'transition' AND etat_avant = 'entretien_a_planifier'
          AND etat_apres = 'entretien_a_planifier' AND motif_interne = 'Motif interne de cloture'
          AND details @> '{"geste": "demander_complement", "transition": 23, "aCompleter": [], "cloture": true}'::jsonb
          AND NOT details ? 'aNotifier') = 1
  AND (pg_temp.trace(pg_temp.c('01')) ->> 'audit')::int = (pg_temp.lu('t01') ->> 'audit')::int + 1
  AND pg_temp.lu('d01') -> 'complementDemande' = '[]'::jsonb
  AND private.candidature_complement_en_cours((SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('01'))) = '[]'::jsonb
  AND (pg_temp.lu('l_ap') #>> '{compteursAlertes,informationsManquantes}')::int
      = (pg_temp.lu('l_av') #>> '{compteursAlertes,informationsManquantes}')::int - 1,
  'D20 : la cloture (transition 23, liste vide, aucun marqueur de notification) ramene complementDemande a [] et sort la candidature des informations manquantes');
SELECT pg_temp.garde('t01', pg_temp.trace(pg_temp.c('01')));
SELECT pg_temp.garde('cl_2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['complement_clos'], 'Motif', pg_temp.v('01'),
    'cle-o6-cloture-02')$$));
SELECT pg_temp.garde('cl_r', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['complement_clos'], 'Motif interne de cloture',
    pg_temp.v('01') - 1, 'cle-o6-cloture-01')$$));
SELECT pg_temp.vrai(pg_temp.lu('cl_2') = '{"erreur": "aucun_complement"}'::jsonb
  AND pg_temp.lu('cl_r') = (pg_temp.lu('cl_ok') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.trace(pg_temp.c('01')) = pg_temp.lu('t01'),
  'D20 : rien a cloturer, aucun_complement ; la cloture rejouee rend le premier resultat sans ecriture');
SELECT pg_temp.garde('cl_n', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.demander_complement_candidat(pg_temp.c('01'), ARRAY['avis'], 'Motif', pg_temp.v('01'), 'cle-o6-nouveau-01')$$));
SELECT pg_temp.garde('l_nv', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures()$$));
SELECT pg_temp.vrai(pg_temp.lu('cl_n') -> 'aCompleter' = '["avis"]'::jsonb
  AND private.candidature_complement_en_cours((SELECT c FROM public.candidatures c WHERE c.id = pg_temp.c('01'))) = '["avis"]'::jsonb
  AND (pg_temp.lu('l_nv') #>> '{compteursAlertes,informationsManquantes}')::int
      = (pg_temp.lu('l_ap') #>> '{compteursAlertes,informationsManquantes}')::int + 1,
  'D20 : apres la cloture, un complement neuf se demande et compte de nouveau');

-- (o7) D18 : un seul vocabulaire. Chaque valeur de gestesGroupables est
-- acceptee par l'apercu et l'execution, qui rendent le code du moteur.
SELECT pg_temp.garde('cap_o7', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.capacites_candidatures()$$));
DO $o7$
DECLARE
  g text;
  r jsonb;
  v_codes text[] := ARRAY[]::text[];
BEGIN
  FOR g IN SELECT jsonb_array_elements_text(pg_temp.lu('cap_o7') -> 'gestesGroupables') LOOP
    r := pg_temp.en(pg_temp.p('a1'), 'admin', format($$SELECT public.apercu_lot_candidats(%L, ARRAY[pg_temp.c('52')])$$, g));
    PERFORM pg_temp.vrai(NOT r ? 'erreur' AND r ->> 'geste' IN ('mettre_en_pause', 'lever_pause', 'refuser'),
      'D18 : gestesGroupables ' || g || ' accepte par l''apercu, code du moteur ' || coalesce(r ->> 'geste', '?'));
    v_codes := v_codes || (r ->> 'geste');
  END LOOP;
  PERFORM pg_temp.vrai(v_codes = ARRAY['mettre_en_pause', 'lever_pause', 'refuser'],
    'D18 : les trois gestes groupables de la capacite sont les trois du moteur');
END $o7$;
SELECT pg_temp.garde('ap_v1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettreEnPause', ARRAY[pg_temp.c('52')])$$));
SELECT pg_temp.garde('ex_v1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('mettreEnPause', ARRAY[pg_temp.c('52')], pg_temp.lu('ap_v1') ->> 'jeton', 1,
    'cle-o7-vocab-0001', 'Motif interne de relecture', 'pause_general')$$));
SELECT pg_temp.garde('ap_v2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.apercu_lot_candidats('leverPause', ARRAY[pg_temp.c('52')])$$));
SELECT pg_temp.garde('ex_v2', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.executer_lot_candidats('leverPause', ARRAY[pg_temp.c('52')], pg_temp.lu('ap_v2') ->> 'jeton', 1,
    'cle-o7-vocab-0002')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex_v1') @> '{"geste": "mettre_en_pause", "reussies": 1}'::jsonb
  AND pg_temp.lu('ex_v2') @> '{"geste": "lever_pause", "reussies": 1}'::jsonb
  AND (SELECT NOT en_pause FROM public.candidatures WHERE id = pg_temp.c('52'))
  AND EXISTS (SELECT 1 FROM public.candidature_lots WHERE cle = 'cle-o7-vocab-0001' AND geste = 'mettre_en_pause'),
  'D18 : l''execution accepte mettreEnPause et leverPause (capacite), le rapport et la cle gardent le code du moteur');

-- (o8) D19 : un seul code pour la carte du versement. La transition 9 nomme
-- une carte de la liste fermee que la direction peut demander.
SELECT pg_temp.vrai((SELECT bool_and(c IN (SELECT jsonb_array_elements_text(pg_temp.lu('cap_o7') -> 'listes' -> 'complementSalleExamen')))
                       FROM jsonb_array_elements_text(pg_temp.lu('d53') -> 'complementDemande') c)
  AND NOT pg_temp.lu('cap_o7') -> 'listes' -> 'complementSalleExamen' ? 'moyen_paiement'
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements
                   WHERE candidature_id::text LIKE 'ca2bcccc%'
                     AND jsonb_path_exists(details, '$.aCompleter[*] ? (@ == "moyen_paiement")')),
  'D19 : la transition 9 (referentiel et reouverture) nomme versement, une carte de la liste fermee du complement ; moyen_paiement n''est ecrit nulle part');

-- (o9) D21 : lire_candidature rend le modele de la pause, celui du refus et
-- la cause de la restriction, comme le resultat d'un geste.
SELECT pg_temp.garde('lr51', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature(pg_temp.c('51'))$$));
SELECT pg_temp.garde('lr07', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature(pg_temp.c('07'))$$));
SELECT pg_temp.garde('lr52', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature(pg_temp.c('52'))$$));
SELECT pg_temp.vrai(pg_temp.lu('lr51') @> '{"enPause": true, "pauseModele": "pause_attente_besoin", "refusModele": null,
      "restrictionCause": null}'::jsonb
  AND pg_temp.lu('lr51') ->> 'pauseModele' = pg_temp.lu('ex_o3') #>> '{lignes,0,candidature,pauseModele}'
  AND pg_temp.lu('lr53') ->> 'refusModele' = pg_temp.lu('rf53') #>> '{candidature,refusModele}'
  AND pg_temp.lu('lr07') @> '{"restreinte": true, "restrictionCause": "paiement", "pauseModele": null}'::jsonb
  AND pg_temp.lu('lr52') @> '{"enPause": false, "pauseModele": null, "refusModele": null, "restrictionCause": null}'::jsonb
  AND pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature(pg_temp.c('06'))$$) = '{"erreur": "hors_portee"}'::jsonb,
  'D21 : lire_candidature rend pauseModele, refusModele et restrictionCause (les memes valeurs que le resultat du geste) ; l''autre cote reste hors_portee');

-- (o10) D22 : refus puis reouverture d'une candidature en entretien planifie.
-- Le refus note l'entretien planifie (L4 l'annulera) ; la reouverture rend
-- l'etat d'origine. Que cet etat soit entretien_planifie ou
-- entretien_a_planifier apres un entretien annule reste a soumettre au
-- directeur (0.2 bis) : le comportement est fige ici pour que L4 le voie.
SELECT pg_temp.garde('rf56', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.refuser_candidat(pg_temp.c('56'), 'Motif interne de relecture', 'refus_general', pg_temp.v('56'),
    'cle-o10-refus-001')$$));
SELECT pg_temp.garde('ro56', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.rouvrir_candidat(pg_temp.c('56'), 'Motif interne de relecture', pg_temp.v('56'), 'cle-o10-rouv-0001')$$));
SELECT pg_temp.vrai(pg_temp.lu('rf56') -> 'candidature' @> '{"issue": "refusee", "etat": "entretien_planifie"}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements
               WHERE candidature_id = pg_temp.c('56') AND details @> '{"geste": "refuser", "entretienPlanifie": true}'::jsonb)
  AND pg_temp.lu('ro56') -> 'candidature' @> '{"issue": "en_cours", "etape": "verifications",
      "etat": "entretien_planifie"}'::jsonb,
  'D22 : le refus d''une candidature en entretien planifie le note (entretienPlanifie) ; la reouverture rend l''etat d''origine, entretien_planifie, tant que L4 et le directeur n''ont pas tranche (0.2 bis)');


-- ------------------------------------------------------------
-- (n) L2-11 : une ligne audit_logs par transition, chaine verifiable
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT bool_and(
                       (SELECT count(*) FROM public.audit_logs a
                         WHERE a.row_id = c.id::text AND a.action = 'candidature_geste')
                       = (SELECT count(*) FROM public.candidature_evenements e
                           WHERE e.candidature_id = c.id AND e.details ? 'geste'))
                     FROM public.candidatures c WHERE c.id::text LIKE 'ca2bcccc%')
  AND (SELECT count(*) FROM public.candidature_evenements e
        WHERE e.candidature_id::text LIKE 'ca2bcccc%' AND e.details ? 'geste'
          AND e.details ->> 'transition' IN ('7', '10', '16', '17', '18', '19', '23', '24', '25', '28')) = 50,
  'L2-11 : autant de lignes audit_logs que de transitions du moteur, candidature par candidature ; 50 gestes de ce lot (7, 10, 16 a 19, 23 a 25, 28)');
SELECT pg_temp.garde('chaine', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT to_jsonb(v) FROM public.verifier_chaine_audit(5000) v$$));
SELECT pg_temp.vrai((pg_temp.lu('chaine') ->> 'rompues')::int = 0
  AND (pg_temp.lu('chaine') ->> 'verifiees')::int = (SELECT count(*) FROM public.audit_logs),
  'L2-11 : chaine d''audit verifiee par verifier_chaine_audit, 0 maillon rompu');
-- Les lignes d'audit des gestes ne se lisent que du cote de la candidature
-- (C15 de CAND-L2A1) : la direction femme ne lit aucune ligne de 01 ; la
-- direction homme ne lit pas la pause posee sur 06 par la direction femme.
SELECT pg_temp.garde('vu', jsonb_build_object(
  'a2_01', pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT to_jsonb(count(*)) FROM public.journal_audit(NULL, 'candidature_geste',
    NULL, 200, NULL, NULL) j WHERE j.ligne_visee = pg_temp.c('01')::text$$),
  'a1_06', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT to_jsonb(count(*)) FROM public.journal_audit(NULL, 'candidature_geste',
    NULL, 200, NULL, NULL) j WHERE j.ligne_visee = pg_temp.c('06')::text$$),
  'a2_06', pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT to_jsonb(count(*)) FROM public.journal_audit(NULL, 'candidature_geste',
    NULL, 200, NULL, NULL) j WHERE j.ligne_visee = pg_temp.c('06')::text$$)));
SELECT pg_temp.vrai(pg_temp.lu('vu') = '{"a2_01": 0, "a1_06": 0, "a2_06": 1}'::jsonb,
  'journal : les gestes de ce lot ne se lisent que du cote de la candidature (C15)');

-- ------------------------------------------------------------
-- (p) Questionnaire du 22/10 (CAND-L2A1, C17) : le controle
-- questionnaire_complet et les moyens accessibles
-- ------------------------------------------------------------
-- 32 : un moyen accessible hors catalogue (champ informatif, ecarte du
-- controle) ; 33 : sans langue maternelle, treize langues d'explication ;
-- 34 a 37 : ce que le controle lit toujours (ancien code d'ijaza, l'arabe pour
-- seule langue de cours, heures a la place des classes, ancien code de public).
SELECT pg_temp.cand('32', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"moyensAccessibles": ["moyen_inconnu_du_catalogue"]}'::jsonb);
SELECT pg_temp.cand('33', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  (pg_temp.lu('complet_sa') - 'langueMaternelle')
  || '{"languesExplication": ["poular", "francais", "english", "man", "sus", "sw", "ha", "wo", "bm", "snk", "mnk", "yo", "autre"],
       "moyensAccessibles": ["wave", "orange_money"]}'::jsonb);
SELECT pg_temp.cand('34', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"ijazaPresentable": "pret_a_un_test"}'::jsonb);
SELECT pg_temp.cand('35', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"languesExplication": ["ar"]}'::jsonb);
SELECT pg_temp.cand('36', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  (pg_temp.lu('complet_sa') - 'classesSouhaitees') || '{"heuresParSemaine": "de_6_a_10"}'::jsonb);
SELECT pg_temp.cand('37', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"publics": ["enfant"]}'::jsonb);
SELECT pg_temp.vrai((SELECT jsonb_object_agg(right(c.id::text, 2), private.candidature_questionnaire_envoye(c))
                       FROM public.candidatures c
                      WHERE c.id IN (pg_temp.c('32'), pg_temp.c('33'), pg_temp.c('34'), pg_temp.c('35'),
                                     pg_temp.c('36'), pg_temp.c('37')))
    = '{"32": "complet", "33": "complet", "34": "incomplet", "35": "incomplet", "36": "incomplet", "37": "incomplet"}'::jsonb,
  'questionnaire_complet : complet malgre un moyen accessible hors catalogue, sans langue maternelle, avec treize langues ; incomplet pour un ancien code d''ijaza, l''arabe seul, des heures sans classes, un ancien code de public');
-- Contre-epreuve : sans l'exclusion, le meme document serait incomplet ; c'est
-- bien l'exclusion de moyensAccessibles qui le protege.
SELECT pg_temp.vrai(
  (private.questionnaire_examiner(
     (SELECT q.definition FROM public.candidature_questionnaires q WHERE q.courant AND q.type_code = 'enseignant'),
     (SELECT r.reponses FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.c('32')))
   -> 'invalides') = '["moyensAccessibles"]'::jsonb
  AND (private.questionnaire_examiner(
     (SELECT q.definition FROM public.candidature_questionnaires q WHERE q.courant AND q.type_code = 'enseignant'),
     (SELECT r.reponses - 'accordRemuneration' - 'operateurs' - 'moyensAccessibles'
        FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.c('32')))
   -> 'invalides') = '[]'::jsonb,
  'contre-epreuve : le document de 32 examine en entier a un champ invalide (moyensAccessibles) ; ecarte comme le fait le controle, il est complet');
-- La seule fonction qui nomme la cle est l'exclusion du controle : ni le
-- paiement, ni une autre fonction, ni un declencheur.
SELECT pg_temp.vrai((SELECT jsonb_agg(n.nspname || '.' || p.proname ORDER BY n.nspname, p.proname)
                       FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
                      WHERE n.nspname IN ('public', 'private', 'app_private') AND p.prosrc LIKE '%moyensAccessibles%')
    = '["private.candidature_questionnaire_envoye"]'::jsonb,
  'moyensAccessibles : une seule fonction du schema le nomme, l''exclusion du controle questionnaire_complet');
-- De bout en bout : 32, dont le moyen accessible est invalide, est admise en
-- Salle de verification et d'entretien (moyen confirme, cadre accepte).
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES (pg_temp.p('32'), 'teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.garde('cf32', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.confirmer_moyen_paiement_candidat(pg_temp.c('32'), 'virement_bancaire', NULL, 1, 'cle-confirmer-32')$$));
SELECT pg_temp.garde('ad32', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.admettre_salle_verification(pg_temp.c('32'), 3, 'cle-admission-32')$$));
SELECT pg_temp.vrai(pg_temp.lu('cf32') ->> 'paiement' = 'compatible'
  AND pg_temp.lu('ad32') -> 'candidature' @> '{"etape": "verifications", "etat": "entretien_a_planifier"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('32') AND type = 'transition'
          AND details @> '{"transition": 10, "controles": [{"nom": "paiement_compatible", "valeur": true},
                                                           {"nom": "cadre_religieux", "valeur": true},
                                                           {"nom": "questionnaire_complet", "valeur": true}]}'::jsonb) = 1,
  'admission de bout en bout : un moyen accessible invalide ne bloque ni le questionnaire ni l''admission ; le controle de paiement reste celui de la transition 24');

-- ------------------------------------------------------------
-- (q) CLASSES-PLAFOND : le controle questionnaire_complet ne depend pas du
-- maximum de Classes par enseignant pour une reponse deja envoyee
-- ------------------------------------------------------------
-- 38 a repondu « 3 », 39 « 5 », 71 « 80 », 72 « 81 » (hors de toute borne).
-- Quel que soit le maximum que la direction regle (3 par defaut, puis 1, 5, 80,
-- 2, et 4), 38, 39 et 71 restent completes et 72 incomplete : une reponse
-- valide le jour de l'envoi ne bloque jamais l'admission pour un reglage que
-- la candidate n'a pas touche (« 5 », valide au maximum de 5, l'est encore
-- quand il redescend a 4, a 3 ou a 1).
CREATE FUNCTION pg_temp.regler(p_n integer) RETURNS void
LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE public.app_config SET value = pg_catalog.to_jsonb(p_n) WHERE key = 'enseignant.classes_max';
$$;
SELECT pg_temp.cand('38', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"classesSouhaitees": "3"}'::jsonb);
SELECT pg_temp.cand('39', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"classesSouhaitees": "5"}'::jsonb);
SELECT pg_temp.cand('71', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"classesSouhaitees": "80"}'::jsonb);
SELECT pg_temp.cand('72', 'male', 'prequalification', 'en_examen', 'en_cours', false,
  pg_temp.lu('complet_sa') || '{"classesSouhaitees": "81"}'::jsonb);
DO $classes_plafond_controle$
DECLARE
  v_max integer;
BEGIN
  FOREACH v_max IN ARRAY ARRAY[3, 5, 4, 3, 2, 1, 80, 4] LOOP
    PERFORM pg_temp.regler(v_max);
    PERFORM pg_temp.vrai((SELECT jsonb_object_agg(right(c.id::text, 2), private.candidature_questionnaire_envoye(c))
                           FROM public.candidatures c
                          WHERE c.id IN (pg_temp.c('38'), pg_temp.c('39'), pg_temp.c('71'), pg_temp.c('72')))
        = '{"38": "complet", "39": "complet", "71": "complet", "72": "incomplet"}'::jsonb,
      'questionnaire_complet, maximum de Classes regle a ' || v_max
      || ' : « 3 », « 5 » et « 80 » restent complets, « 81 » incomplet (le reglage n''invalide aucune reponse envoyee)');
  END LOOP;
  PERFORM pg_temp.regler(3);
END $classes_plafond_controle$;

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 244 THEN
    RAISE EXCEPTION 'CAND-L2A2 ROUGE : % controles executes, 244 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L2A2 : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
