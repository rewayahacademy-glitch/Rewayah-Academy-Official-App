-- CLASSE-FORM-1 : les enseignants proposables pour une classe A CREER
-- (PortEnseignantsClasse.pourClasse(public)).
--
-- enseignants_pour_classe(uuid) exige une classe existante en attente
-- d'enseignant ; le formulaire de creation n'a pas encore de classe. Les
-- specifications le justifient (docs/current/UX_REVIEW_CLASSE-FORM-1.md,
-- D2 a D6) : le formulaire classe la liste lui-meme (classerEnseignants),
-- garde visibles les enseignants incompatibles ou occupes avec leur raison,
-- et a besoin pour chacun du genre public (titre sayyid / sayyida, D3),
-- des creneaux libres, des creneaux pris et de la charge.
--
-- * Rend tous les enseignants valides (compte actif, KYC approuve) : aucun
--   filtre de genre ici, la compatibilite se dit a l'ecran (D4).
-- * p_type_public ('enfant' | 'adulte') est valide et fait partie du
--   contrat ; aucun attribut d'enseignant ne restreint aujourd'hui le
--   public, il ne filtre donc rien.
-- * Memes colonnes que enseignants_pour_classe ; titre_public vaut 'sayyid'
--   ou 'sayyida' (orthographe de teacher_profiles.titre). Creneaux libres :
--   disponibilites declarees moins celles qui chevauchent une classe active
--   ou une affectation individuelle (meme regle que enseignants_pour_classe).
-- * DEFINER : weekly_availability et les colonnes de groupes ne sont
--   accordees a aucun client ; garde positive direction active.
BEGIN;

CREATE FUNCTION public.enseignants_pour_public(p_type_public text)
RETURNS TABLE (
  teacher_id uuid, first_name text, last_name text, immutable_id text, country text,
  titre_public text, timezone_iana text, classes_actives integer,
  creneaux_pris jsonb, creneaux_libres jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_duree integer := public.app_config_int('session_duration_minutes', 60);
  v_masque boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'proposition d''enseignants reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type_public IS NULL OR p_type_public NOT IN ('enfant', 'adulte') THEN
    RAISE EXCEPTION 'public invalide' USING ERRCODE = '22023';
  END IF;
  v_masque := coalesce(public.agent_identite_masquee(), false);

  RETURN QUERY
  SELECT p.id,
         CASE WHEN v_masque THEN NULL ELSE p.first_name END,
         CASE WHEN v_masque THEN NULL ELSE p.last_name END,
         p.immutable_id, tp.country,
         CASE p.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayyid' END,
         tp.timezone_iana,
         (SELECT count(*)::integer FROM public.groupes g
           WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', b.weekday, 'hour_local', b.hour_local, 'timezone_iana', b.timezone_iana)
                  ORDER BY b.weekday, b.hour_local, b.timezone_iana)
           FROM (
             SELECT DISTINCT s.weekday, s.hour_local, g.timezone_iana
             FROM public.groupes g
             CROSS JOIN LATERAL (
               SELECT g.weekday, g.hour_local
               UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
             ) s
             WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
           ) b), '[]'::jsonb),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', wa.weekday, 'hour_local', wa.hour_local, 'timezone_iana', wa.timezone_iana)
                  ORDER BY wa.weekday, wa.hour_local)
           FROM public.weekly_availability wa
           WHERE wa.profile_id = p.id
             AND NOT EXISTS (
               SELECT 1 FROM public.groupes g
               CROSS JOIN LATERAL (
                 SELECT g.weekday, g.hour_local
                 UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
               ) s
               WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
                 AND app_private.creneaux_recurrents_se_chevauchent(
                       wa.weekday, wa.hour_local, wa.timezone_iana,
                       s.weekday, s.hour_local, g.timezone_iana, v_duree))
             AND NOT EXISTS (
               SELECT 1 FROM public.teacher_student_assignments tsa
               JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
               WHERE tsa.teacher_id = p.id AND tsa.ended_at IS NULL
                 AND app_private.creneaux_recurrents_se_chevauchent(
                       wa.weekday, wa.hour_local, wa.timezone_iana,
                       busy.weekday, busy.hour_local, busy.timezone_iana, v_duree))), '[]'::jsonb)
  FROM public.profiles p
  JOIN public.teacher_profiles tp ON tp.profile_id = p.id
  WHERE p.role = 'teacher' AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
  ORDER BY p.last_name, p.first_name, p.id;
END;
$function$;

REVOKE ALL ON FUNCTION public.enseignants_pour_public(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.enseignants_pour_public(text) TO authenticated;

-- @@F86_DEBUT_ENSEIGNANTS_PUBLIC@@
COMMENT ON FUNCTION public.enseignants_pour_public(text) IS
  'F86: signature=public.enseignants_pour_public(text); md5_functiondef=0e9bf8754f3f27aa6de1e0a37b62314f; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortEnseignantsClasse.pourClasse. Garde: direction active.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.enseignants_pour_public(text)'::regprocedure
      AND (pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> '0e9bf8754f3f27aa6de1e0a37b62314f'
           OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
           OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || '0e9bf8754f3f27aa6de1e0a37b62314f' || '%'
           OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'CLASSE-FORM-1 enseignants_pour_public : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_ENSEIGNANTS_PUBLIC@@

COMMIT;
