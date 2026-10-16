-- F86 : un jeton admin doit aussi correspondre a un compte actif pour lire les dossiers.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8610000-0000-0000-0000-000000000001', 'f86-dossiers-admin-disabled@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f861ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8610000-0000-0000-0000-000000000001', 'F86DOSADMIN0001', 'admin',
   'f861ffff-0000-0000-0000-000000000001', 'F86', 'Disabled', 'disabled');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8610000-0000-0000-0000-000000000099', true);
SELECT set_config('request.jwt.claim.sub', 'f8610000-0000-0000-0000-000000000099', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_admin_without_profile$
BEGIN
  BEGIN
    PERFORM 1 FROM public.dossiers_en_attente();
    RAISE EXCEPTION 'F86: dossiers_en_attente a accepte un JWT admin sans profil';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'validation des dossiers reservee a l''administration' THEN RAISE; END IF;
  END;
END
$f86_admin_without_profile$;

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8610000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8610000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_disabled_admin$
BEGIN
  BEGIN
    PERFORM 1 FROM public.dossiers_en_attente();
    RAISE EXCEPTION 'F86: dossiers_en_attente a accepte un admin desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'validation des dossiers reservee a l''administration' THEN RAISE; END IF;
  END;
END
$f86_disabled_admin$;

RESET ROLE;
ROLLBACK;
