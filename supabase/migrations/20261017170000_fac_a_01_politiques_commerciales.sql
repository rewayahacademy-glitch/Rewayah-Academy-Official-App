-- FAC-A-01 (17/10/2026) : la politique commerciale versionnee, en base
-- (FI-BR-01, FI-BR-02 ; guide Finance V4 §1 et §5.7 ; lot A de
-- 07_MEMOIRE_PEDAGOGIE_FINANCE ; passation du 17/10, point 2).
--
-- Contrat Dart : lib/core/finance/politique_commerciale.dart et
-- lib/core/capacites/port_politiques_commerciales.dart. Aucun montant dans
-- Flutter : tarifs, remises, essais, conservation, relances vivent ici.
--
-- * `politiques_commerciales` ne garde que les versions PUBLIEES. Une version
--   publiee ne se modifie ni ne se supprime (trigger) : on publie la suivante.
-- * La version active est la plus recente dont la date d'effet est passee,
--   dans le fuseau comptable (`private.bf1_fuseau_comptable`).
-- * Le brouillon n'est pas stocke : `politiques_commerciales_versions()` en
--   propose un, copie de la derniere version, au numero suivant et a la
--   premiere date d'effet libre (premier jour d'un mois a venir). L'ecran de
--   la direction l'edite, puis `publier_politique_commerciale` l'inscrit.
-- * Publier exige la direction active en double verification (aal2) : seul le
--   directeur publie les prix (dossier maitre, annexe 21). La date d'effet est
--   strictement future et posterieure a toute version publiee : jamais
--   retroactive sur une facture deja emise (guide §1.3).
-- * La version de lancement v1.0.0 est inscrite ici, avec les valeurs
--   decidees : guide V4 du 02/10 (FIN4-01, §1.2, §1.3, §1.4, §1.5, §1.7) et
--   registre de reconciliation du 14/10 §6 (remise confirmee le 12/10).
--   Aucune relance ni allocation Internet n'est decidee : nulles.
BEGIN;

CREATE TABLE public.politiques_commerciales (
  version text PRIMARY KEY CHECK (version ~ '^v[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'),
  date_effet date NOT NULL UNIQUE,
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  tarif_enfant_mineur bigint NOT NULL CHECK (tarif_enfant_mineur >= 0),
  tarif_adulte_mineur bigint NOT NULL CHECK (tarif_adulte_mineur >= 0),
  essais_max integer NOT NULL CHECK (essais_max BETWEEN 0 AND 10),
  essai_actif boolean NOT NULL,
  remises_par_rang jsonb NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(remises_par_rang) = 'array'),
  base_horaire_mineur bigint NOT NULL CHECK (base_horaire_mineur >= 0),
  plafond_horaire_mineur bigint NOT NULL,
  capacite_enfant integer NOT NULL CHECK (capacite_enfant BETWEEN 1 AND 50),
  capacite_adulte integer NOT NULL CHECK (capacite_adulte BETWEEN 1 AND 50),
  capacite_debutant integer NOT NULL CHECK (capacite_debutant BETWEEN 1 AND 50),
  minimum_ouverture integer NOT NULL CHECK (minimum_ouverture BETWEEN 1 AND 50),
  classes_objectif integer NOT NULL CHECK (classes_objectif BETWEEN 1 AND 50),
  classes_max integer NOT NULL CHECK (classes_max BETWEEN 1 AND 50),
  jours_conservation_place integer NOT NULL CHECK (jours_conservation_place BETWEEN 0 AND 90),
  marge_objectif_pour_mille integer NOT NULL CHECK (marge_objectif_pour_mille BETWEEN 0 AND 1000),
  marge_forte_pour_mille integer NOT NULL CHECK (marge_forte_pour_mille BETWEEN 0 AND 1000),
  marge_stretch_pour_mille integer NOT NULL CHECK (marge_stretch_pour_mille BETWEEN 0 AND 1000),
  rails_actifs text[] NOT NULL
    CHECK (rails_actifs <@ ARRAY['web_stripe','ios_storekit','android_play']::text[]),
  allocation_internet_mineur bigint CHECK (allocation_internet_mineur >= 0),
  jours_relance integer[] CHECK (jours_relance IS NULL OR 0 <= ALL (jours_relance)),
  budgets jsonb NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(budgets) = 'array'),
  publiee_par uuid REFERENCES public.profiles(id),
  publiee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT politiques_commerciales_plafond CHECK (plafond_horaire_mineur >= base_horaire_mineur),
  CONSTRAINT politiques_commerciales_classes CHECK (classes_max >= classes_objectif)
);
COMMENT ON TABLE public.politiques_commerciales IS
  'FAC-A-01: versions publiees de la politique commerciale (FI-BR-01, FI-BR-02). Ajout seul ; montants en unites mineures de `devise`.';

ALTER TABLE public.politiques_commerciales ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.politiques_commerciales FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.politiques_commerciales TO authenticated;
CREATE POLICY politiques_commerciales_lecture_direction ON public.politiques_commerciales
  FOR SELECT TO authenticated
  USING (coalesce((SELECT public.app_role()) IN ('admin', 'accountant')
                  AND (SELECT public.app_account_valid()), false));

-- Ajout seul : une version publiee ne change plus.
CREATE FUNCTION private.fac_politique_immuable()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'une version publiee de la politique commerciale ne se modifie pas : publier la suivante'
    USING ERRCODE = 'insufficient_privilege';
END;
$function$;
ALTER FUNCTION private.fac_politique_immuable() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.fac_politique_immuable() FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER politiques_commerciales_immuable
  BEFORE UPDATE OR DELETE ON public.politiques_commerciales
  FOR EACH ROW EXECUTE FUNCTION private.fac_politique_immuable();

-- Version de lancement (valeurs decidees, voir l'en-tete).
INSERT INTO public.politiques_commerciales (
  version, date_effet, devise, tarif_enfant_mineur, tarif_adulte_mineur,
  essais_max, essai_actif, remises_par_rang, base_horaire_mineur,
  plafond_horaire_mineur, capacite_enfant, capacite_adulte, capacite_debutant,
  minimum_ouverture, classes_objectif, classes_max, jours_conservation_place,
  marge_objectif_pour_mille, marge_forte_pour_mille, marge_stretch_pour_mille,
  rails_actifs, allocation_internet_mineur, jours_relance, budgets, publiee_par)
VALUES (
  'v1.0.0', DATE '2026-10-01', 'USD', 5000, 6000,
  2, true,
  '[{"a_partir_du_rang":3,"remise_mineur":-500},{"a_partir_du_rang":4,"remise_mineur":-700}]'::jsonb,
  400, 700, 5, 6, 4, 4, 3, 4, 7, 300, 350, 400,
  ARRAY['web_stripe'], NULL, NULL, '[]'::jsonb, NULL);

-- ---------------------------------------------------------------------------
-- Aides (aucun droit client).
-- ---------------------------------------------------------------------------

-- Le jour courant dans le fuseau comptable.
CREATE FUNCTION private.fac_aujourdhui()
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (pg_catalog.now() AT TIME ZONE private.bf1_fuseau_comptable())::date;
$function$;

-- Une ligne de politique rendue au format du contrat Dart.
CREATE FUNCTION private.fac_politique_json(p public.politiques_commerciales, p_statut text)
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
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'aPartirDuRang', (r ->> 'a_partir_du_rang')::integer,
               'remise', private.bf1_montant((r ->> 'remise_mineur')::bigint, p.devise))
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
        FROM pg_catalog.jsonb_array_elements(p.budgets) AS b), '[]'::jsonb));
$function$;

-- Un montant `{mineur, devise}` du contrat, dans la devise attendue.
CREATE FUNCTION private.fac_montant_lu(p_json jsonb, p_cle text, p_devise text)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v jsonb := p_json -> p_cle;
BEGIN
  IF v IS NULL OR pg_catalog.jsonb_typeof(v) <> 'object'
     OR pg_catalog.jsonb_typeof(v -> 'mineur') <> 'number'
     OR v ->> 'devise' IS DISTINCT FROM p_devise THEN
    RAISE EXCEPTION 'montant invalide : %', p_cle USING ERRCODE = '22023';
  END IF;
  RETURN (v ->> 'mineur')::bigint;
END;
$function$;

-- Un entier du contrat.
CREATE FUNCTION private.fac_entier_lu(p_json jsonb, p_cle text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF pg_catalog.jsonb_typeof(p_json -> p_cle) IS DISTINCT FROM 'number'
     OR (p_json ->> p_cle) !~ '^-?[0-9]+$' THEN
    RAISE EXCEPTION 'entier invalide : %', p_cle USING ERRCODE = '22023';
  END IF;
  RETURN (p_json ->> p_cle)::integer;
END;
$function$;

-- Lit et valide une politique au format du contrat. Toute forme inattendue
-- leve 22023 ; les bornes metier sont celles de la table.
CREATE FUNCTION private.fac_politique_lue(p jsonb)
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
    IF private.fac_entier_lu(v_e, 'aPartirDuRang') < 1
       OR private.fac_montant_lu(v_e, 'remise', v_devise) > 0 THEN
      RAISE EXCEPTION 'remise de rang invalide' USING ERRCODE = '22023';
    END IF;
    IF private.fac_montant_lu(v_e, 'remise', v_devise) + r.tarif_enfant_mineur < 0 THEN
      RAISE EXCEPTION 'remise superieure au tarif' USING ERRCODE = '22023';
    END IF;
    v_rangs := v_rangs || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'a_partir_du_rang', private.fac_entier_lu(v_e, 'aPartirDuRang'),
      'remise_mineur', private.fac_montant_lu(v_e, 'remise', v_devise)));
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

  r.allocation_internet_mineur := CASE
    WHEN p -> 'allocationInternet' IS NULL OR pg_catalog.jsonb_typeof(p -> 'allocationInternet') = 'null' THEN NULL
    ELSE private.fac_montant_lu(p, 'allocationInternet', v_devise) END;

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
  RETURN r;
END;
$function$;

-- La remise du membre payant de rang p_rang (1 = premier), ou nulle : la
-- remise du plus grand palier `a_partir_du_rang` inferieur ou egal au rang.
CREATE FUNCTION private.fac_remise_rang(p public.politiques_commerciales, p_rang integer)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT (r ->> 'remise_mineur')::bigint
    FROM pg_catalog.jsonb_array_elements(p.remises_par_rang) AS r
   WHERE (r ->> 'a_partir_du_rang')::integer <= p_rang
   ORDER BY (r ->> 'a_partir_du_rang')::integer DESC
   LIMIT 1;
$function$;

-- La version suivante d'un numero vX.Y.Z : vX.(Y+1).0.
CREATE FUNCTION private.fac_version_suivante(p_version text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT 'v' || pg_catalog.split_part(pg_catalog.substr(p_version, 2), '.', 1) || '.'
         || (pg_catalog.split_part(p_version, '.', 2)::integer + 1)::text || '.0';
$function$;

-- La derniere version publiee (par date d'effet).
CREATE FUNCTION private.fac_derniere_politique()
RETURNS public.politiques_commerciales
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p.* FROM public.politiques_commerciales p ORDER BY p.date_effet DESC LIMIT 1;
$function$;

-- La politique en vigueur au jour p_jour (fuseau comptable), ou nulle.
CREATE FUNCTION private.fac_politique_au(p_jour date)
RETURNS public.politiques_commerciales
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p.* FROM public.politiques_commerciales p
   WHERE p.date_effet <= p_jour
   ORDER BY p.date_effet DESC LIMIT 1;
$function$;

-- La premiere date d'effet libre : le premier jour d'un mois strictement
-- posterieur a aujourd'hui et a toute version publiee.
CREATE FUNCTION private.fac_prochaine_date_effet()
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (pg_catalog.date_trunc('month', greatest(
            private.fac_aujourdhui(),
            coalesce((SELECT max(p.date_effet) FROM public.politiques_commerciales p),
                     private.fac_aujourdhui())))
          + interval '1 month')::date;
$function$;

-- Lecture reservee a la direction et a la comptabilite, comptes valides.
CREATE FUNCTION private.fac_lecteur_politique()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_role() IN ('admin', 'accountant')
                  AND public.app_account_valid(), false);
$function$;

-- ---------------------------------------------------------------------------
-- RPC.
-- ---------------------------------------------------------------------------

-- PortPolitiquesCommerciales.active() (FI-BR-01).
CREATE FUNCTION public.politique_commerciale_active()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.politiques_commerciales;
BEGIN
  IF NOT private.fac_lecteur_politique() THEN
    RAISE EXCEPTION 'politique commerciale reservee a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  v := private.fac_politique_au(private.fac_aujourdhui());
  IF v.version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  RETURN private.fac_politique_json(v, 'publiee');
END;
$function$;

-- PortPolitiquesCommerciales.versions() (FI-BR-02) : le brouillon propose,
-- puis les versions publiees, la plus recente d'abord.
CREATE FUNCTION public.politiques_commerciales_versions()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_derniere public.politiques_commerciales;
  v_brouillon public.politiques_commerciales;
BEGIN
  IF NOT private.fac_lecteur_politique() THEN
    RAISE EXCEPTION 'politique commerciale reservee a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  v_derniere := private.fac_derniere_politique();
  IF v_derniere.version IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;
  v_brouillon := v_derniere;
  v_brouillon.version := private.fac_version_suivante(v_derniere.version);
  v_brouillon.date_effet := private.fac_prochaine_date_effet();
  RETURN pg_catalog.jsonb_build_array(private.fac_politique_json(v_brouillon, 'brouillon'))
    || coalesce((SELECT pg_catalog.jsonb_agg(private.fac_politique_json(p, 'publiee')
                                             ORDER BY p.date_effet DESC)
                   FROM public.politiques_commerciales p), '[]'::jsonb);
END;
$function$;

-- PortPolitiquesCommerciales.publier() (FI-BR-02).
CREATE FUNCTION public.publier_politique_commerciale(p_politique jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.politiques_commerciales;
  v_derniere public.politiques_commerciales;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid() AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'publication des prix reservee a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;
  v := private.fac_politique_lue(p_politique);

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('politiques-commerciales', 0));
  v_derniere := private.fac_derniere_politique();
  IF v_derniere.version IS NOT NULL
     AND v.version IS DISTINCT FROM private.fac_version_suivante(v_derniere.version) THEN
    RAISE EXCEPTION 'version attendue : %', private.fac_version_suivante(v_derniere.version)
      USING ERRCODE = '22023';
  END IF;
  IF v.date_effet <= private.fac_aujourdhui()
     OR (v_derniere.version IS NOT NULL AND v.date_effet <= v_derniere.date_effet) THEN
    RAISE EXCEPTION 'la date d''effet doit etre future et posterieure a la derniere version'
      USING ERRCODE = '22023';
  END IF;
  IF v_derniere.version IS NOT NULL AND v.devise <> v_derniere.devise THEN
    RAISE EXCEPTION 'changement de devise non pris en charge' USING ERRCODE = '22023';
  END IF;

  v.publiee_par := auth.uid();
  v.publiee_le := pg_catalog.clock_timestamp();
  INSERT INTO public.politiques_commerciales SELECT v.*;

  PERFORM public.log_sensitive_access('politique_commerciale_publiee', 'politiques_commerciales',
    v.version, pg_catalog.jsonb_build_object('date_effet', v.date_effet));
  RETURN private.fac_politique_json(v, 'publiee');
END;
$function$;

-- PortPolitiquesCommerciales.apercuFamille() : la mensualite de chaque rang
-- payant (1 a 5) et le total, sous la politique fournie (brouillon ou non).
CREATE FUNCTION public.apercu_politique_famille(p_politique jsonb, p_enfants integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.politiques_commerciales;
  v_lignes jsonb := '[]'::jsonb;
  v_total bigint := 0;
  v_remise bigint;
  v_rang integer;
BEGIN
  IF NOT private.fac_lecteur_politique() THEN
    RAISE EXCEPTION 'apercu reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_enfants IS NULL OR p_enfants NOT BETWEEN 1 AND 5 THEN
    RAISE EXCEPTION 'nombre d''enfants hors bornes (1 a 5)' USING ERRCODE = '22023';
  END IF;
  v := private.fac_politique_lue(p_politique);
  FOR v_rang IN 1..p_enfants LOOP
    v_remise := private.fac_remise_rang(v, v_rang);
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'rang', v_rang,
      'tarif', private.bf1_montant(v.tarif_enfant_mineur, v.devise),
      'remise', CASE WHEN v_remise IS NULL THEN NULL ELSE private.bf1_montant(v_remise, v.devise) END,
      'mensualite', private.bf1_montant(v.tarif_enfant_mineur + coalesce(v_remise, 0), v.devise)));
    v_total := v_total + v.tarif_enfant_mineur + coalesce(v_remise, 0);
  END LOOP;
  RETURN pg_catalog.jsonb_build_object('enfants', v_lignes,
    'total', private.bf1_montant(v_total, v.devise));
END;
$function$;

-- PortPolitiquesCommerciales.apercuEnseignant() : guide §1.4,
-- taux = min(plafond, base + (plafond - base) x eligibles / capacite),
-- arrondi a l'unite mineure inferieure.
CREATE FUNCTION public.apercu_politique_enseignant(p_politique jsonb, p_capacite integer, p_eligibles integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.politiques_commerciales;
  v_eligibles integer;
  v_taux bigint;
BEGIN
  IF NOT private.fac_lecteur_politique() THEN
    RAISE EXCEPTION 'apercu reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_capacite IS NULL OR p_capacite NOT BETWEEN 1 AND 50
     OR p_eligibles IS NULL OR p_eligibles < 0 THEN
    RAISE EXCEPTION 'capacite ou eligibles hors bornes' USING ERRCODE = '22023';
  END IF;
  v := private.fac_politique_lue(p_politique);
  v_eligibles := least(p_eligibles, p_capacite);
  v_taux := least(v.plafond_horaire_mineur,
    v.base_horaire_mineur
    + (v.plafond_horaire_mineur - v.base_horaire_mineur) * v_eligibles / p_capacite);
  RETURN pg_catalog.jsonb_build_object(
    'capacite', p_capacite,
    'eligibles', v_eligibles,
    'baseHoraire', private.bf1_montant(v.base_horaire_mineur, v.devise),
    'occupation', private.bf1_montant(v_taux - v.base_horaire_mineur, v.devise),
    'tauxHoraire', private.bf1_montant(v_taux, v.devise),
    'plafondHoraire', private.bf1_montant(v.plafond_horaire_mineur, v.devise));
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
    'private.fac_aujourdhui()'::regprocedure,
    'private.fac_politique_json(public.politiques_commerciales,text)'::regprocedure,
    'private.fac_montant_lu(jsonb,text,text)'::regprocedure,
    'private.fac_entier_lu(jsonb,text)'::regprocedure,
    'private.fac_politique_lue(jsonb)'::regprocedure,
    'private.fac_remise_rang(public.politiques_commerciales,integer)'::regprocedure,
    'private.fac_version_suivante(text)'::regprocedure,
    'private.fac_derniere_politique()'::regprocedure,
    'private.fac_politique_au(date)'::regprocedure,
    'private.fac_prochaine_date_effet()'::regprocedure,
    'private.fac_lecteur_politique()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.politique_commerciale_active()'::regprocedure,
    'public.politiques_commerciales_versions()'::regprocedure,
    'public.publier_politique_commerciale(jsonb)'::regprocedure,
    'public.apercu_politique_famille(jsonb,integer)'::regprocedure,
    'public.apercu_politique_enseignant(jsonb,integer,integer)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17. FAC-A-01.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid::text LIKE 'publier%' THEN 'ROLE_POSITIVE_ADMIN_AAL2'
           ELSE 'ROLE_POSITIVE_ADMIN_OR_ACCOUNTANT' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.politique_commerciale_active()'::regprocedure,
    'public.politiques_commerciales_versions()'::regprocedure,
    'public.publier_politique_commerciale(jsonb)'::regprocedure,
    'public.apercu_politique_famille(jsonb,integer)'::regprocedure,
    'public.apercu_politique_enseignant(jsonb,integer,integer)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FAC-A-01 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'fac\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FAC-A-01 : aide privee executable par un client';
  END IF;
  IF (SELECT count(*) FROM public.politiques_commerciales) <> 1 THEN
    RAISE EXCEPTION 'FAC-A-01 : version de lancement absente';
  END IF;
END;
$postflight$;

COMMIT;
