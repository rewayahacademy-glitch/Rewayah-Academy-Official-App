CREATE OR REPLACE FUNCTION public.poser_exception_progression(p_student_id uuid, p_type text, p_motif text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'pose d''une exception de progression reservee a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour poser une exception';
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

  if exists (
    select 1 from public.progression_exceptions
    where student_id = p_student_id and type = p_type and closed_at is null
  ) then
    raise exception 'une exception de ce type est deja active pour cet eleve';
  end if;

  insert into public.progression_exceptions (student_id, type, motif, cree_par)
  values (p_student_id, p_type, p_motif, auth.uid())
  returning id into v_id;

  perform public.log_sensitive_access(
    'exception_progression_posee', 'progression_exceptions', v_id::text,
    jsonb_build_object('student_id', p_student_id, 'type', p_type, 'motif', p_motif)
  );

  return v_id;
end;
$function$

