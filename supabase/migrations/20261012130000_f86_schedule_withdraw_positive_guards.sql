BEGIN;

CREATE OR REPLACE FUNCTION public.retirer_creneau_personnalise(p_membre_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() IN ('guardian', 'student'),
    false
  ) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer'
      USING ERRCODE = '42501';
  END IF;

  PERFORM public.retirer_demande_horaire(p_membre_id, 'retrait_famille');
END;
$function$;
ALTER FUNCTION public.retirer_creneau_personnalise(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.retirer_creneau_personnalise(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.retirer_creneau_personnalise(uuid)
  TO authenticated;
COMMENT ON FUNCTION public.retirer_creneau_personnalise(uuid) IS
  'F86 candidate allowlist: signature=public.retirer_creneau_personnalise(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.retirer_demande_horaire(
  p_membre_id uuid,
  p_motif text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_demandes integer := 0;
  v_intentions integer := 0;
  v_personnalisees integer := 0;
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() IN ('guardian', 'student'),
    false
  ) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer'
      USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer'
      USING ERRCODE = '42501';
  END IF;
  IF v_motif IS NULL THEN
    RAISE EXCEPTION 'un motif est requis pour retirer une demande horaire';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('demande-horaire:' || p_membre_id::text, 0)
  );

  UPDATE public.demandes_horaires_famille
     SET etat = 'retiree', motif = v_motif, updated_at = pg_catalog.now()
   WHERE eleve_id = p_membre_id
     AND etat = 'envoyee';
  GET DIAGNOSTICS v_demandes = ROW_COUNT;

  UPDATE public.intentions_horaire
     SET etat = 'retiree',
         retiree_at = pg_catalog.now(),
         retiree_par = auth.uid(),
         retrait_motif = v_motif
   WHERE eleve_id = p_membre_id
     AND etat <> 'retiree'
     AND groupe_id IS NULL;
  GET DIAGNOSTICS v_intentions = ROW_COUNT;

  UPDATE public.demandes_creneau_personnalise
     SET etat = 'retiree', retiree_at = pg_catalog.now(), offre_id = NULL
   WHERE eleve_id = p_membre_id
     AND etat IN ('en_attente_quota', 'offre_ouverte');
  GET DIAGNOSTICS v_personnalisees = ROW_COUNT;

  IF v_demandes + v_intentions + v_personnalisees = 0 THEN
    RAISE EXCEPTION 'aucune demande horaire active pour cet apprenant';
  END IF;

  PERFORM public.log_sensitive_access(
    'demande_horaire_retiree', 'demandes_horaires_famille',
    p_membre_id::text,
    pg_catalog.jsonb_build_object(
      'motif', v_motif,
      'demandes', v_demandes,
      'intentions', v_intentions,
      'personnalisees', v_personnalisees
    )
  );
END;
$function$;
ALTER FUNCTION public.retirer_demande_horaire(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.retirer_demande_horaire(uuid, text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.retirer_demande_horaire(uuid, text)
  TO authenticated;
COMMENT ON FUNCTION public.retirer_demande_horaire(uuid, text) IS
  'F86 candidate allowlist: signature=public.retirer_demande_horaire(uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.renoncer_intention_horaire(
  p_membre_id uuid,
  p_motif text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() IN ('guardian', 'student'),
    false
  ) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer'
      USING ERRCODE = '42501';
  END IF;

  PERFORM public.retirer_demande_horaire(p_membre_id, p_motif);
END;
$function$;
ALTER FUNCTION public.renoncer_intention_horaire(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.renoncer_intention_horaire(uuid, text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.renoncer_intention_horaire(uuid, text)
  TO authenticated;
COMMENT ON FUNCTION public.renoncer_intention_horaire(uuid, text) IS
  'F86 candidate allowlist: signature=public.renoncer_intention_horaire(uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

CREATE OR REPLACE FUNCTION public.signaler_horaire_insatisfait(
  p_membre_id uuid,
  p_detail jsonb
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_role public.app_role := public.app_role();
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
      AND public.app_role() IN ('guardian', 'student'),
    false
  ) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer'
      USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer'
      USING ERRCODE = '42501';
  END IF;

  IF v_role IS NULL THEN
    RAISE EXCEPTION 'compte sans role';
  END IF;

  INSERT INTO public.matching_requests
    (kind, subject_profile_id, rule_key, rule_value, reason, requested_by, requester_role)
  VALUES
    ('horaire_insatisfait', p_membre_id, 'offre_horaire',
     coalesce(p_detail, '{}'::jsonb),
     'aucun horaire propose ne convient a ce foyer',
     auth.uid(), v_role)
  RETURNING id INTO v_id;

  PERFORM public.log_sensitive_access(
    'horaire_insatisfait_signale', 'matching_requests', v_id::text,
    pg_catalog.jsonb_build_object('eleve_id', p_membre_id,
      'detail', coalesce(p_detail, '{}'::jsonb))
  );

  RETURN v_id;
END;
$function$;
ALTER FUNCTION public.signaler_horaire_insatisfait(uuid, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.signaler_horaire_insatisfait(uuid, jsonb)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.signaler_horaire_insatisfait(uuid, jsonb)
  TO authenticated;
COMMENT ON FUNCTION public.signaler_horaire_insatisfait(uuid, jsonb) IS
  'F86 candidate allowlist: signature=public.signaler_horaire_insatisfait(uuid,jsonb); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12.';

COMMIT;
