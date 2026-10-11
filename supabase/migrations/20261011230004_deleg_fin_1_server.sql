BEGIN;

CREATE TABLE public.finance_delegation (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  cle_globale text NOT NULL UNIQUE DEFAULT 'global' CHECK (cle_globale='global'),
  etat text NOT NULL DEFAULT 'active' CHECK (etat IN ('active','suspendue')),
  accordee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  expire_le timestamptz NOT NULL DEFAULT (pg_catalog.now()+interval '90 days'),
  version integer NOT NULL DEFAULT 1 CHECK (version>0),
  politique jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(politique)='object'),
  modifiee_par uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  modifiee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT finance_delegation_duree CHECK (expire_le>accordee_le)
);
INSERT INTO public.finance_delegation(cle_globale,etat,politique)
VALUES('global','active',pg_catalog.jsonb_build_object(
  'paiements_standards_autorises',false,
  'plafond_par_transaction',null,
  'plafond_par_lot',null,
  'plafond_par_periode',null,
  'remboursement_standard_autorise',false,
  'alimentation_reserve_autorisee',false,
  'retrait_reserve_interdit',true,
  'premier_paiement_seconde_validation',true,
  'coordonnees_recentes_seconde_validation',true,
  'jours_coordonnees_recentes',30,
  'auto_payout_interdit',true,
  'montant_manuel_interdit',true,
  'politique_tarifaire_interdite',true,
  'duree_jours',90,'delai_sortie_heures',24,
  'plafond_defaut_mineur',0
));

CREATE TABLE public.finance_delegation_exception (
  id uuid PRIMARY KEY,
  delegation_id uuid NOT NULL REFERENCES public.finance_delegation(id) ON DELETE RESTRICT,
  libelle text NOT NULL CHECK (pg_catalog.btrim(libelle)<>''),
  coffres_autorises text[] NOT NULL DEFAULT '{}',
  beneficiaires_exclus uuid[] NOT NULL DEFAULT '{}',
  plafond_par_transaction_minor bigint,
  devise text,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT finance_delegation_exception_cap CHECK (
    (plafond_par_transaction_minor IS NULL AND devise IS NULL)
    OR (plafond_par_transaction_minor>=0 AND devise ~ '^[A-Z]{3}$')
  ),
  CONSTRAINT finance_delegation_exception_coffres CHECK (coffres_autorises <@ ARRAY[
    'fondsClientsEngages','paieADecaisser','chargesEssentielles','taxesObligations',
    'reserveStrategique','enTransit','tresorerieLibre']::text[])
);
CREATE INDEX finance_delegation_exception_delegation_idx
  ON public.finance_delegation_exception(delegation_id,libelle,id);

CREATE TABLE public.finance_delegation_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  delegation_id uuid NOT NULL REFERENCES public.finance_delegation(id) ON DELETE RESTRICT,
  acteur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  cle_idempotence uuid NOT NULL,
  action text NOT NULL CHECK (action IN (
    'politique_enregistree','suspension','reactivation','renouvellement','sortie_annulee'
  )),
  objet_id text,
  raison text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(payload)='object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT finance_delegation_journal_idempotence UNIQUE(acteur_id,cle_idempotence)
);
CREATE INDEX finance_delegation_journal_date_idx
  ON public.finance_delegation_journal(cree_le DESC,id DESC);

ALTER TABLE public.payouts
  ADD COLUMN executable_apres timestamptz NOT NULL DEFAULT (pg_catalog.now()+interval '24 hours'),
  ADD COLUMN annulee_par uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  ADD COLUMN annulee_le timestamptz,
  ADD COLUMN demandee_par uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  ADD COLUMN cle_demande uuid;
ALTER TABLE public.payouts ADD CONSTRAINT payouts_annulation_complete CHECK (
  (annulee_par IS NULL AND annulee_le IS NULL)
  OR (annulee_par IS NOT NULL AND annulee_le IS NOT NULL)
);
CREATE UNIQUE INDEX payouts_demande_idempotence_uidx
  ON public.payouts(demandee_par,cle_demande) WHERE cle_demande IS NOT NULL;
CREATE INDEX payouts_requested_executable_idx
  ON public.payouts(executable_apres,created_at,id) WHERE status='requested';

ALTER TABLE public.finance_delegation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.finance_delegation_exception ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.finance_delegation_journal ENABLE ROW LEVEL SECURITY;
CREATE POLICY finance_delegation_admin_read ON public.finance_delegation
  FOR SELECT TO authenticated USING (
    coalesce(public.app_account_valid() AND public.app_role()='admin',false));
CREATE POLICY finance_delegation_exception_admin_read ON public.finance_delegation_exception
  FOR SELECT TO authenticated USING (
    coalesce(public.app_account_valid() AND public.app_role()='admin',false));
CREATE POLICY finance_delegation_journal_admin_read ON public.finance_delegation_journal
  FOR SELECT TO authenticated USING (
    coalesce(public.app_account_valid() AND public.app_role()='admin',false));
REVOKE ALL ON public.finance_delegation,public.finance_delegation_exception,
  public.finance_delegation_journal FROM PUBLIC,anon,authenticated,service_role,agent_ro;
GRANT SELECT ON public.finance_delegation,public.finance_delegation_exception,
  public.finance_delegation_journal TO authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.finance_delegation,public.finance_delegation_exception,
  public.finance_delegation_journal FROM PUBLIC,anon,authenticated,service_role,agent_ro;

CREATE FUNCTION private.finance_delegation_journal_append_only()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'journal delegation append-only' USING ERRCODE='55000';
END;
$function$;
REVOKE ALL ON FUNCTION private.finance_delegation_journal_append_only()
  FROM PUBLIC,anon,authenticated,service_role,agent_ro;
CREATE TRIGGER finance_delegation_journal_append_only
  BEFORE UPDATE OR DELETE ON public.finance_delegation_journal
  FOR EACH ROW EXECUTE FUNCTION private.finance_delegation_journal_append_only();

CREATE FUNCTION private.finance_delegation_direction()
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
  SELECT coalesce(public.app_role()='admin' AND public.app_account_valid()
    AND (auth.jwt()->>'aal')='aal2',false);
$function$;
REVOKE ALL ON FUNCTION private.finance_delegation_direction()
  FROM PUBLIC,anon,authenticated,service_role,agent_ro;

CREATE FUNCTION private.finance_delegation_payout_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_delegation public.finance_delegation%ROWTYPE;
  v_beneficiaire uuid;
  v_currency text;
  v_general_cap bigint;
  v_batch_cap bigint;
  v_period_cap bigint;
  v_period_total bigint;
  v_exception public.finance_delegation_exception%ROWTYPE;
BEGIN
  IF TG_OP='INSERT' THEN
    IF NEW.status<>'requested' THEN
      RAISE EXCEPTION 'un payout commence en requested' USING ERRCODE='23514';
    END IF;
    IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid()
       AND public.app_role()='accountant',false) THEN
      RAISE EXCEPTION 'demande payout reservee au comptable actif' USING ERRCODE='42501';
    END IF;
    SELECT * INTO v_delegation FROM public.finance_delegation WHERE cle_globale='global';
    IF NOT FOUND OR v_delegation.etat<>'active'
       OR v_delegation.expire_le<=pg_catalog.clock_timestamp() THEN
      RAISE EXCEPTION 'delegation financiere inactive ou expiree' USING ERRCODE='42501';
    END IF;
    SELECT w.currency,pm.profile_id INTO v_currency,v_beneficiaire
      FROM public.wallets w JOIN public.payout_methods pm ON pm.id=NEW.payout_method_id
     WHERE w.id=NEW.wallet_id AND pm.deleted_at IS NULL;
    IF NOT FOUND OR NEW.amount_minor<=0 THEN
      RAISE EXCEPTION 'payout invalide' USING ERRCODE='22023';
    END IF;
    v_general_cap:=coalesce((v_delegation.politique->'plafond_par_transaction'->>v_currency)::bigint,0);
    v_batch_cap:=coalesce((v_delegation.politique->'plafond_par_lot'->>'mineur')::bigint,0);
    v_period_cap:=coalesce((v_delegation.politique->'plafond_par_periode'->>'mineur')::bigint,0);
    IF NOT coalesce((v_delegation.politique->>'paiements_standards_autorises')::boolean,false)
       OR NEW.amount_minor>v_general_cap OR NEW.amount_minor>v_batch_cap
       OR v_period_cap=0 THEN
      RAISE EXCEPTION 'payout hors delegation ou plafond nul' USING ERRCODE='42501';
    END IF;
    PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
      'delegation-beneficiaire:'||v_beneficiaire::text||':'||v_currency||':'||
      pg_catalog.to_char(pg_catalog.clock_timestamp() AT TIME ZONE 'UTC','YYYY-MM'),0));
    SELECT coalesce(sum(p.amount_minor),0) INTO v_period_total
      FROM public.payouts p JOIN public.payout_methods pm ON pm.id=p.payout_method_id
      JOIN public.wallets w ON w.id=p.wallet_id
     WHERE pm.profile_id=v_beneficiaire AND w.currency=v_currency
       AND p.status IN ('requested','paid')
       AND pg_catalog.date_trunc('month',p.created_at AT TIME ZONE 'UTC')=
           pg_catalog.date_trunc('month',pg_catalog.clock_timestamp() AT TIME ZONE 'UTC');
    IF v_period_total+NEW.amount_minor>v_period_cap THEN
      RAISE EXCEPTION 'plafond cumule de periode depasse' USING ERRCODE='42501';
    END IF;
    SELECT * INTO v_exception FROM public.finance_delegation_exception e
     WHERE e.delegation_id=v_delegation.id AND v_beneficiaire=ANY(e.beneficiaires_exclus)
     LIMIT 1;
    IF FOUND THEN RAISE EXCEPTION 'beneficiaire exclu de la delegation' USING ERRCODE='42501'; END IF;
    SELECT * INTO v_exception FROM public.finance_delegation_exception e
     WHERE e.delegation_id=v_delegation.id AND e.devise=v_currency
       AND e.plafond_par_transaction_minor IS NOT NULL
     ORDER BY e.plafond_par_transaction_minor,e.id LIMIT 1;
    IF FOUND AND NEW.amount_minor>v_exception.plafond_par_transaction_minor THEN
      RAISE EXCEPTION 'payout au-dessus du plafond specifique' USING ERRCODE='42501';
    END IF;
    NEW.demandee_par:=auth.uid();
    NEW.executable_apres:=pg_catalog.clock_timestamp()+interval '24 hours';
    NEW.annulee_par:=NULL; NEW.annulee_le:=NULL;
    RETURN NEW;
  END IF;

  IF OLD.status IN ('cancelled','paid','failed') AND NEW IS DISTINCT FROM OLD THEN
    RAISE EXCEPTION 'payout terminal et immuable' USING ERRCODE='55000';
  END IF;
  IF (NEW.wallet_id,NEW.payout_method_id,NEW.amount_minor,NEW.created_at,
      NEW.executable_apres,NEW.demandee_par,NEW.cle_demande)
     IS DISTINCT FROM
     (OLD.wallet_id,OLD.payout_method_id,OLD.amount_minor,OLD.created_at,
      OLD.executable_apres,OLD.demandee_par,OLD.cle_demande)
     OR (NEW.annulee_par,NEW.annulee_le) IS DISTINCT FROM (OLD.annulee_par,OLD.annulee_le) THEN
    RAISE EXCEPTION 'champs payout immuables' USING ERRCODE='55000';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF OLD.status<>'requested' OR NEW.status NOT IN ('cancelled','paid','failed') THEN
      RAISE EXCEPTION 'transition payout invalide' USING ERRCODE='55000';
    END IF;
    IF NEW.status='cancelled' THEN
      IF NOT private.finance_delegation_direction() THEN
        RAISE EXCEPTION 'annulation reservee a la direction MFA' USING ERRCODE='42501';
      END IF;
      NEW.annulee_par:=auth.uid();
      NEW.annulee_le:=pg_catalog.clock_timestamp();
    ELSIF NEW.status='paid' THEN
      SELECT * INTO v_delegation FROM public.finance_delegation WHERE cle_globale='global';
      IF NEW.executable_apres>pg_catalog.clock_timestamp() THEN
        RAISE EXCEPTION 'delai de securite payout non ecoule' USING ERRCODE='55000';
      END IF;
      IF NOT FOUND OR v_delegation.etat<>'active'
         OR v_delegation.expire_le<=pg_catalog.clock_timestamp() THEN
        RAISE EXCEPTION 'delegation suspendue ou expiree' USING ERRCODE='42501';
      END IF;
      SELECT w.currency,pm.profile_id INTO v_currency,v_beneficiaire
        FROM public.wallets w JOIN public.payout_methods pm ON pm.id=NEW.payout_method_id
       WHERE w.id=NEW.wallet_id;
      v_general_cap:=coalesce((v_delegation.politique->'plafond_par_transaction'->>v_currency)::bigint,0);
      IF NOT coalesce((v_delegation.politique->>'paiements_standards_autorises')::boolean,false)
         OR NEW.amount_minor>v_general_cap THEN
        RAISE EXCEPTION 'delegation ou plafond modifie depuis la demande' USING ERRCODE='42501';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.finance_delegation_payout_guard() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.finance_delegation_payout_guard()
  FROM PUBLIC,anon,authenticated,service_role,agent_ro;
COMMENT ON FUNCTION private.finance_delegation_payout_guard() IS
  'F86 candidate allowlist: signature=private.finance_delegation_payout_guard(); md5_functiondef=A_CALCULER; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';
CREATE TRIGGER finance_delegation_payout_guard
  BEFORE INSERT OR UPDATE ON public.payouts
  FOR EACH ROW EXECUTE FUNCTION private.finance_delegation_payout_guard();

CREATE FUNCTION private.finance_delegation_exige_direction()
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  IF NOT private.finance_delegation_direction() THEN
    RAISE EXCEPTION 'direction active MFA requise' USING ERRCODE='42501';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION private.finance_delegation_exige_direction()
  FROM PUBLIC,anon,authenticated,service_role,agent_ro;

CREATE FUNCTION public.lire_delegation_finance()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v public.finance_delegation%ROWTYPE; v_exceptions jsonb; v_policy jsonb; v_currency text; v_cap bigint;
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  SELECT * INTO v FROM public.finance_delegation WHERE cle_globale='global';
  v_policy:=v.politique;
  IF pg_catalog.jsonb_typeof(v_policy->'plafond_par_transaction')='object'
     AND (SELECT count(*) FROM pg_catalog.jsonb_object_keys(v_policy->'plafond_par_transaction'))>0 THEN
    SELECT key,value::text::bigint INTO v_currency,v_cap
      FROM pg_catalog.jsonb_each(v_policy->'plafond_par_transaction') LIMIT 1;
    v_policy:=pg_catalog.jsonb_set(v_policy,'{plafond_par_transaction}',
      pg_catalog.jsonb_build_object('mineur',v_cap,'devise',v_currency),true);
  ELSE
    v_policy:=pg_catalog.jsonb_set(v_policy,'{plafond_par_transaction}','null'::jsonb,true);
  END IF;
  IF pg_catalog.jsonb_typeof(v_policy->'plafond_par_lot')='null'
     OR v_policy->'plafond_par_lot' IS NULL THEN
    v_policy:=pg_catalog.jsonb_set(v_policy,'{plafond_par_lot}','null'::jsonb,true);
  END IF;
  IF pg_catalog.jsonb_typeof(v_policy->'plafond_par_periode')='null'
     OR v_policy->'plafond_par_periode' IS NULL THEN
    v_policy:=pg_catalog.jsonb_set(v_policy,'{plafond_par_periode}','null'::jsonb,true);
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id',e.id,'libelle',e.libelle,'coffres_autorises',e.coffres_autorises,
    'beneficiaires_exclus',coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id',p.id,'nom',pg_catalog.concat_ws(' ',p.first_name,p.last_name)) ORDER BY p.last_name,p.first_name)
      FROM public.profiles p WHERE p.id=ANY(e.beneficiaires_exclus)),'[]'::jsonb),
    'plafond_par_transaction',CASE WHEN e.plafond_par_transaction_minor IS NULL THEN NULL
      ELSE pg_catalog.jsonb_build_object('mineur',e.plafond_par_transaction_minor,'devise',e.devise) END
  ) ORDER BY e.libelle,e.id),'[]'::jsonb) INTO v_exceptions
  FROM public.finance_delegation_exception e WHERE e.delegation_id=v.id;
  RETURN v_policy||pg_catalog.jsonb_build_object(
    'version',v.version::text,'etat',CASE WHEN v.expire_le<=pg_catalog.clock_timestamp()
      THEN 'expiree' ELSE v.etat END,
    'suspendue_le',(SELECT j.cree_le FROM public.finance_delegation_journal j
      WHERE j.delegation_id=v.id AND j.action='suspension' ORDER BY j.id DESC LIMIT 1),
    'expire_le',v.expire_le,'duree_jours',90,'delai_sortie_heures',24,
    'date_effet',v.accordee_le,'auteur',(SELECT pg_catalog.concat_ws(' ',p.first_name,p.last_name)
      FROM public.profiles p WHERE p.id=v.modifiee_par),'exceptions',v_exceptions);
END;
$function$;
ALTER FUNCTION public.lire_delegation_finance() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lire_delegation_finance() FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_delegation_finance() TO authenticated;
COMMENT ON FUNCTION public.lire_delegation_finance() IS
  'F86 candidate allowlist: signature=public.lire_delegation_finance(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.enregistrer_delegation_finance(p_brouillon jsonb,p_cle uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v public.finance_delegation%ROWTYPE; v_exception jsonb; v_id uuid; v_cap jsonb;
  v_general jsonb; v_exceptions jsonb; v_payload jsonb; v_actor uuid:=auth.uid();
  v_currency text; v_amount bigint; v_count integer;
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  IF p_cle IS NULL OR pg_catalog.jsonb_typeof(p_brouillon)<>'object' THEN
    RAISE EXCEPTION 'politique de delegation invalide' USING ERRCODE='22023';
  END IF;
  IF NOT (p_brouillon ?& ARRAY['paiements_standards_autorises','remboursement_standard_autorise',
    'alimentation_reserve_autorisee','retrait_reserve_interdit','premier_paiement_seconde_validation',
    'coordonnees_recentes_seconde_validation','plafond_par_transaction','plafond_par_lot',
    'plafond_par_periode','jours_coordonnees_recentes','exceptions']) THEN
    RAISE EXCEPTION 'champs de politique manquants' USING ERRCODE='22023';
  END IF;
  IF pg_catalog.jsonb_typeof(p_brouillon->'paiements_standards_autorises')<>'boolean'
     OR pg_catalog.jsonb_typeof(p_brouillon->'remboursement_standard_autorise')<>'boolean'
     OR pg_catalog.jsonb_typeof(p_brouillon->'alimentation_reserve_autorisee')<>'boolean'
     OR pg_catalog.jsonb_typeof(p_brouillon->'retrait_reserve_interdit')<>'boolean'
     OR pg_catalog.jsonb_typeof(p_brouillon->'premier_paiement_seconde_validation')<>'boolean'
     OR pg_catalog.jsonb_typeof(p_brouillon->'coordonnees_recentes_seconde_validation')<>'boolean'
     OR pg_catalog.jsonb_typeof(p_brouillon->'exceptions')<>'array' THEN
    RAISE EXCEPTION 'types de politique invalides' USING ERRCODE='22023';
  END IF;
  IF coalesce((p_brouillon->>'retrait_reserve_interdit')::boolean,false)=false THEN
    RAISE EXCEPTION 'le retrait de reserve est interdit' USING ERRCODE='42501';
  END IF;
  v_general:=coalesce(p_brouillon->'plafond_par_transaction','null'::jsonb);
  IF v_general<>'null'::jsonb THEN
    IF pg_catalog.jsonb_typeof(v_general)<>'object' THEN
      RAISE EXCEPTION 'plafond general invalide' USING ERRCODE='22023';
    END IF;
    v_currency:=v_general->>'devise'; v_amount:=(v_general->>'mineur')::bigint;
    IF v_currency !~ '^[A-Z]{3}$' OR v_amount<0 THEN
      RAISE EXCEPTION 'plafond general invalide' USING ERRCODE='22023';
    END IF;
  END IF;
  v_exceptions:=p_brouillon->'exceptions';
  IF pg_catalog.jsonb_array_length(v_exceptions)>100 THEN
    RAISE EXCEPTION 'trop d exceptions de delegation' USING ERRCODE='22023';
  END IF;
  SELECT * INTO v FROM public.finance_delegation WHERE cle_globale='global' FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.finance_delegation_journal j
      WHERE j.acteur_id=v_actor AND j.cle_idempotence=p_cle) THEN
    IF EXISTS (SELECT 1 FROM public.finance_delegation_journal j
      WHERE j.acteur_id=v_actor AND j.cle_idempotence=p_cle
        AND j.action='politique_enregistree' AND j.payload->'brouillon'=p_brouillon) THEN
      RETURN public.lire_delegation_finance();
    END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee' USING ERRCODE='22023';
  END IF;
  v_payload:=pg_catalog.jsonb_build_object(
    'paiements_standards_autorises',p_brouillon->'paiements_standards_autorises',
    'plafond_par_transaction',CASE WHEN v_general='null'::jsonb THEN '{}'::jsonb
      ELSE pg_catalog.jsonb_build_object(v_general->>'devise',(v_general->>'mineur')::bigint) END,
    'plafond_par_lot',p_brouillon->'plafond_par_lot',
    'plafond_par_periode',p_brouillon->'plafond_par_periode',
    'remboursement_standard_autorise',p_brouillon->'remboursement_standard_autorise',
    'alimentation_reserve_autorisee',p_brouillon->'alimentation_reserve_autorisee',
    'retrait_reserve_interdit',true,
    'premier_paiement_seconde_validation',p_brouillon->'premier_paiement_seconde_validation',
    'coordonnees_recentes_seconde_validation',p_brouillon->'coordonnees_recentes_seconde_validation',
    'jours_coordonnees_recentes',p_brouillon->'jours_coordonnees_recentes',
    'auto_payout_interdit',true,'montant_manuel_interdit',true,'politique_tarifaire_interdite',true,
    'duree_jours',90,'delai_sortie_heures',24,'plafond_defaut_mineur',0);
  UPDATE public.finance_delegation SET politique=v_payload,version=version+1,
    modifiee_par=v_actor,modifiee_le=pg_catalog.clock_timestamp()
    WHERE id=v.id RETURNING * INTO v;
  DELETE FROM public.finance_delegation_exception WHERE delegation_id=v.id;
  FOR v_exception IN SELECT value FROM pg_catalog.jsonb_array_elements(v_exceptions) LOOP
    IF pg_catalog.jsonb_typeof(v_exception)<>'object'
       OR NOT (v_exception ?& ARRAY['id','libelle','coffres_autorises','beneficiaires_exclus']) THEN
      RAISE EXCEPTION 'exception invalide' USING ERRCODE='22023';
    END IF;
    v_id:=(v_exception->>'id')::uuid;
    IF EXISTS(SELECT 1 FROM pg_catalog.jsonb_array_elements_text(v_exception->'coffres_autorises') AS c(value)
      WHERE c.value NOT IN ('fondsClientsEngages','paieADecaisser','chargesEssentielles','taxesObligations',
        'reserveStrategique','enTransit','tresorerieLibre'))
       OR EXISTS(SELECT 1 FROM pg_catalog.jsonb_array_elements(v_exception->'beneficiaires_exclus') AS b(value)
          WHERE NOT EXISTS(SELECT 1 FROM public.profiles p WHERE p.id=(b.value->>'id')::uuid
            AND p.deleted_at IS NULL)) THEN
      RAISE EXCEPTION 'coffre ou beneficiaire invalide' USING ERRCODE='22023';
    END IF;
    v_cap:=coalesce(v_exception->'plafond_par_transaction','null'::jsonb);
    IF v_cap<>'null'::jsonb THEN
      IF pg_catalog.jsonb_typeof(v_cap)<>'object' OR v_cap->>'devise' IS DISTINCT FROM v_general->>'devise'
         OR (v_cap->>'mineur')::bigint<0
         OR v_general='null'::jsonb OR (v_cap->>'mineur')::bigint>(v_general->>'mineur')::bigint THEN
        RAISE EXCEPTION 'plafond exception au-dessus du plafond general' USING ERRCODE='22023';
      END IF;
    END IF;
    INSERT INTO public.finance_delegation_exception(id,delegation_id,libelle,
      coffres_autorises,beneficiaires_exclus,plafond_par_transaction_minor,devise)
    VALUES(v_id,v.id,v_exception->>'libelle',
      ARRAY(SELECT jsonb_array_elements_text(v_exception->'coffres_autorises')),
      ARRAY(SELECT (x.value->>'id')::uuid FROM jsonb_array_elements(v_exception->'beneficiaires_exclus') x),
      CASE WHEN v_cap='null'::jsonb THEN NULL ELSE (v_cap->>'mineur')::bigint END,
      CASE WHEN v_cap='null'::jsonb THEN NULL ELSE v_cap->>'devise' END);
  END LOOP;
  INSERT INTO public.finance_delegation_journal(delegation_id,acteur_id,cle_idempotence,
    action,payload) VALUES(v.id,v_actor,p_cle,'politique_enregistree',
      pg_catalog.jsonb_build_object('brouillon',p_brouillon,'version',v.version));
  RETURN public.lire_delegation_finance();
END;
$function$;
ALTER FUNCTION public.enregistrer_delegation_finance(jsonb,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.enregistrer_delegation_finance(jsonb,uuid)
  FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.enregistrer_delegation_finance(jsonb,uuid) TO authenticated;
COMMENT ON FUNCTION public.enregistrer_delegation_finance(jsonb,uuid) IS
  'F86 candidate allowlist: signature=public.enregistrer_delegation_finance(jsonb,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.journal_delegation_finance()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  RETURN coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id',j.id,'date',j.cree_le,
    'initiateur',coalesce(pg_catalog.concat_ws(' ',p.first_name,p.last_name),'la direction'),
    'objet',CASE j.action WHEN 'politique_enregistree' THEN 'Politique de délégation'
      WHEN 'suspension' THEN 'Suspension de toutes les délégations'
      WHEN 'reactivation' THEN 'Réactivation de la délégation'
      WHEN 'renouvellement' THEN 'Renouvellement de la délégation'
      ELSE 'Annulation d’une sortie en attente' END,
    'ancien_etat',j.payload->>'ancien_etat','nouvel_etat',j.payload->>'nouvel_etat',
    'source','finance_delegation','reference',j.objet_id,'preuve',j.raison,
    'montant',j.payload->'montant') ORDER BY j.cree_le DESC,j.id DESC)
    FROM public.finance_delegation_journal j
    LEFT JOIN public.profiles p ON p.id=j.acteur_id),'[]'::jsonb);
END;
$function$;
ALTER FUNCTION public.journal_delegation_finance() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.journal_delegation_finance() FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.journal_delegation_finance() TO authenticated;
COMMENT ON FUNCTION public.journal_delegation_finance() IS
  'F86 candidate allowlist: signature=public.journal_delegation_finance(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.suspendre_toutes_delegations_finance(p_cle uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v public.finance_delegation%ROWTYPE; v_actor uuid:=auth.uid(); v_cancelled integer;
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  IF p_cle IS NULL THEN RAISE EXCEPTION 'cle requise' USING ERRCODE='22023'; END IF;
  SELECT * INTO v FROM public.finance_delegation WHERE cle_globale='global' FOR UPDATE;
  IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
    AND j.cle_idempotence=p_cle) THEN
    IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
      AND j.cle_idempotence=p_cle AND j.action='suspension') THEN RETURN public.lire_delegation_finance(); END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee' USING ERRCODE='22023';
  END IF;
  UPDATE public.finance_delegation SET etat='suspendue',modifiee_par=v_actor,
    modifiee_le=pg_catalog.clock_timestamp() WHERE id=v.id;
  UPDATE public.payouts SET status='cancelled' WHERE status='requested';
  GET DIAGNOSTICS v_cancelled=ROW_COUNT;
  INSERT INTO public.finance_delegation_journal(delegation_id,acteur_id,cle_idempotence,
    action,payload) VALUES(v.id,v_actor,p_cle,'suspension',pg_catalog.jsonb_build_object(
      'ancien_etat',CASE WHEN v.expire_le<=pg_catalog.clock_timestamp() THEN 'expiree' ELSE v.etat END,
      'nouvel_etat','suspendue','sorties_annulees',v_cancelled));
  RETURN public.lire_delegation_finance();
END;
$function$;
ALTER FUNCTION public.suspendre_toutes_delegations_finance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.suspendre_toutes_delegations_finance(uuid) FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.suspendre_toutes_delegations_finance(uuid) TO authenticated;
COMMENT ON FUNCTION public.suspendre_toutes_delegations_finance(uuid) IS
  'F86 candidate allowlist: signature=public.suspendre_toutes_delegations_finance(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.reactiver_delegation_finance(p_cle uuid,p_raison text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v public.finance_delegation%ROWTYPE; v_actor uuid:=auth.uid(); v_reason text:=pg_catalog.btrim(p_raison);
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  IF p_cle IS NULL OR v_reason IS NULL OR pg_catalog.length(v_reason) NOT BETWEEN 3 AND 500 THEN
    RAISE EXCEPTION 'cle et raison de 3 a 500 caracteres requises' USING ERRCODE='22023';
  END IF;
  SELECT * INTO v FROM public.finance_delegation WHERE cle_globale='global' FOR UPDATE;
  IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
    AND j.cle_idempotence=p_cle) THEN
    IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
      AND j.cle_idempotence=p_cle AND j.action='reactivation' AND j.raison=v_reason)
      THEN RETURN public.lire_delegation_finance(); END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee' USING ERRCODE='22023';
  END IF;
  IF v.expire_le<=pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'delegation expiree: seul le renouvellement repart' USING ERRCODE='55000';
  END IF;
  IF v.etat<>'suspendue' THEN RAISE EXCEPTION 'delegation non suspendue' USING ERRCODE='55000'; END IF;
  UPDATE public.finance_delegation SET etat='active',modifiee_par=v_actor,
    modifiee_le=pg_catalog.clock_timestamp() WHERE id=v.id;
  INSERT INTO public.finance_delegation_journal(delegation_id,acteur_id,cle_idempotence,
    action,raison,payload) VALUES(v.id,v_actor,p_cle,'reactivation',v_reason,
      pg_catalog.jsonb_build_object('ancien_etat','suspendue','nouvel_etat','active'));
  RETURN public.lire_delegation_finance();
END;
$function$;
ALTER FUNCTION public.reactiver_delegation_finance(uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reactiver_delegation_finance(uuid,text) FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.reactiver_delegation_finance(uuid,text) TO authenticated;
COMMENT ON FUNCTION public.reactiver_delegation_finance(uuid,text) IS
  'F86 candidate allowlist: signature=public.reactiver_delegation_finance(uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.renouveler_delegation_finance(p_cle uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v public.finance_delegation%ROWTYPE; v_actor uuid:=auth.uid();
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  IF p_cle IS NULL THEN RAISE EXCEPTION 'cle requise' USING ERRCODE='22023'; END IF;
  SELECT * INTO v FROM public.finance_delegation WHERE cle_globale='global' FOR UPDATE;
  IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
    AND j.cle_idempotence=p_cle) THEN
    IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
      AND j.cle_idempotence=p_cle AND j.action='renouvellement') THEN RETURN public.lire_delegation_finance(); END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee' USING ERRCODE='22023';
  END IF;
  UPDATE public.finance_delegation SET etat='active',accordee_le=pg_catalog.clock_timestamp(),
    expire_le=pg_catalog.clock_timestamp()+interval '90 days',version=version+1,
    modifiee_par=v_actor,modifiee_le=pg_catalog.clock_timestamp() WHERE id=v.id;
  INSERT INTO public.finance_delegation_journal(delegation_id,acteur_id,cle_idempotence,
    action,payload) VALUES(v.id,v_actor,p_cle,'renouvellement',pg_catalog.jsonb_build_object(
      'ancien_etat',CASE WHEN v.expire_le<=pg_catalog.clock_timestamp() THEN 'expiree' ELSE v.etat END,
      'nouvel_etat','active','ancienne_expiration',v.expire_le));
  RETURN public.lire_delegation_finance();
END;
$function$;
ALTER FUNCTION public.renouveler_delegation_finance(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.renouveler_delegation_finance(uuid) FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.renouveler_delegation_finance(uuid) TO authenticated;
COMMENT ON FUNCTION public.renouveler_delegation_finance(uuid) IS
  'F86 candidate allowlist: signature=public.renouveler_delegation_finance(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.sorties_en_attente_delegation_finance()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  RETURN coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id',p.id,'beneficiaire',pg_catalog.concat_ws(' ',pr.first_name,pr.last_name),
    'objet','Sortie '||p.id::text,
    'montant',pg_catalog.jsonb_build_object('mineur',p.amount_minor,'devise',w.currency),
    'demandee_le',p.created_at,'liberable_le',p.executable_apres)
    ORDER BY p.executable_apres,p.created_at,p.id)
    FROM public.payouts p JOIN public.wallets w ON w.id=p.wallet_id
    JOIN public.payout_methods pm ON pm.id=p.payout_method_id
    JOIN public.profiles pr ON pr.id=pm.profile_id WHERE p.status='requested'),'[]'::jsonb);
END;
$function$;
ALTER FUNCTION public.sorties_en_attente_delegation_finance() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.sorties_en_attente_delegation_finance() FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.sorties_en_attente_delegation_finance() TO authenticated;
COMMENT ON FUNCTION public.sorties_en_attente_delegation_finance() IS
  'F86 candidate allowlist: signature=public.sorties_en_attente_delegation_finance(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.annuler_sortie_delegation_finance(p_sortie_id uuid,p_cle uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v public.payouts%ROWTYPE; v_delegation uuid; v_actor uuid:=auth.uid(); v_currency text;
BEGIN
  PERFORM private.finance_delegation_exige_direction();
  IF p_sortie_id IS NULL OR p_cle IS NULL THEN RAISE EXCEPTION 'sortie et cle requises' USING ERRCODE='22023'; END IF;
  IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
    AND j.cle_idempotence=p_cle) THEN
    IF EXISTS(SELECT 1 FROM public.finance_delegation_journal j WHERE j.acteur_id=v_actor
      AND j.cle_idempotence=p_cle AND j.action='sortie_annulee' AND j.objet_id=p_sortie_id::text)
      THEN RETURN; END IF;
    RAISE EXCEPTION 'cle idempotence deja utilisee' USING ERRCODE='22023';
  END IF;
  SELECT p.* INTO v FROM public.payouts p WHERE p.id=p_sortie_id FOR UPDATE;
  IF NOT FOUND OR v.status<>'requested' THEN RAISE EXCEPTION 'sortie non annulable' USING ERRCODE='55000'; END IF;
  SELECT w.currency INTO v_currency FROM public.wallets w WHERE w.id=v.wallet_id;
  SELECT id INTO v_delegation FROM public.finance_delegation WHERE cle_globale='global';
  UPDATE public.payouts SET status='cancelled' WHERE id=p_sortie_id;
  INSERT INTO public.finance_delegation_journal(delegation_id,acteur_id,cle_idempotence,
    action,objet_id,payload) VALUES(v_delegation,v_actor,p_cle,'sortie_annulee',p_sortie_id::text,
      pg_catalog.jsonb_build_object('ancien_etat','requested','nouvel_etat','cancelled',
        'montant',pg_catalog.jsonb_build_object('mineur',v.amount_minor,'devise',v_currency),
        'payout_id',v.id));
END;
$function$;
ALTER FUNCTION public.annuler_sortie_delegation_finance(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.annuler_sortie_delegation_finance(uuid,uuid) FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.annuler_sortie_delegation_finance(uuid,uuid) TO authenticated;
COMMENT ON FUNCTION public.annuler_sortie_delegation_finance(uuid,uuid) IS
  'F86 candidate allowlist: signature=public.annuler_sortie_delegation_finance(uuid,uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

COMMIT;
