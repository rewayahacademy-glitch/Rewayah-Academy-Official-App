-- CAND-L6 : referentiel declaratif de compatibilite de paiement (CAND-Q05,
-- DEC:28). Migration 20261021220100_cand_l6_referentiel_paiement.sql.
-- Cas de la spec consolidee, section 12.1 : L6-1 a L6-10 ; plus les droits
-- (direction, comptabilite, candidat, autres roles, anon), le journal
-- (referentiel, candidature_evenements, audit_logs, ajout seul, idempotence,
-- version), la portee des compteurs (impact et alertes bornes au cote du
-- lecteur, exception super-admin journalisee, total pour la comptabilite,
-- direction au genre inconnu refusee), la cle de l'Afrique (aucune ecriture
-- directe, decision du proprietaire seulement, fermeture gardee), les effets
-- d'une ecriture directe (declencheur), la salle 3 a colonne perimee et a
-- deux moyens dont un seul confirme (lecture stricte), et le compte candidat
-- desactive ou expire (L1-08).
-- Chaque controle leve 'CAND-L6 ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE (stub_auth puis toutes les migrations) ; le scenario pose ses
-- propres fixtures et annule tout a la fin.
-- Hors de ce lot, nommes la ou ils comptent : la transition 10 (admission en
-- salle 2) est un geste de L2, dont ce lot fournit le controle
-- private.paiement_compatible ; les notifications et courriels de la
-- transition 9 sont de L5, dont ce lot pose le marqueur aNotifier.
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
    RAISE EXCEPTION 'CAND-L6 ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CAND-L6 ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'CAND-L6 ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- La ligne du referentiel d'un pays et d'une methode (operateur facultatif).
-- DEFINER (proprietaire du scenario) : un compte ne lit pas la table.
CREATE FUNCTION pg_temp.ligne(p_pays text, p_methode text, p_operateur text DEFAULT NULL)
RETURNS public.referentiel_paiement
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT l.* FROM public.referentiel_paiement l
  WHERE l.pays = p_pays AND l.methode = p_methode
    AND l.operateur IS NOT DISTINCT FROM p_operateur;
$$;

-- Ecrit une ligne par la RPC, au nom de l'appelant courant.
CREATE FUNCTION pg_temp.ecrire(p_pays text, p_methode text, p_operateur text, p_etat text,
                               p_verifie_le date, p_cle text, p_notes text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE
  v_l public.referentiel_paiement := pg_temp.ligne(p_pays, p_methode, p_operateur);
BEGIN
  RETURN public.enregistrer_ligne_referentiel_paiement(
    v_l.id, p_pays, p_methode, p_operateur, NULL, NULL, NULL, p_etat, p_verifie_le, p_notes,
    v_l.version, p_cle);
END $$;

-- Nombre d'evenements d'une candidature, d'un type et d'un detail donnes.
CREATE FUNCTION pg_temp.ev(p_id uuid, p_type text, p_details jsonb DEFAULT '{}'::jsonb) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
  WHERE e.candidature_id = p_id AND e.type = p_type AND e.details @> p_details;
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text),
  pg_temp.ligne(text, text, text), pg_temp.ecrire(text, text, text, text, date, text, text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction au genre inconnu, a4
-- super-admin homme (exception de 0088), a5 direction desactivee, b1
-- comptabilite, e1 tuteur, f1 controleur ; c01 a c24 comptes enseignants,
-- chacun sa candidature (c23 desactive, c24 expire).
INSERT INTO auth.users (id, email)
SELECT ('ca6d0000-0000-4000-8000-0000000000' || s)::uuid, 'cand-l6-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'a4', 'a5', 'b1', 'e1', 'f1', '01', '02', '03', '04', '05', '06', '07',
                  '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21',
                  '22', '23', '24']) AS s;
INSERT INTO public.households (id, timezone)
VALUES ('ca6dffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('ca6d0000-0000-4000-8000-0000000000a1', 'CA6-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 ('ca6d0000-0000-4000-8000-0000000000a2', 'CA6-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 ('ca6d0000-0000-4000-8000-0000000000a3', 'CA6-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 ('ca6d0000-0000-4000-8000-0000000000a4', 'CA6-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 ('ca6d0000-0000-4000-8000-0000000000a5', 'CA6-ADM-0005', 'admin', NULL, 'Direction', 'Desactivee', 'disabled', 'male'),
 ('ca6d0000-0000-4000-8000-0000000000b1', 'CA6-CPT-0001', 'accountant', NULL, 'Compta', 'Essai', 'active', 'female'),
 ('ca6d0000-0000-4000-8000-0000000000e1', 'CA6-TUT-0001', 'guardian', 'ca6dffff-ffff-4fff-8fff-000000000001',
  'Tuteur', 'Essai', 'active', 'female'),
 ('ca6d0000-0000-4000-8000-0000000000f1', 'CA6-CTL-0001', 'controller', NULL, 'Controle', 'Essai', 'active', 'male'),
 ('ca6d0000-0000-4000-8000-000000000001', 'CA6-ENS-0001', 'teacher', NULL, 'Yahya', 'Arabie', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000002', 'CA6-ENS-0002', 'teacher', NULL, 'Hafsa', 'France', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000003', 'CA6-ENS-0003', 'teacher', NULL, 'Musa', 'Nigeria', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000004', 'CA6-ENS-0004', 'teacher', NULL, 'Ruqayya', 'Verif', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000005', 'CA6-ENS-0005', 'teacher', NULL, 'Idris', 'Seul', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000006', 'CA6-ENS-0006', 'teacher', NULL, 'Ilyas', 'Deux', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000007', 'CA6-ENS-0007', 'teacher', NULL, 'Asma', 'Seule', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000008', 'CA6-ENS-0008', 'teacher', NULL, 'Harun', 'Piece', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000009', 'CA6-ENS-0009', 'teacher', NULL, 'Zaynab', 'Salle', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000010', 'CA6-ENS-0010', 'teacher', NULL, 'Yunus', 'Examen', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000011', 'CA6-ENS-0011', 'teacher', NULL, 'Safiyya', 'Completer', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000012', 'CA6-ENS-0012', 'teacher', NULL, 'Ishaq', 'Refuse', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000013', 'CA6-ENS-0013', 'teacher', NULL, 'Dawud', 'Pk', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000014', 'CA6-ENS-0014', 'teacher', NULL, 'Sumayya', 'Pk', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000015', 'CA6-ENS-0015', 'teacher', NULL, 'Talha', 'Wave', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000016', 'CA6-ENS-0016', 'teacher', NULL, 'Nusayba', 'Gb', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000017', 'CA6-ENS-0017', 'teacher', NULL, 'Ammar', 'Ca', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000018', 'CA6-ENS-0018', 'teacher', NULL, 'Umama', 'Mobile', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000019', 'CA6-ENS-0019', 'teacher', NULL, 'Bashir', 'Forme', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000020', 'CA6-ENS-0020', 'teacher', NULL, 'Hamza', 'Directe', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000021', 'CA6-ENS-0021', 'teacher', NULL, 'Khalid', 'Perime', 'pending_kyc', 'male'),
 ('ca6d0000-0000-4000-8000-000000000022', 'CA6-ENS-0022', 'teacher', NULL, 'Maryam', 'DeuxMoyens', 'pending_kyc', 'female'),
 ('ca6d0000-0000-4000-8000-000000000023', 'CA6-ENS-0023', 'teacher', NULL, 'Salim', 'Desactive', 'disabled', 'male'),
 ('ca6d0000-0000-4000-8000-000000000024', 'CA6-ENS-0024', 'teacher', NULL, 'Rayan', 'Expire', 'pending_kyc', 'male');
UPDATE public.profiles SET access_until = now() - interval '1 day'
WHERE id = 'ca6d0000-0000-4000-8000-000000000024';
-- L'exception super-admin de 0088 pour a4, comme dans le scenario de L1.
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('ca6d0000-0000-4000-8000-0000000000a4');
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

-- Un operateur fictif du catalogue, pour les lignes de mobile money des cas
-- L6-6 et L6-8 (hors d'Afrique, puisque l'Afrique reste en verification).
INSERT INTO public.referentiel_paiement_operateurs (code, methode, nom)
VALUES ('op_fictif', 'mobile_money', 'Operateur fictif');

-- Candidatures (genre recopie du compte). Etapes et etats choisis par cas.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue,
                                 restreinte, restriction_cause, source)
SELECT ('ca6dcccc-0000-4000-8000-0000000000' || v.s)::uuid, 'enseignant',
       ('ca6d0000-0000-4000-8000-0000000000' || v.s)::uuid, 'male', 'Fixture ' || v.s,
       v.etape, v.etat, v.issue, v.restreinte, v.cause, 'lien_public'
FROM (VALUES
  ('01', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('02', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('03', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('04', 'verifications', 'entretien_a_planifier', 'en_cours', false, NULL),
  ('05', 'confirmee', NULL, 'en_cours', false, NULL),
  ('06', 'confirmee', NULL, 'en_cours', false, NULL),
  ('07', 'confirmee', NULL, 'en_cours', false, NULL),
  ('08', 'confirmee', NULL, 'en_cours', true, 'piece'),
  ('09', 'verifications', 'entretien_a_planifier', 'en_cours', false, NULL),
  ('10', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('11', 'prequalification', 'a_completer', 'en_cours', false, NULL),
  ('12', 'prequalification', 'en_examen', 'refusee', false, NULL),
  ('13', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('14', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('15', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('16', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('17', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('18', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('19', 'prequalification', 'a_completer', 'en_cours', false, NULL),
  ('20', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('22', 'confirmee', NULL, 'en_cours', false, NULL),
  ('23', 'prequalification', 'en_examen', 'en_cours', false, NULL),
  ('24', 'prequalification', 'en_examen', 'en_cours', false, NULL)
) AS v(s, etape, etat, issue, restreinte, cause);

-- Reponses declarees (cles de la migration : paysVersement, compteBancaire,
-- operateurs). c19 : un document importe plus recent, ignore ; c04 : un
-- document plus ancien sur un autre pays, remplace par le plus recent.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
SELECT ('ca6dcccc-0000-4000-8000-0000000000' || v.s)::uuid, 'v1-2026-10', v.r::jsonb, 'candidat', now() - interval '1 day'
FROM (VALUES
  ('01', '{"paysResidence": "SA", "paysVersement": "SA", "compteBancaire": true, "operateurs": [], "accordRemuneration": true}'),
  ('02', '{"paysResidence": "FR", "paysVersement": "FR", "compteBancaire": false, "operateurs": [], "accordRemuneration": true}'),
  ('03', '{"paysResidence": "NG", "paysVersement": "NG", "compteBancaire": true, "operateurs": ["wave"]}'),
  ('04', '{"paysVersement": "PK", "compteBancaire": true}'),
  ('05', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('06', '{"paysVersement": "TR", "compteBancaire": true, "operateurs": ["op_fictif"]}'),
  ('07', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('08', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('09', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('10', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('11', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('12', '{"paysVersement": "TR", "compteBancaire": true}'),
  ('13', '{"paysVersement": "PK", "compteBancaire": true}'),
  ('14', '{"paysVersement": "PK", "compteBancaire": true}'),
  ('15', '{"paysVersement": "PK", "compteBancaire": false, "operateurs": ["wave", "Pas Un Code", 7]}'),
  ('16', '{"paysVersement": "GB", "compteBancaire": true}'),
  ('17', '{"paysVersement": "CA", "compteBancaire": true}'),
  ('18', '{"paysVersement": "PH", "compteBancaire": false, "operateurs": ["op_fictif"]}'),
  ('19', '{"paysVersement": "sa", "compteBancaire": true}'),
  ('20', '{"paysVersement": "DE", "compteBancaire": true}'),
  ('22', '{"paysVersement": "TR", "compteBancaire": true, "operateurs": ["op_fictif"]}'),
  ('23', '{"paysVersement": "IT", "compteBancaire": true}'),
  ('24', '{"paysVersement": "FR", "compteBancaire": true}')
) AS v(s, r);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le) VALUES
 ('ca6dcccc-0000-4000-8000-000000000004', 'v1-2026-10', '{"paysVersement": "SA", "compteBancaire": true}',
  'candidat', now() - interval '5 days'),
 ('ca6dcccc-0000-4000-8000-000000000019', 'formulaire-A1',
  '{"paysVersement": "SA", "compteBancaire": true}', 'import', now());

-- ------------------------------------------------------------
-- (a) Tables, RPC et aides : RLS, droits, F86
-- ------------------------------------------------------------
DO $structure$
DECLARE
  t regclass;
  f regprocedure;
  r text;
BEGIN
  FOREACH t IN ARRAY ARRAY['public.referentiel_paiement'::regclass, 'public.referentiel_paiement_afrique'::regclass,
                           'public.referentiel_paiement_afrique_decisions'::regclass,
                           'public.referentiel_paiement_operateurs'::regclass,
                           'public.referentiel_paiement_journal'::regclass,
                           'public.candidature_paiement_decisions'::regclass] LOOP
    IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = t) THEN
      RAISE EXCEPTION 'CAND-L6 ROUGE : RLS inactive sur %', t;
    END IF;
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_table_privilege(r, t, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-L6 ROUGE : % a un privilege sur %', r, t;
      END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM pg_policies p JOIN pg_class c ON c.oid = t
               WHERE p.schemaname = 'public' AND p.tablename = c.relname) THEN
      RAISE EXCEPTION 'CAND-L6 ROUGE : une policy ouvre %', t;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('six tables : RLS active, aucun privilege pour anon, authenticated, service_role, agent_ro, aucune policy');

  FOREACH f IN ARRAY ARRAY['public.capacites_referentiel_paiement()'::regprocedure,
                           'public.lire_referentiel_paiement(text)'::regprocedure,
                           'public.options_paiement_confirmees(text)'::regprocedure,
                           'public.enregistrer_ligne_referentiel_paiement(uuid,text,text,text,text,text,text,text,date,text,integer,text)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                   AND coalesce(proconfig @> ARRAY['search_path=""'], false)
            FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE')
       OR app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f)) THEN
      RAISE EXCEPTION 'CAND-L6 ROUGE : DEFINER, proprietaire, search_path, empreinte, ACL ou garde de %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('quatre RPC : DEFINER postgres, search_path vide, empreinte reelle, authenticated seul, garde positive (b18)');
  IF (SELECT array_agg(provolatile::text ORDER BY proname) FROM pg_proc
      WHERE pronamespace = 'public'::regnamespace
        AND proname IN ('capacites_referentiel_paiement', 'enregistrer_ligne_referentiel_paiement',
                        'lire_referentiel_paiement', 'options_paiement_confirmees'))
     IS DISTINCT FROM ARRAY['s', 'v', 'v', 's'] THEN
    RAISE EXCEPTION 'CAND-L6 ROUGE : volatilite inattendue';
  END IF;
  PERFORM pg_temp.ok('capacites et options STABLE ; ecriture et lecture du referentiel VOLATILE (la lecture journalise l''exception super-admin ; liste blanche des volatiles)');
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p
           WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'paiement\_%' LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_function_privilege(r, f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L6 ROUGE : aide interne % executable par %', f, r;
      END IF;
    END LOOP;
  END LOOP;
  IF (SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace AND proname LIKE 'paiement\_%') <> 19
     OR (SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace AND proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-L6 ROUGE : dix-neuf aides paiement_ attendues, et les neuf aides cand_ de L1 intactes';
  END IF;
  PERFORM pg_temp.ok('dix-neuf aides internes paiement_, executables par aucun compte ; les neuf aides de L1 inchangees');
  IF (SELECT count(*) FROM pg_trigger WHERE tgrelid = 'public.referentiel_paiement'::regclass
        AND tgname = 'referentiel_paiement_effets' AND tgtype & 1 = 1 AND tgenabled <> 'D') <> 1
     OR (SELECT count(*) FROM pg_trigger WHERE tgrelid = 'public.app_config'::regclass
           AND tgname = 'app_config_paiement_afrique_ouverte' AND tgenabled <> 'D') <> 1 THEN
    RAISE EXCEPTION 'CAND-L6 ROUGE : declencheur des effets (par ligne) ou garde de la cle Afrique absent';
  END IF;
  PERFORM pg_temp.ok('declencheur des effets sur le referentiel (par ligne, toute voie) et garde de la cle paiement.afrique_ouverte poses');
END $structure$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.lire_referentiel_paiement()$$, '42501', 'anon : lecture du referentiel refusee');
SELECT pg_temp.refus($$SELECT public.options_paiement_confirmees('SA')$$, '42501', 'anon : options refusees');
SELECT pg_temp.refus($$SELECT private.paiement_etat('ca6dcccc-0000-4000-8000-000000000001')$$, '42501',
  'anon : calcul prive ferme');
RESET ROLE;

-- ------------------------------------------------------------
-- (b) Etat initial deduit de DEC:28 et liste des pays d'Afrique (ONU M49)
-- ------------------------------------------------------------
DO $initial$
BEGIN
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement) = 249
    AND (SELECT count(DISTINCT pays) FROM public.referentiel_paiement) = 249
    AND (SELECT bool_and(methode = 'virement_bancaire' AND operateur IS NULL AND source = 'decision_directeur'
                         AND source_ref = 'DEC:28 (CAND-Q05, 21/10/2026)' AND verifie_par IS NULL AND notes LIKE '%DEC:28%')
         FROM public.referentiel_paiement),
    'etat initial : une ligne de virement par pays de pays_iso.dart (249), source decision du directeur DEC:28');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement_afrique) = 60
    AND (SELECT array_agg(region_m49 || ':' || n ORDER BY region_m49) FROM
          (SELECT region_m49, count(*) n FROM public.referentiel_paiement_afrique GROUP BY 1) x)
        = ARRAY['011:17', '014:22', '015:7', '017:9', '018:5'],
    'Afrique (ONU M49, region 002) : 60 pays ou territoires, 7 au nord, 22 a l''est, 9 au centre, 5 au sud, 17 a l''ouest');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement l
                        JOIN public.referentiel_paiement_afrique a ON a.pays = l.pays
                        WHERE l.etat = 'en_verification' AND l.verifie_le IS NULL) = 60
    AND (SELECT count(*) FROM public.referentiel_paiement l
         WHERE l.etat = 'confirme' AND l.verifie_le = DATE '2026-10-21'
           AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement_afrique a WHERE a.pays = l.pays)) = 189
    AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement WHERE etat = 'indisponible'),
    'Afrique : 60 lignes en verification, compte bancaire compris ; hors d''Afrique : 189 lignes confirme du 21/10');
  PERFORM pg_temp.vrai((pg_temp.ligne('SA', 'virement_bancaire')).etat = 'confirme'
    AND (pg_temp.ligne('YE', 'virement_bancaire')).etat = 'confirme'
    AND (pg_temp.ligne('EG', 'virement_bancaire')).etat = 'en_verification'
    AND (pg_temp.ligne('NG', 'virement_bancaire')).etat = 'en_verification'
    AND (pg_temp.ligne('SN', 'virement_bancaire')).etat = 'en_verification'
    AND (pg_temp.ligne('RE', 'virement_bancaire')).etat = 'en_verification'
    AND (pg_temp.ligne('FR', 'virement_bancaire')).etat = 'confirme',
    'DEC:28 : Arabie saoudite comprise (et Yemen, Asie de l''Ouest) ; Egypte, Nigeria, Senegal, Reunion en verification');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.referentiel_paiement WHERE methode = 'mobile_money')
    AND (SELECT array_agg(code ORDER BY code) FROM public.referentiel_paiement_operateurs WHERE code <> 'op_fictif')
        = ARRAY['moov_money', 'orange_money', 'wave'],
    'aucune ligne de mobile money supposee ; trois operateurs nommes par la spec au catalogue');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement_journal
                        WHERE auteur_id IS NULL AND cle_idempotence IS NULL AND avant IS NULL) = 249,
    'etat initial journalise : une ligne de journal par ligne, sans auteur ni cle');
  PERFORM pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'paiement.afrique_ouverte') = 'false'::jsonb
    AND NOT private.paiement_afrique_ouverte()
    AND (SELECT count(*) FROM public.referentiel_paiement_afrique_decisions) = 1
    AND (SELECT NOT ouverte AND decision_ref LIKE 'DEC:80-83%' AND decide_le = DATE '2026-10-21'
         FROM public.referentiel_paiement_afrique_decisions),
    'CAND-Q05 ouvert : une decision fermee (DEC:80-83), recopiee dans la cle paiement.afrique_ouverte a false');
END $initial$;

-- ------------------------------------------------------------
-- (c) Droits et capacites (spec consolidee 8.1 et 8.2)
-- ------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": true, "peutEcrire": true}'::jsonb,
  'direction homme : lit et ecrit le referentiel');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a3', 'admin');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": false, "peutEcrire": false}'::jsonb,
  'direction au genre inconnu : aucune capacite (CAND-Q07, comme L1)');
SELECT pg_temp.refus($$SELECT public.lire_referentiel_paiement()$$, '42501',
  'direction au genre inconnu : lecture refusee (alertes cloisonnees)');
SELECT pg_temp.refus($$SELECT pg_temp.ecrire('TR', 'virement_bancaire', NULL, 'indisponible', current_date, 'inconnu-cle-0001')$$,
  '42501', 'direction au genre inconnu : ecriture refusee avant tout effet sur une candidature');
SELECT pg_temp.refus($$SELECT public.options_paiement_confirmees('TR')$$, '42501',
  'direction au genre inconnu : options refusees');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a4', 'admin');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": true, "peutEcrire": true}'::jsonb,
  'super-admin (exception de 0088) : lit et ecrit');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000b1', 'accountant');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": true, "peutEcrire": true}'::jsonb,
  'comptabilite : lit et ecrit le referentiel');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a5', 'admin');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": false, "peutEcrire": false}'::jsonb,
  'direction desactivee : aucune capacite');
SELECT pg_temp.refus($$SELECT public.lire_referentiel_paiement()$$, '42501', 'direction desactivee : lecture refusee');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000e1', 'guardian');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": false, "peutEcrire": false}'::jsonb,
  'tuteur : aucune capacite');
SELECT pg_temp.refus($$SELECT public.lire_referentiel_paiement()$$, '42501', 'tuteur : lecture refusee');
SELECT pg_temp.refus($$SELECT public.options_paiement_confirmees('SA')$$, '42501', 'tuteur : options refusees');
SELECT pg_temp.refus($$SELECT pg_temp.ecrire('FR', 'virement_bancaire', NULL, 'indisponible', NULL, 'tuteur-cle-0001')$$,
  '42501', 'tuteur : ecriture refusee');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000f1', 'controller');
SELECT pg_temp.refus($$SELECT public.lire_referentiel_paiement()$$, '42501', 'controleur : lecture refusee');
SELECT pg_temp.refus($$SELECT pg_temp.ecrire('FR', 'virement_bancaire', NULL, 'indisponible', NULL, 'ctl-cle-0001')$$,
  '42501', 'controleur : ecriture refusee');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-000000000001', 'teacher');
SELECT pg_temp.vrai(public.capacites_referentiel_paiement() = '{"peutLire": false, "peutEcrire": false}'::jsonb,
  'candidat : aucune capacite sur le referentiel');
SELECT pg_temp.refus($$SELECT public.lire_referentiel_paiement('SA')$$, '42501', 'L6-7 candidat : referentiel complet refuse');
SELECT pg_temp.refus($$SELECT pg_temp.ecrire('SA', 'virement_bancaire', NULL, 'indisponible', NULL, 'cand-cle-0001')$$,
  '42501', 'candidat : ecriture refusee');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-000000000012', 'teacher');
SELECT pg_temp.refus($$SELECT public.options_paiement_confirmees('TR')$$, '42501',
  'candidature refusee : plus d''options (titulaire d''une candidature EN COURS seulement)');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-000000000023', 'teacher');
SELECT pg_temp.refus($$SELECT public.options_paiement_confirmees('TR')$$, '42501',
  'L1-08 : compte desactive, candidature en cours : options refusees');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-000000000024', 'teacher');
SELECT pg_temp.refus($$SELECT public.options_paiement_confirmees('FR')$$, '42501',
  'L1-08 : compte en attente expire (access_until passe) : options refusees');
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.refus($$SELECT public.capacites_referentiel_paiement()$$, '42501', 'sans session : capacites refusees');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($$SELECT count(*) FROM public.referentiel_paiement$$, '42501', 'direction : aucune lecture directe de la table');
SELECT pg_temp.refus($$INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000001', 'SA', 'virement_bancaire', 'confirme', 'ca6d0000-0000-4000-8000-0000000000a1')$$,
  '42501', 'direction : aucune ecriture directe des decisions (geste L2 par RPC)');
DO $lire$
DECLARE
  r1 jsonb; r2 jsonb; rk jsonb;
BEGIN
  r1 := public.lire_referentiel_paiement();
  PERFORM pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
  r2 := public.lire_referentiel_paiement();
  PERFORM pg_temp.qui('ca6d0000-0000-4000-8000-0000000000b1', 'accountant');
  rk := public.lire_referentiel_paiement();
  PERFORM pg_temp.vrai(r1 = r2 AND r2 = rk AND jsonb_array_length(r1 -> 'lignes') = 249,
    'lignes non cloisonnees : directeur, directrice et comptabilite lisent les memes 249 lignes (aucune alerte encore)');
  PERFORM pg_temp.vrai((r1 ->> 'afriqueEnVerification')::boolean
    AND jsonb_array_length(r1 -> 'afrique' -> 'pays') = 60
    AND r1 -> 'afrique' ->> 'source' LIKE '%M49%unstats.un.org%'
    AND r1 -> 'options' -> 'methodes' = '["virement_bancaire", "mobile_money"]'::jsonb
    AND r1 -> 'options' -> 'etats' = '["confirme", "en_verification", "indisponible"]'::jsonb
    AND jsonb_array_length(r1 -> 'options' -> 'operateurs') = 4
    AND r1 -> 'afrique' -> 'decision' ->> 'ouverte' = 'false'
    AND r1 -> 'afrique' -> 'decision' ->> 'reference' LIKE 'DEC:80-83%'
    AND r1 -> 'alertes' = '[]'::jsonb,
    'lecture : Afrique en verification, liste de 60 pays et sa source nommee, derniere decision, listes de la fiche, aucune alerte');
  PERFORM pg_temp.vrai((SELECT l FROM jsonb_array_elements(public.lire_referentiel_paiement('SA') -> 'lignes') l)
      - 'id' - 'modifieLe' = '{"pays": "SA", "afrique": false, "methode": "virement_bancaire", "operateur": null,
        "operateurNom": null, "prestataire": null, "devise": null, "typeDecaissement": null, "etat": "confirme",
        "capacitePayout": "prisEnCharge", "source": "decision_directeur", "sourceRef": "DEC:28 (CAND-Q05, 21/10/2026)",
        "verifieLe": "2026-10-21", "verifiePar": null, "verifieParNom": null,
        "notes": "Décision du directeur du 21/10, DEC:28 : virement bancaire hors d''Afrique, Arabie saoudite comprise. Règle décidée, pays non vérifié un à un : un pays où l''académie ne peut pas verser se signale au directeur.",
        "version": 1}'::jsonb
    AND (SELECT l ->> 'capacitePayout' FROM jsonb_array_elements(public.lire_referentiel_paiement('NG') -> 'lignes') l)
        = 'verificationRequise',
    'ligne SA : forme complete pour la direction ; part de CPT-BR-10 : confirme prisEnCharge, en verification verificationRequise');
  PERFORM pg_temp.refus($$SELECT public.lire_referentiel_paiement('sa')$$, '22023', 'pays mal forme refuse');
END $lire$;
RESET ROLE;

-- ------------------------------------------------------------
-- (d) Le calcul de la dimension paiement (spec consolidee 4.1, 5.1)
-- ------------------------------------------------------------
DO $calcul$
BEGIN
  PERFORM pg_temp.vrai(private.paiement_declaration('ca6dcccc-0000-4000-8000-000000000015')
      = '{"paysVersement": "PK", "compteBancaire": false, "operateurs": ["wave"]}'::jsonb
    AND private.paiement_declaration('ca6dcccc-0000-4000-8000-000000000004')
      = '{"paysVersement": "PK", "compteBancaire": true, "operateurs": []}'::jsonb,
    'declaration : codes d''operateur mal formes ignores ; le document candidat le plus recent fait foi');
  PERFORM pg_temp.vrai(private.paiement_etat('ca6dcccc-0000-4000-8000-000000000019') = 'inconnu'
    AND private.paiement_declaration('ca6dcccc-0000-4000-8000-000000000019') IS NULL,
    'inconnu : pays de versement mal forme ; une reponse importee plus recente ne compte pas (paiement jamais pre-rempli)');
  -- L6-1 : Arabie saoudite, compte bancaire oui, moyen confirme.
  PERFORM pg_temp.vrai(private.paiement_etat('ca6dcccc-0000-4000-8000-000000000001') = 'a_verifier'
    AND NOT private.paiement_compatible('ca6dcccc-0000-4000-8000-000000000001'),
    'L6-1 avant decision : la declaration croise la ligne confirme de SA, a_verifier, pas encore compatible');
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000001', 'SA', 'virement_bancaire', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a1');
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000001', 'moyen_confirme',
    'ca6d0000-0000-4000-8000-0000000000a1');
  PERFORM pg_temp.vrai(private.paiement_etat('ca6dcccc-0000-4000-8000-000000000001') = 'compatible'
    AND private.paiement_compatible('ca6dcccc-0000-4000-8000-000000000001')
    AND (SELECT paiement = 'compatible' AND etat = 'en_examen' FROM public.candidatures
         WHERE id = 'ca6dcccc-0000-4000-8000-000000000001'),
    'L6-1 : Arabie saoudite, compte bancaire, moyen confirme : compatible ; le controle paiement_compatible de la transition 10 (L2) est vrai');

  -- L6-2 : hors d'Afrique, sans compte bancaire.
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000002', 'reponses');
  PERFORM pg_temp.vrai((SELECT paiement = 'incompatible' AND etape = 'prequalification'
                               AND etat = 'paiement_non_disponible' AND issue = 'en_cours'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000002')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000002', 'transition',
                   '{"transition": 8, "cause": "reponses"}') = 1,
    'L6-2 : France sans compte bancaire : incompatible, paiement_non_disponible, issue en_cours, transition 8 tracee');

  -- L6-3 : Afrique, compte bancaire oui, CAND-Q05 ouvert.
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000003', 'reponses');
  PERFORM pg_temp.vrai(private.paiement_etat('ca6dcccc-0000-4000-8000-000000000003') = 'incompatible'
    AND (SELECT etat FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000003')
        = 'paiement_non_disponible',
    'L6-3 : Nigeria avec compte bancaire, CAND-Q05 ouvert : incompatible, reste en salle d''examen');
  PERFORM pg_temp.refus($$INSERT INTO public.candidature_paiement_decisions
      (candidature_id, pays, methode, decision, auteur_id)
    VALUES ('ca6dcccc-0000-4000-8000-000000000003', 'NG', 'virement_bancaire', 'confirme',
            'ca6d0000-0000-4000-8000-0000000000a1')$$, '23514',
    'L6-3 et L6-4 : une ligne en_verification ne se confirme jamais (decision de la direction refusee en base)');
  PERFORM pg_temp.refus($$INSERT INTO public.candidature_paiement_decisions
      (candidature_id, pays, methode, decision, auteur_id)
    VALUES ('ca6dcccc-0000-4000-8000-000000000002', 'FR', 'virement_bancaire', 'confirme',
            'ca6d0000-0000-4000-8000-0000000000a1')$$, '23514',
    'confirmation d''un moyen non declare (pas de compte bancaire) refusee en base');
  PERFORM pg_temp.refus($$INSERT INTO public.candidature_paiement_decisions
      (candidature_id, pays, methode, decision, auteur_id)
    VALUES ('ca6dcccc-0000-4000-8000-000000000017', 'CA', 'virement_bancaire', 'infirme',
            'ca6d0000-0000-4000-8000-0000000000a1')$$, '23514',
    'infirmer un moyen sans motif refuse (transition 25)');
  PERFORM pg_temp.refus($$SELECT private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000017',
      'moyen_infirme', 'ca6d0000-0000-4000-8000-0000000000a1', '  ')$$, '22023',
    'recalcul apres infirmation sans motif refuse');
  PERFORM pg_temp.refus($$SELECT private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000017', 'autre')$$,
    '22023', 'cause de recalcul hors liste refusee');
  -- Une candidature refusee n'est jamais touchee.
  PERFORM pg_temp.vrai(private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000012', 'reponses') ->> 'effet' = 'aucun'
    AND (SELECT paiement = 'inconnu' AND version = 1 FROM public.candidatures
         WHERE id = 'ca6dcccc-0000-4000-8000-000000000012'),
    'candidature refusee : aucun effet, aucune ecriture');
END $calcul$;

-- ------------------------------------------------------------
-- (e) Ecriture : confirmation sans verification, conflit, idempotence,
-- Afrique (L6-5)
-- ------------------------------------------------------------
-- Le journal et l'audit ne sont pas lisibles par un compte : on compte en
-- proprietaire avant et apres.
SELECT set_config('test.j0', (SELECT count(*)::text FROM public.referentiel_paiement_journal), true);
SELECT set_config('test.a0', (SELECT count(*)::text FROM public.audit_logs
                              WHERE action = 'referentiel_paiement_ecriture'), true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
DO $ecriture$
DECLARE
  r jsonb;
  v_fr public.referentiel_paiement := pg_temp.ligne('FR', 'virement_bancaire');
BEGIN

  -- L6-5 : confirme sans date de verification.
  r := public.enregistrer_ligne_referentiel_paiement(v_fr.id, 'FR', 'virement_bancaire', NULL, NULL, 'EUR', NULL,
         'confirme', NULL, NULL, 1, 'l6-cle-sans-date-0001');
  PERFORM pg_temp.vrai(r = '{"erreur": "confirmation_sans_verification"}'::jsonb,
    'L6-5 : confirme sans date de verification, refus rendu confirmation_sans_verification');
  -- Afrique : CAND-Q05 ouvert.
  r := pg_temp.ecrire('SN', 'virement_bancaire', NULL, 'confirme', current_date, 'l6-cle-afrique-0001');
  PERFORM pg_temp.vrai(r = '{"erreur": "afrique_en_verification", "pays": "SN"}'::jsonb,
    'Afrique : confirmer le virement au Senegal est refuse tant que CAND-Q05 est ouvert');
  r := pg_temp.ecrire('SN', 'virement_bancaire', NULL, 'indisponible', current_date, 'l6-cle-afrique-0002');
  PERFORM pg_temp.vrai(r = '{"erreur": "afrique_en_verification", "pays": "SN"}'::jsonb,
    'Afrique : passer le virement au Senegal a indisponible est refuse aussi (toutes ses lignes restent en verification)');
  -- Version perimee, ligne deja existante, identite changee.
  r := public.enregistrer_ligne_referentiel_paiement(v_fr.id, 'FR', 'virement_bancaire', NULL, NULL, 'EUR', NULL,
         'confirme', current_date, NULL, 7, 'l6-cle-perimee-0001');
  PERFORM pg_temp.vrai(r ->> 'erreur' = 'conflit_referentiel' AND (r -> 'ligne' ->> 'version')::int = 1,
    'version perimee : conflit_referentiel, ligne relue rendue');
  r := public.enregistrer_ligne_referentiel_paiement(NULL, 'FR', 'virement_bancaire', NULL, NULL, NULL, NULL,
         'confirme', current_date, NULL, NULL, 'l6-cle-doublon-0001');
  PERFORM pg_temp.vrai(r ->> 'erreur' = 'conflit_referentiel' AND r -> 'ligne' ->> 'id' = v_fr.id::text,
    'creation d''une ligne qui existe deja : conflit_referentiel');
  r := public.enregistrer_ligne_referentiel_paiement(gen_random_uuid(), 'FR', 'virement_bancaire', NULL, NULL, NULL,
         NULL, 'confirme', current_date, NULL, 1, 'l6-cle-absente-0001');
  PERFORM pg_temp.vrai(r = '{"erreur": "absente"}'::jsonb, 'ligne inconnue : absente');
  PERFORM pg_temp.refus(pg_catalog.format($$SELECT public.enregistrer_ligne_referentiel_paiement(%L, 'BE',
      'virement_bancaire', NULL, NULL, NULL, NULL, 'confirme', current_date, NULL, 1, 'l6-cle-identite-0001')$$, v_fr.id),
    '22023', 'le pays d''une ligne ne change pas');
  PERFORM pg_temp.refus($$SELECT public.enregistrer_ligne_referentiel_paiement(NULL, 'FR', 'mobile_money', NULL, NULL,
      NULL, NULL, 'confirme', current_date, NULL, NULL, 'l6-cle-sansop-0001')$$, '22023',
    'mobile money sans operateur refuse');
  PERFORM pg_temp.refus($$SELECT public.enregistrer_ligne_referentiel_paiement(NULL, 'FR', 'mobile_money', 'inconnu_op',
      NULL, NULL, NULL, 'confirme', current_date, NULL, NULL, 'l6-cle-opinc-0001')$$, '22023',
    'operateur hors catalogue refuse');
  PERFORM pg_temp.refus($$SELECT public.enregistrer_ligne_referentiel_paiement(NULL, 'ZZ', 'virement_bancaire', NULL,
      NULL, NULL, NULL, 'en_verification', NULL, NULL, NULL, 'l6-cle-pays-0001')$$, '22023',
    'pays inconnu du referentiel refuse');
  PERFORM pg_temp.refus(pg_catalog.format($$SELECT public.enregistrer_ligne_referentiel_paiement(%L, 'FR',
      'virement_bancaire', NULL, NULL, NULL, NULL, 'confirme', current_date + 30, NULL, 1, 'l6-cle-futur-0001')$$, v_fr.id),
    '22023', 'date de verification dans le futur refusee');
  PERFORM pg_temp.refus($$SELECT pg_temp.ecrire('FR', 'virement_bancaire', NULL, 'confirme', current_date, 'court')$$,
    '22023', 'cle d''idempotence trop courte refusee');

  -- Une ecriture reussie, sans effet sur les candidatures (FR reste confirme).
  r := public.enregistrer_ligne_referentiel_paiement(v_fr.id, 'FR', 'virement_bancaire', NULL, 'banque_fictive', 'EUR',
         'virement_international', 'confirme', current_date, '  Virement SEPA vérifié par un essai.  ', 1,
         'l6-cle-fr-0001');
  PERFORM pg_temp.vrai(r ->> 'rejoue' = 'false' AND (r ->> 'impact')::int = 0
    AND r -> 'ligne' ->> 'source' = 'verification' AND r -> 'ligne' ->> 'sourceRef' IS NULL
    AND r -> 'ligne' ->> 'verifiePar' = 'ca6d0000-0000-4000-8000-0000000000a1'
    AND r -> 'ligne' ->> 'verifieParNom' = 'Direction Homme'
    AND r -> 'ligne' ->> 'verifieLe' = current_date::text
    AND r -> 'ligne' ->> 'notes' = 'Virement SEPA vérifié par un essai.'
    AND (r -> 'ligne' ->> 'version')::int = 2
    AND r -> 'ligne' ->> 'devise' = 'EUR' AND r -> 'ligne' ->> 'prestataire' = 'banque_fictive'
    AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(r) k) = ARRAY['impact', 'ligne', 'rejoue'],
    'ecriture : ligne relue au serveur, verifie par le compte qui enregistre, version 2, impact 0 ; rien d''autre que la ligne, l''impact et rejoue');
  -- Reprise de la meme cle : meme reponse, aucun nouvel effet.
  PERFORM pg_temp.vrai(public.enregistrer_ligne_referentiel_paiement(v_fr.id, 'FR', 'virement_bancaire', NULL,
      'banque_fictive', 'EUR', 'virement_international', 'confirme', current_date,
      '  Virement SEPA vérifié par un essai.  ', 1, 'l6-cle-fr-0001')
    = jsonb_set(r, '{rejoue}', 'true'),
    'meme cle rejouee : meme ligne et meme impact, rejoue vrai');
  PERFORM pg_temp.vrai(public.enregistrer_ligne_referentiel_paiement(v_fr.id, 'FR', 'virement_bancaire', NULL,
      NULL, 'EUR', NULL, 'indisponible', current_date, NULL, 2, 'l6-cle-fr-0001')
    = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb,
    'meme cle pour une autre demande : refus rendu');
  PERFORM pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
  PERFORM pg_temp.vrai(public.enregistrer_ligne_referentiel_paiement(v_fr.id, 'FR', 'virement_bancaire', NULL,
      'banque_fictive', 'EUR', 'virement_international', 'confirme', current_date,
      '  Virement SEPA vérifié par un essai.  ', 1, 'l6-cle-fr-0001')
    = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb,
    'meme cle par un autre compte : refus rendu');
END $ecriture$;
RESET ROLE;

DO $ecriture_trace$
BEGIN
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement_journal) = current_setting('test.j0')::int + 1
    AND (SELECT count(*) FROM public.audit_logs WHERE action = 'referentiel_paiement_ecriture')
        = current_setting('test.a0')::int + 1
    AND (pg_temp.ligne('FR', 'virement_bancaire')).version = 2
    AND (pg_temp.ligne('SN', 'virement_bancaire')).etat = 'en_verification',
    'refus et reprises : 0 ecriture ; la seule ecriture reussie laisse 1 ligne de journal et 1 entree audit_logs');
  PERFORM pg_temp.vrai((SELECT avant ->> 'etat' = 'confirme' AND avant ->> 'source' = 'decision_directeur'
                               AND apres ->> 'source' = 'verification' AND auteur_id = 'ca6d0000-0000-4000-8000-0000000000a1'
                               AND cle_idempotence = 'l6-cle-fr-0001'
                        FROM public.referentiel_paiement_journal ORDER BY id DESC LIMIT 1),
    'journal : avant, apres, auteur et cle de l''ecriture');
END $ecriture_trace$;

DO $contraintes$
BEGIN
  PERFORM pg_temp.refus($$INSERT INTO public.referentiel_paiement (pays, methode, operateur, etat, source)
    VALUES ('FR', 'mobile_money', 'wave', 'confirme', 'verification')$$, '23514',
    'L6-5 en base : confirme sans date ni responsable refuse par la table');
  PERFORM pg_temp.refus($$UPDATE public.referentiel_paiement SET verifie_le = NULL
    WHERE pays = 'DE' AND methode = 'virement_bancaire'$$, '23514',
    'L6-5 en base : une ligne confirme ne perd pas sa date de verification');
  PERFORM pg_temp.refus($$UPDATE public.referentiel_paiement SET etat = 'confirme', verifie_le = current_date
    WHERE pays = 'SN' AND methode = 'virement_bancaire'$$, '23514',
    'Afrique en base : aucune voie ne confirme une ligne d''Afrique tant que CAND-Q05 est ouvert');
  PERFORM pg_temp.refus($$UPDATE public.referentiel_paiement SET etat = 'indisponible'
    WHERE pays = 'SN' AND methode = 'virement_bancaire'$$, '23514',
    'Afrique en base : aucune voie ne la passe indisponible non plus tant que CAND-Q05 est ouvert');
  PERFORM pg_temp.refus($$UPDATE public.referentiel_paiement SET pays = 'BE'
    WHERE pays = 'FR' AND methode = 'virement_bancaire'$$, '55000',
    'en base : le pays d''une ligne ne change pas, par aucune voie');
  PERFORM pg_temp.refus($$DELETE FROM public.referentiel_paiement WHERE pays = 'FR'$$, '55000',
    'en base : une ligne ne s''efface pas, elle passe indisponible');
  PERFORM pg_temp.refus($$UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'paiement.afrique_ouverte'$$,
    '42501', 'cle Afrique : le proprietaire lui-meme ne l''ouvre pas par app_config (seule la table des decisions)');
  PERFORM pg_temp.refus($$DELETE FROM public.app_config WHERE key = 'paiement.afrique_ouverte'$$, '42501',
    'cle Afrique : ne s''efface pas');
  PERFORM pg_temp.refus($$UPDATE public.app_config SET key = 'paiement.afrique_ouverte_x' WHERE key = 'paiement.afrique_ouverte'$$,
    '42501', 'cle Afrique : ne se renomme pas');
  PERFORM pg_temp.refus($$UPDATE public.referentiel_paiement_afrique_decisions SET ouverte = true$$, '55000',
    'decisions sur l''Afrique en ajout seul');
  PERFORM pg_temp.refus($$UPDATE public.referentiel_paiement_journal SET impact = '{}' WHERE id = 1$$, '55000',
    'journal du referentiel en ajout seul (modification)');
  PERFORM pg_temp.refus($$DELETE FROM public.referentiel_paiement_journal WHERE id = 1$$, '55000',
    'journal du referentiel en ajout seul (suppression)');
  PERFORM pg_temp.refus($$DELETE FROM public.candidature_paiement_decisions$$, '55000',
    'decisions de la direction en ajout seul');
END $contraintes$;

-- ------------------------------------------------------------
-- (e bis) Decisions de la direction sur les virements des fixtures (geste 24
-- du lot L2, joue par sa trace), avant toute ligne neuve de leur pays : une
-- personne en salle 3 est toujours compatible ou restreinte (R13).
-- ------------------------------------------------------------
DO $decisions$
DECLARE
  s text;
BEGIN
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, auteur_id)
  SELECT ('ca6dcccc-0000-4000-8000-0000000000' || v.s)::uuid, 'TR', 'virement_bancaire', 'confirme',
         'ca6d0000-0000-4000-8000-0000000000a1'
  FROM unnest(ARRAY['05', '06', '07', '08', '09']) AS v(s);
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000022', 'TR', 'virement_bancaire', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a2'),
         ('ca6dcccc-0000-4000-8000-000000000004', 'PK', 'virement_bancaire', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a2');
  FOREACH s IN ARRAY ARRAY['04', '05', '06', '07', '08', '09', '22'] LOOP
    PERFORM private.paiement_recalculer(('ca6dcccc-0000-4000-8000-0000000000' || s)::uuid, 'moyen_confirme',
      'ca6d0000-0000-4000-8000-0000000000a1');
  END LOOP;
  FOREACH s IN ARRAY ARRAY['20', '23', '24'] LOOP
    PERFORM private.paiement_recalculer(('ca6dcccc-0000-4000-8000-0000000000' || s)::uuid, 'reponses');
  END LOOP;
  PERFORM pg_temp.vrai((SELECT bool_and(paiement = 'compatible') FROM public.candidatures
                        WHERE right(id::text, 2) IN ('04', '05', '06', '07', '08', '09', '22')
                          AND id::text LIKE 'ca6dcccc-%'),
    'fixtures : virements turcs et pakistanais confirmes par la direction, compatibles');
END $decisions$;

-- ------------------------------------------------------------
-- (f) L6-8 : sans compte bancaire, une ligne mobile_money confirme
-- ------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000b1', 'accountant');
SELECT pg_temp.vrai(
  (public.enregistrer_ligne_referentiel_paiement(NULL, 'PH', 'mobile_money', 'op_fictif', 'prestataire_fictif', 'PHP',
     'payout_portefeuille', 'confirme', current_date, NULL, NULL, 'l6-cle-ph-0001') -> 'ligne' ->> 'etat') = 'confirme',
  'comptabilite : cree une ligne mobile money confirme aux Philippines (pays de fixture)');
SELECT pg_temp.vrai(
  (public.enregistrer_ligne_referentiel_paiement(NULL, 'TR', 'mobile_money', 'op_fictif', NULL, 'TRY',
     NULL, 'confirme', current_date, NULL, NULL, 'l6-cle-tr-mm-0001') ->> 'impact')::int = 0,
  'comptabilite : cree une ligne mobile money confirme en Turquie');
RESET ROLE;
DO $l6_8$
BEGIN
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000018', 'reponses');
  PERFORM pg_temp.vrai((SELECT paiement FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000018')
    = 'a_verifier', 'L6-8 avant decision : sans compte bancaire, l''operateur declare croise la ligne confirme : a_verifier');
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, operateur, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000018', 'PH', 'mobile_money', 'op_fictif', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a2');
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000018', 'moyen_confirme',
    'ca6d0000-0000-4000-8000-0000000000a2');
  PERFORM pg_temp.vrai(private.paiement_compatible('ca6dcccc-0000-4000-8000-000000000018')
    AND (SELECT paiement = 'compatible' AND etat = 'en_examen' FROM public.candidatures
         WHERE id = 'ca6dcccc-0000-4000-8000-000000000018'),
    'L6-8 : sans compte bancaire, mobile money confirme et moyen confirme : compatible ; controle de la transition 10 vrai');
END $l6_8$;

-- ------------------------------------------------------------
-- (g) L6-6 : une ligne passe indisponible ; salle 3, salle 2, salle d'examen
-- ------------------------------------------------------------
-- En Turquie : c05 (homme) et c07 (femme) en salle 3 n'ont que le virement ;
-- c06 a aussi le mobile money confirme par la direction ; c08 est deja en
-- restriction (piece) ; c09 en salle 2 ; c10 en examen ; c11 a completer ;
-- c12 refusee ; c21 (homme) en salle 3, virement confirme, colonne paiement
-- jamais recalculee (perimee) ; c22 (femme) en salle 3, virement et mobile
-- money declares, seul le virement confirme par la direction.
DO $fixtures_tr$
DECLARE
  s text;
BEGIN
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, operateur, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000006', 'TR', 'mobile_money', 'op_fictif', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a1');
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000006', 'moyen_confirme',
    'ca6d0000-0000-4000-8000-0000000000a1');
  FOREACH s IN ARRAY ARRAY['10', '11', '13', '14', '15', '16', '17'] LOOP
    PERFORM private.paiement_recalculer(('ca6dcccc-0000-4000-8000-0000000000' || s)::uuid, 'reponses');
  END LOOP;
  -- c21 : entree en salle 3 telle que L2 l'ecrirait, sans recalcul (colonne
  -- paiement restee inconnu).
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
  VALUES ('ca6dcccc-0000-4000-8000-000000000021', 'enseignant', 'ca6d0000-0000-4000-8000-000000000021',
          'male', 'Fixture 21', 'confirmee', NULL, 'en_cours', 'lien_public');
  INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le)
  VALUES ('ca6dcccc-0000-4000-8000-000000000021', 'v1-2026-10',
          '{"paysVersement": "TR", "compteBancaire": true}', 'candidat', now() - interval '1 day');
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000021', 'TR', 'virement_bancaire', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a1');
  PERFORM pg_temp.vrai((SELECT array_agg(right(id::text, 2) || ':' || paiement || ':' || coalesce(etat, '-') ORDER BY id)
                        FROM public.candidatures WHERE id::text LIKE 'ca6dcccc-%'
                          AND right(id::text, 2) IN ('04', '05', '06', '07', '08', '09', '10', '11', '13', '14', '15',
                                                     '16', '17', '20', '21', '22'))
    = ARRAY['04:compatible:entretien_a_planifier', '05:compatible:-', '06:compatible:-', '07:compatible:-',
            '08:compatible:-', '09:compatible:entretien_a_planifier', '10:a_verifier:en_examen',
            '11:a_verifier:a_completer', '13:a_verifier:en_examen', '14:a_verifier:en_examen',
            '15:incompatible:paiement_non_disponible', '16:a_verifier:en_examen', '17:a_verifier:en_examen',
            '20:a_verifier:en_examen', '21:inconnu:-', '22:compatible:-'],
    'fixtures : paiement calcule pour chaque candidature ; c15 (operateur sans ligne au Pakistan) deja en paiement_non_disponible ; c21 a colonne perimee');
  PERFORM pg_temp.vrai(private.paiement_etat('ca6dcccc-0000-4000-8000-000000000021') = 'compatible'
    AND private.paiement_etat('ca6dcccc-0000-4000-8000-000000000022') = 'compatible',
    'c21 et c22 compatibles en direct avant le changement');
  PERFORM set_config('test.version06', (SELECT version::text FROM public.candidatures
                                         WHERE id = 'ca6dcccc-0000-4000-8000-000000000006'), true);
  PERFORM set_config('test.version05', (SELECT version::text FROM public.candidatures
                                         WHERE id = 'ca6dcccc-0000-4000-8000-000000000005'), true);
END $fixtures_tr$;

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
SELECT set_config('test.r_tr', pg_temp.ecrire('TR', 'virement_bancaire', NULL, 'indisponible', current_date,
  'l6-cle-tr-0001', 'Banques correspondantes fermees (fixture).')::text, true);
RESET ROLE;
DO $l6_6$
DECLARE
  r jsonb := current_setting('test.r_tr')::jsonb;
  v_ligne uuid := (pg_temp.ligne('TR', 'virement_bancaire')).id;
BEGIN
  PERFORM pg_temp.vrai((r ->> 'impact')::int = 2 AND NOT r ? 'effets'
    AND r -> 'ligne' ->> 'etat' = 'indisponible' AND r -> 'ligne' ->> 'capacitePayout' = 'nonPrisEnCharge',
    'L6-6 et genre : impact rendu a la directrice = 2, les restrictions de son cote (c07, c22), aucun autre compteur');
  PERFORM pg_temp.vrai((SELECT impact FROM public.referentiel_paiement_journal WHERE cle_idempotence = 'l6-cle-tr-0001')
    = '{"restrictions": 4, "bloquees": 1, "paiementNonDisponible": 1, "aCompleter": 0, "recalculees": 9,
        "parGenre": {"female": {"restrictions": 2, "bloquees": 1, "paiementNonDisponible": 0, "aCompleter": 0, "recalculees": 4},
                     "male": {"restrictions": 2, "bloquees": 0, "paiementNonDisponible": 1, "aCompleter": 0, "recalculees": 5}}}'::jsonb,
    'L6-6 au journal : K = 4 restrictions (c05, c07, c21, c22), 1 bloquee, 1 transition 8, 9 recalculees, partage par genre');
  PERFORM pg_temp.vrai((SELECT array_agg(right(id::text, 2) ORDER BY id) FROM public.candidatures
                        WHERE id::text LIKE 'ca6dcccc-%' AND restriction_cause = 'paiement')
                       = ARRAY['05', '07', '21', '22']
    AND (SELECT bool_and(etape = 'confirmee' AND restreinte AND issue = 'en_cours' AND paiement = 'incompatible')
         FROM public.candidatures WHERE id IN ('ca6dcccc-0000-4000-8000-000000000005',
                                                'ca6dcccc-0000-4000-8000-000000000007')),
    'L6-6 et genre : restriction paiement pour c05 (homme) et c07 (femme), posee par une directrice ; etape confirmee gardee');
  PERFORM pg_temp.vrai((SELECT restreinte AND restriction_cause = 'paiement' AND paiement = 'incompatible'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000021')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000021', 'restriction',
                   jsonb_build_object('transition', 20, 'ligne', v_ligne, 'paiementAvant', 'inconnu')) = 1,
    'salle 3 a colonne perimee (c21, paiement jamais recalcule) : restreinte quand meme, le calcul en direct decide');
  PERFORM pg_temp.vrai((SELECT restreinte AND restriction_cause = 'paiement' AND paiement = 'a_verifier'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000022')
    AND (pg_temp.ligne('TR', 'mobile_money', 'op_fictif')).etat = 'confirme',
    'salle 3, deux moyens declares, seul le virement confirme par la direction (c22) : restreinte, paiement a_verifier, bien que la ligne mobile money reste confirme (lecture stricte, R13)');
  PERFORM pg_temp.vrai((SELECT NOT restreinte AND restriction_cause IS NULL AND paiement = 'compatible'
                               AND version::text = current_setting('test.version06')
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000006')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000006', 'controle', jsonb_build_object('ligne', v_ligne)) = 0,
    'L6-6 : 0 changement pour qui garde un autre moyen confirme par la direction sur une ligne confirme (c06, mobile money confirme)');
  PERFORM pg_temp.vrai((SELECT restreinte AND restriction_cause = 'piece' AND paiement = 'incompatible'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000008')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000008', 'restriction') = 0
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000008', 'controle',
                   jsonb_build_object('cause', 'referentiel', 'ligne', v_ligne, 'valeurApres', false)) = 1,
    'deja en restriction (piece) : la cause reste, le controle qui tombe est journalise, aucune restriction comptee');
  PERFORM pg_temp.vrai((SELECT etape = 'verifications' AND etat = 'entretien_a_planifier' AND NOT restreinte
                               AND paiement = 'incompatible'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000009')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000009', 'controle',
                   jsonb_build_object('cause', 'referentiel', 'controle', 'paiement_compatible',
                                      'valeurAvant', true, 'valeurApres', false)) = 1
    AND NOT private.paiement_compatible('ca6dcccc-0000-4000-8000-000000000009'),
    'salle 2 : le controle passe faux et se journalise, sans retour d''etape (bloquee)');
  PERFORM pg_temp.vrai((SELECT etat = 'paiement_non_disponible' AND paiement = 'incompatible'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000010')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000010', 'transition',
                   jsonb_build_object('transition', 8, 'cause', 'referentiel', 'ligne', v_ligne)) = 1
    AND (SELECT etat = 'a_completer' AND paiement = 'incompatible'
         FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000011')
    AND (SELECT paiement = 'inconnu' AND version = 1 FROM public.candidatures
         WHERE id = 'ca6dcccc-0000-4000-8000-000000000012'),
    'salle d''examen : en examen, transition 8 avec la ligne pour cause ; a completer, paiement seul ; refusee, intouchee');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements e
                        WHERE e.type = 'restriction' AND e.auteur_id IS NULL
                          AND e.motif_interne LIKE 'Paiement à revérifier%'
                          AND e.details @> jsonb_build_object('transition', 20, 'restrictionCause', 'paiement',
                                                              'cause', 'referentiel', 'ligne', v_ligne)) = 4
    AND (SELECT version::int FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000005')
        = current_setting('test.version05')::int + 1,
    'transition 20 automatique : 4 evenements restriction, auteur systeme, motif paiement a reverifier, cause et ligne ; version augmentee');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_effet_paiement'
                          AND payload ->> 'ligne' = v_ligne::text) = 5,
    'audit_logs : une entree par effet (4 restrictions, 1 transition 8)');
  -- R13 : la direction confirme l'autre moyen de c22 (transition 24 ouverte en
  -- salle 3 sous restriction de cause paiement, geste de L2 joue par sa trace).
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, operateur, decision, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000022', 'TR', 'mobile_money', 'op_fictif', 'confirme',
          'ca6d0000-0000-4000-8000-0000000000a2');
  PERFORM private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000022', 'moyen_confirme',
    'ca6d0000-0000-4000-8000-0000000000a2');
  PERFORM pg_temp.vrai((SELECT paiement = 'compatible' AND restreinte AND restriction_cause = 'paiement'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000022'),
    'R13 : l''autre moyen confirme en salle 3, c22 redevient compatible ; la restriction reste jusqu''a la levee par la direction (21)');
END $l6_6$;

-- L'historique de L1 rend la restriction : auteur systeme, motif, aucun nom.
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.vrai(
  (SELECT e ->> 'auteur' = 'systeme' AND e ->> 'type' = 'restriction' AND e ->> 'motif' LIKE 'Paiement à revérifier%'
   FROM jsonb_array_elements(public.historique_candidature('ca6dcccc-0000-4000-8000-000000000005') -> 'evenements') e
   LIMIT 1),
  'historique (L1) de c05 : la restriction en tete, auteur systeme, motif rendu a la direction de son cote');
SELECT pg_temp.vrai(
  (SELECT jsonb_array_length(r -> 'alertes') = 1
          AND r -> 'alertes' -> 0 ->> 'pays' = 'TR' AND r -> 'alertes' -> 0 ->> 'etatAvant' = 'confirme'
          AND r -> 'alertes' -> 0 ->> 'etatApres' = 'indisponible'
          AND r -> 'alertes' -> 0 -> 'impact' = '2'::jsonb
          AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(r -> 'alertes' -> 0) k)
              = ARRAY['etatApres', 'etatAvant', 'id', 'impact', 'ligne', 'methode', 'operateur', 'pays', 'quand']
          AND strpos((r -> 'alertes')::text, 'ca6d0000') = 0 AND strpos((r -> 'alertes')::text, 'Fixture') = 0
          AND strpos((r -> 'alertes')::text, 'recalculees') = 0 AND strpos((r -> 'alertes')::text, 'parGenre') = 0
   FROM (SELECT public.lire_referentiel_paiement() AS r) x),
  'alerte au directeur : le changement turc, impact = 2 restrictions de son cote (c05, c21), aucun autre compteur, aucun nom ni identifiant de personne');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
SELECT pg_temp.vrai((public.lire_referentiel_paiement() -> 'alertes' -> 0 -> 'impact') = '2'::jsonb,
  'alerte a la directrice : 2 restrictions de son cote (c07, c22)');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000b1', 'accountant');
SELECT pg_temp.vrai(jsonb_array_length(public.lire_referentiel_paiement() -> 'alertes') = 1
    AND (public.lire_referentiel_paiement() -> 'alertes' -> 0 -> 'impact') = '4'::jsonb,
  'alerte a la comptabilite : le meme changement, impact total 4 (8.1 : elle n''a pas de cote)');
SELECT set_config('test.sa0', (SELECT count(*)::text FROM public.audit_logs
                               WHERE action = 'referentiel_paiement_exception_super_admin'), true);
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a4', 'admin');
SELECT pg_temp.vrai((public.lire_referentiel_paiement() -> 'alertes' -> 0 -> 'impact') = '4'::jsonb,
  'alerte au super-admin (exception de 0088) : les deux cotes, impact 4');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'referentiel_paiement_exception_super_admin'
                       AND payload = '{"lecture": "alertes", "restrictionsHorsGenre": 2, "motif": "exception_super_admin_kyc"}'::jsonb)
                    = current_setting('test.sa0')::int + 1,
  'exception super-admin journalisee (C13 de L1) : 1 entree audit_logs, 2 restrictions de l''autre cote');

-- ------------------------------------------------------------
-- (h) L6-4 et L6-9 : le virement pakistanais passe en verification, puis
-- revient a confirme
-- ------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.r_pk1', pg_temp.ecrire('PK', 'virement_bancaire', NULL, 'en_verification', NULL,
  'l6-cle-pk-0001')::text, true);
RESET ROLE;
DO $l6_4$
DECLARE
  r jsonb := current_setting('test.r_pk1')::jsonb;
BEGIN
  PERFORM pg_temp.vrai((r ->> 'impact')::int = 0
    AND (SELECT impact - 'parGenre' FROM public.referentiel_paiement_journal WHERE cle_idempotence = 'l6-cle-pk-0001')
        = '{"restrictions": 0, "bloquees": 1, "paiementNonDisponible": 2, "aCompleter": 0, "recalculees": 4}'::jsonb,
    'virement pakistanais en verification : impact 0 ; au journal, c04 bloquee, c13 et c14 en transition 8');
  PERFORM pg_temp.vrai(private.paiement_etat('ca6dcccc-0000-4000-8000-000000000004') = 'incompatible'
    AND EXISTS (SELECT 1 FROM public.candidature_paiement_decisions d
                WHERE d.candidature_id = 'ca6dcccc-0000-4000-8000-000000000004' AND d.decision = 'confirme'),
    'L6-4 : une decision de confirmation anterieure ne rend pas compatible une ligne en_verification');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM public.candidatures c
      WHERE private.paiement_etat(c.id) = 'compatible'
        AND NOT EXISTS (
          SELECT 1 FROM public.referentiel_paiement l
          WHERE l.pays = private.paiement_declaration(c.id) ->> 'paysVersement' AND l.etat = 'confirme')),
    'L6-4 : 0 cas compatible sans ligne confirme du pays de versement, sur toutes les candidatures');
  PERFORM pg_temp.refus($$INSERT INTO public.candidature_paiement_decisions
      (candidature_id, pays, methode, decision, auteur_id)
    VALUES ('ca6dcccc-0000-4000-8000-000000000013', 'PK', 'virement_bancaire', 'confirme',
            'ca6d0000-0000-4000-8000-0000000000a1')$$, '23514',
    'L6-4 : confirmer un moyen sur une ligne en_verification refuse en base');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.candidatures
                        WHERE id IN ('ca6dcccc-0000-4000-8000-000000000013', 'ca6dcccc-0000-4000-8000-000000000014',
                                     'ca6dcccc-0000-4000-8000-000000000015')
                          AND etat = 'paiement_non_disponible' AND issue = 'en_cours') = 3,
    'trois candidatures du Pakistan en paiement_non_disponible, issue en_cours');
END $l6_4$;

SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
SELECT set_config('test.r_pk2', pg_temp.ecrire('PK', 'virement_bancaire', NULL, 'confirme', current_date,
  'l6-cle-pk-0002')::text, true);
RESET ROLE;
DO $l6_9$
DECLARE
  r jsonb := current_setting('test.r_pk2')::jsonb;
  v_ligne uuid := (pg_temp.ligne('PK', 'virement_bancaire')).id;
  s text;
BEGIN
  PERFORM pg_temp.vrai((r ->> 'impact')::int = 0
    AND (SELECT impact - 'parGenre' FROM public.referentiel_paiement_journal WHERE cle_idempotence = 'l6-cle-pk-0002')
        = '{"restrictions": 0, "bloquees": 0, "paiementNonDisponible": 0, "aCompleter": 3, "recalculees": 4}'::jsonb,
    'L6-9 : ligne passee confirme : 3 candidatures du pays passent a_completer (journal)');
  FOREACH s IN ARRAY ARRAY['13', '14', '15'] LOOP
    PERFORM pg_temp.vrai((SELECT etape = 'prequalification' AND etat = 'a_completer' AND issue = 'en_cours'
                          FROM public.candidatures WHERE id = ('ca6dcccc-0000-4000-8000-0000000000' || s)::uuid)
      AND pg_temp.ev(('ca6dcccc-0000-4000-8000-0000000000' || s)::uuid, 'transition',
            jsonb_build_object('transition', 9, 'cause', 'referentiel', 'ligne', v_ligne,
                               'aCompleter', jsonb_build_array('moyen_paiement'),
                               'aNotifier', 'paiement_possible')) = 1,
      'L6-9 : c' || s || ' en a_completer, moyen_paiement nomme, 1 evenement a notifier, modele paiement_possible de la liste fermee (notification et courriel : L5)');
  END LOOP;
  PERFORM pg_temp.vrai((SELECT array_agg(paiement ORDER BY id) FROM public.candidatures
                        WHERE id IN ('ca6dcccc-0000-4000-8000-000000000013', 'ca6dcccc-0000-4000-8000-000000000015'))
                       = ARRAY['a_verifier', 'incompatible'],
    'apres la transition 9 : le virement declare croise (a_verifier) ; l''operateur seul ne croise rien (incompatible), le moyen est a declarer');
  PERFORM pg_temp.vrai((SELECT paiement = 'compatible' AND etat = 'entretien_a_planifier'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000004'),
    'salle 2 : la ligne revenue, la decision de confirmation compte de nouveau (aucune levee automatique n''est en jeu)');
  PERFORM pg_temp.vrai((SELECT restreinte AND restriction_cause = 'paiement' FROM public.candidatures
                        WHERE id = 'ca6dcccc-0000-4000-8000-000000000005'),
    'aucune levee automatique d''une restriction (transition 21, geste de la direction)');
END $l6_9$;

-- ------------------------------------------------------------
-- (i) L6-10 : la seule ligne quitte confirme ; puis moyen infirme
-- ------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
SELECT set_config('test.r_gb', pg_temp.ecrire('GB', 'virement_bancaire', NULL, 'indisponible', NULL,
  'l6-cle-gb-0001')::text, true);
RESET ROLE;
DO $l6_10$
DECLARE
  v_ligne uuid := (pg_temp.ligne('GB', 'virement_bancaire')).id;
  r jsonb;
BEGIN
  PERFORM pg_temp.vrai((SELECT etat = 'paiement_non_disponible' AND paiement = 'incompatible' AND issue = 'en_cours'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000016')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000016', 'transition',
                   jsonb_build_object('transition', 8, 'cause', 'referentiel', 'ligne', v_ligne)) = 1,
    'L6-10 : candidate en examen dont la seule ligne quitte confirme : paiement_non_disponible, ligne pour cause');
  -- Geste 25 du lot L2, joue ici par sa trace : decision infirmee, puis recalcul.
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, decision, motif_interne, auteur_id)
  VALUES ('ca6dcccc-0000-4000-8000-000000000017', 'CA', 'virement_bancaire', 'infirme',
          'Compte au nom d''un tiers (fixture).', 'ca6d0000-0000-4000-8000-0000000000a1');
  r := private.paiement_recalculer('ca6dcccc-0000-4000-8000-000000000017', 'moyen_infirme',
         'ca6d0000-0000-4000-8000-0000000000a1', 'Compte au nom d''un tiers (fixture).');
  PERFORM pg_temp.vrai(r ->> 'effet' = 'paiement_non_disponible'
    AND (SELECT etat = 'paiement_non_disponible' AND paiement = 'incompatible'
         FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000017')
    AND (SELECT count(*) FROM public.candidature_evenements e
         WHERE e.candidature_id = 'ca6dcccc-0000-4000-8000-000000000017' AND e.type = 'transition'
           AND e.auteur_id = 'ca6d0000-0000-4000-8000-0000000000a1'
           AND e.motif_interne = 'Compte au nom d''un tiers (fixture).'
           AND e.details @> '{"transition": 8, "cause": "moyen_infirme"}') = 1,
    'L6-10 : moyen infirme par la direction : paiement_non_disponible, motif et auteur traces');
  PERFORM pg_temp.vrai((SELECT pg_get_functiondef('private.cand_ma_candidature()'::regprocedure) NOT LIKE '%motif%'),
    'le motif interne ne sort pas vers l''etat du candidat (brique de L1 sans motif)');
END $l6_10$;

-- ------------------------------------------------------------
-- (i bis) Ecriture directe (editeur SQL, migration) : les memes effets
-- ------------------------------------------------------------
SELECT pg_temp.qui(NULL, NULL);
SELECT set_config('test.de_version', (pg_temp.ligne('DE', 'virement_bancaire')).version::text, true);
SELECT set_config('test.de_journal', (SELECT count(*)::text FROM public.referentiel_paiement_journal), true);
UPDATE public.referentiel_paiement SET etat = 'indisponible', notes = 'Ecriture directe (fixture).'
WHERE pays = 'DE' AND methode = 'virement_bancaire';
DO $directe$
DECLARE
  v_ligne public.referentiel_paiement := pg_temp.ligne('DE', 'virement_bancaire');
BEGIN
  PERFORM pg_temp.vrai((SELECT etat = 'paiement_non_disponible' AND paiement = 'incompatible'
                        FROM public.candidatures WHERE id = 'ca6dcccc-0000-4000-8000-000000000020')
    AND pg_temp.ev('ca6dcccc-0000-4000-8000-000000000020', 'transition',
                   jsonb_build_object('transition', 8, 'cause', 'referentiel', 'ligne', v_ligne.id)) = 1,
    'ecriture directe (sans RPC) : la ligne quitte confirme, c20 passe en transition 8 avec la ligne pour cause');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement_journal)
                         = current_setting('test.de_journal')::int + 1
    AND (SELECT auteur_id IS NULL AND cle_idempotence IS NULL AND avant ->> 'etat' = 'confirme'
                AND apres ->> 'etat' = 'indisponible' AND (impact ->> 'paiementNonDisponible')::int = 1
         FROM public.referentiel_paiement_journal WHERE ligne_id = v_ligne.id ORDER BY id DESC LIMIT 1)
    AND v_ligne.version = current_setting('test.de_version')::int + 1
    AND (SELECT payload ->> 'voie' FROM public.audit_logs WHERE action = 'referentiel_paiement_ecriture'
           AND row_id = v_ligne.id::text ORDER BY created_at DESC, id DESC LIMIT 1) = 'directe',
    'ecriture directe : 1 ligne de journal sans auteur ni cle, effets comptes, version augmentee, audit voie directe');
END $directe$;

-- ------------------------------------------------------------
-- (j) L6-7 : le candidat lit les options de son pays de versement
-- ------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-000000000001', 'teacher');
DO $l6_7$
DECLARE
  r jsonb;
BEGIN
  r := public.options_paiement_confirmees('TR');
  PERFORM pg_temp.vrai(r = '{"pays": "TR", "lignes": [{"methode": "mobile_money", "operateur": "op_fictif",
                              "operateurNom": "Operateur fictif", "devise": "TRY"}]}'::jsonb,
    'L6-7 : en Turquie, la seule ligne confirme (le virement indisponible n''apparait pas)');
  r := public.options_paiement_confirmees('FR');
  PERFORM pg_temp.vrai(jsonb_array_length(r -> 'lignes') = 1 AND NOT (r::text LIKE '%SEPA%')
    AND NOT (r -> 'lignes' -> 0 ? 'notes') AND NOT (r -> 'lignes' -> 0 ? 'prestataire')
    AND NOT (r -> 'lignes' -> 0 ? 'verifiePar') AND NOT (r -> 'lignes' -> 0 ? 'source')
    AND r -> 'lignes' -> 0 = '{"methode": "virement_bancaire", "operateur": null, "operateurNom": null, "devise": "EUR"}'::jsonb,
    'L6-7 : 0 note interne, 0 prestataire, 0 source, 0 nom ; quatre cles seulement');
  PERFORM pg_temp.vrai(public.options_paiement_confirmees('NG') = '{"pays": "NG", "lignes": []}'::jsonb
    AND public.options_paiement_confirmees('GB') = '{"pays": "GB", "lignes": []}'::jsonb,
    'L6-7 : 0 ligne non confirmee (Nigeria en verification, Royaume-Uni indisponible) : liste vide, l''ecran dit la phrase');
  PERFORM pg_temp.refus($$SELECT public.options_paiement_confirmees('tr')$$, '22023', 'pays mal forme refuse');
END $l6_7$;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000b1', 'accountant');
SELECT pg_temp.vrai((SELECT array_agg(l ->> 'methode' ORDER BY n) FROM jsonb_array_elements(
                       public.options_paiement_confirmees('PH') -> 'lignes') WITH ORDINALITY AS t(l, n))
                     = ARRAY['virement_bancaire', 'mobile_money'],
  'comptabilite : lit les options d''un pays (apercu de l''ecran du candidat), virement d''abord');
RESET ROLE;

-- ------------------------------------------------------------
-- (k) Afrique : seule la decision du directeur ouvre la confirmation
-- ------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a1', 'admin');
SELECT pg_temp.refus($$UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'paiement.afrique_ouverte'$$,
  '42501', 'cle Afrique : une direction active (aal1) ne l''ouvre pas par une ecriture directe dans app_config');
SELECT pg_temp.refus($$INSERT INTO public.app_config (key, value) VALUES ('paiement.afrique_ouverte', 'true'::jsonb)
  ON CONFLICT (key) DO UPDATE SET value = excluded.value$$,
  '42501', 'cle Afrique : ni par une insertion');
SELECT pg_temp.refus($$INSERT INTO public.referentiel_paiement_afrique_decisions (ouverte, decision_ref, decide_le)
  VALUES (true, 'DEC:essai', current_date)$$, '42501',
  'decisions sur l''Afrique : aucune ecriture par un compte');
SELECT pg_temp.vrai((pg_temp.ecrire('SN', 'mobile_money', 'wave', 'en_verification', NULL, 'l6-cle-sn-wave-0001')
                      -> 'ligne' ->> 'etat') = 'en_verification',
  'CAND-Q05 ouvert : une ligne d''Afrique neuve se cree, en verification seulement');
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a4', 'admin');
SELECT pg_temp.vrai((pg_temp.ecrire('SN', 'virement_bancaire', NULL, 'confirme', current_date, 'l6-cle-sn-super-0001')
                      ->> 'erreur') = 'afrique_en_verification',
  'CAND-Q05 ouvert : le super-admin ne confirme pas non plus une ligne d''Afrique');
RESET ROLE;
SELECT pg_temp.qui(NULL, NULL);
-- La decision datee du directeur, ecrite par le proprietaire (migration ou
-- editeur SQL) : la cle suit.
INSERT INTO public.referentiel_paiement_afrique_decisions (ouverte, decision_ref, decide_le)
VALUES (true, 'DEC:fixture (decision de test, CAND-Q05 tranche)', current_date);
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'paiement.afrique_ouverte') = 'true'::jsonb
    AND private.paiement_afrique_ouverte()
    AND (SELECT enregistre_par FROM public.referentiel_paiement_afrique_decisions ORDER BY id DESC LIMIT 1)
        = session_user::text,
  'decision du directeur enregistree par le proprietaire : la cle passe a true, l''auteur de session est garde');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
SELECT pg_temp.vrai(
  (pg_temp.ecrire('SN', 'virement_bancaire', NULL, 'confirme', current_date, 'l6-cle-sn-0001') -> 'ligne' ->> 'etat')
    = 'confirme'
  AND (public.lire_referentiel_paiement('SN') ->> 'afriqueEnVerification')::boolean IS FALSE,
  'CAND-Q05 tranche (decision datee) : une ligne d''Afrique peut passer confirme');
RESET ROLE;
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.refus($$INSERT INTO public.referentiel_paiement_afrique_decisions (ouverte, decision_ref, decide_le)
  VALUES (false, 'DEC:fixture (refermeture)', current_date)$$, '23514',
  'refermer l''Afrique est refuse tant qu''une ligne d''Afrique est confirme (jamais cle fermee et ligne confirme)');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui('ca6d0000-0000-4000-8000-0000000000a2', 'admin');
SELECT pg_temp.vrai(
  (pg_temp.ecrire('SN', 'virement_bancaire', NULL, 'en_verification', NULL, 'l6-cle-sn-0002') -> 'ligne' ->> 'etat')
    = 'en_verification',
  'avant de refermer : la ligne du Senegal revient en verification par la RPC');
RESET ROLE;
SELECT pg_temp.qui(NULL, NULL);
INSERT INTO public.referentiel_paiement_afrique_decisions (ouverte, decision_ref, decide_le)
VALUES (false, 'DEC:fixture (refermeture)', current_date);
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'paiement.afrique_ouverte') = 'false'::jsonb
    AND NOT private.paiement_afrique_ouverte()
    AND (SELECT count(*) FROM public.app_config_history WHERE key = 'paiement.afrique_ouverte') = 2
    AND NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l JOIN public.referentiel_paiement_afrique a
                    ON a.pays = l.pays WHERE l.etat <> 'en_verification'),
  'refermee : cle a false, deux changements dans app_config_history, toutes les lignes d''Afrique en verification');

-- ------------------------------------------------------------
-- (l) Journal : une ligne par ecriture, une entree d'audit par ecriture
-- ------------------------------------------------------------
DO $journal$
BEGIN
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.referentiel_paiement_journal WHERE auteur_id IS NOT NULL) = 10
    AND (SELECT count(*) FROM public.audit_logs WHERE action = 'referentiel_paiement_ecriture') = 11
    AND (SELECT count(*) FROM public.audit_logs WHERE action = 'referentiel_paiement_ecriture'
           AND payload ->> 'voie' = 'directe') = 1
    AND (SELECT count(DISTINCT cle_idempotence) FROM public.referentiel_paiement_journal) = 10,
    'journal : 10 ecritures par la RPC a cle unique et 1 ecriture directe ; 11 entrees audit_logs');
  PERFORM pg_temp.vrai((SELECT array_agg(DISTINCT p.role::text ORDER BY p.role::text)
                        FROM public.referentiel_paiement_journal j JOIN public.profiles p ON p.id = j.auteur_id)
                       = ARRAY['accountant', 'admin'],
    'auteurs : direction et comptabilite');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM public.candidatures c
      WHERE c.id::text LIKE 'ca6dcccc-%' AND c.issue = 'en_cours' AND c.profile_id IS NOT NULL
        AND c.paiement IS DISTINCT FROM private.paiement_etat(c.id)),
    'la colonne paiement de chaque candidature recalculee egale le calcul en direct');
END $journal$;

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 146 THEN
    RAISE EXCEPTION 'CAND-L6 ROUGE : % controles executes, 146 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L6 referentiel de paiement : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
