CREATE OR REPLACE FUNCTION public.guard_rule_override_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if tg_op = 'DELETE' then
    raise exception 'une regle ayant compte pour une seance ne s''efface pas';
  end if;

  if old.ended_at is not null then
    raise exception 'cette regle est deja close';
  end if;

  if new.profile_id <> old.profile_id or new.key <> old.key
     or new.value <> old.value or new.reason <> old.reason
     or new.set_by <> old.set_by or new.created_at <> old.created_at then
    raise exception 'seule la cloture d''une regle est modifiable';
  end if;

  return new;
end;
$function$

