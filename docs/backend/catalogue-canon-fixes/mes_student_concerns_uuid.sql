CREATE OR REPLACE FUNCTION public.mes_student_concerns(p_groupe_id uuid DEFAULT NULL::uuid)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'teacher' and public.app_account_valid(), false) then
    raise exception 'lecture de signalements reservee a un enseignant actif';
  end if;

  return query
  select pg_catalog.jsonb_build_object(
    'id', c.id, 'categorie', c.categorie::text, 'groupe_id', c.groupe_id,
    'session_id', c.session_id, 'academy_id', p.immutable_id,
    'enseignant_id', c.teacher_id, 'internal_details', c.internal_details,
    'family_summary', c.family_summary, 'statut', c.statut::text,
    'cree_le', c.cree_le, 'transmis_le', c.transmis_le,
    'transmis_a', c.transmis_a::text
  )
    from public.student_concern c
    join public.profiles p on p.id = c.student_id
   where c.teacher_id = auth.uid()
     and (p_groupe_id is null or c.groupe_id = p_groupe_id)
   order by c.cree_le desc, c.id desc;
end;
$function$

