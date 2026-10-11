CREATE OR REPLACE FUNCTION public.guard_prayer_adjustments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_cle text;
  v_valeur jsonb;
begin
  if jsonb_typeof(new.adjustments) <> 'object' then
    raise exception 'les ajustements sont un objet';
  end if;

  foreach v_cle in array array['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] loop
    v_valeur := new.adjustments -> v_cle;
    if v_valeur is null or jsonb_typeof(v_valeur) <> 'number' then
      raise exception 'ajustement manquant ou non numerique : %', v_cle;
    end if;
    if (v_valeur #>> '{}')::numeric < -30 or (v_valeur #>> '{}')::numeric > 30 then
      raise exception 'ajustement hors bornes pour % : au-dela de 30 minutes, changez de methode', v_cle;
    end if;
  end loop;

  if (select count(*) from jsonb_object_keys(new.adjustments)) <> 5 then
    raise exception 'les ajustements ne portent que les cinq prieres';
  end if;

  new.updated_at := now();
  return new;
end;
$function$

