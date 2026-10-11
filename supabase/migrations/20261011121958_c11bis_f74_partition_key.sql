-- C-11 bis / F74: partition requests by their authoritative student attributes.
BEGIN;

ALTER TABLE public.groupes
  ADD COLUMN niveau text;

ALTER TABLE public.groupes
  ADD CONSTRAINT groupes_niveau_declare_valide
  CHECK (niveau IS NULL OR niveau IN (
    'debut_lettres',
    'lettres_avec_aide',
    'lecture_lente',
    'lecture_courante',
    'memorisation_partielle'
  ));

COMMENT ON COLUMN public.groupes.niveau IS
  'Niveau déclaré du regroupement, dérivé côté serveur lors de la création.';

ALTER TABLE public.demandes_horaires_famille
  ADD COLUMN niveau_declare text;

ALTER TABLE public.demandes_horaires_famille
  ADD CONSTRAINT demandes_horaires_niveau_declare_valide
  CHECK (niveau_declare IS NULL OR niveau_declare IN (
    'debut_lettres',
    'lettres_avec_aide',
    'lecture_lente',
    'lecture_courante',
    'memorisation_partielle'
  ));

-- Pre-existing requests remain incomplete until an authorized caller explicitly
-- snapshots the current server-side profile level through the completion RPC.

CREATE INDEX demandes_horaires_famille_f74_partition
  ON public.demandes_horaires_famille (type_public, langue_code, niveau_declare)
  WHERE etat = 'envoyee';

CREATE OR REPLACE FUNCTION public.snapshot_niveau_demande_horaire()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_niveau text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT sp.niveau_declare
      INTO NEW.niveau_declare
      FROM public.student_profiles sp
     WHERE sp.profile_id = NEW.eleve_id
       AND sp.deleted_at IS NULL;
    RETURN NEW;
  END IF;

  IF NEW.niveau_declare IS DISTINCT FROM OLD.niveau_declare THEN
    SELECT sp.niveau_declare INTO v_niveau
      FROM public.student_profiles sp
     WHERE sp.profile_id = NEW.eleve_id
       AND sp.deleted_at IS NULL;
    IF OLD.niveau_declare IS NOT NULL
       OR NEW.niveau_declare IS DISTINCT FROM v_niveau THEN
      RAISE EXCEPTION 'niveau_demande_immuable';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.snapshot_niveau_demande_horaire()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER demandes_horaires_snapshot_niveau_insert
BEFORE INSERT
ON public.demandes_horaires_famille
FOR EACH ROW
EXECUTE FUNCTION public.snapshot_niveau_demande_horaire();

CREATE TRIGGER demandes_horaires_snapshot_niveau_update
BEFORE UPDATE OF niveau_declare
ON public.demandes_horaires_famille
FOR EACH ROW
EXECUTE FUNCTION public.snapshot_niveau_demande_horaire();

CREATE OR REPLACE FUNCTION public.completer_niveau_demande_horaire(p_eleve_id uuid)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_niveau text;
BEGIN
  IF NOT coalesce(
       public.app_account_valid()
       AND public.app_role() IN ('student', 'guardian'),
       false
     ) THEN
    RAISE EXCEPTION 'acces_profil_demande_refuse'
      USING ERRCODE = '42501';
  END IF;

  IF p_eleve_id IS NULL
     OR NOT coalesce(public.peut_decrire_apprenant(p_eleve_id), false) THEN
    RAISE EXCEPTION 'acces_profil_demande_refuse'
      USING ERRCODE = '42501';
  END IF;

  SELECT sp.niveau_declare INTO v_niveau
    FROM public.student_profiles sp
   WHERE sp.profile_id = p_eleve_id
     AND sp.deleted_at IS NULL;

  IF v_niveau IS NULL OR v_niveau NOT IN (
    'debut_lettres', 'lettres_avec_aide', 'lecture_lente',
    'lecture_courante', 'memorisation_partielle'
  ) THEN
    RETURN false;
  END IF;

  UPDATE public.demandes_horaires_famille d
     SET niveau_declare = v_niveau
   WHERE d.eleve_id = p_eleve_id
     AND d.etat = 'envoyee'
     AND d.niveau_declare IS NULL;

  RETURN FOUND;
END;
$function$;

ALTER FUNCTION public.completer_niveau_demande_horaire(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.completer_niveau_demande_horaire(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.completer_niveau_demande_horaire(uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.c11bis_cle_regroupement(
  p_type_public text,
  p_langue_code text,
  p_jours smallint[],
  p_heures_locales smallint[],
  p_fuseau_iana text,
  p_genre_public text,
  p_niveau text
)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT p_type_public || '|' || p_langue_code || '|' ||
         public.cle_horaire_utc(p_jours, p_heures_locales, p_fuseau_iana) || '|' ||
         p_genre_public || '|' || p_niveau
$function$;

CREATE OR REPLACE FUNCTION public.c11bis_id_regroupement(p_cle text)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = ''
AS $function$
  SELECT pg_catalog.md5(p_cle)::uuid
$function$;

REVOKE ALL ON FUNCTION public.c11bis_cle_regroupement(text, text, smallint[], smallint[], text, text, text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.c11bis_cle_regroupement(text, text, smallint[], smallint[], text, text, text)
  TO authenticated;
REVOKE ALL ON FUNCTION public.c11bis_id_regroupement(text)
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.c11bis_id_regroupement(text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.regroupements_c11bis_admin()
RETURNS SETOF jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid() AND public.app_role() = 'admin',
    false
  ) THEN
    RAISE EXCEPTION 'regroupements_reserves_administration'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH demandes AS (
    SELECT
      d.*,
      p.gender,
      CASE p.gender
        WHEN 'male' THEN 'hommes'
        WHEN 'female' THEN 'femmes'
        ELSE NULL
      END AS genre_public,
      sp.niveau_declare AS niveau_actuel,
      CASE WHEN d.niveau_declare IN (
        'debut_lettres', 'lettres_avec_aide', 'lecture_lente',
        'lecture_courante', 'memorisation_partielle'
      ) THEN d.niveau_declare ELSE NULL END AS niveau,
      public.cle_horaire_utc(d.jours, d.heures_locales, d.fuseau_iana) AS cle_utc,
      h.timezone,
      (p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
       AND h.status = 'active' AND h.deleted_at IS NULL
       AND sp.deleted_at IS NULL
       AND c.actif AND l.actif
       AND NOT EXISTS (
         SELECT 1 FROM public.groupe_membres gm
          WHERE gm.student_id = d.eleve_id AND gm.left_at IS NULL
       )) AS eligible
    FROM public.demandes_horaires_famille d
    JOIN public.profiles p ON p.id = d.eleve_id
    LEFT JOIN public.student_profiles sp ON sp.profile_id = d.eleve_id
    LEFT JOIN public.cohortes_age c
      ON c.code = sp.cohorte AND c.type_public = d.type_public
    LEFT JOIN public.langues_cours l
      ON l.code = d.langue_code AND l.code = sp.langue_cours
    LEFT JOIN public.households h ON h.id = p.household_id
    WHERE d.etat = 'envoyee'
  ),
  complets AS (
    SELECT d.*,
      public.c11bis_cle_regroupement(
        d.type_public, d.langue_code, d.jours, d.heures_locales,
        d.fuseau_iana, d.genre_public, d.niveau
      ) AS cle_famille
    FROM demandes d
    WHERE d.eligible
      AND d.genre_public IS NOT NULL
      AND d.niveau IS NOT NULL
  ),
  agr AS (
    SELECT
      public.c11bis_id_regroupement(cle_famille) AS regroupement_id,
      cle_famille,
      type_public,
      langue_code,
      genre_public,
      niveau,
      count(*)::integer AS nombre_eleves,
      CASE type_public
        WHEN 'adulte' THEN public.app_config_int('groupe.capacite_adulte', 6)
        ELSE public.app_config_int('groupe.capacite_enfant', 5)
      END AS quota
    FROM complets
    GROUP BY cle_famille, type_public, langue_code, genre_public, niveau
  ),
  inconnus AS (
    SELECT d.*,
      CASE
        WHEN d.genre_public IS NULL THEN 'genre_inconnu'
        ELSE 'niveau_inconnu'
      END AS motif_incomplet
    FROM demandes d
    WHERE d.eligible
      AND (d.genre_public IS NULL OR d.niveau IS NULL)
  )
  SELECT pg_catalog.jsonb_build_object(
    'regroupement_id', a.regroupement_id,
    'type_public', a.type_public,
    'langue_code', a.langue_code,
    'langue_nom', lc.nom_humain,
    'genre_public', a.genre_public,
    'niveau', a.niveau,
    'fuseau_iana', e.fuseau_iana,
    'occurrences', (
      SELECT coalesce(pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'jour_iso', e.jours[i], 'heure', e.heures_locales[i], 'minute', 0
        ) ORDER BY i
      ), '[]'::jsonb)
      FROM pg_catalog.generate_subscripts(e.jours, 1) AS positions(i)
    ),
    'nombre_eleves', a.nombre_eleves,
    'quota', a.quota,
    'autres_fuseaux', coalesce(e.autres_fuseaux, '[]'::jsonb),
    'peut_creer_classe', a.nombre_eleves >= a.quota,
    'classe', e.classe
  )
  FROM agr a
  JOIN public.langues_cours lc ON lc.code = a.langue_code
  LEFT JOIN LATERAL (
    SELECT c.*,
      CASE WHEN existing.groupe_id IS NULL THEN NULL ELSE
        pg_catalog.jsonb_build_object(
          'classe_id', existing.groupe_id,
          'libelle', existing.libelle,
          'genre_classe', existing.genre_public,
          'peut_affecter_enseignant', false
        ) END AS classe,
      (
        SELECT pg_catalog.jsonb_agg(
          pg_catalog.jsonb_build_object(
            'fuseau', z.timezone,
            'jour_iso', h.heure ->> 'jour_iso',
            'heure', (h.heure ->> 'heure')::integer,
            'minute', (h.heure ->> 'minute')::integer,
            'decalage_jour', (h.heure ->> 'decalage_jour')::integer
          ) ORDER BY z.timezone, (h.heure ->> 'jour_iso')::integer
        )
        FROM (
          SELECT DISTINCT d.timezone
            FROM complets d
           WHERE d.cle_famille = a.cle_famille
             AND d.timezone <> c.fuseau_iana
        ) z
        CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(
          public.traduire_occurrences_fuseau(
            c.jours, c.heures_locales, c.fuseau_iana, z.timezone
          )
        ) h(heure)
      ) AS autres_fuseaux
    FROM LATERAL (
      SELECT d.fuseau_iana, d.jours, d.heures_locales
        FROM complets d
       WHERE d.cle_famille = a.cle_famille
       ORDER BY d.created_at, d.id
       LIMIT 1
    ) c
    LEFT JOIN LATERAL (
      SELECT g.id AS groupe_id, g.libelle, g.genre_public
        FROM public.groupes g
       WHERE g.ended_at IS NULL
         AND g.type_public = a.type_public
         AND g.langue_code = a.langue_code
         AND g.genre_public = a.genre_public
         AND g.niveau = a.niveau
         AND public.cle_horaire_utc(
           ARRAY(SELECT gc.weekday FROM public.groupe_creneaux gc
                  WHERE gc.groupe_id = g.id ORDER BY gc.weekday, gc.hour_local),
           ARRAY(SELECT gc.hour_local FROM public.groupe_creneaux gc
                  WHERE gc.groupe_id = g.id ORDER BY gc.weekday, gc.hour_local),
           g.timezone_iana
         ) = public.cle_horaire_utc(
           c.jours, c.heures_locales, c.fuseau_iana
         )
       ORDER BY g.created_at, g.id
       LIMIT 1
    ) existing ON true
  ) e ON true

  UNION ALL

  SELECT pg_catalog.jsonb_build_object(
    'regroupement_id', i.id,
    'type_public', i.type_public,
    'langue_code', i.langue_code,
    'langue_nom', lc.nom_humain,
    'genre_public', i.genre_public,
    'niveau', i.niveau,
    'etat', 'a_completer',
    'motif_a_completer', i.motif_incomplet,
    'fuseau_iana', i.fuseau_iana,
    'occurrences', (
      SELECT coalesce(pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'jour_iso', i.jours[j], 'heure', i.heures_locales[j], 'minute', 0
        ) ORDER BY j
      ), '[]'::jsonb)
      FROM pg_catalog.generate_subscripts(i.jours, 1) AS positions(j)
    ),
    'nombre_eleves', 1,
    'quota', CASE i.type_public
      WHEN 'adulte' THEN public.app_config_int('groupe.capacite_adulte', 6)
      ELSE public.app_config_int('groupe.capacite_enfant', 5)
    END,
    'autres_fuseaux', '[]'::jsonb,
    'peut_creer_classe', false,
    'classe', NULL
  )
  FROM inconnus i
  JOIN public.langues_cours lc ON lc.code = i.langue_code

  UNION ALL

  SELECT pg_catalog.jsonb_build_object(
    'regroupement_id', 'g:' || g.id::text,
    'type_public', g.type_public,
    'langue_code', g.langue_code,
    'langue_nom', lc.nom_humain,
    'genre_public', g.genre_public,
    'niveau', g.niveau,
    'fuseau_iana', g.timezone_iana,
    'occurrences', coalesce(slots.valeurs, '[]'::jsonb),
    'nombre_eleves', membres.nombre,
    'quota', g.seuil_max,
    'autres_fuseaux', '[]'::jsonb,
    'peut_creer_classe', false,
    'classe', pg_catalog.jsonb_build_object(
      'classe_id', g.id,
      'libelle', g.libelle,
      'genre_classe', g.genre_public,
      'peut_affecter_enseignant', false
    )
  )
  FROM public.classes_a_confirmer_admin() a
  JOIN public.groupes g ON g.id = a.classe_id
  JOIN public.langues_cours lc ON lc.code = g.langue_code
  LEFT JOIN LATERAL (
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'jour_iso', gc.weekday, 'heure', gc.hour_local, 'minute', 0
    ) ORDER BY gc.weekday, gc.hour_local) AS valeurs
    FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
  ) slots ON true
  LEFT JOIN LATERAL (
    SELECT count(*)::integer AS nombre
    FROM public.groupe_membres gm
    WHERE gm.groupe_id = g.id AND gm.left_at IS NULL
  ) membres ON true
  ORDER BY 1;
END;
$function$;

REVOKE ALL ON FUNCTION public.regroupements_c11bis_admin()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.regroupements_c11bis_admin()
  TO authenticated;
ALTER FUNCTION public.regroupements_c11bis_admin() OWNER TO postgres;

-- The legacy projection merges dimensions now required by F74. Keep its
-- identity for dependent old code, but make it unavailable as an API.
REVOKE ALL ON FUNCTION public.regroupements_demandes_horaires_admin()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- F74 creation uses only the server-derived grouping UUID and snapshots.
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
     )
     OR p_regroupement_id IS NULL
     OR p_cle_idempotence IS NULL
     OR coalesce(btrim(p_libelle), '') = '' THEN
    RAISE EXCEPTION 'creation_classe_non_autorisee'
      USING ERRCODE = '42501';
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
     AND p.gender = CASE v_genre WHEN 'hommes' THEN 'male' WHEN 'femmes' THEN 'female' END
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
       AND p.gender = CASE v_genre WHEN 'hommes' THEN 'male' WHEN 'femmes' THEN 'female' END
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

REVOKE ALL ON FUNCTION public.creer_classe_depuis_regroupement(text, uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.creer_classe_depuis_regroupement_c11bis(text, uuid, text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION public.regroupements_c11bis_admin() IS
  'F86 candidate allowlist: signature=public.regroupements_c11bis_admin(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: requests are partitioned by UTC schedule, public, language, server-derived gender and request-level declared level; unknown attributes are returned individually as a_completer.';

COMMENT ON FUNCTION public.creer_classe_depuis_regroupement(uuid, uuid, text) IS
  'F86 candidate allowlist: signature=public.creer_classe_depuis_regroupement(uuid, uuid, text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: no client gender/level input; server revalidates every member gender and snapshotted level before atomic class creation.';

COMMENT ON FUNCTION public.completer_niveau_demande_horaire(uuid) IS
  'F86 candidate allowlist: signature=public.completer_niveau_demande_horaire(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: only the active student or guardian may copy the server-stored declared level into that learner’s incomplete active request.';

DO $postflight$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.regroupements_c11bis_admin()'::regprocedure
       AND p.prosecdef
       AND p.proowner = 'postgres'::regrole
       AND p.proconfig @> ARRAY['search_path=""']
       AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE '%md5_functiondef=A_CALCULER%'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.creer_classe_depuis_regroupement(uuid, uuid, text)'::regprocedure
       AND p.prosecdef
       AND p.proowner = 'postgres'::regrole
       AND p.proconfig @> ARRAY['search_path=""']
       AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE '%md5_functiondef=A_CALCULER%'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid = 'public.completer_niveau_demande_horaire(uuid)'::regprocedure
       AND p.prosecdef
       AND p.proowner = 'postgres'::regrole
       AND p.proconfig @> ARRAY['search_path=""']
       AND pg_catalog.obj_description(p.oid, 'pg_proc') LIKE '%md5_functiondef=A_CALCULER%'
  ) OR pg_catalog.has_function_privilege(
       'anon', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     ) OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     ) OR pg_catalog.has_function_privilege(
       'service_role', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
     ) OR NOT pg_catalog.has_function_privilege(
       'authenticated', 'public.creer_classe_depuis_regroupement(uuid, uuid, text)', 'EXECUTE'
  ) OR pg_catalog.has_function_privilege(
       'authenticated', 'public.creer_classe_depuis_regroupement(text, uuid, text)', 'EXECUTE'
     ) OR pg_catalog.has_function_privilege(
       'authenticated', 'public.regroupements_demandes_horaires_admin()', 'EXECUTE'
     ) OR pg_catalog.has_function_privilege(
       'anon', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
     ) OR pg_catalog.has_function_privilege(
       'service_role', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
     ) OR pg_catalog.has_function_privilege(
       'agent_ro', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
     ) OR NOT pg_catalog.has_function_privilege(
       'authenticated', 'public.completer_niveau_demande_horaire(uuid)', 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'F74: SECURITY DEFINER/ACL postflight failed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
     WHERE t.tgrelid = 'public.demandes_horaires_famille'::regclass
       AND t.tgname = 'demandes_horaires_snapshot_niveau_insert'
       AND NOT t.tgisinternal
       AND NOT (
         SELECT p.prosecdef
           FROM pg_catalog.pg_proc p
          WHERE p.oid = t.tgfoid
       )
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger t
     WHERE t.tgrelid = 'public.demandes_horaires_famille'::regclass
       AND t.tgname = 'demandes_horaires_snapshot_niveau_update'
       AND NOT t.tgisinternal
       AND NOT (
         SELECT p.prosecdef
           FROM pg_catalog.pg_proc p
          WHERE p.oid = t.tgfoid
       )
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_attribute
     WHERE attrelid = 'public.groupes'::regclass
       AND attname = 'niveau'
       AND NOT attisdropped
  ) THEN
    RAISE EXCEPTION 'F74: snapshot/level schema postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
