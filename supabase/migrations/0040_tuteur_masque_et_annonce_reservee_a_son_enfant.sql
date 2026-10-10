-- 0040_tuteur_masque_et_annonce_reservee_a_son_enfant.sql
-- Rend la regle de visibilite du 21/09 EXECUTABLE PAR LE SERVEUR.
--
-- LA REGLE, dictee par l'operateur, deja en specification 11.3 :
--   « Le tuteur est visible par son enfant et l'enseignant, les autres enfants
--   ne voient rien. Chacun voit son parent a lui quand il est en ligne. »
--
--   | Qui                        | Ce qu'il voit                                  |
--   |----------------------------|------------------------------------------------|
--   | L'enseignant               | un oeil + les tuteurs en observation           |
--   | L'enfant observe           | un oeil + une mention discrete                 |
--   | Les autres enfants         | RIEN -- ni galerie video, ni annonce           |
--
-- Le client disait deja vrai : capacites_observateur.dart pose
-- `visibleDesParticipants: false`. Le serveur, lui, ne suivait pas, aux deux
-- bouts a la fois. Cette migration ferme les deux.
--
-- ============================================================================
-- A. LE TUTEUR SORT DE LA GALERIE DES AUTRES ENFANTS
-- ============================================================================
--
-- LE DEFAUT, LU DANS LE CORPS DE LA FONCTION EN PRODUCTION :
--   v_invisible := (v_role in ('masked_controller', 'admin_masked'));
-- `guardian_observer` n'y figure pas, donc le jeton part avec `hidden = false`
-- et LiveKit place le tuteur dans la galerie de CHAQUE participant. Dans un
-- groupe de cinq, les quatre autres enfants le voient. C'est l'inverse exact de
-- la regle.
--
-- La fonction se contredisait elle-meme : son propre commentaire de capacites,
-- trois lignes plus haut, annonce « guardian_observer : rien ne se publie,
-- MASQUE, ttl borne par le budget ». La table etait juste, le code ne la suivait
-- pas.
--
-- MESURE AVANT, faite sur la base de production le 21/09, six roles inscrits a
-- une seance de mesure, `autoriser_jeton_video` REELLEMENT appelee (fixture
-- montee puis rejetee dans le meme bloc atomique, aucune ligne laissee) :
--   teacher            ttl=900  hidden=false publish=true  video=true  data=true
--   student            ttl=900  hidden=false publish=true  video=true  data=false
--   guardian_observer  ttl=120  hidden=FALSE publish=false video=false data=false   <-- le defaut
--   masked_controller  ttl=900  hidden=true  publish=false video=false data=false
--   admin_masked       ttl=900  hidden=true  publish=false video=false data=false
--   admin_visible      ttl=900  hidden=false publish=true  video=true  data=false
--
-- CE QUE CETTE MIGRATION CHANGE : UNE SEULE LIGNE de cette fonction. Le reste du
-- corps est recopie caractere pour caractere depuis `pg_get_functiondef` de la
-- version en production. C'est un point chaud traverse par SIX valeurs de role
-- et deja reecrit une fois par fusion de trois lots : la plus petite
-- modification est la seule qui ne risque rien pour les autres. Le controle de
-- sortie exige que les cinq autres roles gardent exactement leurs capacites.
--
-- ATTENDU APRES : seule la ligne `guardian_observer` bouge, `hidden` passant de
-- false a true ; les cinq autres rendent le meme ttl et les memes capacites.
--
-- DROITS. L'ACL reelle a ete LUE avant d'ecrire quoi que ce soit (`proacl`) :
--   postgres=X/postgres, service_role=X/postgres
-- et RIEN d'autre -- ni PUBLIC, ni anon, ni authenticated, ni agent_ro. Cette
-- fonction n'est donc PAS appelable depuis le client : elle passe par une
-- fonction de bord sous `service_role`. Les droits reposes ci-dessous sont
-- exactement ceux-la. Ecrire `grant ... to authenticated` par habitude aurait
-- ouvert l'emission de jetons video a tout compte connecte.
--
-- ============================================================================
-- B. L'ENFANT OBSERVE L'APPREND, ET LUI SEUL
-- ============================================================================
--
-- CE QUI MANQUAIT. Il n'existait aucune lecture serveur par laquelle un enfant
-- puisse apprendre que son parent regarde :
--   * `annonces_observation` (0033_tc_vues_rpc.sql) leve `insufficient_privilege`
--     pour tout appelant qui n'est pas `sessions.teacher_id` -- verifie dans le
--     corps en production ;
--   * la RLS de `guardian_session_visit` n'ouvre le SELECT qu'a
--     `observateur_profile_id = auth.uid()` (policy `guardian_visit_self`) ou a
--     `app_role() = 'admin'` (policy `guardian_visit_admin`) -- lues sur
--     `pg_policy`. L'enfant n'est ni l'un ni l'autre : il est le SUJET de la
--     ligne, jamais son observateur.
-- Brancher le temoin cote enfant sans cette migration aurait pose un voyant qui
-- ne s'allume jamais.
--
-- POURQUOI UNE RPC ET PAS UNE POLICY DE PLUS. Ouvrir `guardian_session_visit`
-- en SELECT a l'enfant concerne lui donnerait la LIGNE ENTIERE : l'identite de
-- l'observateur, le numero de visite, la version de politique, le compteur de
-- ses passages. La RLS borne les LIGNES, pas les COLONNES. L'enfant n'a besoin
-- que de deux faits -- « quelqu'un de mon foyer regarde » et « depuis quand » --
-- et c'est tout ce que cette fonction rend.
--
-- LE VERROU DE VIE PRIVEE. La requete porte `v.enfant_profile_id = auth.uid()`
-- dans son WHERE. Ce n'est pas un filtre d'affichage : c'est la seule ligne que
-- la fonction puisse atteindre. Un enfant ne peut donc pas apprendre que le
-- parent d'un autre enfant observe -- ni son nom, ni son existence, ni meme leur
-- NOMBRE. Le retour ne porte aucun compteur, volontairement : un « 1 observateur
-- dans la salle » renseignerait deja sur les autres foyers.
--
-- LA PORTE, EN EXIGENCE POSITIVE. `if not exists (...) then raise` et jamais
-- `if role <> 'x' then raise` : avec `auth.uid()` nul, la seconde forme ne se
-- declenche pas et ouvre la porte a `anon` (lecon de 0035 et des deux fuites
-- trouvees ainsi). L'appartenance exigee est celle au GROUPE de la seance, pas
-- l'inscription a `session_participants` : le lien de groupe est durable, ce qui
-- permet au temoin de s'allumer aussi bien dans la salle qu'ailleurs, sans rien
-- relacher -- le verrou de vie privee ne tient pas a la porte, il tient au
-- WHERE.
-- `m.student_id = auth.uid()` et non `est_du_foyer(m.student_id)` : le tuteur ne
-- passe pas cette porte. Il n'en a pas besoin, c'est lui l'observateur.
--
-- LA FONCTION EST `stable` : elle ne fait que lire. `agent_ro` n'apparait
-- neanmoins QUE dans le revoke. Elle lit sous `security definer` ce que
-- l'appelant a le droit de savoir de LUI ; un agent qui la lirait apprendrait
-- l'observation d'un foyer qui n'est pas le sien.

-- ============================================================================
-- A. autoriser_jeton_video -- une seule ligne change
-- ============================================================================

create or replace function public.autoriser_jeton_video(
  p_session_id uuid, p_profile_id uuid, p_ws_url_cloud text, p_ws_url_self_hosted text
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

-- Droits : l'ACL reelle relevee AVANT d'ecrire, a l'identique. Un
-- `create or replace` de meme signature la conserve deja ; elle est reposee
-- parce que s'en remettre a ce qu'un `replace` conserve serait s'en remettre a
-- un souvenir. `authenticated` figure dans le REVOKE et jamais dans le grant :
-- cette fonction emet des jetons video et n'est pas appelable depuis le client.
revoke execute on function public.autoriser_jeton_video(uuid, uuid, text, text)
  from public, anon, authenticated, agent_ro;
grant execute on function public.autoriser_jeton_video(uuid, uuid, text, text)
  to service_role;

-- ============================================================================
-- B. L'annonce reservee a l'enfant concerne
-- ============================================================================

create or replace function public.annonce_observation_pour_moi(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_depuis timestamptz;
begin
  -- Porte d'entree, en EXIGENCE POSITIVE. Avec auth.uid() nul, `not exists`
  -- est vrai et la porte se FERME ; un `if role <> 'x' then raise` se serait
  -- tu et aurait ouvert a `anon`.
  if not exists (
    select 1
      from public.sessions s
      join public.groupe_membres m
        on m.groupe_id = s.groupe_id
       and m.left_at is null
     where s.id = p_session_id
       and s.deleted_at is null
       and m.student_id = auth.uid()
       and public.app_account_valid()
  ) then
    raise exception 'reserve a l''eleve du groupe de cette seance'
      using errcode = 'insufficient_privilege';
  end if;

  -- LE VERROU DE VIE PRIVEE : `v.enfant_profile_id = auth.uid()`. Ce n'est pas
  -- un filtre d'affichage, c'est la seule ligne que cette fonction puisse
  -- atteindre. Aucun enfant ne peut apprendre qu'un autre foyer observe.
  select v.entered_at into v_depuis
    from public.guardian_session_visit v
   where v.session_id = p_session_id
     and v.role = 'guardian_observer'
     and v.left_at is null
     and v.enfant_profile_id = auth.uid()
   order by v.entered_at desc
   limit 1;

  -- Deux faits, pas un de plus. Ni identite de l'observateur, ni numero de
  -- visite, ni compteur : un compteur renseignerait deja sur les autres foyers.
  return jsonb_build_object(
    'observe', v_depuis is not null,
    'depuis',  v_depuis
  );
end;
$$;

-- Droits : calques sur `annonces_observation` (postgres, authenticated,
-- service_role). Les DEUX instructions sont ecrites : un `create` neuf recoit
-- les droits par defaut de Supabase, `anon` compris, et un revoke de public ne
-- retire rien a `authenticated`. La fonction est `stable`, mais `agent_ro`
-- n'apparait que dans le revoke : elle dit d'un foyer ce qui ne regarde que lui.
revoke execute on function public.annonce_observation_pour_moi(uuid) from public, anon, agent_ro;
grant execute on function public.annonce_observation_pour_moi(uuid) to authenticated;

-- ============================================================================
-- Controle de sortie -- modele 0030_tc_socle.sql:218-230. Chaque controle est
-- ecrit en EXIGENCE POSITIVE : un `if valeur <> attendue` ne se declenche pas
-- quand la ligne manque, puisque NULL n'est pas vrai.
-- ============================================================================
do $$
declare
  v_oid    oid;
  v_nb     int;
  v_source text;
begin
  -- ==========================================================================
  -- A. autoriser_jeton_video
  -- ==========================================================================
  v_oid := to_regprocedure('public.autoriser_jeton_video(uuid, uuid, text, text)')::oid;
  if v_oid is null then
    raise exception '0040 incomplete : public.autoriser_jeton_video(uuid, uuid, text, text) est absente';
  end if;

  select count(*) into v_nb
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'autoriser_jeton_video';
  if v_nb <> 1 then
    raise exception '0040 incomplete : % fonction(s) autoriser_jeton_video, 1 attendue', v_nb;
  end if;

  select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid = v_oid;

  -- Le tuteur observateur est masque. C'est toute la correction.
  if v_source not like '%v_role in (''masked_controller'', ''admin_masked'', ''guardian_observer'')%' then
    raise exception '0040 incomplete : guardian_observer n''a pas rejoint les roles masques';
  end if;

  -- LES CINQ AUTRES ROLES SONT INCHANGES. Chaque capacite est exigee
  -- separement : c'est un point chaud, et ne pas trouver de faute n'est pas une
  -- preuve. Les motifs cherches sont les expressions qui decident de chaque
  -- capacite, et NON les lignes entieres : un controle qui casse sur un espace
  -- de plus ne controle rien.
  if v_source not like '%v_role in (''teacher'', ''student'', ''admin_visible'')%' then
    raise exception '0040 incomplete : la regle de publication a bouge';
  end if;
  if v_source not like '%(v_role = ''teacher'')%' then
    raise exception '0040 incomplete : le canal de donnees a bouge';
  end if;
  if v_source not like '%(v_role = ''admin_visible'')%' then
    raise exception '0040 incomplete : la video de l''administration a bouge';
  end if;
  if v_source not like '%''Administration Rewayah''%' then
    raise exception '0040 incomplete : l''identite institutionnelle a disparu';
  end if;
  -- Le ttl du tuteur reste borne par le budget, les autres par le seul TTL.
  if v_source not like '%least(v_ttl, ((v_budget->>''restant_secondes'')::int))%' then
    raise exception '0040 incomplete : le ttl du tuteur n''est plus borne par le budget';
  end if;
  -- La politique camera de l'eleve est toujours interrogee.
  if v_source not like '%coalesce(v_camera, ''forbidden'') = ''allowed''%' then
    raise exception '0040 incomplete : la politique camera de l''eleve a disparu';
  end if;

  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 'v' then
    raise exception '0040 incomplete : autoriser_jeton_video n''est plus volatile';
  end if;
  if not (select p.prosecdef from pg_catalog.pg_proc p where p.oid = v_oid) then
    raise exception '0040 incomplete : autoriser_jeton_video n''est plus security definer';
  end if;
  if not exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid = v_oid and p.proconfig @> array['search_path=""']
  ) then
    raise exception '0040 incomplete : autoriser_jeton_video n''a plus search_path vide';
  end if;

  -- L'ACL doit rester CELLE QUI A ETE RELEVEE : service_role seul. Chaque role
  -- est verifie separement -- EXECUTE arrive par deux chemins sur Supabase.
  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0040 incomplete : anon a EXECUTE sur autoriser_jeton_video';
  end if;
  if pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0040 incomplete : authenticated a EXECUTE sur l''emission de jetons video';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid, 'execute') then
    raise exception '0040 incomplete : agent_ro a EXECUTE sur une fonction volatile';
  end if;
  if not pg_catalog.has_function_privilege('service_role', v_oid, 'execute') then
    raise exception '0040 incomplete : service_role a PERDU EXECUTE -- plus aucun jeton video ne peut etre emis';
  end if;

  -- ==========================================================================
  -- B. annonce_observation_pour_moi
  -- ==========================================================================
  v_oid := to_regprocedure('public.annonce_observation_pour_moi(uuid)')::oid;
  if v_oid is null then
    raise exception '0040 incomplete : public.annonce_observation_pour_moi(uuid) est absente';
  end if;

  select count(*) into v_nb
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'annonce_observation_pour_moi';
  if v_nb <> 1 then
    raise exception '0040 incomplete : % fonction(s) annonce_observation_pour_moi, 1 attendue', v_nb;
  end if;

  select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid = v_oid;

  -- LE VERROU DE VIE PRIVEE, exige par sa presence. Sans cette clause, la
  -- fonction rendrait la visite d'un autre foyer.
  if v_source not like '%v.enfant_profile_id = auth.uid()%' then
    raise exception '0040 incomplete : l''annonce enfant n''est pas bornee a l''enfant concerne';
  end if;
  -- Elle ne doit rendre QUE la sienne : jamais d'agregat.
  if v_source like '%jsonb_agg%' or v_source like '%count(%' then
    raise exception '0040 incomplete : l''annonce enfant agrege, donc elle renseigne sur les autres foyers';
  end if;
  -- La porte est ecrite en exigence positive.
  if v_source not like '%if not exists (%' then
    raise exception '0040 incomplete : la porte de l''annonce enfant n''est pas en exigence positive';
  end if;

  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 's' then
    raise exception '0040 incomplete : annonce_observation_pour_moi n''est pas stable';
  end if;
  if not (select p.prosecdef from pg_catalog.pg_proc p where p.oid = v_oid) then
    raise exception '0040 incomplete : annonce_observation_pour_moi n''est pas security definer';
  end if;
  if not exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid = v_oid and p.proconfig @> array['search_path=""']
  ) then
    raise exception '0040 incomplete : annonce_observation_pour_moi n''a pas search_path vide';
  end if;

  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0040 incomplete : anon garde EXECUTE sur annonce_observation_pour_moi';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0040 incomplete : authenticated n''a pas EXECUTE sur annonce_observation_pour_moi';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid, 'execute') then
    raise exception '0040 incomplete : agent_ro a EXECUTE sur l''annonce d''un foyer';
  end if;

  -- ==========================================================================
  -- C. Ce que 0040 ne doit PAS avoir defait
  -- ==========================================================================
  -- La RLS de guardian_session_visit n'est pas relachee : l'enfant passe par la
  -- RPC, jamais par la table. Les deux policies de lecture doivent etre les
  -- deux seules.
  if (select count(*) from pg_catalog.pg_policy p
       where p.polrelid = 'public.guardian_session_visit'::regclass and p.polcmd = 'r') <> 2 then
    raise exception '0040 incomplete : le nombre de policies de lecture sur guardian_session_visit a change';
  end if;
  if not (select c.relrowsecurity from pg_catalog.pg_class c
           where c.oid = 'public.guardian_session_visit'::regclass) then
    raise exception '0040 incomplete : la RLS de guardian_session_visit est desactivee';
  end if;

  -- annonces_observation reste reservee a l'enseignant : 0040 ne l'ouvre a
  -- personne d'autre.
  if (select p.prosrc from pg_catalog.pg_proc p
       join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = 'annonces_observation')
     not like '%v_seance.teacher_id <> auth.uid()%' then
    raise exception '0040 incomplete : annonces_observation n''est plus reservee a l''enseignant';
  end if;
end $$;
