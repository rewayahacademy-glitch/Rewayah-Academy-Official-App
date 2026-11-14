-- PROGRAMME-PUBLIE (14/11/2026, demande du directeur relayee par le pilote) : l'eleve et sa famille
-- VOIENT le programme de l'academie (cycles, etapes, objectifs, matieres), meme sans etape propre.
--
-- Constat : `programme_versions`, `programme_niveaux` et `programme_cycles` ne se lisent que par la
-- direction (RLS), et `ma_progression` ne rend que le cycle de l'etape PROPRE a l'eleve ; sans etape,
-- l'onglet Programme de l'espace Apprendre n'avait rien a montrer.
--
-- Migration additive : une lecture neuve, aucune table, aucune fonction existante modifiee. Rien ne
-- s'ecrit ici.
--
-- Principes :
--   1. Seule la version PUBLIEE sort (jamais un brouillon, jamais une version archivee).
--   2. Aucune donnee personnelle, aucune place de l'eleve : la lecture dit le programme, pas ou en
--      est une personne (cela reste `ma_progression`).
--   3. Objectifs et noms pour tout appelant autorise. Matieres, durees prevues et dates limites
--      seulement quand un eleve est nomme (`p_eleve_id`) : elles dependent de sa tranche d'age, et
--      les durees suivent la regle unique de `ma_progression` (`private.dates_retenues` : l'enfant
--      de 6 a 9 ans qui lit pour lui-meme n'en recoit aucune ; son tuteur les recoit). Sans eleve
--      nomme, aucune matiere et aucune duree.
--   4. Garde positive : compte valide et role eleve, tuteur, enseignant ou direction. Quand un eleve
--      est nomme, la garde est celle de `suivi_pedagogique_eleve` (appelee, jamais copiee) : 42501
--      pour un autre foyer, un autre eleve, une classe etrangere.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.programme_publie(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'PROGRAMME-PUBLIE : deja installee';
  END IF;
  IF pg_catalog.to_regclass('public.programme_cycles') IS NULL
     OR pg_catalog.to_regprocedure('public.suivi_pedagogique_eleve(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.dates_retenues(uuid, uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cohorte_effective(uuid, uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.eleve_voit_dates(text)') IS NULL THEN
    RAISE EXCEPTION 'PROGRAMME-PUBLIE : SOCLE-PROGRAMME ou SUIVI-ELEVE absent';
  END IF;
END
$preflight$;

CREATE FUNCTION public.programme_publie(p_eleve_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
#variable_conflict use_column
DECLARE
  v_version public.programme_versions%ROWTYPE;
  v_groupe uuid;
  v_coh text := NULL;
  v_masque boolean := true;
  v_voit boolean := NULL;
  v_cycles jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL
                  AND public.app_account_valid()
                  AND public.app_role() IN ('student', 'guardian', 'teacher', 'admin'), false) THEN
    RAISE EXCEPTION 'programme refuse' USING errcode = '42501';
  END IF;

  IF p_eleve_id IS NOT NULL THEN
    -- La garde de la lecture du suivi, sans copie : leve 42501 hors famille, classe et direction.
    PERFORM public.suivi_pedagogique_eleve(p_eleve_id);
    SELECT m.groupe_id INTO v_groupe
      FROM public.groupe_membres m
      JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
     WHERE m.student_id = p_eleve_id AND m.left_at IS NULL
     ORDER BY m.joined_at DESC, m.groupe_id
     LIMIT 1;
    v_coh := private.cohorte_effective(p_eleve_id, v_groupe);
    v_voit := private.eleve_voit_dates(v_coh);
    v_masque := coalesce(private.dates_retenues(p_eleve_id, v_groupe), true);
  END IF;

  SELECT * INTO v_version FROM public.programme_versions WHERE statut = 'publiee';
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('version', NULL, 'eleve_voit_dates', v_voit,
                                         'cycles', '[]'::jsonb);
  END IF;

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'code', c.code,
           'nom', c.nom_humain,
           'ordre', c.ordre,
           'duree_prevue_semaines',
             CASE WHEN v_masque OR v_coh IS NULL THEN NULL ELSE (c.durees -> v_coh ->> 'prevue')::int END,
           'date_limite_semaines',
             CASE WHEN v_masque OR v_coh IS NULL THEN NULL ELSE (c.durees -> v_coh ->> 'limite')::int END,
           'etapes', coalesce((
             SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                      'code', e.code_technique,
                      'ordre', e.ordre,
                      'nom', e.nom_humain,
                      'objectifs', pg_catalog.to_jsonb(e.objectifs),
                      'matiere_principale',
                        CASE WHEN v_coh IS NULL THEN NULL ELSE e.matieres -> v_coh ->> 'principale' END,
                      'matiere_secondaire',
                        CASE WHEN v_coh IS NULL THEN NULL ELSE e.matieres -> v_coh ->> 'secondaire' END,
                      'duree_prevue_semaines',
                        CASE WHEN v_masque OR v_coh IS NULL THEN NULL
                             ELSE (e.durees -> v_coh ->> 'prevue')::int END,
                      'date_limite_semaines',
                        CASE WHEN v_masque OR v_coh IS NULL THEN NULL
                             ELSE (e.durees -> v_coh ->> 'limite')::int END)
                    ORDER BY e.ordre)
               FROM public.programme_niveaux e
              WHERE e.version_id = c.version_id AND e.cycle_code = c.code), '[]'::jsonb))
           ORDER BY c.ordre), '[]'::jsonb)
    INTO v_cycles
    FROM public.programme_cycles c
   WHERE c.version_id = v_version.id;

  RETURN pg_catalog.jsonb_build_object(
    'version', pg_catalog.jsonb_build_object('numero', v_version.numero_version),
    'eleve_voit_dates', v_voit,
    'cycles', v_cycles);
END;
$function$;

COMMENT ON FUNCTION public.programme_publie(uuid) IS
  'PROGRAMME-PUBLIE (14/11/2026) : le programme de la version publiee (cycles, etapes, objectifs), '
  'lisible par l''eleve, le tuteur, l''enseignant et la direction, meme sans etape propre. Matieres, '
  'durees et dates limites seulement avec un eleve nomme (sa tranche) et selon la regle de '
  'ma_progression (aucune duree pour l''enfant de 6 a 9 ans qui lit pour lui-meme). Aucune donnee '
  'personnelle, aucune place.';

REVOKE ALL ON FUNCTION public.programme_publie(uuid) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.programme_publie(uuid) TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.programme_publie(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.programme_publie(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.programme_publie(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PROGRAMME-PUBLIE : droits inattendus';
  END IF;
END
$postflight$;
