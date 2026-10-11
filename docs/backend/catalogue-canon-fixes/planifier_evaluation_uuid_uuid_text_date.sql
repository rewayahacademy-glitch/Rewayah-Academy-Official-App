CREATE OR REPLACE FUNCTION public.planifier_evaluation(p_student_id uuid, p_niveau_id uuid, p_type text, p_date_prevue date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'planification d''une evaluation reservee a l''administration';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_id
      and p.role = 'student'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if not exists (select 1 from public.programme_niveaux where id = p_niveau_id) then
    raise exception 'ce niveau de programme n''existe pas';
  end if;

  insert into public.evaluations (student_id, niveau_id, type, date_prevue)
  values (p_student_id, p_niveau_id, p_type, p_date_prevue)
  returning id into v_id;

  perform public.log_sensitive_access(
    'evaluation_planifiee', 'evaluations', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'niveau_id', p_niveau_id, 'type', p_type, 'date_prevue', p_date_prevue)
  );

  return v_id;
end;
$function$

