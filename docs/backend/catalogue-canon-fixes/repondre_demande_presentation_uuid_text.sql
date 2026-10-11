CREATE OR REPLACE FUNCTION public.repondre_demande_presentation(p_demande_id uuid, p_statut text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_demande public.demandes_presentation%ROWTYPE;
  v_foyer uuid;
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() = 'guardian',
    false
  ) THEN
    RAISE EXCEPTION 'reponse reservee au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(
    p_demande_id IS NOT NULL
    AND p_statut IN ('acceptee', 'refusee')
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.profiles guardian
      JOIN public.households h ON h.id = guardian.household_id
      WHERE guardian.id = auth.uid()
        AND guardian.role = 'guardian'
        AND guardian.deleted_at IS NULL
        AND h.status = 'active'
        AND h.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'réponse réservée au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_demande
  FROM public.demandes_presentation d
  WHERE d.id = p_demande_id
    AND d.foyer_id = public.app_household_id()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'demande de présentation inaccessible'
      USING ERRCODE = '42501';
  END IF;

  IF v_demande.statut = p_statut THEN
    RETURN v_demande.statut;
  END IF;
  IF v_demande.statut <> 'en_attente' THEN
    RAISE EXCEPTION 'demande déjà tranchée';
  END IF;

  UPDATE public.demandes_presentation
  SET statut = p_statut,
      repondu_le = pg_catalog.now(),
      repondu_par = auth.uid()
  WHERE id = v_demande.id
    AND foyer_id = public.app_household_id()
    AND statut = 'en_attente'
  RETURNING foyer_id INTO v_foyer;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'demande déjà tranchée';
  END IF;

  PERFORM public.log_sensitive_access(
    'demande_presentation_' || p_statut,
    'demandes_presentation',
    v_demande.id::text,
    pg_catalog.jsonb_build_object('foyer_id', v_foyer)
  );

  RETURN p_statut;
END;
$function$

