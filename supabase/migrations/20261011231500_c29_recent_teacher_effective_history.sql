-- C-29: derive historical teacher ownership from confirmed B-09 replacement events.
BEGIN;

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
        CASE WHEN coalesce((SELECT pg_catalog.min(seance_realisee.started_at)>=pg_catalog.clock_timestamp()-interval '90 days' FROM public.sessions seance_realisee WHERE private.c29_enseignant_effectif_session(seance_realisee.id)=private.c29_enseignant_effectif_session(s.id) AND seance_realisee.status='ended' AND seance_realisee.deleted_at IS NULL),false)
          AND v_weights->>'enseignants_recents'='fort' THEN 4
        WHEN coalesce((SELECT pg_catalog.min(seance_realisee.started_at)>=pg_catalog.clock_timestamp()-interval '90 days' FROM public.sessions seance_realisee WHERE private.c29_enseignant_effectif_session(seance_realisee.id)=private.c29_enseignant_effectif_session(s.id) AND seance_realisee.status='ended' AND seance_realisee.deleted_at IS NULL),false)
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
  SELECT coalesce((SELECT pg_catalog.min(s.started_at)>=pg_catalog.clock_timestamp()-interval '90 days' FROM public.sessions s WHERE private.c29_enseignant_effectif_session(s.id)=v_effectif AND s.status='ended' AND s.deleted_at IS NULL),false) INTO v_recent;
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
 'F86 candidate allowlist: signature=private.c29_attribuer_mission_controle(); md5_functiondef=ceb2ac64c99895fa5c97d3f4b92bcf87; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11. Must-pass: pondération récente uniquement si la première séance terminée non supprimée de l’enseignant effectivement en charge (titulaire ou remplacement B-09 confirmé) date des 90 derniers jours; la date de création du compte n’influence pas ce critère.';
COMMIT;
