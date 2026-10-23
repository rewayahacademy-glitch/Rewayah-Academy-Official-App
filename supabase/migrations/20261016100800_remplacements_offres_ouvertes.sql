-- REMPL-1 : le tableau commun des remplacements (PortRemplacements.suivre).
--
-- Contrat : lib/core/enseignant/port_remplacements.dart (OffreCommune,
-- EtatOffreCommune) et sa demonstration (features/demo/remplacements_demo.dart).
-- L'acceptation existe deja (prendre_remplacement, atomique, 'dejaPrise'
-- apres la premiere) ; il manquait la lecture des offres.
--
-- * Une offre = une seance de Classe a venir (planned, non supprimee, Classe
--   active) dont le dernier evenement de remplacements_seance est
--   'absence_declaree' (ouverte) ou une prise ('remplacement_pris',
--   'remplacement_designe_admin').
-- * Visibilite par genre portee ici (decision du 02/10) : une offre n'est
--   rendue qu'a un enseignant compatible (remplacement_enseignant_compatible :
--   compte actif, KYC approuve, genre de la Classe). Le titulaire absent ne
--   voit pas sa propre seance dans le tableau commun.
-- * etat : 'ouverte' | 'prise_par_moi' | 'prise_par_un_collegue'. Le nom du
--   collegue, le motif d'absence, le titulaire et tout genre ne sont jamais
--   rendus.
-- * Chaque offre : {seance_id, groupe_id, classe, numero_dans_famille,
--   debut, fin, nb_eleves, etat}, par debut croissant.
-- * DEFINER : remplacements_seance n'a aucune policy client et les colonnes
--   de groupes lues ne sont pas accordees ; garde positive enseignant actif.
--   Le flux temps reel se fait par relecture (comme l'adaptateur des
--   demandes) : la table n'est pas publiee aux clients.
BEGIN;

CREATE FUNCTION public.offres_remplacement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'teacher', false) THEN
    RAISE EXCEPTION 'RemplacementNonAutorise' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'seance_id', o.session_id, 'groupe_id', o.groupe_id, 'classe', o.libelle,
             'numero_dans_famille', o.numero, 'debut', o.started_at, 'fin', o.ended_at,
             'nb_eleves', o.nb_eleves, 'etat', o.etat)
           ORDER BY o.started_at, o.session_id)
    FROM (
      SELECT s.id AS session_id, g.id AS groupe_id, g.libelle, n.numero, s.started_at, s.ended_at,
             (SELECT count(*)::integer FROM public.session_participants sp
               WHERE sp.session_id = s.id AND sp.role = 'student' AND sp.deleted_at IS NULL) AS nb_eleves,
             CASE WHEN dernier.evenement = 'absence_declaree' THEN 'ouverte'
                  WHEN dernier.enseignant_remplacant_id = v_moi THEN 'prise_par_moi'
                  ELSE 'prise_par_un_collegue' END AS etat
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
      LEFT JOIN app_private.classes_numerotees() n ON n.groupe_id = g.id
      CROSS JOIN LATERAL (
        SELECT r.evenement, r.enseignant_titulaire_id, r.enseignant_remplacant_id
        FROM public.remplacements_seance r
        WHERE r.session_id = s.id
        ORDER BY r.cree_le DESC, r.id DESC LIMIT 1
      ) dernier
      WHERE s.deleted_at IS NULL AND s.status = 'planned' AND s.started_at > pg_catalog.now()
        AND dernier.enseignant_titulaire_id <> v_moi
        AND (dernier.enseignant_remplacant_id = v_moi
             OR public.remplacement_enseignant_compatible(s.id, v_moi))
    ) o), '[]'::jsonb);
END;
$function$;

REVOKE ALL ON FUNCTION public.offres_remplacement() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.offres_remplacement() TO authenticated;

-- @@F86_DEBUT_REMPLACEMENTS@@
COMMENT ON FUNCTION public.offres_remplacement() IS
  'F86: signature=public.offres_remplacement(); md5_functiondef=e2086c171f42d15adbea3cfae94e5e0c; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. PortRemplacements.suivre. Garde: enseignant actif ; filtre de genre serveur.';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.offres_remplacement()'::regprocedure
      AND (pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> 'e2086c171f42d15adbea3cfae94e5e0c'
           OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
           OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || 'e2086c171f42d15adbea3cfae94e5e0c' || '%'
           OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
           OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE'))
  ) THEN
    RAISE EXCEPTION 'REMPL offres : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_REMPLACEMENTS@@

COMMIT;
