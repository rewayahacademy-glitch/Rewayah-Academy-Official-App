CREATE OR REPLACE FUNCTION public.enregistrer_archive_seance(p_room_name text, p_egress_id text, p_object_key text, p_duration_seconds integer, p_size_bytes bigint, p_codec text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_id uuid;
  v_session_id uuid;
  v_retention int;
begin
  if p_room_name is null or p_object_key is null or p_egress_id is null then
    raise exception 'metadonnees d''archive incompletes' using errcode = '22023';
  end if;

  select r.session_id into v_session_id
  from public.session_video_route r
  where r.room_name = p_room_name;

  if v_session_id is null then
    raise exception 'salle inconnue' using errcode = '23503';
  end if;

  -- La duree de conservation est celle que l'exploitation a posee, lue au
  -- moment de l'entree. Trente jours est le defaut de l'ADR-002, pas une
  -- valeur ecrite en dur ici.
  v_retention := coalesce(
    (public.get_config('recording_retention_days', '30'::jsonb) #>> '{}')::int,
    30
  );

  -- Idempotence portee par l'index unique sur `egress_id`, et non par une
  -- condition ecrite ici : un webhook n'arrive ni une seule fois ni dans
  -- l'ordre (section 29 de la specification).
  insert into public.session_recordings (
    session_id, object_key, duration_seconds, size_bytes, codec, status, expires_at
  )
  values (
    v_session_id,
    p_object_key,
    greatest(coalesce(p_duration_seconds, 0), 0),
    greatest(coalesce(p_size_bytes, 0), 0),
    p_codec,
    'available',
    now() + make_interval(days => v_retention)
  )
  returning id into v_id;

  update public.session_recordings set egress_id = p_egress_id where id = v_id;

  return v_id;
exception
  when unique_violation then
    -- Doublon d'Egress : l'archive est deja entree. Rendre son identifiant
    -- plutot que d'echouer, pour que le webhook reponde 200 et n'appelle pas
    -- un renvoi qui ne serait pas moins doublon.
    select r.id into v_id
    from public.session_recordings r
    where r.egress_id = p_egress_id;
    return v_id;
end;
$function$

