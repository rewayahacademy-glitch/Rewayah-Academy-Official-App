CREATE OR REPLACE FUNCTION public.video_config_lire()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_config public.video_config%rowtype;
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'reserve a l''administration' using errcode = 'insufficient_privilege';
  end if;
  select * into v_config from public.video_config where id;
  return jsonb_build_object(
    'active_provider', v_config.active_provider,
    'canary_provider', v_config.canary_provider,
    'canary_percentage', v_config.canary_percentage,
    'ws_url_override', v_config.ws_url_override,
    'token_ttl_seconds', v_config.token_ttl_seconds,
    'updated_at', v_config.updated_at
  );
end;
$function$

