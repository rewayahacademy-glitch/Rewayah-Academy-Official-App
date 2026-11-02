-- FN-115c (pilote, 02/11/2026) : le bouton « Rembourser » de l'ecran Finance.
--
-- Decision du directeur du 01/11/2026 (DECISION-TARIFS-2026-10-18.md, point
-- 7) : « D'ou part un remboursement : de l'ecran Finance de l'application. Le
-- serveur y propose le montant juste, selon les points 2 et 3 ; la direction
-- confirme ; l'application rembourse par le prestataire. »
--
-- REGLE DE DELAI EN ATTENTE DU DIRECTEUR (pilote, 02/11) : « 14 jours de
-- retractation » ou « premiere semaine » n'est pas tranche. Ce fichier suit le
-- texte en vigueur (arbitrage du pilote du 01/11, DECISION-TARIFS l.29-31) :
--   - dans la premiere semaine, on rembourse ce qui a ete paye, moins les
--     seances suivies (point 2) ;
--   - apres, une formule payee d'avance n'est remboursee que sur geste de la
--     direction : les mois commences au prix mensuel normal, sans la remise de
--     la formule, le reste rendu (point 3).
-- Tout le calcul tient dans private.fn115c_montant_propose : si le directeur
-- tranche autrement, seul son corps change ; le delai lui-meme est une
-- colonne de la politique commerciale (7 jours aujourd'hui).
--
-- Contenu, approuve par le pilote le 02/11 :
--   1. la politique commerciale porte le nombre de seances d'un mois et le
--      delai de remboursement ; le prix d'une seance suivie en derive (prix
--      mensuel normal / seances du mois : 5 500 / 13 = 423, 6 500 / 13 = 500,
--      le barème du 18/10) : jamais ecrit en dur ;
--   2. private.fn115c_montant_propose : le montant juste et son detail ;
--   3. la table remboursements_demandes : la decision de la direction ;
--   4. les RPC de la direction (admin seul) : paiements d'un eleve, eleves
--      remboursables, confirmation plafonnee au montant propose et
--      idempotente ;
--   5. les RPC de la fonction Edge remboursement-stripe et du webhook :
--      relire la demande, noter l'identifiant du remboursement Stripe,
--      retrouver le profil vise par cet identifiant (p_profil de
--      remboursement_evenement_stripe, prevu par FN-115b).
-- Aucune ligne n'est effacee ; aucune contrainte ni colonne n'est retiree.
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. La politique commerciale : seances d'un mois et delai de remboursement.
-- ---------------------------------------------------------------------------
-- Une version publiee ne se modifie pas (fac_politique_immuable) : ADD COLUMN
-- avec un defaut n'est pas une mise a jour de ligne. Les deux valeurs sont
-- celles du barème du 18/10 et des conditions publiques (trois seances par
-- semaine, 13 par mois ; « premiere semaine remboursee », 7 jours), vraies
-- aussi pour v1.0.0. La version suivante les publie elle-meme.
ALTER TABLE public.politiques_commerciales
  ADD COLUMN IF NOT EXISTS seances_par_mois smallint NOT NULL DEFAULT 13
    CHECK (seances_par_mois BETWEEN 1 AND 31),
  ADD COLUMN IF NOT EXISTS remboursement_delai_jours smallint NOT NULL DEFAULT 7
    CHECK (remboursement_delai_jours BETWEEN 0 AND 60);
COMMENT ON COLUMN public.politiques_commerciales.seances_par_mois IS
  'FN-115c : seances d''un mois (prix d''une seance suivie = tarif mensuel normal / seances_par_mois).';
COMMENT ON COLUMN public.politiques_commerciales.remboursement_delai_jours IS
  'FN-115c : delai, en jours depuis le paiement, pendant lequel on rembourse ce qui a ete paye moins les seances suivies. Regle en attente du directeur (« premiere semaine » ou « 14 jours »).';

-- ---------------------------------------------------------------------------
-- 2. La decision de la direction.
-- ---------------------------------------------------------------------------
CREATE TABLE public.remboursements_demandes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  commande_id uuid NOT NULL REFERENCES public.commandes_recharge(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  montant_propose_mineur bigint NOT NULL CHECK (montant_propose_mineur > 0),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  CHECK (montant_mineur <= montant_propose_mineur),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  detail jsonb NOT NULL,
  cle uuid NOT NULL UNIQUE,
  etat text NOT NULL DEFAULT 'confirmee'
    CHECK (etat IN ('confirmee', 'envoyee', 'echec', 'remboursee')),
  stripe_remboursement text UNIQUE,
  erreur text,
  demande_par uuid NOT NULL REFERENCES public.profiles(id),
  demande_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
-- Une seule demande en cours par paiement et par eleve : un double clic, meme
-- avec deux cles, ne cree pas deux remboursements.
CREATE UNIQUE INDEX remboursements_demandes_en_cours
  ON public.remboursements_demandes (commande_id, profile_id)
  WHERE etat IN ('confirmee', 'envoyee');
ALTER TABLE public.remboursements_demandes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.remboursements_demandes FROM PUBLIC, anon, authenticated;
CREATE POLICY remboursements_demandes_direction_lecture ON public.remboursements_demandes
  FOR SELECT TO authenticated
  USING (coalesce((SELECT public.app_role()) IN ('admin', 'accountant')
                  AND (SELECT public.app_account_valid()), false));
GRANT SELECT ON public.remboursements_demandes TO authenticated;
COMMENT ON TABLE public.remboursements_demandes IS
  'FN-115c : remboursement decide par la direction depuis l''ecran Finance. Ecrite par les RPC remboursement_* seulement.';

-- ---------------------------------------------------------------------------
-- 3. Le montant juste (une seule fonction : la regle du directeur).
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.fn115c_montant_propose(p_commande uuid, p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.commandes_recharge;
  v_a public.commandes_recharge_allocations;
  v_p public.politiques_commerciales;
  v_e public.engagements_prepaiement;
  v_paye bigint;
  v_rendu bigint;
  v_en_cours bigint;
  v_reste bigint;
  v_mensuel bigint;
  v_prix_seance bigint;
  v_suivies integer := 0;
  v_mois integer := 0;
  v_jours integer;
  v_regle text;
  v_montant bigint := 0;
BEGIN
  SELECT * INTO v_c FROM public.commandes_recharge WHERE id = p_commande;
  SELECT * INTO v_a FROM public.commandes_recharge_allocations
   WHERE commande_id = p_commande AND profile_id = p_profil;
  IF v_c.id IS NULL OR v_a.commande_id IS NULL OR v_c.etat <> 'completed'
     OR v_a.entry_id IS NULL OR v_c.paiement_prestataire IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('montant_mineur', 0, 'regle', 'non_remboursable');
  END IF;

  v_paye := v_a.montant_mineur;
  -- Deja rendu sur cette part (remboursement ou contestation), et ce qui est
  -- deja decide mais pas encore confirme par le prestataire.
  SELECT coalesce(sum(w.amount_minor), 0) INTO v_rendu FROM public.wallet_entries w
   WHERE w.refund_of_entry_id = v_a.entry_id AND w.reference_type = 'refund';
  SELECT coalesce(sum(d.montant_mineur), 0) INTO v_en_cours FROM public.remboursements_demandes d
   WHERE d.commande_id = p_commande AND d.profile_id = p_profil
     AND d.etat IN ('confirmee', 'envoyee');
  v_reste := GREATEST(v_paye - v_rendu - v_en_cours, 0);

  -- La politique en vigueur le jour du paiement.
  v_p := private.fac_politique_au((coalesce(v_c.confirme_le, v_c.cree_le))::date);
  v_mensuel := coalesce(private.fac_tarif_profil(p_profil, v_p), 0);
  v_prix_seance := pg_catalog.round(v_mensuel::numeric / v_p.seances_par_mois)::bigint;
  v_jours := (pg_catalog.now()::date - (coalesce(v_c.confirme_le, v_c.cree_le))::date);

  IF v_jours <= v_p.remboursement_delai_jours THEN
    -- Point 2 : ce qui a ete paye, moins les seances suivies depuis.
    SELECT count(DISTINCT sp.session_id) INTO v_suivies
      FROM public.session_participants sp
     WHERE sp.profile_id = p_profil AND sp.role = 'student'
       AND sp.deleted_at IS NULL AND sp.entered_at IS NOT NULL
       AND sp.entered_at >= coalesce(v_c.confirme_le, v_c.cree_le);
    v_regle := 'delai';
    v_montant := GREATEST(v_paye - v_suivies * v_prix_seance - v_rendu - v_en_cours, 0);
  ELSE
    SELECT * INTO v_e FROM public.engagements_prepaiement
     WHERE commande_id = p_commande AND profile_id = p_profil
     ORDER BY cree_le DESC LIMIT 1;
    IF v_e.id IS NOT NULL THEN
      -- Point 3 : les mois commences au prix mensuel normal, sans la remise
      -- de la formule ; le reste est rendu.
      v_mois := LEAST(GREATEST(
        (EXTRACT(YEAR FROM pg_catalog.age(pg_catalog.date_trunc('month', pg_catalog.now())::date, v_e.mois_debut))::integer * 12
         + EXTRACT(MONTH FROM pg_catalog.age(pg_catalog.date_trunc('month', pg_catalog.now())::date, v_e.mois_debut))::integer
         + 1), 0), v_e.nb_mois);
      v_regle := 'prepaiement';
      v_montant := GREATEST(v_paye - v_mois * v_mensuel - v_rendu - v_en_cours, 0);
    ELSE
      -- Un mois paye, apres le delai : rien a rendre.
      v_regle := 'hors_delai';
      v_montant := 0;
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'montant_mineur', LEAST(v_montant, v_reste),
    'regle', v_regle,
    'devise', v_c.devise,
    'paye_mineur', v_paye,
    'deja_rendu_mineur', v_rendu,
    'en_cours_mineur', v_en_cours,
    'seances_suivies', v_suivies,
    'prix_seance_mineur', v_prix_seance,
    'mois_commences', v_mois,
    'prix_mensuel_mineur', v_mensuel,
    'jours_depuis_paiement', v_jours,
    'delai_jours', v_p.remboursement_delai_jours,
    'politique', v_p.version);
END;
$function$;
ALTER FUNCTION private.fn115c_montant_propose(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.fn115c_montant_propose(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role;

-- Vrai pour la direction (admin) dont le compte est valide.
CREATE FUNCTION private.fn115c_direction()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
$function$;
ALTER FUNCTION private.fn115c_direction() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.fn115c_direction() FROM PUBLIC, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. Les RPC de la direction.
-- ---------------------------------------------------------------------------
-- Les paiements d'un eleve, le plus recent d'abord, avec le montant propose.
CREATE FUNCTION public.remboursement_paiements_eleve(p_profil uuid)
RETURNS TABLE (commande_id uuid, reference text, paye_le timestamptz, devise text,
               paye_mineur bigint, montant_propose_mineur bigint, detail jsonb)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.fn115c_direction() THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT c.id, c.reference, coalesce(c.confirme_le, c.cree_le), c.devise, a.montant_mineur,
         (x.d ->> 'montant_mineur')::bigint, x.d
    FROM public.commandes_recharge_allocations a
    JOIN public.commandes_recharge c ON c.id = a.commande_id
    CROSS JOIN LATERAL (SELECT private.fn115c_montant_propose(c.id, a.profile_id) AS d) x
   WHERE a.profile_id = p_profil AND c.etat = 'completed'
   ORDER BY coalesce(c.confirme_le, c.cree_le) DESC
   LIMIT 24;
END;
$function$;
ALTER FUNCTION public.remboursement_paiements_eleve(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_paiements_eleve(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.remboursement_paiements_eleve(uuid) TO authenticated;

-- Les eleves qui ont au moins un paiement remboursable : la capacite du
-- serveur qui montre « Rembourser » dans le menu de la ligne.
CREATE FUNCTION public.remboursement_eleves_remboursables()
RETURNS SETOF uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.fn115c_direction() THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT DISTINCT a.profile_id
    FROM public.commandes_recharge_allocations a
    JOIN public.commandes_recharge c ON c.id = a.commande_id
   WHERE c.etat = 'completed'
     -- Au-dela d'un an, aucune formule ne court encore.
     AND coalesce(c.confirme_le, c.cree_le) > pg_catalog.now() - interval '13 months'
     AND (private.fn115c_montant_propose(c.id, a.profile_id) ->> 'montant_mineur')::bigint > 0;
END;
$function$;
ALTER FUNCTION public.remboursement_eleves_remboursables() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_eleves_remboursables() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.remboursement_eleves_remboursables() TO authenticated;

-- La direction confirme : plafonne au montant propose, idempotent (meme cle :
-- la meme demande ; une demande deja en cours pour ce paiement et cet eleve :
-- celle-la, sans en creer une seconde).
CREATE FUNCTION public.remboursement_confirmer(
  p_commande uuid, p_profil uuid, p_montant bigint, p_cle uuid)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_d jsonb;
  v_propose bigint;
BEGIN
  IF NOT private.fn115c_direction() THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL THEN
    RAISE EXCEPTION 'cle requise' USING ERRCODE = '22023';
  END IF;
  -- Un seul passage a la fois pour ce paiement.
  PERFORM 1 FROM public.commandes_recharge WHERE id = p_commande FOR UPDATE;
  SELECT id INTO v_id FROM public.remboursements_demandes WHERE cle = p_cle;
  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;
  SELECT id INTO v_id FROM public.remboursements_demandes
   WHERE commande_id = p_commande AND profile_id = p_profil AND etat IN ('confirmee', 'envoyee');
  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;
  v_d := private.fn115c_montant_propose(p_commande, p_profil);
  v_propose := (v_d ->> 'montant_mineur')::bigint;
  IF coalesce(v_propose, 0) <= 0 THEN
    RAISE EXCEPTION 'rien a rembourser' USING ERRCODE = '22023';
  END IF;
  IF p_montant IS NULL OR p_montant <= 0 OR p_montant > v_propose THEN
    RAISE EXCEPTION 'montant au-dessus du montant propose' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.remboursements_demandes
    (commande_id, profile_id, montant_propose_mineur, montant_mineur, devise, detail, cle, demande_par)
  VALUES (p_commande, p_profil, v_propose, p_montant, v_d ->> 'devise', v_d, p_cle, public.app_user_id())
  RETURNING id INTO v_id;
  PERFORM public.log_sensitive_access('remboursement_decide', 'remboursements_demandes', v_id::text,
    pg_catalog.jsonb_build_object('commande_id', p_commande, 'profil', p_profil,
      'montant_mineur', p_montant, 'propose_mineur', v_propose));
  RETURN v_id;
END;
$function$;
ALTER FUNCTION public.remboursement_confirmer(uuid, uuid, bigint, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_confirmer(uuid, uuid, bigint, uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.remboursement_confirmer(uuid, uuid, bigint, uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. La fonction Edge remboursement-stripe et le webhook.
-- ---------------------------------------------------------------------------
-- Appelee par la fonction Edge AVEC LE JETON de la personne : la direction
-- seule relit sa demande, cote serveur (jamais un montant venu du client).
CREATE FUNCTION public.remboursement_a_envoyer(p_demande uuid)
RETURNS TABLE (demande_id uuid, paiement text, environnement text, montant_mineur bigint,
               devise text, profil uuid, etat text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.fn115c_direction() THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT d.id, c.paiement_prestataire, c.environnement, d.montant_mineur, d.devise,
         d.profile_id, d.etat
    FROM public.remboursements_demandes d
    JOIN public.commandes_recharge c ON c.id = d.commande_id
   WHERE d.id = p_demande;
END;
$function$;
ALTER FUNCTION public.remboursement_a_envoyer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_a_envoyer(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.remboursement_a_envoyer(uuid) TO authenticated;

-- Le resultat de l'appel au prestataire (service_role seulement) : l'identifiant
-- du remboursement Stripe, ou l'erreur. Un echec libere le paiement pour une
-- nouvelle demande.
CREATE FUNCTION public.remboursement_resultat_stripe(
  p_demande uuid, p_remboursement text, p_erreur text)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_etat text;
BEGIN
  IF p_remboursement IS NOT NULL THEN
    UPDATE public.remboursements_demandes
       SET stripe_remboursement = p_remboursement,
           etat = CASE WHEN etat = 'remboursee' THEN etat ELSE 'envoyee' END,
           erreur = NULL, maj_le = pg_catalog.clock_timestamp()
     WHERE id = p_demande AND etat IN ('confirmee', 'envoyee', 'remboursee')
       AND (stripe_remboursement IS NULL OR stripe_remboursement = p_remboursement)
    RETURNING etat INTO v_etat;
  ELSE
    UPDATE public.remboursements_demandes
       SET etat = 'echec', erreur = pg_catalog.left(coalesce(p_erreur, '?'), 500),
           maj_le = pg_catalog.clock_timestamp()
     WHERE id = p_demande AND etat = 'confirmee'
    RETURNING etat INTO v_etat;
  END IF;
  RETURN coalesce(v_etat, 'inchange');
END;
$function$;
ALTER FUNCTION public.remboursement_resultat_stripe(uuid, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_resultat_stripe(uuid, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.remboursement_resultat_stripe(uuid, text, text) TO service_role;

-- Le webhook : le profil vise par un remboursement Stripe, retrouve par son
-- identifiant (nul : un remboursement fait hors de l'application, au prorata).
CREATE FUNCTION public.remboursement_profil_stripe(p_remboursement text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT d.profile_id FROM public.remboursements_demandes d
   WHERE d.stripe_remboursement = p_remboursement AND d.etat = 'envoyee';
$function$;
ALTER FUNCTION public.remboursement_profil_stripe(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_profil_stripe(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.remboursement_profil_stripe(text) TO service_role;

-- Le webhook, une fois le remboursement passe aux ecritures : la demande est
-- soldee.
CREATE FUNCTION public.remboursement_solder_stripe(p_remboursement text)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  UPDATE public.remboursements_demandes
     SET etat = 'remboursee', maj_le = pg_catalog.clock_timestamp()
   WHERE stripe_remboursement = p_remboursement AND etat = 'envoyee';
  RETURN FOUND;
END;
$function$;
ALTER FUNCTION public.remboursement_solder_stripe(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.remboursement_solder_stripe(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.remboursement_solder_stripe(text) TO service_role;

-- ---------------------------------------------------------------------------
-- 6. Garde.
-- ---------------------------------------------------------------------------
DO $garde$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated',
       'public.remboursement_resultat_stripe(uuid, text, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
       'public.remboursement_profil_stripe(text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated',
       'public.remboursement_confirmer(uuid, uuid, bigint, uuid)', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.remboursements_demandes', 'INSERT') THEN
    RAISE EXCEPTION 'FN-115c : droits inattendus';
  END IF;
END
$garde$;

COMMIT;
