-- MESURE-LECTURE (08/11/2026) : « comment on mesure » (vision, priorite n° 1).
-- Aujourd'hui seule la direction lit les resultats d'evaluation (evaluations_lecture).
-- Cette fonction rend les resultats REALISES d'UN eleve :
--   (a) a l'eleve lui-meme, et a son tuteur s'il est mineur de son foyer ;
--   (b) au titulaire de sa classe, et au remplacant pendant la seance qu'il assure.
-- Ni `notes` ni l'evaluateur ne sortent. Aucune table n'est modifiee, aucune politique
-- n'est touchee. Le code `resultat` est technique : les mots visibles (« Etape validee »,
-- « Quelques points sont a renforcer », « Une nouvelle verification est necessaire »)
-- sont ceux de mots-rewayah, poses plus tard cote ecran. Aucun affichage dans ce lot.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.lire_resultats_evaluations(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'MESURE-LECTURE : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.c29_enseignant_effectif_session(uuid)') IS NULL THEN
    RAISE EXCEPTION 'MESURE-LECTURE : enseignant effectif de seance absent';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema = 'public' AND table_name = 'evaluations'
                    AND column_name = 'resultat') THEN
    RAISE EXCEPTION 'MESURE-LECTURE : evaluations.resultat absente';
  END IF;
END
$preflight$;

CREATE FUNCTION public.lire_resultats_evaluations(p_student_id uuid DEFAULT NULL)
RETURNS TABLE (
  evaluation_id uuid,
  student_id uuid,
  type text,
  date_realisee date,
  resultat text,
  niveau text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT e.id, e.student_id, e.type, e.date_realisee, e.resultat, n.nom_humain
    FROM public.evaluations e
    JOIN public.programme_niveaux n ON n.id = e.niveau_id
   WHERE auth.uid() IS NOT NULL
     AND public.app_account_valid()
     AND e.statut = 'realisee'
     AND e.student_id = coalesce(p_student_id, auth.uid())
     AND (
       -- l'eleve, pour lui seul
       (public.app_role() IN ('student', 'guardian') AND e.student_id = auth.uid())
       -- le tuteur, pour un mineur de son foyer (jamais un adulte du foyer)
       OR (public.app_role() = 'guardian'
           AND public.est_du_foyer(e.student_id)
           AND EXISTS (SELECT 1 FROM public.student_profiles sp
                        WHERE sp.profile_id = e.student_id
                          AND sp.deleted_at IS NULL
                          AND sp.student_type = 'minor'))
       -- l'enseignant : titulaire de la classe actuelle de l'eleve, ou remplacant
       -- pendant la seance de cette classe qu'il assure
       OR (public.app_role() = 'teacher'
           AND EXISTS (
             SELECT 1
               FROM public.groupe_membres gm
               JOIN public.groupes g ON g.id = gm.groupe_id
              WHERE gm.student_id = e.student_id
                AND gm.left_at IS NULL
                AND (
                  g.teacher_id = auth.uid()
                  OR EXISTS (
                    SELECT 1 FROM public.sessions s
                     WHERE s.groupe_id = g.id
                       AND s.deleted_at IS NULL
                       AND s.status <> 'canceled'
                       AND pg_catalog.now() >= s.started_at
                       AND pg_catalog.now() < s.ended_at
                       AND private.c29_enseignant_effectif_session(s.id) = auth.uid())
                )))
     )
   ORDER BY e.date_realisee DESC, e.id;
$function$;
ALTER FUNCTION public.lire_resultats_evaluations(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lire_resultats_evaluations(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_resultats_evaluations(uuid) TO authenticated;

COMMENT ON FUNCTION public.lire_resultats_evaluations(uuid) IS
  'MESURE-LECTURE (08/11/2026) : resultats realises d''un eleve, pour lui, son tuteur '
  '(mineur du foyer), le titulaire de sa classe ou le remplacant de la seance en cours. '
  'Ni notes ni evaluateur.';

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.lire_resultats_evaluations(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.lire_resultats_evaluations(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'MESURE-LECTURE : droits d''execution incorrects';
  END IF;
END
$postflight$;
