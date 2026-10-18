-- FAC-E-02 (18/10/2026) : la paie de l'enseignant par eleve present et par
-- heure (docs/current/DECISION-TARIFS-2026-10-18.md, document du directeur,
-- section « Remuneration des enseignants »).
--
-- * Une politique qui porte un taux par eleve present (v2.0.0 et suivantes)
--   paie chaque seance de classe terminee : taux du public de la classe
--   (enfant 0,95 $, adulte 1,00 $) x eleves presents x heures de la seance.
-- * Eleve present : un eleve de la seance avec au moins une arrivee mesuree par
--   la salle (`session_events`, evenement `joined`), ou dont la presence a ete
--   corrigee a la main par la direction (`corrigee_manuel`) ; une absence
--   excusee (`excusee`) n'est pas payee (regle par defaut du document : un
--   absent n'est jamais paye). Jamais une declaration de l'enseignant.
-- * Heures : la duree prevue de la seance, pauses et prieres comprises, quand
--   l'enseignant a tenu au moins la duree due (45 min enfant, 70 min adulte) ;
--   en dessous, les minutes effectivement tenues. Duree inconnue : la seance
--   part a la direction (file de reprise `duree_indeterminee`), comme avant.
-- * Une seance sans eleve present ne paie rien et n'ecrit rien.
-- * La seance ecrit sa paie due dans `paie_a_decaisser` (lue par
--   `mes_revenus_enseignant`) et sa contrepartie dans `fonds_clients_engages`.
--   Le reste de l'encaisse se repartit au niveau des factures, pas ici.
-- * Une politique sans ce taux (v1.0.0) garde le calcul X2-17 tel quel, par la
--   fonction renommee `private.x217_remuneration_horaire`.
-- * `mes_revenus_enseignant` : sous une politique par eleve present, la regle
--   rendue est la fourchette de paie horaire d'une classe (classe ouverte au
--   minimum, classe pleine), et le taux effectif n'est plus borne par l'ancien
--   taux horaire.
BEGIN;

ALTER FUNCTION public.remuneration_due_seance(uuid) RENAME TO x217_remuneration_horaire;
ALTER FUNCTION public.x217_remuneration_horaire(uuid) SET SCHEMA private;

-- Les eleves presents d'une seance (voir l'en-tete).
CREATE FUNCTION private.pai_eleves_presents(p_seance uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT count(DISTINCT sp.profile_id)::integer
    FROM public.session_participants sp
    LEFT JOIN public.session_presence_override o
      ON o.session_id = sp.session_id AND o.profile_id = sp.profile_id
   WHERE sp.session_id = p_seance AND sp.role = 'student' AND sp.deleted_at IS NULL
     AND (o.etat IS NULL OR o.etat <> 'excusee')
     AND (o.etat = 'corrigee_manuel'
          OR EXISTS (SELECT 1 FROM public.session_events e
                      WHERE e.session_id = sp.session_id AND e.profile_id = sp.profile_id
                        AND e.event_type = 'joined'));
$function$;

-- La paie d'une seance sous une politique par eleve present. Rend le montant
-- du (0 sans eleve present), ou nul si la seance attend la direction.
CREATE FUNCTION private.pai_due_seance(p_seance uuid, p public.politiques_commerciales)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions;
  v_public text;
  v_taux bigint;
  v_duree_due integer;
  v_prevues numeric;
  v_tenues numeric;
  v_payees numeric;
  v_presents integer;
  v_due bigint;
  v_ref bigint;
  v_debut timestamptz;
  v_fin timestamptz;
  v_montant bigint;
  v_devise text;
  v_decide boolean;
  v_transfert uuid := pg_catalog.gen_random_uuid();
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance FOR UPDATE;
  IF NOT FOUND OR v_s.status NOT IN ('ended', 'tech_failure') THEN
    RETURN NULL;
  END IF;
  SELECT q.decision_debut, q.decision_fin, q.decision_montant_minor, q.decision_devise
    INTO v_debut, v_fin, v_montant, v_devise
    FROM public.tresorerie_a_reprendre q
   WHERE q.source_type = 'prestation' AND q.source_id = p_seance::text
     AND q.raison = 'duree_indeterminee' AND q.traite_le IS NULL
     AND (q.decision_debut IS NOT NULL OR q.decision_montant_minor IS NOT NULL)
   ORDER BY q.id DESC LIMIT 1;
  v_decide := v_debut IS NOT NULL;
  IF NOT v_decide THEN
    v_debut := v_s.finance_started_at;
    v_fin := v_s.finance_ended_at;
  END IF;

  IF v_montant IS NOT NULL THEN
    IF v_devise IS DISTINCT FROM p.devise OR v_montant < 0 THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'montant_invalide');
      RETURN NULL;
    END IF;
    v_due := v_montant;
  ELSE
    IF (v_s.status = 'tech_failure' AND NOT v_decide)
       OR v_debut IS NULL OR v_fin IS NULL OR v_fin <= v_debut THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'duree_indeterminee');
      RETURN NULL;
    END IF;
    SELECT g.type_public INTO v_public FROM public.groupes g WHERE g.id = v_s.groupe_id;
    v_taux := CASE v_public WHEN 'adulte' THEN p.taux_eleve_heure_adulte_mineur
                            ELSE p.taux_eleve_heure_enfant_mineur END;
    v_duree_due := CASE v_public WHEN 'adulte' THEN p.duree_due_adulte_minutes
                                 ELSE p.duree_due_enfant_minutes END;
    IF v_taux IS NULL THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'regle_remuneration_absente');
      RETURN NULL;
    END IF;
    v_prevues := extract(epoch FROM (v_s.ended_at - v_s.started_at)) / 60;
    v_tenues := extract(epoch FROM (v_fin - v_debut)) / 60;
    v_payees := CASE WHEN v_duree_due IS NULL OR v_tenues >= v_duree_due THEN v_prevues
                     ELSE least(v_tenues, v_prevues) END;
    v_presents := private.pai_eleves_presents(p_seance);
    v_due := pg_catalog.round(v_taux * v_presents * v_payees / 60)::bigint;
  END IF;

  IF v_due = 0 THEN
    RETURN 0;
  END IF;
  v_fin := coalesce(v_fin, v_s.finance_ended_at, v_s.ended_at);
  v_ref := public.x217_montant_ref(v_due, p.devise, v_fin);
  IF v_ref IS NULL OR v_ref <= 0 THEN
    PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'taux_change_absent');
    RETURN NULL;
  END IF;
  INSERT INTO public.tresorerie_mouvements (coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref,
      survenu_le, transfert_id, source_type, regle, source_id)
  VALUES ('fonds_clients_engages', 'sortie', v_due, p.devise, v_ref, 'USD', v_fin,
          v_transfert, 'prestation', 'session_debit', p_seance::text),
         ('paie_a_decaisser', 'entree', v_due, p.devise, v_ref, 'USD', v_fin,
          v_transfert, 'prestation', 'remuneration_due', p_seance::text)
  ON CONFLICT (source_type, source_id, regle, coffre, sens) DO NOTHING;
  RETURN v_due;
END;
$function$;

-- Le point d'entree appele a la cloture d'une seance et par la reprise de la
-- direction (meme nom, meme contrat qu'X2-17).
CREATE FUNCTION public.remuneration_due_seance(p_seance uuid)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions;
  v_zone text := private.bf1_fuseau_comptable();
  p public.politiques_commerciales;
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  p := private.fac_politique_au((coalesce(v_s.finance_started_at, v_s.started_at) AT TIME ZONE v_zone)::date);
  IF v_s.groupe_id IS NOT NULL AND p.version IS NOT NULL
     AND (p.taux_eleve_heure_enfant_mineur IS NOT NULL OR p.taux_eleve_heure_adulte_mineur IS NOT NULL) THEN
    RETURN private.pai_due_seance(p_seance, p);
  END IF;
  RETURN private.x217_remuneration_horaire(p_seance);
END;
$function$;

CREATE OR REPLACE FUNCTION public.mes_revenus_enseignant(p_mois date DEFAULT NULL)
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
  v_pol public.politiques_commerciales;
  v_par_eleve boolean;
  v_devises integer;
  v_devise text;
  v_classes jsonb;
  v_minutes bigint;
  v_capacite bigint;
  v_sieges bigint;
  v_total bigint;
  v_moyen bigint;
  v_base bigint;
  v_plafond bigint;
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

  v_pol := private.fac_politique_au(v_mois);
  v_par_eleve := v_pol.version IS NOT NULL
    AND v_pol.taux_eleve_heure_enfant_mineur IS NOT NULL AND v_pol.taux_eleve_heure_adulte_mineur IS NOT NULL;
  IF v_par_eleve THEN
    v_base := least(v_pol.taux_eleve_heure_enfant_mineur, v_pol.taux_eleve_heure_adulte_mineur)
              * v_pol.minimum_ouverture;
    v_plafond := greatest(v_pol.taux_eleve_heure_enfant_mineur * v_pol.capacite_enfant,
                          v_pol.taux_eleve_heure_adulte_mineur * v_pol.capacite_adulte);
  ELSE
    SELECT r.* INTO v_regle FROM public.regles_remuneration_enseignant r
     WHERE r.date_effet < (v_mois + interval '1 month')::date
       AND (r.enseignant_id = v_uid OR r.enseignant_id IS NULL)
     ORDER BY (r.enseignant_id IS NOT NULL) DESC, r.date_effet DESC, r.cree_le DESC
     LIMIT 1;
  END IF;

  SELECT count(DISTINCT p.devise), min(p.devise) INTO v_devises, v_devise
    FROM private.bf1_prestations(v_uid, v_debut, v_fin) p;
  IF v_devises > 1
     OR (v_devises = 1 AND NOT v_par_eleve AND v_regle.id IS NOT NULL AND v_devise <> v_regle.devise)
     OR (v_devises = 1 AND v_par_eleve AND v_devise <> v_pol.devise) THEN
    RAISE EXCEPTION 'revenus en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_devise := coalesce(v_devise, CASE WHEN v_par_eleve THEN v_pol.devise ELSE v_regle.devise END);

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
    'regle', CASE WHEN v_par_eleve THEN pg_catalog.jsonb_build_object(
                    'base', private.bf1_montant(v_base, v_pol.devise),
                    'plafond', private.bf1_montant(v_plafond, v_pol.devise))
                  WHEN v_regle.id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
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

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.x217_remuneration_horaire(uuid)'::regprocedure,
    'private.pai_eleves_presents(uuid)'::regprocedure,
    'private.pai_due_seance(uuid,public.politiques_commerciales)'::regprocedure,
    'public.remuneration_due_seance(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  COMMENT ON FUNCTION public.mes_revenus_enseignant(date) IS
    'BF1-01, FAC-E-02 : revenus estimes de l''enseignant connecte (FI-BR-11), lus dans tresorerie_mouvements (remuneration_due) ; sous une politique par eleve present, la regle est la fourchette de paie horaire d''une classe. Garde: teacher + compte valide; perimetre auth.uid(). DEFINER: tresorerie fermee a l''enseignant. date=2026-10-18.';
END;
$droits$;

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated', 'public.remuneration_due_seance(uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.remuneration_due_seance(uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.pai_due_seance(uuid,public.politiques_commerciales)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.x217_remuneration_horaire(uuid)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'FAC-E-02 : le calcul de la paie doit rester au serveur';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.mes_revenus_enseignant(date)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.mes_revenus_enseignant(date)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'FAC-E-02 : droits de mes_revenus_enseignant invalides';
  END IF;
END;
$postflight$;

COMMIT;
