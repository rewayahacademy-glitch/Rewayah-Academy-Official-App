-- FN-SERVEUR (03/11/2026, PLAN-LOTS rang 11, plan valide par le pilote) :
-- trois lectures serveur corrigees, sans toucher l'application.
--
-- FN-003 : private.presence_temps_reel bornait la presence a la fin
--   financiere de la seance. Une seance close automatiquement des heures
--   apres sa fin prevue comptait un enseignant entre sans jamais sortir
--   jusqu'a la cloture (1 799 minutes pour une seance d'une heure). La borne
--   est desormais la fin prevue plus la grace. L'argent ne change pas : la
--   paie etait deja plafonnee a la duree prevue.
-- FN-019 : mes_seances_enseignant_v et cahier_semaine_depose ne
--   connaissaient que le titulaire ; le remplacant de la seance
--   (private.c29_enseignant_effectif_session) la voit et lit l'etat du cahier
--   de la semaine.
-- FN-106 : mes_seances_v ne rend plus a la famille ni a l'eleve une seance
--   d'une Classe quittee ou cloturee avant son debut (la seance annulee de
--   l'ancienne Classe apparaissait en tete de l'Accueil). Les seances d'avant
--   le depart restent ; l'enseignant, la direction et le controleur ne
--   changent pas.
--
-- FICHIER SANS EFFACEMENT (regle B5) : deux fonctions et deux vues
-- remplacees a signature et colonnes egales ; rien n'est retire.

BEGIN;

-- 1. FN-003 ------------------------------------------------------------------

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

-- 2. FN-019 ------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cahier_semaine_depose(p_seance uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid()
                  AND (public.app_role() = 'admin'
                       OR EXISTS (SELECT 1 FROM public.sessions s
                                   WHERE s.id = p_seance AND s.teacher_id = auth.uid())
                       -- FN-019 : le remplacant de la seance.
                       OR private.c29_enseignant_effectif_session(p_seance) = auth.uid()),
                  false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN private.cahier_semaine_couvert(p_seance);
END;
$function$;
COMMENT ON FUNCTION public.cahier_semaine_depose(uuid) IS
  'CAHIER-HEBDOMADAIRE (31/10/2026) : lecture de private.cahier_semaine_couvert pour mes_seances_enseignant_v. Garde : compte valide, enseignant de la seance, son remplacant (FN-019, 03/11/2026) ou direction. Lecture seule.';

CREATE OR REPLACE VIEW public.mes_seances_enseignant_v WITH (security_barrier = true) AS
 SELECT s.id AS session_id,
    s.started_at,
    s.ended_at,
    s.status,
    s.session_type,
    s.prayer_pause_minutes,
    s.groupe_id,
    g.libelle AS groupe_libelle,
    g.type_public,
    g.seuil_max,
    count(DISTINCT sp.profile_id) FILTER (WHERE sp.role = 'student'::public.participant_role AND sp.deleted_at IS NULL)::integer AS nb_participants,
    (EXISTS ( SELECT 1
           FROM public.lesson_reports lr
          WHERE lr.session_id = s.id AND lr.deleted_at IS NULL)) AS cahier_depose,
    public.cahier_semaine_depose(s.id) AS cahier_semaine_depose
   FROM public.sessions s
     LEFT JOIN public.groupes g ON g.id = s.groupe_id
     LEFT JOIN public.session_participants sp ON sp.session_id = s.id
  WHERE s.deleted_at IS NULL
    AND (s.teacher_id = auth.uid()
         -- FN-019 : le remplacant voit la seance qu'il assure. Meme regle que
         -- private.c29_enseignant_effectif_session (dernier evenement de
         -- remplacement), ecrite ici : une fonction appelee dans une vue est
         -- executee avec les droits de l'appelant, et celle-ci est fermee aux
         -- comptes clients.
         OR EXISTS (
           SELECT 1
             FROM (SELECT x.evenement, x.enseignant_remplacant_id
                     FROM public.remplacements_seance x
                    WHERE x.session_id = s.id
                    ORDER BY x.cree_le DESC, x.id DESC
                    LIMIT 1) r
            WHERE r.evenement IN ('remplacement_pris', 'remplacement_designe_admin')
              AND r.enseignant_remplacant_id = auth.uid()))
  GROUP BY s.id, s.started_at, s.ended_at, s.status, s.session_type, s.prayer_pause_minutes, s.groupe_id, g.libelle, g.type_public, g.seuil_max;
COMMENT ON VIEW public.mes_seances_enseignant_v IS
  'ENS-02 : les seances de l''enseignant connecte (titulaire, ou remplacant depuis FN-019, 03/11/2026), une ligne par seance et non par eleve. Ne porte aucun prenom : le roster se lit par teacher_roster_v, qui applique deja le masquage d''observation. CAHIER-HEBDOMADAIRE (31/10/2026) : cahier_semaine_depose, la semaine de la Classe est couverte pour les eleves de la seance.';

-- 3. FN-106 ------------------------------------------------------------------

CREATE OR REPLACE VIEW public.mes_seances_v
WITH (security_barrier = true)
AS
SELECT
  s.id AS session_id,
  s.started_at,
  s.ended_at,
  s.status,
  s.session_type,
  s.prayer_pause_minutes,
  eleve.id AS student_id,
  CASE WHEN public.agent_identite_masquee()
       THEN eleve.immutable_id ELSE eleve.first_name END AS student_first_name,
  eleve.immutable_id AS student_immutable_id,
  ens.id AS teacher_id,
  CASE WHEN public.agent_identite_masquee()
       THEN ens.immutable_id ELSE ens.first_name END AS teacher_first_name,
  ens.immutable_id AS teacher_immutable_id
FROM public.sessions s
JOIN public.session_participants spe
  ON spe.session_id = s.id AND spe.role = 'student' AND spe.deleted_at IS NULL
JOIN public.profiles eleve ON eleve.id = spe.profile_id AND eleve.deleted_at IS NULL
JOIN public.profiles ens ON ens.id = s.teacher_id AND ens.deleted_at IS NULL
WHERE s.deleted_at IS NULL
  AND public.app_account_valid()
  AND (
    (public.app_role() = 'teacher' AND s.teacher_id = auth.uid())
    OR (
      (
        (public.app_role() = 'student' AND spe.profile_id = auth.uid())
        OR (
          public.app_role() = 'guardian'
          AND eleve.household_id IS NOT NULL
          AND eleve.household_id = public.app_household_id()
        )
      )
      -- FN-106 : pas de seance d'une Classe quittee ou cloturee avant son
      -- debut ; les seances d'avant le depart restent (historique).
      AND NOT EXISTS (
        SELECT 1 FROM public.groupe_membres gm
         WHERE gm.groupe_id = s.groupe_id AND gm.student_id = eleve.id
           AND gm.left_at IS NOT NULL AND gm.left_at <= s.started_at
           AND NOT EXISTS (SELECT 1 FROM public.groupe_membres gm2
                            WHERE gm2.groupe_id = s.groupe_id AND gm2.student_id = eleve.id
                              AND gm2.left_at IS NULL))
      AND NOT EXISTS (
        SELECT 1 FROM public.groupes g
         WHERE g.id = s.groupe_id AND g.ended_at IS NOT NULL AND g.ended_at <= s.started_at)
    )
    OR public.app_role() IN ('admin', 'controller')
  );

-- Postflight ------------------------------------------------------------------

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure),
                       'grace_after_end_minutes') = 0 THEN
    RAISE EXCEPTION 'FN-003 : presence_temps_reel sans borne de grace';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.presence_temps_reel(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-003 : presence_temps_reel exposee';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.cahier_semaine_depose(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.cahier_semaine_depose(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-019 : droits de cahier_semaine_depose invalides';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.mes_seances_enseignant_v'::pg_catalog.regclass
                    AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true'])
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.mes_seances_v'::pg_catalog.regclass
                    AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']) THEN
    RAISE EXCEPTION 'FN-019/FN-106 : une vue a perdu security_barrier';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_views v
                  WHERE v.schemaname = 'public' AND v.viewname = 'mes_seances_v'
                    AND v.definition LIKE '%app_account_valid%') THEN
    RAISE EXCEPTION 'FN-106 : mes_seances_v a perdu sa garde';
  END IF;
END;
$postflight$;

COMMIT;
