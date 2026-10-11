-- C-20: timezone-correct event projection and RLS-governed realtime refresh.
BEGIN;

CREATE VIEW public.demande_evenements_foyer_v
WITH (security_barrier = true)
AS
SELECT e.id,
       e.demande_id,
       e.eleve_id,
       e.type,
       e.motif_attente,
       CASE WHEN e.survenu_le IS NULL THEN NULL
            ELSE e.survenu_le AT TIME ZONE h.timezone END AS survenu_le_foyer,
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

DO $realtime$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication p
     WHERE p.pubname = 'supabase_realtime'
  ) THEN
    RAISE EXCEPTION 'C-20: publication supabase_realtime absente';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication_tables p
     WHERE p.pubname = 'supabase_realtime'
       AND p.schemaname = 'public'
       AND p.tablename = 'demande_evenements'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.demande_evenements;
  END IF;
END;
$realtime$;

DO $postflight$
BEGIN
  IF has_table_privilege('anon', 'public.demande_evenements_foyer_v', 'SELECT')
     OR has_table_privilege('service_role', 'public.demande_evenements_foyer_v', 'SELECT')
     OR has_table_privilege('agent_ro', 'public.demande_evenements_foyer_v', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.demande_evenements_foyer_v', 'SELECT')
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_publication_tables p
        WHERE p.pubname = 'supabase_realtime'
          AND p.schemaname = 'public'
          AND p.tablename = 'demande_evenements'
     ) THEN
    RAISE EXCEPTION 'C-20: ACL/projection/realtime postflight echoue';
  END IF;
END;
$postflight$;

COMMIT;
