CREATE OR REPLACE FUNCTION public.enregistrer_webhook_livekit(p_event_id text, p_event_type text, p_room_name text, p_profile_id uuid, p_server_ts timestamp with time zone, p_detail jsonb DEFAULT '{}'::jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_session_id uuid;
  v_type       public.session_event_type;
  v_source     text;
begin
  insert into public.livekit_webhook_deliveries (event_id, event_type, room_name, detail)
  values (p_event_id, p_event_type, p_room_name, coalesce(p_detail, '{}'::jsonb))
  on conflict (event_id) do nothing;

  if not found then
    return false;   -- rejeu : rien d'autre a faire
  end if;

  -- La salle est opaque : seule `session_video_route` sait a quelle seance
  -- elle correspond. Un webhook qui nomme une salle inconnue est enregistre
  -- -- pour l'exploitation -- mais n'ecrit aucune presence.
  select r.session_id into v_session_id
    from public.session_video_route r
   where r.room_name = p_room_name;

  if v_session_id is null or p_profile_id is null then
    return false;
  end if;

  -- Seuls les evenements de presence descendent dans `session_events`. Le
  -- reste (room_started, track_published...) reste dans le journal de
  -- reception : §33 interdit de stocker chaque evenement brut comme une ligne
  -- permanente du metier.
  v_type := case p_event_type
    when 'participant_joined' then 'joined'::public.session_event_type
    when 'participant_left' then 'left'::public.session_event_type
    else null
  end;

  if v_type is null then
    return false;
  end if;

  -- Le vocabulaire fixe par N1. Un depart annonce par LiveKit est subi par
  -- defaut : c'est le client qui, en pressant le bouton de sortie, ecrit
  -- `user_action` avant de se deconnecter. Confondre les deux ferait
  -- disparaitre la distinction entre `sortie` et `deconnectee`.
  v_source := 'livekit_webhook';

  -- Un depart deja ecrit par le geste volontaire du participant ne doit pas
  -- etre double par le webhook qui suit : sans cela, `etat_presence()` lirait
  -- le webhook comme derniere trace et rendrait `deconnectee` la ou
  -- l'utilisateur a proprement quitte.
  if v_type = 'left' and exists (
    select 1 from public.session_events e
     where e.session_id = v_session_id
       and e.profile_id = p_profile_id
       and e.event_type = 'left'
       and e.source = 'user_action'
       and e.server_ts > p_server_ts - interval '30 seconds'
  ) then
    return false;
  end if;

  insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
  values (v_session_id, p_profile_id, v_type, coalesce(p_server_ts, now()), v_source);

  update public.livekit_webhook_deliveries
     set applique = true
   where event_id = p_event_id;

  return true;
end;
$function$

