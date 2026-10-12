-- F86 null-input cases kept independent of scenarios_offres_personnalisees.
BEGIN;

INSERT INTO auth.users (id, email)
VALUES ('f8600000-0000-0000-0000-000000000001', 'f86-null-admin@example.test');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('f8600000-0000-0000-0000-000000000001', 'F86-NULL-ADMIN', 'admin',
   'F86', 'Admin', 'active', 'male');

SELECT set_config('request.jwt.claim.sub', 'f8600000-0000-0000-0000-000000000001', true);
SELECT set_config(
  'request.jwt.claims',
  jsonb_build_object('app_metadata', jsonb_build_object('role', 'admin'))::text,
  true
);

DO $f86_null_inputs$
DECLARE
  v_state text;
  v_message text;
BEGIN
  v_state := NULL;
  v_message := NULL;
  BEGIN
    PERFORM public.creer_classe_depuis_regroupement(
      NULL::uuid, 'f8600000-0000-0000-0000-000000000099', 'F86 null grouping key'
    );
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
  END;
  IF v_state IS DISTINCT FROM '22023' THEN
    RAISE EXCEPTION 'F86: NULL regroupement id must fail parameter validation, got SQLSTATE %', v_state;
  END IF;

  v_state := NULL;
  v_message := NULL;
  BEGIN
    PERFORM public.creer_offre_horaire(
      'adulte', 'francais', 'Europe/Paris', NULL::smallint[], 20::smallint, NULL::smallint
    );
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
  END;
  IF v_state IS DISTINCT FROM 'P0001' OR v_message NOT LIKE 'jours invalides :%' THEN
    RAISE EXCEPTION 'F86: NULL weekday array must fail the invalid-days check, got SQLSTATE % and message %',
      v_state, v_message;
  END IF;
END
$f86_null_inputs$;

ROLLBACK;
