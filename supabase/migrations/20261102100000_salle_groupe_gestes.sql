-- Petits groupes en salle (consigne du pilote du 30/10/2026, audit des
-- groupes de 2 a 5 eleves). Trois manques cote serveur :
--
-- 1. Les gestes de l'enseignant sur un eleve (couper son micro, couper sa
--    camera, le faire sortir de la salle). La fonction Edge `salle-gestes`
--    appelle `public.autoriser_geste_salle` sous la cle de service : la base
--    verifie que l'appelant est l'enseignant EFFECTIF de CETTE seance (meme
--    regle que `autoriser_jeton_video`, 20261017110100), que la cible est un
--    eleve inscrit a la seance, que la salle est ouverte, journalise le geste
--    (`log_sensitive_access`) et rend la route LiveKit ; la fonction Edge
--    appelle ensuite l'API serveur LiveKit (RoomService). Rien ne se decide
--    dans la fonction Edge.
--
--    Retrait : le plus simple et sur. Un eleve que l'enseignant fait sortir
--    est inscrit dans `public.salle_exclusions` ; tant que la ligne n'est pas
--    levee, `autoriser_jeton_video` lui refuse tout nouveau jeton pour CETTE
--    seance (et seulement celle-ci : la suivante n'est pas touchee). Seul
--    l'enseignant effectif le readmet (`public.readmettre_eleve_salle`), et
--    il lit qui est sorti par `public.eleves_sortis_salle`. Limite dite : un
--    jeton deja delivre reste valable jusqu'a son echeance
--    (`video_config.token_ttl_seconds`) ; LiveKit ne revoque pas un jeton.
--
--    Le jeton de l'enseignant porte desormais la capacite `can_moderate`
--    (role de seance `teacher`) : l'ecran lit une capacite, jamais un role.
--
-- 2. Un eleve ajoute a une Classe n'etait inscrit aux seances deja creees
--    que par la cloche de la nuit (`materialiser_seances_groupe`, qui ne voit
--    d'ailleurs que les occurrences a venir : `instant_creneau` rend la
--    prochaine). La seance du jour, en cours ou a venir, lui refusait donc le
--    jeton. Desormais, l'arrivee d'un membre (ou son retour) l'inscrit aux
--    seances de sa Classe qui ne sont pas finies (ni supprimees, ni closes,
--    fin pas encore passee). Une seance terminee n'est jamais touchee. Un
--    rattrapage inscrit une fois les membres actuels de la meme facon.
--
-- Aucun mot de suppression de ligne, d'objet ou de table dans ce fichier.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Les sorties de salle decidees par l'enseignant.
-- ---------------------------------------------------------------------------
CREATE TABLE public.salle_exclusions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  exclu_par uuid NOT NULL REFERENCES public.profiles(id),
  exclu_le timestamptz NOT NULL DEFAULT now(),
  readmis_par uuid NULL REFERENCES public.profiles(id),
  readmis_le timestamptz NULL,
  CONSTRAINT salle_exclusions_readmission_complete
    CHECK ((readmis_le IS NULL) = (readmis_par IS NULL))
);
COMMENT ON TABLE public.salle_exclusions IS
  'Eleves que l''enseignant effectif a fait sortir d''une seance (30/10/2026). Une ligne sans readmission ferme le jeton video de cet eleve pour cette seance. Lue et ecrite seulement par les fonctions de la salle.';

CREATE UNIQUE INDEX salle_exclusions_active_uidx
  ON public.salle_exclusions (session_id, profile_id)
  WHERE readmis_le IS NULL;

ALTER TABLE public.salle_exclusions ENABLE ROW LEVEL SECURITY;
-- Aucune policy : aucun client ne lit ni n'ecrit la table directement.
REVOKE ALL ON public.salle_exclusions FROM PUBLIC, anon, authenticated;

-- L'enseignant effectif d'une seance : le remplacant designe, sinon
-- l'attitre (meme lecture que le passage en cours du webhook, 20261030120000).
CREATE FUNCTION private.salle_enseignant_effectif(p_session_id uuid)
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT coalesce(private.c29_enseignant_effectif_session(s.id), s.teacher_id)
  FROM public.sessions s
  WHERE s.id = p_session_id AND s.deleted_at IS NULL;
$function$;
ALTER FUNCTION private.salle_enseignant_effectif(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.salle_enseignant_effectif(uuid)
  FROM PUBLIC, anon, authenticated, service_role;

-- Le geste, autorise et journalise par la base. Appele par la fonction Edge
-- `salle-gestes` sous la cle de service, avec l'identite lue dans le jeton
-- Supabase de l'appelant (jamais dans le corps de la requete).
CREATE FUNCTION public.autoriser_geste_salle(
  p_session_id uuid,
  p_profile_id uuid,
  p_cible uuid,
  p_geste text
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_seance public.sessions%ROWTYPE;
  v_route public.session_video_route%ROWTYPE;
  v_fenetre int := public.app_config_int('join_window_minutes', 20);
  v_grace int := public.app_config_int('grace_after_end_minutes', 15);
BEGIN
  IF p_geste IS NULL OR p_geste NOT IN ('couper_micro', 'couper_camera', 'faire_sortir') THEN
    RAISE EXCEPTION 'geste inconnu' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
     WHERE p.id = p_profile_id
       AND p.deleted_at IS NULL
       AND p.account_status IN ('active', 'provisional_active')
       AND (p.access_until IS NULL OR p.access_until > now())
  ) THEN
    RAISE EXCEPTION 'compte non valide' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_seance FROM public.sessions s
   WHERE s.id = p_session_id AND s.deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'seance introuvable' USING ERRCODE = '42501';
  END IF;

  -- Exigence positive : l'appelant EST l'enseignant effectif de la seance.
  IF NOT coalesce(private.salle_enseignant_effectif(p_session_id) = p_profile_id, false) THEN
    RAISE EXCEPTION 'geste reserve a l''enseignant de la seance' USING ERRCODE = '42501';
  END IF;

  IF v_seance.status NOT IN ('planned', 'preflight', 'in_progress')
     OR now() < coalesce(v_seance.join_opens_at,
                         v_seance.started_at - make_interval(mins => v_fenetre))
     OR now() > v_seance.ended_at + make_interval(mins => v_grace) THEN
    RAISE EXCEPTION 'salle fermee' USING ERRCODE = '23514';
  END IF;

  -- La cible est un eleve inscrit a cette seance, jamais l'enseignant ni un
  -- observateur.
  IF p_cible IS NULL OR p_cible = p_profile_id OR NOT EXISTS (
    SELECT 1 FROM public.session_participants sp
     WHERE sp.session_id = p_session_id
       AND sp.profile_id = p_cible
       AND sp.role = 'student'
       AND sp.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'cible hors de la seance' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_route FROM public.session_video_route r
   WHERE r.session_id = p_session_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'salle jamais ouverte' USING ERRCODE = '23514';
  END IF;

  IF p_geste = 'faire_sortir' THEN
    INSERT INTO public.salle_exclusions (session_id, profile_id, exclu_par)
    VALUES (p_session_id, p_cible, p_profile_id)
    ON CONFLICT (session_id, profile_id) WHERE readmis_le IS NULL DO NOTHING;
  END IF;

  -- Sous la cle de service, auth.uid() est nul : l'auteur est dans la charge.
  PERFORM public.log_sensitive_access(
    'salle_geste_' || p_geste, 'sessions', p_session_id::text,
    jsonb_build_object('enseignant', p_profile_id, 'eleve', p_cible)
  );

  RETURN jsonb_build_object(
    'provider', v_route.provider,
    'ws_url', v_route.ws_url,
    'room_name', v_route.room_name,
    -- L'identite LiveKit d'un eleve est son profil (autoriser_jeton_video).
    'identity', p_cible::text
  );
END;
$function$;
ALTER FUNCTION public.autoriser_geste_salle(uuid, uuid, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.autoriser_geste_salle(uuid, uuid, uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.autoriser_geste_salle(uuid, uuid, uuid, text)
  TO service_role;
COMMENT ON FUNCTION public.autoriser_geste_salle(uuid, uuid, uuid, text) IS
  'Salle en groupe (30/10/2026) : autorise et journalise un geste de l''enseignant effectif sur un eleve inscrit (couper_micro, couper_camera, faire_sortir), rend la route LiveKit. Cle de service seulement (fonction Edge salle-gestes).';

-- La readmission : l'enseignant effectif, connecte, leve la sortie.
CREATE FUNCTION public.readmettre_eleve_salle(p_session_id uuid, p_cible uuid)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF NOT coalesce(
       public.app_account_valid() AND v_uid IS NOT NULL
       AND private.salle_enseignant_effectif(p_session_id) = v_uid,
       false) THEN
    RAISE EXCEPTION 'readmission reservee a l''enseignant de la seance' USING ERRCODE = '42501';
  END IF;

  UPDATE public.salle_exclusions
     SET readmis_le = now(), readmis_par = v_uid
   WHERE session_id = p_session_id AND profile_id = p_cible AND readmis_le IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucune sortie a lever' USING ERRCODE = 'P0002';
  END IF;

  PERFORM public.log_sensitive_access(
    'salle_geste_readmettre', 'sessions', p_session_id::text,
    jsonb_build_object('enseignant', v_uid, 'eleve', p_cible)
  );
END;
$function$;
ALTER FUNCTION public.readmettre_eleve_salle(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.readmettre_eleve_salle(uuid, uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.readmettre_eleve_salle(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.readmettre_eleve_salle(uuid, uuid) IS
  'Salle en groupe (30/10/2026) : l''enseignant effectif connecte readmet un eleve sorti de la seance ; journalise.';

-- Qui est sorti de la seance, pour l'enseignant effectif seulement (vide pour
-- tout autre appelant).
CREATE FUNCTION public.eleves_sortis_salle(p_session_id uuid)
RETURNS TABLE (profile_id uuid, prenom text, exclu_le timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
  SELECT e.profile_id, p.first_name, e.exclu_le
  FROM public.salle_exclusions e
  JOIN public.profiles p ON p.id = e.profile_id
  WHERE e.session_id = p_session_id
    AND e.readmis_le IS NULL
    AND coalesce(public.app_account_valid() AND auth.uid() IS NOT NULL
                 AND private.salle_enseignant_effectif(p_session_id) = auth.uid(), false)
  ORDER BY e.exclu_le;
$function$;
ALTER FUNCTION public.eleves_sortis_salle(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.eleves_sortis_salle(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.eleves_sortis_salle(uuid) TO authenticated;
COMMENT ON FUNCTION public.eleves_sortis_salle(uuid) IS
  'Salle en groupe (30/10/2026) : eleves sortis de la seance et pas encore readmis ; vide pour qui n''est pas l''enseignant effectif.';

-- ---------------------------------------------------------------------------
-- Le jeton video : refus de l'eleve sorti, capacite `can_moderate`.
-- Le corps en vigueur est modifie a deux endroits, chacun trouve exactement
-- une fois ; sinon la migration s'arrete.
-- ---------------------------------------------------------------------------
DO $jeton$
DECLARE
  v_oid regprocedure := 'public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_ancre text := E'  -- La fenetre d''ouverture : configurable';
  v_ajout text := $ajout$
  -- Salle en groupe (30/10/2026) : l'eleve que l'enseignant a fait sortir
  -- ne revient pas dans CETTE seance tant qu'il n'est pas readmis.
  if v_role = 'student' and exists (
    select 1 from public.salle_exclusions e
     where e.session_id = p_session_id
       and e.profile_id = p_profile_id
       and e.readmis_le is null
  ) then
    raise exception 'sorti de la seance par l''enseignant' using errcode = 'insufficient_privilege';
  end if;

$ajout$;
  v_avant text := E'      ''can_subscribe'', true,\n';
  v_apres text := E'      ''can_subscribe'', true,\n      ''can_moderate'', v_role = ''teacher'',\n';
BEGIN
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
       / pg_catalog.length(v_ancre) <> 1
     OR (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_avant, '')))
       / pg_catalog.length(v_avant) <> 1
     OR pg_catalog.strpos(v_def, 'salle_exclusions') > 0 THEN
    RAISE EXCEPTION 'autoriser_jeton_video : ancres introuvables ou deja posees, migration a revoir';
  END IF;
  v_def := pg_catalog.replace(v_def, v_ancre, v_ajout || v_ancre);
  v_def := pg_catalog.replace(v_def, v_avant, v_apres);
  EXECUTE v_def;
END;
$jeton$;

-- ---------------------------------------------------------------------------
-- 2. Un membre qui arrive est inscrit aux seances pas encore finies.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.inscrire_membre_seances_ouvertes(p_groupe_id uuid, p_student_id uuid)
RETURNS integer
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  -- Une participation retiree (retrait d'une Classe puis retour) revit ;
  -- une seance finie, close, annulee ou supprimee n'est jamais touchee.
  INSERT INTO public.session_participants (session_id, profile_id, role)
  SELECT s.id, p_student_id, 'student'
  FROM public.sessions s
  WHERE s.groupe_id = p_groupe_id
    AND s.deleted_at IS NULL
    AND s.status IN ('planned', 'preflight', 'in_progress')
    AND s.ended_at > now()
  ON CONFLICT (session_id, profile_id) DO UPDATE
    SET deleted_at = NULL
    WHERE public.session_participants.deleted_at IS NOT NULL
      AND public.session_participants.role = 'student';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;
ALTER FUNCTION private.inscrire_membre_seances_ouvertes(uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.inscrire_membre_seances_ouvertes(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role;

CREATE FUNCTION private.membre_inscrit_aux_seances()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF NEW.left_at IS NULL THEN
    PERFORM private.inscrire_membre_seances_ouvertes(NEW.groupe_id, NEW.student_id);
  END IF;
  RETURN NULL;
END;
$function$;
ALTER FUNCTION private.membre_inscrit_aux_seances() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.membre_inscrit_aux_seances()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE TRIGGER membre_inscrit_aux_seances
  AFTER INSERT OR UPDATE OF left_at ON public.groupe_membres
  FOR EACH ROW EXECUTE FUNCTION private.membre_inscrit_aux_seances();

-- Rattrapage : les membres actuels, aux seances pas encore finies.
DO $rattrapage$
DECLARE
  v_m record;
BEGIN
  FOR v_m IN
    SELECT m.groupe_id, m.student_id FROM public.groupe_membres m WHERE m.left_at IS NULL
  LOOP
    PERFORM private.inscrire_membre_seances_ouvertes(v_m.groupe_id, v_m.student_id);
  END LOOP;
END;
$rattrapage$;

-- ---------------------------------------------------------------------------
-- Controles.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure), 'salle_exclusions') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure), 'can_moderate') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure), 'fac_eleve_suspendu') = 0 THEN
    RAISE EXCEPTION 'salle en groupe : le jeton video n''a pas ses controles';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'public.autoriser_jeton_video(uuid,uuid,text,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.autoriser_geste_salle(uuid,uuid,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'public.autoriser_geste_salle(uuid,uuid,uuid,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.autoriser_geste_salle(uuid,uuid,uuid,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.readmettre_eleve_salle(uuid,uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.readmettre_eleve_salle(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.eleves_sortis_salle(uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.eleves_sortis_salle(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.inscrire_membre_seances_ouvertes(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.salle_exclusions', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.salle_exclusions', 'SELECT') THEN
    RAISE EXCEPTION 'salle en groupe : droits inattendus';
  END IF;
END;
$postflight$;

COMMIT;
