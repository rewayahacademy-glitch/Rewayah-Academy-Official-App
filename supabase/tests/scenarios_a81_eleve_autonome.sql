BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('a8100000-0000-0000-0000-000000000001', 'a81-solo@example.test'),
 ('a8100000-0000-0000-0000-000000000002', 'a81-famille@example.test'),
 ('a8100000-0000-0000-0000-000000000003', 'a81-parent-seul@example.test'),
 ('a8100000-0000-0000-0000-000000000004', 'a81-child@example.test');

DO $scenario$
DECLARE
  v_solo uuid := 'a8100000-0000-0000-0000-000000000001';
  v_famille uuid := 'a8100000-0000-0000-0000-000000000002';
  v_parent uuid := 'a8100000-0000-0000-0000-000000000003';
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_solo::text, true);
  PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
  PERFORM public.creer_profil_inscription('guardian', 'Adulte', 'Solo', NULL, 'Europe/Paris', true);
  -- La creation attend encore le KYC; la capacite ne s'ouvre qu'apres activation.
  UPDATE public.profiles SET account_status = 'active' WHERE id = v_solo;
  IF NOT public.ma_capacite_eleve() OR
     (SELECT role FROM public.profiles WHERE id = v_solo) <> 'guardian' THEN
    RAISE EXCEPTION 'A81: Moi uniquement doit créer la capacité sans changer le rôle';
  END IF;
  UPDATE public.profiles SET account_status = 'disabled' WHERE id = v_solo;
  IF public.ma_capacite_eleve() THEN
    RAISE EXCEPTION 'A81: un compte desactive ne conserve pas la capacite eleve';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_famille::text, true);
  PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
  PERFORM public.creer_profil_inscription('guardian', 'Parent', 'Famille', NULL, 'Europe/Paris', true);
  UPDATE public.profiles SET account_status = 'active' WHERE id = v_famille;
  IF NOT public.ma_capacite_eleve() THEN
    RAISE EXCEPTION 'A81: famille avec parent_suit_des_cours doit créer la capacité';
  END IF;
  INSERT INTO public.profiles
    (id, immutable_id, role, household_id, first_name, last_name, account_status)
  SELECT 'a8100000-0000-0000-0000-000000000004', 'A81-CHILD', 'student', household_id,
         'Enfant', 'Famille', 'pending_kyc'
  FROM public.profiles WHERE id = v_famille;
  INSERT INTO public.student_profiles(profile_id, student_type)
  VALUES ('a8100000-0000-0000-0000-000000000004', 'minor');

  PERFORM set_config('request.jwt.claim.sub', v_parent::text, true);
  PERFORM set_config('request.jwt.claims', '{"app_metadata":{"role":"guardian"}}', true);
  PERFORM public.creer_profil_inscription('guardian', 'Parent', 'Sans cours', NULL, 'Europe/Paris', false);
  IF public.ma_capacite_eleve() THEN
    RAISE EXCEPTION 'A81: tuteur sans cours doit rester sans capacité autonome';
  END IF;
END
$scenario$;

ROLLBACK;
