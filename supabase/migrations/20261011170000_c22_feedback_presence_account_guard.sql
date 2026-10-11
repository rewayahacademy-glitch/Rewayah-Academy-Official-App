BEGIN;

-- Feedback trends are only visible to a currently valid account. The earlier
-- view filtered by role and teacher ownership but did not reject suspended
-- accounts whose JWT remained valid.
CREATE OR REPLACE VIEW public.tendance_feedback_v
WITH (security_barrier = true)
AS
SELECT
  f.groupe_id,
  f.question_id,
  count(*) AS nombre_echantillons,
  count(*) FILTER (WHERE f.reponse = 'difficile') AS n_difficile,
  count(*) FILTER (WHERE f.reponse = 'bien') AS n_bien,
  count(*) FILTER (WHERE f.reponse = 'tres_bien') AS n_tres_bien
FROM public.session_feedback f
JOIN public.groupes g ON g.id = f.groupe_id
WHERE f.question_id = 'comprehension'
  AND coalesce(public.app_account_valid(), false)
  AND (g.teacher_id = auth.uid() OR public.app_role() = 'admin')
GROUP BY f.groupe_id, f.question_id
HAVING count(*) >= public.app_config_int('feedback_seuil_tendance', 5);

REVOKE ALL ON public.tendance_feedback_v
  FROM PUBLIC, anon, agent_ro;
GRANT SELECT ON public.tendance_feedback_v TO authenticated;

-- The scoped presence RPC is for authenticated application users only.
REVOKE EXECUTE ON FUNCTION public.etat_presence(uuid, uuid) FROM agent_ro;

DO $postflight$
DECLARE
  v_view_definition text;
BEGIN
  SELECT pg_catalog.pg_get_viewdef('public.tendance_feedback_v'::regclass, true)
    INTO v_view_definition;

  IF v_view_definition !~* 'app_account_valid'
     OR pg_catalog.has_table_privilege(
       'anon', 'public.tendance_feedback_v', 'SELECT'
     )
     OR pg_catalog.has_table_privilege(
       'agent_ro', 'public.tendance_feedback_v', 'SELECT'
     )
     OR NOT pg_catalog.has_table_privilege(
       'authenticated', 'public.tendance_feedback_v', 'SELECT'
     )
     OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.etat_presence(uuid,uuid)', 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'C-22: feedback/presence ACL postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
