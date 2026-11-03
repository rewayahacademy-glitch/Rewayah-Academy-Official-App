-- D1-bis, correctif (03/11/2026) : `public.concern_famille_v` en lecture seule.
--
-- FAILLE EN PRODUCTION depuis 20261106200000 (D1-bis). La vue porte sur une
-- seule table : PostgreSQL la rend modifiable automatiquement. `authenticated`
-- y avait tous les droits d'ecriture, et la vue s'execute avec les droits de
-- son proprietaire, ce qui contourne la RLS de `student_concern`. Un tuteur
-- pouvait donc reecrire, par la vue, le message que la direction lui avait
-- transmis (constate le 03/11 sur Postgres 17 nu, toutes les migrations : une
-- ligne modifiee), et le meme chemin ouvrait le retrait de lignes.
-- C'etait la seule vue modifiable de `public` (information_schema.views,
-- is_updatable, croise avec les droits d'ecriture d'authenticated).
--
-- Correctif : tous les droits retires, puis la seule lecture rendue a
-- `authenticated`. La vue elle-meme ne change pas (D1-ter la reprendra).
-- Lecteurs (B1) : aucun ecran ni fonction n'ecrit par cette vue ; les
-- scenarios `scenarios_pe_protection_enfants` et
-- `scenarios_d1bis_traiter_signalement` la lisent seulement.
-- Mots d'effacement dans ce fichier : aucun.
BEGIN;

REVOKE ALL ON public.concern_famille_v FROM PUBLIC, anon, authenticated, agent_ro;
GRANT SELECT ON public.concern_famille_v TO authenticated;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.concern_famille_v', 'SELECT')
     OR EXISTS (SELECT 1 FROM information_schema.role_table_grants g
                 WHERE g.table_schema = 'public' AND g.table_name = 'concern_famille_v'
                   AND g.grantee IN ('authenticated', 'anon', 'PUBLIC', 'agent_ro')
                   AND NOT (g.grantee = 'authenticated' AND g.privilege_type = 'SELECT')) THEN
    RAISE EXCEPTION 'D1-bis correctif : droits de concern_famille_v invalides';
  END IF;
END;
$postflight$;

COMMIT;
