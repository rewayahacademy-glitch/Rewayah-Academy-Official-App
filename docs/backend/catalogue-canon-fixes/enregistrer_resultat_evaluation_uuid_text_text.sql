CREATE OR REPLACE FUNCTION public.enregistrer_resultat_evaluation(p_evaluation_id uuid, p_resultat text, p_notes text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_statut text;
  v_type text;
  v_student_id uuid;
  v_niveau_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'enregistrement d''un resultat reserve a l''administration';
  end if;

  select statut, type, student_id, niveau_id
    into v_statut, v_type, v_student_id, v_niveau_id
  from public.evaluations where id = p_evaluation_id;

  if v_statut is null then
    raise exception 'evaluation introuvable';
  end if;

  if v_statut <> 'planifiee' then
    raise exception 'cette evaluation n''est plus planifiee';
  end if;

  update public.evaluations
  set statut = 'realisee', date_realisee = current_date, resultat = p_resultat,
      evaluateur_id = auth.uid(), notes = p_notes, updated_at = now()
  where id = p_evaluation_id;

  if p_resultat = 'reussi' and v_type in ('reevaluation', 'certification') then
    insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
    values (
      v_student_id, v_niveau_id, 'reevaluation', auth.uid(),
      case v_type
        when 'certification' then 'certification reussie'
        else 'reevaluation reussie'
      end
    );
  end if;

  perform public.log_sensitive_access(
    'resultat_evaluation_enregistre', 'evaluations', p_evaluation_id::text,
    jsonb_build_object('resultat', p_resultat, 'type', v_type)
  );
end;
$function$

