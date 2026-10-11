CREATE OR REPLACE FUNCTION public.partie_concernee(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    public.app_role() in ('admin', 'controller')
    or p_profile_id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = p_profile_id
        and p.household_id is not null
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
    or exists (
      select 1 from public.teacher_student_assignments a
      where a.ended_at is null
        and (
          (a.teacher_id = auth.uid() and a.student_id = p_profile_id)
          or (a.student_id = auth.uid() and a.teacher_id = p_profile_id)
        )
    )
    -- Le foyer est partie au dossier de l'enseignant de son enfant. Sans cette
    -- branche, un tuteur ne pourrait lire ni les disponibilites ni les reglages
    -- de priere de la personne qui fait cours a son enfant : la transparence
    -- exigee par l'ADR-017 s'arreterait a l'enfant lui-meme, qui a six ans.
    or exists (
      select 1
      from public.teacher_student_assignments a
      join public.profiles eleve on eleve.id = a.student_id
      where a.ended_at is null
        and a.teacher_id = p_profile_id
        and eleve.household_id is not null
        and eleve.household_id = public.app_household_id()
        and eleve.deleted_at is null
    );
$function$

