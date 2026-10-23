-- FAC-E-01 (18/10/2026) : les tarifs du 18/10 dans l'application.
--
-- Source unique : docs/current/DECISION-TARIFS-2026-10-18.md (valeurs :
-- docs/current/tarifs-2026-10-18.json). Directeur, 18/10 : dernier passage
-- sur les tarifs ; part de l'enseignant enfant 22,5 % (0,95 $ par eleve
-- present et par heure), adulte 30 % (1,00 $) ; formule adulte a 18 ans.
--
-- * La politique gagne ce que la v1 ne portait pas : taux de paie par eleve
--   present et par heure (et leurs plafonds), duree due par public,
--   prepaiement (trimestre, annee), parrainage, bourse, plafond de cumul des
--   remises, jour de suspension. Les remises de rang acceptent un pour mille
--   du tarif (`pour_mille`) en plus d'un montant (`remise_mineur`, v1).
-- * Version `v2.0.0`, en vigueur le 1er novembre 2026 (jamais retroactive) :
--   55 $ et 65 $, sans essai, -8 % au 2e membre du foyer et -17 % au 3e et
--   suivants, groupe ouvert a 3, place gardee 14 jours apres la suspension du
--   4, relances J-7, J-3, J-1.
-- * Bourse (`bourses_eleves`) : accordee par la direction, -30 %, 6 mois,
--   5 % des eleves au plus, jamais cumulee avec une autre remise.
-- * Prepaiement (`engagements_prepaiement`) : un trimestre (-5 %) ou une annee
--   (-10 %) payes d'avance par la recharge ; chaque facture du mois couvert
--   prend sa part de l'engagement. Remises foyer + prepaiement : 25 % au plus.
-- * Parrainage (`parrainages`) : note par la direction ; 20 $ de credit a
--   chacun des deux foyers apres le premier mois finance du filleul.
BEGIN;

ALTER TABLE public.politiques_commerciales
  ADD COLUMN taux_eleve_heure_enfant_mineur bigint CHECK (taux_eleve_heure_enfant_mineur >= 0),
  ADD COLUMN taux_eleve_heure_adulte_mineur bigint CHECK (taux_eleve_heure_adulte_mineur >= 0),
  ADD COLUMN plafond_eleve_heure_enfant_mineur bigint,
  ADD COLUMN plafond_eleve_heure_adulte_mineur bigint,
  ADD COLUMN duree_due_enfant_minutes integer CHECK (duree_due_enfant_minutes BETWEEN 1 AND 240),
  ADD COLUMN duree_due_adulte_minutes integer CHECK (duree_due_adulte_minutes BETWEEN 1 AND 240),
  ADD COLUMN prepaiement_trimestriel_pour_mille integer CHECK (prepaiement_trimestriel_pour_mille BETWEEN 0 AND 1000),
  ADD COLUMN prepaiement_annuel_pour_mille integer CHECK (prepaiement_annuel_pour_mille BETWEEN 0 AND 1000),
  ADD COLUMN parrainage_credit_mineur bigint CHECK (parrainage_credit_mineur >= 0),
  ADD COLUMN bourse_pour_mille integer CHECK (bourse_pour_mille BETWEEN 0 AND 1000),
  ADD COLUMN bourse_places_pour_mille integer CHECK (bourse_places_pour_mille BETWEEN 0 AND 1000),
  ADD COLUMN bourse_duree_mois integer CHECK (bourse_duree_mois BETWEEN 1 AND 24),
  ADD COLUMN cumul_max_pour_mille integer CHECK (cumul_max_pour_mille BETWEEN 0 AND 1000),
  ADD COLUMN jour_suspension integer CHECK (jour_suspension BETWEEN 1 AND 28),
  ADD CONSTRAINT politiques_commerciales_taux_enfant_sous_adulte CHECK (
    taux_eleve_heure_enfant_mineur IS NULL OR taux_eleve_heure_adulte_mineur IS NULL
    OR taux_eleve_heure_enfant_mineur <= taux_eleve_heure_adulte_mineur),
  ADD CONSTRAINT politiques_commerciales_plafond_eleve CHECK (
    (plafond_eleve_heure_enfant_mineur IS NULL OR plafond_eleve_heure_enfant_mineur >= coalesce(taux_eleve_heure_enfant_mineur, 0))
    AND (plafond_eleve_heure_adulte_mineur IS NULL OR plafond_eleve_heure_adulte_mineur >= coalesce(taux_eleve_heure_adulte_mineur, 0)));

COMMENT ON COLUMN public.politiques_commerciales.taux_eleve_heure_enfant_mineur IS
  'FAC-E-01 : paie de l''enseignant par eleve present et par heure, classe enfant (0,95 $ au 18/10/2026). Remplace base_horaire_mineur pour les versions qui le portent.';

-- Version du 18/10/2026.
INSERT INTO public.politiques_commerciales (
  version, date_effet, devise, tarif_enfant_mineur, tarif_adulte_mineur,
  essais_max, essai_actif, remises_par_rang, base_horaire_mineur,
  plafond_horaire_mineur, capacite_enfant, capacite_adulte, capacite_debutant,
  minimum_ouverture, classes_objectif, classes_max, jours_conservation_place,
  marge_objectif_pour_mille, marge_forte_pour_mille, marge_stretch_pour_mille,
  rails_actifs, allocation_internet_mineur, jours_relance, budgets, publiee_par,
  taux_eleve_heure_enfant_mineur, taux_eleve_heure_adulte_mineur,
  plafond_eleve_heure_enfant_mineur, plafond_eleve_heure_adulte_mineur,
  duree_due_enfant_minutes, duree_due_adulte_minutes,
  prepaiement_trimestriel_pour_mille, prepaiement_annuel_pour_mille,
  parrainage_credit_mineur, bourse_pour_mille, bourse_places_pour_mille, bourse_duree_mois,
  cumul_max_pour_mille, jour_suspension)
VALUES (
  'v2.0.0', DATE '2026-11-01', 'USD', 5500, 6500,
  0, false,
  '[{"a_partir_du_rang":2,"pour_mille":80},{"a_partir_du_rang":3,"pour_mille":170}]'::jsonb,
  600, 900, 5, 6, 4, 3, 3, 4, 14, 450, 500, 520,
  ARRAY['web_stripe'], NULL, ARRAY[7, 3, 1], '[]'::jsonb, NULL,
  95, 100, 130, 150, 45, 70, 50, 100, 2000, 300, 50, 6, 250, 4);

-- ---------------------------------------------------------------------------
-- Bourses, prepaiements, parrainages
-- ---------------------------------------------------------------------------
CREATE TABLE public.bourses_eleves (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  pour_mille integer NOT NULL CHECK (pour_mille BETWEEN 1 AND 1000),
  mois_debut date NOT NULL CHECK (mois_debut = pg_catalog.date_trunc('month', mois_debut)::date),
  mois_fin date NOT NULL CHECK (mois_fin = pg_catalog.date_trunc('month', mois_fin)::date),
  motif text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(motif)) BETWEEN 1 AND 500),
  accordee_par uuid NOT NULL REFERENCES public.profiles(id),
  accordee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  retiree_par uuid REFERENCES public.profiles(id),
  retiree_le timestamptz,
  CHECK (mois_fin >= mois_debut),
  CHECK ((retiree_le IS NULL) = (retiree_par IS NULL))
);
CREATE UNIQUE INDEX bourses_eleves_une_active ON public.bourses_eleves (profile_id) WHERE retiree_le IS NULL;
COMMENT ON TABLE public.bourses_eleves IS
  'FAC-E-01 : bourse Rewayah accordee par la direction (motif jamais montre a la famille ni a l''enseignant). Non cumulable.';

CREATE TABLE public.engagements_prepaiement (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  formule text NOT NULL CHECK (formule IN ('trimestriel', 'annuel')),
  mois_debut date NOT NULL CHECK (mois_debut = pg_catalog.date_trunc('month', mois_debut)::date),
  nb_mois integer NOT NULL CHECK (nb_mois IN (3, 12)),
  total_mineur bigint NOT NULL CHECK (total_mineur > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  commande_id uuid REFERENCES public.commandes_recharge(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CHECK ((formule = 'trimestriel') = (nb_mois = 3))
);
CREATE INDEX engagements_prepaiement_profil ON public.engagements_prepaiement (profile_id, mois_debut);
COMMENT ON TABLE public.engagements_prepaiement IS
  'FAC-E-01 : trimestre ou annee payes d''avance ; chaque facture du mois couvert prend sa part du total.';

CREATE TABLE public.parrainages (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  parrain_household_id uuid NOT NULL REFERENCES public.households(id),
  filleul_household_id uuid NOT NULL UNIQUE REFERENCES public.households(id),
  enregistre_par uuid NOT NULL REFERENCES public.profiles(id),
  enregistre_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  credite_le timestamptz,
  CHECK (parrain_household_id <> filleul_household_id)
);
COMMENT ON TABLE public.parrainages IS
  'FAC-E-01 : parrainage note par la direction ; credit des deux foyers apres le premier mois finance du filleul.';

DO $tables$
DECLARE
  v_t text;
BEGIN
  FOREACH v_t IN ARRAY ARRAY['bourses_eleves', 'engagements_prepaiement', 'parrainages'] LOOP
    EXECUTE pg_catalog.format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', v_t);
    EXECUTE pg_catalog.format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_t);
  END LOOP;
END;
$tables$;

ALTER TABLE public.recharges_recap_lignes
  ADD COLUMN formule text NOT NULL DEFAULT 'libre' CHECK (formule IN ('libre', 'mois', 'trimestriel', 'annuel'));
ALTER TABLE public.commandes_recharge_allocations
  ADD COLUMN formule text NOT NULL DEFAULT 'libre' CHECK (formule IN ('libre', 'mois', 'trimestriel', 'annuel'));

-- ---------------------------------------------------------------------------
-- Calculs
-- ---------------------------------------------------------------------------

-- La remise de rang (montant negatif) d'un tarif, en montant (v1) ou en
-- pour mille du tarif (v2), ou nulle : le plus grand palier atteint.
CREATE FUNCTION private.fac_remise_montant(p public.politiques_commerciales, p_rang integer, p_tarif bigint)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE WHEN r ? 'pour_mille'
              THEN -((p_tarif * (r ->> 'pour_mille')::bigint + 500) / 1000)
              ELSE (r ->> 'remise_mineur')::bigint END
    FROM pg_catalog.jsonb_array_elements(p.remises_par_rang) AS r
   WHERE (r ->> 'a_partir_du_rang')::integer <= p_rang
   ORDER BY (r ->> 'a_partir_du_rang')::integer DESC
   LIMIT 1;
$function$;

-- La remise de rang d'un enfant (remplace la version FAC-A, lue par l'apercu
-- d'un foyer) : en montant ou en pour mille du tarif enfant.
CREATE OR REPLACE FUNCTION private.fac_remise_rang(p public.politiques_commerciales, p_rang integer)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT private.fac_remise_montant(p, p_rang, p.tarif_enfant_mineur);
$function$;

-- Le tarif mensuel d'un profil sous p : adulte pour un compte autonome
-- (18 ans et plus), enfant sinon.
CREATE FUNCTION private.fac_tarif_profil(p_profil uuid, p public.politiques_commerciales)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE WHEN sp.student_type = 'autonomous' THEN p.tarif_adulte_mineur ELSE p.tarif_enfant_mineur END
    FROM public.student_profiles sp WHERE sp.profile_id = p_profil;
$function$;

-- Le rang du profil dans son foyer pour p_mois : celui de sa facture si elle
-- existe, sinon le rang qu'il prendrait (membres deja factures + 1).
CREATE FUNCTION private.fac_rang_attendu(p_profil uuid, p_mois date)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT f.rang_familial FROM public.factures_mensuelles f
      WHERE f.profile_id = p_profil AND f.mois = p_mois AND f.statut <> 'annulee'),
    1 + (SELECT count(*)::integer FROM public.factures_mensuelles f
           JOIN public.profiles pr ON pr.id = p_profil
          WHERE f.household_id = pr.household_id AND f.mois = p_mois AND f.statut <> 'annulee'));
$function$;

-- La bourse active d'un profil au mois p_mois, ou nulle.
CREATE FUNCTION private.fac_bourse(p_profil uuid, p_mois date)
RETURNS public.bourses_eleves
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT b.* FROM public.bourses_eleves b
   WHERE b.profile_id = p_profil AND b.retiree_le IS NULL
     AND p_mois BETWEEN b.mois_debut AND b.mois_fin
   LIMIT 1;
$function$;

-- Le prix d'un trimestre (3) ou d'une annee (12) payes d'avance a partir de
-- p_mois : tarif x mois, moins la remise de rang et le prepaiement, le tout
-- borne au plafond de cumul, arrondi au dollar. Nul si la formule n'existe
-- pas dans la politique, ou si une bourse s'applique (non cumulable).
CREATE FUNCTION private.fac_prix_prepaiement(p_profil uuid, p_mois date, p_nb_mois integer)
RETURNS bigint
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  p public.politiques_commerciales := private.fac_politique_au(p_mois);
  v_tarif bigint;
  v_rang bigint;
  v_pre integer;
  v_remise bigint;
BEGIN
  v_pre := CASE p_nb_mois WHEN 3 THEN p.prepaiement_trimestriel_pour_mille
                          WHEN 12 THEN p.prepaiement_annuel_pour_mille END;
  IF p.version IS NULL OR v_pre IS NULL OR (private.fac_bourse(p_profil, p_mois)).id IS NOT NULL THEN
    RETURN NULL;
  END IF;
  v_tarif := private.fac_tarif_profil(p_profil, p);
  IF v_tarif IS NULL OR v_tarif = 0 THEN
    RETURN NULL;
  END IF;
  v_rang := -coalesce(private.fac_remise_montant(p, private.fac_rang_attendu(p_profil, p_mois), v_tarif), 0);
  v_remise := v_rang * p_nb_mois + (v_tarif * p_nb_mois * v_pre + 500) / 1000;
  IF p.cumul_max_pour_mille IS NOT NULL THEN
    v_remise := least(v_remise, (v_tarif * p_nb_mois * p.cumul_max_pour_mille) / 1000);
  END IF;
  RETURN ((v_tarif * p_nb_mois - v_remise + 50) / 100) * 100;
END;
$function$;

-- La part d'un engagement pour p_mois : le total reparti a parts egales, le
-- reste des centimes sur le dernier mois.
CREATE FUNCTION private.fac_part_engagement(e public.engagements_prepaiement, p_mois date)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE WHEN p_mois = (e.mois_debut + pg_catalog.make_interval(months => e.nb_mois - 1))::date
              THEN e.total_mineur - (e.total_mineur / e.nb_mois) * (e.nb_mois - 1)
              ELSE e.total_mineur / e.nb_mois END;
$function$;

-- Les lignes et le total de la mensualite (remplace la version FAC-B) : tarif ;
-- bourse (seule) ou remise de rang puis part de prepaiement ; prorata du
-- premier mois payant hors engagement.
CREATE OR REPLACE FUNCTION private.fac_mensualite(
  p_profil uuid, p_mois date, p public.politiques_commerciales,
  p_rang integer, p_premier boolean)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_tarif bigint := coalesce(private.fac_tarif_profil(p_profil, p), 0);
  v_remise bigint;
  v_base bigint;
  v_lignes jsonb;
  v_adh public.groupe_membres;
  v_o integer;
  v_e integer;
  v_prorata bigint := 0;
  v_bourse public.bourses_eleves := private.fac_bourse(p_profil, p_mois);
  v_eng public.engagements_prepaiement;
  v_part bigint;
BEGIN
  v_lignes := pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'nature', 'tarif', 'montant', private.bf1_montant(v_tarif, p.devise), 'rang', NULL));
  IF v_bourse.id IS NOT NULL THEN
    v_remise := -((v_tarif * v_bourse.pour_mille + 500) / 1000);
    v_base := greatest(v_tarif + v_remise, 0);
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nature', 'bourse', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', NULL));
  ELSE
    v_remise := CASE WHEN p_rang IS NULL THEN NULL ELSE private.fac_remise_montant(p, p_rang, v_tarif) END;
    v_base := greatest(v_tarif + coalesce(v_remise, 0), 0);
    IF v_remise IS NOT NULL THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'nature', 'remise_rang', 'montant', private.bf1_montant(v_base - v_tarif, p.devise), 'rang', p_rang));
    END IF;
    SELECT e.* INTO v_eng FROM public.engagements_prepaiement e
     WHERE e.profile_id = p_profil AND e.devise = p.devise
       AND p_mois >= e.mois_debut
       AND p_mois < (e.mois_debut + pg_catalog.make_interval(months => e.nb_mois))::date
     ORDER BY e.cree_le LIMIT 1;
    IF v_eng.id IS NOT NULL THEN
      v_part := private.fac_part_engagement(v_eng, p_mois);
      IF v_part <> v_base THEN
        v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
          'nature', 'remise_prepaiement', 'montant', private.bf1_montant(v_part - v_base, p.devise), 'rang', NULL));
      END IF;
      v_base := v_part;
    END IF;
  END IF;

  IF p_premier AND v_eng.id IS NULL THEN
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

-- La politique, au format du contrat (remplace la version FAC-A) : les
-- remises de rang en montant ou en pour mille, et les valeurs de la v2.
CREATE OR REPLACE FUNCTION private.fac_politique_json(p public.politiques_commerciales, p_statut text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'version', p.version,
    'statut', p_statut,
    'dateEffet', pg_catalog.to_char(p.date_effet, 'YYYY-MM-DD'),
    'tarifEnfant', private.bf1_montant(p.tarif_enfant_mineur, p.devise),
    'tarifAdulte', private.bf1_montant(p.tarif_adulte_mineur, p.devise),
    'essaisMax', p.essais_max,
    'essaiActif', p.essai_actif,
    'remisesParRang', coalesce((
      SELECT pg_catalog.jsonb_agg(CASE WHEN r ? 'pour_mille'
               THEN pg_catalog.jsonb_build_object(
                      'aPartirDuRang', (r ->> 'a_partir_du_rang')::integer,
                      'pourMille', (r ->> 'pour_mille')::integer)
               ELSE pg_catalog.jsonb_build_object(
                      'aPartirDuRang', (r ->> 'a_partir_du_rang')::integer,
                      'remise', private.bf1_montant((r ->> 'remise_mineur')::bigint, p.devise)) END
             ORDER BY (r ->> 'a_partir_du_rang')::integer)
        FROM pg_catalog.jsonb_array_elements(p.remises_par_rang) AS r), '[]'::jsonb),
    'baseHoraire', private.bf1_montant(p.base_horaire_mineur, p.devise),
    'plafondHoraire', private.bf1_montant(p.plafond_horaire_mineur, p.devise),
    'capaciteEnfant', p.capacite_enfant,
    'capaciteAdulte', p.capacite_adulte,
    'capaciteDebutant', p.capacite_debutant,
    'minimumOuverture', p.minimum_ouverture,
    'classesObjectif', p.classes_objectif,
    'classesMax', p.classes_max,
    'joursConservationPlace', p.jours_conservation_place,
    'margeReferencePourMille', pg_catalog.jsonb_build_object(
      'objectif', p.marge_objectif_pour_mille,
      'forte', p.marge_forte_pour_mille,
      'stretch', p.marge_stretch_pour_mille),
    'railsActifs', coalesce((
      SELECT pg_catalog.jsonb_agg(CASE r WHEN 'web_stripe' THEN 'webStripe'
                                         WHEN 'ios_storekit' THEN 'iosStoreKit'
                                         ELSE 'androidPlay' END ORDER BY r)
        FROM pg_catalog.unnest(p.rails_actifs) AS r), '[]'::jsonb),
    'allocationInternet', CASE WHEN p.allocation_internet_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(p.allocation_internet_mineur, p.devise) END,
    'joursRelance', CASE WHEN p.jours_relance IS NULL THEN NULL
      ELSE pg_catalog.to_jsonb(p.jours_relance) END,
    'budgets', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'nature', b ->> 'nature', 'pourMille', (b ->> 'pour_mille')::integer)
             ORDER BY b ->> 'nature')
        FROM pg_catalog.jsonb_array_elements(p.budgets) AS b), '[]'::jsonb),
    'tauxEleveHeureEnfant', CASE WHEN p.taux_eleve_heure_enfant_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(p.taux_eleve_heure_enfant_mineur, p.devise) END,
    'tauxEleveHeureAdulte', CASE WHEN p.taux_eleve_heure_adulte_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(p.taux_eleve_heure_adulte_mineur, p.devise) END,
    'plafondEleveHeureEnfant', CASE WHEN p.plafond_eleve_heure_enfant_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(p.plafond_eleve_heure_enfant_mineur, p.devise) END,
    'plafondEleveHeureAdulte', CASE WHEN p.plafond_eleve_heure_adulte_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(p.plafond_eleve_heure_adulte_mineur, p.devise) END,
    'dureeDueEnfantMinutes', p.duree_due_enfant_minutes,
    'dureeDueAdulteMinutes', p.duree_due_adulte_minutes,
    'prepaiementTrimestrielPourMille', p.prepaiement_trimestriel_pour_mille,
    'prepaiementAnnuelPourMille', p.prepaiement_annuel_pour_mille,
    'parrainageCredit', CASE WHEN p.parrainage_credit_mineur IS NULL THEN NULL
      ELSE private.bf1_montant(p.parrainage_credit_mineur, p.devise) END,
    'boursePourMille', p.bourse_pour_mille,
    'boursePlacesPourMille', p.bourse_places_pour_mille,
    'bourseDureeMois', p.bourse_duree_mois,
    'cumulMaxPourMille', p.cumul_max_pour_mille,
    'jourSuspension', p.jour_suspension);
$function$;

-- Un entier facultatif du contrat (absent ou nul : nul).
CREATE FUNCTION private.fac_entier_facultatif(p_json jsonb, p_cle text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_json -> p_cle IS NULL OR pg_catalog.jsonb_typeof(p_json -> p_cle) = 'null' THEN
    RETURN NULL;
  END IF;
  RETURN private.fac_entier_lu(p_json, p_cle);
END;
$function$;

-- Un montant facultatif du contrat (absent ou nul : nul).
CREATE FUNCTION private.fac_montant_facultatif(p_json jsonb, p_cle text, p_devise text)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF p_json -> p_cle IS NULL OR pg_catalog.jsonb_typeof(p_json -> p_cle) = 'null' THEN
    RETURN NULL;
  END IF;
  RETURN private.fac_montant_lu(p_json, p_cle, p_devise);
END;
$function$;

-- Lit et valide une politique (remplace la version FAC-A) : la v1 telle
-- quelle, plus les remises en pour mille et les valeurs de la v2.
CREATE OR REPLACE FUNCTION private.fac_politique_lue(p jsonb)
RETURNS public.politiques_commerciales
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  r public.politiques_commerciales;
  v_devise text := p #>> '{tarifEnfant,devise}';
  v_rangs jsonb := '[]'::jsonb;
  v_budgets jsonb := '[]'::jsonb;
  v_rails text[] := ARRAY[]::text[];
  v_e jsonb;
  v_t text;
  v_pm integer;
BEGIN
  IF p IS NULL OR pg_catalog.jsonb_typeof(p) <> 'object' THEN
    RAISE EXCEPTION 'politique absente' USING ERRCODE = '22023';
  END IF;
  IF v_devise IS NULL OR v_devise !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'devise invalide' USING ERRCODE = '22023';
  END IF;
  r.version := p ->> 'version';
  IF r.version IS NULL OR r.version !~ '^v[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' THEN
    RAISE EXCEPTION 'numero de version invalide' USING ERRCODE = '22023';
  END IF;
  IF (p ->> 'dateEffet') IS NULL OR (p ->> 'dateEffet') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN
    RAISE EXCEPTION 'date d''effet invalide' USING ERRCODE = '22023';
  END IF;
  r.date_effet := (p ->> 'dateEffet')::date;
  r.devise := v_devise;
  r.tarif_enfant_mineur := private.fac_montant_lu(p, 'tarifEnfant', v_devise);
  r.tarif_adulte_mineur := private.fac_montant_lu(p, 'tarifAdulte', v_devise);
  r.essais_max := private.fac_entier_lu(p, 'essaisMax');
  IF pg_catalog.jsonb_typeof(p -> 'essaiActif') IS DISTINCT FROM 'boolean' THEN
    RAISE EXCEPTION 'essaiActif invalide' USING ERRCODE = '22023';
  END IF;
  r.essai_actif := (p ->> 'essaiActif')::boolean;

  IF pg_catalog.jsonb_typeof(p -> 'remisesParRang') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'remisesParRang invalide' USING ERRCODE = '22023';
  END IF;
  FOR v_e IN SELECT x FROM pg_catalog.jsonb_array_elements(p -> 'remisesParRang') AS x LOOP
    IF private.fac_entier_lu(v_e, 'aPartirDuRang') < 1 THEN
      RAISE EXCEPTION 'remise de rang invalide' USING ERRCODE = '22023';
    END IF;
    IF v_e ? 'pourMille' THEN
      v_pm := private.fac_entier_lu(v_e, 'pourMille');
      IF v_pm NOT BETWEEN 0 AND 1000 OR v_e ? 'remise' THEN
        RAISE EXCEPTION 'remise de rang invalide' USING ERRCODE = '22023';
      END IF;
      v_rangs := v_rangs || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'a_partir_du_rang', private.fac_entier_lu(v_e, 'aPartirDuRang'), 'pour_mille', v_pm));
    ELSE
      IF private.fac_montant_lu(v_e, 'remise', v_devise) > 0
         OR private.fac_montant_lu(v_e, 'remise', v_devise) + r.tarif_enfant_mineur < 0 THEN
        RAISE EXCEPTION 'remise de rang invalide' USING ERRCODE = '22023';
      END IF;
      v_rangs := v_rangs || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'a_partir_du_rang', private.fac_entier_lu(v_e, 'aPartirDuRang'),
        'remise_mineur', private.fac_montant_lu(v_e, 'remise', v_devise)));
    END IF;
  END LOOP;
  IF (SELECT count(*) <> count(DISTINCT x ->> 'a_partir_du_rang')
        FROM pg_catalog.jsonb_array_elements(v_rangs) AS x) THEN
    RAISE EXCEPTION 'rang de remise en double' USING ERRCODE = '22023';
  END IF;
  r.remises_par_rang := v_rangs;

  r.base_horaire_mineur := private.fac_montant_lu(p, 'baseHoraire', v_devise);
  r.plafond_horaire_mineur := private.fac_montant_lu(p, 'plafondHoraire', v_devise);
  r.capacite_enfant := private.fac_entier_lu(p, 'capaciteEnfant');
  r.capacite_adulte := private.fac_entier_lu(p, 'capaciteAdulte');
  r.capacite_debutant := private.fac_entier_lu(p, 'capaciteDebutant');
  r.minimum_ouverture := private.fac_entier_lu(p, 'minimumOuverture');
  r.classes_objectif := private.fac_entier_lu(p, 'classesObjectif');
  r.classes_max := private.fac_entier_lu(p, 'classesMax');
  r.jours_conservation_place := private.fac_entier_lu(p, 'joursConservationPlace');
  r.marge_objectif_pour_mille := private.fac_entier_lu(p -> 'margeReferencePourMille', 'objectif');
  r.marge_forte_pour_mille := private.fac_entier_lu(p -> 'margeReferencePourMille', 'forte');
  r.marge_stretch_pour_mille := private.fac_entier_lu(p -> 'margeReferencePourMille', 'stretch');

  IF pg_catalog.jsonb_typeof(p -> 'railsActifs') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'railsActifs invalide' USING ERRCODE = '22023';
  END IF;
  FOR v_t IN SELECT x FROM pg_catalog.jsonb_array_elements_text(p -> 'railsActifs') AS x LOOP
    v_rails := v_rails || CASE v_t WHEN 'webStripe' THEN 'web_stripe'
                                   WHEN 'iosStoreKit' THEN 'ios_storekit'
                                   WHEN 'androidPlay' THEN 'android_play'
                                   ELSE NULL END;
    IF v_rails[pg_catalog.array_length(v_rails, 1)] IS NULL THEN
      RAISE EXCEPTION 'rail de paiement inconnu' USING ERRCODE = '22023';
    END IF;
  END LOOP;
  r.rails_actifs := v_rails;

  r.allocation_internet_mineur := private.fac_montant_facultatif(p, 'allocationInternet', v_devise);

  IF p -> 'joursRelance' IS NULL OR pg_catalog.jsonb_typeof(p -> 'joursRelance') = 'null' THEN
    r.jours_relance := NULL;
  ELSIF pg_catalog.jsonb_typeof(p -> 'joursRelance') = 'array' THEN
    IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(p -> 'joursRelance') AS x
                WHERE pg_catalog.jsonb_typeof(x) <> 'number' OR x::text !~ '^[0-9]+$') THEN
      RAISE EXCEPTION 'joursRelance invalide' USING ERRCODE = '22023';
    END IF;
    r.jours_relance := ARRAY(SELECT (x)::text::integer
                               FROM pg_catalog.jsonb_array_elements(p -> 'joursRelance') AS x);
  ELSE
    RAISE EXCEPTION 'joursRelance invalide' USING ERRCODE = '22023';
  END IF;

  IF pg_catalog.jsonb_typeof(coalesce(p -> 'budgets', '[]'::jsonb)) <> 'array' THEN
    RAISE EXCEPTION 'budgets invalide' USING ERRCODE = '22023';
  END IF;
  FOR v_e IN SELECT x FROM pg_catalog.jsonb_array_elements(coalesce(p -> 'budgets', '[]'::jsonb)) AS x LOOP
    IF (v_e ->> 'nature') NOT IN ('marketing', 'operationnel')
       OR private.fac_entier_lu(v_e, 'pourMille') NOT BETWEEN 0 AND 1000 THEN
      RAISE EXCEPTION 'budget invalide' USING ERRCODE = '22023';
    END IF;
    v_budgets := v_budgets || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nature', v_e ->> 'nature', 'pour_mille', private.fac_entier_lu(v_e, 'pourMille')));
  END LOOP;
  r.budgets := v_budgets;

  r.taux_eleve_heure_enfant_mineur := private.fac_montant_facultatif(p, 'tauxEleveHeureEnfant', v_devise);
  r.taux_eleve_heure_adulte_mineur := private.fac_montant_facultatif(p, 'tauxEleveHeureAdulte', v_devise);
  r.plafond_eleve_heure_enfant_mineur := private.fac_montant_facultatif(p, 'plafondEleveHeureEnfant', v_devise);
  r.plafond_eleve_heure_adulte_mineur := private.fac_montant_facultatif(p, 'plafondEleveHeureAdulte', v_devise);
  r.duree_due_enfant_minutes := private.fac_entier_facultatif(p, 'dureeDueEnfantMinutes');
  r.duree_due_adulte_minutes := private.fac_entier_facultatif(p, 'dureeDueAdulteMinutes');
  r.prepaiement_trimestriel_pour_mille := private.fac_entier_facultatif(p, 'prepaiementTrimestrielPourMille');
  r.prepaiement_annuel_pour_mille := private.fac_entier_facultatif(p, 'prepaiementAnnuelPourMille');
  r.parrainage_credit_mineur := private.fac_montant_facultatif(p, 'parrainageCredit', v_devise);
  r.bourse_pour_mille := private.fac_entier_facultatif(p, 'boursePourMille');
  r.bourse_places_pour_mille := private.fac_entier_facultatif(p, 'boursePlacesPourMille');
  r.bourse_duree_mois := private.fac_entier_facultatif(p, 'bourseDureeMois');
  r.cumul_max_pour_mille := private.fac_entier_facultatif(p, 'cumulMaxPourMille');
  r.jour_suspension := private.fac_entier_facultatif(p, 'jourSuspension');
  RETURN r;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Bourses (direction)
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.fac_direction()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false);
$function$;

-- Accorde une bourse au profil eleve : le taux, la duree et le plafond de
-- places viennent de la politique en vigueur. Codes : 42501 droits, 22023
-- motif ou profil, P0002 aucune bourse dans la politique, BO001 plus de place,
-- BO002 deja boursier.
CREATE FUNCTION public.accorder_bourse(p_profil uuid, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_mois date := private.fac_mois_courant();
  p public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
  v_eleves integer;
  v_actives integer;
  v_id uuid;
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'bourse reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF v_motif IS NULL OR pg_catalog.length(v_motif) > 500 THEN
    RAISE EXCEPTION 'motif obligatoire' USING ERRCODE = '22023';
  END IF;
  IF p.bourse_pour_mille IS NULL OR p.bourse_duree_mois IS NULL THEN
    RAISE EXCEPTION 'aucune bourse dans la politique en vigueur' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
                  WHERE sp.profile_id = p_profil AND sp.deleted_at IS NULL AND pr.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'profil eleve introuvable' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('bourses', 0));
  IF EXISTS (SELECT 1 FROM public.bourses_eleves b WHERE b.profile_id = p_profil AND b.retiree_le IS NULL) THEN
    RAISE EXCEPTION 'deja boursier' USING ERRCODE = 'BO002';
  END IF;
  SELECT count(*) INTO v_eleves FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
   WHERE sp.deleted_at IS NULL AND pr.deleted_at IS NULL;
  SELECT count(*) INTO v_actives FROM public.bourses_eleves b
   WHERE b.retiree_le IS NULL AND b.mois_fin >= v_mois;
  IF p.bourse_places_pour_mille IS NOT NULL
     AND (v_actives + 1) * 1000 > greatest(v_eleves, 1) * p.bourse_places_pour_mille
     AND v_actives >= 1 THEN
    RAISE EXCEPTION 'plus de place de bourse' USING ERRCODE = 'BO001';
  END IF;
  INSERT INTO public.bourses_eleves (profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par)
  VALUES (p_profil, p.bourse_pour_mille, v_mois,
          (v_mois + pg_catalog.make_interval(months => p.bourse_duree_mois - 1))::date, v_motif, auth.uid())
  RETURNING id INTO v_id;
  PERFORM public.log_sensitive_access('bourse_accordee', 'bourses_eleves', v_id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'pour_mille', p.bourse_pour_mille));
  RETURN public.bourses_lister() -> 0;
END;
$function$;

-- Retire une bourse (motif obligatoire) : les factures deja emises ne changent pas.
CREATE FUNCTION public.retirer_bourse(p_profil uuid, p_motif text)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'bourse reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF nullif(pg_catalog.btrim(coalesce(p_motif, '')), '') IS NULL THEN
    RAISE EXCEPTION 'motif obligatoire' USING ERRCODE = '22023';
  END IF;
  UPDATE public.bourses_eleves SET retiree_par = auth.uid(), retiree_le = pg_catalog.clock_timestamp()
   WHERE profile_id = p_profil AND retiree_le IS NULL
  RETURNING id INTO v_id;
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'aucune bourse active' USING ERRCODE = 'P0002';
  END IF;
  PERFORM public.log_sensitive_access('bourse_retiree', 'bourses_eleves', v_id::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'motif', pg_catalog.btrim(p_motif)));
END;
$function$;

-- Les bourses actives, les plus recentes d'abord, avec les places restantes.
CREATE FUNCTION public.bourses_lister()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'bourse reservee a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'profilId', b.profile_id, 'prenom', pr.first_name, 'nom', pr.last_name,
             'matricule', pr.immutable_id, 'pourMille', b.pour_mille,
             'moisDebut', pg_catalog.to_char(b.mois_debut, 'YYYY-MM-DD'),
             'moisFin', pg_catalog.to_char(b.mois_fin, 'YYYY-MM-DD'),
             'motif', b.motif) ORDER BY b.accordee_le DESC)
      FROM public.bourses_eleves b JOIN public.profiles pr ON pr.id = b.profile_id
     WHERE b.retiree_le IS NULL), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Parrainage (direction note, le serveur credite)
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.enregistrer_parrainage(p_parrain_foyer uuid, p_filleul_foyer uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.fac_direction() THEN
    RAISE EXCEPTION 'parrainage reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_parrain_foyer IS NULL OR p_filleul_foyer IS NULL OR p_parrain_foyer = p_filleul_foyer
     OR NOT EXISTS (SELECT 1 FROM public.households h WHERE h.id = p_parrain_foyer AND h.deleted_at IS NULL)
     OR NOT EXISTS (SELECT 1 FROM public.households h WHERE h.id = p_filleul_foyer AND h.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'foyers invalides' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.factures_mensuelles f
              WHERE f.household_id = p_filleul_foyer AND f.statut = 'financee') THEN
    RAISE EXCEPTION 'le filleul a deja un mois finance' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.parrainages (parrain_household_id, filleul_household_id, enregistre_par)
  VALUES (p_parrain_foyer, p_filleul_foyer, auth.uid());
  PERFORM public.log_sensitive_access('parrainage_enregistre', 'parrainages', p_filleul_foyer::text,
    pg_catalog.jsonb_build_object('parrain', p_parrain_foyer));
EXCEPTION WHEN unique_violation THEN
  RAISE EXCEPTION 'ce foyer a deja un parrain' USING ERRCODE = '22023';
END;
$function$;

-- Credite un parrainage du foyer p_foyer si son premier mois vient d'etre
-- finance : le credit de la politique, au premier profil eleve de chaque
-- foyer (credit sans expiration, jamais converti en argent).
CREATE FUNCTION private.fac_crediter_parrainage(p_foyer uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_par public.parrainages;
  p public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
  v_foyer uuid;
  v_profil uuid;
  v_w public.wallets;
BEGIN
  SELECT * INTO v_par FROM public.parrainages
   WHERE filleul_household_id = p_foyer AND credite_le IS NULL FOR UPDATE;
  IF v_par.id IS NULL OR p.parrainage_credit_mineur IS NULL OR p.parrainage_credit_mineur = 0
     OR NOT EXISTS (SELECT 1 FROM public.factures_mensuelles f
                     WHERE f.household_id = p_foyer AND f.statut = 'financee' AND f.total_mineur > 0) THEN
    RETURN;
  END IF;
  FOREACH v_foyer IN ARRAY ARRAY[v_par.parrain_household_id, v_par.filleul_household_id] LOOP
    SELECT pr.id INTO v_profil FROM public.profiles pr
      JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
     WHERE pr.household_id = v_foyer AND pr.deleted_at IS NULL
     ORDER BY pr.created_at, pr.id LIMIT 1;
    IF v_profil IS NOT NULL THEN
      v_w := private.fac_portefeuille(v_foyer, p.devise);
      INSERT INTO public.wallet_entries
        (wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
      VALUES (v_w.id, p.parrainage_credit_mineur, p.devise, 'credit', v_profil, pg_catalog.clock_timestamp());
    END IF;
  END LOOP;
  UPDATE public.parrainages SET credite_le = pg_catalog.clock_timestamp() WHERE id = v_par.id;
  PERFORM public.log_sensitive_access('parrainage_credite', 'parrainages', v_par.id::text,
    pg_catalog.jsonb_build_object('montant_mineur', p.parrainage_credit_mineur));
END;
$function$;

-- Finance les factures couvertes (remplace la version FAC-B), puis credite
-- le parrainage du foyer quand son premier mois vient d'etre finance.
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
  RETURN v_n;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Recharge : formules (remplace les versions FI-BR-06)
-- ---------------------------------------------------------------------------

-- Les montants proposes a un profil, chacun avec sa formule : le reste a
-- payer, un mois au tarif publie, puis le trimestre et l'annee payes d'avance
-- (a partir du mois suivant) quand la politique les propose et que le mois en
-- cours est deja regle : le credit d'un engagement ne paie jamais un autre mois.
-- Une politique sans prepaiement (v1) garde deux et trois mois au tarif.
CREATE FUNCTION private.rch_offres(p_profil uuid)
RETURNS TABLE (formule text, montant bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  WITH pol AS (SELECT * FROM private.fac_politique_au(private.fac_aujourdhui())),
       suivant AS (SELECT (private.fac_mois_courant() + interval '1 month')::date AS m),
       o AS (
    SELECT 'libre'::text AS formule, private.fac_reste_a_payer(p_profil) AS montant, 0 AS ordre
    UNION ALL
    SELECT 'mois', private.fac_tarif_profil(p_profil, pol), 1 FROM pol
    UNION ALL
    SELECT 'libre', private.fac_tarif_profil(p_profil, pol) * k, 1 FROM pol, pg_catalog.generate_series(2, 3) k
     WHERE pol.prepaiement_trimestriel_pour_mille IS NULL AND pol.prepaiement_annuel_pour_mille IS NULL
    UNION ALL
    SELECT 'trimestriel', private.fac_prix_prepaiement(p_profil, suivant.m, 3), 2 FROM suivant
     WHERE private.fac_reste_a_payer(p_profil) = 0
    UNION ALL
    SELECT 'annuel', private.fac_prix_prepaiement(p_profil, suivant.m, 12), 3 FROM suivant
     WHERE private.fac_reste_a_payer(p_profil) = 0)
  SELECT DISTINCT ON (o.montant) o.formule, o.montant
    FROM o WHERE o.montant > 0
   ORDER BY o.montant, o.ordre DESC;
$function$;

CREATE OR REPLACE FUNCTION private.rch_montants(p_profil uuid)
RETURNS bigint[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.array_agg(o.montant ORDER BY o.montant), '{}'::bigint[])
    FROM private.rch_offres(p_profil) o;
$function$;

CREATE OR REPLACE FUNCTION public.recharge_beneficiaires()
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
             'montantsProposes', (SELECT coalesce(pg_catalog.jsonb_agg(private.bf1_montant(o.montant, v_devise)
                                    ORDER BY o.montant), '[]'::jsonb) FROM private.rch_offres(x.id) o),
             'formules', (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                             'montant', private.bf1_montant(o.montant, v_devise), 'formule', o.formule)
                             ORDER BY o.montant), '[]'::jsonb) FROM private.rch_offres(x.id) o),
             'montantSuggere', CASE WHEN private.fac_reste_a_payer(x.id) > 0
                                    THEN private.bf1_montant(private.fac_reste_a_payer(x.id), v_devise) END)
           ORDER BY x.first_name, x.id)
      FROM (SELECT p.id, p.first_name, sp.avatar_storage_key
              FROM public.profiles p
              JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
             WHERE p.deleted_at IS NULL AND p.household_id = public.app_household_id()) x), '[]'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.recharge_verifier_montants(p_choix jsonb)
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
  v_formule text;
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
    SELECT o.formule INTO v_formule FROM private.rch_offres(v_profil) o WHERE o.montant = v_montant;
    IF (v_c ->> 'devise') IS DISTINCT FROM v_devise OR v_formule IS NULL THEN
      RAISE EXCEPTION 'montant non propose' USING ERRCODE = '22023';
    END IF;
    v_rang := v_rang + 1;
    INSERT INTO public.recharges_recap_lignes (recapitulatif_id, rang, profile_id, montant_mineur, formule)
    VALUES (v_id, v_rang, v_profil, v_montant, v_formule);
    v_total := v_total + v_montant;
  END LOOP;
  UPDATE public.recharges_recapitulatifs SET total_mineur = v_total WHERE id = v_id;
  RETURN pg_catalog.jsonb_build_object(
    'id', v_id,
    'total', private.bf1_montant(v_total, v_devise),
    'lignes', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'beneficiaireId', l.profile_id, 'prenom', p.first_name,
                 'cleAvatar', sp.avatar_storage_key, 'formule', l.formule,
                 'montant', private.bf1_montant(l.montant_mineur, v_devise)) ORDER BY l.rang)
                 FROM public.recharges_recap_lignes l
                 JOIN public.profiles p ON p.id = l.profile_id
                 LEFT JOIN public.student_profiles sp ON sp.profile_id = l.profile_id
                WHERE l.recapitulatif_id = v_id));
END;
$function$;

-- La commande reprend la formule de chaque ligne (remplace FI-BR-06 en
-- gardant son contrat).
CREATE OR REPLACE FUNCTION public.recharge_payer(p_recapitulatif uuid, p_cle uuid)
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
    INSERT INTO public.commandes_recharge_allocations (commande_id, rang, profile_id, montant_mineur, formule)
    SELECT v_c.id, l.rang, l.profile_id, l.montant_mineur, l.formule
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

-- L'evenement Stripe (remplace FI-BR-06) : en plus du credit, un trimestre ou
-- une annee payes d'avance ouvrent leur engagement au mois suivant.
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

-- ---------------------------------------------------------------------------
-- Droits
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_remise_montant(public.politiques_commerciales,integer,bigint)'::regprocedure,
    'private.fac_remise_rang(public.politiques_commerciales,integer)'::regprocedure,
    'private.fac_tarif_profil(uuid,public.politiques_commerciales)'::regprocedure,
    'private.fac_rang_attendu(uuid,date)'::regprocedure,
    'private.fac_bourse(uuid,date)'::regprocedure,
    'private.fac_prix_prepaiement(uuid,date,integer)'::regprocedure,
    'private.fac_part_engagement(public.engagements_prepaiement,date)'::regprocedure,
    'private.fac_mensualite(uuid,date,public.politiques_commerciales,integer,boolean)'::regprocedure,
    'private.fac_politique_json(public.politiques_commerciales,text)'::regprocedure,
    'private.fac_entier_facultatif(jsonb,text)'::regprocedure,
    'private.fac_montant_facultatif(jsonb,text,text)'::regprocedure,
    'private.fac_politique_lue(jsonb)'::regprocedure,
    'private.fac_direction()'::regprocedure,
    'private.fac_crediter_parrainage(uuid)'::regprocedure,
    'private.fac_financer_profil(uuid)'::regprocedure,
    'private.rch_offres(uuid)'::regprocedure,
    'private.rch_montants(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.accorder_bourse(uuid,text)'::regprocedure,
    'public.retirer_bourse(uuid,text)'::regprocedure,
    'public.bourses_lister()'::regprocedure,
    'public.enregistrer_parrainage(uuid,uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FAC-E-01.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.recharge_beneficiaires()'::regprocedure,
    'public.recharge_verifier_montants(jsonb)'::regprocedure,
    'public.recharge_payer(uuid,uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_GUARDIAN_TITULAIRE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FI-BR-06, FAC-E-01.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
  v_oid := 'public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=SERVICE_ROLE_ONLY_EDGE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FI-BR-06, FAC-E-01.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.accorder_bourse(uuid,text)'::regprocedure,
    'public.retirer_bourse(uuid,text)'::regprocedure,
    'public.bourses_lister()'::regprocedure,
    'public.enregistrer_parrainage(uuid,uuid)'::regprocedure,
    'public.recharge_beneficiaires()'::regprocedure,
    'public.recharge_verifier_montants(jsonb)'::regprocedure,
    'public.recharge_payer(uuid,uuid)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FAC-E-01 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated',
       'public.recharge_evenement_stripe(text,text,text,uuid,text,text,text,bigint,text)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'FAC-E-01 : la confirmation Stripe doit rester au serveur';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND (p.proname LIKE 'fac\_%' OR p.proname LIKE 'rch\_%')
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FAC-E-01 : aide privee executable par un client';
  END IF;
  IF (SELECT tarif_enfant_mineur FROM public.politiques_commerciales WHERE version = 'v2.0.0') <> 5500
     OR (SELECT taux_eleve_heure_enfant_mineur FROM public.politiques_commerciales WHERE version = 'v2.0.0') <> 95 THEN
    RAISE EXCEPTION 'FAC-E-01 : la politique v2.0.0 ne porte pas les valeurs du 18/10';
  END IF;
END;
$postflight$;

COMMIT;
