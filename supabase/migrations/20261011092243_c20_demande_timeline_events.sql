-- C-20: append-only timeline facts emitted in the same transaction as source changes.
BEGIN;

CREATE TABLE public.demande_evenements (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  demande_id uuid NOT NULL
    REFERENCES public.demandes_horaires_famille(id) ON DELETE RESTRICT,
  eleve_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  household_id uuid NOT NULL REFERENCES public.households(id) ON DELETE RESTRICT,
  type text NOT NULL CHECK (type IN (
    'envoyee', 'en_attente', 'classe_creee', 'enseignant_affecte',
    'eleve_integre', 'premiere_seance_prevue', 'close'
  )),
  motif_attente text CHECK (
    motif_attente IS NULL OR motif_attente IN (
      'classes_pleines', 'aucun_enseignant_libre'
    )
  ),
  survenu_le timestamptz DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT demande_evenements_demande_eleve_type_key
    UNIQUE (demande_id, eleve_id, type)
);

CREATE INDEX demande_evenements_foyer_timeline_idx
  ON public.demande_evenements (household_id, demande_id, survenu_le, id);

ALTER TABLE public.demande_evenements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.demande_evenements
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON TABLE public.demande_evenements TO authenticated;
CREATE POLICY demande_evenements_foyer_lecture
  ON public.demande_evenements
  FOR SELECT TO authenticated
  USING (
    public.app_account_valid()
    AND (
      (
        household_id = public.app_household_id()
        AND EXISTS (
          SELECT 1 FROM public.profiles p
           WHERE p.id = demande_evenements.eleve_id
             AND p.household_id = public.app_household_id()
             AND p.deleted_at IS NULL
        )
      )
      OR public.app_role() = 'admin'
    )
  );

-- The creation date is a known fact for every extant request. No later
-- milestone is backfilled from a current status because its historical time
-- cannot be inferred safely.
INSERT INTO public.demande_evenements
  (demande_id, eleve_id, household_id, type, survenu_le)
SELECT d.id, d.eleve_id, p.household_id, 'envoyee', d.created_at
  FROM public.demandes_horaires_famille d
  JOIN public.profiles p ON p.id = d.eleve_id
 WHERE p.household_id IS NOT NULL AND p.deleted_at IS NULL
ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;

-- The function is deliberately SECURITY INVOKER. Transitions made by the
-- existing server RPCs are recorded atomically; clients have no table DML.
CREATE FUNCTION public.c20_capture_demande_evenements()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_demande_id uuid;
  v_eleve_id uuid;
  v_groupe_id uuid;
  v_type text;
  v_household_id uuid;
BEGIN
  IF TG_TABLE_NAME = 'demandes_horaires_famille' THEN
    v_demande_id := NEW.id;
    v_eleve_id := NEW.eleve_id;
    v_groupe_id := NEW.groupe_id;

    SELECT p.household_id INTO v_household_id
      FROM public.profiles p
     WHERE p.id = v_eleve_id AND p.deleted_at IS NULL;
    IF v_household_id IS NULL THEN
      RAISE EXCEPTION 'C-20: household absent pour la demande';
    END IF;

    IF TG_OP = 'INSERT' AND NEW.etat = 'envoyee' THEN
      INSERT INTO public.demande_evenements
        (demande_id, eleve_id, household_id, type, survenu_le)
      VALUES (NEW.id, NEW.eleve_id, v_household_id, 'envoyee', NEW.created_at)
      ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;
      RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
      IF NEW.groupe_id IS NOT NULL
         AND NEW.groupe_id IS DISTINCT FROM OLD.groupe_id THEN
        v_type := 'classe_creee';
        INSERT INTO public.demande_evenements
          (demande_id, eleve_id, household_id, type)
        VALUES (NEW.id, NEW.eleve_id, v_household_id, v_type)
        ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;
      END IF;

      IF NEW.etat = 'enseignant_affecte'
         AND OLD.etat IS DISTINCT FROM NEW.etat THEN
        INSERT INTO public.demande_evenements
          (demande_id, eleve_id, household_id, type)
        VALUES (NEW.id, NEW.eleve_id, v_household_id, 'enseignant_affecte')
        ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;
      END IF;

      IF NEW.etat IN ('refusee', 'retiree')
         AND OLD.etat IS DISTINCT FROM NEW.etat THEN
        INSERT INTO public.demande_evenements
          (demande_id, eleve_id, household_id, type)
        VALUES (NEW.id, NEW.eleve_id, v_household_id, 'close')
        ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;
      END IF;
      RETURN NEW;
    END IF;
  ELSIF TG_TABLE_NAME = 'groupe_membres' THEN
    IF NEW.left_at IS NOT NULL THEN RETURN NEW; END IF;
    v_eleve_id := NEW.student_id;
    v_groupe_id := NEW.groupe_id;
    SELECT p.household_id INTO v_household_id
      FROM public.profiles p
     WHERE p.id = v_eleve_id AND p.deleted_at IS NULL;
    IF v_household_id IS NULL THEN
      RAISE EXCEPTION 'C-20: household absent pour le membre';
    END IF;
    FOR v_demande_id IN
      SELECT d.id
        FROM public.demandes_horaires_famille d
       WHERE d.eleve_id = v_eleve_id AND d.groupe_id = v_groupe_id
    LOOP
      INSERT INTO public.demande_evenements
        (demande_id, eleve_id, household_id, type)
      VALUES (v_demande_id, v_eleve_id, v_household_id, 'eleve_integre')
      ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;
    END LOOP;
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'C-20: table source non prise en charge';
END;
$function$;
REVOKE ALL ON FUNCTION public.c20_capture_demande_evenements()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER c20_demandes_evenements
  AFTER INSERT OR UPDATE OF etat, groupe_id
  ON public.demandes_horaires_famille
  FOR EACH ROW EXECUTE FUNCTION public.c20_capture_demande_evenements();
CREATE TRIGGER c20_membres_evenements
  AFTER INSERT ON public.groupe_membres
  FOR EACH ROW EXECUTE FUNCTION public.c20_capture_demande_evenements();

DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
          WHERE c.oid = 'public.demande_evenements'::regclass)
     OR has_table_privilege('anon', 'public.demande_evenements', 'SELECT')
     OR has_table_privilege('authenticated', 'public.demande_evenements', 'INSERT')
     OR has_table_privilege('authenticated', 'public.demande_evenements', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.demande_evenements', 'DELETE')
     OR has_table_privilege('service_role', 'public.demande_evenements', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.demande_evenements', 'SELECT')
     OR EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = 'public.c20_capture_demande_evenements()'::regprocedure
          AND p.prosecdef
     )
     OR (SELECT count(*) FROM pg_catalog.pg_trigger t
          WHERE t.tgname IN ('c20_demandes_evenements', 'c20_membres_evenements')
            AND NOT t.tgisinternal) <> 2 THEN
    RAISE EXCEPTION 'C-20: postflight du journal des demandes echoue';
  END IF;
END;
$postflight$;

COMMIT;
