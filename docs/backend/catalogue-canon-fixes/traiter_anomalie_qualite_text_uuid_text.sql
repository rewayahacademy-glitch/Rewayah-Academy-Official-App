CREATE OR REPLACE FUNCTION public.traiter_anomalie_qualite(p_type_anomalie text, p_ref_id uuid, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_table text;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'traitement d''une anomalie qualite reserve a l''administration';
  end if;

  v_table := case p_type_anomalie
    when 'rapport_manquant' then 'sessions'
    when 'blocage_sans_suivi' then 'progression_exceptions'
    when 'evaluation_en_retard' then 'evaluations'
    else null
  end;

  if v_table is null then
    raise exception 'type d''anomalie inconnu : %', p_type_anomalie;
  end if;

  insert into public.controles_qualite (type_anomalie, ref_table, ref_id, statut, traite_par, traite_at, note)
  values (p_type_anomalie, v_table, p_ref_id, 'traite', auth.uid(), now(), p_note)
  on conflict (type_anomalie, ref_id) do update
    set statut = 'traite', traite_par = excluded.traite_par, traite_at = excluded.traite_at, note = excluded.note
  returning id into v_id;

  perform public.log_sensitive_access(
    'anomalie_qualite_traitee', 'controles_qualite', v_id::text,
    jsonb_build_object('type_anomalie', p_type_anomalie, 'ref_id', p_ref_id, 'note', p_note)
  );

  return v_id;
end;
$function$

