-- V1-a (03/11/2026) : la visio d'entretien, partie serveur, plusieurs
-- intervieweurs. Remplace 20261107700001, jamais installee.
--
-- Decisions appliquees (directeur, 03/11/2026 vers 17:20 et 17:35, relayees
-- par garde-cap ; registre 08) :
--   * la direction choisit librement, dans le personnel, le ou les fondateurs
--     et les autres participants (experts) d'un entretien ; l'application
--     n'impose ni ne propose personne ;
--   * « fondateur » est une coche sur le profil d'un membre du personnel,
--     tenue par la direction ; elle ne sert qu'a compter ;
--   * reglages (Configuration > Regles) : `entretiens.fondateurs_minimum`
--     (entier, 2 par defaut) et `entretiens.regle_fondateurs_active`
--     (booleen, vrai par defaut). Active : planifier un entretien, ou en
--     retirer un participant, avec moins de N fondateurs est refuse, avec
--     une phrase claire ; desactive : aucune verification ;
--   * aucun blocage d'entree du candidat lie aux fondateurs ;
--   * CAND-Q07 (DECISION-CANDIDATURES, ligne 30), confirme par garde-cap :
--     la separation femmes / hommes vaut aussi pour les entretiens. Tout
--     participant est du cote de la candidature ; seule exception, le
--     super-admin de 0088 (tant que `kyc_exception_super_admin` est vrai).
--     Le serveur l'impose ; ce n'est pas un reglage ;
--   * un compte rendu par participant, lisible par la direction ; l'issue de
--     l'entretien est consignee par la direction (moteur des candidatures,
--     regles 12 et 13) ; le journal des presents est celui de la salle
--     (`session_events`, ecrit par le webhook LiveKit pour tout porteur de
--     jeton).
--
-- Exclusions (recensement B1 et mesure du 03/11) : seule la cloture de
-- tresorerie prenait la seance d'entretien ; elle est gardee ici. La seance
-- porte `teacher_id` = la direction qui planifie, jamais un enseignant :
-- aucune vue d'enseignant ni de Classe ne la montre.
--
-- Pour la salle 3 (N1, 20261108300000), stables et documentes :
--   * `public.entretiens.candidature_id`, `issue` ('tenu', 'annule',
--     'manque_candidat', 'manque_intervieweur') ;
--   * `public.entretien_comptes_rendus` (avis 'favorable', 'reserve',
--     'defavorable' ; constat : memorisation_observee, tajwid_observe,
--     riwayat_observees, ijaza_presentee, codes de la salle d'examen) ;
--   * `private.entretien_conclusion(p_candidature uuid) RETURNS jsonb`,
--     STABLE, sans droit client.
--
-- `supabase/functions` : rien ne change.
--
-- Mots de suppression de ce fichier : 0.

-- ---------------------------------------------------------------------------
-- 1. Les fondateurs (coche de la direction)
-- ---------------------------------------------------------------------------
CREATE TABLE public.personnel_fondateurs (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id),
  -- La coche elle-meme ; decocher la remet a faux, sans effacer la ligne.
  fondateur boolean NOT NULL,
  modifie_par uuid NOT NULL REFERENCES public.profiles(id),
  modifie_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
ALTER TABLE public.personnel_fondateurs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.personnel_fondateurs FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.personnel_fondateurs IS
  'V1-a (03/11/2026) : la coche « fondateur » d''un membre du personnel, tenue par la direction '
  '(poser_fondateur). Ne sert qu''a compter les fondateurs d''un entretien.';

-- Un membre du personnel au compte actif (direction, enseignant, comptable,
-- controleur), jamais un candidat (`pending_kyc`) ni un eleve ou un tuteur.
CREATE FUNCTION private.personnel_actif(p_profil uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce((
    SELECT p.role IN ('admin', 'teacher', 'accountant', 'controller')
           AND p.account_status = 'active'
           AND p.deleted_at IS NULL
      FROM public.profiles p WHERE p.id = p_profil), false);
$function$;

-- CAND-Q07 : une personne peut prendre part a un entretien de ce cote si elle
-- est de ce genre, ou si elle est le super-admin de 0088 (exception active).
CREATE FUNCTION private.entretien_cote_permis(p_profil uuid, p_genre public.gender)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    EXISTS (SELECT 1 FROM public.profiles p
             WHERE p.id = p_profil AND p.gender = p_genre)
    OR (EXISTS (SELECT 1 FROM private.super_admin_kyc s WHERE s.profile_id = p_profil)
        AND EXISTS (SELECT 1 FROM public.app_config c
                     WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb)),
    false);
$function$;

CREATE FUNCTION public.poser_fondateur(p_profil uuid, p_fondateur boolean)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'la coche fondateur est tenue par la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_profil IS NULL OR p_fondateur IS NULL THEN
    RAISE EXCEPTION 'fondateur : profil et choix attendus' USING ERRCODE = '22023';
  END IF;
  IF p_fondateur THEN
    IF NOT private.personnel_actif(p_profil) THEN
      RAISE EXCEPTION 'seul un membre du personnel au compte actif peut etre fondateur'
        USING ERRCODE = '22023';
    END IF;
  END IF;
  INSERT INTO public.personnel_fondateurs AS f (profile_id, fondateur, modifie_par)
  VALUES (p_profil, p_fondateur, auth.uid())
  ON CONFLICT (profile_id) DO UPDATE
    SET fondateur = excluded.fondateur, modifie_par = excluded.modifie_par,
        modifie_le = pg_catalog.clock_timestamp();
  PERFORM public.log_sensitive_access(
    CASE WHEN p_fondateur THEN 'fondateur_coche' ELSE 'fondateur_decoche' END,
    'personnel_fondateurs', p_profil::text, '{}'::jsonb);
  RETURN p_fondateur;
END;
$function$;

-- La liste du personnel pour choisir les participants : la direction active,
-- de genre connu ; les personnes de SON cote (CAND-Q07), et le super-admin.
-- Aucun contact.
CREATE FUNCTION public.personnel_entretiens()
RETURNS TABLE (profile_id uuid, prenom text, nom text, role text, fondateur boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
BEGIN
  SELECT l.genre INTO v_genre FROM private.cand_lecteur() l;
  IF v_genre IS NULL THEN
    RAISE EXCEPTION 'personnel des entretiens reserve a la direction active de genre connu'
      USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT p.id, p.first_name, p.last_name, p.role::text, coalesce(f.fondateur, false)
      FROM public.profiles p
      LEFT JOIN public.personnel_fondateurs f ON f.profile_id = p.id
     WHERE private.personnel_actif(p.id)
       AND private.entretien_cote_permis(p.id, v_genre)
     ORDER BY coalesce(f.fondateur, false) DESC, p.first_name, p.last_name;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. Les reglages (Configuration > Regles)
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('entretiens.fondateurs_minimum', '2'::jsonb),
  ('entretiens.regle_fondateurs_active', 'true'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.entretiens_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.key = 'entretiens.fondateurs_minimum' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number'
       OR (NEW.value #>> '{}') !~ '^[1-9][0-9]?$' THEN
      RAISE EXCEPTION 'nombre minimum de fondateurs : un entier de 1 a 99 est attendu'
        USING ERRCODE = '22023';
    END IF;
  ELSIF NEW.key = 'entretiens.regle_fondateurs_active' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'boolean' THEN
      RAISE EXCEPTION 'regle des fondateurs : oui ou non est attendu' USING ERRCODE = '22023';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER app_config_entretiens
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.entretiens_reglages_valider();

-- Le minimum de fondateurs exige, ou NULL quand la regle est desactivee.
CREATE FUNCTION private.entretiens_fondateurs_exiges()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN coalesce((SELECT c.value FROM public.app_config c
                    WHERE c.key = 'entretiens.regle_fondateurs_active'), 'true'::jsonb) = 'true'::jsonb
    THEN coalesce((SELECT (c.value #>> '{}')::integer FROM public.app_config c
                    WHERE c.key = 'entretiens.fondateurs_minimum'), 2)
  END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. L'entretien, ses participants, leurs comptes rendus
-- ---------------------------------------------------------------------------
CREATE TABLE public.entretiens (
  session_id uuid PRIMARY KEY REFERENCES public.sessions(id),
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id),
  candidat_id uuid NOT NULL REFERENCES public.profiles(id),
  planifie_par uuid NOT NULL REFERENCES public.profiles(id),
  planifie_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  -- NULL tant que la direction n'a pas consigne l'entretien.
  issue text NULL CHECK (issue IN ('tenu', 'annule', 'manque_candidat', 'manque_intervieweur')),
  consigne_par uuid NULL REFERENCES public.profiles(id),
  consigne_le timestamptz NULL,
  CONSTRAINT entretiens_consigne_coherent CHECK ((issue IS NULL) = (consigne_le IS NULL)
                                                 AND (issue IS NULL) = (consigne_par IS NULL))
);
CREATE UNIQUE INDEX entretiens_un_ouvert_par_candidature
  ON public.entretiens (candidature_id) WHERE issue IS NULL;
CREATE INDEX entretiens_candidature_idx ON public.entretiens (candidature_id, consigne_le DESC);
ALTER TABLE public.entretiens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.entretiens FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.entretiens IS
  'V1-a (03/11/2026) : une seance session_type = entretien et sa candidature. Issue : NULL (ouvert), '
  'tenu, annule, manque_candidat, manque_intervieweur. Lu par la salle 3 (20261108300000) a travers '
  'private.entretien_conclusion. Aucun droit client.';

CREATE TABLE public.entretien_participants (
  session_id uuid NOT NULL REFERENCES public.entretiens(session_id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  -- Fondateur au moment de l'ajout (la coche peut changer ensuite).
  fondateur boolean NOT NULL,
  ajoute_par uuid NOT NULL REFERENCES public.profiles(id),
  ajoute_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  retire_par uuid NULL REFERENCES public.profiles(id),
  retire_le timestamptz NULL,
  PRIMARY KEY (session_id, profile_id),
  CONSTRAINT entretien_participants_retrait CHECK ((retire_le IS NULL) = (retire_par IS NULL))
);
CREATE INDEX entretien_participants_profil_idx ON public.entretien_participants (profile_id)
  WHERE retire_le IS NULL;
ALTER TABLE public.entretien_participants ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.entretien_participants FROM PUBLIC, anon, authenticated;

CREATE TABLE public.entretien_comptes_rendus (
  session_id uuid NOT NULL REFERENCES public.entretiens(session_id),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  texte text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(texte)) BETWEEN 1 AND 4000),
  avis text NOT NULL CHECK (avis IN ('favorable', 'reserve', 'defavorable')),
  -- Le constat, codes de la salle d'examen (20261022000000).
  memorisation_observee text NULL
    CHECK (memorisation_observee IN ('aucune', 'moins_10_juz', 'de_10_a_29_juz', 'coran_entier')),
  tajwid_observe text NULL
    CHECK (tajwid_observe IN ('lecture_sans_regles_tajwid', 'tajwid_applique', 'tajwid_enseigne')),
  riwayat_observees text[] NOT NULL DEFAULT '{}'::text[]
    CHECK (riwayat_observees <@ ARRAY['hafs', 'shuba', 'warsh', 'qalun', 'al_bazzi', 'qunbul',
      'ad_duri_abi_amr', 'as_susi', 'hisham', 'ibn_dhakwan', 'khalaf_an_hamza', 'khallad',
      'abu_al_harith', 'ad_duri_al_kisai', 'ibn_wardan', 'ibn_jammaz', 'ruways', 'rawh', 'ishaq',
      'idris']::text[]),
  ijaza_presentee text NULL CHECK (ijaza_presentee IN ('oui', 'pret_test', 'non')),
  ecrit_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (session_id, auteur_id)
);
ALTER TABLE public.entretien_comptes_rendus ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.entretien_comptes_rendus FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.entretien_comptes_rendus IS
  'V1-a (03/11/2026) : un compte rendu par participant (avis favorable, reserve ou defavorable, et '
  'constat). Ecrit par le participant, lu par la direction de ce cote.';

-- Le compte des fondateurs actifs d'un entretien, et le refus clair quand il
-- en manque (regle activee).
CREATE FUNCTION private.entretien_fondateurs_verifier(p_fondateurs integer)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_exige integer := private.entretiens_fondateurs_exiges();
BEGIN
  IF v_exige IS NOT NULL AND coalesce(p_fondateurs, 0) < v_exige THEN
    RETURN pg_catalog.jsonb_build_object(
      'erreur', 'fondateurs_insuffisants',
      'exiges', v_exige,
      'presents', coalesce(p_fondateurs, 0),
      'message', pg_catalog.format(
        'Il faut au moins %s fondateurs parmi les participants (%s choisi%s).',
        v_exige, coalesce(p_fondateurs, 0), CASE WHEN coalesce(p_fondateurs, 0) > 1 THEN 's' ELSE '' END));
  END IF;
  RETURN NULL;
END;
$function$;

-- Le genre de la candidature d'un entretien, et la garde de la direction qui
-- agit : active, de genre connu, du meme cote.
CREATE FUNCTION private.entretien_direction_de_son_cote(p_session uuid)
RETURNS public.entretiens
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_e public.entretiens;
  v_genre public.gender;
BEGIN
  SELECT l.genre INTO v_genre FROM private.cand_lecteur() l;
  IF v_genre IS NULL THEN
    RAISE EXCEPTION 'entretiens reserves a la direction active de genre connu' USING ERRCODE = '42501';
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e
    JOIN public.candidatures c ON c.id = e.candidature_id
   WHERE e.session_id = p_session AND c.genre = v_genre;
  RETURN v_e;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Les gestes de la direction
-- ---------------------------------------------------------------------------
-- planifierEntretien : candidature en Salle de verification, entretien a
-- planifier (moteur, regle 11) ; participants choisis librement dans le
-- personnel actif, du cote de la candidature ; fondateurs comptes si la
-- regle est active. La seance porte teacher_id = la direction qui planifie.
CREATE FUNCTION public.planifier_entretien(
  p_candidature uuid,
  p_debut timestamptz,
  p_duree_minutes integer,
  p_participants uuid[],
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_o jsonb;
  v_c public.candidatures;
  v_seance uuid;
  v_participants uuid[];
  v_p uuid;
  v_fondateurs integer;
  v_refus jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_debut IS NULL OR p_duree_minutes IS NULL THEN
    RAISE EXCEPTION 'entretien : debut et duree attendus' USING ERRCODE = '22023';
  END IF;

  v_o := private.candidature_geste_ouvrir(p_candidature, 'planifier_entretien', 'direction', v_moi,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;

  IF NOT pg_catalog.isfinite(p_debut)
     OR p_debut < pg_catalog.now() + interval '5 minutes'
     OR p_debut > pg_catalog.now() + interval '90 days' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'debut_invalide');
  END IF;
  IF p_duree_minutes NOT BETWEEN 15 AND 120 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'duree_invalide');
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature;
  IF v_c.profile_id IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.profiles p WHERE p.id = v_c.profile_id AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidat_sans_compte');
  END IF;

  SELECT pg_catalog.array_agg(DISTINCT x) INTO v_participants
    FROM pg_catalog.unnest(coalesce(p_participants, '{}'::uuid[])) x WHERE x IS NOT NULL;
  IF v_participants IS NULL OR pg_catalog.cardinality(v_participants) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participants_requis');
  END IF;
  IF pg_catalog.cardinality(v_participants) > 12 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participants_trop_nombreux');
  END IF;
  FOREACH v_p IN ARRAY v_participants LOOP
    IF v_p = v_c.profile_id OR NOT private.personnel_actif(v_p) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'participant_non_autorise', 'profil', v_p);
    END IF;
    IF NOT private.entretien_cote_permis(v_p, v_c.genre) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'participant_autre_cote', 'profil', v_p);
    END IF;
  END LOOP;
  SELECT count(*)::integer INTO v_fondateurs
    FROM public.personnel_fondateurs f
   WHERE f.fondateur AND f.profile_id = ANY (v_participants);
  v_refus := private.entretien_fondateurs_verifier(v_fondateurs);
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;
  IF EXISTS (SELECT 1 FROM public.entretiens e WHERE e.candidature_id = v_c.id AND e.issue IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_deja_planifie');
  END IF;

  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_moi, p_debut, p_debut + pg_catalog.make_interval(mins => p_duree_minutes),
          'planned', 'entretien', p_debut - interval '10 minutes')
  RETURNING id INTO v_seance;
  INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
  VALUES (v_seance, v_c.id, v_c.profile_id, v_moi);
  INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par)
  SELECT v_seance, x, coalesce(f.fondateur, false), v_moi
    FROM pg_catalog.unnest(v_participants) x
    LEFT JOIN public.personnel_fondateurs f ON f.profile_id = x;
  INSERT INTO public.session_participants (session_id, profile_id, role)
  SELECT v_seance, x, 'intervieweur'::public.participant_role FROM pg_catalog.unnest(v_participants) x
  UNION ALL
  SELECT v_seance, v_c.profile_id, 'candidat'::public.participant_role;

  PERFORM private.candidature_geste_appliquer(p_candidature, 'planifier_entretien',
    (v_o ->> 'variante')::smallint, 'direction', v_moi, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('sessionId', v_seance, 'debut', p_debut,
      'dureeMinutes', p_duree_minutes, 'participants', pg_catalog.to_jsonb(v_participants),
      'fondateurs', v_fondateurs, 'aNotifier', 'entretien_planifie'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_candidature, 'planifier_entretien', v_moi,
    pg_catalog.jsonb_build_object(
      'candidature', private.candidature_etat_direction(p_candidature),
      'entretien', pg_catalog.jsonb_build_object(
        'sessionId', v_seance, 'debut', p_debut,
        'fin', p_debut + pg_catalog.make_interval(mins => p_duree_minutes),
        'participants', pg_catalog.to_jsonb(v_participants), 'fondateurs', v_fondateurs)));
END;
$function$;

-- Ajouter un participant a un entretien ouvert, par profil, du meme cote.
CREATE FUNCTION public.ajouter_participant_entretien(p_session uuid, p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_e public.entretiens;
  v_genre public.gender;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_e := private.entretien_direction_de_son_cote(p_session);
  IF v_e.session_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF v_e.issue IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_consigne');
  END IF;
  SELECT c.genre INTO v_genre FROM public.candidatures c WHERE c.id = v_e.candidature_id;
  IF p_profil IS NULL OR p_profil = v_e.candidat_id OR NOT private.personnel_actif(p_profil) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participant_non_autorise');
  END IF;
  IF NOT private.entretien_cote_permis(p_profil, v_genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participant_autre_cote');
  END IF;
  INSERT INTO public.entretien_participants AS ep (session_id, profile_id, fondateur, ajoute_par)
  VALUES (p_session, p_profil,
          coalesce((SELECT f.fondateur FROM public.personnel_fondateurs f WHERE f.profile_id = p_profil), false),
          auth.uid())
  ON CONFLICT (session_id, profile_id) DO UPDATE
    SET retire_le = NULL, retire_par = NULL, ajoute_par = excluded.ajoute_par,
        ajoute_le = pg_catalog.clock_timestamp(), fondateur = excluded.fondateur;
  INSERT INTO public.session_participants AS sp (session_id, profile_id, role)
  VALUES (p_session, p_profil, 'intervieweur'::public.participant_role)
  ON CONFLICT (session_id, profile_id) DO UPDATE SET deleted_at = NULL, role = excluded.role;
  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
  VALUES (v_e.candidature_id, 'entretien', auth.uid(),
          pg_catalog.jsonb_build_object('geste', 'ajouter_participant', 'sessionId', p_session,
                                        'profil', p_profil));
  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'ajoute', p_profil);
END;
$function$;

-- Retirer un participant : jamais en dessous du minimum de fondateurs (regle
-- active), jamais le dernier participant.
CREATE FUNCTION public.retirer_participant_entretien(p_session uuid, p_profil uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_e public.entretiens;
  v_restants integer;
  v_fondateurs integer;
  v_refus jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_e := private.entretien_direction_de_son_cote(p_session);
  IF v_e.session_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF v_e.issue IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_consigne');
  END IF;
  PERFORM 1 FROM public.entretien_participants ep
   WHERE ep.session_id = p_session FOR UPDATE;
  IF NOT EXISTS (SELECT 1 FROM public.entretien_participants ep
                  WHERE ep.session_id = p_session AND ep.profile_id = p_profil AND ep.retire_le IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participant_absent');
  END IF;
  SELECT count(*)::integer, count(*) FILTER (WHERE ep.fondateur)::integer
    INTO v_restants, v_fondateurs
    FROM public.entretien_participants ep
   WHERE ep.session_id = p_session AND ep.retire_le IS NULL AND ep.profile_id <> p_profil;
  IF v_restants = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'dernier_participant');
  END IF;
  v_refus := private.entretien_fondateurs_verifier(v_fondateurs);
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;
  UPDATE public.entretien_participants
     SET retire_le = pg_catalog.clock_timestamp(), retire_par = auth.uid()
   WHERE session_id = p_session AND profile_id = p_profil;
  UPDATE public.session_participants SET deleted_at = pg_catalog.now()
   WHERE session_id = p_session AND profile_id = p_profil;
  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
  VALUES (v_e.candidature_id, 'entretien', auth.uid(),
          pg_catalog.jsonb_build_object('geste', 'retirer_participant', 'sessionId', p_session,
                                        'profil', p_profil));
  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'retire', p_profil);
END;
$function$;

-- consignerEntretien (contrat) : tenu (au moins un compte rendu, regle 13),
-- ou annule, manque du candidat, manque d'un intervieweur (motif requis,
-- regle 12). La seance suit par les transitions permises.
CREATE FUNCTION public.consigner_entretien(
  p_session uuid,
  p_issue text,
  p_motif text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_e public.entretiens;
  v_geste text;
  v_o jsonb;
  v_statut public.session_status;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_issue IS NULL OR p_issue NOT IN ('tenu', 'annule', 'manque_candidat', 'manque_intervieweur') THEN
    RAISE EXCEPTION 'entretien : issue tenu, annule, manque_candidat ou manque_intervieweur attendue'
      USING ERRCODE = '22023';
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e WHERE e.session_id = p_session;
  IF v_e.session_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  v_geste := CASE WHEN p_issue = 'tenu' THEN 'consigner_entretien_tenu' ELSE 'consigner_entretien_non_tenu' END;

  v_o := private.candidature_geste_ouvrir(v_e.candidature_id, v_geste, 'direction', v_moi,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e WHERE e.session_id = p_session FOR UPDATE;
  IF v_e.issue IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_deja_consigne');
  END IF;
  IF p_issue = 'tenu' AND NOT EXISTS (
       SELECT 1 FROM public.entretien_comptes_rendus cr WHERE cr.session_id = p_session) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'compte_rendu_requis');
  END IF;

  UPDATE public.entretiens
     SET issue = p_issue, consigne_par = v_moi, consigne_le = pg_catalog.clock_timestamp()
   WHERE session_id = p_session;

  SELECT s.status INTO v_statut FROM public.sessions s WHERE s.id = p_session FOR UPDATE;
  IF p_issue = 'tenu' THEN
    IF v_statut = 'planned' THEN
      UPDATE public.sessions SET status = 'preflight' WHERE id = p_session;
      v_statut := 'preflight';
    END IF;
    IF v_statut = 'preflight' THEN
      UPDATE public.sessions SET status = 'in_progress' WHERE id = p_session;
      v_statut := 'in_progress';
    END IF;
    IF v_statut = 'in_progress' THEN
      UPDATE public.sessions SET status = 'ended' WHERE id = p_session;
    END IF;
  ELSIF v_statut = 'planned' THEN
    UPDATE public.sessions SET status = 'canceled' WHERE id = p_session;
  END IF;

  PERFORM private.candidature_geste_appliquer(v_e.candidature_id, v_geste,
    (v_o ->> 'variante')::smallint, 'direction', v_moi, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('sessionId', p_session, 'issue', p_issue));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_e.candidature_id, v_geste, v_moi,
    pg_catalog.jsonb_build_object(
      'candidature', private.candidature_etat_direction(v_e.candidature_id),
      'entretien', pg_catalog.jsonb_build_object('sessionId', p_session, 'issue', p_issue)));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Les participants : leurs entretiens, leur compte rendu
-- ---------------------------------------------------------------------------
-- Le compte rendu de l'appelant, participant actif d'un entretien commence
-- et pas encore consigne. Un par participant ; reecrit tant que l'entretien
-- est ouvert.
CREATE FUNCTION public.ecrire_compte_rendu_entretien(
  p_session uuid,
  p_texte text,
  p_avis text,
  p_memorisation text,
  p_tajwid text,
  p_riwayat text[],
  p_ijaza text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_e public.entretiens;
  v_debut timestamptz;
BEGIN
  IF v_moi IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'compte rendu reserve a un participant au compte valide' USING ERRCODE = '42501';
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e
    JOIN public.entretien_participants ep ON ep.session_id = e.session_id
   WHERE e.session_id = p_session AND ep.profile_id = v_moi AND ep.retire_le IS NULL;
  IF v_e.session_id IS NULL THEN
    RAISE EXCEPTION 'compte rendu reserve aux participants de cet entretien' USING ERRCODE = '42501';
  END IF;
  IF v_e.issue IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_consigne');
  END IF;
  -- CAND-Q07 : du cote de la candidature, ou super-admin (exception active).
  IF NOT private.entretien_cote_permis(v_moi,
       (SELECT c.genre FROM public.candidatures c WHERE c.id = v_e.candidature_id)) THEN
    RAISE EXCEPTION 'compte rendu reserve aux participants du cote de la candidature'
      USING ERRCODE = '42501';
  END IF;
  SELECT s.started_at INTO v_debut FROM public.sessions s WHERE s.id = p_session;
  IF pg_catalog.now() < v_debut THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_pas_commence');
  END IF;
  IF p_texte IS NULL OR pg_catalog.length(pg_catalog.btrim(p_texte)) NOT BETWEEN 1 AND 4000 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'texte_invalide');
  END IF;
  INSERT INTO public.entretien_comptes_rendus AS cr
    (session_id, auteur_id, texte, avis, memorisation_observee, tajwid_observe, riwayat_observees,
     ijaza_presentee)
  VALUES (p_session, v_moi, pg_catalog.btrim(p_texte), p_avis, p_memorisation, p_tajwid,
          coalesce(p_riwayat, '{}'::text[]), p_ijaza)
  ON CONFLICT (session_id, auteur_id) DO UPDATE
    SET texte = excluded.texte, avis = excluded.avis,
        memorisation_observee = excluded.memorisation_observee,
        tajwid_observe = excluded.tajwid_observe, riwayat_observees = excluded.riwayat_observees,
        ijaza_presentee = excluded.ijaza_presentee, ecrit_le = pg_catalog.clock_timestamp();
  RETURN pg_catalog.jsonb_build_object('sessionId', p_session, 'enregistre', true);
EXCEPTION WHEN check_violation THEN
  RETURN pg_catalog.jsonb_build_object('erreur', 'constat_invalide');
END;
$function$;

-- mesEntretiens : ceux ou l'appelant participe ; pour la direction active de
-- genre connu, aussi tous ceux de son cote. Jamais le contact du candidat.
CREATE FUNCTION public.mes_entretiens(p_jours integer DEFAULT 14)
RETURNS TABLE (
  session_id uuid,
  candidature_id uuid,
  reference text,
  nom_complet text,
  debut timestamptz,
  fin timestamptz,
  statut_seance text,
  issue text,
  je_participe boolean,
  mon_compte_rendu boolean,
  participants integer,
  fondateurs integer,
  version_candidature integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_genre public.gender;
BEGIN
  IF v_moi IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'entretiens reserves a un compte valide' USING ERRCODE = '42501';
  END IF;
  SELECT l.genre INTO v_genre FROM private.cand_lecteur() l;
  RETURN QUERY
    SELECT e.session_id, c.id, c.reference, c.nom_complet, s.started_at, s.ended_at,
           s.status::text, e.issue,
           EXISTS (SELECT 1 FROM public.entretien_participants ep
                    WHERE ep.session_id = e.session_id AND ep.profile_id = v_moi AND ep.retire_le IS NULL),
           EXISTS (SELECT 1 FROM public.entretien_comptes_rendus cr
                    WHERE cr.session_id = e.session_id AND cr.auteur_id = v_moi),
           (SELECT count(*)::integer FROM public.entretien_participants ep
             WHERE ep.session_id = e.session_id AND ep.retire_le IS NULL),
           (SELECT count(*) FILTER (WHERE ep.fondateur)::integer FROM public.entretien_participants ep
             WHERE ep.session_id = e.session_id AND ep.retire_le IS NULL),
           c.version
      FROM public.entretiens e
      JOIN public.candidatures c ON c.id = e.candidature_id
      JOIN public.sessions s ON s.id = e.session_id
     WHERE s.deleted_at IS NULL
       AND s.ended_at >= pg_catalog.now()
             - pg_catalog.make_interval(days => least(greatest(coalesce(p_jours, 14), 0), 90))
       AND ((v_genre IS NOT NULL AND c.genre = v_genre)
            OR EXISTS (SELECT 1 FROM public.entretien_participants ep
                        WHERE ep.session_id = e.session_id AND ep.profile_id = v_moi
                          AND ep.retire_le IS NULL))
     ORDER BY s.started_at;
END;
$function$;

-- lireEntretien : les participants, les comptes rendus et le journal des
-- presents. La direction de ce cote lit tout ; un participant lit les
-- participants et son propre compte rendu.
CREATE FUNCTION public.lire_entretien(p_session uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_e public.entretiens;
  v_direction boolean := false;
  v_participant boolean;
BEGIN
  IF v_moi IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'entretien reserve a un compte valide' USING ERRCODE = '42501';
  END IF;
  IF EXISTS (SELECT 1 FROM private.cand_lecteur() l WHERE l.genre IS NOT NULL) THEN
    v_e := private.entretien_direction_de_son_cote(p_session);
    v_direction := v_e.session_id IS NOT NULL;
  END IF;
  v_participant := EXISTS (SELECT 1 FROM public.entretien_participants ep
                            WHERE ep.session_id = p_session AND ep.profile_id = v_moi
                              AND ep.retire_le IS NULL);
  IF NOT v_direction AND NOT v_participant THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e WHERE e.session_id = p_session;
  RETURN pg_catalog.jsonb_build_object(
    'sessionId', v_e.session_id,
    'issue', v_e.issue,
    'participants', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'profileId', ep.profile_id, 'prenom', p.first_name, 'nom', p.last_name,
               'fondateur', ep.fondateur, 'retire', ep.retire_le IS NOT NULL)
             ORDER BY ep.fondateur DESC, p.first_name)
        FROM public.entretien_participants ep
        JOIN public.profiles p ON p.id = ep.profile_id
       WHERE ep.session_id = p_session), '[]'::jsonb),
    'comptesRendus', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'auteurId', cr.auteur_id, 'texte', cr.texte, 'avis', cr.avis,
               'memorisation', cr.memorisation_observee, 'tajwid', cr.tajwid_observe,
               'riwayat', cr.riwayat_observees, 'ijaza', cr.ijaza_presentee, 'ecritLe', cr.ecrit_le)
             ORDER BY cr.ecrit_le)
        FROM public.entretien_comptes_rendus cr
       WHERE cr.session_id = p_session AND (v_direction OR cr.auteur_id = v_moi)), '[]'::jsonb),
    -- Le journal des presents (webhook LiveKit), pour la direction.
    'presences', CASE WHEN v_direction THEN coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'profileId', ev.profile_id, 'evenement', ev.event_type::text, 'le', ev.server_ts)
             ORDER BY ev.server_ts)
        FROM public.session_events ev
       WHERE ev.session_id = p_session AND ev.event_type::text IN ('joined', 'left')), '[]'::jsonb)
      ELSE '[]'::jsonb END);
END;
$function$;

REVOKE ALL ON FUNCTION public.personnel_entretiens() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.poser_fondateur(uuid, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.planifier_entretien(uuid, timestamptz, integer, uuid[], integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.ajouter_participant_entretien(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.retirer_participant_entretien(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.consigner_entretien(uuid, text, text, integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.ecrire_compte_rendu_entretien(uuid, text, text, text, text, text[], text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mes_entretiens(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.lire_entretien(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.personnel_entretiens() TO authenticated;
GRANT EXECUTE ON FUNCTION public.poser_fondateur(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.planifier_entretien(uuid, timestamptz, integer, uuid[], integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ajouter_participant_entretien(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.retirer_participant_entretien(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.consigner_entretien(uuid, text, text, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ecrire_compte_rendu_entretien(uuid, text, text, text, text, text[], text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mes_entretiens(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lire_entretien(uuid) TO authenticated;
REVOKE ALL ON FUNCTION private.personnel_actif(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretien_cote_permis(uuid, public.gender) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretiens_fondateurs_exiges() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretien_fondateurs_verifier(integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretien_direction_de_son_cote(uuid) FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 6. Exclusion : la tresorerie ne prend que les seances de cours
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.x217_sessions_cloture_tresorerie()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  -- V1 : un entretien ou une reunion n'est ni une prestation ni une paie.
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('ended','tech_failure')
     AND NEW.session_type IN ('standard', 'child') THEN
    PERFORM public.remuneration_due_seance(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Le jeton video (corps en vigueur, retouche par ancrage)
-- ---------------------------------------------------------------------------
-- Le corps en vigueur est retouche par ancrage, comme 20261102800000 et
-- 20261104600000 l'ont fait (une copie du texte de 20261102500000 effacerait
-- l'ouverture par le jeton, A3-bis, SNT et l'acces paye). Chaque ancre doit
-- se trouver une fois et une seule, sinon la migration s'arrete.
DO $jeton$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_retouches text[][] := ARRAY[
    -- 1. Le compte : le candidat `pending_kyc` admis pour SA seance d'entretien
    --    seulement (inscrit `candidat`, entretien ouvert, candidature en cours).
    ARRAY[$a$       and p.account_status in ('active', 'provisional_active')
       and (p.access_until is null or p.access_until > now())
  ) then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';$a$,
          $a$       and (p.access_until is null or p.access_until > now())
       and (p.account_status in ('active', 'provisional_active')
            -- V1 (03/11/2026) : le candidat convoque entre avec un compte
            -- `pending_kyc`, dans SA seance d'entretien seulement.
            or (p.account_status = 'pending_kyc' and exists (
                  select 1
                    from public.sessions s
                    join public.session_participants sp on sp.session_id = s.id
                    join public.entretiens en on en.session_id = s.id
                    join public.candidatures c on c.id = en.candidature_id
                   where s.id = p_session_id
                     and s.session_type = 'entretien'
                     and sp.profile_id = p_profile_id
                     and sp.role = 'candidat'
                     and sp.deleted_at is null
                     and en.candidat_id = p_profile_id
                     and en.issue is null
                     and c.issue = 'en_cours')))
  ) then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';$a$],
    -- 2. Le role : un entretien ou une reunion n'admet que ses inscrits (ni
    --    l'enseignant deduit de teacher_id, ni un remplacant) ; `candidat` ne
    --    vaut que dans un entretien ouvert, sur sa propre candidature.
    ARRAY[$a$  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;$a$,
          $a$  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;
  -- V1 (03/11/2026) : entretien et reunion, inscrits seulement ; les roles
  -- `candidat` et `intervieweur` hors d'un entretien ne valent rien, et
  -- `candidat` seulement dans un entretien ouvert. (Ces tests ne
  -- changent pas FOUND, lu plus bas.)
  if v_seance.session_type in ('entretien', 'reunion') then
    if v_role is null or v_role in ('teacher', 'student', 'guardian_observer') then
      raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
    end if;
  elsif v_role in ('candidat', 'intervieweur') then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;
  if v_role = 'candidat' and not exists (
    select 1 from public.entretiens en
      join public.candidatures c on c.id = en.candidature_id
     where en.session_id = p_session_id
       and en.candidat_id = p_profile_id
       and en.issue is null
       and c.issue = 'en_cours'
  ) then
    raise exception 'entretien clos ou candidature close' using errcode = 'insufficient_privilege';
  end if;$a$],
    -- 3. Le candidat et les intervieweurs parlent (aucun canal de donnees,
    --    jamais masques : chacun est nomme).
    ARRAY[$a$  v_publier       := v_role in ('teacher', 'student', 'admin_visible');$a$,
          $a$  v_publier       := v_role in ('teacher', 'student', 'admin_visible', 'candidat', 'intervieweur');$a$],
    -- 4. ... et se montrent (visio d'entretien).
    ARRAY[$a$  if v_role = 'teacher' then
    v_publier_video := true;$a$,
          $a$  if v_role in ('teacher', 'candidat', 'intervieweur') then
    v_publier_video := true;$a$]
  ];
  i integer;
  v_ancre text;
BEGIN
  FOR i IN 1 .. pg_catalog.array_length(v_retouches, 1) LOOP
    v_ancre := v_retouches[i][1];
    IF pg_catalog.strpos(v_def, v_ancre) = 0 THEN
      RAISE EXCEPTION 'autoriser_jeton_video : ancre % absente, le corps a change, migration a revoir', i;
    END IF;
    IF pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_ancre) + 1), v_ancre) <> 0 THEN
      RAISE EXCEPTION 'autoriser_jeton_video : ancre % ambigue, migration a revoir', i;
    END IF;
    v_def := pg_catalog.replace(v_def, v_ancre, v_retouches[i][2]);
  END LOOP;
  EXECUTE v_def;
END;
$jeton$;


-- ---------------------------------------------------------------------------
-- 8. Les capacites des candidatures (retouche par ancrage du corps en vigueur)
-- ---------------------------------------------------------------------------
-- Comme le jeton : jamais une copie entiere. La salle 3 (20261108300000) a
-- deja retouche ce corps en production ('validerPiece', v_decider) ; une copie
-- l'effacerait. Chaque ancre se trouve une fois et une seule, sinon la
-- migration s'arrete. Juste dans les deux ordres (8000001 avant ou apres
-- 8300000) : aucune ancre ne touche validerPiece.
DO $capacites$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::pg_catalog.regprocedure);
  v_retouches text[][] := ARRAY[
    ARRAY[$a$    'peutMenerEntretien', false,$a$,
          $a$    'peutMenerEntretien', v_decider,
    -- V1-a : la coche fondateur (direction active), le choix des participants
    -- et la regle en vigueur (NULL : regle desactivee).
    'peutPoserFondateur', v_admin,
    'peutChoisirParticipants', v_decider,
    'fondateursExiges', CASE WHEN v_decider THEN pg_catalog.to_jsonb(private.entretiens_fondateurs_exiges())
                             ELSE 'null'::jsonb END,$a$],
    ARRAY[$a$      'planifierEntretien', false,$a$,
          $a$      'planifierEntretien', v_decider,$a$],
    ARRAY[$a$      'consignerEntretien', false,$a$,
          $a$      'consignerEntretien', v_decider,$a$]
  ];
  i integer;
  v_n integer;
BEGIN
  FOR i IN 1 .. pg_catalog.array_length(v_retouches, 1) LOOP
    v_n := (pg_catalog.length(v_def)
            - pg_catalog.length(pg_catalog.replace(v_def, v_retouches[i][1], '')))
           / pg_catalog.length(v_retouches[i][1]);
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'capacites_candidatures : ancre % trouvee % fois au lieu de 1, migration a revoir', i, v_n;
    END IF;
    v_def := pg_catalog.replace(v_def, v_retouches[i][1], v_retouches[i][2]);
  END LOOP;
  EXECUTE v_def;
END;
$capacites$;

DO $empreinte$
DECLARE
  v_ancien text := pg_catalog.obj_description('public.capacites_candidatures()'::regprocedure, 'pg_proc');
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.capacites_candidatures() IS %L',
    pg_catalog.regexp_replace(v_ancien, 'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)))
    || ' V1-a (03/11/2026) : peutMenerEntretien, planifierEntretien, consignerEntretien et peutChoisirParticipants suivent peutDecider ; peutPoserFondateur, fondateursExiges. Must-pass: supabase/tests/scenarios_v1_entretiens.sql.');
END;
$empreinte$;

-- ---------------------------------------------------------------------------
-- 9. Pour la salle 3 (N1, 20261108300000) : la conclusion d'une candidature
-- ---------------------------------------------------------------------------
-- Lue sur le dernier entretien consigne 'tenu' de la candidature :
--   * avisFavorable : au moins un compte rendu 'favorable' d'un participant
--     encore autorise (du cote de la candidature, ou super-admin) ;
--   * constatComplet : memorisation, au moins une riwaya et ijaza renseignees
--     dans un meme compte rendu de cet entretien ; `constat` est celui du plus
--     recent compte rendu complet, a defaut du plus recent compte rendu.
-- Sans entretien tenu : tenu faux, le reste faux ou NULL. STABLE, aucun droit
-- client : seule une fonction SECURITY DEFINER la lit.
CREATE FUNCTION private.entretien_conclusion(p_candidature uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
  v_session uuid;
  v_favorable boolean := false;
  v_cr public.entretien_comptes_rendus;
  v_complet boolean := false;
BEGIN
  SELECT c.genre INTO v_genre FROM public.candidatures c WHERE c.id = p_candidature;
  SELECT e.session_id INTO v_session
    FROM public.entretiens e
   WHERE e.candidature_id = p_candidature AND e.issue = 'tenu'
   ORDER BY e.consigne_le DESC, e.session_id
   LIMIT 1;
  IF v_session IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('tenu', false, 'avisFavorable', false, 'constatComplet', false,
      'constat', pg_catalog.jsonb_build_object('memorisation', NULL, 'tajwid', NULL,
                                               'riwayat', '[]'::jsonb, 'ijaza', NULL),
      'sessionId', NULL);
  END IF;
  v_favorable := EXISTS (
    SELECT 1 FROM public.entretien_comptes_rendus cr
     WHERE cr.session_id = v_session AND cr.avis = 'favorable'
       AND private.entretien_cote_permis(cr.auteur_id, v_genre));
  SELECT cr.* INTO v_cr
    FROM public.entretien_comptes_rendus cr
   WHERE cr.session_id = v_session
     AND private.entretien_cote_permis(cr.auteur_id, v_genre)
   ORDER BY (cr.memorisation_observee IS NOT NULL
             AND pg_catalog.cardinality(cr.riwayat_observees) > 0
             AND cr.ijaza_presentee IS NOT NULL) DESC,
            cr.ecrit_le DESC, cr.auteur_id
   LIMIT 1;
  v_complet := coalesce(v_cr.memorisation_observee IS NOT NULL
                        AND pg_catalog.cardinality(v_cr.riwayat_observees) > 0
                        AND v_cr.ijaza_presentee IS NOT NULL, false);
  RETURN pg_catalog.jsonb_build_object('tenu', true, 'avisFavorable', v_favorable,
    'constatComplet', v_complet,
    'constat', pg_catalog.jsonb_build_object('memorisation', v_cr.memorisation_observee,
      'tajwid', v_cr.tajwid_observe,
      'riwayat', pg_catalog.to_jsonb(coalesce(v_cr.riwayat_observees, '{}'::text[])),
      'ijaza', v_cr.ijaza_presentee),
    'sessionId', v_session);
END;
$function$;
REVOKE ALL ON FUNCTION private.entretien_conclusion(uuid) FROM PUBLIC, anon, authenticated;
COMMENT ON FUNCTION private.entretien_conclusion(uuid) IS
  'V1-a (03/11/2026) : {tenu, avisFavorable, constatComplet, constat{memorisation, tajwid, riwayat, ijaza}, '
  'sessionId}, sur le dernier entretien tenu. Signature convenue avec la salle 3 (20261108300000) : ne pas '
  'changer. Aucun droit client.';

-- ---------------------------------------------------------------------------
-- 10. Verification finale
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_t text;
  v_f text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_enum en
                   JOIN pg_catalog.pg_type t ON t.oid = en.enumtypid
                  WHERE t.typname = 'participant_role' AND en.enumlabel = 'intervieweur')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_enum en
                   JOIN pg_catalog.pg_type t ON t.oid = en.enumtypid
                  WHERE t.typname = 'participant_role' AND en.enumlabel = 'candidat') THEN
    RAISE EXCEPTION 'V1-a : participant_role sans intervieweur ou candidat (20261108000000 ou 20261107700000 manquante)';
  END IF;
  IF pg_catalog.pg_get_constraintdef((SELECT c.oid FROM pg_catalog.pg_constraint c
        WHERE c.conname = 'sessions_session_type_check'
          AND c.conrelid = 'public.sessions'::regclass)) !~ 'entretien.*reunion' THEN
    RAISE EXCEPTION 'V1-a : session_type n''admet pas entretien et reunion';
  END IF;
  FOREACH v_t IN ARRAY ARRAY['public.personnel_fondateurs', 'public.entretiens',
                             'public.entretien_participants', 'public.entretien_comptes_rendus'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = v_t::regclass)
       OR pg_catalog.has_table_privilege('authenticated', v_t, 'SELECT')
       OR pg_catalog.has_table_privilege('authenticated', v_t, 'INSERT')
       OR pg_catalog.has_table_privilege('authenticated', v_t, 'UPDATE')
       OR pg_catalog.has_table_privilege('anon', v_t, 'SELECT') THEN
      RAISE EXCEPTION 'V1-a : % ouverte au client', v_t;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
      'public.personnel_entretiens()', 'public.poser_fondateur(uuid,boolean)',
      'public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)',
      'public.ajouter_participant_entretien(uuid,uuid)', 'public.retirer_participant_entretien(uuid,uuid)',
      'public.consigner_entretien(uuid,text,text,integer,text)',
      'public.ecrire_compte_rendu_entretien(uuid,text,text,text,text,text[],text)',
      'public.mes_entretiens(integer)', 'public.lire_entretien(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'V1-a : droits d''execution inattendus sur %', v_f;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY['private.entretien_conclusion(uuid)', 'private.personnel_actif(uuid)',
      'private.entretien_cote_permis(uuid,public.gender)', 'private.entretiens_fondateurs_exiges()',
      'private.entretien_fondateurs_verifier(integer)', 'private.entretien_direction_de_son_cote(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'V1-a : % executable par un client', v_f;
    END IF;
  END LOOP;
  IF (SELECT p.provolatile FROM pg_catalog.pg_proc p
         WHERE p.oid = 'private.entretien_conclusion(uuid)'::regprocedure) <> 's'
     OR pg_catalog.pg_get_function_result('private.entretien_conclusion(uuid)'::regprocedure) <> 'jsonb' THEN
    RAISE EXCEPTION 'V1-a : entretien_conclusion n''a pas la signature convenue (STABLE, jsonb)';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'public.autoriser_jeton_video(uuid,uuid,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'V1-a : autoriser_jeton_video executable par un client';
  END IF;
  IF pg_catalog.pg_get_functiondef('public.x217_sessions_cloture_tresorerie()'::regprocedure) !~ 'session_type'
     OR pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure)
          !~ '''candidat'', ''intervieweur'''
     OR pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)
          !~ 'peutChoisirParticipants'
     OR pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)
          !~ '''planifierEntretien'', v_decider'
     OR pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)
          !~ '''consignerEntretien'', v_decider' THEN
    RAISE EXCEPTION 'V1-a : une des trois fonctions retouchees n''a pas son ajout';
  END IF;
  -- La salle 3 (20261108300000) n'est jamais defaite : si elle est passee,
  -- validerPiece suit toujours peutDecider ; sinon il est encore a faux.
  IF pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)
       !~ '''validerPiece'', (v_decider|false)' THEN
    RAISE EXCEPTION 'V1-a : validerPiece a disparu de capacites_candidatures';
  END IF;
  IF to_regprocedure('public.affectation_candidat(uuid)') IS NOT NULL
     AND pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)
           !~ '''validerPiece'', v_decider' THEN
    RAISE EXCEPTION 'V1-a : la salle 3 est installee mais validerPiece ne suit plus peutDecider';
  END IF;
  -- Aucune ligne n'emploie encore le nouveau role (il nait avec ce lot).
  IF EXISTS (SELECT 1 FROM public.session_participants sp WHERE sp.role::text = 'intervieweur') THEN
    RAISE EXCEPTION 'V1-a : des inscrits intervieweur existent avant ce lot';
  END IF;
END;
$postflight$;
