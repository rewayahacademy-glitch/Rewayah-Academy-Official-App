-- X2-17: source versionnee des taux de remuneration et preuve future de paiement.
-- Aucun taux n'est precharge. La duree de prestation et son alimentation restent
-- dans un lot distinct tant que la source evenementielle et F86 ne sont pas fixees.

BEGIN;

CREATE TABLE public.regles_remuneration_enseignant (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enseignant_id uuid REFERENCES public.profiles(id),
  taux_minor_par_heure bigint NOT NULL CHECK (taux_minor_par_heure >= 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  date_effet date NOT NULL,
  motif text NOT NULL CHECK (char_length(btrim(motif)) BETWEEN 1 AND 500),
  cree_par uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX regles_remuneration_enseignant_globale_date_uidx
  ON public.regles_remuneration_enseignant (date_effet)
  WHERE enseignant_id IS NULL;
CREATE UNIQUE INDEX regles_remuneration_enseignant_individuelle_date_uidx
  ON public.regles_remuneration_enseignant (enseignant_id, date_effet)
  WHERE enseignant_id IS NOT NULL;

ALTER TABLE public.regles_remuneration_enseignant ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.regles_remuneration_enseignant
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT, INSERT ON TABLE public.regles_remuneration_enseignant TO authenticated;

CREATE POLICY regles_remuneration_direction_read
  ON public.regles_remuneration_enseignant FOR SELECT TO authenticated
  USING (coalesce(public.app_account_valid() AND public.app_role() = 'admin', false));
CREATE POLICY regles_remuneration_direction_aal2_insert
  ON public.regles_remuneration_enseignant FOR INSERT TO authenticated
  WITH CHECK (
    coalesce(public.app_account_valid() AND public.app_role() = 'admin', false)
    AND auth.jwt() ->> 'aal' = 'aal2'
    AND cree_par = auth.uid()
  );

CREATE FUNCTION public.valider_regle_remuneration_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.enseignant_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = NEW.enseignant_id
       AND p.role = 'teacher'
       AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'regle_remuneration_enseignant_invalide'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER regles_remuneration_validate_insert
  BEFORE INSERT ON public.regles_remuneration_enseignant
  FOR EACH ROW EXECUTE FUNCTION public.valider_regle_remuneration_enseignant();

CREATE FUNCTION public.refuser_modification_regle_remuneration()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'regles_remuneration_enseignant_append_only'
    USING ERRCODE = '55000';
END;
$function$;

CREATE TRIGGER regles_remuneration_no_update
  BEFORE UPDATE ON public.regles_remuneration_enseignant
  FOR EACH ROW EXECUTE FUNCTION public.refuser_modification_regle_remuneration();
CREATE TRIGGER regles_remuneration_no_delete
  BEFORE DELETE ON public.regles_remuneration_enseignant
  FOR EACH ROW EXECUTE FUNCTION public.refuser_modification_regle_remuneration();

CREATE FUNCTION public.auditer_regle_remuneration_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  PERFORM public.log_sensitive_access(
    'regle_remuneration_creee',
    'regles_remuneration_enseignant',
    NEW.id::text,
    jsonb_build_object(
      'enseignant_id', NEW.enseignant_id,
      'taux_minor_par_heure', NEW.taux_minor_par_heure,
      'devise', NEW.devise,
      'date_effet', NEW.date_effet,
      'motif', NEW.motif
    )
  );
  RETURN NEW;
END;
$function$;

CREATE TRIGGER regles_remuneration_audit_insert
  AFTER INSERT ON public.regles_remuneration_enseignant
  FOR EACH ROW EXECUTE FUNCTION public.auditer_regle_remuneration_enseignant();

REVOKE ALL ON FUNCTION public.refuser_modification_regle_remuneration()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.valider_regle_remuneration_enseignant()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.auditer_regle_remuneration_enseignant()
  FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE public.wallet_entries
  ADD COLUMN confirme_par_prestataire_le timestamptz;
COMMENT ON COLUMN public.wallet_entries.confirme_par_prestataire_le IS
  'Renseigne uniquement par le futur webhook FI-BR-06 apres verification du prestataire; aucune alimentation de tresorerie n''est branchee dans X2-17 tant que le contrat d''ecriture webhook et F86 ne sont pas disponibles.';

COMMIT;
