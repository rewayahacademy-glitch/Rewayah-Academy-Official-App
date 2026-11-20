-- DOSSIER-DIRECTION (migration 20261130965000_dossier_direction.sql) : PE-C1, PE-C2, PE-C10.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. references_dossiers_admin : la direction du meme cote recoit la reference du candidat enseignant ;
--      l'autre cote ne recoit rien ; un profil sans candidature ne rend rien ; une famille n'est jamais rendue ;
--      un tuteur, anon et un enseignant sont refuses ; plus de 500 profils sont refuses ;
--   2. lire_candidature rend derniereConnexion (null jamais connecte, puis l'instant) et manquants (codes) ;
--   3. une piece deposee par un candidat enseignant notifie la direction avec `reference` ; celle d'une famille
--      sans candidature d'enseignant garde la seule piece_id ; la candidature a examiner porte `reference` ;
--   4. les aides privees ne sont executables par aucun role client.
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'DOSSIER-DIRECTION ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('dossier-direction-' || p)::uuid $$;

-- Une requete jouee en `authenticated` sous l'identite donnee ; rend le premier champ en jsonb.
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

CREATE FUNCTION pg_temp.refus(p_id uuid, p_role text, p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_code text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    EXECUTE 'RESET ROLE';
  END;
  PERFORM pg_temp.vrai(v_code = p_code, p_label || ' (code ' || coalesce(v_code, 'aucun refus') || ')');
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text), pg_temp.id(text)
  TO authenticated, anon;

-- Fixtures (donnees inventees) : direction homme (dh), direction femme (df), candidat homme (ch),
-- candidate femme (cf), tuteur (tu) sans candidature d'enseignant.
INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'dossier-direction-' || x || '@test.invalid'
  FROM unnest(ARRAY['dh', 'df', 'ch', 'cf', 'tu']) AS x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('foyer'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('dh'), 'DDIR-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
       (pg_temp.id('df'), 'DDIR-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
       (pg_temp.id('ch'), 'DDIR-ENS-0001', 'teacher', NULL, 'Essai', 'Homme', 'pending_kyc', 'male'),
       (pg_temp.id('cf'), 'DDIR-ENS-0002', 'teacher', NULL, 'Essai', 'Femme', 'pending_kyc', 'female'),
       (pg_temp.id('tu'), 'DDIR-TUT-0001', 'guardian', pg_temp.id('foyer'), 'Tuteur', 'Essai', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id) VALUES (pg_temp.id('ch')), (pg_temp.id('cf'))
  ON CONFLICT (profile_id) DO NOTHING;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.id('cand-ch'), 'enseignant', pg_temp.id('ch'), 'male', 'Candidat Essai',
        'prequalification', 'a_completer', 'en_cours', false, 'lien_public'),
       (pg_temp.id('cand-cf'), 'enseignant', pg_temp.id('cf'), 'female', 'Candidate Essai',
        'prequalification', 'a_completer', 'en_cours', false, 'lien_public');

-- 1. La reference depuis un profil --------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.id('dh'), 'admin', pg_catalog.format(
    'SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(''p'', r.profile_id, ''r'', r.reference))
       FROM public.references_dossiers_admin(%L::uuid[]) r',
    ARRAY[pg_temp.id('ch'), pg_temp.id('cf'), pg_temp.id('tu'), pg_temp.id('dh')]::text))
  = pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'p', pg_temp.id('ch'), 'r', (SELECT reference FROM public.candidatures WHERE id = pg_temp.id('cand-ch')))),
  'direction homme : la reference de son cote seulement, rien pour la candidate, le tuteur ni un admin');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.id('df'), 'admin', pg_catalog.format(
    'SELECT pg_catalog.jsonb_agg(r.reference) FROM public.references_dossiers_admin(%L::uuid[]) r',
    ARRAY[pg_temp.id('ch'), pg_temp.id('cf')]::text))
  = pg_catalog.jsonb_build_array((SELECT reference FROM public.candidatures WHERE id = pg_temp.id('cand-cf'))),
  'direction femme : la reference de la candidate seulement');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.id('dh'), 'admin',
    'SELECT pg_catalog.to_jsonb(pg_catalog.count(*)) FROM public.references_dossiers_admin(ARRAY[]::uuid[])')
  = '0'::jsonb, 'liste vide : aucune ligne');
SELECT pg_temp.refus(pg_temp.id('tu'), 'guardian',
  pg_catalog.format('SELECT * FROM public.references_dossiers_admin(%L::uuid[])', ARRAY[pg_temp.id('ch')]::text),
  '42501', 'un tuteur est refuse');
SELECT pg_temp.refus(pg_temp.id('ch'), 'teacher',
  pg_catalog.format('SELECT * FROM public.references_dossiers_admin(%L::uuid[])', ARRAY[pg_temp.id('ch')]::text),
  '42501', 'un enseignant est refuse');
SELECT pg_temp.refus(pg_temp.id('dh'), 'admin',
  'SELECT * FROM public.references_dossiers_admin((SELECT pg_catalog.array_agg(gen_random_uuid()) FROM generate_series(1, 501)))',
  '22023', 'plus de 500 profils : refuse');
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.references_dossiers_admin(uuid[])', 'EXECUTE'),
  'anon ne peut pas executer references_dossiers_admin');

-- 2. Le dossier : derniere connexion et manquants ------------------------------------
DO $dossier$
DECLARE
  v jsonb;
BEGIN
  v := pg_temp.en(pg_temp.id('dh'), 'admin',
         pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.id('cand-ch')));
  PERFORM pg_temp.vrai(v ? 'derniereConnexion' AND v -> 'derniereConnexion' = 'null'::jsonb,
    'jamais connecte : derniereConnexion presente et nulle');
  PERFORM pg_temp.vrai(pg_catalog.jsonb_typeof(v -> 'manquants') = 'array'
    AND v -> 'manquants' @> '["piece_identite", "photo", "contrat"]'::jsonb,
    'manquants : la piece, la photo et le contrat (codes du serveur), lus par praxis_dossier_manques');
  PERFORM pg_temp.vrai(v ? 'controles' AND v ? 'reference', 'les cles d''avant restent');
END $dossier$;
UPDATE auth.users SET last_sign_in_at = '2026-11-19 08:30:00+00' WHERE id = pg_temp.id('ch');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.id('dh'), 'admin',
     pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.id('cand-ch'))) ->> 'derniereConnexion')::timestamptz
  = '2026-11-19 08:30:00+00'::timestamptz,
  'derniereConnexion : l''instant de la derniere connexion du compte');
SELECT pg_temp.vrai(
  NOT (pg_temp.en(pg_temp.id('dh'), 'admin',
     pg_catalog.format('SELECT public.lire_candidature(%L)', pg_temp.id('cand-cf'))) ? 'derniereConnexion'),
  'l''autre cote : hors portee, aucune derniere connexion rendue');

-- 3. Les notifications portent la reference -----------------------------------------
INSERT INTO public.kyc_documents (profile_id, doc_type, gender, object_key)
VALUES (pg_temp.id('ch'), 'passport', 'male', 'dossier-direction/piece-ch.jpg'),
       (pg_temp.id('tu'), 'passport', 'male', 'dossier-direction/piece-tu.jpg');
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM public.notifications n
   WHERE n.destinataire = pg_temp.id('dh') AND n.evenement = 'piece_identite_deposee'
     AND n.destination = '/admin/personnes/dossiers'
     AND n.params ->> 'reference' = (SELECT reference FROM public.candidatures WHERE id = pg_temp.id('cand-ch'))),
  'piece d''un candidat enseignant : la notification porte sa reference, destination inchangee');
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM public.notifications n JOIN public.kyc_documents k ON k.id::text = n.params ->> 'piece_id'
   WHERE n.destinataire = pg_temp.id('dh') AND n.evenement = 'piece_identite_deposee'
     AND k.profile_id = pg_temp.id('tu') AND NOT (n.params ? 'reference')),
  'piece d''une famille : aucune reference, la piece seule');

UPDATE public.candidatures SET etat = 'en_examen' WHERE id = pg_temp.id('cand-ch');
SET CONSTRAINTS ALL IMMEDIATE;
SELECT pg_temp.vrai(EXISTS (
  SELECT 1 FROM public.notifications n
   WHERE n.destinataire = pg_temp.id('dh') AND n.evenement = 'candidature_enseignant_a_examiner'
     AND n.destination = '/admin/personnes/candidatures'
     AND n.params ->> 'reference' = (SELECT reference FROM public.candidatures WHERE id = pg_temp.id('cand-ch'))),
  'candidature a examiner : la notification porte la reference');

-- 4. Droits des aides privees -------------------------------------------------------
SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.derniere_connexion_compte(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.derniere_connexion_compte(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.reference_candidature_enseignant(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.reference_candidature_enseignant(uuid)', 'EXECUTE'),
  'aides privees : aucun role client');

ROLLBACK;
