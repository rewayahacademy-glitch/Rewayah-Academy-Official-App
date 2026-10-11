CREATE OR REPLACE FUNCTION public.refuser_demande_horaire(p_demande_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_demande uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'refus de demande reserve a l''administration';
  end if;
  if p_demande_id is null or p_motif is distinct from 'refus_direction' then
    raise exception 'motif de refus invalide';
  end if;

  select d.id into v_demande
    from public.demandes_horaires_famille d
   where d.id = p_demande_id and d.etat = 'envoyee'
   for update;
  if not found then
    raise exception 'demande absente ou deja traitee';
  end if;

  update public.demandes_horaires_famille
     set etat = 'refusee',
         motif = p_motif,
         updated_at = pg_catalog.now()
   where id = v_demande;

  perform public.log_sensitive_access(
    'demande_horaire_refusee',
    'demandes_horaires_famille',
    v_demande::text,
    pg_catalog.jsonb_build_object('motif', p_motif)
  );
end;
$function$

