-- OFFRES-I5 : le créneau personnalisé reste invisible avant le quota,
-- s'ouvre à 6 adultes (app_config), ne révèle aucun vivier et reste réessayable.
-- Rejoué après toutes les migrations sur une base jetable.
BEGIN;

INSERT INTO public.households (id, timezone)
SELECT ('f1480000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
       'Europe/Paris'
FROM generate_series(1, 7) AS g(n);

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT
  ('f1490000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
  'F1-ADULTE-' || g.n::text,
  'student',
  ('f1480000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
  'Adulte', g.n::text, 'pending_kyc', 'male'
FROM generate_series(1, 7) AS g(n);

INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy,
   langue_cours, cohorte, niveau_declare, objectif)
SELECT
  ('f1490000-0000-0000-0000-' || lpad(g.n::text, 12, '0'))::uuid,
  'autonomous', 'standard', 'forbidden',
  'francais', 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire'
FROM generate_series(1, 7) AS g(n);

DO $quota$
DECLARE
  v_i integer;
  v_id uuid;
  v_reponse jsonb;
  v_offre uuid;
  v_total integer;
  v_visible integer;
BEGIN
  FOR v_i IN 1..6 LOOP
    v_id := ('f1490000-0000-0000-0000-' || lpad(v_i::text, 12, '0'))::uuid;
    PERFORM set_config('test.uid', v_id::text, true);
    PERFORM set_config(
      'test.jwt',
      jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text,
      true
    );

    v_reponse := public.demander_creneau_personnalise(
      v_id, 'Europe/Paris', ARRAY[2, 4, 6]::smallint[], 3
    );

    IF v_i < 6 AND v_reponse->>'etat' <> 'en_attente_quota' THEN
      RAISE EXCEPTION 'F1 quota: demande % ouverte avant les six adultes: %',
        v_i, v_reponse;
    END IF;
    IF v_i = 6 AND v_reponse->>'etat' <> 'offre_ouverte' THEN
      RAISE EXCEPTION 'F1 quota: la sixième demande n''ouvre pas le créneau: %',
        v_reponse;
    END IF;
  END LOOP;

  v_offre := (v_reponse->>'offre_id')::uuid;
  SELECT count(*) INTO v_total
    FROM public.demandes_creneau_personnalise
   WHERE offre_id = v_offre AND etat = 'offre_ouverte';
  IF v_total <> 6 THEN
    RAISE EXCEPTION 'F1 quota: % demandes liées à l''offre, 6 attendues', v_total;
  END IF;

  SELECT count(*) INTO v_total
    FROM public.intentions_horaire
   WHERE offre_id = v_offre;
  IF v_total <> 0 THEN
    RAISE EXCEPTION 'F1 quota: l''ouverture ne doit pas inscrire les familles';
  END IF;

  -- Une répétition réseau, même après l'ouverture, retourne le même résultat.
  PERFORM set_config(
    'test.uid',
    'f1490000-0000-0000-0000-000000000006',
    true
  );
  PERFORM set_config(
    'test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text,
    true
  );
  v_reponse := public.demander_creneau_personnalise(
    'f1490000-0000-0000-0000-000000000006',
    'Europe/Paris', ARRAY[2, 4, 6]::smallint[], 3
  );
  IF v_reponse->>'offre_id' IS DISTINCT FROM v_offre::text THEN
    RAISE EXCEPTION 'F1 idempotence: la répétition a changé d''offre: %', v_reponse;
  END IF;

  -- Une autre identité ne peut pas demander le créneau pour cet adulte.
  PERFORM set_config(
    'test.uid',
    'f1490000-0000-0000-0000-000000000007',
    true
  );
  BEGIN
    PERFORM public.demander_creneau_personnalise(
      'f1490000-0000-0000-0000-000000000001',
      'Europe/Paris', ARRAY[2, 4, 6]::smallint[], 3
    );
    RAISE EXCEPTION 'F1 relation: un autre compte a créé la demande';
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    IF position('pas le votre ni celui de votre foyer' IN SQLERRM) = 0 THEN
      RAISE;
    END IF;
  END;

  IF pg_catalog.has_function_privilege(
       'anon',
       'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)',
       'EXECUTE'
     )
     OR pg_catalog.has_function_privilege(
       'agent_ro',
       'public.demander_creneau_personnalise(uuid,text,smallint[],smallint)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'F1 ACL: anon ou agent_ro peut créer une demande';
  END IF;

  -- La lecture directe sous un compte ne révèle que sa propre ligne.
  SET LOCAL ROLE authenticated;
  PERFORM set_config('test.uid', 'f1490000-0000-0000-0000-000000000001', true);
  PERFORM set_config(
    'test.jwt',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text,
    true
  );
  SELECT count(*) INTO v_visible
    FROM public.demandes_creneau_personnalise;
  IF v_visible <> 1 THEN
    RAISE EXCEPTION 'F1 confidentialité: un compte voit % demandes au lieu de sa seule demande',
      v_visible;
  END IF;
  RESET ROLE;

  RAISE NOTICE 'F1 quota: ouverture après 6 adultes, répétition idempotente, aucun engagement automatique, relation et RLS vérifiées';
END
$quota$;

ROLLBACK;
