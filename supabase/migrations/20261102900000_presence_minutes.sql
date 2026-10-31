-- PRESENCE-MINUTES (31/10/2026) : la presence de l'eleve au temps reel.
--
-- DELETE / DROP / TRUNCATE : 0. Un INSERT de reglage (ON CONFLICT DO
-- NOTHING), une fonction privee et une lecture publique gardee creees, une fonction privee remplacee
-- (CREATE OR REPLACE, meme signature), une vue remplacee (CREATE OR REPLACE
-- VIEW : memes colonnes dans le meme ordre, quatre colonnes ajoutees a la
-- fin), commentaires et verifications.
--
-- Decision du 31/10/2026 (08 §5 bis, PR 97 ; laissee au pilote par le
-- directeur) : le serveur additionne les minutes reellement connectees.
--   * presente : au moins `presence.seuil_present_pourcentage` (50 %) de la
--     duree prevue ;
--   * partielle : plus de zero et moins de ce seuil ;
--   * absente : aucune connexion.
-- L'enseignant est paye pour les presents et les presences partielles ;
-- l'absent ne compte pas. La famille et la direction voient l'arrivee, la
-- sortie et le total des minutes.
--
-- Le defaut corrige : `private.pai_eleves_presents` (FAC-E-02,
-- 20261018130000:33-48) comptait « present » sur un seul evenement `joined`.
-- C'est la source unique de la paie (lue par `private.pai_due_seance`,
-- `private.pai_releve_seances` [PAIE-REMPLACANT, 20261102300000, qui
-- attribue la seance a l'enseignant effectif via
-- `private.c29_enseignant_effectif_session`, non touche ici] et
-- `public.ses_cloture_auto`). On la remplace a signature egale : aucune
-- seconde source, aucun appelant a reecrire.
--
-- Sources lues, toutes existantes (rien de nouveau n'est enregistre) :
--   * `session_events` `joined` / `left` : verite serveur ecrite par les
--     webhooks LiveKit (0010, `recevoir_webhook_livekit`, idempotence par
--     `livekit_webhook_deliveries`) et par le geste de sortie
--     (`quitter_salle`, source `user_action`) ;
--   * `session_participants.entered_at` / `exited_at` quand ils sont poses
--     (missions de controle C-29).
-- Chaque `joined` ouvre un intervalle ferme par le premier `left` qui le
-- suit ; sans `left`, par la fin de la seance (`finance_ended_at`, sinon
-- l'heure prevue, bornee a maintenant pendant la seance). Les intervalles
-- sont bornes a [debut prevu, fin], puis fusionnes : une reconnexion ajoute
-- ses minutes, un chevauchement (deux appareils, webhook en double, `joined`
-- sans `left`) n'est compte qu'une fois.
--
-- Corrections de la direction (`session_presence_override`, inchangees) :
-- `corrigee_manuel` vaut presente, `excusee` n'est pas payee.
BEGIN;

INSERT INTO public.app_config (key, value)
VALUES ('presence.seuil_present_pourcentage', '50'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 1. Les minutes connectees d'une personne a une seance
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.presence_temps_reel(p_seance uuid, p_profil uuid)
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
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  v_debut := v_s.started_at;
  v_fin := coalesce(v_s.finance_ended_at, least(pg_catalog.now(), v_s.ended_at));
  v_prevues := extract(epoch FROM (v_s.ended_at - v_s.started_at));
  v_seuil := public.app_config_int('presence.seuil_present_pourcentage', 50);

  -- Ilots : intervalles bornes, tries par debut, fusionnes a la volee.
  FOR r IN
    WITH ev AS (
      SELECT e.id, e.event_type, e.server_ts
        FROM public.session_events e
       WHERE e.session_id = p_seance AND e.profile_id = p_profil
         AND e.event_type IN ('joined', 'left')
    ), intervalles AS (
      SELECT j.server_ts AS a,
             coalesce((SELECT min(l.server_ts) FROM ev l
                        WHERE l.event_type = 'left' AND l.server_ts >= j.server_ts), v_fin) AS b,
             NOT EXISTS (SELECT 1 FROM ev l
                          WHERE l.event_type = 'left' AND l.server_ts >= j.server_ts) AS ouvert
        FROM ev j WHERE j.event_type = 'joined'
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

-- La lecture des clients : les quatre chemins de `public.etat_presence`
-- (direction ou controle, enseignant de la seance, tuteur du foyer, soi-meme),
-- recopies tels quels. Une fonction appelee par une vue s'execute avec les
-- droits de celui qui lit la vue : l'aide privee reste fermee, cette porte
-- seule est ouverte a `authenticated`.
CREATE FUNCTION public.presence_temps_seance(p_session_id uuid, p_profile_id uuid)
RETURNS TABLE (arrivee timestamptz, sortie timestamptz, minutes integer,
               minutes_prevues integer, statut text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_enseignant uuid;
BEGIN
  IF NOT public.app_account_valid() THEN
    RAISE EXCEPTION 'compte non valide' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT s.teacher_id INTO v_enseignant FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  IF NOT coalesce(
    public.app_role() = ANY (ARRAY['admin', 'controller']::public.app_role[])
    OR v_enseignant = auth.uid()
    OR (public.app_role() = 'guardian' AND public.est_du_foyer(p_profile_id))
    OR p_profile_id = auth.uid(),
    false
  ) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN QUERY SELECT * FROM private.presence_temps_reel(p_session_id, p_profile_id);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. La source de la paie : presents et presences partielles
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.pai_eleves_presents(p_seance uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT count(DISTINCT sp.profile_id)::integer
    FROM public.session_participants sp
    CROSS JOIN LATERAL private.presence_temps_reel(sp.session_id, sp.profile_id) t
   WHERE sp.session_id = p_seance AND sp.role = 'student' AND sp.deleted_at IS NULL
     AND t.statut IN ('presente', 'partielle');
$function$;

-- ---------------------------------------------------------------------------
-- 3. La vue lue par la famille, l'eleve et la direction : quatre colonnes
--    ajoutees a la fin (sortie, minutes connectees, minutes prevues, etat au
--    temps reel). Le reste est recopie de la base rejouee (pg_get_viewdef),
--    garde de compte et security_barrier compris (AF L1-08-reprise).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.presence_seance_v WITH (security_barrier = true) AS
 SELECT sp.session_id,
    sp.profile_id,
    sp.role,
        CASE
            WHEN public.agent_identite_masquee() THEN p.immutable_id
            ELSE p.first_name
        END AS prenom,
    p.immutable_id AS identifiant_immuable,
    public.etat_presence(sp.session_id, sp.profile_id) AS etat,
    ( SELECT
                CASE
                    WHEN min(e.server_ts) IS NOT NULL THEN GREATEST(min(e.server_ts), s.started_at)
                    ELSE NULL::timestamp with time zone
                END AS "case"
           FROM public.session_events e
          WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id AND e.event_type = 'joined'::public.session_event_type) AS entre_le,
    ( SELECT max(e.server_ts) AS max
           FROM public.session_events e
          WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id) AS derniere_trace_le,
    o.etat IS NOT NULL AS consolide,
    o.decide_le AS consolide_le,
    s.started_at,
    s.ended_at,
    s.status AS statut_seance,
    t.sortie AS sortie_le,
    t.minutes AS minutes_connectees,
    t.minutes_prevues,
    t.statut AS presence_temps
   FROM public.session_participants sp
     JOIN public.sessions s ON s.id = sp.session_id
     JOIN public.profiles p ON p.id = sp.profile_id
     LEFT JOIN public.session_presence_override o ON o.session_id = sp.session_id AND o.profile_id = sp.profile_id
     LEFT JOIN LATERAL public.presence_temps_seance(sp.session_id, sp.profile_id) t ON true
  WHERE ( SELECT public.app_account_valid() AS app_account_valid) AND sp.deleted_at IS NULL AND s.deleted_at IS NULL AND p.deleted_at IS NULL AND ((public.app_role() = ANY (ARRAY['admin'::public.app_role, 'controller'::public.app_role])) OR s.teacher_id = auth.uid() OR public.app_role() = 'guardian'::public.app_role AND public.est_du_foyer(p.id) OR sp.profile_id = auth.uid()) AND ((sp.role <> ALL (ARRAY['masked_controller'::public.participant_role, 'admin_masked'::public.participant_role])) OR public.app_role() = 'admin'::public.app_role);

-- ---------------------------------------------------------------------------
-- 4. Droits et commentaires
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure,
    'private.pai_eleves_presents(uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;
  v_oid := 'public.presence_temps_seance(uuid,uuid)'::pg_catalog.regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  -- Memes droits que `public.etat_presence`, sa voisine dans la vue.
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM anon', v_oid);
  END IF;
  FOREACH v_role IN ARRAY ARRAY['authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO %I', v_oid, v_role);
    END IF;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.presence_temps_reel(uuid, uuid) IS
  'PRESENCE-MINUTES (31/10/2026) : arrivee, sortie, minutes connectees (joined/left de session_events et entered_at/exited_at, bornes a la seance, reconnexions additionnees, chevauchements comptes une fois), minutes prevues et etat : presente (>= presence.seuil_present_pourcentage de la duree prevue), partielle (> 0), absente (0) ; excusee et corrigee_manuel de la direction l''emportent. Privee.';
COMMENT ON FUNCTION public.presence_temps_seance(uuid, uuid) IS
  'PRESENCE-MINUTES (31/10/2026) : lecture de private.presence_temps_reel pour presence_seance_v. Garde : compte valide et les quatre chemins de etat_presence (admin ou controle, enseignant de la seance, tuteur du foyer, soi-meme). Lecture seule.';
COMMENT ON FUNCTION private.pai_eleves_presents(uuid) IS
  'FAC-E-02, PRESENCE-MINUTES (31/10/2026) : eleves payes d''une seance = presents et presences partielles au temps reel (private.presence_temps_reel) ; absent et excusee non payes. Source unique de la paie. Privee.';
COMMENT ON VIEW public.presence_seance_v IS
  'Presence par seance (inscrits, pas connectes). PRESENCE-MINUTES (31/10/2026) : sortie_le, minutes_connectees, minutes_prevues, presence_temps (presente, partielle, absente, excusee) calcules au serveur.';

-- ---------------------------------------------------------------------------
-- 5. Verifications
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure,
    'private.pai_eleves_presents(uuid)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PRESENCE-MINUTES : aide privee % exposee ou mal declaree', v_oid;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated',
           'public.presence_temps_seance(uuid,uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
           'public.presence_temps_seance(uuid,uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PRESENCE-MINUTES : droits de presence_temps_seance invalides';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_views v
                  WHERE v.schemaname = 'public' AND v.viewname = 'presence_seance_v'
                    AND v.definition LIKE '%app_account_valid%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                     WHERE c.oid = 'public.presence_seance_v'::pg_catalog.regclass
                       AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']) THEN
    RAISE EXCEPTION 'PRESENCE-MINUTES : presence_seance_v a perdu sa garde ou security_barrier';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'presence.seuil_present_pourcentage') THEN
    RAISE EXCEPTION 'PRESENCE-MINUTES : reglage du seuil absent';
  END IF;
END;
$postflight$;

COMMIT;
