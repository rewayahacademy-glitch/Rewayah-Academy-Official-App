-- 0075 — C-10 : suivi privé du foyer et invalidation temps réel.
--
-- Le RPC historique mes_demandes_horaires(uuid) est conservé pour ses
-- appelants existants. Le nouveau RPC ne prend aucun profil fourni par le
-- client : il dérive les membres accessibles de la session et rend les seuls
-- champs utiles au suivi familial.
BEGIN;

DROP POLICY IF EXISTS demandes_horaires_famille_lecture
  ON public.demandes_horaires_famille;
CREATE POLICY demandes_horaires_famille_lecture
  ON public.demandes_horaires_famille
  FOR SELECT TO authenticated
  USING (
    coalesce(public.peut_decrire_apprenant(eleve_id), false)
    OR coalesce(
      public.app_role() = 'admin' AND public.app_account_valid(),
      false
    )
  );

-- L'abonnement Realtime sert uniquement d'invalidation. Le RPC SECURITY
-- DEFINER rend ensuite le document complet après contrôle du foyer. Les
-- colonnes visibles en lecture directe ne contiennent aucun horaire ni nom.
REVOKE ALL ON public.demandes_horaires_famille
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT (id, eleve_id, etat, updated_at)
  ON public.demandes_horaires_famille TO authenticated;

CREATE OR REPLACE FUNCTION public.mes_demandes_horaires_famille()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR NOT coalesce(
       public.app_account_valid() OR public.compte_en_parcours(),
       false
     ) THEN
    RAISE EXCEPTION 'session familiale indisponible';
  END IF;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'demande_id', d.id,
        'eleve_id', d.eleve_id,
        'prenom', eleve.first_name,
        'etat', d.etat,
        'jours', d.jours,
        'heures_locales', d.heures_locales,
        'fuseau_iana', d.fuseau_iana,
        'personnalisee', d.source = 'personnalisee',
        'enseignant', CASE
          WHEN d.etat = 'enseignant_affecte' AND enseignant.gender = 'female'
            THEN nullif(btrim('Sayyida ' || coalesce(enseignant.first_name, '')), 'Sayyida')
          WHEN d.etat = 'enseignant_affecte' AND enseignant.gender = 'male'
            THEN nullif(btrim('Sayid ' || coalesce(enseignant.first_name, '')), 'Sayid')
          ELSE NULL
        END,
        'debut_cours_local', CASE
          WHEN d.etat = 'enseignant_affecte' THEN (
            SELECT to_char(
              s.started_at AT TIME ZONE g.timezone_iana,
              'YYYY-MM-DD"T"HH24:MI:SS'
            )
            FROM public.sessions s
            JOIN public.groupes g ON g.id = s.groupe_id
            WHERE s.groupe_id = d.groupe_id
              AND s.deleted_at IS NULL
              AND s.started_at >= now()
            ORDER BY s.started_at
            LIMIT 1
          )
          ELSE NULL
        END,
        'motif', CASE
          WHEN d.etat NOT IN ('refusee', 'retiree') THEN NULL
          WHEN d.motif IN (
            'retrait_famille', 'offre_retiree',
            'classe_non_constituee', 'refus_direction'
          ) THEN d.motif
          ELSE 'inconnu'
        END,
        'peut_choisir_autre_creneau', d.etat IN ('refusee', 'retiree')
      ) ORDER BY d.updated_at DESC, d.id
    ),
    '[]'::jsonb
  )
  INTO v_result
  FROM public.demandes_horaires_famille d
  JOIN public.profiles eleve ON eleve.id = d.eleve_id
  LEFT JOIN public.groupes g ON g.id = d.groupe_id
  LEFT JOIN public.profiles enseignant ON enseignant.id = g.teacher_id
  WHERE coalesce(public.peut_decrire_apprenant(d.eleve_id), false);

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.mes_demandes_horaires_famille()
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.mes_demandes_horaires_famille()
  TO authenticated;

-- La transition existante affecter_enseignant_classe conserve ses contrôles
-- d'éligibilité, son verrou et son journal. Ce trigger ne fait qu'aligner
-- l'état privé des demandes après l'affectation atomique de la classe.
CREATE OR REPLACE FUNCTION public.tc_demandes_horaires_enseignant_affecte()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF OLD.teacher_id IS NULL AND NEW.teacher_id IS NOT NULL
     AND NEW.etat = 'active' THEN
    UPDATE public.demandes_horaires_famille
       SET etat = 'enseignant_affecte', updated_at = pg_catalog.now()
     WHERE groupe_id = NEW.id AND etat = 'classe_validee';
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.tc_demandes_horaires_enseignant_affecte()
  FROM PUBLIC, anon, authenticated, agent_ro;
DROP TRIGGER IF EXISTS demandes_horaires_enseignant_affecte
  ON public.groupes;
CREATE TRIGGER demandes_horaires_enseignant_affecte
AFTER UPDATE OF teacher_id, etat ON public.groupes
FOR EACH ROW
EXECUTE FUNCTION public.tc_demandes_horaires_enseignant_affecte();

-- Realtime est optionnel dans un Postgres nu. Sur Supabase, inclure la table
-- au plus une fois ; les événements sont encore filtrés par RLS.
DO $migration$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication
    WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'demandes_horaires_famille'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.demandes_horaires_famille';
  END IF;
END;
$migration$;

COMMIT;
