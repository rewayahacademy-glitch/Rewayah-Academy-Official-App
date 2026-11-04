-- FN-115b, fichier 2 sur 2 (02/11/2026) : remboursements et contestations
-- Stripe traites par le serveur. Aucun mot de suppression dans ce fichier : le
-- pilote le pose lui-meme, APRES le fichier 1 (20261104300000, contraintes de
-- notifications, colle par le directeur).
--
-- Decision du directeur du 01/11/2026, « oui pour les 7 points »
-- (DECISION-TARIFS-2026-10-18.md, section du 01/11/2026) ; plan accepte par le
-- pilote le 02/11 avec quatre conditions, toutes tenues ici :
--   1. le drapeau de reouverture est local a la transaction, pose seulement
--      par une fonction SECURITY DEFINER, et le declencheur exige en plus que
--      l'appelant effectif soit postgres (proprietaire) ou service_role ;
--   2. les frais d'une contestation perdue vont au plus ancien beneficiaire de
--      la commande (rang 1), regle ecrite dans DECISION-TARIFS ;
--   3. ce fichier ne contient aucun mot de suppression ;
--   4. les trois evenements a ajouter au webhook Stripe sont ecrits dans la PR.
--
-- Ce qui existait et sert tel quel :
--   - wallet_entries 'refund' (x2_17 : refund_of = un credit confirme, plafond
--     du credit moins ses remboursements, ligne de tresorerie « remboursement »),
--     'adjustment' (montant signe tel quel, bf1_montant_signe) et 'credit' ;
--   - private.fac_solde_profil, fac_financer_profil, fac_retablir_acces,
--     fac_notifier_paiement, fac_destinataires_paiement, fac_portefeuille ;
--   - acces_suspensions_paiement et relances_paiement (action 'suspension') ;
--   - paiement_webhooks pour l'idempotence (prestataire, environnement,
--     identifiant d'evenement), comme recharge_evenement_stripe ;
--   - les evenements existants acces_suspendu_paiement / acces_retabli_paiement.
--
-- Regles (directeur) :
--   - un mois rembourse n'est plus paye : si le solde du profil passe sous
--     zero, les factures financees, la plus recente d'abord, repassent « a
--     financer » (une ligne 'adjustment' annule leur debit) jusqu'a ce que le
--     solde revienne a zero ou plus ; l'acces est alors suspendu TOUT DE SUITE,
--     sans rappels. Un remboursement partiel qui laisse le solde positif ne
--     suspend rien (pilote, 02/11) ;
--   - une contestation ouverte retire l'argent comme un remboursement, avec la
--     meme suite ; gagnee, l'argent revient (credit confirme) et l'acces est
--     rendu si les factures sont de nouveau financees ; perdue, les frais du
--     prestataire vont au solde du plus ancien beneficiaire de la commande ;
--   - une simple demande de renseignement de la banque (statut warning_*)
--     ne retire pas l'argent : elle est notee, sans effet sur l'acces ;
--   - la famille est prevenue par e-mail et dans l'application, la direction
--     dans l'application, l'enseignant jamais.

-- ---------------------------------------------------------------------------
-- 1. Courriel ou application : les trois nouveaux evenements.
-- ---------------------------------------------------------------------------
INSERT INTO private.notification_courriel (evenement, portee, courriel) VALUES
  ('remboursement_effectue', '*', true),
  ('remboursement_effectue', 'direction', false),
  ('litige_ouvert', '*', true),
  ('litige_ouvert', 'direction', false),
  ('litige_clos', '*', true),
  ('litige_clos', 'direction', false)
ON CONFLICT (evenement, portee) DO NOTHING;

-- public.courriel_depuis_notification remplacee EN ENTIER. Corps de base :
-- 20261103600000_seance_terminee_avis.sql, section 3 ; la seule difference est
-- la categorie 'facturation' des trois nouveaux evenements.
CREATE OR REPLACE FUNCTION public.courriel_depuis_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- DECISION-NOTIFICATIONS-COURRIEL (01/11/2026) : application seulement.
  IF NOT private.notification_avec_courriel(NEW.evenement, NEW.params ->> 'portee') THEN
    RETURN NULL;
  END IF;
  PERFORM public.courriel_enfiler(
    CASE
      WHEN NEW.evenement IN ('paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
                             'paiement_recu', 'remboursement_effectue', 'litige_ouvert', 'litige_clos')
        THEN 'facturation'
      WHEN NEW.evenement IN ('demande_recue', 'classe_validee', 'demande_close', 'demande_presentation')
        THEN 'inscription'
      ELSE 'classes' END,
    NEW.evenement,
    public.courriel_adresse_profil(NEW.destinataire),
    NEW.destinataire,
    NEW.params || pg_catalog.jsonb_build_object('destination', NEW.destination),
    'notification:' || NEW.id::text);
  RETURN NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Une facture financee peut redevenir « a financer », par le serveur seul.
-- ---------------------------------------------------------------------------
-- Corps de base : 20261017171000_fac_b_01_factures_mensuelles.sql. Ce qui
-- change : la transition financee -> a_financer est permise si le drapeau de
-- transaction 'fac.reouverture' vaut 'on' ET si l'appelant effectif est
-- postgres (la fonction SECURITY DEFINER qui le pose) ou service_role. Un
-- compte client qui poserait le drapeau reste refuse (scenario SQL).
CREATE OR REPLACE FUNCTION private.fac_facture_figee()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RAISE EXCEPTION 'une facture emise ne se supprime pas : l''annuler' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['statut','financee_le','debit_entry_id','annulee_le','annulee_par','motif_annulation'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['statut','financee_le','debit_entry_id','annulee_le','annulee_par','motif_annulation']) THEN
    RAISE EXCEPTION 'une facture emise ne change plus ; seul son statut avance' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF OLD.statut = 'a_financer' AND NEW.statut IN ('financee', 'annulee') THEN
    RETURN NEW;
  END IF;
  -- FN-115b : un remboursement ou une contestation rouvre une facture.
  IF OLD.statut = 'financee' AND NEW.statut = 'a_financer'
     AND coalesce(pg_catalog.current_setting('fac.reouverture', true), '') = 'on'
     AND current_user IN ('postgres', 'service_role')
     AND NEW.financee_le IS NULL AND NEW.debit_entry_id IS NULL THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'une facture emise ne change plus ; seul son statut avance' USING ERRCODE = 'insufficient_privilege';
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Les traces : remboursements et contestations.
-- ---------------------------------------------------------------------------
CREATE TABLE public.litiges_paiement (
  id text PRIMARY KEY CHECK (pg_catalog.length(id) BETWEEN 1 AND 255),
  commande_id uuid NOT NULL REFERENCES public.commandes_recharge(id),
  environnement text NOT NULL CHECK (environnement IN ('test', 'live')),
  montant_mineur bigint NOT NULL CHECK (montant_mineur >= 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  statut text NOT NULL CHECK (statut IN ('enquete', 'ouvert', 'gagne', 'perdu', 'enquete_close')),
  frais_mineur bigint CHECK (frais_mineur IS NULL OR frais_mineur >= 0),
  ouvert_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  clos_le timestamptz
);
ALTER TABLE public.litiges_paiement ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.litiges_paiement FROM PUBLIC, anon, authenticated;
CREATE POLICY litiges_paiement_direction_lecture ON public.litiges_paiement
  FOR SELECT TO authenticated
  USING (coalesce((SELECT public.app_role()) IN ('admin', 'accountant')
                  AND (SELECT public.app_account_valid()), false));
GRANT SELECT ON public.litiges_paiement TO authenticated;
COMMENT ON TABLE public.litiges_paiement IS
  'FN-115b : contestations d''un paiement aupres de la banque (Stripe dispute), une ligne par contestation. Ecrite par remboursement_evenement_stripe seulement.';

-- Une ligne par part rendue a un beneficiaire : d'un remboursement Stripe
-- (origine 'remboursement') ou d'une contestation (origine 'litige').
CREATE TABLE public.remboursements_paiement (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  commande_id uuid NOT NULL REFERENCES public.commandes_recharge(id),
  origine text NOT NULL CHECK (origine IN ('remboursement', 'litige')),
  litige_id text REFERENCES public.litiges_paiement(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  entry_id bigint NOT NULL UNIQUE REFERENCES public.wallet_entries(id),
  evenement_id text NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CHECK ((origine = 'litige') = (litige_id IS NOT NULL))
);
CREATE INDEX remboursements_paiement_commande ON public.remboursements_paiement (commande_id, origine);
ALTER TABLE public.remboursements_paiement ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.remboursements_paiement FROM PUBLIC, anon, authenticated;
CREATE POLICY remboursements_paiement_direction_lecture ON public.remboursements_paiement
  FOR SELECT TO authenticated
  USING (coalesce((SELECT public.app_role()) IN ('admin', 'accountant')
                  AND (SELECT public.app_account_valid()), false));
GRANT SELECT ON public.remboursements_paiement TO authenticated;
COMMENT ON TABLE public.remboursements_paiement IS
  'FN-115b : part d''un remboursement ou d''une contestation rendue a un beneficiaire (ligne wallet_entries ''refund''). Ecrite par remboursement_evenement_stripe seulement.';

-- ---------------------------------------------------------------------------
-- 4. Aides privees.
-- ---------------------------------------------------------------------------

-- Si le solde du profil est negatif, rouvre ses factures financees, la plus
-- recente d'abord, jusqu'a ce qu'il redevienne positif ou nul ; puis suspend
-- l'acces TOUT DE SUITE sur la plus ancienne facture rouverte. Rend le nombre
-- de factures rouvertes.
CREATE FUNCTION private.fac_rouvrir_si_negatif(p_profil uuid, p_cause text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  f public.factures_mensuelles;
  v_w public.wallets;
  v_n integer := 0;
  v_plus_ancienne uuid;
  v_susp uuid;
  v_dest integer;
  v_jour date := private.fac_aujourdhui();
BEGIN
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('financement:' || p_profil::text, 0));
  IF private.fac_solde_profil(p_profil) >= 0 THEN
    RETURN 0;
  END IF;
  PERFORM pg_catalog.set_config('fac.reouverture', 'on', true);
  FOR f IN SELECT * FROM public.factures_mensuelles
            WHERE profile_id = p_profil AND statut = 'financee'
              AND total_mineur > 0 AND debit_entry_id IS NOT NULL
            ORDER BY mois DESC, emise_le DESC LOOP
    EXIT WHEN private.fac_solde_profil(p_profil) >= 0;
    v_w := private.fac_portefeuille(f.household_id, f.devise);
    INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id)
    VALUES (v_w.id, f.total_mineur, f.devise, 'adjustment', f.id, p_profil);
    UPDATE public.factures_mensuelles
       SET statut = 'a_financer', financee_le = NULL, debit_entry_id = NULL
     WHERE id = f.id;
    v_n := v_n + 1;
    v_plus_ancienne := f.id;
  END LOOP;
  PERFORM pg_catalog.set_config('fac.reouverture', '', true);
  IF v_plus_ancienne IS NULL THEN
    RETURN 0;
  END IF;
  -- Suspension immediate (on paie avant de commencer : ni rappels ni delai).
  INSERT INTO public.acces_suspensions_paiement (profile_id, facture_id, jour)
  VALUES (p_profil, v_plus_ancienne, v_jour)
  ON CONFLICT (profile_id) WHERE retabli_le IS NULL DO NOTHING
  RETURNING id INTO v_susp;
  IF v_susp IS NOT NULL THEN
    v_dest := private.fac_notifier_paiement(p_profil, 'acces_suspendu_paiement',
      pg_catalog.jsonb_build_object('cause', p_cause));
    INSERT INTO public.relances_paiement (facture_id, profile_id, action, jour, destinataires)
    VALUES (v_plus_ancienne, p_profil, 'suspension', v_jour, v_dest);
    PERFORM public.log_sensitive_access('acces_suspendu_paiement', 'acces_suspensions_paiement', v_susp::text,
      pg_catalog.jsonb_build_object('profile_id', p_profil, 'facture_id', v_plus_ancienne,
        'cause', p_cause, 'destinataires', v_dest));
  END IF;
  RETURN v_n;
END;
$function$;

-- Rend une somme a des beneficiaires de la commande : une ligne 'refund' par
-- part, au prorata de ce qui reste remboursable sur chaque credit (le dernier
-- beneficiaire, dans l'ordre des rangs, recoit le reste), ou entierement au
-- profil vise s'il est donne. Rend la somme effectivement rendue.
CREATE FUNCTION private.fac_rendre_commande(
  p_commande uuid, p_montant bigint, p_origine text, p_litige text, p_evenement text, p_profil uuid)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.commandes_recharge;
  v_w public.wallets;
  r record;
  v_total_reste bigint;
  v_reste_a_rendre bigint;
  v_part bigint;
  v_entry bigint;
  v_rendu bigint := 0;
  v_dernier integer;
BEGIN
  SELECT * INTO v_c FROM public.commandes_recharge WHERE id = p_commande;
  v_w := private.fac_portefeuille(v_c.household_id, v_c.devise);
  -- Ce qui reste remboursable sur chaque credit de la commande (une vue
  -- calculee deux fois : le total, puis les parts).
  SELECT coalesce(sum(x.reste), 0), max(x.rang) INTO v_total_reste, v_dernier
    FROM (SELECT a.rang,
                 a.montant_mineur - coalesce((SELECT sum(w.amount_minor) FROM public.wallet_entries w
                                                WHERE w.refund_of_entry_id = a.entry_id
                                                  AND w.reference_type = 'refund'), 0) AS reste
            FROM public.commandes_recharge_allocations a
           WHERE a.commande_id = p_commande AND a.entry_id IS NOT NULL
             AND (p_profil IS NULL OR a.profile_id = p_profil)) x
   WHERE x.reste > 0;
  v_reste_a_rendre := LEAST(p_montant, v_total_reste);
  IF v_reste_a_rendre <= 0 THEN
    RETURN 0;
  END IF;
  FOR r IN SELECT x.* FROM (
             SELECT a.rang, a.profile_id, a.entry_id,
                    a.montant_mineur - coalesce((SELECT sum(w.amount_minor) FROM public.wallet_entries w
                                                   WHERE w.refund_of_entry_id = a.entry_id
                                                     AND w.reference_type = 'refund'), 0) AS reste
               FROM public.commandes_recharge_allocations a
              WHERE a.commande_id = p_commande AND a.entry_id IS NOT NULL
                AND (p_profil IS NULL OR a.profile_id = p_profil)) x
            WHERE x.reste > 0 ORDER BY x.rang LOOP
    v_part := CASE WHEN r.rang = v_dernier
                   THEN LEAST(r.reste, v_reste_a_rendre - v_rendu)
                   ELSE LEAST(r.reste, (v_reste_a_rendre * r.reste) / v_total_reste) END;
    CONTINUE WHEN v_part <= 0;
    INSERT INTO public.wallet_entries
      (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id,
       refund_of_entry_id, confirme_par_prestataire_le)
    VALUES (v_w.id, v_part, v_c.devise, 'refund', v_c.id, r.profile_id, r.entry_id,
            pg_catalog.clock_timestamp())
    RETURNING id INTO v_entry;
    INSERT INTO public.remboursements_paiement
      (commande_id, origine, litige_id, profile_id, montant_mineur, entry_id, evenement_id)
    VALUES (v_c.id, p_origine, p_litige, r.profile_id, v_part, v_entry, p_evenement);
    v_rendu := v_rendu + v_part;
  END LOOP;
  RETURN v_rendu;
END;
$function$;

-- Previent la famille de la commande (e-mail et application) et la direction
-- (application). L'enseignant n'est jamais prevenu.
CREATE FUNCTION private.fac_notifier_remboursement(p_commande uuid, p_evenement text, p_params jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.commandes_recharge;
  v_n integer;
  v_m integer;
BEGIN
  SELECT * INTO v_c FROM public.commandes_recharge WHERE id = p_commande;
  INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
  SELECT d.destinataire, d.foyer, p_evenement,
         p_params || pg_catalog.jsonb_build_object('commande_id', v_c.id, 'devise', v_c.devise, 'portee', 'foyer'),
         '/tuteur/foyer/recharge'
    FROM (
      SELECT dd.destinataire, dd.foyer
        FROM public.commandes_recharge_allocations al
        CROSS JOIN LATERAL private.fac_destinataires_paiement(al.profile_id) dd
       WHERE al.commande_id = v_c.id
      UNION
      SELECT v_c.titulaire, v_c.household_id
    ) d
   WHERE d.destinataire IS NOT NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO public.notifications (destinataire, evenement, params, destination)
  SELECT p.id, p_evenement,
         p_params || pg_catalog.jsonb_build_object('commande_id', v_c.id, 'devise', v_c.devise,
                                                   'portee', 'direction'),
         '/admin/finance'
    FROM public.profiles p
   WHERE p.role = 'admin' AND p.deleted_at IS NULL AND p.account_status = 'active'
     AND (p.access_until IS NULL OR p.access_until > pg_catalog.now());
  GET DIAGNOSTICS v_m = ROW_COUNT;
  RETURN v_n + v_m;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4 bis. Le reste a payer compte la dette du profil.
-- ---------------------------------------------------------------------------
-- Les frais d'une contestation perdue vont au solde du profil (point 5 du
-- directeur). Le corps de 20261017172000_fac_c_01_paiements_saisis.sql ne
-- comptait qu'un solde POSITIF : avec 15 USD de frais, la page de paiement
-- proposait le mois seul (55 USD), la famille payait, et l'acces restait
-- suspendu (vu sur le banc local le 02/11/2026). Desormais un solde negatif
-- s'ajoute aux mois a financer : le montant propose et suggere couvre la
-- dette, et le paiement rouvre l'acces. Solde positif : inchange.
CREATE OR REPLACE FUNCTION private.fac_reste_a_payer(p_profil uuid)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT greatest(coalesce((SELECT sum(f.total_mineur) FROM public.factures_mensuelles f
                             WHERE f.profile_id = p_profil AND f.statut = 'a_financer'), 0)
                  - private.fac_solde_profil(p_profil), 0)::bigint;
$function$;

-- ---------------------------------------------------------------------------
-- 5. L'evenement Stripe : remboursement ou contestation.
-- ---------------------------------------------------------------------------
-- Appelee par la fonction Edge stripe-webhook, signature verifiee. Parametres :
--   p_type       'charge.refunded', 'charge.dispute.created', 'charge.dispute.closed' ;
--   p_paiement   le payment_intent (commandes_recharge.paiement_prestataire) ;
--   p_montant    charge.refunded : le CUMUL rembourse (amount_refunded) ;
--                contestation : le montant conteste ;
--   p_litige     l'identifiant de la contestation (du_...) ;
--   p_statut     statut Stripe de la contestation (warning_*, needs_response,
--                won, lost...) ;
--   p_frais      contestation perdue : les frais du prestataire, en mineur ;
--   p_profil     le profil vise par un remboursement fait depuis l'ecran
--                Finance (FN-115c) ; nul : prorata des beneficiaires.
CREATE FUNCTION public.remboursement_evenement_stripe(
  p_evenement text, p_type text, p_environnement text, p_paiement text,
  p_montant bigint, p_devise text,
  p_litige text DEFAULT NULL, p_statut text DEFAULT NULL, p_frais bigint DEFAULT NULL,
  p_profil uuid DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.commandes_recharge;
  v_l public.litiges_paiement;
  v_issue text;
  v_deja bigint;
  v_rendu bigint;
  v_profil uuid;
  v_w public.wallets;
  r record;
  v_premier uuid;
  v_frais bigint;
BEGIN
  IF p_evenement IS NULL OR p_environnement NOT IN ('test', 'live') THEN
    RAISE EXCEPTION 'evenement invalide' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.paiement_webhooks (prestataire, environnement, evenement_id, type, issue)
  VALUES ('stripe', p_environnement, p_evenement, coalesce(p_type, '?'), 'en_cours')
  ON CONFLICT DO NOTHING;
  IF NOT FOUND THEN
    RETURN 'doublon';
  END IF;

  SELECT * INTO v_c FROM public.commandes_recharge
   WHERE paiement_prestataire = p_paiement AND p_paiement IS NOT NULL FOR UPDATE;
  IF v_c.id IS NULL THEN
    v_issue := 'commande_inconnue';
  ELSIF v_c.environnement IS DISTINCT FROM p_environnement THEN
    v_issue := 'environnement_different';
  ELSIF v_c.etat <> 'completed' THEN
    v_issue := 'etat_' || v_c.etat;
  ELSIF pg_catalog.upper(coalesce(p_devise, '')) <> v_c.devise THEN
    v_issue := 'devise_differente';

  ELSIF p_type = 'charge.refunded' THEN
    -- Stripe donne le cumul : on ne rend que ce qui n'a pas deja ete rendu,
    -- quel que soit l'ordre d'arrivee des evenements.
    SELECT coalesce(sum(montant_mineur), 0) INTO v_deja FROM public.remboursements_paiement
     WHERE commande_id = v_c.id AND origine = 'remboursement';
    IF coalesce(p_montant, 0) <= v_deja THEN
      v_issue := 'deja_rembourse';
    ELSE
      v_rendu := private.fac_rendre_commande(v_c.id, p_montant - v_deja, 'remboursement', NULL,
                                             p_evenement, p_profil);
      FOR v_profil IN SELECT DISTINCT profile_id FROM public.remboursements_paiement
                       WHERE commande_id = v_c.id AND evenement_id = p_evenement LOOP
        PERFORM private.fac_rouvrir_si_negatif(v_profil, 'remboursement');
      END LOOP;
      PERFORM private.fac_notifier_remboursement(v_c.id, 'remboursement_effectue',
        pg_catalog.jsonb_build_object('montant_mineur', v_rendu));
      PERFORM public.log_sensitive_access('remboursement_stripe', 'commandes_recharge', v_c.id::text,
        pg_catalog.jsonb_build_object('montant_mineur', v_rendu, 'cumul_stripe', p_montant,
          'paiement', p_paiement));
      v_issue := CASE WHEN v_rendu < p_montant - v_deja THEN 'rembourse_plafonne' ELSE 'rembourse' END;
    END IF;

  ELSIF p_type = 'charge.dispute.created' THEN
    IF p_litige IS NULL THEN
      v_issue := 'litige_sans_identifiant';
    ELSIF EXISTS (SELECT 1 FROM public.litiges_paiement WHERE id = p_litige) THEN
      v_issue := 'litige_deja_ouvert';
    ELSIF coalesce(p_statut, '') LIKE 'warning%' THEN
      -- Demande de renseignement : l'argent n'est pas retire.
      INSERT INTO public.litiges_paiement (id, commande_id, environnement, montant_mineur, devise, statut)
      VALUES (p_litige, v_c.id, p_environnement, coalesce(p_montant, 0), v_c.devise, 'enquete');
      v_issue := 'enquete';
    ELSE
      INSERT INTO public.litiges_paiement (id, commande_id, environnement, montant_mineur, devise, statut)
      VALUES (p_litige, v_c.id, p_environnement, coalesce(p_montant, 0), v_c.devise, 'ouvert');
      v_rendu := private.fac_rendre_commande(v_c.id, coalesce(p_montant, 0), 'litige', p_litige,
                                             p_evenement, NULL);
      FOR v_profil IN SELECT DISTINCT profile_id FROM public.remboursements_paiement
                       WHERE litige_id = p_litige LOOP
        PERFORM private.fac_rouvrir_si_negatif(v_profil, 'litige');
      END LOOP;
      PERFORM private.fac_notifier_remboursement(v_c.id, 'litige_ouvert',
        pg_catalog.jsonb_build_object('montant_mineur', v_rendu));
      PERFORM public.log_sensitive_access('litige_ouvert', 'litiges_paiement', p_litige,
        pg_catalog.jsonb_build_object('commande_id', v_c.id, 'montant_mineur', v_rendu));
      v_issue := 'litige_ouvert';
    END IF;

  ELSIF p_type = 'charge.dispute.closed' THEN
    SELECT * INTO v_l FROM public.litiges_paiement WHERE id = p_litige FOR UPDATE;
    IF v_l.id IS NULL THEN
      v_issue := 'litige_inconnu';
    ELSIF v_l.statut = 'enquete' THEN
      UPDATE public.litiges_paiement SET statut = 'enquete_close', clos_le = pg_catalog.clock_timestamp()
       WHERE id = v_l.id;
      v_issue := 'enquete_close';
    ELSIF v_l.statut <> 'ouvert' THEN
      v_issue := 'litige_deja_clos';
    ELSIF p_statut = 'won' THEN
      -- L'argent revient : un credit confirme par part rendue, puis les
      -- factures se financent de nouveau et l'acces est rendu.
      v_w := private.fac_portefeuille(v_c.household_id, v_c.devise);
      FOR r IN SELECT profile_id, sum(montant_mineur) AS montant FROM public.remboursements_paiement
                WHERE litige_id = v_l.id GROUP BY profile_id LOOP
        INSERT INTO public.wallet_entries
          (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id,
           confirme_par_prestataire_le)
        VALUES (v_w.id, r.montant, v_c.devise, 'credit', v_c.id, r.profile_id, pg_catalog.clock_timestamp());
        PERFORM private.fac_financer_profil(r.profile_id);
      END LOOP;
      UPDATE public.litiges_paiement SET statut = 'gagne', clos_le = pg_catalog.clock_timestamp()
       WHERE id = v_l.id;
      PERFORM private.fac_notifier_remboursement(v_c.id, 'litige_clos',
        pg_catalog.jsonb_build_object('issue', 'gagne', 'montant_mineur', v_l.montant_mineur));
      v_issue := 'litige_gagne';
    ELSE
      -- Perdu : remboursement total deja ecrit a l'ouverture ; les frais du
      -- prestataire vont au plus ancien beneficiaire de la commande (rang 1),
      -- jamais a l'academie (DECISION-TARIFS, section du 01/11/2026).
      v_frais := coalesce(p_frais, 0);
      IF v_frais > 0 THEN
        SELECT a.profile_id INTO v_premier FROM public.commandes_recharge_allocations a
         WHERE a.commande_id = v_c.id ORDER BY a.rang LIMIT 1;
        v_w := private.fac_portefeuille(v_c.household_id, v_c.devise);
        INSERT INTO public.wallet_entries (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id)
        VALUES (v_w.id, -v_frais, v_c.devise, 'adjustment', v_c.id, v_premier);
        PERFORM private.fac_rouvrir_si_negatif(v_premier, 'litige');
      END IF;
      UPDATE public.litiges_paiement
         SET statut = 'perdu', frais_mineur = v_frais, clos_le = pg_catalog.clock_timestamp()
       WHERE id = v_l.id;
      PERFORM private.fac_notifier_remboursement(v_c.id, 'litige_clos',
        pg_catalog.jsonb_build_object('issue', 'perdu', 'montant_mineur', v_l.montant_mineur,
                                      'frais_mineur', v_frais));
      v_issue := 'litige_perdu';
    END IF;
  ELSE
    v_issue := 'ignore';
  END IF;

  UPDATE public.paiement_webhooks SET issue = v_issue, commande_id = v_c.id
   WHERE prestataire = 'stripe' AND environnement = p_environnement AND evenement_id = p_evenement;
  RETURN v_issue;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Droits : aucun client n'appelle ces fonctions.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.fac_rouvrir_si_negatif(uuid,text)',
    'private.fac_rendre_commande(uuid,bigint,text,text,text,uuid)',
    'private.fac_notifier_remboursement(uuid,text,jsonb)',
    'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', v_f);
  END LOOP;
END;
$droits$;
GRANT EXECUTE ON FUNCTION public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)
  TO service_role;
COMMENT ON FUNCTION public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid) IS
  'FN-115b : remboursement (charge.refunded, cumul) ou contestation (charge.dispute.created/closed) Stripe. Idempotent par evenement (paiement_webhooks). service_role seulement.';

-- ---------------------------------------------------------------------------
-- 7. Controle apres pose.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated',
       'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.remboursement_evenement_stripe(text,text,text,text,bigint,text,text,text,bigint,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.fac_rouvrir_si_negatif(uuid,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-115b : un client peut executer une fonction de remboursement';
  END IF;
  IF (SELECT count(*) FROM private.notification_courriel
       WHERE evenement IN ('remboursement_effectue', 'litige_ouvert', 'litige_clos')) <> 6 THEN
    RAISE EXCEPTION 'FN-115b : lignes de courriel manquantes';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.courriel_depuis_notification()'::regprocedure), 'remboursement_effectue') = 0 THEN
    RAISE EXCEPTION 'FN-115b : courriel_depuis_notification sans la categorie facturation des remboursements';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'private.fac_facture_figee()'::regprocedure), 'fac.reouverture') = 0 THEN
    RAISE EXCEPTION 'FN-115b : fac_facture_figee sans la reouverture';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'private.fac_reste_a_payer(uuid)'::regprocedure), 'greatest(private') > 0 THEN
    RAISE EXCEPTION 'FN-115b : fac_reste_a_payer ignore encore la dette du profil';
  END IF;
END;
$postflight$;
