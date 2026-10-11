CREATE OR REPLACE FUNCTION public.profil_du_jeton_appareil(p_token text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_hash text := encode(extensions.digest(convert_to(p_token, 'UTF8'), 'sha256'), 'hex');
  v_profile uuid;
begin
  select d.profile_id into v_profile
  from public.devices d
  where d.token_hash = v_hash
    and d.revoked_at is null and d.deleted_at is null;

  if v_profile is null then
    raise exception 'jeton d''appareil inconnu ou revoque';
  end if;

  update public.devices set last_used_at = now() where token_hash = v_hash;
  return v_profile;
end;
$function$

