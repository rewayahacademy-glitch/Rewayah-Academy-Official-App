BEGIN;

-- L'ajout d'une colonne OUT exige de recréer la fonction; aucun objet métier
-- dépendant n'appelle cette projection dans le schéma.
DROP FUNCTION public.suivi_demandes_horaires_foyer();

CREATE FUNCTION public.suivi_demandes_horaires_foyer()
RETURNS TABLE (
  demande_id uuid,
  eleve_id uuid,
  prenom text,
  etape text,
  motif text,
  occurrences jsonb,
  fuseau_iana text,
  personnalisee boolean,
  enseignant text,
  titre_public text,
  debut_cours timestamp without time zone,
  peut_choisir_autre_creneau boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_account_valid()
    AND EXISTS (
      SELECT 1
      FROM public.profiles courant
      WHERE courant.id = auth.uid()
        AND courant.role IN ('guardian', 'student')
        AND courant.deleted_at IS NULL
    ),
    false
  ) THEN
    RAISE EXCEPTION 'suivi reserve a un compte famille actif'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    d.id,
    d.eleve_id,
    p.first_name,
    CASE d.etat
      WHEN 'envoyee' THEN 'envoyee'
      WHEN 'classe_validee' THEN 'classe_validee'
      WHEN 'enseignant_affecte' THEN 'enseignant_affecte'
      ELSE 'close'
    END,
    CASE d.motif
      WHEN 'retrait_famille' THEN d.motif
      WHEN 'offre_retiree' THEN d.motif
      WHEN 'classe_non_constituee' THEN d.motif
      WHEN 'refus_direction' THEN d.motif
      WHEN 'deja_en_classe' THEN d.motif
      ELSE NULL
    END,
    coalesce(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'jour_iso', extract(isodow FROM x.heure_foyer)::integer,
            'heure', extract(hour FROM x.heure_foyer)::integer,
            'minute', extract(minute FROM x.heure_foyer)::integer
          )
          ORDER BY x.position
        )
        FROM (
          SELECT
            i AS position,
            (
              (
                date_trunc('week', pg_catalog.now() AT TIME ZONE d.fuseau_iana)::date
                + (d.jours[i] - 1)
                + pg_catalog.make_interval(hours => d.heures_locales[i])
            ) AT TIME ZONE d.fuseau_iana
          ) AT TIME ZONE h.timezone AS heure_foyer
          FROM pg_catalog.generate_subscripts(d.jours, 1) AS positions(i)
        ) AS x
      ),
      '[]'::jsonb
    ),
    h.timezone,
    d.source = 'personnalisee',
    CASE WHEN d.etat = 'enseignant_affecte'
      THEN nullif(pg_catalog.btrim(pg_catalog.concat_ws(' ', enseignant.first_name, enseignant.last_name)), '')
      ELSE NULL
    END,
    CASE WHEN d.etat = 'enseignant_affecte' THEN CASE enseignant.gender
      WHEN 'female' THEN 'sayyida'
      WHEN 'male' THEN 'sayid'
      ELSE NULL
    END ELSE NULL END,
    CASE WHEN d.etat = 'enseignant_affecte' THEN (
      SELECT min(s.started_at) AT TIME ZONE h.timezone
      FROM public.sessions s
      WHERE s.groupe_id = d.groupe_id
        AND s.deleted_at IS NULL
        AND s.started_at > pg_catalog.now()
    ) ELSE NULL END,
    d.etat IN ('refusee', 'retiree')
      AND NOT EXISTS (
        SELECT 1
        FROM public.groupe_membres gm
        WHERE gm.student_id = d.eleve_id
          AND gm.left_at IS NULL
      )
  FROM public.demandes_horaires_famille d
  JOIN public.profiles p ON p.id = d.eleve_id
  JOIN public.households h ON h.id = p.household_id
  LEFT JOIN public.groupes g ON g.id = d.groupe_id
  LEFT JOIN public.profiles enseignant ON enseignant.id = g.teacher_id
  WHERE coalesce(public.peut_decrire_apprenant(d.eleve_id), false)
    AND p.deleted_at IS NULL
    AND h.status = 'active'
    AND h.deleted_at IS NULL
  ORDER BY d.created_at DESC, d.id;
END;
$function$;

ALTER FUNCTION public.suivi_demandes_horaires_foyer() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.suivi_demandes_horaires_foyer()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.suivi_demandes_horaires_foyer()
  TO authenticated;
COMMENT ON FUNCTION public.suivi_demandes_horaires_foyer() IS
  'F86: signature=public.suivi_demandes_horaires_foyer(); md5_functiondef=9e7d6b4cea897babc465b9454b0b03e4; guard=active family account; titre_public derives from profiles.gender.';

DO $postflight$
DECLARE
  v_oid oid := pg_catalog.to_regprocedure('public.suivi_demandes_horaires_foyer()');
  v_source text;
  v_result text;
BEGIN
  IF v_oid IS NULL THEN
    RAISE EXCEPTION 'C-04: suivi_demandes_horaires_foyer absent après remplacement';
  END IF;

  SELECT p.prosrc, pg_catalog.pg_get_function_result(p.oid)
    INTO v_source, v_result
    FROM pg_catalog.pg_proc p
   WHERE p.oid = v_oid
     AND p.prosecdef
     AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
     AND p.proconfig @> ARRAY['search_path=""'];
  IF NOT FOUND
     OR pg_catalog.strpos(v_source, 'IF NOT coalesce(') = 0
     OR pg_catalog.strpos(v_source, 'public.app_account_valid()') = 0
     OR pg_catalog.strpos(v_result, 'titre_public text') = 0 THEN
    RAISE EXCEPTION 'C-04: propriétaire, search_path, garde ou retour titre_public invalide';
  END IF;

  IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.obj_description(v_oid, 'pg_proc') NOT LIKE
       '%signature=public.suivi_demandes_horaires_foyer(); md5_functiondef=9e7d6b4cea897babc465b9454b0b03e4;%'
  THEN
    RAISE EXCEPTION 'C-04: ACL ou empreinte F86 placeholder incorrecte';
  END IF;
END
$postflight$;

COMMIT;
