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

INSERT INTO auth.users (id, email)
VALUES
  ('f1490000-0000-0000-0000-000000000996', 'f1-controller@example.test'),
  ('f1490000-0000-0000-0000-000000000997', 'f1-teacher@example.test'),
  ('f1490000-0000-0000-0000-000000000998', 'f1-guardian@example.test'),
  ('f1490000-0000-0000-0000-000000000999', 'f1-admin@example.test');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('f1490000-0000-0000-0000-000000000996', 'F1-CONTROLLER', 'controller', NULL,
   'Controleur', 'Test', 'active', 'male'),
  ('f1490000-0000-0000-0000-000000000997', 'F1-TEACHER', 'teacher', NULL,
   'Enseignant', 'Test', 'active', 'male'),
  ('f1490000-0000-0000-0000-000000000998', 'F1-GUARDIAN', 'guardian',
   'f1480000-0000-0000-0000-000000000003', 'Foyer', 'Titulaire', 'active', 'female'),
  ('f1490000-0000-0000-0000-000000000999', 'F1-ADMIN', 'admin', NULL,
   'Admin', 'Test', 'active', 'male');

INSERT INTO public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES
  ('f1490000-0000-0000-0000-000000000997', ARRAY['francais'], 10, 'approved', 'Europe/Paris');

UPDATE public.households
   SET primary_guardian_id = 'f1490000-0000-0000-0000-000000000998'
 WHERE id = 'f1480000-0000-0000-0000-000000000003';

DO $request_account_one$
DECLARE
  v_reponse jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  v_reponse := public.demander_creneau_personnalise(
    'f1490000-0000-0000-0000-000000000001',
    'Europe/Paris', ARRAY[2,4,6]::smallint[], 18::smallint
  );
  IF v_reponse->>'etat' <> 'envoyee' THEN
    RAISE EXCEPTION 'F1 fixture: première demande valide absente';
  END IF;
END
$request_account_one$;

DO $request_account_two$
DECLARE
  v_reponse jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000002', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  v_reponse := public.demander_creneau_personnalise(
    'f1490000-0000-0000-0000-000000000002',
    'Europe/Paris', ARRAY[2,4,6]::smallint[], 18::smallint
  );
  IF v_reponse->>'etat' <> 'envoyee' THEN
    RAISE EXCEPTION 'F1 fixture: seconde demande valide absente';
  END IF;
END
$request_account_two$;

-- Les changements de statut privilégiés passent par le contexte admin du fixture.
SELECT set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000999', true);
SELECT set_config('request.jwt.claims',
  jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
UPDATE public.profiles SET account_status = 'disabled'
 WHERE id = 'f1490000-0000-0000-0000-000000000001';
UPDATE public.households SET status = 'suspended'
 WHERE id = 'f1480000-0000-0000-0000-000000000002';

DO $request_disabled_account$
DECLARE
  v_ok boolean := false;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  BEGIN
    PERFORM public.demander_creneau_personnalise(
      'f1490000-0000-0000-0000-000000000001',
      'Europe/Paris', ARRAY[2,4,6]::smallint[], 18::smallint
    );
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'ce profil n''est pas le votre ni celui de votre foyer' THEN
      v_ok := true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'F1: un compte désactivé a été accepté'; END IF;
END
$request_disabled_account$;

DO $request_suspended_household$
DECLARE
  v_ok boolean := false;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000002', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text, true);
  BEGIN
    PERFORM public.demander_creneau_personnalise(
      'f1490000-0000-0000-0000-000000000002',
      'Europe/Paris', ARRAY[2,4,6]::smallint[], 18::smallint
    );
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'profil d''apprentissage incomplet%' THEN
      v_ok := true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'F1: un foyer suspendu a été accepté'; END IF;
END
$request_suspended_household$;

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
  v_groupe uuid;
  v_groupe_rejoue uuid;
  v_sessions integer;
BEGIN
  v_capacite := public.app_config_int('groupe.capacite_adulte', 6);
  IF v_capacite < 1 THEN
    RAISE EXCEPTION 'F1 test fixture: capacité adulte invalide';
  END IF;

  -- Une demande sans jour ou sans heure est refusée avant toute écriture.
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000003', true);
  PERFORM set_config('request.jwt.claims',
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

  -- Un même tuteur peut envoyer les demandes de plusieurs élèves de son foyer.
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000998', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'guardian',
      'household_id', 'f1480000-0000-0000-0000-000000000003'
    ))::text, true);

  -- Tous les élèves valides partagent un seul foyer. Le quota compte les élèves.
  FOR v_i IN 1..(v_capacite + 1) LOOP
    v_id := ('f1490000-0000-0000-0000-' || lpad((v_i + 2)::text, 12, '0'))::uuid;
    v_reponse := public.demander_creneau_personnalise(
      v_id, CASE WHEN v_i = 1 THEN 'Europe/Brussels' ELSE 'Europe/Paris' END,
      CASE WHEN v_i = 1 THEN ARRAY[6,4,2,2]::smallint[]
           ELSE ARRAY[2,4,6]::smallint[] END,
      18::smallint
    );
    IF v_reponse->>'etat' <> 'envoyee' THEN
      RAISE EXCEPTION 'F1: demande non transmise à l''administration: %', v_reponse;
    END IF;
  END LOOP;

  -- Cet élève a rejoint une autre classe entre sa demande et le regroupement.
  INSERT INTO public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday,
     hour_local, timezone_iana, langue_code)
  VALUES
    ('f1470000-0000-0000-0000-000000000001', NULL, 'en_attente_enseignant',
     'adulte', v_capacite, 'Classe existante', 1, 17, 'Europe/Paris', 'francais');
  INSERT INTO public.groupe_membres (groupe_id, student_id)
  VALUES (
    'f1470000-0000-0000-0000-000000000001',
    'f1490000-0000-0000-0000-000000000003'
  );

  -- Une répétition réseau renvoie la même demande sans compter deux fois.
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

  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000999', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  IF public.cle_horaire_utc(
       ARRAY[2,4,6]::smallint[], ARRAY[18,18,18]::smallint[], 'Europe/Paris'
     ) IS DISTINCT FROM public.cle_horaire_utc(
       ARRAY[6,4,2]::smallint[], ARRAY[18,18,18]::smallint[], 'Europe/Brussels'
     ) THEN
    RAISE EXCEPTION 'M3: des créneaux équivalents Paris/Bruxelles sont séparés';
  END IF;
  SELECT pg_catalog.array_agg(n.jour_iso ORDER BY n.jour_iso)
    INTO v_jours
    FROM public.creneaux_normalises_utc(
      ARRAY[4,6,1]::smallint[], ARRAY[18,18,18]::smallint[], 'Asia/Tokyo'
    ) n;
  IF v_jours IS DISTINCT FROM ARRAY[1,4,6]::smallint[] THEN
    RAISE EXCEPTION 'M3: les jours Tokyo ne sont pas triés: %', v_jours;
  END IF;

  SELECT regroupement_id, nombre_eleves, quota, pret, jours, heures_locales
    INTO v_regroupement, v_count, v_quota, v_pret, v_jours, v_heures
    FROM public.regroupements_demandes_horaires_admin()
   WHERE regroupement_id = 'p:' || pg_catalog.md5(
     'adulte|francais|' ||
     public.cle_horaire_utc(
       ARRAY[2,4,6]::smallint[], ARRAY[18,18,18]::smallint[], 'Europe/Paris'
     )
   );
  IF v_count <> v_capacite OR v_quota <> v_capacite OR NOT v_pret THEN
    RAISE EXCEPTION 'F1 quota: regroupement=% eleves=% quota=% pret=%',
      v_regroupement, v_count, v_quota, v_pret;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.demandes_horaires_famille
     WHERE eleve_id = 'f1490000-0000-0000-0000-000000000003'
       AND etat = 'envoyee'
  ) THEN
    RAISE EXCEPTION 'M2 fixture: la demande de l''élève déjà groupé manque';
  END IF;
  IF v_jours IS DISTINCT FROM ARRAY[2,4,6]::smallint[] THEN
    RAISE EXCEPTION 'F1 normalisation des jours incorrecte: %', v_jours;
  END IF;
  IF v_fuseau <> 'UTC'
     OR v_heures IS DISTINCT FROM ARRAY(
       SELECT n.heure_locale
       FROM public.creneaux_normalises_utc(
         ARRAY[2,4,6]::smallint[], ARRAY[18,18,18]::smallint[], 'Europe/Paris'
       ) n ORDER BY n.jour_iso, n.heure_locale
     )::smallint[] THEN
    RAISE EXCEPTION 'M3: horaire de référence UTC incorrect: % %', v_fuseau, v_heures;
  END IF;

  v_groupe := public.creer_classe_depuis_regroupement(
    v_regroupement, 'c1200000-0000-0000-0000-000000000001', 'Classe F1 C-12'
  );
  v_groupe_rejoue := public.creer_classe_depuis_regroupement(
    v_regroupement, 'c1200000-0000-0000-0000-000000000001', 'Classe F1 C-12'
  );
  IF v_groupe_rejoue <> v_groupe
     OR NOT EXISTS (
       SELECT 1 FROM public.groupes
       WHERE id = v_groupe AND teacher_id IS NULL
         AND etat = 'en_attente_enseignant'
     )
     OR (SELECT count(*) FROM public.groupe_membres
         WHERE groupe_id = v_groupe AND left_at IS NULL) <> v_quota THEN
    RAISE EXCEPTION 'C-12: classe en attente, membres ou idempotence invalides';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.demandes_horaires_famille
     WHERE eleve_id = 'f1490000-0000-0000-0000-000000000003'
       AND etat = 'refusee' AND motif = 'refus_direction'
  ) OR EXISTS (
    SELECT 1 FROM public.groupe_membres
     WHERE groupe_id = v_groupe
       AND student_id = 'f1490000-0000-0000-0000-000000000003'
       AND left_at IS NULL
  ) THEN
    RAISE EXCEPTION 'M2 ECHEC : élève déjà groupé ajouté ou demande non clôturée';
  END IF;
  SELECT count(*) INTO v_sessions FROM public.sessions WHERE groupe_id = v_groupe;
  IF v_sessions <> 0 THEN
    RAISE EXCEPTION 'C-12: séances matérialisées avant affectation: %', v_sessions;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000997', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'teacher'))::text, true);
  IF EXISTS (SELECT 1 FROM public.mes_groupes_v WHERE groupe_id = v_groupe) THEN
    RAISE EXCEPTION 'C-12: mes_groupes_v expose une classe sans enseignant';
  END IF;
  v_ok := false;
  BEGIN
    PERFORM public.autoriser_jeton_video(
      'c1200000-0000-0000-0000-000000000099',
      'f1490000-0000-0000-0000-000000000003',
      'wss://cloud.example.test', 'wss://self.example.test'
    );
  EXCEPTION WHEN OTHERS THEN
    v_ok := SQLERRM = 'seance introuvable';
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'C-12: jeton vidéo accordé sans séance'; END IF;
  IF public.brouillon_cahier('c1200000-0000-0000-0000-000000000099') IS NOT NULL THEN
    RAISE EXCEPTION 'C-12: cahier de séance rendu sans séance';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000996', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'controller'))::text, true);
  v_ok := false;
  BEGIN
    PERFORM public.rejoindre_observation('c1200000-0000-0000-0000-000000000099');
  EXCEPTION WHEN OTHERS THEN
    v_ok := SQLERRM = 'seance introuvable';
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'C-12: observation possible sans séance affectée'; END IF;

  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000998', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'guardian', 'household_id', 'f1480000-0000-0000-0000-000000000003'
    ))::text, true);
  v_ok := false;
  BEGIN
    PERFORM public.affecter_enseignant_classe(
      v_groupe, 'f1490000-0000-0000-0000-000000000997'
    );
  EXCEPTION WHEN OTHERS THEN
    v_ok := true;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'C-12: un tuteur a affecté un enseignant'; END IF;

  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000999', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  PERFORM public.affecter_enseignant_classe(
    v_groupe, 'f1490000-0000-0000-0000-000000000997'
  );
  IF NOT EXISTS (
    SELECT 1 FROM public.groupes
    WHERE id = v_groupe AND teacher_id = 'f1490000-0000-0000-0000-000000000997'
      AND etat = 'active'
  ) THEN
    RAISE EXCEPTION 'C-12: affectation ne rend pas la classe active';
  END IF;
  SELECT count(*) INTO v_sessions FROM public.sessions WHERE groupe_id = v_groupe;
  IF v_sessions < 1 OR EXISTS (
    SELECT 1 FROM public.sessions
    WHERE groupe_id = v_groupe AND teacher_id <> 'f1490000-0000-0000-0000-000000000997'
  ) THEN
    RAISE EXCEPTION 'C-12: séances absentes ou sans enseignant affecté';
  END IF;
  v_ok := false;
  BEGIN
    PERFORM public.affecter_enseignant_classe(
      v_groupe, 'f1490000-0000-0000-0000-000000000997'
    );
  EXCEPTION WHEN OTHERS THEN
    v_ok := true;
  END;
  IF NOT v_ok THEN RAISE EXCEPTION 'C-12: une double affectation a été acceptée'; END IF;

  -- Le tuteur ne reçoit que l'état de l'élève de son foyer.
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000998', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'guardian',
      'household_id', 'f1480000-0000-0000-0000-000000000003'
    ))::text, true);
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
    RAISE EXCEPTION 'F1 ACL: table_select=%, demande_anon=%, admin_group_anon=%, owner=%, acl=%',
      pg_catalog.has_table_privilege(
        'authenticated', 'public.demandes_horaires_famille', 'SELECT'),
      pg_catalog.has_function_privilege(
        'anon', 'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)', 'EXECUTE'),
      pg_catalog.has_function_privilege(
        'anon', 'public.regroupements_demandes_horaires_admin()', 'EXECUTE'),
      (SELECT pg_catalog.pg_get_userbyid(relowner)
         FROM pg_catalog.pg_class WHERE oid = 'public.demandes_horaires_famille'::regclass),
      (SELECT relacl::text
         FROM pg_catalog.pg_class WHERE oid = 'public.demandes_horaires_famille'::regclass);
  END IF;

  -- La carte publiée par l'administration crée aussi une demande privée,
  -- sans exposer de disponibilité ou publier à nouveau la vitrine.
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000999', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text, true);
  v_offre := public.creer_offre_horaire(
    'adulte', 'francais', 'Europe/Paris', ARRAY[1,3,5]::smallint[], 20::smallint, NULL
  );
  PERFORM public.publier_offre_horaire(v_offre);
  PERFORM set_config('request.jwt.claim.sub', 'f1490000-0000-0000-0000-000000000998', true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object(
      'role', 'guardian',
      'household_id', 'f1480000-0000-0000-0000-000000000003'
    ))::text, true);
  v_id := ('f1490000-0000-0000-0000-' || lpad((v_capacite + 4)::text, 12, '0'))::uuid;
  v_result := public.choisir_offre_horaire(v_id, v_offre, 'Europe/Paris');
  IF NOT EXISTS (
    SELECT 1 FROM public.demandes_horaires_famille
     WHERE eleve_id = v_id AND source = 'offre' AND offre_id = v_offre
       AND etat = 'envoyee'
  ) THEN
    RAISE EXCEPTION 'F1: choix d''une carte non transmis à l''administration';
  END IF;

  -- M1 : le retrait doit couvrir l'intention de vitrine (source=offre) autant
  -- que les demandes personnalisées, afin de libérer le quota et le choix suivant.
  PERFORM public.retirer_demande_horaire(v_id, 'test retrait source offre');
  IF EXISTS (
    SELECT 1 FROM public.demandes_horaires_famille
     WHERE eleve_id = v_id AND etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')
  ) THEN
    RAISE EXCEPTION 'M1 ECHEC : demande source offre encore active';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.intentions_horaire
     WHERE eleve_id = v_id AND etat = 'retiree'
       AND retrait_motif = 'test retrait source offre'
  ) THEN
    RAISE EXCEPTION 'M1 ECHEC : intention source offre non retiree';
  END IF;

  RAISE NOTICE 'F1: demandes privées, regroupement par élèves, quota serveur, états et ACL vérifiés';
END
$quota$;

ROLLBACK;
