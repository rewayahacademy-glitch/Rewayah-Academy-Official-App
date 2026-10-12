-- C-20/C-28: expose instants UTC and keep the household IANA zone separate.
BEGIN;

DROP VIEW public.demande_evenements_foyer_v;
CREATE VIEW public.demande_evenements_foyer_v
WITH (security_barrier = true)
AS
SELECT e.id,
       e.demande_id,
       e.eleve_id,
       e.type,
       e.motif_attente,
       e.survenu_le AS survenu_le_foyer,
       h.timezone AS fuseau_iana
  FROM public.demande_evenements e
  JOIN public.profiles p ON p.id = e.eleve_id AND p.deleted_at IS NULL
  JOIN public.households h ON h.id = p.household_id
 WHERE public.app_account_valid()
   AND (
     (
       e.household_id = public.app_household_id()
       AND p.household_id = public.app_household_id()
       AND h.deleted_at IS NULL
       AND h.status = 'active'
     )
     OR public.app_role() = 'admin'
   );

REVOKE ALL ON public.demande_evenements_foyer_v
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT SELECT ON public.demande_evenements_foyer_v TO authenticated;

CREATE OR REPLACE FUNCTION public.suivi_demandes_horaires_foyer_utc()
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
  debut_cours timestamptz,
  peut_choisir_autre_creneau boolean
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT r.demande_id, r.eleve_id, r.prenom, r.etape, r.motif,
         r.occurrences, r.fuseau_iana, r.personnalisee, r.enseignant,
         CASE WHEN r.debut_cours IS NULL THEN NULL
              ELSE r.debut_cours AT TIME ZONE r.fuseau_iana END,
         r.peut_choisir_autre_creneau
    FROM public.suivi_demandes_horaires_foyer() r;
$function$;

REVOKE ALL ON FUNCTION public.suivi_demandes_horaires_foyer_utc()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.suivi_demandes_horaires_foyer_utc()
  TO authenticated;

DO $postflight$
BEGIN
  IF has_table_privilege('anon', 'public.demande_evenements_foyer_v', 'SELECT')
     OR has_table_privilege('service_role', 'public.demande_evenements_foyer_v', 'SELECT')
     OR has_table_privilege('agent_ro', 'public.demande_evenements_foyer_v', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.demande_evenements_foyer_v', 'SELECT')
     OR has_function_privilege('anon', 'public.suivi_demandes_horaires_foyer_utc()', 'EXECUTE')
     OR has_function_privilege('service_role', 'public.suivi_demandes_horaires_foyer_utc()', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.suivi_demandes_horaires_foyer_utc()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.suivi_demandes_horaires_foyer_utc()', 'EXECUTE') THEN
    RAISE EXCEPTION 'C-20/C-28: UTC projection or ACL postflight failed';
  END IF;
END;
$postflight$;

COMMIT;
