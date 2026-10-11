CREATE OR REPLACE FUNCTION public.video_route_de_seance(p_session_id uuid, p_ws_url_cloud text, p_ws_url_self_hosted text)
 RETURNS TABLE(provider video_provider, ws_url text, room_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_config    public.video_config%rowtype;
  v_provider  public.video_provider;
  v_url       text;
  v_room      text;
  v_tirage    int;
begin
  -- Deja route : on relit, on ne rejoue pas le tirage.
  return query
    select r.provider, r.ws_url, r.room_name
      from public.session_video_route r
     where r.session_id = p_session_id;
  if found then
    return;
  end if;

  select * into v_config from public.video_config where id;

  v_provider := v_config.active_provider;

  -- Le canari : une fraction des seances part sur l'autre fournisseur. Le
  -- tirage vient du `session_id`, donc il est reproductible en test et stable
  -- si la fonction est rappelee.
  if v_config.canary_provider is not null and v_config.canary_percentage > 0 then
    -- 28 bits et non 32 : `bit(32)::int` rend un entier SIGNE, donc negatif
    -- une fois sur deux, et un modulo negatif ne tomberait jamais dans le
    -- canari. Sur 28 bits la valeur tient dans un int positif par
    -- construction.
    v_tirage := ('x' || substr(md5(p_session_id::text), 1, 7))::bit(28)::int % 100;
    if v_tirage < v_config.canary_percentage then
      v_provider := v_config.canary_provider;
    end if;
  end if;

  v_url := coalesce(
    v_config.ws_url_override,
    case v_provider
      when 'cloud' then p_ws_url_cloud
      when 'self_hosted' then p_ws_url_self_hosted
    end
  );

  if v_url is null or v_url = '' then
    raise exception 'aucune URL pour le fournisseur %', v_provider
      using errcode = 'check_violation';
  end if;

  -- Un nom de salle opaque (section 10 : aucune donnee personnelle). Il derive
  -- du `session_id` pour rester stable, sans le reveler tel quel.
  -- `extensions.digest` et non `digest` : ces fonctions ont `search_path = ''`
  -- et pgcrypto vit dans le schema `extensions` (0001, ligne 19).
  v_room := 'r_' || substr(
    encode(extensions.digest(p_session_id::text, 'sha256'), 'hex'), 1, 32
  );

  insert into public.session_video_route (session_id, provider, ws_url, room_name)
  values (p_session_id, v_provider, v_url, v_room)
  on conflict (session_id) do nothing;

  -- Relecture inconditionnelle : si un appel concurrent a gagne la course,
  -- c'est SA decision qui fait foi, pas la notre.
  return query
    select r.provider, r.ws_url, r.room_name
      from public.session_video_route r
     where r.session_id = p_session_id;
end;
$function$

