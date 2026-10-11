CREATE OR REPLACE FUNCTION public.creer_classe_depuis_regroupement(p_regroupement_id text, p_cle_idempotence uuid, p_libelle text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_type text;
  v_langue text;
  v_fuseau text;
  v_jours smallint[];
  v_heures smallint[];
  v_nombre integer;
  v_quota integer;
  v_groupe uuid;
  v_cle text;
  v_student uuid;
  v_i integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false)
     OR p_regroupement_id IS NULL
     OR p_cle_idempotence IS NULL
     OR coalesce(btrim(p_libelle), '') = '' THEN
    RAISE EXCEPTION 'creation de classe reservee a l''administration';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('classe-idempotence:' || p_cle_idempotence::text, 0)
  );

  SELECT groupe_id INTO v_groupe
  FROM public.demandes_horaires_creation_classe
  WHERE cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF EXISTS (
      SELECT 1 FROM public.demandes_horaires_creation_classe
      WHERE cle_idempotence = p_cle_idempotence
        AND regroupement_id = p_regroupement_id
    ) THEN
      RETURN v_groupe;
    END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee';
  END IF;

  SELECT r.regroupement_id, r.type_public, r.langue_code, r.fuseau_iana, r.jours,
         r.heures_locales, r.nombre_eleves, r.quota
    INTO v_cle, v_type, v_langue, v_fuseau, v_jours, v_heures, v_nombre, v_quota
  FROM public.regroupements_demandes_horaires_admin() AS r
  WHERE r.regroupement_id = p_regroupement_id AND r.pret IS TRUE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'regroupement absent ou quota non atteint';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('classe:' || p_regroupement_id, 0)
  );

  IF cardinality(v_jours) <> cardinality(v_heures)
     OR cardinality(v_jours) < 1
     OR cardinality(v_jours) <> (
       SELECT count(DISTINCT j) FROM unnest(v_jours) AS x(j)
     )
     OR v_nombre < v_quota THEN
    RAISE EXCEPTION 'regroupement invalide';
  END IF;

  INSERT INTO public.groupes
    (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
     timezone_iana, langue_code)
  VALUES
    (NULL, 'en_attente_enseignant', v_type, v_quota, btrim(p_libelle),
     v_jours[1], v_heures[1], v_fuseau, v_langue)
  RETURNING id INTO v_groupe;

  -- Le trigger d'ancrage crée le premier créneau; ON CONFLICT protège les
  -- variations historiques du schéma qui l'ajoutent déjà au même insert.
  FOR v_i IN 1..cardinality(v_jours) LOOP
    INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
    VALUES (v_groupe, v_jours[v_i], v_heures[v_i])
    ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;
  END LOOP;


  -- Un élève déjà membre actif ne peut pas être réinséré. Sa demande orpheline
  -- est close et notifiée avant de sélectionner les membres de cette classe.
  UPDATE public.demandes_horaires_famille d
     SET etat = 'refusee', motif = 'deja_en_classe', updated_at = pg_catalog.now()
   WHERE d.etat = 'envoyee'
     AND d.type_public = v_type AND d.langue_code = v_langue
     AND (
       (d.source = 'offre' AND 'o:' || d.offre_id::text = p_regroupement_id)
       OR (d.source = 'personnalisee'
         AND 'p:' || pg_catalog.md5(
           d.type_public || '|' || d.langue_code || '|' ||
           public.cle_horaire_utc(d.jours, d.heures_locales, d.fuseau_iana)
         ) = p_regroupement_id)
     )
     AND EXISTS (
       SELECT 1 FROM public.groupe_membres gm
       WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
     );

  FOR v_student IN

    SELECT d.eleve_id
    FROM public.demandes_horaires_famille d
    JOIN public.profiles p ON p.id = d.eleve_id
    JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
    JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.actif
    JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.actif
    JOIN public.households h ON h.id = p.household_id
    WHERE d.etat = 'envoyee'
      AND d.type_public = v_type AND d.langue_code = v_langue
      AND (
        (d.source = 'offre' AND 'o:' || d.offre_id::text = p_regroupement_id)
        OR (d.source = 'personnalisee'
          AND 'p:' || pg_catalog.md5(
            d.type_public || '|' || d.langue_code || '|' ||
            public.cle_horaire_utc(d.jours, d.heures_locales, d.fuseau_iana)
          ) = p_regroupement_id)
      )
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > now())
      AND h.status = 'active' AND h.deleted_at IS NULL
      AND sp.deleted_at IS NULL

      AND NOT EXISTS (
        SELECT 1 FROM public.groupe_membres gm
        WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
      )
      AND c.type_public = d.type_public

      AND l.code = d.langue_code
    ORDER BY d.created_at, d.eleve_id
    LIMIT v_quota
    FOR UPDATE OF d
  LOOP
    INSERT INTO public.groupe_membres (groupe_id, student_id)
    VALUES (v_groupe, v_student);
    UPDATE public.demandes_horaires_famille
       SET etat = 'classe_validee', groupe_id = v_groupe, updated_at = now()
     WHERE eleve_id = v_student AND etat = 'envoyee';
  END LOOP;

  IF (SELECT count(*) FROM public.groupe_membres
      WHERE groupe_id = v_groupe AND left_at IS NULL) < v_quota THEN
    RAISE EXCEPTION 'les demandes ont change pendant la creation';
  END IF;

  INSERT INTO public.demandes_horaires_creation_classe
    (cle_idempotence, regroupement_id, groupe_id, cree_par)
  VALUES (p_cle_idempotence, p_regroupement_id, v_groupe, auth.uid());

  PERFORM public.log_sensitive_access(
    'classe_creee_depuis_regroupement', 'groupes', v_groupe::text,
    jsonb_build_object('regroupement_id', p_regroupement_id)
  );
  IF pg_catalog.to_regclass('public.notifications') IS NOT NULL THEN
    EXECUTE $sql$
      INSERT INTO public.notifications
        (destinataire, foyer_id, evenement, params, destination)
      SELECT DISTINCT h.primary_guardian_id, h.id, 'classe_validee',
             jsonb_build_object('groupe_id', $1), '/tuteur/demandes'
      FROM public.groupe_membres gm
      JOIN public.profiles p ON p.id = gm.student_id
      JOIN public.households h ON h.id = p.household_id
      WHERE gm.groupe_id = $1 AND gm.left_at IS NULL
        AND h.primary_guardian_id IS NOT NULL
    $sql$ USING v_groupe;
  END IF;
  RETURN v_groupe;
END;
$function$

