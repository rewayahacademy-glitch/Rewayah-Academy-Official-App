-- OFFRES-I5 : le créneau personnalisé reste invisible avant le quota,
-- s'ouvre à 6 adultes (app_config), ne révèle aucun vivier et reste réessayable.
-- Rejoué après toutes les migrations sur une base jetable.
BEGIN;

INSERT INTO auth.users (id, email)
SELECT ('f1490000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
       'f1-adulte-' || g.n::text || '@example.test'
FROM generate_series(1, public.app_config_int('groupe.capacite_adulte', 6) + 4) AS g(n);

INSERT INTO public.households (id, timezone)
VALUES
  ('f1480000-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('f1480000-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('f1480000-0000-0000-0000-000000000003', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT
  ('f1490000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
  'F1-ADULTE-' || g.n::text,
  'student',
  CASE WHEN g.n = 2
       THEN 'f1480000-0000-0000-0000-000000000002'::uuid
       ELSE 'f1480000-0000-0000-0000-000000000003'::uuid END,
  'Adulte', g.n::text,
  'active'::public.account_status,
  'male'
FROM generate_series(1, public.app_config_int('groupe.capacite_adulte', 6) + 4) AS g(n);

INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy,
   langue_cours, cohorte, niveau_declare, objectif)
SELECT
  ('f1490000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
  'autonomous', 'standard', 'forbidden',
  'francais', 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire'
FROM generate_series(1, public.app_config_int('groupe.capacite_adulte', 6) + 4) AS g(n);

DO $quota$
DECLARE
  v_i integer;
  v_capacite integer;
  v_id uuid;
  v_reponse jsonb;
  v_repetee jsonb;
  v_ok boolean;
  v_count integer;
  v_quota integer;
  v_pret boolean;
  v_jours smallint[];
  v_heures smallint[];
  v_regroupement text;
  v_offre uuid;
  v_result uuid;
BEGIN
  v_capacite := public.app_config_int('groupe.capacite_adulte', 6);
  IF v_capacite < 1 THEN
    RAISE EXCEPTION 'F1 test fixture: capacité adulte invalide';
  END IF;

  -- Une demande sans jour ou sans heure est refusée avant toute écriture.
  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000003', true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  v_ok := false;
  BEGIN
    PERFORM public.demander_creneau_personnalise(
      'f1490000-0000-0000-0000-000000000003',
      'Europe/Paris', ARRAY[]::smallint[], 18::smallint
    );
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'jours invalides' THEN v_ok := true; ELSE RAISE; END IF;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'F1: les jours vides ont été acceptés'; END IF;

  v_ok := false;
  BEGIN
    PERFORM public.demander_creneau_personnalise(
      'f1490000-0000-0000-0000-000000000003',
      'Europe/Paris', ARRAY[2,4,6]::smallint[], NULL
    );
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'heure locale invalide' THEN v_ok := true; ELSE RAISE; END IF;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'F1: une heure absente a été acceptée'; END IF;

  -- Les demandes entrent dans la file, puis leur compte/foyer peut être
  -- désactivé avant le calcul du regroupement. Le quota doit les exclure.
  FOREACH v_id IN ARRAY ARRAY[
    'f1490000-0000-0000-0000-000000000001'::uuid,
    'f1490000-0000-0000-0000-000000000002'::uuid
  ] LOOP
    PERFORM set_config('test.uid', v_id::text, true);
    PERFORM set_config('test.jwt',
      jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
    PERFORM public.demander_creneau_personnalise(v_id, 'Europe/Paris',
      ARRAY[2,4,6]::smallint[], 18::smallint);
  END LOOP;
  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000999', true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  UPDATE public.profiles SET account_status = 'disabled'
   WHERE id = 'f1490000-0000-0000-0000-000000000001';
  UPDATE public.households SET status = 'suspended'
   WHERE id = 'f1480000-0000-0000-0000-000000000002';
  FOREACH v_id IN ARRAY ARRAY[
    'f1490000-0000-0000-0000-000000000001'::uuid,
    'f1490000-0000-0000-0000-000000000002'::uuid
  ] LOOP
    PERFORM set_config('test.uid', v_id::text, true);
    v_ok := false;
    BEGIN
      PERFORM public.demander_creneau_personnalise(v_id, 'Europe/Paris',
        ARRAY[2,4,6]::smallint[], 18::smallint);
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM = 'ce profil n''est pas le votre ni celui de votre foyer'
         OR SQLERRM LIKE 'profil d''apprentissage incomplet%' THEN
        v_ok := true;
      ELSE
        RAISE;
      END IF;
    END;
    IF NOT v_ok THEN RAISE EXCEPTION 'F1: compte ou foyer inactif accepté'; END IF;
  END LOOP;

  -- Tous les élèves valides partagent un seul foyer. Le quota compte les élèves.
  FOR v_i IN 1..v_capacite LOOP
    v_id := ('f1490000-0000-0000-0000-' || lpad((v_i + 2)::text, 12, '0'))::uuid;
    PERFORM set_config('test.uid', v_id::text, true);
    v_reponse := public.demander_creneau_personnalise(
      v_id, 'Europe/Paris',
      CASE WHEN v_i = 1 THEN ARRAY[6,4,2,2]::smallint[]
           ELSE ARRAY[2,4,6]::smallint[] END,
      18::smallint
    );
    IF v_reponse->>'etat' <> 'envoyee' THEN
      RAISE EXCEPTION 'F1: demande non transmise à l''administration: %', v_reponse;
    END IF;
  END LOOP;

  -- Une répétition réseau renvoie la même demande sans compter deux fois.
  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000003', true);
  v_repetee := public.demander_creneau_personnalise(
    'f1490000-0000-0000-0000-000000000003',
    'Europe/Paris', ARRAY[2,4,6]::smallint[], 18::smallint
  );
  IF v_repetee->>'etat' <> 'envoyee' THEN
    RAISE EXCEPTION 'F1 idempotence: la demande répétée a changé d''état';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.offres_horaires
    WHERE type_public = 'adulte' AND langue_code = 'francais'
      AND fuseau_iana = 'Europe/Paris'
      AND jours = ARRAY[2,4,6]::smallint[] AND heure_locale = 18
      AND origine = 'quota_familial'
  ) THEN
    RAISE EXCEPTION 'F1: une demande familiale a publié une offre vitrine';
  END IF;

  INSERT INTO auth.users (id, email)
  VALUES ('f1490000-0000-0000-0000-000000000999', 'f1-admin@example.test');
  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
  VALUES
    ('f1490000-0000-0000-0000-000000000999', 'F1-ADMIN', 'admin', NULL,
     'Admin', 'Test', 'active', 'male');

  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000999', true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  SELECT regroupement_id, nombre_eleves, quota, pret, jours, heures_locales
    INTO v_regroupement, v_count, v_quota, v_pret, v_jours, v_heures
    FROM public.regroupements_demandes_horaires_admin()
   WHERE type_public = 'adulte' AND langue_code = 'francais'
     AND fuseau_iana = 'Europe/Paris';
  IF v_count <> v_capacite OR v_quota <> v_capacite OR NOT v_pret THEN
    RAISE EXCEPTION 'F1 quota: regroupement=% eleves=% quota=% pret=%',
      v_regroupement, v_count, v_quota, v_pret;
  END IF;
  IF v_jours IS DISTINCT FROM ARRAY[2,4,6]::smallint[] THEN
    RAISE EXCEPTION 'F1 normalisation des jours incorrecte: %', v_jours;
  END IF;
  IF v_heures IS DISTINCT FROM ARRAY[18,18,18]::smallint[] THEN
    RAISE EXCEPTION 'F1 heures de regroupement incorrectes: %', v_heures;
  END IF;

  -- La famille reçoit uniquement son propre état; aucun effectif ni foyer tiers.
  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000003', true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  v_reponse := public.mes_demandes_horaires(
    'f1490000-0000-0000-0000-000000000003');
  IF jsonb_array_length(v_reponse) <> 1
     OR v_reponse::text LIKE '%nombre_eleves%'
     OR v_reponse::text LIKE '%regroupement_id%' THEN
    RAISE EXCEPTION 'F1 confidentialité: réponse famille trop large: %', v_reponse;
  END IF;
  IF pg_catalog.has_table_privilege(
       'authenticated', 'public.demandes_horaires_famille', 'SELECT')
     OR pg_catalog.has_function_privilege(
       'anon', 'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)', 'EXECUTE')
     OR pg_catalog.has_function_privilege(
       'anon', 'public.regroupements_demandes_horaires_admin()', 'EXECUTE') THEN
    RAISE EXCEPTION 'F1 ACL: table_select=%, demande_anon=%, admin_group_anon=%',
      pg_catalog.has_table_privilege(
        'authenticated', 'public.demandes_horaires_famille', 'SELECT'),
      pg_catalog.has_function_privilege(
        'anon', 'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)', 'EXECUTE'),
      pg_catalog.has_function_privilege(
        'anon', 'public.regroupements_demandes_horaires_admin()', 'EXECUTE');
  END IF;

  -- La carte publiée par l'administration crée aussi une demande privée,
  -- sans exposer de disponibilité ou publier à nouveau la vitrine.
  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000999', true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  v_offre := public.creer_offre_horaire(
    'adulte', 'francais', 'Europe/Paris', ARRAY[1,3,5]::smallint[], 20::smallint, NULL
  );
  PERFORM public.publier_offre_horaire(v_offre);
  v_id := ('f1490000-0000-0000-0000-' || lpad((v_capacite + 3)::text, 12, '0'))::uuid;
  PERFORM set_config('test.uid', v_id::text, true);
  PERFORM set_config('test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  v_result := public.choisir_offre_horaire(v_id, v_offre, 'Europe/Paris');
  IF NOT EXISTS (
    SELECT 1 FROM public.demandes_horaires_famille
     WHERE eleve_id = v_id AND source = 'offre' AND offre_id = v_offre
       AND etat = 'envoyee'
  ) THEN
    RAISE EXCEPTION 'F1: choix d''une carte non transmis à l''administration';
  END IF;

  RAISE NOTICE 'F1: demandes privées, regroupement par élèves, quota serveur, états et ACL vérifiés';
END
$quota$;

ROLLBACK;
