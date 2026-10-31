-- PAIE-REMPLACANT (02/11/2026) : la paie d'une seance va a l'enseignant qui
-- l'a reellement assuree.
--
-- DELETE / DROP / TRUNCATE : 0. Uniquement CREATE OR REPLACE de trois
-- fonctions, puis droits, commentaires et verifications.
--
-- Regle du directeur, en vigueur depuis le debut du projet (systeme des
-- astreintes, dossier maitre du 14/10/2026, ligne 7644 : « Paie seance
-- affectee au remplacant ») : quand un enseignant ne vient pas et qu'un autre
-- le remplace, la paie de cette seance va au remplacant. Jamais de double paie.
--
-- Le defaut corrige : `sessions.teacher_id` reste le titulaire (C-29, voulu),
-- mais les lectures de la paie s'appuyaient sur ce champ. Un remplacant ne
-- voyait pas sa paie, et le titulaire la voyait a sa place.
--
-- La source de l'enseignant effectif existe deja et est reutilisee telle
-- quelle : `private.c29_enseignant_effectif_session(uuid)` (migration
-- 20261011200002), lue dans le flux B-09 `remplacements_seance` (dernier
-- evenement `remplacement_pris` ou `remplacement_designe_admin` : le
-- remplacant ; sinon le titulaire). `private.salle_enseignant_effectif`
-- (20261102100000) n'en est qu'une enveloppe pour la salle : pas un second
-- calcul, rien a fusionner ici.
--
-- Le montant ne change pas : il est ecrit une fois par seance dans
-- `tresorerie_mouvements` (regle `remuneration_due`, sans colonne
-- d'enseignant) par `private.pai_due_seance`, qui lit le taux selon le public
-- de la classe, les eleves presents et la duree, jamais selon l'enseignant.
-- Seul change QUI le lit. Une seance a un seul enseignant effectif : le
-- total du mois est identique, la seance passe d'une ligne a l'autre.
--
-- Fonctions remplacees (corps identiques, seul le filtre ou la colonne de
-- l'enseignant change) :
--   - private.pai_releve_seances : colonne `enseignant` = enseignant
--     effectif ; `releve_paie_mensuel` et `releve_paie_seances(p_mois,
--     p_enseignant)` la lisent sans changer de texte (le detail filtre donc
--     sur l'enseignant effectif) ;
--   - private.bf1_prestations : seances de l'enseignant effectif, lues par
--     `mes_revenus_enseignant` ;
--   - public.mes_revenus_mois_disponibles : meme filtre.
BEGIN;

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
         greatest(0, coalesce(pg_catalog.floor(extract(epoch FROM
           (coalesce(q.decision_fin, s.finance_ended_at)
            - coalesce(q.decision_debut, s.finance_started_at))) / 60)::bigint, 0)),
         private.pai_eleves_presents(s.id),
         (SELECT count(DISTINCT sp.profile_id)::integer FROM public.session_participants sp
           WHERE sp.session_id = s.id AND sp.role = 'student' AND sp.deleted_at IS NULL),
         m.montant_minor, m.devise,
         (m.id IS NULL AND EXISTS (
            SELECT 1 FROM public.tresorerie_a_reprendre a
             WHERE a.source_type = 'prestation' AND a.source_id = s.id::text AND a.traite_le IS NULL))
    FROM public.sessions s
    LEFT JOIN public.tresorerie_mouvements m
      ON m.source_type = 'prestation' AND m.source_id = s.id::text
     AND m.regle = 'remuneration_due' AND m.coffre = 'paie_a_decaisser' AND m.sens = 'entree'
    LEFT JOIN LATERAL (
      SELECT a.decision_debut, a.decision_fin FROM public.tresorerie_a_reprendre a
       WHERE a.source_type = 'prestation' AND a.source_id = s.id::text
         AND a.raison = 'duree_indeterminee' AND a.decision_debut IS NOT NULL
       ORDER BY a.id DESC LIMIT 1) q ON true
   WHERE s.groupe_id IS NOT NULL AND s.deleted_at IS NULL
     AND s.status IN ('ended', 'tech_failure')
     AND CASE WHEN m.id IS NOT NULL THEN m.survenu_le >= p_debut AND m.survenu_le < p_fin
              ELSE coalesce(s.finance_ended_at, s.ended_at) >= p_debut
               AND coalesce(s.finance_ended_at, s.ended_at) < p_fin END;
$function$;

CREATE OR REPLACE FUNCTION private.bf1_prestations(p_uid uuid, p_debut timestamptz, p_fin timestamptz)
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
   WHERE s.groupe_id IS NOT NULL
     AND m.survenu_le >= p_debut AND m.survenu_le < p_fin
     AND coalesce(private.c29_enseignant_effectif_session(s.id), s.teacher_id) = p_uid;
$function$;

CREATE OR REPLACE FUNCTION public.mes_revenus_mois_disponibles()
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
           WHERE s.groupe_id IS NOT NULL
             AND coalesce(private.c29_enseignant_effectif_session(s.id), s.teacher_id) = v_uid
        ) y ORDER BY y.mois DESC LIMIT 24
      ) x);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Droits (CREATE OR REPLACE garde proprietaire et ACL ; on les repose quand
-- meme, a l'identique des migrations d'origine)
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure,
    'private.bf1_prestations(uuid,timestamptz,timestamptz)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;

  v_oid := 'public.mes_revenus_mois_disponibles()'::pg_catalog.regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
    END IF;
  END LOOP;
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  COMMENT ON FUNCTION public.mes_revenus_mois_disponibles() IS
    'BF1-01, PAIE-REMPLACANT : mois rendables des revenus de l''enseignant connecte, seances dont il est l''enseignant effectif (C-29, remplacements B-09). Garde: teacher + compte valide. date=2026-11-02.';
  COMMENT ON FUNCTION public.mes_revenus_enseignant(date) IS
    'BF1-01, FAC-E-02, PAIE-REMPLACANT : revenus estimes de l''enseignant connecte (FI-BR-11), lus dans tresorerie_mouvements (remuneration_due) pour les seances dont il est l''enseignant effectif (C-29 : le remplacant, pas le titulaire) ; sous une politique par eleve present, la regle est la fourchette de paie horaire d''une classe. Garde: teacher + compte valide; perimetre auth.uid(). DEFINER: tresorerie fermee a l''enseignant. date=2026-11-02.';

  -- Le commentaire F86 des deux lectures de la direction, recalcule : leur
  -- texte ne change pas, leur source (`pai_releve_seances`) si.
  FOREACH v_oid IN ARRAY ARRAY[
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-02. B2.5, PAIE-REMPLACANT : releve mensuel de la paie des enseignants, lu dans tresorerie_mouvements (remuneration_due), chaque seance attribuee a l''enseignant effectif (C-29 : le remplacant, pas le titulaire) ; garde: admin ou accountant + compte valide ; lecture seule.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  -- Les aides privees : DEFINER, search_path vide, STABLE, fermees aux clients.
  FOREACH v_oid IN ARRAY ARRAY[
    'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure,
    'private.bf1_prestations(uuid,timestamptz,timestamptz)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PAIE-REMPLACANT : aide privee % exposee ou mal declaree', v_oid;
    END IF;
  END LOOP;
  -- Les lectures publiques : DEFINER, STABLE, authenticated seul.
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_revenus_mois_disponibles()'::pg_catalog.regprocedure,
    'public.mes_revenus_enseignant(date)'::pg_catalog.regprocedure,
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'PAIE-REMPLACANT : DEFINER, volatilite ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  -- La source de l'enseignant effectif reste fermee aux clients.
  IF pg_catalog.has_function_privilege('authenticated',
       'private.c29_enseignant_effectif_session(uuid)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PAIE-REMPLACANT : c29_enseignant_effectif_session exposee';
  END IF;
END;
$postflight$;

COMMIT;
