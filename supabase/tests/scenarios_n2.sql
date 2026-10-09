-- Scenarios d'acceptation SQL de `N2`, la video : aiguillage, emission de
-- jeton, webhooks, et l'etat `en_connexion`.
-- Chaque scenario echoue bruyamment ou n'ecrit rien : aucun ne se contente
-- d'un « pas d'erreur ».
--
-- Se rejoue sur un Postgres nu, apres stub_auth.sql et les migrations 0001 a
-- 0010. Un fichier de scenarios ne se rejoue jamais deux fois sur la meme
-- base : il insere ses fixtures.
--
-- Ce fichier doit rester AVANT `scenarios_adm04.sql` dans `ci.yml` : le
-- controle J4 de ce dernier verifie l'integrite de tout ce que les fichiers
-- precedents ont ecrit, et l'emission d'un jeton ecrit dans `audit_logs`.

-- Droits facon Supabase (alter default privileges du projet).
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to authenticated, service_role;
grant all on all sequences in schema public to authenticated, service_role;
grant all on all functions in schema public to service_role;

-- Le grant ci-dessus vient d'annuler la restriction que 0010 pose sur les
-- fonctions d'emission. En production l'ordre est inverse : les droits par
-- defaut sont accordes a la creation, la migration les restreint ensuite. On
-- rejoue donc la restriction, sans quoi le controle N7 mesurerait le harnais
-- et non la migration.
revoke execute on function
  public.autoriser_jeton_video(uuid, uuid, text, text),
  public.video_route_de_seance(uuid, text, text),
  public.enregistrer_webhook_livekit(text, text, text, uuid, timestamptz, jsonb)
  from anon, authenticated, public;

-- ============================================================
-- Fixtures : une seance, un enseignant, deux eleves, un controleur
-- ============================================================
--
--   * Bilal enseigne : il publie voix ET image, et lui seul diffuse des
--     donnees (c'est lui qui presentera le Coran).
--   * Nour a `camera_policy = 'allowed'` : elle publie son image.
--   * Idriss garde le defaut `forbidden` : il publie sa voix, jamais son
--     image, quoi qu'affiche son ecran. C'est lui qui mesure le choix 3.
--   * Khadija observe en `masked_controller` : invisible, muette.
--   * Salim n'est inscrit a rien : c'est lui qui mesure le refus.

insert into auth.users (id, email) values
  ('b2000000-0000-0000-0000-000000000001', 'bilal@example.test'),
  ('b2000000-0000-0000-0000-000000000002', 'nour@example.test'),
  ('b2000000-0000-0000-0000-000000000003', 'idriss@example.test'),
  ('b2000000-0000-0000-0000-000000000004', 'khadija@example.test'),
  ('b2000000-0000-0000-0000-000000000005', 'salim@example.test');

insert into public.households (id, timezone) values
  ('b2ffffff-0000-0000-0000-00000000000a', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('b2000000-0000-0000-0000-000000000001', 'TEACH-N2-000001', 'teacher',
   'b2ffffff-0000-0000-0000-00000000000a', 'Bilal', 'Ndiaye', 'active', 'male'),
  ('b2000000-0000-0000-0000-000000000002', 'STUD-N2-000001', 'student',
   'b2ffffff-0000-0000-0000-00000000000a', 'Nour', 'Ndiaye', 'active', 'female'),
  ('b2000000-0000-0000-0000-000000000003', 'STUD-N2-000002', 'student',
   'b2ffffff-0000-0000-0000-00000000000a', 'Idriss', 'Ndiaye', 'active', 'male'),
  ('b2000000-0000-0000-0000-000000000004', 'CTRL-N2-000001', 'controller',
   'b2ffffff-0000-0000-0000-00000000000a', 'Khadija', 'Ba', 'active', 'female'),
  ('b2000000-0000-0000-0000-000000000005', 'STUD-N2-000003', 'student',
   'b2ffffff-0000-0000-0000-00000000000a', 'Salim', 'Ba', 'active', 'male');

insert into public.student_profiles (profile_id, student_type, interface_mode, camera_policy)
values
  ('b2000000-0000-0000-0000-000000000002', 'minor', 'standard', 'allowed'),
  ('b2000000-0000-0000-0000-000000000003', 'minor', 'standard', 'forbidden');

-- Le MVP-0 plafonne une seance a deux participants (guard_session_participant_cap,
-- 0001). La salle de N2 doit pourtant savoir accueillir un enseignant, deux
-- eleves et un controleur invisible. On memorise la configuration exacte
-- pour restaurer l'etat partage, y compris une cle absente.
create temporary table n2_allow_multi_snapshot as
select value from public.app_config
where key = 'allow_multi_participant_sessions';

update public.app_config set value = 'true'::jsonb
 where key = 'allow_multi_participant_sessions';
insert into public.app_config (key, value)
select 'allow_multi_participant_sessions', 'true'::jsonb
 where not exists (select 1 from public.app_config
                    where key = 'allow_multi_participant_sessions');

-- La seance est EN COURS : commencee il y a cinq minutes, finit dans
-- cinquante-cinq. La fenetre d'emission est donc ouverte.
insert into public.sessions (id, teacher_id, started_at, ended_at, status)
values
  ('b2aaaaaa-0000-0000-0000-00000000000a',
   'b2000000-0000-0000-0000-000000000001',
   now() - interval '5 minutes', now() + interval '55 minutes', 'in_progress'),
  -- Une seconde seance, plus tard, pour le controle de fenetre.
  ('b2aaaaaa-0000-0000-0000-00000000000b',
   'b2000000-0000-0000-0000-000000000001',
   now() + interval '3 hours', now() + interval '4 hours', 'planned'),
  -- Une troisieme, close.
  ('b2aaaaaa-0000-0000-0000-00000000000c',
   'b2000000-0000-0000-0000-000000000001',
   now() - interval '3 hours', now() - interval '2 hours', 'ended');

insert into public.session_participants (session_id, profile_id, role) values
  ('b2aaaaaa-0000-0000-0000-00000000000a', 'b2000000-0000-0000-0000-000000000001', 'teacher'),
  ('b2aaaaaa-0000-0000-0000-00000000000a', 'b2000000-0000-0000-0000-000000000002', 'student'),
  ('b2aaaaaa-0000-0000-0000-00000000000a', 'b2000000-0000-0000-0000-000000000003', 'student'),
  ('b2aaaaaa-0000-0000-0000-00000000000a', 'b2000000-0000-0000-0000-000000000004', 'masked_controller'),
  ('b2aaaaaa-0000-0000-0000-00000000000b', 'b2000000-0000-0000-0000-000000000001', 'teacher'),
  ('b2aaaaaa-0000-0000-0000-00000000000b', 'b2000000-0000-0000-0000-000000000002', 'student'),
  ('b2aaaaaa-0000-0000-0000-00000000000c', 'b2000000-0000-0000-0000-000000000001', 'teacher'),
  ('b2aaaaaa-0000-0000-0000-00000000000c', 'b2000000-0000-0000-0000-000000000002', 'student');

-- ============================================================
-- N1 : la route est figee a la premiere emission, et ne retombe jamais
--      deux participants d'une meme seance sur deux serveurs differents
-- ============================================================

do $$
declare
  v_a jsonb;
  v_b jsonb;
  v_routes int;
begin
  -- autoriser_jeton_video (0042) valide le compte de l'appelant avant
  -- d'émettre le jeton. Le scénario représente successivement chaque profil.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000001', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"teacher","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  set local role service_role;

  v_a := public.autoriser_jeton_video(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000001',
    'wss://cloud.example', 'wss://self.example');

  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  v_b := public.autoriser_jeton_video(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000002',
    'wss://cloud.example', 'wss://self.example');

  if v_a ->> 'ws_url' is distinct from v_b ->> 'ws_url' then
    raise exception 'N1 ECHEC : enseignant sur %, eleve sur % -- salle coupee en deux',
      v_a ->> 'ws_url', v_b ->> 'ws_url';
  end if;
  if v_a ->> 'room_name' is distinct from v_b ->> 'room_name' then
    raise exception 'N1 ECHEC : deux noms de salle pour une seule seance';
  end if;

  select count(*) into v_routes from public.session_video_route
   where session_id = 'b2aaaaaa-0000-0000-0000-00000000000a';
  if v_routes <> 1 then
    raise exception 'N1 ECHEC : % routes pour une seance', v_routes;
  end if;

  -- Le nom de salle ne doit rien reveler (specification section 10).
  if v_a ->> 'room_name' like '%b2aaaaaa%' then
    raise exception 'N1 ECHEC : le nom de salle contient l''identifiant de seance';
  end if;
end $$;

-- ============================================================
-- N2 : changer la configuration APRES le premier jeton ne deplace pas
--      une seance deja routee
-- ============================================================

do $$
declare
  v_avant text;
  v_apres text;
begin
  set local role service_role;

  select ws_url into v_avant from public.session_video_route
   where session_id = 'b2aaaaaa-0000-0000-0000-00000000000a';

  update public.video_config
     set active_provider = 'self_hosted', ws_url_override = 'wss://ailleurs.example'
   where id;

  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  perform public.autoriser_jeton_video(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000003',
    'wss://cloud.example', 'wss://self.example');

  select ws_url into v_apres from public.session_video_route
   where session_id = 'b2aaaaaa-0000-0000-0000-00000000000a';

  if v_avant is distinct from v_apres then
    raise exception 'N2 ECHEC : la seance a change de serveur en cours de route, % -> %',
      v_avant, v_apres;
  end if;

  -- On remet la configuration d'origine pour la suite.
  update public.video_config
     set active_provider = 'cloud', ws_url_override = null
   where id;
end $$;

-- ============================================================
-- N3 : le canari est deterministe, et il aiguille reellement
-- ============================================================

do $$
declare
  v_p1 public.video_provider;
  v_p2 public.video_provider;
  v_cloud int := 0;
  v_self  int := 0;
  v_id uuid;
  v_r record;
begin
  set local role service_role;

  -- A 100 %, tout part sur le canari ; a 0 %, rien. C'est la seule facon de
  -- prouver que le pourcentage est lu et pas ignore.
  update public.video_config
     set canary_provider = 'self_hosted', canary_percentage = 100 where id;
  select provider into v_p1 from public.video_route_de_seance(
    'b2aaaaaa-0000-0000-0000-00000000000b', 'wss://cloud.example', 'wss://self.example');
  if v_p1 <> 'self_hosted' then
    raise exception 'N3 ECHEC : canari a 100 %% et fournisseur %', v_p1;
  end if;

  -- Le meme appel rend la meme chose : la route est ancree.
  select provider into v_p2 from public.video_route_de_seance(
    'b2aaaaaa-0000-0000-0000-00000000000b', 'wss://cloud.example', 'wss://self.example');
  if v_p1 <> v_p2 then
    raise exception 'N3 ECHEC : deux appels, deux fournisseurs (% puis %)', v_p1, v_p2;
  end if;

  -- La repartition sur cent seances neuves doit approcher le pourcentage
  -- demande. Un tirage constant passerait N3 sans cela.
  update public.video_config
     set canary_provider = 'self_hosted', canary_percentage = 50 where id;
  -- Chaque seance est decalee d'un jour : `sessions_no_teacher_overlap`
  -- interdit a un enseignant deux seances qui se chevauchent, et ce n'est pas
  -- ce controle-ci qui doit la mesurer.
  for i in 1..100 loop
    v_id := gen_random_uuid();
    insert into public.sessions (id, teacher_id, started_at, ended_at, status)
    values (v_id, 'b2000000-0000-0000-0000-000000000001',
            now() + make_interval(days => i + 7),
            now() + make_interval(days => i + 7) + interval '30 minutes',
            'planned');
    select * into v_r from public.video_route_de_seance(
      v_id, 'wss://cloud.example', 'wss://self.example');
    if v_r.provider = 'cloud' then v_cloud := v_cloud + 1; else v_self := v_self + 1; end if;
  end loop;

  if v_cloud < 25 or v_self < 25 then
    raise exception 'N3 ECHEC : repartition 50/50 attendue, lue % cloud et % self', v_cloud, v_self;
  end if;

  -- Les cent seances de mesure ne doivent pas survivre au controle : les
  -- fichiers de scenarios partagent une base, et laisser cent seances
  -- fantomes fausserait tout comptage ulterieur.
  delete from public.sessions
   where teacher_id = 'b2000000-0000-0000-0000-000000000001'
     and started_at > now() + interval '7 days';

  update public.video_config
     set canary_provider = null, canary_percentage = 0 where id;
end $$;

-- ============================================================
-- N4 : les capacites se deduisent du role et de la politique camera,
--      jamais de ce que le client pretend
-- ============================================================

do $$
declare
  v_ens jsonb;
  v_nour jsonb;
  v_idriss jsonb;
  v_ctrl jsonb;
begin
  set local role service_role;

  select to_jsonb(g) into v_ens from public.video_token_grants g
   where g.session_id = 'b2aaaaaa-0000-0000-0000-00000000000a'
     and g.profile_id = 'b2000000-0000-0000-0000-000000000001'
   order by g.emis_le desc limit 1;

  if not (v_ens ->> 'can_publish_video')::boolean
     or not (v_ens ->> 'can_publish_data')::boolean then
    raise exception 'N4 ECHEC : l''enseignant doit publier image et donnees, lu %', v_ens;
  end if;

  select to_jsonb(g) into v_nour from public.video_token_grants g
   where g.profile_id = 'b2000000-0000-0000-0000-000000000002'
   order by g.emis_le desc limit 1;
  if not (v_nour ->> 'can_publish_video')::boolean then
    raise exception 'N4 ECHEC : camera_policy allowed et pourtant image refusee';
  end if;

  select to_jsonb(g) into v_idriss from public.video_token_grants g
   where g.profile_id = 'b2000000-0000-0000-0000-000000000003'
   order by g.emis_le desc limit 1;
  if (v_idriss ->> 'can_publish_video')::boolean then
    raise exception 'N4 ECHEC : camera_policy forbidden et pourtant image autorisee';
  end if;
  if not (v_idriss ->> 'can_publish')::boolean then
    raise exception 'N4 ECHEC : un eleve sans camera doit garder la voix';
  end if;
  if (v_idriss ->> 'can_publish_data')::boolean then
    raise exception 'N4 ECHEC : un eleve ne diffuse pas de donnees';
  end if;

  -- Le controleur : invisible et muet, decide en base et non par une case.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000004', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"controller","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  v_ctrl := public.autoriser_jeton_video(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000004',
    'wss://cloud.example', 'wss://self.example');
  if not (v_ctrl -> 'capabilities' ->> 'hidden')::boolean then
    raise exception 'N4 ECHEC : CTR-02 exige un controleur invisible';
  end if;
  if (v_ctrl -> 'capabilities' ->> 'can_publish')::boolean then
    raise exception 'N4 ECHEC : un controleur ne publie rien';
  end if;
end $$;

-- ============================================================
-- N5 : ce qui doit etre refuse l'est -- non-inscrit, hors fenetre, close
-- ============================================================

do $$
declare
  v_ok boolean;
begin
  set local role service_role;

  -- Non inscrit : compte actif, mais absent de la seance.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000005', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  v_ok := false;
  begin
    perform public.autoriser_jeton_video(
      'b2aaaaaa-0000-0000-0000-00000000000a',
      'b2000000-0000-0000-0000-000000000005',
      'wss://cloud.example', 'wss://self.example');
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'N5 ECHEC : un non-inscrit a obtenu un jeton pour la salle';
  end if;

  -- Trop tot : compte inscrit actif, mais avant l'ouverture T-10.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  v_ok := false;
  begin
    perform public.autoriser_jeton_video(
      'b2aaaaaa-0000-0000-0000-00000000000b',
      'b2000000-0000-0000-0000-000000000002',
      'wss://cloud.example', 'wss://self.example');
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'N5 ECHEC : jeton emis trois heures avant le debut';
  end if;

  -- Seance close : le meme compte inscrit est toujours valide.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  v_ok := false;
  begin
    perform public.autoriser_jeton_video(
      'b2aaaaaa-0000-0000-0000-00000000000c',
      'b2000000-0000-0000-0000-000000000002',
      'wss://cloud.example', 'wss://self.example');
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'N5 ECHEC : jeton emis pour une seance terminee';
  end if;
end $$;

-- ============================================================
-- N6 : `en_connexion` -- l'etat que N1 refusait de deviner
-- ============================================================

do $$
declare
  v_etat public.presence_state;
begin
  -- etat_presence revalide l'appelant depuis 0042, même pour ce test
  -- exécuté sous service_role : on représente ici le compte actif de l'élève.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  set local role service_role;

  -- Un jeton vient d'etre emis pour Nour, et aucun `joined` n'est arrive.
  v_etat := public.etat_presence(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000002');
  if v_etat <> 'en_connexion' then
    raise exception 'N6 ECHEC : jeton emis, aucune entree, attendu en_connexion, lu %', v_etat;
  end if;

  -- Passe la fenetre, la tentative a echoue : l'ecran ne doit pas afficher
  -- « en connexion » indefiniment. On vieillit la trace plutot que d'attendre.
  update public.video_token_grants
     set emis_le = now() - interval '10 minutes'
   where profile_id = 'b2000000-0000-0000-0000-000000000002';

  v_etat := public.etat_presence(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000002');
  if v_etat <> 'en_attente' then
    raise exception 'N6 ECHEC : fenetre de connexion depassee, attendu en_attente, lu %', v_etat;
  end if;
end $$;

-- ============================================================
-- N7 : le webhook est idempotent, et il fait entrer
-- ============================================================

do $$
declare
  v_premier boolean;
  v_rejeu   boolean;
  v_lignes  int;
  v_etat    public.presence_state;
  v_room    text;
begin
  -- Le webhook et le calcul d'état sont évalués pour le compte actif concerné.
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt',
    '{"app_metadata":{"role":"student","household_id":"b2ffffff-0000-0000-0000-00000000000a"}}',
    true);
  set local role service_role;

  select room_name into v_room from public.session_video_route
   where session_id = 'b2aaaaaa-0000-0000-0000-00000000000a';

  -- L'horodatage est celui que LiveKit porte, pas celui de la reception : Nour
  -- est entree une minute apres le debut, donc dans les temps. Poser `now()`
  -- ici la rendrait `en_retard` -- correctement, la seance ayant commence il y
  -- a cinq minutes -- et ce n'est pas ce que ce controle mesure.
  v_premier := public.enregistrer_webhook_livekit(
    'evt_n2_0001', 'participant_joined', v_room,
    'b2000000-0000-0000-0000-000000000002', now() - interval '4 minutes', '{}'::jsonb);
  if not v_premier then
    raise exception 'N7 ECHEC : la premiere livraison devait etre appliquee';
  end if;

  -- Exactement le meme evenement, renvoye par LiveKit comme il le fait.
  v_rejeu := public.enregistrer_webhook_livekit(
    'evt_n2_0001', 'participant_joined', v_room,
    'b2000000-0000-0000-0000-000000000002', now() - interval '4 minutes', '{}'::jsonb);
  if v_rejeu then
    raise exception 'N7 ECHEC : un rejeu a ete applique une seconde fois';
  end if;

  select count(*) into v_lignes from public.session_events
   where session_id = 'b2aaaaaa-0000-0000-0000-00000000000a'
     and profile_id = 'b2000000-0000-0000-0000-000000000002'
     and event_type = 'joined';
  if v_lignes <> 1 then
    raise exception 'N7 ECHEC : % entrees ecrites pour une seule arrivee', v_lignes;
  end if;

  v_etat := public.etat_presence(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000002');
  if v_etat <> 'presente' then
    raise exception 'N7 ECHEC : entree constatee, attendu presente, lu %', v_etat;
  end if;

  -- Une salle que personne ne connait n'ecrit aucune presence.
  if public.enregistrer_webhook_livekit(
       'evt_n2_0002', 'participant_joined', 'r_inconnue',
       'b2000000-0000-0000-0000-000000000003', now(), '{}'::jsonb) then
    raise exception 'N7 ECHEC : un webhook sur salle inconnue a ecrit une presence';
  end if;
  -- Mais elle est bien tracee pour l'exploitation.
  if not exists (select 1 from public.livekit_webhook_deliveries where event_id = 'evt_n2_0002') then
    raise exception 'N7 ECHEC : la livraison inconnue n''a pas ete journalisee';
  end if;
end $$;

-- ============================================================
-- N8 : sortie volontaire contre perte reseau -- la distinction tient
-- ============================================================

do $$
declare
  v_etat public.presence_state;
  v_room text;
begin
  select room_name into v_room from public.session_video_route
   where session_id = 'b2aaaaaa-0000-0000-0000-00000000000a';

  -- Nour presse le bouton de sortie.
  set local role authenticated;
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000002', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);
  perform public.quitter_salle('b2aaaaaa-0000-0000-0000-00000000000a');

  set local role service_role;
  v_etat := public.etat_presence(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000002');
  if v_etat <> 'sortie' then
    raise exception 'N8 ECHEC : bouton de sortie presse, attendu sortie, lu %', v_etat;
  end if;

  -- Le webhook `participant_left` arrive juste apres, comme toujours. Il ne
  -- doit PAS transformer un depart propre en deconnexion subie.
  perform public.enregistrer_webhook_livekit(
    'evt_n2_0003', 'participant_left', v_room,
    'b2000000-0000-0000-0000-000000000002', now(), '{}'::jsonb);

  v_etat := public.etat_presence(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000002');
  if v_etat <> 'sortie' then
    raise exception 'N8 ECHEC : le webhook a ecrase une sortie volontaire, lu %', v_etat;
  end if;

  -- Idriss, lui, tombe du reseau : meme evenement LiveKit, sans geste
  -- prealable. La fenetre de reconnexion s'ouvre.
  perform public.enregistrer_webhook_livekit(
    'evt_n2_0004', 'participant_joined', v_room,
    'b2000000-0000-0000-0000-000000000003', now() - interval '3 minutes', '{}'::jsonb);
  perform public.enregistrer_webhook_livekit(
    'evt_n2_0005', 'participant_left', v_room,
    'b2000000-0000-0000-0000-000000000003', now(), '{}'::jsonb);

  v_etat := public.etat_presence(
    'b2aaaaaa-0000-0000-0000-00000000000a',
    'b2000000-0000-0000-0000-000000000003');
  if v_etat <> 'en_reconnexion' then
    raise exception 'N8 ECHEC : perte reseau, attendu en_reconnexion, lu %', v_etat;
  end if;
end $$;

-- ============================================================
-- N9 : rien ne s'ecrit ni ne se lit depuis un navigateur
-- ============================================================

do $$
declare
  v_ok boolean;
  v_vu int;
begin
  set local role authenticated;
  perform set_config('test.uid', 'b2000000-0000-0000-0000-000000000003', true);
  perform set_config('test.jwt', '{"app_metadata":{"role":"student"}}', true);

  -- Un eleve ne fabrique pas son propre jeton.
  v_ok := false;
  begin
    perform public.autoriser_jeton_video(
      'b2aaaaaa-0000-0000-0000-00000000000a',
      'b2000000-0000-0000-0000-000000000003',
      'wss://cloud.example', 'wss://self.example');
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'N9 ECHEC : un eleve a pu emettre son propre jeton video';
  end if;

  -- Ni ne raconte au serveur qu'il vient d'arriver.
  v_ok := false;
  begin
    perform public.enregistrer_webhook_livekit(
      'evt_n2_forge', 'participant_joined', 'r_x',
      'b2000000-0000-0000-0000-000000000003', now(), '{}'::jsonb);
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'N9 ECHEC : un eleve a pu forger un webhook de presence';
  end if;

  -- Il voit sa propre trace d'emission, et elle seule.
  select count(*) into v_vu from public.video_token_grants;
  if v_vu = 0 then
    raise exception 'N9 ECHEC : un participant doit voir sa propre trace';
  end if;
  if exists (select 1 from public.video_token_grants
              where profile_id <> 'b2000000-0000-0000-0000-000000000003') then
    raise exception 'N9 ECHEC : un eleve voit les traces des autres participants';
  end if;

  -- La configuration video reste fermee.
  v_ok := false;
  begin
    perform public.video_config_lire();
  exception when others then v_ok := true;
  end;
  if not v_ok then
    raise exception 'N9 ECHEC : un eleve a lu la configuration video';
  end if;
end $$;

-- ============================================================
-- N10 : chaque entree en salle laisse une trace dans le journal d'audit
-- ============================================================

do $$
declare
  v_entrees int;
begin
  set local role service_role;
  select count(*) into v_entrees from public.audit_logs
   where action = 'video_token_issued'
     and row_id = 'b2aaaaaa-0000-0000-0000-00000000000a';
  if v_entrees < 4 then
    raise exception 'N10 ECHEC : % entrees de journal pour quatre emissions au moins', v_entrees;
  end if;

  -- Le journal doit dire QUI, avec quel role, sur quel fournisseur : une
  -- ligne qui ne porte pas cela ne sert a rien le jour ou on la lit.
  if exists (
    select 1 from public.audit_logs
     where action = 'video_token_issued'
       and (payload ->> 'profile_id' is null or payload ->> 'role' is null
            or payload ->> 'provider' is null)
  ) then
    raise exception 'N10 ECHEC : une entree de journal sans acteur, role ou fournisseur';
  end if;
end $$;

-- Restaurer exactement la valeur precedente. Si la cle n'existait pas,
-- retirer la ligne de fixture ajoutee au debut du fichier.
do $$
begin
  if exists (select 1 from pg_temp.n2_allow_multi_snapshot) then
    update public.app_config
       set value = (select value from pg_temp.n2_allow_multi_snapshot)
     where key = 'allow_multi_participant_sessions';
  else
    delete from public.app_config
     where key = 'allow_multi_participant_sessions';
  end if;
end $$;
drop table pg_temp.n2_allow_multi_snapshot;

do $$
begin
  raise notice 'N2 : dix controles verts.';
end $$;
