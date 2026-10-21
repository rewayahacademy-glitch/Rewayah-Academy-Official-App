-- CAND-L1 : socle des candidatures (tables, cloisonnement par genre, cinq RPC
-- de lecture de la direction, brique privee de l'etat du candidat). Migration
-- 20261021200000_cand_l1_socle_candidatures.sql.
-- Chaque garde a un controle de refus ; chaque controle leve
-- 'CAND-L1 ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE (stub_auth
-- puis toutes les migrations) ; le scenario pose ses propres fixtures et
-- annule tout a la fin.
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
    RAISE EXCEPTION 'CAND-L1 ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CAND-L1 ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'CAND-L1 ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Les identifiants des lignes d'une page, dans l'ordre rendu.
CREATE FUNCTION pg_temp.ids(p_page jsonb) RETURNS uuid[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg((l ->> 'id')::uuid ORDER BY n), '{}')
  FROM jsonb_array_elements(p_page -> 'lignes') WITH ORDINALITY AS t(l, n);
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text),
  pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text), pg_temp.ids(jsonb)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction au genre inconnu,
-- a4 super-admin (femme), a5 direction desactivee, a6 direction homme non
-- nommee pour le contact ; c1 a c4 comptes enseignants en attente
-- (pending_kyc) ; c5 enseignante sans candidature, c6 compte au genre inconnu,
-- c7 a c9 enseignants pour l'indisponibilite ; g1 tuteur actif.
INSERT INTO auth.users (id, email) VALUES
 ('ca1d0000-0000-4000-8000-0000000000a1', 'cand-adm-h@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000a2', 'cand-adm-f@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000a3', 'cand-adm-x@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000a4', 'cand-super@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000a5', 'cand-adm-off@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000a6', 'cand-adm-h2@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c1', 'cand-c1@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c2', 'cand-c2@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c3', 'cand-c3@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c4', 'cand-c4@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c5', 'cand-c5@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c6', 'cand-c6@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c7', 'cand-c7@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c8', 'cand-c8@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000c9', 'cand-c9@test.invalid'),
 ('ca1d0000-0000-4000-8000-0000000000e1', 'cand-tuteur@test.invalid');
INSERT INTO public.households (id, timezone)
VALUES ('ca1dffff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('ca1d0000-0000-4000-8000-0000000000a1', 'CA1-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000a2', 'CA1-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 ('ca1d0000-0000-4000-8000-0000000000a3', 'CA1-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 ('ca1d0000-0000-4000-8000-0000000000a4', 'CA1-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'female'),
 ('ca1d0000-0000-4000-8000-0000000000a5', 'CA1-ADM-0005', 'admin', NULL, 'Direction', 'Desactivee', 'disabled', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000a6', 'CA1-ADM-0006', 'admin', NULL, 'Direction', 'NonNommee', 'active', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000c1', 'CA1-ENS-0001', 'teacher', NULL, 'Maryam', 'Exemple', 'pending_kyc', 'female'),
 ('ca1d0000-0000-4000-8000-0000000000c2', 'CA1-ENS-0002', 'teacher', NULL, 'Ahmad', 'Zeta', 'pending_kyc', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000c3', 'CA1-ENS-0003', 'teacher', NULL, 'Fatima', 'Verif', 'pending_kyc', 'female'),
 ('ca1d0000-0000-4000-8000-0000000000c4', 'CA1-ENS-0004', 'teacher', NULL, 'Omar', 'Alpha', 'pending_kyc', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000c5', 'CA1-ENS-0005', 'teacher', NULL, 'Sara', 'Rattachee', 'pending_kyc', 'female'),
 ('ca1d0000-0000-4000-8000-0000000000c6', 'CA1-ENS-0006', 'teacher', NULL, 'Sans', 'Genre', 'pending_kyc', NULL),
 ('ca1d0000-0000-4000-8000-0000000000c7', 'CA1-ENS-0007', 'teacher', NULL, 'Idris', 'Ouvert', 'pending_kyc', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000c8', 'CA1-ENS-0008', 'teacher', NULL, 'Ilyas', 'Jour', 'pending_kyc', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000c9', 'CA1-ENS-0009', 'teacher', NULL, 'Hamza', 'Passe', 'pending_kyc', 'male'),
 ('ca1d0000-0000-4000-8000-0000000000e1', 'CA1-TUT-0001', 'guardian', 'ca1dffff-ffff-4fff-8fff-000000000001',
  'Tuteur', 'Essai', 'active', 'female');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('ca1d0000-0000-4000-8000-0000000000a4');
-- La direction nommee pour le contact : a1, a2 et la super-admin ; pas a6.
INSERT INTO private.candidature_lecteurs_contact (profile_id) VALUES
 ('ca1d0000-0000-4000-8000-0000000000a1'), ('ca1d0000-0000-4000-8000-0000000000a2'),
 ('ca1d0000-0000-4000-8000-0000000000a4');
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Candidatures. Hommes : K1 (importee, sans compte, recue), K3 (recue,
-- refusee), K4 (confirmee, indisponible), K5 (prequalification a completer,
-- en pause). Femmes : K2 (prequalification a completer, lien public), K6
-- (invitee, sans compte), K7 (verifications, decision en attente).
INSERT INTO public.candidatures
  (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, reprise_le,
   indisponible, indisponible_jusqu_au, paiement, source, source_ref, pays_residence, recue_le, derniere_activite)
VALUES
 ('ca1dcccc-0000-4000-8000-000000000001', 'enseignant', NULL, 'male', 'Yusuf Fictif',
  'recue', NULL, 'en_cours', false, NULL, false, NULL, 'inconnu', 'import', 'classeurA1:onglet1:2025-03-02T10:00',
  NULL, now() - interval '10 days', now() - interval '1 day'),
 ('ca1dcccc-0000-4000-8000-000000000002', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c1', 'female',
  'Élodie Maryam Exemple', 'prequalification', 'a_completer', 'en_cours', false, NULL, false, NULL, 'a_verifier',
  'lien_public', NULL, 'MA', now() - interval '6 days', now() - interval '4 hours'),
 ('ca1dcccc-0000-4000-8000-000000000003', 'enseignant', NULL, 'male', 'Bilal Essai',
  'recue', NULL, 'refusee', false, NULL, false, NULL, 'inconnu', 'import', 'classeurA1:onglet1:2025-03-05T11:00',
  NULL, now() - interval '9 days', now() - interval '8 days'),
 ('ca1dcccc-0000-4000-8000-000000000004', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c2', 'male',
  'Ahmad Zeta', 'confirmee', NULL, 'en_cours', false, NULL, true, current_date + 10, 'compatible',
  'lien_public', NULL, 'FR', now() - interval '30 days', now() - interval '2 days'),
 ('ca1dcccc-0000-4000-8000-000000000005', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c4', 'male',
  'Omar Alpha', 'prequalification', 'a_completer', 'en_cours', true, current_date + 30, false, NULL, 'inconnu',
  'lien_public', NULL, NULL, now() - interval '5 days', now() - interval '3 days'),
 ('ca1dcccc-0000-4000-8000-000000000006', 'enseignant', NULL, 'female', 'Khadija Invitee',
  'invitee', NULL, 'en_cours', false, NULL, false, NULL, 'inconnu', 'invitation', NULL,
  NULL, now() - interval '2 days', now() - interval '2 days'),
 ('ca1dcccc-0000-4000-8000-000000000007', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c3', 'female',
  'Fatima Verif', 'verifications', 'decision_en_attente', 'en_cours', false, NULL, false, NULL, 'compatible',
  'lien_public', NULL, 'GB', now() - interval '20 days', now() - interval '6 days');
-- K3 : un numero tape dans la colonne du courriel et un numero national,
-- gardes tels quels (MAPPAGE_IMPORT_FORMULAIRES.md section 4).
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone, courriel_brut, telephone_brut) VALUES
 ('ca1dcccc-0000-4000-8000-000000000001', 'yusuf.essai@test.invalid', '+33600000001', NULL, NULL),
 ('ca1dcccc-0000-4000-8000-000000000002', 'maryam.exemple@test.invalid', NULL, NULL, NULL),
 ('ca1dcccc-0000-4000-8000-000000000003', NULL, NULL, '0612345678', '0612345678'),
 ('ca1dcccc-0000-4000-8000-000000000004', NULL, '+212600000004', NULL, NULL);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, soumis_le) VALUES
 ('ca1dcccc-0000-4000-8000-000000000001', 'formulaire-A1', '{"memorisation": "10 hizb"}', 'import', now() - interval '10 days'),
 ('ca1dcccc-0000-4000-8000-000000000002', 'formulaire-A2', '{"langues": ["fr"]}', 'import', now() - interval '6 days'),
 ('ca1dcccc-0000-4000-8000-000000000002', 'v1-2026-10', '{"paysResidence": "MA"}', 'candidat', now() - interval '1 day');
-- Historique de K2 : creation (systeme), transition (la candidate), responsable (direction).
INSERT INTO public.candidature_evenements
  (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, auteur_id, motif_interne, cree_le)
VALUES
 ('ca1dcccc-0000-4000-8000-000000000002', 'creee', NULL, 'invitee', NULL, NULL, NULL, NULL, now() - interval '6 days'),
 ('ca1dcccc-0000-4000-8000-000000000002', 'transition', 'invitee', 'prequalification', NULL, 'a_completer',
  'ca1d0000-0000-4000-8000-0000000000c1', NULL, now() - interval '5 days'),
 ('ca1dcccc-0000-4000-8000-000000000002', 'responsable', NULL, NULL, NULL, NULL,
  'ca1d0000-0000-4000-8000-0000000000a2', 'suivi confie a la direction', now() - interval '4 days');

SELECT set_config('test.ref1', (SELECT reference FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000001'), true);
SELECT set_config('test.ref2', (SELECT reference FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000002'), true);

-- ------------------------------------------------------------
-- (a) Tables : RLS, aucun privilege client, aucune policy
-- ------------------------------------------------------------
DO $tables$
DECLARE
  t regclass;
  r text;
BEGIN
  FOREACH t IN ARRAY ARRAY['public.candidature_types'::regclass, 'public.candidatures'::regclass,
                           'public.candidature_contacts'::regclass, 'public.candidature_reponses'::regclass,
                           'public.candidature_evenements'::regclass,
                           'private.candidature_lecteurs_contact'::regclass] LOOP
    IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = t) THEN
      RAISE EXCEPTION 'CAND-L1 ROUGE : RLS inactive sur %', t;
    END IF;
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_table_privilege(r, t, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-L1 ROUGE : % a un privilege sur %', r, t;
      END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM pg_policies p JOIN pg_class c ON c.oid = t
               WHERE p.schemaname = c.relnamespace::regnamespace::text AND p.tablename = c.relname) THEN
      RAISE EXCEPTION 'CAND-L1 ROUGE : une policy ouvre %', t;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('six tables (dont la direction nommee) : RLS active, aucun privilege pour anon, authenticated, service_role, agent_ro, aucune policy');
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF has_sequence_privilege(r, 'public.candidatures_reference_seq', 'USAGE,SELECT,UPDATE')
       OR has_sequence_privilege(r, 'public.candidature_evenements_id_seq', 'USAGE,SELECT,UPDATE') THEN
      RAISE EXCEPTION 'CAND-L1 ROUGE : % a un privilege sur une sequence des candidatures', r;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('sequences des candidatures fermees aux comptes');
END $tables$;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT count(*) FROM public.candidatures$$, '42501', 'direction : aucune lecture directe de la table');
SELECT pg_temp.refus($$SELECT count(*) FROM public.candidature_contacts$$, '42501', 'direction : aucune lecture directe des contacts');
SELECT pg_temp.refus($$INSERT INTO public.candidature_evenements (candidature_id, type)
  VALUES ('ca1dcccc-0000-4000-8000-000000000001', 'controle')$$, '42501', 'direction : aucune ecriture directe dans le journal');
RESET ROLE;

-- ------------------------------------------------------------
-- (j) F86 : cinq RPC DEFINER, aides internes fermees, aucune lecture publique
-- de l'etat du candidat
-- ------------------------------------------------------------
DO $f86$
DECLARE
  f regprocedure;
  r text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.capacites_candidatures()'::regprocedure,
                           'public.lister_candidatures(jsonb,text,integer)'::regprocedure,
                           'public.lire_candidature(uuid)'::regprocedure,
                           'public.lire_contact_candidature(uuid)'::regprocedure,
                           'public.historique_candidature(uuid,bigint,integer)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                   AND coalesce(proconfig @> ARRAY['search_path=""'], false)
            FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-L1 ROUGE : DEFINER, proprietaire, search_path, empreinte ou ACL de %', f;
    END IF;
    IF app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f)) THEN
      RAISE EXCEPTION 'CAND-L1 ROUGE : garde negative dans %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('cinq RPC : DEFINER postgres, search_path vide, empreinte reelle, authenticated seul, garde positive');
  IF (SELECT array_agg(provolatile::text ORDER BY proname) FROM pg_proc
      WHERE pronamespace = 'public'::regnamespace
        AND proname IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature',
                        'lire_contact_candidature', 'historique_candidature'))
     IS DISTINCT FROM ARRAY['s', 'v', 'v', 'v', 'v'] THEN
    RAISE EXCEPTION 'CAND-L1 ROUGE : volatilite inattendue';
  END IF;
  PERFORM pg_temp.ok('capacites STABLE, les quatre lectures journalisees VOLATILE');
  IF to_regprocedure('public.ma_candidature()') IS NOT NULL
     OR EXISTS (SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
                AND proname LIKE '%candidature%' AND has_function_privilege('authenticated', oid, 'EXECUTE')
                AND proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature',
                                    'lire_contact_candidature', 'historique_candidature')) THEN
    RAISE EXCEPTION 'CAND-L1 ROUGE : une lecture publique de l''etat du candidat double etat_dossier()';
  END IF;
  PERFORM pg_temp.ok('aucune lecture publique de l''etat du candidat : etat_dossier() reste la seule source (contrat, section 3)');
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p
           WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'cand\_%' LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_function_privilege(r, f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L1 ROUGE : aide interne % executable par %', f, r;
      END IF;
    END LOOP;
  END LOOP;
  IF (SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace AND proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-L1 ROUGE : neuf aides internes attendues';
  END IF;
  PERFORM pg_temp.ok('neuf aides internes, executables par aucun compte');
END $f86$;

SET LOCAL ROLE anon;
SELECT pg_temp.refus($$SELECT public.lister_candidatures()$$, '42501', 'anon : liste refusee');
SELECT pg_temp.refus($$SELECT private.cand_ma_candidature()$$, '42501', 'anon : brique de l''etat du candidat fermee');
RESET ROLE;

-- ------------------------------------------------------------
-- (b) Capacites par appelant
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.capacites_candidatures() = '{"peutLire": true, "peutVoirContact": true,
  "peutLireHorsGenre": false, "genreLecteurConnu": true, "peutDecider": false, "peutImporter": false,
  "doubleVerificationRequise": false, "peutMenerEntretien": false, "peutEcrireReferentiel": false}'::jsonb,
  'direction homme nommee aal1 : lit son cote et le contact, aucun geste ni double verification promis');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal2');
SELECT pg_temp.vrai((public.capacites_candidatures() ->> 'doubleVerificationRequise') = 'false'
  AND (public.capacites_candidatures() ->> 'peutImporter') = 'false'
  AND (public.capacites_candidatures() ->> 'peutLire') = 'true',
  'direction homme aal2 : monter en aal2 n''ouvre rien, la double verification n''est donc jamais demandee');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a6', 'admin', 'aal2');
SELECT pg_temp.vrai((public.capacites_candidatures() ->> 'peutLire') = 'true'
  AND (public.capacites_candidatures() ->> 'peutVoirContact') = 'false',
  'direction homme non nommee : lit son cote, pas le contact');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a2', 'admin', 'aal2');
SELECT pg_temp.vrai((public.capacites_candidatures() ->> 'peutLire') = 'true'
  AND (public.capacites_candidatures() ->> 'peutLireHorsGenre') = 'false',
  'direction femme : lit son cote, pas l''autre');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a3', 'admin', 'aal2');
SELECT pg_temp.vrai((public.capacites_candidatures() ->> 'peutLire') = 'false'
  AND (public.capacites_candidatures() ->> 'peutVoirContact') = 'false'
  AND (public.capacites_candidatures() ->> 'genreLecteurConnu') = 'false',
  'direction au genre inconnu : ne lit rien');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a4', 'admin', 'aal2');
SELECT pg_temp.vrai((public.capacites_candidatures() ->> 'peutLire') = 'true'
  AND (public.capacites_candidatures() ->> 'peutLireHorsGenre') = 'true',
  'super-admin : lit les deux cotes');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a5', 'admin', 'aal1');
SELECT pg_temp.vrai((public.capacites_candidatures() ->> 'peutLire') = 'false'
  AND (public.capacites_candidatures() ->> 'doubleVerificationRequise') = 'false',
  'direction desactivee : aucune capacite');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000e1', 'guardian', 'aal1');
SELECT pg_temp.vrai(public.capacites_candidatures() = '{"peutLire": false, "peutVoirContact": false,
  "peutLireHorsGenre": false, "genreLecteurConnu": false, "peutDecider": false, "peutImporter": false,
  "doubleVerificationRequise": false, "peutMenerEntretien": false, "peutEcrireReferentiel": false}'::jsonb,
  'tuteur : aucune capacite');
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.refus($$SELECT public.capacites_candidatures()$$, '42501', 'sans session : capacites refusees');
RESET ROLE;

-- ------------------------------------------------------------
-- (c) Lister : portee, compteurs, filtres, tri, pages
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $liste_homme$
DECLARE r jsonb;
BEGIN
  r := public.lister_candidatures();
  PERFORM pg_temp.vrai((r ->> 'total')::int = 4 AND (r ->> 'page')::int = 1 AND (r ->> 'taillePage')::int = 50
    AND pg_temp.ids(r) = ARRAY['ca1dcccc-0000-4000-8000-000000000001', 'ca1dcccc-0000-4000-8000-000000000004',
                               'ca1dcccc-0000-4000-8000-000000000005', 'ca1dcccc-0000-4000-8000-000000000003']::uuid[],
    'direction homme : ses quatre candidatures, derniere activite d''abord (tri par defaut)');
  PERFORM pg_temp.vrai(r -> 'compteursEtapes' = '{"recue": 1, "invitee": 0, "prequalification": 1,
    "verifications": 0, "confirmee": 1}'::jsonb,
    'direction homme : compteurs d''etape en cours de son cote (la refusee exclue)');
  PERFORM pg_temp.vrai(r -> 'compteursAlertes' = '{"informationsManquantes": 0, "confirmeesIndisponibles": 1,
    "entretiensEnRetard": null, "bloquees": null}'::jsonb,
    'direction homme : alertes (la candidature en pause hors compte), deux alertes null et non 0');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(r -> 'lignes') l
      WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(l) k) IS DISTINCT FROM
            (SELECT array_agg(x ORDER BY x) FROM unnest(ARRAY['id', 'reference', 'nomComplet', 'type',
              'etape', 'etat', 'issue', 'enPause', 'repriseLe', 'restreinte', 'indisponible',
              'indisponibleJusquAu', 'paiement', 'paysResidence', 'responsableId', 'courrielAObtenir',
              'indicatifAConfirmer', 'derniereActivite', 'recueLe']) x)),
    'chaque ligne porte exactement les dix-neuf cles du contrat');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(r -> 'lignes') l
      WHERE l ? 'courriel' OR l ? 'telephone' OR l ? 'genre' OR l ? 'sourceRef')
    AND strpos(r::text, '@') = 0 AND strpos(r::text, '+33600000001') = 0
    AND strpos(r::text, '0612345678') = 0,
    'aucune ligne ne porte courriel, telephone (valide ou brut), genre ni reference source');
  PERFORM pg_temp.vrai((SELECT jsonb_object_agg(l ->> 'id', jsonb_build_array(l -> 'courrielAObtenir',
                                 l -> 'indicatifAConfirmer', l -> 'indisponible'))
                        FROM jsonb_array_elements(r -> 'lignes') l) =
    jsonb_build_object('ca1dcccc-0000-4000-8000-000000000001', '[false, false, false]'::jsonb,
                       'ca1dcccc-0000-4000-8000-000000000003', '[true, true, false]'::jsonb,
                       'ca1dcccc-0000-4000-8000-000000000004', '[true, false, true]'::jsonb,
                       'ca1dcccc-0000-4000-8000-000000000005', '[true, false, false]'::jsonb),
    'marques calculees au serveur : courriel a obtenir (absent ou mal forme), indicatif a confirmer, indisponible');
  PERFORM pg_temp.vrai((SELECT bool_and(l ->> 'derniereActivite' ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$'
                                    AND l ->> 'recueLe' ~ 'Z$')
                        FROM jsonb_array_elements(r -> 'lignes') l),
    'instants de la liste en UTC, suffixe Z');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{}', 'recente', 1)) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000005', 'ca1dcccc-0000-4000-8000-000000000003',
          'ca1dcccc-0000-4000-8000-000000000001', 'ca1dcccc-0000-4000-8000-000000000004']::uuid[],
    'tri recente : reception la plus recente d''abord');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{}', 'nom', 1)) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000004', 'ca1dcccc-0000-4000-8000-000000000003',
          'ca1dcccc-0000-4000-8000-000000000005', 'ca1dcccc-0000-4000-8000-000000000001']::uuid[],
    'tri nom : ordre alphabetique');
  r := public.lister_candidatures('{"etape": "recue"}');
  PERFORM pg_temp.vrai((r ->> 'total')::int = 2 AND pg_temp.ids(r) = ARRAY['ca1dcccc-0000-4000-8000-000000000001',
    'ca1dcccc-0000-4000-8000-000000000003']::uuid[]
    AND r -> 'compteursEtapes' ->> 'prequalification' = '1',
    'filtre etape : total du filtre, compteurs d''etape sans les filtres');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"issue": "refusee"}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000003']::uuid[], 'filtre issue');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"enPause": true}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000005']::uuid[]
    AND (public.lister_candidatures('{"enPause": false}') ->> 'total')::int = 3, 'filtre pause');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"paiement": "compatible"}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000004']::uuid[], 'filtre paiement');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"paysResidence": "FR"}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000004']::uuid[], 'filtre pays de residence');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"etat": "a_completer"}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000005']::uuid[], 'filtre etat');
  PERFORM pg_temp.vrai((public.lister_candidatures('{"type": "enseignant"}') ->> 'total')::int = 4
    AND pg_temp.ids(public.lister_candidatures('{"etape": "recue", "issue": "en_cours"}')) =
        ARRAY['ca1dcccc-0000-4000-8000-000000000001']::uuid[],
    'filtre type, et filtres combines');
  PERFORM pg_temp.vrai((public.lister_candidatures('{"etape": null, "recherche": "   "}') ->> 'total')::int = 4,
    'une cle a null et une recherche vide ne filtrent rien');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures(
      jsonb_build_object('recherche', lower(current_setting('test.ref1'))))) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000001']::uuid[], 'recherche par reference exacte, casse ignoree');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"recherche": "  Yusuf.ESSAI@test.invalid "}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000001']::uuid[], 'recherche par courriel exact');
  PERFORM pg_temp.vrai((public.lister_candidatures('{"recherche": "0612345678"}') ->> 'total')::int = 0,
    'un courriel mal forme garde tel quel n''est pas une cle de recherche');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"recherche": "fict"}')) =
    ARRAY['ca1dcccc-0000-4000-8000-000000000001']::uuid[], 'recherche par nom partiel');
  PERFORM pg_temp.vrai((public.lister_candidatures('{"recherche": "maryam.exemple@test.invalid"}') ->> 'total')::int = 0
    AND (public.lister_candidatures('{"recherche": "Maryam"}') ->> 'total')::int = 0
    AND (public.lister_candidatures(jsonb_build_object('recherche', current_setting('test.ref2'))) ->> 'total')::int = 0,
    'recherche hors portee : rien, ni par courriel, ni par nom, ni par reference');
  PERFORM pg_temp.vrai((public.lister_candidatures('{"recherche": "%"}') ->> 'total')::int = 0
    AND (public.lister_candidatures('{"recherche": "_"}') ->> 'total')::int = 0,
    'recherche : % et _ ne sont pas des jokers');
  PERFORM pg_temp.vrai((public.lister_candidatures('{}', 'activite', 2) ->> 'total')::int = 4
    AND jsonb_array_length(public.lister_candidatures('{}', 'activite', 2) -> 'lignes') = 0
    AND (public.lister_candidatures('{}', 'activite', 2) ->> 'page')::int = 2,
    'page au-dela de la fin : aucune ligne, total reel');
END $liste_homme$;

SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"inconnu": "x"}')$$, '22023', 'cle de filtre inconnue');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"telephone": "+33600000001"}')$$, '22023', 'recherche par telephone absente de ce lot');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"etape": "salle3"}')$$, '22023', 'etape invalide');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"etat": "en_pause"}')$$, '22023', 'etat invalide');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"issue": "acceptee"}')$$, '22023', 'issue invalide');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"paiement": "stripe"}')$$, '22023', 'paiement invalide');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"paysResidence": "fr"}')$$, '22023', 'pays invalide');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"type": "comptable"}')$$, '22023', 'type inconnu');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"enPause": "oui"}')$$, '22023', 'pause mal typee');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{"etape": 3}')$$, '22023', 'etape mal typee');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('["recue"]')$$, '22023', 'filtre qui n''est pas un objet');
SELECT pg_temp.refus($$SELECT public.lister_candidatures(jsonb_build_object('recherche', repeat('a', 201)))$$, '22023', 'recherche trop longue');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{}', 'score', 1)$$, '22023', 'tri inconnu');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{}', NULL, 1)$$, '22023', 'tri absent');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{}', 'activite', 0)$$, '22023', 'page 0');
SELECT pg_temp.refus($$SELECT public.lister_candidatures('{}', 'activite', NULL)$$, '22023', 'page absente');
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a2', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $liste_femme$
DECLARE r jsonb;
BEGIN
  r := public.lister_candidatures();
  PERFORM pg_temp.vrai((r ->> 'total')::int = 3
    AND pg_temp.ids(r) = ARRAY['ca1dcccc-0000-4000-8000-000000000002', 'ca1dcccc-0000-4000-8000-000000000006',
                               'ca1dcccc-0000-4000-8000-000000000007']::uuid[],
    'direction femme : ses trois candidatures seulement');
  PERFORM pg_temp.vrai(r -> 'compteursEtapes' = '{"recue": 0, "invitee": 1, "prequalification": 1,
    "verifications": 1, "confirmee": 0}'::jsonb
    AND r -> 'compteursAlertes' = '{"informationsManquantes": 1, "confirmeesIndisponibles": 0,
    "entretiensEnRetard": null, "bloquees": null}'::jsonb,
    'direction femme : compteurs de son cote');
  PERFORM pg_temp.vrai((SELECT jsonb_object_agg(l ->> 'id', jsonb_build_array(l -> 'courrielAObtenir',
                                 l -> 'indicatifAConfirmer'))
                        FROM jsonb_array_elements(r -> 'lignes') l) =
    jsonb_build_object('ca1dcccc-0000-4000-8000-000000000002', '[false, false]'::jsonb,
                       'ca1dcccc-0000-4000-8000-000000000006', '[true, false]'::jsonb,
                       'ca1dcccc-0000-4000-8000-000000000007', '[true, false]'::jsonb),
    'marques : sans telephone du tout, aucun indicatif a confirmer ; courriel valide, rien a obtenir');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"recherche": "elodie"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-000000000002']::uuid[]
    AND pg_temp.ids(public.lister_candidatures('{"recherche": "ÉLO"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-000000000002']::uuid[],
    'recherche par nom normalisee : accents et casse ignores');
  PERFORM pg_temp.vrai((public.lister_candidatures('{"recherche": "yusuf.essai@test.invalid"}') ->> 'total')::int = 0,
    'direction femme : le courriel d''un candidat ne revele rien');
END $liste_femme$;
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a4', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
DO $liste_super$
DECLARE r jsonb;
BEGIN
  r := public.lister_candidatures('{}', 'nom', 1);
  PERFORM pg_temp.vrai((r ->> 'total')::int = 7 AND jsonb_array_length(r -> 'lignes') = 7
    AND r -> 'compteursEtapes' = '{"recue": 1, "invitee": 1, "prequalification": 2,
    "verifications": 1, "confirmee": 1}'::jsonb
    AND r -> 'compteursAlertes' ->> 'informationsManquantes' = '1'
    AND r -> 'compteursAlertes' ->> 'confirmeesIndisponibles' = '1',
    'super-admin : les deux cotes, compteurs complets');
  PERFORM pg_temp.vrai(strpos(r::text, '@') = 0 AND strpos(r::text, '+212600000004') = 0,
    'super-admin : la liste ne porte aucun contact');
END $liste_super$;
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a3', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.lister_candidatures()$$, '42501', 'direction au genre inconnu : liste refusee');
SELECT pg_temp.refus($$SELECT public.lire_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501',
  'direction au genre inconnu : dossier refuse');
SELECT pg_temp.refus($$SELECT public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501',
  'direction au genre inconnu : contact refuse');
SELECT pg_temp.refus($$SELECT public.historique_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501',
  'direction au genre inconnu : historique refuse');
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000e1', 'guardian', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.lister_candidatures()$$, '42501', 'tuteur : liste refusee');
SELECT pg_temp.refus($$SELECT public.lire_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501', 'tuteur : dossier refuse');
SELECT pg_temp.refus($$SELECT public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501', 'tuteur : contact refuse');
SELECT pg_temp.refus($$SELECT public.historique_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501', 'tuteur : historique refuse');
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a5', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.lister_candidatures()$$, '42501', 'direction desactivee : liste refusee');
RESET ROLE;
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000c1', 'teacher', 'aal1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.lister_candidatures()$$, '42501', 'candidate : liste refusee');
SELECT pg_temp.refus($$SELECT public.lire_candidature('ca1dcccc-0000-4000-8000-000000000002')$$, '42501',
  'candidate : son propre dossier interne refuse (elle passe par ma_candidature)');
RESET ROLE;
-- Un JWT admin sans profil : app_account_valid() est faux.
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000ff', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT public.lister_candidatures()$$, '42501', 'JWT admin sans profil : liste refusee');
RESET ROLE;

-- 30 listes rendues : 25 par la direction homme, 4 par la direction femme, 1 par
-- la super-admin ; une liste refusee (42501, 22023) n'a rien rendu et n'est pas comptee.
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_liste') = 30
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'candidatures_liste'
                  AND (strpos(payload::text, '@') > 0 OR strpos(lower(payload::text), 'yusuf') > 0))
  AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'candidatures_liste'
              AND actor = 'ca1d0000-0000-4000-8000-0000000000a4'
              AND payload ->> 'exception_active' = 'true' AND payload ->> 'total' = '7'
              AND payload ->> 'lignes_hors_genre' = '4')
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'candidatures_liste'
                  AND actor <> 'ca1d0000-0000-4000-8000-0000000000a4'
                  AND payload ->> 'lignes_hors_genre' <> '0'),
  'chaque lecture de liste est auditee, sans le terme cherche ; l''exception super-admin y est notee avec les quatre lignes de l''autre cote');

-- ------------------------------------------------------------
-- (d) Lire un dossier
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a2', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $lire$
DECLARE r jsonb;
BEGIN
  r := public.lire_candidature('ca1dcccc-0000-4000-8000-000000000002');
  PERFORM pg_temp.vrai(r ->> 'reference' = current_setting('test.ref2')
    AND r ->> 'nomComplet' = 'Élodie Maryam Exemple'
    AND r ->> 'etape' = 'prequalification' AND r ->> 'etat' = 'a_completer'
    AND (r ->> 'version')::int = 1 AND r ->> 'source' = 'lien_public'
    AND r -> 'controles' = 'null'::jsonb AND r -> 'piece' = 'null'::jsonb
    AND NOT r ? 'erreur',
    'direction femme : dossier de sa candidate, controles et piece null dans ce lot');
  PERFORM pg_temp.vrai(jsonb_array_length(r -> 'reponses') = 2
    AND r -> 'reponses' -> 0 ->> 'questionnaireVersion' = 'v1-2026-10'
    AND r -> 'reponses' -> 0 ->> 'source' = 'candidat'
    AND r -> 'reponses' -> 0 -> 'reponses' = '{"paysResidence": "MA"}'::jsonb
    AND r -> 'reponses' -> 1 ->> 'questionnaireVersion' = 'formulaire-A2'
    AND r -> 'reponses' -> 0 ->> 'soumisLe' ~ 'Z$',
    'reponses versionnees, la plus recente d''abord, instant en UTC');
  PERFORM pg_temp.vrai(NOT (r ? 'courriel' OR r ? 'telephone' OR r ? 'genre' OR r ? 'sourceRef')
    AND strpos(r::text, '@') = 0,
    'le dossier ne porte ni contact, ni genre, ni reference source');
  PERFORM pg_temp.vrai(public.lire_candidature('ca1dcccc-0000-0000-0000-00000000dead') = '{"erreur": "absente"}'::jsonb,
    'identifiant inconnu : absente');
END $lire$;
SELECT pg_temp.refus($$SELECT public.lire_candidature(NULL)$$, '22023', 'dossier sans identifiant');
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.lire_candidature('ca1dcccc-0000-4000-8000-000000000002') = '{"erreur": "hors_portee"}'::jsonb,
  'direction homme : dossier d''une candidate hors portee, aucune donnee');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements
                     WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002'
                       AND type = 'lecture_hors_portee'
                       AND auteur_id = 'ca1d0000-0000-4000-8000-0000000000a1'
                       AND motif_interne IS NULL AND details = '{}'::jsonb) = 1
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_hors_portee'
         AND row_id = 'ca1dcccc-0000-4000-8000-000000000002'
         AND actor = 'ca1d0000-0000-4000-8000-0000000000a1' AND payload ->> 'lecture' = 'dossier') = 1,
  'la tentative hors portee est tracee (journal de la candidature et audit), malgre le refus');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.candidature_evenements
                                WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000001'),
  'une lecture dans la portee ne laisse aucun evenement');

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a4', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.lire_candidature('ca1dcccc-0000-4000-8000-000000000002') ->> 'reference' = current_setting('test.ref2')
  AND public.lire_candidature('ca1dcccc-0000-4000-8000-000000000001') ->> 'reference' = current_setting('test.ref1'),
  'super-admin : lit un dossier de chaque cote');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
                       AND row_id = 'ca1dcccc-0000-4000-8000-000000000001'
                       AND actor = 'ca1d0000-0000-4000-8000-0000000000a4'
                       AND payload = '{"lecture": "dossier", "motif": "exception_super_admin_kyc"}'::jsonb) = 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
                  AND (row_id = 'ca1dcccc-0000-4000-8000-000000000002'
                       OR actor <> 'ca1d0000-0000-4000-8000-0000000000a4')),
  'exception super-admin journalisee : un dossier lu de l''autre cote, une entree ; de son cote, aucune');

-- ------------------------------------------------------------
-- (e) Lire le contact
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000001') =
  '{"courriel": "yusuf.essai@test.invalid", "telephone": "+33600000001", "courrielBrut": null,
    "telephoneBrut": null}'::jsonb,
  'direction homme nommee : contact valide de son candidat');
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000003') =
  '{"courriel": null, "telephone": null, "courrielBrut": "0612345678", "telephoneBrut": "0612345678"}'::jsonb,
  'contact brut rendu a part, jamais pris pour un courriel ni un telephone valides');
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000005') =
  '{"courriel": null, "telephone": null, "courrielBrut": null, "telephoneBrut": null}'::jsonb,
  'contact absent : quatre null');
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000002') = '{"erreur": "hors_portee"}'::jsonb,
  'direction homme : contact d''une candidate hors portee refuse');
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-0000-0000-00000000dead') = '{"erreur": "absente"}'::jsonb,
  'contact d''une candidature inconnue : absente');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements
                     WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000001' AND type = 'lecture_contact'
                       AND auteur_id = 'ca1d0000-0000-4000-8000-0000000000a1') = 1
  AND (SELECT count(*) FROM public.candidature_evenements
       WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000005' AND type = 'lecture_contact') = 1
  AND (SELECT count(*) FROM public.candidature_evenements
       WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000003' AND type = 'lecture_contact') = 1
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_lecture_contact'
         AND actor = 'ca1d0000-0000-4000-8000-0000000000a1'
         AND payload ->> 'motif' = 'meme_genre_admin') = 3,
  'chaque lecture du contact laisse un evenement et une entree d''audit');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements
                     WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002' AND type = 'lecture_hors_portee') = 2
  AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements
                  WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002' AND type = 'lecture_contact')
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_hors_portee'
         AND payload ->> 'lecture' = 'contact') = 1,
  'contact hors portee : tentative tracee, aucune lecture du contact consignee');

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a2', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000002') =
  '{"courriel": "maryam.exemple@test.invalid", "telephone": null, "courrielBrut": null,
    "telephoneBrut": null}'::jsonb,
  'direction femme nommee : contact de sa candidate');
SELECT pg_temp.refus($$SELECT public.lire_contact_candidature(NULL)$$, '22023', 'contact sans identifiant');
RESET ROLE;

-- La direction non nommee lit la candidature, pas le contact (C12).
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a6', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.lire_candidature('ca1dcccc-0000-4000-8000-000000000001') ->> 'reference'
                    = current_setting('test.ref1'),
  'direction non nommee : lit le dossier de son cote');
SELECT pg_temp.refus($$SELECT public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000001')$$, '42501',
  'direction non nommee : contact refuse');
RESET ROLE;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.candidature_evenements
                                WHERE auteur_id = 'ca1d0000-0000-4000-8000-0000000000a6')
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'candidature_lecture_contact'
                  AND actor = 'ca1d0000-0000-4000-8000-0000000000a6'),
  'direction non nommee : aucune lecture du contact consignee, aucun contact rendu');

-- ------------------------------------------------------------
-- (f) Historique
-- ------------------------------------------------------------
-- K2 compte maintenant six evenements : creee, transition, responsable, deux
-- lectures hors portee (direction homme), une lecture du contact (direction femme).
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a2', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $historique$
DECLARE
  r jsonb;
  s jsonb;
  t jsonb;
BEGIN
  r := public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002', NULL, 4);
  PERFORM pg_temp.vrai(jsonb_array_length(r -> 'evenements') = 4
    AND r -> 'evenements' -> 0 ->> 'type' = 'lecture_contact'
    AND r -> 'evenements' -> 1 ->> 'type' = 'lecture_hors_portee'
    AND r -> 'evenements' -> 2 ->> 'type' = 'lecture_hors_portee'
    AND r -> 'evenements' -> 3 ->> 'type' = 'responsable'
    AND (r ->> 'curseurSuivant')::bigint = (r -> 'evenements' -> 3 ->> 'id')::bigint,
    'historique : le plus recent d''abord, curseur sur le dernier rendu quand il en reste');
  PERFORM pg_temp.vrai(r -> 'evenements' -> 0 ->> 'auteur' = 'direction'
    AND r -> 'evenements' -> 3 ->> 'auteur' = 'direction'
    AND r -> 'evenements' -> 3 ->> 'motif' = 'suivi confie a la direction',
    'auteur direction et motif interne rendus a la direction');
  s := public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002', (r ->> 'curseurSuivant')::bigint, 4);
  PERFORM pg_temp.vrai(jsonb_array_length(s -> 'evenements') = 2
    AND s -> 'evenements' -> 0 ->> 'type' = 'transition'
    AND s -> 'evenements' -> 0 ->> 'auteur' = 'candidat'
    AND s -> 'evenements' -> 0 ->> 'etapeAvant' = 'invitee'
    AND s -> 'evenements' -> 0 ->> 'etapeApres' = 'prequalification'
    AND s -> 'evenements' -> 0 ->> 'etatApres' = 'a_completer'
    AND s -> 'evenements' -> 1 ->> 'type' = 'creee'
    AND s -> 'evenements' -> 1 ->> 'auteur' = 'systeme'
    AND s -> 'curseurSuivant' = 'null'::jsonb,
    'page suivante : la suite sans doublon, auteurs candidat et systeme, plus de curseur');
  t := public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002');
  PERFORM pg_temp.vrai(jsonb_array_length(t -> 'evenements') = 6 AND t -> 'curseurSuivant' = 'null'::jsonb
    AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(t -> 'evenements' -> 0) k) =
        (SELECT array_agg(x ORDER BY x) FROM unnest(ARRAY['id', 'type', 'quand', 'etapeAvant', 'etapeApres',
          'etatAvant', 'etatApres', 'issueAvant', 'issueApres', 'auteur', 'motif']) x),
    'historique complet en une page, onze cles par evenement');
  PERFORM pg_temp.vrai((SELECT bool_and(e ->> 'quand' ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$')
                        FROM jsonb_array_elements(t -> 'evenements') e),
    'historique : instants en UTC, suffixe Z');
  PERFORM pg_temp.vrai(strpos(t::text, 'ca1d0000-0000-4000-8000-0000000000c1') = 0
    AND strpos(t::text, 'ca1d0000-0000-4000-8000-0000000000a1') = 0
    AND strpos(t::text, 'ca1d0000-0000-4000-8000-0000000000a2') = 0
    AND strpos(t::text, 'Maryam') = 0 AND strpos(t::text, 'Direction') = 0,
    'historique : ni nom ni identifiant de profil d''auteur');
END $historique$;
SELECT pg_temp.refus($$SELECT public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002', NULL, 0)$$, '22023', 'limite 0');
SELECT pg_temp.refus($$SELECT public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002', NULL, 201)$$, '22023', 'limite 201');
SELECT pg_temp.refus($$SELECT public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002', 999999999, 10)$$, '22023',
  'curseur qui n''est pas un evenement de la candidature');
SELECT pg_temp.vrai(public.historique_candidature('ca1dcccc-0000-0000-0000-00000000dead') = '{"erreur": "absente"}'::jsonb,
  'historique d''une candidature inconnue : absente');
RESET ROLE;

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002') = '{"erreur": "hors_portee"}'::jsonb,
  'direction homme : historique hors portee refuse');
SELECT pg_temp.vrai(jsonb_array_length(public.historique_candidature('ca1dcccc-0000-4000-8000-000000000001') -> 'evenements') = 1,
  'direction homme : historique de son candidat (sa lecture du contact)');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_evenements
                     WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002' AND type = 'lecture_hors_portee') = 3
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_hors_portee'
         AND payload ->> 'lecture' = 'historique') = 1,
  'historique hors portee : tentative tracee');

-- ------------------------------------------------------------
-- (f bis) Exception super-admin : historique et contact de l'autre cote
-- ------------------------------------------------------------
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a4', 'admin', 'aal2');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(jsonb_array_length(public.historique_candidature('ca1dcccc-0000-4000-8000-000000000001') -> 'evenements') = 1
  AND jsonb_array_length(public.historique_candidature('ca1dcccc-0000-4000-8000-000000000002') -> 'evenements') = 7,
  'super-admin : historique de chaque cote');
SELECT pg_temp.vrai(public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000001') ->> 'courriel' = 'yusuf.essai@test.invalid'
  AND public.lire_contact_candidature('ca1dcccc-0000-4000-8000-000000000002') ->> 'courriel' = 'maryam.exemple@test.invalid',
  'super-admin nommee : contact de chaque cote');
RESET ROLE;
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
                       AND row_id = 'ca1dcccc-0000-4000-8000-000000000001'
                       AND payload = '{"lecture": "historique", "motif": "exception_super_admin_kyc"}'::jsonb) = 1
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin') = 2
  AND (SELECT payload ->> 'motif' FROM public.audit_logs WHERE action = 'candidature_lecture_contact'
         AND actor = 'ca1d0000-0000-4000-8000-0000000000a4'
         AND row_id = 'ca1dcccc-0000-4000-8000-000000000001') = 'exception_super_admin_kyc'
  AND (SELECT payload ->> 'motif' FROM public.audit_logs WHERE action = 'candidature_lecture_contact'
         AND actor = 'ca1d0000-0000-4000-8000-0000000000a4'
         AND row_id = 'ca1dcccc-0000-4000-8000-000000000002') = 'meme_genre_admin',
  'exception super-admin journalisee pour l''historique et le contact de l''autre cote, jamais pour son cote');

-- ------------------------------------------------------------
-- (g) L'etat du candidat : brique privee pour etat_dossier() etendu (C7)
-- ------------------------------------------------------------
-- La brique lit auth.uid() ; elle s'appelle ici en proprietaire, comme
-- etat_dossier() (DEFINER) l'appellera au lot L2. Aucun compte ne l'execute.
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000c1', 'teacher', 'aal1');
SELECT pg_temp.vrai(NOT public.app_account_valid()
  AND private.cand_ma_candidature() = jsonb_build_object('candidature', true, 'reference', current_setting('test.ref2'),
    'type', 'enseignant', 'etape', 'prequalification', 'etat', 'a_completer', 'issue', 'en_cours',
    'enPause', false, 'repriseLe', NULL),
  'candidate pending_kyc : sa candidature, rien de plus (ni motif, ni responsable, ni paiement)');
SET LOCAL ROLE authenticated;
SELECT pg_temp.refus($$SELECT private.cand_ma_candidature()$$, '42501',
  'candidate : aucune lecture publique de son etat hors etat_dossier()');
RESET ROLE;
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000c4', 'teacher', 'aal1');
SELECT pg_temp.vrai(private.cand_ma_candidature() ->> 'enPause' = 'true'
  AND (private.cand_ma_candidature() ->> 'repriseLe')::date = current_date + 30,
  'candidat en pause : la pause et sa reprise');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000e1', 'guardian', 'aal1');
SELECT pg_temp.vrai(private.cand_ma_candidature() = '{"candidature": false}'::jsonb, 'tuteur : aucune candidature');
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal2');
SELECT pg_temp.vrai(private.cand_ma_candidature() = '{"candidature": false}'::jsonb,
  'direction : la brique ne rend que la candidature du compte appelant (aucune)');
SELECT pg_temp.qui(NULL, NULL);
SELECT pg_temp.vrai(private.cand_ma_candidature() = '{"candidature": false}'::jsonb,
  'sans session : aucune candidature');

-- ------------------------------------------------------------
-- (h) Journal en ajout seul
-- ------------------------------------------------------------
SELECT pg_temp.refus($$UPDATE public.candidature_evenements SET motif_interne = 'reecrit'
  WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002'$$, '55000', 'journal : aucune modification, meme par le proprietaire');
SELECT pg_temp.refus($$DELETE FROM public.candidature_evenements
  WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002'$$, '55000', 'journal : aucune suppression, meme par le proprietaire');
SELECT pg_temp.refus($$DELETE FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000002'$$, '23503',
  'une candidature qui a un historique ne s''efface pas (RESTRICT explicite, jamais silencieux)');
DO $cascade$
BEGIN
  INSERT INTO public.candidatures (id, type_code, genre, nom_complet, source, source_ref)
  VALUES ('ca1dcccc-0000-4000-8000-000000000099', 'enseignant', 'male', 'Sans Historique', 'import', 'essai:cascade');
  INSERT INTO public.candidature_contacts (candidature_id, courriel) VALUES ('ca1dcccc-0000-4000-8000-000000000099', 'x@test.invalid');
  INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source)
  VALUES ('ca1dcccc-0000-4000-8000-000000000099', 'formulaire-A1', '{}', 'import');
  DELETE FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000099';
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.candidature_contacts WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000099')
    AND NOT EXISTS (SELECT 1 FROM public.candidature_reponses WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000099'),
    'sans historique : contacts et reponses suivent la candidature (cascade)');
END $cascade$;

-- ------------------------------------------------------------
-- (i) Contraintes
-- ------------------------------------------------------------
SELECT pg_temp.vrai((SELECT bool_and(reference ~ '^CAND-[0-9]{5}$') AND count(DISTINCT reference) = count(*)
                     FROM public.candidatures),
  'references CAND-nnnnn posees par le serveur, distinctes');
SELECT pg_temp.vrai(
  ('CAND-' || to_char(7::bigint, 'FM99999999900000')) = 'CAND-00007'
  AND ('CAND-' || to_char(123456::bigint, 'FM99999999900000')) = 'CAND-123456',
  'format de reference : cinq chiffres au moins, sans troncature');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c2', 'male', 'X', 'prequalification', NULL, 'lien_public')$$,
  '23514', 'prequalification sans etat refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, etape, etat, source, source_ref)
  VALUES ('enseignant', 'male', 'X', 'recue', 'en_examen', 'import', 'essai:1')$$,
  '23514', 'etat dans une etape sans etat refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c2', 'male', 'X', 'verifications', 'a_completer', 'lien_public')$$,
  '23514', 'verifications a completer refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c2', 'male', 'X', 'prequalification', 'entretien_planifie', 'lien_public')$$,
  '23514', 'prequalification avec un etat d''entretien refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (reference, type_code, genre, nom_complet, source, source_ref)
  VALUES ('CAND-12', 'enseignant', 'male', 'X', 'import', 'essai:2')$$, '23514', 'reference mal formee refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, source)
  VALUES ('enseignant', 'male', 'X', 'import')$$, '23514', 'import sans reference source refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, etape, etat, source)
  VALUES ('enseignant', 'male', 'X', 'prequalification', 'a_completer', 'lien_public')$$,
  '23514', 'sans compte au-dela de l''invitation refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, etape, source)
  VALUES ('enseignant', 'male', 'X', 'confirmee', 'lien_public')$$, '23514', 'confirmee sans compte refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, source, source_ref)
  VALUES ('enseignant', 'male', 'X', 'import', 'classeurA1:onglet1:2025-03-02T10:00')$$,
  '23505', 'meme reference source importee deux fois refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c1', 'female', 'X', 'lien_public')$$,
  '23505', 'deux candidatures du meme type pour un compte refusees');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, source)
  VALUES ('comptable', 'male', 'X', 'lien_public')$$, '23503', 'type inconnu refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, source)
  VALUES ('enseignant', 'male', '   ', 'lien_public')$$, '23514', 'nom vide refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, source, pays_residence)
  VALUES ('enseignant', 'male', 'X', 'lien_public', 'France')$$, '23514', 'pays hors ISO refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, genre, nom_complet, source, reprise_le)
  VALUES ('enseignant', 'male', 'X', 'lien_public', current_date)$$, '23514', 'date de reprise hors pause refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidature_contacts (candidature_id, courriel)
  VALUES ('ca1dcccc-0000-4000-8000-000000000007', 'Fatima@Test.invalid')$$, '23514', 'courriel non normalise refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidature_contacts (candidature_id, courriel)
  VALUES ('ca1dcccc-0000-4000-8000-000000000007', '0612345678')$$, '23514',
  'courriel mal forme refuse dans la colonne validee (il va dans courriel_brut)');
SELECT pg_temp.refus($$INSERT INTO public.candidature_contacts (candidature_id, telephone)
  VALUES ('ca1dcccc-0000-4000-8000-000000000007', '0600000000')$$, '23514',
  'telephone hors E.164 refuse dans la colonne validee (il va dans telephone_brut)');
SELECT pg_temp.refus($$INSERT INTO public.candidature_contacts (candidature_id, courriel, courriel_brut)
  VALUES ('ca1dcccc-0000-4000-8000-000000000007', 'f@test.invalid', 'f@test')$$, '23514',
  'courriel valide et brut ensemble refuses');
SELECT pg_temp.refus($$INSERT INTO public.candidature_contacts (candidature_id, telephone, telephone_brut)
  VALUES ('ca1dcccc-0000-4000-8000-000000000007', '+33600000007', '0600000007')$$, '23514',
  'telephone valide et brut ensemble refuses');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, source, indisponible)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c7', 'male', 'X', 'recue', 'lien_public', true)$$, '23514',
  'indisponibilite avant la salle 3 refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, source, indisponible_jusqu_au)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c7', 'male', 'X', 'confirmee', 'lien_public', current_date)$$, '23514',
  'date d''indisponibilite sans indisponibilite refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, etape, source, indisponible, indisponible_jusqu_au)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c7', 'male', 'X', 'confirmee', 'lien_public', true, 'infinity')$$, '23514',
  'indisponibilite a date infinie refusee (sans date, elle est ouverte)');
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source, en_pause, reprise_le)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c7', 'male', 'X', 'lien_public', true, '-infinity')$$, '23514',
  'reprise a date infinie refusee');

-- Le genre d'une candidature rattachee est celui du compte (C8).
DO $genre$
DECLARE
  v_genre public.gender;
BEGIN
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, source)
  VALUES ('ca1dcccc-0000-4000-8000-000000000098', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c5',
          'male', 'Sara Rattachee', 'lien_public')
  RETURNING genre INTO v_genre;
  PERFORM pg_temp.vrai(v_genre = 'female', 'genre declare ecrase par celui du compte a l''insertion');
  UPDATE public.candidatures SET genre = 'male' WHERE id = 'ca1dcccc-0000-4000-8000-000000000098'
  RETURNING genre INTO v_genre;
  PERFORM pg_temp.vrai(v_genre = 'female', 'genre jamais deplace a la main sur une candidature rattachee');
  UPDATE public.candidatures SET profile_id = NULL WHERE id = 'ca1dcccc-0000-4000-8000-000000000098';
  UPDATE public.candidatures SET profile_id = 'ca1d0000-0000-4000-8000-0000000000c5', genre = 'male'
   WHERE id = 'ca1dcccc-0000-4000-8000-000000000098'
  RETURNING genre INTO v_genre;
  PERFORM pg_temp.vrai(v_genre = 'female', 'rattachement apres coup : le genre suit le compte');
  DELETE FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000098';
  SELECT genre INTO v_genre FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000001';
  PERFORM pg_temp.vrai(v_genre = 'male', 'sans compte, le genre declare a l''import est garde');
END $genre$;
SELECT pg_temp.refus($$INSERT INTO public.candidatures (type_code, profile_id, genre, nom_complet, source)
  VALUES ('enseignant', 'ca1d0000-0000-4000-8000-0000000000c6', 'female', 'Sans Genre', 'lien_public')$$, '23514',
  'compte au genre inconnu : candidature impossible a rattacher');
SELECT pg_temp.refus($$UPDATE public.candidatures SET profile_id = 'ca1d0000-0000-4000-8000-0000000000c6'
  WHERE id = 'ca1dcccc-0000-4000-8000-000000000006'$$, '23514',
  'ligne sans compte rattachee a un compte au genre inconnu : refusee');
SELECT pg_temp.refus($$INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source)
  VALUES ('ca1dcccc-0000-4000-8000-000000000003', 'v1', '[]', 'import')$$, '23514', 'reponses qui ne sont pas un objet refusees');
SELECT pg_temp.refus($$INSERT INTO public.candidature_evenements (candidature_id, type)
  VALUES ('ca1dcccc-0000-4000-8000-000000000003', 'suppression')$$, '23514', 'type d''evenement inconnu refuse');
SELECT pg_temp.refus($$INSERT INTO public.candidature_evenements (candidature_id, type, etape_apres)
  VALUES ('ca1dcccc-0000-4000-8000-000000000003', 'transition', 'salle3')$$, '23514', 'etape d''evenement inconnue refusee');

-- ------------------------------------------------------------
-- (c bis) Pages de 50
-- ------------------------------------------------------------
INSERT INTO public.candidatures (type_code, genre, nom_complet, source, source_ref, recue_le, derniere_activite)
SELECT 'enseignant', 'male', 'Lot Pagination ' || lpad(n::text, 2, '0'), 'import', 'lot-pagination:' || n,
       now() - interval '100 days', now() - interval '100 days' - n * interval '1 minute'
FROM generate_series(1, 50) n;
SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $pages$
DECLARE
  p1 jsonb := public.lister_candidatures('{}', 'activite', 1);
  p2 jsonb := public.lister_candidatures('{}', 'activite', 2);
  p3 jsonb := public.lister_candidatures('{}', 'activite', 3);
BEGIN
  PERFORM pg_temp.vrai((p1 ->> 'total')::int = 54 AND jsonb_array_length(p1 -> 'lignes') = 50
    AND (p2 ->> 'total')::int = 54 AND jsonb_array_length(p2 -> 'lignes') = 4
    AND jsonb_array_length(p3 -> 'lignes') = 0,
    'pages de 50 : 50 puis 4 puis rien, total reel sur chaque page');
  PERFORM pg_temp.vrai((pg_temp.ids(p1))[1:4] = ARRAY['ca1dcccc-0000-4000-8000-000000000001',
      'ca1dcccc-0000-4000-8000-000000000004', 'ca1dcccc-0000-4000-8000-000000000005',
      'ca1dcccc-0000-4000-8000-000000000003']::uuid[]
    AND (SELECT count(DISTINCT x) FROM unnest(pg_temp.ids(p1) || pg_temp.ids(p2)) x) = 54,
    'pages : ordre stable, aucune ligne repetee ni perdue');
  PERFORM pg_temp.vrai(p1 -> 'compteursEtapes' ->> 'recue' = '51',
    'compteurs : toute la portee, pas la page');
END $pages$;
RESET ROLE;

-- ------------------------------------------------------------
-- (k) Recherche arabe, instants et jour UTC, indisponibilite, compte anonymise
-- ------------------------------------------------------------
INSERT INTO public.candidatures (id, type_code, genre, nom_complet, source, source_ref) VALUES
 ('ca1dcccc-0000-4000-8000-0000000000b1', 'enseignant', 'male', 'أحمد بن عبد الله', 'import', 'arabe:1'),
 ('ca1dcccc-0000-4000-8000-0000000000b2', 'enseignant', 'male', 'مُحَمَّد يوسف', 'import', 'arabe:2'),
 ('ca1dcccc-0000-4000-8000-0000000000b3', 'enseignant', 'male', 'مصطفـــى', 'import', 'arabe:3');
-- Trois confirmes indisponibles : sans date (ouverte), jusqu'au jour UTC
-- courant, jusqu'a la veille (finie).
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, source,
                                 indisponible, indisponible_jusqu_au) VALUES
 ('ca1dcccc-0000-4000-8000-0000000000d7', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c7', 'male',
  'Idris Ouvert', 'confirmee', 'lien_public', true, NULL),
 ('ca1dcccc-0000-4000-8000-0000000000d8', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c8', 'male',
  'Ilyas Jour', 'confirmee', 'lien_public', true, (now() AT TIME ZONE 'UTC')::date),
 ('ca1dcccc-0000-4000-8000-0000000000d9', 'enseignant', 'ca1d0000-0000-4000-8000-0000000000c9', 'male',
  'Hamza Passe', 'confirmee', 'lien_public', true, (now() AT TIME ZONE 'UTC')::date - 1);

SELECT pg_temp.qui('ca1d0000-0000-4000-8000-0000000000a1', 'admin', 'aal1');
SET LOCAL ROLE authenticated;
DO $arabe$
BEGIN
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"recherche": "احمد"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-0000000000b1']::uuid[]
    AND pg_temp.ids(public.lister_candidatures('{"recherche": "أحمد"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-0000000000b1']::uuid[],
    'recherche arabe : alif avec ou sans hamza');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"recherche": "محمد"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-0000000000b2']::uuid[]
    AND pg_temp.ids(public.lister_candidatures('{"recherche": "مُحَمَّد"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-0000000000b2']::uuid[],
    'recherche arabe : voyelles breves et chadda ignorees, des deux cotes');
  PERFORM pg_temp.vrai(pg_temp.ids(public.lister_candidatures('{"recherche": "مصطفى"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-0000000000b3']::uuid[]
    AND pg_temp.ids(public.lister_candidatures('{"recherche": "مصطفي"}')) =
      ARRAY['ca1dcccc-0000-4000-8000-0000000000b3']::uuid[],
    'recherche arabe : allongement ignore, alif maqsura lu ya');
  PERFORM pg_temp.vrai((public.lister_candidatures(jsonb_build_object('recherche', U&'\064E\0640')) ->> 'total')::int = 0,
    'recherche faite seulement de signes : aucun nom rapproche, pas toute la liste');
END $arabe$;

DO $fuseaux$
DECLARE
  r_est jsonb;
  r_ouest jsonb;
BEGIN
  PERFORM set_config('TimeZone', 'Pacific/Kiritimati', true);
  r_est := public.lister_candidatures('{"etape": "confirmee"}', 'nom', 1);
  PERFORM set_config('TimeZone', 'Pacific/Pago_Pago', true);
  r_ouest := public.lister_candidatures('{"etape": "confirmee"}', 'nom', 1);
  PERFORM pg_temp.vrai(r_est -> 'compteursAlertes' ->> 'confirmeesIndisponibles' = '3'
    AND r_ouest -> 'compteursAlertes' ->> 'confirmeesIndisponibles' = '3',
    'confirmees indisponibles : jour UTC, le meme a UTC+14 et a UTC-11 (ouverte, jusqu''a aujourd''hui, pas hier)');
  PERFORM pg_temp.vrai(r_est -> 'lignes' = r_ouest -> 'lignes',
    'lignes identiques quel que soit le TimeZone de la session');
  PERFORM pg_temp.vrai((SELECT jsonb_object_agg(l ->> 'id', jsonb_build_array(l -> 'indisponible', l -> 'indisponibleJusquAu'))
                        FROM jsonb_array_elements(r_est -> 'lignes') l
                        WHERE l ->> 'id' IN ('ca1dcccc-0000-4000-8000-0000000000d7', 'ca1dcccc-0000-4000-8000-0000000000d9')) =
    jsonb_build_object('ca1dcccc-0000-4000-8000-0000000000d7', '[true, null]'::jsonb,
                       'ca1dcccc-0000-4000-8000-0000000000d9',
                       jsonb_build_array(false, (now() AT TIME ZONE 'UTC')::date - 1)),
    'indisponibilite ouverte rendue indisponible sans date ; date passee rendue disponible par le serveur');
END $fuseaux$;
RESET TimeZone;
RESET ROLE;

-- ECART CONNU (C1, CAND-Q21, CAND-BR-14), epingle : l'anonymisation existante
-- ne touche pas la candidature. Ce controle doit basculer quand le lot de
-- conservation etendra cpt_anonymiser et mes_donnees_export.
DO $anonymise$
DECLARE
  v_genre public.gender;
BEGIN
  PERFORM private.cpt_anonymiser('ca1d0000-0000-4000-8000-0000000000c1');
  UPDATE public.candidatures SET derniere_activite = derniere_activite
   WHERE id = 'ca1dcccc-0000-4000-8000-000000000002'
  RETURNING genre INTO v_genre;
  PERFORM pg_temp.vrai(v_genre = 'female'
    AND (SELECT gender FROM public.profiles WHERE id = 'ca1d0000-0000-4000-8000-0000000000c1') IS NULL,
    'compte anonymise (genre efface) : la candidature s''ecrit encore et garde le dernier genre connu');
  PERFORM pg_temp.vrai(
    (SELECT nom_complet FROM public.candidatures WHERE id = 'ca1dcccc-0000-4000-8000-000000000002') = 'Élodie Maryam Exemple'
    AND (SELECT courriel FROM public.candidature_contacts
          WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002') = 'maryam.exemple@test.invalid'
    AND (SELECT count(*) FROM public.candidature_reponses
          WHERE candidature_id = 'ca1dcccc-0000-4000-8000-000000000002') = 2
    AND pg_get_functiondef('public.mes_donnees_export()'::regprocedure) NOT LIKE '%candidature%',
    'ECART CONNU CAND-Q21 : nom, contact et reponses survivent a l''anonymisation, absents de l''export (prealable a la production)');
END $anonymise$;

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 174 THEN
    RAISE EXCEPTION 'CAND-L1 ROUGE : % controles executes, 174 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L1 socle : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
