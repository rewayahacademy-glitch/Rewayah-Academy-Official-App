CREATE OR REPLACE FUNCTION public.creer_code_appairage(p_student_profile_id uuid)
 RETURNS TABLE(code text, expires_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  -- 32 caracteres, sans 0 O 1 I : 256 est un multiple de 32, donc le tirage est
  -- uniforme sans biais de modulo. 32^6, soit environ 1,07 milliard.
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code text;
  v_expire timestamptz;
  v_max int;
  v_actifs int;
begin
  if NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) or not public.app_account_valid() then
    raise exception 'seul un tuteur au compte valide appaire un appareil';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = p_student_profile_id
      and p.household_id is not null
      and p.household_id = public.app_household_id()
      and p.role = 'student'
      and p.deleted_at is null
  ) then
    raise exception 'cet eleve n''appartient pas a votre foyer';
  end if;

  select coalesce((public.get_config('max_devices_per_student', '2'::jsonb) #>> '{}')::int, 2)
    into v_max;
  select count(*) into v_actifs from public.devices d
  where d.profile_id = p_student_profile_id
    and d.revoked_at is null and d.deleted_at is null;
  if v_actifs >= v_max then
    raise exception 'plafond d''appareils atteint';
  end if;

  -- Un seul code vivant par eleve : en demander un nouveau perime le precedent.
  update public.device_pairing_codes
  set deleted_at = now()
  where student_profile_id = p_student_profile_id
    and consumed_at is null and deleted_at is null;

  select string_agg(substr(v_alphabet, 1 + (get_byte(s.b, i) % 32), 1), '' order by i)
  into v_code
  from (select extensions.gen_random_bytes(6) as b) s,
       generate_series(0, 5) as i;

  v_expire := now() + make_interval(mins =>
    coalesce((public.get_config('pairing_code_ttl_minutes', '10'::jsonb) #>> '{}')::int, 10));

  insert into public.device_pairing_codes (student_profile_id, code_hash, created_by, expires_at)
  values (
    p_student_profile_id,
    encode(extensions.digest(convert_to(v_code, 'UTF8'), 'sha256'), 'hex'),
    auth.uid(),
    v_expire
  );

  perform public.log_sensitive_access('appairage_code_cree', 'device_pairing_codes',
    p_student_profile_id::text, '{}'::jsonb);

  return query select v_code, v_expire;
end;
$function$

