-- AF L1-08 : les policies par role exigent aussi un compte valide (P1-6, P2-1).
-- Un administrateur, un comptable ou un controleur suspendu gardait ses droits REST
-- pendant la vie de son jeton ; les RPC etaient deja gardees (F86).
-- Methode : texte actuel de chaque policy exporte de la base rejouee (apres L1-01 a L1-07),
-- puis enveloppe en coalesce((<expression>) and public.app_account_valid(), false).
-- Rien d'autre ne change. La migration est generee, pas tapee.
-- app_account_valid() est STABLE (pg_proc.provolatile = 's'), DEFINER, search_path vide.
--
-- Policies modifiees (41) :
--   app_config.app_config_admin_read (SELECT)
--   app_config.app_config_admin_update (UPDATE)
--   app_config.app_config_admin_write (INSERT)
--   app_config_history.app_config_history_admin (SELECT)
--   audit_logs.audit_logs_read (SELECT)
--   availability_slots.availability_slots_admin_all (ALL)
--   contract_acceptances.contract_acceptances_admin_read (SELECT)
--   contract_required_versions.contract_required_versions_admin_read (SELECT)
--   device_pairing_codes.pairing_codes_admin_read (SELECT)
--   devices.devices_admin_all (ALL)
--   fx_rates.fx_rates_admin_accountant_read (SELECT)
--   households.households_accountant_select (SELECT)
--   households.households_admin_all (ALL)
--   juz.juz_admin (ALL)
--   lesson_reports.lesson_reports_admin_all (ALL)
--   lesson_reports.lesson_reports_teacher_write (ALL)
--   library_reading_position.library_reading_position_admin (SELECT)
--   matching_requests.matching_requests_privileged_read (SELECT)
--   mushaf.mushaf_admin (ALL)
--   page_mushaf.page_mushaf_admin (ALL)
--   payout_methods.payout_methods_admin_accountant_all (ALL)
--   payouts.payouts_admin_accountant_all (ALL)
--   prayer_settings.prayer_settings_admin_all (ALL)
--   profiles.profiles_admin_all (ALL)
--   profiles.profiles_agent_select (SELECT)
--   recurrence_rules.recurrence_rules_admin_all (ALL)
--   session_participants.session_participants_admin_all (ALL)
--   session_presence_override.spo_ecriture (ALL)
--   session_presence_override.spo_lecture (SELECT)
--   sessions.sessions_admin_all (ALL)
--   sourate.sourate_admin (ALL)
--   student_concern.student_concern_update_admin (UPDATE)
--   student_profiles.student_profiles_admin_all (ALL)
--   student_reading_position.srp_admin (ALL)
--   teacher_profiles.teacher_profiles_admin_all (ALL)
--   teacher_student_assignments.assignments_privileged_read (SELECT)
--   verset.verset_admin (ALL)
--   video_token_grants.video_token_grants_admin_read (SELECT)
--   wallets.wallets_admin_accountant_all (ALL)
--   webhook_events.webhook_events_admin_read (SELECT)
--   weekly_availability.weekly_availability_admin_all (ALL)--
-- audit_logs_read est de plus reduite au seul administrateur (le controleur lisait
-- tout le journal, payloads KYC et jetons video compris : P2-1).
--
-- Policies laissees (8) :
--   Cinq de lecture pour roles non privilegies, a l'appreciation du relecteur :
--   offres_horaires_vitrine, profiles_family_select, households_guardian_select,
--   srp_foyer_lecture, intentions_horaire_parties.
--   Trois d'accueil, ajoutees par ce lot : kyc_staff_self_insert, kyc_guardian_insert,
--   contract_acceptances_self_insert. app_account_valid() n'accepte que 'active' et
--   'provisional_active' ; or ces trois policies servent justement les comptes
--   'pending_kyc' (depot de la piece, signature du contrat). Les envelopper empeche
--   l'enseignant de deposer sa piece : scenarios_etape3 (S3, ligne 137) et
--   scenarios_hook_jeton (ligne 366) passent au rouge. Elles restent ouvertes au compte
--   en attente, mais recoivent une garde etroite (decision de l'orchestrateur) : un compte
--   disabled ou supprime (deleted_at non nul) ne depose ni piece ni signature.
-- Hors liste : wallet_entries_admin_accountant_all n'existe plus (remplacee par L1-06,
-- elle ne teste plus un role nu). Aucune des 49 policies n'etait deja gardee.

begin;

alter policy app_config_admin_read on public.app_config
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy app_config_admin_update on public.app_config
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy app_config_admin_write on public.app_config
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy app_config_history_admin on public.app_config_history
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy audit_logs_read on public.audit_logs
  using (coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

alter policy availability_slots_admin_all on public.availability_slots
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy contract_acceptances_admin_read on public.contract_acceptances
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy contract_required_versions_admin_read on public.contract_required_versions
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy pairing_codes_admin_read on public.device_pairing_codes
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy devices_admin_all on public.devices
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy fx_rates_admin_accountant_read on public.fx_rates
  using (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false));

alter policy households_accountant_select on public.households
  using (coalesce((((public.app_role() = 'accountant'::app_role) AND (deleted_at IS NULL))) and public.app_account_valid(), false));

alter policy households_admin_all on public.households
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy juz_admin on public.juz
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy lesson_reports_admin_all on public.lesson_reports
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy lesson_reports_teacher_write on public.lesson_reports
  using (coalesce((((author_profile_id = auth.uid()) AND (deleted_at IS NULL))) and public.app_account_valid(), false))
  with check (coalesce((((public.app_role() = 'teacher'::app_role) AND (author_profile_id = auth.uid()) AND session_belongs_to_teacher(session_id, auth.uid()))) and public.app_account_valid(), false));

alter policy library_reading_position_admin on public.library_reading_position
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy matching_requests_privileged_read on public.matching_requests
  using (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role]))) and public.app_account_valid(), false));

alter policy mushaf_admin on public.mushaf
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy page_mushaf_admin on public.page_mushaf
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy payout_methods_admin_accountant_all on public.payout_methods
  using (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false));

alter policy payouts_admin_accountant_all on public.payouts
  using (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false));

alter policy prayer_settings_admin_all on public.prayer_settings
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy profiles_admin_all on public.profiles
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy profiles_agent_select on public.profiles
  using (coalesce((((deleted_at IS NULL) AND ((id = auth.uid()) OR ((NOT agent_identite_masquee()) AND ((public.app_role() = 'admin'::app_role) OR ((household_id = app_household_id()) AND (public.app_role() = ANY (ARRAY['guardian'::app_role, 'accountant'::app_role, 'controller'::app_role])))))))) and public.app_account_valid(), false));

alter policy recurrence_rules_admin_all on public.recurrence_rules
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy session_participants_admin_all on public.session_participants
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy spo_ecriture on public.session_presence_override
  using (coalesce((((public.app_role() = 'admin'::app_role) OR (EXISTS ( SELECT 1
   FROM sessions s
  WHERE ((s.id = session_presence_override.session_id) AND (s.teacher_id = app_user_id()) AND (s.deleted_at IS NULL)))))) and public.app_account_valid(), false))
  with check (coalesce((((decide_par = app_user_id()) AND ((public.app_role() = 'admin'::app_role) OR (EXISTS ( SELECT 1
   FROM sessions s
  WHERE ((s.id = session_presence_override.session_id) AND (s.teacher_id = app_user_id()) AND (s.deleted_at IS NULL))))))) and public.app_account_valid(), false));

alter policy spo_lecture on public.session_presence_override
  using (coalesce((((public.app_role() = 'admin'::app_role) OR (profile_id = app_user_id()) OR (EXISTS ( SELECT 1
   FROM sessions s
  WHERE ((s.id = session_presence_override.session_id) AND (s.teacher_id = app_user_id()) AND (s.deleted_at IS NULL)))))) and public.app_account_valid(), false));

alter policy sessions_admin_all on public.sessions
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy sourate_admin on public.sourate
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy student_concern_update_admin on public.student_concern
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy student_profiles_admin_all on public.student_profiles
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy srp_admin on public.student_reading_position
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy teacher_profiles_admin_all on public.teacher_profiles
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy assignments_privileged_read on public.teacher_student_assignments
  using (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'controller'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false));

alter policy verset_admin on public.verset
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy video_token_grants_admin_read on public.video_token_grants
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy wallets_admin_accountant_all on public.wallets
  using (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = ANY (ARRAY['admin'::app_role, 'accountant'::app_role]))) and public.app_account_valid(), false));

alter policy webhook_events_admin_read on public.webhook_events
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));

alter policy weekly_availability_admin_all on public.weekly_availability
  using (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false))
  with check (coalesce(((public.app_role() = 'admin'::app_role)) and public.app_account_valid(), false));
-- Policies de depot (comptes pending_kyc admis) : garde etroite, un compte disabled ou
-- supprime ne depose ni piece ni signature. Meme texte exporte, sans app_account_valid().
alter policy kyc_staff_self_insert on public.kyc_documents
  with check (coalesce((((profile_id = auth.uid()) AND (public.app_role() = ANY (ARRAY['teacher'::app_role, 'controller'::app_role])))) and exists (select 1 from public.profiles pv where pv.id = auth.uid() and pv.account_status <> 'disabled' and pv.deleted_at is null), false));

alter policy kyc_guardian_insert on public.kyc_documents
  with check (coalesce((((public.app_role() = 'guardian'::app_role) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = kyc_documents.profile_id) AND (p.household_id = app_household_id()) AND (p.deleted_at IS NULL)))))) and exists (select 1 from public.profiles pv where pv.id = auth.uid() and pv.account_status <> 'disabled' and pv.deleted_at is null), false));

alter policy contract_acceptances_self_insert on public.contract_acceptances
  with check (coalesce((((profile_id = auth.uid()) AND ((contract_kind <> 'teacher_nda'::text) OR ((public.app_role() = 'teacher'::app_role) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'teacher'::app_role) AND (p.deleted_at IS NULL) AND (p.account_status = ANY (ARRAY['pending_kyc'::account_status, 'provisional_active'::account_status, 'active'::account_status]))))) AND (EXISTS ( SELECT 1
   FROM contract_texts t
  WHERE ((t.contract_kind = 'teacher_nda'::text) AND (t.version = contract_acceptances.version) AND (t.locale = 'fr'::text) AND t.is_current))))))) and exists (select 1 from public.profiles pv where pv.id = auth.uid() and pv.account_status <> 'disabled' and pv.deleted_at is null), false));

do $postflight$
declare v_liste text;
begin
  select string_agg(tablename || '.' || policyname, ', ' order by tablename || '.' || policyname)
    into v_liste
    from pg_policies
   where schemaname = 'public'
     and (coalesce(qual,'') || coalesce(with_check,'')) like '%app_role()%'
     and (coalesce(qual,'') || coalesce(with_check,'')) not like '%app_account_valid%';
  if v_liste is distinct from 'contract_acceptances.contract_acceptances_self_insert, households.households_guardian_select, intentions_horaire.intentions_horaire_parties, kyc_documents.kyc_guardian_insert, kyc_documents.kyc_staff_self_insert, offres_horaires.offres_horaires_vitrine, profiles.profiles_family_select, student_reading_position.srp_foyer_lecture' then
    raise exception 'L1-08 postflight: policies sans app_account_valid : %', coalesce(v_liste, '(aucune)');
  end if;
end $postflight$;

commit;
