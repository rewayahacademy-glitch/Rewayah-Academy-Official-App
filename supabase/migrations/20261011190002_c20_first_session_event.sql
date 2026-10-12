-- C-20: record the first known scheduled session for each matching request.
BEGIN;

CREATE FUNCTION public.c20_record_first_session_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_started_at timestamptz;
BEGIN
  IF NEW.deleted_at IS NOT NULL
     OR NEW.status NOT IN ('planned', 'preflight', 'in_progress')
     OR NEW.groupe_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_started_at := NEW.started_at;
  INSERT INTO public.demande_evenements
    (demande_id, eleve_id, household_id, type, survenu_le)
  SELECT d.id, d.eleve_id, p.household_id, 'premiere_seance_prevue', v_started_at
    FROM public.demandes_horaires_famille d
    JOIN public.profiles p ON p.id = d.eleve_id AND p.deleted_at IS NULL
   WHERE d.groupe_id = NEW.groupe_id
     AND d.etat IN ('classe_validee', 'enseignant_affecte')
     AND p.household_id IS NOT NULL
  ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.c20_record_first_session_event()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER c20_sessions_first_timeline_event
  AFTER INSERT OR UPDATE OF started_at, status, deleted_at, groupe_id
  ON public.sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.c20_record_first_session_event();

DO $postflight$
BEGIN
  IF EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.c20_record_first_session_event()'::regprocedure
          AND p.prosecdef
     )
     OR has_function_privilege('anon', 'public.c20_record_first_session_event()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.c20_record_first_session_event()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.c20_record_first_session_event()', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.c20_record_first_session_event()', 'EXECUTE')
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
        WHERE t.tgname = 'c20_sessions_first_timeline_event'
          AND NOT t.tgisinternal
     ) THEN
    RAISE EXCEPTION 'C-20: first scheduled session event producer invalid';
  END IF;
END;
$postflight$;

COMMIT;
