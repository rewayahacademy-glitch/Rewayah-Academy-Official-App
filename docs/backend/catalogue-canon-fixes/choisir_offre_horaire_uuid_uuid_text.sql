CREATE OR REPLACE FUNCTION public.choisir_offre_horaire(p_membre_id uuid, p_offre_id uuid, p_fuseau_vue text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_compatible record;
  v_intention uuid;
  v_demande public.demandes_horaires_famille%rowtype;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  SELECT * INTO v_compatible
  FROM public.offres_compatibles(p_membre_id, p_fuseau_vue) o
  WHERE o.offre_id = p_offre_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'cette offre n''est pas compatible avec ce profil, ou n''est plus publiee';
  END IF;

  SELECT * INTO v_demande
  FROM public.demandes_horaires_famille
  WHERE eleve_id = p_membre_id
    AND etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')
  FOR UPDATE;
  IF FOUND THEN
    RAISE EXCEPTION 'retirez votre demande actuelle avant d''en choisir une autre';
  END IF;

  INSERT INTO public.intentions_horaire
    (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
  VALUES
    (p_membre_id, p_offre_id, p_fuseau_vue,
     v_compatible.heures_locales[1], v_compatible.jours_locaux, auth.uid())
  RETURNING id INTO v_intention;

  INSERT INTO public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, offre_id)
  VALUES
    (p_membre_id, v_compatible.type_public, v_compatible.langue_code, p_fuseau_vue,
     v_compatible.jours_locaux, v_compatible.heures_locales, 'offre', p_offre_id);

  UPDATE public.student_profiles SET diagnostic_statut = 'a_planifier'
  WHERE profile_id = p_membre_id AND diagnostic_statut = 'non_requis';
  PERFORM public.log_sensitive_access(
    'intention_horaire_enregistree', 'intentions_horaire', v_intention::text,
    jsonb_build_object('eleve_id', p_membre_id, 'offre_id', p_offre_id)
  );
  RETURN v_intention;
END;
$function$

