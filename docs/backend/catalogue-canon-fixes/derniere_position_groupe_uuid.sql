CREATE OR REPLACE FUNCTION public.derniere_position_groupe(p_groupe_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_autorise boolean;
  v_position jsonb;
begin
  select exists (
    select 1 from public.groupes g
    where g.id = p_groupe_id
      and (
        g.teacher_id = auth.uid()
        or public.app_role() = 'admin'
        or exists (
          select 1 from public.groupe_membres m
          where m.groupe_id = g.id and m.left_at is null
            and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
        )
      )
  ) into v_autorise;

  if not v_autorise then
    raise exception 'groupe introuvable ou acces refuse' using errcode = 'insufficient_privilege';
  end if;

  select c.group_resume_position into v_position
    from public.session_shared_content c
    join public.sessions s on s.id = c.session_id
   where s.groupe_id = p_groupe_id
     and s.deleted_at is null
     and c.group_resume_position is not null
   order by s.started_at desc
   limit 1;

  return v_position;
end;
$function$

