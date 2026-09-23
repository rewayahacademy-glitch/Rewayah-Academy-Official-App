-- 0010 : N2, la video. Aiguillage de fournisseur, emission de jeton,
-- reception des webhooks, et l'etat `en_connexion` que N1 refusait de deviner.
--
-- Perimetre fixe par ADR-001 (docs/archive/2026-09-pre-remise-a-plat/architecture/decisions.md) et par
-- docs/archive/2026-09-pre-remise-a-plat/architecture/etape-5-salle-coran-presence.md sections 6.2, 6.3 et 12.
--
-- Ce fichier n'ouvre AUCUNE policy d'ecriture au client. Tout ce qu'il cree
-- s'ecrit par la cle de service, depuis les fonctions Edge, et se lit par des
-- fonctions `security definer` qui reverifient l'autorisation. La raison est
-- dans le titre du lot : le jeton video EST le controle d'acces a la salle.
-- Une policy d'ecriture ici serait une porte sur le produit entier.
--
-- Cinq choix portes ici, pas dans le TypeScript ni dans le Dart :
--
--   1. **Les deux fournisseurs coexistent, et le choix est ancre par seance.**
--      L'operateur a tranche le 12 septembre : Cloud pour eprouver, self-host
--      pour encaisser, jamais Cloud seul. Le piege evident serait de tirer le
--      fournisseur a chaque emission de jeton : un enseignant et son eleve
--      atterriraient alors sur deux serveurs differents et ne se verraient
--      jamais. `session_video_route` fige donc la decision a la PREMIERE
--      emission de la seance ; toutes les suivantes la relisent. Un changement
--      de `canary_percentage` en cours de seance ne peut plus couper une salle
--      en deux.
--
--   2. **La trace d'emission ne va pas dans `session_events`.** Cette table
--      porte la verite serveur venue des webhooks LiveKit ; y injecter ce que
--      notre propre backend decide melangerait deux sources de nature
--      differente, et obligerait a etendre l'enum `session_event_type` -- dont
--      une nouvelle valeur n'est pas utilisable dans la transaction qui
--      l'ajoute. `video_token_grants` est donc une table a part, qui porte en
--      plus ce qu'un evenement de presence n'a pas a porter : le fournisseur
--      retenu, les capacites accordees, la duree de validite.
--
--   3. **Les capacites sont calculees en base, jamais recues du client.**
--      §11 et §42 de la specification LiveKit : l'interface Flutter n'est
--      jamais une couche de securite. Un eleve dont `camera_policy` vaut
--      `forbidden` -- le defaut -- recoit un jeton qui ne PEUT pas publier de
--      video, quoi qu'affiche son ecran. Le controleur recoit `hidden`, ce qui
--      realise `CTR-02` cote serveur et non par une case a cocher.
--
--   4. **L'idempotence des webhooks est une contrainte d'unicite, pas du
--      code.** §29 : les webhooks ne sont ni ordonnes ni garantis sans
--      doublon. `livekit_webhook_deliveries` porte l'identifiant d'evenement
--      LiveKit en cle primaire ; un rejeu s'ecrase sur le conflit et n'ecrit
--      pas deux fois dans `session_events`.
--
--   5. **`en_connexion` devient derivable, et rien d'autre ne bouge dans
--      `etat_presence()`.** N1 a volontairement laisse cet etat de cote faute
--      de trace en base (commentaire de 0007). La trace existe desormais : la
--      fonction est reecrite a l'identique, a une branche pres.

-- ============================================================
-- 1. Le fournisseur, et son aiguillage
-- ============================================================

create type public.video_provider as enum ('cloud', 'self_hosted');

-- La configuration, en une seule ligne. `id` est contraint a `true` : la
-- table ne peut donc physiquement pas en contenir deux, et aucune fonction
-- n'a besoin de choisir laquelle lire.
create table public.video_config (
  id boolean primary key default true check (id),
  active_provider public.video_provider not null default 'cloud',
  -- Le fournisseur vers lequel une fraction des seances est routee. Null
  -- desactive le canari, quel que soit le pourcentage.
  canary_provider public.video_provider,
  canary_percentage int not null default 0
    check (canary_percentage between 0 and 100),
  -- Permet de pointer un serveur precis sans redeployer les fonctions Edge :
  -- c'est le retour arriere « instantane » promis par l'ADR-001. Null = la
  -- variable d'environnement du fournisseur retenu fait foi.
  ws_url_override text,
  -- Duree de validite du jeton. Courte par principe : un jeton vole ne vaut
  -- que le temps d'un debut de seance.
  token_ttl_seconds int not null default 900
    check (token_ttl_seconds between 60 and 21600),
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

insert into public.video_config (id) values (true);

comment on table public.video_config is
  'Aiguillage video, une seule ligne. Modifiable par l''administration seule, lue par la cle de service.';

-- L'ancre : quel serveur sert cette seance, decide une fois pour toutes.
create table public.session_video_route (
  session_id uuid primary key references public.sessions(id) on delete cascade,
  provider public.video_provider not null,
  -- L'URL reellement servie, figee elle aussi. Si l'administration change
  -- `ws_url_override` pendant une seance, les participants deja routes
  -- gardent leur serveur : couper une salle en deux serait pire que servir
  -- l'ancienne adresse quelques minutes de plus.
  ws_url text not null,
  -- Le nom de salle LiveKit. Opaque, conformement a la section 10 de la
  -- specification : aucune donnee personnelle dans un nom de room.
  room_name text not null unique,
  decide_le timestamptz not null default now()
);

comment on table public.session_video_route is
  'Le fournisseur et la salle d''une seance, figes a la premiere emission de jeton.';

-- ============================================================
-- 2. La trace d'emission (section 6.3 : ce qui rend `en_connexion` derivable)
-- ============================================================

create table public.video_token_grants (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.sessions(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.participant_role not null,
  provider public.video_provider not null,
  -- Les capacites reellement inscrites dans le jeton, telles quelles. Ce
  -- n'est pas decoratif : c'est la seule facon de repondre plus tard a
  -- « qui a pu publier de la video dans cette salle, et quand ».
  can_publish boolean not null,
  can_publish_video boolean not null,
  can_publish_data boolean not null,
  hidden boolean not null default false,
  emis_le timestamptz not null default now(),
  expire_le timestamptz not null,
  constraint video_token_grants_duree_ok check (expire_le > emis_le)
);

-- La derivation de `en_connexion` lit la derniere emission d'un participant
-- dans une seance : cet index la sert exactement.
create index video_token_grants_dernier_ix
  on public.video_token_grants (session_id, profile_id, emis_le desc);

comment on table public.video_token_grants is
  'Chaque jeton video emis. Append-only : c''est une trace d''autorisation, pas un etat.';

-- ============================================================
-- 3. L'idempotence des webhooks (specification section 29)
-- ============================================================

create table public.livekit_webhook_deliveries (
  -- L'identifiant que LiveKit attribue a l'evenement. C'est lui, et lui seul,
  -- qui distingue un rejeu d'un fait nouveau.
  event_id text primary key,
  event_type text not null,
  room_name text,
  recu_le timestamptz not null default now(),
  -- Vrai quand la livraison a produit une ecriture. Un rejeu reste a faux et
  -- se lit comme tel dans le journal d'exploitation.
  applique boolean not null default false,
  detail jsonb not null default '{}'::jsonb
);

create index livekit_webhook_deliveries_recu_ix
  on public.livekit_webhook_deliveries (recu_le desc);

comment on table public.livekit_webhook_deliveries is
  'Journal de reception des webhooks LiveKit. La cle primaire fait l''idempotence.';

-- ============================================================
-- 4. Les seuils, reglables sans redeploiement (section 6.3)
-- ============================================================

-- Combien de temps un jeton emis sans entree constatee vaut « en connexion »
-- plutot que « en attente ». Au-dela, la tentative a echoue et l'ecran doit le
-- dire. Valeur de depart a mesurer contre le vrai comportement des webhooks,
-- exactement comme les deux seuils poses par N1.
insert into public.app_config (key, value) values
  ('presence.fenetre_connexion_secondes', '90'::jsonb)
on conflict (key) do nothing;

-- ============================================================
-- 5. L'aiguillage, appele par la fonction Edge a chaque emission
-- ============================================================

-- Rend le fournisseur et la salle d'une seance, en les decidant si c'est la
-- premiere emission. Deterministe : le tirage du canari depend du `session_id`
-- et non du hasard, donc deux appels concurrents choisissent la meme chose
-- avant meme que l'unicite ne tranche.
create or replace function public.video_route_de_seance(
  p_session_id uuid,
  p_ws_url_cloud text,
  p_ws_url_self_hosted text
) returns table (provider public.video_provider, ws_url text, room_name text)
language plpgsql volatile security definer set search_path = ''
as $$
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
$$;

-- ============================================================
-- 6. L'emission : autorisation, capacites, trace
-- ============================================================

-- Le coeur du lot. Appelee par `create-room-token` avec la cle de service,
-- elle reverifie tout ce que la fonction Edge ne doit pas se contenter de
-- croire, calcule les capacites, ecrit la trace, et rend a la fonction Edge
-- de quoi signer un jeton -- mais ne signe rien : la cle LiveKit ne descend
-- jamais dans la base.
create or replace function public.autoriser_jeton_video(
  p_session_id uuid,
  p_profile_id uuid,
  p_ws_url_cloud text,
  p_ws_url_self_hosted text
) returns jsonb
language plpgsql volatile security definer set search_path = ''
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
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    raise exception 'seance introuvable' using errcode = 'no_data_found';
  end if;

  -- Une seance close ne rouvre pas. C'est ce qui empeche un jeton d'etre
  -- reclame apres coup pour fabriquer une presence.
  if v_seance.status in ('ended', 'canceled', 'canceled_late') then
    raise exception 'seance close' using errcode = 'check_violation';
  end if;

  -- L'appartenance : lue dans `session_participants`, jamais recue en
  -- parametre. C'est elle qui repond a « a-t-il le droit d'etre dans CETTE
  -- salle », et le role qu'elle porte decide de tout le reste.
  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;
  if not found then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  -- La fenetre d'ouverture (ADR-005) : dix minutes avant le debut, et jusqu'a
  -- la fin annoncee majoree d'un quart d'heure pour absorber les depassements.
  if now() < v_seance.started_at - interval '10 minutes' then
    raise exception 'salle pas encore ouverte' using errcode = 'check_violation';
  end if;
  if now() > v_seance.ended_at + interval '15 minutes' then
    raise exception 'salle fermee' using errcode = 'check_violation';
  end if;

  select * into v_route from public.video_route_de_seance(
    p_session_id, p_ws_url_cloud, p_ws_url_self_hosted
  );

  select vc.token_ttl_seconds into v_ttl from public.video_config vc where vc.id;
  v_expire := now() + make_interval(secs => v_ttl);

  -- Les capacites. Elles se deduisent du role et de la politique camera, et
  -- d'absolument rien que le client ait envoye.
  v_invisible     := (v_role = 'masked_controller');
  v_publier       := v_role in ('teacher', 'student');
  v_publier_data  := (v_role = 'teacher');
  v_publier_video := false;

  if v_role = 'teacher' then
    v_publier_video := true;
  elsif v_role = 'student' then
    select sp.camera_policy into v_camera
      from public.student_profiles sp
     where sp.profile_id = p_profile_id;
    -- Defaut `forbidden` cote table, et defaut `forbidden` ici aussi quand
    -- aucune fiche eleve n'existe : l'absence d'information ne vaut pas
    -- autorisation.
    v_publier_video := (coalesce(v_camera, 'forbidden') = 'allowed');
  end if;

  insert into public.video_token_grants (
    session_id, profile_id, role, provider,
    can_publish, can_publish_video, can_publish_data, hidden, expire_le
  ) values (
    p_session_id, p_profile_id, v_role, v_route.provider,
    v_publier, v_publier_video, v_publier_data, v_invisible, v_expire
  );

  -- Une entree en salle est un acces sensible : elle se journalise comme les
  -- autres, dans la chaine que `ADM-04` sait relire.
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
    'identity', p_profile_id::text,
    'role', v_role,
    'ttl_seconds', v_ttl,
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

-- ============================================================
-- 7. La reception d'un webhook, idempotente
-- ============================================================

-- Rend vrai quand la livraison etait nouvelle et a ete appliquee, faux quand
-- c'etait un rejeu. La fonction Edge repond 200 dans les deux cas : un
-- webhook qui recoit une erreur est reessaye, et reessayer un doublon ne le
-- rend pas moins doublon.
create or replace function public.enregistrer_webhook_livekit(
  p_event_id text,
  p_event_type text,
  p_room_name text,
  p_profile_id uuid,
  p_server_ts timestamptz,
  p_detail jsonb default '{}'::jsonb
) returns boolean
language plpgsql volatile security definer set search_path = ''
as $$
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
$$;

-- Le geste volontaire de sortie, ecrit par le client AVANT de se deconnecter.
-- C'est la seule ecriture de presence que le produit confie a l'utilisateur,
-- et elle ne peut rien affirmer d'autre que « je pars » : ni entrer, ni
-- entrer a la place d'un autre.
create or replace function public.quitter_salle(p_session_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not public.session_has_participant(p_session_id, auth.uid()) then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;

  insert into public.session_events (session_id, profile_id, event_type, source)
  values (p_session_id, auth.uid(), 'left', 'user_action');
end;
$$;

-- ============================================================
-- 8. `etat_presence()` : la branche que N1 avait laissee vide
-- ============================================================

-- Reecrite a l'identique de 0007, a une seule branche pres, marquee ci-dessous.
-- Le reste du corps n'est pas retouche : la non-regression des quatorze etats
-- se verifie par les quinze controles de N1, rejoues tels quels.
create or replace function public.etat_presence(
  p_session_id uuid,
  p_profile_id uuid
) returns public.presence_state
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_seance         public.sessions%rowtype;
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
begin
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
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

  -- Jamais vu entrer.
  if v_premier_joined is null then
    if v_seance.status in ('ended', 'teacher_absent', 'student_absent') then
      return 'absente';
    end if;

    -- >>> La branche de N2, et la seule difference avec 0007. <<<
    -- Un jeton vient d'etre emis et aucune entree n'est encore constatee :
    -- la connexion LiveKit est en cours. Passe la fenetre, la tentative a
    -- echoue et l'etat retombe sur l'attente -- l'ecran ne doit pas afficher
    -- « en connexion » indefiniment devant quelqu'un qui n'arrivera pas.
    select max(g.emis_le) into v_jeton_le
      from public.video_token_grants g
     where g.session_id = p_session_id
       and g.profile_id = p_profile_id;

    if v_jeton_le is not null
       and now() - v_jeton_le <= make_interval(secs => v_fenetre_conn) then
      return 'en_connexion';
    end if;
    -- >>> Fin de la branche de N2. <<<

    if now() < v_seance.started_at - interval '10 minutes' then
      return 'planifiee';
    end if;
    return 'en_attente';
  end if;

  -- Sorti : le vocabulaire de `source` tranche entre geste et panne.
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

-- ============================================================
-- 9. Lecture de la configuration par l'administration
-- ============================================================

create or replace function public.video_config_lire()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_config public.video_config%rowtype;
begin
  if public.app_role() <> 'admin' then
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
$$;

-- ============================================================
-- 10. RLS : tout est ferme, rien ne s'ecrit depuis le client
-- ============================================================

alter table public.video_config enable row level security;
alter table public.session_video_route enable row level security;
alter table public.video_token_grants enable row level security;
alter table public.livekit_webhook_deliveries enable row level security;

-- Aucune policy permissive n'est creee pour `video_config`,
-- `session_video_route` ni `livekit_webhook_deliveries` : RLS active sans
-- policy signifie « personne, sauf la cle de service ». C'est voulu, et c'est
-- le comportement le plus sur pour des tables qui decident d'un acces media.

-- Un participant peut savoir qu'un jeton lui a ete emis -- c'est sa propre
-- trace, et l'ecran de salle s'en sert pour distinguer « je me connecte » de
-- « j'attends ». Il ne voit jamais celle des autres.
create policy video_token_grants_self_read on public.video_token_grants
  for select to authenticated
  using (profile_id = auth.uid());

-- L'administration lit tout, en lecture seule comme partout ailleurs.
create policy video_token_grants_admin_read on public.video_token_grants
  for select to authenticated
  using (public.app_role() = 'admin');

-- ============================================================
-- 11. Droits d'execution
-- ============================================================

-- Les deux fonctions qui decident d'un acces media ne sont jamais appelables
-- depuis un navigateur : seule la cle de service les atteint, depuis les
-- fonctions Edge, apres avoir verifie le porteur du jeton Supabase.
revoke execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  from anon, authenticated, public;

grant execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  to service_role;

-- Le geste de sortie, lui, appartient a l'utilisateur.
revoke execute on function public.quitter_salle(uuid) from anon, public;
grant execute on function public.quitter_salle(uuid) to authenticated;

revoke execute on function public.video_config_lire() from anon, public;
grant execute on function public.video_config_lire() to authenticated;
