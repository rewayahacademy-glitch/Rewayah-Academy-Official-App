-- PARCOURS-BOUT-EN-BOUT (directeur, 22/11/2026) : la frise de l'inscription
-- montre, pour la demande d'admission, quand elle a ete envoyee et quand la
-- direction a decide (precisions demandees ou acceptation). Additif : meme
-- signature, deux cles de plus dans l'objet rendu (`recue_le`, `decision_le`),
-- instants UTC (timestamptz) ; le client les lit a l'heure de la personne.
-- Aucun effacement ni suppression. Aucun nouvel etat : « lue par la direction »
-- n'a pas de signal serveur tant qu'aucun geste n'a eu lieu, la frise le dit
-- « en cours ».
BEGIN;

CREATE OR REPLACE FUNCTION public.ma_demande_admission()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
           'etape', c.etape,
           'etat', c.etat,
           'issue', c.issue,
           'recue_le', c.recue_le,
           'decision_le', (
             SELECT e.cree_le
               FROM public.candidature_evenements e
              WHERE e.candidature_id = c.id AND e.type = 'transition'
                AND (e.etape_apres IS DISTINCT FROM e.etape_avant
                     OR e.etat_apres IS DISTINCT FROM e.etat_avant
                     OR e.issue_apres IS DISTINCT FROM e.issue_avant)
              ORDER BY e.cree_le DESC, e.id DESC
              LIMIT 1),
           'precisions', CASE WHEN c.etat = 'a_completer' THEN (
             SELECT e.details ->> 'precisions'
               FROM public.candidature_evenements e
              WHERE e.candidature_id = c.id AND e.details ? 'precisions'
              ORDER BY e.cree_le DESC
              LIMIT 1) END)
    FROM public.candidatures c
   WHERE c.profile_id = auth.uid() AND c.type_code IN ('famille', 'eleve_adulte')
   LIMIT 1;
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.ma_demande_admission()'::pg_catalog.regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-22. Frise de l''inscription.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)), 'TITULAIRE_SELF'));
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'FRISE-ADMISSION : DEFINER ou ACL invalide pour %', v_oid;
  END IF;
END;
$droits$;

COMMIT;
