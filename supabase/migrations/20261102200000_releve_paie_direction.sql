-- B2.5 PAIE-DIRECTION (02/11/2026) : le releve mensuel de la paie des
-- enseignants, lu par la direction et la comptabilite (constat du pilote du
-- 30/10/2026, `docs/current/PLAN-LOTS-BOUCLES-2-4-2026-10-30.md` : la vue de
-- la paie par la direction rendait `CapaciteIndisponible`).
--
-- Lecture seule : rien n'est ecrit, aucun paiement, aucune cloture de mois.
--
-- Le montant n'est PAS recalcule ici. Il est celui que la tresorerie a deja
-- ecrit a la cloture de chaque seance (`remuneration_due_seance`, migration
-- 20261018130000, regle `remuneration_due` dans `paie_a_decaisser`) : taux du
-- public de la classe lu dans la politique commerciale en vigueur x eleves
-- presents x heures (`private.pai_due_seance`). Le releve et la vue de
-- l'enseignant (`mes_revenus_enseignant`) lisent donc la meme source et ne
-- peuvent pas diverger. Aucun taux, prix ni pourcentage n'est ecrit ici.
--
-- Perimetre d'une seance comptee dans le mois (fuseau comptable) :
--   - seance de Classe (`groupe_id` non nul), non supprimee, terminee
--     (`ended`) ou en panne technique (`tech_failure`) ; une seance annulee
--     n'est jamais comptee ;
--   - payee : date de l'ecriture de paie dans le mois ; non payee : fin de
--     la seance dans le mois.
-- Une seance terminee sans ecriture de paie est soit sans eleve present
-- (paie nulle), soit en attente de la direction (`tresorerie_a_reprendre`
-- non traitee : duree inconnue, panne) : `enAttente` la distingue.
--
-- L'enseignant paye est celui de la seance (`sessions.teacher_id`), comme
-- dans la regle existante : un remplacement (B-09, `remplacements_seance`)
-- ne change pas aujourd'hui le beneficiaire de la paie.
--
-- Deux lectures :
--   - `releve_paie_mensuel(p_mois)` : une ligne par enseignant (prenom, nom,
--     seances tenues, seances en attente, minutes, eleves presents x minutes,
--     montant du, Classes) et le total ;
--   - `releve_paie_seances(p_mois, p_enseignant)` : le detail par seance.
BEGIN;

-- Les seances du releve sur [p_debut, p_fin[, une ligne par seance.
CREATE FUNCTION private.pai_releve_seances(p_debut timestamptz, p_fin timestamptz)
RETURNS TABLE (seance uuid, enseignant uuid, groupe uuid, debut timestamptz, minutes bigint,
               presents integer, inscrits integer, montant bigint, devise text, en_attente boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT s.id, s.teacher_id, s.groupe_id, s.started_at,
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

-- La porte commune : direction ou comptabilite, compte valide.
CREATE FUNCTION private.pai_releve_autorise()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_role() IN ('admin', 'accountant')
                  AND public.app_account_valid(), false);
$function$;

-- Le releve du mois `p_mois` (premier jour ; nul = mois en cours du fuseau
-- comptable). Rend {debut, fin, devise, enseignants: [...], total}.
CREATE FUNCTION public.releve_paie_mensuel(p_mois date DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_devise text;
  v_devises integer;
  v_enseignants jsonb;
  v_total bigint;
BEGIN
  IF NOT private.pai_releve_autorise() THEN
    RAISE EXCEPTION 'releve de paie reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month',
    coalesce(p_mois, (pg_catalog.now() AT TIME ZONE v_zone)::date))::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;

  SELECT count(DISTINCT r.devise), min(r.devise) INTO v_devises, v_devise
    FROM private.pai_releve_seances(v_debut, v_fin) r WHERE r.devise IS NOT NULL;
  IF v_devises > 1 THEN
    RAISE EXCEPTION 'releve de paie en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, (private.fac_politique_au(v_mois)).devise);

  WITH r AS (SELECT * FROM private.pai_releve_seances(v_debut, v_fin)),
  par_enseignant AS (
    SELECT r.enseignant,
           count(*) FILTER (WHERE NOT r.en_attente)::integer AS tenues,
           count(*) FILTER (WHERE r.en_attente)::integer AS en_attente,
           coalesce(sum(r.minutes) FILTER (WHERE NOT r.en_attente), 0)::bigint AS minutes,
           coalesce(sum(r.minutes * r.presents) FILTER (WHERE NOT r.en_attente), 0)::bigint AS minutes_eleves,
           coalesce(sum(r.montant), 0)::bigint AS montant,
           pg_catalog.array_agg(DISTINCT r.groupe) AS groupes
      FROM r GROUP BY r.enseignant
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'enseignantId', e.enseignant,
           'prenom', p.first_name, 'nom', p.last_name,
           'seancesTenues', e.tenues, 'seancesEnAttente', e.en_attente,
           'minutes', e.minutes, 'minutesEleves', e.minutes_eleves,
           'montant', private.bf1_montant(e.montant, v_devise),
           'classes', (SELECT coalesce(pg_catalog.jsonb_agg(g.libelle ORDER BY g.libelle), '[]'::jsonb)
                         FROM public.groupes g WHERE g.id = ANY (e.groupes)))
           ORDER BY p.last_name, p.first_name, e.enseignant), '[]'::jsonb),
         coalesce(sum(e.montant), 0)
    INTO v_enseignants, v_total
    FROM par_enseignant e
    JOIN public.profiles p ON p.id = e.enseignant;

  RETURN pg_catalog.jsonb_build_object(
    'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((v_mois + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'),
    'devise', v_devise,
    'enseignants', v_enseignants,
    'total', private.bf1_montant(v_total, v_devise));
END;
$function$;

-- Le detail par seance d'un enseignant pour le mois `p_mois`. Rend {debut,
-- fin, devise, enseignant: {enseignantId, prenom, nom}, seances: [...],
-- total}. Un enseignant sans seance dans le mois rend une liste vide.
CREATE FUNCTION public.releve_paie_seances(p_mois date, p_enseignant uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_zone text;
  v_mois date;
  v_debut timestamptz;
  v_fin timestamptz;
  v_devise text;
  v_devises integer;
  v_prof public.profiles;
  v_seances jsonb;
  v_total bigint;
BEGIN
  IF NOT private.pai_releve_autorise() THEN
    RAISE EXCEPTION 'releve de paie reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_mois IS NULL OR p_enseignant IS NULL THEN
    RAISE EXCEPTION 'mois et enseignant requis' USING ERRCODE = '22023';
  END IF;
  SELECT p.* INTO v_prof FROM public.profiles p WHERE p.id = p_enseignant;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'enseignant inconnu' USING ERRCODE = 'P0002';
  END IF;

  v_zone := private.bf1_fuseau_comptable();
  v_mois := pg_catalog.date_trunc('month', p_mois)::date;
  v_debut := v_mois::timestamp AT TIME ZONE v_zone;
  v_fin := (v_mois + interval '1 month')::timestamp AT TIME ZONE v_zone;

  SELECT count(DISTINCT r.devise), min(r.devise) INTO v_devises, v_devise
    FROM private.pai_releve_seances(v_debut, v_fin) r
   WHERE r.enseignant = p_enseignant AND r.devise IS NOT NULL;
  IF v_devises > 1 THEN
    RAISE EXCEPTION 'releve de paie en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, (private.fac_politique_au(v_mois)).devise);

  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'seanceId', r.seance, 'classeId', r.groupe, 'classe', g.libelle,
           'debut', r.debut, 'minutes', r.minutes,
           'elevesPresents', r.presents, 'elevesInscrits', r.inscrits,
           'montant', CASE WHEN r.en_attente THEN NULL
                           ELSE private.bf1_montant(coalesce(r.montant, 0), v_devise) END,
           'enAttente', r.en_attente)
           ORDER BY r.debut, r.seance), '[]'::jsonb),
         coalesce(sum(r.montant), 0)
    INTO v_seances, v_total
    FROM private.pai_releve_seances(v_debut, v_fin) r
    JOIN public.groupes g ON g.id = r.groupe
   WHERE r.enseignant = p_enseignant;

  RETURN pg_catalog.jsonb_build_object(
    'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
    'fin', pg_catalog.to_char((v_mois + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'),
    'devise', v_devise,
    'enseignant', pg_catalog.jsonb_build_object(
      'enseignantId', v_prof.id, 'prenom', v_prof.first_name, 'nom', v_prof.last_name),
    'seances', v_seances,
    'total', private.bf1_montant(v_total, v_devise));
END;
$function$;

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure,
    'private.pai_releve_autorise()'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
    FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
      IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
        EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
      END IF;
    END LOOP;
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-02. B2.5 : releve mensuel de la paie des enseignants, lu dans tresorerie_mouvements (remuneration_due) ; garde: admin ou accountant + compte valide ; lecture seule.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.releve_paie_mensuel(date)'::pg_catalog.regprocedure,
    'public.releve_paie_seances(date,uuid)'::pg_catalog.regprocedure] LOOP
    IF (SELECT p.provolatile FROM pg_catalog.pg_proc p WHERE p.oid = v_oid) <> 's' THEN
      RAISE EXCEPTION '% doit etre STABLE (aucune ecriture)', v_oid;
    END IF;
    IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'droits de % invalides', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'private.pai_releve_seances(timestamptz,timestamptz)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'B2.5 : la lecture brute des seances doit rester au serveur';
  END IF;
END;
$postflight$;

COMMIT;
