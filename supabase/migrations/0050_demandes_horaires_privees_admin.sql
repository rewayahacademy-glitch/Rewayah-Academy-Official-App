-- 0050 — les choix familiaux sont des demandes privees, jamais des publications.
-- Decision du directeur: docs/current/DECISION-OFFRES-GROUPES-2026-10-09.md.
BEGIN;

CREATE OR REPLACE FUNCTION public.heures_locales_valides(p_heures smallint[])
RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = ''
AS $function$
  SELECT p_heures IS NOT NULL
     AND coalesce(array_length(p_heures, 1), 0) > 0
     AND NOT EXISTS (
       SELECT 1 FROM unnest(p_heures) h
       WHERE h IS NULL OR h < 0 OR h > 23
     );
$function$;
REVOKE EXECUTE ON FUNCTION public.heures_locales_valides(smallint[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.heures_locales_valides(smallint[]) TO authenticated;

CREATE TABLE public.demandes_horaires_famille (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  eleve_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type_public text NOT NULL CHECK (type_public IN ('enfant', 'adulte')),
  langue_code text NOT NULL REFERENCES public.langues_cours(code),
  fuseau_iana text NOT NULL CHECK (btrim(fuseau_iana) <> ''),
  jours smallint[] NOT NULL,
  heures_locales smallint[] NOT NULL,
  source text NOT NULL CHECK (source IN ('offre', 'personnalisee')),
  offre_id uuid REFERENCES public.offres_horaires(id),
  etat text NOT NULL DEFAULT 'envoyee'
    CHECK (etat IN ('envoyee', 'classe_validee', 'enseignant_affecte', 'refusee', 'retiree')),
  motif text,
  groupe_id uuid REFERENCES public.groupes(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT demande_horaire_jours CHECK (
    coalesce(public.jours_iso_valides(jours), false)
    AND cardinality(jours) = cardinality(heures_locales)
    AND public.heures_locales_valides(heures_locales)
  ),
  CONSTRAINT demande_horaire_source CHECK (
    (source = 'offre' AND offre_id IS NOT NULL)
    OR (source = 'personnalisee' AND offre_id IS NULL)
  ),
  CONSTRAINT demande_horaire_etat_groupe CHECK (
    (etat IN ('classe_validee', 'enseignant_affecte') AND groupe_id IS NOT NULL)
    OR (etat NOT IN ('classe_validee', 'enseignant_affecte'))
  )
);

CREATE UNIQUE INDEX demandes_horaires_famille_eleve_active
  ON public.demandes_horaires_famille (eleve_id)
  WHERE etat IN ('envoyee', 'classe_validee', 'enseignant_affecte');

CREATE INDEX demandes_horaires_famille_regroupement
  ON public.demandes_horaires_famille
     (type_public, langue_code, fuseau_iana, jours, heures_locales)
  WHERE etat = 'envoyee';

ALTER TABLE public.demandes_horaires_famille ENABLE ROW LEVEL SECURITY;
CREATE POLICY demandes_horaires_famille_lecture
  ON public.demandes_horaires_famille
  FOR SELECT TO authenticated
  USING (
    eleve_id = auth.uid()
    OR coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false)
  );
REVOKE ALL ON public.demandes_horaires_famille FROM PUBLIC, anon, authenticated, agent_ro;

-- Les requetes de famille ne renvoient que l'etat de l'appelant.
CREATE OR REPLACE FUNCTION public.mes_demandes_horaires(p_membre_id uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id,
    'etat', d.etat,
    'prochaine_etape', CASE d.etat
      WHEN 'envoyee' THEN 'constitution_classe'
      WHEN 'classe_validee' THEN 'affectation_enseignant'
      WHEN 'enseignant_affecte' THEN 'debut_cours'
      WHEN 'refusee' THEN 'choisir_autre_horaire'
      ELSE 'aucune'
    END,
    'motif', d.motif,
    'updated_at', d.updated_at
  ) ORDER BY d.created_at DESC), '[]'::jsonb)
  INTO v_result
  FROM public.demandes_horaires_famille d
  WHERE d.eleve_id = p_membre_id;
  RETURN v_result;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.mes_demandes_horaires(uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.mes_demandes_horaires(uuid) TO authenticated;

-- Une demande personnalisee est complete, privee et visible par l'administration
-- des son envoi. Le quota ne publie rien: il ne sert qu'a marquer le regroupement
-- comme pret dans la vue admin.
CREATE OR REPLACE FUNCTION public.demander_creneau_personnalise(
  p_membre_id uuid,
  p_fuseau_iana text,
  p_jours smallint[],
  p_heure_locale smallint
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
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
$function$;

REVOKE EXECUTE ON FUNCTION public.demander_creneau_personnalise(uuid, text, smallint[], smallint)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.demander_creneau_personnalise(uuid, text, smallint[], smallint)
  TO authenticated;

-- Le choix d'une carte laisse sa preference historique, et crée la même demande
-- privée que le créneau personnalisé. Les heures locales restent parallèles aux jours.
CREATE OR REPLACE FUNCTION public.choisir_offre_horaire(
  p_membre_id uuid,
  p_offre_id uuid,
  p_fuseau_vue text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_compatible record;
  v_intention uuid;
  v_demande public.demandes_horaires_famille%rowtype;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  SELECT * INTO v_compatible
  FROM public.offres_compatibles(p_membre_id, p_fuseau_vue) o
  WHERE o.offre_id = p_offre_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'cette offre n''est pas compatible avec ce profil, ou n''est plus publiee';
  END IF;

  SELECT * INTO v_demande
  FROM public.demandes_horaires_famille
  WHERE eleve_id = p_membre_id
    AND etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')
  FOR UPDATE;
  IF FOUND THEN
    RAISE EXCEPTION 'retirez votre demande actuelle avant d''en choisir une autre';
  END IF;

  INSERT INTO public.intentions_horaire
    (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
  VALUES
    (p_membre_id, p_offre_id, p_fuseau_vue,
     v_compatible.heures_locales[1], v_compatible.jours_locaux, auth.uid())
  RETURNING id INTO v_intention;

  INSERT INTO public.demandes_horaires_famille
    (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, offre_id)
  VALUES
    (p_membre_id, v_compatible.type_public, v_compatible.langue_code, p_fuseau_vue,
     v_compatible.jours_locaux, v_compatible.heures_locales, 'offre', p_offre_id);

  UPDATE public.student_profiles SET diagnostic_statut = 'a_planifier'
  WHERE profile_id = p_membre_id AND diagnostic_statut = 'non_requis';
  PERFORM public.log_sensitive_access(
    'intention_horaire_enregistree', 'intentions_horaire', v_intention::text,
    jsonb_build_object('eleve_id', p_membre_id, 'offre_id', p_offre_id)
  );
  RETURN v_intention;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.choisir_offre_horaire(uuid, uuid, text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.choisir_offre_horaire(uuid, uuid, text) TO authenticated;

-- La file et le seuil appartiennent à l'administration. La fonction ne rend
-- aucune identité ni liste familiale; elle renvoie une clé opaque de regroupement.
CREATE OR REPLACE FUNCTION public.etat_creneau_personnalise(p_membre_id uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT CASE
    WHEN coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN (
      SELECT jsonb_build_object('etat', d.etat)
      FROM public.demandes_horaires_famille d
      WHERE d.eleve_id = p_membre_id
        AND d.source = 'personnalisee'
        AND d.etat IN ('envoyee', 'classe_validee', 'enseignant_affecte')
      ORDER BY d.created_at DESC LIMIT 1
    )
    ELSE NULL
  END;
$function$;
REVOKE EXECUTE ON FUNCTION public.etat_creneau_personnalise(uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.etat_creneau_personnalise(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.retirer_creneau_personnalise(p_membre_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_demande public.demandes_horaires_famille%rowtype;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  SELECT * INTO v_demande
    FROM public.demandes_horaires_famille
   WHERE eleve_id = p_membre_id AND source = 'personnalisee'
     AND etat = 'envoyee'
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucune demande de creneau personnalise active';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    v_demande.type_public || '|' || v_demande.langue_code || '|' ||
    v_demande.fuseau_iana || '|' || array_to_string(v_demande.jours, ',') || '|' ||
    array_to_string(v_demande.heures_locales, ','), 0
  ));
  UPDATE public.demandes_horaires_famille
     SET etat = 'retiree', updated_at = now()
   WHERE id = v_demande.id AND etat = 'envoyee';
  PERFORM public.log_sensitive_access(
    'creneau_personnalise_retire', 'demandes_horaires_famille',
    v_demande.id::text, jsonb_build_object('eleve_id', p_membre_id)
  );
END;
$function$;
REVOKE EXECUTE ON FUNCTION public.retirer_creneau_personnalise(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.retirer_creneau_personnalise(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.regroupements_demandes_horaires_admin()
RETURNS TABLE (
  regroupement_id text,
  type_public text,
  langue_code text,
  fuseau_iana text,
  jours smallint[],
  heures_locales smallint[],
  nombre_eleves integer,
  quota integer,
  pret boolean
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces reserve a l''administration';
  END IF;
  RETURN QUERY
  SELECT md5(concat_ws('|', d.type_public, d.langue_code, d.fuseau_iana,
                       array_to_string(d.jours, ','), array_to_string(d.heures_locales, ','))),
         d.type_public, d.langue_code, d.fuseau_iana, d.jours, d.heures_locales,
         count(*)::integer,
         CASE d.type_public
           WHEN 'adulte' THEN public.app_config_int('groupe.capacite_adulte', 6)
           ELSE public.app_config_int('groupe.capacite_enfant', 5)
         END,
         count(*) >= CASE d.type_public
           WHEN 'adulte' THEN public.app_config_int('groupe.capacite_adulte', 6)
           ELSE public.app_config_int('groupe.capacite_enfant', 5)
         END
  FROM public.demandes_horaires_famille d
  JOIN public.profiles p ON p.id = d.eleve_id
    AND p.deleted_at IS NULL
    AND p.account_status IN ('pending_kyc', 'active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > now())
  JOIN public.households h ON h.id = p.household_id
    AND h.status = 'active'
    AND h.deleted_at IS NULL
  JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
    AND sp.deleted_at IS NULL
  JOIN public.cohortes_age c ON c.code = sp.cohorte
    AND c.type_public = d.type_public AND c.actif
  JOIN public.langues_cours l ON l.code = sp.langue_cours
    AND l.code = d.langue_code AND l.actif
  WHERE d.etat = 'envoyee'
  GROUP BY d.type_public, d.langue_code, d.fuseau_iana, d.jours, d.heures_locales
  ORDER BY d.type_public, d.langue_code, d.fuseau_iana, d.jours, d.heures_locales;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.regroupements_demandes_horaires_admin() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.regroupements_demandes_horaires_admin() TO authenticated;

COMMIT;
