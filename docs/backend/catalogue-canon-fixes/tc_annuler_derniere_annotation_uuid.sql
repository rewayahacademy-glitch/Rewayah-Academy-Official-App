CREATE OR REPLACE FUNCTION public.tc_annuler_derniere_annotation(p_layer_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_layer public.annotation_layer%rowtype;
  v_type text;
  v_id uuid;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte inactif' using errcode = '42501';
  end if;

  select * into v_layer
    from public.annotation_layer l
   where l.id = p_layer_id
     and l.auteur_profile_id = auth.uid()
   for update;
  if not found then
    raise exception 'couche inaccessible' using errcode = '42501';
  end if;

  select geste.type, geste.id into v_type, v_id
    from (
      select 'trait'::text as type, t.id, t.cree_le
        from public.annotation_trait t where t.layer_id = p_layer_id
      union all
      select 'marqueur'::text as type, m.id, m.cree_le
        from public.annotation_marqueur m where m.layer_id = p_layer_id
    ) geste
   order by geste.cree_le desc, geste.id desc
   limit 1;

  if v_id is null then
    return;
  elsif v_type = 'trait' then
    delete from public.annotation_trait where id = v_id and layer_id = p_layer_id;
  else
    delete from public.annotation_marqueur where id = v_id and layer_id = p_layer_id;
  end if;
end;
$function$

