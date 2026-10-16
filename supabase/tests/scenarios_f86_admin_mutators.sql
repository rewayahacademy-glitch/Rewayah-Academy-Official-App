-- F86 : les quatre RPC d'administration refusent un JWT admin sans profil
-- et un profil admin desactive. MD5 fournis par la revue Claude PG16.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8600000-0000-0000-0000-000000000001', 'f86-admin-disabled@example.test');

INSERT INTO public.households (id, timezone)
VALUES ('f86fffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8600000-0000-0000-0000-000000000001', 'F86ADMIN000001', 'admin',
   'f86fffff-0000-0000-0000-000000000001',
   'F86', 'Disabled', 'disabled');

DO $f86_admin_mutator_fingerprints$
DECLARE
  v_check record;
  v_actual text;
BEGIN
  FOR v_check IN
    SELECT * FROM (VALUES
      ('public.clore_regle(uuid,text)', '23aa85aa637e93ad3d27de78f0c157dd'),
      ('public.decider_demande(uuid,boolean,text)', 'ec9fe0b06d004bd701071201e3ad9707'),
      ('public.maj_eleve_pedagogie(uuid,text,text)', 'd520a13d7d56c740fdadc8291b7b0ac6'),
      ('public.poser_regle(uuid,text,integer,text)', 'a3c7d8e4a47b497ca8089389114eba8e')
    ) AS expected(signature, md5_functiondef)
  LOOP
    SELECT pg_catalog.md5(pg_catalog.pg_get_functiondef(v_check.signature::regprocedure))
      INTO v_actual;
    IF v_actual IS DISTINCT FROM v_check.md5_functiondef THEN
      RAISE EXCEPTION 'F86: empreinte inattendue pour % : %',
        v_check.signature, v_actual;
    END IF;
  END LOOP;
END
$f86_admin_mutator_fingerprints$;

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8600000-0000-0000-0000-000000000099', true);
SELECT set_config('request.jwt.claim.sub', 'f8600000-0000-0000-0000-000000000099', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_admin_without_profile$
BEGIN
  BEGIN
    PERFORM public.maj_eleve_pedagogie(NULL::uuid, NULL::text, NULL::text);
    RAISE EXCEPTION 'F86: maj_eleve_pedagogie a accepte un JWT admin sans profil';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur modifie le niveau ou la riwaya' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.poser_regle(NULL::uuid, NULL::text, NULL::integer, NULL::text);
    RAISE EXCEPTION 'F86: poser_regle a accepte un JWT admin sans profil';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur pose une regle' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.clore_regle(NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: clore_regle a accepte un JWT admin sans profil';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur clot une regle' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.decider_demande(NULL::uuid, false, NULL::text);
    RAISE EXCEPTION 'F86: decider_demande a accepte un JWT admin sans profil';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur tranche une demande' THEN RAISE; END IF;
  END;
END
$f86_admin_without_profile$;

RESET ROLE;
UPDATE public.profiles SET account_status = 'disabled'
WHERE id = 'f8600000-0000-0000-0000-000000000001';

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8600000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8600000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_disabled_admin$
BEGIN
  BEGIN
    PERFORM public.maj_eleve_pedagogie(NULL::uuid, NULL::text, NULL::text);
    RAISE EXCEPTION 'F86: maj_eleve_pedagogie a accepte un admin desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur modifie le niveau ou la riwaya' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.poser_regle(NULL::uuid, NULL::text, NULL::integer, NULL::text);
    RAISE EXCEPTION 'F86: poser_regle a accepte un admin desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur pose une regle' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.clore_regle(NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: clore_regle a accepte un admin desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur clot une regle' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.decider_demande(NULL::uuid, false, NULL::text);
    RAISE EXCEPTION 'F86: decider_demande a accepte un admin desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'seul un administrateur tranche une demande' THEN RAISE; END IF;
  END;
END
$f86_disabled_admin$;

RESET ROLE;
ROLLBACK;
