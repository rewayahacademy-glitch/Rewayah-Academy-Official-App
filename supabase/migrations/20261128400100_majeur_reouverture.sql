-- MAJEUR : la direction remet a zero la declaration « 18 ans ou plus » (directeur, 16/11/2026,
-- decision du coordinateur sur la PR 517).
--
-- Une declaration « moins de 18 ans » est definitive pour le candidat (declaration_deja_faite).
-- Si la personne s'est trompee de case, seule la direction peut la remettre a zero, avec un motif
-- obligatoire. Effet : la declaration redevient « non faite » (le candidat la refait) ; si la
-- candidature etait en pause pour l'age (derniere pause ouverte, cause age), la pause est levee.
-- Tout est trace dans candidature_evenements (engagement, et reprise quand la pause est levee) et
-- dans le journal des acces sensibles. Rien n'est supprime.
--
-- Additive : une fonction nouvelle, aucune table, aucune suppression.
-- Un seul appelant : la direction active (admin, compte valide).

CREATE FUNCTION public.rouvrir_declaration_majorite_candidat(
  p_id uuid,
  p_version_attendue integer,
  p_motif text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_c public.candidatures;
  v_dernier public.candidature_evenements;
  v_leve boolean := false;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_ev bigint;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR p_version_attendue IS NULL OR v_motif = '' THEN
    RAISE EXCEPTION 'candidature, version attendue et motif obligatoires' USING ERRCODE = '22023';
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_introuvable');
  END IF;
  IF NOT coalesce(v_c.type_code = 'enseignant', false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'pas_du_recrutement');
  END IF;
  IF v_c.issue IS DISTINCT FROM 'en_cours' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_close');
  END IF;
  IF v_c.version IS DISTINCT FROM p_version_attendue THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'version_perimee');
  END IF;
  IF v_c.majorite_declaree IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'rien_a_rouvrir');
  END IF;

  -- La pause est levee seulement si elle vient de l'age : la derniere pause ou reprise de la
  -- candidature est une pause dont la cause est « age ».
  IF v_c.majorite_declaree = false AND v_c.en_pause THEN
    SELECT e.* INTO v_dernier
      FROM public.candidature_evenements e
     WHERE e.candidature_id = v_c.id AND e.type IN ('pause', 'reprise')
     ORDER BY e.id DESC LIMIT 1;
    v_leve := FOUND AND v_dernier.type = 'pause' AND coalesce(v_dernier.details ->> 'cause', '') = 'age';
  END IF;

  UPDATE public.candidatures
     SET majorite_declaree = NULL,
         majorite_attestee_le = NULL,
         en_pause = CASE WHEN v_leve THEN false ELSE en_pause END,
         version = version + 1,
         derniere_activite = v_maintenant
   WHERE id = v_c.id;

  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, motif_interne, details)
  VALUES (v_c.id, 'engagement', v_uid, v_motif,
          pg_catalog.jsonb_build_object('engagement', 'majorite', 'action', 'rouverte',
                                        'avant', v_c.majorite_declaree, 'auteur', 'direction'))
  RETURNING id INTO v_ev;
  IF v_leve THEN
    INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, motif_interne, details)
    VALUES (v_c.id, 'reprise', v_uid, v_motif,
            pg_catalog.jsonb_build_object('cause', 'age', 'auteur', 'direction',
                                          'geste', 'rouvrir_declaration_majorite'));
  END IF;
  PERFORM public.log_sensitive_access('candidature_geste', 'candidatures', v_c.id::text,
    pg_catalog.jsonb_build_object(
      'geste', 'rouvrir_declaration_majorite', 'auteur', 'direction', 'evenement', v_ev,
      'declarationAvant', v_c.majorite_declaree, 'pauseLevee', v_leve, 'version', v_c.version + 1));

  RETURN pg_catalog.jsonb_build_object(
    'rouverte', true,
    'pauseLevee', v_leve,
    'version', v_c.version + 1);
END;
$function$;

ALTER FUNCTION public.rouvrir_declaration_majorite_candidat(uuid, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rouvrir_declaration_majorite_candidat(uuid, integer, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.rouvrir_declaration_majorite_candidat(uuid, integer, text) TO authenticated;

DO $f86$
BEGIN
  EXECUTE pg_catalog.format(
    'COMMENT ON FUNCTION public.rouvrir_declaration_majorite_candidat(uuid, integer, text) IS %L',
    pg_catalog.format(
      'F86 candidate allowlist: signature=public.rouvrir_declaration_majorite_candidat(uuid,integer,text); md5_functiondef=%s; guard_type=POSITIVE_ADMIN_ACTIVE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-16. MAJEUR : direction active seule, sinon 42501 ; motif, version et candidature obligatoires (22023) ; candidature d enseignant en cours, version attendue, declaration existante ; remet la declaration a zero, leve la pause seulement si elle vient de l age ; trace (engagement, reprise) et journal des acces sensibles ; rien de supprime. Must-pass: supabase/tests/scenarios_majeur.sql.',
      pg_catalog.md5(pg_catalog.pg_get_functiondef(
        'public.rouvrir_declaration_majorite_candidat(uuid,integer,text)'::regprocedure))));
END;
$f86$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.rouvrir_declaration_majorite_candidat(uuid,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.rouvrir_declaration_majorite_candidat(uuid,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.rouvrir_declaration_majorite_candidat(uuid,integer,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.rouvrir_declaration_majorite_candidat(uuid,integer,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'MAJEUR : droits inattendus sur la reouverture';
  END IF;
END;
$postflight$;
