-- PERF-ATTENTE (a) (garde-cap, 07/11/2026 : feu vert « premier fichier,
-- minimal ») : un index sur public.session_events pour la presence d'une
-- seance.
--
-- Constat (production, lecture seule, 07/11/2026) : session_events n'a QUE sa
-- cle primaire. Les lectures de presence (la vue presence_seance_v, et les
-- fonctions etat_presence / presence_temps_seance qu'elle appelle) cherchent par
-- seance et par personne ; sans index, chaque lecture parcourt toute la table :
-- 49 381 parcours sequentiels, 10,7 millions de lignes lues, 0 lecture par index.
-- Aujourd'hui la table compte 315 lignes : l'effet est invisible ; il grandit
-- avec chaque seance.
--
-- Colonnes : le garde-cap a ecrit « (session_id, created_at) » ; la table n'a
-- pas de created_at, son horodatage s'appelle server_ts (relu en production).
-- L'index : (session_id, profile_id, server_ts) INCLUDE (event_type) : la
-- recherche par seance et par personne, le dernier et le premier instant sans
-- lire la table, et le filtre event_type = 'joined' sur l'index.
--
-- Pas de CONCURRENTLY : la table est minuscule (un verrou d'ecriture de
-- quelques millisecondes) et la page collee tient en une transaction. Aucun mot
-- d'effacement. Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                  WHERE a.attrelid = 'public.session_events'::regclass AND NOT a.attisdropped
                    AND a.attname IN ('session_id', 'profile_id', 'server_ts', 'event_type')
                  GROUP BY a.attrelid HAVING pg_catalog.count(*) = 4) THEN
    RAISE EXCEPTION 'PERF-INDEX : colonnes session_id, profile_id, server_ts, event_type absentes de session_events, arret';
  END IF;
END;
$preflight$;

CREATE INDEX IF NOT EXISTS session_events_session_profile_ts_ix
  ON public.session_events (session_id, profile_id, server_ts) INCLUDE (event_type);

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_index i
                   JOIN pg_catalog.pg_class c ON c.oid = i.indexrelid
                  WHERE i.indrelid = 'public.session_events'::regclass
                    AND c.relname = 'session_events_session_profile_ts_ix'
                    AND i.indisvalid AND i.indisready) THEN
    RAISE EXCEPTION 'PERF-INDEX : l''index de session_events est absent ou invalide';
  END IF;
END;
$postflight$;
