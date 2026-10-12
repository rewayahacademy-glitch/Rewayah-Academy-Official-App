BEGIN;

-- F86 batch: replace role-only admin comparisons with a positive, null-safe
-- guard that also rejects invalid or suspended accounts.
CREATE OR REPLACE FUNCTION public.maj_eleve_pedagogie(
  p_profile_id uuid,
  p_level text DEFAULT NULL,
  p_riwaya text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'seul un administrateur modifie le niveau ou la riwaya';
  END IF;

  UPDATE public.student_profiles
  SET level = coalesce(p_level, level),
      riwaya = coalesce(p_riwaya, riwaya)
  WHERE profile_id = p_profile_id AND deleted_at IS NULL;

  PERFORM public.log_sensitive_access('maj_pedagogie', 'student_profiles',
    p_profile_id::text,
    jsonb_build_object('level', p_level, 'riwaya', p_riwaya));
END;
$function$;
ALTER FUNCTION public.maj_eleve_pedagogie(uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.maj_eleve_pedagogie(uuid,text,text)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.maj_eleve_pedagogie(uuid,text,text) TO authenticated;
COMMENT ON FUNCTION public.maj_eleve_pedagogie(uuid,text,text) IS
  'F86 candidate allowlist: signature=public.maj_eleve_pedagogie(uuid,text,text); md5_functiondef=d520a13d7d56c740fdadc8291b7b0ac6; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.poser_regle(
  p_profile_id uuid,
  p_key text,
  p_value int,
  p_motif text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'seul un administrateur pose une regle';
  END IF;
  IF coalesce(btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'une regle sans motif ne se relit pas six mois plus tard';
  END IF;

  UPDATE public.rule_overrides
  SET ended_at = now(), ended_by = auth.uid(),
      end_reason = 'remplacee : ' || btrim(p_motif)
  WHERE profile_id = p_profile_id AND key = p_key AND ended_at IS NULL;

  INSERT INTO public.rule_overrides (profile_id, key, value, reason, set_by)
  VALUES (p_profile_id, p_key, to_jsonb(p_value), btrim(p_motif), auth.uid())
  RETURNING id INTO v_id;

  PERFORM public.log_sensitive_access('regle_posee', 'rule_overrides', v_id::text,
    jsonb_build_object('profile_id', p_profile_id, 'key', p_key, 'value', p_value));

  RETURN v_id;
END;
$function$;
ALTER FUNCTION public.poser_regle(uuid,text,integer,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.poser_regle(uuid,text,integer,text)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.poser_regle(uuid,text,integer,text) TO authenticated;
COMMENT ON FUNCTION public.poser_regle(uuid,text,integer,text) IS
  'F86 candidate allowlist: signature=public.poser_regle(uuid,text,integer,text); md5_functiondef=a3c7d8e4a47b497ca8089389114eba8e; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.clore_regle(p_override_id uuid, p_motif text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'seul un administrateur clot une regle';
  END IF;
  IF coalesce(btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'une cloture sans motif ne se relit pas';
  END IF;

  UPDATE public.rule_overrides
  SET ended_at = now(), ended_by = auth.uid(), end_reason = btrim(p_motif)
  WHERE id = p_override_id AND ended_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'regle introuvable ou deja close';
  END IF;

  PERFORM public.log_sensitive_access('regle_close', 'rule_overrides',
    p_override_id::text, jsonb_build_object('motif', btrim(p_motif)));
END;
$function$;
ALTER FUNCTION public.clore_regle(uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.clore_regle(uuid,text)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.clore_regle(uuid,text) TO authenticated;
COMMENT ON FUNCTION public.clore_regle(uuid,text) IS
  'F86 candidate allowlist: signature=public.clore_regle(uuid,text); md5_functiondef=23aa85aa637e93ad3d27de78f0c157dd; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.decider_demande(
  p_request_id uuid,
  p_accepte boolean,
  p_motif text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_d public.matching_requests;
  v_assignment uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'seul un administrateur tranche une demande';
  END IF;
  IF NOT p_accepte AND coalesce(btrim(p_motif), '') = '' THEN
    RAISE EXCEPTION 'un refus exige un motif';
  END IF;

  SELECT * INTO v_d FROM public.matching_requests
  WHERE id = p_request_id AND status = 'pending';
  IF v_d.id IS NULL THEN
    RAISE EXCEPTION 'demande introuvable ou deja tranchee';
  END IF;

  IF p_accepte THEN
    IF v_d.kind = 'reassignment' THEN
      UPDATE public.teacher_student_assignments
      SET ended_at = now(), ended_by = auth.uid(),
          end_reason = coalesce(btrim(p_motif), btrim(v_d.reason))
      WHERE student_id = v_d.subject_profile_id AND ended_at IS NULL
      RETURNING id INTO v_assignment;

      UPDATE public.sessions s
      SET status = 'canceled', updated_at = now()
      WHERE s.deleted_at IS NULL
        AND s.status = 'planned'
        AND s.started_at > now()
        AND EXISTS (
          SELECT 1 FROM public.session_participants sp
          WHERE sp.session_id = s.id AND sp.profile_id = v_d.subject_profile_id
            AND sp.deleted_at IS NULL
        );
    ELSE
      PERFORM public.poser_regle(
        v_d.subject_profile_id, v_d.rule_key, (v_d.rule_value #>> '{}')::int,
        'demande accordee : ' || v_d.reason);
    END IF;
  END IF;

  UPDATE public.matching_requests
  SET status = CASE WHEN p_accepte THEN 'approved' ELSE 'rejected' END,
      decided_by = auth.uid(), decided_at = now(),
      decision_reason = btrim(p_motif)
  WHERE id = p_request_id;

  PERFORM public.log_sensitive_access('demande_tranchee', 'matching_requests',
    p_request_id::text,
    jsonb_build_object('accepte', p_accepte, 'kind', v_d.kind));
END;
$function$;
ALTER FUNCTION public.decider_demande(uuid,boolean,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.decider_demande(uuid,boolean,text)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.decider_demande(uuid,boolean,text) TO authenticated;
COMMENT ON FUNCTION public.decider_demande(uuid,boolean,text) IS
  'F86 candidate allowlist: signature=public.decider_demande(uuid,boolean,text); md5_functiondef=ec9fe0b06d004bd701071201e3ad9707; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

DO $postflight$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace
  JOIN pg_catalog.pg_roles r ON r.oid=p.proowner
  WHERE (n.nspname,p.proname,pg_catalog.pg_get_function_identity_arguments(p.oid)) IN (
      ('public','maj_eleve_pedagogie','p_profile_id uuid, p_level text, p_riwaya text'),
      ('public','poser_regle','p_profile_id uuid, p_key text, p_value integer, p_motif text'),
      ('public','clore_regle','p_override_id uuid, p_motif text'),
      ('public','decider_demande','p_request_id uuid, p_accepte boolean, p_motif text'))
    AND p.prosecdef AND r.rolname='postgres'
    AND 'search_path=""' = ANY(coalesce(p.proconfig,ARRAY[]::text[]))
    AND NOT pg_catalog.has_function_privilege('anon',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('service_role',p.oid,'EXECUTE')
    AND NOT pg_catalog.has_function_privilege('agent_ro',p.oid,'EXECUTE')
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'NOT COALESCE') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'APP_ACCOUNT_VALID') > 0
    AND pg_catalog.strpos(pg_catalog.upper(p.prosrc),'APP_ROLE') > 0;
  IF v_count<>4 THEN
    RAISE EXCEPTION 'F86 admin guard batch postflight failed: % of 4',v_count;
  END IF;
END;
$postflight$;

COMMIT;
