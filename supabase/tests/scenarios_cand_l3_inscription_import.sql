-- CAND-L3 : inscription publique sans invitation, import controle des reponses
-- des formulaires, rapprochement et liste des personnes a prevenir. Migration
-- 20261022000600_cand_l3_inscription_import_rapprochement.sql, sur le moteur de
-- CAND-L2A1 et le socle de CAND-L1 / CAND-L1B.
-- Cas de la spec consolidee, section 12.1 : L3-1 (inscription sans courriel
-- confirme), L3-2 et L3-17 (plafond horaire : la meme reponse que le succes),
-- L3-3 (la forme du compte), L3-4 (essai a blanc : aucune ecriture, compteurs),
-- L3-5 (confirmation, puis second import identique), L3-6 (B : deja connue),
-- L3-7 et L3-12 (rapprochement par courriel confirme, par telephone seul, par
-- nom), L3-10 (colonne J : aucun creneau n'est un disponibilite), L3-11
-- (doublons : la plus recente l'emporte, CAND-Q16), L3-13 (sans genre),
-- L3-14 (seconde inscription), L3-15 (une directrice est refusee), L3-16
-- (reimport d'une ligne corrigee), L3-18 (cle de mise en ligne), L3-19
-- (personne de B reconnue, rien de pre-rempli) ; L3-8 et L3-9 (inviter,
-- expiration) restent hors de ce lot (file des courriels, L5). Plus : la
-- portee par genre de chaque lecture et de chaque geste, les droits (F86, ACL,
-- aides internes, tables), la normalisation des contacts (MAPPAGE 4), l'ordre
-- des refus, l'idempotence et le jeton de l'import, la liste des personnes a
-- prevenir et le geste « prevenu » (transition 26), le rattachement par la
-- direction (transition 27), la conversion d'une ligne « pour suivi » en
-- candidature, l'invitation comme seconde porte, l'import apres l'inscription,
-- une ligne gardee pour suivi jamais mise en historique et un courriel porte par
-- deux lignes actives qui ne relie rien (section l). Section m, relecture du 23/10 :
-- une proposition qui ne tient plus (genre, telephone, candidature deja reliee),
-- une ligne redevenue active rapprochee, une ligne de suivi retiree non reprise,
-- le meme resultat rendu quoi que la base sache du courriel ou du telephone,
-- les groupes de doublons fermes de proche en proche (et libres quand une ligne
-- corrigee les quitte), l'accord WhatsApp, un courriel porte par deux candidatures
-- ou par deux lignes « distinctes ». Les verrous sont dans scenarios_cand_l3_concurrence.sql.
-- Aucune donnee reelle : noms inventes, adresses en @test.invalid, numeros fictifs.
-- Chaque controle leve 'CAND-L3 ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE (stub_auth puis toutes les migrations) ; tout est annule a la fin.
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
    RAISE EXCEPTION 'CAND-L3 ROUGE : %', p_label;
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
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text, p_aal text DEFAULT 'aal1') RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Un appel qui doit etre refuse avec ce code, sous authenticated (ou anon).
CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_db_role text DEFAULT 'authenticated', p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
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
    RAISE EXCEPTION 'CAND-L3 ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CAND-L3 ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Un utilisateur d'authentification (courriel confirme ou non).
CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca3b0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.u(p_n text, p_courriel text, p_confirme boolean DEFAULT true) RETURNS uuid
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email, email_confirmed_at)
  VALUES (pg_temp.p(p_n), p_courriel, CASE WHEN p_confirme THEN pg_catalog.clock_timestamp() END);
  RETURN pg_temp.p(p_n);
END $$;

-- Tout ce que l'inscription et l'import peuvent ecrire, pour prouver qu'un
-- refus n'a rien laisse.
CREATE FUNCTION pg_temp.ecritures() RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'profils', (SELECT count(*) FROM public.profiles),
    'fiches', (SELECT count(*) FROM public.teacher_profiles),
    'candidatures', (SELECT count(*) FROM public.candidatures),
    'contacts', (SELECT count(*) FROM public.candidature_contacts),
    'evenements', (SELECT count(*) FROM public.candidature_evenements),
    'reponses', (SELECT count(*) FROM public.candidature_reponses),
    'accords', (SELECT count(*) FROM public.candidat_accords_confidentialite),
    'compteur', (SELECT count(*) FROM private.inscriptions_publiques),
    'invitations', (SELECT count(*) FROM public.invitations_enseignant WHERE utilisee_le IS NOT NULL),
    'contrats', (SELECT count(*) FROM public.contract_acceptances),
    'pieces', (SELECT count(*) FROM public.kyc_documents),
    'lots', (SELECT count(*) FROM public.formulaires_lots),
    'importees', (SELECT count(*) FROM public.formulaires_reponses),
    'journal', (SELECT count(*) FROM public.formulaires_journal),
    'propositions', (SELECT count(*) FROM public.formulaires_rapprochements),
    'gestes', (SELECT count(*) FROM public.candidature_gestes),
    'dispos', (SELECT count(*) FROM public.weekly_availability));
$$;
-- Les lignes importees, sans les instants : ce qu'un rejeu ou un refus ne change pas.
CREATE FUNCTION pg_temp.importees() RETURNS text
LANGUAGE sql AS $$
  SELECT coalesce(md5(string_agg(md5((to_jsonb(r) - 'modifie_le' - 'cree_le' - 'lot_id')::text), '|'
                                 ORDER BY r.reference_source)), '')
  FROM public.formulaires_reponses r;
$$;

-- ------------------------------------------------------------
-- Les formulaires : une ligne d'export (14 colonnes) et le fichier
-- ------------------------------------------------------------
CREATE FUNCTION pg_temp.q(p_t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN p_t ~ '[,"\n]' THEN '"' || replace(p_t, '"', '""') || '"' ELSE coalesce(p_t, '') END
$$;
CREATE FUNCTION pg_temp.entete() RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT 'Horodateur,هل أنت,الاسم الكامل,رقم الواتساب مع رمز الدولة,ما هي لغتك الأم,'
      || 'بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه,ما مستواك في حفظ القرآن,'
      || 'هل تستطيع تقديم شهادة أو إجازة تثبت مستواك عند المقابلة,هل لديك خبرة في تعليم المبتدئين القراءة,'
      || 'هل تستطيع التدريس في ساعات متأخرة من الليل بتوقيت مكة المكرمة,'
      || 'كم ساعة في الأسبوع تستطيع التدريس بانتظام,متى تستطيع أن تبدأ,'
      || 'أوافق على أن يتصل بي فريق المشروع عبر واتساب,البريد الألكتروني'
$$;
-- Une ligne : horodatage, genre ('h' ou 'f' ou autre), nom, telephone, courriel ;
-- les reponses sont celles d'une candidate type (langue maternelle arabe,
-- francais et poular, Coran entier, ijaza, experience, de 3 a 5 heures, debut
-- immediat, accord WhatsApp) sauf indication.
CREATE FUNCTION pg_temp.l(p_h text, p_genre text, p_nom text, p_tel text, p_courriel text,
                          p_langues text DEFAULT 'الفرنسية, الفولاني ـ فولفولدي',
                          p_creneaux text DEFAULT 'من 8 مساءً إلى 10 مساءً') RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_temp.q(p_h) || ',' || pg_temp.q(CASE p_genre WHEN 'h' THEN 'ذكر' WHEN 'f' THEN 'أنثى' ELSE p_genre END)
      || ',' || pg_temp.q(p_nom) || ',' || pg_temp.q(p_tel) || ',' || pg_temp.q('العربية')
      || ',' || pg_temp.q(p_langues) || ',' || pg_temp.q('حفظت القرآن كله') || ',' || pg_temp.q('نعم')
      || ',' || pg_temp.q('نعم') || ',' || pg_temp.q(p_creneaux)
      || ',' || pg_temp.q('من 3 إلى 5 ساعات في الأسبوع') || ',' || pg_temp.q('يمكن لي البدء فورا')
      || ',' || pg_temp.q('أوافق') || ',' || pg_temp.q(p_courriel)
$$;
CREATE FUNCTION pg_temp.csv(VARIADIC p_lignes text[]) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_temp.entete() || E'\n' || array_to_string(p_lignes, E'\n') || E'\n'
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.p(text), pg_temp.u(text, text, boolean),
  pg_temp.ecritures(), pg_temp.importees(), pg_temp.q(text), pg_temp.entete(),
  pg_temp.l(text, text, text, text, text, text, text), pg_temp.csv(text[])
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- dm direction homme, df direction femme, du direction au genre inconnu, sa
-- super-admin (homme), sb seconde super-admin (homme), tu tuteur, en
-- enseignant en place (provisoire) sans candidature.
INSERT INTO auth.users (id, email, email_confirmed_at)
SELECT pg_temp.p(s), 'cand-l3-' || s || '@test.invalid', pg_catalog.clock_timestamp()
FROM unnest(ARRAY['d1', 'd2', 'd3', 'd4', 'd5', 'a1', 'e1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca3bffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('d1'), 'CA3B-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('d2'), 'CA3B-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('d3'), 'CA3B-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 (pg_temp.p('d4'), 'CA3B-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 (pg_temp.p('d5'), 'CA3B-ADM-0005', 'admin', NULL, 'Seconde', 'Super', 'active', 'male'),
 (pg_temp.p('a1'), 'CA3B-TUT-0001', 'guardian', 'ca3bffff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female'),
 (pg_temp.p('e1'), 'CA3B-ENS-0001', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('d4')), (pg_temp.p('d5'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

-- L'import des inscriptions du 12/10 : un foyer avec un enseignant (B), un foyer
-- avec seulement un tuteur (jamais une personne de B).
WITH h AS (
  INSERT INTO private.preinscription_households (email_normalise)
  VALUES ('b1@test.invalid'), ('g1@test.invalid') RETURNING id, email_normalise)
INSERT INTO private.preinscription_persons (household_id, person_kind, first_name, last_name, source_row)
SELECT h.id, CASE h.email_normalise WHEN 'b1@test.invalid' THEN 'teacher' ELSE 'guardian' END, 'Essai', 'Fictif', 2
FROM h;

SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'candidatures.inscription_publique_ouverte') = 'false'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'candidatures.inscriptions_par_heure') = '60'::jsonb
  AND (SELECT value FROM public.app_config WHERE key = 'candidatures.confidentialite_version') = '"2026-10-v1"'::jsonb
  AND (SELECT count(*) FROM public.candidatures) = 0 AND (SELECT count(*) FROM public.formulaires_reponses) = 0,
  'fixtures : mise en ligne fausse par defaut, plafond de 60 par heure, confidentialite 2026-10-v1, aucune candidature ni reponse importee');

-- ------------------------------------------------------------
-- (a) Droits, empreintes F86, aides internes, tables, reglages
-- ------------------------------------------------------------
DO $f86$
DECLARE
  f regprocedure;
  r text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
      'public.inscription_candidat_ouverte()'::regprocedure,
      'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure,
      'public.apercu_import_formulaires(text,text,text,jsonb,text)'::regprocedure,
      'public.confirmer_import_formulaires(text,text,text,text,jsonb,text,jsonb,text)'::regprocedure,
      'public.lister_formulaires_importes(jsonb,integer)'::regprocedure,
      'public.garder_formulaire_pour_suivi(uuid)'::regprocedure,
      'public.lister_a_prevenir_candidats(boolean,integer)'::regprocedure,
      'public.consigner_prevenu_candidat(uuid,text,text,date,integer,text)'::regprocedure,
      'public.lister_rapprochements_candidats(integer)'::regprocedure,
      'public.rattacher_formulaire_candidat(uuid,uuid,integer,text)'::regprocedure,
      'public.capacites_candidatures()'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                   AND coalesce(proconfig @> ARRAY['search_path=""'], false)
            FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%CAND-L3%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-L3 ROUGE : DEFINER, proprietaire, search_path, empreinte ou ACL de %', f;
    END IF;
    IF app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f))
       OR (SELECT prosrc LIKE '%app_role()%' AND prosrc NOT LIKE '%app_account_valid%' FROM pg_proc WHERE oid = f) THEN
      RAISE EXCEPTION 'CAND-L3 ROUGE : garde negative ou sans app_account_valid dans %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('onze RPC (dix du lot, capacites redefinie) : DEFINER postgres, search_path vide, empreinte reelle, authenticated seul, garde positive');
  IF (SELECT array_agg(provolatile::text ORDER BY proname) FROM pg_proc
      WHERE pronamespace = 'public'::regnamespace
        AND proname IN ('inscription_candidat_ouverte', 'inscrire_candidat', 'apercu_import_formulaires',
                        'confirmer_import_formulaires', 'capacites_candidatures', 'lister_formulaires_importes'))
     IS DISTINCT FROM ARRAY['v', 's', 'v', 's', 'v', 'v'] THEN
    RAISE EXCEPTION 'CAND-L3 ROUGE : volatilite inattendue';
  END IF;
  PERFORM pg_temp.ok('inscription, apercu, confirmation et listes VOLATILE ; ouverte et capacites STABLE');
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p
           WHERE p.pronamespace = 'private'::regnamespace
             AND (p.proname LIKE 'formulaires\_%' OR p.proname = 'inscription_reglages_valider') LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_function_privilege(r, f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L3 ROUGE : aide interne % executable par %', f, r;
      END IF;
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND proname LIKE 'formulaires\_%') = 16
    AND (SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace AND proname LIKE 'cand\_%') = 9,
    'seize aides formulaires_ executables par aucun compte ; les neuf aides cand_ de CAND-L1 inchangees');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
         AND proname LIKE '%candidature%' AND has_function_privilege('authenticated', oid, 'EXECUTE')
         AND proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature',
                             'lire_contact_candidature', 'historique_candidature')),
    'aucune RPC du lot ne double etat_dossier() : aucun nom ne contient candidature');
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF has_table_privilege(r, 'public.formulaires_reponses', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'public.formulaires_lots', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'public.formulaires_journal', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'public.formulaires_rapprochements', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'public.formulaires_choix_doublons', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'public.candidat_accords_confidentialite', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'private.inscriptions_publiques', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'private.indicatifs_telephoniques', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'private.formulaires_entetes', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'private.formulaires_libelles', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
      RAISE EXCEPTION 'CAND-L3 ROUGE : % garde un privilege sur une table du lot', r;
    END IF;
  END LOOP;
  PERFORM pg_temp.vrai((SELECT bool_and(relrowsecurity) FROM pg_class
                         WHERE oid IN ('public.formulaires_reponses'::regclass, 'public.formulaires_lots'::regclass,
                                       'public.formulaires_journal'::regclass, 'public.formulaires_rapprochements'::regclass,
                                       'public.candidat_accords_confidentialite'::regclass,
                                       'public.formulaires_choix_doublons'::regclass,
                                       'private.inscriptions_publiques'::regclass,
                                       'private.indicatifs_telephoniques'::regclass,
                                       'private.formulaires_entetes'::regclass,
                                       'private.formulaires_libelles'::regclass))
    AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename IN ('formulaires_reponses', 'formulaires_lots',
      'formulaires_journal', 'formulaires_rapprochements', 'formulaires_choix_doublons', 'candidat_accords_confidentialite',
      'inscriptions_publiques', 'indicatifs_telephoniques', 'formulaires_entetes', 'formulaires_libelles')),
    'dix tables du lot : RLS active, aucun privilege client, aucune policy');
  PERFORM pg_temp.vrai((SELECT count(*) FROM private.candidature_gestes_regles) = 26,
    'la table des regles de CAND-L2A1 est inchangee (vingt-six variantes)');
END $f86$;

-- Le journal de l'import, des lots et des accords ne se modifie pas (ajout seul).
SELECT pg_temp.vrai((SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal
                      AND tgrelid IN ('public.formulaires_lots'::regclass, 'public.formulaires_journal'::regclass,
                                      'public.candidat_accords_confidentialite'::regclass)
                      AND tgname LIKE '%ajout_seul') = 3,
  'lots, journal des lignes et accords de confidentialite : trois declencheurs d''ajout seul');

-- Reglages mal formes refuses (22023) ; les autres cles d'app_config ne sont pas touchees.
SELECT pg_temp.refus_en(NULL, NULL, $$UPDATE public.app_config SET value = '"oui"'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte'$$,
  '22023', 'mise en ligne : un booleen est attendu', 'postgres');
SELECT pg_temp.refus_en(NULL, NULL, $$UPDATE public.app_config SET value = '0'::jsonb WHERE key = 'candidatures.inscriptions_par_heure'$$,
  '22023', 'plafond : un entier d''au moins 1', 'postgres');
SELECT pg_temp.refus_en(NULL, NULL, $$UPDATE public.app_config SET value = '10001'::jsonb WHERE key = 'candidatures.inscriptions_par_heure'$$,
  '22023', 'plafond : 10000 au plus', 'postgres');
SELECT pg_temp.refus_en(NULL, NULL, $$UPDATE public.app_config SET value = '"v1"'::jsonb WHERE key = 'candidatures.confidentialite_version'$$,
  '22023', 'version de confidentialite : forme 2026-10-v1', 'postgres');

-- ------------------------------------------------------------
-- (b) Inscription sans invitation (CAND-04) : conditions de la transition 5
-- ------------------------------------------------------------
SELECT pg_temp.u('01', 'cand-l3-01@test.invalid');
SELECT pg_temp.u('02', 'cand-l3-02@test.invalid', false);
SELECT pg_temp.garde('avant', pg_temp.ecritures());

-- Fermee par defaut : rien n'est cree (L3-18, premiere moitie).
SELECT pg_temp.garde('r_fermee', pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', '2026-10-v1')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_fermee') = '{"resultat": "fermee"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant')
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = pg_temp.p('01')),
  'L3-18 : cle de mise en ligne fausse : inscription sans code refusee (fermee), 0 profil, 0 candidature');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), NULL, $$SELECT public.inscription_candidat_ouverte()$$)
  = '{"ouverte": false, "versionConfidentialite": "2026-10-v1"}'::jsonb,
  'inscription_candidat_ouverte() : fausse tant que la cle l''est, avec la version de confidentialite attendue');

-- L3-1 : sans courriel confirme, la candidature n'existe pas (cle fausse ou vraie).
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';
SELECT pg_temp.garde('r_nonconf', pg_temp.en(pg_temp.p('02'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Deux', 'female', '+966500000102', 'fr', '2026-10-v1')$$));
SELECT pg_temp.garde('r_nonconf_code', pg_temp.en(pg_temp.p('02'), NULL,
  $$SELECT public.inscrire_candidat('ABCD-EFGH-JKMN', 'Essai', 'Deux', 'female', '+966500000102', 'fr', '2026-10-v1')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_nonconf') = '{"resultat": "courriel_non_confirme"}'::jsonb
  AND pg_temp.lu('r_nonconf_code') = '{"resultat": "courriel_non_confirme"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant'),
  'L3-1 : courriel non confirme (lien public ou code) : 0 profil, 0 candidature, 0 accord, 0 ecriture');

-- Les refus de forme, nommes, sans ecriture (L3-13 : sans genre).
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', NULL, '+966500000101', 'fr', '2026-10-v1')$$)
  = '{"resultat": "invalide", "champs": ["genre"]}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant'),
  'L3-13 : sans genre, refus nomme ; 0 profil');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, '  ', '', 'male', '0612345678', 'en', '2026-10-v1')$$)
  = '{"resultat": "invalide", "champs": ["prenom", "nom", "langue", "telephone"]}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant'),
  'prenom, nom, langue (fr ou ar) et telephone avec indicatif exiges et nommes (un numero national est refuse)');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+999123456789', 'fr', '2026-10-v1')$$)
  = '{"resultat": "invalide", "champs": ["telephone"]}'::jsonb
  AND pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', NULL, NULL, '2026-10-v1')$$)
  = '{"resultat": "invalide", "champs": ["langue", "telephone"]}'::jsonb,
  'un indicatif inconnu ou un telephone absent ne passe pas : jamais complete, jamais devine');
-- L'accord de confidentialite : requis, et a la version que le serveur attend.
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', NULL)$$)
  = '{"resultat": "confidentialite_requise", "versionCourante": "2026-10-v1"}'::jsonb
  AND pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', '2025-01-v0')$$)
  = '{"resultat": "confidentialite_perimee", "versionCourante": "2026-10-v1"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant'),
  'accord de confidentialite absent ou d''une autre version : refus nommes, version courante rendue, 0 ecriture');
UPDATE public.app_config SET value = '"2026-11-v2"'::jsonb WHERE key = 'candidatures.confidentialite_version';
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', '2026-10-v1')$$)
  = '{"resultat": "confidentialite_perimee", "versionCourante": "2026-11-v2"}'::jsonb,
  'la version attendue se change dans app_config sans migration : l''ancienne est perimee');
UPDATE public.app_config SET value = '"2026-10-v1"'::jsonb WHERE key = 'candidatures.confidentialite_version';

-- Session absente ou anonyme : refus (42501).
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', '2026-10-v1')$$,
  '42501', 'sans session : inscription refusee');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', '2026-10-v1')$$,
  '42501', 'anon : inscription fermee (ACL)', 'anon');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.inscription_candidat_ouverte()$$, '42501',
  'anon : l''ouverture n''est pas lisible (ACL)', 'anon');

-- Le succes : un compte candidat de la forme de l'invitation (L3-3), la
-- candidature en Salle d'examen a completer, le contact, l'accord, le journal.
SELECT pg_temp.garde('r_succes', pg_temp.en(pg_temp.p('01'), NULL,
  $$SELECT public.inscrire_candidat(NULL, '  Essai ', 'Un', 'male', '+966 50 000 0101', 'ar', '2026-10-v1')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_succes') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT role = 'teacher' AND account_status = 'pending_kyc' AND household_id IS NULL AND gender = 'male'
              AND first_name = 'Essai' AND last_name = 'Un'
         FROM public.profiles WHERE id = pg_temp.p('01'))
  AND EXISTS (SELECT 1 FROM public.teacher_profiles WHERE profile_id = pg_temp.p('01'))
  AND (SELECT count(*) FROM public.candidatures WHERE profile_id = pg_temp.p('01')) = 1,
  'L3-3 : 1 compte teacher pending_kyc sans foyer, avec sa fiche vide (la forme de l''invitation) et 1 candidature');
SELECT pg_temp.vrai((SELECT etape = 'prequalification' AND etat = 'a_completer' AND issue = 'en_cours'
                            AND source = 'lien_public' AND langue = 'ar' AND genre = 'male'
                            AND type_code = 'enseignant' AND nom_complet = 'Essai Un' AND version = 1
                            AND source_ref IS NULL AND NOT en_pause AND paiement = 'inconnu'
       FROM public.candidatures WHERE profile_id = pg_temp.p('01'))
  AND (SELECT courriel = 'cand-l3-01@test.invalid' AND telephone = '+966500000101'
              AND courriel_brut IS NULL AND telephone_brut IS NULL
       FROM public.candidature_contacts k JOIN public.candidatures c ON c.id = k.candidature_id
       WHERE c.profile_id = pg_temp.p('01'))
  AND (SELECT version = '2026-10-v1' AND porte = 'lien_public'
       FROM public.candidat_accords_confidentialite WHERE profile_id = pg_temp.p('01'))
  AND (SELECT count(*) FROM private.inscriptions_publiques) = 1,
  'la candidature naît en Salle d''examen a completer : langue, contact normalise (+ et chiffres), accord a sa version et sa date, compteur du plafond');
SELECT pg_temp.vrai((SELECT e.type = 'creee' AND e.details ->> 'porte' = 'lien_public' AND e.details ->> 'geste' = 'inscription'
                            AND (e.details ->> 'transition')::int = 5 AND e.auteur_id = pg_temp.p('01')
                            AND e.etape_apres = 'prequalification' AND e.etat_apres = 'a_completer'
                       FROM public.candidature_evenements e JOIN public.candidatures c ON c.id = e.candidature_id
                      WHERE c.profile_id = pg_temp.p('01'))
  AND EXISTS (SELECT 1 FROM public.audit_logs a JOIN public.candidatures c ON c.id::text = a.row_id
               WHERE c.profile_id = pg_temp.p('01') AND a.action = 'candidature_inscription'
                 AND a.payload ->> 'porte' = 'lien_public'),
  'la creation laisse un evenement (transition 5) et une ligne audit_logs, sans nom');
SELECT pg_temp.vrai((SELECT count(*) FROM public.contract_acceptances WHERE profile_id = pg_temp.p('01')) = 0
  AND (SELECT count(*) FROM public.kyc_documents WHERE profile_id = pg_temp.p('01')) = 0
  AND (SELECT count(*) FROM public.candidature_reponses) = 0
  AND (SELECT count(*) FROM public.weekly_availability) = 0,
  'aucun accord signe, aucune piece, aucune reponse, aucune disponibilite a la place de la personne');
SELECT pg_temp.garde('etat01', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.vrai(pg_temp.lu('etat01') #>> '{candidature,etape}' = 'prequalification'
  AND pg_temp.lu('etat01') #>> '{candidature,etat}' = 'a_completer'
  AND pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT to_jsonb(public.app_account_valid())$$) = 'false'::jsonb,
  'etat_dossier() du candidat lit sa candidature ; son compte n''est pas valide (aucune capacite d''enseignant)');
-- Seconde inscription du meme compte : refusee (L3-14).
SELECT pg_temp.garde('avant2', pg_temp.ecritures());
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher',
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'male', '+966500000101', 'fr', '2026-10-v1')$$,
  '42501', 'L3-14 : seconde candidature du meme compte : refusee');
SELECT pg_temp.vrai(pg_temp.ecritures() = pg_temp.lu('avant2'), 'le refus n''ecrit rien');

-- L3-2 et L3-17 : le plafond par heure. La reponse au-dela est exactement celle du succes.
UPDATE public.app_config SET value = '2'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';
SELECT pg_temp.u('03', 'cand-l3-03@test.invalid');
SELECT pg_temp.u('04', 'cand-l3-04@test.invalid');
SELECT pg_temp.garde('r_ok2', pg_temp.en(pg_temp.p('03'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Trois', 'female', '+966500000103', 'fr', '2026-10-v1')$$));
SELECT pg_temp.garde('avant3', pg_temp.ecritures());
SELECT pg_temp.garde('r_plafond', pg_temp.en(pg_temp.p('04'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Quatre', 'male', '+966500000104', 'fr', '2026-10-v1')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_ok2') = pg_temp.lu('r_succes') AND pg_temp.lu('r_plafond') = pg_temp.lu('r_ok2')
  AND pg_temp.lu('r_plafond') = '{"resultat": "acceptee"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant3')
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = pg_temp.p('04'))
  AND (SELECT count(*) FROM private.inscriptions_publiques) = 2,
  'L3-2 et L3-17 : au-dela du plafond, la reponse est identique a celle du succes, 0 profil, 0 candidature, 0 accord');
-- Le refus neutre ne brule rien : le plafond releve, la meme personne s'inscrit.
UPDATE public.app_config SET value = '60'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';
SELECT pg_temp.garde('r_retry', pg_temp.en(pg_temp.p('04'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Quatre', 'male', '+966500000104', 'fr', '2026-10-v1')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_retry') = '{"resultat": "acceptee"}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = pg_temp.p('04')),
  'le plafond releve, la personne refusee en silence s''inscrit');
-- Les inscriptions vieilles de plus d'une heure ne comptent plus.
UPDATE private.inscriptions_publiques SET cree_le = clock_timestamp() - interval '61 minutes';
UPDATE public.app_config SET value = '1'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';
SELECT pg_temp.u('05', 'cand-l3-05@test.invalid');
SELECT pg_temp.garde('r_heure', pg_temp.en(pg_temp.p('05'), NULL,
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Cinq', 'female', '+966500000105', 'fr', '2026-10-v1')$$));
SELECT pg_temp.vrai(pg_temp.lu('r_heure') = '{"resultat": "acceptee"}'::jsonb
  AND EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = pg_temp.p('05'))
  AND (SELECT count(*) FROM private.inscriptions_publiques WHERE cree_le > clock_timestamp() - interval '1 hour') = 1,
  'une heure plus tard le compteur repart : le plafond ne compte que la derniere heure');
UPDATE public.app_config SET value = '60'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';

-- ------------------------------------------------------------
-- (c) L'invitation, seconde porte : memes resultats que inscrire_enseignant_invite
-- ------------------------------------------------------------
INSERT INTO public.invitations_enseignant (code, email, cree_par, cree_le, expire_le, revoquee_le, revoquee_par,
                                           utilisee_le, utilisee_par)
VALUES
 ('ABCD-EFGH-JKMN', 'cand-l3-i1@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days', NULL, NULL, NULL, NULL),
 ('PQRS-TUVW-XYZ2', 'cand-l3-i2@test.invalid', pg_temp.p('d1'), now() - interval '2 days', now() - interval '1 day',
  NULL, NULL, NULL, NULL),
 ('2345-6789-ABCD', 'cand-l3-i3@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days', now(),
  pg_temp.p('d1'), NULL, NULL),
 ('MNPQ-RSTU-VWXY', 'cand-l3-i4@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days', NULL, NULL,
  now(), pg_temp.p('d2')),
 ('KMNP-QRST-UVWX', 'cand-l3-i5@test.invalid', pg_temp.p('d1'), now(), now() + interval '14 days', NULL, NULL, NULL, NULL);
SELECT pg_temp.u('b1', 'cand-l3-i1@test.invalid');
SELECT pg_temp.u('b2', 'cand-l3-i2@test.invalid');
SELECT pg_temp.u('b3', 'cand-l3-i3@test.invalid');
SELECT pg_temp.u('b4', 'cand-l3-i4@test.invalid');
SELECT pg_temp.u('b5', 'cand-l3-i5@test.invalid');
SELECT pg_temp.u('b6', 'cand-l3-i6@test.invalid');
SELECT pg_temp.garde('avant4', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('b6'), NULL, $$SELECT public.inscrire_candidat('ABCD-EFGH-JKMN', 'Essai', 'Intrus', 'male', '+966500000206', 'fr', '2026-10-v1')$$) = '{"resultat": "inconnue"}'::jsonb
  AND pg_temp.en(pg_temp.p('b2'), NULL, $$SELECT public.inscrire_candidat('PQRS-TUVW-XYZ2', 'Essai', 'Echue', 'male', '+966500000202', 'fr', '2026-10-v1')$$) = '{"resultat": "expiree"}'::jsonb
  AND pg_temp.en(pg_temp.p('b3'), NULL, $$SELECT public.inscrire_candidat('2345-6789-ABCD', 'Essai', 'Revoquee', 'male', '+966500000203', 'fr', '2026-10-v1')$$) = '{"resultat": "inconnue"}'::jsonb
  AND pg_temp.en(pg_temp.p('b4'), NULL, $$SELECT public.inscrire_candidat('MNPQ-RSTU-VWXY', 'Essai', 'Utilisee', 'male', '+966500000204', 'fr', '2026-10-v1')$$) = '{"resultat": "deja_utilisee"}'::jsonb
  AND pg_temp.en(pg_temp.p('b6'), NULL, $$SELECT public.inscrire_candidat('ZZZZ-ZZZZ-ZZZZ', 'Essai', 'Inconnu', 'male', '+966500000206', 'fr', '2026-10-v1')$$) = '{"resultat": "inconnue"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant4'),
  'un code d''une autre adresse, echu, revoque, consomme ou inconnu : inconnue, expiree, inconnue, deja_utilisee, inconnue ; 0 ecriture');
-- Un refus de forme ne brule pas le code.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('b1'), NULL, $$SELECT public.inscrire_candidat('ABCD-EFGH-JKMN', 'Essai', 'Invite', NULL, '+966500000201', 'fr', '2026-10-v1')$$)
    = '{"resultat": "invalide", "champs": ["genre"]}'::jsonb
  AND (SELECT utilisee_le IS NULL FROM public.invitations_enseignant WHERE code = 'ABCD-EFGH-JKMN')
  AND pg_temp.ecritures() = pg_temp.lu('avant4'),
  'un refus de forme (sans genre) ne consomme pas le code d''invitation');
-- La porte du code ne depend ni de la cle de mise en ligne ni du plafond.
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';
UPDATE public.app_config SET value = '1'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';
SELECT pg_temp.garde('r_code', pg_temp.en(pg_temp.p('b1'), NULL,
  $$SELECT public.inscrire_candidat(' abcd-efgh-jkmn ', 'Essai', 'Invite', 'female', '+966500000201', 'ar', '2026-10-v1')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('r_code') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT utilisee_par = pg_temp.p('b1') AND utilisee_le IS NOT NULL
         FROM public.invitations_enseignant WHERE code = 'ABCD-EFGH-JKMN')
  AND (SELECT source = 'invitation' AND etape = 'prequalification' AND etat = 'a_completer' AND langue = 'ar'
         FROM public.candidatures WHERE profile_id = pg_temp.p('b1'))
  AND (SELECT porte = 'invitation' AND version = '2026-10-v1'
         FROM public.candidat_accords_confidentialite WHERE profile_id = pg_temp.p('b1'))
  AND (SELECT role = 'teacher' AND account_status = 'pending_kyc' AND household_id IS NULL
         FROM public.profiles WHERE id = pg_temp.p('b1'))
  AND (SELECT count(*) FROM private.inscriptions_publiques) = (SELECT pg_temp.lu('avant4') ->> 'compteur')::int,
  'le code (casse et espaces tolerees) : meme compte, meme candidature, provenance invitation ; cle fausse et plafond atteint n''y changent rien ; le compteur du lien public n''avance pas');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher',
  $$SELECT public.inscrire_candidat('ABCD-EFGH-JKMN', 'Essai', 'Invite', 'female', '+966500000201', 'ar', '2026-10-v1')$$,
  '42501', 'le candidat deja inscrit ne rejoue pas son code');
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';
UPDATE public.app_config SET value = '60'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';

-- ------------------------------------------------------------
-- (d) L'import des formulaires : droits, essai a blanc, confirmation
-- ------------------------------------------------------------
-- Le fichier A1 : 17 lignes de donnees (la ligne 1 est l'en-tete).
--  2 r1 homme, 3 r2 homme (meme telephone que r1, plus recent), 4 r3 femme
--  (creneaux contradictoires), 5 r4 femme (numero national, sans courriel),
--  6 r5 homme (son courriel est celui d'un enseignant de B), 7 r6 genre
--  illisible, 8 ligne vide, 9 r8 homme (courriel mal forme, sans telephone),
--  10 r9, 11 r10 (courriel d'un foyer sans enseignant), 12 r3 repetee, 13 la
--  reference de r4 avec un autre contenu, 14 r13 femme, 15 r14 femme,
--  16 r15 homme, 17 r16 homme, 18 r17 homme au meme nom que r1.
CREATE FUNCTION pg_temp.ref(p_onglet text, p_h text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$ SELECT 'Classeur L3|' || p_onglet || '|' || p_h $$;
CREATE FUNCTION pg_temp.rep(p_onglet text, p_h text) RETURNS public.formulaires_reponses
LANGUAGE sql STABLE AS $$ SELECT r FROM public.formulaires_reponses r WHERE r.reference_source = pg_temp.ref(p_onglet, p_h) $$;
GRANT EXECUTE ON FUNCTION pg_temp.ref(text, text), pg_temp.rep(text, text) TO authenticated, anon;

SELECT pg_temp.garde('f1', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-01 10:00:00', 'h', 'Essai Homme Un', '+966500000301', 'h1@test.invalid'),
  pg_temp.l('2026-10-02 10:00:00', 'h', 'Essai  Homme Deux', '966500000301', ' H2@Test.Invalid '),
  pg_temp.l('2026-10-03 12:00:00', 'f', 'Essai Femme Un', '+966500000303', 'f1@test.invalid',
            'الفرنسية, الفولاني ـ فولفولدي', 'من 8 مساءً إلى 10 مساءً, جاهز في أي وقت من اليوم'),
  pg_temp.l('2026-10-04 13:00:00', 'f', 'Essai Femme Deux', '0501234567', ''),
  pg_temp.l('2026-10-05 14:00:00', 'h', 'Essai Homme Cinq', '+966500000305', 'b1@test.invalid'),
  pg_temp.l('2026-10-06 15:00:00', '?', 'Essai Sans Genre', '+966500000306', 'g6@test.invalid'),
  ',,,,,,,,,,,,,',
  pg_temp.l('2026-10-08 16:00:00', 'h', 'Essai Homme Huit', '', 'pas-un-courriel'),
  pg_temp.l('2026-10-10 10:00:00', 'h', 'Essai Homme Neuf', '+966500000309', 'x1@test.invalid'),
  pg_temp.l('2026-10-11 10:00:00', 'h', 'Essai Homme Dix', '+966500000310', 'g1@test.invalid'),
  pg_temp.l('2026-10-03 12:00:00', 'f', 'Essai Femme Un', '+966500000303', 'f1@test.invalid',
            'الفرنسية, الفولاني ـ فولفولدي', 'من 8 مساءً إلى 10 مساءً, جاهز في أي وقت من اليوم'),
  pg_temp.l('2026-10-04 13:00:00', 'f', 'Essai Femme Autre', '+966500000312', 'f12@test.invalid'),
  pg_temp.l('2026-10-13 10:00:00', 'f', 'Essai Femme Treize', '+966500000313', 'f13@test.invalid'),
  pg_temp.l('2026-10-14 10:00:00', 'f', 'Essai Femme Quatorze', '+966500000314', 'f14@test.invalid'),
  pg_temp.l('2026-10-15 10:00:00', 'h', 'Essai Homme Quinze', '+966500000315', 'h15@test.invalid'),
  pg_temp.l('2026-10-16 10:00:00', 'h', 'Essai Homme Seize', '+966500000316', 'm16@test.invalid'),
  pg_temp.l('2026-10-17 10:00:00', 'h', 'Essai Homme Un', '+966500000317', 'n17@test.invalid'))));
SELECT pg_temp.garde('avant5', pg_temp.ecritures());

-- Les droits : l'import est celui du super-admin en double verification, rien d'autre.
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, '42501',
  'une direction qui n''est pas super-admin ne lance pas l''essai a blanc', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, '42501',
  'L3-15 : une directrice lance l''essai a blanc : refus, rien de lu', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, '42501',
  'une direction au genre inconnu est refusee aussi', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, '42501',
  'un tuteur est refuse', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, '42501',
  'un candidat est refuse', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, '42501',
  'anon : l''import est ferme (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1', 'x', '[]', 'cle-refus-0001')$$,
  '42501', 'une directrice ne confirme pas non plus', 'authenticated', 'aal2');
SELECT pg_temp.vrai(pg_temp.ecritures() = pg_temp.lu('avant5'), 'ces refus n''ont rien ecrit');
-- Le super-admin en aal1 : la double verification est exigee en base, rien n'est lu ni ecrit.
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('d4'), 'admin',
    $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, 'aal1')
  = '{"erreur": "double_verification_requise", "ecritureEffectuee": false}'::jsonb
  AND pg_temp.en(pg_temp.p('d4'), 'admin',
    $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1', 'x', '[]', 'cle-aal1-0001')$$, 'aal1')
  = '{"erreur": "double_verification_requise", "ecritureEffectuee": false}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant5'),
  'super-admin en aal1 : double_verification_requise (apercu et confirmation), 0 ecriture');
-- Des arguments impossibles : 22023.
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur|L3', 'A1')$$, '22023',
  'un classeur qui contient la barre de la reference est refuse', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(NULL, 'Classeur L3', 'A1')$$, '22023',
  'sans fichier : 22023', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1', NULL, 'Mars/Inconnu')$$, '22023',
  'un fuseau inconnu est refuse', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1', 'x', '[]', 'court')$$, '22023',
  'une cle d''idempotence de moins de 8 signes est refusee', 'authenticated', 'aal2');

-- Un fichier illisible ou incomplet : rendu, rien d'ecrit.
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.apercu_import_formulaires('a,b' || E'\n' || '"x', 'Classeur L3', 'A1')$$, 'aal2')
     ->> 'erreur') = 'fichier_illisible'
  AND (pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.apercu_import_formulaires('', 'Classeur L3', 'A1')$$, 'aal2')
     ->> 'erreur') = 'fichier_vide'
  AND pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.apercu_import_formulaires('Nom,Courriel' || E'\n' || 'a,b@test.invalid' || E'\n', 'Classeur L3', 'A1')$$, 'aal2')
     @> '{"erreur": "mappage_incomplet", "champs": ["horodatage", "genre", "nom", "contact"]}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant5'),
  'fichier illisible, vide ou aux en-tetes inconnus : refus nommes (champs a associer), 0 ecriture');
-- L'association manuelle d'une colonne (position -> champ) comble un en-tete inconnu.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.apercu_import_formulaires(
      'Date,Sexe,Nom complet,Mail' || E'\n' || '2026-10-01 10:00:00,ذكر,Essai Manuel,m1@test.invalid' || E'\n',
      'Classeur L3', 'M', '{"1": "horodatage", "2": "genre", "3": "nom", "4": "courriel"}')$$, 'aal2')
    @> '{"compteurs": {"nouvelles": 1, "aCorriger": 0}}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant5'),
  'association manuelle des colonnes : un en-tete inconnu se range par sa position, sans ecriture');

-- L3-4 : l'essai a blanc.
SELECT pg_temp.garde('apercu1', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.ecritures() = pg_temp.lu('avant5')
  AND pg_temp.lu('apercu1') ->> 'ecritureEffectuee' = 'false'
  AND pg_temp.lu('apercu1') #>> '{jeton}' ~ '^[0-9a-f]{32}$'
  AND pg_temp.lu('apercu1') -> 'compteurs' = '{"lignesLues": 17, "nouvelles": 12, "corrigees": 0, "dejaConnues": 1,
      "ignorees": 2, "aCorriger": 2, "historique": 1, "personnes": 11}'::jsonb,
  'L3-4 : essai a blanc par le super-admin : 0 ecriture, jeton, compteurs (12 nouvelles, 1 deja connue, 2 ignorees, 2 a corriger, 1 en historique, 11 personnes pour 17 lignes)');
SELECT pg_temp.vrai((pg_temp.lu('apercu1') ->> 'jeton') IS NOT NULL
  AND pg_temp.lu('apercu1')::text !~ 'Essai|test\.invalid|9665000|0501234567|Classeur'
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes')) = 17
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'groupes')) = 1,
  'l''apercu ne rend ni nom, ni courriel, ni telephone, ni reponse, ni nom de classeur : une ligne par ligne lue, un seul groupe');
SELECT pg_temp.vrai(
  pg_temp.lu('apercu1') #> '{groupes,0}' @> '{"nature": "telephone", "taille": 2, "lignes": [2, 3], "retenueProposee": 3,
    "retenueDansLaBase": false, "choisi": false}'::jsonb
  AND (SELECT l ->> 'issue' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 2) = 'nouvelle'
  AND (SELECT l ->> 'etatFinal' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 2) = 'historique'
  AND (SELECT l ->> 'etatFinal' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 3) = 'active',
  'L3-11 (CAND-Q16) : deux lignes qui partagent un telephone forment un groupe (sa nature, jamais la valeur) ; la plus recente est proposee, l''autre passe en historique');
SELECT pg_temp.vrai(
  (SELECT l -> 'motifs' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 6) = '["inscription_12_10"]'::jsonb
  AND (SELECT l ->> 'issue' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 6) = 'deja_connue'
  AND (SELECT l -> 'motifs' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 7) = '["genre_illisible"]'::jsonb
  AND (SELECT l ->> 'issue' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 8) = 'ignoree'
  AND (SELECT l -> 'motifs' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 12) = '["meme_reference_meme_contenu"]'::jsonb
  AND (SELECT l -> 'motifs' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 13) = '["meme_reference_contenu_different"]'::jsonb
  AND (SELECT l ->> 'issue' FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 11) = 'nouvelle',
  'L3-6 : un enseignant de B est deja connu (0 ecriture) mais un foyer sans enseignant ne l''est pas ; genre illisible a corriger ; ligne vide ignoree ; meme reference : identique ignoree, differente a corriger');
SELECT pg_temp.vrai(
  (SELECT (l ->> 'courrielAObtenir')::boolean AND (l ->> 'indicatifAConfirmer')::boolean
     FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 5)
  AND (SELECT (l ->> 'courrielAObtenir')::boolean AND NOT (l ->> 'indicatifAConfirmer')::boolean
     FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 9)
  AND (SELECT NOT (l ->> 'courrielAObtenir')::boolean AND NOT (l ->> 'indicatifAConfirmer')::boolean
     FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 3)
  AND (SELECT '{creneaux_contradictoires}'::text[] <@ ARRAY(SELECT jsonb_array_elements_text(l -> 'avertissements'))
     FROM jsonb_array_elements(pg_temp.lu('apercu1') -> 'lignes') l WHERE (l ->> 'ligne')::int = 4),
  'les marques « courriel a obtenir » (absent ou mal forme) et « indicatif a confirmer » (numero national) se lisent ; les creneaux contradictoires sont signales');
-- Le jeton est celui du fichier : un autre fichier, un autre onglet, un autre auteur le perime.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
     'ffffffffffffffffffffffffffffffff', '[]', 'cle-jeton-0001')$$, 'aal2')
    = '{"erreur": "jeton_perime", "ecritureEffectuee": false}'::jsonb
  AND pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}' || ' ', 'Classeur L3', 'A1',
     pg_temp.lu('apercu1') ->> 'jeton', '[]', 'cle-jeton-0002')$$, 'aal2')
    = '{"erreur": "jeton_perime", "ecritureEffectuee": false}'::jsonb
  AND pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A2',
     pg_temp.lu('apercu1') ->> 'jeton', '[]', 'cle-jeton-0003')$$, 'aal2')
    = '{"erreur": "jeton_perime", "ecritureEffectuee": false}'::jsonb
  AND pg_temp.en(pg_temp.p('d5'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
     pg_temp.lu('apercu1') ->> 'jeton', '[]', 'cle-jeton-0004')$$, 'aal2')
    = '{"erreur": "jeton_perime", "ecritureEffectuee": false}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant5'),
  'le jeton (HMAC sous la cle du serveur) est celui du fichier, de l''onglet et de l''auteur : un autre le perime, 0 ecriture');
-- Un choix de doublons inconnu est refuse, sans ecriture.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
     pg_temp.lu('apercu1') ->> 'jeton', '[{"groupe": "zzzzzzzzzzzz", "retenue": "distinctes"}]', 'cle-choix-0001')$$, 'aal2')
    = '{"erreur": "choix_invalide", "groupes": ["zzzzzzzzzzzz"], "ecritureEffectuee": false}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant5'),
  'un groupe inconnu dans les choix : choix_invalide nomme, 0 ecriture');

-- L3-5 : la confirmation.
SELECT pg_temp.garde('lot1', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
      pg_temp.lu('apercu1') ->> 'jeton', '[]', 'cle-import-0001')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('lot1') ->> 'ecritureEffectuee' = 'true' AND pg_temp.lu('lot1') ->> 'rejoue' = 'false'
  AND pg_temp.lu('lot1') -> 'compteurs' = pg_temp.lu('apercu1') -> 'compteurs'
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('lot1') -> 'lignes')) = 17
  AND pg_temp.lu('lot1')::text !~ 'Essai|test\.invalid|9665000|0501234567'
  AND (SELECT count(*) FROM public.formulaires_reponses) = 12
  AND (SELECT count(*) FROM public.formulaires_lots) = 1
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'import') = 12,
  'L3-5 : la confirmation ecrit 12 reponses importees, 1 lot, 12 lignes de journal ; le rapport (17 lignes) ne porte aucun nom ni contact');
SELECT pg_temp.vrai(
  (pg_temp.ecritures() - 'lots' - 'importees' - 'journal') = (pg_temp.lu('avant5') - 'lots' - 'importees' - 'journal'),
  'L3-5 : 0 ligne de plus dans profiles, invitations, kyc_documents, contract_acceptances, candidatures (recue comprise), contacts, accords, weekly_availability');
SELECT pg_temp.vrai(
  (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('A1', '2026-10-02 10:00:00')).id
          AND suivi_id IS NULL AND candidature_id IS NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-01 10:00:00'))
  AND (SELECT etat = 'active' AND remplacee_par IS NULL FROM public.formulaires_reponses
        WHERE reference_source = pg_temp.ref('A1', '2026-10-02 10:00:00'))
  AND (SELECT count(*) FILTER (WHERE etat = 'historique') FROM public.formulaires_reponses) = 1,
  'L3-11 : la ligne la plus recente l''emporte, l''autre reste en historique, rien n''est fusionne ni efface');
SELECT pg_temp.vrai(
  (SELECT telephone = '+966500000301' AND telephone_brut IS NULL AND courriel = 'h2@test.invalid'
          AND nom_affiche = 'Essai Homme Deux' AND genre = 'male' AND consentement_whatsapp
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-02 10:00:00'))
  AND (SELECT telephone IS NULL AND telephone_brut = '0501234567' AND courriel IS NULL AND courriel_brut IS NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-04 13:00:00'))
  AND (SELECT courriel IS NULL AND courriel_brut = 'pas-un-courriel' AND telephone IS NULL AND telephone_brut IS NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-08 16:00:00')),
  'normalisation (MAPPAGE 4) : courriel en minuscules sans espaces, telephone en + et chiffres ; un numero national reste tel quel (jamais complete) ; un courriel mal forme reste a part et n''est ni cle ni adresse');
SELECT pg_temp.vrai(
  (SELECT reponses = '{"debutPossible": "immediat", "ijazaPresentable": "oui", "langueMaternelle": "ar",
        "classesSouhaitees": "1", "languesExplication": ["francais", "poular"], "experienceDebutants": "oui",
        "niveauMemorisationDeclare": "coran_entier"}'::jsonb
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-02 10:00:00'))
  AND (SELECT NOT (reponses ?| ARRAY['disponibilitesDeclarees', 'fuseauIana', 'paysResidence', 'paysVersement',
        'publics', 'compteBancaire', 'operateurs', 'moyensAccessibles', 'riwayat', 'niveauLectureTajwid'])
          AND creneaux_libelle = 'من 8 مساءً إلى 10 مساءً, جاهز في أي وقت من اليوم'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-03 12:00:00'))
  AND (SELECT count(*) FROM public.weekly_availability) = 0,
  'L3-10 : la colonne J ne pre-remplit aucun champ (aucun jour) ; son libelle est garde tel quel ; 0 ligne weekly_availability ; ni pays, ni paiement, ni publics, ni riwaya');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-05 14:00:00'))
  AND EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE courriel = 'g1@test.invalid')
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-06 15:00:00')),
  'L3-6 : la personne de B n''est pas ecrite ; un foyer sans enseignant l''est ; la ligne a genre illisible n''est pas ecrite');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action IN ('formulaires_apercu', 'formulaires_import')
                AND a.payload::text ~ 'Essai|test\.invalid|9665000')
  AND (SELECT count(*) FROM public.audit_logs a WHERE a.action = 'formulaires_import') = 1
  AND (SELECT count(*) FROM public.audit_logs a WHERE a.action = 'formulaires_apercu') >= 1
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_journal j WHERE j.details::text ~ 'Essai|test\.invalid|9665000'),
  'journal : une ligne audit_logs par apercu et par import, des compteurs seulement ; le journal des lignes ne porte ni nom ni contact');

-- Le rejeu : la meme cle rend le meme rapport, sans rien ecrire.
SELECT pg_temp.garde('avant6', pg_temp.ecritures());
SELECT pg_temp.garde('imp6', to_jsonb(pg_temp.importees()));
SELECT pg_temp.garde('rejeu1', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
      pg_temp.lu('apercu1') ->> 'jeton', '[]', 'cle-import-0001')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('rejeu1') = (pg_temp.lu('lot1') || '{"rejoue": true}'::jsonb)
  AND pg_temp.ecritures() = pg_temp.lu('avant6'),
  'le meme fichier rejoue sous la meme cle : le meme rapport (rejoue = true), 0 ecriture');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A2',
     public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A2') ->> 'jeton', '[]', 'cle-import-0001')$$, 'aal2')
    = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.en(pg_temp.p('d5'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
     public.apercu_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1') ->> 'jeton', '[]', 'cle-import-0001')$$, 'aal2')
    = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.importees() = pg_temp.lu('imp6') #>> '{}',
  'la cle d''un autre onglet ou d''un autre auteur est refusee (cle_idempotence_reutilisee)');
-- Le meme fichier sous une cle neuve : rien de nouveau (L3-5, seconde moitie).
SELECT pg_temp.garde('lot2', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1') #>> '{}', 'Classeur L3', 'A1',
      pg_temp.lu('apercu1') ->> 'jeton', '[]', 'cle-import-0002')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('lot2') -> 'compteurs' = '{"lignesLues": 17, "nouvelles": 0, "corrigees": 0,
      "dejaConnues": 13, "ignorees": 2, "aCorriger": 2, "historique": 0, "personnes": 11}'::jsonb
  AND pg_temp.importees() = pg_temp.lu('imp6') #>> '{}'
  AND (SELECT count(*) FROM public.formulaires_reponses) = 12
  AND (SELECT count(*) FROM public.formulaires_journal) = 12
  AND (SELECT count(*) FROM public.formulaires_lots) = 2,
  'L3-5 : un second import identique ajoute 0 reponse, 0 ligne de journal (13 deja connues) ; seul le lot est trace');

-- ------------------------------------------------------------
-- (e) L3-16 : une ligne corrigee dans le classeur, reimportee
-- ------------------------------------------------------------
SELECT pg_temp.garde('f1b', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-01 10:00:00', 'h', 'Essai Homme Un', '+966500000301', 'h1@test.invalid'),
  pg_temp.l('2026-10-02 10:00:00', 'h', 'Essai  Homme Deux', '966500000301', ' H2@Test.Invalid '),
  pg_temp.l('2026-10-03 12:00:00', 'f', 'Essai Femme Un', '+966500000303', 'f1@test.invalid',
            'الفرنسية, الفولاني ـ فولفولدي', 'من 8 مساءً إلى 10 مساءً, جاهز في أي وقت من اليوم'),
  pg_temp.l('2026-10-04 13:00:00', 'f', 'Essai Femme Deux Corrigee', '+966500000304', ''),
  pg_temp.l('2026-10-05 14:00:00', 'h', 'Essai Homme Cinq', '+966500000305', 'b1@test.invalid'),
  pg_temp.l('2026-10-06 15:00:00', '?', 'Essai Sans Genre', '+966500000306', 'g6@test.invalid'),
  ',,,,,,,,,,,,,',
  pg_temp.l('2026-10-08 16:00:00', 'h', 'Essai Homme Huit', '', 'pas-un-courriel'),
  pg_temp.l('2026-10-10 10:00:00', 'h', 'Essai Homme Neuf', '+966500000309', 'x1@test.invalid'),
  pg_temp.l('2026-10-11 10:00:00', 'h', 'Essai Homme Dix', '+966500000310', 'g1@test.invalid'),
  pg_temp.l('2026-10-13 10:00:00', 'f', 'Essai Femme Treize', '+966500000313', 'f13@test.invalid'),
  pg_temp.l('2026-10-14 10:00:00', 'f', 'Essai Femme Quatorze', '+966500000314', 'f14@test.invalid'),
  pg_temp.l('2026-10-15 10:00:00', 'h', 'Essai Homme Quinze', '+966500000315', 'h15@test.invalid'),
  pg_temp.l('2026-10-16 10:00:00', 'h', 'Essai Homme Seize', '+966500000316', 'm16@test.invalid'),
  pg_temp.l('2026-10-17 10:00:00', 'h', 'Essai Homme Un', '+966500000317', 'n17@test.invalid'))));
SELECT pg_temp.garde('apercu2', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1b') #>> '{}', 'Classeur L3', 'A1')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu2') -> 'compteurs' = '{"lignesLues": 15, "nouvelles": 0, "corrigees": 1,
      "dejaConnues": 12, "ignorees": 1, "aCorriger": 1, "historique": 0, "personnes": 11}'::jsonb
  AND (SELECT l ->> 'issue' FROM jsonb_array_elements(pg_temp.lu('apercu2') -> 'lignes') l WHERE (l ->> 'ligne')::int = 5) = 'corrigee',
  'L3-16 : l''essai a blanc d''un fichier corrige lit 1 ligne corrigee, 0 nouvelle');
SELECT pg_temp.garde('avant7', pg_temp.ecritures());
SELECT pg_temp.garde('autres7', to_jsonb((SELECT md5(string_agg(md5((to_jsonb(r) - 'modifie_le' - 'cree_le' - 'lot_id')::text), '|'
  ORDER BY r.reference_source)) FROM public.formulaires_reponses r
  WHERE r.reference_source <> pg_temp.ref('A1', '2026-10-04 13:00:00'))));
SELECT pg_temp.garde('lot3', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f1b') #>> '{}', 'Classeur L3', 'A1',
      pg_temp.lu('apercu2') ->> 'jeton', '[]', 'cle-import-0003')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('lot3') -> 'compteurs' @> '{"nouvelles": 0, "corrigees": 1}'::jsonb
  AND (SELECT count(*) FROM public.formulaires_reponses) = 12
  AND (SELECT nom_affiche = 'Essai Femme Deux Corrigee' AND telephone = '+966500000304' AND telephone_brut IS NULL
          AND courriel IS NULL AND (reponses -> 'langueMaternelle') = '"ar"'::jsonb
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-04 13:00:00'))
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'correction') = 1
  AND (SELECT jsonb_agg(c ORDER BY c) = '["nom", "telephone"]'::jsonb
         FROM public.formulaires_journal j, jsonb_array_elements_text(j.details -> 'champs') c WHERE j.type = 'correction')
  AND (SELECT j.reponse_id = (pg_temp.rep('A1', '2026-10-04 13:00:00')).id
         AND j.lot_id = (pg_temp.lu('lot3') ->> 'lot')::uuid FROM public.formulaires_journal j WHERE j.type = 'correction')
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'import') = 12
  AND (SELECT to_jsonb(md5(string_agg(md5((to_jsonb(r) - 'modifie_le' - 'cree_le' - 'lot_id')::text), '|'
        ORDER BY r.reference_source))) FROM public.formulaires_reponses r
       WHERE r.reference_source <> pg_temp.ref('A1', '2026-10-04 13:00:00')) = pg_temp.lu('autres7'),
  'L3-16 : la correction s''inscrit sur la meme reference source (0 reponse nouvelle, 1 ligne corrigee, 1 correction tracee avec les champs, aucune autre ligne touchee)');

-- ------------------------------------------------------------
-- (f) Lire les reponses importees : la portee par genre (CAND-Q07)
-- ------------------------------------------------------------
SELECT pg_temp.garde('lh', pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{}', 1)$$));
SELECT pg_temp.garde('lf', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_formulaires_importes('{}', 1)$$));
SELECT pg_temp.garde('ls', pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.lister_formulaires_importes('{}', 1)$$));
SELECT pg_temp.vrai((pg_temp.lu('lh') ->> 'total')::int = 8 AND (pg_temp.lu('lf') ->> 'total')::int = 4
  AND (pg_temp.lu('ls') ->> 'total')::int = 12
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('lh') -> 'lignes') l WHERE l ->> 'nomComplet' LIKE 'Essai Femme%')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('lf') -> 'lignes') l WHERE l ->> 'nomComplet' NOT LIKE 'Essai Femme%')
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('ls') -> 'lignes') l) = 12,
  'la direction homme lit 8 lignes d''hommes, la directrice 4 de femmes, le super-admin les 12 : la portee est dans le WHERE');
SELECT pg_temp.vrai(
  (SELECT array_agg(k ORDER BY k COLLATE "C") FROM jsonb_object_keys(pg_temp.lu('lh') #> '{lignes,0}') k)
    = ARRAY['aPrevenir', 'candidatureSuivieId', 'courrielAObtenir', 'etat', 'id', 'indicatifAConfirmer', 'nomComplet',
            'prevenu', 'rattachee', 'recueLe', 'reference', 'suivi']
  AND pg_temp.lu('lh')::text !~ 'test\.invalid|9665000|0501234567|\"genre\"|male|female',
  'une ligne ne porte ni courriel, ni telephone, ni genre, ni reponse : le nom, la date, les marques et l''etat seuls');
SELECT pg_temp.vrai(pg_temp.lu('lh') -> 'compteurs' = '{"actives": 7, "historique": 1, "suivies": 0, "rattachees": 0, "aPrevenir": 1}'::jsonb
  AND pg_temp.lu('lf') -> 'compteurs' = '{"actives": 4, "historique": 0, "suivies": 0, "rattachees": 0, "aPrevenir": 1}'::jsonb,
  'compteurs dans la portee du lecteur (une ligne a prevenir de chaque cote : sans courriel valide)');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin', $$SELECT public.lister_formulaires_importes('{}', 1)$$, '42501',
  'direction au genre inconnu : aucune reponse importee lisible');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian', $$SELECT public.lister_formulaires_importes('{}', 1)$$, '42501', 'tuteur : refuse');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', $$SELECT public.lister_formulaires_importes('{}', 1)$$, '42501', 'candidat : refuse');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.lister_formulaires_importes('{}', 1)$$, '42501', 'anon : refuse (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"genre": "male"}', 1)$$, '22023',
  'un filtre inconnu (le genre) est refuse : il ne se filtre pas');
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"suivi": "oui"}', 1)$$, '22023',
  'un filtre mal type est refuse');
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"etat": "autre"}', 1)$$, '22023',
  'une valeur de filtre inconnue est refusee');
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{}', 0)$$, '22023', 'page 0 refusee');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"etat": "historique"}', 1)$$) ->> 'total')::int = 1
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"aPrevenir": true}', 1)$$) ->> 'total')::int = 1
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"recherche": "deux"}', 1)$$) ->> 'total')::int = 1
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"recherche": "H2@test.invalid"}', 1)$$) ->> 'total')::int = 1
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"recherche": "Classeur L3|A1|2026-10-02 10:00:00"}', 1)$$) ->> 'total')::int = 1
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"recherche": "Femme"}', 1)$$) ->> 'total')::int = 0
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{"rattachee": true}', 1)$$) ->> 'total')::int = 0
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_formulaires_importes('{}', 2)$$) -> 'lignes') = '[]'::jsonb,
  'filtres : etat, a prevenir, nom partiel, courriel exact, reference exacte ; une recherche ne franchit pas la portee ; page 2 vide');
-- L'audit d'une liste ne se lit que de son cote ; celle du super-admin, des deux.
SELECT pg_temp.vrai(
  (SELECT (private.journal_portee('candidatures', a.row_id, a.actor, a.payload)).cote = 'male'
     FROM public.audit_logs a WHERE a.action = 'formulaires_liste' AND a.actor = pg_temp.p('d1')
     ORDER BY a.id DESC LIMIT 1)
  AND (SELECT (private.journal_portee('candidatures', a.row_id, a.actor, a.payload)).cote = 'female'
     FROM public.audit_logs a WHERE a.action = 'formulaires_liste' AND a.actor = pg_temp.p('d2')
     ORDER BY a.id DESC LIMIT 1)
  AND (SELECT (private.journal_portee('candidatures', a.row_id, a.actor, a.payload)).cote = 'deux'
          AND (a.payload ->> 'lignes_hors_genre')::int = 4
     FROM public.audit_logs a WHERE a.action = 'formulaires_liste' AND a.actor = pg_temp.p('d4')
     ORDER BY a.id DESC LIMIT 1),
  'chaque lecture de liste laisse une ligne d''audit bornee a son cote ; le super-admin journalise les 4 lignes de l''autre cote');

-- ------------------------------------------------------------
-- (g) Garder une ligne pour suivi (transition 2), la liste des personnes a
-- prevenir (CAND-BR-16) et le geste « prevenu » (transition 26)
-- ------------------------------------------------------------
SELECT pg_temp.garde('avant8', pg_temp.ecritures());
SELECT pg_temp.garde('ligne_r4', to_jsonb((pg_temp.rep('A1', '2026-10-04 13:00:00')).id));
SELECT pg_temp.garde('ligne_r8', to_jsonb((pg_temp.rep('A1', '2026-10-08 16:00:00')).id));
SELECT pg_temp.garde('ligne_r1', to_jsonb((pg_temp.rep('A1', '2026-10-01 10:00:00')).id));
-- Hors portee : un homme ne garde pas une femme, le super-admin non plus (il ne decide que du sien).
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$)
    = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$, 'aal2')
    = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant8'),
  'garder pour suivi : hors portee rendu, super-admin compris, 0 ecriture');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs a WHERE a.action = 'formulaire_hors_portee') = 2
  AND (SELECT bool_and((private.journal_portee('candidatures', a.row_id, a.actor, a.payload)).cote = 'female')
         FROM public.audit_logs a WHERE a.action = 'formulaire_hors_portee'),
  'la trace de la tentative hors portee ne se lit que du cote vise (les femmes), jamais de celui de son auteur');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$,
  '42501', 'garder pour suivi : direction au genre inconnu refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$,
  '42501', 'garder pour suivi : tuteur refuse');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$,
  '42501', 'garder pour suivi : candidat refuse');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.garder_formulaire_pour_suivi('ca3b0000-0000-4000-8000-000000000000')$$,
  '42501', 'garder pour suivi : anon refuse (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin', $$SELECT public.garder_formulaire_pour_suivi(NULL)$$, '22023', 'garder pour suivi : sans reponse, 22023');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.garder_formulaire_pour_suivi('ca3b0000-0000-4000-8000-000000000000')$$)
    = '{"erreur": "absente"}'::jsonb
  AND pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r1') #>> '{}')::uuid)$$)
    = '{"erreur": "ligne_historique"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant8'),
  'une reponse absente ou en historique ne se garde pas : refus rendus, 0 ecriture');
-- La directrice garde r4 : une candidature recue, sans compte, sans contact rendu.
SELECT pg_temp.garde('suivi_r4', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$));
SELECT pg_temp.vrai(pg_temp.lu('suivi_r4') ->> 'rejoue' = 'false'
  AND pg_temp.lu('suivi_r4') #>> '{candidature,etape}' = 'recue' AND pg_temp.lu('suivi_r4') #>> '{candidature,issue}' = 'en_cours'
  AND pg_temp.lu('suivi_r4') #>> '{candidature,version}' = '1'
  AND pg_temp.lu('suivi_r4')::text !~ 'Essai|9665000|test\.invalid'
  AND (SELECT c.etape = 'recue' AND c.etat IS NULL AND c.profile_id IS NULL AND c.genre = 'female' AND c.source = 'import'
          AND c.source_ref = pg_temp.ref('A1', '2026-10-04 13:00:00') AND c.nom_complet = 'Essai Femme Deux Corrigee'
          AND c.langue IS NULL
     FROM public.candidatures c WHERE c.id = (pg_temp.lu('suivi_r4') #>> '{candidature,id}')::uuid)
  AND (SELECT k.courriel IS NULL AND k.courriel_brut IS NULL AND k.telephone = '+966500000304'
     FROM public.candidature_contacts k WHERE k.candidature_id = (pg_temp.lu('suivi_r4') #>> '{candidature,id}')::uuid)
  AND (SELECT suivi_id = (pg_temp.lu('suivi_r4') #>> '{candidature,id}')::uuid AND candidature_id IS NULL
     FROM public.formulaires_reponses WHERE id = (pg_temp.lu('ligne_r4') #>> '{}')::uuid)
  AND (SELECT (e ->> 'type') = 'creee' AND e -> 'details' @> '{"geste": "garder_pour_suivi", "transition": 2}'::jsonb
         AND e ->> 'auteur_id' = pg_temp.p('d2')::text
     FROM (SELECT to_jsonb(x) AS e FROM public.candidature_evenements x
            WHERE x.candidature_id = (pg_temp.lu('suivi_r4') #>> '{candidature,id}')::uuid) q)
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'suivi') = 1,
  'transition 2 : une candidature recue SANS compte, au nom et aux contacts de la ligne, au cote de la ligne, un evenement et une ligne de journal');
SELECT pg_temp.vrai((pg_temp.ecritures() - 'candidatures' - 'contacts' - 'evenements' - 'journal')
    = (pg_temp.lu('avant8') - 'candidatures' - 'contacts' - 'evenements' - 'journal')
  AND (pg_temp.ecritures() ->> 'candidatures')::int = (pg_temp.lu('avant8') ->> 'candidatures')::int + 1
  AND (pg_temp.ecritures() ->> 'contacts')::int = (pg_temp.lu('avant8') ->> 'contacts')::int + 1
  AND (pg_temp.ecritures() ->> 'evenements')::int = (pg_temp.lu('avant8') ->> 'evenements')::int + 1
  AND (pg_temp.ecritures() ->> 'journal')::int = (pg_temp.lu('avant8') ->> 'journal')::int + 1,
  'garder pour suivi n''ecrit rien d''autre : 0 profil, 0 invitation, 0 piece, 0 accord, 0 reponse du candidat, 0 disponibilite');
-- Le rejeu : la meme ligne de suivi, rien de plus.
SELECT pg_temp.garde('avant9', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r4') #>> '{}')::uuid)$$)
    = (pg_temp.lu('suivi_r4') || '{"rejoue": true}'::jsonb)
  AND pg_temp.ecritures() = pg_temp.lu('avant9'),
  'garder deux fois la meme ligne : la meme candidature (rejoue = true), 0 ecriture');
-- Le super-admin garde les lignes de son cote (r8, courriel mal forme).
SELECT pg_temp.garde('suivi_r8', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r8') #>> '{}')::uuid)$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('suivi_r8') ->> 'rejoue' = 'false'
  AND (SELECT k.courriel IS NULL AND k.courriel_brut = 'pas-un-courriel' AND k.telephone IS NULL
     FROM public.candidature_contacts k WHERE k.candidature_id = (pg_temp.lu('suivi_r8') #>> '{candidature,id}')::uuid),
  'le super-admin garde une ligne de son cote ; le courriel mal forme reste « a obtenir », il n''est jamais une adresse');

CREATE FUNCTION pg_temp.jour() RETURNS date LANGUAGE sql STABLE AS $$ SELECT (pg_catalog.now() AT TIME ZONE 'UTC')::date $$;
GRANT EXECUTE ON FUNCTION pg_temp.jour() TO authenticated, anon;

-- ------------------------------------------------------------
-- (h) La liste des personnes a prevenir et « consigner prevenu » (CAND-BR-16)
-- ------------------------------------------------------------
-- La directrice garde aussi r13, qui a un courriel valide : elle ne se previent pas
-- par WhatsApp, elle s'invite par courriel (transition 3, avec la file des courriels, L5).
SELECT pg_temp.garde('ligne_r13', to_jsonb((pg_temp.rep('A1', '2026-10-13 10:00:00')).id));
SELECT pg_temp.garde('suivi_r13', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r13') #>> '{}')::uuid)$$));
SELECT pg_temp.garde('pf', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$));
SELECT pg_temp.garde('ph', pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$));
SELECT pg_temp.garde('ps', pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$, 'aal2'));
SELECT pg_temp.vrai((pg_temp.lu('pf') ->> 'total')::int = 1 AND (pg_temp.lu('ph') ->> 'total')::int = 1
  AND (pg_temp.lu('ps') ->> 'total')::int = 2
  AND pg_temp.lu('pf') #>> '{lignes,0,id}' = pg_temp.lu('suivi_r4') #>> '{candidature,id}'
  AND pg_temp.lu('ph') #>> '{lignes,0,id}' = pg_temp.lu('suivi_r8') #>> '{candidature,id}'
  AND pg_temp.lu('pf') #>> '{lignes,0,nomComplet}' = 'Essai Femme Deux Corrigee'
  AND pg_temp.lu('pf') #>> '{lignes,0,prevenu}' = 'false' AND pg_temp.lu('pf') #>> '{lignes,0,version}' = '1'
  AND pg_temp.lu('ph') #>> '{lignes,0,indicatifAConfirmer}' = 'false'
  AND (SELECT array_agg(k ORDER BY k COLLATE "C") FROM jsonb_object_keys(pg_temp.lu('pf') #> '{lignes,0}') k)
     = ARRAY['accordWhatsapp', 'canal', 'dateEnvoi', 'id', 'indicatifAConfirmer', 'nomComplet', 'prevenu', 'prevenuLe',
             'recueLe', 'reference', 'version'],
  'la liste des personnes a prevenir : les lignes recue gardees pour suivi, sans courriel valide, dans la portee (la femme, l''homme, les deux pour le super-admin) ; celle qui a un courriel valide n''y est pas');
SELECT pg_temp.vrai(pg_temp.lu('pf')::text !~ '9665000|test\.invalid|0501234567',
  'aucun numero ni courriel dans la liste des personnes a prevenir : le contact se lit par lire_contact_candidature, journalisee');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$, '42501',
  'a prevenir : direction au genre inconnu refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$, '42501', 'a prevenir : tuteur refuse');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$, '42501', 'a prevenir : candidat refuse');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.lister_a_prevenir_candidats(false, 1)$$, '42501', 'a prevenir : anon refuse (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_a_prevenir_candidats(NULL, 1)$$, '22023', 'a prevenir : argument nul, 22023');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 0)$$, '22023', 'a prevenir : page 0, 22023');
-- La liste des candidatures de CAND-L1 lit aussi ces lignes recue, dans la meme portee.
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_candidatures('{"etape": "recue"}', 'activite', 1)$$) ->> 'total')::int = 2
  AND (pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_candidatures('{"etape": "recue"}', 'activite', 1)$$) ->> 'total')::int = 1
  AND (SELECT (l ->> 'courrielAObtenir')::boolean
         FROM jsonb_array_elements(pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_candidatures('{"etape": "recue"}', 'activite', 1)$$) -> 'lignes') l
        WHERE l ->> 'id' = pg_temp.lu('suivi_r4') #>> '{candidature,id}'),
  'lister_candidatures voit les lignes recue de son cote, avec la marque « courriel a obtenir » (aucun contact)');

-- Consigner « prevenu » : liste fermee, date non future, ligne sans courriel valide.
SELECT pg_temp.garde('c4', to_jsonb(pg_temp.lu('suivi_r4') #>> '{candidature,id}'));
SELECT pg_temp.garde('c13', to_jsonb(pg_temp.lu('suivi_r13') #>> '{candidature,id}'));
SELECT pg_temp.garde('c8', to_jsonb(pg_temp.lu('suivi_r8') #>> '{candidature,id}'));
SELECT pg_temp.garde('avant10', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'sms', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0001')$$)
    = '{"erreur": "canal_inconnu"}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'texte_libre', pg_temp.jour(), 1, 'cle-prev-0001')$$)
    = '{"erreur": "modele_inconnu"}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour() + 2, 1, 'cle-prev-0001')$$)
    = '{"erreur": "date_future"}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c13') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0002')$$)
    = '{"erreur": "courriel_disponible"}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 7, 'cle-prev-0004')$$)
    = '{"erreur": "conflit_candidature", "versionCourante": 1}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat('ca3b0000-0000-4000-8000-000000000000', 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0005')$$)
    = '{"erreur": "absente"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant10'),
  'consigner prevenu : canal, modele, date future, courriel disponible, version perimee, absente : refus rendus et nommes, 0 ecriture');
SELECT pg_temp.garde('hp1', pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0003')$$));
SELECT pg_temp.vrai(
  pg_temp.lu('hp1') = '{"erreur": "hors_portee"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements WHERE candidature_id = (pg_temp.lu('c4') #>> '{}')::uuid
         AND type = 'lecture_hors_portee') = 1
  AND (pg_temp.ecritures() ->> 'gestes') = (pg_temp.lu('avant10') ->> 'gestes'),
  'consigner prevenu : l''autre cote est hors portee (la tentative est tracee sur la ligne, aucun geste ecrit)');
-- Une candidature qui n'est plus « recue » (une inscrite en Salle d'examen) : transition interdite, nommee.
SELECT pg_temp.garde('cb1', to_jsonb((SELECT id FROM public.candidatures WHERE profile_id = pg_temp.p('b1'))));
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('cb1') #>> '{}')::uuid,
      'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0006')$$)
    = '{"erreur": "transition_interdite", "geste": "consigner_prevenu", "etape": "prequalification",
        "etat": "a_completer", "issue": "en_cours", "enPause": false, "raison": "etat"}'::jsonb,
  'consigner prevenu : une candidature deja inscrite n''est plus une ligne recue (transition_interdite)');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin',
  $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0007')$$,
  '42501', 'consigner prevenu : direction au genre inconnu refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian',
  $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0008')$$,
  '42501', 'consigner prevenu : tuteur refuse');
SELECT pg_temp.refus_en(pg_temp.p('b1'), 'teacher',
  $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0009')$$,
  '42501', 'consigner prevenu : candidat refuse');
SELECT pg_temp.refus_en(NULL, NULL,
  $$SELECT public.consigner_prevenu_candidat('ca3b0000-0000-4000-8000-000000000000', 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0010')$$,
  '42501', 'consigner prevenu : anon refuse (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin',
  $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, NULL, 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0011')$$,
  '22023', 'consigner prevenu : canal absent, 22023');
-- Le geste : version, evenement « prevenu », rien d'envoye.
SELECT pg_temp.garde('prev1', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0012')$$));
SELECT pg_temp.vrai(pg_temp.lu('prev1') ->> 'rejoue' = 'false' AND pg_temp.lu('prev1') #>> '{candidature,version}' = '2'
  AND pg_temp.lu('prev1') #>> '{candidature,etape}' = 'recue'
  AND (SELECT e.type = 'prevenu' AND e.auteur_id = pg_temp.p('d2') AND e.details ->> 'canal' = 'whatsapp'
          AND e.details ->> 'modele' = 'lien_inscription' AND (e.details ->> 'date')::date = pg_temp.jour()
          AND e.details ->> 'geste' = 'consigner_prevenu' AND (e.details ->> 'transition')::int = 26
       FROM public.candidature_evenements e
      WHERE e.candidature_id = (pg_temp.lu('c4') #>> '{}')::uuid AND e.type = 'prevenu')
  AND (SELECT count(*) FROM public.candidature_gestes WHERE geste = 'consigner_prevenu') = 1
  AND to_regclass('public.candidature_courriels') IS NULL
  AND (SELECT count(*) FROM public.candidatures WHERE id = (pg_temp.lu('c4') #>> '{}')::uuid AND profile_id IS NULL) = 1,
  'transition 26 : un evenement prevenu (canal, modele, date), la version avance ; la ligne reste sans compte ; aucune file de courriels n''existe encore, rien n''est envoye par ce module');
SELECT pg_temp.garde('avant11', pg_temp.ecritures());
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('d2'), 'admin',
    $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0012')$$)
    = (pg_temp.lu('prev1') || '{"rejoue": true}'::jsonb)
  AND pg_temp.en(pg_temp.p('d2'), 'admin',
    $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 2, 'cle-prev-0012')$$) @> '{"rejoue": true}'
  AND pg_temp.en(pg_temp.p('d2'), 'admin',
    $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c13') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0012')$$)
    = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant11'),
  'la meme cle rejouee rend le premier resultat (meme sans version a jour), 0 ecriture ; la cle d''une autre ligne est refusee');
-- La liste des personnes a prevenir ne montre plus la personne prevenue, sauf si on les demande toutes.
SELECT pg_temp.garde('pf2', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$));
SELECT pg_temp.garde('pf3', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_a_prevenir_candidats(true, 1)$$));
SELECT pg_temp.vrai((pg_temp.lu('pf2') ->> 'total')::int = 0
  AND (pg_temp.lu('pf3') ->> 'total')::int = 1 AND pg_temp.lu('pf3') #>> '{lignes,0,prevenu}' = 'true'
  AND pg_temp.lu('pf3') #>> '{lignes,0,canal}' = 'whatsapp'
  AND pg_temp.lu('pf3') #>> '{lignes,0,dateEnvoi}' = pg_temp.jour()::text
  AND pg_temp.lu('pf3') #>> '{lignes,0,version}' = '2'
  AND (pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_formulaires_importes('{"aPrevenir": true}', 1)$$) ->> 'total')::int = 0
  AND (pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_formulaires_importes('{"suivi": true}', 1)$$) ->> 'total')::int = 2,
  'une personne prevenue sort de la liste (et de « a prevenir » des reponses importees) ; la liste complete garde son canal et la date de l''envoi');
-- Un second envoi se consigne (le premier peut n'avoir pas abouti), sous une autre cle.
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('d2'), 'admin',
    $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 2, 'cle-prev-0013')$$)
    #>> '{candidature,version}' = '3',
  'un second envoi se consigne, sous sa propre cle');
-- Le super-admin consigne de son cote (r8), pas de l'autre.
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c8') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 1, 'cle-prev-0014')$$, 'aal2')
    #>> '{candidature,version}' = '2'
  AND pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.consigner_prevenu_candidat((pg_temp.lu('c4') #>> '{}')::uuid, 'whatsapp', 'lien_inscription', pg_temp.jour(), 3, 'cle-prev-0015')$$, 'aal2')
    = '{"erreur": "hors_portee"}'::jsonb,
  'le super-admin consigne de son cote ; l''autre cote lui est hors portee (il le lit, il ne decide pas)');
-- L'action groupee ne prend pas le geste : il reste hors du lot (GesteNonGroupable de CAND-L2A2).
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.apercu_lot_candidats('consigner_prevenu', ARRAY[(pg_temp.lu('c4') #>> '{}')::uuid])$$)
    = '{"erreur": "geste_non_groupable", "geste": "consigner_prevenu"}'::jsonb,
  'consigner prevenu reste un geste a l''unite : l''action groupee le refuse (geste_non_groupable)');

-- ------------------------------------------------------------
-- (i) Le rapprochement (spec 3.4) : courriel confirme, telephone, nom, genre, B
-- ------------------------------------------------------------
CREATE FUNCTION pg_temp.inscrit(p_n text, p_courriel text, p_prenom text, p_nom text, p_genre text, p_tel text,
                                p_code text DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.u(p_n, p_courriel);
  RETURN pg_temp.en(pg_temp.p(p_n), NULL, pg_catalog.format(
    $q$SELECT public.inscrire_candidat(%L, %L, %L, %L::public.gender, %L, 'fr', '2026-10-v1')$q$,
    p_code, p_prenom, p_nom, p_genre, p_tel));
END $$;
CREATE FUNCTION pg_temp.cid(p_n text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM public.candidatures WHERE profile_id = pg_temp.p(p_n) $$;
CREATE FUNCTION pg_temp.brouillon(p_n text) RETURNS public.candidature_reponses
LANGUAGE sql STABLE AS $$ SELECT r FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.cid(p_n) $$;
GRANT EXECUTE ON FUNCTION pg_temp.inscrit(text, text, text, text, text, text, text), pg_temp.cid(text),
  pg_temp.brouillon(text) TO authenticated, anon;

SELECT pg_temp.garde('avant12', pg_temp.ecritures());
-- Le meme courriel confirme qu'une ligne importee : lien et pre-remplissage (r2, hommes).
SELECT pg_temp.garde('i_mail', pg_temp.inscrit('c1', 'h2@test.invalid', 'Essai', 'CandidatCourriel', 'male', '+966500000401'));
SELECT pg_temp.vrai(pg_temp.lu('i_mail') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT candidature_id = pg_temp.cid('c1') AND rattachement = 'courriel' AND rattachee_le IS NOT NULL
          AND etat = 'active'
          AND prerempli_champs = ARRAY['classesSouhaitees', 'debutPossible', 'experienceDebutants', 'ijazaPresentable',
                                       'langueMaternelle', 'languesExplication', 'niveauMemorisationDeclare']
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-02 10:00:00'))
  AND (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-01 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_rapprochements) = 0,
  'L3-7 : le courriel confirme d''une reponse importee la relie et pre-remplit ; la ligne en historique (meme telephone) n''est pas touchee ; aucune proposition');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = pg_temp.cid('c1')) = 1
  AND (SELECT r.source = 'candidat' AND r.brouillon AND r.envoye_le IS NULL AND r.version = 1
          AND r.questionnaire_version = 'salle-examen-1'
          AND r.reponses = '{"debutPossible": "immediat", "ijazaPresentable": "oui", "langueMaternelle": "ar",
              "classesSouhaitees": "1", "languesExplication": ["francais", "poular"], "experienceDebutants": "oui",
              "niveauMemorisationDeclare": "coran_entier"}'::jsonb
     FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.cid('c1'))
  AND NOT ((pg_temp.brouillon('c1')).reponses ?| ARRAY['disponibilitesDeclarees', 'fuseauIana', 'publics', 'paysResidence',
        'paysVersement', 'compteBancaire', 'operateurs', 'moyensAccessibles', 'riwayat', 'niveauLectureTajwid'])
  AND (SELECT etape = 'prequalification' AND etat = 'a_completer' AND version = 1 AND paiement = 'inconnu' AND NOT en_pause
     FROM public.candidatures WHERE id = pg_temp.cid('c1'))
  AND (SELECT count(*) FROM public.contract_acceptances WHERE profile_id = pg_temp.p('c1')) = 0
  AND (SELECT count(*) FROM public.kyc_documents WHERE profile_id = pg_temp.p('c1')) = 0
  AND (SELECT count(*) FROM public.weekly_availability) = 0,
  'le brouillon contient les 7 reponses utiles (colonnes E a I, K, L), jamais les disponibilites, le pays, le fuseau, les publics, le paiement ; rien n''est envoye a sa place (brouillon, etat a completer, version 1, 0 accord, 0 piece)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_evenements WHERE candidature_id = pg_temp.cid('c1')) = 2
  AND (SELECT e.type = 'import' AND e.details ->> 'geste' = 'rattachement' AND e.details ->> 'cle' = 'courriel'
         FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.cid('c1') AND e.type = 'import')
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'rattachement' AND auteur_id = pg_temp.p('c1')) = 1,
  'le lien est trace des deux cotes : evenement de la candidature (import, courriel) et ligne du journal des reponses');
SELECT pg_temp.garde('q_c1', pg_temp.en(pg_temp.p('c1'), 'teacher', $$SELECT public.questionnaire_salle_examen()$$));
SELECT pg_temp.vrai((pg_temp.lu('q_c1') #>> '{dernieresReponses,brouillon}') = 'true'
  AND (pg_temp.lu('q_c1') ->> 'versionBrouillon') = '1'
  AND pg_temp.lu('q_c1') #> '{dernieresReponses,reponses,languesExplication}' = '["francais", "poular"]'::jsonb
  AND (pg_temp.lu('q_c1') #>> '{dernieresReponses,envoyeLe}') IS NULL,
  'la personne retrouve son brouillon pre-rempli dans la Salle d''examen, a relire et a envoyer elle-meme (version 1 du brouillon)');

-- Le meme telephone, seulement (r14, femme) : rien n'est montre, une proposition a la direction.
SELECT pg_temp.garde('ligne_r14', to_jsonb((pg_temp.rep('A1', '2026-10-14 10:00:00')).id));
SELECT pg_temp.garde('suivi_r14', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_r14') #>> '{}')::uuid)$$));
SELECT pg_temp.garde('i_tel', pg_temp.inscrit('c2', 'cp@test.invalid', 'Essai', 'CandidatTel', 'female', '+966500000314'));
SELECT pg_temp.vrai(pg_temp.lu('i_tel') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT candidature_id IS NULL AND rattachement IS NULL AND prerempli_champs IS NULL
     FROM public.formulaires_reponses WHERE id = (pg_temp.lu('ligne_r14') #>> '{}')::uuid)
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('c2')
        AND reponse_id = (pg_temp.lu('ligne_r14') #>> '{}')::uuid AND cle = 'telephone' AND statut = 'proposee') = 1
  AND (SELECT count(*) FROM public.formulaires_rapprochements) = 1
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = pg_temp.cid('c2')) = 0
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'proposition') = 1,
  'L3-12 : un courriel neuf et le telephone d''une reponse importee : 1 proposition a la direction, aucun lien, aucun pre-remplissage');
SELECT pg_temp.garde('etat_c2', pg_temp.en(pg_temp.p('c2'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.garde('q_c2', pg_temp.en(pg_temp.p('c2'), 'teacher', $$SELECT public.questionnaire_salle_examen()$$));
SELECT pg_temp.vrai(pg_temp.lu('etat_c2')::text !~ 'Quatorze|f14@|966500000314|rapprochement|proposition'
  AND pg_temp.lu('q_c2')::text !~ 'Quatorze|f14@|966500000314|rapprochement|proposition'
  AND pg_temp.lu('q_c2') -> 'dernieresReponses' = 'null'::jsonb,
  'L3-12 : la personne ne voit rien du rapprochement par telephone (ni etat_dossier, ni questionnaire, ni brouillon)');

-- Le nom seul ne rapproche jamais ; un autre genre non plus (courriel et telephone d'un homme, une femme).
SELECT pg_temp.garde('i_nom', pg_temp.inscrit('c3', 'cn@test.invalid', 'Essai Homme', 'Un', 'male', '+966500000419'));
SELECT pg_temp.garde('i_genre', pg_temp.inscrit('c4', 'm16@test.invalid', 'Essai', 'CandidateGenre', 'female', '+966500000316'));
SELECT pg_temp.vrai(pg_temp.lu('i_nom') = '{"resultat": "acceptee"}'::jsonb AND pg_temp.lu('i_genre') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT nom_complet = 'Essai Homme Un' FROM public.candidatures WHERE id = pg_temp.cid('c3'))
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE candidature_id IN (pg_temp.cid('c3'), pg_temp.cid('c4')))
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_rapprochements WHERE candidature_id IN (pg_temp.cid('c3'), pg_temp.cid('c4')))
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id IN (pg_temp.cid('c3'), pg_temp.cid('c4'))) = 0
  AND (SELECT count(*) FROM public.formulaires_rapprochements) = 1,
  'L3-7 : le nom seul (le meme que deux reponses) ne rapproche rien ; une femme au courriel et au telephone d''une reponse d''homme : ni lien ni proposition (rien ne traverse les deux cotes)');

-- Une personne de B (courriel confirme) : reconnue, rien de pre-rempli (L3-19).
SELECT pg_temp.garde('i_b', pg_temp.inscrit('c5', 'b1@test.invalid', 'Essai', 'CandidatB', 'male', '+966500000420'));
SELECT pg_temp.vrai(pg_temp.lu('i_b') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT e.details ->> 'reconnue' = 'inscription_12_10' FROM public.candidature_evenements e
        WHERE e.candidature_id = pg_temp.cid('c5') AND e.type = 'creee')
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
        WHERE e.candidature_id IN (pg_temp.cid('c1'), pg_temp.cid('c3'), pg_temp.cid('c4')) AND e.details ? 'reconnue')
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE candidature_id = pg_temp.cid('c5'))
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = pg_temp.cid('c5')) = 0,
  'L3-19 : une personne de B (courriel confirme) est reconnue (evenement), 0 champ pre-rempli, 0 ligne rattachee');

-- Une ligne gardee pour suivi devient la candidature de la personne (r13, meme courriel confirme).
SELECT pg_temp.garde('avant13', pg_temp.ecritures());
SELECT pg_temp.garde('i_suivi', pg_temp.inscrit('c6', 'f13@test.invalid', 'Essai', 'CandidateSuivie', 'female', '+966500000413'));
SELECT pg_temp.vrai(pg_temp.lu('i_suivi') = '{"resultat": "acceptee"}'::jsonb
  AND pg_temp.cid('c6') = (pg_temp.lu('c13') #>> '{}')::uuid
  AND (SELECT etape = 'prequalification' AND etat = 'a_completer' AND issue = 'en_cours' AND source = 'import'
          AND profile_id = pg_temp.p('c6') AND langue = 'fr' AND version = 2 AND genre = 'female'
          AND nom_complet = 'Essai CandidateSuivie'
     FROM public.candidatures WHERE id = pg_temp.cid('c6'))
  AND (SELECT courriel = 'f13@test.invalid' AND telephone = '+966500000413'
     FROM public.candidature_contacts WHERE candidature_id = pg_temp.cid('c6'))
  AND (pg_temp.ecritures() ->> 'candidatures')::int = (pg_temp.lu('avant13') ->> 'candidatures')::int
  AND (pg_temp.ecritures() ->> 'profils')::int = (pg_temp.lu('avant13') ->> 'profils')::int + 1
  AND (SELECT candidature_id = pg_temp.cid('c6') AND suivi_id = pg_temp.cid('c6') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE id = (pg_temp.lu('ligne_r13') #>> '{}')::uuid)
  AND (SELECT r.reponses -> 'langueMaternelle' = '"ar"'::jsonb AND r.brouillon
     FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.cid('c6')),
  'une ligne « pour suivi » du meme courriel confirme devient CETTE candidature (meme identifiant, Salle d''examen a completer, contact mis a jour) et pre-remplit ; aucune candidature de plus, un compte de plus');
SELECT pg_temp.vrai(
  (SELECT e.type = 'transition' AND e.etape_avant = 'recue' AND e.etape_apres = 'prequalification'
          AND e.etat_apres = 'a_completer' AND e.details @> '{"geste": "inscription", "transition": 5, "ligneSuivie": true}'
     FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.cid('c6') AND e.type = 'transition')
  AND (SELECT count(*) FROM public.candidature_evenements WHERE candidature_id = pg_temp.cid('c6')) = 3,
  'la conversion est une transition tracee (recue vers prequalification, transition 5) entre la creation de la ligne et le lien');

-- L'invitation, seconde porte, rapproche de la meme maniere (r15, hommes).
INSERT INTO public.invitations_enseignant (code, email, cree_par, expire_le)
VALUES ('RSTV-WXYZ-2345', 'h15@test.invalid', pg_temp.p('d1'), now() + interval '14 days');
SELECT pg_temp.garde('i_code', pg_temp.inscrit('c7', 'h15@test.invalid', 'Essai', 'CandidatInvite', 'male', '+966500000415',
  'RSTV-WXYZ-2345'));
SELECT pg_temp.vrai(pg_temp.lu('i_code') = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT source = 'invitation' FROM public.candidatures WHERE id = pg_temp.cid('c7'))
  AND (SELECT candidature_id = pg_temp.cid('c7') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-15 10:00:00'))
  AND (SELECT r.reponses ?& ARRAY['languesExplication', 'niveauMemorisationDeclare'] AND r.brouillon
     FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.cid('c7')),
  'L3-7 : par invitation, memes regles : le courriel confirme relie la reponse importee et pre-remplit');

-- La direction applique la proposition par telephone (transition 27).
SELECT pg_temp.garde('lr_f', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_rapprochements_candidats(1)$$));
SELECT pg_temp.garde('lr_h', pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.lister_rapprochements_candidats(1)$$));
SELECT pg_temp.garde('lr_s', pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.lister_rapprochements_candidats(1)$$, 'aal2'));
SELECT pg_temp.vrai((pg_temp.lu('lr_f') ->> 'total')::int = 1 AND (pg_temp.lu('lr_h') ->> 'total')::int = 0
  AND (pg_temp.lu('lr_s') ->> 'total')::int = 1
  AND pg_temp.lu('lr_f') #>> '{lignes,0,reponse,nomComplet}' = 'Essai Femme Quatorze'
  AND pg_temp.lu('lr_f') #>> '{lignes,0,candidature,nomComplet}' = 'Essai CandidatTel'
  AND pg_temp.lu('lr_f') #>> '{lignes,0,candidature,id}' = pg_temp.cid('c2')::text
  AND pg_temp.lu('lr_f') #>> '{lignes,0,cle}' = 'telephone' AND pg_temp.lu('lr_f') #>> '{lignes,0,candidature,version}' = '1'
  AND pg_temp.lu('lr_f')::text !~ '9665000|test\.invalid',
  'les propositions : la directrice lit la sienne (les deux noms, pour decider), la direction des hommes aucune, le super-admin les deux cotes ; aucun contact');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin', $$SELECT public.lister_rapprochements_candidats(1)$$, '42501', 'rapprochements : direction au genre inconnu refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian', $$SELECT public.lister_rapprochements_candidats(1)$$, '42501', 'rapprochements : tuteur refuse');
SELECT pg_temp.refus_en(pg_temp.p('c2'), 'teacher', $$SELECT public.lister_rapprochements_candidats(1)$$, '42501', 'rapprochements : la candidate concernee ne les lit pas');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.lister_rapprochements_candidats(1)$$, '42501', 'rapprochements : anon refuse (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_rapprochements_candidats(0)$$, '22023', 'rapprochements : page 0, 22023');
-- La candidate a deja ecrit une reponse : elle l'emporte sur le pre-remplissage.
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('c2'), 'teacher', $$SELECT public.enregistrer_reponses_salle_examen(
    'salle-examen-1', '{"langueMaternelle": "francais"}', 0, 'cle-brouillon-c2')$$) @> '{"versionBrouillon": 1}',
  'la candidate commence son brouillon avant que la direction rattache');
SELECT pg_temp.garde('avant14', pg_temp.ecritures());
SELECT pg_temp.garde('c_c2', to_jsonb(pg_temp.cid('c2')));
SELECT pg_temp.garde('c_c1', to_jsonb(pg_temp.cid('c1')));
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
      (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0001')$$) = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
      (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 9, 'cle-ratt-0002')$$)
    = '{"erreur": "conflit_candidature", "versionCourante": 1}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
      (pg_temp.lu('ligne_r13') #>> '{}')::uuid, 1, 'cle-ratt-0003')$$) = '{"erreur": "proposition_inconnue"}'::jsonb
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c1') #>> '{}')::uuid,
      (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0004')$$) = '{"erreur": "hors_portee"}'::jsonb
  AND (pg_temp.ecritures() ->> 'gestes') = (pg_temp.lu('avant14') ->> 'gestes')
  AND (pg_temp.ecritures() ->> 'journal') = (pg_temp.lu('avant14') ->> 'journal'),
  'rattacher : hors portee, version perimee, reponse sans proposition : refus rendus et nommes, aucune ligne rattachee, aucun geste ecrit');
SELECT pg_temp.refus_en(pg_temp.p('d3'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
  (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0005')$$, '42501', 'rattacher : direction au genre inconnu refusee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'guardian', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
  (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0006')$$, '42501', 'rattacher : tuteur refuse');
SELECT pg_temp.refus_en(pg_temp.p('c2'), 'teacher', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
  (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0007')$$, '42501', 'rattacher : la candidate ne se rattache pas elle-meme');
SELECT pg_temp.refus_en(NULL, NULL, $$SELECT public.rattacher_formulaire_candidat('ca3b0000-0000-4000-8000-000000000000',
  'ca3b0000-0000-4000-8000-000000000000', 1, 'cle-ratt-0008')$$, '42501', 'rattacher : anon refuse (ACL)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
  NULL, 1, 'cle-ratt-0009')$$, '22023', 'rattacher : sans reponse, 22023');
SELECT pg_temp.garde('ratt1', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat(
  (pg_temp.lu('c_c2') #>> '{}')::uuid, (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0010')$$));
SELECT pg_temp.vrai(pg_temp.lu('ratt1') ->> 'rejoue' = 'false' AND pg_temp.lu('ratt1') #>> '{candidature,version}' = '2'
  AND pg_temp.lu('ratt1') -> 'prerempli' = '["classesSouhaitees", "debutPossible", "experienceDebutants", "ijazaPresentable",
      "languesExplication", "niveauMemorisationDeclare"]'::jsonb
  AND (SELECT candidature_id = (pg_temp.lu('c_c2') #>> '{}')::uuid AND rattachement = 'telephone'
     FROM public.formulaires_reponses WHERE id = (pg_temp.lu('ligne_r14') #>> '{}')::uuid)
  AND (SELECT statut = 'appliquee' AND applique_par = pg_temp.p('d2') AND applique_le IS NOT NULL
     FROM public.formulaires_rapprochements WHERE candidature_id = (pg_temp.lu('c_c2') #>> '{}')::uuid)
  AND (SELECT r.reponses = '{"langueMaternelle": "francais", "debutPossible": "immediat", "ijazaPresentable": "oui",
        "classesSouhaitees": "1", "languesExplication": ["francais", "poular"], "experienceDebutants": "oui",
        "niveauMemorisationDeclare": "coran_entier"}'::jsonb AND r.version = 2 AND r.brouillon AND r.envoye_le IS NULL
     FROM public.candidature_reponses r WHERE r.candidature_id = (pg_temp.lu('c_c2') #>> '{}')::uuid),
  'transition 27 : la reponse est reliee par la direction, le brouillon pre-rempli SANS ecraser ce que la candidate a ecrit (sa langue maternelle l''emporte), sa version avance, la candidate renvoie son brouillon a relire');
SELECT pg_temp.vrai(
  (SELECT c.issue = 'retiree' AND c.profile_id IS NULL AND c.etape = 'recue' AND c.version = 2
     FROM public.candidatures c WHERE c.id = (pg_temp.lu('suivi_r14') #>> '{candidature,id}')::uuid)
  AND (SELECT e.details @> '{"geste": "rattacher", "transition": 27, "cause": "inscrite"}'::jsonb
          AND e.issue_avant = 'en_cours' AND e.issue_apres = 'retiree'
     FROM public.candidature_evenements e
    WHERE e.candidature_id = (pg_temp.lu('suivi_r14') #>> '{candidature,id}')::uuid AND e.type = 'transition')
  AND (SELECT count(*) FROM public.candidature_evenements WHERE candidature_id = (pg_temp.lu('c_c2') #>> '{}')::uuid
         AND type IN ('import', 'transition')) = 2
  AND (pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_rapprochements_candidats(1)$$) ->> 'total')::int = 0,
  'la ligne gardee pour suivi est retiree (la personne est inscrite), le geste est trace sur la candidature, la proposition sort de la liste');
SELECT pg_temp.garde('avant15', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
      (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 1, 'cle-ratt-0010')$$) = (pg_temp.lu('ratt1') || '{"rejoue": true}'::jsonb)
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('c_c2') #>> '{}')::uuid,
      (pg_temp.lu('ligne_r14') #>> '{}')::uuid, 2, 'cle-ratt-0011')$$) = '{"erreur": "reponse_deja_rattachee"}'::jsonb
  AND pg_temp.ecritures() = pg_temp.lu('avant15'),
  'rattacher deux fois : la cle rejouee rend le premier resultat ; une autre cle trouve la reponse deja rattachee ; 0 ecriture');

-- L'import APRES l'inscription : memes regles, dans l'autre sens.
SELECT pg_temp.inscrit('c8', 'rev1@test.invalid', 'Essai', 'RevUn', 'male', '+966500000501');
SELECT pg_temp.inscrit('c9', 'rev2@test.invalid', 'Essai', 'RevDeux', 'male', '+966500000502');
SELECT pg_temp.garde('f4', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-11-01 10:00:00', 'h', 'Essai Rev Un', '+966500000601', 'rev1@test.invalid'),
  pg_temp.l('2026-11-02 10:00:00', 'h', 'Essai Rev Deux', '+966500000502', 'rev2autre@test.invalid'),
  pg_temp.l('2026-11-03 10:00:00', 'f', 'Essai Rev Trois', '+966500000503', 'rev1@test.invalid'))));
SELECT pg_temp.garde('apercu4', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f4') #>> '{}', 'Classeur L3', 'A6')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu4') -> 'compteurs' = '{"lignesLues": 3, "nouvelles": 3, "corrigees": 0, "dejaConnues": 0,
      "ignorees": 0, "aCorriger": 0, "historique": 0, "personnes": 3}'::jsonb
  AND pg_temp.lu('apercu4') -> 'groupes' = '[]'::jsonb,
  'un couple, ou deux personnes de genres declares differents au meme courriel, ne forment pas un groupe de doublons : 3 personnes, rien ne traverse les deux cotes');
SELECT pg_temp.garde('avant16', pg_temp.ecritures());
SELECT pg_temp.garde('lot4', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f4') #>> '{}', 'Classeur L3', 'A6',
      pg_temp.lu('apercu4') ->> 'jeton', '[]', 'cle-import-0004')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('lot4') ->> 'ecritureEffectuee' = 'true'
  AND (SELECT candidature_id = pg_temp.cid('c8') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A6', '2026-11-01 10:00:00'))
  AND (SELECT r.reponses ?& ARRAY['languesExplication', 'niveauMemorisationDeclare'] AND r.brouillon
     FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.cid('c8'))
  AND (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A6', '2026-11-02 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('c9') AND statut = 'proposee') = 1
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A6', '2026-11-03 10:00:00')
                    AND candidature_id IS NOT NULL)
  AND (pg_temp.ecritures() ->> 'candidatures') = (pg_temp.lu('avant16') ->> 'candidatures')
  AND (pg_temp.ecritures() ->> 'profils') = (pg_temp.lu('avant16') ->> 'profils'),
  'importer apres l''inscription : le courriel confirme d''une inscrite relie sa ligne et pre-remplit ; le telephone seul propose ; une ligne de l''autre genre ne se rattache pas ; aucune candidature ni compte cree');

-- ------------------------------------------------------------
-- (j) Doublons avec ce que la base garde : la plus recente, une ligne utilisee, les choix de la direction
-- ------------------------------------------------------------
SELECT pg_temp.garde('f3a', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-20 10:00:00', 'h', 'Essai Homme Neuf Bis', '+966500000399', 'x1@test.invalid'))));
SELECT pg_temp.garde('apercu5', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f3a') #>> '{}', 'Classeur L3', 'A2')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu5') -> 'compteurs' = '{"lignesLues": 1, "nouvelles": 1, "corrigees": 0, "dejaConnues": 0,
      "ignorees": 0, "aCorriger": 0, "historique": 0, "personnes": 1}'::jsonb
  AND pg_temp.lu('apercu5') #> '{groupes,0}' @> '{"nature": "courriel", "taille": 2, "lignes": [2], "retenueProposee": 2,
      "retenueDansLaBase": false, "choisi": false, "choix": null}'::jsonb,
  'une ligne plus recente que celle de la base (meme courriel, autre fichier) : un groupe de deux, la nouvelle proposee, la compteur de personnes compte une personne');
SELECT pg_temp.garde('g5', to_jsonb(pg_temp.lu('apercu5') #>> '{groupes,0,id}'));
SELECT pg_temp.garde('avant17', pg_temp.ecritures());
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3a') #>> '{}', 'Classeur L3', 'A2',
      pg_temp.lu('apercu5') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g5') #>> '{}',
      'retenue', 'Classeur L3|A2|ligne-inconnue')), 'cle-import-0005')$$, 'aal2')
    = jsonb_build_object('erreur', 'choix_invalide', 'groupes', jsonb_build_array(pg_temp.lu('g5') #>> '{}'), 'ecritureEffectuee', false)
  AND pg_temp.ecritures() = pg_temp.lu('avant17'),
  'une reference qui n''est pas dans le groupe : choix_invalide, 0 ecriture');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3a') #>> '{}', 'Classeur L3', 'A2',
  pg_temp.lu('apercu5') ->> 'jeton', '[{"groupe": "abcdefabcdef"}]', 'cle-import-0005')$$, '22023',
  'un choix sans reference retenue est mal forme (22023)', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3a') #>> '{}', 'Classeur L3', 'A2',
  pg_temp.lu('apercu5') ->> 'jeton', '{"groupe": "x"}', 'cle-import-0005')$$, '22023',
  'des choix qui ne sont pas une liste sont refuses (22023)', 'authenticated', 'aal2');
SELECT pg_temp.garde('lot5', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3a') #>> '{}', 'Classeur L3', 'A2',
      pg_temp.lu('apercu5') ->> 'jeton', '[]', 'cle-import-0005')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('A2', '2026-10-20 10:00:00')).id
          AND suivi_id IS NULL AND candidature_id IS NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-10 10:00:00'))
  AND (SELECT etat = 'active' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A2', '2026-10-20 10:00:00'))
  AND (SELECT j.type = 'historique' AND j.lot_id = (pg_temp.lu('lot5') ->> 'lot')::uuid
          AND j.details ->> 'remplaceePar' = (pg_temp.rep('A2', '2026-10-20 10:00:00')).id::text
     FROM public.formulaires_journal j WHERE j.reponse_id = (pg_temp.rep('A1', '2026-10-10 10:00:00')).id AND j.type = 'historique')
  AND (SELECT count(*) FROM public.formulaires_reponses) = 16,
  'CAND-Q16 : la plus recente l''emporte aussi sur une ligne deja en base (hors du fichier) : l''ancienne passe en historique, tracee, rien n''est efface');
SELECT pg_temp.garde('imp7', to_jsonb(pg_temp.importees()));
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3a') #>> '{}', 'Classeur L3', 'A2',
      pg_temp.lu('apercu5') ->> 'jeton', '[]', 'cle-import-0006')$$, 'aal2') -> 'compteurs' ->> 'dejaConnues') = '1'
  AND pg_temp.importees() = pg_temp.lu('imp7') #>> '{}',
  'rejouer ce fichier ne change plus rien : la ligne est deja connue, l''ancienne reste en historique');

-- Une ligne utilisee (rattachee a une candidature) n'est jamais mise en historique.
SELECT pg_temp.garde('f3b', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-25 10:00:00', 'h', 'Essai Homme Z', '+966500000398', 'h2@test.invalid'))));
SELECT pg_temp.garde('apercu6', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f3b') #>> '{}', 'Classeur L3', 'A3')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu6') -> 'compteurs' @> '{"nouvelles": 1, "historique": 1, "personnes": 1}'::jsonb
  AND pg_temp.lu('apercu6') #> '{groupes,0}' @> '{"retenueDansLaBase": true, "retenueProposee": null}'::jsonb
  AND (SELECT l ->> 'etatFinal' FROM jsonb_array_elements(pg_temp.lu('apercu6') -> 'lignes') l LIMIT 1) = 'historique',
  'l''essai a blanc le dit : la ligne plus recente passe en historique, car celle de la base est rattachee a une candidature');
SELECT pg_temp.garde('lot6', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3b') #>> '{}', 'Classeur L3', 'A3',
      pg_temp.lu('apercu6') ->> 'jeton', '[]', 'cle-import-0007')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT etat = 'active' AND candidature_id = pg_temp.cid('c1') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A1', '2026-10-02 10:00:00'))
  AND (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('A1', '2026-10-02 10:00:00')).id
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A3', '2026-10-25 10:00:00')),
  'une ligne rattachee a une candidature n''est jamais remplacee : la plus recente passe en historique, le lien et le brouillon sont intacts');

-- Les choix de la direction : « distinctes » et la ligne retenue, gardes pour les imports suivants.
SELECT pg_temp.garde('f3c', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-27 10:00:00', 'f', 'Essai E', '+966500000380', 'e1@test.invalid'),
  pg_temp.l('2026-10-28 10:00:00', 'f', 'Essai F', '+966500000380', 'e2@test.invalid'))));
SELECT pg_temp.garde('apercu7', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f3c') #>> '{}', 'Classeur L3', 'A4')$$, 'aal2'));
SELECT pg_temp.garde('g7', to_jsonb(pg_temp.lu('apercu7') #>> '{groupes,0,id}'));
SELECT pg_temp.vrai(pg_temp.lu('apercu7') -> 'compteurs' @> '{"nouvelles": 2, "historique": 1, "personnes": 1}'::jsonb
  AND pg_temp.lu('apercu7') #> '{groupes,0}' @> '{"nature": "telephone", "lignes": [2, 3], "retenueProposee": 3, "choisi": false}'::jsonb,
  'deux femmes au meme telephone : un groupe ; par defaut la plus recente l''emporte (1 personne, 1 en historique)');
SELECT pg_temp.garde('lot7', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3c') #>> '{}', 'Classeur L3', 'A4',
      pg_temp.lu('apercu7') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g7') #>> '{}',
      'retenue', 'distinctes')), 'cle-import-0008')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('lot7') -> 'compteurs' @> '{"nouvelles": 2, "historique": 0, "personnes": 2}'::jsonb
  AND (SELECT count(*) FILTER (WHERE etat = 'active') = 2 FROM public.formulaires_reponses WHERE reference_source LIKE 'Classeur L3|A4|%')
  AND pg_temp.lu('lot7') -> 'choix' = jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g7') #>> '{}', 'retenue', 'distinctes'))
  AND (SELECT retenue = 'distinctes' AND auteur_id = pg_temp.p('d4') FROM public.formulaires_choix_doublons
        WHERE groupe = pg_temp.lu('g7') #>> '{}'),
  '« personnes distinctes » : les deux lignes restent actives (deux personnes qui partagent un telephone), le choix est trace au rapport et garde');
SELECT pg_temp.garde('imp8', to_jsonb(pg_temp.importees()));
SELECT pg_temp.garde('apercu8', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f3c') #>> '{}', 'Classeur L3', 'A4')$$, 'aal2'));
SELECT pg_temp.garde('lot8', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3c') #>> '{}', 'Classeur L3', 'A4',
      pg_temp.lu('apercu8') ->> 'jeton', '[]', 'cle-import-0009')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu8') #> '{groupes,0}' @> '{"choisi": true, "choix": "distinctes", "retenueProposee": null,
      "retenueDansLaBase": false}'::jsonb
  AND pg_temp.lu('lot8') -> 'compteurs' @> '{"nouvelles": 0, "dejaConnues": 2, "historique": 0, "personnes": 2}'::jsonb
  AND pg_temp.importees() = pg_temp.lu('imp8') #>> '{}'
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type IN ('historique', 'reactivation')
        AND reponse_id IN (SELECT id FROM public.formulaires_reponses WHERE reference_source LIKE 'Classeur L3|A4|%')) = 0,
  'le fichier corrige qui se rejoue sans choix ne defait pas la decision : le groupe est lu « choisi », les deux lignes restent actives');
-- La ligne retenue, plus ancienne que l'autre.
SELECT pg_temp.garde('f3d', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-29 10:00:00', 'f', 'Essai G', '+966500000381', 'g1x@test.invalid'),
  pg_temp.l('2026-10-30 10:00:00', 'f', 'Essai H', '+966500000381', 'h1x@test.invalid'))));
SELECT pg_temp.garde('apercu9', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f3d') #>> '{}', 'Classeur L3', 'A5')$$, 'aal2'));
SELECT pg_temp.garde('g9', to_jsonb(pg_temp.lu('apercu9') #>> '{groupes,0,id}'));
SELECT pg_temp.garde('lot9', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3d') #>> '{}', 'Classeur L3', 'A5',
      pg_temp.lu('apercu9') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g9') #>> '{}',
      'retenue', pg_temp.ref('A5', '2026-10-29 10:00:00'))), 'cle-import-0010')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT etat = 'active' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A5', '2026-10-29 10:00:00'))
  AND (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('A5', '2026-10-29 10:00:00')).id
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A5', '2026-10-30 10:00:00')),
  'la direction retient la ligne la plus ancienne : elle reste active, la plus recente passe en historique');
SELECT pg_temp.garde('imp9', to_jsonb(pg_temp.importees()));
SELECT pg_temp.garde('apercu10', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f3d') #>> '{}', 'Classeur L3', 'A5')$$, 'aal2'));
SELECT pg_temp.garde('lot10', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3d') #>> '{}', 'Classeur L3', 'A5',
      pg_temp.lu('apercu10') ->> 'jeton', '[]', 'cle-import-0011')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu10') #>> '{groupes,0,choix}' = pg_temp.ref('A5', '2026-10-29 10:00:00')
  AND pg_temp.lu('apercu10') #>> '{groupes,0,retenueProposee}' = '2'
  AND pg_temp.importees() = pg_temp.lu('imp9') #>> '{}',
  'rejoue sans choix : la ligne retenue par la direction reste la retenue (choix garde, rien ne change)');
-- La direction change d'avis : « distinctes » a son tour ; la ligne en historique est reactivee.
SELECT pg_temp.garde('lot11', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f3d') #>> '{}', 'Classeur L3', 'A5',
      pg_temp.lu('apercu10') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g9') #>> '{}',
      'retenue', 'distinctes')), 'cle-import-0012')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT etat = 'active' AND remplacee_par IS NULL FROM public.formulaires_reponses
    WHERE reference_source = pg_temp.ref('A5', '2026-10-30 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'reactivation'
        AND reponse_id = (pg_temp.rep('A5', '2026-10-30 10:00:00')).id AND lot_id = (pg_temp.lu('lot11') ->> 'lot')::uuid) = 1
  AND (SELECT retenue FROM public.formulaires_choix_doublons WHERE groupe = pg_temp.lu('g9') #>> '{}') = 'distinctes',
  'un nouveau choix remplace l''ancien : la ligne en historique est reactivee (tracee), le choix garde est celui d''aujourd''hui');

-- Une correction ne change pas le genre d'une ligne gardee pour suivi.
SELECT pg_temp.garde('f1c', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-10-13 10:00:00', 'h', 'Essai Femme Treize', '+966500000313', 'f13@test.invalid'))));
SELECT pg_temp.garde('imp10', to_jsonb(pg_temp.importees()));
SELECT pg_temp.garde('apercu11', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f1c') #>> '{}', 'Classeur L3', 'A1')$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('apercu11') -> 'compteurs' @> '{"aCorriger": 1, "corrigees": 0}'::jsonb
  AND pg_temp.lu('apercu11') #>> '{lignes,0,motifs}' = '["genre_change_sur_ligne_suivie"]'
  AND pg_temp.importees() = pg_temp.lu('imp10') #>> '{}',
  'une ligne gardee pour suivi ne change pas de genre par un fichier corrige : a corriger, rien n''est ecrit (le genre fixe la portee)');

-- ------------------------------------------------------------
-- (k) Aucune porte laissee ouverte par ailleurs ; capacites
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin', $$SELECT count(*) FROM public.formulaires_reponses$$, '42501',
  'aucune lecture directe des reponses importees (pas meme le super-admin)', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin', $$SELECT count(*) FROM public.formulaires_journal$$, '42501',
  'aucune lecture directe du journal des reponses', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('c1'), 'teacher', $$SELECT count(*) FROM public.candidat_accords_confidentialite$$, '42501',
  'aucune lecture directe des accords de confidentialite');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin', $$INSERT INTO public.formulaires_reponses (reference_source, lot_id, recue_le, genre,
  nom_affiche, contenu_empreinte) SELECT 'x|y|z', id, now(), 'male', 'Intrus', md5('x') FROM public.formulaires_lots LIMIT 1$$, '42501',
  'aucune ecriture directe des reponses importees', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(pg_temp.p('c1'), 'teacher', $$INSERT INTO public.candidat_accords_confidentialite (profile_id, version, porte)
  VALUES ('ca3b0000-0000-4000-8000-0000000000c1', '2026-10-v1', 'lien_public')$$, '42501',
  'aucune ecriture directe d''un accord de confidentialite');
SELECT pg_temp.refus_en(pg_temp.p('d4'), 'admin', $$UPDATE public.formulaires_lots SET cle = 'autre-cle-0000'$$, '42501',
  'aucune modification directe d''un lot', 'authenticated', 'aal2');
SELECT pg_temp.refus_en(NULL, NULL, $$UPDATE public.formulaires_lots SET cle = 'autre-cle-0000'$$, '55000',
  'un lot ne se modifie pas, pas meme par le proprietaire (ajout seul)', 'postgres');
SELECT pg_temp.refus_en(NULL, NULL, $$DELETE FROM public.formulaires_journal$$, '55000',
  'le journal des reponses ne s''efface pas, pas meme par le proprietaire (ajout seul)', 'postgres');
SELECT pg_temp.refus_en(NULL, NULL, $$UPDATE public.candidat_accords_confidentialite SET version = '2026-11-v2'$$, '55000',
  'un accord de confidentialite ne se modifie pas (ajout seul)', 'postgres');
-- La porte fermee le 17/10 reste fermee par l'ancienne voie.
SELECT pg_temp.u('d6', 'cand-l3-d6@test.invalid');
SELECT pg_temp.refus_en(pg_temp.p('d6'), NULL, $$SELECT public.creer_profil_inscription('teacher', 'Essai', 'Ancienne', 'female')$$,
  '23514', 'creer_profil_inscription refuse toujours le role teacher : la seule porte est inscrire_candidat (ou l''invitation)');
-- Une direction (qui a deja un profil) ne s'inscrit pas comme candidate.
SELECT pg_temp.refus_en(pg_temp.p('d1'), 'admin',
  $$SELECT public.inscrire_candidat(NULL, 'Essai', 'Direction', 'male', '+966500000999', 'fr', '2026-10-v1')$$, '42501',
  'un compte qui a deja un profil (la direction) ne s''inscrit pas comme candidat');

SELECT pg_temp.garde('cap_s2', pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.capacites_candidatures()$$, 'aal2'));
SELECT pg_temp.garde('cap_s1', pg_temp.en(pg_temp.p('d4'), 'admin', $$SELECT public.capacites_candidatures()$$, 'aal1'));
SELECT pg_temp.garde('cap_h2', pg_temp.en(pg_temp.p('d1'), 'admin', $$SELECT public.capacites_candidatures()$$, 'aal2'));
SELECT pg_temp.garde('cap_f2', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.capacites_candidatures()$$, 'aal2'));
SELECT pg_temp.garde('cap_u2', pg_temp.en(pg_temp.p('d3'), 'admin', $$SELECT public.capacites_candidatures()$$, 'aal2'));
SELECT pg_temp.garde('cap_t2', pg_temp.en(pg_temp.p('a1'), 'guardian', $$SELECT public.capacites_candidatures()$$, 'aal2'));
SELECT pg_temp.vrai(pg_temp.lu('cap_s2') @> '{"peutImporter": true, "doubleVerificationRequise": false, "peutDecider": true}'::jsonb
  AND pg_temp.lu('cap_s1') @> '{"peutImporter": false, "doubleVerificationRequise": true, "peutDecider": true}'::jsonb
  AND pg_temp.lu('cap_h2') @> '{"peutImporter": false, "doubleVerificationRequise": false, "peutDecider": true}'::jsonb
  AND pg_temp.lu('cap_f2') @> '{"peutImporter": false, "doubleVerificationRequise": false, "peutDecider": true}'::jsonb
  AND pg_temp.lu('cap_u2') @> '{"peutImporter": false, "doubleVerificationRequise": false, "peutDecider": false}'::jsonb
  AND pg_temp.lu('cap_t2') @> '{"peutImporter": false, "doubleVerificationRequise": false, "peutDecider": false}'::jsonb,
  'capacites : l''import est celui du super-admin en aal2 (en aal1 la double verification est demandee), jamais d''une autre direction ni d''un autre role');
SELECT pg_temp.vrai(pg_temp.lu('cap_f2') -> 'gestes' @> '{"garderPourSuivi": true, "consignerPrevenu": true, "rattacher": true, "inviter": false}'::jsonb
  AND pg_temp.lu('cap_f2') -> 'listes' @> '{"canauxPrevenu": ["whatsapp"], "modelesPrevenu": ["lien_inscription"]}'::jsonb
  AND NOT EXISTS (SELECT 1 FROM jsonb_each(pg_temp.lu('cap_u2') -> 'gestes') g WHERE g.value <> 'false'::jsonb)
  AND pg_temp.lu('cap_u2') #> '{listes,canauxPrevenu}' = '[]'::jsonb AND pg_temp.lu('cap_u2') #> '{listes,modelesPrevenu}' = '[]'::jsonb
  AND NOT EXISTS (SELECT 1 FROM jsonb_each(pg_temp.lu('cap_t2') -> 'gestes') g WHERE g.value <> 'false'::jsonb),
  'capacites : garder pour suivi, consigner prevenu et rattacher pour la direction de son cote, avec leurs listes fermees ; inviter reste faux (L5) ; rien pour le genre inconnu ni le tuteur');

-- ------------------------------------------------------------
-- (l) Deux lignes actives au meme courriel : une ligne gardee pour suivi n'est
-- jamais mise en historique, et un courriel porte par deux lignes ne relie rien
-- ------------------------------------------------------------
-- La direction retient la ligne la plus recente d'un groupe dont l'autre est gardee pour suivi.
SELECT pg_temp.garde('f4a', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-11-02 10:00:00', 'h', 'Essai Pin Un', '+966500000501', 'pin@test.invalid'))));
SELECT pg_temp.garde('apercu12', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f4a') #>> '{}', 'Classeur L3', 'A6')$$, 'aal2'));
SELECT pg_temp.garde('lot12', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f4a') #>> '{}', 'Classeur L3', 'A6',
      pg_temp.lu('apercu12') ->> 'jeton', '[]', 'cle-import-0013')$$, 'aal2'));
SELECT pg_temp.garde('ligne_pin', to_jsonb((pg_temp.rep('A6', '2026-11-02 10:00:00')).id));
SELECT pg_temp.garde('suivi_pin', pg_temp.en(pg_temp.p('d1'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('ligne_pin') #>> '{}')::uuid)$$));
SELECT pg_temp.vrai(pg_temp.lu('suivi_pin') ->> 'rejoue' = 'false'
  AND (SELECT suivi_id IS NOT NULL AND etat = 'active' FROM public.formulaires_reponses
        WHERE reference_source = pg_temp.ref('A6', '2026-11-02 10:00:00')),
  'fixture : la premiere ligne d''un futur groupe est gardee pour suivi (candidature recue, ligne active)');
SELECT pg_temp.garde('f4b', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-11-03 10:00:00', 'h', 'Essai Pin Deux', '+966500000502', 'pin@test.invalid'))));
SELECT pg_temp.garde('apercu13', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f4b') #>> '{}', 'Classeur L3', 'A7')$$, 'aal2'));
SELECT pg_temp.garde('g13', to_jsonb(pg_temp.lu('apercu13') #>> '{groupes,0,id}'));
SELECT pg_temp.vrai(pg_temp.lu('apercu13') #> '{groupes,0}' @> '{"nature": "courriel", "taille": 2, "retenueDansLaBase": true}'::jsonb,
  'le groupe que forment la ligne suivie et la nouvelle (meme courriel) est vu : la ligne de la base est la retenue par defaut');
SELECT pg_temp.garde('lot13', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f4b') #>> '{}', 'Classeur L3', 'A7',
      pg_temp.lu('apercu13') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g13') #>> '{}',
      'retenue', pg_temp.ref('A7', '2026-11-03 10:00:00'))), 'cle-import-0014')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT etat = 'active' AND remplacee_par IS NULL AND suivi_id IS NOT NULL FROM public.formulaires_reponses
    WHERE reference_source = pg_temp.ref('A6', '2026-11-02 10:00:00'))
  AND (SELECT etat = 'active' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A7', '2026-11-03 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_journal WHERE type = 'historique'
        AND reponse_id = (pg_temp.rep('A6', '2026-11-02 10:00:00')).id) = 0,
  'la direction retient l''autre ligne : celle gardee pour suivi n''est jamais mise en historique, les deux restent actives');

-- Un courriel porte par deux lignes actives du meme cote (deux personnes) ne relie rien.
SELECT pg_temp.garde('f4c', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-11-04 10:00:00', 'h', 'Essai Boite Un', '+966500000503', 'boite@test.invalid'),
  pg_temp.l('2026-11-05 10:00:00', 'h', 'Essai Boite Deux', '+966500000504', 'boite@test.invalid'))));
SELECT pg_temp.garde('apercu14', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f4c') #>> '{}', 'Classeur L3', 'A8')$$, 'aal2'));
SELECT pg_temp.garde('g14', to_jsonb(pg_temp.lu('apercu14') #>> '{groupes,0,id}'));
SELECT pg_temp.garde('lot14', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f4c') #>> '{}', 'Classeur L3', 'A8',
      pg_temp.lu('apercu14') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g14') #>> '{}',
      'retenue', 'distinctes')), 'cle-import-0015')$$, 'aal2'));
SELECT pg_temp.vrai((SELECT count(*) FROM public.formulaires_reponses
        WHERE reference_source LIKE 'Classeur L3|A8|%' AND etat = 'active' AND courriel = 'boite@test.invalid') = 2,
  'fixture : deux personnes distinctes au meme courriel, les deux lignes actives');
SELECT pg_temp.garde('avant14', pg_temp.ecritures());
SELECT pg_temp.garde('i_boite', pg_temp.inscrit('ca', 'boite@test.invalid', 'Essai', 'CandidatBoite', 'male', '+966500000505'));
SELECT pg_temp.vrai(pg_temp.lu('i_boite') = '{"resultat": "acceptee"}'::jsonb
  AND pg_temp.cid('ca') IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE candidature_id = pg_temp.cid('ca'))
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = pg_temp.cid('ca')) = 0
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('ca')) = 0
  AND (pg_temp.ecritures() ->> 'candidatures')::int = (pg_temp.lu('avant14') ->> 'candidatures')::int + 1,
  'un courriel confirme porte par deux lignes actives du meme cote : la personne est inscrite, aucune ligne n''est choisie a sa place (0 lien, 0 pre-remplissage)');

-- ------------------------------------------------------------
-- (m) Reprise apres relecture (23/10) : une proposition ne survit pas aux
-- donnees sur lesquelles elle repose, une ligne redevenue active se
-- rapproche, une ligne de suivi retiree n'est pas reprise, et rien n'est
-- montre selon ce que la base connait deja d'un courriel ou d'un telephone
-- ------------------------------------------------------------
-- Import complet (essai a blanc puis confirmation) par le super-admin en aal2.
CREATE FUNCTION pg_temp.importer(p_csv text, p_onglet text, p_cle text, p_choix jsonb DEFAULT '[]') RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v_ap jsonb;
BEGIN
  v_ap := pg_temp.en(pg_temp.p('d4'), 'admin', pg_catalog.format(
    'SELECT public.apercu_import_formulaires(%L, %L, %L)', p_csv, 'Classeur L3', p_onglet), 'aal2');
  RETURN pg_temp.en(pg_temp.p('d4'), 'admin', pg_catalog.format(
    'SELECT public.confirmer_import_formulaires(%L, %L, %L, %L, %L::jsonb, %L)',
    p_csv, 'Classeur L3', p_onglet, v_ap ->> 'jeton', p_choix::text, p_cle), 'aal2');
END $$;
-- Les noms de reponse que la direction (ou le super-admin) lit dans ses propositions.
CREATE FUNCTION pg_temp.noms_proposes(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(l #>> '{reponse,nomComplet}' ORDER BY l #>> '{reponse,nomComplet}'), ARRAY[]::text[])
    FROM jsonb_array_elements(pg_temp.en(p_id, p_role, $q$SELECT public.lister_rapprochements_candidats(1)$q$, p_aal) -> 'lignes') l
$$;
GRANT EXECUTE ON FUNCTION pg_temp.importer(text, text, text, jsonb), pg_temp.noms_proposes(uuid, text, text)
  TO authenticated, anon;

-- m1 : le genre d'une ligne corrigee dans le classeur apres une proposition. La
-- proposition ne rend jamais a un cote le nom d'une ligne de l'autre cote.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-01 10:00:00', 'f', 'Essai Femme Devenue Homme', '+966500000701', '')), 'A9', 'cle-rev-0001');
SELECT pg_temp.inscrit('f1', 'cand-l3-g1@test.invalid', 'Essai', 'CandidateMg1', 'female', '+966500000701');
SELECT pg_temp.garde('g1_ligne', to_jsonb((pg_temp.rep('A9', '2026-12-01 10:00:00')).id));
SELECT pg_temp.vrai(
  pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Devenue Homme']
  AND pg_temp.noms_proposes(pg_temp.p('d1'), 'admin') <> ARRAY['Essai Femme Devenue Homme']
  AND NOT pg_temp.noms_proposes(pg_temp.p('d1'), 'admin') @> ARRAY['Essai Femme Devenue Homme'],
  'm1 : la proposition par telephone est lue par la directrice, pas par la direction des hommes (avant la correction)');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-01 10:00:00', 'h', 'Essai Femme Devenue Homme', '+966500000701', '')), 'A9', 'cle-rev-0002');
SELECT pg_temp.vrai(
  (SELECT genre = 'male' AND etat = 'active' AND candidature_id IS NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A9', '2026-12-01 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('f1')) = 1
  AND NOT pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Devenue Homme']
  AND NOT pg_temp.noms_proposes(pg_temp.p('d1'), 'admin') @> ARRAY['Essai Femme Devenue Homme']
  AND NOT pg_temp.noms_proposes(pg_temp.p('d4'), 'admin', 'aal2') @> ARRAY['Essai Femme Devenue Homme'],
  'm1 : la ligne corrigee passe du cote des hommes : sa proposition (toujours en base) n''est plus lue par la directrice, ni par la direction des hommes (la candidate est une femme), ni par le super-admin');
SELECT pg_temp.garde('g1_cand', to_jsonb(pg_temp.cid('f1')));
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('g1_cand') #>> '{}')::uuid,
      (pg_temp.lu('g1_ligne') #>> '{}')::uuid, 1, 'cle-rev-ratt-1')$$) = '{"erreur": "proposition_inconnue"}'::jsonb
  AND (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE id = (pg_temp.lu('g1_ligne') #>> '{}')::uuid),
  'm1 : rattacher refuse la proposition d''une ligne passee de l''autre cote, rien n''est relie');

-- m2 : le telephone d'une ligne corrigee apres une proposition.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-02 10:00:00', 'f', 'Essai Femme Telephone Change', '+966500000702', '')), 'A10', 'cle-rev-0003');
SELECT pg_temp.inscrit('f2', 'cand-l3-g2@test.invalid', 'Essai', 'CandidateMg2', 'female', '+966500000702');
SELECT pg_temp.garde('g2_ligne', to_jsonb((pg_temp.rep('A10', '2026-12-02 10:00:00')).id));
SELECT pg_temp.garde('g2_cand', to_jsonb(pg_temp.cid('f2')));
SELECT pg_temp.vrai(pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Telephone Change'],
  'm2 : le telephone partage fait une proposition lue par la directrice');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-02 10:00:00', 'f', 'Essai Femme Telephone Change', '+966500000799', '')), 'A10', 'cle-rev-0004');
SELECT pg_temp.vrai(
  (SELECT telephone = '+966500000799' FROM public.formulaires_reponses WHERE id = (pg_temp.lu('g2_ligne') #>> '{}')::uuid)
  AND NOT pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Telephone Change']
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('g2_cand') #>> '{}')::uuid,
      (pg_temp.lu('g2_ligne') #>> '{}')::uuid, 1, 'cle-rev-ratt-2')$$) = '{"erreur": "proposition_inconnue"}'::jsonb
  AND (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE id = (pg_temp.lu('g2_ligne') #>> '{}')::uuid),
  'm2 : le telephone de la ligne a change dans le classeur : la proposition ne se lit plus et ne s''applique plus');

-- m3 : une candidature deja reliee a une ligne ne se voit pas proposer une autre ligne (la proposition
-- ne pourrait pas s'appliquer) ; et une proposition faite avant le lien ne se lit plus une fois la candidature reliee.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-03 10:00:00', 'f', 'Essai Femme Courriel Trois', '+966500000703', 'cand-l3-g3@test.invalid'),
  pg_temp.l('2026-12-03 11:00:00', 'f', 'Essai Femme Telephone Trois', '+966500000704', 'g3autre@test.invalid')), 'A11', 'cle-rev-0005');
SELECT pg_temp.inscrit('f3', 'cand-l3-g3@test.invalid', 'Essai', 'CandidateMg3', 'female', '+966500000704');
SELECT pg_temp.vrai(
  (SELECT candidature_id = pg_temp.cid('f3') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A11', '2026-12-03 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('f3')) = 0
  AND NOT pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Telephone Trois'],
  'm3 : la candidature reliee par son courriel ne recoit aucune proposition pour une autre ligne du meme telephone (elle ne pourrait pas s''appliquer)');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-05 10:00:00', 'f', 'Essai Femme Proposee Avant', '+966500000715', 'x715@test.invalid')), 'A15', 'cle-rev-0013');
SELECT pg_temp.inscrit('fa', 'cand-l3-g6@test.invalid', 'Essai', 'CandidateMg6', 'female', '+966500000715');
SELECT pg_temp.garde('g6_cand', to_jsonb(pg_temp.cid('fa')));
SELECT pg_temp.garde('g6_ligne_x', to_jsonb((pg_temp.rep('A15', '2026-12-05 10:00:00')).id));
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('fa')) = 1
  AND pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Proposee Avant'],
  'm3 : fixture : la candidate a une proposition par telephone, lue par la directrice');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-05 11:00:00', 'f', 'Essai Femme Courriel Apres', '+966500000716', 'cand-l3-g6@test.invalid')), 'A16', 'cle-rev-0014');
SELECT pg_temp.vrai(
  (SELECT candidature_id = pg_temp.cid('fa') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A16', '2026-12-05 11:00:00'))
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('fa')) = 1
  AND NOT pg_temp.noms_proposes(pg_temp.p('d2'), 'admin') @> ARRAY['Essai Femme Proposee Avant']
  AND pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.rattacher_formulaire_candidat((pg_temp.lu('g6_cand') #>> '{}')::uuid,
      (pg_temp.lu('g6_ligne_x') #>> '{}')::uuid, 1, 'cle-rev-ratt-3')$$) = '{"erreur": "candidature_deja_rattachee"}'::jsonb,
  'm3 : une ligne importee ensuite relie la candidate par son courriel : la proposition faite avant (toujours en base) ne se lit plus et se refuse (candidature_deja_rattachee)');

-- m4 : une ligne de suivi retiree n'est pas reprise : la personne qui s'inscrit a ce courriel a une
-- candidature neuve, la ligne retiree reste retiree, sans compte.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-04 10:00:00', 'f', 'Essai Femme Suivie Retiree', '+966500000705', 'cand-l3-g4@test.invalid')), 'A12', 'cle-rev-0006');
SELECT pg_temp.garde('g4_row', to_jsonb((pg_temp.rep('A12', '2026-12-04 10:00:00')).id));
SELECT pg_temp.garde('g4_suivi', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('g4_row') #>> '{}')::uuid)$$));
SELECT pg_temp.garde('g4_ligne', to_jsonb(pg_temp.lu('g4_suivi') #>> '{candidature,id}'));
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('d2'), 'admin', pg_catalog.format($q$SELECT public.consigner_retrait_candidat(%L::uuid, 'courriel', current_date,
    'Retrait demande par la personne', 1, 'cle-rev-ret-1')$q$, pg_temp.lu('g4_ligne') #>> '{}')) #>> '{candidature,issue}' = 'retiree',
  'm4 : fixture : la ligne gardee pour suivi est retiree par la direction');
SELECT pg_temp.garde('avant_g4', pg_temp.ecritures());
SELECT pg_temp.inscrit('f4', 'cand-l3-g4@test.invalid', 'Essai', 'CandidateMg4', 'female', '+966500000706');
SELECT pg_temp.vrai(
  pg_temp.cid('f4') IS NOT NULL AND pg_temp.cid('f4') <> (pg_temp.lu('g4_ligne') #>> '{}')::uuid
  AND (SELECT issue = 'retiree' AND profile_id IS NULL AND etape = 'recue'
         FROM public.candidatures WHERE id = (pg_temp.lu('g4_ligne') #>> '{}')::uuid)
  AND (SELECT etape = 'prequalification' AND etat = 'a_completer' AND issue = 'en_cours'
         FROM public.candidatures WHERE id = pg_temp.cid('f4'))
  AND (pg_temp.ecritures() ->> 'candidatures')::int = (pg_temp.lu('avant_g4') ->> 'candidatures')::int + 1
  AND (SELECT candidature_id = pg_temp.cid('f4') AND rattachement = 'courriel'
         FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A12', '2026-12-04 10:00:00')),
  'm4 : la ligne de suivi retiree n''est pas reprise (elle reste retiree, sans compte) : candidature neuve, et la reponse importee est reliee a la candidature neuve');

-- m5 : une ligne redevenue active par un choix de la direction se rapproche de la personne deja inscrite.
SELECT pg_temp.garde('f5', to_jsonb(pg_temp.csv(
  pg_temp.l('2026-12-10 10:00:00', 'h', 'Essai Homme Ancien', '+966500000707', 'cand-l3-g5@test.invalid'),
  pg_temp.l('2026-12-11 10:00:00', 'h', 'Essai Homme Recent', '+966500000707', 'g5autre@test.invalid'))));
SELECT pg_temp.importer(pg_temp.lu('f5') #>> '{}', 'A13', 'cle-rev-0007');
SELECT pg_temp.inscrit('f5', 'cand-l3-g5@test.invalid', 'Essai', 'CandidatMg5', 'male', '+966500000708');
SELECT pg_temp.vrai(
  (SELECT etat = 'historique' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A13', '2026-12-10 10:00:00'))
  AND (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A13', '2026-12-10 10:00:00'))
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE candidature_id = pg_temp.cid('f5')),
  'm5 : fixture : la ligne la plus ancienne est en historique, la personne s''inscrit a son courriel : rien n''est relie (une ligne en historique ne relie pas)');
SELECT pg_temp.garde('g5_ap', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f5') #>> '{}', 'Classeur L3', 'A13')$$, 'aal2'));
SELECT pg_temp.garde('g5_lot', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f5') #>> '{}', 'Classeur L3', 'A13',
      pg_temp.lu('g5_ap') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('g5_ap') #>> '{groupes,0,id}',
      'retenue', 'distinctes')), 'cle-rev-0008')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT etat = 'active' AND candidature_id = pg_temp.cid('f5') AND rattachement = 'courriel'
          AND prerempli_champs IS NOT NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A13', '2026-12-10 10:00:00'))
  AND (SELECT r.reponses ?& ARRAY['languesExplication', 'niveauMemorisationDeclare'] AND r.brouillon
         FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.cid('f5')),
  'm5 : « personnes distinctes » reactive la ligne ancienne : elle est reliee a la personne deja inscrite (courriel) et pre-remplit, comme une ligne neuve');

-- m6 : rien n'est montre a la personne selon ce que la base connait deja de son courriel ou de son telephone.
-- Quatre inscrites (femmes) : courriel et telephone connus, courriel seul, telephone seul, aucun.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-20 10:00:00', 'f', 'Essai Femme Les Deux', '+966500000711', 'cand-l3-h1@test.invalid'),
  pg_temp.l('2026-12-20 11:00:00', 'f', 'Essai Femme Courriel Seul', '+966500000712', 'cand-l3-h2@test.invalid'),
  pg_temp.l('2026-12-20 12:00:00', 'f', 'Essai Femme Telephone Seul', '+966500000713', 'h3autre@test.invalid')), 'A14', 'cle-rev-0009');
SELECT pg_temp.garde('h_deux', pg_temp.inscrit('f6', 'cand-l3-h1@test.invalid', 'Essai', 'CandidateMh1', 'female', '+966500000711'));
SELECT pg_temp.garde('h_mail', pg_temp.inscrit('f7', 'cand-l3-h2@test.invalid', 'Essai', 'CandidateMh2', 'female', '+966500000722'));
SELECT pg_temp.garde('h_tel', pg_temp.inscrit('f8', 'cand-l3-h3@test.invalid', 'Essai', 'CandidateMh3', 'female', '+966500000713'));
SELECT pg_temp.garde('h_rien', pg_temp.inscrit('f9', 'cand-l3-h4@test.invalid', 'Essai', 'CandidateMh4', 'female', '+966500000744'));
SELECT pg_temp.vrai(
  pg_temp.lu('h_deux') = '{"resultat": "acceptee"}'::jsonb AND pg_temp.lu('h_mail') = pg_temp.lu('h_deux')
  AND pg_temp.lu('h_tel') = pg_temp.lu('h_deux') AND pg_temp.lu('h_rien') = pg_temp.lu('h_deux'),
  'L3-17 : la reponse est la meme que le courriel ou le telephone soit connu, ou non, de la base (4 cas : les deux, courriel seul, telephone seul, aucun)');
SELECT pg_temp.garde('et_tel', pg_temp.en(pg_temp.p('f8'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.garde('et_rien', pg_temp.en(pg_temp.p('f9'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.garde('qu_tel', pg_temp.en(pg_temp.p('f8'), 'teacher', $$SELECT public.questionnaire_salle_examen()$$));
SELECT pg_temp.garde('qu_rien', pg_temp.en(pg_temp.p('f9'), 'teacher', $$SELECT public.questionnaire_salle_examen()$$));
SELECT pg_temp.vrai(
  (pg_temp.lu('et_tel') -> 'candidature') - 'reference' = (pg_temp.lu('et_rien') -> 'candidature') - 'reference'
  AND pg_temp.lu('qu_tel') = pg_temp.lu('qu_rien')
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('f8')) = 1
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('f9')) = 0
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses WHERE candidature_id IN (pg_temp.cid('f8'), pg_temp.cid('f9')))
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id IN (pg_temp.cid('f8'), pg_temp.cid('f9'))) = 0,
  'L3-12 / L3-17 : une inscrite dont le telephone seul est connu voit EXACTEMENT ce que voit une inscrite dont rien n''est connu (etat du dossier, questionnaire, brouillon) ; seule la direction a une proposition');
SELECT pg_temp.vrai(
  (SELECT candidature_id = pg_temp.cid('f6') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A14', '2026-12-20 10:00:00'))
  AND (SELECT candidature_id = pg_temp.cid('f7') AND rattachement = 'courriel'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A14', '2026-12-20 11:00:00'))
  AND (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('A14', '2026-12-20 12:00:00')),
  'les quatre cas ont bien eu des suites differentes cote serveur (deux liens par courriel, une proposition, rien) : le meme resultat rendu n''est pas un faux accord');

-- m7 : rejouer le meme fichier ne defait pas un groupe qui ne tient que par une ligne d'un autre fichier.
-- D (fichier B1) partage le courriel de F1 et le telephone de F2 (fichier B2) ; F1 et F2 ne partagent rien.
-- Le premier import de B2 met D et F1 en historique ; si D ne comptait plus au second, F1 et F2 se
-- croiraient seules et F1 redeviendrait active.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-01-01 10:00:00', 'f', 'Essai Femme Pont', '+966500000801', 'cand-l3-pont@test.invalid')), 'B1', 'cle-rev-0010');
SELECT pg_temp.garde('f_b2', to_jsonb(pg_temp.csv(
  pg_temp.l('2027-01-02 10:00:00', 'f', 'Essai Femme Un Pont', '+966500000802', 'cand-l3-pont@test.invalid'),
  pg_temp.l('2027-01-03 10:00:00', 'f', 'Essai Femme Deux Pont', '+966500000801', 'cand-l3-pont2@test.invalid'))));
SELECT pg_temp.importer(pg_temp.lu('f_b2') #>> '{}', 'B2', 'cle-rev-0011');
SELECT pg_temp.vrai(
  (SELECT etat = 'historique' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('B1', '2027-01-01 10:00:00'))
  AND (SELECT etat = 'historique' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('B2', '2027-01-02 10:00:00'))
  AND (SELECT etat = 'active' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('B2', '2027-01-03 10:00:00')),
  'm7 : fixture : trois lignes reliees de proche en proche par une ligne d''un autre fichier : la plus recente seule reste active');
SELECT pg_temp.garde('imp_b2', to_jsonb(pg_temp.importees()));
SELECT pg_temp.garde('journal_b2', to_jsonb((SELECT count(*) FROM public.formulaires_journal)));
SELECT pg_temp.garde('lot_b2', pg_temp.importer(pg_temp.lu('f_b2') #>> '{}', 'B2', 'cle-rev-0012'));
SELECT pg_temp.vrai(
  pg_temp.importees() = pg_temp.lu('imp_b2') #>> '{}'
  AND pg_temp.lu('lot_b2') -> 'compteurs' @> '{"nouvelles": 0, "corrigees": 0, "dejaConnues": 2, "historique": 0}'::jsonb
  AND (SELECT etat = 'historique' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('B2', '2027-01-02 10:00:00'))
  AND (SELECT count(*) FROM public.formulaires_journal) = (pg_temp.lu('journal_b2') #>> '{}')::bigint
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_journal WHERE type = 'reactivation'
        AND reponse_id IN (SELECT id FROM public.formulaires_reponses WHERE reference_source LIKE 'Classeur L3|B_|%')),
  'm7 : le meme fichier rejoue sous une autre cle ne change rien : la ligne en historique y reste, aucune reactivation, aucune ligne de journal de plus');

-- m8 : l'accord de contact par WhatsApp de la personne se montre a la direction qui va la prevenir :
-- jamais perdu dans la reponse importee, jamais rendu avec son numero.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2026-12-21 10:00:00', 'f', 'Essai Femme Avec Accord', '+966500000717', ''),
  replace(pg_temp.l('2026-12-21 11:00:00', 'f', 'Essai Femme Sans Accord', '+966500000718', ''), 'أوافق', '')), 'A17', 'cle-rev-0015');
SELECT pg_temp.garde('m8_a', to_jsonb((pg_temp.rep('A17', '2026-12-21 10:00:00')).id));
SELECT pg_temp.garde('m8_s', to_jsonb((pg_temp.rep('A17', '2026-12-21 11:00:00')).id));
SELECT pg_temp.vrai(
  (SELECT consentement_whatsapp FROM public.formulaires_reponses WHERE id = (pg_temp.lu('m8_a') #>> '{}')::uuid)
  AND NOT (SELECT consentement_whatsapp FROM public.formulaires_reponses WHERE id = (pg_temp.lu('m8_s') #>> '{}')::uuid),
  'm8 : fixture : l''import garde l''accord de chaque personne (vrai pour l''une, faux pour l''autre)');
SELECT pg_temp.garde('m8_ka', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('m8_a') #>> '{}')::uuid)$$));
SELECT pg_temp.garde('m8_ks', pg_temp.en(pg_temp.p('d2'), 'admin',
  $$SELECT public.garder_formulaire_pour_suivi((pg_temp.lu('m8_s') #>> '{}')::uuid)$$));
SELECT pg_temp.garde('m8_liste', pg_temp.en(pg_temp.p('d2'), 'admin', $$SELECT public.lister_a_prevenir_candidats(false, 1)$$));
SELECT pg_temp.vrai(
  (SELECT l ->> 'accordWhatsapp' FROM jsonb_array_elements(pg_temp.lu('m8_liste') -> 'lignes') l
    WHERE l ->> 'id' = pg_temp.lu('m8_ka') #>> '{candidature,id}') = 'true'
  AND (SELECT l ->> 'accordWhatsapp' FROM jsonb_array_elements(pg_temp.lu('m8_liste') -> 'lignes') l
    WHERE l ->> 'id' = pg_temp.lu('m8_ks') #>> '{candidature,id}') = 'false'
  AND pg_temp.lu('m8_liste')::text !~ '9665000|test\.invalid',
  'm8 : la liste des personnes a prevenir montre l''accord WhatsApp de chacune (vrai, faux), sans son numero ni son courriel');

-- m9 : un groupe se forme de proche en proche, sur plusieurs rangs. D1 et D2 (deux personnes distinctes
-- au meme telephone, choix de la direction) restent actives ; un fichier ulterieur ne touche que D1 (son
-- courriel) : D2, qui ne tient que par D1, passe en historique avec lui, la plus recente seule reste active.
SELECT pg_temp.garde('f_c1', to_jsonb(pg_temp.csv(
  pg_temp.l('2027-02-01 10:00:00', 'f', 'Essai Femme D Deux', '+966500000811', 'cand-l3-d2@test.invalid'),
  pg_temp.l('2027-02-02 10:00:00', 'f', 'Essai Femme D Un', '+966500000811', 'cand-l3-d1@test.invalid'))));
SELECT pg_temp.garde('ap_c1', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f_c1') #>> '{}', 'Classeur L3', 'C1')$$, 'aal2'));
SELECT pg_temp.garde('lot_c1', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f_c1') #>> '{}', 'Classeur L3', 'C1',
      pg_temp.lu('ap_c1') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('ap_c1') #>> '{groupes,0,id}',
      'retenue', 'distinctes')), 'cle-rev-0016')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.formulaires_reponses WHERE reference_source LIKE 'Classeur L3|C1|%' AND etat = 'active') = 2,
  'm9 : fixture : deux personnes distinctes au meme telephone, les deux lignes actives');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-02-03 10:00:00', 'f', 'Essai Femme D Trois', '+966500000812', 'cand-l3-d1@test.invalid')), 'C2', 'cle-rev-0017');
SELECT pg_temp.vrai(
  (SELECT etat = 'active' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('C2', '2027-02-03 10:00:00'))
  AND (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('C2', '2027-02-03 10:00:00')).id
         FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('C1', '2027-02-02 10:00:00'))
  AND (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('C2', '2027-02-03 10:00:00')).id
         FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('C1', '2027-02-01 10:00:00')),
  'm9 : le groupe se forme sur deux rangs (la nouvelle ligne touche D1, D1 touche D2) : D1 et D2 passent en historique, remplacees par la plus recente');

-- m10 : deux candidatures qui portent le meme courriel de contact (la premiere personne a change d'adresse
-- de connexion, une seconde s'est inscrite a l'adresse devenue libre) : une ligne importee a ce courriel ne
-- se rattache a aucune des deux (jamais un choix entre deux personnes). C'est le cas que le mutant
-- « plusieurs candidatures » de la contre-epreuve atteint ; auth.users ne l'interdit pas.
SELECT pg_temp.inscrit('fb', 'cand-l3-m10@test.invalid', 'Essai', 'AncienneAdresse', 'female', '+966500000721');
UPDATE auth.users SET email = 'cand-l3-m10-nouvelle@test.invalid' WHERE id = pg_temp.p('fb');
SELECT pg_temp.inscrit('fc', 'cand-l3-m10@test.invalid', 'Essai', 'NouvelleInscrite', 'female', '+966500000722');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_contacts k WHERE k.courriel = 'cand-l3-m10@test.invalid') = 2,
  'm10 : fixture : deux candidatures portent le meme courriel de contact');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-03-01 10:00:00', 'f', 'Essai Femme Deux Adresses', '+966500000723', 'cand-l3-m10@test.invalid')), 'D1', 'cle-rev-0018');
SELECT pg_temp.vrai(
  (SELECT candidature_id IS NULL FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('D1', '2027-03-01 10:00:00'))
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id IN (pg_temp.cid('fb'), pg_temp.cid('fc'))) = 0
  AND (SELECT count(*) FROM public.formulaires_rapprochements WHERE candidature_id IN (pg_temp.cid('fb'), pg_temp.cid('fc'))) = 0,
  'm10 : un courriel porte par deux candidatures ne relie la ligne importee a aucune des deux : ni lien, ni brouillon, ni proposition');

-- m11 : une ligne corrigee quitte son groupe, et ses voisins, qui ne sont pas dans le fichier rejoue, en
-- sortent aussi. Deux onglets : la ligne de E2 (la plus recente) met celle de E1 en historique ; le
-- courriel de E2 est ensuite corrige dans le classeur. Sans cela, E1 resterait « remplacee » par une
-- ligne qui ne lui ressemble plus : la personne ne serait ni rapprochee ni a prevenir.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-04-01 10:00:00', 'f', 'Essai Femme Voisine Un', '+966500001101', 'cand-l3-n1@test.invalid')), 'E1', 'cle-rev-0019');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-04-02 10:00:00', 'f', 'Essai Femme Voisine Deux', '+966500001102', 'cand-l3-n1@test.invalid')), 'E2', 'cle-rev-0020');
SELECT pg_temp.vrai(
  (SELECT etat = 'historique' AND remplacee_par = (pg_temp.rep('E2', '2027-04-02 10:00:00')).id
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E1', '2027-04-01 10:00:00'))
  AND (SELECT etat = 'active' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E2', '2027-04-02 10:00:00')),
  'm11 : fixture : le meme courriel dans deux onglets, la plus recente reste active');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-04-02 10:00:00', 'f', 'Essai Femme Voisine Deux', '+966500001102', 'cand-l3-n2@test.invalid')), 'E2', 'cle-rev-0021');
SELECT pg_temp.vrai(
  (SELECT etat = 'active' AND remplacee_par IS NULL
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E1', '2027-04-01 10:00:00'))
  AND (SELECT etat = 'active' AND courriel = 'cand-l3-n2@test.invalid'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E2', '2027-04-02 10:00:00'))
  AND EXISTS (SELECT 1 FROM public.formulaires_journal j
               WHERE j.type = 'reactivation' AND j.reponse_id = (pg_temp.rep('E1', '2027-04-01 10:00:00')).id),
  'm11 : le courriel de la ligne corrigee ne les relie plus : la voisine, absente du fichier, sort de l''historique (reactivation tracee)');

-- m12 : une ligne corrigee passe de l'autre cote (le genre est corrige dans le classeur) : sa voisine, de
-- l'ancien cote, redevient active ; aucune ligne n'est jamais « remplacee » par une ligne de l'autre cote.
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-05-01 10:00:00', 'f', 'Essai Femme Voisine Trois', '+966500001103', 'cand-l3-n3@test.invalid')), 'E3', 'cle-rev-0022');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-05-02 10:00:00', 'f', 'Essai Femme Voisine Quatre', '+966500001104', 'cand-l3-n3@test.invalid')), 'E4', 'cle-rev-0023');
SELECT pg_temp.vrai(
  (SELECT etat = 'historique' FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E3', '2027-05-01 10:00:00')),
  'm12 : fixture : la plus ancienne des deux lignes est en historique');
SELECT pg_temp.importer(pg_temp.csv(
  pg_temp.l('2027-05-02 10:00:00', 'h', 'Essai Homme Voisin Quatre', '+966500001104', 'cand-l3-n3@test.invalid')), 'E4', 'cle-rev-0024');
SELECT pg_temp.vrai(
  (SELECT etat = 'active' AND remplacee_par IS NULL AND genre = 'female'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E3', '2027-05-01 10:00:00'))
  AND (SELECT etat = 'active' AND genre = 'male'
     FROM public.formulaires_reponses WHERE reference_source = pg_temp.ref('E4', '2027-05-02 10:00:00'))
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses a JOIN public.formulaires_reponses b ON b.id = a.remplacee_par
                   WHERE a.genre IS DISTINCT FROM b.genre),
  'm12 : la ligne passee de l''autre cote ne tient plus sa voisine en historique ; aucune ligne n''est remplacee par une ligne de l''autre cote');

-- m13 : la regle du courriel est la meme a l'import qu'a l'inscription : exactement une ligne active, libre et
-- du meme cote. Deux soeurs « distinctes » au meme courriel (choix de la direction), la personne s'est inscrite
-- avant l'import : l'import ne relie ni l'une ni l'autre (il reliait la premiere traitee), et ne pre-remplit rien.
SELECT pg_temp.inscrit('fd', 'cand-l3-q1@test.invalid', 'Essai', 'Fratrie', 'female', '+966500009901');
SELECT pg_temp.garde('f_q', to_jsonb(pg_temp.csv(
  pg_temp.l('2027-07-01 10:00:00', 'f', 'Essai Femme Soeur Une', '+966500009911', 'cand-l3-q1@test.invalid'),
  pg_temp.l('2027-07-02 10:00:00', 'f', 'Essai Femme Soeur Deux', '+966500009912', 'cand-l3-q1@test.invalid'))));
SELECT pg_temp.garde('ap_q', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.apercu_import_formulaires(pg_temp.lu('f_q') #>> '{}', 'Classeur L3', 'F1')$$, 'aal2'));
SELECT pg_temp.garde('lot_q', pg_temp.en(pg_temp.p('d4'), 'admin',
  $$SELECT public.confirmer_import_formulaires(pg_temp.lu('f_q') #>> '{}', 'Classeur L3', 'F1',
      pg_temp.lu('ap_q') ->> 'jeton', jsonb_build_array(jsonb_build_object('groupe', pg_temp.lu('ap_q') #>> '{groupes,0,id}',
      'retenue', 'distinctes')), 'cle-rev-0025')$$, 'aal2'));
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.formulaires_reponses WHERE reference_source LIKE 'Classeur L3|F1|%' AND etat = 'active') = 2
  AND (SELECT count(*) FROM public.formulaires_reponses
        WHERE reference_source LIKE 'Classeur L3|F1|%' AND candidature_id IS NULL) = 2
  AND NOT EXISTS (SELECT 1 FROM public.candidature_reponses WHERE candidature_id = pg_temp.cid('fd'))
  AND NOT EXISTS (SELECT 1 FROM public.formulaires_rapprochements WHERE candidature_id = pg_temp.cid('fd')),
  'm13 : deux lignes actives au meme courriel (distinctes) : l''import apres l''inscription ne relie ni l''une ni l''autre, ne pre-remplit rien, ne propose rien (memes regles qu''a l''inscription)');

SELECT pg_catalog.set_config('test.final', pg_catalog.current_setting('test.n', true), true);
\o
SELECT 'CAND-L3 : ' || pg_catalog.current_setting('test.final') || ' controles verts' AS resultat;
ROLLBACK;
