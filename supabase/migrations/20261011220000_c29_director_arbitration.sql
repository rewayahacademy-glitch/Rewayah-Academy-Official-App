BEGIN;

-- C-29 directeur: 5 visites hebdomadaires par defaut, reglables et versionnees.
INSERT INTO public.app_config(key,value) VALUES ('controle.missions_par_semaine','5'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.c29_proteger_quota_controle()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  IF NEW.key='controle.missions_par_semaine' AND pg_catalog.pg_trigger_depth() < 2 THEN
    RAISE EXCEPTION 'le quota C-29 se modifie par la RPC versionnee' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.c29_proteger_quota_controle()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER c29_proteger_quota_controle
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.c29_proteger_quota_controle();

CREATE FUNCTION private.c29_sync_quota_controle()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  INSERT INTO public.app_config(key,value,updated_by,updated_at)
  VALUES ('controle.missions_par_semaine',pg_catalog.to_jsonb(NEW.missions_par_semaine),
    NEW.cree_par,pg_catalog.clock_timestamp())
  ON CONFLICT (key) DO UPDATE SET value=excluded.value,
    updated_by=excluded.updated_by,updated_at=excluded.updated_at;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.c29_sync_quota_controle()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER c29_sync_quota_controle
  AFTER INSERT ON public.controle_regles
  FOR EACH ROW EXECUTE FUNCTION private.c29_sync_quota_controle();

CREATE OR REPLACE FUNCTION public.lire_regles_tirage()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE v_config jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role()='admin',false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur','autorisation_direction_requise');
  END IF;
  SELECT pg_catalog.to_jsonb(r) INTO v_config FROM public.controle_regles r
   ORDER BY r.version DESC LIMIT 1;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object(
      'version',(v_config->>'version')::integer,
      'missions_par_semaine',(v_config->>'missions_par_semaine')::integer,
      'ponderations',v_config->'ponderations',
      'cibles',coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id',c.cible_id,'type',c.type,'libelle',c.libelle) ORDER BY c.type,c.cible_id)
        FROM public.controle_regles_cibles c WHERE c.version=(v_config->>'version')::integer),'[]'::jsonb)
    );
  END IF;
  SELECT c.value INTO v_config FROM public.app_config c WHERE c.key='controle.missions_par_semaine';
  RETURN pg_catalog.jsonb_build_object('version',0,
    'missions_par_semaine',coalesce((v_config#>>'{}')::integer,5),
    'ponderations',pg_catalog.jsonb_build_object(
      'enseignants_recents','normal','classes_signalees','normal','heures_de_pointe','normal'),
    'cibles','[]'::jsonb);
END;
$function$;

ALTER TABLE private.controle_missions DROP CONSTRAINT controle_missions_statut_check;
ALTER TABLE private.controle_missions ADD CONSTRAINT controle_missions_statut_check
  CHECK (statut IN ('attribuee','en_cours','controlee','non_controlee','deja_controlee','conflit_declare'));
ALTER TABLE private.controle_mission_journal DROP CONSTRAINT controle_mission_journal_evenement_check;
ALTER TABLE private.controle_mission_journal ADD CONSTRAINT controle_mission_journal_evenement_check
  CHECK (evenement IN ('attribuee','debut','controlee','non_controlee','deja_controlee','conflit_declare'));
ALTER TABLE private.controle_missions ADD COLUMN cle_conflit uuid UNIQUE;

CREATE OR REPLACE FUNCTION private.c29_journaliser_transition_mission()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE v_evenement text;
BEGIN
  IF TG_OP='INSERT' THEN v_evenement:=NEW.statut;
  ELSIF OLD.statut IS DISTINCT FROM NEW.statut THEN
    v_evenement:=CASE NEW.statut WHEN 'en_cours' THEN 'debut' ELSE NEW.statut END;
  ELSE RETURN NEW; END IF;
  INSERT INTO private.controle_mission_journal(mission_id,evenement,acteur_id,payload)
  VALUES(NEW.id,v_evenement,auth.uid(),pg_catalog.jsonb_build_object(
    'session_id',NEW.session_id,'groupe_id',NEW.groupe_id,'controleur_id',NEW.controleur_id,
    'version_regles',NEW.version_regles,'cycle_debut',NEW.cycle_debut,'critere',NEW.critere,
    'rapport_envoye',NEW.rapport_envoye,'cle_conflit',NEW.cle_conflit));
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.c29_journaliser_transition_mission()
  FROM PUBLIC,anon,authenticated,service_role,agent_ro;

CREATE OR REPLACE FUNCTION private.c29_attribuer_mission_controle()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_effectif uuid;
  v_regle public.controle_regles%ROWTYPE;
  v_controller uuid;
  v_candidate public.sessions%ROWTYPE;
  v_cycle date := (pg_catalog.date_trunc('week',pg_catalog.clock_timestamp() AT TIME ZONE 'UTC'))::date;
  v_quota integer;
  v_version integer := 0;
  v_weights jsonb := pg_catalog.jsonb_build_object(
    'enseignants_recents','normal','classes_signalees','normal','heures_de_pointe','normal');
  v_critere text := 'aleatoire';
  v_tz text;
  v_recent boolean;
  v_signalee boolean;
  v_pointe boolean;
BEGIN
  IF NEW.status <> 'in_progress' OR OLD.status = 'in_progress'
     OR NEW.groupe_id IS NULL OR NEW.deleted_at IS NOT NULL THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM private.controle_missions m WHERE m.session_id=NEW.id) THEN RETURN NEW; END IF;
  SELECT r.* INTO v_regle FROM public.controle_regles r ORDER BY r.version DESC LIMIT 1;
  IF FOUND THEN
    v_version:=v_regle.version;
    v_weights:=v_regle.ponderations;
  END IF;
  SELECT coalesce((c.value#>>'{}')::integer,5) INTO v_quota
    FROM public.app_config c WHERE c.key='controle.missions_par_semaine';
  v_quota:=coalesce(v_quota,5);
  IF v_quota NOT BETWEEN 0 AND 50 THEN
    RAISE EXCEPTION 'quota C-29 invalide dans app_config' USING ERRCODE='23514';
  END IF;
  IF v_quota=0 THEN RETURN NEW; END IF;

  -- Le pool ne contient que des seances deja commencees. Les classes sans
  -- visite cette semaine passent d'abord; les autres ne sont prises qu'apres.
  SELECT s.* INTO v_candidate
    FROM public.sessions s
    JOIN public.groupes g ON g.id=s.groupe_id AND g.ended_at IS NULL
    WHERE s.status='in_progress' AND s.deleted_at IS NULL AND s.groupe_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM private.controle_missions m WHERE m.session_id=s.id)
      AND NOT EXISTS (SELECT 1 FROM private.controle_missions m
        WHERE m.groupe_id=s.groupe_id AND m.statut IN ('attribuee','en_cours'))
      AND EXISTS (SELECT 1 FROM private.controle_capacites c
        JOIN public.profiles p ON p.id=c.profile_id
        WHERE c.revoked_at IS NULL AND c.active_from<=pg_catalog.clock_timestamp()
          AND c.expires_at>pg_catalog.clock_timestamp()
          AND p.role IN ('controller','teacher','admin') AND p.account_status='active'
          AND p.deleted_at IS NULL AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp())
          AND p.id<>private.c29_enseignant_effectif_session(s.id)
          AND (c.scope_all_groups OR s.groupe_id=ANY(c.scope_group_ids)
               OR private.c29_enseignant_effectif_session(s.id)=ANY(c.scope_teacher_ids))
          AND NOT EXISTS (SELECT 1 FROM public.session_participants sp
            WHERE sp.session_id=s.id AND sp.profile_id=p.id AND sp.role<>'masked_controller'
              AND sp.deleted_at IS NULL AND sp.exited_at IS NULL)
          AND NOT EXISTS (SELECT 1 FROM private.controle_missions own
            WHERE own.controleur_id=p.id AND own.cycle_debut=v_cycle
            GROUP BY own.controleur_id HAVING count(*)>=v_quota))
    ORDER BY
      CASE WHEN EXISTS (SELECT 1 FROM private.controle_missions done
        WHERE done.groupe_id=s.groupe_id AND done.cycle_debut=v_cycle
          AND done.statut='controlee') THEN 1 ELSE 0 END,
      -pg_catalog.ln(1.0-pg_catalog.random()) /
        (
        CASE WHEN EXISTS (SELECT 1 FROM private.controle_missions previous_teacher
          WHERE previous_teacher.enseignant_effectif_id=private.c29_enseignant_effectif_session(s.id)
            AND previous_teacher.affectee_le>=pg_catalog.clock_timestamp()-interval '28 days')
          THEN 0.25 ELSE 1 END *
        CASE WHEN EXISTS (SELECT 1 FROM public.controle_regles_cibles t
          WHERE t.version=v_version AND ((t.type='classe' AND t.cible_id=s.groupe_id)
            OR (t.type='enseignant' AND t.cible_id=private.c29_enseignant_effectif_session(s.id)))) THEN 8
        ELSE 1 END *
        CASE WHEN EXISTS (SELECT 1 FROM public.student_concern sc
          WHERE sc.groupe_id=s.groupe_id AND sc.statut='ouvert'
            AND sc.cree_le>=pg_catalog.clock_timestamp()-interval '30 days')
          AND v_weights->>'classes_signalees'='fort' THEN 4
        WHEN EXISTS (SELECT 1 FROM public.student_concern sc
          WHERE sc.groupe_id=s.groupe_id AND sc.statut='ouvert'
            AND sc.cree_le>=pg_catalog.clock_timestamp()-interval '30 days')
          AND v_weights->>'classes_signalees'='normal' THEN 2 ELSE 1 END *
        CASE WHEN EXISTS (SELECT 1 FROM public.teacher_profiles tp
          WHERE tp.profile_id=private.c29_enseignant_effectif_session(s.id)
            AND tp.created_at>=pg_catalog.clock_timestamp()-interval '90 days')
          AND v_weights->>'enseignants_recents'='fort' THEN 4
        WHEN EXISTS (SELECT 1 FROM public.teacher_profiles tp
          WHERE tp.profile_id=private.c29_enseignant_effectif_session(s.id)
            AND tp.created_at>=pg_catalog.clock_timestamp()-interval '90 days')
          AND v_weights->>'enseignants_recents'='normal' THEN 2 ELSE 1 END *
        CASE WHEN (s.started_at AT TIME ZONE g.timezone_iana)::time >= TIME '17:00'
          AND (s.started_at AT TIME ZONE g.timezone_iana)::time < TIME '21:00'
          AND v_weights->>'heures_de_pointe'='fort' THEN 4
        WHEN (s.started_at AT TIME ZONE g.timezone_iana)::time >= TIME '17:00'
          AND (s.started_at AT TIME ZONE g.timezone_iana)::time < TIME '21:00'
          AND v_weights->>'heures_de_pointe'='normal' THEN 2 ELSE 1 END
        ),
      s.id
    LIMIT 1 FOR UPDATE OF s SKIP LOCKED;
  IF NOT FOUND THEN RETURN NEW; END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('controle-groupe:'||v_candidate.groupe_id::text,0));
  IF EXISTS (SELECT 1 FROM private.controle_missions m
      WHERE m.groupe_id=v_candidate.groupe_id AND m.statut IN ('attribuee','en_cours')) THEN
    RETURN NEW;
  END IF;
  v_effectif:=private.c29_enseignant_effectif_session(v_candidate.id);
  IF v_effectif IS NULL THEN RETURN NEW; END IF;
  SELECT g.timezone_iana INTO v_tz FROM public.groupes g WHERE g.id=v_candidate.groupe_id;
  SELECT EXISTS (SELECT 1 FROM public.teacher_profiles tp
      WHERE tp.profile_id=v_effectif AND tp.created_at>=pg_catalog.clock_timestamp()-interval '90 days')
    INTO v_recent;
  SELECT EXISTS (SELECT 1 FROM public.student_concern sc WHERE sc.groupe_id=v_candidate.groupe_id
      AND sc.statut='ouvert' AND sc.cree_le>=pg_catalog.clock_timestamp()-interval '30 days') INTO v_signalee;
  v_pointe:=(v_candidate.started_at AT TIME ZONE v_tz)::time >= TIME '17:00'
    AND (v_candidate.started_at AT TIME ZONE v_tz)::time < TIME '21:00';
  IF EXISTS (SELECT 1 FROM public.controle_regles_cibles t WHERE t.version=v_version
      AND ((t.type='classe' AND t.cible_id=v_candidate.groupe_id)
        OR (t.type='enseignant' AND t.cible_id=v_effectif))) THEN
    v_critere:='cible';
  ELSIF (v_recent AND v_weights->>'enseignants_recents'<>'aucun')
      OR (v_signalee AND v_weights->>'classes_signalees'<>'aucun')
      OR (v_pointe AND v_weights->>'heures_de_pointe'<>'aucun') THEN
    v_critere:='ponderation';
  END IF;
  SELECT c.profile_id INTO v_controller FROM private.controle_capacites c
    JOIN public.profiles p ON p.id=c.profile_id
    WHERE c.revoked_at IS NULL AND c.active_from<=pg_catalog.clock_timestamp()
      AND c.expires_at>pg_catalog.clock_timestamp()
      AND p.role IN ('controller','teacher','admin') AND p.account_status='active'
      AND p.deleted_at IS NULL AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp())
      AND p.id<>v_effectif
      AND (c.scope_all_groups OR v_candidate.groupe_id=ANY(c.scope_group_ids)
           OR v_effectif=ANY(c.scope_teacher_ids))
      AND NOT EXISTS (SELECT 1 FROM public.session_participants sp
        WHERE sp.session_id=v_candidate.id AND sp.profile_id=p.id AND sp.role<>'masked_controller'
          AND sp.deleted_at IS NULL AND sp.exited_at IS NULL)
      AND NOT EXISTS (SELECT 1 FROM private.controle_missions own
        WHERE own.controleur_id=p.id AND own.cycle_debut=v_cycle
        GROUP BY own.controleur_id HAVING count(*)>=v_quota)
    ORDER BY -pg_catalog.ln(1.0-pg_catalog.random()) /
      CASE WHEN EXISTS (SELECT 1 FROM private.controle_missions ancienne_mission
        WHERE ancienne_mission.controleur_id=c.profile_id
          AND ancienne_mission.groupe_id=v_candidate.groupe_id
          AND ancienne_mission.affectee_le>=pg_catalog.clock_timestamp()-interval '28 days')
        THEN 0.25 ELSE 1 END,
      c.profile_id
    LIMIT 1 FOR UPDATE OF c SKIP LOCKED;
  IF v_controller IS NULL THEN RETURN NEW; END IF;
  INSERT INTO private.controle_missions(session_id,groupe_id,enseignant_effectif_id,
    controleur_id,version_regles,cycle_debut,critere,echeance,statut)
  VALUES(v_candidate.id,v_candidate.groupe_id,v_effectif,v_controller,v_version,v_cycle,
    v_critere,v_candidate.ended_at,'attribuee');
  INSERT INTO public.notifications(destinataire,evenement,params,destination)
  VALUES(v_controller,'controle_mission_attribuee',pg_catalog.jsonb_build_object(
    'mission_id',(SELECT id FROM private.controle_missions WHERE session_id=v_candidate.id)),
    '/controleur');
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.c29_attribuer_mission_controle() OWNER TO postgres;
COMMENT ON FUNCTION private.c29_attribuer_mission_controle() IS
 'F86 candidate allowlist: signature=private.c29_attribuer_mission_controle(); md5_functiondef=A_CALCULER; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE OR REPLACE FUNCTION public.demarrer_mission_controle(p_mission_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_mission private.controle_missions%ROWTYPE;
BEGIN
  SELECT * INTO v_mission FROM private.controle_missions
   WHERE id=p_mission_id AND controleur_id=auth.uid() FOR UPDATE;
  IF NOT FOUND OR NOT coalesce(public.app_account_valid()
      AND auth.jwt()->>'aal'='aal2'
      AND EXISTS (SELECT 1 FROM private.controle_capacites c JOIN public.profiles p ON p.id=c.profile_id
        WHERE c.profile_id=auth.uid() AND c.revoked_at IS NULL
          AND c.active_from<=pg_catalog.clock_timestamp() AND c.expires_at>pg_catalog.clock_timestamp()
          AND p.role IN ('controller','teacher','admin') AND p.account_status='active'
          AND p.deleted_at IS NULL AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp())
          AND (c.scope_all_groups OR v_mission.groupe_id=ANY(c.scope_group_ids)
            OR v_mission.enseignant_effectif_id=ANY(c.scope_teacher_ids))),false) THEN
    RAISE EXCEPTION 'mission indisponible' USING ERRCODE='42501';
  END IF;
  IF v_mission.statut<>'attribuee' OR v_mission.echeance<=pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'mission expiree ou deja commencee' USING ERRCODE='55000';
  END IF;
  UPDATE private.controle_missions SET statut='en_cours',commencee_le=pg_catalog.clock_timestamp()
   WHERE id=p_mission_id;
  INSERT INTO public.session_participants(session_id,profile_id,role,entered_at)
  VALUES(v_mission.session_id,auth.uid(),'masked_controller',pg_catalog.clock_timestamp())
  ON CONFLICT(session_id,profile_id) DO UPDATE SET deleted_at=NULL,entered_at=excluded.entered_at;
  RETURN pg_catalog.jsonb_build_object('statut','en_cours');
END;
$function$;
COMMENT ON FUNCTION public.demarrer_mission_controle(uuid) IS
 'F86 candidate allowlist: signature=public.demarrer_mission_controle(uuid); md5_functiondef=3fe3b44c1d1451f72dcc0d0e47ceffcb; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE OR REPLACE FUNCTION public.ma_mission_controle()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce((SELECT pg_catalog.jsonb_build_object(
    'id',m.id,'session_id',m.session_id,'groupe_id',m.groupe_id,
    'enseignant_effectif_id',m.enseignant_effectif_id,'echeance',m.echeance,
    'statut',m.statut,'commencee_le',m.commencee_le)
    FROM private.controle_missions m JOIN private.controle_capacites c ON c.profile_id=m.controleur_id
    JOIN public.profiles p ON p.id=m.controleur_id
    WHERE m.controleur_id=auth.uid() AND m.statut IN ('attribuee','en_cours')
      AND c.revoked_at IS NULL AND c.active_from<=pg_catalog.clock_timestamp()
      AND c.expires_at>pg_catalog.clock_timestamp()
      AND (c.scope_all_groups OR m.groupe_id=ANY(c.scope_group_ids)
        OR m.enseignant_effectif_id=ANY(c.scope_teacher_ids))
      AND p.role IN ('controller','teacher','admin') AND p.account_status='active'
      AND p.deleted_at IS NULL AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp())
      AND public.app_account_valid() AND auth.jwt()->>'aal'='aal2'
    ORDER BY m.affectee_le DESC LIMIT 1),'{}'::jsonb);
$function$;
COMMENT ON FUNCTION public.ma_mission_controle() IS
 'F86 candidate allowlist: signature=public.ma_mission_controle(); md5_functiondef=bfc289f725aaf511f497e4c81faebf69; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.declarer_conflit_mission(p_mission_id uuid,p_cle uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_mission private.controle_missions%ROWTYPE;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND auth.jwt()->>'aal'='aal2'
     AND EXISTS(SELECT 1 FROM private.controle_capacites c JOIN public.profiles p ON p.id=c.profile_id
       WHERE c.profile_id=auth.uid() AND c.revoked_at IS NULL
         AND c.active_from<=pg_catalog.clock_timestamp() AND c.expires_at>pg_catalog.clock_timestamp()
         AND p.role IN ('controller','teacher','admin') AND p.account_status='active'
         AND p.deleted_at IS NULL),false) THEN
    RAISE EXCEPTION 'capacite controle active et MFA requise' USING ERRCODE='42501';
  END IF;
  IF p_mission_id IS NULL OR p_cle IS NULL THEN
    RAISE EXCEPTION 'cle et mission requises' USING ERRCODE='22023';
  END IF;
  SELECT * INTO v_mission FROM private.controle_missions
   WHERE id=p_mission_id AND controleur_id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'mission indisponible' USING ERRCODE='42501'; END IF;
  IF v_mission.cle_conflit=p_cle THEN
    RETURN pg_catalog.jsonb_build_object('statut',v_mission.statut);
  END IF;
  IF v_mission.cle_conflit IS NOT NULL THEN
    RAISE EXCEPTION 'cle de conflit deja utilisee' USING ERRCODE='22023';
  END IF;
  IF v_mission.statut<>'attribuee' THEN
    RAISE EXCEPTION 'conflit impossible apres le debut du controle' USING ERRCODE='55000';
  END IF;
  UPDATE private.controle_missions SET statut='conflit_declare',cle_conflit=p_cle,
      terminee_le=pg_catalog.clock_timestamp()
   WHERE id=p_mission_id;
  RETURN pg_catalog.jsonb_build_object('statut','conflit_declare');
END;
$function$;
ALTER FUNCTION public.declarer_conflit_mission(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.declarer_conflit_mission(uuid,uuid) FROM PUBLIC,anon,service_role,agent_ro;
GRANT EXECUTE ON FUNCTION public.declarer_conflit_mission(uuid,uuid) TO authenticated;
COMMENT ON FUNCTION public.declarer_conflit_mission(uuid,uuid) IS
 'F86 candidate allowlist: signature=public.declarer_conflit_mission(uuid,uuid); md5_functiondef=ec0543210cae0d373ef9f38749e4b136; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

COMMIT;
