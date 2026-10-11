CREATE OR REPLACE FUNCTION public.etat_creneau_personnalise(p_membre_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT CASE
    WHEN coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN (
      SELECT jsonb_build_object('etat', d.etat)
      FROM public.demandes_horaires_famille d
      WHERE d.eleve_id = p_membre_id
        AND d.source = 'personnalisee'
        AND d.etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')
      ORDER BY d.created_at DESC LIMIT 1
    )
    ELSE NULL
  END;
$function$

