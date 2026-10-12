-- C-20: project event instants in the household IANA zone for the wall-clock
-- contract consumed by FriseDemande. The client never substitutes its own zone.
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
       e.survenu_le AT TIME ZONE h.timezone AS survenu_le_foyer,
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

ALTER VIEW public.demande_evenements_foyer_v OWNER TO postgres;
REVOKE ALL ON public.demande_evenements_foyer_v
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT SELECT ON public.demande_evenements_foyer_v TO authenticated;
COMMENT ON VIEW public.demande_evenements_foyer_v IS
  'C-20 frise projection: event timestamps rendered as household wall-clock values.';

DO $postflight$
DECLARE
  v_type oid;
BEGIN
  SELECT a.atttypid INTO v_type
    FROM pg_catalog.pg_attribute a
   WHERE a.attrelid = 'public.demande_evenements_foyer_v'::regclass
     AND a.attname = 'survenu_le_foyer'
     AND NOT a.attisdropped;

  IF v_type IS DISTINCT FROM 'timestamp without time zone'::regtype
     OR pg_catalog.has_table_privilege('anon', 'public.demande_evenements_foyer_v', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'public.demande_evenements_foyer_v', 'SELECT')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.demande_evenements_foyer_v', 'SELECT')
     OR NOT pg_catalog.has_table_privilege('authenticated', 'public.demande_evenements_foyer_v', 'SELECT') THEN
    RAISE EXCEPTION 'C-20 household wall-clock projection or ACL failed';
  END IF;
END;
$postflight$;

COMMIT;
