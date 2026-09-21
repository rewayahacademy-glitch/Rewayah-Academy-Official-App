-- 0037_entrer_observation_rend_l_enfant_concerne.sql
-- Fait revenir l'intervalle d'observation COMPLET a l'appelant, et d'abord
-- l'enfant concerne.
--
-- LE DEFAUT, MESURE DANS LE CODE. public.entrer_observation
-- (0033_tc_vues_rpc.sql:1186-1191) rend :
--
--   'visite', jsonb_build_object('id', v_visit_id, 'visit_number', v_visit_num)
--
-- Deux cles sur onze. La colonne v_enfant est calculee a l'etape 3
-- (0033:1134-1139), ecrite dans guardian_session_visit (0033:1176), journalisee
-- (0033:1183) -- et jamais rendue. Or c'est la SEULE source de l'enfant que le
-- tuteur a le droit de regarder : GuardianSessionVisit.depuisJson la lit sous
-- 'enfant_profile_id' (lib/core/tc_observation/guardian_session_visit.dart:128)
-- et VueObservationTuteur.depuis s'en sert pour reconnaitre l'enfant dans la
-- liste des participants de la salle
-- (lib/features/tc_observation_ui/vue_observation_tuteur.dart:55-59).
--
-- CONSEQUENCE CHIFFREE, avant cette migration : enfantConcerneId vaut toujours
-- null, donc monEnfant vaut toujours null, donc le panneau du tuteur affiche
-- toujours « Votre enfant n'a pas d'image ouverte » -- meme quand l'enfant est
-- dans la salle, camera ouverte, en train de reciter. C'est-a-dire : la visite
-- rend exactement l'inverse du service qu'elle promet. La regle produit du
-- 21/09 est « le parent vient voir si son enfant est actif » ; un ecran qui ne
-- lui montre jamais son enfant ne la sert pas.
--
-- POURQUOI TOUTES LES COLONNES, ET PAS SEULEMENT L'ENFANT. depuisJson lit onze
-- cles et retombe, pour chaque absente, sur un defaut silencieux : role devient
-- `tuteur` meme pour un administrateur, entered_at devient l'epoque, sessionId
-- et groupeId deviennent la chaine vide. Ces defauts ne se voient pas : ils
-- produisent un objet complet et faux. Rendre la ligne entiere coute une
-- expression et supprime la classe entiere de defauts. La forme retenue est
-- exactement celle de visites_observation (0033:1242-1250), augmentee des
-- quatre colonnes que celle-ci ne rend pas non plus.
--
-- CE QUI NE CHANGE PAS. Aucune signature, aucun droit, aucune verification,
-- aucun ordre d'operations : les etapes 1 a 6 sont recopiees a l'identique de
-- 0033:1103-1184, seule la valeur de la cle 'visite' du jsonb final change. Un
-- `create or replace` sur une signature inchangee CONSERVE les droits deja
-- poses (0033:1195-1196) ; ils ne sont donc pas reposes, contrairement au cas
-- d'un `drop` (cf. 0036, ou la signature changeait).
--
-- QUI EST AFFECTE. Les tuteurs observateurs (ils voient enfin leur enfant) et
-- les administrateurs observateurs (leur role revient exact au lieu de se
-- lire `guardian_observer` par defaut). Aucun appelant ne casse : le seul
-- lecteur est ResultatEntreeObservation.depuisJson
-- (lib/core/tc_observation/port_visite_observation.dart:25-40), qui passe le
-- sous-objet a GuardianSessionVisit.depuisJson, laquelle lit deja ces onze cles
-- avec des defauts surs. Des cles EN PLUS ne cassent rien ; c'est leur absence
-- qui cassait.
--
-- VERITE SERVEUR. enfant_profile_id n'est jamais recu en parametre : il est
-- calcule ici, par est_du_foyer, sur le groupe de la seance. Un tuteur ne peut
-- donc pas designer l'enfant qu'il regarde -- il regarderait celui des autres.

create or replace function public.entrer_observation(p_session_id uuid, p_role text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_seance    public.sessions%rowtype;
  v_role      public.participant_role;
  v_fenetre   int := public.app_config_int('join_window_minutes', 20);
  v_grace     int := public.app_config_int('grace_after_end_minutes', 15);
  v_enfant    uuid;
  v_pol       jsonb;
  v_budget    jsonb;
  v_visite    public.guardian_session_visit;
  v_visit_num smallint;
begin
  if p_role not in ('guardian_observer', 'admin_masked', 'admin_visible') then
    raise exception 'role d''observation inconnu : %', p_role using errcode = 'invalid_parameter_value';
  end if;
  v_role := p_role::public.participant_role;

  if not public.app_account_valid() then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';
  end if;

  -- 1. La seance existe et est dans la fenetre.
  select * into v_seance from public.sessions s
   where s.id = p_session_id and s.deleted_at is null;
  if not found then
    return jsonb_build_object('autorise', false, 'motif_refus', 'seance_non_active');
  end if;
  if now() < coalesce(v_seance.join_opens_at, v_seance.started_at - make_interval(mins => v_fenetre))
     or now() > v_seance.ended_at + make_interval(mins => v_grace) then
    return jsonb_build_object('autorise', false, 'motif_refus', 'hors_fenetre');
  end if;

  -- 2. Le droit de tenir CE role.
  if v_role = 'guardian_observer' and public.app_role() <> 'guardian' then
    raise exception 'observation reservee au tuteur' using errcode = 'insufficient_privilege';
  end if;
  if v_role in ('admin_masked', 'admin_visible') and public.app_role() <> 'admin' then
    raise exception 'observation reservee a l''administration' using errcode = 'insufficient_privilege';
  end if;

  -- 3. Lien tuteur-enfant dans CE groupe -- guardian_observer seulement.
  if v_role = 'guardian_observer' then
    select m.student_id into v_enfant
      from public.groupe_membres m
     where m.groupe_id = v_seance.groupe_id
       and m.left_at is null
       and public.est_du_foyer(m.student_id)
     limit 1;
    if v_enfant is null then
      return jsonb_build_object('autorise', false, 'motif_refus', 'lien_tuteur_absent');
    end if;
  end if;

  -- 4. Politique du groupe -- guardian_observer seulement.
  v_pol := public.politique_observation_effective(v_seance.groupe_id);
  if v_role = 'guardian_observer' and not (v_pol->>'observation_activee')::boolean then
    return jsonb_build_object('autorise', false, 'motif_refus', 'policy_desactivee');
  end if;

  -- 5. Quota -- guardian_observer seulement.
  if v_role = 'guardian_observer' then
    v_budget := public.budget_observation(p_session_id);
    if not (v_budget->>'peut_entrer')::boolean then
      return jsonb_build_object(
        'autorise', false,
        'motif_refus', v_budget->>'motif_refus',
        'budget', v_budget
      );
    end if;
  end if;

  -- 6. Alors seulement : ecriture, y compris pour un role incognito.
  insert into public.session_participants (session_id, profile_id, role)
  values (p_session_id, auth.uid(), v_role)
  on conflict (session_id, profile_id) do update set role = excluded.role, deleted_at = null;

  select coalesce(max(v.visit_number), 0) + 1 into v_visit_num
    from public.guardian_session_visit v
   where v.session_id = p_session_id and v.observateur_profile_id = auth.uid();

  insert into public.guardian_session_visit (
    session_id, groupe_id, observateur_profile_id, role, enfant_profile_id,
    visit_number, policy_version
  ) values (
    p_session_id, v_seance.groupe_id, auth.uid(), v_role, v_enfant,
    v_visit_num, coalesce(v_pol->>'policy_version', '')
  )
  returning * into v_visite;

  perform public.log_sensitive_access(
    'observation_entree', 'guardian_session_visit', v_visite.id::text,
    jsonb_build_object('session_id', p_session_id, 'role', v_role, 'enfant_profile_id', v_enfant)
  );

  return jsonb_build_object(
    'autorise', true,
    'motif_refus', null,
    -- L'intervalle COMPLET. `enfant_profile_id` est la raison d'etre de ce
    -- bloc : sans lui, le panneau du tuteur ne peut reconnaitre son enfant
    -- dans la salle.
    'visite', jsonb_build_object(
      'id',                     v_visite.id,
      'session_id',             v_visite.session_id,
      'groupe_id',              v_visite.groupe_id,
      'observateur_profile_id', v_visite.observateur_profile_id,
      'role',                   v_visite.role,
      'enfant_profile_id',      v_visite.enfant_profile_id,
      'entered_at',             v_visite.entered_at,
      'left_at',                v_visite.left_at,
      'duration_seconds',       v_visite.duration_seconds,
      'visit_number',           v_visite.visit_number,
      'policy_version',         v_visite.policy_version,
      'fin_de_visite',          v_visite.fin_de_visite
    ),
    'budget', case when v_role = 'guardian_observer' then public.budget_observation(p_session_id) else null end
  );
end;
$$;

-- Les droits de 0033:1195-1196 survivent a un `create or replace` de meme
-- signature. Ils sont neanmoins reposes : EXECUTE arrive par DEUX chemins sur
-- Supabase, et une seule instruction ne suffit jamais a raisonner sur les deux.
-- La fonction reste volatile : agent_ro n'apparait que dans le revoke.
revoke execute on function public.entrer_observation(uuid, text) from public, anon, agent_ro;
grant execute on function public.entrer_observation(uuid, text) to authenticated;

-- ============================================================================
-- Controle de sortie -- modele 0030_tc_socle.sql:218-230 et 0036. Chaque
-- controle est ecrit en EXIGENCE POSITIVE : un `if valeur <> attendue` ne se
-- declenche pas quand la ligne manque, puisque NULL n'est pas vrai.
-- ============================================================================
do $$
declare
  v_oid oid;
  v_nb  int;
begin
  select count(*) into v_nb
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'entrer_observation';
  if v_nb <> 1 then
    raise exception '0037 incomplete : % fonction(s) entrer_observation, 1 attendue', v_nb;
  end if;

  if to_regprocedure('public.entrer_observation(uuid, text)') is null then
    raise exception '0037 incomplete : la signature (uuid, text) est absente';
  end if;

  select p.oid into v_oid
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'entrer_observation';

  -- Le corps doit rendre l'enfant concerne : c'est tout l'objet de 0037. Le
  -- motif cherche est `v_visite.enfant_profile_id`, qui n'existe que dans la
  -- version rendue -- la version 0033 ne connaissait que `v_enfant`.
  if (select p.prosrc from pg_catalog.pg_proc p where p.oid = v_oid)
     not like '%v_visite.enfant_profile_id%' then
    raise exception '0037 incomplete : entrer_observation ne rend pas enfant_profile_id';
  end if;

  -- Elle ecrit : elle doit rester volatile, c'est ce qui interdit agent_ro.
  if (select p.provolatile from pg_catalog.pg_proc p where p.oid = v_oid) <> 'v' then
    raise exception '0037 incomplete : entrer_observation n''est plus volatile';
  end if;

  if pg_catalog.has_function_privilege('anon', v_oid, 'execute') then
    raise exception '0037 incomplete : anon garde EXECUTE sur entrer_observation';
  end if;
  if not pg_catalog.has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception '0037 incomplete : authenticated n''a pas EXECUTE sur entrer_observation';
  end if;
  if pg_catalog.has_function_privilege('agent_ro', v_oid, 'execute') then
    raise exception '0037 incomplete : agent_ro a EXECUTE sur une fonction volatile';
  end if;
end $$;
