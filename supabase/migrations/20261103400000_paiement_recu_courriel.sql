-- Parcours 7 (ouverture, 03/11/2026) : quand Stripe confirme un paiement
-- (checkout.session.completed ou async_payment_succeeded avec payment_status
-- « paid »), la famille est prevenue dans l'application et par e-mail.
--
-- Avant cette migration, `recharge_evenement_stripe` creditait le solde en
-- silence : aucune notification, aucun e-mail. La page de paiement Stripe
-- envoie son propre recu seulement si l'option est activee dans le tableau de
-- bord ; l'application n'avait rien qui lui appartienne.
--
-- Regles (mots-rewayah) : « Le paiement est reçu » et jamais « paiement
-- confirmé » ; la preuve est l'evenement Stripe « paid », pas le retour de la
-- page de paiement. Un seul avis par destinataire et par commande, meme quand
-- la commande recharge plusieurs profils eleves du meme foyer.
--
-- Destinataires : ceux de `private.fac_destinataires_paiement` pour chaque
-- profil credite (l'eleve adulte lui-meme, sinon tous les tuteurs du foyer),
-- plus le titulaire de la commande, sans doublon.
--
-- Pour celui qui applique : aucun effacement de lignes ni vidage de table ;
-- une seule suppression de contrainte « IF EXISTS » (section 1), recreee
-- aussitot. Pas de BEGIN / COMMIT de transaction : les deux BEGIN du fichier
-- ouvrent des corps de fonction plpgsql.

-- ---------------------------------------------------------------------------
-- 1. Un evenement de plus dans la contrainte des notifications.
-- ---------------------------------------------------------------------------
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
  'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation',
  'controle_mission_attribuee', 'controle_mission_non_controlee', 'classe_changee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire',
  'creneau_change', 'seance_annulee', 'seance_deplacee', 'enseignante_absente',
  'classe_supprimee',
  -- A3 (31/10/2026).
  'remplacement_avertissement', 'remplacement_pre_alerte', 'remplacement_inutile',
  'titulaire_en_retard', 'remplacant_arrive',
  -- Parcours 7 (03/11/2026).
  'paiement_recu'));

-- ---------------------------------------------------------------------------
-- 2. L'e-mail du paiement recu part avec les autres e-mails de facturation.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.courriel_depuis_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM public.courriel_enfiler(
    CASE
      WHEN NEW.evenement IN ('paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement',
                             'paiement_recu')
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
-- 3. Le credit d'une commande previent la famille.
--    Corps identique a 20261018120000 (FAC-E-01), plus l'insertion des
--    notifications apres le passage de la commande a « completed ».
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.recharge_evenement_stripe(
  p_evenement text, p_type text, p_environnement text, p_commande uuid,
  p_session text, p_paiement text, p_statut_paiement text,
  p_montant bigint, p_devise text)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.commandes_recharge;
  v_w public.wallets;
  a public.commandes_recharge_allocations;
  v_entry bigint;
  v_issue text;
  v_suivant date := (private.fac_mois_courant() + interval '1 month')::date;
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
   WHERE id = p_commande AND session_prestataire = p_session FOR UPDATE;
  IF v_c.id IS NULL THEN
    v_issue := 'commande_inconnue';
  ELSIF v_c.environnement IS DISTINCT FROM p_environnement THEN
    v_issue := 'environnement_different';
  ELSIF p_type IN ('checkout.session.completed', 'checkout.session.async_payment_succeeded') THEN
    IF p_statut_paiement IS DISTINCT FROM 'paid' THEN
      v_issue := 'paiement_en_attente';
    ELSIF v_c.etat = 'completed' THEN
      v_issue := 'deja_credite';
    ELSIF v_c.etat NOT IN ('awaiting_confirmation', 'preparing') THEN
      v_issue := 'etat_' || v_c.etat;
    ELSIF p_montant IS DISTINCT FROM v_c.total_mineur
          OR pg_catalog.upper(coalesce(p_devise, '')) <> v_c.devise THEN
      UPDATE public.commandes_recharge SET etat = 'failed', motif = 'montant_incoherent',
             paiement_prestataire = p_paiement WHERE id = v_c.id;
      v_issue := 'montant_incoherent';
    ELSE
      UPDATE public.commandes_recharge
         SET etat = 'allocation_in_progress', paiement_prestataire = p_paiement,
             confirme_le = pg_catalog.clock_timestamp()
       WHERE id = v_c.id;
      v_w := private.fac_portefeuille(v_c.household_id, v_c.devise);
      FOR a IN SELECT * FROM public.commandes_recharge_allocations
                WHERE commande_id = v_c.id ORDER BY rang LOOP
        INSERT INTO public.wallet_entries
          (wallet_id, amount_minor, currency, reference_type, reference_id, beneficiaire_id,
           confirme_par_prestataire_le)
        VALUES (v_w.id, a.montant_mineur, v_c.devise, 'credit', v_c.id, a.profile_id,
                pg_catalog.clock_timestamp())
        RETURNING id INTO v_entry;
        UPDATE public.commandes_recharge_allocations SET entry_id = v_entry
         WHERE commande_id = v_c.id AND profile_id = a.profile_id;
        IF a.formule IN ('trimestriel', 'annuel') THEN
          INSERT INTO public.engagements_prepaiement
            (profile_id, formule, mois_debut, nb_mois, total_mineur, devise, commande_id)
          VALUES (a.profile_id, a.formule, v_suivant, CASE a.formule WHEN 'trimestriel' THEN 3 ELSE 12 END,
                  a.montant_mineur, v_c.devise, v_c.id);
        END IF;
        PERFORM private.fac_emettre_facture(a.profile_id, private.fac_mois_courant(), v_c.titulaire);
        PERFORM private.fac_financer_profil(a.profile_id);
      END LOOP;
      UPDATE public.commandes_recharge SET etat = 'completed', termine_le = pg_catalog.clock_timestamp()
       WHERE id = v_c.id;
      -- Parcours 7 : la famille est prevenue, une fois par destinataire. Le
      -- declencheur `courriel_notification` met l'e-mail en file.
      INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
      SELECT d.destinataire, d.foyer, 'paiement_recu',
             pg_catalog.jsonb_build_object('montant_mineur', v_c.total_mineur, 'devise', v_c.devise,
                                           'commande_id', v_c.id),
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
      PERFORM public.log_sensitive_access('recharge_creditee', 'commandes_recharge', v_c.id::text,
        pg_catalog.jsonb_build_object('total_mineur', v_c.total_mineur, 'devise', v_c.devise,
          'prestataire', 'stripe', 'paiement', p_paiement));
      v_issue := 'credite';
    END IF;
  ELSIF p_type = 'checkout.session.async_payment_failed' THEN
    UPDATE public.commandes_recharge SET etat = 'failed', motif = 'paiement_refuse'
     WHERE id = v_c.id AND etat IN ('awaiting_confirmation', 'preparing');
    v_issue := CASE WHEN FOUND THEN 'echec' ELSE 'etat_' || v_c.etat END;
  ELSIF p_type = 'checkout.session.expired' THEN
    UPDATE public.commandes_recharge SET etat = 'stale', motif = 'session_expiree'
     WHERE id = v_c.id AND etat IN ('awaiting_confirmation', 'preparing');
    v_issue := CASE WHEN FOUND THEN 'perime' ELSE 'etat_' || v_c.etat END;
  ELSE
    v_issue := 'ignore';
  END IF;

  UPDATE public.paiement_webhooks SET issue = v_issue, commande_id = v_c.id
   WHERE prestataire = 'stripe' AND environnement = p_environnement AND evenement_id = p_evenement;
  RETURN v_issue;
END;
$function$;
