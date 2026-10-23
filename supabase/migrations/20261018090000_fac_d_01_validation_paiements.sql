-- FAC-D-01 (18/10/2026) : un paiement recu hors application, saisi par la
-- comptabilite, attend la validation de la direction avant d'etre credite.
--
-- Source : dossier maitre du 14/10/2026, « Permissions par role », ligne
-- « Crediter apres paiement manuel » : la direction approuve, la comptabilite
-- rapproche et soumet, l'admin operationnel ne credite pas, la famille depose
-- sa reference. Et : « au lancement avec une seule personne administrative,
-- le directeur peut assumer les taches operationnelles et financieres avec
-- motif, preuve et audit » ; « des delegation, separer preparation et
-- approbation ». Decision Q-8 = (a) du 05/10 (CPT-VAL-1) : la demande arrive
-- dans l'onglet « A valider » de la direction, Valider ou Refuser avec motif,
-- celui qui demande ne decide jamais.
--
-- * `finance_validations` : les demandes de validation (nature
--   `paiement_recu` pour ce lot), lues et decidees par RPC seulement.
-- * `paiements_soumis` : la saisie de la comptabilite, en attente ; rien
--   n'est credite tant que la direction n'a pas valide.
-- * `enregistrer_paiement` (meme signature) : la direction credite tout de
--   suite (comme FAC-C-01) ; la comptabilite cree une demande et rend
--   `etat = validation_demandee`. La meme cle rejouee rend l'etat courant.
-- * `finance_validations_lister`, `finance_validation_decider`,
--   `finance_validation_journal` : les RPC attendues par l'ecran « A valider »
--   (`lib/core/capacites/port_validations_finance.dart`).
BEGIN;

CREATE TABLE public.finance_validations (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  nature text NOT NULL CHECK (nature IN ('paiement_recu')),
  objet_id uuid NOT NULL REFERENCES public.profiles(id),
  demandeur uuid NOT NULL REFERENCES public.profiles(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  raison text NOT NULL CHECK (raison IN ('paiement_hors_application')),
  reference text CHECK (reference IS NULL OR pg_catalog.length(reference) BETWEEN 1 AND 200),
  etat text NOT NULL DEFAULT 'en_attente' CHECK (etat IN ('en_attente', 'validee', 'refusee')),
  decideur uuid REFERENCES public.profiles(id),
  motif text CHECK (motif IS NULL OR pg_catalog.length(motif) BETWEEN 1 AND 500),
  cle_decision uuid UNIQUE,
  demande_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  decide_le timestamptz,
  CHECK ((etat = 'en_attente') = (decideur IS NULL)),
  CHECK ((etat = 'en_attente') = (decide_le IS NULL)),
  CHECK (etat <> 'refusee' OR motif IS NOT NULL),
  CHECK (decideur IS NULL OR decideur <> demandeur)
);
COMMENT ON TABLE public.finance_validations IS
  'FAC-D-01: demandes de validation de la comptabilite, decidees par la direction (Q-8 = a). Lecture et ecriture par RPC seulement.';
CREATE INDEX finance_validations_etat_idx ON public.finance_validations (etat, demande_le DESC);
CREATE INDEX finance_validations_demandeur_idx ON public.finance_validations (demandeur);
ALTER TABLE public.finance_validations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.finance_validations FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE TABLE public.paiements_soumis (
  cle uuid PRIMARY KEY,
  validation_id uuid NOT NULL UNIQUE REFERENCES public.finance_validations(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  montant_mineur bigint NOT NULL CHECK (montant_mineur > 0),
  devise text NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  reference text CHECK (reference IS NULL OR pg_catalog.length(reference) BETWEEN 1 AND 200),
  soumis_par uuid NOT NULL REFERENCES public.profiles(id),
  soumis_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
COMMENT ON TABLE public.paiements_soumis IS
  'FAC-D-01: paiements recus saisis par la comptabilite, credites seulement apres validation de la direction.';
ALTER TABLE public.paiements_soumis ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.paiements_soumis FROM PUBLIC, anon, authenticated, service_role, agent_ro;

ALTER TABLE public.paiements_saisis
  ADD COLUMN valide_par uuid REFERENCES public.profiles(id);
COMMENT ON COLUMN public.paiements_saisis.valide_par IS
  'FAC-D-01 : la direction qui a valide la saisie de la comptabilite ; nul quand la direction a saisi elle-meme.';

-- Credite un paiement deja recu : ecriture `credit` au beneficiaire, facture
-- du mois emise si elle manque, factures couvertes financees, journal. Appele
-- par la saisie de la direction et par la validation d'une saisie de la
-- comptabilite. Rend l'ecriture.
CREATE FUNCTION private.fac_crediter_paiement(
  p_cle uuid, p_profil uuid, p_montant_mineur bigint, p_devise text,
  p_reference text, p_saisi_par uuid, p_valide_par uuid)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid;
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
  v_w public.wallets;
  v_entry bigint;
BEGIN
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
  INSERT INTO public.paiements_saisis
    (cle, profile_id, entry_id, montant_mineur, devise, reference, saisi_par, valide_par)
  VALUES (p_cle, p_profil, v_entry, p_montant_mineur, v_w.currency, p_reference, p_saisi_par, p_valide_par);

  PERFORM private.fac_emettre_facture(p_profil, private.fac_mois_courant(), coalesce(p_valide_par, p_saisi_par));
  PERFORM private.fac_financer_profil(p_profil);

  PERFORM public.log_sensitive_access('paiement_saisi', 'wallet_entries', v_entry::text,
    pg_catalog.jsonb_build_object('profile_id', p_profil, 'montant_mineur', p_montant_mineur,
      'devise', v_w.currency, 'saisi_par', p_saisi_par, 'valide_par', p_valide_par));
  RETURN v_entry;
END;
$function$;

-- La devise dans laquelle un profil eleve est credite : celle du
-- portefeuille de son foyer, sinon celle de la politique en vigueur.
CREATE FUNCTION private.fac_devise_profil(p_profil uuid, p_devise_politique text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce((SELECT w.currency FROM public.wallets w
                    JOIN public.profiles pr ON pr.household_id = w.household_id
                   WHERE pr.id = p_profil), p_devise_politique);
$function$;

-- Une demande de validation, telle que la personne connectee la lit : les
-- actions sont calculees pour elle (celui qui demande ne decide jamais).
CREATE FUNCTION private.fv_json(p_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', v.id,
    'nature', v.nature,
    'date', v.demande_le,
    'demandeur', pg_catalog.btrim(coalesce(d.first_name, '') || ' ' || coalesce(d.last_name, '')),
    'objet', pg_catalog.btrim(coalesce(e.first_name, '') || ' ' || coalesce(e.last_name, ''))
             || CASE WHEN e.immutable_id IS NULL THEN '' ELSE ' (' || e.immutable_id || ')' END,
    'objetId', v.objet_id,
    'montant', private.bf1_montant(v.montant_mineur, v.devise),
    'raison', v.raison,
    'reference', v.reference,
    'etat', v.etat,
    'decideur', CASE WHEN v.decideur IS NULL THEN NULL
                     ELSE pg_catalog.btrim(coalesce(k.first_name, '') || ' ' || coalesce(k.last_name, '')) END,
    'motif', v.motif,
    'dateDecision', v.decide_le,
    'actions', CASE WHEN v.etat = 'en_attente' AND v.demandeur <> auth.uid()
                         AND public.app_role() = 'admin'
                    THEN '["approuver"]'::jsonb ELSE '[]'::jsonb END,
    'blocages', CASE WHEN v.etat = 'en_attente' AND v.demandeur = auth.uid()
                     THEN '{"approuver": "auto_paiement"}'::jsonb ELSE '{}'::jsonb END)
    FROM public.finance_validations v
    JOIN public.profiles d ON d.id = v.demandeur
    JOIN public.profiles e ON e.id = v.objet_id
    LEFT JOIN public.profiles k ON k.id = v.decideur
   WHERE v.id = p_id;
$function$;

-- Enregistre un paiement deja recu pour un profil eleve. La direction le
-- credite ; la comptabilite le soumet a la validation de la direction.
CREATE OR REPLACE FUNCTION public.enregistrer_paiement(
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
  v_soumis public.paiements_soumis;
  v_val public.finance_validations;
  v_pol public.politiques_commerciales := private.fac_politique_au(private.fac_aujourdhui());
  v_entry bigint;
  v_id uuid;
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

  -- La meme saisie rejouee : son etat courant, rien n'est ajoute.
  SELECT * INTO v_deja FROM public.paiements_saisis WHERE cle = p_cle;
  IF v_deja.cle IS NOT NULL THEN
    IF v_deja.profile_id <> p_profil OR v_deja.montant_mineur <> p_montant_mineur
       OR v_deja.devise <> p_devise THEN
      RAISE EXCEPTION 'cle deja utilisee pour un autre paiement' USING ERRCODE = '22023';
    END IF;
    RETURN pg_catalog.jsonb_build_object('etat', 'enregistre', 'paiement', v_deja.entry_id::text,
      'nouveau', false, 'finance', private.bf1_finance_profil(p_profil));
  END IF;
  SELECT * INTO v_soumis FROM public.paiements_soumis WHERE cle = p_cle;
  IF v_soumis.cle IS NOT NULL THEN
    IF v_soumis.profile_id <> p_profil OR v_soumis.montant_mineur <> p_montant_mineur
       OR v_soumis.devise <> p_devise THEN
      RAISE EXCEPTION 'cle deja utilisee pour un autre paiement' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO v_val FROM public.finance_validations WHERE id = v_soumis.validation_id;
    RETURN pg_catalog.jsonb_build_object(
      'etat', CASE v_val.etat WHEN 'refusee' THEN 'refusee' ELSE 'validation_demandee' END,
      'validation', v_val.id::text, 'motif', v_val.motif,
      'nouveau', false, 'finance', private.bf1_finance_profil(p_profil));
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

  IF public.app_role() = 'accountant' THEN
    -- La comptabilite soumet : rien n'est credite avant la direction.
    IF NOT EXISTS (SELECT 1 FROM public.profiles pr
                     JOIN public.student_profiles sp ON sp.profile_id = pr.id
                    WHERE pr.id = p_profil AND pr.deleted_at IS NULL
                      AND sp.deleted_at IS NULL AND pr.household_id IS NOT NULL) THEN
      RAISE EXCEPTION 'profil eleve introuvable' USING ERRCODE = 'P0002';
    END IF;
    IF p_devise IS DISTINCT FROM private.fac_devise_profil(p_profil, v_pol.devise) THEN
      RAISE EXCEPTION 'devise differente de celle du foyer' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.finance_validations
      (nature, objet_id, demandeur, montant_mineur, devise, raison, reference)
    VALUES ('paiement_recu', p_profil, auth.uid(), p_montant_mineur, p_devise,
            'paiement_hors_application', v_ref)
    RETURNING id INTO v_id;
    INSERT INTO public.paiements_soumis
      (cle, validation_id, profile_id, montant_mineur, devise, reference, soumis_par)
    VALUES (p_cle, v_id, p_profil, p_montant_mineur, p_devise, v_ref, auth.uid());
    PERFORM public.log_sensitive_access('paiement_soumis', 'finance_validations', v_id::text,
      pg_catalog.jsonb_build_object('profile_id', p_profil, 'montant_mineur', p_montant_mineur,
        'devise', p_devise));
    RETURN pg_catalog.jsonb_build_object('etat', 'validation_demandee', 'validation', v_id::text,
      'motif', NULL, 'nouveau', true, 'finance', private.bf1_finance_profil(p_profil));
  END IF;

  v_entry := private.fac_crediter_paiement(p_cle, p_profil, p_montant_mineur, p_devise,
                                           v_ref, auth.uid(), NULL);
  RETURN pg_catalog.jsonb_build_object('etat', 'enregistre', 'paiement', v_entry::text,
    'nouveau', true, 'finance', private.bf1_finance_profil(p_profil));
END;
$function$;

-- Les demandes visibles : toutes pour la direction, les siennes pour la
-- comptabilite ; en attente d'abord, puis les plus recentes.
CREATE FUNCTION public.finance_validations_lister(
  p_etat text DEFAULT NULL,
  p_nature text DEFAULT NULL,
  p_objet uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_role text := public.app_role()::text;
BEGIN
  IF NOT private.fac_saisisseur() THEN
    RAISE EXCEPTION 'validations reservees a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(private.fv_json(v.id)
             ORDER BY (v.etat = 'en_attente') DESC, v.demande_le DESC, v.id)
      FROM public.finance_validations v
     WHERE (v_role = 'admin' OR v.demandeur = auth.uid())
       AND (p_etat IS NULL OR v.etat = p_etat)
       AND (p_nature IS NULL OR v.nature = p_nature)
       AND (p_objet IS NULL OR v.objet_id = p_objet)), '[]'::jsonb);
END;
$function$;

-- Decide une demande. Seule la direction decide, jamais celui qui a demande ;
-- un refus porte un motif ; la meme cle rejouee rend la meme reponse.
-- Codes : RV001 demandeur, RV002 motif obligatoire, RV003 deja decidee.
CREATE FUNCTION public.finance_validation_decider(
  p_demande uuid,
  p_decision text,
  p_motif text,
  p_cle uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.finance_validations;
  s public.paiements_soumis;
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
BEGIN
  IF auth.uid() IS NULL OR NOT private.fac_saisisseur() THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF p_demande IS NULL OR p_cle IS NULL OR p_decision IS NULL
     OR p_decision NOT IN ('valider', 'refuser') THEN
    RAISE EXCEPTION 'decision invalide' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('validation:' || p_demande::text, 0));
  SELECT * INTO v FROM public.finance_validations WHERE id = p_demande FOR UPDATE;
  IF v.id IS NULL THEN
    RAISE EXCEPTION 'demande introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v.cle_decision = p_cle THEN
    RETURN private.fv_json(v.id);
  END IF;
  IF v.demandeur = auth.uid() THEN
    RAISE EXCEPTION 'demandeur_ne_peut_pas_valider' USING ERRCODE = 'RV001';
  END IF;
  IF NOT coalesce(public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING ERRCODE = '42501';
  END IF;
  IF v.etat <> 'en_attente' THEN
    RAISE EXCEPTION 'deja_decidee' USING ERRCODE = 'RV003';
  END IF;
  IF p_decision = 'refuser' AND v_motif IS NULL THEN
    RAISE EXCEPTION 'motif_obligatoire' USING ERRCODE = 'RV002';
  END IF;
  IF v_motif IS NOT NULL AND pg_catalog.length(v_motif) > 500 THEN
    RAISE EXCEPTION 'motif trop long' USING ERRCODE = '22023';
  END IF;

  IF p_decision = 'valider' AND v.nature = 'paiement_recu' THEN
    SELECT * INTO s FROM public.paiements_soumis WHERE validation_id = v.id;
    PERFORM private.fac_crediter_paiement(s.cle, s.profile_id, s.montant_mineur, s.devise,
                                          s.reference, s.soumis_par, auth.uid());
  END IF;

  UPDATE public.finance_validations
     SET etat = CASE p_decision WHEN 'valider' THEN 'validee' ELSE 'refusee' END,
         decideur = auth.uid(),
         motif = CASE p_decision WHEN 'refuser' THEN v_motif END,
         cle_decision = p_cle,
         decide_le = pg_catalog.clock_timestamp()
   WHERE id = v.id;
  PERFORM public.log_sensitive_access('validation_finance_decidee', 'finance_validations', v.id::text,
    pg_catalog.jsonb_build_object('decision', p_decision, 'nature', v.nature));
  RETURN private.fv_json(v.id);
END;
$function$;

-- Le journal d'une demande : sa creation, puis sa decision.
CREATE FUNCTION public.finance_validation_journal(p_demande uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.finance_validations;
BEGIN
  IF NOT private.fac_saisisseur() THEN
    RAISE EXCEPTION 'validations reservees a la direction et a la comptabilite'
      USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v FROM public.finance_validations WHERE id = p_demande;
  IF v.id IS NULL OR NOT coalesce(public.app_role() = 'admin' OR v.demandeur = auth.uid(), false) THEN
    RAISE EXCEPTION 'demande introuvable' USING ERRCODE = 'P0002';
  END IF;
  RETURN pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object(
        'id', v.id::text || ':demande', 'date', v.demande_le, 'action', 'demandee',
        'initiateur', (SELECT pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, ''))
                         FROM public.profiles p WHERE p.id = v.demandeur),
        'montant', private.bf1_montant(v.montant_mineur, v.devise),
        'reference', v.reference))
    || CASE WHEN v.decideur IS NULL THEN '[]'::jsonb ELSE pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object(
        'id', v.id::text || ':decision', 'date', v.decide_le, 'action', v.etat,
        'initiateur', (SELECT pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, ''))
                         FROM public.profiles p WHERE p.id = v.decideur),
        'montant', NULL, 'reference', NULL)) END;
END;
$function$;

DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.fac_crediter_paiement(uuid,uuid,bigint,text,text,uuid,uuid)'::regprocedure,
    'private.fac_devise_profil(uuid,text)'::regprocedure,
    'private.fv_json(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.enregistrer_paiement(uuid,bigint,text,text,uuid)'::regprocedure,
    'public.finance_validations_lister(text,text,uuid)'::regprocedure,
    'public.finance_validation_decider(uuid,text,text,uuid)'::regprocedure,
    'public.finance_validation_journal(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_ADMIN_OR_ACCOUNTANT; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. FAC-D-01.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.enregistrer_paiement(uuid,bigint,text,text,uuid)'::regprocedure,
    'public.finance_validations_lister(text,text,uuid)'::regprocedure,
    'public.finance_validation_decider(uuid,text,text,uuid)'::regprocedure,
    'public.finance_validation_journal(uuid)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'FAC-D-01 : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'public.finance_validations', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.paiements_soumis', 'SELECT') THEN
    RAISE EXCEPTION 'FAC-D-01 : table lisible hors RPC';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND (p.proname LIKE 'fac\_%' OR p.proname = 'fv_json')
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'FAC-D-01 : aide privee executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
