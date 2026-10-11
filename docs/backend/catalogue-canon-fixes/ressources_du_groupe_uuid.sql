CREATE OR REPLACE FUNCTION public.ressources_du_groupe(p_groupe_id uuid)
 RETURNS SETOF library_resource
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  -- Porte d'entree, en EXIGENCE POSITIVE (`if not exists ... then raise`) :
  -- avec auth.uid() nul, un `if role <> 'x' then raise` ne se declencherait pas
  -- et ouvrirait la porte a `anon`. On exige en plus app_account_valid(), que
  -- 0033 avait omis et que la policy de la table impose (0032:153).
  if not exists (
    select 1 from public.groupes g
    where g.id = p_groupe_id
      and public.app_account_valid()
      and (
        g.teacher_id = auth.uid()
        or public.app_role() = 'admin'
        or exists (
          select 1 from public.groupe_membres m
          where m.groupe_id = g.id and m.left_at is null
            and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
        )
      )
  ) then
    raise exception 'groupe introuvable ou acces refuse' using errcode = 'insufficient_privilege';
  end if;

  return query
    select r.*
      from public.library_resource r
      join public.library_resource_groupe lrg on lrg.resource_id = r.id
      join public.resource_version rv on rv.id = r.current_version_id
     where lrg.groupe_id = p_groupe_id
       and rv.statut = 'publiee'
       and r.archived_at is null
       -- Transcription litterale de library_resource_lecture (0032:154-176).
       -- Le sous-EXISTS n'est volontairement PAS borne a p_groupe_id : la policy
       -- ne le borne pas non plus, et deux regles differentes pour la meme
       -- donnee sont ce que cette migration repare.
       and (
         public.app_role() = 'admin'
         or r.access_policy in ('publique', 'inscrits')
         or (
           r.access_policy in ('groupe_assigne', 'enseignant_seul')
           and exists (
             select 1
               from public.library_resource_groupe lrg_policy
               join public.groupes g on g.id = lrg_policy.groupe_id
              where lrg_policy.resource_id = r.id
                and (
                  g.teacher_id = auth.uid()
                  or (
                    r.access_policy = 'groupe_assigne'
                    and exists (
                      select 1 from public.groupe_membres m
                      where m.groupe_id = g.id
                        and m.left_at is null
                        and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
                    )
                  )
                )
           )
         )
       )
     order by lrg.epinglee desc, r.title asc;
end;
$function$

