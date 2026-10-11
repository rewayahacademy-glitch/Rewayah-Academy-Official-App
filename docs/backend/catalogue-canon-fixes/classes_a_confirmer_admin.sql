CREATE OR REPLACE FUNCTION public.classes_a_confirmer_admin()
 RETURNS TABLE(classe_id uuid, libelle text, peut_affecter_enseignant boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'acces reserve a l''administration';
  end if;
  return query
  select g.id, g.libelle, true
  from public.groupes g
  where g.teacher_id is null
    and g.etat = 'en_attente_enseignant'
    and g.ended_at is null
  order by g.created_at, g.id;
end;
$function$

