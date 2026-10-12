BEGIN;

-- C-29 reads the effective teacher from the authoritative B-09 append-only
-- event stream. sessions.teacher_id remains the titular teacher.
CREATE FUNCTION private.c29_enseignant_effectif_session(p_session_id uuid)
RETURNS uuid
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
  SELECT CASE
    WHEN r.evenement IN ('remplacement_pris', 'remplacement_designe_admin')
      THEN r.enseignant_remplacant_id
    ELSE s.teacher_id
  END
  FROM public.sessions s
  LEFT JOIN LATERAL (
    SELECT x.evenement, x.enseignant_remplacant_id
      FROM public.remplacements_seance x
     WHERE x.session_id = s.id
     ORDER BY x.cree_le DESC, x.id DESC
     LIMIT 1
  ) r ON true
  WHERE s.id = p_session_id AND s.deleted_at IS NULL;
$function$;
ALTER FUNCTION private.c29_enseignant_effectif_session(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.c29_enseignant_effectif_session(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $postflight$
BEGIN
  IF to_regprocedure('private.c29_enseignant_effectif_session(uuid)') IS NULL
     OR has_function_privilege(
       'authenticated', 'private.c29_enseignant_effectif_session(uuid)', 'EXECUTE'
     )
     OR has_function_privilege(
       'service_role', 'private.c29_enseignant_effectif_session(uuid)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C29: effective-teacher helper is absent or exposed';
  END IF;
END;
$postflight$;

COMMIT;
