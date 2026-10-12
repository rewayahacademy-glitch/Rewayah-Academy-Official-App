-- 0051 — indexes for demand foreign keys and per-row stable request predicates.
-- Supabase Advisors on STAGING identified these F1-specific performance findings
-- after 0050. This migration changes no business behavior or family visibility.
BEGIN;

CREATE INDEX IF NOT EXISTS demandes_creneau_personnalise_langue_code_idx
  ON public.demandes_creneau_personnalise (langue_code);
CREATE INDEX IF NOT EXISTS demandes_creneau_personnalise_offre_id_idx
  ON public.demandes_creneau_personnalise (offre_id);

CREATE INDEX IF NOT EXISTS demandes_horaires_famille_groupe_id_idx
  ON public.demandes_horaires_famille (groupe_id);
CREATE INDEX IF NOT EXISTS demandes_horaires_famille_langue_code_idx
  ON public.demandes_horaires_famille (langue_code);
CREATE INDEX IF NOT EXISTS demandes_horaires_famille_offre_id_idx
  ON public.demandes_horaires_famille (offre_id);

DROP POLICY IF EXISTS demandes_creneau_lecture_propre
  ON public.demandes_creneau_personnalise;
CREATE POLICY demandes_creneau_lecture_propre
  ON public.demandes_creneau_personnalise
  FOR SELECT TO authenticated
  USING (
    eleve_id = (SELECT auth.uid())
    OR coalesce(
      (SELECT public.app_role()) = 'admin'
      AND (SELECT public.app_account_valid()),
      false
    )
  );

DROP POLICY IF EXISTS demandes_horaires_famille_lecture
  ON public.demandes_horaires_famille;
CREATE POLICY demandes_horaires_famille_lecture
  ON public.demandes_horaires_famille
  FOR SELECT TO authenticated
  USING (
    eleve_id = (SELECT auth.uid())
    OR coalesce(
      (SELECT public.app_role()) = 'admin'
      AND (SELECT public.app_account_valid()),
      false
    )
  );

COMMIT;
