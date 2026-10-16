-- L1-07 (audit final 16/10/2026, P1-5) : `profiles.gender` n'est modifiable
-- que par un administrateur valide. Le titulaire de la ligne (enseignant) ne
-- peut pas changer son genre, mais garde le droit de modifier son prenom.
-- Scenario transactionnel : toutes les donnees de test sont annulees.
BEGIN;

INSERT INTO auth.users (id, email)
VALUES
  ('a1070000-0000-0000-0000-000000000001', 'l107-enseignant@example.test'),
  ('a1070000-0000-0000-0000-000000000002', 'l107-admin@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('a1070000-0000-0000-0000-000000000101', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('a1070000-0000-0000-0000-000000000001', 'L107-ENSEIGNANT', 'teacher',
   'a1070000-0000-0000-0000-000000000101', 'Enseignant', 'Test',
   -- provisional_active : 0089 exige les contrats signes pour un enseignant
   -- `active` ; ce scenario ne teste pas l'activation.
   'provisional_active'::public.account_status, 'male'),
  ('a1070000-0000-0000-0000-000000000002', 'L107-ADMIN', 'admin',
   'a1070000-0000-0000-0000-000000000101', 'Administrateur', 'Test',
   'active'::public.account_status, 'female');

-- Le titulaire (enseignant) tente de changer son propre genre : refuse.
SET LOCAL ROLE authenticated;
DO $teacher_gender$
DECLARE
  v_denied boolean := false;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'a1070000-0000-0000-0000-000000000001', true);
  PERFORM set_config(
    'request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'teacher'))::text,
    true
  );

  BEGIN
    UPDATE public.profiles SET gender = 'female'
    WHERE id = 'a1070000-0000-0000-0000-000000000001';
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;

  IF NOT v_denied THEN
    RAISE EXCEPTION 'L1-07: le titulaire a change son genre';
  END IF;
END
$teacher_gender$;

-- Le meme titulaire modifie son prenom : toujours permis.
DO $teacher_first_name$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.profiles SET first_name = 'Test2'
  WHERE id = 'a1070000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'L1-07: la mise a jour du prenom par le titulaire a touche % ligne(s)', v_count;
  END IF;
END
$teacher_first_name$;

-- L'administrateur valide modifie le genre d'un autre profil : permis.
DO $admin_gender$
DECLARE
  v_count integer;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'a1070000-0000-0000-0000-000000000002', true);
  PERFORM set_config(
    'request.jwt.claims',
    jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text,
    true
  );

  UPDATE public.profiles SET gender = 'female'
  WHERE id = 'a1070000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'L1-07: l''administrateur n''a pas modifie le genre (% ligne(s))', v_count;
  END IF;
END
$admin_gender$;

RESET ROLE;

-- Verification d'etat, sous le proprietaire : le genre du titulaire est bien
-- celui que l'administrateur a ecrit. Le refus du titulaire est prouve par
-- v_denied ci-dessus.
DO $etat$
DECLARE
  v_gender public.gender;
BEGIN
  SELECT p.gender INTO v_gender FROM public.profiles p
  WHERE p.id = 'a1070000-0000-0000-0000-000000000001';
  IF v_gender IS DISTINCT FROM 'female' THEN
    RAISE EXCEPTION 'L1-07: genre final attendu female, lu %', v_gender;
  END IF;
END
$etat$;

ROLLBACK;
