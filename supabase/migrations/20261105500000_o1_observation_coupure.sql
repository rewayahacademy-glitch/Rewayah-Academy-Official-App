-- Lot O1 (02/11/2026) : ouvrir l'observation des parents en production.
--
-- FICHIER SANS MOT D'EFFACEMENT (B5) : le pilote l'installe. Additif (B6) :
-- une fonction nouvelle, une retouche par ancre, une tache planifiee
-- nouvelle ; aucune signature existante ne change, rien n'est retire.
--
-- Decision du directeur (31/10/2026) : 2 visites par seance au plus, 2
-- minutes au plus chacune ; une visite ecourtee compte. Ces valeurs vivent
-- dans app_config (observation.max_visits_per_session = 2,
-- observation.max_seconds_per_visit = 120, observation.max_total_seconds =
-- 240 en production, relu le 02/11) et dans la politique propre a une classe.
-- **Rien n'est ecrit en dur ici** : tout se lit par
-- politique_observation_effective().
--
-- 1. public.couper_visites_observation_echues(ws_url_cloud, ws_url_self_hosted)
--    Ce qui manquait : l'expiration d'un jeton LiveKit n'ejecte pas un
--    participant deja connecte ; seul le client se coupait. Cette fonction
--    clot, cote serveur, chaque visite de tuteur (guardian_observer) ouverte
--    dont la duree permise est atteinte :
--      duree permise = min(max_seconds_per_visit, max_total - deja consomme)
--      (0 si la politique est fermee : la visite est revoquee) ;
--    left_at = entered_at + duree permise (le temps compte est le temps permis,
--    jamais plus), fin_de_visite = 'quota_atteint' (ou 'revocation_serveur').
--    Une visite d'une seance finie (fin + grace) est close a 'seance_terminee'.
--    Elle rend la route LiveKit (provider, ws_url, room_name, identity) de
--    chaque visite coupee dans les 3 dernieres minutes : la fonction Edge
--    `observation-coupure` fait sortir le participant (removeParticipant) ;
--    rendre aussi les coupures recentes permet de reessayer sans risque, une
--    sortie d'un absent n'est pas une erreur. Idempotente. SECURITY DEFINER,
--    search_path vide, EXECUTE au seul service_role.
-- 2. public.annonces_observation : l'enseignant EFFECTIF de la seance (un
--    remplacant designe) est prevenu, pas seulement le titulaire. Retouche
--    par ancre (B4).
-- 2 bis. Interrupteur : app_config.observation.activee pose a faux s'il est
--    absent (INSERT ... ON CONFLICT DO NOTHING, jamais d'ecrasement) ; une
--    cle absente ferme ; version de politique `fermee` quand l'academie n'a
--    pas ouvert. Retouche par ancre de politique_observation_effective.
-- 3. Tache planifiee `observation-coupure`, chaque minute, sur le modele exact
--    de `courriels-envoi` (20261023120000) : net.http_post vers l'URL lue au
--    coffre, l'en-tete secret lu au coffre ; rien ne part s'il n'y a ni visite
--    de tuteur ouverte, ni coupure recente, ni URL au coffre.
--    **Secrets a poser par le directeur, hors depot** (aucune valeur ici) :
--      - coffre (Vault) `observation_coupure_url` : l'URL complete de la
--        fonction Edge, https://<projet>.supabase.co/functions/v1/observation-coupure ;
--      - coffre (Vault) `observation_coupure_secret` : une chaine aleatoire ;
--      - secret de fonction Edge `OBSERVATION_COUPURE_SECRET` : la MEME chaine.
--    Sans eux, la tache ne fait rien, et la coupure reste celle du client
--    (comme avant ce lot).
--
-- Lecteurs recenses (B1) : aucune colonne ne change de sens.
-- guardian_session_visit.left_at et fin_de_visite sont deja ecrits par
-- sortir_observation ; budget_observation lit duration_seconds (genere).

BEGIN;

CREATE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- ------------------------------------------------------------------
-- 1. La coupure serveur des visites echues
-- ------------------------------------------------------------------
CREATE FUNCTION public.couper_visites_observation_echues(
  p_ws_url_cloud text,
  p_ws_url_self_hosted text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_grace integer := public.app_config_int('grace_after_end_minutes', 15);
  v_v record;
  v_pol jsonb;
  v_max_pv integer;
  v_max_t integer;
  v_avant integer;
  v_limite integer;
  v_motif text;
  v_route record;
  v_sorties jsonb := '[]'::jsonb;
BEGIN
  FOR v_v IN
    SELECT v.id, v.session_id, v.groupe_id, v.observateur_profile_id, v.entered_at,
           s.ended_at AS seance_fin
      FROM public.guardian_session_visit v
      JOIN public.sessions s ON s.id = v.session_id
     WHERE v.role = 'guardian_observer'
       AND v.left_at IS NULL
     ORDER BY v.entered_at
       FOR UPDATE OF v SKIP LOCKED
  LOOP
    v_pol := public.politique_observation_effective(v_v.groupe_id);
    v_max_pv := (v_pol->>'max_seconds_per_visit')::integer;
    v_max_t := coalesce((v_pol->>'max_total_observation_seconds')::integer, 0);

    SELECT coalesce(pg_catalog.sum(w.duration_seconds), 0)::integer INTO v_avant
      FROM public.guardian_session_visit w
     WHERE w.session_id = v_v.session_id
       AND w.observateur_profile_id = v_v.observateur_profile_id
       AND w.role = 'guardian_observer'
       AND w.left_at IS NOT NULL;

    v_limite := greatest(0, v_max_t - v_avant);
    IF v_max_pv IS NOT NULL THEN
      v_limite := least(v_limite, v_max_pv);
    END IF;
    v_motif := 'quota_atteint';
    IF NOT coalesce((v_pol->>'observation_activee')::boolean, false) THEN
      v_limite := 0;
      v_motif := 'revocation_serveur';
    END IF;

    IF pg_catalog.now() >= v_v.entered_at + pg_catalog.make_interval(secs => v_limite) THEN
      UPDATE public.guardian_session_visit
         SET left_at = v_v.entered_at + pg_catalog.make_interval(secs => v_limite),
             fin_de_visite = v_motif
       WHERE id = v_v.id;
    ELSIF pg_catalog.now() > v_v.seance_fin + pg_catalog.make_interval(mins => v_grace) THEN
      UPDATE public.guardian_session_visit
         SET left_at = pg_catalog.now(),
             fin_de_visite = 'seance_terminee'
       WHERE id = v_v.id;
    END IF;
  END LOOP;

  -- Les coupures recentes (3 minutes) : la fonction Edge fait sortir chaque
  -- participant ; un participant deja parti n'est pas une erreur.
  FOR v_v IN
    SELECT v.id, v.session_id, v.observateur_profile_id
      FROM public.guardian_session_visit v
     WHERE v.role = 'guardian_observer'
       AND v.fin_de_visite IN ('quota_atteint', 'revocation_serveur', 'seance_terminee')
       AND v.left_at IS NOT NULL
       AND v.left_at > pg_catalog.now() - pg_catalog.make_interval(mins => 3)
       AND NOT EXISTS (
         -- Une visite suivante deja ouverte du meme tuteur : ne pas l'ejecter.
         SELECT 1 FROM public.guardian_session_visit n
          WHERE n.session_id = v.session_id
            AND n.observateur_profile_id = v.observateur_profile_id
            AND n.left_at IS NULL)
  LOOP
    SELECT * INTO v_route
      FROM public.video_route_de_seance(v_v.session_id, p_ws_url_cloud, p_ws_url_self_hosted);
    IF v_route.room_name IS NOT NULL THEN
      v_sorties := v_sorties || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'visite_id', v_v.id,
        'provider', v_route.provider,
        'ws_url', v_route.ws_url,
        'room_name', v_route.room_name,
        'identity', v_v.observateur_profile_id::text));
    END IF;
  END LOOP;

  RETURN v_sorties;
END;
$function$;

ALTER FUNCTION public.couper_visites_observation_echues(text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.couper_visites_observation_echues(text, text)
  FROM PUBLIC, anon, authenticated;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE ALL ON FUNCTION public.couper_visites_observation_echues(text, text) FROM agent_ro;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'service_role') THEN
    GRANT EXECUTE ON FUNCTION public.couper_visites_observation_echues(text, text) TO service_role;
  END IF;
END;
$agent$;
COMMENT ON FUNCTION public.couper_visites_observation_echues(text, text) IS
  'O1 (02/11/2026) : clot cote serveur les visites de tuteur echues (duree de la politique, ou seance finie) et rend la route LiveKit des coupures des 3 dernieres minutes, pour la fonction Edge observation-coupure. Idempotente. DEFINER, service_role seul.';

-- ------------------------------------------------------------------
-- 2. L'enseignant effectif est prevenu
-- ------------------------------------------------------------------
SELECT pg_temp.remplacer('public.annonces_observation(uuid)',
  $a$if not found or v_seance.teacher_id <> auth.uid() then$a$,
  $b$if not found or auth.uid() is null
     or auth.uid() not in (v_seance.teacher_id,
                           coalesce(private.c29_enseignant_effectif_session(p_session_id),
                                    v_seance.teacher_id)) then$b$, 1);

-- ------------------------------------------------------------------
-- 2 bis. L'interrupteur de l'academie, ferme tant que le pilote ne l'ouvre pas
-- ------------------------------------------------------------------
-- Seconde barriere (pilote, 02/11/2026) : l'observation reelle des parents ne
-- s'ouvre que si le serveur le dit, par app_config.observation.activee (la cle
-- existe depuis 0030 ; elle valait true en production le 02/11). Posee a faux
-- seulement si elle est absente, sans ecraser une valeur existante. Le pilote
-- l'ouvre, apres les secrets et un premier passage reussi de la tache
-- planifiee, par la ligne ecrite en tete de la PR (un UPDATE).
INSERT INTO public.app_config (key, value)
VALUES ('observation.activee', 'false'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Une cle absente ferme (elle ouvrait), et l'interrupteur de l'academie se dit
-- par sa propre version de politique, `fermee`, distincte de `desactivee`
-- (une classe fermee par la direction) : le client ne dit pas « fermee pour
-- cette classe » quand c'est l'academie qui n'a pas encore ouvert. Tout suit
-- cette politique : entrer_observation, budget_observation, le jeton video et
-- la coupure serveur (revocation d'une visite ouverte).
SELECT pg_temp.remplacer('public.politique_observation_effective(uuid)',
  $a$if not coalesce((public.get_config('observation.activee', 'true'::jsonb))::boolean, true)
     or v_source = 'desactivee' then$a$,
  $b$if not coalesce((public.get_config('observation.activee', 'false'::jsonb))::boolean, false) then
    v_activee := false;
    v_max_visites := 0;
    v_max_secondes := 0;
    v_max_secondes_visite := null;
    v_policy_version := 'fermee';
  elsif v_source = 'desactivee' then$b$, 1);

-- Empreintes F86 eventuelles des fonctions retouchees.
DO $empreintes$
DECLARE
  v_f pg_catalog.regprocedure;
  v_com text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['public.annonces_observation(uuid)'::pg_catalog.regprocedure,
                             'public.politique_observation_effective(uuid)'::pg_catalog.regprocedure] LOOP
    v_com := pg_catalog.obj_description(v_f, 'pg_proc');
    IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
        pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
          'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
    END IF;
  END LOOP;
END;
$empreintes$;

-- ------------------------------------------------------------------
-- 3. La tache planifiee, sur le modele de courriels-envoi
-- ------------------------------------------------------------------
-- Seulement sur un projet Supabase (pg_cron, pg_net et le coffre presents) ;
-- un Postgres nu (CI) passe. cron.schedule remplace une tache du meme nom.
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'pg_cron')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'pg_net')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = 'vault') THEN
    CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    PERFORM cron.schedule('observation-coupure', '* * * * *', $cron$
      SELECT net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'observation_coupure_url'),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'x-observation-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'observation_coupure_secret')),
        body := '{}'::jsonb)
      WHERE EXISTS (SELECT 1 FROM public.guardian_session_visit v
                     WHERE v.role = 'guardian_observer'
                       AND (v.left_at IS NULL
                            OR (v.fin_de_visite IN ('quota_atteint', 'revocation_serveur', 'seance_terminee')
                                AND v.left_at > pg_catalog.now() - pg_catalog.make_interval(mins => 3))))
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'observation_coupure_url')
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'observation_coupure_secret');
    $cron$);
  END IF;
END;
$planification$;

-- ------------------------------------------------------------------
-- Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f pg_catalog.regprocedure := 'public.couper_visites_observation_echues(text,text)'::pg_catalog.regprocedure;
  v_taches integer;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef
                    AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'O1 : couper_visites_observation_echues sans DEFINER ou search_path';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
    RAISE EXCEPTION 'O1 : couper_visites_observation_echues executable par un client';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro')
     AND pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
    RAISE EXCEPTION 'O1 : couper_visites_observation_echues executable par agent_ro';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.annonces_observation(uuid)'::pg_catalog.regprocedure),
                       'c29_enseignant_effectif_session') = 0 THEN
    RAISE EXCEPTION 'O1 : annonces_observation ignore l''enseignant effectif';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.politique_observation_effective(uuid)'::pg_catalog.regprocedure),
                       'v_policy_version := ''fermee''') = 0 THEN
    RAISE EXCEPTION 'O1 : politique_observation_effective sans interrupteur ferme par defaut';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'observation.activee') THEN
    RAISE EXCEPTION 'O1 : cle observation.activee absente';
  END IF;
  -- Requete dynamique : sur un Postgres nu (CI), cron.job n'existe pas et une
  -- requete statique echouerait des l'analyse.
  IF pg_catalog.to_regclass('cron.job') IS NOT NULL THEN
    EXECUTE 'SELECT pg_catalog.count(*)::integer FROM cron.job WHERE jobname = $1'
      INTO v_taches USING 'observation-coupure';
    IF v_taches <> 1 THEN
      RAISE EXCEPTION 'O1 : tache observation-coupure absente';
    END IF;
  END IF;
END;
$postflight$;

COMMIT;
