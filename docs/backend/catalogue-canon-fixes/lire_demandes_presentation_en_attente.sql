CREATE OR REPLACE FUNCTION public.lire_demandes_presentation_en_attente()
 RETURNS TABLE(id uuid, eleve_id uuid, eleve_prenom text, cree_le timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() = 'guardian',
    false
  ) THEN
    RAISE EXCEPTION 'lecture reservee au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.households h ON h.id = p.household_id
      WHERE p.id = auth.uid()
        AND p.role = 'guardian'
        AND p.deleted_at IS NULL
        AND h.status = 'active'
        AND h.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'lecture réservée au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT d.id, d.eleve_id, student.first_name, d.cree_le
  FROM public.demandes_presentation d
  JOIN public.profiles guardian ON guardian.id = auth.uid()
  JOIN public.profiles student ON student.id = d.eleve_id
  WHERE d.foyer_id = guardian.household_id
    AND d.statut = 'en_attente'
    AND student.deleted_at IS NULL
  ORDER BY d.cree_le;
END;
$function$

