-- PRIERE-1 (12/11/2026) : la priere a l'heure, calculee par le serveur.
-- Decision : docs/current/pedagogie/PRIERE.md (P1 a P11, arbitrage de l'architecte
-- pedagogique, sur delegation du directeur). Numero de migration reserve.
--
-- Ce fichier ne contient AUCUN des trois mots que le serveur Supabase fait
-- confirmer une seconde fois (effacement de ligne, suppression d'objet, vidage de
-- table) : il s'installe tel quel. Les lignes devenues inutiles ne sont jamais
-- retirees : elles sont marquees `retiree_le` et la vue du contrat les cache.
--
-- Contenu, dans l'ordre :
--   1. le contrat avec la salle : stock, vue `seance_pause_prevue`, lecture
--      `pause_prevue_seance(uuid)` ;
--   (la suite de la migration s'ajoute dans les commits suivants du lot)
--
-- Sans BEGIN ni COMMIT de premier niveau.

-- ===========================================================================
-- 1. Le contrat avec la salle
-- ===========================================================================

-- Le stock : une ligne par seance calculee. `retiree_le` non nul = aucune pause
-- de prière pour cette seance (aucune priere n'entre, pas de lieu, calcul
-- indefini...). Pas de cle etrangere : des operations et des tests retirent des
-- seances pour de bon, et la vue ne montre que les seances qui existent encore.
CREATE TABLE public.seance_pause_prevue_stock (
  session_id uuid PRIMARY KEY,
  debut_prevu_utc timestamptz,
  duree_minutes integer CHECK (duree_minutes BETWEEN 5 AND 20),
  motif text CHECK (motif = 'priere'),
  priere text CHECK (priere IN ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha')),
  calcule_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  retiree_le timestamptz,
  indefini boolean NOT NULL DEFAULT false,
  CONSTRAINT seance_pause_prevue_stock_complete CHECK (
    retiree_le IS NOT NULL
    OR (debut_prevu_utc IS NOT NULL AND duree_minutes IS NOT NULL
        AND motif IS NOT NULL AND priere IS NOT NULL)
  )
);

COMMENT ON TABLE public.seance_pause_prevue_stock IS
  'PRIERE-1 : stockage de la pause de priere prevue par seance. Rempli par le serveur seulement (private.priere_recalculer_seance). Jamais lu directement : la vue seance_pause_prevue (contrat avec la salle) et pause_prevue_seance() le montrent.';

ALTER TABLE public.seance_pause_prevue_stock ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.seance_pause_prevue_stock FROM PUBLIC, anon, authenticated, service_role;

-- Le contrat, tel que la salle le lit : une ligne quand une priere entre
-- pendant la seance, aucune sinon. Aucun droit direct.
CREATE VIEW public.seance_pause_prevue AS
  SELECT p.session_id,
         p.debut_prevu_utc,
         p.duree_minutes,
         p.motif,
         p.priere,
         p.calcule_le
    FROM public.seance_pause_prevue_stock p
    JOIN public.sessions s ON s.id = p.session_id AND s.deleted_at IS NULL
   WHERE p.retiree_le IS NULL;

COMMENT ON VIEW public.seance_pause_prevue IS
  'PRIERE-1, contrat avec la salle : la pause de priere prevue d''une seance. Aucune ligne quand aucune priere n''entre pendant la seance. Remplie par le serveur ; aucun droit direct ; lecture client par pause_prevue_seance(uuid).';

REVOKE ALL ON public.seance_pause_prevue FROM PUBLIC, anon, authenticated, service_role;

-- Lecture : la direction, l'enseignant qui enseigne reellement (titulaire, ou
-- remplacant accepte), les eleves de la classe et leur foyer. Jamais un lieu :
-- la fonction ne rend que l'heure, la duree, le motif et le nom de la priere.
CREATE FUNCTION public.pause_prevue_seance(p_session_id uuid)
RETURNS TABLE (
  debut_prevu_utc timestamptz,
  duree_minutes integer,
  motif text,
  priere text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_role public.app_role := public.app_role();
  v_menage uuid := public.app_household_id();
  v_groupe uuid;
  v_autorise boolean := false;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) OR v_uid IS NULL THEN
    RAISE EXCEPTION 'pause prevue : acces refuse' USING ERRCODE = '42501';
  END IF;

  SELECT s.groupe_id INTO v_groupe
    FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;

  IF FOUND THEN
    IF v_role = 'admin' THEN
      v_autorise := true;
    ELSIF v_role = 'teacher' THEN
      v_autorise := coalesce(
        private.c29_enseignant_effectif_session(p_session_id) = v_uid, false);
    ELSIF v_role IN ('student', 'guardian') THEN
      v_autorise := coalesce(
        EXISTS (
          SELECT 1
            FROM public.session_participants sp
            JOIN public.profiles pr ON pr.id = sp.profile_id
           WHERE sp.session_id = p_session_id
             AND sp.role = 'student'
             AND sp.deleted_at IS NULL
             AND pr.deleted_at IS NULL
             AND (pr.id = v_uid
                  OR (v_role = 'guardian' AND v_menage IS NOT NULL
                      AND pr.household_id = v_menage)))
        OR (v_groupe IS NOT NULL AND EXISTS (
          SELECT 1
            FROM public.groupe_membres gm
            JOIN public.profiles pr ON pr.id = gm.student_id
           WHERE gm.groupe_id = v_groupe
             AND gm.left_at IS NULL
             AND pr.deleted_at IS NULL
             AND (pr.id = v_uid
                  OR (v_role = 'guardian' AND v_menage IS NOT NULL
                      AND pr.household_id = v_menage)))),
        false);
    END IF;
  END IF;

  -- Exigence positive : tout ce qui n'est pas explicitement autorise est refuse
  -- (seance inconnue, role etranger, eleve d'une autre classe). Le refus est
  -- le meme dans tous les cas : aucun oracle sur l'existence d'une seance.
  IF NOT v_autorise THEN
    RAISE EXCEPTION 'pause prevue : acces refuse' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
    SELECT v.debut_prevu_utc, v.duree_minutes, v.motif, v.priere
      FROM public.seance_pause_prevue v
     WHERE v.session_id = p_session_id;
END;
$function$;

ALTER FUNCTION public.pause_prevue_seance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.pause_prevue_seance(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.pause_prevue_seance(uuid) TO authenticated;

COMMENT ON FUNCTION public.pause_prevue_seance(uuid) IS
  'PRIERE-1, contrat avec la salle : heure, duree, motif et priere de la pause prevue, sans aucun lieu. Direction, enseignant de la seance (titulaire ou remplacant accepte), eleves de la classe et leur foyer ; refus pour tout autre. Aucune ligne quand aucune priere n''entre pendant la seance.';
