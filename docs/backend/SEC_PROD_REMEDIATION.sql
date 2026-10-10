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
-- Exécution prévue seulement avec psql -v ON_ERROR_STOP=1 -v sec_prod_confirm_ref=gggmtelinlpseweouyav après les gates.
-- La transaction doit pouvoir être entièrement annulée. Ne pas copier dans une migration.
\set ON_ERROR_STOP on
\if :{?sec_prod_confirm_ref}
\else
  \echo 'SEC-PROD refuse: fournir -v sec_prod_confirm_ref=gggmtelinlpseweouyav'
  \quit 3
\endif
select set_config('codex.sec_prod_confirm_ref', :'sec_prod_confirm_ref', false);
begin;
set local search_path = pg_catalog, public, app_private;

-- Verrouiller la cible logique et le catalogue avant toute DDL.
do $sec_prod_preflight$
declare
  v_count integer;
  v_latest_name text;
  v_schema text;
begin
  if current_setting('codex.sec_prod_confirm_ref', true) is distinct from 'gggmtelinlpseweouyav' then
    raise exception 'SEC-PROD: confirmation de projet psql incorrecte';
  end if;
  if current_setting('server_version_num')::integer < 150000 then
    raise exception 'SEC-PROD: PostgreSQL 15+ requis';
  end if;
  if to_regclass('supabase_migrations.schema_migrations') is null then
    raise exception 'SEC-PROD: ledger Supabase absent';
  end if;
  select count(*) into v_count
    from supabase_migrations.schema_migrations;
  select name into v_latest_name
    from supabase_migrations.schema_migrations
   order by version desc
   limit 1;
  if v_count <> 50 or v_latest_name is distinct from '0042_etat_presence_fermee_et_jeton_video_verifie_le_compte' then
    raise exception 'SEC-PROD: ledger inattendu (count=%, latest=%); attendu 50 / 0042_etat_presence_fermee_et_jeton_video_verifie_le_compte', v_count, v_latest_name;
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
  authenticated_execute boolean not null,
  agent_ro_execute boolean not null
) on commit drop;
insert into pg_temp.sec_prod_expected_functions(signature, md5_definition, anon_execute, authenticated_execute, agent_ro_execute) values
  ('public.agent_identite_masquee()', 'd840394e84b8b4c9ba497dffaad20d54', true, true, true),
  ('public.agent_pre_request()', '6b20cd70194775bf54db14725128a3c5', true, true, true),
  ('public.ajouter_eleve_groupe(uuid, uuid, text)', '5c001c226d18ba90fdaf5a7581be9a66', false, true, false),
  ('public.ajouter_niveau_programme(uuid, text, text, text, integer, text)', 'cee5a197b02fbed73038efe1113f45cb', false, true, false),
  ('public.annonce_observation_pour_moi(uuid)', 'a527cfa220e0f6b3af044b1634ea152c', false, true, false),
  ('public.annonces_observation(uuid)', '4c3f4797c0e0a55d197fc4bb701a7300', false, true, false),
  ('public.annuler_evaluation(uuid, text)', '4f9fd8b123ac1e3994921a19839ea657', false, true, false),
  ('public.anomalies_qualite()', 'cc4216e342fc0346371a6980b2399bea', false, true, true),
  ('public.app_account_valid()', '25ef4708ed7b2d0b81a58f3c13675f95', true, true, true),
  ('public.app_config_int(text, integer)', '8e952a7f94ab026e910b91aa34871768', true, true, true),
  ('public.app_household_id()', '542ef88e02409f5373959100cd7a3d0c', true, true, true),
  ('public.app_role()', 'b20471b9c758fed68602f39e075717c1', true, true, true),
  ('public.app_user_id()', '662840b5e2b92eb18413856d550b1af3', true, true, true),
  ('public.attribuer_eleve(uuid, uuid, integer, integer, text)', '0f45793b6620c4126fb8021f9ad85f71', false, true, false),
  ('public.autoriser_ecoute_archive(uuid)', '43b6560d4add3f778326e832a251088c', false, true, false),
  ('public.autoriser_lecture_piece_identite(uuid)', 'f3e4c7db59cc2000fd609e2fbe6f5cf3', false, true, false),
  ('public.brouillon_cahier(uuid)', '6abe6bbcb1515130213fb637cdd5cfb7', false, true, true),
  ('public.budget_observation(uuid)', '390f9c621dccf161c23501b6f7937c22', false, true, false),
  ('public.clore_exception_progression(uuid, text)', 'ee94547ce13af07a6bb3a526c1b93019', false, true, false),
  ('public.clore_regle(uuid, text)', '69c2d22a82d2d06431a75488e9b96aad', false, true, false),
  ('public.cloturer_groupe(uuid, text)', 'c08ce88599444254b4155baff166302f', false, true, false),
  ('public.completer_kyc_document()', '55e4cc15937dcb0b70a28ac0471ef7b8', true, true, false),
  ('public.comptes_admin()', '78817cf3395a6a3c301c91f45934e80f', true, true, true),
  ('public.creer_code_appairage(uuid)', 'ed5103a9093421c68265efdef96ed16b', false, true, false),
  ('public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint)', '97c8c9e666653e03584e0d875ad00c33', true, true, true),
  ('public.creer_groupe(uuid, text, text, smallint, smallint, smallint)', 'd85b1b126ac26ab5628777ee722b71b0', false, true, false),
  ('public.creer_jeton_agent(text, uuid, integer, boolean)', '0084e98d6eada6c376364bfead236b22', false, true, false),
  ('public.creer_profil_inscription(text, text, text, gender, text)', '4564536aa08e2389235fcecf00117611', false, true, false),
  ('public.creer_version_programme(uuid)', 'b72ca828b9c07f40cb69b8a2f6e11de3', false, true, false),
  ('public.decider_demande(uuid, boolean, text)', '7e1986d430bef88eec0dffa29e290acf', false, true, false),
  ('public.decider_dossier(uuid, boolean, text)', '9b1f8d0d3baea020be07d676c34de6e2', false, true, false),
  ('public.decider_placement(uuid, uuid, text)', '57f9459ec3a73dbbc3b6b3dea0a0015d', false, true, false),
  ('public.definir_politique_observation_groupe(uuid, text, smallint, integer, integer)', '967659fc78d48da104daa224138b2de6', false, true, false),
  ('public.demander(text, uuid, text, text, integer)', 'ebb7508bf33843ce0602e66bbcf8dc82', false, true, false),
  ('public.demandes_en_attente()', 'a9003a8e91895e4b6d7674e584a7fe75', false, true, true),
  ('public.derniere_position_groupe(uuid)', '73ddd94f8f873fb5ebed000d501b8ed6', false, true, false),
  ('public.diagnostics_a_traiter()', 'b1294c4ac77aeeb86a308246beb5059d', false, true, true),
  ('public.doit_demander_feedback(uuid)', '03d6f39788bbe7ff8df48985b70ea879', false, true, false),
  ('public.dossiers_en_attente()', 'b31b4fbc58d5a55117b4ed951a3403b5', false, true, true),
  ('public.eleves_sans_enseignant()', 'd3e14512ba428ffec5e9623d8e8bacbd', false, true, true),
  ('public.enregistrer_resultat_evaluation(uuid, text, text)', '4bd65c40df79915136eece059762a525', false, true, false),
  ('public.enseignants_pour(uuid)', 'f2446791e27fe948db4a172470be5940', false, true, true),
  ('public.entrer_observation(uuid, text)', '9da9386bb2c6b2d07eae3fadee3c2010', false, true, false),
  ('public.est_du_foyer(uuid)', 'cf01e3f9efe82d50ca05275ce30428e9', false, true, false),
  ('public.est_observateur_masque(uuid, uuid)', 'a5e13b2fbdbff5a32f21616bb7637fff', false, true, true),
  ('public.etat_dossier()', '8029881e3743ba27d7838fef226813a4', false, true, true),
  ('public.etat_presence(uuid, uuid)', '6915fe061c06c9f5617c7d9e9bf0f051', false, true, true),
  ('public.evaluations_admin()', '71eff9577dda431a05fb4766db2c2032', false, true, true),
  ('public.geler_archive_seance(uuid, text, boolean)', 'cdab571836d441c57694f9bea5099f40', false, true, false),
  ('public.groupe_detail(uuid)', 'dec65463d891f3cef2ec314efebe2051', false, true, true),
  ('public.groupe_roster_enseignant(uuid)', '20212f9b34187cef242bc98ce2fa57a2', false, true, false),
  ('public.groupes_admin()', '948e0562c8ef4086dd00f6fb70c7d1e2', true, true, true),
  ('public.guard_app_config_history()', '99b0223e1ea4211510dab2699c048d9b', true, true, false),
  ('public.guard_assignment_cap()', '8f663d8b6fe5b4e7ceca82229e3ac43b', true, true, false),
  ('public.guard_audit_logs_immutable()', 'a582efceb101d5541fd511cb7c0c7a91', true, true, false),
  ('public.guard_contract_acceptances_immutable()', '572baa09d163a0b386a7a98d7006b02b', true, true, false),
  ('public.guard_devices_max_reactivation()', 'fd517074a8ada2d32fabe95def07ec44', true, true, false),
  ('public.guard_devices_max()', 'f43bd4724f00b05af103bdafcbe8a714', true, true, false),
  ('public.guard_prayer_adjustments()', 'f358ae78bf49c71bf2316a9271c61d78', true, true, false),
  ('public.guard_profile_immutable_id()', '1fff46e37cbb5c465e4109b910b76d1d', true, true, false),
  ('public.guard_profile_privileged_columns()', '0e0b9d7f966e64b2e5182a0a9d5495eb', true, true, false),
  ('public.guard_rule_override_coherente()', '3f5931edc446d04c9cd03fbfd5387052', true, true, false),
  ('public.guard_rule_override_immutable()', '458c3ca2dfc2858b89472aa0e6e988de', true, true, false),
  ('public.guard_session_state_transition()', '6337e0fa1c9f05b12440c7dd66a18b63', true, true, false),
  ('public.horloge_seance(uuid)', '879eb5957f8cabd0f25278807c5e0576', false, true, true),
  ('public.indicateurs_admin()', 'd7e1209572394c2ab6d5f9dae3834aaa', false, true, true),
  ('public.jetons_agent_actifs()', '0712f58e294f778705822aab96d9bea4', false, true, true),
  ('public.journal_audit_filtres()', '49c1360b67ef589d2aaef8468ecc31bc', false, true, true),
  ('public.journal_audit(uuid, text, timestamp with time zone, integer, timestamp with time zone, bigint)', '973fec3923b807963042e424ef181e50', false, true, true),
  ('public.log_sensitive_access(text, text, text, jsonb)', 'f8bd87ae2b78060f31362ccf7697cbc4', false, true, false),
  ('public.maintenant_serveur()', '544d5e02a1e48495e4d4aac532bc498b', false, true, true),
  ('public.maj_eleve_pedagogie(uuid, text, text)', 'f9164b5c4b9a7bbc582ae7675ff94678', false, true, false),
  ('public.maj_profil_enseignant(text, text[], text)', '62a32e47dabb25ff2d1161077944eb83', false, true, false),
  ('public.materialiser_seances(uuid)', '3033a4a29b4fac32a7ba2cc093b5f09b', false, true, false),
  ('public.mes_rapports_en_attente()', 'f5f2f30e05982a7880583244c343dd21', false, true, true),
  ('public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint)', '713d5acca4971058883ea90e06bb6ad4', true, true, true),
  ('public.modifier_groupe(uuid, text, smallint, smallint, smallint)', '5bfb604429ef9b20ac632197218f9784', false, true, false),
  ('public.modifier_niveau_programme(uuid, text, text, integer, text)', 'b61928f62425d1439e3ac806c96a7f8c', false, true, false),
  ('public.mon_fuseau()', 'df015b341503e85ecebe9e57fefb086b', false, true, true),
  ('public.mon_groupe_detail(uuid)', '2a294f40be8845fb7df1b98655ffea78', false, true, true),
  ('public.next_immutable_id(app_role, text)', 'b33f7d92b9211e63497e47240599ce72', false, true, false),
  ('public.partie_concernee(uuid)', '1eb8c65b41d86791b900ab7e40208389', false, true, true),
  ('public.personnes_observables()', '0f42e63032d25873d2658c53ea669399', true, true, true),
  ('public.peut_deposer_piece_identite(uuid)', '363d0e5c384d1dbf1dc9c72765dca799', false, true, true),
  ('public.peut_poser_disponibilite(uuid)', '73be37213e5c5f3ceb6cf11bdcc36605', false, true, true),
  ('public.planifier_evaluation(uuid, uuid, text, date)', 'edeae79dea1ee637962a2f9f68e45968', false, true, false),
  ('public.politique_observation_effective(uuid)', 'fe478b6be57c4b0e11648dedfd6a8417', false, true, false),
  ('public.poser_exception_progression(uuid, text, text)', '476c9fbc67014db1aba74e764b0acf67', false, true, false),
  ('public.poser_regle(uuid, text, integer, text)', 'b42b46c02c394102058503378bc35c6e', false, true, false),
  ('public.prendre_eleve(uuid, integer, integer)', 'b5ac5d0c855282281567be91c3d211c1', false, true, false),
  ('public.preparer_depot_piece_identite(uuid, text)', 'a5f61b7f8dad3d63938248b34ec77934', false, true, false),
  ('public.profil_de_mon_foyer(text)', '9a229eac8bc0751df03eac3693c279d5', true, true, true),
  ('public.programme_niveaux_admin(uuid)', '528cede3db466e4026bd81f48b65abc2', false, true, true),
  ('public.programme_versions_admin()', '0c527e4b9077b9c58db1abd84de39b08', false, true, true),
  ('public.progression_admin()', '68b358b2d8edf96816388202a8abaca9', false, true, true),
  ('public.progression_promouvoir(uuid, uuid, text)', 'e538d880616ae549860df58ebe06b15f', false, true, false),
  ('public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)', 'af005c1a3ad93786c1aed15c0e9fae0b', false, true, false),
  ('public.publier_version_programme(uuid, text)', 'c7715e24d0d338cea4113a3c787580c2', false, true, false),
  ('public.quitter_salle(uuid)', 'c36b13c2df7b623747bb070bfea6279c', false, true, false),
  ('public.read_kyc_documents()', 'cccb3f874b090ea4b6de084ca6ef70ff', false, true, true),
  ('public.record_session_event(uuid, uuid, session_event_type, text)', '380de00d3a207f33eee34e98c9287a4c', false, true, false),
  ('public.regle_effective(uuid, text)', '778d4a4cde1a262d94e15cf74931130d', false, true, true),
  ('public.rejoindre_observation(uuid)', '11297b9563e6816b369cf55bc842af5e', false, true, false),
  ('public.ressources_du_groupe(uuid)', '7f3868abf037296891b446a5ff3a83ee', false, true, true),
  ('public.retirer_eleve_groupe(uuid, uuid, text)', 'fcf523b2cdbebec969a5e2253de26aba', false, true, false),
  ('public.revoquer_appareil(uuid)', '94514a938b71c72c9c480554c0ac6bb1', false, true, false),
  ('public.revoquer_jeton_agent(uuid)', 'fc536a7b55da1011ebd638ca0c269206', false, true, false),
  ('public.rls_auto_enable()', '6998ea6b4c2480f5d2e34b5dcf3f8d36', true, true, false),
  ('public.session_belongs_to_teacher(uuid, uuid)', '92f8a2b8ccf6814a0226c9ae2c339387', false, true, true),
  ('public.session_has_participant(uuid, uuid)', 'c72c6cbc12f9af1c5e7e1ff64adec966', false, true, true),
  ('public.session_in_household(uuid, uuid)', '146fb204821facbc32ef2013fd421758', false, true, true),
  ('public.sortir_observation(uuid)', '51afae46db2d837c08fb32f7b8671aac', false, true, false),
  ('public.supprimer_niveau_programme(uuid, text)', '21449ed510bae1e51bd71972989b0fa7', false, true, false),
  ('public.traiter_anomalie_qualite(text, uuid, text)', '8a78c8c8605e0bad66f15f62f406462b', false, true, false),
  ('public.transitions_fuseau_a_venir(integer)', 'c90a4ebcfe6a2f303dac10960cabddff', false, true, false),
  ('public.verifier_chaine_audit(integer)', 'cf28eb75e08bd5cdd0cb8d18067c720b', false, true, true),
  ('public.video_config_lire()', '4af82d0a2db1602453eeeaf40a10e9cc', false, true, true),
  ('public.visites_observation(uuid)', 'fac9c7bb4194a98c08c7455afc18cd6c', false, true, false);

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

-- Preflight strict des 15 vues : définitions, owner, options, ACL directes
-- et SELECT effectif doivent correspondre exactement au snapshot.
-- Expected view definitions, ACLs and options from the exact PROD snapshot.
create temporary table sec_prod_expected_views (
  view_name text primary key,
  md5_definition text not null,
  expected_relacl text not null,
  expected_reloptions text[] not null,
  expected_owner text not null,
  anon_select boolean not null,
  authenticated_select boolean not null,
  agent_ro_select boolean not null
) on commit drop;
insert into pg_temp.sec_prod_expected_views values
  ('concern_famille_v', 'cbdc1455db6cdd936d41856517ec2c21', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, false),
  ('eleves_en_attente_v', '5f909b7adbbf0feb38146f9364c2468f', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('mes_affectations_v', '618110777250838d10c04ddb79da304c', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('mes_appareils_v', '0c7c334a9070e9cc43d0262bc4c34ad0', '{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', true, true, true),
  ('mes_codes_appairage_v', '8ea8a6236f2cf66f3bd03229bc706b04', '{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', true, true, true),
  ('mes_groupes_famille_v', 'b75cd7b1fe443df98d3b49e697a9910b', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('mes_groupes_v', '10ae29f7162b67873fb9fe39a0077fbc', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('mes_seances_enseignant_v', 'dfcbf379090a7265d98786e2da48e799', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('mes_seances_v', 'ebbdd7b2516aab5514fcceccd0320361', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('presence_seance_v', '87730d907d7210e4fe6b9cbc830b904e', '{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', true, true, true),
  ('profils_du_foyer_v', 'de6bcd8b1ff623fffa10c735248b8909', '{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', true, true, true),
  ('regles_profil_v', 'c3a01cde33501e90fdb1c50a5e6dbe48', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('session_peers_v', '4dba47724f45f172d362643972e272e4', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array[]::text[], 'postgres', false, true, true),
  ('teacher_roster_v', '44ffcb9c5828d4c36036a3f78f0d8792', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres,agent_ro=r/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, true),
  ('tendance_feedback_v', '824d982444d0e62643af53159cfc2429', '{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}', array['security_barrier=true']::text[], 'postgres', false, true, false);

do $sec_prod_views_preflight$
declare
  r record;
  v_oid oid;
  v_kind "char";
  v_md5 text;
  v_relacl text;
  v_reloptions text;
  v_owner text;
begin
  if (select count(*) from pg_temp.sec_prod_expected_views) <> 15 then
    raise exception 'SEC-PROD: matrice des vues incomplète';
  end if;
  for r in select * from pg_temp.sec_prod_expected_views order by view_name loop
    v_oid := to_regclass(format('public.%I', r.view_name));
    if v_oid is null then raise exception 'SEC-PROD: vue absente: public.%', r.view_name; end if;
    select relkind, md5(pg_get_viewdef(c.oid, true)), coalesce(c.relacl::text, ''),
           coalesce(array_to_string(c.reloptions, ','), ''), pg_get_userbyid(c.relowner)
      into v_kind, v_md5, v_relacl, v_reloptions, v_owner
      from pg_catalog.pg_class c where c.oid = v_oid;
    if v_kind <> 'v' then raise exception 'SEC-PROD: objet remplacé (relkind=%): public.%', v_kind, r.view_name; end if;
    if v_md5 is distinct from r.md5_definition then raise exception 'SEC-PROD: définition différente du snapshot: public.%', r.view_name; end if;
    if v_owner is distinct from r.expected_owner then raise exception 'SEC-PROD: owner différent du snapshot: public.%', r.view_name; end if;
    if v_relacl is distinct from r.expected_relacl then raise exception 'SEC-PROD: ACL directe différente du snapshot: public.%', r.view_name; end if;
    if v_reloptions is distinct from array_to_string(r.expected_reloptions, ',') then raise exception 'SEC-PROD: options différentes du snapshot: public.%', r.view_name; end if;
    if has_table_privilege('anon', v_oid, 'SELECT') is distinct from r.anon_select
       or has_table_privilege('authenticated', v_oid, 'SELECT') is distinct from r.authenticated_select
       or has_table_privilege('agent_ro', v_oid, 'SELECT') is distinct from r.agent_ro_select then
      raise exception 'SEC-PROD: SELECT effectif différent du snapshot: public.%', r.view_name;
    end if;
    if r.expected_reloptions @> array['security_invoker=true'] then
      raise exception 'SEC-PROD: vue déjà security_invoker: public.%', r.view_name;
    end if;
  end loop;
end
$sec_prod_views_preflight$;

-- Transformations gardes positives/null-safe issues de 0074.
-- 0074 — convertir les comparaisons de rôles négatives en gardes positives.
-- Le balayage couvre les fonctions SECURITY DEFINER de public et app_private,
-- sans dépendre d'une forme IF sur une seule ligne. Une comparaison non
-- transformée fait échouer la migration.
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

-- Cette voie enseignant contourne le comparateur rôle seul : le helper ne vérifie que
-- teacher_id et deleted_at. Exiger explicitement rôle, propriété de séance et compte actif.
do $sec_prod_teacher_publish_guard$
declare
  v_oid oid;
  v_definition text;
  v_corrected text;
  v_source text;
  v_normalized text;
  v_pattern text := $pattern$(?i)if[[:space:]]+not[[:space:]]+public[.]session_belongs_to_teacher[[:space:]]*[(][[:space:]]*p_session_id[[:space:]]*,[[:space:]]*auth[.]uid[[:space:]]*[(][[:space:]]*[)][[:space:]]*[)][[:space:]]+and[[:space:]]+public[.]app_role[[:space:]]*[(][[:space:]]*[)][[:space:]]*<>[[:space:]]*'admin'[[:space:]]+then$pattern$;
  v_guard text := $guard$IF NOT COALESCE(((public.app_role() = 'teacher' AND public.session_belongs_to_teacher(p_session_id, auth.uid())) OR public.app_role() = 'admin') AND public.app_account_valid(), false) THEN$guard$;
  v_matches integer;
begin
  v_oid := to_regprocedure('public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)');
  if v_oid is null
     or md5(pg_get_functiondef(v_oid)) is distinct from
        (select md5_definition from pg_temp.sec_prod_expected_functions
          where signature = 'public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)') then
    raise exception 'SEC-PROD M2: définition non conforme avant garde publier_etat_partage';
  end if;
  v_definition := pg_get_functiondef(v_oid);
  select count(*) into v_matches from regexp_matches(v_definition, v_pattern, 'gi');
  if v_matches <> 1 then
    raise exception 'SEC-PROD M2: garde teacher/admin attendue exactement une fois dans publier_etat_partage (trouvé %)', v_matches;
  end if;
  v_corrected := regexp_replace(v_definition, v_pattern, v_guard, 'gi');
  if v_corrected = v_definition
     or app_private.has_unsafe_role_guard(v_corrected) then
    raise exception 'SEC-PROD M2: garde publier_etat_partage non transformée';
  end if;
  execute v_corrected;
  select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid = v_oid;
  v_normalized := regexp_replace(lower(v_source), '[[:space:]]+', ' ', 'g');
  if strpos(v_normalized, lower(v_guard)) = 0 then
    raise exception 'SEC-PROD M2: garde positive publier_etat_partage absente après réécriture';
  end if;
end
$sec_prod_teacher_publish_guard$;

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


-- Scanner M2 fail-closed: masquer commentaires et chaînes avant d'examiner
-- les conditions; les littéraux sont remplacés par 'x' pour conserver la forme
-- des comparaisons de rôle sans interpréter leur contenu comme du SQL.
create or replace function app_private.sec_prod_has_unsafe_role_guard(p_definition text)
returns boolean
language plpgsql
stable
security invoker
set search_path = ''
as $scanner$
declare
  v_clean text := '';
  v_state text := 'code';
  v_input text := coalesce(p_definition, '');
  v_length integer := length(coalesce(p_definition, ''));
  v_i integer := 1;
  v_depth integer := 0;
  v_char text;
  v_next text;
  v_tag text;
  v_condition text;
  v_lower text;
  v_compact text;
  v_role_pos integer;
  v_account_pos integer;
  v_coalesce_pos integer;
  v_open_pos integer;
  v_close_pos integer;
  v_backslash_escape boolean := false;
begin
  -- Masquage lexical : commentaires SQL (y compris blocs imbriqués),
  -- chaînes simples et dollar-quoted. Les identifiants cités sont conservés.
  while v_i <= v_length loop
    v_char := substring(v_input from v_i for 1);
    v_next := substring(v_input from v_i + 1 for 1);

    if v_state = 'code' then
      if v_char = '-' and v_next = '-' then
        v_clean := v_clean || '  ';
        v_state := 'line_comment';
        v_i := v_i + 2;
        continue;
      elsif v_char = '/' and v_next = '*' then
        v_clean := v_clean || '  ';
        v_state := 'block_comment';
        v_depth := 1;
        v_i := v_i + 2;
        continue;
      elsif v_char = chr(39) then
        if lower(substring(v_input from v_i - 1 for 1)) = 'e'
           and (v_i <= 2 or substring(v_input from v_i - 2 for 1) !~ '[[:alnum:]_$]') then
          v_backslash_escape := true;
        elsif current_setting('standard_conforming_strings', true) = 'off' then
          v_backslash_escape := true;
        elsif current_setting('standard_conforming_strings', true) = 'on' then
          v_backslash_escape := false;
        else
          return true;
        end if;
        v_clean := v_clean || chr(39) || 'x' || chr(39);
        v_state := 'single_quote';
        v_i := v_i + 1;
        continue;
      elsif v_char = '"' then
        v_state := 'double_quote';
        v_i := v_i + 1;
        continue;
      elsif v_char = ' and (v_i = 1 or substring(v_input from v_i - 1 for 1) !~ '[[:alnum:]_$]') then
        v_tag := substring(substring(v_input from v_i) from '^\$[[:alnum:]_]*\$');
        if coalesce(v_tag, '') <> '' then
          v_clean := v_clean || chr(39) || 'x' || chr(39);
          v_state := 'dollar_quote';
          v_i := v_i + length(v_tag);
          continue;
        end if;
      end if;
      v_clean := v_clean || v_char;
      v_i := v_i + 1;

    elsif v_state = 'line_comment' then
      if v_char = chr(10) or v_char = chr(13) then
        v_clean := v_clean || v_char;
        v_state := 'code';
      else
        v_clean := v_clean || ' ';
      end if;
      v_i := v_i + 1;

    elsif v_state = 'block_comment' then
      if v_char = '/' and v_next = '*' then
        v_clean := v_clean || '  ';
        v_depth := v_depth + 1;
        v_i := v_i + 2;
      elsif v_char = '*' and v_next = '/' then
        v_clean := v_clean || '  ';
        v_depth := v_depth - 1;
        v_i := v_i + 2;
        if v_depth = 0 then
          v_state := 'code';
        end if;
      else
        v_clean := v_clean || case when v_char in (chr(10), chr(13)) then v_char else ' ' end;
        v_i := v_i + 1;
      end if;

    elsif v_state = 'single_quote' then
      if v_backslash_escape and v_char = chr(92) and v_i < v_length then
        v_i := v_i + 2;
      elsif v_char = chr(39) and v_next = chr(39) then
        v_i := v_i + 2;
      elsif v_char = chr(39) then
        v_state := 'code';
        v_i := v_i + 1;
      else
        v_i := v_i + 1;
      end if;

    elsif v_state = 'double_quote' then
      if v_char = '"' and v_next = '"' then
        v_clean := v_clean || '"';
        v_i := v_i + 2;
      elsif v_char = '"' then
        v_state := 'code';
        v_i := v_i + 1;
      else
        v_clean := v_clean || v_char;
        v_i := v_i + 1;
      end if;

    elsif v_state = 'dollar_quote' then
      if substring(v_input from v_i for length(v_tag)) = v_tag then
        v_state := 'code';
        v_i := v_i + length(v_tag);
      else
        v_i := v_i + 1;
      end if;
    end if;
  end loop;

  if app_private.has_unsafe_role_guard(v_clean) then
    return true;
  end if;

  for v_condition in
    select m[1]
    from regexp_matches(v_clean, '((if|elsif)[[:space:]]+[^;]*?then)', 'gi') as m
  loop
    if v_condition ~* 'app_role[[:space:]]*[(]'
       and v_condition ~* 'not' then
      v_lower := lower(v_condition);
      v_compact := regexp_replace(v_lower, '[[:space:]]+', '', 'g');
      v_role_pos := strpos(v_compact, 'app_role()');
      v_account_pos := strpos(v_compact, 'app_account_valid()');
      v_coalesce_pos := strpos(v_compact, 'coalesce(');
      v_close_pos := 0;
      v_depth := 1;
      v_i := v_coalesce_pos + length('coalesce(');

      while v_i <= length(v_compact) loop
        v_char := substring(v_compact from v_i for 1);
        if v_char = '(' then
          v_depth := v_depth + 1;
        elsif v_char = ')' then
          v_depth := v_depth - 1;
          if v_depth = 0 then
            v_close_pos := v_i;
            exit;
          end if;
        end if;
        v_i := v_i + 1;
      end loop;

       if v_coalesce_pos = 0
          or v_role_pos = 0
          or v_account_pos = 0
          or v_close_pos = 0
          or lower(btrim(substring(v_compact from v_close_pos + 1))) <> 'then'
          or v_compact ~ 'app_role\(\)=''x''(=false|isfalse|isnottrue)'
          or v_compact ~ 'coalesce\([^)]*not(public\.)?app_role\('
          or v_compact !~ '(^|[^[:alnum:]_$])(public\.)?app_role\(\)(=''x''|in\(''x''(,''x'')*\))'
          or v_compact !~ '(^|[^[:alnum:]_$])(public\.)?app_account_valid\(\)'
          or v_compact ~ '(and|or)not(public\.)?app_account_valid\(\)'
          or (
            v_compact ~ '(^|[^[:alnum:]_])or([^[:alnum:]_]|$)'
            and v_compact <> 'ifnotcoalesce(((public.app_role()=''x''andpublic.session_belongs_to_teacher(p_session_id,auth.uid()))orpublic.app_role()=''x'')andpublic.app_account_valid(),false)then'
          ) then
         return true;
       end if;
    end if;
  end loop;
  return false;
end
$scanner$;
revoke all on function app_private.sec_prod_has_unsafe_role_guard(text) from public, anon, authenticated, agent_ro;

-- 0084 révoque agent_ro d'etat_presence malgré son accès effectif dans le snapshot.
-- Le rôle garde cette RPC non-KYC; 0081 retire l'accès KYC effectivement présent sur read_kyc_documents().
grant execute on function public.etat_presence(uuid, uuid) to agent_ro;

-- Révoquer anon/PUBLIC sur les 27 SECURITY DEFINER exposées; conserver explicitement
-- les accès effectifs existants de authenticated (118) et agent_ro (48) ci-dessus.
revoke all on function public.agent_identite_masquee() from public, anon;
revoke all on function public.agent_pre_request() from public;
grant execute on function public.agent_pre_request() to anon;
revoke all on function public.app_account_valid() from public, anon;
revoke all on function public.app_config_int(text, integer) from public, anon;
revoke all on function public.app_household_id() from public, anon;
revoke all on function public.app_role() from public, anon;
revoke all on function public.app_user_id() from public, anon;
revoke all on function public.completer_kyc_document() from public, anon;
revoke all on function public.comptes_admin() from public, anon;
revoke all on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint) from public, anon;
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
revoke all on function public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint) from public, anon;
revoke all on function public.personnes_observables() from public, anon;
revoke all on function public.profil_de_mon_foyer(text) from public, anon;
revoke all on function public.rls_auto_enable() from public, anon;
grant execute on function public.agent_identite_masquee() to authenticated;
grant execute on function public.agent_pre_request() to authenticated;
grant execute on function public.ajouter_eleve_groupe(uuid, uuid, text) to authenticated;
grant execute on function public.ajouter_niveau_programme(uuid, text, text, text, integer, text) to authenticated;
grant execute on function public.annonce_observation_pour_moi(uuid) to authenticated;
grant execute on function public.annonces_observation(uuid) to authenticated;
grant execute on function public.annuler_evaluation(uuid, text) to authenticated;
grant execute on function public.anomalies_qualite() to authenticated;
grant execute on function public.app_account_valid() to authenticated;
grant execute on function public.app_config_int(text, integer) to authenticated;
grant execute on function public.app_household_id() to authenticated;
grant execute on function public.app_role() to authenticated;
grant execute on function public.app_user_id() to authenticated;
grant execute on function public.attribuer_eleve(uuid, uuid, integer, integer, text) to authenticated;
grant execute on function public.autoriser_ecoute_archive(uuid) to authenticated;
grant execute on function public.autoriser_lecture_piece_identite(uuid) to authenticated;
grant execute on function public.brouillon_cahier(uuid) to authenticated;
grant execute on function public.budget_observation(uuid) to authenticated;
grant execute on function public.clore_exception_progression(uuid, text) to authenticated;
grant execute on function public.clore_regle(uuid, text) to authenticated;
grant execute on function public.cloturer_groupe(uuid, text) to authenticated;
grant execute on function public.completer_kyc_document() to authenticated;
grant execute on function public.comptes_admin() to authenticated;
grant execute on function public.creer_code_appairage(uuid) to authenticated;
grant execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint) to authenticated;
grant execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint) to authenticated;
grant execute on function public.creer_jeton_agent(text, uuid, integer, boolean) to authenticated;
grant execute on function public.creer_profil_inscription(text, text, text, gender, text) to authenticated;
grant execute on function public.creer_version_programme(uuid) to authenticated;
grant execute on function public.decider_demande(uuid, boolean, text) to authenticated;
grant execute on function public.decider_dossier(uuid, boolean, text) to authenticated;
grant execute on function public.decider_placement(uuid, uuid, text) to authenticated;
grant execute on function public.definir_politique_observation_groupe(uuid, text, smallint, integer, integer) to authenticated;
grant execute on function public.demander(text, uuid, text, text, integer) to authenticated;
grant execute on function public.demandes_en_attente() to authenticated;
grant execute on function public.derniere_position_groupe(uuid) to authenticated;
grant execute on function public.diagnostics_a_traiter() to authenticated;
grant execute on function public.doit_demander_feedback(uuid) to authenticated;
grant execute on function public.dossiers_en_attente() to authenticated;
grant execute on function public.eleves_sans_enseignant() to authenticated;
grant execute on function public.enregistrer_resultat_evaluation(uuid, text, text) to authenticated;
grant execute on function public.enseignants_pour(uuid) to authenticated;
grant execute on function public.entrer_observation(uuid, text) to authenticated;
grant execute on function public.est_du_foyer(uuid) to authenticated;
grant execute on function public.est_observateur_masque(uuid, uuid) to authenticated;
grant execute on function public.etat_dossier() to authenticated;
grant execute on function public.etat_presence(uuid, uuid) to authenticated;
grant execute on function public.evaluations_admin() to authenticated;
grant execute on function public.geler_archive_seance(uuid, text, boolean) to authenticated;
grant execute on function public.groupe_detail(uuid) to authenticated;
grant execute on function public.groupe_roster_enseignant(uuid) to authenticated;
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
grant execute on function public.horloge_seance(uuid) to authenticated;
grant execute on function public.indicateurs_admin() to authenticated;
grant execute on function public.jetons_agent_actifs() to authenticated;
grant execute on function public.journal_audit_filtres() to authenticated;
grant execute on function public.journal_audit(uuid, text, timestamp with time zone, integer, timestamp with time zone, bigint) to authenticated;
grant execute on function public.log_sensitive_access(text, text, text, jsonb) to authenticated;
grant execute on function public.maintenant_serveur() to authenticated;
grant execute on function public.maj_eleve_pedagogie(uuid, text, text) to authenticated;
grant execute on function public.maj_profil_enseignant(text, text[], text) to authenticated;
grant execute on function public.materialiser_seances(uuid) to authenticated;
grant execute on function public.mes_rapports_en_attente() to authenticated;
grant execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint) to authenticated;
grant execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint) to authenticated;
grant execute on function public.modifier_niveau_programme(uuid, text, text, integer, text) to authenticated;
grant execute on function public.mon_fuseau() to authenticated;
grant execute on function public.mon_groupe_detail(uuid) to authenticated;
grant execute on function public.next_immutable_id(app_role, text) to authenticated;
grant execute on function public.partie_concernee(uuid) to authenticated;
grant execute on function public.personnes_observables() to authenticated;
grant execute on function public.peut_deposer_piece_identite(uuid) to authenticated;
grant execute on function public.peut_poser_disponibilite(uuid) to authenticated;
grant execute on function public.planifier_evaluation(uuid, uuid, text, date) to authenticated;
grant execute on function public.politique_observation_effective(uuid) to authenticated;
grant execute on function public.poser_exception_progression(uuid, text, text) to authenticated;
grant execute on function public.poser_regle(uuid, text, integer, text) to authenticated;
grant execute on function public.prendre_eleve(uuid, integer, integer) to authenticated;
grant execute on function public.preparer_depot_piece_identite(uuid, text) to authenticated;
grant execute on function public.profil_de_mon_foyer(text) to authenticated;
grant execute on function public.programme_niveaux_admin(uuid) to authenticated;
grant execute on function public.programme_versions_admin() to authenticated;
grant execute on function public.progression_admin() to authenticated;
grant execute on function public.progression_promouvoir(uuid, uuid, text) to authenticated;
grant execute on function public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer) to authenticated;
grant execute on function public.publier_version_programme(uuid, text) to authenticated;
grant execute on function public.quitter_salle(uuid) to authenticated;
grant execute on function public.read_kyc_documents() to authenticated;
grant execute on function public.record_session_event(uuid, uuid, session_event_type, text) to authenticated;
grant execute on function public.regle_effective(uuid, text) to authenticated;
grant execute on function public.rejoindre_observation(uuid) to authenticated;
grant execute on function public.ressources_du_groupe(uuid) to authenticated;
grant execute on function public.retirer_eleve_groupe(uuid, uuid, text) to authenticated;
grant execute on function public.revoquer_appareil(uuid) to authenticated;
grant execute on function public.revoquer_jeton_agent(uuid) to authenticated;
grant execute on function public.rls_auto_enable() to authenticated;
grant execute on function public.session_belongs_to_teacher(uuid, uuid) to authenticated;
grant execute on function public.session_has_participant(uuid, uuid) to authenticated;
grant execute on function public.session_in_household(uuid, uuid) to authenticated;
grant execute on function public.sortir_observation(uuid) to authenticated;
grant execute on function public.supprimer_niveau_programme(uuid, text) to authenticated;
grant execute on function public.traiter_anomalie_qualite(text, uuid, text) to authenticated;
grant execute on function public.transitions_fuseau_a_venir(integer) to authenticated;
grant execute on function public.verifier_chaine_audit(integer) to authenticated;
grant execute on function public.video_config_lire() to authenticated;
grant execute on function public.visites_observation(uuid) to authenticated;
grant execute on function public.agent_identite_masquee() to agent_ro;
grant execute on function public.agent_pre_request() to agent_ro;
grant execute on function public.anomalies_qualite() to agent_ro;
grant execute on function public.app_account_valid() to agent_ro;
grant execute on function public.app_config_int(text, integer) to agent_ro;
grant execute on function public.app_household_id() to agent_ro;
grant execute on function public.app_role() to agent_ro;
grant execute on function public.app_user_id() to agent_ro;
grant execute on function public.brouillon_cahier(uuid) to agent_ro;
grant execute on function public.comptes_admin() to agent_ro;
grant execute on function public.creer_groupe(uuid, text, text, smallint, smallint, smallint, text, smallint) to agent_ro;
grant execute on function public.demandes_en_attente() to agent_ro;
grant execute on function public.diagnostics_a_traiter() to agent_ro;
grant execute on function public.dossiers_en_attente() to agent_ro;
grant execute on function public.eleves_sans_enseignant() to agent_ro;
grant execute on function public.enseignants_pour(uuid) to agent_ro;
grant execute on function public.est_observateur_masque(uuid, uuid) to agent_ro;
grant execute on function public.etat_dossier() to agent_ro;
grant execute on function public.etat_presence(uuid, uuid) to agent_ro;
grant execute on function public.evaluations_admin() to agent_ro;
grant execute on function public.groupe_detail(uuid) to agent_ro;
grant execute on function public.groupes_admin() to agent_ro;
grant execute on function public.horloge_seance(uuid) to agent_ro;
grant execute on function public.indicateurs_admin() to agent_ro;
grant execute on function public.jetons_agent_actifs() to agent_ro;
grant execute on function public.journal_audit_filtres() to agent_ro;
grant execute on function public.journal_audit(uuid, text, timestamp with time zone, integer, timestamp with time zone, bigint) to agent_ro;
grant execute on function public.maintenant_serveur() to agent_ro;
grant execute on function public.mes_rapports_en_attente() to agent_ro;
grant execute on function public.modifier_groupe(uuid, text, smallint, smallint, smallint, text, smallint) to agent_ro;
grant execute on function public.mon_fuseau() to agent_ro;
grant execute on function public.mon_groupe_detail(uuid) to agent_ro;
grant execute on function public.partie_concernee(uuid) to agent_ro;
grant execute on function public.personnes_observables() to agent_ro;
grant execute on function public.peut_deposer_piece_identite(uuid) to agent_ro;
grant execute on function public.peut_poser_disponibilite(uuid) to agent_ro;
grant execute on function public.profil_de_mon_foyer(text) to agent_ro;
grant execute on function public.programme_niveaux_admin(uuid) to agent_ro;
grant execute on function public.programme_versions_admin() to agent_ro;
grant execute on function public.progression_admin() to agent_ro;
grant execute on function public.read_kyc_documents() to agent_ro;
grant execute on function public.regle_effective(uuid, text) to agent_ro;
grant execute on function public.ressources_du_groupe(uuid) to agent_ro;
grant execute on function public.session_belongs_to_teacher(uuid, uuid) to agent_ro;
grant execute on function public.session_has_participant(uuid, uuid) to agent_ro;
grant execute on function public.session_in_household(uuid, uuid) to agent_ro;
grant execute on function public.verifier_chaine_audit(integer) to agent_ro;
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



-- M2: la null-sécurité du rôle ne remplace pas la validité du compte.
-- Ces deux RPC restaient accessibles avec un JWT admin devenu invalide.
-- Le snapshot hashé ci-dessus protège le patch ciblé contre une dérive de définition.
do $sec_prod_account_validity$
declare
  r record;
  v_oid oid;
  v_definition text;
  v_corrected text;
  v_old text := 'if not coalesce(public.app_role() = ''admin'', false) then';
  v_new text := 'if not coalesce(public.app_role() = ''admin'' and public.app_account_valid(), false) then';
  v_count integer := 0;
  v_matches integer;
begin
  for r in
    select signature, md5_definition
      from pg_temp.sec_prod_expected_functions
     where signature in (
       'public.dossiers_en_attente()',
       'public.geler_archive_seance(uuid, text, boolean)'
     )
     order by signature
  loop
    v_oid := to_regprocedure(r.signature);
    if v_oid is null or md5(pg_get_functiondef(v_oid)) <> r.md5_definition then
      raise exception 'SEC-PROD M2: définition non conforme avant validité compte: %', r.signature;
    end if;
    v_definition := pg_get_functiondef(v_oid);
    v_matches := (length(v_definition) - length(replace(v_definition, v_old, ''))) / length(v_old);
    if v_matches <> 1 then
      raise exception 'SEC-PROD M2: garde admin attendue exactement une fois dans % (trouvé %)', r.signature, v_matches;
    end if;
    v_corrected := replace(v_definition, v_old, v_new);
    execute v_corrected;
    v_count := v_count + 1;
  end loop;
  if v_count <> 2 then
    raise exception 'SEC-PROD M2: nombre de gardes de compte corrigées inattendu (%)', v_count;
  end if;
end
$sec_prod_account_validity$;

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
    'IF NOT coalesce(app_role() = ''admin)'' AND app_account_valid(), false) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner mishandles parentheses inside a SQL string literal';
  end if;
  if app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'' AND app_account_valid(), false) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner rejects canonical null-safe guard';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'' AND NOT app_account_valid(), false) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed negated account-validity conjunct';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'', false) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed missing account-validity check';
  end if;
  if app_private.sec_prod_has_unsafe_role_guard(
    E'IF NOT coalesce(\n  auth.uid() IS NOT NULL\n  AND v_seance.teacher_id = auth.uid()\n  AND public.app_role() = ''teacher''\n  AND public.app_account_valid(),\n  false\n) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner rejects a null-safe role guard with restrictive identity conjuncts';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = ''teacher'' AND public.app_account_valid(), false) OR public.app_role() = ''admin'' THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed OR outside a null-safe role guard';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'' /* (app_account_valid(), false) */, false) THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed account guard hidden only in a comment';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'' AND app_account_valid(), false) AND false THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed a boolean tail outside COALESCE';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF NOT coalesce(app_role() = ''admin'' AND app_account_valid(), false) AND app_role() = ''admin'' THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed role logic outside the null-safe guard';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF (NOT app_role() = ''admin'') THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed parenthesized unary NOT';
  end if;
  if not app_private.sec_prod_has_unsafe_role_guard(
    'IF app_account_valid() AND NOT (app_role() = ''admin'') THEN RAISE; END IF;'
  ) then
    raise exception 'SEC-PROD M2 scanner missed NOT after a boolean operator';
  end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     'IF NOT COALESCE(NOT public.app_role() = ''admin'' AND public.app_account_valid(), false) THEN RAISE; END IF;'
   ) then
     raise exception 'SEC-PROD M2 scanner missed nested NOT inside COALESCE';
   end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     'IF NOT COALESCE(public.app_role() = ''admin'' = false AND public.app_account_valid(), false) THEN RAISE; END IF;'
   ) then
     raise exception 'SEC-PROD M2 scanner missed role equality to false';
   end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     'IF NOT COALESCE(public.app_role() = ''admin'' IS FALSE AND public.app_account_valid(), false) THEN RAISE; END IF;'
   ) then
     raise exception 'SEC-PROD M2 scanner missed IS FALSE role predicate';
   end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     'IF NOT COALESCE(public.app_role() = ''admin'' IS NOT TRUE AND public.app_account_valid(), false) THEN RAISE; END IF;'
   ) then
     raise exception 'SEC-PROD M2 scanner missed IS NOT TRUE role predicate';
   end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     'IF NOT COALESCE(public.app_role() = ''admin'' AND public.fake_app_account_valid(), false) THEN RAISE; END IF;'
   ) then
     raise exception 'SEC-PROD M2 scanner accepted fake_app_account_valid';
   end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     $probe$v$t$ := 1; IF NOT public.app_role() = 'admin' THEN RAISE; END IF;$probe$
   ) then
     raise exception 'SEC-PROD M2 scanner missed dollar delimiter inside identifier';
   end if;
   if not app_private.sec_prod_has_unsafe_role_guard(
     $probe$v := 'x\'; IF NOT public.app_role() = 'admin' THEN RAISE; END IF; w := 'y';$probe$
   ) then
     raise exception 'SEC-PROD M2 scanner mishandled standard_conforming_strings=on';
   end if;
end
$sec_prod_scanner_tests$;

-- The audit writer accepts caller-supplied fields. Its 47 current callers are
-- SECURITY DEFINER functions owned by postgres, so they retain owner execution;
-- authenticated clients must not be able to forge or flood audit entries.
revoke all on function public.log_sensitive_access(text, text, text, jsonb) from authenticated;

-- M2: guard read RPCs and SQL helpers against suspended accounts.
-- Wrap complete predicates so an OR branch cannot bypass account validity.
do $sec_prod_active_read_guards$
declare
  r record; v_oid oid; v_definition text; v_source text;
  v_corrected_source text; v_corrected_definition text;
  v_old text; v_new text; v_matches integer; v_seen integer:=0; v_policy text;
begin
  for r in select signature,md5_definition from pg_temp.sec_prod_expected_functions
   where signature in ('public.derniere_position_groupe(uuid)','public.visites_observation(uuid)','public.partie_concernee(uuid)','public.peut_poser_disponibilite(uuid)')
   order by signature
  loop
    v_oid:=to_regprocedure(r.signature);
    if v_oid is null or md5(pg_get_functiondef(v_oid)) is distinct from r.md5_definition then raise exception 'SEC-PROD M2: définition inattendue: %',r.signature; end if;
    v_definition:=pg_get_functiondef(v_oid);
    select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid=v_oid;
    if r.signature='public.derniere_position_groupe(uuid)' then
      v_old:='if not v_autorise then'; v_new:='if not coalesce(public.app_account_valid() and v_autorise, false) then';
      v_matches:=(length(v_definition)-length(replace(v_definition,v_old,'')))/length(v_old);
      if v_matches<>1 then raise exception 'SEC-PROD M2: garde groupe occurrence %',v_matches; end if;
      v_corrected_definition:=replace(v_definition,v_old,v_new);
    elsif r.signature='public.visites_observation(uuid)' then
      v_old:='where v.session_id = p_session_id'; v_new:='where public.app_account_valid() and v.session_id = p_session_id';
      v_matches:=(length(v_definition)-length(replace(v_definition,v_old,'')))/length(v_old);
      if v_matches<>1 then raise exception 'SEC-PROD M2: filtre visite occurrence %',v_matches; end if;
      v_corrected_definition:=replace(v_definition,v_old,v_new);
    else
      if v_source !~* '^[[:space:]]*select[[:space:]]+' or v_source !~ ';[[:space:]]*$' then raise exception 'SEC-PROD M2: forme SQL inattendue: %',r.signature; end if;
      v_corrected_source:=regexp_replace(v_source,'^[[:space:]]*select[[:space:]]+','select coalesce(public.app_account_valid() and (','i');
      v_corrected_source:=regexp_replace(v_corrected_source,';[[:space:]]*$','), false);');
      if v_corrected_source is not distinct from v_source
       or v_corrected_source !~* '^[[:space:]]*select[[:space:]]+coalesce[[:space:]]*[(][[:space:]]*public[.]app_account_valid[[:space:]]*[(][[:space:]]*[)][[:space:]]+and[[:space:]]*[(]'
       or v_corrected_source !~ '[)][[:space:]]*,[[:space:]]*false[)][[:space:]]*;[[:space:]]*$' then raise exception 'SEC-PROD M2: enveloppe invalide: %',r.signature; end if;
      v_matches:=(length(v_definition)-length(replace(v_definition,v_source,'')))/length(v_source);
      if v_matches<>1 then raise exception 'SEC-PROD M2: source SQL non unique: %',r.signature; end if;
      v_corrected_definition:=replace(v_definition,v_source,v_corrected_source);
    end if;
    if v_corrected_definition is not distinct from v_definition then raise exception 'SEC-PROD M2: patch vide: %',r.signature; end if;
    execute v_corrected_definition; v_seen:=v_seen+1;
  end loop;
  if v_seen<>4 then raise exception 'SEC-PROD M2: nombre de RPC/helpers corrigés %',v_seen; end if;
  select qual into v_policy from pg_catalog.pg_policies where schemaname='public' and tablename='matching_requests' and policyname='matching_requests_parties_read';
  if v_policy is distinct from '((requested_by = auth.uid()) OR partie_concernee(subject_profile_id))' then raise exception 'SEC-PROD M2: policy matching divergée: %',v_policy; end if;
  select qual into v_policy from pg_catalog.pg_policies where schemaname='public' and tablename='teacher_student_assignments' and policyname='assignments_parties_read';
  if v_policy is distinct from '(partie_concernee(student_id) OR (teacher_id = auth.uid()))' then raise exception 'SEC-PROD M2: policy assignments divergée: %',v_policy; end if;
  alter policy matching_requests_parties_read on public.matching_requests using (public.app_account_valid() and (requested_by=auth.uid() or public.partie_concernee(subject_profile_id)));
  alter policy assignments_parties_read on public.teacher_student_assignments using (public.app_account_valid() and (public.partie_concernee(student_id) or teacher_id=auth.uid()));
end
$sec_prod_active_read_guards$;

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
  if v_anon <> 1
     or not has_function_privilege('anon', 'public.agent_pre_request()', 'EXECUTE')
     or (select count(*) from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
         where n.nspname='public' and p.prosecdef and has_function_privilege('anon',p.oid,'EXECUTE')
           and p.oid <> to_regprocedure('public.agent_pre_request()')) <> 0 then
    raise exception 'SEC-PROD: anon doit conserver uniquement agent_pre_request() (trouvé %)', v_anon;
  end if;
  -- PROD read-only ACL review: authenticator is not a member of anon/authenticated;
  -- retain its direct pre-request hook grant and revoke the three PUBLIC-only paths.
  if not has_function_privilege('authenticator', 'public.agent_pre_request()', 'EXECUTE') then
    raise exception 'SEC-PROD: authenticator a perdu EXECUTE sur le pre-request hook';
  end if;
  if (select count(*) from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      where n.nspname='public' and p.prosecdef and has_function_privilege('authenticator',p.oid,'EXECUTE')) <> 1 then
    raise exception 'SEC-PROD: droits authenticator SECURITY DEFINER inattendus après retrait PUBLIC/anon';
  end if;
  select count(*) into v_auth from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef and has_function_privilege('authenticated',p.oid,'EXECUTE');
  if has_function_privilege('authenticated', 'public.log_sensitive_access(text, text, text, jsonb)', 'EXECUTE') then
    raise exception 'SEC-PROD: authenticated conserve EXECUTE direct sur le writer d''audit';
  end if;
  if v_auth <> 117 then raise exception 'SEC-PROD: nombre inattendu de RPC authenticated (% au lieu de 117)', v_auth; end if;
  select count(*) into v_agent from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef and has_function_privilege('agent_ro',p.oid,'EXECUTE');
  if v_agent <> 47 then raise exception 'SEC-PROD: droits agent_ro inattendus après retrait KYC (% au lieu de 47)', v_agent; end if;
  if exists (
    select 1 from pg_temp.sec_prod_expected_functions e
    where has_function_privilege('agent_ro', e.signature, 'EXECUTE') is distinct from
      (e.agent_ro_execute and e.signature not in ('public.read_kyc_documents()', 'public.autoriser_lecture_piece_identite(uuid)'))
  ) then raise exception 'SEC-PROD: usage agent_ro non préservé conformément à la matrice'; end if;
  if exists (
    select 1 from pg_temp.sec_prod_expected_functions e
    where has_function_privilege('authenticated', e.signature, 'EXECUTE') is distinct from (e.authenticated_execute and e.signature <> 'public.log_sensitive_access(text, text, text, jsonb)')
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
end
$sec_prod_postflight$;

-- Ce RPC a un chemin enseignant par appartenance de séance; vérifier aussi la
-- garde globale de validité du compte et la séparation des rôles après simulation.
do $sec_prod_teacher_publish_postflight$
declare
  v_source text;
  v_normalized text;
  v_guard text := $guard$if not coalesce(((public.app_role() = 'teacher' and public.session_belongs_to_teacher(p_session_id, auth.uid())) or public.app_role() = 'admin') and public.app_account_valid(), false) then$guard$;
begin
  select p.prosrc into v_source
    from pg_catalog.pg_proc p
   where p.oid = to_regprocedure('public.publier_etat_partage(uuid, uuid, uuid, jsonb, jsonb, text, jsonb, jsonb, jsonb, integer)');
  v_normalized := regexp_replace(lower(coalesce(v_source, '')), '[[:space:]]+', ' ', 'g');
  if strpos(v_normalized, v_guard) = 0 then
    raise exception 'SEC-PROD M2: garde teacher/admin valide manquante dans publier_etat_partage';
  end if;
end
$sec_prod_teacher_publish_postflight$;

-- M2: an authenticated JWT role claim is not proof that the profile remains active.
-- Keep admin/controller/guardian role gates, but fail closed on revoked, expired,
-- deleted or otherwise invalid profiles before exposing or mutating privileged state.
do $sec_prod_active_role_guards$
declare r record; v_oid oid; v_definition text; v_source text; v_new_source text; v_new_definition text; v_matches integer; v_seen integer:=0;
begin
 for r in select * from (values ('public.clore_regle(uuid,text)','69c2d22a82d2d06431a75488e9b96aad','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.decider_demande(uuid,boolean,text)','7e1986d430bef88eec0dffa29e290acf','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.decider_dossier(uuid,boolean,text)','9b1f8d0d3baea020be07d676c34de6e2','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.demandes_en_attente()','a9003a8e91895e4b6d7674e584a7fe75','if[[:space:]]+public[.]app_role[(][)][[:space:]]+not[[:space:]]+in[[:space:]]*[(][[:space:]]*''admin''[[:space:]]*,[[:space:]]*''controller''[[:space:]]*[)][[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() in (''admin'', ''controller''), false) then'),
('public.eleves_sans_enseignant()','d3e14512ba428ffec5e9623d8e8bacbd','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.enseignants_pour(uuid)','f2446791e27fe948db4a172470be5940','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.guard_profile_privileged_columns()','0e0b9d7f966e64b2e5182a0a9d5495eb','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+and[[:space:]]*[(]','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) and ('),
('public.indicateurs_admin()','d7e1209572394c2ab6d5f9dae3834aaa','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.journal_audit_filtres()','49c1360b67ef589d2aaef8468ecc31bc','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.journal_audit(uuid,text,timestamp with time zone,integer,timestamp with time zone,bigint)','973fec3923b807963042e424ef181e50','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.maj_eleve_pedagogie(uuid,text,text)','f9164b5c4b9a7bbc582ae7675ff94678','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.poser_regle(uuid,text,integer,text)','b42b46c02c394102058503378bc35c6e','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.revoquer_appareil(uuid)','94514a938b71c72c9c480554c0ac6bb1','if[[:space:]]+public[.]app_role[(][)][[:space:]]+not[[:space:]]+in[[:space:]]*[(][[:space:]]*''guardian''[[:space:]]*,[[:space:]]*''admin''[[:space:]]*[)][[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() in (''guardian'', ''admin''), false) then'),
('public.verifier_chaine_audit(integer)','cf28eb75e08bd5cdd0cb8d18067c720b','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then'),
('public.video_config_lire()','4af82d0a2db1602453eeeaf40a10e9cc','if[[:space:]]+public[.]app_role[(][)][[:space:]]*<>[[:space:]]*''admin''[[:space:]]+then','if not coalesce(public.app_account_valid() and public.app_role() = ''admin'', false) then')) as t(signature,expected_hash,pattern,replacement) order by signature
 loop
  v_oid:=to_regprocedure(r.signature);
  if v_oid is null or md5(pg_get_functiondef(v_oid)) is distinct from r.expected_hash then raise exception 'définition inattendue: %',r.signature; end if;
  v_definition:=pg_get_functiondef(v_oid); select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid=v_oid;
  v_matches:=regexp_count(v_source,r.pattern,1,'i');
  if v_matches<>1 then raise exception 'garde rôle non unique (%): %',v_matches,r.signature; end if;
  v_new_source:=regexp_replace(v_source,r.pattern,r.replacement,'i');
  if v_new_source is not distinct from v_source then raise exception 'remplacement vide: %',r.signature; end if;
  v_new_definition:=replace(v_definition,v_source,v_new_source);
  if v_new_definition is not distinct from v_definition then raise exception 'définition non réécrite: %',r.signature; end if;
  execute v_new_definition; v_seen:=v_seen+1;
 end loop;
 if v_seen<>15 then raise exception 'nombre inattendu: %',v_seen; end if;
end
$sec_prod_active_role_guards$;

do $sec_prod_active_role_postflight$
declare r record; v_source text; v_normalized text; v_seen integer:=0;
begin
  for r in select unnest(array[
    'public.clore_regle(uuid,text)',
    'public.decider_demande(uuid,boolean,text)',
    'public.decider_dossier(uuid,boolean,text)',
    'public.demandes_en_attente()',
    'public.eleves_sans_enseignant()',
    'public.enseignants_pour(uuid)',
    'public.guard_profile_privileged_columns()',
    'public.indicateurs_admin()',
    'public.journal_audit_filtres()',
    'public.journal_audit(uuid,text,timestamp with time zone,integer,timestamp with time zone,bigint)',
    'public.maj_eleve_pedagogie(uuid,text,text)',
    'public.poser_regle(uuid,text,integer,text)',
    'public.revoquer_appareil(uuid)',
    'public.verifier_chaine_audit(integer)',
    'public.video_config_lire()'
  ]) as signature
  loop
    select p.prosrc into v_source from pg_catalog.pg_proc p where p.oid=to_regprocedure(r.signature);
    v_normalized:=regexp_replace(lower(coalesce(v_source,'')),'[[:space:]]+','','g');
    if position('ifnotcoalesce(public.app_account_valid()andpublic.app_role()' in v_normalized)=0 then
      raise exception 'SEC-PROD M2: compte actif absent du garde rôle de %',r.signature;
    end if;
    v_seen:=v_seen+1;
  end loop;
  if v_seen<>15 then raise exception 'SEC-PROD M2: postflight rôle incomplet (%)',v_seen; end if;
end
$sec_prod_active_role_postflight$;

do $sec_prod_active_read_postflight$
declare v_source text; v_normalized text; v_policy text;
begin
  select prosrc into v_source from pg_catalog.pg_proc where oid=to_regprocedure('public.derniere_position_groupe(uuid)');
  v_normalized:=regexp_replace(lower(coalesce(v_source,'')),'[[:space:]]+','','g');
  if position('ifnotcoalesce(public.app_account_valid()andv_autorise,false)then' in v_normalized)=0 then raise exception 'SEC-PROD M2: garde compte absente de derniere_position_groupe'; end if;
  select prosrc into v_source from pg_catalog.pg_proc where oid=to_regprocedure('public.visites_observation(uuid)');
  v_normalized:=regexp_replace(lower(coalesce(v_source,'')),'[[:space:]]+','','g');
  if position('wherepublic.app_account_valid()andv.session_id=p_session_id' in v_normalized)=0 then raise exception 'SEC-PROD M2: filtre compte absent de visites_observation'; end if;
  for v_source in select p.prosrc from pg_catalog.pg_proc p where p.oid in (to_regprocedure('public.partie_concernee(uuid)'),to_regprocedure('public.peut_poser_disponibilite(uuid)')) loop
    v_normalized:=regexp_replace(lower(coalesce(v_source,'')),'[[:space:]]+','','g');
    if v_normalized !~ '^selectcoalesce[(]public[.]app_account_valid[(][)]and[(]' or v_normalized !~ '[)][,]false[)][;]$' then raise exception 'SEC-PROD M2: SQL helper pas entièrement gardé'; end if;
  end loop;
  select qual into v_policy from pg_catalog.pg_policies where schemaname='public' and tablename='matching_requests' and policyname='matching_requests_parties_read';
  v_normalized:=regexp_replace(replace(lower(coalesce(v_policy,'')),'public.',''),'[[:space:]]+','','g');
  if v_normalized<>'(app_account_valid()and((requested_by=auth.uid())orpartie_concernee(subject_profile_id)))' then raise exception 'SEC-PROD M2: garde matching inattendue: %',v_policy; end if;
  select qual into v_policy from pg_catalog.pg_policies where schemaname='public' and tablename='teacher_student_assignments' and policyname='assignments_parties_read';
  v_normalized:=regexp_replace(replace(lower(coalesce(v_policy,'')),'public.',''),'[[:space:]]+','','g');
  if v_normalized<>'(app_account_valid()and(partie_concernee(student_id)or(teacher_id=auth.uid())))' then raise exception 'SEC-PROD M2: garde assignments inattendue: %',v_policy; end if;
end
$sec_prod_active_read_postflight$;

do $sec_prod_views_postflight$
declare
  r record;
  v_oid oid;
  v_options text[];
  v_expected_agent boolean;
begin
  for r in select * from pg_temp.sec_prod_expected_views order by view_name loop
    v_oid := to_regclass(format('public.%I', r.view_name));
    if v_oid is null then raise exception 'SEC-PROD: vue absente après remédiation: public.%', r.view_name; end if;
    if md5(pg_get_viewdef(v_oid, true)) is distinct from r.md5_definition then
      raise exception 'SEC-PROD: définition modifiée pendant remédiation: public.%', r.view_name;
    end if;
    select reloptions into v_options from pg_catalog.pg_class where oid=v_oid;
    if not coalesce(v_options @> array['security_invoker=true'], false)
       or cardinality(coalesce(v_options, array[]::text[])) <> cardinality(r.expected_reloptions) + 1
       or not coalesce(v_options @> r.expected_reloptions, false) then
      raise exception 'SEC-PROD: options invoker/barrier inattendues: public.%', r.view_name;
    end if;
    v_expected_agent := r.agent_ro_select
      and r.view_name not in ('mes_appareils_v','mes_groupes_famille_v','mes_groupes_v','mes_seances_enseignant_v','teacher_roster_v');
    if has_table_privilege('anon', v_oid, 'SELECT')
       or has_table_privilege('authenticated', v_oid, 'SELECT') is distinct from r.authenticated_select
       or has_table_privilege('agent_ro', v_oid, 'SELECT') is distinct from v_expected_agent then
      raise exception 'SEC-PROD: droits SELECT post-remédiation inattendus: public.%', r.view_name;
    end if;
  end loop;
end
$sec_prod_views_postflight$;


-- Le scan M2 global est volontairement exécuté après tous les patchs ciblés.
do $m2_scan_postflight$
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
      and app_private.sec_prod_has_unsafe_role_guard(p.prosrc)
  loop
    raise exception 'SEC-PROD M2: garde négative app_role résiduelle après patch oid=%', v.oid;
  end loop;
end
$m2_scan_postflight$;

-- Ne modifie ni btree_gist ni l'index sessions_no_teacher_overlap:
-- pg_depend établit que le déplacement requiert une opération séparée et testée.
commit;
