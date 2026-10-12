-- B-07 — un titulaire guardian peut créer son profil d'apprenant adulte
-- sur le même profile_id, sans nouveau compte ni changement de rôle.
-- Scénario transactionnel : toutes les données de test sont annulées.
BEGIN;

INSERT INTO auth.users (id, email)
VALUES ('b0700000-0000-0000-0000-000000000001', 'b07-titulaire@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('b0700000-0000-0000-0000-000000000101', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('b0700000-0000-0000-0000-000000000001', 'B07-TITULAIRE', 'guardian',
   'b0700000-0000-0000-0000-000000000101', 'Adulte', 'Titulaire',
   'active'::public.account_status, 'female');

DO $scenario$
DECLARE
  v_id uuid := 'b0700000-0000-0000-0000-000000000001';
  v_profile uuid;
  v_count integer;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_id::text, true);
  PERFORM set_config(
    'request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'guardian'))::text,
    true
  );

  IF public.profil_eleve_titulaire_existe() THEN
    RAISE EXCEPTION 'B-07: une fiche titulaire est annoncée avant création';
  END IF;

  v_profile := public.creer_profil_eleve_titulaire();
  IF v_profile IS DISTINCT FROM v_id THEN
    RAISE EXCEPTION 'B-07: la fiche ne réutilise pas le profil du titulaire';
  END IF;

  IF public.creer_profil_eleve_titulaire() IS DISTINCT FROM v_id THEN
    RAISE EXCEPTION 'B-07: une répétition idempotente a renvoyé un autre profil';
  END IF;
  IF NOT public.profil_eleve_titulaire_existe() THEN
    RAISE EXCEPTION 'B-07: la lecture serveur n''a pas détecté la fiche créée';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.student_profiles sp
  WHERE sp.titulaire_profile_id = v_id
    AND sp.profile_id = v_id
    AND sp.student_type = 'autonomous'
    AND sp.cohorte = 'adulte_18_plus'
    AND sp.deleted_at IS NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'B-07: attendu une seule fiche adulte titulaire, reçu %', v_count;
  END IF;

  IF (SELECT p.role FROM public.profiles p WHERE p.id = v_id) <> 'guardian' THEN
    RAISE EXCEPTION 'B-07: le rôle du titulaire a été modifié';
  END IF;

  IF NOT public.peut_decrire_apprenant(v_id) THEN
    RAISE EXCEPTION 'B-07: le titulaire ne peut pas décrire sa propre fiche';
  END IF;

END
$scenario$;

DO $negative_student$
DECLARE
  v_denied boolean := false;
BEGIN
  PERFORM set_config(
    'request.jwt.claim.sub', 'b0700000-0000-0000-0000-000000000001', true
  );
  PERFORM set_config(
    'request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'student'))::text,
    true
  );
  BEGIN
    PERFORM public.profil_eleve_titulaire_existe();
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-07: un rôle student a lu la capacité du titulaire';
  END IF;
  v_denied := false;
  BEGIN
    PERFORM public.creer_profil_eleve_titulaire();
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'création réservée au titulaire connecté' THEN
      v_denied := true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'B-07: un rôle student a pu appeler la création titulaire';
  END IF;
END
$negative_student$;

ROLLBACK;
