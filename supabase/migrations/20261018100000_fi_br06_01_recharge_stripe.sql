-- FI-BR-06 (18/10/2026) : le paiement des familles par le prestataire, chemin
-- par defaut. Guide Finance V4 §1.6 (lancement : web + PWA, `WEB_STRIPE`
-- actif ; recharge multi-profils : un paiement externe, une allocation
-- nominative par profil ; huit etats ; jamais « confirme » au retour d'un
-- ecran externe), §5.3, §5.4 ; dossier maitre §13.4 (le retour navigateur
-- n'est pas une preuve d'encaissement, idempotence des webhooks, unicite
-- prestataire/environnement/operation) ; blueprint BR0B, ligne FI-BR-06.
--
-- Directeur, 18/10/2026 : les montants payes par les familles viennent du
-- prestataire, jamais d'une saisie ; la saisie a la main (FAC-C, FAC-D) reste
-- un recours, pas le chemin par defaut.
--
-- * `recharges_recapitulatifs` (+ lignes) : le recapitulatif arrete par le
--   serveur avant le paiement (un montant par profil, le total).
-- * `commandes_recharge` (+ allocations) : la commande, idempotente par la
--   cle du titulaire ; ses huit etats ; la session du prestataire.
-- * `paiement_webhooks` : chaque evenement du prestataire une seule fois
--   (prestataire, environnement, identifiant).
-- * RPC du titulaire : `recharge_beneficiaires`, `recharge_verifier_montants`,
--   `recharge_payer`, `recharge_suivre`.
-- * RPC du serveur seulement (`service_role`, fonctions Edge
--   `recharge-payer` et `stripe-webhook`) : `recharge_attacher_session`,
--   `recharge_evenement_stripe`. Seule la seconde credite, et seulement sur
--   un evenement signe dont le montant et la devise sont ceux de la commande.
-- * Aucune taxe n'est configuree en base : le total est la somme des parts,
--   sans ligne de taxe (guide §1.8 : jamais de taux dans le client).
BEGIN;

CREATE TABLE public.recharges_recapitulatifs (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  titulaire uuid NOT NULL REFERENCES public.profiles(id),
  household_id uuid NOT NULL REFERENCES public.households(id),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  total_mineur bigint NOT NULL CHECK (total_mineur > 0),
  taxe_mineur bigint NOT NULL DEFAULT 0 CHECK (taxe_mineur >= 0),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  expire_le timestamptz NOT NULL
);
CREATE TABLE public.recharges_recap_lignes (
  recapitulatif_id uuid NOT NULL REFERENCES public.recharges_recapitulatifs(id),
  rang integer NOT NULL CHECK (rang >= 1),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  PRIMARY KEY (recapitulatif_id, profile_id)
);

CREATE TABLE public.commandes_recharge (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  reference text NOT NULL UNIQUE,
  recapitulatif_id uuid NOT NULL UNIQUE REFERENCES public.recharges_recapitulatifs(id),
  titulaire uuid NOT NULL REFERENCES public.profiles(id),
  household_id uuid NOT NULL REFERENCES public.households(id),
  cle uuid NOT NULL,
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  total_mineur bigint NOT NULL CHECK (total_mineur > 0),
  rail text NOT NULL DEFAULT 'web_stripe' CHECK (rail IN ('web_stripe')),
  etat text NOT NULL DEFAULT 'preparing' CHECK (etat IN (
    'preparing', 'awaiting_confirmation', 'confirmed', 'allocation_in_progress',
    'completed', 'failed', 'cancelled', 'stale')),
  session_prestataire text UNIQUE,
  url_paiement text,
  paiement_prestataire text,
  environnement text CHECK (environnement IS NULL OR environnement IN ('test', 'live')),
  motif text CHECK (motif IS NULL OR motif IN (
    'paiement_refuse', 'montant_incoherent', 'session_expiree')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  confirme_le timestamptz,
  termine_le timestamptz,
  UNIQUE (titulaire, cle)
);
CREATE INDEX commandes_recharge_titulaire_idx ON public.commandes_recharge (titulaire, cree_le DESC);

CREATE TABLE public.commandes_recharge_allocations (
  commande_id uuid NOT NULL REFERENCES public.commandes_recharge(id),
  rang integer NOT NULL CHECK (rang >= 1),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  entry_id bigint UNIQUE REFERENCES public.wallet_entries(id),
  PRIMARY KEY (commande_id, profile_id)
);

CREATE TABLE public.paiement_webhooks (
  prestataire text NOT NULL CHECK (prestataire IN ('stripe')),
  environnement text NOT NULL CHECK (environnement IN ('test', 'live')),
  evenement_id text NOT NULL CHECK (pg_catalog.length(evenement_id) BETWEEN 1 AND 255),
  type text NOT NULL,
  commande_id uuid REFERENCES public.commandes_recharge(id),
  issue text NOT NULL,
  recu_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (prestataire, environnement, evenement_id)
);

COMMENT ON TABLE public.commandes_recharge IS
  'FI-BR-06: commande de recharge multi-profils payee chez le prestataire ; creditee seulement par un evenement signe du prestataire.';
COMMENT ON TABLE public.paiement_webhooks IS
  'FI-BR-06: evenements du prestataire, chacun traite une seule fois (prestataire, environnement, identifiant).';

DO $tables$
DECLARE
  v_t text;
BEGIN
  FOREACH v_t IN ARRAY ARRAY['recharges_recapitulatifs', 'recharges_recap_lignes', 'commandes_recharge',
                             'commandes_recharge_allocations', 'paiement_webhooks'] LOOP
    EXECUTE pg_catalog.format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_t);
    EXECUTE pg_catalog.format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_t);
  END LOOP;
END;
$tables$;

-- Les beneficiaires que la session peut recharger : les profils eleves de son
-- foyer quand elle en est le titulaire.
CREATE FUNCTION private.rch_beneficiaire(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(private.bf1_est_titulaire() AND private.bf1_profil_du_foyer(p_profil), false);
$function$;

-- La devise des recharges du foyer : celle de son portefeuille, sinon celle
-- de la politique en vigueur.
CREATE FUNCTION private.rch_devise(p_foyer uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce((SELECT w.currency FROM public.wallets w WHERE w.household_id = p_foyer),
                  (private.fac_politique_au(private.fac_aujourdhui())).devise);
$function$;

-- Les montants proposes a un profil : le reste a payer (suggere) s'il y en a
-- un, puis un, deux et trois mois au tarif publie de son public.
CREATE FUNCTION private.rch_montants(p_profil uuid)
RETURNS bigint[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH pol AS (SELECT * FROM private.fac_politique_au(private.fac_aujourdhui())),
       tarif AS (
    SELECT CASE WHEN sp.student_type = 'autonomous' THEN pol.tarif_adulte_mineur
                ELSE pol.tarif_enfant_mineur END AS t
      FROM public.student_profiles sp, pol WHERE sp.profile_id = p_profil)
  SELECT coalesce(pg_catalog.array_agg(DISTINCT m ORDER BY m), '{}'::bigint[])
    FROM (SELECT private.fac_reste_a_payer(p_profil) AS m
          UNION ALL SELECT tarif.t * k FROM tarif, pg_catalog.generate_series(1, 3) k) x
   WHERE m > 0;
$function$;

-- Le suivi d'une commande (SuiviPaiement).
CREATE FUNCTION private.rch_suivi_json(p_commande uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'commandeId', c.id,
    'reference', c.reference,
    -- Une commande jamais partie chez le prestataire se perime au bout d'une
    -- heure : elle se lit « perimee », rien n'a ete preleve.
    'etat', CASE WHEN c.etat = 'preparing' AND c.cree_le < pg_catalog.now() - interval '1 hour'
                 THEN 'stale' ELSE c.etat END,
    'total', private.bf1_montant(c.total_mineur, c.devise),
    'date', coalesce(c.confirme_le, c.cree_le),
    'moyen', CASE WHEN c.etat = 'completed' THEN c.rail END,
    'motif', c.motif,
    'allocations', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'profilId', a.profile_id, 'prenom', p.first_name,
               'montant', private.bf1_montant(a.montant_mineur, c.devise),
               'nouveauSolde', CASE WHEN c.etat = 'completed'
                                    THEN private.bf1_montant(private.fac_solde_profil(a.profile_id), c.devise) END)
             ORDER BY a.rang)
        FROM public.commandes_recharge_allocations a
        JOIN public.profiles p ON p.id = a.profile_id
       WHERE a.commande_id = c.id), '[]'::jsonb))
    FROM public.commandes_recharge c WHERE c.id = p_commande;
$function$;

-- Les beneficiaires du titulaire et les montants proposes.
CREATE FUNCTION public.recharge_beneficiaires()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_devise text;
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'recharge reservee au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  v_devise := private.rch_devise(public.app_household_id());
  IF v_devise IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', x.id, 'prenom', x.first_name, 'cleAvatar', x.avatar_storage_key,
             'solde', private.bf1_montant(private.fac_solde_profil(x.id), v_devise),
             'montantsProposes', (SELECT coalesce(pg_catalog.jsonb_agg(private.bf1_montant(m, v_devise) ORDER BY m), '[]'::jsonb)
                                    FROM pg_catalog.unnest(private.rch_montants(x.id)) m),
             'montantSuggere', CASE WHEN private.fac_reste_a_payer(x.id) > 0
                                    THEN private.bf1_montant(private.fac_reste_a_payer(x.id), v_devise) END)
           ORDER BY x.first_name, x.id)
      FROM (SELECT p.id, p.first_name, sp.avatar_storage_key
              FROM public.profiles p
              JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
             WHERE p.deleted_at IS NULL AND p.household_id = public.app_household_id()) x), '[]'::jsonb);
END;
$function$;

-- Arrete le recapitulatif d'une recharge par montants choisis. Chaque montant
-- doit etre l'un de ceux proposes au profil : rien de saisi, rien d'invente.
CREATE FUNCTION public.recharge_verifier_montants(p_choix jsonb)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid := public.app_household_id();
  v_devise text;
  v_id uuid;
  v_total bigint := 0;
  v_rang integer := 0;
  v_c jsonb;
  v_profil uuid;
  v_montant bigint;
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'recharge reservee au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  IF p_choix IS NULL OR pg_catalog.jsonb_typeof(p_choix) <> 'array'
     OR pg_catalog.jsonb_array_length(p_choix) NOT BETWEEN 1 AND 20 THEN
    RAISE EXCEPTION 'choix invalides' USING ERRCODE = '22023';
  END IF;
  v_devise := private.rch_devise(v_foyer);
  IF v_devise IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  INSERT INTO public.recharges_recapitulatifs (titulaire, household_id, devise, total_mineur, expire_le)
  VALUES (auth.uid(), v_foyer, v_devise, 1, pg_catalog.clock_timestamp() + interval '1 hour')
  RETURNING id INTO v_id;
  FOR v_c IN SELECT * FROM pg_catalog.jsonb_array_elements(p_choix) LOOP
    BEGIN
      v_profil := (v_c ->> 'profilId')::uuid;
      v_montant := (v_c ->> 'mineur')::bigint;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'choix invalide' USING ERRCODE = '22023';
    END;
    IF v_profil IS NULL OR NOT private.rch_beneficiaire(v_profil) THEN
      RAISE EXCEPTION 'profil hors du foyer' USING ERRCODE = '42501';
    END IF;
    IF (v_c ->> 'devise') IS DISTINCT FROM v_devise
       OR NOT coalesce(v_montant = ANY (private.rch_montants(v_profil)), false) THEN
      RAISE EXCEPTION 'montant non propose' USING ERRCODE = '22023';
    END IF;
    v_rang := v_rang + 1;
    INSERT INTO public.recharges_recap_lignes (recapitulatif_id, rang, profile_id, montant_mineur)
    VALUES (v_id, v_rang, v_profil, v_montant);
    v_total := v_total + v_montant;
  END LOOP;
  UPDATE public.recharges_recapitulatifs SET total_mineur = v_total WHERE id = v_id;
  RETURN pg_catalog.jsonb_build_object(
    'id', v_id,
    'total', private.bf1_montant(v_total, v_devise),
    'lignes', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'beneficiaireId', l.profile_id, 'prenom', p.first_name,
                 'cleAvatar', sp.avatar_storage_key,
                 'montant', private.bf1_montant(l.montant_mineur, v_devise)) ORDER BY l.rang)
                 FROM public.recharges_recap_lignes l
                 JOIN public.profiles p ON p.id = l.profile_id
                 LEFT JOIN public.student_profiles sp ON sp.profile_id = l.profile_id
                WHERE l.recapitulatif_id = v_id));
END;
$function$;

-- Cree (ou rend, pour la meme cle) la commande du recapitulatif. Rien n'est
-- preleve ici : la fonction Edge `recharge-payer` ouvre ensuite la page du
-- prestataire.
CREATE FUNCTION public.recharge_payer(p_recapitulatif uuid, p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.commandes_recharge;
  v_r public.recharges_recapitulatifs;
  v_id uuid := pg_catalog.gen_random_uuid();
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'recharge reservee au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  IF p_recapitulatif IS NULL OR p_cle IS NULL THEN
    RAISE EXCEPTION 'recapitulatif ou cle absent' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('recharge:' || p_cle::text, 0));
  SELECT * INTO v_c FROM public.commandes_recharge WHERE titulaire = auth.uid() AND cle = p_cle;
  IF v_c.id IS NOT NULL THEN
    IF v_c.recapitulatif_id <> p_recapitulatif THEN
      RAISE EXCEPTION 'cle deja utilisee pour une autre recharge' USING ERRCODE = '22023';
    END IF;
  ELSE
    SELECT * INTO v_r FROM public.recharges_recapitulatifs
     WHERE id = p_recapitulatif AND titulaire = auth.uid();
    IF v_r.id IS NULL THEN
      RAISE EXCEPTION 'recapitulatif introuvable' USING ERRCODE = 'P0002';
    END IF;
    IF v_r.expire_le < pg_catalog.now() OR EXISTS (
         SELECT 1 FROM public.commandes_recharge WHERE recapitulatif_id = v_r.id) THEN
      RAISE EXCEPTION 'recapitulatif perime' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.commandes_recharge
      (id, reference, recapitulatif_id, titulaire, household_id, cle, devise, total_mineur)
    VALUES (v_id, 'RWY-' || pg_catalog.upper(pg_catalog.substr(pg_catalog.md5(v_id::text), 1, 8)),
            v_r.id, auth.uid(), v_r.household_id, p_cle, v_r.devise, v_r.total_mineur)
    RETURNING * INTO v_c;
    INSERT INTO public.commandes_recharge_allocations (commande_id, rang, profile_id, montant_mineur)
    SELECT v_c.id, l.rang, l.profile_id, l.montant_mineur
      FROM public.recharges_recap_lignes l WHERE l.recapitulatif_id = v_r.id;
    PERFORM public.log_sensitive_access('recharge_commandee', 'commandes_recharge', v_c.id::text,
      pg_catalog.jsonb_build_object('total_mineur', v_c.total_mineur, 'devise', v_c.devise));
  END IF;
  RETURN private.rch_suivi_json(v_c.id) || pg_catalog.jsonb_build_object(
    'urlPaiement', CASE WHEN v_c.etat = 'awaiting_confirmation' THEN v_c.url_paiement END,
    'lignesPaiement', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                         'prenom', p.first_name, 'mineur', a.montant_mineur) ORDER BY a.rang)
                         FROM public.commandes_recharge_allocations a
                         JOIN public.profiles p ON p.id = a.profile_id
                        WHERE a.commande_id = v_c.id));
END;
$function$;

-- L'etat d'une commande du titulaire.
CREATE FUNCTION public.recharge_suivre(p_commande uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'recharge reservee au titulaire du foyer' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.commandes_recharge
                  WHERE id = p_commande AND titulaire = auth.uid()) THEN
    RAISE EXCEPTION 'commande introuvable' USING ERRCODE = 'P0002';
  END IF;
  RETURN private.rch_suivi_json(p_commande);
END;
$function$;

-- Serveur seulement : la session ouverte chez le prestataire pour la
-- commande. La commande attend alors la confirmation du prestataire.
CREATE FUNCTION public.recharge_attacher_session(
  p_commande uuid, p_titulaire uuid, p_session text, p_url text, p_environnement text)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF p_session IS NULL OR p_url IS NULL OR p_environnement NOT IN ('test', 'live') THEN
    RAISE EXCEPTION 'session invalide' USING ERRCODE = '22023';
  END IF;
  UPDATE public.commandes_recharge
     SET session_prestataire = p_session, url_paiement = p_url, environnement = p_environnement,
         etat = 'awaiting_confirmation'
   WHERE id = p_commande AND titulaire = p_titulaire AND etat = 'preparing';
  IF NOT FOUND AND NOT EXISTS (SELECT 1 FROM public.commandes_recharge
                                WHERE id = p_commande AND session_prestataire = p_session) THEN
    RAISE EXCEPTION 'commande introuvable ou deja partie' USING ERRCODE = 'P0002';
  END IF;
END;
$function$;

-- Serveur seulement : un evenement Stripe deja verifie (signature) par la
-- fonction Edge `stripe-webhook`. Chaque evenement n'est traite qu'une fois ;
-- seul un paiement encaisse, du montant et de la devise de la commande,
-- credite chaque profil de sa part. Rend l'issue.
CREATE FUNCTION public.recharge_evenement_stripe(
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
      -- Double confirmation : un seul credit.
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
        PERFORM private.fac_emettre_facture(a.profile_id, private.fac_mois_courant(), v_c.titulaire);
        PERFORM private.fac_financer_profil(a.profile_id);
      END LOOP;
      UPDATE public.commandes_recharge SET etat = 'completed', termine_le = pg_catalog.clock_timestamp()
       WHERE id = v_c.id;
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

DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.rch_beneficiaire(uuid)'::regprocedure,
    'private.rch_devise(uuid)'::regprocedure,
    'private.rch_montants(uuid)'::regprocedure,
    'private.rch_suivi_json(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.recharge_beneficiaires()'::regprocedure,
    'public.recharge_verifier_montants(jsonb)'::regprocedure,
    'public.recharge_payer(uuid,uuid)'::regprocedure,
    'public.recharge_suivre(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_GUARDIAN_TITULAIRE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FI-BR-06.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.recharge_attacher_session(uuid,uuid,text,text,text)'::regprocedure,
    'public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SERVICE_ROLE_ONLY_EDGE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FI-BR-06.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.recharge_beneficiaires()'::regprocedure,
    'public.recharge_verifier_montants(jsonb)'::regprocedure,
    'public.recharge_payer(uuid,uuid)'::regprocedure,
    'public.recharge_suivre(uuid)'::regprocedure] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FI-BR-06 : ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.recharge_attacher_session(uuid,uuid,text,text,text)'::regprocedure,
    'public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FI-BR-06 : % doit rester au serveur', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'rch\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FI-BR-06 : aide privee executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
