-- CAHIER-HEBDOMADAIRE (31/10/2026) : le cahier de transmission est
-- hebdomadaire, un par eleve et par semaine (decision du directeur du
-- 31/10/2026, 08 §5 bis, PR 97 ; confirme DECISION-TARIFS-2026-10-18.md :
-- « paie en attente si le cahier de la semaine manque »).
--
-- DELETE / DROP / TRUNCATE : 0. Deux fonctions creees (une aide privee, une
-- lecture publique gardee), trois remplacees a signature egale
-- (CREATE OR REPLACE), une vue remplacee (memes colonnes, une ajoutee a la
-- fin), droits, commentaires, verifications.
--
-- Rien de nouveau n'est enregistre : le cahier reste `lesson_reports` (une
-- ligne par seance, `content.eleves[].student_id` par eleve), depose par le
-- meme ecran. Seule la periode due change : la seance n'exige plus son
-- propre cahier, chaque eleve de la seance doit figurer dans UN cahier de
-- la meme Classe et de la meme semaine.
--
-- La semaine : du lundi au dimanche, dans le fuseau de la Classe
-- (`groupes.timezone_iana`). Pourquoi ce fuseau et pas un autre :
--   * l'horaire d'une Classe est defini dans ce fuseau (`weekday`,
--     `hour_local`, `horloge_classe`) : toutes ses seances tombent dans la
--     meme semaine locale, sans dependre de la ou vivent l'enseignant et les
--     familles (plusieurs fuseaux dans une meme Classe) ;
--   * en UTC, une Classe du dimanche soir a Montreal ou du lundi matin a
--     Jakarta changerait de semaine selon la saison et l'heure d'ete ;
--   * le fuseau de l'enseignant change s'il voyage ou s'il est remplace ;
--     celui de la Classe est fixe et unique.
-- Une seance sans Classe (cours individuel d'avant le pivot du 19/09) garde
-- l'ancienne regle : son propre cahier.
--
-- Branchements (aucune seconde source) :
--   1. `private.cahier_semaine_couvert(seance)` : la regle, seule source ;
--   2. `public.mes_rapports_en_attente()` (Journee de l'enseignant, liste des
--      cahiers a remplir) : une ligne par Classe et par semaine non couverte,
--      la derniere seance de la semaine ;
--   3. `public.mes_seances_enseignant_v.cahier_semaine_depose` (colonne
--      ajoutee) : le bouton de fin de seance (CTA-FIN-1) ne demande plus le
--      cahier quand la semaine est deja couverte ;
--   4. `private.pai_releve_seances` (releve de paie de la direction) : une
--      seance payee dont la semaine n'a pas son cahier passe « en attente »,
--      son montant sort du total a verser tant que le cahier manque. Corps
--      repris de la definition de PRODUCTION apres PRESENCE-MINUTES
--      (20261102900000, md5 c213e628... relu en production le 31/10, duree
--      = minutes connectees de l'enseignant effectif) ; seuls `montant` et
--      `en_attente` changent (et le `;` parasite en tete de corps laisse par
--      20261102900000 disparait).
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La regle
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.cahier_semaine_couvert(p_seance uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH s AS (
    SELECT s.id, s.groupe_id, g.timezone_iana AS tz,
           pg_catalog.date_trunc('week', s.started_at AT TIME ZONE g.timezone_iana) AS semaine
      FROM public.sessions s
      LEFT JOIN public.groupes g ON g.id = s.groupe_id
     WHERE s.id = p_seance
  )
  SELECT
    -- Le cahier de la seance elle-meme couvre toujours ses eleves (ancienne
    -- forme du contenu comprise).
    EXISTS (SELECT 1 FROM public.lesson_reports lr
             WHERE lr.session_id = p_seance AND lr.deleted_at IS NULL)
    OR (
      (SELECT s.groupe_id FROM s) IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
          FROM public.session_participants sp
         WHERE sp.session_id = p_seance AND sp.role = 'student' AND sp.deleted_at IS NULL
           AND NOT EXISTS (
             SELECT 1
               FROM s
               JOIN public.sessions s2
                 ON s2.groupe_id = s.groupe_id AND s2.deleted_at IS NULL
                AND pg_catalog.date_trunc('week', s2.started_at AT TIME ZONE s.tz) = s.semaine
               JOIN public.lesson_reports lr
                 ON lr.session_id = s2.id AND lr.deleted_at IS NULL
                AND pg_catalog.jsonb_typeof(lr.content -> 'eleves') = 'array'
              WHERE EXISTS (
                SELECT 1 FROM pg_catalog.jsonb_array_elements(lr.content -> 'eleves') e
                 WHERE e ->> 'student_id' = sp.profile_id::text))));
$function$;

-- La lecture de la vue de l'enseignant : une fonction appelee par une vue
-- s'execute avec les droits du lecteur, l'aide privee reste fermee.
CREATE FUNCTION public.cahier_semaine_depose(p_seance uuid)
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
                                   WHERE s.id = p_seance AND s.teacher_id = auth.uid())),
                  false) THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN private.cahier_semaine_couvert(p_seance);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Les cahiers a remplir de la Journee
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mes_rapports_en_attente()
 RETURNS TABLE(session_id uuid, started_at timestamp with time zone, ended_at timestamp with time zone, groupe_id uuid, groupe_libelle text, nb_participants integer, heures_de_retard integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select
    s.id,
    s.started_at,
    s.ended_at,
    s.groupe_id,
    g.libelle,
    count(distinct sp.profile_id) filter (
      where sp.role = 'student' and sp.deleted_at is null
    )::int,
    greatest(0, (extract(epoch from (now() - s.ended_at)) / 3600)::int)
  from public.sessions s
    left join public.groupes g on g.id = s.groupe_id
    left join public.session_participants sp on sp.session_id = s.id
  where s.deleted_at is null
    and s.teacher_id = auth.uid()
    and public.app_role() = 'teacher'
    and public.app_account_valid()
    -- Une seance annulee, ou l'enseignant ne s'est pas presente, ne doit aucun
    -- cahier : il n'y a rien a transmettre.
    and s.status in ('ended', 'student_absent', 'tech_failure')
    and s.ended_at < now()
    -- CAHIER-HEBDOMADAIRE : chaque eleve de la seance figure dans un cahier
    -- de la Classe cette semaine-la (fuseau de la Classe).
    and not private.cahier_semaine_couvert(s.id)
    -- Une ligne par Classe et par semaine : la derniere seance non couverte.
    and not exists (
      select 1 from public.sessions s2
       where s.groupe_id is not null
         and s2.groupe_id = s.groupe_id
         and s2.id <> s.id
         and s2.deleted_at is null
         and s2.teacher_id = auth.uid()
         and s2.status in ('ended', 'student_absent', 'tech_failure')
         and s2.ended_at < now()
         and s2.ended_at > s.ended_at
         and pg_catalog.date_trunc('week', s2.started_at at time zone g.timezone_iana)
             = pg_catalog.date_trunc('week', s.started_at at time zone g.timezone_iana)
         and not private.cahier_semaine_couvert(s2.id)
    )
  group by s.id, s.started_at, s.ended_at, s.groupe_id, g.libelle
  order by s.ended_at asc;
$function$;

-- ---------------------------------------------------------------------------
-- 3. La vue des seances de l'enseignant : une colonne ajoutee a la fin
-- ---------------------------------------------------------------------------
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
  WHERE s.deleted_at IS NULL AND s.teacher_id = auth.uid()
  GROUP BY s.id, s.started_at, s.ended_at, s.status, s.session_type, s.prayer_pause_minutes, s.groupe_id, g.libelle, g.type_public, g.seuil_max;

-- ---------------------------------------------------------------------------
-- 4. Le releve de paie : la semaine sans cahier met la seance en attente
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.pai_releve_seances(p_debut timestamptz, p_fin timestamptz)
RETURNS TABLE (seance uuid, enseignant uuid, groupe uuid, debut timestamptz, minutes bigint,
               presents integer, inscrits integer, montant bigint, devise text, en_attente boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT s.id, coalesce(private.c29_enseignant_effectif_session(s.id), s.teacher_id),
         s.groupe_id, s.started_at,
         CASE WHEN q.decision_debut IS NOT NULL
              THEN greatest(0, coalesce(pg_catalog.floor(extract(epoch FROM
                     (q.decision_fin - q.decision_debut)) / 60)::bigint, 0))
              ELSE coalesce(private.pai_minutes_enseignant(s.id), 0)::bigint END,
         private.pai_eleves_presents(s.id),
         (SELECT count(DISTINCT sp.profile_id)::integer FROM public.session_participants sp
           WHERE sp.session_id = s.id AND sp.role = 'student' AND sp.deleted_at IS NULL),
         CASE WHEN m.id IS NOT NULL AND NOT c.couvert THEN NULL ELSE m.montant_minor END,
         m.devise,
         (m.id IS NULL AND EXISTS (
            SELECT 1 FROM public.tresorerie_a_reprendre a
             WHERE a.source_type = 'prestation' AND a.source_id = s.id::text AND a.traite_le IS NULL))
         OR (m.id IS NOT NULL AND NOT c.couvert)
    FROM public.sessions s
    LEFT JOIN public.tresorerie_mouvements m
      ON m.source_type = 'prestation' AND m.source_id = s.id::text
     AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree'
    LEFT JOIN LATERAL (
      SELECT a.decision_debut, a.decision_fin FROM public.tresorerie_a_reprendre a
       WHERE a.source_type = 'prestation' AND a.source_id = s.id::text
         AND a.raison = 'duree_indeterminee' AND a.decision_debut IS NOT NULL
       ORDER BY a.id DESC LIMIT 1) q ON true
    CROSS JOIN LATERAL (SELECT private.cahier_semaine_couvert(s.id) AS couvert) c
   WHERE s.groupe_id IS NOT NULL AND s.deleted_at IS NULL
     AND s.status IN ('ended', 'tech_failure')
     AND CASE WHEN m.id IS NOT NULL THEN m.survenu_le >= p_debut AND m.survenu_le < p_fin
              ELSE coalesce(s.finance_ended_at, s.ended_at) >= p_debut
               AND coalesce(s.finance_ended_at, s.ended_at) < p_fin END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Droits et commentaires
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.cahier_semaine_couvert(uuid)'::pg_catalog.regprocedure,
    'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;

  v_oid := 'public.cahier_semaine_depose(uuid)'::pg_catalog.regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM anon', v_oid);
  END IF;
  -- Memes lecteurs que la vue qui l'appelle.
  FOREACH v_role IN ARRAY ARRAY['authenticated', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO %I', v_oid, v_role);
    END IF;
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.cahier_semaine_couvert(uuid) IS
  'CAHIER-HEBDOMADAIRE (31/10/2026) : vrai quand la seance a son propre cahier, ou quand chaque eleve de la seance figure (content.eleves[].student_id) dans un cahier non supprime d''une seance de la meme Classe, la meme semaine (lundi-dimanche, fuseau groupes.timezone_iana). Seance sans Classe : son propre cahier. Source unique. Privee.';
COMMENT ON FUNCTION public.cahier_semaine_depose(uuid) IS
  'CAHIER-HEBDOMADAIRE (31/10/2026) : lecture de private.cahier_semaine_couvert pour mes_seances_enseignant_v. Garde : compte valide, enseignant de la seance ou direction. Lecture seule.';
COMMENT ON FUNCTION public.mes_rapports_en_attente() IS
  'ENS-02, CAHIER-HEBDOMADAIRE (31/10/2026) : les cahiers a remplir de l''enseignant connecte, une ligne par Classe et par semaine dont un eleve ne figure dans aucun cahier (private.cahier_semaine_couvert), la plus ancienne d''abord. Disparait d''elle-meme une fois le cahier depose.';
COMMENT ON VIEW public.mes_seances_enseignant_v IS
  'ENS-02 : les seances de l''enseignant connecte, une ligne par seance et non par eleve. Ne porte aucun prenom : le roster se lit par teacher_roster_v, qui applique deja le masquage d''observation. CAHIER-HEBDOMADAIRE (31/10/2026) : cahier_semaine_depose, la semaine de la Classe est couverte pour les eleves de la seance.';
COMMENT ON FUNCTION private.pai_releve_seances(timestamptz, timestamptz) IS
  'B2.5, PAIE-REMPLACANT, CAHIER-HEBDOMADAIRE (31/10/2026) : seances de Classe du mois (paie ecrite ou fin dans le mois), enseignant effectif ; en_attente si la direction doit decider la duree ou si le cahier de la semaine manque (montant nul tant qu''il manque). Privee.';

-- ---------------------------------------------------------------------------
-- 6. Verifications
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.cahier_semaine_couvert(uuid)'::pg_catalog.regprocedure,
    'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAHIER-HEBDOMADAIRE : aide privee % exposee ou mal declaree', v_oid;
    END IF;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated',
           'public.cahier_semaine_depose(uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
           'public.cahier_semaine_depose(uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
           'public.mes_rapports_en_attente()'::pg_catalog.regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
           'public.mes_rapports_en_attente()'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'CAHIER-HEBDOMADAIRE : droits invalides';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.mes_seances_enseignant_v'::pg_catalog.regclass
                    AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']) THEN
    RAISE EXCEPTION 'CAHIER-HEBDOMADAIRE : mes_seances_enseignant_v a perdu security_barrier';
  END IF;
END;
$postflight$;

COMMIT;
