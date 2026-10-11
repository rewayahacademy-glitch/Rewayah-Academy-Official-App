CREATE OR REPLACE FUNCTION public.revoquer_appareil(p_device_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_profil uuid;
begin
  if NOT coalesce(public.app_role() IN ('guardian', 'admin') AND public.app_account_valid(), false) then
    raise exception 'seul un tuteur ou un administrateur revoque un appareil';
  end if;

  select d.profile_id into v_profil
  from public.devices d
  join public.profiles p on p.id = d.profile_id
  where d.id = p_device_id
    and d.deleted_at is null
    and p.deleted_at is null
    and (
      public.app_role() = 'admin'
      or (p.household_id is not null and p.household_id = public.app_household_id())
    );

  if v_profil is null then
    raise exception 'cet appareil n''appartient pas a votre foyer';
  end if;

  update public.devices
  set revoked_at = now(), token_hash = null
  where id = p_device_id and revoked_at is null;

  -- Le jeton est efface en meme temps que la revocation : un appareil revoque
  -- dont le jeton survivrait resterait utilisable jusqu'a la prochaine lecture.
  perform public.log_sensitive_access('appareil_revoque', 'devices',
    p_device_id::text, jsonb_build_object('profile_id', v_profil));
end;
$function$

