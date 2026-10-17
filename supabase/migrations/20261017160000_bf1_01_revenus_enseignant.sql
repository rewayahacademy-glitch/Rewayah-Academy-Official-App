-- BF1-01 (17/10/2026) : les revenus de l'enseignant connecte, en lecture seule
-- (contrat lib/core/capacites/port_revenus_enseignant.dart, FI-BR-11).
--
-- Source de verite : les ecritures `tresorerie_mouvements` deja arretees par
-- `remuneration_due_seance` (X2-17) : source_type 'prestation', regle
-- 'remuneration_due', coffre 'paie_a_decaisser', sens 'entree', source_id =
-- l'identifiant de la seance. Rien n'est recalcule ici a partir d'un taux : le
-- montant est celui que la tresorerie a ecrit. Les minutes sont la duree
-- financiere de la seance (horodatages `finance_started_at` / `finance_ended_at`,
-- ou la decision de reprise de la direction quand elle existe, comme le fait
-- remuneration_due_seance).
--
-- Ce que la RPC ne rend PAS, faute de donnees serveur :
-- * aucune aide Internet (`allocationInternet` toujours nul) ;
-- * aucune base garantie ni plafond distincts : la politique en vigueur est un
--   taux horaire unique (`regles_remuneration_enseignant`), rendu comme base ET
--   comme plafond ; sans regle applicable, `regle` est nul et l'adaptateur dit
--   la capacite indisponible ;
-- * aucun releve « arrete » : aucune cloture mensuelle n'existe cote serveur,
--   l'adaptateur garde `releve()` indisponible ;
-- * les seances sans classe (`sessions.groupe_id` nul, ancien 1 a 1) ne sont
--   pas rendues : la vue est par classe.
--
-- Les sieges eligibles sont les eleves distincts inscrits aux seances payees de
-- la classe sur le mois, jamais au-dela de la capacite.
--
-- Droits : SECURITY DEFINER (la tresorerie est fermee a l'enseignant), garde
-- positive role teacher + compte valide, perimetre auth.uid() seul ; STABLE ;
-- EXECUTE retire a PUBLIC, anon, service_role, agent_ro, accorde a
-- authenticated.
BEGIN;

CREATE FUNCTION private.bf1_fuseau_comptable()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT c.value #>> '{}' FROM public.app_config c WHERE c.key = 'fuseau_comptable'),
    'Europe/Paris');
$function$;

CREATE FUNCTION private.bf1_montant(p_mineur bigint, p_devise text)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object('mineur', p_mineur, 'devise', p_devise);
$function$;

-- Les remunerations dues des seances de classe de l'enseignant p_uid sur
-- [p_debut, p_fin[ : une ligne par seance, montant ecrit par la tresorerie.
CREATE FUNCTION private.bf1_prestations(p_uid uuid, p_debut timestamptz, p_fin timestamptz)
RETURNS TABLE (seance uuid, groupe uuid, minutes bigint, montant bigint, devise text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT s.id, s.groupe_id,
         greatest(0, coalesce(pg_catalog.floor(extract(epoch FROM
           (coalesce(q.decision_fin, s.finance_ended_at)
            - coalesce(q.decision_debut, s.finance_started_at))) / 60)::bigint, 0)),
         m.montant_minor, m.devise
    FROM public.sessions s
    JOIN public.tresorerie_mouvements m
      ON m.source_type = 'prestation' AND m.source_id = s.id::text
     AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree'
    LEFT JOIN LATERAL (
      SELECT a.decision_debut, a.decision_fin FROM public.tresorerie_a_reprendre a
       WHERE a.source_type = 'prestation' AND a.source_id = s.id::text
         AND a.raison = 'duree_indeterminee' AND a.decision_debut IS NOT NULL
       ORDER BY a.id DESC LIMIT 1) q ON true
   WHERE s.teacher_id = p_uid AND s.groupe_id IS NOT NULL
     AND m.survenu_le >= p_debut AND m.survenu_le < p_fin;
$function$;

-- Les revenus du mois `p_mois` (premier jour ; nul = mois en cours du fuseau
-- comptable). Rend {debut, fin, devise, regle: {base, plafond} | nul, classes,
-- total, totalEstime, allocationInternet: nul}.
CREATE FUNCTION public.mes_revenus_enseignant(p_mois date DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_regle public.regles_remuneration_enseignant%ROWTYPE;
  v_devises integer;
  v_devise text;
  v_classes jsonb;
  v_minutes bigint;
  v_capacite bigint;
  v_sieges bigint;
  v_total bigint;
  v_moyen bigint;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() = 'teacher'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'revenus reserves a l''enseignant connecte' USING ERRCODE = '42501';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month',
    coalesce(p_mois, (pg_catalog.now() AT TIME ZONE v_zone)::date))::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;

  SELECT r.* INTO v_regle FROM public.regles_remuneration_enseignant r
   WHERE r.date_effet < (v_mois + interval '1 month')::date
     AND (r.enseignant_id = v_uid OR r.enseignant_id IS NULL)
   ORDER BY (r.enseignant_id IS NOT NULL) DESC, r.date_effet DESC, r.cree_le DESC
   LIMIT 1;

  SELECT count(DISTINCT p.devise), min(p.devise) INTO v_devises, v_devise
    FROM private.bf1_prestations(v_uid, v_debut, v_fin) p;
  IF v_devises > 1 OR (v_devises = 1 AND v_regle.id IS NOT NULL AND v_devise <> v_regle.devise) THEN
    RAISE EXCEPTION 'revenus en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, v_regle.devise);

  WITH par_classe AS (
    SELECT g.id, g.libelle, g.type_public, g.seuil_max,
           (g.teacher_id IS DISTINCT FROM v_uid) AS remplacement,
           sum(p.minutes)::bigint AS minutes, sum(p.montant)::bigint AS montant,
           least(g.seuil_max::bigint, (
             SELECT count(DISTINCT sp.profile_id) FROM public.session_participants sp
              JOIN private.bf1_prestations(v_uid, v_debut, v_fin) p2 ON p2.seance = sp.session_id
             WHERE p2.groupe = g.id AND sp.role = 'student' AND sp.deleted_at IS NULL)) AS sieges
      FROM private.bf1_prestations(v_uid, v_debut, v_fin) p
      JOIN public.groupes g ON g.id = p.groupe
     GROUP BY g.id, g.libelle, g.type_public, g.seuil_max, g.teacher_id
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'classeId', c.id, 'classe', c.libelle,
           'type', CASE c.type_public WHEN 'adulte' THEN 'adultes' ELSE 'enfants' END,
           'minutesAssurees', c.minutes, 'capacite', c.seuil_max, 'siegesEligibles', c.sieges,
           'tauxHoraireEffectif', private.bf1_montant(
             CASE WHEN c.minutes > 0 THEN least(
               coalesce(v_regle.taux_minor_par_heure, pg_catalog.round(c.montant * 60.0 / c.minutes)::bigint),
               pg_catalog.round(c.montant * 60.0 / c.minutes)::bigint) ELSE 0 END, v_devise),
           'montantEstime', private.bf1_montant(c.montant, v_devise),
           'enRemplacement', c.remplacement)
           ORDER BY c.libelle, c.id), '[]'::jsonb),
         coalesce(sum(c.minutes), 0), coalesce(sum(c.seuil_max), 0),
         coalesce(sum(c.sieges), 0), coalesce(sum(c.montant), 0)
    INTO v_classes, v_minutes, v_capacite, v_sieges, v_total
    FROM par_classe c;

  v_moyen := CASE WHEN v_minutes > 0 THEN least(
    coalesce(v_regle.taux_minor_par_heure, pg_catalog.round(v_total * 60.0 / v_minutes)::bigint),
    pg_catalog.round(v_total * 60.0 / v_minutes)::bigint) ELSE 0 END;

  RETURN pg_catalog.jsonb_build_object(
    'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((v_mois + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'),
    'devise', v_devise,
    'regle', CASE WHEN v_regle.id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
      'base', private.bf1_montant(v_regle.taux_minor_par_heure, v_regle.devise),
      'plafond', private.bf1_montant(v_regle.taux_minor_par_heure, v_regle.devise)) END,
    'classes', v_classes,
    'total', pg_catalog.jsonb_build_object(
      'minutesAssurees', v_minutes, 'capacite', v_capacite, 'siegesEligibles', v_sieges,
      'tauxHoraireMoyen', private.bf1_montant(v_moyen, v_devise)),
    'totalEstime', private.bf1_montant(v_total, v_devise),
    'allocationInternet', NULL);
END;
$function$;

-- Les mois que la source sait rendre, le plus recent d'abord : le mois en
-- cours, puis chaque mois portant une remuneration due de l'enseignant
-- connecte (24 mois au plus).
CREATE FUNCTION public.mes_revenus_mois_disponibles()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_zone text;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() = 'teacher'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'revenus reserves a l''enseignant connecte' USING ERRCODE = '42501';
  END IF;
  v_zone := private.bf1_fuseau_comptable();
  RETURN (
    SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.to_char(x.mois, 'YYYY-MM-DD') ORDER BY x.mois DESC), '[]'::jsonb)
      FROM (
        SELECT DISTINCT y.mois FROM (
          SELECT pg_catalog.date_trunc('month', (pg_catalog.now() AT TIME ZONE v_zone))::date AS mois
          UNION
          SELECT pg_catalog.date_trunc('month', (m.survenu_le AT TIME ZONE v_zone))::date
            FROM public.sessions s
            JOIN public.tresorerie_mouvements m
              ON m.source_type = 'prestation' AND m.source_id = s.id::text
             AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree'
           WHERE s.teacher_id = v_uid AND s.groupe_id IS NOT NULL
        ) y ORDER BY y.mois DESC LIMIT 24
      ) x);
END;
$function$;

ALTER FUNCTION private.bf1_fuseau_comptable() OWNER TO postgres;
ALTER FUNCTION private.bf1_montant(bigint, text) OWNER TO postgres;
ALTER FUNCTION private.bf1_prestations(uuid, timestamptz, timestamptz) OWNER TO postgres;
ALTER FUNCTION public.mes_revenus_enseignant(date) OWNER TO postgres;
ALTER FUNCTION public.mes_revenus_mois_disponibles() OWNER TO postgres;

REVOKE ALL ON FUNCTION private.bf1_fuseau_comptable() FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.bf1_montant(bigint, text) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.bf1_prestations(uuid, timestamptz, timestamptz) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.mes_revenus_enseignant(date) FROM PUBLIC, anon, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.mes_revenus_mois_disponibles() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.mes_revenus_enseignant(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mes_revenus_mois_disponibles() TO authenticated;

COMMENT ON FUNCTION public.mes_revenus_enseignant(date) IS
  'BF1-01: revenus estimes de l''enseignant connecte (FI-BR-11), lus dans tresorerie_mouvements (remuneration_due). Garde: teacher + compte valide; perimetre auth.uid(). DEFINER: tresorerie fermee a l''enseignant. date=2026-10-17.';
COMMENT ON FUNCTION public.mes_revenus_mois_disponibles() IS
  'BF1-01: mois rendables des revenus de l''enseignant connecte. Garde: teacher + compte valide. date=2026-10-17.';

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_revenus_enseignant(date)'::regprocedure,
    'public.mes_revenus_mois_disponibles()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'BF1-01 : DEFINER, volatilite ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.bf1_fuseau_comptable()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.bf1_montant(bigint,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.bf1_prestations(uuid,timestamptz,timestamptz)', 'EXECUTE') THEN
    RAISE EXCEPTION 'BF1-01 : aide privee executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
