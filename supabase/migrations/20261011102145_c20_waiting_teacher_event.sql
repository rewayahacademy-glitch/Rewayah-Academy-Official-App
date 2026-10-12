-- C-20: record the known waiting-for-teacher transition and enforce append-only history.
BEGIN;

CREATE OR REPLACE FUNCTION public.c20_capture_demande_evenements()
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
  v_groupe_etat text;
  v_teacher_id uuid;
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
        INSERT INTO public.demande_evenements
          (demande_id, eleve_id, household_id, type)
        VALUES (NEW.id, NEW.eleve_id, v_household_id, 'classe_creee')
        ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;

        SELECT g.etat, g.teacher_id
          INTO v_groupe_etat, v_teacher_id
          FROM public.groupes g
         WHERE g.id = NEW.groupe_id;
        IF NOT FOUND THEN
          RAISE EXCEPTION 'C-20: classe de la demande introuvable';
        END IF;
        IF v_groupe_etat = 'en_attente_enseignant'
           AND v_teacher_id IS NULL THEN
          INSERT INTO public.demande_evenements
            (demande_id, eleve_id, household_id, type, motif_attente)
          VALUES (
            NEW.id, NEW.eleve_id, v_household_id, 'en_attente',
            'aucun_enseignant_libre'
          )
          ON CONFLICT (demande_id, eleve_id, type) DO NOTHING;
        END IF;
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

CREATE FUNCTION public.c20_rejeter_modification_evenement()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'C-20: les evenements sont append-only'
    USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION public.c20_rejeter_modification_evenement()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TRIGGER c20_demande_evenements_append_only
  BEFORE UPDATE OR DELETE ON public.demande_evenements
  FOR EACH ROW EXECUTE FUNCTION public.c20_rejeter_modification_evenement();

DO $postflight$
BEGIN
  IF EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid IN (
          'public.c20_capture_demande_evenements()'::regprocedure,
          'public.c20_rejeter_modification_evenement()'::regprocedure
        ) AND p.prosecdef
     ) OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_trigger t
        WHERE t.tgname = 'c20_demande_evenements_append_only'
          AND NOT t.tgisinternal
     ) OR has_table_privilege('authenticated', 'public.demande_evenements', 'UPDATE')
       OR has_table_privilege('authenticated', 'public.demande_evenements', 'DELETE') THEN
    RAISE EXCEPTION 'C-20: journal append-only invalide';
  END IF;
END;
$postflight$;

COMMIT;
