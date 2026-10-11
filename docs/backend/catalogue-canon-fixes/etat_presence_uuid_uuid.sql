CREATE OR REPLACE FUNCTION public.etat_presence(p_session_id uuid, p_profile_id uuid)
 RETURNS presence_state
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance         public.sessions%rowtype;
  v_seance_trouvee boolean;
  v_override       public.presence_state;
  v_premier_joined timestamptz;
  v_dernier_type   public.session_event_type;
  v_dernier_ts     timestamptz;
  v_dernier_source text;
  v_left_subi      boolean;
  v_jeton_le       timestamptz;
  v_seuil_retard   int := public.app_config_int('presence.seuil_retard_secondes', 300);
  v_fenetre_reco   int := public.app_config_int('presence.fenetre_reconnexion_secondes', 120);
  v_fenetre_conn   int := public.app_config_int('presence.fenetre_connexion_secondes', 90);
  v_fenetre_join   int := public.app_config_int('join_window_minutes', 20);
begin
  if not public.app_account_valid() then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  v_seance_trouvee := found;

  -- La meme portee que le WHERE de `presence_seance_v` (0007) : admin ou
  -- controleur, l'enseignant de CETTE seance, un tuteur pour SON foyer, ou
  -- le profil lui-meme. Rien d'autre n'apprend l'etat de presence de rien.
  if not coalesce((
    public.app_role() = any (array['admin', 'controller']::public.app_role[])
    or (v_seance_trouvee and v_seance.teacher_id = auth.uid())
    or (public.app_role() = 'guardian' and public.est_du_foyer(p_profile_id))
    or p_profile_id = auth.uid()
  ), false) then
    raise exception 'acces refuse' using errcode = 'insufficient_privilege';
  end if;

  if not v_seance_trouvee then
    return null;
  end if;

  select o.etat into v_override from public.session_presence_override o
   where o.session_id = p_session_id and o.profile_id = p_profile_id;
  if v_override is not null then
    return v_override;
  end if;

  select min(e.server_ts) into v_premier_joined
    from public.session_events e
   where e.session_id = p_session_id
     and e.profile_id = p_profile_id
     and e.event_type = 'joined';

  select e.event_type, e.server_ts, e.source
    into v_dernier_type, v_dernier_ts, v_dernier_source
    from public.session_events e
   where e.session_id = p_session_id
     and e.profile_id = p_profile_id
     and e.event_type in ('joined', 'left', 'track_subscribed')
   order by e.server_ts desc, e.id desc
   limit 1;

  if v_premier_joined is null then
    if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
      return 'absente';
    end if;

    select max(g.emis_le) into v_jeton_le
      from public.video_token_grants g
     where g.session_id = p_session_id
       and g.profile_id = p_profile_id;

    if v_jeton_le is not null
       and now() - v_jeton_le <= make_interval(secs => v_fenetre_conn) then
      return 'en_connexion';
    end if;

    if now() < v_seance.started_at - make_interval(mins => v_fenetre_join) then
      return 'planifiee';
    end if;
    return 'en_attente';
  end if;

  if v_dernier_type = 'left' then
    if v_dernier_source = 'user_action' then
      return 'sortie';
    end if;
    if now() - v_dernier_ts <= make_interval(secs => v_fenetre_reco) then
      return 'en_reconnexion';
    end if;
    return 'deconnectee';
  end if;

  select exists (
    select 1 from public.session_events e
     where e.session_id = p_session_id
       and e.profile_id = p_profile_id
       and e.event_type = 'left'
       and e.source <> 'user_action'
       and e.server_ts < v_dernier_ts
  ) into v_left_subi;

  if v_left_subi then
    return 'reconnectee';
  end if;

  if v_premier_joined > v_seance.started_at + make_interval(secs => v_seuil_retard) then
    return 'en_retard';
  end if;

  if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
    return 'confirmation_en_attente';
  end if;

  return 'presente';
end;
$function$

