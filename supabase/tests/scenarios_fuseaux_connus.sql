-- PERF-ATTENTE (d) (migration 20261120200500_fuseaux_connus) :
-- valider un nom de fuseau sans lire pg_timezone_names.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. app_private.fuseau_connu : un nom de la table repond vrai, un nom inconnu
--      faux, NULL et vide faux ; un nom VALIDE mais ABSENT de la table (on le
--      retire ici) reste vrai par le repli sur pg_timezone_names ;
--   2. quinze fonctions ne lisent plus pg_timezone_names (seule
--      private.questionnaire_options, qui LISTE les fuseaux, la lit encore) ;
--   3. leur comportement ne change pas : prerequis_enseignant (fuseau valide,
--      invalide, valide mais absent de la table), offres_compatibles (fuseau
--      valide : memes offres ; inconnu : aucune ligne), cle_horaire_utc,
--      creneaux_normalises_utc, traduire_occurrences_fuseau, series_tresorerie ;
--   4. la table est en RLS, sans droit client ; fuseau_connu : authenticated et
--      service_role oui, anon non ;
--   5. mesure : la lecture de pg_timezone_names contre fuseau_connu, imprimee
--      (la base jetable de la CI lit la vue en quelques millisecondes ; la
--      production, 646 ms par lecture le 07/11/2026) ; l'assertion de gain ne
--      s'applique que si la lecture de la vue depasse 50 ms ici.
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout est
-- annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PERF-FUSEAUX ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.id(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('perf-fz-' || p)::uuid $$;

CREATE FUNCTION pg_temp.jeton(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
    'app_metadata', pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text, true);
END $$;

-- Un appel doit etre refuse avec ce SQLSTATE et un message qui commence ainsi.
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'PERF-FUSEAUX ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE IS DISTINCT FROM p_code OR SQLERRM NOT LIKE p_message || '%' THEN
      RAISE EXCEPTION 'PERF-FUSEAUX ROUGE : % (%, « % »)', p_label, SQLSTATE, SQLERRM;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- 1. fuseau_connu.
SELECT pg_temp.vrai(app_private.fuseau_connu('Europe/Paris') AND app_private.fuseau_connu('UTC')
                    AND NOT app_private.fuseau_connu('Mars/Olympus') AND NOT app_private.fuseau_connu('')
                    AND NOT app_private.fuseau_connu(NULL),
  'fuseau_connu : un fuseau de la table vrai, un inconnu faux, vide et NULL faux');
DELETE FROM app_private.fuseaux_connus WHERE nom = 'Asia/Tokyo';
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM app_private.fuseaux_connus WHERE nom = 'Asia/Tokyo')
  AND app_private.fuseau_connu('Asia/Tokyo'),
  'un nom valide mais ABSENT de la table reste vrai par le repli sur pg_timezone_names');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM app_private.fuseaux_connus) + 1
    = (SELECT pg_catalog.count(*) FROM pg_catalog.pg_timezone_names WHERE pg_catalog.length(name) BETWEEN 1 AND 100),
  'la table porte tous les noms de pg_timezone_names (moins celui retire ici)');

-- 2. Plus de lecture de la vue, sauf celle de la liste.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.array_agg(n.nspname || '.' || p.proname ORDER BY p.proname)
     FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE p.prosrc ILIKE '%pg_timezone_names%' AND n.nspname IN ('public', 'private', 'app_private'))
  = ARRAY['app_private.fuseau_connu', 'private.questionnaire_options'],
  'seules private.questionnaire_options (la liste) et fuseau_connu (le repli) lisent encore pg_timezone_names');

-- 3. Le comportement ne change pas.
SELECT pg_temp.vrai(
  public.cle_horaire_utc(ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'Europe/Paris') IS NOT NULL
  AND (SELECT pg_catalog.count(*) FROM public.creneaux_normalises_utc(ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'Europe/Paris')) = 1,
  'cle_horaire_utc et creneaux_normalises_utc : un fuseau valide passe');
SELECT pg_temp.refus($q$SELECT public.cle_horaire_utc(ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'Mars/Olympus')$q$,
  'P0001', 'créneaux ou fuseau invalides', 'cle_horaire_utc refuse un fuseau inconnu comme avant');
SELECT pg_temp.refus($q$SELECT * FROM public.creneaux_normalises_utc(ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'Mars/Olympus')$q$,
  'P0001', 'créneaux ou fuseau invalides', 'creneaux_normalises_utc refuse un fuseau inconnu comme avant');
SELECT pg_temp.refus($q$SELECT * FROM public.traduire_occurrences_fuseau(ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'Europe/Paris', 'Mars/Olympus')$q$,
  'P0001', 'créneaux ou fuseaux invalides', 'traduire_occurrences_fuseau refuse une destination inconnue comme avant');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.traduire_occurrences_fuseau(ARRAY[1]::smallint[], ARRAY[9]::smallint[], 'Europe/Paris', 'Asia/Tokyo')) = 1,
  'traduire_occurrences_fuseau : un fuseau valide absent de la table passe (repli)');
UPDATE public.app_config SET value = '"Mars/Olympus"'::jsonb WHERE key = 'fuseau_comptable';
INSERT INTO public.app_config (key, value) SELECT 'fuseau_comptable', '"Mars/Olympus"'::jsonb
 WHERE NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'fuseau_comptable');

-- Fixtures : un enseignant, un tuteur et son eleve, une offre publiee.
SET LOCAL session_replication_role = replica;
INSERT INTO auth.users (id, email) SELECT pg_temp.id(x), 'perf-fz-' || x || '@test.invalid' FROM unnest(ARRAY['g', 's', 't', 'adm']) x;
INSERT INTO public.households (id, timezone) VALUES (pg_temp.id('h'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.id('g'), 'PFZ-G', 'guardian', pg_temp.id('h'), 'G', 'T', 'active', 'male'),
 (pg_temp.id('s'), 'PFZ-S', 'student', pg_temp.id('h'), 'S', 'T', 'active', 'male'),
 (pg_temp.id('t'), 'PFZ-T', 'teacher', NULL, 'T', 'T', 'active', 'female'),
 (pg_temp.id('adm'), 'PFZ-A', 'admin', NULL, 'A', 'T', 'active', 'male');
INSERT INTO public.student_profiles (profile_id, student_type, langue_cours, cohorte) VALUES (pg_temp.id('s'), 'minor', 'francais', 'enfant_6_9');
INSERT INTO public.teacher_profiles (profile_id, country, kyc_status, timezone_iana, languages) VALUES (pg_temp.id('t'), 'FR', 'approved', 'Europe/Paris', ARRAY['fr'])
  ON CONFLICT (profile_id) DO UPDATE SET country = 'FR', timezone_iana = 'Europe/Paris', languages = ARRAY['fr'];
INSERT INTO public.offres_horaires (id, type_public, langue_code, fuseau_iana, jours, heure_locale, duree_minutes, etat, publiee_at, publiee_par)
VALUES (pg_temp.id('o'), 'enfant', 'francais', 'Europe/Paris', ARRAY[1, 3]::smallint[], 18, 60, 'publiee', now(), pg_temp.id('adm'));
RESET session_replication_role;

-- series_tresorerie : le fuseau comptable inconnu est refuse comme avant.
SELECT pg_temp.jeton(pg_temp.id('adm'), 'admin', NULL);
SELECT pg_temp.refus($q$SELECT * FROM public.series_tresorerie()$q$, '22023', 'fuseau_comptable_invalide',
  'series_tresorerie refuse un fuseau comptable inconnu comme avant');

-- prerequis_enseignant : valide, invalide, valide mais absent de la table.
SELECT pg_temp.jeton(pg_temp.id('t'), 'teacher', NULL);
SELECT pg_temp.vrai((public.prerequis_enseignant() ->> 'fuseau')::boolean,
  'prerequis_enseignant : un fuseau de la table = fait');
UPDATE public.teacher_profiles SET timezone_iana = 'Mars/Olympus' WHERE profile_id = pg_temp.id('t');
SELECT pg_temp.vrai(NOT (public.prerequis_enseignant() ->> 'fuseau')::boolean,
  'prerequis_enseignant : un fuseau inconnu = a faire');
UPDATE public.teacher_profiles SET timezone_iana = 'Asia/Tokyo' WHERE profile_id = pg_temp.id('t');
SELECT pg_temp.vrai((public.prerequis_enseignant() ->> 'fuseau')::boolean,
  'prerequis_enseignant : un fuseau valide mais absent de la table = fait (repli)');

-- offres_compatibles : fuseau valide, valide absent de la table, inconnu.
SELECT pg_temp.jeton(pg_temp.id('g'), 'guardian', pg_temp.id('h'));
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.offres_compatibles(pg_temp.id('s'), 'Europe/Paris')) = 1,
  'offres_compatibles : un fuseau de la table rend l''offre');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.offres_compatibles(pg_temp.id('s'), 'Asia/Tokyo')) = 1,
  'offres_compatibles : un fuseau valide absent de la table rend l''offre (repli)');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.offres_compatibles(pg_temp.id('s'), 'Mars/Olympus')) = 0,
  'offres_compatibles : un fuseau inconnu ne rend aucune ligne, comme avant');

-- 4. Droits.
SELECT pg_temp.vrai(
  (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'app_private.fuseaux_connus'::regclass)
  AND NOT pg_catalog.has_table_privilege('anon', 'app_private.fuseaux_connus', 'SELECT')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'app_private.fuseaux_connus', 'SELECT')
  AND pg_catalog.has_function_privilege('authenticated', 'app_private.fuseau_connu(text)', 'EXECUTE')
  AND pg_catalog.has_function_privilege('service_role', 'app_private.fuseau_connu(text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'app_private.fuseau_connu(text)', 'EXECUTE'),
  'la table est en RLS sans droit client ; fuseau_connu : authenticated et service_role oui, anon non');

-- 5. Mesure : la vue contre fuseau_connu (nom present dans la table).
CREATE FUNCTION pg_temp.ms(p_sql text, p_n integer) RETURNS numeric
LANGUAGE plpgsql AS $$
DECLARE t0 timestamptz; i integer;
BEGIN
  t0 := pg_catalog.clock_timestamp();
  FOR i IN 1..p_n LOOP EXECUTE p_sql; END LOOP;
  RETURN round((extract(epoch FROM pg_catalog.clock_timestamp() - t0) * 1000 / p_n)::numeric, 3);
END $$;
DO $$
DECLARE
  v_vue numeric := pg_temp.ms($q$SELECT exists (select 1 from pg_catalog.pg_timezone_names where name = 'Europe/Paris')$q$, 20);
  v_connu numeric := pg_temp.ms($q$SELECT app_private.fuseau_connu('Europe/Paris')$q$, 20);
BEGIN
  RAISE NOTICE 'MESURE par appel : lecture de pg_timezone_names % ms, fuseau_connu % ms', v_vue, v_connu;
  IF v_vue > 50 AND v_connu * 5 > v_vue THEN
    RAISE EXCEPTION 'PERF-FUSEAUX ROUGE : fuseau_connu (% ms) n''est pas 5 fois plus rapide que la vue (% ms)', v_connu, v_vue;
  END IF;
END $$;

ROLLBACK;
