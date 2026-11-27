-- SALLE-SECOND-APPAREIL (directeur, 23/11/2026 : « Il faut penser toujours à communiquer avec les gens ») :
-- une seule connexion par profil dans une séance, sans coupure brusque. Quand un profil déjà dans la salle demande
-- un jeton depuis un AUTRE appareil, le serveur ne le rend pas tout de suite : il crée une demande, le premier
-- appareil la voit (son battement la lui rend) et répond « Accepter » ou « Refuser ». Le second appareil attend.
--
--   * Premier appareil silencieux (aucun battement depuis 30 s : plantage, onglet fermé) : le second entre tout de
--     suite, avec la note « l'autre appareil ne répondait plus ».
--   * Premier appareil vivant qui ne répond pas dans les 45 s : « pas de réponse », le second peut recommencer.
--   * Délais lus dans `app_config` (`salle.second_appareil.battement_perime_s`, `.attente_max_s`).
--   * L'appareil est une étiquette (« Chrome · Android »), jamais une adresse IP.
--   * L'enseignant suit la même règle. L'identité visible de l'administration (`admin_visible`, identité
--     partagée « Administration Rewayah ») est hors périmètre : un compte administrateur n'est pas suivi ici.
--   * Un identifiant de demande qui n'est pas celui du demandeur (ou du profil, pour répondre) est refusé.
--
-- Aucun mot de suppression. Aucune table lisible par un client : tout passe par des fonctions SECURITY DEFINER.

INSERT INTO public.app_config (key, value) VALUES
  ('salle.second_appareil.battement_perime_s', '30'::jsonb),
  ('salle.second_appareil.attente_max_s', '45'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- L'appareil qui tient la place d'un profil dans une séance.
CREATE TABLE IF NOT EXISTS public.salle_appareils (
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  appareil uuid NOT NULL,
  libelle text NOT NULL CHECK (pg_catalog.length(libelle) BETWEEN 1 AND 60),
  battement_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  cede_le timestamptz,
  PRIMARY KEY (session_id, profile_id)
);
ALTER TABLE public.salle_appareils ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.salle_appareils FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.salle_appareils IS
  'SALLE-SECOND-APPAREIL : l''appareil qui tient la place d''un profil dans une seance (battement). Ecrite par les fonctions salle_* seulement.';

-- Les demandes d'un second appareil.
CREATE TABLE IF NOT EXISTS public.salle_passages (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.sessions(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  demandeur uuid NOT NULL REFERENCES public.profiles(id),
  appareil uuid NOT NULL,
  libelle text NOT NULL CHECK (pg_catalog.length(libelle) BETWEEN 1 AND 60),
  etat text NOT NULL DEFAULT 'en_attente'
    CHECK (etat IN ('en_attente', 'accepte', 'refuse', 'sans_reponse', 'annule', 'libre', 'servi')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  decide_le timestamptz
);
CREATE INDEX IF NOT EXISTS salle_passages_attente ON public.salle_passages (session_id, profile_id)
  WHERE etat = 'en_attente';
ALTER TABLE public.salle_passages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.salle_passages FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.salle_passages IS
  'SALLE-SECOND-APPAREIL : demandes d''un second appareil pour entrer dans une seance avec le meme profil. Ecrite par les fonctions salle_* seulement.';

-- ---------------------------------------------------------------------------
-- Aides privées.
-- ---------------------------------------------------------------------------
-- L'appelant agit pour [p_profil] : lui-même, ou le tuteur du foyer pour un élève (l'enfant qui entre depuis
-- l'appareil de son tuteur, D6 du 24/10).
CREATE OR REPLACE FUNCTION private.salle_peut_agir_pour(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() = p_profil AND public.app_account_valid(), false)
      OR coalesce(public.app_role() = 'guardian' AND public.app_account_valid() AND EXISTS (
           SELECT 1 FROM public.profiles e
            WHERE e.id = p_profil AND e.role = 'student' AND e.deleted_at IS NULL
              AND e.household_id IS NOT NULL AND e.household_id = public.app_household_id()), false);
$function$;

CREATE OR REPLACE FUNCTION private.salle_etiquette(p_libelle text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT coalesce(nullif(pg_catalog.left(pg_catalog.btrim(
           pg_catalog.regexp_replace(coalesce(p_libelle, ''), '[[:cntrl:]]', ' ', 'g')), 60), ''), 'Autre appareil');
$function$;

-- Vrai quand l'appareil tenant la place est vivant : un battement récent, non cédé.
CREATE OR REPLACE FUNCTION private.salle_appareil_vivant(a public.salle_appareils)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT a.cede_le IS NULL
     AND a.battement_le > pg_catalog.clock_timestamp()
           - pg_catalog.make_interval(secs => public.app_config_int('salle.second_appareil.battement_perime_s', 30));
$function$;

-- Réévalue une demande en attente : premier appareil silencieux => « libre » ; attente trop longue => « sans_reponse ».
CREATE OR REPLACE FUNCTION private.salle_reevaluer_passage(p_id uuid)
RETURNS public.salle_passages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  d public.salle_passages;
  a public.salle_appareils;
BEGIN
  SELECT * INTO d FROM public.salle_passages WHERE id = p_id FOR UPDATE;
  IF d.id IS NULL OR d.etat <> 'en_attente' THEN
    RETURN d;
  END IF;
  SELECT * INTO a FROM public.salle_appareils WHERE session_id = d.session_id AND profile_id = d.profile_id;
  IF a.session_id IS NULL OR a.appareil = d.appareil OR NOT private.salle_appareil_vivant(a) THEN
    UPDATE public.salle_passages SET etat = 'libre', decide_le = pg_catalog.clock_timestamp()
     WHERE id = d.id RETURNING * INTO d;
  ELSIF d.cree_le < pg_catalog.clock_timestamp()
          - pg_catalog.make_interval(secs => public.app_config_int('salle.second_appareil.attente_max_s', 45)) THEN
    UPDATE public.salle_passages SET etat = 'sans_reponse', decide_le = pg_catalog.clock_timestamp()
     WHERE id = d.id RETURNING * INTO d;
  END IF;
  RETURN d;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Le serveur de jetons (create-room-token, service_role) : peut-on rendre le jeton à cet appareil ?
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.salle_passage(
  p_session uuid, p_profil uuid, p_demandeur uuid, p_appareil uuid, p_libelle text, p_demande uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  a public.salle_appareils;
  d public.salle_passages;
  v_etiquette text := private.salle_etiquette(p_libelle);
  v_note text := NULL;
BEGIN
  IF p_session IS NULL OR p_profil IS NULL OR p_demandeur IS NULL OR p_appareil IS NULL THEN
    RAISE EXCEPTION 'appel incomplet' USING ERRCODE = '22023';
  END IF;
  -- L'administration (identite visible partagee) n'est pas suivie ici.
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = p_profil AND p.role <> 'admin') THEN
    RETURN pg_catalog.jsonb_build_object('decision', 'entrer');
  END IF;
  -- Rien n'est suivi, ni demande, pour qui n'a pas sa place dans cette seance, ou pour qui n'agit pas pour ce
  -- profil (un tuteur n'agit que pour un eleve de son foyer) : `autoriser_jeton_video` refusera de toute facon.
  -- Sans cette garde, un inconnu pourrait « tenir la place » d'un autre profil.
  IF p_demandeur <> p_profil AND NOT EXISTS (
       SELECT 1 FROM public.profiles t JOIN public.profiles e ON e.household_id = t.household_id
        WHERE t.id = p_demandeur AND t.role = 'guardian' AND t.household_id IS NOT NULL
          AND e.id = p_profil AND e.role = 'student' AND e.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('decision', 'entrer');
  END IF;
  IF NOT (EXISTS (SELECT 1 FROM public.session_participants sp
                   WHERE sp.session_id = p_session AND sp.profile_id = p_profil AND sp.deleted_at IS NULL)
          OR EXISTS (SELECT 1 FROM public.sessions s WHERE s.id = p_session AND s.teacher_id = p_profil)
          OR private.c29_enseignant_effectif_session(p_session) = p_profil
          OR EXISTS (SELECT 1 FROM private.acces_eleves_seance(p_session) e(id) WHERE e.id = p_profil)) THEN
    RETURN pg_catalog.jsonb_build_object('decision', 'entrer');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('salle_appareil:' || p_session::text || p_profil::text, 0));

  -- Une demande presentee : elle doit etre celle de CE demandeur, de CET appareil, pour CE profil et CETTE seance.
  IF p_demande IS NOT NULL THEN
    SELECT * INTO d FROM public.salle_passages WHERE id = p_demande;
    IF d.id IS NULL OR d.session_id <> p_session OR d.profile_id <> p_profil
       OR d.demandeur <> p_demandeur OR d.appareil <> p_appareil THEN
      RAISE EXCEPTION 'demande inconnue' USING ERRCODE = '42501';
    END IF;
    d := private.salle_reevaluer_passage(d.id);
  END IF;

  SELECT * INTO a FROM public.salle_appareils WHERE session_id = p_session AND profile_id = p_profil FOR UPDATE;

  -- 1. Place libre, silencieuse, cedee ou deja a cet appareil : il entre.
  IF a.session_id IS NULL OR a.appareil = p_appareil OR NOT private.salle_appareil_vivant(a) THEN
    IF a.session_id IS NOT NULL AND a.appareil <> p_appareil AND a.cede_le IS NULL THEN
      v_note := 'ancien_silencieux';
    END IF;
    INSERT INTO public.salle_appareils (session_id, profile_id, appareil, libelle)
    VALUES (p_session, p_profil, p_appareil, v_etiquette)
    ON CONFLICT (session_id, profile_id) DO UPDATE
      SET appareil = excluded.appareil, libelle = excluded.libelle,
          battement_le = pg_catalog.clock_timestamp(), cede_le = NULL;
    IF d.id IS NOT NULL AND d.etat IN ('accepte', 'libre') THEN
      UPDATE public.salle_passages SET etat = 'servi' WHERE id = d.id;
    END IF;
    RETURN pg_catalog.jsonb_build_object('decision', 'entrer', 'note', v_note);
  END IF;

  -- 2. Un autre appareil est vivant.
  IF d.id IS NOT NULL THEN
    IF d.etat IN ('accepte', 'libre') THEN
      INSERT INTO public.salle_appareils (session_id, profile_id, appareil, libelle)
      VALUES (p_session, p_profil, p_appareil, v_etiquette)
      ON CONFLICT (session_id, profile_id) DO UPDATE
        SET appareil = excluded.appareil, libelle = excluded.libelle,
            battement_le = pg_catalog.clock_timestamp(), cede_le = NULL;
      UPDATE public.salle_passages SET etat = 'servi' WHERE id = d.id;
      RETURN pg_catalog.jsonb_build_object('decision', 'entrer',
        'note', CASE WHEN d.etat = 'libre' THEN 'ancien_silencieux' END);
    ELSIF d.etat = 'refuse' THEN
      RETURN pg_catalog.jsonb_build_object('decision', 'refuse');
    ELSIF d.etat = 'sans_reponse' THEN
      RETURN pg_catalog.jsonb_build_object('decision', 'sans_reponse');
    ELSIF d.etat = 'en_attente' THEN
      RETURN pg_catalog.jsonb_build_object('decision', 'attendre', 'demande', d.id, 'libelle', a.libelle);
    END IF;
    -- annulee ou servie : on repart d'une demande neuve.
  END IF;

  -- Une demande neuve ; les precedentes de cet appareil se ferment.
  UPDATE public.salle_passages SET etat = 'annule', decide_le = pg_catalog.clock_timestamp()
   WHERE session_id = p_session AND profile_id = p_profil AND appareil = p_appareil AND etat = 'en_attente';
  INSERT INTO public.salle_passages (session_id, profile_id, demandeur, appareil, libelle)
  VALUES (p_session, p_profil, p_demandeur, p_appareil, v_etiquette)
  RETURNING * INTO d;
  PERFORM public.log_sensitive_access('salle_second_appareil_demande', 'salle_passages', d.id::text,
    pg_catalog.jsonb_build_object('session_id', p_session, 'profile_id', p_profil));
  RETURN pg_catalog.jsonb_build_object('decision', 'attendre', 'demande', d.id, 'libelle', a.libelle);
END;
$function$;

-- ---------------------------------------------------------------------------
-- Le premier appareil : battement (et notification).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.salle_battement(p_session uuid, p_profil uuid, p_appareil uuid, p_libelle text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  a public.salle_appareils;
  d public.salle_passages;
BEGIN
  IF NOT coalesce(private.salle_peut_agir_pour(p_profil), false) THEN
    RAISE EXCEPTION 'reserve a la personne concernee' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO a FROM public.salle_appareils WHERE session_id = p_session AND profile_id = p_profil FOR UPDATE;
  -- Cet appareil ne tient plus la place (cedee, ou prise par un autre) : il doit sortir.
  IF a.session_id IS NOT NULL AND a.appareil = p_appareil AND a.cede_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('cede', true, 'demande', NULL);
  END IF;
  IF a.session_id IS NOT NULL AND a.appareil <> p_appareil AND private.salle_appareil_vivant(a) THEN
    RETURN pg_catalog.jsonb_build_object('cede', true, 'demande', NULL);
  END IF;
  IF a.session_id IS NULL OR a.appareil <> p_appareil THEN
    -- Place libre ou silencieuse : cet appareil la reprend (il est dans la salle, puisqu'il bat).
    INSERT INTO public.salle_appareils (session_id, profile_id, appareil, libelle)
    VALUES (p_session, p_profil, p_appareil, private.salle_etiquette(p_libelle))
    ON CONFLICT (session_id, profile_id) DO UPDATE
      SET appareil = excluded.appareil, libelle = excluded.libelle,
          battement_le = pg_catalog.clock_timestamp(), cede_le = NULL;
  ELSE
    UPDATE public.salle_appareils SET battement_le = pg_catalog.clock_timestamp()
     WHERE session_id = p_session AND profile_id = p_profil;
  END IF;
  SELECT * INTO d FROM public.salle_passages
   WHERE session_id = p_session AND profile_id = p_profil AND etat = 'en_attente'
   ORDER BY cree_le DESC LIMIT 1;
  IF d.id IS NOT NULL THEN
    d := private.salle_reevaluer_passage(d.id);
  END IF;
  IF d.id IS NULL OR d.etat <> 'en_attente' THEN
    RETURN pg_catalog.jsonb_build_object('cede', false, 'demande', NULL);
  END IF;
  RETURN pg_catalog.jsonb_build_object('cede', false, 'demande', pg_catalog.jsonb_build_object(
    'id', d.id, 'libelle', d.libelle, 'cree_le', d.cree_le));
END;
$function$;

-- Le premier appareil répond.
CREATE OR REPLACE FUNCTION public.salle_repondre_passage(p_demande uuid, p_accepter boolean)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  d public.salle_passages;
BEGIN
  SELECT * INTO d FROM public.salle_passages WHERE id = p_demande FOR UPDATE;
  IF d.id IS NULL OR NOT coalesce(private.salle_peut_agir_pour(d.profile_id), false) THEN
    RAISE EXCEPTION 'demande inconnue' USING ERRCODE = '42501';
  END IF;
  IF p_accepter IS NULL THEN
    RAISE EXCEPTION 'reponse attendue' USING ERRCODE = '22023';
  END IF;
  d := private.salle_reevaluer_passage(d.id);
  IF d.etat <> 'en_attente' THEN
    RETURN d.etat;
  END IF;
  IF p_accepter THEN
    UPDATE public.salle_passages SET etat = 'accepte', decide_le = pg_catalog.clock_timestamp() WHERE id = d.id;
    -- Le premier appareil cede la place : son prochain battement lui dit de sortir.
    UPDATE public.salle_appareils SET cede_le = pg_catalog.clock_timestamp()
     WHERE session_id = d.session_id AND profile_id = d.profile_id AND appareil <> d.appareil;
    RETURN 'accepte';
  END IF;
  UPDATE public.salle_passages SET etat = 'refuse', decide_le = pg_catalog.clock_timestamp() WHERE id = d.id;
  RETURN 'refuse';
END;
$function$;

-- Le second appareil lit l'état de SA demande.
CREATE OR REPLACE FUNCTION public.salle_etat_passage(p_demande uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  d public.salle_passages;
BEGIN
  SELECT * INTO d FROM public.salle_passages WHERE id = p_demande;
  IF d.id IS NULL OR d.demandeur IS DISTINCT FROM auth.uid() OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'demande inconnue' USING ERRCODE = '42501';
  END IF;
  d := private.salle_reevaluer_passage(d.id);
  RETURN pg_catalog.jsonb_build_object('etat', d.etat);
END;
$function$;

-- Le second appareil renonce.
CREATE OR REPLACE FUNCTION public.salle_annuler_passage(p_demande uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  d public.salle_passages;
BEGIN
  SELECT * INTO d FROM public.salle_passages WHERE id = p_demande FOR UPDATE;
  IF d.id IS NULL OR d.demandeur IS DISTINCT FROM auth.uid() OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'demande inconnue' USING ERRCODE = '42501';
  END IF;
  IF d.etat = 'en_attente' THEN
    UPDATE public.salle_passages SET etat = 'annule', decide_le = pg_catalog.clock_timestamp() WHERE id = d.id;
  END IF;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Droits et empreintes.
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.salle_peut_agir_pour(uuid)', 'private.salle_etiquette(text)',
    'private.salle_appareil_vivant(public.salle_appareils)', 'private.salle_reevaluer_passage(uuid)',
    'public.salle_passage(uuid,uuid,uuid,uuid,text,uuid)'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', v_f);
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
    'public.salle_battement(uuid,uuid,uuid,text)', 'public.salle_repondre_passage(uuid,boolean)',
    'public.salle_etat_passage(uuid)', 'public.salle_annuler_passage(uuid)'] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role', v_f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_f);
  END LOOP;
END;
$droits$;
GRANT EXECUTE ON FUNCTION public.salle_passage(uuid,uuid,uuid,uuid,text,uuid) TO service_role;
DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.salle_passage(uuid,uuid,uuid,uuid,text,uuid), public.salle_battement(uuid,uuid,uuid,text), public.salle_repondre_passage(uuid,boolean), public.salle_etat_passage(uuid), public.salle_annuler_passage(uuid) FROM agent_ro';
  END IF;
END;
$agent$;

DO $empreinte$
DECLARE
  v_oid regprocedure;
BEGIN
  FOR v_oid IN SELECT unnest(ARRAY[
      'public.salle_battement(uuid,uuid,uuid,text)'::regprocedure,
      'public.salle_repondre_passage(uuid,boolean)'::regprocedure,
      'public.salle_etat_passage(uuid)'::regprocedure,
      'public.salle_annuler_passage(uuid)'::regprocedure]) LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-23. SALLE-SECOND-APPAREIL : un profil, un appareil a la fois.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$empreinte$;

DO $postflight$
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.salle_appareils'::regclass)
     OR NOT (SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.salle_passages'::regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'public.salle_passages', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.salle_appareils', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated', 'public.salle_passage(uuid,uuid,uuid,uuid,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.salle_battement(uuid,uuid,uuid,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', 'public.salle_passage(uuid,uuid,uuid,uuid,text,uuid)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.salle_battement(uuid,uuid,uuid,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SALLE-SECOND-APPAREIL : droits invalides';
  END IF;
END;
$postflight$;
