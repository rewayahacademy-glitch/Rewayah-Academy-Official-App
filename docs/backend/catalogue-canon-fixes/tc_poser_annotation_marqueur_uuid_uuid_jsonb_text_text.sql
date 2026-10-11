CREATE OR REPLACE FUNCTION public.tc_poser_annotation_marqueur(p_layer_id uuid, p_id uuid, p_plage jsonb, p_intention text, p_note text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_resource_id uuid;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte inactif' using errcode = '42501';
  end if;

  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = p_layer_id
     and l.auteur_profile_id = auth.uid()
   for update;
  if v_resource_id is null then
    raise exception 'couche inaccessible' using errcode = '42501';
  end if;
  if p_id is null or p_plage is null
     or pg_catalog.jsonb_typeof(p_plage) <> 'object'
     or p_plage ->> 'resource_id' is distinct from v_resource_id::text
     or not coalesce(p_intention in ('learn', 'review', 'reinforce', 'maintain', 'assessment'), false) then
    raise exception 'marqueur invalide';
  end if;

  delete from public.annotation_marqueur
   where layer_id = p_layer_id and plage = p_plage;
  insert into public.annotation_marqueur (id, layer_id, plage, intention, note)
  values (p_id, p_layer_id, p_plage, p_intention, p_note);
end;
$function$

