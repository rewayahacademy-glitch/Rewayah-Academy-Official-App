-- RIEN-DE-GRATUIT (directeur, 27/11/2026 : « la logique elle-meme doit etre revue pour etre sur que tu ne
-- distribues rien gratuitement »). Audit de la facturation en production ; deux fuites prouvees, corrigees ici.
-- Aucun paiement encaisse ni remboursement fait a ce jour (0 commande completee) : rien n'a ete perdu.
--
-- 1. Le mois d'entree n'etait jamais facture. `fac_emission_planifiee` n'emettait les factures du mois courant
--    que du 1er au 3 du mois (avant le jour de suspension) ; `paiement.premier_avant_cours` est a false, donc
--    l'entree en classe n'emet rien non plus. Un eleve entre en classe le 10 suivait le reste du mois sans
--    facture, et sans suspension (une suspension ne vise qu'une facture emise). Desormais le mois courant est
--    emis chaque jour pour tout eleve en classe qui n'a pas encore sa facture (au prorata de ses seances,
--    `fac_mensualite`) ; l'emission reste idempotente (une facture par eleve et par mois). Le delai de 3 jours
--    d'un premier paiement ne change pas : au-dela, l'acces est suspendu jusqu'au paiement.
--
-- 2. Le remboursement dans le delai legal se calculait mal (`fn115c_montant_propose`) :
--    - il ne retirait que les seances suivies APRES le paiement : une famille qui suivait trois semaines de
--      cours, payait puis demandait le remboursement recuperait presque tout ;
--    - il comptait la seance au tarif / 13 (`seances_par_mois` de la politique), alors que les classes ont
--      environ 8 seances par mois : chaque seance suivie etait sous-comptee d'un tiers ;
--    - il s'appliquait a chaque paiement, alors que le delai de 14 jours vaut pour un nouvel inscrit
--      (A-HARMONISER-REGLES-ARGENT-ET-ARRET : « 14 jours legaux pour les nouveaux inscrits »).
--    Desormais : le delai ne vaut que pour le PREMIER paiement du profil ; toutes les seances suivies par le
--    profil sont retirees (le premier paiement couvre aussi celles d'avant) ; chaque seance vaut le prix
--    mensuel du profil (remise de famille comprise, la meme que sa facture) divise par le nombre reel de
--    seances de sa classe ce mois-la (`rch_seances_mois`, repli sur la politique). Les paiements suivants
--    suivent la regle du paiement d'avance (mois commences retires) ou ne sont pas remboursables.
--    La direction confirme toujours elle-meme chaque remboursement ; cette fonction ne fait que proposer.
--
-- Aucune suppression ; aucune donnee de personne modifiee.

CREATE OR REPLACE FUNCTION private.fac_emission_planifiee(p_jour date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_courant date;
  v_suivant date;
  v_p_courant public.politiques_commerciales;
  v_p_suivant public.politiques_commerciales;
  v_avance integer;
  v_res jsonb := '[]'::jsonb;
BEGIN
  IF p_jour IS NULL THEN
    RAISE EXCEPTION 'jour absent' USING ERRCODE = '22023';
  END IF;
  v_courant := pg_catalog.date_trunc('month', p_jour)::date;
  v_suivant := (v_courant + interval '1 month')::date;
  v_p_courant := private.fac_politique_au(v_courant);
  v_p_suivant := private.fac_politique_au(v_suivant);

  -- Le mois courant : chaque jour (RIEN-DE-GRATUIT). Un eleve entre en classe en cours de mois recoit sa
  -- facture au prorata le jour meme ; celui qui l'a deja n'en recoit pas une seconde.
  IF v_p_courant.version IS NOT NULL THEN
    v_res := v_res || pg_catalog.jsonb_build_array(
      private.fac_emettre_factures_du_mois(v_courant, NULL));
  END IF;

  -- Le mois suivant : des la plus grande avance de relance de sa politique.
  IF v_p_suivant.version IS NOT NULL THEN
    SELECT max(j) INTO v_avance FROM pg_catalog.unnest(v_p_suivant.jours_relance) AS j;
    IF v_avance IS NOT NULL AND v_avance > 0 AND p_jour >= v_suivant - v_avance THEN
      v_res := v_res || pg_catalog.jsonb_build_array(
        private.fac_emettre_factures_du_mois(v_suivant, NULL));
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object('jour', pg_catalog.to_char(p_jour, 'YYYY-MM-DD'),
    'emissions', v_res);
END;
$function$;

CREATE OR REPLACE FUNCTION private.fn115c_montant_propose(p_commande uuid, p_profil uuid)
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
  v_prix_seance bigint := 0;
  v_deduit bigint := 0;
  v_suivies integer := 0;
  v_mois integer := 0;
  v_jours integer;
  v_regle text;
  v_montant bigint := 0;
  v_premier boolean;
BEGIN
  SELECT * INTO v_c FROM public.commandes_recharge WHERE id = p_commande;
  SELECT * INTO v_a FROM public.commandes_recharge_allocations
   WHERE commande_id = p_commande AND profile_id = p_profil;
  IF v_c.id IS NULL OR v_a.commande_id IS NULL OR v_c.etat <> 'completed'
     OR v_a.entry_id IS NULL OR v_c.paiement_prestataire IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('montant_mineur', 0, 'regle', 'non_remboursable');
  END IF;

  v_paye := v_a.montant_mineur;
  SELECT coalesce(sum(w.amount_minor), 0) INTO v_rendu FROM public.wallet_entries w
   WHERE w.refund_of_entry_id = v_a.entry_id AND w.reference_type = 'refund';
  SELECT coalesce(sum(d.montant_mineur), 0) INTO v_en_cours FROM public.remboursements_demandes d
   WHERE d.commande_id = p_commande AND d.profile_id = p_profil
     AND d.etat IN ('confirmee', 'envoyee');
  v_reste := GREATEST(v_paye - v_rendu - v_en_cours, 0);

  v_p := private.fac_politique_au((coalesce(v_c.confirme_le, v_c.cree_le))::date);
  v_mensuel := coalesce(private.fac_tarif_profil(p_profil, v_p), 0);
  v_jours := (pg_catalog.now()::date - (coalesce(v_c.confirme_le, v_c.cree_le))::date);
  -- Le delai legal vaut pour un nouvel inscrit : le premier paiement complete du profil.
  v_premier := NOT EXISTS (
    SELECT 1 FROM public.commandes_recharge_allocations a2
      JOIN public.commandes_recharge c2 ON c2.id = a2.commande_id
     WHERE a2.profile_id = p_profil AND c2.etat = 'completed' AND c2.id <> v_c.id
       AND (coalesce(c2.confirme_le, c2.cree_le), c2.id) < (coalesce(v_c.confirme_le, v_c.cree_le), v_c.id));

  IF v_premier AND v_jours <= v_p.remboursement_delai_jours THEN
    -- Toutes les seances suivies par le profil (le premier paiement couvre aussi celles d'avant lui), chacune
    -- au prix mensuel du profil (remise de famille comprise) divise par le nombre reel de seances de sa classe
    -- ce mois-la.
    SELECT count(*)::integer,
           coalesce(sum(pg_catalog.round(
             (v_mensuel + coalesce(private.fac_remise_montant(v_p,
                 private.fac_rang_inscription(p_profil, pg_catalog.date_trunc('month', s.started_at)::date),
                 v_mensuel), 0))::numeric
             / GREATEST(coalesce(nullif((SELECT count(*) FROM private.rch_seances_mois(s.groupe_id,
                 pg_catalog.date_trunc('month', s.started_at)::date)), 0), v_p.seances_par_mois, 1), 1))), 0)::bigint
      INTO v_suivies, v_deduit
      FROM (SELECT DISTINCT ON (x.id) x.id, x.started_at, x.groupe_id
              FROM public.session_participants sp
              JOIN public.sessions x ON x.id = sp.session_id
             WHERE sp.profile_id = p_profil AND sp.role = 'student'
               AND sp.deleted_at IS NULL AND sp.entered_at IS NOT NULL
               AND x.deleted_at IS NULL) s;
    v_prix_seance := CASE WHEN v_suivies > 0 THEN v_deduit / v_suivies ELSE 0 END;
    v_regle := 'delai';
    v_montant := GREATEST(v_paye - v_deduit - v_rendu - v_en_cours, 0);
  ELSE
    SELECT * INTO v_e FROM public.engagements_prepaiement
     WHERE commande_id = p_commande AND profile_id = p_profil
     ORDER BY cree_le DESC LIMIT 1;
    IF v_e.id IS NOT NULL THEN
      v_mois := LEAST(GREATEST(
        (EXTRACT(YEAR FROM pg_catalog.age(pg_catalog.date_trunc('month', pg_catalog.now())::date, v_e.mois_debut))::integer * 12
         + EXTRACT(MONTH FROM pg_catalog.age(pg_catalog.date_trunc('month', pg_catalog.now())::date, v_e.mois_debut))::integer
         + 1), 0), v_e.nb_mois);
      v_regle := 'prepaiement';
      v_montant := GREATEST(v_e.total_mineur - v_mois * coalesce(v_e.prix_mensuel_mineur, v_mensuel)
                            - v_rendu - v_en_cours, 0);
    ELSE
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
    'seances_deduites_mineur', v_deduit,
    'mois_commences', v_mois,
    'prix_mensuel_mineur', v_mensuel,
    'jours_depuis_paiement', v_jours,
    'delai_jours', v_p.remboursement_delai_jours,
    'politique', v_p.version);
END;
$function$;
