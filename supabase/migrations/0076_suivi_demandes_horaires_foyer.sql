-- 0076 — projection privée des demandes du foyer pour le suivi C-10 bis.
BEGIN;

-- M2 : une demande déjà classée reçoit un code métier propre.
DO $migration$
DECLARE
  v_oid oid := 'public.creer_classe_depuis_regroupement(text, uuid, text)'::regprocedure;
  v_definition text;
  v_corrected text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef(v_oid);
  v_corrected := pg_catalog.replace(
    v_definition,
    $old$motif = 'refus_direction', updated_at = pg_catalog.now()$old$,
    $new$motif = 'deja_en_classe', updated_at = pg_catalog.now()$new$
  );
  IF v_corrected = v_definition THEN
    RAISE EXCEPTION 'M2 : fermeture des demandes déjà en classe introuvable';
  END IF;
  EXECUTE v_corrected;
END
$migration$;

CREATE OR REPLACE FUNCTION public.suivi_demandes_horaires_foyer()
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

REVOKE ALL ON FUNCTION public.suivi_demandes_horaires_foyer()
  FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.suivi_demandes_horaires_foyer()
  TO authenticated;

COMMIT;
