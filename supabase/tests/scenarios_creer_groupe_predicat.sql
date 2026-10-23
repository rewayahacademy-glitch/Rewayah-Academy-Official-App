-- CAND-Q15, lot creer_groupe (21/10/2026) : creer_groupe (8 arguments) passe
-- par le predicat C-04/C-07, sans la couverture par les disponibilites
-- (decision du directeur : controle strict sauf les disponibilites, D4).
-- Migration 20261021210200_creer_groupe_predicat_affectation.sql.
--
-- Rejoue sur une base neuve, apres stub_auth.sql et toutes les migrations,
-- sous une direction active (role authenticated). Fixtures :
--   E1 eligible, sans aucune disponibilite declaree ;
--   E2 piece d'identite 'pending' ; E3 acces expire ; E4 genre inconnu ;
--   E5 profil enseignant supprime ; E6 deja en classe le mardi a 18 h ;
--   E7 plafond 1 heure, deja atteint ; E8 seance ponctuelle au meme instant.
-- Chaque controle reussi ecrit une ligne "CAND-Q15 OK". Un controle en
-- echec leve une exception et arrete le fichier (ON_ERROR_STOP).
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('cf150000-0000-4000-8000-000000000001', 'q15-admin@example.test'),
  ('cf150000-0000-4000-8000-0000000000e1', 'q15-e1@example.test'),
  ('cf150000-0000-4000-8000-0000000000e2', 'q15-e2@example.test'),
  ('cf150000-0000-4000-8000-0000000000e3', 'q15-e3@example.test'),
  ('cf150000-0000-4000-8000-0000000000e4', 'q15-e4@example.test'),
  ('cf150000-0000-4000-8000-0000000000e5', 'q15-e5@example.test'),
  ('cf150000-0000-4000-8000-0000000000e6', 'q15-e6@example.test'),
  ('cf150000-0000-4000-8000-0000000000e7', 'q15-e7@example.test'),
  ('cf150000-0000-4000-8000-0000000000e8', 'q15-e8@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender, access_until)
VALUES
  ('cf150000-0000-4000-8000-000000000001', 'Q15ADMIN00000001', 'admin',
   'Fixture', 'Direction', 'active', 'female', NULL),
  ('cf150000-0000-4000-8000-0000000000e1', 'Q15TEACHER0000E1', 'teacher',
   'Amina', 'Eligible', 'provisional_active', 'female', NULL),
  ('cf150000-0000-4000-8000-0000000000e2', 'Q15TEACHER0000E2', 'teacher',
   'Badr', 'Piece', 'provisional_active', 'male', NULL),
  ('cf150000-0000-4000-8000-0000000000e3', 'Q15TEACHER0000E3', 'teacher',
   'Chaima', 'Acces', 'provisional_active', 'female', pg_catalog.now() - interval '1 day'),
  ('cf150000-0000-4000-8000-0000000000e4', 'Q15TEACHER0000E4', 'teacher',
   'Dalil', 'Genre', 'provisional_active', NULL, NULL),
  ('cf150000-0000-4000-8000-0000000000e5', 'Q15TEACHER0000E5', 'teacher',
   'Elyas', 'Supprime', 'provisional_active', 'male', NULL),
  ('cf150000-0000-4000-8000-0000000000e6', 'Q15TEACHER0000E6', 'teacher',
   'Farah', 'Collision', 'provisional_active', 'female', NULL),
  ('cf150000-0000-4000-8000-0000000000e7', 'Q15TEACHER0000E7', 'teacher',
   'Ghali', 'Plafond', 'provisional_active', 'male', NULL),
  ('cf150000-0000-4000-8000-0000000000e8', 'Q15TEACHER0000E8', 'teacher',
   'Hana', 'Ponctuelle', 'provisional_active', 'female', NULL);

INSERT INTO public.teacher_profiles
  (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, deleted_at)
VALUES
  ('cf150000-0000-4000-8000-0000000000e1', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('cf150000-0000-4000-8000-0000000000e2', 'FR', ARRAY['francais'], 40, 'pending', 'Europe/Paris', NULL),
  ('cf150000-0000-4000-8000-0000000000e3', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('cf150000-0000-4000-8000-0000000000e4', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('cf150000-0000-4000-8000-0000000000e5', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', pg_catalog.now()),
  ('cf150000-0000-4000-8000-0000000000e6', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL),
  ('cf150000-0000-4000-8000-0000000000e7', 'FR', ARRAY['francais'], 1, 'approved', 'Europe/Paris', NULL),
  ('cf150000-0000-4000-8000-0000000000e8', 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris', NULL);

-- E6 : une classe active le mardi a 18 h (Paris). E7 : une classe active le
-- lundi a 10 h, qui remplit deja son plafond d'une heure.
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES
  ('cf15ffff-0000-4000-8000-0000000000e6', 'cf150000-0000-4000-8000-0000000000e6', 'active',
   'adulte', 6, 'Q15 classe existante E6', 2, 18, 'Europe/Paris'),
  ('cf15ffff-0000-4000-8000-0000000000e7', 'cf150000-0000-4000-8000-0000000000e7', 'active',
   'adulte', 6, 'Q15 classe existante E7', 1, 10, 'Europe/Paris');

-- E8 : une seance ponctuelle (sans classe), prevue, qui couvre le mardi a 18 h
-- de la semaine 1. La colonne est sessions.status (relecture).
INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, groupe_id)
SELECT 'cf150000-0000-4000-8000-0000000000e8',
       public.instant_creneau(2, 18, 'Europe/Paris', 1) - interval '15 minutes',
       public.instant_creneau(2, 18, 'Europe/Paris', 1) + interval '45 minutes',
       'planned', NULL;

-- Une classe en attente le mercredi a 9 h, pour la non-regression du
-- predicat public a deux arguments.
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
VALUES
  ('cf15ffff-0000-4000-8000-000000000a01', NULL, 'en_attente_enseignant',
   'adulte', 6, 'Q15 classe en attente', 3, 9, 'Europe/Paris');

-- Aucune disponibilite n'est declaree, pour personne.
DO $fixtures$
BEGIN
  IF EXISTS (SELECT 1 FROM public.weekly_availability wa
              WHERE wa.profile_id::text LIKE 'cf150000-%') THEN
    RAISE EXCEPTION 'ROUGE fixtures : une disponibilite existe';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM public.sessions s
       WHERE s.teacher_id = 'cf150000-0000-4000-8000-0000000000e8' AND s.groupe_id IS NULL) <> 1 THEN
    RAISE EXCEPTION 'ROUGE fixtures : seance ponctuelle de E8 absente';
  END IF;
END
$fixtures$;

-- ------------------------------------------------------------------
-- C1. Catalogue : signatures, droits, empreinte
-- ------------------------------------------------------------------
DO $catalogue$
DECLARE
  v_interne regprocedure := pg_catalog.to_regprocedure(
    'app_private.verifier_affectation_enseignant(uuid,uuid,boolean)');
  v_public regprocedure := pg_catalog.to_regprocedure(
    'public.tc_verifier_affectation_enseignant(uuid,uuid)');
  v_creer regprocedure := pg_catalog.to_regprocedure(
    'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)');
  v_role text;
BEGIN
  IF v_interne IS NULL OR v_public IS NULL OR v_creer IS NULL THEN
    RAISE EXCEPTION 'ROUGE C1 : signature absente';
  END IF;
  -- Le predicat public garde sa signature et ses droits (lot c11bis).
  IF (SELECT p.proacl::text FROM pg_catalog.pg_proc p WHERE p.oid = v_public::oid)
       <> '{postgres=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'ROUGE C1 : droits du predicat public changes : %',
      (SELECT p.proacl::text FROM pg_catalog.pg_proc p WHERE p.oid = v_public::oid);
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, v_interne, 'EXECUTE') THEN
      RAISE EXCEPTION 'ROUGE C1 : % execute le predicat interne', v_role;
    END IF;
  END LOOP;
  IF (SELECT p.prosecdef FROM pg_catalog.pg_proc p WHERE p.oid = v_interne::oid) THEN
    RAISE EXCEPTION 'ROUGE C1 : le predicat interne est DEFINER';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', v_creer, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_creer, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_creer, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_creer, 'EXECUTE') THEN
    RAISE EXCEPTION 'ROUGE C1 : droits de creer_groupe';
  END IF;
  IF coalesce(pg_catalog.obj_description(v_creer::oid, 'pg_proc'), '') NOT LIKE
       '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_creer)) || '%' THEN
    RAISE EXCEPTION 'ROUGE C1 : empreinte F86 de creer_groupe';
  END IF;
  RAISE NOTICE 'CAND-Q15 OK C1 : signatures, droits et empreinte F86';
END
$catalogue$;

-- ------------------------------------------------------------------
-- Les appels, sous une direction active
-- ------------------------------------------------------------------
SELECT set_config('request.jwt.claim.sub', 'cf150000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'cf150000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
SET LOCAL ROLE authenticated;

-- E1 : eligible, aucune disponibilite declaree : la classe est creee.
DO $e1$
DECLARE
  v_id uuid;
BEGIN
  v_id := public.creer_groupe('cf150000-0000-4000-8000-0000000000e1', 'adulte',
    'Q15 E1 mardi', 2::smallint, 18::smallint, 6::smallint, NULL::text, NULL::smallint);
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'ROUGE E1 : aucun identifiant rendu';
  END IF;
  PERFORM pg_catalog.set_config('q15.e1', v_id::text, true);
  RAISE NOTICE 'CAND-Q15 OK E1 : creee sans disponibilite declaree (D4)';
END
$e1$;

-- E2 a E8 : refus, avec leur motif exact ; ni classe ni seance ne reste.
CREATE TEMP TABLE q15_refus (enseignant text, libelle text, jour smallint,
  heure smallint, fuseau text, motif text) ON COMMIT DROP;
INSERT INTO q15_refus VALUES
  ('e2', 'Q15 E2 piece', 2, 18, NULL, 'enseignant indisponible ou genre inconnu'),
  ('e3', 'Q15 E3 acces', 2, 18, NULL, 'enseignant indisponible ou genre inconnu'),
  ('e4', 'Q15 E4 genre', 2, 18, NULL, 'enseignant indisponible ou genre inconnu'),
  ('e5', 'Q15 E5 profil', 2, 18, NULL, 'enseignant indisponible ou genre inconnu'),
  ('e6', 'Q15 E6 collision', 2, 18, NULL, 'chevauchement avec une classe ou affectation active'),
  ('e7', 'Q15 E7 plafond', 2, 18, NULL, 'plafond horaire enseignant dépassé'),
  ('e8', 'Q15 E8 ponctuelle', 2, 18, NULL, 'chevauchement avec une séance existante'),
  -- E1 une seconde fois au meme instant : la classe creee par creer_groupe
  -- compte desormais (CF1-B6).
  ('e1', 'Q15 E1 doublon', 2, 18, NULL, 'chevauchement avec une classe ou affectation active'),
  -- E1 a Londres a 17 h, le meme instant que Paris a 18 h : des instants,
  -- pas des heures locales (C-07).
  ('e1', 'Q15 E1 Londres', 2, 17, 'Europe/London', 'chevauchement avec une classe ou affectation active');

DO $refus$
DECLARE
  r record;
  v_groupes bigint;
  v_seances bigint;
  v_n integer := 0;
BEGIN
  FOR r IN SELECT * FROM q15_refus LOOP
    SELECT pg_catalog.count(*) INTO v_groupes FROM public.groupes;
    SELECT pg_catalog.count(*) INTO v_seances FROM public.sessions;
    BEGIN
      PERFORM public.creer_groupe(('cf150000-0000-4000-8000-0000000000' || r.enseignant)::uuid,
        'adulte', r.libelle, r.jour, r.heure, 6::smallint, r.fuseau, NULL::smallint);
      RAISE EXCEPTION 'ROUGE % : classe creee malgre le motif attendu « % »', r.libelle, r.motif;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM <> r.motif THEN
        RAISE EXCEPTION 'ROUGE % : motif « % », attendu « % »', r.libelle, SQLERRM, r.motif;
      END IF;
    END;
    IF EXISTS (SELECT 1 FROM public.groupes g WHERE g.libelle = r.libelle)
       OR (SELECT pg_catalog.count(*) FROM public.groupes) <> v_groupes
       OR (SELECT pg_catalog.count(*) FROM public.sessions) <> v_seances THEN
      RAISE EXCEPTION 'ROUGE % : une classe ou une seance reste apres le refus', r.libelle;
    END IF;
    v_n := v_n + 1;
    RAISE NOTICE 'CAND-Q15 OK % : refus « % », rien ne reste', r.libelle, r.motif;
  END LOOP;
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'ROUGE refus : % cas joues, 9 attendus', v_n;
  END IF;
END
$refus$;

-- La garde reste la premiere instruction : un enseignant connecte ne cree rien.
SELECT set_config('request.jwt.claim.sub', 'cf150000-0000-4000-8000-0000000000e1', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
SELECT set_config('test.uid', 'cf150000-0000-4000-8000-0000000000e1', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
DO $garde$
BEGIN
  BEGIN
    PERFORM public.creer_groupe('cf150000-0000-4000-8000-0000000000e1', 'adulte',
      'Q15 garde', 4::smallint, 18::smallint, 6::smallint, NULL::text, NULL::smallint);
    RAISE EXCEPTION 'ROUGE garde : un enseignant a cree une classe';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'creation de groupe reservee a l''administration' THEN
      RAISE EXCEPTION 'ROUGE garde : motif « % »', SQLERRM;
    END IF;
  END;
  RAISE NOTICE 'CAND-Q15 OK garde : un enseignant connecte est refuse avant tout controle';
END
$garde$;

RESET ROLE;

-- ------------------------------------------------------------------
-- Ce que la classe de E1 est devenue (lu en postgres)
-- ------------------------------------------------------------------
DO $e1_etat$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_seances integer;
BEGIN
  SELECT * INTO v_g FROM public.groupes
   WHERE id = pg_catalog.current_setting('q15.e1')::uuid;
  IF NOT FOUND OR v_g.etat <> 'active'
     OR v_g.teacher_id <> 'cf150000-0000-4000-8000-0000000000e1'
     OR v_g.genre_public <> 'indetermine' OR v_g.langue_code IS NOT NULL
     OR v_g.libelle <> 'Q15 E1 mardi' OR v_g.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'ROUGE E1 etat : etat %, enseignant %, genre %, langue %',
      v_g.etat, v_g.teacher_id, v_g.genre_public, v_g.langue_code;
  END IF;
  SELECT pg_catalog.count(*) INTO v_seances FROM public.sessions s
   WHERE s.groupe_id = v_g.id AND s.deleted_at IS NULL
     AND s.teacher_id = 'cf150000-0000-4000-8000-0000000000e1';
  IF v_seances < 1 THEN
    RAISE EXCEPTION 'ROUGE E1 etat : aucune seance materialisee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.audit_logs a
                  WHERE a.action = 'groupe_cree' AND a.row_id = v_g.id::text) THEN
    RAISE EXCEPTION 'ROUGE E1 etat : journal groupe_cree absent';
  END IF;
  RAISE NOTICE 'CAND-Q15 OK E1 etat : active, enseignante E1, genre indetermine, langue nulle, % seances, journal', v_seances;
END
$e1_etat$;

-- ------------------------------------------------------------------
-- Non-regression : le predicat public a deux arguments exige toujours les
-- disponibilites ; l'interne ne s'en passe qu'avec false.
-- ------------------------------------------------------------------
DO $c04$
DECLARE
  v_attente uuid := 'cf15ffff-0000-4000-8000-000000000a01';
  v_e1 uuid := 'cf150000-0000-4000-8000-0000000000e1';
BEGIN
  BEGIN
    PERFORM public.tc_verifier_affectation_enseignant(v_attente, v_e1);
    RAISE EXCEPTION 'ROUGE C-04 : deux arguments sans disponibilite acceptes';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'enseignant non disponible: jour 3, heure 9,%' THEN
      RAISE EXCEPTION 'ROUGE C-04 : motif « % »', SQLERRM;
    END IF;
  END;
  RAISE NOTICE 'CAND-Q15 OK C-04 : a deux arguments, les disponibilites restent exigees';

  BEGIN
    PERFORM app_private.verifier_affectation_enseignant(v_attente, v_e1, NULL);
    RAISE EXCEPTION 'ROUGE drapeau : NULL a saute les disponibilites';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'enseignant non disponible:%' THEN
      RAISE EXCEPTION 'ROUGE drapeau : motif « % »', SQLERRM;
    END IF;
  END;
  RAISE NOTICE 'CAND-Q15 OK drapeau : NULL vaut true';

  PERFORM app_private.verifier_affectation_enseignant(v_attente, v_e1, false);
  RAISE NOTICE 'CAND-Q15 OK drapeau : false ne saute que la couverture des disponibilites';

  -- Avec les disponibilites qui couvrent le mercredi de 9 h a 10 h 30, les deux
  -- arguments passent. La classe en attente est une Classe d'adultes, qui dure
  -- 90 minutes : il faut les heures 9 ET 10 (CLASSES-DUREE, 22/10 ; avant, la
  -- seule heure 9 suffisait, la seance etant comptee 60 minutes).
  INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
  VALUES (v_e1, 3, 9, 'Europe/Paris'), (v_e1, 3, 10, 'Europe/Paris');
  PERFORM public.tc_verifier_affectation_enseignant(v_attente, v_e1);
  RAISE NOTICE 'CAND-Q15 OK C-04 : disponibilite declaree, deux arguments acceptes';
END
$c04$;

-- Le predicat public reste ferme aux comptes connectes, direction comprise.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'cf150000-0000-4000-8000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.uid', 'cf150000-0000-4000-8000-000000000001', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $ferme$
BEGIN
  BEGIN
    PERFORM public.tc_verifier_affectation_enseignant(
      'cf15ffff-0000-4000-8000-000000000a01', 'cf150000-0000-4000-8000-0000000000e1');
    RAISE EXCEPTION 'ROUGE ferme : predicat public execute par authenticated';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  BEGIN
    PERFORM app_private.verifier_affectation_enseignant(
      'cf15ffff-0000-4000-8000-000000000a01', 'cf150000-0000-4000-8000-0000000000e1', false);
    RAISE EXCEPTION 'ROUGE ferme : predicat interne execute par authenticated';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
  RAISE NOTICE 'CAND-Q15 OK ferme : ni le predicat public ni l''interne ne sont executables par authenticated';
END
$ferme$;
RESET ROLE;

ROLLBACK;
