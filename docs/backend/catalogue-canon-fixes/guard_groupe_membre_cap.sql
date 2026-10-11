CREATE OR REPLACE FUNCTION public.guard_groupe_membre_cap()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_max smallint;
  v_actifs int;
  v_groupe_ended timestamptz;
begin
  if new.left_at is not null then
    return new;
  end if;

  select seuil_max, ended_at into v_max, v_groupe_ended
  from public.groupes
  where id = new.groupe_id;

  if v_groupe_ended is not null then
    raise exception 'ce groupe est cloture, aucun nouveau membre ne peut y entrer';
  end if;

  select count(*) into v_actifs
  from public.groupe_membres m
  where m.groupe_id = new.groupe_id and m.left_at is null and m.id <> new.id;

  if v_actifs >= v_max then
    raise exception 'plafond de membres atteint pour ce groupe (%)', v_max;
  end if;

  return new;
end;
$function$

