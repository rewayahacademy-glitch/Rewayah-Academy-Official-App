-- CANDIDAT DE REMEDIATION SEC-PROD — NE PAS EXECUTER EN L'ETAT.
-- Draft dérivé du catalogue PROD ledger 0042 observé le 2026-10-10.
-- Il n'est ni une migration, ni une preuve de test, ni une autorisation d'exécution.
-- Gates restantes: revue Claude de CE SHA, rejeu 0001-0042 + tests ciblés sur PostgreSQL 17 frais,
-- STAGING/API, contrôle des usages directs des vues, puis autorisation PROD selon Journal distant.
-- Ne touche pas btree_gist, les données, les fonctions Edge, Auth ni les objets Storage.
--
-- Sources de code de départ:
--   0074 @ 0120fa11134075bbfdd5cb5094a9e46b9ae9829a
--   0081 @ 7045e7d4956ba9bf78cdced893e0a11d99c46e9b
--   0084 @ ba943f016df3c3ce9720663fc1c5b7b83fd69bfd
--   snapshot @ 98611976d56781f32a2383ec9cc5f76f5fe8b409
--
-- Exécution prévue seulement avec psql -v ON_ERROR_STOP=1 après les gates.
-- La transaction doit pouvoir être entièrement annulée. Ne pas copier dans une migration.
begin;
set local search_path = pg_catalog, public, app_private;

-- Verrouiller la cible logique et le catalogue avant toute DDL.
do $sec_prod_preflight$
declare
  v_count integer;
  v_latest text;
  v_schema text;
begin
  if current_setting('server_version_num')::integer < 150000 then
    raise exception 'SEC-PROD: PostgreSQL 15+ requis';
  end if;
  if to_regclass('supabase_migrations.schema_migrations') is null then
    raise exception 'SEC-PROD: ledger Supabase absent';
  end if;
  select count(*), max(version::text) into v_count, v_latest
    from supabase_migrations.schema_migrations;
  if v_count <> 50 or v_latest <> '0042' then
    raise exception 'SEC-PROD: ledger inattendu (count=%, max=%); attendu 50 / 0042', v_count, v_latest;
  end if;
  if to_regnamespace('app_private') is not null then
    raise exception 'SEC-PROD: app_private déjà présent; cible divergée du ledger 0042 observé';
  end if;
  if (select count(*) from pg_catalog.pg_roles where rolname in ('anon','authenticated','agent_ro')) <> 3 then
    raise exception 'SEC-PROD: rôles Supabase attendus absents';
  end if;
end
$sec_prod_preflight$;

-- Matrice complète des 118 fonctions authenticated issue du snapshot.
-- L'empreinte protège contre un changement de définition depuis l'archive.
create temporary table sec_prod_expected_functions (
  signature text primary key,
  md5_definition text not null,
  anon_execute boolean not null,
  agent_ro_execute boolean not null
) on commit drop;
insert into pg_temp.sec_prod_expected_functions(signature, md5_definition, anon_execute, agent_ro_execute) values
  ('public.agent_identite_masquee()', 'd840394e84b8b4c9ba497dffaad20d54', true, true),
  ('public.agent_pre_request()', '6b20cd70194775bf54db14725128a3c5', true, true),
  ('public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)', '5c001c226d18ba90fdaf5a7581be9a66', false, false),
  ('public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)', 'cee5a197b02fbed73038efe1113f45cb', false, false),
  ('public.annonce_observation_pour_moi(p_session_id uuid)', 'a527cfa220e0f6b3af044b1634ea152c', false, false),
  ('public.annonces_observation(p_session_id uuid)', '4c3f4797c0e0a55d197fc4bb701a7300', false, false),
  ('public.annuler_evaluation(p_evaluation_id uuid, p_motif text)', '4f9fd8b123ac1e3994921a19839ea657', false, false),
  ('public.anomalies_qualite()', 'cc4216e342fc0346371a6980b2399bea', false, true),
  ('public.app_account_valid()', '25ef4708ed7b2d0b81a58f3c13675f95', true, true),
  ('public.app_config_int(p_key text, p_defaut integer)', '8e952a7f94ab026e910b91aa34871768', true, true),
  ('public.app_household_id()', '542ef88e02409f5373959100cd7a3d0c', true, true),
  ('public.app_role()', 'b20471b9c758fed68602f39e075717c1', true, true),
  ('public.app_user_id()', '662840b5e2b92eb18413856d550b1af3', true, true),
  ('public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text)', '0f45793b6620c4126fb8021f9ad85f71', false, false),
  ('public.autoriser_ecoute_archive(p_recording_id uuid)', '43b6560d4add3f778326e832a251088c', false, false),
  ('public.autoriser_lecture_piece_identite(p_document_id uuid)', 'f3e4c7db59cc2000fd609e2fbe6f5cf3', false, false),
  ('public.brouillon_cahier(p_session_id uuid)', '6abe6bbcb1515130213fb637cdd5cfb7', false, true),
  ('public.budget_observation(p_session_id uuid)', '390f9c621dccf161c23501b6f7937c22', false, false),
  ('public.clore_exception_progression(p_exception_id uuid, p_motif text)', 'ee94547ce13af07a6bb3a526c1b93019', false, false),
  ('public.clore_regle(p_override_id uuid, p_motif text)', '69c2d22a82d2d06431a75488e9b96aad', false, false),
  ('public.cloturer_groupe(p_groupe_id uuid, p_motif text)', 'c08ce88599444254b4155baff166302f', false, false),
  ('public.completer_kyc_document()', '55e4cc15937dcb0b70a28ac0471ef7b8', true, false),
  ('public.comptes_admin()', '78817cf3395a6a3c301c91f45934e80f', true, true),
  ('public.creer_code_appairage(p_student_profile_id uuid)', 'ed5103a9093421c68265efdef96ed16b', false, false),
  ('public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint)', '97c8c9e666653e03584e0d875ad00c33', true, true),
  ('public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint)', 'd85b1b126ac26ab5628777ee722b71b0', false, false),
  ('public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer, p_identite_masquee boolean)', '0084e98d6eada6c376364bfead236b22', false, false),
  ('public.creer_profil_inscription(p_role text, p_first_name text, p_last_name text, p_gender gender, p_timezone text)', '4564536aa08e2389235fcecf00117611', false, false),
  ('public.creer_version_programme(p_source_version_id uuid)', 'b72ca828b9c07f40cb69b8a2f6e11de3', false, false),
  ('public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text)', '7e1986d430bef88eec0dffa29e290acf', false, false),
  ('public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text)', '9b1f8d0d3baea020be07d676c34de6e2', false, false),
  ('public.decider_placement(p_student_id uuid, p_niveau_id uuid, p_motif text)', '57f9459ec3a73dbbc3b6b3dea0a0015d', false, false),
  ('public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer)', '967659fc78d48da104daa224138b2de6', false, false),
  ('public.demander(p_kind text, p_subject_profile_id uuid, p_motif text, p_rule_key text, p_rule_value integer)', 'ebb7508bf33843ce0602e66bbcf8dc82', false, false),
  ('public.demandes_en_attente()', 'a9003a8e91895e4b6d7674e584a7fe75', false, true),
  ('public.derniere_position_groupe(p_groupe_id uuid)', '73ddd94f8f873fb5ebed000d501b8ed6', false, false),
  ('public.diagnostics_a_traiter()', 'b1294c4ac77aeeb86a308246beb5059d', false, true),
  ('public.doit_demander_feedback(p_session_id uuid)', '03d6f39788bbe7ff8df48985b70ea879', false, false),
  ('public.dossiers_en_attente()', 'b31b4fbc58d5a55117b4ed951a3403b5', false, true),
  ('public.eleves_sans_enseignant()', 'd3e14512ba428ffec5e9623d8e8bacbd', false, true),
  ('public.enregistrer_resultat_evaluation(p_evaluation_id uuid, p_resultat text, p_notes text)', '4bd65c40df79915136eece059762a525', false, false),
  ('public.enseignants_pour(p_student_profile_id uuid)', 'f2446791e27fe948db4a172470be5940', false, true),
  ('public.entrer_observation(p_session_id uuid, p_role text)', '9da9386bb2c6b2d07eae3fadee3c2010', false, false),
  ('public.est_du_foyer(p_profile_id uuid)', 'cf01e3f9efe82d50ca05275ce30428e9', false, false),
  ('public.est_observateur_masque(p_session_id uuid, p_profile_id uuid)', 'a5e13b2fbdbff5a32f21616bb7637fff', false, true),
  ('public.etat_dossier()', '8029881e3743ba27d7838fef226813a4', false, true),
  ('public.etat_presence(p_session_id uuid, p_profile_id uuid)', '6915fe061c06c9f5617c7d9e9bf0f051', false, true),
  ('public.evaluations_admin()', '71eff9577dda431a05fb4766db2c2032', false, true),
  ('public.geler_archive_seance(p_recording_id uuid, p_motif text, p_gel boolean)', 'cdab571836d441c57694f9bea5099f40', false, false),
  ('public.groupe_detail(p_groupe_id uuid)', 'dec65463d891f3cef2ec314efebe2051', false, true),
  ('public.groupe_roster_enseignant(p_groupe_id uuid)', '20212f9b34187cef242bc98ce2fa57a2', false, false),
  ('public.groupes_admin()', '948e0562c8ef4086dd00f6fb70c7d1e2', true, true),
  ('public.guard_app_config_history()', '99b0223e1ea4211510dab2699c048d9b', true, false),
  ('public.guard_assignment_cap()', '8f663d8b6fe5b4e7ceca82229e3ac43b', true, false),
  ('public.guard_audit_logs_immutable()', 'a582efceb101d5541fd511cb7c0c7a91', true, false),
  ('public.guard_contract_acceptances_immutable()', '572baa09d163a0b386a7a98d7006b02b', true, false),
  ('public.guard_devices_max_reactivation()', 'fd517074a8ada2d32fabe95def07ec44', true, false),
  ('public.guard_devices_max()', 'f43bd4724f00b05af103bdafcbe8a714', true, false),
  ('public.guard_prayer_adjustments()', 'f358ae78bf49c71bf2316a9271c61d78', true, false),
  ('public.guard_profile_immutable_id()', '1fff46e37cbb5c465e4109b910b76d1d', true, false),
  ('public.guard_profile_privileged_columns()', '0e0b9d7f966e64b2e5182a0a9d5495eb', true, false),
  ('public.guard_rule_override_coherente()', '3f5931edc446d04c9cd03fbfd5387052', true, false),
  ('public.guard_rule_override_immutable()', '458c3ca2dfc2858b89472aa0e6e988de', true, false),
  ('public.guard_session_state_transition()', '6337e0fa1c9f05b12440c7dd66a18b63', true, false),
  ('public.horloge_seance(p_session_id uuid)', '879eb5957f8cabd0f25278807c5e0576', false, true),
  ('public.indicateurs_admin()', 'd7e1209572394c2ab6d5f9dae3834aaa', false, true),
  ('public.jetons_agent_actifs()', '0712f58e294f778705822aab96d9bea4', false, true),
  ('public.journal_audit_filtres()', '49c1360b67ef589d2aaef8468ecc31bc', false, true),
  ('public.journal_audit(p_acteur uuid, p_action text, p_depuis timestamp with time zone, p_limite integer, p_avant_date timestamp with time zone, p_avant_id bigint)', '973fec3923b807963042e424ef181e50', false, true),
  ('public.log_sensitive_access(p_action text, p_table_name text, p_row_id text, p_payload jsonb)', 'f8bd87ae2b78060f31362ccf7697cbc4', false, false),
  ('public.maintenant_serveur()', '544d5e02a1e48495e4d4aac532bc498b', false, true),
  ('public.maj_eleve_pedagogie(p_profile_id uuid, p_level text, p_riwaya text)', 'f9164b5c4b9a7bbc582ae7675ff94678', false, false),
  ('public.maj_profil_enseignant(p_country text, p_languages text[], p_timezone text)', '62a32e47dabb25ff2d1161077944eb83', false, false),
  ('public.materialiser_seances(p_assignment_id uuid)', '3033a4a29b4fac32a7ba2cc093b5f09b', false, false),
  ('public.mes_rapports_en_attente()', 'f5f2f30e05982a7880583244c343dd21', false, true),
  ('public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint)', '713d5acca4971058883ea90e06bb6ad4', true, true),
  ('public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint)', '5bfb604429ef9b20ac632197218f9784', false, false),
  ('public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text)', 'b61928f62425d1439e3ac806c96a7f8c', false, false),
  ('public.mon_fuseau()', 'df015b341503e85ecebe9e57fefb086b', false, true),
  ('public.mon_groupe_detail(p_groupe_id uuid)', '2a294f40be8845fb7df1b98655ffea78', false, true),
  ('public.next_immutable_id(role_code app_role, initials text)', 'b33f7d92b9211e63497e47240599ce72', false, false),
  ('public.partie_concernee(p_profile_id uuid)', '1eb8c65b41d86791b900ab7e40208389', false, true),
  ('public.personnes_observables()', '0f42e63032d25873d2658c53ea669399', true, true),
  ('public.peut_deposer_piece_identite(p_profile_id uuid)', '363d0e5c384d1dbf1dc9c72765dca799', false, true),
  ('public.peut_poser_disponibilite(p_profile_id uuid)', '73be37213e5c5f3ceb6cf11bdcc36605', false, true),
  ('public.planifier_evaluation(p_student_id uuid, p_niveau_id uuid, p_type text, p_date_prevue date)', 'edeae79dea1ee637962a2f9f68e45968', false, false),
  ('public.politique_observation_effective(p_groupe_id uuid)', 'fe478b6be57c4b0e11648dedfd6a8417', false, false),
  ('public.poser_exception_progression(p_student_id uuid, p_type text, p_motif text)', '476c9fbc67014db1aba74e764b0acf67', false, false),
  ('public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text)', 'b42b46c02c394102058503378bc35c6e', false, false),
  ('public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer)', 'b5ac5d0c855282281567be91c3d211c1', false, false),
  ('public.preparer_depot_piece_identite(p_profile_id uuid, p_doc_type text)', 'a5f61b7f8dad3d63938248b34ec77934', false, false),
  ('public.profil_de_mon_foyer(p_profile_id text)', '9a229eac8bc0751df03eac3693c279d5', true, true),
  ('public.programme_niveaux_admin(p_version_id uuid)', '528cede3db466e4026bd81f48b65abc2', false, true),
  ('public.programme_versions_admin()', '0c527e4b9077b9c58db1abd84de39b08', false, true),
  ('public.progression_admin()', '68b358b2d8edf96816388202a8abaca9', false, true),
  ('public.progression_promouvoir(p_student_id uuid, p_niveau_id uuid, p_motif text)', 'e538d880616ae549860df58ebe06b15f', false, false),
  ('public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer)', 'af005c1a3ad93786c1aed15c0e9fae0b', false, false),
  ('public.publier_version_programme(p_version_id uuid, p_motif text)', 'c7715e24d0d338cea4113a3c787580c2', false, false),
  ('public.quitter_salle(p_session_id uuid)', 'c36b13c2df7b623747bb070bfea6279c', false, false),
  ('public.read_kyc_documents()', 'cccb3f874b090ea4b6de084ca6ef70ff', false, true),
  ('public.record_session_event(p_session_id uuid, p_profile_id uuid, p_event_type session_event_type, p_source text)', '380de00d3a207f33eee34e98c9287a4c', false, false),
  ('public.regle_effective(p_profile_id uuid, p_key text)', '778d4a4cde1a262d94e15cf74931130d', false, true),
  ('public.rejoindre_observation(p_session_id uuid)', '11297b9563e6816b369cf55bc842af5e', false, false),
  ('public.ressources_du_groupe(p_groupe_id uuid)', '7f3868abf037296891b446a5ff3a83ee', false, true),
  ('public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text)', 'fcf523b2cdbebec969a5e2253de26aba', false, false),
  ('public.revoquer_appareil(p_device_id uuid)', '94514a938b71c72c9c480554c0ac6bb1', false, false),
  ('public.revoquer_jeton_agent(p_id uuid)', 'fc536a7b55da1011ebd638ca0c269206', false, false),
  ('public.rls_auto_enable()', '6998ea6b4c2480f5d2e34b5dcf3f8d36', true, false),
  ('public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid)', '92f8a2b8ccf6814a0226c9ae2c339387', false, true),
  ('public.session_has_participant(p_session_id uuid, p_uid uuid)', 'c72c6cbc12f9af1c5e7e1ff64adec966', false, true),
  ('public.session_in_household(p_session_id uuid, p_household_id uuid)', '146fb204821facbc32ef2013fd421758', false, true),
  ('public.sortir_observation(p_session_id uuid)', '51afae46db2d837c08fb32f7b8671aac', false, false),
  ('public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text)', '21449ed510bae1e51bd71972989b0fa7', false, false),
  ('public.traiter_anomalie_qualite(p_type_anomalie text, p_ref_id uuid, p_note text)', '8a78c8c8605e0bad66f15f62f406462b', false, false),
  ('public.transitions_fuseau_a_venir(p_jours integer)', 'c90a4ebcfe6a2f303dac10960cabddff', false, false),
  ('public.verifier_chaine_audit(p_limite integer)', 'cf28eb75e08bd5cdd0cb8d18067c720b', false, true),
  ('public.video_config_lire()', '4af82d0a2db1602453eeeaf40a10e9cc', false, true),
  ('public.visites_observation(p_session_id uuid)', 'fac9c7bb4194a98c08c7455afc18cd6c', false, false);

do $sec_prod_functions_preflight$
declare
  r record;
  v_oid oid;
  v_seen integer := 0;
begin
  for r in select * from pg_temp.sec_prod_expected_functions order by signature loop
    v_oid := to_regprocedure(r.signature);
    if v_oid is null then
      raise exception 'SEC-PROD: fonction snapshot absente: %', r.signature;
    end if;
    if md5(pg_get_functiondef(v_oid)) <> r.md5_definition then
      raise exception 'SEC-PROD: définition différente du snapshot: %', r.signature;
    end if;
    if not has_function_privilege('authenticated', v_oid, 'EXECUTE') then
      raise exception 'SEC-PROD: droit authenticated déjà absent: %', r.signature;
    end if;
    if has_function_privilege('anon', v_oid, 'EXECUTE') is distinct from r.anon_execute then
      raise exception 'SEC-PROD: privilège anon différent du snapshot: %', r.signature;
    end if;
    if has_function_privilege('agent_ro', v_oid, 'EXECUTE') is distinct from r.agent_ro_execute then
      raise exception 'SEC-PROD: privilège agent_ro différent du snapshot: %', r.signature;
    end if;
    v_seen := v_seen + 1;
  end loop;
  if v_seen <> 118 then
    raise exception 'SEC-PROD: matrice authenticated incomplète: %', v_seen;
  end if;
  if (select count(*) from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      where n.nspname='public' and p.prosecdef and has_function_privilege('anon',p.oid,'EXECUTE')) <> 27 then
    raise exception 'SEC-PROD: exposition anon SECURITY DEFINER différente du snapshot';
  end if;
  if (select count(*) from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      where n.nspname='public' and p.prosecdef and has_function_privilege('agent_ro',p.oid,'EXECUTE')) <> 48 then
    raise exception 'SEC-PROD: exposition agent_ro SECURITY DEFINER différente du snapshot';
  end if;
end
$sec_prod_functions_preflight$;

-- Les 15 vues doivent exister et ne pas déjà être en SECURITY INVOKER.
do $sec_prod_views_preflight$
declare
  v_name text;
  v_oid oid;
  v_views text[] := array['concern_famille_v', 'eleves_en_attente_v', 'mes_affectations_v', 'mes_appareils_v', 'mes_codes_appairage_v', 'mes_groupes_famille_v', 'mes_groupes_v', 'mes_seances_enseignant_v', 'mes_seances_v', 'presence_seance_v', 'profils_du_foyer_v', 'regles_profil_v', 'session_peers_v', 'teacher_roster_v', 'tendance_feedback_v'];
begin
  foreach v_name in array v_views loop
    v_oid := to_regclass(format('public.%I', v_name));
    if v_oid is null or (select relkind from pg_catalog.pg_class where oid=v_oid) <> 'v' then
      raise exception 'SEC-PROD: vue absente ou remplacée: public.%', v_name;
    end if;
    if coalesce((select reloptions @> array['security_invoker=true'] from pg_catalog.pg_class where oid=v_oid), false) then
      raise exception 'SEC-PROD: vue déjà security_invoker: public.%', v_name;
    end if;
    if not has_table_privilege('authenticated', v_oid, 'SELECT') then
      raise exception 'SEC-PROD: authenticated n''a déjà plus SELECT sur public.%', v_name;
    end if;
  end loop;
end
$sec_prod_views_preflight$;

-- Transformations gardes positives/null-safe issues de 0074.
-- 0074 — convertir les comparaisons de rôles négatives en gardes positives.
-- Le balayage couvre les fonctions SECURITY DEFINER de public et app_private,
-- sans dépendre d'une forme IF sur une seule ligne. Une comparaison non
-- transformée fait échouer la migration.
begin;

-- PROD s'arrête au ledger 0042 et ne possède pas encore app_private.
-- Créer le schéma ici rend ce scanner autonome sans ouvrir le schéma aux clients.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, agent_ro;

create or replace function app_private.has_unsafe_role_guard(p_definition text)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $function$
  select coalesce(
    p_definition ~*
      '((public[.])?app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]*(<>|!=)[[:space:]]*''[^'']+''|(public[.])?app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]+not[[:space:]]+in[[:space:]]*[(]|''[^'']+''[[:space:]]*(<>|!=)[[:space:]]*(public[.])?app_role[[:space:]]*[(][[:space:]]*[)])',
    false
  );
$function$;
revoke all on function app_private.has_unsafe_role_guard(text) from public;
revoke all on function app_private.has_unsafe_role_guard(text) from anon, authenticated, agent_ro;

do $migration$
declare
  v record;
  v_definition text;
  v_corrigee text;
  v_modifiees integer := 0;
begin
  for v in
    select p.oid
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'app_private')
      and p.prokind = 'f'
      and p.prosecdef
      and app_private.has_unsafe_role_guard(p.prosrc)
  loop
    v_definition := pg_catalog.pg_get_functiondef(v.oid);

    -- Rôle requis et compte valide : toute valeur NULL devient un refus.
    v_corrigee := pg_catalog.regexp_replace(
      v_definition,
      '(?i)(public[.])?app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]*(<>|!=)[[:space:]]*''([^'']+)''',
      E'NOT coalesce(public.app_role() = ''\\3'' AND public.app_account_valid(), false)',
      'gi'
    );

    v_corrigee := pg_catalog.regexp_replace(
      v_corrigee,
      '(?i)(public[.])?app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]+NOT[[:space:]]+IN[[:space:]]*[(]([^)]*)[)]',
      E'NOT coalesce(public.app_role() IN (\\2) AND public.app_account_valid(), false)',
      'gi'
    );

    v_corrigee := pg_catalog.regexp_replace(
      v_corrigee,
      '(?i)''([^'']+)''[[:space:]]*(<>|!=)[[:space:]]*(public[.])?app_role[[:space:]]*[(][[:space:]]*[)]',
      E'NOT coalesce(public.app_role() = ''\\1'' AND public.app_account_valid(), false)',
      'gi'
    );

    if v_corrigee = v_definition then
      raise exception '0074: comparaison négative non transformée dans la fonction oid=%', v.oid;
    end if;

    execute v_corrigee;
    v_modifiees := v_modifiees + 1;
  end loop;

  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'app_private')
      and p.prokind = 'f'
      and p.prosecdef
      and app_private.has_unsafe_role_guard(p.prosrc)
  ) then
    raise exception '0074: une comparaison négative subsiste dans une fonction SECURITY DEFINER';
  end if;

  raise notice '0074: % fonctions SECURITY DEFINER mises à garde positive', v_modifiees;
end
$migration$;

-- Remplacement du garde etat_presence + trigger de profil issus de 0084.
-- 0084 — gardes null-safe et rôle effectif du trigger de profils.
-- Cible les définitions présentes depuis le ledger 0042; cette migration
-- additive ne doit pas être appliquée à PROD sans revue du script.
begin;

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
$$;

revoke all on function public.etat_presence(uuid, uuid) from public;
revoke all on function public.etat_presence(uuid, uuid) from anon;
grant execute on function public.etat_presence(uuid, uuid) to authenticated;

create or replace function public.guard_profile_privileged_columns()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin')
     and not coalesce(
       public.app_role() = 'admin' and public.app_account_valid(),
       false
     )
     and (
       old.role is distinct from new.role
       or old.household_id is distinct from new.household_id
       or old.account_status is distinct from new.account_status
       or old.access_until is distinct from new.access_until
     )
  then
    raise exception 'seul un admin modifie rôle, foyer, statut ou accès'
      using errcode = 'insufficient_privilege';
  end if;
  return new;
end;
$function$;


-- M2 / REVUE-F2-I19 : détecter aussi les gardes négatives qui placent
-- app_role() sous NOT (expression parenthésée), y compris IF/ELSIF
-- multilignes et NOT unaire. NOT coalesce(..., false) positif canonique
-- n'est pas capté, car coalesce est une fonction enveloppe.
create or replace function app_private.has_unsafe_role_guard(p_definition text)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $function$
  select coalesce(
    p_definition ~*
      '((if|elsif)[[:space:]]+not[[:space:]]*[(][[:space:]]*(public[.])?app_role[[:space:]]*[(][[:space:]]*[)])'
    or p_definition ~*
      '((if|elsif)[[:space:]]+not[[:space:]]+(public[.])?app_role[[:space:]]*[(][[:space:]]*[)])',
    false
  );
$function$;
revoke all on function app_private.has_unsafe_role_guard(text) from public;
revoke all on function app_private.has_unsafe_role_guard(text) from anon, authenticated, agent_ro;

do $m2_scan$
declare
  v record;
begin
  for v in
    select p.oid
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'app_private')
      and p.prokind = 'f'
      and p.prosecdef
      and app_private.has_unsafe_role_guard(p.prosrc)
  loop
    raise exception '0084 M2: garde négative app_role résiduelle dans SECURITY DEFINER oid=%', v.oid;
  end loop;
end
$m2_scan$;
-- 0084 révoque agent_ro d'etat_presence malgré son accès effectif dans le snapshot.
-- Le rôle garde cette RPC non-KYC; 0081 retire uniquement ses deux RPC KYC.
grant execute on function public.etat_presence(uuid, uuid) to agent_ro;

-- Révoquer anon/PUBLIC sur les 27 SECURITY DEFINER exposées; conserver explicitement
-- les accès effectifs existants de authenticated (118) et agent_ro (48) ci-dessus.
revoke all on function public.agent_identite_masquee() from public, anon;
revoke all on function public.agent_pre_request() from public, anon;
revoke all on function public.app_account_valid() from public, anon;
revoke all on function public.app_config_int(p_key text, p_defaut integer) from public, anon;
revoke all on function public.app_household_id() from public, anon;
revoke all on function public.app_role() from public, anon;
revoke all on function public.app_user_id() from public, anon;
revoke all on function public.completer_kyc_document() from public, anon;
revoke all on function public.comptes_admin() from public, anon;
revoke all on function public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint) from public, anon;
revoke all on function public.groupes_admin() from public, anon;
revoke all on function public.guard_app_config_history() from public, anon;
revoke all on function public.guard_assignment_cap() from public, anon;
revoke all on function public.guard_audit_logs_immutable() from public, anon;
revoke all on function public.guard_contract_acceptances_immutable() from public, anon;
revoke all on function public.guard_devices_max_reactivation() from public, anon;
revoke all on function public.guard_devices_max() from public, anon;
revoke all on function public.guard_prayer_adjustments() from public, anon;
revoke all on function public.guard_profile_immutable_id() from public, anon;
revoke all on function public.guard_profile_privileged_columns() from public, anon;
revoke all on function public.guard_rule_override_coherente() from public, anon;
revoke all on function public.guard_rule_override_immutable() from public, anon;
revoke all on function public.guard_session_state_transition() from public, anon;
revoke all on function public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint) from public, anon;
revoke all on function public.personnes_observables() from public, anon;
revoke all on function public.profil_de_mon_foyer(p_profile_id text) from public, anon;
revoke all on function public.rls_auto_enable() from public, anon;
grant execute on function public.agent_identite_masquee() to authenticated;
grant execute on function public.agent_pre_request() to authenticated;
grant execute on function public.ajouter_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text) to authenticated;
grant execute on function public.ajouter_niveau_programme(p_version_id uuid, p_code_technique text, p_nom_humain text, p_cycle text, p_ordre integer, p_description text) to authenticated;
grant execute on function public.annonce_observation_pour_moi(p_session_id uuid) to authenticated;
grant execute on function public.annonces_observation(p_session_id uuid) to authenticated;
grant execute on function public.annuler_evaluation(p_evaluation_id uuid, p_motif text) to authenticated;
grant execute on function public.anomalies_qualite() to authenticated;
grant execute on function public.app_account_valid() to authenticated;
grant execute on function public.app_config_int(p_key text, p_defaut integer) to authenticated;
grant execute on function public.app_household_id() to authenticated;
grant execute on function public.app_role() to authenticated;
grant execute on function public.app_user_id() to authenticated;
grant execute on function public.attribuer_eleve(p_student_profile_id uuid, p_teacher_profile_id uuid, p_weekday integer, p_hour integer, p_motif text) to authenticated;
grant execute on function public.autoriser_ecoute_archive(p_recording_id uuid) to authenticated;
grant execute on function public.autoriser_lecture_piece_identite(p_document_id uuid) to authenticated;
grant execute on function public.brouillon_cahier(p_session_id uuid) to authenticated;
grant execute on function public.budget_observation(p_session_id uuid) to authenticated;
grant execute on function public.clore_exception_progression(p_exception_id uuid, p_motif text) to authenticated;
grant execute on function public.clore_regle(p_override_id uuid, p_motif text) to authenticated;
grant execute on function public.cloturer_groupe(p_groupe_id uuid, p_motif text) to authenticated;
grant execute on function public.completer_kyc_document() to authenticated;
grant execute on function public.comptes_admin() to authenticated;
grant execute on function public.creer_code_appairage(p_student_profile_id uuid) to authenticated;
grant execute on function public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint) to authenticated;
grant execute on function public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint) to authenticated;
grant execute on function public.creer_jeton_agent(p_libelle text, p_profil_observe uuid, p_duree_heures integer, p_identite_masquee boolean) to authenticated;
grant execute on function public.creer_profil_inscription(p_role text, p_first_name text, p_last_name text, p_gender gender, p_timezone text) to authenticated;
grant execute on function public.creer_version_programme(p_source_version_id uuid) to authenticated;
grant execute on function public.decider_demande(p_request_id uuid, p_accepte boolean, p_motif text) to authenticated;
grant execute on function public.decider_dossier(p_document_id uuid, p_approuve boolean, p_motif text) to authenticated;
grant execute on function public.decider_placement(p_student_id uuid, p_niveau_id uuid, p_motif text) to authenticated;
grant execute on function public.definir_politique_observation_groupe(p_groupe_id uuid, p_source text, p_max_visites smallint, p_max_secondes integer, p_max_secondes_par_visite integer) to authenticated;
grant execute on function public.demander(p_kind text, p_subject_profile_id uuid, p_motif text, p_rule_key text, p_rule_value integer) to authenticated;
grant execute on function public.demandes_en_attente() to authenticated;
grant execute on function public.derniere_position_groupe(p_groupe_id uuid) to authenticated;
grant execute on function public.diagnostics_a_traiter() to authenticated;
grant execute on function public.doit_demander_feedback(p_session_id uuid) to authenticated;
grant execute on function public.dossiers_en_attente() to authenticated;
grant execute on function public.eleves_sans_enseignant() to authenticated;
grant execute on function public.enregistrer_resultat_evaluation(p_evaluation_id uuid, p_resultat text, p_notes text) to authenticated;
grant execute on function public.enseignants_pour(p_student_profile_id uuid) to authenticated;
grant execute on function public.entrer_observation(p_session_id uuid, p_role text) to authenticated;
grant execute on function public.est_du_foyer(p_profile_id uuid) to authenticated;
grant execute on function public.est_observateur_masque(p_session_id uuid, p_profile_id uuid) to authenticated;
grant execute on function public.etat_dossier() to authenticated;
grant execute on function public.etat_presence(p_session_id uuid, p_profile_id uuid) to authenticated;
grant execute on function public.evaluations_admin() to authenticated;
grant execute on function public.geler_archive_seance(p_recording_id uuid, p_motif text, p_gel boolean) to authenticated;
grant execute on function public.groupe_detail(p_groupe_id uuid) to authenticated;
grant execute on function public.groupe_roster_enseignant(p_groupe_id uuid) to authenticated;
grant execute on function public.groupes_admin() to authenticated;
grant execute on function public.guard_app_config_history() to authenticated;
grant execute on function public.guard_assignment_cap() to authenticated;
grant execute on function public.guard_audit_logs_immutable() to authenticated;
grant execute on function public.guard_contract_acceptances_immutable() to authenticated;
grant execute on function public.guard_devices_max_reactivation() to authenticated;
grant execute on function public.guard_devices_max() to authenticated;
grant execute on function public.guard_prayer_adjustments() to authenticated;
grant execute on function public.guard_profile_immutable_id() to authenticated;
grant execute on function public.guard_profile_privileged_columns() to authenticated;
grant execute on function public.guard_rule_override_coherente() to authenticated;
grant execute on function public.guard_rule_override_immutable() to authenticated;
grant execute on function public.guard_session_state_transition() to authenticated;
grant execute on function public.horloge_seance(p_session_id uuid) to authenticated;
grant execute on function public.indicateurs_admin() to authenticated;
grant execute on function public.jetons_agent_actifs() to authenticated;
grant execute on function public.journal_audit_filtres() to authenticated;
grant execute on function public.journal_audit(p_acteur uuid, p_action text, p_depuis timestamp with time zone, p_limite integer, p_avant_date timestamp with time zone, p_avant_id bigint) to authenticated;
grant execute on function public.log_sensitive_access(p_action text, p_table_name text, p_row_id text, p_payload jsonb) to authenticated;
grant execute on function public.maintenant_serveur() to authenticated;
grant execute on function public.maj_eleve_pedagogie(p_profile_id uuid, p_level text, p_riwaya text) to authenticated;
grant execute on function public.maj_profil_enseignant(p_country text, p_languages text[], p_timezone text) to authenticated;
grant execute on function public.materialiser_seances(p_assignment_id uuid) to authenticated;
grant execute on function public.mes_rapports_en_attente() to authenticated;
grant execute on function public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint) to authenticated;
grant execute on function public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint) to authenticated;
grant execute on function public.modifier_niveau_programme(p_niveau_id uuid, p_nom_humain text, p_cycle text, p_ordre integer, p_description text) to authenticated;
grant execute on function public.mon_fuseau() to authenticated;
grant execute on function public.mon_groupe_detail(p_groupe_id uuid) to authenticated;
grant execute on function public.next_immutable_id(role_code app_role, initials text) to authenticated;
grant execute on function public.partie_concernee(p_profile_id uuid) to authenticated;
grant execute on function public.personnes_observables() to authenticated;
grant execute on function public.peut_deposer_piece_identite(p_profile_id uuid) to authenticated;
grant execute on function public.peut_poser_disponibilite(p_profile_id uuid) to authenticated;
grant execute on function public.planifier_evaluation(p_student_id uuid, p_niveau_id uuid, p_type text, p_date_prevue date) to authenticated;
grant execute on function public.politique_observation_effective(p_groupe_id uuid) to authenticated;
grant execute on function public.poser_exception_progression(p_student_id uuid, p_type text, p_motif text) to authenticated;
grant execute on function public.poser_regle(p_profile_id uuid, p_key text, p_value integer, p_motif text) to authenticated;
grant execute on function public.prendre_eleve(p_student_profile_id uuid, p_weekday integer, p_hour integer) to authenticated;
grant execute on function public.preparer_depot_piece_identite(p_profile_id uuid, p_doc_type text) to authenticated;
grant execute on function public.profil_de_mon_foyer(p_profile_id text) to authenticated;
grant execute on function public.programme_niveaux_admin(p_version_id uuid) to authenticated;
grant execute on function public.programme_versions_admin() to authenticated;
grant execute on function public.progression_admin() to authenticated;
grant execute on function public.progression_promouvoir(p_student_id uuid, p_niveau_id uuid, p_motif text) to authenticated;
grant execute on function public.publier_etat_partage(p_session_id uuid, p_resource_id uuid, p_resource_version_id uuid, p_content_position jsonb, p_content_range jsonb, p_display_mode text, p_hidden_ranges jsonb, p_semantic_markers jsonb, p_group_resume_position jsonb, p_revision integer) to authenticated;
grant execute on function public.publier_version_programme(p_version_id uuid, p_motif text) to authenticated;
grant execute on function public.quitter_salle(p_session_id uuid) to authenticated;
grant execute on function public.read_kyc_documents() to authenticated;
grant execute on function public.record_session_event(p_session_id uuid, p_profile_id uuid, p_event_type session_event_type, p_source text) to authenticated;
grant execute on function public.regle_effective(p_profile_id uuid, p_key text) to authenticated;
grant execute on function public.rejoindre_observation(p_session_id uuid) to authenticated;
grant execute on function public.ressources_du_groupe(p_groupe_id uuid) to authenticated;
grant execute on function public.retirer_eleve_groupe(p_groupe_id uuid, p_student_profile_id uuid, p_motif text) to authenticated;
grant execute on function public.revoquer_appareil(p_device_id uuid) to authenticated;
grant execute on function public.revoquer_jeton_agent(p_id uuid) to authenticated;
grant execute on function public.rls_auto_enable() to authenticated;
grant execute on function public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid) to authenticated;
grant execute on function public.session_has_participant(p_session_id uuid, p_uid uuid) to authenticated;
grant execute on function public.session_in_household(p_session_id uuid, p_household_id uuid) to authenticated;
grant execute on function public.sortir_observation(p_session_id uuid) to authenticated;
grant execute on function public.supprimer_niveau_programme(p_niveau_id uuid, p_motif text) to authenticated;
grant execute on function public.traiter_anomalie_qualite(p_type_anomalie text, p_ref_id uuid, p_note text) to authenticated;
grant execute on function public.transitions_fuseau_a_venir(p_jours integer) to authenticated;
grant execute on function public.verifier_chaine_audit(p_limite integer) to authenticated;
grant execute on function public.video_config_lire() to authenticated;
grant execute on function public.visites_observation(p_session_id uuid) to authenticated;
grant execute on function public.agent_identite_masquee() to agent_ro;
grant execute on function public.agent_pre_request() to agent_ro;
grant execute on function public.anomalies_qualite() to agent_ro;
grant execute on function public.app_account_valid() to agent_ro;
grant execute on function public.app_config_int(p_key text, p_defaut integer) to agent_ro;
grant execute on function public.app_household_id() to agent_ro;
grant execute on function public.app_role() to agent_ro;
grant execute on function public.app_user_id() to agent_ro;
grant execute on function public.brouillon_cahier(p_session_id uuid) to agent_ro;
grant execute on function public.comptes_admin() to agent_ro;
grant execute on function public.creer_groupe(p_teacher_profile_id uuid, p_type_public text, p_libelle text, p_weekday smallint, p_hour_local smallint, p_seuil_max smallint, p_timezone_iana text, p_couleur_jeton smallint) to agent_ro;
grant execute on function public.demandes_en_attente() to agent_ro;
grant execute on function public.diagnostics_a_traiter() to agent_ro;
grant execute on function public.dossiers_en_attente() to agent_ro;
grant execute on function public.eleves_sans_enseignant() to agent_ro;
grant execute on function public.enseignants_pour(p_student_profile_id uuid) to agent_ro;
grant execute on function public.est_observateur_masque(p_session_id uuid, p_profile_id uuid) to agent_ro;
grant execute on function public.etat_dossier() to agent_ro;
grant execute on function public.etat_presence(p_session_id uuid, p_profile_id uuid) to agent_ro;
grant execute on function public.evaluations_admin() to agent_ro;
grant execute on function public.groupe_detail(p_groupe_id uuid) to agent_ro;
grant execute on function public.groupes_admin() to agent_ro;
grant execute on function public.horloge_seance(p_session_id uuid) to agent_ro;
grant execute on function public.indicateurs_admin() to agent_ro;
grant execute on function public.jetons_agent_actifs() to agent_ro;
grant execute on function public.journal_audit_filtres() to agent_ro;
grant execute on function public.journal_audit(p_acteur uuid, p_action text, p_depuis timestamp with time zone, p_limite integer, p_avant_date timestamp with time zone, p_avant_id bigint) to agent_ro;
grant execute on function public.maintenant_serveur() to agent_ro;
grant execute on function public.mes_rapports_en_attente() to agent_ro;
grant execute on function public.modifier_groupe(p_groupe_id uuid, p_libelle text, p_seuil_max smallint, p_weekday smallint, p_hour_local smallint, p_timezone_iana text, p_couleur_jeton smallint) to agent_ro;
grant execute on function public.mon_fuseau() to agent_ro;
grant execute on function public.mon_groupe_detail(p_groupe_id uuid) to agent_ro;
grant execute on function public.partie_concernee(p_profile_id uuid) to agent_ro;
grant execute on function public.personnes_observables() to agent_ro;
grant execute on function public.peut_deposer_piece_identite(p_profile_id uuid) to agent_ro;
grant execute on function public.peut_poser_disponibilite(p_profile_id uuid) to agent_ro;
grant execute on function public.profil_de_mon_foyer(p_profile_id text) to agent_ro;
grant execute on function public.programme_niveaux_admin(p_version_id uuid) to agent_ro;
grant execute on function public.programme_versions_admin() to agent_ro;
grant execute on function public.progression_admin() to agent_ro;
grant execute on function public.read_kyc_documents() to agent_ro;
grant execute on function public.regle_effective(p_profile_id uuid, p_key text) to agent_ro;
grant execute on function public.ressources_du_groupe(p_groupe_id uuid) to agent_ro;
grant execute on function public.session_belongs_to_teacher(p_session_id uuid, p_uid uuid) to agent_ro;
grant execute on function public.session_has_participant(p_session_id uuid, p_uid uuid) to agent_ro;
grant execute on function public.session_in_household(p_session_id uuid, p_household_id uuid) to agent_ro;
grant execute on function public.verifier_chaine_audit(p_limite integer) to agent_ro;
grant execute on function public.video_config_lire() to agent_ro;

-- Les vues deviennent SECURITY INVOKER: les droits/RLS des tables du lecteur s'appliquent.
-- anon n'a plus de privilèges directs sur elles; aucun grant sous-jacent ne sera élargi.
alter view public.concern_famille_v set (security_invoker = true);
revoke all on table public.concern_famille_v from public, anon;
alter view public.eleves_en_attente_v set (security_invoker = true);
revoke all on table public.eleves_en_attente_v from public, anon;
alter view public.mes_affectations_v set (security_invoker = true);
revoke all on table public.mes_affectations_v from public, anon;
alter view public.mes_appareils_v set (security_invoker = true);
revoke all on table public.mes_appareils_v from public, anon;
alter view public.mes_codes_appairage_v set (security_invoker = true);
revoke all on table public.mes_codes_appairage_v from public, anon;
alter view public.mes_groupes_famille_v set (security_invoker = true);
revoke all on table public.mes_groupes_famille_v from public, anon;
alter view public.mes_groupes_v set (security_invoker = true);
revoke all on table public.mes_groupes_v from public, anon;
alter view public.mes_seances_enseignant_v set (security_invoker = true);
revoke all on table public.mes_seances_enseignant_v from public, anon;
alter view public.mes_seances_v set (security_invoker = true);
revoke all on table public.mes_seances_v from public, anon;
alter view public.presence_seance_v set (security_invoker = true);
revoke all on table public.presence_seance_v from public, anon;
alter view public.profils_du_foyer_v set (security_invoker = true);
revoke all on table public.profils_du_foyer_v from public, anon;
alter view public.regles_profil_v set (security_invoker = true);
revoke all on table public.regles_profil_v from public, anon;
alter view public.session_peers_v set (security_invoker = true);
revoke all on table public.session_peers_v from public, anon;
alter view public.teacher_roster_v set (security_invoker = true);
revoke all on table public.teacher_roster_v from public, anon;
alter view public.tendance_feedback_v set (security_invoker = true);
revoke all on table public.tendance_feedback_v from public, anon;
revoke select on table public.mes_appareils_v from agent_ro;
revoke select on table public.mes_groupes_famille_v from agent_ro;
revoke select on table public.mes_groupes_v from agent_ro;
revoke select on table public.mes_seances_enseignant_v from agent_ro;
revoke select on table public.teacher_roster_v from agent_ro;

-- B-06: KYC Direction-only; retire lecture directe et policy de lecture Storage.
-- B-06 / SEC-04 — reserver la revue et l'ouverture des pieces KYC a la Direction.
-- Additif uniquement : les migrations deja appliquees ne sont jamais reecrites.
begin;

create or replace function public.read_kyc_documents()
returns setof public.kyc_documents
language plpgsql
security definer
set search_path = ''
as $function$
declare
  reader_gender public.gender;
begin
  if not coalesce(
    public.app_role() = 'admin' and public.app_account_valid(),
    false
  ) then
    raise exception 'acces KYC refuse';
  end if;

  select p.gender into reader_gender
  from public.profiles p
  where p.id = auth.uid() and p.deleted_at is null;

  if reader_gender is null then
    raise exception 'genre du lecteur inconnu : renseignez-le avant de consulter un dossier';
  end if;

  perform public.log_sensitive_access(
    'kyc_read',
    'kyc_documents',
    null::text,
    jsonb_build_object('reader_gender', reader_gender)
  );

  return query
    select k.*
    from public.kyc_documents k
    where k.deleted_at is null and k.gender = reader_gender;
end;
$function$;

create or replace function public.autoriser_lecture_piece_identite(p_document_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_piece public.kyc_documents;
begin
  if not coalesce(
    public.app_role() = 'admin' and public.app_account_valid(),
    false
  ) then
    raise exception 'lecture des pieces d''identite reservee a la Direction'
      using errcode = '42501';
  end if;

  if p_document_id is null then
    raise exception 'document non precise' using errcode = '22023';
  end if;

  select k.* into v_piece
  from public.read_kyc_documents() k
  where k.id = p_document_id;

  if not found then
    raise exception 'piece introuvable ou hors de votre perimetre'
      using errcode = '42501';
  end if;

  perform public.log_sensitive_access(
    'kyc_document_open',
    'kyc_documents',
    v_piece.id::text,
    jsonb_build_object(
      'profile_id', v_piece.profile_id,
      'storage_backend', v_piece.storage_backend,
      'status', v_piece.status
    )
  );

  return jsonb_build_object(
    'document_id', v_piece.id,
    'profile_id', v_piece.profile_id,
    'object_key', v_piece.object_key,
    'storage_backend', v_piece.storage_backend,
    'doc_type', v_piece.doc_type
  );
end;
$function$;

comment on function public.read_kyc_documents() is
  'B-06: Direction seulement; filtre de genre et audit de liste avant retour.';
comment on function public.autoriser_lecture_piece_identite(uuid) is
  'B-06/SEC-04: Direction active seulement; audite une piece avant que le serveur emette une URL courte.';

revoke all on function public.read_kyc_documents() from public, anon, agent_ro;
grant execute on function public.read_kyc_documents() to authenticated;
revoke all on function public.autoriser_lecture_piece_identite(uuid) from public, anon, agent_ro;
grant execute on function public.autoriser_lecture_piece_identite(uuid) to authenticated;

-- Les lectures et décisions passent par les RPC auditées. La policy historique
-- ALL permettait à un admin de lire/modifier directement la table, sans filtre
-- par genre ni événement par pièce.
drop policy if exists kyc_admin_all on public.kyc_documents;

-- Aucun client ne lit directement la table, même si une policy est ajoutée
-- par erreur plus tard. Les accès légitimes passent par les RPC auditées.
revoke select on table public.kyc_documents from public, anon, authenticated, agent_ro;

-- Le navigateur ne signe plus d'URL Storage directement. L'Edge Function
-- piece-identite-acces signe avec le client serveur après l'autorisation SQL.
do $storage$
begin
  if to_regclass('storage.objects') is not null then
    execute 'drop policy if exists kyc_lecture_admin on storage.objects';
  end if;
end
$storage$;

do $verify$
begin
  if not (
    select relrowsecurity
    from pg_catalog.pg_class
    where oid = 'public.kyc_documents'::regclass
  ) then
    raise exception 'B-06: RLS must remain enabled on kyc_documents';
  end if;

  if exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename = 'kyc_documents'
      and cmd in ('ALL', 'SELECT')
  ) then
    raise exception 'B-06: direct KYC table read policy remains';
  end if;

  if pg_catalog.has_table_privilege('anon', 'public.kyc_documents', 'SELECT')
     or pg_catalog.has_table_privilege('authenticated', 'public.kyc_documents', 'SELECT')
     or pg_catalog.has_table_privilege('agent_ro', 'public.kyc_documents', 'SELECT') then
    raise exception 'B-06: anon, authenticated, or agent_ro retains direct KYC SELECT privilege';
  end if;

  if pg_catalog.has_function_privilege('anon', 'public.read_kyc_documents()', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.autoriser_lecture_piece_identite(uuid)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.autoriser_lecture_piece_identite(uuid)', 'execute') then
    raise exception 'B-06: anon or agent_ro retains a KYC RPC';
  end if;

  if not pg_catalog.has_function_privilege('authenticated', 'public.read_kyc_documents()', 'execute')
     or not pg_catalog.has_function_privilege('authenticated', 'public.autoriser_lecture_piece_identite(uuid)', 'execute') then
    raise exception 'B-06: authenticated lacks the guarded KYC RPC';
  end if;
end
$verify$;

-- Contrôle M2 additionnel: le scan 0084 source ne reconnaît pas toutes les formes IF NOT.
-- Heuristique fail-closed, complétée par tests explicites ci-dessous.
create or replace function app_private.sec_prod_has_unsafe_role_guard(p_definition text)
returns boolean language plpgsql immutable security invoker set search_path = ''
as $scanner$
declare
  v_condition text;
begin
  if app_private.has_unsafe_role_guard(p_definition) then
    return true;
  end if;
  for v_condition in
    select m[1]
    from regexp_matches(p_definition, '(if|elsif)[[:space:]]+not[^;]*then', 'gi') as m
  loop
    if v_condition ~* 'app_role[[:space:]]*[(]'
       and v_condition !~* '(if|elsif)[[:space:]]+not[[:space:]]+coalesce[[:space:]]*[(]' then
      return true;
    end if;
  end loop;
  return false;
end
$scanner$;
revoke all on function app_private.sec_prod_has_unsafe_role_guard(text) from public, anon, authenticated, agent_ro;

do $sec_prod_scanner_tests$
begin
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT (app_role() = ''admin'' OR app_role() = ''controller'') THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner failed: parenthesized OR';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    E'ELSIF NOT (\n  public.app_role() = ''admin''\n  OR public.app_role() = ''controller''\n) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner failed: multiline ELSIF';
  end if;
  if app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'' AND app_account_valid(), false) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner rejects canonical null-safe guard';
  end if;
end
$sec_prod_scanner_tests$;

do $sec_prod_postflight$
declare
  v_anon integer;
  v_auth integer;
  v_agent integer;
  v_name text;
  v_views text[] := array['concern_famille_v', 'eleves_en_attente_v', 'mes_affectations_v', 'mes_appareils_v', 'mes_codes_appairage_v', 'mes_groupes_famille_v', 'mes_groupes_v', 'mes_seances_enseignant_v', 'mes_seances_v', 'presence_seance_v', 'profils_du_foyer_v', 'regles_profil_v', 'session_peers_v', 'teacher_roster_v', 'tendance_feedback_v'];
begin
  select count(*) into v_anon from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef and has_function_privilege('anon',p.oid,'EXECUTE');
  if v_anon <> 0 then raise exception 'SEC-PROD: % SECURITY DEFINER restent exécutables par anon', v_anon; end if;
  select count(*) into v_auth from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef and has_function_privilege('authenticated',p.oid,'EXECUTE');
  if v_auth <> 118 then raise exception 'SEC-PROD: nombre inattendu de RPC authenticated (% au lieu de 118)', v_auth; end if;
  select count(*) into v_agent from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef and has_function_privilege('agent_ro',p.oid,'EXECUTE');
  if v_agent <> 46 then raise exception 'SEC-PROD: droits agent_ro inattendus après retrait KYC (% restent)', v_agent; end if;
  if exists (
    select 1 from pg_temp.sec_prod_expected_functions e
    where has_function_privilege('agent_ro', e.signature, 'EXECUTE') is distinct from
      (e.agent_ro_execute and e.signature not in ('public.read_kyc_documents()', 'public.autoriser_lecture_piece_identite(uuid)'))
  ) then raise exception 'SEC-PROD: usage agent_ro non préservé conformément à la matrice'; end if;
  if exists (
    select 1 from pg_temp.sec_prod_expected_functions e
    where has_function_privilege('authenticated', e.signature, 'EXECUTE') is distinct from e.authenticated_execute
  ) then raise exception 'SEC-PROD: usage authenticated non préservé'; end if;
  if not has_function_privilege('agent_ro','public.etat_presence(uuid,uuid)','EXECUTE') then
    raise exception 'SEC-PROD: agent_ro a perdu etat_presence';
  end if;
  foreach v_name in array v_views loop
    if not coalesce((select reloptions @> array['security_invoker=true'] from pg_catalog.pg_class where oid=to_regclass(format('public.%I',v_name))), false) then
      raise exception 'SEC-PROD: vue non invoker: public.%', v_name;
    end if;
    if has_table_privilege('anon',format('public.%I',v_name),'SELECT') then
      raise exception 'SEC-PROD: anon conserve SELECT sur public.%', v_name;
    end if;
    if not has_table_privilege('authenticated',format('public.%I',v_name),'SELECT') then
      raise exception 'SEC-PROD: authenticated a perdu SELECT sur public.%', v_name;
    end if;
  end loop;
  foreach v_name in array array['mes_appareils_v','mes_groupes_famille_v','mes_groupes_v','mes_seances_enseignant_v','teacher_roster_v'] loop
    if has_table_privilege('agent_ro',format('public.%I',v_name),'SELECT') then
      raise exception 'SEC-PROD: agent_ro conserve SELECT sans droits de dépendances sur public.%', v_name;
    end if;
  end loop;
  if has_table_privilege('authenticated','public.kyc_documents','SELECT')
     or has_table_privilege('anon','public.kyc_documents','SELECT')
     or has_table_privilege('agent_ro','public.kyc_documents','SELECT') then
    raise exception 'SEC-PROD: SELECT direct KYC restant';
  end if;
  if exists(select 1 from pg_catalog.pg_policies where schemaname='storage' and tablename='objects' and policyname='kyc_lecture_admin') then
    raise exception 'SEC-PROD: policy Storage KYC lecture encore présente';
  end if;
  if exists(select 1 from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
            where n.nspname in ('public','app_private') and p.prosecdef
              and app_private.sec_prod_has_unsafe_role_guard(p.prosrc)) then
    raise exception 'SEC-PROD M2: garde négative résiduelle';
  end if;
end
$sec_prod_postflight$;

-- Ne modifie ni btree_gist ni l'index sessions_no_teacher_overlap:
-- pg_depend établit que le déplacement requiert une opération séparée et testée.
commit;
