BEGIN;

CREATE TABLE public.pause_reglages (
  groupe_id uuid PRIMARY KEY REFERENCES public.groupes(id) ON DELETE CASCADE,
  actif boolean NOT NULL DEFAULT false,
  apres_minutes integer NOT NULL DEFAULT 15
    CHECK (apres_minutes BETWEEN 5 AND 120 AND apres_minutes % 5 = 0),
  duree_minutes integer NOT NULL DEFAULT 5
    CHECK (duree_minutes BETWEEN 5 AND 30 AND duree_minutes % 5 = 0),
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  updated_by uuid NOT NULL REFERENCES public.profiles(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.pause_reglages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pause_reglages FROM PUBLIC, anon, authenticated, agent_ro, service_role;

CREATE TABLE public.pause_reglages_historique (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  groupe_id uuid NOT NULL,
  version bigint NOT NULL,
  acteur_id uuid NOT NULL,
  ancienne_valeur jsonb,
  nouvelle_valeur jsonb NOT NULL,
  cree_le timestamptz NOT NULL DEFAULT now(),
  UNIQUE (groupe_id, version)
);
ALTER TABLE public.pause_reglages_historique ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pause_reglages_historique FROM PUBLIC, anon, authenticated, agent_ro, service_role;

CREATE TABLE public.pause_seances (
  seance_id uuid PRIMARY KEY REFERENCES public.sessions(id) ON DELETE CASCADE,
  statut text NOT NULL CHECK (statut IN ('non_prevue','programmee','en_cours','prise','non_prise')),
  duree_prevue_minutes integer NOT NULL CHECK (duree_prevue_minutes BETWEEN 5 AND 30 AND duree_prevue_minutes % 5 = 0),
  debut_prevu_utc timestamptz,
  debut_utc timestamptz,
  fin_utc timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((statut = 'non_prevue' AND debut_prevu_utc IS NULL)
      OR (statut <> 'non_prevue' AND debut_prevu_utc IS NOT NULL)),
  CHECK ((statut IN ('en_cours','prise') AND debut_utc IS NOT NULL)
      OR (statut NOT IN ('en_cours','prise') AND debut_utc IS NULL)),
  CHECK ((statut IN ('prise','non_prise') AND fin_utc IS NOT NULL)
      OR (statut NOT IN ('prise','non_prise') AND fin_utc IS NULL))
);
ALTER TABLE public.pause_seances ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pause_seances FROM PUBLIC, anon, authenticated, agent_ro, service_role;

CREATE TABLE public.pause_idempotence (
  acteur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cle_idempotence text NOT NULL CHECK (length(btrim(cle_idempotence)) BETWEEN 1 AND 200),
  operation text NOT NULL,
  cible_id uuid NOT NULL,
  requete jsonb NOT NULL,
  resultat jsonb,
  cree_le timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (acteur_id, cle_idempotence)
);
ALTER TABLE public.pause_idempotence ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pause_idempotence FROM PUBLIC, anon, authenticated, agent_ro, service_role;

CREATE OR REPLACE FUNCTION public.pause_reglage_lire(p_groupe_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_result jsonb; v_role public.app_role;
BEGIN
  v_role := public.app_role();
  IF auth.uid() IS NULL OR NOT public.app_account_valid()
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id)
     OR NOT (v_role = 'admin' OR (v_role = 'teacher' AND EXISTS (
       SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()
     ))) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture du reglage refusee';
  END IF;
  SELECT jsonb_build_object('actif', coalesce(r.actif, false),
    'apres_minutes', coalesce(r.apres_minutes, 15), 'duree_minutes', coalesce(r.duree_minutes, 5),
    'version', coalesce(r.version, 0)::text,
    'peut_modifier', v_role = 'teacher')
    INTO v_result FROM (SELECT 1) x
    LEFT JOIN public.pause_reglages r ON r.groupe_id = p_groupe_id;
  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.pause_reglage_ecrire(
  p_groupe_id uuid, p_actif boolean, p_apres_minutes integer, p_duree_minutes integer,
  p_version_attendue text, p_cle_idempotence text
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_old public.pause_reglages%ROWTYPE;
  v_previous public.pause_idempotence%ROWTYPE;
  v_request jsonb;
  v_result jsonb;
  v_version bigint;
BEGIN
  IF auth.uid() IS NULL OR p_groupe_id IS NULL OR p_actif IS NULL
     OR coalesce(length(btrim(p_cle_idempotence)), 0) NOT BETWEEN 1 AND 200
     OR NOT coalesce(public.app_role() = 'teacher' AND public.app_account_valid(), false)
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'ecriture du reglage refusee';
  END IF;
  IF p_apres_minutes IS NULL OR p_duree_minutes IS NULL
     OR p_apres_minutes NOT BETWEEN 5 AND 120 OR p_apres_minutes % 5 <> 0
     OR p_duree_minutes NOT BETWEEN 5 AND 30 OR p_duree_minutes % 5 <> 0 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'valeur_invalide';
  END IF;
  v_request := jsonb_build_object('groupe_id',p_groupe_id,'actif',p_actif,
    'apres_minutes',p_apres_minutes,'duree_minutes',p_duree_minutes,
    'version_attendue',p_version_attendue);
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text || ':' || p_cle_idempotence, 0));
  SELECT i.* INTO v_previous FROM public.pause_idempotence i
   WHERE i.acteur_id = auth.uid() AND i.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    IF v_previous.operation <> 'reglage' OR v_previous.cible_id <> p_groupe_id
       OR v_previous.requete IS DISTINCT FROM v_request THEN
      RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'cle_idempotence_reutilisee';
    END IF;
    RETURN v_previous.resultat;
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('pause-reglage:' || p_groupe_id::text, 0));
  SELECT r.* INTO v_old FROM public.pause_reglages r WHERE r.groupe_id = p_groupe_id FOR UPDATE;
  v_version := coalesce(v_old.version, 0);
  IF p_version_attendue IS DISTINCT FROM v_version::text THEN
    RAISE EXCEPTION USING ERRCODE = '40001', MESSAGE = 'reglage_obsolete';
  END IF;
  INSERT INTO public.pause_reglages AS actuel
    (groupe_id,actif,apres_minutes,duree_minutes,version,updated_by,updated_at)
  VALUES (p_groupe_id,p_actif,p_apres_minutes,p_duree_minutes,v_version+1,auth.uid(),now())
  ON CONFLICT (groupe_id) DO UPDATE SET actif=EXCLUDED.actif,
    apres_minutes=EXCLUDED.apres_minutes,duree_minutes=EXCLUDED.duree_minutes,
    version=actuel.version+1,updated_by=auth.uid(),updated_at=now();
  INSERT INTO public.pause_reglages_historique
    (groupe_id,version,acteur_id,ancienne_valeur,nouvelle_valeur)
  VALUES (p_groupe_id,v_version+1,auth.uid(),
    CASE WHEN v_old.groupe_id IS NULL THEN NULL ELSE jsonb_build_object(
      'actif',v_old.actif,'apres_minutes',v_old.apres_minutes,'duree_minutes',v_old.duree_minutes) END,
    jsonb_build_object('actif',p_actif,'apres_minutes',p_apres_minutes,'duree_minutes',p_duree_minutes));
  PERFORM public.log_sensitive_access('pause_reglage_modifie','pause_reglages',p_groupe_id::text,
    jsonb_build_object('ancienne_valeur',CASE WHEN v_old.groupe_id IS NULL THEN NULL ELSE
      jsonb_build_object('actif',v_old.actif,'apres_minutes',v_old.apres_minutes,'duree_minutes',v_old.duree_minutes) END,
      'nouvelle_valeur',jsonb_build_object('actif',p_actif,'apres_minutes',p_apres_minutes,'duree_minutes',p_duree_minutes)));
  v_result := public.pause_reglage_lire(p_groupe_id);
  INSERT INTO public.pause_idempotence(acteur_id,cle_idempotence,operation,cible_id,requete,resultat)
    VALUES(auth.uid(),p_cle_idempotence,'reglage',p_groupe_id,v_request,v_result);
  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.pause_etat_interne(p_seance_id uuid, p_uid uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'statut', coalesce(ps.statut,'non_prevue'),
    'duree_prevue_minutes', coalesce(ps.duree_prevue_minutes,5),
    'debut_prevu_utc',ps.debut_prevu_utc,'debut_utc',ps.debut_utc,'fin_utc',ps.fin_utc,
    'peut_piloter', coalesce(s.teacher_id = p_uid AND s.status = 'in_progress',false))
    INTO v_result
    FROM public.sessions s LEFT JOIN public.pause_seances ps ON ps.seance_id=s.id
   WHERE s.id=p_seance_id AND s.deleted_at IS NULL;
  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.pause_seance_etat(p_seance_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_role public.app_role;
BEGIN
  v_role := public.app_role();
  IF auth.uid() IS NULL OR NOT public.app_account_valid()
     OR NOT EXISTS (SELECT 1 FROM public.sessions s WHERE s.id=p_seance_id AND s.deleted_at IS NULL
       AND (v_role='admin' OR (v_role='teacher' AND s.teacher_id=auth.uid()))) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='lecture de pause refusee';
  END IF;
  RETURN public.pause_etat_interne(p_seance_id,auth.uid());
END;
$function$;

CREATE OR REPLACE FUNCTION public.pause_seance_demarrer(p_seance_id uuid,p_cle_idempotence text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_s public.sessions%ROWTYPE; v_pause public.pause_seances%ROWTYPE; v_i public.pause_idempotence%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR coalesce(public.app_role()='teacher' AND public.app_account_valid(),false)=false
     OR coalesce(length(btrim(p_cle_idempotence)),0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pilotage de pause refuse';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||':'||p_cle_idempotence,0));
  SELECT i.* INTO v_i FROM public.pause_idempotence i WHERE i.acteur_id=auth.uid() AND i.cle_idempotence=p_cle_idempotence;
  IF FOUND THEN
    IF v_i.operation<>'demarrer' OR v_i.cible_id<>p_seance_id THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='cle_idempotence_reutilisee'; END IF;
    RETURN public.pause_seance_etat(p_seance_id);
  END IF;
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id=p_seance_id AND s.teacher_id=auth.uid() AND s.deleted_at IS NULL FOR UPDATE;
  IF NOT FOUND OR v_s.status<>'in_progress' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pilotage de pause refuse'; END IF;
  SELECT ps.* INTO v_pause FROM public.pause_seances ps WHERE ps.seance_id=p_seance_id FOR UPDATE;
  IF NOT FOUND OR v_pause.statut NOT IN ('programmee','en_cours') THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pause non disponible'; END IF;
  IF v_pause.statut='programmee' THEN
    UPDATE public.pause_seances SET statut='en_cours',debut_utc=now(),updated_at=now() WHERE seance_id=p_seance_id;
  END IF;
  INSERT INTO public.pause_idempotence(acteur_id,cle_idempotence,operation,cible_id,requete)
    VALUES(auth.uid(),p_cle_idempotence,'demarrer',p_seance_id,jsonb_build_object('seance_id',p_seance_id));
  RETURN public.pause_etat_interne(p_seance_id,auth.uid());
END;
$function$;

CREATE OR REPLACE FUNCTION public.pause_seance_terminer(p_seance_id uuid,p_cle_idempotence text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_s public.sessions%ROWTYPE; v_pause public.pause_seances%ROWTYPE; v_i public.pause_idempotence%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR coalesce(public.app_role()='teacher' AND public.app_account_valid(),false)=false
     OR coalesce(length(btrim(p_cle_idempotence)),0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pilotage de pause refuse';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||':'||p_cle_idempotence,0));
  SELECT i.* INTO v_i FROM public.pause_idempotence i WHERE i.acteur_id=auth.uid() AND i.cle_idempotence=p_cle_idempotence;
  IF FOUND THEN
    IF v_i.operation<>'terminer' OR v_i.cible_id<>p_seance_id THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='cle_idempotence_reutilisee'; END IF;
    RETURN public.pause_seance_etat(p_seance_id);
  END IF;
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id=p_seance_id AND s.teacher_id=auth.uid() AND s.deleted_at IS NULL FOR UPDATE;
  IF NOT FOUND OR v_s.status<>'in_progress' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pilotage de pause refuse'; END IF;
  SELECT ps.* INTO v_pause FROM public.pause_seances ps WHERE ps.seance_id=p_seance_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pause non disponible'; END IF;
  IF v_pause.statut='en_cours' THEN
    UPDATE public.pause_seances SET statut='prise',fin_utc=now(),updated_at=now() WHERE seance_id=p_seance_id;
  END IF;
  INSERT INTO public.pause_idempotence(acteur_id,cle_idempotence,operation,cible_id,requete)
    VALUES(auth.uid(),p_cle_idempotence,'terminer',p_seance_id,jsonb_build_object('seance_id',p_seance_id));
  RETURN public.pause_etat_interne(p_seance_id,auth.uid());
END;
$function$;

CREATE OR REPLACE FUNCTION public.pause_seance_snapshot_trigger()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_reglage public.pause_reglages%ROWTYPE;
BEGIN
  IF TG_OP='UPDATE' AND OLD.status IS DISTINCT FROM NEW.status
     AND NEW.status='in_progress' AND NEW.groupe_id IS NOT NULL THEN
    SELECT r.* INTO v_reglage FROM public.pause_reglages r WHERE r.groupe_id=NEW.groupe_id;
    IF FOUND AND v_reglage.actif THEN
      INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc)
      VALUES(NEW.id,'programmee',v_reglage.duree_minutes,now()+make_interval(mins=>v_reglage.apres_minutes))
      ON CONFLICT(seance_id) DO NOTHING;
    ELSE
      INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc)
      VALUES(NEW.id,'non_prevue',5,NULL) ON CONFLICT(seance_id) DO NOTHING;
    END IF;
  END IF;
  IF TG_OP='UPDATE' AND OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('ended','tech_failure') THEN
    UPDATE public.pause_seances SET
      statut=CASE WHEN statut='en_cours' THEN 'prise' WHEN statut='programmee' THEN 'non_prise' ELSE statut END,
      fin_utc=CASE WHEN statut IN ('en_cours','programmee') THEN now() ELSE fin_utc END,
      updated_at=now()
    WHERE seance_id=NEW.id AND statut IN ('en_cours','programmee');
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER sessions_pause_snapshot
AFTER UPDATE OF status ON public.sessions
FOR EACH ROW EXECUTE FUNCTION public.pause_seance_snapshot_trigger();

ALTER FUNCTION public.pause_reglage_lire(uuid) OWNER TO postgres;
ALTER FUNCTION public.pause_reglage_ecrire(uuid,boolean,integer,integer,text,text) OWNER TO postgres;
ALTER FUNCTION public.pause_etat_interne(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.pause_seance_etat(uuid) OWNER TO postgres;
ALTER FUNCTION public.pause_seance_demarrer(uuid,text) OWNER TO postgres;
ALTER FUNCTION public.pause_seance_terminer(uuid,text) OWNER TO postgres;
ALTER FUNCTION public.pause_seance_snapshot_trigger() OWNER TO postgres;

REVOKE ALL ON FUNCTION public.pause_reglage_lire(uuid) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_reglage_ecrire(uuid,boolean,integer,integer,text,text) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_etat_interne(uuid,uuid) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_seance_etat(uuid) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_seance_demarrer(uuid,text) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_seance_terminer(uuid,text) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_seance_snapshot_trigger() FROM PUBLIC,anon,authenticated,agent_ro,service_role;
GRANT EXECUTE ON FUNCTION public.pause_reglage_lire(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_reglage_ecrire(uuid,boolean,integer,integer,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_seance_etat(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_seance_demarrer(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_seance_terminer(uuid,text) TO authenticated;

DO $acl$
BEGIN
  IF NOT has_function_privilege('authenticated','public.pause_reglage_lire(uuid)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_reglage_ecrire(uuid,boolean,integer,integer,text,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_seance_etat(uuid)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_seance_demarrer(uuid,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_seance_terminer(uuid,text)','EXECUTE')
     OR has_function_privilege('anon','public.pause_reglage_lire(uuid)','EXECUTE')
     OR has_function_privilege('service_role','public.pause_reglage_lire(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','public.pause_etat_interne(uuid,uuid)','EXECUTE')
     OR has_function_privilege('anon','public.pause_reglage_ecrire(uuid,boolean,integer,integer,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'X2-22 ACL inattendue';
  END IF;
END;
$acl$;

COMMIT;
