CREATE OR REPLACE FUNCTION public.rejoindre_observation(p_session_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_seance public.sessions%rowtype;
  v_role   public.participant_role;
begin
  -- L'exclusion de role de l'ADR-011 (« un meme profil ne peut pas etre a la
  -- fois enseignant et controleur ») tient deja dans `profiles.role` : ce test
  -- la reprend sans la rejouer.
  if NOT coalesce(public.app_role() = 'controller' AND public.app_account_valid(), false) or not public.app_account_valid() then
    raise exception 'observation reservee au controle qualite'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  -- Meme liste de statuts que `autoriser_jeton_video()`, volontairement : deux
  -- portes qui refuseraient des seances differentes finiraient par se
  -- contredire, et c'est l'ecran qui porterait la contradiction.
  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  -- « Toute seance EN COURS » : on n'entre pas avant le debut. L'enseignant, lui,
  -- ouvre la salle dix minutes avant (ADR-005) -- observer son pre-vol n'est pas
  -- observer un cours.
  if now() < v_seance.started_at then
    raise exception 'seance pas encore commencee' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'seance terminee' using errcode = 'check_violation';
  end if;

  -- ADR-011 : « ne peut pas observer une seance ou il est lui-meme
  -- participant ». La regle se verifie ici, pas a l'ecran.
  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id and sp.profile_id = auth.uid()
     and sp.deleted_at is null;
  if found and v_role <> 'masked_controller' then
    raise exception 'observer une seance dont on est partie prenante est interdit'
      using errcode = 'check_violation';
  end if;
  if v_seance.teacher_id = auth.uid() then
    raise exception 'observer une seance dont on est partie prenante est interdit'
      using errcode = 'check_violation';
  end if;

  -- Idempotente : une visite interrompue par un rechargement de page doit
  -- pouvoir reprendre. Le conflit reveille une ligne soft-supprimee plutot que
  -- d'echouer sur la cle primaire.
  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), 'masked_controller')
  on conflict (session_id, profile_id) do update
    set deleted_at = null, role = 'masked_controller';

  -- « Qui surveille le surveillant » (ADR-011) : identite, seance, horodatage.
  -- La duree se lit dans `session_events`, ou le webhook ecrit `joined` et
  -- `left`. L'emission du jeton se journalise deja (0010) ; cette entree-ci
  -- nomme la VISITE, et c'est elle que `ADM-04` sait filtrer.
  perform public.log_sensitive_access(
    'controller_observation_started',
    'session_participants',
    p_session_id::text,
    jsonb_build_object(
      'teacher_id', v_seance.teacher_id,
      'started_at', v_seance.started_at,
      'hidden', true
    )
  );

  return p_session_id;
end;
$function$

