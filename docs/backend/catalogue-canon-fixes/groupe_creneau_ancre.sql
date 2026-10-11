CREATE OR REPLACE FUNCTION public.groupe_creneau_ancre()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if tg_op = 'UPDATE'
     and old.weekday = new.weekday
     and old.hour_local = new.hour_local then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    delete from public.groupe_creneaux
    where groupe_id = new.id
      and weekday = old.weekday
      and hour_local = old.hour_local;
  end if;

  insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
  values (new.id, new.weekday, new.hour_local)
  on conflict (groupe_id, weekday, hour_local) do nothing;

  return new;
end;
$function$

