BEGIN;

CREATE TABLE public.mission_fils (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  mission_id uuid NOT NULL UNIQUE REFERENCES private.controle_missions(id) ON DELETE RESTRICT,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);

CREATE TABLE public.mission_messages (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  fil_id uuid NOT NULL REFERENCES public.mission_fils(id) ON DELETE RESTRICT,
  auteur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  cle_client uuid NOT NULL,
  texte text NOT NULL CHECK (pg_catalog.btrim(texte) <> '' AND pg_catalog.length(texte) <= 5000),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  UNIQUE (fil_id, auteur_id, cle_client)
);
CREATE INDEX mission_messages_fil_date_idx ON public.mission_messages(fil_id, cree_le, id);

CREATE TABLE public.rapports_mission (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  mission_id uuid NOT NULL UNIQUE REFERENCES private.controle_missions(id) ON DELETE RESTRICT,
  session_id uuid NOT NULL REFERENCES public.sessions(id) ON DELETE RESTRICT,
  controleur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  classe text NOT NULL,
  enseignant text NOT NULL,
  debut timestamptz NOT NULL,
  duree_observee_secondes integer NOT NULL CHECK (duree_observee_secondes >= 0),
  faits jsonb CHECK (faits IS NULL OR pg_catalog.jsonb_typeof(faits) = 'object'),
  presents text[] NOT NULL DEFAULT '{}',
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);

CREATE TABLE public.rapport_complements (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  rapport_id uuid NOT NULL REFERENCES public.rapports_mission(id) ON DELETE RESTRICT,
  auteur_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  texte text NOT NULL CHECK (pg_catalog.btrim(texte) <> '' AND pg_catalog.length(texte) <= 5000),
  motif text CHECK (motif IS NULL OR pg_catalog.length(motif) <= 1000),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX rapport_complements_parent_date_idx ON public.rapport_complements(rapport_id, cree_le, id);

ALTER TABLE public.mission_fils ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rapports_mission ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rapport_complements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.mission_fils, public.mission_messages,
  public.rapports_mission, public.rapport_complements
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION private.b12_mission_autorisee(p_mission_id uuid, p_direction boolean DEFAULT true)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(public.app_account_valid() AND (
    (p_direction AND public.app_role() = 'admin')
    OR EXISTS (
      SELECT 1 FROM private.controle_missions m
      JOIN private.controle_capacites c ON c.profile_id = m.controleur_id
      JOIN public.profiles p ON p.id = m.controleur_id
      WHERE m.id = p_mission_id AND m.controleur_id = auth.uid()
        AND c.revoked_at IS NULL
        AND c.active_from <= pg_catalog.clock_timestamp()
        AND c.expires_at > pg_catalog.clock_timestamp()
        AND (c.scope_all_groups OR m.groupe_id = ANY(c.scope_group_ids)
             OR m.enseignant_effectif_id = ANY(c.scope_teacher_ids))
        AND p.role = 'controller'
        AND p.account_status = 'active' AND p.deleted_at IS NULL
        AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp())
    )), false);
$function$;
REVOKE ALL ON FUNCTION private.b12_mission_autorisee(uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION private.b12_creer_fil_mission()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
BEGIN
  IF NEW.controleur_id IS NOT NULL THEN
    INSERT INTO public.mission_fils(mission_id) VALUES (NEW.id) ON CONFLICT (mission_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.b12_creer_fil_mission()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER b12_fil_a_affectation
  AFTER INSERT ON private.controle_missions
  FOR EACH ROW EXECUTE FUNCTION private.b12_creer_fil_mission();

INSERT INTO public.mission_fils(mission_id)
  SELECT m.id FROM private.controle_missions m WHERE m.controleur_id IS NOT NULL
  ON CONFLICT (mission_id) DO NOTHING;

CREATE FUNCTION private.b12_creer_rapport_fin_mission()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
DECLARE
  v_session public.sessions%ROWTYPE;
  v_classe text;
  v_enseignant text;
  v_debut_reel timestamptz;
  v_attendus integer;
  v_presents integer;
  v_reconnexions integer;
  v_liste_presents text[];
  v_faits jsonb;
BEGIN
  IF NEW.statut NOT IN ('controlee','non_controlee')
     OR OLD.statut IS NOT DISTINCT FROM NEW.statut
     OR NEW.controleur_id IS NULL THEN RETURN NEW; END IF;
  SELECT * INTO v_session FROM public.sessions s WHERE s.id=NEW.session_id;
  SELECT g.libelle INTO v_classe FROM public.groupes g WHERE g.id=NEW.groupe_id;
  SELECT pg_catalog.concat_ws(' ',p.first_name,p.last_name) INTO v_enseignant
    FROM public.profiles p WHERE p.id=NEW.enseignant_effectif_id;
  SELECT min(e.server_ts) INTO v_debut_reel FROM public.session_events e
    WHERE e.session_id=NEW.session_id AND e.event_type='joined';
  SELECT count(*) FILTER (WHERE sp.role='student'),
         count(*) FILTER (WHERE sp.role='student' AND sp.entered_at IS NOT NULL)
    INTO v_attendus,v_presents FROM public.session_participants sp
    WHERE sp.session_id=NEW.session_id AND sp.deleted_at IS NULL;
  SELECT greatest(count(*)-count(DISTINCT e.profile_id),0)::integer
    INTO v_reconnexions FROM public.session_events e
    WHERE e.session_id=NEW.session_id AND e.event_type='joined' AND e.profile_id IS NOT NULL;
  SELECT coalesce(pg_catalog.array_agg(pg_catalog.concat_ws(' ',p.first_name,
      CASE WHEN pg_catalog.btrim(coalesce(p.last_name,''))='' THEN NULL
           ELSE pg_catalog.upper(pg_catalog.left(pg_catalog.btrim(p.last_name),1))||'.' END)
      ORDER BY sp.entered_at,sp.profile_id),'{}'::text[])
    INTO v_liste_presents FROM public.session_participants sp
    JOIN public.profiles p ON p.id=sp.profile_id
    WHERE sp.session_id=NEW.session_id AND sp.role='student'
      AND sp.deleted_at IS NULL AND sp.entered_at IS NOT NULL;
  IF v_debut_reel IS NOT NULL THEN
    v_faits := pg_catalog.jsonb_build_object(
      'debut_prevu',v_session.started_at,'fin_prevue',v_session.ended_at,
      'debut_reel',v_debut_reel,'fin_reelle',v_session.ended_at,
      'participants_attendus',coalesce(v_attendus,0),
      'participants_presents',coalesce(v_presents,0),
      'reconnexions',coalesce(v_reconnexions,0));
  END IF;
  INSERT INTO public.rapports_mission
    (mission_id,session_id,controleur_id,classe,enseignant,debut,
     duree_observee_secondes,faits,presents)
  VALUES (NEW.id,NEW.session_id,NEW.controleur_id,coalesce(v_classe,''),
    coalesce(v_enseignant,''),v_session.started_at,
    CASE WHEN NEW.commencee_le IS NULL THEN 0 ELSE greatest(
      extract(epoch FROM (coalesce(NEW.terminee_le,pg_catalog.clock_timestamp())-NEW.commencee_le)::interval)::integer,0) END,
    v_faits,coalesce(v_liste_presents,'{}'::text[]))
  ON CONFLICT (mission_id) DO NOTHING;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.b12_creer_rapport_fin_mission()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER b12_rapport_fin_mission
  AFTER UPDATE OF statut ON private.controle_missions
  FOR EACH ROW EXECUTE FUNCTION private.b12_creer_rapport_fin_mission();

CREATE FUNCTION private.b12_refuser_mutation_append_only()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $function$
BEGIN
  RAISE EXCEPTION 'historique B-12 append-only' USING ERRCODE = '55000';
END;
$function$;
REVOKE ALL ON FUNCTION private.b12_refuser_mutation_append_only()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER mission_messages_append_only BEFORE UPDATE OR DELETE ON public.mission_messages
  FOR EACH ROW EXECUTE FUNCTION private.b12_refuser_mutation_append_only();
CREATE TRIGGER rapports_mission_append_only BEFORE UPDATE OR DELETE ON public.rapports_mission
  FOR EACH ROW EXECUTE FUNCTION private.b12_refuser_mutation_append_only();
CREATE TRIGGER rapport_complements_append_only BEFORE UPDATE OR DELETE ON public.rapport_complements
  FOR EACH ROW EXECUTE FUNCTION private.b12_refuser_mutation_append_only();

CREATE FUNCTION public.controleur_lister_fils()
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_resultat jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND (
    public.app_role() = 'admin' OR EXISTS (
      SELECT 1 FROM private.controle_capacites c JOIN public.profiles p ON p.id=c.profile_id
      WHERE c.profile_id=auth.uid() AND c.revoked_at IS NULL
        AND c.active_from<=pg_catalog.clock_timestamp() AND c.expires_at>pg_catalog.clock_timestamp()
        AND p.role = 'controller' AND p.account_status='active'
        AND p.deleted_at IS NULL AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp())
    )), false) THEN RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501'; END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(x.fil ORDER BY x.activite DESC), '[]'::jsonb)
    INTO v_resultat FROM (
      SELECT pg_catalog.jsonb_build_object(
        'id',f.id,'mission_id',m.id,'classe',g.libelle,'debut_mission',s.started_at,
        'etat',CASE WHEN last_message.auteur_id IS NOT NULL
                         AND last_message.auteur_id IS DISTINCT FROM auth.uid()
                    THEN 'reponse_recue' ELSE 'en_attente' END,
        'messages',coalesce(msg.liste,'[]'::jsonb)
      ) AS fil, coalesce(last_message.cree_le,f.cree_le) AS activite
      FROM public.mission_fils f
      JOIN private.controle_missions m ON m.id=f.mission_id
      JOIN public.groupes g ON g.id=m.groupe_id
      JOIN public.sessions s ON s.id=m.session_id
      LEFT JOIN LATERAL (
        SELECT mm.auteur_id,mm.cree_le FROM public.mission_messages mm
        WHERE mm.fil_id=f.id ORDER BY mm.cree_le DESC,mm.id DESC LIMIT 1
      ) last_message ON true
      LEFT JOIN LATERAL (
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
          'id',mm.id,'auteur',CASE WHEN mm.auteur_id=m.controleur_id THEN 'controleur' ELSE 'administration' END,
          'texte',mm.texte,'date',mm.cree_le) ORDER BY mm.cree_le,mm.id) AS liste
        FROM public.mission_messages mm WHERE mm.fil_id=f.id
      ) msg ON true
      WHERE private.b12_mission_autorisee(m.id,true)
    ) x;
  PERFORM public.log_sensitive_access('b12_lire_fils','mission_fils',auth.uid()::text,'{}'::jsonb);
  RETURN v_resultat;
END;
$function$;

CREATE FUNCTION public.controleur_fil_de_mission(p_mission_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_result jsonb;
BEGIN
  IF p_mission_id IS NULL OR NOT private.b12_mission_autorisee(p_mission_id,true) THEN
    RAISE EXCEPTION 'B12 mission indisponible' USING ERRCODE='42501';
  END IF;
  INSERT INTO public.mission_fils(mission_id) VALUES (p_mission_id) ON CONFLICT (mission_id) DO NOTHING;
  SELECT pg_catalog.jsonb_build_object(
    'id',f.id,'mission_id',m.id,'classe',g.libelle,'debut_mission',s.started_at,
    'etat',CASE WHEN last_message.auteur_id IS NOT NULL
                     AND last_message.auteur_id IS DISTINCT FROM auth.uid()
                THEN 'reponse_recue' ELSE 'en_attente' END,
    'messages',coalesce(msg.liste,'[]'::jsonb)
  ) INTO v_result
  FROM public.mission_fils f JOIN private.controle_missions m ON m.id=f.mission_id
  JOIN public.groupes g ON g.id=m.groupe_id JOIN public.sessions s ON s.id=m.session_id
  LEFT JOIN LATERAL (SELECT mm.auteur_id FROM public.mission_messages mm WHERE mm.fil_id=f.id
    ORDER BY mm.cree_le DESC,mm.id DESC LIMIT 1) last_message ON true
  LEFT JOIN LATERAL (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id',mm.id,'auteur',CASE WHEN mm.auteur_id=m.controleur_id THEN 'controleur' ELSE 'administration' END,
    'texte',mm.texte,'date',mm.cree_le) ORDER BY mm.cree_le,mm.id) AS liste
    FROM public.mission_messages mm WHERE mm.fil_id=f.id) msg ON true
  WHERE m.id=p_mission_id;
  PERFORM public.log_sensitive_access('b12_lire_fil','mission_fils',p_mission_id::text,'{}'::jsonb);
  RETURN v_result;
END;
$function$;

CREATE FUNCTION public.controleur_envoyer_message(p_fil_id uuid,p_cle_client uuid,p_texte text)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_mission_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND auth.uid() IS NOT NULL
      AND public.app_role() IN ('admin','controller'),false) THEN
    RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501';
  END IF;
  IF p_fil_id IS NULL OR p_cle_client IS NULL OR p_texte IS NULL
     OR pg_catalog.btrim(p_texte)='' OR pg_catalog.length(p_texte)>5000 THEN
    RAISE EXCEPTION 'B12 message invalide' USING ERRCODE='22023';
  END IF;
  SELECT m.id INTO v_mission_id FROM public.mission_fils f
    JOIN private.controle_missions m ON m.id=f.mission_id WHERE f.id=p_fil_id;
  IF v_mission_id IS NULL OR NOT private.b12_mission_autorisee(v_mission_id,true) THEN
    RAISE EXCEPTION 'B12 fil indisponible' USING ERRCODE='42501';
  END IF;
  INSERT INTO public.mission_messages(fil_id,auteur_id,cle_client,texte)
    VALUES(p_fil_id,auth.uid(),p_cle_client,pg_catalog.btrim(p_texte))
    ON CONFLICT(fil_id,auteur_id,cle_client) DO NOTHING;
  PERFORM public.log_sensitive_access('b12_envoyer_message','mission_messages',p_fil_id::text,'{}'::jsonb);
END;
$function$;

CREATE FUNCTION public.controleur_lister_rapports()
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_result jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND (
    public.app_role()='admin' OR EXISTS(SELECT 1 FROM private.controle_capacites c
      JOIN public.profiles p ON p.id=c.profile_id WHERE c.profile_id=auth.uid()
        AND c.revoked_at IS NULL AND c.active_from<=pg_catalog.clock_timestamp()
        AND c.expires_at>pg_catalog.clock_timestamp() AND p.role='controller'
        AND p.account_status='active' AND p.deleted_at IS NULL
        AND (p.access_until IS NULL OR p.access_until>pg_catalog.clock_timestamp()))),false) THEN
    RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id',r.id,'mission_id',r.mission_id,'seance_id',r.session_id,'classe',r.classe,
    'enseignant',r.enseignant,'debut',r.debut,'duree_observee_secondes',r.duree_observee_secondes,
    'statut',CASE WHEN c.id IS NOT NULL THEN 'complement_ajoute'
                  WHEN m.rapport_envoye THEN 'envoye' ELSE 'a_terminer' END,
    'faits',r.faits,'choix',null,'observation',null,'eleve',null,
    'presents',to_jsonb(r.presents),
    'complements',coalesce(cpl.liste,'[]'::jsonb)
  ) ORDER BY r.debut DESC), '[]'::jsonb) INTO v_result
  FROM public.rapports_mission r
  JOIN private.controle_missions m ON m.id=r.mission_id
  LEFT JOIN LATERAL (SELECT c.id FROM public.rapport_complements c WHERE c.rapport_id=r.id
    ORDER BY c.cree_le DESC,c.id DESC LIMIT 1) c ON true
  LEFT JOIN LATERAL (SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'date',c.cree_le,'texte',c.texte,'motif',c.motif,
    'auteur',CASE WHEN c.auteur_id=auth.uid() THEN null ELSE 'Administration' END
  ) ORDER BY c.cree_le,c.id) AS liste FROM public.rapport_complements c WHERE c.rapport_id=r.id) cpl ON true
  WHERE (r.controleur_id=auth.uid() OR public.app_role()='admin')
    AND private.b12_mission_autorisee(r.mission_id,true);
  PERFORM public.log_sensitive_access('b12_lire_rapports','rapports_mission',auth.uid()::text,'{}'::jsonb);
  RETURN v_result;
END;
$function$;

CREATE FUNCTION public.controleur_ajouter_complement(p_rapport_id uuid,p_texte text,p_motif text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE v_report public.rapports_mission%ROWTYPE; v_id uuid; v_at timestamptz;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'controller',false) THEN
    RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501';
  END IF;
  IF p_rapport_id IS NULL OR p_texte IS NULL OR pg_catalog.btrim(p_texte)=''
     OR pg_catalog.length(p_texte)>5000 OR pg_catalog.length(coalesce(p_motif,''))>1000 THEN
    RAISE EXCEPTION 'B12 complement invalide' USING ERRCODE='22023';
  END IF;
  SELECT * INTO v_report FROM public.rapports_mission r
    WHERE r.id=p_rapport_id AND r.controleur_id=auth.uid() FOR UPDATE;
  IF NOT FOUND OR NOT private.b12_mission_autorisee(v_report.mission_id,false) THEN
    RAISE EXCEPTION 'B12 rapport indisponible' USING ERRCODE='42501';
  END IF;
  INSERT INTO public.rapport_complements(rapport_id,auteur_id,texte,motif)
    VALUES(p_rapport_id,auth.uid(),pg_catalog.btrim(p_texte),nullif(pg_catalog.btrim(p_motif),''))
    RETURNING id,cree_le INTO v_id,v_at;
  PERFORM public.log_sensitive_access('b12_ajouter_complement','rapport_complements',p_rapport_id::text,'{}'::jsonb);
  RETURN pg_catalog.jsonb_build_object('id',v_id,'date',v_at,'texte',pg_catalog.btrim(p_texte),
    'motif',nullif(pg_catalog.btrim(p_motif),''),'auteur',null);
END;
$function$;

DO $f86$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.controleur_lister_fils()',
    'public.controleur_fil_de_mission(uuid)',
    'public.controleur_envoyer_message(uuid,uuid,text)',
    'public.controleur_lister_rapports()',
    'public.controleur_ajouter_complement(uuid,text,text)'
  ] LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$f86$;

COMMENT ON FUNCTION public.controleur_lister_fils() IS
 'F86 candidate allowlist: signature=public.controleur_lister_fils(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: anon, autre contrôleur, compte inactif refusés; DTO sans contacts ni KYC.';
COMMENT ON FUNCTION public.controleur_fil_de_mission(uuid) IS
 'F86 candidate allowlist: signature=public.controleur_fil_de_mission(uuid); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: mission hors périmètre refusée; fil canonique idempotent.';
COMMENT ON FUNCTION public.controleur_envoyer_message(uuid,uuid,text) IS
 'F86 candidate allowlist: signature=public.controleur_envoyer_message(uuid,uuid,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: refus rôle non autorisé et message vide; clé client idempotente.';
COMMENT ON FUNCTION public.controleur_lister_rapports() IS
 'F86 candidate allowlist: signature=public.controleur_lister_rapports(); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: contrôleur ne lit que ses rapports, Direction active lit tout; aucune donnée contact/KYC.';
COMMENT ON FUNCTION public.controleur_ajouter_complement(uuid,text,text) IS
 'F86 candidate allowlist: signature=public.controleur_ajouter_complement(uuid,text,text); md5_functiondef=A_CALCULER; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-12. Must-pass: autre auteur refusé; rapport parent immuable; complément ajouté.';

DO $postflight$
BEGIN
  IF (SELECT count(*) FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='public' AND c.relname IN ('mission_fils','mission_messages','rapports_mission','rapport_complements')
        AND c.relrowsecurity) <> 4
     OR has_table_privilege('authenticated','public.mission_messages','SELECT')
     OR has_table_privilege('authenticated','public.mission_fils','SELECT')
     OR has_table_privilege('authenticated','public.rapports_mission','SELECT')
     OR has_table_privilege('authenticated','public.rapport_complements','SELECT')
     OR (SELECT count(*) FROM pg_catalog.pg_proc p WHERE p.oid IN (
       'public.controleur_lister_fils()'::regprocedure,
       'public.controleur_fil_de_mission(uuid)'::regprocedure,
       'public.controleur_envoyer_message(uuid,uuid,text)'::regprocedure,
       'public.controleur_lister_rapports()'::regprocedure,
       'public.controleur_ajouter_complement(uuid,text,text)'::regprocedure
     ) AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
       AND pg_catalog.obj_description(p.oid,'pg_proc') LIKE '%md5_functiondef=A_CALCULER%') <> 5 THEN
    RAISE EXCEPTION 'B12 schema, ACL, RLS ou allowlist F86 invalide';
  END IF;
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.controleur_lister_fils()'::regprocedure),
      ('public.controleur_fil_de_mission(uuid)'::regprocedure),
      ('public.controleur_envoyer_message(uuid,uuid,text)'::regprocedure),
      ('public.controleur_lister_rapports()'::regprocedure),
      ('public.controleur_ajouter_complement(uuid,text,text)'::regprocedure)
    ) AS fonctions(oid)
    WHERE NOT pg_catalog.has_function_privilege('authenticated', oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'B12 RPC execute ACL invalid';
  END IF;
END;
$postflight$;

COMMIT;
