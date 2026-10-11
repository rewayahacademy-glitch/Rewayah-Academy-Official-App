CREATE OR REPLACE FUNCTION public.entrer_observation(p_session_id uuid, p_role text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  if v_role = 'guardian_observer' and NOT coalesce(public.app_role() = 'guardian' AND public.app_account_valid(), false) then
    raise exception 'observation reservee au tuteur' using errcode = 'insufficient_privilege';
  end if;
  if v_role in ('admin_masked', 'admin_visible') and NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
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
$function$

