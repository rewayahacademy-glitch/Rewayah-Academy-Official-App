-- FORMULE-VITESSE-UNIQUE (08/11/2026) : la regle de vitesse d'un eleve n'existe plus qu'en
-- UN endroit, `private.vitesse_eleve`, appelee par `suivi_pedagogique_eleve` (famille et
-- eleve) et par `rythme_classe` (enseignant et direction). Jusqu'ici la meme formule etait
-- ecrite deux fois (dette notee dans RYTHME-LECTURE).
--
-- Aucun changement de comportement : le CASE est deplace tel quel, `now()` est passe en
-- parametre (p_maintenant) pour pouvoir eprouver chaque frontiere. Les deux fonctions
-- publiques sont reecrites a l'identique (signature, resultat, droits, commentaire)
-- sauf cet appel. Aucune table, aucune politique, aucun droit nouveau ; la fonction
-- privee n'est ouverte a personne.
--
-- Regle (07/11, inchangee) :
--   ecoule <= duree prevue               : dans_les_temps ;
--   duree prevue < ecoule <= date limite : au_dela_du_prevu ;
--   ecoule > date limite                 : date_limite_depassee ;
--   sans « depuis » ou sans duree         : inconnu.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.vitesse_eleve(timestamptz, integer, date, timestamptz)') IS NOT NULL THEN
    RAISE EXCEPTION 'FORMULE-VITESSE-UNIQUE : deja installee';
  END IF;
  IF pg_catalog.to_regprocedure('public.rythme_classe(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.suivi_pedagogique_eleve(uuid)') IS NULL THEN
    RAISE EXCEPTION 'FORMULE-VITESSE-UNIQUE : RYTHME-LECTURE ou SUIVI-ELEVE absent';
  END IF;
  -- Les deux fonctions portent encore la formule en ligne : on remplace ce qu'on a relu.
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.suivi_pedagogique_eleve(uuid)'::pg_catalog.regprocedure),
                       'date_limite_depassee') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.rythme_classe(uuid)'::pg_catalog.regprocedure),
                          'date_limite_depassee') = 0 THEN
    RAISE EXCEPTION 'FORMULE-VITESSE-UNIQUE : la formule n''est plus en ligne, migration a revoir';
  END IF;
END
$preflight$;

CREATE FUNCTION private.vitesse_eleve(
  p_depuis timestamptz,
  p_duree_prevue_semaines int,
  p_date_limite date,
  p_maintenant timestamptz
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE
           WHEN p_depuis IS NULL OR p_duree_prevue_semaines IS NULL THEN 'inconnu'
           WHEN p_maintenant <= p_depuis + pg_catalog.make_interval(weeks => p_duree_prevue_semaines)
             THEN 'dans_les_temps'
           WHEN p_date_limite IS NULL OR p_maintenant::date <= p_date_limite
             THEN 'au_dela_du_prevu'
           ELSE 'date_limite_depassee'
         END;
$function$;
ALTER FUNCTION private.vitesse_eleve(timestamptz, integer, date, timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.vitesse_eleve(timestamptz, integer, date, timestamptz)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.vitesse_eleve(timestamptz, integer, date, timestamptz) IS
  'FORMULE-VITESSE-UNIQUE (08/11/2026) : seule regle de vitesse (dans_les_temps, au_dela_du_prevu, '
  'date_limite_depassee, inconnu). Appelee par suivi_pedagogique_eleve et rythme_classe. Aucun droit direct.';

CREATE OR REPLACE FUNCTION public.suivi_pedagogique_eleve(p_eleve_id uuid)
RETURNS TABLE (
  etape_nom text,
  etape_ordre int,
  cycle text,
  objectifs text[],
  duree_prevue_semaines int,
  date_limite date,
  depuis timestamptz,
  semaines_ecoulees int,
  rythme text,
  page_reprise int,
  page_reprise_le timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_user uuid := auth.uid();
  v_groupe uuid;
BEGIN
  IF NOT coalesce(
    v_user IS NOT NULL AND p_eleve_id IS NOT NULL AND public.app_account_valid()
    AND (
      -- L'eleve lui-meme.
      (public.app_role() = 'student' AND p_eleve_id = v_user)
      -- Le titulaire de son propre profil eleve (0052).
      OR (public.app_role() = 'guardian' AND p_eleve_id = v_user
          AND EXISTS (SELECT 1 FROM public.student_profiles sp
                       WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user
                         AND sp.deleted_at IS NULL))
      -- Le tuteur du foyer de l'eleve : son enfant seulement.
      OR (public.app_role() = 'guardian'
          AND EXISTS (SELECT 1 FROM public.profiles p
                       WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                         AND p.household_id IS NOT NULL
                         AND p.household_id = public.app_household_id()))
    ), false) THEN
    RAISE EXCEPTION 'suivi pedagogique refuse' USING errcode = '42501';
  END IF;

  SELECT m.groupe_id INTO v_groupe
    FROM public.groupe_membres m
   WHERE m.student_id = p_eleve_id AND m.left_at IS NULL;
  IF v_groupe IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
    WITH e AS (
      SELECT * FROM private.etape_eleve(p_eleve_id, v_groupe)
    ),
    calcul AS (
      SELECT e.*,
             CASE WHEN e.depuis IS NOT NULL
                  THEN pg_catalog.floor(
                         EXTRACT(epoch FROM pg_catalog.now() - e.depuis) / 604800)::int
             END AS semaines
        FROM e
    )
    SELECT c.etape_nom,
           c.etape_ordre,
           c.cycle,
           c.objectifs,
           c.duree_prevue_semaines,
           c.date_limite,
           c.depuis,
           c.semaines,
           private.vitesse_eleve(c.depuis, c.duree_prevue_semaines, c.date_limite, pg_catalog.now()),
           r.page::int,
           r.presentee_le
      FROM calcul c
      LEFT JOIN public.classe_position_reprise r ON r.groupe_id = v_groupe;
END;
$function$;

CREATE OR REPLACE FUNCTION public.rythme_classe(p_groupe_id uuid)
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
           private.vitesse_eleve(e.depuis, e.duree_prevue_semaines, e.date_limite, pg_catalog.now())
      FROM public.groupe_membres m
     CROSS JOIN LATERAL private.etape_eleve(m.student_id, p_groupe_id) e
     WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;
END;
$function$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.suivi_pedagogique_eleve(uuid)'::pg_catalog.regprocedure),
                       'private.vitesse_eleve') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.rythme_classe(uuid)'::pg_catalog.regprocedure),
                          'private.vitesse_eleve') = 0 THEN
    RAISE EXCEPTION 'FORMULE-VITESSE-UNIQUE : une des deux fonctions n''appelle pas la source unique';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.vitesse_eleve(timestamptz, integer, date, timestamptz)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.vitesse_eleve(timestamptz, integer, date, timestamptz)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.suivi_pedagogique_eleve(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.rythme_classe(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.suivi_pedagogique_eleve(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.rythme_classe(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FORMULE-VITESSE-UNIQUE : droits inattendus';
  END IF;
END
$postflight$;
