-- F86 : les sept signatures de mutation de groupes refusent role NULL et compte invalide.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('f8670000-0000-0000-0000-000000000001', 'f86-group-guard-active@example.test'),
  ('f8670000-0000-0000-0000-000000000002', 'f86-group-guard-disabled@example.test');

INSERT INTO public.households (id, timezone) VALUES
  ('f867ffff-0000-0000-0000-000000000001', 'Europe/Paris');

INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('f8670000-0000-0000-0000-000000000001', 'F86GROUPACTIVE001', 'teacher',
   'f867ffff-0000-0000-0000-000000000001', 'F86', 'GroupActive', 'active'),
  ('f8670000-0000-0000-0000-000000000002', 'F86GROUPDISABL002', 'admin',
   'f867ffff-0000-0000-0000-000000000001', 'F86', 'GroupDisabled', 'disabled');

SET LOCAL ROLE authenticated;
SELECT set_config('test.uid', 'f8670000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claim.sub', 'f8670000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{}}', true);

DO $f86_missing_role$
BEGIN
  BEGIN
    PERFORM public.creer_groupe(NULL::uuid, NULL::text, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint);
    RAISE EXCEPTION 'F86: creer_groupe 6 args a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'creation de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.modifier_groupe(NULL::uuid, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint);
    RAISE EXCEPTION 'F86: modifier_groupe 5 args a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'modification de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.ajouter_eleve_groupe(NULL::uuid, NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: ajouter_eleve_groupe a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'ajout d''un eleve a un groupe reserve a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.retirer_eleve_groupe(NULL::uuid, NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: retirer_eleve_groupe a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'retrait d''un eleve d''un groupe reserve a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.cloturer_groupe(NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: cloturer_groupe a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'cloture de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.creer_groupe(NULL::uuid, NULL::text, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint, NULL::text, NULL::smallint);
    RAISE EXCEPTION 'F86: creer_groupe 8 args a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'creation de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.modifier_groupe(NULL::uuid, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint, NULL::text, NULL::smallint);
    RAISE EXCEPTION 'F86: modifier_groupe 7 args a accepte role NULL';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'modification de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
END
$f86_missing_role$;

SELECT set_config('test.uid', 'f8670000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claim.sub', 'f8670000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

DO $f86_disabled_admin$
BEGIN
  BEGIN
    PERFORM public.creer_groupe(NULL::uuid, NULL::text, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint);
    RAISE EXCEPTION 'F86: creer_groupe 6 args a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'creation de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.modifier_groupe(NULL::uuid, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint);
    RAISE EXCEPTION 'F86: modifier_groupe 5 args a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'modification de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.ajouter_eleve_groupe(NULL::uuid, NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: ajouter_eleve_groupe a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'ajout d''un eleve a un groupe reserve a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.retirer_eleve_groupe(NULL::uuid, NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: retirer_eleve_groupe a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'retrait d''un eleve d''un groupe reserve a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.cloturer_groupe(NULL::uuid, NULL::text);
    RAISE EXCEPTION 'F86: cloturer_groupe a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'cloture de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.creer_groupe(NULL::uuid, NULL::text, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint, NULL::text, NULL::smallint);
    RAISE EXCEPTION 'F86: creer_groupe 8 args a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'creation de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.modifier_groupe(NULL::uuid, NULL::text, NULL::smallint, NULL::smallint, NULL::smallint, NULL::text, NULL::smallint);
    RAISE EXCEPTION 'F86: modifier_groupe 7 args a accepte compte desactive';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'modification de groupe reservee a l''administration' THEN RAISE; END IF;
  END;
END
$f86_disabled_admin$;

RESET ROLE;
ROLLBACK;
