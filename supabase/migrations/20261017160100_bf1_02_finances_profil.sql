-- BF1-02 (17/10/2026) : la finance par profil eleve, en lecture seule
-- (contrats lib/core/capacites/port_mes_finances.dart, FI-BR-17, et
-- lib/core/capacites/port_paiements_foyer.dart, FI-BR-03, FI-BR-05, DB-CPT-03).
--
-- Constat : `wallets` est par foyer et `wallet_entries` ne portait aucun
-- profil. Cette migration ajoute la ventilation : `wallet_entries.beneficiaire_id`
-- (nullable, additive). Une ecriture sans beneficiaire reste une ecriture du
-- foyer : elle compte dans le total du foyer, jamais dans le solde d'un profil.
-- Un remboursement herite du beneficiaire du credit qu'il rembourse ; un payout
-- n'a jamais de beneficiaire eleve.
--
-- Regles de lecture (toutes en SQL, aucune dans Flutter) :
-- * montant signe : credit +|x|, debit -|x|, refund -|x|, payout -|x|,
--   adjustment tel qu'ecrit (signe compris) ;
-- * un credit compte quand le prestataire l'a confirme
--   (`confirme_par_prestataire_le`, X2-17) ; avant, il est « en confirmation »
--   et ne compte pas ;
-- * solde d'un profil = somme signee de ses ecritures comptees, dans la devise
--   du portefeuille du foyer ; une ecriture en autre devise leve 22023 (aucun
--   change invente) ;
-- * etat (regle provisoire BF1, a remplacer quand les politiques de prix et la
--   facturation existeront, lots A et B de 07_MEMOIRE_PEDAGOGIE_FINANCE) :
--   en_confirmation si un credit du profil attend sa confirmation, sinon expire
--   si `profiles.access_until` est passe, sinon manque si le solde est negatif
--   (le manque vaut alors -solde), sinon finance ;
-- * aucune echeance ni facture n'existe cote serveur : periode, prochainDebit,
--   essaisUtilises et finConservation sont toujours nuls, la mensualite vaut 0
--   sans aucune ligne (l'ecran ne l'affiche pas sans ligne) ;
-- * un profil sans portefeuille de foyer, ou sans aucune ecriture ni
--   access_until, n'a pas encore de finance : nul.
--
-- Droits :
-- * `mes_finances_eleve`, `mes_mouvements_eleve` : la personne connectee pour
--   SON SEUL profil eleve adulte (eleve autonome, ou titulaire qui suit des
--   cours, 0052) ; aucun identifiant passe par le client ;
-- * `finances_foyer`, `mouvements_profil_foyer`, `derniers_mouvements_foyer`,
--   `paiements_foyer` : le titulaire du foyer seulement
--   (households.primary_guardian_id = auth.uid(), role guardian), jamais
--   l'enfant ni le second adulte ;
-- * toutes STABLE, SECURITY DEFINER, search_path vide, gardes positives,
--   EXECUTE retire a PUBLIC, anon, service_role, agent_ro, accorde a
--   authenticated. Les aides `private.bf1_*` ne sont executables par aucun
--   role client.
BEGIN;

-- 1. La ventilation par profil.
ALTER TABLE public.wallet_entries
  ADD COLUMN beneficiaire_id uuid REFERENCES public.profiles(id);
CREATE INDEX wallet_entries_beneficiaire_idx
  ON public.wallet_entries (beneficiaire_id, created_at DESC, id DESC)
  WHERE beneficiaire_id IS NOT NULL;
COMMENT ON COLUMN public.wallet_entries.beneficiaire_id IS
  'BF1-02: profil eleve du foyer auquel l''ecriture est imputee; nul = ecriture du foyer. Un refund herite du beneficiaire du credit rembourse.';

CREATE FUNCTION private.bf1_valider_beneficiaire()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_origine uuid;
BEGIN
  IF NEW.reference_type = 'refund' AND NEW.refund_of_entry_id IS NOT NULL THEN
    SELECT o.beneficiaire_id INTO v_origine FROM public.wallet_entries o
     WHERE o.id = NEW.refund_of_entry_id;
    IF NEW.beneficiaire_id IS NULL THEN
      NEW.beneficiaire_id := v_origine;
    ELSIF NEW.beneficiaire_id IS DISTINCT FROM v_origine THEN
      RAISE EXCEPTION 'beneficiaire du remboursement different du credit' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF NEW.beneficiaire_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF NEW.reference_type = 'payout' THEN
    RAISE EXCEPTION 'un payout n''a pas de beneficiaire eleve' USING ERRCODE = '23514';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.wallets w
      JOIN public.profiles p ON p.household_id = w.household_id
      JOIN public.student_profiles sp ON sp.profile_id = p.id
     WHERE w.id = NEW.wallet_id AND p.id = NEW.beneficiaire_id
       AND p.deleted_at IS NULL AND sp.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'beneficiaire hors du foyer du portefeuille' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.bf1_valider_beneficiaire() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.bf1_valider_beneficiaire() FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER wallet_entries_beneficiaire_valide
  BEFORE INSERT ON public.wallet_entries
  FOR EACH ROW EXECUTE FUNCTION private.bf1_valider_beneficiaire();

-- 2. Les aides de lecture (aucun droit client).
CREATE FUNCTION private.bf1_montant_signe(p_type text, p_montant bigint)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE p_type
    WHEN 'credit' THEN abs(p_montant)
    WHEN 'adjustment' THEN p_montant
    ELSE -abs(p_montant) END;
$function$;

CREATE FUNCTION private.bf1_compte(p_type text, p_confirme timestamptz)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT p_type <> 'credit' OR p_confirme IS NOT NULL;
$function$;

-- Le profil eleve personnel de la session, ou nul.
CREATE FUNCTION private.bf1_profil_personnel()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT sp.profile_id FROM public.student_profiles sp
   WHERE coalesce(auth.uid() IS NOT NULL AND public.app_account_valid(), false)
     AND sp.profile_id = auth.uid() AND sp.deleted_at IS NULL
     AND sp.student_type = 'autonomous'
     AND ((public.app_role() = 'student')
          OR (public.app_role() = 'guardian' AND sp.titulaire_profile_id = auth.uid()));
$function$;

-- Vrai quand la session est le titulaire de son foyer.
CREATE FUNCTION private.bf1_est_titulaire()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    auth.uid() IS NOT NULL AND public.app_role() = 'guardian' AND public.app_account_valid()
    AND EXISTS (SELECT 1 FROM public.households h
                 WHERE h.id = public.app_household_id()
                   AND h.primary_guardian_id = auth.uid()
                   AND h.deleted_at IS NULL),
    false);
$function$;

-- Vrai quand p_profil est un profil eleve du foyer de la session.
CREATE FUNCTION private.bf1_profil_du_foyer(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(EXISTS (
    SELECT 1 FROM public.profiles p
      JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
     WHERE p.id = p_profil AND p.deleted_at IS NULL
       AND p.household_id IS NOT NULL AND p.household_id = public.app_household_id()), false);
$function$;

-- La finance d'un profil (FinancesProfil), ou nul.
CREATE FUNCTION private.bf1_finance_profil(p_profil uuid)
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
BEGIN
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = p_profil AND p.deleted_at IS NULL;
  SELECT sp.* INTO v_sp FROM public.student_profiles sp
   WHERE sp.profile_id = p_profil AND sp.deleted_at IS NULL;
  IF v_p.id IS NULL OR v_sp.profile_id IS NULL OR v_p.household_id IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT w.* INTO v_w FROM public.wallets w WHERE w.household_id = v_p.household_id;
  IF v_w.id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT count(*)::integer,
         (count(*) FILTER (WHERE e.currency <> v_w.currency))::integer,
         (count(*) FILTER (WHERE e.reference_type = 'credit' AND e.confirme_par_prestataire_le IS NULL))::integer,
         coalesce(sum(private.bf1_montant_signe(e.reference_type, e.amount_minor))
           FILTER (WHERE private.bf1_compte(e.reference_type, e.confirme_par_prestataire_le)), 0)::bigint
    INTO v_n, v_autres, v_attente, v_solde
    FROM public.wallet_entries e WHERE e.beneficiaire_id = p_profil;
  IF v_autres > 0 THEN
    RAISE EXCEPTION 'finances du profil en plusieurs devises' USING ERRCODE = '22023';
  END IF;
  IF v_n = 0 AND v_p.access_until IS NULL THEN
    RETURN NULL;
  END IF;

  v_etat := CASE
    WHEN v_attente > 0 THEN 'en_confirmation'
    WHEN v_p.access_until IS NOT NULL AND v_p.access_until <= pg_catalog.now() THEN 'expire'
    WHEN v_solde < 0 THEN 'manque'
    ELSE 'finance' END;

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
    'solde', private.bf1_montant(v_solde, v_w.currency),
    'periode', NULL,
    'prochainDebit', NULL,
    'mensualite', private.bf1_montant(0, v_w.currency),
    'lignesMensualite', '[]'::jsonb,
    'essaisUtilises', NULL,
    'manque', CASE WHEN v_etat = 'manque' THEN private.bf1_montant(-v_solde, v_w.currency) END,
    'finConservation', NULL);
END;
$function$;

-- Une ecriture rendue comme mouvement (MouvementProfil).
CREATE FUNCTION private.bf1_mouvement_json(e public.wallet_entries)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', e.id::text,
    'date', coalesce(e.confirme_par_prestataire_le, e.created_at),
    'nature', CASE e.reference_type
      WHEN 'credit' THEN 'recharge'
      WHEN 'debit' THEN 'debit'
      WHEN 'refund' THEN 'remboursement'
      WHEN 'payout' THEN 'payout'
      ELSE CASE WHEN e.amount_minor >= 0 THEN 'avoir' ELSE 'correction' END END,
    'montant', private.bf1_montant(private.bf1_montant_signe(e.reference_type, e.amount_minor), e.currency),
    'statut', CASE WHEN private.bf1_compte(e.reference_type, e.confirme_par_prestataire_le)
                   THEN 'enregistre' ELSE 'en_confirmation' END,
    'periode', NULL,
    'recu', NULL);
$function$;

CREATE FUNCTION private.bf1_mouvements_profil(p_profil uuid, p_limite integer)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(private.bf1_mouvement_json(x) ORDER BY x.created_at DESC, x.id DESC), '[]'::jsonb)
    FROM (SELECT e.* FROM public.wallet_entries e
           WHERE e.beneficiaire_id = p_profil
           ORDER BY e.created_at DESC, e.id DESC
           LIMIT greatest(1, least(coalesce(p_limite, 50), 200))) x;
$function$;

-- 3. Les RPC de lecture.

-- PortMesFinances.finances() : la finance du seul profil personnel, ou nul.
CREATE FUNCTION public.mes_finances_eleve()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profil uuid := private.bf1_profil_personnel();
BEGIN
  IF NOT coalesce(v_profil IS NOT NULL, false) THEN
    RAISE EXCEPTION 'finances reservees a l''eleve adulte sur son profil' USING ERRCODE = '42501';
  END IF;
  RETURN private.bf1_finance_profil(v_profil);
END;
$function$;

-- PortMesFinances.mouvements() : les mouvements du seul profil personnel.
CREATE FUNCTION public.mes_mouvements_eleve(p_limite integer DEFAULT 50)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profil uuid := private.bf1_profil_personnel();
BEGIN
  IF NOT coalesce(v_profil IS NOT NULL, false) THEN
    RAISE EXCEPTION 'finances reservees a l''eleve adulte sur son profil' USING ERRCODE = '42501';
  END IF;
  RETURN private.bf1_mouvements_profil(v_profil, p_limite);
END;
$function$;

-- PortPaiementsFoyer.finances() : la synthese et une finance par profil, ou
-- nul quand le foyer n'a pas encore de portefeuille.
CREATE FUNCTION public.finances_foyer()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_foyer uuid := public.app_household_id();
  v_w public.wallets%ROWTYPE;
  v_zone text;
  v_profils jsonb;
  v_nb integer;
  v_total bigint;
  v_autres integer;
  v_paiements integer;
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'finances du foyer reservees au titulaire' USING ERRCODE = '42501';
  END IF;
  SELECT w.* INTO v_w FROM public.wallets w WHERE w.household_id = v_foyer;
  IF v_w.id IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT coalesce(h.timezone, 'Europe/Paris') INTO v_zone FROM public.households h WHERE h.id = v_foyer;

  SELECT count(*)::integer,
         coalesce(pg_catalog.jsonb_agg(x.f ORDER BY x.created_at, x.id) FILTER (WHERE x.f IS NOT NULL), '[]'::jsonb)
    INTO v_nb, v_profils
    FROM (SELECT p.id, p.created_at, private.bf1_finance_profil(p.id) AS f
            FROM public.profiles p
            JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
           WHERE p.household_id = v_foyer AND p.deleted_at IS NULL) x;

  SELECT (count(*) FILTER (WHERE e.currency <> v_w.currency))::integer,
         coalesce(sum(private.bf1_montant_signe(e.reference_type, e.amount_minor))
           FILTER (WHERE private.bf1_compte(e.reference_type, e.confirme_par_prestataire_le)), 0)::bigint,
         (count(*) FILTER (WHERE e.reference_type = 'credit'
            AND e.confirme_par_prestataire_le IS NOT NULL
            AND pg_catalog.date_trunc('month', e.confirme_par_prestataire_le AT TIME ZONE v_zone)
              = pg_catalog.date_trunc('month', pg_catalog.now() AT TIME ZONE v_zone)))::integer
    INTO v_autres, v_total, v_paiements
    FROM public.wallet_entries e WHERE e.wallet_id = v_w.id;
  IF v_autres > 0 THEN
    RAISE EXCEPTION 'finances du foyer en plusieurs devises' USING ERRCODE = '22023';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'synthese', pg_catalog.jsonb_build_object(
      'totalSoldes', private.bf1_montant(v_total, v_w.currency),
      'aPayerCeMois', private.bf1_montant(coalesce((
        SELECT sum((f.v -> 'manque' ->> 'mineur')::bigint)
          FROM pg_catalog.jsonb_array_elements(v_profils) AS f(v)
         WHERE f.v -> 'manque' IS NOT NULL AND f.v ->> 'manque' IS NOT NULL), 0)::bigint, v_w.currency),
      'profilsFinances', (SELECT count(*) FROM pg_catalog.jsonb_array_elements(v_profils) AS f(v)
                           WHERE f.v ->> 'etat' = 'finance'),
      'profils', v_nb,
      'paiementsDuMois', v_paiements),
    'profils', v_profils);
END;
$function$;

-- PortPaiementsFoyer.mouvements(profilId) : un profil du foyer, titulaire.
CREATE FUNCTION public.mouvements_profil_foyer(p_profil uuid, p_limite integer DEFAULT 50)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'finances du foyer reservees au titulaire' USING ERRCODE = '42501';
  END IF;
  IF NOT private.bf1_profil_du_foyer(p_profil) THEN
    RAISE EXCEPTION 'profil introuvable dans le foyer' USING ERRCODE = 'P0002';
  END IF;
  RETURN private.bf1_mouvements_profil(p_profil, p_limite);
END;
$function$;

-- PortPaiementsFoyer.derniersMouvements() : tous profils du foyer confondus.
CREATE FUNCTION public.derniers_mouvements_foyer(p_limite integer DEFAULT 3)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'finances du foyer reservees au titulaire' USING ERRCODE = '42501';
  END IF;
  RETURN (
    SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'profilId', x.beneficiaire_id, 'prenom', x.first_name,
             'mouvement', private.bf1_mouvement_json(x.e))
             ORDER BY (x.e).created_at DESC, (x.e).id DESC), '[]'::jsonb)
      FROM (SELECT e, e.beneficiaire_id, p.first_name
              FROM public.wallet_entries e
              JOIN public.wallets w ON w.id = e.wallet_id AND w.household_id = public.app_household_id()
              JOIN public.profiles p ON p.id = e.beneficiaire_id
             WHERE e.beneficiaire_id IS NOT NULL
             ORDER BY e.created_at DESC, e.id DESC
             LIMIT greatest(1, least(coalesce(p_limite, 3), 50))) x);
END;
$function$;

-- PortPaiementsFoyer.historique() et detail(id) : les credits du foyer
-- (paiements), le plus recent d'abord ; p_id restreint a un paiement.
CREATE FUNCTION public.paiements_foyer(p_id bigint DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.bf1_est_titulaire() THEN
    RAISE EXCEPTION 'paiements du foyer reserves au titulaire' USING ERRCODE = '42501';
  END IF;
  RETURN (
    SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', x.id::text,
             'montantMineur', abs(x.amount_minor),
             'devise', x.currency,
             'statut', CASE WHEN x.confirme_par_prestataire_le IS NOT NULL
                            THEN 'confirme' ELSE 'en_confirmation' END,
             'date', coalesce(x.confirme_par_prestataire_le, x.created_at),
             'justificatifDisponible', false)
             ORDER BY x.created_at DESC, x.id DESC), '[]'::jsonb)
      FROM (SELECT e.* FROM public.wallet_entries e
              JOIN public.wallets w ON w.id = e.wallet_id AND w.household_id = public.app_household_id()
             WHERE e.reference_type = 'credit' AND (p_id IS NULL OR e.id = p_id)
             ORDER BY e.created_at DESC, e.id DESC
             LIMIT 200) x);
END;
$function$;

-- 4. Proprietaire et droits.
DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.bf1_montant_signe(text,bigint)'::regprocedure,
    'private.bf1_compte(text,timestamptz)'::regprocedure,
    'private.bf1_profil_personnel()'::regprocedure,
    'private.bf1_est_titulaire()'::regprocedure,
    'private.bf1_profil_du_foyer(uuid)'::regprocedure,
    'private.bf1_finance_profil(uuid)'::regprocedure,
    'private.bf1_mouvement_json(public.wallet_entries)'::regprocedure,
    'private.bf1_mouvements_profil(uuid,integer)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_finances_eleve()'::regprocedure,
    'public.mes_mouvements_eleve(integer)'::regprocedure,
    'public.finances_foyer()'::regprocedure,
    'public.mouvements_profil_foyer(uuid,integer)'::regprocedure,
    'public.derniers_mouvements_foyer(integer)'::regprocedure,
    'public.paiements_foyer(bigint)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid,
      'BF1-02: lecture finance par profil (FI-BR-03, FI-BR-05, FI-BR-17). Garde positive: '
      || CASE WHEN (SELECT p.proname FROM pg_catalog.pg_proc p WHERE p.oid = v_oid) LIKE 'mes\_%' THEN 'profil eleve adulte personnel'
              ELSE 'titulaire du foyer (primary_guardian_id)' END
      || ' + compte valide. DEFINER: wallets, profils. date=2026-10-17.');
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_finances_eleve()'::regprocedure,
    'public.mes_mouvements_eleve(integer)'::regprocedure,
    'public.finances_foyer()'::regprocedure,
    'public.mouvements_profil_foyer(uuid,integer)'::regprocedure,
    'public.derniers_mouvements_foyer(integer)'::regprocedure,
    'public.paiements_foyer(bigint)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.provolatile = 's' AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'BF1-02 : DEFINER, volatilite ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'bf1\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'BF1-02 : aide privee executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
