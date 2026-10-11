CREATE OR REPLACE FUNCTION public.regroupements_c11bis_admin()
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'regroupements réservés à l''administration'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH regroupements AS (
    SELECT r.*
    FROM public.regroupements_demandes_horaires_admin() AS r
  )
  SELECT jsonb_build_object(
    'regroupement_id', r.regroupement_id,
    'type_public', r.type_public,
    'langue_code', r.langue_code,
    'langue_nom', lc.nom_humain,
    'fuseau_iana', r.fuseau_iana,
    'occurrences', (
      SELECT coalesce(jsonb_agg(
        jsonb_build_object(
          'jour_iso', r.jours[i],
          'heure', r.heures_locales[i],
          'minute', 0
        ) ORDER BY i
      ), '[]'::jsonb)
      FROM pg_catalog.generate_subscripts(r.jours, 1) AS positions(i)
    ),
    'nombre_eleves', r.nombre_eleves,
    'quota', r.quota,
    'autres_fuseaux', coalesce(autres.valeurs, '[]'::jsonb),
    'peut_creer_classe', r.pret,
    'classe', NULL
  )
  FROM regroupements r
  JOIN public.langues_cours lc ON lc.code = r.langue_code
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(
      jsonb_build_object(
        'fuseau', z.timezone,
        'jour_iso', h.heure ->> 'jour_iso',
        'heure', (h.heure ->> 'heure')::integer,
        'minute', (h.heure ->> 'minute')::integer,
        'decalage_jour', (h.heure ->> 'decalage_jour')::integer
      )
      ORDER BY z.timezone, (h.heure ->> 'jour_iso')::integer
    ) AS valeurs
    FROM (
      SELECT DISTINCT hh.timezone
      FROM public.demandes_horaires_famille d
      JOIN public.profiles p ON p.id = d.eleve_id
      JOIN public.households hh ON hh.id = p.household_id
      WHERE d.etat = 'envoyee'
        AND hh.timezone <> r.fuseau_iana
        AND CASE WHEN d.source = 'offre'
          THEN 'o:' || d.offre_id::text
          ELSE 'p:' || pg_catalog.md5(
            d.type_public || '|' || d.langue_code || '|' ||
            public.cle_horaire_utc(d.jours, d.heures_locales, d.fuseau_iana)
          )
        END = r.regroupement_id
    ) AS z
    CROSS JOIN LATERAL jsonb_array_elements(
      public.traduire_occurrences_fuseau(
        r.jours, r.heures_locales, r.fuseau_iana, z.timezone
      )
    ) AS h(heure)
  ) AS autres ON true

  UNION ALL

  SELECT jsonb_build_object(
    'regroupement_id', 'g:' || g.id::text,
    'type_public', g.type_public,
    'langue_code', g.langue_code,
    'langue_nom', lc.nom_humain,
    'fuseau_iana', g.timezone_iana,
    'occurrences', coalesce(
      slots.valeurs,
      jsonb_build_array(jsonb_build_object(
        'jour_iso', g.weekday,
        'heure', g.hour_local,
        'minute', 0
      ))
    ),
    'nombre_eleves', membres.nombre,
    'quota', g.seuil_max,
    'autres_fuseaux', coalesce(autres.valeurs, '[]'::jsonb),
    'peut_creer_classe', false,
    'classe', jsonb_build_object(
      'classe_id', g.id,
      'libelle', g.libelle,
      'genre_classe', g.genre_public,
      'peut_affecter_enseignant', false
    )
  )
  FROM public.classes_a_confirmer_admin() AS a
  JOIN public.groupes g ON g.id = a.classe_id
  JOIN public.langues_cours lc ON lc.code = g.langue_code
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(
      jsonb_build_object(
        'jour_iso', gc.weekday,
        'heure', gc.hour_local,
        'minute', 0
      )
      ORDER BY gc.weekday, gc.hour_local
    ) AS valeurs
    FROM public.groupe_creneaux gc
    WHERE gc.groupe_id = g.id
  ) AS slots ON true
  LEFT JOIN LATERAL (
    SELECT count(*)::integer AS nombre
    FROM public.groupe_membres gm
    WHERE gm.groupe_id = g.id
      AND gm.left_at IS NULL
  ) AS membres ON true
  LEFT JOIN LATERAL (
    SELECT jsonb_agg(
      jsonb_build_object(
        'fuseau', z.timezone,
        'jour_iso', h.heure ->> 'jour_iso',
        'heure', (h.heure ->> 'heure')::integer,
        'minute', (h.heure ->> 'minute')::integer,
        'decalage_jour', (h.heure ->> 'decalage_jour')::integer
      )
      ORDER BY z.timezone, (h.heure ->> 'jour_iso')::integer
    ) AS valeurs
    FROM (
      SELECT DISTINCT hh.timezone
      FROM public.groupe_membres membres
      JOIN public.profiles p ON p.id = membres.student_id
      JOIN public.households hh ON hh.id = p.household_id
      WHERE membres.groupe_id = g.id
        AND membres.left_at IS NULL
        AND hh.timezone <> g.timezone_iana
    ) AS z
    CROSS JOIN LATERAL jsonb_array_elements(
      public.traduire_occurrences_fuseau(
        ARRAY(
          SELECT c.weekday FROM public.groupe_creneaux c
          WHERE c.groupe_id = g.id ORDER BY c.weekday, c.hour_local
        ),
        ARRAY(
          SELECT c.hour_local FROM public.groupe_creneaux c
          WHERE c.groupe_id = g.id ORDER BY c.weekday, c.hour_local
        ),
        g.timezone_iana,
        z.timezone
      )
    ) AS h(heure)
  ) AS autres ON true
  ;
END;
$function$

