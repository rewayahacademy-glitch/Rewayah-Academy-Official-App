-- PUB-TARIFS (18/10/2026) : les tarifs du site public lus dans la base.
--
-- Une seule porte, `public.tarifs_publics()`, sans parametre : elle rend la
-- politique commerciale en vigueur aujourd'hui (fuseau comptable) et, si une
-- version deja publiee prend effet plus tard, la suivante avec sa date.
--
-- Liste blanche explicite de cles : version, date d'effet, devise, prix,
-- remises du foyer, prepaiement, parrainage, bourse (pourcentage et duree
-- seulement), plafond de cumul, taille des classes, essai. JAMAIS : paie des
-- enseignants (taux, plafonds, duree due), marges, budgets, rails de paiement,
-- jours de relance ou de suspension, auteur, date de publication, donnees de
-- famille. Aucune ligne de table n'est serialisee d'un bloc (pas de to_jsonb).
--
-- Droits : EXECUTE a anon et authenticated sur cette seule fonction. Aucun
-- droit nouveau sur les tables ; la RLS de `politiques_commerciales` reste
-- reservee a la direction et a la comptabilite.
--
-- Le site ne l'appelle pas depuis le navigateur : `site-public/build_site.py`
-- la lit au moment du build (voir ce fichier).
BEGIN;

-- Age a partir duquel s'applique la formule adulte (DECISION-TARIFS-2026-10-18 :
-- 18 ans). Porte par la politique versionnee, pas par le code.
ALTER TABLE public.politiques_commerciales
  ADD COLUMN age_formule_adulte smallint NOT NULL DEFAULT 18
  CHECK (age_formule_adulte BETWEEN 14 AND 25);
COMMENT ON COLUMN public.politiques_commerciales.age_formule_adulte IS
  'Age a partir duquel la formule adulte s''applique (18 au 18/10/2026).';

-- Une nouvelle version publiee sans cet age herite de la version precedente.
CREATE FUNCTION private.pub_age_formule_herite()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.age_formule_adulte IS NULL THEN
    SELECT p.age_formule_adulte INTO NEW.age_formule_adulte
      FROM public.politiques_commerciales p
     WHERE p.date_effet <= NEW.date_effet
     ORDER BY p.date_effet DESC
     LIMIT 1;
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.pub_age_formule_herite() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER politiques_age_formule_herite
  BEFORE INSERT ON public.politiques_commerciales
  FOR EACH ROW EXECUTE FUNCTION private.pub_age_formule_herite();

-- Une politique, au format public (liste blanche).
CREATE FUNCTION private.pub_tarifs_politique(p public.politiques_commerciales)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'version', p.version,
    'dateEffet', pg_catalog.to_char(p.date_effet, 'YYYY-MM-DD'),
    'devise', p.devise,
    -- Les prix publics s'entendent hors taxes (DECISION-TARIFS-2026-10-18).
    'horsTaxes', true,
    'ageAdulte', p.age_formule_adulte,
    'tarifEnfantMineur', p.tarif_enfant_mineur,
    'tarifAdulteMineur', p.tarif_adulte_mineur,
    'essaiActif', p.essai_actif,
    'essaisMax', p.essais_max,
    'remisesFoyer', coalesce((
      SELECT pg_catalog.jsonb_agg(
               pg_catalog.jsonb_build_object('aPartirDuRang', (r ->> 'a_partir_du_rang')::integer)
               || CASE WHEN r ? 'pour_mille'
                    THEN pg_catalog.jsonb_build_object('pourMille', (r ->> 'pour_mille')::integer)
                    ELSE pg_catalog.jsonb_build_object('montantMineur', (r ->> 'remise_mineur')::bigint) END
               ORDER BY (r ->> 'a_partir_du_rang')::integer)
        FROM pg_catalog.jsonb_array_elements(p.remises_par_rang) AS r), '[]'::jsonb),
    'prepaiement', CASE
      WHEN p.prepaiement_trimestriel_pour_mille IS NULL AND p.prepaiement_annuel_pour_mille IS NULL THEN NULL
      ELSE pg_catalog.jsonb_build_object(
             'trimestrielPourMille', p.prepaiement_trimestriel_pour_mille,
             'annuelPourMille', p.prepaiement_annuel_pour_mille) END,
    'parrainageCreditMineur', p.parrainage_credit_mineur,
    'bourse', CASE
      WHEN p.bourse_pour_mille IS NULL THEN NULL
      ELSE pg_catalog.jsonb_build_object(
             'pourMille', p.bourse_pour_mille,
             'dureeMois', p.bourse_duree_mois) END,
    'cumulMaxPourMille', p.cumul_max_pour_mille,
    'classes', pg_catalog.jsonb_build_object(
      'tailleEnfant', p.capacite_enfant,
      'tailleAdulte', p.capacite_adulte,
      'ouvertureMinimum', p.minimum_ouverture));
$function$;

CREATE FUNCTION public.tarifs_publics()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_jour date := private.fac_aujourdhui();
  v_courante public.politiques_commerciales := private.fac_politique_au(v_jour);
  v_suivante public.politiques_commerciales;
BEGIN
  -- Fonction volontairement publique : elle ne lit aucune donnee de personne,
  -- seulement la politique deja publiee.
  IF v_courante.version IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('courante', NULL, 'suivante', NULL);
  END IF;
  SELECT p.* INTO v_suivante FROM public.politiques_commerciales p
   WHERE p.date_effet > v_jour ORDER BY p.date_effet ASC LIMIT 1;
  RETURN pg_catalog.jsonb_build_object(
    'courante', private.pub_tarifs_politique(v_courante),
    'suivante', CASE WHEN v_suivante.version IS NULL THEN NULL
                     ELSE private.pub_tarifs_politique(v_suivante) END);
END;
$function$;

COMMENT ON FUNCTION public.tarifs_publics() IS
  'PUB-TARIFS : tarifs publics (liste blanche de cles) de la politique en vigueur et de la suivante publiee. Ouverte a anon par choix : aucune donnee de personne.';

ALTER FUNCTION private.pub_tarifs_politique(public.politiques_commerciales) OWNER TO postgres;
ALTER FUNCTION public.tarifs_publics() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.pub_tarifs_politique(public.politiques_commerciales)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION public.tarifs_publics() FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.tarifs_publics() TO anon, authenticated;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.tarifs_publics()'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=PUBLIC_READ_WHITELIST; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. PUB-TARIFS : lecture publique voulue, liste blanche de cles.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('anon', 'public.tarifs_publics()'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.tarifs_publics()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PUB-TARIFS : tarifs_publics() doit etre ouverte a anon et authenticated';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.pub_tarifs_politique(public.politiques_commerciales)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.pub_tarifs_politique(public.politiques_commerciales)'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'PUB-TARIFS : l''aide privee ne doit pas etre appelable';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.politiques_commerciales', 'SELECT') THEN
    RAISE EXCEPTION 'PUB-TARIFS : anon ne doit jamais lire la table des politiques';
  END IF;
END;
$postflight$;

COMMIT;
