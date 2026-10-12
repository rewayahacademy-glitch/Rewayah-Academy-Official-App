-- X2-17 : alimentation transactionnelle et reprise des événements financiers.
BEGIN;

ALTER TABLE public.wallet_entries
  DROP CONSTRAINT wallet_entries_reference_type_check;
ALTER TABLE public.wallet_entries
  ADD CONSTRAINT wallet_entries_reference_type_check
  CHECK (reference_type IN ('credit','debit','adjustment','payout','refund'));
ALTER TABLE public.wallet_entries
  ADD COLUMN refund_of_entry_id bigint REFERENCES public.wallet_entries(id);
ALTER TABLE public.wallet_entries
  ADD CONSTRAINT wallet_entries_refund_link_check CHECK (
    (reference_type = 'refund' AND refund_of_entry_id IS NOT NULL)
    OR (reference_type <> 'refund' AND refund_of_entry_id IS NULL)
  );
CREATE FUNCTION public.x217_guard_confirmation_source()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  IF TG_OP='INSERT' THEN
    IF NEW.confirme_par_prestataire_le IS NOT NULL
       AND current_user NOT IN ('postgres','service_role') THEN
      RAISE EXCEPTION 'confirmation_prestataire_reservee_au_serveur'
        USING ERRCODE='42501';
    END IF;
    RETURN NEW;
  END IF;
  IF OLD.confirme_par_prestataire_le IS DISTINCT FROM NEW.confirme_par_prestataire_le
     AND (OLD.confirme_par_prestataire_le IS NOT NULL
       OR current_user NOT IN ('postgres','service_role')) THEN
    RAISE EXCEPTION 'confirmation_prestataire_reservee_au_serveur'
      USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER wallet_entries_confirmation_source_guard
  BEFORE INSERT OR UPDATE ON public.wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.x217_guard_confirmation_source();
REVOKE ALL ON FUNCTION public.x217_guard_confirmation_source() FROM PUBLIC,anon,authenticated,agent_ro,service_role;
ALTER TABLE public.sessions
  ADD COLUMN finance_started_at timestamptz,
  ADD COLUMN finance_ended_at timestamptz;

CREATE TABLE public.tresorerie_a_reprendre (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  source_type text NOT NULL CHECK (source_type IN ('encaissement','remboursement','prestation','payout')),
  source_id text NOT NULL,
  raison text NOT NULL CHECK (raison IN (
    'taux_change_absent','regle_remuneration_absente','duree_indeterminee','politique_allocation_absente',
    'montant_financier_invalide',
    'debit_prestation_absent','devise_prestation_multiple','montant_prestation_insuffisant'
  )),
  decision_debut timestamptz,
  decision_fin timestamptz,
  decide_par uuid REFERENCES public.profiles(id),
  decide_le timestamptz,
  cree_le timestamptz NOT NULL DEFAULT now(),
  traite_le timestamptz,
  UNIQUE (source_type,source_id,raison),
  CHECK ((decision_debut IS NULL AND decision_fin IS NULL AND decide_par IS NULL AND decide_le IS NULL)
      OR (decision_debut IS NOT NULL AND decision_fin > decision_debut AND decide_par IS NOT NULL AND decide_le IS NOT NULL))
);
ALTER TABLE public.tresorerie_a_reprendre ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.tresorerie_a_reprendre FROM PUBLIC,anon,authenticated,agent_ro,service_role;
GRANT SELECT ON public.tresorerie_a_reprendre TO authenticated;
CREATE POLICY tresorerie_reprise_finance_read ON public.tresorerie_a_reprendre
  FOR SELECT TO authenticated USING (
    coalesce(public.app_account_valid() AND public.app_role() IN ('admin','accountant'),false)
  );

CREATE TABLE public.politique_allocation_coffres (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  date_effet date NOT NULL UNIQUE,
  taux_taxes_permille integer NOT NULL CHECK (taux_taxes_permille BETWEEN 0 AND 1000),
  taux_charges_permille integer NOT NULL CHECK (taux_charges_permille BETWEEN 0 AND 1000),
  taux_reserve_permille integer NOT NULL CHECK (taux_reserve_permille BETWEEN 0 AND 1000),
  cree_par uuid NOT NULL REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT now(),
  CHECK (taux_taxes_permille+taux_charges_permille+taux_reserve_permille<=1000)
);
ALTER TABLE public.politique_allocation_coffres ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.politique_allocation_coffres FROM PUBLIC,anon,authenticated,agent_ro,service_role;
GRANT SELECT,INSERT ON public.politique_allocation_coffres TO authenticated;
GRANT USAGE,SELECT ON SEQUENCE public.politique_allocation_coffres_id_seq TO authenticated;
CREATE POLICY politique_coffres_admin_read ON public.politique_allocation_coffres
  FOR SELECT TO authenticated USING (
    coalesce(public.app_account_valid() AND public.app_role()='admin',false)
  );
CREATE POLICY politique_coffres_admin_aal2_insert ON public.politique_allocation_coffres
  FOR INSERT TO authenticated WITH CHECK (
    coalesce(public.app_account_valid() AND public.app_role()='admin'
      AND auth.jwt()->>'aal'='aal2' AND cree_par=auth.uid(),false)
  );
CREATE FUNCTION public.x217_valider_politique_coffres()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  IF TG_OP<>'INSERT' OR NOT coalesce(public.app_account_valid()
       AND public.app_role()='admin' AND auth.jwt()->>'aal'='aal2'
       AND NEW.cree_par=auth.uid(),false) THEN
    RAISE EXCEPTION 'politique_allocation_modification_refusee' USING ERRCODE='42501';
  END IF;
  PERFORM public.log_sensitive_access('politique_allocation_coffres_creee',
    'politique_allocation_coffres',NEW.id::text,
    jsonb_build_object('date_effet',NEW.date_effet,
      'taux_taxes_permille',NEW.taux_taxes_permille,
      'taux_charges_permille',NEW.taux_charges_permille,
      'taux_reserve_permille',NEW.taux_reserve_permille));
  RETURN NEW;
END;
$function$;
CREATE TRIGGER politique_coffres_append_only BEFORE UPDATE OR DELETE
  ON public.politique_allocation_coffres FOR EACH ROW
  EXECUTE FUNCTION public.x217_valider_politique_coffres();
CREATE TRIGGER politique_coffres_audit BEFORE INSERT
  ON public.politique_allocation_coffres FOR EACH ROW
  EXECUTE FUNCTION public.x217_valider_politique_coffres();
REVOKE ALL ON FUNCTION public.x217_valider_politique_coffres() FROM PUBLIC,anon,authenticated,agent_ro,service_role;

CREATE FUNCTION public.x217_montant_ref(p_minor bigint,p_devise text,p_a timestamptz)
RETURNS bigint LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_taux numeric; v_decimales integer; v_ref_decimales integer := 2;
BEGIN
  IF p_devise = 'USD' THEN RETURN p_minor; END IF;
  SELECT f.rate INTO v_taux FROM public.fx_rates f
   WHERE f.from_currency=p_devise AND f.to_currency='USD' AND f.effective_at<=p_a
   ORDER BY f.effective_at DESC,f.id DESC LIMIT 1;
  IF v_taux IS NULL THEN RETURN NULL; END IF;
  v_decimales := CASE WHEN p_devise IN ('JPY','XOF','XAF','KMF') THEN 0
    WHEN p_devise IN ('KWD','BHD','TND','OMR') THEN 3 ELSE 2 END;
  RETURN round(p_minor::numeric*v_taux*power(10::numeric,v_ref_decimales-v_decimales))::bigint;
END;
$function$;

CREATE FUNCTION public.x217_mettre_en_file(p_type text,p_source text,p_raison text)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = ''
AS $function$
  INSERT INTO public.tresorerie_a_reprendre(source_type,source_id,raison)
  VALUES(p_type,p_source,p_raison) ON CONFLICT(source_type,source_id,raison) DO NOTHING;
$function$;

CREATE FUNCTION public.x217_alimenter_wallet_entry()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_type text; v_sens text; v_coffre text; v_source_type text; v_ref bigint;
        v_amount bigint; v_currency text; v_occurred timestamptz; v_id text;
BEGIN
  IF OLD.confirme_par_prestataire_le IS NOT NULL OR NEW.confirme_par_prestataire_le IS NULL THEN RETURN NEW; END IF;
  IF NEW.reference_type='credit' THEN
    v_type:='encaissement'; v_sens:='entree'; v_coffre:='fonds_clients_engages';
  ELSIF NEW.reference_type='refund' THEN
    v_type:='remboursement'; v_sens:='sortie'; v_coffre:='fonds_clients_engages';
    IF NOT EXISTS (SELECT 1 FROM public.wallet_entries original
       WHERE original.id=NEW.refund_of_entry_id AND original.reference_type='credit'
         AND original.confirme_par_prestataire_le IS NOT NULL
         AND original.wallet_id=NEW.wallet_id AND original.currency=NEW.currency)
       OR NEW.amount_minor<=0
       OR NEW.amount_minor > (SELECT original.amount_minor - coalesce(sum(refund.amount_minor),0)
          FROM public.wallet_entries original LEFT JOIN public.wallet_entries refund
            ON refund.refund_of_entry_id=original.id AND refund.reference_type='refund'
           AND refund.confirme_par_prestataire_le IS NOT NULL AND refund.id<>NEW.id
          WHERE original.id=NEW.refund_of_entry_id GROUP BY original.amount_minor) THEN
      RAISE EXCEPTION 'remboursement_source_invalide' USING ERRCODE='23514';
    END IF;
  ELSE RETURN NEW;
  END IF;
  IF NEW.amount_minor<=0 THEN
    PERFORM public.x217_mettre_en_file(v_type,NEW.id::text,'montant_financier_invalide');
    RETURN NEW;
  END IF;
  v_ref:=public.x217_montant_ref(abs(NEW.amount_minor),NEW.currency,NEW.confirme_par_prestataire_le);
  IF v_ref IS NULL THEN
    PERFORM public.x217_mettre_en_file(v_type,NEW.id::text,'taux_change_absent');
    RETURN NEW;
  END IF;
  IF v_ref<=0 THEN
    PERFORM public.x217_mettre_en_file(v_type,NEW.id::text,'montant_financier_invalide');
    RETURN NEW;
  END IF;
  INSERT INTO public.tresorerie_mouvements
    (coffre,sens,montant_minor,devise,montant_ref_minor,devise_ref,survenu_le,
     source_type,regle,source_id,cree_par)
  VALUES(v_coffre,v_sens,abs(NEW.amount_minor),NEW.currency,v_ref,'USD',
    NEW.confirme_par_prestataire_le,v_type,'confirmation_prestataire',NEW.id::text,NULL)
  ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER wallet_entries_tresorerie_confirmation
  AFTER UPDATE OF confirme_par_prestataire_le ON public.wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.x217_alimenter_wallet_entry();

CREATE FUNCTION public.x217_alimenter_payout()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_currency text; v_transfer uuid:=gen_random_uuid(); v_ref bigint;
        v_source text; v_at timestamptz:=clock_timestamp();
BEGIN
  v_source:=NEW.id::text;
  IF TG_OP='UPDATE' THEN
    IF OLD.status IS NOT DISTINCT FROM NEW.status THEN RETURN NEW; END IF;
  END IF;
  SELECT w.currency INTO v_currency FROM public.wallets w WHERE w.id=NEW.wallet_id;
  IF v_currency IS NULL OR NEW.amount_minor<=0 THEN
    PERFORM public.x217_mettre_en_file('payout',v_source,'montant_financier_invalide'); RETURN NEW;
  END IF;
  v_ref:=public.x217_montant_ref(NEW.amount_minor,v_currency,v_at);
  IF v_ref IS NULL THEN
    PERFORM public.x217_mettre_en_file('payout',v_source,'taux_change_absent'); RETURN NEW;
  END IF;
  IF v_ref<=0 THEN
    PERFORM public.x217_mettre_en_file('payout',v_source,'montant_financier_invalide'); RETURN NEW;
  END IF;
  IF NEW.status='requested' THEN
    INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,
      devise_ref,survenu_le,transfert_id,source_type,regle,source_id)
    VALUES('paie_a_decaisser','sortie',NEW.amount_minor,v_currency,v_ref,'USD',v_at,v_transfer,
      'payout','payout_demande',v_source),
      ('en_transit','entree',NEW.amount_minor,v_currency,v_ref,'USD',v_at,v_transfer,
      'payout','payout_demande',v_source)
    ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  ELSIF NEW.status='paid' THEN
    INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,
      devise_ref,survenu_le,source_type,regle,source_id)
    VALUES('en_transit','sortie',NEW.amount_minor,v_currency,v_ref,'USD',v_at,
      'payout','payout_confirme',v_source)
    ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  ELSIF NEW.status IN ('failed','cancelled') THEN
    INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,
      devise_ref,survenu_le,transfert_id,source_type,regle,source_id)
    VALUES('en_transit','sortie',NEW.amount_minor,v_currency,v_ref,'USD',v_at,v_transfer,
      'payout','payout_retour',v_source),
      ('paie_a_decaisser','entree',NEW.amount_minor,v_currency,v_ref,'USD',v_at,v_transfer,
      'payout','payout_retour',v_source)
    ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER payouts_tresorerie_alimentation
  AFTER INSERT OR UPDATE OF status ON public.payouts
  FOR EACH ROW EXECUTE FUNCTION public.x217_alimenter_payout();

CREATE FUNCTION public.x217_marquer_temps_session()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  IF TG_OP='INSERT' THEN
    NEW.finance_started_at:=NULL; NEW.finance_ended_at:=NULL; RETURN NEW;
  END IF;
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status='in_progress' THEN
    NEW.finance_started_at:=clock_timestamp(); NEW.finance_ended_at:=NULL;
  ELSIF OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('ended','tech_failure') THEN
    NEW.finance_started_at:=OLD.finance_started_at;
    NEW.finance_ended_at:=clock_timestamp();
  ELSE
    NEW.finance_started_at:=OLD.finance_started_at; NEW.finance_ended_at:=OLD.finance_ended_at;
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER sessions_tresorerie_timestamps BEFORE INSERT OR UPDATE ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION public.x217_marquer_temps_session();
REVOKE ALL ON FUNCTION public.x217_marquer_temps_session() FROM PUBLIC,anon,authenticated,agent_ro,service_role;

CREATE FUNCTION public.remuneration_due_seance(p_seance uuid)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_session public.sessions%ROWTYPE; v_rate public.regles_remuneration_enseignant%ROWTYPE;
        v_policy public.politique_allocation_coffres%ROWTYPE;
        v_seconds numeric; v_currency_count integer; v_due bigint; v_charge bigint; v_currency text; v_ref bigint;
        v_rem bigint; v_taxes bigint:=0; v_charges bigint:=0; v_reserve bigint:=0; v_libre bigint;
        v_due_ref bigint; v_taxes_ref bigint:=0; v_charges_ref bigint:=0;
        v_reserve_ref bigint:=0; v_libre_ref bigint:=0;
        v_transfer uuid := gen_random_uuid(); v_fx_at timestamptz;
        v_decision_debut timestamptz; v_decision_fin timestamptz; v_zone text;
BEGIN
  SELECT s.* INTO v_session FROM public.sessions s WHERE s.id=p_seance FOR UPDATE;
  IF NOT FOUND OR v_session.status NOT IN ('ended','tech_failure') THEN RETURN NULL; END IF;
  SELECT q.decision_debut,q.decision_fin INTO v_decision_debut,v_decision_fin
    FROM public.tresorerie_a_reprendre q WHERE q.source_type='prestation'
      AND q.source_id=p_seance::text AND q.raison='duree_indeterminee' AND q.traite_le IS NULL
      AND q.decision_debut IS NOT NULL ORDER BY q.id DESC LIMIT 1;
  IF v_session.finance_started_at IS NULL THEN v_session.finance_started_at:=v_decision_debut; END IF;
  IF v_session.finance_ended_at IS NULL THEN v_session.finance_ended_at:=v_decision_fin; END IF;
  IF (v_session.status='tech_failure' AND v_decision_debut IS NULL)
     OR v_session.finance_started_at IS NULL OR v_session.finance_ended_at IS NULL
     OR v_session.finance_ended_at<=v_session.finance_started_at THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'duree_indeterminee'); RETURN NULL;
  END IF;
  v_seconds:=extract(epoch FROM (v_session.finance_ended_at-v_session.finance_started_at))::bigint;
  SELECT coalesce(c.value #>> '{}','Europe/Paris') INTO v_zone
    FROM public.app_config c WHERE c.key='fuseau_comptable';
  v_zone:=coalesce(v_zone,'Europe/Paris');
  SELECT r.* INTO v_rate FROM public.regles_remuneration_enseignant r
   WHERE r.date_effet <= (v_session.finance_started_at AT TIME ZONE v_zone)::date
     AND (r.enseignant_id=v_session.teacher_id OR r.enseignant_id IS NULL)
   ORDER BY (r.enseignant_id IS NOT NULL) DESC,r.date_effet DESC,r.cree_le DESC LIMIT 1;
  IF NOT FOUND THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'regle_remuneration_absente'); RETURN NULL;
  END IF;
  SELECT count(DISTINCT w.currency),sum(abs(w.amount_minor)),min(w.currency)
    INTO v_currency_count,v_charge,v_currency
    FROM public.wallet_entries w
   WHERE w.reference_type='debit' AND w.reference_id=p_seance;
  IF v_currency_count = 0 OR v_charge IS NULL THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'debit_prestation_absent'); RETURN NULL;
  END IF;
  IF v_currency_count > 1 OR v_rate.devise<>v_currency THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'devise_prestation_multiple'); RETURN NULL;
  END IF;
  v_due:=round(v_rate.taux_minor_par_heure::numeric *
    extract(epoch FROM (v_session.finance_ended_at-v_session.finance_started_at))/3600)::bigint;
  IF v_due<=0 OR v_due>v_charge THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'montant_prestation_insuffisant'); RETURN NULL;
  END IF;
  v_fx_at:=v_session.finance_ended_at;
  v_ref:=public.x217_montant_ref(v_charge,v_currency,v_fx_at);
  IF v_ref IS NULL THEN PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'taux_change_absent'); RETURN NULL; END IF;
  v_rem:=v_charge-v_due;
  SELECT p.* INTO v_policy FROM public.politique_allocation_coffres p
   WHERE p.date_effet <= (v_session.finance_started_at AT TIME ZONE v_zone)::date
   ORDER BY p.date_effet DESC LIMIT 1;
  IF FOUND THEN
    v_taxes:=trunc(v_rem*v_policy.taux_taxes_permille/1000.0)::bigint;
    v_charges:=trunc(v_rem*v_policy.taux_charges_permille/1000.0)::bigint;
    v_reserve:=trunc(v_rem*v_policy.taux_reserve_permille/1000.0)::bigint;
  ELSIF v_rem>0 THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'politique_allocation_absente');
  END IF;
  v_libre:=v_rem-v_taxes-v_charges-v_reserve;
  v_due_ref:=public.x217_montant_ref(v_due,v_currency,v_fx_at);
  IF v_taxes>0 THEN v_taxes_ref:=public.x217_montant_ref(v_taxes,v_currency,v_fx_at); END IF;
  IF v_charges>0 THEN v_charges_ref:=public.x217_montant_ref(v_charges,v_currency,v_fx_at); END IF;
  IF v_reserve>0 THEN v_reserve_ref:=public.x217_montant_ref(v_reserve,v_currency,v_fx_at); END IF;
  IF v_libre>0 THEN v_libre_ref:=public.x217_montant_ref(v_libre,v_currency,v_fx_at); END IF;
  IF v_due_ref IS NULL OR v_due_ref<=0 OR (v_taxes>0 AND coalesce(v_taxes_ref,0)<=0)
     OR (v_charges>0 AND coalesce(v_charges_ref,0)<=0)
     OR (v_reserve>0 AND coalesce(v_reserve_ref,0)<=0)
     OR (v_libre>0 AND coalesce(v_libre_ref,0)<=0) THEN
    PERFORM public.x217_mettre_en_file('prestation',p_seance::text,'montant_financier_invalide');
    RETURN NULL;
  END IF;
  INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,devise_ref,
      survenu_le,transfert_id,source_type,regle,source_id)
  VALUES ('fonds_clients_engages','sortie',v_charge,v_currency,v_ref,'USD',v_session.finance_ended_at,
      v_transfer,'prestation','session_debit',p_seance::text),
    ('paie_a_decaisser','entree',v_due,v_currency,
      v_due_ref,'USD',v_session.finance_ended_at,
      v_transfer,'prestation','remuneration_due',p_seance::text)
  ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,
      devise_ref,survenu_le,transfert_id,source_type,regle,source_id)
  SELECT x.coffre,'entree',x.montant,v_currency,x.montant_ref,
      'USD',v_session.finance_ended_at,v_transfer,'prestation',x.regle,p_seance::text
    FROM (VALUES ('taxes_obligations',v_taxes,'allocation_taxes',v_taxes_ref),
      ('charges_essentielles',v_charges,'allocation_charges',v_charges_ref),
      ('reserve_strategique',v_reserve,'allocation_reserve',v_reserve_ref),
      ('tresorerie_libre',v_libre,'solde_libre',v_libre_ref)) AS x(coffre,montant,regle,montant_ref)
   WHERE x.montant>0
  ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  RETURN v_due;
END;
$function$;

CREATE FUNCTION public.x217_sessions_cloture_tresorerie()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('ended','tech_failure') THEN
    PERFORM public.remuneration_due_seance(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER sessions_tresorerie_cloture AFTER UPDATE OF status ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION public.x217_sessions_cloture_tresorerie();

CREATE FUNCTION public.decider_tresorerie_duree(p_id bigint,p_debut timestamptz,p_fin timestamptz)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role()='admin'
      AND auth.jwt()->>'aal'='aal2',false)
     OR p_debut IS NULL OR p_fin IS NULL OR p_fin<=p_debut THEN
    RAISE EXCEPTION 'decision_tresorerie_refusee' USING ERRCODE='42501';
  END IF;
  UPDATE public.tresorerie_a_reprendre SET decision_debut=p_debut,decision_fin=p_fin,
    decide_par=auth.uid(),decide_le=now()
  WHERE id=p_id AND raison='duree_indeterminee' AND traite_le IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'decision_tresorerie_introuvable' USING ERRCODE='22023'; END IF;
  PERFORM public.log_sensitive_access('tresorerie_duree_decidee','tresorerie_a_reprendre',p_id::text,
    jsonb_build_object('debut',p_debut,'fin',p_fin));
END;
$function$;

CREATE FUNCTION public.reprendre_alimentation_tresorerie()
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_row public.tresorerie_a_reprendre%ROWTYPE; v_processed integer:=0;
        v_entry public.wallet_entries%ROWTYPE; v_session public.sessions%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role()='admin'
      AND auth.jwt()->>'aal'='aal2',false) THEN
    RAISE EXCEPTION 'reprise_tresorerie_refusee' USING ERRCODE='42501';
  END IF;
  FOR v_row IN SELECT * FROM public.tresorerie_a_reprendre WHERE traite_le IS NULL FOR UPDATE LOOP
    IF v_row.source_type IN ('encaissement','remboursement') AND v_row.raison='taux_change_absent' THEN
      SELECT * INTO v_entry FROM public.wallet_entries WHERE id=v_row.source_id::bigint;
      IF FOUND AND public.x217_montant_ref(abs(v_entry.amount_minor),v_entry.currency,v_entry.confirme_par_prestataire_le) IS NOT NULL THEN
        PERFORM public.x217_alimenter_wallet_entry_reprise(v_entry.id);
        UPDATE public.tresorerie_a_reprendre SET traite_le=now() WHERE id=v_row.id;
        v_processed:=v_processed+1;
      END IF;
    ELSIF v_row.source_type='prestation' AND v_row.raison='duree_indeterminee'
      AND v_row.decision_debut IS NOT NULL THEN
      SELECT * INTO v_session FROM public.sessions WHERE id=v_row.source_id::uuid;
      IF FOUND THEN
        PERFORM public.remuneration_due_seance(v_session.id);
        UPDATE public.tresorerie_a_reprendre SET traite_le=now() WHERE id=v_row.id;
        v_processed:=v_processed+1;
      END IF;
    ELSIF v_row.source_type='prestation' AND v_row.raison IN ('regle_remuneration_absente','debit_prestation_absent','devise_prestation_multiple','montant_prestation_insuffisant') THEN
      PERFORM public.remuneration_due_seance(v_row.source_id::uuid);
      IF EXISTS (SELECT 1 FROM public.tresorerie_mouvements m WHERE m.source_type='prestation' AND m.source_id=v_row.source_id) THEN
        UPDATE public.tresorerie_a_reprendre SET traite_le=now() WHERE id=v_row.id;
        v_processed:=v_processed+1;
      END IF;
    END IF;
  END LOOP;
  RETURN v_processed;
END;
$function$;

-- Réutilise le même chemin transactionnel et la même clé de déduplication que le trigger.
CREATE FUNCTION public.x217_alimenter_wallet_entry_reprise(p_id bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_entry public.wallet_entries%ROWTYPE;
BEGIN
  SELECT * INTO v_entry FROM public.wallet_entries WHERE id=p_id;
  IF NOT FOUND OR v_entry.confirme_par_prestataire_le IS NULL THEN RETURN; END IF;
  IF v_entry.reference_type='credit' THEN
    INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,devise_ref,survenu_le,source_type,regle,source_id)
    VALUES('fonds_clients_engages','entree',abs(v_entry.amount_minor),v_entry.currency,
      public.x217_montant_ref(abs(v_entry.amount_minor),v_entry.currency,v_entry.confirme_par_prestataire_le),'USD',
      v_entry.confirme_par_prestataire_le,'encaissement','confirmation_prestataire',v_entry.id::text)
    ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  ELSIF v_entry.reference_type='refund' THEN
    INSERT INTO public.tresorerie_mouvements(coffre,sens,montant_minor,devise,montant_ref_minor,devise_ref,survenu_le,source_type,regle,source_id)
    VALUES('fonds_clients_engages','sortie',abs(v_entry.amount_minor),v_entry.currency,
      public.x217_montant_ref(abs(v_entry.amount_minor),v_entry.currency,v_entry.confirme_par_prestataire_le),'USD',
      v_entry.confirme_par_prestataire_le,'remboursement','confirmation_prestataire',v_entry.id::text)
    ON CONFLICT(source_type,source_id,regle,coffre,sens) DO NOTHING;
  END IF;
END;
$function$;

ALTER FUNCTION public.x217_montant_ref(bigint,text,timestamptz) OWNER TO postgres;
ALTER FUNCTION public.x217_mettre_en_file(text,text,text) OWNER TO postgres;
ALTER FUNCTION public.x217_alimenter_wallet_entry() OWNER TO postgres;
ALTER FUNCTION public.x217_alimenter_payout() OWNER TO postgres;
ALTER FUNCTION public.remuneration_due_seance(uuid) OWNER TO postgres;
ALTER FUNCTION public.x217_sessions_cloture_tresorerie() OWNER TO postgres;
ALTER FUNCTION public.decider_tresorerie_duree(bigint,timestamptz,timestamptz) OWNER TO postgres;
ALTER FUNCTION public.reprendre_alimentation_tresorerie() OWNER TO postgres;
ALTER FUNCTION public.x217_alimenter_wallet_entry_reprise(bigint) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.x217_montant_ref(bigint,text,timestamptz) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.x217_mettre_en_file(text,text,text) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.x217_alimenter_wallet_entry() FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.x217_alimenter_payout() FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.remuneration_due_seance(uuid) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.x217_sessions_cloture_tresorerie() FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.x217_alimenter_wallet_entry_reprise(bigint) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.decider_tresorerie_duree(bigint,timestamptz,timestamptz) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.reprendre_alimentation_tresorerie() FROM PUBLIC,anon,agent_ro,service_role;
GRANT EXECUTE ON FUNCTION public.decider_tresorerie_duree(bigint,timestamptz,timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reprendre_alimentation_tresorerie() TO authenticated;

DO $acl$
BEGIN
  IF has_function_privilege('anon','public.remuneration_due_seance(uuid)','EXECUTE')
     OR has_function_privilege('service_role','public.remuneration_due_seance(uuid)','EXECUTE')
     OR has_function_privilege('anon','public.reprendre_alimentation_tresorerie()','EXECUTE')
     OR has_function_privilege('service_role','public.reprendre_alimentation_tresorerie()','EXECUTE')
     OR has_function_privilege('anon','public.decider_tresorerie_duree(bigint,timestamptz,timestamptz)','EXECUTE')
     OR has_function_privilege('service_role','public.decider_tresorerie_duree(bigint,timestamptz,timestamptz)','EXECUTE')
     OR has_function_privilege('anon','public.x217_guard_confirmation_source()','EXECUTE')
     OR has_function_privilege('service_role','public.x217_guard_confirmation_source()','EXECUTE')
     OR has_function_privilege('anon','public.x217_alimenter_payout()','EXECUTE')
     OR has_function_privilege('service_role','public.x217_alimenter_payout()','EXECUTE')
     OR has_table_privilege('service_role','public.tresorerie_mouvements','INSERT')
     OR has_table_privilege('service_role','public.tresorerie_a_reprendre','INSERT')
     OR has_table_privilege('service_role','public.politique_allocation_coffres','INSERT') THEN
    RAISE EXCEPTION 'X2-17 ACL inattendue';
  END IF;
END;
$acl$;

COMMIT;
