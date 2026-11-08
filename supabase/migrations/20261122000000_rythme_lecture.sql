-- RYTHME-LECTURE (08/11/2026) : « a quelle vitesse il avance » (vision, point 4), pour
-- l'enseignant et la direction. Aujourd'hui le rythme d'un eleve (semaines ecoulees et etat
-- de vitesse) n'est rendu qu'a l'eleve et a sa famille (`suivi_pedagogique_eleve`) ;
-- l'enseignant et la direction ne lisent, par classe, que l'etape, la duree prevue et la
-- date limite (`etapes_eleves_classe`), sans les semaines ecoulees ni la vitesse.
--
-- `rythme_classe(p_groupe_id)` rend, pour chaque eleve present de la Classe, ses semaines
-- ecoulees sur l'etape et son etat de vitesse. Aucune saisie, aucune table, aucune politique
-- touchee : tout vient de `private.etape_eleve` (source unique) et la regle de vitesse est
-- celle, mot pour mot, de `suivi_pedagogique_eleve` (tranchee le 07/11) :
--   ecoule <= duree prevue               : dans_les_temps ;
--   duree prevue < ecoule <= date limite : au_dela_du_prevu ;
--   ecoule > date limite                 : date_limite_depassee ;
--   sans « depuis » ou sans duree         : inconnu.
-- Garde : `private.cahier_c1_peut_lire_classe` (direction, titulaire, enseignant effectif
-- d'une seance de la Classe pas encore passee de plus d'un jour) ; 42501 sinon.
-- Dette notee : la formule de vitesse existe maintenant a deux endroits ; la mettre dans
-- une fonction privee unique est un lot a part (suivi_pedagogique_eleve est installee).

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.rythme_classe(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'RYTHME-LECTURE : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('private.etape_eleve(uuid, uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cahier_c1_peut_lire_classe(uuid)') IS NULL THEN
    RAISE EXCEPTION 'RYTHME-LECTURE : SUIVI-ELEVE ou CAHIER-C1 absent';
  END IF;
END
$preflight$;

CREATE FUNCTION public.rythme_classe(p_groupe_id uuid)
RETURNS TABLE (
  student_id uuid,
  etape_nom text,
  etape_ordre int,
  duree_prevue_semaines int,
  date_limite date,
  depuis timestamptz,
  semaines_ecoulees int,
  vitesse text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
BEGIN
  IF NOT private.cahier_c1_peut_lire_classe(p_groupe_id) THEN
    RAISE EXCEPTION 'rythme de la classe refuse' USING errcode = '42501';
  END IF;
  RETURN QUERY
    SELECT m.student_id,
           e.etape_nom,
           e.etape_ordre,
           e.duree_prevue_semaines,
           e.date_limite,
           e.depuis,
           CASE WHEN e.depuis IS NOT NULL
                THEN pg_catalog.floor(
                       EXTRACT(epoch FROM pg_catalog.now() - e.depuis) / 604800)::int
           END,
           CASE
             WHEN e.depuis IS NULL OR e.duree_prevue_semaines IS NULL THEN 'inconnu'
             WHEN pg_catalog.now() <= e.depuis + pg_catalog.make_interval(weeks => e.duree_prevue_semaines)
               THEN 'dans_les_temps'
             WHEN e.date_limite IS NULL OR pg_catalog.now()::date <= e.date_limite
               THEN 'au_dela_du_prevu'
             ELSE 'date_limite_depassee'
           END
      FROM public.groupe_membres m
     CROSS JOIN LATERAL private.etape_eleve(m.student_id, p_groupe_id) e
     WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;
END;
$function$;
ALTER FUNCTION public.rythme_classe(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rythme_classe(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.rythme_classe(uuid) TO authenticated;

COMMENT ON FUNCTION public.rythme_classe(uuid) IS
  'RYTHME-LECTURE (08/11/2026) : semaines ecoulees et vitesse (dans_les_temps, au_dela_du_prevu, '
  'date_limite_depassee, inconnu) de chaque eleve present de la Classe. Direction, titulaire, '
  'enseignant effectif (garde CAHIER-C1). 42501 sinon.';

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.rythme_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.rythme_classe(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'RYTHME-LECTURE : droits d''execution incorrects';
  END IF;
END
$postflight$;
