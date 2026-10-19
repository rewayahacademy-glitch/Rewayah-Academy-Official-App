-- SES-CLOTURE-AUTO (18/10/2026) : une seance oubliee ne reste plus « planned »,
-- « preflight » ou « in_progress » apres son heure de fin. Elle bloquait la
-- paie (FAC-E-02 ne paie qu'une seance `ended`) et l'historique.
--
-- * Reglage : `app_config` cle `seances.cloture_auto_marge_minutes` (valeur
--   posee ici, modifiable par la direction). Le code ne porte aucune duree.
-- * `private.ses_cloturer_seances_echues(p_maintenant)` : toute seance dont la
--   fin prevue + la marge est depassee est close en suivant la machine d'etats
--   (`guard_session_state_transition`) et les memes declencheurs que la fin
--   normale (horodatage financier, paie due, presence, missions de controle) :
--     - l'enseignant (ou son remplacant) a un evenement `joined` : `ended`
--       (une seance encore « planned » ou « preflight » passe par les etapes
--       preflight puis in_progress, jamais d'un saut interdit) ;
--     - sinon, seance « planned » ou « preflight » : `teacher_absent` ;
--     - sinon, seance « in_progress » sans arrivee de l'enseignant (la machine
--       interdit teacher_absent) : `tech_failure`, la direction fixe la duree
--       (file `tresorerie_a_reprendre`, raison `duree_indeterminee`).
--   Une seance passee de force par les etapes n'a pas de duree mesuree : si des
--   eleves etaient presents et que la paie n'a rien ecrit, la seance part dans
--   la file de reprise pour que la direction fixe la duree tenue.
--   Idempotente : une seance finie n'est jamais relue ; une seance verrouillee
--   par un autre traitement est laissee au passage suivant ; l'echec d'une
--   seance n'arrete pas les autres.
-- * Journal : chaque cloture ecrit `seance_cloturee_auto` dans `audit_logs`
--   (charge `automatique: true`, ancien et nouveau statut, declencheur), lisible
--   par la direction.
-- * `public.ses_cloturer_seances_echues_maintenant()` : declenchement manuel,
--   direction connectee avec double authentification (aal2).
-- * Planification toutes les 15 minutes par pg_cron, seulement si l'extension
--   est deja installee ; sinon la migration passe sans rien planifier.
BEGIN;

INSERT INTO public.app_config (key, value)
VALUES ('seances.cloture_auto_marge_minutes', '30'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.ses_cloturer_seances_echues(p_maintenant timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_marge integer;
  v_brut jsonb;
  v_declencheur text := CASE WHEN auth.uid() IS NULL THEN 'planification' ELSE 'direction' END;
  v_s record;
  v_present boolean;
  v_cible public.session_status;
  v_etape public.session_status;
  v_a_reprendre boolean;
  v_ended integer := 0;
  v_absent integer := 0;
  v_panne integer := 0;
  v_erreurs integer := 0;
BEGIN
  IF p_maintenant IS NULL THEN
    RAISE EXCEPTION 'instant de reference obligatoire' USING ERRCODE = '22023';
  END IF;
  SELECT c.value INTO v_brut FROM public.app_config c WHERE c.key = 'seances.cloture_auto_marge_minutes';
  IF v_brut IS NULL OR pg_catalog.jsonb_typeof(v_brut) <> 'number'
     OR (v_brut #>> '{}') !~ '^[0-9]{1,5}$' THEN
    RAISE EXCEPTION 'reglage seances.cloture_auto_marge_minutes absent ou invalide' USING ERRCODE = '22023';
  END IF;
  v_marge := (v_brut #>> '{}')::integer;

  FOR v_s IN
    SELECT s.id, s.status, s.teacher_id, s.ended_at
      FROM public.sessions s
     WHERE s.deleted_at IS NULL
       AND s.status IN ('planned', 'preflight', 'in_progress')
       AND s.ended_at + pg_catalog.make_interval(mins => v_marge) < p_maintenant
     ORDER BY s.ended_at, s.id
       FOR UPDATE OF s SKIP LOCKED
  LOOP
    BEGIN
      v_etape := v_s.status;
      v_present := EXISTS (
        SELECT 1 FROM public.session_events e
         WHERE e.session_id = v_s.id AND e.event_type = 'joined'
           AND e.profile_id IN (v_s.teacher_id,
                                coalesce(private.c29_enseignant_effectif_session(v_s.id), v_s.teacher_id)));
      IF v_present THEN
        v_cible := 'ended';
        IF v_etape = 'planned' THEN
          UPDATE public.sessions SET status = 'preflight' WHERE id = v_s.id;
          v_etape := 'preflight';
        END IF;
        IF v_etape = 'preflight' THEN
          UPDATE public.sessions SET status = 'in_progress' WHERE id = v_s.id;
        END IF;
      ELSIF v_s.status = 'in_progress' THEN
        v_cible := 'tech_failure';
      ELSE
        v_cible := 'teacher_absent';
      END IF;
      UPDATE public.sessions SET status = v_cible WHERE id = v_s.id;

      v_a_reprendre := false;
      IF v_cible = 'ended' AND v_s.status <> 'in_progress' THEN
        -- Duree non mesuree : la direction la fixe si des eleves etaient la.
        IF private.pai_eleves_presents(v_s.id) > 0 AND NOT EXISTS (
             SELECT 1 FROM public.tresorerie_mouvements m
              WHERE m.source_type = 'prestation' AND m.source_id = v_s.id::text
                AND m.regle = 'remuneration_due') THEN
          PERFORM public.x217_mettre_en_file('prestation', v_s.id::text, 'duree_indeterminee');
          v_a_reprendre := true;
        END IF;
      END IF;

      PERFORM public.log_sensitive_access('seance_cloturee_auto', 'sessions', v_s.id::text,
        pg_catalog.jsonb_build_object(
          'automatique', true,
          'declencheur', v_declencheur,
          'statut_avant', v_s.status,
          'statut_apres', v_cible,
          'enseignant_present', v_present,
          'fin_prevue', v_s.ended_at,
          'marge_minutes', v_marge,
          'duree_a_fixer_par_la_direction', v_a_reprendre OR v_cible = 'tech_failure'));
      IF v_cible = 'ended' THEN v_ended := v_ended + 1;
      ELSIF v_cible = 'teacher_absent' THEN v_absent := v_absent + 1;
      ELSE v_panne := v_panne + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_erreurs := v_erreurs + 1;
      RAISE WARNING 'cloture automatique de la seance % impossible : %', v_s.id, SQLERRM;
    END;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'ended', v_ended, 'teacher_absent', v_absent, 'tech_failure', v_panne, 'erreurs', v_erreurs);
END;
$function$;

CREATE FUNCTION public.ses_cloturer_seances_echues_maintenant()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(
       public.app_account_valid()
       AND public.app_role() = 'admin'
       AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'cloture des seances reservee a la direction (double authentification)'
      USING ERRCODE = '42501';
  END IF;
  RETURN private.ses_cloturer_seances_echues(pg_catalog.clock_timestamp());
END;
$function$;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.ses_cloturer_seances_echues_maintenant()'::regprocedure;
BEGIN
  ALTER FUNCTION private.ses_cloturer_seances_echues(timestamptz) OWNER TO postgres;
  REVOKE ALL ON FUNCTION private.ses_cloturer_seances_echues(timestamptz)
    FROM PUBLIC, anon, authenticated, service_role, agent_ro;
  ALTER FUNCTION public.ses_cloturer_seances_echues_maintenant() OWNER TO postgres;
  REVOKE ALL ON FUNCTION public.ses_cloturer_seances_echues_maintenant()
    FROM PUBLIC, anon, service_role, agent_ro;
  GRANT EXECUTE ON FUNCTION public.ses_cloturer_seances_echues_maintenant() TO authenticated;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_AAL2; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. SES-CLOTURE-AUTO.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  COMMENT ON FUNCTION private.ses_cloturer_seances_echues(timestamptz) IS
    'SES-CLOTURE-AUTO : cloture les seances echues (marge app_config seances.cloture_auto_marge_minutes) par la machine d''etats et les declencheurs normaux ; journal seance_cloturee_auto. DEFINER, jamais exposee aux clients ; appelee par pg_cron et par ses_cloturer_seances_echues_maintenant().';
END;
$droits$;

-- Planification toutes les 15 minutes, seulement si pg_cron est installee.
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      EXECUTE $cron$SELECT cron.schedule('ses_cloture_auto', '*/15 * * * *',
        'SELECT private.ses_cloturer_seances_echues(pg_catalog.clock_timestamp())')$cron$;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'SES-CLOTURE-AUTO : planification pg_cron impossible (%) ; a faire a la main', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'SES-CLOTURE-AUTO : pg_cron absente, rien n''est planifie (appel manuel par la direction)';
  END IF;
END;
$planification$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated', 'private.ses_cloturer_seances_echues(timestamptz)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.ses_cloturer_seances_echues(timestamptz)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'SES-CLOTURE-AUTO : la cloture automatique doit rester au serveur';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.ses_cloturer_seances_echues_maintenant()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ses_cloturer_seances_echues_maintenant()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.ses_cloturer_seances_echues_maintenant()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'SES-CLOTURE-AUTO : droits de l''enveloppe admin invalides';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'seances.cloture_auto_marge_minutes') THEN
    RAISE EXCEPTION 'SES-CLOTURE-AUTO : reglage de marge absent';
  END IF;
END;
$postflight$;

COMMIT;
