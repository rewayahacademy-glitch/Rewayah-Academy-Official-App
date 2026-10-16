-- Jeton video : la porte de compte de 0042 visait auth.uid(), absent sous
-- service_role. `create-room-token` appelle cette RPC avec la cle de service :
-- tout appel reel tombait sur « compte non valide » (constate sur STAGING le
-- 16/10/2026 : 403 pour l'enseignant et l'eleve inscrits). Les scenarios N1-N5
-- simulaient test.uid et ne le voyaient pas.
-- 1. La validite du compte porte sur p_profile_id.
-- 2. L'enseignant attitre de la seance (sessions.teacher_id) est admis meme
--    sans ligne session_participants, que les seances de classe n'ont pas.
-- Le reste du corps est celui de 0042, inchange. ACL inchangee (CREATE OR
-- REPLACE conserve postgres/service_role seuls).

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
  -- Meme exigence que 0042 (compte actif, non supprime, acces non echu), mais
  -- sur le profil pour lequel le jeton est demande : `create-room-token`
  -- appelle sous service_role, sans auth.uid(), et la porte de 0042
  -- refusait donc tout le monde. La fonction Edge passe l'identifiant du
  -- jeton Supabase verifie (`compte.id`), jamais une valeur du corps.
  if not exists (
    select 1 from public.profiles p
     where p.id = p_profile_id
       and p.deleted_at is null
       and p.account_status in ('active', 'provisional_active')
       and (p.access_until is null or p.access_until > now())
  ) then
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
    -- L'enseignant attitre de la seance : `materialiser_seances_groupe`
    -- n'inscrit que les eleves dans session_participants.
    if v_seance.teacher_id is not null and v_seance.teacher_id = p_profile_id then
      v_role := 'teacher';
    else
      raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
    end if;
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

revoke all on function public.autoriser_jeton_video(uuid, uuid, text, text)
  from public, anon, authenticated;

do $postflight$
begin
  if has_function_privilege('anon', 'public.autoriser_jeton_video(uuid, uuid, text, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.autoriser_jeton_video(uuid, uuid, text, text)', 'EXECUTE')
     or not has_function_privilege('service_role', 'public.autoriser_jeton_video(uuid, uuid, text, text)', 'EXECUTE') then
    raise exception 'autoriser_jeton_video : ACL inattendue';
  end if;
  if pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid, uuid, text, text)'::regprocedure)
       like '%app_account_valid()%' then
    raise exception 'autoriser_jeton_video : porte encore liee a auth.uid()';
  end if;
end
$postflight$;
