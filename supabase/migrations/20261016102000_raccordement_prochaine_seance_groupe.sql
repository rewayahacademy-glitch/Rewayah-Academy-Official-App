-- RACCORDEMENT 16/10 (A, B) : la prochaine seance d'une Classe.
--
-- Constat sur STAGING : l'Accueil de l'eleve et les cartes de Classe du
-- foyer n'affichent aucune prochaine seance reelle. `horloge_seance()`
-- (0033) exige un identifiant de seance, et aucune lecture ne rend celui de
-- la prochaine occurrence d'une Classe : `mes_groupes_famille_v` ne porte
-- aucune occurrence. Le client n'avait donc rien a demander.
--
-- * `prochaine_seance_groupe(p_groupe_id)` rend l'identifiant de la
--   prochaine seance non terminee et non annulee de la Classe, ou NULL.
-- * SECURITY DEFINER, indispensable : la porte lit `groupes.teacher_id` et
--   `groupe_membres`, que le role client ne lit pas partout (droits par
--   colonne sur `groupes`, aucun droit de table dans la base de reference de
--   la CI). search_path vide, objets qualifies ; la porte reprend le
--   predicat de `horloge_seance()` (0033), qui rend ensuite l'horloge de la
--   seance : aucune ligne de plus n'est ouverte que ce que l'horloge ouvre.
-- * Porte positive : compte valide ET (direction, enseignant de la Classe,
--   eleve membre actif, ou tuteur dont un enfant est membre actif, foyer lu
--   dans le JWT par `est_du_foyer`). Un eleve ne lit jamais la Classe d'un
--   frere ou d'une soeur : le foyer n'ouvre que le role tuteur.
-- * Le reste (fenetre, fuseaux, phases) vient de `horloge_seance()`, sans
--   changement.

BEGIN;

CREATE FUNCTION public.prochaine_seance_groupe(p_groupe_id uuid)
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_autorise boolean;
  v_seance uuid;
BEGIN
  v_autorise := coalesce(
    p_groupe_id IS NOT NULL
    AND public.app_account_valid()
    AND (
      public.app_role() = 'admin'
      OR (public.app_role() = 'teacher' AND EXISTS (
            SELECT 1 FROM public.groupes g
             WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()))
      OR EXISTS (
            SELECT 1 FROM public.groupe_membres m
             WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
               AND (m.student_id = auth.uid()
                    OR (public.app_role() = 'guardian' AND public.est_du_foyer(m.student_id))))
    ), false);
  IF NOT v_autorise THEN
    RAISE EXCEPTION 'prochaine seance de Classe non autorisee' USING ERRCODE = '42501';
  END IF;

  SELECT s.id INTO v_seance
    FROM public.sessions s
   WHERE s.groupe_id = p_groupe_id
     AND s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND s.ended_at > pg_catalog.now()
   ORDER BY s.started_at, s.id
   LIMIT 1;
  RETURN v_seance;
END;
$function$;

ALTER FUNCTION public.prochaine_seance_groupe(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.prochaine_seance_groupe(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.prochaine_seance_groupe(uuid) TO authenticated;

-- @@F86_DEBUT_PROCHAINE_SEANCE@@
COMMENT ON FUNCTION public.prochaine_seance_groupe(uuid) IS
  'F86: signature=public.prochaine_seance_groupe(uuid); md5_functiondef=c6dcbdb39cc93ee7f6021358b5a88598; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: compte valide ET (direction, enseignant de la Classe, eleve membre actif, tuteur du foyer d''un membre actif). DEFINER: groupes.teacher_id et groupe_membres non accordes partout au client. L''horloge se lit ensuite par horloge_seance().';

DO $postflight$
BEGIN
  IF NOT (SELECT p.prosecdef FROM pg_catalog.pg_proc p
           WHERE p.oid = 'public.prochaine_seance_groupe(uuid)'::regprocedure)
     OR pg_catalog.md5(pg_catalog.pg_get_functiondef('public.prochaine_seance_groupe(uuid)'::regprocedure))
        <> 'c6dcbdb39cc93ee7f6021358b5a88598'
     OR coalesce(pg_catalog.obj_description('public.prochaine_seance_groupe(uuid)'::regprocedure, 'pg_proc'), '')
        NOT LIKE '%c6dcbdb39cc93ee7f6021358b5a88598%'
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.prochaine_seance_groupe(uuid)'::regprocedure
         AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.prochaine_seance_groupe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.prochaine_seance_groupe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.prochaine_seance_groupe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.prochaine_seance_groupe(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'RACCORDEMENT-1016 A : empreinte F86, DEFINER, search_path ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_PROCHAINE_SEANCE@@

COMMIT;
