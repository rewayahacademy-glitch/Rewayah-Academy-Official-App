BEGIN;

ALTER TABLE public.remplacements_seance
  ALTER COLUMN cree_le SET DEFAULT pg_catalog.clock_timestamp();

COMMIT;
