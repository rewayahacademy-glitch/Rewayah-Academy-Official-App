CREATE OR REPLACE FUNCTION public.affecter_enseignant_classe_c11bis(p_groupe_id uuid, p_teacher_profile_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_groupe public.groupes%ROWTYPE;
BEGIN
  IF NOT coalesce(
       public.app_role() = 'admin' AND public.app_account_valid(),
       false
     )
     OR p_groupe_id IS NULL
     OR p_teacher_profile_id IS NULL THEN
    RAISE EXCEPTION 'affectation reservee a l''administration'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_groupe FROM public.groupes
   WHERE id = p_groupe_id
   FOR UPDATE;
  IF NOT FOUND OR v_groupe.ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;
  IF v_groupe.teacher_id IS NOT NULL THEN
    RETURN 'deja_affecte';
  END IF;
  IF v_groupe.etat <> 'en_attente_enseignant' THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;

  -- teacher_profiles ne porte pas le titre public C-05 et aucune règle
  -- serveur de collisions C-07 n'est encore complète. Refus explicite plutôt
  -- qu'une affectation qui ne peut pas prouver sa compatibilité.
  RAISE EXCEPTION 'compatibilite enseignant non verifiable : source titre public absente';
END;
$function$

