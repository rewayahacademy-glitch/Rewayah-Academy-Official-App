-- CONTRATS-MANQUANTS (6/6) : le travail a venir d'une classe et les
-- prerequis de l'enseignant.
--
-- 1. PortTravailAVenir (lib/core/tc_parcours/port_travail_a_venir.dart) est
--    compose cote client par TravailAVenir(PortAssignations, SourceContenuSeance).
--    La reprise de groupe existe deja (derniere_position_groupe) ; il manquait
--    la lecture PortAssignations.aVenir : assignations_a_venir rend au plus
--    TROIS travaux ouverts ('a_faire', 'en_cours') de la classe, filtres a la
--    source par eleve (amendement 2.1 de TC_CONTRACT_REQUEST_H : collectifs
--    et nominatifs de cet eleve), le plus urgent d'abord (echeance proche,
--    sans echeance en dernier). Le plafond est garanti ici, jamais par
--    l'appelant. INVOKER : les policies de learning_assignment bornent les
--    lignes (enseignant auteur, direction, foyer membre).
-- 2. PrerequisEnseignant (lib/features/bienvenue_enseignant/bienvenue_page.dart) :
--    prerequis_enseignant rend les quatre elements de ENS-01, calcules par le
--    serveur pour l'enseignant connecte : photo (photo_storage_key posee),
--    langues (au moins une), fuseau (fuseau connu de la base ET informations
--    confirmees par maj_profil_enseignant, qui pose le pays), disponibilites
--    (au moins une disponibilite hebdomadaire). DEFINER : weekly_availability
--    n'est lisible par aucun client ; la garde exige un enseignant actif et
--    la lecture ne porte que sur auth.uid().
BEGIN;

CREATE FUNCTION public.assignations_a_venir(
  p_group_id uuid, p_student_id uuid DEFAULT NULL, p_limite integer DEFAULT 3
)
RETURNS SETOF public.learning_assignment
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid()
       AND EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_group_id), false) THEN
    RAISE EXCEPTION 'classe introuvable ou acces refuse' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT a.*
    FROM public.learning_assignment a
    WHERE a.group_id = p_group_id
      AND a.status IN ('a_faire', 'en_cours')
      AND (p_student_id IS NULL OR a.student_id IS NULL OR a.student_id = p_student_id)
    ORDER BY a.due_at ASC NULLS LAST, a.starts_at, a.id
    LIMIT least(3, greatest(0, coalesce(p_limite, 3)));
END;
$function$;

CREATE FUNCTION public.prerequis_enseignant()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profil public.teacher_profiles;
BEGIN
  IF NOT coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'prerequis reserves a un enseignant actif' USING ERRCODE = '42501';
  END IF;
  SELECT tp.* INTO v_profil FROM public.teacher_profiles tp
   WHERE tp.profile_id = auth.uid() AND tp.deleted_at IS NULL;
  IF v_profil.profile_id IS NULL THEN
    RAISE EXCEPTION 'aucun profil enseignant' USING ERRCODE = 'P0002';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'photo', v_profil.photo_storage_key IS NOT NULL,
    'langues', coalesce(cardinality(v_profil.languages), 0) > 0,
    'fuseau', v_profil.country IS NOT NULL AND EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = v_profil.timezone_iana),
    'disponibilites', EXISTS (
       SELECT 1 FROM public.weekly_availability wa WHERE wa.profile_id = auth.uid()));
END;
$function$;

REVOKE ALL ON FUNCTION public.assignations_a_venir(uuid, uuid, integer) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.prerequis_enseignant() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.assignations_a_venir(uuid, uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.prerequis_enseignant() TO authenticated;
COMMENT ON FUNCTION public.assignations_a_venir(uuid, uuid, integer) IS
  'CONTRATS-MANQUANTS: PortAssignations.aVenir (PortTravailAVenir). INVOKER, plafond 3 serveur, garde positive classe lisible.';
COMMENT ON FUNCTION public.prerequis_enseignant() IS
  'F86: signature=public.prerequis_enseignant(); md5_functiondef=cf58651d62a508cdcbfadfca719572db; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PrerequisEnseignant (ENS-01). Garde: enseignant actif, lecture de soi seul.';

DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.prerequis_enseignant()'::regprocedure, 'cf58651d62a508cdcbfadfca719572db')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CONTRATS travail et prerequis : empreinte F86, DEFINER ou ACL invalide';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.assignations_a_venir(uuid,uuid,integer)'::regprocedure
      AND (p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
           OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'CONTRATS travail : assignations_a_venir doit rester INVOKER';
  END IF;
END;
$postflight$;

COMMIT;
