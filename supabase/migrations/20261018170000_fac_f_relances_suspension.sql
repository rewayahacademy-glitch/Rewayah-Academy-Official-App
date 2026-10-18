-- FAC-F-01 (18/10/2026) : les relances avant echeance et la suspension pour
-- paiement, que la politique v2 portait sans que rien ne les execute.
--
-- Source : docs/current/DECISION-TARIFS-2026-10-18.md (relances J-7, J-3, J-1 ;
-- renouvellement le 1er ; suspension le 4). Les jours viennent de la politique
-- en vigueur (`jours_relance`, `jour_suspension`), jamais du code.
--
-- * `private.fac_traiter_relances(date)` : idempotente, rejouable le meme jour.
--   - relance : une facture `a_financer` dont l'echeance (premier jour du
--     mois facture) tombe dans `jours_relance` jours recoit une notification
--     pour le tuteur (eleve mineur) ou pour l'eleve adulte lui-meme. Une
--     relance par facture et par jour d'avance (index unique du journal) ;
--   - suspension : au jour de suspension de la politique (et apres, tant que
--     la facture reste impayee), l'acces de l'eleve passe a « suspendu pour
--     paiement ». Pas de suspension si la facture est financee, si une bourse
--     de 100 % couvre le mois, si un paiement attend sa confirmation
--     (validation de la direction FAC-D, credit non confirme, commande Stripe
--     confirmee) ;
--   - retablissement : des que la facture n'est plus a financer (le paiement
--     valide passe par `fac_financer_profil`, appelee par la validation FAC-D
--     et par le webhook Stripe FI-BR-06), l'acces revient tout de suite.
-- * Journal `relances_paiement` : chaque action, une ligne ; plus l'audit
--   chaine (`log_sensitive_access`).
-- * `public.fac_traiter_relances_du_jour()` : la direction (AAL2) la lance a
--   la main. Une planification pg_cron quotidienne est posee SI l'extension
--   existe ; sinon rien n'echoue.
-- * Lecture pour l'application : `mon_acces()` (l'eleve connecte : l'enfant ne
--   lit qu'une ouverture, jamais une cause) et `acces_du_foyer()` (le tuteur,
--   avec le motif).
-- * Le jeton video refuse un eleve suspendu pour paiement.
BEGIN;

-- ---------------------------------------------------------------------------
-- Notifications : trois evenements et la destination « payer ».
-- ---------------------------------------------------------------------------
ALTER TABLE public.notifications DROP CONSTRAINT notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
  'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation',
  'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement'));
ALTER TABLE public.notifications DROP CONSTRAINT notifications_destination_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_destination_check CHECK (destination IN (
  '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
  '/admin/securite-audit/tirages', '/tuteur/foyer/recharge'));

-- ---------------------------------------------------------------------------
-- Tables : suspensions et journal.
-- ---------------------------------------------------------------------------
CREATE TABLE public.acces_suspensions_paiement (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  facture_id uuid NOT NULL REFERENCES public.factures_mensuelles(id),
  jour date NOT NULL,
  suspendu_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  retabli_le timestamptz,
  retabli_motif text CHECK (retabli_motif IN ('paiement', 'facture_close')),
  CHECK ((retabli_le IS NULL) = (retabli_motif IS NULL))
);
CREATE UNIQUE INDEX acces_suspensions_paiement_une_ouverte
  ON public.acces_suspensions_paiement (profile_id) WHERE retabli_le IS NULL;
CREATE INDEX acces_suspensions_paiement_facture ON public.acces_suspensions_paiement (facture_id);
COMMENT ON TABLE public.acces_suspensions_paiement IS
  'FAC-F-01 : acces d''un eleve suspendu pour paiement (une ouverte au plus par eleve). Lecture par RPC seulement ; le compte reste ouvert.';

CREATE TABLE public.relances_paiement (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  facture_id uuid NOT NULL REFERENCES public.factures_mensuelles(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  action text NOT NULL CHECK (action IN ('relance', 'suspension', 'retablissement')),
  jours_avant integer CHECK (jours_avant >= 0),
  jour date NOT NULL,
  destinataires integer NOT NULL DEFAULT 0 CHECK (destinataires >= 0),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CHECK ((action = 'relance') = (jours_avant IS NOT NULL))
);
CREATE UNIQUE INDEX relances_paiement_une_par_jour_avant
  ON public.relances_paiement (facture_id, jours_avant) WHERE action = 'relance';
CREATE INDEX relances_paiement_profil ON public.relances_paiement (profile_id, cree_le DESC);
COMMENT ON TABLE public.relances_paiement IS
  'FAC-F-01 : journal des relances, suspensions et retablissements ; la relance d''une facture a un jour d''avance donne ne se repete jamais.';

DO $tables$
DECLARE
  v_t text;
BEGIN
  FOREACH v_t IN ARRAY ARRAY['acces_suspensions_paiement', 'relances_paiement'] LOOP
    EXECUTE pg_catalog.format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_t);
    EXECUTE pg_catalog.format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_t);
  END LOOP;
END;
$tables$;

-- ---------------------------------------------------------------------------
-- Aides (aucun droit client).
-- ---------------------------------------------------------------------------

-- Les personnes a prevenir pour un eleve : son tuteur (eleve mineur), ou lui-meme
-- (eleve adulte autonome).
CREATE FUNCTION private.fac_destinataires_paiement(p_profil uuid)
RETURNS TABLE (destinataire uuid, foyer uuid)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pr.id, pr.household_id
    FROM public.profiles pr
    JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
   WHERE pr.id = p_profil AND pr.deleted_at IS NULL AND sp.student_type = 'autonomous'
  UNION
  SELECT g.id, g.household_id
    FROM public.profiles pr
    JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
    JOIN public.profiles g ON g.household_id = pr.household_id AND g.role = 'guardian'
                          AND g.deleted_at IS NULL
   WHERE pr.id = p_profil AND pr.deleted_at IS NULL AND pr.household_id IS NOT NULL
     AND sp.student_type = 'minor';
$function$;

-- Vrai quand un paiement du profil attend sa confirmation : validation de la
-- direction en attente (FAC-D), credit non confirme par le prestataire, ou
-- commande de recharge payee et en cours d'attribution (FI-BR-06).
CREATE FUNCTION private.fac_paiement_en_attente(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.finance_validations v
                  WHERE v.objet_id = p_profil AND v.etat = 'en_attente')
      OR EXISTS (SELECT 1 FROM public.wallet_entries e
                  WHERE e.beneficiaire_id = p_profil AND e.reference_type = 'credit'
                    AND e.confirme_par_prestataire_le IS NULL)
      OR EXISTS (SELECT 1 FROM public.commandes_recharge_allocations a
                   JOIN public.commandes_recharge c ON c.id = a.commande_id
                  WHERE a.profile_id = p_profil
                    AND c.etat IN ('confirmed', 'allocation_in_progress'));
$function$;

-- Vrai quand une bourse de 100 % couvre le mois p_mois pour ce profil.
CREATE FUNCTION private.fac_bourse_couvre(p_profil uuid, p_mois date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.bourses_eleves b
                  WHERE b.profile_id = p_profil AND b.retiree_le IS NULL
                    AND b.pour_mille >= 1000
                    AND b.mois_debut <= p_mois AND b.mois_fin >= p_mois);
$function$;

-- Vrai quand l'eleve est suspendu pour paiement.
CREATE FUNCTION private.fac_eleve_suspendu(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.acces_suspensions_paiement s
                  WHERE s.profile_id = p_profil AND s.retabli_le IS NULL);
$function$;

-- Prevenir les personnes concernees ; rend leur nombre.
CREATE FUNCTION private.fac_notifier_paiement(
  p_profil uuid, p_evenement text, p_params jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT d.destinataire, d.foyer, p_evenement, p_params, '/tuteur/foyer/recharge'
    FROM private.fac_destinataires_paiement(p_profil) d;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- Rend l'acces a l'eleve si la facture qui l'avait suspendu n'est plus a
-- financer (payee, financee par une bourse ou annulee). Rend vrai quand
-- l'acces est retabli.
CREATE FUNCTION private.fac_retablir_acces(p_profil uuid, p_jour date)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  s public.acces_suspensions_paiement;
  v_statut text;
  v_motif text;
  v_n integer;
BEGIN
  SELECT * INTO s FROM public.acces_suspensions_paiement
   WHERE profile_id = p_profil AND retabli_le IS NULL FOR UPDATE;
  IF s.id IS NULL THEN
    RETURN false;
  END IF;
  SELECT f.statut INTO v_statut FROM public.factures_mensuelles f WHERE f.id = s.facture_id;
  IF v_statut = 'a_financer' THEN
    RETURN false;
  END IF;
  v_motif := CASE WHEN v_statut = 'financee' THEN 'paiement' ELSE 'facture_close' END;
  UPDATE public.acces_suspensions_paiement
     SET retabli_le = pg_catalog.clock_timestamp(), retabli_motif = v_motif
   WHERE id = s.id;
  v_n := private.fac_notifier_paiement(p_profil, 'acces_retabli_paiement', '{}'::jsonb);
  INSERT INTO public.relances_paiement (facture_id, profile_id, action, jour, destinataires)
  VALUES (s.facture_id, p_profil, 'retablissement', p_jour, v_n);
  PERFORM public.log_sensitive_access('acces_retabli_paiement', 'acces_suspensions_paiement', s.id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'facture_id', s.facture_id,
      'motif', v_motif, 'destinataires', v_n));
  RETURN true;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Le traitement du jour.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.fac_traiter_relances(p_jour date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_mois_courant date;
  f public.factures_mensuelles;
  v_profil uuid;
  v_n integer;
  v_id bigint;
  v_susp uuid;
  v_relances integer := 0;
  v_suspensions integer := 0;
  v_retablissements integer := 0;
BEGIN
  IF p_jour IS NULL THEN
    RAISE EXCEPTION 'jour absent' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('relances:' || p_jour::text, 0));
  v_mois_courant := pg_catalog.date_trunc('month', p_jour)::date;

  -- 1. Les acces dont la facture n'est plus a financer sont rendus.
  FOR v_profil IN SELECT s.profile_id FROM public.acces_suspensions_paiement s
                   WHERE s.retabli_le IS NULL ORDER BY s.suspendu_le, s.id LOOP
    IF private.fac_retablir_acces(v_profil, p_jour) THEN
      v_retablissements := v_retablissements + 1;
    END IF;
  END LOOP;

  -- 2. Les relances : l'echeance d'une facture est le premier jour de son
  -- mois ; une relance par facture et par jour d'avance lu dans la politique
  -- de la facture (celle de son mois, figee a l'emission).
  BEGIN
    FOR f IN SELECT x.* FROM public.factures_mensuelles x
               JOIN public.politiques_commerciales p ON p.version = x.politique_version
              WHERE x.statut = 'a_financer' AND x.total_mineur > 0
                AND x.mois >= p_jour
                AND p.jours_relance IS NOT NULL
                AND (x.mois - p_jour) = ANY (p.jours_relance)
              ORDER BY x.mois, x.emise_le, x.id LOOP
      IF private.fac_paiement_en_attente(f.profile_id)
         OR private.fac_bourse_couvre(f.profile_id, f.mois) THEN
        CONTINUE;
      END IF;
      v_id := NULL;
      INSERT INTO public.relances_paiement (facture_id, profile_id, action, jours_avant, jour)
      VALUES (f.id, f.profile_id, 'relance', f.mois - p_jour, p_jour)
      ON CONFLICT (facture_id, jours_avant) WHERE action = 'relance' DO NOTHING
      RETURNING id INTO v_id;
      IF v_id IS NULL THEN
        CONTINUE;
      END IF;
      v_n := private.fac_notifier_paiement(f.profile_id, 'paiement_relance',
        pg_catalog.jsonb_build_object('jours_avant', f.mois - p_jour));
      UPDATE public.relances_paiement SET destinataires = v_n WHERE id = v_id;
      PERFORM public.log_sensitive_access('paiement_relance', 'factures_mensuelles', f.id::text,
        pg_catalog.jsonb_build_object('profile_id', f.profile_id, 'jours_avant', f.mois - p_jour,
          'destinataires', v_n));
      v_relances := v_relances + 1;
    END LOOP;
  END;

  -- 3. La suspension : au jour de suspension de la politique de la facture,
  -- et tant que la facture reste impayee ensuite (un traitement manque se
  -- rattrape).
  BEGIN
    FOR f IN SELECT x.* FROM public.factures_mensuelles x
               JOIN public.politiques_commerciales p ON p.version = x.politique_version
              WHERE x.statut = 'a_financer' AND x.total_mineur > 0
                AND p.jour_suspension IS NOT NULL
                AND (x.mois < v_mois_courant
                     OR (x.mois = v_mois_courant
                         AND pg_catalog.date_part('day', p_jour) >= p.jour_suspension))
              ORDER BY x.mois, x.emise_le, x.id LOOP
      IF private.fac_paiement_en_attente(f.profile_id)
         OR private.fac_bourse_couvre(f.profile_id, f.mois)
         OR (private.fac_adhesion(f.profile_id, f.mois)).id IS NULL
         OR private.fac_eleve_suspendu(f.profile_id) THEN
        CONTINUE;
      END IF;
      v_susp := NULL;
      INSERT INTO public.acces_suspensions_paiement (profile_id, facture_id, jour)
      VALUES (f.profile_id, f.id, p_jour)
      ON CONFLICT (profile_id) WHERE retabli_le IS NULL DO NOTHING
      RETURNING id INTO v_susp;
      IF v_susp IS NULL THEN
        CONTINUE;
      END IF;
      v_n := private.fac_notifier_paiement(f.profile_id, 'acces_suspendu_paiement', '{}'::jsonb);
      INSERT INTO public.relances_paiement (facture_id, profile_id, action, jour, destinataires)
      VALUES (f.id, f.profile_id, 'suspension', p_jour, v_n);
      PERFORM public.log_sensitive_access('acces_suspendu_paiement', 'acces_suspensions_paiement', v_susp::text,
        pg_catalog.jsonb_build_object('profile_id', f.profile_id, 'facture_id', f.id,
          'mois', f.mois, 'destinataires', v_n));
      v_suspensions := v_suspensions + 1;
    END LOOP;
  END;

  RETURN pg_catalog.jsonb_build_object('jour', p_jour,
    'relances', v_relances, 'suspensions', v_suspensions, 'retablissements', v_retablissements);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Le paiement valide rend l'acces tout de suite : `fac_financer_profil` est le
-- point commun de la saisie de la direction, de la validation (FAC-D) et du
-- webhook Stripe (FI-BR-06). Corps de FAC-E-01, plus le retablissement.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.fac_financer_profil(p_profil uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  f public.factures_mensuelles;
  v_w public.wallets;
  v_debit bigint;
  v_n integer := 0;
  v_foyer uuid;
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('financement:' || p_profil::text, 0));
  FOR f IN SELECT * FROM public.factures_mensuelles
            WHERE profile_id = p_profil AND statut = 'a_financer'
            ORDER BY mois, emise_le LOOP
    IF f.total_mineur = 0 THEN
      UPDATE public.factures_mensuelles SET statut = 'financee', financee_le = pg_catalog.clock_timestamp()
       WHERE id = f.id;
    ELSE
      EXIT WHEN private.fac_solde_profil(p_profil) < f.total_mineur;
      v_w := private.fac_portefeuille(f.household_id, f.devise);
      INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id)
      VALUES (v_w.id, f.total_mineur, f.devise, 'debit', f.id, p_profil)
      RETURNING id INTO v_debit;
      UPDATE public.factures_mensuelles
         SET statut = 'financee', financee_le = pg_catalog.clock_timestamp(), debit_entry_id = v_debit
       WHERE id = f.id;
    END IF;
    v_n := v_n + 1;
    v_foyer := f.household_id;
  END LOOP;
  IF v_foyer IS NOT NULL THEN
    PERFORM private.fac_crediter_parrainage(v_foyer);
  END IF;
  PERFORM private.fac_retablir_acces(p_profil, private.fac_aujourdhui());
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Lancement a la main (direction, AAL2).
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.fac_traiter_relances_du_jour()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_res jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid() AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'relances reservees a la direction en verification renforcee'
      USING ERRCODE = '42501';
  END IF;
  v_res := private.fac_traiter_relances(private.fac_aujourdhui());
  PERFORM public.log_sensitive_access('relances_paiement_lancees', 'relances_paiement', v_res ->> 'jour', v_res);
  RETURN v_res;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Lecture pour l'application.
-- ---------------------------------------------------------------------------

-- L'acces d'un eleve tel que l'application le lit. `p_avec_cause` : le tuteur
-- et l'eleve adulte lisent la cause (« suspendu_paiement ») ; l'enfant n'en
-- lit qu'une ouverture (jamais une cause ni un montant).
CREATE FUNCTION private.fac_acces_json(p_profil uuid, p_avec_cause boolean, p_gere_son_acces boolean)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'eleveId', pr.id,
    'prenom', pr.first_name,
    'finAcces', CASE WHEN pr.access_until IS NULL THEN NULL
                     ELSE pg_catalog.to_char(pr.access_until AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END,
    'seancesPayantesOuvertes', CASE WHEN s.id IS NOT NULL THEN false ELSE NULL END,
    'place', CASE WHEN s.id IS NOT NULL AND p_avec_cause THEN 'suspendu_paiement' ELSE NULL END,
    'datePlace', CASE WHEN s.id IS NOT NULL AND p_avec_cause
                      THEN pg_catalog.to_char(s.jour, 'YYYY-MM-DD') ELSE NULL END,
    'gereSonAcces', p_gere_son_acces)
    FROM public.profiles pr
    LEFT JOIN public.acces_suspensions_paiement s ON s.profile_id = pr.id AND s.retabli_le IS NULL
   WHERE pr.id = p_profil AND pr.deleted_at IS NULL;
$function$;

-- PortMonAcces : la ligne de l'eleve connecte, ou nul.
CREATE FUNCTION public.mon_acces()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_type public.student_type;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'acces reserve a un compte valide' USING ERRCODE = '42501';
  END IF;
  SELECT sp.student_type INTO v_type FROM public.student_profiles sp
   WHERE sp.profile_id = auth.uid() AND sp.deleted_at IS NULL;
  IF v_type IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN private.fac_acces_json(auth.uid(), v_type = 'autonomous', v_type = 'autonomous');
END;
$function$;

-- PortAccesFoyer : un acces par eleve du foyer, pour un tuteur du foyer.
CREATE FUNCTION public.acces_du_foyer()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid := public.app_household_id();
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'guardian'
                  AND public.app_account_valid() AND v_foyer IS NOT NULL, false) THEN
    RAISE EXCEPTION 'acces du foyer reserve a un tuteur du foyer' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(private.fac_acces_json(pr.id, true, false)
             ORDER BY pg_catalog.lower(pr.first_name), pr.id)
      FROM public.profiles pr
      JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
     WHERE pr.household_id = v_foyer AND pr.deleted_at IS NULL), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Le jeton video refuse un eleve suspendu pour paiement (le compte, lui, reste
-- ouvert). Corps de la version en vigueur, plus un controle apres le role.
-- ---------------------------------------------------------------------------
DO $jeton$
DECLARE
  v_oid regprocedure := 'public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_ancre text := E'  -- La fenetre d''ouverture : configurable';
  v_ajout text := $ajout$
  -- FAC-F-01 : un eleve suspendu pour paiement ne rejoint pas la salle.
  if v_role = 'student' and private.fac_eleve_suspendu(p_profile_id) then
    raise exception 'acces suspendu pour paiement' using errcode = 'insufficient_privilege';
  end if;

$ajout$;
BEGIN
  IF pg_catalog.strpos(v_def, v_ancre) = 0
     OR pg_catalog.strpos(v_def, 'fac_eleve_suspendu') > 0 THEN
    RAISE EXCEPTION 'FAC-F-01 : ancre du jeton video introuvable ou deja posee';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancre, v_ajout || v_ancre);
END;
$jeton$;

-- ---------------------------------------------------------------------------
-- Proprietaire, droits, empreintes.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_destinataires_paiement(uuid)'::regprocedure,
    'private.fac_paiement_en_attente(uuid)'::regprocedure,
    'private.fac_bourse_couvre(uuid,date)'::regprocedure,
    'private.fac_eleve_suspendu(uuid)'::regprocedure,
    'private.fac_notifier_paiement(uuid,text,jsonb)'::regprocedure,
    'private.fac_retablir_acces(uuid,date)'::regprocedure,
    'private.fac_traiter_relances(date)'::regprocedure,
    'private.fac_financer_profil(uuid)'::regprocedure,
    'private.fac_acces_json(uuid,boolean,boolean)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;

  FOREACH v_oid IN ARRAY ARRAY[
    'public.fac_traiter_relances_du_jour()'::regprocedure,
    'public.mon_acces()'::regprocedure,
    'public.acces_du_foyer()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  END LOOP;

  v_oid := 'public.fac_traiter_relances_du_jour()'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FAC-F-01 : lancement a la main des relances et de la suspension, direction en AAL2.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  v_oid := 'public.mon_acces()'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SESSION_POSITIVE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FAC-F-01 : acces de l''eleve connecte ; l''enfant ne lit jamais la cause.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  v_oid := 'public.acces_du_foyer()'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FAC-F-01 : acces des eleves du foyer pour un tuteur du foyer, avec la cause.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- ---------------------------------------------------------------------------
-- Planification quotidienne, SEULEMENT si pg_cron existe.
-- ---------------------------------------------------------------------------
DO $cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      PERFORM cron.schedule('fac-relances-quotidiennes', '15 5 * * *',
        'SELECT private.fac_traiter_relances(private.fac_aujourdhui())');
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'FAC-F-01 : planification pg_cron non posee (%)', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'FAC-F-01 : pg_cron absent, planification non posee ; lancer fac_traiter_relances_du_jour() a la main';
  END IF;
END;
$cron$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.fac_traiter_relances_du_jour()'::regprocedure,
    'public.mon_acces()'::regprocedure,
    'public.acces_du_foyer()'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                      AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FAC-F-01 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'fac\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FAC-F-01 : aide privee executable par un client';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure, 'EXECUTE')
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure),
                          'fac_eleve_suspendu') = 0 THEN
    RAISE EXCEPTION 'FAC-F-01 : le jeton video doit refuser l''eleve suspendu et rester ferme aux clients';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.fac_financer_profil(uuid)'::regprocedure),
                       'fac_retablir_acces') = 0 THEN
    RAISE EXCEPTION 'FAC-F-01 : le financement doit retablir l''acces';
  END IF;
END;
$postflight$;

COMMIT;
