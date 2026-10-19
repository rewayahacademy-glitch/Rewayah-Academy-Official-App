-- FAC-C-01 (17/10/2026) : la saisie d'un paiement recu hors application,
-- attribue a un eleve (DB-CPT-03 ; 07_MEMOIRE_PEDAGOGIE_FINANCE : « paiement
-- initial hors application enregistre et valide manuellement » ; passation du
-- 17/10, point 3).
--
-- * `enregistrer_paiement` : la direction ou la comptabilite (compte valide)
--   inscrit un paiement deja recu pour un profil eleve. Le portefeuille du
--   foyer est cree s'il manque, dans la devise de la politique en vigueur ;
--   l'ecriture `credit` porte le beneficiaire et compte tout de suite
--   (`confirme_par_prestataire_le`, pose par le serveur seul : le paiement est
--   valide par la personne qui le saisit). La facture du mois courant est
--   emise si elle manque, puis les factures que le solde couvre en entier sont
--   financees (FAC-B-01). Aucun montant ni aucun etat ne viennent du client.
-- * Idempotente par `p_cle` : une meme saisie envoyee deux fois n'ecrit qu'une
--   fois et rend le meme resultat.
-- * `eleves_pour_paiement` : les profils eleves que la saisie peut viser, avec
--   le reste a payer de chacun, pour preremplir le montant (K-57).
BEGIN;

CREATE TABLE public.paiements_saisis (
  cle uuid PRIMARY KEY,
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  entry_id bigint NOT NULL UNIQUE REFERENCES public.wallet_entries(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  reference text CHECK (reference IS NULL OR pg_catalog.length(reference) BETWEEN 1 AND 200),
  saisi_par uuid NOT NULL REFERENCES public.profiles(id),
  saisi_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
COMMENT ON TABLE public.paiements_saisis IS
  'FAC-C-01: paiements recus hors application, saisis par la direction ou la comptabilite ; une ligne par cle d''idempotence.';
ALTER TABLE public.paiements_saisis ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.paiements_saisis FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.paiements_saisis TO authenticated;
CREATE POLICY paiements_saisis_lecture_direction ON public.paiements_saisis
  FOR SELECT TO authenticated
  USING (coalesce((SELECT public.app_role()) IN ('admin', 'accountant')
                  AND (SELECT public.app_account_valid()), false));

-- Le reste a payer d'un profil : factures non financees moins le solde
-- positif, jamais negatif.
CREATE FUNCTION private.fac_reste_a_payer(p_profil uuid)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT greatest(coalesce((SELECT sum(f.total_mineur) FROM public.factures_mensuelles f
                             WHERE f.profile_id = p_profil AND f.statut = 'a_financer'), 0)
                  - greatest(private.fac_solde_profil(p_profil), 0), 0)::bigint;
$function$;

CREATE FUNCTION private.fac_saisisseur()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_role() IN ('admin', 'accountant')
                  AND public.app_account_valid(), false);
$function$;

-- Les profils eleves que la saisie peut viser, le plus a regulariser d'abord.
CREATE FUNCTION public.eleves_pour_paiement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
BEGIN
  IF NOT private.fac_saisisseur() THEN
    RAISE EXCEPTION 'saisie des paiements reservee a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  IF v_pol.version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'profilId', x.id, 'prenom', x.first_name, 'nom', x.last_name,
             'matricule', x.immutable_id, 'foyerId', x.household_id,
             'resteAPayer', private.bf1_montant(x.reste, coalesce(x.currency, v_pol.devise)))
           ORDER BY x.reste DESC, x.first_name, x.id)
      FROM (SELECT pr.id, pr.first_name, pr.last_name, pr.immutable_id, pr.household_id,
                   w.currency, private.fac_reste_a_payer(pr.id) AS reste
              FROM public.profiles pr
              JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
              LEFT JOIN public.wallets w ON w.household_id = pr.household_id
             WHERE pr.deleted_at IS NULL AND pr.household_id IS NOT NULL) x), '[]'::jsonb);
END;
$function$;

-- Enregistre un paiement deja recu pour un profil eleve.
CREATE FUNCTION public.enregistrer_paiement(
  p_profil uuid,
  p_montant_mineur bigint,
  p_devise text,
  p_reference text,
  p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_deja public.paiements_saisis;
  v_foyer uuid;
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
  v_w public.wallets;
  v_entry bigint;
  v_ref text := nullif(pg_catalog.btrim(coalesce(p_reference, '')), '');
BEGIN
  IF NOT private.fac_saisisseur() THEN
    RAISE EXCEPTION 'saisie des paiements reservee a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  IF p_cle IS NULL OR p_profil IS NULL THEN
    RAISE EXCEPTION 'cle ou profil absent' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('paiement:' || p_cle::text, 0));
  SELECT * INTO v_deja FROM public.paiements_saisis WHERE cle = p_cle;
  IF v_deja.cle IS NOT NULL THEN
    IF v_deja.profile_id <> p_profil OR v_deja.montant_mineur <> p_montant_mineur
       OR v_deja.devise <> p_devise THEN
      RAISE EXCEPTION 'cle deja utilisee pour un autre paiement' USING ERRCODE = '22023';
    END IF;
    RETURN pg_catalog.jsonb_build_object('paiement', v_deja.entry_id::text, 'nouveau', false,
      'finance', private.bf1_finance_profil(p_profil));
  END IF;

  IF p_montant_mineur IS NULL OR p_montant_mineur <= 0 OR p_montant_mineur > 100000000 THEN
    RAISE EXCEPTION 'montant invalide' USING ERRCODE = '22023';
  END IF;
  IF v_ref IS NOT NULL AND pg_catalog.length(v_ref) > 200 THEN
    RAISE EXCEPTION 'reference trop longue' USING ERRCODE = '22023';
  END IF;
  IF v_pol.version IS NULL THEN
    RAISE EXCEPTION 'aucune politique commerciale en vigueur' USING ERRCODE = 'P0002';
  END IF;
  SELECT pr.household_id INTO v_foyer
    FROM public.profiles pr JOIN public.student_profiles sp ON sp.profile_id = pr.id
   WHERE pr.id = p_profil AND pr.deleted_at IS NULL AND sp.deleted_at IS NULL;
  IF v_foyer IS NULL THEN
    RAISE EXCEPTION 'profil eleve introuvable' USING ERRCODE = 'P0002';
  END IF;
  v_w := private.fac_portefeuille(v_foyer, v_pol.devise);
  IF p_devise IS DISTINCT FROM v_w.currency THEN
    RAISE EXCEPTION 'devise differente de celle du foyer' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.wallet_entries
    (wallet_id, amount_minor, currency, reference_type, beneficiaire_id, confirme_par_prestataire_le)
  VALUES (v_w.id, p_montant_mineur, v_w.currency, 'credit', p_profil, pg_catalog.clock_timestamp())
  RETURNING id INTO v_entry;
  INSERT INTO public.paiements_saisis (cle, profile_id, entry_id, montant_mineur, devise, reference, saisi_par)
  VALUES (p_cle, p_profil, v_entry, p_montant_mineur, v_w.currency, v_ref, auth.uid());

  PERFORM private.fac_emettre_facture(p_profil, private.fac_mois_courant(), auth.uid());
  PERFORM private.fac_financer_profil(p_profil);

  PERFORM public.log_sensitive_access('paiement_saisi', 'wallet_entries', v_entry::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'montant_mineur', p_montant_mineur,
      'devise', v_w.currency));
  RETURN pg_catalog.jsonb_build_object('paiement', v_entry::text, 'nouveau', true,
    'finance', private.bf1_finance_profil(p_profil));
END;
$function$;

DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_reste_a_payer(uuid)'::regprocedure,
    'private.fac_saisisseur()'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.eleves_pour_paiement()'::regprocedure,
    'public.enregistrer_paiement(uuid,bigint,text,text,uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_OR_ACCOUNTANT; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17. FAC-C-01.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.eleves_pour_paiement()'::regprocedure,
    'public.enregistrer_paiement(uuid,bigint,text,text,uuid)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FAC-C-01 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'fac\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FAC-C-01 : aide privee executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
