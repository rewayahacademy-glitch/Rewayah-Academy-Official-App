CREATE OR REPLACE FUNCTION public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'ajout d''un eleve a un groupe reserve a l''administration';
  end if;

  if coalesce(btrim(p_motif), '') = '' then
    raise exception 'un motif est requis pour ajouter un eleve a un groupe';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.role = 'student'
      and p.deleted_at is null
      and p.account_status in ('active', 'provisional_active')
  ) then
    raise exception 'cet eleve n''existe pas ou son compte n''est pas valide';
  end if;

  if exists (
    select 1 from public.groupe_membres where student_id = p_student_profile_id and left_at is null
  ) then
    raise exception 'cet eleve appartient deja a un groupe actif';
  end if;

  insert into public.groupe_membres (groupe_id, student_id)
  values (p_groupe_id, p_student_profile_id);

  perform public.log_sensitive_access(
    'eleve_ajoute_groupe', 'groupe_membres', p_groupe_id::text,
    jsonb_build_object('student_id', p_student_profile_id, 'motif', p_motif)
  );
end;
$function$

