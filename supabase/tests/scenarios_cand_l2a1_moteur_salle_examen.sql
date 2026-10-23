-- CAND-L2A1 : moteur des gestes et Salle d'examen cote candidat.
-- Migration 20261022000000_cand_l2a1_moteur_salle_examen.sql.
-- Cas de la spec consolidee, section 12.1 : L2-8 (cle rejouee, version
-- perimee), L2-9 (geste en pause), L2-10 (geste sans motif), L2-11 (une ligne
-- audit_logs par transition, chaine verifiable), L2-5 en partie (refus : 0
-- motif interne dans etat_dossier()) ; plus le questionnaire versionne et ses
-- listes fermees, le brouillon, la transition 6 (questionnaire complet,
-- accord de remuneration, cadre religieux a la version requise, recalcul du
-- paiement de L6), la transition 17 par le candidat, la sorte d'accord du
-- cadre religieux sans version publiee, les conditions de remuneration lues
-- en base, etat_dossier() etendu (cles gardees, jamais un motif), la portee
-- par genre des gestes de la direction (hors portee trace, super-admin
-- compris), les droits (F86, ACL, aides internes, inventaire des policies).
-- Repris apres relecture (22/10) : (k) journal d'audit et accords bornes par
-- genre (une candidate envoie puis se retire : 0 de ses lignes pour la
-- direction de l'autre cote, la reference et jamais le nom pour son cote, le
-- super-admin journalise) ; (l) brouillon : version de la candidature
-- inchangee, geste de la direction non refuse, aucune reponse gardee sous une
-- cle, une seule cle de brouillon par candidature, jamais une declaration de
-- paiement ; (m) complement demande en salle 2 et cadre neuf a accepter ;
-- (n) changements admis par geste, responsable du meme cote ; motif fait de
-- tabulations, fins de ligne ou espaces Unicode refuse (L2-10) ; envoi aux
-- conditions perimees refuse ; politique sans part : conditions
-- indisponibles ; dimension paiement rendue au candidat.
-- Repris le 22/10 selon les reponses du directeur (C17, DECISION-CANDIDATURES
-- section 1 ter) : (o) langues d'explication sans plafond, ni arabe de cours ni
-- ff, poular unique, "autre", langue maternelle facultative ; memorisation et
-- ijaza separees ; tranches d'age ; classes souhaitees a la place des heures ;
-- moyens accessibles informatifs, jamais lus par le paiement ni par un
-- controle (contre-epreuve : memes reponses, paiement identique).
-- Repris le 22/10 (C18, disponibilites au format que lit l'affectation) : (q)
-- plages par jour ISO a bornes en heures entieres, sans second fuseau, sans
-- chevauchement (refus rendu avec sa cause nommee par l'examen et par les deux
-- RPC), au moins une heure ; l'expansion « une ligne par heure couverte » donne
-- des lignes que weekly_availability accepte et que le predicat d'affectation
-- lit, et un chevauchement donnerait deux fois la meme ligne (cle unique).
-- Chaque controle leve 'CAND-L2A1 ROUGE : ...' s'il echoue. A rejouer sur une
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
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
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
    RAISE EXCEPTION 'CAND-L2A1 ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CAND-L2A1 ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'CAND-L2A1 ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Garde le resultat d'un appel dans un reglage de la transaction (lisible
-- apres RESET ROLE).
CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

-- Tout ce qu'un geste peut ecrire pour une candidature : evenements, audit,
-- cles, documents de reponses, accords du compte, et la ligne elle-meme.
-- DEFINER (proprietaire du scenario) : un compte ne lit pas ces tables.
CREATE FUNCTION pg_temp.trace(p_id uuid) RETURNS jsonb
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT pg_catalog.jsonb_build_object(
    'evenements', (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id = p_id),
    'audit', (SELECT count(*) FROM public.audit_logs a WHERE a.row_id = p_id::text),
    'gestes', (SELECT count(*) FROM public.candidature_gestes g WHERE g.candidature_id = p_id),
    'cle_brouillon', (SELECT md5(coalesce(string_agg(to_jsonb(b)::text, '|'), ''))
                        FROM public.candidature_brouillon_cles b WHERE b.candidature_id = p_id),
    'reponses', (SELECT md5(coalesce(string_agg(r.reponses::text || coalesce(r.envoye_le::text, '-')
                                                || r.soumis_le::text, '|' ORDER BY r.id), ''))
                   FROM public.candidature_reponses r WHERE r.candidature_id = p_id),
    'accords', (SELECT count(*) FROM public.contract_acceptances a
                  JOIN public.candidatures c ON c.profile_id = a.profile_id WHERE c.id = p_id),
    'ligne', (SELECT md5(to_jsonb(c)::text) FROM public.candidatures c WHERE c.id = p_id));
$$;

-- Fixe le nombre maximal de Classes par enseignant (CLASSES-PLAFOND). DEFINER
-- (proprietaire du scenario) : le candidat ne lit ni n'ecrit app_config.
CREATE FUNCTION pg_temp.regler(p_n integer) RETURNS void
LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE public.app_config SET value = pg_catalog.to_jsonb(p_n) WHERE key = 'enseignant.classes_max';
$$;

-- Une fixture dans la premiere source d'une regle du moteur (L2-9, L2-10),
-- homme, dans la portee de la direction a1. p_pause force la pause.
CREATE FUNCTION pg_temp.fixture(p_geste text, p_variante smallint, p_pause boolean) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE
  r private.candidature_gestes_regles;
  v_profil uuid;
  v_id uuid := gen_random_uuid();
  v_etape text;
  v_etat text;
BEGIN
  SELECT x.* INTO r FROM private.candidature_gestes_regles x WHERE x.geste = p_geste AND x.variante = p_variante;
  v_etape := r.etapes[1];
  v_etat := CASE WHEN r.etats IS NOT NULL THEN r.etats[1]
                 WHEN v_etape = 'prequalification' THEN 'a_completer'
                 WHEN v_etape = 'verifications' THEN 'entretien_a_planifier' END;
  IF v_etape NOT IN ('recue', 'invitee') THEN
    v_profil := gen_random_uuid();
    INSERT INTO auth.users (id, email) VALUES (v_profil, 'cand-l2a1-' || v_profil || '@test.invalid');
    INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
    VALUES (v_profil, 'CA2A-' || substr(replace(v_profil::text, '-', ''), 1, 12), 'teacher', 'Regle',
            p_geste, 'pending_kyc', 'male');
  END IF;
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause,
                                   restreinte, restriction_cause, indisponible, source)
  VALUES (v_id, 'enseignant', v_profil, 'male', 'Regle ' || p_geste, v_etape, v_etat, r.issues[1],
          p_pause OR r.pause = 'requise',
          coalesce(r.condition IN ('restreinte', 'restreinte_paiement_a_verifier'), false),
          CASE r.condition WHEN 'restreinte' THEN 'manuelle' WHEN 'restreinte_paiement_a_verifier' THEN 'paiement' END,
          coalesce(r.condition = 'indisponible', false), 'invitation');
  IF r.condition LIKE '%paiement%' THEN
    INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source)
    VALUES (v_id, 'salle-examen-1', '{"paysVersement": "SA", "compteBancaire": true}', 'candidat');
  END IF;
  RETURN v_id;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.refus(text, text, text), pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.trace(uuid)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction au genre inconnu, a4
-- super-admin homme (exception de 0088), e1 tuteur, b1 enseignant (provisoire, garde 0089) sans
-- candidature ; c01 a c14 comptes enseignants en attente, chacun sa
-- candidature (c07 desactive ; c02, c06 et c13 femmes, le genre de la
-- candidature recopie du compte).
INSERT INTO auth.users (id, email)
SELECT ('ca2a0000-0000-4000-8000-0000000000' || s)::uuid, 'cand-l2a1-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'a4', 'e1', 'b1', '01', '02', '03', '04', '05', '06', '07', '08', '09',
                  '10', '11', '12', '13', '14']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca2affff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('ca2a0000-0000-4000-8000-0000000000a1', 'CA2A-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 ('ca2a0000-0000-4000-8000-0000000000a2', 'CA2A-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 ('ca2a0000-0000-4000-8000-0000000000a3', 'CA2A-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 ('ca2a0000-0000-4000-8000-0000000000a4', 'CA2A-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 ('ca2a0000-0000-4000-8000-0000000000e1', 'CA2A-TUT-0001', 'guardian', 'ca2affff-ffff-4fff-8fff-000000000001',
  'Tuteur', 'Essai', 'active', 'female'),
 ('ca2a0000-0000-4000-8000-0000000000b1', 'CA2A-ENS-00B1', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male'),
 ('ca2a0000-0000-4000-8000-000000000001', 'CA2A-ENS-0001', 'teacher', NULL, 'Yahya', 'Arabie', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000002', 'CA2A-ENS-0002', 'teacher', NULL, 'Hafsa', 'Nigeria', 'pending_kyc', 'female'),
 ('ca2a0000-0000-4000-8000-000000000003', 'CA2A-ENS-0003', 'teacher', NULL, 'Musa', 'Examen', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000004', 'CA2A-ENS-0004', 'teacher', NULL, 'Idris', 'Entretien', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000005', 'CA2A-ENS-0005', 'teacher', NULL, 'Ilyas', 'Pause', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000006', 'CA2A-ENS-0006', 'teacher', NULL, 'Asma', 'Femme', 'pending_kyc', 'female'),
 ('ca2a0000-0000-4000-8000-000000000007', 'CA2A-ENS-0007', 'teacher', NULL, 'Harun', 'Desactive', 'disabled', 'male'),
 ('ca2a0000-0000-4000-8000-000000000008', 'CA2A-ENS-0008', 'teacher', NULL, 'Yunus', 'Refuse', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000009', 'CA2A-ENS-0009', 'teacher', NULL, 'Ishaq', 'Cle', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000010', 'CA2A-ENS-0010', 'teacher', NULL, 'Dawud', 'Direction', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000011', 'CA2A-ENS-0011', 'teacher', NULL, 'Yusuf', 'Conditions', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000012', 'CA2A-ENS-0012', 'teacher', NULL, 'Salih', 'Brouillon', 'pending_kyc', 'male'),
 ('ca2a0000-0000-4000-8000-000000000013', 'CA2A-ENS-0013', 'teacher', NULL, 'Maryam', 'Journal', 'pending_kyc', 'female'),
 ('ca2a0000-0000-4000-8000-000000000014', 'CA2A-ENS-0014', 'teacher', NULL, 'Hud', 'Verification', 'pending_kyc', 'male');
-- L'exception super-admin de 0088 pour a4, comme dans le scenario de L1.
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('ca2a0000-0000-4000-8000-0000000000a4');
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause,
                                 reprise_le, pause_modele, issue_modele, source)
SELECT ('ca2acccc-0000-4000-8000-0000000000' || v.s)::uuid, 'enseignant',
       ('ca2a0000-0000-4000-8000-0000000000' || v.s)::uuid, 'male', 'Fixture ' || v.s,
       v.etape, v.etat, v.issue, v.pause, CASE WHEN v.pause THEN current_date + 10 END,
       CASE WHEN v.pause THEN 'pause_attente_documents' END,
       CASE WHEN v.issue = 'refusee' THEN 'refus_profil' END, 'lien_public'
FROM (VALUES
  ('01', 'prequalification', 'a_completer', 'en_cours', false),
  ('02', 'prequalification', 'a_completer', 'en_cours', false),
  ('03', 'prequalification', 'en_examen', 'en_cours', false),
  ('04', 'verifications', 'entretien_planifie', 'en_cours', false),
  ('05', 'prequalification', 'a_completer', 'en_cours', true),
  ('06', 'prequalification', 'a_completer', 'en_cours', false),
  ('07', 'prequalification', 'a_completer', 'en_cours', false),
  ('08', 'prequalification', 'a_completer', 'refusee', false),
  ('09', 'prequalification', 'a_completer', 'en_cours', false),
  ('10', 'prequalification', 'a_completer', 'en_cours', false),
  ('11', 'prequalification', 'a_completer', 'en_cours', false),
  ('12', 'prequalification', 'a_completer', 'en_cours', false),
  ('13', 'prequalification', 'a_completer', 'en_cours', false),
  ('14', 'verifications', 'entretien_a_planifier', 'en_cours', false)
) AS v(s, etape, etat, issue, pause);

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
-- Le Nigeria (C17) : sans langue maternelle (facultative), treize langues
-- d'explication (plus de dix : aucun plafond), les quatre tranches d'age, et
-- trois moyens accessibles dont aucun n'est confirme dans le pays.
SELECT pg_temp.garde('complet_ng', (pg_temp.lu('complet_sa') - 'langueMaternelle')
  || '{"paysResidence": "NG", "paysVersement": "NG", "fuseauIana": "Africa/Lagos",
       "publics": ["6_9", "10_13", "14_17", "adultes"], "classesSouhaitees": "3",
       "languesExplication": ["poular", "francais", "english", "man", "sus", "sw", "ha", "wo", "bm", "snk",
                              "mnk", "yo", "autre"],
       "moyensAccessibles": ["wave", "orange_money", "moov_money"]}'::jsonb);

-- ------------------------------------------------------------
-- (a) Droits, empreintes F86, aides internes, tables
-- ------------------------------------------------------------
DO $f86$
DECLARE
  f regprocedure;
  r text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.conditions_remuneration_candidat()'::regprocedure,
                           'public.questionnaire_salle_examen()'::regprocedure,
                           'public.enregistrer_reponses_salle_examen(text,jsonb,integer,text)'::regprocedure,
                           'public.envoyer_reponses_salle_examen(text,jsonb,boolean,text,integer,text)'::regprocedure,
                           'public.retrait_candidat(integer,text)'::regprocedure,
                           'public.cadre_religieux_version_requise()'::regprocedure,
                           'public.cadre_religieux_acceptable(text)'::regprocedure,
                           'public.etat_dossier()'::regprocedure,
                           'public.journal_audit(uuid,text,timestamptz,integer,timestamptz,bigint)'::regprocedure,
                           'public.journal_audit_filtres()'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                   AND coalesce(proconfig @> ARRAY['search_path=""'], false)
            FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%CAND-L2A1%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-L2A1 ROUGE : DEFINER, proprietaire, search_path, empreinte ou ACL de %', f;
    END IF;
    IF app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f)) THEN
      RAISE EXCEPTION 'CAND-L2A1 ROUGE : garde negative dans %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('dix RPC client (dont le journal redefini) : DEFINER postgres, search_path vide, empreinte reelle, authenticated seul, garde positive');
  IF (SELECT array_agg(provolatile::text ORDER BY proname) FROM pg_proc
      WHERE pronamespace = 'public'::regnamespace
        AND proname IN ('cadre_religieux_acceptable', 'cadre_religieux_version_requise',
                        'conditions_remuneration_candidat', 'enregistrer_reponses_salle_examen',
                        'envoyer_reponses_salle_examen', 'etat_dossier', 'questionnaire_salle_examen',
                        'retrait_candidat'))
     IS DISTINCT FROM ARRAY['s', 's', 's', 'v', 'v', 's', 's', 'v'] THEN
    RAISE EXCEPTION 'CAND-L2A1 ROUGE : volatilite inattendue';
  END IF;
  PERFORM pg_temp.ok('lectures et etat_dossier STABLE ; brouillon, envoi et retrait VOLATILE');
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p
           WHERE p.pronamespace = 'private'::regnamespace
             AND (p.proname LIKE 'questionnaire\_%' OR p.proname LIKE 'candidature\_%'
                  OR p.proname IN ('conditions_remuneration_applicables', 'politique_part_version_publiee',
                                   'journal_portee')) LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_function_privilege(r, f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L2A1 ROUGE : aide interne % executable par %', f, r;
      END IF;
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND (proname LIKE 'questionnaire\_%' OR proname LIKE 'candidature\_%'
                              OR proname IN ('conditions_remuneration_applicables',
                                             'politique_part_version_publiee'))) >= 21,
    'aides internes du moteur et du questionnaire executables par aucun compte');
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND proname LIKE 'cand\_%') = 9,
    'aucune aide cand_ de plus : les neuf de CAND-L1');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
         AND proname LIKE '%candidature%' AND has_function_privilege('authenticated', oid, 'EXECUTE')
         AND proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature',
                             'lire_contact_candidature', 'historique_candidature')),
    'aucune RPC du lot ne double etat_dossier() : la seule lecture de l''etat du candidat (contrat, section 3)');
END $f86$;

DO $tables$
DECLARE
  t regclass;
  r text;
BEGIN
  FOREACH t IN ARRAY ARRAY['public.candidature_questionnaires'::regclass, 'public.candidature_gestes'::regclass,
                           'public.candidature_brouillon_cles'::regclass,
                           'public.politique_part_enseignant'::regclass, 'private.pays_iso_3166'::regclass,
                           'private.candidature_gestes_regles'::regclass] LOOP
    IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = t) THEN
      RAISE EXCEPTION 'CAND-L2A1 ROUGE : RLS inactive sur %', t;
    END IF;
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_table_privilege(r, t, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-L2A1 ROUGE : % garde un privilege sur %', r, t;
      END IF;
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM pg_policies
                        WHERE tablename IN ('candidature_questionnaires', 'candidature_gestes', 'candidature_brouillon_cles',
                                            'politique_part_enseignant', 'pays_iso_3166',
                                            'candidature_gestes_regles')),
    'tables du lot : RLS active, aucun privilege client, aucune policy');
END $tables$;

-- Ajout seul et immuabilite.
UPDATE public.candidature_questionnaires SET courant = courant WHERE version = 'salle-examen-1';
SELECT pg_temp.refus($$UPDATE public.candidature_questionnaires SET definition = '{"champs": []}'::jsonb
  WHERE version = 'salle-examen-1'$$, '55000', 'questionnaire publie : definition immuable, meme pour le proprietaire');
SELECT pg_temp.refus($$DELETE FROM public.candidature_questionnaires WHERE version = 'salle-examen-1'$$, '55000',
  'questionnaire publie : jamais efface');
SELECT pg_temp.refus($$INSERT INTO public.candidature_questionnaires (version, type_code, definition)
  VALUES ('essai-libre', 'enseignant', '{"champs": [{"code": "commentaire", "type": "texte", "requis": false}]}')$$,
  '23514', 'definition a champ libre refusee par la contrainte (types fermes)');
SELECT pg_temp.refus($$INSERT INTO public.candidature_questionnaires (version, type_code, definition, courant)
  VALUES ('essai-deux', 'enseignant', (SELECT definition FROM public.candidature_questionnaires
                                       WHERE version = 'salle-examen-1'), true)$$,
  '23505', 'une seule version courante par type');
SELECT pg_temp.refus($$UPDATE public.politique_part_enseignant SET part_enfant_pour_mille = 500$$, '42501',
  'part de l''enseignant : ajout seul');
SELECT pg_temp.refus($$INSERT INTO public.politique_part_enseignant
  (politique_version, part_enfant_pour_mille, part_adulte_pour_mille, decision_ref)
  VALUES ('v9.9.9', 470, 470, 'essai')$$, '23503', 'part de l''enseignant : seulement pour une politique publiee');
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000001', 'cadre_inconnu', 'v1')$$, '23514',
  'sorte d''accord hors liste refusee');

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.questionnaire_salle_examen()$$, '42501', 'anon : questionnaire ferme');
SELECT pg_temp.refus($$SELECT public.retrait_candidat(1, 'cle-anon-0001')$$, '42501', 'anon : retrait ferme');
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000001',
  'retirer', 'candidat', 'ca2a0000-0000-4000-8000-000000000001', 1, 'cle-directe-01')$$, '42501',
  'candidat : le moteur prive ne s''appelle pas directement');
SELECT pg_temp.refus($$SELECT * FROM public.candidature_gestes$$, '42501', 'candidat : aucune lecture des cles');
RESET ROLE;

-- ------------------------------------------------------------
-- (b) Le cadre religieux : sorte d'accord, aucune version publiee
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.cadre_religieux_version_requise() IS NULL,
  'aucune version requise du cadre religieux publiee par la migration (spec 9)');
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000001', 'teacher_religious_framework', 'test-cadre-1')$$, '42501',
  'cadre non publie : aucune acceptation possible');
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000001', 'teacher_pay_conditions', 'v2.0.0')$$, '42501',
  'accord de remuneration : jamais par une insertion directe');
RESET ROLE;

-- ------------------------------------------------------------
-- (c) Conditions de remuneration lues en base (CAND-BR-12)
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('cond', public.conditions_remuneration_candidat());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('cond') ->> 'disponible' = 'true'
  AND pg_temp.lu('cond') ->> 'version' = 'v2.0.0'
  AND pg_temp.lu('cond') ->> 'dateEffet' = '2026-11-01'
  AND (pg_temp.lu('cond') ->> 'enVigueur')::boolean = (DATE '2026-11-01' <= private.fac_aujourdhui())
  AND pg_temp.lu('cond') -> 'accepteesLe' = 'null'::jsonb,
  'conditions : politique v2.0.0, date d''effet rendue, pas encore acceptees');
SELECT pg_temp.vrai(pg_temp.lu('cond') -> 'publics' = (
    SELECT jsonb_build_array(
      jsonb_build_object('public', 'enfant', 'partPourMille', x.part_enfant_pour_mille),
      jsonb_build_object('public', 'adulte', 'partPourMille', x.part_adulte_pour_mille))
    FROM public.politiques_commerciales p JOIN public.politique_part_enseignant x ON x.politique_version = p.version
    WHERE p.version = 'v2.0.0')
  AND pg_temp.lu('cond') #>> '{publics,0,partPourMille}' = '470'
  AND pg_temp.lu('cond') #>> '{publics,1,partPourMille}' = '470',
  'conditions : 47 % du prix pour chaque public, lu en base, en pour mille');
-- Decision du directeur du 22/10 : le candidat ne recoit jamais un montant,
-- seulement des pourcentages. Aucune cle de montant ni de devise, a aucun
-- niveau, et aucun nombre autre que la part et la date.
SELECT pg_temp.vrai(
  (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.lu('cond')) k)
    = ARRAY['accepteesLe', 'dateEffet', 'disponible', 'enVigueur', 'publics', 'version']
  AND (SELECT bool_and((SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(e) k) = ARRAY['partPourMille', 'public'])
         FROM jsonb_array_elements(pg_temp.lu('cond') -> 'publics') e)
  AND NOT jsonb_path_exists(pg_temp.lu('cond'), 'lax $.**.devise')
  AND NOT jsonb_path_exists(pg_temp.lu('cond'), 'lax $.**.parElevePresentEtParHeure')
  AND NOT jsonb_path_exists(pg_temp.lu('cond'), 'lax $.**.mineur')
  AND pg_temp.lu('cond')::text !~* '(usd|[^a-z]eur[^a-z]|199|157)',
  'conditions : aucun montant ni devise rendu au candidat (decision du 22/10) : seules la version, la date, la part en pour mille');
-- (Aucun montant ecrit en dur : voir (j), en fin de scenario.)

DO $refus_conditions$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('ca2a0000-0000-4000-8000-0000000000e1'::uuid, 'guardian', 'tuteur'),
      ('ca2a0000-0000-4000-8000-0000000000a1'::uuid, 'admin', 'direction'),
      ('ca2a0000-0000-4000-8000-0000000000b1'::uuid, 'teacher', 'enseignant actif sans candidature'),
      ('ca2a0000-0000-4000-8000-000000000007'::uuid, 'teacher', 'candidat au compte desactive'),
      ('ca2a0000-0000-4000-8000-000000000008'::uuid, 'teacher', 'candidature refusee')) AS t(id, role, nom) LOOP
    PERFORM pg_temp.qui(v.id, v.role);
    PERFORM pg_temp.refus($$SELECT public.conditions_remuneration_candidat()$$, '42501',
      'conditions refusees : ' || v.nom);
    PERFORM pg_temp.refus($$SELECT public.questionnaire_salle_examen()$$, '42501',
      'questionnaire refuse : ' || v.nom);
  END LOOP;
END $refus_conditions$;

-- ------------------------------------------------------------
-- (d) Le questionnaire versionne et ses listes fermees
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('q', public.questionnaire_salle_examen());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('q') ->> 'version' = 'salle-examen-1'
  AND jsonb_array_length(pg_temp.lu('q') -> 'champs') = 17
  AND pg_temp.lu('q') ->> 'candidatureVersion' = '1'
  AND pg_temp.lu('q') -> 'dernieresReponses' = 'null'::jsonb,
  'questionnaire : version courante, 17 champs, version de la candidature, aucune reponse encore');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                                 WHERE c ->> 'type' NOT IN ('choix', 'choix_multiple', 'booleen', 'creneaux'))
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                   WHERE c ->> 'type' IN ('choix', 'choix_multiple') AND c ->> 'code' <> 'operateurs'
                     AND (jsonb_typeof(c -> 'options') <> 'array' OR jsonb_array_length(c -> 'options') = 0))
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
               WHERE c ->> 'code' = 'operateurs' AND c -> 'options' = 'null'::jsonb
                 AND c ->> 'dependDe' = 'paysVersement'),
  'questionnaire : aucun champ libre ; chaque choix porte sa liste fermee ; operateurs lus par pays de versement (L6)');
SELECT pg_temp.vrai((SELECT jsonb_agg(c ->> 'code' ORDER BY c ->> 'code') FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                     WHERE c ->> 'code' IN ('paysVersement', 'compteBancaire', 'operateurs', 'paysResidence', 'fuseauIana'))
    = '["compteBancaire", "fuseauIana", "operateurs", "paysResidence", "paysVersement"]'::jsonb,
  'questionnaire : cles de L6 (paysVersement, compteBancaire, operateurs), pays de residence et fuseau');
SELECT pg_temp.vrai((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'langueMaternelle') -> 0 = '{"code": "poular", "referentiel": true}'::jsonb
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('q') #> '{champs,0,options}') o
        WHERE (o ->> 'referentiel')::boolean) = 3
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('q') #> '{champs,0,options}') o
        WHERE o ->> 'code' = 'ar' AND NOT (o ->> 'referentiel')::boolean) = 1
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('q') #> '{champs,0,options}') o
                   WHERE o ->> 'code' IN ('autre_a_preciser', 'Français', 'arabe')),
  'langues : codes du referentiel d''abord (poular, francais, english), puis ISO 639 hors referentiel marques ; jamais un nom ni autre_a_preciser');

-- (d-22/10) Les reponses du directeur sur les langues (C17).
SELECT pg_temp.garde('opt_mat', (SELECT jsonb_agg(o ->> 'code') FROM jsonb_array_elements(
  (SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c WHERE c ->> 'code' = 'langueMaternelle')) o));
SELECT pg_temp.garde('opt_exp', (SELECT jsonb_agg(o ->> 'code') FROM jsonb_array_elements(
  (SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c WHERE c ->> 'code' = 'languesExplication')) o));
SELECT pg_temp.vrai(NOT (SELECT c ? 'max' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                          WHERE c ->> 'code' = 'languesExplication')
  AND (SELECT c ->> 'requis' = 'true' AND c ->> 'min' = '1' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
        WHERE c ->> 'code' = 'languesExplication')
  AND jsonb_array_length(pg_temp.lu('opt_exp')) = 27
  AND jsonb_array_length(pg_temp.lu('opt_mat')) = 28,
  'langues d''explication : aucun plafond (pas de max, 27 options), au moins une ; langue maternelle : 28 options');
SELECT pg_temp.vrai(NOT pg_temp.lu('opt_exp') ? 'ar' AND pg_temp.lu('opt_mat') ? 'ar'
  AND NOT pg_temp.lu('opt_exp') ?| ARRAY['ff', 'peul', 'fulfulde', 'fula', 'arabe']
  AND NOT pg_temp.lu('opt_mat') ?| ARRAY['ff', 'peul', 'fulfulde', 'fula', 'arabe'],
  'l''arabe n''est pas une langue de cours mais reste une langue maternelle ; plus de ff : poular, peul et fulfulde ne font qu''une entree');
SELECT pg_temp.vrai(pg_temp.lu('opt_exp') @> '["poular", "francais", "english", "man", "sus", "sw", "ha", "wo", "bm", "snk", "mnk", "autre"]'::jsonb
  AND pg_temp.lu('opt_mat') @> '["poular", "francais", "english", "man", "sus", "sw", "ha", "wo", "bm", "snk", "mnk", "autre"]'::jsonb
  AND pg_temp.lu('opt_exp') ->> 0 = 'poular' AND pg_temp.lu('opt_exp') ->> 26 = 'autre'
  AND pg_temp.lu('opt_mat') ->> 27 = 'autre'
  AND (SELECT count(*) FROM jsonb_array_elements_text(pg_temp.lu('opt_exp')) x WHERE x = 'poular') = 1
  AND (SELECT count(*) FROM jsonb_array_elements_text(pg_temp.lu('opt_exp')) x WHERE x = 'autre') = 1,
  'langues du public vise : poular (referentiel), francais, english, malinke (man), soussou (sus), swahili, haoussa, wolof, bambara, soninke, mandinka ; poular en tete, "autre langue" a la fin, une seule fois');
SELECT pg_temp.vrai((SELECT c ->> 'requis' = 'false' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'langueMaternelle'),
  'langue maternelle : facultative');

-- (d-22/10) Memorisation et ijaza : deux questions ; tranches d'age ; classes.
SELECT pg_temp.vrai((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'niveauMemorisationDeclare')
    = '["aucune", "moins_10_juz", "de_10_a_29_juz", "coran_entier"]'::jsonb
  AND (SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
        WHERE c ->> 'code' = 'ijazaPresentable') = '["oui", "pret_test", "non"]'::jsonb
  AND (SELECT c ->> 'requis' = 'true' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
        WHERE c ->> 'code' IN ('niveauMemorisationDeclare') )
  AND (SELECT c ->> 'requis' = 'true' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
        WHERE c ->> 'code' IN ('ijazaPresentable')),
  'memorisation (aucune, moins de 10 juz'', de 10 a 29 juz'', Coran entier) et ijaza (oui, pret a un test, non) : deux questions, obligatoires');
SELECT pg_temp.vrai((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'publics') = '["6_9", "10_13", "14_17", "adultes"]'::jsonb
  AND (SELECT c ->> 'type' = 'choix_multiple' AND c ->> 'min' = '1' AND c ->> 'max' = '4'
         FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c WHERE c ->> 'code' = 'publics'),
  'publics : quatre tranches d''age (6-9, 10-13, 14-17, adultes), plusieurs au choix, au moins une');
SELECT pg_temp.vrai((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'classesSouhaitees') = '["1", "2", "3"]'::jsonb
  AND (SELECT c ->> 'type' = 'choix' AND c ->> 'requis' = 'true' AND c ->> 'carte' = 'disponibilites'
         FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c WHERE c ->> 'code' = 'classesSouhaitees')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                   WHERE c ->> 'code' = 'heuresParSemaine'),
  'classes souhaitees : 1, 2 ou 3 (le maximum de Classes par enseignant en vigueur, 3 par defaut) ; heuresParSemaine n''existe plus');

-- (p-22/10) Les classes souhaitees suivent le reglage « nombre maximal de
-- Classes par enseignant » (enseignant.classes_max, CLASSES-PLAFOND) : le
-- questionnaire servi propose de 1 au maximum, sans nouvelle version.
CREATE FUNCTION pg_temp.options_classes() RETURNS jsonb
LANGUAGE sql AS $$
  SELECT c -> 'options' FROM jsonb_array_elements(public.questionnaire_salle_examen() -> 'champs') c
   WHERE c ->> 'code' = 'classesSouhaitees';
$$;
SELECT pg_temp.regler(5);
SELECT pg_temp.vrai(pg_temp.options_classes() = '["1", "2", "3", "4", "5"]'::jsonb,
  'classes souhaitees : le maximum passe a 5, le questionnaire servi propose de 1 a 5');
SELECT pg_temp.regler(2);
SELECT pg_temp.vrai(pg_temp.options_classes() = '["1", "2"]'::jsonb,
  'classes souhaitees : le maximum baisse a 2, le questionnaire servi propose 1 et 2');
SELECT pg_temp.regler(1);
SELECT pg_temp.vrai(pg_temp.options_classes() = '["1"]'::jsonb,
  'classes souhaitees : le maximum baisse a 1, le questionnaire servi propose 1');
SELECT pg_temp.regler(80);
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.options_classes()) = 80
  AND pg_temp.options_classes() -> 0 = '"1"'::jsonb AND pg_temp.options_classes() -> 79 = '"80"'::jsonb,
  'classes souhaitees : au maximum de 80, quatre-vingts options en codes de texte');
SELECT pg_temp.regler(3);
SELECT pg_temp.vrai(pg_temp.options_classes() = '["1", "2", "3"]'::jsonb,
  'classes souhaitees : le maximum revient a 3, le questionnaire servi propose de nouveau 1, 2, 3');

-- (d-22/10) Moyens accessibles : facultatif, la liste de tous les moyens
-- connus du catalogue de L6 (confirmes ou non), sans pays ni etat.
SELECT pg_temp.vrai((SELECT c ->> 'requis' = 'false' AND c ->> 'type' = 'choix_multiple'
                            AND c ->> 'carte' = 'versement' AND c ->> 'min' = '0' AND NOT c ? 'dependDe'
                       FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c WHERE c ->> 'code' = 'moyensAccessibles')
  AND (SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
        WHERE c ->> 'code' = 'moyensAccessibles')
    = (SELECT jsonb_agg(jsonb_build_object('code', o.code, 'methode', o.methode, 'nom', o.nom) ORDER BY o.cree_le, o.code)
         FROM public.referentiel_paiement_operateurs o WHERE o.actif)
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                                                      WHERE c ->> 'code' = 'moyensAccessibles')) o
                   WHERE o ?| ARRAY['pays', 'etat', 'confirme', 'ligne', 'notes', 'prestataire'])
  AND EXISTS (SELECT 1 FROM public.referentiel_paiement_operateurs o
               WHERE o.code = 'moov_money'
                 AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                                  WHERE l.operateur = o.code AND l.etat = 'confirme')),
  'moyens accessibles : facultatif, les operateurs actifs du catalogue de L6 (code, methode, nom) meme ceux qu''aucun pays ne confirme, sans pays ni etat ; operateurs, lui, reste lu par pays de versement');
SELECT pg_temp.vrai((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'paysVersement')
    = (SELECT jsonb_agg(code ORDER BY rang) FROM private.pays_iso_3166)
  AND jsonb_array_length((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                           WHERE c ->> 'code' = 'paysResidence')) = 249,
  'pays : les 249 codes ISO de pays_iso.dart, dans le meme ordre');
SELECT pg_temp.vrai((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
                      WHERE c ->> 'code' = 'fuseauIana') @> '["Europe/Paris", "Asia/Riyadh", "Africa/Conakry"]'::jsonb
  AND NOT ((SELECT c -> 'options' FROM jsonb_array_elements(pg_temp.lu('q') -> 'champs') c
             WHERE c ->> 'code' = 'fuseauIana') ?| ARRAY['US/Eastern', 'Etc/UTC', 'UTC', 'posix/Europe/Paris']),
  'fuseaux : noms IANA Zone/Lieu, jamais un alias');

-- ------------------------------------------------------------
-- (e) Le brouillon : valeurs dans les listes, cle et version du document
-- ------------------------------------------------------------
SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('b1', public.enregistrer_reponses_salle_examen('salle-examen-1',
  '{"paysResidence": "SA", "langueMaternelle": "ar", "languesExplication": ["francais", "poular"]}', 0,
  'cle-brouillon-c01-1'));
SELECT pg_temp.garde('q1', public.questionnaire_salle_examen());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('b1') ->> 'rejoue' = 'false' AND pg_temp.lu('b1') ->> 'versionBrouillon' = '1'
  AND pg_temp.lu('b1') ->> 'complet' = 'false' AND NOT pg_temp.lu('b1') ? 'reponses'
  AND pg_temp.lu('b1') -> 'manquants' @> '["riwayat", "fuseauIana", "paysVersement", "compteBancaire"]'::jsonb
  AND NOT pg_temp.lu('b1') -> 'manquants' ? 'operateurs'
  AND pg_temp.lu('q1') ->> 'versionBrouillon' = '1' AND pg_temp.lu('q1') ->> 'candidatureVersion' = '1'
  AND pg_temp.lu('q1') #> '{dernieresReponses,reponses}'
      = '{"paysResidence": "SA", "langueMaternelle": "ar", "languesExplication": ["francais", "poular"]}'::jsonb
  AND pg_temp.lu('q1') #> '{dernieresReponses,brouillon}' = 'true'::jsonb,
  'brouillon partiel accepte : version du brouillon 1, champs requis manquants nommes (operateurs facultatif), reponses relues par le questionnaire, jamais rendues par l''enregistrement');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_reponses
                      WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001' AND source = 'candidat'
                        AND questionnaire_version = 'salle-examen-1' AND envoye_le IS NULL AND brouillon
                        AND version = 1) = 1
  AND (SELECT pays_residence IS NULL AND version = 1 AND etat = 'a_completer'
       FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000001')
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') ->> 'evenements')
      = pg_temp.lu('t01') ->> 'evenements'
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') ->> 'audit') = pg_temp.lu('t01') ->> 'audit'
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') ->> 'gestes')::int = 0
  AND (SELECT count(*) FROM public.candidature_brouillon_cles
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001' AND cle = 'cle-brouillon-c01-1') = 1,
  'brouillon : un document candidat marque brouillon, version de la candidature inchangee, rien recopie avant l''envoi, aucun evenement ni audit, sa seule cle gardee a part');
SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('b1r', public.enregistrer_reponses_salle_examen('salle-examen-1', '{"paysResidence": "FR"}', 0,
  'cle-brouillon-c01-1'));
SELECT pg_temp.garde('b2', public.enregistrer_reponses_salle_examen('salle-examen-1', '{"paysResidence": "FR"}', 0,
  'cle-brouillon-c01-2'));
SELECT pg_temp.garde('b3', public.enregistrer_reponses_salle_examen('salle-examen-0', '{"paysResidence": "FR"}', 1,
  'cle-brouillon-c01-3'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('b1r') = (pg_temp.lu('b1') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('b2') = '{"erreur": "conflit_brouillon", "versionCourante": 1}'::jsonb
  AND pg_temp.lu('b3') = '{"erreur": "questionnaire_perime", "versionCourante": "salle-examen-1"}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'L2-8 : meme cle rejouee, premier resultat sans ecriture ; version du brouillon perimee : conflit_brouillon ; questionnaire perime nomme ; 0 ecriture');

DO $invalides$
DECLARE
  v record;
  v_r jsonb;
  v_n integer := 0;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('{"paysResidence": "XX"}', 'paysResidence', 'pays hors ISO'),
      ('{"paysResidence": "sa"}', 'paysResidence', 'pays en minuscules'),
      ('{"langueMaternelle": "autre_a_preciser"}', 'langueMaternelle', 'autre_a_preciser n''est pas une langue'),
      ('{"langueMaternelle": "Français"}', 'langueMaternelle', 'langue par son nom'),
      ('{"languesExplication": ["francais", "francais"]}', 'languesExplication', 'langue en double'),
      ('{"languesExplication": ["ar"]}', 'languesExplication', 'l''arabe n''est pas une langue de cours'),
      ('{"languesExplication": ["francais", "ar"]}', 'languesExplication', 'l''arabe parmi d''autres langues de cours'),
      ('{"languesExplication": ["ff"]}', 'languesExplication', 'ff n''existe plus : poular'),
      ('{"langueMaternelle": "ff"}', 'langueMaternelle', 'ff n''existe plus : poular'),
      ('{"languesExplication": ["peul"]}', 'languesExplication', 'peul n''est pas un code : poular'),
      ('{"languesExplication": "poular"}', 'languesExplication', 'une langue au lieu d''une liste'),
      ('{"heuresParSemaine": "de_6_a_10"}', 'heuresParSemaine', 'heuresParSemaine n''existe plus'),
      ('{"classesSouhaitees": "81"}', 'classesSouhaitees', 'quatre-vingt-une classes : au-dela de la borne du reglage (80)'),
      ('{"classesSouhaitees": "0"}', 'classesSouhaitees', 'zero classe'),
      ('{"classesSouhaitees": 2}', 'classesSouhaitees', 'un nombre au lieu du code'),
      ('{"classesSouhaitees": ["2"]}', 'classesSouhaitees', 'une liste au lieu d''un choix'),
      ('{"niveauMemorisationDeclare": "plus_de_10_juz"}', 'niveauMemorisationDeclare', 'ancien code de memorisation'),
      ('{"niveauMemorisationDeclare": "ijaza_lecture_enseignement"}', 'niveauMemorisationDeclare', 'l''ijaza n''est plus un niveau de memorisation'),
      ('{"ijazaPresentable": "pret_a_un_test"}', 'ijazaPresentable', 'ancien code de l''ijaza : pret_test'),
      ('{"publics": ["enfant"]}', 'publics', 'ancien code de public : enfant'),
      ('{"publics": ["adulte"]}', 'publics', 'ancien code de public : adulte'),
      ('{"publics": ["6_9", "6_9"]}', 'publics', 'tranche en double'),
      ('{"publics": ["6_9", "10_13", "14_17", "adultes", "adultes"]}', 'publics', 'cinq tranches pour quatre'),
      ('{"moyensAccessibles": ["virement_bancaire"]}', 'moyensAccessibles', 'un moyen hors du catalogue des operateurs'),
      ('{"moyensAccessibles": ["wave", "wave"]}', 'moyensAccessibles', 'moyen en double'),
      ('{"moyensAccessibles": "wave"}', 'moyensAccessibles', 'un moyen au lieu d''une liste'),
      ('{"riwayat": ["autre"]}', 'riwayat', 'riwaya hors liste'),
      ('{"niveauMemorisationDeclare": "j''ai tout appris"}', 'niveauMemorisationDeclare', 'texte libre'),
      ('{"commentaire": "texte libre"}', 'commentaire', 'cle inconnue'),
      ('{"fuseauIana": "US/Eastern"}', 'fuseauIana', 'alias de fuseau'),
      ('{"fuseauIana": "Mars/Olympus"}', 'fuseauIana', 'fuseau inconnu'),
      ('{"compteBancaire": "oui"}', 'compteBancaire', 'booleen en texte'),
      ('{"publics": ["enfant", "famille"]}', 'publics', 'public hors liste'),
      ('{"paysVersement": "SA", "operateurs": ["wave"]}', 'operateurs', 'operateur sans ligne confirmee du pays'),
      ('{"disponibilitesDeclarees": {"fuseau": "Asia/Riyadh", "creneaux": [{"jour": 1, "debut": "20:00", "fin": "22:00"}]}}',
       'disponibilitesDeclarees', 'ancienne forme : un objet avec un second fuseau et des creneaux'),
      ('{"disponibilitesDeclarees": [{"jour": 8, "debut": "20:00", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'jour 8'),
      ('{"disponibilitesDeclarees": [{"jour": 0, "debut": "20:00", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'jour 0'),
      ('{"disponibilitesDeclarees": [{"jour": "1", "debut": "20:00", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'jour en texte'),
      ('{"disponibilitesDeclarees": [{"jour": 1.5, "debut": "20:00", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'jour decimal'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:15", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'debut avec des minutes (20:15)'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:30", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'debut a la demi-heure (l''ancienne maille)'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "21:30"}]}',
       'disponibilitesDeclarees', 'fin a la demi-heure (l''ancienne maille)'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "8:00", "fin": "10:00"}]}',
       'disponibilitesDeclarees', 'heure sans zero de tete'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "22:00", "fin": "20:00"}]}',
       'disponibilitesDeclarees', 'fin avant debut'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "20:00"}]}',
       'disponibilitesDeclarees', 'fin egale au debut : aucune heure'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "00:00"}]}',
       'disponibilitesDeclarees', 'fin a minuit ecrite 00:00 (24:00 est la seule ecriture)'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "24:00", "fin": "24:00"}]}',
       'disponibilitesDeclarees', 'debut a 24:00'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "25:00"}]}',
       'disponibilitesDeclarees', 'fin a 25:00'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "22:00", "note": "x"}]}',
       'disponibilitesDeclarees', 'plage a cle libre'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "22:00", "fuseau": "Asia/Riyadh"}]}',
       'disponibilitesDeclarees', 'un fuseau dans la plage : le fuseau est celui de fuseauIana'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00"}]}',
       'disponibilitesDeclarees', 'plage sans fin'),
      ('{"disponibilitesDeclarees": [null]}', 'disponibilitesDeclarees', 'plage nulle'),
      ('{"disponibilitesDeclarees": ["lundi soir"]}', 'disponibilitesDeclarees', 'plage en texte'),
      ('{"disponibilitesDeclarees": "lundi soir"}', 'disponibilitesDeclarees', 'texte libre au lieu de plages'),
      ('{"disponibilitesDeclarees": {}}', 'disponibilitesDeclarees', 'objet vide'),
      ('{"disponibilitesDeclarees": [{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 1, "debut": "20:00", "fin": "22:00"}]}',
       'disponibilitesDeclarees', 'deux plages du meme jour qui se chevauchent')
    ) AS t(reponses, champ, cas) LOOP
    v_n := v_n + 1;
    v_r := public.enregistrer_reponses_salle_examen('salle-examen-1', v.reponses::jsonb, 1,
                                                    'cle-invalide-c01-' || v_n);
    PERFORM pg_temp.vrai(v_r ->> 'erreur' = 'reponses_invalides' AND v_r -> 'champs' ? v.champ,
      'valeur hors liste refusee, champ nomme : ' || v.cas);
  END LOOP;
END $invalides$;
SELECT pg_temp.vrai(pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'reponses invalides : 0 ecriture (ni document, ni version, ni cle)');

-- (q-22/10) Le refus d'un chevauchement de plages est NOMME, par les deux RPC
-- qui examinent des reponses (C18) : reponses_invalides, le champ, et sa cause
-- sous « motifs ». Un autre champ invalide, ou une autre cause (une demi-heure),
-- n'en porte pas : la cle motifs n'est rendue que si une cause est nommee.
SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('chev_enreg', public.enregistrer_reponses_salle_examen('salle-examen-1',
  '{"disponibilitesDeclarees": [{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 1, "debut": "20:00", "fin": "22:00"}]}',
  1, 'cle-chevauchement-c01-1'));
SELECT pg_temp.garde('chev_enreg_deux', public.enregistrer_reponses_salle_examen('salle-examen-1',
  '{"paysResidence": "XX", "disponibilitesDeclarees": [{"jour": 2, "debut": "18:00", "fin": "19:00"}, {"jour": 2, "debut": "18:00", "fin": "19:00"}]}',
  1, 'cle-chevauchement-c01-2'));
SELECT pg_temp.garde('chev_envoi', public.envoyer_reponses_salle_examen('salle-examen-1',
  pg_temp.lu('complet_sa') || '{"disponibilitesDeclarees": [{"jour": 3, "debut": "08:00", "fin": "12:00"}, {"jour": 3, "debut": "11:00", "fin": "13:00"}]}',
  true, 'v2.0.0', 1, 'cle-chevauchement-c01-3'));
SELECT pg_temp.garde('demi_enreg', public.enregistrer_reponses_salle_examen('salle-examen-1',
  '{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:30", "fin": "22:00"}]}', 1, 'cle-demi-heure-c01-1'));
SELECT pg_temp.garde('demi_envoi', public.envoyer_reponses_salle_examen('salle-examen-1',
  pg_temp.lu('complet_sa') || '{"disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "22:30"}]}',
  true, 'v2.0.0', 1, 'cle-demi-heure-c01-2'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('chev_enreg') = '{"erreur": "reponses_invalides", "champs": ["disponibilitesDeclarees"],
      "motifs": {"disponibilitesDeclarees": "plages_qui_se_chevauchent"}}'::jsonb
  AND pg_temp.lu('chev_envoi') = pg_temp.lu('chev_enreg')
  AND pg_temp.lu('chev_enreg_deux') = '{"erreur": "reponses_invalides", "champs": ["disponibilitesDeclarees", "paysResidence"],
      "motifs": {"disponibilitesDeclarees": "plages_qui_se_chevauchent"}}'::jsonb,
  'enregistrer et envoyer : plages qui se chevauchent refusees avec la cause nommee (plages_qui_se_chevauchent) ; un autre champ invalide a cote ne perd pas sa place dans champs');
SELECT pg_temp.vrai(pg_temp.lu('demi_enreg') = '{"erreur": "reponses_invalides", "champs": ["disponibilitesDeclarees"]}'::jsonb
  AND pg_temp.lu('demi_envoi') = pg_temp.lu('demi_enreg')
  AND NOT pg_temp.lu('demi_enreg') ? 'motifs',
  'contre-epreuve : une demi-heure est refusee sans cause nommee (pas de cle motifs) : le chevauchement n''est pas le fourre-tout des plages invalides');
SELECT pg_temp.vrai(pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'refus de chevauchement et de demi-heure : 0 ecriture (ni document, ni version, ni cle) ; envoi refuse = aucun accord, aucune transition');

-- (e-22/10) Ce que le questionnaire accepte (reponses du directeur, C17) :
-- les valeurs decidees, les champs facultatifs absents, aucun plafond de
-- langues. Examen direct de la definition courante.
SELECT pg_temp.garde('def', (SELECT q.definition FROM public.candidature_questionnaires q
                              WHERE q.courant AND q.type_code = 'enseignant'));
CREATE FUNCTION pg_temp.examen(p_reponses jsonb) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT private.questionnaire_examiner(pg_temp.lu('def'), p_reponses) - 'reponses';
$$;
DO $acceptees$
DECLARE
  v_rien constant jsonb := '{"invalides": [], "manquants": [], "inconnus": []}';
  v_tout jsonb;
  v_code text;
BEGIN
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa')) = v_rien
    AND pg_temp.examen(pg_temp.lu('complet_ng')) = v_rien,
    'les deux jeux de reponses completes (Arabie saoudite, Nigeria) sont valides');
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') - 'langueMaternelle') = v_rien
    AND pg_temp.examen((pg_temp.lu('complet_sa') - 'langueMaternelle') || '{"langueMaternelle": null}') = v_rien,
    'langue maternelle facultative : absente ou nulle, les reponses restent completes');
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') - 'classesSouhaitees')
        = '{"invalides": [], "manquants": ["classesSouhaitees"], "inconnus": []}'
    AND pg_temp.examen(pg_temp.lu('complet_sa') - 'languesExplication')
        = '{"invalides": [], "manquants": ["languesExplication"], "inconnus": []}'
    AND pg_temp.examen((pg_temp.lu('complet_sa') - 'publics') || '{"publics": []}')
        = '{"invalides": [], "manquants": ["publics"], "inconnus": []}'
    AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"languesExplication": []}')
        = '{"invalides": [], "manquants": ["languesExplication"], "inconnus": []}',
    'classes souhaitees, langues d''explication (au moins une) et publics (au moins une tranche) restent obligatoires');
  -- Aucun plafond : toutes les options en une fois.
  v_tout := pg_temp.lu('opt_exp');
  PERFORM pg_temp.vrai(jsonb_array_length(v_tout) = 27
    AND pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('languesExplication', v_tout)) = v_rien,
    'langues d''explication : les 27 options choisies ensemble sont valides (aucun plafond)');
  FOR v_code IN SELECT jsonb_array_elements_text(pg_temp.lu('opt_mat')) LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('langueMaternelle', v_code)) = v_rien,
      'langue maternelle valide : ' || v_code);
  END LOOP;
  FOREACH v_code IN ARRAY ARRAY['aucune', 'moins_10_juz', 'de_10_a_29_juz', 'coran_entier'] LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('niveauMemorisationDeclare', v_code)) = v_rien,
      'memorisation valide : ' || v_code);
  END LOOP;
  FOREACH v_code IN ARRAY ARRAY['oui', 'pret_test', 'non'] LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('ijazaPresentable', v_code)) = v_rien,
      'ijaza valide : ' || v_code);
  END LOOP;
  FOREACH v_code IN ARRAY ARRAY['1', '2', '3'] LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('classesSouhaitees', v_code)) = v_rien,
      'classes souhaitees valides : ' || v_code);
  END LOOP;
  FOREACH v_code IN ARRAY ARRAY['6_9', '10_13', '14_17', 'adultes'] LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('publics', jsonb_build_array(v_code))) = v_rien,
      'une seule tranche d''age suffit : ' || v_code);
  END LOOP;
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || '{"publics": ["6_9", "10_13", "14_17", "adultes"]}') = v_rien,
    'les quatre tranches d''age ensemble sont valides');
  -- Moyens accessibles : absent, vide, un ou tous les moyens connus.
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') - 'moyensAccessibles') = v_rien
    AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"moyensAccessibles": []}') = v_rien
    AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"moyensAccessibles": ["moov_money"]}') = v_rien
    AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"moyensAccessibles": ["wave", "orange_money", "moov_money"]}') = v_rien,
    'moyens accessibles : facultatif, vide, un seul ou tous les moyens connus (meme sans ligne confirmee)');
  -- Un operateur retire du catalogue (actif = false) n'est plus propose ni accepte.
  UPDATE public.referentiel_paiement_operateurs SET actif = false WHERE code = 'moov_money';
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || '{"moyensAccessibles": ["moov_money"]}')
        = '{"invalides": ["moyensAccessibles"], "manquants": [], "inconnus": []}'
    AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(private.questionnaire_options(pg_temp.lu('def'),
          (SELECT c FROM jsonb_array_elements(pg_temp.lu('def') -> 'champs') c WHERE c ->> 'code' = 'moyensAccessibles'))) o
          WHERE o ->> 'code' = 'moov_money'),
    'un operateur desactive du catalogue n''est plus propose ni accepte dans les moyens accessibles');
  UPDATE public.referentiel_paiement_operateurs SET actif = true WHERE code = 'moov_money';
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || '{"moyensAccessibles": ["moov_money"]}') = v_rien,
    'operateur reactive : de nouveau accepte');
END $acceptees$;

-- (q-22/10) Les disponibilites au format que lit l'affectation (C18) : des
-- plages par jour ISO a bornes en heures entieres, sans second fuseau.
DO $plages$
DECLARE
  v_rien constant jsonb := '{"invalides": [], "manquants": [], "inconnus": []}';
  v_chev constant jsonb := '{"invalides": ["disponibilitesDeclarees"], "manquants": [], "inconnus": [],
    "motifs": {"disponibilitesDeclarees": "plages_qui_se_chevauchent"}}';
  v_generique constant jsonb := '{"invalides": ["disponibilitesDeclarees"], "manquants": [], "inconnus": []}';
  v_manque constant jsonb := '{"invalides": [], "manquants": ["disponibilitesDeclarees"], "inconnus": []}';
  v_cas record;
  v_champ jsonb := (SELECT c FROM jsonb_array_elements(pg_temp.lu('def') -> 'champs') c
                     WHERE c ->> 'code' = 'disponibilitesDeclarees');
  v_toute_la_semaine jsonb;
BEGIN
  -- La definition : un champ de plages, requis, sans liste, et UN SEUL champ de
  -- fuseau dans tout le questionnaire (fuseauIana).
  PERFORM pg_temp.vrai(v_champ @> '{"type": "creneaux", "requis": true, "min": 1, "max": 168}'
    AND NOT v_champ ? 'liste' AND NOT v_champ ? 'valeurs'
    AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('def') -> 'champs') c
          WHERE c ->> 'liste' = 'fuseaux') = 1
    AND (SELECT c ->> 'code' FROM jsonb_array_elements(pg_temp.lu('def') -> 'champs') c
          WHERE c ->> 'liste' = 'fuseaux') = 'fuseauIana',
    'disponibilitesDeclarees : plages requises (de 1 a 168), et fuseauIana est le seul fuseau du questionnaire');

  -- Ce qui est accepte.
  FOR v_cas IN SELECT * FROM (VALUES
      ('une seule heure', '[{"jour": 1, "debut": "18:00", "fin": "19:00"}]'),
      ('plusieurs heures du soir', '[{"jour": 1, "debut": "18:00", "fin": "21:00"}]'),
      ('la journee entiere, de minuit a 24:00', '[{"jour": 7, "debut": "00:00", "fin": "24:00"}]'),
      ('la derniere heure de la journee', '[{"jour": 5, "debut": "23:00", "fin": "24:00"}]'),
      ('la premiere heure de la journee', '[{"jour": 2, "debut": "00:00", "fin": "01:00"}]'),
      ('les memes heures deux jours de suite', '[{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 2, "debut": "18:00", "fin": "21:00"}]'),
      ('deux plages qui se touchent (19:00 est la fin de l''une et le debut de l''autre)',
       '[{"jour": 1, "debut": "18:00", "fin": "19:00"}, {"jour": 1, "debut": "19:00", "fin": "21:00"}]'),
      ('deux plages separees d''une heure', '[{"jour": 1, "debut": "08:00", "fin": "09:00"}, {"jour": 1, "debut": "10:00", "fin": "11:00"}]'),
      ('plages dans le desordre', '[{"jour": 3, "debut": "22:00", "fin": "24:00"}, {"jour": 1, "debut": "08:00", "fin": "09:00"}, {"jour": 3, "debut": "06:00", "fin": "07:00"}]'),
      ('une nuit a cheval sur minuit : deux plages, sur deux jours',
       '[{"jour": 4, "debut": "22:00", "fin": "24:00"}, {"jour": 5, "debut": "00:00", "fin": "01:00"}]')
    ) AS t(cas, plages) LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa')
                           || jsonb_build_object('disponibilitesDeclarees', v_cas.plages::jsonb)) = v_rien,
      'plages acceptees : ' || v_cas.cas);
  END LOOP;
  -- Le maximum : 7 jours de 24 plages d'une heure (168), sans chevauchement.
  SELECT jsonb_agg(jsonb_build_object('jour', j, 'debut', to_char(h, 'FM00') || ':00', 'fin', to_char(h + 1, 'FM00') || ':00')
                   ORDER BY j, h)
    INTO v_toute_la_semaine FROM generate_series(1, 7) j, generate_series(0, 23) h;
  PERFORM pg_temp.vrai(jsonb_array_length(v_toute_la_semaine) = 168
    AND pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('disponibilitesDeclarees', v_toute_la_semaine)) = v_rien,
    'plages acceptees : toute la semaine en 168 plages d''une heure (le maximum de la definition)');
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa')
        || jsonb_build_object('disponibilitesDeclarees', v_toute_la_semaine || '[{"jour": 1, "debut": "00:00", "fin": "01:00"}]'))
        = v_generique,
    'plus de 168 plages : refusees comme invalides (le maximum est verifie avant le chevauchement)');

  -- Le chevauchement, refuse avec sa cause nommee.
  FOR v_cas IN SELECT * FROM (VALUES
      ('recouvrement partiel', '[{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 1, "debut": "20:00", "fin": "22:00"}]'),
      ('recouvrement partiel, plages listees dans l''autre ordre', '[{"jour": 1, "debut": "20:00", "fin": "22:00"}, {"jour": 1, "debut": "18:00", "fin": "21:00"}]'),
      ('recouvrement d''une seule heure', '[{"jour": 6, "debut": "18:00", "fin": "20:00"}, {"jour": 6, "debut": "19:00", "fin": "21:00"}]'),
      ('une plage contenue dans une autre', '[{"jour": 2, "debut": "08:00", "fin": "12:00"}, {"jour": 2, "debut": "09:00", "fin": "10:00"}]'),
      ('deux plages identiques', '[{"jour": 3, "debut": "18:00", "fin": "21:00"}, {"jour": 3, "debut": "18:00", "fin": "21:00"}]'),
      ('jusqu''a 24:00', '[{"jour": 7, "debut": "22:00", "fin": "24:00"}, {"jour": 7, "debut": "23:00", "fin": "24:00"}]'),
      ('le recouvrement est la troisieme plage, apres deux plages qui se touchent',
       '[{"jour": 1, "debut": "18:00", "fin": "19:00"}, {"jour": 1, "debut": "19:00", "fin": "21:00"}, {"jour": 1, "debut": "20:00", "fin": "22:00"}]'),
      ('recouvrement un jour, rien un autre',
       '[{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 2, "debut": "18:00", "fin": "21:00"}, {"jour": 2, "debut": "20:00", "fin": "21:00"}]')
    ) AS t(cas, plages) LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa')
                           || jsonb_build_object('disponibilitesDeclarees', v_cas.plages::jsonb)) = v_chev,
      'chevauchement refuse, cause nommee : ' || v_cas.cas);
  END LOOP;
  -- Contre-epreuve : les memes heures un autre jour, ou bout a bout, ne se
  -- chevauchent pas (acceptees plus haut) ; et un champ mal forme n'est jamais
  -- range sous la cause « chevauchement », meme si deux plages se recouvrent
  -- aussi (la forme se verifie d'abord).
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('disponibilitesDeclarees',
        '[{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 1, "debut": "20:00", "fin": "22:30"}]'::jsonb)) = v_generique
    AND pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('disponibilitesDeclarees',
        '[{"jour": 1, "debut": "18:00", "fin": "21:00"}, {"jour": 1, "debut": "20:00", "fin": "22:00", "note": "x"}]'::jsonb)) = v_generique,
    'un recouvrement dans des plages dont une est mal formee : refus generique, sans cause nommee');

  -- Vide ou absent : manquant (champ requis), jamais invalide.
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || '{"disponibilitesDeclarees": []}') = v_manque
    AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"disponibilitesDeclarees": null}') = v_manque
    AND pg_temp.examen(pg_temp.lu('complet_sa') - 'disponibilitesDeclarees') = v_manque,
    'aucune plage (liste vide, nulle ou absente) : champ requis manquant, pas invalide');
END $plages$;

-- (q-22/10) Une ligne par heure couverte. Les plages deviennent des lignes de
-- weekly_availability a l'entree en salle 3 (L2B, pas ecrit dans ce lot) : la
-- regle d'expansion est posee ici, en fonction de test, et prouvee contre la
-- vraie table et contre le vrai predicat d'affectation.
CREATE FUNCTION pg_temp.heures_couvertes(p_plages jsonb) RETURNS TABLE (weekday smallint, hour_local smallint)
LANGUAGE sql AS $$
  SELECT (e ->> 'jour')::smallint, h::smallint
    FROM jsonb_array_elements(p_plages) e
   CROSS JOIN LATERAL generate_series(substr(e ->> 'debut', 1, 2)::integer, substr(e ->> 'fin', 1, 2)::integer - 1) h;
$$;
DO $expansion$
DECLARE
  v_t1 constant uuid := 'ca2a0000-0000-4000-8000-0000000000c1';
  v_t2 constant uuid := 'ca2a0000-0000-4000-8000-0000000000c2';
  v_plages constant jsonb := '[{"jour": 3, "debut": "18:00", "fin": "21:00"}, {"jour": 5, "debut": "22:00", "fin": "24:00"}]';
  v_chevauche constant jsonb := '[{"jour": 3, "debut": "18:00", "fin": "21:00"}, {"jour": 3, "debut": "20:00", "fin": "22:00"}]';
  v_classe uuid;
  v_ok boolean;
  v_cas record;
BEGIN
  -- Deux enseignants prets a recevoir une Classe (compte provisoire actif, piece validee, francais).
  INSERT INTO auth.users (id, email) VALUES (v_t1, 'cand-l2a1-c1@test.invalid'), (v_t2, 'cand-l2a1-c2@test.invalid');
  INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  VALUES (v_t1, 'CA2A-ENS-00C1', 'teacher', 'Zaynab', 'Paris', 'provisional_active', 'female'),
         (v_t2, 'CA2A-ENS-00C2', 'teacher', 'Zakaria', 'Riyad', 'provisional_active', 'male');
  INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
  VALUES (v_t1, 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris'),
         (v_t2, 'SA', ARRAY['francais'], 40, 'approved', 'Asia/Riyadh');

  -- 1. Les plages valides (fuseauIana = Europe/Paris) donnent cinq lignes que la table accepte :
  --    mercredi 18, 19, 20 ; vendredi 22, 23.
  INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  SELECT v_t1, x.weekday, x.hour_local, 'Europe/Paris' FROM pg_temp.heures_couvertes(v_plages) x;
  PERFORM pg_temp.vrai((SELECT jsonb_agg(jsonb_build_array(weekday, hour_local) ORDER BY weekday, hour_local)
                          FROM public.weekly_availability WHERE profile_id = v_t1)
      = '[[3, 18], [3, 19], [3, 20], [5, 22], [5, 23]]'::jsonb
    AND pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('disponibilitesDeclarees', v_plages)) =
        '{"invalides": [], "manquants": [], "inconnus": []}'::jsonb,
    'une ligne par heure couverte : mercredi 18:00-21:00 et vendredi 22:00-24:00 donnent les heures 18, 19, 20 et 22, 23, que la table accepte');

  -- 2. Le predicat d'affectation lit ces lignes heure par heure (Classe de 60 minutes, la duree du reglage).
  FOR v_cas IN SELECT * FROM (VALUES
      (3, 18, true), (3, 19, true), (3, 20, true), (5, 22, true), (5, 23, true),
      (3, 17, false), (3, 21, false), (5, 21, false), (4, 18, false), (5, 0, false)
    ) AS t(jour, heure, couverte) LOOP
    v_classe := gen_random_uuid();
    INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    VALUES (v_classe, NULL, 'en_attente_enseignant', 'enfant', 5, 'Q22 plage ' || v_cas.jour || '-' || v_cas.heure,
            v_cas.jour, v_cas.heure, 'Europe/Paris');
    BEGIN
      PERFORM app_private.verifier_affectation_enseignant(v_classe, v_t1, true);
      v_ok := true;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM NOT LIKE 'enseignant non disponible: jour ' || v_cas.jour || ', heure ' || v_cas.heure || ',%' THEN
        RAISE EXCEPTION 'CAND-L2A1 ROUGE : motif inattendu pour le jour %, heure % : %', v_cas.jour, v_cas.heure, SQLERRM;
      END IF;
      v_ok := false;
    END;
    PERFORM pg_temp.vrai(v_ok = v_cas.couverte,
      'le predicat d''affectation lit la plage : Classe le jour ' || v_cas.jour || ' a ' || v_cas.heure || ' h '
      || CASE WHEN v_cas.couverte THEN 'couverte, acceptee' ELSE 'hors plage, refusee (enseignant non disponible)' END);
  END LOOP;

  -- 3. Le fuseau de la plage est celui de fuseauIana : une Classe donnee dans un autre fuseau se
  --    compare en instants. Riyad (UTC+3) 18:00 est Conakry (UTC+0) 15:00, sans changement d'heure.
  INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  SELECT v_t2, x.weekday, x.hour_local, 'Asia/Riyadh'
    FROM pg_temp.heures_couvertes('[{"jour": 2, "debut": "18:00", "fin": "19:00"}]') x;
  FOR v_cas IN SELECT * FROM (VALUES (15, true), (16, false), (18, false)) AS t(heure, couverte) LOOP
    v_classe := gen_random_uuid();
    INSERT INTO public.groupes (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    VALUES (v_classe, NULL, 'en_attente_enseignant', 'enfant', 5, 'Q22 fuseau ' || v_cas.heure, 2, v_cas.heure, 'Africa/Conakry');
    BEGIN
      PERFORM app_private.verifier_affectation_enseignant(v_classe, v_t2, true);
      v_ok := true;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM NOT LIKE 'enseignant non disponible:%' THEN
        RAISE EXCEPTION 'CAND-L2A1 ROUGE : motif inattendu a Conakry, heure % : %', v_cas.heure, SQLERRM;
      END IF;
      v_ok := false;
    END;
    PERFORM pg_temp.vrai(v_ok = v_cas.couverte,
      'plage mardi 18:00-19:00 a Riyad : Classe a Conakry le mardi a ' || v_cas.heure || ' h '
      || CASE WHEN v_cas.couverte THEN '(15 h Conakry = 18 h Riyad) acceptee' ELSE 'refusee' END);
  END LOOP;

  -- 4. Contre-epreuve : sans l'interdiction du chevauchement, l'expansion produirait deux fois la
  --    meme ligne (mercredi 20 h), que la cle unique de la table refuse. C'est ce que le refus
  --    « plages_qui_se_chevauchent » evite en amont.
  PERFORM pg_temp.vrai((SELECT count(*) - count(DISTINCT (weekday, hour_local)) FROM pg_temp.heures_couvertes(v_chevauche)) = 1
    AND pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('disponibilitesDeclarees', v_chevauche))
        = '{"invalides": ["disponibilitesDeclarees"], "manquants": [], "inconnus": [],
            "motifs": {"disponibilitesDeclarees": "plages_qui_se_chevauchent"}}'::jsonb,
    'contre-epreuve : des plages qui se chevauchent donneraient une heure en double (mercredi 20 h), et l''examen les refuse');
  BEGIN
    INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
    SELECT 'ca2a0000-0000-4000-8000-0000000000b1', x.weekday, x.hour_local, 'Europe/Paris'
      FROM pg_temp.heures_couvertes(v_chevauche) x;
    RAISE EXCEPTION 'CAND-L2A1 ROUGE : l''expansion de plages qui se chevauchent a ete acceptee par la table';
  EXCEPTION WHEN unique_violation THEN
    PERFORM pg_temp.ok('contre-epreuve : la cle unique de weekly_availability refuse l''expansion de plages qui se chevauchent');
  END;
END $expansion$;

-- (p-22/10) L'EXAMEN ne depend PAS du maximum de Classes par enseignant : il
-- accepte tout entier de 1 a 80 (la borne du reglage) pour classesSouhaitees,
-- quel que soit le maximum en vigueur. Une reponse valide a l'envoi ne devient
-- jamais invalide parce que la direction regle le maximum (le meme examen
-- relit les reponses envoyees : etat_dossier(), controle questionnaire_complet
-- de L2A2) : « 5 », valide au maximum de 5, l'est encore a 4, a 3, a 1. Seules
-- les options proposees a l'ecran suivent le maximum.
DO $classes_plafond$
DECLARE
  v_rien constant jsonb := '{"invalides": [], "manquants": [], "inconnus": []}';
  v_invalide constant jsonb := '{"invalides": ["classesSouhaitees"], "manquants": [], "inconnus": []}';
  v_champ jsonb := (SELECT c FROM jsonb_array_elements(pg_temp.lu('def') -> 'champs') c WHERE c ->> 'code' = 'classesSouhaitees');
  v_code text;
  v_max integer;
BEGIN
  -- Aux maximums 3 (defaut), 5, 2, 1, 80 : memes valeurs acceptees (1, 3, 4, 5,
  -- 80), memes valeurs refusees (0, 81), et l'ecran propose de 1 au maximum.
  FOREACH v_max IN ARRAY ARRAY[3, 5, 2, 1, 80] LOOP
    PERFORM pg_temp.regler(v_max);
    PERFORM pg_temp.vrai(
          pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "1"}') = v_rien
      AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "3"}') = v_rien
      AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "4"}') = v_rien
      AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "5"}') = v_rien
      AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "80"}') = v_rien
      AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "0"}') = v_invalide
      AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"classesSouhaitees": "81"}') = v_invalide
      AND pg_temp.examen(pg_temp.lu('complet_ng')) = v_rien
      AND private.questionnaire_options(pg_temp.lu('def'), v_champ)
          = (SELECT jsonb_agg(to_jsonb(n::text) ORDER BY n) FROM generate_series(1, v_max) n),
      'classes souhaitees, maximum ' || v_max || ' : l''examen accepte 1, 3, 4, 5 et 80 (une reponse envoyee ne devient jamais invalide), refuse 0 et 81 ; l''ecran propose 1 a ' || v_max);
  END LOOP;
  -- Les formes refusees le sont aussi au maximum de 80.
  FOREACH v_code IN ARRAY ARRAY['0', '00', '01', '+3', '3.0', ' 3', '3 ', 'trois', '', '-1', '100', '1e1'] LOOP
    PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || jsonb_build_object('classesSouhaitees', v_code)) = v_invalide,
      'classes souhaitees : forme refusee meme au maximum de 80 : « ' || v_code || ' »');
  END LOOP;
  PERFORM pg_temp.vrai(NOT private.questionnaire_permis(pg_temp.lu('def'), v_champ, NULL, NULL),
    'classes souhaitees : une valeur nulle n''est pas permise');
  -- Le maximum ne touche aucun autre champ a valeurs fermees.
  PERFORM pg_temp.vrai(pg_temp.examen(pg_temp.lu('complet_sa') || '{"ijazaPresentable": "4"}')
        = '{"invalides": ["ijazaPresentable"], "manquants": [], "inconnus": []}'
    AND pg_temp.examen(pg_temp.lu('complet_sa') || '{"debutPossible": "4"}')
        = '{"invalides": ["debutPossible"], "manquants": [], "inconnus": []}',
    'le maximum de Classes ne rend valide aucun autre champ a valeurs fermees (« 4 » refuse ailleurs)');
  PERFORM pg_temp.regler(3);
END $classes_plafond$;

-- La definition elle-meme : forme verifiee par la contrainte de la table
-- (cle "exclure" reservee aux langues, codes de langue, listes nommees).
DO $definition_forme$
DECLARE
  v_def jsonb := pg_temp.lu('def');
  v_champs jsonb := pg_temp.lu('def') -> 'champs';
BEGIN
  PERFORM pg_temp.vrai(private.questionnaire_definition_valide(v_def), 'la definition courante est valide');
  PERFORM pg_temp.vrai(
    NOT private.questionnaire_definition_valide(jsonb_set(v_def, '{languesHorsReferentiel}', v_def -> 'languesHorsReferentiel' || '["autre_a_preciser"]'))
    AND NOT private.questionnaire_definition_valide(jsonb_set(v_def, '{languesHorsReferentiel}', v_def -> 'languesHorsReferentiel' || '["Français"]'))
    AND NOT private.questionnaire_definition_valide(jsonb_set(v_def, '{languesHorsReferentiel}', v_def -> 'languesHorsReferentiel' || '["ha"]'))
    AND private.questionnaire_definition_valide(jsonb_set(v_def, '{languesHorsReferentiel}', v_def -> 'languesHorsReferentiel' || '["kri"]')),
    'langues hors referentiel : un code ISO 639 ou "autre", jamais autre_a_preciser, un nom ou un doublon');
  PERFORM pg_temp.vrai(
    NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "publics", "type": "choix_multiple", "requis": true, "valeurs": ["a"], "exclure": ["ar"]}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "pays", "type": "choix", "requis": true, "liste": "pays", "exclure": ["ar"]}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "langues", "type": "choix", "requis": true, "liste": "langues", "exclure": []}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "langues", "type": "choix", "requis": true, "liste": "langues", "exclure": ["ar", "ar"]}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "langues", "type": "choix", "requis": true, "liste": "langues", "exclure": [1]}'::jsonb)))
    AND private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "langues", "type": "choix", "requis": true, "liste": "langues", "exclure": ["ar", "ps"]}'::jsonb))),
    'exclure : une liste non vide, distincte, de codes de langue, sur une liste "langues" seulement');
  PERFORM pg_temp.vrai(
    private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "champx", "type": "choix", "requis": true, "valeurs": ["1", "2", "6_9"]}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "champx", "type": "choix", "requis": true, "valeurs": ["_1"]}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "champx", "type": "choix", "requis": true, "valeurs": ["A"]}'::jsonb)))
    AND NOT private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "champx", "type": "choix", "requis": true, "liste": "moyens_inconnus"}'::jsonb)))
    AND private.questionnaire_definition_valide(jsonb_build_object('champs', jsonb_build_array(
      '{"code": "champx", "type": "choix_multiple", "requis": false, "liste": "moyens_connus"}'::jsonb))),
    'codes de valeurs : un chiffre peut ouvrir un code (1, 6_9), pas un tiret bas ni une majuscule ; seules les listes nommees existent');
  PERFORM pg_temp.vrai(jsonb_array_length(v_champs) = 17
    AND (SELECT count(DISTINCT c ->> 'code') FROM jsonb_array_elements(v_champs) c) = 17,
    'dix-sept champs, tous de code distinct');
END $definition_forme$;

-- Un second brouillon met a jour le meme document ; une cle deja prise pour
-- un autre geste est refusee ; une cle de brouillon plus ancienne que la
-- derniere est une cle neuve, refusee par la version du brouillon.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('b4', public.enregistrer_reponses_salle_examen('salle-examen-1',
  pg_temp.lu('complet_sa') - 'riwayat', 1, 'cle-brouillon-c01-4'));
SELECT pg_temp.garde('e0', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-brouillon-c01-4'));
SELECT pg_temp.garde('b1v', public.enregistrer_reponses_salle_examen('salle-examen-1', '{"paysResidence": "FR"}', 0,
  'cle-brouillon-c01-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('b4') ->> 'versionBrouillon' = '2' AND pg_temp.lu('b4') -> 'manquants' = '["riwayat"]'::jsonb
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001') = 1
  AND (SELECT fuseau_iana IS NULL AND version = 1 FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000001')
  AND pg_temp.lu('e0') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('b1v') = '{"erreur": "conflit_brouillon", "versionCourante": 2}'::jsonb
  AND (SELECT cle FROM public.candidature_brouillon_cles
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001') = 'cle-brouillon-c01-4',
  'second brouillon : meme document, version 2, candidature intacte ; derniere cle reprise pour l''envoi refusee ; cle ancienne : conflit_brouillon');

-- ------------------------------------------------------------
-- (f) etat_dossier() etendu : cles gardees, jamais un motif
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('d1', public.etat_dossier());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('d1') @> '{"profil": true, "role": "teacher", "statut": "pending_kyc",
    "piece_deposee": false, "contrat_signe": false, "accuse_signe": false, "code_conduite_signe": false,
    "suit_des_cours": false}'::jsonb
  AND pg_temp.lu('d1') ?& ARRAY['piece_statut', 'motif_refus', 'depose_le', 'usage'],
  'etat_dossier : toutes les cles d''avant, valeurs inchangees');
SELECT pg_temp.vrai(pg_temp.lu('d1') -> 'candidature' @> '{"candidature": true, "type": "enseignant",
    "etape": "prequalification", "etat": "a_completer", "issue": "en_cours", "enPause": false, "version": 1,
    "aCompleter": ["questionnaire"], "peutEnvoyer": false, "pauseModele": null, "refusModele": null,
    "paiement": "inconnu", "complementDemande": [],
    "cadreReligieux": {"versionRequise": null, "accepte": false},
    "conditionsRemuneration": {"disponible": true, "version": "v2.0.0", "acceptees": false},
    "questionnaire": {"versionCourante": "salle-examen-1", "versionReponses": "salle-examen-1",
                      "perime": false, "manquants": ["riwayat"]}}'::jsonb
  AND pg_temp.lu('d1') #> '{candidature,envoiBloque}' = '["questionnaire_incomplet", "cadre_non_publie"]'::jsonb,
  'etat_dossier du candidat : etape, etat, issue, ce qui manque, envoi bloque par le questionnaire et le cadre non publie');
SELECT pg_temp.vrai(NOT (pg_temp.lu('d1') -> 'candidature') ?| ARRAY['motif', 'motifInterne', 'responsableId',
                                                                      'restreinte', 'evenements', 'decisions']
  AND (pg_temp.lu('d1') -> 'candidature')::text NOT LIKE '%motif%',
  'etat_dossier du candidat : ni motif, ni responsable, ni restriction, ni evenement, ni decision de paiement');
SELECT pg_temp.vrai((SELECT paiement = 'inconnu' AND private.paiement_etat(id) = 'inconnu'
                       AND private.paiement_declaration(id) IS NULL
                     FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000001')
  AND (SELECT reponses ->> 'paysVersement' = 'SA' AND (reponses ->> 'compteBancaire')::boolean AND brouillon
         FROM public.candidature_reponses WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001'),
  'C8 : un brouillon qui declare l''Arabie saoudite et un compte bancaire n''est pas une declaration : colonne et calcul en direct disent inconnu');
DO $sans_candidature$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('ca2a0000-0000-4000-8000-0000000000e1'::uuid, 'guardian', 'tuteur'),
      ('ca2a0000-0000-4000-8000-0000000000a1'::uuid, 'admin', 'direction'),
      ('ca2a0000-0000-4000-8000-0000000000b1'::uuid, 'teacher', 'enseignant sans candidature')) AS t(id, role, nom) LOOP
    PERFORM pg_temp.qui(v.id, v.role);
    PERFORM pg_temp.vrai(public.etat_dossier() -> 'candidature' = '{"candidature": false}'::jsonb
      AND public.etat_dossier() ->> 'role' = v.role,
      'etat_dossier sans candidature : {"candidature": false} et le reste inchange (' || v.nom || ')');
  END LOOP;
END $sans_candidature$;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000005', 'teacher');
SELECT pg_temp.vrai(public.etat_dossier() -> 'candidature' @> '{"enPause": true, "pauseModele": "pause_attente_documents",
    "aCompleter": []}'::jsonb
  AND public.etat_dossier() #>> '{candidature,repriseLe}' = (current_date + 10)::text
  AND public.etat_dossier() #> '{candidature,envoiBloque}' ? 'pause',
  'candidat en pause : modele de message et reprise, rien a completer, envoi bloque par la pause');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000008', 'teacher');
SELECT pg_temp.vrai(public.etat_dossier() -> 'candidature' @> '{"issue": "refusee", "refusModele": "refus_profil"}'::jsonb
  AND public.etat_dossier() #> '{candidature,envoiBloque}' ? 'etat',
  'candidature refusee : le modele du refus, jamais le motif');

-- ------------------------------------------------------------
-- (g) Transition 6 : envoi par le candidat
-- ------------------------------------------------------------
SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('e1', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c01-1'));
SELECT pg_temp.garde('e2', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), false,
  'v2.0.0', 1, 'cle-envoi-c01-2'));
SELECT pg_temp.garde('e3', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa') - 'riwayat',
  true, 'v2.0.0', 1, 'cle-envoi-c01-3'));
SELECT pg_temp.garde('e4', public.envoyer_reponses_salle_examen('salle-examen-1',
  pg_temp.lu('complet_sa') || '{"riwayat": ["hafs", "x"]}'::jsonb, true, 'v2.0.0', 1, 'cle-envoi-c01-4'));
SELECT pg_temp.garde('e5', public.envoyer_reponses_salle_examen('salle-examen-0', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c01-5'));
SELECT pg_temp.refus($$SELECT public.envoyer_reponses_salle_examen('salle-examen-1', '{}'::jsonb, true, NULL, 1,
  'cle-envoi-c01-x')$$, '22023', 'envoi sans la version des conditions affichees : 22023');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('e1') = '{"erreur": "engagement_non_accepte", "versionRequise": null, "publie": false}'::jsonb
  AND pg_temp.lu('e2') = '{"erreur": "accord_remuneration_requis"}'::jsonb
  AND pg_temp.lu('e3') = '{"erreur": "reponses_incompletes", "champs": ["riwayat"]}'::jsonb
  AND pg_temp.lu('e4') = '{"erreur": "reponses_invalides", "champs": ["riwayat"]}'::jsonb
  AND pg_temp.lu('e5') = '{"erreur": "questionnaire_perime", "versionCourante": "salle-examen-1"}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'transition 6 impossible sans cadre publie ; sans accord, incomplet, hors liste, perime : refus nommes, 0 ecriture');

-- Version de TEST du cadre religieux, publiee dans la transaction du scenario.
INSERT INTO public.contract_required_versions (contract_kind, version)
VALUES ('teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('e6', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c01-6'));
SELECT pg_temp.garde('d2', public.etat_dossier());
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000001', 'teacher_religious_framework', 'autre-version')$$, '42501',
  'cadre religieux : une autre version que la requise est refusee');
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000002', 'teacher_religious_framework', 'test-cadre-1')$$, '42501',
  'cadre religieux : jamais pour un autre compte');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('e6') = '{"erreur": "engagement_non_accepte", "versionRequise": "test-cadre-1", "publie": true}'::jsonb
  AND pg_temp.lu('d2') #> '{candidature,cadreReligieux}' = '{"versionRequise": "test-cadre-1", "accepte": false}'::jsonb
  AND pg_temp.lu('d2') #> '{candidature,aCompleter}' = '["questionnaire", "cadre_religieux"]'::jsonb
  AND pg_temp.lu('d2') #> '{candidature,envoiBloque}' = '["questionnaire_incomplet", "cadre_non_accepte"]'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'cadre publie, pas accepte : engagement_non_accepte avec la version requise ; etat_dossier dit quoi accepter');

-- Insertions directes sous le role authenticated (la RLS joue), une par compte.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000e1', 'guardian');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-0000000000e1', 'teacher_religious_framework', 'test-cadre-1')$$, '42501',
  'cadre religieux refuse : tuteur');
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000b1', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-0000000000b1', 'teacher_religious_framework', 'test-cadre-1')$$, '42501',
  'cadre religieux refuse : enseignant actif sans candidature');
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000008', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000008', 'teacher_religious_framework', 'test-cadre-1')$$, '42501',
  'cadre religieux refuse : candidature refusee');
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000007', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
  VALUES ('ca2a0000-0000-4000-8000-000000000007', 'teacher_religious_framework', 'test-cadre-1')$$, '42501',
  'cadre religieux refuse : compte desactive');
RESET ROLE;

-- c01 accepte le cadre par la page d'accords (insertion directe, C9), puis
-- complete son brouillon.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES ('ca2a0000-0000-4000-8000-000000000001', 'teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.garde('b5', public.enregistrer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), 2,
  'cle-brouillon-c01-5'));
SELECT pg_temp.garde('d3', public.etat_dossier());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('b5') ->> 'complet' = 'true' AND pg_temp.lu('b5') ->> 'versionBrouillon' = '3'
  AND pg_temp.lu('d3') #> '{candidature,peutEnvoyer}' = 'true'::jsonb
  AND pg_temp.lu('d3') #> '{candidature,envoiBloque}' = '[]'::jsonb
  AND pg_temp.lu('d3') #> '{candidature,aCompleter}' = '[]'::jsonb
  AND pg_temp.lu('d3') #> '{candidature,cadreReligieux,accepte}' = 'true'::jsonb,
  'cadre accepte et brouillon complet : etat_dossier dit que la candidature peut partir');

SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('e7', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 0, 'cle-envoi-c01-7'));
SELECT pg_temp.garde('e7c', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v1.9.9', 1, 'cle-envoi-c01-7c'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('e7') = '{"erreur": "conflit_candidature", "versionCourante": 1}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'L2-8 : envoi a version perimee, conflit_candidature, 0 ecriture ; les trois brouillons n''ont pas change la version');
SELECT pg_temp.vrai(pg_temp.lu('e7c') = '{"erreur": "conditions_perimees", "versionCourante": "v2.0.0"}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01')
  AND NOT EXISTS (SELECT 1 FROM public.contract_acceptances
                   WHERE profile_id = 'ca2a0000-0000-4000-8000-000000000001' AND contract_kind = 'teacher_pay_conditions'),
  'C11 : accord donne a d''autres conditions que celles en base : conditions_perimees, version courante rendue, aucun accord, 0 ecriture');

SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('e8', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c01-8'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('e8') ->> 'rejoue' = 'false'
  AND pg_temp.lu('e8') -> 'candidature' @> '{"etape": "prequalification", "etat": "en_examen", "issue": "en_cours",
      "peutEnvoyer": false, "aCompleter": []}'::jsonb
  AND pg_temp.lu('e8') #> '{candidature,envoiBloque}' = '["etat"]'::jsonb
  AND pg_temp.lu('e8') #> '{candidature,conditionsRemuneration,acceptees}' = 'true'::jsonb
  AND pg_temp.lu('e8') #>> '{candidature,questionnaire,envoyeLe}' IS NOT NULL
  AND pg_temp.lu('e8') #>> '{candidature,paiement}' = 'a_verifier',
  'transition 6 : en examen, etat relu par etat_dossier(), accord de remuneration enregistre, envoi date, paiement a verifier rendu');
SELECT pg_temp.vrai((SELECT etat = 'en_examen' AND paiement = 'a_verifier' AND version = 3
                       AND pays_residence = 'SA' AND fuseau_iana = 'Asia/Riyadh'
                     FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000001')
  AND (SELECT count(*) FROM public.candidature_reponses
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001') = 1
  AND (SELECT envoye_le IS NOT NULL AND NOT brouillon AND version = 4 AND (reponses ->> 'accordRemuneration')::boolean
              AND reponses ->> 'paysVersement' = 'SA'
         FROM public.candidature_reponses WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000001')
  AND (SELECT paiement = private.paiement_etat(id) FROM public.candidatures
        WHERE id = 'ca2acccc-0000-4000-8000-000000000001')
  AND (SELECT count(*) FROM public.contract_acceptances
        WHERE profile_id = 'ca2a0000-0000-4000-8000-000000000001' AND contract_kind = 'teacher_pay_conditions'
          AND version = 'v2.0.0') = 1,
  'transition 6 : etat en examen, paiement recalcule (L6 : a_verifier), document envoye, accord de remuneration v2.0.0');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements e
                      WHERE e.candidature_id = 'ca2acccc-0000-4000-8000-000000000001' AND e.type = 'transition'
                        AND e.etape_avant = 'prequalification' AND e.etape_apres = 'prequalification'
                        AND e.etat_avant = 'a_completer' AND e.etat_apres = 'en_examen'
                        AND e.issue_avant = 'en_cours' AND e.issue_apres = 'en_cours'
                        AND e.auteur_id = 'ca2a0000-0000-4000-8000-000000000001' AND e.motif_interne IS NULL
                        AND e.details @> '{"geste": "envoyer_reponses", "transition": 6, "auteur": "candidat",
                                           "questionnaireVersion": "salle-examen-1", "conditionsRemuneration": "v2.0.0",
                                           "cadreReligieux": "test-cadre-1",
                                           "changements": {"pays_residence": {"avant": null, "apres": "SA"},
                                                           "fuseau_iana": {"avant": null, "apres": "Asia/Riyadh"}}}'::jsonb) = 1
  AND (SELECT count(*) FROM public.candidature_evenements e
        WHERE e.candidature_id = 'ca2acccc-0000-4000-8000-000000000001' AND e.type = 'controle'
          AND e.auteur_id IS NULL AND e.details @> '{"cause": "reponses", "paiementApres": "a_verifier"}'::jsonb) = 1
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id = 'ca2acccc-0000-4000-8000-000000000001' AND a.action = 'candidature_geste'
          AND a.actor = 'ca2a0000-0000-4000-8000-000000000001'
          AND a.payload @> '{"geste": "envoyer_reponses", "transition": 6, "auteur": "candidat",
                             "etatAvant": "a_completer", "etatApres": "en_examen"}'::jsonb) = 1
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') ->> 'audit')::int
      = (pg_temp.lu('t01') ->> 'audit')::int + 1,
  'L2-11 : la transition 6 laisse 1 evenement (avant, apres, auteur candidat, aucun motif, pays et fuseau recopies avant et apres) et 1 ligne audit_logs ; le controle de paiement de L6 suit');

SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('e8r', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c01-8'));
SELECT pg_temp.garde('e9', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 3, 'cle-envoi-c01-9'));
SELECT pg_temp.garde('b6', public.enregistrer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), 0,
  'cle-brouillon-c01-6'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('e8r') = (pg_temp.lu('e8') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01'),
  'L2-8 : envoi rejoue avec la meme cle (version d''alors) : le premier resultat, 1 seul effet, 0 ecriture');
SELECT pg_temp.vrai(pg_temp.lu('e9') @> '{"erreur": "transition_interdite", "geste": "envoyer_reponses",
    "etape": "prequalification", "etat": "en_examen", "issue": "en_cours", "enPause": false, "raison": "etat"}'::jsonb
  AND pg_temp.lu('b6') @> '{"erreur": "transition_interdite", "etat": "en_examen"}'::jsonb,
  'en examen : second envoi et brouillon refuses, etat courant nomme');

-- L'historique de la direction nomme l'auteur par categorie.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('h1', public.historique_candidature('ca2acccc-0000-4000-8000-000000000001'));
RESET ROLE;
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('h1') -> 'evenements') e
                            WHERE e ->> 'type' = 'transition' AND e ->> 'etatApres' = 'en_examen'
                              AND e ->> 'auteur' = 'candidat' AND e -> 'motif' = 'null'::jsonb
                              AND (e ->> 'quand') LIKE '%Z')
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('h1') -> 'evenements') e
               WHERE e ->> 'type' = 'controle' AND e ->> 'auteur' = 'systeme'),
  'historique : la transition 6 par le candidat, l''effet de paiement par le systeme, instants UTC');

-- c02, Nigeria : CAND-Q05 ouvert, la transition 8 de L6 suit l'envoi.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES ('ca2a0000-0000-4000-8000-000000000002', 'teacher_religious_framework', public.cadre_religieux_version_requise());
SELECT pg_temp.garde('n1', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_ng'), true,
  'v2.0.0', 1, 'cle-envoi-c02-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('n1') #>> '{candidature,etat}' = 'paiement_non_disponible'
  AND pg_temp.lu('n1') #>> '{candidature,paiement}' = 'incompatible'
  AND (SELECT etat = 'paiement_non_disponible' AND paiement = 'incompatible' AND issue = 'en_cours'
       FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000002')
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000002' AND type = 'transition'
          AND details ->> 'transition' IN ('6', '8')) = 2
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = 'ca2acccc-0000-4000-8000-000000000002'
          AND action IN ('candidature_geste', 'candidature_effet_paiement')) = 2,
  'envoi depuis l''Afrique : transition 6 puis transition 8 (L6), une ligne d''audit chacune, issue en cours');

-- Le document envoye depuis le Nigeria garde ce que le directeur a decide (C17) :
-- treize langues d'explication (plus de dix), pas de langue maternelle, les
-- quatre tranches d'age, trois classes, trois moyens accessibles.
SELECT pg_temp.vrai((SELECT jsonb_array_length(reponses -> 'languesExplication') = 13
                            AND NOT reponses ? 'langueMaternelle'
                            AND reponses -> 'publics' = '["6_9", "10_13", "14_17", "adultes"]'::jsonb
                            AND reponses ->> 'classesSouhaitees' = '3'
                            AND reponses -> 'moyensAccessibles' = '["wave", "orange_money", "moov_money"]'::jsonb
                            AND envoye_le IS NOT NULL AND NOT brouillon
                       FROM public.candidature_reponses WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000002'),
  'envoi du Nigeria : 13 langues d''explication, sans langue maternelle, quatre tranches d''age, trois classes, trois moyens accessibles, tout garde');

-- (o) CONTRE-EPREUVE : les moyens accessibles ne sont lus ni par le calcul du
-- paiement ni par un controle. Memes reponses avec et sans eux : meme
-- declaration, meme dimension paiement, meme controle paiement_compatible.
-- Declarer tous les moyens du catalogue ne rend compatible personne qui n'a ni
-- compte bancaire ni operateur confirme dans son pays.
CREATE FUNCTION pg_temp.paiement_avec(p_id uuid, p_reponses jsonb) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE
  v_doc uuid;
  v_r jsonb;
BEGIN
  INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
  VALUES (p_id, 'salle-examen-1', p_reponses, 'candidat', pg_catalog.clock_timestamp() + interval '1 hour')
  RETURNING id INTO v_doc;
  v_r := jsonb_build_object('declaration', private.paiement_declaration(p_id),
                            'etat', private.paiement_etat(p_id),
                            'compatible', private.paiement_compatible(p_id));
  DELETE FROM public.candidature_reponses WHERE id = v_doc;
  RETURN v_r;
END $$;
SELECT pg_temp.garde('t01', pg_temp.trace('ca2acccc-0000-4000-8000-000000000001'));
SELECT pg_temp.garde('pm_sa0', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001', pg_temp.lu('complet_sa')));
SELECT pg_temp.garde('pm_sa1', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001',
  pg_temp.lu('complet_sa') || '{"moyensAccessibles": ["wave", "orange_money", "moov_money"]}'));
SELECT pg_temp.garde('pm_sa2', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001',
  pg_temp.lu('complet_sa') || '{"compteBancaire": false, "moyensAccessibles": []}'));
SELECT pg_temp.garde('pm_sa3', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001',
  pg_temp.lu('complet_sa') || '{"compteBancaire": false, "moyensAccessibles": ["wave", "orange_money", "moov_money"]}'));
SELECT pg_temp.garde('pm_ng0', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000002',
  pg_temp.lu('complet_ng') - 'moyensAccessibles'));
SELECT pg_temp.garde('pm_ng1', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000002', pg_temp.lu('complet_ng')));
SELECT pg_temp.garde('pm_ng2', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000002',
  (pg_temp.lu('complet_ng') - 'moyensAccessibles') || '{"compteBancaire": false}'));
SELECT pg_temp.garde('pm_ng3', pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000002',
  pg_temp.lu('complet_ng') || '{"compteBancaire": false}'));
SELECT pg_temp.vrai(pg_temp.lu('pm_sa0') = pg_temp.lu('pm_sa1')
  AND pg_temp.lu('pm_sa0') -> 'etat' = '"a_verifier"'::jsonb
  AND pg_temp.lu('pm_sa0') #> '{declaration}' = '{"paysVersement": "SA", "compteBancaire": true, "operateurs": []}'::jsonb
  AND pg_temp.lu('pm_ng0') = pg_temp.lu('pm_ng1')
  AND pg_temp.lu('pm_ng0') -> 'etat' = '"incompatible"'::jsonb
  AND pg_temp.lu('pm_ng0') #> '{declaration}' = '{"paysVersement": "NG", "compteBancaire": true, "operateurs": []}'::jsonb,
  'contre-epreuve : memes reponses avec et sans moyens accessibles, meme declaration (trois cles seulement), meme dimension paiement (Arabie saoudite a verifier, Nigeria incompatible)');
SELECT pg_temp.vrai(pg_temp.lu('pm_sa2') = pg_temp.lu('pm_sa3')
  AND pg_temp.lu('pm_sa3') -> 'etat' = '"incompatible"'::jsonb
  AND pg_temp.lu('pm_sa3') -> 'compatible' = 'false'::jsonb
  AND pg_temp.lu('pm_ng2') = pg_temp.lu('pm_ng3')
  AND pg_temp.lu('pm_ng3') -> 'etat' = '"incompatible"'::jsonb
  AND pg_temp.lu('pm_ng3') -> 'compatible' = 'false'::jsonb,
  'contre-epreuve : sans compte bancaire ni operateur confirme, cocher tous les moyens connus ne rend personne compatible (le controle de paiement reste la condition d''entree en salle 2)');
-- Contre-epreuve decisive : une ligne de mobile money CONFIRMEE (Turquie,
-- hors d'Afrique, posee dans un sous-bloc annule). Le meme operateur declare
-- dans `operateurs` rend le paiement a verifier ; declare dans
-- `moyensAccessibles` il ne change rien.
DO $ligne_confirmee$
DECLARE
  v_base jsonb := pg_temp.lu('complet_sa')
    || '{"paysResidence": "TR", "paysVersement": "TR", "fuseauIana": "Europe/Istanbul", "compteBancaire": false}';
  v_sans jsonb;
  v_operateur jsonb;
  v_accessible jsonb;
BEGIN
  BEGIN
    INSERT INTO public.referentiel_paiement (pays, methode, operateur, etat, source, source_ref, verifie_le)
    VALUES ('TR', 'mobile_money', 'wave', 'confirme', 'decision_directeur', 'scenario CAND-L2A1', current_date);
    v_sans := pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001', v_base || '{"operateurs": []}');
    v_operateur := pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001', v_base || '{"operateurs": ["wave"]}');
    v_accessible := pg_temp.paiement_avec('ca2acccc-0000-4000-8000-000000000001',
      v_base || '{"operateurs": [], "moyensAccessibles": ["wave"]}');
    RAISE EXCEPTION 'annule' USING ERRCODE = 'P0001';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'annule' THEN
      RAISE;
    END IF;
  END;
  PERFORM pg_temp.vrai(v_sans -> 'etat' = '"incompatible"'::jsonb
    AND v_operateur -> 'etat' = '"a_verifier"'::jsonb
    AND v_accessible -> 'etat' = '"incompatible"'::jsonb
    AND v_accessible = v_sans
    AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement WHERE pays = 'TR' AND methode = 'mobile_money'),
    'contre-epreuve decisive : avec une ligne confirmee, wave dans operateurs rend le paiement a verifier, wave dans moyensAccessibles le laisse incompatible, comme sans rien (ligne annulee ensuite)');
END $ligne_confirmee$;
SELECT pg_temp.vrai(pg_temp.trace('ca2acccc-0000-4000-8000-000000000001') = pg_temp.lu('t01')
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
                   WHERE n.nspname IN ('private', 'public', 'app_private')
                     AND p.proname LIKE 'paiement\_%' AND p.prosrc LIKE '%moyensAccessibles%')
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
                   WHERE n.nspname IN ('private', 'public', 'app_private')
                     AND (p.proname LIKE '%controle%' OR p.proname LIKE 'cand%' OR p.proname LIKE 'candidature%')
                     AND p.prosrc LIKE '%moyensAccessibles%'
                     AND p.proname <> 'candidature_questionnaire_envoye'),
  'moyens accessibles : aucune fonction de paiement ni aucun controle ne cite la cle (seule l''exclusion du controle questionnaire_complet de L2A2 la nomme), 0 ecriture restante');

-- ------------------------------------------------------------
-- (h) Transition 17 : retrait par le candidat (CAND-03)
-- ------------------------------------------------------------
SELECT pg_temp.garde('t03', pg_temp.trace('ca2acccc-0000-4000-8000-000000000003'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000003', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.retrait_candidat(NULL, 'cle-retrait-c03-0')$$, '22023',
  'retrait sans version attendue : 22023');
SELECT pg_temp.refus($$SELECT public.retrait_candidat(1, 'court')$$, '22023', 'cle d''idempotence trop courte : 22023');
SELECT pg_temp.garde('r1', public.retrait_candidat(1, 'cle-retrait-c03-1'));
SELECT pg_temp.garde('r1r', public.retrait_candidat(1, 'cle-retrait-c03-1'));
SELECT pg_temp.garde('r2', public.retrait_candidat(2, 'cle-retrait-c03-2'));
SELECT pg_temp.garde('r3', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 2, 'cle-envoi-c03-1'));
SELECT pg_temp.refus($$SELECT public.questionnaire_salle_examen()$$, '42501',
  'candidature retiree : le questionnaire n''est plus lu');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('r1') ->> 'rejoue' = 'false'
  AND pg_temp.lu('r1') -> 'candidature' @> '{"issue": "retiree", "etape": "prequalification", "etat": "en_examen",
      "version": 2}'::jsonb
  AND pg_temp.lu('r1r') = (pg_temp.lu('r1') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('r2') @> '{"erreur": "transition_interdite", "issue": "retiree"}'::jsonb
  AND pg_temp.lu('r3') @> '{"erreur": "transition_interdite", "issue": "retiree"}'::jsonb,
  'transition 17 : retiree, etape et etat d''origine gardes ; rejeu sans effet ; second retrait et envoi refuses');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements e
                      WHERE e.candidature_id = 'ca2acccc-0000-4000-8000-000000000003' AND e.type = 'transition'
                        AND e.issue_avant = 'en_cours' AND e.issue_apres = 'retiree'
                        AND e.auteur_id = 'ca2a0000-0000-4000-8000-000000000003' AND e.motif_interne IS NULL
                        AND e.details @> '{"geste": "retirer", "transition": 17, "auteur": "candidat",
                          "canal": "application", "entretienPlanifie": false, "pauseLevee": false,
                          "aNotifier": "retrait_enregistre"}'::jsonb) = 1
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000003') ->> 'audit')::int
      = (pg_temp.lu('t03') ->> 'audit')::int + 1
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000003') ->> 'gestes')::int = 1,
  'L2-11 : le retrait laisse 1 evenement (canal application, date, auteur candidat) et 1 ligne audit_logs');

SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000004', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('r4', public.retrait_candidat(1, 'cle-retrait-c04-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('r4') -> 'candidature' @> '{"issue": "retiree", "etape": "verifications"}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidature_evenements
               WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000004'
                 AND details @> '{"transition": 17, "entretienPlanifie": true}'::jsonb),
  'retrait en Salle de verification, entretien planifie : journalise (L4 l''annulera)');

SELECT pg_temp.garde('t05', pg_temp.trace('ca2acccc-0000-4000-8000-000000000005'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000005', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('p1', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c05-1'));
SELECT pg_temp.garde('p2', public.enregistrer_reponses_salle_examen('salle-examen-1', '{"paysResidence": "SA"}', 0,
  'cle-brouillon-c05-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('p1') @> '{"erreur": "transition_interdite", "enPause": true, "raison": "pause"}'::jsonb
  AND pg_temp.lu('p2') @> '{"erreur": "transition_interdite", "enPause": true, "raison": "pause"}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000005') = pg_temp.lu('t05'),
  'L2-9 : en pause, ni envoi ni brouillon, raison pause, 0 ecriture');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000005', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('p3', public.retrait_candidat(1, 'cle-retrait-c05-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('p3') -> 'candidature' @> '{"issue": "retiree", "enPause": false, "pauseModele": null,
    "repriseLe": null}'::jsonb
  AND (SELECT NOT en_pause AND pause_modele IS NULL AND reprise_le IS NULL
       FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000005')
  AND EXISTS (SELECT 1 FROM public.candidature_evenements
               WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000005'
                 AND details @> '{"transition": 17, "pauseLevee": true}'::jsonb),
  'retrait permis en pause : la pause est levee avec l''issue terminale (C5), journalisee');

-- c02, maintenue faute de moyen de paiement : jamais un refus, libre de partir.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000002', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('n2', public.retrait_candidat(3, 'cle-retrait-c02-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('n2') -> 'candidature' @> '{"issue": "retiree", "etape": "prequalification",
    "etat": "paiement_non_disponible"}'::jsonb,
  'paiement non disponible : le candidat reste libre de partir (retrait permis, etat d''origine garde)');

DO $retrait_refuse$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('ca2a0000-0000-4000-8000-0000000000e1'::uuid, 'guardian', 'tuteur'),
      ('ca2a0000-0000-4000-8000-0000000000b1'::uuid, 'teacher', 'enseignant sans candidature'),
      ('ca2a0000-0000-4000-8000-000000000007'::uuid, 'teacher', 'compte desactive'),
      ('ca2a0000-0000-4000-8000-0000000000a1'::uuid, 'admin', 'direction')) AS t(id, role, nom) LOOP
    PERFORM pg_temp.qui(v.id, v.role);
    PERFORM pg_temp.refus($$SELECT public.retrait_candidat(1, 'cle-retrait-refuse')$$, '42501',
      'retrait refuse : ' || v.nom);
    PERFORM pg_temp.refus($$SELECT public.envoyer_reponses_salle_examen('salle-examen-1', '{}'::jsonb, true, 'v2.0.0', 1,
      'cle-envoi-refuse')$$, '42501', 'envoi refuse : ' || v.nom);
  END LOOP;
END $retrait_refuse$;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000008', 'teacher');
SELECT pg_temp.vrai(public.retrait_candidat(1, 'cle-retrait-c08-1') @> '{"erreur": "transition_interdite",
  "issue": "refusee"}'::jsonb, 'candidature refusee : le retrait n''est pas une transition permise');

-- ------------------------------------------------------------
-- (i) Le moteur : portee par genre, cles, pause, motif, chaine d'audit
-- ------------------------------------------------------------
-- La direction de l'autre cote, super-admin compris (C4), et au genre inconnu.
SELECT pg_temp.garde('t06', pg_temp.trace('ca2acccc-0000-4000-8000-000000000006'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.garde('g1', private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000006', 'refuser',
  'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 1, 'cle-geste-c06-1', 'Motif de test', 'refus_test'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a4', 'admin');
SELECT pg_temp.garde('g2', private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000006', 'refuser',
  'direction', 'ca2a0000-0000-4000-8000-0000000000a4', 1, 'cle-geste-c06-2', 'Motif de test', 'refus_test'));
SELECT pg_temp.vrai(public.kyc_super_admin_exception_active(), 'fixture : exception super-admin active pour a4');
SELECT pg_temp.vrai(pg_temp.lu('g1') = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.lu('g2') = '{"erreur": "hors_portee"}'::jsonb
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000006') ->> 'ligne') = pg_temp.lu('t06') ->> 'ligne'
  AND (pg_temp.trace('ca2acccc-0000-4000-8000-000000000006') ->> 'evenements')::int
      = (pg_temp.lu('t06') ->> 'evenements')::int + 2
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000006' AND type = 'lecture_hors_portee') = 2
  AND (SELECT count(*) FROM public.audit_logs
        WHERE row_id = 'ca2acccc-0000-4000-8000-000000000006' AND action = 'candidature_hors_portee'
          AND payload ->> 'lecture' = 'geste:refuser') = 2,
  'geste de l''autre cote, super-admin compris : hors_portee rendu, trace comme une lecture hors portee, candidature inchangee');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a3', 'admin');
SELECT pg_temp.refus($$SELECT private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000006', 'refuser',
  'direction', 'ca2a0000-0000-4000-8000-0000000000a3', 1, 'cle-geste-c06-3', 'Motif', 'refus_test')$$, '42501',
  'direction au genre inconnu : aucun geste');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a2', 'admin');
SELECT pg_temp.vrai(private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000006', 'refuser',
    'direction', 'ca2a0000-0000-4000-8000-0000000000a2', 1, 'cle-geste-c06-4', 'Motif de test', 'refus_test')
    = '{"ok": true, "transition": 16, "variante": 1}'::jsonb,
  'direction du meme cote : le geste s''ouvre');
SELECT pg_temp.refus($$SELECT private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000006', 'refuser',
  'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 1, 'cle-geste-c06-5', 'Motif', 'refus_test')$$, '42501',
  'auteur different de la session : 42501');
SELECT pg_temp.refus($$SELECT private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000006', 'envoyer_reponses',
  'direction', 'ca2a0000-0000-4000-8000-0000000000a2', 1, 'cle-geste-c06-6')$$, '22023',
  'geste du candidat demande par la direction : 22023');

-- Une cle prise par une candidature ne sert pas a une autre.
SELECT pg_temp.garde('t09', pg_temp.trace('ca2acccc-0000-4000-8000-000000000009'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000009', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('k1', public.enregistrer_reponses_salle_examen('salle-examen-1', '{"paysResidence": "SA"}', 0,
  'cle-brouillon-c01-5'));
SELECT pg_temp.garde('k2', public.enregistrer_reponses_salle_examen('salle-examen-1', '{"paysResidence": "SA"}', 0,
  'cle-envoi-c01-8'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('k1') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('k2') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000009') = pg_temp.lu('t09'),
  'cle d''une autre candidature (derniere cle de brouillon, cle d''envoi) : refusee, 0 ecriture');

-- Le moteur, appele sans son premier temps, refuse d'ecrire hors regle.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000003', 'teacher');
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000003',
  'envoyer_reponses', 1::smallint, 'candidat', 'ca2a0000-0000-4000-8000-000000000003')$$, 'P0001',
  'appliquer hors de la regle (candidature retiree) : refuse');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000009',
  'lever_pause', 1::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', NULL, NULL,
  '{"etape": "confirmee"}'::jsonb)$$, '22023', 'changement non admis (etape) : refuse');

-- La table des regles suit la section 4.2.
SELECT pg_temp.vrai((SELECT string_agg(DISTINCT transition::text, ',' ORDER BY transition::text)
                       FROM private.candidature_gestes_regles WHERE 'direction' = ANY (motif_requis))
    = '12,15,16,17,18,19,20,21,23,25,7'
  AND (SELECT string_agg(geste, ',' ORDER BY geste) FROM private.candidature_gestes_regles WHERE pause <> 'interdite')
    = 'lever_pause,refuser,retirer'
  AND (SELECT string_agg(geste, ',' ORDER BY geste) FROM private.candidature_gestes_regles WHERE 'candidat' = ANY (auteurs))
    = 'enregistrer_reponses,envoyer_reponses,retirer'
  AND NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles WHERE 'candidat' = ANY (motif_requis)),
  'regles : motif exige ou la section 4.2 le dit (7, 12, 15, 16, 17 direction, 18 pose, 19, 20, 21, 23, 25) ; en pause seuls lever, refuser, retirer');

-- L2-10 : chaque geste a motif, depuis une source valide, sans motif : refus,
-- 0 ecriture ; avec motif (et modele quand il en faut un) : il s'ouvre.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $l2_10$
DECLARE
  r record;
  v_id uuid;
  v_avant jsonb;
  v_res jsonb;
  v_n integer := 0;
BEGIN
  FOR r IN SELECT * FROM private.candidature_gestes_regles
           WHERE 'direction' = ANY (motif_requis) ORDER BY transition, geste, variante LOOP
    v_n := v_n + 1;
    v_id := pg_temp.fixture(r.geste, r.variante, false);
    v_avant := pg_temp.trace(v_id);
    v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
                                              1, 'cle-l2-10-sans-' || v_n, NULL, 'modele_test');
    PERFORM pg_temp.vrai(v_res = jsonb_build_object('erreur', 'motif_requis', 'geste', r.geste)
      AND pg_temp.trace(v_id) = v_avant,
      'L2-10 : ' || r.geste || ' (transition ' || r.transition || ') sans motif : refus, 0 ecriture');
    v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
                                              1, 'cle-l2-10-avec-' || v_n, '   ', 'modele_test');
    PERFORM pg_temp.vrai(v_res ->> 'erreur' = 'motif_requis',
      'L2-10 : ' || r.geste || ' : un motif fait d''espaces vaut absent');
    -- Tabulations et fins de ligne ; espace insecable, espace de largeur
    -- nulle, espace ideographique (codes construits par chr, rien d'invisible
    -- dans ce fichier).
    v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
                                              1, 'cle-l2-10-tab-' || v_n, E'\t\n\r \t', 'modele_test');
    PERFORM pg_temp.vrai(v_res ->> 'erreur' = 'motif_requis' AND pg_temp.trace(v_id) = v_avant,
      'L2-10 : ' || r.geste || ' : un motif fait de tabulations et de fins de ligne vaut absent, 0 ecriture');
    v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
                                              1, 'cle-l2-10-uni-' || v_n, chr(160) || chr(8203) || chr(12288) || chr(65279),
                                              'modele_test');
    PERFORM pg_temp.vrai(v_res ->> 'erreur' = 'motif_requis' AND pg_temp.trace(v_id) = v_avant,
      'L2-10 : ' || r.geste || ' : un motif fait d''espaces Unicode vaut absent, 0 ecriture');
    IF r.modele_vers IS NOT NULL THEN
      v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
                                                1, 'cle-l2-10-modele-' || v_n, 'Motif interne', NULL);
      PERFORM pg_temp.vrai(v_res = jsonb_build_object('erreur', 'modele_requis', 'geste', r.geste)
        AND pg_temp.trace(v_id) = v_avant,
        'L2-10 : ' || r.geste || ' sans modele de message : modele_requis, 0 ecriture');
    END IF;
    v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
                                              1, 'cle-l2-10-ok-' || v_n, 'Motif interne', 'modele_test');
    PERFORM pg_temp.vrai(v_res = jsonb_build_object('ok', true, 'transition', r.transition, 'variante', r.variante),
      'L2-10 : ' || r.geste || ' avec motif : le geste s''ouvre depuis sa source');
  END LOOP;
  PERFORM pg_temp.vrai(v_n = 11, 'L2-10 : onze variantes de gestes a motif');
END $l2_10$;

-- L2-9 : en pause, tout geste autre que lever la pause, refuser ou retirer
-- est refuse depuis sa source, 0 ecriture ; ces trois-la s'ouvrent.
DO $l2_9$
DECLARE
  r record;
  v_id uuid;
  v_auteur uuid;
  v_avant jsonb;
  v_res jsonb;
  v_n integer := 0;
BEGIN
  FOR r IN SELECT * FROM private.candidature_gestes_regles ORDER BY geste, variante LOOP
    v_n := v_n + 1;
    v_id := pg_temp.fixture(r.geste, r.variante, true);
    IF 'direction' = ANY (r.auteurs) THEN
      v_auteur := 'ca2a0000-0000-4000-8000-0000000000a1';
      PERFORM pg_temp.qui(v_auteur, 'admin');
      v_avant := pg_temp.trace(v_id);
      v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'direction', v_auteur, 1, 'cle-l2-9-' || v_n,
                                                'Motif interne', 'modele_test');
    ELSE
      SELECT profile_id INTO v_auteur FROM public.candidatures WHERE id = v_id;
      PERFORM pg_temp.qui(v_auteur, 'teacher');
      v_avant := pg_temp.trace(v_id);
      v_res := private.candidature_geste_ouvrir(v_id, r.geste, 'candidat', v_auteur, 1, 'cle-l2-9-' || v_n);
    END IF;
    IF r.pause = 'interdite' THEN
      PERFORM pg_temp.vrai(v_res @> '{"erreur": "transition_interdite", "enPause": true, "raison": "pause"}'::jsonb
        AND pg_temp.trace(v_id) = v_avant,
        'L2-9 : ' || r.geste || ' v' || r.variante || ' en pause : refus nomme, 0 ecriture');
    ELSE
      PERFORM pg_temp.vrai(v_res ->> 'ok' = 'true',
        'L2-9 : ' || r.geste || ' permis pendant une pause');
    END IF;
  END LOOP;
  PERFORM pg_temp.vrai(v_n = 26, 'L2-9 : les vingt-six variantes de la table des regles');
END $l2_9$;

-- Un geste de la direction de bout en bout par le moteur (c10) : refus avec
-- motif interne et modele (L2-5 en partie), puis lecture par le candidat.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $refus_c10$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
  v_r jsonb;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000010', 'refuser', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 1, 'cle-refus-c10-1', 'Motif interne confidentiel L2A1',
    'refus_profil_incomplet');
  PERFORM pg_temp.vrai(v_o ->> 'ok' = 'true', 'refus c10 : ouvert');
  v_c := private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000010', 'refuser',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1',
    E'\t Motif interne confidentiel L2A1 \n' || chr(160), 'refus_profil_incomplet');
  v_r := private.candidature_geste_conclure('cle-refus-c10-1', 'ca2acccc-0000-4000-8000-000000000010', 'refuser',
    'ca2a0000-0000-4000-8000-0000000000a1', jsonb_build_object('version', v_c.version));
  PERFORM pg_temp.vrai(v_c.issue = 'refusee' AND v_c.issue_modele = 'refus_profil_incomplet' AND v_c.version = 2
    AND v_r = '{"version": 2, "rejoue": false}'::jsonb,
    'refus c10 : issue refusee, modele pose, version suivante, resultat garde sous la cle');
  PERFORM pg_temp.vrai(private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000010', 'refuser',
      'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 1, 'cle-refus-c10-1', 'Motif', 'refus_test')
      = '{"rejoue": {"version": 2, "rejoue": true}}'::jsonb,
    'refus c10 rejoue avec la version d''alors : premier resultat, aucun nouvel effet');
END $refus_c10$;
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements
                      WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000010'
                        AND motif_interne = 'Motif interne confidentiel L2A1' AND issue_apres = 'refusee'
                        AND details @> '{"geste": "refuser", "transition": 16, "auteur": "direction",
                                         "modele": "refus_profil_incomplet"}'::jsonb) = 1
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = 'ca2acccc-0000-4000-8000-000000000010'
          AND action = 'candidature_geste') = 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE row_id = 'ca2acccc-0000-4000-8000-000000000010'
                   AND (payload::text LIKE '%confidentiel%' OR payload ? 'motif')),
  'refus : motif interne garde dans l''evenement seulement (blancs de tete et de queue retires), jamais dans audit_logs');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000010', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('d10', public.etat_dossier());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('d10') -> 'candidature' @> '{"issue": "refusee", "refusModele": "refus_profil_incomplet",
    "peutEnvoyer": false}'::jsonb
  AND pg_temp.lu('d10')::text NOT LIKE '%confidentiel%'
  AND pg_temp.lu('d10')::text NOT LIKE '%Motif interne%',
  'L2-5 : refus lu par le candidat : le modele, 0 motif interne dans etat_dossier()');

-- Pause et reprise par le moteur : le modele de la pause, la reprise
-- facultative, puis tout leve.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $pause_c09$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000009', 'mettre_en_pause', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 1, 'cle-pause-c09-1', 'Motif de pause', 'pause_test');
  v_c := private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000009', 'mettre_en_pause',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif de pause',
    'pause_test', jsonb_build_object('reprise_le', current_date + 7));
  PERFORM private.candidature_geste_conclure('cle-pause-c09-1', v_c.id, 'mettre_en_pause',
    'ca2a0000-0000-4000-8000-0000000000a1', jsonb_build_object('version', v_c.version));
  PERFORM pg_temp.vrai(v_c.en_pause AND v_c.pause_modele = 'pause_test' AND v_c.reprise_le = current_date + 7,
    'pause : drapeau, modele, reprise');
END $pause_c09$;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000009', 'teacher');
SELECT pg_temp.vrai(public.etat_dossier() -> 'candidature' @> '{"enPause": true, "pauseModele": "pause_test"}'::jsonb
  AND public.etat_dossier()::text NOT LIKE '%Motif de pause%',
  'pause lue par le candidat : le modele seulement');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $reprise_c09$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000009', 'lever_pause', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 2, 'cle-pause-c09-2');
  v_c := private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000009', 'lever_pause',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1');
  PERFORM pg_temp.vrai(NOT v_c.en_pause AND v_c.pause_modele IS NULL AND v_c.reprise_le IS NULL
    AND (SELECT count(*) FROM public.candidature_evenements
          WHERE candidature_id = v_c.id AND type IN ('pause', 'reprise')) = 2,
    'reprise : drapeau, modele et date leves ; un evenement pause et un evenement reprise');
END $reprise_c09$;

-- L2-11 : une ligne d'audit par transition de ce scenario, chaine verifiable.
SELECT pg_temp.vrai((SELECT bool_and(
                       (SELECT count(*) FROM public.audit_logs a
                         WHERE a.row_id = c.id::text AND a.action = 'candidature_geste')
                       = (SELECT count(*) FROM public.candidature_evenements e
                           WHERE e.candidature_id = c.id AND e.details ? 'geste'))
                     FROM public.candidatures c WHERE c.id::text LIKE 'ca2acccc%'),
  'L2-11 : autant de lignes audit_logs que de transitions du moteur, candidature par candidature');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('chaine', (SELECT to_jsonb(v) FROM public.verifier_chaine_audit(5000) v));
RESET ROLE;
SELECT pg_temp.vrai((pg_temp.lu('chaine') ->> 'rompues')::int = 0
  AND (pg_temp.lu('chaine') ->> 'verifiees')::int = (SELECT count(*) FROM public.audit_logs)
  AND (SELECT count(*) FROM public.audit_logs) >= 11,
  'L2-11 : chaine d''audit verifiee par verifier_chaine_audit, 0 maillon rompu');

-- ------------------------------------------------------------
-- (k) Journal d'audit et accords bornes par genre (C15, CAND-Q07)
-- ------------------------------------------------------------
-- c13, candidate (femme) : accepte le cadre, envoie, puis se retire. La
-- direction hommes (a1) ne doit rien lire d'elle ; la direction femmes (a2)
-- la lit par sa reference, jamais par son nom ; le super-admin (a4, homme)
-- la lit, et sa lecture se journalise.
SELECT pg_temp.vrai((SELECT genre = 'female' FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000013')
  AND (SELECT genre = 'female' FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000002'),
  'fixture : c13 et c02 sont du cote des femmes (genre recopie du compte)');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000013', 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES ('ca2a0000-0000-4000-8000-000000000013', 'teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.garde('j13a', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c13-1'));
SELECT pg_temp.garde('j13b', public.retrait_candidat(3, 'cle-retrait-c13-1'));
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a2', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('liste_a2', public.lister_candidatures());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('j13a') #>> '{candidature,etat}' = 'en_examen'
  AND pg_temp.lu('j13b') #>> '{candidature,issue}' = 'retiree'
  AND (SELECT count(*) FROM public.audit_logs
        WHERE row_id = 'ca2acccc-0000-4000-8000-000000000013' AND actor = 'ca2a0000-0000-4000-8000-000000000013'
          AND action = 'candidature_geste') = 2
  AND (SELECT count(*) FROM public.contract_acceptances
        WHERE profile_id = 'ca2a0000-0000-4000-8000-000000000013') = 2,
  'fixture : c13 a envoye puis s''est retiree, deux lignes d''audit dont elle est l''auteur, deux accords');

-- Une ligne d'audit ecrite par c13 sur une autre table (comme le depot d'une
-- piece ou un accord le feraient) : son cote est celui de sa candidature.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000013', 'teacher');
SELECT public.log_sensitive_access('cand_l2a1_essai_autre_table', 'kyc_documents', NULL, '{}'::jsonb);

-- Ce qu'un compte de la direction lit de c13 et de c02 (Nigeria, effet de
-- paiement de L6 ecrit dans sa session), par toutes les voies.
CREATE FUNCTION pg_temp.vu(p_cand uuid, p_profil uuid) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE
  v_f jsonb := public.journal_audit_filtres();
BEGIN
  RETURN jsonb_build_object(
    'journal_acteur', (SELECT count(*) FROM public.journal_audit(p_profil, NULL, NULL, 200, NULL, NULL) j),
    'journal_ligne', (SELECT count(*) FROM public.journal_audit(NULL, 'candidature_geste', NULL, 200, NULL, NULL) j
                       WHERE j.ligne_visee = p_cand::text)
                     + (SELECT count(*) FROM public.journal_audit(NULL, 'candidature_effet_paiement', NULL, 200, NULL, NULL) j
                         WHERE j.ligne_visee = p_cand::text),
    'noms', (SELECT coalesce(jsonb_agg(DISTINCT j.nom_acteur), '[]'::jsonb)
               FROM public.journal_audit(p_profil, NULL, NULL, 200, NULL, NULL) j),
    'filtres_acteur', (SELECT coalesce(jsonb_agg(a ->> 'nom'), '[]'::jsonb)
                         FROM jsonb_array_elements(v_f -> 'acteurs') a WHERE a ->> 'id' = p_profil::text),
    'filtres_total', v_f -> 'total',
    'direct', (SELECT count(*) FROM public.audit_logs a WHERE a.row_id = p_cand::text OR a.actor = p_profil),
    'accords', (SELECT count(*) FROM public.contract_acceptances c WHERE c.profile_id = p_profil));
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.vu(uuid, uuid) TO authenticated;

DO $vu$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('a1', 'ca2a0000-0000-4000-8000-0000000000a1'::uuid), ('a2', 'ca2a0000-0000-4000-8000-0000000000a2'::uuid),
      ('a3', 'ca2a0000-0000-4000-8000-0000000000a3'::uuid), ('a4', 'ca2a0000-0000-4000-8000-0000000000a4'::uuid))
      AS t(nom, id) LOOP
    PERFORM pg_temp.qui(v.id, 'admin');
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM pg_temp.garde('vu13_' || v.nom, pg_temp.vu('ca2acccc-0000-4000-8000-000000000013',
                                                      'ca2a0000-0000-4000-8000-000000000013'));
    PERFORM pg_temp.garde('vu02_' || v.nom, pg_temp.vu('ca2acccc-0000-4000-8000-000000000002',
                                                      'ca2a0000-0000-4000-8000-000000000002'));
    EXECUTE 'RESET ROLE';
  END LOOP;
END $vu$;
SELECT pg_temp.vrai(pg_temp.lu('vu13_a1') @> '{"journal_acteur": 0, "journal_ligne": 0, "noms": [], "filtres_acteur": [],
                                             "direct": 0, "accords": 0}'::jsonb
  AND pg_temp.lu('vu02_a1') @> '{"journal_acteur": 0, "journal_ligne": 0, "filtres_acteur": [], "direct": 0, "accords": 0}'::jsonb,
  'C15 : la direction de l''autre cote ne lit aucune ligne d''une candidate (journal_audit, journal_audit_filtres, audit_logs direct, contract_acceptances)');
SELECT pg_temp.vrai(pg_temp.lu('vu13_a3') @> '{"journal_acteur": 0, "journal_ligne": 0, "filtres_acteur": [], "direct": 0}'::jsonb
  AND pg_temp.lu('vu02_a3') @> '{"journal_acteur": 0, "journal_ligne": 0, "direct": 0}'::jsonb,
  'C15 : une direction au genre inconnu ne lit aucune ligne qui a un cote');
SELECT pg_temp.vrai(pg_temp.lu('vu13_a2') @> '{"journal_acteur": 3, "journal_ligne": 2, "direct": 3, "accords": 2}'::jsonb
  AND pg_temp.lu('vu13_a2') -> 'noms' = jsonb_build_array((SELECT reference FROM public.candidatures
                                                            WHERE id = 'ca2acccc-0000-4000-8000-000000000013'))
  AND pg_temp.lu('vu13_a2') -> 'filtres_acteur' = pg_temp.lu('vu13_a2') -> 'noms'
  AND pg_temp.lu('vu13_a2')::text NOT LIKE '%Maryam%' AND pg_temp.lu('vu13_a2')::text NOT LIKE '%Journal%'
  AND pg_temp.lu('vu02_a2') @> '{"journal_acteur": 3, "journal_ligne": 3, "accords": 2}'::jsonb
  AND pg_temp.lu('vu02_a2') -> 'noms' = jsonb_build_array((SELECT reference FROM public.candidatures
                                                            WHERE id = 'ca2acccc-0000-4000-8000-000000000002'))
  AND pg_temp.lu('vu02_a2')::text NOT LIKE '%Hafsa%',
  'C15 : la direction du meme cote lit ses lignes ; l''auteur candidat est nomme par sa reference CAND-, jamais par son nom (8.3)');
SELECT pg_temp.vrai(pg_temp.lu('vu13_a4') @> '{"journal_acteur": 3, "journal_ligne": 2, "direct": 0, "accords": 2}'::jsonb
  AND (pg_temp.lu('vu13_a4') ->> 'filtres_total')::int > (pg_temp.lu('vu13_a1') ->> 'filtres_total')::int
  AND (pg_temp.lu('vu13_a4') ->> 'filtres_total')::int > (pg_temp.lu('vu13_a2') ->> 'filtres_total')::int,
  'C15 : le super-admin lit les deux cotes par journal_audit (jamais par la lecture directe, qui ne se journalise pas)');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs
                      WHERE action = 'candidature_exception_super_admin' AND table_name = 'audit_logs'
                        AND actor = 'ca2a0000-0000-4000-8000-0000000000a4'
                        AND payload ->> 'motif' = 'exception_super_admin_kyc'
                        AND payload ->> 'lecture' = 'journal_audit' AND (payload ->> 'lignesAutreCote')::int > 0) >= 2
  AND (SELECT count(*) FROM public.audit_logs
        WHERE action = 'candidature_exception_super_admin' AND table_name = 'audit_logs'
          AND payload ->> 'lecture' = 'journal_audit_filtres') >= 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs
                   WHERE action = 'candidature_exception_super_admin' AND table_name = 'audit_logs'
                     AND actor IS DISTINCT FROM 'ca2a0000-0000-4000-8000-0000000000a4'),
  'C15 : chaque lecture du journal qui rend des lignes de l''autre cote au super-admin laisse une trace, lui seul en laisse');
-- Les traces de l'exception, les lectures de liste et les tentatives hors
-- portee restent de leur cote.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('k_a1', jsonb_build_object(
  'traces', (SELECT count(*) FROM public.journal_audit(NULL, 'candidature_exception_super_admin', NULL, 200, NULL, NULL) j
              WHERE j.table_visee = 'audit_logs'),
  'listes_a2', (SELECT count(*) FROM public.journal_audit('ca2a0000-0000-4000-8000-0000000000a2', 'candidatures_liste',
                                                          NULL, 200, NULL, NULL)),
  'hors_portee_c06', (SELECT count(*) FROM public.journal_audit(NULL, 'candidature_hors_portee', NULL, 200, NULL, NULL) j
                       WHERE j.ligne_visee = 'ca2acccc-0000-4000-8000-000000000006')));
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a2', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('k_a2', jsonb_build_object(
  'traces', (SELECT count(*) FROM public.journal_audit(NULL, 'candidature_exception_super_admin', NULL, 200, NULL, NULL) j
              WHERE j.table_visee = 'audit_logs'),
  'listes_a2', (SELECT count(*) FROM public.journal_audit('ca2a0000-0000-4000-8000-0000000000a2', 'candidatures_liste',
                                                          NULL, 200, NULL, NULL)),
  'hors_portee_c06', (SELECT jsonb_agg(j.nom_acteur ORDER BY j.nom_acteur)
                        FROM public.journal_audit(NULL, 'candidature_hors_portee', NULL, 200, NULL, NULL) j
                       WHERE j.ligne_visee = 'ca2acccc-0000-4000-8000-000000000006')));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('k_a1') = '{"traces": 0, "listes_a2": 0, "hors_portee_c06": 0}'::jsonb
  AND pg_temp.lu('k_a2') @> '{"traces": 0, "listes_a2": 1}'::jsonb
  AND pg_temp.lu('k_a2') -> 'hors_portee_c06' = '["Direction Homme", "Super Admin"]'::jsonb,
  'C15 : traces de l''exception (super-admin seul), liste lue par a2 et tentatives hors portee sur c06 : lues du seul cote de c06, auteurs de la direction nommes');

-- Les deux formes de la regle (ligne a ligne pour journal_audit et la
-- policy, ensembliste pour journal_audit_filtres) rendent le meme cote et la
-- meme reference, ligne par ligne, sur tout le journal du scenario.
SELECT pg_temp.vrai((SELECT count(*) FROM private.audit_logs_cotes WHERE cote IS NOT NULL) > 10
  AND (SELECT bool_and(v.cote IS NOT DISTINCT FROM j.cote AND v.reference_acteur IS NOT DISTINCT FROM j.reference_acteur)
         FROM private.audit_logs_cotes v
         CROSS JOIN LATERAL private.journal_portee(v.table_name, v.row_id, v.actor, v.payload) j)
  AND (SELECT count(*) FROM private.audit_logs_cotes) = (SELECT count(*) FROM public.audit_logs),
  'C15 : private.journal_portee et private.audit_logs_cotes rendent le meme cote et la meme reference pour chaque ligne');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT count(*) FROM private.audit_logs_cotes$$, '42501',
  'la vue des cotes du journal ne se lit par aucun compte');
RESET ROLE;

-- ------------------------------------------------------------
-- (l) Le brouillon ne gene jamais un geste de la direction
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('v12', public.lire_candidature('ca2acccc-0000-4000-8000-000000000012'));
RESET ROLE;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000012', 'teacher');
SET LOCAL ROLE authenticated;
DO $brouillons_c12$
BEGIN
  FOR i IN 1..25 LOOP
    PERFORM pg_temp.garde('b12_' || i, public.enregistrer_reponses_salle_examen('salle-examen-1',
      (pg_temp.lu('complet_sa') - 'riwayat') || jsonb_build_object('classesSouhaitees',
        CASE WHEN i % 2 = 0 THEN '1' ELSE '2' END),
      i - 1, 'cle-brouillon-c12-' || lpad(i::text, 2, '0')));
  END LOOP;
END $brouillons_c12$;
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('b12_25') @> '{"rejoue": false, "versionBrouillon": 25, "complet": false}'::jsonb
  AND (SELECT version FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000012')
      = (pg_temp.lu('v12') ->> 'version')::int
  AND (SELECT count(*) FROM public.candidature_gestes WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000012') = 0
  AND (SELECT count(*) FROM public.candidature_brouillon_cles
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000012' AND cle = 'cle-brouillon-c12-25'
          AND NOT resultat ? 'reponses') = 1
  AND (SELECT count(*) = 1 AND bool_and(version = 25 AND brouillon) FROM public.candidature_reponses
        WHERE candidature_id = 'ca2acccc-0000-4000-8000-000000000012'),
  'vingt-cinq brouillons : un document a la version 25, version de la candidature inchangee, une seule cle gardee, sans reponse');
-- Une reponse serait un membre nomme comme un champ (paysResidence...) ou un
-- objet reponses, a toute profondeur ; un champ manquant n'est qu'un code
-- dans une liste.
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_gestes) > 0
  AND NOT EXISTS (SELECT 1 FROM public.candidature_gestes g
                   WHERE jsonb_path_exists(g.resultat, 'lax $.**.reponses')
                      OR jsonb_path_exists(g.resultat, 'lax $.**.paysResidence')
                      OR jsonb_path_exists(g.resultat, 'lax $.**.langueMaternelle')
                      OR jsonb_path_exists(g.resultat, 'lax $.**.languesExplication')
                      OR jsonb_path_exists(g.resultat, 'lax $.**.moyensAccessibles'))
  AND NOT EXISTS (SELECT 1 FROM public.candidature_brouillon_cles b
                   WHERE jsonb_path_exists(b.resultat, 'lax $.**.reponses')
                      OR jsonb_path_exists(b.resultat, 'lax $.**.paysResidence')),
  'conservation : aucun resultat garde sous une cle ne porte une reponse du candidat (CAND-Q21)');
SELECT pg_temp.vrai((SELECT paiement = 'inconnu' AND private.paiement_etat(id) = 'inconnu'
                     FROM public.candidatures WHERE id = 'ca2acccc-0000-4000-8000-000000000012'),
  'C8 : apres vingt-cinq brouillons qui declarent un compte bancaire en Arabie saoudite, colonne et calcul en direct disent inconnu');
SELECT pg_temp.garde('t12', pg_temp.trace('ca2acccc-0000-4000-8000-000000000012'));
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000012', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('b12r', public.enregistrer_reponses_salle_examen('salle-examen-1', '{}'::jsonb, 24,
  'cle-brouillon-c12-25'));
SELECT pg_temp.garde('b12v', public.enregistrer_reponses_salle_examen('salle-examen-1', '{}'::jsonb, 4,
  'cle-brouillon-c12-05'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('b12r') = (pg_temp.lu('b12_25') - 'rejoue') || '{"rejoue": true}'::jsonb
  AND pg_temp.lu('b12v') = '{"erreur": "conflit_brouillon", "versionCourante": 25}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000012') = pg_temp.lu('t12'),
  'derniere cle rejouee : premier resultat ; cle plus ancienne : conflit_brouillon ; 0 ecriture');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $direction_c12$
DECLARE
  v_version integer := (pg_temp.lu('v12') ->> 'version')::int;
  v_o jsonb;
  v_c public.candidatures;
BEGIN
  PERFORM pg_temp.vrai(private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000012', 'refuser', 'direction',
      'ca2a0000-0000-4000-8000-0000000000a1', v_version, 'cle-refus-c12-1', 'Motif de test', 'refus_test') ->> 'ok' = 'true',
    'refus ouvert a la version lue par la direction avant vingt-cinq brouillons');
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000012', 'mettre_en_pause', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', v_version, 'cle-pause-c12-1', 'Motif de test', 'pause_test');
  v_c := private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000012', 'mettre_en_pause',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif de test', 'pause_test');
  PERFORM pg_temp.vrai(v_o ->> 'ok' = 'true' AND v_c.en_pause AND v_c.version = v_version + 1,
    'pause posee a la version lue par la direction : les brouillons du candidat ne la refusent pas');
END $direction_c12$;

-- ------------------------------------------------------------
-- (m) Ce qui est demande au candidat : complement et cadre neuf
-- ------------------------------------------------------------
-- Transition 7 (c01, en examen) : le complement se lit, puis l'envoi le leve.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $complement_c01$
DECLARE
  v_o jsonb;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000001', 'demander_complement', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 3, 'cle-complement-c01-1', 'Motif interne');
  PERFORM private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000001', 'demander_complement',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif interne', NULL,
    '{}'::jsonb, '{"aCompleter": ["langues", "disponibilites"]}'::jsonb);
  PERFORM pg_temp.vrai(v_o ->> 'transition' = '7', 'complement en Salle d''examen : transition 7');
END $complement_c01$;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000001', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('m1', public.etat_dossier() -> 'candidature');
SELECT pg_temp.garde('m2', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 4, 'cle-envoi-c01-10') -> 'candidature');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('m1') @> '{"etat": "a_completer", "complementDemande": ["langues", "disponibilites"],
    "peutEnvoyer": true}'::jsonb
  AND pg_temp.lu('m2') @> '{"etat": "en_examen", "complementDemande": []}'::jsonb
  AND pg_temp.lu('m1')::text NOT LIKE '%Motif interne%',
  'transition 7 : les elements demandes se lisent (jamais le motif), et le renvoi (6) les leve');
-- Transition 23 (c14, Salle de verification et d'entretien) et cadre neuf.
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000014', 'teacher');
SELECT pg_temp.garde('m3', public.etat_dossier() -> 'candidature');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $complement_c14$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000014', 'demander_complement', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 1, 'cle-complement-c14-1', 'Motif interne');
  v_c := private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'demander_complement',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif interne', NULL,
    '{}'::jsonb, '{"aCompleter": ["piece_identite", "langues"]}'::jsonb);
  PERFORM pg_temp.vrai(v_o ->> 'transition' = '23' AND v_c.etat = 'entretien_a_planifier' AND v_c.version = 2,
    'complement en Salle de verification et d''entretien : transition 23, meme etat');
END $complement_c14$;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000014', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('m4', public.etat_dossier() -> 'candidature');
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES ('ca2a0000-0000-4000-8000-000000000014', 'teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.garde('m5', public.etat_dossier() -> 'candidature');
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('m3') @> '{"etape": "verifications", "aCompleter": ["cadre_religieux"],
    "complementDemande": []}'::jsonb
  AND pg_temp.lu('m4') @> '{"aCompleter": ["cadre_religieux"], "complementDemande": ["piece_identite", "langues"]}'::jsonb
  AND pg_temp.lu('m5') @> '{"aCompleter": [], "complementDemande": ["piece_identite", "langues"],
                            "cadreReligieux": {"accepte": true}}'::jsonb,
  'salle 2 : cadre a une version requise non acceptee nomme dans aCompleter, accepte depuis la salle 2 ; complement de la transition 23 lu');
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
DO $complement_c14_leve$
DECLARE
  v_o jsonb;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000014', 'demander_complement', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 2, 'cle-complement-c14-2', 'Motif interne');
  PERFORM private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'demander_complement',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif interne', NULL,
    '{}'::jsonb, '{"aCompleter": []}'::jsonb);
END $complement_c14_leve$;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000014', 'teacher');
SELECT pg_temp.vrai(public.etat_dossier() #> '{candidature,complementDemande}' = '[]'::jsonb,
  'salle 2 : une demande plus recente, vide, remplace la precedente');

-- ------------------------------------------------------------
-- (n) Changements admis par geste ; responsable du meme cote (C16)
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.garde('t14', pg_temp.trace('ca2acccc-0000-4000-8000-000000000014'));
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'refuser',
  1::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif', 'refus_test',
  '{"responsable_id": "ca2a0000-0000-4000-8000-0000000000a1"}'::jsonb)$$, '22023',
  'refus qui pose un responsable : changement non admis');
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'mettre_en_pause',
  1::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', 'Motif', 'pause_test',
  '{"pays_residence": "FR"}'::jsonb)$$, '22023', 'pause qui change le pays : changement non admis');
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'definir_responsable',
  1::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', NULL, NULL,
  '{"responsable_id": "ca2a0000-0000-4000-8000-0000000000a2"}'::jsonb)$$, '42501',
  'responsable de l''autre cote : refuse');
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'definir_responsable',
  1::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', NULL, NULL,
  '{"responsable_id": "ca2a0000-0000-4000-8000-0000000000a3"}'::jsonb)$$, '42501',
  'responsable au genre inconnu : refuse');
SELECT pg_temp.refus($$SELECT private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'definir_responsable',
  1::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', NULL, NULL,
  '{"responsable_id": "ca2a0000-0000-4000-8000-0000000000b1"}'::jsonb)$$, '42501',
  'responsable hors de la direction : refuse');
SELECT pg_temp.vrai(pg_temp.trace('ca2acccc-0000-4000-8000-000000000014') = pg_temp.lu('t14'),
  'changements refuses : 0 ecriture');
DO $responsable_c14$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
BEGIN
  v_o := private.candidature_geste_ouvrir('ca2acccc-0000-4000-8000-000000000014', 'definir_responsable', 'direction',
    'ca2a0000-0000-4000-8000-0000000000a1', 3, 'cle-responsable-c14-1');
  v_c := private.candidature_geste_appliquer('ca2acccc-0000-4000-8000-000000000014', 'definir_responsable',
    (v_o ->> 'variante')::smallint, 'direction', 'ca2a0000-0000-4000-8000-0000000000a1', NULL, NULL,
    '{"responsable_id": "ca2a0000-0000-4000-8000-0000000000a1"}'::jsonb);
  PERFORM pg_temp.vrai(v_o ->> 'transition' = '28' AND v_c.responsable_id = 'ca2a0000-0000-4000-8000-0000000000a1'
    AND EXISTS (SELECT 1 FROM public.candidature_evenements e
                 WHERE e.candidature_id = v_c.id AND e.type = 'responsable'
                   AND e.details @> '{"geste": "definir_responsable", "transition": 28,
                     "changements": {"responsable_id": {"avant": null, "apres": "ca2a0000-0000-4000-8000-0000000000a1"}}}'::jsonb),
    'transition 28 : responsable du meme cote pose, avant et apres dans l''evenement');
END $responsable_c14$;

-- L2-11, de nouveau apres (k) a (n) : une ligne d'audit par transition.
SELECT pg_temp.vrai((SELECT bool_and(
                       (SELECT count(*) FROM public.audit_logs a
                         WHERE a.row_id = c.id::text AND a.action = 'candidature_geste')
                       = (SELECT count(*) FROM public.candidature_evenements e
                           WHERE e.candidature_id = c.id AND e.details ? 'geste'))
                     FROM public.candidatures c WHERE c.id::text LIKE 'ca2acccc%'),
  'L2-11 : autant de lignes audit_logs que de transitions du moteur, apres les gestes de (k) a (n)');

-- ------------------------------------------------------------
-- (j) Aucun montant rendu, la part lue en base : un taux change en base ne
-- change pas la reponse, une part changee la change
-- ------------------------------------------------------------
-- En dernier : les gardes d'ajout seul sont levees le temps du controle, puis
-- remises ; tout est annule par le ROLLBACK final.
ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
UPDATE public.politiques_commerciales SET taux_eleve_heure_enfant_mineur = 211, plafond_eleve_heure_enfant_mineur = 211
 WHERE version = 'v2.0.0';
ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;
ALTER TABLE public.politique_part_enseignant DISABLE TRIGGER politique_part_enseignant_immuable;
UPDATE public.politique_part_enseignant SET part_adulte_pour_mille = 480 WHERE politique_version = 'v2.0.0';
ALTER TABLE public.politique_part_enseignant ENABLE TRIGGER politique_part_enseignant_immuable;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000009', 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.garde('cond2', public.conditions_remuneration_candidat());
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('cond2') -> 'publics' -> 0 = pg_temp.lu('cond') -> 'publics' -> 0
  AND pg_temp.lu('cond2') #>> '{publics,0,partPourMille}' = '470'
  AND pg_temp.lu('cond2')::text NOT LIKE '%211%'
  AND NOT jsonb_path_exists(pg_temp.lu('cond2'), 'lax $.**.parElevePresentEtParHeure')
  AND NOT jsonb_path_exists(pg_temp.lu('cond2'), 'lax $.**.devise'),
  'conditions : un taux change en base ne change pas la reponse, qui ne porte aucun montant (decision du 22/10)');
SELECT pg_temp.vrai(pg_temp.lu('cond2') #>> '{publics,1,partPourMille}' = '480'
  AND pg_temp.lu('cond2') -> 'publics' -> 1 <> pg_temp.lu('cond') -> 'publics' -> 1,
  'conditions : une part changee en base change la reponse (rien en dur)');

-- Une politique sans sa ligne de part de l'enseignant n'est jamais rendue
-- (CAND-BR-12 : la part s'affiche toujours) : conditions indisponibles, envoi
-- refuse sans ecriture.
ALTER TABLE public.politique_part_enseignant DISABLE TRIGGER politique_part_enseignant_immuable;
DELETE FROM public.politique_part_enseignant WHERE politique_version = 'v2.0.0';
ALTER TABLE public.politique_part_enseignant ENABLE TRIGGER politique_part_enseignant_immuable;
SELECT pg_temp.qui('ca2a0000-0000-4000-8000-000000000011', 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES ('ca2a0000-0000-4000-8000-000000000011', 'teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.garde('t11', pg_temp.trace('ca2acccc-0000-4000-8000-000000000011'));
SELECT pg_temp.garde('cond3', public.conditions_remuneration_candidat());
SELECT pg_temp.garde('d11', public.etat_dossier() -> 'candidature');
SELECT pg_temp.garde('e11', public.envoyer_reponses_salle_examen('salle-examen-1', pg_temp.lu('complet_sa'), true,
  'v2.0.0', 1, 'cle-envoi-c11-1'));
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.lu('cond3') = '{"disponible": false}'::jsonb
  AND pg_temp.lu('d11') @> '{"conditionsRemuneration": {"disponible": false, "version": null}, "peutEnvoyer": false}'::jsonb
  AND pg_temp.lu('d11') -> 'envoiBloque' ? 'conditions_indisponibles'
  AND pg_temp.lu('e11') = '{"erreur": "conditions_indisponibles"}'::jsonb
  AND pg_temp.trace('ca2acccc-0000-4000-8000-000000000011') = pg_temp.lu('t11'),
  'politique sans part de l''enseignant : conditions indisponibles, envoi refuse, aucun accord, 0 ecriture');

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 417 THEN
    RAISE EXCEPTION 'CAND-L2A1 ROUGE : % controles executes, 417 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L2A1 : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
