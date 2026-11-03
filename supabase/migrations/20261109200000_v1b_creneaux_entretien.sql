-- V1-b (03/11/2026, numero reserve par le pilote et garde-cap) : les creneaux
-- d'entretien, ouverts par la direction, reserves par le candidat.
--
-- Decisions appliquees (directeur, 03/11 vers 17:20 et 17:35, puis 20:30,
-- relayees par garde-cap ; Q2 et Q3 de garde-cap) :
--   * la direction ouvre des creneaux : un debut, une duree, des
--     participants choisis librement dans le personnel actif (fondateurs et
--     experts), et les langues de l'entretien ;
--   * un creneau declare son cote (le genre des candidatures qu'il accueille).
--     Ses participants sont de ce cote (CAND-Q07), ou le super-admin de 0088 ;
--     la direction ouvre un creneau de son cote, le super-admin des deux
--     cotes (V1-a-bis), au journal sensible ;
--   * la regle des fondateurs (entretiens.fondateurs_minimum,
--     entretiens.regle_fondateurs_active) vaut a l'ouverture et a la
--     reservation ;
--   * le candidat ne voit que les creneaux de son cote, dont une langue est
--     dans sa reponse « langues » (langueMaternelle, languesExplication) ;
--   * le candidat reserve un creneau : c'est le geste planifier_entretien du
--     moteur des candidatures, variante 2, auteur candidat (cle, version,
--     journal) ; la seance d'entretien et ses inscrits sont ceux de V1-a ;
--   * mon_entretien : l'entretien a venir du candidat, pour /attente.
--
-- Garde-cap (03/11, 21:28) : « proposé », decoule de CAND-Q07 deja decide,
-- sans question au directeur : un creneau declare son cote, aucun creneau
-- mixte.
--
-- Borne cote candidat : un candidat ne voit et ne reserve que les creneaux
-- du genre de sa candidature (recopie du compte, C8), sans role de direction.
-- Deux reservations du meme creneau : la ligne du creneau est verrouillee
-- (FOR UPDATE) et entretien_creneaux.session_id est unique ; la seconde
-- trouve le creneau pris (creneau_indisponible).
--
-- Fonctions existantes remplacees : aucune (0 CREATE OR REPLACE). Ce fichier
-- appelle sans les modifier les fonctions de V1-a et V1-a-bis
-- (entretien_peut_agir, entretien_cote_permis, personnel_actif,
-- entretien_fondateurs_verifier, entretien_journal_hors_cote) et le moteur
-- des candidatures (candidature_geste_ouvrir, _appliquer, _conclure).
--
-- Rien n'est efface : un creneau annule garde sa ligne (annule_le).
-- Mots de suppression de ce fichier : 0.

-- ---------------------------------------------------------------------------
-- 1. La regle du moteur : le candidat planifie son entretien en reservant
-- ---------------------------------------------------------------------------
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('planifier_entretien', 2, 11, '{candidat}', '{verifications}', '{entretien_a_planifier}', '{en_cours}',
   'interdite', NULL, '{}', NULL, false, 'entretien', '{"etat": "entretien_planifie"}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Les creneaux et leurs participants
-- ---------------------------------------------------------------------------
CREATE TABLE public.entretien_creneaux (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cote public.gender NOT NULL,
  debut timestamptz NOT NULL,
  duree_minutes integer NOT NULL CHECK (duree_minutes BETWEEN 15 AND 120),
  langues text[] NOT NULL
    CHECK (pg_catalog.cardinality(langues) BETWEEN 1 AND 10
           AND pg_catalog.array_position(langues, NULL) IS NULL),
  ouvert_par uuid NOT NULL REFERENCES public.profiles(id),
  ouvert_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  annule_par uuid NULL REFERENCES public.profiles(id),
  annule_le timestamptz NULL,
  -- L'entretien ne nait qu'a la reservation.
  session_id uuid NULL UNIQUE REFERENCES public.entretiens(session_id),
  reserve_le timestamptz NULL,
  CONSTRAINT entretien_creneaux_annulation CHECK ((annule_le IS NULL) = (annule_par IS NULL)),
  CONSTRAINT entretien_creneaux_reservation CHECK ((session_id IS NULL) = (reserve_le IS NULL)),
  CONSTRAINT entretien_creneaux_libre_ou_annule CHECK (session_id IS NULL OR annule_le IS NULL)
);
CREATE INDEX entretien_creneaux_ouverts_idx ON public.entretien_creneaux (cote, debut)
  WHERE session_id IS NULL AND annule_le IS NULL;
ALTER TABLE public.entretien_creneaux ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.entretien_creneaux FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.entretien_creneaux IS
  'V1-b (03/11/2026) : creneau d''entretien ouvert par la direction (cote, debut, duree, langues), '
  'reserve par un candidat de ce cote. Aucun droit client.';

CREATE TABLE public.entretien_creneau_participants (
  creneau_id uuid NOT NULL REFERENCES public.entretien_creneaux(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  PRIMARY KEY (creneau_id, profile_id)
);
ALTER TABLE public.entretien_creneau_participants ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.entretien_creneau_participants FROM PUBLIC, anon, authenticated;

-- Les langues de la reponse « langues » d'une candidature (derniere reponse).
CREATE FUNCTION private.candidature_langues(p_candidature uuid)
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.array_agg(DISTINCT x) FILTER (WHERE x IS NOT NULL), '{}'::text[])
    FROM (SELECT r.reponses FROM public.candidature_reponses r
           WHERE r.candidature_id = p_candidature
           ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1) d,
         LATERAL (SELECT d.reponses ->> 'langueMaternelle' AS x
                  UNION ALL
                  SELECT pg_catalog.jsonb_array_elements_text(
                           CASE WHEN pg_catalog.jsonb_typeof(d.reponses -> 'languesExplication') = 'array'
                                THEN d.reponses -> 'languesExplication' ELSE '[]'::jsonb END)) l;
$function$;

-- La candidature du candidat appelant, en attente d'un entretien.
CREATE FUNCTION private.candidature_a_planifier_du_candidat()
RETURNS public.candidatures
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT c.* FROM public.candidatures c
   WHERE c.profile_id = auth.uid()
     AND c.issue = 'en_cours' AND c.etape = 'verifications' AND c.etat = 'entretien_a_planifier'
     AND NOT c.en_pause
   ORDER BY c.recue_le DESC, c.id
   LIMIT 1;
$function$;

-- Un creneau est-il encore tenable : participants actifs, du cote, regle des
-- fondateurs. Rend NULL si oui, sinon le refus.
CREATE FUNCTION private.entretien_creneau_tenable(p_creneau uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cr public.entretien_creneaux;
  v_fondateurs integer;
BEGIN
  SELECT c.* INTO v_cr FROM public.entretien_creneaux c WHERE c.id = p_creneau;
  IF EXISTS (SELECT 1 FROM public.entretien_creneau_participants p
              WHERE p.creneau_id = p_creneau
                AND NOT (private.personnel_actif(p.profile_id)
                         AND private.entretien_cote_permis(p.profile_id, v_cr.cote))) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participant_non_autorise');
  END IF;
  SELECT count(*)::integer INTO v_fondateurs
    FROM public.entretien_creneau_participants p
    JOIN public.personnel_fondateurs f ON f.profile_id = p.profile_id AND f.fondateur
   WHERE p.creneau_id = p_creneau;
  RETURN private.entretien_fondateurs_verifier(v_fondateurs);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. La direction : ouvrir, annuler, lister
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.ouvrir_creneau_entretien(
  p_cote public.gender,
  p_debut timestamptz,
  p_duree_minutes integer,
  p_langues text[],
  p_participants uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_participants uuid[];
  v_langues text[];
  v_p uuid;
  v_id uuid;
  v_refus jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'creneaux d''entretien reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_cote IS NULL OR p_debut IS NULL OR p_duree_minutes IS NULL THEN
    RAISE EXCEPTION 'creneau : cote, debut et duree attendus' USING ERRCODE = '22023';
  END IF;
  IF NOT private.entretien_peut_agir(p_cote) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  IF NOT pg_catalog.isfinite(p_debut)
     OR p_debut < pg_catalog.now() + interval '1 hour'
     OR p_debut > pg_catalog.now() + interval '90 days' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'debut_invalide');
  END IF;
  IF p_duree_minutes NOT BETWEEN 15 AND 120 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'duree_invalide');
  END IF;
  SELECT pg_catalog.array_agg(DISTINCT x ORDER BY x) INTO v_langues
    FROM pg_catalog.unnest(coalesce(p_langues, '{}'::text[])) x WHERE x IS NOT NULL;
  IF v_langues IS NULL OR pg_catalog.cardinality(v_langues) NOT BETWEEN 1 AND 10
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_langues) x WHERE x !~ '^([a-z]{2,3}|autre)$') THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'langues_invalides');
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
    IF NOT private.personnel_actif(v_p) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'participant_non_autorise', 'profil', v_p);
    END IF;
    IF NOT private.entretien_cote_permis(v_p, p_cote) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'participant_autre_cote', 'profil', v_p);
    END IF;
  END LOOP;
  v_refus := private.entretien_fondateurs_verifier(
    (SELECT count(*)::integer FROM public.personnel_fondateurs f
      WHERE f.fondateur AND f.profile_id = ANY (v_participants)));
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;

  INSERT INTO public.entretien_creneaux (cote, debut, duree_minutes, langues, ouvert_par)
  VALUES (p_cote, p_debut, p_duree_minutes, v_langues, v_moi)
  RETURNING id INTO v_id;
  INSERT INTO public.entretien_creneau_participants (creneau_id, profile_id)
  SELECT v_id, x FROM pg_catalog.unnest(v_participants) x;
  PERFORM private.entretien_journal_hors_cote(p_cote, 'ouvrir_creneau', v_id);
  RETURN pg_catalog.jsonb_build_object('creneauId', v_id, 'debut', p_debut,
    'fin', p_debut + pg_catalog.make_interval(mins => p_duree_minutes), 'langues', pg_catalog.to_jsonb(v_langues),
    'participants', pg_catalog.to_jsonb(v_participants));
END;
$function$;

-- Annuler un creneau encore libre. Sa ligne reste (annule_le).
CREATE FUNCTION public.annuler_creneau_entretien(p_creneau uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cr public.entretien_creneaux;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'creneaux d''entretien reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT c.* INTO v_cr FROM public.entretien_creneaux c WHERE c.id = p_creneau FOR UPDATE;
  IF v_cr.id IS NULL OR NOT private.entretien_peut_agir(v_cr.cote) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF v_cr.session_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'creneau_reserve');
  END IF;
  IF v_cr.annule_le IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('creneauId', p_creneau, 'annule', true);
  END IF;
  UPDATE public.entretien_creneaux
     SET annule_le = pg_catalog.clock_timestamp(), annule_par = auth.uid()
   WHERE id = p_creneau;
  PERFORM private.entretien_journal_hors_cote(v_cr.cote, 'annuler_creneau', p_creneau);
  RETURN pg_catalog.jsonb_build_object('creneauId', p_creneau, 'annule', true);
END;
$function$;

-- Les creneaux a venir de son cote (des deux cotes pour le super-admin).
CREATE FUNCTION public.lister_creneaux_entretien(p_jours integer DEFAULT 30)
RETURNS TABLE (
  creneau_id uuid,
  cote text,
  debut timestamptz,
  fin timestamptz,
  langues text[],
  participants integer,
  fondateurs integer,
  etat text,
  session_id uuid
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'creneaux d''entretien reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT c.id, c.cote::text, c.debut, c.debut + pg_catalog.make_interval(mins => c.duree_minutes), c.langues,
           (SELECT count(*)::integer FROM public.entretien_creneau_participants p WHERE p.creneau_id = c.id),
           (SELECT count(*)::integer FROM public.entretien_creneau_participants p
              JOIN public.personnel_fondateurs f ON f.profile_id = p.profile_id AND f.fondateur
             WHERE p.creneau_id = c.id),
           CASE WHEN c.annule_le IS NOT NULL THEN 'annule'
                WHEN c.session_id IS NOT NULL THEN 'reserve'
                ELSE 'libre' END,
           c.session_id
      FROM public.entretien_creneaux c
     WHERE private.entretien_peut_agir(c.cote)
       AND c.debut >= pg_catalog.now() - interval '1 day'
       AND c.debut <= pg_catalog.now() + pg_catalog.make_interval(days => least(greatest(coalesce(p_jours, 30), 1), 90))
     ORDER BY c.debut;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Le candidat : voir, reserver, son entretien
-- ---------------------------------------------------------------------------
-- Les creneaux libres de son cote, dans l'une de ses langues. Ni nom ni
-- contact des participants.
CREATE FUNCTION public.creneaux_entretien_disponibles()
RETURNS TABLE (creneau_id uuid, debut timestamptz, fin timestamptz, langues text[])
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
  v_langues text[];
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'creneaux reserves a un candidat connecte' USING ERRCODE = '42501';
  END IF;
  v_c := private.candidature_a_planifier_du_candidat();
  IF v_c.id IS NULL THEN
    RETURN;
  END IF;
  v_langues := private.candidature_langues(v_c.id);
  RETURN QUERY
    SELECT c.id, c.debut, c.debut + pg_catalog.make_interval(mins => c.duree_minutes), c.langues
      FROM public.entretien_creneaux c
     WHERE c.cote = v_c.genre
       AND c.session_id IS NULL AND c.annule_le IS NULL
       AND c.debut > pg_catalog.now() + interval '30 minutes'
       AND c.langues && v_langues
       AND private.entretien_creneau_tenable(c.id) IS NULL
     ORDER BY c.debut
     LIMIT 50;
END;
$function$;

-- Reserver : le geste planifier_entretien du moteur (variante 2, auteur
-- candidat). L'entretien est celui de V1-a : seance 'entretien' dont
-- teacher_id est la direction qui a ouvert le creneau, participants inscrits
-- 'intervieweur', candidat inscrit 'candidat'.
CREATE FUNCTION public.reserver_creneau_entretien(
  p_creneau uuid,
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
  v_c public.candidatures;
  v_cr public.entretien_creneaux;
  v_o jsonb;
  v_seance uuid;
  v_refus jsonb;
  v_fondateurs integer;
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'reservation reservee a un candidat connecte' USING ERRCODE = '42501';
  END IF;
  v_c := private.candidature_a_planifier_du_candidat();
  IF v_c.id IS NULL THEN
    -- Un rejeu apres succes : la candidature n'est plus a planifier.
    SELECT c.* INTO v_c FROM public.candidatures c
     WHERE c.profile_id = v_moi AND c.issue = 'en_cours' ORDER BY c.recue_le DESC, c.id LIMIT 1;
    IF v_c.id IS NULL THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'aucune_candidature');
    END IF;
  END IF;

  v_o := private.candidature_geste_ouvrir(v_c.id, 'planifier_entretien', 'candidat', v_moi,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;

  SELECT c.* INTO v_cr FROM public.entretien_creneaux c WHERE c.id = p_creneau FOR UPDATE;
  IF v_cr.id IS NULL OR v_cr.cote IS DISTINCT FROM v_c.genre
     OR NOT (v_cr.langues && private.candidature_langues(v_c.id)) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'creneau_indisponible');
  END IF;
  IF v_cr.session_id IS NOT NULL OR v_cr.annule_le IS NOT NULL
     OR v_cr.debut <= pg_catalog.now() + interval '30 minutes' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'creneau_indisponible');
  END IF;
  v_refus := private.entretien_creneau_tenable(p_creneau);
  IF v_refus IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'creneau_indisponible');
  END IF;
  IF EXISTS (SELECT 1 FROM public.entretiens e WHERE e.candidature_id = v_c.id AND e.issue IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_deja_planifie');
  END IF;

  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_cr.ouvert_par, v_cr.debut, v_cr.debut + pg_catalog.make_interval(mins => v_cr.duree_minutes),
          'planned', 'entretien', v_cr.debut - interval '10 minutes')
  RETURNING id INTO v_seance;
  INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
  VALUES (v_seance, v_c.id, v_moi, v_cr.ouvert_par);
  INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par)
  SELECT v_seance, p.profile_id, coalesce(f.fondateur, false), v_cr.ouvert_par
    FROM public.entretien_creneau_participants p
    LEFT JOIN public.personnel_fondateurs f ON f.profile_id = p.profile_id
   WHERE p.creneau_id = p_creneau;
  INSERT INTO public.session_participants (session_id, profile_id, role)
  SELECT v_seance, p.profile_id, 'intervieweur'::public.participant_role
    FROM public.entretien_creneau_participants p WHERE p.creneau_id = p_creneau
  UNION ALL
  SELECT v_seance, v_moi, 'candidat'::public.participant_role;
  UPDATE public.entretien_creneaux
     SET session_id = v_seance, reserve_le = pg_catalog.clock_timestamp()
   WHERE id = p_creneau;
  SELECT count(*) FILTER (WHERE ep.fondateur)::integer INTO v_fondateurs
    FROM public.entretien_participants ep WHERE ep.session_id = v_seance;

  PERFORM private.candidature_geste_appliquer(v_c.id, 'planifier_entretien',
    (v_o ->> 'variante')::smallint, 'candidat', v_moi, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('sessionId', v_seance, 'creneauId', p_creneau, 'debut', v_cr.debut,
      'dureeMinutes', v_cr.duree_minutes, 'fondateurs', v_fondateurs, 'aNotifier', 'entretien_reserve'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_c.id, 'planifier_entretien', v_moi,
    pg_catalog.jsonb_build_object(
      'entretien', pg_catalog.jsonb_build_object(
        'sessionId', v_seance, 'creneauId', p_creneau, 'debut', v_cr.debut,
        'fin', v_cr.debut + pg_catalog.make_interval(mins => v_cr.duree_minutes))));
END;
$function$;

-- L'entretien a venir du candidat (pour /attente) : quand, et s'il est ouvert.
-- Ni nom ni contact des participants.
CREATE FUNCTION public.mon_entretien()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r record;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'entretien reserve a un candidat connecte' USING ERRCODE = '42501';
  END IF;
  SELECT e.session_id, s.started_at, s.ended_at, s.join_opens_at, s.status::text AS statut
    INTO v_r
    FROM public.entretiens e
    JOIN public.sessions s ON s.id = e.session_id
   WHERE e.candidat_id = auth.uid() AND e.issue IS NULL AND s.deleted_at IS NULL
   ORDER BY s.started_at
   LIMIT 1;
  IF v_r.session_id IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object('sessionId', v_r.session_id, 'debut', v_r.started_at,
    'fin', v_r.ended_at, 'ouvertureLe', v_r.join_opens_at, 'statut', v_r.statut);
END;
$function$;

REVOKE ALL ON FUNCTION public.ouvrir_creneau_entretien(public.gender, timestamptz, integer, text[], uuid[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.annuler_creneau_entretien(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.lister_creneaux_entretien(integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.creneaux_entretien_disponibles() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reserver_creneau_entretien(uuid, integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mon_entretien() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ouvrir_creneau_entretien(public.gender, timestamptz, integer, text[], uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.annuler_creneau_entretien(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lister_creneaux_entretien(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.creneaux_entretien_disponibles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.reserver_creneau_entretien(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mon_entretien() TO authenticated;
REVOKE ALL ON FUNCTION private.candidature_langues(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.candidature_a_planifier_du_candidat() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.entretien_creneau_tenable(uuid) FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5. Verification finale
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_t text;
  v_f text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                  WHERE r.geste = 'planifier_entretien' AND r.variante = 2 AND r.auteurs = '{candidat}') THEN
    RAISE EXCEPTION 'V1-b : la regle planifier_entretien du candidat manque';
  END IF;
  FOREACH v_t IN ARRAY ARRAY['public.entretien_creneaux', 'public.entretien_creneau_participants'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = v_t::regclass)
       OR pg_catalog.has_table_privilege('authenticated', v_t, 'SELECT')
       OR pg_catalog.has_table_privilege('authenticated', v_t, 'INSERT')
       OR pg_catalog.has_table_privilege('anon', v_t, 'SELECT') THEN
      RAISE EXCEPTION 'V1-b : % ouverte au client', v_t;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY[
      'public.ouvrir_creneau_entretien(public.gender,timestamptz,integer,text[],uuid[])',
      'public.annuler_creneau_entretien(uuid)', 'public.lister_creneaux_entretien(integer)',
      'public.creneaux_entretien_disponibles()', 'public.reserver_creneau_entretien(uuid,integer,text)',
      'public.mon_entretien()'] LOOP
    IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'V1-b : droits inattendus sur %', v_f;
    END IF;
  END LOOP;
  FOREACH v_f IN ARRAY ARRAY['private.candidature_langues(uuid)',
      'private.candidature_a_planifier_du_candidat()', 'private.entretien_creneau_tenable(uuid)'] LOOP
    IF pg_catalog.has_function_privilege('authenticated', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'V1-b : % executable par un client', v_f;
    END IF;
  END LOOP;
  -- V1-a, V1-a-bis et la salle 3 ne sont pas defaites (ce fichier ne retouche
  -- aucune fonction existante).
  IF pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure) !~ '''validerPiece'', v_decider' THEN
    RAISE EXCEPTION 'V1-b : validerPiece ne suit plus v_decider';
  END IF;
END;
$postflight$;
