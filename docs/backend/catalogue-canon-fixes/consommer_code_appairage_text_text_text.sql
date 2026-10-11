CREATE OR REPLACE FUNCTION public.consommer_code_appairage(p_code text, p_device_fingerprint text, p_platform text)
 RETURNS TABLE(profile_id uuid, device_id uuid, device_token text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_hash text := encode(extensions.digest(convert_to(upper(btrim(p_code)), 'UTF8'), 'sha256'), 'hex');
  v_row public.device_pairing_codes;
  v_device uuid;
  v_token text := encode(extensions.gen_random_bytes(32), 'hex');
  v_max int;
  v_actifs int;
begin
  select * into v_row
  from public.device_pairing_codes c
  where c.code_hash = v_hash and c.deleted_at is null
  for update;

  if v_row.id is null then
    raise exception 'code inconnu';
  end if;
  if v_row.consumed_at is not null then
    raise exception 'code deja utilise';
  end if;
  if v_row.expires_at <= now() then
    raise exception 'code expire';
  end if;

  -- I7 : le plafond est verifie au moment ou l'appareil arrive, pas seulement au
  -- moment ou le code a ete demande. L'appareil en cours d'appairage est exclu
  -- du compte, pour qu'un reappairage ne se compte pas deux fois.
  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into v_max;
  select count(*) into v_actifs from public.devices d
  where d.profile_id = v_row.student_profile_id
    and d.device_fingerprint <> p_device_fingerprint
    and d.revoked_at is null and d.deleted_at is null;
  if v_actifs >= v_max then
    raise exception 'plafond d''appareils atteint';
  end if;

  insert into public.devices (
    profile_id, device_fingerprint, platform, token_hash, last_used_at
  ) values (
    v_row.student_profile_id, p_device_fingerprint, p_platform,
    encode(extensions.digest(convert_to(v_token, 'UTF8'), 'sha256'), 'hex'), now()
  )
  -- Le conflit se designe par le NOM de la contrainte, pas par ses colonnes :
  -- `profile_id` est aussi le nom d'un parametre de sortie de cette fonction, et
  -- PL/pgSQL ne sait pas lequel des deux est vise dans une clause d'inference.
  on conflict on constraint devices_profile_fingerprint_unique do update
  set token_hash = excluded.token_hash,
      revoked_at = null,
      last_used_at = now()
  returning id into v_device;

  update public.device_pairing_codes
  set consumed_at = now(), consumed_by_device = v_device
  where id = v_row.id;

  perform public.log_sensitive_access('appairage_consomme', 'devices', v_device::text,
    jsonb_build_object('platform', p_platform));

  return query select v_row.student_profile_id, v_device, v_token;
end;
$function$

