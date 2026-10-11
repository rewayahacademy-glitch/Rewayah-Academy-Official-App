CREATE OR REPLACE FUNCTION public.tc_annotation_toucher_couche()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_layer_id uuid;
begin
  v_layer_id := case when tg_op = 'DELETE' then old.layer_id else new.layer_id end;
  update public.annotation_layer
     set maj_le = pg_catalog.now()
   where id = v_layer_id;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$function$

