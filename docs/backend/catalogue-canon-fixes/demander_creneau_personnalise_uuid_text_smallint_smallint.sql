CREATE OR REPLACE FUNCTION public.demander_creneau_personnalise(p_membre_id uuid, p_fuseau_iana text, p_jours smallint[], p_heure_locale smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_type text;
  v_langue text;
  v_jours smallint[];
  v_demande public.demandes_horaires_famille%rowtype;
  v_heures smallint[];
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  IF coalesce(btrim(p_fuseau_iana), '') = ''
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_fuseau_iana) THEN
    RAISE EXCEPTION 'fuseau IANA invalide';
  END IF;
  IF p_heure_locale IS NULL OR p_heure_locale NOT BETWEEN 0 AND 23 THEN
    RAISE EXCEPTION 'heure locale invalide';
  END IF;
  v_jours := (
    SELECT array_agg(DISTINCT j ORDER BY j)
    FROM unnest(coalesce(p_jours, ARRAY[]::smallint[])) AS x(j)
  );
  IF NOT coalesce(public.jours_iso_valides(v_jours), false) THEN
    RAISE EXCEPTION 'jours invalides';
  END IF;

  SELECT c.type_public, sp.langue_cours INTO v_type, v_langue
  FROM public.student_profiles sp
  JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.actif
  JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.actif
  JOIN public.profiles p ON p.id = sp.profile_id
  JOIN public.households h ON h.id = p.household_id
  WHERE sp.profile_id = p_membre_id
    AND sp.deleted_at IS NULL
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active', 'pending_kyc')
    AND h.status = 'active'
    AND h.deleted_at IS NULL
    AND (p.access_until IS NULL OR p.access_until > now());
  IF NOT FOUND THEN
    RAISE EXCEPTION 'profil d''apprentissage incomplet ou indisponible';
  END IF;

  v_heures := array_fill(p_heure_locale, ARRAY[cardinality(v_jours)]);
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    v_type || '|' || v_langue || '|' || p_fuseau_iana || '|' ||
    array_to_string(v_jours, ',') || '|' || p_heure_locale::text, 0
  ));
  SELECT * INTO v_demande
  FROM public.demandes_horaires_famille
  WHERE eleve_id = p_membre_id
    AND etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')
  FOR UPDATE;
  IF FOUND THEN
    IF v_demande.source = 'personnalisee'
       AND v_demande.type_public = v_type
       AND v_demande.langue_code = v_langue
       AND v_demande.fuseau_iana = p_fuseau_iana
       AND v_demande.jours = v_jours
       AND v_demande.heures_locales = v_heures THEN
      RETURN jsonb_build_object(
        'id', v_demande.id, 'etat', v_demande.etat,
        'prochaine_etape', 'constitution_classe',
        'updated_at', v_demande.updated_at
      );
    END IF;
    RAISE EXCEPTION 'retirez votre demande actuelle avant d''en choisir une autre';
  END IF;

  INSERT INTO public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source)
  VALUES
    (p_membre_id, v_type, v_langue, p_fuseau_iana, v_jours, v_heures, 'personnalisee')
  RETURNING * INTO v_demande;
  PERFORM public.log_sensitive_access(
    'demande_horaire_personnalisee_envoyee', 'demandes_horaires_famille',
    v_demande.id::text, jsonb_build_object('eleve_id', p_membre_id)
  );
  RETURN jsonb_build_object(
    'id', v_demande.id, 'etat', v_demande.etat,
    'prochaine_etape', 'constitution_classe',
    'updated_at', v_demande.updated_at
  );
END;
$function$

