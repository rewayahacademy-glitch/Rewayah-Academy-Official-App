BEGIN;

-- C-29: server-owned mission cycle. The configured weekly number is a ceiling
-- per controller; the cycle boundary is Monday 00:00 UTC.
CREATE TABLE private.controle_missions (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  session_id uuid NOT NULL UNIQUE REFERENCES public.sessions(id) ON DELETE RESTRICT,
  groupe_id uuid NOT NULL REFERENCES public.groupes(id) ON DELETE RESTRICT,
  enseignant_effectif_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  controleur_id uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  version_regles integer NOT NULL CHECK (version_regles >= 0),
  cycle_debut date NOT NULL,
  critere text NOT NULL CHECK (critere IN ('aleatoire', 'ponderation', 'cible')),
  affectee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  echeance timestamptz NOT NULL,
  commencee_le timestamptz,
  terminee_le timestamptz,
  statut text NOT NULL CHECK (statut IN (
    'attribuee', 'en_cours', 'controlee', 'non_controlee', 'deja_controlee'
  )),
  rapport_envoye boolean NOT NULL DEFAULT false,
  rapport_envoye_le timestamptz,
  CONSTRAINT controle_missions_controller_status CHECK (
    (statut = 'deja_controlee' AND controleur_id IS NULL)
    OR (statut <> 'deja_controlee' AND controleur_id IS NOT NULL)
  ),
  CONSTRAINT controle_missions_times CHECK (
    (commencee_le IS NULL OR commencee_le >= affectee_le)
    AND (terminee_le IS NULL OR terminee_le >= coalesce(commencee_le, affectee_le))
    AND (rapport_envoye_le IS NULL OR rapport_envoye)
  )
);

CREATE INDEX controle_missions_controller_cycle_idx
  ON private.controle_missions (controleur_id, cycle_debut, affectee_le DESC);
CREATE INDEX controle_missions_deadline_idx
  ON private.controle_missions (echeance, statut)
  WHERE statut IN ('attribuee', 'en_cours');
CREATE UNIQUE INDEX controle_missions_one_open_per_class_uidx
  ON private.controle_missions (groupe_id)
  WHERE statut IN ('attribuee', 'en_cours');

CREATE TABLE private.controle_mission_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mission_id uuid NOT NULL REFERENCES private.controle_missions(id) ON DELETE RESTRICT,
  evenement text NOT NULL CHECK (evenement IN (
    'attribuee', 'debut', 'controlee', 'non_controlee', 'deja_controlee'
  )),
  acteur_id uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(payload) = 'object')
);
CREATE INDEX controle_mission_journal_mission_idx
  ON private.controle_mission_journal (mission_id, cree_le, id);

ALTER TABLE private.controle_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.controle_mission_journal ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.controle_missions, private.controle_mission_journal
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION private.c29_refuser_modification_journal_mission()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'journal des missions append-only' USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION private.c29_refuser_modification_journal_mission()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER controle_mission_journal_append_only
  BEFORE UPDATE OR DELETE ON private.controle_mission_journal
  FOR EACH ROW EXECUTE FUNCTION private.c29_refuser_modification_journal_mission();

CREATE FUNCTION private.c29_journaliser_transition_mission()
RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $function$
DECLARE v_evenement text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_evenement := NEW.statut;
  ELSIF OLD.statut IS DISTINCT FROM NEW.statut THEN
    v_evenement := CASE NEW.statut
      WHEN 'en_cours' THEN 'debut'
      ELSE NEW.statut
    END;
  ELSE
    RETURN NEW;
  END IF;
  INSERT INTO private.controle_mission_journal
    (mission_id, evenement, acteur_id, payload)
  VALUES (
    NEW.id, v_evenement, auth.uid(),
    pg_catalog.jsonb_build_object(
      'session_id', NEW.session_id,
      'groupe_id', NEW.groupe_id,
      'controleur_id', NEW.controleur_id,
      'version_regles', NEW.version_regles,
      'cycle_debut', NEW.cycle_debut,
      'critere', NEW.critere,
      'rapport_envoye', NEW.rapport_envoye
    )
  );
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.c29_journaliser_transition_mission()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER controle_missions_journal_transition
  AFTER INSERT OR UPDATE ON private.controle_missions
  FOR EACH ROW EXECUTE FUNCTION private.c29_journaliser_transition_mission();

ALTER TABLE public.notifications
  DROP CONSTRAINT notifications_evenement_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
    'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
    'remplacement_propose', 'remplacement_pris',
    'controle_mission_attribuee', 'controle_mission_non_controlee'
  ));
ALTER TABLE public.notifications
  DROP CONSTRAINT notifications_destination_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_destination_check CHECK (destination IN (
    '/tuteur/demandes', '/enseignant/journee/remplacements', '/controleur',
    '/admin/securite-audit/tirages'
  ));
CREATE UNIQUE INDEX notifications_c29_mission_once_uidx
  ON public.notifications (
    destinataire, evenement, ((params ->> 'mission_id'))
  )
  WHERE evenement IN ('controle_mission_attribuee', 'controle_mission_non_controlee');

-- Assignment runs inside the session state transition, so simultaneous
-- controllers cannot claim the same class. A controller sees only own tasks.
CREATE FUNCTION private.c29_attribuer_mission_controle()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_effectif uuid;
  v_regle public.controle_regles%ROWTYPE;
  v_controller uuid;
  v_cycle date;
  v_critere text := 'aleatoire';
BEGIN
  IF NEW.status <> 'in_progress' OR OLD.status = 'in_progress'
     OR NEW.groupe_id IS NULL OR NEW.deleted_at IS NOT NULL THEN
    RETURN NEW;
  END IF;
  IF EXISTS (SELECT 1 FROM private.controle_missions m WHERE m.session_id = NEW.id) THEN
    RETURN NEW;
  END IF;
  SELECT r.* INTO v_regle FROM public.controle_regles r ORDER BY r.version DESC LIMIT 1;
  IF NOT FOUND OR v_regle.missions_par_semaine = 0 THEN RETURN NEW; END IF;
  v_effectif := private.c29_enseignant_effectif_session(NEW.id);
  IF v_effectif IS NULL THEN RETURN NEW; END IF;
  v_cycle := (pg_catalog.date_trunc('week', pg_catalog.clock_timestamp() AT TIME ZONE 'UTC'))::date;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('controle-groupe:' || NEW.groupe_id::text, 0)
  );
  IF EXISTS (SELECT 1 FROM private.controle_missions m
              WHERE m.groupe_id = NEW.groupe_id AND m.statut IN ('attribuee','en_cours')) THEN
    INSERT INTO private.controle_missions
      (session_id,groupe_id,enseignant_effectif_id,controleur_id,version_regles,
       cycle_debut,critere,echeance,statut)
    VALUES (NEW.id,NEW.groupe_id,v_effectif,NULL,v_regle.version,v_cycle,
       'aleatoire',NEW.ended_at,'deja_controlee');
    RETURN NEW;
  END IF;
  SELECT c.profile_id INTO v_controller
    FROM private.controle_capacites c
    JOIN public.profiles p ON p.id = c.profile_id
   WHERE c.revoked_at IS NULL AND c.active_from <= pg_catalog.clock_timestamp()
     AND c.expires_at > pg_catalog.clock_timestamp()
     AND p.role = 'controller' AND p.account_status = 'active'
     AND p.deleted_at IS NULL AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp())
     AND c.profile_id <> v_effectif
     AND (c.scope_all_groups OR NEW.groupe_id = ANY(c.scope_group_ids)
          OR v_effectif = ANY(c.scope_teacher_ids))
     AND NOT EXISTS (
       SELECT 1 FROM private.controle_missions own
        WHERE own.controleur_id = c.profile_id AND own.cycle_debut = v_cycle
        GROUP BY own.controleur_id HAVING count(*) >= v_regle.missions_par_semaine
     )
   ORDER BY pg_catalog.random(), c.profile_id
   LIMIT 1 FOR UPDATE OF c SKIP LOCKED;
  IF v_controller IS NULL THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM public.controle_regles_cibles c
      WHERE c.version = v_regle.version AND
        ((c.type = 'classe' AND c.cible_id = NEW.groupe_id)
         OR (c.type = 'enseignant' AND c.cible_id = v_effectif))) THEN
    v_critere := 'cible';
  ELSIF EXISTS (SELECT 1 FROM public.student_concern sc
      WHERE sc.groupe_id = NEW.groupe_id AND sc.statut = 'transmis')
      OR (NEW.started_at AT TIME ZONE 'UTC')::time >= TIME '17:00' THEN
    v_critere := 'ponderation';
  END IF;
  INSERT INTO private.controle_missions
    (session_id,groupe_id,enseignant_effectif_id,controleur_id,version_regles,
     cycle_debut,critere,echeance,statut)
  VALUES (NEW.id,NEW.groupe_id,v_effectif,v_controller,v_regle.version,v_cycle,
     v_critere,NEW.ended_at,'attribuee');
  INSERT INTO public.notifications(destinataire,evenement,params,destination)
  VALUES (v_controller,'controle_mission_attribuee',
    pg_catalog.jsonb_build_object('mission_id',(SELECT id FROM private.controle_missions WHERE session_id=NEW.id)),
    '/controleur');
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.c29_attribuer_mission_controle() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.c29_attribuer_mission_controle()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.c29_attribuer_mission_controle() IS
  'F86 candidate allowlist: signature=private.c29_attribuer_mission_controle(); md5_functiondef=A_CALCULER; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';
CREATE TRIGGER c29_attribuer_mission_controle
  AFTER UPDATE OF status ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION private.c29_attribuer_mission_controle();

CREATE FUNCTION public.demarrer_mission_controle(p_mission_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_mission private.controle_missions%ROWTYPE;
BEGIN
  SELECT * INTO v_mission FROM private.controle_missions
   WHERE id=p_mission_id AND controleur_id=auth.uid() FOR UPDATE;
  IF NOT FOUND OR NOT coalesce(public.app_account_valid()
      AND public.app_role()='controller'
      AND EXISTS (SELECT 1 FROM private.controle_capacites c
        WHERE c.profile_id=auth.uid() AND c.revoked_at IS NULL
          AND c.active_from <= pg_catalog.clock_timestamp()
          AND c.expires_at > pg_catalog.clock_timestamp()
          AND (c.scope_all_groups OR v_mission.groupe_id=ANY(c.scope_group_ids)
               OR v_mission.enseignant_effectif_id=ANY(c.scope_teacher_ids))),false) THEN
    RAISE EXCEPTION 'mission indisponible' USING ERRCODE='42501';
  END IF;
  IF v_mission.statut <> 'attribuee' OR v_mission.echeance <= pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'mission expiree ou deja commencee' USING ERRCODE='55000';
  END IF;
  UPDATE private.controle_missions SET statut='en_cours', commencee_le=pg_catalog.clock_timestamp()
   WHERE id=p_mission_id;
  INSERT INTO public.session_participants(session_id,profile_id,role,entered_at)
  VALUES(v_mission.session_id,auth.uid(),'masked_controller',pg_catalog.clock_timestamp())
  ON CONFLICT(session_id,profile_id) DO UPDATE SET deleted_at=NULL, entered_at=excluded.entered_at;
  RETURN pg_catalog.jsonb_build_object('statut','en_cours');
END;
$function$;
ALTER FUNCTION public.demarrer_mission_controle(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.demarrer_mission_controle(uuid)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demarrer_mission_controle(uuid) TO authenticated;
COMMENT ON FUNCTION public.demarrer_mission_controle(uuid) IS
  'F86 candidate allowlist: signature=public.demarrer_mission_controle(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION private.c29_clore_mission_controle()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_mission private.controle_missions%ROWTYPE; v_statut text;
BEGIN
  IF NEW.status <> 'ended' OR OLD.status = 'ended' THEN RETURN NEW; END IF;
  SELECT * INTO v_mission FROM private.controle_missions WHERE session_id=NEW.id FOR UPDATE;
  IF NOT FOUND OR v_mission.statut NOT IN ('attribuee','en_cours') THEN RETURN NEW; END IF;
  v_statut := CASE WHEN v_mission.statut='en_cours' THEN 'controlee' ELSE 'non_controlee' END;
  UPDATE private.controle_missions SET statut=v_statut, terminee_le=pg_catalog.clock_timestamp()
   WHERE id=v_mission.id;
  IF v_statut='non_controlee' THEN
    INSERT INTO public.notifications(destinataire,evenement,params,destination)
    SELECT p.id,'controle_mission_non_controlee',
      pg_catalog.jsonb_build_object('mission_id',v_mission.id),'/admin/securite-audit/tirages'
    FROM public.profiles p
    WHERE p.role='admin' AND p.account_status='active' AND p.deleted_at IS NULL;
    UPDATE private.controle_missions SET rapport_envoye=true,
      rapport_envoye_le=pg_catalog.clock_timestamp() WHERE id=v_mission.id;
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.c29_clore_mission_controle() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.c29_clore_mission_controle()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.c29_clore_mission_controle() IS
  'F86 candidate allowlist: signature=private.c29_clore_mission_controle(); md5_functiondef=A_CALCULER; guard_type=INTERNAL_TRIGGER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';
CREATE TRIGGER c29_clore_mission_controle
  AFTER UPDATE OF status ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION private.c29_clore_mission_controle();

CREATE FUNCTION public.ma_mission_controle()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce((SELECT pg_catalog.jsonb_build_object(
    'id',m.id,'session_id',m.session_id,'groupe_id',m.groupe_id,
    'enseignant_effectif_id',m.enseignant_effectif_id,'echeance',m.echeance,
    'statut',m.statut,'commencee_le',m.commencee_le)
    FROM private.controle_missions m
    JOIN private.controle_capacites c ON c.profile_id=m.controleur_id
    WHERE m.controleur_id=auth.uid() AND m.statut IN ('attribuee','en_cours')
      AND c.revoked_at IS NULL AND c.active_from <= pg_catalog.clock_timestamp()
      AND c.expires_at > pg_catalog.clock_timestamp()
      AND (c.scope_all_groups OR m.groupe_id=ANY(c.scope_group_ids)
           OR m.enseignant_effectif_id=ANY(c.scope_teacher_ids))
      AND public.app_account_valid() AND public.app_role()='controller'
    ORDER BY m.affectee_le DESC LIMIT 1),'{}'::jsonb);
$function$;
ALTER FUNCTION public.ma_mission_controle() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.ma_mission_controle()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.ma_mission_controle() TO authenticated;
COMMENT ON FUNCTION public.ma_mission_controle() IS
  'F86 candidate allowlist: signature=public.ma_mission_controle(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

CREATE FUNCTION public.historique_tirages(
  p_statut text DEFAULT NULL, p_texte text DEFAULT '', p_page integer DEFAULT 1,
  p_taille integer DEFAULT 25
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE v_total integer; v_all integer; v_page integer; v_counts jsonb; v_rows jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role()='admin'
     AND EXISTS(SELECT 1 FROM public.profiles p WHERE p.id=auth.uid()
       AND p.role='admin' AND p.account_status='active' AND p.deleted_at IS NULL),false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE='42501';
  END IF;
  IF p_page IS NULL OR p_page < 1 OR p_taille IS NULL OR p_taille NOT BETWEEN 1 AND 100
     OR (p_statut IS NOT NULL AND p_statut NOT IN
       ('attribuee','en_cours','controlee','non_controlee','deja_controlee')) THEN
    RAISE EXCEPTION 'parametres de pagination invalides' USING ERRCODE='22023';
  END IF;
  SELECT count(*) INTO v_all FROM private.controle_missions;
  SELECT count(*) INTO v_total FROM private.controle_missions m
   JOIN public.groupes g ON g.id=m.groupe_id
   JOIN public.profiles t ON t.id=m.enseignant_effectif_id
   LEFT JOIN public.profiles c ON c.id=m.controleur_id
   WHERE (p_statut IS NULL OR m.statut=p_statut)
     AND (coalesce(p_texte,'')='' OR pg_catalog.concat_ws(' ',g.libelle,t.first_name,t.last_name,c.first_name,c.last_name)
       ILIKE '%'||p_texte||'%');
  v_page := least(p_page,greatest(1,pg_catalog.ceil(v_total::numeric/p_taille)::integer));
  SELECT coalesce(pg_catalog.jsonb_object_agg(x.statut,x.n),'{}'::jsonb) INTO v_counts
   FROM (SELECT m.statut,count(*) n FROM private.controle_missions m
     JOIN public.groupes g ON g.id=m.groupe_id
     JOIN public.profiles t ON t.id=m.enseignant_effectif_id
     LEFT JOIN public.profiles c ON c.id=m.controleur_id
     WHERE coalesce(p_texte,'')='' OR pg_catalog.concat_ws(' ',g.libelle,t.first_name,t.last_name,c.first_name,c.last_name)
       ILIKE '%'||p_texte||'%' GROUP BY m.statut) x;
  SELECT coalesce(pg_catalog.jsonb_agg(x.row ORDER BY x.affectee_le DESC,x.id),'[]'::jsonb)
    INTO v_rows FROM (
      SELECT m.id,m.affectee_le,pg_catalog.jsonb_build_object(
        'id',m.id,'quand',m.affectee_le,'classe',g.libelle,
        'enseignant',pg_catalog.concat_ws(' ',t.first_name,t.last_name),
        'controleur',coalesce(pg_catalog.concat_ws(' ',c.first_name,c.last_name),''),
        'statut',m.statut,'critere',m.critere,'rapport_envoye',m.rapport_envoye) row
      FROM private.controle_missions m JOIN public.groupes g ON g.id=m.groupe_id
      JOIN public.profiles t ON t.id=m.enseignant_effectif_id
      LEFT JOIN public.profiles c ON c.id=m.controleur_id
      WHERE (p_statut IS NULL OR m.statut=p_statut)
        AND (coalesce(p_texte,'')='' OR pg_catalog.concat_ws(' ',g.libelle,t.first_name,t.last_name,c.first_name,c.last_name)
          ILIKE '%'||p_texte||'%')
      ORDER BY m.affectee_le DESC,m.id LIMIT p_taille OFFSET (v_page-1)*p_taille
    ) x;
  RETURN pg_catalog.jsonb_build_object('lignes',v_rows,'total',v_total,'page',v_page,
    'taille',p_taille,'total_sans_filtre',v_all,'compteurs',coalesce(v_counts,'{}'::jsonb));
END;
$function$;
ALTER FUNCTION public.historique_tirages(text,text,integer,integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.historique_tirages(text,text,integer,integer)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.historique_tirages(text,text,integer,integer) TO authenticated;
COMMENT ON FUNCTION public.historique_tirages(text,text,integer,integer) IS
  'F86 candidate allowlist: signature=public.historique_tirages(text,text,integer,integer); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-11.';

COMMIT;
