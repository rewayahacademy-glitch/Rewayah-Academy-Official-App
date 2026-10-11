CREATE OR REPLACE FUNCTION public.mes_demandes_horaires(p_membre_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id,
    'etat', d.etat,
    'prochaine_etape', CASE d.etat
      WHEN 'envoyee' THEN 'constitution_classe'
      WHEN 'classe_validee' THEN 'affectation_enseignant'
      WHEN 'enseignant_affecte' THEN 'debut_cours'
      WHEN 'refusee' THEN 'choisir_autre_horaire'
      ELSE 'aucune'
    END,
    'motif', d.motif,
    'updated_at', d.updated_at
  ) ORDER BY d.created_at DESC), '[]'::jsonb)
  INTO v_result
  FROM public.demandes_horaires_famille d
  WHERE d.eleve_id = p_membre_id;
  RETURN v_result;
END;
$function$

