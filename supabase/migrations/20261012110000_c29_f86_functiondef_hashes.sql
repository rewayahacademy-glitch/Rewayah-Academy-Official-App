BEGIN;
SET LOCAL search_path = '';

-- Record the PG17 replayed function-definition hashes from Claude's review
-- (Questions!A670). The bodies are unchanged in this migration.
COMMENT ON FUNCTION private.c29_attribuer_mission_controle() IS
  'F86 candidate allowlist: signature=private.c29_attribuer_mission_controle(); md5_functiondef=ceb2ac64c99895fa5c97d3f4b92bcf87; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';
COMMENT ON FUNCTION private.c29_clore_mission_controle() IS
  'F86 candidate allowlist: signature=private.c29_clore_mission_controle(); md5_functiondef=f26da770b43eea7634344dc85896ea86; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';
COMMENT ON FUNCTION public.demarrer_mission_controle(uuid) IS
  'F86 candidate allowlist: signature=public.demarrer_mission_controle(uuid); md5_functiondef=3fe3b44c1d1451f72dcc0d0e47ceffcb; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';
COMMENT ON FUNCTION public.ma_mission_controle() IS
  'F86 candidate allowlist: signature=public.ma_mission_controle(); md5_functiondef=bfc289f725aaf511f497e4c81faebf69; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';
COMMENT ON FUNCTION public.historique_tirages(text,text,integer,integer) IS
  'F86 candidate allowlist: signature=public.historique_tirages(text,text,integer,integer); md5_functiondef=f25154e7e0fbf38753a9da9a20ad7f72; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';
COMMENT ON FUNCTION public.declarer_conflit_mission(uuid,uuid) IS
  'F86 candidate allowlist: signature=public.declarer_conflit_mission(uuid,uuid); md5_functiondef=ec0543210cae0d373ef9f38749e4b136; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12.';

COMMENT ON FUNCTION public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid) IS
  'F79 candidate allowlist: signature=public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid); md5_functiondef=1949480f7b43b7de9724049cf7f247e1; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12. Must-pass: admin account with aal2 grants only active teacher/admin/controller profiles; grant is scoped, audited and idempotent; aal1/non-admin cannot grant.';
COMMENT ON FUNCTION public.retirer_capacite_controle(uuid,text,uuid) IS
  'F79 candidate allowlist: signature=public.retirer_capacite_controle(uuid,text,uuid); md5_functiondef=d95932d9af9c9ed55111ec1fdb0cb29b; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12. Must-pass: only active admin aal2 revokes; revocation is immediate, scoped, audited and idempotent.';
COMMENT ON FUNCTION public.ma_capacite_controle_active() IS
  'F79 candidate allowlist: signature=public.ma_capacite_controle_active(); md5_functiondef=c9fb15780e387e635e2861732e133229; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude; date=2026-10-12. Must-pass: only auth.uid() active capability is evaluated; account, role, expiry, revocation and aal2 are checked.';

DO $postflight$
DECLARE
  v_signature text;
  v_expected text;
  v_actual text;
BEGIN
  FOR v_signature, v_expected IN
    SELECT * FROM (VALUES
      ('private.c29_attribuer_mission_controle()', 'ceb2ac64c99895fa5c97d3f4b92bcf87'),
      ('private.c29_clore_mission_controle()', 'f26da770b43eea7634344dc85896ea86'),
      ('public.demarrer_mission_controle(uuid)', '3fe3b44c1d1451f72dcc0d0e47ceffcb'),
      ('public.ma_mission_controle()', 'bfc289f725aaf511f497e4c81faebf69'),
      ('public.historique_tirages(text,text,integer,integer)', 'f25154e7e0fbf38753a9da9a20ad7f72'),
      ('public.declarer_conflit_mission(uuid,uuid)', 'ec0543210cae0d373ef9f38749e4b136'),
      ('public.accorder_capacite_controle(uuid,timestamptz,timestamptz,boolean,uuid[],uuid[],uuid)', '1949480f7b43b7de9724049cf7f247e1'),
      ('public.retirer_capacite_controle(uuid,text,uuid)', 'd95932d9af9c9ed55111ec1fdb0cb29b'),
      ('public.ma_capacite_controle_active()', 'c9fb15780e387e635e2861732e133229')
    ) AS expected(signature, md5_functiondef)
  LOOP
    v_actual := pg_catalog.md5(pg_catalog.pg_get_functiondef(
      pg_catalog.to_regprocedure(v_signature)
    ));
    IF v_actual IS DISTINCT FROM v_expected THEN
      RAISE EXCEPTION 'C-29 F86 hash mismatch for %: expected %, got %',
        v_signature, v_expected, v_actual;
    END IF;
    IF coalesce(pg_catalog.strpos(
      pg_catalog.obj_description(pg_catalog.to_regprocedure(v_signature)::oid, 'pg_proc'),
      'md5_functiondef=' || v_expected || ';'
    ), 0) = 0 THEN
      RAISE EXCEPTION 'C-29 F86 allowlist metadata missing for %', v_signature;
    END IF;
  END LOOP;
END
$postflight$;

COMMIT;
