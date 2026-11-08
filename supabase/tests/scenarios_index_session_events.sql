-- PERF-ATTENTE (a) (migration 20261120200300) : l'index de session_events.
--
-- Ce que le scenario prouve (il ECHOUE sans la migration, il PASSE avec) :
--   1. l'index existe, valide, sur (session_id, profile_id, server_ts) avec
--      event_type en colonne incluse ;
--   2. le planificateur l'emploie pour la recherche de la vue de presence
--      (seance + personne) : sequentiel interdit, le plan nomme l'index ;
--   3. la migration est rejouable (l'index n'est pas recree).
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'PERF-INDEX ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

SELECT pg_temp.vrai(
  (SELECT pg_catalog.pg_get_indexdef(i.indexrelid)
     FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class c ON c.oid = i.indexrelid
    WHERE i.indrelid = 'public.session_events'::regclass AND c.relname = 'session_events_session_profile_ts_ix'
      AND i.indisvalid AND i.indisready)
  LIKE '%(session_id, profile_id, server_ts) INCLUDE (event_type)%',
  'l''index existe, valide, sur (session_id, profile_id, server_ts) avec event_type inclus');

-- 2. Le plan de la recherche de la vue de presence.
CREATE FUNCTION pg_temp.plan(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE v_ligne text; v_plan text := '';
BEGIN
  FOR v_ligne IN EXECUTE 'EXPLAIN ' || p_sql LOOP
    v_plan := v_plan || v_ligne || E'\n';
  END LOOP;
  RETURN v_plan;
END $$;

SET LOCAL enable_seqscan = off;
SELECT pg_temp.vrai(
  pg_temp.plan($q$SELECT max(e.server_ts) FROM public.session_events e
                  WHERE e.session_id = '00000000-0000-0000-0000-000000000001'
                    AND e.profile_id = '00000000-0000-0000-0000-000000000002'$q$)
    LIKE '%session_events_session_profile_ts_ix%',
  'la recherche par seance et personne emploie l''index');
SELECT pg_temp.vrai(
  pg_temp.plan($q$SELECT min(e.server_ts) FROM public.session_events e
                  WHERE e.session_id = '00000000-0000-0000-0000-000000000001'
                    AND e.profile_id = '00000000-0000-0000-0000-000000000002'
                    AND e.event_type = 'joined'$q$)
    LIKE '%session_events_session_profile_ts_ix%',
  'le premier instant « joined » emploie l''index');

ROLLBACK;
