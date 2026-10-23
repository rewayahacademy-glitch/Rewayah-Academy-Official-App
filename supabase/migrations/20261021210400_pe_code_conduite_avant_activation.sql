-- PE (21/10/2026, CAND-Q15 lot conduite) : le code de conduite de l'enseignant
-- se signe avant l'activation de son compte, et la garde d'activation l'exige.
-- Suite prevue par l'en-tete de 20261018160000_pe_protection_enfants.sql
-- (l. 20-23) : le texte est valide par le directeur depuis le 19/10
-- (20261019100000_pe_code_conduite_v2.sql, version requise '2026-10-19').
--
-- Constat (docs/current/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md, section 7) :
-- * guard_teacher_activation_signatures() (une seule definition, 0089)
--   n'exige que le contrat (teacher_nda) et l'accuse
--   (recording_and_control_notice). Un enseignant invite devient actif, donc
--   affectable a une classe ou a un remplacement, sans avoir accepte le code
--   de conduite (regle 9 du texte valide : "refuser veut dire pas d'eleves") ;
-- * l'ajout tel quel bloquerait tout : la policy RESTRICTIVE
--   contract_acceptances_code_conduite_enseignant exige app_account_valid(),
--   qui n'admet que active et provisional_active, et l'enseignant invite nait
--   pending_kyc ;
-- * etat_dossier() ne dit rien du code : le portail d'attente ne peut pas le
--   demander sur la page unique des accords (DECISION-ENTREE du 17/10).
--
-- Correction :
-- 1. La policy RESTRICTIVE prend l'enveloppe de depot d'af_l1_08 : l'enseignant
--    accepte la version requise sur son propre profil (profile_id = auth.uid()
--    ecrit en clair), compte pending_kyc, provisional_active ou active, ni
--    desactive ni supprime. app_role() est enveloppe par (select ...), comme
--    l'a fait L1-08-reprise pour les autres policies. Inventaire des policies
--    sans app_account_valid() : 8 -> 9 (a acter par la revue de securite).
-- 2. guard_teacher_activation_signatures() : corps de 0089 recopie, plus un
--    troisieme bloc qui exige teacher_conduct_code a la version requise de
--    contract_required_versions. Message 'contract_not_signed_current:teacher_conduct_code'
--    (SQLSTATE 23514). Le declencheur 0089 reste tel quel ; un compte deja
--    actif n'est pas re-controle (regle 0089 conservee).
-- 3. etat_dossier() : corps de 20261017180000_l5_01_usage_inscription.sql
--    recopie, plus 'code_conduite_signe'. Vrai pour tout compte qui n'est pas
--    enseignant ; pour l'enseignant, vrai seulement a la version requise (la
--    meme regle que la garde, sinon le portail dirait "fait" et la
--    validation echouerait).
-- 4. teacher_signature_statuses(uuid) : corps de 0089 recopie, plus une cle
--    'code_conduite' (meme forme que 'contrat' et 'accuse'), pour que la
--    direction sache pourquoi la validation d'une piece echoue.
--
-- Ce que la migration ne fait pas : aucune acceptation n'est fabriquee
-- (ADR-011) ; les enseignants deja actifs ou provisoires ne sont pas
-- re-controles ; un compte passe a la main en provisional_active n'est pas
-- couvert (le meme trou existe deja pour le contrat). Voir la section 7,
-- "Risques et suites".
--
-- Ordre : apres 20261018160000 et 20261019100000, dans le meme lot. Appliquee
-- seule, ALTER POLICY echoue (policy inconnue) : l'echec se voit.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. L'enseignant en attente accepte la version requise
-- ---------------------------------------------------------------------------
ALTER POLICY contract_acceptances_code_conduite_enseignant
  ON public.contract_acceptances
  WITH CHECK (
    contract_kind <> 'teacher_conduct_code'
    OR coalesce(
      profile_id = auth.uid()
      AND (SELECT public.app_role()) = 'teacher'::public.app_role
      AND version = public.code_conduite_version_requise()
      AND EXISTS (
        SELECT 1 FROM public.profiles p
         WHERE p.id = auth.uid()
           AND p.role = 'teacher'::public.app_role
           AND p.deleted_at IS NULL
           AND p.account_status IN ('pending_kyc'::public.account_status,
                                    'provisional_active'::public.account_status,
                                    'active'::public.account_status)),
      false)
  );

-- ---------------------------------------------------------------------------
-- 2. La garde d'activation exige aussi le code de conduite
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_teacher_activation_signatures()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE
  v_teacher_version text;
  v_teacher_hash text;
  v_notice_version text;
  v_conduite_version text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.role = 'teacher'::public.app_role
     AND OLD.account_status = 'active'::public.account_status THEN
    RETURN NEW;
  END IF;
  IF NEW.role <> 'teacher'::public.app_role
     OR NEW.account_status <> 'active'::public.account_status THEN
    RETURN NEW;
  END IF;

  SELECT t.version, t.sha256 INTO v_teacher_version, v_teacher_hash
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda'
    AND t.locale = 'fr'
    AND t.is_current;
  IF v_teacher_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'teacher_nda'
      AND c.version = v_teacher_version
      AND c.signed_sha256 = v_teacher_hash
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:teacher_nda';
  END IF;

  SELECT r.version INTO v_notice_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'recording_and_control_notice';
  IF v_notice_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'recording_and_control_notice'
      AND c.version = v_notice_version
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:recording_and_control_notice';
  END IF;

  -- CAND-Q15 conduite : le code de conduite, a la version requise.
  SELECT r.version INTO v_conduite_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'teacher_conduct_code';
  IF v_conduite_version IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.contract_acceptances c
    WHERE c.profile_id = NEW.id
      AND c.contract_kind = 'teacher_conduct_code'
      AND c.version = v_conduite_version
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514', MESSAGE = 'contract_not_signed_current:teacher_conduct_code';
  END IF;

  RETURN NEW;
END;
$function$;
ALTER FUNCTION public.guard_teacher_activation_signatures() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.guard_teacher_activation_signatures()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
-- Le declencheur profiles_guard_teacher_activation_signatures (0089) reste tel
-- quel : BEFORE INSERT OR UPDATE OF role, account_status, WHEN active.

-- ---------------------------------------------------------------------------
-- 3. etat_dossier() rend code_conduite_signe
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.etat_dossier()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_profile public.profiles;
  v_doc public.kyc_documents;
  v_contrat boolean;
  v_accuse boolean;
  v_conduite boolean;
  v_usage text;
  v_suit boolean;
begin
  if auth.uid() is null then
    raise exception 'aucune session';
  end if;

  select * into v_profile
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;

  -- Aucun profil : c'est une inscription a terminer, pas un dossier a attendre.
  if v_profile.id is null then
    return jsonb_build_object('profil', false);
  end if;

  select * into v_doc
  from public.kyc_documents k
  where k.profile_id = v_profile.id and k.deleted_at is null
  order by k.created_at desc
  limit 1;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = case when v_profile.role = 'teacher'
                                 then 'teacher_nda' else 'guardian_terms' end
  ) into v_contrat;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = 'recording_and_control_notice'
  ) into v_accuse;

  -- CAND-Q15 conduite : le code de conduite n'est demande qu'a l'enseignant,
  -- a la version requise (la meme regle que la garde d'activation).
  select v_profile.role is distinct from 'teacher'::public.app_role or exists (
    select 1 from public.contract_acceptances c
    join public.contract_required_versions r
      on r.contract_kind = c.contract_kind and r.version = c.version
    where c.profile_id = v_profile.id
      and c.contract_kind = 'teacher_conduct_code'
  ) into v_conduite;

  -- L5-01 : l'usage choisi a l'inscription, et la fiche d'eleve du titulaire.
  select h.usage_inscription into v_usage
  from public.households h
  where h.id = v_profile.household_id and h.primary_guardian_id = v_profile.id;

  select exists (
    select 1 from public.student_profiles s
    where s.profile_id = v_profile.id
  ) into v_suit;

  return jsonb_build_object(
    'profil', true,
    'role', v_profile.role::text,
    'statut', v_profile.account_status::text,
    'piece_deposee', v_doc.id is not null,
    'piece_statut', v_doc.status::text,
    'motif_refus', v_doc.rejection_reason,
    'depose_le', v_doc.created_at,
    'contrat_signe', v_contrat,
    'accuse_signe', v_accuse,
    'code_conduite_signe', v_conduite,
    'usage', v_usage,
    'suit_des_cours', v_suit
  );
end;
$function$;

-- ---------------------------------------------------------------------------
-- 4. teacher_signature_statuses(uuid) rend aussi le code de conduite
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.teacher_signature_statuses(p_profile_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE
  v_teacher_version text;
  v_teacher_signed text;
  v_notice_version text;
  v_notice_signed text;
  v_conduite_version text;
  v_conduite_signed text;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin'::public.app_role
      AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'admin_required';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id AND p.role = 'teacher'::public.app_role
      AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'teacher_profile_not_found';
  END IF;

  SELECT t.version INTO v_teacher_version
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current;
  SELECT c.version INTO v_teacher_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id AND c.contract_kind = 'teacher_nda'
  ORDER BY c.accepted_at DESC LIMIT 1;

  SELECT r.version INTO v_notice_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'recording_and_control_notice';
  SELECT c.version INTO v_notice_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id
    AND c.contract_kind = 'recording_and_control_notice'
  ORDER BY c.accepted_at DESC LIMIT 1;

  -- CAND-Q15 conduite : la version requise est-elle acceptee ? Une
  -- acceptation de la version requise compte meme si une autre est plus
  -- recente : c'est elle que la garde d'activation lit.
  SELECT r.version INTO v_conduite_version
  FROM public.contract_required_versions r
  WHERE r.contract_kind = 'teacher_conduct_code';
  SELECT c.version INTO v_conduite_signed
  FROM public.contract_acceptances c
  WHERE c.profile_id = p_profile_id
    AND c.contract_kind = 'teacher_conduct_code'
  ORDER BY (c.version = v_conduite_version) DESC, c.accepted_at DESC LIMIT 1;

  RETURN jsonb_build_object(
    'contrat', jsonb_build_object(
      'status', CASE
        WHEN v_teacher_signed IS NULL THEN 'non_signe'
        WHEN v_teacher_version IS NOT NULL AND v_teacher_signed = v_teacher_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_teacher_signed,
      'version_courante', v_teacher_version
    ),
    'accuse', jsonb_build_object(
      'status', CASE
        WHEN v_notice_signed IS NULL THEN 'non_signe'
        WHEN v_notice_version IS NOT NULL AND v_notice_signed = v_notice_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_notice_signed,
      'version_courante', v_notice_version
    ),
    'code_conduite', jsonb_build_object(
      'status', CASE
        WHEN v_conduite_signed IS NULL THEN 'non_signe'
        WHEN v_conduite_version IS NOT NULL AND v_conduite_signed = v_conduite_version
          THEN 'signe_version_courante'
        ELSE 'signe_ancienne_version'
      END,
      'version_signee', v_conduite_signed,
      'version_courante', v_conduite_version
    )
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- Droits et empreintes
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_etat regprocedure := 'public.etat_dossier()'::regprocedure;
  v_statuts regprocedure := 'public.teacher_signature_statuses(uuid)'::regprocedure;
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[v_etat, v_statuts] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_etat, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. CAND-Q15 conduite : rend code_conduite_signe (vrai hors enseignant, version requise pour l enseignant). Lecture du seul dossier de l appelant.',
    v_etat::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_etat))));
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_statuts, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. SECURITY INVOKER (gate F79). CAND-Q15 conduite : cle code_conduite en plus du contrat et de l accuse.',
    v_statuts::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_statuts))));
END;
$droits$;

-- ---------------------------------------------------------------------------
-- Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_garde regprocedure := 'public.guard_teacher_activation_signatures()'::regprocedure;
  v_etat regprocedure := 'public.etat_dossier()'::regprocedure;
  v_statuts regprocedure := 'public.teacher_signature_statuses(uuid)'::regprocedure;
  v_policy record;
  v_liste text;
  v_role text;
BEGIN
  -- La garde : INVOKER, postgres, search_path vide, appelable par personne,
  -- et elle lit le code de conduite.
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = v_garde AND NOT p.prosecdef
          AND p.proowner = 'postgres'::regrole
          AND coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']
          AND pg_catalog.strpos(p.prosrc, 'teacher_conduct_code') > 0
          AND pg_catalog.strpos(p.prosrc, 'contract_not_signed_current:teacher_nda') > 0
          AND pg_catalog.strpos(p.prosrc, 'contract_not_signed_current:recording_and_control_notice') > 0) THEN
    RAISE EXCEPTION 'PE conduite : garde d''activation invalide';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, v_garde, 'EXECUTE') THEN
      RAISE EXCEPTION 'PE conduite : la garde est executable par %', v_role;
    END IF;
  END LOOP;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
        WHERE t.tgrelid = 'public.profiles'::regclass
          AND t.tgname = 'profiles_guard_teacher_activation_signatures'
          AND t.tgfoid = v_garde::oid
          AND NOT t.tgisinternal
          AND t.tgenabled = 'O'
          AND (t.tgtype & 20) = 20) THEN
    RAISE EXCEPTION 'PE conduite : declencheur d''activation absent ou desactive';
  END IF;

  -- La policy : RESTRICTIVE, INSERT, enseignant sur son propre profil, compte
  -- en attente admis, sans app_account_valid().
  SELECT p.permissive, p.cmd, p.with_check INTO v_policy
    FROM pg_catalog.pg_policies p
   WHERE p.schemaname = 'public' AND p.tablename = 'contract_acceptances'
     AND p.policyname = 'contract_acceptances_code_conduite_enseignant';
  IF v_policy.cmd IS DISTINCT FROM 'INSERT'
     OR v_policy.permissive IS DISTINCT FROM 'RESTRICTIVE'
     OR pg_catalog.strpos(v_policy.with_check, '(profile_id = auth.uid())') = 0
     OR pg_catalog.strpos(v_policy.with_check, '( SELECT app_role() AS app_role)') = 0
     OR pg_catalog.strpos(v_policy.with_check, 'pending_kyc') = 0
     OR pg_catalog.strpos(v_policy.with_check, 'code_conduite_version_requise()') = 0
     OR pg_catalog.strpos(v_policy.with_check, 'app_account_valid') > 0 THEN
    RAISE EXCEPTION 'PE conduite : policy du code de conduite invalide : %', v_policy.with_check;
  END IF;

  -- Inventaire des policies sans app_account_valid() : neuf, liste exacte.
  SELECT string_agg(p.tablename || '.' || p.policyname, ', '
                    ORDER BY p.tablename || '.' || p.policyname)
    INTO v_liste
    FROM pg_catalog.pg_policies p
   WHERE p.schemaname = 'public'
     AND (coalesce(p.qual, '') || coalesce(p.with_check, '')) LIKE '%app_role()%'
     AND (coalesce(p.qual, '') || coalesce(p.with_check, '')) NOT LIKE '%app_account_valid%';
  IF v_liste IS DISTINCT FROM 'contract_acceptances.contract_acceptances_code_conduite_enseignant, contract_acceptances.contract_acceptances_self_insert, households.households_guardian_select, intentions_horaire.intentions_horaire_parties, kyc_documents.kyc_guardian_insert, kyc_documents.kyc_staff_self_insert, offres_horaires.offres_horaires_vitrine, profiles.profiles_family_select, student_reading_position.srp_foyer_lecture' THEN
    RAISE EXCEPTION 'PE conduite : inventaire des policies sans app_account_valid inattendu : %', v_liste;
  END IF;

  -- etat_dossier : DEFINER stable, authenticated seul, empreinte a jour.
  -- teacher_signature_statuses : INVOKER stable, authenticated seul.
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = v_etat AND p.prosecdef AND p.provolatile = 's'
          AND p.proowner = 'postgres'::regrole
          AND coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']
          AND pg_catalog.strpos(p.prosrc, 'code_conduite_signe') > 0)
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = v_statuts AND NOT p.prosecdef AND p.provolatile = 's'
          AND p.proowner = 'postgres'::regrole
          AND coalesce(p.proconfig, ARRAY[]::text[]) @> ARRAY['search_path=""']
          AND pg_catalog.strpos(p.prosrc, 'teacher_conduct_code') > 0) THEN
    RAISE EXCEPTION 'PE conduite : etat_dossier ou teacher_signature_statuses invalide';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', v_etat, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_statuts, 'EXECUTE') THEN
    RAISE EXCEPTION 'PE conduite : authenticated perd une RPC du dossier';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_function_privilege(v_role, v_etat, 'EXECUTE')
       OR pg_catalog.has_function_privilege(v_role, v_statuts, 'EXECUTE') THEN
      RAISE EXCEPTION 'PE conduite : RPC du dossier executable par %', v_role;
    END IF;
  END LOOP;
  IF pg_catalog.strpos(coalesce(pg_catalog.obj_description(v_etat::oid, 'pg_proc'), ''),
       'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_etat))) = 0
     OR pg_catalog.strpos(coalesce(pg_catalog.obj_description(v_statuts::oid, 'pg_proc'), ''),
       'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_statuts))) = 0 THEN
    RAISE EXCEPTION 'PE conduite : empreinte F86 absente ou perimee';
  END IF;

  -- La version requise existe : sans elle, aucun enseignant ne serait active.
  IF public.code_conduite_version_requise() IS NULL THEN
    RAISE EXCEPTION 'PE conduite : version requise du code de conduite absente';
  END IF;
END;
$postflight$;

COMMIT;
