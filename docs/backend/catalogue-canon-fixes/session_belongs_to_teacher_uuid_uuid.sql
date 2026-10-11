CREATE OR REPLACE FUNCTION public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.sessions s
    where s.id = p_session_id and s.teacher_id = p_uid and s.deleted_at is null
  );
$function$

