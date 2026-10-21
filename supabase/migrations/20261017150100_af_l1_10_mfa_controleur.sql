-- L1-10 : double vérification (TOTP, aal2) du contrôleur. Décision A-02, option 1,
-- directeur, 17/10/2026 01:47 : activer avant toute mission réelle.
--
-- Le claim `aal` est posé par Supabase Auth (jamais par custom_access_token_hook).
-- Un contrôleur connecté avec le seul mot de passe (aal1), ou qui a enrôlé un
-- facteur sans le vérifier à cette connexion, est refusé (42501) par chaque RPC
-- que le contrôleur appelle. L'administrateur n'est pas concerné ici : il a ses
-- propres gardes aal2 (capacités, règles, trésorerie).
-- Déjà aal2 pour tout rôle, donc inchangées : demarrer_mission_controle,
-- declarer_conflit_mission, ma_capacite_controle_active.
BEGIN;

CREATE OR REPLACE FUNCTION public.app_aal()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT nullif(auth.jwt() ->> 'aal', '');
$$;
ALTER FUNCTION public.app_aal() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.app_aal() FROM PUBLIC, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.app_aal() TO authenticated, anon;
COMMENT ON FUNCTION public.app_aal() IS
  'Niveau d assurance du jeton (aal1 ou aal2), pose par Supabase Auth ; null sans jeton.';

CREATE OR REPLACE FUNCTION public.rejoindre_observation(p_session_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_seance public.sessions%ROWTYPE;
  v_role public.participant_role;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'controller' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'observation reservee au controle qualite'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_seance
  FROM public.sessions s
  WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'seance introuvable' USING ERRCODE = 'no_data_found';
  END IF;

  IF v_seance.status IN ('ended', 'canceled', 'canceled_late') THEN
    RAISE EXCEPTION 'seance close' USING ERRCODE = 'check_violation';
  END IF;

  IF pg_catalog.now() < v_seance.started_at THEN
    RAISE EXCEPTION 'seance pas encore commencee' USING ERRCODE = 'check_violation';
  END IF;
  IF pg_catalog.now() > v_seance.ended_at + interval '15 minutes' THEN
    RAISE EXCEPTION 'seance terminee' USING ERRCODE = 'check_violation';
  END IF;

  SELECT sp.role INTO v_role
  FROM public.session_participants sp
  WHERE sp.session_id = p_session_id
    AND sp.profile_id = auth.uid()
    AND sp.deleted_at IS NULL;
  IF FOUND AND v_role <> 'masked_controller' THEN
    RAISE EXCEPTION 'observer une seance dont on est partie prenante est interdit'
      USING ERRCODE = 'check_violation';
  END IF;
  IF v_seance.teacher_id = auth.uid() THEN
    RAISE EXCEPTION 'observer une seance dont on est partie prenante est interdit'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.session_participants (session_id, profile_id, role)
  VALUES (p_session_id, auth.uid(), 'masked_controller')
  ON CONFLICT (session_id, profile_id) DO UPDATE
    SET deleted_at = NULL, role = 'masked_controller';

  PERFORM public.log_sensitive_access(
    'controller_observation_started',
    'session_participants',
    p_session_id::text,
    jsonb_build_object(
      'teacher_id', v_seance.teacher_id,
      'started_at', v_seance.started_at,
      'hidden', true
    )
  );

  RETURN p_session_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.controleur_fil_de_mission(p_mission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_result jsonb;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'B12 mission indisponible' USING ERRCODE='42501';
  END IF;
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
  END IF;
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

CREATE OR REPLACE FUNCTION public.controleur_lister_fils()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
  END IF;
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

CREATE OR REPLACE FUNCTION public.controleur_envoyer_message(p_fil_id uuid, p_cle_client uuid, p_texte text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_mission_id uuid;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND auth.uid() IS NOT NULL
      AND public.app_role() IN ('admin','controller'),false) THEN
    RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501';
  END IF;
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
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

CREATE OR REPLACE FUNCTION public.controleur_lister_rapports()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
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

CREATE OR REPLACE FUNCTION public.controleur_ajouter_complement(p_rapport_id uuid, p_texte text, p_motif text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_report public.rapports_mission%ROWTYPE; v_id uuid; v_at timestamptz;
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'controller',false) THEN
    RAISE EXCEPTION 'B12 non autorise' USING ERRCODE='42501';
  END IF;
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
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

CREATE OR REPLACE FUNCTION public.ma_mission_controle()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF public.app_role() = 'controller' AND coalesce(public.app_aal(), 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION 'seconde étape de connexion requise' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN coalesce((
      select pg_catalog.jsonb_build_object(
        'id', m.id,
        'session_id', m.session_id,
        'groupe_id', m.groupe_id,
        'enseignant_effectif_id', m.enseignant_effectif_id,
        'echeance', m.echeance,
        'statut', m.statut,
        'commencee_le', m.commencee_le
      )
        from private.controle_missions m
        join private.controle_capacites c on c.profile_id = m.controleur_id
        join public.profiles p on p.id = auth.uid()
       where m.controleur_id = auth.uid()
         and m.statut in ('attribuee', 'en_cours')
         and m.echeance > pg_catalog.statement_timestamp()
         and c.revoked_at is null
         and c.active_from <= pg_catalog.statement_timestamp()
         and c.expires_at > pg_catalog.statement_timestamp()
         and (c.scope_all_groups
              or m.groupe_id = any(c.scope_group_ids)
              or m.enseignant_effectif_id = any(c.scope_teacher_ids))
         and p.role = 'controller'
         and p.account_status = 'active'
         and p.deleted_at is null
         and (p.access_until is null or p.access_until > pg_catalog.statement_timestamp())
         and public.rech_session_autorisee()
         and public.app_account_valid()
         and public.app_role() = 'controller'
       order by m.affectee_le desc, m.id
       limit 1
    ), '{}'::jsonb);
END;
$function$;

DO $postflight$
DECLARE
  v_n integer;
BEGIN
  SELECT count(*) INTO v_n
  FROM pg_catalog.pg_proc p
  JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname IN ('rejoindre_observation','ma_mission_controle','controleur_fil_de_mission',
                      'controleur_lister_fils','controleur_envoyer_message',
                      'controleur_lister_rapports','controleur_ajouter_complement')
    AND p.prosecdef
    AND 'search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[]))
    AND pg_catalog.strpos(p.prosrc, 'app_aal()') > 0;
  IF v_n <> 7 THEN
    RAISE EXCEPTION 'L1-10 postflight : % fonctions gardees sur 7', v_n;
  END IF;
END;
$postflight$;

COMMIT;
