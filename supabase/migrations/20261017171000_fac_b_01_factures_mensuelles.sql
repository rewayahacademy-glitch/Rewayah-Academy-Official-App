-- FAC-B-01 (17/10/2026) : factures mensuelles, essai, financement et etat
-- financier par profil (FI-BR-03, FI-BR-08, FI-BR-09 ; guide Finance V4
-- §1.1, §1.2, §1.3, §1.7, §5.1, §5.2 ; lot B de 07_MEMOIRE_PEDAGOGIE_FINANCE ;
-- passation du 17/10, point 2). Remplace la regle provisoire d'etat de
-- 20261017160100 (bf1_02), fondee sur le solde seul.
--
-- Regles (toutes en SQL, aucune dans Flutter ; montants lus dans la politique
-- de FAC-A-01 en vigueur au premier jour du mois facture) :
-- * une facture par eleve et par mois civil (FIN4-02, FIN4-03), jamais par
--   seance ; une facture emise ne change plus (lignes et total figes avec le
--   numero de politique) : seuls passent « a financer » -> « financee » ou
--   « annulee » ;
-- * lignes : tarif enfant ou adulte (`student_type`), remise de rang du foyer
--   (guide §1.3 ; le rang est l'ordre d'emission parmi les membres payants du
--   mois, jamais reecrit), prorata du premier mois payant : M x E / O, ou O
--   est le nombre de seances non annulees de la classe dans le mois et E celles
--   accessibles apres l'entree et l'essai ; O = 0 donne 0 (dossier maitre §3.4).
--   Aucune taxe ni plancher de fermeture : aucun taux ni plancher n'est encore
--   decide pour une version publiee ;
-- * essai (FIN4-10 a FIN4-17) : tant que l'essai est actif dans la politique,
--   que l'eleve n'a jamais recu de paiement et qu'il a consomme moins de
--   seances d'essai que le maximum, aucune facture. Une seance tenue consomme l'essai, absence de l'eleve comprise ;
--   annulee, panne ou enseignant absent ne le consomment pas ;
-- * financement : une facture se finance en une fois par une ecriture `debit`
--   du profil, seulement si le solde compte du profil la couvre (FIN4-09 :
--   aucun debit partiel). Une facture a zero est financee sans ecriture ;
-- * etat (guide §5.1) : en confirmation si un credit attend le prestataire ;
--   finance si le mois courant est finance (manque si le mois suivant est
--   emis et non couvert) ; a regulariser si le mois courant est emis et non
--   finance, place conservee jusqu'au premier du mois + jours de conservation
--   de la politique (§1.7) ; expire apres ; essai pendant l'essai ; sans
--   facture : l'ancienne lecture (solde, acces date).
--
-- Emission : `emettre_factures_mois(mois)` par la direction ou la
-- comptabilite, pour le mois courant ou le suivant, idempotente ; elle cree
-- le portefeuille du foyer dans la devise de la politique s'il manque.
BEGIN;

CREATE TABLE public.factures_mensuelles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  household_id uuid NOT NULL REFERENCES public.households(id),
  mois date NOT NULL CHECK (mois = pg_catalog.date_trunc('month', mois)::date),
  politique_version text NOT NULL REFERENCES public.politiques_commerciales(version),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  rang_familial integer CHECK (rang_familial >= 1),
  lignes jsonb NOT NULL CHECK (jsonb_typeof(lignes) = 'array'),
  total_mineur bigint NOT NULL CHECK (total_mineur >= 0),
  statut text NOT NULL DEFAULT 'a_financer' CHECK (statut IN ('a_financer', 'financee', 'annulee')),
  emise_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  emise_par uuid REFERENCES public.profiles(id),
  financee_le timestamptz,
  debit_entry_id bigint REFERENCES public.wallet_entries(id),
  annulee_le timestamptz,
  annulee_par uuid REFERENCES public.profiles(id),
  motif_annulation text,
  CONSTRAINT factures_mensuelles_financement CHECK (
    (statut = 'financee') = (financee_le IS NOT NULL)
    AND (debit_entry_id IS NULL OR statut = 'financee')
    AND (statut <> 'financee' OR total_mineur = 0 OR debit_entry_id IS NOT NULL)),
  CONSTRAINT factures_mensuelles_annulation CHECK (
    (statut = 'annulee') = (annulee_le IS NOT NULL))
);
CREATE UNIQUE INDEX factures_mensuelles_une_par_mois
  ON public.factures_mensuelles (profile_id, mois) WHERE statut <> 'annulee';
CREATE INDEX factures_mensuelles_foyer_mois ON public.factures_mensuelles (household_id, mois);
COMMENT ON TABLE public.factures_mensuelles IS
  'FAC-B-01: une facture par eleve et par mois civil, figee a l''emission (politique, lignes, total). Seul le statut avance.';

ALTER TABLE public.factures_mensuelles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.factures_mensuelles FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.factures_mensuelles TO authenticated;
CREATE POLICY factures_mensuelles_lecture_direction ON public.factures_mensuelles
  FOR SELECT TO authenticated
  USING (coalesce((SELECT public.app_role()) IN ('admin', 'accountant')
                  AND (SELECT public.app_account_valid()), false));

-- Une facture emise ne change plus : seul le statut avance, une seule fois.
CREATE FUNCTION private.fac_facture_figee()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'une facture emise ne se supprime pas : l''annuler' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['statut','financee_le','debit_entry_id','annulee_le','annulee_par','motif_annulation'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['statut','financee_le','debit_entry_id','annulee_le','annulee_par','motif_annulation'])
     OR OLD.statut <> 'a_financer'
     OR NEW.statut NOT IN ('financee', 'annulee') THEN
    RAISE EXCEPTION 'une facture emise ne change plus ; seul son statut avance' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.fac_facture_figee() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.fac_facture_figee() FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER factures_mensuelles_figee
  BEFORE UPDATE OR DELETE ON public.factures_mensuelles
  FOR EACH ROW EXECUTE FUNCTION private.fac_facture_figee();

-- ---------------------------------------------------------------------------
-- Aides (aucun droit client).
-- ---------------------------------------------------------------------------

-- Le mois courant (premier jour) dans le fuseau comptable.
CREATE FUNCTION private.fac_mois_courant()
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.date_trunc('month', private.fac_aujourdhui())::date;
$function$;

-- Une seance qui consomme l'essai : tenue par Rewayah, eleve present ou non
-- (FIN4-17).
CREATE FUNCTION private.fac_seance_tenue(p_statut public.session_status)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT p_statut IN ('in_progress', 'ended', 'student_absent');
$function$;

-- Les seances d'essai consommees par l'eleve, dans l'ordre (au plus p_max).
CREATE FUNCTION private.fac_seances_essai(p_profil uuid, p_max integer)
RETURNS TABLE (session_id uuid)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT s.id
    FROM public.sessions s
    JOIN public.session_participants sp ON sp.session_id = s.id
   WHERE sp.profile_id = p_profil AND sp.role = 'student'
     AND s.deleted_at IS NULL AND private.fac_seance_tenue(s.status)
   ORDER BY s.started_at, s.id
   LIMIT greatest(p_max, 0);
$function$;

-- Vrai tant que l'eleve est en essai sous la politique p : aucune facture
-- emise, aucun paiement deja recu pour lui (un eleve deja paye, inscrit avant
-- FAC-B ou qui paie pendant l'essai, est un membre payant), et moins de
-- seances d'essai consommees que le maximum.
CREATE FUNCTION private.fac_en_essai(p_profil uuid, p public.politiques_commerciales)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(p.essai_actif, false) AND p.essais_max > 0
     AND NOT EXISTS (SELECT 1 FROM public.factures_mensuelles f
                      WHERE f.profile_id = p_profil AND f.statut <> 'annulee')
     AND NOT EXISTS (SELECT 1 FROM public.wallet_entries e
                      WHERE e.beneficiaire_id = p_profil AND e.reference_type = 'credit')
     AND (SELECT count(*) FROM private.fac_seances_essai(p_profil, p.essais_max)) < p.essais_max;
$function$;

-- La classe active de l'eleve au mois p_mois (la plus recente adhesion), ou
-- nulle.
CREATE FUNCTION private.fac_adhesion(p_profil uuid, p_mois date)
RETURNS public.groupe_membres
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT m.* FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id
   WHERE m.student_id = p_profil
     AND m.joined_at < (p_mois + interval '1 month')
     AND (m.left_at IS NULL OR m.left_at >= p_mois)
     AND (g.ended_at IS NULL OR g.ended_at >= p_mois)
   ORDER BY m.joined_at DESC, m.id
   LIMIT 1;
$function$;

-- Les lignes et le total de la mensualite d'un eleve pour p_mois sous p, au
-- rang p_rang (nul : rang sans remise), avec le prorata du premier mois payant
-- quand p_premier est vrai. Rend {lignes, total}.
CREATE FUNCTION private.fac_mensualite(
  p_profil uuid, p_mois date, p public.politiques_commerciales,
  p_rang integer, p_premier boolean)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_adulte boolean;
  v_tarif bigint;
  v_remise bigint;
  v_base bigint;
  v_lignes jsonb;
  v_adh public.groupe_membres;
  v_o integer;
  v_e integer;
  v_prorata bigint := 0;
BEGIN
  SELECT sp.student_type = 'autonomous' INTO v_adulte
    FROM public.student_profiles sp WHERE sp.profile_id = p_profil;
  v_tarif := CASE WHEN coalesce(v_adulte, false) THEN p.tarif_adulte_mineur ELSE p.tarif_enfant_mineur END;
  v_remise := CASE WHEN p_rang IS NULL THEN NULL ELSE private.fac_remise_rang(p, p_rang) END;
  v_base := greatest(v_tarif + coalesce(v_remise, 0), 0);
  v_lignes := pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nature', 'tarif', 'montant', private.bf1_montant(v_tarif, p.devise), 'rang', NULL));
  IF v_remise IS NOT NULL THEN
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nature', 'remise_rang', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', p_rang));
  END IF;

  IF p_premier THEN
    v_adh := private.fac_adhesion(p_profil, p_mois);
    SELECT count(*) FILTER (WHERE TRUE),
           count(*) FILTER (WHERE s.started_at >= coalesce(v_adh.joined_at, '-infinity'::timestamptz)
                              AND s.id NOT IN (SELECT e.session_id
                                                 FROM private.fac_seances_essai(p_profil, p.essais_max) e))
      INTO v_o, v_e
      FROM public.sessions s
     WHERE s.groupe_id = v_adh.groupe_id AND s.deleted_at IS NULL
       AND s.status NOT IN ('canceled', 'canceled_late')
       AND s.started_at >= p_mois AND s.started_at < (p_mois + interval '1 month');
    IF v_o = 0 THEN
      v_prorata := -v_base;
    ELSIF v_e < v_o THEN
      v_prorata := (v_base * v_e / v_o) - v_base;
    END IF;
    IF v_prorata <> 0 THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'nature', 'prorata', 'montant', private.bf1_montant(v_prorata, p.devise), 'rang', NULL));
    END IF;
  END IF;
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'total', v_base + v_prorata);
END;
$function$;

-- Le portefeuille du foyer, cree dans la devise p_devise s'il manque ; une
-- autre devise est refusee (aucun change invente).
CREATE FUNCTION private.fac_portefeuille(p_foyer uuid, p_devise text)
RETURNS public.wallets
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.wallets;
BEGIN
  SELECT w.* INTO v FROM public.wallets w WHERE w.household_id = p_foyer;
  IF v.id IS NULL THEN
    INSERT INTO public.wallets (household_id, currency) VALUES (p_foyer, p_devise)
    RETURNING * INTO v;
  ELSIF v.currency <> p_devise THEN
    RAISE EXCEPTION 'le portefeuille du foyer est dans une autre devise' USING ERRCODE = '22023';
  END IF;
  RETURN v;
END;
$function$;

-- Le solde compte d'un profil (credits confirmes, debits, avoirs).
CREATE FUNCTION private.fac_solde_profil(p_profil uuid)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(sum(private.bf1_montant_signe(e.reference_type, e.amount_minor))
           FILTER (WHERE private.bf1_compte(e.reference_type, e.confirme_par_prestataire_le)), 0)::bigint
    FROM public.wallet_entries e WHERE e.beneficiaire_id = p_profil;
$function$;

-- Finance, dans l'ordre des mois, les factures du profil que le solde couvre
-- en entier (FIN4-09) ; s'arrete a la premiere qu'il ne couvre pas. Rend le
-- nombre de factures financees.
CREATE FUNCTION private.fac_financer_profil(p_profil uuid)
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
  END LOOP;
  RETURN v_n;
END;
$function$;

-- Emet la facture d'un eleve pour p_mois si elle manque et qu'il n'est plus en
-- essai ; rend vrai quand une facture est emise. Appelee par l'emission du
-- mois (et par la saisie d'un paiement, FAC-C).
CREATE FUNCTION private.fac_emettre_facture(p_profil uuid, p_mois date, p_par uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_p public.politiques_commerciales := private.fac_politique_au(p_mois);
  v_foyer uuid;
  v_rang integer;
  v_premier boolean;
  v_calcul jsonb;
BEGIN
  IF v_p.version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur ce mois' USING ERRCODE = 'P0002';
  END IF;
  SELECT pr.household_id INTO v_foyer
    FROM public.profiles pr JOIN public.student_profiles sp ON sp.profile_id = pr.id
   WHERE pr.id = p_profil AND pr.deleted_at IS NULL AND sp.deleted_at IS NULL;
  IF v_foyer IS NULL OR (private.fac_adhesion(p_profil, p_mois)).id IS NULL
     OR private.fac_en_essai(p_profil, v_p) THEN
    RETURN false;
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'facturation:' || v_foyer::text || ':' || p_mois::text, 0));
  IF EXISTS (SELECT 1 FROM public.factures_mensuelles f
              WHERE f.profile_id = p_profil AND f.mois = p_mois AND f.statut <> 'annulee') THEN
    RETURN false;
  END IF;
  PERFORM private.fac_portefeuille(v_foyer, v_p.devise);
  v_rang := 1 + (SELECT count(*) FROM public.factures_mensuelles f
                  WHERE f.household_id = v_foyer AND f.mois = p_mois AND f.statut <> 'annulee');
  v_premier := NOT EXISTS (SELECT 1 FROM public.factures_mensuelles f
                            WHERE f.profile_id = p_profil AND f.statut <> 'annulee');
  v_calcul := private.fac_mensualite(p_profil, p_mois, v_p, v_rang, v_premier);
  INSERT INTO public.factures_mensuelles
    (profile_id, household_id, mois, politique_version, devise, rang_familial, lignes, total_mineur, emise_par)
  VALUES (p_profil, v_foyer, p_mois, v_p.version, v_p.devise, v_rang,
          v_calcul -> 'lignes', (v_calcul ->> 'total')::bigint, p_par);
  RETURN true;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Emission du mois (direction ou comptabilite).
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.emettre_factures_mois(p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_courant date := private.fac_mois_courant();
  v_profil uuid;
  v_emises integer := 0;
  v_financees integer := 0;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() IN ('admin', 'accountant')
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'emission des factures reservee a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  IF p_mois IS NULL OR p_mois <> pg_catalog.date_trunc('month', p_mois)::date
     OR p_mois NOT IN (v_courant, (v_courant + interval '1 month')::date) THEN
    RAISE EXCEPTION 'seuls le mois courant et le suivant se facturent' USING ERRCODE = '22023';
  END IF;
  IF (private.fac_politique_au(p_mois)).version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur ce mois' USING ERRCODE = 'P0002';
  END IF;
  FOR v_profil IN
    SELECT pr.id FROM public.profiles pr
      JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
     WHERE pr.deleted_at IS NULL AND pr.household_id IS NOT NULL
     ORDER BY pr.household_id, pr.created_at, pr.id
  LOOP
    IF private.fac_emettre_facture(v_profil, p_mois, auth.uid()) THEN
      v_emises := v_emises + 1;
    END IF;
    v_financees := v_financees + private.fac_financer_profil(v_profil);
  END LOOP;
  PERFORM public.log_sensitive_access('factures_mois_emises', 'factures_mensuelles', p_mois::text,
    pg_catalog.jsonb_build_object('emises', v_emises, 'financees', v_financees));
  RETURN pg_catalog.jsonb_build_object('mois', pg_catalog.to_char(p_mois, 'YYYY-MM-DD'),
    'emises', v_emises, 'financees', v_financees);
END;
$function$;

-- ---------------------------------------------------------------------------
-- L'etat financier d'un profil : remplace la regle provisoire de bf1_02.
-- Meme signature et meme forme rendue (FinancesProfil).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.bf1_finance_profil(p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_p public.profiles%ROWTYPE;
  v_sp public.student_profiles%ROWTYPE;
  v_w public.wallets%ROWTYPE;
  v_n integer;
  v_autres integer;
  v_attente integer;
  v_solde bigint;
  v_etat text;
  v_classe text;
  v_mois date := private.fac_mois_courant();
  v_suivant date := (private.fac_mois_courant() + interval '1 month')::date;
  v_cur public.factures_mensuelles;
  v_next public.factures_mensuelles;
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
  v_essai boolean;
  v_essais integer;
  v_devise text;
  v_lignes jsonb := '[]'::jsonb;
  v_mensualite bigint := 0;
  v_periode jsonb;
  v_debit jsonb;
  v_manque bigint;
  v_conservation date;
  v_fin_financee date;
  v_estime jsonb;
  v_passee boolean;
BEGIN
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = p_profil AND p.deleted_at IS NULL;
  SELECT sp.* INTO v_sp FROM public.student_profiles sp
   WHERE sp.profile_id = p_profil AND sp.deleted_at IS NULL;
  IF v_p.id IS NULL OR v_sp.profile_id IS NULL OR v_p.household_id IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT w.* INTO v_w FROM public.wallets w WHERE w.household_id = v_p.household_id;

  SELECT f.* INTO v_cur FROM public.factures_mensuelles f
   WHERE f.profile_id = p_profil AND f.mois = v_mois AND f.statut <> 'annulee';
  SELECT f.* INTO v_next FROM public.factures_mensuelles f
   WHERE f.profile_id = p_profil AND f.mois = v_suivant AND f.statut <> 'annulee';
  v_essai := v_pol.version IS NOT NULL AND private.fac_en_essai(p_profil, v_pol)
             AND (private.fac_adhesion(p_profil, v_mois)).id IS NOT NULL;
  v_devise := coalesce(v_w.currency, v_cur.devise, v_pol.devise);

  IF v_w.id IS NULL AND v_cur.id IS NULL AND NOT v_essai THEN
    RETURN NULL;
  END IF;

  SELECT count(*)::integer,
         (count(*) FILTER (WHERE e.currency <> v_devise))::integer,
         (count(*) FILTER (WHERE e.reference_type = 'credit' AND e.confirme_par_prestataire_le IS NULL))::integer,
         coalesce(sum(private.bf1_montant_signe(e.reference_type, e.amount_minor))
           FILTER (WHERE private.bf1_compte(e.reference_type, e.confirme_par_prestataire_le)), 0)::bigint
    INTO v_n, v_autres, v_attente, v_solde
    FROM public.wallet_entries e WHERE e.beneficiaire_id = p_profil;
  IF v_autres > 0 THEN
    RAISE EXCEPTION 'finances du profil en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  v_passee := EXISTS (SELECT 1 FROM public.factures_mensuelles f
                       WHERE f.profile_id = p_profil AND f.statut = 'financee' AND f.mois < v_mois);
  IF v_n = 0 AND v_p.access_until IS NULL AND v_cur.id IS NULL AND NOT v_essai AND NOT v_passee THEN
    RETURN NULL;
  END IF;

  IF v_cur.id IS NOT NULL AND v_cur.statut = 'financee' THEN
    -- La periode financee court du mois courant au dernier mois finance consecutif.
    v_fin_financee := v_mois;
    WHILE EXISTS (SELECT 1 FROM public.factures_mensuelles f
                   WHERE f.profile_id = p_profil AND f.statut = 'financee'
                     AND f.mois = (v_fin_financee + interval '1 month')::date) LOOP
      v_fin_financee := (v_fin_financee + interval '1 month')::date;
    END LOOP;
    v_periode := pg_catalog.jsonb_build_object(
      'debut', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'),
      'fin', pg_catalog.to_char((v_fin_financee + interval '1 month' - interval '1 day')::date, 'YYYY-MM-DD'));
    IF v_next.id IS NOT NULL AND v_next.statut = 'a_financer' THEN
      v_etat := 'manque';
      v_manque := v_next.total_mineur - greatest(v_solde, 0);
      v_lignes := v_next.lignes; v_mensualite := v_next.total_mineur;
      v_debit := pg_catalog.jsonb_build_object('date', pg_catalog.to_char(v_suivant, 'YYYY-MM-DD'),
        'montant', private.bf1_montant(v_next.total_mineur, v_next.devise));
    ELSE
      v_etat := 'finance';
      v_lignes := v_cur.lignes; v_mensualite := v_cur.total_mineur;
      IF v_next.id IS NULL AND v_pol.version IS NOT NULL THEN
        v_estime := private.fac_mensualite(p_profil, v_suivant,
          coalesce(private.fac_politique_au(v_suivant), v_pol), v_cur.rang_familial, false);
        v_debit := pg_catalog.jsonb_build_object(
          'date', pg_catalog.to_char((v_fin_financee + interval '1 month')::date, 'YYYY-MM-DD'),
          'montant', private.bf1_montant((v_estime ->> 'total')::bigint, v_devise));
      END IF;
    END IF;
  ELSIF v_cur.id IS NOT NULL THEN
    v_conservation := (v_mois + pg_catalog.make_interval(days => coalesce(
      (SELECT p.jours_conservation_place FROM public.politiques_commerciales p
        WHERE p.version = v_cur.politique_version), 0)))::date;
    v_etat := CASE WHEN private.fac_aujourdhui() <= v_conservation THEN 'a_regulariser' ELSE 'expire' END;
    v_manque := v_cur.total_mineur - greatest(v_solde, 0);
    -- Aucun prochain debit annonce : le mois du est passe, le manque et la
    -- mensualite disent deja ce qui reste a financer.
    v_lignes := v_cur.lignes; v_mensualite := v_cur.total_mineur;
  ELSIF v_essai THEN
    v_etat := 'essai';
    v_essais := (SELECT count(*) FROM private.fac_seances_essai(p_profil, v_pol.essais_max))::integer;
  ELSIF v_passee THEN
    v_etat := 'expire';
  ELSE
    -- Sans facture : la lecture d'avant FAC-B (solde et acces date).
    v_etat := CASE
      WHEN v_p.access_until IS NOT NULL AND v_p.access_until <= pg_catalog.now() THEN 'expire'
      WHEN v_solde < 0 THEN 'manque'
      ELSE 'finance' END;
    IF v_etat = 'manque' THEN v_manque := -v_solde; END IF;
  END IF;
  IF v_attente > 0 THEN
    v_etat := 'en_confirmation';
  END IF;

  SELECT g.libelle INTO v_classe FROM public.groupe_membres m
    JOIN public.groupes g ON g.id = m.groupe_id
   WHERE m.student_id = p_profil AND m.left_at IS NULL AND g.ended_at IS NULL
   ORDER BY m.joined_at DESC LIMIT 1;

  RETURN pg_catalog.jsonb_build_object(
    'profilId', v_p.id,
    'prenom', v_p.first_name,
    'cleAccent', v_p.id::text,
    'estAdulte', v_sp.student_type = 'autonomous',
    'cleAvatar', v_sp.avatar_storage_key,
    'classe', v_classe,
    'age', NULL,
    'etat', v_etat,
    'solde', private.bf1_montant(v_solde, v_devise),
    'periode', v_periode,
    'prochainDebit', v_debit,
    'mensualite', private.bf1_montant(v_mensualite, v_devise),
    'lignesMensualite', v_lignes,
    'essaisUtilises', v_essais,
    'manque', CASE WHEN v_etat IN ('manque', 'a_regulariser', 'expire')
                        AND v_manque IS NOT NULL AND v_manque > 0
                   THEN private.bf1_montant(v_manque, v_devise) END,
    'finConservation', CASE WHEN v_conservation IS NULL THEN NULL
                            ELSE pg_catalog.to_char(v_conservation, 'YYYY-MM-DD') END);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Proprietaire, droits, empreintes.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_mois_courant()'::regprocedure,
    'private.fac_seance_tenue(public.session_status)'::regprocedure,
    'private.fac_seances_essai(uuid,integer)'::regprocedure,
    'private.fac_en_essai(uuid,public.politiques_commerciales)'::regprocedure,
    'private.fac_adhesion(uuid,date)'::regprocedure,
    'private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)'::regprocedure,
    'private.fac_portefeuille(uuid,text)'::regprocedure,
    'private.fac_solde_profil(uuid)'::regprocedure,
    'private.fac_financer_profil(uuid)'::regprocedure,
    'private.fac_emettre_facture(uuid,date,uuid)'::regprocedure,
    'private.bf1_finance_profil(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  v_oid := 'public.emettre_factures_mois(date)'::regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_OR_ACCOUNTANT; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17. FAC-B-01 : emission idempotente du mois courant ou suivant.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.emettre_factures_mois(date)'::regprocedure AND p.prosecdef
                    AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.emettre_factures_mois(date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.emettre_factures_mois(date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.emettre_factures_mois(date)', 'EXECUTE') THEN
    RAISE EXCEPTION 'FAC-B-01 : DEFINER ou ACL invalide pour emettre_factures_mois';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND (p.proname LIKE 'fac\_%' OR p.proname LIKE 'bf1\_%')
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FAC-B-01 : aide privee executable par un client';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.bf1_finance_profil(uuid)'::regprocedure),
                       'factures_mensuelles') = 0 THEN
    RAISE EXCEPTION 'FAC-B-01 : l''etat financier ne lit pas les factures';
  END IF;
END;
$postflight$;

COMMIT;
