CREATE OR REPLACE FUNCTION public.accepter_demande_presentation(p_demande_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'guardian', false
  ) THEN
    RAISE EXCEPTION 'reponse reservee au tuteur du foyer'
      USING ERRCODE = '42501';
  END IF;
  RETURN public.repondre_demande_presentation(p_demande_id, 'acceptee');
END;
$function$

