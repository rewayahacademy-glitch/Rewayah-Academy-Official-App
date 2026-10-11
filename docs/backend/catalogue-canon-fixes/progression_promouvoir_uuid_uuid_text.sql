CREATE OR REPLACE FUNCTION public.progression_promouvoir(p_student_id uuid, p_niveau_id uuid, p_motif text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'promotion de progression reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour promouvoir un eleve';
  end if;

  if not exists (
    select 1 from public.progression_historique where student_id = p_student_id
  ) then
    raise exception 'cet eleve n''a encore aucun niveau decide : passez par Diagnostics';
  end if;

  if not exists (select 1 from public.programme_niveaux where id = p_niveau_id) then
    raise exception 'ce niveau de programme n''existe pas';
  end if;

  insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
  values (p_student_id, p_niveau_id, 'promotion', auth.uid(), p_motif)
  returning id into v_id;

  perform public.log_sensitive_access(
    'progression_promue', 'progression_historique', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'niveau_id', p_niveau_id, 'motif', p_motif)
  );

  return v_id;
end;
$function$

