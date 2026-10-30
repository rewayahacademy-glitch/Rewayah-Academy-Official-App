-- TRANSPARENCE (directeur, 30/10/2026 ; DECISION-BIBLIOTHEQUE-ET-RESTES §2,
-- DECISION-TARIFS-2026-10-18, decision du 22/10) : ce qu'une famille a le droit
-- de lire de la politique commerciale, et la repartition de chaque paiement en
-- pourcentages.
--
-- * `politique_commerciale_active` reste reservee a la direction et a la
--   comptabilite : elle porte la paie horaire des enseignants, les marges et les
--   budgets. Le foyer lit `politique_commerciale_famille`, qui ne rend que la
--   version, la date d'effet, les tarifs publics, l'essai, les remises par rang
--   et les moyens de paiement actifs, plus la repartition ci-dessous.
-- * `repartitions_paiement` : une repartition par version des prix, en pour
--   mille du paiement d'un eleve (somme = 1000), jamais un montant de charge.
--   Elle est publiee avec la version des prix qu'elle estime et revue a chaque
--   nouvelle version. Aucun client n'y ecrit ni ne la lit directement.
-- * Repartition de la v2.0.0 (55 $ enfant, 65 $ adulte), base decidee par le
--   pilote le 30/10 : 100 eleves, 50 enfants et 50 adultes, chacun au plein
--   tarif et present a toutes les seances, soit 6 000 $ encaisses par mois.
--   Charges du 19/10 (DECISION-TARIFS) : enseignant 47 % du prix ; frais de
--   carte et de change 5 % de l'encaisse ; envoi de la paie 2 % de la paie plus
--   1 $ par versement (11 enseignants, comme le scenario de reference) ; visio
--   150 $, application 290 $, e-mails 20 $, stockage 5 $, comptable 150 $,
--   developpeur 600 $, administration 500 $ ; impot britannique sur les
--   societes 19 % du resultat. Chaque charge est arrondie au dixieme de point le
--   plus proche ; le benefice est le reste (148,2 pour mille calcules, 149
--   publies). Detail : docs/current/TRANSPARENCE-REPARTITION-2026-10-31.md.
BEGIN;

-- La forme d'une repartition : une liste de postes connus, chacun une fois,
-- de 0 a 1000 pour mille, dont la somme fait 1000.
CREATE FUNCTION private.rp_postes_valides(p jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_typeof(p) = 'array'
     AND pg_catalog.jsonb_array_length(p) > 0
     AND NOT EXISTS (
           SELECT 1 FROM pg_catalog.jsonb_array_elements(p) AS e
            WHERE pg_catalog.jsonb_typeof(e) <> 'object'
               OR NOT (e ->> 'poste' = ANY (ARRAY[
                    'enseignant', 'frais_carte_change', 'frais_envoi_paie',
                    'visioconference', 'application_hebergement', 'emails',
                    'stockage', 'comptabilite', 'developpement', 'administration',
                    'impot_societes', 'benefice']))
               OR pg_catalog.jsonb_typeof(e -> 'pour_mille') <> 'number'
               OR (e ->> 'pour_mille')::numeric <> pg_catalog.trunc((e ->> 'pour_mille')::numeric)
               OR (e ->> 'pour_mille')::numeric NOT BETWEEN 0 AND 1000)
     AND (SELECT count(DISTINCT e ->> 'poste') FROM pg_catalog.jsonb_array_elements(p) AS e)
         = pg_catalog.jsonb_array_length(p)
     AND (SELECT sum((e ->> 'pour_mille')::integer) FROM pg_catalog.jsonb_array_elements(p) AS e)
         = 1000;
$function$;

CREATE TABLE public.repartitions_paiement (
  politique_version text PRIMARY KEY
    REFERENCES public.politiques_commerciales(version),
  base_eleves_enfants integer NOT NULL CHECK (base_eleves_enfants >= 0),
  base_eleves_adultes integer NOT NULL CHECK (base_eleves_adultes >= 0),
  postes jsonb NOT NULL CHECK (private.rp_postes_valides(postes)),
  publiee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT repartitions_paiement_base CHECK (base_eleves_enfants + base_eleves_adultes > 0)
);
COMMENT ON TABLE public.repartitions_paiement IS
  'TRANSPARENCE: repartition estimee du paiement d''un eleve, en pour mille (somme 1000), par version des prix. Lue par politique_commerciale_famille seulement.';

ALTER TABLE public.repartitions_paiement ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.repartitions_paiement FROM PUBLIC, anon, authenticated, service_role, agent_ro;

INSERT INTO public.repartitions_paiement (
  politique_version, base_eleves_enfants, base_eleves_adultes, postes)
VALUES ('v2.0.0', 50, 50, '[
  {"poste": "enseignant", "pour_mille": 470},
  {"poste": "frais_carte_change", "pour_mille": 50},
  {"poste": "frais_envoi_paie", "pour_mille": 11},
  {"poste": "visioconference", "pour_mille": 25},
  {"poste": "application_hebergement", "pour_mille": 48},
  {"poste": "emails", "pour_mille": 3},
  {"poste": "stockage", "pour_mille": 1},
  {"poste": "comptabilite", "pour_mille": 25},
  {"poste": "developpement", "pour_mille": 100},
  {"poste": "administration", "pour_mille": 83},
  {"poste": "impot_societes", "pour_mille": 35},
  {"poste": "benefice", "pour_mille": 149}
]'::jsonb);

-- La repartition a montrer : celle de la version des prix en vigueur ; a
-- defaut, celle de la prochaine version publiee (la page dit sa date).
CREATE FUNCTION private.rp_repartition_json(p_jour date)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
           'politiqueVersion', r.politique_version,
           'dateEffet', pg_catalog.to_char(p.date_effet, 'YYYY-MM-DD'),
           'baseElevesEnfants', r.base_eleves_enfants,
           'baseElevesAdultes', r.base_eleves_adultes,
           'postes', (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                               'poste', e ->> 'poste',
                               'pourMille', (e ->> 'pour_mille')::integer) ORDER BY o)
                        FROM pg_catalog.jsonb_array_elements(r.postes) WITH ORDINALITY AS x(e, o)))
    FROM public.repartitions_paiement r
    JOIN public.politiques_commerciales p ON p.version = r.politique_version
   ORDER BY (p.date_effet <= p_jour) DESC,
            CASE WHEN p.date_effet <= p_jour THEN p.date_effet END DESC,
            p.date_effet ASC
   LIMIT 1;
$function$;

-- PortPolitiquesCommerciales.famille() : la politique en vigueur, sans paie,
-- sans marge, sans budget ; tout compte connecte.
CREATE FUNCTION public.politique_commerciale_famille()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.politiques_commerciales;
  j jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'politique commerciale : connexion requise' USING ERRCODE = '42501';
  END IF;
  v := private.fac_politique_au(private.fac_aujourdhui());
  IF v.version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  j := private.fac_politique_json(v, 'publiee');
  RETURN pg_catalog.jsonb_build_object(
    'version', j -> 'version',
    'dateEffet', j -> 'dateEffet',
    'tarifEnfant', j -> 'tarifEnfant',
    'tarifAdulte', j -> 'tarifAdulte',
    'essaiActif', j -> 'essaiActif',
    'essaisMax', j -> 'essaisMax',
    'remisesParRang', j -> 'remisesParRang',
    'railsActifs', j -> 'railsActifs',
    'repartition', private.rp_repartition_json(private.fac_aujourdhui()));
END;
$function$;

DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.rp_postes_valides(jsonb)'::regprocedure,
    'private.rp_repartition_json(date)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  v_oid := 'public.politique_commerciale_famille()'::regprocedure;
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=AUTHENTICATED_PUBLIC_PRICES; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-31. TRANSPARENCE.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.politique_commerciale_famille()'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'TRANSPARENCE : DEFINER ou ACL invalide pour %', v_oid;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'rp\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'TRANSPARENCE : aide privee executable par un client';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.repartitions_paiement', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.repartitions_paiement', 'SELECT') THEN
    RAISE EXCEPTION 'TRANSPARENCE : table lisible par un client';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.repartitions_paiement WHERE politique_version = 'v2.0.0') THEN
    RAISE EXCEPTION 'TRANSPARENCE : repartition v2.0.0 absente';
  END IF;
END;
$postflight$;

COMMIT;
