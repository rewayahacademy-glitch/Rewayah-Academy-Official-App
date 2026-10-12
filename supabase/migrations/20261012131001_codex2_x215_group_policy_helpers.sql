BEGIN;

CREATE SCHEMA IF NOT EXISTS codex2_private AUTHORIZATION postgres;
REVOKE ALL ON SCHEMA codex2_private FROM PUBLIC, anon, service_role, agent_ro;
GRANT USAGE ON SCHEMA codex2_private TO authenticated;

CREATE OR REPLACE FUNCTION codex2_private.peut_lire_groupe(p_groupe_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce(
    (public.app_role() = 'admin' AND public.app_account_valid())
    OR EXISTS (
      SELECT 1 FROM public.groupes g
      WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.groupe_membres m
      JOIN public.profiles p ON p.id = m.student_id
      WHERE m.groupe_id = p_groupe_id
        AND m.left_at IS NULL
        AND (p.id = auth.uid() OR p.household_id = public.app_household_id())
    ),
    false
  );
$function$;

CREATE OR REPLACE FUNCTION codex2_private.peut_lire_membre_groupe(
  p_groupe_id uuid,
  p_student_id uuid
)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce(
    (public.app_role() = 'admin' AND public.app_account_valid())
    OR EXISTS (
      SELECT 1 FROM public.groupes g
      WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = p_student_id
        AND (p.id = auth.uid() OR p.household_id = public.app_household_id())
    ),
    false
  );
$function$;

ALTER FUNCTION codex2_private.peut_lire_groupe(uuid) OWNER TO postgres;
ALTER FUNCTION codex2_private.peut_lire_membre_groupe(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION codex2_private.peut_lire_groupe(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION codex2_private.peut_lire_membre_groupe(uuid, uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION codex2_private.peut_lire_groupe(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION codex2_private.peut_lire_membre_groupe(uuid, uuid) TO authenticated;

DROP POLICY groupes_lecture ON public.groupes;
CREATE POLICY groupes_lecture ON public.groupes
  FOR SELECT TO authenticated
  USING (codex2_private.peut_lire_groupe(groupes.id));

DROP POLICY groupe_membres_lecture ON public.groupe_membres;
CREATE POLICY groupe_membres_lecture ON public.groupe_membres
  FOR SELECT TO authenticated
  USING (
    codex2_private.peut_lire_membre_groupe(
      groupe_membres.groupe_id,
      groupe_membres.student_id
    )
  );

DO $verification$
BEGIN
  IF NOT has_function_privilege('authenticated', 'codex2_private.peut_lire_groupe(uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'codex2_private.peut_lire_membre_groupe(uuid,uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'codex2_private.peut_lire_groupe(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'codex2_private.peut_lire_membre_groupe(uuid,uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'codex2_private.peut_lire_groupe(uuid)', 'EXECUTE')
     OR has_function_privilege('service_role', 'codex2_private.peut_lire_membre_groupe(uuid,uuid)', 'EXECUTE')
     OR EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid IN (
         'codex2_private.peut_lire_groupe(uuid)'::regprocedure,
         'codex2_private.peut_lire_membre_groupe(uuid,uuid)'::regprocedure
       )
         AND (
           NOT p.prosecdef
           OR p.provolatile <> 's'
           OR p.proowner <> 'postgres'::regrole
           OR NOT coalesce(p.proconfig, array[]::text[]) @> array['search_path=""']
         )
     ) THEN
    RAISE EXCEPTION 'X2-15: ACL des helpers de policy invalide';
  END IF;
END;
$verification$;

COMMIT;
