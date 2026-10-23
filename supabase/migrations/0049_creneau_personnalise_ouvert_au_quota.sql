-- 0049 — ouvrir un créneau personnalisé seulement quand la cohorte atteint
-- le quota du groupe (5 enfants, 6 adultes par app_config).
--
-- Une demande reste privée jusqu'au seuil. À l'ouverture, elle crée une offre
-- horaire normale, sans enseignant ni place réservée. Chaque famille confirme
-- ensuite son choix par choisir_offre_horaire(); ce RPC conserve la vérification
-- d'éligibilité et crée l'intention sans transformer le créneau en inscription.
BEGIN;

CREATE OR REPLACE FUNCTION public.jours_iso_valides(p_jours smallint[])
RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = ''
AS $function$
  SELECT p_jours IS NOT NULL
     AND coalesce(array_length(p_jours, 1), 0) BETWEEN 1 AND 7
     AND NOT EXISTS (
       SELECT 1 FROM unnest(p_jours) AS j
       WHERE j IS NULL OR j < 1 OR j > 7
     )
     AND coalesce(array_length(p_jours, 1), 0) =
         (SELECT count(DISTINCT j) FROM unnest(p_jours) AS j);
$function$;

ALTER TABLE public.offres_horaires
  ADD COLUMN origine text NOT NULL DEFAULT 'administration'
  CHECK (origine IN ('administration', 'quota_familial'));

CREATE TABLE public.demandes_creneau_personnalise (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  eleve_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type_public text NOT NULL CHECK (type_public IN ('enfant', 'adulte')),
  langue_code text NOT NULL REFERENCES public.langues_cours(code),
  fuseau_iana text NOT NULL,
  jours smallint[] NOT NULL,
  heure_locale smallint NOT NULL CHECK (heure_locale BETWEEN 0 AND 23),
  etat text NOT NULL DEFAULT 'en_attente_quota'
    CHECK (etat IN ('en_attente_quota', 'offre_ouverte', 'retiree')),
  offre_id uuid REFERENCES public.offres_horaires(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  retiree_at timestamptz,
  CONSTRAINT demande_creneau_jours_valides
    CHECK (coalesce(public.jours_iso_valides(jours), false)),
  CONSTRAINT demande_creneau_etat_coherent CHECK (
    (etat = 'offre_ouverte' AND offre_id IS NOT NULL)
    OR (etat <> 'offre_ouverte' AND offre_id IS NULL)
  )
);

CREATE UNIQUE INDEX demandes_creneau_eleve_vivant
  ON public.demandes_creneau_personnalise (eleve_id)
  WHERE etat IN ('en_attente_quota', 'offre_ouverte');

CREATE INDEX demandes_creneau_quota
  ON public.demandes_creneau_personnalise
     (type_public, langue_code, fuseau_iana, jours, heure_locale)
  WHERE etat = 'en_attente_quota';

ALTER TABLE public.demandes_creneau_personnalise ENABLE ROW LEVEL SECURITY;

CREATE POLICY demandes_creneau_lecture_propre
  ON public.demandes_creneau_personnalise
  FOR SELECT TO authenticated
  USING (
    eleve_id = auth.uid()
    OR coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false)
  );

REVOKE ALL ON public.demandes_creneau_personnalise
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT ON public.demandes_creneau_personnalise TO authenticated;

REVOKE ALL ON public.offres_horaires
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT (
  id, type_public, langue_code, fuseau_iana, jours, heure_locale,
  duree_minutes, programme_niveau_id, etat, publiee_at
) ON public.offres_horaires TO authenticated, agent_ro;

CREATE OR REPLACE FUNCTION public.choisir_offre_horaire(
  p_membre_id uuid,
  p_offre_id uuid,
  p_fuseau_vue text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_compatible record;
  v_demande public.demandes_creneau_personnalise%rowtype;
  v_demande_id uuid;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;

  SELECT * INTO v_demande
    FROM public.demandes_creneau_personnalise
   WHERE eleve_id = p_membre_id
     AND etat = 'en_attente_quota';
  IF FOUND THEN
    v_demande_id := v_demande.id;
    PERFORM pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        v_demande.type_public || '|' || v_demande.langue_code || '|' ||
        v_demande.fuseau_iana || '|' ||
        array_to_string(v_demande.jours, ',') || '|' ||
        v_demande.heure_locale::text,
        0
      )
    );
    SELECT * INTO v_demande
      FROM public.demandes_creneau_personnalise
     WHERE id = v_demande_id
       AND etat = 'en_attente_quota'
     FOR UPDATE;
  END IF;

  SELECT * INTO v_compatible
    FROM public.offres_compatibles(p_membre_id, p_fuseau_vue) o
   WHERE o.offre_id = p_offre_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'cette offre n''est pas compatible avec ce profil, ou n''est plus publiee';
  END IF;

  BEGIN
    INSERT INTO public.intentions_horaire
      (eleve_id, offre_id, fuseau_affiche, heure_affichee, jours_affiches, created_by)
    VALUES
      (p_membre_id, p_offre_id, p_fuseau_vue,
       v_compatible.heures_locales[1], v_compatible.jours_locaux, auth.uid())
    RETURNING id INTO v_id;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'cet apprenant a deja une preference horaire enregistree';
  END;

  UPDATE public.student_profiles
     SET diagnostic_statut = 'a_planifier'
   WHERE profile_id = p_membre_id
     AND diagnostic_statut = 'non_requis';

  IF v_demande_id IS NOT NULL AND v_demande.id IS NOT NULL THEN
    UPDATE public.demandes_creneau_personnalise
       SET etat = 'retiree', retiree_at = now(), offre_id = NULL
     WHERE id = v_demande_id
       AND etat = 'en_attente_quota'
    RETURNING * INTO v_demande;
    IF FOUND THEN
      PERFORM public.log_sensitive_access(
        'creneau_personnalise_retire_choix_offre',
        'demandes_creneau_personnalise', v_demande.id::text,
        jsonb_build_object('eleve_id', p_membre_id, 'offre_id', p_offre_id)
      );
    END IF;
  END IF;

  PERFORM public.log_sensitive_access(
    'intention_horaire_enregistree', 'intentions_horaire', v_id::text,
    jsonb_build_object('eleve_id', p_membre_id, 'offre_id', p_offre_id,
                       'fuseau_affiche', p_fuseau_vue)
  );
  RETURN v_id;
END;
$function$;

-- La demande n'expose aucun vivier. Le retour ne révèle que l'état de l'appelant.
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
  v_capacite integer;
  v_duree integer;
  v_seances_par_semaine integer;
  v_demande public.demandes_creneau_personnalise%rowtype;
  v_offre uuid;
  v_vivier integer;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;
  IF coalesce(btrim(p_fuseau_iana), '') = ''
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_fuseau_iana
     ) THEN
    RAISE EXCEPTION 'fuseau IANA invalide';
  END IF;
  IF p_heure_locale IS NULL OR p_heure_locale NOT BETWEEN 0 AND 23 THEN
    RAISE EXCEPTION 'heure locale invalide';
  END IF;
  v_jours := (
    SELECT array_agg(DISTINCT j ORDER BY j)
      FROM unnest(coalesce(p_jours, ARRAY[]::smallint[])) AS input(j)
  );
  IF NOT coalesce(public.jours_iso_valides(v_jours), false) THEN
    RAISE EXCEPTION 'jours invalides';
  END IF;
  v_seances_par_semaine :=
    public.app_config_int('groupe.seances_par_semaine', 3);
  IF v_seances_par_semaine IS NULL
     OR v_seances_par_semaine < 1
     OR coalesce(array_length(v_jours, 1), 0) <> v_seances_par_semaine THEN
    RAISE EXCEPTION 'nombre de séances par semaine invalide';
  END IF;

  SELECT c.type_public, sp.langue_cours
    INTO v_type, v_langue
    FROM public.student_profiles sp
    JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.actif
    JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.actif
   WHERE sp.profile_id = p_membre_id
     AND sp.deleted_at IS NULL
     AND public.peut_decrire_apprenant(p_membre_id);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'profil d''apprentissage incomplet';
  END IF;
  v_capacite := CASE v_type
    WHEN 'adulte' THEN public.app_config_int('groupe.capacite_adulte', 6)
    ELSE public.app_config_int('groupe.capacite_enfant', 5)
  END;
  v_duree := CASE v_type
    WHEN 'adulte' THEN public.app_config_int('seance.duree_minutes_adulte', 90)
    ELSE public.app_config_int('seance.duree_minutes_enfant', 60)
  END;
  IF v_capacite < 1 THEN
    RAISE EXCEPTION 'quota de lancement invalide';
  END IF;

  -- Les demandes partageant exactement la même plage sont sérialisées :
  -- deux dernières demandes concurrentes ne peuvent pas ouvrir deux offres.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      v_type || '|' || v_langue || '|' || p_fuseau_iana || '|' ||
      array_to_string(v_jours, ',') || '|' || p_heure_locale::text,
      0
    )
  );

  SELECT * INTO v_demande
    FROM public.demandes_creneau_personnalise
   WHERE eleve_id = p_membre_id
     AND etat IN ('en_attente_quota', 'offre_ouverte')
   FOR UPDATE;

  IF FOUND THEN
    IF v_demande.type_public IS DISTINCT FROM v_type
       OR v_demande.langue_code IS DISTINCT FROM v_langue
       OR v_demande.fuseau_iana IS DISTINCT FROM p_fuseau_iana
       OR v_demande.jours IS DISTINCT FROM v_jours
       OR v_demande.heure_locale IS DISTINCT FROM p_heure_locale THEN
      RAISE EXCEPTION 'retirez la demande actuelle avant d''en choisir une autre';
    END IF;
  ELSE
    BEGIN
      INSERT INTO public.demandes_creneau_personnalise
        (eleve_id, type_public, langue_code, fuseau_iana, jours, heure_locale)
      VALUES
        (p_membre_id, v_type, v_langue, p_fuseau_iana, v_jours, p_heure_locale)
      RETURNING * INTO v_demande;
    EXCEPTION WHEN unique_violation THEN
      SELECT * INTO STRICT v_demande
        FROM public.demandes_creneau_personnalise
       WHERE eleve_id = p_membre_id
         AND etat IN ('en_attente_quota', 'offre_ouverte')
       FOR UPDATE;
      IF v_demande.type_public IS DISTINCT FROM v_type
         OR v_demande.langue_code IS DISTINCT FROM v_langue
         OR v_demande.fuseau_iana IS DISTINCT FROM p_fuseau_iana
         OR v_demande.jours IS DISTINCT FROM v_jours
         OR v_demande.heure_locale IS DISTINCT FROM p_heure_locale THEN
        RAISE EXCEPTION 'retirez la demande actuelle avant d''en choisir une autre';
      END IF;
    END;
    PERFORM public.log_sensitive_access(
      'creneau_personnalise_demande', 'demandes_creneau_personnalise',
      v_demande.id::text,
      jsonb_build_object('eleve_id', p_membre_id, 'type_public', v_type,
                         'langue_code', v_langue)
    );
  END IF;

  IF v_demande.etat = 'offre_ouverte' THEN
    RETURN jsonb_build_object(
      'etat', 'offre_ouverte',
      'offre_id', v_demande.offre_id
    );
  END IF;

  -- Une première intention horaire doit être retirée avant de demander un
  -- créneau personnalisé. Le contrôle vient après la relecture idempotente :
  -- une répétition réseau réussit aussi après l'ouverture de l'offre.
  IF EXISTS (
    SELECT 1 FROM public.intentions_horaire i
    WHERE i.eleve_id = p_membre_id AND i.etat <> 'retiree'
  ) THEN
    RAISE EXCEPTION 'retirez d''abord la preference horaire actuelle';
  END IF;

  -- Après ouverture du quota, les nouveaux demandeurs du même créneau
  -- rejoignent l'offre publiée au lieu d'attendre un nouveau quota.
  SELECT id INTO v_offre
    FROM public.offres_horaires
   WHERE type_public = v_type
     AND langue_code = v_langue
     AND fuseau_iana = p_fuseau_iana
     AND jours = v_jours
     AND heure_locale = p_heure_locale
     AND etat = 'publiee'
   ORDER BY id
   LIMIT 1
   FOR UPDATE;

  IF v_offre IS NOT NULL THEN
    UPDATE public.demandes_creneau_personnalise
       SET etat = 'offre_ouverte', offre_id = v_offre
     WHERE id = v_demande.id;
    PERFORM public.log_sensitive_access(
      'creneau_personnalise_rattache_offre',
      'demandes_creneau_personnalise', v_demande.id::text,
      jsonb_build_object('eleve_id', p_membre_id, 'offre_id', v_offre)
    );
    RETURN jsonb_build_object('etat', 'offre_ouverte', 'offre_id', v_offre);
  END IF;

  -- Une offre retirée ne doit pas être recréée par les demandes familiales.
  IF EXISTS (
    SELECT 1
      FROM public.offres_horaires o
     WHERE o.type_public = v_type
       AND o.langue_code = v_langue
       AND o.fuseau_iana = p_fuseau_iana
       AND o.jours = v_jours
       AND o.heure_locale = p_heure_locale
       AND o.etat = 'retiree'
  ) THEN
    RETURN jsonb_build_object('etat', 'en_attente_quota');
  END IF;

  SELECT count(*)::integer INTO v_vivier
    FROM public.demandes_creneau_personnalise d
    JOIN public.profiles p ON p.id = d.eleve_id
    JOIN public.households h ON h.id = p.household_id
                           AND h.status = 'active'
                           AND h.deleted_at IS NULL
    JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
    JOIN public.cohortes_age c ON c.code = sp.cohorte
                               AND c.type_public = d.type_public
                               AND c.actif
   WHERE d.etat = 'en_attente_quota'
     AND d.type_public = v_type
     AND d.langue_code = v_langue
     AND d.fuseau_iana = p_fuseau_iana
     AND d.jours = v_jours
     AND d.heure_locale = p_heure_locale
     AND p.deleted_at IS NULL
     AND p.account_status IN ('pending_kyc', 'active', 'provisional_active')
     AND (p.access_until IS NULL OR p.access_until > now())
     AND sp.deleted_at IS NULL
     AND sp.cohorte IS NOT NULL
     AND sp.langue_cours = v_langue
     AND NOT EXISTS (
       SELECT 1 FROM public.intentions_horaire i
        WHERE i.eleve_id = d.eleve_id
          AND i.etat <> 'retiree'
     );

  IF v_vivier >= v_capacite THEN
    -- Une offre identique déjà publiée est réutilisée. Un brouillon existant
    -- n'est jamais publié par une demande familiale.
    INSERT INTO public.offres_horaires
      (type_public, langue_code, fuseau_iana, jours, heure_locale,
       duree_minutes, etat, created_by, publiee_at, publiee_par, origine)
    VALUES
      (v_type, v_langue, p_fuseau_iana, v_jours, p_heure_locale,
       v_duree, 'publiee', NULL, now(), NULL, 'quota_familial')
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_offre;

    IF v_offre IS NULL THEN
      SELECT id INTO v_offre
        FROM public.offres_horaires
       WHERE type_public = v_type
         AND langue_code = v_langue
         AND fuseau_iana = p_fuseau_iana
         AND jours = v_jours
         AND heure_locale = p_heure_locale
         AND etat = 'publiee'
       LIMIT 1;
    END IF;

    IF v_offre IS NOT NULL THEN
      UPDATE public.demandes_creneau_personnalise
         SET etat = 'offre_ouverte', offre_id = v_offre
       WHERE etat = 'en_attente_quota'
         AND type_public = v_type
         AND langue_code = v_langue
         AND fuseau_iana = p_fuseau_iana
         AND jours = v_jours
         AND heure_locale = p_heure_locale
         AND NOT EXISTS (
           SELECT 1 FROM public.intentions_horaire i
            WHERE i.eleve_id = demandes_creneau_personnalise.eleve_id
              AND i.etat <> 'retiree'
         );
      PERFORM public.log_sensitive_access(
        'creneau_personnalise_ouvert', 'offres_horaires', v_offre::text,
        jsonb_build_object('type_public', v_type, 'langue_code', v_langue,
                           'quota', v_capacite)
      );
      RETURN jsonb_build_object('etat', 'offre_ouverte', 'offre_id', v_offre);
    END IF;
  END IF;

  RETURN jsonb_build_object('etat', 'en_attente_quota');
END;
$function$;

REVOKE EXECUTE ON FUNCTION
  public.demander_creneau_personnalise(uuid, text, smallint[], smallint)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION
  public.demander_creneau_personnalise(uuid, text, smallint[], smallint)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.etat_creneau_personnalise(p_membre_id uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT CASE
    WHEN NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN NULL
    ELSE (
      SELECT jsonb_build_object(
        'etat', d.etat,
        'offre_id', d.offre_id
      )
      FROM public.demandes_creneau_personnalise d
      WHERE d.eleve_id = p_membre_id
        AND d.etat IN ('en_attente_quota', 'offre_ouverte')
    )
  END;
$function$;

REVOKE EXECUTE ON FUNCTION public.etat_creneau_personnalise(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.etat_creneau_personnalise(uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.retirer_creneau_personnalise(p_membre_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_demande public.demandes_creneau_personnalise%rowtype;
BEGIN
  IF NOT coalesce(public.peut_decrire_apprenant(p_membre_id), false) THEN
    RAISE EXCEPTION 'ce profil n''est pas le votre ni celui de votre foyer';
  END IF;

  SELECT * INTO v_demande
    FROM public.demandes_creneau_personnalise
   WHERE eleve_id = p_membre_id
     AND etat IN ('en_attente_quota', 'offre_ouverte');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucune demande de creneau personnalise active';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      v_demande.type_public || '|' || v_demande.langue_code || '|' ||
      v_demande.fuseau_iana || '|' ||
      array_to_string(v_demande.jours, ',') || '|' ||
      v_demande.heure_locale::text,
      0
    )
  );
  SELECT * INTO v_demande
    FROM public.demandes_creneau_personnalise
   WHERE id = v_demande.id
     AND etat IN ('en_attente_quota', 'offre_ouverte')
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucune demande de creneau personnalise active';
  END IF;

  UPDATE public.demandes_creneau_personnalise
     SET etat = 'retiree', retiree_at = now(), offre_id = NULL
   WHERE id = v_demande.id
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'aucune demande de creneau personnalise active';
  END IF;

  PERFORM public.log_sensitive_access(
    'creneau_personnalise_retire', 'demandes_creneau_personnalise',
    v_id::text, jsonb_build_object('eleve_id', p_membre_id)
  );
END;
$function$;
REVOKE EXECUTE ON FUNCTION public.retirer_creneau_personnalise(uuid)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.retirer_creneau_personnalise(uuid)
  TO authenticated;

COMMIT;
