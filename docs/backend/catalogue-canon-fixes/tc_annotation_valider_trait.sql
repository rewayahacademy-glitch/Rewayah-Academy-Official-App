CREATE OR REPLACE FUNCTION public.tc_annotation_valider_trait()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_resource_id uuid;
begin
  select l.resource_id into v_resource_id
    from public.annotation_layer l
   where l.id = new.layer_id
   for update;
  if v_resource_id is null
     or pg_catalog.jsonb_typeof(new.ancrage) <> 'object'
     or new.ancrage ->> 'resource_id' is distinct from v_resource_id::text
     or pg_catalog.jsonb_typeof(new.points) <> 'array' then
    raise exception 'trait incompatible avec la couche'
      using errcode = '23514';
  end if;
  return new;
end;
$function$

