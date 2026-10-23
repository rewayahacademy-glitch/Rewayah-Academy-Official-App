-- Support actif : publier session_shared_content dans Realtime.
-- L'adaptateur PortSupportActif ecoute ce canal puis relit par RPC ; sans la
-- publication, le canal ne signale rien et l'ecran retombe sur une relecture
-- toutes les 5 s. La publication n'ouvre aucune ligne : Realtime applique la RLS
-- de la table a chaque abonne.
-- Le modele est celui de 20261011092933 (demande_evenements) : sur un Postgres
-- nu sans publication supabase_realtime (CI, rejeu local), la migration ne fait rien.

DO $realtime$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication p
     WHERE p.pubname = 'supabase_realtime'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_publication_tables p
       WHERE p.pubname = 'supabase_realtime'
         AND p.schemaname = 'public'
         AND p.tablename = 'session_shared_content'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.session_shared_content;
    END IF;
  END IF;
END;
$realtime$;

DO $postflight$
BEGIN
  IF EXISTS (
       SELECT 1 FROM pg_catalog.pg_publication p
        WHERE p.pubname = 'supabase_realtime'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_publication_tables p
        WHERE p.pubname = 'supabase_realtime'
          AND p.schemaname = 'public'
          AND p.tablename = 'session_shared_content'
     ) THEN
    RAISE EXCEPTION 'session_shared_content absente de supabase_realtime';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_class c
        WHERE c.oid = 'public.session_shared_content'::regclass
          AND c.relrowsecurity
     ) THEN
    RAISE EXCEPTION 'session_shared_content sans RLS : publication refusee';
  END IF;
END;
$postflight$;
