-- Deux fuites trouvees par revue, sans lien avec 0040/0041.
--
-- A. `etat_presence(uuid, uuid)` etait accordee a `anon`. Ni 0007 ni 0010 ne
--    l'accordent qu'a `authenticated` -- mais aucune des deux ne revoque le
--    droit que PUBLIC recoit par defaut a la creation de toute fonction, et
--    `anon` en herite comme tout le monde : le meme chemin que documente
--    deja ce depot (EXECUTE arrive par deux chemins sur Supabase). La
--    fonction elle-meme ne verifiait RIEN : ni compte valide, ni lien entre
--    l'appelant et la paire (session, profil) demandee. N'importe qui, meme
--    non connecte, pouvait lire l'etat de presence de n'importe quel profil
--    sur n'importe quelle seance.
--
--    Aucun appel client direct n'existe (`rg "rpc\('etat_presence"` : rien) --
--    la seule voie prevue est `presence_seance_v` (0007), qui borne deja les
--    LIGNES a l'admin/controleur, a l'enseignant de LA seance, au tuteur pour
--    SON foyer, ou au profil lui-meme. Cette portee est copiee dans la
--    fonction, pour qu'elle tienne aussi quand on l'appelle sans passer par
--    la vue -- exactement la lecon de `session_peers_v` en 0041.
--
-- B. `autoriser_jeton_video` n'appelait pas `app_account_valid()`, contrairement
--    a `entrer_observation` qui le fait en premiere ligne. Elle n'est pas
--    exposee au client (ACL = postgres/service_role seulement) : c'est
--    `create-room-token` qui l'appelle sous service_role. Mais cette fonction
--    de bord ne vérifie que la validite du jeton Supabase de l'appelant
--    (`client.auth.getUser()`), jamais le statut du compte -- un compte
--    suspendu ou supprime (`account_status`, `deleted_at`, `access_until`)
--    dont le jeton n'a pas encore expire pouvait continuer a obtenir des
--    jetons video tant que sa ligne `session_participants` restait en place.

-- ============================================================
-- A. etat_presence : portee de presence_seance_v copiee dans la fonction
-- ============================================================

create or replace function public.etat_presence(
  p_session_id uuid,
  p_profile_id uuid
) returns public.presence_state
language plpgsql
stable
security definer
set search_path = ''
as $$
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
  if not (
    public.app_role() = any (array['admin', 'controller']::public.app_role[])
    or (v_seance_trouvee and v_seance.teacher_id = auth.uid())
    or (public.app_role() = 'guardian' and public.est_du_foyer(p_profile_id))
    or p_profile_id = auth.uid()
  ) then
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
$$;

-- `revoke ... from public` ET `from anon` : sur Supabase l'un sans l'autre ne
-- suffit pas, seul `has_function_privilege` le montre.
revoke all on function public.etat_presence(uuid, uuid) from public;
revoke all on function public.etat_presence(uuid, uuid) from anon;
grant execute on function public.etat_presence(uuid, uuid) to authenticated;

-- ============================================================
-- B. autoriser_jeton_video : le compte doit etre valide, comme partout ailleurs
-- ============================================================

create or replace function public.autoriser_jeton_video(
  p_session_id uuid,
  p_profile_id uuid,
  p_ws_url_cloud text,
  p_ws_url_self_hosted text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_seance    public.sessions%rowtype;
  v_role      public.participant_role;
  v_route     record;
  v_ttl       int;
  v_camera    public.camera_policy;
  v_publier       boolean;
  v_publier_video boolean;
  v_publier_data  boolean;
  v_invisible     boolean;
  v_expire    timestamptz;
  v_identite  text;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_budget    jsonb;
begin
  -- Meme porte que `entrer_observation` : un compte suspendu ou supprime ne
  -- doit pas pouvoir tirer un jeton video parce que son jeton Supabase n'a
  -- pas encore expire. `create-room-token` ne verifie que ce dernier point.
  if not public.app_account_valid() then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;
  if not found then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  -- La fenetre d'ouverture : configurable (D-13, 20 min par defaut), jusqu'a
  -- la fin annoncee majoree de la grace configurable.
  if now() < coalesce(v_seance.join_opens_at, v_seance.started_at - make_interval(mins => v_fenetre)) then
    raise exception 'salle pas encore ouverte' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + make_interval(mins => v_grace) then
    raise exception 'salle fermee' using errcode = 'check_violation';
  end if;

  -- Le quota PRECEDE le jeton pour un observateur-tuteur : un jeton d'abord
  -- et un quota ensuite a deja laisse entrer (G §1.5, confirme par Q).
  if v_role = 'guardian_observer' then
    v_budget := public.budget_observation(p_session_id);
    if not (v_budget->>'peut_entrer')::boolean then
      raise exception 'quota d''observation atteint : %', v_budget->>'motif_refus'
        using errcode = 'check_violation';
    end if;
  end if;

  select * into v_route from public.video_route_de_seance(
    p_session_id, p_ws_url_cloud, p_ws_url_self_hosted
  );

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_ttl := coalesce(v_ttl, 300);

  -- Les capacites. Table de G §1.5 :
  --   guardian_observer : rien ne se publie, masque, ttl borne par le budget.
  --   admin_masked      : rien ne se publie, masque comme un controleur.
  --   admin_visible     : voix + image, JAMAIS le canal de donnees (c'est
  --                       l'enseignant qui garde la main pedagogique), visible.
  --   masked_controller : inchange (0010/0012).
  v_identite      := p_profile_id::text;
  -- SEULE LIGNE MODIFIEE PAR 0040. `guardian_observer` rejoint les roles
  -- masques : c'est ce que la table ci-dessus annoncait deja (« masque ») et ce
  -- que la regle de visibilite du 21/09 exige. Sans lui, le jeton partait avec
  -- hidden = false et les quatre autres enfants du groupe voyaient le tuteur.
  v_invisible     := (v_role in ('masked_controller', 'admin_masked', 'guardian_observer'));
  v_publier       := v_role in ('teacher', 'student', 'admin_visible');
  v_publier_data  := (v_role = 'teacher');
  v_publier_video := (v_role = 'admin_visible');

  if v_role = 'teacher' then
    v_publier_video := true;
  elsif v_role = 'student' then
    select sp.camera_policy into v_camera
      from public.student_profiles sp
     where sp.profile_id = p_profile_id;
    v_publier_video := (coalesce(v_camera, 'forbidden') = 'allowed');
  end if;

  if v_role = 'guardian_observer' then
    v_expire := now() + make_interval(secs => least(v_ttl, ((v_budget->>'restant_secondes')::int)));
  else
    v_expire := now() + make_interval(secs => v_ttl);
  end if;

  -- L'identite institutionnelle : c'est l'institution qui entre, pas
  -- quelqu'un. Jamais le prenom de la personne pour admin_visible.
  if v_role = 'admin_visible' then
    v_identite := 'Administration Rewayah';
  end if;

  insert into public.video_token_grants (
    session_id, profile_id, role, provider,
    can_publish, can_publish_video, can_publish_data, hidden, expire_le
  ) values (
    p_session_id, p_profile_id, v_role, v_route.provider,
    v_publier, v_publier_video, v_publier_data, v_invisible, v_expire
  );

  perform public.log_sensitive_access(
    'video_token_issued',
    'video_token_grants',
    p_session_id::text,
    jsonb_build_object(
      'profile_id', p_profile_id,
      'role', v_role,
      'provider', v_route.provider,
      'hidden', v_invisible
    )
  );

  return jsonb_build_object(
    'ws_url', v_route.ws_url,
    'room_name', v_route.room_name,
    'provider', v_route.provider,
    'identity', v_identite,
    'role', v_role,
    'ttl_seconds', extract(epoch from (v_expire - now()))::int,
    'expire_le', v_expire,
    'capabilities', jsonb_build_object(
      'can_publish', v_publier,
      'can_publish_video', v_publier_video,
      'can_publish_data', v_publier_data,
      'can_subscribe', true,
      'hidden', v_invisible
    )
  );
end;
$$;
