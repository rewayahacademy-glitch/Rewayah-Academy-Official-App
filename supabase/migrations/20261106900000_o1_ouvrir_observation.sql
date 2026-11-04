-- O1 : ouverture de l'observation aux parents, apres pose des secrets de la
-- coupure (observation_coupure_url, observation_coupure_secret) par le
-- directeur le 03/11/2026. La cle a ete creee fermee par
-- 20261105500000_o1_observation_coupure.sql. Un seul changement : la cle
-- passe a vrai. Le scenario scenarios_o1_observation.sql la referme lui-meme.

UPDATE public.app_config
   SET value = 'true'::jsonb, updated_at = pg_catalog.now()
 WHERE key = 'observation.ouverture_parents';

DO $postflight$
BEGIN
  IF (SELECT value FROM public.app_config WHERE key = 'observation.ouverture_parents') IS DISTINCT FROM 'true'::jsonb THEN
    RAISE EXCEPTION 'O1 : observation.ouverture_parents n''est pas a vrai';
  END IF;
END;
$postflight$;
