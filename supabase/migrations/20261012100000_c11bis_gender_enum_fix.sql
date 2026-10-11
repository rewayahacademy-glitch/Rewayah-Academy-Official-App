-- C-11 bis: keep server-derived gender typed as the profile enum in comparisons.
BEGIN;

CREATE OR REPLACE FUNCTION public.creer_classe_depuis_regroupement(
  p_regroupement_id uuid,
  p_cle_idempotence uuid,
  p_libelle text
)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_type text;
  v_langue text;
  v_fuseau text;
  v_jours smallint[];
  v_heures smallint[];
  v_genre text;
  v_niveau text;
  v_quota integer;
  v_groupe uuid;
  v_student uuid;
  v_count integer;
BEGIN
  IF NOT coalesce(
       public.app_account_valid() AND public.app_role() = 'admin',
       false
     ) THEN
    RAISE EXCEPTION 'creation_classe_non_autorisee'
      USING ERRCODE = '42501';
  END IF;
  IF p_regroupement_id IS NULL
     OR p_cle_idempotence IS NULL
     OR coalesce(btrim(p_libelle), '') = '' THEN
    RAISE EXCEPTION 'parametres_creation_classe_invalides'
      USING ERRCODE = '22023';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('classe-idempotence:' || p_cle_idempotence::text, 0)
  );

  SELECT c.groupe_id INTO v_groupe
    FROM public.demandes_horaires_creation_classe c
   WHERE c.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF EXISTS (
      SELECT 1 FROM public.demandes_horaires_creation_classe c
       WHERE c.cle_idempotence = p_cle_idempotence
         AND c.regroupement_id = p_regroupement_id::text
    ) THEN
      RETURN v_groupe;
    END IF;
    RAISE EXCEPTION 'cle_idempotence_deja_utilisee';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('regroupement-c11bis:' || p_regroupement_id::text, 0)
  );

  SELECT
    d.type_public,
    d.langue_code,
    CASE p.gender WHEN 'male' THEN 'hommes' WHEN 'female' THEN 'femmes' END,
    d.niveau_declare,
    d.fuseau_iana,
    d.jours,
    d.heures_locales,
    CASE d.type_public
      WHEN 'adulte' THEN public.app_config_int('groupe.capacite_adulte', 6)
      ELSE public.app_config_int('groupe.capacite_enfant', 5)
    END
  INTO v_type, v_langue, v_genre, v_niveau, v_fuseau, v_jours, v_heures, v_quota
  FROM public.demandes_horaires_famille d
  JOIN public.profiles p ON p.id = d.eleve_id
  JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
  JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.type_public = d.type_public
  JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.code = d.langue_code
  JOIN public.households h ON h.id = p.household_id
  WHERE d.etat = 'envoyee'
    AND p.gender IN ('male', 'female')
    AND sp.niveau_declare = d.niveau_declare
    AND d.niveau_declare IN (
      'debut_lettres', 'lettres_avec_aide', 'lecture_lente',
      'lecture_courante', 'memorisation_partielle'
    )
    AND public.c11bis_id_regroupement(public.c11bis_cle_regroupement(
      d.type_public, d.langue_code, d.jours, d.heures_locales, d.fuseau_iana,
      CASE p.gender WHEN 'male' THEN 'hommes' WHEN 'female' THEN 'femmes' END,
      d.niveau_declare
    )) = p_regroupement_id
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND h.status = 'active' AND h.deleted_at IS NULL
    AND sp.deleted_at IS NULL
    AND c.actif AND l.actif
    AND NOT EXISTS (
      SELECT 1 FROM public.groupe_membres gm
       WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
    )
  ORDER BY d.created_at, d.id
  LIMIT 1
  FOR UPDATE OF d;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'regroupement_introuvable';
  END IF;

  SELECT count(*)::integer INTO v_count
    FROM public.demandes_horaires_famille d
    JOIN public.profiles p ON p.id = d.eleve_id
    JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
    JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.type_public = d.type_public
    JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.code = d.langue_code
    JOIN public.households h ON h.id = p.household_id
   WHERE d.etat = 'envoyee'
     AND p.gender = (CASE v_genre WHEN 'hommes' THEN 'male' WHEN 'femmes' THEN 'female' END)::public.gender
     AND d.type_public = v_type
     AND d.langue_code = v_langue
     AND d.niveau_declare = v_niveau
     AND sp.niveau_declare = d.niveau_declare
     AND public.c11bis_id_regroupement(public.c11bis_cle_regroupement(
       d.type_public, d.langue_code, d.jours, d.heures_locales, d.fuseau_iana,
       v_genre, d.niveau_declare
     )) = p_regroupement_id
     AND p.deleted_at IS NULL
     AND p.account_status IN ('active', 'provisional_active')
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
     AND h.status = 'active' AND h.deleted_at IS NULL
     AND sp.deleted_at IS NULL AND c.actif AND l.actif
     AND NOT EXISTS (
       SELECT 1 FROM public.groupe_membres gm
        WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
     );

  IF v_count < v_quota THEN
    RAISE EXCEPTION 'regroupement_incoherent';
  END IF;

  INSERT INTO public.groupes
    (teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
     timezone_iana, langue_code, genre_public, niveau)
  VALUES
    (NULL, 'en_attente_enseignant', v_type, v_quota, btrim(p_libelle),
     v_jours[1], v_heures[1], v_fuseau, v_langue, v_genre, v_niveau)
  RETURNING id INTO v_groupe;

  FOR v_count IN 1..cardinality(v_jours) LOOP
    INSERT INTO public.groupe_creneaux (groupe_id, weekday, hour_local)
    VALUES (v_groupe, v_jours[v_count], v_heures[v_count])
    ON CONFLICT (groupe_id, weekday, hour_local) DO NOTHING;
  END LOOP;

  FOR v_student IN
    SELECT d.eleve_id
      FROM public.demandes_horaires_famille d
      JOIN public.profiles p ON p.id = d.eleve_id
      JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
      JOIN public.cohortes_age c ON c.code = sp.cohorte AND c.type_public = d.type_public
      JOIN public.langues_cours l ON l.code = sp.langue_cours AND l.code = d.langue_code
      JOIN public.households h ON h.id = p.household_id
     WHERE d.etat = 'envoyee'
       AND p.gender = (CASE v_genre WHEN 'hommes' THEN 'male' WHEN 'femmes' THEN 'female' END)::public.gender
       AND d.type_public = v_type AND d.langue_code = v_langue
       AND d.niveau_declare = v_niveau AND sp.niveau_declare = d.niveau_declare
       AND public.c11bis_id_regroupement(public.c11bis_cle_regroupement(
         d.type_public, d.langue_code, d.jours, d.heures_locales, d.fuseau_iana,
         v_genre, d.niveau_declare
       )) = p_regroupement_id
       AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
       AND h.status = 'active' AND h.deleted_at IS NULL
       AND sp.deleted_at IS NULL AND c.actif AND l.actif
       AND NOT EXISTS (
         SELECT 1 FROM public.groupe_membres gm
          WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
       )
     ORDER BY d.created_at, d.id
     LIMIT v_quota
     FOR UPDATE OF d
  LOOP
    INSERT INTO public.groupe_membres (groupe_id, student_id)
    VALUES (v_groupe, v_student);
    UPDATE public.demandes_horaires_famille
       SET etat = 'classe_validee', groupe_id = v_groupe, updated_at = pg_catalog.now()
     WHERE eleve_id = v_student AND etat = 'envoyee';
  END LOOP;

  IF (SELECT count(*) FROM public.groupe_membres
       WHERE groupe_id = v_groupe AND left_at IS NULL) < v_quota THEN
    RAISE EXCEPTION 'regroupement_incoherent';
  END IF;

  INSERT INTO public.demandes_horaires_creation_classe
    (cle_idempotence, regroupement_id, groupe_id, cree_par)
  VALUES (p_cle_idempotence, p_regroupement_id::text, v_groupe, auth.uid());

  PERFORM public.log_sensitive_access(
    'classe_creee_depuis_regroupement', 'groupes', v_groupe::text,
    pg_catalog.jsonb_build_object(
      'regroupement_id', p_regroupement_id,
      'genre_public', v_genre,
      'niveau', v_niveau
    )
  );

  IF pg_catalog.to_regclass('public.notifications') IS NOT NULL THEN
    EXECUTE $sql$
      INSERT INTO public.notifications
        (destinataire, foyer_id, evenement, params, destination)
      SELECT DISTINCT h.primary_guardian_id, h.id, 'classe_validee',
             pg_catalog.jsonb_build_object('groupe_id', $1), '/tuteur/demandes'
        FROM public.groupe_membres gm
        JOIN public.profiles p ON p.id = gm.student_id
        JOIN public.households h ON h.id = p.household_id
       WHERE gm.groupe_id = $1
         AND gm.left_at IS NULL
         AND h.primary_guardian_id IS NOT NULL
    $sql$ USING v_groupe;
  END IF;

  RETURN v_groupe;
END;
$function$;

ALTER FUNCTION public.creer_classe_depuis_regroupement(uuid, uuid, text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.creer_classe_depuis_regroupement(uuid, uuid, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.creer_classe_depuis_regroupement(uuid, uuid, text)
  TO authenticated;
COMMENT ON FUNCTION public.creer_classe_depuis_regroupement(uuid, uuid, text) IS
  'F86 candidate allowlist: signature=public.creer_classe_depuis_regroupement(uuid, uuid, text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: no client gender/level input; server revalidates every member gender and snapshotted level before atomic class creation.';

DO $postflight$
DECLARE
  v_source text;
BEGIN
  SELECT p.prosrc INTO v_source
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.creer_classe_depuis_regroupement(uuid, uuid, text)'::regprocedure
     AND p.prosecdef
     AND p.proowner = 'postgres'::regrole
     AND p.proconfig @> ARRAY['search_path=""'];
  IF v_source IS NULL
     OR (length(v_source) - length(replace(v_source, '::public.gender', ''))) / length('::public.gender') <> 2
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'C-11 bis gender enum postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
