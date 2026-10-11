-- X2-07 must-pass: privileges effectifs controles par has_function_privilege.
do $x2_f86_acl$
declare
  v_signature text;
  v_function regprocedure;
  v_security_definer boolean;
begin
  foreach v_signature in array array[
    'public.agent_identite_masquee()',
    'public.agent_jeton_vivant(uuid)',
    'public.app_account_valid()',
    'public.app_config_int(text, integer)',
    'public.app_household_id()',
    'public.app_role()',
    'public.app_user_id()',
    'public.attacher_partition_audit(date)',
    'public.autoriser_ecoute_archive(uuid)',
    'public.autoriser_lecture_piece_identite(uuid)',
    'public.brouillon_cahier(uuid)',
    'public.classes_a_confirmer_admin()',
    'public.completer_kyc_document()',
    'public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)',
    'public.creer_jeton_agent(text, uuid, integer, boolean)',
    'public.dossiers_en_attente()',
    'public.est_observateur_masque(uuid, uuid)',
    'public.etat_presence(uuid, uuid)',
    'public.geler_archive_seance(uuid, text, boolean)',
    'public.groupes_admin()',
    'public.guard_app_config_history()',
    'public.guard_assignment_cap()',
    'public.guard_audit_logs_immutable()',
    'public.guard_contract_acceptances_immutable()',
    'public.guard_devices_max()',
    'public.guard_devices_max_reactivation()',
    'public.guard_prayer_adjustments()',
    'public.guard_profile_immutable_id()',
    'public.guard_rule_override_coherente()',
    'public.guard_rule_override_immutable()',
    'public.guard_session_overlap()',
    'public.guard_session_participant_cap()',
    'public.guard_session_state_transition()',
    'public.horloge_seance(uuid)',
    'public.jetons_agent_actifs()',
    'public.maintenant_serveur()',
    'public.materialiser_seances(uuid)',
    'public.materialiser_seances_groupe(uuid)',
    'public.mes_rapports_en_attente()',
    'public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint)',
    'public.mon_fuseau()',
    'public.mon_groupe_detail(uuid)',
    'public.next_immutable_id(app_role, text)',
    'public.partie_concernee(uuid)',
    'public.peut_deposer_piece_identite(uuid)',
    'public.peut_poser_disponibilite(uuid)',
    'public.preparer_depot_piece_identite(uuid, text)',
    'public.profil_de_mon_foyer(text)',
    'public.record_session_event(uuid, uuid, session_event_type, text)',
    'public.regle_brute(uuid, text)',
    'public.regle_effective(uuid, text)',
    'public.regroupements_demandes_horaires_admin()',
    'public.revoquer_jeton_agent(uuid)',
    'public.session_belongs_to_teacher(uuid, uuid)',
    'public.session_has_participant(uuid, uuid)',
    'public.session_in_household(uuid, uuid)',
    'public.unite_curriculum(uuid)',
    'public.video_route_de_seance(uuid, text, text)'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing manifest function: %', v_signature; end if;
    if has_function_privilege('service_role', v_function, 'EXECUTE') then raise exception 'X2-07 service_role still has EXECUTE: %', v_signature; end if;
  end loop;
  foreach v_signature in array array[
    'public.agent_identite_masquee()',
    'public.profil_de_mon_foyer(text)'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing anon target: %', v_signature; end if;
    if has_function_privilege('anon', v_function, 'EXECUTE') then raise exception 'X2-07 anon still has EXECUTE: %', v_signature; end if;
  end loop;
  foreach v_signature in array array[
    'public.app_account_valid()',
    'public.app_config_int(text, integer)',
    'public.app_household_id()',
    'public.app_role()',
    'public.app_user_id()'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing claims helper: %', v_signature; end if;
    if not has_function_privilege('anon', v_function, 'EXECUTE') then raise exception 'X2-07 anon lost claims helper EXECUTE: %', v_signature; end if;
  end loop;
  foreach v_signature in array array[
    'public.enregistrer_webhook_livekit(text, text, text, uuid, timestamp with time zone, jsonb)',
    'public.autoriser_jeton_video(uuid, uuid, text, text)',
    'public.consommer_code_appairage(text, text, text)',
    'public.profil_du_jeton_appareil(text)',
    'public.confirmer_depot_piece_identite(uuid)',
    'public.creer_profil_enfant(uuid, uuid, text, text, integer, text)',
    'public.remettre_session_agent(text)',
    'public.enregistrer_archive_seance(text, text, text, integer, bigint, text)',
    'public.get_config(text, jsonb)'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing service-role callable function: %', v_signature; end if;
    if not has_function_privilege('service_role', v_function, 'EXECUTE') then raise exception 'X2-07 service_role lost EXECUTE: %', v_signature; end if;
  end loop;
  -- La baseline fe253766 ne donne pas EXECUTE a supabase_auth_admin sur get_config.
  -- La migration ne touche pas cette ACL; l'assertion positive ci-dessus couvre service_role.
  v_function := to_regprocedure('public.agent_pre_request()');
  if v_function is null then raise exception 'X2-07 missing agent_pre_request()'; end if;
  foreach v_signature in array array['anon', 'authenticated', 'service_role', 'agent_ro']::text[] loop
    if not has_function_privilege(v_signature, v_function, 'EXECUTE') then
      raise exception 'X2-07 pre-request role lost EXECUTE: %', v_signature;
    end if;
  end loop;
  foreach v_signature in array array[
    'public.completer_kyc_document()',
    'public.guard_devices_max_reactivation()'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing get_config trigger function: %', v_signature; end if;
    select p.prosecdef into v_security_definer from pg_proc p where p.oid = v_function;
    if not v_security_definer then raise exception 'X2-07 get_config trigger must remain SECURITY DEFINER: %', v_signature; end if;
  end loop;
  foreach v_signature in array array[
    'public.groupe_creneau_ancre()',
    'public.guard_app_config_history()',
    'public.guard_assignment_cap()',
    'public.guard_audit_logs_immutable()',
    'public.guard_contract_acceptances_immutable()',
    'public.guard_devices_max()',
    'public.guard_groupe_membre_cap()',
    'public.guard_prayer_adjustments()',
    'public.guard_profile_immutable_id()',
    'public.guard_rule_override_coherente()',
    'public.guard_rule_override_immutable()',
    'public.guard_session_overlap()',
    'public.guard_session_participant_cap()',
    'public.guard_session_state_transition()',
    'public.tc_demande_horaire_cloture_retrait_groupe()',
    'public.tc_materialiser_apres_adhesion()',
    'public.tc_materialiser_apres_creation_groupe()',
    'public.tc_notification_etape_adulte_autonome()',
    'public.tc_session_feedback_calculer_empreinte()'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing trigger function: %', v_signature; end if;
    select p.prosecdef into v_security_definer from pg_proc p where p.oid = v_function;
    if v_security_definer then raise exception 'X2-07 trigger remains SECURITY DEFINER: %', v_signature; end if;
  end loop;
  foreach v_signature in array array[
    'public.tc_annotation_toucher_couche()',
    'public.tc_annotation_valider_marqueur()',
    'public.tc_annotation_valider_trait()'
  ]::text[] loop
    v_function := to_regprocedure(v_signature);
    if v_function is null then raise exception 'X2-07 missing annotation trigger function: %', v_signature; end if;
    select p.prosecdef into v_security_definer from pg_proc p where p.oid = v_function;
    if not v_security_definer then raise exception 'X2-07 annotation trigger must remain SECURITY DEFINER: %', v_signature; end if;
  end loop;
end;
$x2_f86_acl$;
