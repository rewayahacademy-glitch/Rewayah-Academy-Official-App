-- F86 : les transitions de fuseau ne sont visibles qu'a un compte admin valide.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8620000-0000-0000-0000-000000000001', 'f86-timezone-admin-disabled@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f862ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8620000-0000-0000-0000-000000000001', 'F86TZADMIN00001', 'admin',
   'f862ffff-0000-0000-0000-000000000001', 'F86', 'Disabled', 'disabled');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8620000-0000-0000-0000-000000000099', true);
SELECT set_config('request.jwt.claim.sub', 'f8620000-0000-0000-0000-000000000099', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_admin_without_profile$
BEGIN
  BEGIN
    PERFORM 1 FROM public.transitions_fuseau_a_venir();
    RAISE EXCEPTION 'F86: transitions_fuseau_a_venir a accepte un JWT admin sans profil';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$f86_admin_without_profile$;

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8620000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8620000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_disabled_admin$
BEGIN
  BEGIN
    PERFORM 1 FROM public.transitions_fuseau_a_venir();
    RAISE EXCEPTION 'F86: transitions_fuseau_a_venir a accepte un admin desactive';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END
$f86_disabled_admin$;

RESET ROLE;
ROLLBACK;
