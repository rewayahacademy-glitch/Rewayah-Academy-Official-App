-- PAIE-MINUTES-RECONNEXION (13/11/2026) : private.presence_temps_reel perdait
-- du temps de presence a chaque reconnexion.
--
-- DEFAUT (prouve en production, lecture seule, seance du 12/11/2026) : chaque
-- joined de session_events etait apparie au premier left d'horodatage superieur
-- OU EGAL. Une reconnexion ecrit le left de l'ancienne connexion et le joined de
-- la nouvelle a la meme seconde (horodatage du webhook video tronque a la
-- seconde) : le nouveau joined prenait ce left, intervalle nul, et tout le temps
-- jusqu'au left suivant disparaissait. Enseignant de la seance citee : 33
-- minutes rendues pour 39 reelles. Ces minutes alimentent la paie
-- (private.pai_minutes_enseignant, private.pai_due_seance) et la presence des
-- eleves.
--
-- CORRECTION : seul l'appariement joined/left change (detail dans le corps).
-- Restent a l'identique de 20261107500000 : les bornes v_debut et v_fin (regle
-- FN-003 comprise), la branche session_participants.entered_at/exited_at, la
-- fusion des ilots, l'heure de sortie, le statut et le seuil, la signature et
-- les droits. Aucune regle de prix, de taux, de seuil ou de duree due ne change.
--
-- AUCUN RECALCUL : ce fichier ne modifie aucune ligne. Les montants deja ecrits
-- (tresorerie_mouvements et les autres tables d'argent) restent tels quels ;
-- seules les lectures et les clotures A VENIR utilisent la nouvelle mesure.
--
-- FICHIER SANS EFFACEMENT (regle B5) : une fonction remplacee a signature
-- egale, rien n'est retire. Rejouable, collable en un bloc.
-- Scenario : supabase/tests/scenarios_paie_minutes_reconnexion.sql.

BEGIN;

CREATE OR REPLACE FUNCTION private.presence_temps_reel(p_seance uuid, p_profil uuid)
RETURNS TABLE (arrivee timestamptz, sortie timestamptz, minutes integer,
               minutes_prevues integer, statut text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions;
  v_debut timestamptz;
  v_fin timestamptz;
  v_seuil numeric;
  v_override public.presence_state;
  v_secondes numeric := 0;
  v_prevues numeric;
  v_ouvert_fin boolean := false;
  r record;
  v_ilot_debut timestamptz;
  v_ilot_fin timestamptz;
  -- PAIE-MINUTES-RECONNEXION : connexions ouvertes (pile) et intervalles tires
  -- des evenements joined/left.
  g record;
  v_pile timestamptz[] := ARRAY[]::timestamptz[];
  v_a timestamptz[] := ARRAY[]::timestamptz[];
  v_b timestamptz[] := ARRAY[]::timestamptz[];
  v_o boolean[] := ARRAY[]::boolean[];
  v_reste integer;
  v_n integer;
  v_j timestamptz;
  v_suivant timestamptz;
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  v_debut := v_s.started_at;
  -- FN-003 : une fin financiere posee tard (cloture automatique, des heures
  -- apres) ne prolonge plus la presence au-dela de la fin prevue et de la
  -- grace (grace_after_end_minutes) ; sans fin financiere, rien ne change.
  v_fin := coalesce(
    least(v_s.finance_ended_at,
          v_s.ended_at + pg_catalog.make_interval(mins => public.app_config_int('grace_after_end_minutes', 15))),
    least(pg_catalog.now(), v_s.ended_at));
  v_prevues := extract(epoch FROM (v_s.ended_at - v_s.started_at));
  v_seuil := public.app_config_int('presence.seuil_present_pourcentage', 50);

  -- PAIE-MINUTES-RECONNEXION (13/11/2026). Les evenements joined/left sont lus
  -- dans l'ordre de server_ts (jamais l'ordre d'insertion), un groupe par
  -- horodatage, comme des connexions ouvertes :
  --   * un left ferme d'abord une connexion ouverte AVANT cet horodatage ; il
  --     ne ferme donc plus la connexion qui s'ouvre a la meme seconde
  --     (reconnexion : left de l'ancienne et joined de la nouvelle arrivent
  --     avec le meme horodatage, tronque a la seconde par le webhook video) ;
  --   * s'il n'y a rien d'ouvert, un left et un joined du meme horodatage
  --     s'annulent (connexion de moins d'une seconde : zero, comme avant) ;
  --   * un left sans connexion ouverte est ignore, comme avant ;
  --   * deux appareils en meme temps : la presence dure jusqu'au left qui
  --     ferme la derniere connexion (union reelle) ;
  --   * un joined jamais ferme par un left qui lui revient garde la regle
  --     d'avant : ferme au left suivant s'il y en a un, sinon ouvert jusqu'a
  --     la borne de fin (deux joined pour un seul left comptent une fois).
  -- session_events ne porte aucun identifiant de connexion : ni id (ordre
  -- d'arrivee des webhooks, non garanti) ni source (geste ou reseau) ne dit
  -- quelle connexion un left ferme ; aucun des deux ne sert donc a departager.
  FOR g IN
    SELECT e.server_ts AS ts,
           (pg_catalog.count(*) FILTER (WHERE e.event_type = 'joined'))::integer AS nj,
           (pg_catalog.count(*) FILTER (WHERE e.event_type = 'left'))::integer AS nl
      FROM public.session_events e
     WHERE e.session_id = p_seance AND e.profile_id = p_profil
       AND e.event_type IN ('joined', 'left')
     GROUP BY e.server_ts
     ORDER BY e.server_ts
  LOOP
    v_reste := g.nl;
    v_n := coalesce(pg_catalog.cardinality(v_pile), 0);
    WHILE v_reste > 0 AND v_n > 0 LOOP
      v_a := v_a || v_pile[v_n];
      v_b := v_b || g.ts;
      v_o := v_o || false;
      v_pile := v_pile[1:v_n - 1];
      v_n := v_n - 1;
      v_reste := v_reste - 1;
    END LOOP;
    FOR v_n IN 1 .. g.nj - v_reste LOOP
      v_pile := v_pile || g.ts;
    END LOOP;
  END LOOP;
  -- Connexions restees ouvertes : left suivant s'il existe, sinon borne de fin.
  FOREACH v_j IN ARRAY v_pile LOOP
    SELECT pg_catalog.min(e.server_ts) INTO v_suivant
      FROM public.session_events e
     WHERE e.session_id = p_seance AND e.profile_id = p_profil
       AND e.event_type = 'left' AND e.server_ts > v_j;
    v_a := v_a || v_j;
    v_b := v_b || coalesce(v_suivant, v_fin);
    v_o := v_o || (v_suivant IS NULL);
  END LOOP;

  -- Ilots : intervalles bornes, tries par debut, fusionnes a la volee.
  FOR r IN
    WITH intervalles AS (
      SELECT x.a, x.b, x.ouvert
        FROM ROWS FROM (pg_catalog.unnest(v_a), pg_catalog.unnest(v_b), pg_catalog.unnest(v_o))
             AS x(a, b, ouvert)
      UNION ALL
      SELECT sp.entered_at, coalesce(sp.exited_at, v_fin), sp.exited_at IS NULL
        FROM public.session_participants sp
       WHERE sp.session_id = p_seance AND sp.profile_id = p_profil
         AND sp.deleted_at IS NULL AND sp.entered_at IS NOT NULL
    )
    SELECT greatest(i.a, v_debut) AS a, least(i.b, v_fin) AS b, i.ouvert
      FROM intervalles i
     WHERE least(i.b, v_fin) > greatest(i.a, v_debut)
     ORDER BY 1, 2
  LOOP
    IF v_ilot_fin IS NULL OR r.a > v_ilot_fin THEN
      IF v_ilot_fin IS NOT NULL THEN
        v_secondes := v_secondes + extract(epoch FROM (v_ilot_fin - v_ilot_debut));
      END IF;
      v_ilot_debut := r.a;
      v_ilot_fin := r.b;
      v_ouvert_fin := r.ouvert;
      IF arrivee IS NULL THEN
        arrivee := r.a;
      END IF;
    ELSIF r.b >= v_ilot_fin THEN
      v_ouvert_fin := CASE WHEN r.b > v_ilot_fin THEN r.ouvert ELSE v_ouvert_fin OR r.ouvert END;
      v_ilot_fin := r.b;
    END IF;
  END LOOP;
  IF v_ilot_fin IS NOT NULL THEN
    v_secondes := v_secondes + extract(epoch FROM (v_ilot_fin - v_ilot_debut));
    -- Encore connecte pendant la seance : pas d'heure de sortie a montrer.
    sortie := CASE WHEN v_ouvert_fin AND v_s.finance_ended_at IS NULL
                         AND v_s.status IN ('planned', 'preflight', 'in_progress')
                    THEN NULL ELSE v_ilot_fin END;
  END IF;

  minutes := pg_catalog.floor(v_secondes / 60)::integer;
  minutes_prevues := pg_catalog.ceil(v_prevues / 60)::integer;

  SELECT o.etat INTO v_override FROM public.session_presence_override o
   WHERE o.session_id = p_seance AND o.profile_id = p_profil;
  statut := CASE
    WHEN v_override = 'excusee' THEN 'excusee'
    WHEN v_override = 'corrigee_manuel' THEN 'presente'
    WHEN v_secondes <= 0 THEN 'absente'
    WHEN v_secondes * 100 >= v_prevues * v_seuil THEN 'presente'
    ELSE 'partielle'
  END;
  RETURN NEXT;
END;
$function$;

COMMENT ON FUNCTION private.presence_temps_reel(uuid, uuid) IS
  'PRESENCE-MINUTES (31/10/2026), PAIE-MINUTES-RECONNEXION (13/11/2026) : arrivee, sortie, minutes connectees (joined/left de session_events lus comme des connexions ouvertes, un left ne ferme jamais la connexion ouverte a la meme seconde ; entered_at/exited_at ; bornes a la seance, reconnexions additionnees, chevauchements comptes une fois), minutes prevues et etat : presente (>= presence.seuil_present_pourcentage de la duree prevue), partielle (> 0), absente (0) ; excusee et corrigee_manuel de la direction l''emportent. Privee.';

-- Postflight ------------------------------------------------------------------

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'PAIE-MINUTES-RECONNEXION') = 0
     OR pg_catalog.strpos(v_def, 'l.server_ts >= j.server_ts') > 0 THEN
    RAISE EXCEPTION 'PAIE-MINUTES-RECONNEXION : ancien appariement encore en place';
  END IF;
  IF pg_catalog.strpos(v_def, 'grace_after_end_minutes') = 0 THEN
    RAISE EXCEPTION 'PAIE-MINUTES-RECONNEXION : borne de grace (FN-003) perdue';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('public', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PAIE-MINUTES-RECONNEXION : presence_temps_reel exposee';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure
                    AND p.prosecdef AND p.provolatile = 's'
                    AND 'search_path=""' = ANY (coalesce(p.proconfig, ARRAY[]::text[]))) THEN
    RAISE EXCEPTION 'PAIE-MINUTES-RECONNEXION : fonction mal durcie';
  END IF;
END;
$postflight$;

COMMIT;
